/*' $Header:   P:/PVCS/MAX/QUILIB/UI.C_V   1.1   13 Oct 1995 12:13:20   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * UI.C 								      *
 *									      *
 * User interface functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <conio.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "libcolor.h"
#include "constant.h"
#include "input.h"
#include "keyboard.h"
#include "libtext.h"
#include "screen.h"
#include "ui.h"
#include "video.h"
#include "windowfn.h"

/*	Definitions for this Module */
#define VERTBORDER 52
#define VERTSPACE  2

void dumpShadow( WINDESC *win );
/*	Program Code */
/**
*
* Name		initializeScreenInfo
*
* Synopsis	void initializeScreenInfo( BOOL snowcontrol )
*
* Parameters
*		none
*
* Description
*		This routine sets up the UI variables about what kind of screen
*	and keyboard and other necessary info about the environment we
*	are living in.
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void initializeScreenInfo( BOOL snowcontrol )
{
	VIDEOPARM parm;

	get_video_parm(&parm);

	ScreenSize.col = parm.cols;
	ScreenSize.row = parm.rows;
	AdapterType = parm.id[0].adapter;

	/* Set screen I/O mode */
	if (parm.id[0].adapter == ADAPTERID_CGA && snowcontrol)
		set_mode(WINMODE_SLOW);
	else
		set_mode(WINMODE_FAST);

	if (!ScreenSet) {
		if (parm.monotube)
			ScreenType = SCREEN_MONO;
		else
			ScreenType = SCREEN_COLOR;
	}
	setLibColors(ScreenType == SCREEN_MONO ? TRUE : FALSE);

	/* Init background screen metrics */
	DataWin.row = 2;
	DataWin.col = 1;
	DataWin.nrows = ScreenSize.row - 5;
	DataWin.ncols = VERTBORDER;

	QuickWin.row = DataWin.row;
	QuickWin.nrows = DataWin.nrows;
	QuickWin.col = VERTBORDER + VERTSPACE + 2;
	QuickWin.ncols = ScreenSize.col - VERTBORDER - VERTSPACE - 5;

}

/**
*
* Name		PaintBackgroundScreen
*
* Synopsis	void paintBackgroundScreen( void )
*
* Parameters
*		none
*
* Description
*		This routine draws in the basic background screen moving in
*	the boxes as appropriate.  It will not put ANY words on the screen
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void paintBackgroundScreen( void )
{
	WINDESC win;

	SETWINDOW( &win, 0,0, ScreenSize.row, ScreenSize.col );
	wput_sca( &win, VIDWORD( BackScreenColor, BACKCHAR ));	/*	Full space */

	wput_sca( &DataWin, VIDWORD( DataColor, ' '));
	shadowWindow( &DataWin );

	wput_sca( &QuickWin, VIDWORD( QuickBackColor, ' '));
	shadowWindow( &QuickWin );
}

/**
*
* Name		pressAnyKey
*
* Synopsis	BOOL pressAnyKey( long delay )
*
* Parameters
*		none
*
* Description
*		This routine draws a button on the bottom of the screen telling
*	the user to press any key to continue
*
* Returns	TRUE if user wants to abort.
*
* Version	1.0
*/
BOOL pressAnyKey( long delay )
{
	BOOL rtn;
	INPUTEVENT event;
	WINDESC win;
	WINDESC winSave;

	WORD saveBuffer[ sizeof( PRESSANYKEYTEXT ) + 1 ];

	/*	Don't include the terminator */
	SETWINDOW( &win, ScreenSize.row-1, 2, 1, sizeof( PRESSANYKEYTEXT ) - 1 );

	/*	Save the under screen */
	winSave = win;
	winSave.ncols++;
	wget_ca( &winSave, saveBuffer );

	/*	Put the message out */
	wput_csa( &win, PressAnyKeyData, PressAnyKeyColor );

	/*	And it's shadow */
	halfShadow( &win );
	move_cursor(ScreenSize.row,0);
	get_input(delay, &event);
	if (event.key == KEY_ESCAPE) rtn = TRUE;
	else			     rtn = FALSE;

	/*	Put back the original screen */
	wput_ca( &winSave, saveBuffer );
	return rtn;
}

/**
*
* Name		shadowWindow
*
* Synopsis	void shadowWindow( WINDESC *win,	)
*
* Parameters
*		WINDESC *win		Window to shadow
*
* Description
*		This routine draws a shadow around a window definition.
*	The shadow is done by changing the attribute of the correct positions
*	to black on black.
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void shadowWindow(
	WINDESC *win )			/* Window descriptor */
{
	WINDESC shadowWin;

	SETWINDOW( &shadowWin,
				win->row+1, win->col + win->ncols,
				win->nrows, 2 );

	if( shadowWin.col + 1 == ScreenSize.col )
		shadowWin.ncols = 1;

	if( shadowWin.col + shadowWin.ncols <= ScreenSize.col )
		dumpShadow( &shadowWin );

	SETWINDOW( &shadowWin,
				win->row+win->nrows, win->col + 2,
				1, win->ncols-2 );
	if( shadowWin.col +win->ncols >= ScreenSize.col )
		shadowWin.ncols = ScreenSize.col - shadowWin.col;
	if( shadowWin.row + shadowWin.nrows <= ScreenSize.row )
		dumpShadow( &shadowWin );

}

