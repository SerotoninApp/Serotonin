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

#include "version.h"


//===-----------------------------------------------------------------------===//
/*-- Mach-O                              									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  Load a Mach-O from a given filepath.
 * 
 *  @param          filepath to load from.
 * 
 *  @returns        loaded and parsed `macho_t`.
 */
void *macho_load (const char *filename)
{
    file_t      *file = NULL;
    void        *macho = NULL;

    if (filename) {
        debugf ("macho.c: reading Mach-O from filename: %s\n", filename);

        file = file_load (filename);
        if (!file) {
            free (file);
            return NULL;
        }

        if (file->size <= 0) {
            errorf ("macho_load(): file could not be loaded properly: %d", file->size);
            free (macho);
            return NULL;
        } 

        debugf ("macho.c: macho_load(): creating Mach-O struct\n");
        macho = macho_create_from_buffer ((unsigned char *) file_get_data (file, 0));

        if (macho == NULL) {
            errorf ("macho_load(): error creating macho: macho == NULL\n");
            return NULL;
        }

        debugf ("macho.c: macho_load(): all is well\n");
    } else {
        errorf ("macho_load(): no filename specified\n");
    }
    return macho;
}


/**
 *  Generic load a Mach-O from a given data buffer.
 */
void *macho_create_from_buffer (unsigned char *data)
{
    // check the data is valid
    if (!data) {
        errorf ("macho_create_from_buffer(): invalid data\n");
        return NULL;
    }

    // check if the data is a FAT file
    if (FAT(data)) {
        errorf ("macho_create_from_buffer(): cannot handle fat archive here\n");
        return NULL;
    }

    // try to load the mach header here. Does not matter which one.
    mach_header_t *hdr = (mach_header_t *) data;
    mach_header_type_t type = mach_header_verify (hdr->magic);

    if (type == MH_TYPE_MACHO64) {
        return macho_64_create_from_buffer (data);
    } else if (type == MH_TYPE_MACHO32) {
        return macho_32_create_from_buffer (data);
    } else {
        errorf ("macho_create_from_buffer(): cannot handle mach-o magic: 0x%08x\n", data);
        return NULL;
    }
}


/**
 *  Return the pointer to an offset within a Mach-O
 * 
 */
void *macho_get_bytes (void *macho, uint32_t offset)
{
    macho_t *tmp = (macho_t *) macho;
    return (void *) (tmp->data + offset);
}


/**
 *  Duplicate `size` bytes from a given Mach-O into a given buffer.
 * 
 */
void macho_read_bytes (void *macho, uint32_t offset, void *buffer, size_t size)
{
    macho_t *tmp = (macho_t *) macho;
    memcpy (buffer, macho_get_bytes (tmp->data, offset), size);
}



/**
 *  Load `size` bytes into a malloc()'d buffer and return.
 * 
 */
void *macho_load_bytes (void *macho, size_t size, uint32_t offset)
{
    macho_t *tmp = (macho_t *) macho;

    void *ret = malloc (size);
    memcpy (ret, tmp->data + offset, size);
    return ret;
}

//===-----------------------------------------------------------------------===//
/*-- Mach-O Header functions         									 --*/
//===-----------------------------------------------------------------------===//


/**
 *  Verify a magic number.
 * 
 *  @param         magic number to verify
 * 
 *  @returns       header type
 */
mach_header_type_t mach_header_verify (uint32_t magic)
{
    switch (magic) {
        case MACH_MAGIC_64:
        case MACH_CIGAM_64:
            return MH_TYPE_MACHO64;
        case MACH_MAGIC_32:
        case MACH_CIGAM_32:
            return MH_TYPE_MACHO32;
        case MACH_MAGIC_UNIVERSAL:
        case MACH_CIGAM_UNIVERSAL:
            return MH_TYPE_FAT;
        default:
            break;
    }
    return MH_TYPE_UNKNOWN;
}


