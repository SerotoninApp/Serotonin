#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <stdio.h>
#include "fishhook.h"
#include <spawn.h>

int (*orig_csops)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int (*orig_csops_audittoken)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int (*orig_posix_spawn)(pid_t * __restrict pid, const char * __restrict path,
                        const posix_spawn_file_actions_t *file_actions,
                        const posix_spawnattr_t * __restrict attrp,
                        char *const argv[ __restrict], char *const envp[ __restrict]);

int hooked_csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize) {
    int result = orig_csops(pid, ops, useraddr, usersize);
    if (ops == 0) { // CS_OPS_STATUS
        *((uint32_t *)useraddr) |= 0x4000000; // CS_PLATFORM_BINARY
    }
    return result;
}

int hooked_csops_audittoken(pid_t pid, unsigned int ops, void * useraddr, size_t usersize, audit_token_t * token) {
    int result = orig_csops_audittoken(pid, ops, useraddr, usersize, token);
    if (ops == 0) { // CS_OPS_STATUS
        *((uint32_t *)useraddr) |= 0x4000000; // CS_PLATFORM_BINARY
    }
    return result;
}

int hooked_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions,
                        const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {
    int result = orig_posix_spawn(pid, path, file_actions, attrp, argv, envp);
//    FILE *file = fopen("/var/mobile/lunchd.log", "a");
//    if (file) {
//        char output[1024];
//        sprintf(output, "[lunchd] pid %d, path %s\n", *pid, path);
//        fputs(output, file);
//        fclose(file);
//    }
    if (posix_spawnattr_t->)...
    return result;
}


__attribute__((constructor)) static void init(int argc, char **argv) {
    FILE *file;
    file = fopen("/var/mobile/lunchd.log", "w");
    char output[1024];
    sprintf(output, "[lunchd] launchdhook pid %d", getpid());
    printf("[lunchd] launchdhook pid %d", getpid());
    fputs(output, file);
    
    struct rebinding rebindings[] = (struct rebinding[]){
        {"csops", hooked_csops, (void *)&orig_csops},
        {"csops_audittoken", hooked_csops_audittoken, (void *)&orig_csops_audittoken},
        {"posix_spawn", hooked_posix_spawn, (void *)&orig_posix_spawn}
    };
    rebind_symbols(rebindings, sizeof(rebindings)/sizeof(struct rebinding));
}
