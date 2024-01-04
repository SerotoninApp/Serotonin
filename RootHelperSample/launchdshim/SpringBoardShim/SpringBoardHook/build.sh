make
ldid -S../../entitlements.plist -Cadhoc springboardhooksigned.dylib
/Users/ibarahime/ChOma/ct_bypass -i .theos/obj/debug/SpringBoardHook.dylib -r -o springboardhooksigned.dylib
