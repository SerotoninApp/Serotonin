#ifndef dynamic_info_h
#define dynamic_info_h

struct dynamic_info {
    // iOS version range
    struct {
        u8 major_start;
        u8 minor_start;
        u8 major_end;
        u8 minor_end;
    } ios_range;
    // struct fileglob
    u64 fileglob__fg_ops;
    u64 fileglob__fg_data;
    // struct fileops
    u64 fileops__fo_kqfilter;
    // struct fileproc
    // u64 fileproc__fp_iocount;
    // u64 fileproc__fp_vflags;
    // u64 fileproc__fp_flags;
    // u64 fileproc__fp_guard_attrs;
    // u64 fileproc__fp_glob;
    // u64 fileproc__fp_guard;
    // u64 fileproc__object_size;
    // struct fileproc_guard
    u64 fileproc_guard__fpg_guard;
    // struct kqworkloop
    u64 kqworkloop__kqwl_state;
    u64 kqworkloop__kqwl_p;
    u64 kqworkloop__kqwl_owner;
    u64 kqworkloop__kqwl_dynamicid;
    u64 kqworkloop__object_size;
    // struct pmap
    u64 pmap__tte;
    u64 pmap__ttep;
    // struct proc
    u64 proc__p_list__le_next;
    u64 proc__p_list__le_prev;
    u64 proc__p_pid;
    u64 proc__p_fd__fd_ofiles;
    u64 proc__object_size;
    // struct pseminfo
    u64 pseminfo__psem_usecount;
    u64 pseminfo__psem_uid;
    u64 pseminfo__psem_gid;
    u64 pseminfo__psem_name;
    u64 pseminfo__psem_semobject;
    // struct psemnode
    // u64 psemnode__pinfo;
    // u64 psemnode__padding;
    // u64 psemnode__object_size;
    // struct semaphore
    u64 semaphore__owner;
    // struct specinfo
    u64 specinfo__si_rdev;
    // struct task
    u64 task__map;
    u64 task__threads__next;
    u64 task__threads__prev;
    u64 task__itk_space;
    u64 task__object_size;
    // struct thread
    u64 thread__task_threads__next;
    u64 thread__task_threads__prev;
    u64 thread__map;
    u64 thread__thread_id;
    u64 thread__object_size;
    // struct uthread
    u64 uthread__object_size;
    // struct vm_map_entry
    u64 vm_map_entry__links__prev;
    u64 vm_map_entry__links__next;
    u64 vm_map_entry__links__start;
    u64 vm_map_entry__links__end;
    u64 vm_map_entry__store__entry__rbe_left;
    u64 vm_map_entry__store__entry__rbe_right;
    u64 vm_map_entry__store__entry__rbe_parent;
    // struct vnode
    u64 vnode__v_un__vu_specinfo;
    // struct _vm_map
    u64 _vm_map__hdr__links__prev;
    u64 _vm_map__hdr__links__next;
    u64 _vm_map__hdr__links__start;
    u64 _vm_map__hdr__links__end;
    u64 _vm_map__hdr__nentries;
    u64 _vm_map__hdr__rb_head_store__rbh_root;
    u64 _vm_map__pmap;
    u64 _vm_map__hint;
    u64 _vm_map__hole_hint;
    u64 _vm_map__holes_list;
    u64 _vm_map__object_size;
};

