/*' $Header:   P:/PVCS/MAX/INSTALL/INSTALL.C_V   1.7   02 Jan 1996 17:45:34   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INSTALL.C								      *
 *									      *
 * Main source module for INSTALL.EXE					      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <graph.h>
#include <conio.h>
#include <ctype.h>
#include <process.h>
#include <io.h>

#include "bioscrc.h"
#include "compile.h"
#include "common.h"
#include "commfunc.h"
#include "dcache.h"
#include "defn.h"
#include "extsize.h"
#include "intmsg.h"
#include "libcolor.h"
#include "myalloc.h"
#include "qprint.h"
#include "qhelp.h"
#ifdef STACKER
#include "stacker.h"
#endif
#include "ui.h"

#define OWNER
#define MAIN_C
#include "instext.h"
#undef MAIN_C
#undef OWNER

#ifndef PROTO
#include "install.pro"
#include "drve.pro"
#include "files.pro"
#include "misc.pro"
#include "scrn.pro"
#include "security.pro"
#include "pd_sub.pro"
#include "mxz_adf.pro"
#endif

extern WORD SVENDOR, VMODEL;

#pragma optimize("leg",off)

void main (int argc, char *argv [])
{
	int err;
	int config_act;
	char szTemp[128];

	startup_init ( argc, argv );	// Initialize some globals:
	// boot_drive
	// saved_drive
	// saved_path
	// ScreenSet, ScreenType
	// DiskCacheTest
	// SwappedDrive
	// AllBCFs
	// NewMachine
	// PatchPrep
	// ReInstall
	// VGAWARN
	// GraphicsLogo
	// SnowControl
	// RestoreFile
	// RecallString
	// AdvancedOpts
	// source_subdir

// Install our Ctrl-Break (INT 23h) and Critical Error (INT 24h) handlers
// From this point on, exits MUST call abortprep ()
	inst2324 ();
	enable23 ();

// Attempt to link in high DOS
	openhigh ();

	set_exename( argv[0], OEM_INST );
	// Sets ExeName

	MaxInst = qmaxpres (&POVR_MAC, NULL);

	if (ReInstall) { // Get keywords from INSTALL.CFG file

#if REDUIT
		if (AllBCFs) {
		  // /M can only be run from the distribution diskette
		  printf (MsgNeedDisk);
		  goto REINSTALL_INVAL;
		} // /M specified
#endif

		// Ensure we're not trying to run install/r
		// from a floppy with 386max.1 on it
		if (check_source (OEM_CHKFILE)) {
			printf (MsgNoReinstall);
#if REDUIT
REINSTALL_INVAL:
#endif
			done2324 ();
			exit (-1);
		} // Tried to run INSTALL/r from distribution disk

	} // ReInstall

	if (RestoreFile) {
	  // We'll run STRIPMGR /e after extracting files.  This should
	  // give us a list of changes.  We're primarily concerned with
	  // CONFIG.SYS so we can let MBPARSE relocate the lines for us.
	  // On return, we can parse CONFIG.SYS again.
	  // Before chaining to STRIPMGR, we need to call endHelp()
	  // (close INSTALL.HLP), end_input() (restore Int 9) and
	  // done2324() (Ints 23h and 24h).  We don't want to call
	  // abortprep(), reset_video(), etc.
	  // restore_path() is a useful precaution in case we don't
	  // make it back from STRIPMGR.
	  // On return, we need to parse the RestoreFile.  This will set
	  // dest_subdir (among other things).
	  parse_restore ();
	  read_cfg (FALSE);
	  // Set cfg list, SnowControl, GraphicsLogo, boot_drive,
	  // ScreenSet, ScreenType
	  ReInstall = TRUE;
	} // Returning from STRIPMGR
	else {
	  read_cfg (TRUE);	// If INSTALL.CFG is on the distribution disk,
				// read it.
	  strcpy(HelpFullName,DOSNAME".HLP");

	} // Not returning from STRIPMGR

	// Set retrace check mode (default=none) and get screen data
	initializeScreenInfo (SnowControl);

	// Set colors according to ScreenType
	setColors();

	/* Initialize the video and help systems or die trying */
	set_video(FALSE);

	setHelpArgs(InstallArgCnt,InstallArgFrom,InstallArgTo);

	if (!RestoreFile)
	{
		do_logo (GraphicsLogo); // Display Qualitas and product name
		if (argc <= 1)		// If there are no arguments, ...
		    do_windows ();	// See if they want Windows install
	}

#if !UPDATE
	QuickHelpNum = HELP_QI_INTRO;
#else
	QuickHelpNum = HELP_QU_INTRO;
