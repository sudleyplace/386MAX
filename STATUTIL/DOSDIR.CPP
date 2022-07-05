// $Header:   P:/PVCS/MAX/STATUTIL/DOSDIR.CPV   1.2   30 Jul 1996 14:54:36   PETERJ  $
//
// DOSDIR.CPP - DOS-specific directory functions
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//

#include <string.h>
#include <stdlib.h>
#include <io.h>
#include <memory.h>
#include <direct.h>

#include <dosdefs.h>

#ifdef _WIN32
#include <32alias.h>

	#define	_SMALL_DATA	0
	#define	_SMALL_CODE	0
#else
  #if defined(_M_I86SM) || defined(_M_I86MM)
  	#define	_SMALL_DATA	1
  #else
    #define	_SMALL_DATA 0
  #endif
  #if defined(_M_I86SM) || defined(_M_I86CM)
  	#define	_SMALL_CODE	1
  #else
    #define	_SMALL_CODE	0
  #endif
#endif


// Exported functions
#ifdef __cplusplus
extern "C" {
#endif

// Assert trailing backslash.  May grow pathname by one character.
void
AssertBS( LPSTR lpDir ) {

	// Make sure it's a valid string
	if (!lpDir) {
		return;
	} // NULL pointer

	// Address last character
	int nEnd = _fstrlen( lpDir ) - 1;

	if (nEnd < 0) {
		return;
	} // Nothing to do

	if (lpDir[ nEnd ] != '/' && lpDir[ nEnd ] != '\\') {
		lpDir[ nEnd + 1 ] = '\\';
		lpDir[ nEnd + 2 ] = '\0';
	} // No backslash; add one

} // AssertBS()

// Remove trailing backslash unless root.
void
RemoveBS( LPSTR lpDir ) {

	if (!lpDir) {
		return;
	} // NULL pointer

	int nLast = _fstrlen( lpDir ) - 1;

	// Trim these a\ \1\ c:\foo\bar
	// but not these: \ c:\ (line can't end in backslash)
	if (nLast < 1 || (nLast == 2 && lpDir[ 1 ] == ':')) {
		return;
	} // Leave root cases alone

	if (lpDir[ nLast ] == '/' || lpDir[ nLast ] == '\\') {
		lpDir[ nLast ] = '\0';
	} // Clobber trailing backslash

} // RemoveBS()

// Action function for RecurseDir to create a directory
void
RDMkDir( LPCSTR lpDir ) {
#if _SMALL_DATA
	char szBuf[ _MAX_PATH ];
	_fstrcpy( szBuf, lpDir );
	_mkdir( szBuf );
#else
	_mkdir( lpDir );
#endif
} // RDMkDir()

// Recursively perform specified action on directory.  No slashes allowed
// (backslash only allowed as dir separator).
void
RecurseDir( LPSTR lpDir, void (*lpfn)(LPCSTR) ) {

	// Look for a separator
	LPSTR lpszSep = _fstrrchr( lpDir, '\\' );

	// If there's something after it, first try the operation on the previous
	// level.
	if (lpszSep && lpszSep[ 1 ]) {
		*lpszSep = '\0';
		RecurseDir( lpDir, lpfn );
		*lpszSep = '\\'; // Restore clobbered backslash
	} // Try previous

	// Now try the operation with this one
	lpfn( lpDir );

} // RecurseDir()

// Recursively create directory.  Upstream directories will be created
// as needed.  Returns 0 if directory's existence was confirmed, -1 if
// not.
int
RMakeDir( LPCSTR lpDir ) {

	char szDir[ _MAX_DIR ];
	char *pszSlash;

	_fstrcpy( szDir, lpDir );

	// Caller should already know it doesn't exist as some other type of file
	if (!_access( szDir, 00 )) {
		return 0;
	} // Directory already exists

	// Convert all slashes to backslashes
	while (pszSlash = strchr( szDir, '/' )) *pszSlash = '\\';

	// Recursively try to create
	RecurseDir( szDir, RDMkDir );

	// Try again to confirm
#if _SMALL_DATA
	_fstrcpy( szDir, lpDir );
	return _access( szDir, 00 ) ? -1 : 0;
#else
	return _access( lpDir, 00 ) ? -1 : 0;
#endif

} // RMakeDir()

// Get a valid backslash-terminated temp directory.  We'll get TMP
// or TEMP and verify that they exist; failing all else, we'll resort
// to the current working dir.
// (was)to \ (backslash)
void
GetTempDir( LPSTR lpDir ) {

	char *pszEnv = getenv( "TMP" );
	if (pszEnv && !_access( pszEnv, 00 )) {
		_fstrcpy( lpDir, pszEnv );
	} // Got TMP
	else if ((pszEnv = getenv( "TEMP" )) && !_access( pszEnv, 00 )) {
		_fstrcpy( lpDir, pszEnv );
	} // Got TEMP
	else {
//        _fstrcpy( lpDir, "\\" );
//		return;
        _getcwd( lpDir, _MAX_PATH );   
	} 

	AssertBS( lpDir );

} // GetTempDir()

#ifdef __cplusplus
} // extern "C"
#endif

