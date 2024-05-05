//
//  vnode.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "vnode.h"
#include "krw.h"
#include "proc.h"
#include "offsets.h"
#include <sys/fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>
#include <sys/mman.h>
#include <Foundation/Foundation.h>
#include "thanks_opa334dev_htrowii.h"

uint64_t getVnodeAtPath(char* filename) {
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    
    uint64_t proc = getProc(getpid());

    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = unsign_kptr(filedesc_pac);
    uint64_t openedfile = kread64(filedesc + (8 * file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = unsign_kptr(fileglob_pac);
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t vnode = unsign_kptr(vnode_pac);
    
    close(file_index);
    
    return vnode;
}

uint64_t funVnodeHide(char* filename) {
    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    //vnode_ref, vnode_get
    uint32_t usecount = kread32(vnode + off_vnode_v_usecount);
    uint32_t iocount = kread32(vnode + off_vnode_v_iocount);
    printf("[i] vnode->usecount: %d, vnode->iocount: %d\n", usecount, iocount);
    kwrite32(vnode + off_vnode_v_usecount, usecount + 1);
    kwrite32(vnode + off_vnode_v_iocount, iocount + 1);
    
    //hide file
    uint32_t v_flags = kread32(vnode + off_vnode_v_flag);
    printf("[i] vnode->v_flags: 0x%x\n", v_flags);
    kwrite32(vnode + off_vnode_v_flag, (v_flags | VISSHADOW));

    //exist test (should not be exist
    printf("[i] %s access ret: %d\n", filename, access(filename, F_OK));
    
    //restore vnode iocount, usecount
    usecount = kread32(vnode + off_vnode_v_usecount);
    iocount = kread32(vnode + off_vnode_v_iocount);
    if(usecount > 0)
        kwrite32(vnode + off_vnode_v_usecount, usecount - 1);
    if(iocount > 0)
        kwrite32(vnode + off_vnode_v_iocount, iocount - 1);

    return vnode;
}

uint64_t funVnodeReveal(uint64_t vnode) {
    //vnode_ref, vnode_get
    uint32_t usecount = kread32(vnode + off_vnode_v_usecount);
    uint32_t iocount = kread32(vnode + off_vnode_v_iocount);
    printf("[i] vnode->usecount: %d, vnode->iocount: %d\n", usecount, iocount);
    kwrite32(vnode + off_vnode_v_usecount, usecount + 1);
    kwrite32(vnode + off_vnode_v_iocount, iocount + 1);
    
    //show file
    uint32_t v_flags = kread32(vnode + off_vnode_v_flag);
    kwrite32(vnode + off_vnode_v_flag, (v_flags &= ~VISSHADOW));
    
    //restore vnode iocount, usecount
    usecount = kread32(vnode + off_vnode_v_usecount);
    iocount = kread32(vnode + off_vnode_v_iocount);
    if(usecount > 0)
        kwrite32(vnode + off_vnode_v_usecount, usecount - 1);
    if(iocount > 0)
        kwrite32(vnode + off_vnode_v_iocount, iocount - 1);

    return 0;
}

uint64_t funVnodeChown(char* filename, uid_t uid, gid_t gid) {

    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    uint64_t v_data = kread64(vnode + off_vnode_v_data);
    uint32_t v_uid = kread32(v_data + 0x80);
    uint32_t v_gid = kread32(v_data + 0x84);
    
    //vnode->v_data->uid
    printf("[i] Patching %s vnode->v_uid %d -> %d\n", filename, v_uid, uid);
    kwrite32(v_data+0x80, uid);
    //vnode->v_data->gid
    printf("[i] Patching %s vnode->v_gid %d -> %d\n", filename, v_gid, gid);
    kwrite32(v_data+0x84, gid);
    
    struct stat file_stat;
    if(stat(filename, &file_stat) == 0) {
        printf("[+] %s UID: %d\n", filename, file_stat.st_uid);
        printf("[+] %s GID: %d\n", filename, file_stat.st_gid);
    }
    
    return 0;
}

uint64_t funVnodeChmod(char* filename, mode_t mode) {
    uint64_t vnode = getVnodeAtPath(filename);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s", filename);
        return -1;
    }
    
    uint64_t v_data = kread64(vnode + off_vnode_v_data);
    uint32_t v_mode = kread32(v_data + 0x88);
    
    printf("[i] Patching %s vnode->v_mode %o -> %o\n", filename, v_mode, mode);
    kwrite32(v_data+0x88, mode);
    
    struct stat file_stat;
    if(stat(filename, &file_stat) == 0) {
        printf("[+] %s mode: %o\n", filename, file_stat.st_mode);
    }
    
    return 0;
}

uint64_t findRootVnode(void) {
    uint64_t launchd_proc = getProc(1);
    
    uint64_t textvp_pac = kread64(launchd_proc + off_p_textvp);
    uint64_t textvp = unsign_kptr(textvp_pac);
    printf("[i] launchd proc->textvp: 0x%llx\n", textvp);

    uint64_t textvp_nameptr = kread64(textvp + off_vnode_v_name);
    uint64_t textvp_name = kread64(textvp_nameptr);
    uint64_t devvp = kread64(unsign_kptr(kread64(textvp + off_vnode_v_mount)) + off_mount_mnt_devvp);
    uint64_t nameptr = kread64(devvp + off_vnode_v_name);
    uint64_t name = kread64(nameptr);
    char* devName = &name;
    printf("[i] launchd proc->textvp->v_name: %s, v_mount->mnt_devvp->v_name: %s\n", &textvp_name, devName);
    
    uint64_t sbin_vnode = unsign_kptr(kread64(textvp + off_vnode_v_parent));
    textvp_nameptr = kread64(sbin_vnode + off_vnode_v_name);
    textvp_name = kread64(textvp_nameptr);
    devvp = kread64(unsign_kptr(kread64(textvp + off_vnode_v_mount)) + off_mount_mnt_devvp);
    nameptr = kread64(devvp + off_vnode_v_name);
    name = kread64(nameptr);
    devName = &name;
    printf("[i] launchd proc->textvp->v_parent->v_name: %s, v_mount->mnt_devvp->v_name:%s\n", &textvp_name, devName);
    
    uint64_t root_vnode = unsign_kptr(kread64(sbin_vnode + off_vnode_v_parent));
    textvp_nameptr = kread64(root_vnode + off_vnode_v_name);
    textvp_name = kread64(textvp_nameptr);
    devvp = kread64(unsign_kptr(kread64(root_vnode + off_vnode_v_mount)) + off_mount_mnt_devvp);
    nameptr = kread64(devvp + off_vnode_v_name);
    name = kread64(nameptr);
    devName = &name;
    printf("[i] launchd proc->textvp->v_parent->v_parent->v_name: %s, v_mount->mnt_devvp->v_name:%s\n", &textvp_name, devName);
    printf("[+] rootvnode: 0x%llx\n", root_vnode);
    
    return root_vnode;
}

uint64_t funVnodeRedirectFolder(char* to, char* from) {
    uint64_t to_vnode = getVnodeAtPathByChdir(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    uint64_t orig_to_v_data = kread64(to_vnode + off_vnode_v_data);
    
    uint64_t from_vnode = getVnodeAtPathByChdir(from);
    if(from_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", from);
        return -1;
    }
    
    //If mount point is different, return -1
    uint64_t to_devvp = kread64(unsign_kptr(kread64(to_vnode + off_vnode_v_mount)) + off_mount_mnt_devvp);
    uint64_t from_devvp = kread64(unsign_kptr(kread64(from_vnode + off_vnode_v_mount)) + off_mount_mnt_devvp);
    if(to_devvp != from_devvp) {
        printf("[-] mount points of folders are different!\n");
        return -1;
    }
    
    uint64_t from_v_data = kread64(from_vnode + off_vnode_v_data);
    
    kwrite32(to_vnode + off_vnode_v_usecount, to_usecount + 1);
    kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount + 1);
    kwrite8(to_vnode + off_vnode_v_references, to_v_references + 1);
    kwrite64(to_vnode + off_vnode_v_data, from_v_data);
    
    return orig_to_v_data;
}

uint64_t funVnodeOverwriteFile(char* to, char* from) {

    int to_file_index = open(to, O_RDONLY);
    if (to_file_index == -1) return -1;
    off_t to_file_size = lseek(to_file_index, 0, SEEK_END);
    
    int from_file_index = open(from, O_RDONLY);
    if (from_file_index == -1) return -1;
    off_t from_file_size = lseek(from_file_index, 0, SEEK_END);
    
    if(to_file_size < from_file_size) {
        close(from_file_index);
        close(to_file_index);
        printf("[-] File is too big to overwrite!");
        return -1;
    }
    
    uint64_t proc = getProc(getpid());
    
    //get vnode
    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = unsign_kptr(filedesc_pac);
    uint64_t openedfile = kread64(filedesc + (8 * to_file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = unsign_kptr(fileglob_pac);
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t to_vnode = unsign_kptr(vnode_pac);
    printf("[i] %s to_vnode: 0x%llx\n", to, to_vnode);
    
    uint64_t rootvnode_mount_pac = kread64(findRootVnode() + off_vnode_v_mount);
    uint64_t rootvnode_mount = unsign_kptr(rootvnode_mount_pac);
    uint32_t rootvnode_mnt_flag = kread32(rootvnode_mount + off_mount_mnt_flag);
    
    kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag & ~MNT_RDONLY);
    kwrite32(fileglob + off_fg_flag, FREAD | FWRITE);
    
    uint32_t to_vnode_v_writecount =  kread32(to_vnode + off_vnode_v_writecount);
    printf("[i] %s Increasing to_vnode->v_writecount: %d\n", to, to_vnode_v_writecount);
    if(to_vnode_v_writecount <= 0) {
        kwrite32(to_vnode + off_vnode_v_writecount, to_vnode_v_writecount + 1);
        printf("[+] %s Increased to_vnode->v_writecount: %d\n", to, kread32(to_vnode + off_vnode_v_writecount));
    }
    

    char* from_mapped = mmap(NULL, from_file_size, PROT_READ, MAP_PRIVATE, from_file_index, 0);
    if (from_mapped == MAP_FAILED) {
        perror("[-] Failed mmap (from_mapped)");
        kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
        close(from_file_index);
        close(to_file_index);
        return -1;
    }
    
    char* to_mapped = mmap(NULL, to_file_size, PROT_READ | PROT_WRITE, MAP_SHARED, to_file_index, 0);
    if (to_mapped == MAP_FAILED) {
        perror("[-] Failed mmap (to_mapped)");
        kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
        close(from_file_index);
        close(to_file_index);
        return -1;
    }
    
    memcpy(to_mapped, from_mapped, from_file_size);
    printf("[i] msync ret: %d\n", msync(to_mapped, to_file_size, MS_SYNC));
    
    munmap(from_mapped, from_file_size);
    munmap(to_mapped, to_file_size);
    
    kwrite32(fileglob + off_fg_flag, FREAD);
    kwrite32(rootvnode_mount + off_mount_mnt_flag, rootvnode_mnt_flag);
    
    close(from_file_index);
    close(to_file_index);
    
    return 0;
}

uint64_t funVnodeIterateByPath(char* dirname) {
    
    uint64_t vnode = getVnodeAtPath(dirname);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", dirname);
        return -1;
    }
    
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_name = kread64(vp_nameptr);
    
    printf("[i] vnode->v_name: %s\n", &vp_name);
    
    //get child directory
    
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    printf("[i] vnode->v_ncchildren.tqh_first: 0x%llx\n", vp_namecache);
    if(vp_namecache == 0)
        return 0;
    
    while(1) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        vp_nameptr = kread64(vnode + off_vnode_v_name);
        
        char vp_name[256];
        kreadbuf(vp_nameptr, &vp_name, 256);
        
        printf("[i] vnode->v_name: %s, vnode: 0x%llx\n", vp_name, vnode);
        vp_namecache = kread64(vp_namecache + off_namecache_nc_child_tqe_prev);
    }

    return 0;
}

