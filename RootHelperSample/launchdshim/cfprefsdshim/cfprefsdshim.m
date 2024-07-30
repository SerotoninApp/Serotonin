#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <substrate.h>
#include <libhooker/libhooker.h>
#include <spawn.h>
#include <unistd.h>
#include <signal.h>
#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <objc/runtime.h>
#include <sys/param.h>
#include <libgen.h>
#include "../../jbroot.h"
// #include <roothide.h>
// from nathanlr - thanks nathan

int (*orig_csops)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int (*orig_csops_audittoken)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int csops_audittoken(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

int hooked_csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize) {
    int result = orig_csops(pid, ops, useraddr, usersize);
    if (result != 0) return result;
    if (ops == 0) {
       *((uint32_t *)useraddr) |= 0x4000001;
    }
    return result;
}

int hooked_csops_audittoken(pid_t pid, unsigned int ops, void * useraddr, size_t usersize, audit_token_t * token) {
    int result = orig_csops_audittoken(pid, ops, useraddr, usersize, token);
    if (result != 0) return result;
    if (ops == 0) {
       *((uint32_t *)useraddr) |= 0x4000001;
    }
    return result;
}

BOOL preferencePlistNeedsRedirection(NSString *plistPath)
{
    if ([plistPath hasPrefix:@"/private/var/mobile/Containers"] || [plistPath hasPrefix:@"/var/db"] || [plistPath hasPrefix:jbrootobjc(@"/")]) return NO;

    NSString *plistName = plistPath.lastPathComponent;

    if ([plistName hasPrefix:@"com.apple."] || [plistName hasPrefix:@"systemgroup.com.apple."] || [plistName hasPrefix:@"group.com.apple."]) return NO;

    NSArray *additionalSystemPlistNames = @[
        @".GlobalPreferences.plist",
        @".GlobalPreferences_m.plist",
        @"bluetoothaudiod.plist",
        @"NetworkInterfaces.plist",
        @"OSThermalStatus.plist",
        @"preferences.plist",
        @"osanalyticshelper.plist",
        @"UserEventAgent.plist",
        @"wifid.plist",
        @"dprivacyd.plist",
        @"silhouette.plist",
        @"nfcd.plist",
        @"kNPProgressTrackerDomain.plist",
        @"siriknowledged.plist",
        @"UITextInputContextIdentifiers.plist",
        @"mobile_storage_proxy.plist",
        @"splashboardd.plist",
        @"mobile_installation_proxy.plist",
        @"languageassetd.plist",
        @"ptpcamerad.plist",
        @"com.google.gmp.measurement.monitor.plist",
        @"com.google.gmp.measurement.plist",
        @"APMExperimentSuiteName.plist",
        @"APMAnalyticsSuiteName.plist",
        @"com.tigisoftware.Filza.plist",
        @"com.serena.Antoine.plist",
        @"org.coolstar.SileoStore.plist",
    ];

    return ![additionalSystemPlistNames containsObject:plistName];
}

bool (*orig_CFPrefsGetPathForTriplet)(CFStringRef, CFStringRef, bool, CFStringRef, char*);
bool new_CFPrefsGetPathForTriplet(CFStringRef bundleIdentifier, CFStringRef user, bool byHost, CFStringRef path, char *buffer) {
    bool orig = orig_CFPrefsGetPathForTriplet(bundleIdentifier, user, byHost, path, buffer);
    if(orig && buffer && !access(jbroot("/"), F_OK))
    {
        NSString* origPath = [NSString stringWithUTF8String:(char*)buffer];
        BOOL needsRedirection = preferencePlistNeedsRedirection(origPath);
        if (needsRedirection) {
            //NSLog(@"Plist redirected to /var/jb: %@", origPath);
            strcpy((char*)buffer, jbroot("/"));
            strcat((char*)buffer, origPath.UTF8String);
        }
    }

    return orig;
}

int (*__CFXPreferencesDaemon_main)(int argc, char *argv[], char *envp[], char* apple[]);
int ptrace(int request, pid_t pid, caddr_t addr, int data);

int main(int argc, char *argv[], char *envp[], char* apple[]) {
    @autoreleasepool {
//        NSLog(@"cfprefsdshim loaded"); /
        if (argc > 1 && strcmp(argv[1], "--jit") == 0) {
//            NSLog(@"cfprefsdshim jit 1");
            ptrace(0, 0, 0, 0);
            exit(0);
        } else {
            pid_t pid;
            char *modified_argv[] = {argv[0], "--jit", NULL };
            int ret = posix_spawnp(&pid, argv[0], NULL, NULL, modified_argv, envp);
            if (ret == 0) {
//                NSLog(@"cfprefsdshim jit 2");
                waitpid(pid, NULL, WUNTRACED);
                ptrace(11, pid, 0, 0);
                kill(pid, SIGTERM);
                wait(NULL);
            }
        }
        
        MSImageRef coreFoundationImage = MSGetImageByName("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation");
        void* CFPrefsGetPathForTriplet_ptr = MSFindSymbol(coreFoundationImage, "__CFPrefsGetPathForTriplet");
        
        const struct LHFunctionHook hooks[] = {
            {(void *)csops, (void *)hooked_csops, (void *)&orig_csops, 0},
            {(void *)csops_audittoken, (void *)hooked_csops_audittoken, (void *)&orig_csops_audittoken, 0},
            {CFPrefsGetPathForTriplet_ptr, (void *)new_CFPrefsGetPathForTriplet, (void *)&orig_CFPrefsGetPathForTriplet, 0},
        };
            
        LHHookFunctions(hooks, 3);
        void *handle = dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", RTLD_GLOBAL);
        __CFXPreferencesDaemon_main = dlsym(handle, "__CFXPreferencesDaemon_main");
//        NSLog(@"cfprefsdshim starting...");
        return __CFXPreferencesDaemon_main(argc, argv, envp, apple);
    }
}
