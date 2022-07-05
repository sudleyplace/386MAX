/*' $Header:   P:/PVCS/MAX/ASQENG/ADF.C_V   1.2   02 Jun 1997 14:40:02   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ADF.C								      *
 *									      *
 * Functions to read adapter description files				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>

#include <commdef.h>		/* Common definitions */
#include <engine.h>		/* Engine functions */
#include "adf.h"                /* ADF file functions */
#include <commfunc.h>		/* Utility functions */
#include <saveadf.h>

#define ADF_C
#include "engtext.h"            /* Text strings */

typedef enum _adfstate {	/* ADF processing states */
	ADF_UNKNOWN,		/* Unknown state */
	ADF_EATLN,		/* Eat rest of current line */
	ADF_KW, 		/* Process keyword */
	ADF_NUM,		/* Process numeric value */
	ADF_QUOTE,		/* Process quoted string */
	ADF_BRKT1,		/* Process [n] */
	ADF_BRKT2,		/* Process [n] */
	ADF_BRKT3,		/* Process [n] */
	ADF_EQUAL1,		/* Process =token */
	ADF_EQUAL2,		/* Process =token */
	ADF_RANGESEP,		/* Process MEM xxxxx - yyyyy separator */
	ADF_DONE,		/* Done processing */
	ADF_TOOBIG		/* Off the scale */
} ADFSTATE;

typedef enum _kwcode {		/* Keyword code numbers */
	KW_UNKNOWN,		/* Unknown keyword */
	KW_AID, 		/* Adapter id */
	KW_ANAME,		/* Adapter name */
	KW_PROMPT,		/* Prompt text */
	KW_CHOICE,		/* Choice text */
	KW_POS, 		/* POS register */
	KW_MEM, 		/* MEM range for choice */
	KW_TOOBIG		/* Off the scale */
} KWCODE;

static int Nspec = -1;		/* How many chars in adf spec */
static char AdfSpec[80] = { MSG6000 }; /* Where to find ADF files */

/* Local functions */
static void add_choice( 	/* Add ADF choice to option structure */
	ADFOPTION *option,	/* Pointer to option structure */
	ADFCHOICE *choice);	/* Pointer to choice structure */

static void add_option( 	/* Add ADF option to info structuret */
	ADFINFO *info,		/* Pointer to info structure */
	ADFOPTION *option);	/* Pointer to option structure */

/* In TESTMEM.ASM: 1 byte per 4K block in high DOS */
/* 0x03 indicates NOSCAN; 0x07 indicates adapter memory (and NOSCAN) */
extern unsigned char pascal TESTMEM_MAP[1];

/*
 *	adf_setup - Collect and verify ADF file spec.
 */

int adf_setup(void)
{
	BOOL err;
	struct find_t find;	/* File find structure */
	char temp[MAXFILELENGTH];

	reportEval(EVAL_ADF);
	if (check_adf_files(temp,sizeof(temp))) {
		/* Already have valid .ADF files */
		strncpy(AdfSpec,temp,sizeof(AdfSpec)-1);
		AdfSpec[sizeof(AdfSpec)-1] = '\0';
		Nspec = trim(AdfSpec);
		return 1;
	}

	err = FALSE;
	for (;;) {
		int rtn;

		if (!adf_spec(AdfSpec,sizeof(AdfSpec)-12,err)) return -1;
		Nspec = trim(AdfSpec);
		if (Nspec < 1) continue;
		if (AdfSpec[Nspec-1] != '\\') {
			strcat(AdfSpec,"\\");
			Nspec++;
		}

		strcpy(AdfSpec+Nspec,MSG6001);
		rtn = _dos_findfirst(AdfSpec,_A_ARCH | _A_HIDDEN | _A_SYSTEM | _A_RDONLY,&find);
		AdfSpec[Nspec] = '\0';
		if (rtn == 0) {
			if (save_adf_files(AdfSpec,temp)) {
				strncpy(AdfSpec,temp,sizeof(AdfSpec)-1);
				AdfSpec[sizeof(AdfSpec)-1] = '\0';
				Nspec = strlen (AdfSpec);
			}
			return 1;
		}
		err = TRUE;
	}
}

/*
 *	adf_read - Read and interpret an Adapter Description File
 *
 *	Takes either an explicit file name, or an adapter id number,
 *  opens the corresponding ADF file, and reads selected information
 *  into a structure.
 */

static	ADFINFO info;		/* Scratch info structure */
static	ADFOPTION option;	/* Scratch option structure */
static	ADFCHOICE choice;	/* Scratch choice structure */

