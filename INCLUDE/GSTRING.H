// $Header:   P:/PVCS/MAX/INCLUDE/GSTRING.H_V   1.0   02 Apr 1996 17:02:32   HENRY  $
//
// GSTRING.H - String allocation class
//
// Copyright (C) 1995-96 Qualitas, Inc.  GNU General Public License version 3.
//
// This is a CString-like class for low-level string operations.
// It doesn't have any overloaded operators or any fancy stuff yet.
// It is useful for strings that may grow to a large size (global
// memory is used and locked as needed).  It should NOT be used for
// a large number of instances as a selector is needed for each
// object.
//
// The implementation of this class may be statically linked from
// the appropriate model of STATUTIL (LSTUTIL.LIB, MSTUTIL.LIB).

#ifndef GSTRING_INCLUDED
#define	GSTRING_INCLUDED

class GString {

public:
// Constructor / destructor
	GString( void );

	~GString( void );

public:
// Public members and functions

	// Assign a new value.  Returns 0 if OK, else -1.
	int Assign( LPCSTR lpsz, int nLen = -1 );

	// Append a string.  Returns 0 if OK, else -1.
	int Append( LPCSTR lpsz, int nLen = -1 );

	// Free all global memory
	void Free( void );

	// Unlock buffer.
	void Unlock( void );

	// Returns a pointer to buffer
	LPSTR Ptr( void );

	// Returns length of buffer
	WORD GetLen( void );

	// Reallocates to a specified length.  Returns 0 if OK, else -1.
	int SetLen( int nLen = -1 );


protected:
// Private parts

	// Current handle
	HGLOBAL m_hMem;

	// Current pointer to start of buffer (NULL if not locked)
	LPSTR m_lpszPtr;

	// Current allocated length of buffer
	WORD m_wAlloc;

	// Current length used in buffer.  May be less than allocated length.
	// Stored as -1 if length is ASCIIZ string length.
	WORD m_wLength;

	// Current allocation blocking factor (minimum growth increment)
	WORD m_wGrowMin;

};

#endif

