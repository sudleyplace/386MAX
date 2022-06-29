// $Header:   P:/PVCS/MAX/WINMXMZ/MXDLGS.CPV   1.10   23 May 1996 13:43:12   HENRY  $
//
// mxdlgs.cpp - Implementation of Maximize dialogs
//

#include "stdafx.h"
#include "winmxmz.h"
#include "mxdlgs.h"

#include <commfunc.h>
#include <mbparse.h>
#include <mxhelpid.h>

#include <statmfc.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CCustomOpts dialog


CCustomOpts::CCustomOpts(CWnd* pParent /*=NULL*/, int nID /*=CCustomOpts::IDD*/)
	: CDialog(nID, pParent)
{
	//{{AFX_DATA_INIT(CCustomOpts)
	m_bExtraDOS = FALSE;
	m_bROMSrch = FALSE;
	m_bVGASwap = FALSE;
	m_bDisROMSrch = FALSE;
	m_bDisVGASwap = FALSE;
	//}}AFX_DATA_INIT

	m_bDOSStart = FALSE;

	m_csMaxPro = "";

	m_bHasVGASwap = FALSE;
	m_bHasUseHigh = FALSE;
	m_bAutoStrip = FALSE;
	m_bWin95 = FALSE;
	m_bDOSStartEna = TRUE;
	m_bROMSrchEna = TRUE;
}

void CCustomOpts::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CCustomOpts)
	DDX_Control(pDX, IDC_VGASWAP, m_btnVGASwap);
	DDX_Control(pDX, IDC_ROMSRCH, m_btnROMSrch);
	DDX_Control(pDX, IDC_DISVGASWAP, m_btnDisVGASwap);
	DDX_Control(pDX, IDC_DISROMSRCH, m_btnDisROMSrch);
	DDX_Check(pDX, IDC_EXTRADOS, m_bExtraDOS);
	DDX_Check(pDX, IDC_ROMSRCH, m_bROMSrch);
	DDX_Check(pDX, IDC_VGASWAP, m_bVGASwap);
	DDX_Check(pDX, IDC_DISROMSRCH, m_bDisROMSrch);
	DDX_Check(pDX, IDC_DISVGASWAP, m_bDisVGASwap);
	//}}AFX_DATA_MAP

	if (m_bWin95) {
		DDX_Control(pDX, IDC_DOSSTART, m_btnDOSStart);
		DDX_Check(pDX, IDC_DOSSTART, m_bDOSStart);
	} // Handle additional option
}

BEGIN_MESSAGE_MAP(CCustomOpts, CDialog)
	//{{AFX_MSG_MAP(CCustomOpts)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	ON_BN_CLICKED(IDC_BACK, OnBack)
	ON_BN_CLICKED(IDC_DISROMSRCH, OnDisromsrch)
	ON_BN_CLICKED(IDC_DISVGASWAP, OnDisvgaswap)
	ON_BN_CLICKED(IDC_ROMSRCH, OnRomsrch)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CCustomOpts message handlers

void CCustomOpts::OnBack()
{
	UpdateData( TRUE );
	EndDialog( IDC_BACK );
}

void CCustomOpts::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

void CCustomOpts::OnDisromsrch()
{
	// Get new setting
	UpdateData( TRUE );

	// If removing high DOS statements, clear and disable "Run ROMSRCH"
	// otherwise enable it.
	if (m_bDisROMSrch) {
		m_btnROMSrch.SetCheck( 0 ); // Clear it
		m_btnROMSrch.EnableWindow( FALSE ); // Disable it
	} // Going from off (not removing) to on (removing)
	else {
		m_btnROMSrch.EnableWindow( TRUE );
	} // Re-enabling "Run ROMSRCH"

	m_bAutoStrip = FALSE;

}

void CCustomOpts::OnDisvgaswap()
{
	// Get current setting
	UpdateData( TRUE );

	// If removing VGASwap, clear and disable "Enable VGASwap" otherwise
	// enable it.
	if (m_bDisVGASwap) {
		m_btnVGASwap.SetCheck( 0 ); // Clear it
		m_btnVGASwap.EnableWindow( FALSE ); // Disable it
	} // Going from off to on
	else {
		m_btnVGASwap.EnableWindow( TRUE );
	} // Re-enabling
}

