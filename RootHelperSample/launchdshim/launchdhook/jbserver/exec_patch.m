//
// Created by Ylarod on 2024/3/15.
//

#include "exec_patch.h"
#import <Foundation/Foundation.h>

#import "log.h"
#import "kernel.h"
#import "util.h"

BOOL gSpawnExecPatchTimerSuspend;
dispatch_queue_t gSpawnExecPatchQueue = nil;
NSMutableDictionary *gSpawnExecPatchArray = nil;

void spawnExecPatchTimer() {
    @autoreleasepool {

        for (NSNumber *processId in [gSpawnExecPatchArray copy]) {

            pid_t pid = [processId intValue];
            bool should_resume = [gSpawnExecPatchArray[processId] boolValue];

            bool paused = false;
            if (proc_paused(pid, &paused) != 0) {
                JBLogDebug("spawnExecPatch: invalid pid: %d, total=%d", pid, gSpawnExecPatchArray.count);
                [gSpawnExecPatchArray removeObjectForKey:processId];
                continue;
            } else if (paused) {
                JBLogDebug("spawnExecPatch: patch for process: %d resume=%d, total=%d", pid, should_resume,
                           gSpawnExecPatchArray.count);
                proc_csflags_patch(pid);
                if (should_resume) {
                    JBLogDebug("spawnExecPatch: resume process: %d", pid);
                    kill(pid, SIGCONT);
                }
                [gSpawnExecPatchArray removeObjectForKey:processId];
                continue;
            }
        }
        if (gSpawnExecPatchArray.count) {
            dispatch_async(gSpawnExecPatchQueue, ^{ spawnExecPatchTimer(); });
            usleep(5 * 1000);
        } else {
            gSpawnExecPatchTimerSuspend = YES;
        }

    }
}

void initSpawnExecPatch() {
    gSpawnExecPatchArray = [[NSMutableDictionary alloc] init];
    gSpawnExecPatchQueue = dispatch_queue_create("spawnExecPatchQueue", DISPATCH_QUEUE_SERIAL);
    gSpawnExecPatchTimerSuspend = YES;
}

void patchExecAdd(int callerPid, const char *exec_path, bool resume) {
    JBLogDebug("spawnExecPatch: add exec patch: %d %s resume=%d", callerPid, exec_path, resume);
    dispatch_async(gSpawnExecPatchQueue, ^{
        [gSpawnExecPatchArray setObject:@(resume) forKey:@(callerPid)];
        if (gSpawnExecPatchTimerSuspend) {
            JBLogDebug("spawnExecPatch: wakeup spawnExecPatchTimer...");
            dispatch_async(gSpawnExecPatchQueue, ^{ spawnExecPatchTimer(); });
            gSpawnExecPatchTimerSuspend = NO;
        }
    });
}

void patchExecDel(int callerPid, const char *exec_path) {
    JBLogDebug("spawnExecPatch: del exec patch: %d %s", callerPid, exec_path);
    dispatch_async(gSpawnExecPatchQueue, ^{
        [gSpawnExecPatchArray removeObjectForKey:@(callerPid)];
    });
}