//' $Header:   P:/PVCS/MAX/SETUP/SETUTIL.CPV   1.12   16 Jun 1998 00:04:26   BOB  $
//------------------------------------------------------------------
// SETUTIL.CPP
// Utility Functions for Setup
// Version 1.0
// 7 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
//------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <malloc.h>
#include <time.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#ifdef _WIN32
#include <winver.h>
#else
#include <ver.h>
#endif

#include <ctl3d.h>

#include <setglob.h>

#ifdef _WIN16
	#include <dunzdll.h>
	#include <dzipdll.h>
#else
	#include <32alias.h>
	#include <dunzip32.h>
	#include <dzip32.h>
#endif

#include <setunzip.h>

#define ASCTIMELEN 26

//------------------------------------------------------------------
// Initialization function. Called at beginning of program.
// WARNING - Don't put any action in this function that is
// parameter specific...ie. things that you don't want in all branches.
//------------------------------------------------------------------
void GetEnvInfo( HINSTANCE hInstance )
	{
		// get our file name and path
	GetModuleFileName( hInstance, szTemp, _MAX_PATH );

	if( szTemp ) 
		{
#ifdef _WIN32
			// get past the long file names...for now.
		if( bWin95 )
			{
			MyGetShortPathName( szTemp, szTemp, _MAX_PATH );
			}
#endif
		lpProgName = StrMem( szTemp );
		lpProgPath = StrMem( path_part( szTemp ));

		GetWindowsDirectory( szTemp, _MAX_PATH );
#ifdef _WIN32
			// get past the long file names...for now.
		if( bWin95 )
			{
			MyGetShortPathName( szTemp, szTemp, _MAX_PATH );
			}
#endif
		lpWinPath = StrMem( szTemp );

		GetSystemDirectory( szTemp, _MAX_PATH );
#ifdef _WIN32
			// get past the long file names...for now.
		if( bWin95 )
			{
			MyGetShortPathName( szTemp, szTemp, _MAX_PATH );
			}
#endif
		lpSysPath = StrMem( szTemp );

			// Load the help filename.
		MakePath( lpProgPath, szC_HelpFile, szTemp );
		lpHelpFile = StrMem( szTemp );

			// special case German startup group.
		nCountry = GetProfileInt( (LPSTR)"intl", (LPSTR)"iCountry", nCountry );
		if( nCountry == 49 ) 
			{
			lpStartup = StrMem( szC_DEStartupGroup );
			} 
		else 
			{
			lpStartup = StrMem( szC_USStartupGroup );
			}

			// check to see if they've removed their StartUp directory
			//	 and put it on the desktop!
		if ( bWin95 )  
			{
			char szT2[ _MAX_PATH + 1 ];
			wsprintf( szT2, "desktop\\%s", lpStartup );
			MakePath( lpWinPath, szT2, szTemp );
			if (QueryFileExists( szTemp ))
				{
				bStartUp95 = 1;
				}
			}
		}
	else
		{
		SetErrMsg( szEMsg_Module );
		CrashExit( );
		}
	}


//------------------------------------------------------------------
// Prepare a normal path for comparison with a DynaZip filename.
//------------------------------------------------------------------
void PrepZipPath( LPSTR lpPathIn, LPSTR lpBuffer ) 
	{
	LPSTR lpPath;
	
	lpPath = lpPathIn;
	if (*lpPath && lpPath[ 1 ] == ':') 
		{
		lpPath += 2;
		}

	if (*lpPath == '/' || *lpPath == '\\') 
		{
		lpPath++;
		}

		// copy to buffer and convert to lowercase.
	_fstrcpy( lpBuffer, _fstrlwr( lpPath ));

		// replace the backslashes with slashes.
	for( lpPath=lpBuffer; *lpPath ; ++lpPath )
		{
		if( *lpPath == '\\' )
			{
			*lpPath = '/';
			}
		}
	} // PrepZipPath()

//------------------------------------------------------------------
// Open or Create a file
//------------------------------------------------------------------
HFILE OpenOrCreate( LPSTR lpFile, int nMode )
	{
	HFILE fh;
	
	if( QueryFileExists( lpFile ) != 0 )
		{
		fh = _lopen( lpFile, nMode );
		}
	else
		{
		fh = _lcreat( lpFile, 0 );
		}

	return fh;
	}

//------------------------------------------------------------------
void SetErrMsg( LPSTR szMsg )
	{
	if( szMsg )
		{
		_fstrncpy( szGlobErrorMsg, szMsg, ERRMSGLEN );
		}
	else
		{
		szGlobErrorMsg[ 0 ] = '\0';
		}
	}

//------------------------------------------------------------------
void CenterWindow(HWND hWnd)
	{
	RECT RectParent, Rect;
	int left, top, width, height;

	// get frame window size
	GetWindowRect( GetDesktopWindow(), &RectParent);
	
	GetWindowRect(hWnd, &Rect);

	width = Rect.right - Rect.left;
	height = Rect.bottom - Rect.top;

	left = RectParent.left + ((RectParent.right - RectParent.left) / 2) - (width / 2);
	top = RectParent.top + ((RectParent.bottom - RectParent.top) / 2) - (height / 2);

	SetWindowPos( hWnd, HWND_TOP, left, top, width, height, SWP_SHOWWINDOW );
	}

//------------------------------------------------------------------
// allocate system memory
//------------------------------------------------------------------
LPSTR AllocGlobalMem(unsigned int *uSize)
	{
	HANDLE hMem;

	if ((hMem = GlobalAlloc( GHND, *uSize )) != NULL)
		{
		return (LPSTR)(GlobalLock( hMem ));
		}

	return NULL;
	}

//------------------------------------------------------------------
// free global memory block
//------------------------------------------------------------------
void _fastcall FreeGlobalMem( char *fptr )
	{
	HANDLE hMem;

	if (fptr != 0L) 
		{
#ifdef _WIN16
		hMem = (HANDLE)GlobalHandle( SELECTOROF( fptr ));
#else
		hMem = (HANDLE)GlobalHandle( fptr );
#endif
		GlobalUnlock( hMem );
		GlobalFree( hMem );
		fptr = 0L;
		}
	}

//------------------------------------------------------------------
// make a file name from a directory name by appending '\' (if necessary)
//	 and then appending the filename
//------------------------------------------------------------------
void MakePath(char *pszDir, char *pszFileName, char *pszTarget)
	{
	register int nLength;

	if (pszTarget != pszDir)
		{
		lstrcpy( pszTarget, pszDir );
		}

	nLength = lstrlen( pszTarget );
	if ((*pszTarget) && (strchr( "/\\:", pszTarget[nLength-1] ) == NULL ))
		{
		lstrcat( pszTarget, "\\" );
		}

	lstrcat( pszTarget, pszFileName );
	AnsiUpper( pszTarget );
	}

//------------------------------------------------------------------
// return the path stripped of the filename (or NULL if no path)
//------------------------------------------------------------------
LPSTR path_part( LPSTR s)
	{
	static char buffer[ _MAX_PATH + 1 ];

	lstrcpy( buffer, s );
	
		// search path backwards for beginning of filename
	for (s = buffer + lstrlen(buffer); (--s >= buffer); ) 
		{

			// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) 
			{
				// take care of arguments like "d:.." & "..\.."
			if (lstrcmpi(s+1, "..") != 0)
				{
				s[1] = '\0';
				return buffer;
		}
			}
		}
	return NULL;
	}

