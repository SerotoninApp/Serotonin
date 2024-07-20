//
//  krw.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "krw.h"
#include "offsets.h"
#include "libkfd.h"
//#include "mdc/helpers.h"
#include "memoryControl.h"
#include "kpf/patchfinder.h"
#include "../jbserver/info.h"
#include "../jbserver/primitives_external.h"
#include <xpc/xpc.h>


uint64_t _kfd = 0;
uint64_t unsign_kptr(uint64_t pac_kaddr) {
    if ((pac_kaddr & 0xFFFFFF0000000000) == 0xFFFFFF0000000000) {
        return pac_kaddr;
    }
    if(T1SZ_BOOT != 0) {
        return pac_kaddr |= ~((1ULL << (64U - T1SZ_BOOT)) - 1U);
    }
    return pac_kaddr;
}

uint64_t kUNSIGN_PTR(uint64_t pac_kaddr) {
    if ((pac_kaddr & 0xFFFFFF0000000000) == 0xFFFFFF0000000000) {
        return pac_kaddr;
    }
    if(T1SZ_BOOT != 0) {
        return pac_kaddr |= ~((1ULL << (64U - T1SZ_BOOT)) - 1U);
    }
    return pac_kaddr;
}

__attribute__ ((optnone)) uint64_t do_kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method, size_t headroom, bool use_headroom)
{
    if (use_headroom) {
        size_t STATIC_HEADROOM = (headroom * (size_t)1024 * (size_t)1024);
        uint64_t* memory_hog = NULL;
        size_t pagesize = sysconf(_SC_PAGESIZE);
        size_t memory_avail = os_proc_available_memory();
        size_t hog_headroom = STATIC_HEADROOM + puaf_pages * pagesize;
        size_t memory_to_hog = memory_avail > hog_headroom ? memory_avail - hog_headroom: 0;
        int32_t old_memory_limit = 0;
        memorystatus_memlimit_properties2_t mmprops;
        if (hasEntitlement(CFSTR("com.apple.private.memorystatus"))) {
            uint32_t new_memory_limit = (uint32_t)(getPhysicalMemorySize() / UINT64_C(1048576)) * 2;
            int ret = memorystatus_control(MEMORYSTATUS_CMD_GET_MEMLIMIT_PROPERTIES, getpid(), 0, &mmprops, sizeof(mmprops));
            if (ret == 0) {
                // print_i32(mmprops.v1.memlimit_active);
                old_memory_limit = mmprops.v1.memlimit_active;
                ret = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), new_memory_limit, NULL, 0);
                if (ret == 0) {
                    print_success("The memory limit for pid %d has been set to %u MiB successfully", getpid(), new_memory_limit);
                } else {
                    print_warning("Failed to set memory limit: %d (%s)", errno, strerror(errno));
                }
            } else {
                print_warning("could not get current memory limits");
            }
        }
        if (memory_avail > hog_headroom) {
            memory_hog = malloc(memory_to_hog);
            if (memory_hog != NULL) {
                for (uint64_t i = 0; i < memory_to_hog / sizeof(uint64_t); i++) {
                    memory_hog[i] = 0x4141414141414141;
                }
            }
            print_message("Filled up hogged memory with A's");
        } else {
            print_message("Did not hog memory because there is too little free memory");
        }
        print_message("Performing kopen");
        _kfd = kopen(puaf_pages, puaf_method, kread_method, kwrite_method);

        if (memory_hog) free(memory_hog);
        if (old_memory_limit) {
            // set the limit back because it affects os_proc_available_memory
            int ret = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), old_memory_limit, NULL, 0);
            if (ret == 0) {
                print_success("[memoryHogger] The memory limit for pid %d has been set to %u MiB successfully", getpid(), old_memory_limit);
            } else {
                print_warning("[memoryHogger] Failed to set memory limit: %d (%s)", errno, strerror(errno));
            }
        }
    } else {
        _kfd = kopen(puaf_pages, puaf_method, kread_method, kwrite_method);
    }
    
    
    _offsets_init();
    // set gsystemInfo
    gSystemInfo.kernelConstant.slide = ((struct kfd *)_kfd)->perf.kernel_slide;
    return _kfd;
}

void do_kclose(void)
{
    kclose((u64)(_kfd));
}

void early_kread(uint64_t kfd, u64 kaddr, void* uaddr, u64 size)
{
    kread((u64)(kfd), kaddr, uaddr, size);
}

uint64_t early_kread64(uint64_t kfd, uint64_t where) {
    uint64_t out;
    kread((u64)(kfd), where, &out, sizeof(uint64_t));
    return out;
}

uint32_t early_kread32(uint64_t kfd, uint64_t where) {
    return early_kread64(kfd, where) & 0xffffffff;
}

