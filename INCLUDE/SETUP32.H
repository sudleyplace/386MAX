// $Header:   P:/PVCS/MAX/INCLUDE/SETUP32.H_V   1.0   25 Sep 1996 13:53:00   PETERJ  $
//------------------------------------------------------------------
// setup32.h
// Version 1.0
// 20 August, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
//------------------------------------------------------------------

#ifdef EXTERN
    #undef EXTERN
#endif

#ifdef DEFVAL
    #undef DEFVAL
#endif

#ifdef SETUP32_DEFVARS
    #define EXTERN
    #define DEFVAL(v) =v
#else
    #define EXTERN extern
    #define DEFVAL(v)
#endif

#ifdef _WIN32
	// WIN32
//	#define EXPORT __declspec(dllexport)
	#define EXPORT
	#define EXPORT16
	#define EXPORT32 EXPORT
	#define LOADDS
#else
    // Win16
	#define EXPORT __export
	#define EXPORT16 EXPORT
	#define EXPORT32
	#define LOADDS __loadds
#endif	

#ifndef SETUP32_INCLUDED
//------------------------------------------------------------------
#define SETUP32_INCLUDED

    // CompareVersionInfo return values.
    // Relative to new file.
#define CVI32_FAILED              0x0000
#define CVI32_SUCCESS             0x0001
#define CVI32_PRODOLDER           0x0010
#define CVI32_PRODNEWER           0x0020
#define CVI32_FILEOLDER           0x0040
#define CVI32_FILENEWER           0x0080
#define CVI32_REPLACE             0x1000

#ifdef __cplusplus
extern "C" {
#endif

EXPORT32 BOOL WINAPI AddReg32( HKEY hkRootKey, LPSTR szKey, LPSTR szValName,
                        LPBYTE szVal, DWORD dwType, DWORD dwLen );

EXPORT32 DWORD WINAPI CompareVersionInfo32( LPSTR szOld, LPSTR szNew );

EXPORT32 BOOL WINAPI Is95Ver32( LPSTR szOld );

EXPORT32 BOOL WINAPI DelKey32( HKEY hkRootKey, LPSTR szParentKey, LPSTR szDelKey );

EXPORT32 BOOL WINAPI ItsOurDLL32( LPSTR szFileName );

EXPORT32 BOOL WINAPI RenameValue32( HKEY hkRootKey, LPSTR szKey, 
                             LPSTR szOldValName, LPSTR szNewValName );

EXPORT32 BOOL WINAPI DoesValueExist32( HKEY hkRootKey, LPSTR szKey, 
                                       LPSTR szValName );

EXPORT32 BOOL WINAPI ChangePEVersionNumbers32( LPSTR szSrc, 
                                       LPSTR szDst, LPSTR szImage );

#ifdef __cplusplus
}
#endif

//------------------------------------------------------------------
// end of file SETUP32_INCLUDED endif
#endif
