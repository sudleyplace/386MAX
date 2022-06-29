/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PASS2.C_V   1.3   10 Nov 1995 17:50:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PASS2.C								      *
 *									      *
 * Mainline for MAXIMIZE, phase 2					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <ui.h> 		/* User interface functions */
#include <intmsg.h>		/* Intermediate message functions */

#define PASS2_C 	/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef PASS2_C

#ifndef PROTO
#include "browse.pro"
#include "copyfile.pro"
#include "reboot.pro"
#include "maximize.pro"
#include <maxsub.pro>
#include "parse.pro"
#include "pass2.pro"
#include "proccfg1.pro"
#include "readmxmz.pro"
#include "wrconfig.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */
/* Return action text for one line */
static char *p2_acttext(DSPTEXT *dsp);

/* Toggle state of one line */
static int p2_toggle(
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
	char *(*bldfn)(DSPTEXT *dsp));	/* Text line builder function */

/*********************************** PASS2 ************************************/

void pass2 (void)
{
	int kk;

	readmxmz();

	if (QuickMax > 0) goto there;

	if (nmark < 1) {
		do_error(MsgNoneToDo,TRUE);
	}

	intmsg_save();

	/* Browse config & batch files */
	kk = 0;
	for (;;) {
		int rtn;

		rtn = do_browse(marked[kk],	/* ndx */
				kk == 0,	/* first */
				kk+1 >= nmark,	/* last */
				FALSE,		/* grouping */
				MsgPreToggle,	/* Intro text */
				HELP_P2HELP,	/* helpnum */
				&P2ActColors,	/* actcolors */
				&P2TxtColors,	/* txtcolors */
				(marked[kk] == CONFIG) ? /* bldfn */
					br_buildcfg : br_buildbat,
				p2_acttext,	/* acttext */
				p2_toggle);	/* toggle */

		if (AnyError) break;

		if (rtn == 0) {
			if (kk+1 < nmark) rtn++;
			else break;
		}

		if (rtn < 0) {
			/* If we should back up one file */
			if (kk > 0) kk--;
		}
		else {	/* rtn > 0 */
			if (kk+1 < nmark) kk++; 	/* Skip to next file */
		} /* End ELSE */
	} /* End FOR */
	paintBackgroundScreen();
	do_prodname();
	showQuickHelp(QuickRefs[Pass-1]);
	showAllButtons();
	intmsg_restore();
there:
	if (!AnyError) {
		wrconfig (Pass);
		wrbatfile (Pass);

		if (!AnyError) {
#if SYSTEM != MOVEM
			do_probe ();
			if (!AnyError) do_vgaswap ();
			if (AnyError) return;
#endif
			wrprofile( FALSE, FALSE ); /* Save all changes to profile (no stripping) */
			doreboot ();

		} /* Batch files copied OK */
	} /* End IF */

} /* End PASS2 */

/********************************** P2_ACTTEXT *********************************/

/* Return action text for one line */
static char *p2_acttext(DSPTEXT *dsp)
{
	return MsgP2Action[dsp->action];
}

/********************************** P2_TOGGLE *******************************/

/* Toggle state of one line */
static int p2_toggle(
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
{
	static char f2state [2][5] = {	/* F2 transitions for ->MARK */
		/*  0  1  2  3	4 */
		 {  0, 2, 1, 1, 5 },		/* LOADSW == 0 */
		 {  0, 2, 3, 1, 5 },		/* ...	     1 */
	};
	DSPTEXT *dsp = dsparray[crow]->disp;

	/* Make the compiler shut up */
	if (ndx || first || last ||
	    actwin || txtwin || trows || ctrow || cbrow);

	if (dsp->mark) {
		KEYCODE key;
		char *p;

		dsp->mark = f2state[dsp->opts.loadsw][dsp->mark];
		if (dsp->mark == 5) {	/* If we're to warn, */
			key = do_mistake (MsgCacheWarn,0);	/* Display warning message */
			if (key == RESP_YES) { /* If it's Yes, */
				dsp->mark = 1; /* ...mark as to be MAXIMIZED */
				dsp->opts.vds = 1; /* Mark as VDS present */
			} /* End IF */
			else {	/* Otherwise, */
				dsp->mark = 4; /* ...mark as continued warning */
				dsp->opts.vds = 0; /* Mark as VDS not present */
			} /* End ELSE */
		} /* End IF */

		free_mem (dsparray[crow]->textline);
		p = (*bldfn) (dsp);
		dsparray[crow]->textline = str_mem (p);
		return 1;
	} /* End IF */
	return 0;
}


/********************************** WRBATFILE *********************************/

void wrbatfile (int pass)
{
    DSPTEXT *t;
    FILE *ot;
    char buff[100];
    int i0,i;

    /* Back up only files containing marked lines */
    for (i0 = 0; i0 < nmark; i0++)
    {

	/* CONFIG.SYS has been taken care of elsewhere */
	if ((i = marked[i0]) >= BATFILES)
	{
		if (AnyError)		/* Don't proceed if errors */
			return;

		/* Copy to local buffer to extract filename */
		strcpy (buff, ActiveFiles[i]);
		_strupr (buff);
		if (pass == 2 &&	/* If it's pass 2, */
			!strstr (buff, ".áAT")) /* ...and not AUTOEXEC */
		{
			savefile (i);	/* Save it */
			restbatappend (i); /* Tell PREMAXIM to restore it */
		} /* End IF */

		/* Writing %s file */
		do_intmsg(MsgWrtFile,ActiveFiles[i]);
		disable23 ();		/* Trap DOS errors */
		if ((ot = fopen (ActiveFiles[i], "w")) != NULL) {
			for (t = HbatStrt[i] ; t && !AnyError ; t = t->next) {
				if (t->deleted) continue;
				/* Output w/ trailing LF */
				fputs_text ((pass == 2) ?
					br_buildbat (t) : t->text,ot);
			}
			fclose (ot);
		} /* End IF */
		else
			AnyError = 1;

		if (AnyError) {
			/* Error writing ... file */
			do_textarg(1,ActiveFiles[i]);
			do_error(MsgErrWrite, TRUE);
		} /* End IF */

		enable23 ();

	} /* End if (marked) */

    } /* end for (i0) */

} /* End WRBATFILE */

