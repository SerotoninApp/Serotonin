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

#include "devtree.h"

void dt_cpy_val (char *d, char *s, int l)
{
    int i = 0;
    for (i = 0; s[i] || i < l; i++) {
        if (i > (int) strlen (s)) break;
    }
    
    if (i != l) {
        strcpy(d, "(null)");
        return;
    }
    memcpy(d, s, l);
}

uint32_t dt_dump_node (dt_node_t *node, int indent, int print_children)
{
    /* Testing some shit */
    char buffer[102400];
    char temp[10240];
    /* unused */
    //char h_temp[49152];
    char *name;
    
    int prop = 0, child = 0;
    int i = 0;
    memset(buffer, '\0', 4096);

    dt_node_prop_t *dtp = (dt_node_prop_t *) ((char *)node + sizeof(dt_node_t));

    char *offset = 0;
    int real_len;

    for (prop = 0; prop < (int) node->prop_count; prop++) {

        real_len = dtp->len;
        temp[0] = '\0'; //strcat something?

        for (i = 0; i < indent; i++) {
            strcat (temp, "|  ");
        }
        strcat (temp, "+--");
        strncat (buffer, temp, 1024);
        
        if ((real_len & 0x80000000) > 0) {
            real_len = real_len - 0x80000000;
        }

        sprintf(temp, "%s %d bytes: ", dtp->name, real_len);
        strncat (buffer, temp, 1024);

        if (!strcmp(dtp->name, "name")) {
            name = (char *) &dtp->len + sizeof(uint32_t);
            strncat (buffer, name, dtp->len);
            strcat (buffer,"\n");
        } else {
            dt_cpy_val (temp, ((char *) &dtp->len) + sizeof(uint32_t), real_len);

            strcat(buffer, temp);
            strcat(buffer, "\n");
        }
        dtp = (dt_node_prop_t *) (((char *) dtp) + sizeof(dt_node_prop_t) + real_len);
        
        // Align
        dtp =  (((long) dtp %4) ? (dt_node_prop_t *) (((char *) dtp)  + (4 - ((long)dtp) %4)): dtp);
        offset = (char *) dtp;

    }

    for (i = 0; i < indent - 1; i++) {
        printf ("   ");
    }
    if (indent > 1) {
        printf ("+--");
    }

    printf("%s:\n", name);
    printf ("%s", buffer);


    if (print_children) {
        for (child = 0; child < (int) node->child_count; child++) {
            offset += dt_dump_node ((dt_node_t *) offset, indent + 1, print_children);
        }
    }
    
    return ( (char *) offset - (char*) node);
}


void dt_dump (char *path, int print_children)
{
    char *fn = im4p_extract_silent (path);

    FILE *f = fopen (fn, "rb");
    fseek (f, 0, SEEK_END);
    size_t size = ftell (f);
    fseek (f, 0, SEEK_SET);
    
    char *data = malloc (size);
    fread (data, size, 1, f);
    fclose (f);

    int fres = remove (fn);
    if (fres) {
        printf ("[*] Warning: Temporary file 'im4p.raw.tmp' not deleted.\n");
    }


    dt_node_t *dtn = (dt_node_t *) data;
    printf ("Loaded a Device Tree with %d Properties and %d Children\n", dtn->prop_count, dtn->child_count);

    dt_dump_node (dtn, 1, print_children);

}