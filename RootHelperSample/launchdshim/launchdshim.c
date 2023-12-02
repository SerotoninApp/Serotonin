//
//  launchdshim.c
//  usprebooter
//
//  Created by LL on 2/12/23.
//

#include "launchdshim.h"
#include <spawn.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <limits.h>
#include <sys/types.h>

#define PT_TRACE_ME 0
int ptrace(int, pid_t, caddr_t, int);
extern char** environ;

#define LAUNCHDPATCH_SUFFIX "patchedlaunchd"
#define LAUNCHDHOOK_SUFFIX  "launchdhook.dylib"

int get_boot_manifest_hash(char hash[97])
{
  const UInt8 *bytes;
  CFIndex length;
  io_registry_entry_t chosen = IORegistryEntryFromPath(0, "IODeviceTree:/chosen");
  if (!MACH_PORT_VALID(chosen)) return 1;
  CFDataRef manifestHash = (CFDataRef)IORegistryEntryCreateCFProperty(chosen, CFSTR("boot-manifest-hash"), kCFAllocatorDefault, 0);
  IOObjectRelease(chosen);
  if (manifestHash == NULL || CFGetTypeID(manifestHash) != CFDataGetTypeID())
  {
    if (manifestHash != NULL) CFRelease(manifestHash);
    return 1;
  }
  length = CFDataGetLength(manifestHash);
  bytes = CFDataGetBytePtr(manifestHash);
  for (int i = 0; i < length; i++)
  {
    snprintf(&hash[i * 2], 3, "%02X", bytes[i]);
  }
  CFRelease(manifestHash);
  return 0;
}

int main(int argc, char* argv[]) {
    ptrace(PT_TRACE_ME, 0, NULL, 0);
    char hash[97], launchdHook[PATH_MAX], patchedLaunchd[PATH_MAX];
    int ret = get_boot_manifest_hash(hash);
    if (ret) return -1;
    snprintf(patchedLaunchd, PATH_MAX, "/private/preboot/%s/%s", hash, LAUNCHDPATCH_SUFFIX);
    snprintf(launchdHook, PATH_MAX, "/private/preboot/%s/%s", hash, LAUNCHDHOOK_SUFFIX);
    setenv("DYLD_INSERT_LIBRARIES", launchdHook, 1);
    execve(launchdHook, argv, environ);
    return -1;
}
