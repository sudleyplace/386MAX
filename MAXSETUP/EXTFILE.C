// $Header:   P:/PVCS/MAX/MAXSETUP/EXTFILE.C_V   1.0   15 Dec 1995 11:02:54   PETERJ  $
// EXTFILE.C - Routines to extract data (files) from a resource.
// Stolen from Dispatch uninstall.
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.

#include <windows.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>

#include "extfile.h"

#ifdef __cplusplus
extern "C" {
#endif

BOOL CALLBACK 
ExtractFileFromRes( HINSTANCE hInst, LPCSTR szName, WORD wID ) 
    {
    int fhOut;
    HRSRC hData;
    HGLOBAL hDataInst;
    char FAR* lpBlock;
    WORD FAR* lpwLen;
    char FAR* lpData;

    if (( hData = 
        FindResource( hInst, MAKEINTRESOURCE( wID ), RT_RCDATA )) != NULL )
        {
        if (( hDataInst = LoadResource( hInst, hData )) != NULL )
            {
            if (( lpBlock = LockResource( hDataInst )) != NULL )
                {
                    // sort out the length and data.
                lpwLen = ( WORD FAR *) lpBlock;
                lpData = lpBlock + 2;
            
                    // construct a file.
                fhOut = _open( szName, _O_CREAT | _O_BINARY | _O_RDWR 
                                        | _O_TRUNC, _S_IWRITE | _S_IREAD );
                if (fhOut < 0) 
                    {
                        // Couldn't create output file
                    return FALSE;
                    } 
                        
                    // write the data
                _write( fhOut, lpData, *lpwLen );
                 _close( fhOut );

                UnlockResource( hDataInst );
                }
            else
                {
                FreeResource( hDataInst );
                return FALSE;
                }

            FreeResource( hDataInst );
            }
        else
            {
            return FALSE;
            }
        }
    else
        {
        return FALSE;
        }

    return TRUE;
    }


#ifdef __cplusplus
}
#endif // __cplusplus
