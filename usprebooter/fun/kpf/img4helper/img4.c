//===------------------------------ img4.c --------------------------------===//
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

#include "img4.h"
#include "../libhelper/libhelper/compression/lzfse.h"
#include "../libhelper/libhelper/compression/lzss.h"

//////////////////////////////////////////////////////////////////
/*				   IM4P/IM4M Specific Funcs						*/
//////////////////////////////////////////////////////////////////


/**
 * 	img4_read_image_from_path ()
 * 
 * 	The Image4 situated at path will be read in and used to construct an
 * 	image4_t type, which contains a few properties about an Image4 file
 * 	that is useful for other functions and operations.
 * 
 * 	Args:
 * 		char *path			-	The path to the Image4 that should be loaded
 * 	
 * 	Returns:
 * 		image4_t			-	The constructed image4_t type.
 * 
 */
image4_t *img4_read_image_from_path (char *path)
{
	/* Create our image4_t to populate and return */
	image4_t *image = malloc (sizeof (image4_t));

	/* The path should have already been verified by the caller */
    printf("path: %s\n", path);
	FILE *f = fopen (path, "rb");
	if (!f) {
		printf ("[Error] Could not read file!\n");
		exit(0);
	}

	/* Check the files size in bytes */
	fseek (f, 0, SEEK_END);
	image->size = ftell (f);
	fseek (f, 0, SEEK_SET);

	/* Start reading bytes into the buffer */
	image->buf = malloc (image->size);
	if (image->buf) fread (image->buf, image->size, 1, f);
	
	/* Close the file */
	fclose (f);

	/* Calculate the image file type */
	char *magic = getImageFileType (image->buf);
	if (!magic) {
		printf ("[Error] Input file could not be recognised as an Image4\n");
		exit (0);
	}

	/* Go through and check each of the magics */
	if (!strncmp (magic, "IMG4", 4)) {
		image->type = IMG4_TYPE_IMG4;
	} else if (!strncmp (magic, "IM4P", 4)) {
		image->type = IMG4_TYPE_IM4P;
	} else if (!strncmp (magic, "IM4M", 4)) {
		image->type = IMG4_TYPE_IM4M;
	} else if (!strncmp (magic, "IM4R", 4)) {
		image->type = IMG4_TYPE_IM4R;
	} else {
		printf ("[Error] Input file could not be recognised as an Image4\n");
		exit (0);
	}

	/* Return the newly created image */
	return image;

}


/**
 * 	img4_string_for_image_type ()
 * 
 * 	Takes an Image4Type enum and translates into a string, as enums are
 * 	stored as integers.
 * 
 * 	Args:
 * 		Image4Type type 	-	The type to translate
 * 
 * 	Returns:
 * 		char *				-	The string translation of the type.
 * 
 */
char *img4_string_for_image_type (Image4Type type)
{
	if (type == IMG4_TYPE_IMG4) {
		return "IMG4";
	} else if (type == IMG4_TYPE_IM4P) {
		return "IM4P";
	} else if (type == IMG4_TYPE_IM4M) {
		return "IM4M";
	} else if (type == IMG4_TYPE_IM4R) {
		return "IM4R";
	} else {
		return "Unknown";
	}
}


/**
 * 	img4_get_component_name ()
 * 
 * 	Takes an image buffer and determines which firmware file is has been taken
 * 	from. For example: 'krnl' == 'KernelCache', 'ibot' == 'iBoot'.
 * 
 * 	Args:
 * 		char *		-	The payload bytes
 * 
 * 	Returns:
 * 		char *		-	The component type string.
 * 
 */
