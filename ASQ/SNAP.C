/*' $Header:   P:/PVCS/MAX/ASQ/SNAP.C_V   1.0   05 Sep 1995 15:04:48   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SNAP.C								      *
 *									      *
 * Routines for ASQ Snapshot						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <ctype.h>
#include <dos.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <sys\types.h>
#include <sys\stat.h>

/*	Program Includes */
#include "commfunc.h"
#include "engine.h"
#include "fldedit.h"
#include "intmsg.h"
#include "libcolor.h"
#include "menu.h"
#include "surface.h"
#include "asqtext.h"
#include "ui.h"
#include "myalloc.h"


#define HEIGHT ( 17 - 6 + 1)
#define WIDTH  ( 66 - 12 + 1)
#define DESCHEIGHT 7
#define DESCWIDTH (WIDTH)
enum { DIRTEXT, DESCTEXT, DBUTTONS };

char currentTitle[ SNAPTITLESIZE] = { '\0' };

int askSnapShot(
char *fileName, 	/*	Name to write to */
char *title );		/*	Title to use */
void showSnapText( WINDESC *win, int which, int hiLite );
void snapDesc( char *name );

/*	Program Code */
/**
*
* Name		snapClear - load the current machine state
*
* Synopsis	int snapClear(void )
*
* Parameters
*
* Description
*		Call engine control to purge and then re-analyze the current
*	system.
*
* Returns
*
* Version	2.0
*/
void snapClear( void )
{
	int rtn;
	ReadFile[0] = '\0';
	engine_control( CTRL_SYSPURGE, NULL, 0 );
	intmsg_setup(12);
	do_intmsg ( EvalFmt, Hardware );
	rtn = engine_control( CTRL_SYSINIT, tutorWorkSpace, WORKSPACESIZE );
	intmsg_clear();
	if( rtn != 0 )
		errorMessage( 500 );
	SnapMenu.items[SIPOS].type = ITEM_DISABLED;
}


