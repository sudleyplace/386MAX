/*' $Header:   P:/PVCS/MAX/MAXIMIZE/COPYFILE.C_V   1.1   13 Oct 1995 12:00:48   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * COPYFILE.C								      *
 *									      *
 * MAXIMIZE file copy/save functions					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>		/* Intermediate message functions */

#define COPYFILE_C
#include <maxtext.h>		/* MAXIMIZE message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef COPYFILE_C

#ifndef PROTO
#include "copyfile.pro"
#include <maxsub.pro>
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */

/*********************************** SAVEFILE *********************************/
/* Save file pointed to by "ActiveFiles [f]" */
/* */
/* The saved file name will be placed in "sActiveFiles[f]" with */
/* the same drive, path and root name as the source.  The */
/* target extension will be the first non-existant number */
/* "001, 002, etc." found for the source name */

int savefile (int f)
{
	int ii;
	char buff[100];
	int extoff;
	char pdrv[_MAX_DRIVE],
	ppath[_MAX_PATH],
	pfnam[_MAX_FNAME],
	pfext[_MAX_EXT];

	if (ActiveFiles[f] == NULL)
		return (0);

	_splitpath (ActiveFiles[f], pdrv, ppath, pfnam, pfext);

	sprintf (buff, "%s%s.", LoadString, pfnam);
	extoff = strlen (buff);

	ii = -1; // Start with .000
	strcpy (&buff[extoff], "SAV"); // Use this extension if no previous .nnn

	do {

		if (_access (buff, 0) < 0)
			break;
		ii++;

		/* if we didn't find one available, return error code */
		if (ii == 1000) return (-1);

		sprintf (&buff[extoff], "%03d", ii);

	} while (1);

	if (copyfile (ActiveFiles[f], buff)) {
		do_intmsg(FlErrMsg, buff);
		return (-1);
	}

	SavedFiles[f] = str_mem(buff);

	return (0);

} /* End SAVEFILE */

/********************************* COPYFILE ***********************************/
/* Copy a file (binary mode) */
/* Return 0 if successful */
int copyfile (char *f1, char *f2)
{
	int res = 0;

	do_intmsg(MsgCopying,f1,f2);
	disable23 ();
	if (!copy (f1, f2)) {
		AnyError = TRUE;
		res = 1;
	}
	enable23 ();

	return (res);

} /* End COPYFILE */
