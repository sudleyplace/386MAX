// TOOLBOX.C
// Copyright (c) 1995 Rex C. Conn for Qualitas Inc.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <dos.h>
#include <io.h>

#include "toolbox.h"

#include <shellapi.h>
#include <dosmax.h>

    // define message variables
#define SETUP_MSG_DEFVARS 1
#include "messages.h"

#define PCH char _far *

#define LCLDRV_GETBUFADDR               0x0800
#define LCLDRV_REGISTER                 0x0801
#define LCLDRV_UNREGISTER               0x0802
#define LCLDRV_QUERYCLOSE               0x0803
#define LCLDRV_QUERYENABLE              0x0804
#define LCLDRV_QUERYINSTALL             0x0805
#define LCLDRV_QUERYLOWSEG              0x0806
#define LCLDRV_DISABLE                  0x0807
#define LCLDRV_ENABLE                   0x0808
#define FILENAME "goahead"
#define FILENAMEXT FILENAME ".drv"

int nCountry=1;
char *szUSStartupGroup = "Startup";
char *szDEStartupGroup = "AutoStart";
char szStartupGroup[ 80 ];

    // work buffer
#define WBLEN _MAX_PATH
char szWork[ WBLEN + 1 ];

LPSTR pszGALoadClear = "GALoadClear";
LPSTR pszGADialog = "GADialog";
char szDrvName[] = FILENAMEXT;

char szStrip31[] = "stripmgr.pif";
char szStrip95[] = "stripm95.pif";
char szStripPIF[ 20 ];

void WalkWindowList( void );
LRESULT CALLBACK _export SubdialogCallback(HWND, int, UINT, WPARAM, LPARAM);
static BOOL TabDlg_Do(void);
BOOL CALLBACK __export AboutDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitMaximizeDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitRestartDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ExitRebootDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ModelessDlgProc(HWND, UINT, WPARAM, LPARAM);
BOOL CALLBACK __export ConflictDlgProc(HWND, UINT, WPARAM, LPARAM);

void ReadMultiConfig(void);
void CheckForMax( void );
void StripConfigSys( char *, char * );
int ModifyAutoexec(char *, int);
void ModifyPro( char *, char *, int );
char * ParsePro(char *, char *);
void ParseProRAM( void );
void ParseProUSE( char * );
int CheckForConflicts( HWND );
void WriteMaximizeINI( void );

void SetBusy(void);
void ClearBusy(void);
void WritePrivateProfileInt(char *, char *, int);
int QueryGoAhead(void);
void DeleteDOSMAXKeys( void );

// Instance data structure for each subdialog
typedef struct tagDLGDATA
{
	HWND hDlg;                       // Its own window handle
	// Add more instance data here
	BOOL fModif;                        // data has been modified    
} DLGDATA, NEAR * PDLGDATA, NEAR * NPDLGDATA, FAR * LPDLGDATA;


// Instance data pointer access functions
# define Dialog_GetPtr(hwnd)          (PDLGDATA)(UINT)GetWindowLong((hwnd), DWL_USER)
# define Dialog_SetPtr(hwnd, pDlg)    SetWindowLong((hwnd), DWL_USER, (LONG)(LPDLGDATA)(pDlg))

#define TABS    4

HINSTANCE ghInstance;
HINSTANCE ghToolhelp;
HWND	hModeless;			// handle to general purpose modeless dialog


BOOL	fMaxLoaded = 0;
BOOL	fMaximize = 0;
BOOL	fRestartWindows = 0;
BOOL	fReboot = 0;
BOOL	fEvap = 0;

BOOL	bROMNotSearched = 0;

struct {
	// Startup page
	BOOL	bStartUp95;
	BOOL	bMAXMeter;
	BOOL	bGoAhead;
	BOOL	bDOSMax;
	BOOL	bDOSStacks;
	BOOL	bExtraDOS;
	BOOL	bQMT;

	// Video/Adapters page
	BOOL	bMDA;
	BOOL	bVGASwap;
	BOOL	bROMSrch;
	char	szUseRAM[1024];

	// DPMI page
	BOOL	bDPMI;
	BOOL	bDPMISwap;
	char	szDPMISwapfile[80];
	int	uDPMISwapSize;
	BOOL	bEMS;
	char    szPageFrame[12];
} TBStart, TBEnd;


BOOL	bWin95 = 0;
BOOL	bStripMM = 0;
BOOL	bStripLH = 0;
BOOL	bUninstalling = 0;
BOOL	bRemoveMaxFiles = 0;
BOOL	bRemoveINIEntries = 0;
BOOL	bRemoveINIFile = 0;
BOOL	bRemoveMaxGroup = 0;
BOOL	bRemoveMaxDir = 0;

UINT 	uRAMStart = 0xA000;
UINT	uRAMEnd = 0xA100;

char	szStripMMSection[128];
char	szStripLHSection[128];
char	szSections[4096];

char	szHelpName[80];
char	szIniName[80];

    // maximize.ini stuff
char	*szMaxIniName="maximize.ini";
char    *szDefault="Defaults";
char    *szRemove="Remove";
char    *szCustom="Custom";
char    *szROMSrch="ROMSrch";
char    *szVGASwap="VGASwap";
char    *szExtraDOS="ExtraDOS";
char	szMaxIniPath[ _MAX_PATH + 1 ];

char    szConfigSys[] = "c:\\config.sys";
char	szAutoexec[] = "c:\\autoexec.bat";
char	szCurrentSection[80];
char	szCurrentDescription[256];
char	szMaxDir[80] = "c:\\qmax";
char	szMaxPro[80] = "c:\\qmax\\386max.pro";
char	szINISection[] = "Toolbox";
char    szTBDlgClass[] = "TBDialogClass";

char	szSystemIni[128];
char	szWinIni[128];
char	szWindowsDir[_MAX_PATH+1];
char	szWindowsSystemDir[_MAX_PATH+1];

char	szConflict1[32];
char	szConflict2[32];

#define ADD 1
#define ADD_STRING 2
#define ADD_APPEND 4
#define DELETE 8
#define DELETE_STRING 0x10
#define DELETE_ROMSEARCH 0x20


int PASCAL WinMain(HANDLE hInstance, HANDLE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
{
	char szBuf[256];
	DWORD dwVersion;
	int i;

	dwVersion = GetVersion();
	if (((dwVersion & 0xFF) >= 4) || (((dwVersion >> 8) & 0xFF) >= 50)) {
		bWin95 = 1;
    }
        // adjust for new pif format
    if ( bWin95 ) {
        _fstrcpy( szStripPIF, szStrip95 );
    } else {
        _fstrcpy( szStripPIF, szStrip31 );
    }

	memset( &TBStart, '\0', sizeof(TBStart) );

	if (hPrevInstance) {
		WalkWindowList( );
		return 1;
	}

	// load CTL3DV2
	if ((!Ctl3dRegister(hInstance)) || (!Ctl3dAutoSubclass(hInstance)))
		return 1;

	ghInstance = hInstance;

	// get the Windows directories
	GetWindowsDirectory( szWindowsDir, _MAX_PATH );
	GetSystemDirectory( szWindowsSystemDir, _MAX_PATH );
	MakePath( szWindowsDir, "SYSTEM.INI", szSystemIni );
	MakePath( szWindowsDir, "WIN.INI", szWinIni );

	// set .INI name
	i = GetWindowsDirectory( szIniName, 80 );
	if (i && szIniName[i - 1] != '\\')
		lstrcat( szIniName, "\\" );
	lstrcat( szIniName, "QMAX.INI" );

	GetPrivateProfileString( "CONFIG", "Qualitas MAX Path", "c:\\qmax", szMaxDir, 80, szIniName );
#ifdef VER2
	if (szMaxDir[0] == '\0') {
		MessageBox( 0, szMsg_INICorrupt, szMsg_Title, MB_OK | MB_ICONSTOP );
		goto ExitToolbox;
	}
#endif
	GetPrivateProfileString( "CONFIG", "Qualitas MAX Help", "maxhelp.hlp", szBuf, 80, szIniName );
	MakePath( szMaxDir, szBuf, szHelpName );

    MakePath( szMaxDir, szMaxIniName, szMaxIniPath );

        // special case German startup group.
    nCountry = GetProfileInt( (LPSTR)"intl", (LPSTR)"iCountry", nCountry );
    if( nCountry == 49 ) {
        _fstrcpy( szStartupGroup, szDEStartupGroup );
    } else {
        _fstrcpy( szStartupGroup, szUSStartupGroup );
    }

	InitDDE( );

	// read CONFIG.SYS for section names
	ReadMultiConfig();
	CheckForMax();

	// We don't have a main window; we use the dialog as the window
	TabDlg_Do();

	EndDDE( );

	Ctl3dUnregister(hInstance);

	if (fMaximize) {
        
		MakePath( szMaxDir, "winmaxim.exe /I", szBuf );
		WinExec(szBuf, SW_SHOW);

	} else if (fRestartWindows) {
		ExitWindows( EW_RESTARTWINDOWS, 0 );

    } else if ( fEvap ) {

        if ( !bWin95 ) {
            
            if ( bRemoveMaxDir )
                wsprintf(szBuf, "%s\\evap.exe /S /X %s\\*.*", szMaxDir, szMaxDir );
            else
                wsprintf(szBuf, "%s\\evap.exe %s\\*.*", szMaxDir, szMaxDir );

            WinExec( szBuf, SW_HIDE );
        }
        else {
            if ( bRemoveMaxDir )
                wsprintf(szBuf, "/S /X %s\\*.*", szMaxDir );
            else
                wsprintf(szBuf, "%s\\*.*", szMaxDir );

            del_cmd( szBuf );
        }
    }

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
			if (lstrcmpi(szModuleName, "Toolbox") == 0) {
				SetWindowPos( hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW );
				SetFocus( hWnd );
				break;
			}
		}

		hWnd = GetWindow(hWnd, GW_HWNDNEXT);	// Go on to next window
	}
}


