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
#include "jbroot.h"


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

int signAdhoc(NSString *filePath, NSString *entitlements, bool merge) {
    NSMutableArray *args = [NSMutableArray array];
    
    if (entitlements && entitlements.length > 0) {
        [args addObject:[NSString stringWithFormat:@"-S%@", entitlements]];
    }
    if (merge == true) {
        [args addObjectsFromArray:@[@"-M", filePath]];
    }
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
    signAdhoc(patchedLaunchdCopy, launchdents, true); // source file, NSDictionary with entitlements

    NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
    NSString *stdOut;
    NSString *stdErr;
    spawnRoot(fastPathSignPath, @[@"-i", patchedLaunchdCopy, @"-r", @"-o", patchedLaunchdCopy], &stdOut, &stdErr);

    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] toPath:jbrootobjc(@"launchd") error:nil];

    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"launchdhooksigned.dylib"] toPath:jbrootobjc(@"launchdhook.dylib") error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] error:nil];
}

void installClone(NSString *path) {
    NSLog(@"Signing %@", path);
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingLastPathComponent]] == true) {
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByDeletingLastPathComponent] error:nil];
    }
    
    [[NSFileManager defaultManager] copyItemAtPath:[path stringByDeletingLastPathComponent] toPath:jbrootobjc([path stringByDeletingLastPathComponent]) error:nil];
    
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:jbrootobjc(path) error:nil];
    
    NSString* ents = [usprebooterappPath() stringByAppendingPathComponent:@"launchdentitlements.plist"];
    NSString *hook_file = @"generalhooksigned.dylib";
    NSString *insert_path = @"/generalhooksigned.dylib";
    bool mergeEnts = true;
    if ([path isEqual:@"/Applications/MediaRemoteUI.app/MediaRemoteUI"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"MRUIents.plist"];
    } else if ([path isEqual:@"/System/Library/CoreServices/SpringBoard.app/SpringBoard"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"SpringBoardEnts.plist"];
    } else if ([path isEqual:@"/usr/libexec/installd"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"installdents.plist"];
    } else if ([path isEqual:@"/usr/libexec/nfcd"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"nfcdents.plist"];
    } else if ([path isEqual:@"/usr/libexec/xpcproxy"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"xpcproxydents.plist"];
        hook_file = @"xpcproxyhooksigned.dylib";
        insert_path = @"@loader_path/xpcproxyhooksigned.dylib";
        NSString *dylib_path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:hook_file];
        [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:hook_file] toPath:jbrootobjc(dylib_path) error:nil];
    } else if ([path isEqual:@"/usr/sbin/mediaserverd"]) {
        ents = [usprebooterappPath() stringByAppendingPathComponent:@"mediaserverdents.plist"];
    } else {
        NSLog(@"Note: no dedicated ents file for this, shit will likely break");
    }
    // strip arm64e
    replaceByte(jbrootobjc(path), 8, "\x00\x00\x00\x00");
    NSLog(@"insert dylib ret %d", patch_app_exe([jbrootobjc(path) UTF8String], (char*)[insert_path UTF8String]));
    signAdhoc(jbrootobjc(path), ents, mergeEnts);
    
    NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
    
    NSString *stdOut;
    NSString *stdErr;
    spawnRoot(fastPathSignPath, @[@"-i", jbrootobjc(path), @"-r", @"-o", jbrootobjc(path)], &stdOut, &stdErr);

    NSString *symlink_path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".jbroot"];
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:jbrootobjc(symlink_path) withDestinationPath:jbrootobjc(@"/") error:nil];
}

void install_cfprefsd(void) {
    [[NSFileManager defaultManager] createDirectoryAtPath: jbrootobjc(@"/usr/sbin/") withIntermediateDirectories:YES attributes:nil error:nil];

    [[NSFileManager defaultManager] removeItemAtPath:jbrootobjc(@"/usr/sbin/cfprefsd") error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"cfprefsdshimsignedinjected"] toPath:jbrootobjc(@"/usr/sbin/cfprefsd") error:nil];
     
    // 8. create a symlink to jbroot named .jbroot
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:jbrootobjc(@"/usr/sbin/.jbroot") withDestinationPath:jbrootobjc(@"/") error:nil];
}