//------------------------------------------------------------------
// return the filename stripped of path & disk spec
//------------------------------------------------------------------
LPSTR fname_part( LPSTR pszFileName)
	{
	static char buf[ _MAX_PATH + 1 ];
	register LPSTR s;

		// search path backwards for beginning of filename
	for (s = pszFileName + lstrlen(pszFileName); (--s >= pszFileName); ) 
		{
			// accept either forward or backslashes as path delimiters
		if ((*s == '\\') || (*s == '/') || (*s == ':')) 
			{
				// take care of arguments like "d:.." & "..\.."
			if (lstrcmpi( s+1, ".." ) == 0)
				{
				s += 2;
				}
			break;
			}
		}
		
		// step past the delimiter char
	s++;
	
	lstrcpy( buf, s );
	return buf;
	}

//------------------------------------------------------------------
// return non-zero if the specified file exists
//------------------------------------------------------------------
#if defined(_WIN32) || defined(__WIN32__)
int QueryFileExists( LPSTR pszFileName)
	{
	WIN32_FIND_DATA fd;
	HANDLE fh;

	if(( fh = FindFirstFile( pszFileName, &fd )) != INVALID_HANDLE_VALUE )
		{
		FindClose( fh );
		return 1;
		}
	return 0;
	}
#else
int QueryFileExists( LPSTR pszFileName)
	{
	struct _find_t dir;

	if( FindFile( 0x4E, pszFileName, &dir, NULL ) != NULL )
		{
		return 1;
		}
	return 0;
	}
#endif

//------------------------------------------------------------------
// 16 bit FileFind
//------------------------------------------------------------------
#ifdef _WIN16
LPSTR FindFile( int fflag, LPSTR arg, struct _find_t *dir, LPSTR filename )
	{
	int rval;

		// search for the next matching file
	if (fflag == 0x4E)
		{
		rval = _dos_findfirst( arg, 0x7, (struct find_t *)dir);
		}
	else
		{
		rval = _dos_findnext( (struct find_t *)dir );
		}
	
	if (rval != 0)
		{
		return NULL;
		}

		// if no target filename requested, just return a non-NULL response
	if (filename == NULL)
		{
		return (char *)-1;
		}

	// copy the saved source path
	MakePath( path_part(arg), dir->name, filename );

		// return matching filename
	return (filename);
	}
#endif

//------------------------------------------------------------------
#if defined(_WIN32) || defined(__WIN32__)
BOOL QueryDirExists( LPSTR szDirName )
	{
	WIN32_FIND_DATA fd;
	HANDLE fh;
	char szDir[ _MAX_PATH + 2 ];

		// search for the next matching file
	_fstrncpy( szDir, szDirName, _MAX_PATH );

	if( ( lstrlen( szDir ) < 4 ) &&
		( szDir[1] == ':' ) && 
		( szDir[2] == '\\' ) )
		{
			// it's a root dir, return TRUE;
		return 1;
		}

	strip_trailing( szDir, "\\/" );
	
	if(( fh = FindFirstFile( szDir, &fd )) != INVALID_HANDLE_VALUE )
		{
		FindClose( fh );
		return 1;
		}
	return 0;
	}
#else
BOOL QueryDirExists( LPSTR szDirName )
	{
	BOOL bRet;
	struct _find_t dir;
	char szDir[ _MAX_PATH + 2 ];

		// search for the next matching file
	_fstrncpy( szDir, szDirName, _MAX_PATH );

	if( ( lstrlen( szDir ) < 4 ) &&
		( szDir[1] == ':' ) && 
		( szDir[2] == '\\' ) )
		{
			// it's a root dir, return TRUE;
		return 1;
		}

	strip_trailing( szDir, "\\/" );

	bRet = !(_dos_findfirst( szDir, _A_SUBDIR, &dir));
	return bRet;
	}
#endif
//------------------------------------------------------------------
void FAR *GetMem( size_t s )
	{
	void FAR *ret;
	static int nHeapChk = 0;
	struct _heapinfo hi;
	int nHeapRes;

		// Check the heap
	if (nHeapChk)
		{
		hi._pentry = NULL;
		while ((nHeapRes = _fheapwalk( &hi )) == _HEAPOK) ;
		if (nHeapRes != _HEAPEMPTY &&
			nHeapRes != _HEAPOK &&
			nHeapRes != _HEAPEND)
			{
			SetErrMsg( "Heap corrupt on call to GetMem" );
			CrashExit();
			}
		}

	if ( ret = _fmalloc( s ) )
		{
		_fmemset( ret, 0, s );
		} 
	else 
		{
		SetErrMsg( szEMsg_Mem );
		CrashExit( );
		}

	return (ret);
	} 

//------------------------------------------------------------------
void FAR *ReAllocMem( void FAR *lpMem, size_t s )
	{
	void FAR *ret;
	static int nHeapChk = 0;
	struct _heapinfo hi;
	int nHeapRes;

	if (( ret = _frealloc( lpMem, s )) == NULL )
		{
		SetErrMsg( szEMsg_Mem );
		CrashExit( );
		}

		// Check the heap
	if (nHeapChk)
		{
		hi._pentry = NULL;
		while ((nHeapRes = _fheapwalk( &hi )) == _HEAPOK) ;
		if (nHeapRes != _HEAPEMPTY &&
			nHeapRes != _HEAPOK &&
			nHeapRes != _HEAPEND)
			{
			SetErrMsg( "Heap corrupt on call to ReAllocMem" );
			CrashExit();
			}
		}

	return (ret);
	} 

//------------------------------------------------------------------
 // Same as _fstrdup(), but quits if no memory
//------------------------------------------------------------------
LPSTR StrMem( LPSTR str)
	{ 
	return ( _fstrcpy( (LPSTR)GetMem( strlen(str) + 1 ), str )); 
	}

//------------------------------------------------------------------
// get line from file
//------------------------------------------------------------------
int GetLine( HFILE fh, LPSTR line, int nMaxSize )
	{
	int nRetSize;
	int i = 0, n = 0;

		// get a line and set the file pointer to the next line
	nRetSize = _lread( fh, line, nMaxSize );
	if( nRetSize == HFILE_ERROR )
		{
		line[0] = '\0';
		MessageBox( GetFocus(), szEMsg_Read, szBuff_Title, MB_OK );
		return 0;
		}

		// this limits the line to nMaxSize.
	line[ ( (nRetSize < 0) ? 0 : nRetSize)] = '\0';

		// scan to find the end of the line in the buffer.
	for (n = 0; (  (line[n] != '\r') 
				&& (line[n] != '\n') 
				&& (line[n] != 26) 
				&& (line[n] != '\0')) ; n++) ;
	i = n;
	if (line[i] == '\r') i++;
	if (line[i] == '\n') i++;
	line[n] = '\0';

	(void)_llseek( fh, (long)(i - nRetSize), SEEK_CUR );
	return i;
	}

//------------------------------------------------------------------
// strip the specified leading characters
//------------------------------------------------------------------
void strip_leading( LPSTR arg, LPSTR delims )
	{
	while ((*arg != '\0') && (strchr( delims, *arg ) != NULL ))
		{
		lstrcpy( arg, arg+1 );
		}
	}

//------------------------------------------------------------------
// strip the specified trailing characters
//------------------------------------------------------------------
void strip_trailing( LPSTR arg, LPSTR delims)
	{
	register int i;

	for (i = lstrlen(arg); ((--i >= 0) && (strchr( delims, arg[i] ) != NULL )); )
		{
		arg[i] = '\0';
		}
	}

//------------------------------------------------------------------
// Strip trailing close bracket (])
//------------------------------------------------------------------
void strip_bracket( LPSTR lpBuff )
	{
	register char *psz = strrchr( lpBuff, ']' );
	if (psz) *psz = '\0';
	} // strip_bracket()