uint64_t funVnodeIterateByVnode(uint64_t vnode) {
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_name = kread64(vp_nameptr);
    
    printf("[i] vnode->v_name: %s\n", &vp_name);
    
    //get child directory
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    printf("[i] vnode->v_ncchildren.tqh_first: 0x%llx\n", vp_namecache);
    if(vp_namecache == 0)
        return 0;
    
    while(1) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        vp_nameptr = kread64(vnode + off_vnode_v_name);
        
        char vp_name[256];
        kreadbuf(vp_nameptr, &vp_name, 256);
        
        printf("[i] vnode->v_name: %s, vnode: 0x%llx\n", vp_name, vnode);
        vp_namecache = kread64(vp_namecache + off_namecache_nc_child_tqe_prev);
    }

    return 0;
}

uint64_t getVnodeVar(void) {
    return getVnodeAtPathByChdir("/private/var");
}

uint64_t getVnodeVarMobile(void) {
    return getVnodeAtPathByChdir("/private/var/mobile");
}

uint64_t getVnodePreferences(void) {
    return getVnodeAtPathByChdir("/private/var/mobile/Library/Preferences");
}

uint64_t getVnodeLibrary(void) {
    return getVnodeAtPathByChdir("/private/var/mobile/Library");;
}

uint64_t getVnodeSystemGroup(void) {
    return getVnodeAtPathByChdir("/private/var/containers/Shared/SystemGroup");
}

