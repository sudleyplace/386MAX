// $Header:   P:/PVCS/MAX/SETUP/SETUP.CPV   1.6   20 Jan 1997 08:36:52   PETERJ  $
//------------------------------------------------------------------
// Setup.cpp
// by Peter Johnson
// Version 1.0
// 6 June, 1996
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
#include <ddeml.h>
#include <io.h>
#include <ctl3d.h>

    // define variables
#define SETUP_DEFVARS 1
#include <setglob.h>

 #ifdef _WIN16
    #include <dunzdll.h>
    #include <dzipdll.h>
#else
	#include <new.h>
    #include <dunzip32.h>
    #include <dzip32.h>
#endif

#include <setunzip.h>

HACCEL hAcc;

//------------------------------------------------------------------
// main()
//------------------------------------------------------------------
EXPORT32 int WINAPI EXPORT16 
WinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
    {
    MSG msg;
    ghInstance = hInstance;
    
        // prevent more than one instance.
#ifdef _WIN16
	if( hPrevInstance )
        {
            // pop up the other one if it has a window.
        WalkWindowList();
		return 1;
        }
#else
	if( WalkWindowList( ))
        {
		return 1;
        }
#endif 
        // register window class.
    if( !InitApplication( hInstance ))
        {
		return 1;
        }

        // get the os version number.
    dwVersion = GetVersion();
   
    if (((dwVersion & 0xFF) >= 4 ) || 
        (((dwVersion & 0xFF) == 3) && ((dwVersion >> 8) & 0xFF) >= 50))
        {
#ifdef _WIN32
        OSVERSIONINFO ov;
        ov.dwOSVersionInfoSize = sizeof( OSVERSIONINFO );
        GetVersionEx( &ov );
        if( ov.dwPlatformId == VER_PLATFORM_WIN32_NT )
            {
            bWinNT = TRUE;

            if( ov.dwMajorVersion >= 4 )
                {
                bWinNT4Plus = TRUE;
                }
            else
                {
                bWinNT4Plus = FALSE;
                }

            if( ( ov.dwMajorVersion < 3 ) ||
                (( ov.dwMajorVersion == 3 ) && ( ov.dwMinorVersion < 5 )))
                {
                bOldNT = TRUE;
                }
            }
#endif
        bWin95 = 1;
        }

#ifdef _WIN16
    else
        {
            // NT reports version 3.10 to 16 bit apps.
            // but they (ms) added an additional flag to GetWinFlags
            // to show it is NT.  ( WF_WINNT defined in setglob.h ) 
        if( WF_WINNT & GetWinFlags())
            {
            bWin95 = TRUE;
            bWinNT = TRUE;
            }
        }
#endif

        // NOTE! Don't use any program local functions until the setjmp
        // call below has been executed.
        // Many of them need the quit_env set for proper error exit.
        // Also Note! setjmp/longjmp are really Catch/Throw in the 16 bit 
        // version.  See SETUP.H.
    if( setjmp( quit_env ) < 0 ) 
        {
            // error returns here.
            // If we "crashed" explain why.
        if ( szGlobErrorMsg[0] )
            {
            MessageBox( GetFocus(), szGlobErrorMsg, szEMsg_Term, MB_OK );
            }
        goto Setup_Exit;
        }

        // Process command line flags.
        // Allow for method to inhibit splash screen.
    ProcessCmdLine( lpszCmdLine );

#ifdef _WIN16
    if( bWin95 && bBoost32 )
        {
        goto Setup_Exit;
        }
#endif

        // Initialize the system.
    if( !InitInst( hInstance, nCmdShow, lpszCmdLine ))
        {
		return 1;
        }

        // We should now have the current, windows, windows\system
        // directories loaded in their globals.
        
        // Show Splash Screen.
    if( !bSplashInhibit )
        {
        if ( InitSplash( ghInstance ))
            {
            ShowSplashWindow( hSplash );
            }
        else
            {
            bSplashInhibit = FALSE;
            }
        }
            
        // do any program specific initialization..
    ProcessInitialize();

#ifdef _WIN16
        // load CTL3DV2
    if( !bC3DInhibit )
        {
        LoadCTL3D();
        }
    
    if( bWin95 )
        {
        LoadThunkLib();
        }
#endif

    if( !bSplashInhibit )
        {
        StopSplashWindow( hSplash );
        }

    if( wACCTable )
        {
        hAcc = LoadAccelerators( hInstance, MAKEINTRESOURCE( wACCTable )); 
        }

                // set up the F1 help hook.
    if(( hpF1 = (HOOKPROC)MakeProcInstance( (FARPROC)F1FilterProc, 
                                                ghInstance )) != NULL )
        {
#ifdef _WIN32
        hhF1 = SetWindowsHookEx( WH_MSGFILTER, hpF1, ghInstance, 
                                            GetCurrentThreadId());
#else
        hhF1 = SetWindowsHookEx( WH_MSGFILTER, hpF1, ghInstance, 
                                            GetCurrentTask());
#endif
        }

        // put up the main (blue) window.
    ShowMainWindow();

        // Set the first state, and anything else you want 
        // to do before the loop starts.
        // Just post a message to the window to start things rolling.
    ProcessStartMessage();
    
        // Main message loop.
    while ( GetMessage( &msg, NULL, 0, 0 ))     
        {
        if( (!hGlobDlg) || (!IsDialogMessage( hGlobDlg, &msg )))
            {
            if( wACCTable )
                {
                if( !TranslateAccelerator( ghInstance, hAcc, &msg) )
                    {
                    TranslateMessage( &msg );    
                    DispatchMessage( &msg );     
                    }
                }
            else
                {
                TranslateMessage( &msg );    
                DispatchMessage( &msg );     
                }
            }
        }

Setup_Exit:

#ifdef _WIN16
    if( !bC3DInhibit && hlibCTL3D )
        {
        C3DUnregister( ghInstance );
        FreeLibrary( hlibCTL3D );
        }
#endif

    if( hlibDUNZIP )
        {
        FreeLibrary( hlibDUNZIP );
        }
    
        // release the F1 hook.
    if( hhF1 != NULL )
        {
        UnhookWindowsHookEx( hhF1 );
        }
    
    if( hpF1 != NULL )
        {
        FreeProcInstance( hpF1 );
        }

    if( bClassReg )
        {
        UnregisterClass( szSetupWndClass, ghInstance );
        }

    if( bDlgClassReg )
        {
        UnregisterClass( szSetupDlgClass, ghInstance );
        }

#ifdef _WIN16
        // release the thunk library.
    if( bWin95 && hlibThunk )
        {
        FreeThunkLib();
        }
#endif

        // Remember the main window is gone by now.
        // So are the thunk, zip and ctrl3d functions.
        // This function may restart Windows.
    ProcessExitSpecials();

        // release all allocated memory.
    Cleanup();

#ifdef _WIN16
    if( bWin95 && bBoost32 )
        {
        char szT1[ _MAX_PATH + 2 ];
        GetModuleFileName( hInstance, szT1, _MAX_PATH );
        MakeFileExt( path_part( szT1 ), szC_ProgTitle32, szExeExt, szT1 );
        WinExec( szT1, SW_SHOW );
        }
#endif

    return( msg.wParam );      
    }

