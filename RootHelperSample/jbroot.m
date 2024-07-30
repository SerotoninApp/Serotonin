#include <stdio.h>
#include <sys/types.h>
#include <Foundation/Foundation.h>
NSString *jbrootobjc(NSString *path)
{
    NSString* jbroot = @"/var/jb";
    return [jbroot stringByAppendingPathComponent:path];
}

char* jbroot(const char* path) {
    static char result[1024];
    const char* jb_root = "/var/jb";
    result[0] = '\0';
    strncpy(result, jb_root, sizeof(result) - 1);
    result[sizeof(result) - 1] = '\0';
    size_t remaining = sizeof(result) - strlen(result) - 1;
    if (path[0] != '/' && remaining > 0) {
        strncat(result, "/", remaining);
        remaining--;
    }
    strncat(result, path, remaining);
    return result;
}
