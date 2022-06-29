/****************************************************************************
    MAXMETER.C
    Windows resource monitor
    Copyright (c) 1995 Rex Conn for Qualitas Inc.
****************************************************************************/

#include <windows.h>
#include <ctl3d.h>

#include "maxmeter.h"
#include "resource.h"

#include <stdio.h>
#include <memory.h>
#include <commdlg.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>

#define SETUP_MSG_DEFVARS 1
#include "messages.h"

HANDLE hInst;			// current instance
HWND hStatBar;
COUNTRYINFO gaCountryInfo;	// international formatting info

static unsigned int nSBInited = 0;

int dxStatbar;
int dyStatbar;

int dyFontHeight;
HFONT hFont = (HFONT) NULL;
HFONT hOldFont = (HFONT) NULL;
LOGFONT lf_Font;

int nTopmost = 1;
int nEntries;
int nX;
int nY;
int fAmPm = 1;
int nWin95 = 0;
int fGoAhead = 0;
long glWinFlags;

DWORD lUserFree;
DWORD lGDIFree;
DWORD lDOSMem;
DWORD dwTotalDOS = 0L;

char szIniName[80];
char szHelpName[80];
char szMaxPath[80];
char szINISection[] = "MAXmeter";
char GDI_FREE[] = "GDI: %2.2ld%%";
char USER_FREE[] = "User: %2.2ld%%";
char DOS_MEM[] = "DOS: %2.2ld%%";
char TIME_FMT[] = "%2u-%02u-%02u";

#define STATUSBAR_ENTRIES 6
#define GDI_FLAG 1
#define USER_FLAG 2
#define DOSMEM_FLAG 3

// status bar structure
typedef struct {
	int fFlag;
	int nStart;
	int nWidth;
	void (*func)(char *, BOOL);
} AITEM;

AITEM aSBItem[STATUSBAR_ENTRIES];

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
#define IDC_MEMCHANGED			1019
#define IDC_TASKCHANGED			1020

HDRVR hDriver;
char szDrvName[] = FILENAMEXT;


void WalkWindowList( void );
VOID InitStatBar(void);
VOID StatBar_OnTimer(void);
VOID DisplayStatus(HWND, AITEM[], BOOL);
VOID DrawStatusBar(HWND, HDC, AITEM[]);
void FontSelect(void);
void FontConstruct( HDC );

static void StatusDate(char *, BOOL);
static void StatusTime(char *, BOOL);
static void StatusFree(char *, BOOL);
static void StatusGDI(char *, BOOL);
static void StatusUser(char *, BOOL);
static void StatusDOSMem(char *, BOOL);

static void QueryCountryInfo(void);
static void _fastcall QueryDateTime(DATETIME *);
static char * PASCAL FormatDate(int, int, int );
void WritePrivateProfileInt(char *, char *, int);
VOID UpdateFrameProfile(void);
void MakePath(char *, char *, char *);


/****************************************************************************

    FUNCTION: WinMain(HANDLE, HANDLE, LPSTR, int)

    PURPOSE: calls initialization function, processes message loop

****************************************************************************/

int PASCAL WinMain(HANDLE hInstance, HANDLE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	MSG msg;
	DWORD dwVersion;

	// get version info - in Win95 need to allow for 'X' close box
	dwVersion = GetVersion();
	if (((dwVersion & 0xFF) >= 4) || (((dwVersion >> 8) & 0xFF) >= 50))
		nWin95 = 1;

	// get the windows flags
	glWinFlags = GetWinFlags();

	/* Other instances of app running? */
	if (hPrevInstance) {
		WalkWindowList( );
		return 1;
	}

	// initialize 3-D support
	Ctl3dRegister( hInstance );
	Ctl3dAutoSubclass( hInstance );

	if (!InitApplication(hInstance)) /* Initialize shared things */
		return (FALSE);      /* Exits if unable to initialize     */

	/* Perform initializations that apply to a specific instance */
	if (!InitInstance(hInstance, nCmdShow))
		return (FALSE);

	while (GetMessage(&msg, NULL, NULL, NULL)) {
		TranslateMessage( &msg );    /* Translates virtual key codes       */
		DispatchMessage( &msg );     /* Dispatches message to window       */
	}

	return (msg.wParam);       /* Returns the value from PostQuitMessage */
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
			if (lstrcmpi(szModuleName, "MAXmeter") == 0) {
				SetWindowPos( hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW );
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

    /* Fill in window class structure with parameters that describe the       */
    /* main window.                                                           */

    wc.style = NULL;                    /* Class style(s).                    */
    wc.lpfnWndProc = MainWndProc;       /* Function to retrieve messages for  */
                                        /* windows of this class.             */
    wc.cbClsExtra = 0;                  /* No per-class extra data.           */
    wc.cbWndExtra = 0;                  /* No per-window extra data.          */
    wc.hInstance = hInstance;           /* Application that owns the class.   */
    wc.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(MAXICON));
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  NULL;   /* Name of menu resource in .RC file. */
    wc.lpszClassName = "MaxMeterWClass"; /* Name used in call to CreateWindow. */

    /* Register the window class and return success/failure code. */
    return (RegisterClass(&wc));
}


