// $Header:   P:/PVCS/MAX/MAXSETUP/SETUP.C_V   1.57   30 May 1997 11:53:04   BOB  $
//
// SETUP.C - Windows installation routine for Qualitas MAX 8.0
//  Copyright (C) 1995-7 Qualitas Inc.

#include "setup.h"

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <string.h>
#include <malloc.h>

#include <dlgs.h>
#include <commdlg.h>
#include <shellapi.h>
#include <toolhelp.h>
#include <ver.h>

#include <bioscrc.h>
#include <dosmax.h>

#include "cversion.h"
#include <maxnames.h>
#include "maxtime.h"
#include <mversion.h>

#include <mbparse.h>
#include "multicom.h"

    // define message variables
#define SETUP_MSG_DEFVARS 1
#include "messages.h"

#define PROGRAM_SIZE	2495
#define ONLINEHELP_SIZE  450
#define DOSREADER_SIZE 85

#define PM_TASKEND	WM_USER+0x100

#define LCLDRV_GETBUFADDR		0x0800
#define LCLDRV_REGISTER 		0x0801
#define LCLDRV_UNREGISTER		0x0802
#define LCLDRV_QUERYCLOSE		0x0803
#define LCLDRV_QUERYENABLE		0x0804
#define LCLDRV_QUERYINSTALL		0x0805
#define LCLDRV_QUERYLOWSEG		0x0806
#define LCLDRV_DISABLE			0x0807
#define LCLDRV_ENABLE			0x0808
#define FILENAME "goahead"
#define FILENAMEXT FILENAME ".drv"
#define FILENAMEXE FILENAME ".exe"
#define IDC_MEMCHANGED			1019
#define IDC_TASKCHANGED 		1020

#define RESTARTLINELEN 127
#define PROFLINELEN 516
#define SPCBUFSIZE 132

char NULLSTR[] = "";

LPSTR pszGALoadClear = "GALoadClear";
LPSTR pszGADialog = "GADialog";
char szDrvName[] = FILENAMEXT;

char szMMName[] = "maxmeter.exe";

char szMAXmeter[] = "MAXmeter";
char szGoAhead[] = "Go Ahead";

char szStripMgr[] = "stripmgr.out";
char szStrip31[] = "stripmgr.pif";
char szStrip95[] = "stripm95.pif";
char szStripPIF[ 20 ];

char szIniConfig[] = "CONFIG";
char szIniReg[] = "Registration";
char szIniGaProgs[] = "Go Ahead - Programs";
char szIniGaIncompatable[] = "Go Ahead - Incompatible Drivers";
char szIniGaIgnore[] = "Ignore";
char szIniMEFiles[] = "MAXedit - Files";

//------------------------------------------------------------------
// Incompatible Drivers list for QMAX.INI for Go Ahead.
// This list describes in which ini files to look for conflicting
// resource managers.
// These are stored in QMAX.INI in the
// [Go Ahead - Incompatible Drivers] section.
// Entries are count= and driver#= where # = 1 thru n
// count=5
// driver1="system.ini,386enh,device,ramdublr.386,RamDoubler",
// Fields are:
// "File,section,entry,value to search for,Descriptive string"
//------------------------------------------------------------------
    // list for Go Ahead incompatible drivers
char *szGaInc[ ] = {
    "system.ini,386enh,device,ramdublr.386,RamDoubler",
    "system.ini,386enh,device,Softram1.386,SoftRam",
    "system.ini,386enh,device,Softram2.386,SoftRam",
    "system.ini,386enh,device,MagnaRam.386,MagnaRam",
    "system.ini,386enh,device,WinWatch.386,Hurricane",
    "system.ini,386enh,device,WinGuard.386,Hurricane",
    "system.ini,386enh,device,VXMSEMS.386,Hurricane",
    "system.ini,386enh,device,VCache16.386,Hurricane",
    "system.ini,386enh,device,Globmem.386,Hurricane",
    "system.ini,386enh,device,ARPL.386,Hurricane",
    "system.ini,386enh,device,VSectD.386,Hurricane",
    "system.ini,386enh,device,Heapx.386,Hurricane",
    "system.ini,386enh,device,Magna31.vxd,MagnaRam",
    "system.ini,boot,drivers,MagnaRam.dll,MagnaRam",
    "system.ini,boot,drivers,Rsrcmgr.dll,Memory Multiplier",
    "system.ini,boot,drivers,FreeMeg.dll,FreeMeg",
    "system.ini,boot,system.drv,sysdrv.drv,Hurricane"
};
#define GAIC_COUNT ( sizeof( szGaInc ) / sizeof( szGaInc[0] ))

//------------------------------------------------------------------

int fRefresh = 0;
int fPreBrand = 0;
int fUpdate = 0;
int	Overwrite = 0;
int nCountry = 1;
BOOL PatchPrep = FALSE;

int fMaximize = 0;
int fReboot = 0;
int fRestart = 0;
int fCopiedSetup = 0;

extern char szBackupDir[1];

char szMax[80] = "";                    // existing MAX directory
char szMaxPro[80] = "";                 // 386MAX.PRO filename
char szExtraDosPro[80] = "";            // EXTRADOS.PRO filename
char szININame[80];			// QMAX.INI name
char szConfigSys[80] = "C:\\CONFIG.SYS";
char szConfigTemp[ _MAX_PATH + 1];
char szAutoTemp[ _MAX_PATH + 1];
char szAutoexec[80] = "C:\\AUTOEXEC.BAT";
char szIOSIni[ _MAX_PATH + 1];	    // IOS.INI file
char szMaxIOSIni[ _MAX_PATH + 1];	// IOS.INI safe file
char szSystemIni[80];
char szWinIni[80];
char szMaxConfigSys[80];
char szMaxAutoexec[80];
char szMaxSystemIni[80];
char szMaxWinIni[80];
char szMaxMaxPro[80];
char szMaxExtraDosPro[80];
char *szAppName = PROGNAME;		// App name
// Caption
char *szCaption = MAX8PRODUCT "." VER_MINOR_STR " Setup";
char szDest[_MAX_PATH+1]  = "C:\\QMAX";         // Destination path
char *szProgmanGroup = "Qualitas MAX";          // Progman group caption
char *szUSStartupGroup = "Startup";
char *szDEStartupGroup = "AutoStart";
char szStartupGroup[ 80 ];
char szWindowsDir[_MAX_PATH+1];
char szWindowsSystemDir[_MAX_PATH+1];
char szSetupName[80];			// drive/path/name for SETUP.EXE
char szHelpName[80];			// drive/path/name for SETUP.HLP
char szSections[4096];
char szCurrentSection[128];
char szMultiSection[128];
char szMultiDescription[256];
char szADFSrc[ _MAX_PATH + 1 ];
char szADFDest[ _MAX_PATH + 1 ];
char *pszShowFile;
char *pszStripExcept = "";              // What to _not_ strip; may be "~386MAX " or
char szSMDir[ _MAX_PATH + 1 ];
								// "~BLUEMAX " or nothing
int nOldMaxLine = -1;			// Origin:0 line number of original 386max.sys
								// or bluemax.sys line (only needed to replace
								// bluemax.sys)
BOOL bMaxFound = FALSE; 		// TRUE if 386MAX.SYS or BLUEMAX.SYS was found

char szName[64];
char szCompany[64];
char szSerial[64];

    // strings for IOS.INI
char *szSafeList = "SafeList";
char *szLoadcom = "386Load.com\t; Qualitas Memory Manager";
char *szLoadsys = "386Load.sys\t; Qualitas Memory Manager";
char *szDisksys = "386Disk.sys, NON_DISK\t; Qualitas RAM Drive";

LPSTR szCopyFileName = "COPYFILE.BAT";
LPSTR szCopyDir = "COPYDIR";
LPSTR szCopyProg = "clean.exe";
LPSTR szCTL3D = "ctl3dv2.dll";
LPSTR szTokDel = " ;";
LPSTR szSetup  = "Setup";
LPSTR szSetCmd = "Setup.exe /C";

    // BCF detection
BOOL bBCFsys = FALSE;
BOOL bMCAsys = FALSE;
BOOL bValidBCF = FALSE;
WORD BIOSCRC = 0;
char bcf_dest[ _MAX_PATH + 1 ];
extern void calc_crcinfo( void );

extern void profile_add( void );
extern void edit_batfiles();
extern FILEDELTA *get_filedelta( char *pszPath );
extern char *get_outname( FILEDELTA *pF );

    // sharing violation trapped.
BOOL bHadToCopy = FALSE;
BOOL bBackFromCopy = FALSE;
BOOL bCleanOut = FALSE;
extern BOOL AddToCopyBatch( LPSTR szSaved, LPSTR szDest, LPSTR szCopyFile );
extern BOOL MakeCopyDir( LPSTR szDest, LPSTR lpCopyPath, LPSTR lpCopyFile );

BOOL bIOSModified = 0;

BOOL bWin95 = 0;
BOOL bStartUp95 = 0;
BOOL bExistingMAX = 0;		// 1 if MAX is already installed

BOOL bMChanged = FALSE;

    // were they running flags.
BOOL bGAFound = FALSE;
BOOL bMMFound = FALSE;

BOOL bGASaved = FALSE;

    // the "don't load Go Ahead" flag
BOOL bStayBack = 0;

BOOL bPrograms = 1;		// 1 to install MAX program files
BOOL bOnlineHelp = 1;		// 1 to install MAX help files
BOOL bDosReader = 1;		// 1 to install MAX DOS help file reader

BOOL bGoAhead = 1;		// 1 to load GoAhead in startup group
BOOL bMaxMeter = 1;		// 1 to load MAX Meter in startup group
BOOL bMDA = 1;			// 1 to use MDA
BOOL bQMT = 0;			// 1 to load QMT in AUTOEXEC.BAT
BOOL bEMS = 0;			// 1 to enable EMS

BOOL bUpdateFiles = 1;		// 1 to update .INI, .SYS, .BAT; 0 to put the
				//   changes in .ADD files
BOOL bModified = 0;		// set if .INI, .SYS, or .BAT modified
BOOL bMaxProModified = 0;

DWORD dwVersion;		// Windows version

HWND hParent;		// handle to setup frame window
HWND hSplash;			// handle to modeless startup splash window
HWND hModeless; 		// handle to general purpose modeless dialog

HINSTANCE ghInstance;
HINSTANCE ghChildInstance;
HINSTANCE ghToolhelp;

HTASK ghTaskParent;

jmp_buf quit_env;		// shutdown jump point

LPFNNOTIFYCALLBACK lpCallBackProc = 0L;

void CopyADFFiles();
BOOL GALoadClearance();

void WalkWindowList( );
BOOL InitApplication(HANDLE);
BOOL InitInstance(HANDLE, int);

void ReadMulticonfig(void);
void Install(void);
int DrawMeter(HWND, int);
static void Encrypt(void);
static void Decrypt( void );
int BrandFile (char *);
void CheckForMax( void );
void CheckForBrand( void );
int ParseInstallCfg( char *szLine );
void InsertInConfigSys(char *, char *, char *, int);
int ModifyAutoexec(char *, int);
int ModifyDOSMAXReg( void );
void ModifyMaxPro( char *, int );
char * ParsePro(char *, char *);
void CreatePreinst(void);
int ReadBrand ( char *, int );
int AddDOSMAXKeys( void );
void ModifyIOSIni( char *, char * );
void ShutDownMaxUtils();
void RestartMaxUtils( LPSTR szDst);
BOOL BackupMAXDir( void );
void BackupFile ( LPSTR fname );
BOOL NeedBackup( LPSTR lpOld, LPSTR lpNew );
BOOL DelMaxProRange( LPSTR lpSection, LPSTR lpEntry, DWORD dwLow );
BOOL SFS_Read( LPSTR lpFile );
BOOL SFS_Write( LPSTR lpFile );
BOOL SFS_Search( LPSTR lpSection, LPSTR lpEntry, DWORD dwLow );
BOOL SFS_Add( LPSTR line );
void SFS_Cleanup();

int CALLBACK MultiCfgEdit(BOOL *, LPSTR, LPSTR, LPSTR, LPSTR, LPSTR, LPSTR);
long CALLBACK __export MainWndProc(HWND, UINT, WPARAM, LPARAM);
long CALLBACK __export SplashWndProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export RefDirDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ModelessDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export WelcomeDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export RegisterDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ConfirmDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export MultiDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export DirectoryDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ConfigureDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export UpdateDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export UpdateErrorDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExtractDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export FilesDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ShowDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitSuccessDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitRebootDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitRestartDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitNewDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export AskQuitDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export NotifyRegisterCallback( UINT, DWORD );


int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
{
    LPSTR lpTemp;

    // We don't allow multiple instances
    if (hPrevInstance) {
	WalkWindowList();
	return 1;
    }

    ghInstance = hInstance;

    strip_leading( lpszCmdLine, " \t" );
    strip_trailing( lpszCmdLine, " \t" );

	if (( lpTemp = _fstrstr( lpszCmdLine, (LPSTR)"/W" )) != NULL ) {
	fRefresh = 1;
    }

	if (( lpTemp = _fstrstr( lpszCmdLine, (LPSTR)"/C" )) != NULL ) {
	bBackFromCopy = TRUE;
    }

    // initialize 3-D support
    Ctl3dRegister(hInstance);
    Ctl3dAutoSubclass(hInstance);

    // Create "Qualitas" Progman group and add items
    InitDDE();

    dwVersion = GetVersion();
    if (((dwVersion & 0xFF) >= 4) || (((dwVersion >> 8) & 0xFF) >= 50)) {
	bWin95 = TRUE;
	bStayBack = TRUE;
    }

	// adjust for new pif format
    if ( bWin95 ) {
	_fstrcpy( szStripPIF, szStrip95 );
    } else {
	_fstrcpy( szStripPIF, szStrip31 );
    }

    // create or activate the "Qualitas MAX" group
    if (bWin95 == 0) {
	if ((pmCreateGroup( szProgmanGroup, NULLSTR ) == FALSE ) || (pmShowGroup( szProgmanGroup, 1 ) == FALSE )) {
	    MessageBox(0, szMsg_Init, szMsg_InitTitle, MB_OK | MB_ICONSTOP);
	    goto Exit;
	}
	pmShowGroup( szProgmanGroup, SW_SHOWMINIMIZED );
    }

    if (!InitApplication(hInstance))
	goto Exit;

    if (!InitInstance(hInstance, nCmdShow))
	goto Exit;

    // get the Windows directories
    GetWindowsDirectory(szWindowsDir, _MAX_PATH);
    GetSystemDirectory(szWindowsSystemDir, _MAX_PATH);
    MakePath( szWindowsDir, "SYSTEM.INI", szSystemIni );
    MakePath( szWindowsDir, "WIN.INI", szWinIni );
    MakePath( szWindowsDir, "IOS.INI", szIOSIni );

    GetWindowsDirectory(szININame, _MAX_PATH);
    MakePath( szININame, "QMAX.INI", szININame );

	// special case German startup group.
    nCountry = GetProfileInt( (LPSTR)"intl", (LPSTR)"iCountry", nCountry );
    if( nCountry == 49 ) {
	_fstrcpy( szStartupGroup, szDEStartupGroup );
    } else {
	_fstrcpy( szStartupGroup, szUSStartupGroup );
    }

    // get full path & filename of SETUP.EXE
    GetModuleFileName( hInstance, szSetupName, 127 );

    MakePath( path_part(szSetupName), "setup.hlp", szHelpName );

    ghTaskParent = GetCurrentTask();
    if ((ghToolhelp = LoadLibrary("TOOLHELP.DLL")) > (HINSTANCE)32) {
	// Attempt to register a notify callback with toolhelp.dll
	lpCallBackProc = (LPFNNOTIFYCALLBACK)MakeProcInstance((FARPROC)NotifyRegisterCallback, hInstance);
	if (NotifyRegister( NULL, lpCallBackProc, NF_NORMAL ) == FALSE) {
	    FreeProcInstance( (FARPROC)lpCallBackProc );
	    lpCallBackProc = 0L;
	}
    }

    if( bBackFromCopy ) {

	lstrcpy( (LPSTR)szDest, (LPSTR)path_part(szSetupName));

	pmShowGroup( szStartupGroup, 2 );
	pmShowGroup( szStartupGroup, 1 );
	SetupYield(0);

	    // don't ask me why...one doesn't always work...two does.
	pmDeleteItem( szSetup );
	pmDeleteItem( szSetup );
	SetupYield(0);

	pmShowGroup( szStartupGroup, SW_SHOWMINIMIZED );
	SetupYield(0);
    }

    // set exit jump_buf (EXIT, WM_CLOSE, etc.) & exec the install dialogs
    if (setjmp(quit_env) >= 0) {
	Install();
    }

Exit:

    if( fRestart ) {
	char szTemp[ _MAX_PATH + 2 ];

	pmCreateGroup( szStartupGroup, NULLSTR );
	SetupYield(0);

	MakePath(szDest, szSetCmd, szTemp );

	pmAddItem( szTemp, szSetup, NULLSTR, 0 );
	SetupYield(0);
	pmShowGroup( szStartupGroup, 2 );
	SetupYield(0);
    }

    EndDDE();

    // Free up the Notify callback and it's instance thunk
    if (lpCallBackProc != 0L) {
	NotifyUnRegister(NULL);
	FreeProcInstance((FARPROC)lpCallBackProc);
	FreeLibrary(ghToolhelp);
    }

    if ( fRestart ) {
	BOOL bExec = FALSE;
	int nCancel = IDCANCEL;
	int nExeLen;
	int nParmLen;
	char szExe[ RESTARTLINELEN + 2 ];
	char szParm[ RESTARTLINELEN + 2 ];

	nExeLen = _fstrlen( (LPSTR)szDest );
	nExeLen += _fstrlen( (LPSTR)szCopyProg );

	nParmLen = _fstrlen( (LPSTR)szDest );
	nParmLen += _fstrlen( (LPSTR)szCopyDir );
	nParmLen += _fstrlen( (LPSTR)szCopyFileName );
	nParmLen += _fstrlen( (LPSTR)szDest );
	nParmLen += _fstrlen( (LPSTR)szWindowsDir );
	nParmLen += 2;

	if (( nExeLen < RESTARTLINELEN)
	    &&( nParmLen < RESTARTLINELEN) ) {
	    MakePath( szDest, szCopyProg, szExe );

	    MakePath( szDest, szCopyDir, szParm );
	    MakePath( szParm, szCopyFileName, szParm );
	    _fstrcat( szParm, " " );
	    _fstrcat( szParm, szDest );
	    _fstrcat( szParm, " " );
	    _fstrcat( szParm, szWindowsDir );

	    do {
		SetupYield(0);
		bExec = ExitWindowsExec( (LPSTR)szExe, (LPSTR)szParm );

		if ( !bExec ) {
		nCancel = MessageBox( NULL, szMsg_SFFail, szMsg_SFFailTitle, MB_RETRYCANCEL | MB_ICONSTOP );
		}
	    } while( nCancel == IDRETRY );
	}

    } else {

	SetupYield(0);
	WinHelp(hParent, szHelpName, HELP_QUIT, 0L);
	DestroyWindow(hParent);
	Ctl3dUnregister(hInstance);

	if (fMaximize) {
	char szBuf[256];

	MakePath( szDest, "winmaxim.exe", szBuf );
	WinExec( (LPSTR)szBuf, SW_SHOW);
	}
    }

	// cancel might end up here.
    WinHelp(hParent, szHelpName, HELP_QUIT, 0L);
    DestroyWindow(hParent);
    Ctl3dUnregister(hInstance);
    return 0;
}