/**
 *  Create a `mach_header_t` structure.
 * 
 *  @returns        `mach_header_t` structure
 */
mach_header_t *mach_header_create ()
{
    mach_header_t *ret = malloc (sizeof (mach_header_t));
    memset (ret, '\0', sizeof (mach_header_t));
    return ret;
}


/**
 *  Load a `mach_header_t` from a given `macho_t`
 * 
 *  @param          `macho_t` to load a header from.
 * 
 *  @returns        loaded `mach_header_t`.
 */
mach_header_t *mach_header_load (macho_t *macho)
{
    mach_header_t *hdr = NULL;

    // check the given macho was initialised.
    if (macho) {
        unsigned char *data = macho->data;
        hdr = mach_header_create ();

        // copy bytes from data to hdr
        memcpy (hdr, &data[0], sizeof (mach_header_t));

        // verify the magic value was loaded
        if (!hdr->magic) {
            errorf ("mach_header_load(): No magic value, something went wrong\n");
            return NULL;
        }

        // check the magic
        mach_header_type_t type = mach_header_verify (hdr->magic);

        if (type == MH_TYPE_MACHO64) {
            debugf ("macho.c: mach_header_load(): Detected Mach-O 64 bit\n");
            return hdr;
        } else if (type == MH_TYPE_MACHO32) {
            debugf ("macho.c: mach_header_load(): Detected Mach-O 32 bit\n");
            return hdr;
        } else if (type == MH_TYPE_FAT) {
            debugf ("macho.c: mach_header_load(): Detected Universal Binary. Libhelper cannot load these.\n");
            hdr = NULL;
        } else {
            errorf ("mach_header_load(): Unknown file magic:0x%08x\n", hdr->magic);
            hdr = NULL;
        }
    }
    return hdr;
}


/**
 *  Grab a human-readable cpu type for a given type.
 * 
 *  @param              cputype
 * 
 *  @returns            string representing given type
 */
char *mach_header_read_cpu_type (cpu_type_t type)
{
    debugf ("macho.c: mach_header_read_cpu_type: type: %d\n", type);

    char *cpu_type = "";
    switch (type) {
        case CPU_TYPE_X86:
            cpu_type = "x86";
            break;
        case CPU_TYPE_X86_64:
            cpu_type = "x86_64";
            break;
        case CPU_TYPE_ARM:
            cpu_type = "arm";
            break;
        case CPU_TYPE_ARM64:
            cpu_type = "arm64";
            break;
        case CPU_TYPE_ARM64_32:
            cpu_type = "arm64_32";
            break;
        default:
            cpu_type = "unknown";
            break;
    }
    return cpu_type;
}


/**
 * 
 */
char *mach_header_get_cpu_name (cpu_type_t type, cpu_subtype_t subtype)
{
    switch (type) {
        /* Intel CPUs */
        case CPU_TYPE_X86:
            return "Intel x86";
        case CPU_TYPE_X86_64:
            return "Intel x86_64";
        
        /* ARM CPUs */
        case CPU_TYPE_ARM:
            switch (subtype) {
                case CPU_SUBTYPE_ARM_V7:
                    return "ARM armv7";         /* ARMv7-A and ARMv7-R */
                case CPU_SUBTYPE_ARM_V7F:
                    return "ARM armv7F";        /* Cortex A9 */
                case CPU_SUBTYPE_ARM_V7S:
                    return "ARM armv7S";        /* Swift */
                case CPU_SUBTYPE_ARM_ALL:
                default:
                    return "ARM arm32";           /* Any other arm32 types */
            }
        case CPU_TYPE_ARM64:
            switch (subtype) {
                case CPU_SUBTYPE_ARM64_V8:
                    return "ARM arm64_v8";      /* arm64-v8 */      
                case CPU_SUBTYPE_ARM64E:
                    return "ARM arm64e";
                case CPU_SUBTYPE_ARM64E | CPU_SUBTYPE_ARM64_PTR_AUTH_MASK:
                    return "ARM arm64e (PtrAuth)";
                case CPU_SUBTYPE_ARM64E | CPU_SUBTYPE_ARM64E_MTE_MASK:
                    return "ARM arm64e (MTE)";
                case CPU_SUBTYPE_ARM64_ALL:
                default:
                    return "ARM arm64e";
            }
        case CPU_TYPE_ARM64_32:
            return "ARM arm64_32";

        /* default */
        case CPU_TYPE_ANY:
        default:
            return "Unknown CPU";
    }
}


