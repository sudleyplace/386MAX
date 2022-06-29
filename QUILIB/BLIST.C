/*' $Header:   P:/PVCS/MAX/QUILIB/BLIST.C_V   1.0   05 Sep 1995 17:01:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BLIST.C								      *
 *									      *
 * Functions to manage button lists					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>

/*	Program Includes */

#include "button.h"
#include "libcolor.h"
#include "ui.h"
#include "windowfn.h"

/*	Definitions for this Module */
#define RADIOCHAR '\xf9'
#define CHECKCHAR '\xfb'

void turnBListOff(			/*	Turn off checks and highlight for a list */
	PBUTTONLIST pBList,	/*	List to work on */
	int ignore );			/*	The one to skip -  -1 to do all */

/*	Program Code */
/**
*
* Name		showBList
*
* Synopsis	BUTTONRETURN showBList( PBUTTONLIST pBList, int hiLite )
*
* Parameters
*		PBUTTONLIST pBList;		Button list info
*		int hilite;			Should we hilite the current item
*
* Description
*		Show the button list on the screen
*
* Returns	BUTTON_OK - All buttons shown.
*
* Version	1.0
*/
BUTTONRETURN showBList( 		/*	Dump a button list box out on the screen */
	PBUTTONLIST pBList,		/*	What button list to dump */
	int hiLite )				/*	Should we hilight the current item */
{
	int counter;

	/*	Assume that this window is NOT visible */

	wput_sca( &pBList->info.win, VIDWORD(pBList->info.backgroundAttr, ' '));
	halfShadow( &pBList->info.win );

	/*	Show only 1 highlighted thing if required */
	for( counter = 0; counter < pBList->info.nItems; counter++ ) {
		(pBList->items + counter)->state.highlighted =
					(counter == pBList->info.active && hiLite );
		showBLItem( pBList, counter );
	}
	return BUTTON_OK;
}

/**
*
* Name		showBLItem
*
* Synopsis	BUTTONRETURN showBLItem( PBUTTONLIST pBList, int item )
*
* Parameters
*		PBUTTONLIST pBList;		Button list info
*		int item;				Which item in the button list to show
*
* Description
*		Show a button list item on the screen - Hilight it if appropriate
*
* Returns	BUTTON_OK - All buttons shown.
*
* Version	1.0
*/
BUTTONRETURN showBLItem(		/*	Show a button list item on screen */
	PBUTTONLIST pBList,		/*	Button list to work with */
	int item )					/*	Which item to show */
{
	PBLITEM pItem = pBList->items + item;
	char attr;
	char tempAttr;
	char check = (char)(pBList->info.type == BTYPE_CHECK ? CHECKCHAR : RADIOCHAR);
	WINDESC workWin;

	if (ScreenType == SCREEN_MONO) {
		if( pItem->state.highlighted ) {
			attr = ButtonPushedColor;
			tempAttr = ButtonActiveColor;
		} else {
			attr = ButtonActiveColor;
			tempAttr = TriggerColor;
		}
	} else {
		attr = (char )(( pItem->state.highlighted ? FG_WHITE : FG_BLACK )
				| BACKGROUND( pBList->info.backgroundAttr ));
		tempAttr = (char)(BACKGROUND(attr) | FG_RED);
	}

	SETWINDOW( &workWin,
				pBList->info.win.row + pItem->pos.row,
				pBList->info.win.col + pItem->pos.col,
				1,
				pItem->textLen );

	/*	Force the check as appropriate */
	*(pItem->text+1 ) = (char)(pItem->state.checked ? check : (char)' ');

	/*	Show it - Lots of horsepower here - Assume has trigger pos */
	justifyString( &workWin, pItem->text,  pItem->triggerPos,
					JUSTIFY_LEFT, attr, tempAttr );

	return BUTTON_OK;
}


/**
*
* Name		testBLItem
*
* Synopsis	BUTTONRETURN testBLItem( PBUTTONLIST pBList, INPUTEVENT *event, int active )
*
* Parameters
*		PBUTTONLIST pBList;		Button list info
*		INPUTEVENT *event;		Input event to test for
*		int active;			Should we do the action
*
* Description
*		Test all the things in a blist to see if an inputevent causes
*	an action in this blist.  If yes and active - then show it and toggle
*	the state of the item.
*	In either case return that this blist would react.
*
* Returns	BUTTON_NOOP - This blist not concerned
*			BUTTON_THISLIST - This blist would/did use this key
*
* Version	1.0
*/
BUTTONRETURN testBLItem(	/*	test a button list item on screen */
	PBUTTONLIST pBList,		/*	Button list to work with */
	INPUTEVENT *event,		/*	Input event to test for */
	int active )			/*	Should we do the action */
{
	int counter;
	PBLITEM pItem = pBList->items;
	if( event->key ) {
		if( event->key == pBList->info.trigger )
			goto activeList;
	}

	for( counter = 0; counter < pBList->info.nItems; counter++, pItem++ ) {
		if( event->click ) {
			POINT ulPoint, lrPoint;
			ulPoint.row = pBList->info.win.row + pItem->pos.row;
			ulPoint.col = pBList->info.win.col + pItem->pos.col;
			lrPoint.row = ulPoint.row;
			lrPoint.col = ulPoint.col + pBList->info.win.ncols - 2 * pItem->pos.col;

			if( event->x >= ulPoint.col
				&& event->x <= lrPoint.col
				&& event->y >= ulPoint.row
				&& event->y <= lrPoint.row ) {
					goto activeButton;
			}
		} else {
			if( event->key == pItem->altTrigger ) {
				pBList->info.active = counter;
					goto activeButton;
			}
		}
	}
	return BUTTON_NOOP;

activeButton:
	if( active) {
		turnBListOff( pBList, counter );
		/*	Toggle the state of this item and show it */
		if( pBList->info.type == BTYPE_RADIO ) {
			(pBList->items+counter)->state.checked = TRUE;
		} else {
			(pBList->items+counter)->state.checked =
					!(pBList->items+counter)->state.checked;
		}

		(pBList->items+counter)->state.highlighted = TRUE;
		pBList->info.active = counter;
		showBLItem( pBList, counter );
	}

activeList:
	showBLItem( pBList, pBList->info.active );

	return BUTTON_THISLIST;
}

/**
*
* Name		turnBListOff
*
* Synopsis	void turnBListOff( PBUTTONLIST pBList, int ignore)
*
* Parameters
*		PBUTTONLIST pBList;		Button list info
*
* Description
*		Turn off checks and highlight as appropriate for button type
*	Ignore the button marked as ignore because we are about to do something
*	to it.	-1 to disable ignore
*
* Returns	None
*
* Version	1.0
*/
void turnBListOff(			/*	Turn off checks and highlight for a list */
	PBUTTONLIST pBList,	/*	List to work on */
	int ignore )			/*	The one to skip -  -1 to do all */
{
	int inner;
	PBLITEM pLast;
	/*
	*	See what type of button and set the check/button as appropriate
	*	pItem points at the current item and counter has it's number
	*/
	for( pLast = pBList->items, inner = 0;
		 inner < pBList->info.nItems;
		 pLast++, inner++) {
		int rePaint;

		if( inner == ignore )
			continue;

		rePaint = FALSE;
		if( pBList->info.type == BTYPE_RADIO && pLast->state.checked ) {
			pLast->state.checked = FALSE;
			rePaint = TRUE;
		}
		if( pLast->state.highlighted ) {
			pLast->state.highlighted = FALSE;
			rePaint = TRUE;
		}
		if( rePaint )
			showBLItem( pBList, inner );
	}
}

/**
*
* Name		sendBLItem
*
* Synopsis	BUTTONRETURN sendBLItem( PBUTTONLIST pBList, KEYCODE key )
*
* Parameters
*		PBUTTONLIST pBList;		Button list info
*		KEYCODE key;			Key to process
*
* Description
*		Process this keycode and change screen as required.  Assumes
*	that some will happen so it turns off the current item first.
*	Keys processed are:
*		KEY_UP
*		KEY_DOWN
*		KEY_HOME
*		KEY_END
*		KEY_SPACE
*		KEY_TAB 		Force this one Active
*		KEY_STAB		Deactivate this one
*
* Returns	No return
*
* Version	1.0
*/
void sendBLItem(			/*	Send a key down to process */
	PBUTTONLIST pBList,	/*	Button list to work with */
	KEYCODE key )			/*	What key to process */
{
	PBLITEM pItem = pBList->items + pBList->info.active;
	int toggle = FALSE;

	/*	Turn off the old item */
	if( pItem->state.highlighted && key != KEY_TAB) {
		pItem->state.highlighted = FALSE;
		showBLItem( pBList, pBList->info.active );
	}

	switch( key ) {
	case KEY_UP:
		if( pBList->info.active > 0 )
			pBList->info.active--;
		break;
	case KEY_DOWN:
		if( pBList->info.active < pBList->info.nItems - 1 )
			pBList->info.active++;
		break;
	case KEY_HOME:
		pBList->info.active = 0;
		break;
	case KEY_END:
		pBList->info.active = pBList->info.nItems - 1;
		break;
	case ' ':
		pItem = pBList->items + pBList->info.active;

		if( pBList->info.type == BTYPE_RADIO
			&& pItem->state.checked )
			break;			/*	Don't turn off the current one */

		turnBListOff( pBList, pBList->info.active);
		pItem->state.checked = !pItem->state.checked;
		break;
	case KEY_TAB:
		hide_cursor();
		pItem->state.highlighted = TRUE;
		break;
	case KEY_STAB:
		return; 		/*	Work already done above */
	default:
		{
			int counter;
			int inner;
			for( counter = 0, pItem = pBList->items;
				 counter < pBList->info.nItems;
				 counter++, pItem++	) {
				for( inner = 0; inner < MAXBLTRIGGERS; inner++ ) {
					if( key == pItem->triggers[inner] ) {
						pBList->info.active = counter;
						goto showButton;
					}
				}
			}
		}
	}
showButton:
	pItem = pBList->items + pBList->info.active;
	pItem->state.highlighted = TRUE;
	showBLItem( pBList, pBList->info.active );

}