void early_kreadbuf(uint64_t kfd, uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = early_kread32(kfd, curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}


void do_kread(u64 kaddr, void* uaddr, u64 size)
{
    kread(_kfd, kaddr, uaddr, size);
}

void do_kwrite(void* uaddr, u64 kaddr, u64 size)
{
    kwrite(_kfd, uaddr, kaddr, size);
}

uint64_t get_kslide(void) {    
    return ((struct kfd*)_kfd)->perf.kernel_slide;
}

uint64_t get_kernproc(void) {
    return ((struct kfd*)_kfd)->info.kaddr.kernel_proc;
}

uint64_t get_selftask(void) {
    return ((struct kfd*)_kfd)->info.kaddr.current_task;
}

uint64_t get_selfpmap(void) {
    return ((struct kfd*)_kfd)->info.kaddr.current_pmap;
}

uint64_t get_kerntask(void) {
    return ((struct kfd*)_kfd)->info.kaddr.kernel_task;
}


uint8_t kread8(uint64_t where) {
    uint8_t out;
    kread(_kfd, where, &out, sizeof(uint8_t));
    return out;
}
uint32_t kread16(uint64_t where) {
    uint16_t out;
    kread(_kfd, where, &out, sizeof(uint16_t));
    return out;
}
uint32_t kread32(uint64_t where) {
    uint32_t out;
    kread(_kfd, where, &out, sizeof(uint32_t));
    return out;
}
uint64_t kread64(uint64_t where) {
    uint64_t out;
    kread(_kfd, where, &out, sizeof(uint64_t));
    return out;
}

//Thanks @jmpews
uint64_t kread64_smr(uint64_t where) {
    uint64_t value = unsign_kptr(kread64(where));
    if((value & 0x400000000000) != 0)
        value &= 0xFFFFFFFFFFFFFFE0;
    return value;
}

uint64_t kread_smrptr(uint64_t where) {
    uint64_t value = unsign_kptr(kread64(where));
    if((value & 0x400000000000) != 0)
        value &= 0xFFFFFFFFFFFFFFE0;
    return value;
}


// uint64_t kread_smrptr(uint64_t va)
// {
// 	uint64_t value = kread_ptr(va);

// 	uint64_t bits = (kconstant(smrBase) << (62-kconstant(T1SZ_BOOT)));

// 	uint64_t case1 = 0xFFFFFFFFFFFFC000 & ~bits;
// 	uint64_t case2 = 0xFFFFFFFFFFFFFFE0 & ~bits;

// 	if ((value & bits) == 0) {
// 		if (value) {
// 			value = (value & case1) | bits;
// 		}
// 	}
// 	else {
// 		value = (value & case2) | bits;
// 	}

// 	return value;
// }

void kwrite8(uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(where+1);
    _buf[2] = kread8(where+2);
    _buf[3] = kread8(where+3);
    _buf[4] = kread8(where+4);
    _buf[5] = kread8(where+5);
    _buf[6] = kread8(where+6);
    _buf[7] = kread8(where+7);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite16(uint64_t where, uint16_t what) {
    u16 _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(where+2);
    _buf[2] = kread16(where+4);
    _buf[3] = kread16(where+6);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite32(uint64_t where, uint32_t what) {
    u32 _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(where+4);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}
void kwrite64(uint64_t where, uint64_t what) {
    u64 _buf[1] = {};
    _buf[0] = what;
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

uint64_t do_vtophys(uint64_t what) {
    return vtophys((struct kfd*)(_kfd), what);
}

uint64_t do_phystokv(uint64_t what) {
    return phystokv((struct kfd*)(_kfd), what);
}

uint64_t kread64_ptr(uint64_t kaddr) {
    uint64_t ptr = kread64(kaddr);
    if ((ptr >> 55) & 1) {
        return unsign_kptr(ptr);
    }

    return ptr;
}

uint64_t kread_ptr(uint64_t va)
{
	return unsign_kptr(kread64(va));
}

int kreadbuf(uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = kread32(curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
    return 0;
}

int kwritebuf(uint64_t where, const void *buf, size_t size)
{
    if (size == 1) {
        kwrite8(where, *(uint8_t*)buf);
    }
    else if (size == 2) {
        kwrite16(where, *(uint16_t*)buf);
    }
    else if (size == 4) {
        kwrite32(where, *(uint32_t*)buf);
    }
    else {
        if (size >= UINT16_MAX) {
            for (uint64_t start = 0; start < size; start += UINT16_MAX) {
                uint64_t sizeToUse = UINT16_MAX;
                if (start + sizeToUse > size) {
                    sizeToUse = (size - start);
                }
                kwrite((u64)(_kfd), (void*)((uint8_t *)buf)+start, where+start, sizeToUse);
            }
        } else {
            kwrite((u64)(_kfd), (void*)buf, where, size);
        }
    }
    return 0;
}