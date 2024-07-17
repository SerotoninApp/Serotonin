#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <Foundation/Foundation.h>
#include <bsm/audit.h>
#include <xpc/xpc.h>
#include <stdio.h>
//#include "fishhook.h"
#include <libhooker/libhooker.h>
#include <spawn.h>
#include <limits.h>
#include <dirent.h>
#include <stdbool.h>
#include <errno.h>
#include <dlfcn.h>
#include <roothide.h>
#include <signal.h>
#include "utils.h"

#define PT_DETACH 11    /* stop tracing a process */
#define PT_ATTACHEXC 14 /* attach to running process with signal exception */

int ptrace(int request, pid_t pid, caddr_t addr, int data);
int (*orig_csops)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int (*orig_csops_audittoken)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);

@interface NSBundle(private)
- (id)_cfBundle;
@end

@implementation NSBundle (Loaded)

- (BOOL)isLoaded {
    return YES;
}

@end

static void overwriteMainCFBundle() {
    // Overwrite CFBundleGetMainBundle
    uint32_t *pc = (uint32_t *)CFBundleGetMainBundle;
    void **mainBundleAddr = 0;
    while (true) {
        uint64_t addr = aarch64_get_tbnz_jump_address(*pc, (uint64_t)pc);
        if (addr) {
            // adrp <- pc-1
            // tbnz <- pc
            // ...
            // ldr  <- addr
            mainBundleAddr = (void **)aarch64_emulate_adrp_ldr(*(pc-1), *(uint32_t *)addr, (uint64_t)(pc-1));
            break;
        }
        ++pc;
    }
//    assert(mainBundleAddr != NULL);
    *mainBundleAddr = (__bridge void *)NSBundle.mainBundle._cfBundle;
}

static void overwriteMainNSBundle(NSBundle *newBundle) {
    // Overwrite NSBundle.mainBundle
    // iOS 16: x19 is _MergedGlobals
    // iOS 17: x19 is _MergedGlobals+4

    NSString *oldPath = NSBundle.mainBundle.executablePath;
    uint32_t *mainBundleImpl = (uint32_t *)method_getImplementation(class_getClassMethod(NSBundle.class, @selector(mainBundle)));
    for (int i = 0; i < 20; i++) {
        void **_MergedGlobals = (void **)aarch64_emulate_adrp_add(mainBundleImpl[i], mainBundleImpl[i+1], (uint64_t)&mainBundleImpl[i]);
        if (!_MergedGlobals) continue;

        // In iOS 17, adrp+add gives _MergedGlobals+4, so it uses ldur instruction instead of ldr
        if ((mainBundleImpl[i+4] & 0xFF000000) == 0xF8000000) {
            uint64_t ptr = (uint64_t)_MergedGlobals - 4;
            _MergedGlobals = (void **)ptr;
        }

        for (int mgIdx = 0; mgIdx < 20; mgIdx++) {
            if (_MergedGlobals[mgIdx] == (__bridge void *)NSBundle.mainBundle) {
                _MergedGlobals[mgIdx] = (__bridge void *)newBundle;
                break;
            }
        }
    }

//    assert(![NSBundle.mainBundle.executablePath isEqualToString:oldPath]);
}

int (*orig_csops)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int (*orig_csops_audittoken)(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
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

void setupAppBundle(const char *fullPath) {
    NSString *bundlePath = [NSString stringWithUTF8String:fullPath];
    NSBundle *appBundle = [[NSBundle alloc] initWithPath:bundlePath];
    
    overwriteMainNSBundle(appBundle);
    overwriteMainCFBundle();
    
    NSMutableArray<NSString *> *objcArgv = NSProcessInfo.processInfo.arguments.mutableCopy;
    objcArgv[0] = appBundle.executablePath;
    [NSProcessInfo.processInfo performSelector:@selector(setArguments:) withObject:objcArgv];
    NSProcessInfo.processInfo.processName = appBundle.infoDictionary[@"CFBundleExecutable"];
    *_CFGetProgname() = NSProcessInfo.processInfo.processName.UTF8String;
}

int csops_audittoken(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

__attribute__((constructor)) static void init(int argc, char **argv, char *envp[]) {
    @autoreleasepool {
        if (argc > 1 && strcmp(argv[1], "--jit") == 0) {
//            NSLog(@"generalhook - jitting");
            ptrace(0, 0, 0, 0);
            exit(0);
        } else {
            pid_t pid;
            char *modified_argv[] = {argv[0], "--jit", NULL };
            int ret = posix_spawnp(&pid, argv[0], NULL, NULL, modified_argv, envp);
            if (ret == 0) {
//                NSLog(@"generalhook - jitting 2");
                waitpid(pid, NULL, WUNTRACED);
                ptrace(11, pid, 0, 0);
                kill(pid, SIGTERM);
                wait(NULL);
            }
        }
    }
//    struct rebinding rebindings[] = (struct rebinding[]){
//        {"csops", hooked_csops, (void *)&orig_csops},
//        {"csops_audittoken", hooked_csops_audittoken, (void *)&orig_csops_audittoken},
//    };
//    rebind_symbols(rebindings, sizeof(rebindings)/sizeof(struct rebinding));... apparently fishhook doesnt fucking work?
    const struct LHFunctionHook hooks[] = {
        {(void *)csops, (void *)hooked_csops, (void *)&orig_csops, 0},
        {(void *)csops_audittoken, (void *)hooked_csops_audittoken, (void *)&orig_csops_audittoken, 0}
    };
    LHHookFunctions(hooks, 2);

    const char *appPaths[] = {
        "/System/Library/CoreServices/SpringBoard.app/SpringBoard",
        "/Applications/CarPlayWallpaper.app/CarPlayWallpaper",
        "/Applications/MobileSMS.app/MobileSMS",
        "/Applications/MediaRemoteUI.app/MediaRemoteUI",
        "/Applications/MobilePhone.app/MobilePhone",
        "/Applications/SharingViewService.app/SharingViewService",
        "/Applications/InCallService.app/InCallService"
    };
    for (int i = 0; i < sizeof(appPaths) / sizeof(appPaths[0]); i++) {
        if (strcmp(argv[0], appPaths[i]) == 0) {
            setupAppBundle(appPaths[i]);
            break;
        }
    }
    NSLog(@"generalhook - loading tweaks for pid %d", getpid());
    dlopen(jbroot(@"/basebin/bootstrap.dylib").UTF8String, RTLD_GLOBAL | RTLD_NOW);
}
