TARGET := iphone:clang:16.1:14.5
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook

launchdhook_FILES = $(wildcard *.m) $(wildcard *.c)
launchdhook_CFLAGS = -fobjc-arc
launchdhook_CODESIGN_FLAGS = -S../entitlements.plist

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -o launchdhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
