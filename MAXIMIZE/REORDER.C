/*' $Header:   P:/PVCS/MAX/MAXIMIZE/REORDER.C_V   1.1   13 Oct 1995 12:04:22   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * REORDER.C								      *
 *									      *
 * Top-level reorder functions						      *
 *									      *
 ******************************************************************************/

#ifdef REORDER

/* System Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <memory.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <ui.h> 		/* User interface functions */
#include <intmsg.h>		/* Intermediate message functions */
#include <p3debug.h>		/* Pass 3 debugging */
#include <qhelp.h>		/* Help functions */

#define REORDER_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef REORDER_C

#ifndef PROTO
#include "browse.pro"
#include <maxsub.pro>
#include "pass3.pro"
#include "reorder.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

#ifdef REORDER_DEBUG
#pragma message("Reorder debugging code enabled - output to " DEBUGFILE)
#endif

/* Local variables */
typedef struct _sortitem {		/* Sort item for reordering text */
	DSPTEXT *t;		/* Pointer to entry */
	int oldindex;		/* Index of entry before reordering */
	int
		prevarray:1,	/* Beg. of slot is previous array element */
		nextarray:1;	/* End of slot is next array element */
	DSPTEXT *oldprev,*oldnext; /* t->prev and t->next */
	unsigned key;		/* Sort key */
} SORTITEM;

/* Non-button keystrokes for grouping menu */
static KEYCODE GroupKeys[] = {
	KEY_UP, KEY_DOWN, KEY_CHOME, KEY_CEND, KEY_ENTER, 0 };

static WINDESC P3HitWin; /* Window for mouse hits on group menu lines */
static int P3HitRow;	/* Row of mouse hit */

/* Local functions */
static char *p3_acttext(DSPTEXT *dsp);

