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

#include "libhelper/libhelper.h"
#include "version.h"

int libhelper_is_debug ()
{
	return LIBHELPER_DEBUG;
}

char *libhelper_get_version_long ()
{
    return LIBHELPER_VERSION_LONG;
}

char *libhelper_get_version ()
{
    return LIBHELPER_VERSION;
}

char *libhelper_get_version_with_arch ()
{
    return LIBHELPER_VERS_WITH_ARCH;
}

char *libhelper_version_string ()
{
    return BUILD_TARGET_CAP " Libhelper " LIBHELPER_VERSION "; " __TIMESTAMP__ "; " LIBHELPER_VERS_WITH_ARCH;
}
