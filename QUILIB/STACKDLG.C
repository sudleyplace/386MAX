/*' $Header:   P:/PVCS/MAX/QUILIB/STACKDLG.C_V   1.1   30 May 1997 12:09:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * STACKDLG.C								      *
 *									      *
 * Stacker dialog and support for manual drive compression		      *
 *									      *
 ******************************************************************************/

/***
 *
 * Stacker dialog and support for manual drive compression.
 * If the user wants to use the /K option to manually enable
 * drive compression, the following five parameters (declared
 * in STACKER.H) need to be specified:
 *
 * MaxConfig	Drive letter to use in all CONFIG.SYS references to MAX
 *		drive:\directory.
 *
 * ActualBoot	Drive letter to use when accessing the real boot drive.
 *
 * CopyBoot	Drive letter to copy changed CONFIG.SYS/AUTOEXEC.BAT to.
 *
 * CopyMax1	Drive letter for parallel MAX directory #1.  Changes to
 *		386MAX.PRO need to be copied here.
 *
 * CopyMax2	Drive letter for second parallel MAX directory.  Profile
 *		changes need to be copied here also.
 *
 * To avoid confusion, we ask three questions we can use to derive the
 * above.  If maxdrive == bootdrive, only two questions need answers.
 *
 * Q1: Is maxdrive compressed?
 * Q2: What is the actual drive for maxdrive?
 * (if maxdrive != bootdrive) Q3: What is ActualBoot?
 *
***/

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "commfunc.h"
#include "dialog.h"
#include "qhelp.h"
#include "stacker.h"

#define OWNER
#include "stackdlg.h"

/* It would be nice if we could initialize it &ActualBoot, &CopyBoot, etc... */
#define MAX_SWAPPARMS	5
static char *ptrmap[MAX_SWAPPARMS] = { 0, 0, 0, 0, 0 };
static char stacklead[] = { ' ','/','K',0 };
static char stackopts[sizeof(stacklead) + MAX_SWAPPARMS]; /* " /K" + parms + '\0' */

extern DIALOGPARM NormalDialog;
extern char *TitleAction;

extern char SwapTable[1];
extern int stacked_drive (int driveno);

#define ALPHANULL0(c)	(char) (isalpha(c) ? toupper(c) : '\0')
#define ALPHANULL(c)	c = ALPHANULL0(c)
#define STARNULL(c)	((char) (isalpha(c) ? c : '*'))

static void check_ptrmap (void)
{
 if (!ptrmap[0]) {
	ptrmap[0] = (char *) &ActualBoot;
	ptrmap[1] = (char *) &CopyBoot;
	ptrmap[2] = (char *) &MaxConfig;
	ptrmap[3] = (char *) &CopyMax1;
	ptrmap[4] = (char *) &CopyMax2;
 }
}

void get_stackopts (char **optp)
{
	int i;
	char *slash = strchr (*optp, '/');

	if (!slash) slash = *optp + strlen(*optp);

	/* Skip whitespace */
	while (**optp && strchr (" \t", **optp))        *optp++;

	sscanf (*optp, "%c%c%c%c%c",
		&ActualBoot,
		&CopyBoot,
		&MaxConfig,
		&CopyMax1,
		&CopyMax2);

	check_ptrmap ();
	for (i=0; i<MAX_SWAPPARMS; i++) ALPHANULL(*(ptrmap[i]));

	*optp = slash;

} /* End get_stackopts () */

char *make_stackopts (void)
{
 int i;

 if (SwappedDrive < 1)	stackopts[0] = '\0';
 else {
	strcpy (stackopts, stacklead);
	check_ptrmap ();
	for (i=0; i<MAX_SWAPPARMS; i++) {
		stackopts[sizeof(stacklead)-1+i] = STARNULL(*(ptrmap[i]));
	}
	/* Ensure null termination */
	stackopts[sizeof(stacklead)-1+i] = '\0';
 } // SwappedDrive > 0

 return (stackopts);

} /* End make_stackopts () */

/* Returns 1 if drive letter is valid */
#pragma optimize("leg",off)
int valid_drv (char driveltr)
{
  driveltr = (char) toupper (driveltr);
  if (isalpha (driveltr)) {
    _asm {
	mov	ah,0x30;	/* Get DOS version */
	int	0x21;		/* Major in AL, minor in AH */
	xchg	ah,al;		/* Swap for comparison order */

	push	ax;		/* Save */

	mov	ah,0x52;	/* Get list of lists */
	int	0x21;		/* ES:BX ==> list of lists */

	pop	ax;		/* Get DOS version */

	add	bx,0x10;	/* Assume DOS 3.0; logical drive count at 10h */
	cmp	ax,0x30a;	/* Izit DOS 3.1 or higher? */
	jb	not_dos31;	/* Jump if not */

	add	bx,0x10;	/* Logical drive count is at offset 20h */
not_dos31:
	mov	al,es:[bx];	/* Get number of logical drives */
	mov	ah,driveltr;	/* Get drive to check */
	sub	ah,'A';         /* A=0, B=1, C=2, etc. */
	cmp	ah,al;		/* Izit in range? */
	sbb	ax,ax;		/* AX=-1 if valid */
    }

  } /* It's alphanumeric */
  else return (0); /* Invalid drive letter */

} /* end valid_drv () */
#pragma optimize("",on)

