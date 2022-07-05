/*' $Header:   P:/PVCS/MAX/INSTALL/SCRN.C_V   1.4   31 Oct 1995 13:18:46   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SCRN.C								      *
 *									      *
 * Routines for the various screens displayed by INSTALL.EXE		      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <io.h>
#include <dos.h>
#include <process.h>
#include <conio.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>
#include <ver.h>

#include "bioscrc.h"
#include "c_tload.h"
#include "compile.h"
#include "common.h"
#include "commfunc.h"
#include "cpu.h"
#include "dcache.h"
#include "editwin.h"
#include "emsinfo.h"
#include "extn.h"
#include "extsize.h"
#include "filediff.h"
#include "fldedit.h"
#include "help.h"
#include "intmsg.h"
#include "malloc.h"
#include "myalloc.h"
#include "saveadf.h"
#ifdef STACKER
#include "stackdlg.h"
#include "stacker.h"
#endif
#include "svga_inf.h"
#include "ui.h"

#define SCRN_C
#include "instext.h"    /* Message text */
#undef SCRN_C

#ifndef PROTO
#include "scrn.pro"
#include "drve.pro"
#include "misc.pro"
#include "files.pro"
#include "install.pro"
#include "serialno.pro"
#include "pd_sub.pro"
#endif

extern char *ExeName;	// From EXENAME.C

/* Local variables */
CPUPARM cpu;

/* This is in MBOOTSEL.C */
extern WINRETURN vMBMenu_ask(	 PTEXTWIN pText, INPUTEVENT *event);
extern WINRETURN MBvWinPut_a( PTEXTWIN pText, int   row1, int	col1, int   row2, int	col2, int   attr );
#define vWinPut_a MBvWinPut_a

//******************************** SETCOLORS ********************************
//  Set up our color definitions for color or monochrome screen

void setColors(void)
{
	NormalDialog.editAttr = EditColor;
}

//***************************** CHECK_SYSTYPE **********************************
// Check on what type of machine this is.  The results here determine which
// product to install (max/mov), or if we have to ask what to install.
// Return TRUE if ok to proceed with install.
BOOL check_systype ( void )
{
	EMSPARM eparm;
	BOOL rtn;
	BOOL have_ems;
	int DoMoveEm = FALSE;

	// Processor & Windows check?
	check_cpu(&cpu);

	rtn = TRUE;		// Assume it's gonna work.

	// Set from command line, don't need to do the rest
	if (ProductSet) goto done;

	// Viable EMS support?
	// Although the 386MAX/BlueMAX INSTALL doesn't handle
	// Move'EM, we can still check to see if this system
	// will run Move'EM.  If it does, we tell 'em to send
	// in for the magic decoder ring.  If not, we give 'em
	// the same SOL message we always did.
	have_ems = FALSE;
	if (emsparm(&eparm) == 0) {

		EMSType = eparm.frame ? 2 : 1;
		/* EMS present, is it viable?  Our definition of
		 * viable is:  LIM v4.0 + any mappable pages in
		 * high DOS other than the page frame.
		 */
		if (eparm.version >= 0x40 && eparm.mpages) {
			WORD kk;
			EMSMAP *emap;

			emap = my_malloc(eparm.mpages * sizeof(EMSMAP));
			if (emap) {
				emsmap(emap);

				for (kk = 0; kk < eparm.mpages; kk++) {
					WORD addr = emap[kk].base;

					if (addr >= 0xA000 &&
					  !(addr >= eparm.frame &&
					    addr <  eparm.frame + 0x1000)) {
						have_ems = TRUE;
						break;
					}
				}
				my_free(emap);
			}
		}
	}

	// Do deja vu check
	// If one of our products is already running, assume a
	// re-install of the same product.
#if !MOVEM
	if (qmaxpres(NULL,NULL)) goto done;
#else
	if (qmovpres(NULL,NULL)) goto done;
#endif

	if (cpu.cpu_type >= CPU_80386) {
#if 0
		if (have_ems) {
			/* 386 w/ EMS, ask user */
			KEYCODE key;
			DIALOGPARM parm;

			parm = NormalDialog;
			parm.pButton = YesNoButtons;
			parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
			key = dialog(&parm,
				TitleAction,
				MsgMoveEm,
				NULL,
				NULL,
				0);

			if ( key == RESP_YES ) {
				DoMoveEm = TRUE;
			}
		}
#endif
	}
	else {
		if (!have_ems) {
			WORD chipset;

			/* 286 (or less) with no EMS, do we have a chipset? */
			chipset = check_chipset();
			if (chipset == CHIPSET_NEAT) {
				DoMoveEm = TRUE;
			}
			else {
				/* Can't install */
				do_error(MsgNoInstall,0,FALSE);

				rtn = FALSE;
			}
		} // !have_ems
		else
			DoMoveEm = TRUE;
	}
#if !MOVEM
	if (DoMoveEm) {
		DIALOGPARM parm;

		parm = ErrorDialog;
		parm.width = LARGE_DIALOG;

		disableButton(KEY_ESCAPE,TRUE);
		dialog(&parm,
			TitleError,
			MsgGetMovem,
			0,
			NULL,
			0);
		disableButton(KEY_ESCAPE,FALSE);
		rtn = FALSE;
	} // Move'EM system detected
#endif // not MOVEM
done:
	ProductSet = TRUE;
	return (rtn);

} // End check_systype

#if REDUIT
//**************************** CHECK_BCFSUPPORT ********************************
void	 check_bcfsupport ( void )
{

	profile_add ();

	// If AUTOBCF keyword exists, don't mess with BCF=
	if (!find_pro (AUTOBCF, NULL, NULL)) {
		// If it exists, remove BCF= line from profile
		remove_pro ("BCF", NULL, NULL);
		// Add AUTOBCF statement and comments if we found a match
		// If we didn't find the BCF file, it may be because
		// we can't get the CRC.  Put in AUTOBCF /t speculatively.
		// Maximize will remove it if there's no BCF file.
		if (bcfsys) {
			add2maxpro (ActiveOwner, bcf_fnd ? ProBcf : ProAutoBcf,
					BIOSCRC);
		} // It's a BCF system
	} // AUTOBCF not in profile

} // End check_bcfsupport
#endif

//***************************** DO_YESNO *************************************
// Display text and get a simple yes or no.
// Called by StripmgrOutput (pd_sub.asm) as well as by local functions.
KEYCODE  do_yesno (char _far *text, int helpnum)
{
	DIALOGPARM parm;
	int wid, lwid;
	char _far *tmp;

	parm = NormalDialog;
	wid = parm.width;

	// Grow the box if needed
	for (tmp = text, lwid = 0; *tmp; tmp++, lwid++) {
	    if (*tmp == '\n') {
		wid = max (wid, lwid);
		lwid = 0;
	    }
	} // for ()

	parm.width = min (wid, 72);
	parm.pButton = YesNoButtons;
	parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
	return (
	  dialog(&parm,
		TitleAction,
		text,
		helpnum,
		NULL,
		0)
	);

} // do_yesno ()

//***************************** DO_DROPOUT **********************************
void	 do_dropout ( void )
{
	dialog(&NormalDialog,
		TitleMessage,
		MsgDropOut,
		0,
		NULL,
		0);
} // End do_dropout


#pragma optimize ("leg", off)
//***************************** REBOOT **************************************
void	 reboot ( void )
{
	unsigned char _far *drvstat;
	unsigned int _far *rebootstat;
	void (_far *rebootptr) (void);

	(unsigned long) drvstat =	0x0040003fL;
	(unsigned long) rebootstat =	0x00400072L;
	(unsigned long) rebootptr =	0xf000fff0L;


	_asm {
		push	ds
		push	bp

		mov	ah,0x0d 	// Reset disk
		int	0x21		// Call DOS

		mov	ax,0xffa5	// PC Tools cache
		mov	cx,0xffff	// wierd API call
		int	0x16		// via keyboard interrupt

		pop	bp
		pop	ds
	}

	sleep (6000);			// Wait for disk cache to flush

	while (*drvstat & 0x01)
			;		// Wait for diskette motor to stop

	*rebootstat = 0x1234;		// Force warm boot

	_asm {
		push	ds
		push	bp

		mov	ax,0xc300	// Disable watchdog time-out
		int	0x15		// Request BIOS service

		pop	bp
		pop	ds
	}

	do_intmsg (MsgReboot);

	// First try a hard reboot.  If that fails, try a software reboot.
	_asm {
		cli;			// Disable interrupts
		sub	al,al;		// Prepare to clear DMA page port
		out	0x80,al;	// Clear mfg port
		mov	al,0xFE;	// Shutdown command
		out	0x64,al;	// Shutdown via 8042
		nop;			// Wait for something to happen
	}

	(*rebootptr) ();		// Reboot

} // reboot ()
#pragma optimize ("", on)

//***************************** DO_MAXIMIZE ************************************
void	 do_maximize ( void )
{
	KEYCODE key;
	int len;

	// If we're in V86 mode and MAX is not in the system,
	// ask the user if he/she wants to reboot so we can
	// run MAXIMIZE.
	if (Is_VM () && !MaxInst) {
	 DIALOGPARM parm = NormalDialog;

	 parm.pButton = MMMButtons;
	 parm.nButtons = sizeof(MMMButtons)/sizeof(MMMButtons[0]);
	 do {
	   key = dialog(&parm,
		TitleAction,
		MsgMMMaximize,
		HELP_DOMAXIMIZE,
		NULL,
		0);
	    if (key == RESP_MORE )
		showHelp (HELP_DOMAXIMIZE, FALSE);
	 } while (key == RESP_MORE );

	 if (key == RESP_REBOOT) {
		/***
		 *	User requested to reboot and run MAXIMIZE.
		 *	We need to save the AUTOEXEC.BAT as
		 *	AUTOINST.$$$, create an AUTOEXEC.BAT
		 *	which chains to AUTOINST.BAT, which
		 *	itself does the following:
		 *	1. Copies the original AUTOEXEC.BAT back in
		 *	   place.
		 *	2. Displays a brief "Come out of your
		 *	   shell" message.
		 *	3. Processes AUTOEXEC.BAT using BATPROC.
		 *	4. Starts MAXIMIZE with the same color
		 *	   and boot drive parameters given during
		 *	   INSTALL.  MAXIMIZE will display its
		 *	   logo, giving ample opportunity to abort.
		 ***/

		char destpath[MAXPATH+6];
		FILE *autotemp;

		// Copy AUTOEXEC.BAT to c:\386max\autoinst.$$$
		sprintf (destpath, "%sAUTOINST.$$$", dest_subdir);
		copy_file (StartupBat, destpath);

		// Create c:\386max\autoinst.bat which restores original
		// AUTOEXEC and starts MAXIMIZE.
		sprintf (destpath, "%sAUTOINST.BAT", dest_subdir);
		autotemp = cfopen (destpath, "w", 1);

		sprintf (destpath, "%sAUTOINST.$$$", dest_subdir);
		truename (destpath);
		cfprintf (autotemp, MsgAutotemp, OEM_ProdFile, destpath);
		strcpy (destpath, StartupBat);
		truename (destpath);
		cfprintf (autotemp, "%s\n", destpath);
		sprintf (destpath, "%sBATPROC", dest_subdir);
		truename (destpath);
		cfprintf (autotemp, "%s %s * 386LOAD\n", destpath, StartupBat);
		exec_maximize (destpath);	// Build MAXIMIZE.exe /opts
		cfprintf (autotemp, "%s\n", destpath);
		fclose (autotemp);

		// Create new AUTOEXEC.BAT which starts c:\386max\autoinst.bat
		autotemp = cfopen (StartupBat, "w", 1);
		sprintf (destpath, "%sAUTOINST.BAT", dest_subdir);
		truename (destpath);
		cfprintf (autotemp, "%s\n", destpath);
		fclose (autotemp);

		reboot ();

	 } // Reboot and run MAXIMIZE

	 return;
	}

	// We can clobber the last byte of BackupDir; we don't need it anymore
	if (FilesBackedUp && (len = strlen (BackupDir)))
		BackupDir [len - 1] = '\0';

	do_textarg(1,BackupDir);
	do_textarg(2,RMOLDMAX);
	key = do_yesno ((Backup && !ReInstall && FilesBackedUp) ?
				MsgMaxBack : MsgMaximize,
		HELP_DOMAXIMIZE);

	if (key == RESP_YES ) {
		exec_maximize (NULL);
	}
	else {
		key = dont_take_no(MsgNoMaximize,HELP_NOMAXIMIZE);
		if ( key == RESP_YES ) {
			exec_maximize (NULL);
		}
	}
} // End do_maximize


