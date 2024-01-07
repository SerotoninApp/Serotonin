TARGET := iphone:clang:16.4:14.0
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook

launchdhook_FILES = $(wildcard *.m) $(wildcard *.c) $(wildcard verbose/*.m)
launchdhook_CFLAGS = -fobjc-arc -isystem ../../../apple-include -Wno-error
launchdhook_CODESIGN_FLAGS = -S../launchdentitlements.plist
launchdhook_LDFLAGS = -F./Frameworks
launchdhook_EXTRA_FRAMEWORKS += IOMobileFramebuffer IOSurface

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -o launchdhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