/****************************************************************************

    FUNCTION:  InitInstance(HANDLE, int)

    PURPOSE:  Saves instance handle and creates main window

    COMMENTS:

        This function is called at initialization time for every instance of
        this application.  This function performs initialization tasks that
        cannot be shared by multiple instances.

        In this case, we save the instance handle in a static variable and
        create and display the main program window.

****************************************************************************/

BOOL InitInstance(HANDLE hInstance, int nCmdShow)
{
    HMENU hMenu;
    char szTemp[128];

    /* Save the instance handle in static variable, which will be used in  */
    /* many subsequence calls from this application to Windows.            */

    hInst = hInstance;

    /* Create a main window for this application instance.  */

    hStatBar = CreateWindow(
        "MaxMeterWClass",
        "MAXMeter",
	WS_POPUPWINDOW | WS_CAPTION,
        0,               		/* Default horizontal position.       */
        0,               		/* Default vertical position.         */
        CW_USEDEFAULT,                  /* Default width.                     */
        CW_USEDEFAULT,                  /* Default height.                    */
        HWND_DESKTOP,                   /* Overlapped windows have no parent. */
        NULL,                           /* Use the window class menu.         */
        hInstance,                      /* This instance owns this window.    */
        NULL                            /* Pointer not needed.                */
    );

    // If window could not be created, return "failure"
    if ( hStatBar == NULL )
        return FALSE;

    // remove unneeded system menu options, and add some new ones
    hMenu = GetSystemMenu( hStatBar, FALSE );

    RemoveMenu( hMenu, 8, MF_BYPOSITION );
    RemoveMenu( hMenu, 4, MF_BYPOSITION );
    RemoveMenu( hMenu, 3, MF_BYPOSITION );
    RemoveMenu( hMenu, 2, MF_BYPOSITION );
    RemoveMenu( hMenu, 0, MF_BYPOSITION );

    if (nWin95)
    	AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu( hMenu, MF_STRING, IDM_CONFIGURE, szM_Config );
    AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu( hMenu, MF_STRING, IDM_FONT, szM_Font );
    AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu( hMenu, MF_STRING, IDM_HELP, szM_Over );
    AppendMenu( hMenu, MF_STRING, IDM_HELPSEARCH, szM_Search );
    AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu( hMenu, MF_STRING, IDM_HELPTS, szM_TechS );
    AppendMenu( hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu( hMenu, MF_STRING, IDM_ABOUT, szM_About );

    // set .INI name
    GetWindowsDirectory( szTemp, 80 );
    MakePath( szTemp, "QMAX.INI", szIniName );
    GetPrivateProfileString( "CONFIG", "Qualitas MAX Path", "c:\\qmax", szMaxPath, 80, szIniName );
    GetPrivateProfileString( "CONFIG", "Qualitas MAX Help", "maxhelp.hlp", szTemp, 80, szIniName );
    MakePath( szMaxPath, szTemp, szHelpName );

	// The scheme we use to determine whether or not the driver
	//   was loaded at [boot] section time is to count DRV_CLOSE
	//   messages.  If the driver was loaded at [boot] time, it
	//   has a persistent data segment and the count of DRV_CLOSE
	//   messages can be non-zero.  If the driver wasn't loaded
	//   at [boot] time, then each time we open the driver the
	//   data segment is established anew and the count of
	//   DRV_CLOSE messages must always be zero.

	fGoAhead = 0;
    hDriver = NULL;

        // the Go Ahead driver does not exist in Win95.
    if ( !nWin95 ) {

        // Open it just so we can close it
        if ((hDriver = OpenDriver(szDrvName, NULL, NULL)) != NULL)
            CloseDriver(hDriver, NULL, NULL);  // Ensure at least one close

        if ((hDriver = OpenDriver(szDrvName, NULL, NULL)) != NULL) {

            // See how many times this driver has been closed.  If
            //   it's > 0, then it must have a persistent data
            //   segment, and thus it's been loaded via "drivers="
            //   line in [boot] section in SYSTEM.INI, hence
            //   installed.
           	if ( SendDriverMessage(hDriver, LCLDRV_QUERYCLOSE, NULL, NULL) ) {
               	// If it's already installed, ...
               	// Register our WinApp with the driver so we
               	//   are informed of DOS memory changes
               	SendDriverMessage(hDriver, LCLDRV_REGISTER, (LPARAM) hStatBar, MAKELONG(IDC_MEMCHANGED, IDC_TASKCHANGED));
               	fGoAhead = 1;
            }
        }
        if (!fGoAhead) {
            CloseDriver(hDriver, NULL, NULL);  // It's not installed
            hDriver = NULL;
        }
    }

    InitStatBar();

    return TRUE;
}


/****************************************************************************

    FUNCTION: Config(HWND, unsigned, WORD, LONG)

    PURPOSE:  Processes messages for "Configuration" dialog box

****************************************************************************/

BOOL __export CALLBACK Config(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	register int n;

	switch (message) {
	case WM_INITDIALOG:
		CheckDlgButton(hDlg, IDC_DATE, GetPrivateProfileInt( szINISection, "date", 1, szIniName ) );
		CheckDlgButton(hDlg, IDC_TIME, GetPrivateProfileInt( szINISection, "time", 1, szIniName ) );
		if (nWin95)
			EnableWindow(GetDlgItem(hDlg,IDC_MEMORY), FALSE);
		else
			CheckDlgButton(hDlg, IDC_MEMORY, GetPrivateProfileInt( szINISection, "memory", 1, szIniName ) );
		CheckDlgButton(hDlg, IDC_GDI, GetPrivateProfileInt( szINISection, "gdi", 1, szIniName ) );
		CheckDlgButton(hDlg, IDC_USER, GetPrivateProfileInt( szINISection, "user", 1, szIniName ) );
		CheckDlgButton(hDlg, IDC_DOSMEM, GetPrivateProfileInt( szINISection, "dosmem", 1, szIniName ) );
		n = GetPrivateProfileInt( szINISection, "AmPm", 1, szIniName );
		CheckDlgButton(hDlg, IDC_AMPM, n );
		CheckDlgButton(hDlg, IDC_UT, ( n == 0) );
			
		if (fGoAhead == 0)
			EnableWindow(GetDlgItem(hDlg,IDC_DOSMEM), FALSE);

		CheckDlgButton(hDlg, IDC_TOPMOST, GetPrivateProfileInt( szINISection, "topmost", 1, szIniName ) );
		return TRUE;

        case WM_COMMAND:               /* message: received a command */

	    switch (LOWORD(wParam)) {
            case IDOK:

		n = IsDlgButtonChecked(hDlg, IDC_DATE);
		n |= IsDlgButtonChecked(hDlg, IDC_TIME);
		if (nWin95 == 0)
			n |= IsDlgButtonChecked(hDlg, IDC_MEMORY);
		n |= IsDlgButtonChecked(hDlg, IDC_GDI);
		n |= IsDlgButtonChecked(hDlg, IDC_USER);
		if (fGoAhead)
			n |= IsDlgButtonChecked(hDlg, IDC_DOSMEM);

		if (n == 0) {
			MessageBox(hDlg, szMsg_Select, szMsg_App, MB_OK | MB_ICONSTOP);
			break;
		}

		UpdateFrameProfile();

		WritePrivateProfileInt( szINISection, "topmost", (IsDlgButtonChecked(hDlg, IDC_TOPMOST)) );

		WritePrivateProfileInt( szINISection, "date", (IsDlgButtonChecked(hDlg, IDC_DATE)) );
		WritePrivateProfileInt( szINISection, "time", (IsDlgButtonChecked(hDlg, IDC_TIME)) );
		if (nWin95 == 0)
			WritePrivateProfileInt( szINISection, "memory", (IsDlgButtonChecked(hDlg, IDC_MEMORY)) );
		WritePrivateProfileInt( szINISection, "gdi", (IsDlgButtonChecked(hDlg, IDC_GDI)) );
		WritePrivateProfileInt( szINISection, "user", (IsDlgButtonChecked(hDlg, IDC_USER)) );
		if (fGoAhead)
			WritePrivateProfileInt( szINISection, "dosmem", (IsDlgButtonChecked(hDlg, IDC_DOSMEM)) );

		fAmPm = IsDlgButtonChecked(hDlg, IDC_AMPM);
		WritePrivateProfileInt( szINISection, "AmPm", fAmPm );
		
		// reset the status bar
		InitStatBar();

	    case IDCANCEL:
                EndDialog(hDlg, TRUE);
                return TRUE;
	    }

            break;
	}

	return FALSE;               /* Didn't process a message    */
}


/****************************************************************************

    FUNCTION: About(HWND, unsigned, WORD, LONG)

    PURPOSE:  Processes messages for "About" dialog box

****************************************************************************/

BOOL __export CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	char szBuffer[256], szName[64], szCompany[64], szSerial[32];

	switch (message) {
	case WM_INITDIALOG:
		// get name & company from QMAX.INI
		GetPrivateProfileString( "Registration", "Name", "", szName, sizeof(szName), szIniName );
		GetPrivateProfileString( "Registration", "Company", "", szCompany, sizeof(szCompany), szIniName );
		GetPrivateProfileString( "Registration", "S/N", "", szSerial, sizeof(szSerial), szIniName );
		wsprintf( szBuffer, "%s\r\n%s\r\nS/N  %s", (char _far *)szName, (char _far *)szCompany, (char _far *)szSerial );
		SetDlgItemText( hDlg, ABOUTDLGBOX, szBuffer );
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


long CALLBACK __export MainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	HDC hDC;
	long lResult;

	switch (message) {
	case WM_NCPAINT:
		DefWindowProc( hWnd, message, wParam, lParam );

	case WM_NCACTIVATE:
		// draw the status bar
		hDC = GetWindowDC( hWnd );
		DrawStatusBar( hWnd, hDC, aSBItem );
		ReleaseDC( hWnd, hDC );

		// Time & Resources
		DisplayStatus(hWnd, aSBItem, 1);
		if (message == WM_NCACTIVATE)
			return TRUE;
		break;

	case WM_TIMER:
		StatBar_OnTimer();
		break;

        case WM_DESTROY:          /* message: window being destroyed */
		KillTimer( hStatBar, 1 );
		Ctl3dUnregister( hInst );
		WinHelp(hStatBar, szHelpName, HELP_QUIT, 0L);
        if ( hFont ) {
            DeleteObject( hFont );
            hFont = (HFONT)NULL;
        }
		UpdateFrameProfile();
		PostQuitMessage( 0 );
		break;

	case WM_CLOSE:
		if (hDriver != NULL) {
			lResult = SendDriverMessage(hDriver, LCLDRV_UNREGISTER, (LPARAM) hStatBar, NULL);
			CloseDriver(hDriver, NULL, NULL);
			hDriver = NULL;
		}
		return (DefWindowProc( hWnd, message, wParam, lParam ));

	case WM_QUERYENDSESSION:
		UpdateFrameProfile();
		return TRUE;

	case WM_USER:
                // The DOS memory status has changed
       	        // lParam = dwTotalDOS (free DOS in bytes)
		if (hDriver != NULL) {
			// First see if we're disabled -- if so, use
			//   plan B to get free DOS
			if (SendDriverMessage(hDriver, LCLDRV_QUERYENABLE, NULL, NULL) == 0) {
				if (lParam > 1000L)
					dwTotalDOS = lParam;
				if (fGoAhead == 0)
					InitStatBar();
			} else
				InitStatBar();
		} else
			InitStatBar();
		break;

	case WM_SYSCOMMAND:

		switch (wParam) {
		case IDM_CONFIGURE:
			DialogBox(hInst, MAKEINTRESOURCE(CONFIGDLGBOX),  hWnd,  Config);
			return 0;

		case IDM_FONT:
            FontSelect();
			return 0;

		case IDM_HELP:
			WinHelp( hWnd, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_MOver ));
			return 0;

		case IDM_HELPSEARCH:
			WinHelp( hWnd, szHelpName, HELP_PARTIALKEY, (DWORD)((char _far *)"") );
			return 0;

		case IDM_HELPTS:
			WinHelp( hWnd, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_TechS ));
			return 0;

		case IDM_ABOUT:
            DialogBox(hInst, MAKEINTRESOURCE(ABOUTDLGBOX),  hWnd,  About);
			return 0;
		}

        default:
		return (DefWindowProc(hWnd, message, wParam, lParam));
	}

	return 0;
}


