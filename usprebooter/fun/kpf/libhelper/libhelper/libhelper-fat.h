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
/*
 * Copyright (c) 2007-2016 Apple, Inc. All rights reserved.
 * Copyright (c) 2000 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 *
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */
/*
 * Mach Operating System
 * Copyright (c) 1991,1990,1989,1988,1987 Carnegie Mellon University
 * All Rights Reserved.
 *
 * Permission to use, copy, modify and distribute this software and its
 * documentation is hereby granted, provided that both the copyright
 * notice and this permission notice appear in all copies of the
 * software, derivative works or modified versions, and any portions
 * thereof, and that both notices appear in supporting documentation.
 *
 * CARNEGIE MELLON ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  CARNEGIE MELLON DISCLAIMS ANY LIABILITY OF ANY KIND FOR
 * ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 *
 * Carnegie Mellon requests users of this software to return to
 *
 *  Software Distribution Coordinator  or  Software.Distribution@CS.CMU.EDU
 *  School of Computer Science
 *  Carnegie Mellon University
 *  Pittsburgh PA 15213-3890
 *
 * any improvements or extensions that they make and grant Carnegie Mellon
 * the rights to redistribute these changes.
 */

//
//  NOTE: The licenses from both Mach and Apple are included as many of the
//      definitions within this header are taken from the `mach/` directory
//      of the macOS SDK.
//

#ifndef LIBHELPER_FATH
#define LIBHELPER_FATH

#ifdef cplusplus
extern "C" {
#endif

//
//  This file is part of libhelper's Mach-O parser
//

#include <stdint.h>
#include "libhelper-macho.h"


/**
 *  FAT File Header (Universal Binary).
 * 
 *  The FAT File Header for Universal Binaries. This appears at the top of a 
 *  universal file, with a summary of all the architectures contained within it.
 *  
 *  NOTE: Currently, it is not known whether the new Universal Binary format used
 *      on Apple arm64-based Mac's uses a different type of Universal Binary.
 * 
 */
struct fat_header {
    uint32_t        magic;          /* 0xcafebabe */
    uint32_t        nfat_arch;      /* number of fat_arch structs that follow */
};
// libhelper-fat alias
typedef struct fat_header           fat_header_t;

/**
 *  The fat_arch structs defines an architecture contained within the FAT archive.
 *  These follow the fat_header directly in the file.
 * 
 */
struct fat_arch {
    cpu_type_t      cputype;        /* cpu specifier for this architecture */
    cpu_subtype_t   cpusubtype;     /* cpu subtype specifier for this architecture */
    uint32_t        offset;         /* offset of where the Mach-O begins in the file */
    uint32_t        size;           /* size of the Mach-O */
    uint32_t        align;          /* byte align */
};


/**
 *  Libhelper Universal Binary header with parsed data about the FAT archive
 *  and it's contained architectures.
 * 
 */
struct __libhelper_fat_header_info {
    fat_header_t    *header;        /* FAT archive header */
    HSList          *archs;         /* list of contained archs */
};
typedef struct __libhelper_fat_header_info      fat_header_info_t;


// Functions
extern fat_header_info_t    *mach_universal_load    (file_t *file);
extern fat_header_t         *swap_header_bytes      (fat_header_t *header);
extern mach_header_t        *swap_mach_header_bytes (mach_header_t *header);

extern struct fat_arch      *swap_fat_arch_bytes    (struct fat_arch *a);
extern fat_header_t         *swap_fat_header_bytes  (fat_header_t *h);

#ifdef cplusplus
}
#endif

#endif /* libhelper_fat_h */