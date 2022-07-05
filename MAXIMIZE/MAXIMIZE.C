/*' $Header:   P:/PVCS/MAX/MAXIMIZE/MAXIMIZE.C_V   1.4   23 Jan 1996 14:56:44   HENRY  $ */
/******************************************************************************
 *									      *
 * Copyright (C) 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MAXIMIZE.C								      *
 *									      *
 * Root module for MAXIMIZE						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <io.h>
#include <ctype.h>
#include <process.h>
#include <time.h>
#include <direct.h>
#include <dos.h>
#include <search.h>

/* Local includes */

#include <bioscrc.h>
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>
#include <libcolor.h>
#include <mbparse.h>
#include <myalloc.h>
#include <qprint.h>
#include <qhelp.h>
#include <ui.h>

#define OWNER
#include <debug.h>		/* Debug variables */
#define MAIN_C			/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef MAIN_C
#undef OWNER

#ifdef STACKER
#include <stackdlg.h>
#include <stacker.h>
#endif

#if SYSTEM != MOVEM
#include <ins_var.h>
#endif

#ifndef PROTO
#include "maximize.pro"
#include <maxsub.pro>
#include "readcnfg.pro"
#include "parse.pro"
#include "pass1.pro"
#include "pass2.pro"
#include "pass3.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
static BOOL premaxim_exists;
static BOOL GraphicsLogo = TRUE;	/* TRUE to do 'q' logo */
BOOL SnowControl = FALSE;
static BOOL RebootUnReal = FALSE;	/* TRUE to reboot if not in real mode */

/* Local functions */
int check_max (BYTE owner, char *mbsect); /* Callback for Multiboot sections */

/*
 *	Main program for MAXIMIZE
 */

