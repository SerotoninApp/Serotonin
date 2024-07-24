#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/types.h>
#include <Foundation/Foundation.h>
#define PT_DETACH       11      /* stop tracing a process */
#define PT_ATTACHEXC    14      /* attach to running process with signal exception */

int ptrace(int request, pid_t pid, caddr_t addr, int data);
int proc_paused(pid_t pid, bool *paused);

int enableJIT(pid_t pid)
{
    int ret = ptrace(PT_ATTACHEXC, pid, NULL, 0);
//    NSLog(@"jitter - attach ret");
    if(ret != 0) return ret;
    //don't SIGCONT here, otherwise kernel may send exception msg to this process and the traced process keep waiting, kill(pid, SIGCONT);
    // for(int i=0; i<1000*50; i++)
    // {
    //     bool paused=false;
    //     ret = proc_paused(pid, &paused);
    //     if(ret != 0) return ret;
    //     if(paused) break;
    //     usleep(10);
    // }
    ret = ptrace(PT_DETACH, pid, NULL, 0);
//    NSLog(@"jitter - detach ret");
    return ret;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <pid>\n", argv[0]);
        return 1;
    }

    pid_t pid = (pid_t)atoi(argv[1]);
    if (pid <= 0) {
        fprintf(stderr, "Invalid PID\n");
        return 1;
    }

    return enableJIT(pid);
}
