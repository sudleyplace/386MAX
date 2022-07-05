// $Header:   P:/PVCS/MAX/SETUP32/SETUP16.C_V   1.1   25 Sep 1996 09:19:02   PETERJ  $
//------------------------------------------------------------------
// setup16.c
// 16 bit dll to thunk to 32 bit setup32.dll
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
//------------------------------------------------------------------
#include <windows.h>
typedef unsigned long HKEY;

//------------------------------------------------------------------
// prototypes
//------------------------------------------------------------------
BOOL WINAPI __export thk_ThunkConnect16 (LPSTR, LPSTR, WORD, DWORD);

BOOL WINAPI ChangePEVersionNumbers32( LPSTR szSrc, LPSTR szDst, LPSTR szImage );

BOOL WINAPI AddReg32( HKEY hkRootKey, LPSTR szKey, LPSTR szValName,
                      LPBYTE szVal, DWORD dwType, DWORD dwLen );

DWORD WINAPI CompareVersionInfo32( LPSTR szOld, LPSTR szNew );
BOOL WINAPI DelKey32( HKEY hkRootKey, LPSTR szParentKey, LPSTR szDelKey );
BOOL WINAPI DoesValueExist32( HKEY hkRootKey, LPSTR szKey, LPSTR szValName );
BOOL WINAPI Is95Ver32( LPSTR szOld );
BOOL WINAPI ItsOurDLL32( LPSTR szFileName );
BOOL WINAPI RenameValue32( HKEY hkRootKey, LPSTR szKey, 
                           LPSTR szOldValName, LPSTR szNewValName );


//------------------------------------------------------------------
// dll entry function. Required to initiate thunk connection.
//------------------------------------------------------------------

BOOL WINAPI __export 
DllEntryPoint (DWORD dwReason, WORD  hInst, WORD  wDS,
               WORD  wHeapSize, DWORD dwReserved1, WORD  wReserved2)
    {
	if( !thk_ThunkConnect16 ( "setup16.dll","setup32.dll",
                               hInst, dwReason))
        {
        return FALSE;
        }
    return TRUE;
    }

//------------------------------------------------------------------
BOOL WINAPI __export ChangePEVersionNumbers( LPSTR szSrc, LPSTR szDst, LPSTR szImage )
    {
    return ChangePEVersionNumbers32( szSrc, szDst, szImage );
    }

//------------------------------------------------------------------
BOOL WINAPI __export Is95Ver( LPSTR szOld )
    {
    return Is95Ver32( szOld );
    }

//------------------------------------------------------------------
DWORD WINAPI __export CompareVersionInfo( LPSTR szOld, LPSTR szNew )
    {
    return CompareVersionInfo32( szOld, szNew ); 
    }

//------------------------------------------------------------------
BOOL WINAPI __export ItsOurDLL( LPSTR szFileName )
    {
    return ItsOurDLL32( szFileName );
    }

//------------------------------------------------------------------
BOOL WINAPI __export DelKey( HKEY hkRootKey, LPSTR szParentKey, LPSTR szDelKey )
    {
    return DelKey32( hkRootKey, szParentKey, szDelKey );
    }

//------------------------------------------------------------------
BOOL WINAPI __export RenameValue( HKEY hkRootKey, LPSTR szKey, 
                             LPSTR szOldValName, LPSTR szNewValName )
    {
    return RenameValue32( hkRootKey, szKey, szOldValName, szNewValName );
    }

//------------------------------------------------------------------
BOOL WINAPI __export AddReg( HKEY hkRootKey, LPSTR szKey, LPSTR szValName,
                             LPBYTE szVal, DWORD dwType, DWORD dwLen )
    {
    return AddReg32( hkRootKey, szKey, szValName, szVal, dwType, dwLen );
    }

//------------------------------------------------------------------
BOOL WINAPI __export DoesValueExist( HKEY hkRootKey, LPSTR szKey, 
                                     LPSTR szValName )
    {
    return DoesValueExist32( hkRootKey, szKey, szValName );
    }
