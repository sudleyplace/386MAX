/*' $Header:   P:/PVCS/MAX/QUILIB/DIALOG.C_V   1.0   05 Sep 1995 17:02:04   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DIALOG.C								      *
 *									      *
 * Functions to manage dialog windows					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <string.h>

/*	Program Includes */
#include "fldedit.h"
#include "input.h"
#include "keyboard.h"
#include "dialog.h"
#include "ui.h"
#include "qhelp.h"
#include "video.h"
#include "myalloc.h"

/*	Definitions for this Module */
#define MAXEDITWIDTH 81

static KEYCODE CallBackKey = 0;
static int (*CallBackFunc)(void) = NULL;
static int RowShift;
static int ColShift;
static int ConvertTab = 0; // If ENTER pressed on any but the last of
			// multiple edits, treat it as a TAB...
			// This is also the index (base:1) of the
			// field to start with (normally 1).
static WORD DlgFlags = 0; // Defined in DIALOG.H
static int EditHStart, EditHLen; // Valid if DlgFlags&DLGF_EDITHIGH

/* Interface to ConvertTab */
void set_tabconvert (int newval)
{	ConvertTab = newval;	}

/* Interface to DlgFlags; returns previous setting */
WORD set_dlgflags (WORD newval)
{
  WORD prev;

  prev = DlgFlags;
  DlgFlags = newval;

  return (prev);

} // set_dlgflags ()

/* Interface to set initial edit field highlighting */
void set_edithigh (int start, int len)
{

  EditHStart = start;
  EditHLen   = len;
  DlgFlags  |= DLGF_EDITHIGH;

} // set_edithigh ()

