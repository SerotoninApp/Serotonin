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

#include "libhelper/libhelper.h"
#include "version.h"
#include "hlib.h"

static inline size_t
nearest_power (size_t base, size_t num)
{
    if (num > MY_MAXSIZE / 2) {
      return MY_MAXSIZE;
    } else {
      size_t n = base;
      while (n < num) {
          n <<= 1;
      }
      return n;
    }
}

static void
h_string_maybe_expand (HString *string, size_t len)
{
    if (string->len + len >= string->allocated) {
        string->allocated = nearest_power (1, string->len + len + 1);
        string->str = realloc (string->str, string->allocated);
    }
}

HString *h_string_new (const char *init)
{
    HString *string;

    if (init == NULL || *init == '\0') {
        string = h_string_sized_new (2);
    } else {
        size_t len = strlen (init);
        string = h_string_sized_new (len + 2);

        h_string_append_len (string, init, len);
    }

    return string;
}

HString *h_string_insert_len (HString *string, size_t pos, const char *val, size_t len)
{
    size_t len_unsigned, pos_unsigned;

    h_return_val_if_fail (string != NULL, NULL);
    h_return_val_if_fail (len == 0 || val != NULL, string);

    if (len == 0) return string;

    if (len < 0) {
        len = strlen (val);
    }

    len_unsigned = len;

    if (pos < 0) {
        pos_unsigned = string->len;
    } else {
        pos_unsigned = string->len;
        h_return_val_if_fail (pos_unsigned <= string->len, string);
    }

    /* Check whether val represents a substring of string.
    * This test probably violates chapter and verse of the C standards,
    * since ">=" and "<=" are only valid when val really is a substring.
    * In practice, it will work on modern archs.
    */
   if (H_UNLIKELY (val >= string->str && val <= string->str + string->len)) {
       
        size_t offset = val - string->str;
        size_t precount = 0;

        h_string_maybe_expand (string, len_unsigned);
        val = string->str + offset;
        /* At this point, val is valid again */

        /* Open up space where we are going to insert */
        if (pos_unsigned < string->len) {
            memmove (string->str + pos_unsigned + len_unsigned,
                            string->str + pos_unsigned, string->len - pos_unsigned);
        }
        
        /* Move the source part before the gap, if any */
        if (offset < pos_unsigned) {
            precount = MIN (len_unsigned, pos_unsigned - offset);
            memcpy (string->str + pos_unsigned, val, precount);
        }

        /* Move the source part after teh gap, if any */
        if (len_unsigned > precount) {
            memcpy (string->str + pos_unsigned + precount,
                    val + /* Already moved */ precount +
                        /* Spaced opened up */ len_unsigned,
                        len_unsigned - precount);
        }
   } else {

       h_string_maybe_expand (string, len_unsigned);

       /* If we aren't appending at the end, move a hunk
        * of the old stirng to the end, opening up space
        */
       if (pos_unsigned < string->len) {
           memmove (string->str + pos_unsigned +len_unsigned,
                    string->str + pos_unsigned, string->len - pos_unsigned);
       }

       /* insert the new string */
       if (len_unsigned == 1) {
           string->str[pos_unsigned] = *val;
       } else {
           memcpy (string->str + pos_unsigned, val, len_unsigned);
       }
   }

   string->len += len_unsigned;
   string->str[string->len] = 0;

   return string;
}

HString *h_string_append_len (HString *string, const char *val, size_t len)
{
    return h_string_insert_len (string, -1, val, len);
}

HString *h_string_sized_new (size_t size)
{
    HString *string = h_slice_alloc0 (sizeof(HString));

    string->allocated = 0;
    string->len = 0;
    string->str = NULL;
    
    h_string_maybe_expand (string, MAX(size, 2));
    string->str[0] = 0;
    
    return string;
}

HString *h_string_insert_c (HString *string, size_t pos, char c)
{
    size_t pos_unsigned;

    h_return_val_if_fail (string != NULL, NULL);

    h_string_maybe_expand (string, 1);

    if (pos <= -1) {
        pos = string->len;
    } else {
        h_return_val_if_fail ((gsize) pos <= string->len, string);
    }
    pos_unsigned = pos;

    /* If not just an append, move the old stuff */
    if (pos_unsigned < string->len)
        memmove (string->str + pos_unsigned + 1,
                string->str + pos_unsigned, string->len - pos_unsigned);

    string->str[pos_unsigned] = c;

    string->len += 1;

    string->str[string->len] = 0;

    return string;
}

HString *h_string_append_c (HString *string, char c)
{
    h_return_val_if_fail (string != NULL, NULL);
    return h_string_insert_c (string, -1, c);
}

///////////////////////////////////////////////////////////////////////

StringList *strsplit (const char *s, const char *delim)
{
    StringList *rv = malloc (sizeof (StringList));

    void *data;
    char *_s = (char *) s;
    const char **ptrs;
    unsigned int
        ptrsSize, nbWords = 1,
        sLen = strlen (s),
        delimLen = strlen (delim);

    while (( _s = strstr (_s, delim)))
    {
        _s += delimLen;
        ++nbWords;
    }

    rv->count = nbWords;

    ptrsSize = (nbWords + 1) * sizeof(char*);
    ptrs = data = malloc (ptrsSize + sLen + 1);
    if (data) {
        *ptrs = 
            _s = strcpy (((char *) data) + ptrsSize, s);
        if (nbWords > 1) {
            while ((_s = strstr (_s, delim))) {
                *_s = '\0';
                _s += delimLen;
                *++ptrs = _s;
            }
        }
        *++ptrs = NULL;
    }

    rv->ptrs = data;
    return rv;
}

