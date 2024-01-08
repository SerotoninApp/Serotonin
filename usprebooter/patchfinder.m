//
//  patchfinder.m
//  usprebooter
//
//  Created by Mineek on 08/01/2024.
//

#import <Foundation/Foundation.h>

NSString* findPrebootPath(void) {
    NSString* prebootPath = @"/private/preboot";
    // find the one folder in /private/preboot
    NSFileManager* fm = [NSFileManager defaultManager];
    // look at the contents of the "active" file in /private/preboot
    NSString* activePath = [prebootPath stringByAppendingPathComponent:@"active"];
    NSString* active = [NSString stringWithContentsOfFile:activePath encoding:NSUTF8StringEncoding error:nil];
    if(active == nil) {
        printf("active is nil\n");
        return nil;
    }
    // check if the folder exists
    NSString* activePrebootPath = [prebootPath stringByAppendingPathComponent:active];
    if(![fm fileExistsAtPath:activePrebootPath]) {
        printf("activePrebootPath does not exist\n");
        return nil;
    }
    return activePrebootPath;
}

int find_offsets(const char* kernel_path);

int find_offsets_wrapper(void) {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* offsetsPath = @"/var/mobile/offsets.txt";
    if([fm fileExistsAtPath:offsetsPath]) {
        printf("offsets cache exists\n");
        return 0;
    }
    NSString* prebootPath = findPrebootPath();
    if(prebootPath == nil) {
        printf("prebootPath is nil\n");
        return -1;
    }
    printf("prebootPath: %s\n", [prebootPath UTF8String]);
    NSString* kernelcachePath = [prebootPath stringByAppendingPathComponent:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache"];
    printf("kernelcachePath: %s\n", [kernelcachePath UTF8String]);
    return find_offsets([kernelcachePath UTF8String]);
}
