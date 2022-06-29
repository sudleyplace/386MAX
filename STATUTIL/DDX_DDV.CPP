// $Header:   P:/PVCS/MAX/STATUTIL/DDX_DDV.CPV   1.1   23 May 1996 13:30:38   HENRY  $
//
// DDX-DDV.CPP - DDX and DDV functions for use with MFC
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#include <afxwin.h>
//#include <afxext.h>

#include <stdlib.h>
#include <dos.h>

#include <statutil.h>
#include <statmfc.h>
#include <statres.h>


#ifdef _WIN32

// Replaces _dos_getfileattr()
int GetFAttr( LPTSTR lpFName, unsigned int *pwAttr ) {
	DWORD dw = GetFileAttributes( lpFName );
	if (dw == 0xffffffffL) {
		return -1;
	} // Failed to get it
	*pwAttr = (unsigned int)dw;
	return 0;
} // GetFAttr()

#define	GETFILEATTR(lpF,pwAttr)	GetFAttr( (LPTSTR)lpF, pwAttr )
#define	DIR_ATTRIB	FILE_ATTRIBUTE_DIRECTORY
#define	X_ATTRIB	(FILE_ATTRIBUTE_HIDDEN|FILE_ATTRIBUTE_READONLY|FILE_ATTRIBUTE_SYSTEM)
#else
#define	GETFILEATTR(lpF,pwAttr)	_dos_getfileattr( lpF, pwAttr )
#define	DIR_ATTRIB	_A_SUBDIR
#define	X_ATTRIB	(_A_HIDDEN | _A_RDONLY | _A_SYSTEM)
#endif

// Make sure it's a dir or no subset exists as something other than a dir
void AFXAPI
DDV_DirName( CDataExchange *pDX, LPCSTR lpDir ) {

	if (pDX->m_bSaveAndValidate) {

		unsigned wAttrs;
		char szDrive[ _MAX_DRIVE ], szDir[ _MAX_DIR ], szPath[ _MAX_PATH ];
		char szName[ _MAX_FNAME ];

		// We have a dir name.  It has to be existing as a directory,
		// or we have to make sure nothing upstream names a file.
		if (GETFILEATTR( lpDir, &wAttrs )) {

			// It doesn't exist.  Make sure we don't have an upstream
			// fragment that's a file.  The immediate upstream fragment
			// can't be a read-only, hidden or system directory, either.
			// We may have to create multiple levels of directories, so
			// as soon as we find an upstream directory we're done checking.
			do {

				// Remove a dir component from the end
				_splitpath( lpDir, szDrive, szDir, szName, NULL );
				strcpy( szPath, szDrive );
				strcat( szPath, szDir );
				RemoveBS( szPath );
				lpDir = szPath;

				// Now get attributes
				if (!GETFILEATTR( lpDir, &wAttrs )) {

					if (!(wAttrs & DIR_ATTRIB)) {

						AfxMessageBox( IDS_STAT_BADDIRNAME );
						pDX->Fail();

					} // Bad dir name
					else if (wAttrs & X_ATTRIB) {

						AfxMessageBox( IDS_STAT_BADDIRATTR );
						pDX->Fail();

					} // Not a subdir or bad attributes

					return; // Done checking now we've found a dir upstream

				} // File exists (we got the attributes successfully)

			// Minimum dir that can still be split: \a (into root and a)
			} while (lstrlen( lpDir ) > 1 && szName[ 0 ]);

			// If we fall through to here, assume we reached the root
			// (which doesn't have attributes).

		} // Not found
		else {

			// Fail if not a directory
			if (!(wAttrs & DIR_ATTRIB)) {

					AfxMessageBox( IDS_STAT_BADDIRNAME );
					pDX->Fail();

			} // Conflict with file
			else if (wAttrs & X_ATTRIB) {

					AfxMessageBox( IDS_STAT_BADDIRATTR );
					pDX->Fail();

			} // Bad attributes

			return;

		} // Found, make sure it's a directory

	} // We're validating

} // DDV_DirName()

