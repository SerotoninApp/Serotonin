TARGET := iphone:clang:15.2:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = trolltoolsroothelper

trolltoolsroothelper_FILES = $(wildcard *.m)
trolltoolsroothelper_CFLAGS = -fobjc-arc
trolltoolsroothelper_CODESIGN_FLAGS = -Sentitlements.plist
trolltoolsroothelper_INSTALL_PATH = /usr/local/bin
trolltoolsroothelper_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileCoreServices

include $(THEOS_MAKE_PATH)/tool.mk
