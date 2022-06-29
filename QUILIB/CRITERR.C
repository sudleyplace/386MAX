/*' $Header:   P:/PVCS/MAX/QUILIB/CRITERR.C_V   1.1   13 Oct 1995 12:12:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CRITERR.C								      *
 *									      *
 * Function to display critical error window				      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <string.h>
#include <conio.h>
#include <ctype.h>

/* Local Includes */

#include "commfunc.h"
#include "libtext.h"
#include "libcolor.h"
#include "ui.h"
#include "myalloc.h"

/* Local variables */

/******************************** DISPLAY_CRITERR *****************************/
/* Display critical error window */

int _cdecl display_criterr (	/* Display critical error window */
	int flag,		/* 0 = device error, 1 = disk error */
	char *aritxt)		/* Error message to display */
{
	int iRows;
	int width;
	int rtn;
	PMSG pMsg;
	void *behind;
	WINDESC win;
	int b1wid, b2wid, b3wid, wwid;


	/* If we're already here, don't come in again */
	disableButton(KEY_ESCAPE,TRUE);
	disable23 ();

	push_cursor();
	hide_cursor();

	/*	Build up message to figure out how big it needs to be */
	pMsg = findMessage(555);
	pMsg->message = aritxt;
	if (flag)
		pMsg->type = ERRTYPE_DISK;
	else
		pMsg->type = ERRTYPE_DEVICE;

	b1wid = (pMsg->buttons + 0)->buttonLength + 2;
	b2wid = (pMsg->buttons + 1)->buttonLength + 2;
	b3wid = (pMsg->buttons + 2)->buttonLength + 2;

	wwid = 2 + b1wid + b2wid + b3wid;
	width = 48;
	if (wwid >= width) {
		width = wwid;
		wwid = 0;
	}
	else {
		wwid = (width - wwid) >> 1;
	}

	iRows = strlen(pMsg->message);	/* Make the box 3 lines larger */
	iRows /= (width - 4);		/* than the message will be */
	iRows += 6;

	/*	Specify where to put the window */
	win.row = ( ScreenSize.row - iRows ) / 2;
	win.col = ( ScreenSize.col - width ) / 2;
	win.nrows = iRows;
	win.ncols = width;

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

	if( saveButtons() != BUTTON_OK ) {

		if (behind) {
		       win_restore( behind, TRUE );
		}
		pop_cursor();

		/* if we used up our global memory, try to get it back */
		if (!globalReserve)
		 globalReserve = my_malloc(1000);

		return 0;
	}

	wput_sca( &win, VIDWORD( ErrorColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, TypeMessage[pMsg->type], NULL, ErrorColor );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 4;

	/*	Set position for error type */
	wrapString( &win, pMsg->message, &ErrorColor );

	pMsg->buttons->pos.row = win.row + win.nrows - 2;

	pMsg->buttons->pos.col = wwid + win.col;

	(pMsg->buttons + 1)->pos.col = pMsg->buttons->pos.col + b1wid;
	(pMsg->buttons + 1)->pos.row = win.row + win.nrows - 2;

	(pMsg->buttons + 2)->pos.col = (pMsg->buttons + 1)->pos.col + b2wid;
	(pMsg->buttons + 2)->pos.row = win.row + win.nrows - 2;

	addButton( pMsg->buttons, pMsg->buttonCount, NULL );
	setButtonData(FALSE);
	showAllButtons();

	/*	Wait for any character and terminate input */

	/*  Hey!  LEAVE THIS CODE ALONE!! */
	do {
		rtn = _getch();
		rtn = toupper(rtn);
	} while (rtn != RESP_ABORT && rtn != RESP_RETRY && rtn != RESP_FAIL);
#if 0
	/* We can't use the standard input processing here because
	 * we are inside INT 24H.  This code, or something that this
	 * code calls, will make DOS hang.  So don't call it.
	 */
	do {
		INPUTEVENT event;

		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			switch( testButton( event.key, TRUE ) ) {
			case BUTTON_NOOP:
			case BUTTON_OK:
				continue;
			case BUTTON_LOSEFOCUS:
				testButton( event.key, TRUE );	/*	Force focus back */
				continue;
			default:
				goto cleanup;
			}
		}
		else if( testButtonClick( &event, TRUE ) != 0)
			break;
	} while( LastButton.key != RESP_ABORT &&
		 LastButton.key != RESP_RETRY &&
		 LastButton.key != RESP_FAIL);

cleanup:
	rtn = LastButton.key;
#endif

	/*	Cleanup and kill */
	restoreButtons( );
	if (behind) {
		win_restore( behind, TRUE );
	}
	pop_cursor();

	/* if we used up our global memory, try to get it back */
	if (!globalReserve)
		globalReserve = my_malloc(1000);

	enable23 ();
	disableButton(KEY_ESCAPE,FALSE);

	return rtn;
} /* End DISPLAY_CRITERR */

