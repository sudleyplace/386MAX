/*' $Header:   P:/PVCS/MAX/INCLUDE/BIOSCRC.H_V   1.2   02 Jun 1997 14:37:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * BIOSCRC.H								      *
 *									      *
 * Header file for BIOSCRC.ASM						      *
 *									      *
 ******************************************************************************/

#ifndef BIOSCRC_INCLUDED
#define BIOSCRC_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#include <commdef.h>

typedef struct _cmospos {	/* One CMOS POS entry */
	WORD aid;		/* Adapter ID */
	BYTE pos[4];		/* POS bytes */
} CMOSPOS;

extern unsigned int Is_IBM (void);
extern unsigned int Is_MCA (void);
extern unsigned int Is_VM (void);
extern unsigned int Is_BCF (void);

extern unsigned int Get_BIOS_Start (int cmprom);
extern unsigned long Get_BIOSCRC (void);

extern unsigned int Get_CMOS_POS (CMOSPOS far *buffer);

extern unsigned long __far __cdecl
DPMI_BCRC( unsigned long dwPhysAddr, unsigned long dwLen );

extern int __far __cdecl DPMI_Is_MCA( void );

extern int __far __cdecl DPMI_Is_IBM( void );

extern int __far __cdecl DPMI_Is_BCF( void );

#ifdef __cplusplus
}
#endif

#endif /*BIOSCRC_INCLUDED*/

