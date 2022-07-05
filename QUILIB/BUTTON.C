/*' $Header:   P:/PVCS/MAX/QUILIB/BUTTON.C_V   1.1   30 May 1997 12:08:58   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * BUTTON.C								      *
 *									      *
 * Button management functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <string.h>

/*	Program Includes */

#include "button.h"
#include "commfunc.h"
#include "libcolor.h"
#include "libtext.h"
#include "screen.h"
#include "ui.h"
#include "windowfn.h"
#include "myalloc.h"

/*	Definitions for this Module */
#define MAXBUTTONS 11
#define NAPTIME 200


#define LEFTCHEV	((unsigned char)174)
#define RIGHTCHEV	((unsigned char)175)
#define LEFTCHEVON ((WORD)ButtonActiveColor<<8 | (WORD)LEFTCHEV )
#define RIGHTCHEVON ((WORD)ButtonActiveColor<<8 | (WORD)RIGHTCHEV )
#define LEFTCHEVHOT ((WORD)ButtonHotColor<<8 | (WORD)LEFTCHEV )
#define RIGHTCHEVHOT ((WORD)ButtonHotColor<<8 | (WORD)RIGHTCHEV )

typedef struct
{
	POINT pos;						/*	Where to start the button */
	char text[MAXBUTTONTEXT];		/*	What the button says */
	KEYCODE triggers[MAXBUTTONTRIGGERS];	/*	What pushes the button */
	KEYCODE returnCode;				/*	What value to return */
	int  buttonLength;				/*	How long this button is */
	int  colorStart;				/*	Where to start the second color */
	int  colorLen;					/*	How long to make the color */
	char attr;						/*	What color the second color is */
	BUTTONFLAGS state;
	int remember;	/*	Should we remember what's behind us */
	void * behind;	/*	Image of what was behind this button when displayed */
} BINFO;

typedef BINFO			*PBINFO;		/*	How to point at a BINFO */
typedef BINFO NEAR		*NPBINFO;
typedef BINFO FAR		*LPBINFO;

#define MAXDITCH 12
static BINFO lastDitch[MAXDITCH];
static lastDitchUsed = FALSE;

/*
*	This is the stack of saved button states
*/
#define MAXSAVED 7
int savedCount = 0;
struct {
	int count;			/*	How many buttons */
	int defButton;		/*	Which is the current default -1 for none */
	int curButton;		/*	What button is active right now -1 for none */
	int hasFocus;		/*	Does a button have focus */
	PBINFO where;		/*	Where they are */
} saveStack[MAXSAVED];

int buttonCount = 0;				/*	How many in the button struct */
BINFO  buttonList[MAXBUTTONS];		/*	Actual button structure */

int buttonDefault = -1;
int buttonCurrent = -1;
int buttonHasFocus = FALSE;

/*	Program Code */
/*
*	Name - findThisButton
*
*	Synopsis  PBINFO findThisButton( KEYCODE key )
*
*	Parameters
*		KEYCODE key	Button to find
*
*	Description
*		Walk the button list to find the button indicated by this key
*
*	results
*		Pointer to button that has key code
*		if not found, return null;
*
*	version 1.0
*/
PBINFO findThisButton( KEYCODE key )
{
	int counter;
	PBINFO bInfo;
	for( bInfo = buttonList, counter = 0;
		counter < buttonCount; counter++, bInfo++ ) {
		if( bInfo->returnCode == key )
			return bInfo;
	}
	return NULL;
}

