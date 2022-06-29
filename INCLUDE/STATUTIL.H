//' $Header:   P:/PVCS/MAX/INCLUDE/STATUTIL.H_V   1.4   28 May 1996 16:10:52   HENRY  $
//
// STATUTIL.H -- Prototypes and constants for functions in {L|M}STUtil.lib
//
// Copyright (C) 1994-96 Qualitas, Inc.  All rights reserved.
//

#ifndef STATUTIL_INCLUDED
#define STATUTIL_INCLUDED

#include <dtime.h>

#ifdef __cplusplus

#include <ctimedt.h>

extern "C" {
#endif

// Fills stack using any specified pattern (e.g. "StcK").
// Should be called at start of application, or at any
// time to reset stack as "untouched."
void FAR FillStack( char FAR *lpPattern );

// Returns number of bytes remaining untouched in stack.
unsigned int FAR VirginStack( void );

// Encrypt ASCIIZ string using weak encryption
// *** ALL CHARACTERS IN STRING MUST BE >= ' ' OR EMBEDDED NULLS
// *** MAY OCCUR.
// Encryption is done in place.
void
Encrypt( char FAR *lpsz );

// Decrypt ASCIIZ string encrypted by Encrypt().
// Decryption is done in place.
void
Decrypt( char FAR *lpsz );

// Assert trailing backslash.  May write an additional byte past
// current end of string (as you might expect when adding).
void
AssertBS( LPSTR lpDir );

// Remove trailing backslash unless root.
void
RemoveBS( LPSTR lpDir );

// Recursively create directory.  Upstream directories will be created
// as needed.  Returns 0 if directory's existence was confirmed, -1 if
// not.
int
RMakeDir( LPCSTR lpDir );

// Get a valid backslash-terminated temp directory.  We'll get TMP
// or TEMP and verify that they exist; failing all else, we'll resort
// to \ (backslash)
void
GetTempDir( LPSTR lpDir );

// Create temporary filename by serializing the file extension.
// Return TRUE if successful.
BOOL
CreateTempFName( LPSTR lpOutput, int cbOutput, LPCSTR lpTemplate );

// Get current date/time.  We do NOT write a trailing NULL to DTIME types.
void
GetDTime( DTIME dt );

// Determine if file is plain text or binary by checking first paragraph.
// Returns 0 if binary, 1 if plain text, 128 if upper ASCII,
// or -1 if unable to open file.
int
IsTextFile( LPCSTR lpPath );

#ifdef __cplusplus

// Format time only
LPCSTR
FmtTime( CTimeDate& td );

// Format date only (short format, such as 1995/3/5)
LPCSTR
FmtDate( CTimeDate& td );

// Format date in long format (Sunday, 5 Mar 1995)
LPCSTR
FmtDateLong( CTimeDate& td );

// Parse time according to current WIN.INI Intl format ("9:30 pm", "23:15:20")
// Returns -1 if invalid format / value, 0 if OK.  Only sets m_dwTime
// portion of CTimeDate object.
int
ParseTime( CTimeDate& td, LPCSTR lp );

// Parse short date according to current WIN.INI Intl format ("1995/3/17",
// "3-17-95", etc).  Returns -1 if invalid format / value, 0 if OK.  Only
// sets m_dwEpoch portion of CTimeDate object.
int
ParseDate( CTimeDate& td, LPCSTR lp );

#endif

// Format DTIME value according to WIN.INI settings.  FmtDTOnWinIniChange()
// MUST be called whenever WM_WININICHANGE is received in the application's
// main window proc.  If UseLong is TRUE, date is displayed in long form.
LPCSTR
FmtDTime( LPCSTR lpDTime, BOOL UseLong );

// Called whenever WM_WININICHANGE is received in the application's
// main message loop.  Needed for time and date formatting.
void
FmtDTOnWinIniChange( void );

#define	REPLACESTR_CASE		0x0001	// Matching is case-sensitive
#define	REPLACESTR_STRIPQ	0x0002	// Strip single quotes
#define	REPLACESTR_IGNQ		0x0004	// Ignore possible matches within quotes

// Replace all instances of search string in source with replacement
// string, copying result to output buffer.  Case-sensitive if specified.
// Returns number of replacements made or -1 if input is bad.
int
ReplaceStr( LPCSTR lpSource,	 	// Source string to search in
			LPSTR lpOutput,			// Output buffer
			int cbDest,				// Output buffer length in bytes
			LPCSTR lpSearch,		// What to search for in source
			LPCSTR lpReplace,		// What to replace it with
			WORD wFlags );			// Flags listed above

//------------------------------------------------------------------
// string stack list type.
//------------------------------------------------------------------
typedef struct tagSTRINGSTACK
    {
    void FAR *lpssPrev;
    void FAR *lpssNext;
    LPSTR lpStr;
    } STRSTACK, FAR *LPSTRSTACK;

// creates a stack and saves strings (filenames) on it. 
// These functions need a pointer to an LPSTRSTK that is initially = NULL.
// They return QSE_ error codes. 
int 
StrStkPush( LPSTRSTACK FAR *lplpssA, LPSTR lpStr );

// takes the same pointer to LPSTRSTACK (ie &lpssFile ),
// a return buffer and a length. 
// StrStkPop will return QSE_FUNCTIONFAILED when the stack is empty.
int 
StrStkPop( LPSTRSTACK FAR *lplpssA, LPSTR lpStrBuff, int cBufLen );

// Windows ANSI international version of _access.  Returns 0 if file has
// specified access or existence.
int Access( LPCSTR lpPath, int nMode );

// Hash a string to a 16-bit value.
WORD HashStr( LPCSTR lpsz );

#ifndef _WIN32
// Copy file from source to dest.
// pszSource and pszDest are both fully qualified pathnames.
// Return TRUE if action was successful.
BOOL CopyFile( LPCSTR pszSource, LPCSTR pszDest );
#endif

// Copy file from source to destination if one or more conditions
// are satisfied.  Both source and destination must be fully qualified
// pathnames.  Returns TRUE if conditions satisfied and copy completed.
BOOL CompFCopy( LPCSTR pszSource, LPCSTR pszDest, WORD wFlags );

#define	CFC_VER	0x0001	// Don't copy if dest version > source version
						// (regardless of other flags).  Copy if dest
						// version < source version.
#define	CFC_ABSENT 0x0002 // Copy if dest missing
#define	CFC_NEWER 0x0004 // Copy if source newer than destination

// You must link Lmyexecv.obj or Smyexecv.obj explicitly as the
// _first_ .obj file (not in ?stutil.lib).
// Executes another program, overlaying current space
int MyExecv( char FAR *lpCmd, char FAR *lpCmdTail );

#ifdef __cplusplus
}
#endif

#endif

