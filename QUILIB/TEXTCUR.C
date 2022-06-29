/*' $Header:   P:/PVCS/MAX/QUILIB/TEXTCUR.C_V   1.0   05 Sep 1995 17:02:42   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * TEXTCUR.C								      *
 *									      *
 * Cursor display functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */

/*	Program Includes */
#include "qwindows.h"
#include "video.h"
#include "windowfn.h"


/*	Definitions for this Module */

/*	Program Code */
/**
*
* Name		vWin_get_cursor( PTEXTWIN pText )
*
* Synopsis	CURSOR vWin_get_cursor(PTEXTWIN pText)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Return the current shape of the cursor for this window
*
* Returns	The cursor shape
*
* Version	1.0
*/
CURSOR vWin_get_cursor( 	/*	Return the current cursor shape for this window */
	PTEXTWIN pText )		/*	Window to deal with */
{
	return ( pText->cShape );
}

/**
*
* Name		vWin_set_cursor
*
* Synopsis	CURSOR vWin_set_cursor(PTEXTWIN pText, CURSOR cShape)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	CURSOR cShape;				Shape to make the cursor
*
* Description
*		Force the current window to this shape - if cursor visible
*	force the screen to match
*
* Returns	The cursor shape
*
* Version	1.0
*/
CURSOR vWin_set_cursor( 	/*	Return the current cursor shape for this window */
	PTEXTWIN pText, 	/*	Window to deal with */
	CURSOR cShape ) 	/*	Shape to use for cursor now */
{
	CURSOR old = pText->cShape;
	if( pText->cursorVisible )
		set_cursor( cShape );

	return ( old );
}

/**
*
* Name		vWin_show_cursor( PTEXTWIN pText )
*
* Synopsis	void vWin_show_cursor(PTEXTWIN pText)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Show the current cursor for this window at the correct spot on
*	the screen - If the cursor goes out of the window - it disapears
*
* Returns	Nothing
*
* Version	1.0
*/
void  vWin_show_cursor( 	/*	Set the visible flag */
	PTEXTWIN pText )		/*	Window to deal with */
{
	pText->cursorVisible = TRUE;
	vWin_updateCursor( pText );
	return;
}

/**
*
* Name		vWin_hide_cursor( PTEXTWIN pText )
*
* Synopsis	void vWin_hide_cursor(PTEXTWIN pText)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		hide the current cursor for this window at the correct spot on
*	the screen - If the cursor goes out of the window - it disapears
*
* Returns	Nothing
*
* Version	1.0
*/
void  vWin_hide_cursor( 	/*	Set the visible flag */
	PTEXTWIN pText )		/*	Window to deal with */
{
	pText->cursorVisible = FALSE;
	vWin_updateCursor( pText );
	return;
}

/**
*
* Name		vWin_updateCursor( PTEXTWIN pText )
*
* Synopsis	void vWin_updateCursor(PTEXTWIN pText)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Based on where the cursor is and the cursor visible flag -
*	Show or hide the cursor in the correct shape
*
* Returns	Nothing
*
* Version	1.0
*/
void  vWin_updateCursor(	/*	Set the visible flag */
	PTEXTWIN pText )		/*	Window to deal with */
 {
	if( pText->cursorVisible ) {
		if(    pText->cursor.row >= pText->corner.row
			&& pText->cursor.col >= pText->corner.col
			&& pText->cursor.row <	pText->corner.row + pText->win.nrows
			&& pText->cursor.col <	pText->corner.col + pText->win.ncols	) {
			set_cursor( pText->cShape );
			move_cursor( pText->win.row + pText->cursor.row - pText->corner.row,
						 pText->win.col + pText->cursor.col - pText->corner.col );
			show_cursor();
			return;
		}
	}

	/*	Either hidden or off the visible screen */
	hide_cursor();

	return;
}
