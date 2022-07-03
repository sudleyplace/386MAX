/*' $Header:   P:/PVCS/MAX/QUILIB/MENU.C_V   1.0   05 Sep 1995 17:02:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MENU.C								      *
 *									      *
 * Functions to manage menus						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>
#include <stdlib.h>

/*	Program Includes */
#include "constant.h"
#include "input.h"
#include "libcolor.h"
#include "libtext.h"
#include "menu.h"
#include "qprint.h"
#include "screen.h"
#include "ui.h"
#include "video.h"
#include "windowfn.h"


/*	Definitions for this Module */
#define CALLBACKTIME 200L

int menuClick(				/*	Test the menu for a mouse hit */
	PMENU pMenu,			/*	What menu to test */
	INPUTEVENT *event,		/*	What event to test */
	int *newItem ); 		/*	What thing was chosen */

int menuKey(
	PMENU pMenu,			/*	Menu to show on the screen - Assumed Visible */
	KEYCODE key,			/*	What key was pressed */
	int *item );			/*	What thing was chosen */

int menuNextActive(		/*	Get the next viable menu item */
	PMENU pMenu,			/*	Menu to look at */
	int start );			/*	Which item are we starting on */

int menuPrevActive(			/*	Get the prev viable menu item */
	PMENU pMenu,			/*	Menu to look at */
	int start );			/*	Which item are we starting on */

/*	Program Code */
/*
* Name		showMenu
*
* Synopsis	int showMenu( PMENUINFO pMenu, MENUSTATE state )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		MENUSTATE state;		What state to show this item as
*
* Description
*		Paint the menu on the screen.  Hilight the current
*	item if indicated.	If there is no saved image, save the behind
*	area.  Put up a shadow if a vertical menu.	No shadow if horizontal.
*
* Returns	MENU_OK if things work
*			MENU_NOMEMORY if not able to save background
*
* Version	1.0
*/
int showMenu(				/*	Show this menu on the screen */
	PMENU pMenu,			/*	Menu to show on the screen */
	MENUSTATE state )		/*	How to show the current item */
{
	int counter;
	WINDESC workWin;
	int stop;

	/* Smear in the background */
	if ( !pMenu->info.behind )
		pMenu->info.behind = win_save( &pMenu->info.win,
					(pMenu->info.type == MENU_BAR ? SHADOW_NONE : SHADOW_DOUBLE ));
	if ( !pMenu->info.behind )
		return MENU_NOMEMORY;

	wput_sca( &pMenu->info.win, VIDWORD(pMenu->info.backgroundAttr, ' '));

	workWin.nrows = 1;
	switch ( pMenu->info.type ) {
	case MENU_BAR:
		halfShadow( &pMenu->info.win );
		break;
	case MENU_VERTICAL:
		shadowWindow( &pMenu->info.win );
		/*	put in the around box */
		box( &pMenu->info.win, BOX_SINGLE, NULL, NULL, pMenu->info.backgroundAttr );
		workWin.col = pMenu->info.win.col + 1;	/*	Don't forget the outer line */
		workWin.ncols = pMenu->info.win.ncols - 2;
		break;
	};


	stop = pMenu->info.type == MENU_BAR
			? pMenu->info.nItems
			: pMenu->info.topItem + pMenu->info.win.nrows - 2;
	if( stop > pMenu->info.nItems )
		stop = pMenu->info.nItems;

	for( counter = pMenu->info.topItem; counter < stop; counter++ )
		showMenuItem( pMenu, counter,
				state == MENU_HIGHLIGHTED && (counter!=pMenu->info.active)
					? MENU_VISIBLE			/*	State == highligthed and not the current item */
					: state );

	pMenu->info.visible = TRUE;
	return MENU_OK;
}


