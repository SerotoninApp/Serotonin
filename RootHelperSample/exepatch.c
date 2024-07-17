
#include "exepatch.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <mach-o/fat.h>
#include <mach-o/nlist.h>
#include <mach-o/loader.h>
#include <mach-o/fixup-chains.h>
#include <mach/vm_page_size.h>
#include <assert.h>
#include <libgen.h>

#define SYSLOG(...)   //  do {printf(__VA_ARGS__);printf("\n");} while(0)
char* BOOTSTRAP_INSTALL_NAME = "@loader_path/generalhooksigned.dylib";

extern void abort(void); //???
static size_t write_uleb128(uint64_t val, uint8_t buf[10])
{
    uint8_t* start=buf;
    unsigned char c;
    bool flag;
    do {
        c = val & 0x7f;
        val >>= 7;
        flag = val != 0;
        *buf++ = c | (flag ? 0x80 : 0);
    } while (flag);
    return buf-start;
}
static size_t write_sleb128(uint64_t val, uint8_t buf[10])
{
    uint8_t* start=buf;
    unsigned char c;
    bool flag;
    do {
        c = val & 0x7f;
        val >>= 7;
        flag = c & 0x40 ? val != -1 : val != 0;
        *buf++ = c | (flag ? 0x80 : 0);
    } while (flag);
    return buf-start;
}
static uint64_t read_uleb128(uint8_t** pp, uint8_t* end)
{
    uint8_t* p = *pp;
    uint64_t result = 0;
    int         bit = 0;
    do {
        if ( p == end ) {
            abort();
            break;
        }
        uint64_t slice = *p & 0x7f;

        if ( bit > 63 ) {
            abort();
            break;
        }
        else {
            result |= (slice << bit);
            bit += 7;
        }
    }
    while (*p++ & 0x80);
    *pp = p;
    return result;
}
static int64_t read_sleb128(uint8_t** pp, uint8_t* end)
{
    uint8_t* p = *pp;
    int64_t  result = 0;
    int      bit = 0;
    uint8_t  byte = 0;
    do {
        if ( p == end ) {
            abort();
            break;
        }
        byte = *p++;
        result |= (((int64_t)(byte & 0x7f)) << bit);
        bit += 7;
    } while (byte & 0x80);
    *pp = p;
    // sign extend negative numbers
    if ( ((byte & 0x40) != 0) && (bit < 64) )
        result |= (~0ULL) << bit;
    return result;
}

char* BindCodeDesc[] = 
{
"BIND_OPCODE_DONE", //					0x00
"BIND_OPCODE_SET_DYLIB_ORDINAL_IMM", //			0x10
"BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB", //			0x20
"BIND_OPCODE_SET_DYLIB_SPECIAL_IMM", //			0x30
"BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM", //		0x40
"BIND_OPCODE_SET_TYPE_IMM", //				0x50
"BIND_OPCODE_SET_ADDEND_SLEB", //				0x60
"BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB", //			0x70
"BIND_OPCODE_ADD_ADDR_ULEB", //				0x80
"BIND_OPCODE_DO_BIND", //					0x90
"BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB", //			0xA0
"BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED", //			0xB0
"BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB", //		0xC0
"BIND_OPCODE_THREADED", //					0xD0
};

enum bindtype {
    bindtype_bind,
    bindtype_lazy,
    bindtype_weak
};

#define rebuild(p, copysize, resized) {\
newbind = realloc(newbind, newsize+copysize);\
memcpy((void*)((uint64_t)newbind+newsize), p, copysize);\
newsize += copysize;\
copied=true;\
if(resized) rebuilt=true;\
}

