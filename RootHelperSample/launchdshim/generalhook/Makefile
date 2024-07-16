TARGET := iphone:clang:latest:15.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = generalhook

generalhook_FILES = $(wildcard *.m) $(wildcard *.c) $(wildcard verbose/*.m)
generalhook_CFLAGS = -fobjc-arc -isystem "../../../usprebooter/Private Headers I stole from the macOS SDK" -Wno-error
generalhook_CODESIGN_FLAGS = -S../launchdentitlements.plist
generalhook_LDFLAGS = -L./ -lbsm -L/Users/ibarahime/theos/vendor/lib/ -lhooker -I/Users/ibarahime/theos/vendor/include -dynamiclib
#launchdhook_EXTRA_FRAMEWORKS += IOMobileFramebuffer IOSurface
after-package::
	echo "[*] Signing launchd hook"
	ct_bypass -i .theos/obj/debug/generalhook.dylib -o generalhooksigned.dylib
include $(THEOS_MAKE_PATH)/library.mk
