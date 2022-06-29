/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PARSE.C_V   1.2   26 Oct 1995 21:53:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-94 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PARSE.C								      *
 *									      *
 * Parsing modules							      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>
#include <process.h>
#include <fcntl.h>
#include <io.h>
#include <stdarg.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>		/* Intermediate message functions */
#include <mbparse.h>		/* MultiBoot parse functions */

#define PARSE_C
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef PARSE_C

#if SYSTEM != MOVEM		/* Only needed for AUTOBCF */
#include <bioscrc.h>		/* Get BIOS CRC functions */
#endif				/* SYSTEM != MOVEM */

#ifndef PROTO
#include "copyfile.pro"
#include "linklist.pro"
#include "maximize.pro"
#include <maxsub.pro>
#include "parse.pro"
#include "profile.pro"
#include "readcnfg.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */

/*  Structure used for parsing */
/* */
/*  NEXTSTR ==> initially original string, then comma-delimited portion */
/*  COMMENT ==> original comment (never changed) */
/*  ORIGSTR ==> if (profile) original string (never changed) */
/*		if (maxsys)  moving pointer through the line */

typedef struct _parse_t {
	BYTE delim,		/* Delimiter following keyword */
	*nextstr,		/* Ptr to next string to process */
	*comment,		/* Ptr to comment (NULL if none) */
	*origstr;		/* Ptr to uncompressed line */
} PARSE_T;

static char *dlim = "= ,-";

PARSE_T pcfg, ppro;

/*********************************** PARSECFG *********************************/
/*  Parse 386MAX line */

void parsecfg (char *maxline, DSPTEXT *dt)
{
	char *maxparm;

	/* Tell 'em what we're doing */
	do_intmsg(MsgParsParm,MAXSYS);

	/* Strip off the "d:\path\386max.sys" */
	maxparm = strpbrk (maxline, " \t");

	if (!maxparm)				/* If no parameters, */
	  return;				/* ...return */

	parse (dt, maxparm, dlim, &pcfg, 0);	 /* Get first token on line */

	while (pcfg.delim != '\0')                  /* If we're not done. */
		parse (dt, NULL, dlim, &pcfg, 0); /* ...keep on truckin' */

	/* Case where no profile exists is handled by caller */

} /* End PARSECFG */

/*********************************** NEWPRO ***********************************/
/* Create new profile */

void newpro (DSPTEXT *dt)		/* Save profile name in DT->PROFILEN */

{
	char buff[80], *p;
	char bdrive[_MAX_DRIVE],bname[_MAX_FNAME],bext[_MAX_EXT];
	int cnt = 0;

#define PROLIM 100

	/* Create the profile */
	/* Tell 'em what we're doing (Creating %s profile) */
	sprintf (buff, MsgCreatProf, PRODNAME);
	do_intmsg (buff);

	sprintf (buff, "pro=%s%s.PRO", LoaderDir, PRODNAME);
	p = 1 + strchr (buff, '=');         /* Skip over leading PRO= */
	while (cnt < PROLIM)
		if (_access (p, 0) < 0)		/* If not found, */
		{
			createfile (p); 		/* ...create it */
			break;
		} /* End IF */
		else
			sprintf (p, "%s%s.P%02d", LoaderDir, PRODNAME, ++cnt);

	if (cnt == PROLIM)			/* If we're at our limit, */
		do_error(MsgProLim, TRUE);	/* ...display error message and abort */

	ActiveFiles [PROFILE] = str_mem (p); /* Save form we can use NOW */

	if (cnt) {				/* Create 386max.p## */
		sprintf (p, "%s%s.P%02d", LoaderTrue, PRODNAME, cnt);
	}
	else {					/* Create 386max.pro */
		sprintf (p, "%s%s.PRO", LoaderTrue, PRODNAME);
	}

	dt->profilen = str_mem (p);	/* Save original form */
	_splitpath (dt->profilen, bdrive, buff, bname, bext);
	ProfilePath = ProfileBoot = get_mem (strlen (buff) + strlen (bdrive)+1);
	sprintf (ProfileBoot, "%s%s", bdrive, buff);


} /* End NEWPRO */

/*********************************** PARSEPRO *********************************/
/*  Parse 386MAX.PRO file */

void parsepro (DSPTEXT *dt, char *proname)

{
	char buff[256];
	FILE *in;

	disable23 ();
	if ((in = fopen (proname, "r")) == NULL)
	{
		/* Error opening %s file */
		do_intmsg (MsgErrOpen, proname);
		AnyError = 1;
		return;
	} /* End IF */

	/* Parsing %s file */
	do_intmsg (MsgParsFile, proname);

	/* Parse each line */
	while (fgets (buff, sizeof (buff) - 1, in) != NULL)
		parse (dt, buff, dlim, &ppro, 1); /* Get first token on line */

	fclose (in);
	enable23 ();
} /* End PARSEPRO */

