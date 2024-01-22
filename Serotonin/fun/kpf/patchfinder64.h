#ifndef PATCHFINDER64_H_
#define PATCHFINDER64_H_

#include <stdbool.h>
#include <stdio.h>
#include <stddef.h>

extern bool auth_ptrs;
extern bool monolithic_kernel;

int init_kernel(size_t (*kread)(uint64_t, void *, size_t), uint64_t kernel_base, const char *filename);
void term_kernel(void);

enum text_bases {
    text_xnucore_base = 0,
    text_prelink_base,
    text_ppl_base
};

enum string_bases {
    string_base_cstring = 0,
    string_base_pstring,
    string_base_oslstring,
    string_base_data,
    string_base_const
};

uint64_t find_register_value(uint64_t where, int reg);
uint64_t find_reference(uint64_t to, int n, enum text_bases base);
uint64_t find_strref(const char *string, int n, enum string_bases string_base, bool full_match, bool ppl_base);

uint64_t find_cdevsw(void);
uint64_t find_gPhysBase(void);
uint64_t find_gPhysSize(void);
uint64_t find_gVirtBase(void);
uint64_t find_perfmon_dev_open(void);
uint64_t find_perfmon_devices(void);
uint64_t find_ptov_table(void);
uint64_t find_vn_kqfilter(void);
uint64_t find_proc_object_size(void);

#endif