//------------------------------------------------------------------
// copy a file
//------------------------------------------------------------------
int FileCopy( LPSTR szTarget, LPSTR szSource )
	{
#if defined(_WIN32) || defined(__WIN32__)
	FILETIME ftCreate, ftAccess, ftWrite;
#endif
	unsigned int uSize, uBytesRead, uBytesWritten;
	HFILE hSrc, hDst;
	int nRet = 0;
	char *lpBuf;

		// if the src and target are the same just return.
		// Copying onto yourself is wrong anyway.
	if( !_fstricmp( szTarget, szSource ))
		{
		return 0;
		}

	uSize = 0xFFF0;
	if (( lpBuf = AllocGlobalMem( &uSize )) == 0L)
		{
		bFileError = TRUE;
		return -1;
		}

	if (( hSrc = _lopen( szSource, READ | OF_SHARE_COMPAT )) == HFILE_ERROR) 
		{
		nRet = -1;
		goto AllDone;
		}

	// create or truncate target file
	if (( hDst = _lcreat( szTarget, 0 )) == HFILE_ERROR ) {
		nRet = -1;
		goto AllDone;
	}

	while (uSize != 0) 
		{
		if (( uBytesRead = _lread( hSrc, lpBuf, uSize )) == HFILE_ERROR ) 
			{
			nRet = -1;
			break;
			}
			
		if ( uBytesRead == 0 )
			{
				// read error
			break;
			}
		
		if (( uBytesWritten = sswrite( hDst, lpBuf, uBytesRead )) == HFILE_ERROR) 
			{
			nRet = -1;
			break;
			}
				// check for write error.
		if ( uBytesRead != uBytesWritten ) 
			{
			nRet = -1;
			break;
			}
	}

AllDone:
	FreeGlobalMem( lpBuf );

		// set the file date & time to the same as the source
#ifdef _WIN16
	(void)_dos_getftime( hSrc, &uBytesRead, &uBytesWritten );
	(void)_dos_setftime( hDst, uBytesRead, uBytesWritten );
#else
	GetFileTime( (HANDLE)hSrc, &ftCreate, &ftAccess, &ftWrite );
	SetFileTime( (HANDLE)hDst, &ftCreate, &ftAccess, &ftWrite );
#endif

	if ( hSrc > 0 )
		{
		_lclose( hSrc );
		}

	if ( hDst > 0 ) 
		{
		_lclose( hDst );

			// if an error writing to the output file, delete it
		if ( nRet )
			{
			_unlink( szTarget );
			}
		}
	if( nRet == (-1))
		{
		bFileError = TRUE;
		}

	return nRet;
	}

//------------------------------------------------------------------
// Walks the lists of top level windows, looking for previously loaded
// module's HWND, then switching to it
// Return true if previous instance exists.
//------------------------------------------------------------------
BOOL WalkWindowList( void )
	{
	HWND hWnd;

	if(( hWnd = FindWindow( szSetupWndClass, NULL)) != NULL )
		{
		SetWindowPos( hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW );
		ShowWindow( hWnd, SW_RESTORE );
		SetFocus( hWnd );
		return TRUE;
		}

	return FALSE;
	}

//------------------------------------------------------------------
// WritePrivateProfileInt
//------------------------------------------------------------------
void WritePrivateProfileInt( LPSTR szSect, LPSTR szItem, int nVal, LPSTR szFile )
	{
	char szVal[ 20 ];
	wsprintf( (LPSTR)szVal, "%d", nVal );
	WritePrivateProfileString( szSect, szItem, (LPSTR)szVal, szFile );
	}

//------------------------------------------------------------------
// GetPrivateProfileLong
//------------------------------------------------------------------
long GetPrivateProfileLong( LPSTR szSect, LPSTR szItem, long lDefault, LPSTR szFile )
	{
	char szVal[ 21 ];
	GetPrivateProfileString( szSect, szItem, (LPSTR)"", (LPSTR)szVal, 20, szFile );
	if( szVal[0] != '\0' )
		{
		return atol( szVal );
		}
	else
		{
		return 0;
		}
	}

//------------------------------------------------------------------
// WritePrivateProfileLong
//------------------------------------------------------------------
void WritePrivateProfileLong( LPSTR szSect, LPSTR szItem, long lVal, LPSTR szFile )
	{
	char szVal[ 20 ];
	wsprintf( (LPSTR)szVal, "%ld", lVal );
	WritePrivateProfileString( szSect, szItem, (LPSTR)szVal, szFile );
	}


//------------------------------------------------------------------
// WPPI_IfEmpty - Only write int if there is no existing value.
// Returns TRUE if value was written.
//------------------------------------------------------------------
BOOL WPPI_IfEmpty( LPSTR szSect, LPSTR szItem, int nVal, LPSTR szFile )
	{
	char szT1[ 22 ]; // we really don't care if we get it all.
	
	if( 0 == GetPrivateProfileString( szSect, szItem, (LPSTR)"", 
									  (LPSTR)szT1, 20, szFile))
		{
		WritePrivateProfileInt( szSect, szItem, nVal, szFile );
		return TRUE;
		}

	return FALSE;
	}

//------------------------------------------------------------------
// WPPS_IfEmpty - Only write string if there is no existing value.
// Returns TRUE if value was written.
//------------------------------------------------------------------
BOOL WPPS_IfEmpty( LPSTR szSect, LPSTR szItem, LPSTR szVal, LPSTR szFile )
	{
	char szT1[ 22 ]; // we really don't care if we get it all.
	if( 0 == GetPrivateProfileString( szSect, szItem, (LPSTR)"", 
									  (LPSTR)szT1, 20, szFile))
		{
		WritePrivateProfileString( szSect, szItem, (LPSTR)szVal, szFile );
		return TRUE;
		}
	return FALSE;
	}

//------------------------------------------------------------------
// Return the boot drive character. Stolen from quilib.
// lpDrive must be at least 4 bytes long.
//------------------------------------------------------------------
#pragma optimize ("leg",off)
char bootdrive( LPSTR lpDrive )
	{
	char drive = 0;
	char *p;
	
#ifdef _WIN16
	if (_osmajor >= 4) 
		{
			// DOS 4.00+, get boot drive from DOS 
		_asm 
			{
			mov ax,3305h
			int 21h 	; Do the function
			add dl,'@'      ; Convert to drive letter
			mov drive,dl ; ..and store it
			}
		}
	else 
		{
		p = getenv("COMSPEC");
		if (p && strlen(p) > 1 && isalpha(p[0]) && p[1] == ':') 
			{
			drive = (char) toupper(p[0]);
			}
		
		if (drive < 'A' || drive > 'Z') 
			{
			drive = 'C';
			}
		}
#else
	p = getenv("COMSPEC");
	if (p && strlen(p) > 1 && isalpha(p[0]) && p[1] == ':') 
		{
		drive = (char) toupper(p[0]);
		}
		
	if (drive < 'A' || drive > 'Z') 
		{
		drive = 'C';
		}
#endif

		// Make root dir in string form.
	if( lpDrive != NULL )
		{
		lpDrive[0] = drive;
		lpDrive[1] = ':';
		lpDrive[2] = '\\';
		lpDrive[3] = '\0';
		}

	return drive;
	}
#pragma optimize ("",on)

//------------------------------------------------------------------
void EnumZip( LPSTRINGLIST FAR *lpS, LPSTR pszZipName )
	{
	int nRet;
	ZIPINFO zi;
	CZopen cz( (UINT)ghInstance );
	LPSTRINGLIST lpScan;

	cz.SetZip( pszZipName );

	if (( nRet = cz.GetFirst( (ZIPINFO FAR * ) &zi )) != (-1) )
		{
		(*lpS) = (LPSTRINGLIST)GetMem( sizeof( STRINGLIST ));
		lpScan = (*lpS);
		lpScan->lpString = StrMem( zi.szFileName );
		lpScan->next = NULL;
		
		while (( nRet = cz.GetNext( (ZIPINFO FAR * ) &zi )) != (-1) )
			{
			lpScan->next = (LPSTRINGLIST)GetMem( sizeof( STRINGLIST ));
			lpScan = lpScan->next;
			lpScan->lpString = StrMem( zi.szFileName );
			lpScan->next = NULL;
			}
		}
	}

