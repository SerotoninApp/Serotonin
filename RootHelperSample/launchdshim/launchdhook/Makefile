TARGET := iphone:clang:16.4:14.0
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = launchdhook

launchdhook_FILES = $(wildcard *.m) $(wildcard *.c)
launchdhook_CFLAGS = -fobjc-arc -isystem ../../../apple-include
launchdhook_CODESIGN_FLAGS = -S../entitlements.plist

after-package::
	ct_bypass -i .theos/obj/debug/launchdhook.dylib -o launchdhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
