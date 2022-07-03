/*' $Header:   P:/PVCS/MAX/MAXIMIZE/BROWSE.C_V   1.1   13 Oct 1995 12:00:46   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * BROWSE.C								      *
 *									      *
 * Support routines for pass 2 and 3 browse				      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Local includes */
#include <ui.h> 		/* UI functions */
#include <editwin.h>		/* ..to get scroll bar functions */

#define BROWSE_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef BROWSE_C

#ifndef PROTO
#include "browse.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
#define BWINDCOLS  76	/* Browse window columns */
/*#define BWINDROWS  20 -- Browse window rows */
#define BACTCOLS   11	/* Columns for action items */
#define BLINEDOWN  11
#define BWINDSROW   2	/* Starting row */
#define BWINDSCOL   1	/* Starting column */

#define BR_ROWS    BwindRows-3		/* Number of visible rows */
/*	(2 for lines 0-1) */
#define BR_COLS    (BWINDCOLS - (BACTCOLS + 2)) /* Number visible cols */
/*	(2 for vertical border and scroll bar) */

#define LNONE	0
#define LHIGH	1
#define LLOW	2
#define LMAX	3
#define LLONG	4
#define LWARN	5

#define NCOLS 200	/* Maximum text columns */

static int BwindRows = 20;	/* Rows in browse window */

static BOOL IntroDone = 0; /* TRUE if intro panel already displayed */

static WINDESC VsbWin;	/* Vertical scroll bar window */
static int VsbMax;	/* Vertical scroll bar max value */
static int VsbCur;	/* Vertical scroll bar current pos */

static WINDESC HsbWin;	/* Horizontal scroll bar window */
static int HsbMax;	/* Horizontal scroll bar max value */
static int HsbCur;	/* Horizontal scroll bar current pos */

static WINDESC HitWin;	/* Window for mouse hits on text lines */
static int HitRow;	/* Row of mouse hit */

/* Non-button keys recognized by browse routine */
static KEYCODE OkKeys[] = {
	KEY_CHOME, KEY_CEND, KEY_PGUP, KEY_PGDN, KEY_UP,
	KEY_DOWN, KEY_RIGHT, KEY_LEFT, KEY_HOME, KEY_END,
	KEY_CPGUP, KEY_CPGDN, KEY_CUP, KEY_CDOWN, KEY_TAB,
	KEY_STAB, 0
};

/* Local functions */
static KEYCODE br_input(	/* Input callback function */
	INPUTEVENT *event);	/* Event from dialog_input() */


/* Local functions */

/***************************** DO_BROWSE ***********************************/
/* Controlling routine for pass 2 & 3 browse screens */