/*********************************** PARSE ************************************/
/*  Get tokens from string */
/* If a string is specified, we parse it for a Multiboot section name. */
/* If we find one, we save the OwnerID.  We'll completely parse a line */
/* only if it's in the current or common section of the profile. */
#pragma optimize("leg",off)
void parse (
	DSPTEXT *dt,	/* Save profile name in DT->PROFILEN */
	char *str,	/* If (str != NULL) build STU */
	char *dlim,	/* Delimiters */
	PARSE_T *stu,	/* If (str == NULL) STU = parse structure */
	int cfgpro)	/* 0 = from 386MAX.SYS line, 1 = from profile */
{
	char *stp, *stq, *p, *q, c, buff[80];
	char bdrive[_MAX_DIR],bname[_MAX_FNAME],bext[_MAX_EXT];
	int len, ndx, i, j;
	CONFIG_D *qd;
	static BYTE LastOwner = 0; /* Current section */
	SECTNAME *SRec;
	char *sectname = NULL;

	/* Make sure we have a default owner */
	if (!LastOwner) LastOwner = CommonOwner;

	/* When a string is passed, build parsing structure */
	if (str != NULL)
		/*-----------------------------------------------------*/
		/*  Duplicate any comment portion of string into       */
		/*  ->COMMENT and put the original string (without the */
		/*  comment) into ->ORIGSTR.			       */
		/*-----------------------------------------------------*/
	{
/*		if (MultiBoot) { */ /* Note that we may have MultiConfig */
				/* sections in profiles without MenuItems */
		  if (sscanf (str, "%80s", bdrive) && bdrive[0] == '[') {
		    /* Get actual name */
		    /* We'll ignore all sections other than common if */
		    /* MultiConfig is not active */
		    if ((sectname = strtok (bdrive, "[]")) &&
			(SRec = find_sect (sectname))		)
			    LastOwner = SRec->OwnerID;
		    else LastOwner = 0xff; /* Ignore bogus sections */
		  } /* Found a line beginning with [ */
/*		} */ /* MultiBoot active */

		stp = strpbrk (str, QComments);

		if (stp) {

#if SYSTEM != MOVEM
			/* If it's an active comment for failed ROMSRCH, */
			/* nuke it */
			if (!strncmp (stp,ProbeID,PROBESORRYLEN) &&
							stp == str) {

				stu->comment = MsgSeeMaxCfg;

				if (!maxcfg.noromsrch) {
					add_maxcfg (CfgNoROMSRCH,
							CfgNoROMSRCH_Fail);
				} /* NOROMSRCH not already in MAXIMIZE.CFG */

				maxcfg.noromsrch = 1;

			} /* Active comment for failed ROMSRCH found */
			else
#endif	/* SYSTEM != MOVEM */
				stu->comment = NULL;

			/* If there's a comment */
			while (stp > str		/* If we're in mid-string */
			       && (stp[-1] == ' '       /* Skip back over blanks */
			       || stp[-1] == '\t'))     /* ...and tabs */
				stp--;			/* which precede the comment */
			if (!stu->comment) stu->comment = str_mem (stp);
			c = *stp;			/* Save the original character */
			*stp = '\0';                /* Remove comment from STR */
			if (stp > str)		/* If there's anything left, */
				stu->nextstr = stu->origstr = str_mem (str); /* ...duplicate it */
			else			/* Otherwise, */
				stu->nextstr = stu->origstr = NULL; /* ...zap it */
			*stp = c;			/* Restore the original character */
		} /* End IF comments found */
		else
		{
			stu->comment = NULL;	/* Mark as no comment */

			/* Ensure STR doesn't end with a LF */
			len = strlen (str);
			if (len && str[len - 1] == '\n')
				str[len - 1] = '\0';

			stu->nextstr = stu->origstr = str_mem (str);

		} /* End IF comments / ELSE no comments */

	} /* End IF str != NULL */

	/* STU points to a valid structure with NEXTSTR, ORIGSTR, and COMMENT set */
	/* Fill in the DELIM and SADDR/EADDR (if any) fields */

	stp = skipwhite (stu->nextstr); /* Skip over leading white space */

	len = strcspn (stp, dlim);		/* Find delimiter */
	if (len == 0 || sectname)		/* If none or MultiConfig, */
	{
		strcpy (buff, stp);		/* ...use the whole string */
		stu->delim = '\0';              /* Mark as no delimiter */
		stp = stpend (stp);		/* Skip to the end of the string */
	} /* End IF */
	else
	{
		stq = skipwhite (stp + len);	/* In case the delimiter is ' ' */
		strncpy (buff, stp, len);	/* Copy just the keyword */
		stu->delim = *stq;		/* Copy the delimiter */
		buff[len] = '\0';               /* Ensure properly terminated */
		if (*stq == '=')                /* If the delimiter is '=', */
			stp = stq + 1;		/* ...skip over it */
		else				/* Otherwise, */
			stp += len;		/* ...skip to other delimiter */
	} /* End IF/ELSE */

	/* STP points to the character following the "keyword" or "keyword=" */

	/* Strip off trailing white space */
	len = strlen (buff);
	while (len--)
		if (iswhite (buff[len]))
			buff[len] = '\0';
		else
			break;

	/* Search for the keyword only if it belongs to us */
	/* This is an easy way to ignore lines we don't own, but */
	/* we still need to save the LastOwner value so we can */
	/* distinguish ActiveOwner lines from CommonOwner. */
	ndx = 0;
	if (/* !MultiBoot || */ /* LastOwner is always CommonOwner */
		 LastOwner == ActiveOwner || LastOwner == CommonOwner)
	  for (ndx = 0, i = 1 ; Options[i].name ; i++) {
		j = strlen (Options[i].name);

		/* Shorten name if list entry contains delimiter */
		j -= (Options[i].name[j - 1] == '=');

		if (_strnicmp (buff, Options[i].name, j) == 0 &&
		    !isalnum(buff[j]))
		{
			ndx = i;
			break;
		} /* End IF */
	  } /* End IF / FOR */

PARSE_COMMA:
	/* Allocate space for this structure */
	qd = get_mem (sizeof (CONFIG_D));

	qd->comment = stu->comment;	/* Use original comment */
	qd->etype = Options[ndx].etype; /* Save the enum type */
	qd->origstr = stu->origstr;	/* Use original string */
	qd->Owner = LastOwner;		/* Owner of this line */

	/* If keyword found, split cases based upon option argument type */
	if (ndx && (stu->delim == '=' || stu->delim == ','))
	{
		switch (Options[ndx].atype)
		{
		case HEXADDR:		/* xxxx-yyyy -- Two DWORD hex parms */
			stp = skipwhite (stp);
GOTO_HEXADDR:
			stp = scanlhex (stp, &qd->saddr); /* Scan off hex DWORD */
			stp = skipwhite (stp);
			stp++;		/* Skip over '-' */
			stp = skipwhite (stp);
			stp = scanlhex (stp, &qd->eaddr); /* Scan off hex DWORD */
			if (Options[ndx].etype == NOSCAN) {
				/* Copy any NOSCAN statements to MAXIMIZE.CFG */
				WORD block, eblock;

				/* RAMTAB is in units of 4K */
				block = (WORD) ((qd->saddr - 0xA000L) >> 8);
				eblock = (WORD) ((qd->eaddr - 0xA000L) >> 8);
				if (eblock < block || eblock >= 384/4) break;

				for ( ; block < eblock; block++) {
				    if (!(RAMTAB[block] & RAMTAB_UNK)) {
					while (block < eblock) {
						RAMTAB[block++] |= RAMTAB_UNK;
					}
					add_maxcfg (qd->origstr,
							qd->comment ?
								qd->comment :
								MsgOptCopied);
					break;
				    } /* End if () */
				} /* End for () */
			} /* End if (NOSCAN) */

#if SYSTEM != MOVEM
			/* If any USE= statements infringe on the system ROM, */
			/* force NOROMSRCH unless it's a PCI system. */
			if (Options[ndx].etype == USE &&
				qd->eaddr > (DWORD) SysRom) {

			  if (maxcfg.PCIBIOS || !maxcfg.PCIBIOS_flag) {

			    if (!maxcfg.noromsrch &&
				qd->eaddr > (DWORD) SysRom) {
					maxcfg.noromsrch = 1;
			    } /* Didn't find NOROMSRCH, but there's a USE= */
			      /* in the system ROM area */

			  } /* PCIBIOS in MAXIMIZE.CFG */ else {

			    /* Strip this option */
			    qd->etype = NULLOPT;

			  } /* PCIBIOS not in MAXIMIZE.CFG and PCI local bus */
			} /* End if (USE) */
#endif	/* SYSTEM != MOVEM */

			break;

		case ONEHEXADDR:		/* xxxx -- One DWORD hex parameter */
			stp = skipwhite (stp);
			stp = scanlhex (stp, &qd->saddr); /* Scan off hex DWORD */
			break;

		case NUMADDR:		/* dddd -- One DWORD Decimal parameter */
			stp = skipwhite (stp);
			stp = scanldec (stp, &qd->saddr); /* Scan off dec DWORD */
			break;

		case POSNAME:		/* d:\path\filename.ext */
			stp = skipwhite (stp);
			stp = skipblack (stp); /* Skip over file id */
			break;

		case ADDRLIST:		/* [xxxx],[yyyy],[zzzz] */
			while (*stp && *stp != ';') {
			  stp = skipblack (stp); /* Skip over arg list */
			  stp = skipwhite (stp); /* Skip whitespace */
			}
			break;
#if SYSTEM != MOVEM
		case BCFNAME:		/* d:\path\filename.ext */
			stp = skipwhite (stp);
			stq = skipblack (stp);
			c = *stq;		/* Save character */
			*stq = '\0';           /* Zap it to terminate string */
			process_BCF (stq);	/* Proces BCF file */
			*stq = c;		/* Restore character */
			stp = stq;		/* Move pointer ahead */

			break;
#endif /* SYSTEM != MOVEM */
		case OPTADDR:		/* xxxx-yyyy or dddd */
			stp = skipwhite (stp);
			p = strchr (stp, '-'); /* Find position of '-' */
			if (!p) 	/* If not present, */
				p = stpend (stp);	/* ...set to EOS */
			q = strchr (stp, ' '); /* Find position of ' ' */
			if (!q) 	/* If not present, */
				q = stpend (stp);	/* ...set to EOS */
			if (p < q)		/* If '-' precedes ' ' */
				goto GOTO_HEXADDR; /* Treat as two hex addresses */
			else
				stp = scanldec (stp, &qd->saddr); /* Scan off dec DWORD */
			break;

		case OPTSIZE:		/* XBDAREG=[size,]reg */
			stp = skipwhite (stp);
			p = strchr (stp, ','); /* Find position of ',' */
			qd->saddr = 0L;
			stp = scanldec (stp, p ? &qd->saddr : &qd->eaddr);
			if (p) stp = scanldec (p+1, &qd->eaddr);
			break;

		case PROADDR:
			stp = skipwhite (stp);
			stq = skipblack (stp);

			c = *stq;		/* Save character */

			if (!*stp)
				break;		/* Ignore pro= with no arg */

			*stq = '\0';           /* Zap it to terminate string */

			/* If not readable, display warning but continue */
			if (_access (stp, 0)) {

				do_intmsg (MsgErrOpen, stp);
				*stq = c;	/* Restore character */
				stp = stq;	/* Advance pointer */
				break;		/* Ignore bogus pro= arg */

			} /* File did not exist */

			/* Save the original form to _write back to CONFIG.SYS */
			dt->profilen = str_mem (stp);

			/* Get the path used for the profile */
			_splitpath (stp, bdrive, buff, bname, bext);

			/* Get space for profile path with boot drive; */
			/* reserve space for drive letter + ':' */
			ProfileBoot = get_mem (strlen (bdrive) + 3 + strlen (buff));
			/* Skip space reserved for drive letter + ':' */
			ProfilePath = ProfileBoot + 2;
			sprintf (ProfilePath, "%s%s", bdrive, buff);

			/* If no drive letter specified, use the boot drive */
			if (!*bdrive) {
			 sprintf (buff, "%c:%s", BootDrive, stp);
			 stp = buff;
			 ProfileBoot[0] = (char) BootDrive;
			 ProfileBoot[1] = ':';
			}
			else
			 ProfileBoot += 2;	/* Skip reserved unused space */

			ActiveFiles[PROFILE] = str_mem (stp);

			parsepro (dt,ActiveFiles[PROFILE]);
						/* Parse the profile */
			*stq = c;		/* Restore character */
			stp = stq;		/* Move pointer ahead */

			break;

		} /* End SWITCH */
	} /* End IF */
	else				/* Skip to next keyword */
		if (stu->delim == '=')
			if (cfgpro == 1)			/* If we're in the profile */
				stp = stpend (stp);		/* Skip to the end of the line */
			else				/* Otherwise, skip to next token */
			{
				stp = skipwhite (stp);		/* Skip over white space after '=' */
				len = strcspn (stp, dlim);	/* Find next delimiter */
				stp += len + (stp[len] != '\0'); /* Skip over it unless EOL */
			} /* End IF/IF/ELSE */

	/* At this point, STP points to the character */
	/* after the end of the parameters */
	/* It might point to " , xxxx - yyyy..." */
	/*		      or "   keyword..." */

	/* Skip over trailing white space */
	stq = skipwhite (stp);

	/* Detect comma-delimited fields */
	switch (*stq)
	{
	case ',':
		stq = skipwhite (stq + 1); /* Skip over white space after ',' */
		stu->delim = ',';      /* Save for later use */
		break;

	case '\0':
		stu->delim = '\0';     /* Mark as EOL */
		break;

	default:
		stu->delim = ' ';      /* Mark as another blank */
		break;

	} /* End SWITCH */

	*stp = '\0';                        /* Terminate the last field */
	stp = stq;				/* Skip to next keyword */

#if SYSTEM != MOVEM
	/* If it's AUTOBCF, calculate the CRC, then try to _open BCF file */
	/* to get start of BIOS. */
	if (Options[ndx].etype == AUTOBCF) {
	 sprintf (buff, "%s@%04x.BCF", LoadString, Get_BIOSCRC());
	 process_BCF (buff);
	 /* If the BCF file isn't there, clobber AUTOBCF */
	 if (!BcfInstalled) goto Ignore_option;
	} /* AUTOBCF */
#endif
	/* Link this structure into profile list unless it's the profile */
	/*	or POSFILE; also remove IGNOREFLEXFRAME on pass 3 */
	if (Options[ndx].etype != PRO
	    && Options[ndx].etype != POSFILE
	    && (Pass != 3 || Options[ndx].etype != IGNOREFLEXFRAME))
		addtolst (qd, CfgTail);

#if SYSTEM != MOVEM
Ignore_option:
#endif
	/* If we're in a comma-delimited range, go around again */
	if (stu->delim == ',')
		goto PARSE_COMMA;		/* Go around again */

	/* Save pointer to next string to process */
	stu->nextstr = stp;

	if (cfgpro == 0)			/* If we're on 386MAX.SYS line, */
		stu->origstr = stu->nextstr;	/* ...copy next as original string */
} /* End PARSE */
#pragma optimize("",on)

