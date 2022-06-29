/*' $Header:   P:/PVCS/MAX/QUILIB/PRINT.C_V   1.0   05 Sep 1995 17:02:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PRINT.C								      *
 *									      *
 * Functions to print text						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <string.h>
#include <help.h>

/*	Program Includes */
#include "button.h"
#include "fldedit.h"
#include "qhelp.h"
#include "inthelp.h"
#include "libcolor.h"
#include "libtext.h"
#include "commdef.h"
#include "commfunc.h"
#include "fldedit.h"
#include "qprint.h"
#include "qwindows.h"
#include "screen.h"
#include "ui.h"
#include "video.h"

/*	Definitions for this Module */
#define HEIGHT 22
#define WIDTH  36

#define NOEDITTRUE (!WherePrintList.items[0].state.checked)
#define NOEDITFALSE (WherePrintList.items[0].state.checked)

enum { WHATTEXT, WHERETEXT, FILETEXT };
void showPrintText( WINDESC *win, int which, int hiLite );

/*	Program Code */
/**
*
* Name		doPrint
*
* Synopsis	void doPrint( PTEXTWIN pWin, PRINTTYPE type, int which, int helpNum,int fromHelp	)
*
* Parameters
*			PTEXTWIN pWin;			Pointer to the current text window
*			PRINTTYPE type; 		What type of window this is
*			int which;				which window in a given type
*			int helpNum,			What help number this is
*			int fromHelp;			Were we called from help
*
* Description
*		This routine does ALL Printing
*	Duplicate definition can be found in help.c
*
* Returns	No return
*
* Version	1.0
*/
#pragma optimize ("leg",off)
void doPrint(				/*	Do all printing */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	PRINTTYPE type, 		/*	What type of window this is */
	int which,				/*	which window in a given type */
	int helpNum,			/*	What help number this is */
	int fromHelp )			/*	From help flag */
{
	enum { WHATBUTTON, WHEREBUTTON, NAMEEDIT, DBUTTONS } focus = WHATBUTTON;
	FLDITEM name;
	INPUTEVENT event;
	void *behind = NULL;
	WINDESC win;
	WINDESC textWin;
	PBUTTONLIST pWhichTopList = PrintOptions[type];

	/*	Draw up the dialog box */
	/*	Set up where we are putting this */
	push_cursor();
	hide_cursor();

	SETWINDOW( &win,
			(ScreenSize.row - HEIGHT) / 2,
			(ScreenSize.col - WIDTH) / 2,
			HEIGHT,
			WIDTH );

	/*	Remember what we are stomping on */
	behind = win_save( &win, TRUE );
	if( !behind ) {
		errorMessage( WIN_NOROOM );
		goto lastOut;
	}
	if( saveButtons() != BUTTON_OK )
		goto lastOut;

	/*	Put up the window */
	wput_sca( &win, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, PrintTitle, BottomTitle, BaseColor );

	showPrintText( &win, WHATTEXT, TRUE );

	pWhichTopList->info.win.row = win.row+2;
	showBList( (PBUTTONLIST)pWhichTopList, TRUE );

	showPrintText( &win, WHERETEXT, FALSE );

	WherePrintList.info.win.row = win.row+10;
	showBList( (PBUTTONLIST)&WherePrintList, FALSE );

	showPrintText( &win, FILETEXT, NOEDITTRUE ? FALSE : -1 );

	SETWINDOW( &textWin, win.row+17, 24, 1, 31 );

	/*	No behind so show fld edit MUST work */
	showFldEdit( &name, &textWin, FILENAMEKEY,
				 PrintFile, MAXPRINTFILELENGTH - 1,
				 EditColor, TRUE, FALSE );

	if( NOEDITFALSE ) {
		/*	Where to print is Now the printer so don't show fld edit */
		hideFldText( &name );
	}

	PrintButtons[2].pos.row = win.row + 19;
	PrintButtons[3].pos.row = win.row + 19;

	addButton( PrintButtons, NUMPRINTBUTTONS,NULL );

	if( fromHelp )			/*	don't allow a recursive call to help */
		disableButton( KEY_F1, TRUE );

	disableButton( KEY_F2, TRUE );
	showAllButtons();

askAgain:
	/*	Now we get something from the user */
	for(;;) {
		int oldFocus;
		int oldWhereState;

		/*	Make sure that OK Only works if there is something selected to print */
		/*	Use these before they are set. */
		for ( oldWhereState = oldFocus = 0; oldFocus < pWhichTopList->info.nItems; oldFocus++ ) {
			oldWhereState |= pWhichTopList->items[oldFocus].state.checked;
		}
		disableButton( KEY_ENTER, oldWhereState == 0 );

		oldFocus = focus;
		oldWhereState = NOEDITTRUE;

		get_input(INPUT_WAIT, &event);
		if( testBLItem( (PBUTTONLIST)pWhichTopList, &event, TRUE ) == BUTTON_THISLIST ) {
			if( focus == WHEREBUTTON ) {
				sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_STAB );
				showPrintText( &win, WHERETEXT, FALSE );
			} else if( focus == NAMEEDIT ) {
				showPrintText( &win, FILETEXT, FALSE );
				sendFldEditKey( &name, KEY_STAB, 0 );
			}
			if( focus != WHATBUTTON )
				showPrintText( &win, WHATTEXT, TRUE );
			focus = WHATBUTTON;
			setButtonFocus( FALSE, KEY_TAB );
		} else if( testBLItem( (PBUTTONLIST)&WherePrintList, &event, TRUE ) == BUTTON_THISLIST ) {
			if( focus == WHATBUTTON ) {
				sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
				showPrintText( &win, WHATTEXT, FALSE );
			}
			if( focus == NAMEEDIT ) {
				showPrintText( &win, FILETEXT, FALSE );
				sendFldEditKey( &name, KEY_STAB, 0 );
			}
			if( focus != WHEREBUTTON )
				showPrintText( &win, WHERETEXT, TRUE );
			focus = WHEREBUTTON;
			setButtonFocus( FALSE, KEY_TAB );
		} else if( event.click != MOU_NOCLICK
			&& NOEDITTRUE
			&& sendFldEditClick( &name, &event ) == FLD_OK ) {
			/*	Ok to do this since if we lost focus block selection is lost */
			if( focus == WHEREBUTTON ) {
				showPrintText( &win, WHERETEXT, FALSE );
				sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_STAB );
			} else if( focus == WHATBUTTON ) {
				showPrintText( &win, WHATTEXT, FALSE );
				sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
			}

			if( focus != NAMEEDIT ) {
				showPrintText( &win, FILETEXT, TRUE );
				sendFldEditKey( &name, KEY_TAB, 0 );
			}
			focus = NAMEEDIT;
			setButtonFocus( FALSE, KEY_TAB );
		} else if( !event.key ) {
			switch ( testButtonClick( &event, TRUE )) {
			case KEY_F1:
				showHelp(HELPPRINT, TRUE);
				break;
			case KEY_ESCAPE:
				goto done;
			case KEY_ENTER:
				goto printIt;
			case BUTTON_OK:
				continue;
			case BUTTON_LOSEFOCUS:
				break;				/*	Pop out and let key processing handle */
			}
		}

		if( event.key ) {
			switch( event.key ) {
			case FILENAMEKEY:
				if( NOEDITFALSE ) {
					beep();
					continue;
				}
				if( focus == WHATBUTTON ) {
					showPrintText( &win, WHATTEXT, FALSE );
					sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
				}
				event.key = KEY_TAB;
				focus = WHEREBUTTON;
				/*	Fall into the tab processing.  Cheap and sleazy */
			case KEY_TAB:
				switch( focus ) {
				case WHATBUTTON:
					showPrintText( &win, WHATTEXT, FALSE );
					sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
					showPrintText( &win, WHERETEXT, TRUE );
					sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_TAB );
					focus = WHEREBUTTON;
					break;
				case WHEREBUTTON:
					showPrintText( &win, WHERETEXT, FALSE );
					sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_STAB );
					if( NOEDITFALSE ) {
						setButtonFocus( TRUE, KEY_TAB );
						focus = DBUTTONS;
					} else {
						showPrintText( &win, FILETEXT, TRUE );
						sendFldEditKey( &name, event.key, event.flag );
						focus = NAMEEDIT;
					}
					break;
				case NAMEEDIT:
					showPrintText( &win, FILETEXT, FALSE );
					sendFldEditKey( &name, KEY_STAB,0 ); /* Turn off highlight */
					focus = DBUTTONS;
					setButtonFocus( TRUE, KEY_TAB );
					break;
				case DBUTTONS:
					if( testButton( event.key, FALSE ) == BUTTON_LOSEFOCUS ) {
						showPrintText( &win, WHATTEXT, TRUE );
						sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_TAB );
						focus = WHATBUTTON;
					}
					break;
				}
				break;
			case KEY_STAB:
				switch( focus ) {
				case WHATBUTTON:
					showPrintText( &win, WHATTEXT, FALSE );
					sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
					setButtonFocus( TRUE, KEY_STAB );
					focus = DBUTTONS;
					break;
				case WHEREBUTTON:
					showPrintText( &win, WHERETEXT, FALSE );
					sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_STAB );
					showPrintText( &win, WHATTEXT, TRUE );
					sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_TAB );
					focus = WHATBUTTON;
					break;
				case NAMEEDIT:
					showPrintText( &win, FILETEXT, FALSE );
					sendFldEditKey( &name, event.key, event.flag );
					showPrintText( &win, WHERETEXT, TRUE );
					sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_TAB );
					focus = WHEREBUTTON;
					break;
				case DBUTTONS:
					if( testButton( event.key, FALSE ) == BUTTON_LOSEFOCUS ) {
						showPrintText( &win, WHATTEXT, FALSE );
						sendBLItem( (PBUTTONLIST)pWhichTopList, KEY_STAB );
						if( NOEDITFALSE ) {
							showPrintText( &win, WHERETEXT, TRUE );
							sendBLItem( (PBUTTONLIST)&WherePrintList, KEY_TAB );
							focus = WHEREBUTTON;
						} else {
							showPrintText( &win, FILETEXT, TRUE );
							sendFldEditKey( &name, KEY_TAB,0 ); /*	Turn off highlight */
							focus = NAMEEDIT;
						}
					}
					break;
				}
				break;
			case KEY_UP:
			case KEY_DOWN:
			case KEY_HOME:
			case KEY_END:
			case ' ':
			default:
				if( focus == NAMEEDIT &&
					( toupper (event.key) == RESP_CANCEL ||
					  toupper (event.key) == RESP_OK ))   {
						sendFldEditKey( &name, event.key, event.flag );
						break;
				}
				switch ( testButton( event.key, TRUE )) {
				case KEY_F1:
					showHelp(HELPPRINT, TRUE);
					break;
				case KEY_ESCAPE:
					goto done;
				case KEY_ENTER:
					goto printIt;
				case BUTTON_LOSEFOCUS:
					break;				/*	Pop out and let key processing handle */
				case BUTTON_NOOP:
				default:
					switch( focus ) {
					case WHATBUTTON:
						sendBLItem( (PBUTTONLIST)pWhichTopList, event.key );
						break;
					case WHEREBUTTON:
						sendBLItem( (PBUTTONLIST)&WherePrintList, event.key );
						break;
					case NAMEEDIT:
						sendFldEditKey( &name, event.key, event.flag );
						break;
					}
				}
				break;
			}
		}
		if( NOEDITTRUE != oldWhereState ) {
			if( NOEDITFALSE ) {
				/*	Where to print is Now the printer so don't show fld edit */
				hideFldText( &name );
				showPrintText( &win, FILETEXT, -1 );

			}
			else {
				showFldText( &name, focus == NAMEEDIT, focus == NAMEEDIT );
				showPrintText( &win, FILETEXT, focus == NAMEEDIT );
			}
		}
	}

	/*	The fall from the for loop into printit should never Occur */
