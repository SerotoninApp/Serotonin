/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef kqworkloop_h
#define kqworkloop_h

struct kqworkloop {
    u64 kqwl_state;
    u64 kqwl_p;
    u64 kqwl_owner;
    u64 kqwl_dynamicid;
    u64 object_size;
};

const struct kqworkloop kqworkloop_versions[] = {
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 },
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 },
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 },
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 },
    
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.0 - 15.1.1 arm64
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.0 - 15.1.1 arm64e
    
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.2 - 15.3.1 arm64
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.2 - 15.3.1 arm64e
    
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.4 - 15.7.8 arm64
    { .kqwl_state = 0x10, .kqwl_p = 0x18, .kqwl_owner = 0xd0, .kqwl_dynamicid = 0xe8, .object_size = 0x108 }, // iOS 15.4 - 15.7.2 arm64e
};

typedef u16 kqworkloop_kqwl_state_t;
typedef u64 kqworkloop_kqwl_p_t;
typedef u64 kqworkloop_kqwl_owner_t;
typedef u64 kqworkloop_kqwl_dynamicid_t;

#endif /* kqworkloop_h */
