echo "Building IPA"
xcodebuild clean build -sdk iphoneos -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO"
echo "done building"
cd RootHelperSample
make
mv .theos/obj/debug/arm64/trolltoolsroothelper ../build/Release-iphoneos/usprebooter.app/trolltoolsroothelper
cd ..
cp ent.xml build/Release-iphoneos/ent.xml
cd build/Release-iphoneos
rm -rf Payload
rm -rf FUCK.tipa
mkdir Payload
cp -r usprebooter.app Payload
ldid -Sent.xml -Cadhoc Payload/usprebooter.app/usprebooter
zip -vr FUCK.tipa Payload/ -x "*.DS_Store"
