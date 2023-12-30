//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include "troller.h"
#include "util.h"
#include "fun/fun.h"
#include "fun/krw.h"
#include "fun/helpers.h"
#include <stdint.h>
uint64_t do_kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method);
void do_kclose(void);
void fix_exploit(void);
int fuck(void);
int fuck2(void);
int userspaceReboot(void);
