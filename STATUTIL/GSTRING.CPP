// $Header:   P:/PVCS/MAX/STATUTIL/GSTRING.CPV   1.1   16 Apr 1996 11:31:20   PETERJ  $
//
// GSTRING.CPP - GString class implementation.
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//

#define STRICT
#include <windows.h>

#include <string.h>

#ifdef _WIN32
    #ifndef _INC_32ALIAS
        #include <32alias.h>
    #endif
#endif

#include <gstring.h>

// Constructor
GString::GString( void ) {

	m_hMem = NULL;
	m_lpszPtr = NULL;
	m_wAlloc = 0;
	m_wLength = 0;
	m_wGrowMin = 256;

}

// Destructor
GString::~GString( void ) {
	Free();
}

// Public members and functions

// Assign a new value.  Returns 0 if OK, else -1.
int GString::Assign( LPCSTR lpsz, int nLen ) {

	LPSTR lpszExist;

	// FIXME do some string validation via LSL
	if (!lpsz || !*lpsz || !nLen) {
		return 0;
	} // Nothing to add

	// Determine length to add
	if (nLen == -1) {
		nLen = _fstrlen( lpsz );
	} // Get length to add

	if (SetLen( nLen ) < 0) {
		return -1;
	} // Couldn't allocate space

	if (lpszExist = Ptr()) {
		_fmemcpy( lpszExist, lpsz, nLen );
		lpszExist[ nLen ] = '\0';
	} // Copy new data
	else {
		return -1;
	} // Lock failed

	return 0;

} // GString::Assign()

// Append a string.  Returns 0 if OK, else -1.
int GString::Append( LPCSTR lpsz, int nLen ) {

	WORD wLength = m_wLength;
	LPSTR lpszExist;

	// FIXME do some string validation via LSL
	if (!lpsz || !*lpsz || !nLen) {
		return 0;
	} // Nothing to add

	// Determine length to add
	if (nLen == -1) {
		nLen = _fstrlen( lpsz );
	} // Get length to add

	if (wLength == (WORD)-1) {

		lpszExist = Ptr();

		if (!lpszExist) {
			return -1;
		} // Couldn't get existing string

		wLength = _fstrlen( lpszExist );

	} // Existing length needs to be calculated

	// Allocate space (with trailing NULL)
	if (SetLen( wLength + nLen )) {
		return -1;
	} // Failed to grow

	// Now append the string (or whatever)
	lpszExist = Ptr();
	if (!lpszExist) {
		return -1;
	} // Couldn't get pointer

	_fmemcpy( &lpszExist[ wLength ], lpsz, nLen );

	// Make sure there's a trailing NULL
	lpszExist[ m_wLength ] = '\0';

	return 0;

} // GString::Append()

// Free all global memory
void GString::Free( void ) {

	if (!m_wAlloc) {
		return;
	} // Nothing allocated

	Unlock();

	GlobalFree( m_hMem );

	m_hMem = NULL;
	m_wAlloc = 0;
	m_wLength = 0;

} // GString::Free()

// Unlock buffer.
void GString::Unlock( void ) {

	if (!m_wAlloc) {
		return;
	} // Nothing allocated

	if (m_lpszPtr) {
		GlobalUnlock( m_hMem );
		m_lpszPtr = NULL;
	} // Unlock it

} // GString::Unlock()

// Returns a pointer to buffer (after locking it)
LPSTR GString::Ptr( void ) {

	if (!m_wAlloc) {
		return NULL;
	} // Nothing allocated

	if (!m_lpszPtr) {
		m_lpszPtr = (LPSTR)GlobalLock( m_hMem );
	} // Lock it down

	return m_lpszPtr;

} // GString::Ptr()

// Returns length of buffer
WORD GString::GetLen( void ) {

	if (m_wLength == (WORD)-1) {

		LPCSTR lpsz = Ptr();

		if (lpsz) {
			return _fstrlen( lpsz );
		} // Got pointer
		else {
			return 0;
		} // Length unknown

	} // Get string length

	return m_wLength;

} // GString::GetLen()

// Reallocates to a specified length.  Returns 0 if OK, else -1.
int GString::SetLen( int nLen ) {

	LPCSTR lpsz;

	if (nLen == -1) {

		lpsz = Ptr();

		if (lpsz) {
			nLen = _fstrlen( lpsz );
		} // Got a pointer
		else {
			return -1;
		} // Error

	} // Calculate length from string

	// See if we need to grow.  Always allocate an extra byte for trailing NULL.
	if ((WORD)(nLen + 1) > m_wAlloc) {

		DWORD dwNewLen = (DWORD)(nLen + 1);

		// Round up to next block size unless already exact
		dwNewLen = ((dwNewLen + m_wGrowMin - 1) / m_wGrowMin) * m_wGrowMin;

		if (dwNewLen > 0xfff8) {
			dwNewLen = (DWORD)(nLen + 1);
		} // Too big

		// Check for grow vs. initial allocate
		if (m_wAlloc) {

			Unlock();
			if (GlobalReAlloc( m_hMem, dwNewLen, GMEM_ZEROINIT | GMEM_MOVEABLE ) == NULL) {
				return -1;
			} // Unable to grow

		} // Grow
		else {

			Unlock();
			m_hMem = GlobalAlloc( GMEM_SHARE | GMEM_ZEROINIT | GMEM_MOVEABLE,
						dwNewLen );

			if (m_hMem == NULL) {
				return -1;
			} // Allocate failed

		} // Initial allocate

		m_wAlloc = (WORD)dwNewLen;

	} // Reallocate

	// Save new length
	m_wLength = (WORD)nLen;

	return 0;

} // GString::SetLen()

