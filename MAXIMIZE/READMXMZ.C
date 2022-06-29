/*' $Header:   P:/PVCS/MAX/MAXIMIZE/READMXMZ.C_V   1.3   10 Nov 1995 17:52:22   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * READMXMZ.C								      *
 *									      *
 * Process MAXIMIZE.OUT file						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <dos.h>			// for FINDFIRST function

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>		/* Intermediate message functions */
#include <mbparse.h>

#define READMXMZ_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef READMXMZ_C

#ifndef PROTO
#include <maxsub.pro>
#include "readcnfg.pro"
#include "readmxmz.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

typedef struct _fdate
{
	unsigned ft_day :	5;		//
	unsigned ft_month	:	4;		//
	unsigned ft_year	:	7;		//

} FDATE;

typedef FDATE	*PFDATE;

/* Local variables */
static BATFILE *hbatf[MAXFILES];
static BATFILE *prevbat = 0;
static char    *Date_Sep = "-/.\n";  // Valid Date separators
static int nForceMarked;

/* Local functions are prototyped in readmxmz.pro */

/************************************ READMXMZ ********************************/
#pragma optimize ("leg",off)
void readmxmz (void)

{
	char *p, *cmdpath, *np, buff[256], pathtmp[128];
	int  i, j;
	DSPTEXT *t;
	BATFILE *b;
	FILE *lcfg;
	char pdrv[_MAX_DRIVE],
	ppath[_MAX_PATH],
	pfnam[_MAX_FNAME],
	pfext[_MAX_EXT];

	if (AnyError)
		return;
	readmout();	/* Read MAXIMIZE.OUT and flagged .BAT files */
	if (AnyError)
		return;

	/* Open the loader CFG file */
	disable23 ();
	sprintf (buff, "%s" LOADER ".CFG", LoadString);
	if ((lcfg = fopen (buff, "r")) == NULL) {
		do_warning(MsgLocCfg,0);
		enable23 ();
		AnyError = 1;
		return;
	} /* End IF */

	/*-------------------------------------------------------*/
	/*	For each file found, validate tokens, setup command  */
	/*	tail, etc.					     */
	/*-------------------------------------------------------*/

	for (i = BATFILES ; ActiveFiles[i] ; i++)
	{
		/* Processing %s file */
		do_intmsg (MsgProcFile,ActiveFiles[i]);

		// Walk through the list of MAXIMIZE.OUT lines in their
		// natural order (which should also be LSEG order)
		for (j = 0, t = HbatStrt[i]; t ; j++, t = t->next) {

		  // Since lines within batch files may appear in MAXIMIZE.OUT
		  // in any order (line n+o may come before line n) if
		  // labeled jumps are used, walk through the whole MAXIMIZE.OUT
		  // list each time looking for flagged lines.
		  // Another case where lines may come out of order (or even
		  // twice or more) is where a batch file is run twice,
		  // with some programs going resident on the first pass
		  // and others on the second pass.  Attachmate's EXTRALM.BAT
		  // does this.  ACPMGR does not go resident the second time
		  // around.  We need to ensure we don't blow away the
		  // settings from the first occurrence of ACPMGR if the
		  // first occurrence went resident but the second (or
		  // other subsequent) one did not.
		  for (b = hbatf[i]; b; b = b->next) {

			if (b->flags[0] == '%') {

				// Range marker lines in MAXIMIZE.OUT are
				// slightly different:
				// %	 batfilepath startline endline
				// versus the usual:
				// flags batfilepath line      nlead   command
				// There's no command at the end.
				if (j >= b->line && j <= b->nlead)
					t->visible = 1;

			} // Process range marker
			else if (b->line == j && // If BATPROC has flagged this line
			    (t->mark == DSP_MARK_UNMARKED || // & it's the first
			     resprog (b->flags)) ) // instance or is resident;
			{
				t->devicen = b->command;
				b->batline = t; 	/* Save DSPTEXT ptr for P3UPDATE */
				t->visible = 1; 	/* Mark visible if not already */

				// Check to see if it's a potential UMB loader
				if (p = strchr (b->flags,'-')) {
				 int n;

				 if (*++p == '(')       // Get numeric argument
				  n = atoi(p);
				 else
				  n = 1;

				 if (strchr (b->flags,'&'))
				  n--;			// Decrement if 386LOAD

				 t->umbfailed = (BYTE) n;

				} // '-' flag found

				/* Check flags to determine if the line should be marked */
				if (resprog (b->flags)) {
					char orgline[256];

					/* Skip to resident program */
					strcpy (orgline, np = t->text+b->nlead);

					if (Pass == 3		/* Assume valid if pass 3 */
					    || strchr (orgline, '%')  /* If we're dealing with batch subst */
					    || _strnicmp (orgline, b->command, strlen (b->command)) == 0)
						t->mark = (BYTE) DSP_MARK_GETSIZE;

					/* If it's LOADER, check for PROG= */
					cmdpath = strtok (orgline, ValPathTerms);
					if (t->mark && cmdpath) {

						_splitpath (cmdpath, pdrv, ppath, pfnam, pfext);

						/* strtok() is set up for argument line following LOADER */
						if (_stricmp (pfnam, LOADER) == 0) /* Izit LOADER? */
						{   /* Get length of leading white space and Device=/Install= */

	/* t->text = "    c:\386max\386load getsize prog= c:\foobar.com arf" */
	/* cmdpath = "c:\386max\386load" */
	/* next strtok() --> "options..." */
							strncpy (buff, t->text, b->nlead); /* Copy to working buffer */
	/* buff = "    ... */
							strcpy (&buff[b->nlead], LoadString); /* Followed by loader path */
	/* buff = "    C:\386MAX\" */
							strcat (buff, LOADER);	   /* Followed by loader name */
	/* buff = "    C:\386MAX\386LOAD" */

							np = scanopts (t, i);	   /* Pick off options */
	/* np = " c:\foobar.com arf" within t->text */
							if (np == NULL) {
								/* If SCANOPTS failed, */
								t->mark = (BYTE) DSP_MARK_UNMARKED;		   /* Unmark the line */
								break;		   /* ...and quit */
								// We should do something intelligent with this error condition...
							} /* End IF SCANOPTS failed */

							if (!t->opts.getsize	   /* If not GETSIZE, */
							    && t->opts.prog)	   /*  and PROG= found, */
							{
								t->opts.loadsw = 1;	   /*	set loader switch for P2BROWSE */
								t->mark = (BYTE) DSP_MARK_HIGH;    /* Mark as initially third state */
							} /* End IF */

		/* Copy remainder of line */
							strcat (buff, strstr (t->text + b->nlead, cmdpath) + strlen (cmdpath));
	/* buff = "    C:\386MAX\386LOAD getsize prog= c:\foobar.com arf" */

		/* Free the previous copy */
							free_mem (t->text);

		/* Because we're freeing T->TEXT and NP points into it, */
		/*   we need to reorient NP to the same logical place */
		/*   in T->TEXT. */
		/* Save as new text line */
							t->text = str_mem (buff);
		/* Reset cmdpath to the pathname following "prog=" */
							strncpy (pathtmp, np, sizeof (pathtmp)-1);
							pathtmp[sizeof(pathtmp)-1] = '\0';
							cmdpath = strtok (pathtmp, ValPathTerms);

							np = strstr (t->text + b->nlead, cmdpath);
	/* np = " c:\foobar.com arf" within t->text */

		/* See if the file being loaded by LOADER is in the */
		/* CFG file.  Accommodate bozos who use APPEND= */
		/* because DOS doesn't complain about it. */
							strncpy (buff, np, sizeof(buff-1));
							buff[sizeof(buff)-1] = '\0';
							cmdpath = strtok (buff, ValPathTerms);

							_splitpath (cmdpath, pdrv, ppath, pfnam, pfext);
						} /* End IF LOADER present */

					} /* End IF marked */

					/* If the filename matches one in 386LOAD.CFG with an L-flag */
					/* and a busmastering adapter is present, or if it is flagged */
					/* A in the loader CFG file, load it low. */
					if (check_busm (cmdpath, lcfg) == TRUE)
					{   t->busmark = 1;
					    t->mark = (BYTE) DSP_MARK_WARN;		/* Mark as initially 4th state */
					} /* End IF */
					else if (check_lcfg (cmdpath, lcfg, 'a')) {
					    t->mark = (BYTE) DSP_MARK_UNMARKED; /* Mark as initially low */
					} /* End IF */

					/* Save pointer to text after prog= (if present), */
					/*   start of line if not */
					t->pdevice = str_mem (np);

				} /* End IF resident program */
				else if ((t->umb = (BYTE)umbprog (b->flags)) != 0) {
					/* ???????? */
				}
				else if (remprog (b->flags)) {
					/* If we should REM the line */
					strcpy (buff, "REM ");  /* Start with REM */
					strcat (buff, t->text); /* End with original text */
					free_mem (t->text);	/* Free the previous copy */
					t->text = str_mem (buff); /* Save as new text line */
				} /* End IF/ELSE/IF */

				t->nlead = b->nlead;	/* Get displacement from MAXIMIZE.OUT */
			} // IF (batch line matches)

		  } // End FOR (lines in MAXIMIZE.OUT)

		} // End FOR (lines in batch file)

	} /* End FOR  (all batch files) */

	// Check for unassigned batline - this happens if there's a
	// duplicate nonresident line (as in EXTRALM.BAT)
	for (b = FirstBat; b; ) {

	 if (!(b->batline)) {
		BATFILE *nextb;

		// Unlink it
		if (b->prevbat) b->prevbat->nextbat = b->nextbat;
		if (b->prev) b->prev->next = b->next;
		if (b->nextbat) b->nextbat->prevbat = b->prevbat;
		if (b->next) b->next->prev = b->prev;
		nextb = b->nextbat;
		free_mem (b);
		b = nextb;
	 } // Bogus batline
	 else b = b->nextbat;

	} // end for()

	fclose (lcfg);
	enable23 ();

	/* Find out which files have marked lines */
	nmark = 0;
	memset(marked,0,sizeof(marked));
	for (i = CONFIG; ActiveFiles[i]; i++) {
		DSPTEXT *ts;

		for (ts = HbatStrt[i]; ts; ts = ts->next) {
			if (ts->mark || (i == BATFILES && nForceMarked)) {
				/* If there's one marked */
				marked[nmark++] = i;
				break;
			}
		} /* End FOR/IF */
		if (i == CONFIG) i = BATFILES-1; /* Make a quantum leap */
	}

} /* End READMXMZ */
#pragma optimize ("", on)

/********************************** CHECK_LCFG *********************************/
/* See if the given filename is in the loader CFG file */
/* The filename passed as an argument must match either the entire filename.ext
 * specified in the loader .CFG file, or it must match the filename part */
// This routine is now called with the full pathname in pfname and checks dates

BOOL check_lcfg (char *pfname, FILE *lcfg, char flag)

{
	extern	int	SwappedDrive;
	extern	char	ActualBoot;
	char		cfgbuff[100], *p, *q;
	int		len;
	char		pfnam[ _MAX_FNAME + _MAX_EXT ],
				pfext[_MAX_EXT],
				fullpath[ _MAX_DRIVE + _MAX_PATH + _MAX_FNAME + _MAX_EXT ];
	int	   day , month , year;		// for file date compare
	struct	find_t	finfo;			// file info for findfirst

	_splitpath ( pfname , fullpath , fullpath , pfnam, pfext); // using fullpath as a bogus entry

	strcat( pfnam , pfext );

	strcpy( fullpath , pfname );		// load fullpath

	// At this point pfnam contains the base name,
	//					  fullpath containts the full path and file name

	len = strlen (pfnam);		/* Get its length */
	rewind (lcfg);			/* Start at the beginning */
	while (fgets (cfgbuff, sizeof (cfgbuff) - 1, lcfg) != NULL)
	{      if (cfgbuff[0] == '\0'   /* If it's empty, */
		|| cfgbuff[0] == '\n'   /* ...or the other form of empty, */
		|| strchr (QComments, cfgbuff[0]))   /* ...or a comment, */
		   continue;		/* ...skip this line */

	       p = findwhite (cfgbuff); /* Find white space separator */
	       if (p == NULL)		/* If not present, */
		   continue;		/* ...skip this line */

	       while (iswhite (*p))	/* Skip over white space */
		      *p++ = '\0';      /* ...zapping in the process */

	       q = findwhite (p);	/* Find next white space separator */
	       if (q == NULL)		/* If not present, */
		   continue;		/* ...skip this line */

	       while (iswhite (*q))	/* Skip over white space */
		      *q++ = '\0';      /* ...zapping in the process */

	       if ((strchr (cfgbuff, tolower (flag)) /* If L-flag present */
		 || strchr (cfgbuff, toupper (flag))) /* ...in either case, */
		&& _strnicmp (p, pfnam, len) == 0 /* ...and the file names match */
		&& (p[len] == '.' || p[len] == '\0')) /* ...and we're at the */
					/* end of P OR we match entire basename */
			 {
				p = strtok ( q , Date_Sep );
				year = atoi( p );

				p = strtok ( NULL , Date_Sep );
				month = atoi( p );

				p = strtok ( NULL , Date_Sep );
				day = atoi( p );

				// We may need to change this in 2080, I'll be 110 years old.

				if ( year < 80 )	// if year is ??70 or less
					year+=2000;		// convert it to 20?? format

				if ( year < 100 )	// if year still does not have centuries
					year+=1900;		// convert it to 19?? format

				if ( !(day || month) )		// if there is no date (year could be 2000)
					{
					return (TRUE);	/* Tell the news */
					}

				// otherwise check the files date

				if ( which( fullpath , getenv("PATH") , &finfo) )  // find the file and get its date
					{		// this checks the path (even for CONFIG.SYS stuff)

					if ( day   == (int)(((PFDATE)(&finfo.wr_date))->ft_day ) &&
						  month == (int)(((PFDATE)(&finfo.wr_date))->ft_month ) &&
						  year	== (int)(((PFDATE)(&finfo.wr_date))->ft_year ) + 1980 )
						return (TRUE);	/* Tell the news */
					else
					   continue;
//						return (FALSE); // date compare failed
					}
#ifdef STACKER
				else
					if( SwappedDrive > 0 && ActualBoot != '\0' && fullpath[1]==':' )
						{ // if we are swapping drive, and there is an actual boot, and there is a drive letter in fullpath
						fullpath[0] = ActualBoot;
						if ( which( fullpath , getenv("PATH") , &finfo) )  // find the file and get its date
							{
							if ( day   == (int)(((PFDATE)(&finfo.wr_date))->ft_day ) &&
								  month == (int)(((PFDATE)(&finfo.wr_date))->ft_month ) &&
								  year	== (int)(((PFDATE)(&finfo.wr_date))->ft_year ) + 1980 )
								return (TRUE);	/* Tell the news */
							else
								continue;
//								return (FALSE); // the date compare failed
							}
						}
#endif	// STACKER

					return (TRUE);		// Assume the worst if we cannot locate a dated file

			 }
	} /* End WHILE */

	return (FALSE);
} /* End CHECK_CFG */

