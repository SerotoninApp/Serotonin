//
//  patchfinder64.c
//  extra_recipe
//
//  Created by xerub on 06/06/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#include <assert.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/syscall.h>
#include <stdbool.h>
#include <mach-o/fat.h>
#include "patchfinder64.h"

bool auth_ptrs = false;
typedef unsigned long long addr_t;
static addr_t kerndumpbase = -1;
static addr_t xnucore_base = 0;
static addr_t xnucore_size = 0;
static addr_t ppl_base = 0;
static addr_t ppl_size = 0;
static addr_t prelink_base = 0;
static addr_t prelink_size = 0;
static addr_t cstring_base = 0;
static addr_t cstring_size = 0;
static addr_t pstring_base = 0;
static addr_t pstring_size = 0;
static addr_t oslstring_base = 0;
static addr_t oslstring_size = 0;
static addr_t data_base = 0;
static addr_t data_size = 0;
static addr_t data_const_base = 0;
static addr_t data_const_size = 0;
static addr_t const_base = 0;
static addr_t const_size = 0;
static addr_t kernel_entry = 0;
static void *kernel_mh = 0;
static addr_t kernel_delta = 0;
bool monolithic_kernel = false;


#define IS64(image) (*(uint8_t *)(image) & 1)

#define MACHO(p) ((*(unsigned int *)(p) & ~1) == 0xfeedface)

/* generic stuff *************************************************************/

#define UCHAR_MAX 255

/* these operate on VA ******************************************************/

#define INSN_RET  0xD65F03C0, 0xFFFFFFFF
#define INSN_CALL 0x94000000, 0xFC000000
#define INSN_B    0x14000000, 0xFC000000
#define INSN_CBZ  0x34000000, 0x7F000000
#define INSN_ADRP 0x90000000, 0x9F000000

static unsigned char *
boyermoore_horspool_memmem(const unsigned char* haystack, size_t hlen,
                           const unsigned char* needle,   size_t nlen)
{
    size_t last, scan = 0;
    size_t bad_char_skip[UCHAR_MAX + 1]; /* Officially called:
                                          * bad character shift */

    /* Sanity checks on the parameters */
    if (nlen <= 0 || !haystack || !needle)
        return NULL;

    /* ---- Preprocess ---- */
    /* Initialize the table to default value */
    /* When a character is encountered that does not occur
     * in the needle, we can safely skip ahead for the whole
     * length of the needle.
     */
    for (scan = 0; scan <= UCHAR_MAX; scan = scan + 1)
        bad_char_skip[scan] = nlen;

    /* C arrays have the first byte at [0], therefore:
     * [nlen - 1] is the last byte of the array. */
    last = nlen - 1;

    /* Then populate it with the analysis of the needle */
    for (scan = 0; scan < last; scan = scan + 1)
        bad_char_skip[needle[scan]] = last - scan;

    /* ---- Do the matching ---- */

    /* Search the haystack, while the needle can still be within it. */
    while (hlen >= nlen)
    {
        /* scan from the end of the needle */
        for (scan = last; haystack[scan] == needle[scan]; scan = scan - 1)
            if (scan == 0) /* If the first byte matches, we've found it. */
                return (void *)haystack;

        /* otherwise, we need to skip some bytes and start again.
           Note that here we are getting the skip value based on the last byte
           of needle, no matter where we didn't match. So if needle is: "abcd"
           then we are skipping based on 'd' and that value will be 4, and
           for "abcdd" we again skip on 'd' but the value will be only 1.
           The alternative of pretending that the mismatched character was
           the last character is slower in the normal case (E.g. finding
           "abcd" in "...azcd..." gives 4 by using 'd' but only
           4-2==2 using 'z'. */
        hlen     -= bad_char_skip[haystack[last]];
        haystack += bad_char_skip[haystack[last]];
    }

    return NULL;
}

/* disassembler **************************************************************/

static int HighestSetBit(int N, uint32_t imm)
{
    int i;
    for (i = N - 1; i >= 0; i--) {
        if (imm & (1 << i)) {
            return i;
        }
    }
    return -1;
}

static uint64_t ZeroExtendOnes(unsigned M, unsigned N)    // zero extend M ones to N width
{
    (void)N;
    return ((uint64_t)1 << M) - 1;
}

static uint64_t RORZeroExtendOnes(unsigned M, unsigned N, unsigned R)
{
    uint64_t val = ZeroExtendOnes(M, N);
    if (R == 0) {
        return val;
    }
    return ((val >> R) & (((uint64_t)1 << (N - R)) - 1)) | ((val & (((uint64_t)1 << R) - 1)) << (N - R));
}

static uint64_t Replicate(uint64_t val, unsigned bits)
{
    uint64_t ret = val;
    unsigned shift;
    for (shift = bits; shift < 64; shift += bits) {    // XXX actually, it is either 32 or 64
        ret |= (val << shift);
    }
    return ret;
}

static int DecodeBitMasks(unsigned immN, unsigned imms, unsigned immr, int immediate, uint64_t *newval)
{
    unsigned levels, S, R, esize;
    int len = HighestSetBit(7, (immN << 6) | (~imms & 0x3F));
    if (len < 1) {
        return -1;
    }
    levels = (unsigned int)ZeroExtendOnes(len, 6);
    if (immediate && (imms & levels) == levels) {
        return -1;
    }
    S = imms & levels;
    R = immr & levels;
    esize = 1 << len;
    *newval = Replicate(RORZeroExtendOnes(S + 1, esize, R), esize);
    return 0;
}

