/*' $Header:   P:/PVCS/MAX/INCLUDE/BUTTON.H_V   1.1   02 Jun 1997 14:37:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BUTTON.H								      *
 *									      *
 * This file contains all definitions that are related to Buttons	      *
 *									      *
 ******************************************************************************/

#ifndef BUTTON_INCLUDED
#define BUTTON_INCLUDED

#ifndef WINSUPP_INCLUDED
#include <qwindows.h>
#endif

#ifndef INPUT_INCLUDED
#include <input.h>
#endif

#ifndef SCREEN_INCLUDED
#include <screen.h>
#endif

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */


#define MAXBUTTONTEXT  16		/* Install uses a button this long */
#define MAXBUTTONTRIGGERS	 4
#define MAXBLTRIGGERS  2

/*	Check allow any number to be checked - Radio is exclusive - Only 1 */
typedef enum { BTYPE_CHECK, BTYPE_RADIO } BUTTONTYPE;
typedef struct {
	BUTTONTYPE type;		/*	What type of list is this */
	int nItems;				/*	How many items in a button list */
	int active;			/*	Which item is active - Should match highlighted */
	KEYCODE trigger;		/*	Code that activates this button */
	unsigned char backgroundAttr;	/*	Background attribute */
	WINDESC win;			/*	Total window to display in */
} BLINFO;

typedef struct {
	struct {
		int highlighted:1;			/*	Is this item highlighted */
		int checked:1;				/*	IS this item marked as selected */
	} state;
	POINT pos;				/*	Where this thing lives relative to window */
	int triggerPos; 		/*	Where the trigger color is */
	KEYCODE triggers[MAXBLTRIGGERS];	/*	What pushes the button */
	KEYCODE altTrigger;	/*	Alt key trigger for this item */
	int textLen;			/*	Length of this item */
	char *text;			/*	What text to show */
} BLITEM;

typedef BLITEM			*PBLITEM;		/*	How to point at a BLITEM */
typedef BLITEM NEAR		*NPBLITEM;
typedef BLITEM FAR		*LPBLITEM;

typedef struct {
	int numItems;
	BLINFO info;
	BLITEM items[ 1 ];
} BUTTONLIST;

typedef BUTTONLIST			*PBUTTONLIST;		/*	How to point at a BUTTONLIST */
typedef BUTTONLIST NEAR 	*NPBUTTONLIST;
typedef BUTTONLIST FAR		*LPBUTTONLIST;

typedef struct {
	int visible : 1;			/*	Is this button visible */
	int pushed	: 1;			/*	Is this button in pushed state */
	int disabled: 1;			/*	Is this button currently disabled */
	int defButton:1;			/*	Is the the default button */
	int tabStop:  1;			/*	Does the tab key stop here */
} BUTTONFLAGS;

typedef struct {
	POINT pos;					/*	Where this button starts on the screen */
	int buttonLength;			/*	How wide to make this button */
	char text[MAXBUTTONTEXT];	/*	What is in this button */
	KEYCODE triggers[MAXBUTTONTRIGGERS];	/*	What triggers this button */
	KEYCODE returnCode;			/*	What to return if this button pushed */
	int defButton;				/*	Is this button the default */
	int tabStop;				/*	Is this button a tab key button */
	int colorStart; 			/*	Where to start the second color */
	int colorLen;				/*	How long the colored area is */
	unsigned char attr;			/*	What is the second color */
	int remember;				/*	Remember what was behind this button */
} BUTTON;

typedef BUTTON			*PBUTTON;		/*	How to point at a BUTTON */
typedef BUTTON NEAR		*NPBUTTON;
typedef BUTTON FAR		*LPBUTTON;

/*	Button errors */
typedef enum {
	BUTTON_OK,				/*	Function worked - Success */
	BUTTON_NOOP,			/*	Noop - Didn't do anything */
	BUTTON_NOROOM,			/*	No room in button structure */
	BUTTON_NOMORE,			/*	There were no things left to undo */
	BUTTON_THISLIST,		/*	The event is connected to this blist */
	BUTTON_LOSEFOCUS,		/*	The key press stepped past the last button */
	BUTTON_WEIRD			/*	Other wierd error */
} BUTTONRETURN;

