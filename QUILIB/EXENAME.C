/*' $Header:   P:/PVCS/MAX/QUILIB/EXENAME.C_V   1.0   05 Sep 1995 17:02:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * EXENAME.C								      *
 *									      *
 * Save/restore pointer to .EXE file path and name			      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>

#include "commfunc.h"

char *ExeName = NULL;	/* == argv[0] */

char *set_exename(char *name,char *defname) /* Save program file name for later */
{
	if (!name || !(*name)) {
		/* DOS 2.x */
		ExeName = defname;
	}
	else ExeName = name;
	return ExeName;
}

char *get_exename(void) /* Return path and program file name */
{
	return ExeName;
}

void get_exepath(char *path,int npath)	/* Return path stem of program file name */
{
	int nc;
	char *bslash;

	bslash = strrchr(ExeName, '\\');
	if (bslash) bslash++;
	else {
		/* We should never get here */
		bslash = strrchr(ExeName, ':');
		if (bslash) bslash++;
		else	    bslash = ExeName;
	}
	nc = bslash - ExeName;
	if (nc > npath-1) nc = npath-1;
	if (nc > 0) {
		memcpy(path,ExeName,nc);
		path += nc;
	}
	*path = '\0';
}
