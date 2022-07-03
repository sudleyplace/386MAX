// ERROR.C - error routines for BATPROC
//   (c) 1990  Rex C. Conn  GNU General Public License version 3

#include <stdio.h>

// force definition of the global variables
#define DEFINE_GLOBALS 1

#include "batproc.h"


// display proper BATPROC command usage
int pascal usage(register char *s)
{
	extern char *i_cmd_name;	// name of command being executed

	qprintf(STDERR,USAGE,i_cmd_name);

	for ( ; *s; s++) {
		// expand ^ to [d:][path]filename
		if (*s == '^')
			qputs(STDERR,FILE_SPEC);
		// expand ~ to [d:]pathname
		else if (*s == '~')
			qputs(STDERR,PATH_SPEC);
#ifdef COMPAT_4DOS
		// expand # to [bright][blink] fg ON bg
		else if (*s == '#')
			qputs(STDERR,COLOR_SPEC);
#endif
		else
			qputc(STDERR,*s);
	}
	qputc(STDERR,'\n');

	return USAGE_ERR;
}


// display a BATPROC error message
int pascal error(register unsigned int code, register char *s)
{
	char far *fptr;

	// print the error message
	if (code < OFFSET_BATPROC_MSG) {
		fptr = errmsgc(code);          // find message
		qprintf(STDERR,"%.*Fs",(int)*fptr,fptr+1);
	} else 
		qputs(STDERR,int_batproc_errors[code - OFFSET_BATPROC_MSG]);

	// if s != NULL, print it (probably a filename) in quotes
	if (s != NULL)
		qprintf(STDERR," \"%s\"",s);
	qputc(STDERR,'\n');

	return ERROR_EXIT;
}

