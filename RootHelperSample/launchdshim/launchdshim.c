//
//  launchdshim.c
//  usprebooter
//
//  Created by LL on 2/12/23.
// thanks nick chan

#include "launchdshim.h"
#include <spawn.h>
#include <unistd.h>
#include <stdio.h>
#include <limits.h>
#include <sys/types.h>

extern char** environ;

#define LAUNCHDPATCH_SUFFIX "patchedlaunchd"
//#define LAUNCHDHOOK_SUFFIX  "launchdhook.dylib"

int main(int argc, char* argv[]) {
    char launchdHook[PATH_MAX], patchedLaunchd[PATH_MAX];
    FILE *fp;
    fp = fopen ("/var/mobile/launchd.txt", "w");
    char output[100];
    sprintf(output, "hello from shim, this was running from pid %d", getpid());
    fputs(output, fp);
    fclose(fp);
    sync();
    sprintf(patchedLaunchd, PATH_MAX, "/var/jb/launchd");
//    snprintf(launchdHook, PATH_MAX, "/private/preboot/%s/%s", hash, LAUNCHDHOOK_SUFFIX);
//    setenv("DYLD_INSERT_LIBRARIES", launchdHook, 1);

//    pid_t pid = fork();
//    execve("/sbin/launchd", argv, environ);
    execve(patchedLaunchd, argv, environ);
    return -1;
//    exit(42);
}