/**
*
* Name		addButton
*
* Synopsis	int addButton( PBUTTON button, int nButtons, int *oldCount	)
*
* Parameters
*		PBUTTON button		Pointer to n button structures to add
*		int nButtons		How many buttons to add.
*		int *oldCount)		Original count of buttons before these added
*
* Description
*		This routine adds buttons to the button structure by scanning the
*	structure looking for holes to add a button into.  If oldCount NULL,
*	original count not returned
*
* Returns	BUTTON_OK - All buttons added.
*			BUTTON_NOROOM - No Room.
*			BUTTON_WIERD - Other error
*
* Version	1.0
*/
int addButton(			/*	Add n buttons to the active buttons */
	PBUTTON button, 	/*	Pointer to list of buttons */
	int nButtons,		/*	How many buttons in the list */
	int *oldCount)		/*	Original count of buttons before these added */
{
	int counter;
	PBINFO bInfo = buttonList + buttonCount;	/*	Pointer to start of empty space */

	if( oldCount )
		*oldCount = buttonCount;

	/*	Make sure that all buttons fit.  If not, don't start */
	if( buttonCount + nButtons > MAXBUTTONS )
		return BUTTON_NOROOM;

	for( counter = 0; counter < nButtons; counter++, button++, bInfo++	) {
		memset( bInfo, 0, sizeof( BINFO ));
		bInfo->pos = button->pos;
		strcpy( bInfo->text, button->text );
		memcpy( bInfo->triggers, button->triggers, sizeof( bInfo->triggers ));
		bInfo->returnCode = button->returnCode;
		bInfo->buttonLength = button->buttonLength;
		bInfo->state.defButton = button->defButton;
		bInfo->state.tabStop = button->tabStop;
		bInfo->colorStart = button->colorStart;
		bInfo->colorLen = button->colorLen;
		bInfo->attr = button->attr;
		bInfo->remember = button->remember;
	}

	buttonCount += nButtons;
	setButtonData(FALSE);
	return BUTTON_OK;
}

/**
*
* Name		dropButton
*
* Synopsis	int dropButton( PBUTTON button, int nButtons )
*
* Parameters
*		PBUTTON button		Pointer to n button structures to drop
*		int nButtons		How many buttons to drop.
*
* Description
*		Walk the list of supplied buttons finding them in the big list
*	and droping them one at a time.  This could be done more efficiently
*	with 2 pointers but who cares.
*
* Returns	BUTTON_OK - All buttons dropped.
*
* Version	1.0
*/
int dropButton( 		/*	Take a few buttons out of the list */
	PBUTTON button, 	/*	Pointer to stream of button definitions to remove */
	int nButtons)		/*	How many are in the list */
{
	int counter;
	int doSet = FALSE;

	/*	Walk the list of buttons provided */
	for( counter = 0; counter < nButtons; counter++, button++ ) {
		int listCounter;
		PBINFO bInfo = buttonList;	/*	Pointer to start of button space */

		/*	Find this button */
		for( listCounter = 0;
			listCounter < buttonCount; listCounter++, bInfo++ ) {
			if( bInfo->pos.row == button->pos.row &&
				bInfo->pos.col == button->pos.col ) {

				BUTTONFLAGS flag = buttonList[listCounter].state;

				/*	Kill it */
				if( listCounter == buttonCurrent )
					doSet = TRUE;

				if( flag.visible ) {
					flag.visible = FALSE;
					showButton( listCounter, flag );
				}

				if( listCounter < buttonCount - 1 ) {
					memcpy( bInfo, bInfo+1,
						( buttonCount-listCounter-1 ) * sizeof( BINFO ) );
				}
				buttonCount--;
				break;
			}

		}
	}
	if( doSet )
		setButtonData(FALSE);
	return BUTTON_OK;
}


/**
*
* Name		blastButtons
*
* Synopsis	int blastButtons( void )
*
* Parameters
*		No parameters
*
* Description
*	Toss all buttons out.
*
* Returns	Always works
*
* Version	1.0
*/
void blastButtons(		/*	Show the current list of buttons */
	void )				/*	No arguements */
{
	int listCounter;
	for( listCounter = 0;
		listCounter < buttonCount; listCounter++ ) {
		if( buttonList[listCounter].state.visible ) {
			BUTTONFLAGS flag = buttonList[listCounter].state;
			flag.visible = FALSE;
			showButton( listCounter, flag );
		}
	}
	buttonCount = 0;
}

