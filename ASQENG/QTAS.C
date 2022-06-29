/*' $Header:   P:/PVCS/MAX/ASQENG/QTAS.C_V   1.2   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * QTAS.C								      *
 *									      *
 * Access to Qualitas source code					      *
 *									      *
 ******************************************************************************/

/*????
Do we need to release our own environment?
	Do we need to deal with ID_DOS ?

What about this?
	 test	 CMD_FLAG,@CMD_XHI ; Is high DOS memory available?
	 jnz	 short ACT_MAP_COM ; No

	 cmp	 HDM_FLAG,@HDM_OPEN ; Izit already opened up?
	 je	 short ACT_MAP_COM ; Yes, thus already displayed above


????*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>

#include <engine.h>
#include <myalloc.h>

#include "sysinfo.h"            /* System info structures */
#include <commfunc.h>		/* Utility functions */

#define OWNER
#include "qtas.h"               /* Imports from Qualitas code */

#define QTAS_C
#include "engtext.h"            /* Text strings */


/* Local defines */

#pragma pack(1)
typedef struct _dosmac {	/* DOS Memory allocation chain entry */
	BYTE mz;		/* 'Z' = last, 'M' = valid */
	WORD owner;		/* Owner:  0 = unallocated */
	WORD size;		/* # paragraphs allocated to this entry */
	BYTE unused[3]; 	/* Not used (as far as we know) */
	BYTE name[8];		/* Program Name if DOS 4.x */
} DOSMAC;
#pragma pack()


#define TSIZE 0x4000		/* Expected size of scratch buffer */

static WORD valid_chain(	/* Check for a valid M/Z MAC chain */
	DOSMAC far *macp);	/* Pointer to possible chain */

static void guess_mac(		/* Guess the contents of a MAC entry */
	MACINFO far *info,	/* Info struct to fill in */
	DOSMAC far *macp);	/* Pointer to entry */

static int find_mz_chain(	/* Look for a DOS-style M/Z allocation chain */
	WORD start,		/* Segment for where to start looking */
	void far *scrat,	/* Pointer to big scratch buffer */
	WORD nscrat);		/* How many bytes in scratch buffer */
/* Return:  How many items found */

static int prog_from_psp(	/* Get program name for PSP MAC entry */
	DOSMAC far *macp,	/* Segment of MAC entry */
	char far *name, 	/* Name returned here */
	int nname);		/* Max chars in name */

static char far *env_from_psp(	/* Get environment pointer from PSP, if possible */
	WORD macseg);		/* Segment of MAC entry */

/*
 *	qtas_init - init and call Qtas code
 */

void qtas_init(void)