void* rebind(struct mach_header_64* header, enum bindtype type, void* data, uint32_t* size)
{
    bool rebuilt=false;
    void* newbind = NULL;
    size_t newsize = 0;

    uint8_t*  p    = (uint8_t*)data;
    uint8_t*  end  = (uint8_t*)((uint64_t)data + *size);
    bool stop=false;
    int i=0;
    while ( !stop && (p < end) ) 
    {
        bool copied=false;
        uint8_t immediate = *p & BIND_IMMEDIATE_MASK;
        uint8_t opcode = *p & BIND_OPCODE_MASK;
        uint8_t* curp = p++;
        static char* bindtypedesc[] = {"bind","lazy","weak"};
        SYSLOG("[%s][%d] %02X %s %02X", bindtypedesc[type], i++, opcode, BindCodeDesc[opcode>>4], immediate);
        switch (opcode) {
            case BIND_OPCODE_DONE:
                if(type!=bindtype_lazy) stop = true;
                break;
            case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
            {
                assert(type != bindtype_weak);
                int libraryOrdinal = (int)immediate;
                SYSLOG("=%d", libraryOrdinal);
                if(libraryOrdinal > 0) {
                    SYSLOG("rebind -> %d", libraryOrdinal+1);
                    if(libraryOrdinal<BIND_IMMEDIATE_MASK) {
                        *curp = opcode | libraryOrdinal+1;
                    } else {
                        uint8_t newop = BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB;
                        rebuild(&newop, 1, false);
                        uint8_t ordinal[10];
                        rebuild(ordinal, write_uleb128(libraryOrdinal+1, ordinal), true);
                    }
                }
            }
            break;
            case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
            {
                assert(type != bindtype_weak);
                uint8_t* oldp=p;
                int libraryOrdinal = (int)read_uleb128(&p, end);
                ++i;
                SYSLOG("=%d", libraryOrdinal);
                if(libraryOrdinal > 0) {
                    SYSLOG("rebind -> %d", libraryOrdinal+1);
                    uint8_t ordinal[10];
                    int newlen = write_uleb128(libraryOrdinal+1, ordinal);
                    if(newlen==(p-oldp)) {
                        memcpy(oldp, ordinal, newlen);
                    } else {
                        rebuild(curp, 1, false);
                        rebuild(ordinal, newlen, true);
                    }
                }
            }
            break;

            case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                assert(type != bindtype_weak);
                break;
            case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                ++i;
                while (*p != '\0')
                    ++p;
                ++p;
                break;
            case BIND_OPCODE_SET_TYPE_IMM:
                assert(type != bindtype_lazy);
                break;
            case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                ++i;
                read_uleb128(&p, end);
                break;
            case BIND_OPCODE_SET_ADDEND_SLEB:
                ++i;
                read_sleb128(&p, end);
                break;
            case BIND_OPCODE_DO_BIND:
                break;
            case BIND_OPCODE_THREADED:
                switch (immediate) {
                    case BIND_SUBOPCODE_THREADED_SET_BIND_ORDINAL_TABLE_SIZE_ULEB:
                    {
                        ++i;
                        uint64_t targetTableCount = read_uleb128(&p, end);
                        assert (!( targetTableCount > 65535 ));
                    }
                    break;
                    case BIND_SUBOPCODE_THREADED_APPLY:
                        break;
                    default:
                        abort();
                }
                break;
            case BIND_OPCODE_ADD_ADDR_ULEB:
            case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                assert(type != bindtype_lazy);
                read_uleb128(&p, end);
                ++i;
                break;
            case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                assert(type != bindtype_lazy);
                break;
            case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                assert(type != bindtype_lazy);
                read_uleb128(&p, end);
                ++i;
                read_uleb128(&p, end);
                ++i;
                break;
            default:
                abort();
        }

        if(!copied) rebuild(curp, p-curp, false);
    }

    if(rebuilt) {
        *size = newsize;
        return newbind;
    }

    if(newbind) free(newbind);
    return NULL;
}