#pragma optimize ("leg",off) /* Function too large for... */
int do_browse (
	int ndx,			/* Index into FILES */
	BOOL first,			/* TRUE if this is the first file */
	BOOL last,			/* TRUE if this is the last file */
	BOOL grouping,			/* TRUE for grouping, FALSE for toggle */
	char *intromsg, 		/* Intro message context string */
	int helpnum,			/* Help context number */
	char (*actcolors)[2][2],	/* Action window colors */
	char (*txtcolors)[2][2],	/* Text window colors */
	char *(*bldfn)(DSPTEXT *dsp),	/* Text line builder function */
	char *(*acttext)(DSPTEXT *dsp), /* Action text builder function */
	int (*toggle)(			/* Toggle function */
		int ndx,		/* Index into FILES */
		BOOL first,		/* TRUE if this is the first file */
		BOOL last,		/* TRUE if this is the last file */
		WINDESC *actwin,	/* Descriptor for action window */
		WINDESC *txtwin,	/* Descriptor for text window */
		TEXTHD **dsparray,	/* Display text array */
		int trows,		/* Total rows */
		int ctrow,		/* Current top row */
		int cbrow,		/* Current bottom row */
		int crow,		/* Current row */
		char *(*bldfn)(DSPTEXT *dsp))	/* Text line builder function */
	)
{
	int chg;
	int ii;
	int trows;	/* Total rows to be displayed	 */
	int nrows;	/* Number of visible rows in window */
	int otrow;	/* Top visible line previous pass */
	int ctrow;	/* Top visible line */
	int cbrow;	/* Bottom visible line */
	int crow;	/* Current row in linked list */
	int ccol;	/* Current column in virtual screen */
	int lcol;	/* Screen size for panning */
	int titems;	/* Total marked items in the file   */
	int rtn;	/* Return value: -1, 0, +1 */
	BOOL buttons_hot; /* TRUE when browse buttons are hot */
	WINDESC mainwin;/* Descriptor for main window */
	WINDESC actwin; /* Descriptor for action window */
	WINDESC txtwin; /* Descriptor for text window */
	TEXTHD *head = NULL;
	TEXTHD *tail = NULL;
	TEXTHD *tl, **dsparray;
	DSPTEXT *t, *ts;

	/* Build the display panel */
	br_setup(ActiveFiles[ndx],&mainwin,&actwin,&txtwin,grouping);
	SETWINDOW(&HitWin,actwin.row,actwin.col,actwin.nrows,mainwin.ncols);
	buttons_hot = FALSE;

	ts = HbatStrt[ndx];

	/*---------------------------------------------------------*/
	/*	Remove blank string entries from list		       */
	/*---------------------------------------------------------*/

	for (t = ts ; t ; t = t->next) {
		if (lcm (t->text, " ") != 0)
			break;
		ts = t;
	} /* End FOR */

	/* Get to end of list */
	for (t = ts ; t->next ; t = t->next)
		;

	/* What's going on here?  Shouldn't we be freeing something? */
	for ( ; t->prev ; t = t->prev) {
		if (lcm (t->text, " ") != 0)
			break;
		if (t->prev)		/* Remove blank string by eliminating */
			t->prev->next = NULL; /* structure from linked list */
	} /* End FOR */

	/* Build linked list of DSPTEXT entries */
	/* and return the # rows */
	trows = br_buildln (ts, bldfn, &head, &tail);

	/*
	 *---------------------------------------------------------
	 *	Build an array of addresses to structures
	 *  dsparray is an array of (TEXTHD *), containing pointers to
	 *  each item of the TEXTHD list defined by head/tail
	 *---------------------------------------------------------
	 */

	dsparray = get_mem ((trows + 2) * sizeof (TEXTHD *));
	titems = 0;
	for (ii = 0, tl = head; tl; tl = tl->next, ii++) {
		dsparray[ii] = tl;
		if (dsparray[ii]->disp->mark ||
		    dsparray[ii]->disp->umb)	/* While doing so, count */
			titems++;				/* marked items */
	} /* End FOR */

	rtn = 0;	/* Set a sane default value in case we bail out */

	/* If no marked items, bailout */
	if (!titems) {
		goto bottom;
	}

	/*------------------------------------------------------*/
	/*	Position crow to a marked item for 1st display	*/
	/*	crow is set to zero if no items are marked	*/
	/*------------------------------------------------------*/

	for (crow = 0 ; titems && dsparray[crow]->disp->mark == 0 ; crow++)
		;

	/*---------------------------------------------------------*/
	/*	Push that line toward center of the display	       */
	/*---------------------------------------------------------*/

	for (ii = 0, cbrow = crow ; ii < (txtwin.nrows / 2) && cbrow < trows ; ii++, cbrow++)
		;

	nrows = (int) min (txtwin.nrows, trows);
	ctrow = cbrow - nrows;
	if (crow == 0)
		ctrow = -1;
	while (ctrow < 0) {
		ctrow++;
		cbrow = ctrow + nrows;
	} /* End WHILE */

	otrow = -1;	 /* Initalize old top row */
	lcol = ccol = 0;

	if (trows > txtwin.nrows) {
		/* Set up scroll bar */
		SETWINDOW(&VsbWin,
			txtwin.row,
			txtwin.col+txtwin.ncols,
			txtwin.nrows,
			1);
		VsbMax = trows-txtwin.nrows;
	}
	else {
		VsbMax = 0;
	}

	/* Establish maximum panning parameter */
	for (lcol = ii = 0 ; ii < trows ; ii++)
		lcol = (int) max (lcol, (int) (1 + strlen (dsparray[ii]->textline)));

	if (lcol > (NCOLS-1))	/* Make sure it's not larger than screen */
		lcol = NCOLS-1;

	if (lcol > txtwin.ncols) {
		/* Set up scroll bar */
		SETWINDOW(&HsbWin,
			txtwin.row+txtwin.nrows,
			txtwin.col,
			1,
			txtwin.ncols);
		HsbMax = lcol-txtwin.ncols;
	}
	else	HsbMax = 0;

	/*------------------------------------------------------*/
	/*	Processing loop 				*/
	/*------------------------------------------------------*/

	for (chg=1;;) {
		int marked;	/* 1 if current row is marked */
		int cwrow;	/* Current row in window */
		KEYCODE key = 0;	/* Anything not ESCAPE */

		/*-----------------------------------------------------*/
		/* If column invalid, set to a valid value	       */
		/*-----------------------------------------------------*/

		if (ccol < 0)
			ccol = 0;

		if (ccol > (lcol - txtwin.ncols))
			ccol = max (0, lcol - txtwin.ncols);

		/*-----------------------------------------------------*/
		/* If row invalid, set to a valid value 	       */
		/*-----------------------------------------------------*/

		if (crow < 0)	       crow = 0;
		if (crow > trows - 1)  crow = trows - 1;

		/*-----------------------------------------------------*/
		/* If current row outside of window, rebuild window    */
		/*-----------------------------------------------------*/

		cbrow = ctrow + nrows - 1;
		while (crow < ctrow) {
			ctrow--;
			cbrow = ctrow + nrows - 1;
		} /* End WHILE */

		while (crow > cbrow) {
			ctrow++;
			cbrow = ctrow + nrows - 1;
		} /* End WHILE */

		if ((otrow != ctrow) || chg) {
			int jj;

			/*------------------------------------------------------*/
			/*	Redraw the text portions of the window		*/
			/*------------------------------------------------------*/

			for (ii = 0, jj = ctrow ; ii < nrows ; ii++, jj++) {
				marked = dsparray[jj]->disp->mark ? 1 : 0;
				br_wrtact(&actwin,
					(*acttext)(dsparray[jj]->disp),
					(*actcolors)[0][marked],
					ii);
				br_wrttext(&txtwin,
					dsparray[jj]->textline,
					(*txtcolors)[0][marked],
					ii,
					ccol);
			}
			otrow = ctrow;
			chg = 0;
		}
		cwrow = crow - ctrow;
		marked = dsparray[crow]->disp->mark ? 1 : 0;

		/*-----------------------------------------------------*/
		/* Highlight the current line			       */
		/*-----------------------------------------------------*/

		br_highlight(&actwin,&txtwin,cwrow,
			(*actcolors)[1][marked],
			(*txtcolors)[1][marked]);

		ii = ccol + txtwin.ncols - 1;
		if (ii > lcol)
			ii = lcol;

		/*-----------------------------------------------------*/
		/* Update the scroll bar			       */
		/*-----------------------------------------------------*/

		if (VsbMax) {
			VsbCur = ctrow;
			paintScrollBar(&VsbWin,BrScrollBar,VsbMax,VsbCur);
		}

		if (HsbMax) {
			HsbCur = ccol;
			paintScrollBar(&HsbWin,BrScrollBar,HsbMax,HsbCur);
		}

		/*-----------------------------------------------------*/
		/* Display help screen the first time through	       */
		/*-----------------------------------------------------*/

		if (!IntroDone) {
			/* Display help screen the first time through */
			message_panel(intromsg,helpnum);
			IntroDone = 1;
		}

		if (!buttons_hot) {
			/* Enable selected buttons */
			/* This has to happen here so that buttons will be
			 * cold until after the intro panel */
			disableButton(DONE_KEY,FALSE);
			if (!first) disableButton(PREV_KEY,FALSE);
			if (!last)  disableButton(NEXT_KEY,FALSE);
			buttons_hot = TRUE;
		}

		if (grouping || dsparray[crow]->disp->mark)
			disableButton(TOGGLE_KEY,FALSE);
		else
			disableButton(TOGGLE_KEY,TRUE);

		/* INPUT HAPPENS HERE */
		HitRow = -1;
		key = dialog_input(helpnum,br_input);

		/*-----------------------------------------------------*/
		/* Un-higlight the current line 		       */
		/*-----------------------------------------------------*/

		if (key != TOGGLE_KEY) {
			br_highlight(&actwin,&txtwin,cwrow,
				(*actcolors)[0][marked],
				(*txtcolors)[0][marked]);
		}

		/*-----------------------------------------------------*/
		/* Process the keystroke			       */
		/*-----------------------------------------------------*/

		switch (key) {
		case TOGGLE_KEY:	/* Toggle */
			if (HitRow >= 0) {
				crow = HitRow + ctrow;
			}
			chg = (*toggle)(ndx,first,last,
				&actwin,&txtwin,dsparray,
				trows,ctrow,cbrow,crow,bldfn);

			break;
		case KEY_CHOME:
			crow = -1;
			break;
		case KEY_CEND:
			crow = 500;
			break;
		case KEY_CUP:
			if (ctrow > 0) {
				crow--;
				ctrow--;
				cbrow--;
			}
			break;
		case KEY_CDOWN:
			if (cbrow+1 < trows) {
				crow++;
				ctrow++;
				cbrow++;
			}
			break;
		case KEY_PGUP:
			crow -= nrows - 1;
			ctrow -= nrows - 1;
			cbrow -= nrows - 1;
			while (ctrow < 0)
			{
				ctrow++;
				cbrow++;
				crow++;
			}
			break;
		case KEY_PGDN:
			crow += nrows - 1;
			ctrow += nrows - 1;
			cbrow += nrows - 1;
			while (cbrow >= trows)
			{
				crow--;
				ctrow--;
				cbrow--;
			}
			break;
		case KEY_UP:
			crow--;
			break;
		case KEY_DOWN:
			if (HitRow >= 0) {
				crow = HitRow + ctrow;
			}
			else {
				crow++;
			}
			break;
		case KEY_RIGHT:
			ccol++;
			chg = 1;
			break;
		case KEY_LEFT:
			ccol--;
			chg = 1;
			break;
		case KEY_HOME:
			ccol = 0;
			chg = 1;
			break;
		case KEY_END:
			ccol = 1 + strlen(dsparray[crow]->textline);
			ccol -= txtwin.ncols;
			chg = 1;
			break;
		case KEY_CPGDN:
			ccol += txtwin.ncols;
			chg = 1;
			break;
		case KEY_CPGUP:
			ccol -= txtwin.ncols;
			chg = 1;
			break;
		case KEY_AF11:	/* Vertical scroll bar move */
			{
				int delta;

				delta = VsbCur - ctrow;
				ctrow += delta;
				cbrow += delta;
				crow += delta;
				while (ctrow < 0) {
					ctrow++;
					cbrow++;
					crow++;
				}
				while (cbrow >= trows) {
					crow--;
					ctrow--;
					cbrow--;
				}
			}
			break;
		case KEY_AF12:	/* Horizontal scroll bar move */
			ccol = HsbCur;
			chg = 1;
			break;
/* #if 0 */
		case KEY_TAB:
			for (;;) {
				if (crow == trows - 1)
					crow = 0;
				else
					crow++;
				if (dsparray[crow]->disp->mark)
					break;
			} /* End WHILE */
			break;

		case KEY_STAB:
			for (;;)
			{
				if (crow == 0)
					crow = trows - 1;
				else
					crow--;
				if (dsparray[crow]->disp->mark)
					break;
			} /* End WHILE */
			break;
/* #endif */
		case PREV_KEY:	/* Prev */
			if (!first) {
				rtn = -1;
				goto bottom;
			} /* End IF */
			break;

		case NEXT_KEY:	/* Next */
			if (!last) {
				rtn = 1;
				goto bottom;
			} /* End IF */
			break;

		case KEY_ESCAPE:
			AnyError = AbyUser = 1;
		case DONE_KEY:	/* Done */
			rtn = 0;
			goto bottom;
		default:
			/* This is for testing, should never happen */
			putchar('\007');
		} /* End SWITCH */
	} /* End WHILE */
bottom:
	br_clear(&mainwin);
	br_freedsp (dsparray);
	return rtn;
} /* End do_browse */
#pragma optimize ("",on)

