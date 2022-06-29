/*' $Header:   P:/PVCS/MAX/MAXIMIZE/READCNFG.C_V   1.1   13 Oct 1995 12:04:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-94 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * READCNFG.C								      *
 *									      *
 * Read and parse CONFIG.SYS file					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>		/* Intermediate message functions */
#include <max_sys.h>
#ifdef STACKER
#include <stackdlg.h>		/* Manual drive swapping support */
#include <stacker.h>
#endif			/* ifdef STACKER */
#include <mbparse.h>		/* Multiboot CONFIG.SYS functions */

#define READCNFG_C
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef READCNFG_C

#ifndef PROTO
#include "maximize.pro"
#include <maxsub.pro>
#include "parse.pro"
#include "profile.pro"
#include "readcnfg.pro"
#include "readmxmz.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
static char maxflag = 0;	/* Flag whether or not 386MAX has been found */
static char *loadpath = NULL;
static FILE *cfgfile;		/* 386LOAD.CFG file */

/* Local functions */
int IsResident (char *devpath)
/* Walks through LSEG chain looking for specified device or INSTALL= */
/* basename. */
/* If a match, it's not a UMB allocator, and it went resident, return 1 */
/* Note that devpath may terminate the device path with a command separator */
{
	LSEGFIT far *plseg;
	WORD lseg;
	char devdrive[_MAX_DRIVE], devdir[_MAX_DIR],
		devname[_MAX_FNAME+_MAX_EXT], devext[_MAX_EXT];
	int complen;

	/* In case strtok () returned NULL... */
	if (!devpath) return (0);

	_splitpath (devpath, devdrive, devdir, devname, devext);

	strcat (devname, devext); /* Get FILENAME.EXT */
	complen = strlen (devname); /* Bytes to compare */

	for (lseg = LoadSeg; lseg != -1; lseg = plseg->next) {

	  plseg = FAR_PTR (lseg, 0);
	  if ( (plseg->flag.drv ||	/* DEVICE= */
		plseg->flag.inst) &&	/* INSTALL= */
		!_strnicmp (plseg->name, devname, complen) ) {

		if (plseg->flag.umb) {
		  plseg->flag.xres = 1; /* Mark as not resident */
		  plseg->flag.umb = 0;	/* Avoid confusion with UMBs */
		} /* Allocated UMBs */
		if (plseg->flag.xres) break; /* Not resident */

		/* Resident and not a UMB allocator or MAX.SYS */
		/* We don't need to relocate MAX.SYS */
		return (plseg->grp != GRPMAX);

	   } /* DEVICE or INSTALL with matching name */

	} /* for (lseg;;) */

	return (0);	/* No match found, or not resident */

} /* IsResident () */

int MBCallback (CONFIGLINE *cfg)
/* Takes a line from CONFIG.SYS and tells MultiBoot parser whether it's */
/* a candidate for high loading */
/* Note that we only check DEVICE and INSTALL programs for relocation */
/* in Phase 2 of Maximize, when we've already put in 386LOAD GETSIZE */
/* during Phase 1 so we can tell if the program is already resident */
/* or is a UMB allocator. */
/* Once we've found one resident program, mark all subsequent programs */
/* of the same type as resident so that we keep things in the same */
/* order. */
{
  char *tok1, *tok2;
  char	buffer[256],
	pdrv [_MAX_DRIVE],
	ppath[_MAX_PATH],
	pfnam[_MAX_FNAME],
	pfext[_MAX_EXT];
  static BYTE MovedOwner = 0;
  static CFGID MovedID = ID_OTHER;


  if (	Pass == 2 && !maxcfg.noexpand &&
	(cfg->ID == ID_DEVICE || cfg->ID == ID_INSTALL)
				) {
	/* Get second token: file being loaded */
	strncpy (buffer, cfg->line, sizeof(buffer)-1);
	buffer[sizeof(buffer)-1] = '\0';
	strip_endcrlf (buffer); /* Strip off leading CR trailing LF */
	tok1 = strtok (buffer, ValPathTerms);
	if (tok1 && (!_stricmp (tok1, "lh") ||
		     !_stricmp (tok1, "loadhigh")))
		tok1 = strtok (NULL, ValPathTerms);
	tok2 = strtok (NULL, ValPathTerms);
	if (tok2) {
		// If it's not a DEVICE= or INSTALL= line, ignore it
		// Also ignore a non-resident line or UMB allocator
		if (_strnicmp (tok1, "device", 6) && _stricmp (tok1, "install"))
			return (0);
		_splitpath (tok2, pdrv, ppath, pfnam, pfext);

		// If we've already relocated a (resident) line of
		// the same type {device, install} in this section,
		// we need to relocate any valid lines to maintain order.
		if (MovedOwner == cfg->Owner) {

		  if (MovedID == cfg->ID) return (1);

		} // Same section
		else MovedOwner = 0; // Ensure we don't confuse this with
				// other sections.

		// Always relocate 386LOAD lines unless the program is
		// non-resident or a UMB allocator.
		if (!_stricmp (pfnam, LOADER)) {

			while (tok2 = strtok (NULL, ValPathTerms)) {

			  if (!_stricmp (tok2, "prog"))
				if (!IsResident (strtok (NULL, ValPathTerms)))
					return (0);

			} // while not end of line
			goto MBC_RELOCATE; // Didn't find prog= (?)

		} // 386LOAD

		if (check_lcfg (tok2, cfgfile, 'g') == TRUE ||
		    (cfg->ID == ID_INSTALL &&
			check_lcfg (tok2, cfgfile, 'a') == TRUE) ||
		    !IsResident (tok2))  return (0);

	} // Got DEVICE= / INSTALL= argument
	else return (0);

MBC_RELOCATE:
	MovedID = cfg->ID;	// Relocate subsequent lines of same type
	MovedOwner = cfg->Owner; // and owner.
	return (1);

  } /* INSTALL= or DEVICE= line in Pass 2 */
  else	return (0);

} /* MBCallback () */