//------------------------------------------------------------------
void KillStringList( LPSTRINGLIST FAR *lpS )
	{
	LPSTRINGLIST lpScan;
	LPSTRINGLIST lpTemp;
	
	if( (*lpS) == NULL )
		{
		return;
		}
	
	for( lpScan = (*lpS); lpScan ; lpScan = lpTemp )
		{
		lpTemp = lpScan->next;
		_ffree( lpScan->lpString );
		_ffree( lpScan );
		}

	(*lpS) = NULL;
	}

//------------------------------------------------------------------
// return -1 if the specified file does not exist.
// return  0 to n the index if the specified file exists.
//------------------------------------------------------------------
int QueryNameInList( LPSTR pszName, LPSTRINGLIST FAR *lpS, BOOL bZipPrep )
	{
	int nCount;
	LPSTRINGLIST lpScan;
	char lpBuf[ _MAX_PATH + 1 ];
	
	lpScan = (*lpS);
	nCount = 0;

	if ( bZipPrep )
		{
		PrepZipPath( pszName, lpBuf );
		}

	while( lpScan )
		{
		if( !_fstricmp( lpScan->lpString, ( bZipPrep ) ? lpBuf : pszName ))
			{
			return nCount;
			}
		lpScan = lpScan->next;
		nCount++;
		}
	return -1;
	}

//------------------------------------------------------------------
// return -1 if the specified file does not exist.
// return  0 to n the index if the specified file exists.
// Adds PrepZip modified string to list if not found.
//------------------------------------------------------------------
int QueryNameInListAdd( LPSTR pszName, LPSTRINGLIST FAR *lpS, BOOL bZipPrep )
	{
	int nCount;
	LPSTRINGLIST lpScan;
	char lpBuf[ _MAX_PATH + 1 ];
	
	lpScan = (*lpS);
	nCount = 0;

	if ( bZipPrep )
		{
		PrepZipPath( pszName, lpBuf );
		}

	while( lpScan )
		{
		if( !_fstricmp( lpScan->lpString, ( bZipPrep ) ? lpBuf : pszName ))
			{
			return nCount;
			}

		if( lpScan->next == NULL )
			{
			lpScan->next = (LPSTRINGLIST)GetMem( sizeof(STRINGLIST));
			lpScan->next->lpString = StrMem( ( bZipPrep ) ? lpBuf : pszName );
			return -1;
			}
		lpScan = lpScan->next;
		nCount++;
		}
	return -1;
	}

//------------------------------------------------------------------
// Write with _lwrite with error trap.
//------------------------------------------------------------------
#ifdef _WIN16
UINT sswrite( HFILE fh, const void huge *hp, UINT uLen )
#else
UINT sswrite( HFILE fh, LPCSTR hp, UINT uLen )
#endif
	{
	UINT uRet;
	
	uRet = _lwrite( fh, hp, uLen );
	
	if(( uRet == HFILE_ERROR ) || ( uRet != uLen ))
		{
		SetErrMsg( szEMsg_FileWrite );
		CrashExit( );
		}
	return uRet;
	}

//------------------------------------------------------------------
void CrackIt( WPARAM wParam, LPARAM lParam, WORD *id, WORD *cmd, HWND *hChild )
	{
	*id = LOWORD( wParam );
	*hChild = (HWND)(UINT)( lParam );
#ifdef _WIN16
	*cmd = HIWORD( lParam );
#else
	*cmd = HIWORD( wParam );
#endif
	}

//------------------------------------------------------------------
// receive & dispatch Windows messages
//------------------------------------------------------------------
void SYield( int bWait )
	{
	MSG msg;

		// process any waiting messages
	while (PeekMessage( &msg, NULL, 0, 0, PM_REMOVE )) 
		{
		bWait = 0;
		TranslateMessage( &msg );
		DispatchMessage( &msg );
		}

			// if "Wait" flag set, go to sleep until a message arrives
	if ( (bWait) && ( GetMessage( &msg, NULL, 0, 0 ) ))
		{
		TranslateMessage( &msg );
		DispatchMessage( &msg );
		}
	}

//------------------------------------------------------------------
void CrashExit( )
	{
		// force an exit from the main control loop.
	longjmp( quit_env, -1 );
	}

//------------------------------------------------------------------
// version check then copy files.
//------------------------------------------------------------------
// VCCF_DELETESRC
// VCCF_SHARED_RES
// VCCF_FORCE_COPY
// VCCF_FORCE_DEST
//------------------------------------------------------------------
// VCC_SUCCESS
// VCC_FOUNDINWRONGPLACE
// VCC_FILEINUSE
// VCC_DIFFERENTTYPES
// VCC_BADSRC
// VCC_BADDEST
// VCC_BUFFTOOSMALL
// VCC_OUTOFMEMORY
//------------------------------------------------------------------
// lpSrcFile = name.ext of file to be copied.
// lpSrcDir =  path where lpSrcFile exists.
// lpDestFile = name.ext of file when copied.
// lpDestDir =	destination path.
// lpWinDir =  Windows directory. (ignored if linked with DLL version )
// lpCurDirBuff = Buffer passed from caller. Receives path to current version.
// lpuCurLen = byte length of lpCurDirBuff.
// lpDestDirBuff = Buffer passed by caller. Receives recommended path.
// lpuDestLen = byte length of lpDestDirBuff.
// uFlags = Flag values (0 or or'ed VCCF_ values ).
//------------------------------------------------------------------
int VerChkCopyFiles( LPSTR lpSrcFile,  LPSTR lpSrcDir, 
					 LPSTR lpDestFile, LPSTR lpDestDir, LPSTR lpWinDir,
					 LPSTR lpCurDirBuff,  UINT FAR *lpuCurLen,
					 LPSTR lpDestDirBuff, UINT FAR *lpuDestLen,
					 UINT uFlags )
	{
	int nRet;
	UINT uVRet;
	UINT uVIFFlag;
	DWORD dwVIRet;
	char szTemp[ _MAX_PATH + 2 ];
	char szTempFile[ _MAX_PATH + 2 ];
	UINT uTempLen = _MAX_PATH + 1;

	nRet = 0;

	if(( lpDestDir == NULL ) || ( lpDestDir[0] == '\0' ))
		{
				// check the location of the file
		uVRet = VerFindFile( ( uFlags & VCCF_SHARED_RES )?VFFF_ISSHAREDFILE:0,
							 lpDestFile, lpWinDir, lpDestDir, lpCurDirBuff, 
							 lpuCurLen, lpDestDirBuff, lpuDestLen );  

		if ( uVRet & VFF_BUFFTOOSMALL )
			{
			nRet = VCC_BUFFTOOSMALL;
			}

		if ( uVRet & VFF_FILEINUSE ) 
			{
			nRet |= VCC_FILEINUSE;
			}
				// stop if we got an error.
		if( nRet )
			{
			return nRet;
			}

				// not an excuse to stop, but tell the caller.
		if ( uVRet & VFF_CURNEDEST )
			{
			nRet |= VCC_FOUNDINWRONGPLACE;
			}
		}
	else
		{
		_fstrcpy( lpDestDirBuff, lpDestDir );
		_fstrcpy( lpCurDirBuff, lpDestDir );
		}

			// start with, "don't delete old if it's found in another place".
	uVIFFlag = VIFF_DONTDELETEOLD;
	if( uFlags & VCCF_FORCE_COPY )
		{
		uVIFFlag |= VIFF_FORCEINSTALL;
		}

#ifdef _WIN32
		// There is a bug in the 32 bit VerInstallFile that won't
		// install a file if it cannot read it in the destination.
		// "You can't put it there if it ain't already there!" ?!?
		// so, if it ain't there, we'll put it there.
	MakePath( lpDestDirBuff, lpDestFile, szTemp );
	if( QueryFileExists( szTemp ) <= 0 )
		{
		MakePath( lpSrcDir, lpSrcFile, szTempFile );
		FileCopy( szTemp, szTempFile );
		}
#endif

	uTempLen = _MAX_PATH + 1;
	szTempFile[0] = '\0';
	if( uFlags & VCCF_FORCE_DEST )
		{
			// force copy to Specified install directory.
		dwVIRet = VerInstallFile( uVIFFlag, lpSrcFile, 
							 lpDestFile, lpSrcDir, lpDestDir,
							 lpCurDirBuff, szTempFile, 
							 (UINT FAR *)&uTempLen );
		}
	else
		{
			// Copy to VFF selected directory.
		dwVIRet = VerInstallFile( uVIFFlag, lpSrcFile, 
							 lpDestFile, lpSrcDir, lpDestDirBuff,
							 lpCurDirBuff, szTempFile, 
							 (UINT FAR *)&uTempLen );
		}
		
		// if no errors, or the source is older than the existing...
		// We have a success.
	if( !dwVIRet || ( dwVIRet & VIF_SRCOLD ))
		{
		if ( uFlags & VCCF_DELETESRC )
			{
				// if delflag, delete source.
				// only delete source if successful!
			MakePath( lpSrcDir, lpSrcFile, (LPSTR)szTemp ); 
			_unlink( szTemp );
			}
			
			// see if a temporary file still exists.
		if (  dwVIRet & VIF_TEMPFILE )
			{
			_unlink( szTempFile );
			}
			// SUCCESS EXIT.
		return VCC_SUCCESS;
		}

		// possible errors...
	if ( dwVIRet & VIF_FILEINUSE ) 
		{
			// cannot overwrite...file in use.
		nRet |= VCC_FILEINUSE;
		}

	if ((dwVIRet & VIF_MISMATCH ) ||
		(dwVIRet & VIF_DIFFLANG ) ||
		(dwVIRet & VIF_DIFFCODEPG ) ||
		(dwVIRet & VIF_DIFFTYPE ) )
		{
			// mismatch in versions.
		nRet |= VCC_DIFFERENTTYPES;
		}

	if ((dwVIRet & VIF_OUTOFSPACE ) ||
		(dwVIRet & VIF_ACCESSVIOLATION ) ||
		(dwVIRet & VIF_SHARINGVIOLATION ) ||
		(dwVIRet & VIF_CANNOTCREATE ) ||
		(dwVIRet & VIF_CANNOTDELETE ) ||
		(dwVIRet & VIF_CANNOTRENAME ) ||
		(dwVIRet & VIF_DIFFTYPE ))
		{
			// write error.
		nRet |= VCC_BADDEST;
		}

	if( dwVIRet & VIF_CANNOTREADSRC ) 
		{
			// read error.
		nRet |= VCC_BADSRC;
		}

	if (dwVIRet & VIF_CANNOTREADDST ) 
		{
			// read error.
		nRet |= VCC_BADDEST;
		}

	if (dwVIRet & VIF_OUTOFMEMORY ) 
		{
			// memory error.
		nRet |= VCC_OUTOFMEMORY;
		}

		// see if a temporary file still exists.
	if (  dwVIRet & VIF_TEMPFILE )
		{
		_unlink( szTempFile );
		}

	return nRet;
	}

