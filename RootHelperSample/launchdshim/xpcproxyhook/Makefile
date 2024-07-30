TARGET := iphone:clang:latest:15.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = xpcproxyhook

xpcproxyhook_FILES = $(wildcard *.m) $(wildcard *.c) ../../jbroot.m
xpcproxyhook_CFLAGS = -fobjc-arc -Wno-error
xpcproxyhook_CODESIGN_FLAGS = -S
xpcproxyhook_LDFLAGS = -F./Frameworks
xpcproxyhook_EXTRA_FRAMEWORKS += IOKit
after-package:: echo "[*] Signing xpcproxyhook hook"; ct_bypass -i .theos/obj/debug/xpcproxyhook.dylib -o xpcproxyhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk

