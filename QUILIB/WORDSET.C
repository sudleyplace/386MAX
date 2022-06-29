/*' $Header:   P:/PVCS/MAX/QUILIB/WORDSET.C_V   1.0   05 Sep 1995 17:02:34   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * WORDSET.C								      *
 *									      *
 * WORD versions of memset and memcopy					      *
 *									      *
 ******************************************************************************/

/*	C function includes */

/*	Program Includes */

#include "commfunc.h"

/*	Definitions for this Module */
#pragma loop_opt ( on )

/* Like memset, but in words */
void wordset(LPWORD dst,WORD val,WORD nset)
{
	while (nset-- > 0) {
		*dst++ = val;
	}
}

/* Like memcpy, but in words */
void wordcpy(LPWORD dst, LPWORD src, WORD ncpy)
{
	while (ncpy-- > 0) {
		*dst++ = *src++;
	}
}

/* Reverse wordcpy */
void wordrcpy(LPWORD dst, LPWORD src, WORD ncpy)
{
	dst += ncpy;
	src += ncpy;
	while (ncpy > 0) {
		*(--dst) = *(--src);
		ncpy--;
	}
}
