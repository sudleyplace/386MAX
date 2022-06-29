// $Header:   P:/PVCS/MAX/STATUTIL/ZOPEN.CPV   1.10   22 Jan 1997 14:57:16   PETERJ  $
//
// ZOPEN.CPP - Zip access class CZopen implementation
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

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

#define _DZIP_OWNER
#ifdef _WIN32
    #ifndef _INC_32ALIAS
        #include <32alias.h>
    #endif

	#define EXPORT16
    #include <dunzip32.h>
    #include <dzip32.h>
#else
	#define EXPORT16 __export
    #include <dunzdll.h>
    #include <dzipdll.h>
#endif
#undef _DZIP_OWNER

#include <zopen.h>

// Rename callback interface
extern "C" CALLBACK EXPORT16
CBRename( DZRENAME FAR *lpDZR, CZopen FAR *lpData ) {
	// For small model version, we can cast lpData to NEAR
#ifndef _WIN32
#ifdef _M_I86SM
	return ((CZopen NEAR *)lpData)->Rename( lpDZR );
#else
	return lpData->Rename( lpDZR );
#endif
#else
	return lpData->Rename( lpDZR );
#endif
} // CBRename()

// Unlink for small model
#if defined( _M_I86SM ) && !defined( _WIN32 )

// Copy far pointer to near and unlink file
void
FarUnlink( LPCSTR lpsz ) {

	char szBuff[ _MAX_PATH ];

	_fstrcpy( szBuff, lpsz );
	_unlink( szBuff );

} // FarUnlink()

#define	UNLINK(lpsz)	FarUnlink( lpsz )
#else
#define	UNLINK(lpsz)	_unlink( lpsz )
#endif

// Return an acceptable path for .ZIP file; drive letters are out
// as are leading slashes (apparently).
// PJ. Note this would have never worked for multiple files in a list.
// Also note. Now the caller must free the return value.
LPCSTR
ZipPath( LPCSTR lpInPath ) {
    LPSTR lpTemp;
    LPSTR lpTPtr;
    LPSTR lpPtr;

	lpTemp = (LPSTR)_fmalloc( lstrlen( lpInPath ) + 2 );

    if( lpTemp == NULL ) {
        return NULL;
    }
    
    lpTPtr = lpTemp;
    lpPtr = (LPSTR)lpInPath;

        // pick up the first quote if there is one.
	if ( *lpPtr == '\"') {
    *lpTPtr = (*lpPtr);
    lpPtr++;
    lpTPtr++;
    }
        
        // skip any drive designator.
	if ( *(lpPtr + 1) == ':' ) {
		lpPtr += 2;
	}

        // skip a leading slash.
	if ( *lpPtr == '/' || *lpPtr == '\\') {
		lpPtr++;
	}
        // now copy the rest of the string ( including end quote if present ).
    _fstrcpy( lpTPtr, lpPtr );
	return lpTemp;

} // ZipPath()

// Rename callback member function
int
CZopen::Rename( DZRENAME FAR *lpDZR ) {

    LPSTR lpTemp;
	if (IsValidWrite( m_nCurFile )) {

		// Change lpDZR->Name
        if(( lpTemp = (LPSTR) ZipPath( m_lpFNames[ m_nCurFile ] )) != NULL ){
            lstrcpy( lpDZR->Name, lpTemp );
            _ffree( lpTemp );
        }
	} // Valid file

	return 0;

} // CZopen::Rename()

// Common initialization code called by constructors

