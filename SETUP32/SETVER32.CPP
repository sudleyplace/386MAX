// $Header:   P:/PVCS/MAX/SETUP32/SETVER32.CPV   1.2   25 Sep 1996 14:02:40   BOB  $
//------------------------------------------------------------------
// SETVER32.CPP
// 32 Bit Version Functions for Setup
// Version 1.0
// 20 Aug, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
//------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <winver.h>

#pragma pack(1)
#include <winnt.h>
#include <winternl.h>
#pragma pack()

#include <setup32.h>

	//	keep these local.
int QueryFileExists( LPSTR pszFileName);
void *MyAlloc( DWORD dwBytes );
void MyFree( LPCVOID vp );

	// version VerQueryValue keys.
LPSTR szC_VQVTranslation = "\\VarFileInfo\\Translation";
LPSTR szC_VQVSFInfo = "\\StringFileInfo\\%04x%04x\\";
LPSTR szC_VQVCoName = "CompanyName";
LPSTR szC_Us = "qualitas";
LPSTR szC_VQVProdVer = "ProductVersion";
LPSTR szC_VQVFileVer = "FileVersion";
	
	// wide strings.
LPWSTR szC_VQVWProdVer = L"ProductVersion";
LPWSTR szC_VQVWFileVer = L"FileVersion";

//------------------------------------------------------------------
typedef struct _tagVersionInfo
	{
	WORD wLength;
	WORD wValueLength;
	WORD bText;
#pragma warning (disable:4200)	// Disable warning for zero-sized array
	WCHAR szKey[];
#pragma warning (default:4200)	// Back to normal
	// BYTE padding1[];
	// VS_FIXEDFILEINFO Value;
	// BYTE padding2[];
	// BYTE Children[];
	} VERSIONINFO, *PVERSIONINFO;


BOOL FindPEVersionOffset( LPSTR lpFile, DWORD *dwRetOff, DWORD *dwTotLen );
LPBYTE GetPEVersionResource( LPSTR szSrc, DWORD *pdwRetOff, DWORD *pdwTotLen );
BOOL GetPETargetInfo( LPSTR szImage,
				 DWORD *dwFileVerMS, DWORD *dwFileVerLS,  
				 DWORD *dwProdVerMS, DWORD *dwProdVerLS, 
				 LPSTR szFileID, int *nFIDLen, 
				 LPSTR szProdID, int *nPIDLen );

BOOL ModifyPEVersionBlock( LPBYTE lpVer, DWORD dwFileVerMS, DWORD dwFileVerLS, 
						   DWORD dwProdVerMS, DWORD dwProdVerLS, 
						   LPSTR szFileID, int nFIDLen, 
						   LPSTR szProdID, int nPIDLen );

DWORD CheckResourceDirectory( HFILE hf, PIMAGE_RESOURCE_DIRECTORY lpResDir );
DWORD GetEnclosingSectionHeader (HFILE hFile,  DWORD rva,
								 DWORD dwWinHdrOff,  
								 PIMAGE_NT_HEADERS pNTHeader,
								 PIMAGE_SECTION_HEADER pSection);

void A2W (LPWSTR lpDest, LPSTR lpSrc);
void W2A (LPSTR lpDest, LPWSTR lpSrc, DWORD dwSize);
DWORD RoundUp (DWORD dw, int i);
LPWSTR WINAPI lstrcpyQ (LPWSTR lpString1, LPCWSTR lpString2);
LPWSTR WINAPI lstrcpynQ (LPWSTR lpString1, LPCWSTR lpString2, int iMaxLength);
int WINAPI lstrlenQ (LPCWSTR lpString);
int WINAPI lstrcmpQ (LPCWSTR lpString1, LPCWSTR lpString2 );

PVERSIONINFO NextVer( PVERSIONINFO pv );
LPBYTE GetVerValue( PVERSIONINFO pv );

extern "C" BOOL WINAPI thk_ThunkConnect32 (LPSTR, LPSTR, DWORD, DWORD);

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI 
DllMain( HINSTANCE hDllInst, DWORD fdwReason, LPVOID lpvReserved )
	{
	if( !thk_ThunkConnect32( "SETUP16.DLL", "SETUP32.DLL", (DWORD)hDllInst, fdwReason ))
		{
		return FALSE;
		}

	switch( fdwReason )
		{
		case DLL_PROCESS_ATTACH :
			break;
		case DLL_PROCESS_DETACH :
			break;
		case DLL_THREAD_ATTACH :
			break;
		case DLL_THREAD_DETACH :
			break;
		}
	return TRUE;
	}

