/*' $Header:   P:/PVCS/MAX/ASQENG/QTAS.H_V   1.1   01 Feb 1996 10:32:42   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * QTAS.H								      *
 *									      *
 * Access to Qualitas code						      *
 *									      *
 ******************************************************************************/

#ifndef QTAS_INCLUDED
#define QTAS_INCLUDED

#include <commdef.h>            /* Common definitions */

void qtas_init(void);

int pascal far qtas_mac(
	WORD first_mac, 	/* Segment of first MAC entry */
	WORD first_lseg,	/* Segment of first LSEG if nonzero */
	struct _macinfo far *buf, /* Buffer to fill */
	int nbuf);		/* Max items in buffer */

#endif	/* QTAS_INCLUDED */
