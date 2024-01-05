function replaceByte() {
    printf "\x00\x00\x00\x00" | dd of="$1" bs=1 seek=$2 count=4 conv=notrunc &> /dev/null
}
replaceByte 'launchd' 8 
# /Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/usr/lib/ellekit/libinjector.dylib .theos/obj/debug/arm64e/springboardshim springboardshiminjected --all-yes
# /Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/usr/lib/libellekit.dylib springboardshiminjected springboardshiminjected --all-yes
/Users/ibarahime/insert_dylib/insert_dylib/insert_dylib @loader_path/launchdhook.dylib launchd launchdinjected --all-yes
ldid -Sentitlements.plist launchdinjected
/Users/ibarahime/ChOma/ct_bypass -i launchdinjected -r -o launchdsignedinjected
