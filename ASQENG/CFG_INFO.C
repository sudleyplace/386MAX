/*' $Header:   P:/PVCS/MAX/ASQENG/CFG_INFO.C_V   1.2   02 Jun 1997 14:40:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CFG_INFO.C								      *
 *									      *
 * Formatting routines for configuration screens			      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>

#include <engine.h>		/* Engine definitons */
#include "info.h"               /* Internal info functions */
#include "sysinfo.h"            /* System info structures / functions */
#include <commfunc.h>		/* Utility functions */
#include <libtext.h>		/* Localization constants */

#define CFG_INFO_C
#include "engtext.h"            /* Text strings */

extern char *comma_num (long arg); /* From MEM_INFO.C */
extern void fixtabs(char *dst,char *src,int n); /* From SYSINFO.C */

/* Formats */

/* Summary */
char *CfgFmt1a = "%11s: %u%c%02u";
char *CfgFmt1b = "%11s: %d, %s %d %s";
char *CfgFmt1c = "%11s: %d";
char *CfgFmt1d = "%11s: %d%c%d";
char *CfgFmt1e = "%11s: %c";
char *CfgFmt1f = "%11s: %s";

char *CfgFmt2 =  "%15s: ";

char *CfgFmt3a = "%11s:";
char *CfgFmt3b = "%11s: %3d %s";
char *CfgFmt4a = "%10s: %d";
char *CfgFmt4b = "%10s: %s";
char *CfgFmt4c = "%12s%s";
char *CfgFmt5a = "%7s: %s";

char *CfgFmt7a = "%20s: %s";
char *CfgFmt7b = "%20s: %u.%02u";

/*			File   Size  Time Date */
char *CfgFmt7c = " %-12s  %10s %-6s %s";

/* Type 	 Initialization    Resident size -- Region Group Request Order*/
/*		 program    env    program    env */
char *CfgFmt7d = " %-13s%8s %8s %8s %8s %5s %5s %8s %s";
char *CfgFmt7dl= " %-13s%8s %8s %8s %8s %8s %s";

/* Name 	 Initialization    Resident size -- Region Group Flag*/
/* char *CfgFmt7e = " %-13s %-8s %-8s %-8s %-8s %-8s %-3s   %-5s %s"; */

/* Local functions */
static void show_file(
	HANDLE info,	/* Control structure */
	char *pszLines, /* Handle to file lines */
	WORD nlines);	/* How many lines in file */

static void near show_fstats(
	HANDLE info,	/* Control structure */
	SYSBUFH pFstat, /* Starting entry (may be 0) */
	char *htext);	/* Header */

/*
 *	Config_Summary - build text for Configuration / Sumary screen
 */

