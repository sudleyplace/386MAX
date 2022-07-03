// $Header:   P:/PVCS/MAX/CYASETUP/PSDIALOG.CPV   1.13   05 May 1997 11:07:56   PETERJ  $
//------------------------------------------------------------------
// psdialog.cpp
// by Peter Johnson
// Version 1.0
// 6 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
// This module contains dialog procs for cyasetup.
//------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <commdlg.h>
#include <direct.h>
#include <malloc.h>
#include <time.h>
#include <ctype.h>
#include <ddeml.h>
#include <dos.h>
#include <io.h>
#include <ctl3d.h>
#include <setglob.h>
#include <statutil.h>

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

#include <setunzip.h>

//------------------------------------------------------------------
    // list of files to back up.
typedef struct _tagCFILELIST
    {
    struct _tagCFILELIST FAR *prev;
    struct _tagCFILELIST FAR *next;
    BOOL bChanged;
    LPSTR lpRealName;
    LPSTR lpBackName;
    LPSTR lpDiffName;
    } CFILELIST, FAR *LPCFILELIST; 

    // Config file list.
LPCFILELIST lpCfgAnchor DEFVAL( NULL );

#define MAXSCHED     99
#define MINSCHED      1
    
    // local functions.
void WriteFileList( LPCFILELIST FAR *lpA );
void LoadFileList( LPCFILELIST FAR *lpA );
void KillFileList( LPCFILELIST FAR *lpA );
BOOL ScanFLForDups( LPCFILELIST FAR *lpA, LPSTR szName );
int MakeValidPath( LPSTR lpDir );
int ScrollNumWheel( HWND hw, int nID, int nCode, int nMin, int nMax, 
                                        int nBLen, LPSTR lpBuf );
void CheckEdLimit( HWND hw, int nID, int FAR *nVal, int nMin, int nMax ); 

extern DWORD dwDDEInst;

//------------------------------------------------------------------

//------------------------------------------------------------------
// Welcome dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 WelcomeDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_Main ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    if( bReinstall )
                        {
                        PostMessage( hParent, WM_COMMAND, IDM_AUTOCONFIG, 0L);
                        }
                    else
                        {
                        PostMessage( hParent, WM_COMMAND, IDM_DIRECTORY, 0L);
                        }
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }

//------------------------------------------------------------------
// TrayAsk dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 TrayAskDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                       // the yes branch.
                    bTraynote = TRUE;
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;
                case IDCANCEL:
                       // the no branch.
                    bTraynote = FALSE;
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;
                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, 
                                   (DWORD)(( LPSTR ) szHK_Traynote ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
                // cancel and ok both continue.
            if( !bReinstall )
                {
                PostMessage( hParent, WM_COMMAND, IDM_PGROUP, 0L);
                }
            else
                {
                PostMessage( hParent, WM_COMMAND, IDM_ICONTOGROUP, 0L);
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }

//------------------------------------------------------------------
// Directory dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 DirDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
	{
	WORD id;
	WORD cmd;
	HWND hChild;
	BOOL bSameDrive;
	int nMBRet;
	int i;
    BOOL bDSDone;
	long lDiskSpace;
	long lWinSpace;
	static WORD wRet;
	OPENFILENAME ofn;
	char szFilter[ _MAX_PATH + 2 ];
	char szT1[ _MAX_PATH + 2 ];

	CrackIt( wParam, lParam, &id, &cmd, &hChild );
	switch (uMsg) 
		{
		case WM_INITDIALOG:
			wRet = 0;
			CenterWindow( hDlg );

			SetDlgItemText(hDlg, IDC_INSTDIR, szInstallDir );
            ShowWindow( GetDlgItem( hDlg, IDC_INSTDIR ), SW_SHOW );
            ShowWindow( GetDlgItem( hDlg, IDC_STATDIR ), SW_HIDE );
            SendDlgItemMessage( hDlg, IDC_INSTDIR, EM_LIMITTEXT, 
                                (WPARAM)( _MAX_PATH ), 0L );
            SendDlgItemMessage(hDlg, IDC_INSTDIR, EM_SETSEL, 
                                    0, MAKELONG( 0, -1 ));
            SetFocus( GetDlgItem( hDlg, IDC_INSTDIR ));
			return 0;

		case WM_COMMAND:
			switch( id ) 
				{
				case IDOK:
					int nPRet;
					wRet = id;
					bSameDrive = FALSE;
						// get what the user typed into the box.
					GetDlgItemText(hDlg, IDC_INSTDIR, szInstallDir, _MAX_PATH);
					nPRet = MakeValidPath( szInstallDir );
					if( nPRet > 0 )
						{
						SetDlgItemText(hDlg, IDC_INSTDIR, szInstallDir );
						}

					if( nPRet < 0 )
						{
						char szT1[ 512 ];
						wsprintf( szT1, szFmtMsg_BadDir, szInstallDir );
						MessageBox( hDlg, szT1, szBuff_Title, 
												MB_ICONHAND | MB_OK );
						return 0;
						}

                    lDiskSpace = FreeDiskSpace( (char)szInstallDir[0] );
                    lWinSpace = FreeDiskSpace( (char)lpWinPath[0] );

                        // Handle invalid drive.
                    if( lDiskSpace == 0L )
                        {
                        char szT1[ 512 ];
                        char szDrive[ _MAX_DRIVE ];
                        wsprintf( szT1, szFmtMsg_BadDisk, szInstallDir[0] );
                        MessageBox( hDlg, szT1, szBuff_Title, 
                                                MB_ICONHAND | MB_OK );
                        bootdrive( szDrive );
                        szInstallDir[0] = szDrive[0];
                        SetDlgItemText(hDlg, IDC_INSTDIR, szInstallDir );
                        SendDlgItemMessage(hDlg, IDC_INSTDIR, EM_SETSEL, 
                                                0, MAKELONG( 0, -1 ));
                        SetFocus( GetDlgItem( hDlg, IDC_INSTDIR ));
                        return 0;
                        }

                        // check disk space available.
                        // Note! Win3.1 and Win95 report less than zero for
                        // drives > 2 GB. ( a Microsoft Feature! )
                    do
                        {
                        bDSDone = TRUE;
                        if( szInstallDir[0] == lpWinPath[0] )
                            {
                            bSameDrive = TRUE;
                            lDiskSpaceReq += lWinSpaceReq;
                            }
	
                        if( lDiskSpaceReq > lDiskSpace )
                            {
                            char szT1[ 512 ];
                            int nMBRet;
                            if( bSameDrive )
                                {
                                wsprintf( szT1, szFmtMsg_BadSame, szInstallDir[0],
                                                        lDiskSpaceReq / 1000 );
                                }
                            else
                                {
                                wsprintf( szT1, szFmtMsg_BadSize, szInstallDir[0],
                                                      lDiskSpaceReq / 1000, 
                                                      lWinSpaceReq / 1000 );
                                }

                            nMBRet = MessageBox( hDlg, szT1, szBuff_Title, 
                                            MB_ICONHAND | MB_ABORTRETRYIGNORE );
                            if( nMBRet == IDABORT )
                                {
                                return 0;
                                }
                            else if ( nMBRet == IDRETRY )
                                {
                                bDSDone = FALSE;
                                continue;
                                }
                            }
					
                        if( lWinSpaceReq > lWinSpace && (!bSameDrive))
                            {
                            char szT1[ 512 ];
                            int nMBRet;
                            wsprintf( szT1, szFmtMsg_BadSize, lpWinPath[0],
                                                  lDiskSpaceReq / 1000, 
                                                  lWinSpaceReq / 1000 );

                            nMBRet = MessageBox( hDlg, szT1, szBuff_Title, 
                                            MB_ICONHAND | MB_ABORTRETRYIGNORE );

                            if( nMBRet == IDABORT )
                                {
                                return 0;
                                }
                            else if ( nMBRet == IDRETRY )
                                {
                                bDSDone = FALSE;
                                continue;
                                }
                            }
                        }while( !bDSDone );
					
						// if it already exists, continue on.
					if( QueryDirExists( szInstallDir ) > 0 )
						{
#ifdef _WIN32
                            // get past the long file names...for now.
                        if( bWin95 )
                            {
                            MyGetShortPathName( szInstallDir, szInstallDir, _MAX_PATH );
                            }
#endif
						DestroyWindow( hDlg );	  
						return 0;
						}

						// if it's a root dir, just continue.
					if( ( lstrlen( szInstallDir ) < 4 ) &&
						( szInstallDir[1] == ':' ) && 
						( szInstallDir[2] == '\\' ))
						{
						DestroyWindow( hDlg );	  
						return 0;
						}

					wsprintf( szTemp, szFmt_NoDir, szInstallDir ); 
					if(( nMBRet = MessageBox( hParent, szTemp, szBuff_Title, 
													MB_YESNO )) == IDYES ) 
						{

                            // create a directory.
						if( !RMakeDir( szInstallDir ))
							{
#ifdef _WIN32
                                // get past the long file names...for now.
                            if( bWin95 )
                                {
                                MyGetShortPathName( szInstallDir, szInstallDir, _MAX_PATH );
                                }
#endif
							DestroyWindow( hDlg );	  
							return 0;
							}
						else
							{
							char szT1[ _MAX_PATH + 80 ];
							wsprintf( szT1, szFmtMsg_BadCreate, szInstallDir );
							MessageBox( hDlg, szT1, szBuff_Title, 
											MB_ICONHAND | MB_OK );
							}
						}
					else
						{
						SendDlgItemMessage(hDlg, IDC_INSTDIR, EM_SETSEL, 
												0, MAKELONG( 0, -1 ));
						SetFocus( GetDlgItem( hDlg, IDC_INSTDIR ));
						}
					break;

				case IDC_BROWSE:
					_fstrcpy( (LPSTR)szFilter, szCA_FileFilter );
					for( i=0; szFilter[i] != '\0'; i++ )
						{
						if( szFilter[i] == cFFSep )
							{
							szFilter[i] = '\0';
							}
						}
					_fstrcpy( szT1, "Filename" );
					memset(&ofn, 0, sizeof(OPENFILENAME));
					ofn.lStructSize = sizeof(OPENFILENAME);
					ofn.hwndOwner = hDlg;
					ofn.hInstance = ghInstance;
					ofn.lpstrFilter = (LPSTR)szFilter;
					ofn.nFilterIndex = 1;
					ofn.lpstrFile= szT1;
					ofn.nMaxFile = sizeof( szT1 );
					ofn.lpstrFileTitle = NULL;
					ofn.nMaxFileTitle = 0;
					ofn.lpstrInitialDir = path_part( szInstallDir );
					ofn.lpTemplateName = (LPSTR)MAKEINTRESOURCE( IDD_DIRBROWSE );
					ofn.Flags = OFN_NOTESTFILECREATE | OFN_ENABLETEMPLATE;
					if( GetOpenFileName(&ofn) )
						{
						memset( szInstallDir, 0, sizeof( szInstallDir ));
						_fstrncpy( szInstallDir, szT1, ofn.nFileOffset - 1 );
						szInstallDir[ ofn.nFileOffset ] = '\0';
						if( ( lstrlen( szInstallDir ) < 3 ) &&
							( szInstallDir[1] == ':' ))
							{
							_fstrcat( szInstallDir, "\\" );
							}

						SetDlgItemText(hDlg, IDC_INSTDIR, szInstallDir );
						SendDlgItemMessage(hDlg, IDC_INSTDIR, EM_SETSEL, 
												0, MAKELONG( 0, -1 ));
						SetFocus( GetDlgItem(hDlg, IDOK ));
						}
					else
						{
						SetFocus( GetDlgItem(hDlg, IDC_INSTDIR ));
						}
					break;

				case IDCANCEL:
					wRet = id;
					DestroyWindow( hDlg );	  
					return 0;

				case IDM_HELP:
					WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_Dir ));
					break;
				}
			return 0;

		case WM_DESTROY:
			hGlobDlg = NULL;
			switch( wRet )
				{
				case IDOK:
#ifdef TLOCK
					_fstrcpy( szUserName, szTLUser );
					_fstrcpy( szUserOrg, szTLOrg );
					_fstrcpy( szSerialNumber, szTLSN );
					PostMessage( hParent, WM_COMMAND, IDM_EXTRACTFILES, 0L);
#else
					PostMessage( hParent, WM_COMMAND, IDM_USERINFO, 0L);
#endif
					break;
				case IDCANCEL:
					PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
					break;
				}
			UpdateWindow( hParent );
			return FALSE;
		}

	return FALSE;
	}

