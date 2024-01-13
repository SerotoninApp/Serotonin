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

/**
 *  A few functions here require 64 and 32 bit versions.
 * 
 */


//===-----------------------------------------------------------------------===//
/*-- Mach-O 64 bit                      									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  Load a 64 bit segment command from an offset within a Mach-O.
 * 
 */
mach_segment_command_64_t *mach_segment_command_load (unsigned char *data, uint32_t offset)
{
    mach_segment_command_64_t *sc = (mach_segment_command_64_t *) (data + offset);

    if (!sc) {
        errorf ("mach_segment_command_load(): could not load segment command at offset: 0x%08x\n", offset);
        return NULL;
    }
    return sc;
}


/**
 *  Load a 64 bit segment info (libhelper wrapper) from an offset within a
 *  Mach-O.
 * 
 */
mach_segment_info_t *mach_segment_info_load (unsigned char *data, uint32_t offset)
{
    mach_segment_info_t *seg_inf = calloc (1, sizeof (mach_segment_info_t));
    mach_segment_command_64_t *seg = mach_segment_command_load (data, offset);

    // check the segment is valid
    if (!seg) {
        errorf ("mach_segment_info_load(): Could not load Segment Command at offset: 0x%08x\n", offset);
        return NULL;
    }

    // the section commands are placed directly after the segment command
    uint32_t sectoff = offset + sizeof (mach_segment_command_64_t);
    //debugf ("mach_segment_info_load(): seg->nsect: %d\n", seg->nsects);
    for (uint32_t i = 0; i < seg->nsects; i++) {
        mach_section_64_t *sect = mach_section_load (data, sectoff);
        seg_inf->sects = h_slist_append (seg_inf->sects, sect);
        sectoff += sizeof (mach_section_64_t);
    }

    seg_inf->offset = offset;
    seg_inf->segcmd = seg;
    return seg_inf;
}


/**
 *  Return a list of segments in a 64 bit Mach-O.
 * 
 */
HSList *mach_segment_get_list (macho_t *mach)
{
    // Create a new list, this'll be returned
    HSList *r = NULL;

    // Go through all of them, add them to the list
    for (int i = 0; i < (int) h_slist_length (mach->scmds); i++) {
        
        // Load the segment from the info struct, and add it to the list
        mach_segment_info_t *si = (mach_segment_info_t *) h_slist_nth_data (mach->scmds, i);
        mach_segment_command_64_t *s = (mach_segment_command_64_t *) si->segcmd;

        // Add to the list
        r = h_slist_append (r, s);
    }

    // Return the list
    return r;
}


/**
 *  Search a given list for a Segment matching the given name.
 * 
 */
mach_segment_info_t *mach_segment_info_search (HSList *segments, char *segname)
{
    // Check the segname given is valid
    if (!segname) {
        debugf ("[*] Segment name not valid\n");
        exit (0);
    }

    // Get the amount of segment commands and check its more than 0
    int c = h_slist_length (segments);
    if (!c) {
        debugf ("[*] Error: No Segment Commands\n");
        exit (0);
    }

    // Now go through each of them
    for (int i = 0; i < c; i++) {
        
        // Grab the segment info
        mach_segment_info_t *si = (mach_segment_info_t *) h_slist_nth_data (segments, i);
        mach_segment_command_64_t *s = si->segcmd;

        // Check if they match
        if (!strcmp(s->segname, segname)) {
            return si;
        }
    }

    // Output an error
    debugf ("[*] Could not find Segment %s\n", segname);
    return NULL;
}


/**
 *  
 */
mach_segment_command_64_t *mach_segment_command_from_info (mach_segment_info_t *info)
{
    return (info->segcmd) ? info->segcmd : NULL;
}

//===-----------------------------------------------------------------------===//
/*-- Mach-O 32 bit                      									 --*/
//===-----------------------------------------------------------------------===//


/**
 *  Load a 32 bit segment command from an offset within a Mach-O.
 * 
 */
mach_segment_command_32_t *mach_segment_command_32_load (unsigned char *data, uint32_t offset)
{
    mach_segment_command_32_t *sc = (mach_segment_command_32_t *) (data + offset);
    if (!sc) {
        errorf ("mach_segment_command_load(): could not load segment command at offset: 0x%08x\n", offset);
        return NULL;
    }
    return sc;
}


/**
 *  Load a 32 bit segment info (libhelper wrapper) from an offset within a
 *  Mach-O.
 * 
 */
mach_segment_info_32_t *mach_segment_info_32_load (unsigned char *data, uint32_t offset)
{
    mach_segment_info_32_t *seg_inf = calloc (1, sizeof (mach_segment_info_32_t));
    mach_segment_command_32_t *seg = mach_segment_command_32_load (data, offset);

    // check the segment is valid
    if (!seg) {
        errorf ("mach_segment_info_32_load(): Could not load Segment Command at offset: 0x%08x\n", offset);
        return NULL;
    }

    // the section commands are placed directly after the segment command, and included in the size.
    uint32_t sectoff = offset + sizeof (mach_segment_command_32_t);
    for (uint32_t i = 0; i < seg->nsects; i++) {
        mach_section_32_t *sect = mach_section_32_load (data, sectoff);
        seg_inf->sects = h_slist_append (seg_inf->sects, sect);
        sectoff += sizeof (mach_section_32_t);
    }

    seg_inf->offset = offset;
    seg_inf->segcmd = seg;
    return seg_inf;
}


/**
 *  Return a list of segments in a 32 bit Mach-O.
 * 
 */
HSList *mach_segment_32_get_list (macho_32_t *mach)
{
    // Create a new list, this'll be returned
    HSList *r = NULL;

    // Go through all of them, add them to the list
    for (int i = 0; i < (int) h_slist_length (mach->scmds); i++) {
        
        // Load the segment from the info struct, and add it to the list
        mach_segment_info_32_t *si = (mach_segment_info_32_t *) h_slist_nth_data (mach->scmds, i);
        mach_segment_command_32_t *s = (mach_segment_command_32_t *) si->segcmd;

        // Add to the list
        r = h_slist_append (r, s);
    }

    // Return the list
    return r;
}


/**
 *  Search a given list for a 32 bit Segment matching the given name.
 * 
 */
mach_segment_info_32_t *mach_segment_info_32_search (HSList *segments, char *segname)
{
    // Check the segname given is valid
    if (!segname) {
        debugf ("mach_segment_info_32_search(): segment name not valid\n");
        exit (0);
    }

    // Get the amount of segment commands and check its more than 0
    int c = h_slist_length (segments);
    if (!c) {
        debugf ("mach_segment_info_32_search(): no segment commands\n");
        exit (0);
    }

    // Now go through each of them
    for (int i = 0; i < c; i++) {
        
        // Grab the segment info
        mach_segment_info_t *si = (mach_segment_info_t *) h_slist_nth_data (segments, i);
        mach_segment_command_64_t *s = si->segcmd;

        // Check if they match
        if (!strcmp(s->segname, segname)) {
            return (mach_segment_info_32_t *) si;
        }
    }

    // Output an error
    debugf ("mach_segment_info_32_search(): could not find segment: %s\n", segname);
    return NULL;
}


/**
 *  
 */
mach_segment_command_32_t *mach_segment_command_32_from_info (mach_segment_info_32_t *info)
{
    return (info->segcmd) ? info->segcmd : NULL;
}


//===-----------------------------------------------------------------------===//
/*-- Mach-O Generic                      									 --*/
//===-----------------------------------------------------------------------===//


/**
 * 
 */
char *mach_segment_vm_protection (vm_prot_t prot)
{
    HString *str = h_string_new ("");
    
    if ((prot & VM_PROT_READ) == VM_PROT_READ)
        str = h_string_append_c (str, 'r');
    else
        str = h_string_append_c (str, '-');

    if ((prot & VM_PROT_WRITE) == VM_PROT_WRITE)
        str = h_string_append_c (str, 'w');
    else
        str = h_string_append_c (str, '-');

    if ((prot & VM_PROT_EXEC) == VM_PROT_EXEC)
        str = h_string_append_c (str, 'x');
    else
        str = h_string_append_c (str, '-');

    str = h_string_append_c (str, '\0');
    return str->str;
}


/**
 * 
 */
char *mach_segment_init_vm_protection (vm_prot_t initprot);