#ifdef STACKER
/************************** FIXUP_LOADERS *******************************/
/* Walk through CONFIG.SYS and fix up all 386LOAD.SYS lines with MaxConfig */
void fixup_loaders (void)
{
	DSPTEXT *p2;
	char buff1[_MAX_PATH], *devtext;
	int cmplen;

	if (SwappedDrive > 0 && MaxConfig) {

		LoaderDir[0] = MaxConfig;
		strcpy (LoaderTrue, LoaderDir);
		truedir (LoaderTrue);

		/* Note that we've already parsed all */
		/* device= lines, so now we need to go */
		/* back and fix 'em all up. */
		sprintf (buff1, "%s" LOADERS, LoadTrue);
		cmplen = strlen (buff1);

		for (p2 = HbatStrt[CONFIG]; p2; p2 = p2->next)
		  if (p2->device == (BYTE) DSP_DEV_DEVICE &&
		      !_strnicmp (buff1, devtext = p2->text + p2->nlead, cmplen)) {
			*devtext = MaxConfig;
		  } /* DEVICE=386load.sys line */

	} /* MaxConfig specified */

} /* End fixup_loaders () */
#endif	/* ifdef STACKER */


/************************* pszTempFile ****************************/
/* Create a temporary file name in the c:\386max directory */
/* Note that the returned pointer has been malloc()ed and must */
/* be free()d when we're done with it. */
char *pszTempFile (char *pszPre)
{
	int DirLen;
	char *pszRet;

	/* Remove trailing backslash if not the root directory */
	DirLen = strlen (LoadString);
	if (DirLen > 3 && LoadString [--DirLen] == '\\')
		LoadString [DirLen] = '\0';
	else DirLen = 0;

	pszRet = _tempnam (LoadString, pszPre);

	/* Restore trailing backslash */
	if (DirLen) LoadString [DirLen] = '\\';

	return (pszRet);

} /* pszTempFile () */

/************************************* READCONFIG *****************************/

