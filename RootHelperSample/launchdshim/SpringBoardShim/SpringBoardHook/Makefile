TARGET := iphone:clang:latest:16.5
ARCHS = arm64
THEOS_PACKAGE_SCHEME=rootless


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpringBoardHook

SpringBoardHook_FILES = Tweak.x
SpringBoardHook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