static int p3_toggle(
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

static KEYCODE group_input(	/* Input callback function */
	INPUTEVENT *event);	/* Event from dialog_input() */

DSPTEXT *reorder_lines(DSPTEXT *tx);
void save_groups(int this);
int sortcomp(SORTITEM *p1,SORTITEM *p2);

#ifdef REORDER_DEBUG
static void dump_sortitem(char *fname,char *mode,char *tag,SORTITEM *item,int count);
#endif /* REORDER_DEBUG */

#pragma optimize ("leg",off)
SUMFIT far * try_reorder(SUMFIT far *psumfit, int cfgmark, WORD lastbest)
{
	int kk;
	int thisone;
	int rtn;
	int nmark;
	int marked[2];	/* Flags for which files have marked items */
	DSPTEXT *ts;
	KEYCODE key;
	char	wrk_drv[_MAX_DRIVE],
		wrk_dir[_MAX_DIR],
		wrk_name[_MAX_FNAME],
		wrk_ext[_MAX_EXT];

	/* Find out which files have marked lines */
	nmark = 0;
	memset(marked,0,sizeof(marked));

	/* See if CONFIG.SYS has at least 2 marked lines */
	thisone = 0;
	for (ts = HbatStrt[CONFIG]; ts; ts = ts->next) {
		char *pp;

		if (!ts->visible) continue;

		*ts->groupspec = '\0';

		if (ts->mark)
			pp = ts->pdevice;
		else
			pp = dev_eq(ts->text);

		if (pp) {
			normalize_file(ts->groupspec,pp);
		}

		if (!ts->mark) continue;

		if (ts->psumfit) {
			marked[nmark] = CONFIG;
			thisone++;
		}
		/*else	ts->mark = 0;*/
	}
	if (thisone > 1) nmark++;

	/* Figure out which batch file has the marked lines */
	/* Don't suggest reordering if not at least 2 marked lines */
	thisone = 0;
	for (kk = BATFILES ; ActiveFiles[kk] && !AnyError ; kk++ ) {
		_splitpath (ActiveFiles[kk], wrk_drv, wrk_dir, wrk_name, wrk_ext);
		if (_stricmp (wrk_name, "batproc") || _stricmp (wrk_ext, ".umb"))
		 for (ts = HbatStrt[kk]; ts; ts = ts->next) {
			char *pp;

			*ts->groupspec = '\0';

			if (ts->mark)
				pp = ts->pdevice;
			else
				pp = ts->text;

			pp = not_rem(pp);
			if (pp) {
				normalize_file(ts->groupspec,pp);
			}

			if (!ts->mark && !ts->umb) continue;

			if (ts->psumfit) {
				/* This one does... */
				if (marked[nmark] != kk) {
					if (thisone) {
						/* ...But it's not alone */
						thisone = -1;
						break;
					}
					else {
						thisone = kk;
						marked[nmark] = kk;
					}
				}
			}
			/*else	ts->mark = 0;*/
		}
		if (thisone > 1) nmark++;
		if (thisone == -1) break;
	}

	if (thisone == -1) {
		/* Marked lines in more than one batch file */
		/* Tell user the bad news */
		message_panel (MsgMultBatch,0);
		return (NULL);
	}
	else {
		KEYCODE key;
		DIALOGPARM parm;

		parm = NormalDialog;
		parm.pButton = FeelLuckyButtons;
		parm.nButtons = sizeof(FeelLuckyButtons)/sizeof(FeelLuckyButtons[0]);
		/* Tell'em how much we moved */
		MaximizeArgTo[0] = ltoe (((DWORD) BESTSIZE) << 4, 0);

		/* Warn the user to think about the next question */
		message_panel (MsgFeelLucky, 0);

		/* Ask the user if he feels lucky */
		for (rtn=0; !rtn; ) {

		 key = dialog(&parm,
			TitleAction,
			MsgFeelLucky2,
			HELP_REORDER,
			NULL,
			0);

		 if (AnyError) return (NULL);
		 switch (key) {
			case RESP_YES:
				rtn = 1;
				break;
			case RESP_NO:
				return (NULL);
			case RESP_MORE:
				showHelp (HELP_REORDER, FALSE);
		 } // switch (key)

		} // for (!rtn)

	} // Reordering possible if user can make up his mind

	/* Preset groups from REORDER.CFG and REORDER2.CFG */
	preset_group(marked[0],TRUE);
	preset_group(marked[0],FALSE);
	preset_group(marked[1],TRUE);
	preset_group(marked[1],FALSE);

	/* Browse config & batch files */
	intmsg_save();
	key = 0;
	kk = 0;
	for (;;) {
		/* Browse one file */
		int grp;
		int rtn;
again:
		rtn = do_browse(marked[kk],	/* ndx */
				kk == 0,	/* first */
				kk+1 >= nmark,	/* last */
				TRUE,		/* grouping */
				MsgGroupIntro,	/* Intro text */
				HELP_P3HELP,	/* helpnum */
				&P3ActColors,	/* actcolors */
				&P3TxtColors,	/* txtcolors */
				(marked[kk] == CONFIG) ? /* bldfn */
					br_buildcfg : br_buildbat,
				p3_acttext,	/* acttext */
				p3_toggle);	/* toggle */

		/* Tidy up */
		shadowWindow(&DataWin);

		/* Check for non-groups */
		for (grp = 0; grp < MAXGROUPS; grp++) {
			if (GroupVector[grp] == marked[kk]) {
				int count;

				count = 0;
				for (ts = HbatStrt[marked[kk]]; ts; ts = ts->next) {
					if (ts->group == (BYTE)(grp+1)) {
						count++;
					}
				}
				if (count == 1) {
					warning_panel(MsgSingle,0);
					goto again;
				}
			}
		}

		/* Update the LSEG group bytes */
		/* Note that this is the one way a UMB may be grouped */
		for (ts = HbatStrt[marked[kk]]; ts; ts = ts->next) {
			if (ts->psumfit) {
				LSEGFIT far *ls;

				ls = FAR_PTR(ts->psumfit->lseg,0);
				if (ts->group) {
					ls->grp = ts->group;
					ts->opts.group = 1;
				}
				else {
					ls->grp = 0;
					ts->opts.group = 0;
				}
				psumfit->grp = ls->grp;
			}
		}
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
			if (kk+1 < nmark) kk++;
		} /* End ELSE */
	} /* End FOR */
	paintBackgroundScreen();
	do_prodname();
	showQuickHelp(QuickRefs[Pass-1]);
	showAllButtons();
	intmsg_restore();

	/* Even if we don't win at reordering, save the groups they've */
	/* defined manually */
	save_groups(thisone);

#ifdef REORDER_DEBUG
	dump_lseg(DEBUGFILE,"a","after p3browse");
#endif

	/* Do second cut at MAXIMIZing, with reorder */
	init_progress(MsgReorInProg);
	psumfit = maximize(TRUE);
	end_progress();

#ifdef REORDER_DEBUG
	dump_lseg(DEBUGFILE,"a","after reordered maximize");
	dump_sumfit(DEBUGFILE,"a","after reordered maximize",psumfit);
#endif

	/* If reordering didn't gain us anything, don't reshuffle the deck. */
	if (BESTSIZE <= lastbest) return (NULL);

	/*map_sumfit(psumfit,cfgmark);*/

	HbatStrt[CONFIG] = reorder_lines(HbatStrt[CONFIG]);
	if (thisone) {
		HbatStrt[thisone] = reorder_lines(HbatStrt[thisone]);
	}

	return psumfit;
}
#pragma optimize ("",on)

/*************************** p3_acttext ************************************/

/* Do action text for one line */
static char *p3_acttext(DSPTEXT *dsp)
{
	static char action[20];

	switch (dsp->group) {
#if 0
	case FIRSTGROUP:
		return MsgFirstAction;
	case LASTGROUP:
		return MsgLastAction;
#endif
	case UNGROUP:
		return "";
	default:
		{
			char *p;

			strcpy(action,MsgGrpAction);
			p = strchr(action,'#');
			if (p) *p = (char) (GROUPBASE + dsp->group);
		}
	}
	return action;
}


