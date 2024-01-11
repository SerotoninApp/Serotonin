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
 *  Load a 64 bit section from an offset within a Mach-O.
 * 
 */
mach_section_64_t *mach_section_load (unsigned char *data, uint32_t offset)
{
    mach_section_64_t *sect = (mach_section_64_t *) (data + offset);

    if (sect == NULL) errorf ("mach_section_load(): could not load section at offset: 0x%08x\n", offset);
    return sect;
}


/**
 *  Load a 64 bit section by name from a given segment info struct.
 * 
 */
mach_section_64_t *mach_section_from_segment_info (mach_segment_info_t *info, char *sectname)
{
    // Check the sectname given is valid
    if (!sectname || strlen(sectname) > 16) {
        debugf ("section.c: mach_section_from_segment_info(): section name not valid\n");
        return NULL;
    }

    // Check the segment info is valid
    if (!info) {
        debugf ("section.c: mach_section_form_segment_info(): segment info not valid\n");
        return NULL;
    }

    // Check the length of the sections
    int c = h_slist_length (info->sects);
    if (!c) {
        debugf ("section.c: mach_section_from_segment_info(): no sections\n");
        return NULL;
    }

    // Go through each of them, look for `sectname`
    for (int i = 0; i < c; i++) {
        mach_section_64_t *tmp = (mach_section_64_t *) h_slist_nth_data (info->sects, i);
        if (!strcmp(tmp->sectname, sectname)) return tmp;
    }

    return NULL;
}


/**
 *  Load a 64 bit section at the given index. This treats all sections as one giant list.
 * 
 */
mach_section_64_t *mach_find_section_command_at_index (HSList *segments, int index)
{
    int count = 0;
    for (int i = 0; i < h_slist_length (segments); i++) {
        mach_segment_info_t *seg = (mach_segment_info_t *) h_slist_nth_data (segments, i);
        for (int k = 0; k < (int) seg->segcmd->nsects; k++) {
            count++;
            if (count == index) {
                return (mach_section_64_t *) h_slist_nth_data (seg->sects, k);
            }
        }
    }
    return NULL;
}


/**
 *  Load a 64 bit section by segment name and section name from a given Mach-O.
 * 
 */
mach_section_info_t *mach_section_info_from_name (macho_t *macho, char *segment, char *section)
{
    mach_section_info_t *ret = malloc (sizeof(mach_section_info_t));

    mach_segment_info_t *seginfo = mach_segment_info_search (macho->scmds, segment);
    mach_section_64_t *sect = mach_section_from_segment_info (seginfo, section);

    if (sect == NULL) {
        debugf ("Could not find %s.%s\n", segment, section);
        return NULL;
    }

    ret->section = sect;
    ret->segname = sect->segname;
    ret->sectname = sect->sectname;
    ret->size = sect->size;
    ret->addr = sect->offset;

    return ret;
}

//===-----------------------------------------------------------------------===//
/*-- Mach-O 32 bit                      									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  Load a 32 bit section from an offset within a Mach-O.
 * 
 */
mach_section_32_t *mach_section_32_load (unsigned char *data, uint32_t offset)
{
    mach_section_32_t *sect = (mach_section_32_t *) (data + offset);

    if (sect == NULL) errorf ("mach_section_32_load(): could not load section at offset: 0x%08x\n", offset);
    return sect;
}


/**
 *  Load a 32 bit section by name from a given segment info struct.
 * 
 */
mach_section_32_t *mach_section_32_from_segment_info_32 (mach_segment_info_32_t *info, char *sectname)
{
    // Check the sectname given is valid
    if (!sectname || strlen(sectname) > 16) {
        debugf ("section.c: mach_section_32_from_segment_info_32(): section name not valid\n");
        return NULL;
    }

    // Check the segment info is valid
    if (!info) {
        debugf ("section.c: mach_section_32_from_segment_info_32(): segment info not valid\n");
        return NULL;
    }

    // Check the length of the sections
    int c = h_slist_length (info->sects);
    if (!c) {
        debugf ("section.c: mach_section_32_from_segment_info_32(): no sections\n");
        return NULL;
    }

    // Go through each of them, look for `sectname`
    for (int i = 0; i < c; i++) {
        mach_section_32_t *tmp = (mach_section_32_t *) h_slist_nth_data (info->sects, i);
        if (!strcmp(tmp->sectname, sectname)) return tmp;
    }

    return NULL;
}


/**
 *  Load a 32 bit section at the given index. This treats all sections as one giant list.
 * 
 */
mach_section_32_t *mach_find_section_command_32_at_index (HSList *segments, int index)
{
    int count = 0;
    for (int i = 0; i < h_slist_length (segments); i++) {
        mach_segment_info_32_t *seg = (mach_segment_info_32_t *) h_slist_nth_data (segments, i);
        for (int k = 0; k < (int) seg->segcmd->nsects; k++) {
            count++;
            if (count == index) {
                return (mach_section_32_t *) h_slist_nth_data (seg->sects, k);
            }
        }
    }
    return NULL;
}


/**
 *  Load a 32 bit section by segment name and section name from a given Mach-O.
 * 
 */
mach_section_info_32_t *mach_section_info_32_from_name (macho_32_t *macho, char *segment, char *section)
{
    mach_section_info_32_t *ret = malloc (sizeof(mach_section_info_32_t));

    mach_segment_info_32_t *seginfo = mach_segment_info_32_search (macho->scmds, segment);
    mach_section_32_t *sect = mach_section_32_from_segment_info_32 (seginfo, section);

    if (sect == NULL) {
        debugf ("Could not find %s.%s\n", segment, section);
        return NULL;
    }

    ret->section = sect;
    ret->segname = sect->segname;
    ret->sectname = sect->sectname;
    ret->size = sect->size;
    ret->addr = sect->offset;

    return ret;
}
