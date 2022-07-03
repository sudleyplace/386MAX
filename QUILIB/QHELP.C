/*' $Header:   P:/PVCS/MAX/QUILIB/QHELP.C_V   1.2   30 May 1997 12:09:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * QHELP.C								      *
 *									      *
 * Functions to display text from a help file				      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <malloc.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <io.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "dmalloc.h"
#include "help.h"
#include "libcolor.h"
#include "libtext.h"
#include "message.h"
#include "myalloc.h"
#include "qprint.h"
#include "qhelp.h"
#include "qwindows.h"
#include "ui.h"
#include "windowfn.h"

#define OWNER
#include "intHelp.h"


/*	Definitions for this Module */
#define MAXTITLE 50
#define QUICKHELPWIDTH 80	/*	Allow for 40 characters */
#define HELPDATAWIDTH  160	/*	Allow for 80 characters for data */

enum { HOT_PREV, HOT_NEXT };
void setHotButton( PTEXTWIN pText, int request );
int specialHelp(			/*	Menu callback function */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	INPUTEVENT *event		/*	What event to process - Could be null */
);


/*
*	This is probably trickier than I should be but
*	HelpInfo is defined by text.h.	 (User owned )	 This guy
*	only needs to know where it is, not the specific info about
*	it.
*/
extern HELPDEF HelpInfo[1];
extern BUTTON HelpButtons[ ];

/*
*	Remember that there is a matching structure in help.c
*	to carry the context numbers around.  Help last is in surface.h
*	The correct answer for the order of this file is that it match
*	the order of the condensed file.  FOund dependencie where
*	files with content and index must precede content must precede none
*	Appears that lookup finds the next occurence regardless of file identity
*/
int backCount = 0;			/*	How many back counts are there */
nc lastBackContext = 0; 	/*	What was the last context pushed */
HELPTYPE lastHelpType = 0;		/*	What type this back count is from */

/*
*  I made these global because they were so popular and the
*	settext, gettext, freetext need them as a static set
*/
int prevNextFlag;

/*	Program Code */
/**
*
* Name		startHelp - Open up the help file.
*
* Synopsis	int startHelp( char *helpName, int numContexts	)
*
* Parameters
*		char *helpName			Name of file to _open
*
* Description
*		Open up the help file specified in helpName
*	Look up all contexts and return context number
*
* Returns	0 for no errors - 1 for an error exit
*
* Version	1.0
*/
int startHelp( char *helpName, int numContexts	) /*	Open up the help file system */
{
	int contextNum;
	char fullName[80];
	char fullContext[80];

	if (helpName[1] == ':') {
		/* A dirty trick to allow the caller to provide a fully */
		/* qualified help file name. */
		strcpy(fullName, helpName);
	}
	else {
		/* Otherwise, the help file is in the same directory as
		/* the .EXE file */
		get_exepath( fullName, sizeof(fullName));
		strcat( fullName, helpName);
	}

	if (_access(fullName,0) == -1) {
		/* Say "help file not found" */

		errorMessage( 308 );
		return TRUE;
	}

	/*	Now we have the first context  - Find start of tutorial ( I hope ) */
	for( contextNum = HELP_HELP; contextNum < HELP_LAST; contextNum++ ) {
		HelpTitles[contextNum].context = contextNum == HELP_HELP ?
			HelpOpen( fullName ) :
			HelpNc( HelpTitles[contextNum].name,
				HelpTitles[0].context );
		if( HelpTitles[contextNum].context < HELPERR_MAX ) {
			if( contextNum == 0 ) {
				/*	It didn't work - Report why */
				errorMessage( (int)(LOWORD( HelpTitles[contextNum].context ) + 300 ));
				HelpTitles[contextNum].context = 0;
				return TRUE;
			}	/*	Otherwise ignore it */
			HelpTitles[contextNum].context = HelpTitles[0].context;
		}

		HelpTitles[contextNum].context =
			(HelpTitles[contextNum].context & 0xFFFF0000) + 1;

		strcpy( fullContext, HelpTitles[contextNum].name );
		strcat( fullContext, HelpContents );
		HelpTitles[contextNum].contentsContext =
				HelpNc( fullContext,
					HelpTitles[contextNum].context );

		strcpy( fullContext, HelpTitles[contextNum].name );
		strcat( fullContext, HelpIndex );
		HelpTitles[contextNum].indexContext =
				HelpNc( fullContext,
					HelpTitles[contextNum].context );

		/*	Do this so that print knows where to start or stop
		*	It is important only for QSHELP ASHELP TUTORIAL and GLOSSARY
		*/
		if( HelpTitles[contextNum].contentsContext )
			HelpTitles[contextNum].context =
				HelpTitles[contextNum].contentsContext & 0xFFFF0000L;
	}

	/*	Now load up all the contexts that are known */
	for( contextNum = 0; contextNum < numContexts; contextNum++ ) {
		if( HelpInfo[contextNum].context ) {
			strcpy( fullContext, HelpTitles[HelpInfo[contextNum].type].name );
			strcat( fullContext, HelpInfo[contextNum].context );
			HelpInfo[contextNum].contextNumber =
				HelpNc( fullContext,
						HelpTitles[HelpInfo[contextNum].type].context );

			/*	Change these so we look in correct place for prev/next */
			if( HelpInfo[contextNum].type == HELP_ASQLEARN )
				HelpInfo[contextNum].type = HELP_TUTORIAL;

#ifdef CURTDBG
			if( !HelpInfo[contextNum].contextNumber )
				fprintf( stdaux,
				"\n\rContext %s - type %d not found",
				 HelpInfo[contextNum].context,
				 HelpTitles[HelpInfo[contextNum].type].context	);
#endif
		}
	}
	/*	This now means that we can throw all those nasty text strings away */
	return FALSE;
}


