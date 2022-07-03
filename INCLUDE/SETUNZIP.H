// $Header:   P:/PVCS/MAX/INCLUDE/SETUNZIP.H_V   1.1   20 Jan 1997 08:41:06   PETERJ  $
//------------------------------------------------------------------
// SETUNZIP.H...A class for setup...stolen from...
// ZOPEN.H - Zip access class CZopen
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//------------------------------------------------------------------
#ifndef _SETUNZIP_INCLUDED
#define	_SETUNZIP_INCLUDED

#ifdef EXTERN
    #undef EXTERN
#endif

#ifdef DEFVAL
    #undef DEFVAL
#endif

#ifdef SETUNZIP_DEFVARS
    #define EXTERN
    #define DEFVAL(v) =v
#else
    #define EXTERN extern
    #define DEFVAL(v)
#endif

#ifndef UNZIPSTRUCT
  #ifdef _WIN16
    #include <dunzdll.h>
  #else
    #include <dunzip32.h>
  #endif
#endif

#define	MAXFILESOPEN	20
#define	OUTBUFFLEN	1024
#define	INBUFFLEN	16384

//------------------------------------------------------------------
EXTERN LPSTR szC_DUNZIPLib     DEFVAL( "DUNZIP.DLL" );
EXTERN LPSTR szC_DUNZIP32Lib   DEFVAL( "DUNZIP32.DLL" );

typedef int ( FAR PASCAL *LPFNDUZ) 
    (UNZIPCMDSTRUCT FAR * ucs);
EXTERN LPFNDUZ lpfnDuz;
#define Duz (*lpfnDuz)

extern "C" HINSTANCE LoadUnzipLibrary( LPSTR lpLibName );

#ifdef __cplusplus
extern "C" 
{
EXTERN HINSTANCE hlibDUNZIP DEFVAL( NULL );
#endif
// #ifdef __cplusplus
}

//------------------------------------------------------------------
class CZopen 
    {
public:
	CZopen( UINT wInst ) { _CZopen( wInst ); };

#ifdef STRICT
	CZopen( HINSTANCE hInst ) { _CZopen( (UINT)hInst ); }
#endif

	~CZopen( void );

	// Set current .ZIP file to use.  All files must be closed.
	// Returns 0 if successful, -1 if failed.
	int SetZip( LPCSTR lpZipPath );

	// Extract specified file(s) from .ZIP to specified directory.
	// Required directory components will be created if needed.
	// Returns -1 if failed or 0 if successful.
	int GetFromZip( LPCSTR lpFileList, LPCSTR lpOutDir, BOOL MakeDirs = TRUE );

	// Get first entry in a .ZIP file.  Returns -1 if failed.
	int GetFirst( ZIPINFO FAR *lpZ );

	// Get next entry in .ZIP file.  Returns -1 if error occurred or no
	// more entries, else returns origin:0 index of entry.
	int GetNext( ZIPINFO FAR *lpZ );

	// Close all files.
	void CloseAll( void );

	// Close a single file.  If open for writing, commits it to the .ZIP file.
	void Close( int nFile );

	// Close a file but don't commit to the .ZIP file
	void CloseAbort( int nFile );

	// Returns TRUE if a valid file handle
	BOOL IsValid( int nFile ) { return (nFile < MAXFILESOPEN && nFile >= 0 && m_nFiles[ nFile ] != -1); }

	// Returns TRUE if a file handle we can write to
	BOOL IsValidWrite( int nFile ) { return (nFile < MAXFILESOPEN && nFile >= 0 && m_nFiles[ nFile ] >= 0); }

protected:
	// Do the actual initialization
	void _CZopen( UINT wInst );

        // File we're currently closing (i.e. renaming)
    int m_nCurFile;

        // Instance handle
	HINSTANCE m_hInst;

    	// Full path of .ZIP file
	LPSTR m_lpZip;

	// Close file and commit or not
	void _Close( int nFile, BOOL Commit );

	UNZIPCMDSTRUCT m_uzcs;

// Table of file handles.  If -1, not used.  If -2, reading directly
// from .ZIP file to memory.
	int m_nFiles[ MAXFILESOPEN ];

        // Table of file names.  Format is InternalName\0ExternalName\0
        // where InternalName is the name within the .ZIP file and
        // ExternalName is the name of the temporary file (only applicable
        // if writing to file).
	LPSTR m_lpFNames[ MAXFILESOPEN ];

        // Input buffers.  These are needed for canonical file input.
	LPSTR m_lpInBuffs[ MAXFILESOPEN ];

        // Input buffer lengths.
	int m_nInBuffLens[ MAXFILESOPEN ];

	int m_nCurEntry;	// Index of current entry (-1 if GetFirst not called)
	int m_nTotalEntries; // Total entries in .ZIP file (-1 if GetFirst not called)
    };

#endif

