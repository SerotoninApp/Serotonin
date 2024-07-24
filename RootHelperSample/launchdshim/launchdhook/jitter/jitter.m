#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/types.h>
#include <xpc/xpc.h>
#include <dispatch/dispatch.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/task.h>
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include "../fun/memoryControl.h"
#include "../jbserver/bsm/audit.h"
#include "../jbserver/xpc_private.h"

#define PT_DETACH       11      /* stop tracing a process */
#define PT_ATTACHEXC    14      /* attach to running process with signal exception */
#define MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK 5
#define JBD_MSG_PROC_SET_DEBUGGED 23

int ptrace(int request, pid_t pid, caddr_t addr, int data);
// void JBLogError(const char *format, ...);
// void JBLogDebug(const char *format, ...);
int enableJIT(pid_t pid)
{
    int ret = ptrace(PT_ATTACHEXC, pid, NULL, 0);
    if (ret != 0) return ret;
    ret = ptrace(PT_DETACH, pid, NULL, 0);
    return ret;
}

kern_return_t bootstrap_check_in(mach_port_t bootstrap_port, const char *service, mach_port_t *server_port);

void setJetsamEnabled(bool enabled)
{
    int priorityToSet = enabled ? 10 : -1;
    int rc = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, getpid(), priorityToSet, NULL, 0);
    if (rc < 0) {
        perror("memorystatus_control");
        exit(rc);
    }
}

void jitterd_received_message(mach_port_t machPort, bool systemwide)
{
    @autoreleasepool {
        xpc_object_t message = NULL;
        int err = xpc_pipe_receive(machPort, &message);
        if (err != 0) {
            // JBLogError("xpc_pipe_receive error %d", err);
            return;
        }

        xpc_object_t reply = xpc_dictionary_create_reply(message);
        xpc_type_t messageType = xpc_get_type(message);
        int64_t msgId = -1;

        if (messageType == XPC_TYPE_DICTIONARY) {
            audit_token_t auditToken = {};
            xpc_dictionary_get_audit_token(message, &auditToken);
            // uid_t clientUid = audit_token_to_euid(auditToken);
            // pid_t clientPid = audit_token_to_pid(auditToken);
            msgId = xpc_dictionary_get_int64(message, "id");
            char *description = xpc_copy_description(message);
            free(description);

            switch (msgId) {
                case JBD_MSG_PROC_SET_DEBUGGED: {
                    int64_t result = 0;
                    pid_t pid = xpc_dictionary_get_int64(message, "pid");
                    result = enableJIT(pid);
                    xpc_dictionary_set_int64(reply, "result", result);
                    break;
                }
                default:
                    break;
            }
        }

        if (reply) {
            char *description = xpc_copy_description(reply);
            // JBLogDebug("responding to %s message %lld with %s", systemwide ? "systemwide" : "", msgId, description);
            free(description);
            err = xpc_pipe_routine_reply(reply);
            if (err != 0) {
                // JBLogError("Error %d sending response", err);
            }
        }
    }
}

int main(int argc, char* argv[])
{
    @autoreleasepool {
        setJetsamEnabled(true);

        mach_port_t machPort = 0;
        kern_return_t kr = bootstrap_check_in(bootstrap_port, "com.hrtowii.jitterd", &machPort);
        if (kr != KERN_SUCCESS) {
            // JBLogError("Failed com.hrtowii.jitterd bootstrap check in: %d (%s)", kr, mach_error_string(kr));
            return 1;
        }

        mach_port_t machPortSystemWide = 0;
        kr = bootstrap_check_in(bootstrap_port, "com.hrtowii.jitterd.systemwide", &machPortSystemWide);
        if (kr != KERN_SUCCESS) {
            // JBLogError("Failed com.hrtowii.jitterd.systemwide bootstrap check in: %d (%s)", kr, mach_error_string(kr));
            return 1;
        }

        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, (uintptr_t)machPort, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(source, ^{
            mach_port_t lMachPort = (mach_port_t)dispatch_source_get_handle(source);
            jitterd_received_message(lMachPort, false);
        });
        dispatch_resume(source);

        dispatch_source_t sourceSystemWide = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, (uintptr_t)machPortSystemWide, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(sourceSystemWide, ^{
            mach_port_t lMachPort = (mach_port_t)dispatch_source_get_handle(sourceSystemWide);
            jitterd_received_message(lMachPort, true);
        });
        dispatch_resume(sourceSystemWide);

        dispatch_main();
        return 0;
    }
}