void Config_Summary(HANDLE info)
{
	info_color(info,12);
	info_format(info,CFGFMT1);

	iprintf(info,CfgFmt1a,MSG2001,HIBYTE(SysInfo->dosver),NUM_VDECIMAL,LOBYTE(SysInfo->dosver));
	iprintf(info,CfgFmt1b,MSG2002,SysInfo->config.files,MSG2012,5,MSG2014);
	if (SysInfo->dosver < 0x400) {
		iprintf(info,CfgFmt1b,MSG2003,SysInfo->config.buffers,MSG2012,1,MSG2014);
	}
	else {
		iprintf(info,CfgFmt1c,MSG2003,SysInfo->config.buffers);
	}
	iprintf(info,CfgFmt1d,MSG2004,SysInfo->config.fcbx,NUM_COMMA,SysInfo->config.fcby);
	if (SysInfo->dosver >= 0x314)
		iprintf(info,CfgFmt1d,MSG2005,SysInfo->config.stackx,NUM_COMMA,SysInfo->config.stacky);
	if (SysInfo->dosver >= 0x300) {
		int ldrive = SysInfo->config.lastdrive;

		if (ldrive < 'A' || ldrive > 'Z') ldrive = '*';
		iprintf(info,CfgFmt1e,MSG2006,ldrive);
	}
	iprintf(info,CfgFmt1f,MSG2007,SysInfo->config.brk ? MSG2008 : MSG2009);

	info_color(info,12);
	info_format(info,CFGFMT2);
	if (SysInfo->config.shell || SysInfo->config.country || SysInfo->config.drivparm) {
		info_color(info,16);
		iprintf(info,"");
		/*iprintf(info,CfgFmt2,MSG2051);*/
	}
	if (SysInfo->config.shell) {
		info_color(info,strlen(MSG2010));
		iwraptext(info,MSG2010,"2 ",
			sysbuf_ptr(SysInfo->config.shell),
			DWIDTH1,CONTIN_LINE);
	}
	if (SysInfo->config.country) {
		info_color(info,strlen(MSG2011));
		iwraptext(info,MSG2011,"2 ",
			sysbuf_ptr(SysInfo->config.country),
			DWIDTH1,CONTIN_LINE);
	}
	if (SysInfo->config.drivparm) {
		info_color(info,strlen(MSG2013));
		iwraptext(info,MSG2013,"2 ",
			sysbuf_ptr(SysInfo->config.drivparm),
			DWIDTH1,CONTIN_LINE);
	}
	iprintf(info,"");

	info_format(info,CFGFMT3);
	info_color(info,12);
	iprintf(info,CfgFmt3a,MSG2016);
	iprintf(info,CfgFmt3b,MSG2017,SysInfo->envsize,MSG2019);
	iprintf(info,CfgFmt3b,MSG2018,SysInfo->envused,MSG2019);
	iprintf(info,"");

	info_format(info,CFGFMT2);
	{
		WORD kk;
		char *p;

		p = sysbuf_ptr(SysInfo->envstrs);
		for (kk = 0; kk < SysInfo->envlen; kk++) {
			int n;
			char *p2;

			p2 = strchr(p,'=');
			if (p2) n = p2-p+1;
			else	n = 0;
			info_color(info,n);
			iwraptext(info,"","2 ",p,DWIDTH1,CONTIN_LINE);
			p += strlen(p)+1;
		}
	}

	{
		OPENFILE *ofp;
		OPENFILE *ofpend;
		char *fmt;
		char *txt;

		info_format(info,CFGFMT4);
		info_color(info,11);
		iprintf(info,"");
		iprintf(info,CfgFmt4a,MSG2032,SysInfo->openfcbs);

		fmt = CfgFmt4b;
		txt = MSG2033;
		ofp = sysbuf_ptr(SysInfo->openfiles);
		ofpend = ofp + SysInfo->openlen;
		while (ofp < ofpend) {
			iprintf(info,fmt,txt,ofp->name);
			fmt = CfgFmt4c;
			txt = MSG2034;
			ofp++;
		}
	}
}

/*
 *	Config_CONFIG_SYS - build text for Configuration / CONFIG.SYS screen
 */

void Config_CONFIG_SYS(HANDLE info)
{
	info_format(info,0);
	info_color(info,0);
	if (SysInfo->flags.cfg) {
		show_file(info,SysInfo->pszCnfgsys,SysInfo->cnfglen);
	}
	else {
		char text[80+40];

		sprintf(text,MSG2043,CONFIG_SYS,SysInfo->bootdrv+'A');
		ictrtext(info,text,DWIDTH2);
	}
}

/*
 *	Config_AUTOEXEC_BAT - build text for Configuration / AUTOEXEC.BAT screen
 */

void Config_AUTOEXEC_BAT(HANDLE info)
{
	info_format(info,0);
	info_color(info,0);
	if (SysInfo->flags.aut) {
		show_file(info,SysInfo->pszAutobat,SysInfo->autolen);
	}
	else {
		char text[80+40];

		sprintf(text,MSG2043A,sysbuf_ptr (SysInfo->config.startupbat));
		ictrtext(info,text,DWIDTH2);
	}
}

/*
 *	Config_386MAX_PRO - build text for Configuration / AUTOEXEC.BAT screen
 */

void Config_386MAX_PRO(HANDLE info)
{
	info_format(info,0);
	info_color(info,0);
	if (SysInfo->config.maxpro) {
		show_file(info,SysInfo->pszMaxprof,SysInfo->proflen);
	}
	else {
		/* No profile in CONFIG.SYS */
		ictrtext(info,MSG2045,DWIDTH2);
	}
}

