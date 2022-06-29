// $Header:   P:/PVCS/MAX/WINMXMZ/FILECOPY.C_V   1.0   11 Nov 1995 08:44:36   HENRY  $
//
// FILECOPY.C - Copy file, preserving attributes
//
// Copyright (C) 1994 Qualitas, Inc.  All rights reserved.
//

#define STRICT
#include <windows.h>
#include <windowsx.h>

#include <dos.h>

// Copy file from source to dest.
// pszSource and pszDest are both fully qualified pathnames.
// Return TRUE if action was successful.
BOOL
CopyFile( LPCSTR pszSource, LPCSTR pszDest ) {

	int n1,n2;
	BOOL rtn;
	unsigned nbuf;
	unsigned dt,tm;
	char FAR* bigbuf = NULL;
	HFILE hf1, hf2;
	OFSTRUCT of2;
	HGLOBAL hg = NULL;

	hf1 = _lopen( pszSource, READ | OF_SHARE_COMPAT );
	if( hf1 == HFILE_ERROR ) {
		/* Unable to open file */
		return FALSE;
	}

	dt = tm = 0;
	_dos_getftime( hf1, &dt, &tm );

	hf2 = OpenFile( pszDest, &of2, OF_CREATE | OF_SHARE_COMPAT );
	if( hf2 == HFILE_ERROR ) {
		/* Unable to create file */
		// Try to create directory
		/****
		_splitpath( pszDest, MD_drive, MD_dir, MD_fname, MD_ext );
		CString Parent( MD_drive );
		Parent += MD_dir;
		StripBack( Parent );
		MakeDir( Parent );
		hf2 = OpenFile( pszDest, &of2, OF_CREATE | OF_SHARE_COMPAT );
		if( hf2 == HFILE_ERROR ) 
		***/
			goto error;
	}

#define MAXFILECOPYBUFF	0xfe00
#define	MINFILECOPYBUFF	512
	nbuf = MAXFILECOPYBUFF;
	do {
		hg = GlobalAlloc( GMEM_FIXED, nbuf );
		if (hg == NULL) {
			nbuf /= 2;
		}
	} while (hg == NULL && nbuf > MINFILECOPYBUFF);

	if( hg == NULL || (bigbuf = (char FAR*) GlobalLock( hg ) ) == NULL ) {
		/* Out of memory */
		goto error;
	}

	rtn = 1;
	while ((n1 = _lread( hf1, bigbuf, nbuf)) != 0) {

		if (n1 == HFILE_ERROR) {
			/* Read error */
			break;
		}
		n2 = _lwrite( hf2, bigbuf, n1);
		if (n2 == HFILE_ERROR) {
			/* Write error */
			break;
		}
		if (n2 != n1) {
			/* Out of disk space */
			goto error;
		}
	}

	GlobalUnlock( hg );
	GlobalFree( hg );
	_lclose( hf1 );

	_dos_setftime( hf2, dt, tm );
	_lclose( hf2 );

	return TRUE;

error:
	if (hf1 >= 0) _lclose(hf1);
	if (hf2 >= 0) _lclose(hf2);
	if( hg != NULL ) {
		GlobalUnlock( hg );
		GlobalFree( hg );
	}
	return FALSE;

} // CopyFile

