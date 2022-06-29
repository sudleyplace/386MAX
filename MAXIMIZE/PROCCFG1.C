/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PROCCFG1.C_V   1.1   26 Oct 1995 21:54:24   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PROCCFG1.C								      *
 *									      *
 * Create new MAX/Move'EM.PRO file                                            *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <intmsg.h>		/* Intermediate message functions */

#define PROCCFG1_C
#include <maxtext.h>		/* MAXIMIZE message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef PROCCFG1_C

#ifndef PROTO
#include "copyfile.pro"
#include "linklist.pro"
#include "maximize.pro"
#include <maxsub.pro>
#include "proccfg1.pro"
#include "profile.pro"
#include "screens.pro"
#include "wrconfig.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */

static void elim_overlap (ETYPE etype);

/************************************ PROCCFG1 ********************************/

void proccfg1( BOOL bStripVGASwap, BOOL bStripUseHigh )
{
	/*------------------------------------------------------*/
	/*	Backup 386MAX profile file			*/
	/*------------------------------------------------------*/

	savefile (PROFILE);
	restbatappend (PROFILE);

	/*------------------------------------------------------*/
	/*	Create 386MAX profile file and write all lines	*/
	/*------------------------------------------------------*/

	wrprofile( bStripVGASwap, bStripUseHigh );

} /* End PROCCFG1 */

/*********************************** WRPROFILE ********************************/

void wrprofile( BOOL bStripVGASwap, BOOL bStripUseHigh )
{
	FILE *ot;
	PRSL_T *r;
	char *s, *s2, buff[256];
	int ndx;

	if (AnyError)		/* If something went wrong, */
		return; 		/*  just return */

	do_intmsg(MsgWrtFile,ActiveFiles[PROFILE]);

	elim_overlap (RAM);	/* Eliminate overlapping RAM= statements */
	elim_overlap (USE);	/* ...			 USE= */

	if (bStripVGASwap) {
		for (r = CfgHead; r; r = r->next) {
			if (r->data->etype == VGASWAP) r->data->etype = NULLOPT;
		} // for all profile statements
	} // Remove VGASwap

	if (bStripUseHigh) {
		for (r = CfgHead; r; r = r->next) {
			if (r->data->etype != USE) continue;
			if (r->data->saddr >= 0xf000L) r->data->etype = NULLOPT;
		} // for all profile statements
	} // Remove USE= statements in ROM

	disable23 ();

	if (ForceIgnflex) replace_in_profile (IGNOREFLEXFRAME, MsgIgnoreFlex, 0L, 0L);

	/*---------------------------------------------------------*/
	/*	Create 386MAX profile file			       */
	/*---------------------------------------------------------*/

	if ((ot = fopen (ActiveFiles[PROFILE], "w")) != NULL)
	{
		for (r = CfgHead ; r ; r = r->next)

			/*-----------------------------------------------------*/
			/*  Create a line in file for each struct in list      */
			/*  If type = 0, copy original string		       */
			/*-----------------------------------------------------*/
		{

			/* Ignore any lines we've marked for deletion */
			if (r->data->etype == NULLOPT) continue;

			memset (buff, '\0', sizeof (buff)); /* Initialize for STRCAT/STRNCPY */

			if (r->data->etype == 0) {
				if (r->data->origstr) {
					strcpy (buff, r->data->origstr);
				}
			}
			else {
				/*-------------------------------------------------*/
				/*  Generate entry				   */
				/*-------------------------------------------------*/


				/* Find the corresponding argument type */
				ndx = 0;
				while (Options[ndx].etype != r->data->etype)
					ndx++;

				/* If there is a parameter, copy the original keyword */
				/*   up to and including the equal sign. */
				if (r->data->origstr) {
					if (NULL != (s = strchr (r->data->origstr, '=')))
						strncpy (buff, r->data->origstr, 1 + s - r->data->origstr);
					else
						strcpy (buff, r->data->origstr);
				} /* End IF */
				else		/* Otherwise, use standard name */
					strcpy (buff, Options[ndx].name);

				switch (Options[ndx].atype) /* Based upon argument type */
				{
				case ONEHEXADDR:	    /* FRAME= */
					sprintf (stpend(buff), "%lX", r->data->saddr);
					break;

				case OPTSIZE:
					/* Note that the first argument is */
					/* optional and the second one is */
					/* required. */
					if (r->data->saddr) /* XBDAREG=size,r */
					  sprintf (stpend (buff), "%ld,%ld",
						r->data->saddr, r->data->eaddr);
					else
					  sprintf (stpend (buff), "%ld",
						r->data->eaddr);
					break;

GOTO_NUMADDR:
				case NUMADDR:
					sprintf (stpend(buff), "%ld", r->data->saddr);
					break;

				case POSNAME:
				case BCFNAME:
				case ADDRLIST:
					if (s2 = strchr (r->data->origstr, '='))
						strcat (buff, s2 + 1);
					break;

				case PROADDR:
				case NOADDR:
					break;

				case OPTADDR:
					if (r->data->eaddr == 0) /* INCLUDE= */
						goto GOTO_NUMADDR;
					/* Else fall through to HEXADDR */
				case HEXADDR:
					sprintf (stpend(buff), "%lX-%lX",
					r->data->saddr & 0xFFFFFF00, /* Round down to 4KB in paras */
					(r->data->eaddr + (4096/16) - 1) & 0xFFFFFF00);
					break;

				} /* End SWITCH */
			} /* End IF/ELSE */

			/*---------------------------------------------*/
			/*	Copy the comment, if any		   */
			/*---------------------------------------------*/

			if (r->data->comment)
				strcat (buff, r->data->comment);

			fputs_text (buff, ot); /* Output w/trailing LF */

		} /* End FOR/IF */

		fclose (ot);

#ifdef STACKER
		SwapUpdate (PROFILE);
#endif			/* ifdef STACKER */
	} /* End IF */
	else
		AnyError = 1;

	enable23 ();

} /* End WRPROFILE */