BOOL CCustomOpts::OnInitDialog()
{
	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	// Disable the remove buttons unless there's something to remove
	if (m_bROMSrchEna) {
		m_btnDisROMSrch.EnableWindow( m_bHasUseHigh );
	} // OK to enable ROMSrch if we remove it first
	else {
		m_btnROMSrch.EnableWindow( FALSE );
		m_btnDisROMSrch.EnableWindow( FALSE );
		m_bROMSrch = FALSE;
		m_bDisROMSrch = FALSE;
	} // Can't run ROMsrch because of BCF
	m_btnDisVGASwap.EnableWindow( m_bHasVGASwap );

	if (m_bWin95) {
		// Disable Maximize DOSStart button if no DOSSTART.BAT found
		m_btnDOSStart.EnableWindow( m_bDOSStartEna );
	} // Win95

	// Center ourselves
	CenterDialog( this );

	return TRUE;  // return TRUE  unless you set the focus to a control
}


void CCustomOpts::OnRomsrch()
{
	// Get current setting
	UpdateData( TRUE );

	// If enabling ROMSrch and there are existing statements, make
	// sure we remove them by default
	if (m_bROMSrch && m_bHasUseHigh && !m_bDisROMSrch) {
		m_bDisROMSrch = TRUE;
		m_bAutoStrip = TRUE;
	} // Automatic behavior: strip previous USE= in BIOS area
	else if (!m_bROMSrch && m_bAutoStrip) {
		m_bDisROMSrch = FALSE;
		m_bAutoStrip = FALSE;
	} // Undo automatic behavior

	// Copy updated m_bDisROMSrch back to control
	UpdateData( FALSE );

}

/////////////////////////////////////////////////////////////////////////////
// CEndPhase1 dialog


CEndPhase1::CEndPhase1(CWnd* pParent /*=NULL*/)
	: CDialog(CEndPhase1::IDD, pParent)
{
	//{{AFX_DATA_INIT(CEndPhase1)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}

void CEndPhase1::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CEndPhase1)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CEndPhase1, CDialog)
	//{{AFX_MSG_MAP(CEndPhase1)
	ON_BN_CLICKED(IDC_BACK, OnBack)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CEndPhase1 message handlers
/////////////////////////////////////////////////////////////////////////////
// CSelectMBoot dialog


CSelectMBoot::CSelectMBoot(CWnd* pParent, LPCSTR lpDefault)
	: CDialog(CSelectMBoot::IDD, pParent)
{
	//{{AFX_DATA_INIT(CSelectMBoot)
	m_csSelDesc = "";
	//}}AFX_DATA_INIT

	m_csSelected = "";

	if (lpDefault) {
		m_csSelected = lpDefault;
	}
}


BOOL CSelectMBoot::OnInitDialog( void )
{
	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	char cBoot = ::get_bootdrive();
	int nFoundSelect = -1;

	// Zap current contents
	m_cbSelect.ResetContent();

	// Center ourselves
	CenterDialog( this );

	// Get all MultiConfig sections
	if (::menu_parse( cBoot, 0 )) {

		m_cbSelect.AddString( m_csSelected );

	} // Failed; add default
	else {

		SECTNAME FAR *lpSect;
		int nPosition;

		for (lpSect = FirstSect; lpSect; lpSect = lpSect->next) {

			if (!_stricmp( lpSect->name, "menu" ) ||
				!_stricmp( lpSect->name, "common" )) {
					continue;
			} // These aren't real sections...

			// Add description.  If none, use name
			if (lpSect->text && *lpSect->text) {
				nPosition = m_cbSelect.AddString( lpSect->text );
			} // text exists
			else {
				nPosition = m_cbSelect.AddString( lpSect->name );
			} // no text, use name

			// Check for our target section
			if (nFoundSelect < 0 && !_stricmp( lpSect->name, m_csSelected )) {
				nFoundSelect = nPosition;
				m_csSelDesc = (lpSect->text ? lpSect->text : lpSect->name);
			} // Save index to highlight

			// Save lpSect->name as item data
			if (nPosition >= 0) {
				m_cbSelect.SetItemDataPtr( nPosition, (void *)lpSect->name );
			} // String added successfully

		} // for all sections

	} // Get all sections

	m_cbSelect.SetCurSel( nFoundSelect );

	// Now re-write current selection
	UpdateData( FALSE );

	return TRUE;

}

void CSelectMBoot::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CSelectMBoot)
	DDX_Control(pDX, IDC_SELECTMB, m_cbSelect);
	DDX_CBString(pDX, IDC_SELECTMB, m_csSelDesc);
	DDV_MaxChars(pDX, m_csSelDesc, 80);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CSelectMBoot, CDialog)
	//{{AFX_MSG_MAP(CSelectMBoot)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CSelectMBoot message handlers


