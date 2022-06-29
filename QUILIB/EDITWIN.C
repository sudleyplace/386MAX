/*' $Header:   P:/PVCS/MAX/QUILIB/EDITWIN.C_V   1.0   05 Sep 1995 17:02:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * EDITWIN.C								      *
 *									      *
 * Editor functions							      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <ctype.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "editwin.h"
#include "qprint.h"
#include "ui.h"
#include "windowfn.h"
#include "message.h"
#include "libcolor.h"
#include "myalloc.h"

#define TABTEST

/*	Definitions for this Module */
static char upDown[2] = {
	'\x18','\x19' };
static char leftRight[2] = {
	'\x1b','\x1a' };
static char filler = '\xB0';

WINRETURN tWinPut_c(		/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
WINDESC *win,			/*	Window to spray text into */
char *text );			/*	What text to write with default attr */

WINRETURN tWin_show(	/*	Dump the video buffer to screen USING TABS */
PTEXTWIN pText, 	/*	Text window to show in */
WINDESC *win ); /*	Subset to show */

int   locate_cursor(
PTEXTWIN pText,
int   row,
int   col);

int   locate_display(
PTEXTWIN pText,
int   row,
int   col);

#define tfixup_corner fixup_corner

/* Local functions to call the callbacks if they exist */
/* Note that we've made some variables local to this module to */
/* minimize parameter passing. */
static PTEXTWIN spText;
static INPUTEVENT event;
static int CurrentLine;
static char **spaline;
static int *spwlines;

static int near Lhighlight_area (void)
{
  if (highlight_areaCB)
	return ((*highlight_areaCB) (spText, CurrentLine));
  else	return (0);
} /* Local highlight_area */

static int near Lsave_changes (void)
{
  if (save_changesCB)
	return ((*save_changesCB) (spText, event.key));
  else	return (0);
} /* Local save_changes */

static int near Lcursor3 (KEYCODE key)
{
  if (cursor3CB)
	return ((*cursor3CB) (spText, key, &CurrentLine, spaline, spwlines));
  else	return (0);
} /* Local cursor3 */

static int near Lcursor4 (void)
{
  if (cursor4CB)
	return ((*cursor4CB) (spText, event.key, &CurrentLine, spwlines));
  else	return (cursor4b (spText, event.key, &CurrentLine, spwlines));
} /* Local cursor4 */