/*********************** p3_toggle ***************************************/

#pragma optimize ("leg",off) /* Function too large for... */
static int p3_toggle(
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
	int nn;
	int kk;
	int select;
	int nmenu;
	BYTE grp;
	BYTE selgrp;
	KEYCODE key;
	WINDESC menuwin;
	WINDESC colorwin;
	WINDESC menutext;
	void *save;
	void *colorsave;
	char *menubuf;
	char *menup;
	char *nump;
	char groupnum[MENUWIDTH+1];

	/* Make the compiler shut up */
	if (bldfn);

	/* Disable buttons, etc. */
	dialog_callback(0,NULL);

	disableButton(DONE_KEY,TRUE);
	disableButton(TOGGLE_KEY,TRUE);
	if (!first) disableButton(PREV_KEY,TRUE);
	if (!last)  disableButton(NEXT_KEY,TRUE);

	/* Set up text array for the menu */
	nn = (MAXGROUPS+MENUEXTRA)*MENUWIDTH;
	menubuf = get_mem(nn);
	memset(menubuf,' ',nn);

	/* Build menu items */
	menup = menubuf;
#if 0
	memcpy(menup,MsgFirstGroup,strlen(MsgFirstGroup));
	menup += MENUWIDTH;
#endif
	strcpy(groupnum,MsgGroupNum);
	nump = strchr(groupnum,'#');
	if (!nump) nump = groupnum+MENUWIDTH-1;

	/* Decide which line will determine first selection */
	selgrp = 0;
	if (dsparray[crow]->disp->group != UNGROUP) {
		selgrp = dsparray[crow]->disp->group;
	}
	else if (crow > 0 && dsparray[crow-1]->disp->group != UNGROUP) {
		selgrp = dsparray[crow-1]->disp->group;
	}
	else if (crow < trows-1 && dsparray[crow+1]->disp->group != UNGROUP) {
		selgrp = dsparray[crow+1]->disp->group;
	}

	/* Assemble menu text */
	select = 0;
	for (grp = 0; grp < MAXGROUPS; grp++) {
		if (GroupVector[grp] == ndx) {
			*nump = (char) (GROUPBASE + grp + 1);
			memcpy(menup,groupnum,MENUWIDTH);
			if ((BYTE)(grp+1) == selgrp) {
				select = (menup-menubuf)/MENUWIDTH;
			}
			menup += MENUWIDTH;
		}
	}
	memcpy(menup,MsgNewGroup,strlen(MsgNewGroup));
	menup += MENUWIDTH;
#if 0
	memcpy(menup,MsgLastGroup,strlen(MsgLastGroup));
	menup += MENUWIDTH;
#endif
	memcpy(menup,MsgUnGroup,strlen(MsgUnGroup));
	menup += MENUWIDTH;
	nmenu = (menup - menubuf)/MENUWIDTH;
#if 0
	if (selgrp == LASTGROUP) {
		select = nmenu-2;
	}
#endif
	/* Set up the menu and text windows */
	SETWINDOW(&menuwin,(SCRHEIGHT-nmenu)/2,
		txtwin->col+(txtwin->ncols-(MENUWIDTH+4)-1)/2,nmenu+2,MENUWIDTH+4);
	save = win_save(&menuwin,SHADOW_SINGLE);
	wput_sca(&menuwin,VIDWORD(P3GrpLow,' '));
	box( &menuwin, BOX_SINGLE, TitleGroup, NULL, P3GrpLow );

	shadowWindow(&menuwin); /* halfShadow */
	SETWINDOW(&menutext,menuwin.row+1,menuwin.col+2,nmenu,MENUWIDTH);
	P3HitWin = menutext;
	P3HitWin.col--;
	P3HitWin.ncols += 2;
	wput_csa(&menutext,menubuf,P3GrpLow);

	/* Save a copy of the menu colors */
	colorwin = menuwin;
	colorwin.nrows += 1;
	colorwin.ncols += 2;
	colorsave = get_mem(colorwin.nrows * colorwin.ncols);
	wget_a(&colorwin,colorsave);

	/* Run the the menu proc */
	for (;;) {
		WINDESC win;
		BYTE group = 0;

		/* Get group for selected item */
		menup = menubuf+(select*MENUWIDTH);
#if 0
		if (memcmp(menup,MsgFirstGroup,MENUWIDTH) == 0) {
			/* First group selected */
			group = FIRSTGROUP;
		}
		else if (memcmp(menup,MsgLastGroup,MENUWIDTH) == 0) {
			/* Last group selected */
			group = LASTGROUP;
		}
		else
#endif
		if (memcmp(menup,MsgUnGroup,MENUWIDTH) == 0) {
			/* Ungroup selected */
			group = UNGROUP;
		}
		else if (memcmp(menup,MsgNewGroup,MENUWIDTH) == 0) {
			/* New group selected, find an unused group number */
			for (grp = 0; grp <= MAXGROUPS; grp++) {
				if (GroupVector[grp] == -1) {
					/* Got it */
					group = (BYTE) (grp + 1);
					break;
				}
			}
		}
		else {
			/* Add to existing group */
			group = (BYTE)(*(menup+(nump-groupnum))-GROUPBASE);
		}

		/* Highlight any visible lines for the current group */
		if (group != UNGROUP) {
			for (kk = ctrow; kk <= cbrow; kk++) {
				if (kk != crow && group == dsparray[kk]->disp->group) {
					br_highlight(actwin,txtwin,kk - ctrow,
						P3GrpAlt,P3GrpAlt);
				}
			}
		}

		/* Re-color the menu in case it was overwritten by higlighting */
		wput_a(&colorwin,colorsave);

		/* Highlight the current menu selection */
		win = menutext;
		win.row += select;
		win.nrows = 1;
		win.col--;
		win.ncols += 2;
		wput_sa(&win,P3GrpHigh);

		/* Input happens here */
		P3HitRow = -1;
		key = dialog_input(HELP_P3HELP,group_input);

		/* Un-highlight any visible lines for the current group */
		if (group != UNGROUP) {
			for (kk = ctrow; kk <= cbrow; kk++) {
				if (kk != crow && group == dsparray[kk]->disp->group) {
					br_highlight(actwin,txtwin,kk - ctrow,
						P3ActColors[0][0],P3TxtColors[0][0]);
				}
			}
		}

		/* Bring menu back to normal colors */
		wput_a(&colorwin,colorsave);

		switch (key) {
		case KEY_UP:
			if (select < 1) select = nmenu-1;
			else select--;
			break;
		case KEY_DOWN:
			if (P3HitRow >= 0) {
				select = P3HitRow;
			}
			else {
				if (select >= nmenu-1) select = 0;
				else select++;
			}
			break;
		case KEY_CHOME:
			select = 0;
			break;
		case KEY_CEND:
			select = nmenu-1;
			break;

		case KEY_ENTER:
			if (P3HitRow >= 0) {
				select = P3HitRow;
			}
			{
				BYTE oldgroup;

				/* See if this was the last line of a group */
				oldgroup = dsparray[crow]->disp->group;
				for (kk = 0; kk < trows; kk++) {
					if (kk != crow && oldgroup == dsparray[kk]->disp->group) {
						/* Yes */
						break;
					}
				}
				if (kk >= trows) {
					/* No */
					GroupVector[oldgroup-1] = -1;
				}
			}
			dsparray[crow]->disp->group = group;
			if (group != UNGROUP) {
				GroupVector[group-1] = ndx;
			}
		case KEY_ESCAPE:
			goto bottom;
		}
	}
bottom:
	win_restore(save,TRUE);
	free_mem(colorsave);
	free_mem(menubuf);

	/* Re-enable buttons, etc. */
	dialog_callback(KEY_ESCAPE,chkabort);

	disableButton(DONE_KEY,FALSE);
	/* Don't care about toggle key 'cause it'll be reset by the caller */
	if (!first) disableButton(PREV_KEY,FALSE);
	if (!last)  disableButton(NEXT_KEY,FALSE);

#if 0	/* DEBUG */
	{
		/* Diagnostic: Put the group vector on the screen */
		WINDESC win;

		SETWINDOW(&win,21,0,1,3);
		for (kk = 0; kk < MAXGROUPS; kk++) {
			char temp[10];
			sprintf(temp,"%d   ",GroupVector[kk]);
			win.col = (kk * 3);
			wput_c(&win,temp);
		}
	}
#endif
	return (key == KEY_ENTER) ? 1 : 0;
}
#pragma optimize ("",on)