/* Returns:  TRUE if 386max running, else 0 */
{
	WORD low_mac;
	WORD high_mac;
	WORD lseg;
	WORD nmac;
	WORD nscrat;
	SYSBUFH hscrat;
	BYTE far *scrat;
	MACINFO far *macbuf;
	FLEXROM far *flexbuf;

	nscrat = sysbuf_avail(TSIZE);
	hscrat = sysbuf_alloc(nscrat);
	scrat = sysbuf_ptr(hscrat);
	macbuf = (MACINFO far *)scrat;

	nmac = nscrat / sizeof(MACINFO);

	/* Get Low DOS chain from list of lists */
	low_mac = RawInfo.listlist->base.first_mac;

	reportEval(EVAL_LOWDOS);
	/* Process Low DOS memory chain */
	SysInfo->nlowdos = qtas_mac(low_mac,(WORD)-1,macbuf,nmac);
	if (SysInfo->nlowdos > 0) {
		WORD nbytes;

		nbytes = SysInfo->nlowdos * sizeof(MACINFO);

		sysbuf_realloc(hscrat,nbytes);
		SysInfo->lowdos = hscrat;
		nscrat -= nbytes;
		hscrat = sysbuf_alloc(nscrat);
		macbuf = sysbuf_ptr(hscrat);
	}

	/* Process High DOS memory chain for 386MAX, if present */
	SysInfo->flags.max = qmaxpres(&high_mac,&lseg);
	if (SysInfo->flags.max) {
		int rtn;
		reportEval(EVAL_HIGHDOS1	 );
		SysInfo->nhighdos = qtas_mac(high_mac,lseg,macbuf,nmac);
		if (SysInfo->nhighdos > 0) {
			WORD nbytes;

			nbytes = SysInfo->nhighdos * sizeof(MACINFO);

			sysbuf_realloc(hscrat,nbytes);
			SysInfo->highdos = hscrat;
			nscrat -= nbytes;
			hscrat = sysbuf_alloc(nscrat);
			macbuf = sysbuf_ptr(hscrat);
		}

		SysInfo->flexlen = 0;
		SysInfo->flexlist = 0;
		if (SysInfo->cpu.win_ver < 0x300) {
			/* Collect FLEXxed ROM info */
			reportEval(EVAL_FLEXROM);
			flexbuf = (FLEXROM far *)macbuf;
			rtn = get_flexroms(flexbuf);
			if (rtn > 0) {
				WORD nbytes;

				SysInfo->flexlen = rtn;
				nbytes = SysInfo->flexlen * sizeof(FLEXROM);

				sysbuf_realloc(hscrat,nbytes);
				SysInfo->flexlist = hscrat;
				nscrat -= nbytes;
				hscrat = sysbuf_alloc(nscrat);
				macbuf = sysbuf_ptr(hscrat);
			}
		}
	}

	/* Process High DOS memory chain for MOVE'EM, if present */
	SysInfo->flags.mov = qmovpres(&high_mac,&lseg);
	if (SysInfo->flags.mov) {
		reportEval(EVAL_HIGHDOS2	 );
		SysInfo->nhighload = qtas_mac(high_mac,lseg,macbuf,nmac);
		if (SysInfo->nhighload > 0) {
			WORD nbytes;

			nbytes = SysInfo->nhighload * sizeof(MACINFO);

			sysbuf_realloc(hscrat,nbytes);
			SysInfo->highload = hscrat;
			nscrat -= nbytes;
			hscrat = sysbuf_alloc(nscrat);
			macbuf = sysbuf_ptr(hscrat);
		}
	}

	if (SysInfo->nhighdos < 1 && SysInfo->nhighload < 1) {
		/* No 386max or MOVE'EM, look for foreign High DOS */
		WORD lowend;
		MACINFO *lowdos;
		reportEval(EVAL_HIGHDOS3);
		/* Start looking wherever the low DOS chain ends */
		lowdos = sysbuf_ptr(SysInfo->lowdos);
		lowend = lowdos[SysInfo->nlowdos-1].start + 1 +
			 lowdos[SysInfo->nlowdos-1].size;

		SysInfo->nhighdos = find_mz_chain(lowend,macbuf,nscrat);
		if (SysInfo->nhighdos > 0) {
			WORD nbytes;

			nbytes = SysInfo->nhighdos * sizeof(MACINFO);

			sysbuf_realloc(hscrat,nbytes);
			SysInfo->highdos = hscrat;
			nscrat -= nbytes;
			hscrat = sysbuf_alloc(nscrat);
			macbuf = sysbuf_ptr(hscrat);
		}
	}
	sysbuf_free(hscrat);
}

static int find_mz_chain(	/* Look for a DOS-style M/Z allocation chain */
	WORD start,		/* Segment for where to start looking */
	void far *scrat,	/* Pointer to big scratch buffer */
	WORD nscrat)		/* How many bytes in scratch buffer */
/* Return:  How many items found */
{
	DOSMAC far *macp;
	WORD ninfo;
	MACINFO far *infobase;
	MACINFO far *info;

	info = infobase = scrat;
	ninfo = nscrat / sizeof(MACINFO);

	/* Check every paragraph boundary for 'M' or 'Z' */

	macp = FAR_PTR(start,0);
	for (;;) {
		WORD count;
		DOSMAC far *macp0;

		macp0 = macp;
		if ((count = valid_chain(macp)) > 0) {
			/* Something found, Walk it */
			while (count > 0) {
				guess_mac(info,macp);
				info++;
				ninfo--;
				if (ninfo < 1) break;
				macp = FAR_PTR(FP_SEG(macp)+1+macp->size,0);
				count--;
			}
			break;
		}
		else {
			macp = FAR_PTR(FP_SEG(macp)+1,0);
		}
		if (FP_SEG(macp) < FP_SEG(macp0)) break;
	}
	return (info-infobase);
}

static WORD valid_chain(	/* Check for a valid M/Z MAC chain */
	DOSMAC far *macp)	/* Pointer to possible chain */
{
	/* We don't accept a 'Z' as the first entry because
	 * it's not enough to make a valid test */
	if (macp->mz == 'M') {
		/* Maybe found something */
		WORD count = 1;
		DOSMAC far *macp2;

		for (;;) {
			macp2 = FAR_PTR(FP_SEG(macp)+1+macp->size,0);
			if (FP_SEG(macp2) > FP_SEG(macp) &&
			    macp2->mz == 'M' || macp2->mz == 'Z') {
				count++;
				if (macp2->mz == 'Z') break;
				macp = macp2;
			}
			else	return 0;
		}
		/* Found something */
		return count;
	}
	return 0;
}

