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

//
//	PRIVATE API FILE
//

#ifndef LIBHELPER_INTERNAL_HLIB_H
#define LIBHELPER_INTERNAL_HLIB_H

#ifdef cplusplus
extern "C" {
#endif
	
#include "libhelper/libhelper.h"


/**
 *	HString macro's
 */	 
#define H_UNLIKELY(expr) (expr)
#define MY_MAXSIZE  ((size_t) -1)
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))
	
//
//	@TODO: This generates a warning:
//		warning: incompatible poiunter types returning 'char *' from a
//			function with result type 'HString *' (aka 'struct _HString *')
//
/*#define h_return_val_if_fail(expr, val)  \
    if(!(#expr)) {                       \
        debugf ("bugger\n");             \
        return #val;                     \
    }*/
#define h_return_val_if_fail(expr, val)     0
	
/**
 *  Allocates a block of memory and initialises to 0.
 */
void 	*h_slice_alloc0 (size_t size);


#ifdef cplusplus
}
#endif

#endif /* libhelper_internal_hlib_h */