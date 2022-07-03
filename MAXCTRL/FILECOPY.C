// FILECOPY.C - File copying routine for SETUP.EXE
//   Copyright (c) 1995  Rex C. Conn   GNU General Public License version 3

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <share.h>
#include <string.h>

#include "toolbox.h"


// copy a file to a new name
int FileCopy(char *szTarget, char *szSource)
{
	unsigned int uSize, uBytesRead, uBytesWritten;
	int rval = 0, hInFile, hOutFile;
	char *pchSegment;

	// request memory block (64K more or less)
	uSize = 0xFFF0;
	if ((pchSegment = AllocMem( &uSize )) == 0L)
		return -1;

	// open input file for read
	if (_dos_open( szSource, (O_RDONLY | SH_COMPAT), &hInFile ) != 0) {
		rval = -1;
		goto FileBye;
	}

	// create or truncate target file
	if (_dos_creat( szTarget, _A_NORMAL, &hOutFile ) != 0) {
		rval = -1;
		goto FileBye;
	}

	while (uSize != 0) {

		if (_dos_read( hInFile, pchSegment, uSize, &uBytesRead ) != 0) {
			rval = -1;
			break;
		}

		if (uBytesRead == 0)
			break;

		if (_dos_write( hOutFile, pchSegment, uBytesRead, &uBytesWritten ) != 0) {
			rval = -1;
			break;
		}

		if (uBytesRead != uBytesWritten) {	// error in writing
			rval = -1;
			break;
		}
	}

FileBye:
	FreeMem(pchSegment);

	// set the file date & time to the same as the source
	(void)_dos_getftime( hInFile, &uBytesRead, &uBytesWritten );
	(void)_dos_setftime( hOutFile, uBytesRead, uBytesWritten );

	if (hInFile > 0)
		_dos_close( hInFile );

	if (hOutFile > 0) {
		_dos_close( hOutFile );

		// if an error writing to the output file, delete it
		if (rval)
			remove( szTarget );
	}

	return rval;
}

