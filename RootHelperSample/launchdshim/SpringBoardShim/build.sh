function replaceByte() {
    printf "\x00\x00\x00\x00" | dd of="$1" bs=1 seek=$2 count=4 conv=notrunc &> /dev/null
}

make
# /Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/usr/lib/ellekit/libinjector.dylib .theos/obj/debug/arm64e/springboardshim springboardshiminjected --all-yes
# /Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/usr/lib/libellekit.dylib springboardshiminjected springboardshiminjected --all-yes
/Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/springboardhook.dylib .theos/obj/debug/arm64e/springboardshim springboardshiminjected --all-yes

# replaceByte 'springboardshiminjected' 8 
ldid -SSpringBoardEnts.plist springboardshiminjected
/Users/ibarahime/ChOma/ct_bypass -i springboardshiminjected -r -o springboardshimsignedinjected
