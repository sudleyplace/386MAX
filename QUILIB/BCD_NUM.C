/*' $Header:   P:/PVCS/MAX/QUILIB/BCD_NUM.C_V   1.0   05 Sep 1995 17:01:54   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BCD_NUM.C								      *
 *									      *
 * Decode a BCD integer 						      *
 *									      *
 ******************************************************************************/

#include "commfunc.h"

unsigned short bcd_num(unsigned short num)
{
	return (
		(((num >> 12) & 0x0f) * 1000) +
		(((num >>  8) & 0x0f) * 100 ) +
		(((num >>  4) & 0x0f) * 10  ) +
		 ( num	      & 0x0f)	      );
}
