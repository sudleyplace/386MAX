/*' $Header:   P:/PVCS/MAX/QUILIB/KEYBOARD.C_V   1.0   05 Sep 1995 17:02:14   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * KEYBOARD.C								      *
 *									      *
 * Keyboard support functions						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>	/* for printf() */
#include <stdlib.h>	/* for getenv() */

#ifdef OS2_VERSION
#include "km_os2.h"
#endif /*OS2_VERSION*/

#include "commdef.h"    /* Common Definitions */
#include "commfunc.h"   /* Common Functions */
#include "keyboard.h"   /* Keyboard support functions */

#ifndef OS2_VERSION
static unsigned ExtKbd = 0;	/* Flag for extended keyboard functions */
static KEYFLAG LocalFlags = 0;	/* Local flags word for use with int 9 */

static int test_kb_type(void);	/* Test for ext bios + enh keyboard */
/* Special functions to hook int 9 on pre-extended keyboards */

void pascal far set_hook9(void);
void pascal far clr_hook9(void);
int pascal far get_code9(void);
static EXTKEY process_code9(void);
#endif

#pragma optimize ("leg",off)
void init_keyboard(KEYPARM *parm)
{
	int flags = 0;
#ifdef OS2_VERSION
	kbtstart();
	flags = 3;	/* I'm lying, but who cares? */
#else
	ExtKbd = 0;
	flags = 0;
#ifdef CVDBG
	if (!getenv("KEYFUDGE"))
#endif
	{
		flags = keyboard_id();

		if ((flags & 3) == 3) ExtKbd = 0x1000;
	}
	if (!ExtKbd) {
		set_hook9();
#ifdef CVDBG
		flags |= 4;
#endif
	}

	/* Purge the keystroke buffer */
	_asm {
	L0:
		mov ax,0x100	/* Get keyboard status */
		or  ax,ExtKbd
		int 0x16
		jz L1		/* Jump if no char */

		mov ax,ExtKbd
		int 0x16	/* Read from keyboard and discard */
		jmp L0
	L1:
	}

#endif
	if (parm) parm->flags = flags;
}
#pragma optimize ("",on)

void end_keyboard(void)
{
#ifndef OS2_VERSION
	if (!ExtKbd) clr_hook9();
#endif
}

KEYCODE get_key(int nowait)	/* Test / wait for one key */
{
	KEYCODE key;

	key = KEYCODE_OF(get_extkey(nowait));
	if (!ExtKbd && (key & 0xff) == 0xE0) key &= 0xff00;
	if (key & 0xff) key &= 0x00ff;
	return key;
}

#pragma optimize ("leg",off)
EXTKEY	get_extkey(int nowait)	/* Test / wait for raw keystroke + flags */
{
	EXTKEY rtn = 0;
#ifdef OS2_VERSION
	/* OS2 version */
	if (nowait) kbtwait();
	do {
		rtn = kbtinp();
	} while(!rtn && !nowait);
#else
	/* DOS version */
	/* In theory, this will be the only place we will be checking for
	 * ctrl-c for ctrl-break
	 */
	disable29();
	_asm {
		mov ah,0bh
		int 21h
	}
	enable29();
	do {
		_asm {
			mov ax,0x100	/* Get keyboard status */
			or  ax,ExtKbd
			int 0x16
			mov ax,0	/* Prep for neg return */
			jz L1		/* Jump if no char */

			mov ax,ExtKbd
			int 0x16	/* Read from keyboard */
			mov word ptr rtn,ax
		L1:
			mov ax,0x200	/* Get keyboard flags */
			or  ax,ExtKbd
			int 0x16
			cmp ExtKbd,0
			jnz L3
			mov ah,0	/* No ext keyboard, no ext flags */
		L3:
			mov word ptr rtn+2,ax /* And store in upper half of return */
		}
		if (KEYCODE_OF(rtn)) break;

		if (!ExtKbd) {
			rtn = process_code9();
			if (KEYCODE_OF(rtn)) break;
		}
	} while(!nowait);
#endif /*OS2_VERSION*/
	return rtn;
}
#pragma optimize ("",on)