void InitStatBar(void)
{
	register int i = 0;
	int top, left;
	TEXTMETRIC tm;
    HFONT hTemp;
	HDC hDC;

	fGoAhead = 0;
	if (hDriver != NULL
	 && SendDriverMessage(hDriver, LCLDRV_QUERYENABLE, NULL, NULL) == 0) {
		fGoAhead = 1;
		// force immediate update of DOSMem value
		PostMessage( hStatBar, WM_TIMER, 0L, 0L );
	}

	// get the international format characters (date & time separators)
	QueryCountryInfo();

	hDC = GetWindowDC(hStatBar);

        // make sure we have our font.
    if ( hFont == NULL ) {
        FontConstruct( hDC );
    }

        // We need to kill off this one before exiting.
    if ( hOldFont == NULL ) {
        hOldFont = SelectObject(hDC, hFont );
    } else {
        hTemp = SelectObject(hDC, hFont );
        DeleteObject( hTemp );
    }

	GetTextMetrics(hDC, &tm);
	dyStatbar = GetSystemMetrics(SM_CYCAPTION);
	dxStatbar = GetSystemMetrics(SM_CXSIZE) + 2;
	dyFontHeight = tm.tmHeight + tm.tmExternalLeading;

	// get the widths & start position of each status bar item
	if (GetPrivateProfileInt( szINISection, "date", 1, szIniName ) != 0) {
		aSBItem[i].nWidth = (int)GetTextExtent(hDC, "12-30-99", 8) + 4;
		aSBItem[i].nStart = 7 + dxStatbar;
		aSBItem[i].fFlag = 0;
		aSBItem[i++].func = StatusDate;
	}

	// time
	if (GetPrivateProfileInt( szINISection, "time", 1, szIniName ) != 0) {
		if (i == 0)
			aSBItem[i].nStart = 7 + dxStatbar;
		else
			aSBItem[i].nStart = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
		aSBItem[i].func = StatusTime;
		aSBItem[i].fFlag = 0;
		aSBItem[i++].nWidth = (int)GetTextExtent(hDC, "22:22:22p", 9) + 4;
		fAmPm = GetPrivateProfileInt( szINISection, "AmPm", 1, szIniName );
	}

	// mode & free space
	if ((nWin95 == 0) && (GetPrivateProfileInt( szINISection, "memory", 1, szIniName ) != 0)) {
		if (i == 0)
			aSBItem[i].nStart = 7 + dxStatbar;
		else
			aSBItem[i].nStart = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
		aSBItem[i].nWidth = (int)GetTextExtent(hDC, "222222 Kb", 9) + 4;
		aSBItem[i].fFlag = 0;
		aSBItem[i++].func = StatusFree;
	}

	// GDI resources free
	if (GetPrivateProfileInt( szINISection, "gdi", 1, szIniName ) != 0) {
		if (i == 0)
			aSBItem[i].nStart = 7 + dxStatbar;
		else
			aSBItem[i].nStart = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
		aSBItem[i].nWidth = (int)GetTextExtent(hDC,"GDI: 55%", 8) + 4;
		aSBItem[i].fFlag = GDI_FLAG;
		aSBItem[i++].func = StatusGDI;
	}

	// user resources free
	if (GetPrivateProfileInt( szINISection, "user", 1, szIniName ) != 0) {
		if (i == 0)
			aSBItem[i].nStart = 7 + dxStatbar;
		else
			aSBItem[i].nStart = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
		aSBItem[i].nWidth = (int)GetTextExtent(hDC, "User: 55%", 9) + 4;
		aSBItem[i].fFlag = USER_FLAG;
		aSBItem[i++].func = StatusUser;
	}

	// low DOS memory free
	if ((fGoAhead) && (GetPrivateProfileInt( szINISection, "dosmem", 1, szIniName ) != 0)) {
		if (i == 0)
			aSBItem[i].nStart = 7 + dxStatbar;
		else
			aSBItem[i].nStart = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
		aSBItem[i].nWidth = (int)GetTextExtent(hDC, "DOS: 55%", 9) + 4;
		aSBItem[i].fFlag = DOSMEM_FLAG;
		aSBItem[i++].func = StatusDOSMem;
	}
    
	// set the timer for the status bar time of day display (2 seconds)
	SetTimer( hStatBar, 1, (unsigned int)2000, 0L );

	if (i != 0)
		dxStatbar = aSBItem[i-1].nWidth + aSBItem[i-1].nStart + 9;
	if (nWin95)
		dxStatbar += GetSystemMetrics(SM_CXSIZE) + 2;

	nEntries = i;

	nX = GetDeviceCaps(hDC, HORZRES);
	nY = GetDeviceCaps(hDC, VERTRES);

	ReleaseDC(hStatBar, hDC);

	left = GetPrivateProfileInt( szINISection, "left", (nX - dxStatbar), szIniName );
	top = GetPrivateProfileInt( szINISection, "top", 0, szIniName );

	nTopmost = GetPrivateProfileInt( szINISection, "topmost", 1, szIniName );

    if( nTopmost ) {
        SetWindowPos( hStatBar, HWND_TOPMOST, left, top, dxStatbar, dyStatbar, SWP_SHOWWINDOW );
    } else {
        SetWindowPos( hStatBar, HWND_NOTOPMOST, left, top, dxStatbar, dyStatbar, SWP_SHOWWINDOW | SWP_NOZORDER | SWP_NOACTIVATE );
    }

	nSBInited = 1;
}