static int near Lcursor5 (void)
{
  if (cursor5CB)
	return ((*cursor5CB) (spText, event.key, &CurrentLine, spaline, spwlines));
  else	return (0);
} /* Local cursor5 */


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
WINRETURN vWin_edit_ask(	/*	Let a user run around a window */
PTEXTWIN pText, 	   /*	Text window to run around in */
char  *name,		/* full name of file being edited */
char  *line[],		/* actual data file */
int *lines,			      /* number of lines in file */
int   help,		/*	Help screen */
int   tutor,		/*	Tutorial screen */
int   browseOnly,	/* are we in browse only mode */
int   newFile)		/* if new file, start out in edit mode */
{
	WINRETURN action;
	WINRETURN retVal = WIN_OK;
	POINT oldCorner, oldCursor, oldDisplay;
	int i;
	int display, OldLine, unmark, save_cursor, save_corner, oldLines, redraw;
	WINDESC workWin;
	KEYCODE unGetKey;
	int optenabled = 0;	/* Innocent until proven guilty */

	spText = pText; /* Save a local copy for callbacks */
	spaline = line;
	spwlines = lines;

	/* Determine whether option editor can EVER be called here */
	if (CB_option_editor && CB_option_replace && CB_option_insert) {

	 char ptest_drv[_MAX_DRIVE];
	 char ptest_dir[_MAX_DIR];
	 char ptest_fname[_MAX_FNAME];
	 char ptest_ext[_MAX_EXT];

	 _splitpath (name, ptest_drv, ptest_dir, ptest_fname, ptest_ext);
	 if (	stricmp (ptest_ext, ".bat") &&
		stricmp (ptest_ext, ".sys") &&
		stricmp (ptest_ext, ".cfg") &&
		stricmp (ptest_ext, ".ini") &&
		stricmp (ptest_fname, "extrados") )
	  optenabled = 1;	/* OK to call option editor */

	}

	/* used only to overcome level 4 error */
	/* p = line[0]; */
	EditorFileName = name;

	/* initialize globals */
	markon = 0;
	markWasOn = 0;
	mark[0].row = mark[0].col = 0;	 /* start */
	mark[1].row = mark[1].col = 0;	 /* current page start*/
	mark[2].row = mark[2].col = 0;	 /* current page finish */
	mark[3].row = mark[3].col = 0;	 /* finish */

	VIEW = 0; /* Enable edits */
	if (newFile) {
#if EDITF6
		setButtonText(KEY_F6, ViewBtext, VIEW_TRIG);
		disableButton(KEY_F8, !optenabled);
#endif /* if EDITF6 */
	}
#if EDITF6
	else {
		VIEW = 1;
		disableButton(KEY_F8, TRUE);
	}
#else
	disableButton(KEY_F8, !optenabled);
#endif /* if EDITF6 */

	BROWSE = 1;
	INSERT = 1;
	unGetKey = 0;

	/* initial changed flags */
	FileChanged = 0;
	PageChanged = 0;
	for (i = 0; i < pText->win.nrows; i++) {
		LineChanged[i] = 0;
	}

	CurrentLine = OldLine = 0;

	BLOCK_EXISTS = 0;
	DELETE_BLOCK_EXISTS = 0;

	pText->size.row = *lines;
	pText->size.col = MAXSTRING;

	/* Put up scroll bars */
	if( pText->vScroll.row != -1 )
		paintScrollBar( &pText->vScroll, pText->attr,
		max (pText->size.row - pText->win.nrows, 1),
		pText->corner.row );

	if( pText->hScroll.row != -1 )
		paintScrollBar( &pText->hScroll, pText->attr,
		pText->size.col - pText->win.ncols, pText->corner.col );

	display_status(pText, CurrentLine);

	if (browseOnly) {
		/*	Force the cursor invisible */
		pText->cursorVisible = FALSE;
		vWin_updateCursor( pText );
	}
	else {
		BROWSE = 0;
		/*	Force the cursor visible */
		pText->cursorVisible = TRUE;
		vWin_updateCursor( pText );
	}

	disableButton(KEY_F7, TRUE);
	SAVEON = 0;
	setButtonText( KEY_ESCAPE, DoneEsc, DONEESCTRIG );


top:

	action = 0;
	while(action != WIN_ABANDON) {

		display = 1;
		unmark = 0;

		oldCorner = pText->corner;
		oldCursor = pText->cursor;
		oldDisplay = pText->display;
		oldCursor.row += CurrentLine;
		oldLines   = *lines;

		if (unGetKey) {
			event.key = unGetKey;
			event.flag = KEYFLAG_RSHFT;
			event.click = 0;
			unGetKey = 0;
		}
		else {
			get_input(INPUT_WAIT, &event);
		}
		/* end new */

		if( event.key ) {
			action = vNew_key( pText, event.key );
		}
		else {
			action = vNew_mouse( pText, &event, &CurrentLine );
		}

		SHIFT = 0;
		if (event.key && event.flag &KEYFLAG_RSHFT) SHIFT = 1;
		if (event.key && event.flag &KEYFLAG_LSHFT) SHIFT = 1;

		if (action == WIN_BUTTON) {
			pushButton( LastButton.number );
			switch( LastButton.key ) {
			case KEY_F1:
				showHelp(help, FALSE);
				continue;
			case KEY_F2:
				doPrint( pText , !browseOnly ? P_EDITOR : P_BROWSER, 0, help, FALSE	);
				continue;
			case KEY_F3:
				showHelp(tutor, FALSE);
				continue;
#if EDITF6
			case KEY_F6:
				VIEW = !VIEW;
				if (VIEW) {
					setButtonText(KEY_F6, EditBtext, EDIT_TRIG);
					disableButton(KEY_F8, TRUE);
				}
				else {
					setButtonText(KEY_F6, ViewBtext, VIEW_TRIG);
					disableButton(KEY_F8, !optenabled);
				}
				continue;
#endif /* if EDITF6 */
			case KEY_F7:
				if (FileChanged) {
					SaveLine(pText, line, CurrentLine);

					sayWaitWindow( &pText->win, SAVING );	/* Inform user that we are saving the file */
					if (fileSave(name, line, *lines)) {
						/* save file */
						FileChanged = 0;

						disableButton(KEY_F7, TRUE);
						SAVEON = 0;
					}
					killWait();
				}
				continue;
			case KEY_F8:

				if (!optenabled)
					break;

				/* save changes for certain actions */
				display = Lsave_changes ();
				if (display && PageChanged) {
					SaveLine(pText, line, CurrentLine);
				}

				{
					char *p;
					int   replace;

					p = (*CB_option_editor) (pText, pText->cursor.row, &replace, HELPOPTEDITOR, tutor);
					if (replace) {
						display = (*CB_option_replace) (pText, p, pText->cursor.row);
						FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
						display = 2;
						goto show;
					}
					else if (p[0] != '\0') {
						display = (*CB_option_insert) (pText, p, &CurrentLine, line, lines);
						if (display) {
							FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
							display = 4;
							goto show;
						}
					}
				}
				continue;

			case KEY_ESCAPE:
				SaveLine(pText, line, CurrentLine);
				goto done;

			/*	This has been hooked in to handle asq and flipping windows.
			*	Since this case is BROWSE only - No check for changes made.
			*/
			case KEY_APGUP:
				if( altPageOK )
					return KEY_APGUP;
				break;
			case KEY_APGDN:
				if( altPageOK )
					return KEY_APGDN;
				break;
			}
		}
		else {		 /* if (action == WIN_NOOP) { */
			if (action == WIN_NOOP && !event.key) {
				/* make sure we are within the edit window */
				if(event.x < pText->win.col ||
				    event.y < pText->win.row ||
				    event.x > pText->win.col + pText->win.ncols - 1 ||
				    event.y > pText->win.row + pText->win.nrows - 1) {
					goto skip;
				}
				/* now make sure we are within the file window */
				if ( (CurrentLine + pText->corner.row + (event.y - pText->win.row)) >=
				    *lines) {
					goto skip;
				}


				if (event.click == MOU_LSINGLE || event.click == MOU_LDOUBLE) {

					pText->cursor.row = pText->corner.row + (event.y - pText->win.row);
					pText->display.col = pText->corner.col + (event.x - pText->win.col);
					pText->cursor.col = locate_display(pText, pText->cursor.row, pText->display.col);
					display = Lcursor3 (0);
					if (display) {
						display = 3;
						goto show;
					}
				}
				else if (event.click == MOU_LDRAG) {

					display = Lcursor3 (KEY_F4);

					pText->cursor.row = pText->corner.row + (event.y - pText->win.row);
					pText->display.col = pText->corner.col + (event.x - pText->win.col);
					pText->cursor.col = locate_display(pText, pText->cursor.row, pText->display.col);

					display = Lcursor3 (KEY_F4);
					if (display) {
						display = 3;
						goto show;
					}
				}
				else if (event.click == MOU_LSINGLEUP) {
					goto skip;
				}
				else {
					display = Lcursor3 (0);
				}
			}
			else {

				if (BROWSE) {
					switch(action) {
					case WIN_UP	:
						event.key = KEY_CUP;
						action = 0;
						break;
					case WIN_DOWN	:
						event.key = KEY_CDOWN;
						action = 0;
						break;
					case WIN_LEFT	:
						event.key = KEY_CCLEFT;
						action = 0;
						break;
					case WIN_RIGHT	:
						event.key = KEY_CCRIGHT;
						action = 0;
						break;
					}
				}

				/* If it's INSTALL or ASQ, action is always 0 */
				switch(action) {
				case WIN_MOVETO:
					display = 4;
					if (CurrentLine != OldLine) {
						/* pText->corner.row = 0;
						pText->cursor.row = 0;
						*/
						if (CurrentLine > *lines - pText->win.nrows) {
							CurrentLine = *lines - pText->win.nrows;
							if (CurrentLine < 0) {
								CurrentLine = 0;
								pText->cursor.row = *lines - 1;
							}
						}
					}
					else {
						display = 3;
						/* FIX ME FIX ME */
						pText->cursor.col = locate_display(pText, pText->cursor.row, pText->corner.col);
					}
					goto show;
				case WIN_UP	:
					if (!event.key)
						event.key = KEY_CUP;
					else
						event.key = KEY_UP;
					break;
				case WIN_DOWN	:
					if (!event.key)
						event.key = KEY_CDOWN;
					else
						event.key = KEY_DOWN;
					break;
				case WIN_LEFT	:
					if (!event.key)
						event.key = KEY_CCLEFT;
					else
						event.key = KEY_LEFT;
					break;
				case WIN_RIGHT	:
					if (!event.key)
						event.key = KEY_CCRIGHT;
					else
						event.key = KEY_RIGHT;
					break;
				case WIN_PGUP	 :
					event.key = KEY_PGUP;
					break;
				case WIN_PGDN	 :
					event.key = KEY_PGDN;
					break;
				case WIN_PGLEFT :
					event.key = KEY_CPGUP;
					break;
				case WIN_PGRIGHT:
					event.key = KEY_CPGDN;
					break;
				case WIN_TOP	 :
					event.key = KEY_CHOME;
					break;
				case WIN_BOTTOM :
					event.key = KEY_CEND;
					break;

				case WIN_HOME	 :
					event.key = KEY_HOME;
					break;	/*	added by curt */
				case WIN_END	 :
					event.key = KEY_END;
					break; /*	added by curt */
				}

				/* save changes for certain actions */
				display = Lsave_changes ();
				if (display && PageChanged) {
					SaveLine(pText, line, CurrentLine);
				}

				/* text marking stuff */

				/* FIX SHIFT and other Cursor movement not allowed
				shouldn't kill text select */

				markWasOn = 0;
				if (SHIFT &&
				    (event.key == KEY_LEFT  || event.key == KEY_RIGHT  ||
				    event.key == KEY_UP    || event.key == KEY_DOWN   ||
				    event.key == KEY_HOME  || event.key == KEY_END	 ||
				    event.key == KEY_PGUP  || event.key == KEY_PGDN   ||
				    event.key == KEY_CEND  || event.key == KEY_CHOME  ||
				    event.key == KEY_CLEFT || event.key == KEY_CRIGHT )) {
					display = Lcursor3 (KEY_F3);
				}
				else if (event.key == KEY_ALTBKSP) {
					display = Lcursor3 (event.key);
					goto show;
				}
				else if (SHIFT &&     /* ignore */
				(event.key == KEY_CUP  || event.key == KEY_CDOWN)) {
					goto show;
				}
				else if ((SHIFT &&
				    (event.key == KEY_DEL ||
				    event.key == KEY_INS)) ||
				    event.key == KEY_CINS) {

					if (SHIFT && event.key == KEY_INS && BLOCK_EXISTS && markon) {
						unGetKey = KEY_INS;
						event.key = KEY_DEL;
						SHIFT = 0;
					}

					display = Lcursor3 (event.key);
					goto show;
				}
				else if (event.key == KEY_SF3 ||
				    event.key == KEY_SF4 ||
				    event.key == KEY_SF5 ||
				    event.key == KEY_SF6 ||
				    event.key == KEY_SF7 ||
				    event.key == KEY_SF8 ||
				    event.key == KEY_F5 ||
				    event.key == KEY_CF5) {
					display = Lcursor3 (event.key);
					goto show;
				}
				else if (markon &&
				    (event.key == KEY_DEL || event.key == KEY_BKSP)) {
					display = Lcursor3 (event.key);
					goto show;
				}
				/* Make sure we only replace highlighting with a printable key */
				else if (isascii(event.key) && (event.key&0x00ff) > 31 && markon) {
					int oldSHIFT = SHIFT;
					SHIFT = 0;
					unmark = Lcursor3 (KEY_DEL);
					SHIFT = oldSHIFT;
					markWasOn = 1;
				}
				else {
					unmark = Lcursor3 (0);
				}

				/* cursor movement */
				display = Lcursor4 ();
				if (display) {
					if (markon) {
						Lhighlight_area ();
						display = 3;
					}
					goto show;
				}
				/* printable characters */
				display = Lcursor5 ();
				if (display) {
					goto show;
				}
			}
		}

show:

		redraw = 0;
		if (CurrentLine != OldLine || display == 4 || unmark == 4) {
			OldLine = CurrentLine;
			/* blank and load the screen */
			LoadScreen(pText, line, CurrentLine, *lines);
			if (markWasOn) {
				markWasOn = 0;
				display = Lcursor5 ();
				redraw = 1;
			}
			/* new jhk 8/19 */
			redraw = 1;
			display = 0;
		}
		if (display == 3 || display == 4 || unmark == 3) {
			/* re-draw the entire display */
			redraw = 1;
		}
		if (display == 2 || unmark == 2) {
			/* fix to only re-draw one line */
			redraw = 1;
		}

		save_cursor = pText->cursor.col;
		save_corner = pText->corner.col;

#ifdef TABTEST

		/* adjust the cursor position to temporarily account for TABS.
		meanwhile if we've moved from one line to another and are in
		the same column (as in up or down arrow) or we are on the same
		line and same column, but there are fewer lines, then we must
		move the relative cursor, and adjust for the actual character
		position based on the new display position.

		Finally, adjust the corner column in case we've run off the display.
		*/

		if (oldCursor.row != CurrentLine + pText->cursor.row ||
		    oldLines != *lines) {
			if (oldCursor.col == save_cursor) {
				/* NEW JHK 8/18 new row so we must adjust the cursor position */
				save_cursor = locate_display(pText,  pText->cursor.row,
				oldDisplay.col);
				pText->cursor.col = locate_cursor(pText,  pText->cursor.row,
				save_cursor);
			}
			else {
				pText->cursor.col = locate_cursor(pText,  pText->cursor.row,
				save_cursor);
			}
		}
		else {
			pText->cursor.col = locate_cursor(pText,  pText->cursor.row,
			save_cursor);
		}
		pText->display.col = pText->cursor.col;

		/* was == */
		if (pText->cursor.col >= MAXSTRING) pText->cursor.col = MAXMINUS1;   /* new 7/14 jhk */

		/* adjust the corner.col value to account for the display */
		if (tfixup_corner(pText) == 3) redraw = 1;

#endif

		if (redraw) {
			SETWINDOW( &workWin, pText->corner.row, pText->corner.col,
			pText->win.nrows, pText->win.ncols );
#ifdef TABTEST
			tWin_show( pText, &workWin );
#else
			vWin_show( pText, &workWin );
#endif
		}


		if (oldCursor.row != CurrentLine + pText->cursor.row) {
			if( (pText->vScroll.row != -1)) 		 /* was && oldCorner.row != pText->corner.row ) */
				paintScrollBar( &pText->vScroll, pText->attr,
				max (pText->size.row - pText->win.nrows, 1),
				CurrentLine ); /* was just pText->corner.row */
		}
		if (oldCursor.col != pText->cursor.col) {
			if( (pText->hScroll.row != -1 ) && oldCorner.col != pText->corner.col )
				paintScrollBar( &pText->hScroll, pText->attr,
				pText->size.col - pText->win.ncols, pText->corner.col );
		}

		display_status(pText, CurrentLine);

		if (FileChanged && !SAVEON) {
			disableButton(KEY_F7, FALSE);
			SAVEON = 1;
		}
		else if (!FileChanged && SAVEON) {
			disableButton(KEY_F7, TRUE);
			SAVEON = 0;
		}

		vWin_updateCursor( pText );

		pText->cursor.col = save_cursor;

skip:
		;

	}

done:

	if (FileChanged) {
		int answer;
		answer = askMessage(210);
		if (toupper (answer) == RESP_YES) {
			sayWaitWindow( &pText->win, SAVING );	/* Inform user that we are saving the file */
			fileSave(name, line, *lines);
			killWait();
		}
		if (answer == KEY_ESCAPE) {
			goto top;
		}
		FileChanged = 0;
	}

	return WIN_BUTTON;
}
#pragma optimize ("",on)

