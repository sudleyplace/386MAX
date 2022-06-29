/*' $Header:   P:/PVCS/MAX/INCLUDE/EMSINFO.H_V   1.0   05 Sep 1995 13:29:40   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * EMSINFO.H								      *
 *									      *
 * Functions to get EMS information					      *
 *									      *
 ******************************************************************************/

#ifndef EMSINFO_INCLUDED
#define EMSINFO_INCLUDED

typedef struct _emsparm {
	unsigned short version; /* Version number */
	unsigned short frame;	/* Page frame segment */
	unsigned short avail;	/* Available pages */
	unsigned short total;	/* Total pages */
	unsigned short mpages;	/* !! Mappable physical pages */
	unsigned short tothand; /* !! Total handles supported */
	unsigned short acthand; /* Number of active handles */
	/* Hardware configuration */
	unsigned short rawsize; /* !! Size of raw pages in paragraphs */
	unsigned short amrs;	/* !! Number of alternate map register sets */
	unsigned short mcsize;	/* !! Size of mapping-context save area in bytes */
	unsigned short dmars;	/* !! Number of register sets that can be assigned to DMA */
	unsigned short dmatype; /* !! DMA operation type */
} EMSPARM;

typedef struct _emshand {	/* !! EMS handle name item */
	WORD handle;		/* !! Handle number */
	char name[8];		/* !! Name of handle */
} EMSHAND;

typedef struct _emsmap {	/* !! EMS page mapping item */
	WORD base;		/* !! Base segment address */
	WORD number;		/* !! Physical page number */
} EMSMAP;

/*-asm-*/	int pascal far emsparm(EMSPARM far *parm);
/*-asm-*/	int pascal far emshand(EMSHAND far *hand); /* !! */
/*-asm-*/	int pascal far emsmap(EMSMAP far *map);    /* !! */
/*-asm-*/	int pascal far emshsize(int handle);
/*-asm-*/	int pascal far emsfree(int handle);
/*-asm-*/	int pascal far emsalloc(unsigned npages);

#endif /*EMSINFO_INCLUDED*/
