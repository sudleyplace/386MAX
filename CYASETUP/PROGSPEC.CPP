// $Header:   P:/PVCS/MAX/CYASETUP/PROGSPEC.CPV   1.5   20 Jan 1997 08:39:04   PETERJ  $
//------------------------------------------------------------------
// progspec.cpp
// by Peter Johnson
// Version 1.0
// 6 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
// This module should contain all program specific functions for
// linking with the generic setup functions. 
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

#include <setglob.h>
#include <setunzip.h>

    // define the variables now.
#define PROGSPEC_DEFVARS 1
#include "progspec.h"
#include "cya_ids.h"

 #ifdef _WIN16
    #include <dunzdll.h>
    #include <dzipdll.h>
#else
	#include <new.h>
    #include <dunzip32.h>
    #include <dzip32.h>
#endif

//------------------------------------------------------------------
// Main window command processing.
// This controls the main program sequence.
// PostMessage to hParent to select next process state.
//------------------------------------------------------------------
LPARAM ProcessMainCmds( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam )
    {
    int nDRet;
    WORD id;
    WORD cmd;
    HWND hChild;
    LPARAM lpRet=0;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch( id ) 
        {
        //------------------------------------------------------------------
        // Install functions.
        //------------------------------------------------------------------
        case IDM_INTRO:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_WELCOME ), 
                                        hParent, (DLGPROC)WelcomeDlgProc);
            return 0;

        case IDM_USERINFO:
            if( CheckUser() )
                {
                PostMessage( hParent, WM_COMMAND, IDM_OLDUSER, 0L);
                }
            else
                {
                hGlobDlg = CreateDialog( ghInstance, 
                                         MAKEINTRESOURCE( IDD_USERINFO ),
                                         hParent, (DLGPROC)UserInfoDlgProc);
                }
            return 0;

        case IDM_CONFIRMUSER:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_CONFIRMUSER ),
                                        hParent, (DLGPROC)ConfirmUIDlgProc);
            return 0;

        case IDM_OLDUSER:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_OLDUSER ),
                                        hParent, (DLGPROC)OldUIDlgProc);
            return 0;

        case IDM_DIRECTORY:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_DIRECTORY ), 
                                        hParent, (DLGPROC)DirDlgProc);
            return 0;

        case IDM_EXTRACTFILES:
            nDRet = DialogBox( ghInstance, MAKEINTRESOURCE( IDD_EXTRACT ), 
                         hParent, (DLGPROC)ExtractDlgProc);
        
                // clear the box immediately
            UpdateWindow( hParent );
            SYield(0);

                // move the other dlls to the windows directory.
            if( nDRet == SU_OK )
                {
                MoveLocalToShared();
                }

            PostMessage( hParent, WM_COMMAND, 
                         Decide2( nDRet, IDM_AUTOCONFIG, IDM_EXIT), 0L);
            return 0;

        case IDM_AUTOCONFIG:
            AutoConfig();
            PostMessage( hParent, WM_COMMAND, IDM_FILESET, 0L);
            return 0;

        case IDM_FILESET:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_FILESET ),
                                        hParent, (DLGPROC)FilesetDlgProc);
            return 0;

        case IDM_SCHEDULE:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_SCHEDULE ),
                                        hParent, (DLGPROC)ScheduleDlgProc);
            return 0;

        case IDM_TRAYNOTE:
            if( bWin95 && !( bWinNT && !bWinNT4Plus ))
                {
                    // ask first.
                hGlobDlg = CreateDialog( ghInstance, 
                                         MAKEINTRESOURCE( IDD_TRAYASK ), 
                                         hParent, (DLGPROC)TrayAskDlgProc);
                }
            else
                {
                    // not applicable, just continue.
                bTraynote = FALSE;
                if( !bReinstall )
                    {
                    PostMessage( hParent, WM_COMMAND, IDM_PGROUP, 0L);
                    }
                else
                    {
                    PostMessage( hParent, WM_COMMAND, IDM_ICONTOGROUP, 0L);
                    }
                }
            return 0;

        case IDM_PGROUP:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_PGROUP ),
                                        hParent, (DLGPROC)PGroupDlgProc);
            return 0;

        case IDM_ICONTOGROUP:
            nDRet = IDNO;
            if( bWin95 && !( bWinNT && !bWinNT4Plus ))
                {
                TraynoteConfig();
                }

            if( !InstallIcon())
                {
                PostMessage( hParent, WM_COMMAND, IDM_PGROUP, 0L);
                return 0;
                }
            SYield(0);
            nDRet = MessageBox( hParent, szMsg_ExitRun, szBuff_Title, MB_YESNO );
            if( nDRet == IDYES )
                {
                bRunCYAOnExit = TRUE;
                }
            bComplete = TRUE;
            PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
            return 0;

        //------------------------------------------------------------------
        // uninstall functions.
        //------------------------------------------------------------------
        case IDM_UNINTRO:
            hGlobDlg = CreateDialog( ghInstance, MAKEINTRESOURCE( IDD_UNINSTALL ), 
                                        hParent, (DLGPROC)UninstallDlgProc);
            return 0;

        case IDM_UNINSTALL:
            Do_Uninstall();
            bComplete = TRUE;
            PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
            return 0;

        //------------------------------------------------------------------
        // Don't change the exit or help cases without good reason.
        //------------------------------------------------------------------
        case IDM_EXIT:
            if( !bComplete || bFileError )
                {
                if( bUninstall )
                    {
                    MessageBox( hParent, szEMsg_UnNotDone, szBuff_Title, 
                                                MB_OK | MB_ICONHAND );
                    }
                else
                    {
                    MessageBox( hParent, szEMsg_NotDone, szBuff_Title, 
                                                MB_OK | MB_ICONHAND );
                    }
                }

                // terminate the program.
            PostMessage( hParent, WM_CLOSE, 0, 0L); 
            return 0;

        case IDM_HELP:
            WinHelp( hWnd, lpHelpFile, HELP_KEY, (DWORD)((char FAR *) szHK_Main ));
            return 0;

        case IDM_HELPCONTENTS:
            WinHelp( hWnd, lpHelpFile, HELP_KEY, (DWORD)((char FAR *) szHK_Contents ));
            return 0;
        }
    
    return 0;
    }