/* Build text for EXTRADOS.PRO screen */
void Config_ExtraDOS_PRO (HANDLE info)
{
	info_format(info,0);
	info_color(info,0);
	if (SysInfo->config.extradospro) {
		show_file(info,SysInfo->pszExtrados,SysInfo->extradoslen);
	}
	else {
		/* No profile in CONFIG.SYS */
		ictrtext(info,MSG2045A,DWIDTH2);
	}
} /* Config_ExtraDOS_PRO */

/* Build text for SYSTEM.INI screen */
void Config_SYSINI (HANDLE info)
{
	info_format(info,0);
	info_color(info,0);
	if (SysInfo->WindowsData.sysininame) {
		show_file(info,SysInfo->pszSysini,SysInfo->sysinilen);
	}
	else {
		/* No Windows directory found */
		ictrtext(info,MSG2045B,DWIDTH2);
	}
} /* Config_SYSINI */

static char _far * near mbtypetext (MAXIMIZEBST *pM)
{
  static char text[15];

  if (pM->subseg) {
	sprintf (text, pM->owner == 0 ? MSG2045P : MSG2045O, pM->stype);
  } /* It's a subsegment */
  else {
	if (pM->group == 0xff) strcpy (text, MSG2045I); /* MAX */
	else if (pM->group == 0xfe) strcpy (text, MSG2045J); /* UMB */
	else if (pM->group == 0xfc) strcpy (text, MSG2045K); /* COMMAND.COM */
	else if (pM->lflags.drv) strcpy (text, MSG2045L); /* DEVICE */
	else if (pM->lflags.inst) strcpy (text, MSG2045M); /* INSTALL= */
	else strcpy (text, MSG2045N); /* TSR */
  } /* Not a subsegment */

  return (text);

} /* mbtypetext */

static char * near ccomma (int cond, WORD val, char *alt)
{
  if (cond) return ( comma_num (((DWORD) val) * 16L));
  else return (alt);
} /* ccomma () */

/* Helper function for Config_Qualitas */
/* Display a line of MAXIMIZE.BST output */
/* hdr is assumed to be a constant; it will be modified */
static void near show_maximize (HANDLE info,	/* Destination */
	int movedhigh,				/* 1 for programs moved high */
	char *hdr,				/* Header to display */
	SYSBUFH start)				/* Starting entry */
{
  MAXIMIZEBST *pMax;
  char	reqtxt[20],
	pinittxt[20],
	einittxt[20],
	prestxt[20],
	erestxt[20],
	regtxt[20],
	grptxt[20],
	ordtxt[20];
  int displayedhdr = 0;

  while (start) {
    pMax = sysbuf_ptr (start);
    if ((movedhigh && pMax->preg) || (!movedhigh && !pMax->preg)) {
	if (!displayedhdr) {
	  iprintf (info, "");
	  info_color (info, strlen(MSG2045H1));
	  iprintf (info, hdr);
	  iprintf (info, movedhigh ? MSG2045H1 : MSG2045H1L);
	  iprintf (info, MSG2045H2);
	  info_color (info, 0);
	  displayedhdr = 1;
	} /* Header not yet displayed */
	reqtxt[0] = einittxt[0] = erestxt[0] = regtxt[0] = grptxt[0] =
		ordtxt[0] = '\0';
	if (!pMax->subseg) {
	  if (pMax->group == 0xfe) {
		if (pMax->reqsize) strcpy (reqtxt, ccomma (pMax->reqsize !=
				0xffff, pMax->reqsize, MSG2045Q));
	  } /* UMB */
	  else {
		strcpy (einittxt, ccomma (pMax->epar0, pMax->epar0, ""));
		strcpy (erestxt, ccomma (pMax->epar1, pMax->epar1, ""));
	  } /* Not a UMB */
	  if (pMax->group && pMax->group < 0x80)
		strcpy (grptxt, comma_num (pMax->group));
	  if (pMax->ord) sprintf (ordtxt, "  %d", pMax->ord);
	} /* Not a subsegment */
	strcpy (pinittxt, ccomma (1, pMax->ipara, NULL));
	strcpy (prestxt, ccomma (1, pMax->rpara+1, NULL)); /* Add MAC */
	if (pMax->preg != 0xff) strcpy (regtxt, comma_num (pMax->preg));

	if (movedhigh)
	  iprintf (info, CfgFmt7d, mbtypetext (pMax),
		pinittxt, einittxt,
		prestxt, erestxt,
		regtxt,
		grptxt,
		reqtxt, ordtxt);
	else
	  iprintf (info, CfgFmt7dl, mbtypetext (pMax),
		pinittxt, einittxt,
		prestxt, erestxt,
		grptxt,
		reqtxt, ordtxt);

    } /* Display this */
    start = pMax->next;
  } /* not end of list */
} /* show_maximize () */