#if SYSTEM != MOVEM
/**************************** PROCESS_BCF **********************************/
/* Process specified BCF filename.  */
/* If the file BCF.DEL exists in the MAX directory, it's a listing of */
/* BCF files that were extracted during installation.  Delete 'em and */
/* then delete the file. */
void process_BCF (char *bcf_filename)
{
 int fh;
 BCFH bcfh;
 char szDlist[128], szFname[128];
 FILE *pDlist;

	fh = _open (bcf_filename, O_RDWR|O_BINARY); /* Attempt to open the BCF */
	if (fh != -1)		/* If it's valid, ... */
	{
		_read (fh, &bcfh, sizeof(BCFH)); /* Read in the BCF header */

		/* Calculate the starting segment of the system ROM */
		SysRom = 0xF000 /* from F000 */
			+ ((bcfh.boff /* starting segment in bytes */
			& 0xF000) /* rounded down to 4KB boundary */
			>> 4);	/* and converted from bytes to paras */

		_close (fh);	/* Close the file */
		BcfInstalled = 1; /* Mark as present */

	} /* End IF */

	sprintf (szDlist, "%sBCF.DEL", LoadString);
	if (pDlist = fopen (szDlist, "r")) {

	  while (fscanf (pDlist, "%s\n", szFname) != EOF) {

	    if (truename_cmp (szFname, bcf_filename))
			_unlink (szFname);

	  } /* not end of BCF.DEL */

	  fclose (pDlist);
	  _unlink (szDlist);

	} /* Opened BCF.DEL file */

} /* process_BCF */
#endif /* SYSTEM != MOVEM */

