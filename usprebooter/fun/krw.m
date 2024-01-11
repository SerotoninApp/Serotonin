//
//  krw.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/29.
//

#include "krw.h"
#include "libkfd.h"
#include "mdc/helpers.h"
#include "kpf/patchfinder.h"

uint64_t _kfd = 0;

uint64_t do_kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method)
{
//    remove([NSString stringWithFormat:@"%@/Documents/kfund_offsets.plist", NSHomeDirectory()].UTF8String);  //TEMPORARY: remove offsets plist to check if patchfinder is working
//    do_static_patchfinder();
    _kfd = kopen(puaf_pages, puaf_method, kread_method, kwrite_method);
    return _kfd;
}

void do_kclose(void)
{
    kclose((struct kfd*)(_kfd));
}

void early_kread(uint64_t kfd, u64 kaddr, void* uaddr, u64 size)
{
    kread((struct kfd*)(kfd), kaddr, uaddr, size);
}

uint64_t early_kread64(uint64_t kfd, uint64_t where) {
    uint64_t out;
    kread((struct kfd*)(kfd), where, &out, sizeof(uint64_t));
    return out;
}

uint32_t early_kread32(uint64_t kfd, uint64_t where) {
    return early_kread64(kfd, where) & 0xffffffff;
}

void early_kreadbuf(uint64_t kfd, uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = early_kread32(kfd, curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}


void do_kread(u64 kaddr, void* uaddr, u64 size)
{
    kread(_kfd, kaddr, uaddr, size);
}

void do_kwrite(void* uaddr, u64 kaddr, u64 size)
{
    kwrite(_kfd, uaddr, kaddr, size);
}

uint64_t get_kslide(void) {
    return ((struct kfd*)_kfd)->perf.kernel_slide;
}

uint64_t get_kernproc(void) {
    return ((struct kfd*)_kfd)->info.kaddr.kernel_proc;
}

uint64_t get_selftask(void) {
    return ((struct kfd*)_kfd)->info.kaddr.current_task;
}

uint64_t get_selfpmap(void) {
    return ((struct kfd*)_kfd)->info.kaddr.current_pmap;
}

uint64_t get_kerntask(void) {
    return ((struct kfd*)_kfd)->info.kaddr.kernel_task;
}


uint8_t kread8(uint64_t where) {
    uint8_t out;
    kread(_kfd, where, &out, sizeof(uint8_t));
    return out;
}
uint32_t kread16(uint64_t where) {
    uint16_t out;
    kread(_kfd, where, &out, sizeof(uint16_t));
    return out;
}
uint32_t kread32(uint64_t where) {
    uint32_t out;
    kread(_kfd, where, &out, sizeof(uint32_t));
    return out;
}
uint64_t kread64(uint64_t where) {
    uint64_t out;
    kread(_kfd, where, &out, sizeof(uint64_t));
    return out;
}

//Thanks @jmpews
uint64_t kread64_smr(uint64_t where) {
    uint64_t value = kread64(where) | 0xffffff8000000000;
    if((value & 0x400000000000) != 0)
        value &= 0xFFFFFFFFFFFFFFE0;
    return value;
}

void kwrite8(uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(where+1);
    _buf[2] = kread8(where+2);
    _buf[3] = kread8(where+3);
    _buf[4] = kread8(where+4);
    _buf[5] = kread8(where+5);
    _buf[6] = kread8(where+6);
    _buf[7] = kread8(where+7);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite16(uint64_t where, uint16_t what) {
    u16 _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(where+2);
    _buf[2] = kread16(where+4);
    _buf[3] = kread16(where+6);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

void kwrite32(uint64_t where, uint32_t what) {
    u32 _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(where+4);
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}
void kwrite64(uint64_t where, uint64_t what) {
    u64 _buf[1] = {};
    _buf[0] = what;
    kwrite((u64)(_kfd), &_buf, where, sizeof(u64));
}

uint64_t do_vtophys(uint64_t what) {
    return vtophys((u64)(_kfd), what);
}

uint64_t do_phystokv(uint64_t what) {
    return phystokv((u64)(_kfd), what);
}

uint64_t kread64_ptr(uint64_t kaddr) {
    uint64_t ptr = kread64(kaddr);
    if ((ptr >> 55) & 1) {
        return ptr | 0xFFFFFF8000000000;
    }

    return ptr;
}

void kreadbuf(uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = kread32(curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}
