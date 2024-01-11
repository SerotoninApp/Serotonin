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
 *  Table translating LCs to strings
 */
struct __libhelper_lc_string {
    uint32_t         lc;
    char            *str;
};


static struct __libhelper_lc_string lc_list[] =
{   
    { LC_SEGMENT,                       "LC_SEGMENT"                    },
    { LC_SYMTAB,                        "LC_SYMTAB"                     },
    { LC_SYMSEG,                        "LC_SYMSEG"                     },

    { LC_THREAD,                        "LC_THREAD"                     },
    { LC_UNIXTHREAD,                    "LC_UNIXTHREAD"                 },
    { LC_LOADFVMLIB,                    "LC_LOADFVMLIB"                 },
    { LC_IDFVMLIB,                      "LC_IDFVMLIB"                   },
    { LC_IDENT,                         "LC_IDENT"                      },
    { LC_FVMFILE,                       "LC_FVMFILE"                    },
    { LC_PREPAGE,                       "LC_PREPAGE"                    },
    { LC_DYSYMTAB,                      "LC_DYSYMTAB"                   },
    { LC_LOAD_DYLIB,                    "LC_LOAD_DYLIB"                 },
    { LC_ID_DYLIB,                      "LC_ID_DYLIB"                   },
    { LC_LOAD_DYLINKER,                 "LC_LOAD_DYLINKER"              },
    { LC_ID_DYLINKER,                   "LC_ID_DYLINKER"                },
    { LC_PREBOUND_DYLIB,                "LC_PREBOUND_DYLIB"             },
    { LC_ROUTINES,                      "LC_ROUTINES"                   },
    { LC_SUB_FRAMEWORK,                 "LC_SUB_FRAMEWORK"              },
    { LC_SUB_UMBRELLA,                  "LC_SUB_UMBRELLA"               },
    { LC_SUB_CLIENT,                    "LC_SUB_CLIENT"                 },
    { LC_SUB_LIBRARY,                   "LC_SUB_LIBRARY"                },
    { LC_TWOLEVEL_HINTS,                "LC_TWOLEVEL_HINTS"             },
    { LC_PREBIND_CKSUM,                 "LC_PREBIND_CKSUM"              },

    { LC_LOAD_WEAK_DYLIB,               "LC_LOAD_WEAK_DYLIB"            },

    { LC_SEGMENT_64,                    "LC_SEGMENT_64"                 },
    { LC_ROUTINES_64,                   "LC_ROUTINES_64"                },
    { LC_UUID,                          "LC_UUID"                       },
    { LC_RPATH,                         "LC_RPATH"                      },
    { LC_CODE_SIGNATURE,                "LC_CODE_SIGNATURE"             },
    { LC_SEGMENT_SPLIT_INFO,            "LC_SEGMENT_SPLIT_INFO"         },
    { LC_REEXPORT_DYLIB,                "LC_REEXPORT_DYLIB"             },
    { LC_LAZY_LOAD_DYLIB,               "LC_LAZY_LOAD_DYLIB"            },
    { LC_ENCRYPTION_INFO,               "LC_ENCRYPTION_INFO"            },
    { LC_DYLD_INFO,                     "LC_DYLD_INFO"                  },
    { LC_DYLD_INFO_ONLY,                "LC_DYLD_INFO_ONLY"             },
    { LC_LOAD_UPWARD_DYLIB,             "LC_LOAD_UPWARD_DYLIB"          },
    { LC_VERSION_MIN_MACOSX,            "LC_VERSION_MIN_MACOSX"         },
    { LC_VERSION_MIN_IPHONEOS,          "LC_VERSION_MIN_IPHONEOS"       },
    { LC_FUNCTION_STARTS,               "LC_FUNCTION_STARTS"            },
    { LC_DYLD_ENVIRONMENT,              "LC_DYLD_ENVIRONMENT"           },
    { LC_MAIN,                          "LC_MAIN"                       },
    { LC_DATA_IN_CODE,                  "LC_DATA_IN_CODE"               },
    { LC_SOURCE_VERSION,                "LC_SOURCE_VERSION"             },
    { LC_DYLIB_CODE_SIGN_DRS,           "LC_DYLIB_CODE_SIGN_DRS"        },
    { LC_ENCRYPTION_INFO_64,            "LC_ENCRYPTION_INFO_64"         },
    { LC_LINKER_OPTION,                 "LC_LINKER_OPTION"              },
    { LC_LINKER_OPTIMIZATION_HINT,      "LC_LINKER_OPTIMIZATION_HINT"   },
    { LC_VERSION_MIN_TVOS,              "LC_VERSION_MIN_TVOS"           },
    { LC_VERSION_MIN_WATCHOS,           "LC_VERSION_MIN_WATCHOS"        },
    { LC_NOTE,                          "LC_NOTE"                       },
    { LC_BUILD_VERSION,                 "LC_BUILD_VERSION"              },
    { LC_DYLD_EXPORTS_TRIE,             "LC_DYLD_EXPORTS_TRIE"          },
    { LC_DYLD_CHAINED_FIXUPS,           "LC_DYLD_CHAINED_FIXUPS"        },

