/*' $Header:   P:/PVCS/MAX/QUILIB/MBOOTSEL.C_V   1.2   30 May 1997 12:09:02   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1992-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MBOOTSEL.C								      *
 *									      *
 * Multiboot selection functions					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <help.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "editwin.h"
#include "fldedit.h"
#include "libcolor.h"
#include "mbparse.h"
#include "myalloc.h"
#include "ui.h"
#include "windowfn.h"

#define LIBTEXT_MBOOTSEL
#include "libtext.h"

extern HELPDEF HelpInfo [1];

char MbootText[81];
int (*MBSCallback) (BYTE, char *) = NULL;

WINRETURN vMBMenu_ask(	/* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event);  /* Text window to run around in */

int   inMBMenuWin(
PTEXTWIN pText,
INPUTEVENT *event);

WINRETURN vMBMenu_key(	/*	Take a key and return an appropriate action */
KEYCODE key );		/*	Actual key pressed */


#define WIDTH 66

/* Interface to set and clear the external callback function */
/* Used by Maximize to ensure we don't select a MB section that */
/* doesn't already have MAX in it. */
void set_mbs_callback (int (*callback) (BYTE, char *))
{
  MBSCallback = callback;
}


/**
*
* Name		vWinPut_a - Write an attribute to the screen
*
* Synopsis	WINRETURN vWinPut_a(PTEXTWIN pText,
*	    int row1, int col1,
*	    int row2, col2, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row1,					Row to start text on
*	int col1,					col to start on
*	int row2,					Row to end text on
*	int col2,					col to end on
*	char *text );				What text to _write with default attr
*
* Description	This function lives in EDITWIN.C.  If we need both
*		modules, it'll have to be moved out to its own file.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN MBvWinPut_a(		/*	Write an attribute into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
int   row1,	     /* starting row */
int   col1,	     /* starting column */
int   row2,	     /* ending row */
int   col2,	     /* ending column */
int   attr )			/*	What attribute */
{
	PCELL startPos, thisCell;
	int   count;

	startPos = pText->data + (row1 * pText->size.col + col1);
	thisCell = startPos;

	count =  (row2 * pText->size.col + col2) -
	    (row1 * pText->size.col + col1);

	while (count > 0) {
		thisCell++->attr = ( char )attr;
		count--;
	}

	/*
	do {
	thisCell++->attr = ( char )attr;
	count--;
	} while (count >= 0);
	*/

	return(0);
}

#define vWinPut_a	MBvWinPut_a

/**
*
* Name		mboot_select
*
* Synopsis	WINRETURN vWin_ask(PTEXTWIN pText )
*
*
* Parameters
*	char	*helptext	Name of quick help text to load (H.MBMenu)
*				(strcat(helptext,"2") is the second block
*				 to display, as in H.MBMenu2)
*	int	helpnum 	Index of help context for F1 indepth help
*
* Description
*	Assumes menu_parse() has already been called.  Allows the user
*	to select the MultiBoot section to work with.
*
* Returns	pointer to selected MultiBoot section, or NULL if none
*
* Version	1.0
*/

extern WORD pascal POVR_MAC;

