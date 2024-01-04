make
/Users/ibarahime/insert_dylib/insert_dylib/insert_dylib /var/jb/springboardhook.dylib .theos/obj/debug/springboardshim springboardshiminjected --all-yes
ldid -SSpringBoardEntsBedtime.plist springboardshiminjected 
/Users/ibarahime/ChOma/ct_bypass -i springboardshiminjected -r -o springboardshimsignedinjected
