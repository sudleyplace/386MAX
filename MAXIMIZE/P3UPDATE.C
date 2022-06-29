/*' $Header:   P:/PVCS/MAX/MAXIMIZE/P3UPDATE.C_V   1.0   05 Sep 1995 16:33:14   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * P3UPDATE.C								      *
 *									      *
 * Update files, MAXIMIZE pass 3					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Local includes */
#include <intmsg.h>		/* Intermediate message functions */

#define P3UPDATE_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef P3UPDATE_C

#ifndef PROTO
#include "browse.pro"
#include "linklist.pro"
#include <maxsub.pro>		/* Prototypes for MAXSUB.ASM */
#include "p3update.pro"
#include "profile.pro"
#include "screens.pro"
#include "util.pro"
#include "wrfiles3.pro"
#endif /*PROTO*/

/* Local variables */
static WORD LowProgs;			/* # programs loaded low */

/* Local functions */
static void p3gldprm (DSPTEXT *t, int ind);
static void procline (DSPTEXT *t);

#ifdef HARPO
void update_subcount (void)
/* Update HighParas / LowParas with subsegment data */
/* Update *REG= lines in MAX profile */
{
 SUBFIT *psub;
 SUBSID *psid;

 if (psub = psubsegs) {
	while (psub->lseg) {
	    /* We need to add a MAC entry for subsegments */
	    /* only when they're loaded in high DOS */
	    if (psub->newreg)	HighParas += psub->rpara + HSMACSIZE(psub);
	    else		LowParas += psub->rpara;
	    if (psub->ownr == SFO_MAX) {

		/* Clobber all previously existing lines */
		del_from_profile ((ETYPE) psub->type);

		/* We always need to add an explicit *REG= for */
		/* MAX subsegments in case there's an XBIOSHI or */
		/* STACKS= /h */
		psid = subsid (psub);
		strcpy (TempBuffer, psid->keywd);
		sprintf (stpend (TempBuffer), psid->comment, psub->newreg,
			16L * psub->rpara);
		add_to_profile ((ETYPE) psub->type, TempBuffer,
			16L * psub->rpara, (DWORD) psub->newreg);

	    } /* Owner is MAX.SYS */
	    psub++;	/* Skip to next subsegment */
	} /* for all subsegments */
 } /* Subsegments exist */

} /* End update_subcount () */
#endif

void update_count (SUMFIT far *psum)
/* Initialize HighParas and LowParas and check for MAX loading low */
{
	CONFIG_D *pptr;
	PRSL_T *tptr;
	char xlhiflag = 0;

	HighParas = LowParas = 0;
	/* Check for NOLOADHI and NOLOADHIGH */
	for (tptr = CfgHead ; tptr ; tptr = tptr->next) {
		pptr = tptr->data;
		if (pptr->etype == NOLOADHI || pptr->etype == NOLOADHIGH)
		{
			xlhiflag = 1;	/* Mark as present */
			psum->preg = 0; /* Mark as PRGREG=0 */
			break;
		} /* End IF */
	} /* End FOR */

	/*--------------------------------------------------------------*/
	/*	if NOLOADHI present, ignore PRGREG			*/
	/*	if preg == 0, insert PRGREG=0				*/
	/*	if preg == 1, remove PRGREG=n				*/
	/*	if preg >  1, insert PRGREG=preg			*/
	/*--------------------------------------------------------------*/

	/* Use brute force method of adding PRGREG=n, */
	/* since there may be an existing statement in */
	/* the common area. */
	del_from_profile (PRGREG);
	if (!xlhiflag)
		if (psum->preg != 1) {
			sprintf (TempBuffer, MsgPRGREG, psum->preg, MAXSYS);
			add_to_profile (PRGREG, TempBuffer, (DWORD) psum->preg, 0L);
		} /* End IF */

} /* End update_count () */

/***************************** P3UPDATE ***************************************/