static KEYCODE br_input(	/* Input callback function */
	INPUTEVENT *event)	/* Event from dialog_input() */
{
	if (event->key) {
		/* Check our local valid key list */
		KEYCODE *kp;

		for (kp = OkKeys; *kp; kp++) {
			if (*kp == event->key) {
				return event->key;
			}
		}
		return 0;
	}

	/*fprintf(stdaux,"x,y = %04x, %04x\r\n",event->x,event->y);*/
	if (VsbMax) {
		/* Try the vertical scroll bar */
		WINRETURN wrtn;

		/*fprintf(stdaux,"VsbCur = %04X\r\n",VsbCur);*/
		wrtn = testScroll(&VsbWin,event,VsbMax,&VsbCur);
		/*fprintf(stdaux,"VsbCur = %04X, wrtn = %04X\r\n",VsbCur,wrtn);*/

		switch(wrtn) {
		case WIN_UP:	return KEY_UP;
		case WIN_DOWN:	return KEY_DOWN;
		case WIN_PGUP:	return KEY_PGUP;
		case WIN_PGDN:	return KEY_PGDN;
		case WIN_TOP:	return KEY_CHOME;
		case WIN_BOTTOM:return KEY_CEND;
		case WIN_MOVETO:
			return KEY_AF11;
		case WIN_OK:
			return 0;
		}
	}

	if (HsbMax) {
		/* Try the vertical scroll bar */
		WINRETURN wrtn;

		/*fprintf(stdaux,"HsbCur = %04X\r\n",HsbCur);*/
		wrtn = testScroll(&HsbWin,event,HsbMax,&HsbCur);
		/*fprintf(stdaux,"HsbCur = %04X, wrtn = %04X\r\n",HsbCur,wrtn);*/

		switch(wrtn) {
		case WIN_UP:	return KEY_LEFT;
		case WIN_DOWN:	return KEY_RIGHT;
		case WIN_PGUP:	return KEY_CPGUP;
		case WIN_PGDN:	return KEY_CPGDN;
		case WIN_TOP:	return KEY_HOME;
		case WIN_BOTTOM:return KEY_END;
		case WIN_MOVETO:
			return KEY_AF12;
		case WIN_OK:
			return 0;
		}
	}

	if ((event->y >= HitWin.row && event->y < HitWin.row + HitWin.nrows) &&
	    (event->x >= HitWin.col && event->x < HitWin.col + HitWin.ncols) ) {
		/* Mouse click in data window */
		switch (event->click) {
		case MOU_LSINGLE:
			HitRow = event->y - HitWin.row;
			return KEY_DOWN;
		case MOU_LDOUBLE:
			HitRow = event->y - HitWin.row;
			return TOGGLE_KEY;
		}
	}
	return 0;
}



