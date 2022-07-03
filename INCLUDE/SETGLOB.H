// $Header:   P:/PVCS/MAX/INCLUDE/SETGLOB.H_V   1.15   15 Jun 1998 16:10:06   BOB  $
//------------------------------------------------------------------
// SETGLOB.H
// Global variable definitions for Qualitas Setup library.
// Version 1.0
// 7 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
//------------------------------------------------------------------

#ifdef EXTERN
	#undef EXTERN
#endif

#ifdef DEFVAL
	#undef DEFVAL
#endif

	// make our own simpler version.
#ifdef _WIN16
	#undef _WIN16
#endif

#ifdef SETUP_DEFVARS
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

#ifndef SETGLOB_INCLUDED
#define SETGLOB_INCLUDED
//------------------------------------------------------------------

#ifndef _TIME_T_DEFINED
#include <time.h>
#endif

#ifndef _INC_SHELLAPI
#include <shellapi.h>
#endif


#if !defined(_WIN32) && !defined(__WIN32__)
	#define _WIN16
#endif

#ifdef _WIN32
	#ifndef _INC_SETJMP
	#include <setjmp.h>
	#endif
	#ifndef VER_H
	#include <winver.h>
	#endif
#else
	#ifndef _INC_VER
	#include <ver.h>
	#endif
#endif

#include "cversion.h"
#include <setvers.h>
#include <set_ids.h>

//------------------------------------------------------------------
// defines
//------------------------------------------------------------------

#ifdef _WIN32
	#ifndef _INC_32ALIAS
	#include <32alias.h>
	#endif
#else
	// Win16
	// use the Windows Throw and Catch instead of longjmp/setjmp
	#define longjmp 	Throw
	#define setjmp		Catch
	#define jmp_buf 	CATCHBUF
#endif

	// NT auxillary flag for GetWinFlags.
#define WF_WINNT 0x4000

	// registry key name len.
#define _MAX_KEY  260

	// Getline Read line length.
#define LINEBUFLEN (( _MAX_PATH * 2 ) + 20 )

	// length for global error exit messages.
#define ERRMSGLEN  ( _MAX_PATH + 128 )

	// title buffer len
#define TITLELEN   81

	// default splash display time.
#define SPLASHTIME 2

	// verchkcopyfile flags.
#define VCCF_DELETESRC		0x0001
#define VCCF_SHARED_RES 	0x0002
#define VCCF_FORCE_COPY 	0x0004
#define VCCF_FORCE_DEST 	0x0008

	// verchkcopyfile errors.
#define VCC_SUCCESS 	0x0000
#define VCC_FOUNDINWRONGPLACE	0x0001
#define VCC_FILEINUSE		0x0002
#define VCC_DIFFERENTTYPES	0x0004
#define VCC_BADSRC		0x0008
#define VCC_BADDEST 	0x0016
#define VCC_BUFFTOOSMALL	0x0032
#define VCC_OUTOFMEMORY 	0x0064

	// CompareVersionInfo return values.
	// Relative to new file.
#define CVI_FAILED		0x0000
#define CVI_SUCCESS 	0x0001
#define CVI_PRODOLDER		0x0010
#define CVI_PRODNEWER		0x0020
#define CVI_FILEOLDER		0x0040
#define CVI_FILENEWER		0x0080
#define CVI_REPLACE 	0x1000

	// definition left out of windows.h
#define RT_VERSION MAKEINTRESOURCE(16)

	// Add to copy batch flags
#define ACB_DELETE		0x0001
#define ACB_VMM 		0x0002

//------------------------------------------------------------------
// List for strings.
//------------------------------------------------------------------
typedef struct _tagSTRINGLIST
	{
	struct _tagSTRINGLIST FAR *next;
	LPSTR lpString;
	} STRINGLIST, FAR *LPSTRINGLIST;