/**
*
* Name		endHelp - Kill the help file.
*
* Synopsis	int endHelp( void )
*
* Parameters
*		No parameters
*
* Description
*		Close the help file and release all memory
*
* Returns	No return
*
* Version	1.0
*/
void endHelp( void )		/*	Kill all parts of the help system */
{
	if( HelpTitles[HELP_HELP].context ) {
		HelpTitles[HELP_HELP].context = 0;			/*	Kill all help */
		HelpClose( HelpTitles[HELP_HELP].context );
	}

#ifndef OS2_VERSION
	freeCallbackHelp();
#endif
}

/**
*
* Name		showHelp - Show the help for the requested string
*
* Synopsis	int showHelp( int helpNumber, int fromPrint )
*
* Parameters
*		int helpNumber			What id to display the help for
*		int fromPrint			Was this called from print
*
* Description
*		Save the current state, find the context, show help, let them
*	do things and return
*
* Returns	No return
*
* Version	1.0
*/
#pragma optimize ("leg",off)
void showHelp(				/*	How the help screen */
	int helpNumber, 	/*	What help screen to show */
	int fromPrint ) 	/*	Was this called from print */
{
	int winError;
	int hotJump;
	nc nextContext;
	HELPTYPE HelpWinType = -1;
	void *behind;
	WINDESC tWin;
	nc context;
	int initialContext = TRUE;
	nc originalPrev=0, originalNext=0;
	char contsave[40];

	/*	Specify where to put the window */
	HelpWinDesc.row = 2;
	HelpWinDesc.col = 1;
	HelpWinDesc.nrows = ScreenSize.row - 4;
	HelpWinDesc.ncols = ScreenSize.col - 4;

	/*	Save what's behind us */
	behind = win_save( &HelpWinDesc, TRUE );
	if( !behind ) {
		errorMessage( WIN_NOROOM );
		return;
	}

	if( saveButtons() != BUTTON_OK ) {
		win_restore( behind, TRUE );
		return;
	}


	push_cursor();
	hide_cursor();

	/*	Specify the color to put it in */
	wput_sca( &HelpWinDesc, VIDWORD( HelpColor, ' ' ));
	shadowWindow( &HelpWinDesc );

	/*	Adjust the window inside the box */
	HelpWinDesc.row += 1;
	HelpWinDesc.col += 2;
	HelpWinDesc.nrows -= 5;
	HelpWinDesc.ncols -= 5;

	addButton( HelpButtons, NUMHELPBUTTONS, NULL );
	if( fromPrint ) 		/*	don't allow a recursive call to help */
		disableButton( KEY_F2, TRUE );

	disableButton( KEY_F1, TRUE );

	/*	If there is no index ( Like glossary ) disable index button */
	disableButton( INDEXTRIGGER, HelpTitles[HelpWinType].indexContext == 0 );
	/*	I don't know where this is used.  If it is, it needs a */
	/*	*TRIGGER definition in LIBTEXT.H for localized versions. */
	disableButton( 'C', HelpTitles[HelpWinType].contentsContext == 0 );

	setButtonFocus( TRUE, KEY_TAB );
	showAllButtons();

#ifdef DOSTRIP
	/*	Strip out all backtraces */
	for( ; HelpNcBack();	);
	backCount = 0;
#endif

	context = HelpInfo[helpNumber].contextNumber;
	hotJump = FALSE;

	/*	Wait for any character and terminate input */
	for(;;) {
		HELPDEF *thisHelp;
		HELPDEF fakeHelp;
		/*	Get the context for this context number */
		for( thisHelp = HelpInfo;
			 thisHelp->type < HELP_LAST ;
			 thisHelp++ ) {
			if( (nc)thisHelp->contextNumber == context )
				break;
		}
		if( thisHelp->type == HELP_LAST ) {
			/*	Didn't find it, use a fake one built like the last one */
			thisHelp = &fakeHelp;
			fakeHelp.type = HelpWinType;
			fakeHelp.contextNumber = context;
			fakeHelp.helpBuild = NULL;
		}

		keepIt = TRUE;
		lastHelpType = HelpWinType;
		HelpWinType = thisHelp->type;

		if( lastHelpTopic ) {
			my_ffree( lastHelpTopic );
			lastHelpTopic = NULL;
		}

		if (thisHelp->helpBuild) {
			thisContext = thisHelp->contextNumber;
			winError = thisHelp->helpBuild(TRUE);	/*	Help knows how to load itself */
		}
		else {
			winError = loadHelp(	/*	Create a text window */
				&HelpTextWin,		/*	Pointer to text window */
				&HelpWinDesc,			/* Window descriptor */
				&HelpWinType, /*	WHat type of thingy we are looking up */
				context,	/*	How many rows in the window*/
				HelpColors[0], /*	Default Attribute */
				SHADOW_SINGLE,			/*	Should this have a shadow */
				BORDER_BLANK,	/*	Single line border */
				TRUE, FALSE,	/*	Scroll bars */
				FALSE); 	/*	Should we remember what was below */
		}
		keepIt = FALSE;

		if( winError != WIN_OK ) {
			goto done;
		}

		/*	Set the previous and next information and buttons */
		if( initialContext ) {
			originalPrev = prevStop;
			originalNext = nextStop;
			initialContext = FALSE;
			if( hotJump )
				setCurrentButton( BACKTRIGGER, TRUE );
			else
				setButtonFocus( TRUE, KEY_TAB );
			hotJump = FALSE;

			if( lastHelpType != HelpWinType ) {	/* Type changed - Need to redraw border */
				WINDESC localWin;
				localWin.row = 2;
				localWin.col = 1;
				localWin.nrows = ScreenSize.row - 4;
				localWin.ncols = ScreenSize.col - 4;
				box( &localWin, BOX_DOUBLE, HelpTitles[HelpWinType].title, HelpBottomTitle, HelpColor );

				/*	Set Index and contents buttons based on HelpWinType */
				disableButton( INDEXTRIGGER, HelpTitles[HelpWinType].indexContext == 0 );
				disableButton( TOPICTRIGGER, HelpTitles[HelpWinType].contentsContext == 0 );
				/*	Strip out all backtraces */
#ifdef DOSTRIP
				for( ; HelpNcBack();	);
				backCount = 0;
#endif
			}
		}

		/*	Record where we are  ONLY if different from last time */
		if( thisContext != lastBackContext ) {
			lastBackContext = thisContext;
			HelpNcRecord( thisContext );
			if( backCount < 20 )
				backCount++;
		}

		nextContext = HelpNcNext( thisContext );
		if( thisContext == originalNext || originalNext == 0 )
			nextContext = 0;

		disableButtonHelp( BACKTRIGGER, backCount <= 1, NEXTTRIGGER );
		disableButtonHelp( NEXTTRIGGER, nextContext == 0, backCount <= 1 ? TOPICTRIGGER: BACKTRIGGER );

tightLoop:
		SETWINDOW( &tWin, HelpWinDesc.row, HelpWinDesc.col, HelpWinDesc.nrows +1, HelpWinDesc.ncols+1 );
		switch (vWin_ask( &HelpTextWin, specialHelp )) {
		case WIN_ENTER:
			/*	Lookup the hotspot and continue */
			vWin_destroy( &HelpTextWin );
			wput_sca( &tWin, VIDWORD( HelpColor, ' ' ));
			_fstrcpy(contsave,HelpHotSpot.pXref);
			context = HelpNc( HelpHotSpot.pXref, HelpTitles[0].context );
			initialContext = TRUE;
			hotJump = TRUE;
			break;

		case WIN_BUTTON:
			{
				pushButton(LastButton.number);
				switch( LastButton.key ) {
				case TOPICTRIGGER:
					/*	Lookup the index and continue */
					vWin_destroy( &HelpTextWin );
					wput_sca( &tWin, VIDWORD( HelpColor, ' ' ));
					context = HelpTitles[HelpWinType].contentsContext;
					initialContext = TRUE;
					break;
				case INDEXTRIGGER:
					/*	Lookup the index and continue */
					vWin_destroy( &HelpTextWin );
					wput_sca( &tWin, VIDWORD( HelpColor, ' ' ));
					context = HelpTitles[HelpWinType].indexContext;
					initialContext = TRUE;
					break;
				case BACKTRIGGER:
					/*	Previous item */
					vWin_destroy( &HelpTextWin );
					wput_sca( &tWin, VIDWORD( HelpColor, ' ' ));
					context = HelpNcBack();
					context = HelpNcBack();
					backCount-=2;
					initialContext = TRUE;
					hotJump = TRUE;
					break;
				case NEXTTRIGGER:
					/*	Next item */
					vWin_destroy( &HelpTextWin );
					wput_sca( &tWin, VIDWORD( HelpColor, ' ' ));
					context = nextContext;
					break;
				case KEY_F2:
					doPrint( &HelpTextWin,
						HelpWinType == HELP_TUTORIAL ? P_TUTOR :
							HelpWinType == HELP_GLOSSARY ? P_GLOSS : P_HELP, 0, 0, TRUE );
					goto tightLoop;
				case KEY_ESCAPE:
					goto killWindow;
				}
			}
		}
	}

killWindow:
	vWin_destroy( &HelpTextWin );
	if( lastHelpTopic ) {
		my_ffree( lastHelpTopic );
		lastHelpTopic = NULL;
	}
	/*	Cleanup and kill */
done:
	restoreButtons( );
	win_restore( behind, TRUE );
	pop_cursor();

	return;
}
#pragma optimize ("",on)

