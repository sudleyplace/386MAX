// $Header:   P:/PVCS/MAX/INCLUDE/CTIMEDT.H_V   1.2   23 May 1996 13:27:38   HENRY  $
//
// CTIMEDT.H -- Class declaration for time / date manipulation
//
// Copyright (C) 1995-96 Qualitas, Inc.  GNU General Public License version 3.
//
// Implementation is in LSTUTIL.LIB.
//

#ifndef CTIMEDT_INCLUDED
#define CTIMEDT_INCLUDED

#ifndef __cplusplus
#error Can't compile this without C++
#endif

#include <dtime.h>

// Format types used in FmtYear, FmtMonth, FmtDay, etc.
enum {
	FMT_1D,		// 1 or 2 digits, no leading zero
	FMT_2D,		// 2 digits with leading zero
	FMT_4D,		// 4 digits with leading zero
	FMT_TXT,	// Short text format ("Sun", "Jan", etc.)
	FMT_TXT_LONG // Long text format ("Sunday", "January", etc.)
};

// Simple class to handle time and date comparisons.
// Well, it's not that simple...

class CTimeDate {

public:
// Constructor / destructor
CTimeDate( void ) { Assign( "" ); };
CTimeDate( LPCSTR lpDTime ) { Assign( lpDTime ); };
CTimeDate( CTimeDate& td ) { Assign( td ); };

~CTimeDate( void ) {};

// Public members
public:
	DWORD m_dwEpoch; // Days elapsed since 12/31/1979 (1/1/1980 = 1)
					// (at least in theory; actually days since an imaginary
					//  date 1,980 years prior).
	DWORD m_dwTime;	// Seconds elapsed since midnight (12:01AM = 1,
					//									midnight = 24 * 3600)

// Overloaded comparison operators
	int Comp( CTimeDate FAR& ct ); // Returns -1 if < ct, 0 if ==, 1 if greater
	BOOL operator<( CTimeDate ct );
	BOOL operator>( CTimeDate ct );
	BOOL operator==( CTimeDate ct );
	BOOL operator!=( CTimeDate ct );
	BOOL operator<=( CTimeDate ct );
	BOOL operator>=( CTimeDate ct );

// Assign a YYYYMMDDHHMMSS value or another CTimeDate object
	void Assign( LPCSTR lpDTime );
	void Assign( DTIME dt );
	void Assign( CTimeDate& td );

// Assign current time/date to this object
	void AssignNow( void );

// Returns pointer to static buffer formatted as DTIME (YYYYMMDDHHMMSS).
// DTime() happens to be NULL terminated.
	LPCSTR Str( void );
	LPDTIME DTime( void );

// Time / date arithmetic
	int Add( CTimeDate& ct );
	//int Add( int nY, int nM, int nD, int nH, int nMn, int nS );
	//int Add( LPCSTR lpAdd );
	int Add( DWORD dwE, DWORD dwT );
	int Subtract( CTimeDate& ct );
	int Subtract( DWORD dwE, DWORD dwT );

	int Year( void ) { return m_nYear; };
	int Month( void ) { return m_nMonth; };
	int Day( void ) { return m_nDay; };
	int IsLeap( void );
	int DOW( void ) { return (int)((m_dwEpoch + 7L - 1L) % 7) + 1; }; // Sun = 1, Sat = 7

	int Hour( void ) { return m_nHour; };
	int Minute( void ) { return m_nMinute; };
	int Second( void ) { return m_nSecond; };

// Format functions.  Each returns a pointer to its own internal static
// buffer for numeric formats.
	LPCSTR FmtYear( int nFmt = FMT_4D );
	LPCSTR FmtMonth( int nFmt = FMT_1D );
	LPCSTR FmtDay( int nFmt = FMT_1D );
	LPCSTR FmtDOW( int nFmt = FMT_TXT_LONG );

	LPCSTR FmtHour( int nFmt = FMT_1D );
	LPCSTR FmtMinute( int nFmt = FMT_2D );
	LPCSTR FmtSecond( int nFmt = FMT_2D );

// Overloaded operators
public:

// Private members
protected:
	// Split epoch and time up into components
	void Split( void );

	// Create epoch from year, month, and day
	DWORD YMDToEpoch( int nY, int nM, int nD );

	// Assign from raw string
	void _Assign( LPCSTR lpsz, int cb );

	int m_nYear, m_nMonth, m_nDay;
	int m_nHour, m_nMinute, m_nSecond;
	char m_szExtern[ 32 ]; // External representation as "YYYYMMDDHHMMSS"
	DTIME m_dt;

};


#endif