//------------------------------------------------------------------
// Directory Browse dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 DirBrowseDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
	{
	WORD id;
	WORD cmd;
	HWND hChild;

	CrackIt( wParam, lParam, &id, &cmd, &hChild );
	switch (uMsg) 
		{
		case WM_INITDIALOG:
			CenterWindow( hDlg );
			SendDlgItemMessage( hDlg, IDC_DIRLIST, CB_DIR, 
								( WPARAM ) DDL_DIRECTORY | DDL_EXCLUSIVE, 
								( LPARAM )(LPSTR)"c:\\*" );
			return 0;

		case WM_COMMAND:
			switch( id ) 
				{
				case IDOK:
					GetDlgItemText(hDlg, IDC_DIRLIST, szInstallDir, _MAX_PATH );
					EndDialog( hDlg, SU_OK );
					break;
				case IDCANCEL:
					EndDialog( hDlg, SU_CANCEL );
					break;
				}
			return 0;
		}

	return FALSE;
	}

//------------------------------------------------------------------
// UserInfo dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 UserInfoDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            SetDlgItemText(hDlg, IDC_REGUSER, szUserName );
            SendDlgItemMessage( hDlg, IDC_REGUSER, EM_LIMITTEXT, 
                                (WPARAM)( USERNAMELEN ), 0L );
            SetDlgItemText(hDlg, IDC_REGORG, szUserOrg );
            SendDlgItemMessage( hDlg, IDC_REGORG, EM_LIMITTEXT, 
                                (WPARAM)( USERORGLEN ), 0L );
            SetDlgItemText(hDlg, IDC_REGSERIAL, szSerialNumber );
            SendDlgItemMessage( hDlg, IDC_REGSERIAL, EM_LIMITTEXT, 
                                (WPARAM)( SERNUMLEN ), 0L );
            SetFocus( GetDlgItem( hDlg, IDC_REGUSER ));
            SendDlgItemMessage(hDlg, IDC_REGUSER, EM_SETSEL, 
                                        0, MAKELONG( 0, -1 ));
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                    wRet = id;

                        // get what the user typed into the box.
                    GetDlgItemText(hDlg, IDC_REGUSER, szUserName, USERNAMELEN );
                    GetDlgItemText(hDlg, IDC_REGORG, szUserOrg,  USERORGLEN );
                    GetDlgItemText(hDlg, IDC_REGSERIAL, szSerialNumber, SERNUMLEN );
                    if( !ValidSernum( szSerialNumber ))
                        {
                        MessageBox( hParent, szEMsg_NotValidSN, szBuff_Title, 
                                                    MB_OK | MB_ICONHAND );
                        
                        SetFocus( GetDlgItem( hDlg, IDC_REGSERIAL ));
                        SendDlgItemMessage(hDlg, IDC_REGSERIAL, EM_SETSEL, 
                                                0, MAKELONG( 0, -1 ));
                        return 0;
                        }
                    else
                        {
                        DestroyWindow( hDlg );    
                        return 0;
                        }

                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;
        
                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_UserInfo ));
                    break;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_CONFIRMUSER, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return FALSE;
        }

    return FALSE;
    }

//------------------------------------------------------------------
// Confirm UserInfo dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ConfirmUIDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            SetDlgItemText(hDlg, IDC_REGUSER, szUserName );
            SetDlgItemText(hDlg, IDC_REGORG, szUserOrg );
            SetDlgItemText(hDlg, IDC_REGSERIAL, szSerialNumber );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;
        
                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_UserConf ));
                    break;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_EXTRACTFILES, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_USERINFO, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return FALSE;
        }

    return FALSE;
    }

