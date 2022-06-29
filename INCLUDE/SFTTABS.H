/****************************************************************/
/* SftTabs 1.0 - Tabbed Dialog Toolkit for Windows              */
/* Copyright (C) 1994  Softel vdm. All Rights Reserved.         */
/****************************************************************/

#if !defined(_INC_SFTTABS)
#define _INC_SFTTABS

#if defined(_WIN32) || defined(__FLAT__)
#error  This header file cannot be used with WIN32
#endif

#define MAX_TABBED_ITEMS 64             // Max. # of tabs

// Styles
#define SFTTABS_TOP     0x01            // Tabs on Top of Dialog

#if !defined(RC_INVOKED)

#define TABBEDDIALOG    "TABBEDDIALOG"  // Tabbed Dialog Resource

#if defined(__cplusplus)
extern "C" {
#endif

typedef LRESULT (CALLBACK * TABBEDDLGPROC)(HWND, int, UINT, WPARAM, LPARAM);

#pragma pack(1)                         // packing requirement
typedef struct tagTabbedDialog {
    int size;                           // Size of this structure
    HINSTANCE hinst;                    // Instance handle for resources
    LPCSTR resource;                    // Tabbed Dialog Resource (id or string(name))
    HWND hwndOwner;                     // Owner of main dialog
    int activeItem;                     // initial, active item
    TABBEDDLGPROC lpfnCallback;         // Callback function for subdialogs
    LPARAM lParam;                      // User Data for all subdialogs 
                                        // passed during WM_INITDIALOG
                                        // (remains until tabbed dialog is destroyed)
} TABBEDDIALOGPARM, FAR * LPTABBEDDIALOGPARM;
    
// The following is identical to TABBEDDIALOGPARM, except that all subdialog
// resources have been loaded and pointers are available in lpaTabParms
// this is mainly used by the Dialog Editor where dialog resources are built 
// on the fly

typedef struct tagPreloadTabbedDialog {
    int size;                           // Size of this structure
    HINSTANCE hinst;                    // Instance handle for resources
    LPCSTR resource;                    // Tabbed Dialog Resource (id or string(name))
    HWND hwndOwner;                     // Owner of main dialog
    int activeItem;                     // initial, active item
    TABBEDDLGPROC lpfnCallback;         // Callback function for subdialogs
    LPARAM lParam;                      // User Data for all subdialogs 
                                        // passed during WM_INITDIALOG
                                        // (remains until tabbed dialog is destroyed)
    LPCSTR lpResDlg;                    // Tabbed Dialog Resource
    LPCSTR lpResTabInfo;                // Tab Info Resource
    LPCSTR (FAR *lpalpResDialog)[MAX_TABBED_ITEMS];
                                        // ptr to array of LPCSTR (loaded dialog resources)
} PRELOADTABBEDDIALOGPARM, FAR * LPPRELOADTABBEDDIALOGPARM;
#pragma pack()                          // default packing

// API

LRESULT _export WINAPI DlgTabbed_DefProc(HWND hwndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
void _export WINAPI DlgTabbedDlg_EndDialog(HWND hwndDlg, int val);
BOOL _export WINAPI DlgTabbedDlg_InSimulatedMsg(HWND hwnd);
BOOL _export WINAPI DlgTabbedDlg_IsTabbed(HWND hwnd);

BOOL _export WINAPI DlgTabbedDlg_GetEnable(HWND hwndDlg, int DialogID);
BOOL _export WINAPI DlgTabbedDlg_Enable(HWND hwndDlg, int DialogID, BOOL fActive);
BOOL _export WINAPI DlgTabbedDlg_GetText(HWND hwndDlg, int DialogID, LPSTR lpszText, int cbText);
BOOL _export WINAPI DlgTabbedDlg_SetText(HWND hwndDlg, int DialogID, LPCSTR lpszText);
int _export WINAPI DlgTabbedDlg_GetTabs(HWND hwndDlg);
BOOL _export WINAPI DlgTabbedDlg_SwitchDialog(HWND hwndDlg, int DialogID);
LRESULT _export WINAPI DlgTabbedDlg_GetUserData(HWND hwndDlg);

BOOL _export WINAPI DlgTabbedDlg_Do(LPTABBEDDIALOGPARM lpTab);
HWND _export WINAPI DlgTabbedDlg_Create(LPTABBEDDIALOGPARM lpTab);

#define GetTabbedDialogResult(fResult, hwndDlg, msg, wParam, lParam)            \
    (   IsWindow((hwndDlg))                                                     \
            ? (fResult)                                                         \
                ? ((msg) == WM_CTLCOLOR || (msg) == WM_COMPAREITEM ||           \
                        (msg) == WM_VKEYTOITEM || (msg) == WM_CHARTOITEM ||     \
                        (msg) == WM_QUERYDRAGICON || (msg) == WM_INITDIALOG ||  \
                        (msg) == WM_QUERYENDSESSION)                            \
                    ? (LRESULT) (fResult)                                       \
                    : GetWindowLong((hwndDlg), DWL_MSGRESULT)                   \
                : ((msg) == WM_QUERYENDSESSION)                                 \
                    ? (fResult)                                                 \
                    : DlgTabbed_DefProc((hwndDlg), (msg), (wParam), (lParam))   \
            : TRUE                                                              \
    )

#ifdef __cplusplus
}

#include "sfttabs2.h"                   // Additional definitions when using C++

#if !defined(NOCLASSLIBRARY) 

// use #define NOCLASSLIBRARY when using C++, but not MFC
#if !defined(__BORLANDC__)
#include "sftmfc2.h"                    // Definitions for C++ MFC 2.x
#endif

#endif

#endif /* !defined(NOCLASSLIBRARY) */

#endif  /* !defined(RC_INVOKED) */

#endif  /* !defined(_INC_SFTTABS) */

