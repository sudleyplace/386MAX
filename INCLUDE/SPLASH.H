// $Header:   P:/PVCS/MAX/INCLUDE/SPLASH.H_V   1.2   23 May 1996 13:27:54   HENRY  $
//
// splash.h - declaration of splash "dialog"
//

#include <statres.h>

class CSplashBtn : public CButton
{
public:
	virtual void DrawItem( LPDRAWITEMSTRUCT lpDraw );

	void LoadBitmap( int wResID );

	CBitmap m_bmpSplash;
	BITMAP m_bmpSplashInfo;

};

/////////////////////////////////////////////////////////////////////////////
// CSplashDlg dialog

class CSplashDlg : public CDialog
{
// Construction
public:
	CSplashDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CSplashDlg)
	enum { IDD = IDD_STAT_SPLASH };
	CSplashBtn m_wndSplash;
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support

	// Generated message map functions
	//{{AFX_MSG(CSplashDlg)
	virtual BOOL OnInitDialog();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