//------------------------------------------------------------------
// List for Files.
//------------------------------------------------------------------
typedef struct _tagFILELIST
	{
	struct _tagFILELIST FAR *prev;
	struct _tagFILELIST FAR *next;
	LPSTR lpFilename;
	UINT uSeq;
	UINT uOpt;
	} FILELIST, FAR *LPFILELIST;

//------------------------------------------------------------------
// List for Disks.
//------------------------------------------------------------------
typedef struct _tagDISKLIST
	{
	struct _tagDISKLIST FAR *prev;
	struct _tagDISKLIST FAR *next;
	struct _tagFILELIST FAR *file;
	int   nDiskNum;
	LPSTR lpArchive;
	} DISKLIST, FAR *LPDISKLIST;

//------------------------------------------------------------------
// prototypes
//------------------------------------------------------------------
//------------------------------------------------------------------
// program specific prototypes
// Each instance of a setup program must provide these process functions,
// which provide sequencing and program specific actions.
//------------------------------------------------------------------
	// Command line processing.
extern "C" void ProcessCmdLine( LPSTR lpCmd );
	// program specific initialization.
extern void ProcessInitialize();
	// Decide what the first message should be.
extern "C" void ProcessStartMessage( );
	// Memory cleanup processing.
extern "C" void ProcessCleanup();
	// special "just before exit" processing (exec, etc.) .
extern "C" void ProcessExitSpecials( );
	// this is the "main program loop process"
extern "C" LPARAM ProcessMainCmds( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );

//------------------------------------------------------------------
// Setup function prototypes.
//------------------------------------------------------------------
//------------------------------------------------------------------
// Window procs.
//------------------------------------------------------------------
extern "C" EXPORT32 BOOL EXPORT16 CALLBACK AboutDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL CALLBACK EXPORT16 ExtractDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 LRESULT EXPORT16 CALLBACK MainWndProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 BOOL EXPORT16 CALLBACK ModelessDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 LRESULT CALLBACK EXPORT16 SplashWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
extern "C" EXPORT32 DWORD EXPORT16 CALLBACK F1FilterProc( int nCode, WPARAM wParam, LPARAM lParam);

//------------------------------------------------------------------
// DDE functions
//------------------------------------------------------------------
extern int AddItemIconToGroup( LPSTR szCmdLine, LPSTR szTitle, LPSTR szIcon,
				   int nIconIndex, LPSTR szGroupName, BOOL bClose );
extern int AddItemToGroup( LPSTR szCmdLine, LPSTR szTitle,
			   LPSTR szGroupName, BOOL bClose );
extern BOOL pmAddItem(LPSTR lpszCmdLine, LPSTR lpszCaption, LPSTR lpszIcon, int fMinimize);
extern BOOL pmAddItemIcon(LPSTR lpszCmdLine, LPSTR lpszCaption, LPSTR lpszIcon,
				int nIconIndex, int fMinimize);
extern BOOL pmCreateGroup(LPSTR lpszGroup, LPSTR lpszPath);
extern BOOL pmDeleteGroup(LPSTR lpszGroup);
extern BOOL pmDeleteItem(LPSTR lpszItem);
extern void DeleteItemFromGroup( LPSTR szTitle, LPSTR szGroupName, BOOL bClose );
extern LPSTR GetGroups( );
extern int GetGroupItemList( LPSTR szGroup, LPSTR FAR *szBuff );
extern BOOL pmQueryGroup( LPSTR lpszGroup, LPSTR lpszItem );
extern BOOL pmReplaceItem(LPSTR lpszItem);
extern BOOL pmShowGroup(LPSTR lpszGroup, WORD wCmd);
extern unsigned int InitDDE(void);
extern void EndDDE(void);