/********************************** CHECK_BUSM ********************************/
/* See if the filename matches one in the loader .CFG with an L-flag */

BOOL check_busm (char *pfnam, FILE *lcfg)

{
    if (BusmFlag)		/* If there's a Busmaster, ... */
	/* Compare PFNAM against the L-flag entries in the loader .CFG */
	return (check_lcfg (pfnam, lcfg, 'l'));
    else
	return (FALSE);

} /* End CHECK_BUSM */

/********************************** RESPROG ***********************************/
/* Determine whether or not the flags in MAXIMIZE.OUT indicate */
/* a resident program. */
/* Return 1 if it's resident, 0 if not. */

int resprog (char *flags)

{
	/* If ((not '*') and (not '+') and ('@' or '&')) */
	/* then it's a resident program. */
	return ((strchr (flags, '*') == NULL)
	   && (strchr (flags, '+') == NULL)
	   && (strchr (flags, '@') /* || strchr (flags, '&') */ ));

} /* End RESPROG */

/********************************** UMBPROG ***********************************/
/* Determine whether or not the flags in MAXIMIZE.OUT indicate */
/* a program that allocates UMBs. */
/* Return 1 if so, 0 if not. */

int umbprog (char *flags)

{
	char *pp;

	/* If ('+') then it's a program that allocates UMBs. */
	if (!(pp = strchr (flags,'+'))) return 0;

	/* More than one? */
	if (*(pp+1) == '(') {
		int nn = atoi(pp+2);
		if (nn > 0) return nn;
	}
	return 1;
} /* End UMBPROG */

/********************************** REMPROG ***********************************/
/* Determine whether or not the flags in MAXIMIZE.OUT indicate */
/* a program which should be REMarked out. */
/* Return 1 if it's to be REMmed, 0 if not. */

int remprog (char *flags)

{
	/* If ('^') */
	/* then it's a REMarkable program. */
	return (strchr (flags, '^') != NULL);

} /* End REMPROG */

/********************************* READMOUT **********************************/

void readmout (void)
#define HFILESMAX	40
{
	char *hfiles[HFILESMAX], buff[256+80+20];
	FILE *in;
	int  i, j;
	DSPTEXT *t, *w;

	prevbat = 0;		/* Start at the beginning in case we re-enter */

	memset (hfiles, 0, sizeof(hfiles));
	memset (hbatf, 0, sizeof(hbatf));

	/*-------------------------------------------------------*/
	/*	Read MAXIMIZE.OUT				     */
	/*-------------------------------------------------------*/

	disable23 ();
	sprintf (buff, "%smaximize.out", LoadString);
	if ((in = fopen (buff, "r")) == NULL)
	{
		do_warning(MsgLocMax,0);
		enable23 ();
		AnyError = 1;
		return;
	} /* End IF */

	for (i = 0 ; fgets (buff, sizeof (buff) - 1, in) != NULL &&
			i < HFILESMAX; i++)
	{
		buff[strlen (buff) - 1] = '\0';         /* Zap trailing LF */
		hfiles[i] = str_mem (buff);
	} /* End FOR */

	AnyError = ferror (in);
	if (AnyError)
	{
		do_warning(MsgReadMax,0);
		enable23 ();
		return;
	} /* End IF */

	fclose (in);
	enable23 ();
	/* Parsing MAXIMIZE.OUT file */
	do_intmsg(MsgParsMax);

	/*------------------------------------------------------*/
	/*	Parse MAXIMIZE.OUT				*/
	/*	Note that we need to make two passes, one for	*/
	/*	marked lines and one for range lines.		*/
	/*------------------------------------------------------*/

	// Initialize flag...  It will be set if we snag a startup batch
	// file in prsmxoutl()
	nForceMarked = 0;
	for (j=0; j<2; j++)
	    for (i = 0 ; hfiles[i] && i < HFILESMAX; i++)
		prsmxoutl (hfiles[i], j);

	/*-------------------------------------------------------*/
	/*	For each file found, build a DSPTEXT linked list     */
	/*	containing the text lines			     */
	/*-------------------------------------------------------*/

	for (i = BATFILES ; ActiveFiles[i] && i < MAXFILES; i++)
	{

		HbatStrt[i] = NULL;

		/* Reading ... file */
		do_intmsg(MsgReadFile,_strupr(ActiveFiles[i]));
		if ((in = fopen (ActiveFiles[i], "r")) == NULL)
		{
			/* Error reading ... file, aborting program */
			do_textarg(1,ActiveFiles[i]);
			do_warning(MsgErrRead,0);
			AnyError = 1;
			return;
		} /* End IF */

		while (fgets (buff, sizeof (buff) - 1, in) != NULL)
		{
			strip_endcrlf (buff);	/* Strip off leading CR, trailing LF */

			t = get_mem (sizeof (DSPTEXT));
			t->text = str_mem(buff);

			// Special case: ignore lines starting REM winmaxim~
			// (~ repeated for remainder of line)
			if (!strncmp( buff, "REM winmaxim~", 13 )) {

				char *pszTilde = buff + 13;

				while (*pszTilde == '~') pszTilde++;

				// If this is the unmodified line ignore it
				if (!*pszTilde) t->deleted = 1;

			} // Got a match

			if (HbatStrt[i] == NULL) {
				HbatStrt[i] = t;
			}
			else
			{
				for (w = HbatStrt[i]; w->next; w = w->next)
					;
				t->prev = w;
				w->next = t;
			} /* End ELSE */
		} /* End WHILE */

		AnyError = ferror (in);
		fclose (in);
		if (AnyError)
		{
			/* Error reading ... file, aborting program */
			do_textarg(1,ActiveFiles[i]);
			do_warning(MsgErrRead,0);
			AnyError = 1;
			return;
		} /* End IF */
	} /* End FOR */
} /* End READMOUT */

