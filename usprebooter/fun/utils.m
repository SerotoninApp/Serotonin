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
#import <dlfcn.h>
#import "proc.h"
#import "vnode.h"
#import "krw.h"
#import "helpers.h"
#import "offsets.h"
#import "thanks_opa334dev_htrowii.h"
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
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/private/var/tmp");
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
    do_kclose();
    sleep(1);
    xpc_crasher("com.apple.cfprefsd.daemon");
    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
    
    return 0;
}

int removeSMSCache(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
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
    int open_fd = open([mntPath stringByAppendingString:@"/can_i_remove_file"].UTF8String, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    const char* data = "PLZ_GIVE_ME_GIRLFRIENDS!@#";
    write(open_fd, data, strlen(data));
    close(open_fd);
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int VarMobileWriteFolderTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //create
    mkdir([mntPath stringByAppendingString:@"/can_i_remove_folder"].UTF8String, 0755);
    
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

int VarMobileRemoveFolderTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //remove
    [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/can_i_remove_folder"] error:nil];
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int setSuperviseMode(BOOL enable) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];

    uint64_t configurationprofiles_vnode = getVnodeAtPathByChdir("/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles");
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
    
    funVnodeOverwriteFileUnlimitSize(plistPath.UTF8String, rewrittenPlistPath.UTF8String);
    
    return 0;
}

void HexDump(uint64_t addr, size_t size) {
    void *data = malloc(size);
    kreadbuf(addr, data, size);
    char ascii[17];
    size_t i, j;
    ascii[16] = '\0';
    for (i = 0; i < size; ++i) {
        if ((i % 16) == 0)
        {
            printf("[0x%016llx+0x%03zx] ", addr, i);
//            printf("[0x%016llx] ", i + addr);
        }
        
        printf("%02X ", ((unsigned char*)data)[i]);
        if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
            ascii[i % 16] = ((unsigned char*)data)[i];
        } else {
            ascii[i % 16] = '.';
        }
        if ((i+1) % 8 == 0 || i+1 == size) {
            printf(" ");
            if ((i+1) % 16 == 0) {
                printf("|  %s \n", ascii);
            } else if (i+1 == size) {
                ascii[(i+1) % 16] = '\0';
                if ((i+1) % 16 <= 8) {
                    printf(" ");
                }
                for (j = (i+1) % 16; j < 16; ++j) {
                    printf("   ");
                }
                printf("|  %s \n", ascii);
            }
        }
    }
    free(data);
}

bool sandbox_escape_can_i_access_file(char* path, int mode) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    uint64_t vnode = getVnodeAtPathByChdir([[NSString stringWithUTF8String:path] stringByDeletingLastPathComponent].UTF8String);
    uint64_t orig_to_v_data = createFolderAndRedirect(vnode, mntPath);
    
    NSString *mountedPath = [NSString stringWithFormat:@"%@/%@", mntPath, [[NSString stringWithUTF8String:path] lastPathComponent]];
    
    bool ret = false;
    
    if(access(mountedPath.UTF8String, mode) == 0) {
        ret = true;
    }

    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return ret;
}
