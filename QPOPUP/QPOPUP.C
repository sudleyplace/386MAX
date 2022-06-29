//' $Header:   P:/PVCS/MAX/QPOPUP/QPOPUP.C_V   1.3   10 Nov 1995 23:16:50   BOB  $
/* qpopup.c - Copyright (C) 1993-5 Qualitas, Inc.  All Rights Reserved. */

#define STRICT
#include <windows.h>
#include <windowsx.h>
#include <toolhelp.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "qpopup.h"
#include "vmaxapi.h"            // 386MAX.VXD protected mode API
#include "tdb.h"                // Task database structure

// Undocumented KERNEL exports -- see the .DEF file
BOOL	WINAPI IsWinOldApTask(HTASK hTask);

typedef unsigned long HVM, FAR * LPHVM; // VM_Handle

// Structure pointed to by selector in wParam of registered callback
// Defined in the 386MAX.VXD sources.

typedef struct _PERVMCB {		// VxD's per VM CB
	WORD	wSize;			// Size accessible to callback
	WORD	wFunction;		// Requested function code
	DWORD	VM_Handle;		// Handle to which the CB belongs
	LPSTR	lpszFilename;		// FAR PTR to program name
	WORD	wFlags; 		// Flags
	WORD	wVideoMode;		// Attempted video mode
} PERVMCB, FAR * LPPERVMCB;

// PERVMCB.wFunction equates

#define CBFN_MODESWITCH 0x8000		// VM has attempted a video mode switch
#define CBFN_WARNFLAG	0x4000		// exec() of a troublesome program
#define CBFN_FAILFLAG	0x2000		// exec() of a graphics only program
#define SwapLoBytes(a) ((LOBYTE(a) << 8) | HIBYTE(a))

LPVOID	WINAPI lmemset(LPVOID lpv, BYTE b, UINT cb);
HWND	WINAPI GetWinOldApHWNDFromVMHandle(HVM VM_Handle);
void	CenterWindow(HWND hWnd);

BOOL	RegisterWithVxD(void);
BOOL	UnRegisterWithVxD(void);

#define MK_FP(s,o) ((void FAR *) ((((DWORD) (WORD) (s)) << 16) | (WORD) (o)))

#define UM_CALLBACK	(WM_USER+254)	// VM is trying to enter graphics mode
					// wParam = Selector to Per VM CB
					// lParam =

#define UM_UNREG	(WM_USER+255)	// Unregister with the VxD

typedef struct _PERPOPUP {		// Per Popup dialog data
	LPPERVMCB lpPERVMCB;		// ==> PERVMCB
	HWND	hWndOldAp;		// HWND for WinOldAp
} PERPOPUP, * PPERPOPUP, FAR *LPPERPOPUP;

#define OSP	_asm _emit 0x66

#define SGVMI_Windowed		0x0004	// From \WIN386\INCLUDE\SHELL.INC

WORD	(FAR * VxD)(void);	// FAR PTR to the PM API entry point
WORD	wVxDVer = 0;
WORD	wSwatVer = 0;

FARPROC lpfnVxDCallback = NULL;

#define APP_STYLE (			\
		WS_OVERLAPPED	|	\
		WS_SYSMENU	|	\
		WS_CLIPCHILDREN 	\
		)

static char szQPopup[] = "QPopup";
char	szInfFilespec[_MAX_PATH];

BOOL	fDebug = FALSE;
HWND	hWndMain;
HINSTANCE	hInst;

PSTR apszModeText[] = {
#ifdef LANG_GR
	NULL,			//  0 - text
	NULL,			//  1 - text
	NULL,			//  2 - text
	NULL,			//  3 - color text
	"320 x 200 x 4",        //  4
	"320 x 200 x 4 Grau",   //  5
	"640 x 200 Mono",       //  6
	NULL,			//  7 - monochrome text
	"160 x 200 x 16",       //  8 - PCjr
	"320 x 200 x 16",       //  9 - PCjr
	"640 x 200 x 4",        //  A - PCjr
	NULL,			//  B - reserved
	NULL,			//  C - reserved
	"320 x 200 x 16",       //  D - EGA and better
	"640 x 200 x 16",       //  E - EGA and better
	"640 x 350 Mono",       //  F - EGA and better
	"640 x 200 Farbe",      // 10 - EGA and better
	"640 x 480 Mono",       // 11 - VGA and better
	"640 x 480 x 16",       // 12 - VGA and better
	"320 x 200 x 256"       // 13 - VGA and better
#else
	NULL,			//  0 - text
	NULL,			//  1 - text
	NULL,			//  2 - text
	NULL,			//  3 - color text
	"320 x 200 x 4",        //  4
	"320 x 200 x 4 gray",   //  5
	"640 x 200 mono",       //  6
	NULL,			//  7 - monochrome text
	"160 x 200 x 16",       //  8 - PCjr
	"320 x 200 x 16",       //  9 - PCjr
	"640 x 200 x 4",        //  A - PCjr
	NULL,			//  B - reserved
	NULL,			//  C - reserved
	"320 x 200 x 16",       //  D - EGA and better
	"640 x 200 x 16",       //  E - EGA and better
	"640 x 350 mono",       //  F - EGA and better
	"640 x 200 color",      // 10 - EGA and better
	"640 x 480 mono",       // 11 - VGA and better
	"640 x 480 x 16",       // 12 - VGA and better
	"320 x 200 x 256"       // 13 - VGA and better
#endif				// IFDEF LANG_GR
};

#define NMODETEXT	(sizeof(apszModeText)/sizeof(PSTR))
#define MAXMODE 	(NMODETEXT - 1)

BOOL	InitApplication(HINSTANCE hInstance);
BOOL	InitInstance(HINSTANCE hInstance, int nCmdShow);

LRESULT CALLBACK _export MainWndProc(HWND, UINT, WPARAM, LPARAM);
BOOL	Main_OnCreate(HWND hwnd, CREATESTRUCT FAR* lpCreateStruct);
void	Main_OnDestroy(HWND hwnd);

BOOL CALLBACK _export ModeSwitchHelpDlgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);

BOOL CALLBACK _export ModeSwDlgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
void	ModeSw_OnCommand(HWND hwnd, UINT id, HWND hwndCtl, WORD codeNotify);
BOOL	ModeSw_OnInitDialog(HWND hwnd, HWND hWndFocus, LPARAM lParam);

BOOL	CALLBACK _export TerminateDlgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
BOOL	CALLBACK _export RefuseDlgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
BOOL	CALLBACK _export InsufDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

BOOL CALLBACK _export CfgWarnDlgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
BOOL	CfgWarn_OnInitDialog(HWND hwnd, HWND hWndFocus, LPARAM lParam);


/****************************************************************************
 *
 *  FUNCTION :	lmemset(LPVOID, BYTE, UINT)
 *
 *  PURPOSE  :	_fmemset without the C runtime library
 *
 *  ENTRY    :	LPVOID	lpv;		// ==> buffer
 *		BYTE	b;		// Data used to fill buffer
 *		UINT	cb;		// Length in bytes of buffer
 *
 *  RETURNS  :	LPSTR ==> 1st non-whitespace character in the string
 *
 ****************************************************************************/

