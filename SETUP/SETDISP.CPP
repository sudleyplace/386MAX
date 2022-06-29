// $Header:   P:/PVCS/MAX/SETUP/SETDISP.CPV   1.5   25 Mar 1997 14:34:00   PETERJ  $
//------------------------------------------------------------------
// SETDISP.CPP
// Display functions for Setup
// Version 1.0
// 7 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
//------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <malloc.h>
#include <time.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <ctl3d.h>

#ifdef _WIN32
    #include <dunzip32.h>
#else
    #include <dunzdll.h>
#endif

#include <statutil.h>
#include <setglob.h>
#include <setunzip.h>

//------------------------------------------------------------------
void StartDisplay( LPSTR szText, LPSTR szTitle )
    {
    hModeless = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_MODELESS ), hParent, (FARPROC)ModelessDlgProc);
    SendMessage( hModeless, WM_SETTEXT, 0, (LPARAM)szTitle );
    SetDlgItemText( hModeless, IDC_STATUS1, szText );
	SYield( 0 );
    }

//------------------------------------------------------------------
// Use LPCSTR rather than LPSTR when no changes will be made to the string...
void ChangeDisplay( LPCSTR szText )
    {
    SetDlgItemText( hModeless, IDC_STATUS1, szText );
	SYield( 0 );
    }

//------------------------------------------------------------------
void ChangeDisplay2( LPCSTR szText )
    {
    SetDlgItemText( hModeless, IDC_STATUS2, szText );
	SYield( 0 );
    }

//------------------------------------------------------------------
void EndDisplay( )
    {
    DestroyWindow( hModeless );
	SYield( 0 );
    }

//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ModelessDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static HWND hPrev = NULL;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            hPrev = hActive;
            hActive = hDlg;
            CenterWindow( hDlg );
            return TRUE;

#ifdef _WIN16
        case WM_CTLCOLOR:
            if( !bC3DInhibit )
                {
                return (BOOL)(UINT) C3DCtlColorEx( uMsg, wParam, lParam);
                }
            else
                {
                return FALSE;
                }
#endif

        case WM_DESTROY:
            hActive = hPrev;
            return FALSE;
        }
    return FALSE;
    }


