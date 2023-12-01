/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef uthread_h
#define uthread_h

struct uthread {
    u64 object_size;
};

const struct uthread uthread_versions[] = {
    { .object_size = 0x200 },
    { .object_size = 0x200 },
    { .object_size = 0x1b0 },
    { .object_size = 0x1b0 },
    
    // Note: sizes below here are wrong idc
    { .object_size = 0x1b0 }, // iOS 15.0 - 15.1.1 arm64
    { .object_size = 0x1b0 }, // iOS 15.0 - 15.1.1 arm64e
    
    { .object_size = 0x1b0 }, // iOS 15.2 - 15.3.1 arm64
    { .object_size = 0x1b0 }, // iOS 15.2 - 15.3.1 arm64e
    
    { .object_size = 0x1b0 }, // iOS 15.4 - 15.7.8 arm64
    { .object_size = 0x1b0 }, // iOS 15.4 - 15.7.8 arm64e
};

#endif /* uthread_h */
