#import <stdio.h>
@import Foundation;

#import <sys/stat.h>
#import <dlfcn.h>
#import <spawn.h>
#import <objc/runtime.h>
#import "TSUtil.h"
#import <sys/utsname.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <Security/Security.h>

#import "codesign.h"
#import "coretrust_bug.h"
#import <choma/FAT.h>
#import <choma/MachO.h>
#import <choma/FileStream.h>
#import <choma/Host.h>

#include <sys/types.h>
#include "insert_dylib.h"
#include "exepatch.h"
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


NSString* usprebooterPath()
{
    NSError* mcmError;
    MCMAppContainer* appContainer = [MCMAppContainer containerWithIdentifier:@"pisshill.usprebooter" createIfNecessary:NO existed:NULL error:&mcmError];
    if(!appContainer) return nil;
    return appContainer.url.path;
}

NSString* usprebooterappPath()
{
    return [usprebooterPath() stringByAppendingPathComponent:@"Serotonin.app"];
}

int runLdid(NSArray* args, NSString** output, NSString** errorOutput)
{
    NSString* ldidPath = [usprebooterappPath() stringByAppendingPathComponent:@"ldid"];
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:ldidPath.lastPathComponent atIndex:0];

    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outErr[2];
    pipe(outErr);
    posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&action, outErr[0]);

    int out[2];
    pipe(out);
    posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&action, out[0]);
    
    pid_t task_pid;
    int status = -200;
    int spawnError = posix_spawn(&task_pid, [ldidPath fileSystemRepresentation], &action, NULL, (char* const*)argsC, NULL);
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);

    if(spawnError != 0)
    {
//        NSLog(@"posix_spawn error %d\n", spawnError);
        return spawnError;
    }

    do
    {
        if (waitpid(task_pid, &status, 0) != -1) {
            //printf("Child status %dn", WEXITSTATUS(status));
        } else
        {
            perror("waitpid");
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    close(outErr[1]);
    close(out[1]);

    NSString* ldidOutput = getNSStringFromFile(out[0]);
    if(output)
    {
        *output = ldidOutput;
    }

    NSString* ldidErrorOutput = getNSStringFromFile(outErr[0]);
    if(errorOutput)
    {
        *errorOutput = ldidErrorOutput;
    }

    return WEXITSTATUS(status);
}

int signAdhoc(NSString *filePath, NSString *entitlements) {
    NSMutableArray *args = [NSMutableArray array];
    
    if (entitlements && entitlements.length > 0) {
        [args addObject:[NSString stringWithFormat:@"-S%@", entitlements]];
    }
    
    [args addObjectsFromArray:@[@"-M", filePath]];
    
    NSString *errorOutput;
    NSLog(@"roothelper: running ldid with args: %@", [args componentsJoinedByString:@" "]);
    int ldidRet = runLdid(args, nil, &errorOutput);
    
    if (ldidRet == 0) {
        NSLog(@"ldid succeeded");
        return 0;
    } else {
        NSLog(@"ldid error: %@", errorOutput);
        return 175;
    }
}


NSSet<NSString*>* immutableAppBundleIdentifiers(void)
{
    NSMutableSet* systemAppIdentifiers = [NSMutableSet new];

    LSEnumerator* enumerator = [LSEnumerator enumeratorForApplicationProxiesWithOptions:0];
    LSApplicationProxy* appProxy;
    while(appProxy = [enumerator nextObject])
    {
        if(appProxy.installed)
        {
            if(![appProxy.bundleURL.path hasPrefix:@"/private/var/containers"])
            {
                [systemAppIdentifiers addObject:appProxy.bundleIdentifier.lowercaseString];
            }
        }
    }

    return systemAppIdentifiers.copy;
}

void replaceByte(NSString *filePath, int offset, const char *replacement) {
    const char *fileCString = [filePath UTF8String];
    FILE *file = fopen(fileCString, "r+");
    fseek(file, offset, SEEK_SET);
    fwrite(replacement, sizeof(char), 4, file);
    fclose(file);
}

void removeItemAtPathRecursively(NSString *path) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:path]) {
        NSLog(@"Item does not exist at path: %@", path);
        return;
    }
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    if (error == nil) {
        for (NSString *item in contents) {
            if ([item isEqualToString:@".jbroot"]) {
//                NSLog(@"Skipping deletion of %@ in %@", item, path);
                continue;
            }
            NSString *itemPath = [path stringByAppendingPathComponent:item];
            BOOL isDirectory = NO;
            if ([fileManager fileExistsAtPath:itemPath isDirectory:&isDirectory]) {
                if (isDirectory) {
                    removeItemAtPathRecursively(itemPath);
                } else {
                    [fileManager removeItemAtPath:itemPath error:&error];
                    if (error != nil) {
                        NSLog(@"Error removing item at path %@: %@", itemPath, error);
                    }
                }
            }
        }
        [fileManager removeItemAtPath:path error:&error];
        if (error != nil) {
            NSLog(@"Error removing item at path %@: %@", path, error);
        }
    } else {
        NSLog(@"Error reading contents of directory %@: %@", path, error);
    }
}