static void StatusDate(char *szString, BOOL fRedraw)
{
	static char szOldDate[16] = "";
	DATETIME sysDateTime;

	// get the current date & time
	QueryDateTime( &sysDateTime );
	lstrcpy( szString, FormatDate( sysDateTime.month, sysDateTime.day, sysDateTime.year ));

	if ((fRedraw == 0) && (lstrcmp( szString, szOldDate ) == 0))
		*szString = '\0';
	lstrcpy( szOldDate, szString );
}


static void StatusTime(char *szString, BOOL fRedraw)
{
	DATETIME sysDateTime;
	int cTimeFmt = 0;

	// get the current date & time
	QueryDateTime(&sysDateTime);

	// check for 12 hour format
	if (fAmPm) {
		cTimeFmt = 'P';
		if (sysDateTime.hours < 12) {
			if (sysDateTime.hours == 0)
				sysDateTime.hours = 12;
			cTimeFmt = 'A';
		} else if (sysDateTime.hours > 12)
			sysDateTime.hours -= 12;
	} else
		cTimeFmt = 0;

	// round to 2-second increment
	sysDateTime.seconds &= 0xFE;

	wsprintf(szString, ((cTimeFmt == 0) ? "%02d%c%02d%c%02d" : "%2d%c%02d%c%02d%c"),sysDateTime.hours,gaCountryInfo.szTimeSeparator[0],sysDateTime.minutes,gaCountryInfo.szTimeSeparator[0],sysDateTime.seconds,cTimeFmt);
}


