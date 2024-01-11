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

#ifndef LIBHELPER_MACHO_HEADER_TYPES_H
#define LIBHELPER_MACHO_HEADER_TYPES_H

#ifdef cplusplus
extern "C" {
#endif

#define     MH_NOUNDEFS                 0x1     //  The object file has no undefined references.
#define     MH_INCRLINK                 0x2     //  The object file is the output of an
					                            //   incremental link against a base file
					                            //   and can't be link edited again.
#define     MH_DYLDLINK                 0x3     //  The object file is input for the
					                            //   dynamic linker and can't be staticly
					                            //   link edited again.
#define     MH_BINDATLOAD	            0x8		//  The object file's undefined
					                            //   references are bound by the dynamic
					                            //   linker when loaded.
#define     MH_PREBOUND	                0x10    //  The file has its dynamic undefined
					                            //   references prebound.
#define     MH_SPLIT_SEGS	            0x20    //  The file has its read-only and
					                            //   read-write segments split.
#define     MH_LAZY_INIT	            0x40	//  The shared library init routine is
					                            //   to be run lazily via catching memory
					                            //   faults to its writeable segments
					                            //   (obsolete).
#define     MH_TWOLEVEL	                0x80	//  The image is using two-level name
					                            //   space bindings.
#define     MH_FORCE_FLAT	            0x100	//  The executable is forcing all images
					                            //   to use flat name space bindings.
#define     MH_NOMULTIDEFS	            0x200	//  This umbrella guarantees no multiple
					                            //   defintions of symbols in its
					                            //   sub-images so the two-level namespace
					                            //   hints can always be used.
#define     MH_NOFIXPREBINDING          0x400	//  Do not have dyld notify the
					                            //   prebinding agent about this
					                            //   executable.
#define     MH_PREBINDABLE              0x800   //  The binary is not prebound but can
					                            //   have its prebinding redone. only used
                                                //   when MH_PREBOUND is not set.
#define     MH_ALLMODSBOUND             0x1000	//  Indicates that this binary binds to
                                                //   all two-level namespace modules of
					                            //   its dependent libraries. only used
					                            //   when MH_PREBINDABLE and MH_TWOLEVEL
					                            //   are both set. 
#define     MH_SUBSECTIONS_VIA_SYMBOLS  0x2000  //  Safe to divide up the sections into
					                            //   sub-sections via symbols for dead
					                            //   code stripping.
#define     MH_CANONICAL                0x4000  //  The binary has been canonicalized
					                            //   via the unprebind operation.
#define     MH_WEAK_DEFINES	            0x8000	//  The final linked image contains
					                            //   external weak symbols.
#define     MH_BINDS_TO_WEAK            0x10000	//  The final linked image uses
					                            //   weak symbols.

/**
 *  When this bit is set, all stacks in the task will be
 *  given stack execution privilege. Only used int MH_EXECUTE
 *  filetypes.
 */
#define     MH_ALLOW_STACK_EXECUTION    0x20000

/**
 *  When this bit is set, the binary declares it is safe for
 *  use in processes with uid zero.
 */
#define     MH_ROOT_SAFE                0x40000           

/**
 *  When this bit is set, the binary declares it is safe for
 *  use in processes when issetugid() is true.
 */                                         
#define     MH_SETUID_SAFE              0x80000        

/**
 *  When this bit is set on a dylib, the static linker does not
 *  need to examine dependent dylibs to see if any are re-exported.
 */
#define     MH_NO_REEXPORTED_DYLIBS     0x100000 

/**
 *  When this bit is set, the OS will load the main exectuable at a
 *  random address. Only used in MH_EXECUTE filetypes.
 */
#define	    MH_PIE                      0x200000			

/**
 *  Only for use on dylibs. When linking against a dylib that
 *  has this bit set, the statis linker will automatically not
 *  create a LC_LOAD_DYLIB load command to the dylib if no symbols
 *  are being referenced from the dylib.
 */
#define	    MH_DEAD_STRIPPABLE_DYLIB    0x400000 

/**
 *  Contains a section of type S_THREAD_LOCAL_VARIABLES.
 */
#define     MH_HAS_TLV_DESCRIPTORS      0x800000 

/**
 *  When this bit is set, the OS will run the main executable
 *  with a non-executable heap even on platforms (e.g. i386)
 *  that don't require it. Only used in MH_EXECUTE filetypes
 */
#define     MH_NO_HEAP_EXECUTION        0x1000000	

/**
 *  The code was linked for use in an application extension.
 */
#define     MH_APP_EXTENSION_SAFE       0x02000000 

/**
 *  The external symbols listed in the nlist symbol table do
 *  not include all the symbols listed in the dylid info.
 */
#define	    MH_NLIST_OUTOFSYNC_WITH_DYLDINFO    0x04000000 

/**
 *  Allow LC_MIN_VERSION_MACOS and LC_BUILD_VERSION load commands
 *  with the platforms macOS, iOSMac, iOSSimulator, tvOSSimulator
 *  and watchOSSimulator.
 */
#define	    MH_SIM_SUPPORT              0x08000000	

/**
 *  Only for use on dylibs. When this bit is set, the dylib is part
 *  of the dylid shared cache, rather than loose in the filesystem.
 */ 
#define     MH_DYLIB_IN_CACHE           0x80000000

#ifdef cplusplus
}
#endif

#endif /* libhelper_macho_header_types_h */