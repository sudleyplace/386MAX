/*' $Header:   P:/PVCS/MAX/QUILIB/CHKABORT.C_V   1.0   05 Sep 1995 17:01:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CHKABORT.C								      *
 *									      *
 * Do user abort dialog 						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdlib.h>

/* Local Includes */
#include "commfunc.h"
#include "ui.h"

/* Local variables */
static BOOL AlreadyAborting = FALSE;


/*********************************** CHKABORT *********************************/
/* Check on abort request */
/* Returns 1 if the user wishes to abort, 0 if not */
int _cdecl chkabort (void)
{
	/* If we're already here, don't come in again */
	if (AlreadyAborting) return FALSE;
	AlreadyAborting = TRUE;
	disableButton(KEY_ESCAPE,TRUE);

	disable23 ();

	if (askMessage(554) == RESP_YES) {
		/* User wants to abort, do it NOW */
		abortprep(0);
		exit(1);
	}

	enable23 ();
	disableButton(KEY_ESCAPE,FALSE);
	AlreadyAborting = FALSE;
	return FALSE;
} /* End CHKABORT */
