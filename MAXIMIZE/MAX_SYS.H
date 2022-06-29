/*' $Header:   P:/PVCS/MAX/MAXIMIZE/MAX_SYS.H_V   1.1   26 Oct 1995 21:53:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MAX_SYS.H								      *
 *									      *
 * Maximize header file defining all different system types		      *
 *									      *
 ******************************************************************************/

#ifndef MAX_SYS_INCLUDED
#define MAX_SYS_INCLUDED

#define MAX		0	/* 386MAX */
#define BLUEMAX 	1	/* BlueMAX */
#define MOVEM		2	/* Move'em */

#define STACKER 		/* Stacker/SuperStor support enabled */

#if (SYSTEM == BLUEMAX || SYSTEM == MAX)

#define DEVNAME 	"386MAX$$"
#define LOADNAME	"386LOAD"
#define HARPO		"ExtraDOS" /* Also enables all #ifdef HARPO blocks */
#ifdef HARPO
#define HARPO_EXE	HARPO ".max"
#endif

#if SYSTEM == BLUEMAX
#define MAXSYS		"BLUEMAX.SYS"
#define PRODNAME	"BLUEMAX"       /* PRODUCTNAME in VERSDATA.ASM */
#endif

#if SYSTEM == MAX
#define MAXSYS		"386MAX.SYS"
#define PRODNAME	"Qualitas MAX"        /* PRODUCTNAME in VERSDATA.ASM */
#endif

#endif

#if SYSTEM == MOVEM
#define MAXSYS		"MOVE'EM.MGR"
#define PRODNAME	"MOVE'EM"       /* PRODUCTNAME in VERSDATA.ASM */
#define DEVNAME 	"MOVE'EM$"
#define LOADNAME	"MOVE'EM"
#endif

#if (SYSTEM != MAX && SYSTEM != BLUEMAX && SYSTEM != MOVEM )
#error	SYSTEM must be defined to MAX or BLUEMAX or MOVEM
#endif

#endif /*MAX_SYS_INCLUDED*/
