/*' $Header:   P:/PVCS/MAX/QUILIB/TEXTWIN.C_V   1.0   05 Sep 1995 17:02:24   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * TEXTWIN.C								      *
 *									      *
 * Text window management functions					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "qwindows.h"
#include "ui.h"
#include "windowfn.h"
#include "myalloc.h"

/*	Definitions for this Module */
void paintScrollBar( WINDESC *win, char attr, int max, int current );
void vWin_clearBottom( PTEXTWIN pText );

static char cupCDown[2] = { '\x1e', '\x1f' };
static char upDown[2] = { '\x18','\x19' };
static char cleftCRight[2] = { '\x11', '\x10' };
static char leftRight[2] = { '\x1b','\x1a' };
static char filler = '\xB0';

/*	Program Code */
/**
*
* Name		vWin_create - Create and initialize a text window
*
* Synopsis	int vWin_create(		PTEXTWIN pText,
*									WINDESC *win,
*									int nrows,
*									int ncols,
*									int shadow,
*									int remember
*									int delayed	)
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window descriptor
*	int nrows;					How many rows in the window
*	int ncols;					How wide is the window
*	int shadow;				Should this have a shadow
*	BORDERTYPE border,			What type of border does this get
*	int remember;				Should we remember what was below
*	int delayed				Show we postpone wiping the data space
*
* Description
*		Allocate required memory,  save screen area, and
*	basically initialize everything
*
* Returns	WIN_OK for no errors -
*			WIN_NOMEMORY if unable to allocate memory
*
* Version	1.0
*/
WINRETURN vWin_create(	/*	Create a text window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/* Window descriptor */
	int nrows,				/*	How many rows in the window */
	int ncols,				/*	How wide is the window */
	char attr,				/*	Default attribute for a window */
	SHADOWTYPE shadow,		/*	Should this have a shadow */
	BORDERTYPE border,		/*	What type of border does this get */
	int vScrollBar, 		/*	Is there a vertical scroll bar */
	int hScrollBar, 		/*	How about horizontal scroll bar */
	int remember,			/*	Should we remember what was below */
	int delayed)			/*	Is the inside screen wipe to be delayed */
{
	WINDESC tempWin = *win;

	memset( pText, 0, sizeof( TEXTWIN ));

	/*	Photograph the current screen if told to */
	if( remember )
		pText->behind = win_save( &tempWin, shadow );

	if( !delayed )
		wput_sca( &tempWin, VIDWORD( attr, ' ' ));              /*      Clear the screen too */

	switch( shadow ) {
	case SHADOW_SINGLE:
		halfShadow( &tempWin );
		break;
	case SHADOW_DOUBLE:
		shadowWindow( &tempWin );
		break;
	}

	switch( border ) {
	case BORDER_NONE:
		/*	Allow for scroll bars if present */
		if( vScrollBar ) {
			tempWin.col++;
			tempWin.ncols -= 2;
		}
		if( hScrollBar ) {
			tempWin.row++;
			tempWin.nrows -= 2;
		}
		break;
	case BORDER_SINGLE:
	case BORDER_DOUBLE:
		box( &tempWin, (BOXTYPE)border, NULL, NULL, attr );
		/*	Fall into the BLANK logic */
	case BORDER_BLANK:
		/*	Blanks were put up above so just get on with things! */
		/*	Paint scroll bars here */

		/*	Shrink the box so other things fit */
		tempWin.row++;
		tempWin.col++;
		tempWin.nrows -= 2;
		tempWin.ncols -= 2;
		break;
	}

	/*	Set other information */
	pText->win = tempWin;
	pText->size.row = nrows;
	pText->size.col = ncols;
	pText->numChar = nrows * ncols;
	pText->attr = attr;
	pText->cShape = get_cursor();		/*	Force cursor to default to current */
	pText->delayed = delayed;

	if( vScrollBar ) {
		SETWINDOW( &pText->vScroll, tempWin.row, tempWin.col+tempWin.ncols,
				   tempWin.nrows, 1 );
	} else
		pText->vScroll.row = -1;

	if( hScrollBar ) {
		SETWINDOW( &pText->hScroll, tempWin.row+tempWin.nrows, tempWin.col,
					1, tempWin.ncols );
	} else
		pText->hScroll.row = -1;

	/*	Always add a data space */
	pText->data = (PCELL)my_malloc( pText->numChar*sizeof( CELL ));


	/*	Initialize the data space to blanks */
	if( pText->data ) {
		wordset( (LPWORD)pText->data, VIDWORD( attr, ' ' ), pText->numChar );
	}
	else {
		if (pText->behind) win_restore (pText->behind, 1);
		return (WIN_NOMEMORY);
	} /* Couldn't allocate data */
	return WIN_OK;
}