//------------------------------------------------------------------
extern "C" EXPORT32 LRESULT CALLBACK EXPORT16 
MainWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );

    switch (uMsg) 
        {
        case WM_CLOSE:
            DestroyWindow( hWnd );
            return 0;

        case WM_COMMAND:
            return ProcessMainCmds( hWnd, uMsg, wParam, lParam );

        case WM_PAINT:
            UpdateMainScreen( hWnd );
            return 0;

        case WM_DESTROY:       
            PostQuitMessage(0);
            hParent = NULL;
            return 0;

        default:         
            return (DefWindowProc(hWnd, uMsg, wParam, lParam));
        }

    return FALSE;
    }

//------------------------------------------------------------------
BOOL InitApplication( HINSTANCE hInstance )
    {
    WNDCLASS  wc;

    szGlobErrorMsg[0] = '\0';
    wc.style          = CS_VREDRAW | CS_HREDRAW; 
    wc.lpfnWndProc    = (WNDPROC)MainWndProc;
    wc.cbClsExtra     = 0;
    wc.cbWndExtra     = 0;
    wc.hInstance      = ghInstance;
    wc.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(SETICON));
    wc.hCursor        = NULL;
    wc.hbrBackground  = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName   = (LPSTR)NULL;
    wc.lpszClassName  = (LPSTR)szSetupWndClass;
    if( RegisterClass(&wc) )
        {
        bClassReg = TRUE;
        }

    return ( bClassReg );
    }