printIt:
	if( doPrintCallback(pWin,type,which,helpNum) )
		goto askAgain;

done:
	/*	Don't do a kill fld edit because it doesn't alloc anything in this case */
	/*	Put the screen back the way it was */
	restoreButtons();
lastOut:
	if( behind )
		win_restore( behind, TRUE );
	pop_cursor();
}
#pragma optimize ("",on)

/**
*
* Name		showPrintText
*
* Synopsis	void showPrintText( WINDESC *win, int which, int hiLite )
*
* Parameters
*			WINDESC *win;			Base window we are working from
*			int which;				which window in a given type
*
* Description
*		This routine shows the three text lines on the screen
*
* Returns	No return
*
* Version	1.0
*/
void showPrintText(	/*	Dump the text words to the screen for print */
	WINDESC *win,		/*	Print window */
	int which,			/*	Which Words */
	int hiLite )		/*	Selected or regular */
{
	WINDESC textWin;
	char attr = (char)(hiLite ? ActiveColor : NormalColor) ;
	char trigger = TriggerColor;
	if( hiLite == -1 ) {
		attr = DisableColor;
		trigger = DisableColor;
	}

	SETWINDOW( &textWin,
				win->row+1, win->col+1,
				1, WIDTH - 2 );
	switch( which ) {
	case WHATTEXT:
		justifyString( &textWin,
					PrintWhat,
					PRINTWHATTRIGGER,
					JUSTIFY_CENTER,
					attr,
					trigger );
		break;
	case WHERETEXT:
		textWin.row = win->row+9;
		justifyString( &textWin,
					PrintOutput,
					PRINTOUTPUTTRIGGER,
					JUSTIFY_CENTER,
					attr,
					trigger );
		break;
	case FILETEXT:
		textWin.row = win->row+16;
		justifyString( &textWin,
					PrintFileName,
					PRINTFILENAMETRIGGER,
					JUSTIFY_CENTER,
					attr,
					trigger );
	}
}