/**
*
* Name		vWin_destroy - Release and restore a text window
*
* Synopsis	int vWin_destroy( PTEXTWIN pText )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*	  Restore the screen and release any allocated blocks.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_destroy( /*	Delete a text window */
	PTEXTWIN pText			/*	Pointer to text window */
	)
{
	if( pText->data )
		my_free( pText->data );
	if( pText->behind )
		win_restore( pText->behind, TRUE );

	return WIN_OK;
}


/**
*
* Name		resizeVWin - Release and restore a text window
*
* Synopsis	int resizeVWin( PTEXTWIN pText, int nrows )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int nrows;					New number of rows
*
* Description
*		This function makes ALOT of assumptions with NO safety net.
*	1)	There was a data window created with the original create call
*	2)	You aren't shrinking something smaller than the virtual window
*
*
* Returns	WIN_OK for no errors
*			WIN_NOMEMORY if the realloc failed
*
* Version	1.0
*/
WINRETURN resizeVWin(		/*	Resize a window vertically ONLY */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int nrows				/*	How many rows to allow now */
	)
{
	unsigned oldSize = pText->numChar;

	pText->numChar = nrows * pText->size.col;
	pText->data = (PCELL)my_realloc( pText->data, pText->numChar*sizeof( CELL ));
	pText->size.row = nrows;

	if( !pText->data )
		return WIN_NOMEMORY;

	if( oldSize < pText->numChar ) {
		/*	Fill from the old end to the new end with spaces and color */
		wordset( (LPWORD)pText->data+oldSize,
				VIDWORD( pText->attr, ' ' ),
				pText->numChar - oldSize);
	}

	return WIN_OK;
}

/**
*
* Name		vWin_setDelay - Delay or activate a window
*
* Synopsis	WINRETURN vWin_setDelay( PTEXTWIN pText, int delayed )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int delayed;				True to delay - FALSE to force screen current
*
* Description
*		Delay any screen updates or force the screen current
*
* Returns	whatever vWin_Show returns
*
*
* Version	1.0
*/
WINRETURN vWin_setDelay(
	PTEXTWIN pText, 		/*	Pointer to text window */
	int delayed			/*	Is this window to be delayed */
	)
{
	pText->delayed = delayed;
	if( !delayed ) {
		return vWin_forceCurrent( pText );
	}
	return WIN_OK;
}

/**
*
* Name		vWin_forceCurrent - Delay or activate a window
*
* Synopsis	WINRETURN vWin_forceCurrent( PTEXTWIN pText )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		DUmp the current window to the screen.
*
* Returns	whatever vWin_Show returns
*
*
* Version	1.0
*/
WINRETURN vWin_forceCurrent(
	PTEXTWIN pText) 		/*	Pointer to text window */
{
	WINDESC temp;
	SETWINDOW( &temp, 0, 0, pText->size.row, pText->size.col );
	vWin_clearBottom( pText );
	return vWin_show( pText, &temp );
}

/**
*
* Name		vWinPut_c - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN vWinPut_c(PTEXTWIN pText, WINDESC *win, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window to use
*	char *text );				What text to write with default attr
*
* Description
*		Put text into the video image as required.	Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_c.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinPut_c(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text )			/*	What text to write with default attr */
{
	PCELL startPos;

	int nrows, ncols;
	startPos = pText->data + (win->row * pText->size.col + win->col);

	/*	Now will fit in window */
	for( nrows = win->nrows; nrows; nrows-- ) {
		PCELL thisCell = startPos;
		for( ncols = win->ncols; ncols; ncols-- ) {
			thisCell++->ch = *text++;
		}
		startPos += pText->size.col;
	}
	/*	Now dump the modified part out to the real screen */
	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, win );
}

/**
*
* Name		vWinPut_ca - Write a string of text into the memory /video
*		space.	The text contains attribute information
*		If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN vWinPut_ca(PTEXTWIN pText, WINDESC *win, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window to use
*	char *text );				What text to write with attrs
*
* Description
*		Put text into the video image as required.	Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_c.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinPut_ca(		/*	Write a text string with attributes into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text )			/*	What text to write with attrs */
{
	PCELL startPos;

	int nrows;
	startPos = pText->data + (win->row * pText->size.col + win->col);

	/*	Now will fit in window */
	for( nrows = win->nrows; nrows; nrows-- ) {
		PCELL thisCell = startPos;
		wordcpy( (LPWORD)thisCell, (LPWORD)text, win->ncols );
		startPos += pText->size.col;
	}
	/*	Now dump the modified part out to the real screen */
	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, win );
}


