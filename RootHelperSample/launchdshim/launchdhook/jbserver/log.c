#include <mach-o/dyld.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include "log.h"

// #ifdef ENABLE_LOGS

bool debugLogsEnabled = true;
bool errorLogsEnabled = true;
#define LOGGING_PATH "/var/mobile/"

const char *JBLogGetProcessName(void) {
    static char *processName = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uint32_t length = 0;
        _NSGetExecutablePath(NULL, &length);
        char *buf = malloc(length);
        _NSGetExecutablePath(buf, &length);

        char delim[] = "/";
        char *last = NULL;
        char *ptr = strtok(buf, delim);
        while (ptr != NULL) {
            last = ptr;
            ptr = strtok(NULL, delim);
        }
        processName = strdup(last);
        free(buf);
    });
    return processName;
}


void JBDLogV(const char *prefix, const char *format, va_list va) {
    static char *logFilePath = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *processName = JBLogGetProcessName();

        time_t t = time(NULL);
        //struct tm *tm = localtime(&t);
        char timestamp[64];
        sprintf(&timestamp[0], "%lu-%d", t, getpid());

        logFilePath = malloc(strlen(LOGGING_PATH) + strlen(processName) + strlen(timestamp) + 6);
        strcpy(logFilePath, LOGGING_PATH);
        strcat(logFilePath, processName);
        strcat(logFilePath, "-");
        strcat(logFilePath, timestamp);
        strcat(logFilePath, ".log");
    });

    FILE *logFile = fopen(logFilePath, "a");
    if (logFile) {
        time_t ltime;
        struct tm result;
        char stime[32];
        ltime = time(NULL);

        __uint64_t tid = 0;
        pthread_threadid_np(0, &tid);
        fprintf(logFile, "[%lu] [%lld] [%s] ", ltime, tid, prefix);
        vfprintf(logFile, format, va);
        fprintf(logFile, "\n");

        fflush(logFile);
        fsync(fileno(logFile));
        fclose(logFile);
    }
}

bool jblogenable = false;

void JBLogDebug(const char *format, ...) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (access(LOGGING_PATH "/.jblogenable", F_OK) == 0) jblogenable = true;
    });

    if (!jblogenable) return;

    if (!debugLogsEnabled) return;
    va_list va;
    va_start(va, format);
    JBDLogV("DEBUG", format, va);
    va_end(va);
}

void JBLogError(const char *format, ...) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (access(LOGGING_PATH "/.jblogenable", F_OK) == 0) jblogenable = true;
    });

    if (!jblogenable) return;

    if (!errorLogsEnabled) return;
    va_list va;
    va_start(va, format);
    JBDLogV("ERROR", format, va);
    va_end(va);
}

// #endif
