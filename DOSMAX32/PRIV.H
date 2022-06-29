// $Header:   P:/PVCS/MAX/DOSMAX32/PRIV.H_V   1.1   18 Dec 1995 16:15:10   BOB  $
//--------------------------------------------------------------
// common user interface routines
//
//
//--------------------------------------------------------------

#ifndef STRICT
#define STRICT
#endif

#define INC_OLE2        // WIN32, get ole2 from windows.h

#include <windows.h>
#include <windowsx.h>
#include <shlobj.h>
#include <winuser.h>

#define ResultFromShort(i)  ResultFromScode(MAKE_SCODE(SEVERITY_SUCCESS, 0, (USHORT)(i)))

