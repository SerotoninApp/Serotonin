xcrun -sdk iphoneos clang -Oz -Wall -Wextra -miphoneos-version-min=14.0 -framework IOKit -framework CoreFoundation launchdshim.c -o shim
ldid -Sentitlements.plist -Cadhoc shim
/Users/ibarahime/ChOma/output/tests/ct_bypass -i shim -r -o shim
