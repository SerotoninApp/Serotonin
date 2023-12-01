//
//  utils.m
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#import <Foundation/Foundation.h>
#import <dirent.h>
#import <sys/statvfs.h>
#import <sys/stat.h>
#import "proc.h"
#import "vnode.h"
#import "krw.h"
#import "helpers.h"
#include "offsets.h"
#import "thanks_opa334dev_htrowii.h"
#import <errno.h>
#import "utils.h"

uint64_t createFolderAndRedirect(uint64_t vnode, NSString *mntPath) {
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    uint64_t orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    return orig_to_v_data;
}

uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data, NSString *mntPath) {
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    return 0;
}

int setResolution(NSString *path, NSInteger height, NSInteger width) {
    NSDictionary *dictionary = @{
        @"canvas_height": @(height),
        @"canvas_width": @(width)
    };
    
    BOOL success = [dictionary writeToFile:path atomically:YES];
    if (!success) {
        printf("[-] Failed createPlistAtPath.\n");
        return -1;
    }
    
    return 0;
}

int ResSet16(NSInteger height, NSInteger width) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    //1. Create /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/var/tmp");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode, mntPath);
    
    
    //iPhone 14 Pro Max Resolution
    setResolution([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"], height, width);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    
    //2. Create symbolic link /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist -> /var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t preferences_vnode = getVnodePreferences();
    orig_to_v_data = createFolderAndRedirect(preferences_vnode, mntPath);

    remove([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist", [mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String));
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    //3. xpc restart
//    do_kclose();
//    sleep(1);
//    xpc_crasher("com.apple.cfprefsd.daemon");
//    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
    
    return 0;
}

int removeSMSCache(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t library_vnode = getVnodeLibrary();
    uint64_t sms_vnode = getVnodeAtPathByChdir("/var/mobile/Library/SMS");
    printf("[i] /var/mobile/Library/SMS vnode: 0x%llx\n", sms_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(sms_vnode, mntPath);

    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);

    remove([mntPath stringByAppendingString:@"/com.apple.messages.geometrycache_v7.plist"].UTF8String);

    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);

    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int VarMobileWriteTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //create
    [@"PLZ_GIVE_ME_GIRLFRIENDS!@#" writeToFile:[mntPath stringByAppendingString:@"/can_i_remove_file"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int VarMobileRemoveTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //remove
    int ret = remove([mntPath stringByAppendingString:@"/can_i_remove_file"].UTF8String);
    printf("remove ret: %d\n", ret);
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int setSuperviseMode(BOOL enable) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    // /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/CloudConfigurationDetails.plist
    
    uint64_t systemgroup_vnode = getVnodeSystemGroup();
    
    //must enter 3 subdirectories
    uint64_t configurationprofiles_vnode = findChildVnodeByVnode(systemgroup_vnode, "systemgroup.com.apple.configurationprofiles");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(systemgroup_vnode, "systemgroup.com.apple.configurationprofiles");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles vnode: 0x%llx\n", configurationprofiles_vnode);
    
    configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "Library");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "Library");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library vnode: 0x%llx\n", configurationprofiles_vnode);
    
    configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "ConfigurationProfiles");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "ConfigurationProfiles");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles vnode: 0x%llx\n", configurationprofiles_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(configurationprofiles_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles directory list:\n %@", dirs);
    
    //set value of "IsSupervised" key
    NSString *plistPath = [mntPath stringByAppendingString:@"/CloudConfigurationDetails.plist"];
    
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
        
    if (plist) {
        // Set the value of "IsSupervised" key to true
        [plist setObject:@(enable) forKey:@"IsSupervised"];
        
        // Save the updated plist back to the file
        if ([plist writeToFile:plistPath atomically:YES]) {
            printf("[+] Successfully set IsSupervised in the plist.");
        } else {
            printf("[-] Failed to write the updated plist to file.");
        }
    } else {
        printf("[-] Failed to load the plist file.");
    }
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int removeKeyboardCache(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t vnode = getVnodeAtPath("/var/mobile/Library/Caches/com.apple.keyboards/images");
    if(vnode == -1) return 0;
    
    uint64_t orig_to_v_data = createFolderAndRedirect(vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/com.apple.keyboards/images directory list:\n %@", dirs);
    
    for(NSString *dir in dirs) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", mntPath, dir];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/com.apple.keyboards/images directory list:\n %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

#define COUNTRY_KEY @"h63QSdBCiT/z0WU6rdQv6Q"
#define REGION_KEY @"zHeENZu+wbg7PUprwNwBWg"
int regionChanger(NSString *country_value, NSString *region_value) {
    NSString *plistPath = @"/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist";
    NSString *rewrittenPlistPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/com.apple.MobileGestalt.plist"];
    
    remove(rewrittenPlistPath.UTF8String);
    
    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSMutableDictionary *mdict1 = dict1 ? [dict1 mutableCopy] : [NSMutableDictionary dictionary];
    NSDictionary *dict2 = dict1[@"CacheExtra"];
    
    NSMutableDictionary *mdict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary dictionary];
    mdict2[COUNTRY_KEY] = country_value;
    mdict2[REGION_KEY] = region_value;
    [mdict1 setObject:mdict2 forKey:@"CacheExtra"];
    
    NSData *binaryData = [NSPropertyListSerialization dataWithPropertyList:mdict1 format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    [binaryData writeToFile:rewrittenPlistPath atomically:YES];
    
    funVnodeOverwriteFile(plistPath.UTF8String, rewrittenPlistPath.UTF8String);
    
    return 0;
}

void do_trolling(void) {
    NSString *trolling = [NSString stringWithFormat:@"%@/%s", NSBundle.mainBundle.bundlePath, "/PersistenceHelper_Embedded"];
    funVnodeOverwriteFileUnlimitSize("/var/containers/Bundle/Application/C2B25B81-5A68-4FBF-94C2-C8B16B6CA8C6/Tips.app/Tips", [trolling UTF8String]);
}

int themePasscodes(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/var/tmp");
    
    NSArray *fileNames = @[
        @"/PersistenceHelper_Embedded",
    ];
    
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    // symlink documents folder to /var/tmp, then copy all our images there
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode, mntPath);
    
    NSError *error;
    
    // create a file picker and let users choose the image, add them to your documents or whatever, then do this.
    
    // the topath name can be anything but i'm making them the same for easy copy paste
    
    NSArray *selectedFiles = @[
        @"/PersistenceHelper_Embedded",
    ];
    
    for (int i = 0; i < selectedFiles.count; i++) {
            NSString *sourceFilePath = [NSString stringWithFormat:@"%@/%@", NSBundle.mainBundle.bundlePath, selectedFiles[i]];
            NSString *destinationFilePath = [mntPath stringByAppendingString:fileNames[i]];

            [[NSFileManager defaultManager] copyItemAtPath:sourceFilePath toPath:destinationFilePath error:&error];
            if (error) {
                NSLog(@"Error while copying file: %@", error);
                error = nil; // Reset error for the next iteration
            }
        }
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
//    NSLog(@"/var/tmp directory list:\n %@", dirs);
    printf("unredirecting from tmp\n");
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    uint64_t telephonyui_vnode = getVnodeAtPathByChdir("/var/containers/Bundle/Application/");
    printf("[i] /var/containers/Bundle/Application/ vnode: 0x%llx\n", telephonyui_vnode);
    
    //2. Create symbolic link /var/tmp/image.png -> /var/mobile/Library/Caches/TelephonyUI-9/en-number-letters--white.png, loop through then done. Technically just add our known image paths in /var/tmp (they can be anything, just 1.png also works) into an array then loop through both that array and this directory to automate it

    orig_to_v_data = createFolderAndRedirect(telephonyui_vnode, mntPath);
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"directory list: %@", dirs);

    for (NSString *fileName in fileNames) {
        NSString *filePath = [mntPath stringByAppendingPathComponent:fileName];
        NSString *symlinkPath = [NSString stringWithFormat:@"/var/tmp/%@", fileName];

        printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]);
        printf("symlink ret: %d, errno: %d\n", symlink(symlinkPath.UTF8String, filePath.UTF8String), errno);
    }
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/TelephonyUI-9 directory list:\n %@", dirs);

    
    printf("cleaning up\n");
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return 0;
}