int   display_status(
PTEXTWIN pText,
int	 CurrentLine)
{
	char  string[20];
	int	 len;
	WINDESC tempWin;

	/* blank it out first */
	memset(string, ' ', 20);

	tempWin.row    = pText->win.row-1;
	tempWin.nrows  = 1;
	tempWin.ncols  = 18;
	tempWin.col    = pText->win.col + pText->win.ncols - 18 + 1;

	/*	Blast out the text */
	wput_csa( &tempWin, string, EditorHighColor);

	/* write out the header */
	sprintf(string, "%d/%d,%3d ",
	CurrentLine + pText->cursor.row + 1,
	pText->size.row,
	pText->cursor.col + 1);

	len = strlen(string);
	tempWin.row = pText->win.row-1;
	tempWin.nrows = 1;
	tempWin.ncols = len + 1;

	tempWin.col = pText->win.col + pText->win.ncols - len;	 /* was  + 1 */

	/*	Blast out the text */

	wput_csa( &tempWin, string, EditorHighColor);

	/*
	if( triggerPos != -1 ) {
	tempWin.col += triggerPos;
	tempWin.ncols = 1;
	wput_a( &tempWin, &tAttr );
	}
	*/

	return(0);
}

int   clear(
PTEXTWIN pText)
{
	WINDESC tempWin = pText->win;

	/*	Initialize the data space to blanks */
	if( pText->data ) {
		wordset( (LPWORD)pText->data, VIDWORD( pText->attr, ' ' ), pText->numChar );
	}

	wput_sca( &tempWin, VIDWORD( pText->attr, ' ' ));               /*      Clear the screen too */
	return(0);
}

