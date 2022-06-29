// $Header:   P:/PVCS/MAX/STATUTIL/TDUTIL.CPV   1.1   23 May 1996 13:33:16   HENRY  $
//
// TDUTIL.CPP - Time / date utilities, low-level
//
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved.
//
// These utilities are used by QDServer for getting the current
// time / date as a DTIME value and for formatting DTIME values
// in the appropriate format.
//

#define STRICT
#include <windows.h>

#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

#include <ctimedt.h>
#include <statutil.h>

#ifdef __cplusplus
extern "C" {
#endif

// Values gotten from WIN.INI by FmtDTOnWinIniChange().
static int iTime;	// 0=12 hr, 1=24 hr clock
static int iTLZero;	// 0=no leading zero on hours, 1=leading zero on hours

static char sTime[ 5 ];	// Separator ":"
static char s1159[ 8 ];	// Suffix for time between 00:00 and 11:59 "AM"
static char s2359[ 8 ];	// Suffix for time between 12:00 and 23:59 "PM"
						// Also used as 24-hour time suffix
static char sShortDate[ 40 ]; // Short date picture using m, mm, d, dd, yy, yyyy
static char sLongDate[ 80 ]; // Long date picture

static char INI_INTL[] = "Intl";

// Derived values
static char szTimeFmt[ 32 ]; // wsprintf format for time

// Check to see if we've read INI settings yet.  If not, read 'em now.
// MUST be called by all functions that reference any values gotten from
// WIN.INI.
static void
CheckInit( void ) {

	static BOOL bGotIniData = FALSE;

	// Make sure we've gotten international stuff from WIN.INI
	if (!bGotIniData) {
		bGotIniData = TRUE;
		FmtDTOnWinIniChange();
	} // Didn't get INI data yet

} // CheckInit()

// Replace all instances of search string in source with replacement
// string, copying result to output buffer.  Case-sensitive if specified.
// Does no replacement within single quotes ('') and strips single quotes
// when copying to output.  Single quotes are escaped by doubling.
// Returns number of replacements made or -1 if input is bad.
int
ReplaceStr( LPCSTR lpSource,	 	// Source string to search in
			LPSTR lpOutput,			// Output buffer
			int cbDest,				// Output buffer length in bytes
			LPCSTR lpSearch,		// What to search for in source
			LPCSTR lpReplace,		// What to replace it with
			WORD wFlags ) {			// Flags listed above

	int nOff = 0;
	int nRes = 0;
	int nSLen, nRLen, nDOff;
	BOOL InQuotes = FALSE;
	char szFirstChar[ 3 ];
	char cCur;

	// Validate strings and length
	if (cbDest <= 0 || !lpSource || !lpOutput ||
		!lpSearch || !lpReplace) {
		return -1;
	} // Invalid parameters

	// Make sure we've copied something to the output buffer
	_fstrncpy( lpOutput, lpSource, cbDest );
	lpOutput[ cbDest - 1 ] = '\0';

	nSLen = _fstrlen( lpSearch );
	nRLen = _fstrlen( lpReplace );

	if (!nSLen) {
		return 0;
	} // Nothing to find

	// Create a strpbrk set for quick searching
	if (wFlags & REPLACESTR_CASE) {
		szFirstChar[ 0 ] = *lpSearch;
		szFirstChar[ 1 ] = '\0';
	} // Case sensitive
	else {
		szFirstChar[ 0 ] = toupper( *lpSearch );
		szFirstChar[ 1 ] = tolower( *lpSearch );
		szFirstChar[ 2 ] = '\0';
	} // Case insensitive

	nDOff = 0;

	// Search one character at a time for a match, skipping quoted sections.
	while (cCur = lpSource[ nOff ]) {

		// Note that InQuotes never gets set unless REPLACESTR_IGNQ is set...
		if (InQuotes) {

			if (cCur == '\'') {

				if (!(wFlags & REPLACESTR_STRIPQ)) {
					lpOutput[ nDOff ] = cCur;
					nDOff++;
				} // Not stripping quotes

				nOff++;
				cCur = lpSource[ nOff ];

				if (cCur != '\'') {

					// We've already got the offset of the next character in
					// our mitts, so we don't need to bump nOff...
					InQuotes = FALSE;

					continue;

				} // End quoted section

			} // Got a quote, check for end or escape

		} // Inside quoted string
		else if (cCur == '\'' && (wFlags & REPLACESTR_IGNQ)) {

			InQuotes = TRUE;
			if (wFlags & REPLACESTR_STRIPQ) {
				nOff++;
				continue;
			} // Stripping quotes

		} // Starting quotes
		else {

			if (strchr( szFirstChar, cCur )) {

				BOOL Matched;

				// Weed out partial matches
				if (wFlags & REPLACESTR_CASE) {
					Matched = !_fstrncmp( &lpSource[ nOff ], lpSearch, nSLen );
				} // Case sensitive
				else {
					Matched = !_fstrnicmp( &lpSource[ nOff ], lpSearch, nSLen );
				} // Case insensitive

				if (Matched) {

					// Bump replacement count
					nRes++;

					_fstrncpy( &lpOutput[ nDOff ], lpReplace, cbDest - nDOff );
					nDOff += nRLen;
					nOff += nSLen;

					continue;

				} // Got a match

			} // First character matches

		} // Not in quotes

		// Save current character in output stream
		lpOutput[ nDOff ] = cCur;

		nDOff++;
		nOff++;

	} // Not end of source string

	// Terminate it...
	lpOutput[ nDOff ] = '\0';

#if 0
	// This code does replacement without quote handling
	while (lpFound = _fstrpbrk( &lpSource[ nOff ], szFirstChar )) {

		// Weed out partial matches
		if (bCase) {
			if (_fstrncmp( lpFound, lpSearch, nSLen )) {
				nOff++;
				continue;
			} // Mismatch; continue with next character
		} // Case sensitive
		else {
			if (_fstrnicmp( lpFound, lpSearch, nSLen )) {
				nOff++;
				continue;
			} // Mismatch; continue with next character
		} // Case insensitive

		// Bump replacement count
		nRes++;

		// Copy data from source
		_fstrncpy( &lpOutput[ nDOff ], &lpSource[ nOff ], cbDest - nDOff );

		// Set new source and destination offsets
		nDOff += (int)(lpFound - (LPCSTR)&lpSource[ nOff ]);
		nOff = (int)(lpFound - lpSource);

		// Blast in replacement
		_fstrncpy( &lpOutput[ nDOff ], lpReplace, cbDest - nDOff );
		nDOff += nRLen;

		if (nDOff >= cbDest) {
			break;
		} // No more space

		// Now copy remainder of source string
		nOff += nSLen; // Skip search string
		_fstrncpy( &lpOutput[ nDOff ], &lpSource[ nOff ], cbDest - nDOff );

	} // Finding search string
#endif

	// Make sure it's null-terminated
	lpOutput[ cbDest - 1 ] = '\0';

	return nRes;

} // ReplaceStr()

// Get current date/time.  We do NOT write a trailing NULL to DTIME types.
void
GetDTime( DTIME dt ) {

	static struct _dosdate_t ddate;
	static struct _dostime_t dtime;
	char szdt[ sizeof( DTIME ) + 1 ];

	_dos_getdate( &ddate );
	_dos_gettime( &dtime );

	wsprintf( szdt, DTIME_FMTOUT,
			(int) ddate.year, (int) ddate.month, (int) ddate.day,
					dtime.hour, dtime.minute, dtime.second );
	strncpy( dt, szdt, sizeof( DTIME ) );

} // GetDTime()

// Format time only
LPCSTR
FmtTime( CTimeDate& td ) {

	static char szBuff[ 60 ];
	char *pszSuff;
	int nHour = td.Hour();

	// Make sure we're initialized
	CheckInit();

	// If 24-hour time, use s2359 as suffix
	pszSuff = iTime ? s2359 : s1159;

	if (!iTime && nHour > 12) {
		nHour -= 12;
		pszSuff = s2359;
	} // Use 12 hour clock
	else if (nHour == 12 && td.Minute()) {
		pszSuff = s2359;
	} // Use PM suffix only if at or after 12:01:00

	wsprintf( szBuff, szTimeFmt, nHour, td.Minute(), td.Second() );

	// Add suffix
	if (*pszSuff) {

		if (*pszSuff != ' ') {
			lstrcat( szBuff, " " );
		} // Separate it
		lstrcat( szBuff, pszSuff );

	} // Suffix specified

	return (LPCSTR)szBuff;

} // FmtTime()

// Used by FmtDate() and FmtDateLong()
static void
FmtDateSub( CTimeDate& td, char *pszBuff ) {

	char szBuff2[ 80 ];
#define BSIZE	sizeof( szBuff2 )

	// Search and replace, starting with the longest first.
	ReplaceStr( pszBuff, szBuff2, BSIZE, "yyyy", td.FmtYear( FMT_4D ),
		REPLACESTR_IGNQ );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "yy", td.FmtYear( FMT_2D ),
		REPLACESTR_IGNQ );

	// Do a two-stage replacement on the text formats, since they're
	// unfortunately longer than their numeric counterparts.
	ReplaceStr( pszBuff, szBuff2, BSIZE, "mmmm", "_[^4]_",
		REPLACESTR_IGNQ );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "mmm", "_[^3]_",
		REPLACESTR_IGNQ );
	ReplaceStr( pszBuff, szBuff2, BSIZE, "dddd", "_[$4]_",
		REPLACESTR_IGNQ );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "ddd", "_[$3]_", REPLACESTR_IGNQ );

	// Now we can proceed with numeric replacements
	ReplaceStr( pszBuff, szBuff2, BSIZE, "mm", td.FmtMonth( FMT_2D ),
		REPLACESTR_IGNQ );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "m", td.FmtMonth( FMT_1D ),
		REPLACESTR_IGNQ );
	ReplaceStr( pszBuff, szBuff2, BSIZE, "dd", td.FmtDay( FMT_2D ),
		REPLACESTR_IGNQ );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "d", td.FmtDay( FMT_1D ),
		REPLACESTR_IGNQ );

	// Finish the text replacements
	ReplaceStr( pszBuff, szBuff2, BSIZE, "_[^4]_", td.FmtMonth( FMT_TXT_LONG ),
		REPLACESTR_IGNQ | REPLACESTR_CASE );
	ReplaceStr( szBuff2, pszBuff, BSIZE, "_[^3]_", td.FmtMonth( FMT_TXT ),
		REPLACESTR_IGNQ | REPLACESTR_CASE );
	ReplaceStr( pszBuff, szBuff2, BSIZE, "_[$4]_", td.FmtDOW( FMT_TXT_LONG ),
		REPLACESTR_IGNQ | REPLACESTR_CASE );

	// On this one we need to strip the quotes
	ReplaceStr( szBuff2, pszBuff, BSIZE, "_[$3]_", td.FmtDOW( FMT_TXT ),
		REPLACESTR_IGNQ | REPLACESTR_CASE | REPLACESTR_STRIPQ );

} // FmtDateSub()

