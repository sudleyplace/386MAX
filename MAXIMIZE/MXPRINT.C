/*' $Header:   P:/PVCS/MAX/MAXIMIZE/MXPRINT.C_V   1.0   05 Sep 1995 16:33:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MXPRINT.C								      *
 *									      *
 * Maximize printing routines						      *
 *									      *
 ******************************************************************************/

/*	Standard C includes */
#include <bios.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

/*	Program includes */
#include <commfunc.h>
#include <button.h>
#include <editwin.h>
#include <libcolor.h>
#include <libtext.h>
#include <qprint.h>
#include <qhelp.h>
#include <qwindows.h>
#include <ui.h>
#include <myalloc.h>

#define MXPRINT_C			/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#undef MXPRINT_C


/*	Definitions for this Module */
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

int printHelp( int context, int followLinks,PRINTTITLETYPE type );
int printAllHelp( int context, PRINTTITLETYPE type	);
int printWindow( PTEXTWIN pWin, PRINTTITLETYPE type, int which );
int printTitle( char *title, int type );


void killPrinting( void );
void sayPage( void );
void sayPrinting( void );


/**
*
* Name		doPrintCallBack
*
* Synopsis	void doPrintCallBack( PTEXTWIN pWin, PRINTTYPE type, int which, int helpNum)
*
* Parameters
*			PTEXTWIN pWin;			Pointer to the current text window
*			PRINTTYPE type; 		What type of window this is
*			int helpNum,			What help number this is
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
	int helpNum)			/*	What help number this is */
{
	int errorOut = FALSE;

	/*
	*	First set up the print destionation and set up the printer
	*/
	pageNumber = 1;

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
	case P_HELP:
		if( P_Help.items[0].state.checked ) {
			/*	Print the current Help selection */
			if( pWin )
				errorOut = printWindow( pWin, PRINTTYPEHELP, which );
			else
				errorOut = printHelp( helpNum, FALSE, PRINTTYPEHELP );

		}
		if( !errorOut && P_Help.items[1].state.checked ) {
			/*	Print all the help topics */
			errorOut = printAllHelp( helpSystem, PRINTTYPEHELP );
		}
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
SAYPRINT_RETURN:
	visible_mouse (1); // Always leave mouse cursor visible

}


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
			if( testButton( event.key, TRUE ) )
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
	long timeOut;
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
		if( time(NULL) > timeOut ) break;
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
	char startCText[30];
	long thisContext;
	long next;
	long prev;
	char line[MAXPRINTLINE];
	char line2[MAXPRINTLINE];
	int row;
	int findBeginning = followLinks;

	HELPTYPE hType = HelpInfo[context].type;
	strcpy( startCText, HelpInfo[context].context);

	thisContext = setHelp( hType, startCText, &prev, &next );

	if ( findBeginning ) {
		/*	Move to the begging of the current series */
		if( thisContext != prev ) {
			freeHelp();
			thisContext = contextHelp( hType, prev, NULL, NULL );
		}
	}

	if( !doHeader( type ) )
		goto error;
	do {
		for( row = 1; ; row++ ) {
			if( getHelpLine( row, line ) == 0 )
				break;

			print_argsubs(line2,line);

			if( !dumpLine( line2, type ) )
				goto error;
		}
		freeHelp();
		if( followLinks ) {
			if( thisContext == next )
				followLinks = FALSE;
			else {
				thisContext = nextContextHelp( hType, thisContext );
				if( !thisContext )
					followLinks = FALSE;
			}
		}
	} while( followLinks );

	return FALSE;

error:
	freeHelp();
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
	int context,				/*	Which file of info to print */
	PRINTTITLETYPE type	)
{
	int followLinks = TRUE;
	long thisContext;
	long lastContext;
	int row;
	char line[MAXPRINTLINE];
	char line2[MAXPRINTLINE];

	HELPTYPE hType = HelpInfo[context].type;
	char *contextString = HelpInfo[context].context;

	thisContext = setHelp( hType, contextString, NULL, NULL );

	if( !doHeader( type ) )
		goto error;
	do {
		for( row = 1; ; row++ ) {
			if( getHelpLine( row, line ) == 0 )
				break;

			if (!PrintableHelp) continue;

			print_argsubs(line2,line);

			if( !dumpLine( line2, type ) )
				goto error;
		}

		lastContext = thisContext;
		thisContext = nextContextHelp( hType, thisContext );
	} while( lastContext < thisContext );
	freeHelp();

	return FALSE;
error:
	freeHelp();
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

	if (which);

	if( !doHeader( type	) )
		goto error;

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
	while ( *(++start))
	{
		*start = (char)toupper( *start );
	}

	if(!dumpLine( NULL, type ))
		goto error;

	if(!dumpLine( line, type ))
		goto error;

	return dumpLine( NULL, type );

error:
	return TRUE;
}
