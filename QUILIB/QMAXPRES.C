/*' $Header:   P:/PVCS/MAX/QUILIB/QMAXPRES.C_V   1.0   05 Sep 1995 17:02:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * QMAXPRES.C								      *
 *									      *
 * Test for presence of 386MAX/BlueMAX/Move'em                                *
 *									      *
 ******************************************************************************/

#include <string.h>

#include "commfunc.h"

/* Local functions */
static BOOL read_info(	/* Read info from 386max-family driver */
	char far *devname, /* Name of device */
	void far *buf,	/* Pointer to data buffer */
	int nbuf);	/* How many bytes in buffer */

BOOL qmaxpres(	/* Check if 386max present */
	WORD *hmac,	/* First MAC of high DOS returned */
	WORD *lseg)	/* Start of LOADSEG chain returned */
{
	BOOL rtn;
	char *devname = "386MAX$$";
	char info[128];

	memset(info,'?',sizeof(info));

	rtn = read_info(devname,info,0x57);
	if (rtn) {
		if (memcmp(devname,info+1,6) == 0 && info[7] >= '4') {
			if (hmac) *hmac = *(WORD *)(info+1+0x3A);
			if (lseg) *lseg = *(WORD *)(info+1+0x42);
		}
		else	rtn = FALSE;
	}
	return rtn;
}

BOOL qmovpres(	/* Check if MOVE'EM present */
	WORD *hmac,	/* First MAC of high DOS returned */
	WORD *lseg)	/* Start of LOADSEG chain returned */
{
	BOOL rtn;
	char *devname = "MOVE'EM$";
	char info[128];

	memset(info,'?',sizeof(info));

	rtn = read_info(devname,info,0x2d);
	if (rtn) {
		if (memcmp(devname,info+1,7) == 0) {
			if (hmac) *hmac = *(WORD *)(info+1+0x10);
			if (lseg) *lseg = *(WORD *)(info+1+0x12);
		}
		else	rtn = FALSE;
	}
	return rtn;
}

#pragma optimize ("leg",off)
static BOOL read_info(	/* Read info from 386max-family driver */
	char far *devname, /* Name of device */
	void far *buf,	/* Pointer to data buffer */
	int nbuf)	/* How many bytes in buffer */
{
	BOOL rtn = FALSE;
	int devh = -1;

	/* Init buffer and mark for INFO transfer */
	_fmemset(buf,'0',nbuf);
	*(char far *)buf = 3;

	_asm {
		mov	ax,0x3d02	/* Open for read/write */
		push	ds
		lds	dx,devname	/* Name of device driver */
		int	0x21		/* Do it */
		pop	ds
		jc	notok		/* Didn't work */
		mov	devh,ax 	/* Save device handle */

		mov	bx,ax		/* Handle in BX */
		mov	ax,0x4400	/* Make sure it's a device */
		int	0x21		/* Do it */
		jc	notok		/* Didn't work */

		test	dx,0x80 	/* Check device bit */
		jz	notok		/* No?? */

		mov	bx,devh 	/* Handle in BX */
		mov	cx,nbuf 	/* How much to read */
		dec	cx		/* Less 1 */
		push	ds
		lds	dx,buf		/* Point at buffer */
		mov	ax,0x4402	/* Read control string */
		int	0x21		/* Do it */
		pop	ds
		mov	rtn,TRUE	/* Flag as present */
	notok:
		mov	bx,devh 	/* Get device handle */
		cmp	bx,-1		/* Test it */
		jz	over		/* Not open */
		mov	ax,0x3e00	/* Else, close it */
		int	0x21		/* Do it */
	over:
	} /* _asm */
	return rtn;
}
#pragma optimize ("",on)