/*********************************** FINDWHITE ********************************/
/* Find next white space separator */

char *findwhite (char *inp)

{   char *p, *q;

    p = strchr (inp, ' ');              /* Find blank separator */
    q = strchr (inp, '\t');             /* Find tab separator */

    if (p == NULL && q == NULL) 	/* If neither present, */
	return (NULL);			/* ...say so */

    if (p != NULL && q != NULL) 	/* If both present, */
	return (min (p, q));		/* ...return earlier one */

    if (p != NULL)			/* If present, */
	return (p);			/* ...return it */
    else
	return (q);			/* else return other */

} /* End FINDWHITE */

/*********************************** PRSMXOUTL ********************************/
/* Process a line of the MAXIMIZE.OUT file. A list of flagged */
/* lines in the original files is built here, one list per file */
/* There are two basic formats: */
/* flags batfilepath line col commandpath */
/* % batfilepath startline endline */
/* The second form is used to set the visible attribute for each */
/* DSPTEXT record.  This is needed for reordering so we can determine */
/* which lines are ours and which aren't. */
void prsmxoutl (char *p, int rangelines)

{
	char *f;
	BATFILE *t;
	int i;

	if ((p[0] == '%') != rangelines) return;

	f = gflestr (p, 1); /* Get the batch d:\path\filename.ext */

	/* Trundle through each batch file looking for a home */
	for (i = BATFILES ; i < MAXFILES ; i++) {

		/*-----------------------------------------------------*/
		/*	If name not yet processed, add to files array and  */
		/*	build an hbatf structure for the line		   */
		/*-----------------------------------------------------*/

		if (ActiveFiles[i] == NULL)
		{
			if (rangelines) {

			  // If it's the startup batch file, force it to be present
			  // in memory so we can write out the WinMaxim line...
			  if (Pass == 3 && FromWindows) {

				char szName[ _MAX_FNAME ], szName2[ _MAX_FNAME ];

				_splitpath( StartupBat, NULL, NULL, szName, NULL );
				_splitpath( f, NULL, NULL, szName2, NULL );

				if (_stricmp( szName, szName2 )) {

			  		free (f);
			  		return;

				} // Not autoexec.bat, don't force it into list

				nForceMarked = 1;

			  } // Force Autoexec.áat into batch file list
			  else {

			  	free (f);
			  	return;

			  } // Not forcing startup batch file

			} /* Not adding files for ranges */

			ActiveFiles[i] = _strupr (f);	    /* Save as the bat filename */
			hbatf[i] = bldspst (p, f);  /* Allocate current entry */
			break;
		}

	/*-----------------------------------------------------*/
	/*	else build an hbatf structure and add it to the    */
	/*	list of structures for that file		   */
	/*-----------------------------------------------------*/

		else if (_strnicmp (ActiveFiles[i], f, strlen (f)) == 0)
		{
			for (t = hbatf[i] ; t->next ; t = t->next) /* Skip to NULL entry */
				;
			t->next = bldspst (p, f);   /* Allocate current entry */
			t->next->prev = t;
			free_mem (f);
			break;
		} /* End FOR/ELSE */

	} /* for all ActiveFiles[] */

} /* End PRSMXOUTL */