static KEYCODE group_input(	/* Input callback function */
	INPUTEVENT *event)	/* Event from dialog_input() */
{
	if (event->key) {
		/* Check our local valid key list */
		KEYCODE *kp;

		for (kp = GroupKeys; *kp; kp++) {
			if (*kp == event->key) {
				return event->key;
			}
		}
	}
	if ((event->y >= P3HitWin.row && event->y < P3HitWin.row + P3HitWin.nrows) &&
	    (event->x >= P3HitWin.col && event->x < P3HitWin.col + P3HitWin.ncols) ) {
		/* Mouse click in data window */
		switch (event->click) {
		case MOU_LSINGLE:
			P3HitRow = event->y - P3HitWin.row;
			return KEY_DOWN;
		case MOU_LDOUBLE:
			P3HitRow = event->y - P3HitWin.row;
			return KEY_ENTER;
		}
	}
	return 0;
}

#ifdef REORDER_DEBUG
#pragma optimize("leg",off)
#endif
DSPTEXT *reorder_lines(DSPTEXT *tx)
{
	int count;
	int index;
	DSPTEXT *t, *t2;
	SORTITEM *array;

	/* Count 'em up */
	for (count = 0, t = tx; t; t = t->next) {
		if (t->group || (t->psumfit && t->psumfit->ord)) count++;
	} /* for () */

	if (count == 0) return t; /* ..Should never happen */

	/* Allocate & build array for sorting */

	/* We want to reorder marked lines and associated groups */
	/* with minimal disruption.  Keeping the lines in their */
	/* original order, we first ensure that there is an order */
	/* recorded within each group and set up binding of unmarked */
	/* lines within the group to marked lines.  Unmarked lines */
	/* are always bound to the nearest marked line within the */
	/* group; however, if any given line is equidistant to */
	/* two marked lines, it goes with the previous one. */

	/* All unmarked lines bound to a particular marked line */
	/* are moved with it.  These lines may be taken out of context */
	/* if there are intervening spaces. */

	array = get_mem(count * sizeof(SORTITEM));
	for (index = 0, t = tx; t; t = t->next) {

		/* Only sort marked or grouped lines going high */
		if (!t->group && !(t->psumfit && t->psumfit->ord)) continue;

		array[index].t	  = t;
		array[index].key = index;
		array[index].oldprev  = t->prev;
		array[index].oldnext  = t->next;
		if (t->psumfit) {
			array[index].key |= ((unsigned)t->psumfit->ord << 8);
		} /* End if (marked line) */

		index++;	/* Adjust array index */

	} /* End for () */

#ifdef REORDER_DEBUG
	dump_sortitem(DEBUGFILE,"a","before associate_unmarked",array,count);
#endif
	associate_unmarked_lines (array, count);

	/* Remove unassociated lines from the array */
	for (index = 0; index < count; ) {
		if ((array[index].key & 0xff00) == 0xff00) {
			if (index < --count) {
				memcpy (&(array[index]), &(array[index+1]),
					(count-index) * sizeof(SORTITEM));
			} /* Not the last one */
		} /* Unassociated line */
		else	index++;	/* Process next */
	} /* for () */

#ifdef REORDER_DEBUG
	dump_sortitem(DEBUGFILE,"a","before squeeze",array,count);
#endif
	/* Set the original lines and flags in the squeezed array */
	/* Note that it's not necessary to save oldprev and oldnext */
	/* again here; those wouldn't have changed... */
	for (index = 0; index < count; index++) {
		array[index].oldindex = index;
		if (index && array[index-1].t == array[index].t->prev)
			array[index].prevarray = 1;
		else
			array[index].prevarray = 0;
		if (index+1 < count && array[index+1].t == array[index].t->next)
			array[index].nextarray = 1;
		else
			array[index].nextarray = 0;
	} /* for () */

	/* If we end up with empty hands, don't go any further. */
	/* This can happen if we have grouped lines in CONFIG.SYS, */
	/* but no marked lines. */
	if (!count) return (tx);

	/* Sort'em. Treat groups as unbreakable units. */
#ifdef REORDER_DEBUG
	dump_sortitem(DEBUGFILE,"a","before sort",array,count);
#endif
	qsort( (void *)array, (size_t)count, sizeof(SORTITEM),
		(int (*)(const void *, const void *))sortcomp );
#ifdef REORDER_DEBUG
	dump_sortitem(DEBUGFILE,"a","after sort",array,count);
#endif

	/* Now insert the sorted items into their new slots */
	for (index = 0; index < count; index++) {
		DSPTEXT *tpold,*tnold;
		int ndx;

		t2 = array[index].t;

		/* Find the entry who used to be in our place */
		for (ndx = 0; ndx < count; ndx++) {
			if (array[ndx].oldindex == index) break;
		}

		/* If we're not making any changes, we don't need to */
		/* do all this stuff... */
//		if (ndx == index)	continue;

		/* Won't you be my neighbor? */
		/* Note that prevarray and nextarray were set or cleared */
		/* depending on the position of the original slot prior */
		/* to sorting, so yes, we CAN assume that if prevarray, */
		/* oldindex>0 and therefore index>0.  Ditto for nextarray. */
		if (array[ndx].prevarray) {
			tpold = array[index-1].t;
		}
		else {
			tpold = array[ndx].oldprev;
		}
		if (array[ndx].nextarray) {
			tnold = array[index+1].t;
		}
		else {
			tnold = array[ndx].oldnext;
		}

		/* Join the homeowners' association */
		t2->prev = tpold;
		t2->next = tnold;

		/* Make sure they know about us */
		if (tpold)	tpold->next = t2;
		if (tnold)	tnold->prev = t2;

		/* The gap we leave behind will be taken care of */
		/* when we get to that slot. */

	}

	/* Find the new head of the list */
	for (t=t2; t->prev; t = t->prev)	;

	/* ...And toss the array */
	free_mem(array);
	return (t);
}
#pragma optimize("",on)