BOOL readconfig (int *drive)
{
	char buff[520], *pbuff = buff;
	DSPTEXT *p, *q, *cfg;
	FILE *in;
	SECTNAME *menusect;
	BYTE MenuOwner = 0;
	char *tempname;

	/* Reading CONFIG.SYS file */
	do_intmsg(MsgReadCfg);

	/* Open the loader .CFG file.  We'll need it for the callback. */
	disable23 ();
	sprintf (buff, "%s" LOADER ".CFG", LoadString);
	if ((cfgfile = fopen (buff, "r")) == NULL) {
		do_warning(MsgLocCfg,0);
		enable23 ();
		AnyError = AbyUser = 1; 	/* Mark as if user requested abort */
		return FALSE;
	} /* End IF */

	tempname = pszTempFile ("MB");

	if (MultiBoot) {

	  /* Preprocess CONFIG.SYS into c:\386max\CONFIG.MB$ */
	  /* This may expand INCLUDEd and common sections. */
	  strcpy (buff, tempname);
	  if (config_parse ((char) *drive, ActiveOwner, buff, 0, MBCallback)) goto CONFIGSYS_ERR;

	  /* Get the startup batch file parsed by config_parse() */
	  ActiveFiles[AUTOEXEC] = StartupBat;

	  pbuff = buff + 2;	/* Skip over leading code characters */
	  if (menusect = find_sect ("menu")) MenuOwner = menusect->OwnerID;

	} /* MultiBoot preprocessing */
	else {

	  /* Get 4DOS or DOS 6 startup file, and set Parsed4DOS flag */
	  if (!config_parse ((char) *drive, '@', "/dev/nul", 0, MBCallback))
		ActiveFiles[AUTOEXEC] = StartupBat;

	  /* Tell 'em what we're doing */
	  sprintf (buff, "%c:\\config.sys", *drive);

	} /* No MultiBoot; read CONFIG.SYS directly */

	/* Attempt to open the file */
	if ((in = fopen (buff, "r")) == NULL) {
CONFIGSYS_ERR:
		do_error(MsgNoCfgSys, TRUE);	/* Display message and abort program */
		enable23 ();
		AnyError = AbyUser = 1; 	/* Mark as if user requested abort */
		_unlink (tempname);
		free (tempname);
		return FALSE;
	} /* End IF */

	/*---------------------------------------------------------*/
	/*	Establish structure for the data		       */
	/*---------------------------------------------------------*/

	cfg = get_mem (sizeof (DSPTEXT));

	/*---------------------------------------------------------*/
	/*	Establish structure for first line of file	       */
	/*---------------------------------------------------------*/

	fgets (buff, sizeof (buff) - 1, in);
	strip_endcrlf (buff);	/* Strip off leading CR trailing LF */

	cfg->text = str_mem (pbuff);
	p = cfg;

	cfg->visible = 1;	/* Assume it's visible */
	if (MultiBoot) {
	  cfg->MBtype = buff[0];
	  cfg->MBOwner = buff[1];
	  if (	cfg->MBOwner != ActiveOwner &&
		cfg->MBOwner != CommonOwner &&
		cfg->MBOwner != MenuOwner) {
			cfg->MBtype = ID_REM;
			cfg->visible = 0;
	  } /* Not one of ours */
	}

	/*---------------------------------------------------------*/
	/*	Now link a struct for each line into a list	       */
	/*---------------------------------------------------------*/

	while (fgets (buff, 512, in) != NULL)
	{
		q = get_mem (sizeof (DSPTEXT));
		strip_endcrlf (buff);	/* Strip off leading CR, trailing LF */
		q->text = str_mem (pbuff);
		q->visible = 1; 	/* Assume it's visible */
		if (MultiBoot) {
		  q->MBtype = buff[0];
		  q->MBOwner = buff[1];
		  if (	q->MBOwner != ActiveOwner &&
			q->MBOwner != CommonOwner &&
			q->MBOwner != MenuOwner) {
				q->MBtype = ID_REM;
				q->visible = 0;
		  } /* Not one of ours */
		}
		q->prev = p;
		p->next = q;
		p = q;
	} /* End WHILE */

	fclose (in);

	_unlink (tempname);
	free (tempname);

	/* Get a directory we can reference throughout CONFIG.SYS */
	/* Note that this may be a stub directory, and hence we can't */
	/* use it for references to MAXIMIZE, BATPROC, etc. */
	strcpy (LoaderDir, LoadString);
	strcpy (LoaderTrue, LoaderDir);
	truedir (LoaderTrue);

	/*---------------------------------------------------------*/
	/*	For each line, mark struct if a Device= line	       */
	/*---------------------------------------------------------*/

	for (p = cfg; p; p = p->next)
		fndevice (p, cfgfile);

	fclose (cfgfile);
	enable23 ();

	/*---------------------------------------------------------*/
	/*	Check for required files			       */
	/*---------------------------------------------------------*/

	dofilechk();
	if (AnyError) goto bottom;

	HbatStrt[CONFIG] = cfg;
	/*---------------------------------------------------------*/
	/*	Pass 1 and pass 3, parse 386MAX line and profile       */
	/*	Pass 2, parse 386MAX line only to get profile name     */
	/*	If we didn't find it, UGH.                             */
	/*---------------------------------------------------------*/

	for (p = cfg; p; p = p->next)
		if (p->max == 1)	/* If it's 386MAX */
		{
			char maxdrive;
			char temp[128];

			/* Use argv[0] rather than *ProfileBoot. */
			get_exepath (temp, sizeof(temp));
			maxdrive = (char) (toupper (temp[0]));

#ifdef STACKER
			/* If user specified /K but did not set */
			/* ActualBoot, MaxConfig, and CopyMax1, */
			/* put up a big dialog box... */
			if (SwappedDrive > 0) {
				get_swapparms ((char) BootDrive,
					maxdrive,
					LoadString,
					MsgBootSwap,
					HELP_SWAPPEDDRIVE);
			}
			else
				check_swap ((char) BootDrive, maxdrive);
			fixup_loaders ();	/* Set MaxConfig drive letter */
						/* for all 386load.sys lines */
#endif			/* ifdef STACKER */

			parsecfg(p->pdevice, p);
			/* Handle case where no profile */
			if (ActiveFiles[PROFILE] == NULL)
				newpro (p);

			break;
		} /* End FOR/IF */

	/* Ensure we found it */
	if (p == NULL) {
		do_error(MsgNoMaxCfg, TRUE);	/* Display message and abort program */
		free_mem (cfg);
		AnyError = AbyUser = 1; 	/* Mark as if user requested abort */
		return FALSE;
	} /* End IF */
/*
 *#if SYSTEM != MOVEM
 *    /* If MAX is not installed and EXTSIZE is non-zero, *
 *    /* append an EXT= statement to the profile *
 *    if (!MaxInstalled && ExtSize != 0)
 *    {  /* Loop through the profile and check for EMS= or EXT= statements *
 *	 /* If found, don't put in an EXT= statement *
 *	 PRSL_T *r;
 *
 *	 for (r = CfgHead ; r ; r = r->next)
 *	 switch (r->data->etype)
 *	 {   case EMS:
 *	   case EXT:
 *		     goto SKIPEXT;
 *	 } /* End FOR/SWITCH *
 *
 *	 /* EXT=%ld ; MAXIMIZE has detected %ld KB of extended memory in use *
 *	 sprintf (buff, MsgExtEqu, ExtSize, ExtSize);
 *	 add_to_profile (EXT, buff, ExtSize, 0L);
 *    } /* End IF *
 *
 *SKIPEXT:
 *#endif
 */

bottom:
	return cfg ? TRUE : FALSE;
} /* End READCONFIG */

