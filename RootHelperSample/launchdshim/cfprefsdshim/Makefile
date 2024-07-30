TARGET := iphone:clang:latest
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = cfprefsdshim

$(TOOL_NAME)_FILES = $(wildcard *.c) $(wildcard *.m) ../../jbroot.m
$(TOOL_NAME)_CFLAGS = -fobjc-arc -isystem -Wno-error -O3
$(TOOL_NAME)_LDFLAGS = -L./ -lbsm -lhooker
$(TOOL_NAME)_CODESIGN_FLAGS = -Sent.plist
# EDIT substrate.h similarly to libhooker's tbd in vendor/lib!!! to /var/jb/usr/lib/libhooker.dylib
# old: //install-name:    /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate

after-package:: ct_bypass -i .theos/obj/debug/cfprefsdshim -o cfprefsd

include $(THEOS_MAKE_PATH)/tool.mk
