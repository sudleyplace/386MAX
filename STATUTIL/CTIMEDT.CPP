// $Header:   P:/PVCS/MAX/STATUTIL/CTIMEDT.CPV   1.2   23 May 1996 13:30:32   HENRY  $
//
// CTIMEDT.CPP - Implementation of time / date manipulation class
//
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved.
//

#define STRICT
#include <windows.h>

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <statutil.h>
#include <ctimedt.h>
#include <dtstring.h>

// Days to add for non-leap and leap years for given month (Jan=0, Dec=11)
static int MTab[][ 2 ] = {
	0,		0,		// Jan
	31,		31,		// Feb
	59,		60,		// Mar
	90,		91,		// Apr
	120,	121,	// May
	151,	152,	// Jun
	181,	182,	// Jul
	212,	213,	// Aug
	243,	244,	// Sep
	273,	274,	// Oct
	304,	305,	// Nov
	334,	335,	// Dec
	365,	366		// Yr total
};

static char *MNames[] = {
	MONTH_JAN3,		MONTH_FEB3,		MONTH_MAR3,
	MONTH_APR3,		MONTH_MAY3,		MONTH_JUN3,
	MONTH_JUL3,		MONTH_AUG3,		MONTH_SEP3,
	MONTH_OCT3,		MONTH_NOV3,		MONTH_DEC3
};

static char *MNamesLong[] = {
	MONTH_JAN,		MONTH_FEB,		MONTH_MAR,
	MONTH_APR,		MONTH_MAY,		MONTH_JUN,
	MONTH_JUL,		MONTH_AUG,		MONTH_SEP,
	MONTH_OCT,		MONTH_NOV,		MONTH_DEC
};

static char *DNames[] = {
	DOW_SUN3,		DOW_MON3,		DOW_TUE3,		DOW_WED3,
	DOW_THU3,		DOW_FRI3,		DOW_SAT3
};

static char *DNamesLong[] = {
	DOW_SUN,		DOW_MON,		DOW_TUE,		DOW_WED,
	DOW_THU,		DOW_FRI,		DOW_SAT
};

static int
IsLeapYear( int nYear ) {
	// Every year evenly divisible by 4 is a leap year.
	// The only exception to this rule are years evenly divisible by 100
	// but NOT evenly divisible by 400.  1900 AD is NOT a leap year,
	// 2000 AD WILL be a leap year, 2100 will NOT be a leap year.
	return (!(nYear % 4) && ((nYear % 100) || !(nYear % 400)));
} // IsLeapYear()

// Returns 1 if nYear is a leap year, 0 if not
int
CTimeDate::IsLeap( void ) {
	return IsLeapYear( m_nYear );
} // CTimeDate::IsLeap()

// Define number of days, including leap year days, in 4 normal years.
#define	DAYSIN4YRS		(365L * 4L + 1)
// Define days in 100 normal years.  One set of leap years doesn't happen.
#define	DAYSIN100YRS	(DAYSIN4YRS * 25L - 1)
// Define days in 400 years.
#define DAYSIN400YRS	(DAYSIN100YRS * 4L + 1)

// Split epoch and time up into components
void
CTimeDate::Split( void ) {

	int nY, nLeap, n;
	DWORD dw = m_dwEpoch;

	// Get number of 400 year periods elapsed
	nY = (int)(dw / DAYSIN400YRS);
	dw -= (DAYSIN400YRS * nY);
	m_nYear = nY * 400;

	// Get number of centuries since last 400 year period began
	nY = (int)(dw / DAYSIN100YRS);
	dw -= (DAYSIN100YRS * nY);
	m_nYear += (nY * 100);

	// Get number of 4 year periods since start of century
	nY = (int)(dw / DAYSIN4YRS);
	dw -= (DAYSIN4YRS * nY);
	m_nYear += (nY * 4);

	// Add number of years since start of 4 year period
	nY = (int)(dw / 365);
	dw -= (365L * nY);
	m_nYear += nY;

	nLeap = IsLeap();

	// Search for correct month
	for (n = 1; n <= 12; n++) {
		if (MTab[ n ][ nLeap ] >= (int)dw) {
			break;
		} // Found the right month
	} // Searching month start table
	m_nMonth = n;

	// Calculate days remaining (origin:1)
	dw -= MTab[ m_nMonth - 1 ][ nLeap ];
	m_nDay = (int)dw;

	// Now split up time into hours, minutes and seconds
	dw = m_dwTime;

	// Hours are origin:0 (0 - 23)
	m_nHour = (int)(dw / 3600L);
	dw -= (m_nHour * 3600L);

	// Minutes are origin:0 (00 - 59)
	m_nMinute = (int)(dw / 60L);
	dw -= (m_nMinute * 60L);

	// Seconds are origin:0 (00 - 59)
	m_nSecond = (int)dw;

} // CTimeDate::Split()