/*	Program Code */
/**
*
* Name		dialog - Put up a totally radical dialog box - Hand built
*
* Synopsis	int dialog( char *title, char *message, int width, PBUTTON pButton,
						int nButtons, char *attr, char *editBox, int editLen )
*
* Parameters
*	See function header below.
*
* Description
*		Carefully plan and build a dialog box based on all the parameters
*	that are here.
*
* Returns	key code pressed to respond to the message
*			The edit text is ONLY changed if the key code is not an escape
*
* Version	2.00
*
**/
#pragma optimize("leg",off)
KEYCODE dialog(
	DIALOGPARM *parm,	/*	Control parameters */
	char *title,		/*	Title for the dialog box - I will pad with 1 space each side */
	char *message,		/*	Message to display at top inside of dialog box */
	int helpnum,		/*	Help number if non-zero */
	DIALOGEDIT *edit,	/*	Pointer to edit fields */
	int nEdit)		/*	How many edit fields */
{
	FLDITEM editName[6];
#define MAXNEDIT	(sizeof(editName)/sizeof(FLDITEM))
	HELPTEXT htext;
	INPUTEVENT event;
	int ii;
	int iCols;
	int iRows;
	BOOL in_edit;
	void *behind;
	WINDESC win;
	HELPTYPE ihelp;
	KEYCODE result = 0;
	BUTTON *ourButton;

	/* Keep idiots out of trouble */
	if (!edit) nEdit = 0;
	if (!parm || nEdit < 1) edit = NULL;
	if (nEdit > MAXNEDIT) nEdit = MAXNEDIT;
top:
	push_cursor();
	hide_cursor();

	ihelp = 0;
	iRows = 0;
	iCols = parm->width;
	if (parm->hindex && strlen(message) < 32) {
		/* Text comes from help file */
		int kk;
		DIALOGTEXT *pp;

		pp = parm->hindex;
		for (kk = 0; pp->what; kk++,pp++) {
			if (memcmp(message,pp->what,pp->ncmp) == 0) {
				ihelp = pp->where;
				if (pp->width) iCols = pp->width;
				break;
			}
		}
		if (ihelp) {
			iRows = loadText(&htext,ihelp,message);
			if (iRows < 0) {
				/* Oops.  text not found */
				ihelp = 0;
			}
			else iRows++; /* Makes things come out right */
		}
	}
	if (!ihelp) {
		/* Text comes from caller */
		iRows = wrapStrlen(message,iCols - 4);
	}
	iRows += 1+2+1; /* 1 top + 2 button + 1 bottom */

	SETWINDOW( &win,
		(ScreenSize.row - iRows)/2,
		(ScreenSize.col - iCols)/2,
		iRows,
		iCols );
	win.row += RowShift;
	win.row = max(win.row,0);
	win.col += ColShift;
	win.col = max(win.col,0);

	/*	Save what's behind us */
	behind = win_save( &win, TRUE );

   /* if we DON'T have enough room, release the reserve */
   if (!behind) {
      if (globalReserve) {
	 my_free(globalReserve);
	 globalReserve = NULL;
	 behind = win_save( &win, TRUE );
      }
   }

	/*	Specify the color to put it in */
	wput_sca( &win, VIDWORD( *parm->attr, ' ' ));
	shadowWindow( &win );

	/*	Build up the title */
	box( &win, BOX_DOUBLE, title, NULL, *parm->attr );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 4;

	if (ihelp) {
		showText(&htext,&win,parm->attr,NULL);
	}
	else {
		wrapString( &win, message, parm->attr );
	}

	for (ii = 0; ii < nEdit; ii++) {
		WINDESC workWin;

		workWin = edit[ii].editWin;
		workWin.row += win.row - 1;
		if (edit[ii].editWin.row < 0) {
			workWin.row += win.nrows+2;
		}
		if (edit[ii].editWin.col < 0) {
			workWin.col += win.ncols+4;
		}

		workWin.col += win.col - 2;
		workWin.nrows = 1;
		/*workWin.ncols = min(workWin.ncols,edit[ii].editLen);*/

		showFldEdit(		/*	Put edit field up on screen */
			&editName[ii],		/*	Pointer to the edit window to create			   */
			&workWin,		/*	Window definition to use						   */
			0,				/*	What key activates this  edit window */
			edit[ii].editText,	/*	Edit buffer to modify - Must be maxlen long	  */
			edit[ii].editLen,	/*	Maximium number of chars to support			   */
			parm->editAttr, 	/*	Attribute to use for field edit window */
			parm->editShadow,	/*	Should this box be shadowed					   */
			FALSE );		/*	Remember what we stepped on when we painted the box*/

	}

	/*
	 *  Make a local copy of the button definitions.  We have to do this
	 *  because adjustButtons will modify them, and they may be shared
	 *  with other code (like askMessage) that may get called via
	 *  chkabort.
	 */

	ourButton = my_malloc(parm->nButtons * sizeof(BUTTON));
	if (!ourButton) {
		/* if we DON'T have enough room, release the reserve */
		if (globalReserve) {
			my_free(globalReserve);
			globalReserve = NULL;
			ourButton = my_malloc(parm->nButtons * sizeof(BUTTON));
		}
	}
	if (ourButton) {
		memcpy(ourButton,parm->pButton,parm->nButtons * sizeof(BUTTON));
	}
	else {
		/* A failure here isn't worth aborting the program */
		ourButton = parm->pButton;
	}

	adjustButtons( ourButton, parm->nButtons, &win, win.nrows - 2 );
	addButton( ourButton, parm->nButtons, NULL );
	disableButton(KEY_F1,helpnum ? FALSE : TRUE);

	setButtonData((nEdit > 0 && parm->nButtons > 1) ? FALSE : TRUE);
	showAllButtons();

	if (edit) {
		ii= (ConvertTab && ConvertTab <= nEdit) ? ConvertTab-1 : 0;

		if (DlgFlags & DLGF_EDITHIGH) {

		  DlgFlags &= (~DLGF_EDITHIGH); // Turn it off
		  editName[ii].cursor.col = EditHStart;
		  editName[ii].anchor.col = EditHStart + EditHLen;

		} // Set edit highlight

		sendFldEditKey( &editName[ii], KEY_TAB,0 );
		in_edit = TRUE;
	}
	else {
		move_cursor(ScreenSize.row,0);
		in_edit = FALSE;
	}
	for(;;) {
		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			if (in_edit) {
				// Major kludge so users can press ENTER after entering name
				if (event.key == KEY_TAB ||
					(ConvertTab && event.key == KEY_ENTER &&
							ii != nEdit-1)) {
					sendFldEditKey( &editName[ii], KEY_STAB,0 );
					ii++;
					if (ii >= nEdit) {
						if (parm->nButtons > 1) {
							/* Send focus back to buttons */
							testButton( event.key, TRUE );
							in_edit = FALSE;
						}
						else {
							ii = 0;
							sendFldEditKey( &editName[ii], KEY_TAB, 0 );
						}
					}
					else {
						sendFldEditKey( &editName[ii], KEY_TAB, 0 );
					}
				}
				else if (event.key == KEY_STAB) {
					sendFldEditKey( &editName[ii], KEY_STAB, 0 );
					ii--;
					if (ii < 0) {
						if (parm->nButtons > 1) {
							/* Send focus back to buttons */
							testButton( event.key, TRUE );
							in_edit = FALSE;
						}
						else {
							ii = nEdit - 1;
							sendFldEditKey( &editName[ii], KEY_TAB, 0 );
						}
					}
					else {
						sendFldEditKey( &editName[ii], KEY_TAB, 0 );
					}
				}
				else {
					if (event.key < ' ') {
						result = testButton( event.key, TRUE );
						if (result == BUTTON_NOOP) {
							sendFldEditKey( &editName[ii], event.key, event.flag );
							result = BUTTON_OK;
						}
					}
					else {
						result = sendFldEditKey( &editName[ii], event.key, event.flag );
						if (result == FLD_WIERD) {
							result = testButton( event.key, TRUE );
						}
						else if (result == FLD_NOROOM &&
							(DlgFlags&DLGF_NOFILL)) continue;
					}
#if 0	/* This is what used to be here */
					result = testButton( event.key, TRUE );
					if (result == BUTTON_NOOP) {
						sendFldEditKey( &editName[ii], event.key, event.flag );
						result = BUTTON_OK;
					}
#endif
					// Don't return if user hit an inactive
					// button...
					if (result != BUTTON_NOOP &&
						result != BUTTON_OK) break;
				}
			}
			else /* (!in_edit) */ {
				result = testButton( event.key, TRUE );
				if ( result == BUTTON_LOSEFOCUS ) {
					if (edit) {
						in_edit = TRUE;
						if (event.key == KEY_TAB)
							ii = 0;
						else
							ii = nEdit - 1;
						sendFldEditKey( &editName[ii], KEY_TAB, 0 );
					}
					else {
						/* Force focus back */
						testButton( event.key, TRUE );
					}
				}
				else if (result != BUTTON_OK && result != BUTTON_NOOP) {
					break;
				}
			}
		} else {
			result = testButtonClick( &event, TRUE );
			if( result )
				break;
			if( edit ) {
				int jj;

				for (jj = 0; jj < nEdit; jj++) {
					if (sendFldEditClick( &editName[jj], &event ) == FLD_OK) {
						if (ii != jj) {
							sendFldEditKey( &editName[ii], KEY_STAB, 0 );
							ii = jj;
							sendFldEditKey( &editName[ii], KEY_TAB, 0 );
						}
						setButtonFocus( FALSE, KEY_TAB );
						break;
					}
				}
			}
		}
	}
	dropButton( ourButton, parm->nButtons );

	if (ourButton != parm->pButton) {
		my_free(ourButton);
	}

	if (behind) {
	    win_restore( behind, TRUE );
	}
	pop_cursor();

