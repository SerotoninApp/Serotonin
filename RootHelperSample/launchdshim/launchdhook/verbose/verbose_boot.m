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
    printf("Notch offset\n");
  }
  printf("Done: initVerboseFramebuffer\n");
}