char *img4_get_component_name (char *buf)
{
	char *magic;
	size_t l;
	getSequenceName(buf, &magic, &l);

	if (!strncmp (magic, "img4", 4)) {
		printf ("magic is img4\n");
		buf = getIM4PFromIMG4 (buf);
	}

	char *raw = asn1ElementAtIndex(buf, 1) + 2;

	if (!strncmp (raw, "ibot", 4)) {
		return "iBoot";
	} else if (!strncmp (raw, IMAGE_TYPE_IBEC, 4)) {
		return "iBoot Epoch Change (iBEC)";
	} else if (!strncmp (raw, IMAGE_TYPE_IBSS, 4)) {
		return "iBoot Single Stage (iBSS)";
	} else if (!strncmp (raw, IMAGE_TYPE_LLB, 4)) {
		return "Low Level Bootloader (LLB)";
	} else if (!strncmp (raw, IMAGE_TYPE_SEP_OS, 4)) {
		return "Secure Enclave OS (SEP OS)";
	} else if (!strncmp (raw, IMAGE_TYPE_SEP_OS_RESTORE, 4)) {
		return "Secure Enclave OS Restore (SEP OS RESTORE)";
	} else if (!strncmp (raw, IMAGE_TYPE_DEVTREE, 4)) {
		return "Device Tree";
	} else if (!strncmp (raw, IMAGE_TYPE_RAMDISK, 4)) {
		return "Update/Restore Ramdisk";
	} else if (!strncmp (raw, IMAGE_TYPE_KERNELCACHE, 4)) {
		return "Darwin Kernel Cache";
	} else if (!strncmp (raw, IMAGE_TYPE_LOGO, 4)) {
		return "Boot Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_RECMODE, 4)) {
		return "Recovery Mode Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_NEEDSERVICE, 4)) {
		return "Need Service Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_GLYPHCHRG, 4)) {
		return "Glyph Charge Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_GLYPHPLUGIN, 4)) {
		return "Glyph Plugin Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_BATTERYCHARGING0, 4)) {
		return "Battery Charging 0 Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_BATTERYCHARGING1, 4)) {
		return "Battery Charging 1 Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_BATTERYLOW0, 4)) {
		return "Battery Charging Low 0 Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_BATTERYLOW1, 4)) {
		return "Battery Charging Low 1 Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_BATTERYFULL, 4)) {
		return "Battery Full Logo";
	} else if (!strncmp (raw, IMAGE_TYPE_OS_RESTORE, 4)) {
		return "iOS Restore Image";
	} else if (!strncmp (raw, IMAGE_TYPE_HAMMER, 4)) {
		return "Hammer";
	} else {
		return "Unknown Component";
	}
}


/**
 * 	img4_handle_im4p ()
 * 
 * 	Takes the byte stream of an .im4p, or the im4p section of an .img4, and
 * 	a tab count. The im4p is parsed and each element is printed in a formatted
 * 	way according to the tab count. If there are any errors, the program should
 * 	gracefully exit as there are multiple error checks
 * 
 * 	Args:
 * 		char *buf 		-	The im4p buffer
 * 		int tabs 		-	Amount of whitespace to print before the elements
 * 
 */
void img4_handle_im4p (char *buf, int tabs)
{
	/* Generate a padding string for tabs */
	char *padding = malloc(sizeof(char) * tabs);
	for (int i = 0; i < tabs; i++) {
		padding[i] = '\t';
	}

	/* Print the IM4P banner */
	printf ("  IM4P: ------\n");

	/* We can't really use image4_t here, so we have to calculate everything */
	char *magic;
	size_t l;
	getSequenceName(buf, &magic, &l);

	/* Verify that we have been given an im4p buffer */
	if (strncmp("IM4P", magic, l)) {
		printf ("%s[Error] Expected \"IM4P\", got \"%s\"\n", padding, magic);
	}

	// TODO: counting more elemnts than it should. Images without kbags are still being parsed
	/* Grab the amount of ASN1 elements in the buffer */
	int elems = asn1ElementsInObject(buf);

	/* Print the Image type, desc and size */
	if (--elems > 0) {
		printStringWithKey("Type", (asn1Tag_t *) asn1ElementAtIndex(buf, 1), padding);
	}
	if (--elems > 0) {
		printStringWithKey("Desc", (asn1Tag_t *) asn1ElementAtIndex(buf, 2), padding);
	}
	if (--elems > 0) {

		/* Check the data size and print it. */
		asn1Tag_t *data = (asn1Tag_t *) asn1ElementAtIndex(buf, 3);
		if (data->tagNumber != kASN1TagOCTET) {
			printf ("%s[Warning] Skipped an unexpected tag where an OCTETSTRING was expected\n", padding);
		} else {
			printf ("%sSize: 0x%08zx\n\n", padding, asn1Len((char *) data + 1).dataLen);
		}
	}

	// Check for KBAG values. There should be two on encrypted images, with the first being PRODUCT
	//      and the seccond being DEVELOPMENT.
	//
	//	THIS DOES NOT WORK AND NEEDS TO BE FIXED
	// 	REWRITE WHOLE FUNCTION
	//
	if (elems < 1) {
		printf ("%sThis IM4P is not encrypted, no KBAG values\n", padding);
		exit(1);
	}
	img4PrintKeybag ((char *) asn1ElementAtIndex(buf, 4), padding);

}