void InitStartup(HWND hDlg)
{
	static int fInit = 0;
	char szBuf[256];

	if (fInit == 0) {

		// check to see if they've removed their StartUp directory
		//   and put it on the desktop!
		if (bWin95) {
            wsprintf( (LPSTR)szWork, (LPSTR)"desktop\\%s", (LPSTR)szStartupGroup );
			MakePath( szWindowsDir, szWork, szBuf );
			if (QueryFileExists( szBuf ))
				TBStart.bStartUp95 = 1;
		}

		if ((TBStart.bStartUp95) || ((TBStart.bMAXMeter = pmQueryGroup( szStartupGroup, "MAXmeter" )) == 0)) {
            wsprintf( (LPSTR)szWork, (LPSTR)"desktop\\%s\\maxmeter.exe", (LPSTR)szStartupGroup );
			MakePath( szWindowsDir, szWork, szBuf );
			TBStart.bMAXMeter = QueryFileExists( szBuf );
		}

		TBStart.bGoAhead = QueryGoAhead();

		GetPrivateProfileString( "Qualitas", "DOSMAX", "ON", szBuf, 255, szSystemIni );
		TBStart.bDOSMax = (lstrcmpi( szBuf, "off" ) != 0);

		TBStart.bExtraDOS = (ParsePro( szConfigSys, "extrados.max" ) != NULL);
		TBStart.bDOSStacks = (ParsePro( szMaxPro, "Stacks=0") == NULL);

		TBStart.bQMT = (ParsePro(szAutoexec, "qmt") != NULL);
		if (TBStart.bQMT == 0)
			TBStart.bQMT = (ParsePro(szAutoexec, "qutil") != NULL);
		fInit++;
		return;
	}

	CheckDlgButton(hDlg, IDC_QMT, TBEnd.bQMT);

	CheckDlgButton(hDlg, IDC_EXTRADOS, TBEnd.bExtraDOS);
	CheckDlgButton(hDlg, IDC_STACKS, TBEnd.bDOSStacks);

	CheckDlgButton(hDlg, IDC_MAXMETER, TBEnd.bMAXMeter);
	CheckDlgButton(hDlg, IDC_DOSMAX, TBEnd.bDOSMax );

	CheckDlgButton(hDlg, IDC_MAXRAM, ( bWin95 ) ? 0 : TBEnd.bGoAhead);
    if( bWin95 ) {
        EnableWindow( GetDlgItem( hDlg, IDC_MAXRAM ), !bWin95 );
    }

	EnableWindow( GetDlgItem( hDlg, IDC_EXTRADOS), fMaxLoaded );
	EnableWindow( GetDlgItem( hDlg, IDC_STACKS), fMaxLoaded );
	EnableWindow( GetDlgItem( hDlg, IDC_DOSMAX), fMaxLoaded );
}


void InitVideo(HWND hDlg)
{
	static int fInit = 0, fNoVGA = 0, fROMSrch = 0;
	int i;
	char *ptr, szBuf[128];

	if (fInit == 0) {

		TBStart.bMDA = (ParsePro( szMaxPro, "use=b000-b800" ) != NULL);
		MakePath( szMaxDir, "maximize.cfg", szBuf );
#ifdef OLDVER
		if (ParsePro( szBuf, "NOVGASWAP" ) != NULL)
			fNoVGA = 1;
		else
#endif
		TBStart.bVGASwap = (ParsePro( szMaxPro, "VGASWAP" ) != NULL);

		if ((ParsePro( szMaxPro, "use=E" ) != NULL) || (ParsePro( szMaxPro, "use=F" ) != NULL ))
			TBStart.bROMSrch = 1;
		else if (ParsePro( szBuf, "NOROMSRCH" ) == NULL)
			bROMNotSearched = 1;

		// read existing RAM= from 386MAX.PRO
		ParseProRAM();

		fInit = 1;
		return;
	}

	CheckDlgButton( hDlg, IDC_MDA, TBEnd.bMDA );
	CheckDlgButton( hDlg, IDC_VGASWAP, TBEnd.bVGASwap );
	CheckDlgButton( hDlg, IDC_ROMSEARCH, TBEnd.bROMSrch );

	EnableWindow( GetDlgItem( hDlg, IDC_REMOVERAM), FALSE );

	wsprintf( szBuf, "%x", uRAMStart);
	AnsiUpper( szBuf );
	SetDlgItemText( hDlg, IDC_RAMEDITSTART, szBuf );
	wsprintf( szBuf, "%x", uRAMEnd);
	AnsiUpper( szBuf );
	SetDlgItemText( hDlg, IDC_RAMEDITEND, szBuf );

	for (ptr = TBEnd.szUseRAM; (*ptr != '\0'); ptr += i) {
		i = 0;
		sscanf( ptr, "%[^|]|%n", szBuf, &i );
		SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_ADDSTRING, 0, (LONG)(char *)szBuf);
	}


	if (fMaxLoaded == 0) {
		for (i = IDD_HIGHDOS; (i <= IDC_RAMLIST); i++)
			EnableWindow( GetDlgItem( hDlg, i), FALSE );
	}
}


void InitDPMI(HWND hDlg)
{
	static int fInit = 0;
	char *arg, *ptr, szBuffer[32];
	unsigned int n, uStart, uEnd, uFrameStart, uFrameEnd;

	if (fInit == 0) {

		TBStart.uDPMISwapSize = 8192;

		if ((ptr = ParsePro( szMaxPro, "swapfile" )) != NULL) {

			TBStart.bDPMISwap = 1;
			if ((arg = ntharg( ptr, 1 )) != NULL)
				lstrcpy( TBStart.szDPMISwapfile, arg );
			for (n = 2; ((arg = ntharg( ptr, n )) != NULL); n++) {
				if ((lstrcmpi( arg, "/s" ) == 0) && ((arg = ntharg( ptr, n+1 )) != NULL)) {
					sscanf( arg, "%u", &(TBStart.uDPMISwapSize) );
					break;
				}
			}
			lstrcpy( TBEnd.szDPMISwapfile, TBStart.szDPMISwapfile );
			TBEnd.uDPMISwapSize = TBStart.uDPMISwapSize;

		} else
			MakePath( szMaxDir, "386MAX.SWP", TBStart.szDPMISwapfile );
		lstrcpy( TBEnd.szDPMISwapfile, TBStart.szDPMISwapfile );
			
		TBStart.bDPMI = (ParsePro( szMaxPro, "NODPMI" ) == NULL);

		// if using EMS already, check the control
		TBStart.bEMS = (ParsePro( szMaxPro, "EMS=0" ) == NULL);
		if (((ptr = ParsePro( szMaxPro, "FRAME" )) != NULL) && ((ptr = ntharg( ptr, 1 )) != NULL))
			lstrcpy( TBStart.szPageFrame, ptr );
		else if ((ptr = ParsePro( szMaxPro, "NOFRAME" )) != NULL)
			lstrcpy( TBStart.szPageFrame, ptr );
		else
			lstrcpy( TBStart.szPageFrame, "AUTO" );

		lstrcpy( TBEnd.szPageFrame, TBStart.szPageFrame );
		fInit = 1;
		return;
	}

	CheckDlgButton( hDlg, IDC_DPMI, TBEnd.bDPMI );

	EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAP), TBEnd.bDPMI );

	CheckDlgButton( hDlg, IDC_DPMISWAP, TBEnd.bDPMISwap );

	if (fMaxLoaded) {
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPFILE), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPSIZE), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPFILETEXT), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPSIZETEXT), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPKBTEXT), TBEnd.bDPMISwap );
	}

	SetDlgItemText( hDlg, IDC_DPMISWAPFILE, TBEnd.szDPMISwapfile);
	wsprintf( szBuffer, "%u", TBEnd.uDPMISwapSize );
	SetDlgItemText( hDlg, IDC_DPMISWAPSIZE, szBuffer);

	CheckDlgButton( hDlg, IDC_EMS, TBEnd.bEMS );

	if (fMaxLoaded) {
		EnableWindow( GetDlgItem( hDlg, IDC_EMSFRAME), TBEnd.bEMS );
		EnableWindow( GetDlgItem( hDlg, IDC_EMSFRAMETEXT), TBEnd.bEMS );
	}
	SendDlgItemMessage( hDlg, IDC_EMSFRAME, CB_ADDSTRING, 0, (LONG)(PCH)"AUTO");
	SendDlgItemMessage( hDlg, IDC_EMSFRAME, CB_ADDSTRING, 0, (LONG)(PCH)"NOFRAME");

	for (uFrameStart = 0xC800; (uFrameStart <= 0xE000); uFrameStart += 0x400) {

		uFrameEnd = uFrameStart + 0x1000;

		// make sure there's no RAM= overlap
		for (ptr = TBEnd.szUseRAM; (*ptr != '\0'); ptr += n) {

			uStart = uEnd = n = 0;
			sscanf( ptr, "%x-%x |%n", &uStart, &uEnd, &n );

			if ((uStart >= uFrameStart) && (uStart < uFrameEnd))
				break;

			if ((uEnd > uFrameStart) && (uEnd <= uFrameEnd))
				break;

			if ((uStart < uFrameStart) && (uEnd > uFrameStart))
				break;
		}

		if (*ptr == '\0') {
			wsprintf( szBuffer, "%x", uFrameStart );
			AnsiUpper( szBuffer );
			SendDlgItemMessage( hDlg, IDC_EMSFRAME, CB_ADDSTRING, 0, (LONG)(PCH)szBuffer);
		}
	}

	n = (int)SendDlgItemMessage( hDlg, IDC_EMSFRAME, CB_FINDSTRINGEXACT, (WPARAM)-1, (LPARAM)(PCH)TBEnd.szPageFrame );
	SendDlgItemMessage( hDlg, IDC_EMSFRAME, CB_SETCURSEL, n, 0L );

	if (fMaxLoaded == 0) {
		for (n = IDD_DPMI; (n <= IDC_EMSFRAME); n++)
			EnableWindow( GetDlgItem( hDlg, n), FALSE );
	}
}


void InitUninstall( HWND hDlg )
{
	static int fInit = 0;
	int n;
	register char *arg;
	char szBuf[256], szCSection[128];

	if (fInit == 0) {
		fInit = 1;
		return;
	}

	// if not multiconfig, gray all of the relevant entries
	if (szSections[0] == '\0') {

		EnableWindow( GetDlgItem( hDlg, 401), FALSE );
		EnableWindow( GetDlgItem( hDlg, IDC_STRIPMMSECTION), FALSE );
		EnableWindow( GetDlgItem( hDlg, IDC_STRIPLHSECTION), FALSE );

		szStripMMSection[0] = '\0';
		szStripLHSection[0] = '\0';

	} else {

		EnableWindow( GetDlgItem( hDlg, 401), TRUE );
		EnableWindow( GetDlgItem( hDlg, IDC_STRIPMMSECTION ), bStripMM );
		EnableWindow( GetDlgItem( hDlg, IDC_STRIPLHSECTION ), bStripLH );

		// load section descriptions into combo box
		for (n = 0, arg = szSections; (*arg != '\0'); n++) {

			szBuf[0] = '\0';
			sscanf( arg, "%[^ ,\n]%*[ ,]%255[^\n]", szCSection, szBuf );
			while (*arg++ != '\n')
				;

			if (szBuf[0] == '\0')
				lstrcpy(szBuf, szCSection);

			SendDlgItemMessage(hDlg, IDC_STRIPMMSECTION, CB_ADDSTRING, 0, (LONG)(char *)szBuf);
			SendDlgItemMessage(hDlg, IDC_STRIPLHSECTION, CB_ADDSTRING, 0, (LONG)(char *)szBuf);

			// check for current section and set edit control
			if (lstrcmpi( szCSection, szCurrentSection ) == 0) {
				SendDlgItemMessage( hDlg, IDC_STRIPMMSECTION, CB_SETCURSEL, n, 0L);
				SendDlgItemMessage( hDlg, IDC_STRIPLHSECTION, CB_SETCURSEL, n, 0L);
				lstrcpy( szStripMMSection, szCSection );
				lstrcpy( szStripLHSection, szCSection );
			}
		}
	}

	CheckDlgButton(hDlg, IDC_STRIPMM, bStripMM);
	CheckDlgButton(hDlg, IDC_STRIPLH, bStripLH);
	CheckDlgButton(hDlg, IDC_REMOVEMAX, bRemoveMaxFiles);
	CheckDlgButton(hDlg, IDC_REMOVEINIENTRIES, bRemoveINIEntries);
	CheckDlgButton(hDlg, IDC_REMOVEINIFILE, bRemoveINIFile);
	CheckDlgButton(hDlg, IDC_REMOVEMAXGROUP, bRemoveMaxGroup);
	CheckDlgButton(hDlg, IDC_REMOVEMAXDIR, bRemoveMaxDir);
}


void ProcessStartup( HWND hDlg, UINT uMsg, WORD wParam, DWORD lParam )
{
	switch (LOWORD(wParam)) {
	case IDC_DOSMAX:
		TBEnd.bDOSMax = IsDlgButtonChecked(hDlg, IDC_DOSMAX);
		if ((TBEnd.bDOSStacks == 0) && (TBEnd.bDOSMax)) {
			if (MessageBox(hDlg, szMsg_StksHi, szMsg_DOSMAX, MB_YESNO | MB_ICONSTOP ) == IDYES ) {
				TBEnd.bDOSStacks = 1;
				CheckDlgButton( hDlg, IDC_STACKS, TBEnd.bDOSStacks );
			} else {
				TBEnd.bDOSMax = 0;
				CheckDlgButton( hDlg, IDC_DOSMAX, TBEnd.bDOSMax );
			}
		}
		break;

	case IDC_MAXMETER:
		TBEnd.bMAXMeter = IsDlgButtonChecked(hDlg, IDC_MAXMETER);
		break;

	case IDC_MAXRAM:
		TBEnd.bGoAhead = IsDlgButtonChecked(hDlg, IDC_MAXRAM);
		break;

	case IDC_EXTRADOS:
		TBEnd.bExtraDOS = IsDlgButtonChecked(hDlg, IDC_EXTRADOS);
		break;

	case IDC_STACKS:
		TBEnd.bDOSStacks = IsDlgButtonChecked(hDlg, IDC_STACKS);
		if ((TBEnd.bDOSStacks == 0) && (TBEnd.bDOSMax)) {
			if (MessageBox(hDlg, szMsg_NoStks, szMsg_Stacks, MB_OKCANCEL | MB_ICONSTOP ) == IDOK ) {
				TBEnd.bDOSMax = 0;
				CheckDlgButton( hDlg, IDC_DOSMAX, TBEnd.bDOSMax );
			} else {
				TBEnd.bDOSStacks = 1;
				CheckDlgButton( hDlg, IDC_STACKS, TBEnd.bDOSStacks );
			}
		}
		break;

	case IDC_QMT:
		TBEnd.bQMT = IsDlgButtonChecked(hDlg, IDC_QMT);
	}
}


void ProcessVideo( HWND hDlg, UINT uMsg, WORD wParam, DWORD lParam )
{
	register int i, j, n;
	char szStart[16], szEnd[16], szBuffer[64];
	HWND hWnd;

	switch (uMsg) {
	case WM_VSCROLL:
		hWnd = (HWND)HIWORD(lParam);
		if (hWnd == GetDlgItem( hDlg, IDC_RAMSCROLLSTART)) {

			if (wParam == SB_LINEDOWN) {
				if (uRAMStart > 0xA000)
					uRAMStart -= 0x100;
			} else if (wParam == SB_LINEUP) {
				if (uRAMStart < 0xF700)
					uRAMStart += 0x100;
			} else
				break;

			wsprintf( szStart, "%x", uRAMStart);
			AnsiUpper( szStart );
			SetDlgItemText( hDlg, IDC_RAMEDITSTART, szStart );

			if (uRAMEnd <= uRAMStart) {
				uRAMEnd = uRAMStart + 0x100;
				wsprintf( szEnd, "%x", uRAMEnd);
				AnsiUpper( szEnd );
				SetDlgItemText( hDlg, IDC_RAMEDITEND, szEnd );
			}

		} else if (hWnd == GetDlgItem( hDlg, IDC_RAMSCROLLEND)) {

			if (wParam == SB_LINEDOWN) {
				if ((uRAMEnd > (uRAMStart + 0x100)) && (uRAMEnd > 0xA100))
					uRAMEnd -= 0x100;
			} else if (wParam == SB_LINEUP) {
				if (uRAMEnd < 0xF800)
					uRAMEnd += 0x100;
			} else
				break;
			wsprintf( szEnd, "%x", uRAMEnd);
			AnsiUpper( szEnd );
			SetDlgItemText( hDlg, IDC_RAMEDITEND, szEnd );
		}
		break;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_MDA:
			TBEnd.bMDA = IsDlgButtonChecked(hDlg, IDC_MDA);
			if ((TBEnd.bMDA == 0) && (TBEnd.bVGASwap)) {
				if (MessageBox(hDlg, szMsg_VGAMDA, szMsg_UseMDA, MB_YESNO | MB_ICONSTOP ) == IDYES ) {
					TBEnd.bVGASwap = 0;
					CheckDlgButton( hDlg, IDC_VGASWAP, TBEnd.bVGASwap );
				} else {
					TBEnd.bMDA = 1;
					CheckDlgButton( hDlg, IDC_MDA, TBEnd.bMDA );
				}
			}
			break;

		case IDC_VGASWAP:
			TBEnd.bVGASwap = IsDlgButtonChecked(hDlg, IDC_VGASWAP);
			if ((TBEnd.bVGASwap) && (TBEnd.bMDA == 0)) {
				TBEnd.bMDA = 1;
				CheckDlgButton( hDlg, IDC_MDA, TBEnd.bMDA );
			}
			break;

		case IDC_ROMSEARCH:
			TBEnd.bROMSrch = IsDlgButtonChecked(hDlg, IDC_ROMSEARCH);
			break;

		case IDC_ADDRAM:
			GetDlgItemText( hDlg, IDC_RAMEDITSTART, szStart, 8 );
			GetDlgItemText( hDlg, IDC_RAMEDITEND, szEnd, 8 );
			wsprintf( szBuffer, "%s-%s", szStart, szEnd );

			// make sure it isn't already in the list!
			if (SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_FINDSTRING, 0, (LONG)szBuffer) == LB_ERR) {
				SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_ADDSTRING, 0, (LONG)szBuffer);
				lstrcat( TBEnd.szUseRAM, szBuffer );
				lstrcat( TBEnd.szUseRAM, "|" );
			}
			break;

		case IDC_REMOVERAM:
			i = (int)SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_GETCOUNT, 0, 0L);
			for (j = i; (--i >= 0); ) {
				if (SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_GETSEL, i, 0L) != 0) {
					SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_GETTEXT, i, (LONG)szBuffer);
					n = FindString( TBEnd.szUseRAM, szBuffer );
					lstrcpy( TBEnd.szUseRAM + n, TBEnd.szUseRAM + n + lstrlen( szBuffer) + 1 );
					SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_DELETESTRING, i, 0L);
					j--;
					if (j == 0)
						EnableWindow( GetDlgItem( hDlg, IDC_REMOVERAM), FALSE );
				}
			}

			break;
		}

		if (LOWORD(lParam) == GetDlgItem( hDlg, IDC_RAMLIST )) {
			if (SendDlgItemMessage(hDlg, IDC_RAMLIST, LB_GETSELCOUNT, i, 0L) > 0)
				EnableWindow( GetDlgItem( hDlg, IDC_REMOVERAM), TRUE );
			else
				EnableWindow( GetDlgItem( hDlg, IDC_REMOVERAM), FALSE );
		}
	}
}


void ProcessDPMI( HWND hDlg, UINT uMsg, WORD wParam, DWORD lParam )
{
	int n;
	char szBuffer[16];

	switch (LOWORD(wParam)) {
	case IDC_DPMI:
		TBEnd.bDPMI = IsDlgButtonChecked(hDlg, IDC_DPMI);
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAP), TBEnd.bDPMI );
		if (TBEnd.bDPMI)
			break;
		CheckDlgButton( hDlg, IDC_DPMISWAP, 0 );

	case IDC_DPMISWAP:
		TBEnd.bDPMISwap = IsDlgButtonChecked(hDlg, IDC_DPMISWAP);
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPFILE), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPSIZE), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPFILETEXT), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPSIZETEXT), TBEnd.bDPMISwap );
		EnableWindow( GetDlgItem( hDlg, IDC_DPMISWAPKBTEXT), TBEnd.bDPMISwap );
		break;

	case IDC_EMS:
		TBEnd.bEMS = IsDlgButtonChecked(hDlg, IDC_EMS);
		EnableWindow( GetDlgItem( hDlg, IDC_EMSFRAME), TBEnd.bEMS );
		EnableWindow( GetDlgItem( hDlg, IDC_EMSFRAMETEXT), TBEnd.bEMS );
		break;

	case IDC_DPMISWAPFILE:
		if ((TBEnd.bDPMISwap) && (HIWORD(lParam) == EN_CHANGE))
			GetDlgItemText(hDlg, IDC_DPMISWAPFILE, TBEnd.szDPMISwapfile, sizeof(TBEnd.szDPMISwapfile));
		break;

	case IDC_DPMISWAPSIZE:
		if ((TBEnd.bDPMISwap) && (HIWORD(lParam) == EN_CHANGE)) {
			GetDlgItemText(hDlg, IDC_DPMISWAPSIZE, szBuffer, sizeof(szBuffer));
			TBEnd.uDPMISwapSize = atoi(szBuffer);
		}
		break;

	case IDC_EMSFRAME:
		// see if we've just selected a new entry
		if ((HIWORD(lParam) == CBN_SELENDOK) && (TBEnd.bEMS)) {
			n = (int)SendDlgItemMessage(hDlg, IDC_EMSFRAME, CB_GETCURSEL, 0, 0L);
			SendDlgItemMessage(hDlg, IDC_EMSFRAME, CB_GETLBTEXT, n, (LPARAM)(LPSTR)TBEnd.szPageFrame );
		}
	}
}