#endif
	if (!RestoreFile) showQuickHelp(QuickHelpNum);

	/* Set up intermediate message window */
	intmsg_setup(-1);

	strcpy(MainButtons[0].text,MsgAbortEsc);
	MainButtons[0].colorStart = ABORTESCSTART;
	addButton(MainButtons,sizeof(MainButtons)/sizeof(MainButtons[0]),NULL);
	showAllButtons();

	/* Start with F2 off, turn it on only when needed */
	disableButton(KEY_F2,TRUE);

	/*	Set some defaults for things in quilib */
	 /*  Setup the header for printing */
	PrintProgramName = PrintName;
	/*	Set where help is to start printing all */
	helpSystem = HELP_ABRT;

	 strcpy( PrintFile, DOSNAME ".PRN" );

	if (!check_systype()) goto done;	// Check on system type
	// Sets ProductSet, DoMoveEm, EMSType - if it's Move'EM, we're
	// screwed anyway, and we should re-check EMS.

#if MOVEM
	/* A few things need to be fixed up if we're installing MOVE'EM */
	movem_init();
#endif // IF MOVEM

	if (!ReInstall && !check_source (OEM_CHKFILE))
		get_srcdrve (); 	// Must find the first file; if we have
					// to bail out in calc_crcinfo(), we
					// may need to extract stripmgr.exe

#if REDUIT
	// Sets bcfsys, mcasys, and BIOSCRC
	if (!RestoreFile)
		calc_crcinfo ();	// Get CRC now so we can fail without
					// unzipping everything first...
#endif

	// Changes boot_drive only if it's bad
	get_bootdsk (); 		// Find the boot drive

	// Modifies StartupBat, sets con_dpfne, MultiBoot, autox_fnd,
	// and creates CfgSys chain.
	parse_config ();		// Parse CONFIG.SYS

	if ( !security_crc ) {
		get_userinfo ();	// Get the name and serial number
		do_intmsg(MsgWrtReg);
		do_encryptsrc ();	// Encrypt INSTALL
	}
	else				// Decrypt the serial #
	{
		strncpy (szTemp, security_pattern, sizeof (szTemp)); // Copy to local storage
		decrypt (szTemp, sizeof (szTemp));
		strncpy (user_number, &szTemp[1+sizeof (SERIALNUM_STR)], USER_SERIAL_LEN);
	}

	// After this point fUpdate is valid
	if (user_number[1] == '2')   // Izit an update?
	    fUpdate = YES;
	else
	    fUpdate = NO;

	if (!RestoreFile) {

	  // Sets update_subdir
	  find_update_dest ();		// Look for previously installed files

	  if ( fUpdate ) {
		 do_update ();		// Verify installed files and
					// encrypt UPDATE.EXE
	  }
	  do_cpyrght ();		// Display the Copyright message

	} // Not restoring

	if (RestoreFile) goto Stripmgr_return;

	// Sets dest_subdir and drive swapping parameters
	// Sets dest_drive
	get_destdrv (); 		// Get the destination ( drive/path )
					// and make sure it has enough space
#if REDUIT
// Set up BCF pathname now that we know the destination
	 if (bcfsys) {
		sprintf (bcf_dpfne, "%s@%04X.BCF", dest_subdir, BIOSCRC);
	 } // It's a BCF system
#endif

/*** At this point we may have detected a swapped drive configuration ***/

	 // Check for read-only files
	 err = check_rdonly("?:\\config.sys");
	 err |= check_rdonly(StartupBat);
	 if (err) goto done;

	 if (!ReInstall) {
		disableButton(KEY_F1,TRUE);
		do_intmsg(MsgCopyProg);

		if (toupper(argv[0][0]) == *source_drive) {
		 /* If we were started from the distribution disk, then
		  * copy our .HLP file, and switch to the copy so
		  * the user can change diskettes if desired.
		  */
		 int len;

		 endHelp();
		 copy_one_file(DOSNAME".HLP", OEM_CHKFILE);

		 strcpy(HelpFullName,dest_subdir);
		 len = strlen (HelpFullName);
		 if (HelpFullName[len - 1] != '\\') { // If not trailing slash
			HelpFullName[len++] = '\\';      // add it
		 }
		 strcpy(HelpFullName+len,DOSNAME".HLP");
		 if( startHelp(HelpFullName,HELPCOUNT) ) {
			error(-1,MsgHelpSystemErr);
		 }
		} // argv[0][0] == source drive

		// Always copy INSTALL.EXE, as there may be a newer one
		// in the destination directory.
		copy_one_file( OEM_INST, OEM_CHKFILE );

		// Sets dest_drive
		do_extract (1, "",
#if MOVEM
				MOV_ARCATTR
#else
				MAX_ARCATTR
#endif
						,
				dest_subdir);
					// Unzip the distribution files

		do_delete(DeleteList);
		do_bcfextract();	// Extract BCF file if appropriate
		disableButton(KEY_F1,FALSE);
	 } // !ReInstall

	 do_encryptdest ();		// Encrypt the unzipped files at dest

	// Sets Backup; changes to destination drive/dir
	if (!ReInstall)
		move_old_files ();	// Move out README.EXE, copy QCACHE
					// over existing 386CACHE files

	check_altpath (TRUE);		// Look for files to be copied

	// Sets preinst_bat
	create_preinst_file (); 	// Create preinst.bat

