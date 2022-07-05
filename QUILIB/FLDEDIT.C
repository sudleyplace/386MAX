/*' $Header:   P:/PVCS/MAX/QUILIB/FLDEDIT.C_V   1.0   05 Sep 1995 17:02:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * FLDEDIT.C								      *
 *									      *
 * Functions to manage edit fields					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <string.h>
#include <memory.h>

/*	Program Includes */
#include "commdef.h"
#include "fldedit.h"
#include "libtext.h"
#include "libcolor.h"
#include "mouse.h"
#include "qwindows.h"
#include "screen.h"
#include "ui.h"
#include "windowfn.h"

/*	Definitions for this Module */
void killBlock( PFLDITEM pItem, int cut );
void putBlock( PFLDITEM pItem );

#define MAXCUT 80
char cutBlock[MAXCUT];
int cutSize = 0;

/*	Program Code */
/**
*
* Name		showFldEdit - Put edit field up on screen
*
* Synopsis	FLDRETURN showFldEdit( PFLDITEM pItem, WINDESC *win, char *text,
*							  int maxLen, int shadow, int remember );
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*		WINDESC *win,		Window definition to use
*		char *text,		Scratch buffer to fill in - Must be maxlen long
*		int maxLen,		Maximium number of chars to support
*		int shadow,		Should this box be shadowed
*		int remember		Remember what we stepped on when we painted the box
*
*
* Description
*		This routine does all homework to show an edit field in a window.
*	The shadow will fall outside the window.  The text can be longer than
*	what will show in the window.  First cut will support only a 1 line
*	window.  I.E  No cursor up and down
*
* Returns	FLD_OK			Routine worked - Everything on screen
*			FLD_NOROOM		Allocs failed
*
* Version	1.0
*/
FLDRETURN showFldEdit(		/*	Put edit field up on screen */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create			   */
	WINDESC *win,			/*	Window definition to use						   */
	KEYCODE trigger,		/*	What key activates this  edit window */
	char *text,			/*	Scratch buffer to fill in - Must be maxlen long    */
	int maxLen,			/*	Maximium number of chars to support			   */
	char attr,				/*	Attribute to use for field edit window */
	SHADOWTYPE shadow,			/*	Should this box be shadowed					   */
	int remember )			/*	Remember what we stepped on when we painted the box*/
{
	memset( pItem, 0, sizeof( FLDITEM ));

	if( remember ) {
		pItem->behind = win_save( win, shadow );
		if( !pItem->behind )
			return FLD_NOROOM;
	}

	wput_sca( win, VIDWORD( attr, ' ' ));
	if( shadow )
		halfShadow( win );

	pItem->win = *win;

	if (ScreenType == SCREEN_MONO && pItem->win.ncols > 2) {
		WINDESC temp = *win;
		temp.ncols = 1;
		wput_c( &temp, ButtonStart );
		temp.col = win->col+win->ncols - 1;
		wput_c( &temp, ButtonStop );
		pItem->win.col++;
		pItem->win.ncols -=2;
	}

	pItem->trigger = trigger;
	pItem->attr = attr;
	pItem->maxLen = maxLen;
	pItem->text = text;
	pItem->anchor.col = strlen( text );

	/*	Now tweak the window so that the text stuff works transparently */
	if (maxLen > 1) {
		pItem->win.col++;
		pItem->win.ncols--;
	}

	showFldText( pItem, FALSE, FALSE );

	return FLD_OK;
}


/**
*
* Name		killFldEdit - Wipe a edit field off the face of the earth
*
* Synopsis	FLDRETURN killFldEdit( PFLDITEM pItem )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*
* Description
*		Kill a field edit box - Release all allocated memory.  This
*	does not include the text buffer area.
*
* Returns	FLD_OK			Routine worked - Everything on screen
*
* Version	1.0
*/
FLDRETURN killFldEdit(		/*	Wipe a field edit off the screen */
	PFLDITEM pItem )		/*	Pointer to the edit window to create  */
{
	if( pItem->behind )
		win_restore( pItem->behind, TRUE );
	return FLD_OK;
}

/**
*
* Name		hideFldText - Erase the screen for a field edit window
*
* Synopsis	void hideFldText( PFLDITEM pItem )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*
* Description
*		Blank out a fdl item from the screen
*
* Returns	No return
*
* Version	1.0
*/
void hideFldText( PFLDITEM pItem )
{
	wput_sca( &pItem->win, VIDWORD( pItem->attr, ' '));
}