//***************************** DO_CONFIGSYSN *********************************
// Show proposed changes and ask the user if we should make them.
// Return 0 if not.
// Return 1 if yes and changes were made.
// Return 2 if no changes were needed.
#pragma optimize("leg",off)
int	do_configsysn ( void )
{
	char	fdrive[_MAX_DRIVE],
		fdir[_MAX_DIR],
		fname[_MAX_FNAME],
		fext[_MAX_EXT];
	enum { FDIFF=0, DBUTTONS } focus = DBUTTONS;
	TEXTWIN pFdiff, pDescript;
	WINDESC workWin, FileWin, DescWin, tempWin;
	WINDESC LclWin = {4,	/* row */
			  2,	/* col */
			  16,	/* nrows */
			  74};	/* ncols */
	WINDESC BtnWin = {16, 2, 4, 74};
	INPUTEVENT event;
	void *behind = NULL;
	int filecount, helpcount;
	int i, oldButtons, winError;
	int helpType;
	int DescWindow = 0, FileWindow = 0;
	WORD key;
	unsigned char OldHelpAttr;
	unsigned char OldHelpBAttr;
	char ChangeText[80];
	FILEDELTA *pF;
	char *ShowFile;
	int prepend_path;

	writefiles ();		// Write CONFIG.ADD and 386MAX.ADD to disk
				// All other .ADD files already exist

	// Close INSTALL.HLP while we're creating .DIF files -
	// we might run out of file handles in the default (FILES=8)
	// configuration:
	// 0-4 stdin, stdout, stderr, AUX, PRN
	// 5-7 config.sys, config.add, config.dif
	endHelp();

#if !MOVEM
	// For SYSTEM.INI, if we didn't find it we didn't create it.
	if (WIN30 == NO || !win_fnd) {
	  // Show WINDOWS.DOC only if they requested Windows support
	  // but don't know where the windows directory is
	  Changes[CHG_WINDOWS].Active = (WIN30 != NO);
	} // No Windows
#endif // not MOVEM

	// Walk through the entire FILEDELTA chain, adding up files
	// changed (filecount) and cCount for each file.
	for (filecount=0, pF = pFileDeltas; pF; pF = pF->pNext)
	  if (pF->pszOutput /* && !access (pF->pszOutput, 0) */) {
	    if (access (pF->pszPath, 0)) {
		pF->cChanges = -1;
// We can't free it because it's part of a pool...
//		if (pF->pszDiff) free (pF->pszDiff);
		pF->pszDiff = pF->pszOutput;
	    } // We're creating the file from scratch
	    else {
		// If there are no changes, don't increment filecount
		if (!(pF->cChanges = file_diff (pF->pszPath,
					pF->pszOutput, pF->pszDiff))) continue;
	    } // Create .DIF file
	    pF->Index = filecount++;
	  } // .ADD file exists

	// Reopen INSTALL.HLP
	if( startHelp(HelpFullName,HELPCOUNT) ) {
		error(-1,MsgHelpSystemErr);
	}

	if (!filecount) return (2); // No changes needed

	// Tally up help files (README, WINDOWS.DOC).
	for (helpcount = filecount, i=0; i < NUMCHANGES; i++)
		if (Changes[i].Active) helpcount++;

	// We dump FILEDELTA records to the screen sequentially, then
	// enabled Changes records (README, WINDOWS.DOC).
	// When an entry is selected, if the index is less then filecount,
	// we hunt for a matching pF->Index.  Otherwise, we display
	// Changes[index-filecount].

	// We need to construct a dialog mechanism similar to the
	// option editor.  Focus is on the OK button by default, but
	// can be moved to the "View changes and on-line documentation"
	// group using TAB or Alt-V.
	show_cursor ();
	push_cursor ();

	// Get a background window
	SETWINDOW( &workWin,
	LclWin.row - 2,
	LclWin.col-1,
	LclWin.nrows+4,
	LclWin.ncols+2);

	/*	Remember what we are stomping on */
	behind = win_save( &workWin, TRUE );
	if( !behind ) {
		errorMessage(WIN_NOROOM);
		return (0); // Continue without saving changes
	}

	/*	Put up the window */
	wput_sca( &workWin, VIDWORD( BaseColor, ' ' ));
	shadowWindow( &workWin );
	box( &workWin, BOX_DOUBLE, TitleAction, FDiffBottomTitle, BaseColor );

	/*	Set up our buttons and turn 'em on */
	disableButton (KEY_ESCAPE, FALSE);
	addButton (FileChgButtons, NUMFILECHGBUTTONS, &oldButtons);
	disableButton (KEY_ENTER, FALSE);
	disableButton (KEY_F1, FALSE);
	showAllButtons ();

	SETWINDOW (&FileWin,
			LclWin.row + LclWin.nrows - 6,
			LclWin.col+4,
			4, LclWin.ncols-9);

	winError = vWin_create (&pFdiff,	// Text window pointer
			&FileWin,		// Window extent descriptor
			max (helpcount, 4),	// Rows in virtual window
			FileWin.ncols,		// Width of window
			OptionTextColor,
			SHADOW_SINGLE,
			BORDER_NONE,
			TRUE, FALSE,		// Scroll bars
			FALSE,			// Remember what was below
			FALSE); 		// Delayed update

	if (winError != WIN_OK) {
		errorMessage (WIN_NOMEMORY);
		goto DOCONFIG_EXIT;
	}

	// Get an extent descriptor we can use for vWin_show ()
	SETWINDOW (&FileWin, 0, 0, FileWin.nrows, FileWin.ncols);

	FileWindow = 1;
	// Dump dialog text into window
	SETWINDOW ( &DescWin,
		LclWin.row,
		LclWin.col + 1,
		LclWin.nrows-6,
		LclWin.ncols-3);

	helpType = HelpInfo[HELP_CONFIGSYS].type;
	/* This is a MAJOR kludge... */
	OldHelpAttr = HelpColors[0];
	HelpColors[0] = BaseColor; /* Colors for normal text */
	OldHelpBAttr = HelpColors[1];
	HelpColors[1] = NormalColor; /* Colors to show for "Press Alt-V ..." */
	winError = loadHelp (&pDescript,
			&DescWin,
			&helpType,
			HelpNc (MsgConfigSysN, HelpTitles[0].context),
			BaseColor,
			SHADOW_NONE,
			BORDER_NONE,
			FALSE, FALSE,	/* Scroll bars */
			FALSE); 	/* Don't save background */
	/* Restore help color translation array */
	HelpColors[1] = OldHelpBAttr;
	HelpColors[0] = OldHelpAttr;

	if (winError == WIN_OK) DescWindow = 1;
	else {
		errorMessage (WIN_NOMEMORY);
		goto DOCONFIG_EXIT;
	}

	// Add active items to the text window
	SETWINDOW (&tempWin, 0, 0, 1, FileWin.ncols-1);
	tempWin.col = 0;
	for (pF = pFileDeltas; pF; pF = pF->pNext)
	  if (pF->cChanges) {
		_splitpath (pF->pszPath, fdrive, fdir, fname, fext);
		// "Changes to c:\386max\386max.pro"
		//  | 20 chrs ||  30 chrs	  |
		// Allow 2 for drive + 12 for filename; maximum for path
		// is 16.  If greater, truncate to first 12 + "...\"
		if (strlen (fdir) > 16) strcpy (fdir+12, "...\\");

		sprintf (ChangeText, ChangesTo, fdrive, fdir, fname, fext);
		tempWin.ncols = strlen (ChangeText);
		vWinPut_c (&pFdiff, &tempWin, ChangeText);
		tempWin.row++;

	  } // Changes were made

	for (i=0; i < NUMCHANGES; i++)
	  if (Changes[i].Active) {

	    tempWin.ncols = strlen (Changes[i].DisplayTxt);
	    vWinPut_c (&pFdiff, &tempWin, Changes[i].DisplayTxt);
	    tempWin.row++;

	  } // Item is active

	pFdiff.cursor.row = 0;	// Start at line 1
	// A nasty kludge to leave a blank line
	if (helpcount < pFdiff.size.row) {
		pFdiff.size.row = helpcount;
		pFdiff.win.nrows = helpcount;
	}
//	vWin_show_cursor (&pFdiff);

	if (pFdiff.vScroll.row > 0)
		paintScrollBar (&pFdiff.vScroll, pFdiff.attr,
			pFdiff.size.row - pFdiff.win.nrows, pFdiff.corner.row);

	focus = DBUTTONS; // Initial focus is "OK"
	setButtonFocus (TRUE, KEY_ENTER);

	do {
		int oldFocus = focus;
		int action;

		// Get a virtual window to redisplay
		FileWin.row = pFdiff.corner.row;

		if (focus == FDIFF) {
			vWinPut_a (&pFdiff, pFdiff.cursor.row, 0,
			  pFdiff.cursor.row, pFdiff.win.ncols, OptionHighColor);
			vWin_show_cursor(&pFdiff);
			vWin_show (&pFdiff, &FileWin);
		} // We're in the view files box

		// Get input
		get_input(INPUT_WAIT, &event);

		if (focus == FDIFF) {
			vWinPut_a (&pFdiff, pFdiff.cursor.row, 0,
			  pFdiff.cursor.row, pFdiff.win.ncols, pFdiff.attr);
			vWin_hide_cursor (&pFdiff);
			vWin_show (&pFdiff, &FileWin);
		} // We're in the view files box

		// Check for window button
		action = testButtonClick( &event, FALSE ) ? WIN_BUTTON : WIN_NOOP;
		if (action == WIN_BUTTON) {
		  pushButton (LastButton.number);
		  switch (key = LastButton.key) {
		    case KEY_ESCAPE:
			chkabort ();
			continue;

		    case FILECANKEY:
		    case KEY_ENTER:
			goto DOCONFIG_EXIT;
		    case KEY_F1:
			if (testButton (KEY_F1, TRUE))
					showHelp (HELP_CONFIGSYS, FALSE);
			continue;
		  } // switch()
		} // Got a window button

		// Check for Alt key focus change
		switch (key = event.key) {
		  case FILECHGKEY:	// Alt-V
//		  case ALTFILECHGKEY:	// Plain old V
//		  case ALTFILECHGKEY2:	// Same but in lowercase
			focus = FDIFF;
			goto changefocus;

		  case FILECANKEY:	// Alt-C
			goto DOCONFIG_EXIT;

		  case KEY_F1:
			if (testButton (KEY_F1, TRUE))
					showHelp (HELP_CONFIGSYS, FALSE);
			continue;
		} // switch ()

		// Check for mouse click
		if (event.click != MOU_NOCLICK) {
		  int act1;

//		  act1 = inWin (&pFdiff, &event);
		  if(event.x < pFdiff.win.col ||
		    event.y < pFdiff.win.row ||
		    event.x > pFdiff.win.col + pFdiff.win.ncols || /* was -1 */
		    event.y > pFdiff.win.row + min (pFdiff.win.nrows,
			helpcount) - 1) {
			act1 = 0; // Totally nowhere...
		  }
		  /* are we on the scroll bar?? */
		  else if (event.x == pFdiff.win.col + pFdiff.win.ncols) {
			act1 = 2;
		  }
		  else act1 = 1;

		  if (act1) {
		    if (event.click == MOU_LSINGLE ||
			event.click == MOU_LDOUBLE ||
			event.click == MOU_LDRAG) {
			if (act1 == 1) {
			  vWinPut_a (&pFdiff, pFdiff.cursor.row, 0,
				pFdiff.cursor.row, pFdiff.win.ncols,
				pFdiff.attr);
			  pFdiff.cursor.row = pFdiff.corner.row +
						(event.y - pFdiff.win.row);
//			  pFdiff.cursor.col = pFdiff.corner.col +
//						(event.x - pFdiff.win.col);
			  if (event.click == MOU_LDOUBLE) {
				if (focus != FDIFF) setButtonFocus (FALSE, KEY_TAB);
				focus = FDIFF;
				goto view_file;
			  } // Double click
			  vWinPut_a (&pFdiff, pFdiff.cursor.row, 0,
				pFdiff.cursor.row, pFdiff.win.ncols,
				OptionHighColor);
			} // Happened in the window
		    } // Got an event we're interested in
		    if (focus != FDIFF) {
			focus = FDIFF;
			goto changefocus;
		    } // Change of focus
		    goto process;
		  } // Rodent activity in the file list

		} // Mausklick...

		// Process other keystrokes
		switch (key = toupper (event.key)) {
		  case KEY_TAB:
		  case KEY_STAB:
		    switch (focus) {
		      case DBUTTONS:
			if (testButton (event.key, FALSE == BUTTON_LOSEFOCUS)) {
				focus = FDIFF;
				goto changefocus;
			}
			break;
		      case FDIFF:
			focus = DBUTTONS;
			goto changefocus;
		    } // switch (focus)
		    continue;

		  case KEY_ESCAPE:
		    chkabort ();
		    continue;

		  case FILECANKEY:
		    // No edit fields to pass keys on to
		    testButton (event.key, TRUE);
		    goto DOCONFIG_EXIT;

		  case KEY_ENTER:
		    if (focus == FDIFF) {
			key = 0;
view_file:
			i = pFdiff.cursor.row; // Get index
			if (i >= filecount) {
			  ShowFile = Changes[i-filecount].DisplayFile;
			  prepend_path = 1;
			} // File is in the Changes[] list
			else for (pF = pFileDeltas; pF; pF = pF->pNext) {
			  if (pF->Index == i && pF->cChanges) {
				ShowFile = pF->pszDiff;
				prepend_path = 0;
				break;
			  } // Index matches
			} // For all Changes[]
			view_textfile (ShowFile, prepend_path);
			if (pFdiff.cursor.row + 1 < helpcount) {
//				pFdiff.cursor.row++;
//				continue;
				event.key = KEY_DOWN;
				goto process;
			} // Not at the end of the list
			else {
				focus = DBUTTONS;
				goto changefocus;
			} // Change focus
		    } // focus == FDIFF
		    // Else fall through
		  case RESP_OK:
		    key = testButton (event.key, TRUE);
		    goto DOCONFIG_EXIT;

		} // switch ()
		goto process;

changefocus:
		switch (oldFocus) {
		  case DBUTTONS:
			setButtonFocus (FALSE, KEY_TAB);
			break;
		} // switch (oldFocus)

		switch (focus) {
		  case DBUTTONS:
			setButtonFocus (TRUE, event.key);
			break;
		} // switch (focus)

process:
		if (focus == FDIFF)
		   if (vMBMenu_ask (&pFdiff, &event) == WIN_BUTTON) break;

	} while (key != KEY_ENTER);

DOCONFIG_EXIT:
	dropButton (FileChgButtons, NUMFILECHGBUTTONS);
	if (DescWindow) vWin_destroy (&pDescript);
	if (FileWindow) vWin_destroy (&pFdiff);

	if (behind) win_restore (behind, TRUE);
	pop_cursor ();

	if (key != KEY_ENTER) return (0); // No changes

	do_intmsg (MsgCreateBackup);
	for (pF = pFileDeltas; pF; pF = pF->pNext)
	  if (pF->cChanges > 0) {
		copy_file (pF->pszPath, pF->pszBackup);
		cpreinst_sub (pF->pszBackup, pF->pszPath, pF->swap1, pF->swap2);
	  } // Backup preexisting files

#if !MOVEM
	if (ReadWinVer && WindowsVer < 0x30a) {
	  // Disable ExtraDOS in Maximize if they're running Windows 3.0
	  edit_maxcfg ("NO" MAX_HARPO, CfgNoExtraDOS, 1);
	} // Found WINVER.EXE and the version is 3.0
#endif // not MOVEM

	// *.ADD files need to be copied to their respective
	// destinations
	for (pF = pFileDeltas; pF; pF = pF->pNext)
	  if (pF->cChanges) {
		do_intmsg (MsgWrtFile, pF->pszPath);
		copy_file (pF->pszOutput, pF->pszPath);
	  } // Save files with changes

	return (1);

} // End do_configsysn
#pragma optimize("",on)


