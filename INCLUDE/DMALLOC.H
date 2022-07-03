/*' $Header:   P:/PVCS/MAX/INCLUDE/DMALLOC.H_V   1.0   05 Sep 1995 13:30:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DMALLOC.H								      *
 *									      *
 * DOS malloc routines header file					      *
 *									      *
 ******************************************************************************/

/***
 *
 * These memory allocation routines are a direct replacement for
 * _fmalloc(), _ffree(), and _frealloc().  They should be used by
 * all programs that allocate and free far heap space in the following
 * manner:
 * (Potentially) large allocation A
 * Large allocation B
 * (No other allocations take place here)
 * Free B
 * Free A
 *
 * In such a case, if large amounts of memory are allocated via the
 * heap, additional DOS segments may be allocated.  These segments
 * are NOT freed via _ffree().	This can easily cause a program
 * to run out of DOS free memory quickly, although plenty of far heap
 * space is available.	One example of a situation where we
 * allocate large amounts of memory is in copying files.  After doing
 * so, we may end up with insufficient memory to spawn other programs
 * (such as STRIPMGR).
 *
 * Note that this MAY NOT work with compilers other than MSC 6 and 7,
 * since we depend on ALL far allocations from the heap having a
 * non-zero offset.
 *
 * These routines work with far pointers only.	If space is available
 * in high DOS, segments will be allocated via XMS UMB services.
 * Otherwise, DOS services (fn 48h) will be used.  If all else fails,
 * we pass the request to _fmalloc().
 *
***/

void _far *_dmalloc (unsigned bsize);	/* Allocate a block of bsize bytes */

void _dfree (void _far *p);		/* Free block p */

void _far *_drealloc (void _far *p, unsigned newsize); /* Resize p to newsize */

