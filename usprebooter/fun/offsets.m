//
//  offsets.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "offsets.h"
#include "../libkfd/commmon.h"
#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>

uint32_t off_p_list_le_prev = 0;
uint32_t off_p_proc_ro = 0;
uint32_t off_p_ppid = 0;
uint32_t off_p_original_ppid = 0;
uint32_t off_p_pgrpid = 0;
uint32_t off_p_uid = 0;
uint32_t off_p_gid = 0;
uint32_t off_p_ruid = 0;
uint32_t off_p_rgid = 0;
uint32_t off_p_svuid = 0;
uint32_t off_p_svgid = 0;
uint32_t off_p_sessionid = 0;
uint32_t off_p_puniqueid = 0;
uint32_t off_p_pid = 0;
uint32_t off_p_pfd = 0;
uint32_t off_p_textvp = 0;
uint32_t off_p_name = 0;
uint32_t off_p_ro_p_csflags = 0;
uint32_t off_p_ro_p_ucred = 0;
uint32_t off_p_ro_pr_proc = 0;
uint32_t off_p_ro_pr_task = 0;
uint32_t off_p_ro_t_flags_ro = 0;
uint32_t off_u_cr_label = 0;
uint32_t off_u_cr_posix = 0;
uint32_t off_cr_uid = 0;
uint32_t off_cr_ruid = 0;
uint32_t off_cr_svuid = 0;
uint32_t off_cr_ngroups = 0;
uint32_t off_cr_groups = 0;
uint32_t off_cr_rgid = 0;
uint32_t off_cr_svgid = 0;
uint32_t off_cr_gmuid = 0;
uint32_t off_cr_flags = 0;
uint32_t off_task_t_flags = 0;
uint32_t off_task_itk_space = 0;
uint32_t off_fd_ofiles = 0;
uint32_t off_fd_cdir = 0;
uint32_t off_fp_glob = 0;
uint32_t off_fg_data = 0;
uint32_t off_fg_flag = 0;
uint32_t off_vnode_v_ncchildren_tqh_first = 0;
uint32_t off_vnode_v_ncchildren_tqh_last = 0;
uint32_t off_vnode_v_nclinks_lh_first = 0;
uint32_t off_vnode_v_iocount = 0;
uint32_t off_vnode_v_usecount = 0;
uint32_t off_vnode_v_flag = 0;
uint32_t off_vnode_v_name = 0;
uint32_t off_vnode_v_mount = 0;
uint32_t off_vnode_v_data = 0;
uint32_t off_vnode_v_kusecount = 0;
uint32_t off_vnode_v_references = 0;
uint32_t off_vnode_v_lflag = 0;
uint32_t off_vnode_v_owner = 0;
uint32_t off_vnode_v_parent = 0;
uint32_t off_vnode_v_label = 0;
uint32_t off_vnode_v_cred = 0;
uint32_t off_vnode_v_writecount = 0;
uint32_t off_vnode_v_type = 0;
uint32_t off_vnode_v_id = 0;
uint32_t off_vnode_vu_ubcinfo = 0;
uint32_t off_mount_mnt_data = 0;
uint32_t off_mount_mnt_fsowner = 0;
uint32_t off_mount_mnt_fsgroup = 0;
uint32_t off_mount_mnt_devvp = 0;
uint32_t off_mount_mnt_flag = 0;
uint32_t off_specinfo_si_flags = 0;
uint32_t off_namecache_nc_dvp = 0;
uint32_t off_namecache_nc_vp = 0;
uint32_t off_namecache_nc_hashval = 0;
uint32_t off_namecache_nc_name = 0;
uint32_t off_namecache_nc_child_tqe_prev = 0;
uint32_t off_ipc_space_is_table = 0;
uint32_t off_ubc_info_cs_blobs = 0;
uint32_t off_ubc_info_cs_add_gen = 0;
uint32_t off_cs_blob_csb_pmap_cs_entry = 0;
uint32_t off_cs_blob_csb_cdhash = 0;
uint32_t off_cs_blob_csb_flags = 0;
uint32_t off_cs_blob_csb_teamid = 0;
uint32_t off_cs_blob_csb_validation_category = 0;
uint32_t off_pmap_cs_code_directory_ce_ctx = 0;
uint32_t off_pmap_cs_code_directory_der_entitlements_size = 0;
uint32_t off_pmap_cs_code_directory_trust = 0;
uint32_t off_ipc_entry_ie_object = 0;
uint32_t off_ipc_object_io_bits = 0;
uint32_t off_ipc_object_io_references = 0;
uint32_t off_ipc_port_ip_kobject = 0;

uint64_t off_gphysbase = 0;
uint64_t off_gphysize = 0;
uint64_t off_gvirtbase = 0;
uint64_t off_ptov__table = 0;

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)