/* if we used up our global memory, try to get it back */
   if (!globalReserve)
      globalReserve = my_malloc(1000);

	if (result == CallBackKey && CallBackFunc) {
		if (!(*CallBackFunc)()) goto top;
	}
	if (result == KEY_F1) {
		/* Call help here */
		showHelp(helpnum,FALSE);
		goto top;
	}

	return result;
}
#pragma optimize("",on)

void dialog_callback(		/* Install a dialog callback function */
	KEYCODE key,		/* Call function when this key happens */
	int (*func)(void))	/* Function to call */
{
	CallBackKey = key;
	CallBackFunc = func;
}

void dialog_shift(		/* Set dialog shift factor */
	int rowshift,		/* Row shift */
	int colshift)		/* Column shift */
{
	RowShift = rowshift;
	ColShift = colshift;
}

/**
*
* Name		dialog_input - Get input without dialog box
*
* Synopsis	int dialog_input( KEYCODE *keylist, int nkeys, int helpnum )
*
* Parameters
*	See function header below.
*
* Description
*		Collects input just like dialog(), but with no dialog box.
*
* Returns	key code pressed to respond to the message
*
* Version	2.00
*
**/
KEYCODE dialog_input(
	int helpnum,		/*	Help number if non-zero */
	KEYCODE (*infunc)(INPUTEVENT *)) /* Input event callback if not NULL */
{
	INPUTEVENT event;
	KEYCODE result = 0;
top:
	push_cursor();
	hide_cursor();
	move_cursor(ScreenSize.row,0);

	disableButton(KEY_F1,helpnum ? FALSE : TRUE);
	setButtonFocus(TRUE,KEY_TAB);
	for(;;) {
		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			result = testButton( event.key, TRUE );
			if (result == BUTTON_LOSEFOCUS) {
				/*	Force focus back */
				testButton( event.key, TRUE );
				continue;
			}
			if (result != BUTTON_OK && result != BUTTON_NOOP) break;
			if (infunc) {
				result = (*infunc)(&event);
				if (result) break;
			}
		}
		else {
			result = testButtonClick( &event, TRUE );
			if( result ) break;
			if (infunc) {
				result = (*infunc)(&event);
				if (result) break;
			}
		}
	}

	if (result == CallBackKey && CallBackFunc) {
		if (!(*CallBackFunc)()) goto top;
	}
	if (result == KEY_F1) {
		/* Call help here */
		if (helpnum) showHelp(helpnum,FALSE);
		goto top;
	}

	return result;
}