/*	Global data to look at */

/*	This contains the result of the Last button test done/processed -
*	Either by keyboard OR by mouse.
*	This isa nasty sleazy way to do it but it beats trying to return it
*	All the time.
*/
GLOBAL struct {
	int number;			/*	What button position was pushed */
	KEYCODE key;			/*	Key code that that button returned */
} LastButton;

/*	 Functions */

int addButton(			/*	Add n buttons to the active buttons */
	PBUTTON button, 	/*	Pointer to list of buttons */
	int nButtons,		/*	How many buttons in the list */
	int *oldCount); 	/*	Original count of buttons before these added */

int dropButton( 		/*	Take a few buttons out of the list */
	PBUTTON button, 	/*	Pointer to stream of button definitions to remove */
	int nButtons);		/*	How many are in the list */

void blastButtons(		/*	Clear out ALL buttons */
	void ); 			/*	No arguements */

void adjustButtons(	/*	Adjust buttons around center of screen */
	PBUTTON pButton,	/*	Buttons to work on */
	int nButtons,		/*	How many buttons are there */
	WINDESC *win,		/* Descriptor of target window */
	int row );			/*	What row to put them on, rel to win */

void showAllButtons(		/*	Show the current list of buttons */
	void ); 			/*	No arguements */

void disableButton(		/*	Deactivate a button but leave it on the screen */
	KEYCODE key,	/*	What button to change - Based on return code */
	int enabled );		/*	Make it enabled  */

void disableButtonHelp( 	/*	Deactivate a button but leave it on the screen */
	KEYCODE key,	/*	What button to change - Based on return code */
	int disabled,		/*	Make it disabled  */
	KEYCODE defKey );	/*	Key to make current if required */

void showButton(		/*	Return Hit code for button or 0 */
	int buttonNumber,	/*	What button to show */
	BUTTONFLAGS flags );	/*	Show it pushed or normal */

void setButtonText(		/*	Change the current text for a button */
	KEYCODE key,		/*	What button to change - Based on return code */
	char * text,		/*	New Text for the button */
	int  colorStart);	/*	Where to start the second color */

void setCurrentButton(	/*	Make this the current button ( Slam to it )	*/
	KEYCODE key,		/*	What button to change - Based on return code */
	int show );			/*	Force the screen to update */

void pushButton(			/*	Show a button as being pushed for a short time */
	int number );			/*	Which button was pushed */

void setButtonFocus (	/*	Set the focus flag for the buttons */
	int gotFocus,		/*	True if buttons should consider themselves having focus now */
	KEYCODE key );		/*	Key for what direction we were going ( Tab or STab */

void setButtonData( int hasFocus );	/*	Set current and default upon add */

void noDefaultButton(	/*	Turn off any default button */
	void );

KEYCODE testButton(		/*	Return Hit code for button or 0 */
	KEYCODE key,		/*	What key was pressed */
	int push );		/*	If a button is found, should we push it */

KEYCODE testButtonClick(	/*	See if mouse pushed button */
	INPUTEVENT *event,	/*	What event to test */
	int push );		/*	If a button is found, should we push it */

int saveButtons(		/*	Save the current state of all buttons */
	void ); 			/*	And disable them but leave on the screen */

int restoreButtons(	/*	Put the last set of buttons back */
	void ); 			/*	 No Parameters */


/*	Blist routines */
BUTTONRETURN showBList( 		/*	Dump a button list box out on the screen */
	PBUTTONLIST pBList,		/*	What button list to dump */
	int hiLite );				/*	Should it be highlighted */

BUTTONRETURN showBLItem(		/*	Show a button list item on screen */
	PBUTTONLIST pBList,		/*	Button list to work with */
	int item);					/*	Which item to show */

BUTTONRETURN testBLItem(	/*	test a button list item on screen */
	PBUTTONLIST pBList,		/*	Button list to work with */
	INPUTEVENT *event,		/*	Input event to test for */
	int active );			/*	Should we do the action */

void sendBLItem(			/*	Send a key down to process */
	PBUTTONLIST pBList,	/*	Button list to work with */
	KEYCODE key );			/*	What key to process */

#endif /*  BUTTON_INCLUDED	*/