//------------------------------------------------------------------
// Make version numbers match another dll.
//------------------------------------------------------------------
EXPORT32 BOOL WINAPI ChangePEVersionNumbers32( LPSTR szSrc, LPSTR szDst, LPSTR szImage )
	{
	HFILE hSrc = 0;
	HFILE hDst = 0;
	HANDLE hSrch;
	BOOL bRet = TRUE;
	LPBYTE lpVer;
	int nBuffSize;
	unsigned int uSize;
	unsigned int uBytesRead;
	unsigned int uBytesWritten;
	DWORD dwOffset;
	DWORD dwLen;
	DWORD dwToRead;
	DWORD dwFileVerMS;
	DWORD dwFileVerLS;
	DWORD dwProdVerMS;
	DWORD dwProdVerLS;
	char szFileID[ 160 ];
	int nFIDLen;
	char szProdID[ 160 ];
	int nPIDLen;
	WIN32_FIND_DATA ft;
	FILETIME ftCreate, ftAccess, ftWrite;
	char *lpBuf;

	if(( hSrch =  FindFirstFile( szSrc, &ft )) == INVALID_HANDLE_VALUE )
		{
		return FALSE;
		}
	FindClose( hSrch );
	
		// make a read buffer.
	nBuffSize = 32000;
	do
		{
		if (( lpBuf = (char *)malloc( nBuffSize )) == NULL )
			{
			nBuffSize /= 2;
			if( nBuffSize <= 1000 )
				{
				return FALSE;
				}
			}
		} while(( lpBuf == NULL ) && ( nBuffSize > 1000 ));

	if(( lpVer = GetPEVersionResource( szSrc, &dwOffset, &dwLen )) != NULL )
		{
			// Get target version info.
		if( !GetPETargetInfo( szImage, &dwFileVerMS, &dwFileVerLS, 
						 &dwProdVerMS, &dwProdVerLS, 
						 szFileID, &nFIDLen, 
						 szProdID, &nPIDLen ))
			{
			bRet = FALSE;
			goto AllDone;
			}

			// Modify the version block.
		if( !ModifyPEVersionBlock( lpVer, dwFileVerMS, dwFileVerLS, 
							  dwProdVerMS, dwProdVerLS, 
							  szFileID, nFIDLen, 
							  szProdID, nPIDLen ))
			{
			bRet = FALSE;
			goto AllDone;
			}
		
			// copy the file up to the version block.
		if (( hSrc = _lopen( szSrc, OF_READ | OF_SHARE_COMPAT )) == HFILE_ERROR) 
			{
			bRet = FALSE;
			goto AllDone;
			}

			// create or truncate target file
		if (( hDst = _lcreat( szDst, 0 )) == HFILE_ERROR ) 
			{
			bRet = FALSE;
			goto AllDone;
			}

			// copy up to the offset
		dwToRead = dwOffset;
		while( dwToRead > 0 )
			{
			uSize = ( dwToRead > (DWORD)nBuffSize ) ? nBuffSize 
													: (UINT) dwToRead; 
			
			if (( uBytesRead = _lread( hSrc, lpBuf, uSize )) == HFILE_ERROR )
				{
				bRet = FALSE;
				goto AllDone;
				}

			if (( uBytesWritten = _lwrite( hDst, lpBuf, uBytesRead )) == HFILE_ERROR) 
				{
				bRet = FALSE;
				break;
				}

				// check for write error.
			if ( uBytesRead != uBytesWritten ) 
				{
				bRet = FALSE;
				break;
				}

			dwToRead -= uBytesRead;
			}

			// write the new version block.
		if (( uBytesWritten = _lwrite( hDst, (LPSTR)lpVer, (UINT)dwLen )) 
												   == HFILE_ERROR) 
			{
			bRet = FALSE;
			goto AllDone;
			}

			// write the rest of the file.
		dwToRead = (DWORD)( ft.nFileSizeLow ) - ( dwOffset + dwLen );
		_llseek( hSrc,	dwLen,	SEEK_CUR );

		while( dwToRead > 0 )
			{
			uSize = ( dwToRead > (DWORD)nBuffSize ) ? nBuffSize 
													: (UINT) dwToRead; 
			
			if (( uBytesRead = _lread( hSrc, lpBuf, uSize )) == HFILE_ERROR )
				{
				bRet = FALSE;
				goto AllDone;
				}

			if (( uBytesWritten = _lwrite( hDst, lpBuf, uBytesRead )) == HFILE_ERROR) 
				{
				bRet = FALSE;
				break;
				}

				// check for write error.
			if ( uBytesRead != uBytesWritten ) 
				{
				bRet = FALSE;
				break;
				}
			dwToRead -= uBytesRead;
			}

	AllDone:
		if( lpBuf != NULL )
			{
			free( lpBuf );
			}

		if( lpVer != NULL )
			{
			free( lpVer );
			}
			
			// make the times the same.
		GetFileTime( (HANDLE)hSrc, &ftCreate, &ftAccess, &ftWrite );
		SetFileTime( (HANDLE)hDst, &ftCreate, &ftAccess, &ftWrite );

		if ( hSrc > 0 )
			{
			_lclose( hSrc );
			}

		if ( hDst > 0 ) 
			{
			_lclose( hDst );

				// if an error writing to the output file, delete it
			if ( !bRet )
				{
				_unlink( szDst );
				}
			}
		}
	else
		{
		free( lpBuf );
		return FALSE;
		}
	return bRet;
	}

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI Is95Ver32( LPSTR szOld )
	{
	DWORD dwHOld;
	DWORD dwSizeOld;
	BOOL bRet = FALSE;
	unsigned dwSOld;
	VS_FIXEDFILEINFO FAR *lpVIOld;
	LPSTR lpOldData;

		// can't check it if it isn't there.
	if( QueryFileExists( szOld ) <= 0 )
		{
		return FALSE;
		}

	dwSizeOld = GetFileVersionInfoSize( szOld, (DWORD FAR *) &dwHOld );
	if( !dwSizeOld )
		{
		return FALSE;
		}
	
	lpOldData = (LPSTR)MyAlloc( dwSizeOld + 2 );

	if( GetFileVersionInfo( szOld, dwHOld, dwSizeOld, lpOldData ))
		{
		if( VerQueryValue( lpOldData, "\\", (void FAR * FAR *)&lpVIOld, &dwSOld ))
			{
			if( !lpVIOld )
				{
				bRet = FALSE ;
				}
			else
				{
					// check the major number.
				if( 4 > HIWORD( lpVIOld->dwProductVersionMS ))
					{
					bRet = TRUE;
					}
				}
			}
		}
	MyFree( lpOldData );
	return bRet;
	}


