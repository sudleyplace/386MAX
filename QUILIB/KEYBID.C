/*' $Header:   P:/PVCS/MAX/QUILIB/KEYBID.C_V   1.0   05 Sep 1995 17:02:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * KEYBID.C								      *
 *									      *
 * Identify keyboard BIOS and keyboard type				      *
 *									      *
 ******************************************************************************/

/* System includes */
#include <string.h>

/* Local includes */
#include "commfunc.h"

#define KBBHEAD 0x1A	/* Offset of kb buffer head in BIOS data */
#define KBBTAIL 0x1C	/* Offset of kb buffer tail in BIOS data */
#define KBBUF	0x1E	/* Offset of kb buffer in BIOS data area */
#define KBEFLAG 0x96	/* Offset to flags byte for enh kb */
#define KBBSIZE (1+1+16)*sizeof(WORD) /* Bytes in kb buffer + head/tail */

#pragma optimize ("leg",off)

int keyboard_id(void)	/* Test for ext bios + enh keyboard */
/* Return:  bit 0 == 1 for ext kb bios, bit 1 == 1 for enh keyboard */
{
	int rtn;
	char far *biosdata;
	char save[KBBSIZE];

	/* Point at BIOS data area */
	biosdata = FAR_PTR(0x40,0);

	/* No ints please */
	_asm	cli

	/* Save off the current kb buffer */
	_fmemcpy(save,biosdata+KBBHEAD,KBBSIZE);

	/* Force the buffer empty */
	*(WORD far *)(biosdata+KBBHEAD) = *(WORD far *)(biosdata+KBBTAIL);

	/* Use extended bios to stuff a keystroke */
	rtn = 0;
	_asm {
		mov ax,05ffh	; Function code
		mov cx,0ffffh	; Stuff this
		int 16h 	; Do it
		jc  oops	; ..if error
		or  al,al	; Did it work?
		jc  oops	; No...

		cli		; Just in case...
		mov ax,1000h	; Try reading the keystroke back
		int 16h 	; Do it
		cmp ax,0ffffh	; Did it?
		jnz oops	; If not
		mov rtn,1	; Set flag if it did
	oops:
		sti		; Ints back on
	}
	if (rtn) {
		/* Extended kb bios available, test the enh kb flag */
		if ((*(biosdata+KBEFLAG) & 0x10)) {
			/* It's on */
			rtn |= 2;
		}
	}

	/* Put back the kb buffer */
	_fmemcpy(biosdata+KBBHEAD,save,KBBSIZE);

	return rtn;

}