LPVOID WINAPI lmemset(LPVOID lpv, BYTE b, UINT cb)
{
    LPBYTE	lpb = (LPBYTE) lpv;

    while (cb--) *lpb++ = b;

    return (lpv);
}


/****************************************************************************
 *
 *  FUNCTION :	SkipWhite(LPSTR)
 *
 *  PURPOSE  :	Advance the input pointer to the first non-whitespace character
 *
 *  ENTRY    :	LPSTR	lp;		// ==> NUL-terminated string
 *
 *  RETURNS  :	LPSTR ==> 1st non-whitespace character in the string
 *
 ****************************************************************************/

LPSTR	SkipWhite(LPSTR lp)
{
    while (*lp == ' ' || *lp == '\t') lp++;

    return (lp);
}


/****************************************************************************
 *
 *  FUNCTION :	SkipBlack(LPSTR)
 *
 *  PURPOSE  :	Advance the input pointer to the whitespace character
 *
 *  ENTRY    :	LPSTR	lp;		// ==> NUL-terminated string
 *
 *  RETURNS  :	LPSTR ==> 1st whitespace character in the string
 *
 ****************************************************************************/

LPSTR	SkipBlack(LPSTR lp)
{
    while (*lp != ' ' && *lp != '\t' && *lp != '\0') lp++;

    return (lp);
}


/****************************************************************************
 *
 *  FUNCTION :	CenterWindow(HWND)
 *
 *  PURPOSE  :	Move the specified window to the center of the screen
 *
 *  ENTRY    :	HWND	hWnd;		// Window to be moved
 *
 *  RETURNS  :	void
 *
 ****************************************************************************/

void	CenterWindow(HWND hWnd)
{
    RECT	rect;
    int 	cx, cy;

    int 	cxScreen = GetSystemMetrics(SM_CXSCREEN);
    int 	cyScreen = GetSystemMetrics(SM_CYSCREEN);

    GetWindowRect(hWnd, &rect);

    cx = rect.right - rect.left;
    cy = rect.bottom - rect.top;

    MoveWindow(hWnd, (cxScreen - cx)/2, (cyScreen - cy)/2, cx, cy, TRUE);
}


/****************************************************************************
 *
 *  FUNCTION :	WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
 *
 *  PURPOSE  :	Main entry point from C runtime startup code
 *
 *  ENTRY    :	HINSTANCE hInstance;	// Handle of current instance
 *		HINSTANCE hPrevInstance;// Handle of previous instance
 *		LPSTR	lpszCmdLine;	// ==> command line tail
 *		int	nCmdShow;	// Parameter to ShowWindow()
 *
 *  RETURNS  :	Return code from PostQuitMessage() or NULL
 *
 ****************************************************************************/

int PASCAL WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
{
    MSG 	msg;
    LPSTR	lp;

    hInst = hInstance;

// Don't run under real or Standard mode
    if (0x030A > SwapLoBytes(LOWORD(GetVersion())) || !(GetWinFlags() & WF_ENHANCED)) {
	FARPROC lpfn;

	if (!GetPrivateProfileInt(szQPopup,	// Section name
				"WarnIfNotEnhancedMode", // Key
				TRUE,		// Default
				STR_PROFILE	// Profile filename
				) ) return (0);

	lpfn = MakeProcInstance((FARPROC) InsufDlgProc, hInst);
	DialogBox(hInst, MAKEINTRESOURCE(IDD_INSUF), NULL, (DLGPROC) lpfn);
	FreeProcInstance(lpfn);

	return (0);
    }

// Check for the undocumented /KILL switch to remove a resident copy of QPopup

    lpszCmdLine = SkipWhite(lpszCmdLine);	// ==> 1st non-blank
    lp = SkipBlack(lpszCmdLine);		// ==> end of token
    *lp = '\0';

    if (!lstrcmpi(lpszCmdLine, "/KILL")) {      // /KILL specified
	TASKENTRY	te;
	int		n;

	lmemset(&te, 0x00, sizeof(TASKENTRY));
	te.dwSize = sizeof(TASKENTRY);
	TaskFirst(&te);

	for (n = GetNumTasks()-1; n; n--) {
	    if (te.hInst == hPrevInstance) {

// Find the main window of the app
		HWND	hWnd = FindWindow(szQPopup, NULL);

		if (GetWindowTask(hWnd) == te.hTask) {
		    SendMessage(hWnd, UM_UNREG, 0, 0L);
		}

		TerminateApp(te.hTask, NO_UAE_BOX);
		return (0);
	    }

	    TaskNext(&te);
	}

	MessageBox(NULL,
		"Can't find an instance of " STR_APPNAME " to kill",
		STR_APPNAME " /KILL",
		MB_ICONEXCLAMATION
		);

	return (0);
    }


    if (!hPrevInstance) {
	if (!InitApplication(hInstance)) {
	    return (FALSE);
	}
    } else {
#ifdef _DEBUG
	char	szString[128];		// variable to load resource strings

	LoadString(hInstance, IDS_ERR_INSTANCE, szString, sizeof(szString));
	MessageBox(NULL, szString, NULL, MB_ICONEXCLAMATION);
#endif
	return (0);
    }

    if (!InitInstance(hInstance, nCmdShow)) {
	return (FALSE);
    }

    while (GetMessage(&msg, NULL, 0, 0)) {	// Until WM_QUIT message
	    TranslateMessage(&msg);
	    DispatchMessage(&msg);
    }

//    if (nMainClass == TRUE) UnregisterClass(szQPopup, hInstance);

    return ((int) msg.wParam);
} /* WinMain */


/****************************************************************************
 *
 *  FUNCTION :	InitApplication(HINSTANCE)
 *
 *  PURPOSE  :	Performs initialation required only once per application
 *
 *  ENTRY    :	HINSTANCE hInstance;	// Module instance handle (DS)
 *
 *  RETURNS  :	TRUE if successful
 *
 ****************************************************************************/

BOOL InitApplication(HINSTANCE hInstance)
{
    char	szBuf[128];	// Buffer to hold LoadString resources
    WNDCLASS	wc;

// Create DOSMAXDefault=OFF in the [Qualitas] section in SYSTEM.INI if missing
    GetPrivateProfileString(
			    "QUALITAS",         // Section name
			    "DOSMAXDefault",    // Key name
			    "OFF",              // Default string
			    szBuf,		// Output buffer
			    sizeof(szBuf),	// Size of output buffer
			    "SYSTEM.INI"        // .INI filename
			    );

    if (!lstrcmpi(szBuf, "OFF")) {              // Got back default or OFF
	WritePrivateProfileString(
			    "QUALITAS",         // Section name
			    "DOSMAXDefault",    // Key name
			    szBuf,		// New text
			    "SYSTEM.INI"        // Profile filename
			    );
    }

// Register the class for the main window
    lmemset(&wc, 0x00, sizeof(WNDCLASS));
    wc.style		= CS_BYTEALIGNWINDOW;
    wc.lpfnWndProc	= MainWndProc;
    wc.hInstance	= hInstance;
    wc.hCursor		= LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground	= GetStockObject(WHITE_BRUSH);
    wc.lpszClassName	= szQPopup;

    if (RegisterClass(&wc)) return (TRUE);

    LoadString(hInstance, IDS_ERR_REGISTER_CLASS, szBuf, sizeof(szBuf));
    MessageBox(NULL, szBuf, NULL, MB_ICONEXCLAMATION);

    return (FALSE);
}