static void StatusFree(char *szString, BOOL fRedraw)
{
	static long lOldRAMFree = 0L;
	long lRAMFree;

	lRAMFree = GetFreeSpace(0) >> 10;
	if ((fRedraw == 0) && (lOldRAMFree == lRAMFree))
		*szString = '\0';
	else
		wsprintf(szString, "%6lu Kb", lRAMFree);
	lOldRAMFree = lRAMFree;
}


static void StatusGDI(char *szString, BOOL fRedraw)
{
	static DWORD lOldGDIFree = 0L;

	lGDIFree = GetFreeSystemResources(GFSR_GDIRESOURCES);
	if ((fRedraw == 0) && (lOldGDIFree == lGDIFree))
		*szString = '\0';
	else
		wsprintf(szString, GDI_FREE, lGDIFree);
	lOldGDIFree = lGDIFree;
}


static void StatusUser(char *szString, BOOL fRedraw)
{
	static DWORD lOldUserFree = 0L;

	lUserFree = GetFreeSystemResources(GFSR_USERRESOURCES);
	if ((fRedraw == 0) && (lOldUserFree == lUserFree))
		*szString = '\0';
	else
		wsprintf(szString, USER_FREE, lUserFree);
	lOldUserFree = lUserFree;
}


static void StatusDOSMem(char *szString, BOOL fRedraw)
{
	static DWORD lOldDOSMem = 0;
	DWORD dwSizeDOS;

	// Open it so we can send messages to it
	if (hDriver != NULL) {

		// Get lowest free segment ever encountered
		dwSizeDOS = (640L*1024L) - (16L*SendDriverMessage(hDriver, LCLDRV_QUERYLOWSEG, NULL, NULL));

		// At this point, 100*dwTotalDOS/dwSizeDOS is the percentage
		//   of free low DOS
		lDOSMem = (dwTotalDOS * 100L) / dwSizeDOS;
	} else
		lDOSMem = 0L;

	if ((fRedraw == 0) && (lOldDOSMem == lDOSMem))
		*szString = '\0';
	else
		wsprintf(szString, DOS_MEM, lDOSMem);
	lOldDOSMem = lDOSMem;
}


