//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include "troller.h"
#include "util.h"
#include "fun/fun.h"
#include "fun/krw.h"
#include "fun/kpf/patchfinder.h"
#include "memoryControl.h"
//#include "fun/helpers.h"
#include <stdint.h>
#include <stdbool.h>


void fix_exploit(void);
int go(bool);
int userspaceReboot(void);