void CZopen::_CZopen( UINT wInst ) {

	m_lpZip = NULL;
	m_pszOutBuff = NULL;
	m_hInst = (HINSTANCE)wInst;

	// Set reasonable defaults in command structure
	memset( &m_zcs, 0, sizeof( m_zcs ) );
	m_zcs.zipStructSize = sizeof( m_zcs );

	m_zcs.compFactor = 5; // 0 = no compression, 9 = maximum (slowest)

	m_zcs.recurseFlag = 0;
	//m_zcs.function = ZIP_UPDATE;
	m_zcs.deleteOriginalFlag = FALSE;
	m_zcs.quietFlag = TRUE;

//    m_zcs.wZipSubOptions =  ZSO_MANGLELONGNAMES;

	// Don't add directory entries
	m_zcs.noDirectoryEntriesFlag = TRUE;

	// Set up rename callback (needed for zipping only)
	m_zcs.lpRenameUserData = (void FAR *)(CZopen FAR *)this;
	m_zcs.lpRenameProc = MakeProcInstance( (FARPROC)CBRename, (HINSTANCE)wInst );

	memset( &m_uzcs, 0, sizeof( m_uzcs ) );
	m_uzcs.unzipStructSize = sizeof( m_uzcs );

	m_uzcs.quietFlag = TRUE;
	m_uzcs.overWriteFlag = TRUE;
	m_uzcs.recurseFlag = TRUE;
//    m_uzcs.wUnzipSubOptions =  ZSO_MANGLELONGNAMES;

	// Mark all files as available
	memset( m_nFiles, 0xff, sizeof( m_nFiles ) );

	// Zap list of files
	memset( m_lpFNames, 0, sizeof( m_lpFNames ) );

	// Zap file input buffer list
	memset( m_lpInBuffs, 0, sizeof( m_lpInBuffs ) );
	memset( m_nInBuffLens, 0, sizeof( m_nInBuffLens ) );

} // CZopen::_CZopen()

// Standard destructor

CZopen::~CZopen( void ) {

	CloseAll();

	if (m_lpZip) {
		_ffree( (void FAR *)m_lpZip );
		m_lpZip = NULL;
	}

	if (m_pszOutBuff) {
		free( (void *)m_pszOutBuff );
		m_pszOutBuff = NULL;
	}

	if (m_zcs.lpRenameProc) {
		FreeProcInstance( m_zcs.lpRenameProc );
		m_zcs.lpRenameProc = NULL;
	}

} // ~CZopen()

// Member functions


// Set current .ZIP file to use.  All files must be closed.
// Returns 0 if successful, -1 if failed.
int CZopen::SetZip( LPCSTR lpZipPath ) {

	// Make sure files are closed
	CloseAll();

	if (m_lpZip) {
		_ffree( (void FAR *)m_lpZip );
	}
	m_lpZip = (LPSTR)_fmalloc( lstrlen( lpZipPath ) + 1 );

	m_nCurEntry = -1;
	m_nTotalEntries = -1;

	if (!m_lpZip) {
		return -1;
	} // Failed to allocate

	m_uzcs.lpszZIPFile = m_lpZip;
	m_zcs.lpszZIPFile = m_lpZip;

	lstrcpy( m_lpZip, lpZipPath );

	return 0;

} // CZopen::SetZip()


// Add one or more files, path and all, to .ZIP.
// Returns -1 if failed or 0 if successful.
int CZopen::AddToZip( LPCSTR lpFileList ) {

	m_zcs.lpszItemList = (LPSTR)lpFileList;

	// Move it into the .ZIP and rename it
	m_nCurFile = -1;
	m_zcs.function = ZIP_ADD;

	if (dzip( &m_zcs ) == ZE_OK) {
		return 0;
	} // Success

	return -1;

} // CZopen::AddToZip()

// Add one file, to .ZIP, providing quotes for long filenames.
// Returns -1 if failed or 0 if successful.
int CZopen::AddQToZip( LPCSTR lpFileList ) {
    int nRet;
    LPSTR lpTemp;
    
    if(( lpTemp = (LPSTR)_fmalloc( lstrlen( lpFileList ) + 10 )) != NULL ) {
            // add a quote to the beginning.
        lpTemp[0] = '\"';

            // then the filename.
        _fstrcpy( (LPSTR)&lpTemp[1], lpFileList);

            // add a quote to the end.
        _fstrcat( lpTemp, (LPSTR)"\"");
    
        nRet = AddToZip( lpTemp );
        _ffree( lpTemp );
        return nRet;
    }
        // error return.
    return (-1);
} // CZopen::AddQToZip()

    // get a single file with long filename quote support.
