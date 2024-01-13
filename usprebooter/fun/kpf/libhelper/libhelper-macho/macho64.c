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
/*-- Mach-O 64 bit                      									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  This file contains 64 bit specific parsing of Mach-O files. Generic Mach-O
 *  parsing and 32 bit parsing can be found in macho.c and macho32.c respectively.
 * 
 */

/**
 *  Load a 64-bit Mach-O from a given data buffer.
 * 
 */
macho_t *macho_64_create_from_buffer (unsigned char *data)
{
    // zero out some memory for macho.
    macho_t *macho = calloc (1, sizeof (macho_t));

    macho->data = (uint8_t *) data;
    macho->offset = 0;

    // try to load the mach header, and handle any failure
    macho->header = mach_header_load (macho);
    if (macho->header == NULL) {
        errorf ("macho_create_from_buffer: Mach header is NULL\n");
        free (macho);
        return NULL;
    }

    uint32_t offset = sizeof (mach_header_t);
    HSList *scmds = NULL, *lcmds = NULL, *dylibs = NULL;

    // we'll search through every load command and sort them
    for (int i = 0; i < (int) macho->header->ncmds; i++) {
        mach_load_command_info_t *lc = mach_load_command_info_load ((const char *) macho->data, offset);
        uint32_t type = lc->lc->cmd;

        /**
         *  Different types of Load Command are sorted into one of the three 
         *  lists defined above: scmds, lcmds and dylibs.
         */
        if (type == LC_SEGMENT_64) {

            // create a segment info struct, then add to the list
            mach_segment_info_t *seginf = mach_segment_info_load (macho->data, offset);
            if (seginf == NULL) {
                warningf ("macho_create_from_buffer(): failed to load LC_SEGMENT_64 at offset: 0x%08x\n", offset);
                continue;
            }

            // add to segments lists
            scmds = h_slist_append (scmds, seginf);
        } else if (type == LC_ID_DYLIB || type == LC_LOAD_DYLIB ||
                   type == LC_LOAD_WEAK_DYLIB || type == LC_REEXPORT_DYLIB) {
            /**
             *  Because a Mach-O  can have multiple dynamically linked libraries which
             *  means there are multiple LC_DYLIB-like commands, so it's easier that
             *  there is a sperate list for DYLIB-related commands.
             */

            // dylib info struct
            mach_dylib_command_info_t *dylibinfo = malloc (sizeof (mach_dylib_command_info_t));
            uint32_t cmdsize = lc->lc->cmdsize;

            // create the raw command
            mach_dylib_command_t *raw = malloc (sizeof (mach_dylib_command_t));
            memset (raw, '\0', sizeof (mach_dylib_command_t));
            memcpy (raw, macho->data + offset, sizeof (mach_dylib_command_t));

            // laod the name of the dylib. This is located after the load command
            //  and is included in the cmdsize.
            uint32_t nsize = cmdsize - sizeof(mach_dylib_command_t);
            uint32_t noff = offset + raw->dylib.offset;

            char *name = malloc (nsize);
            memset (name, '\0', nsize);
            memcpy (name, macho->data + noff, nsize);

            // set the name, raw cmd struct and type
            dylibinfo->name = name;
            dylibinfo->dylib = raw;
            dylibinfo->type = lc->lc->cmd;

            // add the offset to the load command
            lc->offset = offset;

            // add them to both lists
            dylibs = h_slist_append (dylibs, dylibinfo);
            lcmds = h_slist_append (lcmds, lc);            

        } else {
            // set the offset of the command so we can find it again
            lc->offset = offset;
            lcmds = h_slist_append (lcmds, lc);
        }

        offset += lc->lc->cmdsize;
    }

    // set macho offset
    macho->offset = offset;

    // set LC lists
    macho->lcmds = lcmds;
    macho->scmds = scmds;
    macho->dylibs = dylibs;

    // fix size
    mach_segment_info_t *last_seg = (mach_segment_info_t *) h_slist_last (macho->scmds);
    macho->size = last_seg->segcmd->fileoff + last_seg->segcmd->filesize;

    return macho;
}
