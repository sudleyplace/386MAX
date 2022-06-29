// $Header:   P:/PVCS/MAX/SETUP/SETVER.CPV   1.2   20 Jan 1997 08:36:52   PETERJ  $
//------------------------------------------------------------------
// SETVER.CPP
// Version Functions for Setup
// Version 1.0
// 19 Aug, 1996
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

#include <setglob.h>

#pragma pack(1)
#include <winternl.h>
#pragma pack()

        // local functions.
BOOL FindNEVersionOffset( LPSTR lpFile, DWORD *dwRetOff, DWORD *dwTotLen );
LPBYTE GetNEVersionResource( LPSTR szSrc, DWORD *pdwRetOff, DWORD *pdwTotLen );
BOOL GetNETargetInfo( LPSTR szImage,
                 DWORD *dwFileVerMS, DWORD *dwFileVerLS,  
                 DWORD *dwProdVerMS, DWORD *dwProdVerLS, 
                 LPSTR szFileID, LPSTR szProdID );
BOOL ModifyNEVersionBlock( LPBYTE lpVer, DWORD dwFileVerMS, DWORD dwFileVerLS, 
                           DWORD dwProdVerMS, DWORD dwProdVerLS, 
                           LPSTR szFileID, LPSTR szProdID );

//------------------------------------------------------------------
DWORD CompareVersionInfo( LPSTR szOld, LPSTR szNew )
    {
    DWORD dwHOld;
    DWORD dwHNew;
    DWORD dwSizeOld;
    DWORD dwSizeNew;
    unsigned dwSOld;
    unsigned dwSNew;
    DWORD dwRet = CVI_FAILED;
    VS_FIXEDFILEINFO FAR *lpVIOld;
    VS_FIXEDFILEINFO FAR *lpVINew;
    LPSTR lpOldData;
    LPSTR lpNewData;

        // can't check it if it isn't there.
    if( QueryFileExists( szOld ) <= 0 )
        {
        dwRet = CVI_SUCCESS;
        dwRet |= CVI_REPLACE;
        return dwRet;
        }

    dwSizeOld = GetFileVersionInfoSize( szOld, (DWORD FAR *) &dwHOld );
    dwSizeNew = GetFileVersionInfoSize( szNew, (DWORD FAR *) &dwHNew );
    if( (!dwSizeNew) || (!dwSizeOld) )
        {
        return CVI_FAILED;
        }
    
    lpOldData = (LPSTR)GetMem( (int)dwSizeOld + 2 );
    lpNewData = (LPSTR)GetMem( (int)dwSizeNew + 2 );

    if(( GetFileVersionInfo( szOld, dwHOld, dwSizeOld, lpOldData )) &&
       ( GetFileVersionInfo( szNew, dwHNew, dwSizeNew, lpNewData )))
        {
        if(( VerQueryValue( lpOldData, "\\", (void FAR * FAR *)&lpVIOld, &dwSOld )) &&
           ( VerQueryValue( lpNewData, "\\",(void FAR * FAR *) &lpVINew, &dwSNew )))
            {
            if( (!lpVIOld) || ( !lpVINew ))
                {
                dwRet = CVI_FAILED;
                }
            else
                {
                dwRet |= CVI_SUCCESS;

                // first check the product info.
                if( lpVIOld->dwProductVersionMS > lpVINew->dwProductVersionMS )
                    {
                    dwRet |= CVI_PRODOLDER;
                    }

                if( lpVIOld->dwProductVersionMS < lpVINew->dwProductVersionMS )
                    {
                    dwRet |= CVI_PRODNEWER;
                    dwRet |= CVI_REPLACE;
                    }

                if( lpVIOld->dwProductVersionMS == lpVINew->dwProductVersionMS )
                    {
                    if( lpVIOld->dwProductVersionLS > 
                        lpVINew->dwProductVersionLS )
                        {
                        dwRet |= CVI_PRODOLDER;
                        }

                    if( lpVIOld->dwProductVersionLS < lpVINew->dwProductVersionLS )
                        {
                        dwRet |= CVI_PRODNEWER;
                        dwRet |= CVI_REPLACE;
                        }
                    }

                if( lpVIOld->dwFileVersionMS > lpVINew->dwFileVersionMS )
                    {
                    dwRet |= CVI_FILEOLDER;
                    }

                if( lpVIOld->dwFileVersionMS < lpVINew->dwFileVersionMS )
                    {
                    dwRet |= CVI_FILENEWER;
                    dwRet |= CVI_REPLACE;
                    }

                if( lpVIOld->dwFileVersionMS == lpVINew->dwFileVersionMS )
                    {
                    if( lpVIOld->dwFileVersionLS > lpVINew->dwFileVersionLS )
                        {
                        dwRet |= CVI_FILEOLDER;
                        }

                    if( lpVIOld->dwFileVersionLS < lpVINew->dwFileVersionLS )
                        {
                        dwRet |= CVI_FILENEWER;
                        dwRet |= CVI_REPLACE;
                        }
                    }
                }
            }
        }

    _ffree( lpOldData );
    _ffree( lpNewData );
    return dwRet;
    }

