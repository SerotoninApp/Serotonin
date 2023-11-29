xcodebuild clean build -sdk iphoneos -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO"
cp ent.xml build/Release-iphoneos/ent.xml
cd build/Release-iphoneos
rm -rf Payload
rm -rf FUCK.tipa
mkdir Payload
cp -r usprebooter.app Payload
ldid -Sent.xml -Cadhoc Payload/usprebooter.app/usprebooter
zip -vr FUCK.tipa Payload/ -x "*.DS_Store"
echo "done building"
open .
