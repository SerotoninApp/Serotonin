CC = clang
SHELL = /usr/bin/env bash
LDID = ldid
MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk iphoneos --show-sdk-path)


all: Serotonin.tipa

Serotonin.tipa: $(wildcard **/*.c **/*.m **/*.swift **/*.plist **/*.xml)
	echo "[*] Building ChOma for host"
	$(MAKE) -C ChOma
	cp -r ChOma ChOma_host
	
	echo "[*] Building ChOma for target"
	$(MAKE) -C ChOma TARGET=ios
	
	echo "[*] Building fastPathSign"
	$(MAKE) -C RootHelperSample/Exploits/fastPathSign
	
	echo "[*] Building lunchd hook"
	$(MAKE) -C RootHelperSample/launchdshim/launchdhook
	
	echo "[*] Signing lunchd hook"
	$(shell test -f RootHelperSample/launchdshim/launchdhook/launchdhooksigned.dylib  || ./ChOma_host/output/tests/ct_bypass -i RootHelperSample/launchdshim/launchdhook/.theos/obj/debug/launchdhook.dylib -o RootHelperSample/launchdshim/launchdhook/launchdhooksigned.dylib)
	
	echo "[*] Building SpringBoard Hook"
	$(MAKE) -C RootHelperSample/launchdshim/SpringBoardShim/SpringBoardHook
	
	echo "[*] Signing SB hook"
	$(shell test -f RootHelperSample/launchdshim/SpringBoardShim/SpringBoardHook/springboardhooksigned.dylib || ./ChOma_host/output/tests/ct_bypass -i RootHelperSample/launchdshim/SpringBoardShim/SpringBoardHook/.theos/obj/debug/SpringBoardHook.dylib -o RootHelperSample/launchdshim/SpringBoardShim/SpringBoardHook/springboardhooksigned.dylib)
	
	# jank workaround at best, can someone else please fix this weird file dependency? – bomberfish
	echo "[*] Copying fastPathSign"
	mkdir -p ChOma/output/ios/tests
	cp RootHelperSample/Exploits/fastPathSign/fastPathSign ChOma/output/ios/tests
	
	echo "[*] Building Serotonin"
	xcodebuild clean build -project Serotonin.xcodeproj -sdk iphoneos -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO"
	
	echo "[*] Done building. Packaging for TS..."
	$(MAKE) -C RootHelperSample
	rm -rf Payload
	rm -rf Serotonin.tipa
	mkdir Payload
	cp -a build/Release-iphoneos/usprebooter.app Payload
	cp RootHelperSample/.theos/obj/debug/arm64/trolltoolsroothelper Payload/usprebooter.app/trolltoolsroothelper
	install -m755 RootHelperSample/launchdshim/launchdhook/launchdhooksigned.dylib Payload/usprebooter.app/launchdhooksigned.dylib
	install -m755 RootHelperSample/launchdshim/SpringBoardShim/SpringBoardHook/springboardhooksigned.dylib Payload/usprebooter.app/springboardhooksigned.dylib
	
	$(LDID) -S./RootHelperSample/entitlements.plist -Cadhoc Payload/usprebooter.app/{fastPathSign,ldid,trolltoolsroothelper}
	$(LDID) -Sent.plist -Cadhoc Payload/usprebooter.app/usprebooter
	zip -vr9 Serotonin.tipa Payload/ -x "*.DS_Store"

apple-include:
	mkdir -p apple-include/{bsm,objc,os/internal,sys,firehose,CoreFoundation,FSEvents,IOSurface,IOKit/kext,libkern,kern,arm,{mach/,}machine,CommonCrypto,Security,CoreSymbolication,Kernel/{kern,IOKit,libkern},rpc,rpcsvc,xpc/private,ktrace,mach-o,dispatch}
	cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,xpc,netinet,servers,timeconv.h,launch.h} apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h apple-include/objc
	cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} apple-include/libkern
	cp -af $(MACOSX_SYSROOT)/usr/include/kern apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,ptrace,kern*,random,reboot,user,vnode,disk,vmmeter,conf}.h apple-include/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h apple-include/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/{AppleConvergedIPCKeys.h,IOBSD.h,IOCFBundle.h,IOCFPlugIn.h,IOCFURLAccess.h,IOKitServer.h,IORPC.h,IOSharedLock.h,IOUserServer.h,audio,avc,firewire,graphics,hid,hidsystem,i2c,iokitmig.h,kext,ndrvsupport,network,ps,pwr_mgt,sbp2,scsi,serial,storage,stream,usb,video} apple-include/IOKit
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecDigestTransform,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,SecReadTransform,oids,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,SecEncryptTransform,cssmapi,cssmcli,mds,x509defs,oidsbase,SecSignVerifyTransform,cssmspi,cssmkrspi,SecTask,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,SecCustomTransform,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTransform,SecTrustSettings,SecStaticCode,emmspi,SecTransformReadTransform,SecKeychain,SecDecodeTransform,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecEncodeTransform,SecureDownload,SecAsn1Templates,AuthorizationDB,SecCertificateOIDs,cssmapple}.h apple-include/Security
	cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,nlist,NSSystemDirectories,tzfile,vproc}.h apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} apple-include/mach
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs apple-include/mach/machine
	cp -af $(MACOSX_SYSROOT)/usr/include/rpc/pmap_clnt.h apple-include/rpc
	cp -af $(MACOSX_SYSROOT)/usr/include/rpcsvc/yp{_prot,clnt}.h apple-include/rpcsvc
	cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h apple-include/mach/machine
	cp -af $(TARGET_SYSROOT)/usr/include/mach/arm apple-include/mach
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* apple-include/IOKit
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOSurface.framework/Headers/* apple-include/IOSurface
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > apple-include/stdlib.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > apple-include/time.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > apple-include/unistd.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > apple-include/mach/task.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > apple-include/mach/mach_host.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > apple-include/ucontext.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > apple-include/signal.h
	gsed -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > apple-include/pthread.h
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h ]; then gsed -E 's/API_UNAVAILABLE\(ios, watchos, tvos\)//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h > apple-include/CoreFoundation/CFUserNotification.h; fi
	gsed -i -E s/'__API_UNAVAILABLE\(.*\)'// apple-include/IOKit/IOKitLib.h

clean:
	rm -rf Payload build RootHelperSample/.theos apple-include RootHelperSample/build FUCK.tipa Serotonin.tipa

.PHONY: all clean
