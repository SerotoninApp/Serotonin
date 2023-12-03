//
//  util.h
//  usprebooter
//
//  Created by LL on 29/11/23.
//

#ifndef util_h
#define util_h
#import <Foundation/Foundation.h>
void respring(void);
//int respawnSelf(NSArray* args);
int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
int ptraceMe(void);
#endif /* util_h */