//------------------------------------------------------------------
EXPORT32 DWORD WINAPI CompareVersionInfo32( LPSTR szOld, LPSTR szNew )
	{
	DWORD dwHOld;
	DWORD dwHNew;
	DWORD dwSizeOld;
	DWORD dwSizeNew;
	unsigned dwSOld;
	unsigned dwSNew;
	DWORD dwRet = CVI32_FAILED;
	VS_FIXEDFILEINFO FAR *lpVIOld;
	VS_FIXEDFILEINFO FAR *lpVINew;
	LPSTR lpOldData;
	LPSTR lpNewData;

		// can't check it if it isn't there.
	if( QueryFileExists( szOld ) <= 0 )
		{
		dwRet = CVI32_SUCCESS;
		dwRet |= CVI32_REPLACE;
		return dwRet;
		}

	dwSizeOld = GetFileVersionInfoSize( szOld, (DWORD FAR *) &dwHOld );
	dwSizeNew = GetFileVersionInfoSize( szNew, (DWORD FAR *) &dwHNew );
	if( (!dwSizeNew) || (!dwSizeOld) )
		{
		return CVI32_FAILED;
		}
	
	lpOldData = (LPSTR)MyAlloc( dwSizeOld + 2 );
	lpNewData = (LPSTR)MyAlloc( dwSizeNew + 2 );

	if(( GetFileVersionInfo( szOld, dwHOld, dwSizeOld, lpOldData )) &&
	   ( GetFileVersionInfo( szNew, dwHNew, dwSizeNew, lpNewData )))
		{
		if(( VerQueryValue( lpOldData, "\\", (void FAR * FAR *)&lpVIOld, &dwSOld )) &&
		   ( VerQueryValue( lpNewData, "\\",(void FAR * FAR *) &lpVINew, &dwSNew )))
			{
			if( (!lpVIOld) || ( !lpVINew ))
				{
				dwRet = CVI32_FAILED;
				}
			else
				{
				dwRet |= CVI32_SUCCESS;

				// first check the product info.
				if( lpVIOld->dwProductVersionMS > lpVINew->dwProductVersionMS )
					{
					dwRet |= CVI32_PRODOLDER;
					}

				if( lpVIOld->dwProductVersionMS < lpVINew->dwProductVersionMS )
					{
					dwRet |= CVI32_PRODNEWER;
					dwRet |= CVI32_REPLACE;
					}

				if( lpVIOld->dwProductVersionMS == lpVINew->dwProductVersionMS )
					{
					if( lpVIOld->dwProductVersionLS > 
						lpVINew->dwProductVersionLS )
						{
						dwRet |= CVI32_PRODOLDER;
						}

					if( lpVIOld->dwProductVersionLS < lpVINew->dwProductVersionLS )
						{
						dwRet |= CVI32_PRODNEWER;
						dwRet |= CVI32_REPLACE;
						}
					}

				if( lpVIOld->dwFileVersionMS > lpVINew->dwFileVersionMS )
					{
					dwRet |= CVI32_FILEOLDER;
					}

				if( lpVIOld->dwFileVersionMS < lpVINew->dwFileVersionMS )
					{
					dwRet |= CVI32_FILENEWER;
					dwRet |= CVI32_REPLACE;
					}

				if( lpVIOld->dwFileVersionMS == lpVINew->dwFileVersionMS )
					{
					if( lpVIOld->dwFileVersionLS > lpVINew->dwFileVersionLS )
						{
						dwRet |= CVI32_FILEOLDER;
						}

					if( lpVIOld->dwFileVersionLS < lpVINew->dwFileVersionLS )
						{
						dwRet |= CVI32_FILENEWER;
						dwRet |= CVI32_REPLACE;
						}
					}
				}
			}
		}

	MyFree( lpOldData );
	MyFree( lpNewData );
	return dwRet;
	}

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI ItsOurDLL32( LPSTR szFileName )
	{
	DWORD dwHOld;
	DWORD dwSizeOld;
	void FAR * FAR *lpTrans;
	unsigned dwSOld;
	BOOL bRet = TRUE;
	LPSTR lpCo;
	LPSTR lpFound;
	LPSTR lpOldData;
	char szT1[ _MAX_PATH + 2 ];
	char szFmt[ _MAX_PATH + 2 ];

		// can't check it if it isn't there.
	if( QueryFileExists( szFileName ) <= 0 )
		{
		return TRUE;
		}

	dwSizeOld = GetFileVersionInfoSize( szFileName, (DWORD FAR *) &dwHOld );

	if( !dwSizeOld )
		{
			// this is to prohibit overwriting the existing DLL.
		return TRUE;
		}

			// allocate a buffer.
	if(( lpOldData = (LPSTR)MyAlloc( dwSizeOld + 2 )) == NULL )
		{
		return TRUE;
		}
			
			// fill said buffer.
	if( GetFileVersionInfo( szFileName, dwHOld, dwSizeOld, lpOldData ))
		{
			// get the translation code.
		if( VerQueryValue( lpOldData, szC_VQVTranslation, 
						   (void FAR * FAR *)&lpTrans, &dwSOld ))
			{
				// format into instruction to get company name.
			strcpy( szFmt, szC_VQVSFInfo );
			strcat( szFmt, szC_VQVCoName );
			wsprintf( szT1, szFmt, LOWORD(*lpTrans), HIWORD(*lpTrans));
			if( VerQueryValue( lpOldData, szT1, 
							   (void FAR * FAR *)&lpCo, &dwSOld ))
				{
					// see if the string "qualitas" is found.
				if(( lpFound = strstr( strlwr( lpCo ), szC_Us )) != NULL )
					{
					bRet = TRUE;
					}
				else
					{
					bRet = FALSE;
					}
				}
			}
		}

	MyFree( lpOldData );
	return bRet;
	}

