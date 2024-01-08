#import <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOSurface/IOSurfaceRef.h>
#import "IOMobileFramebuffer.h"
#include <mach/mach.h>
#include <pthread.h>
#include <spawn.h>
#include <stdio.h>

#include "console/video_console.c"

//void IOMobileFramebufferSwapDirtyRegion(IOMobileFramebufferRef conn);

IOMobileFramebufferRef fbConn;
IOSurfaceRef surface, oldSurface;

pthread_t logger;
// int pfd[2];

// void initialize_prescreen(struct vc_info vinfo);

void initFramebuffer() {
  CGContextRef context;

  printf("[*] Connection init\n");
  printf("[*] size variable init\n");
  IOMobileFramebufferDisplaySize size;
  printf("[*] getting main display\n");
  IOMobileFramebufferGetMainDisplay(&fbConn);
  printf("[*] getting display size\n");
  IOMobileFramebufferGetDisplaySize(fbConn, &size);
  printf("[i] found size %f*%f\n", size.height, size.width);
  printf("[*] getting iosurface\n");

  NSDictionary *properties = @{
    (id)kIOSurfaceIsGlobal: @(NO),
    (id)kIOSurfaceWidth: @(size.width),
    (id)kIOSurfaceHeight: @(size.height),
    (id)kIOSurfacePixelFormat: @((uint32_t)'BGRA'),
    (id)kIOSurfaceBytesPerElement: @(4)
  };
  surface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);

  //IOMobileFramebufferGetLayerDefaultSurface
  //IOMobileFramebufferCopyLayerDisplayedSurface(fbConn, 0, &surface);
  printf("[i] got surface %p\n", surface);

  printf("[*] vinfo setup\n");
  struct vc_info vinfo;
  vinfo.v_width = IOSurfaceGetWidth(surface);
  vinfo.v_height = IOSurfaceGetHeight(surface);
  vinfo.v_depth = 32; // 16, 32?
  vinfo.v_type = 0;
  vinfo.v_scale = 2; //kPEScaleFactor2x;
  vinfo.v_name[0]  = 0;
  vinfo.v_rowbytes = IOSurfaceGetBytesPerRow(surface);
  vinfo.v_baseaddr = (unsigned long)IOSurfaceGetBaseAddress(surface);
  printf("[*] initializing\n");
  IOSurfaceLock(surface, 0, nil);
  //memset((void *)vinfo.v_baseaddr, 0xFFFFFFFF, vinfo.v_width * vinfo.v_height);
  initialize_prescreen(vinfo);
  IOSurfaceUnlock(surface, 0, 0);

  printf("[√] PTR %p\n", IOSurfaceGetBaseAddress(surface));

  int token;
  CGRect frame = CGRectMake(0, 0, vinfo.v_width, vinfo.v_height);
  IOMobileFramebufferSwapBegin(fbConn, &token);
  IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame, 0);
  IOMobileFramebufferSwapEnd(fbConn);
}

void printText(char *str) {
    //CGRect frame = CGRectMake(0, 0, IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface));
    for (int i = 0; str[i]; i++) {
        //IOSurfaceLock(surface, 0, nil);
        char c = str[i];
        vcputc(0, 0, c);
        if (c == '\n' || !str[i+1]) {
            vcputc(0, 0, '\r');
            //IOSurfaceUnlock(surface, 0, 0);
            //IOMobileFramebufferSwapBegin(fbConn, NULL);
            //IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame);
            //IOMobileFramebufferSwapEnd(fbConn);
        }
    }
}

pthread_t logger;
int pfd[2];
static void *logger_thread() {
    initFramebuffer();
    CGRect frame = CGRectMake(0, 0, IOSurfaceGetWidth(surface), IOSurfaceGetHeight(surface));

    setvbuf(stdout, 0, _IOLBF, 0);
    setvbuf(stderr, 0, _IONBF, 0);
    pipe(pfd);
    dup2(pfd[1], 1);
    dup2(pfd[1], 2);

    //ssize_t rsize;
    char c;
    uint8_t linesPrinted = 0;
    while (read(pfd[0], &c, 1) > 0) {
        vcputc(0, 0, c);
        if (c == '\n') {
            vcputc(0, 0, '\r');
            static int lines = 0;
            if (lines++ > 100) return NULL;
            CGRect frame = CGRectMake(0, 0, vinfo.v_width, vinfo.v_height);
            IOMobileFramebufferSwapBegin(fbConn, NULL);
            IOMobileFramebufferSwapSetLayer(fbConn, 0, surface, frame, frame, 0);
            IOMobileFramebufferSwapEnd(fbConn);
        }
    }
    return NULL;
}

void initVerboseFramebuffer() {
  pthread_create(&logger, 0, logger_thread, 0);
  pthread_detach(logger);
  for (int i = 0; i < 4; i++) {
    printf(" \n");
  }
  printf("Done: initVerboseFramebuffer\n");
}

