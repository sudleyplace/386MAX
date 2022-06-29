/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PASS3.C_V   1.2   26 Oct 1995 21:54:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PASS3.C								      *
 *									      *
 * Mainline for MAXIMIZE, phase 3					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <p3debug.h>		/* Pass 3 debugging */

#define PASS3_C 	/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef PASS3_C

#ifndef PROTO
#include "reboot.pro"
#include "maximize.pro"
#include <maxsub.pro>
#include "readmxmz.pro"
#include "pass3.pro"
#include "p3update.pro"
#include "reorder.pro"
#include "screens.pro"
#include "wrfiles3.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local functions */

/************************************ PASS3 ***********************************/

void pass3 (void)
{
	int cfgmark = 0;	/* 1 = Marked lines in CONFIG.SYS, 0 = none */
	DSPTEXT *ts;
	SUMFIT far *psumfit;


	/* Read from MAXIMIZE.OUT */
	readmxmz();
#ifdef DEBUG_SUMFIT
	dump_maxout(DEBUGFILE,"w","After readmxmz()");
	dump_lseg(DEBUGFILE,"a","After readmxmz()");
#endif
	if (AnyError) return;

	/* Do first cut at MAXIMIZing, with no reorder */

	init_progress(MsgMaxInProg);
	psumfit = maximize(FALSE);
	end_progress();
#ifdef DEBUG_SUMFIT
	dump_lseg(DEBUGFILE,"a","after maximize");
	dump_sumfit(DEBUGFILE,"a","after maximize",psumfit);
#endif

	/* See if there are any marked lines in CONFIG.SYS */
	for (ts = HbatStrt[CONFIG]; ts; ts = ts->next) {
		if (ts->mark) {
			/* If there's one marked */
			cfgmark = 1;		/* Mark as found */
			break;			/* Break off to browse */
		} /* End FOR/IF */
	}

	/* Join SUMFIT to DSPTEXT */
	map_sumfit(psumfit,cfgmark);

	/* Save best SUMFIT */
	if (save_psumfit (psumfit)) {
#ifdef REORDER
		SUMFIT far *ps;
#ifdef HARPO
		SUBFIT far *psubseg;
#endif
		WORD lastbest = BESTSIZE;
		DWORD lowtotal;
		char sizediff[20];

		/* Check SUMFIT table for any items still loaded low */
		for (lowtotal = 0, ps = psumfit; ps->lseg; ps++) {
			// Some programs like HYPERDISK.EXE are left low
			// because the resident size is 0...
			if (!ps->preg && !ps->flag.xres) {
				/* Found one */
				lowtotal += (DWORD) ps->rpara;
			}
		}

#ifdef HARPO
		/* We may have loaded all the programs high, but not */
		/* all the subsegs.  Check for subsegs left low. */
		for (psubseg = psubsegs; psubseg->lseg; psubseg++) {
			if (!psubseg->newreg) {
			  lowtotal += (DWORD) psubseg->rpara;
			} /* found one left low */
		} /* for all subsegments */
#endif

		// If not everything went high and we're running Express
		// Maximize from Windows, don't tell 'em anything.
		if (lowtotal && (!FromWindows || QuickMax <= 0)) {
			/* We've determined that not everything went high. */
			/* If optimization took less than 30 seconds, see */
			/* if any possible gains may be made with no holds */
			/* barred on reordering, and display the */
			/* appropriate message. */
			strcpy (sizediff, ltoe (((DWORD) (TOTREG-BESTSIZE)) << 4, 0));
			do_textarg (2, sizediff);
			if (ELAPSED < 30L) {
				int bestdiff;

				init_progress(MsgReorTestInProg);
				psumfit = maximize(TRUE);
				end_progress();
				bestdiff = (int) BESTSIZE - (int) lastbest;
				BESTSIZE = lastbest;
				if (bestdiff <= 0) {
				    /* Nothing to be gained by reordering */
				    goto WRITE_FILES;
				} else {
				    /* Let the user know the maximum possible */
				    /* gain from reordering */
				    strcpy (sizediff, ltoe (((DWORD) bestdiff) << 4, 0));
				}
			} // Elapsed time less than 30 seconds

			if (QuickMax <= 0) {
				/* Some item(s) still low, maybe do reorder */
				psumfit = try_reorder(psumfit,cfgmark,lastbest);
				if (AnyError) return;

				/* User may have said 'no' to reordering, */
				/* reordering may have been aborted, or */
				/* we may not have done any better with */
				/* restrictions laid upon us. */
				if (psumfit) {
					(void) save_psumfit (psumfit);
				}
			}
			else {
				message_panel(MsgNoFit,0);
			}
		}
WRITE_FILES:
		/* Restore best SUMFIT */
		psumfit = rest_psumfit ();
#else
		;
#endif	/*REORDER*/
	}
	p3update(psumfit);
#ifdef DEBUG_SUMFIT
	dump_lseg(DEBUGFILE,"a","after p3update");
	dump_sumfit(DEBUGFILE,"a","after p3update",psumfit);
#endif

	if (AnyError) return;

	do_complete(psumfit);	/* Maximize complete screen */
	if (AnyError) return;

	if (!AnyError && doreboot () >= 0) {
		/* Display reboot screen */
		wrfiles3();	/* Write files - CONFIG .. etc. */
		if (!AnyError) {
			rebootmsg();	/* Display message */
			write_lastphase (Pass); /* Write out the last phase # */
			if (!AnyError) {
				/* If still no error */
				reboot();	/* Reboot the system */
			}
		} /* End IF */
	} /* End IF */

} /* End PASS3 */

