#include <unistd.h>
#include <stdio.h>
#include <dlfcn.h>
#include <dirent.h>
#include <roothide.h>

bool OpenedTweaks = false;

bool os_variant_has_internal_content(const char* subsystem);
%hookf(bool, os_variant_has_internal_content, const char* subsystem) {
    DIR *dir;
    struct dirent *ent;
    if (OpenedTweaks == false) {
        const char* path = "/var/jb/Library/MobileSubstrate/DynamicLibraries";
        if ((dir = opendir(path)) != NULL) {
            while ((ent = readdir(dir)) != NULL) {
                if (ent->d_type == DT_REG && strstr(ent->d_name, ".dylib")) {
                    char filePath[256];
                    snprintf(filePath, sizeof(filePath), "%s/%s", path, ent->d_name);
                    dlopen(filePath, RTLD_NOW | RTLD_GLOBAL);
                }
            }
            OpenedTweaks = true;
            closedir(dir);
        } else {
            perror("Error opening directory");
        }
        dlopen(jbroot(@"/basebin/bootstrap.dylib").UTF8String, RTLD_GLOBAL | RTLD_NOW);
    }
    return true;
}

#define CS_DEBUGGED 0x10000000
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);
int fork();
int ptrace(int, int, int, int);
int isJITEnabled() {
    int flags;
    csops(getpid(), 0, &flags, sizeof(flags));
    return (flags & CS_DEBUGGED) != 0;
}

%ctor {
    if (!isJITEnabled()) {
        // Enable JIT
        int pid = fork();
        if (pid == 0) {
            ptrace(0, 0, 0, 0);
            exit(0);
        } else if (pid > 0) {
            while (wait(NULL) > 0) {
                usleep(1000);
            }
        }
    }
}
