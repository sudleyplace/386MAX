/*' $Header:   P:/PVCS/MAX/INCLUDE/MYALLOC.H_V   1.0   05 Sep 1995 13:29:50   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MYALLOC.H								      *
 *									      *
 * Our memory allocator 						      *
 *									      *
 ******************************************************************************/

#ifndef CVDBG
#define my_malloc	malloc
#define my_calloc	calloc
#define my_realloc	realloc
#define my_free 	free
#define my_fmalloc	_fmalloc
#define my_fcalloc	_fcalloc
#define my_frealloc	_frealloc
#define my_ffree	_ffree
#endif

void *my_malloc(unsigned nbytes);
void *my_calloc(unsigned nbytes,unsigned size);
void *my_realloc(void *ptr,unsigned nbytes);
void my_free(void *ptr);
void far *my_fmalloc(unsigned nbytes);
void far *my_fcalloc(unsigned nbytes,unsigned size);
void far *my_frealloc(void far *ptr,unsigned nbytes);
void my_ffree(void far *ptr);