/************************************* SAVE_PSUMFIT ***************************/
/* Save pointer value of psumfit and the chain of SUMFIT records it points to */
/* Also save pointer value of global psubssegs and the chain of SUBFIT */
/* records it points to. */

int save_psumfit (SUMFIT far *psumfit)
{
 char fname[_MAX_PATH];
 int fh;
#ifdef HARPO
 SUBFIT far *psubseg;
#else
 void far *nothing = NULL;
#endif

 sprintf (fname, SavePsumfitFname, LoadString);

 /* If we can't create the file, tough */
 if ((fh = _open (fname, O_WRONLY|O_BINARY|O_TRUNC|O_CREAT,
					S_IREAD|S_IWRITE)) == -1) {
	return (0);
 }

 _write (fh, &psumfit, sizeof(psumfit));
 _write (fh, &BESTSIZE, sizeof(BESTSIZE));
#ifdef HARPO
 _write (fh, &psubsegs, sizeof(psubsegs));
#else
 /* Make 386MAX and Move'EM MAXIMIZE.BST identical */
 _write (fh, &nothing, sizeof(nothing));
#endif

 for ( ; ; psumfit++) {
	_write (fh, psumfit, sizeof(SUMFIT));
	if (!psumfit->lseg)	break;
 }

#ifdef HARPO
 for (psubseg = psubsegs; ; psubseg++) {
	_write (fh, psubseg, sizeof(SUBFIT));
	if (!psubseg->lseg)	break;
 }
#endif

 _close (fh);

 return (1);

} // save_psumfit ()

#ifdef REORDER
/************************************* REST_PSUMFIT ***************************/
/* Restore psumfit and chain of SUMFIT records */

SUMFIT far *rest_psumfit (void)
{
 char fname[_MAX_PATH];
 int fh;
 SUMFIT far *ret, *cur;
#ifdef HARPO
 SUBFIT far *psubseg;
#else
 void far *nothing = NULL;
#endif

 sprintf (fname, SavePsumfitFname, LoadString);

 /* If we can't _read the file, we're in trouble deep */
 if (	(fh = _open (fname, O_RDONLY|O_BINARY)) == -1 ||
	_read (fh, &ret, sizeof(ret)) != sizeof(ret) ||
	_read (fh, &BESTSIZE, sizeof(BESTSIZE)) != sizeof(BESTSIZE)
#ifdef HARPO
	|| _read (fh, &psubsegs, sizeof(psubsegs)) != sizeof(psubsegs)
#else
	|| _read (fh, &nothing, sizeof(nothing)) != sizeof(nothing)
#endif
		) goto REST_FAIL;

 for (cur = ret; ; cur++) {
	if (_read (fh, cur, sizeof(SUMFIT)) != sizeof(SUMFIT))	goto REST_FAIL;
	if (!cur->lseg) break;
 }

#ifdef HARPO
 for (psubseg = psubsegs; ; psubseg++) {
	if (_read (fh, psubseg, sizeof(SUBFIT)) != sizeof(SUBFIT)) goto REST_FAIL;
	if (!psubseg->lseg) break;
 }
#endif

 _close (fh);

 return (ret);

REST_FAIL:
	do_error (MsgRestFail, TRUE);

} // rest_psumfit ()
#endif

/************************************* GETDEV *********************************/
/* S points to PDEVICE name (d:\path\filename.ext [args]) */

char * getdev (char *s)
{
	char *p;
	static char work[200];

	s = strncpy (work, s, sizeof (work) - 1); /* Copy to static work area */
	work[sizeof(work)-1] = '\0';            /* Ensure it's null terminated */
	p = strpbrk (s, ValPathTerms);		/* Find pathname terminator */
	if (p != NULL)				/* If found, */
		*p = '\0';                      /* ...zap it */
	if ((s = fnddev (s, 0)) == NULL)	/* Find beginning of file name */
		return (NULL);			/* Exit if not found ???? */
	return (s);
} /* End GETDEV */