#ifdef _WIN16
//------------------------------------------------------------------
BOOL LoadCtl3dLibrary( LPSTR lpLibName )
	{
	if (( hlibCTL3D = LoadLibrary( lpLibName )) < 32 )
		{
		return FALSE;
		}

	if ( !( lpfn3DRegister = 
		(LPFN3DREGISTER)GetProcAddress( hlibCTL3D, "Ctl3dRegister") ))
		{
		goto ctl_err_exit;
		}

	if ( !( lpfn3DUnregister = 
		(LPFN3DUNREGISTER)GetProcAddress( hlibCTL3D,"Ctl3dUnregister") ))
		{
		goto ctl_err_exit;
		}

	if ( !( lpfn3DSubclassDlg = 
		(LPFN3DSUBCLASSDLG)GetProcAddress( hlibCTL3D,"Ctl3dSubclassDlg")))
		{
		goto ctl_err_exit;
		}

	if ( !( lpfn3DSubclassDlgEx = 
		(LPFN3DSUBCLASSDLGEX)GetProcAddress( hlibCTL3D,"Ctl3dSubclassDlgEx")))
		{
		goto ctl_err_exit;
		}

	if ( !( lpfn3DAutoSubclass = 
		(LPFN3DAUTOSUBCLASS)GetProcAddress( hlibCTL3D,"Ctl3dAutoSubclass")))
		{
		goto ctl_err_exit;
		}

	if ( !( lpfn3DCtlColorEx = 
		(LPFN3DCTLCOLOREX)GetProcAddress( hlibCTL3D,"Ctl3dCtlColorEx")))
		{
		goto ctl_err_exit;
		}
	return TRUE;

ctl_err_exit:
	FreeLibrary( hlibCTL3D );
	return FALSE;
	}
#endif

//------------------------------------------------------------------
// read the qpacking.lst file and build a filelist.
//------------------------------------------------------------------
#define LINEBUFLEN (( _MAX_PATH * 2 ) + 20 )
void ReadQPFile( LPSTR szFilename )
	{
	HFILE fh;
	LPSTR lpTok1;
	LPSTR lpTok2;
	LPSTR lpTok3;
	LPDISKLIST lpDL=NULL;
	LPFILELIST lpFL=NULL;
	char lpBuf[ LINEBUFLEN + 2 ];
	
	if ((fh = _lopen( szFilename, READ | OF_SHARE_DENY_NONE)) != HFILE_ERROR) 
		{
		while ( GetLine( fh, lpBuf, LINEBUFLEN ))
			{
			strip_leading( lpBuf, " \t" );

			if( lpBuf[0] == ';' )
				{
					// it's a comment line. Skip it.
				continue;
				}

			if( lpBuf[0] == '*' )
				{
					// it's a SIZE line.
				lpTok1=_fstrtok( (LPSTR)&lpBuf[1], "=" );
				lpTok2=_fstrtok( NULL, "," );
				if( !_fstricmp( lpTok1, szC_InstSizeKey ))
					{
					lTotSize = atol( lpTok2 );
					}
				else if( !_fstricmp( lpTok1, szC_WinSizeKey ))
					{
					lWinSize = atol( lpTok2 );
					}
				continue;
				}

			if( lpBuf[0] == '<' )
				{
					// it's a "DISK" line.
				lpTok1=_fstrtok( (LPSTR)&lpBuf[1], "," );
				lpTok2=_fstrtok( NULL, "," );
					// remove the '>'.
				lpTok3=_fstrpbrk( lpTok1, ">" );
				*lpTok3 = '\0';
					// make a new disk node.
				if( lpDL != NULL )
					{
					lpDL->next = (LPDISKLIST)GetMem( sizeof( DISKLIST ));
					lpDL->next->prev = lpDL;
					lpDL = lpDL->next;
					lpDL->lpArchive = StrMem( lpTok2 );
					lpDL->nDiskNum = atoi( lpTok1 );
					lpDL->next = (LPDISKLIST)NULL;
					lpDL->file = (LPFILELIST)NULL;
					}
				else
					{
					lpADisks = (LPDISKLIST)GetMem( sizeof( DISKLIST ));
					lpADisks->lpArchive = StrMem( lpTok2 );
					lpADisks->nDiskNum = atoi( lpTok1 );
					lpADisks->next = (LPDISKLIST)NULL;
					lpADisks->prev = (LPDISKLIST)NULL;
					lpADisks->file = (LPFILELIST)NULL;
					lpDL = lpADisks;
					}
				continue;
				}
			
			// otherwise, it's a file line.
			lpTok1=_fstrtok( lpBuf, "," );
			lpTok2=_fstrtok( NULL, "," );
			lpTok3=_fstrtok( NULL, "," );
			if( lpDL == NULL )
				{
					// this is an error. Must have disk line first.
					// FIXME - Tell them.
				CrashExit();
				}

			if( lpDL->file != NULL )
				{
				lpFL = lpDL->file;
				while( lpFL->next != NULL )
					{
					lpFL = lpFL->next;
					}
				lpFL->next = (LPFILELIST)GetMem( sizeof( FILELIST) );
				lpFL->next->prev = lpFL;
				lpFL=lpFL->next;
				}
			else
				{
				lpDL->file = (LPFILELIST)GetMem( sizeof( FILELIST) );
				lpFL = lpDL->file;
				lpFL->prev = NULL;
				lpFL->next = NULL;
				}

			lpFL->lpFilename = StrMem( lpTok1 );
			lpFL->uSeq = (UINT)atoi( lpTok2 ); 
			lpFL->uOpt = (UINT)atoi( lpTok3 );	
			}
		_lclose(fh);
		}
	else
		{
		wsprintf( szTemp, szFmtMsg_BadOpen, szFilename );
		MessageBox( GetFocus(), szTemp, szBuff_Title, MB_OK );
		}
	}