// This is where we can chain to STRIPMGR.  We'll return here after
// parsing CONFIG.SYS armed with the changes suggested by STRIPMGR
// so we'll have everything in the right MultiConfig section.
	exec_stripmgr (dest_subdir);

Stripmgr_return:
	check_systype ();		// Get EMSType

	// Edits CfgSys list, sets MaxConfig if not already,
	// sets dcache, dcache_arg, FreshInstall, pro_dpfne
	edit_config();			// Make changes to CONFIG.SYS in memory
					// and set up 386MAX.PRO in memory

	edit_batfiles();		// Apply STRIPMGR changes (if any)

	check_shell();			// Make sure SHELL= has reload path

	do_snapshot();

#if !MOVEM
	do_ems();			// Ask if they want EMS services
#endif // not MOVEM

	if (Is_MCA ())	{	       // Ask for reference disk on MCA machines
		do_refdsk();
		CheckForBadADFs();	// Check for NFG ADFs
		}

#if !MOVEM

#if REDUIT
	check_bcfsupport ();	// Warn of BCF support problems
#endif

	if ( cnt_mono = scan_mda () )
		do_mono ();	// Recover MDA region?

#endif // not Move'em install

	if (_osmajor == 5) {
		/* Insert text in DOS 5 help file */
		do_doshelp();
	}

#if QCACHE_TEST
	test_qcache ();
#endif // Not Move'em

	// Removed 5/20/93
	// check_maxpath ();		// Add PATH statement to AUTOEXEC
#if !MOVEM
	do_qmt ();			// Add QMT statement to AUTOEXEC
#endif	// not Move'EM

	config_act = do_configsysn ();	// Show changes and let 'em quit
	if (!config_act) {
	  do_dropout ();
	  return_to_dos(0);				// Hello, DOS
	} // did not elect to edit config.sys

	check_altpath (TRUE);		// Look for files to be copied

	do_maximize (); 		// Run MAXIMIZE

done:
	return_to_dos(0);		// Clean up and go home.

} // End MAIN

#pragma optimize ("", on)

//******************************** STARTUP_INIT ********************************
void	 startup_init ( int argc, char *argv[] )
{
	char fdrive[_MAX_DRIVE], fdir[_MAX_DIR],
		fname[_MAX_FNAME], fext[_MAX_EXT];

// We require DOS version 3.0 or later.
	 if ( _osmajor < 3 )
		 error ( -1, MsgBadDosVer);

	 boot_drive = get_bootdrive();

	 save_path ();

	_splitpath (argv[0], fdrive, fdir, fname, fext);
	strcpy (source_subdir, fdrive);
	strcat (source_subdir, fdir);
	do_backslash (source_subdir);

	*source_drive = (char) toupper (fdrive[0]);  // Assume the home drive

	setOptions(argc,argv);

	/* Init global variables */
	ident[0][0].fname = OEM_FileName = MAX_FILENAME;
	ident[1][0].fname = OEM_OldName = MAX_OLDNAME;
	ident[0][1].fname = ident[1][1].fname = MAX_UTILCOM;
	ident[0][2].fname = ident[1][2].fname = MAX_LOADCOM;
	OEM_IdentReqLen = 3;		/* This is the cut off point */
	ident[0][3].fname = ident[1][3].fname = MAX_QSHELL;
	ident[0][4].fname = ident[1][4].fname = MAX_ASQ;
	ident[0][5].fname = ident[1][5].fname = MAX_MAXIMIZE;
	ident[0][6].fname = ident[1][6].fname = QMT_EXE;
	ident[0][7].fname = ident[1][7].fname = OEM_INSTOVL;
	OEM_IdentLen = 8;

	InstallArgTo[5] = OEM_ProdName = MAX_PRODNAME;
	InstallArgTo[6] = OEM_FileName = MAX_FILENAME;
	InstallArgTo[9] = OEM_ProdFile = MAX_PRODFILE;
	InstallArgTo[10]= MAX_PRODDIR;
	OEM_Readme   = MAX_README;
	OEM_LoadBase = MAX_LOADBASE;

	con_dpfne = get_mem (MAXPATH+1);
	pro_dpfne = get_mem (MAXPATH+1);
	preinst_bat = get_mem (MAXPATH+1);
#if REDUIT
	bcf_dpfne = get_mem (MAXPATH+1);
#endif
	groupname = get_mem (MAXPATH+1);

	init_fstat ();

	strcpy(dest_subdir,MAX_INIDIR);
	strcpy(update_subdir,MAX_INIDIR);

	if (VGAWARN < 0 && !RestoreFile) {
		/* VGAWARN not set, set it; MAY CAUSE A MODE RESET */
		printf (GetSVGAMsg);
		VGAWARN = warn_b8 ();
		printf (PostSVGAMsg);
	}

} // End startup_init

