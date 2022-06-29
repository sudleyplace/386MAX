// $Header:   P:/PVCS/MAX/STATUTIL/BLUESCR.CPV   1.1   23 May 1996 13:29:24   HENRY  $
//
// BLUESCR.CPP - Blue screen "dialog" class
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#include <afxwin.h>

#include <statres.h>
#include <bluescr.h>

/////////////////////////////////////////////////////////////////////////////
// CBlue dialog


CBlue::CBlue(CWnd* pParent /*=NULL*/, LPCBWND lpCBWnd /*=NULL*/)
	: CDialog(CBlue::IDD, pParent)
{
	//{{AFX_DATA_INIT(CBlue)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT

	m_lpCB = lpCBWnd;

	// Create a modeless dialog
	Create( IDD, pParent );

}

void CBlue::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CBlue)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CBlue, CDialog)
	//{{AFX_MSG_MAP(CBlue)
	ON_WM_PAINT()
	ON_WM_LBUTTONDOWN()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CBlue message handlers

BOOL CBlue::OnInitDialog()
{
	CDialog::OnInitDialog();

	// Resize ourselves to take up the whole screen
	CWnd *pDesk = GetDesktopWindow();
	CRect rcDesk;

	ASSERT( pDesk != NULL );

	pDesk->GetWindowRect( rcDesk );

	// Now move it.
	MoveWindow( rcDesk );

	return TRUE;  // return TRUE  unless you set the focus to a control
}


void CBlue::OnPaint()
{
	CPaintDC dc(this); // device context for painting

	// Paint the screen blue
	CBrush brBlue;
	LOGBRUSH lbBrush;
	CRgn rgn;
	CRect crPaint;
	int i, xInc, yInc;

	lbBrush.lbStyle = BS_SOLID;
	//lbBrush.lbHatch = HS_DIAGCROSS;

	// Paint everything using RECT dc.m_ps.rcPaint
	// Step it in varying colors
	crPaint = dc.m_ps.rcPaint;
	xInc = -(crPaint.Width() / 10);
	yInc = -(crPaint.Height() / 10);

	for (i = 0; i < 6; i++, crPaint.InflateRect( xInc, yInc )) {

		if (!rgn.CreateRectRgnIndirect( crPaint )) {
			continue;
		} // Couldn't create region

		//lbBrush.lbColor = RGB( 0, 10, 127 );
		lbBrush.lbColor = RGB( 0, 10 + i * 4, 127 + i + 16 );

		if (!brBlue.CreateBrushIndirect( &lbBrush )) {
			continue;
		} // Couldn't create brush

		// Select the brush
		CBrush *pOldBr = dc.SelectObject( &brBlue );

		dc.PaintRgn( &rgn );

		// Deselect and delete it
		dc.SelectObject( pOldBr );

		rgn.DeleteObject();
		brBlue.DeleteObject();

	} // for all colors

	// Do not call CDialog::OnPaint() for painting messages
}


void CBlue::OnLButtonDown(UINT nFlags, CPoint point)
{
	// Always make specified dialog active
	CWnd *pSummary = NULL;
	if (m_lpCB) {
		pSummary = m_lpCB();
	}
	if (pSummary) {
		pSummary->SetActiveWindow();
	} // Summary dialog exists, make it active
	else {
		CDialog::OnLButtonDown(nFlags, point);
	} // Pass it on to default
}