/**
*
* Name		setButtonData
*
* Synopsis	int setButtonData( int hasFocus )
*
* Parameters
*		int hasFocus;		Buttons have full focus
*
* Description
*	Set the 3 globals for handleing focus and tabs
*
* Returns	Always works
*
* Version	1.0
*/
void setButtonData( int hasFocus )	/*	Set current and default upon add */
{
	int listCounter;

	buttonDefault = buttonCurrent = -1;
	buttonHasFocus = hasFocus;
	for( listCounter = 0;
		listCounter < buttonCount; listCounter++ ) {
		if( buttonList[listCounter].state.defButton ) {
			buttonCurrent = buttonDefault = listCounter;
			return;
		}
	}

}

/**
*
* Name		adjustButtons - Adjust buttons around center of screen
*
* Synopsis	int adjustButtons( PBUTTON pButton, int nButtons, int row );
*
* Parameters
*	PBUTTON pButton,		Buttons to work on
*	int nButtons,			How many buttons are there
*	WINDESC win,			Descriptor of target window
*	int row )			What row to put them on, rel to win
*
* Description
*		Work the button list so that all buttons are centered
*	Fix up the rows also
*
* Returns	Nothing
*
* Version	1.0
*/
#pragma optimize ("leg",off)    /* Optimization bug (?) */
void adjustButtons(	/*	Adjust buttons around center of screen */
	PBUTTON pButton,	/*	Buttons to work on */
	int nButtons,		/*	How many buttons are there */
	WINDESC *win,		/* Descriptor of target window */
	int row )			/*	What row to put them on, rel to win */
{
	PBUTTON thisButton;
	int counter;
	int offset;
	int col;

	/* Calc positions of buttons within window */
	for( offset = counter = 0; counter < nButtons; counter++ ) {
		thisButton = pButton+counter;
		if (thisButton->pos.row < 0) continue;
		offset += thisButton->buttonLength + 2;
	}
	offset -= 2; /* One less gap than buttons */

	/*
	*  offset = (win->ncols - 2 - (nButtons*MAXBUTTONTEXT) - (2 * (nButtons-1))) / 2;
	*/
	/*	Half the leftover space between window width and size of all buttons */
	offset = ((win->ncols - 2) - offset) / 2;
	if (offset < 1) offset = 0;

	col = win->col + offset + 1;
	for( counter = 0; counter < nButtons; counter++ ) {
		thisButton = pButton+counter;
		if (thisButton->pos.row < 0) continue;
		thisButton->pos.row = win->row + row;
		thisButton->pos.col = col;
		col += thisButton->buttonLength + 2;
	}

}
#pragma optimize ("",on)
/**
*
* Name		showAllButtons
*
* Synopsis	int showAllButtons( void )
*
* Parameters
*		No parameters
*
* Description
*		Walk the list of buttons pumping them and their shadows out.
*	Don't worry if it's already displayed,  they'll never notice.
*	The shadow is tricky in that we show a character in that spots
*	foreground color as background
*
* Returns	Always works
*
* Version	1.0
*/
void showAllButtons(		/*	Show the current list of buttons */
	void )				/*	No arguements */
{
	int listCounter;
	for( listCounter = 0;
		listCounter < buttonCount; listCounter++ ) {
		BUTTONFLAGS flags = buttonList[listCounter].state;
		flags.visible = TRUE;
		showButton( listCounter, flags );
	}
}


/**
*
* Name		setButtonFocus
*
* Synopsis	void setButtonFocus( int gotFocus )
*
* Parameters
*		int gotFocus;		True if the buttons should now consider that they have focus
*
* Description
*		Set the buttonFocus Flag to correct state
*
* Returns
*		Always works
*
* Version	1.0
*/
void setButtonFocus (	/*	Set the focus flag for the buttons */
	int gotFocus,	/*	True if buttons should consider themselves having focus now */
	KEYCODE key )	/*	WHat direction to go if now got focus */
{
	int lastButton = buttonCurrent;
	buttonHasFocus = gotFocus;
	if( !buttonHasFocus ) {
		buttonCurrent = buttonDefault;
	} else {
		int listCounter, firstTab, lastTab;
		firstTab = lastTab = -1;
		for( listCounter = 0; listCounter < buttonCount; listCounter++ ) {
			if( !buttonList[listCounter].state.disabled
				&& buttonList[listCounter].state.visible
				&& buttonList[listCounter].state.tabStop ) {
				if( firstTab == -1 )
					firstTab = listCounter;
				lastTab = listCounter;
			}
		}
		if( firstTab == -1 )
			return; 			/*	No default - Don't do anything */
		if( key == KEY_STAB )
			buttonCurrent = lastTab;
		else
			buttonCurrent = firstTab;
	}
	showButton( lastButton, buttonList[lastButton].state );
	showButton( buttonCurrent, buttonList[buttonCurrent].state );
}

