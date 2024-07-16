TARGET := iphone:clang:latest
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = cfprefsdshim

cfprefsdshim_FILES = $(wildcard *.c) $(wildcard *.m)
cfprefsdshim_CFLAGS = -fobjc-arc -isystem -Wno-error
cfprefsdshim_LDFLAGS = -L./ -lbsm -lhooker
cfprefsdshim_CODESIGN_FLAGS = -Sent.plist

after-package:: ct_bypass -i .theos/obj/debug/cfprefsdshim -o cfprefsd

include $(THEOS_MAKE_PATH)/tool.mk