void setOwnershipForFolder(NSString *folderPath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error;
    NSDictionary *attributes = @{
        NSFileOwnerAccountID: @(501),
        NSFileGroupOwnerAccountID: @(501)
    };

    if ([fileManager setAttributes:attributes ofItemAtPath:folderPath error:&error]) {
        NSLog(@"Ownership changed successfully for %@", folderPath);

        NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
        for (NSString *item in contents) {
            NSString *itemPath = [folderPath stringByAppendingPathComponent:item];
            setOwnershipForFolder(itemPath);
        }
    } else {
        NSLog(@"Error changing ownership for %@: %@", folderPath, [error localizedDescription]);
    }
}

// void createSymlink(NSString *originalPath, NSString *symlinkPath) {
//     NSFileManager *fileManager = [NSFileManager defaultManager];
//     NSError *error = nil;
//     BOOL success = [fileManager createSymbolicLinkAtPath:symlinkPath withDestinationPath:originalPath error:&error];
    
//     if (success) {
//         NSLog(@"Symlink created successfully at %@", symlinkPath);
//     } else {
//         NSLog(@"Failed to create symlink: %@", [error localizedDescription]);
//     }
// }

int installBootstrap(char *envp[]) {
    // code skidded from Nathan
    NSLog(@"%@", [NSString stringWithFormat:@"%s%@", return_boot_manifest_hash_main(), @"/jb"]);
    [[NSFileManager defaultManager] createSymbolicLinkAtPath:@"/var/jb" withDestinationPath: [NSString stringWithFormat:@"%s%@", return_boot_manifest_hash_main(), @"/jb"] error: nil];
    NSMutableArray* args = [NSMutableArray new];
    NSString *binaryPath = [usprebooterappPath() stringByAppendingPathComponent:@"unzip"];
    [args addObject:[usprebooterappPath() stringByAppendingString:@"/jb.zip"]];
    [args addObject:@"-d"];
    [args addObject:[NSString stringWithFormat:@"%s", return_boot_manifest_hash_main()]];
    spawnRoot(binaryPath, args, nil, nil);
    
    NSString *defaultSources = @"Types: deb\n"
        @"URIs: https://repo.chariz.com/\n"
        @"Suites: ./\n"
        @"Components:\n"
        @"\n"
        @"Types: deb\n"
        @"URIs: https://havoc.app/\n"
        @"Suites: ./\n"
        @"Components:\n"
        @"\n"
        @"Types: deb\n"
        @"URIs: http://apt.thebigboss.org/repofiles/cydia/\n"
        @"Suites: stable\n"
        @"Components: main\n"
        @"\n"
        @"Types: deb\n"
        @"URIs: https://ellekit.space/\n"
        @"Suites: ./\n"
        @"Components:\n";
    [defaultSources writeToFile:@"/var/jb/etc/apt/sources.list.d/default.sources" atomically:NO encoding:NSUTF8StringEncoding error:nil];
    pid_t pid2;
    int status2 = -200;
    setOwnershipForFolder(@"/var/jb/var/mobile");
    
    char *prep_argv[] = {"/var/jb/bin/sh", "/var/jb/prep_bootstrap.sh", NULL };
    posix_spawnp(&pid2, "/var/jb/bin/sh", NULL, NULL, prep_argv, envp);
    waitpid(pid2, &status2, 0);
    NSString *emptyFileDopamine = @"";
    [emptyFileDopamine writeToFile:@"/var/jb/.installed_dopamine" atomically:NO encoding:NSUTF8StringEncoding error:nil];
    return 0;
}

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
//        NSLog(@"Hello from the other side! our uid is %u and our pid is %d", getuid(), getpid());
        loadMCMFramework();
        NSString* action = [NSString stringWithUTF8String:argv[1]];
        NSString* source = [NSString stringWithUTF8String:argv[2]];
        if ([action isEqual: @"install"]) {
            bool bootstrapInstalled = false;
            if (access(jbroot("/"), F_OK == -1)) {
                NSLog(@"installing bootstrap...");
                installBootstrap(envp);
                bootstrapInstalled = true;
            }
            if (bootstrapInstalled == true || access(jbroot("/"), F_OK == 0)) {
                installLaunchd();
                installClone(@"/System/Library/CoreServices/SpringBoard.app/SpringBoard");
                installClone(@"/Applications/MediaRemoteUI.app/MediaRemoteUI");
                installClone(@"/usr/libexec/xpcproxy");
                installClone(@"/usr/libexec/installd");
                installClone(@"/usr/libexec/nfcd");
                installClone(@"/usr/libexec/lsd");
                installClone(@"/usr/sbin/mediaserverd");
                install_cfprefsd();
                [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"generalhooksigned.dylib"] toPath:jbrootobjc(@"/generalhooksigned.dylib") error:nil];
                [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"jitterd"] toPath:jbrootobjc(@"/jitterd") error:nil];
                [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"jitterd.plist"] toPath:jbrootobjc(@"/Library/LaunchDaemons/com.hrtowii.jitterd.plist") error:nil];