/***************************** BR_FREEDSP **********************************/
/* Free all elements of the array DSP */

void br_freedsp (TEXTHD **dsp)
{
	TEXTHD **tl;

	/* Loop through elements of the array */
	if (dsp) {
		for (tl = dsp; *tl; tl++) {
			free_mem((*tl)->textline); /* Free the text line */
			free_mem(*tl);	/* Free *TEXTHD structure */
		} /* End FOR */

		free_mem(dsp);		/* Free **TEXTHD structure */
	} /* End IF */

}

/***************************** BR_BUILDLN **********************************/

int br_buildln (DSPTEXT *ts, char *(*bldfn)(DSPTEXT *),TEXTHD **head,TEXTHD **tail)
{
	TEXTHD *tl;
	DSPTEXT *t;
	int line, tstop, newpos, endpos;
	char *p;
	char temp[256];

	/*---------------------------------------------------------*/
	/*	Release storage of existing structures		       */
	/*---------------------------------------------------------*/

	*head = *tail = NULL;	/* Initialize head and tail ptrs */
	line = 0;		/* Initialize line counter */

	/*---------------------------------------------------------*/
	/*	Build linked list of structures ready for display      */
	/*---------------------------------------------------------*/

	for (t = ts ; t ; t = t->next)
	{
		p = strcpy (temp, (*bldfn) (t));
		if (t->action == LLONG) /* If initial state is too long, */
			t->action = LLOW;	/* Mark as loaded low */

		line++; 		/* Count in another line */

		/*-----------------------------------------------------*/
		/*  Get storage for structure and text line	       */
		/*-----------------------------------------------------*/

		tl = get_mem(sizeof (TEXTHD));

		/* Expand tabs */
		for (tstop = 0; temp[tstop]; tstop++) {

		/* 012345670123456701234567 */
		/* TAfter--TeachTword becomes */
		/* ........After--.each....word */
		  if (temp[tstop] == '\t') {

		    newpos = (tstop / 8 + 1) * 8 - 1; /* 7, 15, 23... */

		    /* Get new index of trailing null */
		    if ((endpos = strlen (&temp[tstop])) >=
			 (int) (sizeof (temp) - newpos)) break;

		    while (endpos) {
			temp[newpos+endpos] = temp[tstop+endpos];
			endpos--;
		    } /* Move everything over */

		    /* Fill the former tab in with blanks */
		    while (tstop <= newpos) temp[tstop++] = ' ';
		    tstop = newpos;

		  } /* Found a tab */

		} /* Expanding tabs */

		tl->textline = str_mem (temp);

		/*-----------------------------------------------------*/
		/*  Link structure into the list and initialize it     */
		/*-----------------------------------------------------*/

		if (*tail) {
			tl->prev = *tail;
			(*tail)->next = tl;
			*tail = tl;
		} /* End IF */
		else
			*head = *tail = tl;

		tl->atr = (t->mark) ? 1 : 2;
		tl->disp = t;
	} /* End FOR */
	/* This makes bldfn toss it's local alloc */
	(*bldfn) (NULL);

	return (line);

} /* End CBUILDLN */