void get_swapparms (	char bootdrive, /* Apparent boot drive */
			char maxdrive,	/* Drive of main MAX directory */
			char *destdir,	/* 386MAX directory */
			char *dlg,	/* Dialog context name to display */
			int hlp)	/* Help index */
/* If /K is specified but parameters aren't, get 'em */
/* The caller must own NormalDialog and TitleAction. */
{
	char	strings[MAX_SWAPPARMS][2],
		bootdriveStr[2],
		Q1,Q2,Q3;
	char	adialog[128];
	int	i,msgind;
	KEYCODE key;
	DIALOGPARM parm;
	int	numedits = sizeof (SwapEdit) / sizeof (DIALOGEDIT);

	if (ActualBoot && MaxConfig && CopyMax1)	return;

	// First, try to determine everything automatically...
	SwappedDrive = 0;	// Assume failure
	maxdrive = (char) toupper (maxdrive);
	bootdrive = (char) toupper (bootdrive);
	check_swap (bootdrive, maxdrive);
	if (SwappedDrive < 1) { // Set our own defaults; assume it's case 1
		Q1 = RESP_YES;
		Q2 = (char) (maxdrive + 1);
		Q3 = Q2;
		msgind = 0;
		swap_logic (bootdrive, maxdrive, TRUE, Q2, Q3);
	}
	else {
		Q1 = (char) (stacked_drive (maxdrive - 'A') ? RESP_YES : RESP_NO);
		Q2 = (char) (SwapTable[maxdrive-'A'] + 'A');
		if (Q2 == maxdrive) Q2 = ' ';
		Q3 = ActualBoot;
		msgind = SwappedDrive;
	}

	check_ptrmap ();
	if (AdvancedOpts) {
		sprintf (adialog, "%s_A", dlg);
		dlg = adialog;
	}
	else {
		numedits = (maxdrive == bootdrive ? 2 : 3);
		/* Note that this will cause make_getopts() to work */
		/* incorrectly, so we invalidate ptrmap[] when we're done */
		ptrmap[0] = (char *) &Q1;
		ptrmap[1] = (char *) &Q2;
		ptrmap[2] = (char *) &Q3;
		SwapEdit[0].editWin.row = Q1YPOS;
		SwapEdit[0].editWin.col = Q1XPOS;
		SwapEdit[1].editWin.row = Q2YPOS;
		SwapEdit[1].editWin.col = Q2XPOS;
		SwapEdit[2].editWin.row = Q3YPOS;
		SwapEdit[2].editWin.col = Q3XPOS;
	}

	// Set up edits
	for (i=0; i<MAX_SWAPPARMS; i++) {
		SwapEdit[i].editText = strings[i];
		strings[i][0] = (char) (*(ptrmap[i]) ? *(ptrmap[i]) : ' ');
		strings[i][1] = '\0';
	}
	bootdriveStr[0] = bootdrive;
	bootdriveStr[1] = '\0';

	/* This is really using the back door to make it easier for */
	/* INSTALL, MAXIMIZE, and QSHELL to share this code... */
	HelpArgTo[0] = bootdriveStr;
	HelpArgTo[1] = destdir;
	HelpArgTo[2] = AdvancedOpts ? SwapTypes[msgind] : (maxdrive == bootdrive ? SameAsMAX : ":");
	HelpArgTo[3] = DriveCMsg;
	DriveCMsg[DRIVECMSG] = maxdrive;

	parm = NormalDialog;
	parm.editShadow = SHADOW_NONE;

get_parms:
	key = dialog(&parm,
		TitleAction,
		dlg,
		hlp,
		SwapEdit,
		numedits);

	if (key == KEY_ENTER) {
		for (i=0; i<MAX_SWAPPARMS; i++) {
			*(ptrmap[i]) = ALPHANULL0(strings[i][0]);
		}

		if (!AdvancedOpts) {
			ptrmap[0] = NULL;  /* Invalidate for check_ptrmap() */
			if (!isalpha (Q2)) Q2 = maxdrive;
			if (maxdrive == bootdrive) Q3 = Q2;
			Q1 = (char) toupper (Q1);
			if ((Q1 != RESP_YES && Q1 != RESP_NO) ||
				!valid_drv (Q2) || !valid_drv (Q3))
							goto get_parms;
			swap_logic (bootdrive, maxdrive, Q1 == RESP_YES, Q2, Q3);
		}

		if (SwappedDrive < 1) {
			SwappedDrive = 1;	// Pretend it's Stacker
		}

		/* Check for cases where we needn't take action */
		if (CopyMax1 == maxdrive || !isalpha (CopyMax1))
				CopyMax1 = '\0';
		if (CopyMax2 == maxdrive || CopyMax2 == CopyMax1 || !CopyMax1 ||
				!isalpha (CopyMax2)) CopyMax2 = '\0';
		if (CopyBoot == bootdrive || !isalpha (CopyBoot))
				CopyBoot = '\0';
		if (!isalpha (MaxConfig))
				MaxConfig = '\0';

		if (!CopyMax1 && !CopyBoot) {
			SwappedDrive = 0;	// Do nothing
		}
	}

} /* End do_swapparms () */