/********************************* BLDSPST ************************************/
/* For a line in MAXIMIZE.OUT, build a BATFILE structure */

BATFILE *bldspst (char *p, char *fnam)

{
	BATFILE *r;

	r = get_mem (sizeof (BATFILE));
	r->flags = gflestr (p, 0);
	if (r->flags[0] != '%') /* No command line for % lines */
		r->command = gflestr (p, 4);
	/* else r->command = NULL; */
	r->line = atoi (gflestr (p, 2));
	r->nlead = atoi (gflestr (p, 3));

	r->prevbat = prevbat;		/* Save as previous entry */
	r->batname = fnam;			/* Save as bat filename */

	/* If there's a previous one, set its next one to the */
	/* current entry */
	if (prevbat)
		r->prevbat->nextbat = r;
	prevbat = r;			/* Copy as new previous entry */

	if (!FirstBat)			/* Save ptr to first .BAT file */
		FirstBat = r;

	return (r);
} /* End BLDSPST */

/*********************************** GFLESTR **********************************/
/* For the above routine, break out the parameters in the line */

char *gflestr (char *p, int cnt)

{
	char hold[15 + 80 + 256];
	/* Because this buffer is called (among other */
	/* times) with a line from MAXIMIZE.OUT, it */
	/* must be large enough to hold the leading */
	/* flags plus surrounding blanks (15), */
	/* a fully-specified d:\path\filename.ext (80), */
	/* plus a DOS OR 4DOS command line. */

TAG:
	for ( ; *p; p++)
		if (*p != ' ')
			break;
	strcpy (hold, p);
	for (p = hold ; *p ; p++)
	{
		if (*p == ' ')
		{
			*p = '\0';
			break;
		}
	}
	if (cnt > 0)
	{
		++p;
		--cnt;
		goto TAG;
	}
	return str_mem (hold);
} /* End GFLESTR */

