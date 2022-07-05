/*' $Header:   P:/PVCS/MAX/QUILIB/INTMSG.C_V   1.1   13 Oct 1995 12:12:30   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INTMSG.C								      *
 *									      *
 * Code for intermediate message screen 				      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

/* Local includes */
#include "commfunc.h"           /* Common functions */
#include "intmsg.h"             /* Intermediate message functions */
#include "ui.h"                 /* UI functions */
#include "libcolor.h"
#include "myalloc.h"            /* Memory allocator */


typedef struct _intmsgwin {	/* Control structure for intmsg window */
	WINDESC win;		/* Window descriptor */
	char *attr;		/* Video attribute */
	WORD *buff;		/* Pointer to video data buffer */
	int xcur;		/* X cursor position */
	int ycur;		/* Y cursor position */
} INTMSGWIN;

static INTMSGWIN IntMsg = { { 0,0,0,0 }, NULL, NULL, 0, 0 };
static char *IntMsgFmtBuf = NULL;
static char IntMsgColors[2];

#define DEFAULTINDENT 12
static int IntMsgIndent = DEFAULTINDENT;


/* Local functions */
static void fmt_intmsg( 	/* Format intmsg string into buffer */
	INTMSGWIN *imsg,	/* Window control structure */
	char *text,		/* Pointer to text string */
	int color);		/* Index to video attribute */

static void scroll_intmsg(	/* Scroll intmsg buffer up or down */
	INTMSGWIN *imsg,	/* Window controls */
	int count);		/* How many lines to scroll + for up, - for down */

/*************************** INTMSG_SETUP **********************************/

void intmsg_setup(int indent)	/* Set up the window for dointmsg() */

{
	int area;

	if (indent > 0 && indent < 40)
		IntMsgIndent = indent;
	else
		IntMsgIndent = DEFAULTINDENT;

	/* Set up the basic windows */
	SETWINDOW(&IntMsg.win,
		DataWin.row+1,
		DataWin.col+1,
		DataWin.nrows-2,
		DataWin.ncols-2);

	/* Set up formating controls */
	area = IntMsg.win.nrows * IntMsg.win.ncols;
	IntMsgColors[0] = DataColor;
	IntMsgColors[1] = DataYellowColor;

	IntMsg.buff	= my_malloc(area * sizeof(WORD));
	IntMsgFmtBuf	= my_malloc(512);
	if (!IntMsg.buff || !IntMsgFmtBuf) {
		/* Out of memory */
		errorMessage(215);
		abortprep(0);
		exit(2);
	}

	IntMsg.xcur	= IntMsg.ycur = 0;
	IntMsg.attr	= IntMsgColors;
	wordset(IntMsg.buff,VIDWORD(*IntMsg.attr,' '),area);
}

/**************************** INTMSG_SAVE **********************************/

void intmsg_save(void)	/* Save intmsg window */
{
	/* Nothing to do */
}

/*************************** INTMSG_RESTORE ********************************/

void intmsg_restore(void)	/* Restore dointmsg() window */
{
	/* Put it back up on screen */
	if (IntMsg.buff) {
		wput_ca(&IntMsg.win,IntMsg.buff);
	}
}

/***************************** INTMSG_CLEAR ********************************/

void intmsg_clear(void) /* Remove intmsg window */
{
	wput_sca(&IntMsg.win,VIDWORD(*IntMsg.attr,' '));
	if (IntMsg.buff) {
		my_free(IntMsg.buff);
		IntMsg.buff = NULL;
	}
	if (IntMsgFmtBuf) {
		my_free(IntMsgFmtBuf);
		IntMsgFmtBuf = NULL;
	}
}

/**************************** INTMSG_INDENT ********************************/

void intmsg_indent(int indent)	/* Set intmsg indent */
{
	if (indent < 0) indent = DEFAULTINDENT; /* < 0 means reset to default */
	if (indent >= 0 && indent <= 25)
		IntMsgIndent = indent;
}

/******************************** DO_INTMSG ********************************/