// Walks the lists of top level windows, looking for previously loaded
//   module's HWND, then switching to it
void WalkWindowList( void )
{
	char szModuleName[10];
	HWND hWnd;

	// Get the desktop window.  Then, get its first child window.
	// This is the start of the list of top level windows.
	if ((hWnd = GetDesktopWindow()) == 0)
		return;
	hWnd = GetWindow(hWnd, GW_CHILD);

	while (hWnd) {

		// window can't be owned, and must be visible.
		if ((GetWindow(hWnd, GW_OWNER) == 0) && (IsWindowVisible(hWnd))) {

			HTASK hTask;

			hTask = GetWindowTask(hWnd);
			wsprintf(szModuleName, "%.8s", MAKELP(hTask, 0xF2));
			if (lstrcmpi(szModuleName, "Setup") == 0) {
				SetWindowPos( hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW );
				SetFocus( hWnd );
				break;
			}
		}

		hWnd = GetWindow(hWnd, GW_HWNDNEXT);	// Go on to next window
	}
}

/****************************************************************************

    FUNCTION: InitApplication(HANDLE)
    PURPOSE: Initializes window data and registers window class

****************************************************************************/

BOOL InitApplication(HANDLE hInstance)
{
	WNDCLASS  wc;

	wc.style = NULL;
	wc.lpfnWndProc = MainWndProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = hInstance;
	wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = GetStockObject(BLACK_BRUSH);
	wc.lpszMenuName =  NULL;
	wc.lpszClassName = "SetupWClass";

	// Register the window class.
	RegisterClass(&wc);

	wc.style = NULL;
	wc.lpfnWndProc = SplashWndProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = hInstance;
	wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = GetStockObject(BLACK_BRUSH);
	wc.lpszMenuName =  NULL;
	wc.lpszClassName = "SplashWClass";

	// Register the window class and return success/failure code.
	return (RegisterClass(&wc));
}


/****************************************************************************

    FUNCTION:  InitInstance(HANDLE, int)
    PURPOSE:  Saves instance handle and creates main window

****************************************************************************/

BOOL InitInstance(HANDLE hInstance, int nCmdShow)
{
    // Create a main window for this application instance.
    hParent = CreateWindow("SetupWClass", szCaption,
	WS_OVERLAPPED | WS_SYSMENU | WS_THICKFRAME | WS_MAXIMIZE | WS_CLIPCHILDREN,
	CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
	NULL, NULL, hInstance, NULL );

    // If window could not be created, return "failure"
    if (!hParent)
	return FALSE;

    ShowWindow(hParent, SW_SHOWMAXIMIZED);

    hSplash = CreateWindow("SplashWClass", "", WS_POPUP,
	20, 20, 410, 236, hParent, NULL, hInstance, NULL );

    ShowWindow(hSplash, SW_SHOW);
    while (hSplash != NULL)
	SetupYield(0);

    // Make the window visible; update its client area; and return "success"
    UpdateWindow(hParent);

    return TRUE;
}


long CALLBACK __export MainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	register int n;
	int nColor, nColorAdjust, nBottom;
	PAINTSTRUCT ps;
	HBRUSH hBrush, hOldBrush;
	HFONT hFont, hOldFont;
	RECT Rect;

	switch (message) {
	case WM_DESTROY:
	    PostQuitMessage(0);
	    break;

	case WM_PAINT:

	    BeginPaint( hWnd, &ps );

	    // draw the background "fade" (from bright blue to black)
	    GetClientRect( hWnd, &Rect );
	    nColorAdjust = ( 256 / (Rect.bottom / 8)) + 1;
	    nBottom = Rect.bottom;

	    for (n = 0, nColor = 255; (n < nBottom); n += 8) {

		hBrush = CreateSolidBrush( RGB(0,0,nColor) );
		hOldBrush = SelectObject( ps.hdc, hBrush );
		Rect.top = n;
		Rect.bottom = n + 8;
		FillRect( ps.hdc, &Rect, hBrush );
		SelectObject( ps.hdc, hOldBrush );
		DeleteObject( hBrush );

		if ((nColor -= nColorAdjust) < 0)
			nColor = 0;
	    }

	    // draw text in window
	    SetBkMode( ps.hdc, TRANSPARENT );

	    hFont = CreateFont( -40, 0, 0, 0, FW_BOLD, 0, 0, 0, 0, 0, 0, 0, 0, "Arial" );
	    hOldFont = SelectObject( ps.hdc, hFont );

	    // first draw the black shadow
	    SetTextColor( ps.hdc, RGB(0,0,0) );
	    TextOut( ps.hdc, 15, 12, szCaption, lstrlen(szCaption) );

	    // now draw the white text
	    SetTextColor( ps.hdc, RGB(255,255,255) );
	    TextOut( ps.hdc, 12, 10, szCaption, lstrlen(szCaption) );
	    SelectObject( ps.hdc, hOldFont );
	    DeleteObject( hFont );

// draw bitmap here

	    EndPaint( hWnd, &ps );
	    break;

	case PM_TASKEND:
	    // Child has terminated
	    ghChildInstance = NULL;
	    break;

	default:
	    return (DefWindowProc(hWnd, message, wParam, lParam));
	}

	return 0L;
}


// receive & dispatch Windows messages
void SetupYield(int bWait)
{
	MSG msg;

	// process any waiting messages
	while (PeekMessage( &msg, NULL, 0, 0, PM_REMOVE )) {
ProcessMessage:
		if ((hSplash == NULL) || (IsDialogMessage(hSplash, &msg) == 0)) {
			bWait = 0;
			TranslateMessage( &msg );
			DispatchMessage( &msg );
		}
	}

	// if "Wait" flag set, go to sleep until a message arrives
	if ((bWait) && (GetMessage(&msg, NULL, 0, 0)))
		goto ProcessMessage;
}

// read CONFIG.SYS file to get multiconfig sections
void ReadMulticonfig(void)
{
	char cBootDrive, *ptr;
	char szBuf[512];
	HFILE fh;

	szSections[0] = '\0';
	szCurrentSection[0] = '\0';
	szMultiSection[0] = '\0';

	if ((ptr = getenv("CONFIG")) != NULL)
		lstrcpy( szCurrentSection, ptr );

	// set the boot drive (to simplify finding CONFIG.SYS)
	if (_osmajor < 4)
		cBootDrive = 'C';
	else {
_asm {
		mov	ax, 03305h
		int	21h
		add	dl, 64
		mov	cBootDrive, dl
}
	}

	szConfigSys[0] = cBootDrive;
	szAutoexec[0] = cBootDrive;

	// read CONFIG.SYS for section names
	if ((fh = _lopen( szConfigSys, READ | OF_SHARE_DENY_NONE)) != HFILE_ERROR) {

		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			if (_strnicmp( szBuf, "menuitem", 8 ) == 0) {
				for (ptr = szBuf+8; ((*ptr == ' ') || (*ptr == '=')); ptr++)
					;
				if (lstrlen(szSections) + lstrlen(ptr) >= 4090)
					break;
				lstrcat( szSections, ptr );
				lstrcat( szSections, "\n" );
			}
		}

	// create CONFIG.SYS for those who don't have it!
	} else if ((fh = _lcreat (szConfigSys, 0 )) == HFILE_ERROR ) {
		MessageBox(0, szMsg_CreaCsys, szMsg_SetTitle, MB_OK | MB_ICONSTOP);
		fMaximize = 0;
		longjmp( quit_env, -1 );
	}

	_lclose(fh);
}


// do all the actual installation work here
void Install()
{
	static char szUSEMDA[] = "USE=B000-B800   ; SETUP";
	static char szNOFLEX[] = "NOFLEX   ; SETUP";
	static char szEMS[] = "EMS=0   ; SETUP";
	static char szNOWIN30[] = "NOWIN30   ; SETUP";
	char *arg, szTemp[512], szBuf[512];
	int n, rc;
	UINT uRef;
	HDRVR hDriver;

	if ( bBackFromCopy ) {
	    goto FinalDlgs;
	}

	// read CONFIG.SYS for section names
	ReadMulticonfig();

	SetupYield(0);
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(WELCOMEDLGBOX), hParent, WelcomeDlgProc);
	SetupYield(0);

	MakePath( path_part(szSetupName), "setupdos.ovl", szBuf );
	ReadBrand( szBuf, 1 );

Preregistered:
	if (szName[0]) {
		fPreBrand = 1;
		DialogBox(ghInstance, MAKEINTRESOURCE(PREBRANDEDDLGBOX), hParent, ConfirmDlgProc);
		goto Multiconfig;
	}

Register:
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(REGISTERDLGBOX), hParent, RegisterDlgProc);
	SetupYield(0);

	rc = DialogBox(ghInstance, MAKEINTRESOURCE(CONFIRMDLGBOX), hParent, ConfirmDlgProc);
	SetupYield(0);
	if (rc == 2)
		goto Register;

	// check for Update
	if (szSerial[1] == '2') {

		// check for previous 386MAX installation
		CheckForMax( );
		CheckForBrand( );

		if (fUpdate == 0) {
Update:
			DialogBox(ghInstance, MAKEINTRESOURCE(UPDATEDLGBOX), hParent, UpdateDlgProc);
	    SetupYield(0);

			CheckForBrand();
			if (fUpdate == 0) {
				rc = DialogBox(ghInstance, MAKEINTRESOURCE(UPDATEERRORDLGBOX), hParent, UpdateErrorDlgProc);
				SetupYield(0);
				if (rc == 2)
					goto Update;
				szMax[0] = '\0';
			}
		}
	}
	// check for multiconfig
Multiconfig:
	if (szSections[0]) {
		rc = DialogBox(ghInstance, MAKEINTRESOURCE(MULTIDLGBOX), hParent, MultiDlgProc);
		SetupYield(0);
		if (rc == 2) {
			if (fPreBrand)
				goto Preregistered;
			goto Register;
		}
	}

	// check for previous 386MAX installation
	CheckForMax( );

	// get directory
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(DIRECTORYDLGBOX), hParent, DirectoryDlgProc);
	SetupYield(0);
	if (rc == 2) {
		if (szSections[0])
			goto Multiconfig;
		else
			goto Register;
	}

	if (szMaxPro[0] == '\0') {
		// No 386MAX.PRO
		bMaxProModified = 0x10;
		MakePath( szDest, "386max.pro", szMaxPro );
	}

    ShutDownMaxUtils();

//------------------------------------------------------------------
// Test for BCF / MCA here.
    calc_crcinfo();
//
// sets bBCFsys == TRUE if BCF system found.
// puts destination filename in bcf_dest.
//------------------------------------------------------------------

	// extract files
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(EXTRACTDLGBOX), hParent, ExtractDlgProc);
	SetupYield(0);

	if ((bPrograms == 0) && (fRefresh == 0))
		goto SetupGroup;

	// Branding note! As of now (ver 8.0) only DOS apps are branded.
	// The files below should not be part of a necessary exit to DOS copy
	// from Windows. When it is necessary for a Windows file to get
	// branded, the branding mechanism will have to be moved to
	// post-dos copy to ensure the file gets branded.

	MakePath(szDest, "386max.sys", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "asq.exe", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "qmt.exe", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "386util.com", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "386load.com", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "max.exe", szTemp );
	BrandFile( szTemp );

	SetupYield(0);
	MakePath(szDest, "maximize.exe", szTemp );
	BrandFile( szTemp );

	SetupYield(0);

    if ( bPrograms == 1 ) {
	int uError;
	DWORD dwStatus;

	DWORD dwCurHdl;
	DWORD dwCurSize;
	UINT uCurFSize;
	void FAR *lpCurPtr = NULL;
	VS_FIXEDFILEINFO FAR * lpCurFFI = NULL;

	DWORD dwNewHdl;
	DWORD dwNewSize;
	UINT uNewFSize;
	void FAR *lpNewPtr = NULL;
	VS_FIXEDFILEINFO FAR * lpNewFFI = NULL;

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	// All of this is because VerInstallFile considers Access errors
	// more important than whether you really need to replace the file.
	// Hence, we cannot take a failure in VerInstallFile as implying a
	// necessity to replace the file.

	MakePath( szWindowsSystemDir, szCTL3D, szBuf );
	if(( dwCurSize = GetFileVersionInfoSize( (LPSTR)szBuf, (DWORD FAR *)&dwCurHdl )) != NULL ){
	    if (( lpCurPtr = _fmalloc( (size_t) dwCurSize )) != NULL ) {
		if ( GetFileVersionInfo( (LPSTR)szBuf, dwCurHdl, dwCurSize, lpCurPtr )) {
		    VerQueryValue( lpCurPtr, (LPCSTR)"\\", (void FAR * FAR* )&lpCurFFI, (UINT FAR *)&uCurFSize );
		}
	    }
	}

	MakePath( szDest, szCTL3D, szTemp );
	if(( dwNewSize = GetFileVersionInfoSize( szTemp, (DWORD FAR *)&dwNewHdl )) != NULL ) {
	    if (( lpNewPtr = _fmalloc( (size_t) dwNewSize )) != NULL ) {
		if ( GetFileVersionInfo( (LPSTR)szTemp, dwNewHdl, dwNewSize, lpNewPtr )) {
		    VerQueryValue( lpNewPtr, (LPCSTR)"\\",  (void FAR * FAR* )&lpNewFFI, (UINT FAR *)&uNewFSize );
		}
	    }
	}

	if ( lpCurPtr != NULL ) {
	    _ffree( lpCurPtr );
	}

	if ( lpNewPtr != NULL ) {
	    _ffree( lpNewPtr );
	}
	    // if no destination file or if src file newer...
	if ( ( dwCurSize == NULL ) ||
	     (( lpCurFFI && lpNewFFI ) &&
	      ( lpNewFFI->dwFileVersionMS > lpCurFFI->dwFileVersionMS ) ||
	      (( lpNewFFI->dwFileVersionMS == lpCurFFI->dwFileVersionMS ) &&
	       ( lpNewFFI->dwFileVersionLS > lpCurFFI->dwFileVersionLS )))) {

	    dwStatus = VerInstallFile( 0, "ctl3dv2.dll", "ctl3dv2.dll", szDest, szWindowsSystemDir, szWindowsSystemDir, szTemp, &n );

	    if ( dwStatus & ( VIF_FILEINUSE | VIF_SHARINGVIOLATION )) {
		char lpSaved[ 258 ];
		char lpCopyFile[ 258 ];
		char lpCopyPath[ 258 ];

		    // let the DOS copier copy it.
		MakeCopyDir( (LPSTR)szDest, (LPSTR)lpCopyPath, (LPSTR)lpCopyFile );
		MakePath( szDest, szCTL3D, szTemp );
		MakePath( lpCopyPath, szCTL3D, lpSaved );
		if (!FileCopy( lpSaved, szTemp )) {
		    AddToCopyBatch( (LPSTR)lpSaved, (LPSTR)szWindowsSystemDir, (LPSTR) lpCopyFile );
		    bHadToCopy = TRUE;
		}
	    }
	}

	    // remove the \qmax copy
	MakePath( szDest, szCTL3D, szTemp );
	remove( szTemp );
	SetErrorMode( uError );
	SetupYield(0);
    }

	// configure 386MAX
