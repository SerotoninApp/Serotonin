#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <Foundation/Foundation.h>
#include <bsm/audit.h>
#include <xpc/xpc.h>
#include <stdio.h>
#include "fishhook.h"
#include <spawn.h>
#include <limits.h>
#include <dirent.h>
#include <stdbool.h>
#include <errno.h>
#include <roothide.h>
#include <signal.h>
#include "crashreporter.h"
#import "jbserver/exec_patch.h"
#include "fun/krw.h"
#include "jbserver/info.h"
#include "jbserver/log.h"
#include "xpc_hook.h"

#define PT_DETACH 11    /* stop tracing a process */
#define PT_ATTACHEXC 14 /* attach to running process with signal exception */
#define __probable(x)   __builtin_expect(!!(x), 1)
#define __improbable(x) __builtin_expect(!!(x), 0)

int ptrace(int request, pid_t pid, caddr_t addr, int data);

#define INSTALLD_PATH       "/usr/libexec/installd"
#define NFCD_PATH           "/usr/libexec/nfcd"
#define SPRINGBOARD_PATH    "/System/Library/CoreServices/SpringBoard.app/SpringBoard"
#define MRUI_PATH           "/Applications/MediaRemoteUI.app/MediaRemoteUI"
#define XPCPROXY_PATH       "/usr/libexec/xpcproxy"
#define MEDIASERVERD_PATH   "/usr/sbin/mediaserverd"

void abort_with_reason(uint32_t reason_namespace, uint64_t reason_code, const char *reason_string, uint64_t reason_flags);

#define MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT 6
#define POSIX_SPAWNATTR_OFF_MEMLIMIT_ACTIVE 0x48
#define POSIX_SPAWNATTR_OFF_MEMLIMIT_INACTIVE 0x4C

int posix_spawnattr_set_launch_type_np(posix_spawnattr_t *attr, uint8_t launch_type);
int unsandbox2(const char* dir, const char* file);

int (*orig_csops)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int (*orig_csops_audittoken)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int (*orig_posix_spawn)(pid_t * __restrict pid, const char * __restrict path,
                        const posix_spawn_file_actions_t *file_actions,
                        const posix_spawnattr_t * __restrict attrp,
                        char *const argv[ __restrict], char *const envp[ __restrict]);

int (*orig_posix_spawnp)(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *restrict file_actions, const posix_spawnattr_t *restrict attrp, char *const argv[restrict], char *const envp[restrict]);
xpc_object_t (*xpc_dictionary_get_value_orig)(xpc_object_t xdict, const char *key);
int (*memorystatus_control_orig)(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);
bool (*xpc_dictionary_get_bool_orig)(xpc_object_t dictionary, const char *key);

int hooked_csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize) {
    int result = orig_csops(pid, ops, useraddr, usersize);
    if (result != 0) return result;
    if (ops == 0) { // CS_OPS_STATUS
       *((uint32_t *)useraddr) |= 0x4000001; // CS_PLATFORM_BINARY
    }
    return result;
}

int hooked_csops_audittoken(pid_t pid, unsigned int ops, void * useraddr, size_t usersize, audit_token_t * token) {
    int result = orig_csops_audittoken(pid, ops, useraddr, usersize, token);
    if (result != 0) return result;
    if (ops == 0) { // CS_OPS_STATUS
       *((uint32_t *)useraddr) |= 0x4000001; // CS_PLATFORM_BINARY
    }
    return result;
}

void change_launchtype(const posix_spawnattr_t *attrp, const char *restrict path) {
    const char *prefixes[] = {
        "/private/preboot",
        jbroot(@"/").UTF8String,
    };

    if (__builtin_available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)) {
        for (size_t i = 0; i < sizeof(prefixes) / sizeof(prefixes[0]); ++i) {
            size_t prefix_len = strlen(prefixes[i]);
            if (strncmp(path, prefixes[i], prefix_len) == 0) {
//                FILE *file = fopen("/var/mobile/launchd.log", "a");
                if (/*file &&*/ attrp != 0) {
//                    char output[1024];
//                    sprintf(output, "[launchd] setting launch type path %s from %d to 0\n", path, attrp);
//                    fputs(output, file);
//                    fclose(file);
                    posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0); // needs ios 16.0 sdk
                }
                break;
            }
        }
    }
}

