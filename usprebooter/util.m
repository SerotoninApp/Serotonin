//
//  util.m
//  usprebooter
//
//  Created by LL on 29/11/23.
//

#import <Foundation/Foundation.h>
#import "util.h"
#import <spawn.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>

NSString *getExecutablePath(void)
{
    uint32_t len = PATH_MAX;
    char selfPath[len];
    _NSGetExecutablePath(selfPath, &len);
    NSLog(@"executable path: %@", [NSString stringWithUTF8String:selfPath]);
    return [NSString stringWithUTF8String:selfPath];
}

int fd_is_valid(int fd)
{
    return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}

NSString* getNSStringFromFile(int fd)
{
    NSMutableString* ms = [NSMutableString new];
    ssize_t num_read;
    char c;
    if(!fd_is_valid(fd)) return @"";
    while((num_read = read(fd, &c, sizeof(c))))
    {
        [ms appendString:[NSString stringWithFormat:@"%c", c]];
        if(c == '\n') break;
    }
    return ms.copy;
}

void printMultilineNSString(NSString* stringToPrint)
{
    NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
    NSArray* lines = [stringToPrint componentsSeparatedByCharactersInSet:separator];
    for(NSString* line in lines)
    {
        NSLog(@"%@", line);
    }
}

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1

int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
#if TARGET_OS_SIMULATOR
    return 0;
#else
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path.lastPathComponent atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outErr[2];
    if(stdErr)
    {
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }

    int out[2];
    if(stdOut)
    {
        pipe(out);
        posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, out[0]);
    }
    
    pid_t task_pid;
    int status = -200;
    int spawnError = posix_spawn(&task_pid, [path UTF8String], &action, &attr, (char* const*)argsC, NULL);
    posix_spawnattr_destroy(&attr);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    if(spawnError != 0)
    {
        NSLog(@"We down");
        NSLog(@"posix_spawn error %d\n", spawnError);
        return spawnError;
    }

    do
    {
        pid_t waitpids = waitpid(task_pid, &status, 0);
        if (waitpids != -1) {
//            NSLog(@"Child status %d", WEXITSTATUS(status));
        } else
        {
//            perror("waitpid");
//            NSLog(@"waitpid returned %@", waitpids);
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    if(stdOut)
    {
        close(out[1]);
        NSString* output = getNSStringFromFile(out[0]);
        *stdOut = output;
    }

    if(stdErr)
    {
        close(outErr[1]);
        NSString* errorOutput = getNSStringFromFile(outErr[0]);
        *stdErr = errorOutput;
    }
//    NSLog(@"%@", status);
    return WEXITSTATUS(status);
#endif
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
#define JB_ROOT_PREFIX ".jbroot-"
#define JB_RAND_LENGTH  (sizeof(uint64_t)*sizeof(char)*2)

int is_jbrand_value(uint64_t value)
{
   uint8_t check = value>>8 ^ value >> 16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
   return check == (uint8_t)value;
}

int is_jbroot_name(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;
    
    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;
    
    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;
    
    if(!is_jbrand_value(value))
        return 0;
    
    return 1;
}

uint64_t resolve_jbrand_value(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;
    
    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;
    
    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;
    
    if(!is_jbrand_value(value))
        return 0;
    
    return value;
}


NSString* find_jbroot()
{
    //jbroot path may change when re-randomize it
    NSString * jbroot = nil;
    NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
    for (NSString *subItem in subItems) {
        if (is_jbroot_name(subItem.UTF8String))
        {
            NSString* path = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
            jbroot = path;
            break;
        }
    }
    return jbroot;
}

NSString *jbroot(NSString *path)
{
    NSString* jbroot = find_jbroot();
    return [jbroot stringByAppendingPathComponent:path];
}

float roundLog(float input) {
    double floored = floor(input);
    double decimal = input - floored;
    if (decimal < 0.159925) {
        return floored;
    } else if (decimal < 0.45943162) {
        return (floored + 0.32192809);
    } else if (decimal < 0.70043972) {
        return (floored + 0.5849625);
    } else if (decimal < 0.9068906) {
        return (floored + 0.80735492);
    } else {
        return floored + 1;
    }
}

bool isBetaiOS(void) {
    char type[256];
    size_t type_size = 256;
    int ret = sysctlbyname("kern.osreleasetype", &type, &type_size, NULL, 0);
    if (ret) return false;
    return (!strcmp(type, "Beta"));
}
