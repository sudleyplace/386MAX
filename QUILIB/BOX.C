/*' $Header:   P:/PVCS/MAX/QUILIB/BOX.C_V   1.0   05 Sep 1995 17:01:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * BOX.C								      *
 *									      *
 * Function to display a box						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>

/*	Program Includes */
#include "qwindows.h"

/*	Definitions for this Module */
						/*	 ul		 ur		 ll		 lr		 ud		 ss		*/
char singleBoxChars[6] = { '\xda', '\xbf', '\xc0', '\xd9', '\xb3', '\xc4' };

						/*	 ul		 ur		 ll		 lr		 ud		 ss	*/
char doubleBoxChars[6] = { '\xc9', '\xbb', '\xc8', '\xbc', '\xba', '\xcd' };

void box (					/*	Draw a box around the outside edge */
	WINDESC *win,			/*	Definition of what to draw in */
	BOXTYPE boxType,		/* Type of lines */
	char *title,			/*	Title for box or NULL */
	char *bottomTitle,		/*	Title for the bottom of the box or NULL */
	char attr )				/*	Attribute to use */
{
	#define UL	(charBase[0])
	#define UR	(charBase[1])
	#define LL	(charBase[2])
	#define LR	(charBase[3])
	#define UD	(charBase[4])
	#define SS	(charBase[5])

	int offset = win->col + win->ncols - 1;
	WINDESC work;
	char *charBase = ( boxType == BOX_SINGLE ) ? singleBoxChars : doubleBoxChars;

	/*	Draw top line */
	SETWINDOW( &work, win->row, win->col, 1, 1 );
	wput_sca( &work, VIDWORD( attr, UL ));

	/*	Draw line across the top */
	work.col++;
	work.ncols = win->ncols - 2;
	work.nrows = 1;
	wput_sca( &work, VIDWORD( attr, SS ));

	if( title ) {
		work.ncols = strlen( title );
		work.col += (win->ncols - work.ncols - 2) / 2;
		wput_c( &work, title );
	}

	/*	Upper right corner */
	work.col = offset;
	work.ncols = 1;
	wput_sca( &work, VIDWORD( attr, UR ));

	/*	Draw down the left */
	work.row = win->row+1;
	work.nrows = win->nrows - 2;
	work.col = win->col;

	wput_sca( &work, VIDWORD( attr, UD ));
	work.col = offset;
	wput_sca( &work, VIDWORD( attr, UD ));

	/*	Lower left corner */
	work.row += win->nrows - 2;		/*	Remember we were 1 line down */
	work.nrows = 1;
	work.col = win->col;
	wput_sca( &work, VIDWORD( attr, LL ));

	/* across the bottom */
	work.col++;
	work.ncols = win->ncols - 2;
	wput_sca( &work, VIDWORD( attr, SS ));

	if( bottomTitle ) {
		work.ncols = strlen( bottomTitle );
		work.col += (win->ncols - work.ncols - 2) / 2;
		wput_c( &work, bottomTitle );
	}

	/*	Lower right corner finally */
	work.col = offset;
	work.ncols = 1;
	wput_sca( &work, VIDWORD( attr, LR ));

}