int CZopen::GetQFromZip( LPCSTR lpFileList, LPCSTR lpOutDir,
                            BOOL MakeDirs /*= TRUE*/ ) {
    int nRet;
    LPSTR lpTemp;
    
    if(( lpTemp = (LPSTR)_fmalloc( lstrlen( lpFileList ) + 10 )) != NULL ) {

        // add a quote to the beginning.
        lpTemp[0] = '\"';

            // then the filename.
        _fstrcpy( (LPSTR)&lpTemp[1], lpFileList);

            // add a quote to the end.
        _fstrcat( lpTemp, (LPSTR)"\"");
    
        nRet = GetFromZip( lpTemp, lpOutDir, MakeDirs );
    
        _ffree( lpTemp );
        return nRet;
    }
        // error return.
    return (-1);
}

// Extract specified file(s) from .ZIP to specified directory.
// Required directory components will be created if needed.
// Returns -1 if failed or 0 if successful.
int CZopen::GetFromZip( LPCSTR lpFileList, LPCSTR lpOutDir,
			BOOL MakeDirs /*= TRUE*/ ) {

	m_uzcs.function = UNZIP_EXTRACT;
	m_uzcs.zInfo = NULL;
	m_uzcs.lpszFilespec = (LPSTR)ZipPath( lpFileList );
	m_uzcs.index = -1;
	m_uzcs.lpszDestination = (LPSTR)lpOutDir;
	m_uzcs.noDirectoryNamesFlag = !MakeDirs;

	m_nCurFile = -1;

	int nRes = dunzip( &m_uzcs );

	m_uzcs.noDirectoryNamesFlag = 0;

    if( m_uzcs.lpszFilespec )
        {
        _ffree( m_uzcs.lpszFilespec );
        m_uzcs.lpszFilespec = NULL;
        }

	if (nRes == UE_OK) {
		return 0;
	}

	return -1;

} // CZopen::GetFromZip()

// Delete file from .ZIP.  Returns 0 if successful, -1 if failed.
int CZopen::DelFromZip( LPCSTR lpFileList ) {

	m_zcs.lpszItemList = (LPSTR)lpFileList;

	// Delete from .ZIP file
	m_nCurFile = -1;
	m_zcs.function = ZIP_DELETE;

	if (dzip( &m_zcs ) == ZE_OK) {
		return 0;
	} // Success

	return -1;

} // CZopen::DelFromZip()

