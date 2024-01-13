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

void *h_slice_alloc0 (size_t size)
{
    void *mem = malloc (size);
    if (mem) 
        memset (mem, '\0', size);
    return mem;
}


HSList *h_slist_append (HSList *list, void *data)
{
    HSList *new;
    HSList *last;

    new = h_slice_alloc0 (sizeof(HSList));
    new->data = data;
    new->next = NULL;

    if (list) {
        last = h_slist_last (list);
        last->next = new;

        return list;
    }

    return new;
}


HSList *h_slist_last (HSList *list)
{
    if (list) {
        while (list->next) {
            list = list->next;
        }
    }

    return list;
}


int h_slist_length (HSList *list)
{
    int len = 0;
    while (list) {
        len++;
        list = list->next;
    }

    return len;
}


void *h_slist_nth_data (HSList *list, int n)
{
    while (n-- > 0 && list) {
        list = list->next;
    }

    return list ? list->data : NULL;
}

static HSList *_h_slist_remove_data (HSList *list, void *data, int all)
{
    HSList *tmp = NULL;
    HSList **previous_ptr = &list;

    while (*previous_ptr) {
        tmp = *previous_ptr;
        if (tmp->data == data) {
            *previous_ptr = tmp->next;
            free (tmp);
            if (!all) break;
        } else {
            previous_ptr = &tmp->next;
        }
    }
    return list;
}

HSList *h_slist_remove (HSList *list, void *data)
{
    return _h_slist_remove_data (list, data, 0);
}