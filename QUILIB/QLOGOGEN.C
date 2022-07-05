// $Header:   P:/PVCS/MAX/QUILIB/QLOGOGEN.C_V   1.0   01 Mar 1996 17:38:24   HENRY  $
//
// QLogoGen.C -- Program to convert QLOGO.OVL to translatable formats
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//
// This program will generate a .INC file from a binary QLOGO.OVL file


#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <memory.h>
#include <sys\types.h>
#include <sys\stat.h>

typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned long  DWORD;

BYTE Buff[ 8192 ];

// Translate value to binary
char *Binary( WORD w, int nBits ) {

	static char szBuff[ 40 ];
	WORD wMask = 0x0001;

	strcpy( szBuff, "0000000000000000" );
	szBuff[ nBits-- ] = '\0';

	for ( ; nBits >= 0; nBits--) {
		if (w & wMask) szBuff[ nBits ] = '1';
		wMask <<= 1;
	}

	return szBuff;

} // Binary()

// Dump one character set.  Return number of bytes translated or -1 if invalid
int Translate( char *pszLead, char *pszComment, BYTE *pB, int cbLen ) {

	int nChars = *((WORD *)pB);
	int n, n2;
	char szBuff[ 128 ];
	BYTE *pB2, *pBOrg = pB;

	pB += sizeof( WORD );

	printf( "; %s - %d characters\n\n", pszComment, nChars );

	printf( "	public w%sCount\nw%sCount	dw	0%04xh\n\n", pszLead, pszLead, nChars );

	// Dump text as db
	printf( "	public b%sLogo\nb%sLogo	label byte\n", pszLead, pszLead );
	for (n = 0; n < 12; n++) {
		printf( "	db	'" );
		memcpy( szBuff, pB, 22 );
		pB += 22;
		szBuff[ 22 ] = '\0';
		printf( "%s'\n", szBuff );
	} // for all lines

	printf( "\n; For sort:\n\n" );

	// Now dump all characters in hex for sort
	for (pB2 = pB, n = 0; n < nChars; n++) {
		printf( "; " );
		for (n2 = 0; n2 < 14; n2++) {
			printf( "%02x%s", pB2[ n2 ], n2 == 8 ? " " : "" );
		}
		printf( "\t(%03d %s)\n", n + 127, pszLead );
		pB2 += 14;
	} // Dump for sort

	printf( "\n\n; Actual data:\n\n" );

	for (n = 0; n < nChars; n++) {
		printf( "	public	b%sChar%03d\n", pszLead, 127 + n );
		printf( "; %c (%d, %02xh)\n", 127 + n, 127 + n, 127 + n );
		printf( "b%sChar%03d	label byte\n", pszLead, 127 + n );
		for (n2 = 0; n2 < 14; n2++) {
			printf( "	db	%sb\n", Binary( pB[ n2 ], 8 ) );
		}
		printf( "\n\n" );
		pB += 14;
	}

	return (int)(pB - pBOrg);

} // Translate

int main( int argc, char *argv[] ) {

	int n;
	int nFH;
	int nRet = -1;
	int nBytes;

	if (argc < 2) {
		fprintf( stderr, "No file specified\n" );
		return -1;
	}

	nFH = _open( argv[ 1 ], _O_BINARY | _O_RDONLY );
	if (nFH < 0) {
		fprintf( stderr, "Can't open %s\n", argv[ 1 ] );
		return -1;
	}

	nBytes = _read( nFH, Buff, sizeof( Buff ) );
	if (nBytes < 2 || *((unsigned int *)Buff) * 14 + 12 * 22 + 2 > nBytes) {
		fprintf( stderr, "Data looks bad.\n" );
	}
	else nRet = 0;

	_close( nFH );

	if (!nRet) {

		n = Translate( "Q", "\"Q\" logo", Buff, nBytes );
		if (n > 0 && n < nBytes) {
			n = Translate( "A", "\"ASQ\" logo", &Buff[ n ], nBytes - n );
			if (n <= 0) nRet = -1;
		}
		else nRet = -1;

	} // Translate

	return nRet;

}