// Open a file for read (ZOPEN_READ) or write (ZOPEN_WRITE).  Returns
// -1 if failed or handle if successful.  Handle may not be used with
// file operations outside this class.
int CZopen::Open( LPCSTR lpFile, char cMode ) {

	// First try to find an available handle
	int nFile;

	for (nFile = 0; nFile < MAXFILESOPEN; nFile++) {
		if (m_nFiles[ nFile ] == -1) break;
	}

	if (nFile >= MAXFILESOPEN) {
		return -1;
	} // No available handles

	// Reset line number count
	m_uLine[ nFile ] = 0;

	if (cMode == ZOPEN_READ) {

		ZIPINFO zi;

		// For some brain-dead reason, we must first call this function...
		m_uzcs.function = UNZIP_COUNTALLZIPMEMBERS;
		m_uzcs.zInfo = &zi;
		m_uzcs.lpszFilespec = (LPSTR)ZipPath( lpFile );
		m_uzcs.index = -1;
		m_uzcs.returnCount = 0;

		if (dunzip( &m_uzcs ) != UE_OK || m_uzcs.returnCount < 1) {
            if( m_uzcs.lpszFilespec ) {
                _ffree( m_uzcs.lpszFilespec );
                m_uzcs.lpszFilespec = NULL;
            }
			return -1;
		} // Call failed or none found

		// Get size (and incidentally make sure it exists)
		m_uzcs.function = UNZIP_GETNEXTNAMEDZIPINFO;
		m_uzcs.index = -1;
		m_uzcs.zInfo = &zi;

		if (dunzip( &m_uzcs ) != UE_OK) {
                // clean up for the next one.
            if( m_uzcs.lpszFilespec ) {
                _ffree( m_uzcs.lpszFilespec );
                m_uzcs.lpszFilespec = NULL;
            }
			return -1;
		} // Call failed

            // clean up anyway.
        if( m_uzcs.lpszFilespec ) {
            _ffree( m_uzcs.lpszFilespec );
            m_uzcs.lpszFilespec = NULL;
        }

		// Save just the pathname
		m_lpFNames[ nFile ] = _fstrdup( lpFile );
		if (!m_lpFNames[ nFile ]) {
			return -1;
		} // Unable to copy pathname

		// Allocate input buffer and initialize it
		m_lpInBuffs[ nFile ] = (LPSTR)_fmalloc( INBUFFLEN );
		if (!m_lpInBuffs[ nFile ]) {
			_ffree( m_lpFNames[ nFile ] );
			m_lpFNames[ nFile ] = NULL;
			return -1;
		} // Unable to allocate input buffer
		m_nInBuffLens[ nFile ] = 0;

		// Initialize offset within file and overall file size
		m_lFOffs[ nFile ] = 0L;
		m_lFLens[ nFile ] = zi.oSize;

		m_nFiles[ nFile ] = -2;

		return nFile;

	} // Open for read
	else if (cMode == ZOPEN_WRITE) {

		// Create a temp file name by hashing the path name
		char szTemplate[ 8 ];

		wsprintf( szTemplate, "Z_%04x", HashStr( lpFile ) );

		char szTempName[ _MAX_PATH ];

		if (!CreateTempFName( szTempName, sizeof( szTempName ), szTemplate )) {
			return -1;
		} // Couldn't create temp name

		m_lpFNames[ nFile ] = (LPSTR)_fmalloc( lstrlen( szTempName ) + 1
												+ lstrlen( lpFile ) + 1 );

		if (!m_lpFNames[ nFile ]) {
			return -1;
		} // malloc() failure

		lstrcpy( m_lpFNames[ nFile ], lpFile );
		lstrcpy( &m_lpFNames[ nFile ][ lstrlen( lpFile ) + 1 ], szTempName );

		// Make the filename all lowercase and replace \\ with / to be
		// consistent with normal .ZIP usage.
		LPSTR lpsz = m_lpFNames[ nFile ];
		_fstrlwr( lpsz );
		while (*lpsz && (lpsz = _fstrchr( lpsz, '\\' ))) {
			*lpsz = '/';
			lpsz++;
		} // while finding backslashes

		// Now try to open it
		HFILE hf = _lcreat( szTempName, 0 );

		if (hf == HFILE_ERROR) {
			_ffree( m_lpFNames[ nFile ] );
			m_lpFNames[ nFile ] = NULL;
			return -1;
		} // Failed to create file

		m_nFiles[ nFile ] = hf;

		return nFile;

	} // Create temp file for writing

	// Invalid cMode
	return -1;

} // CZopen::Open()