/**
*
* Name		noDefaultButton
*
* Synopsis	void noDefaultButtonFocus( void )
*
* Parameters
*		No parameters
*
* Description
*		Turn off ALL buttons - equivalent to tabbing until focus lost
*
* Returns
*		Always works
*
* Version	1.0
*/
void noDefaultButton(	/*	Turn off any default button */
	void )
{
	int lastButton = buttonCurrent;
	buttonCurrent = -1;
	buttonHasFocus = FALSE;
	showButton( lastButton, buttonList[lastButton].state );
}


/**
*
* Name		testButton
*
* Synopsis	int testButton( KEYCODE key, int push )
*
* Parameters
*		KEYCODE key;			Key to see if a button matches
*		int push;				True if we should push the button
*
* Description
*		Walk the list of buttons testing all their trigger keys
*	to see if they match this key.	Return result or 0.
*
* Returns	0 ->  Not a button key
*			returnCode of button
*
* Version	1.0
*/
KEYCODE testButton(		/*	Return Hit code for button or 0 */
	KEYCODE key,			/*	What key was pressed */
	int push )			/*	If a button is found, should we push it */
{
	int listCounter, inner, lastButton, start;
	int firstTab = -1;
	int lastTab = -1;
	PBINFO bInfo = buttonList;	/*	Pointer to start of empty space */
	if( key == KEY_STAB || key == KEY_TAB ) {
		for( listCounter = 0; listCounter < buttonCount; listCounter++ ) {
			if( !buttonList[listCounter].state.disabled
				&& buttonList[listCounter].state.visible
				&& buttonList[listCounter].state.tabStop ) {
				if( firstTab == -1 )
					firstTab = listCounter;
				lastTab = listCounter;
			}
		}
	}
	switch( key ) {
	case KEY_STAB:
		if( buttonCurrent != -1 ) {
			lastButton = start = buttonCurrent;
			if( !buttonHasFocus )
				start = lastTab+1;
			buttonCurrent = buttonDefault;
			for( listCounter = start-1;
				 listCounter >= firstTab;
				 listCounter-- ) {
				if( !buttonList[listCounter].state.disabled
					&& buttonList[listCounter].state.visible
					&& buttonList[listCounter].state.tabStop ) {
					buttonCurrent = listCounter;
					break;
				}
			}
			showButton( lastButton, buttonList[lastButton].state );
			if( listCounter < firstTab ) {
				buttonHasFocus = FALSE;
				showButton( buttonCurrent, buttonList[buttonCurrent].state );
				return BUTTON_LOSEFOCUS;
			}
			else {
				buttonHasFocus = TRUE;
				showButton( buttonCurrent, buttonList[buttonCurrent].state );
				return BUTTON_OK;
			}

		}
		break;
	case KEY_TAB:
		if( buttonCurrent != -1 ) {
			lastButton = start = buttonCurrent;
			if( !buttonHasFocus )
				start = firstTab-1;
			buttonCurrent = buttonDefault;
			for( listCounter = start+1;
				 listCounter <= lastTab;
				 listCounter++ ) {
				if( !buttonList[listCounter].state.disabled
					&& buttonList[listCounter].state.visible
					&& buttonList[listCounter].state.tabStop ) {
					buttonCurrent = listCounter;
					break;
				}
			}

			showButton( lastButton, buttonList[lastButton].state );
			if( listCounter > lastTab ) {
				buttonHasFocus = FALSE;
				showButton( buttonCurrent, buttonList[buttonCurrent].state );
				return BUTTON_LOSEFOCUS;
			} else {
				buttonHasFocus = TRUE;
				showButton( buttonCurrent, buttonList[buttonCurrent].state );
				return BUTTON_OK;
			}

		}
		break;
	case KEY_ENTER:
		if( buttonCurrent != -1 ) {
			if( buttonList[buttonCurrent].state.disabled || 	/* Disabled or hidden */
				!buttonList[buttonCurrent].state.visible )		/*	Dont cut it */
					return BUTTON_OK;

			LastButton.number = buttonCurrent;
			LastButton.key = buttonList[buttonCurrent].returnCode;
			return buttonList[buttonCurrent].returnCode;
		}
		/*	Fall into default processing here */
	default:
		for( listCounter = 0;
			listCounter < buttonCount; listCounter++, bInfo++ ) {
			for( inner = 0; inner < MAXBUTTONTRIGGERS; inner++ ) {
				if( key == bInfo->triggers[inner] ) {
					if( bInfo->state.disabled ||		/* Disabled or hidden */
						!bInfo->state.visible ) 		/*	Dont cut it */
						return BUTTON_NOOP;		/*	Was button_OK - 9/30/91 */
					if( push ) {
						pushButton( listCounter );
					}
					LastButton.number = listCounter;
					LastButton.key = bInfo->returnCode;
					if( bInfo->state.tabStop && listCounter != buttonCurrent ) {
					/*	Turn off the last current button and make this one current */
						listCounter = buttonCurrent;
						buttonCurrent = LastButton.number;
						showButton( listCounter, buttonList[listCounter].state );
						showButton( buttonCurrent, buttonList[buttonCurrent].state );
					}
					return bInfo->returnCode;
				}
			}
		}
		break;
	}
	return BUTTON_NOOP;
}