/**
*
* Name		LoadHelp - Get a help context and spray it into a created window
*
* Synopsis	WINRETURN loadHelp( PTEXTWIN fWin, WINDESC *win, HELPTYPE type,
*								char *context,
*								char attr, SHADOWTYPE shadow, BORDERTYPE border,
*								int vScroll, int hScroll, int remember)
*
* Parameters
*		PTEXTWIN fWin,			Pointer to text window
*		WINDESC *win,			Window descriptor
*		HELPTYPE type,			What context to start the search in - Must be valid
*		nc contextNumber,			What context string to look for
*		int helpNumber, 		Which help text structure to use
*		char attr,				Default Attribute
*		SHADOWTYPE shadow,		Should this have a shadow
*		BORDERTYPE border,		Single line border
*		int vScroll,			Vertical Scroll bars
*		int hScroll,			Horizontal scroll bars
*		int remember)			Should we remember what was below
*
* Description
*		Save the current state, find the context, show help, let them
*	do things and return
*
* Returns	No return
*
* Version	1.0
*/

WINRETURN loadHelp(			/*	Create a text window */
		PTEXTWIN fWin,		/*	Pointer to text window */
		WINDESC *win,		/* Window descriptor */
		HELPTYPE *type, 	/* Where to start looking by type */
		long context,		/*	Which help text structure to use */
		char attr,			/*	Default Attribute */
		SHADOWTYPE shadow,	/*	Should this have a shadow */
		BORDERTYPE border,	/*	Single line border */
		int vScroll,		/*	Vertical Scroll bars */
		int hScroll,		/*	Horizontal scroll bars */
		int remember)		/*	Should we remember what was below */
{
	char fullContext[80];
	char line[MAXLINE];
	int nRows;
	int nChars;
	nc thisNc;
	WINDESC workWin = *win;
	WINRETURN winError = WIN_OK;

	compBuffer = NULL;
	decompBuffer = NULL;
	PrintableHelp = FALSE;

	/*	Kill the old hot spot if there is one */
	memset( &HelpHotSpot, 0, sizeof( HelpHotSpot ));

	thisNc = context;

	if( thisNc < HELPERR_MAX ) {
		winError = WIN_NOTFOUND;
		goto done;
	}

	/*	Got a context - Now get the compressed size */
	compSize = HelpNcCb( thisNc );

	compBuffer = my_fmalloc( compSize );
	if( !compBuffer ) {
		winError = WIN_NOMEMORY;
		goto done;
	}

	decompSize = HelpLook( thisNc, compBuffer );
	decompBuffer = my_fmalloc( decompSize );
	if( !decompBuffer ) {
		winError = WIN_NOMEMORY;
		goto done;
	}
	HelpDecomp( compBuffer, decompBuffer, thisNc );

	/*	Save this off so help can push it on the visit stack */
	thisContext = thisNc;
	nRows = HelpcLines( decompBuffer );

	if( HelpGetLine( 1, MAXLINE-1, line, decompBuffer ) > 1 ) {
		/*	Check to see if the line is the control line */
		if( line[0] == CONTEXTTRIGGER ) {
			char *next;
			nRows--;
			/*	Get the start and stop contexts
			*			  012...   n12
			*	Format is @P H.start H.stop
			*	P indicates that it is printable
			*/
			PrintableHelp = toupper(line[1]) == 'P';

			next = strchr( line+CONTEXTOFFSET, ' ' );
			if( next ) {
				*(next++) = '\0';
				strcpy( fullContext, HelpTitles[*type].name );
				strcat( fullContext, line+CONTEXTOFFSET );
				prevStop = HelpNc( fullContext, HelpTitles[*type].context );
				strcpy( fullContext, HelpTitles[*type].name );
				strcat( fullContext, next );
				nextStop = HelpNc( fullContext, HelpTitles[*type].context );
			} else
				prevStop = nextStop = 0;	/*	No next and previous */
		}
	}

	/*	Now have a row count */
	winError = vWin_create( /*	Create a text window */
		fWin,			/*	Pointer to text window */
		win,			/* Window descriptor */
		nRows,		/*	How many rows in the window*/
		workWin.ncols-2,		/*	How wide is the window */
		attr,			/*	Default Attribute */
		shadow, 		/*	Should this have a shadow */
		border, 		/*	Single line border */
		vScroll,		/*	Scroll bars */
		hScroll,
		remember,		/*	Should we remember what was below */
		FALSE );		/*	Is this window delayed */


	workWin.row = 0;
	workWin.col = 0;
	workWin.nrows = 1;
	for(nRows=1;;nRows++) {
		nChars = HelpGetCells( nRows, MAXLINE-1, line,
						decompBuffer, HelpColors);

		if( nChars == -1 )
			break;

		/*	Line is now full of a text line that has attributes  attached
		*	Write them into the text buffer
		*/
		if( nChars > 1 ) {
			/*	Skip the context trigger line */
			if( line[0] == CONTEXTTRIGGER ) {
				continue;
			}

			workWin.ncols = nChars / 2;
			if( workWin.ncols > win->ncols )
				workWin.ncols = win->ncols;

#if 1
			/*	This was cut because loadMultHelp should be only one to do it */
			/*	This was put back because setHelpArgs needs it */
			if (HelpArgCnt > 0) {
				WORD line2[MAXLINE];
				help_argsubs(line2,(WORD *)line,workWin.ncols);
				vWinPut_ca( fWin, &workWin,(char *)line2);
			}
			else {
				vWinPut_ca( fWin, &workWin,line);
			}
#else
			vWinPut_ca( fWin, &workWin,line);
#endif
		}
		workWin.row++;
	}

done:
	if( compBuffer )
		_dfree( compBuffer );
	if( decompBuffer ) {
		if( winError != WIN_OK || !keepIt )
			_dfree( decompBuffer );
		else {
			/* save off the topic buffer s.t. hot spots can use it */
			lastHelpTopic = decompBuffer;
		}
	}

	if( winError != WIN_OK )
		errorMessage( WIN_NOTFOUND );
	return winError;
}

