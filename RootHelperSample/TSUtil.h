@import Foundation;
#import "CoreServices.h"

#define TrollStoreErrorDomain @"TrollStoreErrorDomain"

extern void chineseWifiFixup(void);
extern void loadMCMFramework(void);
extern NSString* safe_getExecutablePath();
extern NSString* rootHelperPath(void);
extern NSString* getNSStringFromFile(int fd);
extern void printMultilineNSString(NSString* stringToPrint);
extern int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
extern void killall(NSString* processName);
extern void respring(void);
char* getPatchedLaunchdCopy(void);
char* return_boot_manifest_hash_main(void);