Configure:
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(CONFIGUREDLGBOX), hParent, ConfigureDlgProc);
	SetupYield(0);

	// Save original SYSTEM.INI, WIN.INI, CONFIG.SYS, and AUTOEXEC.BAT

	// copy everything to the QMAX directory
	MakePath( szDest, "config.sav", szMaxConfigSys );
	FileCopy( szMaxConfigSys, szConfigSys );

	MakePath( szDest, "autoexec.sav", szMaxAutoexec );
	FileCopy( szMaxAutoexec, szAutoexec );
    SetupYield(0);

	MakePath( szDest, "system.sav", szMaxSystemIni );
	FileCopy( szMaxSystemIni, szSystemIni );

	MakePath( szDest, "win.sav", szMaxWinIni );
	FileCopy( szMaxWinIni, szWinIni );
    SetupYield(0);

    if ( bWin95 ) {
	MakePath( szDest, "ios.sav", szMaxIOSIni );
	FileCopy( szMaxIOSIni, szIOSIni );
    }

	if (szMax[0]) {

		if (QueryFileExists( szMaxPro ) != 0) {
			MakePath( szDest, "386max.sav", szMaxMaxPro );
			FileCopy( szMaxMaxPro, szMaxPro );
		}

		if (QueryFileExists( szExtraDosPro )) {
			MakePath( szDest, "extrados.sav", szMaxExtraDosPro );
			FileCopy( szMaxExtraDosPro, szExtraDosPro );
		}
	}
    SetupYield(0);


	// make QMAX.INI
	// This must come before move GoAhead.drv
	if (bPrograms) {

	if( !bWin95 ) {
	    if (GetPrivateProfileString( szIniGaProgs, NULL, "", szBuf, sizeof(szBuf), szININame ) == 0) {
		WritePrivateProfileString( szIniGaProgs, "MGR30", "", szININame );
		WritePrivateProfileString( szIniGaProgs, "SQAROBOT", "", szININame );

	    }
		// set up the incompatable list...
	    if (GetPrivateProfileString( szIniGaIncompatable, NULL, "", szBuf, sizeof(szBuf), szININame ) == 0) {
		int i;
		char szT1[ 80 ];

		wsprintf( szT1, "%d", GAIC_COUNT );
		WritePrivateProfileString( szIniGaIncompatable, "count", szT1, szININame );
		for( i=0; i < GAIC_COUNT; i++ ) {
		    wsprintf( szT1, "driver%d", i+1 );
		    WritePrivateProfileString( szIniGaIncompatable, szT1, szGaInc[ i ], szININame );
		}
	    }
		// Force Ignore= to nothingness.
		// Note! this must come AFTER the above or the above won't work.
	    WritePrivateProfileString( szIniGaIncompatable, szIniGaIgnore, NULL, szININame );
	}
		SetupYield(0);

		if (GetPrivateProfileString( szIniMEFiles, NULL, NULLSTR, szBuf, sizeof(szBuf), szININame ) == 0) {
			WritePrivateProfileString( szIniMEFiles, szConfigSys, NULLSTR, szININame );
			WritePrivateProfileString( szIniMEFiles, szAutoexec, NULLSTR, szININame );
			WritePrivateProfileString( szIniMEFiles, szWinIni, NULLSTR, szININame );
			WritePrivateProfileString( szIniMEFiles, szSystemIni, NULLSTR, szININame );
			if (szMaxPro[0])
				WritePrivateProfileString( szIniMEFiles, szMaxPro, NULLSTR, szININame );
		}
		SetupYield(0);
	}

	// test for Go Ahead conflicts.
	// Do this while Go Ahead is still in the szDest directory, so we
	// are ensured of getting the newest version in LoadClear().
	// Win95 sets bStayBack = TRUE;
    if( !bStayBack ) {
	bStayBack = GALoadClearance( );
	SetupYield(0);
    }

	// move the goAhead driver.
    if ( bPrograms == 1 ) {
	int uError;

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	    // point to the  GoAhead driver
	MakePath( szDest, szDrvName, szTemp );

	if ( !bWin95 ) {
		// copy GoAhead.DRV to the Windows system directory
	    MakePath( szWindowsSystemDir, szDrvName, szBuf );

	    if( NeedBackup ( szBuf, szTemp ) ) {
		bGASaved = TRUE;
		if( BackupMAXDir( )) {
		    char szT2[ _MAX_PATH + 1 ];

		    MakePath( szBackupDir, szDrvName, szT2 );
		    FileCopy( szT2, szBuf );
		}
	    }

	    if( FileCopy( szBuf, szTemp ) ) {
		char lpSaved[ 258 ];
		char lpCopyFile[ 258 ];
		char lpCopyPath[ 258 ];

		MakeCopyDir( (LPSTR)szDest, (LPSTR)lpCopyPath, (LPSTR)lpCopyFile );
		MakePath( lpCopyPath, szDrvName, lpSaved );
		if (!FileCopy( lpSaved, szTemp )) {
		    AddToCopyBatch( (LPSTR)lpSaved, (LPSTR)szWindowsSystemDir, (LPSTR) lpCopyFile );
		    bHadToCopy = TRUE;
		}
	    }
	}
	    // remove it from \QMAX
	remove( szTemp );

	if ( bWin95 ) {
		// Since it won't be used...remove the .exe file also.
	    MakePath( szDest, FILENAMEXE, szTemp );
	    remove( szTemp );
	}

	SetupYield(0);
	SetErrorMode( uError );
    }

	// create the PREINST.BAT file
	// must come after moving GoAhead.
	CreatePreinst();

	// switch to MAX directory and work from there
	AnsiUpper( szDest );
	_chdrive( szDest[0] - 64 );
	_chdir( szDest );

	bModified = 1;

	hModeless = CreateDialog(ghInstance, MAKEINTRESOURCE(MODELESSDLGBOX), hParent, ModelessDlgProc);

	SetDlgItemText( hModeless, 100, szMsg_Strip );

    MakePath( szDest, szStripMgr, szSMDir );
	// make sure the stripmgr.out file does not exist.
    _unlink( szSMDir );

	// Invoke Stripmgr in standard or multi mode.
	if (szMultiSection[0])
		wsprintf(szBuf, "%s %c: /E%s /A%s %s", szStripPIF, szConfigSys[0], szSMDir, szMultiSection, pszStripExcept );
	else
		wsprintf(szBuf, "%s %c: /E%s %s", szStripPIF, szConfigSys[0], szSMDir, pszStripExcept );

	if ((ghChildInstance = (HINSTANCE)WinExec( szBuf, SW_HIDE )) <= 32)
		ghChildInstance = NULL;
	else {
		if (lpCallBackProc == 0L) {
			for (n = 0; (n < 100); n++) {
				SetupYield(0);
				Yield();
			}
		} else {
			// wait for Stripmgr to finish!
			while ( ( ghChildInstance != NULL ) &&
		  (( uRef=GetModuleUsage( ghChildInstance )) > 0 )) {
				SetupYield(0);
	    }
		}
	}
	DestroyWindow( hModeless );

    SetupYield(0);

	    // test for MCA machine.
    if ( DPMI_Is_MCA() ) {
		// get disk, make dir and copy ADF file there.
	if ((rc = DialogBox(ghInstance, MAKEINTRESOURCE(REFSRCDLGBOX), hParent, RefDirDlgProc )) == 0) {
	    if ( szADFSrc[0] && szADFDest[0] ){
		CopyADFFiles( "@????.adf" );
		CopyADFFiles( "P????.adf" );
		CopyADFFiles( "S????.adf" );
	    }
	}
    }

SetupGroup:
	pmCreateGroup( szProgmanGroup, NULLSTR );
	pmShowGroup( szProgmanGroup, 2 );
	if (pmShowGroup( szProgmanGroup, 1 ) == FALSE) {
		MessageBox(0, szMsg_Group, szMsg_InitTitle, MB_OK | MB_ICONSTOP);
		goto NoMAXGroup;
	}
	SetupYield(0);

	if (fRefresh == 0) {
		MakePath(szDest, "setup.exe /W", szTemp );
		pmDeleteItem( "Setup" );
		pmAddItem( szTemp, "Setup", NULLSTR, 0 );
		SetupYield(0);
	}

	if (bOnlineHelp) {
		MakePath(szDest, "maxhelp.hlp", szTemp );
		pmDeleteItem( szMsg_HelpIcon );
		pmAddItem( szTemp, szMsg_HelpIcon, NULLSTR, 0 );
	}

	// create QMAX.INI
	WritePrivateProfileString( szIniConfig, "Qualitas MAX Path", szDest, szININame );
	WritePrivateProfileString( szIniConfig, "Qualitas MAX Help", "maxhelp.hlp", szININame );

	if (fRefresh == 0) {
		WritePrivateProfileString( szIniReg, "Name", szName, szININame );
		WritePrivateProfileString( szIniReg, "Company", szCompany, szININame );
		WritePrivateProfileString( szIniReg, "S/N", szSerial, szININame );
	}
	SetupYield(0);

	// Build QMAX.INI was here before it moved above GALoadClearance.
    if ( !bPrograms && (fRefresh == 0)) {
		ShowWindow( hParent, SW_SHOW );
		fMaximize = fReboot = bUpdateFiles = 0;
		MessageBox( 0, szMsg_SetComp, szMsg_SetTitle, MB_OK );
		return;
	}

	MakePath(szDest, "Readme", szTemp );
	wsprintf( szBuf, "notepad.exe %s.", (LPSTR)szTemp );
	pmDeleteItem("README");
	pmAddItem( szBuf, "README", NULLSTR, 0 );

	SetupYield(0);
	MakePath(szDest, "toolbox.exe", szTemp );
	pmDeleteItem( "Toolbox" );
	pmAddItem( szTemp, "Toolbox", NULLSTR, 0 );

	SetupYield(0);
	MakePath(szDest, "maxedit.exe", szTemp );
	pmDeleteItem( "MAXedit" );
	pmAddItem( szTemp, "MAXedit", NULLSTR, 0 );

	SetupYield(0);
	MakePath(szDest, szMMName, szTemp );
	pmDeleteItem( szMAXmeter );
	pmAddItem( szTemp, szMAXmeter, NULLSTR, 0 );

    if ( !bWin95 ) {
	SetupYield(0);
	MakePath(szDest, "goahead.exe", szTemp );
	// kludge for Windows bug in icon positioning
	pmDeleteItem( szGoAhead );
	pmAddItem( szTemp, szGoAhead, NULLSTR, 0 );
	pmReplaceItem( szGoAhead );
	pmAddItem( szTemp, szGoAhead, NULLSTR, 1 );
    }

	SetupYield(0);
	MakePath(szDest, "winmaxim.exe", szTemp );
	pmDeleteItem( "Maximize" );
	pmAddItem( szTemp, "Maximize", NULLSTR, 0 );

	SetupYield(0);
	if (bWin95 == 0) {
		MakePath(szDest, "qpifedit.exe", szTemp );
		pmDeleteItem( "Qualitas PIF Editor" );
		pmAddItem( szTemp, "Qualitas PIF Editor", NULLSTR, 0 );
		SetupYield(0);
	}

	SetupYield(0);
	if (bWin95)
		MakePath(szDest, "dosm95f.pif", szTemp );
	else
		MakePath(szDest, "dosmaxf.pif", szTemp );
	MakePath(szDest, "dosmax.ico", szBuf );
	pmDeleteItem( szMsg_DMFull );
	pmAddItem( szTemp, szMsg_DMFull, szBuf, 0 );

	if (bWin95)
		MakePath(szDest, "dosm95w.pif", szTemp );
	else
		MakePath(szDest, "dosmaxw.pif", szTemp );
	MakePath(szDest, "dosmax.ico", szBuf );
	pmDeleteItem( szMsg_DMWind );
	pmAddItem( szTemp, szMsg_DMWind, szBuf, 0 );

	if (bWin95) {
		// add items to registry
		MakePath( szDest, "rdosmax.exe", szTemp );
		wsprintf( szBuf, "%s %s", szTemp, szDest );
		WinExec(szBuf, SW_HIDE);
	}