/**
*
* Name		vWinPut_sa - Smear an attribute over a window range
*
* Synopsis	WINRETURN vWinPut_sa(PTEXTWIN pText, WINDESC *win, char attr )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window to use
*	char attr );				What attribute to use
*
* Description
*		Put attribute into the video image as required. Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_sa.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinPut_sa(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char attr )			/*	What attribute to write */
{
	PCELL startPos;

	int nrows, ncols;
	startPos = pText->data + (win->row * pText->size.col + win->col);

	/*	Now will fit in window */
	for( nrows = win->nrows; nrows; nrows-- ) {
		PCELL thisCell = startPos;
		for( ncols = win->ncols; ncols; ncols-- ) {
			thisCell++->attr = attr;
		}
		startPos += pText->size.col;
	}
	/*	Now dump the modified part out to the real screen */
	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, win );
}

/**
*
* Name		vWinPut_sca - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN vWinPut_sca(PTEXTWIN pText, WINDESC *win, char *text, char attr )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window to use
*	char *text					What text to write with default attr
*	char attr					Attribute to use for color
*
* Description
*		Put text into the video image as required.	Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_c.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinPut_sca(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	WINDESC *win,			/*	Window to spray text into */
	char *text,			/*	What text to write with default attr */
	char attr)				/*	Attribute to use */
{
	PCELL startPos;

	int nrows, ncols;
	startPos = pText->data + (win->row * pText->size.col + win->col);

	/*	Now will fit in window */
	for( nrows = win->nrows; nrows; nrows-- ) {
		PCELL thisCell = startPos;
		for( ncols = win->ncols; ncols; ncols-- ) {
			thisCell->attr = attr;
			thisCell++->ch = *text++;
		}
		startPos += pText->size.col;
	}
	/*	Now dump the modified part out to the real screen */
	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, win );

}

/**
*
* Name		vWin_put_c - Write a character to the specified spot on the screen
*
* Synopsis	WINRETURN vWin_put_c(PTEXTWIN pText, int row, int col, char ch )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
*	char ch );				What text to write with default attr
*
* Description
*		Save a character off in the video buffer and adjust the screen
*	Assume the the current Attribute is correct
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_put_c(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char ch )				/*	What text to write with default attr */
{
	PCELL image = pText->data;
	image += row * pText->size.col + col;
	image->ch = ch;

	/*	Now update the visible screen if required */
	if(    pText->cursor.row >= pText->corner.row
		&& pText->cursor.col >= pText->corner.col
		&& pText->cursor.row <	pText->corner.row + pText->win.nrows
		&& pText->cursor.col <	pText->corner.col + pText->win.ncols	) {

		WINDESC workWin;

		SETWINDOW( &workWin, row, col, 1, 1 );
		if( !pText->delayed )
			return vWin_show( pText, &workWin );
	}

	return WIN_OK;
}

/**
*
* Name		vWin_put_a - Write a attribute to the specified spot
*
* Synopsis	WINRETURN vWin_put_a(PTEXTWIN pText, int row, int col, char attr )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
*	char attr );				What attribute to write
*
* Description
*		Set an attribute byte on the screen.  Don't touch the character
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_put_a(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char attr )				/*	What attribute to use */
{
	PCELL image = pText->data;
	image += row * pText->size.col + col;
	image->attr = attr;

	/*	Now update the visible screen if required */
	if(    pText->cursor.row >= pText->corner.row
		&& pText->cursor.col >= pText->corner.col
		&& pText->cursor.row <	pText->corner.row + pText->win.nrows
		&& pText->cursor.col <	pText->corner.col + pText->win.ncols	) {

		WINDESC workWin;

		SETWINDOW( &workWin, row, col, 1, 1 );
		if( !pText->delayed )
			return vWin_show( pText, &workWin );
	}

	return WIN_OK;
}

/**
*
* Name		vWin_put_s - Write a character to the specified spot on the screen
*
* Synopsis	WINRETURN vWin_put_s(PTEXTWIN pText, int row, int col, char *string )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
*	char *string ); 			What text to write with default attr
*
* Description
*		Save a character off in the video buffer and adjust the screen
*	Assume the the current Attribute is correct
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_put_s(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char *text )			/*	What text to write with default attr */
{
	PCELL cell;
	PCELL image = pText->data;
	WINDESC workWin;

	image += row * pText->size.col + col;
	for( cell = image; *text; text++, cell++ )
		cell->ch = *text;


	SETWINDOW( &workWin, row, col, 1, cell - image );

	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, &workWin );
}