/* Interpret LSEG flags */
static char _far * near flag_text (LSEGFLAGS f)
{
  static char ftxt[80];

  ftxt[0] = '\0';

  if (f.xems) strcpy (ftxt, MSG2045R1);
  else if (f.inflex) strcpy (ftxt, MSG2045R2);
  else if (f.flex) strcpy (ftxt, MSG2045R3);

  if (f.gsize) {
	if (ftxt[0]) strcat (ftxt, "; ");
	strcat (ftxt, MSG2045R4);
  }

  if (f.stra) {
	if (ftxt[0]) strcat (ftxt, "; ");
	strcat (ftxt, f.stra==1 ? MSG2045R5 : MSG2045R6);
  }

  return (ftxt);

} /* flag_text () */

/* Build text for Qualitas info screen */
void Config_Qualitas (HANDLE info)
{
	info_format(info,CFGFMT6);
	info_color(info,0);

	/* Show files like: */
	/* 386MAX.SYS  210,097	11:46a	05/23/93 */
	show_fstats (info, SysInfo->pQFiles, MSG2045C);

	/* Display current LSEG data */
	if (SysInfo->pLseg) {
	  SYSBUFH nexth;
	  LSEGDATA *lpLseg;
	  char	reqtxt[20],
		pinittxt[20],
		einittxt[20],
		prestxt[20],
		erestxt[20],
		regtxt[20],
		grptxt[20];

	  info_color(info,strlen(MSG2045H1S));
	  iprintf (info, MSG2045D);
	  iprintf (info, MSG2045H1S);
	  iprintf (info, MSG2045H2);
	  info_color(info,0);
	  for (nexth = SysInfo->pLseg; nexth; nexth = lpLseg->next) {

		lpLseg = sysbuf_ptr (nexth);

		reqtxt[0] = einittxt[0] = erestxt[0] = grptxt[0] =
			regtxt[0] = '\0';

		if (lpLseg->grp == 0xfe) {
		  if (lpLseg->reqsize) strcpy (reqtxt,
				ccomma (lpLseg->reqsize != 0xffff,
					lpLseg->reqsize, MSG2045Q));
		} /* UMB */
		else {
		  strcpy (einittxt, ccomma (lpLseg->epar0, lpLseg->epar0, ""));
		  strcpy (erestxt, ccomma (lpLseg->epar1, lpLseg->epar1, ""));
		} /* Not a UMB */

		if (lpLseg->grp && lpLseg->grp < 0x80)
			strcpy (grptxt, comma_num (lpLseg->grp));

		strcpy (pinittxt, comma_num (lpLseg->isize));
		if (lpLseg->preg != 0xff)
			strcpy (regtxt, comma_num (lpLseg->preg));
		strcpy (prestxt, ccomma (1, lpLseg->rpara+1, NULL)); /* Add MAC */

		iprintf (info, CfgFmt7d, lpLseg->fne,
			pinittxt, einittxt,
			prestxt, erestxt,
			regtxt,
			grptxt,
			reqtxt, flag_text (lpLseg->flags));
	  } /* For all LSEG entries */
	} /* We have LSEG data */

	/* Display data from last MAXIMIZE run */
	if (SysInfo->MaximizeBestsize) {
	  show_maximize (info, 1, MSG2045F, SysInfo->pMaxBest);
	  iprintf (info, "");
	  info_color (info,strlen(MSG2045E)+1);
	  iprintf (info, CfgFmt7a, MSG2045E,
				ccomma (1, SysInfo->MaximizeBestsize, NULL));
	  info_color (info,0);
	  show_maximize (info, 0, MSG2045G, SysInfo->pMaxBest);
	} /* Found Maximize.bst */

} /* Config_Qualitas */