//*********************************** WHICH *************************************
//Gives fileinfo after searching the path DOS style
//Takes filename , searchpath , &fileinfo structure
int	which( char *filename , char *my_path , struct find_t *finfo )
{
	char		*p,					// pointer to tokenized path
				*dupath,				// duplicate path string for STRTOK'n
				file_to_get[_MAX_FNAME+_MAX_EXT+1],	// hold base name
				path[ _MAX_PATH + 1],			// may hold drive/path
				pfext[ _MAX_EXT ];
	int		length , found=FALSE;

	if ( filename[0] == '\0' )              // If there is no filename to check
		return found;					// exit with FALSE

	dupath = _strdup ( my_path );	// copy path

	found = check_file( filename , finfo ); 	// check given file name

	if (!found)					// if the file was found, don't was time
		{
		_splitpath ( filename , path, path, file_to_get , pfext);
		strcat( file_to_get , pfext);
		p = (char *) strtok( dupath , ";" );           // Get the first path
		}

	while ( !found && p != NULL )	       // while we have no hits, and there is a path left
		{
		strcpy( path , p );

		if( path[ (length=strlen(path)-1) ] != '\\' )           // not everyone puts a trailing backslash
			{
			path[ ++length ]='\\';
			path[ ++length ]='\0';
			}

		strcat( path , file_to_get );

		found = check_file( path , finfo );

		p = (char *) strtok( NULL , ";" );              // Get the next path
		}

	free( dupath );

	return found;

}

//********************************  CHECK FILE ***************************
// check to see if the file, or any .BAT.COM.EXE variants are around
// This routine will check to see if the filename has an extension
// and if not will look for .COM/.EXE/.BAT if there is an extension
// it will only check for the specified filename
// RETURNS: TRUE if file was found, findt_t structure is filled

int check_file(char *fullpath , struct find_t *finfo )
{

	char		buff[ _MAX_DRIVE + _MAX_PATH + _MAX_FNAME + _MAX_EXT ];
	int		length;

	if ( (char *) strchr( fullpath , '.') != NULL ) // are there any '.'s?
		{
			if ( 0 == _dos_findfirst( fullpath , _A_NORMAL , finfo))  // if there a file?
				return TRUE;
		}
	else
		{	// if there was no extension on the file.

		// Check for .COM first
		strcpy( buff , fullpath );
		length = strlen( buff );			// save length for later
		strcat( buff , ".COM");
		if ( 0 == _dos_findfirst( buff , _A_NORMAL , finfo))  // if there a file?
			return TRUE;

		// check for .EXE
		buff[ length ] = '\0';
		strcat( buff , ".EXE");
		if ( 0 == _dos_findfirst( buff , _A_NORMAL , finfo))  // if there a file?
			return TRUE;

		// check for .BAT
		buff[ length ] = '\0';
		strcat( buff , ".BAT");
		if ( 0 == _dos_findfirst( buff , _A_NORMAL , finfo))  // if there a file?
			return TRUE;
		}

	return FALSE;			// if nothing found, tell bad news
}
