TARGET := iphone:clang:16.4
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

TOOL_NAME = springboardshim

springboardshim_FILES = main.c
springboardshim_CFLAGS = -fobjc-arc -isystem ../../../apple-include -lbsm -O2
springboardshim_LDFLAGS = -lbsm
springboardshim_CODESIGN_FLAGS = -SSpringBoardEntsBedtime.plist
springboardshim_INSTALL_PATH = /usr/local/bin
springboardshim_LIBRARIES = archive
springboardshim_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices Foundation CoreServices Security
#springboardshim_OPTFLAG = 2

after-package::
	ct_bypass -i .theos/obj/debug/springboardshim -o springboardshimsigned
	
include $(THEOS_MAKE_PATH)/tool.mk