void p3update (SUMFIT far *psum) /* SUMFIT array pointer */
{
	SUMFIT far *psumfit;
	SUMFIT far *psumend;
	BOOL *psumvec;
	BOOL *psvec;
	DSPTEXT *t;		/* Points to a DSPTEXT structure */
	int ii;
	BATFILE *b;

	update_count (psum);	/* Initialize High/LowParas and check for */
				/* 386MAX PRGREG */

	/*----------------------------------------------------------------------*/
	/*	Go thru CONFIG.SYS lines and identify loaded modules		*/
	/*	A module is to be loaded into high DOS memory if it		*/
	/*									*/
	/*	* is marked (any Device= following 386MAX or any Install=)	*/
	/*	* has an entry in SUMFIT and that entry has a non-zero		*/
	/*	  program region.						*/
	/*									*/
	/*	In theory, all marked lines have an entry in SUMFIT.		*/
	/*	In theory, all non-UMB entries in SUMFIT are referenced 	*/
	/*	  by marked lines.
	/*									*/
	/*----------------------------------------------------------------------*/

	/* Note that all lines initially are marked as not to be */
	/* loaded high (t->high == 0) */

	/* Account for # paras in 386MAX to be moved into high DOS memory */
	if (psum->preg)
		HighParas += psum->rpara + MACSIZE(psum);
		/* Resident size (plus MAC entry) */
	else
		LowParas += psum->rpara + MACSIZE(psum);

#ifdef HARPO
	/* Count in any subsegments */
	/* Note that the HARPO subsegments get processed when we're ready */
	/* to write everything to disk.  Here we're just updating */
	/* High/LowParas and updating MAX profile lines based on */
	/* MAX subsegments. */
	update_subcount ();
#endif

	/* Set up a vector to track which SUMFIT items we've processed */
	psumfit = psum + 1;	/* Start at entry following 386MAX */
				/* as we don't generate a new line */
				/* in CONFIG.SYS for it */
	psumend = psumfit;
	while (psumend->lseg != 0) psumend++;

	psumvec = get_mem((psumend-psumfit)*sizeof(BOOL));

	/* Process Device= and Install= lines */
	for (t = HbatStrt[CONFIG] ; t ; t = t->next) {
		if (t->device == 1 || t->device == 2) {
			/* If it's a marked Device= line */
			procline (t); /* Process the Device= line */
			if (t->psumfit) {
				psumvec[t->psumfit-psumfit] = TRUE;
			}
		}
	}

	/*------------------------------------------------------------*/
	/*	Now build CONFIG.SYS text lines ready to write to file	  */
	/*------------------------------------------------------------*/

	for (t = HbatStrt[CONFIG] ; t ; t = t->next)
		if (t->max == 2)		/* If it's to be processed */
			p3gldprm(t, 0); 	/* Generate the new line */

	/*--------------------------------------------------------------*/
	/*	Go through .BAT file lines and identify loaded modules	*/
	/*								*/
	/*	Process the .BAT files in the same order as they were	*/
	/*	encountered in MAXIMIZE.OUT				*/
	/*--------------------------------------------------------------*/

	for (b = FirstBat; b ; b = b->nextbat) {
		if (b->batline->mark) {
			/* If it's marked */
			procline (b->batline); /* Process the .BAT line */
			if (b->batline->psumfit) {
				psumvec[b->batline->psumfit-psumfit] = TRUE;
			}
		}
	}

	/* Tell the user about any unprocessed SUMFIT entries
	 *
	 * This condition happens when we have a SUMFIT entry (derived
	 * from an LSEG(FIT) entry) without a matching DSPTEXT entry,
	 * as matched by link_sumfit.  In theory, this should not happen.
	 * The most likely cause would be some bizarre technique in the
	 * batch file.
	 */

	for (psvec = psumvec; psumfit->lseg; psumfit++,psvec++) {
		LSEGFIT far *plseg;
		char lsegname[1 + sizeof (plseg->name)];

		if (psumfit->flag.umb) {
			/* Include any UMBs in HighParas count */
			HighParas += psumfit->rpara + MACSIZE(psumfit);
			/* Resident size (plus MAC entry) */
			continue;		/* Go around again */
		} /* End IF */

#ifdef HARPO
		if (psumfit->grp == GRP_HIPROG) {
			if (psumfit->preg)	HighParas += psumfit->rpara +
							psumfit->epar1 +
							HMACSIZE(psumfit);
			else			LowParas += psumfit->rpara +
							psumfit->epar1;
			continue;
		} /* End if (program loaded high by HARPO) */
#endif

		if (*psvec) {
			/* We processed it already */
			continue;
		}

		/* Copy program name from LSEG */
		plseg = FAR_PTR(psumfit->lseg,0);
		_fmemcpy(lsegname,plseg->name,sizeof(plseg->name));

		/* Ensure properly terminated */
		lsegname[sizeof(plseg->name)] = '\0';

		/* Warning message:  Unprocessed resident program:... */
		do_intmsg (MsgUnpRes, lsegname);
	} /* End FOR */

	/* Toss the SUMFIT vector */
	free_mem(psumvec);

	/*------------------------------------------------------------*/
	/*	Now build .BAT file text lines ready to write to file	  */
	/*------------------------------------------------------------*/

	for (ii = BATFILES ; ii < MAXFILES && HbatStrt[ii] ; ii++) {
		/* For each .BAT file */
		for (t = HbatStrt[ii] ; t ; t = t->next) {
			if (t->mark) {		/* If not a device, skip it */
				p3gldprm (t, 1);	/*   Generate .BAT line */
			}
		}
	}

	/* Tell the user how much data we're moving into high DOS */
	/* Moving %s bytes into high DOS memory */
	/*dointcolor*/
	do_intmsg (MsgMovHigh,ltoe (((DWORD) BESTSIZE) << 4, 0));

} /* End P3UPDATE */

