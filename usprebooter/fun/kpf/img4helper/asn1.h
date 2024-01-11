//===------------------------------ asn1.h --------------------------------===//
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

/**
 *  About:
 *
 *  This file is a small ASN.1 Parser/Decoder based on that used by Tihmstar
 *  for img4tool.
 *
 */

#ifndef ASN1_H
#define ASN1_H

#include <stdio.h>
//#include <plist/plist.h>

#include "img4.h"

#define putStr(s,l) printf("%.*s",(int)l,s)

typedef unsigned char byte;

// Printing padded text
#define kOutputPadding1				"\t";
#define kOutputPaddingNone			"";

// Tag Class
#define kASN1TagClassUniversal       0
#define kASN1TagClassApplication     1
#define kASN1TagClassContextSpecific 2
#define kASN1TagClassPrivate         3

// Primitive
#define kASN1Primitive				 0
#define	kASN1Constructed			 1

// tagNumber
#define kASN1TagEnd_of_Content  0
#define kASN1TagBOOLEAN         1
#define kASN1TagINTEGER         2
#define kASN1TagBIT             3
#define kASN1TagOCTET           4
#define kASN1TagNULL            5
#define kASN1TagOBJECT          6
#define kASN1TagObject          7
#define kASN1TagEXTERNAL        8
#define kASN1TagREAL            9
#define kASN1TagENUMERATED      10 //0x0A
#define kASN1TagEMBEDDED        11 //0x0B
#define kASN1TagUTF8String      12 //0x0C
#define kASN1TagRELATIVE_OID    13 //0x0D
#define kASN1TagReserved        (14 | 15) //(0x0E | 0x0F)
#define kASN1TagSEQUENCE        16 //0x10
#define kASN1TagSET             17 //0x11
#define kASN1TagNumericString   18 //0x12
#define kASN1TagPrintableString 19 //0x13
#define kASN1TagT61String       20 //0x14
#define kASN1TagVideotexString  21 //0x15
#define kASN1TagIA5String       22 //0x16
#define kASN1TagUTCTime         23 //0x17
#define kASN1TagGeneralizedTime 24 //0x18
#define kASN1TagGraphicString   25 //0x19
#define kASN1TagVisibleString   26 //0x1A
#define kASN1TagGeneralString   27 //0x1B
#define kASN1TagUniversalString 28 //0x1C
#define kASN1TagCHARACTER       29 //0x1D
#define kASN1TagBMPString       30 //0x1E
#define kASN1TagPrivate   (char)0xff

typedef struct {
	byte tagNumber : 5;
	byte isConstructed : 1;
	byte tagClass : 2;
} asn1Tag_t;

typedef struct {
	byte len : 7;
	byte isLong : 1;
} asn1Length_t;

typedef struct {
	size_t dataLen;
	size_t sizeBytes;
} asn1ElemLen_t;

typedef struct {
	byte num : 7;
	byte more : 1;
} asn1PrivateTag_t;


/////////////////////////////////////////////////
/*				 ASN1 Parser    			   */
/////////////////////////////////////////////////

asn1ElemLen_t	asn1Len (const char *buf);
uint64_t 		asn1GetNumberFromTag(asn1Tag_t *tag);
size_t			asn1GetPrivateTagnum (asn1Tag_t *tag, size_t *size_bytes);
char		   *asn1GetString (char *buf, char **outstring, size_t *strlen);
char		   *asn1ElementAtIndex (const char *buf, int index);
int			    asn1ElementsInObject (const char *buf);
int				asn1ElementAtIndexWithCounter(const char *buf, int index, asn1Tag_t **tagret);


/////////////////////////////////////////////////
/*				 ASN1 Printer     			   */
/////////////////////////////////////////////////

void			asn1PrintPrivtag (size_t privTag, char *padding);
void 			asn1PrintKeyValue (char *buf, char *padding);
void			asn1PrintValue (asn1Tag_t *tag, char *padding);
void			asn1PrintIA5String (asn1Tag_t *str, char *padding);
void			asn1PrintOctet (asn1Tag_t *str, char *padding);
void			asn1PrintNumber (asn1Tag_t *str, char *padding);


/////////////////////////////////////////////////
/*				 IMG4 Parser     			   */
/////////////////////////////////////////////////

int				getSequenceName (const char *buf, char **name, size_t *namelen);

char 		    *getImageFileType (char *buf);
char 			*getIM4PFromIMG4 (char *buf);
char 			*getIM4MFromIMG4 (char *buf);
char	 		*getIM4RFromIMG4 (char *buf);


/////////////////////////////////////////////////
/*				 IMG4 Printer     			   */
/////////////////////////////////////////////////

void 			printStringWithKey (char* key, asn1Tag_t *string, char *padding);

void 			img4PrintKeybag (char *octet, char *padding);
void 			img4PrintManifestBody (const char *buf, char *padding);

////////////


void getElementsFromIMG4 (char *buf);

#endif