int _cdecl main (int argc, char **argv)
{
	BOOL have_cfg;

#ifdef TESTARGS
	testargs(argc,argv);
#endif /*TESTARGS*/

	/* Get path of program loaded and strip file name */

	set_exename(argv[0],"MAXIMIZE.EXE");
	get_exepath(LoadString,sizeof(LoadString));


	/*----------------------------------------------------------*/
	/*  Get a canonical form of loadstrg to use before AUTOEXEC */
	/*----------------------------------------------------------*/

	strcpy (LoadTrue, LoadString);
	truedir (LoadTrue);

	/* Mark video mode as not set */
	ScreenSet = FALSE;

	/* Parse MAXIMIZE.CFG (if it exists) and set up CfgFile */
	parse_maxcfg ();

	/* Find the location of COMMAND.COM */
	Comspec = getenv ("COMSPEC");
	if (Comspec == NULL) {
		Comspec = "?:\\COMMAND.COM";
	} /* End IF */

	/* Parse the command line.  Command switches may override */
	/* settings in MAXIMIZE.CFG. */
	setOptions(argc, argv);

	initializeScreenInfo (SnowControl);
	setColors(ScreenType == SCREEN_MONO ? TRUE : FALSE);
	strcpy( PrintFile, "MAXIMIZE.PRN" );
	/*	Setup the header for printing */
	PrintProgramName = ProgramName;
	helpSystem = HELP_ABORT;			/*	Set where help is to start printing all */

	/*---------------------------------------------------------*/
	/*	Check if in virtual mode			       */
	/*---------------------------------------------------------*/

#if SYSTEM == MOVEM
	MaxInstalled = maxmovpres ();
#else
	{
		BOOL vmmode;		/* TRUE if in virtual mode */

		vmmode = Is_VM ();
		MaxInstalled = maxmovpres ();
		if (!MaxInstalled && vmmode) {

			// If /R active:
			if (RebootUnReal) {

				// Reboot
				printf( "Rebooting...  Please wait...\n" );
				reboot();
				return 1;

			} // Not real mode and MAX is not present

			/* Please disable ... while running ... */
			printf(MsgPlsDisable);
			return 2;

		} /* End IF */
		else if (RebootUnReal) {
			return 5;
		} // Return errorlevel so files can be restored now
		  // and Maximize can proceed
	}

	/* Set 386LOAD in-progress bit in the 386MAX LSEG and link */
	/* high DOS so malloc() can use it. */
	openhigh ();

	/* See if MAX detected a PCI local bus BIOS */
	maxcfg.PCIBIOS_flag = (is_PCI () ? 1 : 0);
#endif

	/* Install Ctrl-Break (INT 23h) and Critical Error handler (INT 24h) */
	inst2324();

	/*------------------------------------------------------*/
	/*	Check if 4DOS is loaded 			*/
	/*	and set maximum line length appropriately	*/
	/*------------------------------------------------------*/

	MaxLine = izit4dos () ? 254 : 126;

	/* Init background screen */
	istdwind();

	/*	Initialize the help system - Die if we fail - Starthelp gives the error */
	strcpy(HelpFileName,"MAXIMIZE.HLP");    /* Override help file name */
	if( startHelp(HelpFileName, HELPCOUNT) )
		goto bottom;

	setHelpArgs(MaximizeArgCnt,MaximizeArgFrom,MaximizeArgTo);

	/* Pass 1:  Do the logo screen, collect monitor type */
	if (Pass == 1 && !FromWindows) {
		do_logo(GraphicsLogo);
	}
	else	/* Paint the background screen */
		paintback ();

	showQuickHelp(HELP_QINTRO);

	// If we've started from Windows, MAXIMIZE.INI switches should
	// override everything else.
	if (FromWindows) {

		// If not DR DOS, remove NOHARPO
		if (!maxcfg.drdos) {
			if (GetProfileInt( "Defaults", "ExtraDOS", 0, NULL )) {
				del_maxcfg( "NO" HARPO );
				maxcfg.noharpo = 0;
			} // Remove NOEXTRADOS
			else if (!maxcfg.noharpo) {
				add_maxcfg( "NO" HARPO, " ; Disabled in WINMAXIM" );
				maxcfg.noharpo = 1;
			} // Add NOEXTRADOS (not already in MAXIMIZE.CFG)
		} // Remove NOHARPO

		// Ignore settings from Maximize.cfg, but we need to
		// update them so subsequent DOS maximize runs will be
		// in synch...
		if (GetProfileInt( "Defaults", "VGASwap", 0, NULL )) {
			del_maxcfg( "NOVGASWAP" );
			maxcfg.novgaswap = 0;
		} // Remove NOVGASWAP
		else if (!maxcfg.novgaswap) {
			add_maxcfg( "NOVGASWAP", " ; Disabled in WINMAXIM" );
			maxcfg.novgaswap = 1;
		} // Add NOVGASWAP (not already there)

		if (GetProfileInt( "Defaults", "ROMSrch", 0, NULL )) {
			del_maxcfg( "NOROMSRCH" );
			maxcfg.noromsrch = 0;
		} // Remove NOROMSRCH
		else if (!maxcfg.noromsrch) {
			add_maxcfg( "NOROMSRCH", " ; Disabled in WinMaxim" );
			maxcfg.noromsrch = 1;
		} // Add NOROMSRCH (not already there)

	} // Started from Windows
	//else {

		strcpy(MainButtons[0].text,MsgAbortEsc);
		MainButtons[0].colorStart = ABORTESCSTART;
		addButton(MainButtons,sizeof(MainButtons)/sizeof(MainButtons[0]),NULL);
		showAllButtons();

		/* Start with F2 off, turn it on only when needed */
		disableButton(KEY_F2,TRUE);

	//} // Not started from Windows

	/* These are here for testing purposes only, because it's
	 * hard to reproduce the conditions that cause them to come
	 * up in normal processing. --acl */
	/* FOR TESTING ONLY:  do_emshelp();		    */
	/* FOR TESTING ONLY:  do_mistake("L.CacheWarn",0);  */
	/* FOR TESTING ONLY:  do_mistake("L.Static3270",0); */
	/* FOR TESTING ONLY:  do_mistake("L.Static6001",0); */

	if (Pass == 1 && !FromWindows) {
		do_intro();
	}

	/* Bail out if error(s) */
	if (AnyError) goto bottom;

	/* Get boot drive and fill in ActiveFiles[CONFIG] and */
	/* ActiveFiles[AUTOEXEC] */
	do_getdrv();
	if (AnyError) goto bottom;

	/* Adjust comspec if not specified in environment */
	if (Comspec[ 0 ] == '?') {
		Comspec[ 0 ] = (char)BootDrive;
	} /* End IF */

	/* Initialize the group vector */
	{
		int kk;

		for (kk = 0; kk < sizeof(GroupVector)/sizeof(int); kk++) {
			GroupVector[kk] = -1;
		}
	}

	/* Set up window for do_intmsg() */
	intmsg_setup(-1);
	showQuickHelp(QuickRefs[Pass-1]);
	if (AnyError) goto bottom;

	if (!menu_parse ((char) BootDrive, 0)) {
	  if ((MultiBoot && set_current (MultiBoot)) ||
				(Pass == 1 && !MultiBoot)) {
		set_mbs_callback (check_max);
		MultiBoot = mboot_select (MsgMBMenu, HELP_MBMENU);
	  } /* MultiBoot selected */
	  else if (MultiBoot) {
	    SECTNAME *tmpsect;

	    if (tmpsect = find_sect (MultiBoot)) MultiBoot = tmpsect->name;
	  } /* MultiBoot specified on command line- normalize it */
	} /* CONFIG.SYS menu parsed OK */

	/* Read and parse CONFIG.SYS file, and fill in ActiveFiles[PROFILE] */
	/* Also determine if drive swapping is in effect if we didn't */
	/* handle it manually through the command line */
	have_cfg = readconfig (&BootDrive);

	/* Fill in ActiveFiles[BETAFILE] */
	set_betafile ();

	/*----------- Drive swapping parameters are fully set now -----------*/

	/* Create name of restore batch file and fill in ActiveFiles[PREMAXIM] */
	/* (also re-created in DOFILECHK if necessary) */
	restbatname();

	/* Create name of lastphase file and fill in ActiveFiles[LASTPHASE] */
	/* (also re-created in DOFILECHK if necessary) */
	lastphasename();

	/* Record our being here in the log file */
	logfileappend();

	/* All four of the above routines *MUST* be called before we test */
	/* MaxInstalled so we can restore the files if in error */

#if SYSTEM != MOVEM  /* ???? */
	/* If pass > 1, ensure that 386MAX is installed and running version 5.xx */
	if (Pass > 1 && (!MaxInstalled || MaxVer[0] < '5')) {
		do_error(MsgNoInst, FALSE);
		AbyUser = AnyError = TRUE; /* This flag is checked early in the pass */
	} /* End IF */
#endif

	/*---------------------------------------------------------*/
	/*	Get boot drive and process depending on pass parameter */
	/*---------------------------------------------------------*/

	if (!AnyError && BootDrive >= 0 && have_cfg) {
		check_lastphase(Pass);

		/* Ensure we're in the right phase */
		if (Pass == 1 && !AnyError)
			restbatcreate();

		if (!AnyError) {
			switch (Pass) {
			case 1:
				pass1 ();
				break;
			case 2:
				pass2 ();
				break;
			case 3:
				pass3 ();
				break;
			} /* End switch */
		} /* if (!AnyError) */
	} /* if */

	if (AnyError)
		restmsg ();
	else if (BootDrive < 1) {
		do_intmsg (MsgInvDrv); /* Invalid drive selected */
		do_intmsg (MsgPgmAbt); /* Program aborting */
		do_intmsg (MsgPlsRer); /* Please rerun MAXIMIZE */
		dialog_input(0,NULL);
	} /* End IF */
bottom:
	/* Shut down windows and clean up */
	cstdwind();
	done2324();
	maxout (AnyError);
	return 0;
} /* End MAIN */


/********************************* CMPARSE_CB *******************************/
/* parse_config () callback used by check_max () to look for MAX.SYS in */
/* CONFIG.SYS.	Note this function always returns 0. */
int MaxInSection;
int CMParse_CB (CONFIGLINE *cfg)
{
  char *tok1, *tok2;
  char	buffer[256],
	pdrv [_MAX_DRIVE],
	ppath[_MAX_PATH],
	pfnam[_MAX_FNAME],
	pfext[_MAX_EXT];


  if (cfg->ID == ID_DEVICE && !MaxInSection) {
	/* Get second token: file being loaded */
	strncpy (buffer, cfg->line, sizeof(buffer)-1);
	buffer[sizeof(buffer)-1] = '\0';
	strip_endcrlf (buffer); /* Strip off leading CR trailing LF */
	tok1 = strtok (buffer, ValPathTerms); /* DEVICE / DEVICEHIGH */
	tok2 = strtok (NULL, ValPathTerms); /* d:\path\max.sys */
	if (tok2) {
		// If it's not a DEVICE= line, ignore it
		if (_strnicmp (tok1, "device", 6)) return (0);
		_splitpath (tok2, pdrv, ppath, pfnam, pfext);
		sprintf (buffer, "%s%s", pfnam, pfext);
		if (!_stricmp (MAXSYS, buffer)) MaxInSection = 1;
	}
  } /* DEVICE= line and we haven't found MAX.SYS yet */
  return (0);
} /* CMParse_CB () */

/********************************* CHECK_MAX ********************************/
/* Check to see if MAX.sys exists in specified MultiBoot section */
/* We'll parse CONFIG.SYS looking for a MAX.SYS device */
int check_max (BYTE owner, char *sectname)
{
  MaxInSection = 0;	/* Clear flag */
  config_parse ((char) BootDrive, owner, "\\dev\\nul", 0, CMParse_CB);
  if (!MaxInSection) do_error(MsgNoMaxCfgMB, FALSE); /* Display warning */
  return (MaxInSection);
} /* check_max () */

/********************************* BASENAME ***********************************/
static char basetmp[13];

char *basename (char *pathname)
{
	char drive[5],dir[65],ext[5];

	_splitpath (pathname, drive, dir, basetmp, ext);
	strcat (basetmp, ext);
	return (basetmp);
} /* basename() */

/********************************* RESTMSG ************************************/
/* Restore files and display message */

static void restmsg(void)
{
	if (!AbyUser)	/* If user didn't ESCAPE at some point, */
			/*   must be an I/O error at some point. */
	do_intmsg (MsgErrWwf); /* Errors were detected while writing files */

	/* Delete AUTOEXEC.ABETA */
	remove (ActiveFiles[BETAFILE]);

	/* In order to avoid cluttering up the message screen, */
	/*	 don't display this message if it's the only one so far */
	if (AbyUser && IntMsgCount != 0)
		/* Exiting program */
		do_intmsg (MsgExitPgm);

	if (IntMsgCount) {
		/* In order to avoid cluttering up the message screen, */
		/*	 don't display this message if it's the only one so far */

		/* Pause for a keystroke */
		dialog_input(0,NULL);
	} /* End IF */

} /* End RESTMSG */

/********************************* LASTPHASENAME ******************************/
/* Create LASTPHASE file name */

void lastphasename (void)
{
	char work[80];

	/* Construct the name of the LASTPHASE file */
	strcpy (work, LoadString);
	strcat (work, LSTPHS);
	_strupr (work);
	ActiveFiles[LASTPHASE] = str_mem(work);

} /* End LASTPHASENAME */

/******************************** CHECK_LASTPHASE *****************************/
/* Check on LASTPHASE file */

void check_lastphase (int pass)
{
	char buff[1], lastphaseno;
	int err = 0;

	/* Check to see if we're restarting in */
	/* the middle of a previous invocation. */

	/* Calculate the last phase # */
	lastphaseno = (char) ('1' + ((pass + 1) % 3));

	disable23 ();

	if (_access (ActiveFiles[LASTPHASE], 0) == 0) {
		/* If the LASTPHASE file exists, */
		FILE *fp;

		fp = fopen (ActiveFiles[LASTPHASE], "rb");
		if (!fp 				/* If we can't _open it, */
		    || (fread (buff, 1, 1, fp) != 1)	/* ... or we can't read it */
		    || buff[0] != lastphaseno)		/* ... or it's not the correct # */
			do_error(MsgPhsErr, TRUE); /* Display error message and abort */

		/* If we opened it, _close it */
		if (fp) fclose (fp);
	} /* End IF */
	else				/* Otherwise, create it */
		err = createfile (ActiveFiles[LASTPHASE]);
	enable23 ();

	if (err == -1)			/* Check for error */
		AnyError = TRUE;

} /* End CHECK_LASTPHASE */

/******************************** WRITE_LASTPHASE *****************************/
/* Write out a new last phase number */

void write_lastphase (int pass)
{
	FILE *fp;
	char buff[1];

	disable23 ();

	fp = fopen (ActiveFiles[LASTPHASE], "wb"); /* Attempt to open the file */

	if (!fp) {
		/* If we can't */
		AnyError = TRUE;	/* ...mark as in error */
		enable23 ();
		return; 			/* ...and return */
	} /* End IF */

	buff[0] = (char) ('0' + pass);  /* Seed the buffer */
	if (fwrite (buff, 1, 1, fp) != 1) {
		/* If error writing, */
		AnyError = TRUE;	/* ...mark as in error */
		enable23 ();
		fclose (fp);			/* ...close it up */
		return; 			/* ...and return */
	} /* End IF */

	fclose (fp);

	enable23 ();

} /* End WRITE_LASTPHASE */

/********************************* RESTBATNAME ********************************/
/* Create restore batch file name */

void restbatname (void)
{
	char work[80];

	/* Construct the name of the PREMAXIM file */
	strcpy (work, LoadString);
	strcat (work, PRMXM);
	_strupr (work);
	ActiveFiles[PREMAXIM] = str_mem(work);

	/* Construct the name of the ERRMAXIM file */
	strcpy (work, LoadString);
	strcat (work, ERRMXM);
	_strupr (work);
	ActiveFiles[ERRMAXIM] = str_mem(work);
} /* End RESTBATNAME */


/******************************** RESTBATAPPEND *******************************/
/* Append a new line to the PREMAXIM file */
/* NDX is the index into FILES and SFILES */
// If we're in a swapped drive environment, restore file to both drives
// for CONFIG.SYS and 386MAX.PRO

void restbatappend (int ndx)

{
	FILE *fp;
	char work[160], work2[128];
	int err = 0;
#ifdef STACKER
	int i;
#endif

	fp = fopen (ActiveFiles[PREMAXIM], "a+");
	if (!fp) return;

	disable23 ();

#ifdef STACKER
	for (i=0; i<3 && err != -1; i++) {

		strcpy (work2, ActiveFiles[ndx]);
		if (i) {
			if (SwappedDrive > 0) {
				if (i<2 && CopyBoot &&
					(ndx == CONFIG || ndx == AUTOEXEC)) {
					work2[0] = CopyBoot;
				}
				else if (ndx == PROFILE
#ifdef HARPO
					|| ndx == HARPOPRO
#endif
								) {
					if (i==1 && CopyMax1)
						work2[0] = CopyMax1;
					else if (i==2 && CopyMax2)
						work2[0] = CopyMax2;
					else break;
				}
				else break;
			}
			else break;
		}
#endif			/* ifdef STACKER */

		/* Create the line with the "copy" command */
		sprintf (work, "copy %%1%s %s\n",
			basename (SavedFiles[ndx]), work2);

		/* Convert file names to upper case */
		_strupr (strchr (work, ' '));

		if (fwrite(work, strlen(work), 1, fp) != 1) err = -1;

#ifdef STACKER
	} // for ()
#endif			/* ifdef STACKER */

	fclose (fp);
	enable23 ();

	if (err == -1) {
		AnyError = 1;
		return;
	}
	else
		return;

} /* End RESTBATAPPEND */


/******************************** SET_BETAFILE ********************************/
/* Create ActiveFiles[BETAFILE] from ActiveFiles[AUTOEXEC] */
/* It's not always AUTOEXEC.áAT; /K or 4DOS.INI may specify something else */
void set_betafile (void)
{
	char work[80];
	char	pdrv[_MAX_DRIVE],
		pdir[_MAX_DIR],
		pfnam[_MAX_FNAME],
		pext[_MAX_EXT];

	_splitpath (ActiveFiles[AUTOEXEC], pdrv, pdir, pfnam, pext);
	_makepath (work, pdrv, pdir, pfnam, "." ABETA);
	ActiveFiles[BETAFILE] = str_mem (work);

} /* set_betafile () */

/******************************** RESTBATCREATE *******************************/
/* Create restore batch file */

void restbatcreate(void)
{
	char work[80];
	int err;

	/* Check for backup file deletion */
	CheckBackup ();

	/* Tell the user what we're doing */
	do_intmsg(MsgCreating,ActiveFiles[PREMAXIM]);

	disable23();

	/* Create the PREMAXIM file */
	err = createfile(ActiveFiles[PREMAXIM]);
	if (err != -1) {
		/* If no error, */
		FILE *fp;

		fp = fopen (ActiveFiles[PREMAXIM], "a+"); /* Open the file */
		if (!fp)
			err = -1;
		else {
			/* Write out line to delete LASTPHASE */
			/* If PREMAXIM called with no args, use current form of path */
			sprintf (work,	"if \"%%1\" == \"\" %%0 %s\n"
					"erase %%1%s\n"
					"erase %s\n",
				!(*LoadString) ? ".\\" : LoadString,
				basename (ActiveFiles[LASTPHASE]),
				ActiveFiles[BETAFILE]);
			if (fputs(work,fp)) err = -1;
			fclose (fp);		/* Close it up */
		} /* End ELSE */
	} /* End IF */

	enable23 ();

	if (err == -1) {
		AnyError = 1;
		return;
	} /* End IF */

	premaxim_exists = TRUE; 	/* Mark as having been created */

	disable23 ();

	/* Tell the user what we're doing */
	do_intmsg(MsgCreating,ActiveFiles[ERRMAXIM]);

	/* Create the ERRMAXIM file */
	err = createfile (ActiveFiles[ERRMAXIM]);
	if (err != -1) {
		/* If no error, */
		FILE *fp;

		fp = fopen (ActiveFiles[ERRMAXIM], "a+"); /* Open the file */
		if (!fp)
			err = -1;
		else {
			err |= fputs(MsgErrBat1, fp);
			strcpy (work, ActiveFiles[PREMAXIM]);
			truename (work);
			sprintf (work+strlen(work), " %s", LoadTrue);
			err |= fputs(work,fp);
			err |= fputs(MsgErrBat2, fp);
			err |= fputs(ActiveFiles[PREMAXIM], fp);
			err |= fputs("\n", fp);
			if (RecallString) {
			 /* ERRMAXIM calls PREMAXIM, then reloads MAX shell */
			 sprintf (work, "%s /Y0 %s\n",
				RecallString,
				ScreenType == SCREEN_MONO ? "/B" : "/C");
			 err |= fputs (work,fp);
			}
			fclose (fp);	/* Close it up */
		} /* End ELSE */
	} /* End IF */

	enable23 ();

	if (err == -1) {
		AnyError = 1;
	} /* End IF */
} /* End RESTBATCREATE */

int setOptsub (char **pStr, int *pntok, char **popt, int *pskip)
/* Copy argument to a command switch.  Return 0 if all's OK. */
{
	char *pp;

	pp = arg_token((*popt)+1,pntok);
	if (pp) {
		*pStr = my_malloc((*pntok)+1);
		if (*pStr) {
			memcpy(*pStr,pp,*pntok);
			*((*pStr) + *pntok) = '\0';
		}
		*popt = pp;
		*pskip = *pntok;
		return (0);
	}
	else	return (-1);

} /* End setOptsub () */

/************************ setOptions ***************************************
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

#pragma optimize("leg", off)
void setOptions(int argc, char **argv)
{
	int xOK = FALSE;
	int skip;
	int ntok;
	unsigned char *opt;
	char work[256];

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
			BootDrive = *opt;
			skip = 2;
			continue;
		} /* End IF */

		/* Check for pass # */
		if (isdigit(*opt)) {
			Pass = *opt - '0';
			if (Pass < 1) Pass = 1;
			if (maxcfg.BREAK == Pass) _asm int 1;
			skip = 1;
			continue;
		} /* End IF */

		switch( toupper( *opt )) {
		case 'A':       /* Active MultiBoot */
			if (setOptsub (&MultiBoot, &ntok, &opt, &skip))
					goto showHelp;
			break;

		case 'B':       /* B&W monitor */
			ScreenType = SCREEN_MONO;
			ScreenSet = TRUE;
			break;

		case 'C':       /* Color monitor */
			ScreenType = SCREEN_COLOR;
			ScreenSet = TRUE;
			break;
#ifdef DEBUG
		case 'D':       /* Debug (verbose) switch */
			Verbose = TRUE; /* Mark as present */
			break;
#endif
		case 'E':       /* Express Maximize switch */
			QuickMax = 1;
			NopauseMax = 1;
			break;

		case 'I':       /* Force IGNOREFLEXFRAME in Phase I */
			ForceIgnflex = TRUE;
			break;

#ifdef STACKER
		case 'K':       /* Swapped drive environment */
			SwappedDrive = 1;
			/* Get optional parameters: */
			/* ActualBoot CopyBoot MaxConfig CopyMax1 CopyMax2 */
			if (*(opt+1) && !strchr (" \t/\n", *(opt+1))) {
				opt++;		/* Skip 'K' */
				get_stackopts (&opt);
				skip = 0;	/* opt already points to next */
			}
			break;
#endif			/* ifdef STACKER */

		case 'N':       /* Nopause Maximize switch */
			NopauseMax = 1;
			break;

		case 'O':		/* dOsstart.bat switch */
			if (setOptsub (&pszDOSStart, &ntok, &opt, &skip))
					goto showHelp;
			break;

		case 'P':		/* Premaxim and reboot */
			printf( "Restoring previous batch files...\n" );
			Pass = 0;
			maxout( 1 );
			printf( "Rebooting...  Please wait...\n" );
			reboot();
			break;

		case 'R':		/* Reboot if not in real mode */
			RebootUnReal = TRUE;
			break;

		case 'T':       /* Timeout to default on all input */
			TimeoutInput = 1;
			break;

		case 'U':       /* Custom Maximize switch */
			QuickMax = -1;
			break;

		case 'V':       /* Inhibit logo */
			GraphicsLogo = FALSE;
			break;

		case 'W':       /* Enable CGA snow control */
			SnowControl = TRUE;
			break;

		case 'X':		/* Windows start */
			FromWindows = TRUE;
			NopauseMax = 1;
			break;

		case 'Z':       /* Recall program */
			if (setOptsub (&RecallString, &ntok, &opt, &skip))
					goto showHelp;

		case 224:	/* à - Enable advanced options */
			AdvancedOpts = TRUE;
			break;

		default:
			/* Any switch we don't understand */
			goto showHelp;
		}
	}
	return;

