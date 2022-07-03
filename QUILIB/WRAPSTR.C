/*' $Header:   P:/PVCS/MAX/QUILIB/WRAPSTR.C_V   1.0   05 Sep 1995 17:02:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * WRAPSTR.C								      *
 *									      *
 * Functions to wrap text within a window				      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

/*	Program Includes */
#include "windowfn.h"
#include "commfunc.h"

/*	Definitions for this Module */

/*	Variables global static for this file */

/* Local functions */
static void jstr(	/* Justify string */
	char jflag,	/* Justify flag */
	WORD *buf,	/* String, space filled */
	int nc, 	/* Active chars in buf */
	int width);	/* Width of line */

/*	Program Code */
/**
*
* Name		wrapString
*
* Synopsis	void wrapString( WINDESC *win, char *text, char *attr )
*
* Parameters
*			WINDESC *win		Window to write into
*			char *text			What to write
*			char *attr		What colors
*
* Description
*		Wrap a text string into a window.  Does not process
*	tabs or bells, but does handle newlines and embedded color
*	escapes of the form <esc><n> where <n> selects attr[n], and
*	<esc> is an escape character, defined by the first character of
*	the string, if said character is a punctuation character.
*
* Returns	No return
*
* Version	1.00
*
**/
void wrapString(		/*	Word wrap a string into a window */
	WINDESC *win,		/*	Window to write into */
	char *text,		/*	String to write into - No tabs bells lf cr */
	char *attr)		/*	Video attributes */
{
	int column;		/* Column counter */
	int mark;		/* Column of last whitespace */
	int indent;		/* Amount to indent wrapped lines */
	BOOL iflag;		/* Indent-next-line flag */
	char justify;		/* Justification flag */
	char *markp;		/* Pointer to mark's place in text */
	char escchr;		/* Color escape char if nonzero */
	char color;		/* Current text color */
	WINDESC workWin;	/* Scratch window descriptor */
	WORD buf[80];		/* Scratch buffer to build one line of text */

	workWin = *win;
	workWin.nrows = 1;

	/* Pick up escape char if present */
	if (ispunct(*text)) {
		escchr = *text++;
	}
	else	escchr = '\0';

	/* Preset the scratch buffer */
	color = *attr;
	wordset(buf,VIDWORD(color,' '),sizeof(buf)/sizeof(buf[0]));
	column = mark = indent = 0;
	iflag = FALSE;
	justify = '\0';
	markp = NULL;
	while (*text) {
		char c;

		c = *text++;
	again:
		if (c == '\n') {
			/* Newline: justify, flush and reset */
			if (justify) {
				jstr(justify,buf,column,workWin.ncols);
			}
			wput_ca(&workWin,buf);
			workWin.row++;
			wordset(buf,VIDWORD(color,' '),sizeof(buf)/sizeof(buf[0]));
			column = mark = (iflag ? indent : 0);
			iflag = FALSE;
			justify = '\0';
			markp = NULL;
			continue;
		}
		else if (c == escchr) {
			/* Color escape */
			c = *text++;
			if (isdigit(c)) {
				color = attr[c - '0'];
				continue;
			}
			else if (c == '^' || c == '>') {
				justify = c;
				continue;
			}
			else if (c == '+') {
				c = *text++;
				if (isdigit(c)) {
					indent = c - '0';
				}
				continue;
			}
		}

		/* Normal character */
		if (column >= workWin.ncols) {
			/* No room on this line, wrap */
			if (mark && !isspace(c)) {
				wordset(buf+mark,VIDWORD(color,' '),column-mark);
				text = markp;
			}
			while (*text && isspace(*text)) text++;

			iflag = TRUE;	/* Signal indent */
			c = '\n';       /* Fake a newline */
			goto again;
		}
		else {
			/* Stuff it */
			buf[column] = VIDWORD(color,c);
			if (isspace(c)) {
				mark = column;
				markp = text;
			}
			column++;
		}
	} /*while*/
	if (column) {
		if (justify) {
			jstr(justify,buf,column,workWin.ncols);
		}
		wput_ca(&workWin,buf);
	}
}