static int DecodeMov(uint32_t opcode, uint64_t total, int first, uint64_t *newval)
{
    unsigned o = (opcode >> 29) & 3;
    unsigned k = (opcode >> 23) & 0x3F;
    unsigned rn, rd;
    uint64_t i;

    if (k == 0x24 && o == 1) {            // MOV (bitmask imm) <=> ORR (immediate)
        unsigned s = (opcode >> 31) & 1;
        unsigned N = (opcode >> 22) & 1;
        if (s == 0 && N != 0) {
            return -1;
        }
        rn = (opcode >> 5) & 0x1F;
        if (rn == 31) {
            unsigned imms = (opcode >> 10) & 0x3F;
            unsigned immr = (opcode >> 16) & 0x3F;
            return DecodeBitMasks(N, imms, immr, 1, newval);
        }
    } else if (k == 0x25) {                // MOVN/MOVZ/MOVK
        unsigned s = (opcode >> 31) & 1;
        unsigned h = (opcode >> 21) & 3;
        if (s == 0 && h > 1) {
            return -1;
        }
        i = (opcode >> 5) & 0xFFFF;
        h *= 16;
        i <<= h;
        if (o == 0) {                // MOVN
            *newval = ~i;
            return 0;
        } else if (o == 2) {            // MOVZ
            *newval = i;
            return 0;
        } else if (o == 3 && !first) {        // MOVK
            *newval = (total & ~((uint64_t)0xFFFF << h)) | i;
            return 0;
        }
    } else if ((k | 1) == 0x23 && !first) {        // ADD (immediate)
        unsigned h = (opcode >> 22) & 3;
        if (h > 1) {
            return -1;
        }
        rd = opcode & 0x1F;
        rn = (opcode >> 5) & 0x1F;
        if (rd != rn) {
            return -1;
        }
        i = (opcode >> 10) & 0xFFF;
        h *= 12;
        i <<= h;
        if (o & 2) {                // SUB
            *newval = total - i;
            return 0;
        } else {                // ADD
            *newval = total + i;
            return 0;
        }
    }

    return -1;
}

/* patchfinder ***************************************************************/

static addr_t
step64(const uint8_t *buf, addr_t start, size_t length, uint32_t what, uint32_t mask)
{
    addr_t end = start + length;
    while (start < end) {
        uint32_t x = *(uint32_t *)(buf + start);
        if ((x & mask) == what) {
            return start;
        }
        start += 4;
    }
    return 0;
}

static addr_t
step64_back(const uint8_t *buf, addr_t start, size_t length, uint32_t what, uint32_t mask)
{
    addr_t end = start - length;
    while (start >= end) {
        uint32_t x = *(uint32_t *)(buf + start);
        if ((x & mask) == what) {
            return start;
        }
        start -= 4;
    }
    return 0;
}

static addr_t
step_adrp_to_reg(const uint8_t *buf, addr_t start, size_t length, int reg)
{
    return step64(buf, start, length, 0x90000000 | (reg&0x1F), 0x9F00001F);
}

static addr_t
bof64(const uint8_t *buf, addr_t start, addr_t where)
{
    if (auth_ptrs) {
        for (; where >= start; where -= 4) {
            uint32_t op = *(uint32_t *)(buf + where);
            if (op == 0xD503237F) {
                return where;
            }
        }
        return 0;
    }
    for (; where >= start; where -= 4) {
        uint32_t op = *(uint32_t *)(buf + where);
        if ((op & 0xFFC003FF) == 0x910003FD) {
            unsigned delta = (op >> 10) & 0xFFF;
            //printf("0x%llx: ADD X29, SP, #0x%x\n", where + kerndumpbase, delta);
            if ((delta & 0xF) == 0) {
                addr_t prev = where - ((delta >> 4) + 1) * 4;
                uint32_t au = *(uint32_t *)(buf + prev);
                //printf("0x%llx: (%llx & %llx) == %llx\n", prev + kerndumpbase, au, 0x3BC003E0, au & 0x3BC003E0);
                if ((au & 0x3BC003E0) == 0x298003E0) {
                    //printf("%x: STP x, y, [SP,#-imm]!\n", prev);
                    return prev;
                } else if ((au & 0x7F8003FF) == 0x510003FF) {
                    //printf("%x: SUB SP, SP, #imm\n", prev);
                    return prev;
                }
                for (addr_t diff = 4; diff < delta/4+4; diff+=4) {
                    uint32_t ai = *(uint32_t *)(buf + where - diff);
                    // SUB SP, SP, #imm
                    //printf("0x%llx: (%llx & %llx) == %llx\n", where - diff + kerndumpbase, ai, 0x3BC003E0, ai & 0x3BC003E0);
                    if ((ai & 0x7F8003FF) == 0x510003FF) {
                        return where - diff;
                    }
                    // Not stp and not str
                    if (((ai & 0xFFC003E0) != 0xA90003E0) && (ai&0xFFC001F0) != 0xF90001E0) {
                        break;
                    }
                }
                // try something else
                while (where > start) {
                    where -= 4;
                    au = *(uint32_t *)(buf + where);
                    // SUB SP, SP, #imm
                    if ((au & 0xFFC003FF) == 0xD10003FF && ((au >> 10) & 0xFFF) == delta + 0x10) {
                        return where;
                    }
                    // STP x, y, [SP,#imm]
                    if ((au & 0xFFC003E0) != 0xA90003E0) {
                        where += 4;
                        break;
                    }
                }
            }
        }
    }
    return 0;
}