//------------------------------------------------------------------
// utility functions
//------------------------------------------------------------------
extern void AddToWininit( LPSTR pszLine );
extern int AddUninstall( LPSTR lpProdName, LPSTR lpProdKey, LPSTR lpUString );
extern void CenterWindow(HWND hWnd);
extern void ChangeDisplay( LPCSTR szText );
extern void ChangeDisplay2( LPCSTR szText );
extern BOOL ChangeNEVersionNumbers( LPSTR szSrc, LPSTR szDst, LPSTR szImage );
extern void Cleanup( void );
extern DWORD CompareVersionInfo( LPSTR szOld, LPSTR szNew );
extern void CopySetup();
extern void CrackIt( WPARAM wParam, LPARAM lParam, WORD *id, WORD *cmd,
							HWND *hChild );
extern void CrashExit( );

extern BOOL DoesSectionExist( LPSTR lpFile, LPSTR szSection );
extern void ModifyProfileString( LPSTR szSec, LPSTR szLine, LPSTR szElement,
				 LPSTR szFile, BOOL bDelete );
extern void DeleteGroup( LPSTR szGroupName );
extern void EndDisplay( void );
extern void EnumZip( LPSTRINGLIST FAR *lpS, LPSTR lpFile );
extern BOOL FindLastSerialPath( LPSTR szFileBuff );
extern void _fastcall FreeGlobalMem( char *fptr );
extern void FreeThunkLib();
extern void GetEnvInfo( HINSTANCE hInstance );
extern void FAR *GetMem( size_t s );
extern BOOL IsA95DLL( LPSTR szOld );
extern BOOL ItsOurDLL( LPSTR szFileName );
extern void KillDiskList( LPDISKLIST FAR *);
extern void LoadThunkLib();
extern void MakeFileExt( LPSTR szDir, LPSTR szName, LPSTR szExt, LPSTR szTarget );
extern void MakePath(char *pszDir, char *pszFileName, char *pszTarget);
extern void MakeSerialPath( LPSTR szDir, LPSTR szName, LPSTR szNewBuff );
extern void PrepZipPath( LPCSTR lpPathIn, LPCSTR lpBuffer );
extern void ProcessDiskList( LPDISKLIST FAR *lpDL, HWND hMeter );
extern void ReadQPFile( LPSTR szFilename );
extern void FAR *ReAllocMem( void FAR *lpMem, size_t s );
extern void RemoveFiles( LPSTR szTemplate );
extern int RemoveUninstall( LPSTR lpProdKey  );
extern void SetErrMsg( LPSTR szMsg );
extern void ShowMainWindow();
extern void ShowSplashWindow( HWND hSplash );
extern int SNPackStr( LPSTR lpOut, LPSTR lpIn );
extern void StartDisplay( LPSTR szText, LPSTR szTitle );
extern void StopSplashWindow( HWND hSplash );
extern void strip_leading( LPSTR arg, LPSTR delims );
extern void strip_trailing( LPSTR arg, LPSTR delims);
extern void strip_bracket( LPSTR lpBuff );
extern void SYield( int bWait );
extern void UpdateMainScreen( HWND hMWin );
extern void UpdateSplashScreen( HWND hMWin );

extern void WritePrivateProfileInt( LPSTR szSect, LPSTR szItem, int nVal,
								LPSTR szFile );
extern void WritePrivateProfileLong( LPSTR szSect, LPSTR szItem, long lVal,
								LPSTR szFile );
extern char bootdrive( LPSTR lpDrive );
extern int CopyUnzipDll();
extern int DrawMeter(HWND hWnd, int nPercent);
extern int FileCopy( LPSTR szTarget, LPSTR szSource );
extern int GetLine( HFILE fh, LPSTR line, int nMaxSize );
extern int QueryFileExists( LPSTR pszFileName);
extern int QueryFileInZip( LPSTR pszFileName, LPSTR pszZipName);

extern int VerChkCopyFiles( LPSTR lpSrcFile, LPSTR lpSrcDir,
			 LPSTR lpDestFile, LPSTR lpDestDir, LPSTR lpWinDir,
			 LPSTR lpCurDirBuff,  UINT FAR *lpuCurLen,
			 LPSTR lpDestDirBuff, UINT FAR *lpuDestLen,
			 UINT uFlags );

