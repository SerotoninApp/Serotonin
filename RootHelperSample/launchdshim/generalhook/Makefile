TARGET := iphone:clang:latest:15.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = generalhook

$(LIBRARY_NAME)_FILES = $(wildcard *.m) $(wildcard *.c) $(wildcard verbose/*.m) ../launchdhook/jbserver/jbclient_xpc.c ../../jbroot.m
$(LIBRARY_NAME)_CFLAGS = -fobjc-arc -isystem "../../../usprebooter/Private Headers I stole from the macOS SDK" -Wno-error -O3
$(LIBRARY_NAME)_CODESIGN_FLAGS = -S../launchdentitlements.plist
$(LIBRARY_NAME)_LDFLAGS = -L./ -lbsm
#launchdhook_EXTRA_FRAMEWORKS += IOMobileFramebuffer IOSurface
after-package::
	echo "[*] Signing general hook"
	ct_bypass -i .theos/obj/debug/generalhook.dylib -o generalhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