// Create epoch from year, month, and day
DWORD
CTimeDate::YMDToEpoch( int nY, int nM, int nD ) {

	int nLeap;
	DWORD dw;

	// Check for invalid months and wrap to years
	if (nM > 12) {
		nY += (nM / 12);
		nM %= 12;
	} // Wrap months

	nLeap = IsLeapYear( nY ); // 1 if leap year, 0 if not

	dw = nD; // Start with days
	dw += MTab[ nM - 1 ][ nLeap ]; // Add number of days preceding
					// first of this month
	dw += (365L * nY); // Base days for years
	dw += (nY / 4); // Adjust for gross leap years
	dw -= (nY / 100); // Adjust for centurions, which are not leap years
	dw += (nY / 400); // Now add back in every fourth century

	return dw;

} // CTimeDate::YMDToEpoch()

// Assign from string, guaranteed 0 padded and null terminated
void
CTimeDate::_Assign( LPCSTR lpsz, int cb ) {

	char szNum[ DTIME_LEN * 2 + 1 ];

	assert( cb < sizeof( szNum ) );

	// Make sure input is fully padded with 0s
	_fstrncpy( szNum, lpsz, cb );
	szNum[ cb ] = '\0';

	if (strlen( szNum ) < DTIME_LEN) {
		strcat( szNum, DTIME_PAD );
	} // Pad input
	szNum[ DTIME_LEN ] = '\0';

	m_nYear = m_nMonth = m_nDay = 0;
	m_nHour = m_nMinute = m_nSecond = 0;

	sscanf( szNum, DTIME_FMTIN, &m_nYear, &m_nMonth, &m_nDay,
								&m_nHour, &m_nMinute, &m_nSecond );

	// Now build epoch
	m_dwEpoch = YMDToEpoch( m_nYear, m_nMonth, m_nDay );

	// Build time
	m_dwTime = 3600L * m_nHour;
	m_dwTime += 60L * m_nMinute;
	m_dwTime += m_nSecond;

} // CTimeDate::_Assign() (private version)

// Assign from another CTimeDate object
void
CTimeDate::Assign( CTimeDate& td ) {

	m_dwEpoch = td.m_dwEpoch;
	m_dwTime = td.m_dwTime;

	// We'll be a bit paranoid and split up raw values rather than
	// copying individual member data.
	Split();

} // CTimeDate::Assign()

// Assign a string to a date/time object
void
CTimeDate::Assign( LPCSTR lpDTime ) {

	_Assign( lpDTime, DTIME_LEN );

} // CTimeDate::Assign()

// Assign a DTIME object to a date/time object
void
CTimeDate::Assign( DTIME dt ) {

	_Assign( (LPCSTR)dt, sizeof( DTIME ) );

} // CTimeDate::Assign()

// Assign current time / date
void
CTimeDate::AssignNow( void ) {

	DTIME dtNow;

	GetDTime( dtNow );
	Assign( dtNow );

} // CTimeDate::AssignNow()

// Format and return external string representation of object
LPCSTR
CTimeDate::Str( void ) {
	wsprintf( m_szExtern, DTIME_FMTOUT, m_nYear, m_nMonth, m_nDay,
											m_nHour, m_nMinute, m_nSecond );
	return (LPCSTR)m_szExtern;
} // CTimeDate::Str()

LPDTIME
CTimeDate::DTime( void ) {
	_fstrncpy( (LPSTR)m_dt, Str(), sizeof( DTIME ) );
	return m_dt;
} // CTimeDate::DTime()