// Format date only
LPCSTR
FmtDate( CTimeDate& td ) {

	static char szBuff[ 80 ];

	// Make sure we're initialized
	CheckInit();

	_fstrcpy( szBuff, sShortDate );
	FmtDateSub( td, szBuff );

	return (LPCSTR)szBuff;

} // FmtDate()

// Format date in long format
LPCSTR
FmtDateLong( CTimeDate& td ) {

	static char szBuff[ 80 ];

	// Make sure we're initialized
	CheckInit();

	_fstrcpy( szBuff, sLongDate );
	FmtDateSub( td, szBuff );

	return (LPCSTR)szBuff;

} // FmtDateLong()

// Format DTIME value according to WIN.INI settings.  FmtDTOnWinIniChange()
// MUST be called whenever WM_WININICHANGE is received in the application's
// main window proc.  If UseLong is TRUE, date is displayed in long form.
LPCSTR
FmtDTime( LPCSTR lpDTime, BOOL UseLong ) {

	static char szBuff[ 80 ];
	static CTimeDate dt;

	// Make sure we're initialized
	CheckInit();

	// First create an ASCIIZ form
	_fstrncpy( (LPSTR)szBuff, lpDTime, sizeof( DTIME ) );
	szBuff[ sizeof( DTIME ) ] = '\0';

	dt.Assign( szBuff );

	wsprintf( szBuff, "%s %s", UseLong ? FmtDateLong( dt ) : FmtDate( dt ),
					FmtTime( dt ) );

	return (LPCSTR)szBuff;

} // FmtDTime()