/****************************************************************************
 *
 *  FUNCTION :	InitInstance(HINSTANCE, int)
 *
 *  PURPOSE  :	Per instance initialization
 *
 *  ENTRY    :	HINSTANCE hInstance;	// Module instance handle (DS)
 *		int	nCmdShow;	// SW_xxx WinExec() parameter
 *
 *  RETURNS  :	TRUE if successful
 *
 ****************************************************************************/

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
    char	szDrive[_MAX_DRIVE];
    char	szDir[_MAX_DIR];
    char	szFname[_MAX_FNAME];
    char	szExt[_MAX_EXT];

    fDebug = GetPrivateProfileInt(
				szQPopup,	// Section name
				"Debug",        // Key
				FALSE,		// Default
				STR_PROFILE	// Profile filename
				);

// We ask for DOSMAX.386 first to help weed out other vendor's LoadHi
// devices, such as EMM386.EXE.

    if (fDebug)
	_asm int 1			; Call our debugger

    _asm {
	push	es			; Save
	push	di			; ...

	sub	di,di			; Assume it won't work
	mov	es,di			; ...
;;;;;;; assume	es:nothing		; Tell the assembler

	mov	ax,0x1684		; Get device API entry point
	mov	bx,DOSMAX_Device_ID	; DOSMAX.386 (0x2402)
	int	0x2F			; Windows services
;;;;;;; assume	es:nothing		; Tell the assembler

	mov	ax,es			; Did we get a valid pointer?
	or	ax,di			; ...
	jnz	GOT_API_ENTRY_POINT	; Rejoin common code if so

	mov	ax,0x1684		; Get device API entry point
	mov	bx,LoadHi_Device_ID	; 386MAX.VXD (0x001C)
	int	0x2F			; Windows services
;;;;;;; assume	es:nothing		; Tell the assembler
    }

GOT_API_ENTRY_POINT:
    _asm {
	mov	word ptr VxD+0,di	; Save FAR PTR to VxD PM API
	mov	word ptr VxD+2,es	; ...

	pop	di			; Restore
	pop	es			; ...
;;;;;;; assume	es:nothing		; Tell the assembler
    }

    if (!VxD) { 		// Oops, no VxD
	char	szStr1[256], szStr2[256];

	LoadString(hInst, IDS_386MAX_WARN, szStr1, sizeof(szStr1));
	LoadString(hInst, IDS_386MAX_VXDWARN, szStr2, sizeof(szStr2));

	MessageBox(NULL, szStr2, szStr1, MB_ICONEXCLAMATION);
    }

    if (VxD) _asm {
	mov	ax,VMAX_GetVer	; Get 386MAX.VXD version #
	call	VxD		; Call the VxD
	mov	wVxDVer,ax	; Save the version #
    }

    if (VxD) _asm {
	mov	ax,VMAX_GetSwatVer
	call	VxD
	mov	wSwatVer,ax	; Save SWAT version or 0
    }

// Check for presence of ASQ.EXE in QMAX.INI.  Add it if missing.
    {
	char	szBuf[64];

	szBuf[0] = '\0';        // Ensure NUL terminated
	GetPrivateProfileString(
				"IgnoreGraphicsModeSwitch", // Section
				"ASQ.EXE",              // Key name
				"",                     // Default string
				szBuf,			// Output buffer
				sizeof(szBuf),		// Size of output buffer
				STR_PROFILE		// .INI filename
				);

	if (!szBuf[0]) {
	    WritePrivateProfileString(
				"IgnoreGraphicsModeSwitch", // Section name
				"ASQ.EXE",              // Key name
				"1",                    // New '=' text
				STR_PROFILE		// Profile filename
				);
	}
    }

// Build the filespec for QPOPUP.INF from the .EXE path

    GetModuleFileName(hInst, szInfFilespec, sizeof(szInfFilespec));
    _splitpath(szInfFilespec, szDrive, szDir, szFname, szExt);
    _makepath(szInfFilespec, szDrive, szDir, szFname, ".INF");

// Create application's main window

    hWndMain = CreateWindow(
		szQPopup,	// Window class name
		NULL,		// Window title
		APP_STYLE,	// Window style
		0, 0,		// Position
		CW_USEDEFAULT, CW_USEDEFAULT,	// Size
		NULL,		// Parent window handle
		NULL,		// Default to Class Menu
		hInstance,	// Instance of window
		NULL);		// Create struct for WM_CREATE


    if (hWndMain == NULL) {
	char	szString[128];		// variable to load resource strings

	LoadString(hInstance, IDS_ERR_CREATE_WINDOW, szString, sizeof(szString));
	MessageBox(NULL, szString, NULL, MB_ICONEXCLAMATION);
	return (IDS_ERR_CREATE_WINDOW);
    }

    ShowWindow(hWndMain, SW_HIDE);

    return (TRUE);
}


/****************************************************************************
 *
 *  FUNCTION :	MainWndProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Window procedure for the main class
 *
 *  ENTRY    :	HWND	hWnd;		// Window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	LRESULT appropriate for the message
 *
 ****************************************************************************/

