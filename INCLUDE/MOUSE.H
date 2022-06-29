/*' $Header:   P:/PVCS/MAX/INCLUDE/MOUSE.H_V   1.0   05 Sep 1995 13:29:50   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MOUSE.H								      *
 *									      *
 * Mouse support functions						      *
 *									      *
 ******************************************************************************/

#ifndef MOUSE_INCLUDED
#define MOUSE_INCLUDED

/* Defines */
#define MOU_LEFT	0x01	/* Mask for left mouse button */
#define MOU_RIGHT	0x02	/* Mask for right mouse button */
#define MOU_CENTER	0x04	/* Mask for center mouse button */

/* Structures and Enumerated types */

typedef struct _mouseparm {	/* Mouse parameter block */
	int avail;		/* -1 if mouse available, 0 if not */
	int buttons;		/* Number of mouse buttons */
} MOUSEPARM;

typedef enum _mouclick {	/* Our definition of mouse click events */
	MOU_NOCLICK,		/* Nothing happened */
	MOU_LSINGLE,		/* Left button, single click */
	MOU_LSINGLEUP,		/* Left Button up stroke */
	MOU_LDOUBLE,		/* Left button, double click */
	MOU_RSINGLE,		/* Right button, single click */
	MOU_RSINGLEUP,		/* Right button up stroke */
	MOU_RDOUBLE,		/* Right button, double click */
	MOU_CSINGLE,		/* Center button, single click */
	MOU_CSINGLEUP,		/* Center button up stroke */
	MOU_CDOUBLE,		/* Center button, double click */
	MOU_LDRAG,		/* Drag with left button */
	MOU_RDRAG,		/* Drag with right button */
	MOU_CDRAG		/* Drag with center button */
} MOUCLICK;

/* Functions */
void init_mouse(MOUSEPARM *parm); /* Init / get mouse parameters */

void show_mouse(void);		/* Show mouse pointer */

void hide_mouse(void);		/* Hide mouse pointer */

int get_mouse(			/* Poll for mouse event */
	int *x, 		/* Current x-coordinate returned */
	int *y, 		/* Current y-coordinate returned */
	int *b);		/* Current button state returned */
	/* Return:  non-zero if event occurred */

void set_mouse_pos(	/*	Set the mouse cursor here. */
	int x,				/*	What column */
	int y );			/*	What row */

#endif /*MOUSE_INCLUDED*/
