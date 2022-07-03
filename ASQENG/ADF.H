/*' $Header:   P:/PVCS/MAX/ASQENG/ADF.H_V   1.1   01 Feb 1996 10:22:02   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ADF.H								      *
 *									      *
 * Function for reading adapter description files			      *
 *									      *
 ******************************************************************************/

#ifndef ADF_INCLUDED
#define ADF_INCLUDED

#include <commdef.h>            /* Common definitions */
#include <mca_pos.h>            /* Define MCAID */

#include "sysbuf.h"             /* System info buffer */

typedef struct _adfinfo {	/* PS/2 Adapter info */
	WORD aid;		/* Adapter id */
	char name[50];		/* Adapter name */
	WORD noption;		/* Number of options */
	SYSBUFH foption;	/* (ADFOPTION) Handle of first option */
	SYSBUFH loption;	/* (ADFOPTION) Handle of last option */
} ADFINFO;

typedef struct _adfoption {	/* Adapter option */
	SYSBUFH next;		/* (ADFOPTION) Handle of next option */
	char name[50];		/* Name of option */
	WORD nchoice;		/* Number of choices */
	SYSBUFH fchoice;	/* (ADFCHOICE) Handle of first choice */
	SYSBUFH lchoice;	/* (ADFCHOICE) Handle of last choice */
} ADFOPTION;

typedef struct _adfchoice {	/* Option choice */
	SYSBUFH next;		/* (ADFCHOICE) Handle of next choice */
	char name[50];		/* Name of choice */
	char pos[4][10];	/* POS flags */
} ADFCHOICE;

int adf_setup(void);

int adf_read(
	char *name,		/* Name of file if not NULL */
	MCAID *pMCAid,		/* Board info if no name given */
	SYSBUFH *infh); 	/* Handle to ADFINFO struct returned here */

#endif /*ADF_INCLUDED*/

/* Wed Mar 13 21:03:39 1991 alan:  fix bugs */
