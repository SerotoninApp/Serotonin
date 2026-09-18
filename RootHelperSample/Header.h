//
//  Header.h
//  TaskPortHaxxApp
//
//  Created by Duy Tran on 24/10/25.
//

@import Darwin;
#include <crt_externs.h>

#ifdef __arm64e__
#   define xpaci(x) __asm__ volatile("xpaci %0" : "+r"(x))
#else
#   define xpaci(x) (x &= 0xFFFFFFFFF)
#endif

#define msgh_request_port    msgh_local_port
#define MACH_MSGH_BITS_REQUEST(bits)    MACH_MSGH_BITS_LOCAL(bits)
#define msgh_reply_port        msgh_remote_port
#define MACH_MSGH_BITS_REPLY(bits)    MACH_MSGH_BITS_REMOTE(bits)
#define MIG_RETURN_ERROR(X, code)    {\
                ((mig_reply_error_t *)X)->RetCode = code;\
                ((mig_reply_error_t *)X)->NDR = NDR_record;\
                return;\
                }

#define RemoteArbCall(pc, ...) RemoteArbCallInternal((#pc), (uint64_t)(pc), (uint64_t[]){__VA_ARGS__}, sizeof((uint64_t[]){__VA_ARGS__})/sizeof(uint64_t))
uint64_t RemoteArbCallInternal(char *name, uint64_t pc, uint64_t args[], int argCount);
void RemoteChangeLR(uint64_t newLR);
uint64_t RemoteSignPACIA(uint64_t address, uint64_t modifier);
uint64_t RemoteRead64(uint64_t address);
uint32_t RemoteRead32(uint64_t address);
void RemoteWrite32(uint64_t address, uint32_t value);
void RemoteWrite64(uint64_t address, uint64_t value);
void RemoteWriteMemory(uint64_t address, const void *data, size_t length);
void RemoteWriteString(uint64_t address, const char *string);
void RemoteDetach(void);
kern_return_t RemoteTaskWrite64(uint64_t addr, mach_port_t task, uint64_t map, uint64_t value);
void RemoteTaskHexDump(uint64_t addr, size_t size, mach_port_t task, uint64_t map);

#define PT_DETACH 11
#define PT_ATTACHEXC 14

uintptr_t brX8Address, changeLRAddress, paciaAddress;
BOOL wantsDetach;
mach_port_t GlobalChildTaskPort;
mach_port_t GlobalChildThreadPort;
extern char **environ;

uint32_t __atomic_load_4(uint64_t *ptr, int memorder);
uint64_t __atomic_load_8(uint64_t *ptr, int memorder);
void __atomic_store_4(uint64_t *ptr, uint32_t val, int memorder);
void __atomic_store_8(uint64_t *ptr, uint64_t val, int memorder);
// has pacia x16, x17; str x16, [x8]
void zeroify_scalable_zone(void);
// nearest of _objectForActiveContext, which has blraaz x8 followed by invalid instruction
void xpc_create_from_ce_der_with_key(void);

kern_return_t bootstrap_check_in(mach_port_t bootstrap_port, const char *service_name, mach_port_t *service_port);
kern_return_t bootstrap_register(mach_port_t bp, const char *service_name, mach_port_t sp);
kern_return_t bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_launch_type_np(posix_spawnattr_t *attr, uint8_t launch_type);
int posix_spawnattr_set_ptrauth_task_port_np(posix_spawnattr_t * __restrict attr, mach_port_t port);
int posix_spawnattr_setexceptionports_np(posix_spawnattr_t *attr,
         exception_mask_t mask, mach_port_t new_port,
         exception_behavior_t behavior, thread_state_flavor_t flavor);
int posix_spawnattr_set_registered_ports_np(posix_spawnattr_t *__restrict attr, mach_port_t portarray[], uint32_t count);

mach_port_t setup_fake_bootstrap_server(void);
mach_port_t setup_exception_server(void);
pid_t spawn_exploit_process(mach_port_t exception_port);

#define __DARWIN_ARM_THREAD_STATE64_FLAGS_IB_SIGNED_LR 0x2
#define __DARWIN_ARM_THREAD_STATE64_FLAGS_KERNEL_SIGNED_PC 0x4
#define __DARWIN_ARM_THREAD_STATE64_FLAGS_KERNEL_SIGNED_LR 0x8
typedef struct {
    uint64_t __x[29];       /* General purpose registers x0-x28 */
    uint64_t __fp; /* Frame pointer x29 */
    uint64_t __lr; /* Link register x30 */
    uint64_t __sp; /* Stack pointer x31 */
    uint64_t __pc; /* Program counter */
    uint32_t __cpsr;        /* Current program status register */
    uint32_t __flags; /* Flags describing structure format */
} arm_thread_state64_internal;

typedef xpc_object_t xpc_pipe_t;
struct _os_alloc_once_s {
  long once;
  void *ptr;
};
struct xpc_global_data {
  uint64_t a;
  uint64_t xpc_flags;
  mach_port_t task_bootstrap_port; /* 0x10 */
#ifndef _64
  uint32_t padding;
#endif
  xpc_pipe_t xpc_bootstrap_pipe; /* 0x18 */
  // and there's more, but you'll have to wait for MOXiI 2 for those...
  // ...
};

BOOL launchTest(NSString *arg1);

kern_return_t _launch_job_routine(int selector, xpc_object_t request, id *result);
xpc_object_t _CFXPCCreateXPCObjectFromCFObject(id object);
xpc_object_t xpc_pipe_create_from_port(mach_port_t port, uint32_t flags);
int xpc_pipe_receive(mach_port_t port, xpc_object_t *msg);
int xpc_pipe_routine_reply(xpc_object_t reply);
int _xpc_pipe_interface_routine(xpc_pipe_t pipe, uint64_t routine, xpc_object_t msg,
                                xpc_object_t XPC_GIVES_REFERENCE *reply, uint64_t flags);
char *xpc_copy_description(xpc_object_t object);
void *_os_alloc_once(struct _os_alloc_once_s *slot, size_t sz,
                            os_function_t init);

int userspaceReboot(void);

// @interface LSApplicationWorkspace : NSObject
// + (instancetype)defaultWorkspace;
// - (BOOL)openApplicationWithBundleID:(NSString *)arg1 ;
// @end
//
@interface NSProcessInfo(Private)
- (NSDate *)systemStartTime;
@end

uint64_t signed_pointer;
uint32_t signed_diversifier;
@interface NSUserDefaults(Private)
@property(nonatomic) NSUInteger signedPointer;
@property(nonatomic) uint32_t signedDiversifier;
@end