/**
*
* Name		snapLoad - load the current machine state
*
* Synopsis	int snapLoad(void )
*
* Parameters
*
* Description
*		Show the third level menu of all snapshots in the current directory
*	then let them choose a snapshot to load.  Other can be selected for
*	the filename dialog and then open it.
*
* Returns
*
* Version	2.0
*/
void snapLoad( void )			/*	Get a new snap shot from a menu pick */
{
	#define NUMSFILEMENUITEMS 15

	char orgName[MAXFILELENGTH];
	PMENU pSnapMenu = NULL;
	PMENUITEM pItem;
	int fileCount = 0;
	int forceLoad = FALSE;
	int returnCode;
	int menuReturn;
	int numAlloced;
	struct find_t snapFile;

	strcpy( orgName, ReadFile );

	pSnapMenu =
		my_malloc( sizeof( MENUINFO ) + ((NUMSFILEMENUITEMS+2)*sizeof(MENUITEM)));

	if( !pSnapMenu ) {
		errorMessage( WIN_NOMEMORY );
		goto done;
	}

	numAlloced = NUMSFILEMENUITEMS;
	pSnapMenu->info = SnapFileMenuInfo;
	pItem = pSnapMenu->items;

	/*	Now run down the list of files in the directory
	*	and load them in 1 at a time
	*/
	if( !_dos_findfirst( SnapSearchSpec, _A_NORMAL, &snapFile )) {
		do {
			int len = strlen( snapFile.name );

			/*	Build a menu item for this thingy */
			if( fileCount == numAlloced ) {
				PMENU newItem;
				numAlloced += NUMSFILEMENUITEMS;
				newItem = my_realloc( pSnapMenu,
						sizeof( MENUINFO ) + (numAlloced+2)*sizeof(MENUITEM) );
				if( newItem )
					pSnapMenu = newItem;
				else
					break;		/*	No more memory so stop */
			}
			fileCount++;
			*pItem = SnapMenuItems[0];
			pItem->returnCode = pItem->pos.row = fileCount;
			pItem->textLen = len;
			strcpy( pItem->text, snapFile.name );
			pItem++;
		} while( _dos_findnext( &snapFile ) == 0 );
	}
	/*	Add separator and other as required */
	if( fileCount ) {
		*pItem = SnapMenuItems[1];
		fileCount++;
		pItem->returnCode = pItem->pos.row = fileCount;
		pItem++;
	}
	*pItem = SnapMenuItems[2];
	pItem->pos.row = fileCount+1;
	pSnapMenu->info.active = 1;
	pSnapMenu->info.nItems = fileCount+1;
	pSnapMenu->info.win.nrows = fileCount > NUMSFILEMENUITEMS
			? NUMSFILEMENUITEMS + 4
			: fileCount + 3;

	pSnapMenu->info.active = 0;
	pSnapMenu->info.topItem = 0;

	if( fileCount ) {
		saveButtons();
		addButton( AsqButtons, NUMASQBUTTONS, NULL );
		addButton( &SnapLoadButton, 1, NULL );
		showAllButtons();
	}

getNameAgain:
	showMenu( pSnapMenu, MENU_HIGHLIGHTED );

getInnerName:
	menuReturn = askMenu( pSnapMenu, NULL, &returnCode, FALSE );

	switch( menuReturn ) {
	case MENU_BUTTON:
		switch( LastButton.key ) {
		case KEY_F6:
			pushButton( LastButton.number );
			snapDesc( pSnapMenu->items[ pSnapMenu->info.active ].text );
			goto getInnerName;
		case KEY_ESCAPE:
			hideMenu( pSnapMenu );
			if( forceLoad )
				goto restore;
			else
				goto done;
		}
	case MENU_ABANDON:
		hideMenu( pSnapMenu );
		if( forceLoad )
			goto restore;
		else
			goto done;
	case MENU_DIRECT:
	/*	case MENU_SELECT:  Shouldn't need this */
		if( returnCode == SNAPFILEOTHER ) {
			/*	Turn off all menus */
			showMenu( (PMENU)&AsqTopMenu, MENU_DISABLED );
			showMenu( (PMENU)&SnapMenu, MENU_DISABLED );
			showMenu(pSnapMenu, MENU_DISABLED );

			returnCode = askFileName( ReadFile );

			showMenu( (PMENU)&AsqTopMenu, MENU_VISIBLE );
			showMenu( (PMENU)&SnapMenu, MENU_HIGHLIGHTED );
			showMenu(pSnapMenu, MENU_HIGHLIGHTED );

			if( returnCode == KEY_ESCAPE )
				goto getInnerName;
		} else {
			strcpy( ReadFile, pSnapMenu->items[returnCode-1].text );
		}

		/*	Readfile contains the name - Let's do it */
		hideMenu( pSnapMenu );
		sayWait( Loading );	/* Inform user that we are loading the file */

		strcpy(tutorWorkSpace,ReadFile);
		returnCode = engine_control(CTRL_SYSREAD,
			tutorWorkSpace, WORKSPACESIZE);
		killWait();
		switch (returnCode )
		{
		case 0:
			SnapMenu.items[SIPOS].type = ITEM_ACTIVE;
			break;
		case -2:
			errorMessage( 511 );
			goto getNameAgain;
		case -1:
			forceLoad = TRUE;
			errorMessage( 512 );
			goto getNameAgain;
		}
	}

	goto done;

restore:
	strcpy( ReadFile, orgName );
	if( strlen( ReadFile ))
	{
		strcpy(tutorWorkSpace,ReadFile);
		returnCode = engine_control(CTRL_SYSREAD,
			tutorWorkSpace, WORKSPACESIZE);
		switch( returnCode )
		{
		case 0 :
			SnapMenu.items[SIPOS].type = ITEM_ACTIVE;
			goto done;
		case -2:
			errorMessage( 511 );
			break;
		case -1:
			errorMessage( 512 );
			break;
		}
	}
	/*	Force a load of current system if read failed or no read */
	snapClear();

done:
	if( fileCount ) {
		restoreButtons();
	}

	if( pSnapMenu )
		my_free( pSnapMenu );
}

/**
*
* Name		snapSave - write the current machine state to disk
*
* Synopsis	int snapSave(void )
*
* Parameters
*
* Description
*		Prompt for a file name and title
*	system.
*
* Returns
*
* Version	1.0
*/
void snapSave( void )			/*	Dump a snapshot to disk */
{
	if( strlen( WriteFile ) == 0 )
		strcpy( WriteFile, DefaultSnapShot );

editAgain:
	if( askSnapShot( WriteFile, currentTitle ) == KEY_ESCAPE ) {
		WriteFile[0] = '\0';
		return;
	} else {
		int returnCode;
		int tempError;
		struct stat buffer;
		tempError = stat( WriteFile, &buffer );
		if( tempError == 0)
		{
			/*	File exists - Do you want to overwrite */
			if( askMessage( 509 ) != 'Y' )
				goto editAgain; 	/*	Not great but it get's you there */
		}
		/*	Force the current title to match what the user said and write it */
		sayWait( Saving );	/* Inform user that we are saving the file */
		returnCode = engine_control( CTRL_PUTTITLE, currentTitle, 0);
		returnCode = engine_control(CTRL_SYSWRITE,WriteFile,0);
		killWait();
		if (returnCode != 0) {
			errorMessage( 511 );
			goto editAgain;
		}
	}
}

