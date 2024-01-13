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

#ifndef LIBHELPER_VERSION_H
#define LIBHELPER_VERSION_H

#ifdef __cplusplus
extern "C" {
#endif
	

/***********************************************************************
* Libhelper Version.
*
*   Defines for libhelper's version string, a long library version, and
*	the current build type. This long library version takes the format
*	of other Apple projects such as xnu and clang.
*
***********************************************************************/

#define LIBHELPER_VERSION			"2.0.0"
#define LIBHELPER_VERSION_LONG		"libhelper-2000.76.31.5"
#define LIBHELPER_VERSION_TYPE		"DEVELOPMENT"
	
char *libhelper_version_string ();
	
	
/***********************************************************************
* Libhelper Debugger.
*
*   All defines and function calls regarding debugging and development
*	of libhelper.
*
***********************************************************************/

#define LIBHELPER_DEBUG				1

int libhelper_debug_status ();


/***********************************************************************
* Libhelper Platform.
*
*   The platform type, either "Darwin" for macOS/iOS et al. And "Linux"
*   for Linux-based systems. Only the correct one is defined, based on
*   the system used to compile Libhelper.
*
***********************************************************************/

#ifdef __APPLE__
#	define BUILD_TARGET				"darwin"
#	define BUILD_TARGET_CAP			"Darwin"
#else
#	define BUILD_TARGET				"linux"
#	define BUILD_TARGET_CAP			"Linux"
#endif

/**
 *	NOTE: As of libhelper-2000.16.4, support for 32-bit architecture is
 *		  no longer available.
 */
#ifdef __x86_64__
#	define BUILD_ARCH				"x86_64"
#	define BUILD_ARCH_CAP			"X86_64"
#elif __arm64__
#	define BUILD_ARCH				"arm64"
#	define BUILD_ARCH_CAP			"ARM64"
#else
#	error "Unsupported Archiecture."
#endif

#define LIBHELPER_VERS_WITH_ARCH     LIBHELPER_VERSION_LONG "/" LIBHELPER_VERSION_TYPE "_" BUILD_ARCH_CAP " " BUILD_ARCH



#ifdef __cplusplus
}
#endif

#endif /* libhelper_version_h */