#define HEXDUMP_COLS 16
void hexdump(void *mem, unsigned int len)
{
        unsigned int i, j;
        
        for(i = 0; i < len + ((len % HEXDUMP_COLS) ? (HEXDUMP_COLS - len % HEXDUMP_COLS) : 0); i++)
        {
                /* print offset */
                if(i % HEXDUMP_COLS == 0)
                {
                        printf("0x%06x: ", i);
                }
 
                /* print hex data */
                if(i < len)
                {
                        printf("%02x ", 0xFF & ((char*)mem + i)[i]);
                }
                else /* end of block, just aligning for ASCII dump */
                {
                        printf("   ");
                }
                
                /* print ASCII dump */
                if(i % HEXDUMP_COLS == (HEXDUMP_COLS - 1))
                {
                        for(j = i - (HEXDUMP_COLS - 1); j <= i; j++)
                        {
                                if(j >= len) /* end of block, not really printing */
                                {
                                        putchar(' ');
                                }
                                else if(isprint(((char*)mem)[j])) /* printable char */
                                {
                                        putchar(0xFF & ((char*)mem)[j]);
                                }
                                else /* other char */
                                {
                                        putchar('.');
                                }
                        }
                        putchar('\n');
                }
        }
}

void DynamicCOW(void) {
    
    _offsets_init();
    
    xpc_crasher("com.apple.mobilegestalt.xpc");
    
    //1. find "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    //    uint64_t var_vnode = getVnodeVar();
    //    printf("found var vnode\n");
    uint64_t vnode = getVnodeAtPathByChdir("/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/");
    //    printf("found containers vnode\n");
    //    printf("[i] /var/containers vnode: 0x%llx\n", var_containers_vnode);
    //
    //    uint64_t Shared_vnode = findChildVnodeByVnode(var_containers_vnode, "Shared");
    //    printf("found Shared vnode\n");
    //    printf("[i] /var/containers/Shared vnode: 0x%llx\n", Shared_vnode);
    //
    //    uint64_t SystemGroup_vnode = findChildVnodeByVnode(Shared_vnode, "SystemGroup");
    //    printf("found SystemGroup vnode\n");
    //    printf("[i] /var/containers/Shared/SystemGroup vnode: 0x%llx\n", SystemGroup_vnode); sleep(1);
    //
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted/"];
    uint64_t orig_to_v_data = createFolderAndRedirect(vnode, mntPath);
    //
    //    uint64_t _cache_vnode = findChildVnodeByVnodeWithBlock(SystemGroup_vnode, "Caches", ^(uint64_t vn, bool* stop){
    //        printf("found cache vnode\n");
    //        printf("[i] /var/containers/Shared/SystemGroup vnode: 0x%llx\n", vn);
    //
    //        uint64_t orig_to_v_data = createFolderAndRedirect(vn, mntPath);
    //
    //        if (orig_to_v_data == -1) {
    //            return;
    //        }
    //
    //        printf("created var vnode folder\n");
    //
    
    
    [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL] enumerateObjectsUsingBlock:^(NSString * _Nonnull __strong content, NSUInteger index, BOOL * _Nonnull stop2) {
        NSLog(@"element: %@", content);
        if ([content isEqualToString:@"com.apple.MobileGestalt.plist"]) {
            
            NSLog(@"contents: %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL]);
            
            printf("found proper vnode\n"); sleep(1);
            
            NSError *error = nil;
            NSData * tempData = [[NSData alloc] initWithContentsOfFile:[mntPath stringByAppendingString:@"com.apple.MobileGestalt.plist"]];
            
            NSPropertyListFormat* plistFormat = NULL;
            NSMutableDictionary *temp = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListMutableContainersAndLeaves format:plistFormat error:&error];
            
//            hexdump([tempData bytes], [tempData length]);
            
            NSMutableDictionary* cacheExtra = [temp valueForKey:@"CacheExtra"];
            
            [cacheExtra enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull __strong key, id  _Nonnull __strong value, BOOL * _Nonnull stop3) {
                NSLog(@"key %@, value %@", key, value);
                if ([key isEqualToString:@"oPeik/9e8lQWMszEjbPzng"]) {
                    printf("found key\n");
                    [value setValue:[NSNumber numberWithInt:2556] forKey: @"ArtworkDeviceSubType"]; // 2532, 2556, 2796
//                    [value setValue:@"phone" forKey: @"ArtworkDeviceIdiom"]; bricks your fucking phone don't do this please PLEASE
                    *stop3 = true;
                }
            }];
            
            NSLog(
                  @"%d %@",
                  [[NSFileManager defaultManager] fileExistsAtPath:[mntPath stringByAppendingString:@"com.apple.MobileGestalt.plist"]],
                  temp
                  );
            
            NSError *error2;
            NSData *_tempData = [NSPropertyListSerialization dataWithPropertyList: temp
                                                                           format: NSPropertyListBinaryFormat_v1_0
                                                                          options: 0
                                                                            error: &error2];
            
            // Get a pointer to the bytes of the original data
            uint8_t* buf = malloc([_tempData length] - 0x10);
            memcpy(buf, [_tempData bytes] + 0x10, [_tempData length] - 0x10);
            
            // Create a new NSData instance with the remaining data
            NSData *data = _tempData;
            
//            hexdump([data bytes], [data length]);
            
            NSLog(@"error serializing to xml: %@", error2);
            
            if (data == nil) {
                printf("NULL DATA!!\n");
                return;
            }
            
            NSString* temp2 = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/com.apple.MobileGestalt2.plist"];
            
            [[NSFileManager defaultManager] removeItemAtPath:temp2 error:NULL];
            
            BOOL writeStatus = [data writeToFile: temp2
                                         options: 0
                                           error: &error2];
            NSLog (@"error writing to file: %@", error2);
            if (!writeStatus) {
                return;
            }
            
            funVnodeOverwriteFileUnlimitSize([[mntPath stringByAppendingString:@"com.apple.MobileGestalt.plist"] UTF8String], [temp2 UTF8String]);
            
            error = nil;
            tempData = [[NSData alloc] initWithContentsOfFile:[mntPath stringByAppendingString:@"com.apple.MobileGestalt.plist"]];
            
            temp = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListMutableContainersAndLeaves format:plistFormat error:&error];
            
            NSLog(@"%@", temp);
            
            UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
        }
    }];
}


