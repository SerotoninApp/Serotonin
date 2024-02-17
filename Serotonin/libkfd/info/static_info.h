/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef static_info_h
#define static_info_h

/*
 * makedefs/MakeInc.def
 */

uint64_t arm64_link_addr = 0;
#define ARM64_LINK_ADDR    arm64_link_addr

/*
 * osfmk/arm64/proc_reg.h
 */

#define ARM_PGSHIFT    (14ull)
#define ARM_PGBYTES    (1ull << ARM_PGSHIFT)
#define ARM_PGMASK     (ARM_PGBYTES - 1ull)

unsigned long long t1sz_boot = 0;
#define T1SZ_BOOT    t1sz_boot

#define AP_RWNA    (0x0ull << 6)
#define AP_RWRW    (0x1ull << 6)
#define AP_RONA    (0x2ull << 6)
#define AP_RORO    (0x3ull << 6)

#define ARM_PTE_TYPE              0x0000000000000003ull
#define ARM_PTE_TYPE_VALID        0x0000000000000003ull
#define ARM_PTE_TYPE_MASK         0x0000000000000002ull
#define ARM_TTE_TYPE_L3BLOCK      0x0000000000000002ull
#define ARM_PTE_ATTRINDX          0x000000000000001cull
#define ARM_PTE_NS                0x0000000000000020ull
#define ARM_PTE_AP                0x00000000000000c0ull
#define ARM_PTE_SH                0x0000000000000300ull
#define ARM_PTE_AF                0x0000000000000400ull
#define ARM_PTE_NG                0x0000000000000800ull
#define ARM_PTE_ZERO1             0x000f000000000000ull
#define ARM_PTE_HINT              0x0010000000000000ull
#define ARM_PTE_PNX               0x0020000000000000ull
#define ARM_PTE_NX                0x0040000000000000ull
#define ARM_PTE_ZERO2             0x0380000000000000ull
#define ARM_PTE_WIRED             0x0400000000000000ull
#define ARM_PTE_WRITEABLE         0x0800000000000000ull
#define ARM_PTE_ZERO3             0x3000000000000000ull
#define ARM_PTE_COMPRESSED_ALT    0x4000000000000000ull
#define ARM_PTE_COMPRESSED        0x8000000000000000ull

#define ARM_TTE_VALID         0x0000000000000001ull
#define ARM_TTE_TYPE_MASK     0x0000000000000002ull
#define ARM_TTE_TYPE_TABLE    0x0000000000000002ull
#define ARM_TTE_TYPE_BLOCK    0x0000000000000000ull
#define ARM_TTE_TABLE_MASK    0x0000fffffffff000ull
#define ARM_TTE_PA_MASK       0x0000fffffffff000ull

#define ARM_16K_TT_L0_SIZE          0x0000800000000000ull
#define ARM_16K_TT_L0_OFFMASK       0x00007fffffffffffull
#define ARM_16K_TT_L0_SHIFT         47
#define ARM_16K_TT_L0_INDEX_MASK    0x0000800000000000ull

#define ARM_16K_TT_L1_SIZE          0x0000001000000000ull
#define ARM_16K_TT_L1_OFFMASK       0x0000000fffffffffull
#define ARM_16K_TT_L1_SHIFT         36
#define ARM_16K_TT_L1_INDEX_MASK    0x00007ff000000000ull

#define ARM_16K_TT_L2_SIZE          0x0000000002000000ull
#define ARM_16K_TT_L2_OFFMASK       0x0000000001ffffffull
#define ARM_16K_TT_L2_SHIFT         25
#define ARM_16K_TT_L2_INDEX_MASK    0x0000000ffe000000ull

#define ARM_16K_TT_L3_SIZE          0x0000000000004000ull
#define ARM_16K_TT_L3_OFFMASK       0x0000000000003fffull
#define ARM_16K_TT_L3_SHIFT         14
#define ARM_16K_TT_L3_INDEX_MASK    0x0000000001ffc000ull

/*
 * osfmk/arm/pmap/pmap_pt_geometry.h
 */

#define PMAP_TT_L0_LEVEL    0x0
#define PMAP_TT_L1_LEVEL    0x1
#define PMAP_TT_L2_LEVEL    0x2
#define PMAP_TT_L3_LEVEL    0x3

/*
 * osfmk/kern/bits.h
 */

#define BIT(b)    (1ULL << (b))

