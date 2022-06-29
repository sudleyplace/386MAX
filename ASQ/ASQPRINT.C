/*' $Header:   P:/PVCS/MAX/ASQ/ASQPRINT.C_V   1.1   05 Sep 1995 16:27:28   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ASQPRINT.C								      *
 *									      *
 * ASQ printer routines 						      *
 *									      *
 ******************************************************************************/

/*	Standard C includes */
#include <bios.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <help.h>

/*	Program includes */

#include "asqshare.h"
#include "commfunc.h"
#include "button.h"
#include "editwin.h"
#include "libcolor.h"
#include "libtext.h"
#include "qprint.h"
#include "qhelp.h"
#include "inthelp.h"
#include "qwindows.h"
#include "asqtext.h"
#include "ui.h"
#include "myalloc.h"

/*	Definitions for this Module */
#define EDITOROK

#define PRINTDONE -1
#define PRINTER_PROBLEM 0x29
#define PRINTFILEERROR( prtOut ) (errorMessage( ferror( prtOut )+200 ))
#define MAXPRINTLINE 256

static FILE *prtOut;
static int pageNumber;
static int lineNumber;
static char timeString[32];
static void *saveBehind;
static WINDESC printingWin;


int dumpLine( char *line, PRINTTITLETYPE type);
int doHeader( PRINTTITLETYPE type );
int myPrint( char out );

int printHelp( int context, int followLinks, PRINTTITLETYPE type	);
int printAllHelp( int context, PRINTTITLETYPE type	);
int printEditor( PRINTTITLETYPE type );
int printWindow( PTEXTWIN pWin, PRINTTITLETYPE type, int which );
int printAllData( void );
int printInfo( int id, int first );
int printFile( char *name );
int printTitle( char *title, int type );
int printThisContext( long context, PRINTTITLETYPE type );

void killPrinting( void );
void sayPage( void );
void sayPrinting( void );

/**
*
* Name		doPrintCallBack
*
* Synopsis	void doPrintCallBack( PTEXTWIN pWin, PRINTTYPE type, int which, int HelpNum)
*
* Parameters
*			PTEXTWIN pWin;			Pointer to the current text window
*			PRINTTYPE type; 		What type of window this is
*			int HelpNum,			What help number this is
*			int which;				which window in a given type
*
* Description
*		This routine does that actual printing
*
* Returns	TRUE -> there was an error
*			FALSE -> everything ok
*
* Version	1.0
*/

