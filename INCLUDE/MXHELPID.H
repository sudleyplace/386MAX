// $Header:   P:/PVCS/MAX/INCLUDE/MXHELPID.H_V   1.0   06 Nov 1995 12:06:16   PETERJ  $
//
// MXHELPID.H - Max 8 application-specific help ID prefixes
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//

// MAKEHELP uses bits 16-19 to ensure uniqueness across different types
// of resources, so we start at bit 20...
#define	SHL20(v)	(((DWORD)v##_HLP_PRE) << 20)

#define	WINMX_HLP_PRE		0x010
//#define	QDSENDLL_HLP_PRE	0x018

#define	WINMX_HLP_DWORD		SHL20( WINMX )

