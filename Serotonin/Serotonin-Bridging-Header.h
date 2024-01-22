//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include "troller.h"
#include "util.h"
#include "fun/krw.h"
#include "fun/kpf/patchfinder.h"
#include "memoryControl.h"
//#include "fun/helpers.h"
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <CoreFoundation/CoreFoundation.h>


int go(bool isBeta, NSString* argument);
int userspaceReboot(void);
float roundLog(float input);
extern CFDictionaryRef _CFCopySystemVersionDictionary(void);
bool isBetaiOS(void);
