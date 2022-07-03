/*' $Header:   P:/PVCS/MAX/INCLUDE/SAVEADF.H_V   1.1   02 Jun 1997 14:37:32   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SAVEADF.H								      *
 *									      *
 * Functions to save (copy) .ADF files					      *
 *									      *
 ******************************************************************************/


#ifndef SAVEADF_INCLUDED
#define SAVEADF_INCLUDED

#include <mca_pos.h>
#include <bioscrc.h>

typedef struct _adfsig {	/* ADF signature information */
	WORD version;		/* Version number */
	WORD cmos_valid:1,	/* Is cpos[] valid? */
	     reserved:15;	/* Fill out to word boundary */
	MCAID apos[MCASLOTS];	/* Adapter (& system board) POS info */
	CMOSPOS cpos[MCASLOTS]; /* CMOS POS info */
} ADFSIG;

/* Length to compare w/CMOS valid */
#define ADFSIG_CLEN	sizeof(ADFSIG)
/* Length to compare with CMOS invalid */
#define ADFSIG_XCLEN	(sizeof(ADFSIG)-(sizeof(CMOSPOS)*MCASLOTS))

BOOL check_adf_files(		/* Check for valid .ADF files */
	char *path,		/* ADF path filled in */
	int npath);		/* Max chars in path */

BOOL save_adf_files(		/* Copy .ADF files */
	char *src,		/* Source path, usually "A:" */
	char *dst);		/* Destination path, usually "C:\386MAX\ADF" */

char *adf_dir(			/* Get/set ADF directory path */
	char *path);		/* Path to use or NULL */

#endif /*SAVEADF_INCLUDED*/
