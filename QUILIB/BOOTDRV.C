/*' $Header:   P:/PVCS/MAX/QUILIB/BOOTDRV.C_V   1.0   05 Sep 1995 17:01:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BOOTDRV.C								      *
 *									      *
 * Function to return boot drive					      *
 *									      *
 ******************************************************************************/

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "commfunc.h"

/****************************** get_bootdrive ********************************/
#pragma optimize ("leg",off)
char get_bootdrive(void)
{
	char drive = 0;

	if (_osmajor >= 4) {
		/* DOS 4.00+, get boot drive from DOS */
		_asm {
			mov ax,3305h
			int 21h 	; Do the function
			add dl,'@'      ; Convert to drive letter
			mov drive,dl ; ..and store it
		}
	}
	else {
		char *p = getenv("COMSPEC");

		if (p && strlen(p) > 1 && isalpha(p[0]) && p[1] == ':') {
			drive = (char) toupper(p[0]);
		}
		if (drive < 'A' || drive > 'Z') {
			/* When in doubt, mumble */
			drive = 'C';
		}
	}
	return drive;
}
#pragma optimize ("",on)