//------------------------------------------------------------------
// input command line processing.
// set global flags based on command line.
//------------------------------------------------------------------
void ProcessCmdLine( LPSTR lpCmd )
    {
    LPSTR lpTemp;
    if ( (( lpTemp = _fstrstr( lpCmd, (LPSTR)"/U" )) != NULL ) 
      || (( lpTemp = _fstrstr( lpCmd, (LPSTR)"/u" )) != NULL ))
        {
        bUninstall = TRUE;
        }

#ifdef _WIN16
            // this will trigger the setup main to exec setup32.exe.
    bBoost32 = TRUE;
#endif
    }

//------------------------------------------------------------------
void ProcessInitialize()
    {
    char szDrv[4];
    HWND hwTN;
    char szT1[ _MAX_PATH + 22 ];
    char szTVal[ _MAX_PATH + 2 ];
    char szTIni[ _MAX_PATH + 2 ];
    char szApp[ _MAX_PATH + 22 ];
    char szClass[ 128 ];

    bReinstall = FALSE;
    bNoExtract = FALSE;

        // put the program name in the global buffer.
    if( !bUninstall )
        {
        _fstrcpy( szBuff_Title, szC_ProgName ); 
        }
    else
        {
        _fstrcpy( szBuff_Title, szC_UnProgName ); 
        }

        // set up help message.
    wHelpID = IDM_HELP;

        // set up help key pointers for shared dialogs.
    szHKp_Contents = szHK_Contents;
    szHKp_Main = szHK_Main;
    szHKp_Dir = szHK_Dir;

        // set up default install/uninstall directory.
    if( bUninstall )
        {
        _fstrcpy( szInstallDir, lpProgPath ); 
        }
    else
        {
        bootdrive( (LPSTR)szDrv );
        wsprintf( szInstallDir, "%s%s", szDrv, szDefDir );
        }

        // see if this is an initial extraction install.
    MakePath( lpProgPath, szC_Prefix, szT1 );
    _fstrcat( szT1, ".z" );
    if( QueryFileExists( szT1 ) <= 0 )
        {
            // just do the configuration part.
        bReinstall = TRUE;
        bNoExtract = TRUE;
            // set the current working directory.
        _fstrcpy( szInstallDir, lpProgPath ); 
        }

    if( !bNoExtract )
        {
            // point to the traynote.ini file.
        MakePath( lpWinPath, szC_TrayIni, szTIni );
        
            // make a default app name.
        MakeFileExt( szInstallDir, szC8_ProgName32, szC_ExtEXE, szTVal );

                    // get the app dir from the ini file.
        GetPrivateProfileString( szC_TrayIni, szC_TIApp, szTVal, 
                                            szApp, _MAX_PATH, szTIni );

            // see if they changed class names on us.
        GetPrivateProfileString( szC_TrayIni, szC_TIClass, szC_TIDefClass, 
                                                szClass, 120, szTIni );

            // if window found, shut it down.
        if(( hwTN = FindWindow( szClass, szC_TrayIni )) != NULL )
            {
            _fstrcpy( szT1, szApp );
            _fstrcat( szT1, szC_Space );
            _fstrcat( szT1, szC_Quit );
            WinExec( szT1,  SW_SHOWNOACTIVATE);
            bTrayWasOn = TRUE;
            }
        }
    }