/**
 * 	img4_handle_im4m ()
 * 
 * 	Similar to img4_handle_im4p (), takes the .im4m or im4m section buffer and
 * 	a tab count, then prints formatted information contained within the manifest.
 * 
 * 	Args:
 * 		char *buf 		-	The im4m buffer
 * 		int tags		-	 Amount of whitespace to print before the elements
 * 
 */
void img4_handle_im4m (char *buf, int tabs)
{
	char *padding = malloc(sizeof(char) * tabs);
	for (int i = 0; i < tabs; i++) {
		padding[i] = '\t';
	}

	// Print IM4M
	printf("  IM4M: ------\n");

	// Get buf magic
	char *magic;
	size_t l;
	getSequenceName(buf, &magic, &l);

	// Check the magic matches IM4M
	if (strncmp("IM4M", magic, l)) {
		printf ("%sFile does not contain an IM4M\n", padding);
		return;
	}

	// Check the IM4M has at least two elems
	int elems = asn1ElementsInObject (buf);
	if (elems < 2) {
		printf ("%s[Error] Expecting at least 2 elements\n", padding);
		exit(1);
	}

	// Print the IM4M Version
	if (--elems > 0) {
		printf("%sVersion: ", padding);
		asn1PrintNumber((asn1Tag_t *) asn1ElementAtIndex(buf, 1), "");
		putchar('\n');
		putchar('\n');
	}

	// Go through each IM4M element and print it
	if (--elems > 0) {

		// Manifest Body parse
		asn1Tag_t *manbset = (asn1Tag_t *) asn1ElementAtIndex(buf, 2);
		if (manbset->tagNumber != kASN1TagSET) {
			printf ("%s[Error] Expecting SET\n", padding);
			exit(1);
		}

		asn1Tag_t *privtag = manbset + asn1Len((char *) manbset + 1).sizeBytes + 1;

		size_t sb;
		asn1PrintPrivtag(asn1GetPrivateTagnum(privtag++, &sb), padding);
		printf(":\n");

		char *manbseq = (char *)privtag + sb;
		manbseq += asn1Len(manbseq).sizeBytes + 1;

		img4PrintManifestBody(manbseq, padding);
	}
}


/**
 * 	img4_handle_im4r ()
 * 
 * 	Similar to img4_handle_im4p (), takes the .im4r or im4r section buffer and
 * 	a tab count, then prints formatted information contained within the im4r.
 * 
 * 	Args:
 * 		char *buf 		-	The im4r buffer
 * 		int tags		-	Amount of whitespace to print before the elements
 * 
 */
void img4_handle_im4r (char *buf, int tabs)
{
	/* Calculate padding */
	char *padding = malloc (sizeof (char) * tabs);
	for (int i = 0; i < tabs; i++) {
		padding[i] = '\t';
	}

	/* Print IM4R banner */
	printf ("%sIM4R: ------\n", padding);

	/* Verify the buf magic */
	char *magic;
	size_t l;
	getSequenceName (buf, &magic, &l);

	/* Check the magic matches IM4R */
	if (strncmp (magic, "IM4R", 4)) {
		printf ("%sFile does not contain an IM4R\n", padding);
		exit (0);
	}

	/* Verify the amount of elements in the IM4R */
	int elems = asn1ElementsInObject (buf);
	if (elems < 2) {
		printf ("%s[Error] Expecting at least 2 elements\n", padding);
		exit (0);
	}

	/* The BNCN is contained within an ASN1 SET */
	asn1Tag_t *set = (asn1Tag_t *) asn1ElementAtIndex (buf, 1);
	if (set->tagNumber != kASN1TagSET) {
		printf ("%s[Error] Expecting SET\n", padding);
		exit (0);
	}

	/* Remove a few bytes from the start of the SET so we get to the next elem */
	set += asn1Len ((char *) set + 1).sizeBytes + 1;
	
	/* Check if the tag is private */
	if (set->tagClass != kASN1TagClassPrivate) {
		printf ("%s[Error] Expecting Tag of private type\n", padding);
		exit (0);
	}
	
	/* Print the private tag, which should be "BNCN" */
	asn1PrintPrivtag (asn1GetPrivateTagnum (set++, 0), padding);
	printf ("\n");

	/* Advance to the next value */
	set += asn1Len ((char *) set).sizeBytes + 1;
	elems += asn1ElementsInObject ((char *) set);

	/* Check that there is still two values left in the set */
	if (elems < 2) {
		printf ("%s[Error] Expecting at least 2 values\n", padding);
		exit (0);
	}

	/* Print the tag key */
	asn1PrintIA5String ((asn1Tag_t *) asn1ElementAtIndex ((char *) set, 0), padding);
	printf (": ");

	/* Print it's value */
	asn1PrintOctet ((asn1Tag_t *) asn1ElementAtIndex ((char *) set, 1), padding);
	printf ("\n");

}