/**
*
* Name		dumpShadow
*
* Synopsis	void dumpShadow( WINDESC *win )
*
* Parameters
*		WINDESC *win		Window to shadow
*
* Description
*		Do the actual shadowing by looking at a char and deciding
*	what kind of shadow to do.	Shadows are therefore destructive.
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void dumpShadow( WINDESC *win )
{
	int xCount, yCount;
	WINDESC workWin;

	workWin.col = win->col;
	workWin.nrows = workWin.ncols = 1;
	for( xCount = 0; xCount < win->ncols; xCount++, workWin.col++ ) {
		for( yCount = 0, workWin.row = win->row;
			 yCount < win->nrows; yCount++,
			 workWin.row++ ) {

			char c;

			/*	Look at each character and change it appropraitely */
			wget_c( &workWin, &c );
			switch( c ) {
			case BACKCHAR:
			case BOTTOMCHAR:
			case TOPCHAR:
				wput_sa( &workWin, SolidBlackColor );
				break;
			default:
				wput_sa( &workWin, ShadowColor );
			}
		}
	}
}

/**
*
* Name		halfShadow
*
* Synopsis	void halfShadow( void )
*
* Parameters
*		none
*
* Description
*		This routine draws a thin shadow around a window definition.
*	The shadow is done by changing the attribute of the correct positions
*	to black on black and placing appropriate characters.
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void halfShadow(
	WINDESC *win )		/* Window descriptor */
{
	char attChar;
	char attr;
	char outAttr = 0x0f;
	WINDESC shadowWin;

	/*	Down right edge */
	shadowWin.col = win->col + win->ncols;
	if( shadowWin.col < ScreenSize.col ) {
		int nrows = win->nrows;
		shadowWin.row = win->row + nrows - 1;
		shadowWin.nrows = 1;
		shadowWin.ncols = 1;

		for( ; nrows > 1 ; nrows--, shadowWin.row-- ) {
			wget_a( &shadowWin, &attr );
			wget_c( &shadowWin, &attChar );
			if( shadowWin.row < DataWin.row || shadowWin.row > ScreenSize.row - 3)
				outAttr = (char)(FORETOBACK( attr ));	/*	Force the color correct */
			wput_sca( &shadowWin,
				VIDWORD( BG_BLACK | BACKTOFORE( outAttr ),
					 RIGHTCHAR));	/*	upper half box in BACKTOFORE color - lower half black */

		}
		/*	Put the top character last */
		wget_a( &shadowWin, &attr );
		wget_c( &shadowWin, &attChar );
		outAttr = attr;
		if( shadowWin.row < DataWin.row || shadowWin.row > ScreenSize.row - 3)
			outAttr = (char)(FORETOBACK( attr ));	/*	Force the color correct */
		if( attChar == TOPCHAR )
			outAttr = (char)(FORETOBACK( attr ));	/*	Force the color correct */
		wput_sca( &shadowWin,
			VIDWORD( BG_BLACK | BACKTOFORE( outAttr ),
				 TOPCHAR));	/*	upper half box in BACKTOFORE color - lower half black */

	}

	/* across bottom */
	shadowWin.row = win->row + win->nrows;
	if( shadowWin.row < ScreenSize.row ) {
		int ncols = win->ncols;
		shadowWin.row = win->row + win->nrows;
		shadowWin.col = win->col + win->ncols;
		if( shadowWin.col >= ScreenSize.col ) { 		/*	Don't walk off edge */
			shadowWin.col--;
			ncols--;
		}
		shadowWin.nrows = 1;
		shadowWin.ncols = 1;
		for( ;ncols; ncols--, shadowWin.col-- ) {
			wget_a( &shadowWin, &attr );
			wget_c( &shadowWin, &attChar );
			outAttr = attr;
			if( shadowWin.row < DataWin.row || shadowWin.row > ScreenSize.row - 3)
				outAttr = (char)(FORETOBACK( attr ));	/*	Force the color correct */
			if( attChar == BOTTOMCHAR )
				outAttr = (char)(FORETOBACK( attr ));	/*	Force the color correct */

			wput_sca( &shadowWin,
				VIDWORD( BG_BLACK | BACKTOFORE( outAttr ),
					 BOTTOMCHAR));	/*	upper half box in BACKTOFORE color - lower half black */

		}
	}
}

/**
*
* Name		beep
*
* Synopsis	void beep( void )
*
* Parameters
*		none
*
* Description
*		Make some noise so the user knows whats happened
*
* Returns	It ALWAYS works.
*
* Version	1.0
*/
void beep( void )
{
	_putch( '\a' );
}
