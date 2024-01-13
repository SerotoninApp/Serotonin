//===----------------------------- sep ----------------------------===//
//
//                         The Libhelper Project
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  Copyright (C) 2020, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//
/**
 *  Adapated from original sepsplit.c by xerub. 
 *  -------------------------------------------
 * 
 *  SEP firmware split tool
 *
 *  Copyright (c) 2017 xerub
 */

#include "../libhelper/img4/sep.h"

uint8_t     *kernel         = MAP_FAILED;
size_t       kernel_size    = 0;
static int   kernel_fd      = -1;

#define IS64(image) (*(uint8_t *)(image) & 1)
#define MACHO(p) ((*(unsigned int *)(p) & ~1) == 0xfeedface)

/*****************************************************************
******************************************************************/

/**
 *  The whole file interaction here needs to be implemented into file_t
 *  in some way, so the file can still be mmaped into a buffer/pointer
 *  rather than using file_GeT_bytes () all the time.
 * 
 */
static
int write_file (const char *name, const void *buf, size_t size)
{
    int fd;
    size_t sz;
    fd = open (name, O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd < 0) return -1;
    sz = write (fd, buf, size);
    close (fd);
    return (sz == size) ? 0 : -1;
}
/*****************************************************************
******************************************************************/

static
size_t calc_size (const uint8_t *ptr, size_t sz)
{
    //  Create a struct for the mach header, and assume that the mem region
    //  at `ptr` is a Mach-O header - until we can check it. Also create a 
    //  pointer to, what should be, the start of the load commands relative
    //  to the header pointer.
    //
    //  Because of some strange stuff that Apple does, the Mach-O headers of
    //  the SEP components are 32bit, despite the magic being 0xfeedface and
    //  the load/segment commands being 64bit. The only difference between
    //  the 64bit and 32bit headers are that the 64bit has a reserved uint32_t
    //  at the end, so the pointer to the Load Commands is thrown off by a 
    //  few bytes.
    //
    //  Basically, libhelper has part-32bit support, in the sense that it
    //  can recognise 32bit header and you can parse a 32bit header.
    //
    unsigned i;
    const mach_header_32_t *header = (mach_header_32_t *) ptr;
    const uint8_t *lc_ptr = ptr + sizeof(mach_header_32_t);
    size_t end, tsize = 0;


    //  Check three things: If the size of the data at `ptr` is less thab
    //  1024 bytes, it's most likely not a Mach-O, so ignore it.
    //
    //  Then check if it is actually a Mach-O, and then if its 64bit.
    //
    if (sz < 1024) return 0;

    if (!MACHO(ptr)) return 0;

    if (IS64(ptr)) {
        lc_ptr += 4;
    } else {
        errorf ("Cannot handle 32bit\n");
        exit (0);
    }


    //  We need to work out the full size of the file, so we work out how many
    //  load commands there are, how big each segment is, then add that to the
    //  size of the header and we have our file size.
    //
    for (i = 0; i < header->ncmds; i++) {
        const mach_load_command_t *cmd = (mach_load_command_t *) lc_ptr;

        //  Because SEPOS is 64bit, not 32bit, I'm not including checking for
        //  32bit segments, well, atleast not until they're implemented in
        //  libhelper-macho.
        //
        if (cmd->cmd == LC_SEGMENT) warningf ("Cannot handle 32bit Segments");
        if (cmd->cmd == LC_SEGMENT_64) {
            const mach_segment_command_64_t *seg = (mach_segment_command_64_t *) lc_ptr;
            end = seg->fileoff + seg->filesize;
            if (tsize < end) {
                tsize = end;
            }
        }

        //  Move the Load Command pointer so we can parse
        //  the next command.
        //
        lc_ptr += cmd->cmdsize;
    }

    return tsize;
}

static
size_t restore_linkedit (uint8_t *ptr, size_t size)
{
    unsigned i;
    mach_header_32_t *hdr = (mach_header_32_t *) ptr;
    uint64_t min = -1;
    uint64_t delta = 0;
    int is64 = 0;
    uint8_t *lc_ptr;

    //  Similar checks as in calc_size, check whether the ptr is a Mach-O,
    //  that the size is less than 4096 bytes, and that it is 64bit
    //
    if (size < 4096) return -1;
    if (!MACHO (ptr)) return -1;
    if (IS64 (ptr)) is64 = 4;


    //  Set lc_ptr to the end of the mach header, plus it's current value and
    //  is64. Then go through each load command until we find a segment command,
    //
    //  Look for the __PAGEZERO segments, then set the min which is used when
    //  restoring the __LINKEDIT segment.
    //
    lc_ptr = ptr + sizeof (mach_header_32_t) + is64;
    for (i = 0; i < hdr->ncmds; i++) {
        const mach_load_command_t *cmd = (mach_load_command_t *) lc_ptr;

        //  If the segment is 32bit, ignore it.
        //
        if (cmd->cmd == LC_SEGMENT) warningf ("Cannot handle 32bit");

        if (cmd->cmdsize == LC_SEGMENT_64) {
            const mach_segment_command_64_t *seg = (mach_segment_command_64_t *) lc_ptr;
            if (strcmp (seg->segname, "__PAGEZERO") && min > seg->vmaddr) {
                min = seg->vmaddr;
            }
        }
        lc_ptr += cmd->cmdsize;
    }


    //  Now this is the restoring the __LINKEDIT segment part. 
    //
    //  Calculates a delta as the following:
    //      delta = segment->vmaddr - min - segment->fileoffset.
    //
    //  Then, add that to the segment file offset, and the symbol table string
    //  table offset and symbol table offset.
    //
    lc_ptr = ptr + sizeof (mach_header_32_t) + is64;
    for (i = 0; i < hdr->ncmds; i++) {
        const mach_load_command_t *cmd = (mach_load_command_t *) lc_ptr;

        //  If the segment is 32bit, ignore it.
        //
        if (cmd->cmd == LC_SEGMENT) warningf ("Cannot handle 32bit");

        if (cmd->cmd == LC_SEGMENT_64) {
            mach_segment_command_64_t *seg = (mach_segment_command_64_t *) lc_ptr;
            if (!strcmp (seg->segname, "__LINKEDIT")) {
                delta = seg->vmaddr - min - seg->fileoff;
                seg->fileoff += delta;
            }
        }

        if (cmd->cmd == LC_SYMTAB) {
            mach_symtab_command_t *sym = (mach_symtab_command_t *) lc_ptr;
            if (sym->stroff) sym->stroff += delta;
            if (sym->symoff) sym->symoff += delta;
        }
        lc_ptr += cmd->cmdsize;
    }

    return 0;
}

