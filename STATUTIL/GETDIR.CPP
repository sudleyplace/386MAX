// $Header:   P:/PVCS/MAX/STATUTIL/GETDIR.CPV   1.2   23 May 1996 13:32:42   HENRY  $
//
// GETDIR.CPP - Functions to build temporary filename.
//
// Copyright (C) 1995-96 Qualitas, Inc.  GNU General Public License version 3.
//

#define STRICT
#include <windows.h>

#include <string.h>
#include <stdlib.h>
#include <io.h>
#include <memory.h>
#include <direct.h>

#include <statutil.h>

#ifdef _WIN32
    #ifndef _INC_32ALIAS
        #include <32alias.h>
    #endif

	#define EXPORT16
    #include <dunzip32.h>
    #include <dzip32.h>
	#define	_SMALL_DATA	0
	#define	_SMALL_CODE	0
#else
	#define EXPORT16 __export
    #include <dunzdll.h>
    #include <dzipdll.h>
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

// Create temporary filename by serializing the file extension.
// Return TRUE if successful.
BOOL
CreateTempFName( LPSTR lpOutput, int cbOutput, LPCSTR lpTemplate ) {

	LPSTR lpExt;
	HFILE hf;
	static int nExt = 0;

	// Get a temp dir with trailing BS
	GetTempDir( lpOutput );

	_fstrcat( lpOutput, lpTemplate );

	// We're keeping the last serialization, but if it's close to the limit
	// recycle it.
	if (nExt >= 900) {
		nExt = 0;
	} // Start from the beginning

	hf = _lopen( lpOutput, READ | OF_SHARE_COMPAT );

	if (hf != HFILE_ERROR) {

		LPSTR lpSlash, lpLSlash, lpLDot;

		lpLSlash = lpOutput;
		while (lpSlash = _fstrpbrk( lpLSlash + 1, "/\\" )) {
			lpLSlash = lpSlash;
		} // Find last slash

		lpLDot = _fstrrchr( lpOutput, '.' );

		// If no trailing dot or it appears only in directory name, put one in.
		if (!lpLDot || lpLDot < lpLSlash) {
			_fstrcat( lpOutput, "." );
		} // Make sure there's an extension

		lpExt = _fstrrchr( lpOutput, '.' );
		if (!lpExt) {

			_lclose( hf );

			return FALSE;

		} // Shouldna happen...

	} // File exists, prepare to try extensions

	while (hf != HFILE_ERROR) {

		_lclose( hf );

		// Check for sufficient space in buffer (dot, nnn, \0)
		if ((int)(lpExt - lpOutput) + 1 + 3 + 1 > cbOutput) {
			return FALSE;
		} // Not enough room

		wsprintf( lpExt + 1, "%03d", nExt );
		nExt++;
		if (nExt > 999) {
			return FALSE;
		} // Ran out of extension serialization

		hf = _lopen( lpOutput, READ | OF_SHARE_COMPAT );

	} // File exists and is writable

	return TRUE;

} // CreateTempFName()

#ifdef __cplusplus
} // extern "C"
#endif

