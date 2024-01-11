//===------------------------------ asn1.c --------------------------------===//
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

#include "asn1.h"


/////////////////////////////////////////////////
/*				 ASN1 Parser    			   */
/////////////////////////////////////////////////


///**
// * 
// * 
// */
//asn1ElemLen_t asn1Len (const char *buf)
//{
//	asn1Length_t *tmp = (asn1Length_t *)buf;
//	size_t outsize = 0;
//	int bytes = 0;
//
//	unsigned char *sbuf = (unsigned char *)buf;
//
//	if (!tmp->isLong) {
//		outsize = tmp->len;
//	} else {
//		bytes = tmp->len;
//		for (int i = 0; i < bytes; i++) {
//			outsize *= 0x100;
//			outsize += sbuf[1+i];
//		}
//	}
//
//	asn1ElemLen_t ret;
//	ret.dataLen = outsize;
//	ret.sizeBytes = bytes + 1;
//
//	return ret;
//}


///**
// * 
// * 
// */
//uint64_t asn1GetNumberFromTag(asn1Tag_t *tag)
//{
//    if (tag->tagNumber != kASN1TagINTEGER) {
//        printf ("[Error] Not an integer\n");
//        exit(1);
//    }
//
//    uint64_t ret = 0;
//    asn1ElemLen_t len = asn1Len((char *) ++tag);
//    
//    unsigned char *data = (unsigned char *) tag + len.sizeBytes;
//    
//    while (len.dataLen--) {
//        ret *= 0x100;
//        ret+= *data++;
//    }
//    
//    return ret;
//}


///**
// * 
// */
//size_t asn1GetPrivateTagnum (asn1Tag_t *tag, size_t *sizebytes)
//{
//	if (*(unsigned char *) tag != 0xff) {
//		printf ("[Error] Not a private TAG 0x%02x\n", *(unsigned int *) tag);
//		exit(1);
//	}
//
//	size_t sb = 1;
//	asn1ElemLen_t taglen = asn1Len((char *)++tag);
//	taglen.sizeBytes -= 1;
//
//	if (taglen.sizeBytes != 4) {
//		/* 
//         WARNING: seems like apple's private tag is always 4 bytes long
//         i first assumed 0x84 can be parsed as long size with 4 bytes, 
//         but 0x86 also seems to be 4 bytes size even if one would assume it means 6 bytes size.
//         This opens the question what the 4 or 6 nibble means.
//        */
//		taglen.sizeBytes = 4;
//	}
//
//	size_t tagname = 0;
//	do {
//		tagname *= 0x100;
//		tagname >>= 1;
//		tagname += ((asn1PrivateTag_t *)tag)->num;
//		sb++;
//	} while (((asn1PrivateTag_t *) tag++)->more);
//
//	if (sizebytes) *sizebytes = sb;
//	return tagname;
//}


///**
// * 
// */
//char *asn1GetString (char *buf, char **outstring, size_t *strlen)
//{
//	asn1Tag_t *tag = (asn1Tag_t *)buf;
//
//	if (!(tag->tagNumber | kASN1TagIA5String)) {
//		printf("[Error] not a string\n");
//		return 0;
//	}
//
//	asn1ElemLen_t len = asn1Len(++buf);
//	*strlen = len.dataLen;
//	buf += len.sizeBytes;
//	if (outstring) *outstring = buf;
//
//	return buf +* strlen;
//}