// Fill input buffer.  Return -1 if error or number of bytes read.
long CZopen::FillInBuff( int nFile ) {

	// Private function, assume handle is valid
    BOOL bSaveRec;
    
	// If buffer is partially full, do a partial read
	long lToRead = INBUFFLEN - m_nInBuffLens[ nFile ];

	// Check for EOF.
	if (lToRead + m_lFOffs[ nFile ] > m_lFLens[ nFile ]) {
		lToRead = (long)(m_lFLens[ nFile ] - m_lFOffs[ nFile ]);
	} // Determine actual bytes read


	// If buffer is completely full, return 0, which may be
	// misinterpreted as "no more data (i.e. EOF)"
	if (lToRead <= 0) {
		return 0;
	} // No room in buffer

	// Do the read
	//ZIPINFO zi;

	m_uzcs.function = UNZIP_FILETOMEM;
	m_uzcs.lpszFilespec = (LPSTR)ZipPath( m_lpFNames[ nFile ] );
	m_uzcs.index = -1;
	m_uzcs.lpMemBlock = &m_lpInBuffs[ nFile ][ m_nInBuffLens[ nFile ] ];
	m_uzcs.lMemBlockSize = lToRead;
	m_uzcs.lStartingOffset = m_lFOffs[ nFile ];
	//m_uzcs.zInfo = &zi;

    bSaveRec = m_uzcs.recurseFlag;
	m_uzcs.recurseFlag = FALSE;
	int nRes = dunzip( &m_uzcs );
    m_uzcs.recurseFlag = bSaveRec;
  
        // clean up.
    if( m_uzcs.lpszFilespec ) {
        _ffree( m_uzcs.lpszFilespec );
        m_uzcs.lpszFilespec = NULL;
    }

	lToRead = (long)m_uzcs.lMemBlockSize;

	m_uzcs.lpMemBlock = NULL;
	m_uzcs.lMemBlockSize = 0L;

	//m_uzcs.zInfo = NULL;

	if (nRes != UE_OK) {
		return -1;
	} // Call failed

	// Update offset.  We've already checked to ensure it doesn't go
	// past the logical EOF.
	m_lFOffs[ nFile ] += lToRead;

	// Update input buffer size per actual bytes read
	m_nInBuffLens[ nFile ] += lToRead;

	return lToRead;

} // CZopen::FillInBuff()

// Raw read.  No translation of CR/LF to LF is done.  Returns number of
// characters read if successful, -1 if error.
long CZopen::Read( int nFile, LPSTR lpBuff, unsigned nMax ) {

	if (IsValidWrite( nFile )) {
		return _lread( m_nFiles[ nFile ], lpBuff, nMax );
	} // Handle output file separately

	if (!IsValid( nFile )) {
		return -1;
	} // Not a valid handle

	long nRet = 0;
	unsigned nToRead;

	while (nMax > 0) {

		if (m_nInBuffLens[ nFile ] == 0) {
			if (FillInBuff( nFile ) < 0) {
				return -1;
			} // Error on read
		} // Need to fill input buffer

		nToRead = nMax;
		if (nToRead > (unsigned)m_nInBuffLens[ nFile ]) {
			nToRead = (unsigned)m_nInBuffLens[ nFile ];
		}

		nRet += (long)nToRead;
		if (!nToRead) {
			break;
		} // Nothing left

		_fmemcpy( lpBuff, m_lpInBuffs[ nFile ], nToRead );
		nMax -= nToRead;
		lpBuff += nToRead;
		m_nInBuffLens[ nFile ] -= nToRead;
		_fmemcpy( m_lpInBuffs[ nFile ], &m_lpInBuffs[ nFile ][ nToRead ], (unsigned)m_nInBuffLens[ nFile ] );

	} // Haven't filled buffer

	return nRet;

} // CZopen::Read()

// Raw write.  No translation of LF to CR/LF.  Returns number of
// characters written or -1 if error.  If nCount == -1, treat lpBuff
// as an ASCIIZ string.
int CZopen::Write( int nFile, LPCSTR lpBuff, int nCount /*= -1*/ ) {

	if (!IsValidWrite( nFile )) {
		return -1;
	} // Not open for writing

	if (nCount < 0) {
		nCount = lstrlen( lpBuff );
	} // Calculate write length

	return _lwrite( m_nFiles[ nFile ], lpBuff, nCount );

} // CZopen::Write()