/**
*
* Name		vWin_put_sca - Write a string with a given attribute
*
* Synopsis	WINRETURN vWin_put_sca(PTEXTWIN pText, int row, int col,
*								char *string, char attr )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
*	char *string,				What text to write with default attr
*	char attr					Attribute to use
*
* Description
*		Save a character off in the video buffer and adjust the screen
*	Change the current attribute to the specified one.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_put_sca( 	/*	Write a text string into the window with a different color attribute*/
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char *text,				/*	What text to write with default attr */
	char attr )			/*	What attribute to use */
{
	PCELL cell;
	PCELL image = pText->data;
	WINDESC workWin;

	image += row * pText->size.col + col;
	for( cell = image; *text; text++, cell++ ) {
		cell->ch = *text;
		cell->attr = attr;
	}


	SETWINDOW( &workWin, row, col, 1, cell - image );

	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, &workWin );
}


/**
*
* Name		vWinGet_s - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN vWinGet_s(PTEXTWIN pText, int row, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	char *text );				What text to write with default attr
*
* Description
*		Put text into the video image as required.	Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_c.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinGet_s(		/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
int   row,	     /* row starting position */
char *text )			/*	What text to write with default attr */
{
	PCELL startPos, thisCell;
	int ncols = 0;

	startPos = pText->data + (row * pText->size.col);

	thisCell = startPos;

	for (ncols = 0; ncols < pText->size.col; ncols++) {
		*text++ = thisCell++->ch;
	}
	return(0);
}


/**
*
* Name		vWin_insertChar - make room and write a character to the specified spot on the screen
*
* Synopsis	WINRETURN vWin_insertChar(PTEXTWIN pText, int row, int col, char ch )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
*	char ch );				What text to write with default attr
*
* Description
*		Move everything to the right 1 pos and
*	save a character off in the video buffer and adjust the screen
*	Assume the the current Attribute is correct
*
* Returns	WIN_OK for no errors
*			WIN_NOROOM if there is a character in the last position of the row
*
* Version	1.0
*/
WINRETURN vWin_insertChar(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col,				/*	Column to start in */
	char ch )				/*	What text to write with default attr */
{
	PCELL image;
	PCELL edge;
	WINDESC workWin;

	edge = pText->data + ((row+1) * pText->size.col - 1);
	if( edge->ch != ' ' )
		return WIN_NOROOM;

	image = pText->data + (row * pText->size.col + col);

	for( ; edge > image; edge-- )
		*(edge-1) = *edge;

	image->ch = ch;

	SETWINDOW( &workWin, row, col, 1, pText->size.col-col);

	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, &workWin );
}

/**
*
* Name		vWin_deleteChar - Pop the current char and move everything left
*
* Synopsis	WINRETURN vWin_deleteChar(PTEXTWIN pText, int row, int col )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col)					col to start on
*
* Description
*		Move everything to the left - Fill the last pos in with
*	a blank
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_deleteChar(		/*	Write a character into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int row,				/*	Row to start at */
	int col)				/*	Column to start in */
{
	PCELL image;
	PCELL edge;
	WINDESC workWin;

	edge = pText->data + ((row+1) * pText->size.col - 1);

	image = pText->data + (row * pText->size.col + col);

	for( ; edge < image; edge++ )
		*edge = *(edge+1);

	edge->ch = ' ';
	SETWINDOW( &workWin, row, col, 1, pText->size.col-col);

	if( pText->delayed )
		return WIN_OK;
	else
		return vWin_show( pText, &workWin );
}

/**
*
* Name		vWin_show - Show a section of the visible window
*
* Synopsis	WINRETURN vWin_show(PTEXTWIN pText, WIN *win )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WIN *win;					What section of the window to show
*
* Description
*		Show a section of the real window in the visible window.
*	This routines ASSUMES!!!! that there is a data window.
*	Works in two steps:
*		1 - Clip the request into the visible window
*		2 - Paint the adjusted rectangle
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_show(	/*	Dump the video buffer to screen */
	PTEXTWIN pText, 	/*	Text window to show in */
	WINDESC *win )			/*	Subset to show */
{
	int temp;
	WINDESC work;	/*	Adjusted window to show */
	WINDESC actual; /*	Window that we will use to actually dump data to screen */
	WORD *startPos; /*	Where in full window are we */

	if( pText->delayed )
		return WIN_OK;

	/*	Do the row stuff first */
	temp = win->row - pText->corner.row;
	if( temp >= 0 ) {
		/*	Whats changed starts on the screen ( maybe ) */
		if( temp > pText->win.nrows )
			return WIN_OK;			/*	Total off the screen at bottom */
		work.row = pText->corner.row + temp;
		work.nrows = min( pText->win.nrows - temp, win->nrows );
	} else {
		/* Starting position is off the screen above */
		if( win->nrows < -temp )
			return WIN_OK;			/*	Doesn't reach the visible part */
		work.row = pText->corner.row;
		work.nrows = min( pText->win.nrows, win->nrows+temp ) ;
	}

	/*	now do the col stuff */
	temp = win->col - pText->corner.col;
	if( temp >= 0 ) {
		/*	Whats changed starts on the screen ( maybe ) */
		if( temp > pText->win.ncols )
			return WIN_OK;			/*	Total off the screen at right */
		work.col = pText->corner.col + temp;
		work.ncols = min( pText->win.ncols - temp, win->ncols );
	} else {
		/* Starting position is off the screen above */
		if( win->ncols < -temp )
			return WIN_OK;			/*	Doesn't reach the visible part */
		work.col = pText->corner.col;
		work.ncols = min( pText->win.ncols, win->ncols+temp ) ;
	}

	/*
	*	Now work has a corner definition relative to the virtual window
	*	that is all visible.  DUmp the rows out 1 at a time to handle
	*	spill to the right of the window
	*/
	actual.row = pText->win.row + work.row - pText->corner.row;
	actual.col = pText->win.col + work.col - pText->corner.col;
	actual.nrows = 1;
	actual.ncols = work.ncols;

	startPos = (WORD *)(pText->data + (work.row * pText->size.col + work.col));
	for( ;work.nrows; work.nrows--, actual.row++ ) {
		wput_ca( &actual, startPos );
		startPos += pText->size.col;
	}
	vWin_updateCursor(pText);
}

