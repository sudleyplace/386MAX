/*' $Header:   P:/PVCS/MAX/INCLUDE/MENU.H_V   1.1   01 Feb 1996 10:23:32   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MENU.H								      *
 *									      *
 * This file contains all definitions that are related to MENUs 	      *
 *									      *
 ******************************************************************************/

#ifndef MENU_INCLUDED
#define MENU_INCLUDED

#ifndef QHELP_INCLUDED
#include <qhelp.h>
#endif

#ifndef SCREEN_INCLUDED
#include <screen.h>
#endif

#ifndef WINDOWFN_INCLUDED
#include <windowfn.h>
#endif

/*	Menu Errors and other return values*/
typedef enum {
	MENU_OK,				/* 0	Function worked - Success */
	MENU_ABANDON,			/* 1	Use hit ESCAPE or ALT to get out */
	MENU_NOROOM,			/* 2	No room in MENU structure */
	MENU_NOMEMORY,			/* 3	Out of memory - Alloc failed */
	MENU_HOTKEY,			/* 4	The key pressed is a hot key for this menu */
	MENU_WEIRD,				/* 5	Other wierd error */
	MENU_NOOP,				/* 6	From here down - returns from key processing */
	MENU_SELECT,			/* 7	User hit Enter, select letter, or double mouse */
	MENU_DIRECT,			/* 8	User made a single click mouse selection */
	MENU_ALTDIRECT, 		/* 9	User hit a letter key with Alt that had a match */
	MENU_CLICK,				/* a	Single Left Mouse click */
	MENU_DRAG,				/* b	Single Left Mouse Drag */
	MENU_DOUBLE,			/* c	Double left mouse click */
	MENU_BUTTON,			/* d	User hit a button */
	MENU_LEFT,				/* e	Move in some general direction */
	MENU_RIGHT,			/* f	*/
	MENU_UP,				/* 10	*/
	MENU_DOWN,				/* 11	*/
	MENU_PAGEUP,			/* 12	*/
	MENU_PAGEDOWN,			/* 13	*/
	MENU_TOP,				/* 14	*/
	MENU_BOTTOM			/* 15	*/
} MENURETURN;

typedef enum { MENU_NOTSHOWN, MENU_DISABLED,
			MENU_VISIBLE, MENU_HIGHLIGHTED } MENUSTATE;			/*	Is this menu visible */

typedef void (*MENUCALLBACK)(int);			/*	Menu callback function */

typedef struct {
	int nItems;							/*	How many items in this menu */
	enum { MENU_BAR, MENU_VERTICAL } type;	/*	What type of menu this is */
	WINDESC win;							/*	Definition of screen area for menu */
	int active;							/*	Which item is the current selection */
	int topItem;							/*	What is the top item visible on the screen */
	MENUSTATE visible;						/*	Is this menu visible */
	char backgroundAttr;					/*	Background attribute */
	void *behind;							/*	What was behind this menu */
	MENUCALLBACK callBack;					/*	Is there a routine to call when we land on this menu */
} MENUINFO;

typedef MENUINFO			*PMENUINFO;		/*	How to point at a MENUINFO */
typedef MENUINFO NEAR		*NPMENUINFO;
typedef MENUINFO FAR		*LPMENUINFO;

#define MAXMENUITEMTEXT 21
#define MAXMENUTRIGGERS 3
typedef struct {
	POINT pos;						/*	Where this is in the menu ( RELATIVE TO MENU TOP LEFT ) */
	int returnCode; 				/*	What to return when this item pushed */
	enum { ITEM_SEPARATOR, ITEM_INFO,
		  ITEM_ACTIVE, ITEM_DISABLED } type;	/*	What type of item */
	struct {
		int highlighted:1;			/*	Is this item highlighted */
		int visible:1;				/*	IS this item on the screen */
	} state;
	struct _menu *lower;					/*	Lower menu if there is one */
	int triggerPos; 				/*	Which pos to color trigger color (-1 for none) */
	int quickHelpNumber;				/*	What quick help to show for this item ( -1 for none ) */
	int helpNumber; 			/*	What help to show for this item ( -1 for none ) */
	int printNumber;			/*	What type of help to present */
	int tutorNumber;			/*	What tutorial to show for this item ( -1 for none ) */
	KEYCODE triggers[MAXMENUTRIGGERS];	/*	What pushes the button */
	int  textLen;					/*	How many characters in the text */
	char attr;						/*	Attribute for this item */
	char text[MAXMENUITEMTEXT];	/*	Text for the item */
} MENUITEM;

typedef MENUITEM			*PMENUITEM;		/*	How to point at a MENUITEM */
typedef MENUITEM NEAR		*NPMENUITEM;
typedef MENUITEM FAR		*LPMENUITEM;

typedef struct _menu {
	MENUINFO info;
	MENUITEM items[ 1 ];
} MENU;
typedef MENU			*PMENU; 	/*	How to point at a MENU */
typedef MENU NEAR		*NPMENU;	/*	Use casting to force everyone to it */
typedef MENU FAR		*LPMENU;	/*	Note there is 1 array item so arrays work and level 4 accepts */

int askMenu(				/*	Get a menu pick */
	PMENU pMenu,			/*	Menu to show on the screen - Assumed Visible */
	PMENU parentMenu,		/*	Pointer to a parent menu? */
	int *request,			/*	What thing was chosen */
	int doRefresh );		/*	Should we paint the window to start with */

void hideMenu(				/*	Show this menu on the screen */
	PMENU pMenu );			/*	Menu to show on the screen */

int showMenu(				/*	Show this menu on the screen */
	PMENU pMenu,			/*	Menu to show on the screen */
	MENUSTATE state );		/*	How to show the current item */

void showMenuItem(					/*	Show an individual menu item */
	PMENU pMenu,			/*	Menu to show on the screen */
	int item,				/*	Which item to show - ( 0 based ) */
	MENUSTATE state );		/*	How to show the current item */

int testMenu(
	PMENU pMenu,			/*	Menu to test against */
	KEYCODE key,			/*	What key was pressed */
	int *item );			/*	What thing was chosen */

#endif /*  MENU_INCLUDED	*/
