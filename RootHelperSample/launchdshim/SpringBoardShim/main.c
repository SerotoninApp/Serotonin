#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

int (*SBSystemAppMain)(int argc, char *argv[], char *envp[], char* apple[]);

int main(int argc, char *argv[], char *envp[], char* apple[]) {
    void *handle = dlopen("/System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard", RTLD_GLOBAL);
    SBSystemAppMain = dlsym(handle, "SBSystemAppMain");
    return SBSystemAppMain(argc, argv, envp, apple);
}