static addr_t
xref64(const uint8_t *buf, addr_t start, addr_t end, addr_t what)
{
    addr_t i;
    uint64_t value[32];

    memset(value, 0, sizeof(value));

    end &= ~3;
    for (i = start & ~3; i < end; i += 4) {
        uint32_t op = *(uint32_t *)(buf + i);
        unsigned reg = op & 0x1F;

        if ((op & 0x9F000000) == 0x90000000) {
            signed adr = ((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8);
            //printf("%llx: ADRP X%d, 0x%llx\n", i, reg, ((long long)adr << 1) + (i & ~0xFFF));
            value[reg] = ((long long)adr << 1) + (i & ~0xFFF);
            continue;                // XXX should not XREF on its own?
        /*} else if ((op & 0xFFE0FFE0) == 0xAA0003E0) {
            unsigned rd = op & 0x1F;
            unsigned rm = (op >> 16) & 0x1F;
            //printf("%llx: MOV X%d, X%d\n", i, rd, rm);
            value[rd] = value[rm];*/
        } else if ((op & 0xFF000000) == 0x91000000) {
            unsigned rn = (op >> 5) & 0x1F;
            if (rn == 0x1f) {
                // ignore ADD Xn, SP
                value[reg] = 0;
                continue;
            }

            unsigned shift = (op >> 22) & 3;
            unsigned imm = (op >> 10) & 0xFFF;
            if (shift == 1) {
                imm <<= 12;
            } else {
                //assert(shift == 0);
                if (shift > 1) continue;
            }
            //printf("%llx: ADD X%d, X%d, 0x%x\n", i, reg, rn, imm);
            value[reg] = value[rn] + imm;
        } else if ((op & 0xF9C00000) == 0xF9400000) {
            unsigned rn = (op >> 5) & 0x1F;
            unsigned imm = ((op >> 10) & 0xFFF) << 3;
            //printf("%llx: LDR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            if (!imm) continue;            // XXX not counted as true xref
            value[reg] = value[rn] + imm;    // XXX address, not actual value
        /*} else if ((op & 0xF9C00000) == 0xF9000000) {
            unsigned rn = (op >> 5) & 0x1F;
            unsigned imm = ((op >> 10) & 0xFFF) << 3;
            //printf("%llx: STR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            if (!imm) continue;            // XXX not counted as true xref
            value[rn] = value[rn] + imm;    // XXX address, not actual value*/
        } else if ((op & 0x9F000000) == 0x10000000) {
            signed adr = ((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8);
            //printf("%llx: ADR X%d, 0x%llx\n", i, reg, ((long long)adr >> 11) + i);
            value[reg] = ((long long)adr >> 11) + i;
        } else if ((op & 0xFF000000) == 0x58000000) {
            unsigned adr = (op & 0xFFFFE0) >> 3;
            //printf("%llx: LDR X%d, =0x%llx\n", i, reg, adr + i);
            value[reg] = adr + i;        // XXX address, not actual value
        } else if ((op & 0xFC000000) == 0x94000000) {
            // BL addr
            signed imm = (op & 0x3FFFFFF) << 2;
            if (op & 0x2000000) {
                imm |= 0xf << 28;
            }
            unsigned adr = (unsigned)(i + imm);
            if (adr == what) {
                return i;
            }
        }
        // Don't match SP as an offset
        if (value[reg] == what && reg != 0x1f) {
            return i;
        }
    }
    return 0;
}

static addr_t
calc64(const uint8_t *buf, addr_t start, addr_t end, int which)
{
    addr_t i;
    uint64_t value[32];

    memset(value, 0, sizeof(value));

    end &= ~3;
    for (i = start & ~3; i < end; i += 4) {
        uint32_t op = *(uint32_t *)(buf + i);
        unsigned reg = op & 0x1F;
        if ((op & 0x9F000000) == 0x90000000) {
            signed adr = ((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8);
            //printf("%llx: ADRP X%d, 0x%llx\n", i, reg, ((long long)adr << 1) + (i & ~0xFFF));
            value[reg] = ((long long)adr << 1) + (i & ~0xFFF);
        /*} else if ((op & 0xFFE0FFE0) == 0xAA0003E0) {
            unsigned rd = op & 0x1F;
            unsigned rm = (op >> 16) & 0x1F;
            //printf("%llx: MOV X%d, X%d\n", i, rd, rm);
            value[rd] = value[rm];*/
        } else if ((op & 0xFF000000) == 0x91000000) {
            unsigned rn = (op >> 5) & 0x1F;
            unsigned shift = (op >> 22) & 3;
            unsigned imm = (op >> 10) & 0xFFF;
            if (shift == 1) {
                imm <<= 12;
            } else {
                //assert(shift == 0);
                if (shift > 1) continue;
            }
            //printf("%llx: ADD X%d, X%d, 0x%x\n", i, reg, rn, imm);
            value[reg] = value[rn] + imm;
        } else if ((op & 0xF9C00000) == 0xF9400000) {
            unsigned rn = (op >> 5) & 0x1F;
            unsigned imm = ((op >> 10) & 0xFFF) << 3;
            //printf("%llx: LDR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            if (!imm) continue;            // XXX not counted as true xref
            value[reg] = value[rn] + imm;    // XXX address, not actual value
        } else if ((op & 0xF9C00000) == 0xF9000000) {
            unsigned rn = (op >> 5) & 0x1F;
            unsigned imm = ((op >> 10) & 0xFFF) << 3;
            //printf("%llx: STR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            if (!imm) continue;            // XXX not counted as true xref
            value[rn] = value[rn] + imm;    // XXX address, not actual value
        } else if ((op & 0x9F000000) == 0x10000000) {
            signed adr = ((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8);
            //printf("%llx: ADR X%d, 0x%llx\n", i, reg, ((long long)adr >> 11) + i);
            value[reg] = ((long long)adr >> 11) + i;
        } else if ((op & 0xFF000000) == 0x58000000) {
            unsigned adr = (op & 0xFFFFE0) >> 3;
            //printf("%llx: LDR X%d, =0x%llx\n", i, reg, adr + i);
            value[reg] = adr + i;        // XXX address, not actual value
        } else if ((op & 0xF9C00000) == 0xb9400000) { // 32bit
            unsigned rn = (op >> 5) & 0x1F;
            unsigned imm = ((op >> 10) & 0xFFF) << 2;
            if (!imm) continue;            // XXX not counted as true xref
            value[reg] = value[rn] + imm;    // XXX address, not actual value
        }
    }
    return value[which];
}

static addr_t
calc64mov(const uint8_t *buf, addr_t start, addr_t end, int which)
{
    addr_t i;
    uint64_t value[32];

    memset(value, 0, sizeof(value));

    end &= ~3;
    for (i = start & ~3; i < end; i += 4) {
        uint32_t op = *(uint32_t *)(buf + i);
        unsigned reg = op & 0x1F;
        uint64_t newval;
        int rv = DecodeMov(op, value[reg], 0, &newval);
        if (rv == 0) {
            if (((op >> 31) & 1) == 0) {
                newval &= 0xFFFFFFFF;
            }
            value[reg] = newval;
        }
    }
    return value[which];
}

static addr_t
find_call64(const uint8_t *buf, addr_t start, size_t length)
{
    return step64(buf, start, length, INSN_CALL);
}

static addr_t
follow_call64(const uint8_t *buf, addr_t call)
{
    long long w;
    w = *(uint32_t *)(buf + call) & 0x3FFFFFF;
    w <<= 64 - 26;
    w >>= 64 - 26 - 2;
    return call + w;
}

static addr_t
follow_stub(const uint8_t *buf, addr_t call)
{
    addr_t stub = follow_call64(buf, call);
    if (!stub) return 0;

    if (monolithic_kernel) {
        return stub + kerndumpbase;
    }
    addr_t target_function_offset = calc64(buf, stub, stub+4*3, 16);
    if (!target_function_offset) return 0;

    return *(addr_t*)(buf + target_function_offset);
}

static addr_t
follow_cbz(const uint8_t *buf, addr_t cbz)
{
    return cbz + ((*(int *)(buf + cbz) & 0x3FFFFE0) << 10 >> 13);
}

static addr_t
remove_pac(addr_t addr)
{
    if (addr >= kerndumpbase) return addr;
    if (addr >> 56 == 0x80) {
        return (addr&0xffffffff) + kerndumpbase;
    }
    return addr |= 0xfffffff000000000;
}

static addr_t
follow_adrl(const uint8_t *buf, addr_t call)
{
    //Stage1. ADRP
    uint32_t op = *(uint32_t *)(buf + call);
//    printf("op: 0x%llx\n", op);
    
    uint64_t imm_hi_lo = (uint64_t)((op >> 3)  & 0x1FFFFC);
    imm_hi_lo |= (uint64_t)((op >> 29) & 0x3);
    if ((op & 0x800000) != 0) {
        // Sign extend
        imm_hi_lo |= 0xFFFFFFFFFFE00000;
    }
    
    // Build real imm
    uint64_t imm = imm_hi_lo << 12;
//    printf("imm: 0x%llx\n", imm);
    
    uint64_t ret = (call & ~0xFFF) + imm;
    
    //Stage2. ADD
    uint32_t op2 = *(uint32_t *)(buf + call + 4);
    uint64_t imm12 = (op2 & 0x3FFC00) >> 10;
        
    uint32_t shift = (op2 >> 22) & 1;
    if (shift == 1) {
        imm12 = imm12 << 12;
    }
    
    uint8_t regDst = (uint8_t)(op2 & 0x1F);
    uint8_t regSrc = (uint8_t)((op2 >> 5) & 0x1F);
//    printf("regSrc: 0x%x\n", imm12);
    
    ret += imm12;
//    printf("ret: 0x%llx\n", ret + kerndumpbase + imm12);
    
    return ret;
}

static addr_t
follow_adrpLdr(const uint8_t *buf, addr_t call)
{
    //Stage1. ADRP
    uint32_t op = *(uint32_t *)(buf + call);
    
    uint64_t imm_hi_lo = (uint64_t)((op >> 3)  & 0x1FFFFC);
    imm_hi_lo |= (uint64_t)((op >> 29) & 0x3);
    if ((op & 0x800000) != 0) {
        // Sign extend
        imm_hi_lo |= 0xFFFFFFFFFFE00000;
    }
    
    // Build real imm
    uint64_t imm = imm_hi_lo << 12;
//    printf("imm: 0x%llx\n", call, imm);
    
    uint64_t ret = (call & ~0xFFF) + imm;
    
    //Stage2. STR
    uint32_t op2 = *(uint32_t *)(buf + call + 4);
    uint64_t imm12 = ((op2 >> 10) & 0xFFF) << 3;
    ret += imm12;
    
    return ret;
}

/* kernel iOS10 **************************************************************/

#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#ifndef NOT_DARWIN
#include <mach-o/loader.h>
#else
#include "mach-o_loader.h"
#endif

#ifdef VFS_H_included
#define INVALID_HANDLE NULL
static FHANDLE
OPEN(const char *filename, int oflag)
{
    ssize_t rv;
    char buf[28];
    FHANDLE fd = file_open(filename, oflag);
    if (!fd) {
        return NULL;
    }
    rv = fd->read(fd, buf, 4);
    fd->lseek(fd, 0, SEEK_SET);
    if (rv == 4 && !MACHO(buf)) {
        fd = img4_reopen(fd, NULL, 0);
        if (!fd) {
            return NULL;
        }
        rv = fd->read(fd, buf, sizeof(buf));
        if (rv == sizeof(buf) && *(uint32_t *)buf == 0xBEBAFECA && __builtin_bswap32(*(uint32_t *)(buf + 4)) > 0) {
            return sub_reopen(fd, __builtin_bswap32(*(uint32_t *)(buf + 16)), __builtin_bswap32(*(uint32_t *)(buf + 20)));
        }
        fd->lseek(fd, 0, SEEK_SET);
    }
    return fd;
}
#define CLOSE(fd) (fd)->close(fd)
#define READ(fd, buf, sz) (fd)->read(fd, buf, sz)
static ssize_t
PREAD(FHANDLE fd, void *buf, size_t count, off_t offset)
{
    ssize_t rv;
    //off_t pos = fd->lseek(FHANDLE fd, 0, SEEK_CUR);
    fd->lseek(fd, offset, SEEK_SET);
    rv = fd->read(fd, buf, count);
    //fd->lseek(FHANDLE fd, pos, SEEK_SET);
    return rv;
}
#else
#define FHANDLE int
#define INVALID_HANDLE -1
#define OPEN open
#define CLOSE close
#define READ read
#define PREAD pread
#endif

static uint8_t *kernel = NULL;
static size_t kernel_size = 0;

static uint32_t arch_off = 0;

int
init_kernel(size_t (*kread)(uint64_t, void *, size_t), addr_t kernel_base, const char *filename)
{
    size_t rv;
    uint8_t buf[0x5000];
    unsigned i, j;
    const struct mach_header *hdr = (struct mach_header *)buf;
    FHANDLE fd = INVALID_HANDLE;
    const uint8_t *q;
    addr_t min = -1;
    addr_t max = 0;
    int is64 = 0;

    if (filename == NULL) {
        if (!kread || !kernel_base) {
            return -1;
        }
        rv = kread(kernel_base, buf, sizeof(buf));
        if (rv != sizeof(buf) || !MACHO(buf)) {
            return -1;
        }
    } else {
        fd = OPEN(filename, O_RDONLY);
        if (fd == INVALID_HANDLE) {
            return -1;
        }
        
        
        uint32_t magic;
        read(fd, &magic, 4);
        lseek(fd, 0, SEEK_SET);
        if (magic == 0xbebafeca) {
            struct fat_header fat;
            lseek(fd, sizeof(fat), SEEK_SET);
            struct fat_arch_64 arch;
            read(fd, &arch, sizeof(arch));
            arch_off = ntohl(arch.offset);
            lseek(fd, arch_off, SEEK_SET); // kerneldec gives a FAT binary for some reason
        }
        
        rv = READ(fd, buf, sizeof(buf));
        if (rv != sizeof(buf) || !MACHO(buf)) {
            CLOSE(fd);
            return -1;
        }
    }

    if (IS64(buf)) {
        is64 = 4;
    }
    q = buf + sizeof(struct mach_header) + is64;
//    printf("hdr->ncmds: %u\n", hdr->ncmds);
    for (i = 0; i < hdr->ncmds; i++) {
        const struct load_command *cmd = (struct load_command *)q;
//        printf("i: %d, cmd->cmd: 0x%x\n", i, cmd->cmd);
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = (struct segment_command_64 *)q;
            if(seg->filesize == 0) {
                q = q + cmd->cmdsize;
                continue;
            }
            if (min > seg->vmaddr && seg->vmsize > 0) {
                min = seg->vmaddr;
            }
            if (max < seg->vmaddr + seg->vmsize && seg->vmsize > 0) {
                max = seg->vmaddr + seg->vmsize;
            }
            if (!strcmp(seg->segname, "__TEXT_EXEC")) {
                xnucore_base = seg->vmaddr;
                xnucore_size = seg->filesize;
            } else if (!strcmp(seg->segname, "__PPLTEXT")) {
                ppl_base = seg->vmaddr;
                ppl_size = seg->filesize;
            } else if (!strcmp(seg->segname, "__PLK_TEXT_EXEC")) {
                prelink_base = seg->vmaddr;
                prelink_size = seg->filesize;
            } else if (!strcmp(seg->segname, "__TEXT")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__cstring")) {
                        cstring_base = sec[j].addr;
                        cstring_size = sec[j].size;
                    } else if (!strcmp(sec[j].sectname, "__os_log")) {
                        oslstring_base = sec[j].addr;
                        oslstring_size = sec[j].size;
                    } else if (!strcmp(sec[j].sectname, "__const")) {
                        const_base = sec[j].addr;
                        const_size = sec[j].size;
                    }
                }
            } else if (!strcmp(seg->segname, "__PRELINK_TEXT")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__text")) {
                        pstring_base = sec[j].addr;
                        pstring_size = sec[j].size;
                    }
                }
            } else if (!strcmp(seg->segname, "__DATA_CONST")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__const")) {
                        data_const_base = sec[j].addr;
                        data_const_size = sec[j].size;
                    }
                }
            } else if (!strcmp(seg->segname, "__DATA")) {
                const struct section_64 *sec = (struct section_64 *)(seg + 1);
                for (j = 0; j < seg->nsects; j++) {
                    if (!strcmp(sec[j].sectname, "__data")) {
                        data_base = sec[j].addr;
                        data_size = sec[j].size;
                    }
                }
            }
        } else if (cmd->cmd == LC_UNIXTHREAD) {
            uint32_t *ptr = (uint32_t *)(cmd + 1);
            uint32_t flavor = ptr[0];
            struct {
                uint64_t x[29];    /* General purpose registers x0-x28 */
                uint64_t fp;    /* Frame pointer x29 */
                uint64_t lr;    /* Link register x30 */
                uint64_t sp;    /* Stack pointer x31 */
                uint64_t pc;     /* Program counter */
                uint32_t cpsr;    /* Current program status register */
            } *thread = (void *)(ptr + 2);
            if (flavor == 6) {
                kernel_entry = thread->pc;
            }
        }
        
        q = q + cmd->cmdsize;
    }

    if (prelink_size == 0) {
        monolithic_kernel = true;
        prelink_base = xnucore_base;
        prelink_size = xnucore_size;
        pstring_base = cstring_base;
        pstring_size = cstring_size;
    }

    kerndumpbase = min;
    xnucore_base -= kerndumpbase;
    prelink_base -= kerndumpbase;
    cstring_base -= kerndumpbase;
    ppl_base -= kerndumpbase;
    pstring_base -= kerndumpbase;
    oslstring_base -= kerndumpbase;
    data_const_base -= kerndumpbase;
    data_base -= kerndumpbase;
    const_base -= kerndumpbase;
    kernel_size = max - min;

    if (filename == NULL) {
        kernel = malloc(kernel_size);
        if (!kernel) {
            return -1;
        }
        rv = kread(kerndumpbase, kernel, kernel_size);
        if (rv != kernel_size) {
            free(kernel);
            kernel = NULL;
            return -1;
        }

        kernel_mh = kernel + kernel_base - min;
    } else {
        kernel = calloc(1, kernel_size);
        if (!kernel) {
            CLOSE(fd);
            return -1;
        }

        q = buf + sizeof(struct mach_header) + is64;
        for (i = 0; i < hdr->ncmds; i++) {
            const struct load_command *cmd = (struct load_command *)q;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64 *seg = (struct segment_command_64 *)q;
                size_t sz = PREAD(fd, kernel + seg->vmaddr - min, seg->filesize, seg->fileoff);
                if (sz != seg->filesize) {
                    CLOSE(fd);
                    free(kernel);
                    kernel = NULL;
                    return -1;
                }
                if (!kernel_mh) {
                    kernel_mh = kernel + seg->vmaddr - min;
                }
                if (!strcmp(seg->segname, "__PPLDATA")) {
                    auth_ptrs = true;
                } else if (!strcmp(seg->segname, "__LINKEDIT")) {
                    kernel_delta = seg->vmaddr - min - seg->fileoff;
                }
            }
            q = q + cmd->cmdsize;
        }
        
        kernel += arch_off;

        CLOSE(fd);
    }
    return 0;
}