void associate_unmarked_lines (SORTITEM *array, int count)
{
	int ii;
	int jj;
	DSPTEXT *t,*t2;
	int dist1,dist2;
	BYTE ord1,ord2;

	/* Fix up unmarked lines that have a group.  Use the order byte */
	/* from the nearest marked line of the same group.  If two marked */
	/* lines from the same group are equidistant, use the first one. */
	/* If there are no marked lines from the same group, we'll ensure */
	/* they come at the end so we can ignore them. */
	for (jj = 0; jj < count; jj++) {

		t = array[jj].t;
		/* Unprocessed lines, if they're deliberately marked, */
		/* shouldn't be ignored.  This is a case where we */
		/* out-clever ourselves. */
		/* if (!t->visible) continue; */
		if (!t->psumfit || t->psumfit->ord == 0) {

			/* Find the closest marked line, or the first of */
			/* two if they're equidistant. */
			ord1 = 0xff;	/* Ensure it's at the end */
			for (ii = 0, dist1 = dist2 = 0; ii < count; ii++) {

				t2 = array[ii].t;
				if (t2->psumfit && t2->psumfit->ord &&
						t2->group == t->group) {
					if (ii < jj) {
					    if (!dist1 || dist1 > jj - ii) {
						dist1 = jj - ii;
						ord1 = t2->psumfit->ord;
					    }
					}
					else if (ii > jj) {
					    if (!dist2 || dist2 > ii - jj) {
						dist2 = ii - jj;
						ord2 = t2->psumfit->ord;
					    }
					}
				} /* It's a marked line in the same group */

			} /* for (ii;;) */

			if (dist2 && (dist1 > dist2 || !dist1)) {
				ord1 = ord2;
			}

			array[jj].key |= ((unsigned) ord1 << 8);

		} /* if (not a marked line) */

	} /* for () */

} /* End associate_unmarked_lines () */