/*
 * osfmk/arm/machine_routines.h
 */

#define ONES(x)          (BIT((x))-1)
#define PTR_MASK         ONES(64-T1SZ_BOOT)
#define PAC_MASK         (~PTR_MASK)
#define SIGN(p)          ((p) & BIT(55))
#define UNSIGN_PTR(p)    (SIGN(p) ? ((p) | PAC_MASK) : ((p) & ~PAC_MASK))

/*
 * osfmk/kern/kalloc.h
 */

#define KHEAP_MAX_SIZE    (32ull * 1024ull)

/*
 * osfmk/ipc/ipc_init.c
 */

const vm_size_t msg_ool_size_small = KHEAP_MAX_SIZE;

/*
 * osfmk/vm/vm_map_store.h
 */

struct vm_map_store {
    struct {
        u64 rbe_left;
        u64 rbe_right;
        u64 rbe_parent;
    } entry;
};

struct vm_map_links {
    u64 prev;
    u64 next;
    u64 start;
    u64 end;
};

struct vm_map_header {
    struct vm_map_links links;
    i32 nentries;
    u16 page_shift;
    u16
        entries_pageable:1,
        __padding:15;
    struct {
        u64 rbh_root;
    } rb_head_store;
};

/*
 * osfmk/vm/vm_map.h
 */

struct vm_map_entry {
    struct vm_map_links links;
    struct vm_map_store store;
    union {
        u64 vme_object_value;
        struct {
            u64 vme_atomic:1;
            u64 is_sub_map:1;
            u64 vme_submap:60;
        };
        struct {
            u32 vme_ctx_atomic:1;
            u32 vme_ctx_is_sub_map:1;
            u32 vme_context:30;
            u32 vme_object;
        };
    };
    u64
        vme_alias:12,
        vme_offset:52,
        is_shared:1,
        __unused1:1,
        in_transition:1,
        needs_wakeup:1,
        behavior:2,
        needs_copy:1,
        protection:3,
        used_for_tpro:1,
        max_protection:4,
        inheritance:2,
        use_pmap:1,
        no_cache:1,
        vme_permanent:1,
        superpage_size:1,
        map_aligned:1,
        zero_wired_pages:1,
        used_for_jit:1,
        pmap_cs_associated:1,
        iokit_acct:1,
        vme_resilient_codesign:1,
        vme_resilient_media:1,
        __unused2:1,
        vme_no_copy_on_read:1,
        translated_allow_execute:1,
        vme_kernel_object:1;
    u16 wired_count;
    u16 user_wired_count;
};

struct _vm_map {
    u64 lock[2];
    struct vm_map_header hdr;
    u64 pmap;
    u64 size;
    u64 size_limit;
    u64 data_limit;
    u64 user_wire_limit;
    u64 user_wire_size;
#if TARGET_MACOS
    u64 vmmap_high_start;
#else /* TARGET_MACOS */
    u64 user_range[4];
#endif /* TARGET_MACOS */
    union {
        u64 vmu1_highest_entry_end;
        u64 vmu1_lowest_unnestable_start;
    } vmu1;
    u64 hint;
    union {
        u64 vmmap_hole_hint;
        u64 vmmap_corpse_footprint;
    } vmmap_u_1;
    union {
        u64 _first_free;
        u64 _holes;
    } f_s;
    u32 map_refcnt;
    u32
        wait_for_space:1,
        wiring_required:1,
        no_zero_fill:1,
        mapped_in_other_pmaps:1,
        switch_protect:1,
        disable_vmentry_reuse:1,
        map_disallow_data_exec:1,
        holelistenabled:1,
        is_nested_map:1,
        map_disallow_new_exec:1,
        jit_entry_exists:1,
        has_corpse_footprint:1,
        terminated:1,
        is_alien:1,
        cs_enforcement:1,
        cs_debugged:1,
        reserved_regions:1,
        single_jit:1,
        never_faults:1,
        uses_user_ranges:1,
        pad:12;
    u32 timestamp;
};

/*
 * osfmk/arm/pmap/pmap.h
 */