void
term_kernel(void)
{
    kernel -= arch_off;
    if (kernel != NULL) {
        free(kernel);
        kernel = NULL;
    }
}

addr_t
find_register_value(addr_t where, int reg)
{
    addr_t val;
    addr_t bof = 0;
    where -= kerndumpbase;
    if (where > xnucore_base) {
        bof = bof64(kernel, xnucore_base, where);
        if (!bof) {
            bof = xnucore_base;
        }
    } else if (where > prelink_base) {
        bof = bof64(kernel, prelink_base, where);
        if (!bof) {
            bof = prelink_base;
        }
    }
    val = calc64(kernel, bof, where, reg);
    if (!val) {
        return 0;
    }
    return val + kerndumpbase;
}

addr_t
find_reference(addr_t to, int n, enum text_bases text_base)
{
    addr_t ref, end;
    addr_t base = xnucore_base;
    addr_t size = xnucore_size;
    switch (text_base) {
        case text_xnucore_base:
            break;
        case text_prelink_base:
            if (prelink_base) {
                base = prelink_base;
                size = prelink_size;
            }
            break;
        case text_ppl_base:
            if (ppl_base != 0-kerndumpbase) {
                base = ppl_base;
                size = ppl_size;
            }
            break;
        default:
            printf("Unknown base %d\n", text_base);
            return 0;
            break;
    }
    if (n <= 0) {
        n = 1;
    }
    end = base + size;
    to -= kerndumpbase;
    do {
        ref = xref64(kernel, base, end, to);
        if (!ref) {
            return 0;
        }
        base = ref + 4;
    } while (--n > 0);
    return ref + kerndumpbase;
}