/* Map SUMFIT entries to DSPTEXT lists */
void map_sumfit(SUMFIT far *psumfit,int cfgmark)
{
	BATFILE *b;

	/* Start at entry following 386MAX and skip any UMBs. */
	/* There may not be any marked DEVICE or INSTALL= programs. */
	for (psumfit++; psumfit->flag.umb; psumfit++) ;

	if (cfgmark) {
		/* Two passes:	One for device=, one for install= */
		DSPTEXT *t;

		for (t = HbatStrt[CONFIG]; t; t = t->next) {
			if (t->device == DSP_DEV_DEVICE && t->mark) {
				/* If it's a marked Device= line */
				psumfit += link_sumfit(t,psumfit);

				/* Skip UMBs following marked device */
				for ( ; psumfit->flag.umb; psumfit++) ;

			}
		}

		for (t = HbatStrt[CONFIG]; t; t = t->next) {
			if (t->device == DSP_DEV_INSTALL && t->mark) {
				/* If it's a marked Install= line */
				psumfit += link_sumfit(t,psumfit);

				/* Skip UMBs following marked INSTALL= */
				for ( ; psumfit->flag.umb; psumfit++) ;

			}
		}

	} /* if (cfgmark) */

#ifdef HARPO
	/* Skip HARPO COMMAND.COM entry */
	if (psumfit->grp == GRP_HIPROG) HarpoComspec = psumfit++;

	/* Skip HARPO implicit SHARE= entry */
	if (psumfit->grp == GRP_HIPROG) HarpoShare = psumfit++;
#endif

	for (b = FirstBat; b ; b = b->nextbat) {
		if (b->batline == NULL)
			continue;	// This should NOT occur!!!
		if (b->batline->mark || b->batline->umb) {
			/* If it's marked or a UMB allocator */
			psumfit += link_sumfit(b->batline,psumfit);
		}
	}
}

/* Link the SUMFIT and LSEGFIT table entries to matching DSPTEXT entries */
int link_sumfit(DSPTEXT *t,SUMFIT far *psumfit)
{
	LSEGFIT far *plseg;
	char *p1, lsegname[sizeof (plseg->name)];
	int retcnt = 0;

	// Skip non-trailing UMB's in CONFIG.SYS
	if (t->mark &&
	   (t->device == DSP_DEV_DEVICE || t->device == DSP_DEV_INSTALL))
	    while (psumfit && (psumfit->flag.umb
#ifdef HARPO
				|| psumfit->grp == GRP_HIPROG
#endif
				)) {
		psumfit++;
		retcnt++;
	    }

	plseg = FAR_PTR(psumfit->lseg,0); // LSEG entry we're matching here

	if (t->umb && psumfit->lseg != 0 && (psumfit->flag.umb
#ifdef HARPO
				|| psumfit->grp == GRP_HIPROG
#endif
			)) {
		/* (Unmarked) program allocates UMBs */
		t->psumfit = psumfit;	/* Set pointer to SUMFIT entry */
		t->plseg = plseg;	/* Set pointer to LSEGFIT entry */
		/* Note that UMB's may have vanished from the chain */
		/* after BATPROC saved the MAXIMIZE.OUT line.  This */
		/* happens in SMARTDRV's case. */
		for (psumfit++, retcnt=1; retcnt < (int) t->umb &&
				(psumfit->flag.umb
#ifdef HARPO
				 || psumfit->grp == GRP_HIPROG
#endif
							); retcnt++) psumfit++;
		goto bottom;
	} // Unmarked UMB allocator

	if (!t->mark) {
		/* Unmarked */
		goto bottom;
	} // Unmarked

	/* Ensure it has the same program name as in LSEG */
	_fmemcpy(lsegname,plseg->name,sizeof(plseg->name));

	p1 = getdev (t->pdevice);	/* Get Prog= name (wo/extension) */

	/* Allow batch file substitutions, or the names must match */
	if (strchr (p1, '%') || _strnicmp (p1, lsegname, strlen (p1)) == 0) {
		t->psumfit = psumfit;	/* Set pointer to SUMFIT entry */
		t->plseg = plseg;	/* Set pointer to LSEGFIT entry */
		psumfit++;
		retcnt++;		/* Mark as a match */
	} /* End IF */
	else {
		t->psumfit = NULL;
	} /* End IF */
bottom:
	return retcnt;

} /* End LINK_SUMFIT */