///**
// * 
// */
//int asn1ElementAtIndexWithCounter(const char *buf, int index, asn1Tag_t **tagret)
//{
//    int ret = 0;
//    
//    if (!((asn1Tag_t *)buf)->isConstructed) {
//		return 0;
//	}
//    asn1ElemLen_t len = asn1Len(++buf);
//    
//    buf += len.sizeBytes;
//    
//	/* TODO: add lenght and range checks */
//    while (len.dataLen) {
//        if (ret == index && tagret){
//            *tagret = (asn1Tag_t *) buf;
//            return ret;
//        }
//        
//        if (*buf == kASN1TagPrivate) {
//            
//			size_t sb;
//            asn1GetPrivateTagnum((asn1Tag_t *) buf, &sb);
//            
//			buf += sb;
//            len.dataLen -= sb;
//
//        } else if (*buf == (char)0x9F){
//            
//			//buf is element in set and it's value is encoded in the next byte
//            asn1ElemLen_t l = asn1Len(++buf);
//            if (l.sizeBytes > 1) l.dataLen += 0x80;
//            buf += l.sizeBytes;
//            len.dataLen -= 1 + l.sizeBytes;
//        
//		} else
//            buf++,len.dataLen--;
//        
//        asn1ElemLen_t sublen = asn1Len(buf);
//        size_t toadd = sublen.dataLen + sublen.sizeBytes;
//        len.dataLen -= toadd;
//        buf += toadd;
//        ret ++;
//    }
//    
//    return ret;
//}


///**
// * 
// */
//char* asn1ElementAtIndex (const char *buf, int index)
//{
//	asn1Tag_t *ret;
//	asn1ElementAtIndexWithCounter(buf, index, &ret);
//	return (char*) ret;
//}


///**
// * 
// */
//int asn1ElementsInObject (const char *buf)
//{
//	return asn1ElementAtIndexWithCounter (buf, -1, NULL);
//}


/////////////////////////////////////////////////
/*				 ASN1 Printer     			   */
/////////////////////////////////////////////////


/**
 *  asn1PrintKeyValue
 *  Desc:   Print a given IA5String value with the set padding
 * 
 *  Args:
 *      str:        The ASN1 value to print
 *      padding:    The space to leave before the value is printed.
 * 
 */
void asn1PrintIA5String (asn1Tag_t *str, char *padding)
{
    // Check that the given tag is a IA5String
    if (str->tagNumber != kASN1TagIA5String) {
        printf ("%s[Error] Value not an IA5String\n", padding);
        exit(1);
    }

    // Get the length of the string and print
    asn1ElemLen_t len = asn1Len ((char *) ++str);
    printf ("%s%.*s", padding, (int) len.dataLen, ((char *) str) + len.sizeBytes);
}


/**
 *  asn1PrintOctet
 *  Desc:   Print a given Octet value with the set padding
 * 
 *  Args:
 *      str:        The ASN1 Octet to print
 *      padding:    The space to leave before the value is printed.
 * 
 */
void asn1PrintOctet (asn1Tag_t *str, char *padding)
{
    // Check the tag is actually an OCTET value
    if (str->tagNumber != kASN1TagOCTET) {
        printf ("%s[Error] Not an OCTET string\n", padding);
        exit(1);
    }

    // Tihmstar magic
    printf ("%s", padding);
    asn1ElemLen_t len = asn1Len ((char *) str + 1);
    unsigned char *string = (unsigned char *) str + len.sizeBytes +1;
    while (len.dataLen--) printf ("%02x", *string++);
}


/**
 *  asn1PrintOctet
 *  Desc:   Print a given Octet value with the set padding
 * 
 *  Args:
 *      str:        The ASN1 Octet to print
 *      padding:    The space to leave before the value is printed.
 * 
 */
void asn1PrintNumber (asn1Tag_t *str, char *padding)
{
    // Check if the tag is a number
    if (str->tagNumber != kASN1TagINTEGER) {
        printf ("%s[Error] Tag is not an Integer\n", padding);
        return;
    }

    // Tihmstar magic
    asn1ElemLen_t len = asn1Len ((char *) ++str);
    uint32_t num = 0;
    while (len.sizeBytes--) {
        num *= 0x100;
        num += *(unsigned char*) ++str;
    }
    printf ("%s%u", padding, num);
}


/**
 *  asn1PrintPrivtag
 *  Desc:   Print a given Private Tag value with the set padding
 * 
 *  Args:
 *      str:        The Private Tag to print
 *      padding:    The space to leave before the value is printed.
 * 
 */
