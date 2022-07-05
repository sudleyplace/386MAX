// FILECOPY.C - File copying routine for SETUP.EXE
//   Copyright (c) 1995  Rex C. Conn   GNU General Public License version 3

#include <windows.h>
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

#include "setup.h"


// copy a file to a new name
int FileCopy(char *szTarget, char *szSource)
{
	unsigned int uSize, uBytesRead, uBytesWritten;
	int rval = 0;
    HFILE hInFile, hOutFile;
	char *pchSegment;

	// request memory block (64K more or less)
	uSize = 0xFFF0;
	if ((pchSegment = AllocMem( &uSize )) == 0L)
		return -1;

	// open input file for read
	if (( hInFile = _lopen( szSource, READ | OF_SHARE_COMPAT )) == HFILE_ERROR) {
		rval = -1;
		goto FileBye;
	}

	// create or truncate target file
	if (( hOutFile = _lcreat( szTarget, 0 )) == HFILE_ERROR ) {
		rval = -1;
		goto FileBye;
	}

	while (uSize != 0) {

		if (( uBytesRead = _lread( hInFile, pchSegment, uSize )) == HFILE_ERROR ) {
			rval = -1;
			break;
		}

		if (uBytesRead == 0)
			break;
        
		if (( uBytesWritten = _lwrite( hOutFile, pchSegment, uBytesRead )) == HFILE_ERROR) {
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

	if ( hInFile > 0 )
		_lclose( hInFile );

	if ( hOutFile > 0 ) {
		_lclose( hOutFile );

		// if an error writing to the output file, delete it
		if (rval)
			remove( szTarget );
	}

	return rval;
}