//////////////////////////////////////////////////////////////////
/*				    Image Decomp/Decrypt						*/
//////////////////////////////////////////////////////////////////


/**
 * 	img4_check_compression_type ()
 * 
 * 	Takes a given buffer, hopefully verified to be an im4p, and checks
 * 	the compression or encryption state of that buffer. The return value
 * 	is of the Image4CompressionType type. 
 * 
 * 	Args:
 * 		char *buf 				-	The verified im4p buffer
 * 
 * 	Return:
 * 		Image4CompressionType	-	The type of compression
 * 
 */
Image4CompressionType img4_check_compression_type (char *buf)
{
	/* Get the element count and ensure buf is an im4p */
	int c = asn1ElementsInObject (buf);
	if (c < 4) {
		printf ("[Error] Not enough elements in given payload\n");
		exit (0);
	}

	/* Try to select the payload tag from the buffer */
	char *tag = asn1ElementAtIndex (buf, 3) + 1;
	asn1ElemLen_t len = asn1Len (tag);
	char *data = tag + len.sizeBytes;

	/* Check for either lzss or bvx2/lzfse */
	if (!strncmp (data, "complzss", 8)) {
		return IMG4_COMP_LZSS;
	} else if (!strncmp (data, "bvx2", 4)) {
		return IMG4_COMP_BVX2;
	} else if (!strncmp (data, "TEXT", 4)) {
		return IMG4_COMP_NONE;
	} else {
		return IMG4_COMP_ENCRYPTED;
	}

}


//////////////////////////////////////////////////////////////////
/*				    Image Extracting Func						*/
//////////////////////////////////////////////////////////////////


/**
 * 	img4_decompress_bvx2 ()
 * 
 * 	Takes the given image4_t and decompresses it using bvx2. The
 * 	result is written back to an image and returned. Assumes that
 * 	the images compression type has already been checked and verified.
 * 
 * 	Args:
 * 		image4_t *img		-	Compressed Image4 file
 * 
 * 	Returns:
 * 		image4_t			- 	Decompressed Image4 file
 * 
 */
image4_t *img4_decompress_bvx2 (image4_t *img)
{
	char *tag = asn1ElementAtIndex (img->buf, 3) + 1;
	asn1ElemLen_t len = asn1Len (tag);
	char *data = tag + len.sizeBytes;

	char *compTag = data + len.dataLen;
	char *fakeCompSizeTag = asn1ElementAtIndex (compTag, 0);
	char *uncompSizeTag = asn1ElementAtIndex (compTag, 1);

	size_t fake_src_size = asn1GetNumberFromTag ((asn1Tag_t *) fakeCompSizeTag);
	size_t dst_size = asn1GetNumberFromTag ((asn1Tag_t *) uncompSizeTag);

	size_t src_size = len.dataLen;

	if (fake_src_size != 1) {
		printf ("[Error] fake_src_size not 1 but 0x%zx!\n", fake_src_size);
	}

	img->buf = malloc (dst_size);

	size_t uncomp_size = lzfse_decode_buffer ((uint8_t *) img->buf, dst_size,
											  (uint8_t *) data, src_size,
											  NULL);

	if (uncomp_size != dst_size) {
		printf ("[Error] Expected to decompress %zu bytes but only got %zu bytes\n", dst_size, uncomp_size);
		exit(1);
	}			

	img->size = dst_size;
	
	return img;

}


/**
 * 	img4_decompress_lzss ()
 * 
 * 	Takes a given image4_t and decompresses it using lzss. The
 * 	result is written back to an image and returned. Assumes that
 * 	the image compression type has already been checked and verified.
 * 
 * 	Args:
 * 		image4_t *img		-	Compressed Image4 file.
 * 	
 * 	Returns:
 * 		image4_t			-	Decompressed Image4 file.
 * 
 */