void ProcessUninstall( HWND hDlg, UINT uMsg, WORD wParam, DWORD lParam )
{
	char *arg, szBuffer[256], szDescription[256];

	switch (LOWORD(wParam)) {
	case IDC_STRIPMM:
		bStripMM = IsDlgButtonChecked(hDlg, IDC_STRIPMM);
		if (szSections[0])
			EnableWindow( GetDlgItem( hDlg, IDC_STRIPMMSECTION), bStripMM );
		break;

	case IDC_STRIPLH:
		bStripLH = IsDlgButtonChecked(hDlg, IDC_STRIPLH);
		if (szSections[0])
			EnableWindow( GetDlgItem( hDlg, IDC_STRIPLHSECTION), bStripLH );
		break;

	case IDC_REMOVEMAX:
		bRemoveMaxFiles = IsDlgButtonChecked(hDlg, IDC_REMOVEMAX);

		// check all the other boxes
		CheckDlgButton(hDlg, IDC_STRIPMM, bRemoveMaxFiles);
		bStripMM = bRemoveMaxFiles;
        EnableWindow( GetDlgItem( hDlg, IDC_STRIPMMSECTION), bStripMM );
		CheckDlgButton(hDlg, IDC_STRIPLH, bRemoveMaxFiles);
		bStripLH = bRemoveMaxFiles;
        EnableWindow( GetDlgItem( hDlg, IDC_STRIPLHSECTION), bStripLH );
		CheckDlgButton(hDlg, IDC_REMOVEINIENTRIES, bRemoveMaxFiles);
		bRemoveINIEntries = bRemoveMaxFiles;
		CheckDlgButton(hDlg, IDC_REMOVEINIFILE, bRemoveMaxFiles);
		bRemoveINIFile = bRemoveMaxFiles;
		CheckDlgButton(hDlg, IDC_REMOVEMAXGROUP, bRemoveMaxFiles);
		bRemoveMaxGroup = bRemoveMaxFiles;
		break;

	case IDC_REMOVEINIENTRIES:
		bRemoveINIEntries = IsDlgButtonChecked(hDlg, IDC_REMOVEINIENTRIES);
		break;

	case IDC_REMOVEINIFILE:
		bRemoveINIFile = IsDlgButtonChecked(hDlg, IDC_REMOVEINIFILE);
		break;

	case IDC_REMOVEMAXGROUP:
		bRemoveMaxGroup = IsDlgButtonChecked(hDlg, IDC_REMOVEMAXGROUP);
		break;

	case IDC_REMOVEMAXDIR:
		bRemoveMaxDir = IsDlgButtonChecked(hDlg, IDC_REMOVEMAXDIR);

		// check all the other boxes
		CheckDlgButton(hDlg, IDC_STRIPMM, bRemoveMaxDir);
		bStripMM = bRemoveMaxDir;
        EnableWindow( GetDlgItem( hDlg, IDC_STRIPMMSECTION), bStripMM );
		CheckDlgButton(hDlg, IDC_STRIPLH, bRemoveMaxDir);
		bStripLH = bRemoveMaxDir;
        EnableWindow( GetDlgItem( hDlg, IDC_STRIPLHSECTION), bStripLH );
		CheckDlgButton(hDlg, IDC_REMOVEINIENTRIES, bRemoveMaxDir);
		bRemoveINIEntries = bRemoveMaxDir;
		CheckDlgButton(hDlg, IDC_REMOVEINIFILE, bRemoveMaxDir);
		bRemoveINIFile = bRemoveMaxDir;
		CheckDlgButton(hDlg, IDC_REMOVEMAXGROUP, bRemoveMaxDir);
		bRemoveMaxGroup = bRemoveMaxDir;
		CheckDlgButton(hDlg, IDC_REMOVEMAX, TRUE);
		bRemoveMaxFiles = 1;
		break;

	case IDC_STRIPMMSECTION:
		GetDlgItemText( hDlg, IDC_STRIPMMSECTION, szDescription, 255 );
		szStripMMSection[0] = '\0';
		for (arg = szSections; (*arg != '\0'); ) {
			szBuffer[0] = '\0';
			sscanf( arg, "%[^ ,\n]%*[ ,]%255[^\n]", szStripMMSection, szBuffer );
			while (*arg++ != '\n')
				;
			if (szBuffer[0] == '\0')
				lstrcpy(szBuffer, szStripMMSection);
			if (lstrcmpi( szBuffer, szDescription ) == 0)
				break;
		}
		break;

	case IDC_STRIPLHSECTION:
		GetDlgItemText( hDlg, IDC_STRIPLHSECTION, szDescription, 255 );
		szStripLHSection[0] = '\0';
		for (arg = szSections; (*arg != '\0'); ) {
			szBuffer[0] = '\0';
			sscanf( arg, "%[^ ,\n]%*[ ,]%255[^\n]", szStripLHSection, szBuffer );
			while (*arg++ != '\n')
				;
			if (szBuffer[0] == '\0')
				lstrcpy(szBuffer, szStripLHSection );
			if (lstrcmpi( szBuffer, szDescription ) == 0)
				break;
		}
	}

	// if anything selected in Uninstall tab, disable all other tabs
	if ((bStripMM) || (bStripLH) || (bRemoveMaxFiles) || (bRemoveMaxGroup) || (bRemoveINIEntries) || (bRemoveINIFile) || (bRemoveMaxDir))
		bUninstalling = 1;
	else
		bUninstalling = 0;

	DlgTabbedDlg_Enable( hDlg, IDD_STARTUP, (bUninstalling == 0) );
	DlgTabbedDlg_Enable( hDlg, IDD_HIGHDOS, (bUninstalling == 0) );
	DlgTabbedDlg_Enable( hDlg, IDD_DPMI, (bUninstalling == 0) );
}


void SaveStartup(HWND hDlg)
{
	char *arg, szBuf[512], szTemp[512];
	int n;

	if (bUninstalling)
		return;

	// if no MAXIMIZE.CFG, create it with defaults
	MakePath( szMaxDir, "maximize.cfg", szBuf );
	if (QueryFileExists( szBuf ) == 0) {
	    ModifyPro( szBuf, "NOEXTRADOS", ADD );
	    ModifyPro( szBuf, "NOROMSRCH", ADD );
	    ModifyPro( szBuf, "NOVGASWAP", ADD );
	}

	if (TBStart.bExtraDOS != TBEnd.bExtraDOS) {

	    fMaximize = 1;
	    if (TBEnd.bExtraDOS == 0) {
		// remove Device=extrados.max from CONFIG.SYS
		StripConfigSys( "device", "ExtraDOS.max" );
		// remove install=extrados.max from CONFIG.SYS
		StripConfigSys( "install", "ExtraDOS.max" );
	    }
	    MakePath( szMaxDir, "maximize.cfg", szBuf );
	    ModifyPro( szBuf, "NOEXTRADOS", ((TBEnd.bExtraDOS != 0) ? DELETE : ADD) );
	}

// FIXME - insert ExtraDOS lines?

	if (TBStart.bDOSStacks != TBEnd.bDOSStacks) {

	    fMaximize = 1;
	    if (TBEnd.bDOSStacks) {
		ModifyPro( szMaxPro, "Stacks", DELETE );
		WritePrivateProfileString( "Qualitas", "DOSMAX", "Off", szSystemIni );
	    } else {
		ModifyPro( szMaxPro, "Stacks=0", ADD );
		ModifyPro( szMaxPro, "STACKREG", DELETE );
	    }
	}

	if (TBStart.bDOSMax != TBEnd.bDOSMax) {

	    // Add/Remove QPOPUP.EXE in WIN.INI
	    szBuf[0] = szTemp[0] = '\0';
	    GetProfileString( "windows", "load", "", szBuf, 511 );

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

	    if (TBEnd.bDOSMax) {

		WritePrivateProfileString( "Qualitas", "DOSMAX", NULL, szSystemIni );
		ModifyPro( szMaxPro, "Stacks", DELETE );

		MakePath( szMaxDir, "QPOPUP.EXE", szBuf );
		if (szTemp[0])
			lstrcat(szTemp, " ");
		lstrcat(szTemp, szBuf);

		fRestartWindows = 1;

	    } else {
		// write "DOSMAX=off" if button not checked
		WritePrivateProfileString( "Qualitas", "DOSMAX", "off", szSystemIni );
		if (TBEnd.bDOSStacks == 0)
			ModifyPro( szMaxPro, "Stacks=0", ADD );
		fRestartWindows = 1;
	    }
	    WriteProfileString( "windows", "load", szTemp );
	}

	if (TBStart.bQMT != TBEnd.bQMT) {

	    // remove QMT from AUTOEXEC.BAT
	    if (ModifyAutoexec( "qmt.exe", 1 ) == 0) {
	    	if (ModifyAutoexec( "qmt", 1 ) == 0) {
		    if (ModifyAutoexec( "qutil.bat", 1 ) == 0)
			ModifyAutoexec( "qutil", 1 );
		}
	    }

	    if (TBEnd.bQMT) {
		// Add QMT to beginning of AUTOEXEC.BAT
		MakePath( szMaxDir, "QMT.EXE", szTemp );
		wsprintf( szBuf, "%s quick=1", szTemp );
		ModifyAutoexec( szBuf, 0 );
		fReboot = 1;
	    }
	}

	if (TBStart.bMAXMeter != TBEnd.bMAXMeter) {

	    if (TBStart.bStartUp95) {

        wsprintf( (LPSTR)szWork, (LPSTR)"desktop\\%s\\maxmeter.exe", (LPSTR)szStartupGroup );
		MakePath( szWindowsDir, szWork, szBuf );

		if (TBEnd.bMAXMeter != 0) {
			MakePath( szMaxDir, "maxmeter.exe", szTemp );
			FileCopy( szBuf, szTemp );
			WinExec( szBuf, SW_SHOW );
		} else
			remove( szBuf );

	    } else {

		pmCreateGroup( szStartupGroup, "" );

		// Windows bug - we have to minimize the window first, then
		//   show it, or it won't be activated!
		pmShowGroup(  szStartupGroup, 2 );
		pmShowGroup(  szStartupGroup, 1 );

		if (TBEnd.bMAXMeter != 0) {
			MakePath( szMaxDir, "maxmeter.exe", szTemp );
			pmAddItem( szTemp, "MAXmeter", 0 );
			WinExec( szTemp, SW_SHOW );
		} else
			pmDeleteItem( "MAXmeter" );

		pmShowGroup(  szStartupGroup, 2 );
	    }
	}

	if (TBStart.bGoAhead != TBEnd.bGoAhead) {

	    HDRVR hDriver;

	    fRestartWindows = 1;
	    if (TBStart.bStartUp95) {

        wsprintf( (LPSTR)szWork, (LPSTR)"desktop\\%s\\goahead.exe", (LPSTR)szStartupGroup );
		MakePath( szWindowsDir, szWork, szBuf );

		if (TBEnd.bGoAhead != 0) {

			MakePath( szMaxDir, "goahead.exe", szTemp );
			FileCopy( szBuf, szTemp );

			if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
				SendDriverMessage(hDriver, DRV_INSTALL, 0, 0);
				CloseDriver(hDriver, 0, 0);
			}

		} else {

			// tell driver to uninstall itself
			if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
				SendDriverMessage(hDriver, DRV_REMOVE, 0, 0);
				SendDriverMessage(hDriver, LCLDRV_DISABLE, 0, 0);
				CloseDriver(hDriver, 0, 0);
			}

			remove( szBuf );
		}

	    } else {

		pmCreateGroup(  szStartupGroup, "" );

		// kludge for Windows bug
	        pmShowGroup(  szStartupGroup, 2 );
		pmShowGroup(  szStartupGroup, 1 );
	
		// Add/Remove GOAHEAD in SYSTEM.INI
		if (TBEnd.bGoAhead) {

			MakePath( szMaxDir, "goahead.exe", szTemp );
			// kludge for Windows bug - it always puts icons that
			//   startup up minimized at 0,0!
			pmAddItem( szTemp, "Go Ahead", 0 );
			pmReplaceItem( "Go Ahead" );
			pmAddItem( szTemp, "Go Ahead", 1 );

			if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
				SendDriverMessage(hDriver, DRV_INSTALL, 0, 0);
				SendDriverMessage(hDriver, LCLDRV_ENABLE, 0, 0);
				CloseDriver(hDriver, 0, 0);
			}

		} else {

			// tell driver to uninstall itself
			if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
				SendDriverMessage(hDriver, DRV_REMOVE, 0, 0);
				SendDriverMessage(hDriver, LCLDRV_DISABLE, 0, 0);
				CloseDriver(hDriver, 0, 0);
			}

			pmDeleteItem( "Go Ahead" );
		}

		pmShowGroup(  szStartupGroup, 2 );
	    }
	}
}


