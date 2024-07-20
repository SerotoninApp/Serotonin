TARGET := iphone:clang:latest:15.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook
FINALPACKAGE=1
launchdhook_FILES = $(wildcard *.m) $(wildcard *.c) $(wildcard verbose/*.m) $(wildcard jbserver/*.c) $(wildcard jbserver/*.m) $(wildcard fun/*.m) $(wildcard fun/kpf/*.c) $(wildcard fun/kpf/*.m)
launchdhook_CFLAGS = -fobjc-arc -isystem "../../../usprebooter/Private Headers I stole from the macOS SDK" -Wno-error -O3
launchdhook_CODESIGN_FLAGS = -S../launchdentitlements.plist
launchdhook_LDFLAGS = -F./Frameworks -L./ -lbsm -lhooker -framework IOKit
launchdhook_EXTRA_FRAMEWORKS += IOMobileFramebuffer IOSurface
after-package::
	echo "[*] Signing launchd hook"
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -o launchdhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