int lnbc(
char *string,
int  length)
{
	int i;

	i = length - 1;

	do {
		if (*(string+i) != 32) {
			return(i+1);
		}
		i--;
	}
	while (i > -1);
	return(0);
}

int   LoadScreen(
PTEXTWIN fWin,
char  *line[],
int   CurrentLine,
int   lines)
{
	int	 i, len;
	WINDESC tempWin;
	char temp[MAXSTRING + 1];
	SETWINDOW( &tempWin, 0, 0, 1, MAXSTRING);

	memset(temp, ' ', MAXSTRING);

	for(i = 0; i < fWin->win.nrows; i++) {
		if (CurrentLine + i >= lines) {

#ifdef TABTEST
			tWinPut_c( fWin, &tempWin, temp);
#else
			vWinPut_c( fWin, &tempWin, temp);
#endif
			tempWin.row++;
			continue;
		}
		/*
		tempWin.ncols = strlen( line[CurrentLine + i]) - 1;
		vWinPut_c( fWin, &tempWin, line[CurrentLine + i]);
		*/
		len = 0;
		if (line[CurrentLine + i])
			len = strlen(line[CurrentLine + i]);	    /* was -1 */
		if (len > 0) {
			memcpy(temp, line[CurrentLine + i], len);
#ifdef TABTEST
			tWinPut_c( fWin, &tempWin, temp);
#else
			vWinPut_c( fWin, &tempWin, temp);
#endif
			memset(temp, ' ', len);
		}
		else {
#ifdef TABTEST
			tWinPut_c( fWin, &tempWin, temp);
#else
			vWinPut_c (fWin, &tempWin, temp);
#endif
		}
		tempWin.row++;
	}
	return(0);
}