#if SYSTEM != MOVEM
/***************************** DO_PROBE ***********************************/
/* If BCFFLAG is nonzero, return.
 * If NOROMSRCH exists in MAXIMIZE.CFG or USE= statements were found
 *  above the start of system ROM, return.
 * If ROMSRCH.COM does not exist in MAXIMIZE directory, return.
 * Ask user if we should execute PROBE; if no, return.
 * Add NOROMSRCH to MAXIMIZE.CFG with the "deadman switch" comments
 * Redirect STDOUT, execute PROBE, and _read results.
 * Remove NOROMSRCH from MAXIMIZE.CFG
 * If PROBE returned errorlevel > 0, ignore results and return.
 * If PROBE returns "Sorry, PROBE..." add NOROMSRCH to MAXIMIZE.CFG
 *  and return.
 * Append all PROBE lines not intersecting with RAM= statements to MAX.PRO
 * Split all PROBE lines partially intersecting with RAM= statements into
 *  intersecting and non-intersecting portions.  Add the non-intersecting
 *  portions to MAX.PRO; make the intersecting portions into comments
 *  such as "; PROBE found F400-F500 unused but respected existing RAM
 *  statement(s)."
 */

void  do_probe(void)
{
	int probeout, oldstdout;
	int res;
	FILE *probefile;
	char probe[_MAX_PATH],buff[256];
	unsigned int ustart, uend, i;
	unsigned long ubits, rambits;
	int udprofile;
	PRSL_T *p;

	/* If PCIBIOS is not in MAXIMIZE.CFG and we have a PCI local bus */
	/* machine, we've stripped out USE= statements this time around */
	/* regardless of the NOROMSRCH state.  Add PCIBIOS so we don't */
	/* do this again. */
	if (!maxcfg.PCIBIOS && maxcfg.PCIBIOS_flag) {

		maxcfg.noromsrch = 0; /* Yes, we should run ROMSRCH again */
		maxcfg.PCIBIOS = 1; /* Now PCIBIOS is in MAXIMIZE.CFG */
		add_maxcfg (MsgPCIBIOS, "");

	} /* We have a PCI local bus machine without PCIBIOS in MAXIMIZE.CFG */

	/* If BCFFLAG, COMPROM, or noromsrch are nonzero, return. */
	if (BcfFlag || CompROM || maxcfg.noromsrch)
		return;

	/* If PROBE.COM does not exist in MAXIMIZE directory, return. */
	sprintf (probe, "%s" PROBECOM, LoadString);
	if (_access (probe, 0))
		return;

	/* Ask user if we should execute PROBE; if no, return. */
	if (!ask_probe () || AbyUser)
		return;

	/* Executing %s */
	do_intmsg (MsgExecuting, probe);

	/* If I die before I wake, at least don't make me run ROMSRCH again */
	add_maxcfg (CfgNoROMSRCH, CfgNoROMSRCH_Hang);

	/* Redirect STDOUT, execute PROBE, and _read results. */
	sprintf (buff, "%s" PROBEOUT, LoadString);
	if (_dos_creat (buff, 0, &probeout))
		return;

	oldstdout = _dup (STDOUT);  /* Save original STDOUT handle */
	_dup2 (probeout, STDOUT);   /* Redirect stdout for PROBE */
	_dos_close (probeout);	   /* Free handle */

	/* Save the screen, then clear it */
	intmsg_save();
	cstdwind();

	disable23 ();		/* Disable MAXIMIZE Ctrl-Break handler */

	res = _spawnl (P_WAIT, probe, probe, RomsrchOpts, NULL);

	_dup2 (oldstdout, STDOUT);  /* Restore STDOUT & _close redirected file */
	_dos_close (oldstdout);    /* Free handle used to save old STDOUT */

	enable23 ();		/* Enable Ctrl-Break handler */

	/* Restore screen */
	istdwind();
	paintback();
	showAllButtons();
	showQuickHelp(QuickRefs[Pass-1]);
	intmsg_restore();

	// Remove NOROMSRCH from MAXIMIZE.CFG in case the user reboots
	// when they see the "ROMSRCH done" message
	del_maxcfg ("NOROMSRCH");

	// Display ROMSRCH done message
	message_panel (MsgROMSrch2, 0);

	/* If PROBE returned errorlevel > 0, ignore results and return. */
	if (res)
		return;

	/* Open PROBE output file for input; _open MAX.pro for append */
	sprintf (buff, "%s" PROBEOUT, LoadString);
	if ((probefile = fopen (buff, "r")) == NULL) return;

	/* Parsing PROBE.OUT file */
	do_intmsg (MsgParseProbe, LoadString);

	/* Create a 32-bit bitmap with one bit for every 4K */
	for (	rambits=0, p = CfgHead; p != NULL; p = p->next) {
		if (p->data->etype == RAM)
			rambits |= map_segment (ROMBASE, p->data->saddr, p->data->eaddr);
	}

	udprofile = 0;
	res = 0;		// Keep track of the number of regions we get

	while (fgets (buff, sizeof (buff) - 1, probefile) != NULL) {

		if (udprofile++ == 0) {
			/* Updating %s.SYS parameters */
			do_intmsg (MsgUpdateSys, PRODNAME);
		} /* Updating profile */

		if (_strnicmp (buff, "USE=", 4) != 0)
			continue;

		/* Append all PROBE lines not intersecting with RAM= statements to MAX.PRO */
		sscanf (buff, "%*[A-Za-z]%*[ =]%x%*[ -]%x", &ustart, &uend);

		if ((rambits & (ubits = map_segment (ROMBASE, ustart, uend))) == 0L) {
			sprintf (buff, ProbeUse, ustart, uend, (uend-ustart) >> (8-2));
			add_to_profile (USE, buff, ustart, uend);
			res++;

		} // No overlap
		else {

			if ((rambits & ubits) == ubits) {
				/* Complete intersection; tell 'em tough bananas */
				sprintf (buff, ProbeComment, ustart, uend);
				add_to_profile (USE, buff, 0L, 0L);

			} /* Complete intersection */
			else {
				/* Split all PROBE lines partially intersecting with RAM= statements */
				for (i=(ustart&0x1F00) >> 8; ubits & (1L << i) && i < ROMPAGES; i++) {

					ustart = ROMBASE | (i << 8);
					uend = ustart + 0x0100;

					if (rambits & (1L << i)) {

						for ( ; i < ROMPAGES && (ubits & (1L << (i+1))) && (rambits & (1L << (i+1)));	i++)
							    uend += 0x0100;

						sprintf (buff, ProbeComment, ustart, uend);
						add_to_profile (USE, buff, 0L, 0L);

					} /* Intersected with RAM= */
					else {

						for ( ; i < ROMPAGES && (ubits & (1L << (i+1))) && (rambits & (1L << (i+1))) == 0L;    i++)
							    uend += 0x0100;

						sprintf (buff, ProbeComment, ustart, uend);
						add_to_profile (USE, buff, 0L, 0L);

					} /* Did not intersect with RAM= */

				} /* for () */
			} /* Intersection of USE= and RAM= was partial */
		} /* USE= from PROBE intersected with RAM= statement(s). */

	} /* while not EOF (probe output) */

	/* Close files */
	fclose (probefile);

	if (res) replace_in_profile (IGNOREFLEXFRAME, MsgIgnoreFlex, 0L, 0L);

	/* If we didn't find anything, put NOROMSRCH in MAXIMIZE.CFG. */
	/* If we did, the USE= statements above system ROM will prevent */
	/* us from running ROMSRCH again for this Multiboot section. */
	if (!res) add_maxcfg (CfgNoROMSRCH, CfgNoROMSRCH_Fail);

} /* End do_probe () */
#endif	/* SYSTEM != MOVEM */

