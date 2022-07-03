/*' $Header:   P:/PVCS/MAX/MAXIMIZE/REBOOT.C_V   1.3   23 Jan 1996 14:56:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * REBOOT.C								      *
 *									      *
 * MAXIMIZE reboot processing						      *
 *									      *
 ******************************************************************************/

int _getch(void);
/* System Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <ctype.h>

/* Local includes */
#include <commfunc.h>		/* Common function prototypes */
#include <intmsg.h>		/* Intermediate message functions */

#define DOREBOOT_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef DOREBOOT_C

#ifdef STACKER
#include <stackdlg.h>
#include <stacker.h>
#endif

#ifndef PROTO
#include "reboot.pro"
#include "maximize.pro"
#include <maxsub.pro>
#include "screens.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */

/********************************** DOREBOOT **********************************/

int doreboot (void)
{
	int i;
	char *text = NULL;
	KEYCODE key;

	if (Pass == 1 || Pass == 2) {
		char batproc[80];

		dofndbat(batproc); /* Get path of BATPROC */
		if (*batproc) {
			/* Select text for reboot screen and number of rows */
			/* based on pass and drive of installation */
			switch (Pass) {
			case 1:
				if (toupper (BootDrive) == 'A') {
					if (RefDisk)
						text = MsgReboot1C;
					else
						text = MsgReboot1B;
				} /* End IF */
				else
					text = MsgReboot1A;

				break;

			case 2:
				if (toupper (BootDrive) == 'A')
					text = MsgReboot2B;
				else
					text = MsgReboot2A;

				break;

			} /* End SWITCH */

			/* Display the reboot panel */
			/* Last parameter is mask for key help screen */

			if (!NopauseMax) {

			 key = do_bootmsg(text);

			 if (key == KEY_ESCAPE) {
				AnyError = AbyUser = 1;
				return (-1);
			 } /* End IF */

			} // NopauseMax is not TRUE

			for (i = strlen (batproc) - 1 ; i ; i--) {
				if (batproc[i] == '.') {
					batproc[i] = '\0';
					break;
				} /* End FOR/IF */
			}
			aexecp1 (batproc);
			if (AnyError)
				return (-1);
			/* Rebooting the system will take a moment... */
			rebootmsg();

			write_lastphase (Pass); /* Write out last phase # */
			if (AnyError)
				return (-1);
			reboot();
			/* If user specified REBOOTCMD=, return to DOS */
		} /* End IF */
	} /* End IF pass 1 or 2 */
	if (toupper (BootDrive) == 'A')
		text = MsgReboot3B;
	else
		text = MsgReboot3A;

	if (!NopauseMax) {

	 key = do_bootmsg(text);
	 if (key == KEY_ESCAPE)
		AnyError = AbyUser = 1;
	 return (key == KEY_ESCAPE ? -1 : 0);

	} // NopauseMax is false
	else
	 return (0);	// If NopauseMax is true, blast ahead

} /* End DOREBOOT */

/********************************** AEXECP1 ***********************************
 * Since AUTOEXEC.BAT must start BATPROC before the commands in
 * AUTOEXEC.ABETA are executed, the drive:\path combination which
 * is valid when MAXIMIZE is running may not be valid until the
 * appropriate ASSIGN, JOIN, and/or SUBST commands have been processed.
 * We must start BATPROC from the canonical form of its current
 * path (obtained from the undocumented DOS TRUENAME function).
 * MAXIMIZE is started AFTER AUTOEXEC.ABETA has been processed,
 * and we can use the current path.  In fact, the canonical form
 * may have been invalidated by multiple ASSIGN, JOIN, and SUBST
 * commands.
 */

