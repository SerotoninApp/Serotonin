#include "jbserver.h"
// #include "info.h"
#include "sandbox.h"
#include "libproc.h"
#include "libproc_private.h"

// #include <libjailbreak/signatures.h>
// #include <libjailbreak/trustcache.h>
#include "kernel.h"
#include "util.h"
// #include "primitives.h"
#include "codesign.h"
#include <signal.h>
#include "bsm/audit.h"
#include "exec_patch.h"
#include "log.h"
#include "../fun/krw.h"
#include "spawnRoot.h"
// #include <roothide.h>
// #include "../../../jbroot.h"
#include "../fun/memoryControl.h"
#include "jbclient_xpc.h"
char *jbrootC(char* path) {
    // char* boot_manifest_hash = return_boot_manifest_hash_main();
    // if (strcmp(boot_manifest_hash, "lmao") == 0) {
    //     return NULL;
    // }
    // size_t result_len = strlen("/private/preboot/") + strlen(boot_manifest_hash) + strlen(path) + 2; // +2 for '/' and null terminator
    // char* result = (char*)malloc(result_len);
    // if (result == NULL) {
    //     return NULL;
    // }
    // snprintf(result, result_len, "/private/preboot/%s/%s", boot_manifest_hash, path);
    size_t result_len = strlen("/var/jb") + strlen(path) + 2; // +2 for '/' and null terminator
    char* result = (char*)malloc(result_len);
    if (result == NULL) {
        return NULL;
    }
    snprintf(result, result_len, "/var/jb%s/", path);
    return result;
}

#define PT_DETACH       11      /* stop tracing a process */
#define PT_ATTACHEXC    14      /* attach to running process with signal exception */
int ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);

#include <signal.h>

// int enableJIT(pid_t pid)
// {
// 	int ret = spawnRoot(jbrootC("/jitter"), pid, NULL, NULL);
// 	return ret;
// }
// int64_t jitterd(pid_t pid)
// {
// 	xpc_object_t message = xpc_dictionary_create_empty();
// 	xpc_dictionary_set_int64(message, "id", JBD_MSG_PROC_SET_DEBUGGED);
// 	xpc_dictionary_set_int64(message, "pid", pid);
// 	xpc_object_t reply = sendjitterdMessageSystemWide(message);
// 	int64_t result = -1;
// 	if (reply) {
// 		result  = xpc_dictionary_get_int64(reply, "result");
// 		xpc_release(reply);
// 	}
// 	return result;
// }

// extern bool stringStartsWith(const char *str, const char* prefix);
// extern bool stringEndsWith(const char* str, const char* suffix);
bool stringStartsWith(const char *str, const char* prefix)
{
	if (!str || !prefix) {
		return false;
	}

	size_t str_len = strlen(str);
	size_t prefix_len = strlen(prefix);

	if (str_len < prefix_len) {
		return false;
	}

	return !strncmp(str, prefix, prefix_len);
}

bool stringEndsWith(const char* str, const char* suffix)
{
	if (!str || !suffix) {
		return false;
	}

	size_t str_len = strlen(str);
	size_t suffix_len = strlen(suffix);

	if (str_len < suffix_len) {
		return false;
	}

	return !strcmp(str + str_len - suffix_len, suffix);
}

#define APP_PATH_PREFIX "/private/var/containers/Bundle/Application/"

static bool is_app_path(const char* path)
{
    if(!path) return false;

    char rp[PATH_MAX];
    if(!realpath(path, rp)) return false;

    if(strncmp(rp, APP_PATH_PREFIX, sizeof(APP_PATH_PREFIX)-1) != 0)
        return false;

    char* p1 = rp + sizeof(APP_PATH_PREFIX)-1;
    char* p2 = strchr(p1, '/');
    if(!p2) return false;

    //is normal app or jailbroken app/daemon?
    if((p2 - p1) != (sizeof("xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx")-1))
        return false;

	return true;
}

bool is_sub_path(const char* parent, const char* child)
{
	char real_child[PATH_MAX]={0};
	char real_parent[PATH_MAX]={0};

	if(!realpath(child, real_child)) return false;
	if(!realpath(parent, real_parent)) return false;

	if(!stringStartsWith(real_child, real_parent))
		return false;

	return real_child[strlen(real_parent)] == '/';
}