/**
*
* Name		vWinPut_s - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN vWinPut_s(PTEXTWIN pText, int row, int col, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row,					Row to start text on
*	int col,					col to start on
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
WINRETURN vWinPut_s(		/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
int   row,	     /* row starting position */
int   col,	     /* col starting position */
char *text )			/*	What text to write with default attr */
{
	PCELL startPos, thisCell;
	int ncols = 0;

	WINDESC workWin;

	startPos = pText->data + (row * pText->size.col + col);

	/*	Now will fit in window */

	thisCell = startPos;

	while (*text) {
		thisCell++->ch = *text++;
		ncols++;
	}

	/*	Now dump the modified part out to the real screen */
	SETWINDOW( &workWin, row, col, 1,ncols);

#ifdef TABTEST
	return tWin_show( pText, &workWin );
#else
	return vWin_show( pText, &workWin );
#endif
}




/**
*
* Name		vWinPut_a - Write an attribute to the screen
*
* Synopsis	WINRETURN vWinPut_a(PTEXTWIN pText,
*	    int row1, int col1,
*	    int row2, col2, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	int row1,					Row to start text on
*	int col1,					col to start on
*	int row2,					Row to end text on
*	int col2,					col to end on
*	char *text );				What text to write with default attr
*
* Description
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN vWinPut_a(		/*	Write an attribute into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
int   row1,	     /* starting row */
int   col1,	     /* starting column */
int   row2,	     /* ending row */
int   col2,	     /* ending column */
int   attr )			/*	What attribute */
{
	PCELL startPos, thisCell;
	int   count;

	startPos = pText->data + (row1 * pText->size.col + col1);
	thisCell = startPos;

	count =  (row2 * pText->size.col + col2) -
	    (row1 * pText->size.col + col1);

	while (count > 0) {
		thisCell++->attr = ( char )attr;
		count--;
	}

	/*
	do {
	thisCell++->attr = ( char )attr;
	count--;
	} while (count >= 0);
	*/

	return(0);
}

int   SaveLine(
PTEXTWIN fWin,
char  *line[],
int   CurrentLine)
{
	int  len, i;
	char temp[MAXSTRING+1];

	if (!PageChanged) return(0);
	PageChanged = 0;

	for (i = 0; i <fWin->win.nrows; i++) {
		if (!LineChanged[i]) continue;

		LineChanged[i] = 0;

		vWinGet_s( fWin, i, temp);
		len = lnbc(temp, 256);
		temp[len] = '\0';

		if (line[CurrentLine + i]) {
			if (strcmp(temp, line[CurrentLine + i])) {
				if (strlen(temp) == strlen(line[CurrentLine + i])){
					strcpy(line[CurrentLine + i], temp);
				}
				else {
					char *t;
					if ((t = salloc(temp)) != NULL) {
						my_free(line[CurrentLine + i]);
						line[CurrentLine + i] = t;
					}
				}
			}
		}
		else {
			line[CurrentLine + i] = salloc(temp);
		}
	}
	return(0);
}




