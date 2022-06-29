// $Header:   P:/PVCS/MAX/SETUP/SETSPL.CPV   1.1   18 Jul 1996 12:20:18   PETERJ  $
//------------------------------------------------------------------
// Setspl.cpp
// by Peter Johnson
// Version 1.0
// 24 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
//------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <commdlg.h>
#include <direct.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <io.h>
#include <ctl3d.h>

    // define variables
#include <setglob.h>

//------------------------------------------------------------------
extern "C" EXPORT32 LRESULT CALLBACK EXPORT16 
SplashWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static int nSecs = 0;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );

    switch (uMsg) 
        {
        case WM_SHOWWINDOW:
            nSecs = 0; 
            break;
            
        case WM_NCDESTROY:
            bSplashActive = FALSE;
            break;

        case WM_CLOSE:
            DestroyWindow( hWnd );
            return 0;

        case WM_PAINT:
            UpdateSplashScreen( hWnd );
            return 0;

        default:         
            break;
        }
        
        // everything goes here unless completely handled above.
    return (DefWindowProc(hWnd, uMsg, wParam, lParam));
    }

//------------------------------------------------------------------
BOOL InitSplash( HINSTANCE hInstance )
    {
    WNDCLASS  wc;
    BITMAP bmDisp;
    int nFHeight;
    int nFWidth;
    
    if( !bSplashReg )
        {
        wc.style          = CS_VREDRAW | CS_HREDRAW; 
        wc.lpfnWndProc    = (WNDPROC)SplashWndProc;
        wc.cbClsExtra     = 0;
        wc.cbWndExtra     = 0;
        wc.hInstance      = hInstance;
        wc.hIcon          = NULL;
        wc.hCursor        = NULL;
        wc.hbrBackground  = (HBRUSH)(COLOR_WINDOW + 1);
        wc.lpszMenuName   = (LPSTR)NULL;
        wc.lpszClassName  = (LPSTR)szSplashWndClass;

        if( !RegisterClass(&wc))
            {
            bSplashReg = FALSE;
            return FALSE;
            }

        bSplashReg = TRUE;
        }

    hSplash = CreateWindowEx(
            (DWORD)WS_EX_TOPMOST,
            (LPCSTR)szSplashWndClass, 
            NULL,
            WS_DLGFRAME | WS_POPUP,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            (HWND)HWND_DESKTOP,                
            (HMENU)NULL,              
            hInstance,
            (LPVOID) NULL 
            );
  
    if ( !hSplash )
        {
        return (FALSE);
        }   
    
    if(( hbSplash = LoadBitmap( ghInstance, "SETUP"  )) == NULL )
        {
        return (FALSE);
        }

    GetObject( (HGDIOBJ) hbSplash, sizeof( BITMAP ), &bmDisp );
    nBMWidth = bmDisp.bmWidth;
    nBMHeight = bmDisp.bmHeight;
    nFWidth = GetSystemMetrics( SM_CXDLGFRAME );
    nFHeight = GetSystemMetrics( SM_CYDLGFRAME );

    nBMHeight += ( nFHeight * 2 );
    nBMWidth  += ( nFWidth * 2 );

    nBMHeight += 2;
    nBMWidth  += 2;
    
    return TRUE;
    }

//------------------------------------------------------------------
void ShowSplashWindow( HWND hSplash )
    {
    bSplashActive = TRUE;
        
        // get the start time.
    time( &ttSplashStart );
        
        // set the correct size.
    SetWindowPos( hSplash, HWND_TOP, 0, 0, nBMWidth, nBMHeight, 
                                                    SWP_NOMOVE );
        // to the middle.
    CenterWindow( hSplash );
    UpdateWindow( hSplash );
    }

//------------------------------------------------------------------
void StopSplashWindow( HWND hSplash )
    {
    time_t ttNow;

    time( &ttNow );
            
    while( nSplashWait > (int) difftime( ttNow, ttSplashStart))
        {
        SYield(0);
        time( &ttNow );
        }

        // kill it.
    SendMessage( hSplash, WM_CLOSE, 0, 0L );

        // wait for it to work
    while( bSplashActive )
        {
        SYield(0);
        }

        // free the bitmap.
    if( hbSplash != NULL )
        {
        DeleteObject( hbSplash );
        }
    
    if( !bSplashActive && bSplashReg )
        {
        UnregisterClass( szSplashWndClass, ghInstance );
        }
    }

//------------------------------------------------------------------
void
UpdateSplashScreen( HWND hMWin )
    {
    HBITMAP hBMOld;
    HDC hDC, hdcMem;            
    PAINTSTRUCT ps;

    hDC = BeginPaint(hMWin,&ps);

    if (( hdcMem = CreateCompatibleDC( hDC )) != NULL )
        {
            // get the bitmap size
        hBMOld = SelectObject( hdcMem, hbSplash );
        BitBlt( hDC, 0,0, nBMWidth, nBMHeight, hdcMem, 0, 0, SRCCOPY );
        SelectObject( hdcMem, hBMOld );
        }

        // free the created bitmap DC.
    if( hdcMem != NULL )
        {
        DeleteDC( hdcMem );
        }

    EndPaint(hMWin, &ps);
    }

