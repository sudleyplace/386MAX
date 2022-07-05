// $Header:   P:/PVCS/MAX/STATUTIL/FCOPYVER.CPV   1.1   23 May 1996 13:32:30   HENRY  $
//
// FCOPYVER.CPP - Copy file with version and date comparisons
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//

#define STRICT
#include <windows.h>
#include <windowsx.h>
#include <ver.h>

#include <dos.h>
#include <io.h>

#include <statutil.h>

// Copy file from source to destination if one or more conditions
// are satisfied.  Both source and destination must be fully qualified
// pathnames.  Returns 1 if conditions satisfied and copy completed,
// 0 if conditions not satisfied, -1 if error occurred.
int CompFCopy( LPCSTR pszSource, LPCSTR pszDest, WORD wFlags ) {

	// First, if CFC_VER specified, see if copy is allowed.
	if (wFlags & CFC_VER) {

		DWORD dwBuffSize1, dwBuffSize2;
		DWORD dwVH1, dwVH2;

		if ((dwBuffSize1 = GetFileVersionInfoSize( pszSource, &dwVH1 )) &&
			(dwBuffSize2 = GetFileVersionInfoSize( pszDest,   &dwVH2 ))) {

			LPSTR lpBuff1, lpBuff2;
			int nRet = -1;
			HGLOBAL hg = GlobalAlloc( GMEM_MOVEABLE,
							(int)(dwBuffSize1 + dwBuffSize2 + 4) );

			if (!hg) return -1;

			lpBuff1 = (LPSTR)GlobalLock( hg );

			if (!lpBuff1) {
				GlobalFree( hg );
				return -1;
			} // Lock failed

			lpBuff2 = lpBuff1 + dwBuffSize1 + 1;

			// Now get version info
			if (GetFileVersionInfo( pszSource, dwVH1, dwBuffSize1, lpBuff1 )
			 && GetFileVersionInfo( pszDest, dwVH2, dwBuffSize2, lpBuff2 )) {

			 	DWORD dwSize1, dwSize2;
				VS_FIXEDFILEINFO FAR *lpVer1, FAR *lpVer2;

				VerQueryValue( lpBuff1, "\\", &lpVer1, &dwSize1 );
				VerQueryValue( lpBuff2, "\\", &lpVer2, &dwSize2 );

				if (dwSize1 && dwSize2) {

					if (lpVer1->dwFileVersionMS > lpVer2->dwFileVersionMS ||
						(lpVer1->dwFileVersionMS == lpVer2->dwFileVersionMS &&
						 lpVer1->dwFileVersionLS > lpVer2->dwFileVersionLS)) {
						nRet = CopyFile( pszSource, pszDest ) ? 1 : -1;
					} // Source is newer
					else nRet = 0; // OK, but no copy

				} // Got version info for both

			} // Got version info

			GlobalUnlock( hg );
			GlobalFree( hg );

			return nRet;

		} // Got version buffer sizes

	} // Version check specified

	// If CFC_ABSENT and destination is missing, do it
	if ((wFlags & CFC_ABSENT) && _access( pszDest, 00 )) {
		return CopyFile( pszSource, pszDest ) ? 1 : -1;
	} // Destination absent, do it

	// If CFC_NEWER, compare time / date
	if ((wFlags & CFC_NEWER) && !_access( pszDest, 00 )) {

		HFILE hf1, hf2;
		WORD wTime1, wDate1, wTime2, wDate2;
		int nRet;

		hf1 = _lopen( pszSource, READ | OF_SHARE_COMPAT );
		if (hf1 == HFILE_ERROR) return -1;

		hf2 = _lopen( pszDest, READ | OF_SHARE_COMPAT );
		if (hf2 == HFILE_ERROR) {
			_lclose( hf1 );
			return -1;
		} // Failed to open

		nRet = (!_dos_getftime( hf1, &wDate1, &wTime1 ) &&
				!_dos_getftime( hf2, &wDate2, &wTime2 ))
					? ((wDate1 > wDate2 ||
					    (wDate1 == wDate2 && wTime1 > wTime2))
					   ? 1 : 0)
					: -1;

		_lclose( hf1 );
		_lclose( hf2 );

		if (nRet > 0) {
			nRet = CopyFile( pszSource, pszDest ) ? 1 : -1;
		} // Source is newer

		return nRet;
		
	} // Check for newer source

	return 0; // Nothing to do

} // CompFCopy()