#pragma optimize ("leg",off)
char  _far *mboot_select(	/* Let the user choose a multiboot section */
	char	_far *helptext, /* Help text to load on screen */
	int	helpnum 	/* Help index for F1 */
)
{
	TEXTWIN pOption, pDescript, pDescript2;
	INPUTEVENT event;
	WINRETURN action, askReturn;
	void *behind = NULL;
	WINDESC LclWin = {4,	/* row */
			  2,	/* col */
			  16,	/* nrows */
			  74};	/* ncols */
	int   row = 0;
	int   *replace = &row;
	int   tutor = 0;
	int   helpType = HelpInfo[helpnum].type;

	char  far *current;
	SECTNAME far *tmpsect;
	int cursectnum;
	int MenuWindow = 0, DescWindow = 0, DescWindow2 = 0;

	int i, display, oldButtons;
	int winError;

	WINDESC workWin, OptWin, DescWin;
	char helptext2[20];
	BYTE Owner;
	UCHAR OldColor;

	*replace = 0;
	sprintf (helptext2, "%s2", helptext);

	/* Get the currently active menu item */
	MbootText[0] = '\0';
	current = CurrentMboot (POVR_MAC); /* Get current CONFIG= setting */

	/* The list of menu items should already have been parsed.  If */
	/* there are no menu items, return immediately. */
	if (!MenuCount) goto MBS_EXIT;

	if (current) _fstrcpy (MbootText, current);
	display = i = 0;

	/*	Draw up the dialog box */
	/*	Set up where we are putting this */
	show_cursor();
	push_cursor();

	SETWINDOW( &workWin,
	LclWin.row - 2,
	LclWin.col-1,
	LclWin.nrows+4,
	LclWin.ncols+2);

	/*	Remember what we are stomping on */
	behind = win_save( &workWin, TRUE );
	if( !behind ) {
		errorMessage(WIN_NOROOM);
		goto lastOut;
	}

	/*	Put up the window */
	wput_sca( &workWin, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &workWin );
	box( &workWin, BOX_DOUBLE, MBMenuTitle, MBMenuBottomTitle, BaseColor );


	addButton( MBMenuButtons, NUMMBMENUBUTTONS, &oldButtons );
	disableButton( KEY_ENTER, FALSE );
	/* allowEnter = 0; */
	disableButton( KEY_F1, FALSE);
	disableButton( KEY_F2, TRUE);
	disableButton( KEY_ESCAPE, FALSE);
	showAllButtons();


	/* Spray quick help info into top of window */
	/* THIS IS HARD-CODED FOR A MAXIMUM OF 3 ROWS */
	SETWINDOW( &DescWin,
		LclWin.row,
		LclWin.col + 1,
		3,
		LclWin.ncols - 3);

	/* This is a MAJOR kludge... */
	OldColor = HelpColors[0];
	HelpColors[0] = HelpColor;
	winError = loadHelp (
		&pDescript,
		&DescWin,
		&helpType,
		HelpNc (helptext, HelpTitles[0].context),
		HelpColor,
		SHADOW_NONE,
		BORDER_NONE,
		FALSE,FALSE,		/* Scroll bars */
		FALSE); 		/* Don't remember what's below */
	HelpColors[0] = OldColor;

	if (winError == WIN_OK) {
		DescWindow = 1;
	}
	else {
		errorMessage (WIN_NOMEMORY);	/* Insufficient memory */
		goto done2;
	}

	{
		int   i;

		SETWINDOW( &OptWin,
		LclWin.row + 3 + 1,
		LclWin.col + 1,
		min (LclWin.nrows - 6 - 3, MenuCount),
		LclWin.ncols - 4);

		winError = vWin_create( /*	Create a text window */
		&pOption,		/*	Pointer to text window */
		&OptWin,		/*	Window descriptor */
		MenuCount,		/*	How many rows in the window*/
		OptWin.ncols,		/*	How wide is the window */
		OptionTextColor,	/*	Default Attribute */
		SHADOW_SINGLE,		/*	Should this have a shadow */
		BORDER_NONE,		/*	Single line border */
		TRUE, FALSE,		/*	Scroll bars */
		TRUE,			/*	Remember what was below */
		FALSE );		/*	Is this window delayed */

		if( winError == WIN_OK ) {
			WINDESC tempWin;
			SETWINDOW( &tempWin, 0, 0, 1, OptWin.ncols - 1 );

			MenuWindow = 1;
			/* Fill the narrow scroll box with active options */
			for (		cursectnum = 1,
						i = 0, tmpsect = FirstSect;
					tmpsect && i < MenuCount;
					i++, tmpsect = tmpsect->next) {
				char tempstr[80];
				/* Match the current selection name */
				/* with a SECTNAME record */
				if (!_fstricmp (tmpsect->name, current)) {
				  cursectnum = i + 1;	/* Default selection */
				  _fstrcpy (MbootText, tmpsect->name);
				} /* section name matches */
				tempWin.col = 0;
				if (tmpsect->text) {
				  tempWin.ncols = _fstrlen(tmpsect->text);
				  _fstrcpy (tempstr, tmpsect->text);
				  vWinPut_c( &pOption, &tempWin, tempstr);
				  sprintf (tempstr, " [%-10s]", tmpsect->name);
				  tempWin.ncols = strlen(tempstr);
				  tempWin.col = OptWin.ncols - tempWin.ncols - 2;
				} /* Description specified */
				else {
				  tempWin.ncols = _fstrlen (tmpsect->name);
				  _fstrcpy (tempstr, tmpsect->name);
				} /* No description; use name */
				vWinPut_c( &pOption, &tempWin, tempstr);
				tempWin.row++;
			} /* for all menu items */

			/* If there is no active section, use the first one */
			pOption.cursor.row = cursectnum ? cursectnum - 1 : 0;
			if (cursectnum > pOption.win.nrows) {
				/* We can always bottom justify the current */
				/* selection.  If it's not the last, we'll */
				/* try to center it vertically. */
				pOption.corner.row = cursectnum -
					pOption.win.nrows +
					min (MenuCount-cursectnum,
						pOption.win.nrows/2);
			} /* Default selection is beyond scope of window */
			vWin_show_cursor(&pOption);

			if( pOption.vScroll.row > 0 )
				paintScrollBar( &pOption.vScroll, pOption.attr,
				pOption.size.row - pOption.win.nrows, pOption.corner.row );
		}
		else {
			errorMessage( WIN_NOMEMORY	);	/* Insufficient Memory */
			goto done2;
		}

	}

	action = 0;

	/* Spray second block of help info into bottom of window */
	/* THIS BLOCK IS HARD-CODED FOR 2 LINES MAXIMUM. */
	SETWINDOW( &DescWin,
	OptWin.row + OptWin.nrows + 1,
	LclWin.col + 1,
	2,
	LclWin.ncols - 3);

	/* This is a MAJOR kludge... */
	OldColor = HelpColors[0];
	HelpColors[0] = HelpColor;
	winError = loadHelp (
		&pDescript2,
		&DescWin,
		&helpType,
		HelpNc (helptext2, HelpTitles[0].context),
		HelpColor,
		SHADOW_NONE,
		BORDER_NONE,
		FALSE,FALSE,		/* Scroll bars */
		FALSE); 		/* Don't remember what's below */
	HelpColors[0] = OldColor;

	if (winError == WIN_OK) {
		DescWindow2 = 1;
	}
	else {
		errorMessage (WIN_NOMEMORY);	/* Insufficient memory */
		goto done2;
	}

	event.key = KEY_LEFT;
	display = vMBMenu_ask(&pOption, &event);


	for (;;) {
		display = 1;

		if (pOption.cursor.row != cursectnum) {
		  cursectnum = pOption.cursor.row;
		  /* Copy the nth line from the menu list */
		  for ( i=0, tmpsect = FirstSect;
			tmpsect && i < MenuCount;
			i++, tmpsect = tmpsect->next) {
		    if (i == cursectnum) {
			_fstrcpy (MbootText, tmpsect->name);
			Owner = tmpsect->OwnerID;
		    } /* Found current section */
		  } /* Walk through section names */
		} /* Current line changed */

		/* first we get input,
		then we check for button click
		then we focus
		then we send key to the proper handler routine
		*/
		vWin_show_cursor(&pOption);

		get_input(INPUT_WAIT, &event);

		action = testButtonClick( &event, FALSE ) ? WIN_BUTTON : WIN_NOOP;

		if (action == WIN_BUTTON) {
			pushButton( LastButton.number );
			switch( LastButton.key ) {
			case KEY_ENTER:
				goto done;
			case KEY_F1:
				if (testButton(KEY_F1, TRUE)) {
					showHelp( helpnum, FALSE );
				}
				continue;
			case KEY_ESCAPE:
				chkabort();
				continue;
			}
		}

		/* figure out alt keys */
		switch (event.key) {
		case KEY_F1:
			if (testButton(KEY_F1, TRUE)) {
				showHelp( helpnum, FALSE );
			}
			continue;
		case KEY_ESCAPE:
			chkabort();
			continue;
		}

		/* figure out mouse click */
		if( event.click != MOU_NOCLICK) {
			int	act1;
			act1 = inMBMenuWin(&pOption, &event);
			if (act1) {
				if (event.click == MOU_LSINGLE ||
				    event.click == MOU_LDOUBLE ||
				    event.click == MOU_LDRAG) {

					if (act1 == 1) {
						vWinPut_a(&pOption, pOption.cursor.row, 0, pOption.cursor.row, pOption.win.ncols, pOption.attr);

						pOption.cursor.row = pOption.corner.row + (event.y - pOption.win.row);
						pOption.cursor.col = pOption.corner.col + (event.x - pOption.win.col);
						pOption.cursor.col = 0;

						vWinPut_a(&pOption, pOption.cursor.row, 0, pOption.cursor.row, pOption.win.ncols, OptionHighColor);
					}
				}
				goto process;
			}
		}


		switch(toupper (event.key)) {
		case RESP_OK:
		case KEY_ENTER:
			testButton( event.key, TRUE );
			goto done;
		case KEY_ESCAPE:
			chkabort();
			continue;
		}
		goto process;

process:
		askReturn = 0;
		askReturn = vMBMenu_ask(&pOption, &event);

		if (askReturn == WIN_BUTTON) break;
		else continue;
done:
		if (MBSCallback && !(*MBSCallback) (Owner, MbootText)) continue;
		else break;
	}

done2:
	dropButton(MBMenuButtons, NUMMBMENUBUTTONS);

	if (DescWindow2) vWin_destroy(&pDescript2);
	if (DescWindow) vWin_destroy(&pDescript);
	if (MenuWindow) vWin_destroy(&pOption);


lastOut:

	if (behind) win_restore( behind, TRUE);

	pop_cursor();

MBS_EXIT:
	if (MbootText[0] && !set_current (MbootText))	return (MbootText);
	else						return (NULL);

} /* mboot_select () */
#pragma optimize ("",on)