LRESULT CALLBACK _export MainWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {

	HANDLE_MSG(hWnd, WM_CREATE,	Main_OnCreate);
	HANDLE_MSG(hWnd, WM_DESTROY,	Main_OnDestroy);

	case UM_UNREG:
	    UnRegisterWithVxD();
	    return (0);

	case UM_CALLBACK:	// Got a callback from the VxD
	{			// wParam = Selector to Per VM CB
	    int 	n;
	    HWND	hWndOldAp;

	    FARPROC lpfnDlgProc;
	    WORD	wLimit;
	    int 	nRc = 0;		// Return code

	    LPPERVMCB	lpPERVMCB;

	    lpPERVMCB = (LPPERVMCB) MK_FP(wParam, 0);

	    if (wParam < 8) {
BAD_SEL_MSG:
#ifdef LANG_GR
		MessageBox(hWnd, "Schlechter Selektor von 386MAX.VXD erhalten", NULL, MB_ICONEXCLAMATION);
#else
		MessageBox(hWnd, "Bad selector received from 386MAX.VXD", NULL, MB_ICONEXCLAMATION);
#endif			// IFDEF LANG_GR
		return (0);
	    }

	    wLimit = 0;

	    _asm {
		OSP
		sub ax,ax
		mov ax,wParam
		_asm _emit 0x66 // lsl ebx,eax
		_asm _emit 0x0F
		_asm _emit 0x03
		_asm _emit 0xD8

		jnz short BAD_LSL

		mov wLimit,bx
	    }
BAD_LSL:
	    if (!wLimit) goto BAD_SEL_MSG;

// Split cases based on requsted function
	    if (lpPERVMCB->wFunction == CBFN_MODESWITCH) {

		hWndOldAp = GetWinOldApHWNDFromVMHandle(lpPERVMCB->VM_Handle);
    // Check for this app's presence in the .INI file
		n = GetPrivateProfileInt(
				"IgnoreGraphicsModeSwitch",     // Section
				lpPERVMCB->lpszFilename,	// Program name
				0,				// Default
				STR_PROFILE	// Profile filename
				);

		if (n) {	// Always ignore
		    DWORD	VM_Handle = lpPERVMCB->VM_Handle;
		    WORD	wVMInfo;
		    WORD	fVMInfo;

		    if (VxD && wSwatVer && fDebug) _asm int 1;

		    _asm {	// SHELL_GetVMInfo
			mov	ax,VMAX_GetVMInfo
			OSP
			mov	bx,word ptr VM_Handle
			call	VxD		// Carry set if error
			mov	wVMInfo,ax	// Save VMInfo
			sbb	bx,bx		// BX = 0 if OK, -1 if error
			not	bx		// BX = -1 if OK, 0 if error
			mov	fVMInfo,bx	// Save flag
		    }

		    if (fVMInfo && (wVMInfo & SGVMI_Windowed)) {
			SetFocus(hWndOldAp);
		    }

		    _asm {
			mov	ax,VMAX_IgnoreModeSwitch
			OSP
			mov	bx,word ptr VM_Handle
			call	VxD
		    }

// Note that lpPERVMCB is made invalid by the VxD call.
// The VxD has zeroed any segment registers that contained it.

		    return (0);
		}

		hInst = (HINSTANCE) GetWindowWord(hWnd, GWW_HINSTANCE);
		lpfnDlgProc = MakeProcInstance((FARPROC) ModeSwDlgProc, hInst);

		nRc = DialogBoxParam(
				    hInst,
				    MAKEINTRESOURCE(IDD_MODESW),
				    hWnd,
				    (DLGPROC) lpfnDlgProc,
				    (LPARAM) lpPERVMCB
				    );

		FreeProcInstance(lpfnDlgProc);

		if (nRc == IDB_TERMINATE) {
		    DWORD	VM_Handle = lpPERVMCB->VM_Handle;

		// Show 'em the 'refuse to run in the future' dialog
		    FARPROC lpfn = MakeProcInstance((FARPROC) RefuseDlgProc, hInst);

		    nRc = DialogBoxParam(
					hInst,
					MAKEINTRESOURCE(IDD_REFUSE),
					hWnd,
					(DLGPROC) lpfn,
					(LPARAM) lpPERVMCB
					);

		    FreeProcInstance(lpfn);

		    _asm {
			mov	ax,VMAX_Terminate
			OSP
			mov	bx,word ptr VM_Handle
			call	VxD
		    }
// Note that lpPERVMCB is made invalid by the VxD call.
// The VxD has zeroed any segment registers that contained it.

		}
		SetFocus(hWndOldAp);

	    } else if (lpPERVMCB->wFunction == CBFN_WARNFLAG ||
		       lpPERVMCB->wFunction == CBFN_FAILFLAG) {

		DWORD	VM_Handle = lpPERVMCB->VM_Handle;

		n = GetPrivateProfileInt(
			lpPERVMCB->wFunction == CBFN_WARNFLAG ?
							"IgnoreCFGWarning" :
							"IgnoreCFGFailure",
			lpPERVMCB->lpszFilename,	// Program name
			0,				// Default
			STR_PROFILE	// Profile filename
			);

		if (n) _asm {
		    mov ax,VMAX_SignalSemaphore
		    OSP
		    mov bx,word ptr VM_Handle
		    call	VxD
		}

// Note that lpPERVMCB is made invalid by the VxD call.
// The VxD has zeroed any segment registers that contained it.

		if (n) return (0);

		hInst = (HINSTANCE) GetWindowWord(hWnd, GWW_HINSTANCE);
		lpfnDlgProc = MakeProcInstance((FARPROC) CfgWarnDlgProc, hInst);

		nRc = DialogBoxParam(
				    hInst,
				    MAKEINTRESOURCE(IDD_CFGWARN),
				    hWnd,
				    (DLGPROC) lpfnDlgProc,
				    (LPARAM) lpPERVMCB
				    );

		FreeProcInstance(lpfnDlgProc);
	    }
	}
	return (0);
    }
    return(DefWindowProc(hWnd, msg, wParam, lParam));

} /* MainWndProc() */

/****************************************************************************
 *
 *  FUNCTION :	RegisterWithVxD(void)
 *
 *  PURPOSE  :	Read QPOPUP.INF and pass it to the VxD
 *		Send the proc instance of the callback to the VxD
 *
 *  ENTRY    :	void
 *
 *  RETURNS  :	0, indicating no errors
 *
 ****************************************************************************/

#define INTERCEPTS_BUFSIZE	8192

BOOL RegisterWithVxD(void)
{
    int 	nLen;

    LPBYTE	lpb;
    PSTR	pszLcl;

    HLOCAL	hLcl = NULL;
    HGLOBAL	hGbl = NULL;
    LPSTR	lpszLcl = NULL;
    WORD	selIntercepts = NULL;

// Read the filenames from the [INTERCEPTS] section of QPOPUP.INF.
// Read each filename as a key to get the flag byte.
// Copy the file/name pairs into a chunk of global memory in the format
// of a 386LOAD.CFG line.
// Pass the selector up to the VxD.

    hLcl = LocalAlloc(LHND, INTERCEPTS_BUFSIZE);
    if (!hLcl) goto NO_INTERCEPTS;

    pszLcl = (PSTR) LocalLock(hLcl);
    lpszLcl = (LPSTR) pszLcl;

    if (!pszLcl) goto NO_INTERCEPTS;

    nLen = GetPrivateProfileString(
			    "INTERCEPTS",       // Section name
			    NULL,		// NULL key means entire section
			    "",                 // Default string
			    lpszLcl,		// Output buffer
			    INTERCEPTS_BUFSIZE, // Size of output buffer
			    szInfFilespec	// .INF filename
			    );

    if (nLen) { 			// Got the profile data
	PSTR	p = pszLcl;
	UINT	cbKeys = 0;

	while (*(PWORD) p != 0) {	// While not the double NUL
	    UINT n = lstrlen(p);

	    cbKeys += 1+1+n+1+8+2;	// Space for flag byte and whitespace
					// ...	     filename.ext and whitespace
					// ...	     datestamp
					// ...	     CR, LF
	    p += n + 1; 		// Skip filename token and NUL
	}

	cbKeys += 2;			// Terminating CTRL+Z and NUL

// Figure out how many there are and how much space it'll all take
// Assume a format of 'I FILENAME.EXT 00/00/00', CR, LF

// Get space for 'em
	hGbl = GlobalAlloc(GHND, cbKeys);
	if (!hGbl) goto NO_INTERCEPTS;

	lpb = (LPBYTE) GlobalLock(hGbl);

	selIntercepts = SELECTOROF(lpb);

	if (selIntercepts) {
	    p = pszLcl;

// Get the key values
	    while (*p) {		// Until no more tokens
		char	szBuf[16];

		UINT n = lstrlen(p);

		GetPrivateProfileString(
					"INTERCEPTS",   // Section name
					p,		// Key
					" ",            // Default string
					szBuf,		// Output buffer
					sizeof(szBuf),	// Buffer size
					szInfFilespec	// .INF filename
					);

		*lpb++ = (BYTE) szBuf[0];
		*lpb++ = ' ';
		lstrcpy(lpb, p); lpb += n;

#define CFGJUNK " 00/00/00\r\n"
		lstrcpy(lpb, CFGJUNK); lpb += sizeof(CFGJUNK)-1;

		p += n + 1;
	    }

	    *lpb++ = '\x1A';            // Terminating CTRL+Z
	    *lpb = '\0';                // Terminating NUL

	    GlobalUnlock(hGbl);
	} // Got a global selector

    } // Got the profile section

NO_INTERCEPTS:
    if (lpszLcl) LocalUnlock(hLcl);  lpszLcl = NULL;
    if (hLcl) LocalFree(hLcl);	hLcl = NULL;

// Register with the VxD
// FIXME the VxD returns AX = 0 if successful
    if (VxD) _asm {
	mov	bx,word ptr lpfnVxDCallback+0	; ES:BX ==> VxDCallback
	mov	es,word ptr lpfnVxDCallback+2	; ...

	mov	dx,selIntercepts		; DX = selector of intercepts

	mov	ax,VMAX_RegisterCallback
	call	VxD		; Call the VxD
    }

    if (hGbl) GlobalFree(hGbl);

    return (0);
}