NoMAXGroup:
	SetupYield(0);

	// update 386MAX.PRO

	// moved from CheckForMax because that altered the file before
	// copying it to .sav

	// adjust profile for Bios Compression if needed.
    if( bBCFsys ) {
	if (szMaxPro[0]) {
		// add autobcf
	    wsprintf( szBuf, MsgAutoBcf, BIOSCRC );
	    ModifyMaxPro( szBuf, 0 );

		// remove any USE= statements above 0xE000.
	    DelMaxProRange( (LPSTR)(LPSTR)szMultiSection, (LPSTR)"USE", (DWORD)0xE000 );
	}

    } else {
	// remove Bluemax-only args
	if (szMaxPro[0]) {
	    ModifyMaxPro( AUTOBCF, 1 );
	    ModifyMaxPro( "bcf", 1 );
	    // Why do we need to remove FRAME= ?  Check INSTALL...
	    ModifyMaxPro( "frame", 1 );
	}
    }

	// add Swapfile info
	if (freeKB( szDest ) > 10000L) {
		MakePath( szDest, "386MAX.SWP", szTemp );
		wsprintf( szBuf, "SWAPFILE=%s /S=8192   ; SETUP", szTemp );
		ModifyMaxPro( szBuf, 0 );
	}

	// remove NOFLEX
	ModifyMaxPro( "NOFLEX", 1 );

	// add MDA info
	if (bMDA) {
		ModifyMaxPro( szUSEMDA, 0 );
		ModifyMaxPro( szNOFLEX, 0 );
	} else {
		// strip the line
		ModifyMaxPro( "USE=B000-B800", 1 );
	}

	// add EMS info
	if (bEMS) {
		// strip "EMS=0"
		ModifyMaxPro( "EMS=0", 1 );
		// strip NOFRAME
		ModifyMaxPro( "NOFRAME", 1 );
		// Add NOFLEX
		ModifyMaxPro( szNOFLEX, 0 );
	} else {
		// strip "EMS=" anything
		ModifyMaxPro( "EMS=", 1 );
		// strip NOFRAME
		ModifyMaxPro( "NOFRAME", 1 );
		// strip FRAME=
		ModifyMaxPro( "FRAME=", 1 );
	// add EMS=0
		ModifyMaxPro( szEMS, 0 );
    }

	if ((LOBYTE(LOWORD(dwVersion)) > 3) || (HIBYTE(LOWORD(dwVersion)) > 0))
		ModifyMaxPro( szNOWIN30, 0 );
	SetupYield(0);

	// don't call MultiCfgEdit without szSMDir ( the stripmgr file ).
    if ( QueryFileExists( szSMDir ) != 0) {
	FILEDELTA *fd;
	char szT2[ _MAX_PATH + 1 ];

	    // must point to destination exe because,
	    // the source disk has probably been changed.
	MakePath( szDest, "setup.exe", szT2);
	    // do the multiconfig mods. Changed filename returned in szConfigTemp.
	MultiCfgEdit( &bMChanged, (LPSTR)szSetupName, (LPSTR)szConfigSys,
		     (LPSTR)szSMDir, (LPSTR)szMultiSection, (LPSTR)szDest,
		     (LPSTR)szConfigTemp );
	SetupYield(0);

	    // Make any necessary changes to AUTOEXEC.BAT
	edit_batfiles( );

		// get the temporary filename.
		// NOTE! filedelta array is not valid before the
		// call to MultiCfgEdit().
	if(( fd=get_filedelta( szAutoexec )) != NULL ){
	    if(( fd->pszOutput ) != NULL ) {
		_fstrcpy( (LPSTR)szAutoTemp, (LPSTR)(fd->pszOutput) );
	    }
	}

	SetupYield(0);
	    // lose the stripmgr out file.
	unlink( szSMDir );
    }

	// remove QMT from AUTOEXEC.ADD
	if (ModifyAutoexec( "qmt.exe", 1 ) == 0) {
		if (ModifyAutoexec( "qmt", 1 ) == 0) {
			if (ModifyAutoexec( "qutil.bat", 1 ) == 0)
				ModifyAutoexec( "qutil", 1 );
		}
	}

	if (bQMT) {
		MakePath( szDest, "QMT.EXE", szTemp );
		wsprintf( szBuf, "%s quick=1", szTemp );
		ModifyAutoexec( szBuf, 0 );
		SetupYield(0);
	}

	// Add lines to SYSTEM.INI
	WritePrivateProfileString( "386enh", "VCPIWarning", "FALSE", szSystemIni );
	WritePrivateProfileString( "386enh", "SystemROMBreakPoint", "FALSE", szSystemIni );
	WritePrivateProfileString( "Qualitas", "DOSMAXDefault", "OFF", szSystemIni );
	SetupYield(0);

    if ( !bStayBack ) {
	    // Add Go Ahead to SYSTEM.INI
	if ( bGoAhead ) {
	    if ((hDriver = OpenDriver(szDrvName, NULL, NULL)) != NULL) {
		SendDriverMessage(hDriver, DRV_INSTALL, NULL, NULL);
		CloseDriver(hDriver, NULL, NULL);
	    }

	} else {
	    if ((hDriver = OpenDriver(szDrvName, NULL, NULL)) != NULL) {
		SendDriverMessage(hDriver, DRV_REMOVE, NULL, NULL);
		CloseDriver(hDriver, NULL, NULL);
	    }
	}
    }

	// Add QPOPUP.EXE to WIN.INI
	szBuf[0] = szTemp[0] = '\0';
	GetProfileString( "windows", "load", NULLSTR, szBuf, 511 );

	for (n = 0; ; n++) {

		if ((arg = ntharg( szBuf, n )) == NULL)
			break;

		// strip any existing QPOPUP
		if (FindString( arg, "qpopup.exe" ) < 0) {
			if (szTemp[0])
				lstrcat(szTemp, " ");
			lstrcat(szTemp, arg);
		}
	}

	MakePath( szDest, "QPOPUP.EXE", szBuf );
	if (szTemp[0])
		lstrcat(szTemp, " ");
	lstrcat(szTemp, szBuf);
	WriteProfileString( "windows", "load", szTemp );
	SetupYield(0);

	// modify IOS.INI
    if( bWin95 ) {
	ModifyIOSIni( szSafeList, szLoadcom );
	ModifyIOSIni( szSafeList, szLoadsys );
	ModifyIOSIni( szSafeList, szDisksys );
    }

	// display modified files
	rc = DialogBox(ghInstance, MAKEINTRESOURCE(FILESDLGBOX), hParent, FilesDlgProc);
	SetupYield(0);
	if (rc == 2)
		goto Configure;

	// copy changed files to MAX directory and restore originals
	if (bUpdateFiles == 0) {

		MakePath( szDest, "win.add", szTemp );
		FileCopy( szTemp, szWinIni );

		MakePath( szDest, "system.add", szTemp );
		FileCopy( szTemp, szSystemIni );

	if (bWin95 ) {
	    MakePath( szDest, "ios.add", szTemp );
	    FileCopy( szTemp, szIOSIni );
	}

		MakePath( szDest, "profile.add", szTemp );
		FileCopy( szTemp, szMaxPro );

		// restore original profile files
		MakePath( szDest, fname_part(szMaxPro), szTemp );
		FileCopy( szTemp, szMaxMaxPro );

		// restore original SYSTEM.INI and WIN.INI files
		FileCopy( szSystemIni, szMaxSystemIni );
		FileCopy( szWinIni, szMaxWinIni );

	if (bWin95 ) {
	    FileCopy( szIOSIni, szMaxIOSIni );
	}

	} else {

	if( bMChanged ) {
		// the original is already safe.
	    if( !FileCopy( szConfigSys, szConfigTemp ) ){
		_unlink( szConfigTemp );
	    }
	}

	if( !FileCopy( szAutoexec, szAutoTemp ) ){
	    _unlink( szAutoTemp );
	}

		if (bStartUp95) {
	    char szT2[_MAX_PATH +1];
			// they've moved their StartUp group out of the START menu!
	    wsprintf( szT2, "desktop\\%s\\maxmeter.lnk", szStartupGroup );
			MakePath( szWindowsDir, szT2, szTemp );
			remove( szTemp );

	    wsprintf( szT2, "desktop\\%s\\%s", szStartupGroup,szMMName );
			MakePath( szWindowsDir, szT2, szTemp );
			remove( szTemp );

			MakePath(szDest, szMMName, szTemp );
	    wsprintf( szT2, "desktop\\%s\\%s", szStartupGroup, szMMName );
			MakePath( szWindowsDir, szT2, szBuf );

			if (bMaxMeter)
			    FileCopy( szBuf, szTemp );

		} else {

			pmCreateGroup( szStartupGroup, NULLSTR );
			pmShowGroup( szStartupGroup, 2 );
			pmShowGroup( szStartupGroup, 1 );
			SetupYield(0);
			MakePath(szDest, szMMName, szTemp );
			pmDeleteItem( szMAXmeter );
			if (bMaxMeter)
			    pmAddItem( szTemp, szMAXmeter, NULLSTR, 0 );

			SetupYield(0);

	    if ( !bStayBack ) {
		MakePath(szDest, "goahead.exe", szTemp );
		pmDeleteItem( szGoAhead );
		if (bGoAhead) {
		    pmAddItem( szTemp, szGoAhead, NULLSTR, 0 );
		    pmReplaceItem( szGoAhead );
		    pmAddItem( szTemp, szGoAhead, NULLSTR, 1 );
		}
	    }

			pmShowGroup( szStartupGroup, SW_SHOWMINIMIZED );
		}
	}

FinalDlgs:
	// display "success" dialog & exit
	SetupYield( 0 );

    if( bHadToCopy ) {
	DialogBox( ghInstance, MAKEINTRESOURCE(EXITRESTARTDLGBOX), hParent, ExitRestartDlgProc);
    } else {
	if ( bUpdateFiles ) {
	    DialogBox( ghInstance, MAKEINTRESOURCE(EXITSUCCESSDLGBOX), hParent, ExitSuccessDlgProc);
	    if ((fMaximize == 0) && (fReboot)) {
		DialogBox( ghInstance, MAKEINTRESOURCE(EXITREBOOTDLGBOX), hParent, ExitRebootDlgProc);
	    } else {
		    // only restart if reboot not necessary and Max is already loaded.
		if((fMaximize == 0) && bMaxFound ) {
		    RestartMaxUtils( szDest );
		}
	    }
	} else {
		// need to copy .add files.
	    DialogBox( ghInstance, MAKEINTRESOURCE(EXITNEWDLGBOX), hParent, ExitNewDlgProc);
	}
    }
}

// "Splash" dialog box
long  CALLBACK __export SplashWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	static HBITMAP hBitmap;
	HDC hdcMem;
	BITMAP bm;
	PAINTSTRUCT ps;

	switch (uMsg) {
	case WM_CREATE:
		hBitmap = LoadBitmap( ghInstance, MAKEINTRESOURCE(SPLASH_BITMAP) );
		SetTimer( hWnd, 1, (unsigned int)3000, 0L );
		GetObject( hBitmap, sizeof(BITMAP), (LPSTR)&bm );
		SetWindowPos( hWnd, 0, 0, 0, bm.bmWidth, bm.bmHeight, SWP_NOZORDER | SWP_NOMOVE );
		break;

	case WM_SIZE:
		CenterWindow( hWnd );
		break;

	case WM_PAINT:

		BeginPaint( hWnd, &ps );

		// draw the bitmap
		hdcMem = CreateCompatibleDC(ps.hdc);
		SelectObject(hdcMem, hBitmap);
		SetMapMode( hdcMem, GetMapMode( ps.hdc ));
		GetObject( hBitmap, sizeof(BITMAP), (LPSTR)&bm );
		BitBlt(ps.hdc, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY );
		DeleteDC( hdcMem );

		EndPaint( hWnd, &ps );
		break;

	case WM_TIMER:
		KillTimer( hWnd, 1 );
		DestroyWindow( hWnd );
		hSplash = NULL;
		break;

	default:
	    return (DefWindowProc(hWnd, uMsg, wParam, lParam));
	}

	return FALSE;
}


// General purpose modeless dialog
BOOL CALLBACK __export ModelessDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		return TRUE;
	}

	return FALSE;
}


// "Welcome to Qualitas MAX Setup" dialog box
BOOL CALLBACK __export WelcomeDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_BACK:
			EndDialog( hDlg, 2 );
			return TRUE;

		case IDC_CONTINUE:
			EndDialog( hDlg, 0 );
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hParent, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			SetFocus( hDlg );
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((LPSTR)szHKEY_Welcome ));
			break;
		}
	}

	return FALSE;
}


// "Register MAX" dialog box
BOOL CALLBACK __export RegisterDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);

		// get name & company from QMAX.INI
		if (szName[0] == '\0') {
			GetPrivateProfileString( "Registration", "Name", szName, szName, 48, szININame );
			GetPrivateProfileString( "Registration", "Company", szCompany, szCompany, 48, szININame );
			GetPrivateProfileString( "Registration", "S/N", szSerial, szSerial, 24, szININame );
		}

		SendDlgItemMessage(hDlg, IDC_NAME, EM_LIMITTEXT, 48, 0L);
		SendDlgItemMessage(hDlg, IDC_COMPANY, EM_LIMITTEXT, 48, 0L);
		SendDlgItemMessage(hDlg, IDC_SERIAL, EM_LIMITTEXT, 24, 0L);

		SetDlgItemText( hDlg, IDC_NAME, szName );
		SetDlgItemText( hDlg, IDC_COMPANY, szCompany );
		SetDlgItemText( hDlg, IDC_SERIAL, szSerial );
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_BACK:
			EndDialog(hDlg, 2);
			return TRUE;

		case IDC_CONTINUE:

			// save name, company, and serial number
			szName[0] = '\0';
			GetDlgItemText(hDlg, IDC_NAME, szName, 79);
			if ( szName[0] == '\0' ) {
				MessageBox( hDlg, szMsg_Name, szMsg_Reg, MB_OK | MB_ICONSTOP );
				SetFocus(GetDlgItem(hDlg, IDC_NAME));
				break;
			}

			szCompany[0] = '\0';
			GetDlgItemText(hDlg, IDC_COMPANY, szCompany, 79);

			szSerial[0] = '\0';
			GetDlgItemText(hDlg, IDC_SERIAL, szSerial, 31);
			if ( szSerial[0] == '\0' ) {
				MessageBox( hDlg, szMsg_Serial, szMsg_Reg, MB_OK | MB_ICONSTOP );
				SetFocus(GetDlgItem(hDlg, IDC_SERIAL));
				break;
			}

			// verify serial number
			if ( decode_serialno ( (unsigned char *) szSerial ) == NULL ) {
				MessageBox( hDlg, szMsg_InvSer, szMsg_Reg, MB_OK | MB_ICONSTOP );
				SetFocus(GetDlgItem(hDlg, IDC_SERIAL));
				break;
			}

			EndDialog(hDlg, 0);
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hParent, AskQuitDlgProc) == 1) {
				EndDialog(hDlg, 1);
				longjmp(quit_env, -1);
			}
			SetFocus(hDlg);
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((LPSTR) szHKEY_RegInf ));
			break;
		}
	}

	return FALSE;
}


// Confirm registration info
BOOL CALLBACK __export ConfirmDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		SetDlgItemText( hDlg, 100, szName );
		SetDlgItemText( hDlg, 101, szCompany );
		SetDlgItemText( hDlg, 102, szSerial );
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_BACK:
			EndDialog( hDlg, 2 );
			return TRUE;

		case IDC_CONTINUE:
			EndDialog( hDlg, 0 );
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hParent, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			SetFocus( hDlg );
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)(( LPSTR ) szHKEY_RegConf ));
			break;
		}
	}

	return FALSE;
}


// "Get original MAX directory" dialog box
BOOL CALLBACK __export UpdateDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		SetFocus( GetDlgItem( hDlg, IDC_PATH ) );
		return 0;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			GetDlgItemText(hDlg, IDC_PATH, szMax, 127);
			EndDialog( hDlg, 0 );
			break;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hDlg, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			break;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_PARTIALKEY, (DWORD)(( LPSTR ) szHKEY_Up ));
			break;
		}
	}

	return FALSE;
}


BOOL CALLBACK __export UpdateErrorDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		SetFocus( hDlg );
		return 0;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			EndDialog( hDlg, 0 );
			break;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hDlg, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			break;

		case IDC_BACK:
			EndDialog( hDlg, 2 );
			return TRUE;
		}
	}

	return FALSE;
}


// Get Multiconfig section dialog box
BOOL CALLBACK __export MultiDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	register char *arg;
	char szBuf[256], szMSection[256], szCSection[128];
	int n;

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);

		// load section descriptions into combo box
		for (n = 0, arg = szSections; (*arg != '\0'); n++) {

			szCSection[0] = szBuf[0] = '\0';
			sscanf( arg, "%[^ ,\n]%*[ ,]%255[^\n]", szCSection, szBuf );
			while (*arg++ != '\n')
				;

			if (szBuf[0] == '\0')
				lstrcpy(szBuf, szCSection);
			SendDlgItemMessage(hDlg, IDC_MULTI, CB_ADDSTRING, 0, (LONG)(char *)szBuf);

			// check for current section and set edit control
			if (lstrcmpi( szCSection, szCurrentSection ) == 0)
				SendDlgItemMessage( hDlg, IDC_MULTI, CB_SETCURSEL, n, 0L);
		}

		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			GetDlgItemText( hDlg, IDC_MULTI, szMSection, 255 );

			for (arg = szSections; ; ) {

				szMultiSection[0] = szMultiDescription[0] = '\0';
				if (*arg == '\0')
					break;
				sscanf( arg, "%[^ ,\n]%*[ ,]%255[^\n]", szMultiSection, szMultiDescription );
				while (*arg++ != '\n')
					;

				if (szMultiDescription[0] == '\0')
					lstrcpy( szMultiDescription, szMultiSection );

				if (lstrcmpi( szMSection, szMultiDescription ) == 0)
					break;
			}

			if ( szMultiSection[0] == '\0' ) {
				MessageBox( hDlg, szMsg_MustMult, szMsg_Multi, MB_OK | MB_ICONSTOP );
				SetFocus(GetDlgItem(hDlg, IDC_MULTI));
				break;
			}

			EndDialog(hDlg, 0);
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE( ASKQUITDLGBOX ), hParent, AskQuitDlgProc) == 1) {
				EndDialog(hDlg, 1);
				longjmp(quit_env, -1);
			}
			SetFocus(hDlg);
			return TRUE;

		case IDC_BACK:
			EndDialog(hDlg, 2);
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)(( LPSTR ) szHKEY_Multi ));
			break;
		}
	}

	return FALSE;
}