int patch_macho(int fd, struct mach_header_64* header)
{
    int libOrdinal=1;
    int prelibOrdinal=0;
    bool found_new_bootstrap = false;
    int first_sec_off = 0;
    struct segment_command_64* linkedit_seg = NULL;
    struct symtab_command* symtab = NULL;
    struct dysymtab_command* dysymtab = NULL;
    struct linkedit_data_command* fixup = NULL;
    struct dylib_command* first_dylib = NULL;
    struct dyld_info_command* dyld_info = NULL;
    struct linkedit_data_command* code_sign = NULL;
    
    struct load_command* lc = (struct load_command*)((uint64_t)header + sizeof(*header));
    for (int i = 0; i < header->ncmds; i++) {
                
        switch(lc->cmd) {
                
            case LC_LOAD_DYLIB:
            case LC_LOAD_WEAK_DYLIB:
            case LC_REEXPORT_DYLIB:
            case LC_LOAD_UPWARD_DYLIB:
			{
                if(!first_dylib) first_dylib = (struct dylib_command*)lc;

                struct dylib_command* idcmd = (struct dylib_command*)lc;
                char* name = (char*)((uint64_t)idcmd + idcmd->dylib.name.offset);
                SYSLOG("libOrdinal=%d, %s\n", libOrdinal, name);

                if(strcmp(name, BOOTSTRAP_INSTALL_NAME)==0) {
                    SYSLOG("bootstrap library exists @ %d!\n", libOrdinal);
                    prelibOrdinal = libOrdinal;
                    found_new_bootstrap = true;
                }

                libOrdinal++;
                break;
            }

            case LC_SYMTAB: {
                symtab = (struct symtab_command*)lc;
                SYSLOG("symtab offset=%x count=%d strtab offset=%x size=%x\n", symtab->symoff, symtab->nsyms, symtab->stroff, symtab->strsize);
                
                break;
            }
                
            case LC_DYSYMTAB: {
                dysymtab = (struct dysymtab_command*)lc;
                SYSLOG("dysymtab export_index=%d count=%d, import_index=%d count=%d, \n", dysymtab->iextdefsym, dysymtab->nextdefsym, dysymtab->iundefsym, dysymtab->nundefsym);
                
                break;
            }
                
            case LC_SEGMENT_64: {
                struct segment_command_64 * seg = (struct segment_command_64 *) lc;
                
                SYSLOG("segment: %s file=%llx:%llx vm=%16llx:%16llx\n", seg->segname, seg->fileoff, seg->filesize, seg->vmaddr, seg->vmsize);
                
                if(strcmp(seg->segname,SEG_LINKEDIT)==0)
                    linkedit_seg = seg;
                
                struct section_64* sec = (struct section_64*)((uint64_t)seg+sizeof(*seg));
                for(int j=0; j<seg->nsects; j++)
                {
                    SYSLOG("section[%d] = %s/%s offset=%x vm=%16llx:%16llx\n", j, sec[j].segname, sec[j].sectname,
                          sec[j].offset, sec[j].addr, sec[j].size);
                    
                    if(sec[j].offset && (first_sec_off==0 || first_sec_off>sec[j].offset)) {
                        SYSLOG("first_sec_off %x => %x\n", first_sec_off, sec[j].offset);
                        first_sec_off = sec[j].offset;
                    }
                }
                break;
            }
                
            case LC_DYLD_CHAINED_FIXUPS: {
                fixup = (struct linkedit_data_command*)lc;
                break;
            }

            case LC_DYLD_INFO:
            case LC_DYLD_INFO_ONLY:
                assert(dyld_info==NULL);
                dyld_info = (struct dyld_info_command*)lc;
                break;

            case LC_CODE_SIGNATURE:
                code_sign = (struct linkedit_data_command*)lc;
                break;
		}
        
        /////////
        lc = (struct load_command *) ((char *)lc + lc->cmdsize);
	}

//    if(prelibOrdinal > 0) {
//        //keep old way, assert(prelibOrdinal == 1);
//        return 0;
//    }
    if(found_new_bootstrap) {
        return 0;
    }

    struct stat st;
    assert(fstat(fd, &st)==0);
    assert(st.st_size == (linkedit_seg->fileoff+linkedit_seg->filesize));

	int addsize = sizeof(struct dylib_command) + strlen(BOOTSTRAP_INSTALL_NAME) + 1;
	if(addsize%sizeof(void*)) addsize = (addsize/sizeof(void*) + 1) * sizeof(void*); //align
	if(first_sec_off < (sizeof(*header)+header->sizeofcmds+addsize))
	{
		fprintf(stderr, "mach-o header has no enough space!\n");
		return -1;
	}



   uint32_t* itab = (uint32_t*)( (uint64_t)header + dysymtab->indirectsymoff);
   for(int i=0; i<dysymtab->nindirectsyms; i++) {
       SYSLOG("indirect sym[%d] %d\n", i, itab[i]);
   }

    struct nlist_64* symbols64 = (struct nlist_64*)( (uint64_t)header + symtab->symoff);
    for(int i=0; i<symtab->nsyms; i++) {
        char* symstr = (char*)( (uint64_t)header + symtab->stroff + symbols64[i].n_un.n_strx);
        SYSLOG("sym[%d] type:%02x sect:%02x desc:%04x value:%llx \tstr:%x\t%s\n", i, symbols64[i].n_type, symbols64[i].n_sect, symbols64[i].n_desc, symbols64[i].n_value, symbols64[i].n_un.n_strx, symstr);
        
        if(i>=dysymtab->iundefsym && i<(dysymtab->iundefsym+dysymtab->nundefsym))
        {
            uint16_t n_desc = symbols64[i].n_desc;
            uint8_t  n_type = symbols64[i].n_type;
            
            int ordinal= GET_LIBRARY_ORDINAL(n_desc);
            //assert(ordinal > 0); ordinal=0:BIND_SPECIAL_DYLIB_SELF
            
            // Handle defined weak def symbols which need to get a special ordinal
            if ( ((n_type & N_TYPE) == N_SECT) && ((n_type & N_EXT) != 0) && ((n_desc & N_WEAK_DEF) != 0) )
                ordinal = BIND_SPECIAL_DYLIB_WEAK_LOOKUP;
            
            if(ordinal > 0) SET_LIBRARY_ORDINAL(symbols64[i].n_desc, ordinal+1);
        }
    }
    
    if(fixup)
    {
        struct dyld_chained_fixups_header* chainsHeader = (struct dyld_chained_fixups_header*)((uint64_t)header + fixup->dataoff);
        assert(chainsHeader->fixups_version == 0);
        assert(chainsHeader->symbols_format == 0);
        SYSLOG("import format=%d offset=%x count=%d\n", chainsHeader->imports_format, chainsHeader->imports_offset,
               chainsHeader->imports_count);
        
        struct dyld_chained_import*          imports;
        struct dyld_chained_import_addend*   importsA32;
        struct dyld_chained_import_addend64* importsA64;
        char*                         symbolsPool     = (char*)chainsHeader + chainsHeader->symbols_offset;
        int                                 libOrdinal;
        switch (chainsHeader->imports_format) {
            case DYLD_CHAINED_IMPORT:
                imports = (struct dyld_chained_import*)((uint8_t*)chainsHeader + chainsHeader->imports_offset);
                for (uint32_t i=0; i < chainsHeader->imports_count; ++i) {
                     char* symbolName = &symbolsPool[imports[i].name_offset];
                    uint8_t libVal = imports[i].lib_ordinal;
                    if ( libVal > 0xF0 )
                        libOrdinal = (int8_t)libVal;
                    else
                        libOrdinal = libVal;
                    
                    /* c++ template may link as weak symbols:BIND_SPECIAL_DYLIB_WEAK_LOOKUP
                     https://stackoverflow.com/questions/58241873/why-are-functions-generated-on-use-of-template-have-weak-as-symbol-type
                     https://stackoverflow.com/questions/44335046/how-does-the-linker-handle-identical-template-instantiations-across-translation
                     */
                    
                    SYSLOG("import[%d] ordinal=%x weak=%d name=%s\n", i, imports[i].lib_ordinal, imports[i].weak_import, symbolName);
                    if(libOrdinal > 0) imports[i].lib_ordinal = libOrdinal+1;
                }
                break;
            case DYLD_CHAINED_IMPORT_ADDEND:
                importsA32 = (struct dyld_chained_import_addend*)((uint8_t*)chainsHeader + chainsHeader->imports_offset);
                for (uint32_t i=0; i < chainsHeader->imports_count; ++i) {
                     char* symbolName = &symbolsPool[importsA32[i].name_offset];
                    uint8_t libVal = importsA32[i].lib_ordinal;
                    if ( libVal > 0xF0 )
                        libOrdinal = (int8_t)libVal;
                    else
                        libOrdinal = libVal;
                    
                    SYSLOG("importA32[%d] ordinal=%x weak=%d name=%s\n", i, importsA32[i].lib_ordinal, importsA32[i].weak_import, symbolName);
                    if(libOrdinal > 0) importsA32[i].lib_ordinal = libOrdinal+1;
                }
                break;
            case DYLD_CHAINED_IMPORT_ADDEND64:
                importsA64 = (struct dyld_chained_import_addend64*)((uint8_t*)chainsHeader + chainsHeader->imports_offset);
                for (uint32_t i=0; i < chainsHeader->imports_count; ++i) {
                     char* symbolName = &symbolsPool[importsA64[i].name_offset];
                    uint16_t libVal = importsA64[i].lib_ordinal;
                    if ( libVal > 0xFFF0 )
                        libOrdinal = (int16_t)libVal;
                    else
                        libOrdinal = libVal;
                    
                    SYSLOG("importA64[%d] ordinal=%x weak=%d name=%s\n", i, importsA64[i].lib_ordinal, importsA64[i].weak_import, symbolName);
                    if(libOrdinal > 0)  importsA64[i].lib_ordinal = libOrdinal+1;
                }
                break;
           default:
                fprintf(stderr, "unknown imports format: %d\n", chainsHeader->imports_format);
                return -1;
        }
    }

    size_t newfsize = 0;

    if(dyld_info)
    {
        assert(dyld_info->bind_off != 0); //follow dyld

        newfsize = st.st_size;

        if(dyld_info->bind_off && dyld_info->bind_size)
        {
            SYSLOG("bind_off=%x size=%x", dyld_info->bind_off, dyld_info->bind_size);
            uint32_t size = dyld_info->bind_size;
            void* data = (void*)((uint64_t)header + dyld_info->bind_off);
            void* newbind = rebind(header, bindtype_bind, data, &size);
            SYSLOG("new bind=%p size=%x", newbind, size);
            if(newbind) 
            {
                assert(lseek(fd, 0, SEEK_END)==newfsize);
                assert(write(fd, newbind, size)==size);
                dyld_info->bind_off = newfsize;
                dyld_info->bind_size = size;
                linkedit_seg->filesize += size;
                linkedit_seg->vmsize += size;
                newfsize += size;

                free(newbind);
            }
        }
        if(dyld_info->weak_bind_off && dyld_info->weak_bind_size)
        {
            SYSLOG("weak_bind_off=%x size=%x", dyld_info->weak_bind_off, dyld_info->weak_bind_size);
            uint32_t size = dyld_info->weak_bind_size;
            void* data = (void*)((uint64_t)header + dyld_info->weak_bind_off);
            void* newbind = rebind(header, bindtype_weak, data, &size);
            SYSLOG("new weak bind=%p size=%x", newbind, size);
            assert(newbind == NULL); //weak bind, no ordinal
        }
        if(dyld_info->lazy_bind_off && dyld_info->lazy_bind_size)
        {
            SYSLOG("lazy_bind_off=%x size=%x", dyld_info->lazy_bind_off, dyld_info->lazy_bind_size);
            uint32_t size = dyld_info->lazy_bind_size;
            void* data = (void*)((uint64_t)header + dyld_info->lazy_bind_off);
            void* newbind = rebind(header, bindtype_lazy, data, &size);
            SYSLOG("new lazy bind=%p size=%x", newbind, size);
            if(newbind) 
            {
                assert(lseek(fd, 0, SEEK_END)==newfsize);
                assert(write(fd, newbind, size)==size);
                dyld_info->lazy_bind_off = newfsize;
                dyld_info->lazy_bind_size = size;
                linkedit_seg->filesize += size;
                linkedit_seg->vmsize += size;
                newfsize += size;

                free(newbind);
            }
        }

        if(code_sign && newfsize!=st.st_size)
        {
            // some machos has padding data in the end
            // assert(st.st_size == (code_sign->dataoff+code_sign->datasize));

            void* data = (void*)((uint64_t)header + code_sign->dataoff);
            size_t size = code_sign->datasize;
            assert(lseek(fd, 0, SEEK_END)==newfsize);
            assert(write(fd, data, size)==size);
            code_sign->dataoff = newfsize;
            linkedit_seg->filesize += size;
            linkedit_seg->vmsize += size;
            newfsize += size; 
        }

        // for(int i=0; i<(newfsize%0x10); i++) {
        //     int zero=0;
        //     linkedit_seg->filesize++;
        //     assert(write(fd, &zero, 1)==1);
        // }

        linkedit_seg->vmsize = round_page(linkedit_seg->vmsize);
    }


	// struct dylib_command* newlib = (struct dylib_command*)((uint64_t)header + sizeof(*header) + header->sizeofcmds);

    //last
    struct dylib_command* newlib = first_dylib;
    size_t first_dylib_offset = (uint64_t)newlib - ((uint64_t)header + sizeof(*header));
	memmove((void*)((uint64_t)newlib + addsize), newlib, header->sizeofcmds-first_dylib_offset);

	newlib->cmd = LC_LOAD_DYLIB;
	newlib->cmdsize = addsize;
	newlib->dylib.timestamp = 0;
	newlib->dylib.current_version = 0;
	newlib->dylib.compatibility_version = 0;
	newlib->dylib.name.offset = sizeof(*newlib);
	strcpy((char*)newlib+sizeof(*newlib), BOOTSTRAP_INSTALL_NAME);
	
	header->sizeofcmds += addsize;
	header->ncmds++;

    assert(lseek(fd, 0, SEEK_SET) == 0);
	if(write(fd, header, st.st_size) != st.st_size) {
		fprintf(stderr, "write %lld error:%d,%s\n", st.st_size, errno, strerror(errno));
        return -1;
	}

	return 0;
}