// Compare two objects.  Return -1 if less than compared object, 0 if
// equal, or 1 if greater.
int
CTimeDate::Comp( CTimeDate FAR& ct ) {
	if (m_dwEpoch < ct.m_dwEpoch) {
		return -1; // Less
	} // Epoch is less
	else if (m_dwEpoch > ct.m_dwEpoch) {
		return 1; // Greater
	} // Epoch is greater
	else {
		if (m_dwTime < ct.m_dwTime) {
			return -1;
		} // Less
		else if (m_dwTime > ct.m_dwTime) {
			return 1;
		} // Greater
		return 0; // Equal
	} // Epoch is same, compare everything else
} // CTimeDate::Comp()

// Overloaded comparison operators
BOOL
CTimeDate::operator<( CTimeDate ct ) {
	return (Comp( ct ) < 0);
} // CTimeDate::<

BOOL
CTimeDate::operator>( CTimeDate ct ) {
	return (Comp( ct ) > 0);
} // CTimeDate::>

BOOL
CTimeDate::operator==( CTimeDate ct ) {
	return (Comp( ct ) == 0);
} // ==

BOOL
CTimeDate::operator!=( CTimeDate ct ) {
	return (Comp( ct ) != 0);
} // !=

BOOL
CTimeDate::operator<=( CTimeDate ct ) {
	return (Comp( ct ) <= 0);
} // <=

BOOL
CTimeDate::operator>=( CTimeDate ct ) {
	return (Comp( ct ) >= 0);
} // >=

// Add an object to this one.  Return -1 if overflow occurred, 0 if OK.
int
CTimeDate::Add( CTimeDate& ct ) {
	return Add( ct.m_dwEpoch, ct.m_dwTime );
} // CTimeDate::Add

int
CTimeDate::Add( DWORD dwE, DWORD dwT ) {

	int nRes;
	DWORD dwEOp;
	DWORD dwTOp;

	dwEOp = m_dwEpoch;
	dwTOp = m_dwTime;

#ifdef _WIN32
#error Need USE32 version of ASM code
#else
	_asm {
		mov	ax,dwT[ word ptr 0 ];	// Get low word of time operator
		add	dwTOp[ word ptr 0 ],ax;	// Add to low word of time operand
		mov	ax,dwT[ word ptr 2 ];	// Get high word of time operator
		adc dwTOp[ word ptr 2 ],ax;	// Add to high word of time operand

		sbb	ax,ax;					// AX = ffff if overflow occurred
		mov	nRes,ax;				// Save result

		mov	ax,dwE[ word ptr 0 ];	// Get low word of epoch operator
		adc	dwEOp[ word ptr 0 ],ax;	// Add to low word of epoch operand
		mov	ax,dwE[ word ptr 2 ];	// Get high word of epoch operator
		adc	dwEOp[ word ptr 2 ],ax;	// Add to high word of epoch operand

		sbb	ax,ax;					// AX = ffff if overflow occurred
		or	nRes,ax;				// Save result
	}
#endif

	m_dwEpoch = dwEOp;
	m_dwTime = dwTOp;

#define SECONDSIN24HRS	(60L * 60L * 24)
	if (m_dwTime >= SECONDSIN24HRS) {
		m_dwEpoch += (m_dwTime / SECONDSIN24HRS);
		m_dwTime %= SECONDSIN24HRS;
	} // Wrap seconds

	Split();

	return nRes;

} // CTimeDate::Add()

// Add relative times
//int
//CTimeDate::Add( int nY, int nM, int nD, int nH, int nMn, int nS ) {
//	return -1;
//} // CTimeDate::Add

// Add relative times from YYYYMMDDHHMMSS string
//int
//CTimeDate::Add( LPCSTR lpAdd ) {
//	return -1;
//} // CTimeDate::Add

// Subtract an object from this one.  Return -1 if underflow occurred, 0 if OK.
int
CTimeDate::Subtract( CTimeDate& ct ) {
	return Subtract( ct.m_dwEpoch, ct.m_dwTime );
} // CTimeDate::Subtract()