#ifdef _WIN32
extern UINT sswrite( HFILE fh, LPCSTR hp, UINT uLen );
#else
extern UINT sswrite( HFILE fh, const void huge *hp, UINT uLen );
#endif

#ifdef _WIN32
extern DWORD MyGetShortPathName( LPSTR szSrc, LPSTR szDst, DWORD dwLen );
#endif

extern HFILE OpenOrCreate( LPSTR lpFile, int nMode );

extern BOOL AddToCopyBatch( LPSTR szSaved, LPSTR szDest,
				LPSTR szCopyFile, UINT uFlags );
extern BOOL DosCopyPrep( LPSTR szDest, LPSTR lpCopyPath, LPSTR lpCopyProg,
							LPSTR lpBatchFile );
extern BOOL ExecCleanBat( LPSTR szDest, LPSTR szCopyProg, LPSTR szCopyDir,
				  LPSTR szBatFileName, LPSTR szWindowsDir );
extern BOOL CALLBACK ExtractFileFromRes( HINSTANCE hInst, LPCSTR szName,
								 WORD wID );
extern BOOL InitApplication(HINSTANCE hInstance);
extern BOOL InitInst(HINSTANCE hInstance, int nCmdShow, LPSTR lpCmdLine );
extern BOOL InitSplash( HINSTANCE hInstance );
extern BOOL LoadCTL3D();
extern BOOL LoadCtl3dLibrary( LPSTR lpLibName );
extern BOOL QueryDirExists( LPSTR szDirname );
extern BOOL WalkWindowList( void );
extern BOOL WPPI_IfEmpty( LPSTR szSect, LPSTR szItem, int nVal, LPSTR szFile );
extern BOOL WPPS_IfEmpty( LPSTR szSect, LPSTR szItem, LPSTR szVal,
							LPSTR szFile );

extern DWORD FreeDiskSpace( char cDrive );
extern long GetPrivateProfileLong( LPSTR szSect, LPSTR szItem, long lDefault,
								LPSTR szFile );
extern LPSTR AllocGlobalMem(unsigned int *uSize);
extern LPSTR FindFile( int fflag, LPSTR arg, struct _find_t *dir,
						LPSTR filename );
extern LPSTR fname_part( LPSTR pszFileName);
extern LPSTR path_part( LPSTR s );
extern LPSTR StrMem( LPSTR str);

//------------------------------------------------------------------
// CTL3DV2 function pointers for dynamic loading.
//------------------------------------------------------------------
typedef BOOL (FAR PASCAL *LPFN3DREGISTER)
	( HANDLE hInstance );
EXTERN LPFN3DREGISTER lpfn3DRegister;
#define C3DRegister (*lpfn3DRegister)

typedef BOOL (FAR PASCAL *LPFN3DUNREGISTER)
	( HANDLE hInstance );
EXTERN LPFN3DUNREGISTER lpfn3DUnregister;
#define C3DUnregister (*lpfn3DUnregister)

typedef BOOL (FAR PASCAL *LPFN3DSUBCLASSDLG)
	( HWND hWnd, WORD parm );
EXTERN LPFN3DSUBCLASSDLG lpfn3DSubclassDlg;
#define C3DSubClassDlg (*lpfn3DSubclassDlg)

typedef BOOL (FAR PASCAL *LPFN3DSUBCLASSDLGEX)
	( HWND hWnd, DWORD parm );
EXTERN LPFN3DSUBCLASSDLGEX lpfn3DSubclassDlgEx;
#define C3DSubclassDlgEx (*lpfn3DSubclassDlgEx)

typedef BOOL (FAR PASCAL *LPFN3DAUTOSUBCLASS)
	( HANDLE hInstance );