// "Select Directory" dialog box
BOOL CALLBACK __export DirectoryDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	char szBuffer[256];
	unsigned long uKB;
	struct find_t dir;

	switch (uMsg) {
	case WM_INITDIALOG:

		CenterWindow( hDlg );

		// if MAX already in CONFIG.SYS, force installation in that
		//   directory!
		if (szMax[0]) {
			ShowWindow( GetDlgItem( hDlg, IDC_PATH), SW_HIDE);
			SetDlgItemText( hDlg, 666, szMax );
			lstrcpy( szDest, szMax );
		} else {
			ShowWindow( GetDlgItem( hDlg, 666), SW_HIDE);
			SendDlgItemMessage( hDlg, IDC_PATH, EM_LIMITTEXT, _MAX_PATH, 0L );
			SetDlgItemText( hDlg, IDC_PATH, szDest );
		}

		CheckDlgButton( hDlg, IDC_PROGRAMS, bPrograms );
		CheckDlgButton( hDlg, IDC_ONLINEHELP, bOnlineHelp );
		CheckDlgButton( hDlg, IDC_DOSREADER, bDosReader );

		uKB = freeKB( szDest );
		wsprintf(szBuffer, "%lu KB", uKB);
		SetDlgItemText( hDlg, IDC_DISKFREE, szBuffer );

		uKB = 0L;
		if (bPrograms)
			uKB += PROGRAM_SIZE;
		if (bOnlineHelp)
			uKB += ONLINEHELP_SIZE;
		if (bDosReader)
			uKB += DOSREADER_SIZE;
		wsprintf(szBuffer, "%lu KB", uKB );
		SetDlgItemText( hDlg, IDC_DISKNEEDED, szBuffer );

		// check for sufficient room on destination drive(s)
		wsprintf( szBuffer, "%.2s", szDest );
		SetDlgItemText( hDlg, IDC_IDISK, szBuffer );

		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_PATH:
		    if ((HIWORD(lParam) == EN_CHANGE) || (HIWORD(lParam) == EN_KILLFOCUS)) {
			szDest[0] = '\0';
			GetDlgItemText(hDlg, IDC_PATH, szDest, 127 );
			if (szDest[1] != ':')
				break;

			uKB = freeKB( szDest );
			wsprintf( szBuffer, "%.2s", szDest );
			SetDlgItemText( hDlg, IDC_IDISK, szBuffer );
			wsprintf(szBuffer, "%lu KB", uKB);
			SetDlgItemText( hDlg, IDC_DISKFREE, szBuffer );

			goto DisplayKB;
		    }
		    break;

		case IDC_PROGRAMS:
			bPrograms = IsDlgButtonChecked(hDlg, IDC_PROGRAMS);
			goto DisplayKB;

		case IDC_ONLINEHELP:
			bOnlineHelp = IsDlgButtonChecked(hDlg, IDC_ONLINEHELP);
			goto DisplayKB;

		case IDC_DOSREADER:
			bDosReader = IsDlgButtonChecked(hDlg, IDC_DOSREADER);
DisplayKB:
			uKB = 0L;
			if (bPrograms)
				uKB += PROGRAM_SIZE;
			if (bOnlineHelp)
				uKB += ONLINEHELP_SIZE;
			if (bDosReader)
				uKB += DOSREADER_SIZE;
			wsprintf(szBuffer, "%lu KB", uKB );
			SetDlgItemText( hDlg, IDC_DISKNEEDED, szBuffer );
			break;

		case IDC_BACK:
			EndDialog(hDlg, 2);
			return TRUE;

		case IDC_CONTINUE:

			if ((fRefresh == 0) && (bPrograms == 0) && (bOnlineHelp == 0) && (bDosReader == 0)) {
				MessageBox(hDlg, szMsg_MustSel, szMsg_NoFile, MB_OK | MB_ICONSTOP);
				break;
			}

			// create directory; check for existence
			if (szMax[0])
				lstrcpy( szDest, szMax );
			else {
				szDest[0] = '\0';
				GetDlgItemText(hDlg, IDC_PATH, szDest, 127 );
				if ( szDest[0] == '\0' ) {
					MessageBox( hDlg, szMsg_MustDir, szMsg_Dir, MB_OK | MB_ICONSTOP );
					SetFocus(GetDlgItem(hDlg, IDC_PATH));
					break;
				}
			}

			strip_trailing( szDest + 3, "\\/" );

			if (mkfname( szDest ) == NULL) {
				MessageBox( hDlg, szMsg_NoDrive, szMsg_Dir, MB_OK | MB_ICONSTOP );
				ShowWindow( GetDlgItem( hDlg, 666), SW_HIDE);
				SendDlgItemMessage( hDlg, IDC_PATH, EM_LIMITTEXT, _MAX_PATH, 0L );
				SetDlgItemText( hDlg, IDC_PATH, ((szMax[0]) ? szMax : szDest ));
				SetFocus(GetDlgItem(hDlg, IDC_PATH));
				break;
			}

			if (QueryFileExists( szDest )) {
				wsprintf(szBuffer, "%s \"%s\" - %s", szMsg_NDir, szMsg_Xist, szDest );
				MessageBox( hDlg, szBuffer, szMsg_Dir, MB_OK | MB_ICONSTOP );
				break;
			}

			// check for sufficient room on destination drive
			uKB = 0;
			if (bPrograms)
				uKB += PROGRAM_SIZE;
			if (bOnlineHelp)
				uKB += ONLINEHELP_SIZE;
			if (bDosReader)
				uKB += DOSREADER_SIZE;

			if ((szMax[0] == '\0') && (freeKB( szDest ) < uKB)) {
				MessageBox( hDlg, szMsg_NS, szMsg_NoSpc, MB_OK | MB_ICONSTOP );
				break;
			}

			uKB = freeKB( szDest );
			wsprintf( szBuffer, "%.2s", szDest );
			SetDlgItemText( hDlg, IDC_IDISK, szBuffer );

			wsprintf(szBuffer, "%lu KB", uKB);
			SetDlgItemText( hDlg, IDC_DISKFREE, szBuffer );

			if ((szDest[3] != '\0') && (_dos_findfirst( szDest, 0x17, &dir ) != 0)) {

				wsprintf( szBuffer, "%s \"%s\" %s", szMsg_TheDir, szMsg_NoXst, szDest );
				if (MessageBox( hDlg, szBuffer, szMsg_Dir, MB_YESNO | MB_ICONSTOP ) != IDYES) {
					SetFocus(GetDlgItem(hDlg, IDC_PATH));
					break;
				}

				if ((_mkdir( szDest ) == -1) && (_doserrno != 5)) {
					wsprintf( szBuffer,"%s \"%s\".", szMsg_NDir2, szDest );
					MessageBox( hDlg, szBuffer, szMsg_Dir, MB_OK | MB_ICONSTOP );
					break;
				}
			}

			EndDialog( hDlg, 0 );
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hParent, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			SetFocus( hDlg );
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)(( LPSTR ) szHKEY_FLoc ));
			break;
		}
	}

	return FALSE;
}


typedef struct {
	char *pszFilename;
	int nPercent;
} MAXFILES;


BOOL CALLBACK __export ExtractDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	extern int do_extract( HWND, char * );
	extern int nPercent;

	static MAXFILES MaxFiles[7] = {
		"setup.exe", 8,
		"setup.hlp", 2,
		"setupdos.hlp", 1,
		"setupdos.ovl", 12,
		"qlogo.ovl", 1,
		"setupdos.cfg", 1,
		NULL, 0
	};
	register int i;
	char szSource[128], szTarget[128], szBuf[256];

	switch (uMsg) {
	case WM_INITDIALOG:

		CenterWindow( hDlg );

		SetWindowText( hDlg, szMsg_ExtTitle );
		SetTimer( hDlg, 1, (unsigned int)100, 0L );
		return TRUE;

	case WM_TIMER:
		KillTimer( hDlg, 1 );

		// extract the files
		HideCaret( NULL );

		DrawMeter( GetDlgItem( hDlg, IDC_METER), 0);
		lstrcpy( szSource, path_part( szDest ));
		if ((fRefresh == 0) && (lstrcmpi( szSource, path_part( szSetupName ) ) != 0)) {

		    // brand SETUPDOS.OVL on the floppy!
		    MakePath( path_part(szSetupName), "setupdos.ovl", szBuf );
		    BrandFile( szBuf );

		    fCopiedSetup = 1;
		    for (i = 0; (MaxFiles[i].pszFilename != NULL); i++) {

		MakePath( path_part(szSetupName), MaxFiles[i].pszFilename, szSource );
		MakePath( szDest, MaxFiles[i].pszFilename, szTarget );

		// display filename in dialog
		wsprintf( szBuf, "%s %s", szMsg_Copy, AnsiUpper(szTarget) );
		SetDlgItemText( hDlg, 668, szBuf );
		SetupYield( 0 );

		if( NeedBackup ( szTarget, szSource ) ) {
		    BackupFile ( MaxFiles[i].pszFilename );
		}
		FileCopy( szTarget, szSource );

		nPercent += MaxFiles[i].nPercent;
		DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );
		SetupYield( 0 );
		    }
		}

		if ((bPrograms) || (bOnlineHelp) || (bDosReader))
			do_extract( hDlg, szDest );
		ShowCaret( NULL );
		EndDialog( hDlg, 1 );
	}

	return 0L;
}


// "Configure MAX" dialog box
BOOL CALLBACK __export ConfigureDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	char szBuf[256];

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);

		// check to see if they've removed their StartUp directory
		//   and put it on the desktop!
		if (bWin95) {
	    char szT2[ _MAX_PATH + 1 ];
	    wsprintf( szT2, "desktop\\%s", szStartupGroup );
			MakePath( szWindowsDir, szT2, szBuf );
			if (QueryFileExists( szBuf ))
				bStartUp95 = 1;
		}

	    // prevent GoAhead in Win95.
		CheckDlgButton( hDlg, IDC_GOAHEAD, (bWin95) ? 0 : bGoAhead );
		EnableWindow( GetDlgItem( hDlg, IDC_GOAHEAD ),	!bWin95 );

		CheckDlgButton( hDlg, IDC_MAXMETER, bMaxMeter );

		bQMT = (ParsePro(szAutoexec, "qmt") != NULL);
		CheckDlgButton( hDlg, IDC_QMT, bQMT );

		// if 386MAX.PRO doesn't exist, set MDA & EMS defaults
		if (QueryFileExists( szMaxPro ) == 0) {
			bMDA = 1;
			bEMS = 0;
		} else {
			// check for existing 386MAX.PRO
			bMDA = (ParsePro( szMaxPro, "use=b000" ) != NULL);
			// if using EMS already, check the control
			bEMS = (ParsePro( szMaxPro, "EMS=0" ) == NULL);
		}

		CheckDlgButton( hDlg, IDC_MDA, bMDA );
		CheckDlgButton( hDlg, IDC_EMS, bEMS );
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:

			bQMT = IsDlgButtonChecked(hDlg, IDC_QMT);
			bMDA = IsDlgButtonChecked(hDlg, IDC_MDA);
			bMaxMeter = IsDlgButtonChecked(hDlg, IDC_MAXMETER);
			bGoAhead = IsDlgButtonChecked(hDlg, IDC_GOAHEAD);
			bEMS = IsDlgButtonChecked(hDlg, IDC_EMS);

	    if( !bGoAhead ) {
		bStayBack = TRUE;
	    }

			EndDialog(hDlg, 0);
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE( ASKQUITDLGBOX ), hParent, AskQuitDlgProc) == 1) {
				EndDialog(hDlg, 1);
				longjmp(quit_env, -1);
			}
			SetFocus(hDlg);
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((LPSTR) szHKEY_Config ));
			break;
		}
	}

	return FALSE;
}

// Display modified files dialog box
BOOL CALLBACK __export FilesDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	char szBuf[256];

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);

		hModeless = CreateDialog(ghInstance, MAKEINTRESOURCE(MODELESSDLGBOX), hParent, ModelessDlgProc);

		SetDlgItemText( hModeless, 100, szMsg_ModCfg );

		MakePath( szDest, "config.dif", szBuf );
		if (Difference( szConfigTemp, szConfigSys, szBuf ) > 0)
			SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szConfigSys);

		MakePath( szDest, "autoexec.dif", szBuf );
		if (Difference( szAutoTemp, szAutoexec, szBuf ) > 0)
			SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szAutoexec);

		MakePath( szDest, "system.dif", szBuf );
		if (Difference( szSystemIni, szMaxSystemIni, szBuf ) > 0)
			SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szSystemIni);

		MakePath( szDest, "win.dif", szBuf );
		if (Difference( szWinIni, szMaxWinIni, szBuf ) > 0)
			SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szWinIni);

		if (bMaxProModified) {
			MakePath( szDest, "386max.dif", szBuf );
			if (Difference( szMaxPro, szMaxMaxPro, szBuf ) > 0) {
				SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szMaxPro);

	    }
	    else {
		if ( bMaxProModified & 0x10 ) {
		    SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szMaxPro);
		}
	    }
		}

	if ( bWin95 ) {
	    if ( bIOSModified ) {
		MakePath( szDest, "IOS.dif", szBuf );
		if (Difference( szIOSIni, szMaxIOSIni, szBuf ) > 0)
		    SendDlgItemMessage(hDlg, IDC_FILESLB, LB_ADDSTRING, 0, (LONG)(LPSTR)szIOSIni);
	    }
	}

		DestroyWindow( hModeless );

		// make sure we've modified something!
		szBuf[0] = '\0';
		SendDlgItemMessage(hDlg, IDC_FILESLB, LB_GETTEXT, 0, (LONG)(LPSTR)szBuf);
		if (szBuf[0] == '\0') {
			EndDialog(hDlg, 1);
			return TRUE;
		}

		CheckDlgButton( hDlg, IDC_UPDATEFILES, 1 );

		// Set cursor and selection to first item in list box
		SendDlgItemMessage(hDlg, IDC_FILESLB, LB_SETCURSEL, 0, 0L);
		return TRUE;

	case WM_COMMAND:

		if ((HIWORD(lParam) == LBN_DBLCLK) || ((GetFocus() == GetDlgItem(hDlg, IDC_FILESLB)) && (LOWORD(wParam) == IDC_CONTINUE))) {
			SendDlgItemMessage(hDlg, IDC_FILESLB, LB_GETTEXT, (WORD)SendDlgItemMessage(hDlg, IDC_FILESLB,  LB_GETCURSEL, 0, 0L), (LONG)(LPSTR)szBuf);
			pszShowFile = szBuf;
			DialogBox(ghInstance, MAKEINTRESOURCE(SHOWDLGBOX), hParent, ShowDlgProc);
			SetFocus(GetDlgItem(hDlg,IDC_CONTINUE));
			return TRUE;
		}

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			// save radio button state
			bUpdateFiles = IsDlgButtonChecked(hDlg, IDC_UPDATEFILES);
			EndDialog(hDlg, 0);
			return TRUE;

		case IDC_BACK:
			EndDialog(hDlg, 2);
			return TRUE;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE( ASKQUITDLGBOX ), hParent, AskQuitDlgProc) == 1) {
				EndDialog(hDlg, 1);
				longjmp(quit_env, -1);
			}
			SetFocus( hDlg );
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)( (LPSTR)szHKEY_FMod ));
			break;
		}
	}

	return FALSE;
}


// show modified files dialog box
BOOL CALLBACK __export ShowDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	char *ptr, szBuf[128];
	HFILE fh;

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		SetWindowText( hDlg, pszShowFile );

		szBuf[0] = '\0';
		if (FindString( pszShowFile, "config.sys") >= 0)
			MakePath(szDest, "config.dif", szBuf);
		else if (FindString( pszShowFile, "autoexec.bat") >= 0)
			MakePath(szDest, "autoexec.dif", szBuf);
		else if (FindString( pszShowFile, "win.ini") >= 0)
			MakePath(szDest, "win.dif", szBuf);
		else if (FindString( pszShowFile, "system.ini") >= 0)
			MakePath(szDest, "system.dif", szBuf);
		else if (FindString( pszShowFile, ".pro") >= 0)
	    if ( bMaxProModified & 0x10 )
		MakePath(szDest, "386max.pro", szBuf);
	    else
		MakePath(szDest, "386max.dif", szBuf);
		else if (FindString( pszShowFile, "IOS.INI") >= 0)
			MakePath(szDest, "IOS.dif", szBuf);
		pszShowFile = szBuf;

		SendDlgItemMessage(hDlg, IDC_DIF_FILE, EM_SETTABSTOPS, 0, 0L);
		if ((fh = _lopen( pszShowFile, READ)) != HFILE_ERROR) {
	    unsigned int uSize;
	    unsigned long lSize;

	    if ( (lSize = _llseek( fh, 0L, 2 )) != HFILE_ERROR ) {
		if ( lSize > 64000 )
		    uSize = 64000;
		else
		    uSize = ( unsigned int ) lSize;
	    }
	    _llseek( fh, 0L, 0L );

			ptr = AllocMem( &uSize );
			_lread( fh, ptr, uSize );

			SendDlgItemMessage( hDlg, IDC_DIF_FILE, WM_SETTEXT, 0, (LONG)(LPSTR)ptr );

			FreeMem( ptr );
			_lclose( fh );
		}
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDOK:
			EndDialog(hDlg, 0);
			return TRUE;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)( (LPSTR) szHKEY_FMod ));
		}
	}

	return FALSE;
}


