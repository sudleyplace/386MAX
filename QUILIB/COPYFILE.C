/*' $Header:   P:/PVCS/MAX/QUILIB/COPYFILE.C_V   1.2   30 May 1997 12:08:58   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * COPYFILE.C								      *
 *									      *
 * Functions to copy a file						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <io.h>
#include <fcntl.h>
#include <dos.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "libtext.h"
#include "myalloc.h"
#include "dmalloc.h"


BOOL orcopy(char *src, char *dst, WORD flags)
/* Copy a file, ORing flags into destination at EOF-6 */
{
	int n1,n2;
	int f1,f2,rtn;
	unsigned short nbuf;
	unsigned short dt,tm;

	char _far *bigbuf = NULL;

	f1 = _open(src, O_RDONLY | O_BINARY );
	if (f1<0) {
		/* Unable to _open file */
		errorMessage(201);
		return FALSE;
	}

	dt = tm = 0;
	_dos_getftime (f1, &dt, &tm);

	f2 = _open (dst, O_RDWR|O_BINARY|O_TRUNC|O_CREAT,S_IREAD|S_IWRITE);
	if (f2<0) {
		/* Unable to create file */
		errorMessage(560);
		goto error;
	}

	nbuf = 0xfe00;
	do {
		bigbuf = _dmalloc(nbuf);
		if (!bigbuf) nbuf /= 2;
	} while(!bigbuf && nbuf > 512);

	if (!bigbuf) {
		/* Out of memory */
		errorMessage(215);
		goto error;
	}

	rtn = 1;
	while (0 == _dos_read(f1,bigbuf,nbuf,&n1) && n1 != 0) {
		if (n1 == -1) {
			/* Read error */
			errorMessage(561);
			break;
		}
		if (_dos_write(f2,bigbuf,n1,&n2)) {
			/* Write error */
			errorMessage(562);
			break;
		}
		if (n2 != n1) {
			/* Out of disk space */
			errorMessage(232);
			goto error;
		}
	}
	_dfree(bigbuf);
	_close(f1);

	// If flags are being ORed from destination into source at new
	// destination, set 'em now.
	if (flags) {
	  WORD Src_flags = 0;

	  if (_lseek (f2, -4L - sizeof (flags), SEEK_END) != -1L)
		_read (f2, &Src_flags, sizeof (Src_flags));
		flags |= Src_flags;
		_lseek (f2, 0L - sizeof (flags), SEEK_CUR); // Back up
		_write (f2, &flags, sizeof (flags)); // Ignore error
	} // OR flags into destination copy

	_dos_setftime (f2, dt, tm);
	_close(f2);

	return TRUE;

error:
	if (f1 >= 0) _close(f1);
	if (f2 >= 0) _close(f2);
	if (bigbuf) _dfree(bigbuf);
	return FALSE;

} // orcopy ()

BOOL copy(char *src, char *dst)
/* Simple file copy */
{
  return (orcopy (src, dst, 0));
} // copy ()