/**
*
* Name		showQuickHelp - Show quick help for the requested help
*
* Synopsis	int showQuickHelp( int helpNumber )
*
* Parameters
*		int helpNumber			What id to display the help for
*
* Description
*		Without reqard for what was there, just paint the current
*	quick help into the quick help window ( QuickWin )
*
* Returns	No return
*
* Version	1.0
*/
void showQuickHelp(	/*	Load the quick help window with this info */
	int helpNumber )	/*	What context to grab */
{
	char line[QUICKHELPWIDTH];
	WORD line2[QUICKHELPWIDTH/2];
	HELPTYPE hType = HelpInfo[helpNumber].type;
	int nChars;
	int dataRow;
	nc quickNc = HelpInfo[helpNumber].contextNumber;
	WINDESC workWin;

	compBuffer = NULL;
	decompBuffer = NULL;

	/* Clear the quick ref window */
	wput_sca( &QuickWin, VIDWORD( QHelpColors[0], ' ') );

	/*	Got a context number, decompress and show */
	compSize = HelpNcCb( quickNc );

	compBuffer = my_fmalloc( compSize );
	if( !compBuffer ) {
		goto done;
	}

	decompSize = HelpLook( quickNc, compBuffer );
	decompBuffer = my_fmalloc( decompSize );
	if( !decompBuffer ) {
		goto done;
	}
	HelpDecomp( compBuffer, decompBuffer, quickNc );

	/*	So paint it now */
	/*	SETWINDOW( &workWin, QuickWin.row + 1, QuickWin.col + 1, 1, QuickWin.ncols - 1); */
	SETWINDOW( &workWin, QuickWin.row, QuickWin.col + 1, 1, QuickWin.ncols - 1);

	justifyString(			/*	Show a justified string in a single line window */
	&workWin,			/*	Where to draw the string */
	QuickReference, 		/*	What to draw */
	-1,		/*	Trigger position - -1 for none */
	JUSTIFY_CENTER, 	/*	How to justify the string */
	HelpQuickRefColor,				/*	Regular attribute color */
	HelpQuickRefColor );			/*	Trigger color */

	workWin.row += 2;

	wordset( (LPWORD)line, VIDWORD( QHelpColors[0], ' '), QUICKHELPWIDTH/2 );

	for(dataRow = 1; dataRow<= QuickWin.nrows - 3; dataRow++, workWin.row++ ) {
		nChars = HelpGetCells( dataRow, MAXLINE-1, line,
						decompBuffer, QHelpColors);

		/*	Line is now full of a text line that has attributes  attached
		*	Write them into the text buffer
		*/

		if (HelpArgCnt > 0) {
			help_argsubs(line2,(WORD *)line,workWin.ncols);
			wput_ca( &workWin, (WORD *)line2);
		}
		else {
			wput_ca( &workWin, (WORD *)line);
		}

		/*	Clean the line out again */
		if( nChars > 0 )
			wordset( (LPWORD)line, VIDWORD(QHelpColors[0], ' '), nChars/2 );
	}

done:
	if( compBuffer )
		my_ffree( compBuffer );
	if( decompBuffer )
		my_ffree( decompBuffer );

}