image4_t *img4_decompress_lzss (image4_t *img)
{

	/**
	 * 	Create a new compheader with the img buffer. This allows us to
	 * 	access the different properties of the buffer.
	 */
	struct compHeader *compHeader = (struct compHeader *) strstr (img->buf, "complzss");

	/* Print some details about the size of the buffer */
	printf ("[*] Compressed size: %u, Uncompressed Size: %u\n", ntohl(compHeader->compressedSize), ntohl(compHeader->uncompressedSize));

	/**
	 * 	TODO: Add KPP and other useful detections as functions in, say, kernel.c or darwin.c
	 * 
	 * 	This is some code used by Morpheus for doing that very thing:
	 * 
	 * 	1	int sig[2] = { 0xfeedfacf, 0x0100000c };
	 *  2
	 * 	3	char *found = NULL;
	 *  4	if ((found = memmem(buffer + 0x2000, buf_size, "__IMAGEEND", 8))) {
	 * 	5		char *kpp = memmem (found - 0x1000, 0x1000, sig, 4);
	 * 	6		if (kpp) printf ("kpp is at: %slld (0x%x)\n", kpp -buffer, kpp-buffer);
	 * 	7	}
	 * 
	 */

	/* Allocate some space for the decompressed buffer */
	char *decomp = malloc (ntohl (compHeader->uncompressedSize));

	/* Look for 0xfeedfacf */
	int sig = 0xfeedfacf;
	char *feed = memmem (img->buf + 64, 1024, &sig, 3);

	/* Check if there was a memmem result */
	if (!feed) {
		printf ("[*] Error: Could not find Kernel 0xfeedfacf, Mach-O possibly 32bit?\n");

		sig = 0xfeedface;
		feed = memmem (img->buf + 64, 1024, &sig, 3);

		if (!feed) {
			printf ("[*] Error: Could not find Kernel 0xfeedface (32bit)\n");
			exit (0);
		}

	} else {
		printf ("[*] Found Kernel 0xfeedfacf: %ld\n", feed -img->buf);
	}

	/* Try to decompress */
	--feed;
	int rc = decompress_lzss ((uint8_t *) decomp, (uint8_t *) feed, ntohl (compHeader->compressedSize));

	/**
	 * 	Check if 'rc' is the same as the uncompressed size in the header.
	 * 	This will tell if the decompression was successful/
	 */
	if (rc != (int) ntohl (compHeader->uncompressedSize)) {
		printf ("[*] Error: Expected %d bytes, but got %d bytes. Exiting\n", ntohl (compHeader->uncompressedSize), rc);
		exit (0);
	}

	/* Re-assign the img's size and buf vals */
	img->size = ntohl(compHeader->uncompressedSize);
	img->buf = decomp;

	/* Return the decompressed image */
	return img;

}


/**
 * 	img4_extract_payload ()
 * 
 * 	Takes a given image4_t and extracts only the payload and returns as a new
 * 	image4_t structure only containing the IM4P payload, no other metadata.
 * 
 * 	Args:
 * 		image4_t *img		-	The Image to extract the payload from.
 * 
 * 	Returns:
 * 		image4_t *			-	The extracted payload.
 */
image4_t *img4_extract_payload (image4_t *image)
{
	// The approach here is to specifically extract the bytes from the payload tag of an
	// Image4 file. The payload tag should be the third, counting from 0. 

	/* Attempt to find the payload tag. Move pointer by 1 byte */
	char *tag = asn1ElementAtIndex (image->buf, 3) + 1;

	/* Remove the payload length tag from the start of the data */
	asn1ElemLen_t len = asn1Len (tag);

	/* Now create a new Image4 structure. */
	image4_t *newimage = malloc (sizeof (image4_t));

	/* The buf member should be the tag + the len in bytes */
	newimage->buf = tag + len.sizeBytes;

	/* The size is the size from the Image4 header, as this is the size of the payload
		rather than the size of the whole file */
	newimage->size = len.dataLen;

	/* Return the new image */
	return newimage;
}