// Read a line, including CR/LF.  Strip CR, leaving LF.  Guaranteed
// to terminate buffer with \0 even if truncating.  Returns buffer
// length if successful, -1 if failed.
long CZopen::ReadLine( int nFile, LPSTR lpBuff, unsigned nMax ) {

	if (IsValidWrite( nFile )) {
		return -1;
	} // Not supported

	if (!IsValid( nFile )) {
		return -1;
	} // Not a valid handle

	long nRet = 0;
	unsigned nToRead, nToSkip;
	LPSTR lpEnd = NULL;

	while (nMax > 0 && !lpEnd) {

		if (m_nInBuffLens[ nFile ] == 0) {
			if (FillInBuff( nFile ) < 0) {
				return -1;
			} // Error on read
		} // Need to fill input buffer

		nToRead = nMax;
		if (nToRead > (unsigned)m_nInBuffLens[ nFile ]) {
			nToRead = (unsigned)m_nInBuffLens[ nFile ];
		}

		if (!nToRead) {
			break;
		} // Nothing left

		lpEnd = (LPSTR)_fmemccpy( lpBuff, m_lpInBuffs[ nFile ], '\n', nToRead );

		nToSkip = nToRead;

		// If we found a NL lpEnd points to the character after it.
		if (lpEnd) {
			*lpEnd = '\0'; // Terminate in destination
			// If CR/LF, clobber the CR
			if (lpEnd[ -2 ] == '\r') {
				lpEnd--;
				lpEnd[ -1 ] = '\n'; // Replace with LF
				*lpEnd = '\0';
			} // Found a CR before LF
			nToRead = (int)(lpEnd - lpBuff);
			nToSkip = nToRead + 1;
		} // Got a newline

		nMax -= nToRead;
		nRet += (long)nToRead;
		lpBuff += nToRead;
        if( nToSkip > (unsigned)m_nInBuffLens[ nFile ] )
            {
            nToSkip = (unsigned)m_nInBuffLens[ nFile ];
            }
		m_nInBuffLens[ nFile ] -= nToSkip;
		_fmemcpy( m_lpInBuffs[ nFile ], &m_lpInBuffs[ nFile ][ nToSkip ], (unsigned)m_nInBuffLens[ nFile ] );

	} // Haven't filled buffer or found NL

	// Count another line read
	m_uLine[ nFile ]++;

	return nRet;

} // CZopen::ReadLine()

// Write a line, followed by CR/LF.  Returns number of characters
// (including CR/LF) written or -1 if error.  If nCount == -1, treat
// lpBuff as an ASCIIZ string.
int CZopen::WriteLine( int nFile, LPCSTR lpBuff, int nCount /*= -1*/ ) {

	if (!IsValidWrite( nFile )) {
		return -1;
	} // Can't write to file open for reading

	// Calculate count if needed
	if (nCount < 0) {
		nCount = lstrlen( lpBuff );
	}

	HFILE hf = m_nFiles[ nFile ];
	int n = _lwrite( hf, lpBuff, nCount );
	if (n != HFILE_ERROR) {
		int n2 = _lwrite( hf, "\r\n", 2 );
		if (n2 == HFILE_ERROR) {
			return -1;
		} // Error writing CR/LF
		n += n2;
	} // No error on write

	return n;

} // CZopen::WriteLine()

// Allocate output buffer.  If OK, return TRUE, else FALSE
BOOL CZopen::OutBuffOK( void ) {

	if (m_pszOutBuff) {
		return TRUE;
	} // Already exists

	m_pszOutBuff = (char *)malloc( OUTBUFFLEN + 1 );

	return (m_pszOutBuff != NULL);

} // CZopen::OutBuffOK()