//------------------------------------------------------------------
int QueryFileExists( LPSTR pszFileName)
	{
	WIN32_FIND_DATA fd;
	HANDLE fh;

	if(( fh = FindFirstFile( pszFileName, &fd )) != INVALID_HANDLE_VALUE )
		{
		return 1;
		}
	return 0;
	}

//------------------------------------------------------------------
// szValName= NULL sets default value.
//------------------------------------------------------------------
EXPORT32 BOOL WINAPI AddReg32( HKEY hkRootKey, LPSTR szKey, LPSTR szValName,
						LPBYTE szVal, DWORD dwType, DWORD dwLen )
	{
	HKEY hk;
	BOOL bRet = FALSE;
	DWORD dwDisposition; // REG_CREATED_NEW_KEY or REG_OPENED_EXISTING_KEY
	SECURITY_ATTRIBUTES sa = { sizeof( SECURITY_ATTRIBUTES ), NULL, FALSE };

	if (RegCreateKeyEx( hkRootKey, szKey, 0, 
						"??ClassName=", REG_OPTION_NON_VOLATILE, 
						KEY_ALL_ACCESS, &sa, &hk, &dwDisposition ) 
												 == ERROR_SUCCESS)
		{
		if( szVal && ( dwLen > 0 ))
			{
			if( RegSetValueEx( hk, szValName, 0, dwType,
							   (LPBYTE)szVal, dwLen ) 
							   == ERROR_SUCCESS)
				{
				bRet = TRUE;
				}
			}
		else
			{
				// success on key creation.
			bRet = TRUE;
			}

		RegCloseKey( hk );
		}
	return bRet;
	}

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI DelKey32( HKEY hkRootKey, LPSTR szParentKey, LPSTR szDelKey )
	{
	BOOL bRet = FALSE;
	HKEY hk;
	if (RegOpenKeyEx( hkRootKey, szParentKey, 0, 
					  KEY_ALL_ACCESS, &hk ) == ERROR_SUCCESS)
		{
		if( RegDeleteKey( hk, szDelKey ) == ERROR_SUCCESS )
			{
			bRet = TRUE;
			}
		RegCloseKey( hk );
		}
	return bRet;
	}

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI RenameValue32( HKEY hkRootKey, LPSTR szKey, 
							 LPSTR szOldValName, LPSTR szNewValName )
	{
	HKEY hk;
	BOOL bRet = FALSE;
	DWORD dwValType;
	DWORD dwValLen;
	LPBYTE lpVal;
								
			// the key in question must exist.
	if (RegOpenKeyEx( hkRootKey, szKey, 0, KEY_ALL_ACCESS, &hk ) 
											   == ERROR_SUCCESS)
		{
				// request the size.
		if( RegQueryValueEx( hk, szOldValName, 0, &dwValType, 
							 NULL, &dwValLen ) == ERROR_SUCCESS )
			{
			if(( lpVal = (LPBYTE)MyAlloc( dwValLen )) != NULL )
				{
						// get the data.
				if( RegQueryValueEx( hk, szOldValName, 0, &dwValType, 
									 lpVal, &dwValLen ) == ERROR_SUCCESS )
					{
							// make the new entry.
					if( RegSetValueEx( hk, szNewValName, 0, dwValType,
											(LPBYTE)lpVal, dwValLen ) 
													== ERROR_SUCCESS)
						{
								// delete the old one.
						if( RegDeleteValue( hk, szOldValName ) 
											== ERROR_SUCCESS )
							{
							bRet = TRUE;
							}
						}
					}
				MyFree( lpVal );
				}
			}
	
		RegCloseKey( hk );
		}
	return bRet;
	}