//------------------------------------------------------------------
// Initial PostMessage .
// This can vary the initial action based on command line processing, etc.
//------------------------------------------------------------------
void ProcessStartMessage( )
    {
    if( bUninstall )
        {
        PostMessage( hParent, WM_COMMAND, IDM_UNINTRO, 0L); 
        }
    else
        {
//#ifdef TLOCK
//        if( !bWin95 )
//            {
//            MessageBox( GetFocus(), szEMsg_TL95Only, szBuff_Title, 
//                        MB_OK | MB_ICONHAND );
//
//            PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L); 
//            bComplete = TRUE;
//            return;
//            }
//#endif
        PostMessage( hParent, WM_COMMAND, IDM_INTRO, 0L); 
        }
    }

//------------------------------------------------------------------
// free any process specific memory, etc.
//------------------------------------------------------------------
void ProcessCleanup()
    {
    if( lpDataPath != NULL ) { _ffree( lpDataPath ); lpDataPath = NULL; }
    if( lpFileList != NULL ) { _ffree( lpFileList ); lpFileList = NULL; }
    if( lpProgGroup != NULL ) { _ffree( lpProgGroup ); lpProgGroup = NULL; }

    }

//------------------------------------------------------------------
// output processing.
//------------------------------------------------------------------
void ProcessExitSpecials(  )
    {
    char szT1[ _MAX_PATH + 2 ];
    char szT2[ _MAX_PATH + 2 ];
    char szT3[ _MAX_PATH + 40 ];

    _chdir( szInstallDir );
    _chdrive( szInstallDir[0] - '@' );

    if( bRunCYAOnExit )
        {
        if( bWin95 )
            {
            MakePath( szInstallDir, szC8_ProgName32, szT1 );
            }
        else
            {
            MakePath( szInstallDir, szC8_ProgName16, szT1 );
            }
        _fstrcat( szT1, szExeExt ); 
        WinExec( szT1, SW_SHOW );
        }
    else if( bEvap95 || bExitEvap )
        {
            // in Win95 we can erase ourselves directly.
            // remove exe file.
#ifdef _WIN32
            // HA! Apparently not in 32 bit mode.
        MakePath(lpProgPath, szC_Setup32, szT1 );
        _unlink( szT1 );

        MakePath(lpProgPath, szC_Setup, szT1 );
        _unlink( szT1 );

        _chdir( ".." );
        _fstrcpy( szT1, lpProgPath );
        strip_trailing( szT1, "\\/" );
        _rmdir( szT1 );
#endif

                // spawn the cleanup routine.
        MakePath(lpProgPath, szC_Evap, szT1 );
        if( ExtractFileFromRes( ghInstance, szT1, SETCLEAN ))
            {
            MakePath(lpProgPath, szC_Epif, szT1 );
            ExtractFileFromRes( ghInstance, szT1, EVAPIF );

#ifdef _WIN16
            MakePath( szInstallDir, szC_Setup, szT2 );
#else
            MakePath( szInstallDir, szC_Setup32, szT2 );
#endif
            MakePath(lpProgPath, szC_Evap, szT1 );
            wsprintf( szT3, "%s /X %s", szT1, szT2 );
            WinExec( szT3, SW_HIDE );
            }
        }
    }

//------------------------------------------------------------------
// Dialog return 2way branch interpretation.
//------------------------------------------------------------------
int Decide2( int nRVal, int nOK, int nCancel )
    {
    if( nRVal == SU_OK )
        {
        return nOK;
        }
    else
        {
        return nCancel;
        }
    }
