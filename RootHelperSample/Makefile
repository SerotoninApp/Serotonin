TARGET := iphone:clang:15.2:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = trolltoolsroothelper

trolltoolsroothelper_FILES = $(wildcard *.m) Exploits/fastPathSign/src/coretrust_bug.c Exploits/fastPathSign/src/codesign.m
trolltoolsroothelper_LDFLAGS = -Lexternal/lib -lcrypto -lchoma
trolltoolsroothelper_CFLAGS = -fobjc-arc $(shell pkg-config --cflags libcrypto) -Iexternal/include -IExploits/fastPathSign/src
trolltoolsroothelper_CODESIGN_FLAGS = -Sentitlements.plist
trolltoolsroothelper_INSTALL_PATH = /usr/local/bin
trolltoolsroothelper_LIBRARIES = archive
trolltoolsroothelper_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileCoreServices MobileContainerManager

include $(THEOS_MAKE_PATH)/tool.mk
