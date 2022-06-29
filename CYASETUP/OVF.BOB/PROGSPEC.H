// $Header:   P:/PVCS/MAX/CYASETUP/PROGSPEC.H_V   1.14	 05 May 1997 11:07:56	PETERJ	$
//------------------------------------------------------------------
// progspec.h
// Version 1.0
// 6 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
// Header for module containing program specific functions that
// should be present or dummied for each program..
//------------------------------------------------------------------

#ifdef EXTERN
	#undef EXTERN
#endif

#ifdef DEFVAL
	#undef DEFVAL
#endif

#ifdef PROGSPEC_DEFVARS
	#define EXTERN
	#define DEFVAL(v) =v
#else
	#define EXTERN extern
	#define DEFVAL(v)
#endif

#ifdef _WIN32
	// WIN32
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

#ifndef PROGSPEC_INCLUDED
#define PROGSPEC_INCLUDED

#define USERNAMELEN 35
#define USERORGLEN	35
#define SERNUMLEN	20

// exported WinProcs.
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 AddDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ConfirmUIDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 DirDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ExtractDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 FilesetDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 OldUIDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 PGroupDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ScheduleDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 TrayAskDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 UninstallDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 UserInfoDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 WelcomeDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);

// local functions.
extern void AutoConfig();
extern BOOL CheckUser();
extern int Decide2( int nRVal, int nOK, int nCancel );
extern void Do_Uninstall();
extern int DrawMeter(HWND hWnd, int nPercent);
extern BOOL InstallIcon();
extern BOOL MoveLocalToShared();
extern void ProcessFileList( HWND hMeter );
extern void TraynoteConfig();
extern BOOL ValidSernum( LPSTR szSerial );

//------------------------------------------------------------------
	// length for Instance Name.
#define INSTLEN  8

	// length for group name.
#define DEFGROUPLEN  128

//------------------------------------------------------------------
// program specific variables.
//------------------------------------------------------------------

	// default installation directory.
EXTERN LPSTR szDefDir DEFVAL( "QCYA");

//------------------------------------------------------------------
// Control strings, DO NOT Translate.
//------------------------------------------------------------------
EXTERN LPSTR szC8_ProgName16  DEFVAL( "CYA16" );
EXTERN LPSTR szC8_ProgName32  DEFVAL( "CYA32" );

EXTERN LPSTR szC_Prefix 	 DEFVAL( "CYA" );

EXTERN LPSTR szC_IniName	 DEFVAL( "QCYA.ini" );
EXTERN LPSTR szC_InstIni	 DEFVAL( "QCYAINST.ini" );
EXTERN LPSTR szC_RegIni 	 DEFVAL( "QCYAREG.ini" );

EXTERN LPSTR szC_IniReg 	 DEFVAL( "Registration" );
EXTERN LPSTR szC_IniInst	 DEFVAL( "Instance" );
EXTERN LPSTR szC_IniETBar	 DEFVAL( "TaskBar" );
EXTERN LPSTR szC_IniUser	 DEFVAL( "User" );
EXTERN LPSTR szC_IniUOrg	 DEFVAL( "Organization" );
EXTERN LPSTR szC_IniUSN 	 DEFVAL( "SerNum" );
EXTERN LPSTR szC_IniSched	 DEFVAL( "Schedule" );
EXTERN LPSTR szC_IniStart	 DEFVAL( "Startup" );
EXTERN LPSTR szC_IniDays	 DEFVAL( "Days" );
EXTERN LPSTR szC_IniTMark	 DEFVAL( "Timemark" );
EXTERN LPSTR szC_IniPGroup	 DEFVAL( "ProgGroup" );
EXTERN LPSTR szC_RealIniUndo DEFVAL( "DoUndo" );
EXTERN LPSTR szC_IniUserSID  DEFVAL( "UserSID" );

EXTERN LPSTR szC_Undo		 DEFVAL( "undo" );
EXTERN LPSTR szC_UndoDir	 DEFVAL( "cyaundo" );
EXTERN LPSTR szC_DataDir	 DEFVAL( "cyadata" );

	// special files to be installed.
EXTERN LPSTR szC_ZipDLL 	DEFVAL( "dzip.dll" );
EXTERN LPSTR szC_Zip32DLL	DEFVAL( "dzip32.dll" );

EXTERN LPSTR szC_TL16DLL	 DEFVAL( "tl16v20.dll" );
EXTERN LPSTR szC_TL32DLL	 DEFVAL( "tl32v20.dll" );

EXTERN LPSTR szC_Evap		DEFVAL( "Evap.exe" );
EXTERN LPSTR szC_Epif		DEFVAL( "Evap.pif" );
EXTERN LPSTR szC_Setup		DEFVAL( "setup.exe" );
EXTERN LPSTR szC_Setup32	DEFVAL( "setup32.exe" );
EXTERN LPSTR szC_AutoexecNT DEFVAL( "autoexec.nt" );
EXTERN LPSTR szC_ConfigNT	DEFVAL( "config.nt" );
EXTERN LPSTR szC_Sys32		DEFVAL( "system32" );

