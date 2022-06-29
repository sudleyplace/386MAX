/*' $Header:   P:/PVCS/MAX/ASQENG/PROFILE.C_V   1.2   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PROFILE.C								      *
 *									      *
 * Read and process ASQ profile file					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* Local Includes */
#include <commdef.h>		/* Common definitions */
#include "sysinfo.h"            /* System info structures */
#include <commfunc.h>		/* Utility functions */
#include <screen.h>		/* Screen color */

#define PROFILE_C
#include "engtext.h"            /* Text strings */

#define OWNER
#include "profile.h"            /* Profile functions */

/* Local Functions */
static void make_item(GLIST *list,char *line,int *pos,char *name,MAPCLASS class);
static BOOL kwd_value(char *str,int *pos,char *kwd,int nkwd);
static BOOL hex_range(char *str,int *pos,WORD *start,WORD *end);
static BOOL hex_value(char *str,int *pos,WORD *value);
static BOOL dec_value(char *str,int *pos,int *value);
static BOOL sep_char(char *str,int *pos,int sep);

/* Imported from print.c */
extern int readProfile( int first, char *line, int nline );

/* In TESTMEM.ASM */
extern unsigned char pascal TESTMEM_MAP[1];

struct tagProfileOpt {
	char	*keyword;
	void	*pVal;
	int	action; /* 0 to set FALSE, -1 TRUE, else size of argument */
} ProfileOpts[] = {
	{ "NoTestMem", &NoTestMem, -1 },
	{ "NoTestEMS", &NoTestEMS, -1 },
	{ "NoTestDiskCache", &NoTestDiskCache, -1 },
	{ "NoTestVGA", &NoTestVGA, -1 },
	{ "NoLOGO", &GraphicsLogo, 0 },
	{ "SnowControl", &SnowControl, -1 },
	{ "NoTestGamePort", &NoTestGamePort, -1 },
	{ "BootDrive", &BootOverride, 1 },
	{ NULL, NULL, 0}
};

void read_profile(		/* Read and process ASQ profile */
	BOOL def,		/* TRUE to read from default profile */
	BOOL getdata,		/* TRUE to read and process data;
				   otherwise, keywords only */
	char *fname)		/* Profile basename/extension */
{
	FILE *infile;
	GLIST list;
	int slot;
	int first;
	int oi;
	char line[150];
	char kw[20];

	/* Init the temporary list */
	if (getdata) {
		glist_init(&list,GLIST_ARRAY,sizeof(MEMHOLE),4*sizeof(MEMHOLE));
	}

	/* Set up the file spec */
	if (def && getdata) {
		infile = NULL;
	}
	else {
		get_exepath(line,sizeof(line));
		strcat(line,fname);

		/* Try to open it */
		infile = fopen(line,"r");

		if (!infile) return;
	}

	/* Initialize */
	if (getdata) {

		slot = MCASLOTS;	/* ...means no slot selected */
		first = TRUE;

	}

	/* Read lines from file */
	for (;;) {
		int ii;

		if (infile) {
			if (!fgets(line,sizeof(line),infile)) break;
		}
		else {
			if (!readProfile(first, line,sizeof(line))) break;
			first = FALSE;
		}

		/* Ignore empty lines */
		if (trim(line) < 1) continue;

		ii = 0;
		if (!kwd_value(line,&ii,kw,sizeof(kw))) continue;

		for (oi=0; ProfileOpts[oi].keyword; oi++) {
		  if (!stricmp (kw, ProfileOpts[oi].keyword)) {
		    int argwidth;
		    void *argptr;
		    DWORD argval;
		    char *equals;

		    argwidth = ProfileOpts[oi].action;
		    argptr = ProfileOpts[oi].pVal;
		    if (equals = strchr (line, '='))
			    sscanf (equals+1, argwidth == 1 ? "%c" : "%lu",
				&argval);
		    switch (argwidth) {
			case 1: /* BYTE */
			case 2: /* WORD */
			case 4: /* DWORD */
				memcpy (argptr, &argval, argwidth);
				break;
			case 0: /* FALSE */
			case -1: /* TRUE */
				*((WORD *) argptr) = argwidth;
				break;
		    } /* end switch */
		    goto BOTTOMLOOP;
		  } /* Found a matching keyword */
		} /* For all boolean keywords */

		if (!stricmp (kw, "NOSCAN")) {
			WORD start;
			WORD end;

			if (sep_char(line,&ii,'=')) {
			  if (hex_range(line,&ii,&start,&end)) {
			    start = max (start, 0xA000);
			    if (end > start) {
				/* One byte per 4K block */
				start = (start - 0xA000) / (4096/16);
				end = (end - 0xA000 - 1) / (4096/16);
				for ( ; start <= end; start++) TESTMEM_MAP[start] = 0x03; /* Mark as unused */
			    } /* Range was valid (ascending) and in high DOS */
			  } /* Got a hex range */
			} /* Found '=' separator */
		} /* NOSCAN=xxxx-yyyy */
		else if (!stricmp (kw, "USECOLOR")) {
			char *equals;
			if (equals = strchr (line, '='))  {
			  ScreenSet = TRUE;
			  sscanf (kw, "%19s", equals+1);
			  ScreenType = (strchr ("yYtT1", *kw) ||
			     !stricmp (kw, "ON")) ? SCREEN_COLOR : SCREEN_MONO;
			} /* USECOLOR=x */
		} /* USECOLOR */
		else if (getdata) {

		  if (stricmp(kw,"RAM") == 0) {
			make_item(&list,line,&ii,"RAM",CLASS_RAM);
		  }
		  else if (stricmp(kw,"ROM") == 0) {
			make_item(&list,line,&ii,"ROM",CLASS_ROM);
		  }
		  else if (stricmp(kw,"Unused") == 0) {
			make_item(&list,line,&ii,"-Unused-",CLASS_UNUSED);
		  }
		  else if (stricmp(kw,"Adapter") == 0) {
			WORD adapter;

			if (sep_char(line,&ii,'=')) {
				if (hex_value(line,&ii,&adapter) && adapter != 0) {
					for (slot = 0; slot < MCASLOTS; slot++) {
						if (adapter == SysInfo->mcaid[slot].aid) {
							break;
						}
					}
				}
			}
		  }
		  else if (stricmp(kw,"Pos") == 0 && slot < MCASLOTS) {
			int kk;
			int posidx;
			char posstr[16];

			for (kk = 0; kk < 4; kk++) {
				*kw = '\0';
				if (!sep_char(line,&ii,'[')) break;
				if (!dec_value(line,&ii,&posidx)) break;
				if (posidx < 0 || posidx > 3) break;
				if (!sep_char(line,&ii,']')) break;
				if (!sep_char(line,&ii,'=')) break;
				if (!kwd_value(line,&ii,posstr,sizeof(posstr))) break;
				if (!pos_test(SysInfo->mcaid[slot].pos[posidx],posstr)) break;
				if (!kwd_value(line,&ii,kw,sizeof(kw))) break;
				if (stricmp(kw,"Pos") != 0) break;
			}
			if (stricmp(kw,"RAM") == 0) {
				make_item(&list,line,&ii,"RAM",CLASS_RAM);
			}
			else if (stricmp(kw,"ROM") == 0) {
				make_item(&list,line,&ii,"ROM",CLASS_ROM);
			}
		  }

		} /* getdata TRUE */

BOTTOMLOOP:
		;
	} /* for () ... */

	if (infile) fclose(infile);

	if (getdata) {

		/* Transfer data to SysInfo buffer */
		sysbuf_glist(&list,sizeof(MEMHOLE),&SysInfo->emap,&SysInfo->emaplen);

		/* Say bye-bye to the list */
		glist_purge(&list);

	} /* getdata */

} /* read_profile */