struct pmap {
    u64 tte;
    u64 ttep;
    u64 min;
    u64 max;
    u64 pmap_pt_attr;
    u64 ledger;
    u64 rwlock[2];
    struct {
        u64 next;
        u64 prev;
    } pmaps;
    u64 tt_entry_free;
    u64 nested_pmap;
    u64 nested_region_addr;
    u64 nested_region_size;
    u64 nested_region_true_start;
    u64 nested_region_true_end;
    u64 nested_region_asid_bitmap;
    u32 nested_region_asid_bitmap_size;
    u64 reserved0;
    u64 reserved1;
    u64 reserved2;
    u64 reserved3;
    i32 ref_count;
    i32 nested_count;
    u32 nested_no_bounds_refcnt;
    u16 hw_asid;
    u8 sw_asid;
    bool reserved4;
    bool pmap_vm_map_cs_enforced;
    bool reserved5;
    u32 reserved6;
    u8 reserved7;
    u8 type;
    bool reserved8;
    bool reserved9;
    bool is_rosetta;
    bool nx_enabled;
    bool is_64bit;
    bool nested_has_no_bounds_ref;
    bool nested_bounds_set;
    bool disable_jop;
    bool reserved11;
};

/*
 * bsd/kern/kern_guarded.c
 */

#define GUARD_REQUIRED (1u << 1)

/*
 * bsd/sys/file_internal.h
 */

struct fileproc_guard {
    u64 fpg_wset;
    u64 fpg_guard;
};

struct fileproc {
    u32 fp_iocount;
    u32 fp_vflags;
    u16 fp_flags;
    u16 fp_guard_attrs;
    u64 fp_glob;
    union {
        u64 fp_wset;
        u64 fp_guard;
    };
};

typedef enum {
    DTYPE_VNODE = 1,
    DTYPE_SOCKET,
    DTYPE_PSXSHM,
    DTYPE_PSXSEM,
    DTYPE_KQUEUE,
    DTYPE_PIPE,
    DTYPE_FSEVENTS,
    DTYPE_ATALK,
    DTYPE_NETPOLICY,
    DTYPE_CHANNEL,
    DTYPE_NEXUS
} file_type_t;

struct fileops {
    file_type_t fo_type;
    void* fo_read;
    void* fo_write;
    void* fo_ioctl;
    void* fo_select;
    void* fo_close;
    void* fo_kqfilter;
    void* fo_drain;
};

struct fileglob {
    struct {
        u64 le_next;
        u64 le_prev;
    } f_msglist;
    u32 fg_flag;
    u32 fg_count;
    u32 fg_msgcount;
    i32 fg_lflags;
    u64 fg_cred;
    u64 fg_ops;
    i64 fg_offset;
    u64 fg_data;
    u64 fg_vn_data;
    u64 fg_lock[2];
};

/*
 * bsd/sys/perfmon_private.h
 */

struct perfmon_layout {
    u16 pl_counter_count;
    u16 pl_fixed_offset;
    u16 pl_fixed_count;
    u16 pl_unit_count;
    u16 pl_reg_count;
    u16 pl_attr_count;
};

typedef char perfmon_name_t[16];

struct perfmon_event {
    char pe_name[32];
    u64 pe_number;
    u16 pe_counter;
};

struct perfmon_attr {
    perfmon_name_t pa_name;
    u64 pa_value;
};

struct perfmon_spec {
    struct perfmon_event* ps_events;
    struct perfmon_attr* ps_attrs;
    u16 ps_event_count;
    u16 ps_attr_count;
};

enum perfmon_ioctl {
    PERFMON_CTL_ADD_EVENT = _IOWR('P', 5, struct perfmon_event),
    PERFMON_CTL_SPECIFY = _IOWR('P', 10, struct perfmon_spec),
};

/*
 * osfmk/kern/perfmon.h
 */

enum perfmon_kind {
    perfmon_cpmu,
    perfmon_upmu,
    perfmon_kind_max,
};

struct perfmon_source {
    const char* ps_name;
    const perfmon_name_t* ps_register_names;
    const perfmon_name_t* ps_attribute_names;
    struct perfmon_layout ps_layout;
    enum perfmon_kind ps_kind;
    bool ps_supported;
};

#define PERFMON_SPEC_MAX_ATTR_COUNT    (32)

/*
 * osfmk/machine/machine_perfmon.h
 */

struct perfmon_counter {
    u64 pc_number;
};

struct perfmon_config {
    struct perfmon_source* pc_source;
    struct perfmon_spec pc_spec;
    u16 pc_attr_ids[PERFMON_SPEC_MAX_ATTR_COUNT];
    struct perfmon_counter* pc_counters;
    u64 pc_counters_used;
    u64 pc_attrs_used;
    bool pc_configured:1;
};

