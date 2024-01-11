//
//  libgrabkernel.c
//  libgrabkernel
//
//  Created by tihmstar on 31.01.19.
//  Copyright © 2019 tihmstar. All rights reserved.
//

#include "all_libgrabkernel.h"
#include "libgrabkernel.h"
#include <sys/utsname.h>
#include <string.h>
#include "libfragmentzip.h"

#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

#define assure(a) do{ if ((a) == 0){err=__LINE__; goto error;} }while(0)
#define retassure(retcode, a) do{ if ((a) == 0){err=retcode; goto error;} }while(0)
#define safeFree(a) do{ if (a){free(a); a=NULL;} }while(0)

#define IPSW_URL_TEMPLATE "https://api.ipsw.me/v2.1/%s/%s/url/dl"

CFPropertyListRef MGCopyAnswer(CFStringRef property);
char * MYCFStringCopyUTF8String(CFStringRef aString) {
    if (aString == NULL) {
        return NULL;
    }
    
    CFIndex length = CFStringGetLength(aString);
    CFIndex maxSize =
    CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
    char *buffer = (char *)malloc(maxSize);
    if (CFStringGetCString(aString, buffer, maxSize,
                           kCFStringEncodingUTF8)) {
        return buffer;
    }
    free(buffer); // If we failed
    return NULL;
}

int getBuildNum(char *outStr, size_t *inOutSize){
    int err = 0;
    assure(outStr);
    assure(inOutSize);

    CFStringRef buildVersion = MGCopyAnswer(CFSTR("BuildVersion"));
    CFIndex length = CFStringGetLength(buildVersion);
    CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
    assure(*inOutSize>=maxSize);

    assure(CFStringGetCString(buildVersion, outStr, maxSize, kCFStringEncodingUTF8));
    *inOutSize = strlen(outStr)+1;
    
error:
    return err;
}

int getHWModel(char *outStr, size_t *inOutSize){
    int err = 0;
    assure(outStr);
    assure(inOutSize);
    
    CFStringRef s = MGCopyAnswer(CFSTR("HWModelStr"));
    CFIndex length = CFStringGetLength(s);
    CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingASCII) + 1;
    assure(*inOutSize>=maxSize);
    
    assure(CFStringGetCString(s, outStr, maxSize, kCFStringEncodingUTF8));
    *inOutSize = strlen(outStr)+1;
    
error:
    return err;
}

int getMachineName(char *outStr, size_t *inOutSize){
    int err = 0;
    size_t realSize = 0;
    struct utsname name;
    
    assure(outStr);
    assure(inOutSize);
    
    assure(!uname(&name));
    
    realSize = strlen(name.machine)+1;
    assure(*inOutSize>=realSize);

    *inOutSize = realSize;
    strncpy(outStr,name.machine,realSize);

error:
    return err;
}

static void fragmentzip_callback(unsigned int progress){
    static int prevProgress = 0;
    if (prevProgress != progress) {
        prevProgress = progress;
        if (progress % 5 == 0) {
            printf(".");
        }
    }
}

char *getKernelpath(const char *buildmanifestPath, const char *model, int isResearchKernel){
    int err = 0;
    char *rt = NULL;
    assure(buildmanifestPath);
    assure(model);
   
    @autoreleasepool {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithCString:buildmanifestPath encoding:NSUTF8StringEncoding]];
        NSArray *identities = [dict valueForKey:@"BuildIdentities"];
        for (NSDictionary *item in identities) {
            NSDictionary *info = [item valueForKey:@"Info"];
            NSString *hwmodel = [info valueForKey:@"DeviceClass"];
            
            if (strcasecmp(hwmodel.UTF8String, model) == 0) {
                NSDictionary *manifest = [item valueForKey:@"Manifest"];
                NSDictionary *kcache = [manifest valueForKey:@"KernelCache"];
                NSDictionary *kinfo = [kcache valueForKey:@"Info"];
                NSString *kpath = [kinfo valueForKey:@"Path"];
                rt = strdup(kpath.UTF8String);
                break;
            }
        }
    }
    assure(rt);
error:
    if (err) {
        printf("[GK] Error: %d\n",err);
        return NULL;
    }
    return rt;
}

int grabkernel(const char *downloadPath, int isResearchKernel){
    int err = 0;
    char build[0x100] = {};
    char machine[0x100] = {};
    char hwmodel[0x100] = {};
    char firmwareUrl[0x200] = {};
    size_t sBuild = 0;
    size_t sMachine = 0;
    size_t sModel = 0;
    fragmentzip_t * fz= NULL;
    char *kernelpath = NULL;
    printf("[GK] %s\n",libgrabkernel_version());
    assure(downloadPath);

    sBuild = sizeof(build);
    assure(!getBuildNum(build, &sBuild));
//    strcpy(build, "20F75"); //XXX CUSTOM
    printf("[GK] Got build number: %s\n",build);
    sMachine = sizeof(machine);
    assure(!getMachineName(machine, &sMachine));
//    strcpy(machine, "iPhone14,4");  //XXX CUSTOM
    printf("[GK] Got machine number: %s\n",machine);
    sModel = sizeof(hwmodel);
    assure(!getHWModel(hwmodel, &sModel));
//    strcpy(hwmodel, "D16AP");  //XXX CUSTOM
    printf("[GK] Got model: %s\n",hwmodel);

    assure(sizeof(firmwareUrl)>sBuild+sMachine+strlen(IPSW_URL_TEMPLATE)+1);
    snprintf(firmwareUrl, sizeof(firmwareUrl), IPSW_URL_TEMPLATE, machine,build);
    
    char path[1024] = {0};
    snprintf(path, sizeof(path), "%sBuildmanifest.plist", getenv("TMPDIR"));
    
    printf("[GK] Opening remote url %s\n",firmwareUrl);
    assure(fz = fragmentzip_open(firmwareUrl));
    
    printf("[GK] Downloading Buildmanifest");
    assure(!fragmentzip_download_file(fz, "BuildManifest.plist", path, fragmentzip_callback));
    printf(" ok!\n");
    
    assure(kernelpath = getKernelpath(path, hwmodel, isResearchKernel));
    printf("[GK] Downloading kernel: %s",kernelpath);
    assure(!fragmentzip_download_file(fz, kernelpath, downloadPath, fragmentzip_callback));
    printf(" ok!\n");

    printf("[GK] Done!\n");
    
    
error:
    safeFree(kernelpath);
    return err;
}


const char* libgrabkernel_version(){
    return "Libgrabkernel Version: " + LIBGRABKERNEL_VERSION_COMMIT_SHA + " - " + LIBGRABKERNEL_VERSION_COMMIT_COUNT;
}
