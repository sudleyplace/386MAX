/*' $Header:   P:/PVCS/MAX/ASQENG/XMSINFO.H_V   1.0   05 Sep 1995 15:05:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * XMSINFO.H								      *
 *									      *
 * Functions to get XMS information					      *
 *									      *
 ******************************************************************************/

#ifndef XMSINFO_INCLUDED
#define XMSINFO_INCLUDED

typedef struct _xmsparm {
	int flag; /* 0 if XMS installed, 0x80 if not, 0x81 if VDISK running */
	unsigned short version;  /* XMS version number */
	unsigned short driver;	 /* Driver version number */
	unsigned short hmaexist; /* HMA exists flag */
	unsigned short hmaavail; /* HMA available flag */
	unsigned short a20state; /* State of A20 line */
	unsigned short embhand;  /* EMB handles */
	unsigned short embtotal; /* Total Kb EMB free */
	unsigned short embavail; /* Available Kb in largest EMB block */
	unsigned short umbtotal; /* Total Paras UMB free */
	unsigned short umbavail; /* Available Paras in largest UMB block */
} XMSPARM;

/*-asm-*/  int pascal far xmsparm(XMSPARM far *parm);
/*-asm-*/  unsigned short pascal far umballoc(int npara);
/*-asm-*/  int pascal far umbfree(unsigned short umbseg);
/*-asm-*/  unsigned short pascal far emballoc(int npara);
/*-asm-*/  int pascal far embfree(unsigned short embh);
/*-asm-*/  int pascal far setA20(unsigned short onoff);
/*-asm-*/  unsigned short pascal far umbtavail(void);

#endif /*XMSINFO_INCLUDED*/