/*
 * bsd/dev/dev_perfmon.c
 */

struct perfmon_device {
    void* pmdv_copyout_buf;
    u64 pmdv_mutex[2];
    struct perfmon_config* pmdv_config;
    bool pmdv_allocated;
};

/*
 * bsd/pthread/workqueue_syscalls.h
 */

#define KQ_WORKLOOP_CREATE     0x01
#define KQ_WORKLOOP_DESTROY    0x02

#define KQ_WORKLOOP_CREATE_SCHED_PRI      0x01
#define KQ_WORKLOOP_CREATE_SCHED_POL      0x02
#define KQ_WORKLOOP_CREATE_CPU_PERCENT    0x04

struct kqueue_workloop_params {
    i32 kqwlp_version;
    i32 kqwlp_flags;
    u64 kqwlp_id;
    i32 kqwlp_sched_pri;
    i32 kqwlp_sched_pol;
    i32 kqwlp_cpu_percent;
    i32 kqwlp_cpu_refillms;
} __attribute__((packed));

/*
 * bsd/pthread/workqueue_internal.h
 */

struct workq_threadreq_s {
    union {
        u64 tr_entry[3];
        u64 tr_link[1];
        u64 tr_thread;
    };
    u16 tr_count;
    u8 tr_flags;
    u8 tr_state;
    u8 tr_qos;
    u8 tr_kq_override_index;
    u8 tr_kq_qos_index;
};

/*
 * bsd/sys/event.h
 */

struct kqtailq {
    u64 tqh_first;
    u64 tqh_last;
};

/*
 * bsd/sys/eventvar.h
 */

__options_decl(kq_state_t, u16, {
    KQ_SLEEP         = 0x0002,
    KQ_PROCWAIT      = 0x0004,
    KQ_KEV32         = 0x0008,
    KQ_KEV64         = 0x0010,
    KQ_KEV_QOS       = 0x0020,
    KQ_WORKQ         = 0x0040,
    KQ_WORKLOOP      = 0x0080,
    KQ_PROCESSING    = 0x0100,
    KQ_DRAIN         = 0x0200,
    KQ_DYNAMIC       = 0x0800,
    KQ_R2K_ARMED     = 0x1000,
    KQ_HAS_TURNSTILE = 0x2000,
});

struct kqueue {
    u64 kq_lock[2];
    kq_state_t kq_state;
    u16 kq_level;
    u32 kq_count;
    u64 kq_p;
    u64 kq_knlocks[1];
};

struct kqworkloop {
    struct kqueue kqwl_kqueue;
    struct kqtailq kqwl_queue[6];
    struct kqtailq kqwl_suppressed;
    struct workq_threadreq_s kqwl_request;
    u64 kqwl_preadopt_tg;
    u64 kqwl_statelock[2];
    u64 kqwl_owner;
    u32 kqwl_retains;
    u8 kqwl_wakeup_qos;
    u8 kqwl_iotier_override;
    u16 kqwl_preadopt_tg_needs_redrive;
    u64 kqwl_turnstile;
    u64 kqwl_dynamicid;
    u64 kqwl_params;
    u64 kqwl_hashlink[2];
};

/*
 * bsd/kern/posix_sem.c
 */

struct pseminfo {
    u32 psem_flags;
    u32 psem_usecount;
    u16 psem_mode;
    u32 psem_uid;
    u32 psem_gid;
    char psem_name[32];
    u64 psem_semobject;
    u64 psem_label;
    i32 psem_creator_pid;
    u64 psem_creator_uniqueid;
};

struct psemnode {
    u64 pinfo;
    u64 padding;
};

/*
 * osfmk/kern/sync_sema.h
 */

struct semaphore {
    struct {
        u64 next;
        u64 prev;
    } task_link;
    char waitq[24];
    u64 owner;
    u64 port;
    u32 ref_count;
    i32 count;
};

/*
 * bsd/sys/vnode_internal.h
 */

struct vnode {
    u64 v_lock[2];
    u64 v_freelist[2];
    u64 v_mntvnodes[2];
    u64 v_ncchildren[2];
    u64 v_nclinks[1];
    u64 v_defer_reclaimlist;
    u32 v_listflag;
    u32 v_flag;
    u16 v_lflag;
    u8 v_iterblkflags;
    u8 v_references;
    i32 v_kusecount;
    i32 v_usecount;
    i32 v_iocount;
    u64 v_owner;
    u16 v_type;
    u16 v_tag;
    u32 v_id;
    union {
        u64 vu_mountedhere;
        u64 vu_socket;
        u64 vu_specinfo;
        u64 vu_fifoinfo;
        u64 vu_ubcinfo;
    } v_un;
    // ...
};

