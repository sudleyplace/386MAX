/*' $Header:   P:/PVCS/MAX/QUILIB/KM_OS2.H_V   1.0   05 Sep 1995 17:03:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * KM_OS2.C								      *
 *									      *
 * Keyboard and mouse support for OS/2					      *
 *									      *
 ******************************************************************************/

#ifndef KM_OS2_INCLUDED
#define KM_OS2_INCLUDED

unsigned long cdecl kbtinp(void);
void cdecl kbtflush(void);
int cdecl kbtstat(void);
int kbtstart(void);
void kbtwait(void);
void kbthold(int flag);
int mousein(int *x,int *y,int *b,long *t);
int moustart(void);
unsigned short mouhandle(void);
void mouhold(int flag);

#endif /*KM_OS2_INCLUDED*/
