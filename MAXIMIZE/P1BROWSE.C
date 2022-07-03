/*' $Header:   P:/PVCS/MAX/MAXIMIZE/P1BROWSE.C_V   1.0   05 Sep 1995 16:33:04   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * P1BROWSE.C								      *
 *									      *
 * Do ADF optimization choices						      *
 * Not used in MOVE'EM version                                                *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Local Includes */
#include <ins_var.h>		/* INS_*.* global variables */
#include <ui.h> 		/* UI functions */
#include <intmsg.h>

#define P1BROWSE_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef P1BROWSE_C

#ifndef PROTO
#include "p1browse.pro"
#include "ins_opt.pro"
#include "profile.pro"
#include "screens.pro"
#endif /*PROTO*/


/* Local variables */
#define BWINDCOLS  77
#define BWINDROWS  20
#define BACTCOLS   12
#define BTXTCOLS   BWINDCOLS-BACTCOLS-3
#define BLINEDOWN  12
#define BWINDSROW   2
#define BWINDSCOL   1

/* The following array is allocated with +1 to account for the */
/* EMS page frame */
char *aname[MAX_SLOTS];
BYTE row2slot[MAX_SLOTS];	/* Row to slot conversion */

/* Non-button keystrokes */
KEYCODE P1Keys[] = { KEY_UP, KEY_DOWN, KEY_TAB, KEY_STAB, 0 };

WINDESC P1HitWin; /* Window for mouse hits on group menu lines */
int P1HitRow;	/* Row of mouse hit */

/* Local functions */
KEYCODE p1_input(	/* Input callback function */
	INPUTEVENT *event);	/* Event from dialog_input() */

/******************************* P1BROWSE **********************************/

void p1browse (void)
{
	int ii;
	int apos;
	WINDESC mainwin;/* Descriptor for main window */
	WINDESC actwin; /* Descriptor for action window */
	WINDESC txtwin; /* Descriptor for text window */
	struct _device *LD;

	/* Initialize the adapter states */
	for (LD = Last_device, apos = 0; LD; LD = LD->Next) {
		if (LD->Devflags.Ems_device) {
			aname[apos] = MsgEmsFrame;  /* EMS Page Frame */
			slots[LD->slot].cur_state = slots[LD->slot].init_state;
			row2slot[apos] = LD->slot;  /* Save row-to-slot index */
			apos++; 		    /* Increment to next row */
		} /* End IF */
		else if (slots[LD->slot].adapter_id != 0xFFFF /* Valid adapter ID */
				&& (apos == 0 || row2slot[apos - 1] != LD->slot)) { /* and different from */
			aname[apos] = slots[LD->slot].adapter_name; /* previous slot */
			slots[LD->slot].cur_state = slots[LD->slot].init_state;
			row2slot[apos] = LD->slot;  /* Save row-to-slot index */
			apos++; 		    /* Increment to next row */
		} /* End IF/ELSE/IF */
	} /* End FOR */

RECONFIGURE:
	if (QuickMax <= 0) {
		intmsg_save();
		dadapwind (apos, &mainwin, &actwin, &txtwin);
		SETWINDOW(&P1HitWin,actwin.row,actwin.col,actwin.nrows,mainwin.ncols);
		for (ii = 0 ; ii < apos ; ii++) {
			adapline(&actwin,&txtwin,ii,astate(ii),aname[ii],FALSE);
		} /* End FOR */
	}

	if (QuickMax <= 0) {
		procmenu (&actwin,&txtwin,apos);
	}

	/* If the user didn't ESCAPE, press on */
	if (!AnyError) {

		/* Now optimize the adapter positions */
		if (QuickMax <= 0) {
			cadapwind (&mainwin);
			paintBackgroundScreen();
			do_prodname();
			showQuickHelp(QuickRefs[Pass-1]);
			showAllButtons();
			intmsg_restore();
		}
REOPTIMIZE:
		do_intmsg (MsgOptAdapt);
		optimize ();

		/* Handle case where EMS page frame doesn't fit into high DOS */
		if (choice_count == 0 && EmsFrame) {
			int result;

			if (QuickMax <= 0)
				result = do_emshelp();
			else
				result = 'C';

			switch (result) {
			case 'R':
				goto RECONFIGURE;

			case 'D':
				ems_services = FALSE;

			case 'N':
				break;

			case 'C':
				low_frame = TRUE;
				break;
			} /* End SWITCH */

			/* Remove EMS frame from the device list */
			EmsFrame = FALSE;
			Last_device = Last_device->Next;

			goto REOPTIMIZE;
		} /* End IF */
	} /* End IF */

	/* Add EMS=0 or NOFRAME to profile as necessary */
	if (ems_services == FALSE) {
		add_to_profile (EMS, MsgNoEms, 0L, 0L);
/*
 *		if (extset == TRUE)		/* If EXT= present, *
 *			del_from_profile (EXT); /* ...delete it *
 */
	} /* End IF */
	else {
/*
 *	char buff[80];
 *		if (emsmem != 0L && extset == FALSE)
 *		{   sprintf (buff, "EMS=%ld ; Reserve exactly %ld KB of EMS memory",
 *		     emsmem, emsmem);
 *			add_to_profile (EMS, buff, emsmem, 0L);
 *		} // End IF
 */
		if (EmsFrame == FALSE && low_frame == FALSE)
			add_to_profile (NOFRAME, MsgNoFrame, 0L, 0L);
	} /* End ELSE */

} /* End P1BROWSE */