//------------------------------------------------------------------
BOOL ItsOurDLL( LPSTR szFileName )
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
    lpOldData = (LPSTR)GetMem( (int)dwSizeOld + 2 );
            
            // fill said buffer.
    if( GetFileVersionInfo( szFileName, dwHOld, dwSizeOld, lpOldData ))
        {
            // get the translation code.
        if( VerQueryValue( lpOldData, szC_VQVTranslation, 
                           (void FAR * FAR *)&lpTrans, &dwSOld ))
            {
                // format into instruction to get company name.
            _fstrcpy( szFmt, szC_VQVSFInfo );
            _fstrcat( szFmt, szC_VQVCoName );
            wsprintf( szT1, szFmt, LOWORD(*lpTrans), HIWORD(*lpTrans));
            if( VerQueryValue( lpOldData, szT1, 
                               (void FAR * FAR *)&lpCo, &dwSOld ))
                {
                    // see if the string "qualitas" is found.
                if(( lpFound = _fstrstr( _fstrlwr( lpCo ), szC_Us )) != NULL )
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

    _ffree( lpOldData );
    return bRet;
    }

//------------------------------------------------------------------
BOOL IsA95DLL( LPSTR szOld )
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
    
    lpOldData = (LPSTR)GetMem( (int) dwSizeOld + 2 );

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
                if( 4 >= HIWORD( lpVIOld->dwProductVersionMS ))
                    {
                    bRet = TRUE;
                    }
                }
            }
        }
    _ffree( lpOldData );
    return bRet;
    }

