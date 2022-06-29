// MISC.C - miscellaneous support routines for SETUP.EXE
//   Copyright (c) 1995 Rex Conn for Qualitas Inc.

#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <direct.h>
#include <malloc.h>
#include <dos.h>
#include <io.h>
#include <string.h>

#include <bioscrc.h>

#include "setup.h"
#include "messages.h"

extern BOOL bBCFsys;
extern BOOL bMCAsys;
extern BOOL bValidBCF;
extern WORD BIOSCRC;
extern char bcf_dest[1];
extern char _far szDest[];		    // Destination path
extern BOOL bExistingMAX;		    // 1 if MAX is already installed


// get line from file
int GetLine( HFILE fh, register char *line, int nMaxSize )
{
	int i = 0, n = 0;

	nMaxSize = _lread( fh, line, nMaxSize );

	// get a line and set the file pointer to the next line
	line[((nMaxSize < 0) ? 0 : nMaxSize)] = '\0';

	for (n = 0; ((line[n] != '\r') && (line[n] != '\n') && (line[n] != 26) && (line[n] != '\0')); n++)
		;
	i = n;
	if (line[i] == '\r')
		i++;
	if (line[i] == '\n')
		i++;
	line[n] = '\0';

	(void)_llseek( fh, (long)(i - nMaxSize), SEEK_CUR );

	return i;
}


// strip the specified leading characters
void strip_leading( char *arg, char *delims )
{
	while ((*arg != '\0') && (strchr( delims, *arg ) != NULL ))
		lstrcpy( arg, arg+1 );
}


// strip the specified trailing characters
void strip_trailing(register char *arg, char *delims)
{
	register int i;

	for (i = lstrlen(arg); ((--i >= 0) && (strchr( delims, arg[i] ) != NULL )); )
		arg[i] = '\0';
}


// returns the location of the substring "pszString" within "pszText"
int FindString(char *pszText, char *pszString)
{
	register int i, n;

	for ( i = 0, n = lstrlen( pszString ); ((pszText[i]) && ( _strnicmp( pszText+i, pszString, n ) != 0 )); i++ )
		;

	return ((pszText[i] == '\0') ? -1 : i);
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
void MakePath(char *pszDir, char *pszFileName, char *pszTarget)
{
	register int nLength;

	if (pszTarget != pszDir)
		lstrcpy( pszTarget, pszDir );
	nLength = lstrlen( pszTarget );

	if ((*pszTarget) && (strchr( "/\\:", pszTarget[nLength-1] ) == NULL ))
		lstrcat( pszTarget, "\\" );

	lstrcat( pszTarget, pszFileName );
	AnsiUpper( pszTarget );
}


// return free space on specified drive
unsigned long freeKB(char *szDrive)
{
	long lBytesFree;
	struct diskfree_t d_stat;

	if (_dos_getdiskfree((*szDrive - 64), &d_stat))
		return 0;

	lBytesFree = (long)(d_stat.bytes_per_sector * d_stat.sectors_per_cluster) * (long)(d_stat.avail_clusters);

	return (lBytesFree >> 10);
}


// free global memory block
void _fastcall FreeMem(char *fptr)
{
	HANDLE hMem;

	if (fptr != 0L) {
		hMem = (HANDLE)GlobalHandle( SELECTOROF(fptr) );
		GlobalUnlock( hMem );
		GlobalFree( hMem );
	}
}


// allocate system memory
char *AllocMem(unsigned int *uSize)
{
	HANDLE hMem;

	if ((hMem = GlobalAlloc( GHND, *uSize )) != NULL)
		return (GlobalLock( hMem ));

	return NULL;
}


// grow or shrink DOS/OS2 memory block
char *ReallocMem(char *fptr, unsigned long ulSize)
{
	HANDLE hMem;

	if (fptr == 0L)
		return (AllocMem( (unsigned int *)&ulSize) );

	hMem = (HANDLE)GlobalHandle( SELECTOROF(fptr) );
	GlobalUnlock( hMem );
	if ((hMem = GlobalReAlloc(hMem, ulSize, GMEM_MOVEABLE | GMEM_ZEROINIT)) != NULL)
		return (GlobalLock( hMem ));

	return NULL;
}


// insert a string inside another one
char * strins( char *str, char *insert_str )
{
	register unsigned int inslen;

	// length of insert string
	if ((inslen = strlen(insert_str)) > 0) {

		// move original
		memmove( str+inslen, str, (strlen(str)+1));

		// insert the new string into the hole
		memmove(str,insert_str,inslen);
	}

	return (str);
}


// NTHARG returns the nth argument in the line (parsing by whitespace)
//   or NULL if no nth argument exists
char * ntharg(char *line, int index)
{
	static char buf[256];
	static char delims[] = " \t,=";
	register char *ptr;

	if (line == NULL )
		return NULL;

	for ( ; ; index--) {

		// find start of arg[i]
		line += strspn( line, delims );
		if ((*line == '\0') || (index < 0))
			break;

		// search for next delimiter
		ptr = scan(line, delims);

		if (index == 0) {

			// this is the argument I want - copy it & return
			if ((index = (int)(ptr - line)) > 255)
				index = 255;
			wsprintf( buf, "%.255s", line );
			buf[index] = '\0';
			return buf;
		}

		line = ptr;
	}

	return NULL;
}


// Find the first character in LINE that is also in SEARCH.
//   Return a pointer to the matched character or EOS if no match is found.
char * scan(register char *line, register char *search)
{
	if (line != NULL ) {

	    for ( ; (*line != '\0'); line++) {
		    if (strchr(search, *line) != NULL )
			    break;
	    }
	}

	return line;
}


// return the path stripped of the filename (or NULL if no path)
char * path_part(char *s)
{
	static char buffer[260];

	lstrcpy( buffer, s );

	// search path backwards for beginning of filename
	for (s = buffer + lstrlen(buffer); (--s >= buffer); ) {

		// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) {
			// take care of arguments like "d:.." & "..\.."
			if (lstrcmpi(s+1, "..") != 0)
				s[1] = '\0';
			return buffer;
		}
	}

	return NULL;
}