static void guess_mac(		/* Guess the contents of a MAC entry */
	MACINFO far *info,	/* Info struct to fill in */
	DOSMAC far *macp)	/* Pointer to entry */
{
	/* Simple things first */
	_fmemset(info,0,sizeof(MACINFO));
	info->start = FP_SEG(macp);
	info->size = macp->size;
	info->owner = macp->owner;
	info->type = MACTYPE_PRGM;

	if (!macp->owner) {
		info->type = MACTYPE_AVAIL;
	}

	switch (prog_from_psp(macp,info->name,sizeof(info->name))) {
	case 0:
		_fstrncpy(info->name,macp->name,8);
		info->name[8] = '\0';
		break;
	case 1:
		break;
	case 2:
		_fstrncpy(info->text,(char far *)(macp+1),sizeof(info->text)-1);
		info->text[sizeof(info->text)-1] = '\0';
		break;
	}
	if (!(*info->name)) {
		info->type = 0;
	}
	{
		BYTE far *cp;

		for (cp = info->name; *cp; cp++) {
			if (*cp < 32 || *cp > 168) {
				*cp = ' ';
			}
		}
		for (cp = info->text; *cp; cp++) {
			if (*cp < 32 || *cp > 168) {
				*cp = ' ';
			}
		}
	}

/*
	_fmemcpy(info->text,macp+1,sizeof(info->text)-1);
	info->text[sizeof(info->text)-1] = '\0';

	If it's a PSP, try finding it's name thru env ptr
	else try pat mat for device driver
	else try name field in MAC header
	copy text if looks printable

	WORD type;
	char name[16];
	char text[40];
*/
}

static int prog_from_psp(	/* Get program name for PSP MAC entry */
	DOSMAC far *macp,	/* Segment of MAC entry */
	char far *name, 	/* Name returned here */
	int nname)		/* Max chars in name */
{
	WORD macseg0;
	WORD macseg;		/* Segment of MAC entry */

	/* Check for bogus parameters */
	if (!name || nname < 2) return 0;

	macseg0 = macseg = FP_SEG(macp);
	if (macseg+1 != macp->owner) {
		/* Entry doesn't own itself, so it's not a PSP */
		/* ..but maybe it's owner is */
		macseg = macp->owner - 1;
		macp = FAR_PTR(macseg,0);
		if (macseg+1 != macp->owner) {
			/* No, then can't find program name */
			return 0;
		}
	}

	if (_osmajor >= 3) {
		/* Get name from environment thru PSP, if possible */
		WORD nn;
		char far *envp;

		/* Is there an environment? */
		if (!(envp = env_from_psp(macseg))) return 0;

		/* Skip past environment variables */
		do {
			envp += (nn = _fstrlen(envp)) + 1;
		} while (nn);

		/*
		 * envp now points to WORD containing number of strings following
		 * the environment;  The value is normally 1.
		 */

		if ((*((WORD far *) envp) >= 1) &&
		    (*((WORD far *) envp) < 10)) {
			/* Got it */
			char far *p;

			envp += sizeof(WORD);
			p = envp + _fstrlen(envp);
			while (p != envp) {
				--p;
				if (*p == '\\' || *p == ':') {
					p++;
					break;
				}
			}
			name[nname-1] = '\0';
			_fstrncpy(name,p,nname-1);
			return (macseg == macseg0 ? 1 : 2);
		}
	}
	return 0;
}

static char far *env_from_psp(	/* Get environment pointer from PSP, if possible */
	WORD macseg)		/* Segment of MAC entry */
{
	WORD envseg;
	char far *envp;
	MACENTRY far *macp;
	MACENTRY far *envmac;

	/* Get the environment seg from PSP+2C, and make a pointer of it */
	macp = FAR_PTR(macseg,0);
	envseg = *(WORD far *)(FAR_PTR(macp->owner,0x2c));
	envp = FAR_PTR(envseg,0);

	/* Make sure the environment still belongs to this PSP */
	envmac = FAR_PTR(envseg-1,0);
	if (envmac->owner == macp->owner) return envp;
	return NULL;
}