typedef struct _VS_VERSION {
    WORD wTotLen;
    WORD wValLen;
    char szSig[16];
    VS_FIXEDFILEINFO vffInfo;
} VS_VERSION;

//***************************** DO_WINDOWS *************************************
BOOL do_windows ( void )
{
	BOOL rc = TRUE;
	KEYCODE key;
	int nstem;
	DIALOGEDIT edit;
	char win_path[MAXPATH+1];
	char	fdrive[_MAX_DRIVE],
		fdir[_MAX_DIR],
		SetupPath[MAXPATH+1];
	FILEDELTA *pSYSINI, *pWinIni, *pProgIni;

	if ( !do_warning(MsgNoWinSupp,0) ) // If FALSE, continue w/o Win support
	     return rc;

	// Find the Windows directory so we can execute WIN.COM
	if ( locate_winfles (win_path) ) {
		do_backslash (win_path);
		adjust_pfne (win_path, boot_drive, ADJ_PATH);
		nstem = strlen(win_path);
		strcat(win_path, WIN_COMFLE);
		if (!access (win_path, 0)) goto WIN_EDIT;
		win_path[nstem] = '\0';
	}
	else {
		key = do_yesno (MsgNoWin, HELP_NOWIN);

		if (!(rc = (key == RESP_YES))) goto DO_WINDOWS_EXIT;
		strcpy (win_path, INIT_WINDIR);

	}

	edit = PathEdit;
	edit.editText = win_path;
	edit.editLen = MAXPATH;
WNDPFNE:
	// If the user doesn't know where the Windows directory is,
	// let 'em hit Escape and we'll continue with the DOS-only install.
	key = dialog(&NormalDialog,
			TitleFileDir,
			MsgWinPath,
			HELP_GETWNDPFNE,
			&edit,
			1);

	if (key == KEY_ESCAPE) goto DO_WINDOWS_EXIT;

	trim (win_path);
	do_backslash ( win_path );
	adjust_pfne ( win_path, boot_drive, ADJ_PATH );
	nstem = strlen(win_path);

	strcat(win_path,WIN_COMFLE);
	if ( !( access ( win_path, 0 ) ) ) { // If the file exists
		goto WIN_EDIT;
	} else {
		win_path[nstem] = '\0';
		do_textarg(1,win_path);
		// If they don't want to re-enter the path, end of story...
		if ( do_warning(MsgBadWinSubdir,0) )	goto WNDPFNE;
		else
		     goto DO_WINDOWS_EXIT;
	}

WIN_EDIT:
	// Launch WIN.COM with an argument of "d:\path\SETUP.EXE"
	// Unhook interrupts, but don't touch the screen...
	endHelp ();	// Close INSTALL.HLP
	end_input ();	// Restore Int 9
	done2324 ();	// Restore Ints 23h and 24h
	closehigh ();	// Unlink high DOS

	_splitpath (ExeName, fdrive, fdir, NULL, NULL);
	_makepath (SetupPath, fdrive, fdir, PROGNAME, ".EXE");
	_execl (win_path, win_path, SetupPath, NULL);

	// To display our warning, we need to re-initialize the help system
	inst2324 ();
	set_video (FALSE);

	do_error(MsgExecWinErr,0,FALSE);
	return_to_dos(0);
DO_WINDOWS_EXIT:
	return ( rc );

} // End do_windows


//***************************** DO_MONO ****************************************
// If USE=B000-B800 is not already in the profile, the VGA card is not
// on the "no way" list, and the user says "Yes" to recover the MDA,
// add USE=B0-B8 to the profile.
void	 do_mono ( void )
{
	KEYCODE key;
	DIALOGPARM parm;
	char *title;
	char *text;
	char temp[20];
	char temp2[80];
	int  i;

	if (VGAWARN & VW_FORCED) {	/* Vendor/model info unavailable */
		sprintf (temp2, CfgNoVS_Force);
	}
	else {				/* Prepare comment with info */
		sprintf (temp2, CfgNoVS_Adap, SVGA_VENDORID (-1),
						SVGA_MODELID (-1));
	}

	if (VGAWARN & VW_UNSAFE) {	/* Add NOVGASWAP */
		/* MONO = NO; */
		goto ADD_NOVGASWAP;
	}

	if (VGAWARN & VW_RISKY) {
		/* Warn about Super VGA card memory overlap */
		/* N.B.: Only VW_UNSAFE can be forced */
		do_textarg(1,SVGA_VENDORID (-1));
		do_textarg(2,SVGA_MODELID (-1));
		sprintf (temp, "%d",VGAMEM);
		do_textarg(3,temp);

		title = TitleWarning;
		text = MsgSVGAWarn;
	}
	else {
		title = TitleAction;
		text = MsgGetMono;
	}

	parm = NormalDialog;
	parm.pButton = YesNoButtons;
	parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
	key = dialog(&parm,
		title,		// Can't use do_yesno() here; dynamic title
		text,
		HELP_GETMONO,
		NULL,
		0);

	if ( key == RESP_YES ) {
		MONO = YES;
	}

	if ((text == MsgSVGAWarn && MONO == NO) || (VGAWARN & VW_NOSWAP)) {
ADD_NOVGASWAP:
		// If a dubious SVGA card and user said "No," add NOVGASWAP
		// Also add it for cards like the ATI MACH32, where we can
		// recover the monochrome area but VGASWAP doesn't work...
		edit_maxcfg ("NOVGASWAP", temp2, 1);
	}

	if (MONO != YES) return;

	// If there is available space in the MDA and they want it,
	// then add the appropriate statement(s) to the profile.
	for ( i=0; i < cnt_mono; i++ ) {
	  // Add it only if it's not already there
	  sprintf (temp, "%04X",        mono_mem[i].strt_blk);
	  sprintf (temp2,"%04X",        mono_mem[i].end_blk);
	  if (!find_pro (UseRam[0], temp, temp2)) {
		add2maxpro (ActiveOwner, "%s=%s-%s%s", UseRam[0], temp, temp2,
				ProMono);
	  } // Statement did not already exist
	} // for all possible USE/INCLUDE blocks in mono area (usually 1)

} // End do_mono