/**
*
* Name		showDataHelp - Show data help for the requested help
*
* Synopsis	int showDataHelp( int helpNumber )
*
* Parameters
*		int helpNumber			What id to display the help for
*
* Description
*		Without reqard for what was there, just paint the current
*	quick help into the quick help window ( QuickWin )
*
* Returns	No return
*
* Version	1.0
*/
void showDataHelp(	/*	Load the quick help window with this info */
	int helpNumber )	/*	What context to grab */
{
	char line[HELPDATAWIDTH];
	WORD line2[HELPDATAWIDTH/2];
	HELPTYPE hType = HelpInfo[helpNumber].type;
	int nChars;
	int dataRow;
	nc quickNc = HelpInfo[helpNumber].contextNumber;
	WINDESC workWin;

	compBuffer = NULL;
	decompBuffer = NULL;

	/*	Got a context number, decompress and show */
	compSize = HelpNcCb( quickNc );

	compBuffer = my_fmalloc( compSize );
	if( !compBuffer ) {
		goto done;
	}

	decompSize = HelpLook( quickNc, compBuffer );
	decompBuffer = my_fmalloc( decompSize );
	if( !decompBuffer ) {
		goto done;
	}
	HelpDecomp( compBuffer, decompBuffer, quickNc );

	/*	So paint it now */
	SETWINDOW( &workWin, DataWin.row, DataWin.col, 1, DataWin.ncols);

	wordset( (LPWORD)line, VIDWORD( HdataColors[0], ' '),HELPDATAWIDTH/2 );

	wput_ca( &workWin, (WORD *)line);
	workWin.row += 1;
	wput_ca( &workWin, (WORD *)line);
	workWin.row += 1;

	for(dataRow = 1; dataRow<= DataWin.nrows - 3; dataRow++, workWin.row++ ) {
		nChars = HelpGetCells( dataRow, MAXLINE-1, line,
						decompBuffer, HdataColors);

		/*	Line is now full of a text line that has attributes  attached
		*	Write them into the text buffer
		*/
		if (HelpArgCnt > 0) {
			help_argsubs(line2,(WORD *)line,workWin.ncols);
			wput_ca( &workWin, (WORD *)line2);
		}
		else {
			wput_ca( &workWin, (WORD *)line);
		}

		/*	Clean the line out again */
		if( nChars > 0 )
			wordset( (LPWORD)line, VIDWORD(HdataColors[0], ' '), nChars/2 );
	}

done:
	if( compBuffer )
		my_ffree( compBuffer );
	if( decompBuffer )
		my_ffree( decompBuffer );

}


/**
*
* Name		loadText - Get a block of formatted text from the help file
*
* Synopsis	int loadText( HELPTEXT *htext,HELPTYPE type,char *context )
*
* Parameters
*		HELPTEXT *htext 	Control structure to be filled in
*		HELPTYPE type		Where to start looking by type
*		char *context		Which help text structure to use
*
* Description
*		Fetch the named item from the help and _write it to a
*	target window.
*
* Returns	Number of lines in text block
*
* Version	1.0
*/

int loadText(				/* Load text from help file */
		HELPTEXT *htext,	/* Control structure to be filled in */
		HELPTYPE type,		/* Where to start looking by type */
		char *context)		/* Which help text structure to use */
{
	char fullContext[80];
	nc thisNc;
	pb compBuffer = NULL;
	WINRETURN winError = WIN_OK;

	memset(htext,0,sizeof(HELPTEXT));

	if( !context )
		thisNc = thisContext;
	else {
		strcpy( fullContext, HelpTitles[type].name );
		strcat( fullContext, context );
		thisNc = HelpNc( fullContext, HelpTitles[type].context );
	}
	if( thisNc < HELPERR_MAX ) {
		winError = WIN_NOTFOUND;
		htext->nRows = -1;
		goto done;
	}

	/*	Got a context - Now get the compressed size */
	compSize = HelpNcCb( thisNc );

	compBuffer = my_fmalloc( compSize );
	if( !compBuffer ) {
		winError = WIN_NOMEMORY;
		goto done;
	}

	decompSize = HelpLook( thisNc, compBuffer );
	htext->dBuf = my_fmalloc( decompSize );
	if( !htext->dBuf ) {
		winError = WIN_NOMEMORY;
		goto done;
	}
	HelpDecomp( compBuffer, htext->dBuf, thisNc );

	/*	Save this off so help can push it on the visit stack */
	thisContext = thisNc;
	htext->nRows = HelpcLines( htext->dBuf );

done:
	if( compBuffer )
		my_ffree( compBuffer );

	if( winError != WIN_OK )
		errorMessage( WIN_NOTFOUND );
	return htext->nRows;
}


/**
*
* Name		showText - Put help text on screen
*
* Synopsis	void showText( HELPTEXT *htext,WINDESC *win,char *attr,BOOL toss )
*
* Parameters
*		HELPTEXT *htext 	Control structure from loadText
*		WINDESC *win		Descriptor of target window
*		char *attr		Attribute translation array (see HelpColors)
*
* Description
*		Write the text fetched by loadText() to a
*	target window.
*
* Returns	None
*
* Version	1.0
*/

