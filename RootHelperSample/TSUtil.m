#import "TSUtil.h"

#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/sysctl.h>
#include <IOKit/IOKitLib.h>

@interface PSAppDataUsagePolicyCache : NSObject
+ (instancetype)sharedInstance;
- (void)setUsagePoliciesForBundle:(NSString*)bundleId cellular:(BOOL)cellular wifi:(BOOL)wifi;
@end

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);


void loadMCMFramework(void)
{
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		NSBundle* mcmBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/MobileContainerManager.framework"];
		[mcmBundle load];
	});
}

extern char*** _NSGetArgv();
NSString* safe_getExecutablePath()
{
	char* executablePathC = **_NSGetArgv();
	return [NSString stringWithUTF8String:executablePathC];
}

#ifdef EMBEDDED_ROOT_HELPER
NSString* rootHelperPath(void)
{
	return safe_getExecutablePath();
}
#else
NSString* rootHelperPath(void)
{
	return [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"trolltoolsroothelper"];
}
#endif

NSString* getNSStringFromFile(int fd)
{
	NSMutableString* ms = [NSMutableString new];
	ssize_t num_read;
	char c;
	while((num_read = read(fd, &c, sizeof(c))))
	{
		[ms appendString:[NSString stringWithFormat:@"%c", c]];
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

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
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
		NSLog(@"posix_spawn error %d\n", spawnError);
		return spawnError;
	}

	do
	{
		if (waitpid(task_pid, &status, 0) != -1) {
			NSLog(@"Child status %d", WEXITSTATUS(status));
		} else
		{
			perror("waitpid");
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
	
	return WEXITSTATUS(status);
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
	int count;
	
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

void killall(NSString* processName)
{
	enumerateProcessesUsingBlock(^(pid_t pid, NSString* executablePath, BOOL* stop)
	{
		if([executablePath.lastPathComponent isEqualToString:processName])
		{
			kill(pid, SIGTERM);
		}
	});
}

void respring(void)
{
	killall(@"SpringBoard");
	exit(0);
}



SecStaticCodeRef getStaticCodeRef(NSString *binaryPath)
{
	if(binaryPath == nil)
	{
		return NULL;
	}
	
	CFURLRef binaryURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)binaryPath, kCFURLPOSIXPathStyle, false);
	if(binaryURL == NULL)
	{
		NSLog(@"[getStaticCodeRef] failed to get URL to binary %@", binaryPath);
		return NULL;
	}
	
	SecStaticCodeRef codeRef = NULL;
	OSStatus result;
	
	result = SecStaticCodeCreateWithPathAndAttributes(binaryURL, kSecCSDefaultFlags, NULL, &codeRef);
	
	CFRelease(binaryURL);
	
	if(result != errSecSuccess)
	{
		NSLog(@"[getStaticCodeRef] failed to create static code for binary %@", binaryPath);
		return NULL;
	}
		
	return codeRef;
}

NSDictionary* dumpEntitlements(SecStaticCodeRef codeRef)
{
	if(codeRef == NULL)
	{
		NSLog(@"[dumpEntitlements] attempting to dump entitlements without a StaticCodeRef");
		return nil;
	}
	
	CFDictionaryRef signingInfo = NULL;
	OSStatus result;
	
	result = SecCodeCopySigningInformation(codeRef, kSecCSRequirementInformation, &signingInfo);
	
	if(result != errSecSuccess)
	{
		NSLog(@"[dumpEntitlements] failed to copy signing info from static code");
		return nil;
	}
	
	NSDictionary *entitlementsNSDict = nil;
	
	CFDictionaryRef entitlements = CFDictionaryGetValue(signingInfo, kSecCodeInfoEntitlementsDict);
	if(entitlements == NULL)
	{
		NSLog(@"[dumpEntitlements] no entitlements specified");
	}
	else if(CFGetTypeID(entitlements) != CFDictionaryGetTypeID())
	{
		NSLog(@"[dumpEntitlements] invalid entitlements");
	}
	else
	{
		entitlementsNSDict = (__bridge NSDictionary *)(entitlements);
		NSLog(@"[dumpEntitlements] dumped %@", entitlementsNSDict);
	}
	
	CFRelease(signingInfo);
	return entitlementsNSDict;
}

NSDictionary* dumpEntitlementsFromBinaryAtPath(NSString *binaryPath)
{
	// This function is intended for one-shot checks. Main-event functions should retain/release their own SecStaticCodeRefs
	
	if(binaryPath == nil)
	{
		return nil;
	}
	
	SecStaticCodeRef codeRef = getStaticCodeRef(binaryPath);
	if(codeRef == NULL)
	{
		return nil;
	}
	
	NSDictionary *entitlements = dumpEntitlements(codeRef);
	CFRelease(codeRef);

	return entitlements;
}

NSDictionary* dumpEntitlementsFromBinaryData(NSData* binaryData)
{
	NSDictionary* entitlements;
	NSString* tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
	NSURL* tmpURL = [NSURL fileURLWithPath:tmpPath];
	if([binaryData writeToURL:tmpURL options:NSDataWritingAtomic error:nil])
	{
		entitlements = dumpEntitlementsFromBinaryAtPath(tmpPath);
		[[NSFileManager defaultManager] removeItemAtURL:tmpURL error:nil];
	}
	return entitlements;
}

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

char* return_boot_manifest_hash_main(void) {
  static char hash[97];
  int ret = get_boot_manifest_hash(hash);
  if (ret != 0) {
    fprintf(stderr, "could not get boot manifest hash\n");
    return "lmao";
  }
    static char result[115];
    sprintf(result, "/private/preboot/%s", hash);
    return result;
}

char* getPatchedLaunchdCopy(void) {
    char* prebootpath = return_boot_manifest_hash_main();
    static char originallaunchd[256];
    sprintf(originallaunchd, "%s/%s", prebootpath, "patchedlaunchd");
    NSLog(@"patchedlaunchd: %s", originallaunchd);
    return originallaunchd;
}

char* getOriginalLaunchdCopy(void) {
    char* prebootpath = return_boot_manifest_hash_main();
    static char originallaunchd[256];
    sprintf(originallaunchd, "%s/%s", prebootpath, "patchedlaunchd");
    NSLog(@"patchedlaunchd: %s", originallaunchd);
    return originallaunchd;
}