/**
*
* Name		vWin_clearBottom - Wipe from end of data to end of window
*
* Synopsis	void vWin_clearBottom( PTEXTWIN pText
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Do nothing if the virtual window is longer than the real window
*	If virtual window is shorter, wipe out the bottom
*
* Returns	no return
*
* Version	1.0
*/
void vWin_clearBottom( PTEXTWIN pText )
{
	if( pText->win.nrows > pText->size.row ) {
		WINDESC workWin = pText->win;
		/*	Got to do it */
		workWin.row += pText->size.row;
		workWin.nrows -= pText->size.row;
		if( workWin.nrows > 0 )
			wput_sca( &workWin, VIDWORD( pText->attr, ' ' ));       /*      Clear the screen too */
	}

}

/**
*
* Name		vWin_ask - Keyboard interface for a window
*
* Synopsis	WINRETURN vWin_ask(PTEXTWIN pText, VWINCALLBACK *callBack	)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	VWINCALLBACK *callBack, 	Function to preprocess keys with
*
* Description
*		Accept mouse and keyboard events and move the window around
*	as required.
*	Use the call back function for special processing.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWin_ask(	/*	Let a user run around a window */
	PTEXTWIN pText, 	/*	Text window to run around in */
	VWINCALLBACK callBack) /*	Function to preprocess keys with */
{
	INPUTEVENT event;
	WINRETURN action;
	WINRETURN retVal = WIN_OK;
	POINT oldCorner;

	/*	Force the window to be current if delayed */
	if( pText->delayed ) {
		WINDESC temp;
		SETWINDOW( &temp, 0, 0, pText->win.nrows, pText->win.ncols );
		pText->delayed = FALSE;
		vWin_clearBottom( pText );
		vWin_show( pText, &temp );
	}

	/*	Put up scroll bars */
	if( pText->vScroll.row > 0 )
		paintScrollBar( &pText->vScroll, pText->attr,
			pText->size.row - pText->win.nrows, pText->corner.row );
	if( pText->hScroll.row > 0 )
		paintScrollBar( &pText->hScroll, pText->attr,
			pText->size.col - pText->win.ncols, pText->corner.col );

	/*	Force the cursor invisible */
	pText->cursorVisible = FALSE;
	vWin_updateCursor( pText );

	for(;;) {
		oldCorner = pText->corner;

		get_input(INPUT_WAIT, &event);

		/*	Do special processing if required */
		if( callBack ) {
			action = (*callBack)( pText, &event );
			switch( action ) {
			case WIN_OK:	/*	Callback processed it - No further action */
				continue;
			case WIN_NOOP:	/*	Not a recognized key */
				break;
			default:
				retVal = action;	/*	 Return action to caller */
				goto done;
			}
		}

		if( event.key ) {
			action = vWin_key( pText, event.key );
		} else {
			action = vWin_mouse( pText, &event );
		}
		switch( action ) {
		case WIN_MOVETO:
			goto dumpScreen;
		case WIN_UP:
			if( pText->corner.row > 0 )
				pText->corner.row--;
			goto dumpScreen;
		case WIN_DOWN:
			if( pText->size.row - pText->win.nrows > pText->corner.row )
				pText->corner.row++;
			goto dumpScreen;
		case WIN_RIGHT:
			if( pText->size.col - pText->win.ncols > pText->corner.col )
				pText->corner.col++;
			goto dumpScreen;
		case WIN_LEFT:
			if( pText->corner.col > 0 )
				pText->corner.col--;
			goto dumpScreen;
		case WIN_HOME:
			pText->corner.col = 0;
			goto dumpScreen;
		case WIN_END:
			pText->corner.col = pText->size.col - pText->win.ncols;
			goto dumpScreen;
		case WIN_TOP:
			pText->corner.row = 0;
			goto dumpScreen;
		case WIN_BOTTOM:
			pText->corner.row = pText->size.row - pText->win.nrows;
			goto dumpScreen;
		case WIN_PGLEFT:
			pText->corner.col -= pText->win.ncols;
			if( pText->corner.col < 0 )
				pText->corner.col = 0;
			goto dumpScreen;
		case WIN_PGRIGHT:
			pText->corner.col += pText->win.ncols;
			pText->corner.col =
				min( pText->corner.col, pText->size.col - pText->win.ncols );
			goto dumpScreen;
		case WIN_PGUP:
			pText->corner.row -= pText->win.nrows;
			if( pText->corner.row < 0 )
				pText->corner.row = 0;
			goto dumpScreen;
		case WIN_PGDN:
			{
				WINDESC workWin;
				pText->corner.row += pText->win.nrows;
				pText->corner.row =
					min( pText->corner.row, pText->size.row - pText->win.nrows );
dumpScreen:
				SETWINDOW( &workWin, pText->corner.row, pText->corner.col,
									 pText->win.nrows, pText->win.ncols );
				vWin_show( pText, &workWin );
				if( (pText->vScroll.row > 0) && oldCorner.row != pText->corner.row )
					paintScrollBar( &pText->vScroll, pText->attr,
						pText->size.row - pText->win.nrows, pText->corner.row );
				if( (pText->hScroll.row > 0) && oldCorner.col != pText->corner.col )
					paintScrollBar( &pText->hScroll, pText->attr,
						pText->size.col - pText->win.ncols, pText->corner.col );
				break;
			}
		case WIN_BUTTON:
		case WIN_ABANDON:
			retVal = action;
			goto done;
		}
	}
done:
	return retVal;
}