    { LC_FILESET_ENTRY,                 "LC_FILESET_ENTRY"              }
};

#define LIBHELPER_LC_LIST_LEN              (sizeof (lc_list) / sizeof (lc_list[0])) - 1

/**
 * 
 */
mach_load_command_t *mach_load_command_create ()
{
    mach_load_command_t *ret = malloc (sizeof (mach_load_command_t));
    memset (ret, '\0', sizeof (mach_load_command_t));
    return ret;
}


/**
 * 
 */
mach_load_command_info_t *mach_load_command_info_load (const char *data, uint32_t offset)
{
    mach_load_command_info_t *lc_inf = calloc (1, sizeof (mach_load_command_info_t));

    // loads bytes from `data[offset]`.
    lc_inf->lc = (mach_load_command_t *) (data + offset);
    if (!lc_inf->lc) {
        errorf ("mach_load_command_info_load(): Could not load LC: 0x%08x\n", offset);
        return NULL;
    }

    // fill the lc_inf struct
    lc_inf->offset = offset;

    return lc_inf;
}


/**
 * 
 */
char *mach_load_command_get_string (mach_load_command_t *lc)
{
    if (!lc->cmd) {
        debugf ("load-commands.c: mach_load_command_get_string(): lc->cmd not valid\n");
        goto lc_string_failed;
    }

    for (int i = 0; i < (int) LIBHELPER_LC_LIST_LEN; i++) {
        struct __libhelper_lc_string *cur = &lc_list[i];
        if (lc->cmd == cur->lc)
            return cur->str;
    }
lc_string_failed:
    return "LC_UNKNOWN";
}


//===-----------------------------------------------------------------------===//
/*-- Specific Load Commands              									 --*/
//===-----------------------------------------------------------------------===//

/**
 *  The Symtab command can stay here, but handling symbols
 *  should be in symbols.c
 */

mach_load_command_info_t *mach_lc_find_given_cmd (macho_t *macho, int cmd)
{
    uint32_t size = (uint32_t) h_slist_length (macho->lcmds);
    debugf ("load-commands.c: mach_lc_find_given_cmd(): macho->lcmds size: %d\n", size);

    for (uint32_t i = 0; i < size; i++) {
        mach_load_command_info_t *tmp = (mach_load_command_info_t *) h_slist_nth_data (macho->lcmds, (int) i);
        if (tmp->lc->cmd == (uint32_t) cmd)
            return tmp;
    }
    return NULL;
}


/**
 *  Find the LC_SOURCE_VERSION command from a given macho and construct a
 *  mach_source_version_command_t and return it.
 * 
 *  @param          macho to search in
 * 
 *  @returns        mach_source_version_command_t created.
 */
