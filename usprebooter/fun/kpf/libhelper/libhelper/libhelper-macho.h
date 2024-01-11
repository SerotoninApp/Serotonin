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

#ifndef LIBHELPER_MACHO_H
#define LIBHELPER_MACHO_H

#ifdef cplusplus
extern "C" {
#endif
	
/**
 *                  === The Libhelper Project ===
 *                          Mach-O Parser
 *
 *	Libhelper Mach-O Parser is a standalone Mach-O Parser for all platfors
 *	and architectures supported by libhelper. By standalone, it means that
 *	it doesn't require any system Mach-O headers, so can run easily on linux.
 *
 *	The Mach-O parser in this version (libhelper-2000.16.4 and up) differs
 *	from the previous versions as it's aimed at being faster, more reliable
 *	and more efficient.
 *
 *  ----------------
 *  Original Author:
 *      Harry Moulton, @h3adsh0tzz  -   me@h3adsh0tzz.com.
 *
 */

#include <stdint.h>
	
#include "macho/command-types.h"
#include "macho/header-types.h"
#include "libhelper.h"

#ifdef TEST
#   include <mach-o/loader.h>
#endif
	
typedef int                 cpu_type_t;
typedef int                 cpu_subtype_t;
typedef int                 cpu_threadtype_t;
	
/**
 *	Linux does not have OSSwapInt32(), instead is has bswap_32. If the
 *	build platform is Linux redefine bswap_32 as OSSwapInt32 and include
 *	byteswap.h/
 *
 */
#ifdef __APPLE__
#	define OSSwapInt32(x) 	 _OSSwapInt32(x)
#else
#   include <byteswap.h>
#	define OSSwapInt32(x)	bswap_32(x)
#endif

	
/**
 *  Capability bits used in the definition of cpu_type. These are used to
 *  calculate the value of the 64bit CPU Type's by performing a logical OR
 *  between the 32bit variant, and the architecture mask.
 *
 *      E.g. CPU_TYPE_ARM64 = (CPU_TYPE_ARM | CPU_ARCH_ABI64)
 *
 */
#define CPU_ARCH_MASK           0xff000000          /* mask for architecture bits */
#define CPU_ARCH_ABI64          0x01000000          /* 64 bit ABI */
#define CPU_ARCH_ABI64_32       0x02000000          /* ABI for 64-bit hardware with 32-bit types. */

#define CPU_SUBTYPE_MASK        0xff000000          /* mask for feature flags */
#define CPU_SUBTYPE_LIB64       0x80000000          /* 64 bit libraries */
#define CPU_SUBTYPE_PTRAUTH_ABI 0x80000000          /* pointer authentication (PAC) with versioned ABI */


/**
 *  Machine types. There are many more of these defined in `machine.h`, however
 *  we do not need them all as libhelper supports x86_64 and arm64. There
 *  is also support for working with 32-bit ARM files, despite libhelper not
 *  being compatible build-wise.
 * 
 */
#define CPU_TYPE_ANY            ((cpu_type_t) -1)

#define CPU_TYPE_X86            ((cpu_type_t) 7)
#define CPU_TYPE_X86_64         (CPU_TYPE_X86 | CPU_ARCH_ABI64)

#define CPU_TYPE_ARM            ((cpu_type_t) 12)
#define CPU_TYPE_ARM64          (CPU_TYPE_ARM | CPU_ARCH_ABI64)
#define CPU_TYPE_ARM64_32       (CPU_TYPE_ARM | CPU_ARCH_ABI64_32)


/**
 *  Machine subtypes. The case is the same as with machine types, they're taken
 *  from the `machine.h` header. As we only defined x86 and ARM cpu types, not
 *  all CPU types will be required here.
 * 
 */
#define CPU_SUBTYPE_ANY         ((cpu_subtype_t) -1)


/**
 *  x86 subtypes
 */
#define CPU_SUBTYPE_X86_ALL     ((cpu_subtype_t) 3)
#define CPU_SUBTYPE_X86_64_ALL  ((cpu_subtype_t) 3)
#define CPU_SUBTYPE_X86_ARCH1   ((cpu_subtype_t) 4)
#define CPU_SUBTYPE_X86_64_H    ((cpu_subtype_t) 8)     /* Haswell feature subset */


/**
 *  ARM subtypes
 */
#define CPU_SUBTYPE_ARM_ALL             ((cpu_subtype_t) 0)
#define CPU_SUBTYPE_ARM_V4T             ((cpu_subtype_t) 5)
#define CPU_SUBTYPE_ARM_V6              ((cpu_subtype_t) 6)
#define CPU_SUBTYPE_ARM_V5TEJ           ((cpu_subtype_t) 7)
#define CPU_SUBTYPE_ARM_XSCALE          ((cpu_subtype_t) 8)
#define CPU_SUBTYPE_ARM_V7              ((cpu_subtype_t) 9)  /* ARMv7-A and ARMv7-R */
#define CPU_SUBTYPE_ARM_V7F             ((cpu_subtype_t) 10) /* Cortex A9 */
#define CPU_SUBTYPE_ARM_V7S             ((cpu_subtype_t) 11) /* Swift */
#define CPU_SUBTYPE_ARM_V7K             ((cpu_subtype_t) 12)
#define CPU_SUBTYPE_ARM_V8              ((cpu_subtype_t) 13)
#define CPU_SUBTYPE_ARM_V6M             ((cpu_subtype_t) 14) /* Not meant to be run under xnu */
#define CPU_SUBTYPE_ARM_V7M             ((cpu_subtype_t) 15) /* Not meant to be run under xnu */
#define CPU_SUBTYPE_ARM_V7EM            ((cpu_subtype_t) 16) /* Not meant to be run under xnu */
#define CPU_SUBTYPE_ARM_V8M             ((cpu_subtype_t) 17) /* Not meant to be run under xnu */

/**
 *  ARM64 subtypes
 */
#define CPU_SUBTYPE_ARM64_ALL           ((cpu_subtype_t) 0)
#define CPU_SUBTYPE_ARM64_V8            ((cpu_subtype_t) 1)
#define CPU_SUBTYPE_ARM64E              ((cpu_subtype_t) 2)


/**
 *  ARM64_32 subtypes
 */
#define CPU_SUBTYPE_ARM64_32_ALL        ((cpu_subtype_t) 0)
#define CPU_SUBTYPE_ARM64_32_V8         ((cpu_subtype_t) 1)


/**
 *  CPU subtype feature flags for ptrauth on arm64 platforms, and
 *  libhelper experimental MTE (Memory Tagging Extension) mask.
 * 
 */
#define CPU_SUBTYPE_ARM64E_MTE_MASK                 0xc0000000
#define CPU_SUBTYPE_ARM64_PTR_AUTH_MASK             0x0f000000
#define CPU_SUBTYPE_ARM64_PTR_AUTH_VERSION(x)       (((x) & CPU_SUBTYPE_ARM64_PTR_AUTH_MASK) >> 24)
	

/***********************************************************************
* Mach-O Header.
*
*	Redefinitions of values specific to the Mach-O Header
*
************************************************************************/

/**
 *  Mach-O header type. These are defined in `macho/header-types.h`
 *  for libhelper and `loader.h` for the macOS SDK.
 * 
 */
typedef int         mach_header_type_t;

#define MH_TYPE_UNKNOWN         ((mach_header_type_t) -1)
#define MH_TYPE_MACHO64         ((mach_header_type_t) 1)
#define MH_TYPE_MACHO32         ((mach_header_type_t) 2)
#define MH_TYPE_FAT             ((mach_header_type_t) 3)

/**
 *  Mach-O Magic's
 * 
 *  There are three types of Mach-O magic's: 64 bit, 32 bit and Universal
 *  Binary. With macOS 11, it is possible the Universal Binary has changed
 *  in format for cross-platform Apple Silicon applications.
 *
 */
#define MACH_MAGIC_64           0xfeedfacf      /* 64bit magic number */
#define MACH_CIGAM_64           0xcffaedfe      /* NXSwapInt */

#define MACH_MAGIC_32           0xfeedface      /* 32bit magic number */
#define MACH_CIGAM_32           0xcefaedfe      /* NXSwapInt */

#define MACH_MAGIC_UNIVERSAL    0xcafebabe      /* Universal Binary magic number */
#define MACH_CIGAM_UNIVERSAL    0xbebafeca      /* NXSwapInt */


/**
 *  Mach-O type specifiers.
 * 
 *  These describe the type of Mach-O a particular file is, as the format
 *  of each type varies slightly, as an executable will not need the same
 *  structure as a dynamic library.
 * 
 *  NOTE: Not all of the types are defined here. As libhelper supports more,
 *  they will be added here.
 */
#define MACH_TYPE_UNKNOWN       0x0             /* unknown Mach type */

#define MACH_TYPE_OBJECT        0x1             /* object file */
#define MACH_TYPE_EXECUTE       0x2             /* executable file */
#define MACH_TYPE_FVMLIB        0x3             /* fixed vm shared library */
#define MACH_TYPE_CORE          0x4             /* core file */
#define MACH_TYPE_PRELOAD       0x5             /* preloaded executable file */
#define MACH_TYPE_DYLIB         0x6             /* dynamic library */
#define MACH_TYPE_DYLINKER      0x7             /* dynamic link editor */
#define MACH_TYPE_BUNDLE        0x8             /* dynamic bundle file */
#define MACH_TYPE_DYLIB_STUB    0x9             /* shared library stub for static linking */
#define MACH_TYPE_DSYM          0xa             /* debugging companion file */
#define MACH_TYPE_KEXT_BUNDLE   0xb             /* x86_64 KEXT */
#define MACH_TYPE_FILESET       0xc             /* file composed of other Mach-O's */


/**
 *  Mach-O Header flags
 * 
 *  NOTE: Not all are implemented.
 */ 
//...


/**
 *  Mach-O Header's
 * 
 *  The header is placed at the very top of a Mach-O file. There are two separate
 *  headers for 32bit and 64bit Mach-O's (Universal Binary/FAT archives are different).
 * 
 *  The differences between the 32 and 64 bit headers is the presence of the `reserved`
 *  property.
 * 
 *  NOTE: Compatibility issue with pre-libhelper-2000.16.4. The naming of the default
 *          mach_header_xx struct is different, but the alias's are the same.
 * 
 */
struct mach_header_64 {
    uint32_t        magic;          /* mach magic number */
    cpu_type_t      cputype;        /* cpu specifier */
    cpu_subtype_t   cpusubtype;     /* cpu subtype specifier */
    uint32_t        filetype;       /* mach filetype, e.g. MACH_TYPE_OBJECT */
    uint32_t        ncmds;          /* number of load commands */
    uint32_t        sizeofcmds;     /* size of load command region */
    uint32_t        flags;          /* flags */
    uint32_t        reserved;       /* *64 bit only* reserved */
};
// libhelper-macho alias
typedef struct mach_header_64       mach_header_t;

/**
 *  Mach-O Header (32 bit)
 * 
 *  To keep some sort of compatibility with code using the SDK `loader.h`, the original
 *  struct names are used (so the 64 bit header is specified, whereas 32 bit is simply
 *  mach_header). The libhelper alias reverts this, instead specifying 32 bit.
 * 
 */
struct mach_header {
    uint32_t        magic;          /* mach magic number */
    cpu_type_t      cputype;        /* cpu specifier */
    cpu_subtype_t   cpusubtype;     /* cpu subtype specifier */
    uint32_t        filetype;       /* mach filetype, e.g. MACH_TYPE_OBJECT */
    uint32_t        ncmds;          /* number of load commands */
    uint32_t        sizeofcmds;     /* size of load command region */
    uint32_t        flags;          /* flags */
};
// libhelper-macho alias
typedef struct mach_header          mach_header_32_t;


/**
 *  Mach-O file structure. Contains all parsed properties of a Mach-O file, and some
 *  other raw properties.
 * 
 */
struct __libhelper_macho {

    /* raw file properties */
    uint32_t             size;          /* size of mach-o */
    uint32_t             offset;        /* start of data */
    uint8_t             *data;          /* pointer to mach-o in memory */

    /* file data */
    char                *path;          /* filepath */

    /* mach-o parsed properties */
    mach_header_t   *header;        /* mach-o header */
    HSList          *lcmds;         /* list of all load commands (including LC_SEGMENT) */
    HSList          *scmds;         /* list of segment commands */
    HSList          *dylibs;        /* list of dynamic libraries */
    HSList          *symbols;       /* list of symbols */
    HSList          *strings;       /* list of strings */
};
typedef struct __libhelper_macho            macho_t;


/**
 *  Mach-O 32 bit file structure. Contains all parsed properties of a Mach-O file, and
 *  some other raw properties. The 32 bit structure is separate from the 64 bit.
 * 
 */
struct __libhelper_macho_32 {

    /* raw file properties */
    uint32_t             size;          /* size of mach-o */
    uint32_t             offset;        /* start of data */
    uint8_t             *data;          /* pointer to mach-o in memory */

    /* file data */
    char                *path;          /* filepath */

    /* mach-o parsed properties */
    mach_header_32_t    *header;        /* mach-o 32bit header */
    HSList              *lcmds;         /* list of all load commands (including LC_SEGMENT) */
    HSList              *scmds;         /* list of segment commands */
    HSList              *dylibs;        /* list of dynamic libraries */
    HSList              *symbols;       /* list of symbols */
    HSList              *strings;       /* list of strings */
};
typedef struct __libhelper_macho_32         macho_32_t;


/**
 *  Mach-O Header functions (64 bit)
 * 
 */
extern mach_header_t            *mach_header_create                 ();
extern mach_header_t            *mach_header_load                   (macho_t *macho);

/**
 *  Mach-O Header functions (32 bit)
 * 
 */
extern mach_header_32_t         *mach_header_32_load                (macho_32_t *macho);

/**
 *  Mach-O Header functions (generic)
 */
extern mach_header_type_t        mach_header_verify                 (uint32_t magic);

extern char                     *mach_header_get_cpu_name           (cpu_type_t type, cpu_subtype_t subtype);
extern char                     *mach_header_read_cpu_subtype       (cpu_type_t type, cpu_subtype_t subtype);       // these probably aren't
extern char                     *mach_header_read_cpu_type          (cpu_type_t type);                              //  needed anymore.
extern char                     *mach_header_read_file_type         (uint32_t type);
extern char                     *mach_header_read_file_type_short   (uint32_t type);


/**
 *  Mach-O parser
 * 
 */
extern void                     *macho_load                         (const char *filename);
extern void                     *macho_create_from_buffer           (unsigned char *data);

extern macho_t                  *macho_64_create_from_buffer        (unsigned char *data);
extern macho_32_t               *macho_32_create_from_buffer        (unsigned char *data);

extern void                     *macho_load_bytes                   (void *macho, size_t size, uint32_t offset);
extern void                      macho_read_bytes                   (void *macho, uint32_t offset, void *buffer, size_t size);
extern void                     *macho_get_bytes                    (void *macho, uint32_t offset);


/**
 *  Mach-O 32 bit parser
 * 
 */



// TODO: NOTE: MUST MOVE TO SEPARATE HEADER
#define FAT(p) ((*(unsigned int *)(p) & ~1) == 0xbebafeca)

/***********************************************************************
* Mach-O Load Commands.
*
*	Redefinitions of values specific to Mach-O Load Commands, and 
*   libhelpers parsing of those Load Commands.
*
************************************************************************/

/**
 *  Mach-O Generic Load Command.
 * 
 *  Load commands directly follow the Mach-O header and can vary in size and
 *  structure. However every command has the same first 16 bytes which define
 *  the command type and it's size.
 * 
 *  The `load_command` structure, and the libhelper alias, are not architecture
 *  specific (neither are most LCs).
 * 
 */
struct load_command {
    uint32_t        cmd;            /* load command type */
    uint32_t        cmdsize;        /* load command size */
};
// libhelper-macho alias
typedef struct load_command         mach_load_command_t;


/**
 *  Mach-O Load Command Info.
 * 
 *  Used as a wrapper around a `mach_load_command_t`, this provides a few more
 *  bits of information about a load command, such as it's index in the LC list,
 *  and the offset of the command within the Mach-O.
 * 
 */
struct __libhelper_mach_command_info {
    mach_load_command_t     *lc;    /* load command */

    uint32_t        offset;         /* offset in the Mach-O */
    uint32_t        index;          /* index in the LC list */
};
// libhelper-macho alias
typedef struct __libhelper_mach_command_info    mach_load_command_info_t;

#define LC_RAW      0x0
#define LC_INFO     0x1

/**
 *  Mach-O Load Command functions
 */
extern mach_load_command_t      *mach_load_command_create           ();

extern mach_load_command_info_t *mach_load_command_info_create      ();
extern mach_load_command_info_t *mach_load_command_info_load        (const char *data, uint32_t offset);

extern void                      mach_load_command_print            (void *cmd, int flag);
extern char                     *mach_load_command_get_string       (mach_load_command_t *lc);

extern mach_load_command_info_t *mach_lc_find_given_cmd             (macho_t *macho, int cmd);  


/***********************************************************************
* Mach-O Segment Commands.
*
*	Redefinitions of values specific to Mach-O Segment Commands, and 
*   libhelpers parsing of those Load Commands.
*
************************************************************************/

/**
 *  Segment Load Commands, either LC_SEGMENT or LC_SEGMENT_64, indicate a part
 *  of the Mach-O to be mapped into a tasks allocated address space. 
 * 
 *  There are two types of segment command: 32 bit and 64 bit. While libhelper
 *  has the definitions for the 32 bit commands, the is not currently parsing
 *  support.
 * 
 */
typedef int                     vm_prot_t;
struct segment_command_64 {
    uint32_t	cmd;			/* LC_SEGMENT_64 */
    uint32_t	cmdsize;		/* includes sizeof section_64 structs */
    char		segname[16];	/* segment name */
    uint64_t	vmaddr;			/* memory address of this segment */
    uint64_t	vmsize;			/* memory size of this segment */
    uint64_t	fileoff;		/* file offset of this segment */
    uint64_t	filesize;		/* amount to map from the file */
    vm_prot_t	maxprot;		/* maximum VM protection */
    vm_prot_t	initprot;		/* initial VM protection */
    uint32_t	nsects;			/* number of sections in segment */
    uint32_t	flags;			/* flags */   
};
// libhelper-macho alias
typedef struct segment_command_64       mach_segment_command_64_t;

struct segment_command {
	uint32_t	cmd;		/* LC_SEGMENT */
	uint32_t	cmdsize;	/* includes sizeof section structs */
	char		segname[16];	/* segment name */
	uint32_t	vmaddr;		/* memory address of this segment */
	uint32_t	vmsize;		/* memory size of this segment */
	uint32_t	fileoff;	/* file offset of this segment */
	uint32_t	filesize;	/* amount to map from the file */
	vm_prot_t	maxprot;	/* maximum VM protection */
	vm_prot_t	initprot;	/* initial VM protection */
	uint32_t	nsects;		/* number of sections in segment */
	uint32_t	flags;		/* flags */
};
// libhelper-macho alias
typedef struct segment_command mach_segment_command_32_t;


/**
 *  Like Load Commands, libhelper has an info struct for segment commands
 *  so more information about a segcmd can be stored without having to re
 *  process the Mach-O.
 * 
 */
struct __libhelper_mach_segment_info {
    mach_segment_command_64_t       *segcmd;            /* segment command */
    uint32_t                         offset;            /* offset in Mach-O */
    uint64_t                         padding;
    HSList                          *sects;             /* list of sections */
};
typedef struct __libhelper_mach_segment_info        mach_segment_info_t;

/**
 *  32 bit version of mach_segment_info_t;
 */
struct __libhelper_mach_segment_info_32 {
    mach_segment_command_32_t       *segcmd;            /* segment command */
    uint32_t                         offset;            /* offset in the mach-o */
    uint64_t                         padding;
    HSList                          *sects;             /* list of section commands */
};
typedef struct __libhelper_mach_segment_info_32     mach_segment_info_32_t;

// VM protection types
#define VM_PROT_READ            0x00000001
#define VM_PROT_WRITE           0x00000002
#define VM_PROT_EXEC            0x00000004


/**
 *  A segment is made up of multiple sections, e.g. __TEXT can be made up of
 *  __text and __text_exec. This also has a libhelper info struct to make
 *  life easier.
 * 
 */
struct section_64 {
	char		sectname[16];	/* name of this section */
	char		segname[16];	/* segment this section goes in */
	uint64_t	addr;			/* memory address of this section */
	uint64_t	size;			/* size in bytes of this section */
	uint32_t	offset;			/* file offset of this section */
	uint32_t	align;			/* section alignment (power of 2) */
	uint32_t	reloff;			/* file offset of relocation entries */
	uint32_t	nreloc;			/* number of relocation entries */
	uint32_t	flags;			/* flags (section type and attributes)*/
	uint32_t	reserved1;		/* reserved (for offset or index) */
	uint32_t	reserved2;		/* reserved (for count or sizeof) */
	uint32_t	reserved3;		/* reserved */
};
typedef struct section_64 mach_section_64_t;

struct section { /* for 32-bit architectures */
	char		sectname[16];	/* name of this section */
	char		segname[16];	/* segment this section goes in */
	uint32_t	addr;		/* memory address of this section */
	uint32_t	size;		/* size in bytes of this section */
	uint32_t	offset;		/* file offset of this section */
	uint32_t	align;		/* section alignment (power of 2) */
	uint32_t	reloff;		/* file offset of relocation entries */
	uint32_t	nreloc;		/* number of relocation entries */
	uint32_t	flags;		/* flags (section type and attributes)*/
	uint32_t	reserved1;	/* reserved (for offset or index) */
	uint32_t	reserved2;	/* reserved (for count or sizeof) */
};
typedef struct section  mach_section_32_t;

struct __libhelper_mach_section_info {
    mach_section_64_t       *section;

    uint32_t         addr;
    uint32_t         size;
    char            *segname;
    char            *sectname;
};
typedef struct __libhelper_mach_section_info                mach_section_info_t;

struct __libhelper_mach_section_32_info {
    mach_section_32_t       *section;

    uint32_t                 addr;
    uint32_t                 size;
    char                    *segname;
    char                    *sectname;
}
;
typedef struct __libhelper_mach_section_32_info             mach_section_info_32_t;


/**
 *  64 bit Segment parsing
 */
extern mach_segment_command_64_t    *mach_segment_command_load          (unsigned char *data, uint32_t offset);
extern mach_segment_info_t          *mach_segment_info_load             (unsigned char *data, uint32_t offset);
extern mach_segment_info_t          *mach_segment_info_search           (HSList *segments, char *segname);
extern mach_segment_command_64_t    *mach_segment_command_from_info     (mach_segment_info_t *info);

extern mach_section_info_t          *mach_section_info_from_name        (macho_t *macho, char *segment, char *section);
extern mach_section_64_t            *mach_section_from_segment_info     (mach_segment_info_t *info, char *sectname);
extern mach_section_64_t            *mach_section_load                  (unsigned char *data, uint32_t offset);
extern mach_section_64_t            *mach_find_section_command_at_index (HSList *segments, int index);


/**
 *  32 bit Segment parsing
 */
extern mach_segment_command_32_t    *mach_segment_command_32_load          (unsigned char *data, uint32_t offset);
extern mach_segment_info_32_t       *mach_segment_info_32_load             (unsigned char *data, uint32_t offset);
extern mach_segment_command_32_t    *mach_segment_command_32_from_info     (mach_segment_info_32_t *info);
extern mach_segment_info_32_t       *mach_segment_info_32_search           (HSList *segments, char *segname);

extern mach_section_info_32_t       *mach_section_info_32_from_name             (macho_32_t *macho, char *segment, char *section);
extern mach_section_32_t            *mach_section_32_from_segment_info_32       (mach_segment_info_32_t *info, char *sectname);
extern mach_section_32_t            *mach_section_32_load                       (unsigned char *data, uint32_t offset);
extern mach_section_32_t            *mach_find_section_command_32_at_index      (HSList *segments, int index);


/**
 *  Generic Segment parsing
 */
extern char                         *mach_segment_vm_protection         (vm_prot_t prot);
extern char                         *mach_lc_load_str                   (macho_t *macho,
                                                                         uint32_t cmdsize,
                                                                         uint32_t struct_size,
                                                                         off_t cmd_offset,
                                                                         off_t str_offset);
extern char                         *mach_lc_32_load_str                (macho_32_t *macho,
                                                                         uint32_t cmdsize,
                                                                         uint32_t struct_size,
                                                                         off_t cmd_offset,
                                                                         off_t str_offset);


/***********************************************************************
* Mach-O Other Load Commands.
*
*	Redefinitions of values specific to Mach-O Load Commands, and 
*   libhelpers parsing of those Load Commands. These are all the other
*   load command, e.g. dylib commands, build_version, etc...
*
*   TODO: Not all commands are implemented here, try to add them over
*           time.
*
************************************************************************/

/**
 *  An optional load command containing the version of the sources used
 *  to compile the binary.
 */
struct source_version_command {
    uint32_t    cmd;        /* LC_SOURCE_VERSION */
    uint32_t    cmdsize;    /* 16 */
    uint64_t    version;    /* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
};
// libhelper-macho alias
typedef struct source_version_command               mach_source_version_command_t;

extern mach_source_version_command_t 	*mach_lc_find_source_version_cmd (macho_t *macho);
extern char 							*mach_lc_source_version_string (mach_source_version_command_t *svc);

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 * 	The build_version_command contains the min OS version on which this
 * 	binary was built to run for its platform.
 */
struct build_version_command {
    uint32_t	cmd;		/* LC_BUILD_VERSION */
    uint32_t	cmdsize;	/* sizeof(struct build_version_command) plus */
                                /* ntools * sizeof(struct build_tool_version) */
    uint32_t	platform;	/* platform */
    uint32_t	minos;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    uint32_t	sdk;		/* X.Y.Z is encoded in nibbles xxxx.yy.zz */
    uint32_t	ntools;		/* number of tool entries following this */
};
typedef struct build_version_command                mach_build_version_command_t;


/**
 * 	The build_tool_version are found after the mach_build_version_command_t
 * 	in the Mach-O file. The `ntools` prop defines how many build_tool_version
 * 	structs are present. 
 * 
 * 	It defines a build tool, and it's version. For example:
 * 		LD 520.0.0
 */
struct build_tool_version
{
	uint32_t	tool;		/* enum for the tool */
    uint32_t	version;	/* version number of the tool */
};


/**
 * 	This is a neater version of build_tool_version that has an actual char *
 * 	for the tool name, and then the build version as is found in build_tool_version.
 * 
 */
typedef struct build_tool_info_t {
	char		*tool;
	uint32_t	version;
} build_tool_info_t;


/**
 * 	This struct brings all the Build version types together. It contains the 
 * 	original build version Load Command, but also string reps of the platform
 * 	minos, sdk, the number of build tools, and a HSList of tools.
 * 
 */
typedef struct mach_build_version_info_t {
	mach_build_version_command_t *cmd;
	
	char 		*platform;
	char		*minos;
	char		*sdk;

	uint32_t	 ntools;
	HSList 		*tools;
} mach_build_version_info_t;

/* Known values for the platform field above. */
#define PLATFORM_MACOS 1
#define PLATFORM_IOS 2
#define PLATFORM_TVOS 3
#define PLATFORM_WATCHOS 4
#define PLATFORM_BRIDGEOS 5
#define PLATFORM_MACCATALYST 6
#define PLATFORM_IOSSIMULATOR 7
#define PLATFORM_TVOSSIMULATOR 8
#define PLATFORM_WATCHOSSIMULATOR 9
#define PLATFORM_DRIVERKIT 10

/* Known values for the tool field above. */
#define TOOL_CLANG 1
#define TOOL_SWIFT 2
#define TOOL_LD	3

extern mach_build_version_info_t 		*mach_lc_build_version_info (mach_build_version_command_t *bvc, off_t offset, macho_t *macho);

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 *  An option UUID Load Command containing a 128-bit unique random number that
 *  identifies an object produced by the static link editor.
 * 
 */
struct uuid_command {
    uint32_t        cmd;            /* LC_UUID */
    uint32_t        cmdsize;        /* sizeof (mach_uuid_command_t) */
    uint8_t         uuid[16];       /* 128-bit UUID */
};
// libhelper-macho alias
typedef struct uuid_command         mach_uuid_command_t;

extern mach_uuid_command_t 		        *mach_lc_find_uuid_cmd (macho_t *macho);
extern char 						    *mach_lc_uuid_string (mach_uuid_command_t *cmd);


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 * 	The dyld_info_command contains file offsets and size of the new
 * 	compressed form of the information the dyld needs to load the image.
 * 	On macOS the Dynamic Linker uses the information in this command.
 * 
 * 	[Note]
 * 		These are the docs from loader.h, I'll write them in my own words
 * 		as I learn what they do.
 * 
 */
struct dyld_info_command {

	/**
	 * 	Base Mach-O Load Command data.
	 */
	uint32_t	cmd;			/* LC_DYLD_INFO or LC_DYLD_INFO_ONLY */
	uint32_t	cmdsize;		/* sizeof (mach_dyld_info_command_t) */

	/**
	 * 	Dynamic Linker rebases an image whenever dyld loads it at an address
	 * 	different from its preffered address. The rebase information is a
	 * 	stream of byte sized opcodes whose symbolic names start with REBASE_OPCODE_..
	 * 	
	 * 	Conceptually, the rebase information is a table of tuples:
	 * 		<seg-index, seg-offset, type>
	 * 
	 * 	The opcodes are a compressed way to encode teh table by only encoding
	 * 	when a column changes. In addition, simple patterns like "every n'th
	 * 	offset for m times" can be encoded in a few bytes.
	 * 
	 */
	uint32_t	rebase_off;		/* file offset to rebase info */
	uint32_t	rebase_size;	/* size of rebase info */

	/**
	 * 	Dynamic Linker binds an image during the loading process, if the image
	 * 	requires any pointers to be initialised to symbols in other images. The
	 * 	bind information is a stream of byte sized opcodes whose symbolic
	 * 	names start with BIND_OPCODE_...
	 * 
	 * 	Conceptually, the bind information is a table of tuples:
	 * 		<seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>
	 * 
	 * 	The opcodes are a compressed way to encode teh table by only encoding
	 * 	when a column changes. In addition simple patterns like for runs of
	 * 	pointers initialised to the same value can be encoded in a few bytes.
	 * 
	 */
	uint32_t	bind_off;		/* file offset to binding info */
	uint32_t	bind_size;		/* size of binding info */

	/**
	 * 	Some C++ programs require dyld to unique symbols so that all images
	 * 	in the process use the same copy of some code/data. This step is done
	 * 	after binding. The content of the weak_bind info is an opcode stream
	 * 	like the bind_info. But it is sorted alphabetically by symbol name. This
	 * 	enables dyld to walk all images with weak binding information in order
	 * 	and look for collisions. If there are no collisions, dyld does no updating.
	 * 	That means that some fixups are also encoded in the bind_info. For instnace,
	 * 	all calls the "operator new" are first bound to libstdc++.dylib using
	 * 	the information in bind_info. Then if some image overrides operator new
	 * 	that is detected when the weak_bind information is processed and teh call
	 * 	to operator new is then rebound.
	 * 
	 */
	uint32_t	weak_bind_off;		/* file offset to weak binding info */
	uint32_t	weak_bind_size;		/* size of weak binding info */

	/*
     * 	Some uses of external symbols do not need to be bound immediately.
     * 	Instead they can be lazily bound on first use.  The lazy_bind
     * 	are contains a stream of BIND opcodes to bind all lazy symbols.
     * 	Normal use is that dyld ignores the lazy_bind section when
     * 	loading an image.  Instead the static linker arranged for the
     * 	lazy pointer to initially point to a helper function which 
     * 	pushes the offset into the lazy_bind area for the symbol
     * 	needing to be bound, then jumps to dyld which simply adds
     * 	the offset to lazy_bind_off to get the information on what 
     * 	to bind.  
     */
    uint32_t   lazy_bind_off;	/* file offset to lazy binding info */
    uint32_t   lazy_bind_size;  /* size of lazy binding infs */

	/*
     * 	The symbols exported by a dylib are encoded in a trie.  This
     * 	is a compact representation that factors out common prefixes.
     * 	It also reduces LINKEDIT pages in RAM because it encodes all  
     * 	information (name, address, flags) in one small, contiguous range.
     * 	The export area is a stream of nodes.  The first node sequentially
     * 	is the start node for the trie.  
     *
     * 	Nodes for a symbol start with a uleb128 that is the length of
     * 	the exported symbol information for the string so far.
     * 	If there is no exported symbol, the node starts with a zero byte. 
     * 	If there is exported info, it follows the length.  
	 *
	 * 	First is a uleb128 containing flags. Normally, it is followed by
     * 	a uleb128 encoded offset which is location of the content named
     * 	by the symbol from the mach_header for the image.  If the flags
     * 	is EXPORT_SYMBOL_FLAGS_REEXPORT, then following the flags is
     * 	a uleb128 encoded library ordinal, then a zero terminated
     * 	UTF8 string.  If the string is zero length, then the symbol
     * 	is re-export from the specified dylib with the same name.
	 * 	If the flags is EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER, then following
	 * 	the flags is two uleb128s: the stub offset and the resolver offset.
	 * 	The stub is used by non-lazy pointers.  The resolver is used
	 * 	by lazy pointers and must be called to get the actual address to use.
     *
     * 	After the optional exported symbol information is a byte of
     * 	how many edges (0-255) that this node has leaving it, 
     * 	followed by each edge.
     * 	Each edge is a zero terminated UTF8 of the addition chars
     * 	in the symbol, followed by a uleb128 offset for the node that
     * 	edge points to.
     *  
     */
    uint32_t   export_off;	/* file offset to lazy binding info */
    uint32_t   export_size;	/* size of lazy binding infs */
};
// libhelper-macho alias
typedef struct dyld_info_command            mach_dyld_info_command_t;


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

/**
 * 	Dynamicly linked Shared Library command.
 * 
 * 	This identifies any dynamically shared linked libraries that an
 * 	executable requires.
 * 
 * 	The 'dylib' struct contains the lib properties.
 * 
 * 	The 'dylib_command' is the load command structure.
 * 
 * 	The dylib name string is stored just after the load command structure.
 * 	The offset prop is from the start of the load command structure, so
 * 	the size of the string is:
 * 		s = cmdsize - (sizeof(uint32_t) * 4);
 * 
 */
typedef struct dylib_vers_t {
	uint32_t			a;			/* XXXX.00.00 */
	uint32_t			b;			/* 0000.XX.00 */
	uint32_t			c;			/* 0000.00.XX */
} dylib_vers_t;


/**
 * 	dylib struct defines a dynamic library. The name of the library is
 * 	placed after the structure, but is included in the cmdsize of the
 * 	mach_dylib_command_t.
 * 
 */		
struct dylib {
	uint32_t		offset;					/* Offset of the library name in the string table */
#ifndef __LP64__
	char			*ptr;					/* pointer to the string */
#endif
	
	uint32_t		timestamp;				/* lib build time stamp */
	uint32_t		current_version;		/* lib current version numbre */
	uint32_t		compatibility_version;	/* lib compatibility vers numb */
};


/**
 * 	Base mach_dylib_command_t Load Command that matches that in loader.h
 * 
 */	
typedef struct mach_dylib_command_t {
	uint32_t		cmd;		/* LC_ID_DYLIB, LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB */
	uint32_t		cmdsize;	/* Includes pathname string */
	struct dylib	dylib;
} mach_dylib_command_t;


/**
 * 	Struct holding the original load command struct, which type of dylib
 * 	it is, and the pre-calculated name for the library. 
 * 
 */
typedef struct mach_dylib_command_info_t {
	mach_dylib_command_t	*dylib;
	uint32_t				 type;
	char					*name;
} mach_dylib_command_info_t;


extern char 		*mach_lc_load_dylib_format_version (uint32_t vers);
extern char 		*mach_lc_dylib_get_type_string (mach_dylib_command_t *dylib);


/////////////////////////////////////////////////////////////////////////////////

/**
 *  Programs that use a dynamic linker contain the dylinker_command load command to
 *  identify the name of the dynamic linker used. 
 * 
 *  LC_LOAD_DYLINKER
 */
struct dylinker_command {
    uint32_t        cmd;            /* LC_ID_DYLINKER, LC_LOAD_DYLINKER */
    uint32_t        cmdsize;        /* size, including string at offset */

    uint32_t        offset;         /* offset of the string */
#ifndef __LP64__
    char           *ptr;            /* name of the dylinker */
#endif
};
// libhelper-macho alias
typedef struct dylinker_command             mach_dylinker_command_t;

extern char 		*mach_lc_load_dylinker_name (macho_t *macho, mach_dylinker_command_t *dylinker, off_t offset);

/////////////////////////////////////////////////////////////////////////////////

/**
 *  The entry_point_command is described as being a replacement for the thread_command
 *  and is used for main executable to specify the location (offset) of the main()
 *  function.
 */
struct entry_point_command {
    uint32_t        cmd;            /* LC_MAIN */
    uint32_t        cmdsize;        /* size of LC_MAIN */
    uint64_t        entryoff;       /* offset of main() */
    uint64_t        stacksize;      /* initial stack size */
};
// libhelper-macho alias
typedef struct entry_point_command          mach_entry_point_command_t;

/////////////////////////////////////////////////////////////////////////////////

/**
 *  The linkedit_data_command contains the offsets and sizes of a blog
 *  of data in the __linkedit segment.
 * 
 * 	LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO, LC_FUNCTION_STARTS, 
 * 	LC_DATA_IN_CODE, LC_DYLIB_CODE_SIGN_DRS, LC_LINKER_OPTIMIZATION_HINT
 * 	LC_DYLD_EXPORTS_TIRE, LC_DYLD_CHAINED_FIXUPS
 */
struct linkedit_data_command {
    uint32_t        cmd;            /* above commands */
    uint32_t        cmdsize;        /* sizeof (link_Edit_command) */
    uint32_t        dataoff;        /* file offset of data in __LINKEDIT */
    uint32_t        datasize;       /* file size of data in __LINKEDIT */
};
// libhelper-macho alias
typedef struct linkedit_data_command        mach_linkedit_data_command_t;

/////////////////////////////////////////////////////////////////////////////////

/**
 *  rpath_command contains a path which at runtime should be added to the
 *  current runpath used to find @rpath prefix dylibs. 
 * 
 *  LC_RPATH
 */
struct rpath_command {
    uint32_t        cmd;            /* LC_RPATH */
    uint32_t        cmdsize;        /* size of command */

    uint32_t        offset;         /* offset of the path string */
#ifndef __LP64__
    char           *ptr;            /* path string */
#endif
};
// libhelper-macho alias
typedef struct rpath_command                mach_rpath_command_t;

/////////////////////////////////////////////////////////////////////////////////

/**
 *  The LC_FILESET_ENTRY command describes constituent Mach-O files that are part
 *  of what Apple calls a "fileset". Entries are their own Mach-O files, for example
 *  dylibs, with their own headers nad text, data segments. Each entry is further
 *  described by it's own header.
 * 
 */
struct fileset_entry_command {
    uint32_t        cmd;            /* LC_FILESET_ENTRY */
    uint32_t        cmdsize;        /* size, including entry_id strings */
    uint64_t        vmaddr;         /* memory address of the entry */
    uint64_t        fileoff;        /* file offset of the entry */

    uint32_t        offset;         /* contained entry_id */
#ifndef __LP64__
    char           *ptr;
#endif  
    uint32_t        reserved;       /* reserved */
};
// libhelper-macho alias
typedef struct fileset_entry_command        mach_fileset_entry_t;

extern char         *mach_lc_load_fileset_entry_name (macho_t *macho, mach_fileset_entry_t *fileset, off_t offset);

/***********************************************************************
* Mach-O Static Symbol Load Commands.
*
*   Symbols and Dynamic symbols are separated just for organisation.
*
************************************************************************/

/**
 *  The symtab_command structure forms the basis of the symbols listed
 *  within a Mach-O.
 * 
 */
struct symtab_command {
	uint32_t	cmd;			/* LC_SYMTAB */
	uint32_t	cmdsize;		/* sizeof(mach_symtab_command_t) */
	uint32_t	symoff;			/* offset of the symbol table */
	uint32_t	nsyms;			/* number of symbols */
	uint32_t	stroff;			/* offset of the string table */
	uint32_t	strsize;		/* size of the string table in bytes */
};
// libhelper-macho alias
typedef struct symtab_command   mach_symtab_command_t;

/**
 *  The nlist structure make up the entries in the symbol table.
 * 
 */
typedef struct nlist {
    uint32_t    n_strx;         /* index into the string table */

    uint8_t     n_type;         /* type flag */
    uint8_t     n_sect;         /* section number, or NO_SECT */
    uint16_t    n_desc;         /* see stab.h */
    uint64_t    n_value;        /* value of this symbol (or stab offset) */
} nlist;

/**
 *  Symbol Table structure is a libhelper wrapper for the Mach-O symbol
 *  table.
 * 
 */
struct __libhelper_mach_symbol_table {
    mach_symtab_command_t   *cmd;       /* LC_SYMTAB */
    HSList                  *symbols;   /* list of symbols */
};
typedef struct __libhelper_mach_symbol_table        mach_symbol_table_t;

/*
 * The n_type field really contains four fields:
 *	unsigned char N_STAB:3,
 *		      N_PEXT:1,
 *		      N_TYPE:3,
 *		      N_EXT:1;
 * which are used via the following masks.
 */
#define	N_STAB	0xe0  /* if any of these bits set, a symbolic debugging entry */
#define	N_PEXT	0x10  /* private external symbol bit */
#define	N_TYPE	0x0e  /* mask for the type bits */
#define	N_EXT	0x01  /* external symbol bit, set for external symbols */

/*
 * Values for N_TYPE bits of the n_type field.
 */
#define	N_UNDF	0x0		/* undefined, n_sect == NO_SECT */
#define	N_ABS	0x2		/* absolute, n_sect == NO_SECT */
#define	N_SECT	0xe		/* defined in section number n_sect */
#define	N_PBUD	0xc		/* prebound undefined (defined in a dylib) */
#define N_INDR	0xa		/* indirect */


// Functions
extern mach_symtab_command_t        *mach_symtab_command_create     ();
extern mach_symtab_command_t        *mach_symtab_command_load       (macho_t *macho, uint32_t offset);
extern mach_symbol_table_t          *mach_symtab_load_symbols       (macho_t *macho, mach_symtab_command_t *symbol_table);
extern char                         *mach_symtab_find_symbol_name   (macho_t *macho, nlist *sym, mach_symtab_command_t *cmd);

extern char                         *mach_symtab_find_symbol_name   (macho_t *macho, nlist *sym, mach_symtab_command_t *cmd);

extern mach_symtab_command_t        *mach_lc_find_symtab_cmd        (macho_t *macho);

/***********************************************************************
* Mach-O Dynamic Symbol Load Commands.
*
*   Symbols and Dynamic symbols are separated just for organisation.
*
************************************************************************/

/**
 *  The Dynamic Symbol Table command structure. More docs in `loader.h`
 * 
 */
struct dysymtab_command {
    uint32_t cmd;	/* LC_DYSYMTAB */
    uint32_t cmdsize;	/* sizeof(struct dysymtab_command) */

    /*
     * The symbols indicated by symoff and nsyms of the LC_SYMTAB load command
     * are grouped into the following three groups:
     *    local symbols (further grouped by the module they are from)
     *    defined external symbols (further grouped by the module they are from)
     *    undefined symbols
     *
     * The local symbols are used only for debugging.  The dynamic binding
     * process may have to use them to indicate to the debugger the local
     * symbols for a module that is being bound.
     *
     * The last two groups are used by the dynamic binding process to do the
     * binding (indirectly through the module table and the reference symbol
     * table when this is a dynamically linked shared library file).
     */
    uint32_t ilocalsym;	/* index to local symbols */
    uint32_t nlocalsym;	/* number of local symbols */

    uint32_t iextdefsym;/* index to externally defined symbols */
    uint32_t nextdefsym;/* number of externally defined symbols */

    uint32_t iundefsym;	/* index to undefined symbols */
    uint32_t nundefsym;	/* number of undefined symbols */

    /*
     * For the for the dynamic binding process to find which module a symbol
     * is defined in the table of contents is used (analogous to the ranlib
     * structure in an archive) which maps defined external symbols to modules
     * they are defined in.  This exists only in a dynamically linked shared
     * library file.  For executable and object modules the defined external
     * symbols are sorted by name and is use as the table of contents.
     */
    uint32_t tocoff;	/* file offset to table of contents */
    uint32_t ntoc;	/* number of entries in table of contents */

    /*
     * To support dynamic binding of "modules" (whole object files) the symbol
     * table must reflect the modules that the file was created from.  This is
     * done by having a module table that has indexes and counts into the merged
     * tables for each module.  The module structure that these two entries
     * refer to is described below.  This exists only in a dynamically linked
     * shared library file.  For executable and object modules the file only
     * contains one module so everything in the file belongs to the module.
     */
    uint32_t modtaboff;	/* file offset to module table */
    uint32_t nmodtab;	/* number of module table entries */

    /*
     * To support dynamic module binding the module structure for each module
     * indicates the external references (defined and undefined) each module
     * makes.  For each module there is an offset and a count into the
     * reference symbol table for the symbols that the module references.
     * This exists only in a dynamically linked shared library file.  For
     * executable and object modules the defined external symbols and the
     * undefined external symbols indicates the external references.
     */
    uint32_t extrefsymoff;	/* offset to referenced symbol table */
    uint32_t nextrefsyms;	/* number of referenced symbol table entries */

    /*
     * The sections that contain "symbol pointers" and "routine stubs" have
     * indexes and (implied counts based on the size of the section and fixed
     * size of the entry) into the "indirect symbol" table for each pointer
     * and stub.  For every section of these two types the index into the
     * indirect symbol table is stored in the section header in the field
     * reserved1.  An indirect symbol table entry is simply a 32bit index into
     * the symbol table to the symbol that the pointer or stub is referring to.
     * The indirect symbol table is ordered to match the entries in the section.
     */
    uint32_t indirectsymoff; /* file offset to the indirect symbol table */
    uint32_t nindirectsyms;  /* number of indirect symbol table entries */

    /*
     * To support relocating an individual module in a library file quickly the
     * external relocation entries for each module in the library need to be
     * accessed efficiently.  Since the relocation entries can't be accessed
     * through the section headers for a library file they are separated into
     * groups of local and external entries further grouped by module.  In this
     * case the presents of this load command who's extreloff, nextrel,
     * locreloff and nlocrel fields are non-zero indicates that the relocation
     * entries of non-merged sections are not referenced through the section
     * structures (and the reloff and nreloc fields in the section headers are
     * set to zero).
     *
     * Since the relocation entries are not accessed through the section headers
     * this requires the r_address field to be something other than a section
     * offset to identify the item to be relocated.  In this case r_address is
     * set to the offset from the vmaddr of the first LC_SEGMENT command.
     * For MH_SPLIT_SEGS images r_address is set to the the offset from the
     * vmaddr of the first read-write LC_SEGMENT command.
     *
     * The relocation entries are grouped by module and the module table
     * entries have indexes and counts into them for the group of external
     * relocation entries for that the module.
     *
     * For sections that are merged across modules there must not be any
     * remaining external relocation entries for them (for merged sections
     * remaining relocation entries must be local).
     */
    uint32_t extreloff;	/* offset to external relocation entries */
    uint32_t nextrel;	/* number of external relocation entries */

    /*
     * All the local relocation entries are grouped together (they are not
     * grouped by their module since they are only used if the object is moved
     * from it staticly link edited address).
     */
    uint32_t locreloff;	/* offset to local relocation entries */
    uint32_t nlocrel;	/* number of local relocation entries */

};
// libhelper-macho alias
typedef struct dysymtab_command         mach_dysymtab_command_t;


// Functions
extern mach_dysymtab_command_t              *mach_lc_find_dysymtab_cmd      (macho_t *macho);


/////////////////////////////////////////////////////////////////////////////////////





#ifdef cplusplus
}
#endif

#endif /* libhelper_macho_h */