// Called whenever WM_WININICHANGE is received in the application's
// main message loop.  Needed for time and date formatting.
void
FmtDTOnWinIniChange( void ) {

// Get the basic ingredients

#define PROF_GETINT(i,def)	i = GetProfileInt( INI_INTL, #i, def );
	PROF_GETINT( iTime, 1 );
	PROF_GETINT( iTLZero, 0 );

#define PROF_GETSTR(s,def)	\
		GetProfileString( INI_INTL, #s, def, s, sizeof( s ) ); \
		s[ sizeof( s ) - 1 ] = '\0';
	PROF_GETSTR( sTime, ":" );
	PROF_GETSTR( s1159, "AM" );
	PROF_GETSTR( s2359, "PM" );
	PROF_GETSTR( sShortDate, "yyyy/mm/dd" );
	PROF_GETSTR( sLongDate, "ddd, d mmm yyyy" );

	// Now build a time format string
	// This doesn't work.
	//wsprintf( szTimeFmt, "%%%s%s%%02d%s%%02d", iTLZero ? "02d" : "d", sTime, sTime );
	wsprintf( szTimeFmt, "%c%s%s" "%c02d%s" "%c02d",
		'%', (LPCSTR)(iTLZero ? "02d" : "d"), (LPCSTR)sTime,
			'%', (LPCSTR)sTime,
				'%' );

} // FmtDTOnWinIniChange()

// Parse time according to current WIN.INI Intl format ("9:30 pm", "23:15:20")
// Returns -1 if invalid format / value, 0 if OK.  Only sets m_dwTime
// portion of CTimeDate object.
int
ParseTime( CTimeDate& td, LPCSTR lp ) {

	// We'll be somewhat liberal in accepting the first matching character
	// of an AM/PM suffix, so "4:55 p" is interpreted correctly as "16:55".
	// We always take 24 hour time.  However, when 24 hour time is selected
	// in WIN.INI, we can't use s2359 as a PM indicator, so "5:15 pm" will
	// be interpreted as "5:15 am".
	char szSeps[ 64 ];
	char szCopy[ 128 ];
	char szPM[ 64 ];
	BOOL IsPM = FALSE;
	int nHour, nMinute, nSecond;
	char *pszHour, *pszMinute, *pszSecond;

	// Make sure we're initialized
	CheckInit();

	if (!lp) {
		return -1;
	} // Bad input

	// Make a copy all lower case
	_fstrncpy( szCopy, lp, sizeof( szCopy ) );
	_strlwr( szCopy );
	_fstrncpy( szPM, s2359, sizeof( szPM ) );
	_strlwr( szPM );

	// Look for the PM suffix first, then the first character (only if
	// it's not the same as the first character of the AM string)
	if (!iTime) {

		if (strstr( szCopy, szPM )) {

			IsPM = TRUE;

		} // Add 12 hours
		else if (szPM[ 0 ] != tolower( s1159[ 0 ] )) {

			if (strchr( szCopy, szPM[ 0 ] )) {
				IsPM = TRUE;
			} // Found first character "12:01p"

		} // First character differs

	} // Not on 24 hour time

	// Build a separator list with everything in it
	strcpy( szSeps, " :.," );
	strcat( szSeps, sTime );
	strcat( szSeps, s1159 );
	strcat( szSeps, s2359 );

	// Grab tokens and read their values
	pszHour = strtok( szCopy, szSeps );
	pszMinute = strtok( NULL, szSeps );
	pszSecond = strtok( NULL, szSeps );

	nHour = nMinute = nSecond = 0;
	if (pszHour) {
		nHour = atoi( pszHour );
	} // Read hour

	if (pszMinute) {
		nMinute = atoi( pszMinute );
	} // Read minute

	if (pszSecond) {
		nSecond = atoi( pszSecond );
	} // Read second

	// Add PM if specified and nHour < 12
	if (IsPM && nHour < 12) {
		nHour += 12;
	} // Adjust for PM

	// Set up assign value (using existing date)
	sprintf( szCopy, DTIME_FMTOUT, td.Year(), td.Month(), td.Day(),
			nHour, nMinute, nSecond );

	// Assign it and we're done
	td.Assign( (LPCSTR)szCopy );

	return 0;

} // ParseTime()

// Parse short date according to current WIN.INI Intl format ("1995/3/17",
// "3-17-95", etc).  Returns -1 if invalid format / value, 0 if OK.  Only
// sets m_dwEpoch portion of CTimeDate object.
int
ParseDate( CTimeDate& td, LPCSTR lp ) {

	// All we really care about in parsing is the order.  We'll look
	// for the separators used in sShortDate.  We'll ignore the difference
	// between yy and yyyy; if years are less than 100, add 1900.  If
	// less than 80, add 2000.
	char szSeps[ 64 ];
	char szCopy[ 128 ];
	char *psz;
	int i;

	// Make sure we're initialized
	CheckInit();

	if (!lp || strlen( sShortDate ) >= sizeof( szSeps ) - 6) {
		return -1;
	} // Bad input or date format is too long

	if (_fstrlen( lp ) >= sizeof( szCopy )) {
		return -1;
	} // Input too long

	// Start with some sensible separators
	_fstrcpy( szCopy, lp );
	strcpy( szSeps, " /-." );
	i = strlen( szSeps );

	// Add any non-digit characters in sShortDate to the list.
	for (psz = sShortDate; *psz; psz++) {

		if (isdigit( *psz )) {
			continue;
		} // Ignore digits in format string

		if (strchr( "yYmMdD", *psz )) {
			continue;
		} // Ignore data specifiers

		if (strchr( szSeps, *psz )) {
			continue;
		} // Already in separator list

		szSeps[ i ] = *psz; // Add it
		i++;
		szSeps[ i ] = '\0'; // Terminate separator list

	} // For everything in sShortDate

	// Now we have a separator list to use with strtok.  Determine the order.
	char *pszYear = strpbrk( sShortDate, "yY" );
	char *pszMonth = strpbrk( sShortDate, "mM" );
	char *pszDay = strpbrk( sShortDate, "dD" );

	// Parse the tokens
	char *pszTok1 = strtok( szCopy, szSeps );
	char *pszTok2 = strtok( NULL, szSeps );
	char *pszTok3 = strtok( NULL, szSeps );

	// Check for missing tokens
	if (!pszTok1 || !pszTok2 || !pszTok3) {
		return -1;
	} // Error

	if (pszYear <= pszMonth && pszMonth <= pszDay) {
		pszYear = pszTok1;
		pszMonth = pszTok2;
		pszDay = pszTok3;
	} // Y M D
	else if (pszYear <= pszDay && pszDay <= pszMonth) {
		pszYear = pszTok1;
		pszDay = pszTok2;
		pszMonth = pszTok3;
	} // Y D M
	else if (pszMonth <= pszYear && pszYear <= pszDay) {
		pszMonth = pszTok1;
		pszYear = pszTok2;
		pszDay = pszTok3;
	} // M Y D
	else if (pszMonth <= pszDay && pszDay <= pszYear) {
		pszMonth = pszTok1;
		pszDay = pszTok2;
		pszYear = pszTok3;
	} // M D Y
	else if (pszDay <= pszMonth && pszMonth <= pszYear) {
		pszDay = pszTok1;
		pszMonth = pszTok2;
		pszYear = pszTok3;
	} // D M Y
	else { // if ...
		pszDay = pszTok1;
		pszYear = pszTok2;
		pszMonth = pszTok3;
	} // D Y M

	// Adjust for century
	int nYear, nMonth, nDay;

	nYear = atoi( pszYear );
	nMonth = atoi( pszMonth );
	nDay = atoi( pszDay );

	if (nYear < 80) {
		nYear += 2000;
	} // Adjust for years 00-79 --> 2000-2079
	else if (nYear < 200) {
		nYear += 1900;
	} // Adjust for years 80-199 --> 1980-2199

	// Now prepare to assign
	sprintf( szCopy, DTIME_FMTOUT, nYear, nMonth, nDay,
			td.Hour(), td.Minute(), td.Second() );

	td.Assign( (LPCSTR)szCopy );

	return 0;

} // ParseDate()

#ifdef __cplusplus
}
#endif

