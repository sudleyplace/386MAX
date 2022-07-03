
// $Header:   P:/PVCS/MAX/SETUP/SETEXT.CPV   1.3   20 Jan 1997 08:36:52   PETERJ  $
//------------------------------------------------------------------
// SetExt.cpp - Routines to spawn a dos copy out of Windows.
// Stolen from Dispatch uninstall.
// EXTFILE.C - Routines to extract data (files) from a resource.
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//------------------------------------------------------------------
#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>

#include <setglob.h>

    // has Clean.exe been extracted?
BOOL bCleanOut = FALSE;

//------------------------------------------------------------------
// Add entry to batch file for "ExittoDos" copying.
// szSaved = where the file is now.
// szDest = where you want it to go.
// szCopyFile = File Path/name of batch file to add to.
// ACB_DELETE = delete file
// ACB_VMM    = Copy to VMM32 directory.
//------------------------------------------------------------------
BOOL AddToCopyBatch( LPSTR szSaved, LPSTR szDest, LPSTR szBatchFile, 
                     UINT uFlags )
    {
    HFILE hf;
    OFSTRUCT os;
    char msg[ ( _MAX_PATH * 2 ) + 50 ];

    _fmemset( &os, 0, sizeof( OFSTRUCT ));

    if (( hf = OpenFile( szBatchFile, &os, OF_READWRITE )) != HFILE_ERROR ) 
        {
        wsprintf( msg, "@COPY %s %s >NUL\r\n", szSaved, szDest );
        _llseek( hf, 0L, 2 );
        sswrite( hf, msg, lstrlen( msg )); 

        if( uFlags & ACB_VMM )
            {
            char szT1[ _MAX_PATH + 2 ];
            MakePath( lpSysPath, szC_VMMPath, szT1 );
            MakePath( szT1, fname_part( szDest ), szT1 );
            wsprintf( msg, "@COPY %s %s >NUL\r\n", szSaved, szT1 );
            _llseek( hf, 0L, 2 );
            sswrite( hf, msg, lstrlen( msg )); 
            }

        if( uFlags & ACB_DELETE )
            {
            wsprintf( msg, "@DEL %s >NUL\r\n", szSaved );
            _llseek( hf, 0L, 2 );
            sswrite( hf, msg, lstrlen( msg )); 
            }

        _lclose( hf );

    return TRUE;
    }

return FALSE;
}

//------------------------------------------------------------------
// Makes copy directory and file and returns true.
// Also returns true if file already exists.
// Returns false if failure.
//------------------------------------------------------------------
// szDest = the installation directory.
// lpBatchFile is the batch file name 
// lpCopyPath is the name of the dir with the temp copies.
// lpCopyProg is the name of the copy program.
//------------------------------------------------------------------
BOOL DosCopyPrep( LPSTR szDest, LPSTR lpCopyPath, LPSTR lpCopyProg,
                                                LPSTR lpBatchFile )
    {
    int nErr = 0;
    BOOL bNewDir=FALSE;
    HFILE hf;
    OFSTRUCT os;

    if( !bCleanOut ) 
        {
        char szName[ _MAX_PATH+2 ];
        MakePath( szDest, lpCopyProg, szName );
        if ( ExtractFileFromRes( ghInstance, ( LPCSTR ) szName, SETCLEAN )) 
            {
            bCleanOut = TRUE;
            }
        }

        // Does the directory name already exist?
    if( QueryDirExists( lpCopyPath ) == 0 )
        {
            // directory does not exist...make it.
        nErr = _mkdir( (LPSTR)lpCopyPath );
        if( !nErr )
            {
            bNewDir = TRUE;
            }
        } 
            
    if( !nErr )
        {
            // the path already exists.
        if( QueryFileExists( lpBatchFile ) == 0 )
            {
            _fmemset( &os, 0, sizeof( OFSTRUCT ));
        
                // make the file as well.
            if (( hf = OpenFile( lpBatchFile, &os, 
                                OF_READWRITE | OF_CREATE | OF_SHARE_COMPAT ))
                                != HFILE_ERROR ) 
                {
                _lclose( hf );
                } 
            else 
                {
                    // error on file open.
                    // Remove directory since the file create failed.
                if( bNewDir )
                    {
                    _rmdir( lpCopyPath );
                    }
                nErr = -1; 
                }
            }
        }
    
    if( nErr ) 
        {
        return FALSE;
        }

        // directory exists.
    return TRUE;
    }