/**
*
* Name		testButtonClick
*
* Synopsis	int testButtonClick( INPUTEVENT *event, int push )
*
* Parameters
*		EVENTCODE event;		What was mouse caused to see if a button matches
*		int push;				True if we should push the button
*
* Description
*		Walk the list of buttons testing all their positions
*	to see if they match this key.	Return result or 0.
*
* Returns	0 ->  Not a button key
*			returnCode of button
*
* Version	1.0
*/
KEYCODE testButtonClick(	/*	See if mouse pushed button */
	INPUTEVENT *event,	/*	What event to test */
	int push )		/*	If a button is found, should we push it */
{
	int listCounter;
	PBINFO bInfo = buttonList;	/*	Pointer to start of empty space */

	if (event->click == MOU_NOCLICK ||
	    event->click == MOU_LSINGLEUP ||
	    event->click == MOU_RSINGLEUP ||
	    event->click == MOU_CSINGLEUP) {
		/* Up clicks don't count here */
		return 0;
	}

	for( listCounter = 0;
		listCounter < buttonCount; listCounter++, bInfo++ ) {
		POINT ulPoint, lrPoint;
		if( bInfo->state.disabled )
			continue;
		ulPoint.row = (bInfo->pos.row < 0 ) ?
					ScreenSize.row + bInfo->pos.row:
					bInfo->pos.row;
		ulPoint.col = bInfo->pos.col;
		lrPoint.row = ulPoint.row;
		lrPoint.col = ulPoint.col + bInfo->buttonLength - 1;

		if( event->x >= ulPoint.col
			&& event->x <= lrPoint.col
			&& event->y >= ulPoint.row
			&& event->y <= lrPoint.row ) {

			if( push ) {
				pushButton( listCounter );
			}
			LastButton.number = listCounter;
			LastButton.key = bInfo->returnCode;
			if( bInfo->state.tabStop && listCounter != buttonCurrent ) {
			/*	Turn off the last current button and make this one current */
				listCounter = buttonCurrent;
				buttonCurrent = LastButton.number;
				showButton( listCounter, buttonList[listCounter].state );
				showButton( buttonCurrent, buttonList[buttonCurrent].state );
			}
			return bInfo->returnCode;
		}
	}
	return 0;
}