//------------------------------------------------------------------
// Old User Info dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 OldUIDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            SetDlgItemText(hDlg, IDC_REGUSER, szUserName );
            SetDlgItemText(hDlg, IDC_REGORG, szUserOrg );
            SetDlgItemText(hDlg, IDC_REGSERIAL, szSerialNumber );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;
        
                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_UserInfo ));
                    break;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_EXTRACTFILES, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return FALSE;
        }

    return FALSE;
    }

//------------------------------------------------------------------
// Fileset dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 FilesetDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    HWND hLB;
    HDC hlbDC;
    LPCFILELIST lpFL, lpFL2;
    DWORD dwExt = 0;
    DWORD dwMaxExt = 0;
    static DWORD dwCurSel;
    static BOOL bCfgChanged;
    static BOOL bTempReg;
    static BOOL bDoReg=TRUE;
    static LPSTR lpDelFile=NULL;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;

            bCfgChanged = FALSE;
            bTempReg = bDoReg;
            lpDelFile = (LPSTR)GetMem( _MAX_PATH + 1 );
            
            CenterWindow( hDlg );
            EnableWindow( GetDlgItem(hDlg, IDC_DELFILE ), FALSE );

            CheckDlgButton( hDlg, IDC_SAVEREG, bDoReg );

            LoadFileList( &lpCfgAnchor );

            hLB = (HWND)GetDlgItem( hDlg, IDC_FILELIST );
            hlbDC = GetDC( hLB );
            lpFL = lpCfgAnchor;
            while( lpFL != NULL )
                {
#if defined(_WIN32) || defined(__WIN32__)
                SIZE sExt;
                GetTextExtentPoint32( hlbDC, lpFL->lpRealName, 
                                      lstrlen( lpFL->lpRealName), &sExt );
                dwExt = sExt.cx;
#else
                dwExt = LOWORD( GetTextExtent( hlbDC, lpFL->lpRealName, 
                                      lstrlen( lpFL->lpRealName )));
#endif

                if( dwMaxExt < dwExt )
                    {
                    dwMaxExt = dwExt;
                    }
                SendDlgItemMessage(hDlg, IDC_FILELIST, LB_ADDSTRING, 0, (LONG)(LPSTR) lpFL->lpRealName );
                lpFL = lpFL->next;
                }

            ReleaseDC( hLB, hlbDC );
            SendDlgItemMessage( hDlg, IDC_FILELIST, LB_SETHORIZONTALEXTENT,
                                (WORD) dwMaxExt, 0L );
            return 0;

        case WM_COMMAND:
                // trap window activation to hilight buttons.
            if (  (( cmd == LBN_SELCHANGE) 
                || ( cmd == LBN_SETFOCUS)) 
                && (  hChild == (HWND)GetDlgItem( hDlg, IDC_FILELIST )))
                {
                EnableWindow( GetDlgItem(hDlg, IDC_DELFILE ), TRUE );
                dwCurSel = SendDlgItemMessage(hDlg, IDC_FILELIST,  LB_GETCURSEL, 0, 0L), 
                SendDlgItemMessage(hDlg, IDC_FILELIST, LB_GETTEXT, 
                                (WORD)dwCurSel, (LONG)(LPSTR)lpDelFile );
                return TRUE;
                }

            switch( id ) 
                {
                case IDOK:
                    wRet = id;
                    bTempReg = IsDlgButtonChecked(hDlg, IDC_SAVEREG);
                        // don't change if greyed.
                    if( bTempReg != 2 )
                        {
                        WritePrivateProfileString( szIniOpt, szC_IniSaveReg, 
                            ( bTempReg ) ? (LPSTR)"1" : (LPSTR)"0", lpIniFile );

                        bDoReg = bTempReg;
                        }

                    if( bCfgChanged )
                        {
                        WriteFileList( &lpCfgAnchor );
                        KillFileList( &lpCfgAnchor );
                        }
                    else
                        {
                        KillFileList( &lpCfgAnchor );
                        }

                    if( lpDelFile ) 
                        { 
                        _ffree( lpDelFile ); 
                        lpDelFile = NULL; 
                        }
                    DestroyWindow( hDlg );    
                    return 0;

                case IDCANCEL:
                    wRet = id;
                    KillFileList( &lpCfgAnchor );
                    if( lpDelFile ) 
                        { 
                        _ffree( lpDelFile ); 
                        lpDelFile = NULL; 
                        }
                    DestroyWindow( hDlg );    
                    return 0;

                case IDC_ADDFILE:
                    szTPath[0] = '\0';
                    DialogBox( ghInstance, MAKEINTRESOURCE( IDD_ADDFILE ), hDlg, (FARPROC)AddDlgProc );
                    if( szTPath[0] != '\0' )
                        {
                        if( ScanFLForDups( &lpCfgAnchor, szTPath ))
                            {
                            char szT1[ _MAX_PATH + 80 ];
                            wsprintf( szT1, szFmt_Duplicate, szTPath );
                            MessageBox( hParent, szT1, szBuff_Title, 
                                        MB_OK | MB_ICONHAND); 
                            break;
                            }

                        if( QueryFileExists( szTPath ) == 0 )
                            {
                            char szT1[ _MAX_PATH + 80 ];
                            wsprintf( szT1, szFmt_NoFile, szTPath );
                            MessageBox( hParent, szT1, szBuff_Title, 
                                        MB_OK | MB_ICONHAND); 
                            break;
                            }

                        if( IsTextFile( szTPath ) == 0 )
                            {
                            char szT1[ (_MAX_PATH * 2) + 2];
                            wsprintf( szT1, szFmt_NotText, szTPath );
                            MessageBox( hParent, szT1, szBuff_Title, 
                                        MB_OK | MB_ICONHAND); 
                            }

                        SendDlgItemMessage(hDlg, IDC_FILELIST, LB_ADDSTRING, 0, (LONG)(LPSTR) szTPath );
                        bCfgChanged = TRUE;
                        lpFL = lpCfgAnchor;
                        
                            // move to the end of the list.
                        if( lpFL )
                            {
                            while( lpFL->next )
                                {
                                lpFL = lpFL->next;
                                }
                            }

                            // add another link to the list.
                        if( lpFL )
                            {
                            lpFL2 = lpFL;
                            lpFL = ( LPCFILELIST )GetMem( sizeof( CFILELIST ));
                            lpFL2->next = lpFL;
                            lpFL->prev = lpFL2;
                            lpFL->lpRealName = StrMem( szTPath );
                            lpFL->next = NULL;
                            }
                        else
                            {
                            lpCfgAnchor = ( LPCFILELIST )GetMem( sizeof( CFILELIST ));
                            lpCfgAnchor->lpRealName = StrMem( szTPath );
                            lpCfgAnchor->prev = NULL;
                            lpCfgAnchor->next = NULL;
                            }
                        }
                    break;

                case IDC_DELFILE:
                    if( lpDelFile[0] )
                        {
                        SendDlgItemMessage(hDlg, IDC_FILELIST, LB_DELETESTRING, (WORD)dwCurSel, 0L );
                        SendDlgItemMessage(hDlg, IDC_FILELIST,  LB_SETCURSEL, (WPARAM)-1, 0L), 
                        EnableWindow( GetDlgItem(hDlg, IDC_DELFILE ), FALSE );
                        SetFocus( GetDlgItem(hDlg, IDOK ));
                        bCfgChanged = TRUE;
                        lpFL = lpCfgAnchor;

                            // compare names till the list ends..
                        while( lpFL )
                            {
                            if( !_fstrcmp( lpDelFile, lpFL->lpRealName ))
                                {
                                break;
                                }
                            lpFL = lpFL->next;
                            }

                            // trap "Not Found".
                        if( lpFL == NULL )
                            {
                            break;
                            }

                        lpFL2 = lpFL;
                        if( lpFL->prev != NULL )
                            {
                            ((LPCFILELIST)(lpFL->prev))->next = lpFL->next;
                            if( lpFL->next != NULL )
                                {
                                ((LPCFILELIST)(lpFL->next))->prev = lpFL->prev;
                                }

                            _ffree( lpFL2 );
                            }
                        else
                            {
                                // lpFL->prev == NULL.
                                // this is the root node.
                            if( lpFL->next == NULL )
                                {
                                    // there are no more nodes.
                                _ffree( lpCfgAnchor );
                                lpCfgAnchor = NULL;
                                }
                            else
                                {
                                    // make the next one the first one.
                                lpFL2 = lpFL->next;
                                _ffree( lpCfgAnchor );
                                lpCfgAnchor = lpFL2;
                                lpCfgAnchor->prev = NULL;
                                }
                            }
                        }
                    return 0;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_Caplist ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_SCHEDULE, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }

//------------------------------------------------------------------
// Schedule dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ScheduleDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild, hSB;
    BOOL bStartup;
    BOOL bScheduled;
    int nSCode;
    int nDoDays;
    time_t ttMark=0;
    char szT1[20];
    static HWND hwDays;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            
            nDoDays = 7;
            bAddAuto = FALSE;
            bStartup = FALSE;
            bScheduled = FALSE;
            CheckDlgButton( hDlg, IDC_RADNOAUTO, TRUE );
            CheckDlgButton( hDlg, IDC_RADSCHED1, FALSE );
            CheckDlgButton( hDlg, IDC_RADSCHED2, FALSE );
            wsprintf( szT1, "%d", nDoDays );
            SendDlgItemMessage( hDlg, IDC_DAYS, WM_SETTEXT, 0, (LONG)(LPSTR)szT1 );

            hwDays =  (HWND)GetDlgItem( hDlg, IDC_DAYS );
            return 0;

        case WM_VSCROLL:
#ifdef _WIN16
            hSB = (HWND)HIWORD( lParam );
#else
            hSB = (HWND)lParam;
#endif
            nSCode = id;
            if( IDC_DAYSCROLL == GetDlgCtrlID( hSB ))
                {
                if( (nSCode == SB_LINEUP) || (nSCode == SB_LINEDOWN ))
                    {
                    nDoDays = ScrollNumWheel( hDlg, IDC_DAYS, nSCode, 
                                    MINSCHED, MAXSCHED, 5, szT1 );
                    }
                }
            return 0;

        case WM_COMMAND:
                // prevent manually sneaking past the limits.
            if ( cmd == EN_KILLFOCUS )
                {
                if( hChild == hwDays )
                    {
                    CheckEdLimit( hDlg, IDC_DAYS, &nDoDays, 
                                                MINSCHED, MAXSCHED );
                    }
                }
            switch( id ) 
                {
                case IDOK:
                    wRet = id;
                    if( bAddAuto = !IsDlgButtonChecked( hDlg, IDC_RADNOAUTO ))
                        {
                           // this option must be set in both startup cases.
                           // Mutually exclusive with RADNOAUTO.
                        bScheduled = TRUE;

                        bStartup = IsDlgButtonChecked( hDlg, IDC_RADSCHED1 );
                        WritePrivateProfileString( szIniOpt, szC_IniStart, 
                            ( bStartup ) ? (LPSTR)"1" : (LPSTR)"0", lpIniFile );

                        WritePrivateProfileString( szIniOpt, szC_IniSched,
                            ( bScheduled ) ? (LPSTR)"1" : (LPSTR)"0", lpIniFile );

                        SendDlgItemMessage(hDlg, IDC_DAYS, WM_GETTEXT, 
                                                (WORD)5, (LONG)(LPSTR)szT1 );
                        nDoDays = atoi( szT1 );
                        WritePrivateProfileString( szIniOpt, szC_IniDays, 
                                                           szT1, lpIniFile );
                        }
                    else
                        {
                        WritePrivateProfileString( szIniOpt, szC_IniStart, 
                                                   (LPSTR)"0", lpIniFile );
                        WritePrivateProfileString( szIniOpt, szC_IniSched,
                                                   (LPSTR)"0", lpIniFile );
                        }

                    if( !bStartup && bScheduled  )
                        {
                        time( &ttMark );
                            // don't change the time if one already exists.
                        if( !GetPrivateProfileString( szIniOpt, szC_IniTMark, 
                                                 "", szT1, 10, lpIniFile ))
                            {
                            WritePrivateProfileLong( szIniOpt, szC_IniTMark, 
                                               (long)ttMark, lpIniFile );
                            }
                        }
                    DestroyWindow( hDlg );    
                    return 0;

                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_Schedule ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_TRAYNOTE, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }

