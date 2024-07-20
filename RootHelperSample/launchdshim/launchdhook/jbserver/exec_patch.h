//
// Created by Ylarod on 2024/3/15.
//

#ifndef DOPAMINE_EXEC_PATCH_H
#define DOPAMINE_EXEC_PATCH_H

#import <stdbool.h>

void initSpawnExecPatch();
void patchExecAdd(int callerPid, const char* exec_path, bool resume);
void patchExecDel(int callerPid, const char* exec_path);

#endif //DOPAMINE_EXEC_PATCH_H