void print_argsubs(		/* Argument substution for print/help text */
	char *	 dst,		/* destination */
	char *	 src)		/* source */
{
	if (HelpArgCnt < 1) {
		/* Short circuit */
		strcpy(dst,src);
		return;
	}

	while( *src ) {
		/*	Copy until we hit a # */
		int lc;
		char tag[40];
		char *tagp = tag;
		char *subst;
		char *oldSrc;

		while( *src && *src != '#' )
			*dst++ = *src++;

		if( !*src ) {
			break;		/* off the end of the line */
		}

		/*	Got a tag here	-  Find it and copy the sub dst dst */
		oldSrc = src;
		do {
			if( *src != '_' ) {
				*tagp++ = *src;
				if((tagp - tag) >= sizeof(tag)-1) {
					/*	Ooops, no matching # found	*/
					src = oldSrc;
					break;
				}
			}
			src++;
		} while( *src && *src != '#' );

		if( src == oldSrc ) {
			*dst++ = *src++;
			continue;
		}
		/*	Got a legit tag here - Copy the trailing # */
		*tagp++ = *src++;
		*tagp = '\0';

		/* Allow for not finding the tag */
		subst = tag;

		for( lc = 0; lc < HelpArgCnt; lc++ ) {
			if( strcmp(HelpArgFrom[lc], tag) == 0 ) {
				subst = HelpArgTo[lc];
				break;
			}
		}

		/*	Finally copy the new value into place */
		tagp = subst;
		while( *tagp )
			*dst++ = *tagp++;

	}	/*	while( *src ) */

	*dst = '\0';
}