addr_t
find_strref(const char *string, int n, enum string_bases string_base, bool full_match, bool ppl_base)
{
    uint8_t *str;
    addr_t base;
    addr_t size;
    enum text_bases text_base = ppl_base?text_ppl_base:text_xnucore_base;

    switch (string_base) {
        case string_base_const:
            base = const_base;
            size = const_size;
            break;
        case string_base_data:
            base = data_base;
            size = data_size;
            break;
        case string_base_oslstring:
            base = oslstring_base;
            size = oslstring_size;
            break;
        case string_base_pstring:
            base = pstring_base;
            size = pstring_size;
            text_base = text_prelink_base;
            break;
        case string_base_cstring:
        default:
            base = cstring_base;
            size = cstring_size;
            break;
    }
//    printf("base: 0x%llx, size: 0x%llx\n", base, size);
    addr_t off = 0;
    while ((str = boyermoore_horspool_memmem(kernel + base + off, size - off, (uint8_t *)string, strlen(string)))) {
        // Only match the beginning of strings
        if ((str == kernel + base || *(str-1) == '\0') && (!full_match || strcmp((char *)str, string) == 0))
            break;
        off = str - (kernel + base) + 1;
    }
    if (!str) {
        return 0;
    }
    return find_reference(str - kernel + kerndumpbase, n, text_base);
}