void aexecp1 (char *p)
{
	int ii;
	int n1,n2;
	char *q, *e;
	WORD fh, blen, alen;
	char batprocpath[ _MAX_PATH + 1 ], maximpath[ _MAX_PATH + 1 ],
		 opts[ 80 + 80 ], abetapath[ _MAX_PATH + 1 ];

	/*---------------------------------------------------------*/
	/*	p points to d:\path\batproc, copy and strip batproc    */
	/*---------------------------------------------------------*/

	strcpy (maximpath, p); /* use pathname as it is currently valid for MAXIMIZE */

	p = strcpy (batprocpath, p);	/* Copy to our data area */
	truename (p);			/* Get canonical form */

	/* Strip "batproc" and everything after it from the MAXIMIZE path */
	for (q = maximpath; *q; q++)
	{
		if (_strnicmp (q, "batproc", 7) == 0)

			/*-----------------------------------------------------*/
			/* Found BATPROC, make sure it's not \batproc\         */
			/*-----------------------------------------------------*/

		{
			e = q + 7;
			if (*e == ' ' || *e == '\0' || *e == '\t' || *e == '\n')
			{
				*q = '\0';
				break;
			} /* End IF */
		} /* End IF */
	} /* End FOR */

	/*---------------------------------------------------------*/
	/*	Modify text lines for AUTOEXEC.BAT file 	       */
	/*---------------------------------------------------------*/

	/* Why can't this be done in initialization???? */
	BatchAtxt[ERRMAXIM_LN1] = BatchBtxt[ERRMAXIM_LN2] =
		BatchBtxt[ERRMAXIM_LN3] = ActiveFiles[ERRMAXIM];

	/* Try to get canonical form of ERRMAXIM.BAT */
	truename (BatchAtxt[ERRMAXIM_LN1]);

	if (NopauseMax)
	 BatchBtxt[PAUSE_LN] = "\n";                   /* Clobber PAUSE */

	BatchBtxt[BPPATH_LN] = batprocpath;		/* Insert BATPROC command */
	sprintf (abetapath, " %s", ActiveFiles[BETAFILE]);
	/* If also passing DOSSTART.BAT, add it now */
	if (pszDOSStart) {
		strcat( abetapath, "," );
		strcat( abetapath, pszDOSStart );
	} /* Add ,c:\windows\dosstart.bat[,d:\other.bat[,...]] */
	BatchBtxt[BPAEXEC_LN] = abetapath;		/* AUTOEXEC.ABETA */
	BatchBtxt[MAXIMPATH_LN] = maximpath;		/* Path for MAXIMIZE command */
	BatchBtxt[MAXIMDRIVEARG_LN][0] = (char)BootDrive;	/* Drive letter on command line */

	/* Center the header line in its box */
	n1 = strlen(BatchHdr);
	n2 = strlen(BatchA02);
	memcpy(BatchA02+(n2-n1)/2,BatchHdr,n1);
	*strchr (BatchA02, '?') = (char) ('1' + Pass); /* Include pass # for next phase */
	*strchr (BatchBtxt[MAXIMIZE_LN], '?') = (char) ('1' + Pass); /* Include pass # for next phase */

	strcpy (opts, make_stackopts ());
	strcat (opts, ScreenType == SCREEN_MONO ? " /B" : " /C");

/***	Only used in Phase I
 *	if (ForceIgnflex)
 *		strcat (opts, " /I");
***/

	if (QuickMax > 0)
		strcat (opts, " /E");

	if (QuickMax < 0)
		strcat (opts, " /U");

	if (NopauseMax)
		strcat (opts, " /N");

	if (TimeoutInput)
		strcat (opts, " /T");

	if (FromWindows)
		strcat( opts, " /X" );

	if (MultiBoot) {
		strcat (opts, " /A ");
		strcat (opts, MultiBoot);
	}

	if (pszDOSStart) {
		strcat( opts, " /O " );
		strcat( opts, pszDOSStart );
	}

	if (RecallString) {
		strcat (opts, " /Z ");
		strcat (opts, RecallString);
	}

	strcat (opts, "\n");
	BatchBtxt[MAXIMOPT_LN] = opts;

	/*---------------------------------------------------------*/
	/*	Write text to AUTOEXEC.BAT file 		       */
	/*---------------------------------------------------------*/

	if (-1 == createfile (ActiveFiles[AUTOEXEC]))
		AnyError = 1;
	else {
		fh = _open (ActiveFiles[AUTOEXEC], O_TEXT|O_RDWR);
		for (ii = 0; !AnyError && ii < ATXTLEN; ii++) {
			blen = strlen (BatchAtxt[ii]);		/* Save the before length */
			alen = _write (fh, BatchAtxt[ii], blen); /* Write out the text line */
			if (alen != blen)	/* Check for errors */
				AnyError = 1;			/* Mark as in error */
		} /* End FOR */

		for (ii = 0; !AnyError && ii < BTXTLEN; ii++) {
			blen = strlen (BatchBtxt[ii]);		/* Save the before length */
			alen = _write (fh, BatchBtxt[ii], blen); /* Write out the text line */
			if (alen != blen)	/* Check for errors */
				AnyError = 1;			/* Mark as in error */
		} /* End FOR */

		_close (fh);

#ifdef STACKER
		SwapUpdate (AUTOEXEC);
#endif			/* ifdef STACKER */

	} /* End IF/ELSE */
} /* End AEXECP1 */