/********************************* ASTATE *************************************/
/* Return pointer to adapter state text */

static char *astate (int ndx)
{
	BYTE r2s;

	r2s = row2slot[ndx];

	return (MsgAstateText[slots[r2s].cur_state]);
} /* End ASTATE */

/********************************* PROCMENU ***********************************/

void procmenu (WINDESC *actwin,WINDESC *txtwin,int nrows)
{
	KEYCODE key;
	int row;
	BOOL buttons_hot = FALSE;
	BOOL endc;
	static BOOL helpdone = FALSE;

	endc = FALSE;
	row = 0;
	while (!endc) {
		adapline(actwin,txtwin,row,astate(row),aname[row],TRUE);
		if (helpdone == FALSE) {
			message_panel(MsgAdaptIntro,HELP_P1HELP);
			helpdone = TRUE;
		} /* End IF */

		if (!buttons_hot) {
			disableButton(DONE_KEY,FALSE);
			disableButton(TOGGLE_KEY,FALSE);
			buttons_hot = TRUE;
		}

		P1HitRow = -1;
		key = dialog_input(HELP_P1HELP,p1_input);

		/* Very kludgey ... */
		adapline(actwin,txtwin,row,astate(row),aname[row],FALSE);
		switch (key) {
		case KEY_UP:
		case KEY_STAB:
			if (row == 0)
				row = nrows - 1;
			else
				row--;
			break;

		case KEY_DOWN:
		case KEY_TAB:
			if (P1HitRow >= 0) {
				row = min(P1HitRow,nrows-1);
			}
			else {
				if (row == (nrows - 1))
					row = 0;
				else
					row++;
			}
			break;
		PROCMENU_ESCAPE:
		case KEY_ESCAPE:
			AbyUser = AnyError = 1;
		case DONE_KEY:
			endc = TRUE;
			break;

		case TOGGLE_KEY:
			if (P1HitRow >= 0) {
				row = min(P1HitRow,nrows-1);
			}
			if (!toggle (row))
				goto PROCMENU_ESCAPE;
			break;
		} /* End SWITCH */
	} /* End WHILE */

} /* End PROCMENU */

/********************************** TOGGLE ************************************/

static int toggle (int row)
{
	int rtn = 1, r2s;
	struct _slot *pr2s;

	r2s = row2slot[row];

	pr2s = &slots[r2s];
	if (pr2s->init_state == MAXIMIZE)
		pr2s->cur_state = (pr2s->cur_state == MAXIMIZE) ? STATIC : MAXIMIZE;
	else if (pr2s->init_state == STATIC) {
		if (pr2s->cur_state == MAXIMIZE)
			pr2s->cur_state = STATIC;
		else {
			rtn = do_mistake(pr2s->help_static,0);
			if (rtn)
				pr2s->cur_state = MAXIMIZE;
		} /* End ELSE */
	} /* End ELSE/IF */

	return (rtn);
} /* End TOGGLE */