/*********************************** ISWHITE **********************************/
/* Determine whether or not *P is white space (0x09 or 0x20) */

int iswhite (char c)

{
	return (c == '\t' || c == ' ');

} /* End ISWHITE */

/********************************** SKIPWHITE *********************************/
/* Skip over white space */

char *skipwhite (char *p)

{
	while (iswhite (*p)) p++;
	return (p);

} /* End SKIPWHITE */

/********************************** SKIPBLACK *********************************/
/* Skip over non-white space */

char *skipblack (char *p)

{
	while (*p && !iswhite (*p)) p++;
	return (p);

} /* End SKIPBLACK */

/********************************** SCANOPTS *********************************/

/*--------------------------------------------------------------*/
/* Scan a LOADER line for options, setting OPTS in S		*/
/* Return pointer to text following PROG= if all went well,	*/
/* 0 if not							*/
/* On entry, strtok() should be set up so that the each 	*/
/* call to strtok (NULL,) returns the next token.  Note that	*/
/* this means we'll get "prog" instead of "prog="               */
/*--------------------------------------------------------------*/

char *scanopts (DSPTEXT *s, int index)

{
	char *q;

	/* Get options from the loader line. */
	while (q = strtok (NULL, ValPathTerms))
	{
SCAN_REPARSE:
		if (!_stricmp(q, "display"))
		{
			s->opts.display = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "envname"))
		{
			continue;	/* Note we don't mark as present */
		} /* End IF */		/*	 as it is the default */

		if (!_stricmp(q, "envreg"))
		{
			/* If it's not what we expect, treat as unknown line */
			if (!(q = strtok (NULL, ValPathTerms)))
				goto UNKNOWN;

			s->envreg = (BYTE) atoi(q); /* Convert to number */
			s->opts.envreg = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "envsave"))
		{
			s->opts.envsave = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "flexframe"))
		{
			s->opts.flex = 1;	/* Mark as present */
				/* conditionally; if GETSIZE is present, */
				/* we'll zap this when we hit the end */
				/* (prog=) */
			continue;
		} /* End IF */

		if (!_stricmp(q, "getsize"))
		{
			s->opts.getsize = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "group"))
		{
			/* If it's not what we expect, treat as unknown line */
			if (!(q = strtok (NULL, ValPathTerms)))
				goto UNKNOWN;

			s->group = (BYTE) atoi (q); /* Convert to number */
			s->group0 = s->group;
			if (s->group > 0 && s->group < MAXGROUPS) {
				GroupVector[s->group-1] = index;
			}
			s->opts.group = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "int"))
		{
			s->opts.inter = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "nopause"))
		{
			s->opts.nopause = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "noretry"))
		{
			s->opts.noretry = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "pause"))
		{
			s->opts.pause = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "prgreg"))
		{
			/* If it's not what we expect, treat as unknown line */
			if (!(q = strtok (NULL, ValPathTerms)))
				goto UNKNOWN;

			s->prgreg = (BYTE) atoi (q); /* Convert to number */
			s->opts.prgreg = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "prog"))
		{
			strcat (q, "=");        /* Get a string to look for */
			/* If we can't find it in the original line, */
			/* treat it as unknown */
			if (!(q = strstr (s->text, q)))
				goto UNKNOWN;

			s->opts.prog = 1;	      /* Mark as present */
			/* Clobber FLEXFRAME if it's a GETSIZE line */
			if (s->opts.getsize) s->opts.flex = 0;
			q = skipwhite (q+5);	/* Skip over prog= and */
						/* trailing white space */
			return(q);		/* That's all folks... */
		} /* End IF */

		if (!_stricmp(q, "quiet"))
		{
			s->opts.quiet = 1;	 /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "size"))
		{
			/* If it's not what we expect, treat as unknown line */
			/* Note that we can't use ValPathTerms since , is */
			/* also a valid command separator. */
			if (!(q = strtok (NULL, " \t=")))
				goto UNKNOWN;

			s->opts.size = 1;	      /* Mark as present */
			if (q = strtok (NULL, " \t=")) {

			  /* We might have: */
			  /* 1. size=n1,n2 nextoption... */
			  /* 2. size=n1 nextoption... */
			  /* 3. size=n1 ,n2 nextopt... */
			  /* 4. size=n1 , n2 nextopt... */

			  /* Eliminate cases 1 and 2 */
			  if (*q != ',' && !isdigit (*q)) goto SCAN_REPARSE;

			  if (q = strtok (NULL, " \t=")) {

			    /* If case 3, process q */
			    if (!isdigit (*q)) goto SCAN_REPARSE;

			  } /* Got n2 (case 4) or nextopt (case 3) */

			} /* Got another token */
			/* else break; */

			continue;
		} /* End IF */

		if (!_stricmp(q, "vds"))
		{
			s->opts.vds = 1; /* Mark as present */
			continue;
		} /* End IF */

		if (!_stricmp(q, "terse"))
		{
			s->opts.terse = 1; /* Mark as present */
			continue;
		} /* Terse option encountered */

		if (!_stricmp(q, "verbose"))
		{
			s->opts.verbose = 1; /* Mark as present */
			continue;
		} /* Verbose option encountered */