#if !MOVEM
/****************************** DO_EMS *************************************/
// Ask if they want EMS services.  The default is Yes if they already had
// it enabled, No if not.
void do_ems (void)
{
 DIALOGPARM parm;
#define NYESNOBUTTONS	(sizeof(YesNoButtons)/sizeof(YesNoButtons[0]))
 BUTTON FlipButtons[NYESNOBUTTONS];
 int DisabledInPro;
 char *dlgtext;
 int helpnum, i;

 parm = NormalDialog;

 for (i=0; i<NYESNOBUTTONS; i++) FlipButtons[i] = YesNoButtons[i];
 parm.pButton = FlipButtons;
 parm.nButtons = NYESNOBUTTONS;

 // If MAX is already installed but not in the system, check the
 // profile for EMS=0.	If not found, assume they want EMS.
 DisabledInPro = (pro_fnd && find_pro ("EMS", "0", NULL));
 if (EMSType == 0 && !DisabledInPro) {
   EMSType = find_pro ("NOFRAME", NULL, NULL) ? 1 : 0;
 } // Max is installed but not active

 if (EMSType == 0) { // No EMS active; make the default "No"
	FlipButtons [0].defButton = FALSE;	/* Change from "Yes" */
	FlipButtons [1].defButton = TRUE;	/* Default to "No" */
	dlgtext = MsgDisableEMS;
	helpnum = HELP_EMSOFF;
 } // No EMS
 else {
	dlgtext = MsgEnableEMS;
	helpnum = HELP_EMSON;
 } // EMS active

 if (dialog(&parm,
		TitleAction,
		dlgtext,
		helpnum,
		NULL,
		0) == RESP_YES) {
	if (DisabledInPro) {
	  remove_pro ("EMS", "0", NULL);
	  add2maxpro (ActiveOwner, ProIgnoreFlex);
	} // EMS services were previously disabled in the MAX profile
 } // Enable EMS services
 else if (!DisabledInPro) {
	add2maxpro (ActiveOwner, ProNoEMS);
	remove_pro ("FRAME", NULL, NULL);
 } // Disable EMS services

} // do_ems ()
#endif // not MOVEM

//***************************** GET_BOOTDSK ************************************
// Get apparent boot drive.  Note that we can automatically detect
// swapped drive environments like STACKER in check_swap(), which
// is called after we have (possibly) parsed CONFIG.SYS to get the
// apparent MAX directory.
// We no longer ask the user for confirmation of the boot drive unless
// the one we detected (or specified by BOOTDRIVE=) is invalid.
void	 get_bootdsk ( void )
{
	KEYCODE key;
	DIALOGPARM parm;
	DIALOGEDIT edit;
	char drvedit[2];
	int drivebad;

	do_intmsg(MsgGetBoot);

	parm = NormalDialog;
	parm.editShadow = SHADOW_NONE;

	edit = DriveEdit;
	edit.editText = drvedit;
	edit.editLen = 1;

	for (drivebad = 0;;) {
		drvedit[0] = boot_drive;
		drvedit[1] = '\0';

		if (drivebad) {
			key = dialog(&parm,
				TitleAction,
				MsgBootDisk,
				HELP_BOOTDSK,
				&edit,
				1);

			if (key == KEY_ENTER) {
				boot_drive = drvedit[0];
			}
		} // Drive letter was bad

		// We depend on boot_drive being uppercase in various places
		boot_drive = (char) toupper (boot_drive);
		if (chdrive(boot_drive)) {
			char temp[40];

			sprintf(temp,"%c:.",boot_drive);
			if (chdir(temp) == 0) {
				sprintf(temp,"%c:\\",boot_drive);
				truename(temp);
				boot_drive = temp[0];

				// Same drive as update disk?
				// make sure the boot floppy is in.
				if (boot_drive == *source_drive &&
					!is_fixed (*source_drive)) {
					while (!access ( OEM_CHKFILE, 0 )) {
						do_error(MsgInsertBoot,0,TRUE);
					}
				}
				break;
			}
		} // chdrive() was successful
		do_error(MsgBadDrive,0,FALSE);
		drivebad = 1;
	}
} // End get_bootdsk

//******************************** DO_LOGO *************************************
void	 do_logo (int doit)
{
	BOOL abort;
	int badspawn;

#ifndef OS2_VERSION
	badspawn = showLogo(doit,"Q",MsgLogoText,NULL,paintback);
#endif

	disable23();
	/* Inside windows? */
	if (win_version() != 0) {
		/* Naughty, naughty.... */
		do_error(MsgFromWin,0,FALSE);
		abort = TRUE;
	}
	else {
		abort = pressAnyKey(INPUT_WAIT);
	}
	enable23();

#ifndef OS2_VERSION
	if (!badspawn) showLogo(-1,"Q",NULL,NULL,paintback);
#endif
	if (abort) return_to_dos(0);
} // End do_logo


//***************************** DO_CPYRGHT *************************************
void	 do_cpyrght ( void )
{
	dialog(&NormalDialog,
		TitleCopyright,
		MsgCopyright,
		HELP_CPYRGHT,
		NULL,
		0);
} // End do_cpyrght


//***************************** GET_SRCDRVE ************************************
void	 get_srcdrve ( void )
{
	KEYCODE key;
	DIALOGPARM parm;
	DIALOGEDIT edit;

	parm = NormalDialog;
	parm.editShadow = SHADOW_NONE;

	edit = PathEdit;
	edit.editText = source_subdir;
	edit.editLen = 79;
	for (;;) {
		key = dialog(&parm,
			TitleAction,
			MsgSrcDrv,
			HELP_SRCDRV,
			&edit,
			1);

		if (key == KEY_ENTER) {
		  source_drive[0] = source_subdir[0];
		} // User pressed OK button
		if ( check_source (OEM_CHKFILE) ) break;
		do_error(MsgSrcWarn,0,FALSE);
	}
} // End get_srcdrve

//***************************** GET_SRCDRVE2 ***********************************
void	 get_srcdrve2 ( char *msg, int help, BOOL esc, int num )
{
	KEYCODE key;
	DIALOGPARM parm;
	DIALOGEDIT edit;

	parm = NormLargeDialog;
	parm.editShadow = SHADOW_NONE;

	edit = Path2Edit;
	edit.editText = source_subdir;
	edit.editLen = 79;
	if (!esc) disableButton(KEY_ESCAPE,TRUE);
	for (;;) {
		key = dialog(&parm,
			TitleAction,
			msg,
			help,
			&edit,
			1);

		if (key == KEY_ENTER) {
		  source_drive[0] = source_subdir[0];
		  do_backslash(source_subdir);	// In case new path entered
		} // User pressed OK button
		if ( check_source (archive (num) ) ) break;
		do_error(MsgSrcWarn,0,FALSE);
	}
	if (!esc) disableButton(KEY_ESCAPE,FALSE);
} // End get_srcdrve2

//*************************** GET_UPDATEDIR ************************************
void	 get_updatedir ( void )
{
	DIALOGEDIT edit;
	char temp[80];

	edit = PathEdit;
	edit.editText = temp;
	edit.editLen = sizeof(temp)-1;
	for (;;) {
		strcpy(temp,update_subdir);
		dialog(&NormalDialog,
			TitleFileDir,
			MsgUpdateDir,
			HELP_UPDATEDIR,
			&edit,
			1);

		if ( trim(temp) < 1) {
			do_error(MsgBlankWarn,0,FALSE);
			continue;
		} // End IF

		strcpy(update_subdir,temp);
		break;
	}
} // End get_updatedir

//***************************** DETERMINE_MAXDRIVE ***************************
/***
 * Figure out the actual drive letter where MAX is installed:
 *
 *		IF not INSTALL run from a floppy,
 *		THEN BEGIN
 *			IF argv[0] drive != destdrive,
 *			THEN maxdrive = argv[0] drive
 *			ELSE maxdrive = destdrive
 *			ENDIF
 *		     END
 *		ELSE
 *			IF destdrive NOT in CONFIG.SYS,
 *			THEN maxdrive = destdrive
 *			ELSE	BEGIN
 *				    newdrive = 0
 *				    FOR drive = destdrive+1 to Z
 *					IF drive has the MAX directory
 *					with 386MAX.COM, newdrive = drive
 *				    END FOR
 *				    IF newdrive != 0
 *				    THEN maxdrive = newdrive
 *				    ELSE maxdrive = destdrive
 *				    ENDIF
 *				END
 *			ENDIF
 *		ENDIF
 *
***/
void	determine_maxdrive (char *maxdrive)
{
 char argv0[2];
 char drive, newdrive, stackdrive;
 char temp[128];

 if (ReInstall) {
	get_exepath (argv0, sizeof (argv0));
	argv0[0] = (char) toupper (argv0[0]);
	if (argv0[0] != *maxdrive)	*maxdrive = argv0[0];
 } // ReInstall
 else {
	// We don't get called if !mgr_fnd
	// Set up the pathname to look for
	sprintf (temp, "%s%s", dest_subdir,
#if MOVEM
			"CHIPSET.COM"
#else
			"386UTIL.COM"
#endif
				);
	// Fail all critical errors
	set24_resp (RESP_FAIL);
	for (	stackdrive = newdrive = '\0',
			drive = (char) (toupper (*maxdrive) + 1);
		drive <= 'Z';
		drive++ ) {
		// First see if we have a directory with 386UTIL.COM in it...
		// (or CHIPSET.COM if a Move'EM installation)
		temp[0] = drive;
		if (!access (temp, 0)) {
			newdrive = drive;
			if (stacked_drive (drive-'A'))  stackdrive = drive;
		} // Directory found
	} // for ()
	// Resume normal critical error handling
	set24_resp (0);

	// Use the last stacked drive with a parallel directory, otherwise
	// use the last drive with a parallel directory.
	if (stackdrive) 	*maxdrive = stackdrive;
	else if (newdrive)	*maxdrive = newdrive;

 } // not ReInstall

} // determine_maxdrive ()