char *strappend(char *a, char *b) {
    // Get the length of a & b
    size_t a_len = strlen(a), b_len = strlen(b);
    // Create a string for the length of a + b with
    // an extra byte for NULL termination
    char *result = malloc(a_len + b_len + 1);
    // If result is empty, a & b were probably empty
    if (!result)
        // So return NULL
        return NULL;
    // Copy the length of a bytes of a into result
    memcpy(result, a, a_len);
    // Copy the length of b bytes of b into result
    // Starting at length of a bytes into result plus
    // the null termination of b
    memcpy(result + a_len, b, b_len + 1);
    result[a_len + b_len] = '\0';
    // Return the new string
    return result;
}


char *mstrappend(char *toap, ...) {
    
    // Create a va_list, char* and size_t
    va_list arg;                        // va_list arguments
    char *rt;                           // string to return
    size_t count = strlen(toap) / 2;    // amount of parameters given
    size_t len = 0;                     // length of all the parameters together
    char *content[count];               // array to hold each parameter from va_arg()
    
    // Initialise the va list
    va_start(arg, toap);     
            
    // If there are enough args to continue
    if (count > 1) {
        for (size_t i = 0; i < count; i++) {
            // assign va_arg to a temp var
            char *tmp = va_arg(arg, char*);
            /* assign len as the current value + length of current value of tmp
                this is to get the full amount of characters in the final
                appended string */
            len = len + strlen(tmp);
            // set i on content to value of tmp
            content[i] = tmp;
        }
    
        // allocated enough bytes in rt for all contents values + a null byte
        rt = malloc(len + 1);
        for (size_t i = 0; i < count; i++) {
            // append content at i to rt
            rt = strappend(rt, content[i]);
        }
    
    } else {
        // Not enough args to continue, present error
        errorf("Not enough args given");
        // Return with NULL to prevent continuation and SEGFAULT
        return NULL;
    }
    
    // append a Null byte to the end of rt
    rt = strappend(rt, "\0");
    
    // Stop the va_list
    va_end(arg);
            
    // Return the newly appended string
    return rt;
        
}

int __printf(log_type msg_type, char *fmt, ...) {
    // Create arg and done vars
    va_list arg;
    int done;

    // Append what is needed depending on msg_type
    if (msg_type == LOG_ERROR) {
        fmt = mstrappend("%s%s%s", ANSI_COLOR_RED "[Error] ", fmt, ANSI_COLOR_RED ANSI_COLOR_RESET);
    } else if (msg_type == LOG_WARNING) {
        fmt = mstrappend("%s%s%s", ANSI_COLOR_YELLOW "[Warning] ", fmt, ANSI_COLOR_YELLOW ANSI_COLOR_RESET);        
    } else if (msg_type == LOG_DEBUG) {
#if LIBHELPER_DEBUG
        fmt = mstrappend("%s%s%s", ANSI_COLOR_CYAN "DEBUG: ", fmt, ANSI_COLOR_CYAN ANSI_COLOR_RESET);  
#else
        return 1;
#endif      
    }

    // Initialize a variable argument list with arg & fmt
    va_start(arg, fmt);
        
    // assign the value of vfpritnf to done
    done = vfprintf(stdout, fmt, arg);
        
    // End the variable argument list with arg
    va_end(arg);
        
    // Return value of done
    return done;
}

unsigned char *
bh_memmem (const unsigned char *haystack, size_t hlen,
           const unsigned char *needle,   size_t nlen)
{
    size_t last, scan = 0;
    size_t bad_char_skip[__UCHAR_MAX + 1]; /* Officially called:
                                          * bad character shift */

    /* Sanity checks on the parameters */
    if (nlen <= 0 || !haystack || !needle)
        return NULL;

    /* ---- Preprocess ---- */
    /* Initialize the table to default value */
    /* When a character is encountered that does not occur
     * in the needle, we can safely skip ahead for the whole
     * length of the needle.
     */
    for (scan = 0; scan <= __UCHAR_MAX; scan = scan + 1)
        bad_char_skip[scan] = nlen;

    /* C arrays have the first byte at [0], therefore:
     * [nlen - 1] is the last byte of the array. */
    last = nlen - 1;

    /* Then populate it with the analysis of the needle */
    for (scan = 0; scan < last; scan = scan + 1)
        bad_char_skip[needle[scan]] = last - scan;

    /* ---- Do the matching ---- */

    /* Search the haystack, while the needle can still be within it. */
    while (hlen >= nlen)
    {
        /* scan from the end of the needle */
        for (scan = last; haystack[scan] == needle[scan]; scan = scan - 1)
            if (scan == 0) /* If the first byte matches, we've found it. */
                return (void *)haystack;

        /* otherwise, we need to skip some bytes and start again.
           Note that here we are getting the skip value based on the last byte
           of needle, no matter where we didn't match. So if needle is: "abcd"
           then we are skipping based on 'd' and that value will be 4, and
           for "abcdd" we again skip on 'd' but the value will be only 1.
           The alternative of pretending that the mismatched character was
           the last character is slower in the normal case (E.g. finding
           "abcd" in "...azcd..." gives 4 by using 'd' but only
           4-2==2 using 'z'. */
        hlen     -= bad_char_skip[haystack[last]];
        haystack += bad_char_skip[haystack[last]];
    }

    return NULL; 
}