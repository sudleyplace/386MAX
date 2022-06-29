// $Header:   P:/PVCS/MAX/STATUTIL/CENTDLG.CPV   1.1   23 May 1996 13:30:28   HENRY  $
//
// CENTDLG.CPP - Center dialog
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#include <afxwin.h>

#include <statmfc.h>

// Center a dialog (or other window)
void CenterDialog( CWnd *pWnd ) {

	CWnd *pDesk = pWnd->GetDesktopWindow();
	CRect rcDesk, rcThis;
	CPoint ptMove;

	ASSERT( pDesk != NULL );

	pDesk->GetWindowRect( rcDesk );
	pWnd->GetWindowRect( rcThis );

	// Get offset to new top left.
	ptMove.x = rcDesk.Width() / 2 - rcThis.Width() / 2 - rcThis.left;
	ptMove.y = rcDesk.Height() / 2 - rcThis.Height() / 2 - rcThis.top;

	// Now move it.
	rcThis += ptMove;
	pWnd->MoveWindow( rcThis );

} // CenterDialog