#include <netinet/in.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <assert.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOTypes.h>
#include <dlfcn.h>
#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/CGImageSource.h>
//#include <IOMobileFramebuffer/IOMobileframebuffer.h>
//#include <IOSurface/IOSurface.h>
#include <sys/stat.h>

#define WHITE 0xffffffff
#define BLACK 0x00000000
static void *base = NULL;
static int bytesPerRow = 0;
static int height = 0;
static int width = 0;

int init_display(void) {
    if (base) return 0;
    IOMobileFramebufferRef display;
    IOMobileFramebufferGetMainDisplay(&display);
    IOMobileFramebufferDisplaySize size;
    IOMobileFramebufferGetDisplaySize(display, &size);
    IOSurfaceRef buffer;
    IOMobileFramebufferGetLayerDefaultSurface(display, 0, &buffer);
    printf("got display %p\n", display);
    width = size.width;
    height = size.height;
    printf("width: %d, height: %d\n", width, height);

    // create buffer
    CFMutableDictionaryRef properties = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionarySetValue(properties, CFSTR("IOSurfaceIsGlobal"), kCFBooleanFalse);
    CFDictionarySetValue(properties, CFSTR("IOSurfaceWidth"), CFNumberCreate(NULL, kCFNumberIntType, &width));
    CFDictionarySetValue(properties, CFSTR("IOSurfaceHeight"), CFNumberCreate(NULL, kCFNumberIntType, &height));
    CFDictionarySetValue(properties, CFSTR("IOSurfacePixelFormat"), CFNumberCreate(NULL, kCFNumberIntType, &(int){ 0x42475241 }));
    CFDictionarySetValue(properties, CFSTR("IOSurfaceBytesPerElement"), CFNumberCreate(NULL, kCFNumberIntType, &(int){ 4 }));
    buffer = IOSurfaceCreate(properties);
    printf("created buffer at: %p\n", buffer);
    IOSurfaceLock(buffer, 0, 0);
    printf("locked buffer\n");
    base = IOSurfaceGetBaseAddress(buffer);
    printf("got base address at: %p\n", base);
    bytesPerRow = IOSurfaceGetBytesPerRow(buffer);
    printf("got bytes per row: %d\n", bytesPerRow);
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int offset = i * bytesPerRow + j * 4;
            *(int *)(base + offset) = 0xFFFFFFFF;
        }
    }
    printf("wrote to buffer\n");
    IOSurfaceUnlock(buffer, 0, 0);
    printf("unlocked buffer\n");

    int token;
    IOMobileFramebufferSwapBegin(display, &token);
    IOMobileFramebufferSwapSetLayer(display, 0, buffer, (CGRect){ 0, 0, width, height }, (CGRect){ 0, 0, width, height }, 0);
    IOMobileFramebufferSwapEnd(display);
    return 0;
}

#define BOOT_IMAGE_PATH "/var/mobile/Serotonin.jp2"
int bootscreend_main(void) {
    init_display();
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int offset = i * bytesPerRow + j * 4;
            *(int *)(base + offset) = 0x00000000;
        }
    }

    CFURLRef imageURL = NULL;
    CGImageSourceRef cgImageSource = NULL;
    CGImageRef cgImage = NULL;
    CGContextRef context = NULL;
    int retval = -1;

    imageURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR(BOOT_IMAGE_PATH), kCFURLPOSIXPathStyle, false);
    if (!imageURL) {
        fprintf(stderr, "could not create image URL\n");
        goto finish;
    }
    cgImageSource = CGImageSourceCreateWithURL(imageURL, NULL);
    if (!cgImageSource) {
        fprintf(stderr, "could not create image source\n");
        goto finish;
    }
    cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, NULL);
    if (!cgImage) {
        fprintf(stderr, "could not create image\n");
        goto finish;
    }

    CGRect destinationRect = CGRectZero;
    CGFloat imageAspectRatio = (CGFloat)CGImageGetWidth(cgImage) / CGImageGetHeight(cgImage);

    if (width / height > imageAspectRatio) {
        destinationRect.size.width = width;
        destinationRect.size.height = width / imageAspectRatio;
    } else {
        destinationRect.size.width = height * imageAspectRatio;
        destinationRect.size.height = height;
    }
    
    destinationRect.origin.x = (width - CGRectGetWidth(destinationRect)) / 2;
    destinationRect.origin.y = (height - CGRectGetHeight(destinationRect)) / 2;

    context = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst);
    if (!context) {
        fprintf(stderr, "could not create context\n");
        goto finish;
    }

    CGContextDrawImage(context, destinationRect, cgImage);

    retval = 0;
    fprintf(stderr, "bootscreend: done\n");

finish:
    if (context) CGContextRelease(context);
    if (cgImage) CGImageRelease(cgImage);
    if (cgImageSource) CFRelease(cgImageSource);
    if (imageURL) CFRelease(imageURL);

    return retval;
}