// Ask if you _really_ want to quit
BOOL CALLBACK __export AskQuitDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	char szTemp[256];

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			EndDialog( hDlg, 0 );
			break;

		case IDC_EXIT:
			EndDialog( hDlg, 1 );

			// if no entries, delete Qualitas group
			if (pmQueryGroup( szProgmanGroup, "*" ) == 0)
				pmDeleteGroup( szProgmanGroup );

			// restore original files
			if ((bModified) && (szMaxConfigSys[0] != '\0')) {
				FileCopy( szConfigSys, szMaxConfigSys );
				FileCopy( szAutoexec, szMaxAutoexec );
				FileCopy( szWinIni, szMaxWinIni );
				FileCopy( szSystemIni, szMaxSystemIni );
				if (szMaxMaxPro[0])
					FileCopy( szMaxPro, szMaxMaxPro );
				if (szMaxExtraDosPro[0])
					FileCopy( szMaxPro, szMaxMaxPro );
			}

			if (szDest[0]) {
				hModeless = CreateDialog(ghInstance, MAKEINTRESOURCE(MODELESSDLGBOX), hParent, ModelessDlgProc);
				wsprintf(szTemp, szFmt_Rest, szDest );
				SetDlgItemText( hModeless, 100, szTemp );
				RestoreMAX( );
				DestroyWindow( hModeless );
			}
		}
	}

	return FALSE;
}


// MAX successfully installed
BOOL CALLBACK __export ExitSuccessDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fMaximize = 0;
		CenterWindow(hDlg);
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			// run MAXIMIZE
			fMaximize = 1;
			EndDialog( hDlg, 0 );
			longjmp( quit_env, -1 );
			return TRUE;

		case IDC_EXIT:
			EndDialog(hDlg, 1);
			return TRUE;

		case IDC_HELP:
	    WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)(( LPSTR ) szHKEY_MaxNow ));
		}
	}

	return FALSE;
}


// MAX successfully installed, but we need to reboot
BOOL CALLBACK __export ExitRebootDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fReboot = 0;
		CenterWindow(hDlg);
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			EndDialog( hDlg, 0 );
			ExitWindows( EW_REBOOTSYSTEM, 0 );

		case IDC_EXIT:
			EndDialog(hDlg, 1);
			return TRUE;

		case IDC_HELP:
	    WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((LPSTR)szHKEY_Reboot ));
		}
	}

	return FALSE;
}

//------------------------------------------------------------------
// MAX could not copy all files while in Windows.
// We need to exit windows, copy the files and re-enter Windows for the
// exciting conclusion of setup.
BOOL CALLBACK __export ExitRestartDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fRestart = 0;
		CenterWindow(hDlg);
		return TRUE;

	case WM_COMMAND:
		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
	    fRestart = 1;
			EndDialog( hDlg, 0 );
			longjmp( quit_env, -1 );
			return TRUE;

		case IDC_EXIT:
	    fRestart = 0;
			EndDialog(hDlg, 1);
			return TRUE;

		case IDC_HELP:
	    WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)(( LPSTR ) szHKEY_Restart ));
		}
	}

	return FALSE;
}


// MAX successfully installed, but need to copy *.ADD files
BOOL CALLBACK __export ExitNewDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow(hDlg);
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_EXIT:
			EndDialog(hDlg, 1);
			return TRUE;
		}
	}

	return FALSE;
}


void CenterWindow(HWND hWnd)
{
	RECT RectParent, Rect;
	int left, top, width, height;

	// get frame window size
	GetWindowRect(hParent, &RectParent);

	GetWindowRect(hWnd, &Rect);

	width = Rect.right - Rect.left;
	height = Rect.bottom - Rect.top;

	left = RectParent.left + ((RectParent.right - RectParent.left) / 2) - (width / 2);
	top = RectParent.top + ((RectParent.bottom - RectParent.top) / 2) - (height / 2);

	SetWindowPos( hWnd, HWND_TOP, left, top, width, height, SWP_SHOWWINDOW );
}


// draw the copy progress meter
int DrawMeter(HWND hWnd, int nPercent)
{
	char szText[8];
	int n, nHeight;
	LONG lRight;
	HDC hDC;
	RECT rc;
	HBRUSH hBrush;
	TEXTMETRIC tm;

	GetClientRect(hWnd, &rc);
	lRight = rc.right;
	lRight *= nPercent;
	n = (int)(lRight / 100);

	hDC = GetDC(hWnd);

	rc.top += 1;
	rc.left += 1;
	rc.bottom -= 1;
	rc.right = n;
	hBrush = CreateSolidBrush( RGB(0, 0, 255) );
	FillRect(hDC, &rc, hBrush);
	DeleteObject(hBrush);

	// clear the rest of the box
	GetClientRect(hWnd, &rc);
	rc.left = n + 1;
	rc.top += 1;
	rc.bottom -= 1;
	rc.right -= 1;
	hBrush = CreateSolidBrush( RGB(255, 255, 255) );
	FillRect(hDC, &rc, hBrush);
	DeleteObject(hBrush);

	SetBkMode( hDC, TRANSPARENT );
	if (nPercent > 50)
		SetTextColor( hDC, RGB(255,255,255) );
	wsprintf( szText, "%d%%", nPercent );
	GetClientRect( hWnd, &rc );

	GetTextMetrics( hDC, &tm );
	nHeight = tm.tmHeight + tm.tmExternalLeading;
	rc.top = ((rc.bottom - nHeight) / 2);

	DrawText( hDC, szText, lstrlen(szText), &rc, DT_CENTER );

	ReleaseDC( hWnd, hDC );

	return 0;
}

#define SECURITY_LEN 350		// Length of Pattern
#define SECURITY_CHK 2

unsigned char szPattern[SECURITY_LEN+SECURITY_CHK];

// Encrypt Pattern
static void Encrypt (void)
{
	register unsigned int i, accum = 0;

	// Swap the nibbles and add a constant
	for ( i = 0; (i < SECURITY_LEN); i++ )
	     szPattern[i] = (char) ( ( (szPattern[i] << 4) | (szPattern[i] >> 4) ) + 0x23);

	for ( i = 0; (i < SECURITY_LEN); i++ )	  // Build a checksum
	     accum += (unsigned int) szPattern[i];

	// Store the checksum after the encrypted bytes
	*( (unsigned int *)( szPattern+i ) ) = accum;
}


static void Decrypt ( void )
{
	register unsigned int kk, sum;
	BYTE cc;

	/* First, check the checksum */
	sum = 0;
	for (kk = 0; (kk < SECURITY_LEN); kk++)
		sum += szPattern[kk];

	if (sum != *(WORD *)(szPattern+kk))
		return;

	/* Checksum ok, decrypt the string */
	for (kk = 0; (kk < SECURITY_LEN); kk++) {
		/* Subtract a constant and swap the nibbles  */
		cc = (BYTE)((szPattern[kk]) - 0x23);
		szPattern[kk] = (BYTE)((cc << 4) | (cc >> 4));
	}
}


