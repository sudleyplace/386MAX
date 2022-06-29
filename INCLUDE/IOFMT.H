// $Header:   P:/PVCS/MAX/INCLUDE/IOFMT.H_V   1.1   23 May 1996 13:27:50   HENRY  $
//
// IOFMT.H - Replacement sprintf() routines for DLLs
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//
// You must link explicitly with $(L)iofmt.obj - it is not included
// in STATUTIL.LIB.
//

#ifndef _IOFMT_INCLUDED
#define	_IOFMT_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// replace the RTL sscanf()
int _cdecl sscanf(const char *source, const char *fmt, ...);

#ifdef __cplusplus
}
#endif

#endif