EXTERN LPSTR szC_Traynote	 DEFVAL( "TRAYNOTE" );
EXTERN LPSTR szC_TrayExe	 DEFVAL( "TRAYNOTE.EXE" );
EXTERN LPSTR szC_TrayIni	 DEFVAL( "TRAYNOTE.INI" );
EXTERN LPSTR szC_Space		 DEFVAL( " " );
EXTERN LPSTR szC_Start		 DEFVAL( "START" );
EXTERN LPSTR szC_Close		 DEFVAL( "CLOSE" );
EXTERN LPSTR szC_New		 DEFVAL( "NEW" );
EXTERN LPSTR szC_Quit		 DEFVAL( "QUIT" );

EXTERN LPSTR szC_ExtDLL 	  DEFVAL( ".DLL" );
EXTERN LPSTR szC_ExtEXE 	  DEFVAL( ".EXE" );
EXTERN LPSTR szC_ExtBAT 	  DEFVAL( ".BAT" );

EXTERN LPSTR szC_TISecCYA	 DEFVAL( "CYA" );
EXTERN LPSTR szC_TISecGen	 DEFVAL( "General" );
EXTERN LPSTR szC_TITTip 	 DEFVAL( "ToolTip" );
EXTERN LPSTR szC_TIIconFile  DEFVAL( "IconFile" );
EXTERN LPSTR szC_TILeft 	 DEFVAL( "LeftClick" );
EXTERN LPSTR szC_TIRight	 DEFVAL( "RightClick" );
EXTERN LPSTR szC_TIApp		 DEFVAL( "App" );
EXTERN LPSTR szC_TIClass	 DEFVAL( "Class" );
EXTERN LPSTR szC_TIDefClass  DEFVAL( "TrayNoteClass" );

EXTERN LPSTR szC_TTStr		 DEFVAL( "Qualitas C.Y.A." );

	// 32 bit registry reg file heading
EXTERN LPSTR szC_RegTag32 DEFVAL( "REGEDIT4" );

	// cya dialog class for running check.
EXTERN LPSTR szSSDlgClass	DEFVAL( "SSDialogClass");

	// FileSelect filter
EXTERN char  cFFSep DEFVAL( '$' );
EXTERN LPSTR szCA_FileFilter DEFVAL( "*.bat;*.sys;*.ini;*.pro$*.bat;*.sys;*.ini;*.pro$All Files (*.*)$*.*$" );

//------------------------------------------------------------------
// text
//------------------------------------------------------------------

#include "csettext.us"

//------------------------------------------------------------------
// flags.
//------------------------------------------------------------------

	// we are in uninstall mode.
EXTERN BOOL bUninstall DEFVAL( FALSE );

	// were we successful?.
EXTERN BOOL bComplete DEFVAL( FALSE );

	// don't extract files.
EXTERN BOOL bNoExtract DEFVAL( FALSE );

	// This is a reinstall run.
EXTERN BOOL bReinstall DEFVAL( FALSE );

	// Traynote was active.
EXTERN BOOL bTrayWasOn DEFVAL( FALSE );

	// Shall we run after install?.
EXTERN BOOL bRunCYAOnExit DEFVAL( FALSE );

	// are we installing traynote.
EXTERN BOOL bTraynote DEFVAL( FALSE );

	// add CYA to startup group with auto
EXTERN BOOL bAddAuto DEFVAL( FALSE );

	// only remove the instance data.
EXTERN BOOL bUIInstOnly   DEFVAL( FALSE );
EXTERN BOOL bUIProg   DEFVAL( TRUE );
EXTERN BOOL bUIData   DEFVAL( TRUE );
EXTERN BOOL bUIUndo   DEFVAL( TRUE );
EXTERN BOOL bUITray   DEFVAL( TRUE );

	// should we use evap to erase ourselves?
EXTERN BOOL bExitEvap DEFVAL( FALSE );
	// should we delete ourselves in Win95?
EXTERN BOOL bEvap95   DEFVAL( FALSE );

//------------------------------------------------------------------
// Global variables.
//------------------------------------------------------------------

	// Instance name.
EXTERN char szInst[ INSTLEN + 1 ] DEFVAL( "" );

	// Instance name.
EXTERN char szIniOpt[ INSTLEN + sizeof(szC_IniOpt) + 4 ] DEFVAL( "" );

	// Instance name.
EXTERN char szIniDir[ INSTLEN + sizeof(szC_IniDir) + 4 ] DEFVAL( "" );

	// registration info.
EXTERN char szUserName[ USERNAMELEN + 2 ] DEFVAL( "" );
EXTERN char szUserOrg [ USERORGLEN + 2 ] DEFVAL( "" );
EXTERN char szSerialNumber[ SERNUMLEN + 2 ] DEFVAL( "" );

	// Disk size info
EXTERN DWORD dwDiskSpaceReq DEFVAL( 1000000 );
EXTERN DWORD dwWinSpaceReq DEFVAL( 200000 );

//------------------------------------------------------------------
// Anchors.
//------------------------------------------------------------------
EXTERN LPSTR lpFileList DEFVAL( NULL );

EXTERN LPSTR lpProgGroup DEFVAL( NULL );

//------------------------------------------------------------------
	// PROGSPEC_INCLUDED
#endif 