int sortcomp(SORTITEM *p1,SORTITEM *p2)
{
	if (p1->key < p2->key) return -1;
	else if (p1->key > p2->key) return 1;
	return 0;
}

void save_groups(int this)
{
	int index;
	int kk;
	int lastgrp;
	FILE *fp;
	DSPTEXT *t;
	char filename[256];

	get_exepath(filename,sizeof(filename));
	strcat(filename,"REORDER2.CFG");

	fp = fopen(filename,"w");
	if (!fp) {
		/* Need an error message here */
		return;
	}

	t = HbatStrt[CONFIG];
	for (kk=lastgrp=0; kk < 2; kk++) {
		for (; t; t = t->next) {
			if (t->group) {
				if (t->group != (BYTE) lastgrp) index = 1;
				lastgrp = t->group;
				fprintf(fp,"USER%02d %02d",
					t->group,
					index);
				if (t->mark) {
				    fprintf (fp, " F %s\n", t->pdevice);
				}
				else {
				    fprintf (fp, " T \"%s\"\n", t->text);
				}
				index++;
			}
		}
		if (this) t = HbatStrt[this];
		else	  break;
	}
	fclose(fp);
}

#ifdef REORDER_DEBUG
static void dump_sortitem(char *fname,char *mode,char *tag,SORTITEM *item,int count)
{
	int kk;\
	FILE *fp;

	fp = fopen(fname,mode);
	if (!fp) return;

	fprintf(fp,"SORTITEM %s\n",tag);

	fprintf(fp,"   t      key  old prev  old next  t->psumfi t->grp t->text\n");
	fprintf(fp,"--------- ---- --------- --------- --------- ------ ------------------------\n");

	for (kk = 0; kk < count; kk++) {
		SORTITEM *ip;

		ip = item+kk;
		fprintf(fp,"%Fp %04X %Fp %Fp %Fp %6u %s\n",
			(void far *)ip->t,
			ip->key,
			(void far *)ip->oldprev,
			(void far *)ip->oldnext,
			(void far *)ip->t->psumfit,
			ip->t->group,
			ip->t->text);
	}
	fprintf(fp,"--------- ---- ------------------------\n");
	fclose(fp);
}
#endif /* REORDER_DEBUG */