/**
 * 	img4_decrypt_bytes ()
 * 
 * 	Takes a given image4_t and a ivkey pair. The key is split into
 * 	seperate IV and Key that can be handled by CommonCrypto/Openssl.
 * 	
 * 	The given image4_t will then be decrypted, and decompressed
 * 	providing that it can be identified as a supported compression
 * 	type.
 * 
 * 	That decrypted image is then decompressed and passed back to caller.
 * 
 * 	Args:
 * 		image4_t *img 		-	Image to decrypt and decompressed
 * 		char *_key 			-	Full, combined AES IVKEY.
 * 		int dont_decomp		-	Don't decompress decrypted file
 * 
 * 	Returns:
 * 		char *				-	Decrypted, decompressed image4 payload.
 * 
 */
image4_t *img4_decrypt_bytes (image4_t *img, char *_key, int dont_decomp)
{
	/* Split the _key into an IV and KEY */
	char decIV[33];
	memcpy (decIV, &_key[0], 32);
	decIV[32] = '\0';
	//printf ("IV: %s\n", decIV);
	
	char decKey[65];
	memcpy (decKey, &_key[32], 64);
	decKey[64] = '\0';
	//printf ("Key: %s\n", decKey);

	/* Create an uint8_t array for both key and iv of the correct size */
	uint8_t key[32] = { };
	uint8_t iv[16] = { };

	/* Copy the hex data for the IV */
	for (int i = 0; i < (int) sizeof (iv); i++) {
		unsigned int t;
		sscanf (decIV+i*2,"%02x",&t);
		iv[i] = t;
	}
	for (int i = 0; i < (int) sizeof (key); i++) {
		unsigned int t;
		sscanf (decKey+i*2,"%02x",&t);
		key[i] = t;
	}

	/* Obtain the payload from the correct tag */
	char *tag = asn1ElementAtIndex (img->buf, 3) + 1;
	asn1ElemLen_t len = asn1Len (tag);

	/* Load the payload into data */
	char *data = tag + len.sizeBytes;
	char *raw = malloc (len.dataLen);

	/* Calculate a size that is a multiple of the block size */
	size_t tst = 0;
	if (img->size % BLOCK_SIZE) tst = img->size + (BLOCK_SIZE - (img->size % BLOCK_SIZE)) + BLOCK_SIZE;

	/* Use CommonCrypto's decryption function */
	/* TODO: Implement OpenSSL for non-Apple systems */
	CCCryptorStatus dec = CCCrypt (kCCDecrypt, kCCAlgorithmAES, 0, key, sizeof(key), iv, data, len.dataLen, raw, tst, NULL);

	/* Debug: Print the result code for CC */
	if (dec == 0) {
		printf ("[*] File decrypted successfully.\n");
	}


	/**
	 * 	Decompression of the decrypted boot files is a bit odd
	 * 
	 * 	iBoot is compressed with bvx2, iBEC isn't compressed at all, i have
	 * 	not yet tested anything else.
	 * 
	 * 	So, this function should check that the decrypted buffer header
	 * 	contains a compression magic.
	 * 
	 */
	printf ("[*] Detecting compression type...");

	/* Create a new Image to return */
	image4_t *img_ret = malloc (sizeof(image4_t));

	if (!strncmp (raw, "bvx2", 4) && !dont_decomp) {
		printf (" bvx2.\n");

		img_ret = img4_decompress_bvx2_decrypted_buffer (img_ret, raw, len.dataLen);

	} else if (!strncmp (raw, "complzss", 8) && !dont_decomp) {
		printf (" lzss\n");

		img_ret->buf = raw;
		img_ret->size = len.dataLen;

		img_ret = img4_decompress_lzss (img_ret);
	} else {
		printf (" none.\n");
		
		img_ret->buf = raw;
		img_ret->size = len.dataLen;
	}

	return img_ret;
}


/**
 * 	img4_decompress_bvx2_decrypted_buffer ()
 * 
 * 	Takes a given byte stream, and a given size (which should reflect
 * 	that byte stream). `in` will then be decompressed and returned as
 * 	an Image4_t.
 * 
 * 	Args:
 * 		image4_t *img	-	The compressed image.
 * 		char *in		-	A bytestream to be decompressed
 * 		size_t insize 	-	Size of the bytestream.
 * 
 * 	Returns:
 * 		image4_t 		-	Decompressed image.
 */
