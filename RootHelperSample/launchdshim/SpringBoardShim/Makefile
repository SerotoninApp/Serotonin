TARGET := iphone:clang:16.5:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = springboardshim

springboardshim_FILES = main.c
springboardshim_CFLAGS = -fobjc-arc -isystem ../../../apple-include
springboardshim_CODESIGN_FLAGS = -SSpringBoardEntsBedtime.plist
springboardshim_INSTALL_PATH = /usr/local/bin
springboardshim_LIBRARIES = archive
springboardshim_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices

after-package::
	ct_bypass -i .theos/obj/debug/springboardshim -o springboardshimsigned
	
include $(THEOS_MAKE_PATH)/tool.mk