//******************************** do_delete *********************************
// Delete selected files in destin subdir after extracting
void do_delete (char *List[])
{
	int i, len;
	char szTemp[_MAX_PATH];

	strcpy (szTemp, dest_subdir);	// Start with destination subdirectory
					// note already do_backslash'ed
	len = strlen (szTemp);		// Save the length for append

	for (i=0 ; List[i]; i++)	// Loop through the list
	{
	     strcpy (&szTemp[len], List[i]); // Append the file name
	     unlink(szTemp);
	} // End FOR

} // End do_delete()

//******************************** setOptions ********************************
/**
*
* Name		setOptions - Process command line options
*
* Synopsis	void setOptions(int argc, char **argv)
*
* Parameters
*		argc	Argument count from main()
*		argv	Argument vector from main()
*
* Description
*		Parse command line and set variables.
*
* Returns	None
*
* Version	1.0
*/

void setOptions(int argc, char **argv)
{
	int xOK = FALSE;
	int skip;
	int ntok;
	unsigned char *opt;
	char *pp;
	char work[256];

	/* Mark video mode as not set */
	ScreenSet = FALSE;

	arg_concat(work,argc,argv);

	for (opt = work; *opt; opt += skip ) {
		skip = 1;
		if (*opt != '/') {
			if (isspace(*opt)) continue;
			goto showHelp;
		}

		opt++;
		if (!(*opt)) break;

		/* Check for drive letter */
		if (isalpha (*opt) && *(opt+1) == ':') {
			boot_drive = *opt;
			skip = 2;
			continue;
		} /* End IF */

		switch( toupper( *opt )) {
		case 'B':       /* B&W monitor */
			ScreenType = SCREEN_MONO;
			ScreenSet = TRUE;
			break;

		case 'C':       /* Color monitor */
			ScreenType = SCREEN_COLOR;
			ScreenSet = TRUE;
			break;

		case 'D':       /* Skip Disk cache test (undocumented) */
			DiskCacheTest = FALSE;
			break;

#ifdef STACKER
		case 'K':       /* Enable swapped drive support */
			SwappedDrive = 1;
			break;
#endif // ifdef STACKER

#if REDUIT
		case 'M':       /* Extract all BCF files */
			AllBCFs = TRUE;
			break;
#endif

		case 'N':       /* New machine */
			NewMachine = TRUE;
			break;

		case 'O':       /* Overwrite only older files */
			Overwrite = TRUE;
			break;

		case 'P':       /* Overwrite files with different time/date */
			PatchPrep = TRUE;
			break;

		case 'R':       /* Redo install/update */
			ReInstall = TRUE; /* Install main product (386/blue max) */
			break;

		case 'S':       /* Safe (OK to use B0-B8) */
			VGAWARN = VW_SAFE|VW_FORCED;
			break;

		case 'U':       /* Unsafe (not OK to use B0-B8) */
			VGAWARN = VW_UNSAFE|VW_FORCED;
			break;

		case 'V':       /* Inhibit logo */
			GraphicsLogo = 0;
			break;

		case 'W':       /* snoW control */
			SnowControl = TRUE;
			break;

		case 'Y':       /* Restore state (return from stripmgr /e) */
			pp = arg_token(opt+1,&ntok);
			if (pp) {
				RestoreFile = get_mem (ntok+1);
				memcpy(RestoreFile,pp,ntok);
				/* RestoreFile[ntok] = '\0'; */
				opt = pp;
				skip = ntok;
			} /* Argument to /Y specified */
			else	goto showHelp;
			break;

		case 'Z':       /* Recall program */
			pp = arg_token(opt+1,&ntok);
			if (pp) {
				RecallString = get_mem (ntok+1);
				memcpy(RecallString,pp,ntok);
				/* RecallString[ntok] = '\0'; */
				opt = pp;
				skip = ntok;
			}
			else	goto showHelp;
			break;

		case 224:	/* à - Enable advanced options */
			AdvancedOpts = TRUE;
			break;

		case '2':       /* Move'Em install */
			printf (MsgGetMovem);
			exit (2);

		default:
			/* Any switch we don't understand */
			goto showHelp;
		}
	}
	return;

showHelp:
	printf( HelpString );
	exit(2);
} // End setOptions()


#if MOVEM
//******************************** MOVEM_INIT ********************************
//  This does the necessary fixups to install MOVE'EM instead of the main product

void	 movem_init ( )
{
	/* Init global variables */

	ident[0][0].fname = OEM_FileName = MOV_FILENAME;
		ident[1][0].fname = OEM_OldName = MOV_OLDNAME;
	ident[0][1].fname = MOV_MAXCOM;
		ident[1][1].fname = MOV_OLDCOM;
	OEM_IdentReqLen = 2;
	ident[0][2].fname = ident[1][2].fname = MAX_QSHELL;
	ident[0][3].fname = ident[1][3].fname = MAX_ASQ;
	ident[0][4].fname = ident[1][4].fname = MAX_MAXIMIZE;
	OEM_IdentLen = 5;

	InstallArgTo[5] = OEM_ProdName = MOV_PRODNAME;
	InstallArgTo[6] = OEM_FileName;
	InstallArgTo[9] = OEM_ProdFile = MOV_PRODFILE;
	InstallArgTo[10] = MOV_PRODDIR;
	OEM_Readme   = MOV_README;
	OEM_LoadBase = MOV_LOADBASE;

	strcpy(dest_subdir,MOV_INIDIR);
	strcpy(update_subdir,MOV_INIDIR);

} // End movem_init()
#endif

