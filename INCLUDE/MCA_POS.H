/*' $Header:   P:/PVCS/MAX/INCLUDE/MCA_POS.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MCA_POS.H								      *
 *									      *
 * Function to read POS information on MCA machines			      *
 *									      *
 ******************************************************************************/

#ifndef MCAPOS_INCLUDED
#define MCAPOS_INCLUDED

#include <commdef.h>

typedef struct _mcaid { 	/* MCA Adapter ID structure */
	WORD aid;		/* Adapter ID */
	BYTE pos[4];		/* POS bytes */
	WORD suba;		/* Subaddress extension */
} MCAID;

#define MCASLOTS 9		/* How many slots on an MCA bus */

int far pascal mca_pos(MCAID far *parms);

#endif /*MCAPOS_INCLUDED*/
