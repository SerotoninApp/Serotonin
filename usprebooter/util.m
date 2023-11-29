//
//  util.m
//  usprebooter
//
//  Created by LL on 29/11/23.
//

#import <Foundation/Foundation.h>
#import "util.h"
#import <spawn.h>
#import <copyfile.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import "roothelper.h"
NSString *getExecutablePath(void)
{
    uint32_t len = PATH_MAX;
    char selfPath[len];
    _NSGetExecutablePath(selfPath, &len);
    NSLog(@"executable path: %@", [NSString stringWithUTF8String:selfPath]);
    return [NSString stringWithUTF8String:selfPath];
}

int respawnSelf(NSArray* args) {
    spawnRoot(getExecutablePath(), args, nil, nil);
    return 0;
}
void enumerateProcessesUsingBlock(void (^enumerator)(pid_t pid, NSString* executablePath, BOOL* stop))
{
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    uint64_t count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            NSString* executablePath = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
            
            BOOL stop = NO;
            enumerator(pid, executablePath, &stop);
            if(stop)
            {
                free(buffer);
                break;
            }
        }
        free(buffer);
        }
    }
    free(info);
}

void killall(NSString* processName, BOOL softly)
{
    enumerateProcessesUsingBlock(^(pid_t pid, NSString* executablePath, BOOL* stop)
    {
        if([executablePath.lastPathComponent isEqualToString:processName])
        {
            if(softly)
            {
                kill(pid, SIGTERM);
            }
            else
            {
                kill(pid, SIGKILL);
            }
        }
    });
}

void respring(void)
{
    killall(@"SpringBoard", YES);
    exit(0);
}

