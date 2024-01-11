/**
 *     img4helper
 *     Copyright (C) 2019, @h3adsh0tzz
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

#ifndef DEVTREE_H
#define DEVTREE_H

/* Use once libhelper is properly implemented */

#include <stdlib.h>

#include "asn1.h"


/**
 * 
 */
#define kPropertyNameLength     32


/**
 * 
 */
typedef struct dt_node_prop_t {
    char        name[kPropertyNameLength];
    uint32_t    len;
} dt_node_prop_t;


/**
 * 
 */
typedef struct dt_node_t {
    uint32_t        prop_count;
    uint32_t        child_count;
} dt_node_t;


/**
 * 
 */
void dt_dump (char *path, int print_children);


#endif /* devtree_h */