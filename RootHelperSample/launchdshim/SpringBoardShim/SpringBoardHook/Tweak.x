#include <unistd.h>
#include <stdio.h>
bool os_variant_has_internal_content(const char* subsystem);
%hookf(bool, os_variant_has_internal_content, const char* subsystem) {
     return true;
}

#define CS_DEBUGGED 0x10000000
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);
int fork();
int ptrace(int, int, int, int);
int isJITEnabled() {
    int flags;
    csops(getpid(), 0, &flags, sizeof(flags));
    return (flags & CS_DEBUGGED) != 0;
}

%ctor {
    printf("hook works");
    if (!isJITEnabled()) {
        // Enable JIT
        int pid = fork();
        if (pid == 0) {
            ptrace(0, 0, 0, 0);
            exit(0);
        } else if (pid > 0) {
            while (wait(NULL) > 0) {
                usleep(1000);
            }
        }
    }
}