//------------------------------------------------------------------
// Extracts clean.exe from a setup.exe resource.
//------------------------------------------------------------------
BOOL CALLBACK 
ExtractFileFromRes( HINSTANCE hInst, LPCSTR szName, WORD wID ) 
    {
    int fhOut;
    HRSRC hData;
    HGLOBAL hDataInst;
    char FAR* lpBlock;
    WORD FAR* lpwLen;
    char FAR* lpData;

    if (( hData = 
        FindResource( hInst, MAKEINTRESOURCE( wID ), RT_RCDATA )) != NULL )
        {
        if (( hDataInst = LoadResource( hInst, hData )) != NULL )
            {
            if (( lpBlock = (char FAR * )LockResource( hDataInst )) != NULL )
                {
                    // sort out the length and data.
                lpwLen = ( WORD FAR *) lpBlock;
                lpData = lpBlock + 2;
            
                    // construct a file.
                fhOut = _open( szName, _O_CREAT | _O_BINARY | _O_RDWR 
                                        | _O_TRUNC, _S_IWRITE | _S_IREAD );
                if (fhOut < 0) 
                    {
                        // Couldn't create output file
                    return FALSE;
                    } 
                        
                    // write the data
                _write( fhOut, lpData, *lpwLen );
                 _close( fhOut );

                UnlockResource( hDataInst );
                }
            else
                {
                FreeResource( hDataInst );
                return FALSE;
                }

            FreeResource( hDataInst );
            }
        else
            {
            return FALSE;
            }
        }
    else
        {
        return FALSE;
        }

    return TRUE;
    }

#ifdef _WIN16
//------------------------------------------------------------------
// Exit Windows and exec clean.exe to run batch file.
//------------------------------------------------------------------
BOOL ExecCleanBat( LPSTR szDest, LPSTR szCopyProg, LPSTR szCopyDir, 
                   LPSTR szBatFileName, LPSTR szWindowsDir )
    {
    BOOL bExec = FALSE;
    int nCancel = IDCANCEL;
    int nExeLen;
    int nParmLen;
    LPSTR lpExe;
    LPSTR lpParm;

    nExeLen = _fstrlen( (LPSTR)szDest );
    nExeLen += _fstrlen( (LPSTR)szCopyProg );
    lpExe = (LPSTR)GetMem( nExeLen + 10 );

    nParmLen = _fstrlen( (LPSTR)szDest );
    nParmLen += _fstrlen( (LPSTR)szBatFileName );
    nParmLen += _fstrlen( (LPSTR)szDest );
    nParmLen += _fstrlen( (LPSTR)szWindowsDir );
    if( szCopyDir )
        {
        nParmLen += _fstrlen( (LPSTR)szCopyDir );
        }

    lpParm = (LPSTR)GetMem( nParmLen + 10 );
        
    MakePath( szDest, szCopyProg, lpExe );

    if( szCopyDir && (szCopyDir[0] != '\0' ))
        {
        MakePath( szDest, szCopyDir, lpParm );
        MakePath( lpParm, szBatFileName, lpParm );
        }
    else
        {
        MakePath( szDest, szBatFileName, lpParm );
        }

    SYield(0);
    bExec = ExitWindowsExec( lpExe, lpParm );
    return bExec;
    }

#endif
//------------------------------------------------------------------
