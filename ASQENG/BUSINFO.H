/* $Header:   P:/PVCS/MAX/ASQENG/BUSINFO.H_V   1.1   01 Feb 1996 10:21:54   HENRY  $ */
/******************************************************************************
 *									      *
 * Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * BUSINFO.H								      *
 *									      *
 * Bus architecture and card recognition				      *
 *									      *
 ******************************************************************************/

#ifndef BUSINFO_INCLUDED

#define	BUSINFO_INCLUDED

#include <pnp.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Returns 1 if EISA, 0 if not */
/*-asm-*/ WORD pascal far is_eisa( void );

/* Returns binary coded decimal (BCD) version if PCI, 0 if not, */
/* ffff if buggy PCI (unsafe to call PCI BIOS) */
/*-asm-*/ WORD pascal far is_pci( void );

/* Returns 1 if Plug and Play BIOS, 0 if not */
/*-asm-*/ WORD pascal far is_pnp( void );

/* Returns Plug and Play BIOS entry for VM (PM not currently supported) */
/* Also sets data segment value for use in PnP calls */
/* Returns NULL if failed. */
/*-asm-*/ DWORD pascal far pnp_vm( WORD far *pwDS );

/* Returns pointer to structure containing additional info */
/*-asm-*/ LPPNPBIOS_STR pascal far pnp_bios_str( void );

/**** Function pointer casts for Plug and Play functions ****/

/* Get number of nodes: wFunctionNumber, lpwNumNodes, lpwNodeSize, wDataSeg */
typedef WORD (__cdecl __far *LPFNGETNUMNODES) ( WORD, WORD __far *, \
		WORD __far *, WORD );

/* Get/set system device node: wFuncNum, lpwNode, lpData, wCtlFlags, wDataSeg */
typedef WORD (__cdecl __far *LPFNGETSETSYSDEVNODES) ( WORD, WORD __far *, \
		void __far *, WORD, WORD );

/**** Macros for casting a DWORD variable dwPnPEntry as various functions ****/

#define fnGetNumNodes(wFuncNumber,lpwNumNodes,lpwNodeSize,wDataSeg) \
	(*((LPFNGETNUMNODES)dwPnPEntry))( wFuncNumber, lpwNumNodes, lpwNodeSize, \
						wDataSeg )

/* Node must be set on entry to origin:0 number.  On exit, it's set to */
/* the next node number or 255 if the end. */
#define	fnGetSetDevNode(wFuncNumber,lpwNode,lpData,wFlags,wDataSeg) \
	(*((LPFNGETSETSYSDEVNODES)dwPnPEntry))( wFuncNumber, lpwNode, lpData, \
						wFlags, wDataSeg )

/* Flags used for Get/Set device node */
#define	GSDN_CTL_CURRENT	0x01	/* Current config */
#define	GSDN_CTL_NEXTBOOT	0x02	/* Next boot config */

#ifdef __cplusplus
}
#endif

#endif