#ifndef OS2_VERSION
static EXTKEY process_code9(void)
{
	KEYCODE key = 0;

	for (;;) {
		int code9;

		code9 = get_code9();
		if (code9 < 0) break;
#if 0
		printf("[%02X]",code9);
#endif
		switch (code9) {
		case 0x2A: /* Left Shift down */
			LocalFlags |= KEYFLAG_LSHFT;
			break;
		case 0xAA: /* Left Shift up */
			LocalFlags &= ~KEYFLAG_LSHFT;
			break;
		case 0x36: /* Right Shift down */
			LocalFlags |= KEYFLAG_RSHFT;
			break;
		case 0xB6: /* Right Shift up */
			LocalFlags &= ~KEYFLAG_RSHFT;
			break;
		case 0x1D: /* Ctrl down */
			LocalFlags |= KEYFLAG_XCTRL;
			break;
		case 0x9D: /* Ctrl up */
			LocalFlags &= ~KEYFLAG_XCTRL;
			break;
		case 0x38: /* Alt down */
			LocalFlags |= KEYFLAG_XALT;
			break;
		case 0xB8: /* Alt up */
			LocalFlags &= ~KEYFLAG_XALT;
			break;
		case 0x46: /* Scroll Lock down */
			LocalFlags |= KEYFLAG_SCROL;
			break;
		case 0xC6: /* Scroll Lock up */
			LocalFlags &= ~KEYFLAG_SCROL;
			break;
		case 0x45: /* Num Lock down */
			LocalFlags |= KEYFLAG_NUM;
			break;
		case 0xC5: /* Num Lock up */
			LocalFlags &= ~KEYFLAG_NUM;
			break;
		case 0x3A: /* Caps Lock down */
			LocalFlags |= KEYFLAG_CAPS;
			break;
		case 0xBA: /* Caps Lock up */
			LocalFlags &= ~KEYFLAG_CAPS;
			break;

		case 0x48: /* Up key down */
			if (LocalFlags & KEYFLAG_XCTRL) key = KEY_CUP;
			break;
		case 0x50: /* Down key down */
			if (LocalFlags & KEYFLAG_XCTRL) key = KEY_CDOWN;
			break;
#if 0	/* Doctor it hurts when I do this... */
		case 0x49: /* PgUp key down */
			if (LocalFlags & KEYFLAG_XALT) key = KEY_APGUP;
			break;
		case 0x51: /* PgDn key down */
			if (LocalFlags & KEYFLAG_XALT) key = KEY_APGDN;
			break;
#endif
		case 0x0E: /* Backspace key down */
			if (LocalFlags & KEYFLAG_XALT) key = KEY_ALTBKSP;
			break;
		case 0x52: /* Ins key down */
			if (LocalFlags & KEYFLAG_XCTRL) key = KEY_CINS;
			break;
		case 0x53: /* Del key down */
			if (LocalFlags & KEYFLAG_XCTRL) key = KEY_CDEL;
			break;
		} /* switch */
		if (key) break;
	}
	return EXTKEY_OF(key,LocalFlags);
}
#endif

KEYCODE translate_altKey( KEYCODE key ) 	/* Take chorded alt char and return real character */
{

static KEYCODE original[] = {
KEY_ALTA, KEY_ALTB, KEY_ALTC, KEY_ALTD, KEY_ALTE,
KEY_ALTF, KEY_ALTG, KEY_ALTH, KEY_ALTI, KEY_ALTJ,
KEY_ALTK, KEY_ALTL, KEY_ALTM, KEY_ALTN, KEY_ALTO,
KEY_ALTP, KEY_ALTQ, KEY_ALTR, KEY_ALTS, KEY_ALTT,
KEY_ALTU, KEY_ALTV, KEY_ALTW, KEY_ALTX, KEY_ALTY,
KEY_ALTZ
};

static char newkey[] = {
'A', 'B', 'C', 'D', 'E',
'F', 'G', 'H', 'I', 'J',
'K', 'L', 'M', 'N', 'O',
'P', 'Q', 'R', 'S', 'T',
'U', 'V', 'W', 'X', 'Y',
'Z'
};

	register int counter;
	for( counter = 0; counter < sizeof( original ) / sizeof (KEYCODE ); counter++ )
		if( original[counter] == key )
			return newkey[counter];
	return 0;
}