// return the filename stripped of path & disk spec
char * fname_part(char *pszFileName)
{
	static char buf[128];
	register char *s;

	// search path backwards for beginning of filename
	for (s = pszFileName + lstrlen(pszFileName); (--s >= pszFileName); ) {

		// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) {

			// take care of arguments like "d:.." & "..\.."
			if (lstrcmpi( s+1, ".." ) == 0)
				s += 2;
			break;
		}
	}

	// step past the delimiter char
	s++;

	lstrcpy( buf, s );
	return buf;
}


// return the file extension only
char * ext_part(char *s)
{
	static char buf[5];
	char *ptr;

	// make sure extension is for filename, not a directory name
	if ((s == NULL ) || ((ptr = strrchr( s, '.' )) == NULL ) || (strpbrk( ptr, "\\/:" ) != NULL ))
		return NULL;

	// don't read the next element in an include list
	sscanf( ptr, "%4[^;\"]", buf );

	return buf;
}


// get current directory, with leading drive specifier (or NULL if error)
char * gcdir(char *pszDrive)
{
	static char szCurrent[128];

	szCurrent[0] = '\0';
	if (_getdcwd( gcdisk(pszDrive), szCurrent, 127 ) == NULL)
		return NULL;

	return ( szCurrent );
}


// return the specified (or default) drive as 1=A, 2=B, etc.
int gcdisk(char *drive_spec)
{
	if ((drive_spec != NULL) && (drive_spec[1] == ':'))
		return ( *drive_spec - 64 );

	return (_getdrive());
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
void mkdirname(char *dname, char *pszFileName)
{
	register int length;

	length = lstrlen( dname );

	if ((*dname) && (strchr( "/\\:", dname[length-1] ) == NULL ))
		lstrcat( dname, "\\" );
	lstrcat( dname, pszFileName );
}


// make a full file name including disk drive & path
char * mkfname( char *pszFileName )
{
	register char *ptr;
	char temp[128], *source, *curdir = "";

	if (((source = pszFileName) == NULL ) || (*pszFileName == '\0'))
		return NULL;

	AnsiUpper( source );

	// skip the disk specification
	if ((*pszFileName) && (pszFileName[1] == ':'))
		pszFileName += 2;

	// get the current directory, & save to the temp buffer
	if ((curdir = gcdir( source )) == NULL )
		return NULL;

	// skip the disk spec for the default directory
	lstrcpy( temp, curdir );
	curdir = temp + 3;

	// if filespec defined from root, there's no default pathname
	if ((*pszFileName == '\\') || (*pszFileName == '/')) {
		pszFileName++;
		*curdir = '\0';
	}

	while ((pszFileName != NULL ) && (*pszFileName)) {

		// don't strip trailing \ in directory name
		if ((ptr = strpbrk( pszFileName, "/\\" )) != NULL ) {
			if ((ptr[1] != '\0') || (ptr[-1] == '.'))
				*ptr = '\0';
			ptr++;
		}

		// append the directory or filename to the temp buffer
		mkdirname( temp, pszFileName );

		pszFileName = ptr;
	}

	lstrcpy( source, temp );

	// return expanded filename
	return ( source );
}


// return non-zero if the specified file exists
int QueryFileExists(char *pszFileName)
{
	struct _find_t dir;

	// check for valid drive, then expand filename to catch things
	//   like "\4dos\." and "....\wonky\*.*"
	if (FindFile( 0x4E, pszFileName, &dir, NULL ) != NULL )
		return 1;

	return 0;
}


char * FindFile( int fflag, register char *arg, struct _find_t *dir, char *filename )
{
	int rval;

	// search for the next matching file
	if (fflag == 0x4E)
		rval = _dos_findfirst( arg, 0x7, (struct find_t *)dir);
	else
		rval = _dos_findnext( (struct find_t *)dir );

	if (rval != 0)
		return NULL;

	// if no target filename requested, just return a non-NULL response
	if (filename == NULL)
		return (char *)-1;

	// copy the saved source path
	MakePath( path_part(arg), dir->name, filename );

	// return matching filename
	return (filename);
}

//------------------------------------------------------------------
void calc_crcinfo( void )
{
    unsigned long result;

	// Set bcfsys and mcasys
    bBCFsys = DPMI_Is_BCF();
    bMCAsys = DPMI_Is_MCA();

    if( bBCFsys ) {
	    // Get BIOS CRC
			// As we're running under Windows, we use DPMI to get the
			// actual BIOS data, so it doesn't matter who the memory
			// manager is.

			// Note that all BCF machines have 128K BIOSes.
	    result = DPMI_BCRC( 0xe0000L, 0x20000L );

	    if ( !HIWORD(result) ) {
		BIOSCRC = LOWORD(result);
		wsprintf ( bcf_dest, "%s\\@%04X.BCF", szDest, BIOSCRC);
	    }
	    else {
		BIOSCRC = 0;
	    }
    } // System supports BIOS compression

} // End calc_crcinfo

//------------------------------------------------------------------
// add BCF instructions to profile.add
// BCF file must already exist in szDest.
//------------------------------------------------------------------
void profile_add ( void )
{
    HFILE hf;
    OFSTRUCT os;
    char fname[ _MAX_PATH + 1 ];
    LPSTR buffer;

    memset( &os, 0, sizeof( OFSTRUCT ));
    MakePath( szDest, "profile.add", buffer );

    if(( buffer = _fmalloc( _MAX_PATH + 1 + strlen( MsgBcfFind ))) != NULL ) {

	if (( hf = OpenFile( fname, &os,
	    OF_READWRITE | OF_CREATE | OF_SHARE_COMPAT )) != HFILE_ERROR ) {
	    if ( bBCFsys ) {
		if ( BIOSCRC && !_access ( bcf_dest, 0 ) ) {
		    bValidBCF = TRUE;
		    wsprintf ( buffer, MsgBcfFind, szAppName, bcf_dest,
							    szAppName );
		} else {
		    wsprintf ( buffer, MsgNoBcf, BIOSCRC );
		}
	    } else {
		wsprintf ( buffer, MsgNoBcfSys );
	    }
	    if ( _lwrite( hf, buffer, strlen( buffer )) == HFILE_ERROR ) {
		char szMsg[ _MAX_PATH + 128 ];
		wsprintf( szMsg, szFmt_RWErr, fname );
		MessageBox( NULL, szMsg, NULL, MB_OK );
	     }

	_lclose( hf );

	} else {
	    char szMsg[ _MAX_PATH + 128 ];
	    wsprintf( szMsg, szFmt_RWErr, fname );
	    MessageBox( NULL, szMsg, NULL, MB_OK );
	}

    _ffree( buffer );
    } else {
	    // out of memory
	MessageBox( NULL, szMsg_Mem, NULL, MB_OK );
    }
} // End of profile_add