int BrandFile (char *pszFileName)
{
	int rc = 0;
	unsigned int uDate, uTime;
	long lOffset;
	HFILE fh;
	EXEHDR_STR exe_hdr;

	if ((fh = _lopen ( pszFileName, READ_WRITE )) == HFILE_ERROR)
		return -1;

	_dos_getftime (fh, &uDate, &uTime);

	if ((_llseek (fh, -((long) sizeof (lOffset)), SEEK_END) == HFILE_ERROR ) || (_lread (fh, &lOffset, sizeof (lOffset)) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

	lOffset = ( ( lOffset & 0xFFFF0000L ) >> 12 ) + ( lOffset & 0x0000FFFFL );

	if ((_llseek (fh, 0L, SEEK_SET) == HFILE_ERROR ) || (_lread (fh, &exe_hdr, sizeof (exe_hdr)) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

	if (exe_hdr.exe_sign == 0x5a4d) // If .EXE format, skip over header
		lOffset += ((unsigned long) exe_hdr.exe_hsiz) << 4;

	// Ensure Pattern is initialized to 0's
	memset (szPattern, '\0', sizeof(szPattern) );

	// Encrypt data
	if (szCompany[0])
		wsprintf (szPattern, "\x02%s  %s\r\n%s %s - %s\r\n", szMsg_Sernum, szSerial, szMsg_License, szName, szCompany );
	else
		wsprintf (szPattern, "\x02%s  %s\r\n%s %s\r\n", szMsg_Sernum, szSerial, szMsg_License, szName );
	Encrypt ();

	// Write it out
	if ((_llseek (fh, lOffset, SEEK_SET) == HFILE_ERROR ) || (_lwrite (fh, szPattern, SECURITY_LEN+SECURITY_CHK) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

	// Restore file date/time
	_dos_setftime (fh, uDate, uTime);

Close_file:
	_lclose (fh);

	return rc;
}


// Try to get a valid brand from the specified file
int ReadBrand ( char *pszFileName, int fReset )
{
	int rc = 0;
	long lOffset;
	HFILE fh;
	EXEHDR_STR exe_hdr;

	// Ensure Pattern is initialized to 0's
	memset (szPattern, '\0', sizeof(szPattern) );

	if ((fh = _lopen ( pszFileName, READ )) == HFILE_ERROR)
		return -1;

	if ((_llseek (fh, -((long) sizeof (lOffset)), SEEK_END) == HFILE_ERROR ) || (_lread (fh, &lOffset, sizeof (lOffset)) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

	lOffset = ( ( lOffset & 0xFFFF0000L ) >> 12 ) + ( lOffset & 0x0000FFFFL );

	if ((_llseek (fh, 0L, SEEK_SET) == HFILE_ERROR ) || (_lread (fh, &exe_hdr, sizeof (exe_hdr)) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

	if (exe_hdr.exe_sign == 0x5a4d) // If .EXE format, skip over header
		lOffset += ((unsigned long) exe_hdr.exe_hsiz) << 4;

	// Read it in
	if ((_llseek (fh, lOffset, SEEK_SET) == HFILE_ERROR ) || (_lread (fh, szPattern, SECURITY_LEN+SECURITY_CHK) == HFILE_ERROR )) {
		rc = -1;
		goto Close_file;
	}

Close_file:
	_lclose (fh);

	Decrypt();

	if (( szPattern[0] == 1 ) || (szPattern[0] == 2 )) {
		if (fReset) {
			sscanf (szPattern, szFmt_IDScan, szSerial, szName, szCompany );
			strip_trailing( szName, " \t" );
		}
		return 1;
	}

	return rc;
}

// look for 386MAX.SYS or BLUEMAX.SYS in CONFIG.SYS
void CheckForMax( void )
{
	int n, nLine;
	char *ptr, szBuf[512];
	char szFNameTemp[ _MAX_FNAME ];
	static char szFName[ _MAX_FNAME + 2 ];
	HFILE fh;

	nOldMaxLine = -1;
	szMaxPro[0] = '\0';
	pszStripExcept = "";
	nLine = -1;
	bMaxFound = FALSE;
	if ((fh = _lopen( szConfigSys, READ )) != HFILE_ERROR) {

		if (szMultiSection[0] == '\0')
			goto ReadSection;

		// read file for section names
		for ( ; GetLine( fh, szBuf, 511 ) > 0; ) {

	    nLine++;
			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			if (szBuf[0] != '[')
				continue;

			lstrcpy( szBuf, szBuf + 1 );
			strip_trailing( szBuf, "]" );

			// check for section name or common section
			// FIXME Are we also handling these cases properly in
			// InsertInConfigSys ?
			if (lstrcmpi(szBuf, szMultiSection) == 0 ||
			    !lstrcmpi( szBuf, "common" )) {
ReadSection:
				for ( ; (n = GetLine( fh, szBuf, 511 )) > 0; ) {

		    nLine++;
					strip_leading( szBuf, " \t" );
					strip_trailing( szBuf, " \t" );

					if (szBuf[0] == '[') {
						strip_leading( szBuf, "[ \t" );
						strip_trailing( szBuf, "] \t" );
						if (lstrcmpi( szBuf, "COMMON" ) &&
							lstrcmpi( szBuf, szMultiSection ))
							break;
					}

					// ignore lines that don't begin with
					//   "device=..."
					if ((ptr = ntharg( szBuf, 0 )) == NULL)
						continue;
					if (lstrcmpi( ptr, "device" ) != 0)
						continue;

					if ((FindString( szBuf, "386max.sys") >= 0) ||
					    (FindString( szBuf, "bluemax.sys") >= 0)) {

						bMaxFound = TRUE;
						ptr = ntharg( szBuf, 1 );
						if (!ptr) ptr = "";
						_splitpath( ptr, NULL, NULL, szFNameTemp, NULL );
						if (!lstrcmpi( szFNameTemp, "bluemax" )) {
			    nOldMaxLine = nLine;
						} // Save line number to replace
						wsprintf( szFName, "~%s.sys ", szFNameTemp );
						pszStripExcept = szFName;
						if (*ptr && (path_part ( ptr ) != NULL))
							wsprintf( szMax, "%.79s", path_part( ptr ));
						else
							lstrcpy( szMax, "\\" );
						mkfname( szMax );
						strip_trailing( szMax + 3, "\\/" );

						// get 386MAX.PRO name / location
						if (((ptr = ntharg( szBuf, 2 )) != NULL) && (lstrcmpi( ptr, "pro" ) == 0)) {
							lstrcpy( szMaxPro, ntharg( szBuf, 3) );
						}
					}

					if (FindString( szBuf, "extrados.sys") >= 0) {

						// get EXTRADOS.PRO name / location
						if (((ptr = ntharg( szBuf, 2 )) != NULL) && (lstrcmpi( ptr, "pro" ) == 0))
							lstrcpy( szExtraDosPro, ntharg( szBuf, 3) );
						break;
					}
				}
			}
		}

		_lclose(fh);
	}

	if (szMax[0] == '\0') {

		// if not running MAX, we must reboot before Maximizing
		fReboot = 1;

		// look for previous MAX installation in QMAX.INI
		GetPrivateProfileString( "CONFIG", "Qualitas MAX Path", NULLSTR, szMax, 80, szININame );
	}

	if ((szExtraDosPro[0] == '\0') && (szMax[0]))
		MakePath( szMax, "extrados.pro", szExtraDosPro );
}

void CheckForBrand(void)
{
	static char *szaDirs[] = {
		NULL,
		"c:\\386max",
		"c:\\qmax"
	};
	static char *szaUpdate[] = {
		NULL,
		"386load.sys",
		"386util.com"
	};
	register int i, n;
	char szBuf[256];

	szaDirs[0] = szMax;
	szaUpdate[0] = "386max.sys";

	// look for a branded 386MAX
	for (i = 0; ((i < 3) && (fUpdate == 0)); i++) {

		for (n = 0; (n < 3); n++) {
			MakePath( szaDirs[i], szaUpdate[n], szBuf );
			if (QueryFileExists( szBuf ) == 0)
				break;
			fUpdate = (ReadBrand( szBuf, 0 ) != 0);
		}
	}

	if (fUpdate)
		return;

	szaUpdate[0] = "bluemax.sys";

	// look for a branded BLUEMAX
	for (n = 0; (n < 3); n++) {
		MakePath( "c:\\bluemax", szaUpdate[n], szBuf );
		if (QueryFileExists( szBuf ) == 0)
			break;
		fUpdate = (ReadBrand( szBuf, 0 ) != 0);
	}
}

// insert/delete a line in 386MAX.PRO
void ModifyMaxPro( char *pszLine, int fDelete )
{
	static int fSectionHeader = 0;
	unsigned int fInserted = 0, uSize;
	char *ptr, szTemp[128], szBuf[512];
	int fSection = 0;
	long lOffset = 0L;
	HFILE fh;

	if (((fh = _lopen( szMaxPro, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szMaxPro, 0 )) != HFILE_ERROR )) {

		// read file for matching option
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';'))
				goto SaveOffset;

			if ((szBuf[0] == '[') && (szMultiSection[0] != '\0')) {

				if (fSection == 2) {
					// already got the section; add this
					//   line to the end
					if (fDelete == 0) {
						_llseek( fh, lOffset, SEEK_SET );

			    // this will terminate the process.
			goto InsertLine;

					} else {
			    // delete, but line not found yet.
			    // allow for duplicate sections.
			lstrcpy( szBuf, szBuf + 1 );
			strip_trailing( szBuf, "] " );

			// check for duplicate section name
			if (lstrcmpi(szBuf, szMultiSection) != 0) {
			    fSection = 1;
				// effective continue.
			    goto SaveOffset;
			} // else leave fSection = 2.
		    }

				} else {

					lstrcpy( szBuf, szBuf + 1 );
					strip_trailing( szBuf, "] " );

					// check for section name
					if (lstrcmpi(szBuf, szMultiSection) != 0) {
						fSection = 1;
			    // effective continue.
						goto SaveOffset;
					}
			// got the right section!
					fSection = 2;
			// effective continue.
		    goto SaveOffset;
				} // end of else ( fSection != 2 )

			} else if (fSection == 1)
			    // not a section, but in the wrong section.
		continue;	// waiting for right section

			// strip trailing whitespace & comments
			ptr = scan( szBuf, ((fDelete & 1) ? " \t;" : " \t;=" ));
			if (*ptr != '\0')
				*ptr = '\0';

			lstrcpy( szTemp, pszLine );
			ptr = scan( szTemp, ((fDelete & 1) ? " \t;" : " \t;=" ));
			if (*ptr != '\0')
				*ptr = '\0';

		// modified to scan for partials 11/9/95 PETERJ
			if ( !_fstrnicmp( (LPSTR)szBuf, (LPSTR)szTemp, _fstrlen( (LPSTR)szTemp ))) {
InsertLine:
		bMaxProModified |= 1;

				// read remainder of file into temp buffer
				uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
				ptr = AllocMem( &uSize );
				uSize = _lread( fh, ptr, uSize );

				_llseek( fh, lOffset, SEEK_SET );

				// write new line
				if (fDelete == 0) {
					_lwrite( fh, pszLine, lstrlen( pszLine ));
					_lwrite( fh, "\r\n", 2 );
					fInserted = 1;
				}

				// write remainder of file
				_lwrite( fh, ptr, uSize );
				_lwrite( fh, NULLSTR, 0 );
				FreeMem( ptr );
		    // force end of while ( GetLine ).
				break;

			} // end of if( line compares true ).

SaveOffset:
		// save position of end of line just read.
			lOffset = _llseek( fh, 0L, SEEK_CUR );
		} // end of while GetLine().

	    // we never found the proper line and we are now
	    // positioned at the end of the file.
	    // write new line, adding section header if necessary.
		if ((fInserted == 0) && (fDelete == 0)) {

	    bMaxProModified |= 1;
			if ((fSectionHeader == 0) && (szMultiSection[0])) {
				if (lOffset > 0L)
					_lwrite( fh, "\r\n", 2 );
				wsprintf( szBuf, "[%s]\r\n", szMultiSection );
				_lwrite( fh, szBuf, lstrlen( szBuf ));
				fSectionHeader = 1;
			}
			_lwrite( fh, pszLine, lstrlen( pszLine ));
			_lwrite( fh, "\r\n", 2 );
			_lwrite( fh, NULLSTR, 0 );
		}

		_lclose( fh );
	} // end of if (file open)
}


//------------------------------------------------------------------
// check INSTALL.CFG to see if we should install 386MAX.SYS after this line
// FIXME we should parse this into memory rather than re-parsing it
// for every line we check in CONFIG.SYS...
//------------------------------------------------------------------
int ParseInstallCfg( char *pszDriver )
{
	register int rval = 0;
	char szTemp[128];
	char *ptr, szBuf[512];
	HFILE fh;

	if ((pszDriver == NULL) || ((pszDriver = fname_part(pszDriver)) == NULL))
		return 1;

	MakePath( szDest, "setupdos.cfg", szTemp );

	if ((fh = _lopen( szTemp, READ )) != HFILE_ERROR) {

		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			if ((szBuf[0] == '\0') || (szBuf[0] == ';'))
				continue;

			// a 'P' only needs to be loaded before MAX if the
			//   MAX install disk isn't the boot disk
			if (szBuf[0] == 'P') {
				if (szConfigSys[0] == szDest[0])
					continue;
			} else if (szBuf[0] != 'D')
				continue;

			if ((ptr = ntharg( szBuf, 1 )) == NULL)
				continue;

			if (lstrcmpi( ptr, pszDriver ) == 0) {
				rval = 1;
				break;
			}
		}

		_lclose( fh );
	}

	return rval;
}

// insert / delete a line in AUTOEXEC.ADD
int ModifyAutoexec( char *pszLine, int fDelete)
{
	unsigned int uSize = 0;
	char *ptr, szBuf[512];
    char szSpcBuf[ SPCBUFSIZE + 1 ];
	int nI;
	long lOffset = 0L;
	HFILE fh;

    if( !szAutoTemp[0] ) {
	    // we only do this if there were no changes in edit_batfiles().
	MakePath( szDest, "autoexec.add", szAutoTemp );
	FileCopy( szAutoTemp, szAutoexec );
    }

	if (((fh = _lopen( szAutoTemp, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szAutoexec, 0 )) != HFILE_ERROR )) {

		if (fDelete) {

			while (GetLine( fh, szBuf, 511 ) > 0) {

		    // terminates with nI = blanks
		for( nI=0, szSpcBuf[0] = '\0';
		    ( nI < SPCBUFSIZE ) &&
		    ( szBuf[nI] != '\0' ) &&
		    ( szBuf[nI] == ' ' ) || ( szBuf[nI] == '\t' ) ; nI++ ) {

		    szSpcBuf[ nI ] = szBuf[ nI ];
		}
				strip_leading( szBuf, " \t" );
				strip_trailing( szBuf, " \t" );

				if ((ptr = ntharg(szBuf, 0)) != NULL)
					ptr = fname_part( ptr );

				if ((ptr != NULL) && (lstrcmpi(ptr, pszLine) == 0)) {
					uSize = 1;
					break;
				}

				lOffset = _llseek( fh, 0L, SEEK_CUR );
			}

			if (uSize == 0) {
				_lclose(fh);
				return 0;		// line not found
			}
		}

		// read remainder of file into temp buffer
		uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
		ptr = AllocMem( &uSize );
		uSize = _lread( fh, ptr, uSize );

		// write new line
		_llseek( fh, lOffset, SEEK_SET );

		if (fDelete == 0) {
	    if ( nI > 0 ) {
		_lwrite( fh, szSpcBuf, nI );
	    }
			_lwrite( fh, pszLine, lstrlen( pszLine ));
			_lwrite( fh, "\r\n", 2 );
		}

		// write remainder of file
		_lwrite( fh, ptr, uSize );
		_lwrite( fh, NULLSTR, 0 );
		FreeMem( ptr );

		_lclose(fh);
	}

	return 1;
}


// modify the DOSMAX.DLL line in DOSMAX.REG
int ModifyDOSMAXReg( void )
{
#ifdef VER2
	int n;
	unsigned int uSize = 0;
	char *ptr, szBuf[512];
	long lOffset = 0L;
	HFILE fh;

	MakePath( szDest, "dosmax.reg", szBuf );
	if (((fh = _lopen( szBuf, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szAutoexec, 0 )) != HFILE_ERROR )) {

		while (GetLine( fh, szBuf, 511 ) > 0) {

			if ((n = FindString( szBuf, "dosmax.dll" )) >= 0) {

				// read remainder of file into temp buffer
				uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
				ptr = AllocMem( &uSize );
				uSize = _lread( fh, ptr, uSize );

				// write new line
				_llseek( fh, lOffset, SEEK_SET );
		strins( szBuf, szDest );
				_lwrite( fh, pszLine, lstrlen( pszLine ));
				_lwrite( fh, "\"\r\n", 2 );

				// write remainder of file
				_lwrite( fh, ptr, uSize );
				_lwrite( fh, NULLSTR, 0 );
				FreeMem( ptr );

				break;
			}

			lOffset = _llseek( fh, 0L, SEEK_CUR );
		}

		_lclose(fh);
	}
#endif
	return 1;
}


// read the designated .PRO file and return pointer to the line if found
char * ParsePro(char *pszFilename, char *pszLine)
{
	static char szBuf[512];
	int fSection = 0;
	char *ptr;
	HFILE fh;

	if ((fh = _lopen( pszFilename, READ | OF_SHARE_DENY_NONE )) != HFILE_ERROR) {

		// read file
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';') || ((ptr = ntharg(szBuf, 0)) == NULL) || (lstrcmpi(ptr, "rem") == 0))
				continue;

			if ((szBuf[0] == '[') && (szMultiSection[0])) {

				lstrcpy( szBuf, szBuf + 1 );
				strip_trailing( szBuf, "] " );

				// check for section name
				if ((lstrcmpi(szBuf, szMultiSection) != 0) && (lstrcmpi(szBuf, "common") != 0)) {
					fSection = 1;
					continue;
				}

				fSection = 0;

			} else if (fSection == 1)
				continue;	// waiting for right section

			// remove comment before testing line
			if ((ptr = strchr( szBuf, ';' )) != NULL)
				*ptr = '\0';

			if (FindString(szBuf, pszLine) >= 0) {
				_lclose(fh);
				return szBuf;
			}
		}

		_lclose( fh );
	}

	return NULL;
}


void CreatePreinst(void)
{
	extern char _far szBackupDir[];

	char szBuf[512];
	HFILE fh;

	MakePath( szDest, "preinst.bat", szBuf );
	if ((fh = _lcreat( szBuf, 0 )) != HFILE_ERROR) {

		if (szBackupDir[0]) {
			wsprintf(szBuf, "if exist %s\\*.* copy %s\\. %s\\.\r\n", szBackupDir, szBackupDir, szDest );
			_lwrite( fh, szBuf, lstrlen(szBuf) );

	    if( bGASaved ) {
		wsprintf(szBuf, "if exist %s\\%s copy %s\\%s %s\r\n",
				szBackupDir, szDrvName,
				szBackupDir, szDrvName, szWindowsSystemDir );
		_lwrite( fh, szBuf, lstrlen(szBuf) );
	    }
		}

		wsprintf( szBuf, "copy %s %s\r\ncopy %s %s\r\n", szMaxConfigSys, szConfigSys, szMaxAutoexec, szAutoexec );
		_lwrite( fh, szBuf, lstrlen(szBuf) );

		wsprintf( szBuf, "copy %s %s\r\ncopy %s %s\r\n", szMaxSystemIni, szSystemIni, szMaxWinIni, szWinIni );
		_lwrite( fh, szBuf, lstrlen(szBuf) );

	if ( szMaxMaxPro[0] ) {
	    wsprintf( szBuf, "copy %s %s\r\n", szMaxMaxPro, szMaxPro );
	    _lwrite( fh, szBuf, lstrlen(szBuf) );
	}

	if( bWin95 ) {
	    wsprintf( szBuf, "copy %s %s\r\n", szMaxIOSIni, szIOSIni );
	    _lwrite( fh, szBuf, lstrlen(szBuf) );
	}

		_lclose( fh );
	}
}


//-----------------------------------------------------------------
//  NotifyRegisterCallback
//
//  Purpose: Callback procedure for NotifyRegister
//
//  Parameters:
//	wID  = Type of notification
//     dwData = data or pointer to data depending on value of wID
//-----------------------------------------------------------------
BOOL CALLBACK __export NotifyRegisterCallback( UINT wID, DWORD dwData )
{
	HTASK hTask;	 // handle of the task that called the notification call back
	TASKENTRY te;

	// Check for task exiting
	if ((wID == NFY_EXITTASK) && (ghChildInstance)) {

		// Obtain info about the task that is terminating
		hTask = GetCurrentTask();
		te.dwSize = sizeof(TASKENTRY);
		TaskFindHandle( &te, hTask );

		// Check if the task that is terminating is our child task.
		// Also check if the hInstance of the task that is terminating
		// is the same as the hInstance of the task that was Exec'd
		// by us earlier in this file.
		if ((te.hTaskParent == ghTaskParent) && ((te.hInst == ghChildInstance) || (ghChildInstance == NULL)))
			PostMessage( hParent, PM_TASKEND, LOBYTE(dwData), 0L );
	}

	// Pass notification to other callback functions
	return FALSE;
}


// FIXME!

// Win95 Registry support for Setup
int AddDOSMAXKeys( void )
{
	register int i;
	HKEY hkProtocol;
	char szBuf[260];

	for (i = 0; (DosMaxRegistry[i].pszKey != NULL); i++) {
		// Add the DOSMAX keys to the registry
	MessageBox(0,DosMaxRegistry[i].pszKey,DosMaxRegistry[i].pszValue,MB_OK);
		if (i == 1) {
			MakePath( szDest, "dosmax32.dll", szBuf );
			DosMaxRegistry[i].pszValue = szBuf;
		}
		RegSetValue( HKEY_CLASSES_ROOT, DosMaxRegistry[i].pszKey, REG_SZ, DosMaxRegistry[i].pszValue, lstrlen(DosMaxRegistry[i].pszValue) );
	}

	// Add the "ThreadingModel=Apartment" value
	if (RegCreateKey( HKEY_CLASSES_ROOT, "CLSID\\{E7BDB3C0-080D-11CF-BABB-444553540000}\\InProcServer32", &hkProtocol) == ERROR_SUCCESS) {
		RegSetValue( hkProtocol, NULL, REG_SZ, "ThreadingModel=Apartment", 9 );
		RegCloseKey( hkProtocol );
	}

    return 0;
}

//------------------------------------------------------------------
// insert/delete a line in IOS.INI
void ModifyIOSIni( char *pszSection, char *pszLine )
{
	unsigned int fInserted = 0, uSize;
	char *ptr, szTemp[128], szBuf[512];
	int fSection = 0;
	long lOffset = 0L;
	HFILE fh;

	// clear the status flag.
    bIOSModified = 0;

	if (((fh = _lopen( szIOSIni, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szMaxPro, 0 )) != HFILE_ERROR )) {

	    // while there is still a line...
		while ( GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

		// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';')) {

		    // fill at blank if in the right section.
		if ((szBuf[0] == '\0') && fSection ) {
			// add line and proceed to end
		    _llseek( fh, lOffset, SEEK_SET );
		    goto InsertLine;

		} else {
		    goto SaveOffset;
		}
	    }

		// if this line is a section and a section was passed in...
			if ((szBuf[0] == '[') && ( pszSection[0] != '\0')) {

				if ( fSection ) {

					// new section with correct section pending.
					// add line and proceed to end
		    _llseek( fh, lOffset, SEEK_SET );
		    goto InsertLine;

				} else {

			// this is a section...check it
					lstrcpy( szBuf, szBuf + 1 );
					strip_trailing( szBuf, "] " );

					// check for section name
					if (lstrcmpi(szBuf, pszSection) != 0) {
						goto SaveOffset;
					}

					// got the right section!
					fSection = 1;
		    goto SaveOffset;
				}

			} else {

		    // if we are in the correct section...
		if ( fSection ) {
			// strip trailing whitespace & comments
		    ptr = scan( szBuf, " \t;=" );
		    if (*ptr != '\0')
			*ptr = '\0';

		    lstrcpy( szTemp, pszLine );
		    ptr = scan( szTemp, " \t;=" );
		    if (*ptr != '\0')
			*ptr = '\0';

		    if ( lstrcmpi( szBuf, szTemp) == 0) {
			// if a duplicate line...forget it.
			goto CloseOut;
		    }
		}
	    }
		    // waiting for right section
		    // next loop iteration.
				continue;
InsertLine:
	// read remainder of file into temp buffer
	uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
	ptr = AllocMem( &uSize );
	uSize = _lread( fh, ptr, uSize );

	_llseek( fh, lOffset, SEEK_SET );

	// write new line
	_lwrite( fh, pszLine, lstrlen( pszLine ));
	_lwrite( fh, "\r\n", 2 );
	fInserted = 1;
	bIOSModified = 1;

	// write remainder of file
	_lwrite( fh, ptr, uSize );
	_lwrite( fh, NULLSTR, 0 );
	FreeMem( ptr );
	break;

SaveOffset:
	lOffset = _llseek( fh, 0L, SEEK_CUR );
		}

		// write new line
		if ( fInserted == 0) {
	    _lwrite( fh, pszLine, lstrlen( pszLine ));
	    _lwrite( fh, "\r\n", 2 );
	    _lwrite( fh, NULLSTR, 0 );
	    bIOSModified = 1;
		}

CloseOut:
		_lclose( fh );
	}
}

//------------------------------------------------------------------
// "Ref Directory" dialog box
//------------------------------------------------------------------
BOOL CALLBACK __export RefDirDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{

	extern HWND hParent;
	extern HANDLE ghInstance;
	extern char _far szHelpName[];
    char szTemp[ _MAX_PATH + 1 ];
    struct find_t dir;
    int nErr = 0;
    int uError;

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
	szADFSrc[0] = '\0';
	szADFDest[0] = '\0';
		SetDlgItemText( hDlg, IDC_TEXT, szMsg_RefDisk );
		SetDlgItemText( hDlg, IDC_PATH, "A:\\" );
	    SendMessage( GetDlgItem( hDlg, IDC_PATH ), EM_LIMITTEXT, _MAX_PATH, 0L);
		SetFocus( GetDlgItem( hDlg, IDC_PATH ) );
		return 0;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:

	    uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

		// get source dir into szADFSrc.
			GetDlgItemText(hDlg, IDC_PATH, szADFSrc, _MAX_PATH );

		// Make a temporary global path.
	    MakePath( szADFSrc, "*.adf", szTemp );

	    if( _dos_findfirst( szTemp, _A_NORMAL, &dir )) {
		int rc;
		if(( rc=MessageBox( NULL, szMsg_BadRef, NULL,
				    MB_ICONHAND | MB_YESNO )) == IDYES ){
		    szADFSrc[0] = '\0';
		    szADFDest[0] = '\0';
		    SetErrorMode( uError );
		    EndDialog( hDlg, 1 );
		    return 0;
		} else {
		    SetFocus( GetDlgItem( hDlg, IDC_PATH ) );
		    SetErrorMode( uError );
		    break;
		}
	    } else {
		    // Make the destination Directory.
		MakePath( szDest, "ADF", szADFDest );

		    // search for the directory
		if( _dos_findfirst( (LPSTR)szADFDest, _A_SUBDIR, &dir )) {

			// directory does not exist...make it.
		    if(( nErr = _mkdir( (LPSTR)szADFDest )) != 0 )  {
			// a failure has occurred.
			szADFDest[0] = '\0';
		    }
		} // else the directory already exists.

		SetErrorMode( uError );
		EndDialog( hDlg, 0 );
		return 0;
	    }

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hDlg, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			return 0;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)( (LPSTR)szHKEY_RefDir ));
			break;
		}
	}

	return FALSE;
}