//------------------------------------------------------------------
// Make version numbers match another dll.
//------------------------------------------------------------------
BOOL ChangeNEVersionNumbers( LPSTR szSrc, LPSTR szDst, LPSTR szImage )
    {
    HFILE hSrc = 0;
    HFILE hDst = 0;
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
    DWORD dwFileSize;
    char szFileID[ 80 ];
    char szProdID[ 80 ];

	char *lpBuf;
#ifdef _WIN16
    struct _find_t ft;
#else
    HANDLE fh;
    WIN32_FIND_DATA fd;
    FILETIME ftCreate, ftAccess, ftWrite;
#endif

        // get filesize.
#ifdef _WIN16
    if( _dos_findfirst( szSrc, _A_NORMAL, &ft ))
        {
        return FALSE;
        }
    dwFileSize = (DWORD)ft.size;
#else
    if(( fh = FindFirstFile( szSrc, &fd )) == INVALID_HANDLE_VALUE )
        {
        return FALSE;
        }
    FindClose( fh );
    dwFileSize = (DWORD)fd.nFileSizeLow + (DWORD)fd.nFileSizeHigh;
#endif

        // make a read buffer.
    nBuffSize = 32000;
    do
        {
        if (( lpBuf = (char *)_fmalloc( nBuffSize )) == NULL )
            {
            nBuffSize /= 2;
            if( nBuffSize <= 1000 )
                {
                return FALSE;
                }
            }
        } while(( lpBuf == NULL ) && ( nBuffSize > 1000 ));

    if(( lpVer = GetNEVersionResource( szSrc, &dwOffset, &dwLen )) != NULL )
        {
            // Get target version info.
        if( !GetNETargetInfo( szImage, &dwFileVerMS, &dwFileVerLS, 
                         &dwProdVerMS, &dwProdVerLS, 
                         szFileID, szProdID ))
            {
            bRet = FALSE;
            goto AllDone;
            }

            // Modify the version block.
        if( !ModifyNEVersionBlock( lpVer, dwFileVerMS, dwFileVerLS, 
                              dwProdVerMS, dwProdVerLS, 
                              szFileID, szProdID ))
            {
            bRet = FALSE;
            goto AllDone;
            }
        
            // copy the file up to the version block.
        if (( hSrc = _lopen( szSrc, READ | OF_SHARE_COMPAT )) == HFILE_ERROR) 
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
        dwToRead = dwFileSize - ( dwOffset + dwLen );
        _llseek( hSrc,  dwLen,  SEEK_CUR );

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
            _ffree( lpBuf );
            }

        if( lpVer != NULL )
            {
            _ffree( lpVer );
            }

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
            if ( !bRet )
                {
                _unlink( szDst );
                }
            }
        }
    else
        {
        _ffree( lpBuf );
        return FALSE;
        }
    return bRet;
    }

//------------------------------------------------------------------
// Get a version resource into memory.
//------------------------------------------------------------------
LPBYTE GetNEVersionResource( LPSTR szSrc, DWORD *pdwRetOff, DWORD *pdwTotLen )
    {           
    int err;
	HFILE hFile;
    LPBYTE lpRet = NULL;

    if( FindNEVersionOffset( szSrc, pdwRetOff, pdwTotLen ))
        {
            // Open the file for read-only access
        if(( hFile = _lopen( szSrc, OF_READ )) == HFILE_ERROR )
            {
                // exit, failing.
            return lpRet;
            }
        
        _llseek(hFile, *pdwRetOff, SEEK_SET);
        if(( lpRet = (LPBYTE)_fmalloc( (int)(*pdwTotLen) )) == NULL )
            {
            _lclose (hFile);
            return NULL;
            }

            // Read in the resource.
        if(( err = _lread( hFile, lpRet, (int)(*pdwTotLen) )) == HFILE_ERROR )
            {
            _ffree( lpRet );
            _lclose (hFile);
            return NULL;
            }
        _lclose (hFile);
        }
    return lpRet;
    }