int
CTimeDate::Subtract( DWORD dwE, DWORD dwT ) {

	int nRes;
	DWORD dwEOp;
	DWORD dwTOp;

	dwEOp = m_dwEpoch;
	dwTOp = m_dwTime;

#ifdef _WIN32
#error Need Use32 version  of ASM code
#else
	_asm {
		mov	ax,dwT[ word ptr 0 ];	// Get low word of time operator
		sub	dwTOp[ word ptr 0 ],ax;	// Sub from low word of time operand
		mov	ax,dwT[ word ptr 2 ];	// Get high word of time operator
		sbb dwTOp[ word ptr 2 ],ax;	// Sub from high word of time operand

									// Underflow here is acceptable

		mov	ax,dwE[ word ptr 0 ];	// Get low word of epoch operator
		sub	dwEOp[ word ptr 0 ],ax;	// Sub from low word of epoch operand
		mov	ax,dwE[ word ptr 2 ];	// Get high word of epoch operator
		sbb	dwEOp[ word ptr 2 ],ax;	// Sub from high word of epoch operand

		sbb	ax,ax;					// AX = ffff if underflow occurred
		mov	nRes,ax;				// Save result
	}
#endif

	while ((long)m_dwTime < 0) {
		m_dwEpoch--;
		m_dwTime += SECONDSIN24HRS;
	} // Wrap seconds

	m_dwEpoch = dwEOp;
	m_dwTime = dwTOp;

	Split();

	return nRes;

} // CTimeDate::Subtract()

// Formatting subfunction.  Returns pointer to static buffer or text array
// element.  All text indices are origin:1.
static LPCSTR
FmtSub( char *pszBuff,		// Output buffer for numeric types
		int nText,			// Number of text array elements
		char **ppTextShort,	// Short text array or NULL
		char **ppTextLong,	// Long text array or NULL
		int nVal,			// Actual value
		int nFmt ) {		// Format specifier (FMT_D1, etc.)

	// First check for text formatting requests we can't fill
	if (nFmt == FMT_TXT || nFmt == FMT_TXT_LONG) {

		if (!nText || !ppTextShort || !ppTextLong) {
			strcpy( pszBuff, "<Bad req>" );
			return (LPCSTR)pszBuff;
		} // No text

		if (nVal < 1 || nVal > nText) {
			strcpy( pszBuff, "<Bad ndx>" );
			return (LPCSTR)pszBuff;
		} // Out of range

		if (nFmt == FMT_TXT) {
			return (LPCSTR)ppTextShort[ nVal - 1 ];
		} // Short format
		else {
			return (LPCSTR)ppTextLong[ nVal - 1 ];
		} // Long format

	} // Check text format requests for invalid or out of range

	// Format numeric formats
	switch (nFmt) {

		case FMT_1D:
			wsprintf( pszBuff, "%d", nVal );
			break;

		case FMT_2D:
			wsprintf( pszBuff, "%02d", nVal % 100 );
			break;

		case FMT_4D:
			wsprintf( pszBuff, "%04d", nVal );
			break;

		default:
			strcpy( pszBuff, "<Bad fmt>" );
			break;

	} // switch()

	return (LPCSTR)pszBuff;

} // FmtSub()

// Format functions.  Each returns a pointer to its own internal static
// buffer for numeric formats.

LPCSTR
CTimeDate::FmtYear( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 0, NULL, NULL, m_nYear, nFmt );
} // CTimeDate::FmtYear

LPCSTR
CTimeDate::FmtMonth( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 12, MNames, MNamesLong, m_nMonth, nFmt );
} // CTimeDate::FmtMonth

LPCSTR
CTimeDate::FmtDay( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 0, NULL, NULL, m_nDay, nFmt );
} // CTimeDate::FmtDay

LPCSTR
CTimeDate::FmtDOW( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 7, DNames, DNamesLong, DOW(), nFmt );
} // CTimeDate::FmtDOW

LPCSTR
CTimeDate::FmtHour( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 0, NULL, NULL, m_nHour, nFmt );
} // CTimeDate::FmtHour

LPCSTR
CTimeDate::FmtMinute( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 0, NULL, NULL, m_nMinute, nFmt );
} // CTimeDate::FmtMinute

LPCSTR
CTimeDate::FmtSecond( int nFmt ) {
	static char szBuff[ 24 ];
	return FmtSub( szBuff, 0, NULL, NULL, m_nSecond, nFmt );
} // CTimeDate::FmtSecond