/**
*
* Name		vWin_key - Analyze keycode and return action ( if any )
*
* Synopsis	WINRETURN vWin_key(PTEXTWIN pText, KEYCODE key	)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	KEYCODE key;				What key to analyze
*
* Description
*		Return a menu action based on a key action.  If the action is
*	out of range - return NOOP;
*
* Returns	WIN code for the correct action
*
* Version	1.0
*/
WINRETURN vWin_key(	/*	Take a key and return an appropriate action */
	PTEXTWIN pText, 	/*	Window to consider */
	KEYCODE key )		/*	Actual key pressed */
{
	int retVal;

	switch ( key ) {
	case KEY_HOME:
		return pText->corner.col ? WIN_HOME : WIN_NOOP;
	case KEY_CHOME:
		return pText->corner.row ? WIN_TOP : WIN_NOOP;
	case KEY_UP:
		return pText->corner.row ? WIN_UP : WIN_NOOP;
	case KEY_PGUP:
		return pText->corner.row ? WIN_PGUP : WIN_NOOP;
	case KEY_LEFT:
		return pText->corner.col ? WIN_LEFT : WIN_NOOP;
	case KEY_RIGHT:
		return pText->corner.col + pText->win.ncols	>= pText->size.col ? WIN_NOOP : WIN_RIGHT;
	case KEY_PGDN:
		return pText->corner.row + pText->win.nrows	>= pText->size.row ? WIN_NOOP : WIN_PGDN;
	case KEY_END:
		return pText->corner.col + pText->win.ncols	>= pText->size.col ? WIN_NOOP : WIN_END;
	case KEY_CEND:
		return pText->corner.row + pText->win.nrows	>= pText->size.row ? WIN_NOOP : WIN_BOTTOM;
	case KEY_DOWN:
		return pText->corner.row + pText->win.nrows >= pText->size.row ? WIN_NOOP : WIN_DOWN;
	}

	retVal = testButton( key, FALSE );
	if( retVal == BUTTON_LOSEFOCUS )
		return testButton( key, FALSE );	/*	DO it again to force focus back */
	if( retVal && retVal != BUTTON_NOOP )
		return WIN_BUTTON;
	return key == KEY_ESCAPE ? WIN_ABANDON : WIN_NOOP;
}