/**
*
* Name		showFldText - Display text for a field edit window
*
* Synopsis	void showFldText( PFLDITEM pItem )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*
* Description
*		show the text for a field edit box.  SHow the text part first
*	then smear from there to the end of the window.  Don't do the smear
*	if the text >= window length ( Very possible )
*
* Returns	No return
*
* Version	1.0
*/
void showFldText(			/*	Show the text for this item */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create  */
	int hiLite,			/*	Show this item bright or dim */
	int block )			/*	Show the select block */
{
	char *pStart = pItem->text + pItem->start.col;
	char attr;
	int length = strlen( pStart );
	WINDESC workWin = pItem->win;

	if( hiLite ) {
	    if (ScreenType == SCREEN_MONO) attr = EditInvColor;
	    else attr = (char)(FG_WHITE | BACKGROUND( pItem->attr ));
	} /* Field is highlighted */
	else
		attr = pItem->attr;

	/*	Guarantee cursor in the correct shape */
	set_cursor( pItem->cSize == FLD_INSERT ? thin_cursor() : fat_cursor() );

	/*	If no length then just blank the window and return */
	if( !length ) {
		wput_sca( &workWin, VIDWORD( attr, ' '));
		return;
	}
	if( length < workWin.ncols )
		workWin.ncols = length;

	wput_sa( &workWin, attr );
	wput_c( &workWin, pStart );

	if( pItem->win.ncols > length ) {
		workWin.col += length;
		workWin.ncols = pItem->win.ncols - length;
		wput_sa( &workWin, attr );
		wput_sc( &workWin, ' ' );
	}

	if( block && pItem->anchor.col != -1
		&& (pItem->cursor.row != pItem->anchor.row
		|| pItem->cursor.col != pItem->anchor.col )) {
		/*
		*	Half to draw the block selection as a reversed attr of
		*	what's there.  The block streches from Anchor to cursor
		*/
		int start, end;

		if( pItem->anchor.col < pItem->cursor.col ) {
			start = pItem->anchor.col;
			end = pItem->cursor.col;
		} else {
			start = pItem->cursor.col;
			end = pItem->anchor.col;
		}

		workWin.col = start - pItem->start.col;
		if( workWin.col < 0 )
			workWin.col = 0;
		workWin.ncols = end - max(start, pItem->start.col);

		if( workWin.col + workWin.ncols > pItem->win.ncols )
			workWin.ncols = pItem->win.ncols - workWin.col;

		workWin.row = pItem->win.row;
		workWin.col += pItem->win.col;
		workWin.nrows = 1;

		wput_sa( &workWin, EditInvColor );
	}
}

/**
*
* Name		sendFldEditClick - send an event to a field item
*
* Synopsis	FLDRETURN sendFldEditClick( PFLDITEM pItem, INPUTEVENT *event )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*		INPUTEVENT *event;		Input event to deal with
*
* Description
*		Process a Clickboard or mouse event sent to us from our owner
*
* Returns	FLD_OK			Routine worked - Everything on screen
*			FLD_NOOP		Not related to this edit window
*
* Version	1.0
*/
FLDRETURN sendFldEditClick(		/*	Process a mouse message */
	PFLDITEM pItem, 			/*	Pointer to the edit window to create  */
	INPUTEVENT *event)			/*	Input event to deal with */
{
	/*	Look at the mouse event and make sure it is inside us */
	POINT lrPoint;
	lrPoint.row = pItem->win.row + pItem->win.nrows - 1;
	lrPoint.col = pItem->win.col + pItem->win.ncols - 1;

	if( event->x >= pItem->win.col
		&& event->x <= lrPoint.col
		&& event->y >= pItem->win.row
		&& event->y <= lrPoint.row ) {

		switch( event->click ) {
		case MOU_LSINGLE:
			/*	Assume we will get a KEY_TAB to activate us */
			pItem->cursor.row = event->y - pItem->win.row + pItem->start.row;
			pItem->cursor.col = event->x - pItem->win.col + pItem->start.col;
			pItem->anchor = pItem->cursor;
			move_cursor( event->y, event->x );

			break;
		case MOU_LDRAG:
			pItem->cursor.row = event->y - pItem->win.row + pItem->start.row;
			pItem->cursor.col = event->x - pItem->win.col + pItem->start.col;
			move_cursor( event->y, event->x );
			showFldText( pItem, TRUE, TRUE );
			break;
		}
		return FLD_OK;
	}
	return FLD_NOOP;
}