//------------------------------------------------------------------
void KillDiskList( LPDISKLIST FAR *lpA )
	{
	LPDISKLIST lpScan = NULL;
	LPDISKLIST lpTemp = NULL;
	LPFILELIST lpFL=NULL;
	LPFILELIST lpFLTemp=NULL;

	if( (*lpA) != NULL ) 
		{
			// seek to the end of the list.
		for ( lpScan = (*lpA); lpScan->next != NULL; ) 
			{
			lpScan = lpScan->next;
			}
			
			// back up and free the list.
		for ( ; lpScan ; ) 
			{
			lpTemp = lpScan;
			lpScan = lpScan->prev;
			if( lpTemp->lpArchive )
				{
				_ffree( lpTemp->lpArchive );
				}

				// free the attached file list.
			if( lpTemp->file != NULL )
				{
				lpFL = lpTemp->file;
					// move to the end of the list.
				while( lpFL->next != NULL )
					{
					lpFL = lpFL->next;
					}
					// now back up and destroy.
				while( lpFL )
					{
					lpFLTemp = lpFL;
					lpFL = lpFL->prev;

						// free the filename;
					if( lpFLTemp->lpFilename != NULL )
						{
						_ffree( lpFLTemp->lpFilename );
						}
						// free the list entry.
					_ffree( lpFLTemp );
					}
				}
			_ffree( lpTemp );
			}

		*lpA = NULL;
		_fheapmin();
		}
	}

//------------------------------------------------------------------
// Make a filename with a unique extension. 
// szNewBuff must be > _MAX_PATH.
//------------------------------------------------------------------
void MakeSerialPath( LPSTR szDir, LPSTR szName, LPSTR szNewBuff )
	{
	LPSTR lpRet=NULL;
	unsigned int uDx;
	char szTDir[ _MAX_PATH + 2 ];
	char szTFName[ _MAX_PATH + 2 ];
	
		// get just the file name.
	_splitpath( szName, NULL, NULL, szTFName, NULL );
	MakePath( szDir, szTFName, szTDir );
	
	for( uDx=0; uDx < 4095; uDx++ )
		{
		wsprintf( szNewBuff, "%s.%3.3x", szTDir, uDx );
		if( QueryFileExists( szNewBuff ) == 1 )
			{
			szNewBuff[0] = '\0';
			}
		else
			{
			return;
			}
		}
	}

//------------------------------------------------------------------
// find the filename with the highest unique extension. 
// szFileBuff must be > _MAX_PATH.
//------------------------------------------------------------------
BOOL FindLastSerialPath( LPSTR szFileBuff )
	{
	BOOL bFoundOne = FALSE;
	unsigned int uCount;
	char szDrv[ _MAX_DRIVE + 2 ];
	char szTDir[ _MAX_PATH + 2 ];
	char szTFName[ _MAX_PATH + 2 ];
	char szT1[ _MAX_PATH + 2 ];
	
		// get just the file name.
	_splitpath( szFileBuff, szDrv, szTDir, szTFName, NULL );

	_makepath( szT1, szDrv, szTDir, szTFName, NULL );
	for( uCount=0; uCount < 4095; uCount++ )
		{
		wsprintf( szFileBuff, "%s.%3.3x", szT1, uCount );

		if( QueryFileExists( szFileBuff ))
			{
			bFoundOne = TRUE;
			}
		else
			{
			if( bFoundOne )
				{
					// return the last success.
				wsprintf( szFileBuff, "%s.%3.3x", szT1, uCount - 1 );
				return TRUE;
				}
			else
				{
					// none found.
				szFileBuff[0] = '\0';
				return FALSE;
				}
			}
		}
		// default returns with highest extension.
	return TRUE;
	}

//------------------------------------------------------------------
void MakeFileExt( LPSTR szDir, LPSTR szName, LPSTR szExt, LPSTR szTarget )
	{
	MakePath( szDir, szName, szTarget );
	_fstrcat( szTarget, szExt );
	}

//------------------------------------------------------------------
// return free space on specified drive
//------------------------------------------------------------------
DWORD FreeDiskSpace( char cDrive )
	{
	DWORD dwBytesFree;
#if defined(_WIN32) || defined(__WIN32__)
	DWORD dwSectorsPC;
	DWORD dwBytesPS;
	DWORD dwNFreeC;
	DWORD dwTotalNC;
	char szRoot[4];
	
	szRoot[0] = cDrive;
	szRoot[1] = ':';
	szRoot[2] = '\\';
	szRoot[3] = '\0';
	
	if (GetDiskFreeSpace (szRoot, &dwSectorsPC, &dwBytesPS, 
								  &dwNFreeC, &dwTotalNC) == 0)
		return 0;
#else
#define dwBytesPS	d_stat.bytes_per_sector
#define dwSectorsPC d_stat.sectors_per_cluster
#define dwNFreeC	d_stat.avail_clusters
	int nUDrive;
	struct diskfree_t d_stat;

	nUDrive = toupper( (int) cDrive );
	nUDrive -= 64;

	if (_dos_getdiskfree( nUDrive, &d_stat))
		return 0;
#endif
	dwBytesFree = (dwBytesPS * dwSectorsPC) * dwNFreeC;
	
	if (dwBytesFree == 0)
		{
			// reserve zero for error.
		return 1;
		}
		
	// Check for overflow
	if (1 == (((dwBytesFree / dwBytesPS)
							/ dwSectorsPC)
							/ dwNFreeC))
		return dwBytesFree;
	else
		return 0xFFFFFFFF;
	}
//------------------------------------------------------------------
// remove a bunch of files in a single blow.
//------------------------------------------------------------------
#if defined(_WIN32) || defined(__WIN32__)
void RemoveFiles( LPSTR szTemplate )
	{
	WIN32_FIND_DATA fd;
	HANDLE fh;
	char szT1[ _MAX_PATH + 2 ];

	if(( fh = FindFirstFile( szTemplate, &fd )) != INVALID_HANDLE_VALUE )
		{
		if( lstrlen( fd.cAlternateFileName ))
			{
			MakePath( path_part( szTemplate ), fd.cAlternateFileName, szT1 );
			}
		else
			{
			MakePath( path_part( szTemplate ), fd.cFileName, szT1 );
			}
		_unlink( szT1 );

		while( FindNextFile( fh, &fd ))
			{
			if( lstrlen( fd.cAlternateFileName ))
				{
				MakePath( path_part( szTemplate ), fd.cAlternateFileName, szT1 );
				}
			else
				{
				MakePath( path_part( szTemplate ), fd.cFileName, szT1 );
				}
			_unlink( szT1 );
			}
		FindClose( fh );
		}
	}
