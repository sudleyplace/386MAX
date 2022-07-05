// $Header:   P:/PVCS/MAX/WINMXMZ/WINMXMZ.H_V   1.4   23 May 1996 13:44:18   HENRY  $
//
// WINMXMZ.H - Main header file for the WINMXMZ application
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CWinmxmzApp:
// See winmxmz.cpp for the implementation of this class
//

class CWinmxmzApp : public CWinApp
{
public:
	CWinmxmzApp();
	CString m_csDir; // Dispatch directory (putative; may be derived from .EXE)

	void Winmxmz();

	// Set Win95-ish small font for dialog
	void SetSmallFont(CWnd *pDlg);
	CFont m_font;

    // are we in windows 95?
    BOOL m_bWin95;
	
	// Handle and ID of dialog
	HWND m_hwndDlg;
	UINT m_idDlg;

	// Summary dialog
	CWnd *m_CWndSummary;

// Overrides
	virtual BOOL InitInstance();
	virtual int  ExitInstance();
	virtual void WinHelp( DWORD dwData, UINT nCmd = HELP_CONTEXT );		// Windows help


// Implementation

	//{{AFX_MSG(CWinmxmzApp)
	afx_msg void OnHelp();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#define THEAPP ((CWinmxmzApp*)AfxGetApp())

