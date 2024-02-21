@import Darwin;
@import Foundation;
@import MachO;

#include <UIKit/UIKit.h>
#import <mach-o/fixup-chains.h>
#import "overwriter.h"
#import "troller.h"
#import "fun/thanks_opa334dev_htrowii.h"
#include "util.h"
#import "fun/vnode.h"

NSString* getlaunchd(void) {
    return jbroot(@"launchd");
}

#define SYSTEM_VERSION_LOWER_THAN(v)                ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
bool overwrite_patchedlaunchd_kfd(bool isBeta) {
    printf("[i] performing launchd hax\n");
    if (SYSTEM_VERSION_LOWER_THAN(@"16.4")) {
        uint64_t orig_nc_vp = 0;
        uint64_t orig_to_vnode = 0;
        SwitchSysBin160("/sbin/launchd", getlaunchd().UTF8String, &orig_to_vnode, &orig_nc_vp);
    } else if(isBeta && SYSTEM_VERSION_EQUAL_TO(@"16.6")) {
        printf("[i] 16.6b1 detected!");
        uint64_t orig_nc_vp = 0;
        uint64_t orig_to_vnode = 0;
        SwitchSysBin160("/sbin/launchd", getlaunchd().UTF8String, &orig_to_vnode, &orig_nc_vp);
    } else {
        SwitchSysBin(getVnodeAtPathByChdir("/sbin"), "launchd", getlaunchd().UTF8String);
    }
    printf("[i] launchd haxed\n");
    return true;
}
