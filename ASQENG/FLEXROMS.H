/*' $Header:   P:/PVCS/MAX/ASQENG/FLEXROMS.H_V   1.0   05 Sep 1995 15:06:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * FLEXROMS.H								      *
 *									      *
 * Access to FLEXROM info						      *
 *									      *
 ******************************************************************************/

typedef struct _flexrom {	/* Flexxed ROM information */
	WORD src;		/* Source segment */
	WORD dst;		/* Destination segment */
	WORD len;		/* Length in bytes */
	WORD flag;		/* Flag word */
	WORD vxd;		/* Vxd something */
} FLEXROM;

int pascal far get_flexroms(FLEXROM far *stuff);

