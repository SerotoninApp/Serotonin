# Sourced from https://gist.github.com/dlevi309/3da8d364556942fbd63acb52f3ecb866
TARGET = iphone:clang:16.5:14.4
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME=roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hideconfidentialtext

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -lbsm -Wmodule-import-in-extern-c
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = SpringBoardUIServices SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk
