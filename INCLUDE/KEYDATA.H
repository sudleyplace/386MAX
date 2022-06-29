//' $Header:   P:/PVCS/MAX/INCLUDE/KEYDATA.H_V   1.0   25 Sep 1996 11:29:14   BOB  $

//****************************************************************************
// Key Data Structure
//
// This module must be sensitive to these environments:
//	1.	_WIN16
//	2.	_WIN32
//	3.	_WIN32 _UNICODE
//	4.	_WIN32 _UNICODEX
//****************************************************************************


typedef struct tagKEYDATA
{
	DWORD Repeat:16,		// Repeat count
		  ScanCode:8,		// Scan code (SSC_xxx)
		  ExtKey:1, 		// 1 iff extended key
		  :2,				// Unused
		  :2,				// Used internally by W
		  AltKey:1, 		// 1 iff Alt-key down
		  SameKey:1,		// 1 iff same key as last
		  ReleaseKey:1; 	// 1 iff key release (0 = key press)
} KEYDATA;


//***************************************************************************
//	End of File: KEYDATA.H 
//***************************************************************************