//------------------------------------------------------------------
// Un-Welcome dialog proc.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 UninstallDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            CenterWindow( hDlg );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_UnMain ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_UNINSTALL, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }

//------------------------------------------------------------------
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 AddDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    OPENFILENAME ofn;
    int i;
    WORD id;
    WORD cmd;
    HWND hChild;
    static HWND hPrev = NULL;
    char szFilter[ _MAX_PATH ];
    char szT1[ _MAX_PATH ];

    CrackIt( wParam, lParam, &id, &cmd, &hChild );

    szT1[0] = '\0';
    switch (uMsg) 
        {
        case WM_DESTROY:
            hActive = hPrev;
            break;

        case WM_INITDIALOG:
            hPrev = hActive;
            hActive = hDlg;

            CenterWindow( hDlg );
            SetFocus( GetDlgItem(hDlg, IDC_NAMETOADD ));
            szTPath[0] = '\0';
            return 0;

        case WM_COMMAND:
            
            switch( id ) 
                {
                case IDOK:
                    GetDlgItemText(hDlg, IDC_NAMETOADD, szTPath, _MAX_PATH);
#if defined(_WIN32) || defined(__WIN32__)
                        // reduce to short filename.
                    MyGetShortPathName( szTPath, szTPath, _MAX_PATH );
#endif
                    EndDialog( hDlg, 0 );
                    break;

                case IDCANCEL:
                    EndDialog( hDlg, 0 );
                    break;

                case IDC_BROWSE:
                    
                    _fstrcpy( (LPSTR)szFilter, szCA_FileFilter );
                    for( i=0; szFilter[i] != '\0'; i++ )
                        {
                        if( szFilter[i] == cFFSep )
                            {
                            szFilter[i] = '\0';
                            }
                        }
                    memset(&ofn, 0, sizeof(OPENFILENAME));
                    ofn.lStructSize = sizeof(OPENFILENAME);
                    ofn.hwndOwner = hDlg;
                    ofn.lpstrFilter = (LPSTR)szFilter;
                    ofn.nFilterIndex = 1;
                    ofn.lpstrFile= szT1;
                    ofn.nMaxFile = sizeof( szT1 );
                    ofn.lpstrTitle = szC_ProgTitle;
                    ofn.lpstrFileTitle = NULL;
                    ofn.nMaxFileTitle = 0;
                    ofn.lpstrInitialDir = lpWinPath;
                    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST 
                                | OFN_HIDEREADONLY | OFN_SHAREAWARE;
                    if( GetOpenFileName(&ofn) )
                        {
                        SetDlgItemText(hDlg, IDC_NAMETOADD, szT1 );
                        SetFocus( GetDlgItem(hDlg, IDOK ));
                        }
                    else
                        {
                        SetFocus( GetDlgItem(hDlg, IDC_NAMETOADD ));
                        }
                    break;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_PARTIALKEY, (DWORD)(( LPSTR ) szHK_AddFile ));
                    break;
                }
            return 0;
        }

    return FALSE;
    }

