//===------------------------------------------------------------------===//
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
//  Copyright (C) 2021, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//

#ifndef LIBHELPER_IMG4_H
#define LIBHELPER_IMG4_H

/* Headers */
#if defined(__APPLE__) && defined(__MACH__)
#   define IMG4_HELPER_USE_COMMONCRYPTO
#   include <CommonCrypto/CommonCrypto.h>
#else
#   define IMG4_HELPER_USE_OPENSSL
#   include <openssl/aes.h>
#   include <openssl/sha.h>
#endif

#include "../../libhelper/compression/lzfse.h"
#include "../../libhelper/compression/lzss.h"
#include "asn1.h"


#define BLOCK_SIZE		(16)

/* These are different types of Image4 */
#define IMAGE_TYPE_DIAG					"diag"	// diagnostics
#define IMAGE_TYPE_LLB					"illb"	// iboot first-stage loader
#define IMAGE_TYPE_IBOOT				"ibot"	// iboot second-stage loader
#define IMAGE_TYPE_IBSS					"ibss"	// iboot single stage
#define IMAGE_TYPE_IBEC					"ibec"	// iboot epoch change
#define IMAGE_TYPE_DEVTREE				"dtre"	// darwin device tree
#define IMAGE_TYPE_RAMDISK				"rdsk"	// darwin ram disk for restore
#define IMAGE_TYPE_KERNELCACHE			"krnl"	// darwin kernel cache
#define IMAGE_TYPE_LOGO					"logo"	// boot logo image
#define IMAGE_TYPE_RECMODE				"recm"	// recovery mode image
#define IMAGE_TYPE_NEEDSERVICE			"nsrv"	// need service image
#define IMAGE_TYPE_GLYPHCHRG			"glyC"	// glyph charge image
#define IMAGE_TYPE_GLYPHPLUGIN			"glyP"	// glyph plug in image
#define IMAGE_TYPE_BATTERYCHARGING0		"chg0"  // battery charging image - bright
#define IMAGE_TYPE_BATTERYCHARGING1		"chg1"  // battery charging image - dim
#define IMAGE_TYPE_BATTERYLOW0			"bat0"	// battery low image - empty
#define IMAGE_TYPE_BATTERYLOW1			"bat1"	// battery low image - red (composed onto empty)
#define IMAGE_TYPE_BATTERYFULL			"batF"	// battery full image list
#define IMAGE_TYPE_OS_RESTORE			"rosi"	// OS image for restore
#define IMAGE_TYPE_SEP_OS				"sepi"	// SEP OS image
#define IMAGE_TYPE_SEP_OS_RESTORE		"rsep"	// SEP OS image for restore
#define IMAGE_TYPE_HAMMER				"hmmr"	// PE's Hammer test


/* Image type */
typedef enum {
	IMG4_TYPE_ALL,
	IMG4_TYPE_IMG4,
	IMG4_TYPE_IM4P,
	IMG4_TYPE_IM4M,
	IMG4_TYPE_IM4R
} Image4Type;

/**
 * 	This is not a struct for the file structure, its to hold some
 * 	info, the size and a loaded buffer of the img4/im4p/im4m/im4r
 * 	file.
 */
typedef struct image4_t {

	/* File buffer and size */
	char *buf;
	size_t size;

	/* Image4 variant and component (krnl, ibot, etc...) */
	Image4Type type;
	char *component;

} image4_t;


/**
 * 	Compression header for lzss. This code was from Jonathan Levin's
 * 	Joker tool, along with some more code in img4_decompress_lzss.
 * 
 * 	There are vars for the signature/magic, unknown data that isn't
 * 	required, and the uncompressed and compressed sizes.
 */
struct compHeader {
	char		sig[8];
	uint32_t	unknown;
	uint32_t	uncompressedSize;
	uint32_t	compressedSize;
	uint32_t 	unknown1;
};


#endif /* libhelper_img4_h */
