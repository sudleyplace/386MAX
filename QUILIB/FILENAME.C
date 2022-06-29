/*' $Header:   P:/PVCS/MAX/QUILIB/FILENAME.C_V   1.0   05 Sep 1995 17:02:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * FILENAME.C								      *
 *									      *
 * Function to query the user for a filename				      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>
#include <ctype.h>

/*	Program Includes */
#include "commfunc.h"
#include "libcolor.h"
#include "fldedit.h"
#include "ui.h"

/*	Definitions for this Module */

/*	Functions defined in this module */

/*	Variables global static for this file */

/*	Program Code */
/**
*
* Name		askFileName
*
* Synopsis	int askFileName( char *name);
*
* Parameters
*	char *name;		Name to edit
*
* Description
*	Pump out the standardized box - Will probably have to add a title later
*	return what key the use hit ( Escape or Enter ).  Return the new value
*	ONLY if user hits enter.  Assume that name is MAXFILELENGTH long.
*
* Returns	key code pressed to respond to the message
*
* Version	1.00
*
**/
int askFileName(		/*	Get a file name from the user */
	char *name)		/*	Place to store the name - MAXFILELENGTH long */
{
	enum { EDITFIELD, DBUTTONS } focus = EDITFIELD;
	char workName[MAXFILELENGTH+1];
	FLDITEM editName;
	INPUTEVENT event;
	void *behind;
	WINDESC win;
	WINDESC workWin;
	WINDESC stringWin;

	/*	Specify where to put the window */
	win.row = ( ScreenSize.row - FILENAMENROWS ) / 2;
	win.col = ( ScreenSize.col - FILENAMENCOLS ) / 2;
	win.nrows = FILENAMENROWS;
	win.ncols = FILENAMENCOLS;

	if( saveButtons() != BUTTON_OK )
		return 0;

	/*	Save what's behind us */
	behind = win_save( &win, TRUE );
	if( !behind )
		return 0;

	/*	Specify the color to put it in */
	wput_sca( &win, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, FILELOADTITLE, NULL, BaseColor );

	/*	Adjust the window inside the box */
	win.col += 2;
	win.ncols -= 5;
	SETWINDOW( &workWin, win.row + FILETEXTROW, win.col, 1, win.ncols );
	stringWin = workWin;


	justifyString( &stringWin, FILELOADTEXT, -1, JUSTIFY_CENTER, BaseColor, BaseColor );

	workWin.row = win.row + FILEEDITROW;
	/*	No behind so show fld edit MUST work */
	strcpy( workName, name );
	showFldEdit( &editName, &workWin, 0,
				 workName, MAXFILELENGTH,
				 EditColor, TRUE, FALSE );

	sendFldEditKey( &editName, KEY_TAB, 0 );

	FileNameButtons[NUMFILENAMEBUTTONS-2].pos.row = win.row + FILEBUTTONROW;
	FileNameButtons[NUMFILENAMEBUTTONS-1].pos.row = win.row + FILEBUTTONROW;

	addButton( FileNameButtons, NUMFILENAMEBUTTONS, NULL );
	disableButton( KEY_F2, TRUE );
	showAllButtons();

	/*	Wait for any character and terminate input */
	for(;;) {
		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			int retVal;
			if( focus == EDITFIELD ) {
				switch( toupper (event.key) ) {
				case RESP_CANCEL:
				case RESP_OK:
					sendFldEditKey( &editName, event.key, event.flag );
					continue;
				}
			}

			retVal = testButton( event.key, TRUE );
			switch( retVal ) {
			case KEY_F1:
				showHelp( HELPDIALOGS, FALSE );
				continue;
			case KEY_ESCAPE:
			case KEY_ENTER:
				goto cleanup;
			case BUTTON_LOSEFOCUS:
				goto editFocus;
			case BUTTON_OK:
				goto buttonFocus;
			}
			if( sendFldEditKey( &editName, event.key, event.flag ) == FLD_OK )
				goto editFocus;

		} else {
			if( testButtonClick( &event, TRUE ) ) {
				if( LastButton.key == KEY_F1 ) {
					showHelp( HELPDIALOGS, FALSE );
					continue;
				}
				else
					break;
			}
			if( sendFldEditClick( &editName, &event ) == FLD_OK ) {
				goto editFocus;
			}
		}
		continue;
buttonFocus:
		if( focus == EDITFIELD ) {
			justifyString( &stringWin, FILELOADTEXT, -1, JUSTIFY_CENTER, NormalColor, NormalColor );
			focus = DBUTTONS;
			sendFldEditKey( &editName, KEY_STAB, 0 );
		}
		continue;
editFocus:
		if( focus != EDITFIELD ) {
			justifyString( &stringWin, FILELOADTEXT, -1, JUSTIFY_CENTER, BaseColor, BaseColor );
			focus = EDITFIELD;
			setButtonFocus( FALSE, KEY_TAB );
			sendFldEditKey( &editName, KEY_TAB, 0);
		}

	}

	/*	Cleanup and kill */
cleanup:
	restoreButtons( );
	win_restore( behind, TRUE );
	hide_cursor();

	if( LastButton.key == KEY_ENTER )
		strcpy( name, workName );
	return LastButton.key;

}
