/*' $Header:   P:/PVCS/MAX/ASQENG/DEVICE.H_V   1.1   01 Feb 1996 10:32:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DEVICE.H								      *
 *									      *
 * Device driver attributes and header structure			      *
 *									      *
 ******************************************************************************/

#ifndef DEVICE_INCLUDED
#define DEVICE_INCLUDED

#include <commdef.h>

#define DRV_ATTR_CHAR	0x8000	/* Character device */
#define DRV_ATTR_IOCTL	0x4000	/* IOCTL supported */
#define DRV_ATTR_NON_IBM 0x2000 /* Non-IBM format (BLOCK only) */
#define DRV_ATTR_OOB	0x2000	/* Output until busy (CHAR only) */
#define DRV_ATTR_REMOTE 0x1000	/* Remote vs. local */
#define DRV_ATTR_OCREM	0x0800	/* Open/close/RM supported (BLOCK only) */
		/*	0x0400	   Reserved. */
		/*	0x0200	   Reserved. */
		/*	0x0100	   Reserved. */
		/*	0x0080	   Reserved. */
#define DRV_ATTR_LOGDEV 0x0040	/* Get/Set logical device */
		/*	0x0020	   Reserved. */
#define DRV_ATTR_INT29	0x0010	/* INT 29h supported (CHAR only) */
#define DRV_ATTR_CLOCK	0x0008	/* Current CLOCK device (CHAR only) */
#define DRV_ATTR_NUL	0x0004	/* Current NUL device (CHAR only) */
#define DRV_ATTR_OUT	0x0002	/* Current STANDARD OUTPUT device (CHAR only) */
#define DRV_ATTR_INP	0x0001	/* Current STANDARD INPUT device  (CHAR only) */
#define DRV_ATTR_GENIO	0x0001	/* Supports Generic IOCTL (BLOCK only) */

#pragma pack(1)
typedef struct _ddhdr { 		/* Device driver header */
	struct _ddhdr far *next;	/* Pointer to next header */
	WORD attr;			/* Device attributes */
	WORD strat;			/* Pointer to strategy routine */
	WORD intr;			/* Pointer to interrupt routine */
	char name[8];			/* Device name */
} DDHDR;
#pragma pack()

#endif /*DEVICE_INCLUDED*/