void StatBar_OnTimer(void)
{
	DisplayStatus(hStatBar, aSBItem, 0);
}


// display status bar info
VOID DisplayStatus(HWND hWnd, AITEM aItem[], BOOL fRedraw)
{
	register int i, n;
	char szString[128];
	RECT rc, rcTemp;
	HBRUSH hBrush;
	HDC hDC;

	// Make sure the status bar has finished initializing
	if ((nSBInited == 0) || (nEntries == 0))
		return;

	hDC = GetWindowDC(hWnd);
	SetBkColor(hDC, GetSysColor(COLOR_BTNFACE));
    SetTextColor(hDC, GetSysColor(COLOR_BTNTEXT));
    
    SelectObject(hDC, hFont );

	GetWindowRect(hWnd, &rc);
	rc.right = (rc.right - rc.left) - 2;
	rc.left = 0;
	rc.bottom = (rc.bottom - rc.top) - 1;
	rc.top = 1;

	for (i = 0; (i < nEntries); i++) {

		rcTemp.top = 3 + rc.top;
		rcTemp.bottom = rc.bottom - 3;
		rcTemp.left = rc.left + aItem[i].nStart;
		rcTemp.right = rcTemp.left + aItem[i].nWidth - 1;

		(*(aItem[i].func))(szString, fRedraw);
		if (szString[0] == '\0')
			continue;		// value hasn't changed

		hBrush = CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
		FillRect(hDC, &rcTemp, hBrush);
		DeleteObject(hBrush);
		SetBkMode(hDC, TRANSPARENT);

		if (aItem[i].fFlag != 0) {

			int nRight;
			DWORD lVal;

			nRight = rcTemp.right;

			if (aItem[i].fFlag == GDI_FLAG)
				lVal = lGDIFree;
			else if (aItem[i].fFlag == USER_FLAG)
				lVal = lUserFree;
			else
				lVal = lDOSMem;

			n = (int)(((rcTemp.right - rcTemp.left) * lVal) / 100);

			// Green
			if (lVal > 50)
				hBrush = CreateSolidBrush(RGB(0,255,0));
			// Yellow
			else if (lVal > 30)
				hBrush = CreateSolidBrush(RGB(255,255,0));
			// Red
			else
				hBrush = CreateSolidBrush(RGB(255,0,0));

			rcTemp.right = rcTemp.left + n;
			FillRect(hDC, &rcTemp, hBrush);
			DeleteObject(hBrush);
			rcTemp.right = nRight;
		}

		rcTemp.top = (dyStatbar - dyFontHeight) / 2;
		DrawText(hDC, szString, lstrlen(szString), &rcTemp, DT_CENTER);
	}

	ReleaseDC(hWnd,hDC);
}