//------------------------------------------------------------------
BOOL FindNEVersionOffset( LPSTR lpFile, DWORD *pdwRetOff, DWORD *pdwTotLen )
    {
	HFILE hFile;
	UINT err;
	WORD EXESign = 0; 
    WORD EXERelo = 0;
    WORD wRsrcShift = 0;
    DWORD dwWinHdrOff = 0L;
    NEHEADER hNE;
	RESOURCEHEADER RsrcHdr;
	RESOURCEENTRY RsrcEntry;

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
        goto ERRCLOSE;		// ...close and quit
        }

        // Seek to and read in the relocation offset
	_llseek(hFile, 0x18, SEEK_SET);
	if(( err = _lread( hFile, &EXERelo, sizeof( EXERelo ))) == HFILE_ERROR )
        {
		goto ERRCLOSE;		// ...close and quit
        }

         // If not valid EXE signature,
      	// or if not minimum relocation offset,
	if( EXESign != 'ZM' || EXERelo < 0x40 )
        {
		goto ERRCLOSE;		// ...close and quit
        }

        // Seek to and read in the offset to the NE header
	_llseek (hFile, 0x3C, SEEK_SET);
    if(( err = _lread( hFile, &dwWinHdrOff, sizeof( dwWinHdrOff ))) 
                                                   == HFILE_ERROR )
        {
		goto ERRCLOSE;		// ...close and quit
        }

        // If not valid offset ...
	if( dwWinHdrOff == 0 )
        {
		goto ERRCLOSE;		// ...close and quit
        }

        // clear the header buffer.
    memset( &hNE, 0, sizeof( NEHEADER ));

        // Seek to and read in the NE header
	_llseek( hFile, dwWinHdrOff, SEEK_SET );
	if(( err = _lread( hFile, &hNE, sizeof( NEHEADER ))) == HFILE_ERROR )
        {
		goto ERRCLOSE;		// ...close and quit
        }
        
        // If not a valid NE block...
	if( hNE.wSign != IMAGE_OS2_SIGNATURE)
        {
		goto ERRCLOSE;		// ...close and quit
        }

        // If this NE program uses an application-specific loader
        // we can't trust the rest of the format to be valid.
        // In particular, PK Lite executables are in this format.
    if( hNE.wFlags.b.familyApplication )
        {
        goto ERRCLOSE;
        }

        // If this NE-format file has no resources, then why bother?
    if( hNE.npRsrc == hNE.npResName )
        {
        goto ERRCLOSE;
        }

        // Seek to the resource table and read in the alignment shift
    _llseek (hFile, hNE.npRsrc + dwWinHdrOff, SEEK_SET );
    _lread (hFile, &wRsrcShift, sizeof (WORD));

        // Loop through the resource table looking for the version record.
    for( ;; )
        {
        memset( &RsrcHdr, 0, sizeof( RESOURCEHEADER ));

            // Read in the next resource header
        if(( err = _lread( hFile, &RsrcHdr, sizeof(RsrcHdr) )) == HFILE_ERROR )
            {
            goto ERRCLOSE;
            }

            // If it's the end,
        if( RsrcHdr.wType == 0 ) 
            {
                // we didn't find a version resource.
            goto ERRCLOSE;
            }

            // if it's the version resource...
        if( RsrcHdr.wType == ( 0x8000 | (WORD) RT_VERSION )) 
            {
                // 
            memset( &RsrcEntry, 0, sizeof( RESOURCEENTRY ));
            
                // read in the entry...
            if(( err = _lread( hFile, &RsrcEntry, sizeof(RsrcEntry) ))
                                                      == HFILE_ERROR )
                {
                goto ERRCLOSE;
                }

                // We'll close the file, calculate the offset
                // and return it.
            _lclose (hFile);
                // need to return wLen too.
            *pdwRetOff =  (DWORD)(RsrcEntry.wOffset) << wRsrcShift;
            *pdwTotLen = (DWORD)(RsrcEntry.wLen) << wRsrcShift;
                // HERE'S THE SUCCESS RETURN!
            return TRUE;
            } 

            // Not a version resource, skip over it
        while( RsrcHdr.wRsrcCnt-- )
            {
            _lread( hFile, &RsrcEntry, sizeof(RsrcEntry) );
            }
        } // End while

	// An error occurred (wrong format, bad read, etc.)
ERRCLOSE:
	_lclose (hFile);
	return FALSE;
    } // End FindNEVersionOffset( )

