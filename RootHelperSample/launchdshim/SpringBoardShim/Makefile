TARGET := iphone:clang:latest
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = springboardshim

springboardshim_FILES = main.c
springboardshim_CFLAGS = -fobjc-arc -isystem
springboardshim_LDFLAGS = -L./ -lbsm
springboardshim_CODESIGN_FLAGS = -SSpringBoardEnts.plist
#springboardshim_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices Foundation // adding SpringBoard to privateframeworks here will add it into load command before the tweak dylib is loaded, which causes the platform check to fail - thanks DuyKhanhTran

after-package::
	ct_bypass -i .theos/obj/debug/springboardshim -o springboardshimsigned
	
include $(THEOS_MAKE_PATH)/tool.mk
