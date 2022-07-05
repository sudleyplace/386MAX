/*' $Header:   P:/PVCS/MAX/QUILIB/SLEEP.C_V   1.0   05 Sep 1995 17:02:40   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SLEEP.C								      *
 *									      *
 * Sleep the process							      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <time.h>

#include "commdef.h"
#include "commfunc.h"

/* Sleep the process for a fixed number of milliseconds */
void sleep(long msecs)
{
	clock_t t0;
	clock_t t1;


	t0 = clock();
	do {
		t1 = clock();
		if (t1 < t0) t0 = 1 - t0;
	} while ((t1-t0) < msecs);
}