#pragma optimize ("leg",off)
int doPrintCallback(			/*	Do all printing */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	PRINTTYPE type, 		/*	What type of window this is */
	int which,				/*	which window in a given type */
	int HelpNum)			/*	What help number this is */
{
	int errorOut = FALSE;

	/*
	*	First set up the print destionation and set up the printer
	*/
	lineNumber = pageNumber = 1;

	/*	first set up the output device as appropriate */
	if( WherePrintList.items[0].state.checked )
	{
#ifndef OS2_VERSION
		int result = _bios_printer( _PRINTER_STATUS, 0, 0 );			/*	initialize the printer PRN: */
		if( result & PRINTER_PROBLEM )
		{
			errorMessage( prerror(result) );
			return TRUE;
		}
#endif
	} else
	{
		prtOut = fopen( PrintFile,
				WherePrintList.items[1].state.checked ? "wt" : "at" );
		if( (prtOut == NULL) || (ferror( prtOut )) )
		{
			PRINTFILEERROR( prtOut );
			return TRUE;
		}

	}
	sayPrinting( );

	switch( type ) {
	case P_EDITOR:
#ifdef EDITOROK
		if( P_Editor.items[0].state.checked ) {
			/*	Print the current editor file */
			if( pWin )
				errorOut = printEditor( PRINTTYPEFILE );
			else {
				char *name;
				switch( which ) {
				case CONFIGSYS: 		/*	12	*/
					name = ConfigName;
					break;
				case CONFIGAUTOEXEC:	/*	13	*/
					name = AutoexecName;
					break;
				case CONFIGMAXPRO:		/*	14	*/
					name = MAXName;
					break;
				}
				errorOut = printFile( name );
			}
		}
		if( !errorOut && P_Editor.items[1].state.checked ) {
			/*	Print all the editor help topics */
			errorOut = printHelp( HELPEDITOR, TRUE, PRINTTYPEHELP );
		}
		if( !errorOut && P_Editor.items[2].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
#endif
		break;
	case P_GLOSS:
		if( P_Gloss.items[0].state.checked ) {
			/*	Print the current Gloss selection */
			if( pWin )
				errorOut = printWindow( pWin, PRINTTYPEGLOSSARY, which );
			else
				errorOut = printHelp( LEARNGLOSSARY, FALSE, PRINTTYPEGLOSSARY );
		}
		if( !errorOut && P_Gloss.items[1].state.checked ) {
			/*	Print all the glossary help topics */
			errorOut = printAllHelp( LEARNGLOSSARY, PRINTTYPEGLOSSARY );
		}
		break;
	case P_HELP:
		if( P_Help.items[0].state.checked ) {
			/*	Print the current Help selection */
			if( pWin )
				errorOut = printWindow( pWin, PRINTTYPEHELP, which );
			else
				errorOut = printHelp( HelpNum, FALSE, PRINTTYPEHELP );

		}
		if( !errorOut && P_Help.items[1].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
		break;
	case P_QMENU:
	case P_MENU:
		if( P_Menu.items[0].state.checked ) {
			/*	Print the current data item	*/
			if( pWin )
				/*	We were in data window so that is valid */
				errorOut = printWindow( pWin, PRINTTYPEANALYSIS,which );
			else
				/*	Here we have to menu return code */
				/*	Solve this by forcing menu return code to match info request */
				errorOut = printInfo( which, TRUE );
		}
		if( !errorOut && P_Menu.items[1].state.checked ) {
			/*	Print all the data items */
			errorOut = printAllData();
		}
		if( !errorOut && P_Menu.items[2].state.checked ) {
			/*	Print the current help topic for this item */
			errorOut = printHelp( HELP_MEM_SUMM - 1 + which, FALSE, PRINTTYPEHELP );
		}
		if( !errorOut && P_Menu.items[3].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
		break;
	case P_TUTOR:
		if( P_Tutor.items[0].state.checked ) {
			/*	Print the current tutorial topic	*/
			if( pWin )
				errorOut = printWindow( pWin, PRINTTYPETUTORIAL, which );
			else {
				PRINTTITLETYPE pType;
				int helpRequest;

				pType = PRINTTYPETUTORIAL;

				switch( which ) {
				case MLEARNASQ:
					helpRequest = LEARNASQ;
					goto dumpHelp;
				case MLEARNQUALITAS:
					errorOut = printHelp( LEARNQUALITAS, FALSE, pType );
					break;
				case MLEARNTUNING:
					errorOut = printHelp( LEARNTUNING, FALSE, pType );
					break;
				case MLEARNMEMORY:
					helpRequest = LEARNMEMORY;
					goto dumpHelp;
				case MLEARNCONFIG:
					helpRequest = LEARNCONFIG;
					goto dumpHelp;
				case MLEARNEQUIPMENT:
					helpRequest = LEARNEQUIPMENT;
					goto dumpHelp;
				case MLEARNCONTENTS:
					errorOut = printHelp( LEARNCONTENTS, FALSE, pType );
					break;
				case MLEARNINDEX:
					errorOut = printHelp( LEARNINDEX, FALSE, pType );
					break;
				case MLEARNGLOSSARY:
					helpRequest = LEARNGLOSSARY;
					pType = PRINTTYPEGLOSSARY;
dumpHelp:
					errorOut = printHelp( helpRequest, TRUE, pType );
					break;
				}
			}

		}
		if( !errorOut && P_Tutor.items[1].state.checked ) {
			/*	Print all the tutorial items */
			errorOut = printAllHelp( LEARNCONTENTS, PRINTTYPETUTORIAL );
		}
		break;
	case P_BROWSER:
#ifdef EDITOROK
		if( P_Browser.items[0].state.checked ) {
			/*	Print the current editor file */
			if( pWin )
				errorOut = printEditor( PRINTTYPEFILE );
			else {
				char *name;
				switch( which ) {
				case CONFIGSYS: 		/*	12	*/		/* to this */
					name = ConfigName;
					break;
				case CONFIGAUTOEXEC:	/*	13	*/
					name = AutoexecName;
					break;
				case CONFIGMAXPRO:		/*	14	*/
					name = MAXName;
					break;
				}
				errorOut = printFile( name );
			}
		}
		if( !errorOut && P_Browser.items[1].state.checked ) {
			/*	Print all the Browser help topics */
			errorOut = printHelp( HELPEDITOR, TRUE, PRINTTYPEHELP );
		}
		if( !errorOut && P_Browser.items[2].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
#endif
		break;
	case P_OEDITOR:
#ifdef EDITOROK
		if( !errorOut && P_Editor.items[0].state.checked ) {
			/*	Print all the editor help topics */
			errorOut = printHelp( HELPEDITOR, TRUE, PRINTTYPEHELP );
		}
		if( !errorOut && P_Editor.items[1].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
#endif
		break;
	}
	/*	Always dump out a trailing form feed */
	if( !errorOut )
	{
		char outline[2];
		outline[0] = '\f';
		outline[1] = '\0';
		dumpLine( outline, PRINTTYPENONE );
	}

	/*	Now close out result file as approp */
	if( !WherePrintList.items[0].state.checked )
	{
		int result = fclose( prtOut );
		if( result == EOF || ferror( prtOut ))
		{
			PRINTFILEERROR(prtOut);
			return TRUE;
		}
	}

	killPrinting();

	return FALSE;

}
#pragma optimize ("",on)


void killPrinting( void )
{

	visible_mouse (0); // Only show mouse when getting input
	restoreButtons( );
	if( saveBehind ) {
		win_restore( saveBehind, TRUE );
	}
	pop_cursor();
}

void sayPage( void )
{
	char pMessage[20];

	sprintf( pMessage, Printing, pageNumber );
	wrapString( &printingWin, pMessage, &ErrorColor );

}


void sayPrinting( void )
{
	push_cursor();
	hide_cursor();

	printingWin.row = (ScreenSize.row - 1 - 6) / 2;
	printingWin.col = (ScreenSize.col - MAXMESSAGEWIDTH ) / 2;
	printingWin.nrows = 6;
	printingWin.ncols = MAXMESSAGEWIDTH;

	saveBehind = win_save( &printingWin, TRUE );
	if( !saveBehind ) {
		pop_cursor();
		goto SAYPRINT_RETURN;
	}

	if( saveButtons() != BUTTON_OK ) {
		my_free( saveBehind );
		pop_cursor();
		goto SAYPRINT_RETURN;
	}

	wput_sca( &printingWin, VIDWORD( ErrorColor, ' ' ));
	shadowWindow( &printingWin );
	box( &printingWin, BOX_DOUBLE, TypeMessage[ERRTYPE_MESSAGE], NULL, ErrorColor );

	/*	Adjust the window inside the box */
	printingWin.row++;
	printingWin.col += 2;
	printingWin.nrows -= 2;
	printingWin.ncols -= 4;

	sayPage();

	PrintingButtons[0].pos.row = printingWin.row + printingWin.nrows - 2;
	PrintingButtons[0].pos.col = ( ScreenSize.col - MAXBUTTONTEXT ) / 2;

	addButton( PrintingButtons, NUMPRINTINGBUTTONS, NULL );
	showAllButtons();
	setButtonFocus( TRUE, KEY_TAB );

SAYPRINT_RETURN:
	visible_mouse (1); // Leave mouse cursor on constantly

} // sayPrinting ()


/**
*
* Name		dumpLine - Print this line to the currently selected out device
*
* Synopsis	void dumpLine( char *line, PRINTTITLETYPE type )
*
* Parameters
*			char *line - Line to transform and dump
*		PRINTTITLETYPE type - PRINTTYPEANALYSIS
*						 PRINTTYPEHELP
*						 PRINTTYPETUTORIAL
*
* Description
*		Given this display line, transform it to all printable characters
*	and shove it out the selected print device.
*	If line == NULL then just dump a blank line
*
*
* Returns	TRUE == SUCCESS  FALSE == FAILED
*
*
* Version	2.0
*
*	Changed to always return value;
*
**/
#pragma optimize ("leg",off)
int dumpLine( char *line, PRINTTITLETYPE type)
{
	char outline[256];
	char *current = line;
	char *out = outline;
	INPUTEVENT event;
	int result;

	/*	Test keyboard for an event */
	if( get_input( 0, &event) ) {
		if( event.key ) {
			if( testButton( event.key, TRUE ) != BUTTON_NOOP)
				return FALSE;
		} else {
			if( testButtonClick( &event, TRUE ) )
				return FALSE;
		}
	}

	if( lineNumber >= 59 )
	{
		if( !doHeader( type ) ) return FALSE;
	}
	else
		lineNumber++;

	if( line )
	{
		/*	Do the character transform */
		while ( *current)
		{
			switch( *current )
			{
			case '\x01':
				*(out++) = ' ';                 /*      continuation line character */
				break;
			case '\x04':
				*(out++) = '*';                 /*      Diamond character */
				break;
			case '\x11':                            /*      Enter key */
				while (*current && *(++current) != '\xD9');
				strcpy( out, Enter);
				out += sizeof(Enter) - 1;
				break;
			case '\x18':                            /*      Up down arrows - SPecial */
				while (*current && *(++current) != '\x19');
				strcpy( out, Arrows);
				out += sizeof(Arrows)-1;
				break;
			case '\x19':
				*(out++) = 'v';                         /*      Down arrow in memory help */
				break;
			case '\xB0':
				*(out++) = 'F';                         /*      Frame EMS Usage */
				break;
			case '\xB1':
				*(out++) = 'X';                         /*      Mottled Bar */
				break;
			case '\xB2':
				*(out++) = 'D';                         /*      Dos Bar */
				break;
			case '\xB3':                                    /*      Vertical */
			case '\xB4':                                    /*      Box joint left */
			case '\xBA':                                    /*      Double Vertical Bar */
			case '\xC3':                                    /*      Box joint right */
				*(out++) = '|';
				break;
			case '\xBF':                                    /*      Box upper Right */
			case '\xC0':                                    /*      Box lower left */
			case '\xC1':                                    /*      Box joint bottom */
			case '\xC2':                                    /*      Box joint top */
			case '\xC4':                                    /*      horizontal */
			case '\xCD':
			case '\xD9':                                    /*      Box upper left */
			case '\xDA':                                    /*      Box upper left */
				*(out++) = '-';
				break;
			case '\xB5':
			case '\xB8':
			case '\xBE':
			case '\xC5':
			case '\xC6':
			case '\xCF':
			case '\xD4':
			case '\xD5':
				*(out++) = '+';
				break;
			case '\xDB':
				*(out++) = '#';                 /*      DOS EMS Usage */
				break;
			case '\xDC':
				*(out++) = '*';                         /*      Timing */
				break;
			case '\xE6':
				*(out++) = 'u';                         /*      Millisecond speed ratio */
				break;
			case '\xFB':
				*(out++) = 'X';                         /*      Check Mark */
				break;
			case '\xFE':
				*(out++) = 'R';                         /*      ROM EMS Usage */
				break;
			case '\xE8':
				*(out++) = 'r';                         /*      RAM EMS Usage */
				break;
			case '\xF7':
				*(out++) = 'V';                         /*      Video EMS Usage */
				break;
			default:
				*(out++) = *current;
				break;
			}
			current++;
		}

		*out = '\0';    /*      Terminate the string */
	} else
		outline[0] = '\0';

	trnbln(outline);
	if( WherePrintList.items[0].state.checked ) {
		out = outline;
		while(*out)
		{
			if( !myPrint( *out ) ) return FALSE;
			out++;
		}

		/*	Now carriage return linefeed pair */
		if( !myPrint( '\r' )) return FALSE;
		if( !myPrint( '\n' )) return FALSE;
	} else {
		result = fputs( outline, prtOut );
		if( result == EOF || ferror( prtOut ))
		{
			PRINTFILEERROR( prtOut );
			return FALSE;
		}
		result = fputc( '\n', prtOut );
		if( result == EOF || ferror( prtOut ))
		{
			PRINTFILEERROR( prtOut );
			return FALSE;
		}
	}
	return TRUE;
}
#pragma optimize ("",off)


/**
*
* Name		myPrint - Print a character - Handle errors
*
* Synopsis	int myPrint( char out )
*
* Parameters
*			char out - Character to be printed
*
* Description
*		This routine dumps a character to the printer and handles
*	all errors
*
*
* Returns	FALSE == Failure
*
*
* Version	1.10
*
**/
int myPrint( char out )
{
	int result;
	unsigned long timeOut;
	time(&timeOut);
	timeOut += 60;

	result = 1;
	while ( result & 1 )
	{
#ifdef OS2_VERSION
		if( out );
		result = 0;
#else
		result = _bios_printer( _PRINTER_WRITE, 0, out );
#endif
		if( (unsigned long)time(NULL) > timeOut ) break;
	}

	if( result & PRINTER_PROBLEM )
	{
		result = prerror( result );
		errorMessage( result );
		return FALSE;
	}

	return TRUE;
}

/**
*
* Name		doHeader - Print the title lines for output
*
* Synopsis	int doHeader( PRINTTITLETYPE type )
*
* Parameters
*		PRINTTITLETYPE type - PRINTTYPEANALYSIS
*						 PRINTTYPEHELP
*						 PRINTTYPETUTORIAL
*
* Description
*		This routine dumps the propganda and page number at the
*	top of the page and also the page number
*
*
* Returns	FALSE == Failure
*
*
* Version	2.0
*
***** Change for version 1.10 - Add Print Type
**/
int doHeader( PRINTTITLETYPE type )
{
	char outline[81];
	int titleLen = sizeof( PRINTPAGETITLE)-1;
	int fileLen = sizeof( FILEPROMPT )-1;
	int readLen = strlen( ReadFile );

	lineNumber = 1;

	sayPage();

	if(pageNumber > 1 )
	{
		outline[0] = '\f';
		outline[1] = '\0';
		if(!dumpLine( outline, type )) return FALSE;
	} else
	{
		time_t aclock;

		/*	Get printout time */
		time(&aclock);
		timedatefmt (&aclock, timeString, 2, 1);

	}

	memset( outline, ' ', sizeof(outline));
	strcpy( outline, PrintProgramName+1 );
	memcpy( outline+strlen( PrintProgramName )-1, PrintPageTitle, titleLen);	/* Kill leading space */
	/*
	****  Change for 1.10 to add titleLen stuff
	*/
	if( type != PRINTTYPENONE )
		memcpy( outline+25, PRINTTYPETEXT[type], strlen(PRINTTYPETEXT[type]));
	sprintf( outline+72, PrintPage, pageNumber);
	pageNumber++;
	memcpy( outline+40, timeString, 25 );
	if( !dumpLine( outline, type ) ) return FALSE;

	if(  type == PRINTTYPEANALYSIS && readLen )
	{
		memset( outline, ' ', sizeof(outline));
		memcpy( outline, FilePrompt, fileLen );
		strcpy( outline+fileLen+1, ReadFile );
		if( !dumpLine( outline, type ) ) return FALSE;
	}
	memset( outline, '-', sizeof(outline)-1 );
	outline[ sizeof(outline )] = '\0';

	return dumpLine( outline, type );
}

/**
*
* Name		printHelp - Print a series of help blocks
*
* Synopsis	int printHelp( int context, int followLinks )
*
* Parameters
*		int context	- Context number to print
*		int followLinks - Walk the prev-next tree until they are printed
*		PRINTTITLETYPE type - What title type to use
*
* Description
*		walk help to the beginning of the series of topics and follow to
*	the end.  If followlinks false, just print this context.
*
*
* Returns	FALSE == Success
*
*
* Version	2.0
**/
int printHelp(			/*	Print help information */
	int context,		/*	Where to start */
	int followLinks,	/*	Find first in series and print series? */
	PRINTTITLETYPE type )			/*	What title to use */
{
	long thisContext;
	long next;
	long prev;

	thisContext = HelpInfo[context].contextNumber;

	if ( followLinks ) {
		/*	Move to the beginning of the current series */
		thisContext = contextHelp( HelpInfo[context].type,
			HelpInfo[context].contextNumber, &prev, &next );
		freeHelp();

		thisContext = prev;
		followLinks = thisContext != next;
	}

	if( !doHeader( type ) )
		goto error;

	do {
		if( printThisContext( thisContext, type ) )
			goto error;
		if( followLinks ) {
			thisContext = HelpNcNext( thisContext );
			if( thisContext > next )
				followLinks = FALSE;
		}
	} while( followLinks );

	return FALSE;

error:
	return TRUE;
}


/**
*
* Name		printAllHelp - Print all the help in a help file.
*
* Synopsis	int printAllHelp( int context, PRINTTITLETYPE type	)
*
* Parameters
*		int context	initial context to start printing with
*
* Description
*		Walk all the topics in a help file and dump them out.
*
*
* Returns	FALSE == OK - No Failure
*
*
* Version	2.0
**/
int printAllHelp(
	int context,				/*	Which help block to start printing */
	PRINTTITLETYPE type	)
{
	long thisContext;
	long lastContext;

	if( !doHeader( type ) )
		goto error;

	thisContext = HelpInfo[context].contextNumber;

	do {
		lastContext = thisContext;
		if( printThisContext( thisContext, type ) )
			goto error;
		thisContext = HelpNcNext( thisContext );
	} while( thisContext > lastContext );

	return FALSE;
error:
	return TRUE;
}

/**
*
* Name		printThisContext - Print a specific help context regardless of type.
*
* Synopsis	int printThisContext( long context, PRINTTITLETYPE type )
*
* Parameters
*		long context			what actual context
*		PRINTTITLETYPE type	What title to use
*
* Description
*		Dump a help block - Could be a Multiple help block
*
*
* Returns	FALSE == No Error
*
*
* Version	2.0
**/
int printThisContext( long context, PRINTTITLETYPE type )
{
	char line[MAXPRINTLINE], line2[MAXPRINTLINE];
	HELPDEF *thisHelp;
	HELPDEF fakeHelp;
	int row;
	int kk;

	/*	Get the context for this context number */
	for( thisHelp = HelpInfo;
		 thisHelp->type < HELP_LAST ;
		 thisHelp++ ) {
		if( thisHelp->contextNumber == context )
			break;
	}
	if( thisHelp->type == HELP_LAST ) {
		/*	Didn't find it, use a fake one built like the last one */
		thisHelp = &fakeHelp;
		fakeHelp.type = HelpWinType;
		fakeHelp.contextNumber = context;
		fakeHelp.helpBuild = NULL;
	}

	if( thisHelp->helpBuild ) {
		thisHelp->helpBuild( FALSE );
		for( kk = 0; kk < HelpTopicCnt; kk++ ) {
			thisHelp = HelpInfo+HelpArgNum[kk];
			contextHelp( thisHelp->type, thisHelp->contextNumber, NULL, NULL );
			if( PrintableHelp ) {
				for( row = 1;; row++ ) {

					if( getHelpLine( row, line ) == 0 )
						break;

					print_argsubs( line2, line );
					if( !dumpLine( line2, type ))
						goto error;

				}
			}
			freeHelp();
		}
	}
	else {
		contextHelp( thisHelp->type, thisHelp->contextNumber, NULL, NULL );
		if( PrintableHelp ) {
			for( row = 1;; row++ ) {

				if( getHelpLine( row, line ) == 0 )
					break;

				if( !dumpLine( line, type ))
					goto error;

			}
		}
		freeHelp();
	}

	return FALSE;
error:
	freeHelp();
	return TRUE;

}

/**
*
* Name		printEditor - Print all the lines in an edited file.
*
* Synopsis	int printEditor( PRINTTITLETYPE type )
*
* Parameters
*		PRINTTITLETYPE type	What title to use
*
* Description
*		Dump the file that is stored in the editor
*
*
* Returns	FALSE == No Error
*
*
* Version	2.0
**/
int printEditor( PRINTTITLETYPE type )
{
	int i;

	if( !doHeader( type ) )
		goto error;

	if( !printTitle( EditorFileName, type )) return FALSE;

	for (i = 0; i < EditorLines; i++) {
		if (EditorLine[i]) {
			if(!dumpLine( EditorLine[i], type ))
				return FALSE;
		} else
			if(!dumpLine( NULL, type ))
				return FALSE;
	}


	return FALSE;
error:
	return TRUE;

}

/**
*
* Name		printWindow - Print the current text window
*
* Synopsis	int printWindow( PTEXTWIN pWin, PRINTTITLETYPE type, int which )
*
* Parameters
*		PTEXTWIN pWin			Window to print
*		PRINTTITLETYPE type	What title to use
*		int which				What to print as the title
*
* Description
*	Walk a text window and dump it's text to output
*
*
* Returns	FALSE == No Error
*
*
* Version	2.0
**/
int printWindow( PTEXTWIN pWin, PRINTTITLETYPE type, int which )
{
	int row;
	char line[MAXPRINTLINE];

	if( !doHeader( type	) )
		goto error;

	if( type == PRINTTYPEANALYSIS )
		if( !printTitle( DataInfo[which].title, type )) return FALSE;


	for( row = 0; row < pWin->size.row; row++ ) {
		memset( line, 0, MAXPRINTLINE );
		vWinGet_s( pWin, row, line );
		if( !dumpLine( line, type ) )
			goto error;
	}

	return FALSE;
error:
	return TRUE;


}


/**
*
* Name		printAllData - Print all engine data
*
* Synopsis	int printAllData( void )
*
* Parameters
*
* Description
*	Walk all the data results and print them
*
*
* Returns	FALSE == No error
*
*
* Version	2.0
**/
int printAllData( void )
{
	if (!printInfo( INFO_MEM_SUMM, TRUE )
	&& !printInfo( INFO_MEM_LOW, FALSE )
	&& !printInfo( INFO_MEM_HIGH, FALSE )
	&& !printInfo( INFO_MEM_ROM, FALSE )
	&& !printInfo( INFO_MEM_INT, FALSE )
	&& !printInfo( INFO_MEM_EXT, FALSE )
	&& !printInfo( INFO_MEM_EXP, FALSE )
	&& !printInfo( INFO_MEM_EMS, FALSE )
	&& !printInfo( INFO_MEM_XMS, FALSE )
	&& !printInfo( INFO_MEM_TIME, FALSE )
	&& !printInfo( INFO_CFG_SUMM, FALSE )
	&& !printInfo( INFO_CFG_CONFIG, FALSE )
	&& !printInfo( INFO_CFG_AUTOEXEC, FALSE )) {

		if( ConfigMenu.items[CPPOS].type != ITEM_DISABLED ) {
			if( printInfo( INFO_CFG_386MAX, FALSE ))
				return TRUE;
		}

		if( !printInfo( INFO_HW_CMOS, FALSE )
		&& !printInfo( INFO_HW_SUMM, FALSE )
		&& !printInfo( INFO_HW_VIDEO, FALSE )
		&& !printInfo( INFO_HW_DRIVES, FALSE )
		&& !printInfo( INFO_HW_PORTS, FALSE )
		&& !printInfo( INFO_HW_BIOS, FALSE ))
			return FALSE;
	}
	return TRUE;
}

/**
*
* Name		printFile - Print the requested text file
*
* Synopsis	int printFile( char *name )
*
* Parameters
*		char *name			Name of file to print
*
* Description
*	Walk a text File and dump it's text to output
*
*
* Returns	FALSE == No Error
*
*
* Version	2.0
**/
int printFile( char *name )
{
	FILE *fh;
	char line[ MAXPRINTLINE ];
	int len;

	if( !doHeader( PRINTTYPEFILE	) )
		goto error;
	if( !printTitle( name, PRINTTYPEFILE	) )
		goto error;

	fh = fopen ( name, "r");
	if( !fh ) {
		errorMessage( 201 ); /* Unable to open file */
		goto error;
	}

	while( fgets( line, MAXPRINTLINE-1, fh ) != NULL ) {
		if( feof( fh ))
			break;
		len = strlen( line )-1;
		if( len < MAXPRINTLINE )
			line[len ] = '\0';      /*      Strip off cr */

		if(!dumpLine( line, PRINTTYPEFILE ))
				goto error;

	}
	return FALSE;
error:
	return TRUE;
}

/**
*
* title 	printTitle - Print the requested text file
*
* Synopsis	int printTitle( char *title )
*
* Parameters
*		char *title			title of file to print
*
* Description
*	Center the title to pos 40 with a blank line before and after
*
*
* Returns	FALSE == No Error
*
*
* Version	2.0
**/
int printTitle( char *title, int type )
{
	char line[ MAXPRINTLINE ];
	char *start;
	int len;
	len = strlen( title );

	memset( line, ' ', 40 );
	start = line + 40 - len / 2;
	strcpy( start, title );

	/*	Force to upper case */
	while ( *start)
	{
		*start = (char)toupper( *start );
		start++;
	}

	if(!dumpLine( NULL, type ))
		goto error;

	if(!dumpLine( line, type ))
		goto error;

	return dumpLine( NULL, type );

error:
	return TRUE;
}

/**
*
* Name		printInfo - Print analysis information
*
* Synopsis	void printInfo( int id, int first )
*
* Parameters
*			int id - Which piece of information to print
*			int first - Is this the first of 1 or more screens
*
* Description
*		This routine performs the requested information request and then
*	dumps the result to the printer.  It is filtered so that there are
*	all easily printable characters.
*
*
* Returns	FALSE = No Error
*
*
* Version	2.0
*
*	Change to capitalize the section title
*
**/
int printInfo( int id, int first )
{
	char *dataLine;
	ENGTEXT infoData;
	char stuff[256];

	if( first )
	{
		if( !doHeader( PRINTTYPEANALYSIS) ) return FALSE;
	} else
		if(!dumpLine( NULL, PRINTTYPEANALYSIS )) return FALSE;

	if( !printTitle( DataInfo[id].title, PRINTTYPEANALYSIS) ) return FALSE;

	/*	Initialize the data fetch */
	if (engine_control(CTRL_SETBUF,tutorWorkSpace, WORKSPACESIZE) != 0 ||
		engine_control(CTRL_ISETUP,&infoData,id) != 0)
	{
		errorMessage( 501 );
		return TRUE;
	}
	infoData.nbuf = sizeof(stuff);
	infoData.buf = stuff;

	while( engine_control(CTRL_IFETCH,&infoData,0) == 0 )
	{
		dataLine = infoData.buf+IEXTRA;
		if( (*infoData.buf)-CODE_BASE == CONTIN_LINE )
			dataLine[0] = ' ';

		switch( id )
		{
		case INFO_CFG_SUMM:
		case INFO_CFG_CONFIG:
		case INFO_CFG_AUTOEXEC:
		case INFO_CFG_386MAX:
			{
				/*	Strip out all char > 127 to ' ' */
				register unsigned char *cp = dataLine;
				while(*cp )
				{
					if( *cp > 127 )
						*cp = '.';
					cp++;
				}
				break;
			}
		}
		memset( infoData.buf, ' ', IEXTRA);

		if( !dumpLine( infoData.buf, PRINTTYPEANALYSIS ))
			return TRUE;
	}
	return FALSE;
}