/**
*
* Name		vWin_mouse - Analyze mouse event and return action ( if any )
*
* Synopsis	WINRETURN vWin_mouse(PTEXTWIN pText, INPUTEVENT *event	)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	INPUTEVENT *event;				What mouse event to analyze
*
* Description
*		Return a menu action based on a mouse action.	If the action is
*	out of range - return NOOP.  Most mouse actions have to do with the
*	scroll bars since we can't resize a window
*
* Returns	WIN code for the correct action
*
* Version	1.0
*/
WINRETURN vWin_mouse(		/*	Translate a mouse action into a window movement */
	PTEXTWIN pText, 		/* Window that will get the action */
	INPUTEVENT *event )	/*	What mouse event occured */
{
	WINRETURN retVal = WIN_NOOP;
	if( pText->hScroll.row != -1 ) {
		retVal = testScroll( &pText->hScroll, event,
			pText->size.col - pText->win.ncols, &pText->corner.col );
		switch( retVal ) {
		case WIN_OK:
			return WIN_OK;
		case WIN_UP:
			return WIN_LEFT;
		case WIN_DOWN:
			return WIN_RIGHT;
		case WIN_PGUP:
			return WIN_PGLEFT;
		case WIN_PGDN:
			return WIN_PGRIGHT;
		case WIN_MOVETO:
			return WIN_MOVETO;
		}

	}

	if( pText->vScroll.row != -1 ) {
		retVal = testScroll( &pText->vScroll, event,
			pText->size.row - pText->win.nrows, &pText->corner.row );
		if( retVal != WIN_NOOP )
			return retVal;
	}

	/*	Nothing in the window - Check buttons on the bottom */
	return testButtonClick( event, FALSE ) ? WIN_BUTTON : WIN_NOOP;
}

/**
*
* Name		testScroll - Analyze mouse event and return action ( if any )
*
* Synopsis	WINRETURN testScroll(WINDESC *win, INPUTEVENT *event, int max, int current )
*
*
* Parameters
*	WINDESC *win;					Pointer to Scrollbar window
*	INPUTEVENT *event;				What mouse event to analyze
*	int max;						Max number of items to scroll
*	int current;					Where we are right now
*
* Description
*		Return a menu action based on this scroll bar.	If the mouse is
*	out of range, return WIN_NOOP.	Actions supported are:
*		Click on arrow - 1 line in that direction
*		Click between arrow and current pos - Page in that direction
*		Double click on arrow gotos top or bottom
*
* Returns	WIN code for the correct action
*
* Version	1.0
*/
WINRETURN testScroll(		/*	Translate a mouse action into a window movement */
	WINDESC *win,			/* Window that will get the action */
	INPUTEVENT *event,		/*	What mouse event occured */
	int max,				/*	Max number of items */
	int *current )			/*	Where we are right now */
{
	int mousePos;
	enum { NOWAY, LEFTRIGHT, UPDOWN } direction;
	int cursorPos;
	int length;
	int oldPos = *current;
	int clipDrag = event->click == MOU_LDRAG;
	int moveMouse = FALSE;
	static int lastDrag = NOWAY;

	direction = win->nrows == 1 ? LEFTRIGHT : UPDOWN;

#ifdef CURTDBG
	fprintf( stdaux, "\r\nEvent %d (%d,%d) Dir %d Last %d",
			event->click,event->x,event->y, direction, lastDrag );
#endif

	if( clipDrag && direction != lastDrag )
		return WIN_NOOP;

	/*	If the cursor outside the single dimension, don't worry, it can't be ours*/
	if( direction == LEFTRIGHT ) {
		mousePos = event->x - win->col; 	/*	How far from top was click */
		length = win->ncols;
		if( win->row != event->y ) {
			if( !clipDrag ) {
				return WIN_NOOP;					/*	Not in same column */
			}
			event->y = win->row;
			moveMouse = TRUE;
		}
		if( clipDrag ) {
			if( mousePos < 2 ) {
				mousePos = 2;
				event->x = win->col+2;
				moveMouse = TRUE;
			} else if ( mousePos > length-3 ) {
				mousePos = length - 3;
				event->x = win->col + mousePos;
				moveMouse = TRUE;
			}
		}
	} else {
		mousePos = event->y - win->row;
		length = win->nrows;
		if( win->col != event->x ) {
			if( !clipDrag ) {
				return WIN_NOOP;					/*	Not in same column */
			}
			event->x = win->col;
			moveMouse = TRUE;
		}
		if( clipDrag ) {
			if( mousePos < 2 ) {
				mousePos = 2;
				event->y = win->row+2;
				moveMouse = TRUE;
			} else if ( mousePos > length-3 ) {
				mousePos = length - 3;
				event->y = win->row + mousePos;
				moveMouse = TRUE;
			}
		}
	}

#ifdef CURTDBG
	fprintf( stdaux, "  moveMouse %d MousePos %d",moveMouse, mousePos);
#endif

	if( moveMouse ) {
#ifdef CURTDBG
		fprintf( stdaux," to (%d,%d)",event->x,event->y);
#endif
		set_mouse_pos( event->x, event->y );
	}

	/*	Event above scroll bar */
	if( mousePos < 0 )
		return WIN_NOOP;				/*	Above top of scroll bar */
	if( mousePos >= length	)
		return WIN_NOOP;					/*	Too far down */

#ifdef CURTDBG
	fprintf( stdaux,
		"\n\revent:%3d cur:%3d max:%3d MP:%3d len:%3d",
		  event->click,*current,   max,    mousePos,	length );
#endif

	switch( event->click ) {
	case MOU_LDRAG:
#ifdef CURTDBG
		fprintf( stdaux, "   Drag" );
#endif
		if (length>5) {
			*current = ((int) ((long)(mousePos-2) * max) +
					(length-6)) / (length-5);
		} /* Scroll bar is big enough to drag on */
#ifdef CURTDBG
		mousePos = (int)((((long)*current * (length-5)))/max) + 2;
		fprintf( stdaux," - New:%3d MP:%3d",*current, mousePos);
#endif
		return WIN_MOVETO;
	case MOU_LSINGLE:
	case MOU_LDOUBLE:
		lastDrag = direction;
		if( mousePos == 0 )
			return event->click == MOU_LDOUBLE ? WIN_TOP : WIN_PGUP;
		if( mousePos == 1 )
			return WIN_UP;
		if( mousePos == length -1)
			return event->click == MOU_LDOUBLE ? WIN_BOTTOM : WIN_PGDN;
		if( mousePos == length - 2 )
			return WIN_DOWN;

		cursorPos = (int)((((long)oldPos * (length-5)))/max) + 2;

		if( cursorPos > mousePos )
			return WIN_PGUP;			/*	Between top arrow and slide bar */
		if( cursorPos < mousePos )
			return WIN_PGDN;			/*	Between bottom arrow and slide bar */

		if( cursorPos == 2
			&& cursorPos == mousePos
			&& oldPos > 0 )
			return WIN_PGUP;			/*	Too close to edge to tell but not there yet */
		if( cursorPos == length-4
			&& cursorPos == mousePos
			&& oldPos < max )
			return WIN_PGDN;
		if( cursorPos == mousePos )	/*	click on thumbnail - Do nothing */
			return WIN_OK;
		break;
	case MOU_LSINGLEUP:
		lastDrag = NOWAY;
		return WIN_OK;
	}
	lastDrag = NOWAY;
	return WIN_NOOP;
}