mach_source_version_command_t *mach_lc_find_source_version_cmd (macho_t *macho)
{
    size_t size = sizeof (mach_source_version_command_t);
    mach_source_version_command_t *ret = malloc (size);

    HSList *cmds = macho->lcmds;
    for (int i = 0; i < h_slist_length (cmds); i++) {
        mach_load_command_info_t *tmp = (mach_load_command_info_t *) h_slist_nth_data (cmds, i);
        if (tmp->lc->cmd == LC_SOURCE_VERSION) {
            ret = (mach_source_version_command_t *) macho_load_bytes (macho, size, tmp->offset);
            
            if (!ret) {
                debugf ("[*] Error: Failed to load LC_SOURCE_VERSION command from offset: 0x%llx\n");
                return NULL;
            } else {
                return ret;
            }
        }
    }

    return NULL;
}

/**
 * 
 */
char *mach_lc_load_str (macho_t *macho, uint32_t cmdsize, uint32_t struct_size, off_t cmd_offset, off_t str_offset)
{
    return macho_load_bytes (macho, cmdsize - struct_size, cmd_offset + str_offset);
}


/**
 *  Take a LC_SOURCE_VERSION command and unpack the version string.
 * 
 *  @param          svc command
 * 
 *  @returns        unpacked version string.
 */
char *mach_lc_source_version_string (mach_source_version_command_t *svc)
{
    char *ret = malloc(20);
    uint64_t a, b, c, d, e;

    if (svc->cmdsize != sizeof(mach_source_version_command_t)) {
        debugf ("Incorrect size\n");
    }

    a = (svc->version >> 40) & 0xffffff;
    b = (svc->version >> 30) & 0x3ff;
    c = (svc->version >> 20) & 0x3ff;
    d = (svc->version >> 10) & 0x3ff;
    e = svc->version & 0x3ff;

    if (e != 0) {
        snprintf (ret, 20, "%llu.%llu.%llu.%llu.%llu", a, b, c, d, e);
    } else if (d != 0) {
        snprintf (ret, 16, "%llu.%llu.%llu.%llu", a, b, c, d);
    } else if (c != 0) {
        snprintf (ret, 12, "%llu.%llu.%llu", a, b, c);
    } else {
        snprintf (ret, 8, "%llu.%llu", a, b);
    }

    return ret;
}


/////////////////////////////////////////////////////////////////////////////////////

/**
 *  Constructs a `mach_build_version_info_t` structure.
 * 
 *  @param          build_version_command to build the struct around
 *  @param          offset of the LC in the Mach-O
 *  @param          macho containing the LC
 * 
 *  @returns        `mach_build_version_info_t`
 */
