#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/wait.h>
#include "spawnRoot.h"

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1

int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

int fd_is_valid(int fd)
{
    return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}

char* get_string_from_file(int fd)
{
    char* buffer = NULL;
    size_t buffer_size = 0;
    size_t total_read = 0;
    ssize_t bytes_read;
    char c;

    if (!fd_is_valid(fd)) return strdup("");

    do {
        bytes_read = read(fd, &c, 1);
        if (bytes_read > 0) {
            if (total_read >= buffer_size) {
                buffer_size += 128;
                buffer = realloc(buffer, buffer_size);
                if (!buffer) {
                    perror("Memory allocation failed");
                    exit(1);
                }
            }
            buffer[total_read++] = c;
        }
    } while (bytes_read > 0 && c != '\n');

    if (total_read > 0) {
        buffer[total_read] = '\0';
    } else {
        buffer = strdup("");
    }

    return buffer;
}

int spawnRoot(const char* path, pid_t target_pid, char** std_out, char** std_err)
{
    posix_spawnattr_t attr;
    posix_spawn_file_actions_t action;
    pid_t task_pid;
    int status = -200;
    int out[2], outErr[2];
    char pid_str[16];

    char* args[] = {(char*)path, pid_str, NULL};

    snprintf(pid_str, sizeof(pid_str), "%d", target_pid);

    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_init(&action);

    if (std_err) {
        pipe(outErr);
        posix_spawn_file_actions_adddup2(&action, outErr[1], STDERR_FILENO);
        posix_spawn_file_actions_addclose(&action, outErr[0]);
    }

    if (std_out) {
        pipe(out);
        posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&action, out[0]);
    }

    int spawn_error = posix_spawn(&task_pid, path, &action, &attr, args, NULL);
    posix_spawnattr_destroy(&attr);

    if (spawn_error != 0) {
        printf("posix_spawn error %d\n", spawn_error);
        return spawn_error;
    }

    do {
        if (waitpid(task_pid, &status, 0) != -1) {
            printf("Child status %d\n", WEXITSTATUS(status));
        } else {
            perror("waitpid");
            return -222;
        }
    } while (!WIFEXITED(status) && !WIFSIGNALED(status));

    if (std_out) {
        close(out[1]);
        *std_out = get_string_from_file(out[0]);
        close(out[0]);
    }

    if (std_err) {
        close(outErr[1]);
        *std_err = get_string_from_file(outErr[0]);
        close(outErr[0]);
    }

    return WEXITSTATUS(status);
}