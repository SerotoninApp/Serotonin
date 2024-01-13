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

#ifndef LIBHELPER_H
#define LIBHELPER_H

#ifdef cplusplus
extern "C" {
#endif


#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <sys/mman.h>


extern char			*libhelper_get_version 		();
extern char 		*libhelper_version_string 	();
extern char			*libhelper_get_version_long ();
extern char 		*libhelper_get_version_with_arch ();

extern int			 libhelper_is_debug			();

/***********************************************************************
* File loading and handling.
*
*	Functions, structs and defines to improve the easability of working
*	with files in C and C++.
*
***********************************************************************/

/**
 *	Libhelper file structure: wrapper for `FILE` with some extra info
 *	regarding the file.
 *
 */
struct __libhelper_file {
	char			*path;		/* loaded file path */
	size_t			 size;		/* loaded file size */
	unsigned char	*data;		/* mmaped() file */
};
typedef struct __libhelper_file		file_t;

// Functions for handling files
extern file_t			*file_create	();
extern file_t			*file_load		(const char *path);
extern void				 file_close		(file_t *file);
extern void				 file_free		(file_t *file);

extern const void *
file_get_data (file_t *f, 
			   uint32_t offset);

extern int
file_write_new (char *filename, 
				unsigned char *buf, 
				size_t size);

extern void
file_read_data (file_t *f, 
				uint32_t offset, 
				void *buf, 
				size_t size);


extern void *
file_dup_data (file_t *f, 
			   uint32_t offset, 
			   size_t size);


/**
 *	Result flags for `file_read()` and `file_write_new()`.
 */
#define		LH_FILE_FAILURE			0x0
#define 	LH_FILE_SUCCESS			0x1


/* End of libhelper-file */

/***********************************************************************
* Logging.
*
*	Wrappers for `printf()` for error's, warning's and debug messages.
*
***********************************************************************/

/**
 * 	Log levels
 */
typedef enum {
	LOG_ERROR,
	LOG_WARNING,
	LOG_DEBUG,
	LOG_PRINT
} log_type;

// colours
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

/**
 *	Re-implementation of printf() for these macro's
 */
extern int				__printf (log_type msg_type, char *fmt, ...);

// macros
#define errorf(fmt, ...)		__printf (LOG_ERROR, fmt, ##__VA_ARGS__);
#define debugf(fmt, ...)  		__printf (LOG_DEBUG, fmt, ##__VA_ARGS__);
#define warningf(fmt, ...)  	__printf (LOG_WARNING, fmt, ##__VA_ARGS__);


/***********************************************************************
* Boyermoore Horspool memmem()
*
*   Boyermoore Horspool, or Horspool's Algorithim, is an algorithm for
*   finding substrings in a buffer.
*
***********************************************************************/

#define __UCHAR_MAX			255

extern unsigned char 		*bh_memmem (const unsigned char *haystack, 	size_t hlen,
										const unsigned char *needle,	size_t nlen);


/***********************************************************************
* HLibc.
*
*	Quick reimplementations of certain Glib functionality so that libhelper
*	can be built without any dependencies.
*
***********************************************************************/

/* HSList (Singly Linked Lists)*/

typedef struct __libhelper_hslist	HSList;
struct __libhelper_hslist {
	void	*data;
	HSList	*next;
};

// HSList functions
extern HSList	*h_slist_last (HSList *list);
extern HSList	*h_slist_append (HSList *list, void *data);
extern HSList	*h_slist_remove (HSList *list, void *data);
extern int		h_slist_length (HSList *list);
extern void		*h_slist_nth_data (HSList *list, int n);


/* HSList end */
///////////////////////////////////////////////////////////////
/* HString start */


/**
 *	HString structure
 */
typedef struct __libhelper_hstring HString;
struct __libhelper_hstring {
	char		*str;
	size_t 	 	len;
	size_t 	 	allocated;
};


/**
 *	String list implementation
 */
typedef struct __libhelper_stringlist StringList;
struct __libhelper_stringlist {
	char	  **ptrs;
	int			count;
};


// HString functions
extern HString	*h_string_new (const char *init);
extern HString 	*h_string_insert_len (HString *string, size_t pos, const char *val, size_t len);
extern HString 	*h_string_append_len (HString *string, const char *val, size_t len);
extern HString 	*h_string_sized_new (size_t size);

extern HString 	*h_string_insert_c (HString *string, size_t pos, char c);
extern HString 	*h_string_append_c (HString *string, char c);

extern StringList	*strsplit (const char *s, const char *delim);

// string append, multiple string append
extern char		*strappend (char *a, char *b);
extern char		*mstrappend (char *fmt, ...);

/* HString end */
///////////////////////////////////////////////////////////////



#ifdef cplusplus
}
#endif

#endif /* libhelper_h */