mach_build_version_info_t *mach_lc_build_version_info (mach_build_version_command_t *bvc, off_t offset, macho_t *macho)
{
    mach_build_version_info_t *ret = malloc (sizeof(mach_build_version_info_t));

    // platform
    switch (bvc->platform) {
        case PLATFORM_MACOS:
            ret->platform = "macOS";
            break;
        case PLATFORM_IOS:
            ret->platform = "iOS";
            break;
        case PLATFORM_TVOS:
            ret->platform = "TvOS";
            break;
        case PLATFORM_WATCHOS:
            ret->platform = "WatchOS";
            break;
        case PLATFORM_BRIDGEOS:
            ret->platform = "BridgeOS";
            break;
        case PLATFORM_MACCATALYST:
            ret->platform = "macOS Catalyst";
            break;
        case PLATFORM_IOSSIMULATOR:
            ret->platform = "iOS Simulator";
            break;
        case PLATFORM_TVOSSIMULATOR:
            ret->platform = "TvOS Simulator";
            break;
        case PLATFORM_WATCHOSSIMULATOR:
            ret->platform = "WatchOS Simulator";
            break;
        case PLATFORM_DRIVERKIT:
            ret->platform = "DriverKit";
            break;
        default:
            ret->platform = "(null)";
            break;
    }

    // minos
    char *minos_tmp = malloc (10);
    if ((bvc->minos & 0xff) == 0) {
        snprintf (minos_tmp, 10, "%u.%u", bvc->minos >> 16, (bvc->minos >> 8) & 0xff);
    } else {
        snprintf (minos_tmp, 10, "%u.%u", bvc->minos >> 16, (bvc->minos >> 8) & 0xff);
    }
    ret->minos = minos_tmp;

    // sdk
    char *sdk_tmp = malloc (10);
    if (bvc->sdk == 0) {
        sdk_tmp = "(null)";
    } else {
        if ((bvc->sdk & 0xff) == 0) {
            snprintf (sdk_tmp, 10, "%u.%u", bvc->sdk >> 16, (bvc->sdk >> 8) & 0xff);
        } else {
            snprintf (sdk_tmp, 10, "%u.%u.%u", bvc->sdk >> 16, (bvc->sdk >> 8) & 0xff, bvc->sdk & 0xff);
        }
    }
    ret->sdk = sdk_tmp;

    // tools
    ret->ntools = bvc->ntools;
    off_t next_off = offset + sizeof(mach_build_version_command_t);
    for (uint32_t i = 0; i < ret->ntools; i++) {

        struct build_tool_version *btv = (struct build_tool_version *) macho_load_bytes (macho, sizeof(struct build_tool_version), next_off);
        build_tool_info_t *inf = malloc (sizeof(build_tool_info_t));

        switch (btv->tool) {
            case TOOL_CLANG:
                inf->tool = "Clang";
                break;
            case TOOL_LD:
                inf->tool = "LD";
                break;
            case TOOL_SWIFT:
                inf->tool = "Swift";
                break;
            default:
                inf->tool = "(null)";
                break;
        }
	
        inf->version = btv->version;

        ret->tools = h_slist_append (ret->tools, inf);

        next_off += sizeof(mach_build_version_command_t);
    }

    return ret;
}


/////////////////////////////////////////////////////////////////////////////////////

/**
 *  Construct a Dylib version number.
 * 
 *  @param          compressed version of the dylib
 * 
 *  @return         formatted dylib version
 */
char *mach_lc_load_dylib_format_version (uint32_t vers)
{
    char *buf = malloc(10);
    snprintf (buf, 10, "%d.%d.%d", vers >> 16, (vers >> 8) & 0xf, vers & 0xf);
    return buf;
}


/**
 *  Grab dylib Load Command from dylib command.
 * 
 *  @param          dylib command
 * 
 *  @returns        dylib Load Command type.
 */
char *mach_lc_dylib_get_type_string (mach_dylib_command_t *dylib)
{
    switch (dylib->cmd) {
    case LC_ID_DYLIB:
        return "LC_ID_DYLIB";
        break;
    case LC_LOAD_DYLIB:
        return "LC_LOAD_DYLIB";
        break;
    case LC_LOAD_WEAK_DYLIB:
        return "LC_LOAD_WEAK_DYLIB";
        break;
    case LC_REEXPORT_DYLIB:
        return "LC_REEXPORT_DYLIB";
        break;
    default:
        return "(null)";
        break;
    }
}

/////////////////////////////////////////////////////////////////////////////////////

/**
 *  Load the name of a given Dynamic Linker
 * 
 *  @param          macho the command is contained in
 *  @param          dylinker command
 *  @param          offset
 * 
 *  @returns        the dynamic linkers name.
 */
char *mach_lc_load_dylinker_name (macho_t *macho, mach_dylinker_command_t *dylinker, off_t offset)
{
    return macho_load_bytes (macho, dylinker->cmdsize - sizeof(mach_dylinker_command_t), offset + dylinker->offset);
}

/////////////////////////////////////////////////////////////////////////////////////

/**
 *  Load the name of a given Fileset Entry
 * 
 *  @param          macho the command is contained in.
 *  @param          filesetentry command
 *  @param          offset
 * 
 *  @returns        the fileset entry command name.
 */