uint64_t findChildVnodeByVnode(uint64_t vnode, char* childname) {
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_name = kread64(vp_nameptr);

    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    
    if(vp_namecache == 0)
        return 0;
    
    while(1) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        vp_nameptr = kread64(vnode + off_vnode_v_name);
        
        char vp_name[256];
        kreadbuf(vp_nameptr, &vp_name, 256);
//        printf("vp_name: %s\n", vp_name);
        
        if(strcmp(vp_name, childname) == 0) {
            return vnode;
        }
        vp_namecache = kread64(vp_namecache + off_namecache_nc_child_tqe_prev);
    }

    return 0;
}

uint64_t funVnodeRedirectFolderFromVnode(char* to, uint64_t from_vnode) {
    uint64_t to_vnode = getVnodeAtPathByChdir(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    uint64_t orig_to_v_data = kread64(to_vnode + off_vnode_v_data);
    
    //If mount point is different, return -1
    uint64_t to_devvp = kread64(unsign_kptr(kread64(to_vnode + off_vnode_v_mount)) + off_mount_mnt_devvp);
    uint64_t from_devvp = kread64(unsign_kptr(kread64(from_vnode + off_vnode_v_mount)) + off_mount_mnt_devvp);
    if(to_devvp != from_devvp) {
        printf("[-] mount points of folders are different!\n");
        return -1;
    }
    
    uint64_t from_v_data = kread64(from_vnode + off_vnode_v_data);
    
    kwrite32(to_vnode + off_vnode_v_usecount, to_usecount + 1);
    kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount + 1);
    kwrite8(to_vnode + off_vnode_v_references, to_v_references + 1);
    kwrite64(to_vnode + off_vnode_v_data, from_v_data);
    
    return orig_to_v_data;
}

