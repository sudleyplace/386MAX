/*' $Header:   P:/PVCS/MAX/INCLUDE/QWINDOWS.H_V   1.1   01 Feb 1996 10:23:34   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * QWINDOWS.H								      *
 *									      *
 * Window support functions						      *
 *									      *
 ******************************************************************************/

#ifndef WINSUPP_INCLUDED
#define WINSUPP_INCLUDED

#ifndef COMMDEF_INCLUDED
#include <commdef.h>
#endif

#ifndef INPUT_INCLUDED
#include <input.h>
#endif

#ifndef VIDEO_INCLUDED
#include <video.h>
#endif

#ifndef KEYBOARD_INCLUDED
#include <keyboard.h>
#endif

#include <windowfn.h>                   /* Window primitives */

/* Defines and typedefs */

typedef struct {
	char ch;			/*	Character at this position */
	char attr;			/*	Attribute for this position */
} CELL;
typedef CELL			*PCELL; 	/*	How to point at a CELL */
typedef CELL NEAR		*NPCELL;
typedef CELL FAR		*LPCELL;

typedef struct {
	int row;			/*	Where Top to bottom this point is */
	int col;			/*	Where left to right this point is */
} POINT;

typedef POINT			*PPOINT;		/*	How to point at a point */
typedef POINT NEAR	    *NPPOINT;
typedef POINT FAR		*LPPOINT;

typedef struct _textwin {	/*	Text window descriptor */
	WINDESC win;	/*	Visible window description */
	POINT size;	/*	How manu rows and columns are there */
	unsigned numChar;	/*	How many total characters are there ( INT_MAX ) */
	POINT corner;	/*	What row/col is the upper left visible position */
	POINT cursor;	/*	Where the cursor is -  Virtual screen relative */
	POINT display;	/*	Display location of cursor */
	CURSOR cShape;	/*	What shape is the current cursor */
	char attr;		/*	Default attribute for screen color */
	int cursorVisible;	/*	Is the cursor visible */
	int shadowed;	/*	Should this be shown with a shadow */
	int delayed;	/*	Should we postpone writes to this window? */
	WINDESC hScroll;/*	Window info for horizontal scroll bar - row = -1 for none*/
	WINDESC vScroll;/*	Window info for vertical scroll bar - row = -1 for none */
	void * behind;	/*	Image of what was behind this window when displayed */
	CELL * data;	/*	Actual data for this window */
} TEXTWIN;

typedef TEXTWIN 		*PTEXTWIN;		/*	How to point at a TEXTWIN */
typedef TEXTWIN NEAR	*NPTEXTWIN;
typedef TEXTWIN FAR		*LPTEXTWIN;


typedef enum { BOX_NONE, BOX_SINGLE=1, BOX_DOUBLE } BOXTYPE;
typedef enum { JUSTIFY_LEFT, JUSTIFY_CENTER, JUSTIFY_RIGHT } JUSTIFY;
typedef enum { SHADOW_NONE, SHADOW_DOUBLE, SHADOW_SINGLE } SHADOWTYPE;

typedef int (*VWINCALLBACK)(	  /*  TextWin callback function */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	INPUTEVENT *event		/*	What event to process - Could be null */
);

/*	From winsvrs.c */
void *win_save( 			/*	Save a block of video memory */
	WINDESC *win,			/*	Definition of what to save	*/
	int shadowed ); 		/*	Should we save the shadow area too */

void *win_restore(			/*	Restore a block of video memory */
	 void *buffer,			/*	what to restore */
	 int release ); 		/*	Should the buffer be released */

void box (					/*	Draw a box around the outside edge */
	WINDESC *win,			/*	Definition of what to draw in */
	BOXTYPE boxType,		/*	Type of lines */
	char *title,			/*	Title for box or NULL */
	char *bottomTitle,		/*	Title for the bottom of the box or NULL */
	char attr );			/*	Attribute to use */

void justifyString(			/*	Show a justified string in a single line window */
	WINDESC *win,			/*	Where to draw the string */
	char *string,			/*	What to draw */
	int triggerPos, 		/*	Trigger position - -1 for none */
	JUSTIFY justify,		/*	How to justify the string */
	char attr,				/*	Regular attribute color */
	char tAttr );			/*	Trigger color */

/*	From wraptstr.c */
void wrapString(		/*	Word wrap a string into a window */
	WINDESC *win,		/*	Window to write into */
	char *text,		/*	String to write into - No tabs bells lf cr */
	char *attr);		/*	Video attributes */

int wrapStrlen( 		/*	Calculate length of wraped string */
	char *text,		/*	String to write into - No tabs bells lf cr */
	int ncols);		/*	How many columns in window */
	/* Return:  number of rows */

