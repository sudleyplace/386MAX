/*' $Header:   P:/PVCS/MAX/QUILIB/OPTION.C_V   1.0   05 Sep 1995 17:02:20   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * OPTION.C								      *
 *									      *
 * Option editor functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include <help.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "editwin.h"
#include "fldedit.h"
#include "ui.h"
#include "windowfn.h"
#include "libcolor.h"
#include "myalloc.h"

/*	Option data */
#define OWNER
#include "options.h"
#undef	OWNER

static char upDown[2] = {
	'\x18','\x19' };
static char leftRight[2] = {
	'\x1b','\x1a' };
static char filler = '\xB0';

void	showOptionText(WINDESC *win, int which, int hiLite);
extern void vWin_clearBottom( PTEXTWIN pText );

WINRETURN vOpt_ask(  /* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event);  /* Text window to run around in */

WINRETURN vDesc_ask(  /* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event);  /* Text window to run around in */

int   inWin(
PTEXTWIN pText,
INPUTEVENT *event);

WINRETURN vOpt_key(	/*	Take a key and return an appropriate action */
KEYCODE key );		/*	Actual key pressed */


#define WIDTH 66

enum {
	TEXT1, TEXT2, TEXT3 };


int   option_replace(
PTEXTWIN pText,
char  *p,
int   row)
{
	char  temp[MAXSTRING + 2];
	WINDESC tempWin;

	SETWINDOW( &tempWin, 0, 0, 1, MAXSTRING );

	memset(temp, ' ', MAXSTRING);
	temp[MAXSTRING] = '\0';
	tempWin.ncols = MAXSTRING;
	tempWin.row = row;
	vWinPut_c( pText, &tempWin, temp );

	tempWin.ncols = strlen( p );
	vWinPut_c( pText, &tempWin, p );

	return(0);
}

int option_insert(
PTEXTWIN pText,
char  *p,
int   *CurrentLine,
char  *line[],
int   *lines)
{
	int	display;
	int   start = *CurrentLine + pText->cursor.row;
	char  *t;

	if (VIEW) return(0);

	if (!(display = insert_block (pText, CurrentLine, line, lines, start))) {
		errorMessage( WIN_NOMEMORY	);	/* Insufficient Memory */
		return(0);
	}

	if ((t = salloc(p)) == NULL) return(0);
	if (line[start]) my_free(line[start]);
	line[start] = t;

	return(4);
}

/**
*
* Name		vWin_edit_ask - Keyboard interface for a window
*
* Synopsis	WINRETURN vWin_ask(PTEXTWIN pText )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Accept mouse and keyboard events and move the window around
*	as required.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
#pragma optimize ("leg",off)
char  *option_editor(	/*	Let a user choose an option */
PTEXTWIN pText, 	   /*	Text window to run around in */
int   row,
int   *replace,
int   help,
int   tutor)
{
	enum {
		OPTION, DESCRIPT, FIELD, DBUTTONS }
	focus = OPTION;

	TEXTWIN pOption, pDescript;
	INPUTEVENT event;
	WINRETURN action, askReturn;
	FLDITEM     name;
	void *behind = NULL;
	int optioncount;

	int i, display, oldButtons, HelpNumber, oldHelpNumber;
	/* int allowEnter; */
	int   DescWindow = 0, OptWindow = 0;

	WINDESC workWin, OptWin, DescWin, TextWin;

	char  temp[MAXSTRING + 2];
	char  comp[MAXSTRING + 2];

	int	 foundText, len;

	*replace = 0;

	OptionText[0] = '\0';
	display = i = 0;

	/*	Draw up the dialog box */
	/*	Set up where we are putting this */
	show_cursor();
	push_cursor();

	SETWINDOW( &workWin,
	pText->win.row - 2,
	pText->win.col-1,	/* wasn't -1 */
	pText->win.nrows+4,
	pText->win.ncols+2);	/* wasn't +2 */

	/*	Remember what we are stomping on */
	behind = win_save( &workWin, TRUE );
	if( !behind ) {
		errorMessage(WIN_NOROOM);
		goto lastOut;
	}

	if( saveButtons() != BUTTON_OK )
		goto lastOut;

	/*	Put up the window */
	wput_sca( &workWin, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &workWin );
	box( &workWin, BOX_DOUBLE, OptionTitle, OptBottomTitle, BaseColor );


	addButton( OptionButtons, NUMOPTIONBUTTONS, &oldButtons );
	disableButton( KEY_ENTER, FALSE );
	/* allowEnter = 0; */
	disableButton( KEY_ESCAPE, FALSE );
	disableButton( KEY_F1, FALSE);
	disableButton( KEY_F2, TRUE);
	showAllButtons();


	{
		int winError;
		int   i;

		/* Set optioncount and initialize optionIdx[] */
		for (i = optioncount = 0; i < MAXOPTIONS; i++)
		 if (optionList [i].flags & optsActive)
			optionIdx [optioncount++] = i;

		SETWINDOW( &OptWin,
		pText->win.row,
		pText->win.col + 2,
		min (pText->win.nrows - 5, optioncount),
		13);

		OptWindow = 0;
		winError = vWin_create( /*	Create a text window */
		&pOption,		/*	Pointer to text window */
		&OptWin,			/* Window descriptor */
		optioncount,	/*	How many rows in the window*/
		OptWin.ncols,		/*	How wide is the window */
		OptionTextColor, /*	Default Attribute */
		SHADOW_SINGLE,			/*	Should this have a shadow */
		BORDER_NONE,	/*	Single line border */
		TRUE, FALSE,	/*	Scroll bars */
		TRUE,			/*	Should we remember what was below */
		FALSE );		/*	Is this window delayed */

		if( winError == WIN_OK ) {
			WINDESC tempWin;
			SETWINDOW( &tempWin, 0, 0, 1, OPTSTRING - 1 );

			OptWindow = 1;

			/* Fill the narrow scroll box with active options */
			for (i = 0; i < optioncount; i++)
			 if (optionList [optionIdx[i]].flags & optsActive) {
				tempWin.ncols = strlen( optionList[optionIdx[i]].option);
				vWinPut_c( &pOption, &tempWin, optionList[optionIdx[i]].option);
				tempWin.row++;
			 }

			vWin_show_cursor(&pOption);

			if( pOption.vScroll.row > 0 )
				paintScrollBar( &pOption.vScroll, pOption.attr,
				pOption.size.row - pOption.win.nrows, pOption.corner.row );
		}
		else {
			errorMessage( WIN_NOMEMORY	);	/* Insufficient Memory */
			OptionText[0] = '\0';
			goto done;
		}

	}

	{

		SETWINDOW( &DescWin,
		pText->win.row,
		pText->win.col + 2 + 13 + 2,
		pText->win.nrows - 5,
		55);  /* was 54 */

	}


	/* now determine if we are going to edit an existing line */

	vWinGet_s( pText, row, temp);
	len = lnbc(temp, 256);
	temp[len] = '\0';

	{
		int   pos = 0;
		int   flag = 0;
		comp[0] = '\0';
		for (i = 0; i < len; i++) {
			if ((temp[i] == '=') && pos) {
				comp[pos++] = temp[i];
				comp[pos] = '\0';
				break;
			}
			else if ((temp[i] == ' ') && pos && !flag) {
				flag++;
			}
			else if (isspace(temp[i])) {
			}
			else if (flag) {
				break;
			}
			else {
				comp[pos++] = temp[i];
				comp[pos] = '\0';
			}
		}
	}

	foundText = 0;

	for (i = optioncount-1; i >= 0; i--)
	 if (optionList[optionIdx[i]].flags & optsActive) {
		if (strlen(optionList[optionIdx[i]].option) == strlen(comp)) {
			if (!memicmp(comp, optionList[optionIdx[i]].option, strlen(optionList[optionIdx[i]].option))) {
				foundText = i + 1;
				break;
			}
		}
		else if (comp[strlen(comp)-1] == '=') {
			if (!memicmp(comp, optionList[optionIdx[i]].option, strlen(optionList[optionIdx[i]].option))) {
				foundText = i + 1;
				break;
			}

		}
	 } /* For / if active */

	if (foundText) {
		int   winError;
		int   helpType = HELP_OPTION;

		showOptionText(&workWin, TEXT1, FALSE);
		showOptionText(&workWin, TEXT2, FALSE);
		showOptionText(&workWin, TEXT3, TRUE);

		SETWINDOW( &TextWin, workWin.row+workWin.nrows - 5,
		pText->win.col+2,1,MAXOPTIONTEXTLENGTH-1);

		showFldEdit (&name, &TextWin, KEY3,
		OptionText, MAXOPTIONTEXTLENGTH - 1,
		EditColor, TRUE, FALSE) ;

		action = 0;

		focus = FIELD;

		HelpNumber = oldHelpNumber = optionIdx [foundText - 1];

		event.key = WIN_NOOP;

		/* display edit text */
		memset(OptionText, ' ', MAXOPTIONTEXTLENGTH);

		if (strlen(temp) < MAXOPTIONTEXTLENGTH) {
			strcpy(OptionText, temp);
		}
		else {
			strncpy(OptionText, temp, MAXOPTIONTEXTLENGTH);
		}
		showFldText(&name, FALSE, FALSE);

		/* display description window */
		DescWindow = 0;
		winError = loadHelp(	/*	Create a text window */
		&pDescript,		/*	Pointer to text window */
		&DescWin,		/* Window descriptor */
		&helpType,

		/* Note that HelpNumber references the original list */
		HelpNc(optionList[HelpNumber].option, HelpTitles[0].context),

		OptionTextColor, /*	Default Attribute */
		SHADOW_SINGLE,			/*	Should this have a shadow */
		BORDER_NONE,	/*	Single line border */
		TRUE, FALSE,	/*	Scroll bars */
		TRUE);			/*	Should we remember what was below */

		if( winError == WIN_OK ) {
			DescWindow = 1;
			if( pDescript.vScroll.row > 0)
				paintScrollBar( &pDescript.vScroll, pDescript.attr,
				pDescript.size.row - pDescript.win.nrows, pDescript.corner.row );
		}
		else {
			errorMessage( WIN_NOMEMORY	);	/* Insufficient Memory */
			OptionText[0] = '\0';
			goto done;
		}

		pOption.cursor.col = 0;
		pOption.cursor.row = foundText - 1;
		pOption.corner.row = foundText - 1;
		if (pOption.corner.row + pOption.win.nrows > optioncount) {
			pOption.corner.row = optioncount - pOption.win.nrows;
		}
		event.key = WIN_NOOP;
		display = vOpt_ask(&pOption, &event);

		sendFldEditKey( &name, KEY_TAB, 0);

		*replace = 1;
	}
	else {
		showOptionText(&workWin, TEXT1, TRUE);
		showOptionText(&workWin, TEXT2, FALSE);
		showOptionText(&workWin, TEXT3, FALSE);

		SETWINDOW( &TextWin, workWin.row+workWin.nrows - 5,
		pText->win.col+2,1,MAXOPTIONTEXTLENGTH-1);

		showFldEdit (&name, &TextWin, KEY3,
		OptionText, MAXOPTIONTEXTLENGTH - 1,
		EditColor, TRUE, FALSE) ;

		action = 0;

		HelpNumber = optionIdx[0];
		oldHelpNumber = -1;

		event.key = KEY_UP;
		display = vOpt_ask(&pOption, &event);
	}


	for (;;) {
		int oldFocus = focus;
		int winError;

		display = 1;

		if (oldHelpNumber != HelpNumber) {
			int helpType = HELP_OPTION;

			*replace = 0;

			/* display edit text */
			memset(OptionText, ' ', MAXOPTIONTEXTLENGTH);
			strcpy(OptionText, optionList[HelpNumber].usage);

			showFldText(&name, FALSE, FALSE);

			/* display description window */
			DescWindow = 0;
			winError = loadHelp(	/*	Create a text window */
			&pDescript,		/*	Pointer to text window */
			&DescWin,			/* Window descriptor */
			&helpType,

			HelpNc(optionList[HelpNumber].option,HelpTitles[0].context),

			OptionTextColor, /*	Default Attribute */
			SHADOW_SINGLE,			/*	Should this have a shadow */
			BORDER_NONE,	/*	Single line border */
			TRUE, FALSE,	/*	Scroll bars */
			TRUE);			/*	Should we remember what was below */

			if( winError == WIN_OK ) {
				DescWindow = 1;
				if( pDescript.vScroll.row > 0)
					paintScrollBar( &pDescript.vScroll, pDescript.attr,
					pDescript.size.row - pDescript.win.nrows, pDescript.corner.row );
			}
			else {
				/*	Don't need this since LOADHELP takes care of it
				*	It was also WRONG because it said WIN_NOMEMORY
				* errorMessage( winError	);	Insufficient Memory
				*/
				OptionText[0] = '\0';
				goto done;
			}
		}
		oldHelpNumber = HelpNumber;


		/* first we get input,
		then we check for change of focus
		then we check for button click
		then we focus
		then we send key to the proper handler routine
		*/
		if( focus == OPTION )
			vWin_show_cursor(&pOption);

		get_input(INPUT_WAIT, &event);

		action = testButtonClick( &event, FALSE ) ? WIN_BUTTON : WIN_NOOP;

		if (action == WIN_BUTTON) {
			pushButton( LastButton.number );
			switch( LastButton.key ) {
			case KEY_ENTER:
				goto done;
			case KEY_ESCAPE:
				*replace = 0;
				OptionText[0] = '\0';
				goto done;
			case KEY_F1:
				if (testButton(KEY_F1, TRUE)) {
					showHelp( help, FALSE );
				}
				continue;
			case KEY_F3:
				if (testButton(KEY_F3, TRUE)) {
					showHelp( tutor, FALSE );
				}
				continue;
			}
		}

		/* figure out alt keys */
		switch (event.key) {
		case KEY1:	/*	Want's Option */
			focus = OPTION;
			goto changeFocus;
		case KEY2:	/*	Want's Description */
			focus = DESCRIPT;
			goto changeFocus;
		case KEY3:	/*	Want's Text Editor*/
			focus = FIELD;
			goto changeFocus;
		case KEY_F1:
			if (testButton(KEY_F1, TRUE)) {
				showHelp( help, FALSE );
			}
			continue;
		case KEY_F3:
			if (testButton(KEY_F3, TRUE)) {
				showHelp( tutor, FALSE );
			}
			continue;
		}

		/* figure out mouse click */
		if( event.click != MOU_NOCLICK) {
			int	act1, act2;
			act1 = inWin(&pOption, &event);
			act2 = inWin(&pDescript, &event);
			if (act1) {
				if (event.click == MOU_LSINGLE ||
				    event.click == MOU_LDOUBLE ||
				    event.click == MOU_LDRAG) {

					if (act1 == 1) {
						vWinPut_a(&pOption, pOption.cursor.row, 0, pOption.cursor.row, pOption.win.ncols, pOption.attr);

						pOption.cursor.row = pOption.corner.row + (event.y - pOption.win.row);
						pOption.cursor.col = pOption.corner.col + (event.x - pOption.win.col);
						pOption.cursor.col = 0;

						vWinPut_a(&pOption, pOption.cursor.row, 0, pOption.cursor.row, pOption.win.ncols, OptionHighColor);
					}
				}
				if( focus != OPTION ) {
					focus = OPTION;
					goto changeFocus;
				}
				goto process;
			}
			else if (act2) {
				if (event.click == MOU_LSINGLE ||
				    event.click == MOU_LDOUBLE ||
				    event.click == MOU_LDRAG) {
					if (act2 == 1) {
						pDescript.cursor.row = pDescript.corner.row + (event.y - pDescript.win.row);
						pDescript.cursor.col = pDescript.corner.col + (event.x - pDescript.win.col);
					}
				}
				if( focus != DESCRIPT ) {
					focus = DESCRIPT;
					goto changeFocus;
				}
				goto process;
			}
			else if (sendFldEditClick( &name, &event ) == FLD_OK) {
				if( focus != FIELD ) {
					focus = FIELD;
					goto changeFocus;
				}
				goto process;
			}
		}


		switch(toupper (event.key)) {
		case KEY_TAB:
			switch (focus) {
			case OPTION:
				focus = DESCRIPT;
				goto changeFocus;
			case DESCRIPT:
				focus = FIELD;
				goto changeFocus;
			case FIELD:
				focus = DBUTTONS;
				goto changeFocus;
			case DBUTTONS:
				if( testButton( event.key, FALSE == BUTTON_LOSEFOCUS )) {
					focus = OPTION;
					goto changeFocus;
				}
			}
			continue;

		case KEY_STAB:
			switch (focus) {
			case OPTION:
				focus = DBUTTONS;
				goto changeFocus;
			case DESCRIPT:
				focus = OPTION;
				goto changeFocus;
			case FIELD:
				focus = DESCRIPT;
				goto changeFocus;
			case DBUTTONS:
				if( testButton( event.key, FALSE == BUTTON_LOSEFOCUS )) {
					focus = FIELD;
					goto changeFocus;
				}
			}
			continue;

		case RESP_CANCEL:
			if( focus == FIELD ) {
				goto process;
			}
			/*	Fall into the ALTC processing */
		case KEY_ESCAPE:
			*replace = 0;
			OptionText[0] = '\0';
			testButton( event.key, TRUE );
			goto done;

		case RESP_OK:
			if( focus == FIELD ) {
				goto process;
			}
			/*	Fall into the ALTO processing */
		case KEY_ENTER:
			testButton( event.key, TRUE );
			goto done;
		}
		goto process;

changeFocus:
		switch( oldFocus ) {
		case OPTION:
			showOptionText(&workWin, TEXT1, FALSE);
			vWin_hide_cursor(&pOption);
			break;
		case DESCRIPT:
			showOptionText(&workWin, TEXT2, FALSE);
			break;
		case FIELD:
			showOptionText(&workWin, TEXT3, FALSE);
			sendFldEditKey( &name, KEY_STAB, 0);
			break;
		case DBUTTONS:
			setButtonFocus( FALSE, KEY_TAB );
			break;
		}
		switch( focus ) {
		case OPTION:
			showOptionText(&workWin, TEXT1, TRUE);
			break;
		case DESCRIPT:
			showOptionText(&workWin, TEXT2, TRUE);
			break;
		case FIELD:
			showOptionText(&workWin, TEXT3, TRUE);
			sendFldEditKey( &name, KEY_TAB, 0);
			break;
		case DBUTTONS:
			setButtonFocus( TRUE, event.key );
			break;
		}

process:
		askReturn = 0;
		switch (focus) {
		case OPTION:
			if( event.key != KEY_TAB && event.key != KEY_STAB )
				askReturn = vOpt_ask(&pOption, &event);

			HelpNumber = optionIdx [pOption.cursor.row];
			if (oldHelpNumber != HelpNumber) {
				if (DescWindow) {
					DescWindow = 0;
					vWin_destroy (&pDescript);
				}
			}
			break;
		case DESCRIPT:
			/*	if (DescWindow) vWin_show_cursor(&pDescript);  */
			if( event.key != KEY_TAB && event.key != KEY_STAB )
				askReturn = vDesc_ask(&pDescript, &event);

			break;
		case FIELD:
			if (event.key != KEY_TAB && event.key != KEY_STAB) {
				sendFldEditKey( &name, event.key, event.flag);
			}
			else {
				sendFldEditKey( &name, 0, 0);
			}
			break;
		}
		if (askReturn == WIN_BUTTON) break;
	}

done:

	dropButton(OptionButtons, NUMOPTIONBUTTONS);

	killFldEdit( &name);
	if (DescWindow) vWin_destroy(&pDescript);
	if (OptWindow)	vWin_destroy(&pOption);


	restoreButtons();
lastOut:

	if (behind) win_restore( behind, TRUE);

	pop_cursor();

	return (OptionText);

}
#pragma optimize ("",on)


int   inWin(
PTEXTWIN pText,
INPUTEVENT *event)
{
	if(event->x < pText->win.col ||
	    event->y < pText->win.row ||
	    event->x > pText->win.col + pText->win.ncols    || /* was -1 */
	event->y > pText->win.row + pText->win.nrows -1) {
		return(0);
	}
	/* are we on the scroll bar?? */
	if(event->x == pText->win.col + pText->win.ncols ) return(2);
	return(1);
}

/**
*
* Name		showOptionText
*
* Synopsis	void showOptionText( WINDESC *win, int which, int hiLite	)
*
* Parameters
*			WINDESC *win;			Base window we are working from
*			int which;				which window in a given type
*
* Description
*		This routine shows the three text lines on the screen
*
* Returns	No return
*
* Version	1.0
*/
void showOptionText(	/*	Dump the text words to the screen for print */
WINDESC *win,		/*	Print window */
int which,			/*	Which Words */
int hiLite )		/*	Selected or regular */
{
	WINDESC textWin;
	char attr = (char)(hiLite ? BaseColor : NormalColor) ;
	SETWINDOW( &textWin,
	win->row+1, win->col+2,
	1, win->ncols - 2 );

	switch( which ) {
	case TEXT1:
		textWin.ncols = 13;
		justifyString( &textWin,
		Title1,
		TITLE1TRIGGER,
		JUSTIFY_CENTER,
		attr,
		TriggerColor );
		break;
	case TEXT2:
		textWin.col = win->col + 16;
		textWin.ncols = win->ncols - 16;
		justifyString( &textWin,
		Title2,
		TITLE2TRIGGER,
		JUSTIFY_CENTER,
		attr,
		TriggerColor );
		break;
	case TEXT3:
		textWin.row = win->row+16;
		justifyString( &textWin,
		Title3,
		TITLE3TRIGGER,
		JUSTIFY_CENTER,
		attr,
		TriggerColor );
	}
}

/**
*
* Name		vOpt_ask - Keyboard interface for a window
*
* Synopsis	WINRETURN vOpt_ask(PTEXTWIN pText )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Accept mouse and keyboard events and move the window around
*	as required.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vOpt_ask(  /* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event)   /* Text window to run around in */
{
	WINRETURN action;
	WINRETURN retVal = WIN_OK;
	POINT oldCorner;

	/*	Force the window to be current if delayed */
	if( pText->delayed ) {
		WINDESC temp;
		SETWINDOW( &temp, 0, 0, pText->win.nrows, pText->win.ncols );
		pText->delayed = FALSE;
		vWin_show( pText, &temp );
	}

	/*	Put up scroll bars */
	if( pText->vScroll.row > 0 && pText->size.row > pText->win.nrows)
		paintScrollBar( &pText->vScroll, pText->attr,
		pText->size.row - pText->win.nrows, pText->corner.row );
	if( pText->hScroll.row > 0 )
		paintScrollBar( &pText->hScroll, pText->attr,
		pText->size.col - pText->win.ncols, pText->corner.col );

	/*	Force the cursor invisible */
	/*
	pText->cursorVisible = FALSE;
	vWin_updateCursor( pText );
	*/

	oldCorner = pText->corner;
	/*
	get_input(INPUT_WAIT, &event);
	*/
	if( event->key ) {
		action = vOpt_key( event->key );
	}
	else {
		action = vWin_mouse( pText, event );
	}

	vWinPut_a(pText, pText->cursor.row, 0, pText->cursor.row, pText->win.ncols, pText->attr);

	switch( action ) {
	case WIN_NOOP:
		goto dumpScreen;

	case WIN_MOVETO:
		pText->cursor.row = pText->corner.row;
		goto dumpScreen;
	case WIN_UP:
		if (pText->cursor.row) {
			pText->cursor.row--;
		}
		if (pText->corner.row > pText->cursor.row) {
			pText->corner.row--;
		}
		goto dumpScreen;
	case WIN_DOWN:
		if (pText->cursor.row - pText->corner.row < pText->win.nrows - 1) {
			if (pText->cursor.row < pText->size.row - 1) pText->cursor.row++;
		}
		else {
			if (pText->size.row - 1 - pText->win.nrows < pText->corner.row) goto dumpScreen;
			if (pText->cursor.row < pText->size.row) {
				pText->corner.row++;
				pText->cursor.row++;
			}
		}
		goto dumpScreen;
	case WIN_TOP:
		pText->corner.row = 0;
		pText->cursor.row = 0;
		goto dumpScreen;
	case WIN_BOTTOM:
		pText->corner.row = pText->size.row - pText->win.nrows;
		pText->cursor.row = pText->size.row - 1;
		goto dumpScreen;
	case WIN_PGUP:
		pText->corner.row -= pText->win.nrows;
		pText->cursor.row -= pText->win.nrows;
		if( pText->corner.row < 0 ) {
			pText->corner.row = 0;
			pText->cursor.row = 0;
		}
		goto dumpScreen;
	case WIN_PGDN:
		{
			WINDESC workWin;
			pText->corner.row += pText->win.nrows;
			pText->cursor.row += pText->win.nrows;
			if (pText->cursor.row >= pText->size.row)
				pText->cursor.row = pText->size.row - 1;
			pText->corner.row =
			    min( pText->corner.row, pText->size.row - pText->win.nrows );
dumpScreen:
			SETWINDOW( &workWin, pText->corner.row, pText->corner.col,
			pText->win.nrows, pText->win.ncols );

			vWinPut_a(pText, pText->cursor.row, 0, pText->cursor.row, pText->win.ncols, OptionHighColor);
			vWin_show( pText, &workWin );
			if( (pText->vScroll.row > 0) && oldCorner.row != pText->corner.row
			    && pText->size.row > pText->win.nrows)
				paintScrollBar( &pText->vScroll, pText->attr,
				pText->size.row - pText->win.nrows, pText->corner.row );
			if( (pText->hScroll.row > 0) && oldCorner.col != pText->corner.col )
				paintScrollBar( &pText->hScroll, pText->attr,
				pText->size.col - pText->win.ncols, pText->corner.col );


			break;
		}
	default:
		;
	}

	return action;
}

/**
*
* Name		vOpt_key - Analyze keycode and return action ( if any )
*
* Synopsis	WINRETURN vOpt_key(PTEXTWIN pText, KEYCODE key	)
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
WINRETURN vOpt_key(	/*	Take a key and return an appropriate action */
KEYCODE key )		/*	Actual key pressed */
{
	switch ( key ) {
	case KEY_HOME:
		return WIN_TOP;
	case KEY_UP:
		return WIN_UP;
	case KEY_PGUP:
		return WIN_PGUP;
	case KEY_LEFT:
		return WIN_LEFT;
	case KEY_RIGHT:
		return WIN_RIGHT;
	case KEY_PGDN:
		return WIN_PGDN;
	case KEY_END:
		return WIN_BOTTOM;
	case KEY_DOWN:
		return WIN_DOWN;
	}
	return WIN_NOOP;
}


