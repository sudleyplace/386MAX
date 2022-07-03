// $Header:   P:/PVCS/MAX/SETUP/SETUNZIP.CPV   1.2   20 Jan 1997 08:36:50   PETERJ  $
//------------------------------------------------------------------
// SETUNZIP.CPP Unzip routines, stolen from...
// ZOPEN.CPP - Zip access class CZopen implementation
// ...except we dynamically link in this version to avoid
// the missing link errors from not starting with the dll loaded.
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//------------------------------------------------------------------

#define	STRICT
#include <windows.h>

#include <stdio.h>
#include <io.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <memory.h>
#include <stdarg.h>

#include <statutil.h>
#include <setglob.h>

#define _DZIP_OWNER
#ifdef _WIN32
    #include <dunzip32.h>
#else
    #include <dunzdll.h>
#endif
#undef _DZIP_OWNER

    // define setunzip variables.
#define SETUNZIP_DEFVARS 1
#include <setunzip.h>

//------------------------------------------------------------------
// Return an acceptable path for .ZIP file; drive letters are out
// as are leading slashes (apparently).
LPCSTR
ZipPath( LPCSTR lpPath ) 
    {
    if (*lpPath && lpPath[ 1 ] == ':') 
        {
		lpPath += 2;
        }

    if (*lpPath == '/' || *lpPath == '\\') 
        {
		lpPath++;
        }
	return lpPath;
    } // ZipPath()

//------------------------------------------------------------------
// Common initialization code called by constructors
void CZopen::_CZopen( UINT wInst ) 
    {
	m_lpZip = NULL;
	m_hInst = (HINSTANCE)wInst;

	memset( &m_uzcs, 0, sizeof( m_uzcs ) );
	m_uzcs.unzipStructSize = sizeof( m_uzcs );
	m_uzcs.quietFlag = TRUE;
	m_uzcs.overWriteFlag = TRUE;
	m_uzcs.recurseFlag = TRUE;
            
        // Mark all files as available
	memset( m_nFiles, 0xff, sizeof( m_nFiles ) );

        // Zap list of files
	memset( m_lpFNames, 0, sizeof( m_lpFNames ) );

        // Zap file input buffer list
    memset( m_lpInBuffs, 0, sizeof( m_lpInBuffs ) );
	memset( m_nInBuffLens, 0, sizeof( m_nInBuffLens ) );
    } // CZopen::_CZopen()

//------------------------------------------------------------------
// Standard destructor
CZopen::~CZopen( void ) 
    {
	if (m_lpZip) 
        {
		_ffree( (void FAR *)m_lpZip );
		m_lpZip = NULL;
        }
    } // ~CZopen()

//------------------------------------------------------------------
// Member functions

//------------------------------------------------------------------
// Set current .ZIP file to use.  All files must be closed.
// Returns 0 if successful, -1 if failed.
// Very Important to check this return value.
//------------------------------------------------------------------
int CZopen::SetZip( LPCSTR lpZipPath ) 
    {

	if (m_lpZip) 
        {
		_ffree( (void FAR *)m_lpZip );
        }
       
	m_lpZip = (LPSTR)_fmalloc( lstrlen( lpZipPath ) + 1 );
	m_nCurEntry = -1;
	m_nTotalEntries = -1;

	if (!m_lpZip) 
        {
		return -1;
        } // Failed to allocate

	m_uzcs.lpszZIPFile = m_lpZip;
	lstrcpy( m_lpZip, lpZipPath );
	return 0;
    } 

//------------------------------------------------------------------
// Extract specified file(s) from .ZIP to specified directory.
// Required directory components will be created if needed.
// Returns -1 if failed or 0 if successful.
//------------------------------------------------------------------
int CZopen::GetFromZip( LPCSTR lpFileList, LPCSTR lpOutDir,
                        BOOL MakeDirs /*= TRUE*/ ) 
    {
    if( Duz == NULL )
        {
        return -1;
        }

	m_uzcs.function = UNZIP_EXTRACT;
	m_uzcs.zInfo = NULL;
	m_uzcs.lpszFilespec = (LPSTR)ZipPath( lpFileList );
	m_uzcs.index = -1;
	m_uzcs.lpszDestination = (LPSTR)lpOutDir;
	m_uzcs.noDirectoryNamesFlag = !MakeDirs;

	m_nCurFile = -1;

	int nRes = Duz( &m_uzcs );

	m_uzcs.noDirectoryNamesFlag = 0;

	if (nRes == UE_OK) 
        {
		return 0;
        }

	return -1;
    } 

