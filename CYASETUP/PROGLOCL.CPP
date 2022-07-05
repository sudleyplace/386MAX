// $Header:   P:/PVCS/MAX/CYASETUP/PROGLOCL.CPV   1.15   05 May 1997 11:07:54   PETERJ  $
//------------------------------------------------------------------
// proglocl.cpp
// by Peter Johnson
// Version 1.0
// 14 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
// This module should contain all program local functions for
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
#include <statutil.h>
#include <setunzip.h>

 #ifdef _WIN16
    #include <dunzdll.h>
    #include <dzipdll.h>
#else
	#include <new.h>
    #include <dunzip32.h>
    #include <dzip32.h>
#endif

#include "progspec.h"
#include "cya_ids.h"

//------------------------------------------------------------------
// Local Functions
LPSTR GetTextualSid( );
//------------------------------------------------------------------

//------------------------------------------------------------------
// insert ourselves into progman.
//------------------------------------------------------------------
BOOL InstallIcon()
    {
    char szTProg[ _MAX_PATH + 82 ];
    char szT1[ _MAX_PATH + 82 ];

    if( !bReinstall )
        {
            // group request must precede this.
        WritePrivateProfileString( szIniOpt, szC_IniPGroup, lpProgGroup, lpIniFile );

        if( bWin95 )
            {
            MakePath( szInstallDir, szC8_ProgName32, szTProg );
            }
        else
            {
            MakePath( szInstallDir, szC8_ProgName16, szTProg );
            }
    
        _fstrcat( szTProg, szExeExt ); 

            // this first time creates the group...
        if( AddItemToGroup( szTProg, szC_IconTitle, lpProgGroup, FALSE ) )
            {
            SYield(0);
            MessageBox( hParent, szEMsg_AddGroup, szBuff_Title, 
                                        MB_OK | MB_ICONHAND );
            return FALSE;
            }
        SYield(0);
    
            // make setup icon
#ifdef _WIN32
        MakePath( szInstallDir, szC_Setup32, szT1 );
#else
        MakePath( szInstallDir, szC_Setup, szT1 );
#endif
        AddItemToGroup( szT1, szC_SetTitle, lpProgGroup, TRUE );

            // make uninstall icon
#ifdef _WIN32
        MakePath( szInstallDir, szC_Setup32, szT1 );
#else
        MakePath( szInstallDir, szC_Setup, szT1 );
#endif
        _fstrcat( szT1, " /U" ); 
        AddItemToGroup( szT1, szC_UnTitle, lpProgGroup, TRUE );

#ifdef _WIN32
            // add setup to the registry
            // use the string from above.
        if( bWin95 )
            {
            AddUninstall( szC_IconTitle, szC_Prefix, szT1 );
            }
#endif

        if( bAddAuto )
            {
                // szTProg still contains program name.
                // build it into a command line.
            _fstrcat( szTProg, szC_Space ); 
            _fstrcat( szTProg, " /S" );
            AddItemToGroup( szTProg, szC_IconTitle, lpStartup, 
                          ( bTraynote && bWin95 ) ? FALSE : TRUE );
            }
        }
    
    if( bWin95 && !( bWinNT && !bWinNT4Plus ))
        {
        if( bTraynote )
            {
                // traynote name
            MakeFileExt( szInstallDir, szC_Traynote, szC_ExtEXE, szT1 );

                // build it into a command line.
            _fstrcat( szT1, szC_Space ); 
            _fstrcat( szT1, szC_Start ); 
            AddItemToGroup( szT1, szC_ITTraynote, lpStartup, TRUE );
            }
        else
            {
            if( bTrayWasOn )
                {
                    // remove it from startup
                DeleteItemFromGroup(szC_ITTraynote, lpStartup, TRUE );
                }
            }
        }
    else
        {
        if( bWin95 )
            {
                // pre 4 NT does not need these.
                // 32 bit copy did not know this.
            MakeFileExt( szInstallDir, szC_Traynote, (LPSTR)".*", szT1 );
            RemoveFiles( szT1 );
            }
        }

    return TRUE;
    }