//------------------------------------------------------------------
EXPORT32 BOOL WINAPI DoesValueExist32( HKEY hkRootKey, LPSTR szKey, 
									   LPSTR szValName )
	{
	HKEY hk;
	BOOL bRet = FALSE;
	DWORD dwValType;
	DWORD dwValLen;
								
			// the key in question must exist.
	if (RegOpenKeyEx( hkRootKey, szKey, 0, KEY_ALL_ACCESS, &hk ) 
											   == ERROR_SUCCESS)
		{
				// request the size.
		if( RegQueryValueEx( hk, szValName, 0, &dwValType, 
							 NULL, &dwValLen ) == ERROR_SUCCESS )
			{
			bRet = TRUE;
			}

		RegCloseKey( hk );
		}

	return bRet;
	}

//------------------------------------------------------------------
void *MyAlloc( DWORD dwBytes )
	{
	HGLOBAL hg;
	void *pRet = NULL;
   
	if(( hg = GlobalAlloc( GHND, dwBytes )) != NULL )
		{
		pRet = GlobalLock( hg );
		}
	return pRet;
	}

//------------------------------------------------------------------
void MyFree( LPCVOID vp )
	{
	HGLOBAL hg;
	if( vp )
		{
		if(( hg = GlobalHandle( vp )) != NULL )
			{
			GlobalFree( hg );
			}
		}
	}

//------------------------------------------------------------------
// Get a version resource into memory.
//------------------------------------------------------------------
LPBYTE GetPEVersionResource( LPSTR szSrc, DWORD *pdwRetOff, DWORD *pdwTotLen )
	{			
	int err;
	HFILE hFile;
	LPBYTE lpRet = NULL;

	if( FindPEVersionOffset( szSrc, pdwRetOff, pdwTotLen ))
		{
			// Open the file for read-only access
		if(( hFile = _lopen( szSrc, OF_READ )) == HFILE_ERROR )
			{
				// exit, failing.
			return lpRet;
			}
		
		_llseek(hFile, *pdwRetOff, SEEK_SET);
		if(( lpRet = (LPBYTE)malloc( (int)(*pdwTotLen) )) == NULL )
			{
			_lclose (hFile);
			return NULL;
			}

			// Read in the resource.
		if(( err = _lread( hFile, lpRet, (int)(*pdwTotLen) )) == HFILE_ERROR )
			{
			free( lpRet );
			_lclose (hFile);
			return NULL;
			}
		_lclose (hFile);
		}
	return lpRet;
	}

//------------------------------------------------------------------
BOOL FindPEVersionOffset( LPSTR lpFile, DWORD *pdwRetOff, DWORD *pdwTotLen )
	{
	HFILE hFile;
	UINT err;
	PEHEADER hPE;
	WORD EXESign = 0; 
	WORD EXERelo = 0;
	DWORD dwWinHdrOff = 0L;
	DWORD dwRsrcStartRVA;
	DWORD dwResDir;
	DWORD dwVerDir;
	PIMAGE_NT_HEADERS pNTHeader;
	IMAGE_SECTION_HEADER section;
	IMAGE_RESOURCE_DIRECTORY VerHdr;
	IMAGE_RESOURCE_DIRECTORY_ENTRY VerEntry;
	IMAGE_DATA_DIRECTORY VerDataDir;

	*pdwRetOff = 0L;
	*pdwTotLen = 0L;

		// Open the file for read-only access
	if(( hFile = _lopen( lpFile, OF_READ )) == HFILE_ERROR )
		{
			// exit, failing.
		return FALSE;
		}

		// Read in the EXE header signature
	if(( err = _lread( hFile, &EXESign, sizeof( EXESign ))) == HFILE_ERROR )
		{
		goto FPE_ERR;
		}

		// Seek to and read in the relocation offset
	_llseek(hFile, 0x18, SEEK_SET);
	if(( err = _lread( hFile, &EXERelo, sizeof( EXERelo ))) == HFILE_ERROR )
		{
		goto FPE_ERR;
		}

		 // If not valid EXE signature,
		// or if not minimum relocation offset,
	if( EXESign != 'ZM' || EXERelo < 0x40 )
		{
		goto FPE_ERR;
		}

		// Seek to and read in the offset to the PE header
	_llseek (hFile, 0x3C, SEEK_SET);
	if(( err = _lread( hFile, &dwWinHdrOff, sizeof( dwWinHdrOff ))) 
												   == HFILE_ERROR )
		{
		goto FPE_ERR;
		}

		// If not valid offset ...
	if( dwWinHdrOff == 0 )
		{
		goto FPE_ERR;
		}

		// clear the header buffer.
	memset( &hPE, 0, sizeof( PEHEADER ));

		// Seek to and read in the PE header
	_llseek( hFile, dwWinHdrOff, SEEK_SET );
	if(( err = _lread( hFile, &hPE, sizeof( PEHEADER ))) == HFILE_ERROR )
		{
		goto FPE_ERR;
		}

		// validity test.
	if( hPE.Signature != IMAGE_NT_SIGNATURE )
		{
		goto FPE_ERR;
		}
	
		// convert to NTHeader pointer.
	pNTHeader = (PIMAGE_NT_HEADERS) &hPE;

		// get the Virtual Address of the resources.
	dwRsrcStartRVA = pNTHeader->OptionalHeader.DataDirectory
				   [ IMAGE_DIRECTORY_ENTRY_RESOURCE ].VirtualAddress;

		//	Use the RVA to get the IMAGE_SECTION_HEADER that contains 
		//	the exports.
		//	This is usually the .edata section, but it doesn't have to be.
	GetEnclosingSectionHeader( hFile, dwRsrcStartRVA, dwWinHdrOff,
							   pNTHeader, &section);
	
		// Get the raw data address.
	dwResDir  = section.PointerToRawData;	

		// Seek to start of version directory
	_llseek( hFile, dwResDir, SEEK_SET );

	if(( err = _lread( hFile, &VerHdr, sizeof(IMAGE_RESOURCE_DIRECTORY))) 
														 == HFILE_ERROR ) 
		 {
		 goto FPE_ERR;
		 }

		// returns the offset to the RT_VERSION directory table.
	dwVerDir = (DWORD)CheckResourceDirectory( hFile, 
						  (PIMAGE_RESOURCE_DIRECTORY)&VerHdr );  

		// Seek to the version directory.
	_llseek( hFile, dwVerDir + dwResDir, SEEK_SET );

	do
		{
			// Read in the header
			// Assume (NumberOfNamedEntries + NumberOfIDEntries) == 1
		if(( err =_lread( hFile, &VerHdr, sizeof(IMAGE_RESOURCE_DIRECTORY)))
															== HFILE_ERROR ) 
			 {
			 goto FPE_ERR;
			 }

			// Read in the (single) entry
		if(( err =_lread( hFile, &VerEntry, 
						  sizeof( IMAGE_RESOURCE_DIRECTORY_ENTRY )))
													== HFILE_ERROR )		 
			 {
			 goto FPE_ERR;
			 }

		if( VerEntry.DataIsDirectory )
			{
				// Seek to the next level header (D600 + 02A8)
			_llseek( hFile, dwResDir + VerEntry.OffsetToDirectory, SEEK_SET );
			}
		else
			{
			_llseek( hFile, dwResDir + VerEntry.OffsetToData, SEEK_SET );
			}
		} while( VerEntry.DataIsDirectory );

		// Read in the data directory
		if(( err =_lread( hFile, &VerDataDir, sizeof( IMAGE_DATA_DIRECTORY )))
															  == HFILE_ERROR )
			{
			goto FPE_ERR;
			}

		// Convert the virtual address to a raw address
		// return offset and length .
	*pdwRetOff = VerDataDir.VirtualAddress - section.VirtualAddress + dwResDir;
	*pdwTotLen = VerDataDir.Size;

	_lclose (hFile);
	return TRUE;

FPE_ERR:
	_lclose (hFile);
	return FALSE;
	} // End FindPEVersionOffset( )

