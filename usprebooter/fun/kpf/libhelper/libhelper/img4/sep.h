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
 *                  === The Libhelper Project ===
 *                             Image4
 *
 *  Part of the Image4 sub-lib. Handles the splitting and analysis of
 *  Secure Enclave OS (SEPOS) firmware files. The SEP splitting code is
 *  adapted from @xerub's sepsplit.c to make it usable in a library, and
 *  I've added my own spin to it.
 *                                                                      |
 *                                                                      |
 * 
 *  ----------------
 *  Original Author:
 *      Harry Moulton, @h3adsh0tzz  -   me@h3adsh0tzz.com.
 * 
 */
/**
 *  Adapated from original sepsplit.c by xerub. 
 *  -------------------------------------------
 * 
 *  SEP firmware split tool
 *
 *  Copyright (c) 2017 xerub
 */

#ifndef _LIBHELPER_IMG4_SEP_H_
#define _LIBHELPER_IMG4_SEP_H_

#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define USE_LIBHELPER_MACHO       1

#include "../../libhelper/libhelper.h"

#if USE_LIBHELPER_MACHO
#   include "../../libhelper/libhelper-macho.h"
#else
#   include <mach-o/loader.h>
#endif

#define IS64(image) (*(uint8_t *)(image) & 1)

#define MACHO(p) ((*(unsigned int *)(p) & ~1) == 0xfeedface)

static const struct sepapp_t {
    uint64_t phys;
    uint32_t virt;
    uint32_t size;
    uint32_t entry;
    char name[12];
    /*char hash[16];*/
} *apps;
static size_t sizeof_sepapp = sizeof(struct sepapp_t);

#define __UCHAR_MAX 255

void sep_split_init (char *filename);

#endif /* _libhelper_img4_sep_h_ */