//------------------------------------------------------------------
// copy meter dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ExtractDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    HWND hMeter;
    HMODULE hDet;
    char szT1[ _MAX_PATH + 2 ];
    static HWND hPrev = NULL;
        
	switch (uMsg) 
        {
        case WM_INITDIALOG:
            hPrev = hActive;
            hActive = hDlg;
            CenterWindow( hDlg );
            SetWindowText( hDlg, szMsg_Extracting );
            SetTimer( hDlg, 1, (unsigned int)100, 0L );
            return TRUE;

        case WM_TIMER:
            KillTimer( hDlg, 1 );
            
            hMeter = GetDlgItem( hDlg, IDC_METER);

                // extract the files
            HideCaret( NULL );
            DrawMeter( hMeter, 0);

                // while...

                // read in the packing list.
            MakePath( lpProgPath, szQPFile, szTemp );
            ReadQPFile( szTemp );
            SYield(0);
            
                // put the dunzip.dll on the system.
            if( CopyUnzipDll() != VCC_SUCCESS )
                {
                KillDiskList( &lpADisks );
                EndDialog( hDlg, SU_CANCEL );
                PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                return 0L;
                }

            SYield(0);

                // load the unzip library
            if( hlibDUNZIP == NULL )
                {
#ifdef _WIN32
                    // Trap somebody else using DUNZIP32.DLL 
                    // ( or if 16 bit... DUNZIP.DLL ) because it may be an
                    // older version.
                    // NOTE! Static linking of DUNZIP(32).DLL to this
                    // code will always trigger this warning.
                hDet = NULL;
                do
                    {
                    if(( hDet = GetModuleHandle( szC_DUNZIP32Lib )) != NULL )
                        {
                        int nAns;

                        GetModuleFileName( hDet, szT1, _MAX_PATH );
                        wsprintf( szTemp, szFmt_DllInUse, szT1 );
                        nAns = MessageBox( GetFocus(), szTemp, szBuff_Title, MB_ABORTRETRYIGNORE | MB_ICONWARNING );
                        if( nAns == IDABORT )
                            {
                            KillDiskList( &lpADisks );
                                // SU_CANCEL forces call to IDM_EXIT.
                            EndDialog( hDlg, SU_CANCEL );
                            return 0L;
                            }
                        else if( nAns == IDIGNORE )
                            {
                            hDet = NULL;
                            }
                        }
                    }while( hDet != NULL );
                
                MakePath( lpWinPath, szC_DUNZIP32Lib, szT1 );
                if(( hlibDUNZIP = LoadUnzipLibrary( szT1 )) == NULL ) 
                    {
                    SetErrMsg( szEMsg_ZipLib32 );
                    CrashExit();
                    }
#else
                hDet = NULL;
                do
                    {
                    if(( hDet = GetModuleHandle( szC_DUNZIPLib )) != NULL )
                        {
                        int nAns;
                        GetModuleFileName( hDet, szT1, _MAX_PATH );
                        wsprintf( szTemp, szFmt_DllInUse, szT1 );
                        nAns = MessageBox( GetFocus(), szTemp, szBuff_Title, MB_ABORTRETRYIGNORE | MB_ICONHAND );
                        if( nAns == IDABORT )
                            {
                            KillDiskList( &lpADisks );
                                // SU_CANCEL forces call to IDM_EXIT.
                            EndDialog( hDlg, SU_CANCEL );
                            return 0;
                            }
                        else if( nAns == IDIGNORE )
                            {
                            hDet = NULL;
                            }
                        }
                    } while( hDet != NULL );

                MakePath( lpWinPath, szC_DUNZIPLib, szT1 );
                if(( hlibDUNZIP = LoadUnzipLibrary( szC_DUNZIPLib )) == NULL ) 
                    {
                    SetErrMsg( szEMsg_ZipLib );
                    CrashExit();
                    }
#endif
                }
            
            SYield(0);
            CopySetup();
            SYield(0);

                // extract the appropriate files from the zip.
            ProcessDiskList( (LPDISKLIST FAR *)&lpADisks, hMeter );
            SYield(0);

                // almost done.
            DrawMeter( hMeter, 90 );
            SYield(0);

                // free the disk list memory.
            KillDiskList( &lpADisks );
            SYield(0);

            DrawMeter( hMeter, 100 );
            SYield(0);

            ShowCaret( NULL );
            EndDialog( hDlg, SU_OK );
            return 0L;
    
        case WM_DESTROY:
            hActive = hPrev;
            return FALSE;
        }
    return 0L;
    }

//------------------------------------------------------------------
// extract the appropriate files from the diskettes.
// specific to this product.
// This function should call DrawMeter with nPercent parameters from
// 10% to 100%.
//------------------------------------------------------------------
void ProcessDiskList( LPDISKLIST FAR *lpADisks,  HWND hMeter )
    {
    LPDISKLIST lpScan=NULL;
    LPFILELIST lpFL=NULL;
    UINT uProd;
    char szArc[ _MAX_PATH + 2 ];
    UINT uTotalFiles;
    UINT uPercent;
    UINT uIncrement;
    double dRange;
    
    uProd = (bWin95) ? 2 : 1;

        // count the total number of files.
    uTotalFiles = 0;
    for( lpScan = (*lpADisks); lpScan ; lpScan = lpScan->next )
        {
        for( lpFL = lpScan->file ; lpFL ; lpFL = lpFL->next )
            {
            if( ( lpFL->uSeq == 0 ) || ( lpFL->uSeq == uProd ))
                {
                ++uTotalFiles;
                }
            }
        }
        
        // figure out the meter scaling. ( on file basis, not size for now );
    dRange = 90;
    uIncrement = (UINT)( dRange / uTotalFiles );  
    uPercent = 10;
        
        // show them 10% to start.
    DrawMeter( hMeter, uPercent );

        // for each disk in the list.
    for( lpScan = (*lpADisks); lpScan ; lpScan = lpScan->next )
        {
        CZopen cz((UINT)ghInstance);
        
        MakePath( lpProgPath, lpScan->lpArchive, szArc );
        if( QueryFileExists( szArc ) == 0 )
            {
                // ask for new disk containing the archive.
#pragma message( "Fixme! Next disk" )
            }

        cz.SetZip( szArc );
        for( lpFL = lpScan->file ; lpFL ; lpFL = lpFL->next )
            {
            if( lpFL->lpFilename && (lpFL->lpFilename[0] != '\0' ))
                {
                if( ( lpFL->uSeq == 0 ) || ( lpFL->uSeq == uProd ))
                    {
                    if( cz.GetFromZip( lpFL->lpFilename, szInstallDir, FALSE )
                                                                       == -1 )
                        {
                        char szT1[ _MAX_PATH + 82 ];
                            // error extracting.
                        wsprintf( (LPSTR)szT1, szFmtMsg_Extract, 
                                  lpFL->lpFilename, szArc );
                        MessageBox( hParent, szT1, szBuff_Title, MB_OK );
                        bFileError = TRUE;
                        }
                    
                    uPercent += uIncrement;
                    DrawMeter( hMeter, uPercent );
                    }
                }
                // let someone else have some fun.
            SYield(0);
            }
        cz.CloseAll();
        }
    }

