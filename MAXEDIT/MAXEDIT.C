//' $Header:   P:/PVCS/MAX/MAXEDIT/MAXEDIT.C_V   1.18   10 Jul 1996 10:58:14   BOB  $
//  MAXEDIT.C - .INI and .PRO editor
//  Copyright (c) 1995-6 Qualitas, Inc.  GNU General Public License version 3.

#include "maxedit.h"
#include "commdlg.h"

#include <malloc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

    // define message variables
#define SETUP_MSG_DEFVARS 1
#include "messages.h"

#define SEGMENT 	4096

/* global variables used in this module or among more than one module */
PRINTDLG pd;			    /* Common print dialog structure */
OFSTRUCT of;

HANDLE hInst;			    /* Program instance handle		     */
HANDLE hAccel;			    /* Main accelerator resource	     */
HWND hwndFrame		 = NULL;    /* Handle to main window		     */
HWND hwndMDIClient	 = NULL;    /* Handle to MDI client		     */
HWND hwndToolbar	 = NULL;
HWND hwndActive 	 = NULL;    /* Handle to currently activated child   */
HWND hwndActiveEdit	 = NULL;    /* Handle to edit control		     */
LPSTR lpMenu	     = (LPSTR)IDMAXEDIT;  /* Contains the resource id of the */
				    /* current frame menu		     */
char szFrame[] = "MaxEditFrame";   /* Class name for "frame" window */
char szChild[] = "MaxEditChild";   /* Class name for MDI window     */
char szIniName[80];		// MAXEDIT.INI pathname
char szINISection[] = "MAXedit - General";
char szHelpName[80];
char szMaxPath[80];

/* Forward declarations of helper functions in this module */
void WalkWindowList(void);
VOID PASCAL InitializeMenu ( HANDLE );
VOID PASCAL CommandHandler ( HWND, WORD );
BOOL PASCAL QueryCloseAllChildren ( VOID );
int  PASCAL QueryCloseChild ( HWND );
static HWND AlreadyOpen( char * );
static void PASCAL MakePathName ( char *, char * );
static void StripLeading( char *, char * );
static void StripTrailing( char *arg, char *);
static void WritePrivateProfileInt(char *, char *, int);
BOOL FindBreak( LPSTR *lpStart, LPSTR *lpEnd, int nCount, char ch );
int FormatLine( HDC hDC, LPSTR szIn, WORD nInLen, LPSTR FAR *lpRetStr,
				    WORD nMaxPoints, WORD nTabs );


int PASCAL WinMain( HANDLE hInstance, HANDLE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow )
{
    MSG msg;
    char szTemp[80];

    if (hPrevInstance) {
	WalkWindowList( );
	return 0;
    }

    hInst = hInstance;

    // set .INI name
    GetWindowsDirectory( szIniName, 80 );
    MakePathName( szIniName, "QMAX.INI" );

    // get name of .HLP file
    GetPrivateProfileString( "CONFIG", "Qualitas MAX Path", "c:\\qmax", szMaxPath, 80, szIniName );
    GetPrivateProfileString( "CONFIG", "Qualitas MAX Help", "maxhelp.hlp", szTemp, 80, szIniName );
    lstrcpy( szHelpName, szMaxPath );
    MakePathName( szHelpName, szTemp );

    if (!InitializeApplication ())
	return 0;

    // initialize 3-D support
    Ctl3dRegister( hInstance );
    Ctl3dAutoSubclass( hInstance );

    if (!InitializeInstance ( lpszCmdLine, nCmdShow ))
	return 0;

    // main message loop
    while (GetMessage (&msg, NULL, 0, 0)) {
	if ( !TranslateMDISysAccel (hwndMDIClient, &msg) && !TranslateAccelerator (hwndFrame, hAccel, &msg)) {
	    TranslateMessage (&msg);
	    DispatchMessage (&msg);
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
			if (lstrcmpi(szModuleName, "MAXedit") == 0) {
				if (IsIconic(hWnd))
					ShowWindow(hWnd, SW_RESTORE);
				SetWindowPos( hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW );
				SetFocus( hWnd );
				break;
			}
		}

		hWnd = GetWindow(hWnd, GW_HWNDNEXT);	// Go on to next window
	}
}


BOOL PASCAL InitializeApplication( void )
{
    WNDCLASS	wc;

    /* Register the frame class */
    wc.style	     = 0;
    wc.lpfnWndProc   = MPFrameWndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInst;
    wc.hIcon	     = LoadIcon( hInst, IDMAXEDIT );
    wc.hCursor	     = LoadCursor( NULL, IDC_ARROW );
    wc.hbrBackground = COLOR_APPWORKSPACE+1;
    wc.lpszMenuName  = IDMAXEDIT;
    wc.lpszClassName = szFrame;

    if (!RegisterClass (&wc) )
	return FALSE;

    /* Register the MDI child class */
    wc.lpfnWndProc   = MPMDIChildWndProc;
    wc.hIcon	     = LoadIcon( hInst, IDCHILDICO );
    wc.lpszMenuName  = NULL;
    wc.cbWndExtra    = CBWNDEXTRA;
    wc.lpszClassName = szChild;

    /* fill in non-variant fields of PRINTDLG struct. */
    pd.lStructSize    = sizeof( PRINTDLG );
    pd.hDevMode       = NULL;
    pd.hDevNames      = NULL;
    pd.Flags	      = PD_RETURNDC | PD_NOSELECTION | PD_NOPAGENUMS;
    pd.nCopies	      = 1;

    if (!RegisterClass(&wc))
	return FALSE;

    wc.style	     = CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNCLIENT;
    wc.lpfnWndProc   = ControlBarWndProc ;
    wc.cbClsExtra    = 0 ;
    wc.cbWndExtra    = 0 ;
    wc.hInstance     = hInst ;
    wc.hIcon	     = NULL;
    wc.hCursor	     = LoadCursor (NULL, IDC_ARROW) ;
    wc.hbrBackground = GetStockObject ( LTGRAY_BRUSH );
    wc.lpszMenuName  = (LPSTR) NULL ;
    wc.lpszClassName = "classControlBar" ;

    if (!RegisterClass (&wc))
	return (FALSE);

    return TRUE;
}


BOOL PASCAL InitializeInstance( LPSTR lpCmdLine, WORD nCmdShow )
{
    extern HWND hwndMDIClient;
    char sz[260];
    OFSTRUCT of;
    HFILE fh;
    int fSection = 0;
    int nLeft, nTop, nWidth, nHeight;

    /* Get the base window title */
    LoadString (hInst, IDS_APPNAME, sz, sizeof(sz));

    nLeft = GetPrivateProfileInt( szINISection, "left", CW_USEDEFAULT, szIniName );
    nTop = GetPrivateProfileInt( szINISection, "top", CW_USEDEFAULT, szIniName );
    nWidth = GetPrivateProfileInt( szINISection, "width", CW_USEDEFAULT, szIniName );
    nHeight = GetPrivateProfileInt( szINISection, "height", CW_USEDEFAULT, szIniName );

    /* Create the frame */
    hwndFrame = CreateWindow(szFrame, sz, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
	nLeft, nTop, nWidth, nHeight, NULL, NULL, hInst, NULL);

    if ((!hwndFrame) || (!hwndMDIClient))
	return FALSE;

    // initialize the toolbar
    BuildTools ( );

    pd.hwndOwner = hwndFrame;

    /* Load main menu accelerators */
    if (!(hAccel = LoadAccelerators (hInst, IDMAXEDIT)))
	return FALSE;

    /* Display the frame window */
    ShowWindow (hwndFrame, nCmdShow);
    UpdateWindow (hwndFrame);

    // display the toolbar window
    ShowWindow( hwndToolbar, SW_SHOW );

    /* Add the MDI windows */

    // search for .INI file QMAX.INI
    if ((fh = OpenFile( szIniName, &of, OF_READ )) != HFILE_ERROR ) {

	int nMaxSize, i, n;

	while ((( nMaxSize = _lread( fh, sz, sizeof(sz) - 1 )) != HFILE_ERROR ) && (nMaxSize > 0)) {

		// get a line and set the file pointer to the next line
		sz[nMaxSize] = '\0';
		StripLeading( sz, " \t\r\n\x1A" );

		i = n = 0;
		sscanf( sz, "%*[^\r\n\x1A]%n %n", &n, &i );
		if (n > 0)
			sz[n] = '\0';

		// ignore comments & section headers
		if ((sz[0] != ';') && (sz[0] != '\0'))
		if (fSection == 0) {
			if (lstrcmpi(sz, "[MAXedit - Files]") == 0)
				fSection = 1;
		} else {

			if (sz[0] == '[')
				break;

			if (n > 0) {
				StripTrailing( sz, "=" );
				AddFile( sz );
			}

			if (i == 0)
				break;
		}

		(void)_llseek( fh, (long)(i - nMaxSize), SEEK_CUR );
	}

	_lclose (fh);
    }

    if (fSection == 0) {

	AddFile( "c:\\config.sys" );
	AddFile( "c:\\autoexec.bat" );

	GetWindowsDirectory( sz, 128 );
	MakePathName( sz, "system.ini" );
	AddFile( sz );

	GetWindowsDirectory( sz, 128 );
	MakePathName( sz, "win.ini" );
	AddFile( sz );
    }

    return TRUE;
}