void SaveVideo(HWND hDlg)
{
	int n;
	char *arg, szBuf[128];

	if (bUninstalling)
		return;

	if (TBStart.bMDA != TBEnd.bMDA) {

	    fMaximize = 1;
	    if ((TBEnd.bMDA) || (TBEnd.bVGASwap)) {
		ModifyPro( szMaxPro, "USE=B000-B800", ADD_STRING );
		ModifyPro( szMaxPro, "NOFLEX", ADD);
	    } else {
		ModifyPro( szMaxPro, "USE=B000-B800", DELETE_STRING );
		ModifyPro( szMaxPro, "NOFLEX", ADD);
		TBEnd.bVGASwap = 0;
	    }
	}

	if (TBStart.bVGASwap != TBEnd.bVGASwap) {
	    fMaximize = 1;
	    if (TBEnd.bVGASwap) {
		ModifyPro( szMaxPro, "VGASWAP", ADD );
		ModifyPro( szMaxPro, "NOFLEX", ADD );
	    } else {
		ModifyPro( szMaxPro, "VGASWAP", DELETE );
		ModifyPro( szMaxPro, "NOFLEX", DELETE );
	    }

	    MakePath( szMaxDir, "maximize.cfg", szBuf );
	    ModifyPro( szBuf, "NOVGASWAP", ((TBEnd.bVGASwap != 0) ? DELETE : ADD) );
	}

	if (TBStart.bROMSrch != TBEnd.bROMSrch) {
	    MakePath( szMaxDir, "maximize.cfg", szBuf );
	    if (TBEnd.bROMSrch) {
		if (bROMNotSearched)
			fMaximize = 1;
		ModifyPro( szBuf, "NOROMSRCH", DELETE );
	    } else {
		ModifyPro( szMaxPro, "use", DELETE_ROMSEARCH );	// strip "use=xxx ; ROMSRCH"
		ModifyPro( szBuf, "NOROMSRCH", ADD );
	    }
	}

	if (lstrcmpi( TBStart.szUseRAM, TBEnd.szUseRAM ) != 0) {

		fMaximize = 1;

		// remove RAM= statements
		ModifyPro( szMaxPro, "RAM", DELETE );

		ModifyPro( szMaxPro, "NOFLEX", ADD);

		// write RAM= statements to 386MAX.PRO
		for (arg = TBEnd.szUseRAM; (*arg != '\0'); arg += n) {
			sscanf( arg, "%[^|]| %n", szBuf, &n );
			strins(szBuf, "RAM=");
			ModifyPro( szMaxPro, szBuf, ADD_APPEND );
		}
	}
}


void SaveDPMI(HWND hDlg)
{
	char szBuffer[128];

	if (bUninstalling)
		return;

	if (TBStart.bDPMI != TBEnd.bDPMI) {

		fReboot = 1;
		if ( TBEnd.bDPMI == 0) {
			ModifyPro( szMaxPro, "NODPMI", ADD );
			ModifyPro( szMaxPro, "SWAPFILE", DELETE );
		} else
			ModifyPro( szMaxPro, "NODPMI", DELETE );
	}

	if ((TBStart.bDPMISwap != TBEnd.bDPMISwap) || (lstrcmpi( TBStart.szDPMISwapfile, TBEnd.szDPMISwapfile ) != 0) || (TBStart.uDPMISwapSize != TBEnd.uDPMISwapSize )) {
		wsprintf(szBuffer, "SWAPFILE=%s /s=%d", TBEnd.szDPMISwapfile, TBEnd.uDPMISwapSize );
		ModifyPro( szMaxPro, szBuffer, ((TBEnd.bDPMISwap == 0) ? DELETE : ADD ));
	}

	if ((TBStart.bEMS != TBEnd.bEMS) || (lstrcmpi( TBStart.szPageFrame, TBEnd.szPageFrame ) != 0)) {

	    fMaximize = 1;
	    ModifyPro( szMaxPro, "FRAME", DELETE );
	    ModifyPro( szMaxPro, "NOFRAME", DELETE );

	    if (TBEnd.bEMS) {

		ModifyPro( szMaxPro, "EMS=0", DELETE );
		ModifyPro( szMaxPro, "NOFLEX", ADD );

		// set pageframe
		if (lstrcmpi( TBEnd.szPageFrame, "NOFRAME" ) == 0)
			ModifyPro( szMaxPro, "NOFRAME", ADD );
		else if (lstrcmpi( TBEnd.szPageFrame, "AUTO" ) != 0 ) {
			wsprintf( szBuffer, "FRAME=%s", TBEnd.szPageFrame );
			ModifyPro( szMaxPro, szBuffer, ADD );
		}

	    } else
		ModifyPro( szMaxPro, "EMS=0", ADD );
	}
}


int SaveUninstall(HWND hDlg)
{ 
    UINT uRef;
    HINSTANCE ghChildInstance = (HINSTANCE)NULL;
	char szBuf[512], szTemp[128];

	if ((bStripMM) || (bRemoveMaxFiles) || (bRemoveINIEntries) || (bRemoveINIFile) || (bRemoveMaxGroup)) {

		if (MessageBox(hDlg, szMsg_UnOK, szMsg_Uninstall, MB_YESNO | MB_ICONSTOP ) != IDYES )
			return 1;
	}

	if (bStripMM) {

		// strip any existing memory managers
		if (bWin95 == 0) {
			if (MessageBox(hDlg, szMsg_HiMem, szMsg_Uninstall, MB_OKCANCEL | MB_ICONSTOP ) != IDOK )
				return 1;
		}

		MakePath(szMaxDir, szStripPIF, szTemp );
		if (szStripMMSection[0])
			wsprintf(szBuf, "%s %c: /S /T /A%s", szTemp, szConfigSys[0], szStripMMSection );
		else
			wsprintf(szBuf, "%s %c: /S /T", szTemp, szConfigSys[0] );

        ghChildInstance = (HINSTANCE)WinExec( szBuf, SW_HIDE );
        
        while ( ( ghChildInstance != (HINSTANCE)NULL ) && 
              (( uRef=GetModuleUsage( ghChildInstance )) > 0 )) {
        Yield();
        }

	} else if (bStripLH) {

		// remove LoadHigh statements
		MakePath( szMaxDir, szStripPIF, szTemp );
		if (szStripLHSection[0])
			wsprintf(szBuf, "%s %c: /r /t /a%s", szTemp, szConfigSys[0], szStripLHSection );
		else
			wsprintf(szBuf, "%s %c: /r /t", szTemp, szConfigSys[0] );

        ghChildInstance = (HINSTANCE)WinExec( szBuf, SW_HIDE );
        while ( ( ghChildInstance != (HINSTANCE)NULL ) && 
              (( uRef=GetModuleUsage( ghChildInstance )) > 0 )) {
        Yield();
        }
	}

	return 0;
}


static char *pszSearchTitle;
static HWND hSearchWnd;

BOOL CALLBACK EnumWProc(HWND hWnd, LPARAM lParam)
{
	char szTitle[128];

	szTitle[0] = '\0';
	GetWindowText( hWnd, szTitle, 127 );
	szTitle[lstrlen(pszSearchTitle)] = '\0';

	if ( lstrcmpi( pszSearchTitle, szTitle ) == 0) {
		hSearchWnd = hWnd;
		return FALSE;
	}

	return TRUE;
}


// fuzzy (wildcard) pattern matching for window titles
HWND FuzzyFindWindow(char *szTitle)
{
	pszSearchTitle = szTitle;
	hSearchWnd = 0;

	EnumWindows((WNDENUMPROC)&EnumWProc,0L);

	return hSearchWnd;
}


static void RemoveMaxStuff(void)
{
	register int i;
	char *arg, szBuf[512], szTemp[256];
    unsigned int uError;
	HDRVR hDriver;
	HWND hWnd;

	if (bRemoveINIEntries) {

		// remove Registry entries
		if (bWin95)
			DeleteDOSMAXKeys();

		// Remove lines from SYSTEM.INI
		WritePrivateProfileString( "386enh", "VCPIWarning", NULL, szSystemIni );
		WritePrivateProfileString( "386enh", "SystemROMBreakPoint", NULL, szSystemIni );
		WritePrivateProfileString( "Qualitas", NULL, NULL, szSystemIni );

		// tell GoAhead driver to uninstall itself
		if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
			SendDriverMessage(hDriver, LCLDRV_DISABLE, 0, 0);
			SendDriverMessage(hDriver, DRV_REMOVE, 0, 0);
			CloseDriver(hDriver, 0, 0);
		}

		// Remove QPOPUP.EXE from WIN.INI
		szBuf[0] = szTemp[0] = '\0';
		GetProfileString( "windows", "load", "", szBuf, 511 );

		for (i = 0; ; i++) {

			if ((arg = ntharg( szBuf, i )) == NULL)
				break;

			// strip any existing QPOPUP
			if (FindString( arg, "qpopup.exe" ) < 0) {
				if (szTemp[0])
					lstrcat(szTemp, " ");
				lstrcat(szTemp, arg);
			}
		}

		WriteProfileString( "windows", "load", szTemp );
	}

	// remove QMAX.INI file
	if (bRemoveINIFile)
		remove( szIniName );

	// remove the Qualitas MAX group from Program Manager
	if (bRemoveMaxGroup)
		pmDeleteGroup( "Qualitas MAX" );

	if (bRemoveMaxFiles) {

        uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);
		SetBusy();
		hModeless = CreateDialog(ghInstance, MAKEINTRESOURCE(MODELESSDLGBOX), HWND_DESKTOP, ModelessDlgProc);
		SetDlgItemText( hModeless, 100, "Removing Qualitas MAX program files - please wait ..." );

		// FIXME - shut down Go Ahead / MAXmeter if they're running
		if ((hWnd = FindWindow( "MaxMeterWClass", NULL)) != 0)
			SendMessage(hWnd, WM_CLOSE, 0, 0L);
		Yield();
		if ((hWnd = FindWindow( "GAHD_CLS", NULL)) != 0)
			SendMessage(hWnd, WM_CLOSE, 0, 0L);
		Yield();

		// shutdown MaxEdit and QPifedit
		if ((hWnd = FindWindow( "MaxEditFrame", NULL)) != 0)
			SendMessage(hWnd, WM_CLOSE, 0, 0L);
		Yield();
		if ((hWnd = FuzzyFindWindow( "The Qualitas PIF Editor")) != 0)
			SendMessage(hWnd, WM_CLOSE, 0, 0L);
		Yield();

		// remove GoAhead and MAXmeter from Startup
		pmShowGroup(  szStartupGroup, 2 );
		pmShowGroup(  szStartupGroup, 1 );
		pmDeleteItem( "MAXmeter" );
		pmDeleteItem( "Go Ahead" );
		pmShowGroup(  szStartupGroup, 2 );

		// tell driver to uninstall itself
		if ((hDriver = (HDRVR)OpenDriver(szDrvName, 0, 0)) != 0) {
			SendDriverMessage(hDriver, LCLDRV_DISABLE, 0, 0);
			SendDriverMessage(hDriver, DRV_REMOVE, 0, 0);
			CloseDriver(hDriver, 0, 0);
		}

		// remove GoAhead.DRV from the Windows system directory
		MakePath( szWindowsSystemDir, szDrvName, szBuf );
		remove( szBuf );

		// switch to MAX directory and work from there
		AnsiUpper( szMaxDir );
		_chdrive( szMaxDir[0] - 64 );
		_chdir( szMaxDir );
		Yield();

		// delete QMAX.INI		
		remove( szIniName );

        fEvap = 1;
        fMaximize = fRestartWindows = fReboot = 0;

		DestroyWindow( hModeless );
		ClearBusy();
        SetErrorMode( uError );
	}
}