/******************************** P3GLDPRM ************************************/

static void p3gldprm (DSPTEXT *t, int ind)

{
	SUMFIT far *psum;
	DWORD num;
	char buff[256];

	/* Copy leading chars to preserve blanks */
	strncpy (buff, t->text, t->nlead);
	buff[t->nlead] = '\0';

	/* Now we can free the original T->TEXT */
	free_mem (t->text);

	if (!t->high)	/* If not loaded, use pdevice */
		strcat (buff, t->pdevice);
	else
	{
		/* Build loader name */
		if (t->device == (BYTE) DSP_DEV_DEVICE) {
			sprintf (stpend (buff), "%s" LOADERS, LoaderTrue);
		}
		else {
			sprintf (stpend (buff), "%s%s", LoadTrue, ind ? LOADER : LOADERC);
		}

		/* Compute SIZE= and put into line */
		psum = t->psumfit;
		num = psum->ipara;
		num <<= 4;
		sprintf (stpend (buff), " size=%ld ", num);

		/* If forced SIZE=, put it into the line as well */
		if (psum->flag.fsiz) {
			LSEGFIT far *plseg;

			plseg = FAR_PTR(psum->lseg,0);
			num = plseg->rpar2;	/* Get # required paras */
			num <<= 4;			/* Convert from paras to bytes */
			sprintf (stpend (buff) - 1, ",%ld ", num);
		} /* End IF */

		/* Add PRGREG= if needed */
		if (psum->preg > 1)
			sprintf (stpend (buff), "prgreg=%d ", psum->preg);

		/* Add ENVREG= if needed */
		if (ind == 1 || t->device == 2)        /* If it's .BAT or Install= */
			if (psum->ereg != 0 && psum->preg != psum->ereg)
				sprintf (stpend (buff), "envreg=%d ",  psum->ereg);

		t->opts.envreg = 0;	/* Set to zero */
		t->opts.prgreg = 0;	/*   so that P2GLDPRM won't generate */
		strcat (buff, br_gldprm (t)); /* Get loader parameters */
		strcat (buff, "prog=");      /* And now the */
		strcat (buff, t->pdevice);   /*   program to be loaded */
	} /* End ELSE */

	t->text = str_mem (buff);

} /* End P3GLDPRM */

/*********************************** PROCLINE *********************************/
/* Process a line in CONFIG.SYS or a .BAT file */
/* Return # entries in SUMFIT to skip if we found a match in SUMFIT, */
/* 0 otherwise.  This value may be more than one if there are */
/* intervening UMBs. */

static void procline (DSPTEXT *t)
{
	if (!t->psumfit || !t->mark) return;
	if (t->psumfit->preg) {
		/* If it's to be loaded high */
		LSEGFIT far *plseg;

		plseg = FAR_PTR(t->psumfit->lseg,0);

		t->high = 1;		/* Mark it to be loaded high */
		t->opts.flex = plseg->flag.flex; /* Copy what MAXIMIZE says */

		/* Account for # paras to be moved into high DOS memory */
		/* Resident size (plus MAC entry) */
		HighParas += t->psumfit->rpara + MACSIZE(t->psumfit);

		if (!(t->psumfit->flag.drv) && /* If not a device */
		    !t->psumfit->flag.umb)	/* and not a UMB, */
			HighParas += t->psumfit->epar1; /* ...add in resident environment size */
	} /* End IF */
	else if (!t->psumfit->flag.xres) {
		LowProgs++;		/* Count in another program loaded low */
		LowParas += t->psumfit->rpara + MACSIZE(t->psumfit);
	}
} /* End PROCLINE */