static bool systemwide_domain_allowed(audit_token_t clientToken)
{
	return true;
}

static int systemwide_get_jbroot(char **rootPathOut)
{
	*rootPathOut = strdup(jbinfo(rootPath));
	return 0;
}

static int systemwide_get_boot_uuid(char **bootUUIDOut)
{
	const char *launchdUUID = getenv("LAUNCHD_UUID");
	*bootUUIDOut = launchdUUID ? strdup(launchdUUID) : NULL;
	return 0;
}

char* generate_sandbox_extensions(audit_token_t *processToken, bool writable)
{
	char* sandboxExtensionsOut=NULL;
	// char jbrootbase[PATH_MAX];
	// char jbrootsecondary[PATH_MAX];
	// snprintf(jbrootbase, sizeof(jbrootbase), "/private/var/containers/Bundle/Application/.jbroot-%016llX/", jbinfo(jbrand));
	// snprintf(jbrootsecondary, sizeof(jbrootsecondary), "/private/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX/", jbinfo(jbrand));

	// char* fileclass = writable ? "com.apple.app-sandbox.read-write" : "com.apple.app-sandbox.read";

	// char *readExtension = sandbox_extension_issue_file_to_process("com.apple.app-sandbox.read", jbrootbase, 0, *processToken);
	char *readExtension = sandbox_extension_issue_file_to_process("com.apple.app-sandbox.read", jbrootC("/"), 0, *processToken);
	// char *execExtension = sandbox_extension_issue_file_to_process("com.apple.sandbox.executable", jbrootbase, 0, *processToken);
	char *execExtension = sandbox_extension_issue_file_to_process("com.apple.sandbox.executable", jbrootC("/"), 0, *processToken);
	char *readExtension2 = sandbox_extension_issue_file_to_process("com.apple.app-sandbox.read-write", jbrootC("/var/mobile"), 0, *processToken);
	// char *readExtension2 = sandbox_extension_issue_file_to_process(fileclass, jbrootsecondary, 0, *processToken);
	if (readExtension && execExtension && readExtension2) {
		char extensionBuf[strlen(readExtension) + 1 + strlen(execExtension) + strlen(readExtension2) + 1];
		strcat(extensionBuf, readExtension);
		strcat(extensionBuf, "|");
		strcat(extensionBuf, execExtension);
		strcat(extensionBuf, "|");
		strcat(extensionBuf, readExtension2);
		sandboxExtensionsOut = strdup(extensionBuf);
	}
	if (readExtension) free(readExtension);
	if (execExtension) free(execExtension);
	if (readExtension2) free(readExtension2);
	return sandboxExtensionsOut;
}
static int systemwide_process_checkin(audit_token_t *processToken, char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut, bool *fullyDebuggedOut)
{
	// Fetch process info
	pid_t pid = audit_token_to_pid(*processToken);
	char procPath[4*MAXPATHLEN];
	if (proc_pidpath(pid, procPath, sizeof(procPath)) <= 0) {
		return -1;
	}
	systemwide_get_jbroot(rootPathOut);
	systemwide_get_boot_uuid(bootUUIDOut);
	struct statfs fs;
	bool isPlatformProcess = statfs(procPath, &fs)==0 && strcmp(fs.f_mntonname, "/private/var") != 0;
	*sandboxExtensionsOut = generate_sandbox_extensions(processToken, isPlatformProcess);
	// For whatever reason after SpringBoard has restarted, AutoFill and other stuff stops working
	// The fix is to always also restart the kbd daemon alongside SpringBoard
	// Seems to be something sandbox related where kbd doesn't have the right extensions until restarted
	if (strcmp(procPath, "/System/Library/CoreServices/SpringBoard.app/SpringBoard") == 0) {
		static bool springboardStartedBefore = false;
		if (!springboardStartedBefore) {
			// Ignore the first SpringBoard launch after userspace reboot
			// This fix only matters when SpringBoard gets restarted during runtime
			springboardStartedBefore = true;
		}
		else {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				killall("/System/Library/TextInput/kbd", false);
			});
		}
	}
	return 0;
}

static int systemwide_patch_exec_add(audit_token_t *callerToken, const char* exec_path, bool resume)
{
    uint64_t callerPid = audit_token_to_pid(*callerToken);
    if (callerPid > 0) {
        patchExecAdd((int)callerPid, exec_path, resume);
        return 0;
    }
    return -1;
}