// This callback routine is called for every message intended for the
// currently active (sub)dialog.  Use DialogID to determine the current
// dialog and dispatch the message accordingly

LRESULT CALLBACK _export SubdialogCallback(HWND hDlg, int DialogID, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	static int fInitialized = 0;
	int left, top;
    int nHeight, nWidth, nDHeight, nDWidth;
	BOOL fResult = FALSE;
	RECT rect;
	HMENU hMenu;
    
	// We can process messages that are common to all subdialogs right here
	switch (uMsg) {
	case WM_INITDIALOG:

		Ctl3dSubclassDlg(hDlg, CTL3D_ALL);

		if (fInitialized == 0) {

			DlgTabbedDlg_Enable( hDlg, IDD_HIGHDOS, fMaxLoaded );
			DlgTabbedDlg_Enable( hDlg, IDD_DPMI, fMaxLoaded );

			if (szCurrentSection[0]) {

				char szBuf[320];

				if (szCurrentDescription[0] == '\0')
					wsprintf(szBuf, "%s  [%s]", szMsg_Editing, szCurrentSection );
				else
					wsprintf(szBuf, "%s  [%s]  \"%s\"", szMsg_Editing, szCurrentSection, szCurrentDescription );

				SetDlgItemText( hDlg, IDC_MULTISECTION, szBuf );
			}

                // get the screen size.
            nHeight = GetSystemMetrics( SM_CYFULLSCREEN );
            nWidth  = GetSystemMetrics( SM_CXFULLSCREEN );
                
                // get the width and height of the dialog.
            GetWindowRect( hDlg, &rect );
            nDWidth = rect.right - rect.left;
            nDHeight = rect.bottom - rect.top;
                
                // calculate default center
            left = ( nWidth  / 2 ) - ( nDWidth  / 2 ); 
            top =  ( nHeight / 2 ) - ( nDHeight / 2 ); 

			left = GetPrivateProfileInt( szINISection, "left", left, szIniName );
			top = GetPrivateProfileInt( szINISection, "top", top, szIniName );
			SetWindowPos( hDlg, HWND_TOP, left, top, 0, 0, SWP_NOSIZE );
			hMenu = GetSystemMenu( hDlg, FALSE );
			AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
			AppendMenu( hMenu, MF_STRING, IDM_HELP, szM_Over );
			AppendMenu( hMenu, MF_STRING, IDM_HELPSEARCH, szM_Search );
			AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
			AppendMenu( hMenu, MF_STRING, IDM_HELPTS, szM_TechS );
			AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
			AppendMenu( hMenu, MF_STRING, IDM_ABOUT, szM_About );

			// save the startup values
			InitStartup(hDlg);
			InitVideo(hDlg);
			InitDPMI(hDlg);
			InitUninstall(hDlg);

			// copy the startup values to the "working set"
			memmove( &TBEnd, &TBStart, sizeof(TBStart) );
		}

		switch (DialogID) {
		case IDD_STARTUP:
			InitStartup(hDlg);
			break;

		case IDD_HIGHDOS:
			InitVideo(hDlg);
			break;

		case IDD_DPMI:
			InitDPMI(hDlg);
			break;

		case IDD_UNINSTALL:
			InitUninstall(hDlg);
		}

		if (fInitialized == 0) {
			fInitialized = 1;
			return 0L;
		}
		break;

#if defined(_WIN32) || defined(__WIN32__)
	case WM_CTLCOLORBTN:
	case WM_CTLCOLORDLG:
	case WM_CTLCOLOREDIT:
	case WM_CTLCOLORLISTBOX:
	case WM_CTLCOLORSCROLLBAR:
	case WM_CTLCOLORSTATIC:
#else
	case WM_CTLCOLOR:
#endif
		return (LRESULT)(UINT) Ctl3dCtlColorEx(uMsg, wParam, lParam);

	case WM_QUERYENDSESSION:
		fResult = TRUE;             // default to allow switching
		GetWindowRect( hDlg, &rect );
		WritePrivateProfileInt( szINISection, "left", rect.left );
		WritePrivateProfileInt( szINISection, "top", rect.top );
		break;                      // so dialogs without dialog proc

	case WM_VSCROLL:
		if (DialogID == IDD_HIGHDOS) {
			ProcessVideo( hDlg, uMsg, wParam, lParam );
			return 0L;
		}
		break;

	case WM_SYSCOMMAND:

		switch (wParam) {

		case IDM_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_TO ));
			return 0;

		case IDM_HELPSEARCH:
			WinHelp( hDlg, szHelpName, HELP_PARTIALKEY, (DWORD)((char _far *)"") );
			return 0;

		case IDM_HELPTS:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_TS ));
			return 0;

		case IDM_ABOUT:
                	DialogBox(ghInstance, MAKEINTRESOURCE(ABOUTDLGBOX),  hDlg,  AboutDlgProc);
			return 0;
		}
		break;

	case WM_COMMAND:

		switch (DialogID) {
		case IDD_STARTUP:
			ProcessStartup( hDlg, uMsg, wParam, lParam );
			break;

		case IDD_HIGHDOS:
			ProcessVideo( hDlg, uMsg, wParam, lParam );
			break;

		case IDD_DPMI:
			ProcessDPMI( hDlg, uMsg, wParam, lParam );
			break;

		case IDD_UNINSTALL:
			ProcessUninstall( hDlg, uMsg, wParam, lParam );
		}

		switch (LOWORD(wParam)) {
		case IDOK:

			// check for any contradictory requests
			if (CheckForConflicts( hDlg ))
				break;
                
                // check for a Go Ahead driver conflict.
            if (( TBEnd.bGoAhead != TBStart.bGoAhead ) 
             && ( TBEnd.bGoAhead != 0 )) {

                HINSTANCE hInst;
                int nRet = 0;
                BOOL ( FAR *lpfnGALoadClear)();
                BOOL ( FAR *lpfnGADialog)(HWND, int);
				
                MakePath( szWindowsSystemDir, szDrvName, szWork );
                hInst = LoadLibrary ( szWork );
                if ((UINT) hInst >= 32)	// If it worked, ...
                    {
                    (FARPROC) lpfnGALoadClear = GetProcAddress (hInst, pszGALoadClear);
                    (FARPROC) lpfnGADialog = GetProcAddress (hInst, pszGADialog);

                    if (lpfnGALoadClear != NULL) {	// If it worked, ...
                            // if there is a conflict..
                        if( !lpfnGALoadClear() ) {
                                // call the warning box.
                            if (lpfnGADialog != NULL) {	
                                if(( nRet = lpfnGADialog( hDlg, 2 )) != 1 ) {
                                    TBEnd.bGoAhead = 0;
                                }
                            }
                        }
                    }
                    FreeLibrary (hInst); // Decrement reference count
                } 
            }

			// save new .PRO info
			SaveStartup(hDlg);
			SaveVideo(hDlg);
			SaveDPMI(hDlg);
			if (SaveUninstall(hDlg))
				break;

                // set the maximize options
            WriteMaximizeINI();

			WinHelp(hDlg, szHelpName, HELP_QUIT, 0L);

			GetWindowRect( hDlg, &rect );

			// save normal position
			if (bRemoveINIFile == 0) {
				WritePrivateProfileInt( szINISection, "left", rect.left );
				WritePrivateProfileInt( szINISection, "top", rect.top );
			}

			if (fMaximize)
				DialogBox(ghInstance, MAKEINTRESOURCE(EXITMAXIMIZEDLGBOX), hDlg, ExitMaximizeDlgProc);
			else if (fReboot)
				DialogBox(ghInstance, MAKEINTRESOURCE(EXITREBOOTDLGBOX), hDlg, ExitRebootDlgProc);
			else if (fRestartWindows)
				DialogBox(ghInstance, MAKEINTRESOURCE(EXITRESTARTDLGBOX), hDlg, ExitRestartDlgProc);

			DlgTabbedDlg_EndDialog(hDlg, TRUE);

			// strip program files
			RemoveMaxStuff();

			break;

		case IDCANCEL:
			WinHelp(hDlg, szHelpName, HELP_QUIT, 0L);

			// check for changes
			if (_memicmp( &TBStart, &TBEnd, sizeof(TBStart) ) != 0) {
				if (MessageBox(hDlg, szMsg_Changes, szMsg_Cancel, MB_YESNO | MB_ICONSTOP ) != IDYES )
					break;
			}

			DlgTabbedDlg_EndDialog(hDlg, FALSE);
			break;  

		case IDHELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_TO ));
			break;
		}

		fResult = TRUE;
	}

	// Process messages not processed by the dialog procedure
	return (GetTabbedDialogResult(fResult, hDlg, uMsg, wParam, lParam));
}


/****************************************************************************

    FUNCTION: About(HWND, unsigned, WORD, LONG)

    PURPOSE:  Processes messages for "About" dialog box

****************************************************************************/

