/*' $Header:   P:/PVCS/MAX/QUILIB/TRNBLN.C_V   1.1   30 May 1997 12:09:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-97 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * TRNBLN.C								      *
 *									      *
 * Truncate trailing blanks						      *
 *									      *
 ******************************************************************************/

/*
 *	Author:  Alan C. Lindsay
 *	Modified:  15 Oct 1986	add headers
 *
 ************************************************************************
 *
 *	Routine:  trnbln
 *
 *	Purpose:  Truncate trailing blanks
 *
 *	Input Parameters:
 *		char *str; text string
 *
 *	Returns:  Number of characters in altered string.
 *
 *
 *	Alters the given string to remove any trailing white space.
 *  The string is unchanged otherwise.
 *
 *
 *	"White space" is defined as any character that would cause
 *  isspace() to return 1.
 *
 *	See Also:  skpbln(), squish(), trim()
 *
 *
 ************************************************************************
 */

#include <ctype.h>
#include <string.h>

#include "commfunc.h"

int trnbln (char *string)
{
	char *p;
	int n;

	n = strlen(string);
	if (n<1) return 0;
	p = string + n -1;
	while (n>0) {
		if(*p == '\f' )                 /*      Must put out form feeds!!!! */
			break;
		if (isspace(*p))
			*p-- = '\0';
		else
			break;
		n--;
	}
	return n;
}
