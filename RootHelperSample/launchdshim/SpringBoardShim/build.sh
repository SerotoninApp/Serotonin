function replaceByte() {
    printf "\x00\x00\x00\x00" | dd of="$1" bs=1 seek=$2 count=4 conv=notrunc &> /dev/null
}

make
/Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/usr/lib/ellekit/libinjector.dylib .theos/obj/debug/arm64e/springboardshim springboardshiminjected1 --all-yes
/Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/springboardhook.dylib springboardshiminjected1 springboardshiminjected2 --all-yes
replaceByte 'springboardshiminjected2' 8 
ldid -SSpringBoardEntsBedtime.plist springboardshiminjected2
/Users/ibarahime/ChOma/ct_bypass -i springboardshiminjected2 -r -o springboardshimsignedinjected