//************************* RETURN_TO_DOS ***********************************
void return_to_dos(int rc)
{
	abortprep(0);
	if (RecallString) {
		/* Reload QSHELL */
		execl(	RecallString,
			RecallString,
			"/Y0",
			ScreenType == SCREEN_MONO ? "/B" : "/C",
			NULL);
	}
	exit ( rc );
} // End return_to_dos()

extern int archandle; // From DRVE.C
//************************** ABORTPREP *************************************
void _cdecl abortprep(int flag)
{
	if (flag && InChild)	return;
	reset_video ();
	restore_path ();
	// Close archive file (& delete if on hard disk)
	if (archandle > 0) open_archive (0, 0, 0);
}

#pragma optimize("leg",off)
void breakpt(int callswat)
{
  if (callswat) _asm int 1;
}
#pragma optimize("",on)

/*********************** CLOBBER_LF *****************************/
// Strip trailing LF.  Used by parse_restore ().
static void near clobber_lf (char *buff)
{
  char *lf;

  if (lf = strrchr (buff, '\n')) *lf = '\0';

} // clobber_lf ()

/* Add a line from the STRIPMGR /e output file to our list of deltas. */
/* We'll use these in parsing CONFIG.SYS, and to edit batch files. */
void add_stripdelta (	char *pszPath,		// File path
			char *pszMatch, 	// What to find
			char *pszReplace,	// What to replace with
			DWORD dLine)		// Original line offset
{
  FILEDELTA *pF;
  LINEDELTA *pL, *pLNew;

  pF = get_filedelta (pszPath);
  pL = pF->pLines;
  pLNew = get_mem (sizeof(LINEDELTA));
  if (!pL) {
	pF->pLines = pLNew;
  } // List is empty
  else {
	// We'll keep everything sorted by logical offset.
	while (pL->pNext && dLine >= pL->dLine) pL = pL->pNext;
	pLNew->pNext = pL->pNext;	// NULL unless we're inserting
	pL->pNext = pLNew;
  } // Find end of line delta list or an insertion point

  pLNew->pszMatch = str_mem (pszMatch);
  if (pszReplace) pLNew->pszReplace = str_mem (pszReplace);
// else pLNew->pszReplace = NULL;
  pLNew->dLine = dLine;

} // add_stripdelta ()

typedef struct tagSaveTab {
	char near *fmt; // fprintf / fscanf format
	void *varaddr;	// Address of variable
	int nbytes;	// 0 for string or bytes to pass to printf
} SAVETAB;

static char near *pszStr = "%s\n";
static char near *pszCptr= "%s\n";
static char near *pszDec = "%u\n";
static char near *pszLong = "%lu\n";
static char near *pszNull = "(null)";

/* Initialize pSaveTab with values we need to save.  Some of 'em are */
/* allocated dynamically, so we can't make this completely table driven. */
extern char *ExeName;	// From EXENAME.C
SAVETAB *setSaveTab (void)
{
  SAVETAB *pRet;
  int i;

  pRet = get_mem (sizeof(SAVETAB)*40);

  // Character arrays, or pointers that we can always assume are allocated
  for (i=0; i<9; i++) pRet[i].fmt = pszStr;
  pRet[ 0].varaddr = dest_subdir;
  pRet[ 1].varaddr = saved_path;
  pRet[ 2].varaddr = source_drive;
  pRet[ 3].varaddr = source_subdir;
  pRet[ 4].varaddr = HelpFullName;
  pRet[ 5].varaddr = con_dpfne;
  pRet[ 6].varaddr = StartupBat;
  pRet[ 7].varaddr = update_subdir;
  pRet[ 8].varaddr = preinst_bat;

  // Pointers that may not be allocated or may be (null)
  for (i=9; i<13; i++) pRet[i].fmt = pszCptr;
  pRet[ 9].varaddr = &bcf_dpfne;
  pRet[10].varaddr = &RecallString;
  pRet[11].varaddr = &ExeName;
  pRet[12].varaddr = &MultiBoot;

  for (i=13; i<19; i++) {
	pRet[i].fmt = pszDec;
	pRet[i].nbytes = sizeof (char);
  }
  pRet[13].varaddr = &boot_drive;
  pRet[14].varaddr = &MaxConfig;
  pRet[15].varaddr = &ActualBoot;
  pRet[16].varaddr = &CopyBoot;
  pRet[17].varaddr = &CopyMax1;
  pRet[18].varaddr = &CopyMax2;

  for (i=19; i<37; i++) {
	pRet[i].fmt = pszDec;
	pRet[i].nbytes = sizeof (WORD);
  }
  pRet[19].varaddr = &saved_drive;
  pRet[20].varaddr = &ScreenSet;
  pRet[21].varaddr = &ScreenType;
  pRet[22].varaddr = &DiskCacheTest;
  pRet[23].varaddr = &SwappedDrive;
  pRet[24].varaddr = &AllBCFs;
  pRet[25].varaddr = &NewMachine;
  pRet[26].varaddr = &PatchPrep;
  pRet[27].varaddr = &VGAWARN;
  pRet[28].varaddr = &GraphicsLogo;
  pRet[29].varaddr = &SnowControl;
  pRet[30].varaddr = &AdvancedOpts;
  pRet[31].varaddr = &bcfsys;
  pRet[32].varaddr = &mcasys;
  pRet[33].varaddr = &BIOSCRC;
  pRet[34].varaddr = &VGAMEM;
  pRet[35].varaddr = &SVENDOR;
  pRet[36].varaddr = &VMODEL;
// Get MaxInst and POVR_MAC on the fly
// Ditto for ProductSet, DoMoveEm, and EMSType
// We'll force ReInstall
// We'll determine autox_fnd in parse_config()

//pRet[37].fmt = NULL;
//...
//pRet[39].fmt = NULL;

  return (pRet);

} // setSaveTab ()

