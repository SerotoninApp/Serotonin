/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef thread_h
#define thread_h

struct thread {
    u64 task_threads_next;
    u64 task_threads_prev;
    u64 map;
    u64 thread_id;
    u64 object_size;
};

const struct thread thread_versions[] = {
    { .task_threads_next = 0x368, .task_threads_prev = 0x370, .map = 0x380, .thread_id = 0x420, .object_size = 0x4c8 },
    { .task_threads_next = 0x368, .task_threads_prev = 0x370, .map = 0x380, .thread_id = 0x418, .object_size = 0x4c0 },
    { .task_threads_next = 0x3c0, .task_threads_prev = 0x3c8, .map = 0x3d8, .thread_id = 0x490, .object_size = 0x650 },
    { .task_threads_next = 0x3c0, .task_threads_prev = 0x3c8, .map = 0x3d8, .thread_id = 0x490, .object_size = 0x650 },
    
    // Note: sizes below here are wrong idc
    { .task_threads_next = 0x420, .task_threads_prev = 0x428, .map = 0x438, .thread_id = 0x578, .object_size = 0x610 }, // iOS 15.0 - 15.1.1 arm64
    { .task_threads_next = 0x400, .task_threads_prev = 0x408, .map = 0x418, .thread_id = 0x560, .object_size = 0x610 }, // iOS 15.0 - 15.1.1 arm64e
    
    { .task_threads_next = 0x3b0, .task_threads_prev = 0x3b8, .map = 0x3c8, .thread_id = 0x460, .object_size = 0x610 }, // iOS 15.2 - 15.3.1 arm64
    { .task_threads_next = 0x388, .task_threads_prev = 0x390, .map = 0x3a0, .thread_id = 0x438, .object_size = 0x610 }, // iOS 15.2 - 15.3.1 arm64e
    
    { .task_threads_next = 0x3a8, .task_threads_prev = 0x3b0, .map = 0x3c0, .thread_id = 0x458, .object_size = 0x610 }, // iOS 15.4 - 15.7.8 arm64
    { .task_threads_next = 0x388, .task_threads_prev = 0x390, .map = 0x3a0, .thread_id = 0x440, .object_size = 0x610 }, // iOS 15.4 - 15.7.2 arm64e
};

typedef u64 thread_task_threads_next_t;
typedef u64 thread_task_threads_prev_t;
typedef u64 thread_map_t;
typedef u64 thread_thread_id_t;

#endif /* thread_h */