LONG FAR PASCAL __export MPFrameWndProc ( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
	switch ( msg ) {
	case WM_CREATE:
	{
	    CLIENTCREATESTRUCT ccs;

	    wIconWidth = 28;
	    wIconHeight = 36;

	    /* Find window menu where children will be listed */
	    ccs.hWindowMenu = GetSubMenu (GetMenu(hwnd), WINDOWMENU);
	    ccs.idFirstChild = IDM_WINDOWCHILD;

	    /* Create the MDI client filling the client area */
	    hwndMDIClient = CreateWindow ( "mdiclient",
		NULL, WS_CHILD | WS_CLIPCHILDREN | WS_VSCROLL | WS_HSCROLL,
		0, 0, 0, 0, hwnd, 0xCAC, hInst, (LPSTR)&ccs);

	    ShowWindow ( hwndMDIClient, SW_SHOW );
	    break;
	}

	case WM_INITMENU:
	    /* Set up the menu state */
	    InitializeMenu ((HMENU)wParam);
	    break;

	case WM_COMMAND:
	    /* Direct all menu selection or accelerator commands to another
	     * function */
	    CommandHandler ( hwnd, wParam );
	    break;

	case WM_SIZE:
	    if ((wParam == SIZENORMAL) || (wParam == SIZEFULLSCREEN)) {

		WORD wWidth, wHeight;

		wWidth	= LOWORD (lParam);
		wHeight = HIWORD (lParam);

		MoveWindow( hwndMDIClient, 0, TOOLBAR_HEIGHT, wWidth, wHeight - TOOLBAR_HEIGHT, TRUE );
		MoveWindow ( hwndToolbar, 0, 0, wWidth, TOOLBAR_HEIGHT, TRUE );
	    }
	    break;

	case WM_CLOSE:
	case WM_QUERYENDSESSION:
	{
	    RECT rect;

	    GetWindowRect( hwnd, &rect );
	    WritePrivateProfileInt( szINISection, "left", rect.left );
	    WritePrivateProfileInt( szINISection, "top", rect.top );
	    WritePrivateProfileInt( szINISection, "width", rect.right - rect.left );
	    WritePrivateProfileInt( szINISection, "height", rect.bottom - rect.top );

	    if (msg == WM_CLOSE) {
		/* don't close if any children cancel the operation */
		if (!QueryCloseAllChildren ())
			break;
		    WinHelp(hwnd, szHelpName, HELP_QUIT, 0L);
		    DestroyWindow (hwnd);
		    break;
	    }

	    /*	Before session ends, check that all files are saved */
	    return QueryCloseAllChildren ();
	}

	case WM_DESTROY:

	DestroyTools();

	    // free the PrintDlg allocated memory.
	if (pd.hDevNames) {
	    GlobalFree(pd.hDevNames);
	    pd.hDevNames = 0;
	}

	if (pd.hDevMode) {
	    GlobalFree(pd.hDevMode);
	    pd.hDevMode = 0;
	}

	    Ctl3dUnregister( hInst );
	    PostQuitMessage ( 0 );
	    break;

	default:
	    /*	use DefFrameProc() instead of DefWindowProc() since there
	     *	are things that have to be handled differently because of MDI */
	    return DefFrameProc ( hwnd, hwndMDIClient, msg, wParam, lParam );
	}

	return 0;
}