UNKNOWN:
		/* Unknown option:  take safe course and don't mess */
		/* with this line. */
		s->device = 0;	/* Mark as neither Device= nor Install= */
		break;

	} /* End WHILE */

	return (0);			/* Indicate we found a problem */

} /* End SCANOPTS */

#if 0
/*********************************** CONVNUM **********************************/
/* Convert the number at *Q to binary */
/* and skip over it */

static BYTE convnum (char **q)
{
	char *p, c;
	int val;

	*q = skipwhite (*q);		/* Skip over white space */
	p = *q; 		/* Save pointer for ATOI */
	while (isdigit (**q)) (*q)++; /* Skip over decimal digits */
	c = **q;			/* Save value of next character */
	**q = '\0';                   /* Terminate the string starting at P */
	val = atoi (p); 	/* Convert ASCIIZ string to integer */
	**q = c;			/* Restore the character */

	return ((BYTE) (val > 255 ? 255 : val));

} /* Env CONVNUM */
#endif

#if 0
/****************************** RSTRSTR ***********************************/
// Get rightmost occurrence of s2 in s1.  This is necessary to handle
// expressions like
// if exist c:\dos\mouse.com c:\dos\mouse.com
#error No, this will also screw up c:\dos\mouse /d=c:\dos\mouse.
#error We handle this in READMXMZ.  This code may be useful for something else.
char *rstrstr (char *s1, char *s2)
{
  char *pszRet;

  for (pszRet = NULL; ; s1++) {

	s1 = strstr (s1, s2); // Look for next occurrence
	if (s1) pszRet = s1;
	else break;

  } // for ()

  return (pszRet); // Return rightmost position (or NULL)

} // rstrstr ()
#endif	// if 0