static
int restore_file (unsigned index, const unsigned char *buf, size_t size, int restore)
{
    int      rv;
    void    *tmp;
    char     name[256];
    char     tail[12 + 1];


    //
    //
    if (index == 1 && size > 4096) {
        unsigned char *toc = bh_memmem (buf + size - 4096, 4096, (unsigned char *) "SEPOS       ", 12);
        if (toc) {
            unsigned char *ptr = bh_memmem (toc + 1, 64, (unsigned char *) "SEP", 3);
            if (ptr) {
                sizeof_sepapp = ptr - toc;
            }
            apps = (struct sepapp_t *) (toc - offsetof (struct sepapp_t, name));
        }
    }


    //
    //
    if (apps && buf > (unsigned char *) apps) {
        char *ptr;
        memcpy (tail, apps->name, 12);
        for (ptr = tail + 12; ptr > tail && ptr[-1] == ' '; ptr--) {
            continue;
        }

        *ptr = '\0';
        printf ("%-12s phys 0x%llx, virt 0x%x, size 0x%x, entry 0x%x\n", tail, apps->phys, apps->virt, apps->size, apps->entry);
        apps = (struct sepapp_t *) ((char *) apps + sizeof_sepapp);

    } else {

        if (index == 0) {
            strcpy (tail, "boot");
            printf ("Parsed: SEP_%s\n", tail);
        } else if (index == 1) {
            strcpy (tail, "kernel");
            printf ("Parsed: SEP_%s\n", tail);
        } else {
            *tail = '\0';
            printf ("Parsed: SEP_MachO_%d\n", index);
        }
    }

    snprintf (name, sizeof(name), "sepdump%02u_%s", index, tail);
    if (!restore) {
        return write_file (name, buf, size);
    }

    tmp = malloc (size);
    if (!tmp) {
        return -1;
    }

    memcpy (tmp, buf, size);
    restore_linkedit (tmp, size);
    rv = write_file (name, tmp, size);
    free (tmp);

    return rv;

}

void sep_split_init (char *filename)
{
    // Try to open and load the file into 'kernel_fd'
    kernel_fd = open (filename, O_RDONLY);
    if (kernel_fd < 0) {
        errorf ("There was a problem opening the file: %s\n", filename);
        exit (0);
    }

    // get the size of the file
    kernel_size = lseek (kernel_fd, 0, SEEK_END);

    // mmap the file into the kernel pointer
    kernel = mmap (NULL, kernel_size, PROT_READ, MAP_PRIVATE, kernel_fd, 0);
    if (kernel == MAP_FAILED) {
        close (kernel_fd);
        errorf ("Could not map the file.\n");
        exit (0);
    }

    printf ("[*] File loaded okay. Attempting to identify Mach-O regions...\n");
    
    //  Now we start trying to split the sepos firmware. There are 9 areas
    //  we need to extract, the first being the bootloader, the second being
    //  the L4 Kernel Mach-O and the other 7 being application Mach-O's for
    //  SEPOS.
    //
    int restore = 1;
    size_t i, last = 0;
    unsigned j = 0;
    for (i = 0; i < kernel_size; i += 4) {

        //  Each loop jumps 4 bytes, the length of a Mach-O magic. We are searching
        //  for the start of a Mach-O header, which looks like 0xCDFAEDFE. The 'kernel'
        //  points to the current part of the mapped file that we want to check for
        //  a Mach-O.
        //
        //  Basically, if `kernel + i` points to a valid Mach-O header, then we have
        //  found one of the SEPOS componenents. If the pointer is valid, calc_size
        //  will return a valid size of the Mach-O so we can load it from our calculated
        //  offset.
        //
        size_t sz = calc_size (kernel + i, kernel_size - i);
        if (sz) {
            restore_file(j++, kernel + last, i - last, restore);

            last = i;
            i += sz - 4;
        }
    }
    restore_file(j, kernel + last, i - last, restore);

}