/**
*
* Name		vNew_mouse - Analyze mouse event and return action ( if any )
*
* Synopsis	WINRETURN vNew_mouse(PTEXTWIN pText, INPUTEVENT *event	)
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
WINRETURN vNew_mouse(		/*	Translate a mouse action into a window movement */
PTEXTWIN pText, 		/* Window that will get the action */
INPUTEVENT *event,		/* what mouse event occured */
int	   *CurrentLine)	/*	What line are we on */
{
	WINRETURN retVal = WIN_NOOP;
	if( pText->hScroll.row != -1 ) {
		retVal = NewScroll( &pText->hScroll, event,
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

		case WIN_TOP:
			return WIN_HOME;
		case WIN_BOTTOM:
			return WIN_END;
		}
	}

	if( pText->vScroll.row != -1 ) {
		retVal = NewScroll( &pText->vScroll, event,
		max (pText->size.row - pText->win.nrows, pText->win.nrows), CurrentLine ); /* */
		if( retVal != WIN_NOOP )
			return retVal;
	}

	/*	Nothing in the window - Check buttons on the bottom */
	return testButtonClick( event, FALSE ) ? WIN_BUTTON : WIN_NOOP;
}

/**
*
* Name		NewScroll - Analyze mouse event and return action ( if any )
*
* Synopsis	WINRETURN NewScroll(WINDESC *win, INPUTEVENT *event, int max, int current )
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
WINRETURN NewScroll(		/*	Translate a mouse action into a window movement */
WINDESC *win,			/* Window that will get the action */
INPUTEVENT *event,		/*	What mouse event occured */
int max,				/*	Max number of items */
int *current )			/*	Where we are right now */
{
	int mousePos;
	enum {
		NOWAY, LEFTRIGHT, UPDOWN	}
	direction;
	int cursorPos;
	int length;
	int oldPos = *current;
	int clipDrag = event->click == MOU_LDRAG;
	int moveMouse = FALSE;
	static int lastDrag = NOWAY;

	direction = win->nrows == 1 ? LEFTRIGHT : UPDOWN;

	if( clipDrag && direction != lastDrag )
		return WIN_NOOP;

	if (max <= 0)
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
			}
			else if ( mousePos > length-3 ) {
				mousePos = length - 3;
				event->x = win->col + mousePos;
				moveMouse = TRUE;
			}
		}
	}
	else {
		mousePos = event->y - win->row ;
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
			}
			else if ( mousePos > length-3 ) {
				mousePos = length - 3;
				event->y = win->row + mousePos;
				moveMouse = TRUE;
			}
		}
	}

	if( moveMouse ) {
		set_mouse_pos( event->x, event->y );
	}

	/*	Event above scroll bar */
	if( mousePos < 0 )
		return WIN_NOOP;				/*	Above top of scroll bar */
	if( mousePos >= length	)
		return WIN_NOOP;					/*	Too far down */

	switch( event->click ) {
	case MOU_LDRAG:
		*current = ((int)((long)(mousePos-2) * max)+(length-6)) / (length-5);
		return WIN_MOVETO;
	case MOU_LDOUBLE:
	case MOU_LSINGLE:
		lastDrag = direction;
		if( mousePos == 0)
			return event->click == MOU_LDOUBLE ? WIN_TOP : WIN_PGUP;
		if( mousePos == 1 )
			return WIN_UP;				/*	Clicked on up arrow */
		if( mousePos == length - 1)
			return event->click == MOU_LDOUBLE ? WIN_BOTTOM : WIN_PGDN;
		if( mousePos == length - 2 )
			return WIN_DOWN;			/*	Clicked on bottom arrow */

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
		if(cursorPos == mousePos)
			return WIN_OK;		/*	Between bottom arrow and slide bar */
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
* Name		tWin_show - Show a section of the visible window USING TABS
*
* Synopsis	WINRETURN tWin_show(PTEXTWIN pText, WIN *win )
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
WINRETURN tWin_show(	/*	Dump the video buffer to screen */
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
	}
	else {
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
	}
	else {
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

	startPos = (WORD *)(pText->data + (work.row * pText->size.col));

	/* most of the below code is new for expanding tabs */
	for( ;work.nrows; work.nrows--, actual.row++ ) {
		WORD  tmp[256];
		WORD  *to;
		char  *from;
		int   cnt, i;

		from = (char *)startPos;
		to = tmp;

		i = 0;
		cnt = 0;
		while (i < work.col) {
			if (cnt) {
				cnt--;
				if (!cnt) {
					from += sizeof(WORD);
				}
			}
			else if (*from == 9) {
				cnt = (TabStop - 1) - (i % TabStop);
				if (!cnt) from += sizeof(WORD);
			}
			else {
				from += sizeof(WORD);
			}
			i++;
		}
		for (i = 0; i < actual.ncols; i++) {
			if (cnt) {
				cnt--;
				*(to++) = VIDWORD(*(from+1), ' ');
				if (!cnt) {
					from += sizeof(WORD);
				}
			}
			else if (*from == 9) {
				cnt = (TabStop - 1) - ((i+work.col) % TabStop);
				*(to++) = VIDWORD(*(from+1), ' ');
				if (!cnt) from += sizeof(WORD);
			}
			else {
				*(to++) = VIDWORD(*(from+1), *from);
				from += sizeof(WORD);
			}
		}

		wput_ca( &actual, tmp );
		startPos += pText->size.col;
	}
	vWin_updateCursor(pText);
}

/**
*
* Name		zWin_show - Show a section of the visible window USING TABS
*
* Synopsis	WINRETURN zWin_show(PTEXTWIN pText, WIN *win )
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
WINRETURN zWin_show(	/*	Dump the video buffer to screen */
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
	}
	else {
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
	}
	else {
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

	/* most of the below code is new for expanding tabs */
	for( ;work.nrows; work.nrows--, actual.row++ ) {
		WORD  tmp[256];
		WORD  *to;
		char  *from;
		int   cnt, i;

		from = (char *)startPos;
		to = tmp;

		cnt = 0;
		for (i = 0; i < actual.ncols; i++) {
			if (cnt) {
				cnt--;
				*(to++) = VIDWORD(*(from+1), ' ');
				if (!cnt) {
					from += sizeof(WORD);
				}
			}
			else if (*from == 9) {
				cnt = (TabStop - 1) - (i % TabStop);
				*(to++) = VIDWORD(*(from+1), ' ');
				if (!cnt) from += sizeof(WORD);
			}
			else {
				*(to++) = VIDWORD(*(from+1), *from);
				from += sizeof(WORD);
			}
		}

		wput_ca( &actual, tmp );
		startPos += pText->size.col;
	}
	vWin_updateCursor(pText);
}

