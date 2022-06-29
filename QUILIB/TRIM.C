/*' $Header:   P:/PVCS/MAX/QUILIB/TRIM.C_V   1.1   30 May 1997 12:09:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * TRIM.C								      *
 *									      *
 * Trim leading and trailing blanks					      *
 *									      *
 ******************************************************************************/

/*
 *	Author:  Alan C. Lindsay
 *	Modified:  15 Oct 1986	add headers
 *		   08 Apr 1987	add ntrim()
 *
 ************************************************************************
 *
 *	Routine:  trim, ntrim
 *
 *	Purpose:  Trim leading and trailing blanks
 *
 *	Input Parameters:
 *		char *str;	text string
 *		int n;		length of string (ntrim only)
 *
 *	Return:  (int) Number of characters in altered string.
 *
 *
 *	Alters the given string to remove any leading and/or
 *  trailing white space.  The string is unchanged otherwise.
 *  Returns:
 *
 *	"White space" is defined as any character that would cause
 *  isspace() to return 1.
 *
 *	See Also:  squish(), skpbln(), trnbln()
 *
 *
 ************************************************************************
 */

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "commfunc.h"

int trim(char *s)
{
	char *cp,*cp2;
	int n;

	n = strlen(s);
	if (n==0) return 0;
	n--;
	for (cp = s+n; n>0; n--) {
		if (isspace(*cp)) *cp-- = '\0';
		else break;
	}

	cp = s;
	while(*cp) {
		if (isspace(*cp)) cp++;
		else break;
	}
	cp2 = s;
	n = 0;
	while(*cp) {
		*cp2++ = *cp++;
		n++;
	}
	*cp2 = '\0';
	return n;
}

int ntrim(char *s,int n)
{
	if (n < 1) return 0;
	s[n-1] = '\0';
	return (trim(s));
}
