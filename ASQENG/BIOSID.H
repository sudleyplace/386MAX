/*' $Header:   P:/PVCS/MAX/ASQENG/BIOSID.H_V   1.1   01 Feb 1996 10:22:04   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BIOSID.H								      *
 *									      *
 * Function to collect BIOS id codes and date				      *
 *									      *
 ******************************************************************************/

/**** WARNING ****/
/* Do NOT change these fields without making corresponding */
/* changes in the MASM declaration in BIOSID.ASM */

typedef struct _biosid {	/* BIOS Identification params */
	BYTE model;		/* Model code */
	BYTE submodel;		/* Submodel code */
	BYTE revision;		/* Revision number */
	BYTE flags;		/* Configuration flags */
	BYTE bus_flag;		/* 1 if (!) true IBM system | 2 if EISA bus */
				/* 	| 4 if PCI */
	BYTE ncrc;		/* (!) Kb in BIOS crc: 64 or 128 */
	WORD crc;		/* (!) CRC of BIOS */
	WORD sys_id;		/* System board ID for MCA's */
	WORD xbseg;		/* XBIOS segment, if any */
	WORD xbsize;		/* XBIOS size in KB */
	char date[10];		/* Rev date from BIOS ROM */
	char far *i15_ptr;	/* Pointer to int 15 param block */
} BIOSID;

/* (!):  These fields USED to be set by bios_id, and now are set by other
 *	 code.	*/

void far pascal bios_id(BIOSID far *parms);
/* Mon Nov 26 17:05:57 1990 :  renamed from bios_id.h */