#pragma optimize ("eg",off)     /* Function too large for these optimizations */
int adf_read(
	char *name,		/* Name of file if not NULL */
	MCAID *pMCAid,		/* Board ID if no name given */
	SYSBUFH *infh)		/* Handle to ADFINFO struct returned here */
{
	FILE *fp;		/* Stream pointer */
	int ntemp;		/* Scratch char count */
	int posnum;		/* Scratch POS number */
	long lnum;		/* Scratch */
	ADFSTATE state; 	/* Processing state */
	KWCODE keycode; 	/* Keyword ID code */
	WORD id;		/* Adapter ID */
	char temp[128]; 	/* Temp char storage */
	WORD memstart, memend;	/* MEM range */

	static struct _kwds { /* Keyword table */
		char	*name;	   /* Keyword name */
		int	 code;	   /* Keyword id code */
	} kwds[] = {
		MSG6002,	KW_AID,
		MSG6003,	KW_ANAME,
		MSG6004,	KW_PROMPT,
		MSG6005,	KW_CHOICE,
		MSG6006,	KW_POS,
		MSG6006b,	KW_MEM,
		MSG6008,	0,
		NULL, 0, { 0 }
	};

	/* Init everything */
	memset(&info,0,sizeof(info));
	memset(&option,0,sizeof(option));
	memset(&choice,0,sizeof(choice));
	posnum = 0;
	id = pMCAid->aid;

	/* Set up the file spec */
	if (!name) {
		sprintf(AdfSpec+Nspec,MSG6007,id);
	}
	else	strcpy(AdfSpec+Nspec,name);

	/* Try to open it */
	fp = fopen(AdfSpec,"r");
	AdfSpec[Nspec] = '\0';
	if (!fp) return -1;

	/* It's open, run state machine to pick out the info that
	 * we care about.
	 */
	keycode = 0;
	ntemp = 0;
	state = ADF_UNKNOWN;
	for (; state != ADF_DONE; ) {
		int c;

		c = fgetc(fp);
		if (c == EOF) break;

		switch (state) {
		case ADF_UNKNOWN: /* Unknown or baseline state */
			switch (c) {
			case ';':
				state = ADF_EATLN;
				break;
			case '!':
				state = ADF_EATLN;
				break;
			case '"':
				ntemp = 0;
				state = ADF_QUOTE;
				break;
			case '=':
				ntemp = 0;
				state = ADF_EQUAL1;
				break;
			case '[':
				ntemp = 0;
				state = ADF_BRKT1;
				break;
			case '-':
				ntemp = 0;
				state = ADF_RANGESEP;
				break;
			default:
				if (isdigit(c)) {
					state = ADF_NUM;
				}
				else if (isalpha(c)) {
					state = ADF_KW;
				}
				else	break;

				ntemp = 0;
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			break;
		case ADF_KW:	/* Acquiring keyword or other token */
			if (isalnum(c)) {
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			else {
				int k;

				ungetc(c,fp);
				state = ADF_UNKNOWN;
				for (k=0; kwds[k].name; k++) {
					if (strcmpi(temp,kwds[k].name) == 0) {
						if (kwds[k].code) {
							keycode = kwds[k].code;
						}
						break;
					}
				}
				if (!kwds[k].name) {
					keycode = KW_UNKNOWN;
				}
			}
			break;

		case ADF_RANGESEP: /* Process range separator for MEM x - y */
			while (strchr (" \t\n-", c) && c != EOF) c = fgetc(fp);
			if (c == EOF) break;
			/* else fall through */
		case ADF_NUM:	/* Process numeric constant */
			if (isxdigit(c)) {
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			else {
				int oldstate = state;

				if (toupper(c) == 'H') {
					sscanf(temp,"%lx",&lnum);
				}
				else {
					ungetc(c,fp);
					sscanf(temp,"%ld",&lnum);
				}
				state = ADF_UNKNOWN;
				if (keycode == KW_AID) {
					/* Adapter id number */
					if ((WORD)lnum == id) {
						info.aid = (WORD)lnum;
					}
					else if (info.aid != 0) {
						/* Saw an id but already have ours, all done */
						state = ADF_DONE;
					}
				} /* Process adapterid xxxx */
				if (keycode == KW_MEM) {

				  if (oldstate == ADF_RANGESEP) {

					memend = (WORD) (lnum / 16L);

					if (*choice.name &&
						memend >= memstart &&
						lnum >= 0xA0000L) {

					  int posidx;

					  for (posidx = 0;
						posidx < 4; posidx++) {

					    if (*choice.pos[posidx] &&
						!pos_test (pMCAid->pos[posidx],
						  choice.pos[posidx])) break;

					  } /* For all POS bytes */

					  /* Mark TESTMEM_MAP entries for */
					  /* this range. */
					  if (posidx == 4)
					    for (memstart = (max (0xA000,
						 memstart) - 0xA000) / 0x0100,
						 memend = (memend - 0xA000)
								/ 0x0100;
						memstart <= memend;
						memstart++)
						   TESTMEM_MAP[memstart] = 0x07;

					} /* Valid choice exists */

				  } /* Got a MEM range; see if it matches */
				    /* current choice. */
				  else {

					if (lnum > 0xfffffL) memstart = 0xffff;
					else memstart = (WORD) (lnum / 16L);

				  } /* Got first part of a MEM range */

				} /* Process MEM xxxxx - yyyyy */

			} /* End of a numeric value */
			break;
		case ADF_QUOTE: /* Process quoted string */
			if (c != '"') {
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			else {
				if (keycode == KW_ANAME) {
					/* Adapter name */
					if (info.aid) {
						info.name[sizeof(info.name)-1] = '\0';
						strncpy(info.name,temp,sizeof(info.name)-1);
					}
				}
				else if (keycode == KW_PROMPT && info.aid) {
					/* Prompt for option */
					if (*option.name) {
						if (*choice.name) {
							add_choice(&option,&choice);
							memset(&choice,0,sizeof(choice));
						}
						add_option(&info,&option);
						memset(&option,0,sizeof(option));
					}
					option.name[sizeof(option.name)-1] = '\0';
					strncpy(option.name,temp,sizeof(option.name)-1);
				}
				else if (keycode == KW_CHOICE && info.aid) {
					/* Option choice */
					if (*choice.name) {
						add_choice(&option,&choice);
						memset(&choice,0,sizeof(choice));
					}
					choice.name[sizeof(choice.name)-1] = '\0';
					strncpy(choice.name,temp,sizeof(choice.name)-1);
				}
				state = ADF_UNKNOWN;
			}
			break;
		case ADF_BRKT1: 	/* Process [n] */
			if (!isspace(c)) {
				ungetc(c,fp);
				state = ADF_BRKT2;
			}
			break;
		case ADF_BRKT2: 	/* Process [n] */
			if (isxdigit(c)) {
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			else {
				if (toupper(c) == 'H') {
					sscanf(temp,"%lx",&lnum);
				}
				else {
					ungetc(c,fp);
					sscanf(temp,"%ld",&lnum);
				}
				state = ADF_BRKT3;
				if (keycode == KW_POS && *choice.name) {
					posnum = (int) lnum;
				}
			}
			break;
		case ADF_BRKT3: 	/* Process [n] */
			if (c == ']') {
				state = ADF_UNKNOWN;
			}
			break;
		case ADF_EQUAL1:	/* Process token after equal sign */
			if (!isspace(c)) {
				ungetc(c,fp);
				state = ADF_EQUAL2;
			}
			break;
		case ADF_EQUAL2:	/* Finish token after equal sign */
			if (!isspace(c)) {
				if (ntemp < sizeof(temp)-1) {
					temp[ntemp++] = (char) c;
					temp[ntemp] = '\0';
				}
			}
			else {
				if (keycode == KW_POS && *choice.name) {
					/* POS string */
					choice.pos[posnum][sizeof(choice.pos[posnum])-1] = '\0';
					strncpy(choice.pos[posnum],temp,sizeof(choice.pos[posnum])-1);
				}
				state = ADF_UNKNOWN;
			}
			break;
		case ADF_EATLN: /* Eat rest of line */
			if (c == '\n') {
				state = ADF_UNKNOWN;
			}
			break;
		}
	}
	fclose(fp);
	if (*choice.name) {
		add_choice(&option,&choice);
	}
	if (*option.name) {
		add_option(&info,&option);
	}

	/* Store the info structure */
	sysbuf_store(infh,&info,sizeof(info));
	return 0;
}
#pragma optimize ("",on)


void add_choice(		/* Add ADF choice to option structure */
	ADFOPTION *option,	/* Pointer to option structure */
	ADFCHOICE *choice)	/* Pointer to choice structure */
{
	SYSBUFH h;

	sysbuf_store(&h,choice,sizeof(ADFCHOICE));
	option->nchoice++;
	if (option->lchoice) {
		ADFCHOICE *p;

		p = sysbuf_ptr(option->lchoice);
		p->next = h;
		option->lchoice = h;
	}
	else {
		option->fchoice = option->lchoice = h;
	}

}

void add_option(		/* Add ADF option to info structure */
	ADFINFO *info,		/* Pointer to info structure */
	ADFOPTION *option)	/* Pointer to option structure */
{
	SYSBUFH h;

	sysbuf_store(&h,option,sizeof(ADFOPTION));
	info->noption++;
	if (info->loption) {
		ADFOPTION *p;

		p = sysbuf_ptr(info->loption);
		p->next = h;
		info->loption = h;
	}
	else {
		info->foption = info->loption = h;
	}
}

/* Wed Mar 13 21:04:47 1991 alan:  fix bugs */