//------------------------------------------------------------------
// Initialization function. Called at beginning of program.
//------------------------------------------------------------------
BOOL InitInst( HINSTANCE hInstance, int nCmdShow, LPSTR lpCmdLine )
    {
    hParent = CreateWindowEx(
            (DWORD)0,
            (LPCSTR)szSetupWndClass, 
            (LPCSTR)szC_ProgTitle,             
            WS_OVERLAPPED | WS_CAPTION | WS_MINIMIZEBOX,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            (HWND)NULL,                
            (HMENU)NULL,              
            hInstance,
            (LPVOID) NULL 
            );
  
    if ( !hParent )
        {
        return (FALSE);
        }   

    hcArrow = LoadCursor( NULL, IDC_ARROW );
    hcHour  = LoadCursor( NULL, IDC_WAIT  );
    SetCursor( hcArrow );

        // clear the global error message.
    SetErrMsg( NULL );
    bFileError = FALSE;
        
        // load the hourglass cursor.
    hcHour = LoadCursor( NULL, IDC_WAIT );

        // find out where we are. 
        // Initializes global directories for other functions.
    GetEnvInfo( ghInstance );

        // start the process.
    return TRUE;
    }

//------------------------------------------------------------------
void ShowMainWindow()
    {
    SendMessage( hParent, WM_SETTEXT, 0, (LPARAM)(LPSTR)szBuff_Title );
    ShowWindow( hParent, SW_SHOWMAXIMIZED);
    UpdateWindow( hParent );
    }

//------------------------------------------------------------------
#define SCR_DIVS 16
#define COLOR_INC ( 245 / (SCR_DIVS))
void
UpdateMainScreen( HWND hMWin )
    {
    HBITMAP hBitmap = NULL;
    HBITMAP hBMOld;
    static BITMAP bmDisp;

    HDC hDC, hdcMem;            
    PAINTSTRUCT ps;
    HBRUSH hbr, hbrOld;
    RECT rc, rc2;
    int nInc, nDx, nColor;

    hDC = BeginPaint(hMWin,&ps);

    GetWindowRect( hMWin, &rc );
    rc2.left = rc.left;
    rc2.right = rc.right;
    rc2.top = rc.top;

    nInc = ((rc.bottom - rc.top) / SCR_DIVS) - 1;
    rc2.bottom = rc.top + nInc;
   
    nColor = 255;
    hbr = CreateSolidBrush( RGB( 0, 0, nColor ));
    hbrOld = SelectObject( hDC, hbr );
    FillRect( hDC, &rc2, hbr );
    SelectObject( hDC, hbrOld );
    DeleteObject( hbr );

    for( nDx = 1; nDx < SCR_DIVS; nDx++ )
        {
        rc2.top = rc2.bottom;
        if( nDx == ( SCR_DIVS - 1 ))
            {
            rc2.bottom = rc.bottom;
            }
        else
            {
            rc2.bottom = rc2.top + nInc;
            }
        nColor -= COLOR_INC;
        hbr = CreateSolidBrush( RGB( 0, 0, nColor ));
        FillRect( hDC, &rc2, hbr );
        SelectObject( hDC, hbrOld );
        DeleteObject( hbr );
        }

    hBitmap  = LoadBitmap( ghInstance, "SETUP"  );

    if (( hdcMem = CreateCompatibleDC( hDC )) != NULL )
        {
            // get the bitmap size
        GetObject( (HGDIOBJ) hBitmap, sizeof( BITMAP ), &bmDisp );
        hBMOld = SelectObject( hdcMem, hBitmap );
        BitBlt( hDC, 0,0, bmDisp.bmWidth, bmDisp.bmHeight, hdcMem, 
                                                    0, 0, SRCCOPY );
        SelectObject( hdcMem, hBMOld );
        }
    
        // free the created bitmap DC.
    if( hdcMem != NULL )
        {
        DeleteDC( hdcMem );
        }

        // free the bitmap.
    DeleteObject( hBitmap );

    EndPaint(hMWin, &ps);
    }