// display the status bar
void DrawStatusBar(HWND hwnd, HDC hDC, AITEM SBItem[])
{
	register int i;
	HBRUSH hBrush;
	RECT rc, rcTemp;

	if (nEntries == 0)
		return;

	GetWindowRect(hwnd, &rc);
	rc.right = (rc.right - rc.left) - 1;
	if (nWin95)
		rc.right -= (GetSystemMetrics(SM_CXSIZE) + 2);
	rc.left = GetSystemMetrics(SM_CXSIZE) + 2;
	rc.bottom = (rc.bottom - rc.top) - 1;
	rc.top = 1;

	// draw the frame

	hBrush = CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
	FillRect(hDC, &rc, hBrush);
	DeleteObject(hBrush);

	// Shadow color

	hBrush = CreateSolidBrush(GetSysColor(COLOR_BTNSHADOW));

	// Top and left shadow

	rcTemp = rc;
	rcTemp.top = rc.top + 2;
	rcTemp.bottom = rcTemp.top + 1;

	// Top of Item
	for (i = 0; (i < nEntries); i++) {
		rcTemp.left = (SBItem[i].nStart - 1);
		rcTemp.right = (rcTemp.left + SBItem[i].nWidth + 1);
		FillRect(hDC, &rcTemp, hBrush);
	}

	// Left
	rcTemp = rc;
	rcTemp.top += 2;
	rcTemp.bottom -= 2;

	// Left of bar
	for (i = 0; (i < nEntries); i++) {
		rcTemp.left = (SBItem[i].nStart - 1);
		rcTemp.right = (rcTemp.left + 1);
		FillRect(hDC, &rcTemp, hBrush);
	}

	DeleteObject(hBrush);

	// Right, top and bottom hilight

	// Hilight color
	hBrush = CreateSolidBrush(GetSysColor(COLOR_BTNHIGHLIGHT));

	rcTemp = rc;
	rcTemp.top = (rc.bottom - 3);
	rcTemp.bottom = (rcTemp.top + 1);

	// Bottom of Item
	for (i = 0; (i < nEntries); i++) {
		rcTemp.left = SBItem[i].nStart;
		rcTemp.right = (rcTemp.left + SBItem[i].nWidth + 1);
		FillRect(hDC, &rcTemp, hBrush);
	}

	rcTemp = rc;
	rcTemp.top += 3;
	rcTemp.bottom -= 2;

	// Right of Item
	for (i = 0; (i < nEntries); i++) {
		rcTemp.left = (SBItem[i].nWidth + SBItem[i].nStart);
		rcTemp.right = (rcTemp.left + 1);
		FillRect(hDC, &rcTemp, hBrush);
	}

	// Across the top
	rcTemp = rc;
	rcTemp.bottom = 1;
	FillRect(hDC, &rcTemp, hBrush);

	DeleteObject(hBrush);
}


// get the country code (for date formatting)
static void QueryCountryInfo(void)
{
	static char section[] = "intl";
	
	// set am/pm info (if TimeFmt==0, use default country info)
	gaCountryInfo.fsTimeFmt = 1;
	gaCountryInfo.fsDateFmt = (short)GetProfileInt( section, "iDate", 0 );
	gaCountryInfo.nCountryID = (short)GetProfileInt( section, "iCountry", 0 );

	GetProfileString( section, "sThousand", ",", gaCountryInfo.szThousandsSeparator, 2 );
	GetProfileString( section, "sDate", "-", gaCountryInfo.szDateSeparator, 2 );
	GetProfileString( section, "sTime", ":", gaCountryInfo.szTimeSeparator, 2 );
	GetProfileString( section, "sDecimal", ".", gaCountryInfo.szDecimal, 2 );
}


// Get the current date & time
static void _fastcall QueryDateTime(DATETIME *sysDateTime)
{
	_dos_gettime((struct dostime_t *)sysDateTime);
	_dos_getdate((struct dosdate_t *)&(sysDateTime->day));
}


// return the date, formatted appropriately by country type
static char * PASCAL FormatDate(int month, int day, register int year)
{
	static char date[10];
	register int i;

	// make sure year is only 2 digits
	year %= 100;

	if (gaCountryInfo.fsDateFmt == 1) {

		// Europe = dd-mm-yy
		i = day;			// swap day and month
		day = month;
		month = i;

	} else if (gaCountryInfo.fsDateFmt == 2) {

		// Japan = yy-mm-dd
		i = month;			// swap everything!
		month = year;
		year = day;
		day = i;
	}

	wsprintf( date, TIME_FMT, month, day, year );

	return date;
}


// make up for the lack of a Windows API!
void WritePrivateProfileInt(char *szSection, char *szItem, int nValue)
{
	char szBuffer[16];

	wsprintf( szBuffer, "%d", nValue );
	WritePrivateProfileString( szSection, szItem, szBuffer, szIniName );
}