#ifdef STACKER
extern DWORD CopyMax2Size;
/****************************** GDD_SUB ***********************************/
// Subfunction to get_destdrv () - check drive swapping parameters
void	 gdd_sub (char maxdrive)
{
 DWORD AddSpace;

	if (SwappedDrive > 0) {
		get_swapparms ( boot_drive,
				maxdrive,
				dest_subdir,
				MsgBootSwap,
				HELP_SWAPDRIVE);
	}

	// If user didn't manually request swapped drive support,
	// see if we can detect it.
	if (SwappedDrive == -1) check_swap (boot_drive, maxdrive);

	// Make sure we have a valid setup
	if (SwappedDrive > 0 && !CopyMax1) SwappedDrive = 0;

	// Determine alternate path for split installation
	if (SwappedDrive > 0) {
		AltDir = str_mem (dest_subdir);

		// CopyMax1 always exists.  If we need to do CopyMax2,
		// we can use AltDir for a doormat.  Consequently, any
		// use of AltDir should first set up the correct drive:
		// *AltDir = CopyMaxn;	// Setup drive
		*AltDir = CopyMax1;	// Set initial value

		// Check for sufficient space on CopyMax1 (and possibly
		// CopyMax2).  If either drive doesn't have enough room
		// for the bare essentials, crap out.
		// We expect the following space (assuming a 4K blocking
		// factor):
		// 386LOAD.CFG	    4K
		// 386LOAD.SYS	   16K
		// 386MAX.PRO	    8K
		// 386MAX.SYS	  192K
		// 386MAX.VXD	   52K
		// EXTRADOS.EXE    16K
		// EXTRADOS.PRO     4K
		// QCACHE.WIN	    4K
		// XLAT.COM	   12K
		// 386SWAT.LOD	  152K
		// 386SWAT.PRO	    4K
		// CONFIG.SYS	   16K
		// AUTOEXEC.BAT    20K
		// Total	  500K
		// Fudge factor   100K
#define FUDGEFACT (100 * 1024L)
#define NEEDSWAP (500 * 1024L) + FUDGEFACT
		AddSpace = check_altpath (FALSE); // Determine bytes
						// already in use on dest drive
		if (AddSpace < NEEDSWAP)	AddSpace = NEEDSWAP - AddSpace;
		else				AddSpace = FUDGEFACT;

		check_freespace (toupper (CopyMax1)-'@', AddSpace, TRUE);
		if (CopyMax2) {
			if (CopyMax2Size < NEEDSWAP)	AddSpace = NEEDSWAP - CopyMax2Size;
			else				AddSpace = FUDGEFACT;
			check_freespace (toupper (CopyMax2)-'@', AddSpace, TRUE);
		} // CopyMax2

	} // SwappedDrive > 0

} // gdd_sub ()
#endif // ifdef STACKER

//***************************** GET_DESTDRV ************************************
void	 get_destdrv ( void )
{
	DIALOGEDIT edit;
	char temp[80];
	char maxdrive;
	BOOL Round2 = FALSE;

	do_intmsg(MsgGetDest);

	*temp = '\0';

	edit = PathEdit;
	edit.editText = temp;
	edit.editLen = sizeof(temp)-1;
	if (mgr_fnd || ReInstall) {
		strcpy (dest_subdir, update_subdir);
	} // Found MAX line in CONFIG.SYS or install/r
	else {

		save_dcvid ();
		start_twirly ();

		// Try to find a non-network drive that has at least 3MB.
		maxdrive = (char) toupper (boot_drive); // Where to start looking
		// Fail all critical errors
		set24_resp (RESP_FAIL);
		while (maxdrive <= 'Z') {
		    if (freeMB (maxdrive) >= 3) {
			adjust_pfne (dest_subdir, maxdrive, ADJ_DRIVE);
			break;
		    }
		    maxdrive++;
		} // Searching for a drive with sufficient space

		// Resume normal critical error handling
		set24_resp (0);

		end_twirly ();
		rest_dcvid ();

	} // Fresh install

	for (;;) {
		if (!mgr_fnd || Round2) {

		 strcpy(temp,dest_subdir);
		 dialog(&NormalDialog,
			TitleFileDir,
			MsgDestDir,
			HELP_DESTDRV,
			&edit,
			1);

		 if ( trim(temp) < 1) {
			do_error(MsgBlankWarn,0,FALSE);
			continue;
		 } // End IF

		 strcpy(dest_subdir,temp);

		} // !mgr_fnd

		if (!ReInstall)
		 StorageSize =
			do_extract (0, "",  // Determine space in bytes
#if MOVEM
			  MOV_ARCATTR
#else
			  MAX_ARCATTR
#endif
					, dest_subdir);

		if ( !check_dest (OEM_CHKFILE, mgr_fnd) ) {
			/* We made it... */
			break;
		}
		Round2 = TRUE;		// Display path on next round
	}

	// If the user didn't specify a drive for the destination
	// path, assume the boot drive letter.
	adjust_pfne (dest_subdir, boot_drive, ADJ_PATH);

	// Make sure we allocate space for trailing backslash
	do_backslash (dest_subdir);

	// Determine the drive MAX is in.  CONFIG.SYS may be lying...
	maxdrive = dest_subdir[0];
	if (mgr_fnd)	determine_maxdrive (&maxdrive);

#ifdef STACKER
	// If swapped drive support was requested manually, interrogate
	// the user...
	gdd_sub (maxdrive);
#endif // ifdef STACKER

} // End get_destdrv

/****************************** STRCMPRSS **********************************/
// Squeeze all spaces out of a string
void strcmprss (char *psz)
{
  char *pszTail;

  for (pszTail = psz; ; psz++) {
    if (*psz != ' ') *pszTail++ = *psz;
    if (!*psz) break;
  } // Not end of string

} // strcmprss()

//***************************** GET_USERINFO ***********************************
void	 get_userinfo ( void )
{
	char name[45];
	char company[45];
	char number[(3+1+4+1+5)+1];
	DIALOGEDIT edits[3];
	WORD PrevDlgFlags;

	do_intmsg(MsgGetReg);

	*name = '\0';
	edits[0] = RegisterEdit;
	edits[0].editText = name;
	edits[0].editLen = sizeof(name)-1;

	*company = '\0';
	edits[1] = CompanyEdit;
	edits[1].editText = company;
	edits[1].editLen = sizeof(company)-1;

	*number = '\0';
	edits[2] = SerialEdit;
	edits[2].editText = number;
	edits[2].editLen = sizeof(number)-1;

	if (ScreenType == SCREEN_MONO) {
		/* ..to cover the []'s */
		edits[2].editWin.ncols += 2;
	}

	// Let 'em press ENTER after all but the last edit field
	// This also tells us to start with the first edit field highlighted
	set_tabconvert (1);

	// Don't advance to next field when they fill it up
	PrevDlgFlags = set_dlgflags (DLGF_NOFILL);

	for (;;) {
		dialog(&NormalDialog,
			TitleAction,
			MsgUserinfo,
			HELP_USERINFO,
			edits,
			sizeof(edits)/sizeof(edits[0]));

		/* Make sure values are null terminated */
		name [sizeof(name)-1] = '\0';
		company [sizeof (company) - 1] = '\0';
		number [sizeof (number) - 1] = '\0';
		strcmprss (number);

		if ( strlen(name) < 1) {
			do_error(MsgBlankWarn,0,FALSE);
			continue;
		} // End IF

		if (decode_serialno ( (unsigned char *) number ) == NULL ||
		      strlen(number) != 12 ||
		      strncmp(number, "0000000000", 10) == 0 ) {
			int badoff, badlen;
			char *psz;

			do_error(MsgBadNumber,0,FALSE);
			set_tabconvert (3); // Start with the third field

			// Find the offending character(s) and highlight 'em
			for (badoff = -1, psz = number; *psz; psz++)
			  if (badoff < 0) {

			    if (!(isspace (*psz) || isdigit (*psz))) {
				badoff = (int) (psz - number);
				badlen = 1;
			     } // Found initial bad character

			  } // Check for bad character
			  else {

			    if (isspace (*psz) || isdigit (*psz))
				break;
			    else
				badlen++;

			  } // Check for end of bad character(s)

			if (badoff >= 0) set_edithigh (badoff, badlen);

			continue;
		} // End IF
		else set_tabconvert (1);

		/* We made it... */
		strcpy(user_name,name);
		strcpy(user_company,company);
		strcpy(user_number,number);

		/* Now give 'em a chance to back out */
		do_textarg (1, name);
		do_textarg (2, company);
		do_textarg (3, number);
		if (do_yesno (MsgConfirm, HELP_USERINFO) == RESP_YES) break;

	} // for ()

	set_dlgflags (PrevDlgFlags);

	// Restore normal edit key handling (ENTER == OK, usually)
	set_tabconvert (0);

} // End get_userinfo

