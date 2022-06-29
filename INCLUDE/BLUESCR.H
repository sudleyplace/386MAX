// $Header:   P:/PVCS/MAX/INCLUDE/BLUESCR.H_V   1.1   23 May 1996 13:27:36   HENRY  $
//
// BLUESCR.H - Bluescreen dialog class
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//
// This is a do-nothing dialog.  Its constructor takes an optional
// callback function to return a CWnd (if any) we should make the
// active window whenever we receive a mouse click.

#ifndef _BLUESCR_INCLUDED
#define	_BLUESCR_INCLUDED

#include <statres.h>

// Callback type.  Function returns CWnd to make active or NULL.
typedef CWnd FAR * (CALLBACK FAR *LPCBWND)( void );

/////////////////////////////////////////////////////////////////////////////
// CBlue dialog

class CBlue : public CDialog
{
// Construction
public:
	CBlue(CWnd* pParent = NULL, LPCBWND lpCB = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CBlue)
	enum { IDD = IDD_STAT_BLUESCREEN };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	LPCBWND m_lpCB;

	// Generated message map functions
	//{{AFX_MSG(CBlue)
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

#endif