/****************************************************************************
 *
 *  FUNCTION :	UnRegisterWithVxD(void)
 *
 *  PURPOSE  :	Tell the VxD we're gone and the QPOPUP.INF data is stale
 *
 *  ENTRY    :	void
 *
 *  RETURNS  :	0, indicating no errors
 *
 ****************************************************************************/

BOOL UnRegisterWithVxD(void)
{
    if (VxD) _asm {
	mov	ax,VMAX_UnregisterCallback
	call	VxD
    }

    return (0);
}


/****************************************************************************
 *
 *  FUNCTION :	VxDCallback(WORD, DWORD)
 *
 *  PURPOSE  :	Callback from the VxD
 *		Posts a message to the main window to popup the dialog
 *
 *  ENTRY    :	WORD	wParam; 	// Selector to per VM structure
 *		DWORD	VM_Handle;	// Handle of offending VM
 *
 *  RETURNS  :	0, indicating no errors
 *
 ****************************************************************************/

WORD CALLBACK _export VxDCallback(WORD wParam, DWORD VM_Handle)
{
    if (IsWindow(hWndMain)) {
	PostMessage(hWndMain, UM_CALLBACK, wParam, VM_Handle);
	return (0);
    } else {
	return (1);
    }
}

/****************************************************************************
 *
 *  FUNCTION :	Main_OnCreate(HWND, CREATESTRUCT FAR *)
 *
 *  PURPOSE  :	Process the WM_CREATE window message
 *		Registers the address of the callback proc with the VxD
 *		Read the [INTERCEPTS] section of QPOPUP.INF into a GlobalAlloc()
 *		block and pass the address up to the VxD.
 *
 *  ENTRY    :	HWND	hWnd;		// Window handle
 *		CREATESTRUCT FAR *lpcs; // ==> window creation params
 *
 *  RETURNS  :	TRUE, indicating success
 *
 ****************************************************************************/

BOOL Main_OnCreate(HWND hWnd, CREATESTRUCT FAR * lpCreateStruct)
{
    if (VxD && wSwatVer && fDebug) _asm int 1;

    lpfnVxDCallback = MakeProcInstance((FARPROC) VxDCallback, hInst);

    RegisterWithVxD();

    return (TRUE);
}


/****************************************************************************
 *
 *  FUNCTION :	Main_OnDestroy(HWND)
 *
 *  PURPOSE  :	Process the WM_DESTROY window message
 *		Unregister the callback proc address with the VxD
 *		Post the WM_QUIT message
 *
 *  ENTRY    :	HWND	hWnd;		// Window handle
 *
 *  RETURNS  :	VOID
 *
 ****************************************************************************/

void Main_OnDestroy(HWND hWnd)
{
    UnRegisterWithVxD();

    FreeProcInstance(lpfnVxDCallback);

    PostQuitMessage(0);
}


/****************************************************************************
 *
 *  FUNCTION :	ModeSwitchHelpDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for help on the mode switch
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export ModeSwitchHelpDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {

	case WM_COMMAND:
	    switch (wParam) {
		case IDOK:
		case IDCANCEL:
		    EndDialog(hWnd, wParam);
	    }
	    return (FALSE);

	case WM_ERASEBKGND:
	    {
		RECT	rect;
		HBRUSH	hbrOld;
		HBRUSH	hbr = CreateSolidBrush(GetSysColor(COLOR_BTNFACE));
		HDC	hDC = (HDC) wParam;

		UnrealizeObject(hbr);
		hbrOld = SelectObject(hDC, hbr);

		GetClientRect(hWnd, &rect);

		FillRect(hDC, &rect, hbr);

		SelectObject(hDC, hbrOld);
		DeleteBrush(hbr);
	    }
	    return (TRUE);

	case WM_INITDIALOG:
	    {
		HRSRC	hRsrc = FindResource(hInst, MAKEINTRESOURCE(ID_HELPTEXT), RT_RCDATA);

		if (hRsrc) {
		    HLOCAL	hOld = (HLOCAL) SendDlgItemMessage(hWnd, IDE_HELP, EM_GETHANDLE, 0, 0L);
		    HGLOBAL	hGblRsrc = LoadResource(hInst, hRsrc);

		    LPSTR	lpszRsrc = (LPSTR) LockResource(hGblRsrc);

		    HLOCAL	hNew = LocalAlloc(LHND, lstrlen(lpszRsrc) + 1);

		    LPSTR	lpsz = (LPSTR) LocalLock(hNew);

		    lstrcpy(lpsz, lpszRsrc);

		    LocalUnlock(hNew);

		    if (hOld) LocalFree(hOld);

		    UnlockResource(hGblRsrc);
		    FreeResource(hGblRsrc);

		    SendDlgItemMessage(hWnd, IDE_HELP, EM_SETHANDLE, (WPARAM) hNew, 0L);
		    SendDlgItemMessage(hWnd, IDE_HELP, EM_SETREADONLY, (WPARAM) (BOOL) TRUE, 0L);
		}
	    }
	    return (TRUE);
    }

    return (FALSE);
}


/****************************************************************************
 *
 *  FUNCTION :	ModeSwDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for the mode switch popup
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export ModeSwDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {

	case WM_COMMAND:
	    ModeSw_OnCommand(hWnd, (UINT) wParam, (HWND) LOWORD (lParam), HIWORD(lParam));
	    return (FALSE);

	case WM_INITDIALOG:
	    ModeSw_OnInitDialog(hWnd, (HWND) wParam, lParam);
	    return (TRUE);
    }

    return (FALSE);
}


/****************************************************************************
 *
 *  FUNCTION :	ModeSw_OnCommand(HWND, UINT, HWND, WORD)
 *
 *  PURPOSE  :	Process the WM_COMMAND messages sent to ModeSwDlgProc()
 *
 *  ENTRY    :	HWND	hWnd;		// Parent window handle
 *		UINT	id;		// Control ID
 *		HWND	hWndCtl;	// Contro window handle
 *		WORD	codeNotify;	// 1- if accelerator, 0 - menu
 *
 *  RETURNS  :	VOID
 *
 ****************************************************************************/