//------------------------------------------------------------------
//	CheckResourceDirectory ()
//	Check a resource directory for version type
//------------------------------------------------------------------
DWORD
CheckResourceDirectory( HFILE hFile, PIMAGE_RESOURCE_DIRECTORY lpResDir )
	{
	IMAGE_RESOURCE_DIRECTORY_ENTRY VerEntry;
	int i;

	for( i = 0;
		 i < (lpResDir->NumberOfNamedEntries + lpResDir->NumberOfIdEntries);
		 i++ )
		{
			// Read in an entry
		_lread( hFile, &VerEntry, sizeof( IMAGE_RESOURCE_DIRECTORY_ENTRY ));
		if ( VerEntry.Name == (DWORD)RT_VERSION )
			{
			return VerEntry.OffsetToData & 0x7FFFFFFF; 
			}
		}
	return 0;
	} // End CheckResourceDirectory ()
		
//------------------------------------------------------------------
BOOL GetPETargetInfo( LPSTR szImage,
				 DWORD *dwFileVerMS, DWORD *dwFileVerLS,  
				 DWORD *dwProdVerMS, DWORD *dwProdVerLS, 
				 LPSTR szFileID, int *nFIDLen, 
				 LPSTR szProdID, int *nPIDLen )
	{
	DWORD dwHOld;
	DWORD dwSizeOld;
	BOOL bRet = FALSE;
	unsigned uSOld;
	VS_FIXEDFILEINFO FAR *lpVIOld;
	LPSTR lpOldData;
	void FAR * FAR *lpTrans;
	LPSTR lpProdVer;
	LPSTR lpFileVer;
	char szT1[ _MAX_PATH + 2 ];
	char szFmt[ _MAX_PATH + 2 ];

	*nPIDLen = 0;
	*nFIDLen = 0;
	dwSizeOld = GetFileVersionInfoSize( szImage, (DWORD FAR *) &dwHOld );
	if( !dwSizeOld )
		{
		return FALSE;
		}
	
	lpOldData = (LPSTR)malloc( (int) dwSizeOld + 2 );

	if( GetFileVersionInfo( szImage, dwHOld, dwSizeOld, lpOldData ))
		{
		if( VerQueryValue( lpOldData, "\\", (void FAR * FAR *)&lpVIOld, &uSOld ))
			{
			if( !lpVIOld )
				{
				bRet = FALSE ;
				}
			else
				{
				*dwProdVerMS = lpVIOld->dwProductVersionMS;
				*dwProdVerLS = lpVIOld->dwProductVersionLS;
				*dwFileVerMS = lpVIOld->dwFileVersionMS;
				*dwFileVerLS = lpVIOld->dwFileVersionLS;
				
					// get the translation code.
				if( VerQueryValue( lpOldData, szC_VQVTranslation, 
								   (void FAR * FAR *)&lpTrans, &uSOld ))
					{
						// format into instruction to get ProductVersion.
					strcpy( szFmt, szC_VQVSFInfo );
					strcat( szFmt, szC_VQVProdVer );
					wsprintf( szT1, szFmt, LOWORD(*lpTrans), HIWORD(*lpTrans));

					if( VerQueryValue( lpOldData, szT1, 
									   (void FAR * FAR *)&lpProdVer, &uSOld ))
						{
						if( uSOld )
							{
							memcpy( szProdID, lpProdVer, uSOld );  
							*nPIDLen = uSOld;
							}
						else
							{
							szProdID[0] = '\0';
							*nPIDLen = 0;
							}
						}
					
						// format into instruction to get FileVersion.
					strcpy( szFmt, szC_VQVSFInfo );
					strcat( szFmt, szC_VQVFileVer );
					wsprintf( szT1, szFmt, LOWORD(*lpTrans), 
										   HIWORD(*lpTrans));
					if( VerQueryValue( lpOldData, szT1, 
									   (void FAR * FAR *)&lpFileVer, 
									   &uSOld ))
						{
						if( uSOld )
							{
							memcpy( szFileID, lpFileVer, uSOld );  
							*nFIDLen = uSOld;
							}
						else
							{
							szFileID[0] = '\0';
							*nPIDLen = 0;
							}
						}
						// we got it all.
					bRet = TRUE;
					}
				}
			}
		}

	free( lpOldData );
	return bRet;
	}

