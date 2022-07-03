/*' $Header:   P:/PVCS/MAX/INCLUDE/TESTHEAP.H_V   1.0   05 Sep 1995 13:29:54   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * TESTHEAP.H								      *
 *									      *
 * Heap debug functions 						      *
 *									      *
 ******************************************************************************/

void testheap(void );
void heapdump(void);
void _fdspmem(char * text, int addr, void far * vbuf, int n);