#else
void RemoveFiles( LPSTR szTemplate )
	{
	char szT1[ _MAX_PATH + 2 ];
	struct _find_t ft;
	if( FindFile( 0x4E, szTemplate, &ft, szT1 ) != NULL )
		{
		_unlink( szT1 );
		while( FindFile( 0, szTemplate, &ft, szT1 ) != NULL )
			{
			_unlink( szT1 );
			}
		}
	}
#endif

//------------------------------------------------------------------
// remove extranious characters from serial numbers.
// return TRUE if not all zeros. (prevent this as a valid serial number)
//------------------------------------------------------------------
int SNPackStr( LPSTR lpOut, LPSTR lpIn )
	{
	int nZedTrap = 0;
	char FAR *lpIptr;
	char FAR *lpOptr;
	
	lpIptr = lpIn;
	lpOptr = lpOut;

	do
		{
		if ( *lpIptr == '\0' )
			{
			*lpOptr = '\0';
			break;
			}

			// only copy numbers and null.
		if ( ( *lpIptr >= '0' ) && ( *lpIptr <= '9' )) 
			{
			*lpOptr = *lpIptr;
			
			if ( *lpOptr != '0' ) 
				{
				nZedTrap = 1;
				}
			++lpOptr;
			}
		} while ( *lpIptr++ );

	return nZedTrap;
	}
//------------------------------------------------------------------
// insert a line in WININIT.INI
//------------------------------------------------------------------
void AddToWininit( LPSTR pszLine )
	{
	int fSectionHeader = 0;
	unsigned int fInserted = 0, uSize;
	int buffsize;
	int fSection = FALSE;
	long lOffset = 0L;
	LPSTR ptr; 
	char lpFile[ _MAX_PATH + 2 ]; 
	char szBuf[ ( _MAX_PATH * 2 ) + 2 ];
	HFILE fh;

	MakePath( lpWinPath, szC_Wininit, lpFile );
	buffsize = _MAX_PATH * 2 ;

	if( QueryFileExists( lpFile ) > 0 )
		{
		if (( fh = _lopen( lpFile, READ_WRITE | OF_SHARE_EXCLUSIVE )) 
													!= HFILE_ERROR ) 
			{
			while( GetLine( fh, (LPSTR)szBuf, buffsize ))
				{
				strip_leading( szBuf, " \t" );
				strip_trailing( szBuf, " \t" );

				// skip blank lines and comments
				if ((szBuf[0] == '\0') || (szBuf[0] == ';'))
					{
					goto SaveOffset;
					}

				if ( szBuf[0] == '[') 
					{
					if ( fSection == TRUE ) 
						{
							// ...then we're entering a new section... 
							// seek back to before the current read.
						_llseek( fh, lOffset, SEEK_SET );
							// add line here then add rest of file.
							// this will terminate the process.
						goto InsertLine;
						} 
					else 
						{
						lstrcpy( szBuf, szBuf + 1 );
						strip_trailing( szBuf, "] " );

						// check for section name
						if ( lstrcmpi( szBuf, szC_IniRename ) != 0) 
							{
								// wrong section, save offset and continue.
							goto SaveOffset;
							}

							// got the right section!
							// set found flags. 
						fSection = TRUE;
						fSectionHeader = 1;
							// save offset...
						goto SaveOffset;
						} 
					} // end of if '[' 
				else 
					{ // not a section heading, just a line...
					if ( fSection )
						{
						continue;	
						} 
					} 
	InsertLine:
					// read remainder of file into temp buffer
				uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
				ptr = (LPSTR)GetMem( uSize );
				uSize = _lread( fh, ptr, uSize );

					// seek back to previous read.
				_llseek( fh, lOffset, SEEK_SET );

				// write new line
				sswrite( fh, pszLine, lstrlen( pszLine ));
				sswrite( fh, "\r\n", 2 );
				fInserted = 1;

				// write remainder of file
				sswrite( fh, ptr, uSize );
				_ffree( ptr );
					// force end of while ( GetLine ).
				break;

	SaveOffset:
					// save position of end of line just read.
				lOffset = _llseek( fh, 0L, SEEK_CUR );
				} // end of while GetLine().

				// we never found the proper line and we are now
				// positioned at the end of the file.
				// write new line, adding section header if necessary.
			if ( fInserted == 0 ) 
				{
				if ( fSectionHeader == 0) 
					{
					if (lOffset > 0L )
						{
						sswrite( fh, "\r\n", 2 );
						}
					wsprintf( szBuf, "[%s]\r\n", szC_IniRename );
					sswrite( fh, szBuf, lstrlen( szBuf ));
					fSectionHeader = 1;
					}

				sswrite( fh, pszLine, lstrlen( pszLine ));
				sswrite( fh, "\r\n", 2 );
				}
			_lclose( fh );
			} // end of if (file open)
		else
			{
			wsprintf( szBuf, szFmtMsg_BadOpen, lpFile );
			MessageBox( hParent, szBuf, szBuff_Title, MB_OK | MB_ICONHAND );
			}
		}
	else
		{
			// we get to make it.
		if(( fh = _lcreat( lpFile, 0 )) != HFILE_ERROR )
			{
			wsprintf( szBuf, "[%s]\r\n", szC_IniRename );
			sswrite( fh, szBuf, lstrlen( szBuf ));
			sswrite( fh, pszLine, lstrlen( pszLine ));
			sswrite( fh, "\r\n", 2 );
			_lclose( fh );
			}
		else
			{
			wsprintf( szBuf, szFmtMsg_BadCreate, lpFile );
			MessageBox( hParent, szBuf, szBuff_Title, MB_OK | MB_ICONHAND );
			}
		}
	} // end of function.

//------------------------------------------------------------------
// Modify an element from a line in an ini file.
//------------------------------------------------------------------
void ModifyProfileString( LPSTR szSec, LPSTR szLine, 
						  LPSTR szElement, LPSTR szFile, BOOL bDelete )
	{
	LPSTR lpParse;
	LPSTR lpOut;
	LPSTR lpNext;
	LPSTR lpSearch;
	LPSTR lpLowEle;
	BOOL bDone;
	UINT uPSize;
	UINT uEleSize;
	UINT uDRet;

	uPSize=512;
	uEleSize = lstrlen( szElement + 1 );
	lpParse = (LPSTR)GetMem( uPSize ); 
	lpOut = (LPSTR)GetMem( uPSize ); 
	lpLowEle = (LPSTR)_fstrlwr(_fstrdup( szElement ));
	do
		{
		bDone = FALSE;
		uDRet = GetPrivateProfileString( szSec, szLine, "", lpParse, 
													uPSize, szFile );
		if(( uDRet + uEleSize ) < ( uPSize	+ 2 ))
			{
			bDone = TRUE;
			}
		else
			{
			uPSize *= 2;
			lpParse = (LPSTR)ReAllocMem( lpParse, uPSize );
			lpOut = (LPSTR)ReAllocMem( lpOut, uPSize );
			}
		} while ( !bDone );

		// now we check each seperate entry and if it does not concern us,
		// we write it to the line we are constructing.
	lpNext = _fstrtok( _fstrlwr( lpParse ), " " );
	_fstrcpy( lpOut, szC_Null );
	if( !bDelete )
		{
			// add our element, first in line.
		_fstrcat( lpOut, lpLowEle );
		if( lpNext )
			{
			_fstrcat( lpOut, " " );
			}
		}

	while( lpNext )
		{
			// if we find our element, skip it.
		if(( lpSearch = _fstrstr( lpNext, lpLowEle )) == NULL )
			{
				// otherwise, add it to the new line.
			_fstrcat( lpOut, lpNext );
			_fstrcat( lpOut, " " );
			}
		lpNext = _fstrtok( NULL, " " );
		}

		// write it back to the file.
	WritePrivateProfileString( szSec, szLine, lpOut, szFile );

		// let the memory go free!
	_ffree( lpParse );
	_ffree( lpOut );
	_ffree( lpLowEle );
	}
	