//***************************** DO_SNAPSHOT ***********************************
void  do_snapshot ( void )
{
#if 0	/* This won't work yet 'cause there's no mem available to spawn */
	reset_video();

	/*** done2324(); Called within reset_video() ***/
	if (spawnl(P_WAIT,
		   "SNAPSHOT.EXE",
		   "SNAPSHOT.EXE",
		   "SNAPSHOT.INS",
		   "System configuration at install time") == -1) {
		error(-1,"Unable to execute SNAPSHOT program\n");
	}
	inst2324();

	set_video();
#endif
}

//****************************** DO_TEXTARG ***********************************
void do_textarg(int num,char *arg)
{
	if (num > 0) {
		InstallArgTo[num-1] = arg;
	}
}

#ifdef HEAPDBG
/******************************* HEAPDUMP *********************************/
// Dumps all allocated heap entries to specified file.
void	heapdump (char *fname)
{
  FILE *out;
  struct _heapinfo heapi;
  int i;
  char text[17];
  char *tmp;
  DWORD totfree;
  WORD maxsize;
  char *maxptr;

  out = cfopen (fname, "wt", 1);
  heapi._pentry = NULL;
  totfree = 0L;
  maxsize = 0;
  maxptr = NULL;
  while (_heapwalk (&heapi) == _HEAPOK) {
	if (heapi._useflag == _USEDENTRY) {
		cfprintf (out, "%Fp %5u:", heapi._pentry, heapi._size);
		tmp = (char *) heapi._pentry;
		for (i=0; i < min (16, heapi._size); i++) {
		  cfprintf (out, "%02x ", *tmp);
		  if (*tmp > ' ' && *tmp < 0x80) text[i] = *tmp;
		  else text[i] = '.';
		  tmp++;
		} // dump first 16 characters
		for ( ; i < 16; i++) {
		  cfprintf (out, "   ");
		  text[i] = '\0';
		}
		text[16] = '\0';
		cfprintf (out, "%s\n", text);
	} // Still in use
	else {
		totfree += (DWORD) heapi._size;
		if (heapi._size > maxsize) {
		  maxsize = heapi._size;
		  maxptr = (char *) heapi._pentry;
		} // Largest so far
	} // Free
  } // end while ()
  cfprintf (out, "%lu bytes in free entries; largest = %u (%Fp)\n",
	totfree, maxsize, maxptr);
  fclose (out);

} // heapdump
#endif // ifdef HEAPDBG

/************************** VIEW_TEXTFILE ***********************************/
void	 view_textfile ( char *flenme, BOOL addpath)
{
	char work[80];
#ifdef HEAPDBG
	char heapdumpname[15];
	static int extnum = 0;
#endif

	dropButton (FileChgButtons, NUMFILECHGBUTTONS);

	*work = '\0';
	if (addpath) {
		do_backslash ( dest_subdir );
		strcpy(work,dest_subdir);
	}

#ifdef HEAPDBG
	sprintf (heapdumpname, "PREEDIT.%03u", extnum);
	heapdump (heapdumpname);
#endif

	strcat(work,flenme);
	fileEdit( HELPBROWSE, 0, work, TRUE, NULL );

	/*	Should be active per stan disableButton( KEY_F2, TRUE ); */

	/* Slam the F2 key (again) */
	disableButton(KEY_F2,TRUE);

#ifdef HEAPDBG
	sprintf (heapdumpname, "POSTEDIT.%03u", extnum);
	heapdump (heapdumpname);
	extnum++;
#endif

	addButton (FileChgButtons, NUMFILECHGBUTTONS, NULL);

	disableButton (KEY_ESCAPE, FALSE);
	disableButton (KEY_ENTER, FALSE);

	showAllButtons ();

} // End view_textfile


//****************************** CLEARSCREEN ***********************************
void	 clearscreen ( void )
{
	WINDESC win;

	SETWINDOW(&win,0,0,ScreenSize.row,ScreenSize.col);

	wput_sca(&win,0x0720);
	move_cursor(0,0);
} // End clearscreen


//**************************** DONT_TAKE_NO ************************************
// Used by do_maximize() and do_qcache().  Creates a `warning' type box and
// a message to put in it.  Returns key value.
unsigned short dont_take_no(char *message,int helpnum)
{
	KEYCODE key;

	disableButton(KEY_ESCAPE,TRUE);
	key = dialog(&WarningDialog,
		TitleWarning,
		message,
		helpnum,
		NULL,
		0);
	disableButton(KEY_ESCAPE,FALSE);
	return key;
}

/*********************************** DO_ERROR *******************************/
void	 do_error ( char *msg, int help, BOOL esc )
{
	if (!esc) disableButton(KEY_ESCAPE,TRUE);
	dialog(&ErrorDialog,
		TitleError,
		msg,
		help,
		NULL,
		0);
	if (!esc) disableButton(KEY_ESCAPE,FALSE);
} // End do_error


/*********************************** DO_BADUPD ******************************/
// Similar to error, but with three buttons:  "Continue", "Back, and "Exit"
// Returns KEY_ALTC   for "Continue",
//	   KEY_ALTB   for "Back",
//	   KEY_ESCAPE for "Exit"
KEYCODE do_badupd ( char *msg, int help)
{
	return(dialog(&BadUpdDialog,
		      TitleError,
		      msg,
		      help,
		      NULL,
		      0));
} // End do_badupd


/*********************************** DO_ADVICE *******************************/
// Similar to do_error, but with "Action" instead of "Error" and with
// normal colors.
void	 do_advice ( char *msg, int help, BOOL esc )
{
	if (!esc) disableButton(KEY_ESCAPE,TRUE);
	dialog(&NormalDialog,
		TitleAction,
		msg,
		help,
		NULL,
		0);
	if (!esc) disableButton(KEY_ESCAPE,FALSE);
} // End do_advice

/*********************************** DO_WARNING *******************************/
// Display warning message.  Return TRUE if Y pressed, otherwise FALSE.
int  do_warning(char *msg,int help)
{
	KEYCODE key;

	disableButton(KEY_ESCAPE,TRUE);
	key = dialog(&WarningDialog,
		TitleWarning,
		msg,
		0,
		NULL,
		0);

	disableButton(KEY_ESCAPE,FALSE);
	if (toupper(key) == RESP_YES) return TRUE;
	return FALSE;
} // End do_warning


/**************************** ask_3way *********************************/
// If MultiBoot, use a 3-button dialog.
// Otherwise, use do_yesno.
// Return the key pressed.
KEYCODE ask_3way (char *dialogtext, int helpnum, int mbhelpnum)
{
 DIALOGPARM parm;

 if (MultiBoot) {
	parm = NormalDialog;

	parm.pButton = MBButtons;
	parm.nButtons = sizeof(MBButtons)/sizeof(MBButtons[0]);
	return (
	  dialog(&parm,
		TitleAction,
		dialogtext,
		mbhelpnum,
		NULL,
		0)
	);

 } // Multiboot active
 else return (do_yesno (dialogtext, helpnum));

} // ask_3way ()

#if QCACHE_TEST
//*************************** do_qcache **********************************
// If dcfound, SMARTDRV exists... tell user we want to replace it w/ QCACHE
// If 0, no disk cache was detected.  Ask'em if we should put in 386Cache.
void do_qcache (int dcfound)
{
	KEYCODE key;
	int res;

	// Don't ask if it's there but not active.
	if (autox_fnd) {
	  do_intmsg (MsgScanningFile, StartupBat);
	  reset_batch (BT_QCACHE);
	  res = process_stream (StartupBat, "nul", find_batline);
	  clear_batch ();
	  if (res) return;
	} // AUTOEXEC.BAT exists

	key = ask_3way (dcfound ? MsgSmartDrv : MsgNoCache, HELP_SMARTDRV,
			HELP_SMARTDRVMB);

	if ( key == RESP_YES || key == RESP_THIS ) {
		install_qcache (dcfound, key);
	}
	else
	 if (dcfound) {
		key = dont_take_no(MsgNoSmartDrv,HELP_NOSMARTDRV);
		if ( key == RESP_YES ) {
			install_qcache (dcfound, key);
		}
	 } // Give them another chance if the alternative is *GASP* Smartdrv
} // do_qcache ()
#endif

