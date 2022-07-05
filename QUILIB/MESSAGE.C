/*' $Header:   P:/PVCS/MAX/QUILIB/MESSAGE.C_V   1.0   05 Sep 1995 17:02:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MESSAGE.C								      *
 *									      *
 * Message display functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*	Program Includes */
#include "input.h"
#include "libcolor.h"
#include "message.h"
#include "libtext.h"
#include "ui.h"
#include "video.h"
#include "myalloc.h"

/*	Definitions for this Module */
int   MaxMESSAGEWIDTH;

/*	Functions defined in this module */

/*	Variables global static for this file */
char messageText[80];
static MSG emUnknown = { 0, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, messageText };

/*	Program Code */
/**
*
* Name		askMessage
*
* Synopsis	int askMessage(int message_number);
*
* Parameters
*		int message_number	Specific message number ( See text.h again )
*
* Description
*
*		Throw the specified message up on the screen and let the
*	user respond to it.  REturn what ever key was hit
*
* Returns	key code pressed to respond to the message
*
* Version	2.00
*
**/
int askMessage( int message_number)
{
	INPUTEVENT event;
	int iRows;
	char *colors;
	PMSG pMsg;
	void *behind;
	WINDESC win;

#if DEMO
	/*	Don't do error Processing if demo mode */
	if( DemoMode ) return KB_S_N_ESC;
#endif

	push_cursor();
	hide_cursor();

	/*	Build up message to figure out how big it needs to be */
	pMsg = findMessage(message_number);

	MaxMESSAGEWIDTH = MAXMESSAGEWIDTH;
	if (pMsg->buttonCount > 2) {
		MaxMESSAGEWIDTH += (MAXMESSAGEWIDTH < 56 ? 56-MAXMESSAGEWIDTH : 0);
	}
	iRows = strlen(pMsg->message);			/* Make the box 3 lines larger */
	iRows /= (MaxMESSAGEWIDTH - 4); 			/* than the message will be */
	iRows += 6;

	/*	Specify where to put the window */
	win.row = ( ScreenSize.row - iRows ) / 2;
	win.col = ( ScreenSize.col - MaxMESSAGEWIDTH ) / 2;
	win.nrows = iRows;
	win.ncols = MaxMESSAGEWIDTH;

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

	/*	Specify the color to put it in */
	if (pMsg->type == ERRTYPE_WARNING) {
		/* 'scuse me while put this here penny in the fuse box. */
		colors = ErrDlgColors;
	}
	else {
		colors = NorDlgColors;
	}

	wput_sca( &win, VIDWORD( colors[0], ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, TypeMessage[pMsg->type], NULL, colors[0] );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 4;

	/*	Set position for error type */
	wrapString( &win, pMsg->message, colors );

	pMsg->buttons->pos.row = win.row + win.nrows - 2;

   switch (pMsg->buttonCount) {
   case 1:
		pMsg->buttons->pos.col = ( ScreenSize.col - MAXBUTTONTEXT ) / 2;
      break;
   case 2:
		pMsg->buttons->pos.col = ( ScreenSize.col / 2 ) - MAXBUTTONTEXT;
		(pMsg->buttons + 1)->pos.col = pMsg->buttons->pos.col + MAXBUTTONTEXT + 1;
		(pMsg->buttons + 1)->pos.row = win.row + win.nrows - 2;
      break;
   case 3:
		pMsg->buttons->pos.col = ( ScreenSize.col / 2 ) - ((3 * (MAXBUTTONTEXT + 1))	/ 2) + 1;

		(pMsg->buttons + 1)->pos.col = pMsg->buttons->pos.col + MAXBUTTONTEXT + 1;
		(pMsg->buttons + 1)->pos.row = win.row + win.nrows - 2;

		(pMsg->buttons + 2)->pos.col = (pMsg->buttons + 1)->pos.col + MAXBUTTONTEXT + 1;
		(pMsg->buttons + 2)->pos.row = win.row + win.nrows - 2;
      break;
   }

	addButton( pMsg->buttons, pMsg->buttonCount, NULL );
	setButtonFocus( TRUE, KEY_TAB );
	showAllButtons();

	/*	Wait for any character and terminate input */
	for(;;) {
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
		} else if( testButtonClick( &event, TRUE ) != 0)
			break;
	}
	/*	Cleanup and kill */
cleanup:
	restoreButtons( );
	if (behind) {
	    win_restore( behind, TRUE );
	}
	pop_cursor();

/* if we used up our global memory, try to get it back */
   if (!globalReserve)
      globalReserve = my_malloc(1000);

	return LastButton.key;

}

/**
*
* Name		findMessage
*
* Synopsis	pMsg findMessage(int message_number);
*
* Parameters
*		int message_number	Specific message number ( See text.h again )
*
* Description
*		This function turns an error message into a text string
*	It scans the errormessage list in text.h and returns a
*	pointer to the message that matches.
*		If no match is found, it returns a message about
*	unknown message number n.
*
* Returns	pMsg which is always valid
*
* Version	1.00
*
**/
PMSG findMessage( int message_number)
{
	PMSG pMsg;

	for( pMsg = msgs;
		(pMsg->number <= message_number ) &&
		(pMsg < msgs + sizeof( msgs) / sizeof( msgs[0] ));
		pMsg++ )
	{
		if( pMsg->number == message_number )
		{
			if(message_number == 206)		/*	Special handling for 206 */
			{
				emUnknown.number = 206;
				sprintf (messageText, pMsg->message, errno);
				pMsg = &emUnknown;
			}
			return pMsg;
		}
	}

	emUnknown.number = message_number;
	sprintf( messageText, "UNKNOWN MSG %4x", message_number);
	return &emUnknown;
}