//------------------------------------------------------------------
BOOL GetNETargetInfo( LPSTR szImage,
                 DWORD *dwFileVerMS, DWORD *dwFileVerLS,  
                 DWORD *dwProdVerMS, DWORD *dwProdVerLS, 
                 LPSTR szFileID, LPSTR szProdID )
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


    dwSizeOld = GetFileVersionInfoSize( szImage, (DWORD FAR *) &dwHOld );
    if( !dwSizeOld )
        {
        return FALSE;
        }
    
    lpOldData = (LPSTR)_fmalloc( (int) dwSizeOld + 2 );

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
                    _fstrcpy( szFmt, szC_VQVSFInfo );
                    _fstrcat( szFmt, szC_VQVProdVer );
                    wsprintf( szT1, szFmt, LOWORD(*lpTrans), HIWORD(*lpTrans));

                    if( VerQueryValue( lpOldData, szT1, 
                                       (void FAR * FAR *)&lpProdVer, &uSOld ))
                        {
                        if( uSOld )
                            {
                            _fstrcpy( szProdID, lpProdVer );  
                            }
                        else
                            {
                            szProdID[0] = '\0';
                            }
                        }
                    
                        // format into instruction to get FileVersion.
                    _fstrcpy( szFmt, szC_VQVSFInfo );
                    _fstrcat( szFmt, szC_VQVFileVer );
                    wsprintf( szT1, szFmt, LOWORD(*lpTrans), 
                                           HIWORD(*lpTrans));
                    if( VerQueryValue( lpOldData, szT1, 
                                       (void FAR * FAR *)&lpFileVer, 
                                       &uSOld ))
                        {
                        if( uSOld )
                            {
                            _fstrcpy( szFileID, lpFileVer );  
                            }
                        else
                            {
                            szFileID[0] = '\0';
                            }
                        }
                        // we got it all.
                    bRet = TRUE;
                    }
                }
            }
        }

    _ffree( lpOldData );
    return bRet;
    }

//------------------------------------------------------------------
BOOL ModifyNEVersionBlock( LPBYTE lpVer, DWORD dwFileVerMS, DWORD dwFileVerLS, 
                           DWORD dwProdVerMS, DWORD dwProdVerLS, 
                           LPSTR szFileID, LPSTR szProdID )
    {
    int nLen;
    unsigned uSOld;
    LPBYTE lpbPtr;
    void FAR * FAR *lpTrans;
    LPSTR lpProdVer;
    LPSTR lpFileVer;
    char szT1[ _MAX_PATH + 2 ];
    char szFmt[ _MAX_PATH + 2 ];
    VS_FIXEDFILEINFO FAR *lpVptr;

    lpbPtr = lpVer + 4;
    nLen = lstrlen( (LPSTR) lpbPtr );
    lpbPtr += nLen;
    while( *lpbPtr == '\0' )
        {
        lpbPtr++;
        }
    lpVptr = (VS_FIXEDFILEINFO FAR *)lpbPtr;
    if( lpVptr->dwSignature == 0xFEEF04BD )
        {
        lpVptr->dwProductVersionMS = dwProdVerMS;
        lpVptr->dwProductVersionLS = dwProdVerLS;
        lpVptr->dwFileVersionMS = dwFileVerMS;
        lpVptr->dwFileVersionLS = dwFileVerLS;
        }

        // get the translation code.
    if( VerQueryValue( lpVer, szC_VQVTranslation, 
                       (void FAR * FAR *)&lpTrans, &uSOld ))
        {
            // format into instruction to get ProductVersion.
        _fstrcpy( szFmt, szC_VQVSFInfo );
        _fstrcat( szFmt, szC_VQVProdVer );
        wsprintf( szT1, szFmt, LOWORD(*lpTrans), HIWORD(*lpTrans));

        if( VerQueryValue( lpVer, szT1, 
                           (void FAR * FAR *)&lpProdVer, &uSOld ))
            {
            if( uSOld )
                {
                memset( lpProdVer, 0, uSOld );
                _fstrncpy( lpProdVer, szProdID, uSOld );
                }
            }
                    
            // format into instruction to get FileVersion.
        _fstrcpy( szFmt, szC_VQVSFInfo );
        _fstrcat( szFmt, szC_VQVFileVer );
        wsprintf( szT1, szFmt, LOWORD(*lpTrans), 
                               HIWORD(*lpTrans));
        if( VerQueryValue( lpVer, szT1, 
                           (void FAR * FAR *)&lpFileVer, 
                           &uSOld ))
            {
            if( uSOld )
                {
                memset( lpFileVer, 0, uSOld );
                _fstrncpy( lpFileVer, szFileID, uSOld );
                }
            }
            // we got it all.
        return TRUE;
        }
    return FALSE;
    }