#define JB_ROOT_PREFIX ".jbroot-"
#define JB_RAND_LENGTH  (sizeof(uint64_t)*sizeof(char)*2)
int is_jbrand_value(uint64_t value)
{
   uint8_t check = value>>8 ^ value >> 16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
   return check == (uint8_t)value;
}

int is_jbroot_name(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;
    
    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;
    
    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;
    
    if(!is_jbrand_value(value))
        return 0;
    
    return 1;
}

NSString* find_jbroot()
{
    //jbroot path may change when re-randomize it
    NSString * jbroot = nil;
    NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
    for (NSString *subItem in subItems) {
        if (is_jbroot_name(subItem.UTF8String))
        {
            NSString* path = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
            jbroot = path;
            break;
        }
    }
    return jbroot;
}

int hooked_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, posix_spawnattr_t *attrp, char *argv[], char *const envp[]) {
    change_launchtype(attrp, path);
    // crashreporter_pause();
    int r = orig_posix_spawn(pid, path, file_actions, attrp, argv, envp);
    // crashreporter_resume();
    return r;
}

// void log_path(char* path, char* jbroot_path) {
//     FILE *file = fopen("/var/mobile/launchd.log", "a");
//     char output[256];
//     sprintf(output, "[launchd] changing path %s to %s\n", path, jbroot_path);
//     fputs(output, file);
//     fclose(file);
// }
char HOOK_DYLIB_PATH[PATH_MAX] = {0};
bool shouldWeGamble = true;
int hooked_posix_spawnp(pid_t *restrict pid, const char *restrict path, const posix_spawn_file_actions_t *restrict file_actions, posix_spawnattr_t *attrp, char *argv[restrict], char *const envp[restrict]) {
    change_launchtype(attrp, path);
    if (!strncmp(path, SPRINGBOARD_PATH, strlen(SPRINGBOARD_PATH))) {
        // log_path(path, jbroot(SPRINGBOARD_PATH));
        path = jbroot(SPRINGBOARD_PATH);
        argv[0] = (char *)path;
        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
        return posix_spawnp(pid, path, file_actions, (posix_spawnattr_t *)attrp, argv, envp);
    } else if (!strncmp(path, MRUI_PATH, strlen(MRUI_PATH))) {
        // log_path(path, jbroot(MRUI_PATH));
        path = jbroot(MRUI_PATH);
        argv[0] = (char *)path;
        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
    } else if (__probable(!strncmp(path, XPCPROXY_PATH, strlen(XPCPROXY_PATH)))) {
        path = jbroot(XPCPROXY_PATH);
        argv[0] = (char *)path;
        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
        if(__improbable(shouldWeGamble))
        {
            uint64_t kfd = do_kopen(1024, 2, 1, 1, 1000, true);
            // customLog("successfully gambled with kfd!\n");
            customLog("slide: 0x%llx\n, kernproc: 0x%llx\n, kerntask: 0x%llx, nchashtbl: 0x%llx, nchashmask: 0x%llx\n", get_kslide(), get_kernproc(), get_kerntask(), gSystemInfo.kernelConstant.nchashtbl, gSystemInfo.kernelConstant.nchashmask);
            // customLog("reading pid... %d, getpid ret %d", kread32(((struct kfd *)kfd)->info.kaddr.current_proc + 0x60), getpid());
            // unsandbox2("/usr/lib", jbroot("/usr/lib/libhooker.dylib"));
            unsandbox2("/usr/lib", jbroot("/generalhooksigned.dylib"));
            //new "real path"
            snprintf(HOOK_DYLIB_PATH, sizeof(HOOK_DYLIB_PATH), "/usr/lib/generalhooksigned.dylib");
            // do_kclose();
            shouldWeGamble = false;
        }
    //    } else if (!strncmp(path, MEDIASERVERD_PATH, strlen(MEDIASERVERD_PATH))) {
    //        log_path(path, jbroot(MEDIASERVERD_PATH));
    //        path = jbroot(MEDIASERVERD_PATH);
    //        argv[0] = (char *)path;
    //        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
    //    }
    //    } else if (!strncmp(path, installd, strlen(installd))) {
    //        path = jbroot(installd);
    //        argv[0] = (char *)path;
    //        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
    //    }
    //    } else if (!strncmp(path, nfcd, strlen(nfcd))) {
    //        path = jbroot(nfcd);
    //        argv[0] = (char *)path;
    //        posix_spawnattr_set_launch_type_np((posix_spawnattr_t *)attrp, 0);
    }
    return orig_posix_spawnp(pid, path, file_actions, (posix_spawnattr_t *)attrp, argv, envp);
}


