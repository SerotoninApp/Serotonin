/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef proc_h
#define proc_h

struct proc {
    u64 p_list_le_next;
    u64 p_list_le_prev;
    u64 task;
    u64 p_pid;
    u64 p_fd_fd_ofiles;
    u64 object_size;
};

const struct proc proc_versions[] = {
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x60, .p_fd_fd_ofiles = 0xf8, .object_size = 0x538 },
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x60, .p_fd_fd_ofiles = 0xf8, .object_size = 0x730 },
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x60, .p_fd_fd_ofiles = 0xf8, .object_size = 0x580 },
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x60, .p_fd_fd_ofiles = 0xf8, .object_size = 0x778 },
    
    // Note: sizes below here are wrong idc
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0x110, .object_size = 0x4B0 }, // iOS 15.0 - 15.1.1 arm64
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0x100, .object_size = 0x4B0 }, // iOS 15.0 - 15.1.1 arm64e
    
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0xf8, .object_size = 0x4B0 }, // iOS 15.2 - 15.3.1 arm64
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0xf8, .object_size = 0x4B0 }, // iOS 15.2 - 15.3.1 arm64e
    
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0xf8, .object_size = 0x4B0 }, // iOS 15.4 - 15.7.8 arm64
    { .p_list_le_next = 0x0, .p_list_le_prev = 0x8, .task = 0x10, .p_pid = 0x68, .p_fd_fd_ofiles = 0xf8, .object_size = 0x4B0 }, // iOS 15.4 - 15.7.2 arm64e
};

typedef u64 proc_p_list_le_next_t;
typedef u64 proc_p_list_le_prev_t;
typedef u64 proc_task_t;
typedef i32 proc_p_pid_t;
typedef u64 proc_p_fd_fd_ofiles_t;

#endif /* proc_h */