/**
*
* Name		disableButton
*
* Synopsis	void disableButton( KEYCODE key, int enabled )
*
* Parameters
*		KEYCODE key;				Return code to deal with
*		int enabled;				Make the button enabled if true
*
* Description
*		Set the state of the button as required.  If different than what
*	was and VISIBLE, show it in the new state.
*
* Returns
*		nothing
*
* Version	1.0
*/
void disableButton(		/*	Deactivate a button but leave it on the screen */
	KEYCODE key,	/*	What button to change - Based on return code */
	int disabled )		/*	Make it disabled  */
{
	PBINFO bInfo = findThisButton( key );

	if( bInfo &&
		(( bInfo->state.disabled && !disabled ) ||
		( !bInfo->state.disabled && disabled ) ))  {
		bInfo->state.disabled = disabled;
		showButton( bInfo-buttonList, bInfo->state );
		if( disabled && buttonCurrent == bInfo-buttonList ) {
			buttonCurrent = buttonDefault;
			showButton( buttonCurrent, buttonList[buttonCurrent].state );
		}
	}
}

/**
*
* Name		disableButtonHelp
*
* Synopsis	void disableButtonHelp( KEYCODE key, int enabled, keyCode defKey )
*
* Parameters
*		KEYCODE key;				Return code to deal with
*		int enabled;				Make the button enabled if true
*		KEYCODE defKey; 			Code if button disabled is current
*
* Description
*		Set the state of the button as required.  If different than what
*	was and VISIBLE, show it in the new state.	If the current button is disabled
*	then got to the button indicated by defKey
*
* Returns
*		nothing
*
* Version	1.0
*/
void disableButtonHelp( 	/*	Deactivate a button but leave it on the screen */
	KEYCODE key,	/*	What button to change - Based on return code */
	int disabled,		/*	Make it disabled  */
	KEYCODE defKey )
{
	int oldDefault = buttonDefault;
	PBINFO bInfo = findThisButton( defKey );

	buttonDefault = bInfo - buttonList;
	disableButton( key, disabled );
	buttonDefault = oldDefault;
}

/**
*
* Name		setButtonText
*
* Synopsis	void setButtonText( KEYCODE key, char *text, int colorStart )
*
* Parameters
*		KEYCODE key;				Return code to deal with
*		char *text;				New text for the button
*		int  colorStart;			Where to start the second color
*
* Description
*		Copy the new text over the current text and show the button again
*
* Returns
*		nothing
*
* Version	1.0
*/
void setButtonText(		/*	Change the current text for a button */
	KEYCODE key,		/*	What button to change - Based on return code */
	char * text,		/*	New Text for the button */
	int  colorStart)	/*	Where to start the second color */
{
	PBINFO bInfo = findThisButton( key );

	strcpy( bInfo->text, text );
	bInfo->colorStart = colorStart;
	showButton( bInfo-buttonList, bInfo->state );
}


/**
*
* Name		setCurrentButton
*
* Synopsis	void setCurrentButton( int buttonNumber )
*
* Parameters
*		int buttonNumber;			Which button to push
*
* Description
*		Set this button to be the current button
*
* Returns
*		Nothing
*
* Version	1.0
*/
void setCurrentButton(	/*	Make this the current button ( Slam to it )	*/
	KEYCODE key,		/*	What button to change - Based on return code */
	int show )			/*	Force the screen to update */
{
	int lastButton = buttonCurrent;
	PBINFO bInfo = findThisButton( key );

	buttonCurrent = bInfo- buttonList;

	if( show && lastButton != buttonCurrent ) {
		showButton( lastButton, buttonList[lastButton].state );
	}
	buttonHasFocus = TRUE;
	showButton( buttonCurrent, bInfo->state );
}

