TARGET := iphone:clang:16.5:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = serotoninroothelper

$(TOOL_NAME)_FILES = $(wildcard *.m) $(wildcard *.c) Exploits/fastPathSign/src/coretrust_bug.c Exploits/fastPathSign/src/codesign.m
$(TOOL_NAME)_LDFLAGS = -Lexternal/lib -lcrypto -lchoma
$(TOOL_NAME)_CFLAGS = -fobjc-arc $(shell pkg-config --cflags libcrypto) -Iexternal/include -Wno-error -IExploits/fastPathSign/src
$(TOOL_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
$(TOOL_NAME)_INSTALL_PATH = /usr/local/bin
$(TOOL_NAME)_LIBRARIES = archive
$(TOOL_NAME)_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileCoreServices MobileContainerManager IOKit

include $(THEOS_MAKE_PATH)/tool.mk
