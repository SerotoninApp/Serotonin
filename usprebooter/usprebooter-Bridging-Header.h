//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include "troller.h"
#include "util.h"
#include "fun/fun.h"
#include "fun/krw.h"
#include "fun/helpers.h"
#include <stdint.h>
//#include "fun/grant_full_disk_access.h"
uint64_t kopen_intermediate(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void kclose_intermediate(uint64_t kfd);
//void stage2(uint64_t kfd);
//void do_trolling(void);
//void grant_full_disk_access(void);
void respring(void);
void do_fun(void);
