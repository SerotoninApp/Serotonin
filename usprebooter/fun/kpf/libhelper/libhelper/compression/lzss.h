//===--------------------------- libhelper ----------------------------===//
//
//                         The Libhelper Project
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  Copyright (C) 2019, Is This On?, @h3adsh0tzz
//	Copyright (C) 2020, Is This On?, @h3adsh0tzz
//
//  me@h3adsh0tzz.com.
//
//
//===------------------------------------------------------------------===//
/*
 *  LZSS.C -- A data compression program for decompressing lzss compressed objects
 *  4/6/1989 Haruhiko Okumura
 *  Use, distribute, and modify this program freely.
 *  Please send me your improved versions.
 *  PC-VAN      SCIENCE
 *  NIFTY-Serve PAF01022
 *  CompuServe  74050,1022
 *
 *  Copyright (c) 2003 Apple Computer, Inc.
 *  DRI: Josh de Cesare
 */

#include <stdint.h>

#ifndef LIBHELPER_LZSS_H
#define LIBHELPER_LZSS_H

extern uint32_t         lzadler32               (uint8_t *buf, int32_t len);
extern uint8_t         *compress_lzss           (uint8_t *dst, uint32_t dstlen, uint8_t *src, uint32_t srcLen);
extern int              decompress_lzss         (uint8_t *dst, uint8_t *src, uint32_t srclen);

#endif /* libhelper_lzss_h */