// $Header:   P:/PVCS/MAX/INCLUDE/DOSDEFS.H_V   1.2   28 May 1996 16:10:34   HENRY  $
//
// DOSDEFS.H - Definitions for non-Windows source modules
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//
// This is useful for .C programs that use statutil.h.
//

#ifndef DOSDEFS_INCLUDED
#define	DOSDEFS_INCLUDED

#ifndef FAR
#ifdef _WIN32
#define	FAR
#else
#define	FAR __far
#endif
#endif

#ifndef LPSTR
typedef char FAR *LPSTR;
#endif

#ifndef LPCSTR
typedef const char FAR *LPCSTR;
#endif

#ifndef BOOL
typedef int BOOL;
#endif

#ifndef BYTE
typedef unsigned char BYTE;
#endif

#ifndef WORD
typedef unsigned short int WORD;
#endif

#ifndef UINT
#define	UINT WORD
#endif

#ifndef DWORD
typedef unsigned long int DWORD;
#endif

#ifndef TRUE
#define	TRUE	1
#endif

#ifndef FALSE
#define	FALSE	0
#endif

#endif