// Format and write a la fprintf.  LF (\n) translated to CR/LF.
// Returns actual number of characters (including CR/LF) written or
// -1 if error.
int CZopen::zprintf( int nFile, const char *pszFmt, ... ) {

	va_list marker;
	int n;

	if (!OutBuffOK()) {
		return -1;
	} // Couldn't get output buffer

	va_start( marker, pszFmt );

	n = _vsnprintf( m_pszOutBuff, OUTBUFFLEN, pszFmt, marker );

	if (n > 0) {

		char *pszStart, *pszLF;
		int n2;

		n = 0;
		pszStart = m_pszOutBuff;

		do {

			pszLF = strchr( pszStart, '\n' );

			if (pszLF) {
				*pszLF = '\0';
				n2 = WriteLine( nFile, pszStart );
			} // Trailing LF, write CR/lF
			else {
				n2 = Write( nFile, pszStart );
			} // No trailing LF

			if (n2 < 0) {
				return n2;
			} // Error

			// Add to total
			n += n2;

			if (pszLF) {
				pszStart = pszLF + 1;
			} // Start at next character

		} while (pszLF);

	} // Formatted OK

	return n;

} // CZopen::zprintf()

// Returns current position in file a la _llseek() or -1L if error.
long CZopen::Tell( int nFile ) {

	if (!IsValid( nFile )) {
		return -1L;
	} // Not a valid file handle

	if (m_nFiles[ nFile ] == -2) {
		return m_lFOffs[ nFile ];
	} // Reading into memory
	else {
		// Seek 0 bytes from current position to get offset
		return _llseek( m_nFiles[ nFile ], 0L, 1 );
	} // Writing to a file

} // CZopen::Tell()

// Set current position in file.  FromWhere is 0 for start, 1 for
// signed relative to current position, or 2 for signed relative from
// end of file.  Returns new position or -1 if error.
long CZopen::Seek( int nFile, long lWhere, int FromWhere /*= 0*/ ) {

	if (!IsValid( nFile )) {
		return -1L;
	} // Not a valid handle

	if (m_nFiles[ nFile ] == -2) {

		if (FromWhere == 1) {
			lWhere += m_lFOffs[ nFile ];
		} // Relative to current position
		else if (FromWhere == 2) {
			lWhere += m_lFLens[ nFile ];
		} // Relative to end of file
		else if (FromWhere) {
			return -1L;
		} // Invalid FromWhere

		// Make sure it's in range.  We're not writing, so we can't write
		// past the end (or write anywhere else, for that matter).
		if (lWhere > m_lFLens[ nFile ]) {
			return -1L;
		} // Out of range

		m_lFOffs[ nFile ] = lWhere;

		// Invalidate input buffer
		m_nInBuffLens[ nFile ] = 0;

		return lWhere;

	} // Reading into memory
	else {

		// Reset line number count unless we're going nowhere
		if (FromWhere != 1 || lWhere) {
			m_uLine[ nFile ] = 0;
		} // Changing current offset

		return _llseek( m_nFiles[ nFile ], lWhere, FromWhere );
	} // Writing to disk

} // CZopen::Seek()

// Close all files.
void CZopen::CloseAll( void ) {

	int n;

	for (n = 0; n < MAXFILESOPEN; n++) {
		if (m_nFiles[ n ] != -1) {
			Close( n );
		}
	} // for all possible handles

} // CZopen::CloseAll()

// Close a single file.  If open for writing, commits it to the .ZIP file.
void CZopen::Close( int nFile ) {
	_Close( nFile, TRUE );
} // CZopen::Close()

// Close a file but don't commit to the .ZIP file
void CZopen::CloseAbort( int nFile ) {
	_Close( nFile, FALSE );
} // CZopen::CloseAbort()

