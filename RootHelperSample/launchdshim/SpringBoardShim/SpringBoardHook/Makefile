TARGET := iphone:clang:16.4:14.0
ARCHS = arm64e
THEOS_PACKAGE_SCHEME=rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpringBoardHook

SpringBoardHook_FILES = Tweak.x
SpringBoardHook_CFLAGS = -fobjc-arc -lbsm

include $(THEOS_MAKE_PATH)/tweak.mk
