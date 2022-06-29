// $Header:   P:/PVCS/MAX/MAXIMIZE/NEWNAMES.C_V   1.1   13 Oct 1995 12:00:36   HENRY  $
//
// NEWNAMES.C - Convert all old names to new (obviating OLDNAMES.LIB)
//
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>

char *ppszName[] = {
	"access",
	"close",
	"dup",
	"dup2",
	"execl",
	"getch",
	"lseek",
	"ltoa",
	"memicmp",
	"mkdir",
	"movedata",
	"open",
	"putch",
	"read",
	"rmdir",
	"spawnl",
	"strcmpi",
	"strdup",
	"stricmp",
	"strlwr",
	"strnicmp",
	"strupr",
	"tempnam",
	"write",
	"unlink"
};
#define	NNAMES	(sizeof(ppszName)/sizeof(ppszName[0]))

#define	MAXBUFF 1024
char szBuff[ MAXBUFF + 1 ];
char szTemp[ MAXBUFF + 1 ];

// Substitute all tokens " \t\n\r()[]{};" from list
// Returns number of lines changed if OK, else -1
int
ProcessFile( char *pszDest, char *pszSource ) {

	int nRes = -1;
	FILE *pfDest, *pfSource;
	char *psz, *pszStart, *pszEnd;
	int nTok, nChanged, nStart;
	char szTokList[] = " \t\r\n;[]{}()|&^!%*-=+/?:,";

	pfSource = fopen( pszSource, "r" );
	if (!pfSource) {
		return -1;
	}

	pfDest = fopen( pszDest, "w" );
	if (!pfDest) {
		fclose( pfSource );
		return -1;
	}

	nRes = 0;

	while (fgets( szBuff, MAXBUFF, pfSource )) {

		szBuff[ MAXBUFF ] = '\0';

		nChanged = 0;

		// Do a case-sensitive match on all tokens
		for (nTok = 0; nTok < NNAMES; nTok++) {

			pszStart = szBuff;

			while (psz = strstr( pszStart, ppszName[ nTok ] )) {

				// Point to the next search target in szBuff
				pszStart = psz + strlen( ppszName[ nTok ] );

				// Make sure it's a token
				if (psz > szBuff) {
					if (!strchr( szTokList, psz[ -1 ] )) {
						continue;
					} // Not complete
				} // Check start

				nStart = (int)(psz - szBuff);
				strcpy( szTemp, szBuff );
				pszEnd = &szTemp[ nStart + strlen( ppszName[ nTok ] ) ];

				if (*pszEnd) {
					if (!strchr( szTokList, *pszEnd )) {
						continue;
					} // Only partial
				} // Check end

				nChanged = 1; // Count another line changed

				// Now do the substitution
				sprintf( &szBuff[ nStart ], "_%s%s", ppszName[ nTok ], pszEnd );

			} // while still finding things

		} // for all tokens to match

		nRes += nChanged;

		fputs( szBuff, pfDest );

	} // not EOF

ProcessFileExit:
	fclose( pfSource );
	fclose( pfDest );

	return nRes;

} // ProcessFile()

int
main( int argc, char *argv[] ) {

	char szTemp[ _MAX_PATH ], szDrive[ _MAX_DRIVE ], szDir[ _MAX_DIR ];
	int nArg, nRes;

	fprintf( stderr, "NewNames v1.0  Copyright (C) 1995 Qualitas, Inc.  All rights reserved.\n" );

	if (argc < 2) {
		fprintf( stderr, "No files specified.\n" );
		return -1;
	}

	for (nArg = 1; nArg < argc; nArg++) {

		_splitpath( argv[ nArg ], szDrive, szDir, NULL, NULL );
		_makepath( szTemp, szDrive, szDir, "%%newnam", ".tmp" );

		fprintf( stderr, "Processing %s...\n", argv[ nArg ] );

		nRes = ProcessFile( szTemp, argv[ nArg ] );
		if (nRes < 0) {
			fprintf( stderr, "Unable to process %s\n", argv[ nArg ] );
			return -1;
		} // Failed
		else if (!nRes) {
			continue;
		} // Nothing to change

		fprintf( stderr, "    %d lines changed.\n", nRes );

		if (_unlink( argv[ nArg ] ) < 0) {
			fprintf( stderr, "Unable to delete %s and rename %s\n",
					argv[ nArg ], szTemp );
			return -1;
		}

		if (rename( szTemp, argv[ nArg ] ) != 0) {
			fprintf( stderr, "Unable to rename %s to %s\n",
					szTemp, argv[ nArg ] );
			return -1;
		}

	} // for all args

	fprintf( stderr, "Done.\n" );

	return 0;

} // main()

