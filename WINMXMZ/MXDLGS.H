// $Header:   P:/PVCS/MAX/WINMXMZ/MXDLGS.H_V   1.8   23 May 1996 13:43:14   HENRY  $
//
// mxdlgs.h - Maximize dialog classes
//

/////////////////////////////////////////////////////////////////////////////
// CCustomOpts dialog

class CCustomOpts : public CDialog
{
// Construction
public:
	CCustomOpts(CWnd* pParent = NULL, int nID = CCustomOpts::IDD);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CCustomOpts)
	enum { IDD = IDD_CUSTOPTS };
	CButton	m_btnVGASwap;
	CButton	m_btnROMSrch;
	CButton	m_btnDisVGASwap;
	CButton	m_btnDisROMSrch;
	BOOL	m_bExtraDOS;
	BOOL	m_bROMSrch;
	BOOL	m_bVGASwap;
	BOOL	m_bDisROMSrch;
	BOOL	m_bDisVGASwap;
	CButton	m_btnDOSStart;
	//}}AFX_DATA

	BOOL	m_bDOSStart;

	CString m_csMaxPro;	// Path of 386MAX.PRO file

	BOOL m_bHasVGASwap; // TRUE if VGASWAP already present
	BOOL m_bHasUseHigh;	// TRUE if USE= >= F000 already present
	BOOL m_bAutoStrip;	// TRUE if m_bDisROMSrch turned on automatically
	BOOL m_bWin95;		// TRUE if Win95
	BOOL m_bDOSStartEna; // If Win95, TRUE if DOSSTART exists
	BOOL m_bROMSrchEna;	// FALSE if ROMSrch must not be run (e.g. BCF)

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CCustomOpts)
	afx_msg void OnHelp();
	afx_msg void OnBack();
	afx_msg void OnDisromsrch();
	afx_msg void OnDisvgaswap();
	virtual BOOL OnInitDialog();
	afx_msg void OnRomsrch();
	virtual void OnCancel();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
// CEndPhase1 dialog

class CEndPhase1 : public CDialog
{
// Construction
public:
	CEndPhase1(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CEndPhase1)
	enum { IDD = IDD_END_PHASE1 };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CEndPhase1)
	afx_msg void OnBack();
	afx_msg void OnHelp();
	virtual BOOL OnInitDialog();
	virtual void OnCancel();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
/////////////////////////////////////////////////////////////////////////////
// CSelectMBoot dialog

class CSelectMBoot : public CDialog
{
// Construction
public:
	CSelectMBoot(CWnd* pParent, LPCSTR lpDefault);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CSelectMBoot)
	enum { IDD = IDD_SELECTMBOOT };
	CComboBox	m_cbSelect;
	CString m_csSelDesc;
	//}}AFX_DATA

	// Actual short section name selected
	CString m_csSelected;

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CSelectMBoot)
	afx_msg void OnHelp();
	virtual BOOL OnInitDialog();
	virtual void OnOK();
	virtual void OnCancel();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
/////////////////////////////////////////////////////////////////////////////
// CSelectMode dialog

class CSelectMode : public CDialog
{
// Construction
public:
	CSelectMode(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CSelectMode)
	enum { IDD = IDD_SELECTMODE };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

	BOOL m_bCustom; // TRUE if custom, FALSE if express

// Implementation
protected:
	virtual BOOL OnInitDialog( void );

	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CSelectMode)
	afx_msg void OnCustom();
	afx_msg void OnExpress();
	afx_msg void OnBack();
	afx_msg void OnHelp();
	virtual void OnCancel();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
/////////////////////////////////////////////////////////////////////////////
// CWelcome dialog

class CWelcome : public CDialog
{
// Construction
public:
	CWelcome(CWnd* pParent = NULL); // standard constructor

// Dialog Data
	//{{AFX_DATA(CWelcome)
	enum { IDD = IDD_WELCOME };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CWelcome)
	afx_msg void OnHelp();
	virtual BOOL OnInitDialog();
	virtual void OnCancel();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

/////////////////////////////////////////////////////////////////////////////
// CExit dialog

class CExit : public CDialog
{
// Construction
public:
	CExit(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CExit)
	enum { IDD = IDD_CONFIRMEXIT };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CExit)
	virtual BOOL OnInitDialog();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};