showHelp:
	printf( HelpString );
	{
	extern char HelpStringB[];
#ifdef MULTIBOOT
	extern char HelpString6[];

	printf (HelpString6);
#endif	/* ifdef MULTIBOOT */
	printf( HelpStringB );
	}
	exit(2);
}
#pragma optimize("", on)

/**************************** MAXOUT **************************************/
/* If error code > 0, restore files as per PREMAXIM.BAT (if it exists) */
/* If pass == 1, use EXECL */
/* Otherwise, return error code for AUTOEXEC.BAT to process. */
/* This is the exit point for all types of errors other than unhandled */
/* run-time errors (there shouldn't be any of those...) */

void maxout (int errcode)
{
	char buff[80];

#if SYSTEM != MOVEM
	closehigh (); /* Clear 386LOAD in-progress bit and _unlink arenas */
#endif

	if (Pass > 1 || errcode == 0 || (Pass == 1 && !premaxim_exists)) {

	 if (Pass == 1 && RecallString)
		/* Reload QSHELL */
		_execl(	RecallString,
			RecallString,
			"/Y0",
			ScreenType == SCREEN_MONO ? "/B" : "/C",
			NULL);

	 /* Let AUTOEXEC.BAT handle it */
	 exit (errcode);	/* Fall through if _execl() fails as well */
	}

	/* Create argument string to COMMAND.COM */
	sprintf (buff, "%s%s", LoadString, PRMXM);

	/* Execute the line which should look something like */
	/* C:\COMMAND.COM /C C:\386MAX\PREMAXIM */
	if (Pass) {
		_execl (Comspec, Comspec, "/C", buff, NULL);
	} // Not pass 0
	else {
		_spawnl( _P_WAIT, Comspec, Comspec, "/C", buff, NULL );
	} // Pass 0 (used only with /P option)

} /* End MAXOUT */

/******************************** ABORTPREP *******************************/
void _cdecl abortprep(int flag)
{
	if (flag);
	cstdwind();
	done2324();
	maxout(1);
}

/******************************** LOGFILEAPPEND *******************************/
/* Append a new line to the MAXIMIZE log file */

void logfileappend(void)
{
	FILE *fp;
	time_t t;
	char work[80];

	/* Construct the name of the log file */
	strcpy (work, LoadString);
	strcat (work, LOGFILE);
	_strupr (work);
	fp = fopen (work, "a+");
	if (!fp) return;

	/* Write pass number and timestamp */
	time(&t);
	disable23 ();
	fprintf(fp, "Pass %d, %s", Pass, ctime(&t));
	fclose (fp);
	enable23 ();

	/* That's it. */
} /* End logfileappend */
#ifdef TESTARGS
void testargs(int argc,char **argv)
{
	int iarg;
	FILE *fp;


	fp = fopen("aux","w");
	if (!fp) return;

	fprintf(fp,"argc = %d\n",argc);
	for (iarg = 0; iarg < argc; iarg++) {
		fprintf(fp,"  argv[%d] = \"%s\"\n",iarg,argv[iarg]);
	}
	fprintf(fp,"--------\n");
	fclose(fp);
}
#endif /*TESTARGS*/

/*** Local functions used in MAXIMIZE.CFG parser action table ***/

/* NOVGASWAP: Don't enable it */
void Cfg_NoVGASwap (void)
{	maxcfg.novgaswap = 1;	}

/* NOROMSRCH: Don't run it */
void Cfg_NoROMSrch (void)
{	maxcfg.noromsrch = 1;	}

/* REBOOTCMD=[command]
 * After flushing disk cache, execute %COMSPEC% /c <command>.
 * If command is not specified, return to DOS prompt.  Since command
 * is passed to %COMSPEC% /c, command may be a batch file or an
 * executable.
*/
void Cfg_RebootCmd (char *line)
{	RebootCmd = str_mem (line);	}

/* SNOWCONTROL: Enable CGA snow control */
void Cfg_SnowControl (void)
{	SnowControl = TRUE;	}

/* NOLOGO: Inhibit logo (same as /v) */
void Cfg_NoLogo (void)
{	GraphicsLogo = FALSE;	}

/* NOSCAN=addr1-addr2: Inhibit RAMSCAN and leave RAM= statements alone */
void Cfg_NoScan (char *line)
{
	/* Get address range */
	DWORD hex1=0, hex2=0;

	line = skipwhite (line);	// Skip leading whitespace (NOSCAN= ...)
	line = scanlhex (line, &hex1);	// Get first argument
	line = skipwhite (line);	// Skip whitespace (x -)
	line++; 			// Skip '-'
	line = skipwhite (line);	// Skip whitespace (x - y)
	(void) scanlhex (line, &hex2);	// Get second argument

	/**** This doesn't work:
	sscanf (line, "%*[ \t=]%lx%*[ \t-]%lx", &hex1, &hex2)
	*****/

	if (hex1 >= 0x0A000L && hex2 <= 0x10000L && hex2 > hex1) {
	    /* Convert to 4K blocks past A000:0 */
	    hex1 = (hex1-0xA000L) >> 8;
	    while (hex1 <= (hex2-0xA000L-1L) >> 8)
		 RAMTAB[hex1++] = (BYTE) RAMTAB_UNK;
	} /* Range is valid */
} /* Cfg_NoScan */

/* ROMSRCHOPTS=switches: Options passed as args to ROMSRCH.  Ex: /a to
 * recover ABIOS.
 */
void Cfg_RomsrchOpts (char *line)
{	RomsrchOpts = str_mem (line);	}

#ifdef HARPO
/* NOHARPO: Don't add HARPO to CONFIG.SYS */
void Cfg_NoHARPO (void)
{	maxcfg.noharpo = 1;	}
#endif

/* TIMEOUTDELAY=secs: Delay in seconds for input timeout with /T option */
void Cfg_TimeoutDly (char *line)
{
  DWORD tmp;
  if (tmp = atol (line))	TimeoutDelay = tmp * 1000L;
}

/* NOEXPAND: Don't expand MultiBoot CONFIG.SYS include and common sections */
void Cfg_NoExpand (void)
{	maxcfg.noexpand = 1;	}