int patch_executable(const char* file, uint64_t offset, uint64_t size)
{
	int fd = open(file, O_RDWR);
    if(fd < 0) {
        fprintf(stderr, "open %s error:%d,%s\n", file, errno, strerror(errno));
        return -1;
    }
    
    struct stat st;
    if(stat(file, &st) < 0) {
        fprintf(stderr, "stat %s error:%d,%s\n", file, errno, strerror(errno));
        return -1;
    }
    
    SYSLOG("file size = %lld\n", st.st_size);
    
    void* macho = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_PRIVATE, fd, offset);
    if(macho == MAP_FAILED) {
        fprintf(stderr, "map %s error:%d,%s\n", file, errno, strerror(errno));
        return -1;
    }

    if(offset != 0) {
        assert(ftruncate(fd, 0)==0);
        assert(write(fd, macho, size)==size);
        assert(fsync(fd)==0);
        assert(stat(file, &st)==0);
        assert(st.st_size==size);
    }

    struct mach_header_64* header = (struct mach_header_64*)((uint64_t)macho + 0);

	int retval = patch_macho(fd, header);
	SYSLOG("patch macho @ %x : %d", offset, retval);

    munmap(macho, st.st_size);

    close(fd);

    return retval;
}

#include <choma/MachO.h>
#include <choma/Host.h>
int patch_app_exe(const char* file, char* insert_path)
{
    if (insert_path != NULL && insert_path[0] != '\0') {
        BOOTSTRAP_INSTALL_NAME = insert_path;
    }
    FAT *fat = fat_init_from_path(file);
    if (!fat) return -1;
    MachO *macho = fat_find_preferred_slice(fat);
    if (!macho) return -1;
    // printf("offset=%llx size=%llx\n", macho->archDescriptor.offset, macho->archDescriptor.size);
	return patch_executable(file, macho->archDescriptor.offset, macho->archDescriptor.size);
}

