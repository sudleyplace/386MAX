/*' $Header:   P:/PVCS/MAX/INCLUDE/EXTSIZE.H_V   1.0   05 Sep 1995 13:30:02   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * EXTSIZE.H								      *
 *									      *
 * Prototypes for EXTSIZE.ASM						      *
 *									      *
 ******************************************************************************/

unsigned extsize (void);	// Size of extended memory in KB as returned
				// by int 15 fn 88
unsigned extcmos (void);	// Size of extended memory in KB as gotten
				// from CMOS
unsigned xmsmax (void); 	// Size of largest available EMB