void ModeSw_OnCommand(HWND hWnd, UINT id, HWND hWndCtl, WORD codeNotify)
{
    int 	rc;

    HLOCAL	hPerPopup = (HLOCAL) GetProp(hWnd, szQPopup);

    PPERPOPUP	pPerPopup = (PPERPOPUP) LocalLock(hPerPopup);

    LPPERVMCB	lpPERVMCB = pPerPopup->lpPERVMCB;

    HWND	hWndOldAp = pPerPopup->hWndOldAp;

    LocalUnlock(hPerPopup);

    switch (id) {

	case IDB_ALWAYS:		// Write out to the .INI file
					// Fall into IDB_IGNORE
	    WritePrivateProfileString(
		    "IgnoreGraphicsModeSwitch",         // Section name
		    lpPERVMCB->lpszFilename,		// Program name
		    "1",                        // New '=' text
		    STR_PROFILE 		// Profile filename
		    );


	case IDB_IGNORE:
	    {
		DWORD	VM_Handle = lpPERVMCB->VM_Handle;

		LocalFree(hPerPopup);

		RemoveProp(hWnd, szQPopup);
		EndDialog(hWnd, id);

		if (VxD) _asm {
		    mov ax,VMAX_IgnoreModeSwitch
		    OSP
		    mov bx,word ptr VM_Handle
		    call	VxD
		    mov rc,ax
		}

		SetFocus(hWndOldAp);
	    }

	    return;

	case IDB_TERMINATE:
	    {
		FARPROC lpfn = MakeProcInstance((FARPROC) TerminateDlgProc, hInst);

		rc = DialogBox(hInst, MAKEINTRESOURCE(IDD_TERMINATE), hWnd, (DLGPROC) lpfn);

		FreeProcInstance(lpfn);


		if (rc == IDOK) {
		    LocalFree(hPerPopup);

		    RemoveProp(hWnd, szQPopup);
		    EndDialog(hWnd, id);
		}
	    }
	    return;

	case IDB_MODESWHELP:
	    {
		FARPROC lpfnModeSwitchHelpDlgProc = MakeProcInstance((FARPROC) ModeSwitchHelpDlgProc, hInst);

		rc = DialogBox(hInst,
			    MAKEINTRESOURCE(IDD_MODESWHELP),
			    hWnd,
			    (DLGPROC) lpfnModeSwitchHelpDlgProc
			    );

		FreeProcInstance(lpfnModeSwitchHelpDlgProc);
	    }
	    return;


	case IDOK:
	case IDCANCEL:
	    MessageBeep(MB_ICONQUESTION);
    }
}


/****************************************************************************
 *
 *  FUNCTION :	ModeSw_OnInitDialog(HWND, HWND, LPARAM)
 *
 *  PURPOSE  :	Process the WM_INITDIALOG messages sent to ModeSwDlgProc()
 *		Figure out the video mode description string
 *
 *  ENTRY    :	HWND	hWnd;		// Parent window handle
 *		HWND	hWndFocus;	// Control window handle getting focus
 *		LPARAM	lParam; 	// Extra data passed to dialog creator
 *
 *  RETURNS  :	FALSE	- Focus was changed
 *		TRUE	- Focus was not changed
 *
 ****************************************************************************/

BOOL ModeSw_OnInitDialog(HWND hWnd, HWND hWndFocus, LPARAM lParam)
{
// Room for "dd (XXh) 320 x 200 x 4 grey", 0 plus some slop
    char	szBuffer[27+1+16];

    LPPERVMCB	lpPERVMCB = (LPPERVMCB) lParam;

    HWND	hWndOldAp = GetWinOldApHWNDFromVMHandle(lpPERVMCB->VM_Handle);

    HLOCAL	hPerPopup = LocalAlloc(LHND, sizeof(PERPOPUP));

    PPERPOPUP	pPerPopup = (PPERPOPUP) LocalLock(hPerPopup);

    pPerPopup->lpPERVMCB = lpPERVMCB;
    if (VxD && wSwatVer && fDebug) _asm int 1;
    pPerPopup->hWndOldAp = hWndOldAp;

    SetDlgItemText(hWnd, IDT_NAME, lpPERVMCB->lpszFilename);

// Figure out the resolution of the video mode --
// For lower numbered modes we look 'em up in a table of text descriptions.
// For higher numbered modes normally associated with super VGA adapters
// we print the mode number itself.

    wsprintf(szBuffer, "%2d (%.2Xh)", lpPERVMCB->wVideoMode, lpPERVMCB->wVideoMode);

    if (lpPERVMCB->wVideoMode <= MAXMODE) {
	wsprintf(szBuffer + lstrlen(szBuffer), " %s",
	    (LPSTR) apszModeText[lpPERVMCB->wVideoMode]);
    }

    SetDlgItemText(hWnd, IDT_MODE, szBuffer);

    LocalUnlock(hPerPopup);

    SetProp(hWnd, szQPopup, hPerPopup);

    CenterWindow(hWnd);

    return (TRUE);
}


