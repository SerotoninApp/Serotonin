//
//  troller.h
//  usprebooter
//
//  Created by LL on 29/11/23.
//

#ifndef troller_h
#define troller_h
#import <Foundation/Foundation.h>
int userspaceReboot(void);
int go(NSString* argument);
int get_boot_manifest_hash(char hash[97]);
char* return_boot_manifest_hash_main(void);
#endif /* troller_h */
