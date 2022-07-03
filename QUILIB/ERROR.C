/*' $Header:   P:/PVCS/MAX/QUILIB/ERROR.C_V   1.0   05 Sep 1995 17:02:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ERROR.C								      *
 *									      *
 * Error message functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*	Program Includes */
#include "libcolor.h"
#include "input.h"
#include "libtext.h"
#include "ui.h"
#include "video.h"
#include "windowfn.h"
#include "myalloc.h"

/*	Definitions for this Module */
void heapdump( void );

/*	Variables global static for this file */


/*	Program Code */
/**
*
* Name		errorMessage
*
* Synopsis	void errorMessage(int error_number);
*
* Parameters
*		int error_number	Specific error number ( See text.h again )
*
* Description
*
* Returns	0 for no errors - 1 for an error exit
*
* Version	2.00
*
**/
void errorMessage( int error_number)
{
	INPUTEVENT event;

	int iRows;
	PMSG pMsg;
	void *behind;
	WINDESC win;
	char color = ErrorColor;

#ifdef HEAPTEST
	heapdump();
#endif

#if DEMO
	/*	Don't do error Processing if demo mode */
	if( DemoMode ) return;
#endif
	push_cursor();
	hide_cursor();

	/*	Build up error message to figure out how big it needs to be */
	pMsg = findMessage(error_number);

	if (SnapshotOnly) {
		printf ("%s\n",pMsg->message);
		return;
	}

	iRows = strlen(pMsg->message);			/* Make the box 3 lines larger */
	iRows /= (MAXMESSAGEWIDTH - 4); 			/* than the message will be */
	iRows += 6;

	/*	Specify where to put the window */
	win.row = ( ScreenSize.row - iRows ) / 2;
	win.col = ( ScreenSize.col - MAXMESSAGEWIDTH ) / 2;
	win.nrows = iRows;
	win.ncols = MAXMESSAGEWIDTH;

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

	/*	Save the buttons */
	if( saveButtons() != BUTTON_OK ) {
	if (behind) {
	       win_restore( behind, TRUE );
	}
	   pop_cursor();

   /* if we used up our global memory, try to get it back */
      if (!globalReserve)
	 globalReserve = my_malloc(1000);
		return;
	}

	/*	Specify the color to put it in */
	wput_sca( &win, VIDWORD( color, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, TypeMessage[pMsg->type], NULL, ErrorBorderColor );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 4;

	/*	Now for the actual error text positioning */
	win.nrows--;
	wrapString( &win, pMsg->message, &color );

	pMsg->buttons->pos.row = win.row + win.nrows - 1;
	if( pMsg->buttonCount == 1 ) {
		pMsg->buttons->pos.col = ( ScreenSize.col - MAXBUTTONTEXT ) / 2;
	} else {
		pMsg->buttons->pos.col = ( ScreenSize.col / 2 ) - MAXBUTTONTEXT - 1;
		(pMsg->buttons + 1)->pos.col = pMsg->buttons->pos.col + MAXBUTTONTEXT + 2;
		(pMsg->buttons + 1)->pos.row = win.row + win.nrows - 2;
	}
	addButton( MessageButtons, pMsg->buttonCount, NULL );
	setButtonFocus( TRUE, KEY_TAB );
	showAllButtons();

	/*	Wait for any character and terminate input */
	for(;;) {
		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			switch( testButton( event.key, TRUE ) ) {
			case BUTTON_OK:
			case BUTTON_NOOP:
				continue;
			case BUTTON_LOSEFOCUS:
				testButton( event.key, TRUE );	/*	Force focus back */
				continue;
			default:
				goto cleanup;
			}
		} else if( testButtonClick( &event, TRUE ) != 0)
			break;
	}
	/*	Cleanup and kill */
cleanup:
	restoreButtons( );
   if (behind)
      win_restore( behind, TRUE );
	pop_cursor();


/* if we used up our global memory, try to get it back */
   if (!globalReserve)
      globalReserve = my_malloc(1000);

}