BOOL __export CALLBACK AboutDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	char szBuffer[256], szName[64], szCompany[64], szSerial[32];

	switch (message) {
	case WM_INITDIALOG:
		// get name & company from QMAX.INI
		GetPrivateProfileString( "Registration", "Name", "", szName, sizeof(szName), szIniName );
		GetPrivateProfileString( "Registration", "Company", "", szCompany, sizeof(szCompany), szIniName );
		GetPrivateProfileString( "Registration", "S/N", "", szSerial, sizeof(szSerial), szIniName );
		wsprintf( szBuffer, "%s\r\n%s\r\nS/N  %s", (char _far *)szName, (char _far *)szCompany, (char _far *)szSerial );
		SetDlgItemText( hDlg, 102, szBuffer );
		return TRUE;

        case WM_COMMAND:

	    switch (LOWORD(wParam)) {
            case IDOK:
                EndDialog(hDlg, TRUE);
                return TRUE;
	    }
	}

	return FALSE;
}


BOOL CALLBACK __export ExitMaximizeDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fMaximize = 0;
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			// run MAXIMIZE
			fMaximize = 1;
			EndDialog(hDlg, 1);
			return TRUE;

		case IDC_EXIT:
			fReboot = fRestartWindows = 0;
			EndDialog(hDlg, 1);
			return TRUE;
		}
	}

	return FALSE;
}


BOOL CALLBACK __export ExitRestartDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fRestartWindows = 0;
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			fRestartWindows = 1;
			EndDialog(hDlg, 1);
			ExitWindows( EW_RESTARTWINDOWS, 0 );
			return TRUE;

		case IDC_EXIT:
			fMaximize = fReboot = 0;
			EndDialog(hDlg, 1);
			return TRUE;
		}
	}

	return FALSE;
}


BOOL CALLBACK __export ExitRebootDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		fReboot = 0;
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			fReboot = 1;
			EndDialog(hDlg, 1);
			ExitWindows( EW_REBOOTSYSTEM, 0 );
			return TRUE;

		case IDC_EXIT:
			fMaximize = fRestartWindows = 0;
			EndDialog(hDlg, 1);
			return TRUE;
		}
	}

	return FALSE;
}


BOOL CALLBACK __export ConflictDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
	case WM_INITDIALOG:
		SetDlgItemText( hDlg, IDC_CONFLICT1, szConflict1 );
		SetDlgItemText( hDlg, IDC_CONFLICT2, szConflict2 );
		return TRUE;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			EndDialog(hDlg, 1);
			return TRUE;
		}
	}

	return FALSE;
}


// Invoke the tabbed dialog
static BOOL TabDlg_Do(void)
{
    WNDCLASS wc;
    TABBEDDIALOGPARM Tab;

    // Register a class for the dialog box so we can specify an icon
	// if the dialog box is minimized.
	wc.style = CS_DBLCLKS | CS_SAVEBITS | CS_BYTEALIGNWINDOW;
	wc.lpfnWndProc = DefDlgProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = DLGWINDOWEXTRA;
	wc.hInstance = ghInstance;
	wc.hIcon = LoadIcon( ghInstance, MAKEINTRESOURCE( MAXICON ));
	wc.hCursor = LoadCursor( (HINSTANCE)NULL, IDC_ARROW);
	wc.hbrBackground = COLOR_WINDOW + 1;
	wc.lpszMenuName = NULL;
	wc.lpszClassName = szTBDlgClass;
	RegisterClass(&wc);

	Tab.size = sizeof(TABBEDDIALOGPARM);// size of structure
	Tab.hinst = ghInstance;             // Our instance handle
	Tab.resource = MAKEINTRESOURCE(IDD_BASEDIALOG);
	Tab.hwndOwner = HWND_DESKTOP;       // Tabbed dialog window owner
	Tab.activeItem = 0;                 // initially active item     
	Tab.lpfnCallback = (TABBEDDLGPROC) MakeProcInstance((FARPROC)SubdialogCallback, ghInstance);
	Tab.lParam = 0;                     // Data Common to all subdialogs

	return (DlgTabbedDlg_Do(&Tab));       // Modal Tabbed Dialog
}


// read CONFIG.SYS file to get multiconfig sections
void ReadMulticonfig(void)
{
	char cBootDrive, *ptr;
	char szBuf[512], szCSection[80], szTemp[256];
	HFILE fh;

	szSections[0] = '\0';
	szCurrentSection[0] = '\0';
	szCurrentDescription[0] = '\0';

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

				if (szCurrentSection[0]) {
					sscanf( ptr, "%[^ ,\n]%*[ ,]%255[^\n]", szCSection, szTemp );
					if (lstrcmpi( szCSection, szCurrentSection ) == 0)
						lstrcpy( szCurrentDescription, szTemp );
				}
			}
		}

		_lclose(fh);
	}
}


// look for 386MAX.SYS in CONFIG.SYS
void CheckForMax( void )
{
	int n;
	char *ptr, szBuf[512];
	HFILE fh;

	szMaxPro[0] = '\0';

	if ((fh = _lopen( szConfigSys, READ )) != HFILE_ERROR) {

		if (szCurrentSection[0] == '\0')
			goto ReadSection;

		// read file for section names
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			if (szBuf[0] != '[')
				continue;

			lstrcpy( szBuf, szBuf + 1 );
			strip_trailing( szBuf, "]" );

			// check for section name
			if (lstrcmpi(szBuf, szCurrentSection) == 0) {
ReadSection:
				while ((n = GetLine( fh, szBuf, 511 )) > 0) {

					if (FindString( szBuf, "386max.sys") >= 0) {
						// get 386MAX.PRO name / location
						if (((ptr = ntharg( szBuf, 2 )) != NULL) && (lstrcmpi( ptr, "pro" ) == 0))
							lstrcpy( szMaxPro, ntharg( szBuf, 3) );
						fMaxLoaded = 1;
						break;
					}
				}
			}
		}

		_lclose(fh);
	}

	if (szMaxPro[0] == '\0')
		MakePath( szMaxDir, "386max.pro", szMaxPro );
}


// insert/delete a line in *.PRO
void ModifyPro( char *szFilename, char *pszLine, int fFlag )
{
	unsigned int fInserted = 0, uSize;
	char *ptr, szTemp[128], szBuf[512], szBuffer[512];
	int fSection = 0;
	long lOffset = 0L;
	HFILE fh;

	if (((fh = _lopen( szFilename, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szFilename, 0 )) != HFILE_ERROR )) {

		// read file for matching option
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';'))
				goto SaveOffset;

			if ((szBuf[0] == '[') && (szCurrentSection[0] != '\0')) {

				if (fSection == 2) {

					// already got the section; add this
					//   line to the end
					if (fFlag & (ADD | ADD_STRING | ADD_APPEND)) {
						goto InsertLine;
					}

				} else {

					lstrcpy( szBuf, szBuf + 1 );
					strip_trailing( szBuf, "] " );

					// check for section name
					if ((lstrcmpi(szBuf, szCurrentSection) != 0) && (lstrcmpi(szBuf, "common") != 0)) {
						fSection = 1;
						goto SaveOffset;
					}

					// got the right section!
					fSection = 2;
				}

			} else if (fSection == 1)
				continue;	// waiting for right section

			// strip trailing whitespace & comments
			lstrcpy( szBuffer, szBuf );
			ptr = scan( szBuf, ((fFlag & (ADD_STRING | DELETE_STRING)) ? " \t;" : " \t;=" ));
			if (*ptr != '\0')
				*ptr = '\0';

			lstrcpy( szTemp, pszLine );
			ptr = scan( szTemp, ((fFlag & DELETE_STRING) ? " \t;" : " \t;=" ));
			if (*ptr != '\0')
				*ptr = '\0';

			if (lstrcmpi(szBuf, szTemp) == 0) {

				if ((fFlag & DELETE_ROMSEARCH) && (FindString( szBuffer, "use=E" ) < 0 ) && (FindString( szBuffer, "use=F") < 0))
					goto SaveOffset;

				if (fFlag & ADD_APPEND) {
InsertLine:
					_llseek( fh, lOffset, SEEK_SET );
				}

				// read remainder of file into temp buffer
				uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
				ptr = AllocMem( &uSize );
				uSize = _lread( fh, ptr, uSize );

				_llseek( fh, lOffset, SEEK_SET );

				// write new line
				if (fFlag & (ADD | ADD_STRING | ADD_APPEND)) {
					_lwrite( fh, pszLine, lstrlen( pszLine ));
					_lwrite( fh, "\r\n", 2 );
					fInserted = 1;
				}

				// write remainder of file
				_lwrite( fh, ptr, uSize );
				_lwrite( fh, "", 0 );
				FreeMem( ptr );

				if (fFlag & (ADD | ADD_STRING | ADD_APPEND))
					break;
				_llseek( fh, lOffset, SEEK_SET );
			}

SaveOffset:
			lOffset = _llseek( fh, 0L, SEEK_CUR );
		}

		// write new line
		if ((fInserted == 0) && (fFlag & (ADD | ADD_STRING | ADD_APPEND))) {
			_lwrite( fh, pszLine, lstrlen( pszLine ));
			_lwrite( fh, "\r\n", 2 );
			_lwrite( fh, "", 0 );
		}

		_lclose(fh);
	}
}


