/*' $Header:   P:/PVCS/MAX/QUILIB/NOMEM.C_V   1.0   05 Sep 1995 17:02:30   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * NOMEM.C								      *
 *									      *
 * Out of memory exit function						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <stdio.h>

/*	Program Includes */

#include "commfunc.h"
#include "message.h"


/**
*
* Name		nomem_bailout - Issue 'out of memory' message and exit.
*
* Synopsis	void nomem_bailout(int codenum)
*
* Parameters
*		int codenum;	Location specific code number
*
* Description
*
*
* Returns	doesn't
*
**/
void nomem_bailout(int codenum)
{
	PMSG pMsg;
	char temp[128];

	/* Use generic "Out of Memory" message, with code number appended */
	pMsg = findMessage(215);
	sprintf(temp,"%s (%d)",pMsg->message,codenum);
	pMsg->message = temp;
	errorMessage(215);
	abortprep(0);
	exit(254);
}