/*	From textwin.c */
#define WIN_OK				0			/*	Function worked - Success */
#define WIN_NOROOM			1			/*	No room in WIN structure */
#define WIN_NOMEMORY		2			/*	Out of memory - Alloc failed */
#define WIN_NOTFOUND		3			/*	Target request not found ( Help ) */
#define WIN_WEIRD			4			/*	Other wierd error */
#define WIN_NOOP			5			/*	Actions that a window can do - return */
#define WIN_ABANDON			6			/*	User hit escape */
#define WIN_BUTTON			7			/*	User hit a button */
#define WIN_MOVETO			8			/*	Move to a specific line */
#define WIN_UP				KEY_UP
#define WIN_DOWN			KEY_DOWN
#define WIN_RIGHT			KEY_RIGHT
#define WIN_LEFT			KEY_LEFT
#define WIN_TOP 			KEY_CHOME
#define WIN_BOTTOM			KEY_CEND
#define WIN_PGUP			KEY_PGUP
#define WIN_PGDN			KEY_PGDN
#define WIN_PGLEFT			KEY_CPGUP
#define WIN_PGRIGHT		KEY_CPGDN
#define WIN_HOME			KEY_HOME
#define WIN_END 			KEY_END
#define WIN_TAB 			KEY_TAB
#define WIN_STAB			KEY_STAB
#define WIN_ENTER			KEY_ENTER
#define WIN_APGUP			KEY_APGUP
#define WIN_APGDN			KEY_APGDN

typedef unsigned int WINRETURN;

typedef enum {
	BORDER_NONE,				/*	No border around a window */
	BORDER_SINGLE=BOX_SINGLE,	/*	Single border around the window */
	BORDER_DOUBLE=BOX_DOUBLE,	/*	Double border around the window */
	BORDER_BLANK				/*	Invisible border */
} BORDERTYPE;

WINRETURN vWin_create(		/*	Create a text window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window descriptor */
	int nrows,				/*	How many rows in the window */
	int ncols,				/*	How wide is the window */
	char attr,				/*	Default attribute for a window */
	SHADOWTYPE shadow,			/*	Should this have a shadow */
	BORDERTYPE border,		/*	What type of border does this get */
	int vScrollBar, 		/*	Is there a vertical scroll bar */
	int hScrollBar, 		/*	How about horizontal scroll bar */
	int remember,			/*	Should we remember what was below */
	int delayed			/*	Should output to the screen be delayed */
	);

WINRETURN vWin_destroy( 	/*	Delete a text window */
	PTEXTWIN pText			/*	Pointer to text window */
	);

WINRETURN resizeVWin(		/*	Resize a window vertically ONLY */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int nrows				/*	How many rows to allow now */
	);

WINRETURN vWin_setDelay(
	PTEXTWIN pText, 		/*	Pointer to text window */
	int delayed			/*	Is this window to be delayed */
	);

WINRETURN vWin_forceCurrent(	/*	Force the screen to reflect the definition */
	PTEXTWIN pText);			/*	Pointer to text window */

WINRETURN vWinPut_c(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text );			/*	What text to write with default attr */

WINRETURN vWinPut_ca(		/*	Write a text string with attributes into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text );			/*	What text to write with attrs */

WINRETURN vWinPut_sa(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char attr );			/*	What attribute to write */

WINRETURN vWinPut_sca(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text,			/*	What text to write with default attr */
	char attr);				/*	Attribute to use */

WINRETURN vWin_put_c(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char ch );				/*	What text to write with default attr */

WINRETURN vWin_put_a(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char attr );			/*	What attribute to use */

WINRETURN vWin_put_s(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char *text );			/*	What text to write with default attr */

WINRETURN vWin_put_sca( 	/*	Write a text string into the window with a different color attribute*/
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char *text,				/*	What text to write with default attr */
	char attr );			/*	What attribute to use */

WINRETURN vWin_insertChar(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char ch );				/*	What text to write with default attr */

WINRETURN vWin_deleteChar(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col);				/*	Column to start in */

WINRETURN vWin_show(	/*	Dump the video buffer to screen */
	PTEXTWIN pText, 	/*	Text window to show in */
	WINDESC *win ); 		/*	Subset to show */

WINRETURN vWin_ask(		/*	Let a user run around a window */
	PTEXTWIN pText, 		/*	Text window to run around in */
	VWINCALLBACK callBack	/*	Function to preprocess keys with */
	);

WINRETURN testScroll(		/*	Translate a mouse action into a window movement */
	WINDESC *win,			/* Window that will get the action */
	INPUTEVENT *event,		/*	What mouse event occured */
	int max,				/*	Max number of items */
	int *current ); 		/*	Where we are right now - or should be */

WINRETURN vWin_key(	/*	Take a key and return an appropriate action */
	PTEXTWIN pText, 	/*	Window to consider */
	KEYCODE key );		/*	Actual key pressed */

WINRETURN vWin_mouse(		/*	Translate a mouse action into a window movement */
	PTEXTWIN pText, 		/* Window that will get the action */
	INPUTEVENT *event );	/*	What mouse event occured */

/*	Cursor definitions from textcur.c */
CURSOR vWin_get_cursor( 	/*	Return the current cursor shape for this window */
	PTEXTWIN pText );		/*	Window to deal with */

CURSOR vWin_set_cursor( 	/*	Return the current cursor shape for this window */
	PTEXTWIN pText, 		/*	Window to deal with */
	CURSOR cShape );		/*	Shape to use for cursor now */

void  vWin_updateCursor(	/*	Set the visible flag */
	PTEXTWIN pText );		/*	Window to deal with */

void  vWin_show_cursor( 	/*	Set the visible flag */
	PTEXTWIN pText );		/*	Window to deal with */

void  vWin_hide_cursor( 	/*	Set the visible flag */
	PTEXTWIN pText );		/*	Window to deal with */

#endif /*WINSUPP_INCLUDED*/