/**
*
* Name		pushButton
*
* Synopsis	void pushButton( int buttonNumber )
*
* Parameters
*		int buttonNumber;			Which button to push
*
* Description
*		Show the button as pushed - Sit around for n milliseconds
*	and then show the button as regular
*
* Returns
*		Nothing
*
* Version	1.0
*/
void pushButton(				/*	Show a button as being pushed for a short time */
	int number )	/*	Which button was pushed */
{
	PBINFO bInfo = buttonList + number;	/*	Pointer to button to work on */
	if( bInfo->text[0] ) {
		BUTTONFLAGS flags = buttonList[number].state;
		flags.pushed = TRUE;
		showButton( number, flags );
		sleep(	NAPTIME );
		flags.pushed = FALSE;
		showButton( number, flags );
	}
}

/**
*
* Name		showButton
*
* Synopsis	void showButton( int buttonNumber )
*
* Parameters
*		int buttonNumber;			Which button to push
*
* Description
*		Show the given button in the correct state.
*	if the state is hidden, use the behind to paint it.  If no behind
*	paint it default background shade.
*
* Returns
*		Nothing
*
* Version	1.0
*/
void showButton(		/*	Return Hit code for button or 0 */
	int buttonNumber,	/*	What button to change	*/
	BUTTONFLAGS flags )	/*	Show it pushed or normal */
{
	PBINFO bInfo = buttonList + buttonNumber;	/*	Pointer to button to work on */
	WINDESC win;
	char attr;
	unsigned char trigAttr;

	/*	Catch the case of not visible but useable button - No text - no button */
	if( !bInfo->text[0] ) {
		bInfo->state = flags;
		return;
	}

	SETWINDOW(	&win,
				( (bInfo->pos.row < 0 ) ?
					ScreenSize.row + bInfo->pos.row:
					bInfo->pos.row ),
				bInfo->pos.col,
				1,
				bInfo->buttonLength );


	if( flags.visible ) {
		int numChars = strlen( bInfo->text );
		int needChevrons = FALSE;
		int leftChev, rightChev;
		/*
		*  Modified to center the text in the button
		*  Offset is from beginning of string now
		*/
		if( bInfo->remember && !bInfo->behind )
			bInfo->behind = win_save( &win, SHADOW_SINGLE );
		if( flags.pushed ) {
			attr = ButtonPushedColor;
			trigAttr = attr;
		} else if( flags.disabled ) {
			attr = ButtonDisabledColor;
			trigAttr = attr;
		} else if( buttonNumber == buttonCurrent ) {
			attr = buttonHasFocus ?
					ButtonHotColor : ButtonActiveColor;		/*	ButtonHotColor;  */
			trigAttr = buttonHasFocus
				? ButtonHotColor
				: (ScreenType == SCREEN_MONO ? ButtonPushedColor : bInfo->attr);
			needChevrons = TRUE;
		} else {
			attr = ButtonActiveColor;
			trigAttr =
				ScreenType == SCREEN_MONO ? ButtonPushedColor : bInfo->attr;
		}

		wput_sca( &win, VIDWORD( attr, ' ' ));
		bInfo->state = flags;
		halfShadow( &win );

		if (ScreenType == SCREEN_MONO) {
			/*	Set up window to display the whole text */
			win.ncols = 1;
			wput_c( &win, ButtonStart );
			win.col = bInfo->pos.col + bInfo->buttonLength - 1;
			wput_c( &win, ButtonStop );
		}
		/*	Now color in the trigger if specified */

		/*	Set up window to display the whole text */
		win.col = bInfo->pos.col + (bInfo->buttonLength - numChars) / 2;
		leftChev = win.col - 2;
		rightChev = win.col+numChars+1;
		win.ncols = numChars;

		if( leftChev < bInfo->pos.col ) {
			leftChev = bInfo->pos.col;
			rightChev = leftChev+numChars+1;
		}

		/*	Put out the string in button color - Allow for all colored */
		if( win.ncols )
			wput_c( &win, bInfo->text);

		if( bInfo->colorStart >= 0 ) {
			char *start = bInfo->text + bInfo->colorStart;
			win.col += bInfo->colorStart;
			win.ncols = bInfo->colorLen;

			wput_csa( &win, start, trigAttr );
		}
		if( needChevrons ) {
			win.col = leftChev;
			win.ncols = 1;
			wput_sc( &win, LEFTCHEV );
			win.col = rightChev;
			wput_sc( &win, RIGHTCHEV );
		}
	} else if ( bInfo->state.visible ) {
		/*	Was visible - Isn't now */
		if( bInfo->behind )
			bInfo->behind = win_restore( bInfo->behind, TRUE );
		else {
			if( win.row < ScreenSize.row - 1 )
				win.nrows++;
			if( win.col < ScreenSize.col - 1 )
				win.ncols++;
			wput_sca( &win, VIDWORD( ButtonDisabledColor, '\xdb'));
		}
		bInfo->state = flags;
	}


}