/**
*
* Name		sendFldEditKey - send an event to a field item
*
* Synopsis	FLDRETURN sendFldEditKey( PFLDITEM pItem, KEYCODE key )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*		KEYCODE key;		Input event to deal with
*
* Description
*		Process a keyboard or mouse event sent to us from our owner
*
* Returns	FLD_OK			Routine worked - Everything on screen
*			FLD_FOCUS		Response to tab key
*			FLD_WIERD		Something impossible happened
*
* Version	1.0
*/
FLDRETURN sendFldEditKey(		/*	Wipe a field edit off the screen */
	PFLDITEM pItem, 		/*	Pointer to the edit window to create  */
	KEYCODE key,			/*	Input event to deal with */
	KEYFLAG flag )			/*	State of the keyboard at keypress */
{
	int length = strlen( pItem->text );
	int shift = flag & (KEYFLAG_RSHFT| KEYFLAG_LSHFT);
	int showField = FALSE;

	if( key == pItem->trigger )
		key = KEY_TAB;


	switch( key ) {
	case KEY_TAB:
		showFldText( pItem, TRUE, TRUE );
		set_cursor( pItem->cSize == FLD_INSERT ? thin_cursor() : fat_cursor() );
		move_cursor( pItem->win.row + pItem->cursor.row,
					 pItem->win.col + pItem->cursor.col );
		show_cursor();
		return FLD_FOCUS;
	case KEY_STAB:
		hide_cursor();
		showFldText( pItem, FALSE, FALSE );
		return FLD_OK;
	case KEY_HOME:
		if( shift ) {
			if( pItem->anchor.col == -1 )
				pItem->anchor = pItem->cursor;
		} else if( pItem->anchor.col != -1) {
			pItem->anchor.row = pItem->anchor.col = -1;
		}

		pItem->cursor.row = pItem->cursor.col = 0;
		pItem->start.row = pItem->start.col = 0;

		move_cursor( pItem->win.row + pItem->cursor.row,
					 pItem->win.col + pItem->cursor.col );
		showField = TRUE;
		break;
	case KEY_END:
		if( shift ) {
			if( pItem->anchor.col == -1 )
				pItem->anchor = pItem->cursor;
		} else if( pItem->anchor.col != -1) {
			pItem->anchor.row = pItem->anchor.col = -1;
		}
		pItem->cursor.row = 0;
		pItem->cursor.col = length;
		pItem->start.row = 0;
		pItem->start.col =
				pItem->cursor.col > pItem->win.ncols
				? pItem->cursor.col - pItem->win.ncols
				: 0;
		showField = TRUE;
		break;
	case KEY_LEFT:
		if( shift ) {
			if( pItem->anchor.col == -1 )
				pItem->anchor = pItem->cursor;
			showField = TRUE;
		} else if( pItem->anchor.col != -1 ) {
			pItem->anchor.row = pItem->anchor.col = -1;
			showField = TRUE;
		}

		if( pItem->cursor.col > 0 ) {
			pItem->cursor.col--;
			if( pItem->cursor.col < pItem->start.col ) {
				pItem->start.col = pItem->cursor.col;
				showField = TRUE;
			}
		}
		break;
	case KEY_RIGHT:
		if( shift ) {
			if( pItem->anchor.col == -1 )
				pItem->anchor = pItem->cursor;
			showField = TRUE;
		} else if( pItem->anchor.col != -1 ) {
			pItem->anchor.row = pItem->anchor.col = -1;
			showField = TRUE;
		}

		if( pItem->cursor.col < length ) {
			pItem->cursor.col++;
			if( pItem->cursor.col >= pItem->start.col + pItem->win.ncols ) {
				pItem->start.col++;
				showField = TRUE;
			}
		}
		break;
	case KEY_INS:
		if( shift ) {
			putBlock( pItem );
			showField = TRUE;
			break;
		}
		else {
			pItem->cSize = pItem->cSize == FLD_INSERT ? FLD_OVERWRITE : FLD_INSERT;
			set_cursor( pItem->cSize == FLD_INSERT ? thin_cursor() : fat_cursor() );
		}
		return FLD_OK;
	case KEY_CINS:
		killBlock( pItem, FALSE );
		return FLD_OK;
	case KEY_DEL:
		{
			if( pItem->anchor.col != -1 ) {
				killBlock( pItem, TRUE );
				pItem->anchor.row = pItem->anchor.col = -1;
			} else if ((WORD) pItem->cursor.col < strlen(pItem->text))
				strcpy( pItem->text+pItem->cursor.col,
						pItem->text+pItem->cursor.col+1);
			showField = TRUE;
			break;
		}
	case KEY_BKSP:
		{
			if( pItem->anchor.col != -1 ) {
				killBlock( pItem, TRUE );
				pItem->anchor.row = pItem->anchor.col = -1;
			} else if( pItem->cursor.col == 0 ) {
				beep();
				break;
			} else {
				pItem->cursor.col--;
				if ((WORD) pItem->cursor.col < strlen (pItem->text))
				    strcpy( pItem->text+pItem->cursor.col,
						pItem->text+pItem->cursor.col+1);
			}

			if( pItem->cursor.col < pItem->start.col )
				pItem->start.col = pItem->cursor.col;
			showField = TRUE;
			break;
		}
	case KEY_ALTBKSP:
		break;
	default:
		if( NORMALKEY( key ) ) {
			char *current;
			showField = TRUE;
			if( pItem->anchor.col != -1) {
				killBlock( pItem, TRUE );
				length = strlen (pItem->text);
			}

			if( pItem->cursor.col > length )
				pItem->cursor.col = length;
			current = pItem->text + pItem->cursor.col;
			if ( pItem->maxLen == 1) {
				/* One char edit is a special case */
				*current = (char)key;
			}
			else if( pItem->cSize == FLD_INSERT ) {
				char *end;
				if( length >= pItem->maxLen) {
					beep();
					return FLD_NOROOM;
				}
				/*	Bump things down 1 */
				end = pItem->text + length;
				*(end+1) = '\0';
				for( ; end >= current; end-- )
					*(end+1) = *end;
				/* We know there is room */
				*current = (char)key;
				pItem->cursor.col++;
				if( pItem->cursor.col >= pItem->start.col + pItem->win.ncols )
					pItem->start.col++;
			} else {
				/*
				*	If we are about to walk over the null then makesure the
				*	next one is null
				*/
				if( !*current )
					*(current+1)='\0';
				*current = (char)key;
				if( pItem->cursor.col < pItem->maxLen ) {
					pItem->cursor.col++;
					if( pItem->cursor.col >= pItem->start.col + pItem->win.ncols )
						pItem->start.col++;
				} else {
					beep();
				}
			}
			break;
		}
		return FLD_WIERD;
	}
	/*	Update the screen */
	if( showField )
		showFldText( pItem, TRUE, TRUE );
	move_cursor( pItem->win.row + pItem->cursor.row - pItem->start.row,
				 pItem->win.col + pItem->cursor.col - pItem->start.col);
	return FLD_OK;
}

