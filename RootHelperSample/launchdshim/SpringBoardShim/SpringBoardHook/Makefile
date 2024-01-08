TARGET := iphone:clang:latest:15.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME=roothide
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpringBoardHook

SpringBoardHook_FILES = Tweak.x
SpringBoardHook_CFLAGS = -fobjc-arc -lbsm

after-package::
	echo "[*] Signing SB hook"
	ct_bypass -i .theos/obj/debug/springboardhook.dylib -o springboardhooksigned.dylib
include $(THEOS_MAKE_PATH)/tweak.mk