//------------------------------------------------------------------
// Do the automatic configuration stuff.
// Also sets up most filenames and directories.
//------------------------------------------------------------------
void AutoConfig()
    {
    HFILE fh;
    char szLTemp[ _MAX_PATH + 2 ];
    char szT1[ _MAX_PATH + 2 ];
#ifdef _WIN32
    LPSTR lpTextSID;
#endif
    
    if( !bWinNT )
        {
            // Make the undo sub-directory.
        MakePath( szInstallDir, szC_UndoDir, szT1 );
        if( RMakeDir( szT1 ))
            {
                // error.
            wsprintf( szTemp, szFmtMsg_BadCreate, szT1 );
            MessageBox( hParent, szTemp, szBuff_Title, MB_OK );
            }
        }

        // make the QCYA.INI filename in the program dir.
    MakePath( szInstallDir, szC_IniName, szT1 );
    lpIniFile = StrMem( szT1 );

        // make the instance .ini filename in the Windows dir.
    MakePath( lpWinPath, szC_InstIni, szT1 );
    lpWIniFile = StrMem( szT1 );

#ifdef _WIN32
    if( bWinNT )
        {
            // get the SID string.
        lpTextSID = GetTextualSid();
        }
    else
        {
        if( bWin95 )
            {
            unsigned long uTLen;
            char szNBuff[ ( _MAX_PATH * 2) + 2 ];
            uTLen = _MAX_PATH * 2;
            GetUserName( szNBuff, &uTLen );
            if( lstrlen( szNBuff ) > 0 )
                {
                lpTextSID = StrMem( szNBuff );
                }
            else
                {
                    // just use the default key
                lpTextSID = StrMem( szC_HK_UDDefault );
                }
            }
        }

#endif

            // first try to get the instance base from the Wini file.
    if( QueryFileExists( lpWIniFile ))
        {
        GetPrivateProfileString( szC_IniInst, szC_IniIName,"", szInst, INSTLEN, lpWIniFile );
        }

    if( lstrlen( szInst ) == 0 )
        {
            // get the next available from the local ini.
        int i;
        WORD wI;
        for( wI = 1, i=1; i != 0; wI++ )
            {
            wsprintf( szInst, "%s%u", szC_Prefix, wI );
            i = GetPrivateProfileInt( szC_IniInst, szInst, 0, lpIniFile );
            if( wI >= 0x9999 )
                {
                SetErrMsg( szEMsg_Limits );
                CrashExit( );
                }
            }
            
            // write cya#=1 to ini files.
        WritePrivateProfileInt( szC_IniInst, szInst, 1, lpIniFile );
        WritePrivateProfileString( szC_IniInst, szC_IniIName, 
                                               szInst, lpWIniFile );
        }

#ifdef _WIN32
    if( bWin95 )
        {
        for( WORD wI = 1; wI < 0x0FFF; wI++ )
            {
            if( wI >= 0x0FFE )
                {
                SetErrMsg( szEMsg_Limits );
                CrashExit( );
                }

            wsprintf( szLTemp, "%s_%x", szInst, wI );

                // make the conditional option section name.
            _fstrcpy( szIniOpt, szLTemp );
            _fstrcat( szIniOpt, (LPSTR)" " );
            _fstrcat( szIniOpt, szC_IniOpt );

                // see if this section exists.
            GetPrivateProfileString( szIniOpt, szC_IniUserSID, "", szT1, 
                                     _MAX_PATH, lpIniFile );

                // if the section does not exist, or 
                // if the user id matches this user. 
            if(( szT1[0] == '\0' ) || (!_fstricmp( szT1, lpTextSID )))
                {
                    // save Composite section as the Instance.
                _fstrcpy( szInst, szLTemp );

                    // if this is a new section attach it to this user.
                if( szT1[0] == '\0' )
                    {
                    WritePrivateProfileString( szIniOpt, szC_IniUserSID, 
                                               lpTextSID, lpIniFile );
                    }
                break;
                }
            }

        if( lpTextSID )
            {
            _ffree( lpTextSID );
            }
        }
    else
        {
            // make the conditional option section name.
        _fstrcpy( szIniOpt, szInst );
        _fstrcat( szIniOpt, (LPSTR)" " );
        _fstrcat( szIniOpt, szC_IniOpt );
        }
#else
        // make the conditional option section name.
    _fstrcpy( szIniOpt, szInst );
    _fstrcat( szIniOpt, (LPSTR)" " );
    _fstrcat( szIniOpt, szC_IniOpt );
#endif

        // make the conditional Directory section name.
    _fstrcpy( szIniDir, szInst );
    _fstrcat( szIniDir, (LPSTR)" " );
    _fstrcat( szIniDir, szC_IniDataDir );

        // get the data directory from the ini file or make one up.
    if( QueryFileExists( lpIniFile ))
        {
        GetPrivateProfileString( szIniDir, szC_IniDataDir,"", szT1, 
                                        sizeof(szT1) - 1, lpIniFile );
        if( lstrlen( szT1 ) != 0 )
            {
            lpDataPath = StrMem( szT1 );
            }
        else
            {
            MakePath( szInstallDir, szC_DataDir, szT1 );
            lpDataPath = StrMem( szT1 );
            WritePrivateProfileString(szIniDir, szC_IniDataDir, 
                                        lpDataPath, lpIniFile );
            }
        }
    else
        {
        MakePath( szInstallDir, szC_DataDir, szT1 );
        lpDataPath = StrMem( szT1 );
        WritePrivateProfileString(szIniDir, szC_IniDataDir, 
                                    lpDataPath, lpIniFile );
        }
        
        // make the data directory if it doesn't exist.
    if( QueryDirExists( lpDataPath )  == 0 )
        {
        if ((_mkdir( lpDataPath ) == -1) && (_doserrno != 5)) 
            {
            SetErrMsg( szEMsg_DataDir );
            CrashExit( );
            }
        }

        // save the user info in the ini files.
    if( !bReinstall )
        {
        WritePrivateProfileString( szIniOpt, szC_IniUser, szUserName, lpIniFile );
        WritePrivateProfileString( szIniOpt, szC_IniUOrg, szUserOrg, lpIniFile );
        WritePrivateProfileString( szIniOpt, szC_IniUSN,  szSerialNumber, lpIniFile );

#ifndef TLOCK
        MakePath( lpProgPath, szC_RegIni, szT1 );
        WritePrivateProfileString( szC_IniReg, szC_IniUser, szUserName, szT1 );
        WritePrivateProfileString( szC_IniReg, szC_IniUOrg, szUserOrg, szT1 );
        WritePrivateProfileString( szC_IniReg, szC_IniUSN,  szSerialNumber, szT1 );
#endif
        }

        // set a few defaults into the ini file.
            // save the registry.
    WritePrivateProfileString( szIniOpt, szC_IniSaveReg, "1", lpIniFile );

            // this is actually capture on restore.
    WritePrivateProfileString( szIniOpt, szC_IniUndo, "1", lpIniFile );

            // this is the real undo
    WritePrivateProfileString( szIniOpt, szC_RealIniUndo, 
                               (bWinNT) ? "0" : "1", lpIniFile );

            // this is CYA to Tray.
    WritePrivateProfileString( szIniOpt, szC_IniETBar, 
                ( bTraynote && bWin95 ) ? "1" : "0", lpIniFile );
    
        // Now we make the default list of files to save.
    MakePath( lpDataPath, szInst, szT1 );
    _fstrcat( szT1, szLstExt );
    lpFileList = StrMem( szT1 );
        
        // don't overwrite an existing file list.
    if( QueryFileExists( lpFileList )  == 0 )
        {
            // make the default file.
            // Get the boot drive;
        bootdrive( szLTemp );
                
            // open de file.
        if (( fh = _lcreat( lpFileList, 0 )) == HFILE_ERROR ) 
            {
            SetErrMsg( szEMsg_FOpen );
            CrashExit( );
            }

        if( !bWinNT )
            {
            MakePath( szLTemp, szC_Autoexec, szT1 );
            if( QueryFileExists( szT1 ) != 0 )
                {
                sswrite( fh, szT1, lstrlen( szT1 ));
                sswrite( fh, "\r\n", 2);
                }

            MakePath( szLTemp, szC_ConfigSys, szT1 );
            if( QueryFileExists( szT1 ) != 0 )
                {
                sswrite( fh, szT1, lstrlen( szT1 ));
                sswrite( fh, "\r\n", 2);
                }
            }
        else
            {
            MakePath( lpWinPath, szC_Sys32, szT1 );
            MakePath( szT1, szC_AutoexecNT, szT1 );
            if( QueryFileExists( szT1 ) != 0 )
                {
                sswrite( fh, szT1, lstrlen( szT1 ));
                sswrite( fh, "\r\n", 2);
                }

            MakePath( lpWinPath, szC_Sys32, szT1 );
            MakePath( szT1, szC_ConfigNT, szT1 );
            if( QueryFileExists( szT1 ) != 0 )
                {
                sswrite( fh, szT1, lstrlen( szT1 ));
                sswrite( fh, "\r\n", 2);
                }
            }
            
        MakePath( lpWinPath, szC_WinIni, szT1 );
        if( QueryFileExists( szT1 ) != 0 )
            {
            sswrite( fh, szT1, lstrlen( szT1 ));
            sswrite( fh, "\r\n", 2);
            }
            
        MakePath( lpWinPath, szC_SystemIni, szT1 );
        if( QueryFileExists( szT1 ) != 0 )
            {
            sswrite( fh, szT1, lstrlen( szT1 ));
            sswrite( fh, "\r\n", 2);
            }
        _lclose(fh);
        }
    }

