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

#include "../libhelper/libhelper.h"
#include "../libhelper/img4/asn1.h"

/////////////////////////////////////////////////
/*				 ASN1 Parser    			   */
/////////////////////////////////////////////////


/**
 * 
 * 
 */
asn1ElemLen_t asn1Len (const char *buf)
{
	asn1Length_t *tmp = (asn1Length_t *)buf;
	size_t outsize = 0;
	int bytes = 0;

	unsigned char *sbuf = (unsigned char *)buf;

	if (!tmp->isLong) {
		outsize = tmp->len;
	} else {
		bytes = tmp->len;
		for (int i = 0; i < bytes; i++) {
			outsize *= 0x100;
			outsize += sbuf[1+i];
		}
	}

	asn1ElemLen_t ret;
	ret.dataLen = outsize;
	ret.sizeBytes = bytes + 1;

	return ret;
}


/**
 * 
 * 
 */
uint64_t asn1GetNumberFromTag(asn1Tag_t *tag)
{
    if (tag->tagNumber != kASN1TagINTEGER) {
        printf ("[Error] Not an integer\n");
        exit(1);
    }

    uint64_t ret = 0;
    asn1ElemLen_t len = asn1Len((char *) ++tag);
    
    unsigned char *data = (unsigned char *) tag + len.sizeBytes;
    
    while (len.dataLen--) {
        ret *= 0x100;
        ret+= *data++;
    }
    
    return ret;
}


/**
 * 
 */
size_t asn1GetPrivateTagnum (asn1Tag_t *tag, size_t *sizebytes)
{
	if (*(unsigned char *) tag != 0xff) {
		printf ("[Error] Not a private TAG 0x%02x\n", *(unsigned int *) tag);
		exit(1);
	}

	size_t sb = 1;
	asn1ElemLen_t taglen = asn1Len((char *)++tag);
	taglen.sizeBytes -= 1;

	if (taglen.sizeBytes != 4) {
		/* 
         WARNING: seems like apple's private tag is always 4 bytes long
         i first assumed 0x84 can be parsed as long size with 4 bytes, 
         but 0x86 also seems to be 4 bytes size even if one would assume it means 6 bytes size.
         This opens the question what the 4 or 6 nibble means.
        */
		taglen.sizeBytes = 4;
	}

	size_t tagname = 0;
	do {
		tagname *= 0x100;
		tagname >>= 1;
		tagname += ((asn1PrivateTag_t *)tag)->num;
		sb++;
	} while (((asn1PrivateTag_t *) tag++)->more);

	if (sizebytes) *sizebytes = sb;
	return tagname;
}


/**
 * 
 */
char *asn1GetString (char *buf, char **outstring, size_t *strlen)
{
	asn1Tag_t *tag = (asn1Tag_t *)buf;

	if (!(tag->tagNumber | kASN1TagIA5String)) {
		printf("[Error] not a string\n");
		return 0;
	}

	asn1ElemLen_t len = asn1Len(++buf);
	*strlen = len.dataLen;
	buf += len.sizeBytes;
	if (outstring) *outstring = buf;

	return buf +* strlen;
}


/**
 * 
 */
int asn1ElementAtIndexWithCounter(const char *buf, int index, asn1Tag_t **tagret)
{
    int ret = 0;
    
    if (!((asn1Tag_t *)buf)->isConstructed) {
		return 0;
	}
    asn1ElemLen_t len = asn1Len(++buf);
    
    buf += len.sizeBytes;
    
	/* TODO: add lenght and range checks */
    while (len.dataLen) {
        if (ret == index && tagret){
            *tagret = (asn1Tag_t *) buf;
            return ret;
        }
        
        if (*buf == kASN1TagPrivate) {
            
			size_t sb;
            asn1GetPrivateTagnum((asn1Tag_t *) buf, &sb);
            
			buf += sb;
            len.dataLen -= sb;

        } else if (*buf == (char)0x9F){
            
			//buf is element in set and it's value is encoded in the next byte
            asn1ElemLen_t l = asn1Len(++buf);
            if (l.sizeBytes > 1) l.dataLen += 0x80;
            buf += l.sizeBytes;
            len.dataLen -= 1 + l.sizeBytes;
        
		} else
            buf++,len.dataLen--;
        
        asn1ElemLen_t sublen = asn1Len(buf);
        size_t toadd = sublen.dataLen + sublen.sizeBytes;
        len.dataLen -= toadd;
        buf += toadd;
        ret ++;
    }
    
    return ret;
}


/**
 * 
 */
char* asn1ElementAtIndex (const char *buf, int index)
{
	asn1Tag_t *ret;
	asn1ElementAtIndexWithCounter(buf, index, &ret);
	return (char*) ret;
}


/**
 * 
 */
int asn1ElementsInObject (const char *buf)
{
	return asn1ElementAtIndexWithCounter (buf, -1, NULL);
}


/////////////////////////////////////////////////
/*				 IMG4 Parser     			   */
/////////////////////////////////////////////////


int getSequenceName (const char *buf, char **name, size_t *namelen)
{
    int err = 0;

    if (((asn1Tag_t * ) buf )->tagNumber != kASN1TagSEQUENCE) {
        debugf ("asn1.c: get_sequence_name(): not a sequence\n");
        return err;
    }

    int elms = asn1ElementsInObject (buf);
    if (!elms) {
        debugf ("asn1.c: get_sequence_name(): no elements in sequence\n");
        return err;
    }

    size_t len;
    asn1GetString (asn1ElementAtIndex (buf, 0), name, &len);
    if (namelen) *namelen = len;

    return err;
}