void _cdecl do_intmsg(char *format,...) /* Print intermediate message */
{
	int kk;
	int nc, res;
	char *p, *q, *q2, *l1, *l2, left[40];
	va_list arglist;

	/* Format the arguments */

	va_start(arglist, format);

	if (SnapshotOnly) {
	 vprintf (format,arglist);
	 return;
	}

	vsprintf(IntMsgFmtBuf,format,arglist);

	/* Pick off first token */
	q = strchr (IntMsgFmtBuf, ' ');
	if (q) {
		*q = '\0';
		/* Pick off second token */
		q2 = strchr (q+1, ' ');
		if (q2) *q2 = '\0';
	} /* if (q) */

	p = IntMsgFmtBuf;

	for (kk = 0; l1 = IntMsgStrList[kk]; kk++) {
		/* Check keyword for embedded space */
		l2 = strchr (l1, ' ');
		if (l2) *l2 = '\0';
		res = (
			_stricmp(p,l1) == 0 &&	       /* First token matches */
			(l2 == NULL ||		       /* Second doesn't exist*/
			   (q && !_stricmp(l2+1, q+1))  /* or also matches     */
			)
		       );
		if (l2) *l2 = '\0';             /* Restore contents of list */
		if (res) {
			if (l2) {		/* A dual-keyword match */
				*q = ' ';       /* Put the space back in */
				q = q2; 	/* Move up one */
				q2 = NULL;
			} /* l2 != NULL */
			break;
		}
	} /* for (kk...) */

	if (q && q2)	*q2 = ' ';              /* Restore end of second token*/

	if (l1) {
		/* If leading token matches our list */
		/* _write out in white with trailing colon */
		strcpy (left, p);
		strcat (left, ":");
		nc = strlen(left);
		if (nc < IntMsgIndent) {
			memset(left+nc,' ',IntMsgIndent-nc);
			left[IntMsgIndent] = '\0';
		}
		fmt_intmsg(&IntMsg,left,1);
		if (q) {
			fmt_intmsg(&IntMsg,q + 1,0);
		}
	}
	else {
		if (q) *q = ' ';
		fmt_intmsg(&IntMsg,p,1);
	}

	/* Put it up on screen */
	wput_ca(&IntMsg.win,IntMsg.buff);

	/* Place cursor just after message, in case other routines
	 * (like maximize()) want to _write */
	show_cursor();
	move_cursor(IntMsg.win.row+IntMsg.ycur,
		    IntMsg.win.col+IntMsg.xcur);
	hide_cursor();

} /* End DOINTMSG */


static void fmt_intmsg( 	/* Format intmsg string into buffer */
	INTMSGWIN *imsg,	/* Window control structure */
	char *text,		/* Pointer to text string */
	int color)		/* Index to video attribute */
{
	int mark;		/* Column of last breakpoint char */
	int wrap;		/* Wrapped-line flag */
	char *markp;		/* Pointer to mark's place in text */
	WORD *datap;		/* Pointer into window data */

	mark = wrap = 0;
	markp = NULL;
	datap = imsg->buff + imsg->xcur + (imsg->ycur * imsg->win.ncols);
	while (*text) {
		char c;

		c = *text++;
	again:
		if (c == '\n') {
			imsg->xcur = 0;
			if (imsg->ycur >= imsg->win.nrows - 1) {
				scroll_intmsg(imsg,1);
			}
			else imsg->ycur++;
			datap = imsg->buff + imsg->xcur + (imsg->ycur * imsg->win.ncols);
			if (wrap) {
				/* Indent wrapped lines */
				if (IntMsgIndent > 0) {
					wordset(datap,VIDWORD(imsg->attr[color],' '),IntMsgIndent);
					datap += IntMsgIndent;
					imsg->xcur += IntMsgIndent;
				}
			}
			mark = wrap = 0;
			markp = NULL;
		}
		else {
			if (imsg->xcur >= imsg->win.ncols) {
				if (mark && !isspace(c)) {
					int nc = imsg->xcur - mark;
					wordset(datap-nc,VIDWORD(imsg->attr[color],' '),nc);
					text = markp;
				}
				while (*text && isspace(*text)) text++;

				wrap = 1;
				c = '\n';
				goto again;
			}
			else {
				*datap++ = VIDWORD(imsg->attr[color],c);
				if (isspace(c)) {
					mark = imsg->xcur;
					markp = text;
				}
#if 0
				else if (ispunct(c) && *(text+1) && imsg->xcur+1 < imsg->win.ncols) {
					mark = imsg->xcur + 1;
					markp = text;
				}
#endif
			}
			imsg->xcur++;
		}
	}
}

static void scroll_intmsg(	/* Scroll intmsg buffer up or down */
	INTMSGWIN *imsg,	/* Window controls */
	int count)		/* How many lines to scroll + for up, - for down */
{
	int nn;
	WORD *from;
	WORD *to;

	if (count == 0) return;
	else if (abs(count) > imsg->win.nrows) {
		/* Clear the screen, I mean buffer */
		wordset(imsg->buff,VIDWORD(*imsg->attr,' '),imsg->win.nrows * imsg->win.ncols);
	}
	else if (count > 0) {
		/* Scroll up */
		from = imsg->buff + (count * imsg->win.ncols);
		to = imsg->buff;
		nn = imsg->win.nrows - count;
		wordcpy(to,from, nn * imsg->win.ncols);
		to += nn * imsg->win.ncols;
		wordset(to,VIDWORD(*imsg->attr,' '),count * imsg->win.ncols);
	}
	else {
		/* Scroll down */
		count = -count;
		from = imsg->buff;
		to = imsg->buff + (count * imsg->win.ncols);
		wordrcpy(to,from, (imsg->win.nrows - count) * imsg->win.ncols);
		wordset(imsg->buff,VIDWORD(*imsg->attr,' '),count * imsg->win.ncols);
	}
}