/****************************************************************************
 *
 *  FUNCTION :	TerminateDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for the terminate VM warning popup
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export TerminateDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
	case WM_COMMAND:
	    switch (wParam) {
		case IDOK:
		case IDCANCEL:
		    EndDialog(hWnd, wParam);
	    }
	    break;

	case WM_INITDIALOG:
	    return (TRUE);
    }

    return (FALSE);
}

/****************************************************************************
 *
 *  FUNCTION :	RefuseDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for the 'refuse to run in the future' option
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export RefuseDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
	case WM_COMMAND:
	    switch (wParam) {
		case IDYES:
		    {
			char szFilename[8+1+3+1];

			if (GetDlgItemText(hWnd, IDT_REFUSE_FILENAME, szFilename, sizeof(szFilename)) ) {
			    WritePrivateProfileString(
				"INTERCEPTS",   // Section name
				szFilename,	// New FOO.EXE=key
				"F",            // ... =F
				szInfFilespec	// Profile filename
				);
			}

			UnRegisterWithVxD();
			RegisterWithVxD();	// Refresh QPOPUP.INF data
		    }
		// Fall into 'case IDNO:'

		case IDNO:
		    EndDialog(hWnd, wParam);
		    break;

		case IDOK:
		case IDCANCEL:
		    MessageBeep(MB_ICONQUESTION);
		    break;

		case IDB_MODESWHELP:
		    {
			FARPROC lpfn = MakeProcInstance((FARPROC) ModeSwitchHelpDlgProc, hInst);

			DialogBox(hInst,
				    MAKEINTRESOURCE(IDD_MODESWHELP),
				    hWnd,
				    (DLGPROC) lpfn
				    );

			FreeProcInstance(lpfn);
		    }
		    break;

	    }
	    break;

	case WM_INITDIALOG:
	    {
		LPPERVMCB	lpPERVMCB = (LPPERVMCB) lParam;

		SetDlgItemText(hWnd, IDT_REFUSE_FILENAME, lpPERVMCB->lpszFilename);
		CenterWindow(hWnd);
	    }
	    return (TRUE);
    }

    return (FALSE);
}

/****************************************************************************
 *
 *  FUNCTION :	InsufDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for the insufficient Windows mode popup
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export InsufDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
	case WM_COMMAND:
	    switch (wParam) {
		case IDOK:
		case IDCANCEL:
		    EndDialog(hWnd, wParam);
		    return (FALSE);
	    }
	    return (FALSE);

	case WM_DESTROY:
	    {
		BOOL	fExpert = IsDlgButtonChecked(hWnd, IDB_EXPERT);

		WritePrivateProfileString(
		    szQPopup,			// Section name
		    "WarnIfNotEnhancedMode",    // Key
		    fExpert ? "0" : "1",        // New '=' text
		    STR_PROFILE 		// Profile filename
		    );
	    }
	    return (FALSE);

	case WM_INITDIALOG:
	    return (TRUE);
    }

    return (FALSE);
}

/****************************************************************************
 *
 *  FUNCTION :	CfgWarnDlgProc(HWND, UINT, WPARAM, LPARAM)
 *
 *  PURPOSE  :	Dialog proc for the 386LOAD.CFG warning popup
 *
 *  ENTRY    :	HWND	hWndDlg;	// Dialog window handle
 *		UINT	msg;		// WM_xxx message
 *		WPARAM	wParam; 	// Message 16-bit parameter
 *		LPARAM	lParam; 	// Message 32-bit parameter
 *
 *  RETURNS  :	FALSE	- Message processed
 *		TRUE	- DefDlgProc() must process the message
 *
 ****************************************************************************/

BOOL CALLBACK _export CfgWarnDlgProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {

	case WM_INITDIALOG:
	    CfgWarn_OnInitDialog(hWnd, (HWND) wParam, lParam);
	    return (TRUE);

	case WM_COMMAND:
	    switch (wParam) {
		case IDB_CFG_FUTURE:
		    {
		    HLOCAL	hPerPopup = (HLOCAL) GetProp(hWnd, szQPopup);

		    PPERPOPUP	pPerPopup = (PPERPOPUP) LocalLock(hPerPopup);

		    LPPERVMCB	lpPERVMCB = pPerPopup->lpPERVMCB;

		    WritePrivateProfileString(
			    lpPERVMCB->wFunction == CBFN_WARNFLAG ?
						"IgnoreCFGWarning" :
						"IgnoreCFGFailure",
			    lpPERVMCB->lpszFilename,		// Program name
			    "1",                        // New '=' text
			    STR_PROFILE 		// Profile filename
			    );
		    LocalUnlock(hPerPopup);
		    }
		    break;

		case IDOK:
		case IDCANCEL:
		{
		    HLOCAL	hPerPopup = (HLOCAL) GetProp(hWnd, szQPopup);

		    PPERPOPUP	pPerPopup = (PPERPOPUP) LocalLock(hPerPopup);

		    LPPERVMCB	lpPERVMCB = pPerPopup->lpPERVMCB;

		    HWND	hWndOldAp = pPerPopup->hWndOldAp;

		    DWORD	VM_Handle = lpPERVMCB->VM_Handle;

		    LocalUnlock(hPerPopup);

		    _asm {
			mov	ax,VMAX_SignalSemaphore
			OSP
			mov	bx,word ptr VM_Handle
			call	VxD
		    }

// Note that lpPERVMCB is made invalid by the VxD call.
// The VxD has zeroed any segment registers that contained it.

		    LocalFree(hPerPopup);

		    RemoveProp(hWnd, szQPopup);

		    EndDialog(hWnd, wParam);

		    SetFocus(hWndOldAp);
		}
	    }
	    return (FALSE);

    }

    return (FALSE);
}


/****************************************************************************
 *
 *  FUNCTION :	CfgWarn_OnInitDialog(HWND, HWND, LPARAM)
 *
 *  PURPOSE  :	Process the WM_INITDIALOG messages sent to CfgWarnDlgProc()
 *
 *  ENTRY    :	HWND	hWnd;		// Parent window handle
 *		HWND	hWndFocus;	// Control window handle getting focus
 *		LPARAM	lParam; 	// Extra data passed to dialog creator
 *
 *  RETURNS  :	FALSE	- Focus was changed
 *		TRUE	- Focus was not changed
 *
 ****************************************************************************/

BOOL CfgWarn_OnInitDialog(HWND hWnd, HWND hWndFocus, LPARAM lParam)
{
    char	szBuf[256];
#define BUFLEN	(sizeof(szBuf)-1)

    FILE	*fd = NULL;

    LPSTR	lpsz;
    PSTR	psz;

    HWND	hWndHelp = GetDlgItem(hWnd, IDE_CFG_HELPTEXT);

    HLOCAL	hLcl = NULL;
    BOOL	fCustom = FALSE;

    LPPERVMCB	lpPERVMCB = (LPPERVMCB) lParam;

    HWND	hWndOldAp = GetWinOldApHWNDFromVMHandle(lpPERVMCB->VM_Handle);

    HLOCAL	hPerPopup = LocalAlloc(LHND, sizeof(PERPOPUP));

    PPERPOPUP pPerPopup = (PPERPOPUP) LocalLock(hPerPopup);

    pPerPopup->lpPERVMCB = lpPERVMCB;

    pPerPopup->hWndOldAp = hWndOldAp;

    LocalUnlock(hPerPopup);

    SetProp(hWnd, szQPopup, hPerPopup);

// FIXME Henry says fopen() does an malloc().
// I wonder if that's OK?

    if (fd = fopen(szInfFilespec, "r")) {
	char	szTmp[81];
	PSTR	pszTok;

	while (fgets(szBuf, BUFLEN, fd)) {
	    szBuf[BUFLEN] = '\0';
	    pszTok = szTmp;

	    hLcl = LocalAlloc(LMEM_MOVEABLE, 1);
	    psz =  (PSTR) LocalLock(hLcl);
	    *psz = '\0';
	    LocalUnlock(hLcl);

	    if (sscanf(szBuf, "%80s", pszTok) && *pszTok == '[' && (pszTok = strtok(pszTok, "[]"))) {

		if (!_fstrcmp(pszTok, lpPERVMCB->lpszFilename)) {

		    while (fgets(szBuf, BUFLEN, fd) && szBuf[0] != '[') {

			if (psz = strchr(szBuf, '\n')) {
			    *psz++ = '\r';
			    *psz++ = '\n';
			    *psz++ = '\0';
			}

			hLcl = LocalReAlloc(hLcl, LocalSize(hLcl) + lstrlen(szBuf), LMEM_MOVEABLE);
			psz =  (PSTR) LocalLock(hLcl);
			lstrcat(psz, szBuf);
			LocalUnlock(hLcl);

		    } // Not EOF
		    fCustom = TRUE;
		    break;

		} // Found the right section

	    } // Found a section name

	} // Not EOF

    } // Opened file

    if (fd) fclose(fd);

    if (!hLcl || !fCustom) {	// No special text -- use the generic messages
	HRSRC	hRsrc = NULL;

	if (lpPERVMCB->wFunction == CBFN_WARNFLAG) {
	    hRsrc = FindResource(hInst, MAKEINTRESOURCE(ID_WARNTEXT),RT_RCDATA);
	} else if (lpPERVMCB->wFunction == CBFN_FAILFLAG) {
	    hRsrc = FindResource(hInst, MAKEINTRESOURCE(ID_FAILTEXT),RT_RCDATA);
	}

	if (hRsrc) {
	    HLOCAL	hOld = (HLOCAL) SendDlgItemMessage(hWnd, IDE_HELP, EM_GETHANDLE, 0, 0L);
	    HGLOBAL	hGblRsrc = LoadResource(hInst, hRsrc);

	    LPSTR	lpszRsrc = (LPSTR) LockResource(hGblRsrc);

	    hLcl = LocalAlloc(LHND, lstrlen(lpszRsrc) + 1);

	    lpsz = (LPSTR) LocalLock(hLcl);

	    lstrcpy(lpsz, lpszRsrc);

	    LocalUnlock(hLcl);

	    if (hOld) LocalFree(hOld);

	    UnlockResource(hGblRsrc);
	    FreeResource(hGblRsrc);
	}
    }

    if (hLcl) {
	Edit_SetHandle(hWndHelp, hLcl);
    } else {
// FIXME no text at all to display, now what?
    }
    Edit_SetReadOnly(hWndHelp, TRUE);
    Edit_SetSel(hWndHelp, 1, 2);

    SetDlgItemText(hWnd, IDT_CFG_FILENAME, lpPERVMCB->lpszFilename);

    return (TRUE);
}


