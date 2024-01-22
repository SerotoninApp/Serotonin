//
//  util.h
//  Serotonin
//
//  Created by LL on 29/11/23.
//

#ifndef util_h
#define util_h
#import <Foundation/Foundation.h>
void respring(void);
int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
NSString *jbroot(NSString *path);
#endif /* util_h */