#if SYSTEM != MOVEM
/**************************** MAP_SEGMENT *************************************/
/* Convert a range consisting of two paragraph values into a dword of bits */
/* representing 4K chunks at the specified starting address. */
unsigned long map_segment ( unsigned int base,
		unsigned long start,
		unsigned long end)
{
	unsigned long res = 0L;

	if (end > base && end > start) {

	if (start < base)	/* Make sure range is meaningful */
		start = base;

	if ((end & 0xff) == 0L)   /* If it ends on a 4K boundary, decrement end */
		end--;

	start = (start - base) >> 8;	    /* Make 'em 0-based */
	end = (end - base) >> 8;

	for (res = 1L << start; start < end; start++)
		res |= res << 1;	/* Duplicate bits */

	} /* end > base */

	return (res);

} /* End map_segment () */
#endif	/* SYSTEM != MOVEM */

#if SYSTEM != MOVEM
/************************** DO_VGASWAP ***********************************/
// If VGASWAP is not already in the profile and we meet all the criteria,
// add it.  If we add it, make sure IGNOREFLEXFRAME is in the profile.
void do_vgaswap (void)
{
 PRSL_T *p;
 char work[80];
 int res;

 // If NOVGASWAP is in the MAXIMIZE.CFG file, don't do it
 if (maxcfg.novgaswap)
	return;

 /* If it's any system capable of BIOS compression (e.g. it has a 128K ROM)
	VGASWAP is a big no-no */
 if (Is_BCF())
	return;

 // Izit already in the profile?
 // Is NOROM specified?
 for (	p = CfgHead; p != NULL; p = p->next)
	if (p->data->etype == VGASWAP || p->data->etype == NOROM)
	 return;

 // Test for eligibility by running XLAT /t
 sprintf (work, "%s" XLATCOM, LoadString);
 if (res = _spawnl (P_WAIT, work, work, "/t", NULL)) {

	 if (res == -1 && errno) {

	  do_intmsg (MsgExecErr, work);

	 } // Unable to exec
	 else { // Check to see if we should update MAXIMIZE.CFG

	  if (!maxcfg.novgaswap) {

		add_maxcfg (CfgNoVS_Xlat, "");

		if (FromWindows) {
			WriteProfileInt( "Defaults", "VGASwap", 0, NULL );
		} // Make default off

	  } // NOVGASWAP not already in MAXIMIZE.CFG

	 } // Xlat/t returned errorlevel 1

	 return;

 } // Result of _spawnl() was !0

 // If full MAXIMIZE, ask if they want VGASWAP
 if (QuickMax <= 0 && !ask_vgaswap ())
	return;

 replace_in_profile (IGNOREFLEXFRAME, MsgIgnoreFlex, 0L, 0L);
 add_to_profile (VGASWAP, VGASwap, 0L, 0L);

} // do_vgaswap ()
#endif	/* SYSTEM != MOVEM */

/************************* ADD_MAXCFG ***********************************/
// Create MAXIMIZE.CFG if necessary, and add specified keyword and comment.
void add_maxcfg (char *keyword, char *comment)
{
 FILE *f;

 if (CfgFile && (f = fopen (CfgFile,"a+t"))) {

	fprintf (f, "%s%s\n", keyword, comment);
	fclose (f);

 } // CfgFile appended to / created

} // add_maxcfg ()

/************************** DEL_MAXCFG *********************************/
// Delete all occurrences of specified keyword from MAXIMIZE.CFG
void del_maxcfg (char *keyword)
{
 FILE *fin, *fout;
 char lbuff[256];
 char tempout[_MAX_PATH], fdrive[_MAX_DRIVE], fdir[_MAX_DIR],
	fname[_MAX_FNAME], fext[_MAX_EXT];
 char *arg1;

 if (CfgFile && (fin = fopen (CfgFile, "r"))) {

	_splitpath (CfgFile, fdrive, fdir, fname, fext);
	_makepath (tempout, fdrive, fdir, fname, ".$$$");

	if (fout = fopen (tempout, "wt")) {

	  while (fgets (lbuff, sizeof(lbuff)-1, fin)) {

		strncpy (fdir, lbuff, sizeof(fdir)-1);
		fdir[sizeof(fdir)-1] = '\0';
		arg1 = strtok (fdir, CfgKeywordSeps);

		if (!arg1 || _stricmp (arg1, keyword)) fputs (lbuff, fout);

	  } // while not EOF

	} // Opened temporary output MAXIMIZE.$$$

	fclose (fin);

	if (fout) {

	  fclose (fout);
	  _unlink (CfgFile);		// Delete MAXIMIZE.CFG
	  rename (tempout, CfgFile);	// Rename MAXIMIZE.$$$ to MAXIMIZE.CFG

	} // Output file created

 } // Opened MAXIMIZE.CFG

} // del_maxcfg ()

