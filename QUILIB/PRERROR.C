/*' $Header:   P:/PVCS/MAX/QUILIB/PRERROR.C_V   1.0   05 Sep 1995 17:02:40   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PRERROR.C								      *
 *									      *
 * Function to get print spooler error message				      *
 *									      *
 ******************************************************************************/

/**
*
* Name		PRERROR -- Return an error number corresponding to one
*			   of the errors returned by the PR
*			   function family.
*
* Synopsis	int errnum = prerror (errnum);
*
*		int errstr	Pointer to a static string (null-
*				    terminated) that explains the
*				    errnum error code.
*
*		int errnum	    Error code received from another
*				    PR call.
*
* Description	This function returns a pointer to a static
*		text representation of a print spooler error.
*
*		Note: If the string returned is modified, there
*		will be unknown consequences.
*
*
* Special	If the errnum passed to the function is unknown,
* Cases 	the error string returned is "unknown error".
*
* Returns	err - The corresponing error message for this error
*
* Version	2.00
*
**/

#include "message.h"
#include "libtext.h"

#define TIME_OUT (1<<0)
#define IOERROR  (1<<3)
#define OUTOFPAPER (1<<5)

int prerror (int err)
{
	if( err &  TIME_OUT)
		err = 401;
	else if (err & IOERROR )
		err = 402;
	else if (err & OUTOFPAPER)
		err = 403;
	else
		err = 404;

	errorMessage( err );
	return ( err );
}
