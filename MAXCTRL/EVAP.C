// EVAP.C - kludge to delete active Windows files from the DOS box
// Copyright (c) 1995 by Rex Conn for Qualitas, Inc.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <memory.h>
#include <process.h>
#include <time.h>


// make a far pointer from the segment and offset
#define MAKEP(seg,off) ((void _far *)(((unsigned long)(seg) << 16) | (unsigned int)(off)))

#define DEL_SUBDIRS 0x1
#define DEL_RMDIR 0x02

typedef struct
{
	char szSource[80];
	char szTarget[80];
	char *pszFilename;
	unsigned int fFlags;
} DEL_STRUCT;


int del(char *);
int del_cmd(char *);
static int _del(DEL_STRUCT *);
char * path_part(char *);
char * fname_part(char *);
void mkdirname(char *, char *);
void strip_trailing(char *, char *);
char * FindFile( int, char *, int, struct _find_t *, char * );


int main(int argc, char **argv)
{
	char szBuf[128];
	char _far *fptr;
	time_t t1, t2;
	double dWait = 3.0;		// timeout before erase attempt

	// get the start time.
	time( &t1 );     

        // wait a few seconds
	do {
        	time( &t2 );
        } while( dWait > difftime( t2, t1 ));

	// save command line tail
	fptr = (char _far *)MAKEP( _psp, 0x80 );
	argc = *fptr++;
	sprintf( szBuf, "%.*Fs", argc, fptr );

	_chdir( ".." );

	return (del_cmd( szBuf ));
}


// Delete file(s)
int del_cmd(register char *pszLine)
{
	int nLength;
	DEL_STRUCT Del;

	memset(&Del, '\0', sizeof(DEL_STRUCT));

	while (*pszLine) {

		if (*pszLine == ' ')
			pszLine++;

		else if (*pszLine == '/') {

			pszLine++;
			if (*pszLine == 'S') {
				Del.fFlags |= DEL_SUBDIRS;
				pszLine++;
			} else if (*pszLine == 'X') {
				Del.fFlags |= DEL_RMDIR;
				pszLine++;
			}

		} else
			break;
	}

	strcpy(Del.szSource, pszLine);

	nLength = strlen(path_part(Del.szSource));

	// save the source filename part (for recursive calls)
	Del.pszFilename = Del.szSource + nLength;
	Del.pszFilename = strdup( Del.pszFilename );

	return (_del(&Del));
}


// recursive file deletion routine
static int _del(register DEL_STRUCT *Del)
{
	int fval, rval = 0;
	char *source_name;
	struct _find_t dir;

	// do a new-style delete
	for (fval = 0x4E; (FindFile( fval, Del->szSource, 0x07, &dir, Del->szTarget) != NULL); fval = 0x4F) {

		if (remove(Del->szTarget) != 0) {
			// clear hidden/rdonly attributes & try to delete again
			if (_dos_setfileattr(Del->szTarget, _A_NORMAL) == 0)
				if (remove(Del->szTarget) != 0)
					rval = 2;
		}
	}

	// delete the description(s) for deleted or missing files
	sprintf(Del->szSource, "%s%s", path_part(Del->szSource), "*.*");

	// delete matching subdirectory files too?
	if (Del->fFlags & DEL_SUBDIRS) {

		// save the current subdirectory start
		source_name = strchr(Del->szSource,'*');
 
		// search for all subdirectories in this (sub)directory
		for (fval = 0x4E; (FindFile(fval, Del->szSource, 0x17, &dir, NULL) != NULL); fval = 0x4F) {

			if (((dir.attrib & 0x10) == 0) || (dir.name[0] == '.'))
				continue;

			// make the new "source"
			sprintf(source_name, "%s\\%s", dir.name, Del->pszFilename);

			// process directory tree recursively
			rval = _del( Del );

			// restore the original name
			strcpy(source_name, "*.*");
		}
	}

	// delete the subdirectory?
	if (Del->fFlags & DEL_RMDIR) {

		// remove the last filename from the directory name
		source_name = path_part(Del->szSource);
		strip_trailing(source_name, "\\/");

		// don't try to delete the root or current directories
		_rmdir(source_name);
	}

	return rval;
}


// return the path stripped of the filename (or NULL if no path)
char * path_part(register char *s)
{
	static char buffer[80];

	strcpy( buffer, s );

	// search path backwards for beginning of filename
	for (s = buffer + strlen(buffer); (--s >= buffer); ) {

		// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) {
			// take care of arguments like "d:.." & "..\.."
			if (stricmp(s+1, "..") != 0)
				s[1] = '\0';
			return buffer;
		}
	}

	return NULL;
}


// return the filename stripped of path & disk spec
char * fname_part(register char *pszFileName)
{
	static char buf[128];
	register char *s;

	// search path backwards for beginning of filename
	for (s = pszFileName + strlen(pszFileName); (--s >= pszFileName); ) {

		// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) {

			// take care of arguments like "d:.." & "..\.."
			if (stricmp( s+1, ".." ) == 0)
				s += 2;
			break;
		}
	}

	// step past the delimiter char
	s++;

	strcpy( buf, s );
	return buf;
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
void mkdirname(register char *dname, char *pszFileName)
{
	register int length;

	length = strlen( dname );

	if ((*dname) && (strchr( "/\\:", dname[length-1] ) == NULL ))
		strcat( dname, "\\" );
	strcat( dname, pszFileName );
}


// strip the specified trailing characters
void strip_trailing(register char *arg, char *delims)
{
	register int i;

	for (i = strlen(arg); ((--i >= 0) && (strchr( delims, arg[i] ) != NULL )); )
		arg[i] = '\0';
}


// return non-zero if the specified file or directory exists
int QueryFileExists(char *pszFileName)
{
	struct _find_t dir;

	if (FindFile( 0x4E, pszFileName, 0x17, &dir, NULL ) != NULL )
		return 1;

	return 0;
}


char * FindFile( int fflag, register char *arg, int mode, struct _find_t *dir, char *filename )
{
	register int rval;

	// search for the next matching file or directory
	if (fflag == 0x4E)
		rval = _dos_findfirst( arg, mode, (struct find_t *)dir);
	else
		rval = _dos_findnext( (struct find_t *)dir );

	if (rval != 0)
		return NULL;

	// if no target filename requested, just return a non-NULL response
	if (filename == NULL)
		return (char *)-1;

	// copy the saved source path
	strcpy( filename, path_part(arg) );
	mkdirname( filename, dir->name );

	// return matching filename
	return (filename);
}