/*************************** PARSE_RESTORE *******************************/
// Parse the RestoreFile passed on the command line and delete it.
void parse_restore (void)
{
  FILE *fin;
  char stripmgrlist[128];
  char buff[512];
#define BUFFSIZE sizeof(buff)-1
  char pathname[128];
  char stripaction;
  char *matchline, *replaceline;
  WORD lineoff;
  SAVETAB *pHead, *pt;
  DWORD data;
  char **ppsz;
  int isempty;

//  breakpt (1);

  pHead = setSaveTab ();

  fin = cfopen (RestoreFile, "r", 1);

  fscanf (fin, pszStr, stripmgrlist);
  for (pt = pHead; pt->fmt; pt++) {

	if (pt->nbytes) {

	  fscanf (fin, pt->fmt, &data);
	  memcpy (pt->varaddr, &data, pt->nbytes);

	} // Reading char, WORD, or DWORD
	else {

	  fscanf (fin, pt->fmt, buff);
	  isempty = !stricmp (buff, pszNull);

	  if (pt->fmt == pszCptr) {

	    ppsz = pt->varaddr; // Get address of pointer
	    if (!isempty) {

		if (*ppsz)	strcpy (*ppsz, buff);	// Pointer is valid
		else		*ppsz = str_mem (buff); // Allocate it

	    } // We have a valid string
	    else {

		*ppsz = NULL;

	    } // Null pointer

	  } // Reading a character pointer
	  else {

	    if (isempty) buff[0] = '\0';
	    strcpy (pt->varaddr, buff);

	  } // Reading a character array

	} // Reading an array or string

  } // For all variables to restore

  fclose (fin);
  unlink (RestoreFile);

  free (pHead);

  if (stripmgrlist[0] != '*') {

	fin = cfopen (stripmgrlist, "r", 1);

	while (cfgets (buff, BUFFSIZE, fin)) {

	  sscanf (buff, "%s %c %u\n", pathname, &stripaction, &lineoff);

	  if (pathname[0] == '*') break;

	  // We have two types of lines we're interested in:
	  // pathname c lineoff
	  // pathname r lineoff
	  // If c is specified, two lines follow, a match and a replacement.
	  // If r is specified, one line follows, containing a match.
	  // All matches are case sensitive.
	  // The original logical line offset is used for processing
	  // batch files, and the match / replace strings are used for
	  // confirmation and length matching.
	  // In CONFIG.SYS, line offsets are ignored since we might be
	  // relocating all over the place.
	  cfgets (buff, BUFFSIZE, fin);
	  clobber_lf (buff);
	  matchline = str_mem (buff);

	  if (stripaction == 'c') {
	    cfgets (buff, BUFFSIZE, fin);
	    clobber_lf (buff);
	    replaceline = str_mem (buff);
	  } // Get line to change to
	  else replaceline = NULL;

	  // Add to list of file changes
	  add_stripdelta (pathname, matchline, replaceline, lineoff);

	} // Not end of file

	fclose (fin);
//	breakpt(1);
	unlink (stripmgrlist);

  } // Parse list generated by STRIPMGR


} // parse_restore ()

/**************************** CREATE_RESTORE **************************/
// Create a RestoreFile before calling STRIPMGR.
// We're already in the directory, so we can use the filename only.
void create_restore (char *dir)
{
  FILE *fout;
  SAVETAB *pHead, *pt;
  char *psz;

  pHead = setSaveTab ();

  fout = cfopen (DOSNAME ".rcl", "w", 1);

  cfprintf (fout, "%s%s\n", dir, pszStripmgrOut);
  for (pt = pHead; pt->fmt; pt++) {
	switch (pt->nbytes) {

	case sizeof(BYTE):
		cfprintf (fout, pt->fmt, (WORD) *((BYTE *) pt->varaddr));
		break;

	case sizeof(WORD):
		cfprintf (fout, pt->fmt, *((WORD *) pt->varaddr));
		break;

	case sizeof(DWORD):
		cfprintf (fout, pt->fmt, *((DWORD *) pt->varaddr));
		break;

	default:
		if (pt->fmt == pszCptr) psz = *((char **) pt->varaddr);
		else			psz = pt->varaddr;

		// Make sure we use (NULL) if it's empty
		if (psz && !*psz) psz = pszNull;
		cfprintf (fout, pt->fmt, psz);
		break;

	} // end switch
  }

  fclose (fout);

  free (pHead);

} // create_restore ()

