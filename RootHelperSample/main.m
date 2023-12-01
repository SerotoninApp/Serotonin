#import <stdio.h>
@import Foundation;
#import "uicache.h"
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

int signAdhoc(NSString *filePath, NSDictionary *entitlements) // lets just assume ldid is included ok
{
//        if(!isLdidInstalled()) return 173;

        NSString *entitlementsPath = nil;
        NSString *signArg = @"-s";
        NSString* errorOutput;
        if(entitlements)
        {
            NSData *entitlementsXML = [NSPropertyListSerialization dataWithPropertyList:entitlements format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
            if (entitlementsXML) {
                entitlementsPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString] stringByAppendingPathExtension:@"plist"];
                [entitlementsXML writeToFile:entitlementsPath atomically:NO];
                signArg = [@"-S" stringByAppendingString:entitlementsPath];
                signArg = [@"-M" stringByAppendingString:@"/sbin/launchd"];
            }
            
        }
        NSLog(@"roothelper: running ldid");
        int ldidRet = runLdid(@[signArg, filePath], nil, &errorOutput);
        if (entitlementsPath) {
            [[NSFileManager defaultManager] removeItemAtPath:entitlementsPath error:nil];
        }

        NSLog(@"roothelper: ldid exited with status %d", ldidRet);

        NSLog(@"roothelper: - ldid error output start -");

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


// Apparently there is some odd behaviour where TrollStore installed apps sometimes get restricted
// This works around that issue at least and is triggered when rebuilding icon cache
//void cleanRestrictions(void)
//{
//	NSString* clientTruthPath = @"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/ClientTruth.plist";
//	NSURL* clientTruthURL = [NSURL fileURLWithPath:clientTruthPath];
//	NSDictionary* clientTruthDictionary = [NSDictionary dictionaryWithContentsOfURL:clientTruthURL];
//
//	if(!clientTruthDictionary) return;
//
//	NSArray* valuesArr;
//
//	NSDictionary* lsdAppRemoval = clientTruthDictionary[@"com.apple.lsd.appremoval"];
//	if(lsdAppRemoval && [lsdAppRemoval isKindOfClass:NSDictionary.class])
//	{
//		NSDictionary* clientRestrictions = lsdAppRemoval[@"clientRestrictions"];
//		if(clientRestrictions && [clientRestrictions isKindOfClass:NSDictionary.class])
//		{
//			NSDictionary* unionDict = clientRestrictions[@"union"];
//			if(unionDict && [unionDict isKindOfClass:NSDictionary.class])
//			{
//				NSDictionary* removedSystemAppBundleIDs = unionDict[@"removedSystemAppBundleIDs"];
//				if(removedSystemAppBundleIDs && [removedSystemAppBundleIDs isKindOfClass:NSDictionary.class])
//				{
//					valuesArr = removedSystemAppBundleIDs[@"values"];
//				}
//			}
//		}
//	}
//
//	if(!valuesArr || !valuesArr.count) return;
//
//	NSMutableArray* valuesArrM = valuesArr.mutableCopy;
//	__block BOOL changed = NO;
//
//	[valuesArrM enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString* value, NSUInteger idx, BOOL *stop)
//	{
//		if(![value hasPrefix:@"com.apple."])
//		{
//			[valuesArrM removeObjectAtIndex:idx];
//			changed = YES;
//		}
//	}];
//
//	if(!changed) return;
//
//	NSMutableDictionary* clientTruthDictionaryM = (__bridge_transfer NSMutableDictionary*)CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (__bridge CFDictionaryRef)clientTruthDictionary, kCFPropertyListMutableContainersAndLeaves);
//	
//	clientTruthDictionaryM[@"com.apple.lsd.appremoval"][@"clientRestrictions"][@"union"][@"removedSystemAppBundleIDs"][@"values"] = valuesArrM;
//
//	[clientTruthDictionaryM writeToURL:clientTruthURL error:nil];
//}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
        NSLog(@"Hello from the other side! our uid is %u and our pid is %d", getuid(), getpid());
//        [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/testrebuild" withIntermediateDirectories:true attributes:nil error:nil];
//        sleep(1);
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
            NSDictionary* entitlements = @{
                @"get-task-allow": [NSNumber numberWithBool:YES],
                @"platform-application": [NSNumber numberWithBool:YES],
//                @"com.apple.apfs.get-dev-by-role": [NSNumber numberWithBool:YES],
//                @"com.apple.private.amfi.can-allow-non-platform": [NSNumber numberWithBool:YES],
//                @"com.apple.private.kernel.system-override": [NSNumber numberWithBool:YES],
//                @"com.apple.private.persona-mgmt": [NSNumber numberWithBool:YES],
//                @"com.apple.private.security.system-mount-authority": [NSNumber numberWithBool:YES],
//                @"com.apple.private.set-atm-diagnostic-flag": [NSNumber numberWithBool:YES],
//                @"com.apple.private.spawn-subsystem-root": [NSNumber numberWithBool:YES],
//                @"com.apple.private.vfs.allow-low-space-writes": [NSNumber numberWithBool:YES],
//                @"com.apple.private.vfs.pivot-root": [NSNumber numberWithBool:YES],
//                @"com.apple.security.network.server": [NSNumber numberWithBool:YES]
            };
            NSString* patchedLaunchdCopy = [NSString stringWithUTF8String: getPatchedLaunchdCopy()];
            signAdhoc(patchedLaunchdCopy, entitlements); // source file, NSDictionary with entitlements
            NSString *fastPathSignPath = [usprebooterappPath() stringByAppendingPathComponent:@"fastPathSign"];
            NSString *stdOut;
            NSString *stdErr;
            spawnRoot(fastPathSignPath, @[@"-i", patchedLaunchdCopy, @"-r", @"-o", patchedLaunchdCopy], &stdOut, &stdErr);
        }

        return 0;
    }
}