static void jstr(	/* Justify string */
	char jflag,	/* Justify flag */
	WORD *buf,	/* String, space filled */
	int nc, 	/* Active chars in buf */
	int width)	/* Width of line */
{
	int nleft;

	if (nc < 1) return;

	switch (jflag) {
	case '>':
		/* Right justify */
		nleft = width - nc;
		break;
	case '^':
		/* Center */
		nleft = (width - nc) / 2;
		break;
	default:
		return;
	}

	if (nleft > 0) {
		WORD fill = buf[width-1];
		WORD *p1 = buf + nc - 1;
		WORD *p2 = p1 + nleft;

		while (nc > 0) {
			*p2-- = *p1--;
			nc--;
		}

		while (nleft > 0) {
			*p2-- = fill;
			nleft--;
		}
	}
}

/**
*
* Name		wrapStrlen
*
* Synopsis	int wrapStrlen( WINDESC *win, char *text )
*
* Parameters
*			WINDESC *win		Window to write into
*			char *text			What to write
*
* Description
*		Calculate the number of rows need to wrap a text string
*	into a window.	Uses the same algorithm as wrapString.
*
* Returns	No return
*
* Version	1.00
*
**/
int wrapStrlen( 		/*	Calculate length of wraped string */
	char *text,		/*	String to write into - No tabs bells lf cr */
	int ncols)		/*	How many columns in window */
	/* Return:  number of rows */
{
	int column;		/* Column counter */
	int mark;		/* Column of last whitespace */
	int nrows;		/* Rows in window */
	int indent;		/* Amount to indent wrapped lines */
	BOOL iflag;		/* Indent-next-line flag */
	char *markp;		/* Pointer to mark's place in text */
	char escchr;		/* Color escape char if nonzero */

	/* Pick up escape char if present */
	if (ispunct(*text)) {
		escchr = *text++;
	}
	else	escchr = '\0';

	nrows = 0;
	column = mark = indent = 0;
	iflag = FALSE;
	markp = NULL;
	while (*text) {
		char c;

		c = *text++;
	again:
		if (c == '\n') {
			/* Newline, flush and reset */
			nrows++;
			column = mark = (iflag ? indent : 0);
			iflag = FALSE;
			markp = NULL;
			continue;
		}
		else if (c == escchr) {
			/* Color/justify escape */
			c = *text++;
			if (isdigit(c) || c == '^' || c == '>') {
				continue;
			}
			else if (c == '+') {
				c = *text++;
				if (isdigit(c)) {
					indent = c - '0';
				}
				continue;
			}
		}

		/* Normal character */
		if (column >= ncols) {
			/* No room on this line, wrap */
			if (mark && !isspace(c)) {
				text = markp;
			}
			while (*text && isspace(*text)) text++;

			iflag = TRUE;
			c = '\n';       /* Fake a newline */
			goto again;
		}
		else {
			/* Stuff it */
			if (isspace(c)) {
				mark = column;
				markp = text;
			}
			column++;
		}
	} /*while*/
	return nrows;
}
#if 0
/** Old version of wrapString
*
* Name		oldwrapString
*
* Synopsis	void oldwrapString( WINDESC *win, char *text )
*
* Parameters
*			WINDESC *win		Window to write into
*			char *text			What to write
*
* Description
*		Wrap a text string into a window.  Don't allow for an special
*	characters like tabs or bells.
*
* Returns	No return
*
* Version	1.00
*
**/
void oldwrapString(		/*	Word wrap a string into a window */
	WINDESC *win,		/*	Window to write into */
	char *text )		/*	String to write into - No tabs bells lf cr */
{
	int left = strlen( text );
	WINDESC workWin;

	workWin.row = win->row;
	workWin.col = win->col;
	workWin.nrows = 1;

	do {
		char *end;

		/*	First clear to the end of the line */
		workWin.ncols = win->ncols;
		wput_sc( &workWin, ' ' );

		if( workWin.ncols > left )
			workWin.ncols = left;
		else {
			/*	Now set to the correct width - Either window or characters left */
			end = text + workWin.ncols;

			while( *end != ' '&& end > text )
				end--;

			if( end == text ) {
				/*	There is no word break, just use workWin.ncols characters */
				end = text+workWin.ncols;
			} else {
				workWin.ncols = end - text;
			}
		}
		wput_c( &workWin, text );

		/*	Now bump things to go around again */
		workWin.row++;
		text += workWin.ncols;
		left -= workWin.ncols;

		/* Gobble up white space */
		while( left && isspace( *text )) {
			text++;
			left--;
		}

	} while( left > 0 );

}
#endif /*0*/