/**
 *  Grab a human-readable cpu subtype for a given subtype
 * 
 *  @param              cputype
 *  @param              cpusubtype
 * 
 *  @returns            string representing given subtype
 */
char *mach_header_read_cpu_subtype (cpu_type_t type, cpu_subtype_t subtype)
{
    char *cpu_subtype = "";
    if (type == CPU_TYPE_X86_64) {
        return "x86_64";
    } else if (type == CPU_TYPE_X86) {
        return "x86";
    } else if (type == CPU_TYPE_ARM64) {
        switch (subtype) {
        case CPU_SUBTYPE_ARM64_ALL:
            cpu_subtype = "arm64_all";
            break;
        case CPU_SUBTYPE_ARM64_V8:
            cpu_subtype = "arm64_v8";
            break;
        case CPU_SUBTYPE_ARM64E:
        case CPU_SUBTYPE_PTRAUTH_ABI | CPU_SUBTYPE_ARM64E:
            cpu_subtype = "arm64e";
            break;
        case CPU_SUBTYPE_ARM64E_MTE_MASK | CPU_SUBTYPE_ARM64E:
            cpu_subtype = "arm64e_mte";
            break;
        default:
            cpu_subtype = "arm64_unk";
            break;
        }
    } else {
        cpu_subtype = "x86_unk";
    }
    return cpu_subtype;
}


/**
 *  Grab a human-readable Mach-O header type
 * 
 *  @param              header type
 * 
 *  @returns            header type string.
 */
char *mach_header_read_file_type (uint32_t type)
{
    char *ret = "";
    switch (type) {
        case MACH_TYPE_OBJECT:
            ret = "Mach Object (MH_OBJECT)";
            break;
        case MACH_TYPE_EXECUTE:
            ret = "Mach Executable (MH_EXECUTE)";
            break;
        case MACH_TYPE_DYLIB:
            ret = "Mach Dynamic Library (MH_DYLIB)";
            break;
        case MACH_TYPE_KEXT_BUNDLE:
            ret = "Mach Kernel Extension Bundle (MH_KEXT_BUNDLE)";
            break;
        case MACH_TYPE_FILESET:
            ret = "Mach File Set (MH_FILESET)";
            break;
        case MACH_TYPE_DYLINKER:
            ret = "Mach Dyanmic Linker (MH_DYLINKER)";
            break;
        default:
            ret = "Unknown";
            warningf ("mach_header_read_file_type(): Unknown mach-o type: %d\n", type);
            break;
    }
    return ret;
}


/**
 *  Grab a human-readable Mach-O header type (in short)
 * 
 *  @param              header type
 * 
 *  @returns            short header type string.
 */
char *mach_header_read_file_type_short (uint32_t type)
{
    char *ret = "";
    switch (type) {
        case MACH_TYPE_OBJECT:
            ret = "Object";
            break;
        case MACH_TYPE_EXECUTE:
            ret = "Executable";
            break;
        case MACH_TYPE_DYLIB:
            ret = "Dynamic Library";
            break;
        case MACH_TYPE_FILESET:
            ret = "File set";
            break;
        case MACH_TYPE_DYLINKER:
            ret = "Dynamic Linker";
            break;
        default:
            ret = "Unknown";
            break;
    }
    return ret;
}