EXTERN LPFN3DAUTOSUBCLASS lpfn3DAutoSubclass;
#define C3DAutoSubclass (*lpfn3DAutoSubclass)

typedef HBRUSH (FAR PASCAL *LPFN3DCTLCOLOREX)
	(UINT wm, WPARAM wParam, LPARAM lParam);
EXTERN LPFN3DCTLCOLOREX lpfn3DCtlColorEx;
#define C3DCtlColorEx (*lpfn3DCtlColorEx)

//-----------------------------------------------------------------
// Thunk Funcs.
//-----------------------------------------------------------------
typedef BOOL (FAR PASCAL *LPFNCHANGEPEVERSIONNUMBERS )
	( LPSTR szSrc, LPSTR szDst, LPSTR szImage );
EXTERN LPFNCHANGEPEVERSIONNUMBERS lpfnChangePEVersionNumbers;
#define lptChangePEVersionNumbers (*lpfnChangePEVersionNumbers)

typedef BOOL (FAR PASCAL *LPFNITSOURDLL )
	( LPSTR szFileName );
EXTERN LPFNITSOURDLL lpfnItsOurDLL;
#define lptItsOurDLL (*lpfnItsOurDLL)

typedef BOOL (FAR PASCAL *LPFNADDREG )
	( HKEY hkRootKey, LPSTR szKey, LPSTR szValName,
	  LPBYTE szVal, DWORD dwType, DWORD dwLen );
EXTERN LPFNADDREG lpfnAddReg;
#define lptAddReg (*lpfnAddReg)

typedef BOOL (FAR PASCAL *LPFNIS95VER )
	( LPSTR szOld );
EXTERN LPFNIS95VER lpfnIs95Ver;
#define lptIs95Ver (*lpfnIs95Ver)

typedef BOOL (FAR PASCAL *LPFNCOMPAREVERSIONINFO)
	( LPSTR szOld, LPSTR szNew );
EXTERN LPFNCOMPAREVERSIONINFO  lpfnCompareVersionInfo;
#define lptCompareVersionInfo (*lpfnCompareVersionInfo)

typedef BOOL (FAR PASCAL *LPFNDELKEY)
	( HKEY hkRootKey, LPSTR szParentKey, LPSTR szDelKey );
EXTERN LPFNDELKEY  lpfnDelKey;
#define lptDelKey (*lpfnDelKey)

typedef BOOL (FAR PASCAL *LPFNRENAMEVALUE)
	( HKEY hkRootKey, LPSTR szKey, LPSTR szOldValName, LPSTR szNewValName);
EXTERN LPFNRENAMEVALUE	lpfnRenameValue;
#define lptRenameValue (*lpfnRenameValue)

typedef BOOL (FAR PASCAL *LPFNDOESVALUEEXIST)
	( HKEY hkRootKey, LPSTR szKey, LPSTR szValName );
EXTERN LPFNDOESVALUEEXIST  lpfnDoesValueExist;
#define lptDoesValueExist (*lpfnDoesValueExist)

//------------------------------------------------------------------
// Control strings...DO NOT TRANSLATE
//------------------------------------------------------------------
	// eight letter program name for files.
EXTERN LPSTR szC8_ProgName	DEFVAL( "SETUP" );

	// generic program title
EXTERN LPSTR szC_ProgTitle	  DEFVAL( "Setup" );

EXTERN LPSTR szC_ProgTitle32  DEFVAL( "Setup32" );

	// generic company name for string search.
EXTERN LPSTR szC_Us 	DEFVAL( "qualitas" );

	// Ctl3d library name
EXTERN LPSTR szC_Ctl3dLib	DEFVAL( "Ctl3dv2.dll" );
EXTERN LPSTR szC_Ctl3Comp	DEFVAL( "Ctl3dv2.dl_" );

EXTERN LPSTR szC_UnzipDLL	DEFVAL( "dunzip.dll" );
EXTERN LPSTR szC_UnzipComp	DEFVAL( "dunzip.dl_" );