int   inMBMenuWin(
PTEXTWIN pText,
INPUTEVENT *event)
{
	if(event->x < pText->win.col ||
	    event->y < pText->win.row ||
	    event->x > pText->win.col + pText->win.ncols    || /* was -1 */
	event->y > pText->win.row + pText->win.nrows -1) {
		return(0);
	}
	/* are we on the scroll bar?? */
	if(event->x == pText->win.col + pText->win.ncols ) return(2);
	return(1);

} /* inMBMenuWin () */

/**
*
* Name		vMBMenu_ask - Keyboard interface for a window
*
* Synopsis	WINRETURN vOpt_ask(PTEXTWIN pText )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Accept mouse and keyboard events and move the window around
*	as required.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vMBMenu_ask(	/* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event)   /* Text window to run around in */
{
	WINRETURN action;
	WINRETURN retVal = WIN_OK;
	POINT oldCorner;

	/*	Force the window to be current if delayed */
	if( pText->delayed ) {
		WINDESC temp;
		SETWINDOW( &temp, 0, 0, pText->win.nrows, pText->win.ncols );
		pText->delayed = FALSE;
		vWin_show( pText, &temp );
	}

	/*	Put up scroll bars */
	if( pText->vScroll.row > 0 && pText->size.row > pText->win.nrows)
		paintScrollBar( &pText->vScroll, pText->attr,
		pText->size.row - pText->win.nrows, pText->corner.row );
	if( pText->hScroll.row > 0 )
		paintScrollBar( &pText->hScroll, pText->attr,
		pText->size.col - pText->win.ncols, pText->corner.col );

	/*	Force the cursor invisible */
	/*
	pText->cursorVisible = FALSE;
	vWin_updateCursor( pText );
	*/

	oldCorner = pText->corner;
	/*
	get_input(INPUT_WAIT, &event);
	*/
	if( event->key ) {
		action = vMBMenu_key( event->key );
	}
	else {
		action = vWin_mouse( pText, event );
	}

	vWinPut_a(pText, pText->cursor.row, 0, pText->cursor.row, pText->win.ncols, pText->attr);

	switch( action ) {
	case WIN_NOOP:
		goto dumpScreen;

	case WIN_MOVETO:
		pText->cursor.row = pText->corner.row;
		goto dumpScreen;
	case WIN_UP:
		if (pText->cursor.row) {
			pText->cursor.row--;
		}
		if (pText->corner.row > pText->cursor.row) {
			pText->corner.row--;
		}
		goto dumpScreen;
	case WIN_DOWN:
		if (pText->cursor.row - pText->corner.row < pText->win.nrows - 1) {
			if (pText->cursor.row < pText->size.row - 1) pText->cursor.row++;
		}
		else {
			if (pText->size.row - 1 - pText->win.nrows < pText->corner.row) goto dumpScreen;
			if (pText->cursor.row < pText->size.row) {
				pText->corner.row++;
				pText->cursor.row++;
			}
		}
		goto dumpScreen;
	case WIN_TOP:
		pText->corner.row = 0;
		pText->cursor.row = 0;
		goto dumpScreen;
	case WIN_BOTTOM:
		pText->corner.row = pText->size.row - pText->win.nrows;
		pText->cursor.row = pText->size.row - 1;
		goto dumpScreen;
	case WIN_PGUP:
		pText->corner.row -= pText->win.nrows;
		pText->cursor.row -= pText->win.nrows;
		if( pText->corner.row < 0 ) {
			pText->corner.row = 0;
			pText->cursor.row = 0;
		}
		goto dumpScreen;
	case WIN_PGDN:
		{
			WINDESC workWin;
			pText->corner.row += pText->win.nrows;
			pText->cursor.row += pText->win.nrows;
			if (pText->cursor.row >= pText->size.row)
				pText->cursor.row = pText->size.row - 1;
			pText->corner.row =
			    min( pText->corner.row, pText->size.row - pText->win.nrows );

	case WIN_LEFT:
dumpScreen:
			SETWINDOW( &workWin, pText->corner.row, pText->corner.col,
			pText->win.nrows, pText->win.ncols );

			vWinPut_a(pText, pText->cursor.row, 0, pText->cursor.row, pText->win.ncols, OptionHighColor);
			vWin_show( pText, &workWin );
			if( (pText->vScroll.row > 0) && oldCorner.row != pText->corner.row
			    && pText->size.row > pText->win.nrows)
				paintScrollBar( &pText->vScroll, pText->attr,
				pText->size.row - pText->win.nrows, pText->corner.row );
			if( (pText->hScroll.row > 0) && oldCorner.col != pText->corner.col )
				paintScrollBar( &pText->hScroll, pText->attr,
				pText->size.col - pText->win.ncols, pText->corner.col );


			break;
		}
	default:
		;
	}

	return action;

} /* vMBMenu_ask () */

/**
*
* Name		vMBMenu_key - Analyze keycode and return action ( if any )
*
* Synopsis	WINRETURN vOpt_key(PTEXTWIN pText, KEYCODE key	)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	KEYCODE key;				What key to analyze
*
* Description
*		Return a menu action based on a key action.  If the action is
*	out of range - return NOOP;
*
* Returns	WIN code for the correct action
*
* Version	1.0
*/
WINRETURN vMBMenu_key(	/*	Take a key and return an appropriate action */
KEYCODE key )		/*	Actual key pressed */
{
	switch ( key ) {
	case KEY_HOME:
		return WIN_TOP;
	case KEY_UP:
		return WIN_UP;
	case KEY_PGUP:
		return WIN_PGUP;
	case KEY_LEFT:
		return WIN_LEFT;
	case KEY_RIGHT:
		return WIN_RIGHT;
	case KEY_PGDN:
		return WIN_PGDN;
	case KEY_END:
		return WIN_BOTTOM;
	case KEY_DOWN:
		return WIN_DOWN;
	}
	return WIN_NOOP;

} /* vMBMenu_key () */

