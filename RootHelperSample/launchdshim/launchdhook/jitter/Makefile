TARGET := iphone:clang:latest
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = jitter

jitter_FILES = $(wildcard *.c) $(wildcard *.m)
jitter_CFLAGS = -fobjc-arc -isystem -Wno-error
jitter_LDFLAGS = -L./ -lbsm
jitter_CODESIGN_FLAGS = -Sent.plist

after-package:: ct_bypass -i .theos/obj/debug/jitter -o jitter

include $(THEOS_MAKE_PATH)/tool.mk