/**************************** BR_BUILDCFG **********************************/

char *br_buildcfg (DSPTEXT *t)
{
	static char *p = NULL;

	/* Free local memory if called with NULL arg */
	if (!t) {
		if (p) {
			free_mem(p);
			p = NULL;
		}
		return NULL;
	}

	/* Allocate memory the first time only */
	if (p == NULL)
		p = get_mem(300);

	if (!t->busmark && t->mark == 0) {
		t->action = LNONE;
		strcpy (p, t->text);
	} /* End IF */
	else if (!t->busmark && t->mark == 3) {
		t->action = LHIGH;
		strcpy (p, t->text);
	} /* End ELSE/IF */
	else {
		strncpy (p, t->text, t->nlead); /* Copy leading chars to preserve */
		p[t->nlead] = '\0';     /* Ensure properly terminated */

		if (t->busmark && t->mark != 1) {
			t->action = LWARN;
			t->mark = 4;
		} /* End IF */
		else if (t->mark == 1) {
			t->action = LMAX;
			sprintf (&p[t->nlead], "%s%s getsize %sprog=",
			_strlwr ((t->device == (BYTE) DSP_DEV_INSTALL) ? LoadTrue : LoaderTrue),
			_strlwr ((t->device == (BYTE) DSP_DEV_INSTALL) ? LOADERC : LOADERS),
			br_gldprm (t));
		} /* End ELSE/IF */
		else
			t->action = LLOW;

		strcat (p, t->pdevice); 	/* Copy remainder of the text */
	} /* End ELSE */

	return (p);

} /* End BUILDCFG */