image4_t *img4_decompress_bvx2_decrypted_buffer (image4_t *img, char *in, size_t insize)
{
	/**
	 * 	I've taken this code from lzfse/lzfse_main.c. It calcs the
	 * 	"correct" size for the decompressed buffer, then calls the
	 * 	lzfse_decode_buffer () function.
	 * 
	 * 	There is a problem that the result of `out` is always different,
	 * 	this can be observed by checking the sha1 of the resulting file
	 * 	or, in lldb, running `fr v` and observing the difference between
	 * 	two seperate runs on the same file.
	 * 
	 * 	However, when loading the resulting file into IDA64, using
	 * 	https://github.com/argp/iBoot64helper, an iBoot file is always
	 * 	recognised, and the file size is the same, so the difference
	 * 	must be a single byte.
	 * 
	 */
	int op = -1;
	size_t out_allocated = 4 * insize;
	size_t out_size = 0;

	printf ("insize %d, 4 * insize %d, out_allocated %d\n", insize, (4 * insize), out_allocated);

	uint8_t *out = (uint8_t *) malloc (out_allocated);

	out_size = lzfse_decode_buffer (out, out_allocated, (uint8_t *) in, insize, NULL);

	printf ("outsize: %d\n", out_size);

	image4_t *img_ret = img;
	img_ret->buf = (char *) out;
	img_ret->size = out_size;

	return img_ret;
}


/**
 * 	img4_extract_im4p ()
 * 
 * 	Loads a given infile, verifies and prints some information, checks its
 * 	compression type, decompresses and writes the new image to the given
 * 	outfile. If the image requires an ivkey, that is passed aswell.
 * 
 * 	Args:
 * 		char *infile		-		Path of input image
 * 		char *outfile 		-		Path of output raw file
 * 		char *ivkey			-		Encryption key
 * 		int   dont_decomp	-		Don't decompress the decrypted file
 * 	
 */
void img4_extract_im4p (char *infile, char *outfile, char *ivkey, int dont_decomp)
{
	/* Load the image */
	image4_t *image = img4_read_image_from_path (infile);

	/* Check that the image was loaded properly */
	if (!image->size || !image->buf) {
		printf ("[Error] There was an issue loading the file\n");
		exit (0);
	}

	/* If the file is an IMG4, we need to extract the im4p */
	if (image->type == IMG4_TYPE_IMG4) {
		printf ("debug: extracting im4p from img4\n");
		image->buf = getIM4PFromIMG4 (image->buf);
	} else {
		if (image->type != IMG4_TYPE_IM4P) {
			printf ("[Error] Image not .img4 or .im4p\n");
			exit (0);
		}
	}

	/* Print some file information */
	printf ("Loaded: \t%s\n", infile);
	printf ("Image4 Type: \t%s\n", img4_string_for_image_type (image->type));
	printf ("Component: \t%s\n\n", img4_get_component_name (image->buf));

	/* Create an image to hold the decompressed one */
	image4_t *newimage = malloc (sizeof (image4_t));

	/* Start decompression process */
	printf ("[*] Detecting compression type..."); 

	/* Get compression type */
	Image4CompressionType comp = img4_check_compression_type (image->buf);
	if (comp == IMG4_COMP_BVX2) {

		/* Complete the first log */
		printf (" bvx2\n");

		/* Decompress the payload, or leave it if -no-decomp is set */
		if (!dont_decomp) {
			printf ("[*] Decompressing im4p...");

			newimage = img4_decompress_bvx2 (image);

			/* Check if that was successful */
			if (!newimage->buf) {
				printf (" error. There was a problem decompressing the im4p\n");
				exit (0);
			}

			/* Print success */
			printf (" done!\n");
		} else {
			printf ("[*] No Decompression (-no-decomp) set. Will not decompress.\n");
			newimage = img4_extract_payload (image);
		}

	} else if (comp == IMG4_COMP_ENCRYPTED) {

		/* Complete the first log */
		printf (" encrypted\n");

		/* Ensure an ivkey was set */
		if (!ivkey) {
			printf ("[*] Error: No decryption key was specified.\n");
			exit (0);
		}

		/* Decrypt the payload */
		printf ("[*] Attempting to decrypting with ivkey: %s\n", ivkey);
		newimage = img4_decrypt_bytes (image, ivkey, dont_decomp);

	} else if (comp == IMG4_COMP_LZSS) {

		/* Complete the first log */
		printf (" lzss\n");

		if (dont_decomp) {
			printf ("[*] No Decompression (-no-decomp) set. Will not decompress.\n");

			newimage = img4_extract_payload (image);
			
		} else {
			/* Create the new image with the decompressed payload */
			newimage = img4_decompress_lzss (image);
		}

	} else {

		printf ("\n[*] Cannot handle compression type. Exiting...\n");
		exit (0);

	}

	/* Print that we are now writing to the file */
	printf ("[*] Writing decompressed payload to file: %s (%zu bytes)\n", outfile, newimage->size);

	/* Write the buffer to the outfile */
	FILE *o = fopen (outfile, "wb");
	fwrite (newimage->buf, newimage->size, 1, o);
	fclose (o);

	//printf ("\nPlease run img4helper with --analyse to analyse the decompressed image.\n");

}


