//
//  fun.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/25.
//

#include "krw.h"
#include "offsets.h"
#include <sys/stat.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/mount.h>
#include <sys/stat.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <sys/mman.h>
#include <mach/mach.h>
#include "proc.h"
#include "vnode.h"
//#include "grant_wallpaper_access.h"
#include "thanks_opa334dev_htrowii.h"
#include "utils.h"
#include "cs_blobs.h"
//#include "helpers.h"
#include "common.h"

int funUcred(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint64_t ucreds = kread64(proc_ro + off_p_ro_p_ucred);
    
    uint64_t cr_label_pac = kread64(ucreds + off_u_cr_label);
    uint64_t cr_label = cr_label_pac | base_pac_mask;
    NSLog(@"[i] self ucred->cr_label: 0x%llx", cr_label);
    printf("[i] self ucred->cr_label: 0x%llx", cr_label);
    
    uint64_t cr_posix_p = ucreds + off_u_cr_posix;
    NSLog(@"[i] self ucred->posix_cred->cr_uid: %u", kread32(cr_posix_p + off_cr_uid));
    NSLog(@"[i] self ucred->posix_cred->cr_ruid: %u", kread32(cr_posix_p + off_cr_ruid));
    NSLog(@"[i] self ucred->posix_cred->cr_svuid: %u", kread32(cr_posix_p + off_cr_svuid));
    NSLog(@"[i] self ucred->posix_cred->cr_ngroups: %u", kread32(cr_posix_p + off_cr_ngroups));
    NSLog(@"[i] self ucred->posix_cred->cr_groups: %u", kread32(cr_posix_p + off_cr_groups));
    NSLog(@"[i] self ucred->posix_cred->cr_rgid: %u", kread32(cr_posix_p + off_cr_rgid));
    NSLog(@"[i] self ucred->posix_cred->cr_svgid: %u", kread32(cr_posix_p + off_cr_svgid));
    NSLog(@"[i] self ucred->posix_cred->cr_gmuid: %u", kread32(cr_posix_p + off_cr_gmuid));
    NSLog(@"[i] self ucred->posix_cred->cr_flags: %u", kread32(cr_posix_p + off_cr_flags));
    
//    printf("[i] self ucred->posix_cred->cr_uid: %u\n", kread32(cr_posix_p + off_cr_uid));
//    printf("[i] self ucred->posix_cred->cr_ruid: %u\n", kread32(cr_posix_p + off_cr_ruid));
//    printf("[i] self ucred->posix_cred->cr_svuid: %u\n", kread32(cr_posix_p + off_cr_svuid));
//    printf("[i] self ucred->posix_cred->cr_ngroups: %u\n", kread32(cr_posix_p + off_cr_ngroups));
//    printf("[i] self ucred->posix_cred->cr_groups: %u\n", kread32(cr_posix_p + off_cr_groups));
//    printf("[i] self ucred->posix_cred->cr_rgid: %u\n", kread32(cr_posix_p + off_cr_rgid));
//    printf("[i] self ucred->posix_cred->cr_svgid: %u\n", kread32(cr_posix_p + off_cr_svgid));
//    printf("[i] self ucred->posix_cred->cr_gmuid: %u\n", kread32(cr_posix_p + off_cr_gmuid));
//    printf("[i] self ucred->posix_cred->cr_flags: %u\n", kread32(cr_posix_p + off_cr_flags));

    return 0;
}


int funCSFlags(char* process) {
    pid_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint32_t csflags = kread32(proc_ro + off_p_ro_p_csflags);
    NSLog(@"[i] %s proc->proc_ro->p_csflags: 0x%x", process, csflags);
//    printf("[i] %s proc->proc_ro->p_csflags: 0x%x\n", process, csflags);
    
#define TF_PLATFORM 0x400

#define CS_GET_TASK_ALLOW    0x0000004    /* has get-task-allow entitlement */
#define CS_INSTALLER        0x0000008    /* has installer entitlement */

#define    CS_HARD            0x0000100    /* don't load invalid pages */
#define    CS_KILL            0x0000200    /* kill process if it becomes invalid */
#define CS_RESTRICT        0x0000800    /* tell dyld to treat restricted */

#define CS_PLATFORM_BINARY    0x4000000    /* this is a platform binary */

#define CS_DEBUGGED         0x10000000  /* process is currently or has previously been debugged and allowed to run with invalid pages */
    
//    csflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
//    sleep(3);
//    kwrite32(proc_ro + off_p_ro_p_csflags, csflags);
    
    return 0;
}

int funTask(char* process) {
    pid_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    NSLog(@"[i] %s proc: 0x%llx", process, proc);
//    printf("[i] %s proc: 0x%llx\n", process, proc);
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    
    uint64_t pr_proc = kread64(proc_ro + off_p_ro_pr_proc);
    NSLog(@"[i] %s proc->proc_ro->pr_proc: 0x%llx", process, pr_proc);
//    printf("[i] %s proc->proc_ro->pr_proc: 0x%llx\n", process, pr_proc);
    
    uint64_t pr_task = kread64(proc_ro + off_p_ro_pr_task);
    NSLog(@"[i] %s proc->proc_ro->pr_task: 0x%llx", process, pr_task);
//    printf("[i] %s proc->proc_ro->pr_task: 0x%llx\n", process, pr_task);
    
    uint32_t t_flags = kread32(pr_task + off_task_t_flags);
    NSLog(@"[i] %s task->t_flags: 0x%x", process, t_flags);
//    printf("[i] %s task->t_flags: 0x%x\n", process, t_flags);
    
    
    /*
     * RO-protected flags:
     */
    #define TFRO_PLATFORM                   0x00000400                      /* task is a platform binary */
    #define TFRO_FILTER_MSG                 0x00004000                      /* task calls into message filter callback before sending a message */
    #define TFRO_PAC_EXC_FATAL              0x00010000                      /* task is marked a corpse if a PAC exception occurs */
    #define TFRO_PAC_ENFORCE_USER_STATE     0x01000000                      /* Enforce user and kernel signed thread state */
    
    uint32_t t_flags_ro = kread32(proc_ro + off_p_ro_t_flags_ro);
    NSLog(@"[i] %s proc->proc_ro->t_flags_ro: 0x%x", process, t_flags_ro);
//    printf("[i] %s proc->proc_ro->t_flags_ro: 0x%x\n", process, t_flags_ro);
    
    return 0;
}


void fix_exploit(void) {
    printf("[*] Exploit fixup");
    _offsets_init();
    pid_t myPid = getpid();
    uint64_t selfProc = getProc(myPid);
    funUcred(selfProc);
}