EXTERN LPSTR szC_Unzip32DLL   DEFVAL( "dunzip32.dll" );
EXTERN LPSTR szC_Unzip32Comp  DEFVAL( "dunzip32.dl_" );

EXTERN LPSTR szC_VMMPath	DEFVAL( "VMM32" );

EXTERN LPSTR szDifExt		DEFVAL( "dif" );
EXTERN LPSTR szIniExt		DEFVAL( ".ini" );
EXTERN LPSTR szZipExt		DEFVAL( ".zip" );
EXTERN LPSTR szLstExt		DEFVAL( ".lst" );
EXTERN LPSTR szDataExt		DEFVAL( ".dat" );
EXTERN LPSTR szExeExt		DEFVAL( ".exe" );
EXTERN LPSTR szRegExt		DEFVAL( ".reg" );
EXTERN LPSTR szHlpExt		DEFVAL( ".hlp" );

EXTERN LPSTR szC_Null		DEFVAL( "" );

EXTERN LPSTR szC_Autoexec	DEFVAL( "autoexec.bat" );
EXTERN LPSTR szC_ConfigSys	DEFVAL( "config.sys" );
EXTERN LPSTR szC_WinIni 	DEFVAL( "win.ini" );
EXTERN LPSTR szC_SystemIni	DEFVAL( "system.ini" );
EXTERN LPSTR szC_HelpFile	DEFVAL( "SETUP.HLP" );
EXTERN LPSTR szC_Wininit	DEFVAL( "wininit.ini" );

EXTERN LPSTR szSetupWndClass   DEFVAL( "QSetupWndClass");
EXTERN LPSTR szSetupDlgClass   DEFVAL( "QSetupDialogClass");
EXTERN LPSTR szSplashWndClass  DEFVAL( "QSplashWndClass");

EXTERN LPSTR szC_IniOpt 	DEFVAL( "Options" );
EXTERN LPSTR szC_IniSaveReg DEFVAL( "SaveReg" );
EXTERN LPSTR szC_IniUndo	DEFVAL( "CapOnRestore" );

EXTERN LPSTR szC_IniIName	DEFVAL( "IName" );
EXTERN LPSTR szC_IniDir 	DEFVAL( "Directories" );
EXTERN LPSTR szC_IniDataDir DEFVAL( "Data" );
EXTERN LPSTR szC_IniRename	DEFVAL( "rename" );

EXTERN LPSTR szC_IniByAge	 DEFVAL( "ByAge" );
EXTERN LPSTR szC_IniMaxAge	 DEFVAL( "MaxAge" );
EXTERN LPSTR szC_IniByCount  DEFVAL( "ByCount" );
EXTERN LPSTR szC_IniMinCount DEFVAL( "MinCount" );
EXTERN LPSTR szC_IniMaxCount DEFVAL( "MaxCount" );

EXTERN LPSTR szC_Registry DEFVAL( "Registry" );
EXTERN LPSTR szC_USStartupGroup DEFVAL( "Startup" );
EXTERN LPSTR szC_DEStartupGroup DEFVAL( "AutoStart" );
EXTERN LPSTR szC_AutoSwitch DEFVAL( " /S" );

EXTERN LPSTR szC_InstSizeKey DEFVAL( "Install" );
EXTERN LPSTR szC_WinSizeKey  DEFVAL( "Windows" );

	// thunk librarys for 32 bit stuff.
EXTERN LPSTR szC_ThunkLibName DEFVAL( "setup16.dll" );
EXTERN LPSTR szC_Thunk32Name  DEFVAL( "setup32.dll" );

	// version VerQueryValue keys.
