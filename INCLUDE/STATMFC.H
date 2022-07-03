// $Header:   P:/PVCS/MAX/INCLUDE/STATMFC.H_V   1.1   23 May 1996 13:28:22   HENRY  $
//
// STATMFC.H - Non-class MFC components of statutil
//
// Copygright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//
// Any complete class added to statutil should have its own
// .H file.  Modules containing utility functions that require
// MFC but are not classes should be declared here.

#ifndef _STATMFC_INCLUDED
#define	_STATMFC_INCLUDED

// Center any dialog (or other window) on desktop.
void CenterDialog( CWnd *pWnd );

// -- Custom data exchange / validation --

// Make sure it's a dir or no subset exists as something other than a dir
void AFXAPI DDV_DirName( CDataExchange *pDX, LPCSTR lpDir );

#endif

