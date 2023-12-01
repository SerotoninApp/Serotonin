/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef task_h
#define task_h

struct task {
    u64 map;
    u64 threads_next;
    u64 threads_prev;
    u64 itk_space;
    u64 object_size;
};

const struct task task_versions[] = {
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x300, .object_size = 0x648 },
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x300, .object_size = 0x640 },
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x300, .object_size = 0x658 },
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x300, .object_size = 0x658 },
    
    // Note: sizes below here are wrong idc
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x330, .object_size = 0x6B0 }, // iOS 15.0 - 15.1.1 arm64
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x330, .object_size = 0x6B0 }, // iOS 15.0 - 15.1.1 arm64e
    
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x308, .object_size = 0x6B0 }, // iOS 15.2 - 15.3.1 arm64
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x308, .object_size = 0x6B0 }, // iOS 15.2 - 15.3.1 arm64e
    
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x308, .object_size = 0x6B0 }, // iOS 15.4 - 15.7.8 arm64
    { .map = 0x28, .threads_next = 0x58, .threads_prev = 0x60, .itk_space = 0x308, .object_size = 0x6B0 }, // iOS 15.4 - 15.7.2 arm64e
};

typedef u64 task_map_t;
typedef u64 task_threads_next_t;
typedef u64 task_threads_prev_t;
typedef u64 task_itk_space_t;

#endif /* task_h */