//------------------------------------------------------------------
// draw the copy progress meter
//------------------------------------------------------------------
int DrawMeter(HWND hWnd, int nPercent)
    {
	char szText[8];
	int n, nHeight;
	LONG lRight;
	HDC hDC;
	RECT rc;
	HBRUSH hBrush;
	TEXTMETRIC tm;

	GetClientRect(hWnd, &rc);
	lRight = rc.right;
	lRight *= nPercent;
	n = (int)(lRight / 100);

	hDC = GetDC(hWnd);

	rc.top += 1;
	rc.left += 1;
	rc.bottom -= 1;
	rc.right = n;
	hBrush = CreateSolidBrush( RGB(0, 0, 255) );
	FillRect(hDC, &rc, hBrush);
	DeleteObject(hBrush);

	// clear the rest of the box
	GetClientRect(hWnd, &rc);
	rc.left = n + 1;
	rc.top += 1;
	rc.bottom -= 1;
	rc.right -= 1;
	hBrush = CreateSolidBrush( RGB(255, 255, 255) );
	FillRect(hDC, &rc, hBrush);
	DeleteObject(hBrush);

	SetBkMode( hDC, TRANSPARENT );
	if (nPercent > 50)
		SetTextColor( hDC, RGB(255,255,255) );
	wsprintf( szText, "%d%%", nPercent );
	GetClientRect( hWnd, &rc );

	GetTextMetrics( hDC, &tm );
	nHeight = tm.tmHeight + tm.tmExternalLeading;
	rc.top = ((rc.bottom - nHeight) / 2);

	DrawText( hDC, szText, lstrlen(szText), &rc, DT_CENTER );

	ReleaseDC( hWnd, hDC );
	return 0;
    }
    
//------------------------------------------------------------------
void CopySetup()
    {
    char szT1[ _MAX_PATH + 2 ];
    char szT2[ _MAX_PATH + 2 ];

#ifdef _WIN32
    MakeFileExt( lpProgPath, szC_ProgTitle32, szExeExt, szT1 );
    MakeFileExt( szInstallDir, szC_ProgTitle32, szExeExt, szT2 );
    FileCopy( szT2, szT1 );
#endif

    MakeFileExt( lpProgPath, szC_ProgTitle, szExeExt, szT1 );
    MakeFileExt( szInstallDir, szC_ProgTitle, szExeExt, szT2 );
    FileCopy( szT2, szT1 );

    MakeFileExt( lpProgPath, szC_ProgTitle, szHlpExt, szT1 );
    MakeFileExt( szInstallDir, szC_ProgTitle, szHlpExt, szT2 );
    FileCopy( szT2, szT1 );

#ifdef _WIN16
    if( bWin95  )
        {
        MakePath( lpProgPath, szC_ThunkLibName, szT1 );
        MakePath( lpProgPath, szC_Thunk32Name, szT2 );
        
        if( ( QueryFileExists( szT1 ) > 0 )
         && ( QueryFileExists( szT2 ) > 0 ))
            {
            MakePath( lpProgPath, szC_ThunkLibName, szT1 );
            MakePath( szInstallDir, szC_ThunkLibName, szT2 );
            FileCopy( szT2, szT1 );

            MakePath( lpProgPath, szC_Thunk32Name, szT1 );
            MakePath( szInstallDir, szC_Thunk32Name, szT2 );
            FileCopy( szT2, szT1 );
            }
        }
#endif
    }
