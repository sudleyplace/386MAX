/*' $Header:   P:/PVCS/MAX/QUILIB/JUSTSTR.C_V   1.0   05 Sep 1995 17:02:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * JUSTSTR.C								      *
 *									      *
 * Display a justified string						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>

/*	Program Includes */
#include "qwindows.h"
#include "windowfn.h"

/*	Definitions for this Module */


/*	Program Code */
/**
*
* Name		justifyString - Show a justified string in a single line window
*
* Synopsis	void justifyString( WINDESC *win, char *string, int triggerPos,
							JUSTIFY justify, char attr, char tAttr )
*
* Parameters
*	WINDESC *win,				Where to draw the string
*	char *string,				What to draw
*	int triggerPos, 			Trigger position - -1 for none
*	JUSTIFY justify,			How to justify the string
*	char attr,					Regular attribute color
*	char tAttr				Trigger color
*
* Description
*		Justify the specified string in the window.  Do not write
*	blank characters around it.  Caller's responibility to clear the window
*	Set the trigger attribute - Ignored if triggerPos == -1.
*	Routine designed for a 1 line string ONLY!!!!!!
*
* Returns	No return.
*
* Version	1.0
*/
void justifyString(			/*	Show a justified string in a single line window */
	WINDESC *win,			/*	Where to draw the string */
	char *string,			/*	What to draw */
	int triggerPos, 		/*	Trigger position - -1 for none */
	JUSTIFY justify,		/*	How to justify the string */
	char attr,				/*	Regular attribute color */
	char tAttr )			/*	Trigger color */
{
	int length = strlen( string );
	WINDESC tempWin;

	tempWin.row = win->row;
	tempWin.nrows = 1;
	tempWin.ncols = length;

	switch (justify) {
	case JUSTIFY_LEFT:
		tempWin.col = win->col;
		break;
	case JUSTIFY_CENTER:
		tempWin.col = win->col + ( win->ncols - length )/2;
		break;
	case JUSTIFY_RIGHT:
		tempWin.col = win->col + win->ncols - length;
		break;
	}

	/*	Blast out the text */
	wput_csa( &tempWin, string, attr );

	if( triggerPos != -1 ) {
		tempWin.col += triggerPos;
		tempWin.ncols = 1;
		wput_a( &tempWin, &tAttr );
	}

}
