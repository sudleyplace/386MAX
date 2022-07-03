/*' $Header:   P:/PVCS/MAX/QUILIB/INPUT.C_V   1.0   05 Sep 1995 17:02:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INPUT.C								      *
 *									      *
 * Input event functions						      *
 *									      *
 ******************************************************************************/

/* System includes */
#include <stdlib.h>
#include <time.h>

/* Local includes */
#include "input.h"
#include "libtext.h"

static int     Buttons	= 0;	/* Last mouse button flags */
static int     LastX	= 0;	/* Last mouse x-coordinate */
static int     LastY	= 0;	/* Last mouse y-coordinate */
static clock_t Lclock	= 0;	/* Left button clock value */
static clock_t Rclock	= 0;	/* Right button clock value */
static clock_t Cclock	= 0;	/* Center button clock value */
static clock_t Interval = 300;	/* Double click test interval */
static int     MouseVisible = 0; /* Set by visible_mouse () */

static struct _kludgekeys {	/* Keys that need to be kludged up when shifted */
	KEYCODE was;		/* The character was this... */
	KEYCODE willbe; 	/* ...and will be this. */
} KludgeKeys[] = {
	0x532E,  KEY_DEL,	/* . */
	0x5230,  KEY_INS,	/* 0 */
	0x4F31,  KEY_END,	/* 1 */
	0x5032,  KEY_DOWN,	/* 2 */
	0x5133,  KEY_PGDN,	/* 3 */
	0x4B34,  KEY_LEFT,	/* 4 */
	0x4D36,  KEY_RIGHT,	/* 6 */
	0x4737,  KEY_HOME,	/* 7 */
	0x4838,  KEY_UP,	/* 8 */
	0x4939,  KEY_PGUP,	/* 9 */
	0,0
};

static int input_mouse( /* Get input from mouse */
	INPUTEVENT *event);	/* Pointer to event struct */
	/* Return:  non-zero if event occurred */

static int input_key(		/* Get input from keyboard */
	INPUTEVENT *event);	/* Pointer to event struct */
	/* Return:  non-zero if event occurred */

void init_input(		/* Initialize input functions */
	INPUTPARM *parm)	/* Parameters returned here if not NULL */
{
	MOUSEPARM mparm;
	KEYPARM kparm;

	init_mouse(&mparm);
	init_keyboard(&kparm);
	if (parm) {
		parm->flags = kparm.flags;
		parm->buttons = mparm.buttons;
	}
}

void end_input(void)		/* De-Initialize input functions */
{
	end_keyboard();
}

int get_input(			/* Test for / get one input event */
	long waitms,		/* Millisec to wait for an event */
	INPUTEVENT *event)	/* Event structure filled in */
/* Return:  non-zero if something happened */
{
	int result;
	clock_t then;
	clock_t now;
	long elapsed;

	/* Init the struct */
	event->click = MOU_NOCLICK;
	event->key = 0;
	if (!MouseVisible) show_mouse();
	then = clock();
	do {
		result = input_mouse(event);
		if (result) break;
		result = input_key(event);
		if (result) break;
		now = clock();
		elapsed = now - then;
		if (TimeoutInput && elapsed > TimeoutDelay) {
		  event->key = TimeoutKey;	/* Key to return */
		  event->flag = 0;		/* No shift states */
		  result = 1;			/* Something happened */
		  break;
		} /* Forced timeout occurred */
	} while(elapsed < waitms);
	if (!MouseVisible) hide_mouse();
	return result;
}

void visible_mouse (int onoff)
/* Interface to MouseVisible */
{
  MouseVisible = onoff;
  if (MouseVisible) show_mouse();
  else hide_mouse();
} /* visible_mouse () */

static int input_mouse( /* Get input from mouse */
	INPUTEVENT *event)	/* Pointer to event struct */
	/* Return:  non-zero if event occurred */
{
	int rtn;
	int dif;
	clock_t now;

	if (!get_mouse(&event->x,&event->y,&event->b)) return 0;

	dif = event->b ^ Buttons;
	if (dif) {
		/* Button state changed, let's see what */
		if (dif & MOU_LEFT) {
			if (event->b & MOU_LEFT) {
				/* Left button down */
				now = clock();
				if ((now - Lclock) < Interval) {
					event->click = MOU_LDOUBLE;
					Lclock = 0;
				}
				else {
					event->click = MOU_LSINGLE;
					Lclock = now;
				}
			}
			else {
				/* Left button up */
				event->click = MOU_LSINGLEUP;
			}
		}
		if (dif & MOU_RIGHT) {
			if (event->b & MOU_RIGHT) {
				/* Right button down */
				now = clock();
				if ((now - Rclock) < Interval) {
					event->click = MOU_RDOUBLE;
					Rclock = 0;
				}
				else {
					event->click = MOU_RSINGLE;
					Rclock = now;
				}
			}
			else {
				/* Right button up */
				event->click = MOU_RSINGLEUP;
			}
		}
		if (dif & MOU_CENTER) {
			if (event->b & MOU_CENTER) {
				/* Center button down */
				now = clock();
				if ((now - Cclock) < Interval) {
					event->click = MOU_CDOUBLE;
					Cclock = 0;
				}
				else {
					event->click = MOU_CSINGLE;
					Cclock = now;
				}
			}
			else {
				/* Center button up */
				event->click = MOU_CSINGLEUP;
			}
		}
		/* New state becomes old state */
		Buttons = event->b;
		LastX = event->x;
		LastY = event->y;
		rtn = event->click ? 1 : 0;
	}
	else if ((event->b & (MOU_LEFT | MOU_RIGHT | MOU_CENTER)) &&
		 (event->x != LastX || event->y != LastY)) {
		/* Motion with button down */
		if (event->b & MOU_LEFT) {
			event->click = MOU_LDRAG;
		}
		if (event->b & MOU_RIGHT) {
			event->click = MOU_RDRAG;
		}
		if (event->b & MOU_CENTER) {
			event->click = MOU_CDRAG;
		}
		LastX = event->x;
		LastY = event->y;
		rtn = 1;
	}
	else	rtn = 0;
	return rtn;
}

static int input_key(		/* Get input from keyboard */
	INPUTEVENT *event)	/* Pointer to event struct */
	/* Return:  non-zero if event occurred */
{
	EXTKEY xkey;
	KEYCODE ykey;
	KEYCODE key;
	KEYFLAG flag;
	static int altstate = 0;
	static int waskey = 0;

	xkey = get_extkey(1);
	ykey = key = KEYCODE_OF(xkey);

	if ((key & 0xff) == 0xE0) key &= 0xff00;
	if (key & 0xff) key &= 0x00ff;

	flag = KEYFLAG_OF(xkey);
	if (!key) {
		if (!altstate) {
			/* Alt key went down? */
			if (flag & KEYFLAG_XALT) {
				altstate = 1;
				waskey = 0;
			}
		}
		else {
			if (!(flag & KEYFLAG_XALT)) {
				altstate = 0;
				if (!waskey) {
					event->key = KEY_ALTUP;
					event->flag = flag;
					return 1;
				}
			}
		}
		return 0;
	}
	else {
		int kk;
		if ((flag & (KEYFLAG_LSHFT | KEYFLAG_RSHFT)) && NORMALKEY(key)) {
			for (kk=0; KludgeKeys[kk].was; kk++) {
				if (KludgeKeys[kk].was == ykey) {
					key = KludgeKeys[kk].willbe;
					break;
				}
			}
		}
		event->key = key;
		event->flag = flag;
		waskey = 1;
		return 1;
	}
}