/*
* Name		showMenuItem
*
* Synopsis	void showMenuItem( PMENUINFO pMenu, int item, MENUSTATE state )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		int item;				which item in the menu to hilight
*		MENUSTATE state;			Should we hilite the current item
*
* Description
*		Paint the item in normal or reversed attr color as appropriate.
*
* Returns	Always works
*
* Version	1.0
*/
void showMenuItem(					/*	Show an individual menu item */
	PMENU pMenu,			/*	Menu to show on the screen */
	int item,				/*	Which item to show - ( 0 based ) */
	MENUSTATE state )			/*	Should we hilite the current item */
{
	PMENUITEM pItem = pMenu->items + item;

	char attr = 0;

	WINDESC workWin;
	int winWidth = 1;

	workWin.nrows = 1;

	/*	Set the state flag */
	pItem->state.highlighted = FALSE;

	/*	Make a dark background a light foreground by adding FG_BRIGHT */
	switch( state ) {
	case MENU_DISABLED:
		attr = (char)MenuDisableColor;
		break;
	case MENU_VISIBLE:
/***		if (ScreenType == SCREEN_MONO)
 ***			attr = FG_BLACK | BG_GRAY;
 ***		else
 ***/
			attr = pItem->attr;
		break;
	case MENU_HIGHLIGHTED:
		attr = (char)(REVATT(pItem->attr));
		pItem->state.highlighted = TRUE;
		break;
	}

	/*	Set up the windesc - Then let common code take over */
	switch ( pMenu->info.type ) {
	case MENU_BAR:
		workWin.row = pMenu->info.win.row + pItem->pos.row;
		workWin.col = pItem->pos.col;
		winWidth = pItem->textLen;
		break;
	case MENU_VERTICAL:
		workWin.row = pMenu->info.win.row
			 + pItem->pos.row
			 - (pMenu->items + pMenu->info.topItem)->pos.row + 1;	/*	Don't forget the outer line */

		if( workWin.row < pMenu->info.win.row+1 ||
			workWin.row > pMenu->info.win.row + pMenu->info.win.nrows - 2 )
			return; /*	This item is not visible */

		workWin.col = pMenu->info.win.col + pItem->pos.col;
		winWidth = pMenu->info.win.ncols - 4;	/*	Line and space on each side */
		break;
	};

	/*	Window definition for text now set */
	workWin.ncols = 1;
	wput_csa( &workWin, BLANKSTRING, attr );
	workWin.col++;
	workWin.ncols = winWidth;

	switch( pItem->type ) {
	case ITEM_SEPARATOR:
		wput_sca( &workWin, VIDWORD( attr, '\xc4' ));
		break;
	case ITEM_DISABLED:
		wput_csa( &workWin, pItem->text,
				(char)(BACKGROUND(attr) | MenuItemDisabled) );
		break;
	default:
		{
			char tempAttr = MenuItemTriggerColor;
			if (ScreenType != SCREEN_MONO) tempAttr |= (char) BACKGROUND(attr);
			if( state == MENU_HIGHLIGHTED ) {
				tempAttr |= FG_BRIGHT;		/*	The turn the bright bit on */
				attr |= FG_BRIGHT;			/*	Turn on bright foreground */
			}
			wput_csa( &workWin, pItem->text, attr );
			/*	A trigger pos < 0 means no highlight */
			if( pItem->triggerPos >= 0 && state != MENU_DISABLED ) {
				int oldCol = workWin.col;
				workWin.col += (pItem->triggerPos - 1);
				workWin.ncols = 1;
				wput_a( &workWin, &tempAttr );
				workWin.col = oldCol;
			}
			break;
		}
	}

	workWin.col += winWidth;
	workWin.ncols = 1;
	wput_csa( &workWin, BLANKSTRING, attr );

}


/*
* Name		hideMenu
*
* Synopsis	void hideMenu( PMENUINFO pMenu )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*
* Description
*		Clear the current menu by painting it's screen snapshot back
*	Release the snapshot - So we can update things for next time
*
* Returns	MENU_OK if things work
*
* Version	1.0
*/
void hideMenu(				/*	Show this menu on the screen */
	PMENU pMenu )			/*	Menu to show on the screen */
{
	PMENUITEM pItem;
	int counter;

	if( !pMenu->info.visible )
		return;

	/*	First traverse lower if required */
	for( pItem = pMenu->items, counter = 0;
		 pItem < pMenu->items + pMenu->info.nItems;
		 pItem ++, counter++ ) {
		if( pItem->lower )
			hideMenu( pItem->lower );
	}

	if( pMenu->info.behind ) {
		pMenu->info.behind = win_restore( pMenu->info.behind, TRUE );
	}
	pMenu->info.visible = FALSE;
}