#if QCACHE_TEST
/************************** TEST_QCACHE *****************************/
// Run through the disk cache test several times to ensure we don't
// have a slow starter.  If we don't have one active, ask if they want
// us to install QCACHE.
void test_qcache (void)
{
	  char testfile[MAXPATH+1];
	  int dc_retry, dc_res;

	  sprintf (testfile, "%s" QCACHE_TST, dest_subdir);

	  // edit_config set low byte of dcache to indicate which disk
	  // caching software (if any) we found.  Now ask whether we should
	  // do something about it...
	  switch (dcache & DCACHE_ANYCACHE) {	// Handle disk caches

		case DCACHE_SMARTDRV:
		 if ((dcache & DCF_SD_NOSIZE) || dcache_arg <= QCACHE_MAX)
		  do_qcache (DCACHE_SMARTDRV); // SMARTDRV.SYS found
		 else
		  ;				// SMARTDRV found, but
						// it's using more than 2MB
		 break;

		case DCACHE_NONE:
		 if (!DiskCacheTest) break;	// Bug out if user said to skip

		 do_intmsg (MsgDiskCacheTest);
		 // Don't give up easily...
		 save_dcvid ();
		 for (dc_retry=0;
			(dc_res = dcache_active (testfile,
					2048,	// Block size to test
					0)	// Don't test for write delay
						) == DCACHE_NONE &&
				dc_retry < 6; dc_retry++)
					;
		 rest_dcvid ();

		 // Ensure we have the minimum memory to run Windows in
		 // 386 Enhanced mode, and have QCACHE installed period.
		 if (dc_res == DCACHE_NONE &&
		     max (extcmos(), max (extsize (), xmsmax ())) >=
				WINENHEXTCRITICAL)
			do_qcache (DCACHE_NONE);

		 break;

		default:
		 break; 			// If unknown, ignore

	  } // switch (dcache)

} // test_qcache ()
#endif // Not Move'em

/*********************** GET_FILEDELTA **************************/
/* Find the record for this file or add it if it doesn't exist already. */
FILEDELTA *get_filedelta (char *pszPath)
{
  FILEDELTA *pRet;
  FILEDELTA *pFLast;

  // Search the list (if it exists) for a matching file
  for ( pRet = pFLast = pFileDeltas;
	pRet && stricmp (pszPath, pRet->pszPath);
	pRet = pRet->pNext)
		pFLast = pRet;

  if (!pRet) {
	pRet = get_mem (sizeof(FILEDELTA));
	pRet->pszPath = str_mem (pszPath);
	strupr (pRet->pszPath); // For the show changes screen
	if (pFLast)	pFLast->pNext = pRet;
	else		pFileDeltas = pRet;
	// Allocate space for all paths now to avoid heap fragmentation later
	pRet->pszBackup = get_mem ((MAXPATH+1)*3); // pszOutput, pszDiff, and
				// pszBackup -- we'll shrink it later
  } // Didn't find a match

  return (pRet);

} // get_filedelta ()

/******************** EXT_EXISTS **************************/
// Return 1 if another FILEDELTA record has a matching .add or backup file,
// otherwise returns 0.
int ext_exists (char *addname, FILEDELTA *pExcept)
{
  FILEDELTA *pF;

  for (pF = pFileDeltas; pF; pF = pF->pNext)
    if (pF != pExcept &&
	pF->pszOutput &&
	(!stricmp (addname, pF->pszOutput) ||
	 !stricmp (addname, pF->pszBackup))	)
			return (1);

  return (0);

} // ext_exists ()

