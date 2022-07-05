//' $Header:   P:/PVCS/MAX/WINMXMZ/WINLNCH.C_V   1.4   30 May 1997 12:24:18   BOB  $
//
// WINLNCH.C - Windows launcher for Winmaxim
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//
// This program is a DOS executable stub for Winmaxim.exe.
//
// It determines free low DOS, finds WIN.COM in the PATH, then
// execls Windows with the free low DOS figure added to the command
// line.
//

#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <process.h>
#include <malloc.h>

#include <dosdefs.h>
#include <statutil.h>

// Calculate size of our PSP in paras
unsigned
OurPSPSize( void ) {
	unsigned retval;

	_asm {
		push es;

		mov	 ax,_psp;	// Get PSP
		dec	 ax;		// Back off to MAC segment
		mov	 es,ax; 	// Address it
		mov	 ax,es:[word ptr 3]; // Get length in paras
		inc	 ax;		// Add one for mac entry
		mov	 retval,ax;
		pop	 es;
	}
	return retval;
} // OurPSPSize()

static char szExe[] = "WIN.COM";
static char szEnv[] = "PATH";

// Try alternate path settings
void
TryAlternate( int nWhich, char *pszOut, const char *pszPath ) {

	// Note that this only affects the copy kept by the C run-time library
	fprintf( stderr, "Trying alternate %d:\n%s\n", nWhich, pszPath );
	_putenv( pszPath );

	_searchenv( szExe, szEnv, pszOut );

} // TryAlternate

int
main( int argc, char *argv[] ) {

	char szWinPath[ _MAX_PATH ];
	static char szPath1[] = "PATH=c:\\windows;c:\\win;c:\\win3;c:\\win31;c:\\win310;c:\\win311;c:\\";
	static char szPath2[] = "PATH=c:\\wfw;c:\\wfw3;c:\\wfw31;c:\\wfw310;c:\\wfw311";
	static char szPath3[] = "PATH=c:\\win95";
	char *ppszArgs[ 16 ];
	char szSize[ 64 ];
	char szArgs[ 256 ];
	int n, nTail;
	unsigned int wFreeParas;

	// Set heap growth granularity to 2K
	_amblksiz = 2048;

	// Determine free low DOS

	// This will fail, but will give us the largest free block size
	_dos_allocmem( 0xffff, &wFreeParas );

	//fprintf( stderr, "free paras = %u, bytes = %lu\n", wFreeParas, 16L * (unsigned long)wFreeParas );

	// Now get our PSP address
	wFreeParas += OurPSPSize();

	//fprintf( stderr, "our PSP = %u, bytes = %lu\n", OurPSPSize(), 16L * (unsigned long)OurPSPSize() );

	//fprintf( stderr, "total paras = %u, bytes = %lu\n", wFreeParas, 16L * (unsigned long)wFreeParas );

	// Find WIN.COM.  First check the path.
	_searchenv( szExe, szEnv, szWinPath );

	// Try a couple of other directories
	if (!szWinPath[ 0 ]) TryAlternate( 1, szWinPath, szPath1 );
	if (!szWinPath[ 0 ]) TryAlternate( 2, szWinPath, szPath2 );
	if (!szWinPath[ 0 ]) TryAlternate( 3, szWinPath, szPath3 );

	// If all else fails, piss and moan
	if (!szWinPath[ 0 ]) {
		fprintf( stderr, "WinMaxim: Unable to start %s\n", szExe );
		return -1;
	}

	// Now chain to windows
	ppszArgs[ 0 ] = szWinPath;
	for (n = 0; argv[ n ] && n < 14 && n < argc; n++) {
		ppszArgs[ n + 1 ] = argv[ n ];
	} // Copy args

	// Point to next entry in ppszArgs
	n++;

	// Add our size argument
	sprintf( szSize, "%u", wFreeParas / 64 );
	ppszArgs[ n++ ] = szSize;

	// Terminate the list
	ppszArgs[ n ] = NULL;

	// Nice try, but the 900-odd bytes _execl leaves at the top of
	// low DOS wreaks havoc with DOSMax...

	//// If successful, it shouldn't return
	//_execv( szWinPath, ppszArgs );
	//
	//return -1;

	// Works the same as _execv() (unfortunately)
	//_spawnv( _P_OVERLAY, szWinPath, ppszArgs );

	// Eats 22K within Windows - an unnecessary penalty
	//_spawnv( _P_OVERLAY, szWinPath, ppszArgs );

	// If ya want it done right, do it yerself...
	szArgs[ 0 ] = '\0';
	nTail = 0;
	for (n = 1; ppszArgs[ n ]; n++) {
		sprintf( &szArgs[ nTail + 1 ], " %s", ppszArgs[ n ] );
		nTail = strlen( &szArgs[ 1 ] );
	} // Set up command tail
	szArgs[ 0 ] = nTail;
	szArgs[ 1 + nTail ] = '\r';
	szArgs[ 2 + nTail ] = '\0';

	// Takes a program path (fully resolved) and a command tail.
	// The command tail must have a length byte, 0 or more bytes
	// of data (should have leading space), and a \r (not included
	// in the length).
	MyExecv( szWinPath, szArgs );

	return 0;

} // main

