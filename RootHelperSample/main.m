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
/* Attach to a process that is already running. */
//PTRACE_ATTACH = 16,
#define PT_ATTACH 16

/* Detach from a process attached to with PTRACE_ATTACH.  */
//PTRACE_DETACH = 17,
#define PT_DETACH 17
#define PT_ATTACHEXC    14    /* attach to running process with signal exception */
#define PT_TRACE_ME 0
int ptrace(int, pid_t, caddr_t, int);

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
    return [usprebooterPath() stringByAppendingPathComponent:@"usprebooter.app"];
}

//BOOL isLdidInstalled(void)
//{
//    NSString* ldidPath = [trollStoreAppPath() stringByAppendingPathComponent:@"ldid"];
//    return [[NSFileManager defaultManager] fileExistsAtPath:ldidPath];
//}

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
        NSLog(@"posix_spawn error %d\n", spawnError);
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

int signAdhoc(NSString *filePath, NSString *entitlements) // lets just assume ldid is included ok
{
//        if(!isLdidInstalled()) return 173;

//        NSString *entitlementsPath = nil;
        NSString *signArg = @"-S";
        NSString* errorOutput;
        if(entitlements) {
//            NSData *entitlementsXML = [NSPropertyListSerialization dataWithPropertyList:entitlements format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
//            if (entitlementsXML) {
//                entitlementsPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString] stringByAppendingPathExtension:@"plist"];
//                [entitlementsXML writeToFile:entitlementsPath atomically:NO];
                signArg = [signArg stringByAppendingString:entitlements];
//                signArg = [signArg stringByAppendingString:@" -Cadhoc"];
//                signArg = [signArg stringByAppendingString:@" -M"];
//                signArg = [signArg stringByAppendingString:@"/sbin/launchd"];
//            }
        }
        NSLog(@"roothelper: running ldid");
        int ldidRet = runLdid(@[signArg, filePath], nil, &errorOutput);
//        if (entitlementsPath) {
//            [[NSFileManager defaultManager] removeItemAtPath:entitlementsPath error:nil];
//        }

        NSLog(@"roothelper: ldid exited with status %d", ldidRet);

        NSLog(@"roothelper: - ldid error output start -");
    
        printMultilineNSString(signArg);
        printMultilineNSString(errorOutput);

        NSLog(@"roothelper: - ldid error output end -");

        if(ldidRet == 0)
        {
            return 0;
        }
        else
        {
            return 175;
        }
    //}
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

    if (file == NULL) {
        NSLog(@"Error opening workinglaunchd");
        perror("Error opening file");
        return;
    }

    fseek(file, offset, SEEK_SET);
    fwrite(replacement, sizeof(char), 4, file);

    fclose(file);
}

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
//        NSLog(@"Hello from the other side! our uid is %u and our pid is %d", getuid(), getpid());
        loadMCMFramework();
        NSString* action = [NSString stringWithUTF8String:argv[1]];
        NSString* source = [NSString stringWithUTF8String:argv[2]];
        NSString* destination = [NSString stringWithUTF8String:argv[3]];
        
        if ([action isEqual: @"writedata"]) {
            [source writeToFile:destination atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else if ([action isEqual: @"filemove"]) {
            [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"filecopy"]) {
            NSLog(@"roothelper: cp");
            [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:nil];
        } else if ([action isEqual: @"makedirectory"]) {
            NSLog(@"roothelper: mkdir");
            [[NSFileManager defaultManager] createDirectoryAtPath:source withIntermediateDirectories:true attributes:nil error:nil];
        } else if ([action isEqual: @"removeitem"]) {
            NSLog(@"roothelper: rm");
            [[NSFileManager defaultManager] removeItemAtPath:source error:nil];
        } else if ([action isEqual: @"permissionset"]) {
            NSLog(@"roothelper chmod %@", source); // just pass in 755
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSNumber numberWithInt:755]  forKey:NSFilePosixPermissions];
            [[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:source error:nil];
            //        } else if ([action isEqual: @"rebuildiconcache"]) {
            //            cleanRestrictions();
            //            [[LSApplicationWorkspace defaultWorkspace] _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES];
            //            refreshAppRegistrations();
            //            killall(@"backboardd");
        } else if ([action isEqual: @"codesign"]) {
            NSLog(@"roothelper: adhoc sign + fastsign");
//            NSDictionary* entitlements = @{
//                @"get-task-allow": [NSNumber numberWithBool:YES],
//                @"platform-application": [NSNumber numberWithBool:YES],
//            };
            NSString* launchdents = [usprebooterappPath() stringByAppendingPathComponent:@"launchdentitlements.plist"];
            NSString* patchedLaunchdCopy = [usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"];
            signAdhoc(patchedLaunchdCopy, launchdents); // source file, NSDictionary with entitlements
            
            // TODO: Use ct_bypass instead of fastPathSign, it's just better :trol:
            NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
            NSString *stdOut;
            NSString *stdErr;
            spawnRoot(fastPathSignPath, @[@"-i", patchedLaunchdCopy, @"-r", @"-o", patchedLaunchdCopy], &stdOut, &stdErr);
        } else if ([action isEqual: @"ptrace"]) {
            NSLog(@"roothelper: stage 1 ptrace");
            NSString *stdOut;
            NSString *stdErr;
            NSLog(@"trolltoolshelper path %@", rootHelperPath());
            spawnRoot(rootHelperPath(), @[@"ptrace2", source, @""], &stdOut, &stdErr);
            kill(getpid(), 1);
        } else if ([action isEqual: @"ptrace2"]) {
            NSLog(@"roothelper: stage 2 ptrace, app pid: %@", source);
            int pidInt = [source intValue];
//             source = pid of app.
//             ptrace the source, the pid of the original app
//             then detach immediately
//            ptrace(PT_TRACE_ME,0,0,0);
            ptrace(PT_ATTACH, pidInt, 0, 0);
            ptrace(PT_DETACH, pidInt, 0, 0);
            NSLog(@"Done ptracing!");
        } else if ([action isEqual: @"bootstrap"]) {
            NSLog(@"installing");
            if (!jbroot(@"/")) {
                NSLog(@"jbroot not found...");
            } else {
//                if (!jbroot(@"lunchd")) {
                    //                1. install roothide bootstrap
                    //                2. copy over launchd to your macos from your phone
                NSLog(@"copy launchd over");
                    [[NSFileManager defaultManager] copyItemAtPath:@"/sbin/launchd" toPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] error:nil];
                    // remove cpu subtype, insert_dylib, then
                    replaceByte([usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"], 8, "\x00\x00\x00\x00");
                    insert_dylib_main("@loader_path/launchdhook.dylib", [[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] UTF8String]);
                sleep(1);
                NSLog(@"sign launchd over");
                    spawnRoot(rootHelperPath(), @[@"codesign", source, @""], nil, nil);
                    //                3. copy over workinglaunchd to your jbroot/lunchd
                    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"workinglaunchd"] toPath:jbroot(@"lunchd") error:nil];
                    //                4. copy over launchdhooksigned.dylib as jbroot/launchdhook.dylib
                    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"launchdhooksigned.dylib"] toPath:jbroot(@"launchdhook.dylib") error:nil];
                    //                5. copy over your regular SpringBoard.app to jbroot/System/Library/CoreServices/SpringBoard.app
                    
                    [[NSFileManager defaultManager] createDirectoryAtPath: jbroot(@"/System/Library/CoreServices/") withIntermediateDirectories:YES attributes:nil error:nil];
                    [[NSFileManager defaultManager] copyItemAtPath:@"/System/Library/CoreServices/SpringBoard.app" toPath:jbroot(@"/System/Library/CoreServices/SpringBoard.app") error:nil];
                        
                    //                6. replace the regular SpringBoard in your jbroot/System/Library/CoreServices/SpringBoard.app/SpringBoard with springboardshimsignedinjected
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/System/Library/CoreServices/SpringBoard.app/SpringBoard") error:nil];
                    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"springboardshimsignedinjected"] toPath:jbroot(@"/System/Library/CoreServices/SpringBoard.app/SpringBoard") error:nil];
                     
                    //                7. place springboardhooksigned.dylib as jbroot/SpringBoard.app/springboardhook.dylib
                    [[NSFileManager defaultManager] removeItemAtPath:jbroot(@"/System/Library/CoreServices/SpringBoard.app/springboardhook.dylib") error:nil];
                    [[NSFileManager defaultManager] copyItemAtPath:[usprebooterappPath() stringByAppendingPathComponent:@"springboardhooksigned.dylib"] toPath:[jbroot(@"/System/Library/CoreServices/SpringBoard.app") stringByAppendingPathComponent:@"springboardhook.dylib"] error:nil];
                    // last step: create a symlink to jbroot named .jbroot
                    [[NSFileManager defaultManager] createSymbolicLinkAtPath:jbroot(@"/System/Library/CoreServices/SpringBoard.app/.jbroot") withDestinationPath:jbroot(@"/") error:nil];
//                } else {
//                    NSLog(@"lunchd was found, you've already installed");
//                }
            }
        }
        return 0;
    }
}