static int systemwide_patch_exec_del(audit_token_t *callerToken, const char* exec_path)
{
    uint64_t callerPid = audit_token_to_pid(*callerToken);
    if (callerPid > 0){
        patchExecDel((int)callerPid, exec_path);
        return 0;
    }
    return -1;
}

struct jbserver_domain gSystemwideDomain = {
	.permissionHandler = systemwide_domain_allowed,
	.actions = {
		// JBS_SYSTEMWIDE_GET_JBROOT
		{
			.handler = systemwide_get_jbroot,
			.args = (jbserver_arg[]){
				{ .name = "root-path", .type = JBS_TYPE_STRING, .out = true },
				{ 0 },
			},
		},
		// JBS_SYSTEMWIDE_GET_BOOT_UUID
		{
			.handler = systemwide_get_boot_uuid,
			.args = (jbserver_arg[]){
				{ .name = "boot-uuid", .type = JBS_TYPE_STRING, .out = true },
				{ 0 },
			},
		},
		// JBS_SYSTEMWIDE_PROCESS_CHECKIN
		{
			.handler = systemwide_process_checkin,
			.args = (jbserver_arg[]) {
				{ .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
				{ .name = "root-path", .type = JBS_TYPE_STRING, .out = true },
				{ .name = "boot-uuid", .type = JBS_TYPE_STRING, .out = true },
				{ .name = "sandbox-extensions", .type = JBS_TYPE_STRING, .out = true },
				{ .name = "fully-debugged", .type = JBS_TYPE_BOOL, .out = true },
				{ 0 },
			},
		},
		// // JBS_SYSTEMWIDE_FORK_FIX
		// {
		// 	.handler = systemwide_fork_fix,
		// 	.args = (jbserver_arg[]) {
		// 		{ .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
		// 		{ .name = "child-pid", .type = JBS_TYPE_UINT64, .out = false },
		// 		{ 0 },
		// 	},
		// },
		// // JBS_SYSTEMWIDE_CS_REVALIDATE
		// {
		// 	.handler = systemwide_cs_revalidate,
		// 	.args = (jbserver_arg[]) {
		// 		{ .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
		// 		{ 0 },
		// 	},
		// },
        // // JBS_SYSTEMWIDE_CS_DROP_GET_TASK_ALLOW
        // {
        //     // .action = JBS_SYSTEMWIDE_CS_DROP_GET_TASK_ALLOW,
        //     .handler = systemwide_cs_drop_get_task_allow,
        //     .args = (jbserver_arg[]) {
        //             { .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
        //             { 0 },
        //     },
        // },
        // // JBS_SYSTEMWIDE_PATCH_SPAWN
        // {
        //     // .action = JBS_SYSTEMWIDE_PATCH_SPAWN,
        //     .handler = systemwide_patch_spawn,
        //     .args = (jbserver_arg[]) {
        //             { .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
        //             { .name = "pid", .type = JBS_TYPE_UINT64, .out = false },
        //             { .name = "resume", .type = JBS_TYPE_BOOL, .out = false },
        //             { 0 },
        //     },
        // },
        // // JBS_SYSTEMWIDE_PATCH_EXEC_ADD
        // {
        //     // .action = JBS_SYSTEMWIDE_PATCH_EXEC_ADD,
        //     .handler = systemwide_patch_exec_add,
        //     .args = (jbserver_arg[]) {
        //             { .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
        //             { .name = "exec-path", .type = JBS_TYPE_STRING, .out = false },
        //             { .name = "resume", .type = JBS_TYPE_BOOL, .out = false },
        //             { 0 },
        //     },
        // },
        // // JBS_SYSTEMWIDE_PATCH_EXEC_DEL
        // {
        //     // .action = JBS_SYSTEMWIDE_PATCH_EXEC_DEL,
        //     .handler = systemwide_patch_exec_del,
        //     .args = (jbserver_arg[]) {
        //             { .name = "caller-token", .type = JBS_TYPE_CALLER_TOKEN, .out = false },
        //             { .name = "exec-path", .type = JBS_TYPE_STRING, .out = false },
        //             { 0 },
        //     },
        // },
		{ 0 },
	},
};