#ifndef NOT_DARWIN
#include <mach-o/nlist.h>
#else
#include "mach-o_nlist.h"
#endif


addr_t
find_symbol(const char *symbol)
{
    //XXX Temporary disabled
    return 0;
    
    if (!symbol) {
        return 0;
    }
    
    unsigned i;
    const struct mach_header *hdr = kernel_mh;
    const uint8_t *q;
    int is64 = 0;

    if (IS64(hdr)) {
        is64 = 4;
    }

/* XXX will only work on a decrypted kernel */
    if (!kernel_delta) {
        return 0;
    }

    /* XXX I should cache these.  ohwell... */
    q = (uint8_t *)(hdr + 1) + is64;
    for (i = 0; i < hdr->ncmds; i++) {
        const struct load_command *cmd = (struct load_command *)q;
        if (cmd->cmd == LC_SYMTAB) {
            const struct symtab_command *sym = (struct symtab_command *)q;
            const char *stroff = (const char *)kernel + sym->stroff + kernel_delta;
            if (is64) {
                uint32_t k;
                const struct nlist_64 *s = (struct nlist_64 *)(kernel + sym->symoff + kernel_delta);
                for (k = 0; k < sym->nsyms; k++) {
                    if (s[k].n_type & N_STAB) {
                        continue;
                    }
                    if (s[k].n_value && (s[k].n_type & N_TYPE) != N_INDR) {
                        if (!strcmp(symbol, stroff + s[k].n_un.n_strx)) {
                            /* XXX this is an unslid address */
                            return s[k].n_value;
                        }
                    }
                }
            }
        }
        q = q + cmd->cmdsize;
    }
    return 0;
}

