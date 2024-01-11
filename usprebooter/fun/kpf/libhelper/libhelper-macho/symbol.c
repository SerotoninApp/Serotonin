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

#include "../libhelper/libhelper.h"
#include "../libhelper/libhelper-macho.h"

/**
 * 
 */
mach_symtab_command_t *mach_symtab_command_create ()
{
    mach_symtab_command_t *ret = malloc (sizeof (mach_symtab_command_t ));
    memset (ret, '\0', sizeof (mach_symtab_command_t));
    return ret;
}

/**
 * 
 */
mach_symtab_command_t *mach_symtab_command_load (macho_t *macho, uint32_t offset)
{
    mach_symtab_command_t *sym = mach_symtab_command_create ();
    sym = (mach_symtab_command_t *) macho_load_bytes (macho, sizeof (mach_symtab_command_t), offset);

    if (!sym) {
        errorf ("mach_symtab_command_load(): problem loading mach symbol table at offset: 0x%08x\n", offset);
        return NULL;
    }
    return sym;
}

/**
 * 
 */
char *mach_symtab_find_symbol_name (macho_t *macho, nlist *sym, mach_symtab_command_t *cmd)
{
    // offset of the symbol table name is symbol->off + nlist->n_strx;
    uint32_t size = cmd->strsize - sym->n_strx;
    uint32_t offset = cmd->stroff + sym->n_strx;

    HString *curr = h_string_new ("");
    uint32_t found = 0, i = 0;
    char *tmp = malloc (size);

    memcpy (tmp, macho->data + offset, size);
    while (!found) {
        if (i >= size) break;
        if (tmp[i] != 0x0) {
            curr = h_string_append_c (curr, tmp[i]);
            i++;
        } else {
            if (curr->str && curr->len > 0) {
                found = 1;
                return curr->str;
            }
            break;
        }
    }
    return "(no name)";
}

/**
 * 
 * 
 */
mach_symbol_table_t *mach_symtab_load_symbols (macho_t *macho, mach_symtab_command_t *symbol_table)
{
    /*
    
        sym name: __mh_execute_header
        sym index: 0x2
        sym type: 15
        sym section: 0x1

        000001Eb    String table index:     __mh_execute_header
        0F          Type
                    0E                      N_SECT
                    01                      N_EXT
        01          Section Index           1 (__TEXT,__text)
        0010        Description
                    0010                    REFERENCE_DYNAMICALLY
        0           Value                   (IGNORE)


        TODO:
            - Functions to unpack type, sect, desc and value
            - Function to print the symbol in a formatted way.

        00000000    Symbol Name:    __main
        00000000    Type:
                    0E              N_SECT
                    01              N_EXT
        00000001    Section         1 (__TEXT,__text)
        00000010    Description
                    0010            REFERENCE_DYNAMICALLY

    */


    debugf ("\nsymbol.c:mach_symtab_load_symbols(): Trying to load symbol table:\n\n");

    size_t s = symbol_table->nsyms;
    off_t off = symbol_table->symoff;

    for (size_t i = 0; i < s; i++) {
        nlist *tmp = (nlist *) macho_load_bytes (macho, sizeof(nlist), off);

        char *name = mach_symtab_find_symbol_name (macho, tmp, symbol_table);

        // THIS WILL MOVE TO A SEPERATE FUNCTION
        debugf ("symbol.c:mach_symtab_load_symbols(): 0x%08x \tSymbol Name:\t%s\n", tmp->n_strx, name);
        debugf ("symbol.c:mach_symtab_load_symbols(): 0x%08x \tType:\n", tmp->n_type);


        if ((tmp->n_type & N_STAB) == N_STAB) debugf ("\t\t0x%02x\tN_STAB\n", N_STAB);

        if ((tmp->n_type & N_PEXT) == N_PEXT) debugf ("\t\t0x%02x\tN_PEXT\n", N_PEXT);

        // The N_TYPE can also have differnet types, for example
            // N_UNDF (0x0), N_ABS (0x2), N_SECT (0xe), N_PBUD (0xc)
            // and N_INDR (0xa)
            if ((tmp->n_type & N_UNDF) == N_UNDF) debugf ("\t\t0x%02x\tN_UNDF\n", N_UNDF);

            if ((tmp->n_type & N_ABS) == N_ABS) debugf ("\t\t0x%02x\tN_ABS\n", N_ABS);

            if ((tmp->n_type & N_SECT) == N_SECT) debugf ("\t\t0x%02x\tN_SECT\n", N_SECT);

            if ((tmp->n_type & N_PBUD) == N_PBUD) debugf ("\t\t0x%02x\tN_PBUD\n", N_PBUD);

            if ((tmp->n_type & N_INDR) == N_INDR) debugf ("\t\t0x%02x\tN_INDR\n", N_INDR);

        if ((tmp->n_type & N_EXT) == N_EXT) debugf ("\t\t0x%02x\tN_EXT\n", N_EXT); 


        if (tmp->n_sect) {
            mach_section_64_t *section = mach_find_section_command_at_index (macho->scmds, tmp->n_sect);
            debugf ("symbol.c:mach_symtab_load_symbols(): 0x%08x \tSection:\t%d (%s,%s)\n", tmp->n_sect, tmp->n_sect, section->segname, section->sectname);
        } else {
            debugf ("symbol.c:mach_symtab_load_symbols(): 0x%08x \tSection:\tNO_SECT\n");
        }

        printf ("\n");

        //debugf ("symbol.c:mach_symtab_load_symbols(): sym name: %s\n", name);
        //debugf ("symbol.c:mach_symtab_load_symbols(): sym index: 0x%x\n", tmp->n_strx);
        //debugf ("symbol.c:mach_symtab_load_symbols(): sym type: %d\n", tmp->n_type);
        //debugf ("symbol.c:mach_symtab_load_symbols(): sym section: 0x%x\n\n", tmp->n_sect);
        //debugf ("symbol.c:mach_symtab_load_symbols(): sym desc: %d\n", tmp->n_desc);
        //debugf ("symbol.c:mach_symtab_load_symbols(): sym val: %lu\n", tmp->n_value);

        off += sizeof(nlist);
    }

    return NULL;
}