uint64_t funVnodeUnRedirectFolder (char* to, uint64_t orig_to_v_data) {
    uint64_t to_vnode = getVnodeAtPathByChdir(to);
    if(to_vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", to);
        return -1;
    }
    
    uint8_t to_v_references = kread8(to_vnode + off_vnode_v_references);
    uint32_t to_usecount = kread32(to_vnode + off_vnode_v_usecount);
    uint32_t to_v_kusecount = kread32(to_vnode + off_vnode_v_kusecount);
    
    kwrite64(to_vnode + off_vnode_v_data, orig_to_v_data);
    
    if(to_usecount > 0)
       kwrite32(to_vnode + off_vnode_v_usecount, to_usecount - 1);
    if(to_v_kusecount > 0)
        kwrite32(to_vnode + off_vnode_v_kusecount, to_v_kusecount - 1);
    if(to_v_references > 0)
        kwrite8(to_vnode + off_vnode_v_references, to_v_references - 1);
    
    return 0;
}

uint64_t funVnodeOverwriteFileUnlimitSize(char* to, char* from) {

    int to_file_index = open(to, O_RDONLY);
    if (to_file_index == -1) return -1;
    
    int from_file_index = open(from, O_RDONLY);
    if (from_file_index == -1) return -1;
    off_t from_file_size = lseek(from_file_index, 0, SEEK_END);
    
    uint64_t proc = getProc(getpid());
    
    //get vnode
    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = unsign_kptr(filedesc_pac);
    uint64_t openedfile = kread64(filedesc + (8 * to_file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = unsign_kptr(fileglob_pac);
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t to_vnode = unsign_kptr(vnode_pac);
    printf("[i] %s to_vnode: 0x%llx\n", to, to_vnode);
    
    kwrite32(fileglob + off_fg_flag, FREAD | FWRITE);
    
    uint32_t to_vnode_v_writecount =  kread32(to_vnode + off_vnode_v_writecount);
    printf("[i] %s Increasing to_vnode->v_writecount: %d\n", to, to_vnode_v_writecount);
    if(to_vnode_v_writecount <= 0) {
        kwrite32(to_vnode + off_vnode_v_writecount, to_vnode_v_writecount + 1);
        printf("[+] %s Increased to_vnode->v_writecount: %d\n", to, kread32(to_vnode + off_vnode_v_writecount));
    }
    

    char* from_mapped = mmap(NULL, from_file_size, PROT_READ, MAP_PRIVATE, from_file_index, 0);
    if (from_mapped == MAP_FAILED) {
        perror("[-] Failed mmap (from_mapped)");
        close(from_file_index);
        close(to_file_index);
        return -1;
    }
    
    printf("[i] ftruncate ret: %d\n", ftruncate(to_file_index, 0));
    printf("[i] write ret: %zd\n", write(to_file_index, from_mapped, from_file_size));
    
    munmap(from_mapped, from_file_size);
    
    kwrite32(fileglob + off_fg_flag, FREAD);
    
    close(from_file_index);
    close(to_file_index);

    return 0;
}

uint64_t getVnodeAtPathByChdir(char *path) {
    if(access(path, F_OK) == -1)    return -1;
    if(chdir(path) == -1) return -1;
    
    uint64_t fd_cdir_vp = kread64(getProc(getpid()) + off_p_pfd + off_fd_cdir);
    chdir("/");
    return fd_cdir_vp;
}

uint64_t funVnodeRedirectFile(char* to, char* from, uint64_t* orig_to_vnode, uint64_t* orig_nc_vp)
{
    uint64_t to_vnode = getVnodeAtPath(to);
    if(to_vnode == -1) {
        NSString *to_dir = [[NSString stringWithUTF8String:to] stringByDeletingLastPathComponent];
        NSString *to_file = [[NSString stringWithUTF8String:to] lastPathComponent];
        uint64_t to_dir_vnode = getVnodeAtPathByChdir(to_dir.UTF8String);
        to_vnode = findChildVnodeByVnode(to_dir_vnode, to_file.UTF8String);
        if(to_vnode == 0) {
            printf("[-] Couldn't find file (to): %s", to);
            return -1;
        }
    }
    
    uint64_t from_vnode = getVnodeAtPath(from);
    if(from_vnode == -1) {
        NSString *from_dir = [[NSString stringWithUTF8String:from] stringByDeletingLastPathComponent];
        NSString *from_file = [[NSString stringWithUTF8String:from] lastPathComponent];
        uint64_t from_dir_vnode = getVnodeAtPathByChdir(from_dir.UTF8String);
        from_vnode = findChildVnodeByVnode(from_dir_vnode, from_file.UTF8String);
        if(from_vnode == 0) {
            printf("[-] Couldn't find file (from): %s", from);
            return -1;
        }
    }
    
    uint64_t to_vnode_nc = kread64(to_vnode + off_vnode_v_nclinks_lh_first);
    *orig_nc_vp = kread64(to_vnode_nc + off_namecache_nc_vp);
    *orig_to_vnode = to_vnode;
    kwrite64(to_vnode_nc + off_namecache_nc_vp, from_vnode);
    return 0;
}

uint64_t funVnodeUnRedirectFile(uint64_t orig_to_vnode, uint64_t orig_nc_vp)
{
    uint64_t to_vnode_nc = kread64(orig_to_vnode + off_vnode_v_nclinks_lh_first);
    kwrite64(to_vnode_nc + off_namecache_nc_vp, orig_nc_vp);
    return 0;
}

void vnode_increment(uint64_t vnode) {
    uint32_t holdcount = kread32(vnode + v_holdcount);
    kwrite32(vnode + v_holdcount, holdcount + 1);
}

// try reading through vp_ncchildren of /sbin/'s vnode to find launchd's namecache
// after that, kwrite namecache, vnode id -> thx bedtime / misfortune

int SwitchSysBin(uint64_t vnode, char* what, char* with)
{
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    if(vp_namecache == 0)
        return 0;
    
    while(1) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        vp_nameptr = kread64(vnode + off_vnode_v_name);
        
        char vp_name[256];
        kreadbuf(kread64(vp_namecache + 96), &vp_name, 256);
//        printf("vp_name: %s\n", vp_name);
        
        if(strcmp(vp_name, what) == 0)
        {
            uint64_t with_vnd = getVnodeAtPath(with);
            uint32_t with_vnd_id = kread64(with_vnd + 116);
            uint64_t patient = kread64(vp_namecache + 80);        // vnode the name refers
            uint32_t patient_vid = kread64(vp_namecache + 64);    // name vnode id
            printf("patient: %llx vid:%llx -> %llx\n", patient, patient_vid, with_vnd_id);

            kwrite64(vp_namecache + 80, with_vnd);
            kwrite32(vp_namecache + 64, with_vnd_id);
            vnode_increment(with_vnd);
            return vnode;
        }
        vp_namecache = kread64(vp_namecache + off_namecache_nc_child_tqe_prev);
    }
    return 0;
}

uint64_t SwitchSysBin160(char* to, char* from, uint64_t* orig_to_vnode, uint64_t* orig_nc_vp)
{
    uint64_t to_vnode = getVnodeAtPath(to);
    if(to_vnode == -1) {
        NSString *to_dir = [[NSString stringWithUTF8String:to] stringByDeletingLastPathComponent];
        NSString *to_file = [[NSString stringWithUTF8String:to] lastPathComponent];
        uint64_t to_dir_vnode = getVnodeAtPathByChdir(to_dir.UTF8String);
        to_vnode = findChildVnodeByVnode(to_dir_vnode, to_file.UTF8String);
        if(to_vnode == 0) {
            printf("[-] Couldn't find file (to): %s", to);
            return -1;
        }
    }

    uint64_t from_vnode = getVnodeAtPath(from);
    if(from_vnode == -1) {
        NSString *from_dir = [[NSString stringWithUTF8String:from] stringByDeletingLastPathComponent];
        NSString *from_file = [[NSString stringWithUTF8String:from] lastPathComponent];
        uint64_t from_dir_vnode = getVnodeAtPathByChdir(from_dir.UTF8String);
        from_vnode = findChildVnodeByVnode(from_dir_vnode, from_file.UTF8String);
        if(from_vnode == 0) {
            printf("[-] Couldn't find file (from): %s", from);
            return -1;
        }
    }

    uint64_t to_vnode_nc = kread64(to_vnode + off_vnode_v_nclinks_lh_first);
    *orig_nc_vp = kread64(to_vnode_nc + off_namecache_nc_vp);
    *orig_to_vnode = to_vnode;
    kwrite64(to_vnode_nc + off_namecache_nc_vp, from_vnode);
    return 0;
}