/****************************************************************************
 *
 *  FUNCTION :	GetSysVMHandle(void)
 *
 *  PURPOSE  :	Get the Sys VM handle from the VxD
 *
 *  ENTRY    :	void
 *
 *  RETURNS  :	HVM of system VM
 *
 ****************************************************************************/


HVM WINAPI GetSysVMHandle(void)
{
    HVM 	VM_Handle = NULL;

    if (VxD) _asm {
	mov	ax,VMAX_GetSysVMHandle ; ... into EBX
	call	VxD		; Call the VxD
	OSP
	mov	word ptr VM_Handle,bx
    }

    return (VM_Handle);
}


/****************************************************************************
 *
 *  FUNCTION :	GetModeWindow(HINSTANCE)
 *
 *  PURPOSE  :	Get the HWND of the top level window belonging to the
 *		specified instance handle.
 *
 *  ENTRY    :	HINSTANCE of application instance in question
 *
 *  RETURNS  :	HWND of main window for the app
 *
 ****************************************************************************/

HWND GetModuleWindow(HINSTANCE hInst)
{
    HWND	hWndNext;
    HTASK	hTask;
    TASKENTRY	te;

// Get the first window in the top-level window chain

    hWndNext = GetWindow( hWndMain, GW_HWNDFIRST );

// Trundle through all the top-level windows

    do {
	if (!GetParent( hWndNext )) {		/* Found a top level window */
	    hTask = GetWindowTask(hWndNext);	/* Get associated task */

	    lmemset(&te, 0x00, sizeof(TASKENTRY));	/* Clear TASKENTRY */
	    te.dwSize = sizeof(TASKENTRY);		/* Set size */
	    TaskFindHandle( &te, hTask );		/* Fill in TASKENTRY */

	    if (hInst == te.hInst) {
		return (hWndNext);		/* Tell 'em we found it */
	    }
	}
    } while (hWndNext = GetNextWindow (hWndNext, GW_HWNDNEXT ));

    return (NULL);				/* Never found it */
}


/****************************************************************************
 *
 *  FUNCTION :	GetWinOldApHWNDFromVMHandle(HVM)
 *
 *  PURPOSE  :	Get the HWND for the WINOLDAP instance assiciated with
 *		the given VH_Handle.
 *
 *  ENTRY    :	HVM	VM_Handle;		// VM handle
 *
 *  RETURNS  :	HWND of WINOLDAP instance controlling the VM_Handle
 *
 ****************************************************************************/

HWND WINAPI GetWinOldApHWNDFromVMHandle(HVM VM_Handle)
{
    int 	n;
    WORD	wDS;
    HINSTANCE	hInstWinOldAp;
    TASKENTRY	te;

    WORD	wWinVer;
    WORD	wVerNdx;
    WORD	wSysVMOff[3] = {0x9C, 0xA8, 0x68};
    WORD	wVMOff[3]    = {0xF0, 0xFC, 0xBC};

    if (VxD && wSwatVer && fDebug) _asm int 1;

    // Get Windows version # and swap to comparison order
    wWinVer = SwapLoBytes(LOWORD(GetVersion()));

    // Set index into wSysVMOff and wVMOff
    if (wWinVer < 0x030A)	// This covers 3.00
	wVerNdx = 0;
    else if (0x030A <= wWinVer && wWinVer < 0x035F) // This covers 3.1x
	wVerNdx = 1;
    else			// This covers 3.95+ (a.k.a. Win95)
	wVerNdx = 2;

    lmemset(&te, 0x00, sizeof(TASKENTRY));
    te.dwSize = sizeof(TASKENTRY);
    TaskFirst(&te);

    for (n = GetNumTasks()-1; n; n--) {
	if (IsWinOldApTask(te.hTask)) {

	// Get WINOLDAP's HINSTANCE, convert it into a selector to its DGROUP
	    hInstWinOldAp = ((LPTDB) MK_FP(te.hTask, 0))->hInst;
	    wDS = SELECTOROF(GlobalLock(hInstWinOldAp));
	    GlobalUnlock(hInstWinOldAp);

	// Verify the Sys_VM_Handle	@ [009C] (3.0)
	//				@ [009C] (3.0a)
	//				@ [00A8] (3.1)
	//				@ [0068] (4.0)

	    if (GetSysVMHandle() != *(LPHVM) MAKELP(wDS, wSysVMOff[wVerNdx])) {
		MessageBox(NULL,
#ifdef LANG_GR
			"Störung durch WINOLDAP!DGROUP",
#else
			"Confused by WINOLDAP!DGROUP",
#endif				// IFDEF LANG_GR
			"GetWinOldApHWNDFromVMHandle()",
			MB_OK);
	    }

	// Check the VM_Handle	@ [00F0] (3.0)
	//			@ [00F0] (3.0a)
	//			@ [00FC] (3.1)
	//			@ [00BC] (4.0)

	    if (VM_Handle == *(LPHVM) MAKELP(wDS, wVMOff[wVerNdx])) {
		return (GetModuleWindow(hInstWinOldAp));
	    }
	}

	TaskNext(&te);
    }

    return (NULL);
}