void preset_group(int ndx,BOOL userfile)
{
	FILE *infile;
	char line[256];
	char id[7];
	char lastid[7];
	char subid[3];
	char flags[2];
	char file[128];
	BOOL gotone;
	BOOL gotany;
	BOOL txtmatch;
	DSPTEXT *ts;

	/* Phase I:  Set group ids from REORDER.CFG */

	get_exepath(line,sizeof(line));
	strcat(line,userfile ? "REORDER2.CFG" : "REORDER.CFG");

	/* Try to _open it */
	infile = fopen(line,"r");
	if (!infile) return;

	/* Read lines from file */
	*id = *lastid = '\0';
	gotone = gotany = txtmatch = FALSE;
	while (fgets(line,sizeof(line),infile)) {
		int here;
		char *pp;

		/* Cut off any comment text */
		pp = strpbrk(line,"\";");
		if (pp && *pp == ';') {
			*pp = '\0';
		}
		/* Ignore blank lines */
		if (trim(line) < 1) continue;

		here = 0;
		if (!next_token(line,&here,id,sizeof(id))) goto error;
		if (!next_token(line,&here,subid,sizeof(subid))) goto error;
		if (!next_token(line,&here,flags,sizeof(flags))) goto error;

		if (_stricmp(id,lastid) != 0) {
			/* Start of new group */
			if (gotany && !gotone) {
				/* No match on an 01 entry, toss any other
				 * matches for this group */
				remove_group(ndx,lastid);
			}

			strcpy(lastid,id);
			gotone = gotany = txtmatch = FALSE;
		}

		*flags = (char) toupper(*flags);
		if (*flags == 'F') {
			/* File name */
			if (!next_token(line,&here,file,sizeof(file))) goto error;
			if (!normalize_file(line,file)) goto error;
		}
		else if (*flags == 'T') {
			/* Text string */
			normalize_text(line,line+here);
		}
		else goto error;

		/* Do something important here */
		if (match_group(ndx,(*flags == 'T'),line,id)) {
			if (atoi(subid) == 1) {
				gotone = TRUE;
				txtmatch = (*flags == 'T') ? TRUE : FALSE;
			}
			gotany = TRUE;
		}
/*********** So what if we don't match the whole group? **************
 **** This is only an issue if we falsely match isolated lines.
 **** If we remove or change one line in the group, the whole thing
 **** gets thrown out.
		else {
			if (txtmatch) {
*********/
				/* Failed to match all of text group */
/********
				gotone = FALSE;
			}
		}
**********************************************************************/
		continue;
	error:
		continue;
	}
	/* Cleanup for last group */
	if (gotany && !gotone) {
		/* No match on an 01 entry, toss any other
		 * matches for this group */
		remove_group(ndx,lastid);
	}
	fclose(infile);

	/* Phase II:  Use group ids to assign group numbers */

	/* First, items that already have a group number */
	for (ts = HbatStrt[ndx]; ts; ts = ts->next) {
		if (!ts->visible) continue;
		if (*ts->groupspec == '+' && ts->group) {
			DSPTEXT *ts2;

			for (ts2 = HbatStrt[ndx]; ts2; ts2 = ts2->next) {
				if (!ts2->visible) continue;
				if (ts2 != ts &&
				    strcmp(ts->groupspec,ts2->groupspec) == 0) {
					if (!ts2->group) ts2->group = ts->group;
					*ts2->groupspec = '\0';
				}
			}
			*ts->groupspec = '\0';
		}
	}

	/* Next, items that don't have a group number */
	for (ts = HbatStrt[ndx]; ts; ts = ts->next) {
		if (!ts->visible) continue;
		if (*ts->groupspec == '+') {
			int grp;
			DSPTEXT *ts2;

			/* Find an unused group number */
			for (grp = 0; grp <= MAXGROUPS; grp++) {
				if (GroupVector[grp] == -1) {
					/* Got it */
					ts->group = (BYTE) (grp + 1);
					GroupVector[grp] = ndx;
					break;
				}
			}

			for (ts2 = ts->next; ts2; ts2 = ts2->next) {
				if (!ts2->visible) continue;
				if (strcmp(ts->groupspec,ts2->groupspec) == 0 &&
				    !ts2->group) {
					ts2->group = ts->group;
					*ts2->groupspec = '\0';
				}
			}
			*ts->groupspec = '\0';
		}
	}
}

/* Process next token in line */
static BOOL next_token(char *str,int *pos,char *tok,int ntok)
{
	int kk;
	char *p;

	p = str + *pos;

	/* Skip leading white space */
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	for (kk = 0; kk < ntok; kk++) {
		if (!(*p) || isspace(*p)) break;
		tok[kk] = *p++;
	}
	if (kk >= ntok) return FALSE;

	tok[kk] = '\0';
	*pos = p - str;
	return TRUE;
}

#pragma optimize ("leg",off)
static BOOL normalize_file(char *dst,char *src)
{
	int rtn;
	char *pp;
	char far *dstp;
	char far *srcp;


	if (isalpha(src[0]) && src[1] == ':') src += 2;

	for (pp = src; *pp; pp++) {
		if (*pp <= ' ') break;
		if (strchr("\"+,/;:<=>",*pp)) break;

		if (*pp == '\\' || *pp == ':') src = pp+1;
	}

	dstp = dst;
	srcp = src;
	_asm {
		mov  ax,2901h	/* Dos parse filename function */
		les  di,dstp	/* Destination FCB */
		push ds
		lds  si,srcp	/* Source string */
		int  21h	/* Do it */
		pop  ds
		xor  ah,ah
		mov  rtn,ax	/* Save return value */
	}
	/* Error check */
	if (rtn == 255) return FALSE;
	dst[0] = '?';
	dst[12] = '\0';
	if (memcmp(dst+9,"   ",3) == 0) strcpy(dst+9,"???");
	return TRUE;
}
#pragma optimize ("",on)