/**
*
* Name		askSnapShot - Get a name and description for a snapshot
*
* Synopsis	int askSnapShot(char *name, char *title )
*
* Parameters
*
* Description
*		Prompt for a file name and title
*	system.
*
* Returns
*
* Version	1.0
*/
int askSnapShot(
char *fileName,
char *title )
{
	FLDITEM eName;
	FLDITEM eTitle;
	INPUTEVENT event;
	int focus = DIRTEXT;
	int retVal = KEY_ESCAPE;
	WINDESC win;
	WINDESC textWin;
	void *behind = NULL;

	push_cursor();
	hide_cursor();


	SETWINDOW( &win,
			(ScreenSize.row - HEIGHT) / 2,
			(ScreenSize.col - WIDTH) / 2,
			HEIGHT,
			WIDTH );

	/*	Remember what we are stomping on */
	behind = win_save( &win, TRUE );
	if( !behind )
		goto lastOut;
	if( saveButtons() != BUTTON_OK )
		goto lastOut;

	/*	Put up the window */
	wput_sca( &win, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, SaveTitle, NULL, BaseColor );

	showSnapText( &win, DIRTEXT, TRUE );

	SETWINDOW( &textWin, win.row+3, win.col+2, 1, win.ncols - 5 );
	showFldEdit( &eName, &textWin, SNAPDIRKEY,
				 fileName, MAXFILELENGTH,
				 EditColor, TRUE, FALSE );

	showSnapText( &win, DESCTEXT, FALSE );
	textWin.row += 3;
	showFldEdit( &eTitle, &textWin, SNAPDIRKEY,
				 title, SNAPTITLESIZE - 1,
				 EditColor, TRUE, FALSE );
	sendFldEditKey( &eName, KEY_TAB, 0 );

	SnapButtons[2].pos.row = win.row + 9;
	SnapButtons[3].pos.row = win.row + 9;

	addButton( SnapButtons, NUMSNAPBUTTONS,NULL );
	disableButton( KEY_F2, TRUE );
	showAllButtons();

	for(;;) {
		int oldFocus = focus;
		get_input(INPUT_WAIT, &event);
		if( event.click ) {
			if( sendFldEditClick( &eName, &event ) == FLD_OK ) {
				focus = DIRTEXT;
				goto setFocus;
			} else if( sendFldEditClick( &eTitle, &event ) == FLD_OK ) {
				focus = DESCTEXT;
				goto setFocus;
			}

			if( !testButtonClick( &event, TRUE ) )
				continue;

		} else {
			switch( event.key ) {
			case SNAPDIRKEY:
				focus = DIRTEXT;
				goto setFocus;
			case SNAPDESCKEY:
				focus = DESCTEXT;
				goto setFocus;
			case KEY_TAB:
				switch( focus ) {
				case DIRTEXT:
					focus = DESCTEXT;
					break;
				case DESCTEXT:
					focus = DBUTTONS;
					break;
				case DBUTTONS:
					if( testButton( KEY_TAB, TRUE ) == BUTTON_LOSEFOCUS )
						focus = DIRTEXT;
					else
						continue;
					break;
				}
				goto setFocus;
			case KEY_STAB:
				switch( focus ) {
				case DIRTEXT:
					focus = DBUTTONS;
					break;
				case DESCTEXT:
					focus = DIRTEXT;
					break;
				case DBUTTONS:
					if( testButton( KEY_STAB, TRUE ) == BUTTON_LOSEFOCUS )
						focus = DESCTEXT;
					else
						continue;
					break;
				}
				goto setFocus;
			default:
				switch ( toupper (event.key) ) {
				case RESP_CANCEL:
				case RESP_OK:
					switch( focus ) {
					case DIRTEXT:
						sendFldEditKey( &eName, event.key, event.flag );
						continue;
					case DESCTEXT:
						sendFldEditKey( &eTitle, event.key, event.flag );
						continue;
					}
				}
				if( testButton( event.key, TRUE ) == BUTTON_NOOP ) {
					if( focus == DIRTEXT )
						sendFldEditKey( &eName, event.key, event.flag );
					else
						sendFldEditKey( &eTitle, event.key, event.flag );
					continue;
				}
			}
		}

		switch( LastButton.key ) {
		case KEY_F1:
			showHelp(ASQHELPDIALOGS, FALSE);
			continue;
		case KEY_ESCAPE:
			retVal = KEY_ESCAPE;
			goto done;
		case KEY_ENTER:
			retVal = KEY_ENTER;
			goto done;
		}

setFocus:
		if( oldFocus != focus ) {
			switch( oldFocus ) {
			case DIRTEXT:
				showSnapText( &win, DIRTEXT, FALSE );
				sendFldEditKey( &eName, KEY_STAB,0 );
				break;
			case DESCTEXT:
				showSnapText( &win, DESCTEXT, FALSE );
				sendFldEditKey( &eTitle, KEY_STAB, 0	);
				break;
			case DBUTTONS:
				setButtonFocus( FALSE, event.key );
				break;
			}
			switch( focus ) {
			case DIRTEXT:
				showSnapText( &win, DIRTEXT, TRUE	);
				sendFldEditKey( &eName, KEY_TAB,0 );
				break;
			case DESCTEXT:
				showSnapText( &win, DESCTEXT, TRUE	);
				sendFldEditKey( &eTitle, KEY_TAB,0 );
				break;
			case DBUTTONS:
				setButtonFocus( TRUE, event.key );
				break;
			}
		}
		continue;
	}

done:
	/*	Don't do a kill fld edit because it doesn't alloc anything in this case */
	/*	Put the screen back the way it was */
	restoreButtons();
lastOut:
	if( behind )
		win_restore( behind, TRUE );
	pop_cursor();
	return retVal;
}