char *mach_lc_load_fileset_entry_name (macho_t *macho, mach_fileset_entry_t *fileset, off_t offset)
{
    return macho_load_bytes (macho, fileset->cmdsize - sizeof (mach_fileset_entry_t), offset + fileset->offset);
}

/////////////////////////////////////////////////////////////////////////////////////

/**
 *  Finds and creates a mach_uuid_command_t from a given mach-o.
 *  
 *  @param          macho containing LC_UUID command
 * 
 *  @returns        mach_uuid_command_t created from given macho.
 */
mach_uuid_command_t *mach_lc_find_uuid_cmd (macho_t *macho)
{
    size_t size = sizeof (mach_uuid_command_t);
    mach_uuid_command_t *ret = malloc (size);

    HSList *cmds = macho->lcmds;
    for (int i = 0; i < h_slist_length (cmds); i++) {
        mach_load_command_info_t *tmp = (mach_load_command_info_t *) h_slist_nth_data (cmds, i);
        if (tmp->lc->cmd == LC_UUID) {
            ret = (mach_uuid_command_t *) macho_load_bytes (macho, size, tmp->offset);
            
            if (!ret) {
                debugf ("mach_lc_find_uuid_cmd(): Failed to load LC_UUID command from offset: 0x%llx\n");
                return NULL;
            } else {
                return ret;
            }
        }
    }

    return NULL;
}


/**
 *  Takes a LC_UUID command and upacks the uuid.
 * 
 *  @param          UUID command
 * 
 *  @returns        Unpacked UUID.
 */
char *mach_lc_uuid_string (mach_uuid_command_t *uuid)
{
    if (uuid->cmdsize != sizeof(mach_uuid_command_t)) {
        debugf ("Incorrect size\n");
        return NULL;
    }

    size_t size = sizeof(uint8_t) * 128;
    char *ret = malloc (size);
    snprintf (ret, size, "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                            (unsigned int)uuid->uuid[0], (unsigned int)uuid->uuid[1],
                            (unsigned int)uuid->uuid[2],  (unsigned int)uuid->uuid[3],
                            (unsigned int)uuid->uuid[4],  (unsigned int)uuid->uuid[5],
                            (unsigned int)uuid->uuid[6],  (unsigned int)uuid->uuid[7],
                            (unsigned int)uuid->uuid[8],  (unsigned int)uuid->uuid[9],
                            (unsigned int)uuid->uuid[10], (unsigned int)uuid->uuid[11],
                            (unsigned int)uuid->uuid[12], (unsigned int)uuid->uuid[13],
                            (unsigned int)uuid->uuid[14], (unsigned int)uuid->uuid[15]);

    return ret;
}

/////////////////////////////////////////////////////////////////////////////////////

/**
 * 
 */
mach_symtab_command_t *mach_lc_find_symtab_cmd (macho_t *macho)
{
    size_t size = sizeof (mach_symtab_command_t);
    mach_symtab_command_t *ret = malloc (size);
    
    mach_load_command_info_t *cmdinfo = mach_lc_find_given_cmd (macho, LC_SYMTAB);
    if (cmdinfo) {
        ret = (mach_symtab_command_t *) macho_load_bytes (macho, size, cmdinfo->offset);
    } else {
        return NULL;
    }

    return ret;
}


/**
 * 
 */
mach_dysymtab_command_t *mach_lc_find_dysymtab_cmd (macho_t *macho)
{
    size_t size = sizeof (mach_dysymtab_command_t);
    mach_dysymtab_command_t *ret = malloc (size);
    
    mach_load_command_info_t *cmdinfo = mach_lc_find_given_cmd (macho, LC_SYMTAB);
    ret = (mach_dysymtab_command_t *) macho_load_bytes (macho, size, cmdinfo->offset);

    debugf ("LC_DYSYMTAB: %d\n", LC_DYSYMTAB);
    debugf ("test symtab: 0x%llx\n", ret->cmdsize);

    return ret;
}

/////////////////////////////////////////////////////////////////////////////////////