/*
 * bsd/miscfs/specfs/specdev.h
 */

struct specinfo {
    u64 si_hashchain;
    u64 si_specnext;
    i64 si_flags;
    i32 si_rdev;
    i32 si_opencount;
    i32 si_size;
    i64 si_lastr;
    u64 si_devsize;
    u8 si_initted;
    u8 si_throttleable;
    u16 si_isssd;
    u32 si_devbsdunit;
    u64 si_throttle_mask;
};

/*
 * bsd/sys/proc_info.h
 */

#define PROC_INFO_CALL_LISTPIDS             0x1
#define PROC_INFO_CALL_PIDINFO              0x2
#define PROC_INFO_CALL_PIDFDINFO            0x3
#define PROC_INFO_CALL_KERNMSGBUF           0x4
#define PROC_INFO_CALL_SETCONTROL           0x5
#define PROC_INFO_CALL_PIDFILEPORTINFO      0x6
#define PROC_INFO_CALL_TERMINATE            0x7
#define PROC_INFO_CALL_DIRTYCONTROL         0x8
#define PROC_INFO_CALL_PIDRUSAGE            0x9
#define PROC_INFO_CALL_PIDORIGINATORINFO    0xa
#define PROC_INFO_CALL_LISTCOALITIONS       0xb
#define PROC_INFO_CALL_CANUSEFGHW           0xc
#define PROC_INFO_CALL_PIDDYNKQUEUEINFO     0xd
#define PROC_INFO_CALL_UDATA_INFO           0xe
#define PROC_INFO_CALL_SET_DYLD_IMAGES      0xf
#define PROC_INFO_CALL_TERMINATE_RSR        0x10

struct vinfo_stat {
    u32 vst_dev;
    u16 vst_mode;
    u16 vst_nlink;
    u64 vst_ino;
    u32 vst_uid;
    u32 vst_gid;
    i64 vst_atime;
    i64 vst_atimensec;
    i64 vst_mtime;
    i64 vst_mtimensec;
    i64 vst_ctime;
    i64 vst_ctimensec;
    i64 vst_birthtime;
    i64 vst_birthtimensec;
    i64 vst_size;
    i64 vst_blocks;
    i32 vst_blksize;
    u32 vst_flags;
    u32 vst_gen;
    u32 vst_rdev;
    i64 vst_qspare[2];
};

#define PROC_PIDFDVNODEINFO         1
#define PROC_PIDFDVNODEPATHINFO     2
#define PROC_PIDFDSOCKETINFO        3
#define PROC_PIDFDPSEMINFO          4
#define PROC_PIDFDPSHMINFO          5
#define PROC_PIDFDPIPEINFO          6
#define PROC_PIDFDKQUEUEINFO        7
#define PROC_PIDFDATALKINFO         8
#define PROC_PIDFDKQUEUE_EXTINFO    9
#define PROC_PIDFDCHANNELINFO       10

struct proc_fileinfo {
    u32 fi_openflags;
    u32 fi_status;
    i64 fi_offset;
    i32 fi_type;
    u32 fi_guardflags;
};

struct psem_info {
    struct vinfo_stat psem_stat;
    char psem_name[1024];
};

struct psem_fdinfo {
    struct proc_fileinfo pfi;
    struct psem_info pseminfo;
};

#define PROC_PIDDYNKQUEUE_INFO       0
#define PROC_PIDDYNKQUEUE_EXTINFO    1

struct kqueue_info {
    struct vinfo_stat kq_stat;
    u32 kq_state;
    u32 rfu_1;
};

struct kqueue_dyninfo {
    struct kqueue_info kqdi_info;
    u64 kqdi_servicer;
    u64 kqdi_owner;
    u32 kqdi_sync_waiters;
    u8 kqdi_sync_waiter_qos;
    u8 kqdi_async_qos;
    u16 kqdi_request_state;
    u8 kqdi_events_qos;
    u8 kqdi_pri;
    u8 kqdi_pol;
    u8 kqdi_cpupercent;
    u8 _kqdi_reserved0[4];
    u64 _kqdi_reserved1[4];
};

#endif /* static_info_h */