/******************************** ELIM_OVERLAP ********************************/
/* Eliminate and consolidate overlapping structures, */

#define MAXRAM 20

static void elim_overlap (ETYPE etype)

{
	PRSL_T *r, *hr[MAXRAM];
	int cnt, j, k, swap;

	for (j = 0 ; j < MAXRAM ; j++)	/* NULL the array; */
		hr[j] = NULL;

	for (cnt = 0, r = CfgHead; r; r = r->next)
		if (r->data->etype == etype)	/* Find and count matching structures */
			hr[cnt++] = r;

	if (cnt < 2)			/* If 0 or 1, nothing to do */
		return;

	/* Sort entries by start address */
	swap = TRUE;
	while (swap)
	{
		swap = FALSE;
		for (j = 0, k = 1; j < cnt - 1; j++, k++)
			if (hr[j]->data->saddr > hr[k]->data->saddr)
			{
				r = hr[j];
				hr[j] = hr[k];
				hr[k] = r;
				swap = TRUE;
			} /* End FOR/IF */
	} /* End WHILE */

	/* Force overlapping entries to have the same start and end address */
	for (j = 0, k = 1; j < cnt - 1; j++, k++)
		/* If both starting addr same, force both ending addr to larger */
	{
		if (hr[j]->data->saddr == hr[k]->data->saddr)
			hr[k]->data->eaddr = hr[j]->data->eaddr = max (hr[j]->data->eaddr,
			hr[k]->data->eaddr);

		/* If 1st ending addr > 2nd starting addr, */
		/*   force both starting addr to smaller */
		/*   and   both ending	 addr to larger */
		if (hr[j]->data->eaddr > hr[k]->data->saddr)
		{
			hr[k]->data->saddr = hr[j]->data->saddr = min (hr[j]->data->saddr,
			hr[k]->data->saddr);
			hr[k]->data->eaddr = hr[j]->data->eaddr = max (hr[j]->data->eaddr,
			hr[k]->data->eaddr);
		} /* End IF */
	} /* End FOR */

	/* Remove all entries with same start address keeping the last one */
	for (j = 0, k = 1; j < cnt - 1; j++, k++)
		if (hr[j]->data->saddr == hr[k]->data->saddr)
			delfromlst (hr[j], 1);

} /* End ELIM_OVERLAP */