EXTERN LPSTR szC_VQVTranslation   DEFVAL( "\\VarFileInfo\\Translation" );
EXTERN LPSTR szC_VQVSFInfo	  DEFVAL( "\\StringFileInfo\\%04x%04x\\");
EXTERN LPSTR szC_VQVCoName	  DEFVAL( "CompanyName");
EXTERN LPSTR szC_VQVProdVer   DEFVAL( "ProductVersion");
EXTERN LPSTR szC_VQVFileVer   DEFVAL( "FileVersion");

	// uninstall keys
EXTERN LPSTR szC_HK_Uninstall DEFVAL( "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall" );
EXTERN LPSTR szC_HK_UDName	  DEFVAL( "DisplayName" );
EXTERN LPSTR szC_HK_UDString  DEFVAL( "UninstallString" );

EXTERN LPSTR szC_HK_UDDefault DEFVAL( ".Default" );

//------------------------------------------------------------------
// Text strings.
//------------------------------------------------------------------
#include <settext.us>


//------------------------------------------------------------------
// global variables
//------------------------------------------------------------------
	// global instance handle.
EXTERN HINSTANCE ghInstance;

	// parent window handle
EXTERN HWND hParent DEFVAL( NULL );

	// message dialog handle
EXTERN HWND hModeless DEFVAL( NULL );

	// Splash window handle
EXTERN HWND hSplash DEFVAL( NULL );

	// place to save arrow cursor
EXTERN HCURSOR hcArrow DEFVAL( NULL );

	// place to save hourglass cursor
EXTERN HCURSOR hcHour DEFVAL( NULL );

	// the global error exit message.
EXTERN char szGlobErrorMsg[ ERRMSGLEN + 1 ] DEFVAL( "" );

	// Ctl3D library handle.
EXTERN HANDLE hlibCTL3D DEFVAL( NULL );

	// thunk library for 32 bit stuff.
EXTERN HANDLE hlibThunk DEFVAL( NULL );

//------------------------------------------------------------------
// Help Key Pointers. Must set to point to local strings.
//------------------------------------------------------------------
EXTERN LPSTR szHKp_Contents DEFVAL( NULL );
EXTERN LPSTR szHKp_Main 	DEFVAL( NULL );
EXTERN LPSTR szHKp_Dir		DEFVAL( NULL );

//------------------------------------------------------------------
// System state flags.
//------------------------------------------------------------------
EXTERN jmp_buf quit_env;

	// Yes, this is Windows 95!!! ( also set for NT )
EXTERN BOOL bWin95 DEFVAL(0);

	// Yes, this is Windows NT!!!
EXTERN BOOL bWinNT DEFVAL(0);

	// Yes, this is Windows NT version 4 or greater!!!
EXTERN BOOL bWinNT4Plus DEFVAL(0);

	// this Windows NT is older than version 3.5!!!
EXTERN BOOL bOldNT DEFVAL(0);

	// if 16 bit in 32 bit environ, execute 32 bit and exit
	// Set from project ProcessCmdLine.
EXTERN BOOL bBoost32 DEFVAL(0);

	// Flag to indicate startup moved to desktop ( Win95 only ).
EXTERN BOOL bStartUp95 DEFVAL( 0 );

	// Country Code
EXTERN int nCountry DEFVAL( 1 );

	// inhibit splash screen on start.
EXTERN BOOL bSplashInhibit DEFVAL( 0 );

	// Windows version.
EXTERN DWORD dwVersion;

	// Win95 startup group flag.
EXTERN BOOL bStartup DEFVAL( FALSE );

	// window class for main window is registered.
EXTERN BOOL bClassReg DEFVAL( FALSE );

	// window class for dialog icon is registered.
EXTERN BOOL bDlgClassReg DEFVAL( FALSE );

	// File copy error occurred
EXTERN BOOL bFileError DEFVAL( FALSE );

//------------------------------------------------------------------
// splash screen stuff.
//------------------------------------------------------------------
	// splash window registered flag.
EXTERN BOOL bSplashReg DEFVAL( FALSE );

	// Is splash screen on? TRUE if yes.