/*
* Name		menuClick
*
* Synopsis	int menuClick( PMENUINFO pMenu, INPUTEVENT *event, int *item )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		INPUTEVENT *event;			What the user hit
*		int *item;				What the resulting item id is
*
* Description
*		User hit a mouse button,	Find out what to do about it
*
* Returns	MENU_NOOP if the key is a dead key
*			MENU_ABANDON if user hits escape or alt to toggle out
*			MENU_SELECT if double click on lower menu item
*			MENU_DIRECT if single click on item
&			item contains the ID of the item chosen
*
* Version	1.0
*/
int menuClick(				/*	Test the menu for a mouse hit */
	PMENU pMenu,			/*	What menu to test */
	INPUTEVENT *event,		/*	What event to test */
	int *newItem )			/*	What thing was chosen */
{
	int outer;
	PMENUITEM pItem;
	POINT menuStart;

	if( testButtonClick( event, FALSE ) )
		return MENU_BUTTON;

	pItem = pMenu->items;
	menuStart.row = pMenu->info.win.row;
	menuStart.col = pMenu->info.win.col;

	/* key now has the "Normal value for the key in it */
	for( outer = 0; outer < pMenu->info.nItems; outer++, pItem++ ) {
		POINT ulPoint, lrPoint;
		if( pItem->type == ITEM_ACTIVE ) {
			ulPoint.row = pMenu->info.win.row
				+ pItem->pos.row
				- (pMenu->items + pMenu->info.topItem)->pos.row;
			if( pMenu->info.type != MENU_BAR )
				ulPoint.row++;

			ulPoint.col = pMenu->info.win.col + pItem->pos.col;
			lrPoint.row = ulPoint.row;
			lrPoint.col = ulPoint.col +
				( pMenu->info.type == MENU_BAR ? pItem->textLen + 1 : pMenu->info.win.ncols - 3 );
			if( event->x >= ulPoint.col
				&& event->x <= lrPoint.col
				&& event->y >= ulPoint.row
				&& event->y <= lrPoint.row ) {
				*newItem = outer;
				switch( event->click ) {
				case MOU_LSINGLE:
					return MENU_CLICK;
				case MOU_LDOUBLE:
					return MENU_DOUBLE;
				case MOU_LDRAG:
					return MENU_DRAG;
				default:
					return MENU_NOOP;
				}
			}
		}
	}
	return MENU_NOOP;


}

/*
* Name		menuKey
*
* Synopsis	int menuKey( PMENUINFO pMenu, KEYCODE key, int *item )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		KEYCODE key;			What the user hit
*		int *item;				What the resulting item id is
*
* Description
*		User hit a key,  Find out what to do about it
*
* Returns	MENU_NOOP if the key is a dead key
*			MENU_ABANDON if user hits escape or alt to toggle out
&			item contains the ID of the item chosen
*
* Version	1.0
*/
int menuKey(
	PMENU pMenu,			/*	Menu to test against */
	KEYCODE key,			/*	What key was pressed */
	int *item )			/*	What thing was chosen */
{
	int retVal;
	if( SPECIALKEY( key ) ) {
		switch( key ) {
		case KEY_HOME:
			return MENU_TOP;
		case KEY_UP:
			return MENU_UP;
		case KEY_PGUP:
			return MENU_PAGEUP;
		case KEY_STAB:
		case KEY_LEFT:
			return MENU_LEFT;
		case KEY_RIGHT:
			return MENU_RIGHT;
		case KEY_END:
			return MENU_BOTTOM;
		case KEY_DOWN:
			return MENU_DOWN;
		case KEY_PGDN:
			return MENU_PAGEDOWN;
		}
	} else {
		switch( key ) {
		case KEY_TAB:
			return MENU_RIGHT;
		case KEY_ENTER:
			return MENU_DIRECT;
		}
	}

	/*	Now see if it's some special key that we recognize */
	retVal = testButton( key, FALSE );
	if( retVal && retVal != BUTTON_NOOP)
		return MENU_BUTTON;
	return testMenu( pMenu, key, item );

}


