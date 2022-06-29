/*' $Header:   P:/PVCS/MAX/QUILIB/LAUNDER.C_V   1.0   05 Sep 1995 17:02:14   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * LAUNDER.C								      *
 *									      *
 * Remove dirty characters from string					      *
 *									      *
 ******************************************************************************/

#include "commfunc.h"

void launder_string(char *name)
{
	char *cp = name;

	while (*cp) {
		if (*cp == '\r' || *cp == '\n') *cp = ' ';
		cp++;
	}
}