// Update frame window profile in INI file or registration database
VOID UpdateFrameProfile(void)
{
	RECT rect;

	GetWindowRect( hStatBar, &rect );

	// save normal position
	WritePrivateProfileInt( szINISection, "left", rect.left );
	WritePrivateProfileInt( szINISection, "top", rect.top );
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
void MakePath(char *pszDir, char *pszFileName, char *pszTarget)
{
	register int nLength;

	if (pszTarget != pszDir)
		lstrcpy( pszTarget, pszDir );
	nLength = lstrlen( pszTarget );

	if ((*pszTarget) && ( pszTarget[nLength-1] != '\\' ) && ( pszTarget[nLength-1] != '/' ))
		lstrcat( pszTarget, "\\" );

	lstrcat( pszTarget, pszFileName );
}

//------------------------------------------------------------------
void FontSelect()
{
    BOOL bRes;
    CHOOSEFONT chf;
    HDC hDC;
    HFONT hfTemp;
    
    hDC = GetDC( hStatBar );

    memset( &chf, 0, sizeof( CHOOSEFONT ));

    chf.hDC = CreateCompatibleDC( hDC );
    chf.lStructSize = sizeof( CHOOSEFONT );
    chf.hwndOwner = hStatBar;
    chf.lpLogFont = &lf_Font;
    chf.iPointSize = 10;
    chf.Flags = CF_SCREENFONTS | CF_INITTOLOGFONTSTRUCT 
                | CF_ANSIONLY | CF_NOSIMULATIONS 
                | CF_ENABLETEMPLATE;
    chf.hInstance = hInst;
    chf.nFontType = SCREEN_FONTTYPE;
    chf.nSizeMin = 6;
    chf.nSizeMax = 12;

    chf.lpTemplateName = (LPSTR)MAKEINTRESOURCE( FONTDLGBOX );
    
    if (( bRes = ChooseFont( &chf )) != 0 ) {
        hfTemp = CreateFontIndirect( &lf_Font );
        SelectObject(hDC, hfTemp );
        DeleteObject( hFont );
        hFont = hfTemp;
    }

    ReleaseDC( hStatBar, hDC );
    DeleteDC( chf.hDC );

    if ( bRes ) {

		WritePrivateProfileString( szINISection, "Font", 
                                   lf_Font.lfFaceName, szIniName );

		WritePrivateProfileInt( szINISection, "FontHeight", lf_Font.lfHeight);
		WritePrivateProfileInt( szINISection, "FontWidth", lf_Font.lfWidth);

		WritePrivateProfileInt( szINISection, "FontWeight", lf_Font.lfWeight);
		WritePrivateProfileInt( szINISection, "FontItalic", lf_Font.lfItalic);

		WritePrivateProfileInt( szINISection, "FontPitch", lf_Font.lfPitchAndFamily);
		WritePrivateProfileInt( szINISection, "FontQuality", lf_Font.lfQuality);
		WritePrivateProfileInt( szINISection, "FontOutPrecision", lf_Font.lfOutPrecision);
		WritePrivateProfileInt( szINISection, "FontClipPrecision", lf_Font.lfClipPrecision);

            // save the position so init does not kill it.  
		UpdateFrameProfile();
            
            // reload the parameters.
        InitStatBar();

            // make sure all windows are updated.
        DisplayStatus(hStatBar, aSBItem, 1);
    }
}
    
void FontConstruct( HDC hDC )
{
        // This is a startup function.
        // Don't call this function unless hFont == NULL.

        // First, clear the LOGFONT structure.
    memset( &lf_Font, 0, sizeof( LOGFONT ));
    
            // set the default critical factors.
    GetPrivateProfileString( szINISection, "Font", "System", lf_Font.lfFaceName, 
                                    sizeof( lf_Font.lfFaceName ), szIniName );

    lf_Font.lfHeight = GetPrivateProfileInt( szINISection, "FontHeight", 
                                             -13, szIniName );

    lf_Font.lfWidth = GetPrivateProfileInt( szINISection, "FontWidth", 
                                             0, szIniName );

    lf_Font.lfWeight = GetPrivateProfileInt( szINISection, "FontWeight", 
                                             FW_BOLD, szIniName );

    lf_Font.lfItalic = GetPrivateProfileInt( szINISection, "FontItalic", 
                                             0, szIniName );

	lf_Font.lfPitchAndFamily = GetPrivateProfileInt( szINISection, "FontPitch",
                                                    34, szIniName );

    lf_Font.lfQuality = GetPrivateProfileInt( szINISection, "FontQuality", 
                                                    1, szIniName );

    lf_Font.lfOutPrecision = GetPrivateProfileInt( szINISection, "FontOutPrecision",
                                                    1, szIniName );

    lf_Font.lfClipPrecision = GetPrivateProfileInt( szINISection, "FontClipPrecision",
                                                    2, szIniName );


    hFont = CreateFontIndirect( &lf_Font );
}