//------------------------------------------------------------------
// ProgGroup dialog proc.
//------------------------------------------------------------------
#define PGSIZE 128
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 PGroupDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
    WORD id;
    WORD cmd;
    HWND hChild;
    BOOL bDefGroup=FALSE;
    LPSTR szGName;
    int nGroupCount;
    char szT1[ PGSIZE + 2 ];
    static LPSTR szBuff;
    static WORD wRet;

    CrackIt( wParam, lParam, &id, &cmd, &hChild );
    switch (uMsg) 
        {
        case WM_INITDIALOG:
            wRet = 0;
            bDefGroup = FALSE;
            if((szBuff = GetGroups()) == NULL)
                {
                return 0;
                }
                    // add the names to the list.
            nGroupCount = 0;
            for( szGName = _fstrtok( szBuff, "\r\n" );
                 szGName != NULL ;
                 szGName = _fstrtok( NULL, "\r\n" ))
                {
                    // We're testing to find a duplicate group name.
                if( !bDefGroup )
                    {
                    if( !_fstricmp( szGName, szC_DefaultGroup ))
                        {
                        bDefGroup = TRUE;
                        }
                    }
                SendDlgItemMessage(hDlg, IDC_PGLIST, CB_ADDSTRING, 
                                       0, (LONG)(LPSTR) szGName );
                nGroupCount++;
                }
            _ffree( szBuff );

            if( bWin95 || (nGroupCount < 40 ))
                {
                if( !bDefGroup )
                    {
                        // put the default into the edit box.
                    SendDlgItemMessage(hDlg, IDC_PGLIST, CB_ADDSTRING, 
                                        0, (LONG)(LPSTR) szC_DefaultGroup );
                    }

                SendDlgItemMessage(hDlg, IDC_PGLIST,  CB_SELECTSTRING, 
                               0, (LPARAM)(LPCSTR)szC_DefaultGroup );
                }
            else
                {
                MessageBox( hParent, szEMsg_BadGroup, szBuff_Title, 
                                            MB_OK | MB_ICONHAND );
                }
                
            CenterWindow( hDlg );
            return 0;

        case WM_COMMAND:
            switch( id ) 
                {
                case IDOK:
                    wRet = id;
                    SendDlgItemMessage(hDlg, IDC_PGLIST, WM_GETTEXT, 
                                    (WORD)PGSIZE, (LONG)(LPSTR)szT1 );
                    if( szT1[0] != '\0' )
                        {
                        if( lpProgGroup )
                            {
                            _ffree( lpProgGroup );
                            }
                        lpProgGroup = StrMem( szT1 );
                        }
                    else
                        {
                        if( lpProgGroup )
                            {
                            _ffree( lpProgGroup );
                            }
                        lpProgGroup = StrMem( szC_DefaultGroup );
                        }

                    DestroyWindow( hDlg );    
                    return 0;

                case IDCANCEL:
                    wRet = id;
                    DestroyWindow( hDlg );    
                    return 0;

                case IDM_HELP:
                    WinHelp( hDlg, lpHelpFile, HELP_KEY, (DWORD)(( LPSTR ) szHK_PGroup ));
                    return 0;
                }
            return 0;

        case WM_DESTROY:
            hGlobDlg = NULL;
            switch( wRet )
                {
                case IDOK:
                    PostMessage( hParent, WM_COMMAND, IDM_ICONTOGROUP, 0L);
                    break;
                case IDCANCEL:
                    PostMessage( hParent, WM_COMMAND, IDM_EXIT, 0L);
                    break;
                }
            UpdateWindow( hParent );
            return 0;
        }

    return 0;
    }



//------------------------------------------------------------------
// file list utilities.
//------------------------------------------------------------------
void WriteFileList( LPCFILELIST FAR *lpA )
    {
    HFILE fh;
    LPCFILELIST lpFL;

    if (( fh = _lcreat( lpFileList, 0 )) == HFILE_ERROR ) 
        {
        SetErrMsg( szEMsg_FOpen );
        CrashExit( );
        }

        // write the list to disk.
        // Note that a null list will now make an empty file.
    lpFL = (*lpA);
    while( lpFL != NULL )
        {
        sswrite( fh, lpFL->lpRealName, lstrlen( lpFL->lpRealName ));
        sswrite( fh, "\r\n", 2);
        
        lpFL = lpFL->next;
        }
    
    _lclose(fh);
    }

//------------------------------------------------------------------
void LoadFileList( LPCFILELIST FAR *lpA )
    {
    HFILE fh;
    LPCFILELIST lpFL, lpFL2;
    char lpBuf[ LINEBUFLEN + 1 ];
    
    if ((fh = _lopen( lpFileList, READ | OF_SHARE_DENY_NONE)) != HFILE_ERROR) 
        {
        while ( GetLine( fh, lpBuf, _MAX_PATH + 1 ))
            {
            strip_leading( lpBuf, " \t" );
            
            if( (*lpA) )
                {
                lpFL = (*lpA);
                while( lpFL->next != NULL )
                    {
                    lpFL = lpFL->next;
                    }
                lpFL2 = lpFL;
                lpFL = ( LPCFILELIST )GetMem( sizeof( CFILELIST ));
                lpFL2->next = lpFL;
                lpFL->prev = lpFL2;
                lpFL->next = NULL;
                }
            else
                {
                    // create the initial record.
                (*lpA ) = ( LPCFILELIST )GetMem( sizeof(CFILELIST));
                lpFL = (*lpA );
                lpFL->prev = NULL;
                lpFL->next = NULL;
                }
                        
                // put the data in.
            lpFL->lpRealName = StrMem( lpBuf ); 
            }

        _lclose(fh);
        }
    }