// Close file and commit or not
void CZopen::_Close( int nFile, BOOL Commit ) {

	if (!IsValid( nFile )) {
		return;
	} // Not a valid handle

	// Free input buffer
	if (m_lpInBuffs[ nFile ]) {
		_ffree( m_lpInBuffs[ nFile ] );
		m_lpInBuffs[ nFile ] = NULL;
	} // Input buffer was allocated

	// If file was open for input from .ZIP file, no action needed other
	// than marking it as closed.
	if (m_nFiles[ nFile ] >= 0) {

		// Physically close the file
		_lclose( m_nFiles[ nFile ] );

		// Get temp name
		m_zcs.lpszItemList = m_lpFNames[ nFile ];
		m_zcs.lpszItemList += (1 + lstrlen( m_zcs.lpszItemList ));

		if (Commit) {

			// Move it into the .ZIP and rename it
			m_nCurFile = nFile;
			m_zcs.function = ZIP_ADD;

			int nZipErr = dzip( &m_zcs );
			if (nZipErr == ZE_OK) {

				// Delete the temp file
				UNLINK( m_zcs.lpszItemList );

			} // Success
			else {

				char szErrMsg[ 256 ];

				wsprintf( szErrMsg, "Error in %.220s", m_zcs.lpszItemList );
				MessageBox( NULL, ZIPerrors[ nZipErr ], szErrMsg, MB_OK );

			} // Failure, complain about it

		} // Committing to .ZIP file
		else {
			UNLINK( m_zcs.lpszItemList );
		} // Not committing

	} // Writing to file

	// Finally, free names
	_ffree( m_lpFNames[ nFile ] );
	m_lpFNames[ nFile ] = NULL;

	// Mark file handle as available
	m_nFiles[ nFile ] = -1;

} // CZopen::Close()

// Get first entry in a .ZIP file.  Returns -1 if failed.
int CZopen::GetFirst( ZIPINFO FAR *lpZ, LPSTR szName ) {

	// Make sure we have a .ZIP name
	if (!m_lpZip) {
		return -1;
	} // No .ZIP name

	// Assume failure
	m_nCurEntry = -1;

	// Get number of entries
    if( szName == NULL )
        {
        m_uzcs.function = UNZIP_COUNTALLZIPMEMBERS;
        m_uzcs.lpszFilespec = NULL;
        }
    else
        {
        m_uzcs.function = UNZIP_COUNTNAMEDZIPMEMBERS;
        m_uzcs.lpszFilespec = (LPSTR)ZipPath( szName );
        }

	m_uzcs.zInfo = NULL;
	m_uzcs.index = -1;
	m_uzcs.returnCount = 0;

	if (dunzip( &m_uzcs ) != UE_OK) {
        _ffree( m_uzcs.lpszFilespec );
		return -1;
	} // Call failed

    _ffree( m_uzcs.lpszFilespec );
	m_nTotalEntries = m_uzcs.returnCount;

	// If nothing, return error
	if (m_nTotalEntries < 1) {
		return -1;
	} // No entries

	return GetNext( lpZ, szName );

} // CZopen::GetFirst()

// Get next entry in .ZIP file.  Returns -1 if error occurred or no
// more entries, else returns origin:0 index of entry.
int CZopen::GetNext( ZIPINFO FAR *lpZ, LPSTR szName ) {

	if (!m_lpZip || m_nTotalEntries < 1) {
		return -1;
	} // No .ZIP, GetFirst not called, or end of list

	// Get next entry

    if( szName == NULL )
        {
        m_uzcs.function = UNZIP_GETNEXTZIPINFO;
        m_uzcs.lpszFilespec = NULL;
        }
    else
        {
        m_uzcs.function = UNZIP_GETNEXTNAMEDZIPINFO;
        m_uzcs.lpszFilespec = (LPSTR)ZipPath( szName );
        }

	m_uzcs.zInfo = lpZ;
	m_uzcs.index = -1;

	if (dunzip( &m_uzcs ) != UE_OK) {
        _ffree( m_uzcs.lpszFilespec );
		return -1;
	} // Call failed

    _ffree( m_uzcs.lpszFilespec );
	return (m_nCurEntry = lpZ->index);

} // CZopen::GetNext()