/****************************** BR_BUILDBAT *******************************/

char *br_buildbat (DSPTEXT *t)
{
	static char *p = NULL;

	/* Free local memory if called with NULL arg */
	if (!t) {
		if (p) {
			free_mem(p);
			p = NULL;
		}
		return NULL;
	}

	if (p == NULL)
		p = get_mem (300);

	if (!t->busmark && t->mark == 0)
	{
		t->action = (strlen (t->text) > MaxLine) ? LLONG : LNONE;
		strcpy (p, t->text);
	} /* End ELSE/IF */
	else if (!t->busmark && t->mark == 3)
	{
		t->action = LHIGH;
		strcpy (p, t->text);
	} /* End ELSE/IF */
	else
	{
		strncpy (p, t->text, t->nlead); /* Copy leading chars */
		p[t->nlead] = '\0';     /* Ensure properly terminated */

		if (t->busmark && t->mark != 1)
		{   t->action = LWARN;
			t->mark = 4;
		} /* End IF */
		else if (t->mark == 1 && t->action != LLONG) {
			t->action = LMAX;
			sprintf (&p[t->nlead], "%s%s getsize %sprog=",
			_strlwr (LoadTrue),
			_strlwr (LOADER),
			br_gldprm (t));
		} /* End ELSE/IF */
		else
		{
			t->action = LLOW;
			t->mark = 2;
		} /* End ELSE */

		strcat (p, t->pdevice); 	/* Copy remainder of the text */

		if (strlen (p) > MaxLine)	/* If long line */
		{
			t->action = LLONG;		/* Mark as such */
			strcpy (p, t->text);	/* Go back to orignal text */
			t->mark = 2;
		} /* End IF */
	} /* End ELSE */

	return (p);

} /* End BUILDBAT */