///* SYSPOSCOLDBOOT={TRUE|FALSE}: If TRUE, create a system diskette to reboot
// * for POS changes if any planar POS changes occur.  Normally, we'll do
// * this on any system with ABIOS loaded from RAM (Model 56 486slc2, Model
// * 700 Thinkpad).  FALSE tells us it's not that type of system.
// */
//void Cfg_SysPosColdBoot (char *arg)
//{
//  SysPosColdBoot = (	!_stricmp (arg, "TRUE") ||
//			!_stricmp (arg, "ON") ||
//			!_stricmp (arg, "1")             );
//}

/* BOOTDRIVE=d: Specify a boot drive other than what we detect */
/* As this may be specified on the command line, we have to ensure that */
/* the command line value takes precedence. */
void Cfg_BootDrive (char *arg)
{	if (!isalpha(BootDrive)) BootDrive = *arg;	}

/* USECOLOR=BOOL Specify color set to use */
/* Any one of 1, T[RUE], or Y[ES] is equivalent to the /C option; */
/* anything else is equivalent to /B. */
void Cfg_UseColor (char *arg)
{
	ScreenSet = TRUE;
	ScreenType = (strchr ("1YyTt", *arg) || !_stricmp ("ON", arg)) ?
			SCREEN_COLOR : SCREEN_MONO;
}

/* BACKUP=max,min Specify maximum backup file number.  If we have any files */
/* in the MAX directory with .xxx > max, delete everything with .xxx <= */
/* max-min and rename everything to .xxx-min. */
/* Valid max î { 1...999, -1}, min î { empty, 0...999} */
/* BACKUP=-1 means never ask and do nothing */
/* BACKUP=5,1 deletes everything above .004, .004 ==> .000 and .005 ==> .001 */
/* BACKUP=8,0 deletes everything above .008, .008 ==> .000 */
/* Whenever the trigger condition occurs, we'll delete any OLDMAX.n */
/* directories and their contents. */
void Cfg_Backup (char *arg)
{
  WORD tmp1, tmp2;
  char *token, *tseps = " \t,\n";

  if (token = strtok (arg, tseps)) {

	tmp1 = atoi (token);

	if (token = strtok (NULL, tseps)) {

	  tmp2 = atoi (token);

	} /* Second argument specified */
	else tmp2 = BackupMin;

	if (tmp1 && tmp1 < 1000) {

	  BackupMax = tmp1;
	  BackupMin = tmp2;

	} /* First argument valid */

  } /* Got something */

} /* Cfg_Backup */

/* PCIBIOS: MAX detected a PCI local bus BIOS */
void Cfg_PCIBIOS (void)
{	maxcfg.PCIBIOS = 1;	}

#if SYSTEM != MOVEM
/* NOGATE: Don't use WBINVD */
void Cfg_NOGATE (void)
{	nogate();		}
#endif

/* Breakpoint on specified pass (1, 2, 3 or * for all) */
void Cfg_BREAK( char *arg )
{
	int n = atoi( arg );
	maxcfg.BREAK = n;
	if (!n) _asm int 1;
}

struct _CfgAction {
	char	*token;
	void (*action) (void);
	void (*action2) (char *);
} CfgAct[] = {
	{ "NOVGASWAP",  Cfg_NoVGASwap,  NULL },
	{ "NOROMSRCH",  Cfg_NoROMSrch,  NULL },
	{ "REBOOTCMD",  NULL,           Cfg_RebootCmd },
	{ "SNOWCONTROL",Cfg_SnowControl,NULL },
	{ "NOLOGO",     Cfg_NoLogo,     NULL },
	{ "NOSCAN",     NULL,           Cfg_NoScan },
	{ "ROMSRCHOPTS",NULL,           Cfg_RomsrchOpts },
#ifdef HARPO
	{ "NO" HARPO,   Cfg_NoHARPO,    NULL },
#endif
	{ "TIMEOUTDELAY",NULL,          Cfg_TimeoutDly },
	{ "NOEXPAND",   Cfg_NoExpand,   NULL },
//	{ "SYSPOSCOLDBOOT", NULL,       Cfg_SysPosColdBoot },
	{ "BOOTDRIVE",  NULL,           Cfg_BootDrive },
	{ "USECOLOR",   NULL,           Cfg_UseColor },
	{ "BACKUP",     NULL,           Cfg_Backup },
	{ "PCIBIOS",    Cfg_PCIBIOS,    NULL },
#if SYSTEM != MOVEM
	{ "NOGATE",     Cfg_NOGATE,     NULL },
#endif
	{ "BREAK",		NULL,			Cfg_BREAK },
	{ NULL, NULL }
};