#ifdef HARPO
#pragma optimize("g",off)
void add2harpopro (int appendmode,  char *fmt, ...)
/* If appendmode specified, parse the line and add to end of profile. */
/* This assumes that all appendmode calls are made sequentially with */
/* no intervening non-append calls. */
/* Otherwise, try to find a line owned by ActiveOwner.	If none found, */
/* or if appendmode specified, add one to the end of the profile with a */
/* section header. */
{
  static HARPOPROF *Hlast;
  static BYTE LastOwner = 0;
  HARPOPROF *Hnew, *Hline;
  char *kwd, *ktok, *cmt, *ws;
  int i, is_section = 0;
  char buff[256];
  va_list marker;
  SECTNAME *SRec;

  va_start (marker, fmt);
  vsprintf (buff, fmt, marker);
  va_end (marker);

  if (!LastOwner) LastOwner = CommonOwner;

	Hnew = get_mem (sizeof (HARPOPROF));
//	Hnew->next = NULL;	// Initialized by get_mem()
//	Hnew->optype = HOPT_UNK; // Assume it's unrecognized
	Hnew->workspace = str_mem (buff); // Save original text

	if (cmt = strpbrk (Hnew->workspace, QComments)) *cmt = '\0';
	strcpy (buff, Hnew->workspace);
	if (ktok = strtok (buff, ProKeywordSeps)) {

		for (i=0; kwd = HarpoOptions[i].optname; i++) {

		  if (!_stricmp (kwd, ktok)) {

		    // If it's not a line we own, don't bother parsing it
		    // Note that LastOwner == CommonOwner even if there's
		    // no MultiConfig active.
		    if (!appendmode || /* MultiBoot == NULL || */
			LastOwner == CommonOwner || LastOwner == ActiveOwner) {

			Hnew->optype = HarpoOptions[i].optoken;
//			Hnew->nspace = 0;

			if (cmt) {
			  // Count leading whitespace
			  for (ws = cmt-1; ws > Hnew->workspace &&
				strchr (" \t", *ws); ws--) Hnew->nspace++;
			  cmt++; // Skip the comment character
			} /* Found comments */

			Hnew->comments = cmt; // NULL if none found
			cmt = NULL; // We don't need to restore prior contents
			Hnew->keyword = strtok (Hnew->workspace, ProKeywordSeps);
			Hnew->arg1 = strtok (NULL, ProKeywordSeps);
			Hnew->arg2 = strtok (NULL, ProKeywordSeps);

		    } // It's our line

		    goto ADD2H_SETOWNER;

		  } // Got a match

		} // for all options in the table

		if (/* MultiBoot && */ /* There may be sections w/o MenuItems */
		    *ktok == '[' && (ktok = strtok (ktok, "[]"))) {
			is_section = 1;
			if (SRec = find_sect (ktok)) LastOwner = SRec->OwnerID;
			else LastOwner = 0xff;
		} // Check for a section name

	} // Line wasn't blank

ADD2H_SETOWNER:
	// We blew away the comment separator before parsing the line.
	// In case we didn't parse the line (not ours or comment-only),
	// we need to restore the comment separator.
	if (cmt) *cmt = ';';

	// Note that ActiveOwner == CommonOwner == LastOwner if no MultiConfig
	if (!appendmode && /* MultiBoot && */ ActiveOwner != LastOwner) {

	  // Find a line owned by ActiveOwner where the next line is
	  // null or owned by someone else.
	  for ( Hline = HarpoPro;
		Hline && (Hline->Owner != ActiveOwner || Hline->next == NULL ||
					Hline->next->Owner != ActiveOwner);
		Hline = Hline->next) Hlast = Hline;

	  if (Hline) {

		Hnew->next = Hline->next;
		Hline->next = Hnew;

	  } // Found our section; insert
	  else {

		if (Hlast)	Hlast->next = Hnew;
		else		HarpoPro = Hnew;

		if (!is_section) {

		  Hnew->Owner = ActiveOwner;
		  Hline = Hnew;
		  Hnew = get_mem (sizeof (HARPOPROF));
		  Hnew->next = Hline;	// Insert before actual line
//		  Hnew->optype = HOPT_UNK; // Assume it's unrecognized
		  sprintf (buff, "\n[%s]\n", MultiBoot ? MultiBoot : "common");
		  Hnew->workspace = str_mem (buff); // Save section header

		  if (Hlast)	Hlast->next = Hnew;
		  else		HarpoPro = Hnew;

		} // Need to add a section header

	  } // Add to end

	  Hnew->Owner = ActiveOwner;

	} // Find ActiveOwner
	else {

	  if (HarpoPro) Hlast->next = Hnew;
	  else		HarpoPro = Hnew;

	  Hlast = Hnew;
	  Hnew->Owner = LastOwner;

	} // Adding to end

} // add2harpopro ()
#pragma optimize("",on)
#endif /* ifdef HARPO */

#ifdef HARPO
/************************* READ_HARPOPRO *******************************/
// Parse HARPO profile into structure rooted at HarpoPro.
// This structure is supposed to get freed when close_harpopro() is
// called- we don't need to keep it around longer than necessary.
// Return 1 if successful.
int read_harpopro (void)
{
  FILE *hpro;
  char buff[256];
#define BUFFLEN (sizeof(buff)-1)

  HarpoPro = NULL;

  if (hpro = fopen (Harpo_profile, "r")) {

	while (fgets (buff, BUFFLEN, hpro)) {

	  buff[BUFFLEN] = '\0';
	  add2harpopro (1, buff);

	} // Not EOF

	fclose (hpro);
	return (1);	// Indicate success

  } // Open succeeded

  return (0);		// Indicate failure

} // read_harpopro ()
#endif /* ifdef HARPO */

#ifdef HARPO
int close_harpopro (int save)
/* If save != 0, _write HARPO profile to disk. */
/* Free the structure. */
/* Return 0 if unable to _write to file. */
{
  HARPOPROF *Hline, *Hlast;
  FILE *hpro;
  char buff[256];
  int ret = 1;	/* Assume success */

  if (save) {
	if (!(hpro = fopen (Harpo_profile, "w"))) {
	  ret = save = 0;	/* Return failure code */
	  /* Error writing %s file */
	  do_intmsg (MsgErrWriting, Harpo_profile);
	  AnyError = 1;
	} // Open failed
  } /* Open file for writing */

  for (Hline = HarpoPro; Hline; ) {
	if (save && !Hline->deleted) {
	  switch (Hline->optype) {
	    case HOPT_SUBSEG:
	    case HOPT_CCOM:
		sprintf (buff, "%s=%s", Hline->keyword, Hline->arg1);
		if (Hline->arg2) sprintf (stpend (buff), ",%s", Hline->arg2);
		while (Hline->nspace--) strcat (buff, " ");
		if (Hline->comments)
			sprintf (stpend (buff), " ;%s", Hline->comments);
		else	strcat (buff, "\n");
		fprintf (hpro, buff);
		break;

	    case HOPT_DEADMAN:
		break; /* Remove it - this is not the place to act on it */

	    case HOPT_GETSIZE:
		fprintf (hpro, "%s%s", Hline->keyword, Hline->comments ?
			Hline->comments : "\n");
		break;

	    default:
		fprintf (hpro, Hline->workspace);

	  } // actions for different option types
	} // Writing profile back
	Hlast = Hline;
	Hline = Hline->next;
	free (Hlast->workspace);
	free (Hlast);
	HarpoPro = NULL;
  } // For all lines in memory

  ActiveFiles[HARPOPRO] = Harpo_profile;
  if (save) {
	fclose (hpro);
#ifdef STACKER
	SwapUpdate (HARPOPRO);
#endif			/* ifdef STACKER */
  } /* Saving HARPO profile */

  return (ret);

} // close_harpopro ()
#endif /* ifdef HARPO */