EXTERN BOOL bSplashActive DEFVAL( FALSE );

	// timer for splash screen;
EXTERN time_t ttSplashStart DEFVAL(0);

	// time to display splash screen.
EXTERN int nSplashWait DEFVAL( SPLASHTIME );

	// handle for bitmap.
EXTERN HBITMAP hbSplash DEFVAL( NULL );

	// pixel height of bitmap
EXTERN int nBMHeight DEFVAL( 0 );

	// pixel width of bitmap
EXTERN int nBMWidth DEFVAL( 0 );

//------------------------------------------------------------------
// control flags. Set externally to control program attributes.
//------------------------------------------------------------------
	// inhibit use of ctl3dv2.dll.
EXTERN BOOL bC3DInhibit DEFVAL( 0 );

	// inhibit startup splash screen.
EXTERN BOOL bInhibitSplash DEFVAL( 0 );

//------------------------------------------------------------------
// User fillable buffers
//------------------------------------------------------------------
EXTERN char szBuff_Title[ TITLELEN + 2 ]
#ifdef SETUP_DEFVARS
	= "Qualitas Setup"
#endif
;

EXTERN char szQPFile[ _MAX_PATH + 2 ]
#ifdef SETUP_DEFVARS
	= "qpacking.lst"
#endif
;

	// Install directory buffer.
EXTERN char szInstallDir[ _MAX_PATH + 2 ]
#ifdef SETUP_DEFVARS
	= ""
#endif
;

	// set this to ID for Help. ( IDM_HELP )
EXTERN WORD wHelpID DEFVAL( 0 );

	// space requirements.
EXTERN LONG lTotSize DEFVAL( 0 );
EXTERN LONG lWinSize DEFVAL( 0 );

	// f1 filter proc globals.
EXTERN HOOKPROC hpF1;
EXTERN HHOOK  hhF1;

	// Active Dialog window handle (to send help messages to ).
EXTERN HWND hActive DEFVAL( NULL );

	// Accelerator table id.
EXTERN WORD wACCTable DEFVAL( NULL );

	// global dialog handle from CreateDialog.
EXTERN HWND hGlobDlg DEFVAL( NULL );

//------------------------------------------------------------------
// Memory Anchors. These are _fmalloced during program init.
//------------------------------------------------------------------

EXTERN LPSTR lpProgName 	DEFVAL( NULL );
EXTERN LPSTR lpProgPath 	DEFVAL( NULL );
EXTERN LPSTR lpDataPath 	DEFVAL( NULL );
EXTERN LPSTR lpUndoPath 	DEFVAL( NULL );
EXTERN LPSTR lpWinPath		DEFVAL( NULL );
EXTERN LPSTR lpSysPath		DEFVAL( NULL );
EXTERN LPSTR lpHelpFile 	DEFVAL( NULL );
EXTERN LPSTR lpStartup		DEFVAL( NULL );
EXTERN LPSTR lpWIniFile 	DEFVAL( NULL );
EXTERN LPSTR lpIniFile		DEFVAL( NULL );
EXTERN LPSTR lpZipFile		DEFVAL( NULL );

	// enum zip filenames list
EXTERN LPSTRINGLIST lpEnumZip  DEFVAL( NULL );

	// anchor for list of disks and files.
EXTERN LPDISKLIST lpADisks DEFVAL( NULL );

//------------------------------------------------------------------
// The following temporary buffers should be considered volitile.
// Any data put into them should be used immediatly.
//------------------------------------------------------------------
	// must be greater than _MAX_PATH (256)
#define TEXTBUFLEN 512

	// file line read buffer
EXTERN char szTRead[ TEXTBUFLEN + 1 ];

	// Temporary text buffer.
EXTERN char szTemp[ TEXTBUFLEN + 1 ];

	// Temporary buffer.
EXTERN char szTPath[ _MAX_PATH + 1 ];

//------------------------------------------------------------------
#endif // SETGLOB_INCLUDED

