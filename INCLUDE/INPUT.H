/*' $Header:   P:/PVCS/MAX/INCLUDE/INPUT.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INPUT.H								      *
 *									      *
 * Input event functions						      *
 *									      *
 ******************************************************************************/

#ifndef INPUT_INCLUDED
#define INPUT_INCLUDED

#include <commdef.h>
#include <keyboard.h>
#include <mouse.h>

typedef struct _inputparm {	/* Input config parameters */
	int flags;		/* 0=std kb/func, 1=ext func, 2=ext kb, 3=both */
	int buttons;		/* Number of mouse buttons, 0 if no mouse */
} INPUTPARM;

typedef struct _inputevent {	/* One input event */
	KEYCODE key;		/* Keystroke if non-zero */
	KEYFLAG flag;		/* Shift flags for keystroke */
	MOUCLICK click; 	/* Mouse click/drag event if non-zero */
	int x;			/* Mouse X-coordinate */
	int y;			/* Mouse Y-coordinate */
	int b;			/* Mouse button flags */
} INPUTEVENT;

#define INPUT_WAIT 0x7fffffffL	/* Makes get_input wait a long time */

void init_input(		/* Initialize input functions */
	INPUTPARM *parm);	/* Parameters returned here if not NULL */

void end_input(void);		/* De-Initialize input functions */

int get_input(			/* Test for / get one input event */
	long waitms,		/* Millisec to wait for an event */
	INPUTEVENT *event);	/* Event structure filled in */
/* Return:  non-zero if something happened */

void visible_mouse (int onoff); /* 0=normal mouse (cursor visible only */
				/* when getting input), 1=always visible */

#endif /*INPUT_INCLUDED*/