#ifdef HARPO
typedef struct _cheret {
  WORD	efound:1,	/* E=anything found */
	enfound:1,	/* E=noloadhi found */
	cnfound:1,	/* C=noloadhi found */
	:13;		/* Unused bits */
} CHERET;

CHERET check_harpenv (void)
// Check HARPO profile for an E=n statement.  Return bits defined above.
// We'll also delete any OVERFLOW or NOLOADHI= lines we find.
// FIXME In Phase 3, if we find NOLOADHI= we should remove ExtraDOS
//	 and put NOEXTRADOS in the profile.
{
	HARPOPROF *Hline;
	CHERET ret = { 0 };

	for (Hline = HarpoPro; Hline; Hline = Hline->next)
	  if (Hline->optype == HOPT_CCOM) {
		if (!_strnicmp (Hline->arg1, "NOLOADHI", 8)) {
			if (Hline->keyword[0] == HENVIRON) ret.enfound = 1;
			else if (Hline->keyword[0] == HCOMMAND) ret.cnfound = 1;
		} /* It's a NOLOADHI line */
		else	if (Hline->keyword[0] == HENVIRON) ret.efound = 1;
	  } /* For all subsegment lines in Harpo profile */
	  else if (Hline->optype == HOPT_DEADMAN ||
			(Hline->optype == HOPT_GETSIZE &&
			 !_stricmp (Hline->keyword, "OVERFLOW"))) {
		Hline->deleted = 1;
	  } /* Delete this line */

	return (ret);

} // check_harpenv ()
#endif	/* ifdef HARPO */