//------------------------------------------------------------------
void KillFileList( LPCFILELIST FAR *lpA )
    {
    LPCFILELIST lpScan = NULL;
    LPCFILELIST lpTemp = NULL;

    if( (*lpA) != NULL ) 
        {
            // seek to the end of the list.
        for ( lpScan = (*lpA); lpScan->next != NULL; ) 
            {
            lpScan = lpScan->next;
            }
            
            // back up and free the list.
        for ( ; lpScan != (*lpA); ) 
            {
            lpTemp = lpScan;
            lpScan = lpScan->prev;
            if( lpTemp->lpRealName )
                {
                _ffree( lpTemp->lpRealName );
                }
            if( lpTemp->lpBackName )
                {
                _ffree( lpTemp->lpBackName );
                }
            if( lpTemp->lpDiffName )
                {
                _ffree( lpTemp->lpDiffName );
                }
            _ffree( lpTemp );
            }
        
        _ffree( (*lpA)->lpRealName );
        _ffree( (*lpA)->lpBackName );
        _ffree(  (*lpA)->lpDiffName );
        _ffree(  (*lpA) );
        *lpA = NULL;

#ifdef _WIN16
        _fheapmin();
#endif
        }
    }

//------------------------------------------------------------------
BOOL ScanFLForDups( LPCFILELIST FAR *lpA, LPSTR szName )
    {
    LPCFILELIST lpScan = NULL;

    if( (*lpA) != NULL ) 
        {
            // seek to the end of the list.
        for ( lpScan = (*lpA); lpScan->next != NULL; ) 
            {
            if( !_fstricmp( lpScan->lpRealName, szName ))
                {
                return TRUE;
                }
            lpScan = lpScan->next;
            }
        }
    return FALSE;
    }

//------------------------------------------------------------------
int ScrollNumWheel( HWND hw, int nID, int nCode, int nMin, int nMax, 
                                        int nBLen, LPSTR lpBuf )
    {
    int nTemp;
    
    SendDlgItemMessage(hw, nID, WM_GETTEXT, (WORD)nBLen, (LONG)lpBuf );
    nTemp = atoi( lpBuf );
    switch( nCode )
        {
        case SB_LINEUP:
            nTemp = ( nTemp < nMax ) ? ++nTemp : nMin;
            break;
        case SB_LINEDOWN:
            nTemp = ( nTemp > nMin ) ? --nTemp : nMax;
            break;
        }
        
    wsprintf( lpBuf, "%d", nTemp );
    SendDlgItemMessage( hw, nID, WM_SETTEXT, 0, (LONG)lpBuf );

    return nTemp;
    }

//------------------------------------------------------------------
void CheckEdLimit( HWND hw, int nID, int FAR *nVal, int nMin, int nMax ) 
    {
    BOOL bChanged = FALSE;
    char szT1[20];
    
    SendDlgItemMessage(hw, nID, WM_GETTEXT, (WORD)5, (LONG)(LPSTR)szT1 );
    *nVal = atoi( szT1 );

    if( *nVal > nMax )
        {
        *nVal = nMax;
        bChanged = TRUE;
        }

    if( *nVal < nMin )
        {
        *nVal = nMin;
        bChanged = TRUE;
        }

    if( bChanged )
        {
        wsprintf( szT1, "%d", *nVal );
        SendDlgItemMessage( hw, nID, WM_SETTEXT, 0, (LONG)(LPSTR)szT1 );
        }
    }

//------------------------------------------------------------------
// Check path, -1 = no good. 0 = good, 1 = changed.
//------------------------------------------------------------------
int MakeValidPath( LPSTR lpDir )
    {
    int nRet = 0;
    int nFSLen;
    int i;
    LPSTR lpFS;
    char szDrive[ _MAX_DRIVE + 2 ];
    char szPath[ _MAX_PATH + 2 ];
    char szFile[ _MAX_PATH + 2 ];
    char szExt[ _MAX_EXT + 2 ];

        // determine if a drive is specified.
    _splitpath( lpDir, szDrive, szPath, szFile, szExt );

        // make sure it's a valid path.
    if( !bWin95 )
        {
        if( szFile[0] != '\0' )
            {
            lpFS = szFile;
            }
        else
            {
            lpFS = szPath;
            }
        strip_trailing( lpFS, "\\/" );

        nFSLen = lstrlen( lpFS );

        for( i=0; i < nFSLen; i++ )
            {
            if( ( !__iscsym( lpFS[i] )) 
                 && ( lpFS[i] != '!' )
                 && ( lpFS[i] != '@' )
                 && ( lpFS[i] != '#' )
                 && ( lpFS[i] != '$' )
                 && ( lpFS[i] != '%' )
                 && ( lpFS[i] != '^' )
                 && ( lpFS[i] != '&' )
                 && ( lpFS[i] != '~' )
                 && ( lpFS[i] != '-' ))
                {
                return (-1);
                }
            }
        if( nFSLen > 8 )
            {
            lpFS[8] = '\0';
            nRet = 1;
            }
        
            // truncate extension if there is one.
        if( lstrlen( szExt ) > 4 )
            {
            szExt[4] = '\0';
            nRet = 1;
            }
        }

        // insist they have a drive designator.
    if( szDrive[0] == '\0' ) 
        {
        bootdrive( szDrive );
        nRet = 1;
        }
    
    if( nRet > 0 ) 
        {
        MakePath( szDrive, szPath, lpDir );
        MakePath( lpDir, szFile, lpDir );
        if( szExt[0] != '\0')
            {
            _fstrcat( lpDir, szExt );
            }
        }
    return nRet;
    }
