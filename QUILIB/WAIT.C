/*' $Header:   P:/PVCS/MAX/QUILIB/WAIT.C_V   1.0   05 Sep 1995 17:02:28   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * WAIT.C								      *
 *									      *
 * Functions to manage the waiting message box				      *
 *									      *
 ******************************************************************************/

/*	C function includes */

/*	Program Includes */
#include "libcolor.h"
#include "engine.h"
#include "ui.h"
#include "windowfn.h"
#include "myalloc.h"


/*	Definitions for this Module */

/*	Functions defined in this module */

/*	Variables global static for this file */
static void *behind;
static WINDESC win;

/*	Program Code */
/**
*
* Name		sayWait - Put up the waiting message box
*
* Synopsis	void sayWait( char *text )
*
* Parameters
*			char *text - What is the word to put up
*
* Description
*		This routine creates a window to display the specified text in,
*	the window is self centering and has a border.
*
*
* Returns	void
*
* Version	2.00
*
**/
void sayWait( char *text )
{

	win.row = (ScreenSize.row - 1) / 2;
	win.col = (ScreenSize.col - EVALBOX ) / 2;
	win.nrows = 3;
	win.ncols = EVALBOX + 2;

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

	wput_sca( &win, VIDWORD( WaitColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_SINGLE, NULL, NULL, WaitColor );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 3;

	justifyString( &win, text, -1, JUSTIFY_LEFT, WaitColor, WaitColor );
	return;
}

/**
*
* Name		killWait - Clean up the waiting message box
*
* Synopsis	void killWaint( void )
*
* Parameters
*			none
*
* Description
*		This routine removes the wait message.
*
*
* Returns	void
*
* Version	1.00
*
**/
void killWait( void )
{

   if (behind) {
      win_restore( behind, TRUE );
   }

/* if we used up our global memory, try to get it back */
   if (!globalReserve)
      globalReserve = my_malloc(1000);
   behind = NULL;
}


/**
*
* Name		sayWaitWindow - Put up the waiting message box - In a window
*
* Synopsis	void sayWaitWindow( WINDESC *win, char *text )
*
* Parameters
*			WINDESC *win - Window to center in
*			char *text - What is the word to put up
*
* Description
*		This routine creates a window to display the specified text in,
*	the window is self centering and has a border. Centers in the
*	window
*
*
* Returns	void
*
* Version	2.00
*
**/
void sayWaitWindow(	/*	Put up a message centered in a window */
	WINDESC *targetWin,		/*	Window to work in */
	char *text )		/*	Text to write */
{

	win = *targetWin;
	win.row += (targetWin->nrows - 3) / 2;
	win.col += (targetWin->ncols - EVALBOX ) / 2;
	win.nrows = 3;
	win.ncols = EVALBOX + 2;

	behind = win_save( &win, TRUE );
/* if we DON'T have enough room, release the reserve */
   if (!behind) {
      if (globalReserve) {
	 my_free(globalReserve);
	 globalReserve = NULL;
	 behind = win_save( &win, TRUE );
      }
   }

	wput_sca( &win, VIDWORD( WaitColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_SINGLE, NULL, NULL, WaitColor );

	/*	Adjust the window inside the box */
	win.row++;
	win.col += 2;
	win.nrows -= 2;
	win.ncols -= 3;

	justifyString( &win, text, -1, JUSTIFY_LEFT, WaitColor, WaitColor );
	return;
}