//------------------------------------------------------------------
BOOL ModifyPEVersionBlock( LPBYTE lpVer, DWORD dwFileVerMS, DWORD dwFileVerLS, 
						   DWORD dwProdVerMS, DWORD dwProdVerLS, 
						   LPSTR szFileID, int nFIDLen,
						   LPSTR szProdID, int nPIDLen )
	{
	int nTargLen;
	LPBYTE lpTarg;
	VS_FIXEDFILEINFO FAR *lpVptr;
	LPWSTR lpW;
	BOOL bOne, bTwo;
	PVERSIONINFO pvLimit;
	PVERSIONINFO pv;

	pv = (PVERSIONINFO)lpVer;
	pvLimit = (PVERSIONINFO)(lpVer + pv->wLength);
	
	lpW = (LPWSTR)(pv->szKey);
	lpW += (1 + lstrlenQ( (LPWSTR)lpW ));	  // at &padding1.
	lpW = (LPWSTR)RoundUp( (DWORD)lpW, 4 );   // at Value.	
	lpVptr = (VS_FIXEDFILEINFO *)lpW;

	if( lpVptr->dwSignature == 0xFEEF04BD )
		{
		lpVptr->dwProductVersionMS = dwProdVerMS;
		lpVptr->dwProductVersionLS = dwProdVerLS;
		lpVptr->dwFileVersionMS = dwFileVerMS;
		lpVptr->dwFileVersionLS = dwFileVerLS;
		}
	else
		{
		return FALSE;
		}

	bOne = FALSE;
	bTwo = FALSE;
	do
		{
		pv = NextVer( pv );
		
		if( !bOne && (!lstrcmpQ( pv->szKey, szC_VQVWProdVer )))
			{
			nTargLen = pv->wValueLength * 2;
			lpTarg = GetVerValue( pv );
			memset( lpTarg, 0, nTargLen );
			A2W( (LPWSTR)lpTarg, szProdID );
			bOne = TRUE;
			}
		
		if( !bTwo && (!lstrcmpQ( pv->szKey, szC_VQVWFileVer )))
			{
			nTargLen = pv->wValueLength * 2;
			lpTarg = GetVerValue( pv );
			memset( lpTarg, 0, nTargLen );
			A2W( (LPWSTR)lpTarg, szFileID );
			bTwo = TRUE;
			}
		} while( ((!bOne) || (!bTwo)) && ( pv <= pvLimit ));

	return TRUE;
	}


//------------------------------------------------------------------
//	GetEnclosingSectionHeader ()
//
//	Given an RVA, look up the section header that encloses it and return a
//	pointer to its IMAGE_SECTION_HEADER
//	From Windows 95 Programming Secrets
//------------------------------------------------------------------

DWORD GetEnclosingSectionHeader (HFILE hFile,
								 DWORD rva,
								 DWORD dwWinHdrOff,
								 PIMAGE_NT_HEADERS pNTHeader,
								 PIMAGE_SECTION_HEADER pSection)
	{
	unsigned i;
	DWORD dwFirstSec;
	DWORD dwOptSec;
   
   dwOptSec = ((LPBYTE)&pNTHeader->OptionalHeader - (LPBYTE)pNTHeader); 
   
		// Position to first section
	dwFirstSec = dwWinHdrOff + dwOptSec +
				 pNTHeader->FileHeader.SizeOfOptionalHeader;
  
	_llseek( hFile,  dwFirstSec, SEEK_SET );
	
	for( i=0; i < pNTHeader->FileHeader.NumberOfSections; i++ )
		{
			// Read in the section header
		_lread (hFile, pSection, sizeof (IMAGE_SECTION_HEADER));
	
			// Is the RVA within this section?
		if( (rva >= pSection->VirtualAddress) && 
			(rva < (pSection->VirtualAddress + pSection->Misc.VirtualSize)))
			{
			return _llseek( hFile, -(int)sizeof( IMAGE_SECTION_HEADER ), SEEK_CUR );
			}
		}
	
	return 0;
	} // End GetEnclosingSectionHeader ()