void showText(				/*	Load text from help file */
		HELPTEXT *htext,	/* Control structure from loadText */
		WINDESC *win,		/* Descriptor of target window */
		char *attr,		/*	Attribute translation array (see HelpColors) */
		void (*callback)(WINDESC *win, WORD *line)) /* Callback function if not NULL */
{
	WORD line[MAXLINE/2];
	WORD line2[MAXLINE/2];
	int iRows;
	int nChars;
	WINDESC workWin = *win;

	workWin.nrows = 1;
	for(iRows = 1; iRows <= htext->nRows; iRows++) {
		WORD *pp;

		wordset( line, VIDWORD(attr[0], ' '), workWin.ncols );
		nChars = HelpGetCells( iRows, MAXLINE - 1, (char far *)line,
						htext->dBuf, attr);

		if( nChars == -1 )
			break;

		if (HelpArgCnt > 0) {
			help_argsubs(line2,(WORD *)line,workWin.ncols);
			pp = line2;
		}
		else {
			pp = line;
		}
		if (callback) {
			(*callback)(&workWin, pp);
		}
		else {
			wput_ca( &workWin, pp);
		}
		workWin.row++;
	}

	my_ffree( htext->dBuf );
}

/**
*
* Name		setHelpArgs - Set help argument list
*
* Synopsis	void setHelpArgs( int argcnt, char **argfrom,char **argto )
*
* Parameters
*		int argcnt		Argument count
*		char **argfrom		Array of from (or tag) strings
*		char **argto		Array of to (or substitution strings)
*
* Description
*		Set variables for later use.
*
* Returns	None
*
* Version	1.0
*/

void setHelpArgs(		/* Set help argument list */
	int argcnt,		/* Argument count */
	char **argfrom, 	/* Array of from (or tag) strings */
	char **argto)		/* Array of to (or substitution strings) */
{
/***
 *	We don't want to do this.  Some of the pointers in argto[] will
 *	be changed numerous times.  See INSTALL for examples.
 *
 *	int kk;
 *	int nn = sizeof(HelpArgFrom)/sizeof(HelpArgFrom[0]);
 *
 *	argcnt = min(argcnt,nn);
 *	for (kk = 0; kk < argcnt; kk++) {
 *		HelpArgFrom[kk] = argfrom[kk];
 *		HelpArgTo[kk] = argto[kk];
 *	}
***/
	HelpArgFrom = argfrom;
	HelpArgTo = argto;
	HelpArgCnt = argcnt;
}

void help_argsubs(
	WORD *	 dst,		/* destination */
	WORD *	 src,		/* source */
	int len)		/* length of source and dest */
{
	WORD color;
	WORD *srcend;
	WORD *dstend;

	srcend = src + len;
	dstend = dst + len;
	while (dst < dstend && src < srcend) {
		int kk;
		char tag[40];
		char *tagp;
		char *subst;
		WORD *src0;

		/* Copy till '#' found */
		while (src < srcend) {
			if ((char)(*src) == '#') break;
			*dst++ = *src++;
		}

		/* Check for all done */
		if (src >= srcend) break;

		/* Color determined by first '#' of tag */
		color = (WORD)(*src & 0xff00);

		/* Extract the tag string, including the #'s, but ignoring _'s */
		tagp = tag;
		src0 = src;
		do {
			if ((char)(*src) != '_') {
				*tagp++ = (char)(*src);
				if ((tagp-tag) >= sizeof(tag)-1) {
					/* Oops, no matching # found */
					src = src0;
					break;
				}
			}
			src++;
		} while ((char)(*src) != '#' && src < srcend);

		if (src == src0) {
			/* Recover from fuck-up */
			*dst++ = *src++;
			continue;
		}

		*tagp++ = (char)(*src++);
		*tagp++ = '\0';

		/* Look up the tag and substitute */
		subst = tag;
		for (kk = 0; kk < HelpArgCnt; kk++) {
			if (strcmp(HelpArgFrom[kk],tag) == 0) {
				subst = HelpArgTo[kk];
				break;
			}
		}

		/* Do the substitution */
		tagp = subst;
		while (*tagp && dst < dstend) {
			*dst++ = (WORD)(color | (*tagp++));
		}
	} /* while */
	if (dst < dstend) {
		/* Space fill any unfilled words */
		color = (WORD)((*(src-1) & 0xff00) | ' ');
		while (dst < dstend) {
			*dst++ = color;
		}
	}
}


/**
*
* Name		setHotButton - Set which ever hot button is needed
*
* Synopsis	void setHotButton( PTEXTWIN pText, int request )
*
* Parameters
*		PTEXTWIN pText		What window to update
*		int request		What thing to do
*
* Description
*		Walk the hot button list for the first, next or previous button
*	depending on what has been requested
*
* Returns	None
*
* Version	1.0
*/