/*************************** do_qmt ************************************/
// Ask if they want QMT to run every time they boot.
void do_qmt (void)
{
 char buff[20];
 extern WORD _far pascal MULTIME (WORD count);
 DWORD SizeK;
 DWORD Clocks1000, ClockDiv;
 WORD divisor;
 KEYCODE key;
 int sx = 0, is486 = 0, res;

 if (autox_fnd) {
	reset_batch (BT_QMT);
	do_intmsg (MsgScanningFile, StartupBat);
	res = process_stream (get_inname (get_filedelta (StartupBat)),
			"nul", find_batline);
	clear_batch ();
	if (res) return;
 } // AUTOEXEC.BAT exists

 // Estimate time needed to run QMT QUICK=1.  Use CMOS extended memory
 // size + 512K conventional memory, and calculate approximate CPU
 // speed.
 SizeK = ((DWORD) extcmos ()) + 512L;
 // Speed in mhz == (1.193180 * (MULCLKS*1000 + overhead)) / multime(1000)
 Clocks1000 = MULTIME (1000);
 // Get MULCLKS*1000 + overhead
 switch (cpu.cpu_type) {
  case CPU_80386SX:
	sx = 1;
  case CPU_80386:
	ClockDiv = 25*1000 + 15 + 14*1000/100;
	break;

  case CPU_80486:
  case CPU_80486SX:
	is486 = 1;
	ClockDiv = 26*1000 + 15 + 14*1000/100;
	break;

  case CPU_PENTIUM:
  default:
	ClockDiv = 11*1000 + 15 + 10*1000/100;
 }
 ClockDiv *= 59659L; // TIMER2*50000
 ClockDiv /= Clocks1000; // Speed in mhz * 50000
 ClockDiv = (ClockDiv + 49999L) / 50000L; // Speed in Mhz

 // Determine 1024 / (seconds / MB)
 if	 (ClockDiv < 17L) {
    if (sx)	divisor = 68;	// 15.17: 386SX 16 Mhz or less
    else	divisor = 75;	// 13.57: 386DX 16
 }
 else if (ClockDiv < 22L) {
    if (sx)	divisor = 106;	// 9.63: SX 20 Mhz
    else	divisor = 194;	// 5.29: DX 20
 }
 else if (ClockDiv < 27L)	divisor = 247;	// 4.15: 25 Mhz
 else if (ClockDiv < 35L) {
    if (sx)		divisor = 178;	// 5.75: SX 33 Mhz
    else if (!is486)	divisor = 349;	// 2.93: 386DX
    else		divisor = 580;	// 1.77: 486
 }
 else if (ClockDiv < 54L)	divisor = 706;	// 1.45: 50 Mhz
 else {
    if (cpu.cpu_type != CPU_PENTIUM) divisor = 737; // 1.39: 486 60 Mhz and up
    else	divisor = 1296; // Pentium
 }

 sprintf (buff, "%lu", SizeK / divisor);
 do_textarg (1, buff);
 key = do_yesno (MsgQMT, HELP_QMT);
 if (key == RESP_YES) install_qmt (key);

} // do_qmt ()

//*************************** do_doshelp **********************************
// DOS 5.00 only- insert text in help file
// Search path for DOSHELP.HLP- open it and search for 386MAX.
// If found, don't ask again.
void do_doshelp (void)
{
	DIALOGEDIT edit;
	char temp[80];
	int helplines;
	int helpfound;

	edit = PathEdit;
	edit.editText = temp;
	edit.editLen = sizeof(temp)-1;

	// If we can't open DOSHELP.ADD, exit quietly
	if (!(helplines = read_doshelp ()))
	 return;

	// Check the path for DOSHELP.HLP.
	_searchenv ("DOSHELP.HLP", "PATH", temp);
	helpfound = (temp[0] && !access (temp, 06));

	// If found, check to see if our help is already there.
	if (helpfound && !insert_help(temp, DosHelpText, helplines, 0)) return;

	if (do_yesno (MsgDosHelp, 0) == RESP_NO)
	 return;

	if (helpfound) goto ADD_DOS_HELP;

	temp[0] = boot_drive;
	strcpy(temp+1,":\\DOS");
	for (;;) {
		int nc;

		dialog(&NormalDialog,
			TitleFileDir,
			MsgDosPath,
			HELP_DOSDIR,
			&edit,
			1);

		if ( (nc = trim(temp)) < 1) {
			do_error(MsgBlankWarn,0,FALSE);
			continue;
		} // End IF

		if (temp[nc-1] != '\\') strcat(temp,"\\");
		strcat(temp,"DOSHELP.HLP");

		if (access(temp,0) != 0) {
			KEYCODE key;

			temp[nc] = '\0';
			do_textarg(1,temp);
			key = dont_take_no(MsgBadDosDir,0);
			if (key == RESP_YES) continue;
		}
		else {
ADD_DOS_HELP:
			do_intmsg(MsgWrtDosHelp);
			insert_help(temp, DosHelpText, helplines, 1);
		}
		break;
	}
}

/***************************** DO_REFDSK **********************************/

KEYCODE do_refdsk (void)
{
	int nc;
	KEYCODE key;
	DIALOGPARM parm;
	DIALOGEDIT edit;
	char line[MAXFILELENGTH];
	char temp[MAXFILELENGTH];

	/* Set directory for ADF files (use install destination */
	/* rather than default argv[0] path) */
	sprintf (temp, "%sADF", dest_subdir);
	mkdir (temp);
	do_backslash (temp);
	adf_dir (temp);

	/* Do this to get the ADF directory path; if directory is already */
	/* in sync with hardware, skip this step */
	if (check_adf_files(temp,sizeof(temp)))
		return (KEY_ESCAPE);

	parm = NormalDialog;
	parm.width = LARGE_DIALOG;

	parm.pButton = RefDiskButtons;
	parm.nButtons = sizeof(RefDiskButtons)/sizeof(RefDiskButtons[0]);

	edit = PathEdit;
	edit.editWin.ncols = LARGE_DIALOG - 5;
	edit.editText = line;
	edit.editLen = sizeof(line);

	strcpy(line,"A:\\");

DOREFDSK:
	dialog_callback(0,NULL);
	saveButtons();	/* ..so that we can override the line 25 Esc button */
	key = dialog(&parm,
		TitleAction,
		MsgRefDsk,
		HELP_REFDSK,
		&edit,
		1);
	restoreButtons();
	dialog_callback(KEY_ESCAPE,chkabort);

	switch (key) {
	case KEY_ENTER:
		nc = strlen(line);
		if (nc > 0) {
			if (line[nc-1] != '\\') {
				strcat(line,"\\");
			}
			do_intmsg(MsgCopyADF);
			if (save_adf_files(line,temp)) {
				line[sizeof(line)-1] = '\0';
				strncpy(line,temp,sizeof(line)-1);
				goto bottom;
			}
			else	goto DOREFDSK;
		}

	case KEY_ESCAPE:
		goto bottom;

	default:
		goto DOREFDSK;
	} /* End SWITCH */
bottom:
	return key;

} /* End DO_REFDSK */

//****************************** SET_VIDEO *************************************
void	 set_video ( BOOL paint )
{
	init_input(NULL);

	hide_cursor();
	set_cursor( thin_cursor() );

	if (paint) paintback();

	if( startHelp(HelpFullName, HELPCOUNT) ) return_to_dos(0);

	if (QuickHelpNum && !RestoreFile) showQuickHelp(QuickHelpNum);

	dialog_callback(KEY_ESCAPE,chkabort);
	VideoReset = FALSE;

} // End set_video


//****************************** PAINTBACK *************************************
void	 paintback ( void )
{
	paintBackgroundScreen();
	do_prodname();
	showAllButtons();
	intmsg_restore();
} // End paintback

//****************************** RESET_VIDEO ***********************************
void	 reset_video ( void )
{
	 intmsg_save();

	 endHelp();
	 end_input();
	 show_cursor();
	 set_cursor(thin_cursor());
	 clearscreen ();
	 done2324();
	 end_twirly ();
	 VideoReset = TRUE;
	 closehigh ();
} // End reset_video

//****************************** DO_PRODNAME *************************************
void	 do_prodname ( void )
{
	WINDESC win;

	SETWINDOW(&win,0,0,1,0);
	win.ncols = strlen(ProgramName);
	win.col = ScreenSize.col - win.ncols;
	wput_csa( &win, ProgramName, DataColor );
	halfShadow( &win );
}