/********************************* DADAPWIND *********************************/

static void dadapwind (int rows,WINDESC *mainwin,WINDESC *actwin,WINDESC *txtwin)
{
	WINDESC win;

	/* Create the windows */
	SETWINDOW(mainwin,BWINDSROW,BWINDSCOL,BWINDROWS,BWINDCOLS);
	SETWINDOW(actwin,BWINDSROW+2,BWINDSCOL,rows,BACTCOLS);
	SETWINDOW(txtwin,BWINDSROW+2,BWINDSCOL+BACTCOLS+2,rows,BTXTCOLS);

	wput_sca(mainwin,VIDWORD(BrBaseColor,' '));
	shadowWindow(mainwin);

	/* Draw the lines */
	win = *mainwin;
	win.col += BLINEDOWN;
	win.ncols = 1;
	win.nrows = BWINDROWS;
	wput_sc(&win,'³');

	/* Column titles */

	win = *mainwin;
	win.nrows = 1;
	win.ncols = strlen(MsgAdapAction);
	win.col += (BACTCOLS-win.ncols) / 2;
	wput_c(&win,MsgAdapAction);

	win.ncols = strlen(MsgAdapName);
	win.col = mainwin->col + BACTCOLS + (BTXTCOLS - win.ncols) / 2;
	wput_c(&win,MsgAdapName);

	addButton( P1Buttons, sizeof(P1Buttons)/sizeof(P1Buttons[0]), NULL );
	disableButton(DONE_KEY,TRUE);
	disableButton(TOGGLE_KEY,TRUE);
	showAllButtons();

} /* End DADAPWIND */

/******************************** CADAPWIND ***********************************/

static void cadapwind (WINDESC *mainwin)
{
	if (mainwin);
	dropButton( P1Buttons, sizeof(P1Buttons)/sizeof(P1Buttons[0]) );
} /* End CADAPWIND */

/******************************** ADAPLINE ***********************************/

void adapline(
	WINDESC *actwin,	/* Descriptor for action window */
	WINDESC *txtwin,	/* Descriptor for text window */
	int row,		/* Row to update */
	char *action,		/* Action text */
	char *name,		/* Name text */
	BOOL high)		/* TRUE to highlight */
{
	int nc;
	WINDESC win;
	char attr;

	/* Write action */
	win = *actwin;
	win.row += row;
	win.nrows = 1;
	attr = high ? P1HighHot : P1HighCool;

	win.ncols += 2;
	wput_sa(&win,attr);
	win.ncols -= 2;
	wput_c(&win,action);


	/* Write name */
	nc = strlen(name);
	win = *txtwin;
	win.row += row;
	win.nrows = 1;
	win.ncols = min(nc,BTXTCOLS);
	attr = high ? P1LowHot : P1LowCool;
	wput_csa(&win,name,attr);

	if (nc < BTXTCOLS) {
		win.col += win.ncols;
		win.ncols = BTXTCOLS-nc;
		wput_sca(&win,VIDWORD(attr,' '));
	}
}

KEYCODE p1_input(	/* Input callback function */
	INPUTEVENT *event)	/* Event from dialog_input() */
{
	if (event->key) {
		/* Check our local valid key list */
		KEYCODE *kp;

		for (kp = P1Keys; *kp; kp++) {
			if (*kp == event->key) {
				return event->key;
			}
		}
	}
	if ((event->y >= P1HitWin.row && event->y < P1HitWin.row + P1HitWin.nrows) &&
	    (event->x >= P1HitWin.col && event->x < P1HitWin.col + P1HitWin.ncols) ) {
		/* Mouse click in data window */
		switch (event->click) {
		case MOU_LSINGLE:
			P1HitRow = event->y - P1HitWin.row;
			return KEY_DOWN;
		case MOU_LDOUBLE:
			P1HitRow = event->y - P1HitWin.row;
			return TOGGLE_KEY;
		}
	}
	return 0;
}
