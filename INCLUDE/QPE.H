/*' $Header:   P:/PVCS/MAX/INCLUDE/QPE.H_V   1.0   07 Sep 1995 11:51:14   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1993 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * QPE.H								      *
 *									      *
 * Qualitas .QPE structure and equates					      *
 *									      *
 *   A MASM 5.10b compatible version of this file, QPE.INC, must be	      *
 *   maintained by hand.						      *
 *									      *
 ******************************************************************************/

#ifndef BYTE

typedef unsigned char	BYTE;
typedef unsigned short	WORD;
typedef unsigned long	DWORD;

#endif	/* #ifndef BYTE */

#ifndef FAR

#define NEAR	_near
#define FAR	_far

#endif	/* #ifndef FAR */

typedef struct _QPE {
    char	cSig[4];	// 00: "QPIF"
    BYTE	bCheckSum;	// 04: Negative sum of all bytes in .QPE
    BYTE	bVersion;	// 05: Version # of file.  0x01
    WORD	cbQPIF; 	// 06: Count of bytes in entire file
    BYTE	Flags1; 	// 08: Flags
				//	0x80 - 'Forced ON' selected
				//	0x40 - 'Forced OFF' selected
    BYTE	Reserved1;	// 09:
    WORD	DosMax; 	// 0A: Size of DOS VM
    BYTE	Reserved2[4];	// 0C:
    char	szPIF[80];	// 10: Full pathname of parallel .PIF
} QPE, * PQPE, * FAR LPQPE;

#define QPE_SIG "QPIF"          // .QPE signature
#define QPE_SIGL	4	// Length of signature

#define QPE_ON		0x80	// 'Forced ON' selected
#define QPE_OFF 	0x40	// 'Forced OFF' selected