static void normalize_text(char *dst,char *src)
{
	BOOL quote;

	while (*src && isspace(*src)) src++;
	if (*src == '"') {
		quote = TRUE;
		src++;
	}
	else	quote = FALSE;

	while (*src) {
		if (quote && *src == '"') break;
		if (isspace(*src)) {
			*dst++ = ' ';
			while (*src && isspace(*src)) src++;
		}
		else {
			*dst++ = *src++;
		}
	}
	*dst++ = '\0';
}

BOOL match_group(int ndx,int tf,char *tftext,char *id)
/***
 * For the indexed batch file's DSPTEXT array, find the
 * entry matching tftext.  Treat it as (tf ? text : a filename)
 * when comparing.
 * For every match, we look through the entire list until
 * we find a match.  If the match occurs after at least one
 * other item already matched with the same group id, we set
 * that line.  Otherwise, we set the first line found.
 * This strategy is needed to handle cases like the following:
 *	   foobar1
 *	   if errorlevel 1 goto end
 * GROUP A foobar2
 * GROUP A if errorlevel 1 goto end
***/
{
	DSPTEXT *ts,*tsfound = NULL;
	int ingroup = 0, matched;

	for (ts = HbatStrt[ndx]; ts; ts = ts->next) {
		if (!ts->visible) continue;
		if (*ts->groupspec == '+') {
			if (!strcmp (ts->groupspec+1,id)) {
				ingroup = 1;
			} /* Matches our group */
			continue;
		} /* Group already specified */

		matched = 0;
		if (tf) {
			/* Text match */
			if (textcmp(tftext,ts->mark ? ts->pdevice : ts->text) == 0) {
				matched = 1;
			}
		}
		else if (*ts->groupspec) {
			/* File match */
			if (afncmp(tftext+1,ts->groupspec+1,11) == 0) {
				matched = 1;
			}
		}

		if (matched) {
			if (ingroup || !tsfound) {
				tsfound = ts;	/* Save for later */
			}
			if (ingroup) break;		/* Look no further */
		} /* We got a match of either type */

	}
	if (tsfound) {
		*tsfound->groupspec = '+';
		strcpy(tsfound->groupspec+1,id);
		return TRUE;
	}
	return FALSE;
}


void remove_group(int ndx,char *id)
{
	DSPTEXT *ts;

	for (ts = HbatStrt[ndx]; ts; ts = ts->next) {
		if (!ts->visible) continue;
		if (*ts->groupspec == '+') {
			if (_stricmp(ts->groupspec+1,id) == 0) {
				char *pp;

				*ts->groupspec = '\0';

				if (ts->mark)
					pp = ts->pdevice;
				else
					pp = ts->text;

				pp = not_rem(pp);
				if (pp) {
					normalize_file(ts->groupspec,pp);
				}
			}
		}
	}
}


int afncmp(char * s,char * t,int n)
{
	while (n>0) {
		if (*s != *t && *t != '?') {
			if (*s < *t) return -1;
			else return 1;
		}
		s++;
		t++;
		n--;
	}
	return 0;

}

int textcmp(char *s,char *t)
{
	/* Ignore leading whitespace */
	while (*s && isspace(*s)) s++;
	while (*t && isspace(*t)) t++;

	/* Whitespace insensitive compare */
	while (*s && *t) {
		if (isspace(*s) || isspace(*t)) {
			while (*s && isspace(*s)) s++;
			while (*t && isspace(*t)) t++;
		}
		else {
			if (*s < *t) return -1;
			else if (*s > *t) return 1;
			s++;
			t++;
		}
	}

	/* Check for trailing whitespace */
	if (!(*s) && *t) {
		while (*t) {
			if (!isspace(*t)) return 1;
			t++;
		}
	}
	else if (*s && !(*t)) {
		while (*s) {
			if (!isspace(*s)) return -1;
			s++;
		}
	}
	return 0;
}

static char *dev_eq(char *str)
{
	while (*str && isspace(*str)) str++;
	if (_memicmp(str,"device",6) == 0 ||
	    _memicmp(str,"install",7) == 0) {
		char *pp;

		pp = strchr(str,'=');
		if (pp) return pp+1;
	}
	return NULL;
}

static char *not_rem(char *str)
{
	while (*str && isspace(*str)) str++;
	if (!(_memicmp(str,"rem",3) == 0 && isspace(str[3]))) return str;
	return NULL;
}

#endif	/*REORDER*/