//XXXXX
addr_t find_cdevsw(void)
{
//    MOV             X1, #0
//    com.apple.kernel:__text:FFFFFFF0081FB580                 MOV             X2, #0
//    com.apple.kernel:__text:FFFFFFF0081FB584                 MOV             W3, #0
//    com.apple.kernel:__text:FFFFFFF0081FB588                 MOV             W4, #1
//    com.apple.kernel:__text:FFFFFFF0081FB58C                 MOV             X5, #0
//    01 00 80 D2
//    02 00 80 D2
//    03 00 80 52
//    24 00 80 52
//    05 00 80 D2
    //1. opcode
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if ((k[0] & 0xff000000) == 0xb4000000   //cbz
            && k[1] == 0xd2800001   //mov x1, #0
            && k[2] == 0xd2800002   //mov x2, #0
            && k[3] == 0x52800003   //mov w3, #0
            && k[4] == 0x52800024   //mov w4, #1
            && k[5] == 0xd2800005  /* mov x5, #0 */) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Step into High address, and find adrp opcode.
    addr = step64(kernel, addr, 0x80, INSN_ADRP);
    if (!addr) {
        return 0;
    }
    //3. Get label from adrl opcode.
    addr = follow_adrl(kernel, addr);
    
    return addr + kerndumpbase;
}

addr_t find_gPhysBase(void)
{
    //_invalidate_icache64
    //1. Find opcode (5F 00 00 71 20 01 00 54 [ADRL 8 bytes] 42 00 40 F9 00 00 02 CB)
    //    cmp w2, #0
    //    b.eq #0x28
    //    adrl *
    //    ldr x2, [x2]
    //    sub x0, x0, x2
    
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if (k[0] == 0x7100005F
            && k[1] == 0x54000120
            && (k[2] & 0x9F000000) == 0x90000000    //adrp
            && (k[3] & 0xFF800000) == 0x91000000    //add
            && k[4]== 0xF9400042
            && k[5] == 0xCB020000) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Get label from [ADRL 8 bytes]
    addr = follow_adrl(kernel, addr + 8);
    
    return addr + kerndumpbase;
}

addr_t find_gPhysSize(void)
{
    //_invalidate_icache64
    //1. Find opcode ([STR 4 bytes] 08 01 09 8B 08 C5 72 92 08 01 09 CB)
    //    str *
    //    add x8, x8, x9
    //    and x8, x8, #0xffffffffffffc000
    //    sub x8, x8, x9
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if ((k[0] & 0xFFC00000) == 0xF9000000   //str
            && k[1] == 0x8b090108
            && k[2] == 0x9272c508
            && k[3] == 0xcb090108) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return find_gPhysBase() + 8;
    
    //2. Get label from [ADRL 8 bytes]
    addr = follow_adrpLdr(kernel, addr + 0x18);
    
    return addr + kerndumpbase;
}

addr_t find_gVirtBase(void)
{
    //_invalidate_icache64
    //1. Find opcode (5F 00 00 71 20 01 00 54 [ADRL 8 bytes] 42 00 40 F9 00 00 02 CB) + [ADRL            X2, _gVirtBase]
    //    cmp w2, #0
    //    b.eq #0x28
    //    adrl *
    //    ldr x2, [x2]
    //    sub x0, x0, x2
    
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if (k[0] == 0x7100005F
            && k[1] == 0x54000120
            && (k[2] & 0x9F000000) == 0x90000000    //adrp
            && (k[3] & 0xFF800000) == 0x91000000    //add
            && k[4]== 0xF9400042
            && k[5] == 0xCB020000) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Get label from [ADRL 8 bytes]
    addr = follow_adrl(kernel, addr + 0x18);
    
    return addr + kerndumpbase;
}

addr_t find_perfmon_dev_open_2(void)
{
//__TEXT_EXEC:__text:FFFFFFF007324700 3F 01 08 6B                 CMP             W9, W8
//__TEXT_EXEC:__text:FFFFFFF007324704 E1 01 00 54                 B.NE            loc_FFFFFFF007324740
//__TEXT_EXEC:__text:FFFFFFF007324708 A8 5E 00 12                 AND             W8, W21, #0xFFFFFF
//__TEXT_EXEC:__text:FFFFFFF00732470C 1F 05 00 71                 CMP             W8, #1
//__TEXT_EXEC:__text:FFFFFFF007324710 68 02 00 54                 B.HI            loc_FFFFFFF00732475C
    
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if (k[0] == 0x53187ea8  //lsr w8, w21, #0x18
            && (k[2] & 0xffc0001f) == 0xb9400009   // ldr w9, [Xn, n]
            && k[3] == 0x6b08013f    //cmp w9, w8 v
            && (k[4] & 0xff00001f) == 0x54000001    //b.ne *
            && (k[5] & 0xfffffc00) == 0x12005c00    //and Wn, Wn, 0xfffff v
            && k[6] == 0x7100051f   //cmp w8, #1 v
            && (k[7] & 0xff00001f) == 0x54000008    /* b.hi * v */) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Find begin of address(bof64)
    addr = bof64(kernel, xnucore_base, addr);
    if (!addr) {
        return 0;
    }
    
    //3. check PACIBSP (7F 23 03 D5)
    uint32_t op = *(uint32_t *)(kernel + addr - 4);
    if(op == 0xD503237F) {
        addr -= 4;
    }
    
    return addr + kerndumpbase;
}