LONG FAR PASCAL __export MPMDIChildWndProc ( HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
	HWND hwndEdit;
	LPVOID lpPtr;
	GLOBALHANDLE ghEditDS;

	switch (msg){
	case WM_CREATE:

	    if ((ghEditDS = GlobalAlloc( GMEM_DDESHARE | GMEM_MOVEABLE | GMEM_ZEROINIT, SEGMENT )) == 0) {
		MessageBox( hwnd, szMsg_CantAlloc, szMsg_NoMem, MB_OK | MB_ICONSTOP );
		PostQuitMessage ( 0 );
		return 0;
	    }

	    lpPtr = GlobalLock( ghEditDS );
	    LocalInit(HIWORD((LONG)lpPtr), 0, (WORD)(GlobalSize(ghEditDS) - 16));
	    UnlockSegment( HIWORD((LONG)lpPtr) );

	    /* Create an edit control */
	    hwndEdit = CreateWindow ( "edit", NULL,
		WS_CHILD|WS_HSCROLL | WS_MAXIMIZE | WS_VISIBLE |
		WS_VSCROLL | ES_AUTOHSCROLL | ES_AUTOVSCROLL | ES_MULTILINE,
		0, 0, 0, 0, hwnd, ID_EDIT, HIWORD((LONG)lpPtr), NULL);

	    // increase edit control limit to 64K
	    SendMessage(hwndEdit, EM_LIMITTEXT, 0xFFF0, 0L);

	    /* Remember the window handle and initialize some window attributes */
	    SetWindowWord ( hwnd, GWW_HWNDEDIT, (WORD)hwndEdit );
	    SetWindowWord ( hwnd, GWW_CHANGED, FALSE );
	    SetWindowWord ( hwnd, GWW_WORDWRAP, FALSE );
	    SetWindowWord ( hwnd, GWW_UNTITLED, TRUE );
	    SetWindowLong ( hwnd, GWW_EDITPTR, (LONG)lpPtr );
	    SetFocus ( hwndEdit );
	    break;

	case WM_MDIACTIVATE:
	    /* If we're activating this child, remember it */
	    if (wParam) {
		hwndActive     = hwnd;
		hwndActiveEdit = (HWND)GetWindowWord (hwnd, GWW_HWNDEDIT );
	    } else {
		hwndActive     = NULL;
		hwndActiveEdit = NULL;
	    }
	    break;

	case WM_QUERYENDSESSION:
	    /* Prompt to save the child */
	    return (!QueryCloseChild ( hwnd ));

	case WM_CLOSE:
	    /* If its OK to close the child, do so, else ignore */
	    if (QueryCloseChild ( hwnd ))
	    goto CallDCP;
	else
	    break;

	case WM_SIZE:
	{
	    RECT rc;

	    /* On creation or resize, size the edit control. */
	    hwndEdit = GetWindowWord ( hwnd, GWW_HWNDEDIT );
	    GetClientRect ( hwnd, &rc );
	    MoveWindow ( hwndEdit, rc.left, rc.top,
			rc.right-rc.left, rc.bottom-rc.top, TRUE );
	    goto CallDCP;
	}

	case WM_SETFOCUS:
	    SetFocus (GetWindowWord (hwnd, GWW_HWNDEDIT ));
	    break;

	case WM_COMMAND:

		switch (wParam){
		case ID_EDIT:

			switch (HIWORD(lParam)) {
			case EN_CHANGE:

			    /* If the contents of the edit control have changed,
			       set the changed flag */
			    SetWindowWord (hwnd, GWW_CHANGED, TRUE);
			    break;

			case EN_ERRSPACE:
			    /* If the control is out of space, honk */
			    MessageBeep (0);
			    break;

			default:
			    goto CallDCP;
		    }
		    break;

		case IDM_FILESAVE:

		    /* If empty or unchanged file, ignore save */
		    if ((GetWindowWord(hwnd, GWW_UNTITLED)) && (!ChangeFile(hwnd)))
			break;

		    /* Save the contents of the edit control and reset the
		     * changed flag */
		    SaveFile (hwnd);
		    SetWindowWord (hwnd, GWW_CHANGED, FALSE);
		    break;

		default:
		    goto CallDCP;
	    }
	    break;

	default:
CallDCP:
	    /* Again, since the MDI default behaviour is a little different,
	     * call DefMDIChildProc instead of DefWindowProc() */
	    return DefMDIChildProc (hwnd, msg, wParam, lParam);
	}

	return FALSE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : AboutDlgProc ( hwnd, msg, wParam, lParam )		    *
 *									    *
 *  PURPOSE    : Dialog function for the About MAXEDIT... dialog.	    *
 *									    *
 ****************************************************************************/
BOOL CALLBACK __export AboutDlgProc ( HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam )
{
	char szBuffer[256], szName[64], szCompany[64], szSerial[32];

	switch (msg) {
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


/****************************************************************************
 *									    *
 *  FUNCTION   : InitializeMenu ( hMenu )				    *
 *									    *
 *  PURPOSE    : Sets up greying, enabling and checking of main menu items  *
 *		 based on the app's state.                                  *
 *									    *
 ****************************************************************************/
VOID PASCAL InitializeMenu ( register HANDLE hmenu )
{
    register WORD status;
    int i;
    long l;

    /* Is there any active child to talk to? */
    if ( hwndActiveEdit ) {

	/* If edit control can respond to an undo request, enable the
	 * undo selection. */
	if (SendMessage (hwndActiveEdit, EM_CANUNDO, 0, 0L))
	    status = MF_ENABLED;
	else
	    status = MF_GRAYED;
	EnableMenuItem (hmenu, IDM_EDITUNDO, status);

	/* If edit control is non-empty, allow cut/copy/clear */
	l = SendMessage (hwndActiveEdit, EM_GETSEL, 0, 0L);
	status = (HIWORD(l) == LOWORD(l)) ? MF_GRAYED : MF_ENABLED;
	EnableMenuItem (hmenu, IDM_EDITCUT, status);
	EnableMenuItem (hmenu, IDM_EDITCOPY, status);
	EnableMenuItem (hmenu, IDM_EDITCLEAR, status);

	status=MF_GRAYED;
	/* If the clipboard contains some CF_TEXT data, allow paste */
	if (OpenClipboard (hwndFrame)){
	    int wFmt = 0;

	    while (wFmt = EnumClipboardFormats (wFmt)) {
		if (wFmt == CF_TEXT) {
		    status = MF_ENABLED;
		    break;
		}
	    }

	    CloseClipboard ();
	}

	EnableMenuItem (hmenu, IDM_EDITPASTE, status);

	/* Enable search menu items only if there is a search string */
	if (*szSearch)
	    status = MF_ENABLED;
	else
	    status = MF_GRAYED;
	EnableMenuItem (hmenu, IDM_SEARCHNEXT, status);
	EnableMenuItem (hmenu, IDM_SEARCHPREV, status);

	/* select all and wrap toggle always enabled */
	status = MF_ENABLED;
	EnableMenuItem(hmenu, IDM_EDITSELECT, status);
	EnableMenuItem(hmenu, IDM_SEARCHFIND, status);

    } else {

	/* There are no active child windows */
	status = MF_GRAYED;

	/* No active window, so disable everything */
	for (i = IDM_EDITFIRST; i <= IDM_EDITLAST; i++)
	    EnableMenuItem (hmenu, i, status);

	for (i = IDM_SEARCHFIRST; i <= IDM_SEARCHLAST; i++)
	    EnableMenuItem (hmenu, i, status);

	EnableMenuItem (hmenu, IDM_FILEPRINT, status);
    }

    /* The following menu items are enabled if there is an active window */
    EnableMenuItem (hmenu, IDM_FILESAVE, status);
    EnableMenuItem (hmenu, IDM_FILESAVEAS, status);
    EnableMenuItem (hmenu, IDM_WINDOWTILE, status);
    EnableMenuItem (hmenu, IDM_WINDOWCASCADE, status);
    EnableMenuItem (hmenu, IDM_WINDOWICONS, status);
    EnableMenuItem (hmenu, IDM_WINDOWCLOSEALL, status);
}


/****************************************************************************
 *									    *
 *  FUNCTION   : CloseAllChildren ()					    *
 *									    *
 *  PURPOSE    : Destroys all MDI child windows.			    *
 *									    *
 ****************************************************************************/
VOID PASCAL CloseAllChildren ()
{
    register HWND hwndT;

    /* hide the MDI client window to avoid multiple repaints */
    ShowWindow(hwndMDIClient,SW_HIDE);

    /* As long as the MDI client has a child, destroy it */
    while ( hwndT = GetWindow (hwndMDIClient, GW_CHILD)){

	/* Skip the icon title windows */
	while (hwndT && GetWindow (hwndT, GW_OWNER))
	    hwndT = GetWindow (hwndT, GW_HWNDNEXT);

	if (!hwndT)
	    break;

	SendMessage (hwndMDIClient, WM_MDIDESTROY, (WORD)hwndT, 0L);
    }
}


/****************************************************************************
 *									    *
 *  FUNCTION   : CommandHandler ()					    *
 *									    *
 *  PURPOSE    : Processes all "frame" WM_COMMAND messages.                 *
 *									    *
 ****************************************************************************/
VOID PASCAL CommandHandler ( register HWND hwnd, register WORD wParam )
{
	HWND hwndFile;
	DWORD FlagSave;

	switch (wParam) {
	case IDM_FILENEW:
	    /* Add a new, empty MDI child */
	    AddFile (NULL);
	    break;

	case IDM_FILEOPEN:
	    ReadFile (hwnd);
	    break;

	case IDM_FILESAVE:
	    /* Save the active child MDI */
	    SendMessage (hwndActive, WM_COMMAND, IDM_FILESAVE, 0L);
	    break;

	case IDM_FILESAVEAS:
	    /* Save active child MDI under another name */
	    if (ChangeFile (hwndActive))
		SendMessage (hwndActive, WM_COMMAND, IDM_FILESAVE, 0L);
	    break;

	case IDM_FILEPRINT:
	    /* Print the active child MDI */
	    PrintFile (hwndActive);
	    break;

	case IDM_FILESETUP:
	    FlagSave = pd.Flags;
	    pd.Flags |= PD_PRINTSETUP;	  /* Set option */
	    PrintDlg((LPPRINTDLG)&pd);
	    pd.Flags = FlagSave;	  /* Remove option */
	    break;

	case IDM_FILEEXIT:
	    // Close Maxedit
	    SendMessage (hwnd, WM_CLOSE, 0, 0L);
	    break;

	case IDM_HELPHELP:
	    WinHelp( hwnd, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_Over ));
	    break;

	case IDM_HELPSEARCH:
	    WinHelp( hwnd, szHelpName, HELP_PARTIALKEY, (DWORD)((char _far *)"") );
	    break;

	case IDM_HELPTS:
	    WinHelp( hwnd, szHelpName, HELP_KEY, (DWORD)((char _far *) szHKEY_TechS ));
	    break;

	case IDM_HELPABOUT: {
	    FARPROC lpfn;

	    lpfn = MakeProcInstance( AboutDlgProc, hInst );
	    DialogBox (hInst, IDD_ABOUT, hwnd, lpfn);
	    FreeProcInstance (lpfn);
	    break;
	}

	/* The following are edit commands. Pass these off to the active
	 * child's edit control window. */
	case IDM_EDITCOPY:
	    SendMessage (hwndActiveEdit, WM_COPY, 0, 0L);
	    break;

	case IDM_EDITPASTE:
	    SendMessage (hwndActiveEdit, WM_PASTE, 0, 0L);
	    break;

	case IDM_EDITCUT:
	    SendMessage (hwndActiveEdit, WM_CUT, 0, 0L);
	    break;

	case IDM_EDITCLEAR:
	    SendMessage (hwndActiveEdit, EM_REPLACESEL, 0, ( LONG)(LPSTR)"");
	    break;

	case IDM_EDITSELECT:
	    SendMessage (hwndActiveEdit, EM_SETSEL, 0, MAKELONG(0, 0xe000));
	    break;

	case IDM_EDITUNDO:
	    SendMessage (hwndActiveEdit, EM_UNDO, 0, 0L);
	    break;

	case IDM_SEARCHFIND:
	    // Put up the find dialog box
	    Find ();
	    break;

	case IDM_SEARCHNEXT:
	    // Find next occurence
	    FindNext ();
	    break;

	case IDM_SEARCHPREV:
	    // Find previous occurence
	    FindPrev ();
	    break;

	case IDM_EDITINI:
	    // Is file already open?
	    if (hwndFile = AlreadyOpen(szIniName)) {
		// Yes -- bring the file's window to the top
		BringWindowToTop( hwndFile );
	    } else
		AddFile( szIniName );
	    break;

	/* The following are window commands - these are handled by the
	 * MDI Client. */
	case IDM_WINDOWTILE:
	    /* Tile MDI windows */
	    SendMessage (hwndMDIClient, WM_MDITILE, 0, 0L );
	    break;

	case IDM_WINDOWCASCADE:
	    /* Cascade MDI windows */
	    SendMessage (hwndMDIClient, WM_MDICASCADE, 0, 0L );
	    break;

	case IDM_WINDOWICONS:
	    /* Auto - arrange MDI icons */
	    SendMessage (hwndMDIClient, WM_MDIICONARRANGE, 0, 0L);
	    break;

	case IDM_WINDOWCLOSEALL:
	    /* Abort operation if something is not saved */
	    if (!QueryCloseAllChildren())
		break;

	    CloseAllChildren();

	    /* Show the window since CloseAllChilren() hides the window
	     * for fewer repaints. */
	    ShowWindow( hwndMDIClient, SW_SHOW);
	    break;

	default:
	   /* This is essential, since there are frame WM_COMMANDS generated
	    * by the MDI system for activating child windows via the
	    * window menu. */
	    DefFrameProc(hwnd, hwndMDIClient, WM_COMMAND, wParam, 0L);
	}
}


/****************************************************************************
 *									    *
 *  FUNCTION   : MPError ( hwnd, flags, id, ...)			    *
 *									    *
 *  PURPOSE    : Flashes a Message Box to the user. The format string is    *
 *		 taken from the STRINGTABLE.				    *
 *									    *
 *  RETURNS    : Returns value returned by MessageBox() to the caller.	    *
 *									    *
 ****************************************************************************/

short CDECL MPError(HWND hwnd, WORD bFlags, WORD id, ...)
{
	char sz[160];
	char szFmt[128];

	LoadString (hInst, id, szFmt, sizeof (szFmt));
	wvsprintf (sz, szFmt, (LPSTR)(&id + 1));
	LoadString (hInst, IDS_APPNAME, szFmt, sizeof(szFmt) );

	return (MessageBox (hwndFrame, sz, szFmt, bFlags ));
}


/****************************************************************************
 *									    *
 *  FUNCTION   : QueryCloseAllChildren()				    *
 *									    *
 *  PURPOSE    : Asks the child windows if it is ok to close up app. Nothing*
 *		 is destroyed at this point. The z-order is not changed.    *
 *									    *
 *  RETURNS    : TRUE - If all children agree to the query.		    *
 *		 FALSE- If any one of them disagrees.			    *
 *									    *
 ****************************************************************************/

BOOL PASCAL QueryCloseAllChildren(void)
{
    register HWND hwndT;

    for ( hwndT = GetWindow (hwndMDIClient, GW_CHILD); hwndT; hwndT = GetWindow (hwndT, GW_HWNDNEXT) ) {

	/* Skip if an icon title window */
	if (GetWindow (hwndT, GW_OWNER))
	    continue;

	if (SendMessage (hwndT, WM_QUERYENDSESSION, 0, 0L))
	    return FALSE;
    }

    return TRUE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : QueryCloseChild (hwnd) 				    *
 *									    *
 *  PURPOSE    : If the child MDI is unsaved, allow the user to save, not   *
 *		 save, or cancel the close operation.			    *
 *									    *
 *  RETURNS    : TRUE  - if user chooses save or not save, or if the file   *
 *			 has not changed.				    *
 *		 FALSE - otherwise.					    *
 *									    *
 ****************************************************************************/

BOOL PASCAL QueryCloseChild( register HWND hwnd )
{
	char sz [80];
	register int i;

	/* Return OK if edit control has not changed. */
	if (!GetWindowWord (hwnd, GWW_CHANGED))
		return TRUE;

	GetWindowText (hwnd, sz, sizeof(sz));

	/* Ask user whether to save / not save / cancel */
	i = MPError (hwnd, MB_YESNOCANCEL|MB_ICONQUESTION,IDS_CLOSESAVE, (LPSTR)sz);

	switch (i){
	case IDYES:
	    /* User wants file saved */
	    SaveFile(hwnd);
	    break;

	case IDNO:
	    /* User doesn't want file saved */
	    break;

	default:
	    /* We couldn't do the messagebox, or not ok to close */
	    return FALSE;
	}

	return TRUE;
}


BOOL fAbort;		/* TRUE if the user has aborted the print job	 */
HWND hwndPDlg;		/* Handle to the cancel print dialog		 */
PSTR szTitle;		/* Global pointer to job title			 */
HANDLE hInitData=NULL;	/* handle to initialization data		 */


/****************************************************************************
 *									    *
 *  FUNCTION   : GetPrinterDC ()					    *
 *									    *
 *  PURPOSE    : Creates a printer display context for the printer	    *
 *									    *
 *  RETURNS    : HDC   - A handle to printer DC.			    *
 *									    *
 ****************************************************************************/
HDC PASCAL GetPrinterDC(void)
{
    HDC 	hDC;
    LPDEVMODE	lpDevMode = NULL;
    LPDEVNAMES	lpDevNames;
    LPSTR	lpszDriverName;
    LPSTR	lpszDeviceName;
    LPSTR	lpszPortName;

    if (!PrintDlg((LPPRINTDLG)&pd))
	return (NULL);

    if (pd.hDC)
	hDC = pd.hDC;

    else {

	if (!pd.hDevNames)
	    return(NULL);

	lpDevNames = (LPDEVNAMES)GlobalLock(pd.hDevNames);
	lpszDriverName = (LPSTR)lpDevNames + lpDevNames->wDriverOffset;
	lpszDeviceName = (LPSTR)lpDevNames + lpDevNames->wDeviceOffset;
	lpszPortName   = (LPSTR)lpDevNames + lpDevNames->wOutputOffset;
	GlobalUnlock(pd.hDevNames);

	if (pd.hDevMode)
	    lpDevMode = (LPDEVMODE)GlobalLock(pd.hDevMode);

	hDC = CreateDC(lpszDriverName, lpszDeviceName, lpszPortName, (LPSTR)lpDevMode);

	if (pd.hDevMode && lpDevMode)
	    GlobalUnlock(pd.hDevMode);
      }

#if 0
    if (pd.hDevNames) {
	GlobalFree(pd.hDevNames);
	pd.hDevNames = 0;
    }

    if (pd.hDevMode) {
	GlobalFree(pd.hDevMode);
	pd.hDevMode = 0;
    }
#endif

    return(hDC);
}


/****************************************************************************
 *									    *
 *  FUNCTION   : AbortProc()						    *
 *									    *
 *  PURPOSE    : To be called by GDI print code to check for user abort.    *
 *									    *
 ****************************************************************************/
int FAR PASCAL __export AbortProc ( HDC hdc, WORD reserved )
{
    MSG msg;

    /* Allow other apps to run, or get abort messages */
    while (!fAbort && PeekMessage (&msg, NULL, NULL, NULL, TRUE))
	if (!hwndPDlg || !IsDialogMessage (hwndPDlg, &msg)) {
	    TranslateMessage (&msg);
	    DispatchMessage  (&msg);
	}

    return !fAbort;
}

/****************************************************************************
 *									    *
 *  FUNCTION   : PrintDlgProc ()					    *
 *									    *
 *  PURPOSE    : Dialog function for the print cancel dialog box.	    *
 *									    *
 *  RETURNS    : TRUE  - OK to abort/ not OK to abort			    *
 *		 FALSE - otherwise.					    *
 *									    *
 ****************************************************************************/
BOOL FAR PASCAL __export PrintDlgProc(HWND hwnd, WORD msg, WORD wParam, LONG lParam)
{
	if (msg == WM_COMMAND) {
		/* abort printing if the only button gets hit */
		fAbort = TRUE;
		return TRUE;
	}

	return FALSE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : PrintFile ()						    *
 *									    *
 *  PURPOSE    : Prints the contents of the edit control.		    *
 *									    *
 ****************************************************************************/
#define MAXFMTLINES 120
#define MAXCHARSCAN 20
#define PRTLINEBUFLEN 511

VOID PASCAL PrintFile( HWND hwnd )
    {
    TEXTMETRIC tm;
    HDC     hdc;
    WORD    i;
    int     yExtPage;
    int     xExtPage;
    int     yExtSoFar;
    WORD    cch;
    WORD    iLine;
    WORD    nLinesEc;
    WORD    nRLines;
    DOCINFO di;
    ABORTPROC lpfnAbort;
    FARPROC lpfnPDlg;
    WORD    dy;
    WORD    fError = TRUE;
    char    sz[32], szLine[ PRTLINEBUFLEN + 1];
    LPSTR   lpRetStr;
    LPSTR   lpNext;
    HWND    hwndEdit;
    int     nLineLen;
    int     aTabs[2];
    int     nTS = 1;

#if defined(_WIN32) || defined(__WIN32__)
    SIZE sizeRect;
#endif

    hwndEdit = (HWND)GetWindowWord(hwnd,GWW_HWNDEDIT);

    /* Create the job title by loading the title string from STRINGTABLE */
    cch = LoadString (hInst, IDS_PRINTJOB, sz, sizeof(sz));
    szTitle = sz + cch;
    cch += GetWindowText (hwnd, sz + cch, 32 - cch);
    sz[31] = 0;

    di.cbSize = sizeof( DOCINFO );
    di.lpszDocName = sz;
    di.lpszOutput = NULL;


	// Make instances of the Abort proc. and the Print dialog function.
    lpfnAbort = MakeProcInstance( (FARPROC)AbortProc, hInst );
    if (!lpfnAbort)
	{
	goto getout;
	}
    lpfnPDlg = MakeProcInstance( (FARPROC)PrintDlgProc, hInst );
    if (!lpfnPDlg)
	{
	goto getout4;
	}

	// Initialize the printer
    hdc = GetPrinterDC( );
    if (!hdc)
	{
	fError = FALSE;
	goto getout5;
	}

	// get the average char width.
    GetTextMetrics( hdc, &tm );
    aTabs[0] = tm.tmAveCharWidth * 10;
    aTabs[1] = aTabs[0] * 2;

	//Disable the main application window and create the Cancel dialog.
    EnableWindow (hwnd, FALSE);
    hwndPDlg = CreateDialog ( hInst, MAKEINTRESOURCE(IDD_PRINT), hwnd, (DLGPROC)lpfnPDlg);
    if (!hwndPDlg)
	{
	goto getout3;
	}
    ShowWindow (hwndPDlg, SW_SHOW);
    UpdateWindow (hwndPDlg);

	// Allow the app. to inform GDI of the escape function to call.
    if( SetAbortProc( hdc, lpfnAbort ) < 0)
	{
	goto getout3;
	}

	// Initialize the document.
    if( StartDoc( hdc, &di ) == SP_ERROR )
	{
	goto getout3;
	}

	// Get the height of one line and the height of a page.
#if defined(_WIN32) || defined(__WIN32__)
    GetTextExtentPoint( hdc, "CC", 2 , &sizeRect );
    dy = (WORD)sizeRect.cy;
#else
    dy = HIWORD (GetTextExtent (hdc, "CC", 2));
#endif

    yExtPage = GetDeviceCaps (hdc, VERTRES);
    xExtPage = GetDeviceCaps (hdc, HORZRES);

	// Get the lines in document and and a handle to the text buffer.
    iLine     = 0;
    yExtSoFar = 0;
    nLinesEc  = (WORD)SendMessage (hwndEdit, EM_GETLINECOUNT, 0, 0L);

    if( nLinesEc <= 0 )
	{
	goto getout3;
	}

    if( StartPage( hdc ) < 0 )
	{
	goto getout2;
	}

	// While more lines print out the text.
    while( iLine < nLinesEc )
	{
	    /* Get the length and position of the line in the buffer */
	*((WORD *)&szLine[0]) = PRTLINEBUFLEN;
	cch = (WORD)SendMessage( hwndEdit, EM_GETLINE, iLine, (LPARAM)(LPSTR)szLine );
	szLine[cch] = '\0';

	    // this should return a double null terminated list of strings.
	nRLines = FormatLine( hdc, szLine, lstrlen( szLine ), &lpRetStr, xExtPage, 10 );
	lpNext = lpRetStr;

	for( i=0; i < nRLines; i++ )
	    {
	    nLineLen = lstrlen( lpNext );
	    if (yExtSoFar + (int)dy > yExtPage)
		{
			// Reached the end of a page.
			// Tell the device driver to eject a page
		if ( ( EndPage( hdc ) < 0) || fAbort)
		    {
		    goto getout2;
		    }

		if( StartPage( hdc ) < 0 )
		    {
		    goto getout2;
		    }
		yExtSoFar = 0;
		}

		// Print the line.
	    TabbedTextOut (hdc, 0, yExtSoFar, (LPSTR)lpNext, nLineLen,
			   nTS, aTabs, 0 );

		// Test and see if the Abort flag has been set. If yes, exit.
	    if (fAbort)
		{
		goto getout2;
		}

		// Move down the page.
	    yExtSoFar += dy;

	    if( (i+1) < nRLines )
		{
		    // point to the next line.
		lpNext += (nLineLen + 1);
		}
	    }

	if( lpRetStr != NULL )
	    {
	    _ffree( lpRetStr );
	    lpRetStr = NULL;
	    }

	    // increment the index of lines in the edit control.
	iLine++;
	} // end while.

	// Eject the last page.
    if( EndPage( hdc ) < 0)
	{
	goto getout2;
	}

	// Complete the document.
    if( EndDoc( hdc ) < 0)
	{
getout2:
	    // Ran into a problem before NEWFRAME? Abort the document.
	AbortDoc( hdc );
	}
    else
	{
	fError=FALSE;
	}

getout3:
	    // Close the cancel dialog and re-enable main app. window.
    EnableWindow ( hwnd, TRUE);
    DestroyWindow (hwndPDlg);
    hwndPDlg = NULL;
    DeleteDC(hdc);

getout5:
	    // Get rid of dialog procedure instances.
    FreeProcInstance (lpfnPDlg);

getout4:
    FreeProcInstance (lpfnAbort);

getout:
    /* Error? make sure the user knows... */
    if (fError)
	MPError (hwnd, MB_OK | MB_ICONEXCLAMATION, IDS_PRINTERROR, (LPSTR)szTitle);
    }

//------------------------------------------------------------------
// search for end of line chars...changes *lpEnd if found.
//------------------------------------------------------------------
BOOL FindBreak( LPSTR *lpStart, LPSTR *lpEnd, int nCount, char ch )
    {
    LPSTR lpScan;
    int t;

    for( t = 0, lpScan = (*lpEnd) ;
	(lpScan > (*lpStart) ) && (t < nCount ) ;
	t++, lpScan-- )
	{
	if( *lpScan == ch )
	    {
	    *lpEnd = lpScan;
	    return TRUE;
	    }
	}
    return FALSE;
    }

//------------------------------------------------------------------
int FormatLine( HDC hDC, LPSTR szIn, WORD nInLen, LPSTR FAR *lpRetStr,
				    WORD nMaxPoints, WORD nTabs )
    {
    WORD i;
    static int aTabs[2];
    int nRetLines;
    int nTabCount;
    int nCurLen;
    LPSTR lpBuff;
    LPSTR lpStart;
    LPSTR lpNew;
    LPSTR lpEnd;
    WORD nLTabs;
    WORD nOutLen;
    WORD xPointLen;
    TEXTMETRIC tm;

	// count tabs.
    for( i = 0, nTabCount = 0; i < nInLen; i++ )
	{
	if( szIn[i] == '\t' )
	    {
	    nTabCount++;
	    }
	}

    nLTabs = ( nTabs > 1 ) ? nTabs : 1;

	// calculate a buffer long enough to expand.
    nOutLen = nInLen + MAXFMTLINES + 8;

	// make a buffer.
    if(( lpBuff = (LPSTR)_fmalloc( nOutLen )) == NULL )
	{
	return 0;
	}

    *lpRetStr = lpBuff;

    _fstrcpy( lpBuff, szIn );

	// get the average char width.
    GetTextMetrics( hDC, &tm );
    aTabs[0] = tm.tmAveCharWidth * 10;
    aTabs[1] = aTabs[0] * 2;

	// get the string width
    xPointLen = LOWORD(GetTabbedTextExtent( hDC, lpBuff, lstrlen(lpBuff), 1, aTabs ));

	// skip the calculations if we don't need them.
    if( xPointLen < nMaxPoints )
	{
	nRetLines = 1;
	return nRetLines;
	}

	// if we got here, We must break up the line.
    for( lpNew = lpBuff, nRetLines = 1; ; nRetLines++)
	{
	    // don't exceed the buffer limit.
	if( nRetLines > MAXFMTLINES )
	    {
	    break;
	    }

	lpStart = lpNew;

	    // point to the null.
	nCurLen = lstrlen( lpStart ) + 1;
	lpEnd = lpStart + nCurLen;

	// get the string width
	xPointLen = LOWORD(GetTabbedTextExtent( hDC, lpBuff, nCurLen, 1, aTabs ));
	if( xPointLen < nMaxPoints )
	    {
		// a double null finishes it off.
	    *lpEnd++ = '\0';
	    *lpEnd = '\0';
	    return nRetLines;
	    }

	nCurLen = (int)(nMaxPoints / tm.tmAveCharWidth);

	    // find the maximum last character.
	do
	    {
	    xPointLen = LOWORD(GetTabbedTextExtent( hDC, lpStart, nCurLen, 1, aTabs ));
	    if( xPointLen >= nMaxPoints )
		{
		nCurLen--;
		}
	    } while( xPointLen > nMaxPoints );

	    // set the result as the end for now.
	lpEnd = lpStart + nCurLen;

	    // look for spaces
	if (!FindBreak( &lpStart, &lpEnd, MAXCHARSCAN, ' ' ))
	    {
		// look for semicolons
	    FindBreak( &lpStart, &lpEnd, MAXCHARSCAN, ';' );
	    }

	    // skip over the null to the next character.
	lpNew = lpEnd + 2;

	    // move the buffer down...including the null.
	_fmemmove( lpNew, lpEnd+1, lstrlen( lpEnd + 1) + 1 );
	    // terminate the first line.
	*(lpEnd + 1) = '\0';
	}

    return nRetLines;
    }


/****************************************************************************
 *									    *
 *  FUNCTION   : AlreadyOpen(szFile)					    *
 *									    *
 *  PURPOSE    : Checks to see if the file described by the string pointed  *
 *		 to by 'szFile' is already open.                            *
 *									    *
 *  RETURNS    : a handle to the described file's window if that file is    *
 *		 already open;	NULL otherwise. 			    *
 *									    *
 ****************************************************************************/

static HWND AlreadyOpen(char *szFile)
{
    HWND    hwndCheck;
    char    szChild[128];

    /* Open the file with the OF_PARSE flag to obtain the fully qualified
     * pathname in the OFSTRUCT structure. */
    of.szPathName[0] = '\0';
    OpenFile ((LPSTR)szFile, (LPOFSTRUCT)&of, OF_PARSE);
    if (of.szPathName[0] == '\0')
	return 0;

    /* Check each MDI child window in Multipad */
    for ( hwndCheck = GetWindow(hwndMDIClient, GW_CHILD); hwndCheck; hwndCheck = GetWindow(hwndCheck, GW_HWNDNEXT)   ) {

	/* Skip icon title windows */
	if (GetWindow( hwndCheck, GW_OWNER ))
	    continue;

	/* Get current child window's name */
	GetWindowText( hwndCheck, szChild, 128 );

	/* Compare window name with given name */
	if (lstrcmpi( szChild, of.szPathName ) == 0)
		return (hwndCheck);
    }

    /* No match found -- file is not open -- return NULL handle */
    return 0;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : AddFile (lpName)					    *
 *									    *
 *  PURPOSE    : Creates a new MDI window. If the lpName parameter is not   *
 *		 NULL, it loads a file into the window. 		    *
 *									    *
 *  RETURNS    : HWND  - A handle to the new window.			    *
 *									    *
 ****************************************************************************/

HWND PASCAL AddFile( char *pName )
{
    HWND hwnd;
    char sz[160];
    MDICREATESTRUCT mcs;

    if (!pName) {
	/* The pName parameter is NULL -- load the "Untitled" string from */
	/* STRINGTABLE and set the title field of the MDI CreateStruct.    */
	LoadString (hInst, IDS_UNTITLED, sz, sizeof(sz));
	mcs.szTitle = (LPSTR)sz;
    } else {
	/* Title the window with the fully qualified pathname obtained by
	 * calling OpenFile() with the OF_PARSE flag (in function
	 * AlreadyOpen(), which is called before AddFile(). */
	mcs.szTitle = of.szPathName;
    }

    mcs.szClass = szChild;
    mcs.hOwner	= hInst;

    /* Use the default size for the window */
    mcs.x = mcs.cx = CW_USEDEFAULT;
    mcs.y = mcs.cy = CW_USEDEFAULT;

    /* Set the style DWORD of the window to default */
    mcs.style = 0;

    /* tell the MDI Client to create the child */
    hwnd = (WORD)SendMessage (hwndMDIClient, WM_MDICREATE,
			      0, (LONG)(LPMDICREATESTRUCT)&mcs);

    /* Did we get a file? Read it into the window */
    if (pName) {
	if (!LoadFile(hwnd, pName)){
		/* File couldn't be loaded -- close window */
		SendMessage(hwndMDIClient, WM_MDIDESTROY, (WORD) hwnd, 0L);
	}
    }

    return 0;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : LoadFile (lpName)					    *
 *									    *
 *  PURPOSE    : Given the handle to a MDI window and a filename, reads the *
 *		 file into the window's edit control child.                 *
 *									    *
 *  RETURNS    : TRUE  - If file is sucessfully loaded. 		    *
 *		 FALSE - Otherwise.					    *
 *									    *
 ****************************************************************************/

int PASCAL LoadFile (HWND hwnd, char *pName)
{
    WORD   wLength;
    LPSTR  lpB;
    HWND   hwndEdit;
    int    fh;
    HGLOBAL hGlobal;

    hwndEdit = GetWindowWord (hwnd, GWW_HWNDEDIT);

    hGlobal = GlobalAlloc( GMEM_MOVEABLE | GMEM_ZEROINIT, 0xFFF0L );
    lpB = (LPSTR)GlobalLock( hGlobal );

    /* The file has a title, so reset the UNTITLED flag. */
    SetWindowWord(hwnd, GWW_UNTITLED, FALSE);

    fh = _lopen (pName, READ | OF_SHARE_DENY_WRITE );

    /* Make sure file has been opened correctly */
    if ( fh < 0 ) {
	MPError(hwnd, MB_OK | MB_ICONHAND, IDS_CANTOPEN, (LPSTR)pName);
	return FALSE;
    }

    /* Find the length of the file */
    wLength = (WORD)_llseek (fh, 0L, 2);
    _llseek (fh, 0L, 0);

    /* read the file into the buffer */
    if (wLength != _lread (fh, lpB, wLength))
	MPError (hwnd, MB_OK|MB_ICONHAND, IDS_CANTREAD, (LPSTR)pName);
    else
	lpB[wLength] = 0;

    SendMessage(hwndEdit, WM_SETTEXT, 0, (LPARAM)lpB );

    GlobalUnlock ( hGlobal );
    GlobalFree( hGlobal );

    _lclose (fh);

    SetWindowText(hwnd, pName);

    return TRUE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : ReadFile(hwnd) 					    *
 *									    *
 *  PURPOSE    : Called in response to a File/Open menu selection. It asks  *
 *		 the user for a file name and responds appropriately.	    *
 *									    *
 ****************************************************************************/

VOID PASCAL ReadFile(HWND hwnd)
{
    char    szFile[128];
    HWND    hwndFile;
    OPENFILENAME of;

    lstrcpy(szFile, "*.INI");

    memset(&of, '\0', sizeof(OPENFILENAME));

    of.lStructSize  = sizeof(OPENFILENAME);
    of.hwndOwner    = hwnd;
    of.lpstrFilter  = (LPSTR)"INI Files (*.INI)\0*.INI\0Profile Files (*.PRO)\0*.PRO\0All Files (*.*)\0*.*\0";
    of.lpstrCustomFilter = NULL;
    of.nFilterIndex = 1;
    of.lpstrFile    = (LPSTR)szFile;
    of.nMaxFile     = 128;
    of.lpstrInitialDir = NULL;
    of.lpstrTitle   = NULL;
    of.Flags	    = OFN_HIDEREADONLY|OFN_FILEMUSTEXIST;
    of.lpstrDefExt  = NULL;

    if(!GetOpenFileName(&of))
       return;

    /* If the result is not the empty string -- take appropriate action */
    if (*szFile) {

	     /* Is file already open? */
	     if (hwndFile = AlreadyOpen(szFile)) {
		/* Yes -- bring the file's window to the top */
		BringWindowToTop(hwndFile);
	     } else {
		/* No -- make a new window and load file into it */
		AddFile(szFile);
	     }
    }
}


/****************************************************************************
 *									    *
 *  FUNCTION   : SaveFile (hwnd)					    *
 *									    *
 *  PURPOSE    : Saves contents of current edit control to disk.	    *
 *									    *
 ****************************************************************************/

VOID PASCAL SaveFile( HWND hwnd )
{
    LPSTR    lpT;
    char     szFile[128];
    WORD     cch;
    int      fh;
    OFSTRUCT of;
    HWND     hwndEdit;
    HGLOBAL  hGlobal;

    hwndEdit = GetWindowWord ( hwnd, GWW_HWNDEDIT);
    GetWindowText (hwnd, szFile, sizeof(szFile));

    if (lstrcmpi(szFile, "Untitled") == 0) {
	ChangeFile(hwnd);
	GetWindowText (hwnd, szFile, sizeof(szFile));
    }

    fh = OpenFile (szFile, &of, OF_WRITE | OF_CREATE | OF_SHARE_DENY_WRITE );

    /* If file could not be opened, quit */
    if (fh < 0) {
	MPError (hwnd, MB_OK | MB_ICONHAND, IDS_CANTCREATE, (LPSTR)szFile);
	return;
    }

    /* Find out the length of the text in the edit control */
    cch = GetWindowTextLength (hwndEdit) + 1;

    hGlobal = GlobalAlloc( GMEM_MOVEABLE | GMEM_ZEROINIT, cch );
    lpT = GlobalLock( hGlobal );

    /* Write out the contents of the buffer to the file. */
    cch = (int)SendMessage(hwndEdit, WM_GETTEXT, (WPARAM)cch, (LPARAM)(LONG)lpT);
    if (cch != _lwrite (fh, lpT, cch))
	MPError (hwnd, MB_OK | MB_ICONHAND, IDS_CANTWRITE, (LPSTR)szFile);

    /* Clean up */
    GlobalUnlock( hGlobal );
    GlobalFree( hGlobal );

    _lclose( fh );
}


/****************************************************************************
 *									    *
 *  FUNCTION   : ChangeFile (hwnd)					    *
 *									    *
 *  PURPOSE    : Invokes the File/SaveAs dialog.			    *
 *									    *
 *  RETURNS    : TRUE  - if user selected OK or NO.			    *
 *		 FALSE - otherwise.					    *
 *									    *
 ****************************************************************************/

BOOL PASCAL ChangeFile ( HWND hwnd )
{
    char    szFile[128];
    OPENFILENAME of;

    if (GetWindowWord(hwnd, GWW_UNTITLED))
	lstrcpy(szFile, "*.INI");
    else
	GetWindowText(hwnd, szFile, 128);

    of.lStructSize  = sizeof(OPENFILENAME);
    of.hwndOwner    = hwnd;
    of.lpstrFilter  = (LPSTR)"INI Files (*.INI)\0*.INI\0Profile Files (*.PRO)\0*.PRO\0All Files (*.*)\0*.*\0";
    of.lpstrCustomFilter = NULL;
    of.nFilterIndex = 1;
    of.lpstrFile    = (LPSTR)szFile;
    of.nMaxFile     = 128;
    of.lpstrInitialDir = NULL;
    of.lpstrTitle   = NULL;
    of.Flags	    = OFN_HIDEREADONLY;
    of.lpstrDefExt  = NULL;
    of.lpstrFileTitle	= NULL;

    if (!GetSaveFileName( &of ))
       return FALSE;

    SetWindowWord( hwnd, GWW_UNTITLED, 0 );
    SetWindowText( hwnd, szFile );

    return TRUE;
}


#undef HIWORD
#undef LOWORD

#define HIWORD(l) (((WORD*)&(l))[1])
#define LOWORD(l) (((WORD*)&(l))[0])

BOOL fCase	   = FALSE;    /* Turn case sensitivity off */
char szSearch[160] = "";       /* Initialize search string  */

/****************************************************************************
 *									    *
 *  FUNCTION   : RealSlowCompare ()					    *
 *									    *
 *  PURPOSE    : Compares subject string with the target string. This fn/   *
 *		 is called repeatedly so that all substrings are compared,  *
 *		 which makes it O(n ** 2), hence it's name.                 *
 *									    *
 *  RETURNS    : TRUE  - If pSubject is identical to pTarget.		    *
 *		 FALSE - otherwise.					    *
 *									    *
 ****************************************************************************/

BOOL PASCAL RealSlowCompare ( LPSTR pSubject, LPSTR pTarget )
{
    if (fCase) {
	while (*pTarget)
	    if (*pTarget++ != *pSubject++)
		return FALSE;
    } else {
	/* If case-insensitive, convert both subject and target to lowercase
	 * before comparing. */
	AnsiLower ((LPSTR)pTarget);
	while (*pTarget)
	    if (*pTarget++ != (char)(DWORD)AnsiLower ((LPSTR)(DWORD)(BYTE)*pSubject++))
		return FALSE;
    }

    return TRUE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : MyFindText ()						    *
 *									    *
 *  PURPOSE    : Finds the search string in the active window according to  *
 *		 search direction (dch) specified ( -1 for reverse and 1 for*
 *		 forward searches).					    *
 *									    *
 ****************************************************************************/

VOID PASCAL MyFindText( register int dch )
{
    LPSTR pText;
    LONG l;
    WORD cch;
    int i;
    HGLOBAL hGlobal;

    if (!*szSearch)
	return;

    /* Find the current selection range */
    l = (int)SendMessage(hwndActiveEdit, EM_GETSEL, 0, 0L);

    /* Get the length of the text */
    cch = (WORD)SendMessage (hwndActiveEdit, WM_GETTEXTLENGTH, 0, 0L);

    hGlobal = GlobalAlloc( GMEM_MOVEABLE | GMEM_ZEROINIT, cch );
    pText = GlobalLock( hGlobal );
    SendMessage( hwndActiveEdit, WM_GETTEXT, cch, (LPARAM)pText );

    /* Start with the next char. in selected range ... */
    pText += LOWORD (l) + dch;

    /* Compute how many characters are before/after the current selection */
    if (dch < 0)
	i = LOWORD (l);
    else
	i = cch - LOWORD (l) + 1 - lstrlen (szSearch);

    /* While there are uncompared substrings... */
    while ( i > 0) {

	LOWORD(l) += dch;

	/* Does this substring match? */
	if (RealSlowCompare(pText, szSearch)) {

	    /* Yes, unlock the buffer.*/
	    GlobalUnlock( hGlobal );
	    GlobalFree( hGlobal );

	    /* Select the located string */
	    HIWORD(l) = LOWORD(l) + lstrlen (szSearch);
	    SendMessage (hwndActiveEdit, EM_SETSEL, 0, l);
	    return;
	}
	i--;

	/* increment/decrement start position by 1 */
	pText += dch;
    }

    /* Not found... unlock buffer. */
    GlobalUnlock ( hGlobal );
    GlobalFree( hGlobal );

    /* Give a message */
    MPError (hwndFrame, MB_OK | MB_ICONEXCLAMATION, IDS_CANTFIND, (LPSTR)szSearch);
}


/****************************************************************************
 *									    *
 *  FUNCTION   : FindPrev ()						    *
 *									    *
 *  PURPOSE    : Finds the previous occurence of the search string. Calls   *
 *		 MyFindText () with a negative search direction.		    *
 *									    *
 ****************************************************************************/

VOID PASCAL FindPrev(void)
{
	MyFindText(-1);
}


/****************************************************************************
 *									    *
 *  FUNCTION   : FindNext ()						    *
 *									    *
 *  PURPOSE    : Finds the next occurence of search string. Calls	    *
 *		 MyFindText () with a positive search direction.		    *
 *									    *
 ****************************************************************************/

VOID PASCAL FindNext(void)
{
	MyFindText(1);
}


/****************************************************************************
 *									    *
 *  FUNCTION   : FindDlgProc(hwnd, message, wParam, lParam)		    *
 *									    *
 *  PURPOSE    : Dialog function for the Search/Find command. Prompts user  *
 *		 for target string, case flag and search direction.	    *
 *									    *
 ****************************************************************************/

BOOL FAR PASCAL FindDlgProc(HWND hwnd, WORD msg, WORD wParam, LONG lParam)
{
	switch (msg){
	case WM_INITDIALOG:{

	    /* Check/uncheck case button */
	    CheckDlgButton (hwnd, IDD_CASE, fCase);

	    /* Set default search string to most recently searched string */
	    SetDlgItemText (hwnd, IDD_SEARCH, szSearch);

	    /* Allow search only if target is nonempty */
	    if (!lstrlen (szSearch)){
		EnableWindow (GetDlgItem (hwnd, IDOK), FALSE);
		EnableWindow (GetDlgItem (hwnd, IDD_PREV), FALSE);
	    }
	    break;
	}

	case WM_COMMAND:{

	    /* Search forward by default (see IDOK below) */
	    int i = 1;

	    switch (wParam){
		/* if the search target becomes non-empty, enable searching */
		case IDD_SEARCH:
		    if (HIWORD (lParam) == EN_CHANGE){
			if (!(WORD) SendDlgItemMessage (hwnd,
				IDD_SEARCH, WM_GETTEXTLENGTH, 0, 0L))
			    i = FALSE;
			else
			    i = TRUE;
			EnableWindow (GetDlgItem (hwnd, IDOK), i);
			EnableWindow (GetDlgItem (hwnd, IDD_PREV), i);
		    }
		    break;

		case IDD_CASE:
		    /* Toggle state of case button */
		    CheckDlgButton (hwnd, IDD_CASE, !IsDlgButtonChecked (hwnd, IDD_CASE));
		    break;

		case IDD_PREV:
		    // Set direction to backwards
		    i = -1;
		    /*** FALL THRU ***/

		case IDOK:
		    /* Save case selection */
		    fCase = IsDlgButtonChecked( hwnd, IDD_CASE );

		    /* Get search string */
		    GetDlgItemText (hwnd, IDD_SEARCH, szSearch, sizeof (szSearch));

		    /* Find the text */
		    MyFindText (i);
		    /*** FALL THRU ***/

		/* End the dialog */
		case IDCANCEL:
		    EndDialog ( hwnd, 0 );
		    break;

		default:
		    return FALSE;
	    }
	    break;
	}
	default:
	    return FALSE;
	}

	return TRUE;
}


/****************************************************************************
 *									    *
 *  FUNCTION   : Find() 						    *
 *									    *
 *  PURPOSE    : Invokes the Search/Find dialog.			    *
 *									    *
 ****************************************************************************/

VOID PASCAL Find( void )
{
	FARPROC lpfn;

	lpfn = MakeProcInstance ( FindDlgProc, hInst );
	DialogBox ( hInst, IDD_FIND, hwndFrame, lpfn );
	FreeProcInstance ( lpfn );
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
static void PASCAL MakePathName(register char *dname, char *pszFileName)
{
	register int length;

	length = lstrlen( dname );

	if ((*dname) && (strchr( "/\\:", dname[length-1] ) == NULL ))
		lstrcat( dname, "\\" );

	lstrcat( dname, pszFileName );
}


// strip the specified leading characters
static void StripLeading( register char *arg, char *delims )
{
	while ((*arg != '\0') && (strchr( delims, *arg ) != NULL ))
		lstrcpy( arg, arg+1 );
}


// strip the specified trailing characters
static void StripTrailing(register char *arg, char *delims)
{
	register int i;

	for (i = lstrlen(arg); ((--i >= 0) && (strchr( delims, arg[i] ) != NULL )); )
		arg[i] = '\0';
}


// make up for the lack of a Windows API!
void WritePrivateProfileInt(char *szSection, char *szItem, int nValue)
{
	char szBuffer[16];

	wsprintf( szBuffer, "%d", nValue );
	WritePrivateProfileString( szSection, szItem, szBuffer, szIniName );
}