bool (*xpc_dictionary_get_bool_orig)(xpc_object_t dictionary, const char *key);
bool hook_xpc_dictionary_get_bool(xpc_object_t dictionary, const char *key) {
    if (!strcmp(key, "LogPerformanceStatistics")) return true;
    else return xpc_dictionary_get_bool_orig(dictionary, key);
}

xpc_object_t hook_xpc_dictionary_get_value(xpc_object_t dict, const char *key) {
    xpc_object_t retval = xpc_dictionary_get_value_orig(dict, key);

    if (strcmp(key, "Paths") == 0) {
        const char *paths[] = {
            jbroot("/Library/LaunchDaemons"),
            jbroot("/System/Library/LaunchDaemons"),
            jbroot("/Library/LaunchAgents"),
            jbroot("/System/Library/LaunchAgents"),
        };

        for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
            xpc_array_append_value(retval, xpc_string_create(paths[i]));
        }
    }

    return retval;
}

int memorystatus_control_hook(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize)
{
    if (command == MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT) {
        return 0;
    }
    return memorystatus_control_orig(command, pid, flags, buffer, buffersize);
}

__attribute__((constructor)) static void init(int argc, char **argv) {
    // APPARENTLY for no reason, this crashreporter fuckin breaks ptrace in bootstrapd??
    // crashreporter_start();
    // customLog("launchdhook is running");
    if(gSystemInfo.jailbreakInfo.rootPath) free(gSystemInfo.jailbreakInfo.rootPath);
    
    NSString* jbroot_path = find_jbroot();
    if(jbroot_path) {
        gSystemInfo.jailbreakInfo.rootPath = strdup(jbroot_path.fileSystemRepresentation);
        gSystemInfo.jailbreakInfo.jbrand = jbrand();
    }
    initXPCHooks();
	setenv("DYLD_INSERT_LIBRARIES", jbroot("/launchdhook.dylib"), 1);
	setenv("LAUNCHD_UUID", [NSUUID UUID].UUIDString.UTF8String, 1);

    // If Dopamine was initialized before, we assume we're coming from a userspace reboot
	// Stock bug: These prefs wipe themselves after a reboot (they contain a boot time and this is matched when they're loaded)
	// But on userspace reboots, they apparently do not get wiped as boot time doesn't change
	// We could try to change the boot time ourselves, but I'm worried of potential side effects
	// So we just wipe the offending preferences ourselves
	// In practice this fixes nano launch daemons not being loaded after the userspace reboot, resulting in certain apple watch features breaking
	if (!access("/var/mobile/Library/Preferences/com.apple.NanoRegistry.NRRootCommander.volatile.plist", W_OK)) {
		remove("/var/mobile/Library/Preferences/com.apple.NanoRegistry.NRRootCommander.volatile.plist");
	}
	if (!access("/var/mobile/Library/Preferences/com.apple.NanoRegistry.NRLaunchNotificationController.volatile.plist", W_OK)) {
		remove("/var/mobile/Library/Preferences/com.apple.NanoRegistry.NRLaunchNotificationController.volatile.plist");
	}
    struct rebinding rebindings[] = (struct rebinding[]){
        {"csops", hooked_csops, (void *)&orig_csops},
        {"csops_audittoken", hooked_csops_audittoken, (void *)&orig_csops_audittoken},
        {"posix_spawnp", hooked_posix_spawnp, (void *)&orig_posix_spawnp},
        {"xpc_dictionary_get_bool", hook_xpc_dictionary_get_bool, (void *)&xpc_dictionary_get_bool_orig},
        {"xpc_dictionary_get_value", hook_xpc_dictionary_get_value, (void *)&xpc_dictionary_get_value_orig},
        {"memorystatus_control", memorystatus_control_hook, (void *)&memorystatus_control_orig},
    };
    rebind_symbols(rebindings, sizeof(rebindings)/sizeof(struct rebinding));
}
