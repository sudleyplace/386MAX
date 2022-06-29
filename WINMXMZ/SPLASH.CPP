// $Header:   P:/PVCS/MAX/WINMXMZ/SPLASH.CPV   1.3   30 May 1997 12:23:48   BOB  $
//
// splash.cpp - implementation of splash "dialog"
//

#include "stdafx.h"
#include "winmxmz.h"
#include "mxdlgs.h"
#include <splash.h>
#include "resource.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CSplashDlg dialog


CSplashDlg::CSplashDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CSplashDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CSplashDlg)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT

	// Create a modeless dialog
	Create( IDD, pParent );

}

void CSplashDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CSplashDlg)
	DDX_Control(pDX, IDC_SPLASHBMP, m_wndSplash);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CSplashDlg, CDialog)
	//{{AFX_MSG_MAP(CSplashDlg)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CSplashDlg message handlers

void CSplashBtn::DrawItem( LPDRAWITEMSTRUCT lpDraw )
{
#define CX_SHADOW	4
#define CY_SHADOW	4

	// Draw bitmap using lpDraw->hDC
	CDC dcTemp, *pDC;
	pDC = dcTemp.FromHandle( lpDraw->hDC );
	ASSERT(pDC != NULL);

	CWnd *pWnd = FromHandle( lpDraw->hwndItem );
	ASSERT( pWnd != NULL );

	// Create compatible DC
	CDC dcMem;
	if (!dcMem.CreateCompatibleDC(pDC))
		return;

	// Grow this control to occupy the entire dialog
	CRect rcParent;
	CWnd *pParent = GetParent();

	ASSERT( pParent );

	pParent->GetClientRect( rcParent );
	MoveWindow( rcParent );

	//CRect rect;
	//GetClientRect(rect);
	//int cxClient = rect.Width();
	//int cyClient = rect.Height();

	// Select bitmap into memory DC
	CBitmap* pBitmapOld = dcMem.SelectObject( &m_bmpSplash );
	if (pBitmapOld == NULL)
		return;

	// Move bits into button
	pDC->BitBlt( lpDraw->rcItem.left, lpDraw->rcItem.top,
					 lpDraw->rcItem.right - lpDraw->rcItem.left,
					 lpDraw->rcItem.bottom - lpDraw->rcItem.top,
					 &dcMem, 0, 0, SRCCOPY );

	//pDC->StretchBlt( lpDraw->rcItem.left, lpDraw->rcItem.top,
	//				 lpDraw->rcItem.right - lpDraw->rcItem.left,
	//				 lpDraw->rcItem.bottom - lpDraw->rcItem.top,
	//				 &dcMem, 0, 0,
	//				 m_bmpSplashInfo.bmWidth,
	//				 m_bmpSplashInfo.bmHeight, SRCCOPY );

	dcMem.SelectObject( pBitmapOld );
	pBitmapOld->DeleteObject();

}

void CSplashBtn::LoadBitmap( int wResID )
{
	m_bmpSplash.LoadBitmap( wResID );
	m_bmpSplash.GetObject( sizeof( m_bmpSplashInfo ), &m_bmpSplashInfo );
}

BOOL CSplashDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// Load bitmap
	m_wndSplash.LoadBitmap( IDB_SPLASHSCRN );

	// Resize dialog to exact size of bitmap but don't redraw yet
	MoveWindow( 0, 0, m_wndSplash.m_bmpSplashInfo.bmWidth,
					  m_wndSplash.m_bmpSplashInfo.bmHeight, FALSE );

	// Center the dialog
	CenterDialog( this );

	return TRUE;  // return TRUE  unless you set the focus to a control
}
