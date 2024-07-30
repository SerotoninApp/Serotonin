//
//  troller.c
//  usprebooter
//
//  Created by LL on 29/11/23.
//
#include <mach/arm/kern_return.h>
#include "troller.h"
#include "xpc.h"
#include "xpc_connection.h"
#include "bootstrap.h"
#include <stdio.h>
#include <unistd.h>
#include <os/object.h>
#include <time.h>
#include <sys/errno.h>
#include "util.h"
#include "overwriter.h"

int userspaceReboot(void) {
    kern_return_t ret = 0;
    xpc_object_t xdict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(xdict, "cmd", 5);
    xpc_object_t xreply;
    ret = unlink("/private/var/mobile/Library/MemoryMaintenance/mmaintenanced");
    if (ret && errno != ENOENT) {
        fprintf(stderr, "could not delete mmaintenanced last reboot file\n");
        return -1;
    }
    xpc_connection_t connection = xpc_connection_create_mach_service("com.apple.mmaintenanced", NULL, 0);
    if (xpc_get_type(connection) == XPC_TYPE_ERROR) {
        char* desc = xpc_copy_description((__bridge xpc_object_t _Nonnull)(xpc_get_type(connection)));
        puts(desc);
        free(desc);
        return -1;
    }
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        char* desc = xpc_copy_description(event);
        puts(desc);
        free(desc);
    });
    xpc_connection_activate(connection);
    char* desc = xpc_copy_description(connection);
    puts(desc);
    printf("connection created\n");
    xpc_object_t reply = xpc_connection_send_message_with_reply_sync(connection, xdict);
    if (reply) {
        char* desc = xpc_copy_description(reply);
        puts(desc);
        free(desc);
        xpc_connection_cancel(connection);
        return 0;
    }

    return -1;
}

int go(bool isBeta, NSString* argument) {
    kern_return_t ret = 0;
//    copyLaunchd();
    NSString *mainBundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"serotoninroothelper"];
    spawnRoot(mainBundlePath, @[argument, @"", @""], nil, nil);
    overwrite_patchedlaunchd_kfd(isBeta);
//    codesignLaunchd();
    return ret;
}

//int go2(void) {
//    NSLog(@"Attempting unsandbox2...");
//    
//    return 0;
//}
