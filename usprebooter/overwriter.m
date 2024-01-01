@import Darwin;
@import Foundation;
@import MachO;

#import <mach-o/fixup-chains.h>
#import "vm_unaligned_copy_switch_race.h"
#import "overwriter.h"
#import "troller.h"
#import "fun/thanks_opa334dev_htrowii.h"
#include "util.h"
#import "fun/vnode.h"

//char* getLaunchdShim(void) {
//    char* prebootpath = return_boot_manifest_hash_main();
//    static char originallaunchd[256];
//    sprintf(originallaunchd, "%s/%s", prebootpath, "launchdshim");
////    NSString *fakelaunchdPath = [NSString stringWithUTF8String:originallaunchd];
//    NSLog(@"patchedlaunchd: %s", originallaunchd);
//    return originallaunchd;
//}

char* getLunchd(void) {
    char* prebootpath = return_boot_manifest_hash_main();
    static char originallaunchd[256];
    sprintf(originallaunchd, "%s/%s", prebootpath, "lunchd");
    NSLog(@"patchedlaunchd: %s", originallaunchd);
    return originallaunchd;
}


bool overwrite_patchedlaunchd_kfd(void) {
    SwitchSysBin(getVnodeAtPathByChdir("/sbin"), "launchd", getLunchd());
    return true;
}