// Get first entry in a .ZIP file.  Returns -1 if failed.
int CZopen::GetFirst( ZIPINFO FAR *lpZ ) 
    {
        // Make sure we have a .ZIP name
	if (!m_lpZip) 
        {
		return -1;
	} // No .ZIP name

	// Assume failure
	m_nCurEntry = -1;

	// Get number of entries
	m_uzcs.function = UNZIP_COUNTALLZIPMEMBERS;
	m_uzcs.zInfo = NULL;
	m_uzcs.lpszFilespec = NULL;
	m_uzcs.index = -1;
	m_uzcs.returnCount = 0;

	if ( Duz( &m_uzcs ) != UE_OK) 
        {
		return -1;
        } // Call failed

	m_nTotalEntries = m_uzcs.returnCount;

	// If nothing, return error
	if (m_nTotalEntries < 1) 
        {
		return -1;
        } // No entries

	return GetNext( lpZ );

} // CZopen::GetFirst()

//------------------------------------------------------------------
// Get next entry in .ZIP file.  Returns -1 if error occurred or no
// more entries, else returns origin:0 index of entry.
//------------------------------------------------------------------
int CZopen::GetNext( ZIPINFO FAR *lpZ ) 
    {

	if (!m_lpZip || m_nTotalEntries < 1) 
        {
		return -1;
        } // No .ZIP, GetFirst not called, or end of list

	// Get next entry
	m_uzcs.function = UNZIP_GETNEXTZIPINFO;
	m_uzcs.zInfo = lpZ;
	m_uzcs.lpszFilespec = NULL;
	m_uzcs.index = -1;

	if ( Duz( &m_uzcs ) != UE_OK) 
        {
		return -1;
        } // Call failed

	return ( m_nCurEntry = lpZ->index);
    } // CZopen::GetNext()

//------------------------------------------------------------------
HINSTANCE LoadUnzipLibrary( LPSTR lpLibName )
    {
    HINSTANCE hlibRet;

#ifdef _WIN32
    if (( hlibRet = (HINSTANCE)LoadLibrary( lpLibName )) < (HINSTANCE)32 )
#else
    if ( (UINT)(hlibRet = LoadLibrary( lpLibName )) < 32 )
#endif
        {
        return ( HINSTANCE )NULL;
        }

    if ( !( lpfnDuz = 
        (LPFNDUZ)GetProcAddress( hlibRet, "dunzip") ))
        {
        goto duz_err_exit;
        }

    return hlibRet;
    
duz_err_exit:
    FreeLibrary( hlibRet );
    return ( HINSTANCE )NULL;
    }

//----------------------------------------------------------
// Copy unzip.dll from install disk to it's proper location.
//----------------------------------------------------------
int CopyUnzipDll()
    {
    BOOL bRet = TRUE;
    int nVCRet;
    UINT uCurLen = _MAX_PATH;
    UINT uDestLen = _MAX_PATH;
    char lpCurDirBuff[ _MAX_PATH + 2 ];
    char lpDestDirBuff[ _MAX_PATH + 2 ];

    uCurLen = _MAX_PATH;
    uDestLen = _MAX_PATH;

#ifdef _WIN32
    nVCRet = VerChkCopyFiles( szC_Unzip32Comp, lpProgPath, 
                              szC_Unzip32DLL, lpWinPath,
                              lpWinPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
#else
    nVCRet = VerChkCopyFiles( szC_UnzipComp, lpProgPath, 
                              szC_UnzipDLL, lpWinPath,
                              lpWinPath, lpCurDirBuff, &uCurLen, 
                              lpDestDirBuff, &uDestLen, VCCF_SHARED_RES );
#endif
    
    if( nVCRet = VCC_FILEINUSE )
        {
        nVCRet = VCC_SUCCESS;
        }

    return nVCRet;
    }
    
//------------------------------------------------------------------
// Close all files.
void CZopen::CloseAll( void ) 
    {
	int n;

    for (n = 0; n < MAXFILESOPEN; n++) 
        {
        if (m_nFiles[ n ] != -1) 
            {
			Close( n );
            }
        } // for all possible handles

    } // CZopen::CloseAll()

//------------------------------------------------------------------
// Close a single file.  If open for writing, commits it to the .ZIP file.
void CZopen::Close( int nFile ) 
    {
	_Close( nFile, TRUE );
    } // CZopen::Close()

// Close a file but don't commit to the .ZIP file
void CZopen::CloseAbort( int nFile ) 
    {
	_Close( nFile, FALSE );
    } // CZopen::CloseAbort()

// Close file and commit or not
void CZopen::_Close( int nFile, BOOL Commit ) 
    {
	if (!IsValid( nFile )) 
        {
		return;
        } // Not a valid handle

        
        // If file was open for input from .ZIP file, no action needed other
        // than marking it as closed.
	if (m_nFiles[ nFile ] >= 0) 
        {
            // Physically close the file
		_lclose( m_nFiles[ nFile ] );
        } // Writing to file

            // Mark file handle as available
	m_nFiles[ nFile ] = -1;
    } // CZopen::Close()