#pragma optimize("leg",off)
/************************** PARSE_MAXCFG **************************************/
/* Set up filename CfgFile, _open and parse MAXIMIZE.CFG (if it exists), and */
/* set appropriate flags in maxcfg record.  Set NOHARPO if it's DR DOS. */
void parse_maxcfg (void)
{
  char temp[255];
  char token1[41];
  char *semicol;
  int tokenoff, leading;
  FILE *mcfg;
  int i;
#if SYSTEM != MOVEM
  WORD AdfSkipAdd[100];
  WORD AdfStaticAdd[100];
  WORD AdfID;
  int AdfSkipAddCount = 0, AdfStaticAddCount = 0;
#endif

  sprintf (temp, "%s" CFGFILE, LoadString);

  CfgFile = str_mem (temp);

  if ((mcfg = fopen (CfgFile, "r")) != NULL) {

	while (fgets (temp, sizeof (temp) - 1, mcfg)) {

		temp [sizeof (temp) - 1] = '\0';

		if (semicol = strpbrk (temp, QComments)) {
			*semicol = '\0';
		} // Clobber comments

		if (semicol = strchr (temp, '\n')) {
			*semicol = '\0';
		} // Clobber trailing LF

		// Skip leading whitespace
		leading = strspn (temp, CfgKeywordSeps);

		// Skip to end of keyword
		tokenoff = strcspn (temp+leading, CfgKeywordSeps);
		strncpy (token1, temp+leading, tokenoff);
		token1 [tokenoff] = '\0';

		// Make tokenoff an index to the start of the next one
		tokenoff += (leading + strspn (temp+leading+tokenoff,
				CfgKeywordSeps));

		for (i=0; CfgAct[i].token; i++) {
			if (!_stricmp (token1, CfgAct[i].token)) {
				if (CfgAct[i].action) {
					(*CfgAct[i].action) ();
				}
				else {
					(*CfgAct[i].action2) (temp+tokenoff);
				}
			}
		}

#if SYSTEM != MOVEM
		if (!_stricmp (token1, "ADFSTATIC")) {
			while (temp[tokenoff] && AdfStaticAddCount <
			    sizeof (AdfStaticAdd) / sizeof (AdfStaticAdd[0])) {
				tokenoff += strspn (temp+tokenoff,CfgKeywordSeps);
				sscanf (temp+tokenoff, "%x", &AdfID);
				if (AdfID) {
				     AdfStaticAdd[AdfStaticAddCount++] = AdfID;
				}
				tokenoff += strcspn (temp+tokenoff,CfgKeywordSeps);
			}
		}

		if (!_stricmp (token1, "ADFSKIP")) {
			while (temp[tokenoff] && AdfSkipAddCount <
			    sizeof (AdfSkipAdd) / sizeof (AdfSkipAdd[0])) {
				tokenoff += strspn (temp+tokenoff,CfgKeywordSeps);
				sscanf (temp+tokenoff, "%x", &AdfID);
				if (AdfID) {
				     AdfSkipAdd[AdfSkipAddCount++] = AdfID;
				}
				tokenoff += strcspn (temp+tokenoff,CfgKeywordSeps);
			}
		}
#endif

	} /* not end of mcfg file */

	fclose (mcfg);

#if SYSTEM != MOVEM
	if (AdfStaticAddCount) {
		AdfStaticU = get_mem ((AdfStaticAddCount+1) * sizeof (WORD));
		wordcpy (AdfStaticU, AdfStaticAdd, AdfStaticAddCount);
		*(AdfStaticU + AdfStaticAddCount) = 0;
	}
	if (AdfSkipAddCount) {
		AdfSkipU = get_mem ((AdfSkipAddCount+1) * sizeof (WORD));
		wordcpy (AdfSkipU, AdfSkipAdd, AdfSkipAddCount);
		*(AdfSkipU + AdfSkipAddCount) = 0;
	}
#endif

  } /* CfgFile opened */

#ifdef HARPO
  /* Check for DR DOS.	If active, turn on NOHARPO. */
  _asm {
	mov	 ah,0x30;	/* Get DOS version */
	int	 0x21;		/* AH=minor, AL=major */
	cmp	 ax,0x1F03;	/* Izit DR DOS? */
	je	 short DRDOS;	/* Maybe so... */

	cmp	 ax,0x0006;	/* Izit Novell DOS 7? */
	jne	 short NOT_DRDOS; /* Jump if not */

DRDOS:
	mov	 ax,0x4452;	/* DR DOS detection call */
	stc			/* CF=0 on return */
	int	 0x21;		/* AX = DR DOS version code */
	jc	 short NOT_DRDOS; /* Jump if call failed */

	and	 ax,0xFFF0;	/* Get high order 12 bits */
	cmp	 ax,0x1060;	/* Izit a DR DOS version? */
				/* 1060h	3.40 */
				/* 1063h	3.41 */
				/* 1065h	5.0 */
				/* 1066h	6.0 */
	je	 short DRDOS2;	/* Jump if so

	cmp	 ax,0x1070;	/* Izit Novell DOS 7? */
	jne	 short NOT_DRDOS; /* Jump if not DR DOS */

DRDOS2:
  }
  maxcfg.noharpo = 1; /* Disable HARPO support */
  maxcfg.drdos = 1;
NOT_DRDOS:
	;
#endif /* ifdef HARPO */

} /* parse_maxcfg () */
#pragma optimize("",on)

#ifdef STACKER
void SwapUpdate (int ndx)
// Update file ActiveFiles[ndx] on swapped drive
{
 char temp[128];
 char fdrive[_MAX_DRIVE],fdir[_MAX_DIR],fname[_MAX_FNAME],fext[_MAX_EXT];
 char drive = 0, drive2 = 0;

 if (ndx == AUTOEXEC || ndx == CONFIG) {
	drive = CopyBoot;
	if (ndx == AUTOEXEC) {
	  char *trailback;

	  _splitpath (ActiveFiles[ndx], fdrive, fdir, fname, fext);
	  sprintf (temp, "%s%s", fdrive, fdir); /* Get c:\4dos40\ */
	  temp[0] = drive; /* d:\4dos40\ */
	  if (*(trailback = &temp[strlen(temp)-1]) == '\\') {
		*trailback = '\0';
	  } /* Clobber trailing backslash */
	  (void) _mkdir (temp);
	} /* Ensure the destination path exists */
 }
 else if (ndx == PROFILE
#ifdef HARPO
		|| ndx == HARPOPRO
#endif
					) {
	drive	= CopyMax1;
	drive2	= CopyMax2;
 }

 if (SwappedDrive > 0 && drive) {
	strcpy (temp, ActiveFiles[ndx]);
	temp[0] = drive;
	(void) copy (ActiveFiles[ndx], temp);
	if (drive2) {
		temp[0] = drive2;
		(void) copy (ActiveFiles[ndx], temp);
	}
 } // SwappedDrive

} // SwapUpdate ()
#endif			/* ifdef STACKER */

int is_backup (char *fname, int *pExtnum)
{
  char *extension;

	if (extension = strrchr (fname, '.')) {

	  *extension++ = '\0'; /* Terminate basename */
	  if (strlen (extension) == 3) {

		if (!(*pExtnum = atoi (extension)) &&
			strcmp (extension, "000")) return (0);
		else	return (1);

	  } /* Extension is exactly 3 characters (no .1 or .01) */
	  else return (0);

	} /* Found '.' in the filename */
	else return (0);

} /* is_backup () */

typedef struct tagDirSort {
 WORD date;	/* wr_date from find_t */
 WORD time;	/* wr_time from find_t */
 WORD extnum;	/* extension number (0-999) */
} DIRSORT;

typedef struct tagNameSort {
 char fname[12]; /* File basename with ".*" added */
 struct tagNameSort *next;
} NAMESORT;

/* We want to order descendingly */
int DirSortComp (DIRSORT *p1, DIRSORT *p2)
{
  if (p1->date < p2->date)	return (1);
  else if (p1->date > p2->date) return (-1);
  else if (p1->time < p2->time) return (1);
  else if (p1->time > p2->time) return (-1);
  else if (p1->extnum < p2->extnum) return (1);
  else if (p1->extnum > p2->extnum) return (-1);
  else return (0);

} /* DirSortComp () */

static NAMESORT *pName; /* List of unique basenames */

