xcrun -sdk iphoneos clang *.c -o xpcproxyhook.dylib -arch arm64 -miphoneos-version-min=16.0 -dynamiclib -framework IOKit
