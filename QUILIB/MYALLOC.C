/*' $Header:   P:/PVCS/MAX/QUILIB/MYALLOC.C_V   1.0   05 Sep 1995 17:02:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MYALLOC.C								      *
 *									      *
 * My covers for malloc, realloc, free					      *
 *									      *
 ******************************************************************************/

#ifdef CVDBG
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#include "screen.h"
#include "commdef.h"
#include "windowfn.h"
#include "myalloc.h"

static void near check_it(BOOL farflag,unsigned n1,unsigned n2);
static void near uncheck_it(unsigned n1,unsigned n2);
static WINDESC VideoWin = { 24, 60, 1, 20 };

void *my_malloc(unsigned nbytes)
{
	char *p;

	/*	Do this here since it is the first likely call */
	VideoWin.row = ScreenSize.row-1;
	check_it(FALSE,0,nbytes);
	p = malloc(nbytes);
	if (!p) uncheck_it(nbytes,0);
	return p;
}

void *my_calloc(unsigned nitems,unsigned size)
{
	char *p;

	check_it(FALSE,0,nitems*size);
	p = calloc(nitems,size);
	if (!p) uncheck_it(nitems*size,0);
	return p;
}

void *my_realloc(void *ptr,unsigned nbytes)
{
	char *p;
	WORD size = _msize(ptr);

	check_it(FALSE,size,nbytes);
	p = realloc(ptr,nbytes);
	if (!p) uncheck_it(nbytes,size);
	return p;
}

void my_free(void *ptr)
{
	check_it(FALSE,_msize(ptr),0);
	free(ptr);
}

void far *my_fmalloc(unsigned nbytes)
{
	char far *p;

	check_it(TRUE,0,nbytes);
	p = _fmalloc(nbytes);
	if (!p) uncheck_it(nbytes,0);
	return p;
}

void far *my_fcalloc(unsigned nitems,unsigned size)
{
	char far *p;

	check_it(TRUE,0,nitems*size);
	p = _fcalloc(nitems,size);
	if (!p) uncheck_it(nitems*size,0);
	return p;
}

void far *my_frealloc(void far *ptr,unsigned nbytes)
{
	char far *p;
	WORD size = _fmsize(ptr);

	check_it(TRUE,size,nbytes);
	p = _frealloc(ptr,nbytes);
	if (!p) uncheck_it(nbytes,size);
	return p;
}

void my_ffree(void far *ptr)
{
	check_it(TRUE,_fmsize(ptr),0);
	_ffree(ptr);
}

#define COLD 0x3f
#define HOT  0x4f

static long SerialNo = 1;
static long SerialCheck = 0;
static long Count = 0;
static long Amount = 0;
static BOOL FirstFar = TRUE;
static BOOL FirstNorm = TRUE;


static void near check_it(BOOL farflag,unsigned n1,unsigned n2)
{
	int result;

	n1 = (n1+1)&0xfffe;
	n2 = (n2+1)&0xfffe;
	if (farflag) {
		if (FirstFar) {
			result = _HEAPOK;
			FirstFar = FALSE;
		}
		else	result = _fheapchk();
	}
	else {
		if (FirstNorm) {
			result = _HEAPOK;
			FirstNorm = FALSE;
		}
		else	result = _heapchk();
	}

	SerialNo++;
	if (SerialNo == SerialCheck) {
		SerialCheck++;
	}

	if (!n1) Count++;
	if (!n2) Count--;
	Amount -= n1;
	Amount += n2;
	{
		char line[40];

		sprintf(line,"%6ld %6ld %6ld",SerialNo,Count,Amount);
		wput_csa(&VideoWin,line,(BYTE)((result != _HEAPOK) ? HOT : COLD));
	}
	if (result != _HEAPOK) {
		exit(86);
	}
}

static void near uncheck_it(unsigned n1,unsigned n2)
{
	SerialNo--;
	Count--;
	Amount += n1;
	Amount -= n2;
}
#endif	/* CVDBG */