//------------------------------------------------------------------
// Clean up allocated memory before exiting.
//------------------------------------------------------------------
void Cleanup()
    {
    if( lpProgName != NULL ) { _ffree( lpProgName ); lpProgName = NULL; }
    if( lpProgPath != NULL ) { _ffree( lpProgPath ); lpProgPath = NULL; }
    if( lpHelpFile != NULL ) { _ffree( lpHelpFile ); lpHelpFile = NULL; }
    if( lpStartup  != NULL ) { _ffree( lpStartup  ); lpStartup  = NULL; }
    if( lpIniFile  != NULL ) { _ffree( lpIniFile  ); lpIniFile  = NULL; }
    if( lpWIniFile != NULL ) { _ffree( lpWIniFile ); lpWIniFile = NULL; }
    if( lpWinPath  != NULL ) { _ffree( lpWinPath  ); lpWinPath  = NULL; }
    if( lpSysPath  != NULL ) { _ffree( lpSysPath  ); lpSysPath  = NULL; }

    ProcessCleanup();

    _fheapmin();
    }

#ifdef _WIN16
//------------------------------------------------------------------
// get ctl3d into it's proper place and load it.
// Sets bC3DInhibit flag if failure occurrs.
//------------------------------------------------------------------
BOOL LoadCTL3D()
    {
    BOOL bRet = TRUE;
    int nVCRet;
    BOOL bOnDisk=FALSE;
    BOOL bFoundOld=FALSE;
    BOOL bGoLoad=FALSE;
    UINT uCurLen = _MAX_PATH;
    UINT uDestLen = _MAX_PATH;
    char lpCurDirBuff[ _MAX_PATH + 2 ];
    char lpDestDirBuff[ _MAX_PATH + 2 ];
    
    if( !bC3DInhibit )
        {
            // if we have it on the loader disk, 
            // we always try a re-install.
        MakePath( lpProgPath, szC_Ctl3Comp, szTemp );
        if( QueryFileExists( szTemp ))
            {
            bOnDisk = TRUE;
            }
        }
        
    if( (!bC3DInhibit) && bOnDisk )
        {
            // ...then we intend to load it.
            // do the version stuff. This should result in 
            // an installed version.
        nVCRet = VerChkCopyFiles( szC_Ctl3Comp, lpProgPath, 
                                  szC_Ctl3dLib, lpSysPath,
                                  lpWinPath, lpCurDirBuff, &uCurLen, 
                                  lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
        
        if(( nVCRet != VCC_SUCCESS) && (nVCRet != VCC_FILEINUSE ))
            {
                // error, didn't install;
            bC3DInhibit = TRUE;
            bRet = FALSE;
            }
        }
    else
        {
            // we don't have a local copy, we just want to load the one
            // that is in the system.
        if( !bC3DInhibit )
            {
                // see if it exists in the system dir.
            MakePath( lpSysPath, szC_Ctl3dLib, szTemp );
            if( QueryFileExists( szTemp ))
                {
                bFoundOld=TRUE;
                }
            else
                {
                MakePath( lpWinPath, szC_Ctl3dLib, szTemp );
                if( QueryFileExists( szTemp ))
                    {
                    bFoundOld=TRUE;
                    }
                else
                    {
                        // it doesn't exist and we don't have it.
                        // Turn the ctl3d stuff off.
                    bC3DInhibit = TRUE;
                    }
                }
            }
        }

    if( !bC3DInhibit )
        {
        if( LoadCtl3dLibrary( szC_Ctl3dLib ))
            {
            C3DRegister( ghInstance );
            C3DAutoSubclass( ghInstance );
            }
        else
            {
            bC3DInhibit = TRUE;
            bRet = FALSE;
            }
        }
    return bRet;
    }
#endif

//------------------------------------------------------------------
extern "C" EXPORT32 DWORD EXPORT16 CALLBACK F1FilterProc( int nCode, WPARAM wParam, LPARAM lParam)
    {
    LPMSG lpmsg = (LPMSG)lParam;
            
        // do not pass on DDEMGR messages. MS - Q89828
    if( nCode == MSGF_DDEMGR )
        {
        return (DWORD)0;
        }
    
    if( hGlobDlg 
        && ( nCode == MSGF_DIALOGBOX )
        && lpmsg->message == WM_KEYDOWN 
        && lpmsg->wParam == VK_F1 )
        {
        SendMessage( hGlobDlg, WM_COMMAND, wHelpID, 0L ); 
        }

    return CallNextHookEx( hhF1, nCode, wParam, lParam );
    }