void setHotButton( PTEXTWIN pText, int request )
{
	int retState = 0;
	hotspot oldSpot = HelpHotSpot;
	WINDESC workWin;

	switch( request ) {
	case HOT_PREV:
		if( !HelpHotSpot.pXref
			|| HelpHotSpot.line < (ushort)(pText->corner.row+2)
			|| HelpHotSpot.line > (ushort)(pText->corner.row + pText->win.nrows+1)) {
			/*	Start searching at bottom right corner of screen if no
			*	current hot spot
			*/
			HelpHotSpot.line = (ushort)(pText->corner.row + pText->win.nrows+1);
			HelpHotSpot.col = (ushort)pText->win.ncols;
		}
		retState = HelpHlNext( -1, lastHelpTopic, &HelpHotSpot );
		if( !retState ) {
			/*	Set the hot spot to last line in window */
			HelpHotSpot.line = (ushort)pText->size.row;
			HelpHotSpot.col = (ushort)pText->size.col;
			retState = HelpHlNext( -1, lastHelpTopic, &HelpHotSpot );
			if( !retState )
				HelpHotSpot = oldSpot;
		}
		/*	work around a bug in help that prev doesn't set the context right */
		HelpHlNext( 0, lastHelpTopic, &HelpHotSpot );
		break;
	case HOT_NEXT:
		/*	This is not called unless there is a current hot spot */
		if( !HelpHotSpot.pXref
			|| HelpHotSpot.line < (ushort)(pText->corner.row+2)
			|| HelpHotSpot.line > (ushort)(pText->corner.row + pText->win.nrows+1)) {
			/*	Start searching at bottom right corner of screen if no
			*	current hot spot
			*/
			HelpHotSpot.line = (ushort)(pText->corner.row+2);
			HelpHotSpot.ecol = 0;
		}
		HelpHotSpot.col = (ushort)(HelpHotSpot.ecol+1);
		retState = HelpHlNext( 0, lastHelpTopic, &HelpHotSpot );
		if( !retState ) {
			HelpHotSpot.line=HelpHotSpot.col=1;
			retState = HelpHlNext( 0, lastHelpTopic, &HelpHotSpot );
			if( !retState )
				memset( &HelpHotSpot, 0, sizeof( HelpHotSpot ));
		}
		break;
	}

	if( retState ) {
		/*	Paint the old spot in regular mode */
		if( oldSpot.pXref ) {
			SETWINDOW( &workWin, oldSpot.line-2, oldSpot.col-1, 1,
					oldSpot.ecol - oldSpot.col +1 );

		/*	Assume anything with hotspot has a CONTEXTTRIGGER */
			if( !prevStop )
				oldSpot.line++;
			vWinPut_sa( pText, &workWin, HelpColors[4] );
		}
		/*	and now the new spot as hot! */
		if( HelpHotSpot.pXref ) {
			SETWINDOW( &workWin, HelpHotSpot.line-2, HelpHotSpot.col-1, 1,
					HelpHotSpot.ecol - HelpHotSpot.col +1 );
			/*	Assume anything with hotspot has a CONTEXTTRIGGER */
			if( !prevStop )
				HelpHotSpot.line++;
			vWinPut_sa( pText, &workWin, HelpCurContext );
			/*
			*  Now make sure the user can see the hot spot
			*/
			if( workWin.row < pText->corner.row ) {
				pText->corner.row = workWin.row - 2;
				if( pText->corner.row < 0 )
					pText->corner.row = 0;
				vWin_forceCurrent( pText );
			} else if( workWin.row >= pText->corner.row + pText->win.nrows ) {
				pText->corner.row = workWin.row - pText->win.nrows+3;
				if( pText->corner.row + pText->win.nrows > pText->size.row )
					pText->corner.row = pText->size.row - pText->win.nrows;
				vWin_forceCurrent( pText );
			}
			/*	Make sure that the buttons DON'T have focus */
			noDefaultButton();
		}
	}

}

/**
*
* Name		specialHelp - Set which ever hot button is needed
*
* Synopsis	void specialHelp( PTEXTWIN pText, INPUTEVENT *event )
*
* Parameters
*		PTEXTWIN pText		What window to update
*		INPUTEVENT *event	what keyboard event to process
*
* Description
*		Deal with the special keys required by help
*
* Returns	WIN_NOOP - Don't recognize the event
*			WIN_OK	 - Processed the event - No further action
*			WIN_RETURN - Return Enter key to caller of vWin_ask
*
* Version	1.0
*/

int specialHelp(
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	INPUTEVENT *event		/*	What event to process - Could be null */
)			/*	Menu callback function */
{
	hotspot test;
	char far *result;
	WINDESC workWin;

	switch( event->key ) {
	case KEY_STAB:
	case KEY_TAB:
		/*	Kill off the hot spot */
		if( HelpHotSpot.pXref ) {
			SETWINDOW( &workWin, HelpHotSpot.line-2, HelpHotSpot.col-1, 1,
					HelpHotSpot.ecol - HelpHotSpot.col +1 );
			if( !prevStop )
				HelpHotSpot.line++;
			vWinPut_sa( pWin, &workWin, HelpColors[4] );
			memset( &HelpHotSpot, 0, sizeof( HelpHotSpot ));
			/*	Now move the button focus as required */
			setButtonFocus( TRUE, event->key );
		} else {
			if( testButton( event->key, FALSE ) == BUTTON_LOSEFOCUS )
				testButton( event->key, FALSE );
		}
		return WIN_OK;
	case KEY_ENTER:
		return HelpHotSpot.pXref ? event->key : WIN_NOOP;
	case KEY_RIGHT:
		setHotButton( pWin, HOT_NEXT );
		return WIN_OK;
	case KEY_LEFT:
		setHotButton( pWin, HOT_PREV );
		return WIN_OK;
	}
	if( event->click == MOU_NOCLICK )
		return WIN_NOOP;

	if( event->y < pWin->win.row || event->y >= pWin->win.row+pWin->win.nrows )
		return WIN_NOOP;

	if( event->x < pWin->win.col || event->x >= pWin->win.col+pWin->win.ncols )
		return WIN_NOOP;

	test.line = (ushort)(event->y - pWin->win.row + pWin->corner.row + 2);
	test.col = (ushort)(event->x	- pWin->win.col + pWin->corner.col + 1);

	result = HelpXRef( lastHelpTopic, &test );
	if( result ) {
		/*	Kill off the old hot spot */
		if( HelpHotSpot.pXref ) {
			SETWINDOW( &workWin, HelpHotSpot.line-2, HelpHotSpot.col-1, 1,
					HelpHotSpot.ecol - HelpHotSpot.col +1 );
			if( !prevStop )
				HelpHotSpot.line++;
			vWinPut_sa( pWin, &workWin, HelpColors[4] );
		}

		/*	Now set the new one */
		HelpHotSpot = test;
		if( HelpHotSpot.pXref ) {
			SETWINDOW( &workWin, HelpHotSpot.line-2, HelpHotSpot.col-1, 1,
					HelpHotSpot.ecol - HelpHotSpot.col +1 );
			if( !prevStop )
				HelpHotSpot.line++;
			vWinPut_sa( pWin, &workWin, HelpCurContext );
		}

		switch( event->click ) {
		case MOU_LSINGLE:
			return WIN_OK;
		case MOU_LDOUBLE:
			return WIN_ENTER;
		}
	}
	return WIN_NOOP;
}

