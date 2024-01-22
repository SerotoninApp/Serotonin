//
//  troller.h
//  Serotonin
//
//  Created by LL on 29/11/23.
//
#include <stdbool.h>
#include <Foundation/Foundation.h>
#ifndef troller_h
#define troller_h
int userspaceReboot(void);
int go(bool isBeta, NSString* argument);
int get_boot_manifest_hash(char hash[97]);
char* return_boot_manifest_hash_main(void);
#endif /* troller_h */
