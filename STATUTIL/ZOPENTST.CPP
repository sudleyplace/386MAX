// $Header:   P:/PVCS/MAX/STATUTIL/ZOPENTST.CPV   1.1   09 Apr 1996 03:35:22   HENRY  $
//
// ZOPENTST.CPP - Testbed for CZopen class
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//

#define STRICT
#include <windows.h>

#include <stdio.h>
#include <stdlib.h>
#include <io.h>

#include <dunzdll.h>
#include <dzipdll.h>

#include "zopen.h"

#define	MSGOUT(s)	MessageBox( NULL, s, "Zopen test v1.0", MB_OK )

char szBuff[ 512 ];

#define	MSGOUT1(fmt,a1)	{ wsprintf( szBuff, fmt, a1 ); MSGOUT( szBuff ); }
#define	MSGOUT2(fmt,a1,a2) { wsprintf( szBuff, fmt, a1, a2 ); MSGOUT( szBuff ); }
#define	MSGOUT3(fmt,a1,a2,a3) { wsprintf( szBuff, fmt, a1, a2, a3 ); MSGOUT( szBuff ); }

extern "C" int PASCAL
WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance,
		 LPSTR lpCmdLine,  int nCmdShow) {

	MSGOUT( "Testing CZopen" );

	CZopen cz( hInstance );

	// Zip file to use
	char szZip[] = "c:\\tmp\\zopentst.zip";

	// File to write as output
	char szFile[] = "c:\\foo\\bar\\anyfile.txt";

	_unlink( szZip );
	cz.SetZip( szZip );

	MSGOUT1( "Using .ZIP file\n%s", szZip );

	// Now create a file
	int nRes, n;
	
	n = cz.Open( szFile, ZOPEN_WRITE );

	if (n < 0) {
		MSGOUT1( "Unable to create %s", szFile );
	}
	else {

		MSGOUT1( "Opened file, handle = %d", n );

		nRes = cz.WriteLine( n, "Line 1 of test file" );

		MSGOUT1( "WriteLine Result = %d", nRes );

		nRes = cz.zprintf( n, "Writing to file %s, last result = %d\nThird line ", szZip, nRes );

		MSGOUT1( "zprintf Result = %d", nRes );

		nRes = cz.Write( n, "ending\r\n" );

		MSGOUT1( "Write Result = %d", nRes );

		long lRes = cz.Tell( n );

		MSGOUT1( "Tell result = %ld", lRes );

		lRes = cz.Seek( n, 0L, 0 );

		MSGOUT1( "Seek 0 result = %ld", lRes );

		nRes = cz.Write( n, " -<Replace line 1>-" );

		MSGOUT1( "Write after seek, result = %d", nRes );

		lRes = cz.Seek( n, 5, 0 );
		lRes = cz.Seek( n, 4, 1 );

		MSGOUT1( "Seek 1 result = %ld (should be 9)", lRes );

		lRes = cz.Seek( n, 0, 2 );

		MSGOUT1( "Seek 2 result = %ld", lRes );

		//nRes = cz.Write( n, "String\r\nwith nulls\0\0\0\r\n", 23 );

		//MSGOUT1( "Write result = %d", nRes );

		cz.Close( n );

	} // Opened file for write

	// Test read functions
	n = cz.Open( szFile, ZOPEN_READ );

	if (n < 0) {
		MSGOUT1( "Unable to open %s for reading", szFile );
	}
	else {

		MSGOUT2( "Opened %s, handle = %d", szFile, n );

		// First, a raw read
		char szReadBuff[ 256 ];

		nRes = cz.Read( n, szReadBuff, sizeof( szReadBuff ) );
		if (nRes < 0) {
			MSGOUT( "Unable to read" );
		}
		else {
			szReadBuff[ nRes ] = '\0';
			MSGOUT2( "Read %d characters:\n%s", nRes, szReadBuff );
		} // Read OK

		// Go back to start
		cz.Seek( n, 0L, 0 );

		// Now try a line read
		while (cz.ReadLine( n, szReadBuff, sizeof( szReadBuff ) ) > 0) {
			MSGOUT1( "Got\n%s----", szReadBuff );
		} // not EOF

		cz.Close( n );

	} // Opened file

	// Try adding a file
	_unlink( "\\tmp\\config.sys" );
	if (cz.AddToZip( "c:\\config.sys" ) < 0) {
		MSGOUT( "Unable to add config.sys" );
	} // Couldn't add
	else {
		if (cz.GetFromZip( "c:\\config.sys", "c:\\tmp\\" ) < 0) {
			MSGOUT( "Unable to get Config.sys from zip" );
		} // Couldn't get
		else {
			MSGOUT( "Added and extracted config.sys" );
		} // Success
	} // Try extracting

	// Test GetFirst / GetNext
	ZIPINFO zi;

	if (cz.GetFirst( &zi ) != -1) {

		do {
			MSGOUT2( "Entry %d: %s", zi.index, zi.szFileName );
		} while (cz.GetNext( &zi ) != -1);

	} // Got first
	else {
		MSGOUT( "Unable to get first .ZIP file entry" );
	} // Didn't get it

	// Test DelFromZip()
	if (cz.DelFromZip( "C:\\config.sys" ) < 0) {
		MSGOUT( "Unable to delete config.sys from zip file" );
	} // Failed

	MSGOUT( "Deleted CONFIG.SYS\nDone" );

	return FALSE;

} // WinMain()

