#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <Foundation/Foundation.h>
#include <bsm/audit.h>
#include <xpc/xpc.h>
#include <stdio.h>
//#include "fishhook.h"
// #include <libhooker/libhooker.h> // no ellekit! because we may be in /usr/lib from unsandbox hax
#include <spawn.h>
#include <limits.h>
#include <dirent.h>
#include <stdbool.h>
#include <errno.h>
#include <dlfcn.h>
// #include <roothide.h>
#include <signal.h>
#include "utils.h"
#include "codesign.h"
#include "litehook.h"
#include "jbroot.h"
#include "sandbox.h"
#include "../launchdhook/jbserver/jbclient_xpc.h"

#define PT_DETACH 11    /* stop tracing a process */
#define PT_ATTACHEXC 14 /* attach to running process with signal exception */
#define SYSCALL_CSOPS 0xA9
#define SYSCALL_CSOPS_AUDITTOKEN 0xAA

bool gFullyDebugged = false;

int ptrace(int request, pid_t pid, caddr_t addr, int data);
int csops_audittoken(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize, audit_token_t * token);
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

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

// skidding from Dopamine
// For the userland, there are multiple processes that will check CS_VALID for one reason or another
// As we inject system wide (or at least almost system wide), we can just patch the source of the info though - csops itself
// Additionally we also remove CS_DEBUGGED while we're at it, as on arm64e this also is not set and everything is fine
// That way we have unified behaviour between both arm64 and arm64e

int csops_hook(pid_t pid, unsigned int ops, void *useraddr, size_t usersize)
{
	int rv = syscall(SYSCALL_CSOPS, pid, ops, useraddr, usersize);
	if (rv != 0) return rv;
	if (ops == CS_OPS_STATUS) {
		if (useraddr && usersize == sizeof(uint32_t)) {
			uint32_t* csflag = (uint32_t *)useraddr;
			*csflag |= CS_VALID;
            *csflag |= CS_PLATFORM_BINARY;
			*csflag &= ~CS_DEBUGGED;
			// if (pid == getpid() && gFullyDebugged) {
			// 	*csflag |= CS_DEBUGGED;
			// }
		}
	}
	return rv;
}

int csops_audittoken_hook(pid_t pid, unsigned int ops, void *useraddr, size_t usersize, audit_token_t *token)
{
	int rv = syscall(SYSCALL_CSOPS_AUDITTOKEN, pid, ops, useraddr, usersize, token);
	if (rv != 0) return rv;
	if (ops == CS_OPS_STATUS) {
		if (useraddr && usersize == sizeof(uint32_t)) {
			uint32_t* csflag = (uint32_t *)useraddr;
			*csflag |= CS_VALID;
            *csflag |= CS_PLATFORM_BINARY;
			*csflag &= ~CS_DEBUGGED;
			// if (pid == getpid() && gFullyDebugged) {
			// 	*csflag |= CS_DEBUGGED;
			// }
		}
	}
	return rv;
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

static char *JB_SandboxExtensions = NULL;
void applySandboxExtensions(void)
{
	if (JB_SandboxExtensions) {
		char *JB_SandboxExtensions_dup = strdup(JB_SandboxExtensions);
		char *extension = strtok(JB_SandboxExtensions_dup, "|");
		while (extension != NULL) {
            // NSLog(@"generalhook - consuming extension %s", extension);
			sandbox_extension_consume(extension);
			extension = strtok(NULL, "|");
		}
		free(JB_SandboxExtensions_dup);
	} else {
        NSLog(@"generalhook - no jb sandbox extensions?");
    }
}

__attribute__((constructor)) static void init(int argc, char **argv, char *envp[]) {
    // @autoreleasepool {
    //     if (argc > 1 && strcmp(argv[1], "--jit") == 0) {
    //         ptrace(0, 0, 0, 0);
    //         exit(0);
    //     } else {
    //         pid_t pid;
    //         char *modified_argv[] = {argv[0], "--jit", NULL };
    //         int ret = posix_spawnp(&pid, argv[0], NULL, NULL, modified_argv, envp);
    //         if (ret == 0) {
    //             waitpid(pid, NULL, WUNTRACED);
    //             ptrace(11, pid, 0, 0);
    //             kill(pid, SIGTERM);
    //             wait(NULL);
    //         }
    //     }
    // }
    // jits for me
    int checkinret = jbclient_process_checkin(NULL, NULL, &JB_SandboxExtensions, &gFullyDebugged);
    // if (checkinret == -1) {
    //     NSLog(@"generalhook - jbserver no response?");
    //     goto finish;
    // } else {
    //     NSLog(@"generalhook - checkin ret %d", checkinret);
    // }
    applySandboxExtensions();
    // crashes here unless you ptrace yourself?!
    litehook_hook_function(csops, csops_hook);
	litehook_hook_function(csops_audittoken, csops_audittoken_hook);

    const char *appPaths[] = {
        "/System/Library/CoreServices/SpringBoard.app/SpringBoard",
        "/Applications/CarPlayWallpaper.app/CarPlayWallpaper",
        "/Applications/MobileSMS.app/MobileSMS",
        "/Applications/MediaRemoteUI.app/MediaRemoteUI",
        "/Applications/MobilePhone.app/MobilePhone",
        "/Applications/SharingViewService.app/SharingViewService",
        "/Applications/InCallService.app/InCallService",
        "/usr/libexec/installd",
    };
    for (int i = 0; i < sizeof(appPaths) / sizeof(appPaths[0]); i++) {
        if (strcmp(argv[0], appPaths[i]) == 0) {
            setupAppBundle(appPaths[i]);
            break;
        }
    }
    NSLog(@"generalhook - loading tweaks for pid %d", getpid());
    // dlopen([jbroot(@"/usr/lib/roothideinit.dylib") UTF8String], RTLD_NOW);
    // dlopen([jbroot(@"/usr/lib/roothidepatch.dylib") UTF8String], RTLD_NOW);
	const char* oldJBROOT = getenv("JBROOT");
	setenv("JBROOT", [jbroot(@"/") UTF8String], 1);
	dlopen([jbroot(@"/usr/lib/TweakLoader.dylib") UTF8String], RTLD_NOW);
	if(oldJBROOT) setenv("JBROOT", oldJBROOT, 1); else unsetenv("JBROOT");
    // dlopen(jbroot(@"/basebin/bootstrap.dylib").UTF8String, RTLD_GLOBAL | RTLD_NOW);
}