/******************** GET_OUTNAME *************************/
// Construct *.add and *.dif names for a file (if they don't already exist).
// Return a pointer we can use for stream processing; NULL
// if the .add filename has been created already, otherwise
// the name of the .add file.
// This function should NOT be called unless we ARE GOING TO
// write to the file.
// dest_subdir MUST be valid!!!
char *get_outname (FILEDELTA *pF)
{
  char buff[128];
  int extoff;
  char fdrive[_MAX_DRIVE], fdir[_MAX_DIR], fname[_MAX_FNAME], fext[_MAX_EXT];
  char *smem, *osmem;
  int smemavail, osmemavail;
  int smemalloc;
  int ext;

  if (!pF->pszOutput) {
	do_backslash (dest_subdir);
	_splitpath (pF->pszPath, fdrive, fdir, fname, fext);
	sprintf (buff, "%s%s.", dest_subdir, fname);
	extoff = strlen (buff); // Get offset of '\0'
	strcat (buff, "ADD");

	osmem = smem = pF->pszBackup;	// Get memory we set aside for paths
	osmemavail = smemavail = (MAXPATH+1)*3; // How much space remains

	// Now that we're handling other batch files, we need
	// to avoid conflicts between file basenames.
	// Murphy sez:	If there's a dumb trick you think no
	// one will use and you therefore don't need to support,
	// someone will use it.
	for (ext=0; ext_exists (buff, pF) && ext < 100; ext++) {
	  sprintf (&buff[extoff], "A%02d", ext);
	} // Find a .add extension not already in use

	strcpy (pF->pszOutput = smem, buff);
	smemalloc = strlen (buff) + 1;	// Number of bytes we'll use
	smem += smemalloc;
	smemavail -= smemalloc;

	if (ext) sprintf (&buff[extoff], "D%02d", ext);
	else	strcpy (&buff[extoff], "DIF");
	strcpy (pF->pszDiff = smem, buff);
//	smemalloc = strlen (buff) + 1;	// Same as for .A?? file
	smem += smemalloc;
	smemavail -= smemalloc;

	// Use .SAV for backup extension the first time around
	strcpy (&buff[extoff], "SAV");
	if (ext_exists (buff, pF) || !access (buff, 0)) {
	  for (ext=0; ext < 1000; ext++) {
	   sprintf (&buff[extoff], "%03d", ext);
	   // Make sure it's not used by another, and it doesn't
	   // exist on disk.
	   if (!ext_exists (buff, pF) && access (buff, 0)) break;
	  } // Find a backup extension we can use
	} // .SAV exists or is used by another file
	strcpy (pF->pszBackup = smem, buff);
//	smemalloc = strlen (buff) + 1;	// Same as for .A?? file
//	smem += smemalloc;
	smemavail -= smemalloc;

	// Ignore the result - we're shrinking to release the part
	// we didn't need.
	if (smemavail > 0) realloc (osmem, osmemavail - smemavail);

	return (pF->pszOutput);

  } // Create .add, .dif and backup filenames

  return (NULL);

} // get_outname ()

/******************** GET_INNAME *************************/
// Select appropriate name for input.  If pszOutput exists,
// use it, otherwise pszPath.
char *get_inname (FILEDELTA *pF)
{

  return (pF->pszOutput ? pF->pszOutput : pF->pszPath);

} // get_inname ()

static LINEDELTA *pEditCB;
/******************** EDIT_BATSUB ************************/
// process_stream () callback for applying STRIPMGR changes
// to batch files.
int edit_batsub (FILE *output, char *line, long streampos)
{
  LINEDELTA *pL;
  char *psz;

  if (!line) return (0); // Ignore EOF; we are here to take, not to give

  // Check for any changes for this line
  for ( pL = pEditCB;
	pL && pL->dLine != (DWORD) streampos;
	pL = pL->pNext) ; // for all LINEDELTA records

  if (pL && (psz = strstr (line, pL->pszMatch))) {

	if (pL->pszReplace) {

	  *psz = '\0';  // Cut out the part we're replacing
	  cfputs (line, output); // Dump start of line
	  cfputs (pL->pszReplace, output); // Dump the replacement
	  cfputs (psz + strlen (pL->pszMatch), output); // Dump what's left,
				// including trailing LF

	} // Replacing part of the line
	// else swallow the line

  } // Found a delta
  else cfputs (line, output);

  return (0);

} // edit_batsub ()

/******************** EDIT_BATFILES ***********************/
void edit_batfiles (void)
// If we got back any changes to batch files from STRIPMGR, apply
// them before we make any other changes to batch files.
{
  FILEDELTA *pF;
  char *pszInName, *pszOutName;
  char fdrive[_MAX_DRIVE],fdir[_MAX_DIR],fname[_MAX_FNAME],fext[_MAX_EXT];

  // We've already made our changes to CONFIG.SYS
  for (pF = pFileDeltas; pF; pF = pF->pNext)
    if (stricmp (pszInName = pF->pszPath, con_dpfne) &&
	(pEditCB = pF->pLines)) {

	// Set up the .add name and create the .dif and backup names
	pszOutName = get_outname (pF);
	process_stream (pszInName, pszOutName, edit_batsub);

    } // For all files other than CONFIG.SYS with line deltas

  // Set swap parameters for CONFIG.SYS, StartupBat, and MAX.PRO
  pF = get_filedelta (con_dpfne);
  pF->swap1 = CopyBoot;

  // We won't attempt to copy StartupBat to alternate drive unless
  // it's in the root directory.
  pF = get_filedelta (StartupBat);
  _splitpath (pF->pszPath, fdrive, fdir, fname, fext);
  if (!strcmp (fdir, "\\")) pF->swap1 = CopyBoot;

  pF = get_filedelta (pro_dpfne);
  pF->swap1 = CopyMax1;
  pF->swap2 = CopyMax2;

} // edit_batfiles ()

