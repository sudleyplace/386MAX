/*' $Header:   P:/PVCS/MAX/ASQENG/SYSBUF.C_V   1.1   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SYSBUF.C								      *
 *									      *
 * System info buffer routines						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <commfunc.h>
#include "sysinfo.h"            /* Definitions */

SYSBUFH sysbuf_alloc(		/* Allocate space in sysinfo buffer */
	WORD nbytes)		/* How many bytes to allocate, 0 is legal */
{
	SYSBUFH h;

	if (SysInfo->buffree < nbytes) {
		nomem_bailout(101);
	}
	h = SysInfo->buflasth = SysInfo->bufnext;
	SysInfo->bufnext += nbytes;
	SysInfo->buffree -= nbytes;
	return h;
}

SYSBUFH sysbuf_realloc( 	/* Reallocate space in sysinfo buffer */
	SYSBUFH h,		/* Handle to memory block */
	WORD nbytes)		/* How many bytes (total) to allocate */
{
	WORD nb;

	if (h != SysInfo->buflasth) {
		/* You may only reallocate the last item in the buffer */
		nomem_bailout(102);
	}

	nb = SysInfo->bufnext - SysInfo->buflasth;
	if (nbytes < nb) {
		/* Shrinking block, that's easy */
		SysInfo->bufnext -= nb - nbytes;
		SysInfo->buffree += nb - nbytes;
	}
	else {
		/* Growing block */
		WORD ni = nbytes - nb;

		if (SysInfo->buffree < ni) {
			nomem_bailout(103);
		}
		SysInfo->bufnext += ni;
		SysInfo->buffree -= ni;
	}
	return h;
}

void sysbuf_free(		/* Release space in sysinfo buffer */
	SYSBUFH bufh)		/* Handle to release */
{
	if (bufh == SysInfo->buflasth) {
		SysInfo->buffree += SysInfo->bufnext - bufh;
		SysInfo->bufnext = bufh;
		SysInfo->buflastn = 0;
	}
}

WORD sysbuf_avail(		/* Return number of bytes available */
	WORD nbytes)		/* Minimum bytes required */
{
	if (SysInfo->buffree < nbytes) {
		nomem_bailout(104);
	}
	return SysInfo->buffree;
}

void *sysbuf_store(		/* Store data in sysinfo buffer */
	SYSBUFH *bufh,		/* Buffer handle returned */
	void far *dat,		/* Data to be stored if not NULL */
	WORD ndat)		/* How many bytes, or 0 for null-terminated */
{
	void *p;

	if (!ndat) ndat = _fstrlen(dat)+1;

	*bufh = sysbuf_alloc(ndat);
	SysInfo->buflasth = *bufh;
	SysInfo->buflastn = ndat;

	p = sysbuf_ptr(*bufh);
	if (dat) _fmemcpy(p,dat,ndat);
	else	 memset(p,0,ndat);
	return p;
}

void *sysbuf_append(		/* Append data to handle */
	SYSBUFH *bufh,		/* Buffer handle supplied/returned */
	void far *dat,		/* Data to be added if not NULL */
	WORD ndat)		/* How many bytes, or 0 for null-terminated */
{
	char *p;

	if (!(*bufh)) {
		/* No handle, create one */
		*bufh = sysbuf_alloc(0);
		SysInfo->buflasth = *bufh;
		SysInfo->buflastn = 0;
	}

	if (!ndat) ndat = _fstrlen(dat)+1;

	sysbuf_realloc(*bufh,SysInfo->buflastn + ndat);
	p = (char *)sysbuf_ptr(*bufh) + SysInfo->buflastn;
	if (dat) _fmemcpy(p,dat,ndat);
	else	 memset(p,0,ndat);
	SysInfo->buflastn += ndat;
	return p;
}

void *sysbuf_ptr(		/* Obtain pointer into sysinfo buffer */
	SYSBUFH h)		/* SysInfo buffer handle */
{
	if (!h) return NULL;
	return (SysInfoBuf + h);
}

void *sysbuf_glist(		/* Store GLIST data in sysinfo buffer */
	GLIST *list,		/* Pointer to list */
	WORD size,		/* Size of GLIST element */
	SYSBUFH *h,		/* SysInfo buffer handle returned */
	SYSBUFH *l)		/* Number of items returned */
{
	WORD nn;
	void *p;

	/* By the way, this only works for ARRAY-type lists */

	*l = glist_count(list);
	nn = *l * size;
	if (nn) {
		*h = sysbuf_alloc(nn);
		p = sysbuf_ptr(*h);
		memcpy(p,glist_head(list),nn);
	}
	else	p = NULL;
	return p;
}