/********************************** FNDEVICE **********************************/
/*  Determine if it is a Device= or Install= line */
#pragma optimize("leg",off)
void fndevice (DSPTEXT *s, FILE *lcfg)
{
	char *h, *np,
		pdrv [_MAX_DRIVE],
		ppath[_MAX_PATH],
		pfnam[_MAX_FNAME],
		pfext[_MAX_EXT],
		buff[256], pathtmp[80];
	char *token, *devpath, *remainder;
	struct {
	int
	  isdevice:1,
	  isinstall:1,
	  isextrados:1,
	  is386load:1;
	} lflags;

	h = str_mem (s->text);	/* Make working copy */
	token = strtok (h, ValPathTerms); /* Get LH or INSTALL, DEVICE */
	/* If LH INSTALL= or DEVICEHIGH is in there, we'll ignore it. */
	/* Since STRIPMGR should have removed it, the user must have */
	/* put it in, and it WILL work with MAX 7. */

	devpath = strtok (NULL, ValPathTerms); /* Get path */

	lflags.isdevice = !_stricmp (token, "device");
	lflags.isinstall = !_stricmp (token, "install");

	/* Ignore line if there's nothing to parse */
	if (!(token && devpath && (lflags.isdevice || lflags.isinstall)))
		goto FNDEV_QUIT;

	/* Set pointer to separator text following "d:\path\filename.exe" */
	/* Note that we want the leftmost occurrence of devpath... */
	remainder = strstr (s->text, devpath) + strlen (devpath);

	/* Split "d:\path\filename.ext" into component parts */
	_splitpath (devpath, pdrv, ppath, pfnam, pfext);

	/* Get combined filename.ext */
	strcpy (buff, pfnam);
	strcat (buff, pfext);

	lflags.is386load = !_stricmp (buff, lflags.isdevice ? LOADERS : LOADERC);
#ifdef HARPO
	lflags.isextrados = !_stricmp (buff, HARPO_EXE);
#else
	lflags.isextrados = 0; /* Assume it's not EXTRADOS.MAX */
#endif

	/* Set length of leading white space, Device=/Install=, */
	/* and white space following that */
	set_nlead (s, devpath);

	/* Ignore lines we've already determined don't belong to us */
	/* unless they're 386LOAD.SYS GETSIZE lines that were relocated */
	/* by the parser callback due to residency.  If this is the case, */
	/* we need to strip 386load getsize prog= */
	if (!s->visible) {

	  if (Pass == 2 && (lflags.isdevice || lflags.isinstall)) {

		if (lflags.is386load) {

		  /* Scan the LOADER line for options */
		  np = scanopts (s, CONFIG);
		  if (np && s->opts.getsize) {

			/* Copy to working buffer */
			strncpy (buff, s->text, s->nlead);

			/* Clobber 386load *prog= */
			strcpy (&buff[s->nlead], np);
			free_mem (s->text);	/* Free the previous copy */
			s->text = str_mem (buff); /* Save as new text line */

		  } /* 386LOAD GETSIZE */

		} /* It's a 386LOAD line */

	  } /* Phase 2, Device or Install with arguments */

FNDEV_QUIT:
	  free_mem (h);
	  return;

	} /* Doesn't belong to our section */

	if (lflags.isdevice) /* Check for "Device=" */
	{
		s->device = DSP_DEV_DEVICE; /* Mark as Device= */
		if (!maxflag)		/* If not already seen, */
			fn386max (s, buff, pdrv, ppath); /* ...check if 386MAX */
	} /* End IF */
	else /* if (lflags.isinstall) */ {
		s->device = DSP_DEV_INSTALL;	/* Mark as Install= */
	} /* End ELSE */

	if (s->max == 0)		/* If it's not 386MAX */
	{
		if (pfnam[0] && 	/* If it's a valid filename, */
		    pfnam[0] != '.' &&
		   (s->device == (BYTE) DSP_DEV_INSTALL /* If it's Install= */
	/* Or if it's Device= following 386MAX */
		|| (maxflag && s->device == (BYTE) DSP_DEV_DEVICE)))
		{
			s->mark = 1;	/* Mark as Device=, or Install= */
			s->max = 2;	/* ...which follows 386MAX */
		} /* End IF */

		/* Check for device drivers which shouldn't be loaded high */
		if ((lcfg && (check_lcfg (devpath, lcfg, 'g') == TRUE ||
		    (s->device == (BYTE) DSP_DEV_INSTALL &&
			check_lcfg (devpath, lcfg, 'a') == TRUE))) ||
			lflags.isextrados)
			s->mark = 0; /* Unmark as device */

		if (lflags.is386load) {

	/* Copy to working buffer */
			strncpy (buff, s->text, s->nlead);
	/* s->text = "  device = c:\386max\386load.sys getsize prog=foo.sys 1 */
	/* buff = "  device = ... */
			if (s->device == (BYTE) DSP_DEV_DEVICE) {
				sprintf (&buff[s->nlead], "%s" LOADERS, LoaderTrue);
			}
			else {
				sprintf (&buff[s->nlead], "%s" LOADERC, LoadTrue);
			}
	/* buff = "  device = C:\386MAX\386LOAD.SYS" */
	/* Scan the LOADER line for options */
			np = scanopts (s, CONFIG);
	/* np = "foo.sys 1" within s->text */
			if (np) 	/* If nothing went wrong */
			{
				if (!s->opts.getsize	/* If not GETSIZE, */
				&& s->opts.prog)	/*  and PROG= found, */
				{
	/*	 set loader switch for P2BROWSE */
					s->opts.loadsw = 1;
	/*	mark as initially third state */
					s->mark = 3;
				} /* End IF */

				strncpy (pathtmp, np, sizeof (pathtmp)-1);
				pathtmp [sizeof(pathtmp)-1] = '\0';
				devpath = strtok (pathtmp, ValPathTerms);
				if (Pass == 2 && !IsResident (devpath)) {
					s->mark = 0; /* Unmark as device */
	/* Clobber 386load *prog= */
					strcpy (&buff[s->nlead], np);
	/* buff = "  device = foo.sys 1" */
				} /* Strip 386LOAD GETSIZE from a nonresident */
				  /* program or UMB */
				else strcat (buff, remainder); /* Copy */
							/* remainder of line */
	/* buff = "  device = C:\386MAX\386LOAD.SYS getsize prog=foo.sys 1" */
	/* Free the previous copy */
				free_mem (s->text);
	/* Save as new text line */
				s->text = str_mem (buff);
			} /* End IF */
	/* Nothing more on line with loader:  Don't mess with it */
	/* as something's wrong */
			else
	/* Unmark as device, etc. */
				s->device = s->mark = s->max = 0;

		} /* End IF */
		else				/* Not 386LOAD */
			if (Pass == 3)		/* If it's pass #3, */
				s->device = s->mark = s->max = 0; /* Unmark as device, etc. */

		/* If the filename matches one in loader .CFG with an L-flag, */
		/* mark it as the CFG file L-flag says the file should be */
		/* loaded low.	Note that the L flag applies both to device */
		/* drivers and to TSRs */
		if (lcfg && check_busm (devpath, lcfg) == TRUE)
		{
			s->busmark = 1;
			s->mark = 4;	/* Mark as initially 4th state */
		} /* End IF */

	} /* End IF */

	s->pdevice = str_mem (strstr (s->text, devpath)); /* Save "foo.sys 1" */
	s->devicen = str_mem (devpath); /* Save "foo.sys" */
	free_mem (h);			/* Free compressed string */

} /* End FNDEVICE */
#pragma optimize("",on)

/*********************************** FN386MAX *********************************/

/*--------------------------------------------------------------*/
/*  Check if device is 386MAX line				*/
/*--------------------------------------------------------------*/

static void fn386max(
	DSPTEXT *s,	/* Text structure */
	char *fext,	/* FILENAME.EXE */
	char *pdrv,	/* drive: */
	char *pdir)	/* \dirname\ */
{
	char buff[80];

	if (_strcmpi (fext, MAXSYS) == 0)
	{
		s->max = 1;		/* Mark as exactly 386MAX */
		maxflag = 1;		/* Mark locally as well */

		/* Combine drive and path for LOADPATH */
		strcpy (buff, pdrv);
		strcat (buff, pdir);
		loadpath = str_mem (buff);

		/* Set length of leading white space and Device=/Install= */
		/* and white space following that */
		/* Note that drive: is not a valid prefix on any line */
		/* in CONFIG.SYS. */
		set_nlead (s, pdrv);

	} /* End IF */

} /* End FN386MAX */

/********************************* DOFILECHK **********************************/
/* Check for required files */
void dofilechk (void)
{
	char *p;

	/* Look in the LOADSTRG directory */
	if (!(chkforfiles (LoadString, 1)))
		return;

	/* Now check the LOADPATH directory */
	/* If not there, ask the user */
	if (!(p = loadpath) || chkforfiles(p, 0))
		p = do_filereq();

	/* If the user pressed ESCAPE, just exit */
	if (AnyError)
		return;

	/* At this point, we've created the names for PREMAXIM and LASTPHASE */
	/* using LOADSTRG.	Switch to using P as LoadString doesn't have */
	/* all our files. */
	strcpy(LoadString,p);
	strcpy (LoadTrue,p);
	truedir (LoadTrue);

	/* Create name of restore batch file and fill in ActiveFiles[PREMAXIM] */
	if (ActiveFiles[PREMAXIM])
		free_mem (ActiveFiles[PREMAXIM]);
	restbatname ();

	/* Create name of lastphase file and fill in ActiveFiles[LASTPHASE] */
	if (ActiveFiles[LASTPHASE])
		free_mem (ActiveFiles[LASTPHASE]);
	lastphasename ();

} /* End DOFILECHK */

/********************************** CHKFORFILES *******************************/

int chkforfiles (char *path, int firstpass)
{
	char buff[128], *p, **f;
	int ret;

	/* Start with the expected path */
	strcpy (buff, path);

	/* Point to the end so we can copy the filename */
	p = stpend (buff);
	ret = 0;
#ifdef HARPO
	if (!maxcfg.noharpo) {
		strcpy (p, HARPO_EXE);
		ret |= fndfile (buff, firstpass);
	} /* NOHARPO not specified */
#endif
	for (f = Essentials; *f; f++) {
		strcpy (p, *f);
		ret |= fndfile (buff, firstpass);
	}
	return (ret);

} /* End CHKFORFILES */

/*********************************** FNDFILE **********************************/
/* Check for specified file.  If it's the first time around, complain. */
int fndfile (char *p, int firstpass)
{
	int ret;

	ret = _access (p, 0);
	if (ret < 0 && firstpass) {
		/*dointcolor*/
		do_intmsg(MsgFileNf,_strupr(p));
	}
	return (ret);

} /* End FNDFILE */

/********************************* STRIP_ENDCRLF ******************************/
/* Strip off leading CR, trailing LF if present */

void strip_endcrlf (char *buff)
{
	int len;

	/* Strip off leading CRs */
	for (len = 0; buff[len] == '\r'; len++)
		buff[len] = ' ';

	/* Strip off trailing LFs */
	len = strlen (buff);
	if (len && buff[len - 1] == '\n')
		buff[len - 1] = '\0';

} /* End STRIP_ENDCRLF */

/********************************* SET_NLEAD **********************************/
/* Calculate # leading chars to preserve in a CONFIG.SYS line */

void set_nlead (DSPTEXT *s, char *pathname)
{
	char buff[256];
	char pbuff[80];
	char *where;

	strcpy (buff, s->text);
	strcpy (pbuff, pathname);
	_strlwr (buff);
	_strlwr (pbuff);
	/* Get the leftmost occurrence of pbuff */
	if (where = strstr (buff, pbuff))	s->nlead = (int) (where-buff);
	else	/* ??? huh ??? */		s->nlead = 0;

#if 0	/* This code won't work with DEVICE/pathname, DEVICE pathname, etc. */
	/* Capture # leading chars to preserve */
	s->nlead = 1 + strchr (s->text, '=') - s->text;

	/* Capture blanks following '=' */
	while (s->text[s->nlead] == ' ')
		s->nlead++;
#endif

} /* End SET_NLEAD */