void installLaunchd(void) {
    NSLog(@"copy launchd over");
    [[NSFileManager defaultManager] copyItemAtPath:@"/sbin/launchd" toPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] error:nil];

    replaceByte([usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"], 8, "\x00\x00\x00\x00");
    insert_dylib_main("@loader_path/launchdhook.dylib", [[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] UTF8String]);
    
    NSLog(@"sign launchd over and out");

    NSString* launchdents = [usprebooterappPath() stringByAppendingPathComponent:@"launchdentitlements.plist"];
    NSString* patchedLaunchdCopy = [usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"];
    signAdhoc(patchedLaunchdCopy, launchdents); // source file, NSDictionary with entitlements

    NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
    NSString *stdOut;
    NSString *stdErr;
    spawnRoot(fastPathSignPath, @[@"-i", patchedLaunchdCopy, @"-r", @"-o", patchedLaunchdCopy], &stdOut, &stdErr);

    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] toPath:jbroot(@"launchd") error:nil];

    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"launchdhooksigned.dylib"] toPath:jbroot(@"launchdhook.dylib") error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] error:nil];
}

void installClone(NSString *path) {
    NSLog(@"Signing %@", path);
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingLastPathComponent]] == true) {
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByDeletingLastPathComponent] error:nil];
    }
    
    [[NSFileManager defaultManager] copyItemAtPath:[path stringByDeletingLastPathComponent] toPath:jbroot([path stringByDeletingLastPathComponent]) error:nil];
    
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:jbroot(path) error:nil];
    
    NSString* ents = [usprebooterappPath() stringByAppendingPathComponent:@"launchdentitlements.plist"];
    if ([path isEqual:@"/Applications/MediaRemoteUI.app/MediaRemoteUI"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"MRUIents.plist"];
    } else if ([path isEqual:@"/System/Library/CoreServices/SpringBoard.app/SpringBoard"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"SpringBoardEnts.plist"];
    } else {
        NSLog(@"Note: no dedicated ents file for this, shit will likely break");
    }
    // strip arm64e
    replaceByte(jbroot(path), 8, "\x00\x00\x00\x00");
    
    NSLog(@"insert dylib ret %d", patch_app_exe([jbroot(path) UTF8String]));
    signAdhoc(jbroot(path), ents);
    
    NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
    
    NSString *stdOut;
    NSString *stdErr;
    spawnRoot(fastPathSignPath, @[@"-i", jbroot(path), @"-r", @"-o", jbroot(path)], &stdOut, &stdErr);

    NSString *dylib_path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"generalhooksigned.dylib"];
    
    NSString *symlink_path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".jbroot"];
    
    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"generalhooksigned.dylib"] toPath:jbroot(dylib_path) error:nil];

    [[NSFileManager defaultManager] createSymbolicLinkAtPath:jbroot(symlink_path) withDestinationPath:jbroot(@"/") error:nil];
}

void install_cfprefsd(void) {
    [[NSFileManager defaultManager] createDirectoryAtPath: jbroot(@"/usr/sbin/") withIntermediateDirectories:YES attributes:nil error:nil];

    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/usr/sbin/cfprefsd") error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"cfprefsdshimsignedinjected"] toPath:jbroot(@"/usr/sbin/cfprefsd") error:nil];
     
    // 8. create a symlink to jbroot named .jbroot
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:jbroot(@"/usr/sbin/.jbroot") withDestinationPath:jbroot(@"/") error:nil];
}

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
//        NSLog(@"Hello from the other side! our uid is %u and our pid is %d", getuid(), getpid());
        loadMCMFramework();
        NSString* action = [NSString stringWithUTF8String:argv[1]];
        NSString* source = [NSString stringWithUTF8String:argv[2]];
        if ([action isEqual: @"install"]) {
            NSLog(@"installing");
            if (!jbroot(@"/")) {
                NSLog(@"jbroot not found...");
            } else {
                installLaunchd();
                installClone(@"/System/Library/CoreServices/SpringBoard.app/SpringBoard");
                installClone(@"/Applications/MediaRemoteUI.app/MediaRemoteUI");
                installClone(@"/usr/libexec/xpcproxy");
                install_cfprefsd();
            }
        } else if ([action isEqual: @"uninstall"]) {
            NSLog(@"uninstalling");
            if (!jbroot(@"/")) {
                NSLog(@"jbroot not found...");
            } else {
                if (!jbroot(@"launchd")) {
                    NSLog(@"not continuing, launchd wasn't found to remove");
                    return -1;
                } else {
                    removeItemAtPathRecursively(jbroot(@"/System/Library/CoreServices/SpringBoard.app/"));
                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Serotonin.jp2" error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"launchd") error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"launchdhook.dylib") error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/Applications/MediaRemoteUI.app/MediaRemoteUI") error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/Applications/MediaRemoteUI.app/generalhooksigned") error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/Applications/MediaRemoteUI.app/") error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:[jbroot(@"/usr/lib/TweakInject") stringByAppendingPathComponent:@"hideconfidentialtext.plist"] error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:[jbroot(@"/usr/lib/TweakInject") stringByAppendingPathComponent:@"hideconfidentialtext.dylib"] error:nil];
                }
            }
        } else if ([action isEqual: @"reinstall"]) {
            spawnRoot(rootHelperPath(), @[@"uninstall", source, @""], nil, nil);
            spawnRoot(rootHelperPath(), @[@"install", source, @""], nil, nil);
        } else if ([action isEqual: @"toggleVerbose"]) {
                NSString *filePath = @"/var/mobile/.serotonin_verbose";
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
                if (!fileExists) {
                    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
                    return 1;
                } else {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                    return 2;
                }
        } else if ([action isEqual: @"toggleText"]) {
            NSString *filePath = @"/var/mobile/.serotonin_hidetext";
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            if (!fileExists) {
                [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
                return 1;
            } else {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                return 2;
            }
        } else if ([action isEqual: @"checkVerbose"]) {
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.serotonin_verbose"];
            return fileExists;
        } else if ([action isEqual: @"checkHidden"]) {
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.serotonin_hidetext"];
            return fileExists;
        } else {
                return 0;
            }
        }
    }
