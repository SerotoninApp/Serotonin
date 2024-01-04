#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

int (*SBSystemAppMain)(int argc, char *argv[], char *envp[], char* apple[]);

void loadDynamicLibraries(const char *directory) {
    DIR *dir;
    struct dirent *ent;

    if ((dir = opendir(directory)) != NULL) {
        while ((ent = readdir(dir)) != NULL) {
            if (ent->d_type == DT_REG && strstr(ent->d_name, ".dylib")) {
                char filePath[256];
                snprintf(filePath, sizeof(filePath), "%s/%s", directory, ent->d_name);
                dlopen(filePath, RTLD_LAZY | RTLD_GLOBAL);
            }
        }
        closedir(dir);
    } else {
        perror("Error opening directory");
    }
}

int main(int argc, char *argv[], char *envp[], char* apple[]) {
    void *handle = dlopen("/System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard", RTLD_GLOBAL);
//    loadDynamicLibraries("/var/jb/Library/MobileSubstrate/DynamicLibraries");
    SBSystemAppMain = dlsym(handle, "SBSystemAppMain");
    return SBSystemAppMain(argc, argv, envp, apple);
}