const struct dynamic_info kern_versions[] = {
    // 16.0-16.1
    {
        .ios_range = {16, 0, 16, 1},
        .fileglob__fg_ops = 0x28,
        .fileglob__fg_data = 0x40 - 8,
        .fileops__fo_kqfilter = 0x30,
        // .fileproc__fp_iocount = 0x0000,
        // .fileproc__fp_vflags = 0x0004,
        // .fileproc__fp_flags = 0x0008,
        // .fileproc__fp_guard_attrs = 0x000a,
        // .fileproc__fp_glob = 0x0010,
        // .fileproc__fp_guard = 0x0018,
        // .fileproc__object_size = 0x0020,
        .fileproc_guard__fpg_guard = 0x8,
        .kqworkloop__kqwl_state = 0x10,
        .kqworkloop__kqwl_p = 0x18,
        .kqworkloop__kqwl_owner = 0xd0,
        .kqworkloop__kqwl_dynamicid = 0xd0 + 0x18,
        .kqworkloop__object_size = 0x108,
        .pmap__tte = 0x0,
        .pmap__ttep = 0x8,
        .proc__p_list__le_next = 0x0,
        .proc__p_list__le_prev = 0x8,
        .proc__p_pid = 0x60,
        .proc__p_fd__fd_ofiles = 0xf8,
        .proc__object_size = 0x530,
        .pseminfo__psem_usecount = 0x04,
        .pseminfo__psem_uid = 0x0c,
        .pseminfo__psem_gid = 0x10,
        .pseminfo__psem_name = 0x14,
        .pseminfo__psem_semobject = 0x38,
        // .psemnode__pinfo = 0x0000,
        // .psemnode__padding = 0x0008,
        // .psemnode__object_size = 0x0010,
        .semaphore__owner = 0x28,
        .specinfo__si_rdev = 0x18,
        .task__map = 0x28,
        .task__threads__next = 0x80 - 0x28,
        .task__threads__prev = 0x80 - 0x28 + 8,
        .task__itk_space = 0x300,
        .task__object_size = 0x648,
        .thread__task_threads__next = 0x380 - 0x18,
        .thread__task_threads__prev = 0x380 - 0x18 + 8,
        .thread__map = 0x380,
        .thread__thread_id = 0x420,
        .thread__object_size = 0x4c8,
        .uthread__object_size = 0x200,
        .vm_map_entry__links__prev = 0x00,
        .vm_map_entry__links__next = 0x08,
        .vm_map_entry__links__start = 0x10,
        .vm_map_entry__links__end = 0x18,
        .vm_map_entry__store__entry__rbe_left = 0x20,
        .vm_map_entry__store__entry__rbe_right = 0x28,
        .vm_map_entry__store__entry__rbe_parent = 0x30,
        .vnode__v_un__vu_specinfo = 0x78,
        ._vm_map__hdr__links__prev = 0x00 + 0x10,
        ._vm_map__hdr__links__next = 0x08 + 0x10,
        ._vm_map__hdr__links__start = 0x10 + 0x10,
        ._vm_map__hdr__links__end = 0x18 + 0x10,
        ._vm_map__hdr__nentries = 0x30,
        ._vm_map__hdr__rb_head_store__rbh_root = 0x38,
        ._vm_map__pmap = 0x40,
        ._vm_map__hint = 0x90 + 0x08,
        ._vm_map__hole_hint = 0x90 + 0x10,
        ._vm_map__holes_list = 0x90 + 0x18,
        ._vm_map__object_size = 0x0,
    },
    // 16.2-16.3
    {
        .ios_range = {16, 2, 16, 3},
        .fileglob__fg_ops = 0x28,
        .fileglob__fg_data = 0x40 - 0x8,
        .fileops__fo_kqfilter = 0x30,
        // .fileproc__fp_iocount = 0x0000,
        // .fileproc__fp_vflags = 0x0004,
        // .fileproc__fp_flags = 0x0008,
        // .fileproc__fp_guard_attrs = 0x000a,
        // .fileproc__fp_glob = 0x0010,
        // .fileproc__fp_guard = 0x0018,
        // .fileproc__object_size = 0x0020,
        .fileproc_guard__fpg_guard = 0x8,
        .kqworkloop__kqwl_state = 0x10,
        .kqworkloop__kqwl_p = 0x18,
        .kqworkloop__kqwl_owner = 0xd0,
        .kqworkloop__kqwl_dynamicid = 0xd0 + 0x18,
        .kqworkloop__object_size = 0x108,
        .pmap__tte = 0x0,
        .pmap__ttep = 0x8,
        .proc__p_list__le_next = 0x0,
        .proc__p_list__le_prev = 0x8,
        .proc__p_pid = 0x60,
        .proc__p_fd__fd_ofiles = 0xf8,
        .proc__object_size = 0x538,
        .pseminfo__psem_usecount = 0x04,
        .pseminfo__psem_uid = 0x0c,
        .pseminfo__psem_gid = 0x10,
        .pseminfo__psem_name = 0x14,
        .pseminfo__psem_semobject = 0x38,
        // .psemnode__pinfo = 0x0000,
        // .psemnode__padding = 0x0008,
        // .psemnode__object_size = 0x0010,
        .semaphore__owner = 0x28,
        .specinfo__si_rdev = 0x18,
        .task__map = 0x28,
        .task__threads__next = 0x80 - 0x28,
        .task__threads__prev = 0x80 - 0x28 + 0x8,
        .task__itk_space = 0x300,
        .task__object_size = 0x628,
        .thread__task_threads__next = 0x368 - 0x18,
        .thread__task_threads__prev = 0x368 - 0x18 + 0x8,
        .thread__map = 0x368,
        .thread__thread_id = 0x400,
        .thread__object_size = 0x4a8,
        .uthread__object_size = 0x200,
        .vm_map_entry__links__prev = 0x00,
        .vm_map_entry__links__next = 0x08,
        .vm_map_entry__links__start = 0x10,
        .vm_map_entry__links__end = 0x18,
        .vm_map_entry__store__entry__rbe_left = 0x20,
        .vm_map_entry__store__entry__rbe_right = 0x28,
        .vm_map_entry__store__entry__rbe_parent = 0x30,
        .vnode__v_un__vu_specinfo = 0x78,
        ._vm_map__hdr__links__prev = 0x00 + 0x10,
        ._vm_map__hdr__links__next = 0x08 + 0x10,
        ._vm_map__hdr__links__start = 0x10 + 0x10,
        ._vm_map__hdr__links__end = 0x18 + 0x10,
        ._vm_map__hdr__nentries = 0x30,
        ._vm_map__hdr__rb_head_store__rbh_root = 0x38,
        ._vm_map__pmap = 0x40,
        ._vm_map__hint = 0x90 + 0x08,
        ._vm_map__hole_hint = 0x90 + 0x10,
        ._vm_map__holes_list = 0x90 + 0x18,
        ._vm_map__object_size = 0xc0,
    },
    // 16.4-16.6
    {
        .ios_range = {16, 4, 16, 6},
        .fileglob__fg_ops = 0x28,
        .fileglob__fg_data = 0x40 - 8,
        .fileops__fo_kqfilter = 0x30,
        .fileproc_guard__fpg_guard = 0x8,
        .kqworkloop__kqwl_state = 0x10,
        .kqworkloop__kqwl_p = 0x18,
        .kqworkloop__kqwl_owner = 0xd0,
        .kqworkloop__kqwl_dynamicid = 0xd0 + 0x18,
        .kqworkloop__object_size = 0x108,
        .pmap__tte = 0x0,
        .pmap__ttep = 0x8,
        .proc__p_list__le_prev = 0x8,
        .proc__p_pid = 0x60,
        .proc__p_fd__fd_ofiles = 0xf8,
        .proc__object_size = 0x730,
        .pseminfo__psem_usecount = 0x04,
        .pseminfo__psem_uid = 0x0c,
        .pseminfo__psem_semobject = 0x38,
        .semaphore__owner = 0x28,
        .specinfo__si_rdev = 0x18,
            .task__map = 0x28,
            .thread__thread_id = 0x410,
            .vm_map_entry__links__prev = 0x00,
            .vm_map_entry__links__next = 0x08,
            .vm_map_entry__links__start = 0x10,
            .vm_map_entry__links__end = 0x18,
            .vm_map_entry__store__entry__rbe_left = 0x20,
            .vm_map_entry__store__entry__rbe_right = 0x28,
            .vm_map_entry__store__entry__rbe_parent = 0x30,
            .vnode__v_un__vu_specinfo = 0x78,
            ._vm_map__hdr__links__prev = 0x00 + 0x10,
            ._vm_map__hdr__links__next = 0x08 + 0x10,
            ._vm_map__hdr__nentries = 0x30,
            ._vm_map__pmap = 0x40,
            ._vm_map__hint = 0x90 + 0x08,
            ._vm_map__hole_hint = 0x90 + 0x10,
            ._vm_map__holes_list = 0x90 + 0x18,
    },
};

// get for device
const struct dynamic_info* get_kern_version(const char* version) {
    printf("[i] iOS version: %s\n", version);
    char* major = strtok(version, ".");
    char* minor = strtok(NULL, ".");
    u8 major_int = atoi(major);
    u8 minor_int = atoi(minor);
    for (int i = 0; i < sizeof(kern_versions) / sizeof(struct dynamic_info); i++) {
        if (major_int == kern_versions[i].ios_range.major_start && minor_int >= kern_versions[i].ios_range.minor_start && minor_int <= kern_versions[i].ios_range.minor_end) {
            printf("[i] iOS %s detected, selected offsets for range(%d.%d-%d.%d)", version, kern_versions[i].ios_range.major_start, kern_versions[i].ios_range.minor_start, kern_versions[i].ios_range.major_end, kern_versions[i].ios_range.minor_end);
            return &kern_versions[i];
        }
    }
    return NULL;
}

#endif /* dynamic_info_h */