#ifdef DUMP_DEBUG
void dump_sumfit(char *fname,char *mode,char *tag,SUMFIT far *psumfit)
{
	WORD ipara_sum = 0;
	WORD rpara_sum = 0;
	WORD epar0_sum = 0;
	WORD epar1_sum = 0;

	FILE *fp;
	SUMFIT far *ps;

	fp = fopen(fname,mode);
	if (!fp) return;

	fprintf(fp,"SUMFIT %s\n",tag);
	fprintf(fp,"lseg ipar rpar epr0 epr1 pr er gp or ----fne-----   flag\n");
	fprintf(fp,"---- ---- ---- ---- ---- -- -- -- -- ------------ --------\n");
	for (ps = psumfit; ps->lseg; ps++) {
		LSEGFIT far *ls;

		ls = FAR_PTR(ps->lseg,0);
		fprintf(fp,"%04X %04X %04X %04X %04X %02X %02X %02X %02X",
			ps->lseg,
			ps->ipara,
			ps->rpara,
			ps->epar0,
			ps->epar1,
			ps->preg,
			ps->ereg,
			ps->grp,
			ps->ord);
		fprintf(fp," %-12.12Fs",ls->name);
		dump_lsegflag(fp,ps->flag);
		fprintf(fp,"\n");
		ipara_sum += ps->ipara;
		rpara_sum += ps->rpara;
		epar0_sum += ps->epar0;
		epar1_sum += ps->epar1;
	}
	fprintf(fp,"---- ---- ---- ---- ---- -- -- -- -- ------------ --------\n");
	fprintf(fp,"     %04X %04X %04X %04X\n",
		ipara_sum,
		rpara_sum,
		epar0_sum,
		epar1_sum);
	fclose(fp);
}

void dump_lseg(char *fname,char *mode,char *tag)
{
	FILE *fp;
	WORD lseg;

	fp = fopen(fname,mode);
	if (!fp) return;

	fprintf(fp,"LSEG %s\n",tag);

	fprintf(fp,"next prev ----fne----- rpar epr0 epr1 rpr2  asize    lsize    isize   pr er npar gp fi ownh inso inse  flags\n");
	fprintf(fp,"---- ---- ------------ ---- ---- ---- ---- -------- -------- -------- -- -- ---- -- -- ---- ---- ---- --------\n");

	for (lseg = LoadSeg; lseg != -1;) {
		LSEGFIT far *ls;

		ls = FAR_PTR(lseg,0);
		fprintf(fp,"%04X %04X %-12.12Fs %04X %04X %04X %04X %08lX %08lX %08lX %02X %02X %04X %02X %02X %04X %04X %04X",
			ls->next,
			ls->prev,
			ls->name,
			ls->rpara,
			ls->epar0,
			ls->epar1,
			ls->rpar2,
			ls->asize,
			ls->lsize,
			ls->isize,
			ls->preg,
			ls->ereg,
			ls->ipara,
			ls->grp,
			ls->fill1,
			ls->ownrhi,
			ls->instlo,
			ls->instlen);
		dump_lsegflag(fp,ls->flag);
		fprintf(fp,"\n");
		lseg = ls->next;
	}
	fprintf(fp,"---- ---- ------------ ---- ---- ---- ---- -------- -------- -------- -- -- ---- -- -- ---- ---- ---- --------\n");
	fclose(fp);
}

void dump_lsegflag(FILE *fp,LSEGFLAG flag)
{
	if (flag.flex)	fprintf(fp," flex");
	if (flag.inst)	fprintf(fp," inst");
	if (flag.gsize) fprintf(fp," gsize");
	if (flag.xlhi)	fprintf(fp," xlhi");
	if (flag.xems)	fprintf(fp," xems");
	if (flag.fsiz)	fprintf(fp," fsiz");
	if (flag.drv)	fprintf(fp," drv");
	if (flag.winst) fprintf(fp," winst");
}

void dump_maxout(char *fname,char *mode,char *tag)
{
	FILE *fp;
	FILE *f2;
	int c;
	char temp[128];

	fp = fopen(fname,mode);
	if (!fp) return;

	get_exepath(temp,sizeof(temp));
	strcat(temp,"MAXIMIZE.OUT");

	fprintf(fp,"%s %s\n",temp,tag);

	f2 = fopen(temp,"r");
	if (!f2) {
		fprintf(fp,"File not found.\n");
	}
	else {
		while ((c = fgetc(f2)) != EOF) fputc(c,fp);
		fprintf(fp,"---- End of File ----\n");
	}
	fclose(fp);
	return;
}

#endif /* DUMP_DEBUG */