//------------------------------------------------------------------
// Move local files to appropriate shared directories.
//------------------------------------------------------------------
BOOL MoveLocalToShared()
    {
    BOOL bRet = TRUE;
    int nVCRet;
    UINT uCurLen = _MAX_PATH;
    UINT uDestLen = _MAX_PATH;
    char lpCurDirBuff[ _MAX_PATH + 2 ];
    char lpDestDirBuff[ _MAX_PATH + 2 ];
    char lpTL[ _MAX_PATH + 2 ];

    if( bWin95 )
        {
#ifdef TLOCK
            // move the 32 bit timelock file to the windows\system directory.
        uCurLen = _MAX_PATH;
        uDestLen = _MAX_PATH;
        nVCRet = VerChkCopyFiles( szC_TL32DLL, szInstallDir, 
                              szC_TL32DLL, lpSysPath,
                              lpSysPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
        
        if( nVCRet == VCC_SUCCESS )
            {
                // remove the original file.
            MakePath( szInstallDir, szC_TL32DLL, lpTL );
            _unlink( lpTL ); 
            }
#endif

            // move the 32 bit zip files to the windows directory.
        uCurLen = _MAX_PATH;
        uDestLen = _MAX_PATH;
        nVCRet = VerChkCopyFiles( szC_Zip32DLL, szInstallDir, 
                              szC_Zip32DLL, lpWinPath,
                              lpWinPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
        
        if( nVCRet == VCC_SUCCESS )
            {
                // remove the original file.
            MakePath( szInstallDir, szC_Zip32DLL, lpTL );
            _unlink( lpTL );
            }

#ifdef _WIN16
        uCurLen = _MAX_PATH;
        uDestLen = _MAX_PATH;
        nVCRet = VerChkCopyFiles( szC_Unzip32DLL, szInstallDir, 
                              szC_Unzip32DLL, lpWinPath,
                              lpWinPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );

        if( nVCRet == VCC_SUCCESS )
            {
                // remove the original file.
            MakePath( szInstallDir, szC_Unzip32DLL, lpTL );
            _unlink( lpTL ); 
            }
#endif
        }
    else
        {
#ifdef TLOCK
            // move the 16 bit Timelock files to the windows directory.
        uCurLen = _MAX_PATH;
        uDestLen = _MAX_PATH;
        nVCRet = VerChkCopyFiles( szC_TL16DLL, szInstallDir, 
                              szC_TL16DLL, lpSysPath,
                              lpSysPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
        
            // remove the original file.
        MakePath( szInstallDir, szC_TL16DLL, lpTL );
        _unlink( lpTL ); 
#endif
            // move the 16 bit zip files to the windows directory.
        uCurLen = _MAX_PATH;
        uDestLen = _MAX_PATH;
        nVCRet = VerChkCopyFiles( szC_ZipDLL, szInstallDir, 
                              szC_ZipDLL, lpWinPath,
                              lpWinPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );

        if( nVCRet == VCC_SUCCESS )
            {
                // remove the original file.
            MakePath( szInstallDir, szC_ZipDLL, lpTL );
            _unlink( lpTL ); 
            }
        }

    return TRUE;
    }

//------------------------------------------------------------------
// Traynote config.
//------------------------------------------------------------------
void TraynoteConfig( )
    {
    HWND hwTN;
    char szTIni[ _MAX_PATH + 2 ];
    char szTVal[ _MAX_PATH + 2 ];
    char szClass[ 128 ];
    char szApp[ _MAX_PATH + 22 ];
    char szT1[ _MAX_PATH + 22 ];
    
        // Set the proper taskbar in CYA?.INI.
    WritePrivateProfileString( szIniOpt, szC_IniETBar, (bTraynote) ? "1" : "0", lpIniFile );

        // point to the traynote.ini file.
    MakePath( lpWinPath, szC_TrayIni, szTIni );

    if( bTraynote )
        {
            // add [CYA] ToolTip="Qualitas C.Y.A."
        WritePrivateProfileString( szC_TISecCYA, szC_TITTip, szC_TTStr, szTIni );

            // add IconFile=CYA32.exe
        MakeFileExt( szInstallDir, szC8_ProgName32, szC_ExtEXE, szTVal );
        WritePrivateProfileString( szC_TISecCYA, szC_TIIconFile, szTVal, szTIni );

            // LeftClick is the same as IconFile for now.
        WritePrivateProfileString( szC_TISecCYA, szC_TILeft, szTVal, szTIni );

            // Right click.
        _fstrcpy( szT1, szTVal );
        _fstrcat( szT1, " /H");
        WritePrivateProfileString( szC_TISecCYA, szC_TIRight, szT1, szTIni );
    
            // add [TRAYNOTE.INI] App=\traynote.exe
        MakeFileExt( szInstallDir, szC_Traynote, szC_ExtEXE, szTVal );
        WPPS_IfEmpty( szC_TrayIni, szC_TIApp, szTVal, szTIni );
        }

                // get the app dir from the ini file.
    GetPrivateProfileString( szC_TrayIni, szC_TIApp, szTVal, 
                                        szApp, _MAX_PATH, szTIni );

#ifdef _WIN32
        // Traynote might have switched to long filenames.
    MyGetShortPathName( szApp, szApp, _MAX_PATH );
#endif

        // see if they changed class names on us.
    GetPrivateProfileString( szC_TrayIni, szC_TIClass, szC_TIDefClass, 
                                            szClass, 120, szTIni );

        // if no window, we must start it.
    if(( hwTN = FindWindow( szClass, szC_TrayIni )) == NULL )
        {
        if( bTraynote )
            {
            _fstrcpy( szT1, szApp );
            _fstrcat( szT1, szC_Space );
            _fstrcat( szT1, szC_Start );

            _chdir( szInstallDir );
            _chdrive( szInstallDir[0] - '@' );
            WinExec( szT1,  SW_SHOWNOACTIVATE);
            }
        }
    else
        {
        if( bTraynote )
            {
                // traynote is already running. Send "New".
            _fstrcpy( szT1, szApp );
            _fstrcat( szT1, szC_Space );
            _fstrcat( szT1, szC_New );
            _fstrcat( szT1, szC_Space );
            _fstrcat( szT1, szC_TISecCYA );
            _chdir( szInstallDir );
            _chdrive( szInstallDir[0] - '@' );
            WinExec( szT1,  SW_SHOWNOACTIVATE);
            }
        else
            {
                // turn it off
            _fstrcpy( szT1, szApp );
            _fstrcat( szT1, szC_Space );
            _fstrcat( szT1, szC_Quit );
            _chdir( szInstallDir );
            _chdrive( szInstallDir[0] - '@' );
            WinExec( szT1,  SW_SHOWNOACTIVATE);
                // remove it from startup
            DeleteItemFromGroup(szC_ITTraynote, lpStartup, TRUE );
            }
        }
    }

//------------------------------------------------------------------
BOOL ValidSernum( LPSTR szSerial )
    {
    char szSN[ SERNUMLEN + 2 ];

        // pack and trap all zero.
    if( !SNPackStr( szSN, szSerial ))
        {
        return FALSE;
        }
        
        // the simplest of tests.
        // '6' is the magic number for CYA.
    if( (12 != lstrlen( szSN )) || ( szSN[0] != '6' ))
        {
        return FALSE;
        }
        
    return TRUE;
    }

//------------------------------------------------------------------
// retrieve prior user info.
// returns true if it exists.
//------------------------------------------------------------------
BOOL CheckUser()
    {
    char szT1[ _MAX_PATH + 2 ];
    char szTInst[ _MAX_PATH + 2 ];

        // make the qcyareg.ini filename on the source dir.
    MakePath( lpProgPath, szC_RegIni, szT1 );
    if( QueryFileExists( szT1 ) > 0 )
        {
        GetPrivateProfileString( szC_IniReg, szC_IniUser, "", szUserName, 
                                sizeof( szUserName) - 1, szT1 );

        GetPrivateProfileString( szC_IniReg, szC_IniUOrg, "", szUserOrg, 
                                sizeof( szUserOrg ) - 1, szT1 );

        GetPrivateProfileString( szC_IniReg, szC_IniUSN,  "", szSerialNumber, 
                                sizeof( szSerialNumber) - 1, szT1 );

        if( lstrlen( szSerialNumber ))
            {
            return TRUE;
            }
        else
            {
                // no serial number, ask again.
            return FALSE;
            }
        }
    else
        {
            // make the instance .ini filename in the Windows dir.
        MakePath( lpWinPath, szC_InstIni, szT1 );

                // first try to get the instance base from the Wini file.
        if( QueryFileExists( szT1 ))
            {
            GetPrivateProfileString( szC_IniInst, szC_IniIName,"", szTInst, 
                                                        INSTLEN, szT1 );
            }
        else
            {
                // no instance file.
            return FALSE;
            }
        
        if( bWinNT )
            {
                // FIXME - Hard wired to one.
            wsprintf( szTemp, "%s_%x", szTInst, 1 );
            _fstrcpy( szTInst, szTemp );
            }
    
            // make the conditional option section name.
        _fstrcpy( szIniOpt, szTInst );
        _fstrcat( szIniOpt, (LPSTR)" " );
        _fstrcat( szIniOpt, szC_IniOpt );

        MakePath( szInstallDir, szC_IniName, szT1 );
        if( QueryFileExists( szT1 ) > 0 )
            {
            GetPrivateProfileString( szIniOpt, szC_IniUser, "", szUserName, 
                                    sizeof( szUserName) - 1, szT1 );

            GetPrivateProfileString( szIniOpt, szC_IniUOrg, "", szUserOrg, 
                                    sizeof( szUserOrg ) - 1, szT1 );

            GetPrivateProfileString( szIniOpt, szC_IniUSN,  "", szSerialNumber, 
                                    sizeof( szSerialNumber) - 1, szT1 );
            }
        }
    return FALSE;
    }


//------------------------------------------------------------------
// Main uninstall function.
//------------------------------------------------------------------
void Do_Uninstall()
    {
    HWND hWnd;
    BOOL bMulti=FALSE;
    BOOL bTrayInWin=FALSE;
    BOOL bTrayInApp=FALSE;
    LPSTR lpBuff;
    int nPGCount;
    char szUnFile[ 20 ];
    char szT1[ _MAX_PATH + 2 ];
    char szT2[ _MAX_PATH + 2 ];

        // check to see if CYA is running.
    if(( hWnd = FindWindow( szSSDlgClass, NULL)) != NULL )
        {
        MessageBox( hParent, szEMsg_Running, szBuff_Title, MB_OK | MB_ICONHAND );
        return;
        }

    if( bWin95 )
        {
#ifdef _WIN32
            // remove setup from the registry
        RemoveUninstall( szC_Prefix );
#endif
        }

        // make the QCYA.INI filename.
    MakePath( szInstallDir, szC_IniName, szT1 );
    lpIniFile = StrMem( szT1 );

        // Make the undo sub-directory.
    MakePath( szInstallDir, szC_UndoDir, szT1 );
    lpUndoPath = StrMem( szT1 );

        // make the instance .ini filename in the Windows dir.
    MakePath( lpWinPath, szC_InstIni, szT1 );
    lpWIniFile = StrMem( szT1 );

            // first try to get the instance base from the Wini file.
    if( QueryFileExists( lpWIniFile ) )
        {
        GetPrivateProfileString( szC_IniInst, szC_IniIName,"", 
                                 szInst, INSTLEN, lpWIniFile );
        }
    else
        {
            // not there, just use cya1.
        wsprintf( szInst, "%s%u", szC_Prefix, 1 );
        }
    
        // make the conditional option section name.
    if( bWinNT )
        {
            // FIXME - Hard wired to one.
        wsprintf( szTemp, "%s_%x", szInst, 1 );
        _fstrcpy( szInst, szTemp );
        }

        // make the conditional option section name.
    _fstrcpy( szIniOpt, szInst );
    _fstrcat( szIniOpt, (LPSTR)" " );
    _fstrcat( szIniOpt, szC_IniOpt );

        // make the conditional Directory section name.
    _fstrcpy( szIniDir, szInst );
    _fstrcat( szIniDir, (LPSTR)" " );
    _fstrcat( szIniDir, szC_IniDataDir );

        // get the data directory.
    if( GetPrivateProfileString( szIniDir, szC_IniDataDir,"", szT1, 
                                 sizeof(szT1) - 1, lpIniFile ))
        {
        lpDataPath = StrMem( szT1 );
        }
    else
        {
            // can't really erase the data if it wasn't specified.
        bUIData = FALSE;
        MakePath( szInstallDir, szC_DataDir, szT1 );
        lpDataPath = StrMem( szT1 );
        }

        // get the program group name.
    GetPrivateProfileString( szIniOpt, szC_IniPGroup, szC_DefaultGroup, 
                                szT1, sizeof( szT1 ) - 2, lpIniFile );
    lpProgGroup = StrMem( szT1 );
    
        // see if there is more than one instance installed.
    if( GetPrivateProfileString( szC_IniInst, NULL, "", szT1, 
                                 sizeof(szT1) - 1, lpIniFile ))
        {
        LPSTR lpSZ = szT1;          // point to szT1.
        lpSZ += lstrlen( szT1 );    // point to null.
        if( *(lpSZ+1) == '\0' )
            {
                // there is only one instance.
            bUIInstOnly = FALSE;
            bUIProg = TRUE;
            bUIData = TRUE;
            bUIUndo = TRUE;
            }
        else
            {
                // multiple instances.
            bUIInstOnly = TRUE;
            bUIData = TRUE;
            bUIProg = FALSE;
            bUIUndo = TRUE;
                // remove us from the ini file.
            WritePrivateProfileString( szC_IniInst, szInst, NULL, lpIniFile );
            }
        }
    else
        {
            // improper installation, let's waste it totally.
        bUIInstOnly = FALSE;
        bUIProg = TRUE;
        bUIData = TRUE;
        bUIUndo = TRUE;
        }

        // remove instance data.
    if( bUIInstOnly )
        {
        MessageBox( hParent, szEMsg_InstOnly, szBuff_Title, MB_OK | MB_ICONHAND );

        WritePrivateProfileString( szIniOpt, NULL, NULL, lpIniFile );
        WritePrivateProfileString( szIniDir, NULL, NULL, lpIniFile );
        }

        // remove data files.
    if( bUIData )
        {
        MakePath(lpDataPath, szInst, szT1 );
        _fstrcat( szT1, ".*" );
        RemoveFiles( szT1 );
        if( !bUIInstOnly )
            {
            _rmdir( lpDataPath );
            }
        }

        // remove undo files.
    if( bUIUndo )
        {
        if( lpUndoPath )
            {
            if( QueryDirExists( lpUndoPath ) > 0 )
                {
                MakePath(lpUndoPath, szInst, szT1 );
                _fstrcat( szT1, ".*" );
                RemoveFiles( szT1 );

                        // make the undo.bat name too.
                wsprintf( szUnFile, "%s%s%s", szC_Undo, &szInst[3], szC_ExtBAT );
                MakePath(lpUndoPath, szUnFile, szT1 );
                _unlink( szT1 );

                if( !bUIInstOnly )
                    {
                    _rmdir( lpUndoPath );
                    }
                }
            }
        }

    DeleteItemFromGroup( szC_IconTitle, lpProgGroup, FALSE );
    SYield(0);
    DeleteItemFromGroup( szC_SetTitle, lpProgGroup, FALSE );
    SYield(0);
    DeleteItemFromGroup( szC_UnTitle, lpProgGroup, TRUE );
    SYield(0);

    if(( nPGCount = GetGroupItemList( lpProgGroup, &lpBuff )) < 1 )
        {
        DeleteGroup( lpProgGroup );
        SYield(0);
        }
    if( lpBuff != NULL )
        {
        _ffree( lpBuff );
        }
    
    SYield(0);
    DeleteItemFromGroup( szC_IconTitle, lpStartup, TRUE );
    SYield(0);
    
        // remove qcyainst.ini
    _unlink( lpWIniFile );

        // remove program files.
    if( bUIProg && ( !bUIInstOnly ))
        {
            // remove qcya.ini
        _unlink( lpIniFile );

            // remove help file.
        MakePath(lpProgPath, "CYA*.hlp", szT1 );
        RemoveFiles( szT1 );

            // remove readme file.
        MakePath(lpProgPath, "readme", szT1 );
        RemoveFiles( szT1 );

            // remove setup help file.
        MakePath(lpProgPath, "setup.hlp", szT1 );
        _unlink( szT1 );

            // remove exe file.
        MakePath(lpProgPath, "CYA*.exe", szT1 );
        RemoveFiles( szT1 );
    
#ifdef TLOCK
        MakePath(lpProgPath, "CYATL.TSF", szT1 );
        RemoveFiles( szT1 );
#endif
        if( !bUIInstOnly  && bWin95 )
            {
#ifdef _WIN32
            if( bWin95 )
                {
                HANDLE fh;
                WIN32_FIND_DATA fd;
                
                    // remove help file index.
                MakePath(lpProgPath, "CYAHELP.GID", szT1 );
                if(( fh = FindFirstFile( szT1, &fd )) != INVALID_HANDLE_VALUE )
                    {
                    SetFileAttributes( szT1, FILE_ATTRIBUTE_NORMAL );
                    _unlink( szT1 );
                    }

                    // remove setup help file index.
                MakePath(lpProgPath, "setup.gid", szT1 );
                if(( fh = FindFirstFile( szT1, &fd )) != INVALID_HANDLE_VALUE )
                    {
                    SetFileAttributes( szT1, FILE_ATTRIBUTE_NORMAL );
                    _unlink( szT1 );
                    }
                }
#endif
            bEvap95 = TRUE;
            }
        else
            {
            bExitEvap = TRUE;
            }
        }
        
    if( bWin95 && !( bWinNT && !bWinNT4Plus ))
        {
            // look for traynote and see if 
            // they want it removed as well.
        MakePath(lpProgPath, szC_TrayExe, szT2 );
        if( QueryFileExists( szT2 ) > 0 )
            {
            bTrayInApp = TRUE;
            }
        else
            {
            MakePath(lpWinPath, szC_TrayExe, szT2 );
            if( QueryFileExists( szT2 ) > 0 )
                {
                bTrayInWin = TRUE;
                }
            }
                
        if( bTrayInWin || bTrayInApp )
            {
            char szT3[ _MAX_PATH + 40 ];
            char szClass[ 128 ];
            int nMB=IDNO;

            MakePath(lpWinPath, szC_TrayIni, szT1 );
            GetPrivateProfileString( szC_TrayIni, szC_TIApp,
                          "", szT2, sizeof(szT2) - 1, szT1 );
#ifdef _WIN32
                // Traynote might have switched to long filenames.
            MyGetShortPathName( szT2, szT2, _MAX_PATH );
#endif

            GetPrivateProfileString( szC_TrayIni, szC_TIClass,
                    "", szClass, sizeof(szClass) - 1, szT1 );

            nMB = MessageBox( hParent, szMsg_TrayFound, szBuff_Title, 
                                            MB_YESNO | MB_ICONQUESTION );
            if( nMB == IDYES )
                {
                    // remove traynote.txt file.
                MakePath(lpProgPath, "traynote.txt", szT1 );
                _unlink( szT1 );

                if(( hWnd = FindWindow( szClass, szC_TrayIni)) 
                                                     != NULL )
                    {
                    UINT nCount = 64000;
                        // build a QUIT command.
                    _fstrcpy( szT3, szT2 );
                    _fstrcat( szT3, szC_Space );
                    _fstrcat( szT3, szC_Quit );
                    WinExec( szT3,  SW_HIDE );
                        // wait for the window to close

                    while ( nCount && 
                          ( hWnd = FindWindow( szClass, szC_TrayIni)) 
                                                            != NULL )
                        {
                        nCount--;
                        SYield(0);
                        }
                    }
                
                SYield(0);
                if( bTrayInApp )
                    {
                    MakePath(lpProgPath, szC_TrayExe, szT2 );
                        // remove the exe file.
                    RemoveFiles( szT2 );
                    }
                else if( bTrayInWin )
                    {
                    MakePath(lpWinPath, szC_TrayExe, szT2 );
                        // remove the exe file.
                    RemoveFiles( szT2 );
                    }
                    // remove the ini file.
                MakePath(lpWinPath, szC_TrayIni, szT1 );
                RemoveFiles( szT1 );
                            
                    // also remove it from startup
                DeleteItemFromGroup(szC_ITTraynote, lpStartup, TRUE );
                }
            else
                {
                    // build a close command.
                _fstrcpy( szT3, szT2 );
                _fstrcat( szT3, szC_Space );
                _fstrcat( szT3, szC_Close );
                _fstrcat( szT3, szC_Space );
                _fstrcat( szT3, szC_TISecCYA );
                WinExec( szT3,  SW_HIDE );
                        
                    // blow away the section.
                WritePrivateProfileString( szC_TISecCYA, NULL, NULL, 
                                                            szT1 );
                }
            }
        }
    }

//------------------------------------------------------------------

//------------------------------------------------------------------
#ifdef _WIN32
//------------------------------------------------------------------
// Return a pointer to a malloc'ed buffer containing a Text SID.
// Caller must free the buffer.
// This is only for use in Windows NT.
//------------------------------------------------------------------
LPSTR GetTextualSid( )
    {
    PSID_IDENTIFIER_AUTHORITY psia;
    DWORD dwSubAuthorities;
    DWORD dwSidRev=SID_REVISION;
    DWORD dwCounter;
    DWORD dwSidSize;
    HANDLE hProcess, hAccessToken;
    UCHAR InfoBuffer[1000];
    PTOKEN_USER pTokenUser = (PTOKEN_USER)InfoBuffer;
    DWORD dwInfoBufferSize;
    LPSTR TextualSid;
   
    hProcess = GetCurrentProcess();

    OpenProcessToken( hProcess,TOKEN_READ,&hAccessToken );

        // FIXME - Dynamic Alloc of InfoBuffer.
    GetTokenInformation( hAccessToken,TokenUser,InfoBuffer,
                        1000, &dwInfoBufferSize );

        // test if Sid is valid.
    if( !IsValidSid( pTokenUser->User.Sid ))
        {
        return (LPSTR)NULL;
        }
 
        // obtain SidIdentifierAuthority
    psia = GetSidIdentifierAuthority( pTokenUser->User.Sid );
 
        // obtain sidsubauthority count
    dwSubAuthorities = *GetSidSubAuthorityCount( pTokenUser->User.Sid );
 
        // compute buffer length
        // S-SID_REVISION + identifierauthority + subauthorities + NULL
    dwSidSize = ( 15 + 12 + (12 * dwSubAuthorities) + 2 ) * sizeof( TCHAR );
    
        // create a string buffer.
    TextualSid = (LPSTR)GetMem( dwSidSize );
    
        // prepare S-SID_REVISION-
    dwSidSize = wsprintf( TextualSid, TEXT("S-%lu-"), dwSidRev );

        // prepare SidIdentifierAuthority
    if ( (psia->Value[0] != 0) || (psia->Value[1] != 0) )
        {
        dwSidSize += wsprintf(TextualSid + lstrlen(TextualSid),
                    TEXT("0x%02hx%02hx%02hx%02hx%02hx%02hx"),
                    (USHORT)psia->Value[0],
                    (USHORT)psia->Value[1],
                    (USHORT)psia->Value[2],
                    (USHORT)psia->Value[3],
                    (USHORT)psia->Value[4],
                    (USHORT)psia->Value[5]);
        }
    else
        {
        dwSidSize += wsprintf(TextualSid + lstrlen(TextualSid),
                    TEXT("%lu"),
                    (ULONG)(psia->Value[5]      )   +
                    (ULONG)(psia->Value[4] <<  8)   +
                    (ULONG)(psia->Value[3] << 16)   +
                    (ULONG)(psia->Value[2] << 24)   );
        }
 
        // loop through SidSubAuthorities
    for( dwCounter = 0 ; dwCounter < dwSubAuthorities ; dwCounter++ )
        {
        dwSidSize += wsprintf( TextualSid + dwSidSize, TEXT("-%lu"),
                             *GetSidSubAuthority( pTokenUser->User.Sid, 
                                                  dwCounter) );
        }
    return TextualSid;
    }
#endif