int   locate_cursor(
PTEXTWIN pText,
int   row,
int   col)
{
	WORD *startPos; /*	Where in full window are we */
	char  *from;
	int	 i, newCol = 0;

	startPos = (WORD *)(pText->data + (row * pText->size.col)  );
	from = (char *)startPos;

	for (i = 0; i < col; i++) {
		if (*from == 9) newCol += (TabStop - 1) - (newCol % TabStop);
		newCol++;
		from += sizeof(WORD);
	}
	return(newCol);
}

int   locate_display(
PTEXTWIN pText,
int   row,
int   col)
{
	WORD *startPos; /*	Where in full window are we */
	char  *from;
	int	 newChr, newCol = 0;

	startPos = (WORD *)(pText->data + (row * pText->size.col)  );
	from = (char *)startPos;

	newChr = 0;
	for (;;) {
		if (*from == 9) newCol += (TabStop - 1) - (newCol % TabStop);
		newCol++;
		newChr++;
		from += sizeof(WORD);
		if (newCol > col) break;
	}
	return(newChr-1);
}

/**
*
* Name		vNew_key - Analyze keycode and return action ( if any )
*
* Synopsis	WINRETURN vNew_key(PTEXTWIN pText, KEYCODE key	)
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
WINRETURN vNew_key(	/*	Take a key and return an appropriate action */
PTEXTWIN pText, 	/*	Window to consider */
KEYCODE key )		/*	Actual key pressed */
{
	int retVal = pText->cursor.row;

	switch ( key ) {
	case KEY_HOME:
		return WIN_HOME ;
	case KEY_CHOME:
		return WIN_TOP ;
	case KEY_UP:
		return WIN_UP ;
	case KEY_PGUP:
		return WIN_PGUP ;
	case KEY_LEFT:
		return WIN_LEFT ;
	case KEY_RIGHT:
		return WIN_RIGHT;
	case KEY_PGDN:
		return WIN_PGDN;
	case KEY_END:
		return WIN_END;
	case KEY_CEND:
		return WIN_BOTTOM;
	case KEY_DOWN:
		return WIN_DOWN;
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
* Name		tWinPut_c - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN tWinPut_c(PTEXTWIN pText, WINDESC *win, char *text )
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
WINRETURN tWinPut_c(		/*	Write a text string into the window */
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
#ifdef TABTEST
		tWin_show( pText, win );
#else
	vWin_show( pText, win );
#endif
}

int fixup_corner(
PTEXTWIN pText)
{
   if ((pText->cursor.col - pText->corner.col) >= pText->win.ncols) {
      pText->corner.col = (pText->cursor.col - pText->win.ncols) + 1;
      return(3);
   }
   if (( pText->cursor.col < pText->corner.col)) {
	   pText->corner.col = pText->cursor.col;
	   return(3);
   }

   return(0);
}

#if 0
int tfixup_corner(
PTEXTWIN pText)
{
	int   iret = 0;

	/*
	pText->corner.col = locate_cursor(pText,  pText->cursor.row,
	pText->corner.col);
	*/
	if ((pText->cursor.col - pText->corner.col) >= pText->win.ncols) {
		pText->corner.col = (pText->cursor.col - pText->win.ncols) + 1;
		iret = 3;
	}
	else if (( pText->cursor.col < pText->corner.col)) {
		pText->corner.col = pText->cursor.col;
		iret = 3;
	}

	/*
	pText->corner.col = locate_display(pText,  pText->cursor.row,
	pText->corner.col);
	*/
	return(iret);
}
#endif

/* Basic cursor movement needed for browser */
int   cursor4b(
PTEXTWIN pText,
KEYCODE c,
int   *CurrentLine,
int   *lines)
{
   int	 display, disp;
   int	col;

   char tmp[MAXSTRING+1];

   display = *CurrentLine;

   display = 1;

   switch (c) {

   case KEY_CHOME:
      pText->cursor.col = 0;
      pText->cursor.row = 0;
      *CurrentLine = 0;
      pText->corner.col = 0;
      pText->corner.row = 0;
      return(3);

   case KEY_CEND:
      *CurrentLine = *lines - pText->win.nrows;
      pText->cursor.row = pText->win.nrows - 1;
      if (*CurrentLine < 0) {
	 *CurrentLine = 0;
	 pText->cursor.row = *lines - 1;
      }

      /* now we go to end of line */
      pText->cursor.col = getLineLength(*CurrentLine + pText->cursor.row);

      fixup_corner(pText);
      return(3);

   case KEY_CPGUP:
      display = 1;

      if (pText->corner.col == 0) {
	 pText->cursor.col = 0;
      }
      else {
	 col = pText->corner.col;
	 pText->corner.col -= pText->win.ncols;
	 if (pText->corner.col <= 0) {
	    pText->corner.col = 0;
	 }
	 if (col != pText->corner.col) display = 3;

#ifdef TABTEST
	 display = 3;
	 pText->cursor.col = locate_display(pText, pText->cursor.row, pText->corner.col);
#else
	 if (pText->cursor.col < pText->corner.col) {
		 pText->cursor.col = pText->corner.col;
		 display = 3;
	 }
#endif
      }
#ifdef TABTEST
#else
      fixup_cursor(pText);
#endif
      return(display);

   case KEY_CPGDN:
      display = 1;

      if (pText->corner.col == MAXSTRING - pText->win.ncols) {
	 pText->cursor.col = MAXSTRING - 1;
      }
      else {
	 pText->corner.col += pText->win.ncols;
	 if (pText->corner.col > MAXSTRING - pText->win.ncols) {
	    pText->corner.col = MAXSTRING - pText->win.ncols;
	 }
      }
      display = 3;

#ifdef TABTEST
      pText->cursor.col = locate_display(pText, pText->cursor.row, pText->corner.col);
#else
      if (pText->cursor.col < pText->corner.col) {
	 pText->cursor.col = pText->corner.col;
	 display = 3;
      }
#endif
      return(display);

   case KEY_HOME:
      pText->cursor.col = 0;
      if (pText->corner.col) {
	 pText->corner.col = 0;
	 return(3);
      }
      return(1);

   case KEY_END:

      vWinGet_s(pText, pText->cursor.row, tmp);
      pText->cursor.col = lnbc (tmp, MAXSTRING);   /* new 7/14 jhk */
      if (pText->cursor.col == MAXSTRING) pText->cursor.col = MAXMINUS1;   /* new 7/14 jhk */

      disp = fixup_corner(pText);
      if (disp == 3) return(3);

      return(1);

   case KEY_UP:
      if (pText->cursor.row) {
	 pText->cursor.row--;
	 return(1);
      }
      else {
	 if (*CurrentLine) {
	    (*CurrentLine)--;
	    return(3);
	 }
      }
      return(1);

   case KEY_DOWN:
      if (pText->cursor.row < pText->win.nrows - 1) {
	 if (*CurrentLine + pText->cursor.row < (*lines - 1)) pText->cursor.row++;
	 return(1);
      }
      else {
	 if (*lines - pText->win.nrows - 1 < *CurrentLine) return(1);
	 if (pText->cursor.row < *lines) (*CurrentLine)++;
	 return(3);
      }
      return(1);

   case KEY_PGUP:
       (*CurrentLine) -= pText->win.nrows;
       if (*CurrentLine < 0) {
	 *CurrentLine = 0;
	 pText->cursor.row = 0;
       }
       return(3);

   case KEY_PGDN:
       (*CurrentLine) += pText->win.nrows;

       if (*CurrentLine + pText->win.nrows >= *lines) {
	 *CurrentLine = *lines - pText->win.nrows;
	 pText->cursor.row = pText->win.nrows - 1;
	 if (*CurrentLine < 0) {
	    *CurrentLine = 0;
	    pText->cursor.row = *lines - 1;
	 }
       }
       return(3);

   case KEY_LEFT:
      if (pText->cursor.col) {
	      pText->cursor.col--;
      /* new jhk 8/19
	   if (pText->cursor.col < pText->corner.col) {
		 pText->corner.col = pText->cursor.col;
		 return(3);
	   }
      */
      }
      return(1);

   case KEY_RIGHT:
      {
	 int   position;

	 display = 1;

      /* new jhk 8/19
	 if (pText->cursor.col < MAXSTRING - 1) {
		 pText->cursor.col++;
		 display = 2;
	 }

	 disp = fixup_corner(pText);
	 if (disp == 3) display = 3;
      */

			position = locate_cursor(pText, pText->cursor.row, pText->cursor.col+1);
	 if (position < MAXSTRING) {
		 pText->cursor.col++;
		 display = 2;
	 }
	 return(display);
      }

   case KEY_CUP:
      if (*CurrentLine) {
	 (*CurrentLine)--;
	 return(3);
      }
      return(1);

   case KEY_CDOWN:
      if (*lines - pText->win.nrows - 1 < *CurrentLine) return(1);
      if (pText->cursor.row < *lines) (*CurrentLine)++;
      return(3);

   case KEY_CCRIGHT:
      display = 1;
      pText->corner.col ++;
      if (pText->corner.col > MAXSTRING - pText->win.ncols) {
	 pText->corner.col = MAXSTRING - pText->win.ncols;
      }
      display = 3;

#ifdef TABTEST
      pText->cursor.col = locate_display(pText, pText->cursor.row, pText->corner.col);
#else
      if (pText->cursor.col < pText->corner.col) {
	 pText->cursor.col = pText->corner.col;
	 display = 3;
      }
#endif
      return(display);

   case KEY_CCLEFT:
      display = 1;
      col = pText->corner.col;
      pText->corner.col--;
      pText->cursor.col--;
      if (pText->corner.col <= 0) {
	 pText->corner.col = 0;
	 pText->cursor.col = 0;
      }
      if (col != pText->corner.col) display = 3;

#ifdef TABTEST
      pText->cursor.col = locate_display(pText, pText->cursor.row, pText->corner.col);
#else
      if (pText->cursor.col < pText->corner.col) {
	 pText->cursor.col = pText->corner.col;
	 display = 3;
      }
#endif
#ifdef TABTEST
#else
      fixup_cursor(pText);
#endif
      return(display);

   }

   return(0);
} /* cursor4b () */