void asn1PrintPrivtag (size_t privTag, char *padding)
{
    char *ptag = (char *) &privTag;
    int len = 0;
    while (*ptag) ptag++, len++;

    printf ("%s", padding);
    while (len--) putchar(*--ptag);
}


/**
 *  asn1PrintValue
 *  Desc:   Print a given ASN1 Tag value
 * 
 *  Args:
 *      tag:        The tag to print
 *      padding:    The space to leave before the value is printed
 * 
 */
void asn1PrintValue (asn1Tag_t *tag, char *padding)
{
    // Determine if the tag is either HEX, IA5String, Integer or Boolean
    if (tag->tagNumber == kASN1TagIA5String) {
        asn1PrintIA5String (tag, padding);
    } else if (tag->tagNumber == kASN1TagOCTET) {
        asn1PrintOctet (tag, padding);
    } else if (tag->tagNumber == kASN1TagINTEGER) {

        // Not entirely sure how this works. 
        asn1ElemLen_t len = asn1Len ((char *) tag + 1);
        unsigned char *num = (unsigned char *) tag + 1 + len.sizeBytes;
        uint64_t pnum = 0;

        while (len.dataLen--) {
            pnum *= 0x100;
            pnum += *num++;
        }

        if (sizeof (uint64_t) == 8) {
            printf ("%llu", pnum);
        } else {
            printf (" (hex)");
        }

    } else if (tag->tagNumber == kASN1TagBOOLEAN) {
        printf ("%s", (*(char *) tag + 2 == 0) ? "false" : "true");
    } else {
        printf ("%s[Error] Can't print tag of unknown type %02x\n", padding, *(unsigned char *) tag);
    }
}


/**
 *  asn1PrintKeyValue
 *  Desc:   Print the value of the given buffer with the set padding
 * 
 *  Args:
 *      buf:        The ASN1 value to print
 *      padding:    The space to leave before the value is printed.
 * 
 */
void asn1PrintKeyValue (char *buf, char *padding)
{

    /**
     *  See if the buf is a sequence or set.
     */
    if (((asn1Tag_t *) buf)->tagNumber == kASN1TagSEQUENCE) {

        // Check the amount of elements in the buffer is as it should be
        int i;
        if ((i = asn1ElementsInObject(buf)) != 2) {
            printf ("%s[Error] Expecting two elements, found %d\n", padding, i);
            exit(1);
        }

        // Print the IA5String
        asn1PrintIA5String ((asn1Tag_t *) asn1ElementAtIndex (buf, 0), padding);
        printf (": ");

        // This should now print the value of the key.
        asn1PrintKeyValue (asn1ElementAtIndex(buf, 1), padding);
        printf ("\n");

        return;

    } else if (((asn1Tag_t *) buf)->tagNumber != kASN1TagSET) {

        // Just print the value of the buffer
        asn1PrintValue ((asn1Tag_t *) buf, padding);
        return;

    }


    // If we got here, the buffer/tag is not a Sequence so must be a Set.
    printf ("------------------------------\n");

    // Go through any tags in the set.
    for (int i = 0; i < asn1ElementsInObject(buf); i++) {

        // Fetch the element for i in the buffer
        char *elem = (char *) asn1ElementAtIndex (buf, i);
        size_t sb;
        
        // Print the tag name
        asn1PrintPrivtag (asn1GetPrivateTagnum ((asn1Tag_t *) elem, &sb), padding);
        printf (": ");

        // Calculate where the value is
        elem += sb;
        elem += asn1Len(elem + 1).sizeBytes;

        // Print it
        asn1PrintKeyValue (elem, padding);
    }

}


/////////////////////////////////////////////////
/*				 IMG4 Parser     			   */
/////////////////////////////////////////////////


///**
// * 
// */
//int getSequenceName (const char *buf, char **name, size_t *namelen)
//{
//	int err = 0;
//
//	if (((asn1Tag_t *) buf)->tagNumber != kASN1TagSEQUENCE) {
//		printf("not a sequence\n");
//		return err;
//	}
//
//	int elems = asn1ElementsInObject(buf);
//	if (!elems) {
//		printf("no elements in sequence\n");
//		return err;
//	}
//
//	size_t len;
//	asn1GetString(asn1ElementAtIndex(buf, 0), name, &len);
//	if (namelen) *namelen = len;
//
//	return err;
//}


