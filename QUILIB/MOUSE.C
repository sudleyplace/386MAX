/*' $Header:   P:/PVCS/MAX/QUILIB/MOUSE.C_V   1.0   05 Sep 1995 17:02:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MOUSE.C								      *
 *									      *
 * Mouse support functions						      *
 *									      *
 ******************************************************************************/

#ifdef OS2_VERSION
#define INCL_MOU
#include <os2.h>
#include "km_os2.h"
#endif

#include "mouse.h"

static int MouseAvail = 0;	/* Mouse-is-available flag */

#pragma optimize ("leg",off)
void init_mouse(MOUSEPARM *parm) /* Init / get mouse parameters */
{
	int avail;
	int buttons;

#ifdef OS2_VERSION
	avail = moustart(); /* Assume not available */
	avail = -1;
#else	/* DOS_VERSION */
	_asm {
		mov ax,0	/* Reset and get info */
		int 0x33
		mov avail,ax	/* Save available flag */
		mov buttons,bx	/* Save button count */
	}
#endif /* OS2_VERSION */
	MouseAvail = avail;
	if (parm) {
		parm->avail = avail;
		parm->buttons = buttons;
	}
}

void show_mouse(void)		/* Show mouse pointer */
{
	if (!MouseAvail) return;
#ifdef OS2_VERSION
#if 0
	MouDrawPtr(mouhandle());
#endif
#else	/* DOS_VERSION */
	_asm {
		mov ax,1	/* Show mouse pointer */
		int 0x33
	}
#endif /* OS2_VERSION */
}

void hide_mouse(void)		/* Hide mouse pointer */
{
	if (!MouseAvail) return;
#ifdef OS2_VERSION
	{
		NOPTRRECT xrect;

		xrect.row = 0;
		xrect.col = 0;
		xrect.cRow = 480;	/* lower-right x-coordinate */
		xrect.cCol = 640;	/* lower-right y-coordinate */
#if 0
		MouRemovePtr(&xrect, mouhandle());
#endif
	}
#else	/* DOS_VERSION */
	_asm {
		mov ax,2	/* Hide mouse pointer */
		int 0x33
	}
#endif /* OS2_VERSION */
}

int get_mouse(			/* Poll for mouse event */
	int *x, 		/* Current x-coordinate returned */
	int *y, 		/* Current y-coordinate returned */
	int *b) 		/* Current button state returned */
	/* Return:  non-zero if event occurred */
{
	int rtn;
	int xcur;
	int ycur;
	int button;

	xcur = ycur = button = 0;
#ifdef OS2_VERSION
	if (!MouseAvail) return 0;
	rtn = mousein(&xcur,&ycur,&button,NULL);
#else	/* DOS_VERSION */
	if (MouseAvail) _asm {
		mov ax,3	/* Get mouse position and button status */
		/*mov ax,5*/	/* Get button press information */
		int 0x33
		mov button,bx	/* Save button status */
		mov xcur,cx	/* Save x-coordinate */
		mov ycur,dx	/* Save y-coordinate */
	}
	xcur /= 8;
	ycur /= 8;
	rtn = 1;
#endif /* OS2_VERSION */
	if (x) *x = xcur;
	if (y) *y = ycur;
	if (b) *b = button;
	return rtn;
}

void set_mouse_pos(	/*	Set the mouse cursor here. */
	int x,				/*	What column */
	int y ) 			/*	What row */
{
	x *= 8;
	y *= 8;

	if (MouseAvail) _asm {
		mov ax, 4			/*	Set mouse position */
		mov cx, x			/*	Column position */
		mov dx, y			/*	what row */
		int 0x33
	}
}

#pragma optimize ("",on)