void CSelectMBoot::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

void CSelectMBoot::OnOK()
{
	// Get selected item
	UpdateData();

	int nSelected = m_cbSelect.FindStringExact( -1, m_csSelDesc );

	if (nSelected != LB_ERR) {
		m_csSelected = (char *)m_cbSelect.GetItemDataPtr( nSelected );
	} // Found index
	else {

		int n, nTotal = m_cbSelect.GetCount();

		for (n = 0; n < nTotal; n++) {
			if (!lstrcmpi( m_csSelDesc, (LPCSTR)m_cbSelect.GetItemDataPtr( n ))) {
				break;
			} // Found a match
		} // Try to find matching section

		if (n >= nTotal) {

			char szMsg[ 256 ];
			int n;

			n = strspn( m_csSelDesc, " \t." );
			wsprintf( szMsg, "Invalid section [%s] - please try again", m_csSelDesc );
			AfxMessageBox( m_csSelDesc[ n ] ? szMsg : "You must select a MultiConfig section" );

			return;

		} // Didn't find it

	} // Check to ensure it's a real section
	
	CDialog::OnOK();
}

/////////////////////////////////////////////////////////////////////////////
// CSelectMode dialog


CSelectMode::CSelectMode(CWnd* pParent /*=NULL*/)
	: CDialog(CSelectMode::IDD, pParent)
{
	//{{AFX_DATA_INIT(CSelectMode)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}

BOOL CSelectMode::OnInitDialog( void )
{
	// Set default button based on current m_bCustom setting
	SetDefID( m_bCustom ? IDC_CUSTOM : IDC_EXPRESS );

	// Center ourselves
	CenterDialog( this );

	THEAPP->m_hwndDlg = m_hWnd;

	return CDialog::OnInitDialog();
}

void CSelectMode::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CSelectMode)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CSelectMode, CDialog)
	//{{AFX_MSG_MAP(CSelectMode)
	ON_BN_CLICKED(IDC_CUSTOM, OnCustom)
	ON_BN_CLICKED(IDC_EXPRESS, OnExpress)
	ON_BN_CLICKED(IDC_BACK, OnBack)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CSelectMode message handlers
/////////////////////////////////////////////////////////////////////////////
// CWelcome dialog


CWelcome::CWelcome(CWnd* pParent /*=NULL*/)
	: CDialog(CWelcome::IDD, pParent)
{
	//{{AFX_DATA_INIT(CWelcome)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}

void CWelcome::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CWelcome)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CWelcome, CDialog)
	//{{AFX_MSG_MAP(CWelcome)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CWelcome message handlers

void CSelectMode::OnCustom()
{
	m_bCustom = TRUE;
	EndDialog( IDC_CUSTOM );
}

void CSelectMode::OnExpress()
{
	m_bCustom = FALSE;
	EndDialog( IDC_EXPRESS );
}

void CSelectMode::OnBack()
{
	EndDialog( IDC_BACK );
}

void CEndPhase1::OnBack()
{
	EndDialog( IDC_BACK );
}


void CWelcome::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

void CSelectMode::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

void CEndPhase1::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

/////////////////////////////////////////////////////////////////////////////
// CExit dialog


CExit::CExit(CWnd* pParent /*=NULL*/)
	: CDialog(CExit::IDD, pParent)
{
	//{{AFX_DATA_INIT(CExit)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}

void CExit::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CExit)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CExit, CDialog)
	//{{AFX_MSG_MAP(CExit)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CExit message handlers

BOOL CWelcome::OnInitDialog()
{
	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	// Center ourselves
	CenterDialog( this );

	return TRUE;  // return TRUE  unless you set the focus to a control
}


BOOL CExit::OnInitDialog()
{
	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	// Center ourselves
	CenterDialog( this );

	return TRUE;  // return TRUE  unless you set the focus to a control
}

BOOL CEndPhase1::OnInitDialog()
{
	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	// Center ourselves
	CenterDialog( this );

	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CCustomOpts::OnCancel()
{
	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );
	
	CDialog::OnCancel();
}

void CWelcome::OnCancel()
{
	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );

	CDialog::OnCancel();
}

void CEndPhase1::OnCancel()
{
	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );

	CDialog::OnCancel();
}

void CSelectMBoot::OnCancel()
{
	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );

	CDialog::OnCancel();
}

void CSelectMode::OnCancel()
{
	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );

	CDialog::OnCancel();
}