/**
 * 
 */
char *getImageFileType (char *buf)
{
    char *magic;
	size_t l;

	//
	getSequenceName(buf, &magic, &l);
	if (!strncmp("IMG4", magic, l)) {
		return "IMG4";
	} else if (!strncmp("IM4M", magic, l)) {
		return "IM4M";
	} else if (!strncmp("IM4P", magic, l)) {
		return "IM4P";
	} else if (!strncmp("IM4R", magic, l)) {
		return "IM4R";
	} else {
		printf ("[Error] Unexpected tag, got \"%s\"\n", magic);
		exit(1);
	}
}


/**
 * 
 */
char *getIM4PFromIMG4 (char *buf)
{
	char *magic;
	size_t l;

	getSequenceName (buf, &magic, &l);

	if (strncmp("IMG4", magic, l)) {
		printf ("[Error] Expected \"IMG4\", got \"%s\"\n", magic);
		exit(1);
	}

	if (asn1ElementsInObject (buf) < 2) {
		printf ("[Error] Not enough elements in SEQUENCE\n");
		exit(1);
	}

	// The IM4P should be first, so get the element at index 1
	char *ret = (char *) asn1ElementAtIndex(buf, 1);
	getSequenceName (ret, &magic, &l);

	if (strncmp("IM4P", magic, 4) == 0) {
		return ret;
	} else {
		printf ("[Error] Expected \"IM4P\", got \"%s\"\n", magic);
		exit(1);
	}

}


/**
 * 
 */
char *getIM4MFromIMG4 (char *buf)
{
	char *magic;
	size_t l;

	getSequenceName (buf, &magic, &l);

	if (strncmp("IMG4", magic, l)) {
		printf ("[Error] Expected \"IMG4\", got \"%s\"\n", magic);
		exit(1);
	}

	if (asn1ElementsInObject (buf) < 3) {
		printf ("[Error] Not enough elements in SEQUENCE\n");
		exit(1);
	}

	char *ret = (char*) asn1ElementAtIndex (buf, 2);
    if (((asn1Tag_t *) ret)->tagClass != kASN1TagClassContextSpecific) {
		printf ("[Error] unexpected Tag 0x%02x, expected SET\n", *(unsigned char*) ret);
		exit(1);
	}

	ret += asn1Len (ret + 1).sizeBytes +1;
	getSequenceName (ret, &magic, &l);

	if (strncmp("IM4M", magic, 4) == 0) {
		return ret;
	} else {
		printf ("[Error] Expected \"IM4P\", got \"%s\"\n", magic);
		exit(1);
	}
}


/**
 * 
 */
char *getIM4RFromIMG4 (char *buf)
{
	char *magic;
	size_t l;

	getSequenceName (buf, &magic, &l);

	if (strncmp("IMG4", magic, l)) {
		printf ("[Error] Expected \"IMG4\", got \"%s\"\n", magic);
		exit(1);
	}

	if (asn1ElementsInObject (buf) < 4) {
		printf ("[Error] Not enough elements in SEQUENCE\n");
		exit(1);
	}

	char *ret = (char*) asn1ElementAtIndex (buf, 3);
    if (((asn1Tag_t *) ret)->tagClass != kASN1TagClassContextSpecific) {
		printf ("[Error] unexpected Tag 0x%02x, expected SET\n", *(unsigned char*) ret);
		exit(1);
	}

	ret += asn1Len (ret + 1).sizeBytes + 1;
	getSequenceName (ret, &magic, &l);

	if (strncmp("IM4R", magic, 4) == 0) {
		return ret;
	} else {
		printf ("[Error] Expected \"IM4R\", got \"%s\"\n", magic);
		exit(1);
	}
}


/////////////////////////////////////////////////
/*				 IMG4 Printer     			   */
/////////////////////////////////////////////////


/**
 * 
 */
