TARGET := iphone:clang:16.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = springboardshim

springboardshim_FILES = $(wildcard *.c) $(wildcard *.m)
springboardshim_CFLAGS = -fobjc-arc -isystem -Wno-error
springboardshim_LDFLAGS = -L./ -lbsm
springboardshim_CODESIGN_FLAGS = -SSpringBoardEnts.plist
#springboardshim_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices Foundation // adding SpringBoard to privateframeworks here will add it into load command before the tweak dylib is loaded, which causes the platform check to fail - thanks DuyKhanhTran

# EDIT THE LIBHOOKER TBD TO USE @loader_path/.jbroot/usr/lib/libhooker.dylib in $THEOS/vendor/lib/libhooker.tbd
after-package::
	ct_bypass -i .theos/obj/debug/springboardshim -o springboardshimsigned
	
include $(THEOS_MAKE_PATH)/tool.mk
