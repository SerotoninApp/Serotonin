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
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

file_t *file_create ()
{
	file_t *file = malloc (sizeof (file_t));
	memset (file, '\0', sizeof (file_t));
	return file;
}


file_t *file_load (const char *path)
{
	file_t *file = file_create ();

	/* set the file path */
	if (!path) {
		//error ("File path is not valid\n");
		return NULL;
	}
	file->path = strdup (path);

	/* create the file descriptor */
	int fd = open (file->path, O_RDONLY);

	/* calculate the file file */
	struct stat st;
	fstat (fd, &st);
	file->size = st.st_size;

	/* mmap() the file */
	file->data = mmap (NULL, file->size, PROT_READ, MAP_PRIVATE, fd, 0);
	close (fd);

	if (file->data == MAP_FAILED) {
		errorf ("file_load(): mapping failed: %d\n", errno);
		return NULL;
	}
	
	return (file->data) ? file : NULL;
}


void file_free (file_t *file)
{
	file = NULL;
	free (file);
}


int file_write_new (char *filename, unsigned char *buf, size_t size)
{
	FILE *f = fopen (filename, "wb");
	if (!f)
		return LH_FILE_FAILURE;
	
	size_t res = fwrite (buf, sizeof (char), size, f);
	fclose (f);

	return res;
}


const void *
file_get_data (file_t *f, uint32_t offset)
{
	return (void *) (f->data + offset);
}


void
file_read_data (file_t *f, uint32_t offset, void *buf, size_t size)
{
	memcpy (buf, file_get_data (f, offset), size);
}


void *
file_dup_data (file_t *f, uint32_t offset, size_t size)
{
	void *buf = malloc (size);
	file_read_data (f, offset, buf, size);
	return buf;
}