void printStringWithKey (char* key, asn1Tag_t *string, char *padding)
{
	char *str = 0;
	size_t len;

	asn1GetString((char *)string, &str, &len);

	if (len > 32) len = len + (32 - len);

	printf("%s%s: ", padding, key);
	printf("%.*s", (int)len, str);
	printf("\n");
}


/**
 * 
 */
void img4PrintKeybag (char *octet, char *padding)
{
	// Ensure the OCTET has a value
	if (octet == NULL) {
		printf ("%sThis IM4P is not encrypted, no KBAG values\n", padding);
		exit(1);
	}
	
	// Check if the octet is a kASN1TagOCTET
	if (((asn1Tag_t *) octet)->tagNumber != kASN1TagOCTET) {
		//printf ("%s[Error] not an OCTET\n", padding);
		printf ("%sThis IM4P is not encrypted, no KBAG values\n", padding);
		exit(1);
	}

	// Get the octet length
	asn1ElemLen_t octetLen = asn1Len(++octet);
	octet += octetLen.sizeBytes;

	// Parse the KBAG Values
	int subseqs = asn1ElementsInObject (octet);
	for (int i = 0; i < subseqs; i++) {

		// Pick the value
		char *s = (char *)asn1ElementAtIndex (octet, i);
		int elems = asn1ElementsInObject(s);

		// Parse it
		if (elems--) {
			asn1Tag_t *num = (asn1Tag_t *) asn1ElementAtIndex (s, 0);
			if (num->tagNumber != kASN1TagINTEGER) {
				printf ("%s[Warning] Skipping unexpected tag\n", padding);
			} else {
				if (i == 0) {
					printf ("%sKBAG Production [1]:\n", padding);
				} else if (i == 1) {
					printf ("%sKBAG Development [2]:\n", padding);
				} else {
					char n = *(char *)(num + 2);
					printf ("%sKBAG Unknown: [%d]:\n", padding, n);
				}
			}
		}

		// Print the KBAG Hex string
		if (elems--) {
			asn1PrintOctet((asn1Tag_t *) asn1ElementAtIndex(s, 1), padding);
			asn1PrintOctet((asn1Tag_t *) asn1ElementAtIndex(s, 2), "");
			putchar('\n');
			putchar('\n');
		}
	}
}


/**
 * 
 */
void img4PrintManifestBody (const char *buf, char *padding)
{
	// Get the buf magic
	char *magic;
	size_t l;
	getSequenceName(buf, &magic, &l);

	// Check that the magic contains MANB
	if (strncmp("MANB", magic, l)) {
		printf ("[Error] Expected \"MANB\", got \"%s\"\n", magic);
		exit(1);
	}

	// Count the number of elements and make sure it is at least 2
	int manbElmCount = asn1ElementsInObject (buf);
	if (manbElmCount < 2) {
		printf ("[Error] Not enough elements in MANB\n");
		exit(1);
	}

	// Fetch all the elements from the manifest body
	char *manbSeq = (char *)asn1ElementAtIndex(buf, 1);
	for (int i = 0; i < asn1ElementsInObject(manbSeq); i++) {

		// Cycle through each, parsing it and printing.
		asn1Tag_t *manbElm = (asn1Tag_t *)asn1ElementAtIndex(manbSeq, i);


		//This prints the property name
		size_t privTag = 0;
		if (*(char *) manbElm == kASN1TagPrivate) {

			size_t sb;
			printf ("%s", padding);
			size_t privTag = asn1GetPrivateTagnum(manbElm, &sb);
			char *ptag = (char *) &privTag;
			int len = 0;
			while (*ptag) ptag++, len++;
			while (len--) putchar(*--ptag);

			printf(": ");
			manbElm += sb;

		} else {
			manbElm++;
		}

		//This prints the property value.
		manbElm += asn1Len ((char *)manbElm).sizeBytes;

		// Bastard function
		asn1PrintKeyValue ((char *)manbElm, padding);
		if (strncmp((char *)&privTag, "PNAM", 4) == 0) {
			break;
		}
	}

}