#ifdef HARPO
/******************* DO_HARPO() *********************************/
// Ensure that HARPO is in CONFIG.SYS, and that it has a profile.
// This is done in Phase I; if NOHARPO is absent and there is no
// HARPO profile defined in phase III, we display a warning.  We
// also need to add GETSIZE to the HARPO profile.  This forces
// everything low so we can get the size of COMMAND.COM, and
// eliminates any error messages arising from changed FILES and
// BUFFERS.  We parse the HARPO profile looking for an existing
// E=n; if none is found or it's a new profile, we add E=NOLOADHI.
// Since we do this in Phase I, we can't rely on the EMM2CALL
// to return the profile name.	We need to ensure that no DEVICE
// statements come after DEVICE=HARPO, and that no INSTALL
// statements come after INSTALL=HARPO.  Once we've detected
// that the line needs to be moved, if MultiBoot is in effect
// we need to check the owner of the current location.	If it's
// ActiveOwner, we remove it (it shouldn't ever be in a COMMON
// or INCLUDE section unless NOEXPAND is in effect; caveat emptor).
// If not MultiBoot, always remove it and add to after the last
// DEVICE/INSTALL line.  If MultiBoot, find the last line in
// CONFIG.SYS.	If the owner is not ActiveOwner, add a [] section
// with a REM Moved here by MAXIMIZE; HARPO needs to be last.
#pragma optimize("leg",off)
void do_harpo( BOOL bStripExtraDOS )
{
 DSPTEXT *cfg = HbatStrt[CONFIG], *p, *n,
	 *hdev, *hinst, *lastdev, *lastinst,
	 *addenda;
 char drive[_MAX_DRIVE],dir[_MAX_DIR],fname[_MAX_FNAME],ext[_MAX_EXT];
 char newpath[_MAX_PATH];
 char *profile;
 int newprofile, isharpo;
 CHERET henvret;
 int FoundComment;

 /* If user put NOHARPO in MAXIMIZE.CFG or it's DR DOS, do nothing */
 if (maxcfg.noharpo && !bStripExtraDOS)	return;

 /* Tell 'em what we're doing */
 do_intmsg (MsgCheckHarpo);

 /* Find the FIRST DEVICE=HARPO and INSTALL=HARPO. */
 /* Remove all subsequent lines as we find 'em. */
 /* Note that in a MultiBoot configuration, inactive lines will never */
 /* have device set. */
 hdev = hinst = lastdev = lastinst = NULL;
 Harpo_profile[0] = '\0';
 FoundComment = 0;	// TRUE if we find REM ExtraDOS must be the last...
 for (p = n = cfg; n; p = n, n = n->next) {

	if (n->device != 0) { // DEVICE= or INSTALL= line

		_splitpath (n->devicen, drive, dir, fname, ext);
		sprintf (newpath, "%s%s", fname, ext);

		isharpo = !_stricmp (newpath, HARPO_EXE);

		if (n->device == DSP_DEV_DEVICE) {
			lastdev = n;
			if (isharpo) {
			  if (!hdev && !bStripExtraDOS) {
			    hdev = n;
			    strcpy (newpath, n->text);
			    _strlwr (newpath);
			    if (profile = strstr (newpath, "pro=")) {
				profile = strtok (profile+4, " \t\n");
				if (profile) {
				  strcpy (Harpo_profile, profile);
				} // Got profile name
			    } // Found PRO=
			  } // Found Device=HARPO line
			  else {
			    free_mem (n->text);
			    n->device = 0;
			    n->text = MsgRedundant;
			  } // Found a redundant DEVICE=HARPO line or stripping
			} // Found a DEVICE=HARPO line
		} // Found a DEVICE line
		else if (n->device == DSP_DEV_INSTALL) {
			lastinst = n;
			if (isharpo) {
			  if (!hinst && !bStripExtraDOS)	hinst = n;
			  else {
			    free_mem (n->text);
			    n->device = 0;
			    n->text = MsgRedundant;
			  } // Found a redundant INSTALL=HARPO line or stripping
			} // Found an INSTALL=HARPO line
		}

	} // DEVICE or INSTALL line
	else if (!_strnicmp (n->text,MsgMoveHarpo,15)) FoundComment = 1;

 } // for () ;

 // If stripping, we're done
 if (bStripExtraDOS) {
 	return;
 } // Done

 /* If a HARPO profile doesn't exist, skip DEVICE= check */
 addenda = NULL;
 if (Harpo_profile[0] == '\0' && !bStripExtraDOS) {

	/* If DEVICE=HARPO not found, append to CONFIG.SYS */
	// Note that if this is a MultiBoot configuration we'll
	// force relocation unless p's owner is ActiveOwner
	if (!hdev) {

		hdev = get_mem (sizeof (DSPTEXT));
		sprintf (Harpo_profile, "%s" HARPO ".PRO", LoadString);
		sprintf (newpath,"Device=%s" HARPO_EXE " pro=%s",
			LoadTrue, Harpo_profile);
		hdev->text = str_mem (newpath);
		hdev->visible = 1;
		addenda = lastdev = hdev;
		fndevice (hdev, NULL);

	} // No DEVICE=HARPO statement
	else {

		// Get Device= path for profile (if needed)
		_splitpath (hdev->devicen, drive, dir, fname, ext);

		// Default profile
		_makepath (Harpo_profile, drive, dir, HARPO, ".PRO");

		// Clobber all but leading space on the original line
		strcpy (newpath, hdev->text);
		newpath[strspn(newpath," \t")] = '\0';

		// Now reconstruct it and replace hdev->text
		sprintf (stpend (newpath), "Device=%s pro=%s", hdev->devicen,
			Harpo_profile);
		free (hdev->text);
		hdev->text = str_mem (newpath);

		// Recalculate leading space for line reconstruction.
		// This is not strictly needed since HARPO can't be toggled
		// to GETSIZE -- it's always unmarked.
		set_nlead (hdev, hdev->devicen);

	} // Profile name created from Device path

 } // No HARPO profile found

 ActiveFiles[HARPOPRO] = Harpo_profile;

 /* If HARPO profile doesn't exist, create a default profile */
 if (_access (Harpo_profile, 06)) {

	do_intmsg (MsgCreatProf,Harpo_profile);
	newprofile = TRUE;
	HarpoPro = NULL;
	add2harpopro (1, MsgAddHPro);

 } // Profile doesn't exist
 else {
	newprofile = FALSE;
	if (savefile (HARPOPRO)) {
		do_error (MsgHarpoFailSave, FALSE);
	}
	else {
		restbatappend (HARPOPRO);	/* Add to PREMAXIM */
	} /* Harpo profile was saved OK */

	if (!read_harpopro ()) {
	  /* Error opening %s file */
	  do_intmsg (MsgErrOpen, Harpo_profile);
	  AnyError = 1;
	  return;
	} /* Couldn't _read profile */

 } // Save previously existing profile and parse it

 henvret = check_harpenv ();	// Check HARPO profile for E=n statement

 add2harpopro (0, "GETSIZE\n");

/* Check to ensure that DEVICE=HARPO is the last device in CONFIG.SYS */
// We need to ensure that no DEVICE
// statements come after DEVICE=HARPO, and that no INSTALL
// statements come after INSTALL=HARPO.  Once we've detected
// that the line needs to be moved, remove it and add after the last
// DEVICE/INSTALL line.  If MultiBoot, find the last line in
// CONFIG.SYS.	If the owner is not ActiveOwner, add a [] section
// with a REM Moved here by MAXIMIZE; HARPO needs to be last.
 if (hdev != lastdev) {
   // Remove from present location
   if (hdev->prev) hdev->prev->next = hdev->next;
   if (hdev->next) hdev->next->prev = hdev->prev;
   hdev->MBOwner = ActiveOwner; 	// What else could it be?
   hdev->next = NULL;			// Make sure CONFIG.SYS ends somewhere
   addenda = hdev;			// Note that if we created hdev,
					// addenda == hdev and hdev == lastdev
   if (hdev == p) p = hdev->prev;	// If at the end, back off last line
 } // HARPO not the last device in CONFIG.SYS

 /* Check CONFIG.SYS for INSTALL=HARPO (DOS 5+ only) and append if not found */
 /* Note that DOS 4 supports INSTALL=, but HARPO won't load command.com */
 /* high because it's not completely reliable, especially with Novell. */
 if (_osmajor > 4) {
    int env_exists = 0; // 1 if we should check for E=NOLOADHI

    if (!hinst && !Parsed4DOS) {

	hinst = get_mem (sizeof (DSPTEXT));
	if (hdev)	sprintf (newpath, "Install=%s", hdev->devicen);
	else		sprintf (newpath, "Install=%s" HARPO_EXE, LoadString);
	hinst->text = str_mem (newpath);
	hinst->prev = addenda;
	fndevice (hinst, NULL);

    } // INSTALL=HARPO not found
    else if (hinst && (hinst != lastinst || Parsed4DOS)) {

	// Remove from present location
	if (hinst->prev) hinst->prev->next = hinst->next;
	if (hinst->next) hinst->next->prev = hinst->prev;
	hinst->MBOwner = ActiveOwner;	 // What else could it be?
	hinst->next = NULL;		 // Make sure CONFIG.SYS ends
	if (hinst == p) p = hinst->prev; // If at the end, back off last line
	if (Parsed4DOS) goto NO_ADDENDA; // If it's 4DOS, leave unhooked

    } // INSTALL=HARPO not the last INSTALL statement in CONFIG.SYS
    else {
	env_exists = 1; // Check for E=NOLOADHI
	goto NO_ADDENDA;
    } // INSTALL=HARPO is already in the right place

    env_exists = 1; // Check for E=NOLOADHI
    if (addenda) {
	addenda->next = hinst;
	hinst->prev = addenda;
    }
    else addenda = hinst;

NO_ADDENDA:
// Now we can add statements to the HARPO profile that pertain
// only to the INSTALL= portion of HARPO.
    if (env_exists && !(henvret.efound || henvret.enfound))
		add2harpopro (0, "E=NOLOADHI%s\n", MsgEnvLow);

    /* If any lines are to be added, link 'em in.  p is the last line in */
    /* CONFIG.SYS.  We may need to add a section header for MultiBoot, and */
    /* we need to prefix the addenda with a comment. */
    /* p is the last line of CONFIG.SYS */
    if (addenda) {

      n = get_mem (sizeof (DSPTEXT));

      if (MultiBoot) {

	if (p->MBOwner != ActiveOwner) {

	  n->prev = p;
	  p->next = n;
	  sprintf (newpath, "\n[%s]", MultiBoot);
	  n->text = str_mem (newpath);
	  n->MBOwner = ActiveOwner;
	  n->MBtype = ID_SECT;
	  p = n;
	  n = get_mem (sizeof (DSPTEXT));

	  /* p is the newly added section header */

	} // Owner is not active owner

	n->MBOwner = ActiveOwner;

      } /* Create a section header */

      /* p is the last line of CONFIG.SYS (it may also be the new section */
      /* header we just created).  n is the record we'll use to add our */
      /* comment. */
      if (FoundComment) {
	free (n);
	p->next = addenda;
	addenda->prev = p;
      } // Comment already existed
      else {
	n->prev = p;
	p->next = n;
	n->text = MsgMoveHarpo;
	n->next = addenda;
	addenda->prev = n;
      } // Add comment, the INSTALL and DEVICE lines

    } // Add lines to end of CONFIG.SYS
    else if (!FoundComment && hdev) {
	n = get_mem (sizeof (DSPTEXT));
	n->prev = hdev->prev;
	n->next = hdev;
	hdev->prev = n;
	n->text = MsgMoveHarpo;
    } // Comment not found

 } // DOS 5 or greater
 // Note that for DOS < 5, we can't add a REM statement, and the only
 // addendum should be the DEVICE=ExtraDOS statement.
 else if (addenda) p->next = addenda;

 // Write the updated HARPO profile
 close_harpopro (1);

} // do_harpo()
#pragma optimize("",on)
#endif	/* ifdef HARPO */