// remove specified device from CONFIG.SYS
void StripConfigSys( char *pszType, char *pszDevice )
{
	int n;
	unsigned int uSize;
	char *ptr, szBuf[512];
	long lOffset = 0L;
	HFILE fh;

	if ((fh = _lopen( szConfigSys, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) {

		if ((szSections[0] == '\0') || (szCurrentSection[0] == '\0'))
			goto RemoveLine;

		// read file for section names
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			if ((szBuf[0] != '[') || (lstrcmpi(szBuf, "[menu]") == 0))
				continue;

			lstrcpy( szBuf, szBuf + 1 );
			strip_trailing( szBuf, "]" );

			// check for section name
			if (lstrcmpi(szBuf, szCurrentSection) == 0) {
RemoveLine:
				lOffset = _llseek( fh, 0L, SEEK_CUR );
				while ((n = GetLine( fh, szBuf, 511 )) > 0) {

					if ((ptr = ntharg(szBuf, 0)) != NULL) {

					    if (*ptr == '[') {
						n = 0;
						break;
					    }

					    // strip device line
					    if ((lstrcmpi(ptr, pszType) == 0) && (FindString( szBuf, pszDevice ) >= 0))
						break;
					}

					lOffset = _llseek( fh, 0L, SEEK_CUR );
				}

				if (n <= 0)
					break;

				// read remainder of file into temp buffer
				uSize = (unsigned int)(_filelength( fh ) - lOffset) + 16;
				ptr = AllocMem( &uSize );
				uSize = _lread( fh, ptr, uSize );

				// remove line
				_llseek( fh, lOffset, SEEK_SET );

				// write remainder of file
				_lwrite( fh, ptr, uSize );
				_lwrite( fh, "", 0 );
				FreeMem( ptr );
				break;
			}
		}

		_lclose(fh);
	}
}


// insert / delete a line in AUTOEXEC.BAT
int ModifyAutoexec( char *pszLine, int fDelete)
{
	unsigned int uSize = 0;
	char *ptr, szBuf[512];
	long lOffset = 0L;
	HFILE fh;

	if (((fh = _lopen( szAutoexec, READ_WRITE | OF_SHARE_DENY_WRITE )) != HFILE_ERROR) || ((fh = _lcreat( szAutoexec, 0 )) != HFILE_ERROR )) {

		if (fDelete) {

			while (GetLine( fh, szBuf, 511 ) > 0) {

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
			_lwrite( fh, pszLine, lstrlen( pszLine ));
			_lwrite( fh, "\r\n", 2 );
		}

		// write remainder of file
		_lwrite( fh, ptr, uSize );
		_lwrite( fh, "", 0 );
		FreeMem( ptr );

		_lclose(fh);
	}

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

			if ((szBuf[0] == '[') && (szCurrentSection[0])) {

				lstrcpy( szBuf, szBuf + 1 );
				strip_trailing( szBuf, "] " );

				// check for section name
				if ((lstrcmpi(szBuf, szCurrentSection) != 0) && (lstrcmpi(szBuf, "common") != 0)) {
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


// read the 386MAX.PRO file looking for RAM= lines
void ParseProRAM( void )
{
	static char szBuf[512];
	int fSection = 0;
	char *ptr;
	HFILE fh;

	TBStart.szUseRAM[0] = '\0';
	if ((fh = _lopen( szMaxPro, READ | OF_SHARE_DENY_NONE )) != HFILE_ERROR) {

		// read file
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';') || ((ptr = ntharg(szBuf, 0)) == NULL) || (lstrcmpi(ptr, "rem") == 0))
				continue;

			if ((szBuf[0] == '[') && (szCurrentSection[0])) {

				lstrcpy( szBuf, szBuf + 1 );
				strip_trailing( szBuf, "] " );

				// check for section name
				if ((lstrcmpi(szBuf, szCurrentSection) != 0) && (lstrcmpi(szBuf, "common") != 0)) {
					fSection = 1;
					continue;
				}

				fSection = 0;

			} else if (fSection == 1)
				continue;	// waiting for right section

			ptr = ntharg( szBuf, 0 );
			if (lstrcmpi(ptr, "RAM") == 0) {

				if ((ptr = strchr( szBuf, ';' )) != NULL)
					*ptr = '\0';

				ptr = szBuf + 3;
				strip_leading( ptr, " =\t" );
				strip_trailing( ptr, " \t" );
				lstrcat( TBStart.szUseRAM, ptr );
				lstrcat( TBStart.szUseRAM, "|" );
			}
		}

		_lclose( fh );
	}
}


// read the 386MAX.PRO file looking for USE= lines
void ParseProUSE( char *szUSE )
{
	static char szBuf[512];
	int fSection = 0;
	char *ptr;
	HFILE fh;

	if ((fh = _lopen( szMaxPro, READ | OF_SHARE_DENY_NONE )) != HFILE_ERROR) {

		// read file
		while (GetLine( fh, szBuf, 511 ) > 0) {

			strip_leading( szBuf, " \t" );
			strip_trailing( szBuf, " \t" );

			// skip blank lines and comments
			if ((szBuf[0] == '\0') || (szBuf[0] == ';') || ((ptr = ntharg(szBuf, 0)) == NULL) || (lstrcmpi(ptr, "rem") == 0))
				continue;

			if ((szBuf[0] == '[') && (szCurrentSection[0])) {

				lstrcpy( szBuf, szBuf + 1 );
				strip_trailing( szBuf, "] " );

				// check for section name
				if ((lstrcmpi(szBuf, szCurrentSection) != 0) && (lstrcmpi(szBuf, "common") != 0)) {
					fSection = 1;
					continue;
				}

				fSection = 0;

			} else if (fSection == 1)
				continue;	// waiting for right section

			ptr = ntharg( szBuf, 0 );
			if (lstrcmpi(ptr, "USE") == 0) {

				if ((ptr = strchr( szBuf, ';' )) != NULL)
					*ptr = '\0';

				ptr = szBuf + 3;
				strip_leading( ptr, " =\t" );
				strip_trailing( ptr, " \t" );
				lstrcat( szUSE, ptr );
				lstrcat( szUSE, "|" );
			}
		}

		_lclose( fh );
	}
}


// check for contradictory commands
int CheckForConflicts( HWND hDlg )
{
	unsigned int uStart, uEnd, i, n;
	unsigned int uFrameStart, uFrameEnd;
	unsigned int uUseStart, uUseEnd;
	char szUSE[512], *ptr, *ptr1;

	// check for RAM=c000-c800 and VGASWAP
	if (TBEnd.bVGASwap) {

		for (ptr = TBEnd.szUseRAM; (*ptr != '\0'); ptr += i) {

			uStart = uEnd = i = 0;
			sscanf( ptr, "%x-%x |%n", &uStart, &uEnd, &i );

			if (((uStart >= 0xc000) && (uStart <= 0xc800)) || ((uEnd > 0xc000) && (uEnd <= 0xc800)) || ((uStart < 0xc000) && (uEnd > 0xc000))) {
				lstrcpy(szConflict1, "VGASWAP");
				wsprintf(szConflict2, "RAM=%x-%x",uStart,uEnd);
				DialogBox(ghInstance, MAKEINTRESOURCE(CONFLICTDLGBOX), hDlg, ConflictDlgProc);
				return 1;
			}
		}
	}

	// check for FRAME= and RAM= conflict
	if (TBEnd.szPageFrame[0]) {

		uFrameStart = uFrameEnd = 0;
		sscanf( TBEnd.szPageFrame, "%x", &uFrameStart );
		uFrameEnd = uFrameStart + 0x1000;

		for (ptr = TBEnd.szUseRAM; (*ptr != '\0'); ptr += i) {

			uStart = uEnd = i = 0;
			sscanf( ptr, "%x-%x |%n", &uStart, &uEnd, &i );

			if (((uStart >= uFrameStart) && (uStart < uFrameEnd)) || ((uEnd > uFrameStart) && (uEnd < uFrameEnd)) || ((uStart < uFrameStart) && (uEnd > uFrameStart))) {
				wsprintf(szConflict1, "FRAME=%s", TBEnd.szPageFrame);
				wsprintf(szConflict2, "RAM=%x-%x", uStart,uEnd);
				DialogBox(ghInstance, MAKEINTRESOURCE(CONFLICTDLGBOX), hDlg, ConflictDlgProc);
				return 1;
			}
		}
	}

	// check for USE= and RAM= conflict
	if (TBEnd.szUseRAM[0]) {

		szUSE[0] = '\0';
		ParseProUSE( szUSE );

		for (ptr1 = szUSE; (*ptr1 != '\0'); ptr1 += i) {

			uUseStart = uUseEnd = i = 0;
			sscanf( ptr1, "%x-%x |%n", &uUseStart, &uUseEnd, &i );

			for (ptr = TBEnd.szUseRAM; (*ptr != '\0'); ptr += n) {

				uStart = uEnd = n = 0;
				sscanf( ptr, " %x-%x |%n", &uStart, &uEnd, &n );

				if (((uStart >= uUseStart) && (uStart < uUseEnd)) || ((uEnd > uUseStart) && (uEnd < uUseEnd)) || ((uStart < uUseStart) && (uEnd > uUseStart))) {
					wsprintf(szConflict1, "USE=%x-%x", uUseStart, uUseEnd);
					wsprintf(szConflict2, "RAM=%x-%x", uStart, uEnd);
					DialogBox(ghInstance, MAKEINTRESOURCE(CONFLICTDLGBOX), hDlg, ConflictDlgProc);
					return 1;
				}
			}

		}
	}

	return 0;
}


// General purpose modeless dialog
BOOL CALLBACK __export ModelessDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	return FALSE;
}


HCURSOR hSaveCursor;
int fBusyCursor = 0;

// Shows the hourglass cursor and puts the window into a modal condition.
void SetBusy(void)
{
	register HCURSOR hCursor;

	hSaveCursor = GetCursor();
	hCursor = LoadCursor(0, IDC_WAIT);
	SetCursor(hCursor);
	fBusyCursor = 1;
}


// set the cursor back to the arrow
void ClearBusy(void)
{
	if (fBusyCursor) {
		fBusyCursor = 0;
		SetCursor(hSaveCursor);
	}
}


// make up for the lack of a Windows API!
void WritePrivateProfileInt(char *szSection, char *szItem, int nValue)
{
	char szBuffer[16];

	wsprintf( szBuffer, "%d", nValue );
	WritePrivateProfileString( szSection, szItem, szBuffer, szIniName );
}

void WriteMaximizeINI( )
{
	char szBuffer[16];

	wsprintf( szBuffer, "%d",  0 );
	WritePrivateProfileString( szDefault, szCustom, szBuffer, szMaxIniPath );

	wsprintf( szBuffer, "%d",  TBEnd.bROMSrch );
	WritePrivateProfileString( szDefault, szROMSrch, szBuffer, szMaxIniPath );

	wsprintf( szBuffer, "%d",  TBEnd.bVGASwap );
	WritePrivateProfileString( szDefault, szVGASwap, szBuffer, szMaxIniPath );

	wsprintf( szBuffer, "%d",  TBEnd.bExtraDOS );
	WritePrivateProfileString( szDefault, szExtraDOS, szBuffer, szMaxIniPath );
}


int QueryGoAhead(void)
{
	HDRVR hDriver;
	int fGoAhead = 0;

	// The scheme we use to determine whether or not the driver
	//   was loaded at [boot] section time is to count DRV_CLOSE
	//   messages.  If the driver was loaded at [boot] time, it
	//   has a persistent data segment and the count of DRV_CLOSE
	//   messages can be non-zero.  If the driver wasn't loaded
	//   at [boot] time, then each time we open the driver the
	//   data segment is established anew and the count of
	//   DRV_CLOSE messages must always be zero.

	// Open it just so we can close it
	if ((hDriver = OpenDriver( szDrvName, 0, 0 )) != 0)
		CloseDriver(hDriver, 0, 0);  // Ensure at least one close

	if ((hDriver = OpenDriver( szDrvName, 0, 0)) != 0) {

		// See how many times this driver has been closed.  If
		//   it's > 0, then it must have a persistent data
		//   segment, and thus it's been loaded via "drivers="
		//   line in [boot] section in SYSTEM.INI, hence
		//   installed.
		if ( SendDriverMessage(hDriver, LCLDRV_QUERYCLOSE, 0, 0) ) {
			// If it's already installed, ...
			fGoAhead = 1;
		}
	    CloseDriver(hDriver, 0, 0);
	}

	return fGoAhead;
}


// remove the DOSMAX keys from the registry
void DeleteDOSMAXKeys( void )
{
	register int i;

	for ( i = REGISTRY_ENTRIES; (--i >= 0); )
		RegDeleteKey( HKEY_CLASSES_ROOT, DosMaxRegistry[i].pszKey );
}