/**
*
* Name		killBlock - Kill the block between cursor and anchor
*
* Synopsis	void killBlock( PFLDITEM pItem )
*
* Parameters
*		PFLDITEM pItem, 	Pointer to the edit window to create
*
* Description
*		Kill the highlighted block
*
* Returns	none
*
* Version	1.0
*/
void killBlock( 			/*	Kill the area from anchor to cursor */
	PFLDITEM pItem, 	/*	Field to kill */
	int cut )			/*	Cut or copy text */
{
	int start;
	int stop;

	if( pItem->anchor.col != -1 ) {

		if( pItem->anchor.col < pItem->cursor.col ) {
			start = pItem->anchor.col;
			stop = pItem->cursor.col;
		} else {
			start = pItem->cursor.col;
			stop = pItem->anchor.col;
		}

		stop = min (strlen (pItem->text), (WORD) stop);
		cutSize = stop - start;
		if( cutSize > 0 ) {
			memcpy( cutBlock, pItem->text+start, cutSize );

			if( cut ) {
				strcpy( pItem->text+start, pItem->text+stop);
				pItem->cursor.col = start;
				pItem->anchor.row = pItem->anchor.col = -1;
			}
			return;
		}
	}

	cutSize = 0;
	cutBlock[0] = '\0';
	pItem->anchor.row = pItem->anchor.col = -1;
	return;
}

void putBlock(				/*	Add the cut block back into the string */
	PFLDITEM pItem )
{
	int len = strlen( pItem->text );
	int maxLen = pItem->maxLen;

	int maxCut = maxLen - len;
	if( maxCut > cutSize )
		maxCut = cutSize;

	if( maxCut > 0	) {
		memmove( pItem->text+pItem->cursor.col+maxCut,
			 pItem->text+pItem->cursor.col,
			 len - pItem->cursor.col);
		memmove( pItem->text+pItem->cursor.col, cutBlock, maxCut );
		*(pItem->text+len+maxCut) = '\0';
	}
}