static void make_item(GLIST *list,char *line,int *pos,char *name,MAPCLASS class)
{
	WORD start;
	WORD end;
	MEMHOLE hitem;

	if (!sep_char(line,pos,'=')) return;
	if (hex_range(line,pos,&start,&end)) {
		if (end >= start) {
			hitem.class = class;
			hitem.faddr = ((DWORD)start) * 16;
			hitem.length = (((DWORD)end - (DWORD)start) + 1) * 16;
			strcpy(hitem.name,name);
			glist_new(list,&hitem,sizeof(hitem));
		}
	}
}

/* Process "keyword=" token */
static BOOL kwd_value(char *str,int *pos,char *kwd,int nkwd)
{
	int kk;
	char *p;

	p = str + *pos;

	/* Skip leading white space */
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	for (kk = 0; kk < nkwd; kk++) {
		if (!isalnum(*p)) break;
		kwd[kk] = *p++;
	}
	if (kk >= nkwd) return FALSE;

	kwd[kk] = '\0';
	*pos = p - str;
	return TRUE;
}

static BOOL hex_range(char *str,int *pos,WORD *start,WORD *end)
{
	char *p;

	if (!hex_value(str,pos,start)) return FALSE;

	/* Skip leading white space */
	p = str + *pos;
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	if (*p != '-') return FALSE;
	*pos = (p - str) + 1;

	return hex_value(str,pos,end);
}

static BOOL hex_value(char *str,int *pos,WORD *value)
{
	int kk;
	char *p;
	char temp[8];

	/* Skip leading white space */
	p = str + *pos;
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	for (kk = 0; kk < 5; kk++) {
		if (!isxdigit(*p)) break;
		temp[kk] = *p++;
	}
	if (kk >= 5) return FALSE;
	temp[kk] = '\0';
	sscanf(temp,"%x",value);
	*pos = p - str;
	return TRUE;
}

static BOOL dec_value(char *str,int *pos,int *value)
{
	int kk;
	char *p;
	char temp[8];

	/* Skip leading white space */
	p = str + *pos;
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	for (kk = 0; kk < 7; kk++) {
		if (!isdigit(*p) && !(kk == 0 && *p == '-')) break;
		temp[kk] = *p++;
	}
	if (kk >= 7) return FALSE;
	temp[kk] = '\0';
	sscanf(temp,"%d",value);
	*pos = p - str;
	return TRUE;
}

static BOOL sep_char(char *str,int *pos,int sep)
{
	char *p;

	/* Skip leading white space */
	p = str + *pos;
	while (*p && isspace(*p)) p++;
	if (!(*p)) return FALSE;

	if (*p != (char)sep) return FALSE;
	*pos = (p - str) + 1;
	return TRUE;
}
/* Wed Mar 13 21:26:53 1991 :  new */