void _offsets_init(void) {
    if (SYSTEM_VERSION_EQUAL_TO(@"16.1.2")) {
        printf("[i] offsets selected for iOS 16.1.2\n");
        //iPhone 14 Pro 16.1.2 offsets
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/proc_internal.h#L273
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/queue.h#L487
        off_p_list_le_prev = 0x8;
        off_p_proc_ro = 0x18;
        off_p_ppid = 0x20;
        off_p_original_ppid = 0x24;
        off_p_pgrpid = 0x28;
        off_p_uid = 0x2c;
        off_p_gid = 0x30;
        off_p_ruid = 0x34;
        off_p_rgid = 0x38;
        off_p_svuid = 0x3c;
        off_p_svgid = 0x40;
        off_p_sessionid = 0x44;
        off_p_puniqueid = 0x48;
        off_p_pid = 0x60;
        off_p_pfd = 0xf8;
        off_p_textvp = 0x350;
        off_p_name = 0x381;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/proc_ro.h#L59
        off_p_ro_p_csflags = 0x1c;
        off_p_ro_p_ucred = 0x20;
        off_p_ro_pr_proc = 0;
        off_p_ro_pr_task = 0x8;
        off_p_ro_t_flags_ro = 0x78;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ucred.h#L91
        off_u_cr_label = 0x78;
        off_u_cr_posix = 0x18;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ucred.h#L100
        off_cr_uid = 0;
        off_cr_ruid = 0x4;
        off_cr_svuid = 0x8;
        off_cr_ngroups = 0xc;
        off_cr_groups = 0x10;
        off_cr_rgid = 0x50;
        off_cr_svgid = 0x54;
        off_cr_gmuid = 0x58;
        off_cr_flags = 0x5c;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/kern/task.h#L280
        off_task_itk_space = 0x300;
        off_task_t_flags = 0x3D0;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/filedesc.h#L138
        off_fd_ofiles = 0;
        off_fd_cdir = 0x20;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/file_internal.h#L125
        off_fp_glob = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/file_internal.h#L179
        off_fg_data = 0x38;
        off_fg_flag = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/vnode_internal.h#L158
        off_vnode_v_ncchildren_tqh_first = 0x30;
        off_vnode_v_ncchildren_tqh_last = 0x38;
        off_vnode_v_nclinks_lh_first = 0x40;
        off_vnode_v_iocount = 0x64;
        off_vnode_v_usecount = 0x60;
        off_vnode_v_flag = 0x54;
        off_vnode_v_name = 0xb8;
        off_vnode_v_mount = 0xd8;
        off_vnode_v_data = 0xe0;
        off_vnode_v_kusecount = 0x5c;
        off_vnode_v_references = 0x5b;
        off_vnode_v_lflag = 0x58;
        off_vnode_v_owner = 0x68;
        off_vnode_v_parent = 0xc0;
        off_vnode_v_label = 0xe8;
        off_vnode_v_cred = 0x98;
        off_vnode_v_writecount = 0xb0;
        off_vnode_v_type = 0x70;
        off_vnode_v_id = 0x74;
        off_vnode_vu_ubcinfo = 0x78;
        
        //https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/mount_internal.h#L108
        off_mount_mnt_data = 0x11F;
        off_mount_mnt_fsowner = 0x9c0;
        off_mount_mnt_fsgroup = 0x9c4;
        off_mount_mnt_devvp = 0x980;
        off_mount_mnt_flag = 0x70;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/miscfs/specfs/specdev.h#L77
        off_specinfo_si_flags = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/namei.h#L243
        off_namecache_nc_dvp = 0x40;
        off_namecache_nc_vp = 0x48;
        off_namecache_nc_hashval = 0x50;
        off_namecache_nc_name = 0x58;
        off_namecache_nc_child_tqe_prev = 0x10;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/ipc/ipc_space.h#L123
        off_ipc_space_is_table = 0x20;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ubc_internal.h#L156
        off_ubc_info_cs_blobs = 0x50;
        off_ubc_info_cs_add_gen = 0x2c;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/bsd/sys/ubc_internal.h#L103
        off_cs_blob_csb_pmap_cs_entry = 0xb8;
        off_cs_blob_csb_cdhash = 0x58;
        off_cs_blob_csb_flags = 0x20;
        off_cs_blob_csb_teamid = 0x88;
        off_cs_blob_csb_validation_category = 0xb0; //https://gist.github.com/LinusHenze/4cd5d7ef057a144cda7234e2c247c056#file-ios_16_launch_constraints-txt-L39
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/vm/pmap_cs.h#L299
        off_pmap_cs_code_directory_ce_ctx = 0x1c8;
        off_pmap_cs_code_directory_der_entitlements_size = 0x1d8;
        off_pmap_cs_code_directory_trust = 0x1dc;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/ipc/ipc_entry.h#L111
        off_ipc_entry_ie_object = 0;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/ipc/ipc_object.h#L120
        off_ipc_object_io_bits = 0;
        off_ipc_object_io_references = 0x4;
        
        //https://github.com/apple-oss-distributions/xnu/blob/xnu-8792.41.9/osfmk/ipc/ipc_port.h#L167
        off_ipc_port_ip_kobject = 0x48; //https://github.com/0x7ff/dimentio/blob/7ffffffb4ebfcdbc46ab5e8f1becc0599a05711d/libdimentio.c#L973
        
        off_gphysbase = 0xFFFFFFF0077FF710;
        off_gphysize = 0xFFFFFFF0077FFAD8;
        off_gvirtbase = 0xFFFFFFF0077FF708;
        off_ptov__table = 0xFFFFFFF0077FFA18;
        
    } else {
        print("%s","[-] No matching offsets.\n");
        exit(EXIT_FAILURE);
    }
}