/***************************** BR_GLDPRM **********************************/

/*-------------------------------------------------------------*/
/*  Routine searches for the LOADER on a CONFIG.SYS line and   */
/*  if found, eliminates some of its parameters because those  */
/*  parameters will be inserted by the user via toggles        */
/*  The returned line (if non-blank) must have a trailing blank*/
/*-------------------------------------------------------------*/

char *br_gldprm (DSPTEXT *t)
{
	char *p = TempBuffer;

	p[0] = '\0';                /* Start with nothing */

	/* Catenate options to the line in a canonical form (and order) */

	if (t->opts.display)
		strcat(p, "display ");

	/* Note we delete ENVNAME if present as it is now the default */

	if (t->opts.envreg)
		sprintf (stpend (p), "envreg=%d ", t->envreg);

	if (t->opts.envsave)
		strcat(p, "envsave ");

	if (t->opts.flex)
		strcat(p, "flexframe ");

	if (t->opts.group)
		sprintf (stpend (p), "group=%d ", t->group);

	if (t->opts.inter)
		strcat(p, "int ");

	if (t->opts.nopause)
		strcat(p, "nopause ");

	if (t->opts.noretry)
		strcat(p, "noretry ");

	if (t->opts.pause)
		strcat(p, "pause ");

	if (t->opts.prgreg)
		sprintf (stpend (p), "prgreg=%d ", t->prgreg);

	if (t->opts.quiet)
		strcat(p, "quiet ");

	if (t->opts.vds)
		strcat(p, "vds ");

	if (t->opts.terse)
		strcat(p, "terse ");

	if (t->opts.verbose)
		strcat(p, "verbose ");

	return (p);
} /* End GLDPRM */

/**************************** BR_WRTACT *********************************/
/* Write the action part of the line */

void br_wrtact(WINDESC *actwin,char *action,char attr,int row)
{
	int nc;
	WINDESC win;
	char temp[BACTCOLS];

	/* Action part */
	win = *actwin;
	win.row += row;
	win.nrows = 1;
	win.col++;
	win.ncols--;
	nc = min(strlen(action),sizeof(temp));
	if (nc > 0) {
		memcpy(temp,action,nc);
	}
	memset(temp+nc,' ',sizeof(temp)-nc);
	wput_csa(&win,temp,attr);
}

/******************************** BR_WRTTEXT ********************************/
/* Write the text part of the line */