//                [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"Serotonin.jp2"] toPath:@"/var/mobile/Serotonin.jp2" error:nil];
            }
        } else if ([action isEqual: @"uninstall"]) {
            NSLog(@"uninstalling");
            if (access(jbroot("/"), F_OK == -1)) {
                NSLog(@"jbroot not found...");
            } else {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error = nil;
                NSLog(@"%@", [NSString stringWithFormat:@"%s%@", return_boot_manifest_hash_main(), @"/jb"]);
                NSArray *pathsToRemove = @[
                    jbrootobjc(@"/System/Library/CoreServices/SpringBoard.app/"),
                    @"/var/mobile/Serotonin.jp2",
                    jbrootobjc(@"/launchd"),
                    jbrootobjc(@"/launchdhook.dylib"),
                    jbrootobjc(@"/Applications/MediaRemoteUI.app/MediaRemoteUI"),
                    jbrootobjc(@"/Applications/MediaRemoteUI.app/generalhooksigned.dylib"),
                    jbrootobjc(@"/Applications/MediaRemoteUI.app/"),
                    [jbrootobjc(@"/usr/lib/TweakInject") stringByAppendingPathComponent:@"hideconfidentialtext.plist"],
                    [jbrootobjc(@"/usr/lib/TweakInject") stringByAppendingPathComponent:@"hideconfidentialtext.dylib"],
                    [jbrootobjc(@"/usr/libexec/") stringByAppendingPathComponent:@"xpcproxyhooksigned.dylib"],
                    [jbrootobjc(@"/usr/libexec/") stringByAppendingPathComponent:@"generalhooksigned.dylib"],
                    [jbrootobjc(@"/usr/libexec/") stringByAppendingPathComponent:@"xpcproxy"],
                    [jbrootobjc(@"/usr/libexec/") stringByAppendingPathComponent:@"installd"],
                    [jbrootobjc(@"/usr/sbin/") stringByAppendingPathComponent:@"cfprefsd"],
                    [jbrootobjc(@"/usr/sbin/") stringByAppendingPathComponent:@"generalhooksigned.dylib"],
                    [jbrootobjc(@"/usr/sbin/") stringByAppendingPathComponent:@"mediaserverd"],
                    jbrootobjc(@"/generalhooksigned.dylib"),
                    jbrootobjc(@"/var/mobile/Serotonin.jp2"),
                    jbrootobjc(@"/jitterd"),
                    jbrootobjc(@"/Library/LaunchDaemons/com.hrtowii.jitterd.plist"),
                    @"/var/jb",
                ];
                if ([fileManager fileExistsAtPath:@"/var/jb/"]) {
                    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:@"/var/jb/"];
                    NSString *documentsName;
                    while (documentsName = [dirEnum nextObject]) {
                        NSString *filePath = [@"/var/jb/" stringByAppendingString:documentsName];
                        BOOL isFileDeleted = [fileManager removeItemAtPath:filePath error:nil];
                        if(isFileDeleted == NO) {
                            NSLog(@"All Contents not removed");
                            break;
                        }
                    }
                }
                for (NSString *path in pathsToRemove) {
                    if ([fileManager fileExistsAtPath:path]) {
                        if (![fileManager removeItemAtPath:path error:&error]) {
                            NSLog(@"Error removing item at %@: %@", path, error.localizedDescription);
                        }
                    }
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