/* Build text for Windows info screen */
void Config_Windows (HANDLE info)
{
	info_format(info,CFGFMT7);
	if (SysInfo->WindowsData.windowsdir) {
		info_color(info,21);
		iprintf (info, CfgFmt7a, MSG2034A,
				sysbuf_ptr (SysInfo->WindowsData.windowsdir));
		iprintf (info, CfgFmt7b, MSG2034B,
				HIBYTE(SysInfo->WindowsData.windowsver),
				LOBYTE(SysInfo->WindowsData.windowsver));
		info_color(info,0);
		iprintf (info, "");
		show_fstats (info, SysInfo->WindowsData.pWFiles, MSG2034C);
	} /* Got Windows directory */
	else {
		info_color(info,0);
		ictrtext(info,MSG2045B,DWIDTH2);
	} /* Didn't find Windows directory */
} /* Config_Windows */

/*
 *	Config_Snapshot - return info about snapshot
 */

void Config_Snapshot(HANDLE info)
{
	info_format(info,CFGFMT5);
	if (SysInfo->flags.readin) {
		char temp[20];

		info_color(info,8);
		iprintf(info,CfgFmt5a,MSG2046,SysInfo->snapfile);
		iprintf(info,CfgFmt5a,MSG2047,
			datestr(temp,SysInfo->snapdate[0],SysInfo->snapdate[1],SysInfo->snapdate[2]));
		iprintf(info,CfgFmt5a,MSG2048,
			timestr(temp,SysInfo->snaptime[0],SysInfo->snaptime[1],SysInfo->snaptime[2]));
		iprintf(info,CfgFmt5a,MSG2049,SysInfo->snaptitle);
	}
	else {
		info_color(info,0);
		ictrtext(info,MSG2050,DWIDTH2);
	}
}

/*
 *	show_file - read contents of a file into an info list
 */

static void show_file(
	HANDLE info,	/* Control structure */
	char *pszLines, /* Handle to file lines */
	WORD nlines)	/* How many lines in file */
{
	WORD kk;
	char *p;
	char temp[256];

	/* Put lines into list, with text wrap */
	p = pszLines;
	for (kk = 0; kk < nlines; kk++) {
		fixtabs (temp, p, sizeof(temp)-1);
		temp[sizeof(temp)-1] = '\0';
		iwraptext(info,"","2 ",temp,DWIDTH2,CONTIN_LINE);
		p += strlen(p) + 1;
	}
	return;
}

/* Display file stats */

static void near show_fstats(
	HANDLE info,	/* Control structure */
	SYSBUFH pFstat, /* Starting entry (may be 0) */
	char *htext)	/* Header */
{
  FILESTATS *pF;
  char temp[20], temp2[20];

  if (!pFstat) return;

  info_color (info,strlen(MSG2046A));
  iprintf (info, MSG2046A);
  info_color (info,0);
  for (pF = sysbuf_ptr (pFstat); pF; pF = sysbuf_ptr (pF->next)) {
    iprintf (info, CfgFmt7c, pF->fname, comma_num (pF->fsize),
	timestr (temp, pF->fhours, pF->fminutes, pF->fseconds*2),
	datestr (temp2, pF->fmonth, pF->fday, pF->fyear+1980));
    if (!pF->next) break;
  } /* for all files */
  iprintf (info, "");

} /* show_fstats () */

/* Tue Nov 20 18:38:02 1990 alan:  work */
/* Wed Nov 21 10:44:27 1990 alan:  fix bugs */
/* Mon Nov 26 17:05:58 1990 alan:  rwsystxt and other bugs */
/* Tue Nov 27 15:09:37 1990 alan:  bugs */