/* Initialize pName to a list of all unique file basenames */
void CreateUList (void)
{
  struct find_t ff;
  char *maxfspec;
  int extnum;
  NAMESORT *pWalk, *pPrev;

  maxfspec = get_mem (256);

/* First we need to walk through and get a list of unique file basenames */
/* with extensions .000 to .999 */

    strcpy (maxfspec, LoadString);
    strcat (maxfspec, "*.*");

    _dos_findfirst (maxfspec, _A_ARCH, &ff);

    do {

	/* Extension in ff.name is clobbered */
	if (!is_backup (ff.name, &extnum)) continue;

	/* See if it's already in the list */
	for (pWalk = pName, pPrev = NULL;
		pWalk && _stricmp (ff.name, pWalk->fname);
		pWalk = pWalk->next) pPrev = pWalk;

	if (pWalk) continue;

	pWalk = get_mem (sizeof (NAMESORT));
	strcpy (pWalk->fname, ff.name);
/*	pWalk->next = NULL; */

	if (pPrev) pPrev->next = pWalk;
	else pName = pWalk;

    } while (!_dos_findnext (&ff));

  /* Now add .* so we can use 'em for findfirst */
  for (pWalk = pName; pWalk; pWalk = pWalk->next)
	strcat (pWalk->fname, ".*");

  free (maxfspec);

} /* CreateUList () */

/* Delete list of unique file basenames */
void DeleteUList (void)
{
  NAMESORT *pWalk, *pPrev;

  for (pWalk = pName; pWalk; ) {

      pPrev = pWalk;
      pWalk = pWalk->next;
      free (pPrev);

  } /* For all basenames */

} /* DeleteUList () */

/* Get list of extensions and save in pExtensions[] (if specified). */
/* Return number of extensions found. */
int GetExtList (char *maxfspec, DIRSORT *pExtensions)
{
  int cExtensions, extnum;
  struct find_t ff;

  cExtensions = 0;

  if (!_dos_findfirst (maxfspec, _A_ARCH, &ff)) {

	do {

	  if (!is_backup (ff.name, &extnum)) continue;

	  if (pExtensions) {

	    pExtensions[cExtensions].date = ff.wr_date;
	    pExtensions[cExtensions].time = ff.wr_time;
	    pExtensions[cExtensions].extnum = extnum;

	  } /* pExtensions[] specified */

	  cExtensions++;

	} while (!_dos_findnext (&ff) && cExtensions < 1000);

  } /* Found first one */

  return (cExtensions);

} /* GetExtList () */

/* Save the last BackupMin copies of each filename. */
void CheckBackSub (void)
{
  char maxfspec[_MAX_PATH];
  int stemlen, baselen, extnum;
  NAMESORT *pWalk;
  DIRSORT *pExtensions;
  int cExtensions;

    pExtensions = get_mem (1000 * sizeof (DIRSORT));

/* For each basename in the list, get all the extensions and sort */
/* descendingly by date/time/extension, then delete all but the first */
/* BackupMin. */
    strcpy (maxfspec, LoadString);
    stemlen = strlen (maxfspec);

    for (pWalk = pName; pWalk; ) {

      strcpy (&maxfspec[stemlen], pWalk->fname);

      /* Get length of basename */
      baselen = (int) (strrchr (maxfspec, '.') - maxfspec);

      /* Get number of extensions and save them in pExtensions[] */
      cExtensions = GetExtList (maxfspec, pExtensions);

      if (!cExtensions) continue; /* ??? */

      /* Order descendingly (newest first) */
      qsort ((void *)pExtensions, (size_t)cExtensions, sizeof (DIRSORT),
	  		(int (*)(const void *, const void *))DirSortComp);

      /* Delete all but the first BackupMin newest */
      for (extnum = BackupMin; extnum < cExtensions; extnum++) {
	sprintf (&maxfspec[baselen], ".%03d", pExtensions[extnum].extnum);
	_unlink (maxfspec);
      } /* For all extensions older than last BackupMin (if any) */

      pWalk = pWalk->next;

    } /* For all basenames */

    free (pExtensions);

} /* CheckBackSub () */

/* Check for a backup deletion trigger condition: */
void CheckBackup (void)
{
  struct find_t ff, dd;
  char maxfspec[_MAX_PATH],
	fdir[_MAX_DIR];
  NAMESORT *pWalk;
  int trigger = 8;
  int delete = 0;
  int stemlen;

  if (BackupMax < 0) return;

  /* Use BACKUP= trigger value if specified */
  if (BackupMax) trigger = BackupMax;

  /* Create list of unique file basenames */
  CreateUList ();

  /* Check for a trigger condition first */
  /* For each unique file basename having one or more extensions, */
  /* count the number of backup extensions.  If it exceeds BackupMax, */
  /* trigger deletion.	If BackupMax hasn't been specified, we'll */
  /* ask the question when we reach 8. */
  for (pWalk = pName; pWalk; pWalk = pWalk->next) {

    if (GetExtList (pWalk->fname, NULL) >= trigger) {

	if (!BackupMax) {

	    switch (ask_backup (trigger)) {

		case RESP_YES:
		  trigger = BackupMax;
		  break;

		case RESP_NO:
		  trigger = -1; /* Disable question */
		  break;

		case KEY_ESCAPE:
		default:
		  goto CBACK_EXIT;

	    } /* Process response to "Yes, No, Cancel" */

	    /* Save response to MAXIMIZE.CFG */
	    sprintf (fdir, "BACKUP=%d", trigger);
	    if (trigger >= 0) sprintf (stpend (fdir), ",%d", BackupMin);
	    add_maxcfg (fdir, CfgBackup);

	    /* If they don't want deletion, return now */
	    if (trigger < 0) goto CBACK_EXIT;

	} /* First time; ask what they want */

	delete = 1;

      } /* Exceeded maximum */

  } /* For all unique file basenames */

  /* Check for any OLDMAX.n directories */
  sprintf (maxfspec, "%sOLDMAX.*", LoadString);
  if (!_dos_findfirst (maxfspec, _A_ARCH|_A_SUBDIR, &dd)) {

    do {

      if (dd.attrib & _A_SUBDIR) {

	sprintf (maxfspec, "%s%s\\", LoadString, dd.name);
	stemlen = strlen (maxfspec); /* Index of trailing \0 */
	strcat (maxfspec, "*.*");

	if (!_dos_findfirst (maxfspec, _A_ARCH, &ff)) {

	  do {
	    strcpy (&maxfspec[stemlen], ff.name);
	    _unlink (maxfspec);
	  } while (!_dos_findnext (&ff));

	} /* Found files in OLDMAX.* */

	maxfspec[stemlen-1] = '\0';     /* Clobber trailing backslash */
	_rmdir (maxfspec);		/* Unlink the directory */

      } /* Got a directory */

    } while (!_dos_findnext (&dd));

  } /* Found OLDMAX.* */

  if (delete) CheckBackSub ();

CBACK_EXIT:
  /* Free list of unique file basenames */
  DeleteUList ();

} /* CheckBackup () */