/**
*
* Name		setHelp - Get a help context and spray it into a created window
*
* Synopsis	WINRETURN setHelp( HELPTYPE type, char *context )
*
* Parameters
*		HELPTYPE type,			What context to start the search in - Must be valid
*		char *context,			What context string to look for
*		long *prev,				Where to put previous context if any
*		long *next )			Where to put next context if any
*
* Description
*		set everything up for fetching lines
*
* Returns	Number of lines
*
* Version	2.0
*/
long setHelp(				/*	Do all the decompression for a specific help */
	HELPTYPE hType, 		/*	Which file to look in */
	char *contextString,	/*	What to get */
	long *prev,				/*	Where to put previous context if any */
	long *next )			/*	Where to put next context if any */
{
	nc aNc;

	compBuffer = NULL;
	decompBuffer = NULL;

	aNc = HelpNc( contextString, HelpTitles[hType].context );
	if( aNc > HELPERR_MAX ) {
		aNc = contextHelp( hType, aNc, prev, next );
		return aNc;

	}

}

/**
*
* Name		contextHelp - Get a help context and spray it into a created window
*
* Synopsis	WINRETURN setHelp( HELPTYPE type, char *context )
*
* Parameters
*		long context,			What context number to look for
*		long *prev,				Where to put previous context if any
*		long *next )			Where to put next context if any
*
* Description
*		set everything up for fetching lines given a context number
*
* Returns	context number
*
* Version	2.0
*/
long contextHelp (			/*	Set the help print based on this context */
	HELPTYPE hType, 		/*	Which file to look in */
	long context,			/*	Context to look up */
	long *prev,				/*	Where to put previous context if any */
	long *next )			/*	Where to put next context if any */
{
	char line[MAXLINE];
	int nRows;

	PrintableHelp = FALSE;
	compSize = HelpNcCb( context );

	compBuffer = my_fmalloc( compSize );
	if( !compBuffer ) {
		goto error;
	}

	decompSize = HelpLook( context, compBuffer );
	decompBuffer = my_fmalloc( decompSize );
	if( !decompBuffer ) {
		goto error;
	}
	HelpDecomp( compBuffer, decompBuffer, context );

	my_ffree( compBuffer );
	compBuffer = NULL;
	nRows = HelpcLines( decompBuffer );
	prevNextFlag = FALSE;

	if( HelpGetLine( 1, MAXLINE-1, line, decompBuffer ) > 1 ) {
		/*	Check to see if the line is the control line */
		if( line[0] == CONTEXTTRIGGER ) {
			char *cpWork;
			prevNextFlag = TRUE;
			/*	Get the start and stop contexts
			*			  012...   n12
			*	Format is @ H.start H.stop
			*	P indicates that it is printable
			*/
			PrintableHelp = toupper(line[1]) == 'P';
			cpWork = strchr( line+CONTEXTOFFSET, ' ' );
			if( cpWork ) {
				char fullContext[80];
				*(cpWork++) = '\0';
				if( prev ) {
					strcpy( fullContext, HelpTitles[hType].name );
					strcat( fullContext, line+CONTEXTOFFSET );
					*prev = HelpNc( fullContext, HelpTitles[hType].context );
				}
				if( next ) {
					strcpy( fullContext, HelpTitles[hType].name );
					strcat( fullContext, cpWork );
					*next = HelpNc( fullContext, HelpTitles[hType].context );
				}
			} else
				*prev = *next = '\0';   /*      No next and previous */
		}
	}
	return context;

error:
	if( compBuffer ) {
		my_ffree( compBuffer );
		compBuffer = NULL;
	}
	if( decompBuffer ) {
		my_ffree( decompBuffer );
		decompBuffer = NULL;
	}
	return 0;
}


/**
*
* Name		nextContextHelp - Get a help context and spray it into a created window
*
* Synopsis	long nextContextHelp( long context )
*
* Parameters
*		long context,			What context number to look for
*
* Description
*		set everything up for fetching lines given a context number - Just
*	get the next physical context
*
* Returns	next context all filled in or 0
*
* Version	2.0
*/
long nextContextHelp (		/*	Return the next context in file */
	HELPTYPE hType, 		/*	Which file to look in */
	long context )			/*	Where we are now */
{
	nc nextC = HelpNcNext( context );
	if( nextC ) {
		if( contextHelp( hType, nextC, NULL, NULL ) == 0 )
			return 0;
	}
	return nextC;
}

/**
*
* Name		getHelpLine - return the requested help line
*
* Synopsis	WINRETURN freeHelp( int row, char *line )
*
* Parameters
*		int row 		Row to load - 1 based
*		char *line		Where to put the data - Assumed to be large enough
*
* Description
*		fill up the line withthe requested characters. ASSUME the line is
*	long enough.  Adjust row if there was a context string
*
* Returns	length of row
*
* Version	2.0
*/
int getHelpLine(			/*	Get a line of text from a decompressed area */
	int row,				/*	Which row to fetch */
	char *line )			/*	Where to put the line - Assumed large enough */
{
  int retval;

	if( prevNextFlag )
		row++;

	retval = HelpGetLine( row, MAXLINE-1, line, decompBuffer );

	/* Some programs, like INSTALL, walk through all help topics */
	/* when Print All Help is selected from the F2 dialog.	Check */
	/* for unprintable stuff. */
	/* Note that this doesn't catch contexts that have no @N or @P. */
	/* If they are not to show up, they'll need @N. */
	if (retval > 1 && line[0] == CONTEXTTRIGGER ) {
	  PrintableHelp = (toupper (line[1]) == 'P');
	} /* Got text */

	return (retval);
}

/**
*
* Name		freeHelp - release malloced space for help
*
* Synopsis	WINRETURN freeHelp( void )
*
* Parameters
*		None
*
* Description
*		free everything up from fetching lines
*
* Returns	TRUE -> everything ok
*
* Version	2.0
*/
void freeHelp( void )		/*	Release the decompressed help record */
{
	/* (Semi)permanent allocations should not have been made via */
	/* _dmalloc(), but if they don't belong to us we'll pass 'em */
	/* on to _ffree() */
	if( compBuffer ) {
		_dfree( compBuffer );
		compBuffer = 0;
	}
	if( decompBuffer ) {
		_dfree( decompBuffer );
		decompBuffer = 0;
	}
}

