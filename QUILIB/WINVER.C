/*' $Header:   P:/PVCS/MAX/QUILIB/WINVER.C_V   1.0   05 Sep 1995 17:02:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * WINVER.C								      *
 *									      *
 * Utility function to get Windows version if Windows is running	      *
 *									      *
 ******************************************************************************/

#include "commfunc.h"

#pragma optimize ("leg",off)    /* Inline assembler precludes... */
WORD win_version(void)
{
	WORD winver = 0;

	_asm {
		mov ax,1600h
		int 2Fh 	/* DOS Multiplex interrupt */
		mov dx,0	/* Assume no windows */
		cmp al,0
		jz  DONE	/* Windows not running */
		test al,7fh
		jz  DONE	/* Windows not running */

		mov dx,200h	/* Assume Windows 2.x (ha ha) */
		cmp al,-1
		jz  DONE	/* Windows 2.x running */
		cmp al,1h
		jz  DONE	/* Windows 2.x running */

		xchg ah,al
		mov dx,ax
		cmp ah,3
		jge DONE	/* Windows 3.x+ running */
	DONE:
		mov winver,dx
	}
	return winver;
}