void br_wrttext(WINDESC *txtwin,char *text,char attr,int row,int ccol)
{
	int nline;
	int ncmax;
	WINDESC win;

	/* Text part */
	win = *txtwin;
	win.row += row;
	win.nrows = 1;

	nline = strlen(text);
	if (ccol < 1) {
		win.ncols = 1;
		wput_sca(&win,VIDWORD(attr,' '));
		ncmax = txtwin->ncols-1;
		win.col++;
		win.ncols = txtwin->ncols - 1;
	}
	else {
		ccol--;
		ncmax = txtwin->ncols;
	}

	if (ccol < nline) {
		int nc;

		nc = min(nline-ccol,ncmax);
		win.ncols = nc;
		wput_csa(&win,text+ccol,attr);
		if (nc < ncmax) {
			win.col += win.ncols;
			win.ncols = ncmax-nc;
			wput_sca(&win,VIDWORD(attr,' '));
		}
	}
	else {
		win.ncols = ncmax;
		wput_sca(&win,VIDWORD(attr,' '));
	}
}

/****************************** BR_HIGHLIGHT ******************************/
/* Highlight (or un-highlight) one row */

void br_highlight(WINDESC *actwin,WINDESC *txtwin,int row,char attr1,char attr2)
{
	WINDESC win;

	/* Action part */
	win = *actwin;
	win.row += row;
	win.nrows = 1;
	win.ncols++;
	wput_sa(&win,attr1);

	/* Text part */
	win = *txtwin;
	win.row += row;
	win.nrows = 1;
	wput_sa(&win,attr2);
}


/**************************** BR_SETUP *********************************/

void br_setup (char *filename,WINDESC *mainwin,WINDESC *actwin,WINDESC *txtwin,BOOL grouping)
{
	int nhfle;
	WINDESC win;
	char *hfle;
	char hfilename[80];
	char temp[80];

	/* Copy to local buffer to extract filename */
	strcpy (hfilename, filename);

	/* Extract the filename.ext for the title line */
	hfle = fnddev (hfilename, 1);

	if (_strcmpi (hfle, "AUTOEXEC." ABETA) == 0)
		hfle = "AUTOEXEC.BAT";
	else
		hfle = strcpy (hfilename, hfle);
	nhfle = strlen(hfle);

	/* Adjust browse window rows to match screen rows */
	BwindRows = ScreenSize.row - 5;

	/* Create the windows */
	SETWINDOW(mainwin,BWINDSROW,BWINDSCOL,BwindRows,BWINDCOLS);
	SETWINDOW(actwin,BWINDSROW+2,BWINDSCOL,BR_ROWS,BACTCOLS);
	SETWINDOW(txtwin,BWINDSROW+2,BWINDSCOL+BACTCOLS+1,BR_ROWS,BR_COLS);

	wput_sca(mainwin,VIDWORD(BrBaseColor,' '));
	shadowWindow(mainwin);

	/* Draw the lines */
	win = *mainwin;
	win.col += BLINEDOWN;
	win.ncols = 1;
	win.nrows = BwindRows;
	wput_sc(&win,'³');

	/* Column titles */

	win = *mainwin;
	win.nrows = 1;
	win.ncols = strlen(MsgAction);
	win.col += (BACTCOLS-win.ncols) / 2;
	wput_c(&win,MsgAction);

	sprintf(temp,MsgFile,hfle);
	win.ncols = strlen(temp);
	win.col = mainwin->col + BACTCOLS + (BR_COLS - win.ncols) / 2;
	wput_c(&win,temp);

	addButton( BrowseButtons, sizeof(BrowseButtons)/sizeof(BrowseButtons[0]), NULL );

	/* Initially, all browse buttons are cold */
	disableButton(DONE_KEY,TRUE);
	disableButton(TOGGLE_KEY,TRUE);
	disableButton(PREV_KEY,TRUE);
	disableButton(NEXT_KEY,TRUE);

	if (grouping)
		setButtonText(TOGGLE_KEY,MsgGroupText,GROUPTEXTLEN);
	else
		setButtonText(TOGGLE_KEY,MsgToggleText,TOGGLETEXTLEN);

	showAllButtons();
} /* End br_setup */

/*************************** BR_CLEAR ***********************************/

void br_clear(WINDESC *mainwin)
{
	dropButton( BrowseButtons, sizeof(BrowseButtons)/sizeof(BrowseButtons[0]) );
	wput_sca(mainwin,VIDWORD(BrBaseColor,' '));
} /* End br_clear */