/**
*
* Name		vDesc_ask - Keyboard interface for a window
*
* Synopsis	WINRETURN vDesc_ask(PTEXTWIN pText , INPUTEVENT *event)
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*
* Description
*		Accept mouse and keyboard events and move the window around
*	as required.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vDesc_ask(  /* Let a user run around a window */
PTEXTWIN pText,
INPUTEVENT *event)   /* Text window to run around in */
{
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
	if( pText->vScroll.row > 0 && pText->size.row > pText->win.nrows)
		paintScrollBar( &pText->vScroll, pText->attr,
		pText->size.row - pText->win.nrows, pText->corner.row );
	if( pText->hScroll.row > 0 )
		paintScrollBar( &pText->hScroll, pText->attr,
		pText->size.col - pText->win.ncols, pText->corner.col );

	/*	Force the cursor invisible */
	/*
	pText->cursorVisible = FALSE;
	vWin_updateCursor( pText );
	*/

	oldCorner = pText->corner;
	/*
	get_input(INPUT_WAIT, &event);
	*/
	if( event->key ) {
		action = vWin_key( pText, event->key );
	}
	else {
		action = vWin_mouse( pText, event );
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
	case WIN_TOP:
		pText->corner.row = 0;
		goto dumpScreen;
	case WIN_BOTTOM:
		pText->corner.row = pText->size.row - pText->win.nrows;
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
			if( (pText->vScroll.row > 0) && oldCorner.row != pText->corner.row
			    && pText->size.row > pText->win.nrows)
				paintScrollBar( &pText->vScroll, pText->attr,
				pText->size.row - pText->win.nrows, pText->corner.row );
			if( (pText->hScroll.row > 0) && oldCorner.col != pText->corner.col )
				paintScrollBar( &pText->hScroll, pText->attr,
				pText->size.col - pText->win.ncols, pText->corner.col );
			break;
		}
		/*
		case WIN_BUTTON:
		retVal = WIN_BUTTON;
		goto done;
		case WIN_ABANDON:
		goto done;
		*/
	default:
		;
	}

	return action;
}
