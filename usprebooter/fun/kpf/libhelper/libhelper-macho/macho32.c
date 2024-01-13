//===--------------------------- libhelper ----------------------------===//
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
//	Copyright (C) 2020, Is This On?, @h3adsh0tzz
//
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#include "../libhelper/libhelper.h"
#include "../libhelper/libhelper-macho.h"

#include "version.h"

//===-----------------------------------------------------------------------===//
/*-- Mach-O 32 bit                      									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  This file contains 32 bit specific parsing of Mach-O files. Generic Mach-O
 *  parsing and 32 bit parsing can be found in macho.c and macho32.c respectively.
 * 
 */



/**
 *  Load a 32-bit Mach-O from a given data buffer.
 * 
 */
macho_32_t *macho_32_create_from_buffer (unsigned char *data)
{
    // zero out some memory for macho.
    macho_32_t *macho = calloc (1, sizeof (macho_32_t));

    macho->data = (uint8_t *) data;
    macho->offset = 0;

    // try to load the header
    macho->header = (mach_header_32_t *) mach_header_load ((macho_t *) macho);
    if (!macho->header) {
        errorf ("macho_32_create_from_buffer() mach header is NULL\n");
        return NULL;
    }

    uint32_t offset = sizeof (mach_header_32_t);
    HSList *scmds = NULL, *lcmds = NULL, *dylibs = NULL;

    // search through every command
    for (int i = 0; i < (int) macho->header->ncmds; i++) {
        mach_load_command_info_t *lc = mach_load_command_info_load ((const char *) macho->data, offset);
        uint32_t type = lc->lc->cmd;

        debugf ("lc: %d, lcsize: %d\n", lc->lc->cmd, lc->lc->cmdsize);

        /**
         *  This follows the same format as in macho64.c, so only different things will
         *  be documented.
         */
        if (type == LC_SEGMENT) {
            // create a segment info struct, which requires 32bit specific functions.
            mach_segment_info_32_t *seginf = mach_segment_info_32_load (macho->data, offset);
            if (seginf == NULL) {
                warningf ("macho_32_create_from_buffer(): failed to load LC_SEGMENT at offset: 0x%08x\n", offset);
                continue;
            }

            scmds = h_slist_append (scmds, seginf);

        } else if (type == LC_ID_DYLIB || type == LC_LOAD_DYLIB ||
                   type == LC_LOAD_WEAK_DYLIB || type == LC_REEXPORT_DYLIB) {

            /**
             * 
             */
            uint32_t dylib_inf_size = sizeof (mach_dylib_command_info_t);
            
            mach_dylib_command_info_t *dylibinfo = malloc (dylib_inf_size);
            uint32_t cmdsize = lc->lc->cmdsize;

            mach_dylib_command_t *raw = malloc (dylib_inf_size);
            memcpy (raw, macho->data + offset, dylib_inf_size);

            uint32_t nsize = cmdsize - sizeof (mach_dylib_command_t);
            uint32_t noff = offset + raw->dylib.offset;

            char *name = malloc (nsize);
            memcpy (name, macho->data + noff, nsize);
            
            // set name, raw cmd struct and type
            dylibinfo->name = name;
            dylibinfo->dylib = raw;
            dylibinfo->type = lc->lc->cmd;

            lc->offset = offset;

            dylibs = h_slist_append (dylibs, dylibinfo);
            lcmds = h_slist_append (lcmds, lc);
        } else {
            lc->offset = offset;
            lcmds = h_slist_append (lcmds, lc);
        }
        offset += lc->lc->cmdsize;
    }

    // set macho offset
    macho->offset = offset;

    // set lists
    macho->lcmds = lcmds;
    macho->scmds = scmds;
    macho->dylibs = dylibs;

    // fix size
    mach_segment_info_32_t *last_seg = (mach_segment_info_32_t *) h_slist_last (macho->scmds);
    macho->size = last_seg->segcmd->fileoff + last_seg->segcmd->filesize;

    return macho;
}
