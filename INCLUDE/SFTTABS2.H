/****************************************************************/
/* SFTTABS2.H - Tabbed Dialog Support for Windows               */
/* Copyright (C) 1994  Softel vdm. All Rights Reserved.         */
/****************************************************************/

#ifndef _INC_SFTTABS2
#define _INC_SFTTABS2

#if defined(_WIN32) || defined(__FLAT__)
#error  This header file cannot be used with WIN32
#endif

#if defined(__cplusplus)
extern "C" {
#endif

#if !defined(RC_INVOKED)

#endif /* RC_INVOKED */

// Instance Data, each Main Tabbed Dialog has this data attached
// using Window Properties (C) or using the Class Instance data (C++)

#pragma pack(1)                         // packing requirement
typedef struct tagDLGDATA
{
    HWND hwndDlg;                       // Itself
    HINSTANCE hinst;                    // Instance handle for caller's resources
    BOOL fModal;                        // TRUE if this is a modal dialog
    BOOL fRedraw;                       // TRUE if redraw mode on
    LPARAM lParam;                      // User Init Data
    WORD style;                         // Style
    
    int nTabs;                          // # of defined tabs
    int items;                          // # of tabs displayed (rows*cols)
    int rows, cols;                     // Rows and columns of tabs
    int cx, cy;                         // Width, height of available client area
    
    TABBEDDLGPROC lpfnCallback;         // Current subdialog callback procedure
    int activeItem;                     // Active item # (or -1 if none)
    HWND hwndTab;                       // Window for active tab simulation

    BOOL fSimulated;                    // TRUE if in SftTabs generated message

    int tabWidth, tabHeight;            // Width, height of a tab
    int Gapx, Gapy;                     // Gap size around tabs (distance to window border)
    RECT ClientRect;                    // Dimension of available subdialog client area
    POINT TabPt;                        // Position of leftmost tab on front row

    HFONT hFontNormal;                  // Regular Tab Font
    HFONT hFontBold;                    // Selected Tab Font

    LPSTR lpszINIFile;                  // INI File Info to save last active tab
    LPSTR lpszSection;                  // INI Section

    LPSTR lpszItem[MAX_TABBED_ITEMS];   // Tab item strings
    BOOL itemStatus[MAX_TABBED_ITEMS];  // Tab item status
    UINT itemDialog[MAX_TABBED_ITEMS];  // Tab item dialog ids

    LPCSTR (FAR * lpalpResDialog)[MAX_TABBED_ITEMS];
                                        // Ptr to array of pre-loaded dialog resources (if any)
    // Temporaries

    HPEN hPenWhite;                     // GDI objects available during WM_PAINT only
    HPEN hPenBlack;
    HPEN hPenDkGray;
    HBRUSH hbrBk;

} DLGDATA, FAR * PDLGDATA, FAR * LPDLGDATA;

// The following structure is passed to WM_INITDIALOG (in lParam)    
// 

typedef struct tagPassParm {
    HINSTANCE hinst;                    // Caller's instance handle
    HWND hwndOwner;                     // Window owning the tabbed dialog
    int activeItem;                     // Desired active tab entry
    TABBEDDLGPROC lpfnCallback;         // Caller's subdialog callback procedure
    LPARAM lParam;                      // Caller's User Data
    LPCSTR lpResTabInfo;                // Tab Info Resource
    LPCSTR (FAR * lpalpResDialog)[MAX_TABBED_ITEMS];
                                        // Ptr to array of loaded dialog resources
    
    BOOL fModal;                        // TRUE if this is a modal dialog
} PASSPARM, NEAR * PPASSPARM, FAR * LPPASSPARM;
#pragma pack()                          // default packing 

// Message handlers used from C++ CTabDlg.CPP

BOOL _export WINAPI DlgTabbed_OnInitDialogEx(PDLGDATA pDlg, HWND hwndFocus, LPARAM lParam);
void _export WINAPI DlgTabbed_OnDestroyEx(PDLGDATA pDlg);
void _export WINAPI DlgTabbed_OnEnableEx(PDLGDATA pDlg, BOOL fEnable);
void _export WINAPI DlgTabbed_OnPaintEx(PDLGDATA pDlg, LPPAINTSTRUCT lpps);
BOOL _export WINAPI DlgTabbed_OnEraseBkgndEx(PDLGDATA pDlg, HDC hdc);
void _export WINAPI DlgTabbed_OnNCDestroyEx(PDLGDATA pDlg);
DWORD _export WINAPI DlgTabbedDef_OnMenuCharEx(PDLGDATA pDlg, UINT ch, UINT flags, HMENU hmenu);
void _export WINAPI DlgTabbedDef_OnLButtonDownEx(PDLGDATA pDlg, BOOL fDoubleClick, int x, int y, UINT keyFlags);
PDLGDATA _export WINAPI DlgTabbed_AllocInstanceData(void);
void _export WINAPI DlgTabbed_FreeInstanceData(PDLGDATA pDlg);

PDLGDATA _export WINAPI DlgTabbed_GetInstanceData(HWND hwndDlg);// C only, Undocumented Function

LPVOID _export WINAPI FindLoadAndLockResource(HINSTANCE hinst, LPCSTR lpszName, LPCSTR lpszType, BOOL fMsgIfNotFound);
void _export WINAPI FreeLockedResource(LPCSTR lpsz);

#ifdef __cplusplus
}
#endif

#endif  /* _INC_SFTTABS2 */