/*
* Name		testMenu
*
* Synopsis	int testMenu( PMENUINFO pMenu, KEYCODE key, int *item )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		KEYCODE key;			What the user hit
*		int *item;				What the resulting item id is
*
* Description
*		User hit a key,  Find out if it has a trigger key
*
* Returns	MENU_NOOP if the key is a dead key
*			MENU_DIRECT if the regular key letter had a match
&			item contains the ID of the item chosen
*
* Version	1.0
*/
int testMenu(
	PMENU pMenu,			/*	Menu to test against */
	KEYCODE key,			/*	What key was pressed */
	int *item )				/*	What thing was chosen */
{
	int outer, inner;
	PMENUITEM pItem = pMenu->items;

	/* key now has the "Normal value for the key in it */
	for( outer = 0; outer < pMenu->info.nItems; outer++, pItem++ ) {
		if( pItem->type == ITEM_ACTIVE ) {
			for( inner = 0; inner < MAXMENUTRIGGERS; inner++ ) {
				if( key == pItem->triggers[inner] ) {
					*item = outer;
					return MENU_DIRECT;
				}
			}
		}
	}
	return MENU_NOOP;
}

/*
* Name		askMenu
*
* Synopsis	int askMenu( PMENUINFO pMenu, PMENU parentMenu, int *request )
*
* Parameters
*		PMENU pMenu;			Pointer to menu structure
*		PMENU parentMenu;		Pointer to parent menu
*		int *request;			What the resulting request id is
*		int doRefresh ) 		Should we paint the window to start with
*
* Description
*		Wander around a menu showing things and menus as appropriate
*
* Returns	MENU_OK if things work
*			MENU_ABANDON if user hits escape or alt to toggle out
&			request contains the ID of the item chosen
*
* Version	1.0
*/
#pragma optimize ("leg",off)
int askMenu(				/*	Get a 2D menu pick */
	PMENU pMenu,			/*	Menu to deal with - Assumed Visible */
	PMENU parentMenu,		/*	Is there a parent menu? */
	int *request,			/*	What thing was chosen */
	int doRefresh ) 		/*	Should we paint the window to start with */
{
	PMENUITEM pItem;
	int counter;
	int doCallBack;
	int highlighted = FALSE;
	int lowerRequest = -1;
	int retVal;

	hide_cursor();
	/*
	*	First come in and cleanup any previous mess left behind
	*	like some other item hilighted
	*/
	for( pItem = pMenu->items, counter = 0;
		 pItem < pMenu->items + pMenu->info.nItems;
		 pItem ++, counter++ ) {
		if( pItem->state.highlighted ) {
			if( counter == pMenu->info.active )
				highlighted = TRUE;
			else {
				if( pItem->lower )
					hideMenu( pItem->lower );
				showMenuItem( pMenu, counter, MENU_VISIBLE);
			}
		}
	}

	if( !highlighted ) {
		showMenuItem( pMenu, pMenu->info.active, MENU_HIGHLIGHTED );
	}

	/*	Try and show a lower menu if there is one
	*	Show menu noops if already visible
	*/
	if( (pMenu->items+pMenu->info.active)->lower )
		showMenu( (pMenu->items+pMenu->info.active)->lower, MENU_HIGHLIGHTED );


	/*
	*	Now the correct item is highlighted and NO others are.
	*	A lower menu ( if it exists ) is not shown
	*/
	doCallBack = doRefresh;
	for(;;) {
		int newItem = pMenu->info.active;
		int newTop = pMenu->info.topItem;

		INPUTEVENT event;

		pItem = pMenu->items + pMenu->info.active;
		if( pItem->lower && pMenu->info.type == MENU_BAR ) {
			/*	Correct menu ASSUMED to be already on screen */
			retVal = askMenu( pItem->lower, pMenu, &lowerRequest, doRefresh );
			switch( retVal ) {
			case MENU_SELECT:
				*request = lowerRequest;
				break;
			case MENU_DIRECT:
			case MENU_BUTTON:
				*request = lowerRequest;
				goto done;
			case MENU_ALTDIRECT:
				newItem = lowerRequest;
				retVal = MENU_NOOP;		/*	Just let display logic do it */
			case MENU_LEFT:
			case MENU_RIGHT:
				doRefresh = TRUE;
				break;
			}
		} else {
			/*	SHow a quick help box if required */
			if( pMenu->items[newItem].quickHelpNumber != -1 )
				showQuickHelp( pMenu->items[newItem].quickHelpNumber );

			/*	Now set the f1 and f3 buttons as appropriate */
			disableButton( KEY_F1, pItem->helpNumber == -1 );
			disableButton( KEY_F2, pItem->printNumber == -1 );
			disableButton( KEY_F3, pItem->tutorNumber == -1 );
			/*	Get something from the keyboard or mouse */
			retVal = MENU_NOOP;
			do {
				KEYCODE charKey;
				long waitTime = (long)(doCallBack ? CALLBACKTIME : INPUT_WAIT);
				get_input(waitTime, &event);
				if( event.key ) {
					retVal = menuKey( pMenu, event.key, &newItem );
					if( parentMenu
						&& retVal == MENU_NOOP
						&& SPECIALKEY( event.key )
						&& ((charKey = translate_altKey( event.key )) != 0 )
						&& menuKey( parentMenu, charKey, request ) == MENU_DIRECT)
						retVal = MENU_ALTDIRECT;

				} else if( event.click ) {
					retVal = menuClick( pMenu, &event, &newItem );
					if( parentMenu && retVal == MENU_NOOP ) {
						int retVal1 = menuClick( parentMenu, &event, request );
						if( retVal1 == MENU_CLICK || retVal1 == MENU_DRAG )
							retVal = MENU_ALTDIRECT;
						else
							continue;		/*	Double is a noop in here */
					}

				} else if( doCallBack ) {
					doCallBack = FALSE;
					if( pMenu->info.callBack ) {
						WINDESC special;
						WINDESC workWin;
						WORD *newBehind;
						(*pMenu->info.callBack)( pItem->returnCode );
						/*
						*  This is SO cross circuited as to be dangerous
						*  But I can't think of a cleaner way.  We
						*  are going to spray our new screen into a partial
						*  of the behind snapshot.
						*/
						workWin = *((WINDESC *)pMenu->info.behind);
						workWin.row++;
						workWin.nrows--;

						/*	Real special dink for left edge */
						if( workWin.col < 2 ) {
							SETWINDOW( &special, DataWin.row, 0,
										pMenu->info.win.nrows-1, 1 );
							wput_sca( &special,
								VIDWORD( BackScreenColor, BACKCHAR ));	/*	Full space */
							special.col++;
							wput_sca( &special,
								VIDWORD( DataColor, ' ' ));     /*      Full space */

						}
						/*
						*	An even more special dink for the right side shadow
						*	of the data window - Gotta love these - Menu shadow is
						*	one too high so always paint upper right corner just outside
						*	the data window.....
						*/
						SETWINDOW( &special, DataWin.row, DataWin.col+DataWin.ncols,
										1, 2 );
						wput_sca( &special,
								VIDWORD( BackScreenColor, BACKCHAR ));	/*	Full space */


						newBehind = (WORD *)((WINDESC *)pMenu->info.behind + 1);
						newBehind = newBehind		/*	Will inc by 2*ncols */
								+ ((WINDESC *)pMenu->info.behind)->ncols;
						wget_ca(&workWin,newBehind);

						showMenu( pMenu, MENU_HIGHLIGHTED );

					}
				}
			} while ( retVal == MENU_NOOP );
		}

		/*	Move things around based on retVal - First pass at processing */
		switch( retVal ) {
		case MENU_RIGHT:
			if( parentMenu )
				break;
		case MENU_DOWN:
			newItem = menuNextActive( pMenu, newItem + 1 );
			if( newItem - pMenu->info.win.nrows+3 > pMenu->info.topItem )
				newTop = newItem - pMenu->info.win.nrows+3;
			else if( newItem < pMenu->info.topItem )
				newTop = newItem;
			break;
		case MENU_BOTTOM:
			newItem = menuPrevActive( pMenu, pMenu->info.nItems );
			newTop = pMenu->info.nItems - pMenu->info.win.nrows+2;
			break;
		case MENU_LEFT:
			if( parentMenu )
				break;
		case MENU_UP:
			newItem = menuPrevActive( pMenu, newItem - 1 );
			if( newItem - pMenu->info.win.nrows+3 > pMenu->info.topItem )
				newTop = newItem - pMenu->info.win.nrows+3;
			else if( newItem < pMenu->info.topItem )
				newTop = newItem;
			break;
		case MENU_TOP:
			newItem = menuNextActive( pMenu, 0 );
			newTop = 0;
			break;
		case MENU_PAGEUP:
			if( pMenu->info.type == MENU_VERTICAL ) {
				newItem = newItem - pMenu->info.win.nrows+2;
				newTop = newTop - pMenu->info.win.nrows+2;
				if( newTop < 0 )
					newTop = 0;
			} else
				newItem = -1;
			if( newItem < 0 ) {
				newItem = menuNextActive( pMenu, 0 );
				newTop = 0;
			} else {
				newItem = menuPrevActive( pMenu, newItem );
				if( newTop > newItem )
					newTop = newItem;
			}
			break;
		case MENU_PAGEDOWN:
			if( pMenu->info.type == MENU_VERTICAL ) {
				newItem = newItem + pMenu->info.win.nrows-2;
				newTop = newTop + pMenu->info.win.nrows - 2;
			} else
				newItem = pMenu->info.nItems + 1;
			if( newItem >= pMenu->info.nItems )
				newItem = menuPrevActive( pMenu, pMenu->info.nItems);
			else
				newItem = menuNextActive( pMenu, newItem );

			if( newTop + pMenu->info.win.nrows-2 > pMenu->info.nItems	)
				newTop = pMenu->info.nItems - pMenu->info.win.nrows+2;
			break;
		}

		/*	Make the new item highlighted */
		if( newItem != pMenu->info.active ) {
			if( pItem->lower )
				hideMenu( pItem->lower );
			showMenuItem( pMenu, pMenu->info.active, MENU_VISIBLE);
			doCallBack = TRUE;
			pItem = pMenu->items + newItem;
			pMenu->info.active = newItem;

			if( pMenu->info.type == MENU_VERTICAL &&
				pMenu->info.topItem != newTop ) {
				pMenu->info.topItem = newTop;
				showMenu( pMenu, MENU_HIGHLIGHTED );
			} else
				showMenuItem( pMenu, newItem, MENU_HIGHLIGHTED);

			if( pItem->lower )
				showMenu( pItem->lower, MENU_VISIBLE );
		} else if( retVal == MENU_CLICK )
			retVal = MENU_DIRECT;			/*	Single click on the selected it is a go */


		pItem = pMenu->items + newItem;

		switch( retVal ) {
		case MENU_RIGHT:
		case MENU_LEFT:
			if( parentMenu )
				goto done;
			break;
		case MENU_SELECT:
			*request = pItem->returnCode;
			break;
		case MENU_ALTDIRECT:
			goto done;
		case MENU_BUTTON:
			/*	Deal with the buttons we know about */
			switch( LastButton.key ) {
			case KEY_F1:
				pushButton( LastButton.number );
				showHelp( pItem->helpNumber, FALSE );
				continue;
			case KEY_F2:
				pushButton( LastButton.number );
				doPrint( NULL, pItem->printNumber, pItem->returnCode, pItem->helpNumber, FALSE );
				continue;
			case KEY_F3:
				pushButton( LastButton.number );
				showHelp( pItem->tutorNumber, FALSE );
				continue;
			}
			*request = pItem->returnCode;
			goto done;
		case MENU_DOUBLE:
			retVal = MENU_DIRECT;	/*	Fall into the direct logic */
		case MENU_DIRECT:
			*request = pItem->returnCode;
			/*	Force the buttons to reflect the current menu position */
			disableButton( KEY_F1, pItem->helpNumber == -1 );
			disableButton( KEY_F2, pItem->printNumber == -1 );
			disableButton( KEY_F3, pItem->tutorNumber == -1 );
			goto done;
		}
	}
done:
	/*	Done processing - Cleanup */
	return retVal;
}
#pragma optimize ("",on)

int menuNextActive(		/*	Get the next viable menu item */
	PMENU pMenu,			/*	Menu to look at */
	int start )			/*	Which item are we starting on */
{
	if( start >= pMenu->info.nItems )
		start = 0;
	for( ;
		(pMenu->items+start)->type != ITEM_ACTIVE;
		start++ ) {
		if( start >= pMenu->info.nItems )
			start = -1;
	}
	return start;
}

int menuPrevActive(		/*	Get the Prev viable menu item */
	PMENU pMenu,			/*	Menu to look at */
	int start )			/*	Which item are we starting on */
{
	if( start < 0 )
		start = pMenu->info.nItems - 1;
	for( ;
		(pMenu->items+start)->type != ITEM_ACTIVE;
		start-- ) {
		if( start < 0 )
			start = pMenu->info.nItems;
	}
	return start;
}