//****************************************************************************
//	RoundUp ()
//
//	Round up a dword to specified boundary
//****************************************************************************

DWORD RoundUp (DWORD dw, int i)

{
	dw +=  (i - 1);
	dw &= ~(i - 1);
	return dw;

} // End RoundUp ()

//***************************************************************************
//	lstrlenQ ()
//
//	Wide version of lstrlenW ()
//	Note that MSVC doesn't allow one to re-define a dllimport function,
//	hence we can't use a W suffix.
//***************************************************************************

int WINAPI lstrlenQ (LPCWSTR lpString)

	{
	int iLen = 0;
	while (*lpString++)
		iLen++;
	return iLen;
		
	} // End lstrlenQ ()

//************************************************************************
//	A2W ()
//
//	Convert and copy a single byte char string to a wide char string
//************************************************************************

void A2W (LPWSTR lpDest, LPSTR lpSrc)

	{
	int iLen;

	iLen = 1 + lstrlenA (lpSrc);	// Get source length
	MultiByteToWideChar (CP_ACP,	// ANSI code page
						 0, 		// No flags
						 lpSrc, 	// Source
						 iLen,		// Source length
						 lpDest,	// Destin
						 2 * iLen); // Size of buffer
	} // End A2W ()


#if 0
//------------------------------------------------------------------
//	W2A ()
//
//	Convert and copy a wide char string to a single byte char string
//************************************************************************

void W2A (LPSTR lpDest, LPWSTR lpSrc, DWORD dwSize)

{
	int iLen;

	iLen = 1 + lstrlenQ (lpSrc);	// Get source length
	WideCharToMultiByte (CP_ACP,	// ANSI code page
						 0, 		// No flags
						 lpSrc, 	// Source
						 iLen,		// Source length
						 lpDest,	// Destin
						 dwSize,	// Size of buffer
						 NULL,		// Use system default char
						 NULL); 	// Skip notification
} // End W2A ()


//***************************************************************************
//	lstrcpyQ ()
//
//	Wide version of lstrcpyW ()
//	Note that MSVC doesn't allow one to re-define a dllimport function,
//	hence we can't use a W suffix.
//***************************************************************************

LPWSTR WINAPI lstrcpyQ (LPWSTR lpString1, LPCWSTR lpString2)

{
	LPWSTR lpStr = lpString1;

	while (*lpString2)
		*lpString1++ = *lpString2++;
	*lpString1 = _T('\0');

	return lpStr;

} // End lstrcpyQ ()


//***************************************************************************
//	lstrcpynQ ()
//
//	Wide version of lstrcpynW ()
//	Note that MSVC doesn't allow one to re-define a dllimport function,
//	hence we can't use a W suffix.
//***************************************************************************

LPWSTR WINAPI lstrcpynQ (LPWSTR lpString1, LPCWSTR lpString2, int iMaxLength)

{
	LPWSTR lpStr = lpString1;

	if (iMaxLength--)
	{
		while (*lpString2 && iMaxLength--)
			*lpString1++ = *lpString2++;
		*lpString1 = _T('\0');
	} // End IF

	return lpStr;

} // End lstrcpynQ ()

#endif

//------------------------------------------------------------------
int WINAPI lstrcmpQ (LPCWSTR lpString1, LPCWSTR lpString2 )
	{
	while( *lpString1 && *lpString2 )
		{
		if( *lpString1 > *lpString2 )
			{
			return 1;
			}
		if( *lpString2 > *lpString1 )
			{
			return -1;
			}
		lpString1++;
		lpString2++;
		}

	if( *lpString1 )
		{
		return 1;
		}
	if( *lpString2	)
		{
		return -1;
		}
	
	return 0;
	} // End lstrcmpQ ()

//------------------------------------------------------------------
PVERSIONINFO NextVer( PVERSIONINFO pv )
	{
	LPWSTR lpWStr;
	
	lpWStr = (LPWSTR)&pv->szKey;					// at szKey.
	lpWStr += (1 + lstrlenQ( lpWStr )); 	// at &padding1.
	lpWStr = (LPWSTR)RoundUp( (DWORD)lpWStr, 4 );	// at Value.  
		
	if( pv->bText )
		{
		lpWStr += pv->wValueLength;    // at &padding2.
		}
	else
		{
		lpWStr = (LPWSTR)((LPBYTE)lpWStr + pv->wValueLength);	// at &padding2.
		}
	lpWStr = (LPWSTR)RoundUp( (DWORD)lpWStr, 4 );	// to Children.
	return (PVERSIONINFO)lpWStr;
	}

//------------------------------------------------------------------
LPBYTE GetVerValue( PVERSIONINFO pv )
	{
	LPWSTR lpWStr;
	
	lpWStr = (LPWSTR)&pv->szKey;					// at szKey.
	lpWStr += (1 + lstrlenQ( lpWStr )); 	// at &padding1.
	lpWStr = (LPWSTR)RoundUp( (DWORD)lpWStr, 4 );	// at Value.  

	return (LPBYTE)lpWStr;
	}
