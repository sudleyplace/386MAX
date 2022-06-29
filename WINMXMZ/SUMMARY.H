// $Header:   P:/PVCS/MAX/WINMXMZ/SUMMARY.H_V   1.4   11 Nov 1995 08:45:28   HENRY  $
//
// summary.h - Maximize complete summary dialog class
//
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved.
//

/////////////////////////////////////////////////////////////////////////////
// CSummary dialog

class CSummary : public CDialog
{
// Construction
public:
	CSummary(int nKBLowFree, CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CSummary)
	enum { IDD = IDD_SUMMARY };
	CListBox	m_lbLowList;
	CListBox	m_lbHighList;
	CString	m_csTotalFreeHigh;
	CString	m_csTotalFreeLow;
	CString	m_csTotalUsedHigh;
	//}}AFX_DATA

	CString GetPString( LPCSTR lpEntry, LPCSTR lpDefault );

	int GetPInt( LPCSTR lpEntry, int nDefault );

	int m_nKBLowFree;

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CSummary)
	virtual BOOL OnInitDialog();
	afx_msg void OnRevert();
	afx_msg void OnHelp();
	virtual void OnOK();
	afx_msg void OnClose();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

