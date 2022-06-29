// $Header:   P:/PVCS/MAX/INCLUDE/ZOPEN.H_V   1.7   05 May 1997 11:06:14   PETERJ  $
//
// ZOPEN.H - Zip access class CZopen
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#ifndef _ZOPEN_INCLUDED
#define	_ZOPEN_INCLUDED

// We can read directly into memory and keep track of the last offset,
// but writes need to go to a temp file and thence to the archive,
// with a rename along with way.

enum {
	ZOPEN_READ='r',
	ZOPEN_WRITE='w'
};

#define	MAXFILESOPEN 20
#define	OUTBUFFLEN	1024

#ifdef _WIN32
    #define	INBUFFLEN	16384
//    #define	INBUFFLEN	64000
#else
    #define	INBUFFLEN	16384
#endif

class CZopen {

public:
	CZopen( UINT wInst ) { _CZopen( wInst ); };

#ifdef STRICT
	CZopen( HINSTANCE hInst ) { _CZopen( (UINT)hInst ); }
#endif

	~CZopen( void );

	// Set current .ZIP file to use.  All files must be closed.
	// Returns 0 if successful, -1 if failed.
	int SetZip( LPCSTR lpZipPath );

	// Add one or more files, path and all, to .ZIP.
	// Returns -1 if failed or 0 if successful.
	int AddToZip( LPCSTR lpFileList );
    
    // same as above but single file only. Surrounds name with quotes.
	int AddQToZip( LPCSTR lpFileList );

	// Extract specified file(s) from .ZIP to specified directory.
	// Required directory components will be created if needed.
	// Returns -1 if failed or 0 if successful.
	int GetFromZip( LPCSTR lpFileList, LPCSTR lpOutDir, BOOL MakeDirs = TRUE );

        // same as above but single file only. Surrounds with quotes for long filenames.
	int GetQFromZip( LPCSTR lpFileList, LPCSTR lpOutDir, BOOL MakeDirs = TRUE );

	// Delete file from .ZIP.  Returns 0 if successful, -1 if failed.
	int DelFromZip( LPCSTR lpFileList );

	// Open a file for read (ZOPEN_READ) or write (ZOPEN_WRITE).  Returns
	// -1 if failed or handle if successful.  Handle may not be used with
	// file operations outside this class.
	int Open( LPCSTR lpFile, char cMode );

	// Raw read.  No translation of CR/LF to LF is done.  Returns number of
	// characters read if successful, -1 if error.
	long Read( int nFile, LPSTR lpBuff, unsigned nMax );

	// Raw write.  No translation of LF to CR/LF.  Returns number of
	// characters written or -1 if error.  If nCount == -1, treat lpBuff
	// as an ASCIIZ string.
	int Write( int nFile, LPCSTR lpBuff, int nCount = -1 );

	// Read a line, including CR/LF.  Strip CR, leaving LF.  Guaranteed
	// to terminate buffer with \0 even if truncating.  Returns buffer
	// length if successful, -1 if failed.
	long ReadLine( int nFile, LPSTR lpBuff, unsigned nMax );

	// Write a line, followed by CR/LF.  Returns number of characters
	// (including CR/LF) written or -1 if error.  If nCount == -1, treat
	// lpBuff as an ASCIIZ string.
	int WriteLine( int nFile, LPCSTR lpBuff, int nCount = -1 );

	// Format and write a la fprintf.  LF (\n) translated to CR/LF.
	// Returns actual number of characters (including CR/LF) written or
	// -1 if error.
	int zprintf( int nFile, const char *pszFmt, ... );

	// Returns current position in file a la _llseek() or -1L if error.
	long Tell( int nFile );

	// Set current position in file.  FromWhere is 0 for start, 1 for
	// signed relative to current position, or 2 for signed relative from
	// end of file.  Returns new position or -1 if error.
	long Seek( int nFile, long lWhere, int FromWhere = 0 );

	// Close all files.
	void CloseAll( void );

	// Close a single file.  If open for writing, commits it to the .ZIP file.
	void Close( int nFile );

	// Close a file but don't commit to the .ZIP file
	void CloseAbort( int nFile );

	// Get first entry in a .ZIP file.  Returns -1 if failed.
	int GetFirst( ZIPINFO FAR *lpZ, LPSTR szName = NULL );

	// Get next entry in .ZIP file.  Returns -1 if error occurred or no
	// more entries, else returns origin:0 index of entry.
	int GetNext( ZIPINFO FAR *lpZ, LPSTR szName = NULL );

	// Returns TRUE if a valid file handle
	BOOL IsValid( int nFile ) { return (nFile < MAXFILESOPEN && nFile >= 0 && m_nFiles[ nFile ] != -1); }

	// Returns TRUE if a file handle we can write to
	BOOL IsValidWrite( int nFile ) { return (nFile < MAXFILESOPEN && nFile >= 0 && m_nFiles[ nFile ] >= 0); }

	// Rename callback member function
	int Rename( DZRENAME FAR *lpDZR );

	// Return a handle we can use with _lwrite()
	HFILE Handle( int nFile ) { return IsValid( nFile ) ? m_nFiles[ nFile ] : HFILE_ERROR; }

	// Return origin:1 number of last line read via ReadLine()
	unsigned int LastLineNo( int nFile ) { return IsValid( nFile ) ? m_uLine[ nFile ] : 0; }

protected:
	// Do the actual initialization
	void _CZopen( UINT wInst );

	// Allocate output buffer.  If OK, return TRUE, else FALSE
	BOOL OutBuffOK( void );

	// Fill input buffer.  Return -1 if error or number of bytes read.
	long FillInBuff( int nFile );

	// Close file and commit or not
	void _Close( int nFile, BOOL Commit );

	// File we're currently closing (i.e. renaming)
	int m_nCurFile;

	// Instance handle
	HINSTANCE m_hInst;

	LPSTR m_lpZip;	// Full path of .ZIP file
	ZIPCMDSTRUCT m_zcs;
	UNZIPCMDSTRUCT m_uzcs;

// Table of file handles.  If -1, not used.  If -2, reading directly
// from .ZIP file to memory.
	int m_nFiles[ MAXFILESOPEN ];

// Table of line numbers.  Updated only on ReadLine()
	unsigned int m_uLine[ MAXFILESOPEN ];

// Current file offsets (only if reading from .ZIP file to memory)
// and file lengths.
	long m_lFOffs[ MAXFILESOPEN ];
	long m_lFLens[ MAXFILESOPEN ];

// Table of file names.  Format is InternalName\0ExternalName\0
// where InternalName is the name within the .ZIP file and
// ExternalName is the name of the temporary file (only applicable
// if writing to file).
	LPSTR m_lpFNames[ MAXFILESOPEN ];

// Input buffers.  These are needed for canonical file input.
	LPSTR m_lpInBuffs[ MAXFILESOPEN ];

// Input buffer lengths.
	long m_nInBuffLens[ MAXFILESOPEN ];

// Output buffer (used only by zprintf)
	char *m_pszOutBuff;

	int m_nCurEntry;	// Index of current entry (-1 if GetFirst not called)
	int m_nTotalEntries; // Total entries in .ZIP file (-1 if GetFirst not called)

};

#endif

