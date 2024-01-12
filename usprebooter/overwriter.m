@import Darwin;
@import Foundation;
@import MachO;

#include <UIKit/UIKit.h>
#import <mach-o/fixup-chains.h>
#import "vm_unaligned_copy_switch_race.h"
#import "overwriter.h"
#import "troller.h"
#import "fun/thanks_opa334dev_htrowii.h"
#include "util.h"
#import "fun/vnode.h"

NSString* getLunchd(void) {
    return jbroot(@"lunchd");
}

#define SYSTEM_VERSION_LOWER_THAN(v)                ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

bool overwrite_patchedlaunchd_kfd(void) {
    // ayo whats this – bomberfish
//    SwitchSysBin(getVnodeAtPathByChdir("/System/Library/CoreServices/SpringBoard.app"), "SpringBoard", "/var/jb/SprangBoard");
    printf("[i] performing launchd hax\n");
    if (SYSTEM_VERSION_LOWER_THAN(@"16.3.1")) {
        uint64_t orig_nc_vp = 0;
        uint64_t orig_to_vnode = 0;
        SwitchSysBin160("/sbin/launchd", getLunchd().UTF8String, &orig_to_vnode, &orig_nc_vp);
    } else {
        SwitchSysBin(getVnodeAtPathByChdir("/sbin"), "launchd", getLunchd().UTF8String);
    }
    printf("[i] launchd haxed\n");
    return true;
}