/**
*
* Name		paintScrollBar - Dump a scroll bar out as appropriate
*
* Synopsis	void paintScrollBar(PTEXTWIN pText, int max, int current )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window ( Screen relative )
*	char attr;					Attribute of base window
*	int max;					Value for far right position
*	int current;				Where we are right now
*
* Description
*	paint the scroll bar based on where we are now.  This includes
*	Arrows are shown as approp for the size;
*
* Returns	WIN code for the correct action
*
* Version	1.0
*/
void paintScrollBar(
	WINDESC *win,
	char attr,
	int max,
	int current )
{
	char *carrows;
	char *arrows;
	WINDESC temp = *win;
	WINDESC fill = temp;
	POINT currentPos;
	char revAtt = REVATT(attr);

	if( max <= 0 )
		return;

	if( current > max )
		current = max;

	/*	Make it the right color first */
	wput_sa( win, revAtt );

	temp.nrows = temp.ncols = 1;
	if( win->nrows > 1 ) {
		/*	Scroll for vertical */
		carrows = cupCDown;
		arrows = upDown;
		fill.row += 2;
		fill.nrows -= 4;
		wput_c( &temp, carrows++ );
		temp.row++;
		wput_c( &temp, arrows++ );
		temp.row += fill.nrows + 1;
		wput_c( &temp, arrows );
		temp.row++;
		wput_c( &temp, carrows );
		currentPos.row = (int)( (long)(win->nrows-5) * (long)current / max) + win->row + 2;
		currentPos.col = win->col;
	} else {
		/*	horizontal */
		carrows = cleftCRight;
		arrows = leftRight;
		fill.col += 2;
		fill.ncols -= 4;
		wput_c( &temp, carrows++ );
		temp.col++;
		wput_c( &temp, arrows++ );
		temp.col += fill.ncols + 1;
		wput_c( &temp, arrows );
		temp.col++;
		wput_c( &temp, carrows );

		currentPos.col = (int)((long)(win->ncols-5) * (long)current / max) + win->col + 2;
		currentPos.row = win->row;
	}

	wput_sc( &fill, filler );
	temp.row = currentPos.row;
	temp.col = currentPos.col;
	wput_a( &temp, &attr );
}
