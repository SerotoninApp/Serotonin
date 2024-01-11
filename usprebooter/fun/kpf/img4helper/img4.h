//===------------------------------ img4.h --------------------------------===//
//
//                                Img4Helper
//
// 	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
// 	but WITHOUT ANY WARRANTY; without even the implied warranty of
// 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
// 	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//  me@h3adsh0tzz.com.
//
//
//===-----------------------------------------------------------------------===//

#ifndef IMG4_H
#define IMG4_H

/* Headers */
//#include <lzfse.h>

#if defined(__APPLE__) && defined(__MACH__)
#	define IMG4_HELPER_USE_COMMONCRYPTO
#	include <CommonCrypto/CommonCrypto.h>
#else
#	define IMG4_HELPER_USE_OPENSSL
#	include <openssl/aes.h>
#	include <openssl/sha.h
#endif

//#include <libhelper-lzfse/lzfse.h>
//#include <libhelper-lzss/lzss.h>
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


/**
 * 	Functions for handling and manipulating image4_t's
 * 
 */
image4_t 	*img4_read_image_from_path (char *path);
char 		*img4_string_for_image_type (Image4Type print_type);
char 		*img4_get_component_name (char *buf);


/**
 * 	Functions for handling different compression and encryption
 * 	types of iOS firmware components. 
 * 
 * 	There are two types of compression used with iOS firmware files,
 * 	namely bvx2 (lzfse) and lzss. The type of compression can be
 * 	observed in a hexdump of a im4p/img4.
 * 
 * 	Image4 files can be encrypted with an AES iv-key. Image4's
 * 	contain a KBAG in the im4p which is an encrypted AES IVKEY with
 * 	the specific device AP Group ID (GID) key. 
 * 
 * 	The Image4CompressionType type represents the four possible states
 * 	of compression an Image4 can be in. If the type is encrypted, the
 * 	process of checking the compression type and handling should be
 * 	performed again, which will determine whether the file was actually
 * 	encrypted, or if the key was valid.
 * 
 * 	img4_check_compression_type () will verify what type of compression
 * 	the image is using. The value can by of four types, bvx2, lzss, enc
 * 	or nocomp. 
 * 
 * 	img4_decompress_bvx2 () will decompress a given buffer using bvx2.
 * 	The given buffer should have been verified before being given to
 * 	this function as it won't be verified again.
 * 
 * 	img4_decompress_lzss () will decompress a given buffer using lzss.
 * 	The given buffer should have been verified before being given to
 * 	this function as it won't be verified again.
 * 
 * 	img4_decrypt_bytes () will decrypt a given buffer with a given ivkey
 * 	pair. The given buffer should have been verified before being given to
 * 	this function as it won't be verified again.
 */

typedef enum {

	/* bvx2 and lzss */
	IMG4_COMP_BVX2,
	IMG4_COMP_LZSS,

	/* encryption */
	IMG4_COMP_ENCRYPTED,

	/* None */
	IMG4_COMP_NONE

} Image4CompressionType;

Image4CompressionType img4_check_compression_type (char *buf);

image4_t *img4_decompress_bvx2 (image4_t *img);
image4_t *img4_decompress_lzss (image4_t *img);

image4_t *img4_decompress_bvx2_decrypted_buffer (image4_t *img, char *in, size_t insize);
image4_t *img4_decrypt_bytes (image4_t *img, char *_key, int dont_decomp);


/**
 * 	Functions for extracting sections of Image4 files.
 * 
 * 	img4_extract_im4p () decompresses and decrypts im4p sections as necessary
 * 	from a specified file, decrypts if required with the ivkey and writes
 * 	the result to the specified outfile.
 * 
 */
void img4_extract_im4p (char *infile, char *outfile, char *ivkey, int dont_decomp);


/**
 * 	Functions for handling specific types of Image4 files.
 * 
 * 	Note: Full .img4 files should call handle_img4(), which will then
 * 	split the file and call the respective handle_x functions for the
 * 	part of the file being worked on.
 * 
 * 	All functions take the same arguments. The buf is the loaded
 * 	image file, and the tabs are how many indentations to print the
 * 	data in.
 * 
 * 	The handle() function will take an image_t and use the correct
 * 	function.
 * 
 */
void img4_handle (image4_t *image);

void img4_handle_img4 (char *buf, int tabs);
void img4_handle_im4p (char *buf, int tabs);
void img4_handle_im4m (char *buf, int tabs);
void img4_handle_im4r (char *buf, int tabs);


/**
 * 	Functions for printing Image4's.
 *
 * 	One passes the Image4 type and the filename to load to this function,
 * 	the filename is that loaded and an image4_t is constructed and passed
 * 	to img4_handle.
 * 
 */
void img4_print_with_type (Image4Type type, char *filename);


// test
char *im4p_extract_silent (char *fn);

#endif /* IMG4_H */
