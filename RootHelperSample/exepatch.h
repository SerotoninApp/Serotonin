#ifndef EXEPATCH_H
#define EXEPATCH_H

#include <stdint.h>
#include <stdbool.h>

int patch_app_exe(const char* file, char* insert_path);

#endif // MACHO_PATCHER_H