//------------------------------------------------------------------
// Copy ADF files from floppy to \qmax\adf
//------------------------------------------------------------------
void CopyADFFiles( char *szFileTemplate)
{
	int uError, fFval;
	struct find_t dir;
	char szSrcFile[ _MAX_PATH + 1 ];
	char szSrcRet[ _MAX_PATH + 1 ];
	char szTarget[ _MAX_PATH + 1 ];

    uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

    hModeless = CreateDialog(ghInstance, MAKEINTRESOURCE(MODELESSDLGBOX), hParent, ModelessDlgProc);
	SetDlgItemText( hModeless, 100, szMsg_CopyADF );

    MakePath( szADFSrc, szFileTemplate, szSrcFile );
    SetupYield(0);

    for (fFval = 0x4E; ; fFval = 0x4F) {
	szSrcRet[0] = '\0';
	if (FindFile( fFval, szSrcFile, &dir, szSrcRet ) == NULL) {
	    break;
	}

	MakePath( szADFDest, fname_part( szSrcRet), szTarget );
	FileCopy( szTarget, szSrcRet );
	SetupYield(0);
    }

    SetErrorMode( uError );
    DestroyWindow( hModeless );
}

//------------------------------------------------------------------
// Go Ahead Load Clearance, 0 = ok, 1 = Inhibit Go Ahead loading.
//------------------------------------------------------------------
BOOL GALoadClearance()
{
    int nRet = 0;
    char szWork[ _MAX_PATH + 1 ];
    BOOL bRetVal = FALSE;
    HINSTANCE hInst;

    BOOL ( FAR *lpfnGALoadClear)();
    BOOL ( FAR *lpfnGADialog)(HWND, int);

    if ( fRefresh ) {
	    // if /W we must use the installed driver.
	MakePath( szWindowsSystemDir, szDrvName, szWork );
    } else {
	    // use the new one in the \qmax dir.
	MakePath( szDest, szDrvName, szWork );
    }

    hInst = LoadLibrary ( szWork );
    if ((UINT) hInst >= 32)	{ // If it worked, ...
	(FARPROC) lpfnGALoadClear = GetProcAddress (hInst, pszGALoadClear);
	(FARPROC) lpfnGADialog = GetProcAddress (hInst, pszGADialog);

	if (lpfnGALoadClear != NULL) {	// If it worked, ...
		// if there is a conflict..
	    if( !lpfnGALoadClear() ) {
		    // call the warning box.
		if (lpfnGADialog != NULL) {
		    if(( nRet = lpfnGADialog( hParent, 1 )) != 1 ) {
			bRetVal = TRUE;
		    }
		}
	    }
	}
	FreeLibrary (hInst); // Decrement reference count
    }

    return bRetVal;
}

//------------------------------------------------------------------
void ShutDownMaxUtils()
{
    HWND hWndT;
	HDRVR hDriver;
    char szT1[ _MAX_PATH + 1 ];

    if ((hWndT = FindWindow( "GAHD_CLS", NULL)) != 0) {
	SendMessage(hWndT, WM_CLOSE, 0, 0L);
	bGAFound = TRUE;
	SetupYield(0);
    }

    if ((hWndT = FindWindow( "MaxMeterWClass", NULL)) != 0) {
	SendMessage(hWndT, WM_CLOSE, 0, 0L);
	bMMFound = TRUE;
	SetupYield(0);
    }

    if( bWin95 ) {
	    // if win 95 and we found goahead, destroy it!
	if ((hDriver = OpenDriver(szDrvName, NULL, NULL)) != NULL) {
	    SendDriverMessage(hDriver, DRV_REMOVE, NULL, NULL);
	    CloseDriver(hDriver, NULL, NULL);

	    pmShowGroup( szStartupGroup, 2 );
	    pmShowGroup( szStartupGroup, 1 );
	    SetupYield(0);

		// don't ask me why...one doesn't always work...two does.
	    pmDeleteItem( szGoAhead );
	    pmDeleteItem( szGoAhead );
	    pmShowGroup( szStartupGroup, SW_SHOWMINIMIZED );
	    bGAFound = FALSE;

	    pmShowGroup( szProgmanGroup, 2 );
	    pmShowGroup( szProgmanGroup, 1 );
	    pmDeleteItem( szGoAhead );
	    pmDeleteItem( szGoAhead );
	    pmShowGroup( szProgmanGroup, SW_SHOWMINIMIZED );

		// remove the driver...completely.
	    MakePath( szWindowsSystemDir, szDrvName, szT1 );
	    remove( szT1 );
	}
    }
}

//------------------------------------------------------------------
// restart utils if they were already on.
//------------------------------------------------------------------
void RestartMaxUtils( LPSTR szDst)
{
    char szT1[ _MAX_PATH + 1 ];

    if ( bGoAhead && !bStayBack & bGAFound) {
	MakePath( szDst, FILENAMEXE, szT1 );
	WinExec( (LPSTR)szT1, SW_SHOWMINIMIZED );
    }

    if ( bMaxMeter && bMMFound) {
	MakePath( szDst, szMMName, szT1 );
	WinExec( (LPSTR)szT1, SW_SHOW );
    }
}

//------------------------------------------------------------------
// Return TRUE if old files exists and dates do not match.
// Use complete path of both files.
//------------------------------------------------------------------
BOOL NeedBackup( LPSTR lpOld, LPSTR lpNew )
{
    int ohandle, nhandle;
    DIRTIME  otime, ntime;

    otime.dtime = 0L;
    ntime.dtime = 0L;

    if (( ohandle = _lopen( lpOld, READ | OF_SHARE_COMPAT )) != HFILE_ERROR ) {
	  _dos_getftime( ohandle, &(otime.dt.date), &(otime.dt.time));
	  _lclose( ohandle );
    } else {
	return FALSE;
    }

    if (( nhandle = _lopen( lpNew, READ | OF_SHARE_COMPAT )) != HFILE_ERROR ) {
	  _dos_getftime( nhandle, &(ntime.dt.date), &(ntime.dt.time));
	  _lclose( nhandle );
    } else {
	return TRUE;
    }

    if (( ntime.dtime > otime.dtime)
    || ( ntime.dtime < otime.dtime)) {
	return TRUE;
    } else {
	return FALSE;
    }
}

//------------------------------------------------------------------
// Remove Entries with values above the threshold.
//------------------------------------------------------------------

BOOL DelMaxProRange( LPSTR lpSection, LPSTR lpEntry, DWORD dwLow )
{
    if( SFS_Read( szMaxPro )) {
	if( SFS_Search( lpSection, lpEntry, dwLow )) {
	    SFS_Write( szMaxPro );
	}

	SFS_Cleanup();
	return TRUE;
    } else {
	return FALSE;
    }
}

//------------------------------------------------------------------
// Functions to read a file into a list and parse it.
//------------------------------------------------------------------
typedef struct _tagLList
{
    void *prev;
    void *next;
    LPSTR line;
} SFLLIST;

SFLLIST *lpAnchor = NULL;
LPSTR lplFile = NULL;

BOOL SFS_Read( LPSTR lpFile )
{
    BOOL bRet = TRUE;
    BOOL bRead = TRUE;
    BOOL bGotSection = FALSE;
	HFILE fh;
    char szBuf[ 256 ];

	// empty the old garbage...
    SFS_Cleanup();

	// save the new parameters...
    lplFile = _fstrdup( lpFile );

	// build the list to search.
    if ((fh = _lopen( lplFile, READ | OF_SHARE_DENY_NONE )) != HFILE_ERROR ) {

	    // first read in the file.
	while ( GetLine( fh, szBuf, 255 ) > 0 ) {
	    SFS_Add( (LPSTR)szBuf );
	}
	    // reading is complete.
	_lclose( fh );

    } else {

	bRet = FALSE;
    }

    return bRet;
}
//------------------------------------------------------------------

BOOL SFS_Write( LPSTR lpFile )
{
    BOOL bRet = TRUE;
	HFILE fh;
    SFLLIST *lpScan = NULL;

	// build the list to search.
    if ((fh = _lopen( lplFile, WRITE | OF_SHARE_EXCLUSIVE )) == HFILE_ERROR ) {
	return FALSE;
    }

    for ( lpScan = lpAnchor; lpScan != NULL; lpScan = lpScan->next ) {
	if( _lwrite( fh, lpScan->line, lstrlen( lpScan->line )) == HFILE_ERROR ) {
	    _lclose( fh );
	    return FALSE;
	}

	if( _lwrite( fh, "\r\n", 2 ) == HFILE_ERROR ) {
	    _lclose( fh );
	    return FALSE;
	}
    }

    _lclose( fh );
    return TRUE;
}

//------------------------------------------------------------------
// returns true if addition is successful.
//------------------------------------------------------------------
BOOL SFS_Add( LPSTR line )
{
    SFLLIST *lpTemp = NULL;
    SFLLIST *lpScan = NULL;

    if( lpAnchor == NULL ) {
	if ((lpAnchor = (SFLLIST *)_fmalloc( sizeof( SFLLIST ))) != NULL ) {
	    lpAnchor->prev = NULL;
	    lpAnchor->next = NULL;
	    if((lpAnchor->line = _fstrdup( line )) != NULL ) {
		return TRUE;
	    } else {
		return FALSE;
	    }
	} else {
	    return FALSE;
	}
    } else {
	    // go to the end of the line.
	for( lpScan=lpAnchor; lpScan->next != NULL; ) {
	    lpScan = lpScan->next;
	}
	    // add a node.
	if ((lpTemp = (SFLLIST *)_fmalloc( sizeof( SFLLIST ))) != NULL ) {
	    lpScan->next = lpTemp;
	    lpTemp->prev = lpScan;
	    lpTemp->next = NULL;
	    if(( lpTemp->line = _fstrdup( line )) != NULL ) {
		return TRUE;
	    } else {
		return FALSE;
	    }
	} else {
	    return FALSE;
	}
    }
}

//------------------------------------------------------------------
// returns true if value is found in the list.
//------------------------------------------------------------------
#define LBUFLEN 512
char *szSearchToks = "\t=- ";
BOOL SFS_Search( LPSTR lpSection, LPSTR lpEntry, DWORD dwLow )
{
    SFLLIST *lpScan = NULL;
    SFLLIST *lpTemp = NULL;
    BOOL bInSection = FALSE;
    DWORD dwTLow = 0;
    DWORD dwTHigh = 0;
    char lBuf[ LBUFLEN + 1 ];
    char *ptr, *ptr2;

    for ( lpScan = lpAnchor; lpScan != NULL; lpScan = lpScan->next ) {
	_fstrncpy( lBuf, lpScan->line, LBUFLEN );

	strip_leading( lBuf, " \t" );
	strip_trailing( lBuf, " \t" );

	    // skip blank lines and comments
	if (( lBuf[0] == '\0') || ( lBuf[0] == ';')
		|| ((ptr = ntharg( lBuf, 0)) == NULL)
		|| ( lstrcmpi( ptr, "rem") == 0)) {

		// skip to next line.
	    continue;
	}

	    // If we found a section header...
	if (( lBuf[0] == '[') && ( lpSection[0]) ) {

	    lstrcpy( lBuf, lBuf + 1 );
	    strip_trailing( lBuf, "] " );

	    // check for section name
	    if (( lstrcmpi( lBuf, lpSection) != 0 )
	     && ( lstrcmpi( lBuf, "common") != 0) ) {
		bInSection = FALSE;
	    } else {
		bInSection = TRUE;
	    }
		// skip to next line.
	    continue;
	}
	    // Continues skipped comments, blanks and headers...
	    // there's only reason to continue if we've got a line.
	if( bInSection || (!lpSection[0])) {
		// leading and trailing whitespace has been stripped.
		// Get the first token.
	    if(( ptr = strtok( lBuf, szSearchToks )) == NULL ) {
		    // skip to next line.
		continue;
	    }
		    // if not the key, or not enough tokens...continue.
	    if (( lstrcmpi( ptr, lpEntry ) )
		|| (( ptr = strtok( NULL, szSearchToks )) == NULL )
		|| (( ptr2 = strtok( NULL, szSearchToks )) == NULL )) {
		    // skip to next line.
		continue;
	    }

		// convert to numbers...
	    sscanf( ptr, "%lx", &dwTLow );
	    sscanf( ptr2, "%lx", &dwTHigh );

	    if(( dwTLow < dwLow ) && ( dwTHigh < dwLow )){
		    // skip to next line.
		continue;
	    }
		    // if we got this far, delete the line.
		    // if not the anchor, retreat one.
	    if( lpScan->prev != NULL ) {
		((SFLLIST *)lpScan->prev)->next = lpScan->next;
		((SFLLIST *)lpScan->next)->prev = lpScan->prev;
		lpTemp = lpScan->prev;
	    }
	    _ffree( lpScan->line );
	    _ffree( lpScan );
		// must do this or the loop will break!
	    lpScan = lpTemp;
	}
    }

return TRUE;
}

//------------------------------------------------------------------
void SFS_Cleanup()
{
    SFLLIST *lpScan = NULL;
    SFLLIST *lpTemp = NULL;

    if ( lplFile != NULL ) {
	_ffree( lplFile );
	lplFile = NULL;
    }

    if( lpAnchor != NULL ) {
	    // seek to the end of the list.
	for ( lpScan = lpAnchor; lpScan->next != NULL; ) {
	    lpScan = lpScan->next;
	}
	    // back up and free the list.
	for ( ; lpScan != lpAnchor; ) {
	    lpTemp = lpScan;
	    lpScan = lpScan->prev;
	    _ffree( lpTemp->line );
	    _ffree( lpTemp );
	}

    _ffree( lpAnchor->line );
    _ffree( lpAnchor );
    lpAnchor = NULL;
    }

    return;
}
