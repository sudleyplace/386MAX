// $Header:   P:/PVCS/MAX/STATUTIL/STRSTK.C_V   1.2   16 Apr 1996 14:25:26   HENRY  $
//------------------------------------------------------------------
// STRSTK.C
// created by Peter Johnson (PETERJ) 3/22/95
// (C) Copyright Qualitas, Inc. 1995
// All rights reserved
// for statutil.lib
//------------------------------------------------------------------

#include <windows.h> 
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <io.h>

#include <statutil.h>

#ifdef _WIN32
    #ifndef _INC_32ALIAS
        #include <32alias.h>
    #endif
#else
    #define WIN16
#endif

// Define a few values from senderrs.h:
#define QSE_OK			 0
#define QSE_OUTOFMEMORY 	-10
#define QSE_FUNCTIONFAILED	-99

#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------------------------------
// routine to store strings in a list for later recall.
// Pass in a pointer to a LPSTRSTACK (the anchor pointer), initially NULL, 
// and a string to add to the list. 
//------------------------------------------------------------------
int
StrStkPush( LPSTRSTACK FAR *lplpssA, LPSTR lpStr )
    {
    LPSTRSTACK lpssCur;
    
    if ( (*lplpssA) != NULL )
        {
            // get a local pointer to the list.
        lpssCur = ( *lplpssA );

            // find the end of the list.
        while ( lpssCur->lpssNext != NULL )
            {
            lpssCur = lpssCur->lpssNext;
            }
            
            // so now lpssCur->lpssNext = NULL
            // make a new link.
        if (( lpssCur->lpssNext = (LPSTRSTACK)_fmalloc( sizeof( STRSTACK ))) 
                                                                == NULL )
            {
            return QSE_OUTOFMEMORY;
            }
            
            // hook up the reverse link.
        ((LPSTRSTACK)lpssCur->lpssNext)->lpssPrev = lpssCur;
            
            // set our current pointer to the new record.
        lpssCur = lpssCur->lpssNext;

            // terminate the list.
        lpssCur->lpssNext = NULL;
        }
    else
        {
            // make the initial entry.
        if (( *lplpssA = (LPSTRSTACK)_fmalloc( sizeof( STRSTACK ) )) == NULL )
            {
            return QSE_OUTOFMEMORY;
            }

            // point to the beginning of list.
        lpssCur = ( *lplpssA );
        lpssCur->lpssPrev = NULL;
        lpssCur->lpssNext = NULL;
        }

        // either way, now we save the string.
    if (( lpssCur->lpStr = _fstrdup( lpStr )) != NULL )
        {
        return QSE_OK;
        }
    else
        {
        return QSE_OUTOFMEMORY;
        }
    }

//------------------------------------------------------------------
// routine to recall strings from a list.
// Pass in a pointer to a LPSTRSTACK (the anchor pointer), initially NULL, 
// and a string buffer and buffer length for the string return. 
//------------------------------------------------------------------
int
StrStkPop( LPSTRSTACK FAR *lplpssA, LPSTR lpStrBuff, int cBufLen )
    {
    LPSTRSTACK lpssCur;

        // if the anchor is empty, so is the list.
    if ( (*lplpssA) == NULL )
        {
        lpStrBuff[0] = '\0';
        return QSE_FUNCTIONFAILED;
        }

        // get a local pointer to the list.
    lpssCur = ( *lplpssA );
    
        // find the end of the list.
    while ( lpssCur->lpssNext != NULL )
        {
        lpssCur = lpssCur->lpssNext;
        }
        
        // lpssCur is now on the last element.
        // copy the string into the buffer.
    _fstrncpy( lpStrBuff, lpssCur->lpStr, cBufLen );
        
        // free the string memory.
    _ffree( lpssCur->lpStr );

        // reposition ourselves if we can.
    if ( lpssCur->lpssPrev != NULL )
        {
            // move our pointer to the previous record.
        lpssCur = lpssCur->lpssPrev;

            // free the one we were just on.
        _ffree( lpssCur->lpssNext ); 

            // mark it for the next time.
        lpssCur->lpssNext = NULL;

            // success.
        return QSE_OK;
        }
    else
        {
            // top of the list...evaporate.
        _ffree( *lplpssA );
        *lplpssA = NULL;
        return QSE_OK;
        }
    }

//------------------------------------------------------------------
#ifdef __cplusplus
}
#endif // __cplusplus
