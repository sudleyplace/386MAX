/*' $Header:   P:/PVCS/MAX/INCLUDE/DIALOG.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * DIALOG.H								      *
 *									      *
 * This file contains all function definitions				      *
 *									      *
 ******************************************************************************/

#ifndef DIALOG_INCLUDED
#define DIALOG_INCLUDED

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

#ifndef QHELP_INCLUDED
#include <qhelp.h>
#endif

#ifndef WINSUPP_INCLUDED
#include <qwindows.h>
#endif

#ifndef BUTTON_INCLUDED
#include <button.h>
#endif

typedef struct _dialogtext {	/*	Dialog-from-help-text index */
	int ncmp;		/*	How many chars to compare */
	char *what;		/*	If the context string starts with this... */
	HELPTYPE where; 	/*	... then look in this help file */
	int width;		/*	Width of dialog box if non-zero */
} DIALOGTEXT;

typedef struct _dialogparm {	/*	Dialog control parameters */
	int width;		/*	Outer width of dialog box */
	char *attr;		/*	Pointer to video attributes */
	PBUTTON pButton;	/*	Button list - Routine sets positions */
	int nButtons;		/*	How many */
	char editAttr;		/*	Color for edit field(s) */
	int editShadow; 	/*	Shadow control for edit field(s) */
	DIALOGTEXT *hindex;	/*	Pointer to dialog help text index */
} DIALOGPARM;

typedef struct _dialogedit {	/*	Dialog edit field(s) */
	WINDESC editWin;	/*	Edit window, rel to dialog */
	char *editText; 	/*	Where to get/put editable string */
	int editLen;		/*	Length of edit field - Don't forget the null terminator */
} DIALOGEDIT;

void set_tabconvert (int newval); /*	If !0, convert ENTER on all but the */
				/*	last field of multiple edits to TAB */
				/*	and start edits on field newval-1. */

KEYCODE dialog(
	DIALOGPARM *parm,	/*	Control parameters */
	char *title,		/*	Title for the dialog box - I will pad with 1 space each side */
	char *message,		/*	Message to display at top inside of dialog box */
	int helpnum,		/*	Help number if non-zero */
	DIALOGEDIT *edit,	/*	Pointer to edit fields */
	int nEdit);		/*	How many edit fields */

void dialog_callback(		/* Install a dialog callback function */
	KEYCODE key,		/* Call function when this key happens */
	int (*func)(void));	/* Function to call */

void dialog_shift(		/* Set dialog shift factor */
	int rowshift,		/* Row shift */
	int colshift);		/* Column shift */

KEYCODE dialog_input(
	int helpnum,		/*	Help number if non-zero */
	KEYCODE (*infunc)(INPUTEVENT *)); /* Input event callback if not NULL */

WORD set_dlgflags (		/* Sets dialog flags and returns previous */
	WORD newval);

#define DLGF_NOFILL	0x0001	/* No auto-advance when field is full */
#define DLGF_EDITHIGH	0x0002	/* Set initial cursor and anchor */

void set_edithigh (		/* Set initial cursor and anchor for */
	int start,		/* first field to receive edit focus */
	int len);

#endif /*DIALOG_INCLUDED*/
