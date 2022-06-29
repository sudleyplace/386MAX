/*' $Header:   P:/PVCS/MAX/ASQ/ASQDATA.C_V   1.1   05 Sep 1995 16:27:28   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ASQDATA.C								      *
 *									      *
 * Routines for the ASQ data window					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>
#include <stdlib.h>

/*	Program Includes */
#include "libcolor.h"
#include "message.h"
#include "qprint.h"
#include "qwindows.h"
#include "surface.h"
#include "asqtext.h"
#include "ui.h"

/*	Definitions for this Module */

/*	Functions defined in this module */
#ifdef SPECIALDATA
int specialData(			/*	Menu callback function */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	INPUTEVENT *event		/*	What event to process - Could be null */
);
#endif /* SPECIALDATA */

/*	Variables global static for this file */

/*	Program Code */
/**
*
* Name		presentData
*
* Synopsis	KEYCODE  presentData( int item, int helpNum);
*
* Parameters
*	int item;		Which info item to present
*	int helpNum;	Help number to call with
*
* Description
*		Fill up the data win with data.
*
* Returns	KEY_APGUP or KEY_APGDN or NOTHING
*
* Version	2.00
*
**/
KEYCODE  presentData( int infoNum, int helpNum, BOOL wide )
{
	char *dataLine;
	char stuff[256];
	ENGTEXT infoData;
	int waitShown = FALSE;
	void *behind = NULL;
	PDATAINFO pData = DataInfo+infoNum;
	TEXTWIN textWin;
	WINDESC datawin;
	WINDESC workWin;
	WINRETURN retVal;
	KEYCODE retCode = 0;

	datawin = DataWin;
	if (wide) {
		/*	Extend the data window over the quick window */
		datawin.ncols = (QuickWin.col + QuickWin.ncols) - datawin.col;
		/*	Save what's behind us */
		behind = win_save( &datawin, TRUE );
		if( !behind ) {
			/* Need an error message here */
			return 0;
		}
	}

	/*	Make sure it's empty - Including the window */
	memset( &textWin, 0, sizeof( textWin ));

	/*	Make sure the screen is clean */
	wput_sca( &datawin, VIDWORD( DataColor, ' ' ));

	/*	Maybe put up the working message
	*	Don't forget the take down at the end
	*/
	if( pData->working ) {
		sayWaitWindow( &datawin, WORKING );
		waitShown = TRUE;
	}


	/*	Initialize the data fetch */
	if (engine_control(CTRL_SETBUF,tutorWorkSpace, WORKSPACESIZE) != 0 ||
	    engine_control(CTRL_ISETUP,&infoData,infoNum) != 0)
	{
		errorMessage( 501 );
		goto cleanup;
	}

	/*	We know how many rows are in this buffer so create
	*	a window space big enough to hold all the data
	*/
	retVal = vWin_create( &textWin, &datawin,    /* +1 for leading blank line */
					max(infoData.length+1,datawin.nrows-2),
					max(infoData.width+1,datawin.ncols - 2),
					DataColor, SHADOW_DOUBLE, BORDER_BLANK,
					infoData.length > datawin.nrows - 3,	/*	Vscroll bar */
					infoData.width > datawin.ncols - 3,
					FALSE,
					TRUE	);

	if( retVal != WIN_OK ) {
		errorMessage( retVal );
		engine_control(CTRL_IPURGE,&infoData,infoNum);
		if (behind) {
			win_restore( behind, TRUE );
		}
		return 0;
	}

	/*	Pump out the title */
	SETWINDOW( &workWin, datawin.row, datawin.col, 1, datawin.ncols );
	wput_sc(&workWin,' ');
	justifyString( &workWin, pData->title,
					-1, JUSTIFY_CENTER,
					DataYellowColor, DataYellowColor );

	if (*ReadFile) {
		workWin.ncols = strlen(SnapInParens);
		workWin.col = datawin.ncols - workWin.ncols;
		wput_csa(&workWin,SnapInParens,DataYellowColor);
	}

	SETWINDOW( &workWin,  0, 0, 1, datawin.ncols );
	infoData.nbuf = sizeof(stuff);
	infoData.buf = stuff;
	while( engine_control(CTRL_IFETCH,&infoData,0) == 0 )
	{
		int len = 0;
		int count;
		int format;
		char *start;

		workWin.row++;
		workWin.col = 0;

		count = *infoData.buf - CODE_BASE;
		dataLine = infoData.buf+IEXTRA;

		format = *(infoData.buf+1) - CODE_BASE;
		if (format == CENTER_LINE) {
			/* Handle centered lines */
			int nc;

			nc = (datawin.ncols - strlen(dataLine))/2;
			if (nc > 0) {
				workWin.col += nc;
			}
		}

		if (count >= 0)
		{
			start = dataLine + count;
			len = count;
		}
		else if (count == CONTIN_LINE)
		{
			/*	This is a continuation line - Indent is in 1st position */
			workWin.col = dataLine[0] - '0';
			start = dataLine + workWin.col;
		} else
		{
			start = dataLine;
		}

		/*	Write the description out in brown */
		if(len > 0) {
			workWin.ncols = len;
			vWinPut_sca( &textWin, &workWin, dataLine, DataYellowColor );
			workWin.col += len;
		}

		else if(count == CONTIN_LINE)
		{
			/*	Do a continuation line mark - Has to be a blank
			 *	so printing works but needs to be White background
			 */
			vWin_put_a( &textWin, workWin.row, workWin.col++, (char)DataContinueColor );
			start++;
		}
		/*	write the value out in white ( What was there ) */
		vWin_put_s( &textWin, workWin.row, workWin.col, start );
	}
	engine_control(CTRL_IPURGE,&infoData,infoNum);

	/*	Maybe kill the working message */
	if( waitShown ) {
		killWait( );
		waitShown = FALSE;
	}


	setButtonText( KEY_ESCAPE, MenuEsc, MENUESCTRIG );
	addButton( DataButtons, NUMDATABUTTONS, NULL );
	showAllButtons();

	do {
		/*	Let user run around -  Automatically turns window paints on */
userControl:
#ifdef SPECIALDATA
		switch( vWin_ask( &textWin, specialData )) {
#else
		switch( vWin_ask( &textWin, NULL )) {
#endif
		case WIN_BUTTON:
			pushButton( LastButton.number );
			switch( LastButton.key ) {
			case KEY_F1:
				showHelp( helpNum, FALSE	);
				goto userControl;
			case KEY_F2:
				doPrint( &textWin, P_MENU, infoNum, helpNum, FALSE );
				goto userControl;
			case KEY_F3:
				showHelp( infoNum + TUTORIAL_Mem_Sum - 1, FALSE );
				goto userControl;
			case KEY_APGUP:
			case KEY_APGDN:
				retCode = LastButton.key;
				goto cleanup;
			}
			break;
#ifdef SPECIALDATA
		case WIN_APGUP:
			retCode = KEY_APGUP;
			goto cleanup;
		case WIN_APGDN:
			retCode = KEY_APGDN;
			goto cleanup;
#endif /* SPECIALDATA */
		}
	} while ( LastButton.key != KEY_ESCAPE );

cleanup:
	/*	Maybe kill the working message */
	if( waitShown )
		killWait( );

	/*	Kill the window if it got created */
	if( textWin.data )
		vWin_destroy( &textWin );

	dropButton( DataButtons, NUMDATABUTTONS);

	if (behind) {
		win_restore( behind, TRUE );
	}
	else {
		/*	Make sure the screen is clean */
		wput_sca( &DataWin, VIDWORD( DataColor, ' ' ));

		/*	Wipe out the scroll bars on right and bottom edge */
		SETWINDOW( &workWin, datawin.row,
			datawin.col+datawin.ncols - 1, datawin.nrows, 1 );
		wput_sca(&workWin, VIDWORD( DataColor, ' ' ));  /*      Full space */

		SETWINDOW( &workWin, datawin.row+datawin.nrows - 1,
			datawin.col, 1, datawin.ncols );
		wput_sca(&workWin, VIDWORD( DataColor, ' ' ));  /*      Full space */
	}

	return retCode;
}

#ifdef SPECIALDATA
/**
*
* Name		specialData - Return WIN_APGUP or WIN_APGDN if alt... presend
*
* Synopsis	void specialData( PTEXTWIN pText, INPUTEVENT *event )
*
* Parameters
*		PTEXTWIN pText		What window to update
*		INPUTEVENT *event	what keyboard event to process
*
* Description
*		Deal with the special keys required by Data
*
* Returns	WIN_NOOP - Don't recognize the event
*			WIN_OK	 - Processed the event - No further action
*			WIN_APGUP - Return Enter key to caller of vWin_ask
*
* Version	1.0
*/
int specialData(			/*	Menu callback function */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	INPUTEVENT *event)		/*	What event to process - Could be null */
{
	if( pWin );		/*	Shut up the compiler - pWin not important here */
	switch( event->key ) {
	case KEY_APGUP:
	case KEY_APGDN:
		return event->key;
	}
	return WIN_NOOP;
}

#endif /*  SPECIALDATA */
/**
*
* Name		quickShowData
*
* Synopsis	int quickShowData( int item);
*
* Parameters
*	int item;		Which info item to present
*
* Description
*		Fill up the data win with data.
*
* Returns	None.
*
* Version	2.00
*
**/
void quickShowData( int infoNum )
{
	char *dataLine;
	char tempAttr = DataContinueColor;
	char stuff[256];
	ENGTEXT infoData;
	int waitShown = FALSE;
	int endCol = DataWin.col + DataWin.ncols - 2;
	PDATAINFO pData = DataInfo+infoNum;
	WINDESC workWin;


	/*	Initialize the data fetch */
	if (engine_control(CTRL_SETBUF,tutorWorkSpace, WORKSPACESIZE) != 0 ||
	    engine_control(CTRL_ISETUP,&infoData,infoNum) != 0)
	{
		errorMessage( 501 );
		goto cleanup;
	}


	/*	Pump out the title */
	SETWINDOW( &workWin, DataWin.row, DataWin.col, 1, DataWin.ncols );
	wput_sca(&workWin, VIDWORD( DataColor, ' ' ));  /*      Full space */
	justifyString( &workWin, pData->title,
					-1, JUSTIFY_CENTER,
					DataYellowColor, DataYellowColor );

	if (*ReadFile) {
		workWin.ncols = strlen(SnapInParens);
		workWin.col = DataWin.ncols - workWin.ncols;
		wput_csa(&workWin,SnapInParens,DataYellowColor);
	}

	SETWINDOW( &workWin,  DataWin.row+1, DataWin.col+1, 1, DataWin.ncols-1 );
	wput_sca( &workWin, VIDWORD( DataColor, ' ' ));
	infoData.nbuf = sizeof(stuff);
	infoData.buf = stuff;
	while( engine_control(CTRL_IFETCH,&infoData,0) == 0
			&& workWin.row < DataWin.row + DataWin.nrows - 2 )
	{
		int len = 0;
		int count;
		int format;
		char *start;

		workWin.row++;
		workWin.col = DataWin.col+1;
		workWin.ncols = DataWin.ncols - 1;	/*	Allow the scroll bar too */
		wput_sca( &workWin, VIDWORD( DataColor, ' ' ));
		count = *infoData.buf - CODE_BASE;
		dataLine = infoData.buf+IEXTRA;

		format = *(infoData.buf+1) - CODE_BASE;
		if (format == CENTER_LINE) {
			/* Handle centered lines */
			int nc;

			nc = (DataWin.ncols - strlen(dataLine))/2;
			if (nc > 0) {
				workWin.col += nc;
			}
		}

		if (count >= 0)
		{
			start = dataLine + count;
			len = count;
		}
		else if (count == CONTIN_LINE)
		{
			/*	This is a continuation line - Indent is in 1st position */
			workWin.col = dataLine[0] - '0';
			start = dataLine + workWin.col;
		} else
		{
			start = dataLine;
		}

		/*	Write the description out in brown */
		if(len > 0) {
			workWin.ncols = len;
			if( workWin.col + workWin.ncols > endCol )
				workWin.ncols = endCol - workWin.col;
			wput_csa( &workWin, dataLine, DataYellowColor );
			workWin.col += len;
		}

		else if(count == CONTIN_LINE)
		{
			/*	Do a continuation line mark - Has to be a blank
			 *	so printing works but needs to be White background
			 */
			workWin.ncols = 1;
			wput_a( &workWin, &tempAttr );
			workWin.col = DataWin.col + 1 + dataLine[0] - '0';
			start++;
		}
		/*	write the value out in white ( What was there ) */
		workWin.ncols = strlen( start );
		if( workWin.col + workWin.ncols > endCol )
			workWin.ncols = endCol - workWin.col;
		wput_c( &workWin, start );
	}
	engine_control(CTRL_IPURGE,&infoData,infoNum);

	workWin.col = DataWin.col;
	workWin.ncols = DataWin.ncols;
	workWin.row++;
	while(	workWin.row < DataWin.row + DataWin.nrows - 1 ) {
		wput_sca( &workWin, VIDWORD( DataColor, ' ' ));
		workWin.row++;
	}

cleanup:
	return;
}
