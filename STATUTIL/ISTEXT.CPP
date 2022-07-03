// $Header:   P:/PVCS/MAX/STATUTIL/ISTEXT.CPV   1.2   21 Jun 1996 15:31:34   PETERJ  $
//
// ISTEXT.CPP - Test for text / binary file
//
// Copyright (C) 1994-96 Qualitas, Inc.  GNU General Public License version 3.
//

#define	STRICT
#include <windows.h>

#include <stdio.h>
#include <string.h>

#include <statutil.h>


// Determine if file is plain text or binary by checking first paragraph.
// Returns 0 if binary, 1 if plain text, 128 if upper ASCII,
// or -1 if unable to open file.
extern "C" int
IsTextFile( LPCSTR lpPath ) {

#define	BUFFSIZE	256
	unsigned char szBuff[ BUFFSIZE + 1 ];
	HFILE hf = _lopen( lpPath, OF_READ | OF_SHARE_DENY_NONE );
	int nRes = -1;
	int nBytes;

	if (hf != HFILE_ERROR) {

		nBytes =  _lread( hf, szBuff, BUFFSIZE );

		_lclose( hf );

		if (!nBytes) {
			nRes = 1;
		} // Empty file; call it text
		else {

			int n;

			nRes = 1; // Hope for the best

// let binary take precedence over high text.
//			for (n = 0; n < nBytes && !(nRes & 0x80); n++) {
			for (n = 0; n < nBytes; n++) {

				// Ignore CR, LF, FF, HT, and EOF
				if (strchr( "\r\n\x0c\t\x1a", szBuff[ n ] )) {
					continue;
				} // Ignore this one

				if (szBuff[ n ] < ' ' || szBuff[ n ] == 127) {
					nRes = 0;
					break;
				} // Binary
				else if (szBuff[ n ] >= 128) {
					nRes = 0x80;
				} // High order
			} // Check for high text and binary
		} // Check data
	} // Opened successfully

	return nRes;

} // IsTextFile()

