/*' $Header:   P:/PVCS/MAX/ASQENG/PROFILE.H_V   1.0   05 Sep 1995 15:05:54   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PROFILE.H								      *
 *									      *
 * Read and process ASQ profile file					      *
 *									      *
 ******************************************************************************/

void read_profile(		/* Read and process ASQ profile */
	BOOL def,		/* TRUE to read from default profile */
	BOOL getdata,		/* TRUE to read and process data;
				   otherwise, keywords only */
	char *fname);		/* Basename/extension of file */