/**
*
* Name		showSnapText
*
* Synopsis	void showSnapText( WINDESC *win, int which, int hiLite	)
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
void showSnapText(	/*	Dump the text words to the screen for Snap */
	WINDESC *win,		/*	Snap window */
	int which,			/*	Which Words */
	int hiLite )		/*	Selected or regular */
{
	WINDESC textWin;
	char attr = (char)(hiLite ? BaseColor : NormalColor) ;
	char trigger = TriggerColor;
	if( hiLite == -1 ) {
		attr = DisableColor;
		trigger = DisableColor;
	}

	SETWINDOW( &textWin,
				win->row+2, win->col+1,
				1, WIDTH - 2 );
	switch( which ) {
	case DIRTEXT:
		justifyString( &textWin,
					SnapDir,
					SNAPDIRTRIGGER,
					JUSTIFY_CENTER,
					attr,
					trigger );
		break;
	case DESCTEXT:
		textWin.row = win->row+5;
		justifyString( &textWin,
					SnapDesc,
					SNAPDESCTRIGGER,
					JUSTIFY_CENTER,
					attr,
					trigger );
		break;
	}
}

/**
*
* Name		snapDesc
*
* Synopsis	void snapDesc( char *name)
*
* Parameters
*		char *name		Name of snapshot file to pry apart
*
* Description
*		This routine shows the description embeded in a snapshot file
*
* Returns	No return
*
* Version	1.0
*/
void snapDesc( char *name )
{
	char msgString[80];
	INPUTEVENT event;
	void *behind;
	WINDESC win;
	ENGSNAPINFO info;
	int rtn;

	if( name );

	SETWINDOW( &win,
			(ScreenSize.row - DESCHEIGHT) / 2,
			(ScreenSize.col - DESCWIDTH) / 2,
			DESCHEIGHT,
			DESCWIDTH );

	/*	Remember what we are stomping on */
	behind = win_save( &win, TRUE );
	if( !behind )
		return;
	if( saveButtons() != BUTTON_OK ) {
		my_free( behind );
		return;
	}

	/*	Put up the window */
	wput_sca( &win, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &win );
	box( &win, BOX_DOUBLE, TypeMessage[ERRTYPE_MESSAGE], NULL, BaseColor );

	strcpy( msgString, SnapDescColon );
	win.row ++;
	win.col += 2;
	win.ncols -= 4;
	wrapString( &win, msgString, &NormalColor );



	strcpy( info.name, name );
	rtn = engine_control(CTRL_SNAPINFO,&info,0);

	if( rtn == 0 && strlen( info.title ) )
		strcpy( msgString, info.title );
	else
		strcpy( msgString, NoneText );

	win.row ++;
	wrapString( &win, msgString, &BaseColor );
	MessageButtons[0].pos.row = win.row + DESCHEIGHT - 5;
	MessageButtons[0].pos.col = ( ScreenSize.col - MAXBUTTONTEXT ) / 2;

	addButton( MessageButtons, NUMMESSAGEBUTTONS, NULL );
	showAllButtons();
	setButtonFocus( TRUE, KEY_TAB );

	/*	Wait for button Press */
	for(;;) {
		get_input( INPUT_WAIT, &event );
		if( event.key ) {
			switch( testButton( event.key, TRUE ) ) {
			case BUTTON_NOOP:
			case BUTTON_OK:
				continue;
			case BUTTON_LOSEFOCUS:
				testButton( event.key, TRUE );	/*	Force focus back */
				continue;
			default:
				goto cleanup;
			}
		} else if( testButtonClick( &event, TRUE ) != 0)
			break;
	}
cleanup:
	restoreButtons( );
	win_restore( behind, TRUE );
}