//////////////////////////////////////////////////////////////////
/*				    Image Printing Funcs						*/
//////////////////////////////////////////////////////////////////


/**
 * 	img4_print_with_type ()
 * 
 * 	Loads and prints a given Image4 at the filename location. The part of the
 * 	file that is printed (--print-all, --print-im4p, etc...) is determined by
 * 	print_type, this should not be confused with image->type, which although
 * 	the same type, image->type describes what Image4 variant the image is, and
 * 	print_type describes what portion of an image to print.
 * 
 * 	Args:
 * 		Image4Type print_type		-	The part of the Image4 to print
 * 		char *filename				-	The filename of the Image4 to be loaded.
 * 
 */	
void img4_print_with_type (Image4Type print_type, char *filename)
{
	/* Check the given filename is not NULL */
	if (!filename) {
		printf ("[Error] No filename given\n");
		exit(0);
	}

	/* Create an image4_t for the filename */
	image4_t *image = img4_read_image_from_path (filename);
	char *magic = img4_string_for_image_type (image->type);

	/* Print some info contained in the file header */
	printf ("Loaded: \t%s\n", filename);
	printf ("Image4 Type: \t%s\n", magic);

	/* Switch through different print options */
	switch (print_type) {
		case IMG4_TYPE_ALL:

			/* Check what type of image we are dealing with */
			if (!strcmp (magic, "IMG4")) {

				/* A full Image4 has an IM4P, IM4M and IM4R */
				char *im4p = getIM4PFromIMG4 (image->buf);
				char *im4m = getIM4MFromIMG4 (image->buf);
				char *im4r = getIM4RFromIMG4 (image->buf);

				/* Print the component name so it is inline with the loaded and type */
				printf ("Component:  \t%s\n\n", img4_get_component_name (im4p));

				/* Print the IMG4 banner */
				printf ("IMG4: ------\n");

				/* Handle the im4p first */
				img4_handle_im4p (im4p, 1);

				/* Make some space between the two */
				printf ("\n");

				/* Handle the im4m next */
				img4_handle_im4m (im4m, 1);

				/* More space */
				printf ("\n");

				/* Finally, the im4r */
				img4_handle_im4r (im4r, 1);
				

			} else if (!strcmp (magic, "IM4P")) {

				/* Print the component type */
				printf ("Component: \t%s\n\n", img4_get_component_name (image->buf));

				/* Handle the im4p */
				img4_handle_im4p (image->buf, 1);

			} else if (!strcmp (magic, "IM4M")) {

				/* Handle the im4m */
				printf ("\n");
				img4_handle_im4m (image->buf, 1);

			} else if (!strcmp (magic, "IM4R")) {

				/* Handle the im4r */
				printf ("\n");
				img4_handle_im4r (image->buf, 1);

			} else {

				/* Error */
				printf ("[Error] Could not find an IMG4, IM4P, IM4M or IM4R\n");

			}

			break;

		default:
			break;

	}

}




char *im4p_extract_silent (char *fn)
{
	/* Check the given filename is not NULL */
	if (!fn) {
		printf ("[Error] No filename given\n");
		exit(0);
	}

	/* Create an image4_t for the filename */
	image4_t *image = img4_read_image_from_path (fn);
	char *magic = img4_string_for_image_type (image->type);

	/* Print some info contained in the file header */
	printf ("Loaded: \t%s\n", fn);
	printf ("Image4 Type: \t%s\n", magic);

	/* Extract data elements */
	char *tag = asn1ElementAtIndex (image->buf, 3) + 1;
	asn1ElemLen_t len = asn1Len (tag);
	char *data = tag + len.sizeBytes;

	/* Write to a temporary file */
	char *ret_name = "im4p.raw.tmp";

	FILE *o = fopen (ret_name, "wb");
	fwrite (data, len.dataLen, 1, o);
	fclose (o);

	return ret_name;
}
