#ifndef EXEPATCH_H
#define EXEPATCH_H

#include <stdint.h>
#include <stdbool.h>

// Define the bootstrap install name
#define BOOTSTRAP_INSTALL_NAME "@loader_path/generalhook.dylib"

//// Function to rebind Mach-O binary
//void* rebind(struct mach_header_64* header, enum bindtype type, void* data, uint32_t* size);
//
//// Function to patch Mach-O binary
//int patch_macho(int fd, struct mach_header_64* header);
//
//// Function to patch executable
//int patch_executable(const char* file, uint64_t offset, uint64_t size);

// Function to patch application executable
int patch_app_exe(const char* file);

#endif // MACHO_PATCHER_H