/**
*
* Name		saveButtons
*
* Synopsis	void saveButtons( void )
*
* Parameters
*			No parameters
*
* Description
*		Save the current buttonList structure in a handle.	Set
*	all buttons to disabled and show them.	Handles of saved states
*	are stored in a stack of pointers
*
* Returns
*		BUTTON_OK if alloc worked
*		BUTTON_NOROOM if alloc failed
*
* Version	1.0
*/
int saveButtons(		/*	Save the current state of all buttons */
	void )			/*	And disable them but leave on the screen */
{
	if( savedCount < MAXSAVED ) {
		int listCounter;

		/*	Save it off  */
		saveStack[savedCount].where = my_malloc( buttonCount * sizeof(BINFO) );
		if( !saveStack[savedCount].where ) {
			if( lastDitchUsed || buttonCount > MAXDITCH )
				return BUTTON_NOROOM;
			lastDitchUsed = TRUE;			/*	One last chance to save buttons */
			saveStack[savedCount].where = lastDitch;
		}

		memcpy( saveStack[savedCount].where,
				buttonList,
				buttonCount * sizeof(BINFO) );
		saveStack[savedCount].count = buttonCount;
		saveStack[savedCount].defButton = buttonDefault;
		saveStack[savedCount].curButton = buttonCurrent;
		saveStack[savedCount].hasFocus = buttonHasFocus;

		savedCount++;

		/*	Show the disabled buttons */
		for( listCounter = 0;
			listCounter < buttonCount; listCounter++ ) {
			BUTTONFLAGS flags = buttonList[listCounter].state;
			flags.disabled = TRUE;
			showButton( listCounter, flags );
		}
		/*	Make the old ones history */
		buttonCount = 0;
	} else
		return BUTTON_NOROOM;

	return BUTTON_OK;
}
/**
*
* Name		restoreButtons
*
* Synopsis	void restoreButtons( void )
*
* Parameters
*			No parameters
*
* Description
*		restore the current buttonList structure from a handle. Show
*	all buttons.
*
* Returns
*		BUTTON_OK if there was something to pop
*		BUTTON_NOMORE if the stack was empty
*
* Version	1.0
*/
int restoreButtons(	/*	Put the last set of buttons back */
	void )			/*	 No Parameters */
{
	if( savedCount ) {
		int listCounter;

		blastButtons();

		/*	restore the data */
		savedCount--;
		buttonCount = saveStack[savedCount].count;
		buttonDefault = saveStack[savedCount].defButton;
		buttonCurrent = saveStack[savedCount].curButton;
		buttonHasFocus = saveStack[savedCount].hasFocus;

		memcpy( buttonList,
				saveStack[savedCount].where,
				buttonCount * sizeof(BINFO) );

		/*	release it */
		if( !lastDitchUsed )
			my_free( saveStack[savedCount].where );
		lastDitchUsed = FALSE;

		saveStack[savedCount].where = NULL;

		/*	Show it the way it was */
		for( listCounter = 0;
			listCounter < buttonCount; listCounter++ ) {
			BUTTONFLAGS flags;
			flags = buttonList[listCounter].state;
			showButton( listCounter, flags );
		}
	} else
		return BUTTON_NOMORE;

	return BUTTON_OK;
}