addr_t find_perfmon_dev_open(void)
{
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if ((k[0] & 0xff000000) == 0x34000000    //cbz w*
            && k[1] == 0x52800300    //mov W0, #0x18
            && (k[2] & 0xff000000) == 0x14000000    //b*
            && k[3] == 0x52800340   //mov w0, #0x1A
            && (k[4] & 0xff000000) == 0x14000000    /* b* */) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return find_perfmon_dev_open_2();
    
    //2. Find begin of address(bof64)
    addr = bof64(kernel, xnucore_base, addr);
    if (!addr) {
        return 0;
    }
    
    //3. check PACIBSP (7F 23 03 D5)
    uint32_t op = *(uint32_t *)(kernel + addr - 4);
    if(op == 0xD503237F) {
        addr -= 4;
    }
    
    return addr + kerndumpbase;
}

addr_t find_perfmon_devices(void)
{
    
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if (k[0] == 0x6b08013f    //cmp w9, w8
            && (k[1] & 0xff00001f) == 0x54000001    //b.ne *
            && k[2] == 0x52800028    //mov w8, #1
            && k[3] == 0x5280140a   /* mov w10, #0xa0 */) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Step into High address, and find adrp opcode.
    addr = step64(kernel, addr, 0x18, INSN_ADRP);
    if (!addr) {
        return 0;
    }
    //3. Get label from adrl opcode.
    addr = follow_adrl(kernel, addr);
    
    return addr + kerndumpbase;
}

addr_t find_ptov_table(void)
{
    //1. Find opcode (49 00 80 52 04 00 00 14 09 00 80 D2 02 00 00 14)
    uint32_t bytes[] = {
        0x52800049,
        0x14000004,
        0xd2800009,
        0x14000002
    };
    
    uint64_t addr = (uint64_t)boyermoore_horspool_memmem((unsigned char *)((uint64_t)kernel + xnucore_base), xnucore_size, (const unsigned char *)bytes, sizeof(bytes));
    
    if (!addr) {
        return 0;
    }
    addr -= (uint64_t)kernel;
    
    //2. Step into High address, and find adrp opcode.
    addr = step64(kernel, addr, 0x20, INSN_ADRP);
    if (!addr) {
        return 0;
    }
    //3. Get label from adrl opcode.
    addr = follow_adrl(kernel, addr);
    
    return addr + kerndumpbase;
}

addr_t find_vn_kqfilter_2(void)
{
    //1F 05 00 71
    //60 02 00 54
    //1F 11 00 71
    //E0 0C 00 54
    //1F 1D 00 71
    
    bool found = false;
    uint64_t addr = 0;
    addr_t off;
    uint32_t *k;
    k = (uint32_t *)(kernel + xnucore_base);
    for (off = 0; off < xnucore_size - 4; off += 4, k++) {
        if (k[0] == 0x7100051f  //cmp w8, #1
            && (k[1] & 0xff00001f) == 0x54000000    //b.eq *
            && k[2] == 0x7100111f    //cmp w8, #4
            && (k[3] & 0xff00001f) == 0x54000000  //b.eq *
            && k[4] == 0x71001d1f    /* cmp w8, #7 */) {
            addr = off + xnucore_base;
            found = true;
        }
    }
    if(!found)
        return 0;
    
    //2. Find begin of address(bof64)
    addr = bof64(kernel, xnucore_base, addr);
    if (!addr) {
        return 0;
    }
    
    //3. check PACIBSP (7F 23 03 D5)
    uint32_t op = *(uint32_t *)(kernel + addr - 4);
    if(op == 0xD503237F) {
        addr -= 4;
    }
    
    return addr + kerndumpbase;
}

addr_t find_vn_kqfilter(void)
{
    //1. Find opcode (01 00 80 D2 E0 03 15 AA E2 03 13 AA E3 03 14 AA)
    uint32_t bytes[] = {
        0xD2800001,
        0xAA1503E0,
        0xAA1303E2,
        0xAA1403E3
    };
    
    uint64_t addr = (uint64_t)boyermoore_horspool_memmem((unsigned char *)((uint64_t)kernel + xnucore_base), xnucore_size, (const unsigned char *)bytes, sizeof(bytes));
    
    if (!addr) {
        return find_vn_kqfilter_2();
    }
    addr -= (uint64_t)kernel;
    
    //2. Find begin of address(bof64)
    addr = bof64(kernel, xnucore_base, addr);
    if (!addr) {
        return 0;
    }
    
    //3. check PACIBSP (7F 23 03 D5)
    uint32_t op = *(uint32_t *)(kernel + addr - 4);
    if(op == 0xD503237F) {
        addr -= 4;
    }
    
    return addr + kerndumpbase;
}

addr_t find_proc_object_size(void) {
    //footprint
    //_proc_task: ADRP            X8, #qword_FFFFFFF00A3091E8@PAGE
    //qword_FFFFFFF00A3091E8 DCQ 0x530
    
    //E0 03 15 AA
    //E1 04 81 52
    //02 01 80 52
    //03 11 80 52
    uint32_t bytes[] = {
        0xAA1503E0,
        0x528104E1,
        0x52800102,
        0x52801103
    };
    
    uint64_t addr = (uint64_t)boyermoore_horspool_memmem((unsigned char *)((uint64_t)kernel + xnucore_base), xnucore_size, (const unsigned char *)bytes, sizeof(bytes));
    
    if (!addr) {
        return 0;
    }
    addr -= (uint64_t)kernel;
    
    //2. Step into High address, and find adrp opcode.
    addr = step64(kernel, addr, 0x20, INSN_ADRP);
    if (!addr) {
        return 0;
    }
    
    //3. Get label from adrl opcode.
    addr = follow_adrpLdr(kernel, addr);
    
    //4. Get val from addr
    uint64_t val = *(uint64_t *)(kernel + addr);
    
    return val;
}
//XXXXX
