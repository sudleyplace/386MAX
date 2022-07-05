/*' $Header:   P:/PVCS/MAX/INCLUDE/FLDEDIT.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * FLDEDIT.H								      *
 *									      *
 * This file contains all definitions that are related to FLDEDITs	      *
 *									      *
 ******************************************************************************/

#ifndef FLDEDIT_INCLUDED
#define FLDEDIT_INCLUDED

#ifndef WINSUPP_INCLUDED
#include <qwindows.h>
#endif

#ifndef INPUT_INCLUDED
#include <input.h>
#endif

#ifndef SCREEN_INCLUDED
#include <screen.h>
#endif

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

typedef struct {
	WINDESC win;		/*	Area to show text in - Can be smaller than*/
						/*	Adjusted by show win to leave leading space */
	POINT start;		/*	Where the visible part starts */
	POINT cursor;		/*	Where this thing lives relative to window */
	POINT anchor;		/*	Where the last mouse/cusor slide started */
	enum { FLD_INSERT, FLD_OVERWRITE }cSize;	/*	What mode are we in */
	KEYCODE trigger;	/*	Value that activates this item */
	char attr;			/*	Character to use for painting */
	int maxLen;		/*	Length of this item */
	char *text;		/*	What text to show */
	void *behind;		/*	What was behind this window */
} FLDITEM;

typedef FLDITEM 		*PFLDITEM;		/*	How to point at a FLDITEM */
typedef FLDITEM NEAR	*NPFLDITEM;
typedef FLDITEM FAR		*LPFLDITEM;

typedef enum {
	FLD_OK, 			/*	Field Edit returns OK */
	FLD_NOOP,			/*	Has no purpose to talk to this field */
	FLD_NOROOM,		/*	No memory to allocate */
	FLD_FOCUS,			/*	This edit window wants the focus */
	FLD_WIERD			/*	Some other thing went wrong */
}	FLDRETURN;

FLDRETURN showFldEdit(		/*	Put edit field up on screen */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create			   */
	WINDESC *win,			/*	Window definition to use						   */
	KEYCODE trigger,		/*	What key activates this  edit window */
	char *text,			/*	Scratch buffer to fill in - Must be maxlen long    */
	int maxLen,			/*	Maximium number of chars to support			   */
	char attr,				/*	Attribute to use for field edit window */
	int shadow,			/*	Should this box be shadowed					   */
	int remember ); 		/*	Remember what we stepped on when we painted the box*/

FLDRETURN killFldEdit(		/*	Wipe a field edit off the screen */
	PFLDITEM pItem );		/*	Pointer to the edit window to create  */

void hideFldText(			/*	Hide the text of a fld edit window */
	PFLDITEM pItem );

void showFldText(			/*	Show the text for this item */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create  */
	int hiLite,			/*	Show this item bright or dim */
	int block );			/*	Show the select block */

FLDRETURN sendFldEditKey(		/*	Wipe a field edit off the screen */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create  */
	KEYCODE key,			/*	Input event to deal with */
	KEYFLAG flag ); 		/*	State of the keyboard at keypress */

FLDRETURN sendFldEditClick(		/*	Wipe a field edit off the screen */
	PFLDITEM pItem, 			/*	Pointer to the edit window to create  */
	INPUTEVENT *event);			/*	Input event to deal with */

#endif /*  FLDEDIT_INCLUDED	*/