//------------------------------------------------------------------
// we only need thunk lib in 16 bit mode.
#ifdef _WIN16
//------------------------------------------------------------------
// Add the 32 bit functions.
//------------------------------------------------------------------
void LoadThunkLib()
	{
	char szT1[ _MAX_PATH + 2 ];

	if( hlibThunk != NULL )
		{
		return;
		}

		// see if both libs are there before we try to load them.
	MakePath( lpProgPath,  szC_Thunk32Name, szT1 );
	if( QueryFileExists( szT1 ) <= 0 )
		{
		return;
		}
	
	MakePath( lpProgPath, szC_ThunkLibName, szT1 );
// For some reason, this fails if the program is run from the add/remove
// programs icon in the control panel. 
//	  if( QueryFileExists( szC_ThunkLibName ) <= 0 )
//		  {
//		  return;
//		  }
		
		// szT1 still contains the library name.
	if (( hlibThunk = LoadLibrary( szT1 )) < 32 )
		{
		hlibThunk = NULL;
		return;
		}

	if ( !( lpfnChangePEVersionNumbers = 
			( LPFNCHANGEPEVERSIONNUMBERS )GetProcAddress( hlibThunk, 
										"ChangePEVersionNumbers") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnItsOurDLL = ( LPFNITSOURDLL )GetProcAddress( hlibThunk, 
															"ItsOurDLL") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnAddReg = ( LPFNADDREG )GetProcAddress( hlibThunk, 
													  "AddReg") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnCompareVersionInfo = 
					   ( LPFNCOMPAREVERSIONINFO )GetProcAddress( hlibThunk, 
													"CompareVersionInfo") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnIs95Ver = 
					   ( LPFNIS95VER )GetProcAddress( hlibThunk, "Is95Ver") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnDelKey = ( LPFNDELKEY )GetProcAddress( hlibThunk, "DelKey")))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnRenameValue = ( LPFNRENAMEVALUE )GetProcAddress( hlibThunk, 
															"RenameValue") ))
		{
		FreeThunkLib();
		return;
		}

	if ( !( lpfnDoesValueExist = 
		( LPFNDOESVALUEEXIST )GetProcAddress( hlibThunk, "DoesValueExist")))
		{
		FreeThunkLib();
		return;
		}
	}

//------------------------------------------------------------------
void FreeThunkLib()
	{
	if ( hlibThunk )
		{
		FreeLibrary( hlibThunk );
		hlibThunk = NULL;
		}
	}

#endif

//------------------------------------------------------------------
// Does an INI file section exist?
//------------------------------------------------------------------
BOOL DoesSectionExist( LPSTR lpFile, LPSTR szSection )
	{
	HFILE fh;
	int buffsize = 80;
	LPSTR lptr; 
	char szBuf[ 80 + 2 ];
	BOOL bRet = FALSE;

	if( QueryFileExists( lpFile ) > 0 )
		{
		if (( fh = _lopen( lpFile, READ | OF_SHARE_COMPAT )) != HFILE_ERROR )
			{
			while( !bRet && GetLine( fh, (LPSTR)szBuf, buffsize ))
				{
				strip_leading( szBuf, " \t" );
				strip_trailing( szBuf, " \t" );

				if ( szBuf[0] != '[') 
					{
					continue;
					} 
				
				szBuf[0] = ' ';
				if(( lptr = _fstrrchr( szBuf, ']' )) != NULL )
					{
					*lptr = '\0';
					}
				
				strip_leading( szBuf, " \t" );
				strip_trailing( szBuf, " \t" );
					// if it doesn't match...
				if( _fstricmp( szBuf, szSection ))
					{
						// keep going.
					continue;
					}
					// we got the section...
				bRet = TRUE;
				break;
				}
			_lclose( fh );
			}
		}
	return bRet;
	}

//------------------------------------------------------------------
#if defined(_WIN32) || defined(__WIN32__)
// Add uninstall info to the registry  
//------------------------------------------------------------------
int AddUninstall( LPSTR lpProdName, LPSTR lpProdKey, LPSTR lpUString )
	{
	int nRet;
	HKEY hk;
	char szKey[ _MAX_KEY + 2 ];
	DWORD dwDisposition; // REG_CREATED_NEW_KEY or REG_OPENED_EXISTING_KEY
	SECURITY_ATTRIBUTES sa = { sizeof( SECURITY_ATTRIBUTES ), NULL, FALSE };

	nRet = TRUE;
	MakePath( szC_HK_Uninstall, lpProdKey, szKey );
	if (RegCreateKeyEx( HKEY_LOCAL_MACHINE, szKey, 0, 
						"??ClassName=", REG_OPTION_NON_VOLATILE, 
						KEY_ALL_ACCESS, &sa, &hk, &dwDisposition ) 
												 == ERROR_SUCCESS)
		{
		if (RegSetValueEx( hk, szC_HK_UDName, 0, REG_SZ,
				(LPBYTE)lpProdName, lstrlen( lpProdName ) ) != ERROR_SUCCESS)
			{
			nRet = FALSE;
			}
		
		if (RegSetValueEx( hk, szC_HK_UDString, 0, REG_SZ,
				(LPBYTE)lpUString, lstrlen( (LPSTR)lpUString )) != ERROR_SUCCESS)
			{
			nRet = FALSE;
			}
		
		RegCloseKey( hk );
		}
	else
		{
		nRet = FALSE;
		}
	
	if( nRet == FALSE )
		{
		MessageBox( GetFocus(), szEMsg_AddUI, szMsg_Warning, MB_OK );
		}

	return nRet;
	}

//------------------------------------------------------------------
// Remove uninstall from registry
//------------------------------------------------------------------
int RemoveUninstall( LPSTR lpProdKey  )
	{
	int nRet;
	HKEY hk;

	nRet = FALSE;
	if (RegOpenKeyEx( HKEY_LOCAL_MACHINE, szC_HK_Uninstall, 0, 
					  KEY_ALL_ACCESS, &hk ) == ERROR_SUCCESS)
		{
		RegDeleteKey( hk, lpProdKey );
		RegCloseKey( hk );
		nRet = TRUE;
		}

	if( nRet == FALSE )
		{
		MessageBox( GetFocus(), szEMsg_RemUI, szMsg_Warning, MB_OK );
		}

	return nRet;
	}

//------------------------------------------------------------------
// Kludge around GetShortPathName's mishandling of substitute drive names.
//------------------------------------------------------------------
DWORD MyGetShortPathName( LPSTR szSrc, LPSTR szDst, DWORD dwLen )
	{
	int nLen;

		// Windows 95 has a bug that returns D:\Directory when 
		// d:\ is fed to GetShortPathName. Don't let this happen.
	if( bWin95 && (!bWinNT) )
		{
		nLen = lstrlen( szSrc );

		if( ( nLen > 0 )
		 && ( nLen < 4 )
		 && (( nLen < 3 ) || ( szSrc[2] == '\\' ))
		 && (( nLen < 2 ) || ( szSrc[1] == ':' )))
			{
			_fstrcpy( szDst, szSrc );
			return (DWORD)nLen;
			}
		}
	return GetShortPathName( szSrc, szDst, dwLen );
	}


//------------------------------------------------------------------
#endif
// _WIN32
//------------------------------------------------------------------
