/*' $Header:   P:/PVCS/MAX/ASQ/ADFSPEC.C_V   1.0   05 Sep 1995 15:04:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ADFSPEC.C								      *
 *									      *
 * ASQ Routine to get where the ADF files are				      *
 *									      *
 ******************************************************************************/

/* C function includes */
#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* Program Includes */
#include "asqtext.h"
#include "commfunc.h"
#include "libcolor.h"
#include "fldedit.h"
#include "ui.h"

/*	Functions defined in this module */

/*	Variables global static for this file */

/*	Program Code */
/**
*
* Name		adf_spec - Get where the adf files are.
*
* Synopsis	int adf_spec(char *spec,int nspec,BOOL err)
*
* Parameters
*			char *spec - Where the current spec is and where to
*						 put the result
*			int  nspec - How long the spec is including the null.
*			BOOL err   - TRUE to issue error message on a retry
*
* Description
*		This routine pops an edit window up on the screen for the
*	ADF specs.  Return FALSE if the user abandons the whole thing (ESC)
*
* Returns	FALSE if abandoned.
*
* Version	1.00
*
**/

int adf_spec(char *spec,int nspec,BOOL err)
{
	enum { EDITFIELD, DBUTTONS } focus = EDITFIELD;
	char workName[MAXFILELENGTH+1];
	FLDITEM editName;
	INPUTEVENT event;
	int rtn;
	int iRows;
	void *behind;
	WINDESC win;
	WINDESC workWin;
	WINDESC stringWin;

	rtn = FALSE;

	if (err) {
		errorMessage(233);
	}

	if (SnapshotOnly) {

	    if (err) {
		printf(SnapADFQuery,spec);
		do {
			if (!fgets(workName,MAXFILELENGTH,stdin)) {
				return (FALSE);
			}
			trim(workName);
			if (toupper(*workName) == RESP_YES) {
				return (FALSE);
			}
		} while(toupper(*workName) != RESP_NO);
	    }
	    printf(AdfSpecText);

	    printf(SnapADFDefault, spec);
	    if (!fgets(workName,MAXFILELENGTH,stdin)) {
		return (FALSE);
	    }
	    if (*workName != '\n') {
		strcpy(spec,workName);
	    }

	    return (TRUE);

	} /* SnapshotOnly */

	/* Count up the rows */
	iRows = wrapStrlen(AdfSpecText,ADFSPECNCOLS - 4);
	iRows += 8;

	/*	Specify where to put the window */
	win.row = ( ScreenSize.row - iRows ) / 2;
	win.col = ( ScreenSize.col - ADFSPECNCOLS ) / 2;
	win.nrows = iRows;
	win.ncols = ADFSPECNCOLS;

	if( saveButtons() != BUTTON_OK )
		return FALSE;

	/*	Save what's behind us */
	behind = win_save( &win, TRUE );
	if( !behind ) {
		restoreButtons();
		return FALSE;
	}


	/*	Specify the color to put it in */
	wput_sca( &win, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, ADFSPECTITLE, NULL, BaseColor );

	/*	Adjust the window inside the box */
	win.col += 2;
	win.ncols -= 5;
	SETWINDOW( &workWin, win.row + 1, win.col, 1, win.ncols );
	stringWin = workWin;


	/*	Set position for error type */
	wrapString( &stringWin, AdfSpecText, &BaseColor );

	workWin.row = win.row + win.nrows - 5;

	/*	No behind so show fld edit MUST work */
	strcpy( workName, spec );
	showFldEdit( &editName, &workWin, 0,
				 workName, MAXFILELENGTH,
				 EditColor, TRUE, FALSE );

	sendFldEditKey( &editName, KEY_TAB, 0 );

	FileNameButtons[NUMFILENAMEBUTTONS-2].pos.row =
		win.row + win.nrows - 3;
	FileNameButtons[NUMFILENAMEBUTTONS-1].pos.row =
		win.row + win.nrows - 3;

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
			wrapString( &stringWin, AdfSpecText, &NormalColor );
			focus = DBUTTONS;
			sendFldEditKey( &editName, KEY_STAB, 0 );
		}
		continue;
editFocus:
		if( focus != EDITFIELD ) {
			wrapString( &stringWin, AdfSpecText, &BaseColor );
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

	if( LastButton.key == KEY_ENTER ) {
		strncpy( spec, workName, nspec-1 );
		spec[nspec-1] = '\0';
		rtn = TRUE;
	}
	else	rtn = FALSE;
	return rtn;
}
