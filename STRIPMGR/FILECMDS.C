// FILECMDS.C - File maintenance routines for STRIPMGR
//   Copyright (c) 1988, 1989, 1990  Rex C. Conn   GNU General Public License version 3

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
// #include <memory.h>
#include <setjmp.h>
#include <share.h>
#include <string.h>

#include "stripmgr.h"


extern jmp_buf *pEnv;
extern void pushenv (void);
extern void popenv (void);


// copy from the source to the target files
//   outname = target file name
//   inname = source file name
int pascal filecopy(char *outname, char *inname)
{
	unsigned int buf_size, bytes_read, bytes_written;
	int rval, infile = 0, outfile = 0;
	char far *segptr;

	// check for same name
	if (stricmp(inname,outname) == 0)
		return (error(ERROR_BATPROC_DUP_COPY,inname));

	// request memory block (64K more or less)
	buf_size = 0xFFF0;
	if ((segptr = dosmalloc(&buf_size)) == 0L)
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));

	pushenv (); // Save old jmp_buf

	if (setjmp(*pEnv) == -1) {	// ^C trapping
		rval = CTRLC;
		goto filebye;
	}

	// open input file for read
	if ((rval = _dos_open(inname,(O_RDONLY | SH_COMPAT),&infile)) != 0) {
		rval = error(rval,inname);
		goto filebye;
	}

	// create or truncate target file
	if ((rval = _dos_creat(outname,_A_NORMAL,&outfile)) != 0) {
		// DOS returns an odd error if it couldn't create the file!
		if (rval == 2)
			rval = ERROR_BATPROC_CANT_CREATE;
		rval = error(rval,outname);
		goto filebye;
	}

	while (buf_size != 0) {

		if ((rval = _dos_read(infile,segptr,buf_size,&bytes_read)) != 0) {
			rval = error(rval,inname);
			break;
		}

		if (bytes_read == 0)
			break;

		if ((rval = _dos_write(outfile,segptr,bytes_read,&bytes_written)) != 0) {
			rval = error(rval,outname);
			goto filebye;
		}

		if (bytes_read != bytes_written) {	// error in writing
			rval = error(ERROR_BATPROC_WRITE_ERROR,outname);
			goto filebye;
		}
	}

	// set the file date & time to the same as the source
	if (_dos_getftime(infile,&bytes_written,&bytes_read) == 0)
		_dos_setftime(outfile,bytes_written,bytes_read);

filebye:
	popenv (); // Restore previous jmp_buf

	dosfree(segptr);

	if (infile > 0)
		_dos_close(infile);

	if (outfile > 0) {
		_dos_close(outfile);

		// if an error writing to the output file, delete it
		if (rval)
			remove(outname);
	}

	return rval;
}

