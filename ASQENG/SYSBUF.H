/*' $Header:   P:/PVCS/MAX/ASQENG/SYSBUF.H_V   1.1   01 Feb 1996 10:32:46   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SYSBUF.H								      *
 *									      *
 * System info buffer definitions					      *
 *									      *
 ******************************************************************************/

#ifndef SYSBUF_INCLUDED
#define SYSBUF_INCLUDED

#include <commdef.h>            /* Common definitions */

#include "glist.h"              /* Generic list functions */

/* Types */
typedef WORD SYSBUFH;		/* SysInfo buffer handle */

/* Functions */

SYSBUFH sysbuf_alloc(		/* Allocate space in sysinfo buffer */
	WORD nbytes);		/* How many bytes to allocate */

SYSBUFH sysbuf_realloc( 	/* Reallocate space in sysinfo buffer */
	SYSBUFH h,		/* Handle to memory block */
	WORD nbytes);		/* How many bytes (total) to allocate */

void sysbuf_free(		/* Release space in sysinfo buffer */
	SYSBUFH bufh);		/* Handle to release */

WORD sysbuf_avail(		/* Return number of bytes available */
	WORD nbytes);		/* Minimum bytes required */

void *sysbuf_ptr(		/* Obtain pointer into sysinfo buffer */
	SYSBUFH h);		/* SysInfo buffer handle */

void *sysbuf_glist(		/* Store GLIST data in sysinfo buffer */
	GLIST *list,		/* Pointer to list */
	WORD size,		/* Size of GLIST element */
	SYSBUFH *h,		/* SysInfo buffer handle returned */
	SYSBUFH *l);		/* Number of items returned */

void *sysbuf_store(		/* Store data in sysinfo buffer */
	SYSBUFH *bufh,		/* Buffer handle returned */
	void far *dat,		/* Data to be stored if not NULL */
	WORD ndat);		/* How many bytes, or 0 for null-terminated */

void *sysbuf_append(		/* Append data to handle */
	SYSBUFH *bufh,		/* Buffer handle supplied/returned */
	void far *dat,		/* Data to be added if not NULL */
	WORD ndat);		/* How many bytes, or 0 for null-terminated */

#endif /*SYSBUF_INCLUDED*/
