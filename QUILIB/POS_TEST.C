/*' $Header:   P:/PVCS/MAX/QUILIB/POS_TEST.C_V   1.0   05 Sep 1995 17:02:38   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * POS_TEST.C								      *
 *									      *
 * Test POS value against switch settings				      *
 *									      *
 ******************************************************************************/

/*
 *	Compares a 8-bit binary value with a 'switch' string read
 *  from an ADF file.  Returns TRUE if match.
 */

#include "commfunc.h"

int pos_test(			/* Test a POS value */
	WORD posval,		/* Value to test */
	char *posstr)		/* POS switch string to compare with */
{
	int k;
	int bit = 0x80;

	if (!posstr || !(*posstr)) return 0;
	for (k=0; k < 8; k++, bit = bit >> 1) {
		switch (posstr[k]) {
		case '0':       /* This bit must be 0 */
			if (posval & bit) return FALSE;
			break;
		case '1':       /* This bit must be 1 */
			if (!(posval & bit)) return FALSE;
			break;
		case 'X':       /* Don't care about this bit */
		case 'x':
			break;
		default:
			return FALSE;
		}
	}
	return TRUE;
}
