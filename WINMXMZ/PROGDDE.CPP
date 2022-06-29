// $Header:   P:/PVCS/MAX/WINMXMZ/PROGDDE.CPV   1.1   13 Oct 1995 11:56:34   HENRY  $
// PROGDDE.CPP - Routines to delete group from progman.
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved.

#include <windows.h>
#include <stdlib.h>
#include <ddeml.h>
#include <string.h>

#include "progdde.h"

#define DDETIMEOUT 1000

LPCSTR szPM = "PROGMAN";

#ifdef __cplusplus
extern "C" {
#endif

    // dummy dde callback.
HDDEDATA CALLBACK PMDDECallback( UINT wType, UINT wFmt, HCONV hConv, 
                                 HSZ hsz1, HSZ hsz2, HDDEDATA hDDEData, 
                                 DWORD dwData1, DWORD dwData2);

//------------------------------------------------------------------
// Delete ProgMan group
//------------------------------------------------------------------
BOOL CALLBACK 
DeletePMGroup( HINSTANCE hInst, LPSTR lpszGroup ) 
    {
    char buf[ _MAX_PATH ];

    if (lpszGroup && lstrlen(lpszGroup)) 
        {
        wsprintf(buf, "[DeleteGroup(%s)]", lpszGroup);
        }

    return SendPMExecCmd( hInst, (LPSTR) buf );
    }

//------------------------------------------------------------------
// Do nothing callback function for DDE.
//------------------------------------------------------------------
HDDEDATA CALLBACK 
PMDDECallback( UINT wType, UINT wFmt, HCONV hConv, HSZ hsz1, HSZ hsz2, 
               HDDEDATA hDDEData, DWORD dwData1, DWORD dwData2)
    {
    return NULL;
    }

//------------------------------------------------------------------
// Send an execute string to ProgMan
//------------------------------------------------------------------
BOOL 
SendPMExecCmd( HINSTANCE hInst, LPSTR lpszCmd )
    {
    FARPROC fpCallBack;
    DWORD dwDDEInst = 0;
    UINT uRet;
    HSZ hszProgman;
    HCONV hConv;
    HDDEDATA hExecData;

        // Initialize DDEML
    fpCallBack = MakeProcInstance( (FARPROC) PMDDECallback, hInst );
    if (( uRet = DdeInitialize(&dwDDEInst, PMDDECallback, 
                     CBF_FAIL_ALLSVRXACTIONS, 0l)) != DMLERR_NO_ERROR )
        {
        FreeProcInstance( fpCallBack );
        return FALSE;
        }

    hszProgman = DdeCreateStringHandle( dwDDEInst, szPM, CP_WINANSI );
    hConv = DdeConnect( dwDDEInst, hszProgman, hszProgman, NULL);
    DdeFreeStringHandle( dwDDEInst, hszProgman );

    if ( hConv == NULL ) 
        {
        FreeProcInstance( fpCallBack );
        return FALSE;
        }

    hExecData = DdeCreateDataHandle( dwDDEInst, lpszCmd, 
                                    lstrlen( lpszCmd )+1, 0, NULL, 0, 0);
    // Send the execute command
    DdeClientTransaction( (void FAR *)hExecData, (DWORD)-1, hConv,
                           NULL, 0, XTYP_EXECUTE, DDETIMEOUT, NULL);

    DdeDisconnect( hConv );
    DdeUninitialize( dwDDEInst );
    FreeProcInstance( fpCallBack );
    return TRUE;
    }

#ifdef __cplusplus
}
#endif // __cplusplus
