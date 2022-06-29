// ERROR.C - dummy error routines for STRIPMGR
//   (c) 1990  Rex C. Conn  All rights reserved

#include <stdio.h>

// force definition of the global variables
#define DEFINE_GLOBALS 1

#include "stripmgr.h"


// for STRIPMGR, don't display anything, just return an error code
int pascal usage(register char *s)
{
	return USAGE_ERR;
}


// for STRIPMGR, don't display anything, just return an error code
int pascal error(register unsigned int code, register char *s)
{
#ifdef DEBUG
qprintf(STDERR,"error %d",code);
if (s != NULL)
	qprintf(STDERR," \"%s\"",s);
qputc(STDERR,'\n');
#endif

	return ERROR_EXIT;
}

