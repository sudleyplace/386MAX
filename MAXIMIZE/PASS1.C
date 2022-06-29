/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PASS1.C_V   1.1   26 Oct 1995 21:54:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PASS1.C								      *
 *									      *
 * Mainline for MAXIMIZE, phase 1					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>
#include <malloc.h>

#define PASS1_C 	/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef PASS1_C

/* Local includes */
#include <debug.h>		/* Debug variables */
#include <bioscrc.h>		/* CRC and machine type functions */
#include <mbparse.h>		/* MultiBoot definitions */

#ifndef PROTO
#include "chkram.pro"
#include "reboot.pro"
#include "copyfile.pro"
#if SYSTEM != MOVEM
#include "ins_mca.pro"
#include "proccfg1.pro"
#endif	/* SYSTEM != MOVEM */
#include "maximize.pro"
#include <maxsub.pro>
#include "parse.pro"
#include "pass1.pro"
#include "screens.pro"
#include "util.pro"
#include "wrconfig.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */

/************************************ PASS1 ***********************************/

void pass1 (void)
{
	char buff[100];
	DSPTEXT *cfg, *newMI, *newMD;
	char *newtext;
	SECTNAME *tmpsect;
	BOOL	bStripExtraDOS = FALSE,
		bStripVGASwap = FALSE,
		bStripUseHigh = FALSE;

	/*---------------------------------------------------------*/
	/*	Read and parse CONFIG.SYS file			   */
	/*---------------------------------------------------------*/

#if SYSTEM != MOVEM
	if ((
#ifdef DEBUG
	 (!MCAflag) &&
#endif
	 Is_MCA () == FALSE) || process_MCA () == FALSE) {
	 if (!AnyError) {
	    if (QuickMax == 0) {
		do_quickmax();
	    }
	    chkram();
	 }
	}
#else
	if (QuickMax == 0) {
		do_quickmax();
	}
	chkram();
#endif /*SYSTEM != MOVEM*/

	AbyUser = AnyError;
	if (AnyError) goto bottom;

	// If started from Windows, check for explicit removal of
	// BIOS USE= statements and for removal of VGASWAP.  If
	// ExtraDOS is verboten, we'll have to strip it from
	// CONFIG.SYS.
	if (FromWindows) {

		bStripUseHigh = GetProfileInt( "Remove", "UseHigh", 0, NULL );
		bStripExtraDOS = maxcfg.noharpo;
		bStripVGASwap = GetProfileInt( "Remove", "VGASwap", 0, NULL );

		// If removing any of these, turn on /I (ignore flexframe)
		if (bStripUseHigh || bStripExtraDOS || bStripVGASwap) {
			ForceIgnflex = 1;
		} // Ignoreflex required

		// Reset corresponding [Remove] values
		if (bStripUseHigh) WriteProfileInt( "Remove", "UseHigh", 0, NULL );
		if (bStripVGASwap) WriteProfileInt( "Remove", "VGASwap", 0, NULL );

	} // Started from Windows

	/*-----------------------------------------------------*/
	/*  If MultiBoot is active, we need to: 	       */
	/*  1.	Insert "REM mX~" before any MenuDefault item   */
	/*	in the [menu] section.			       */
	/*  2.	Insert the following lines at the beginning    */
	/*	of the [menu] section:			       */
	/*	MenuItem=%MultiBoot,Added temporarily...       */
	/*	MenuDefault=%MultiBoot,0		       */
	/*  In Phase 3, we will strip the REM mX~ magic cookie */
	/*  and remove the first two lines from [menu]	       */
	/*-----------------------------------------------------*/
	if (MultiBoot && (tmpsect = find_sect ("menu"))) {
	  newMI = NULL;
	  for (cfg = HbatStrt[CONFIG]; cfg; cfg = cfg->next) {
		if (cfg->MBOwner == tmpsect->OwnerID) {
		  if (cfg->MBtype == ID_SECT && !newMI	) {
			newMI = get_mem (sizeof (DSPTEXT));
			newMD = get_mem (sizeof (DSPTEXT));

			newMI->MBtype = ID_REM;
			newMI->MBOwner = cfg->MBOwner;
			sprintf (buff, "MenuItem=%s", MultiBoot);
			newMI->text = str_mem (buff);
			newMI->prev = cfg;
			newMI->next = newMD;

			newMD->MBtype = ID_REM;
			newMD->MBOwner = cfg->MBOwner;
			sprintf (buff, "MenuDefault=%s,0", MultiBoot);
			newMD->text = str_mem (buff);
			newMD->prev = newMI;
			newMD->next = cfg->next;

			cfg->next = newMI;
		  } /* Start of menu section */
		  else if (cfg->MBtype == ID_MENUDEFAULT) {
			/* Comment the line out with our magic cookie */
			newtext = get_mem (strlen (cfg->text) + 7 + 1);
			strcpy (newtext, "REM mX~");
			strcat (newtext, cfg->text);
			free_mem (cfg->text);
			cfg->text = newtext;
		  } /* Found a menudefault line */
		} /* Found menu section */
	  } /* for all DSPTEXT records from CONFIG.SYS */
	} /* MultiBoot active */

#if SYSTEM != MOVEM
	if (!AnyError)
	    proccfg1( bStripVGASwap, bStripUseHigh );
#endif /*SYSTEM != MOVEM*/
	if (AnyError) goto bottom;

#ifdef HARPO
	do_harpo( bStripExtraDOS ); /* Make sure HARPO is in CONFIG.SYS */
#endif				/* ifdef HARPO */

	/* Put 386LOAD GETSIZE on all DEVICE and INSTALL lines in */
	/* CONFIG.SYS.	If a program barfs with GETSIZE, it'll be */
	/* necessary to G flag it in 386LOAD.CFG.  (Note that the */
	/* G flag works for DEVICE and INSTALL programs in CONFIG.SYS, */
	/* whereas the A flag works only for programs loaded in */
	/* AUTOEXEC.BAT and its descendents.) */
	wrconfig(Pass);
	if (AnyError) goto bottom;

	/*-----------------------------------------------------*/
	/*  If no errors occurred, process BAT files	       */
	/*-----------------------------------------------------*/

	copyfile(ActiveFiles[AUTOEXEC], ActiveFiles[BETAFILE]);
	savefile(AUTOEXEC);

	restbatappend(AUTOEXEC);
	if (AnyError) goto bottom;

	/*-----------------------------------------------------*/
	/*	If no error occurred, reboot the system        */
	/*-----------------------------------------------------*/

	AnyError = doreboot();
bottom:
	return;
} /* End PASS1 */
