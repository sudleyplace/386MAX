// $Header:   P:/PVCS/MAX/MAXSETUP/EXTFILE.H_V   1.0   15 Dec 1995 11:02:54   PETERJ  $
// EXTFILE.H - prototype for extfile.cpp.
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.

#ifdef __cplusplus
extern "C" {
#endif

extern BOOL CALLBACK 
ExtractFileFromRes( HINSTANCE hInst, LPCSTR szName, WORD wID );

#ifdef __cplusplus
}
#endif // __cplusplus
