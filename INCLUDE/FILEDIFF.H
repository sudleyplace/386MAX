/*' $Header:   P:/PVCS/MAX/INCLUDE/FILEDIFF.H_V   1.0   05 Sep 1995 13:30:04   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * FILEDIFF.H								      *
 *									      *
 * Prototypes for filediff module					      *
 *									      *
 ******************************************************************************/

/***
 * Write differences between file1 and file2 to file3.
 * Lines after 768 are ignored; allocates and releases ~20K
***/
int file_diff (char *file1,char *file2,char *file3);

/***
 * Hash a string
***/
long hashstr (unsigned char *s);
