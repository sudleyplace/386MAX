/* qpifedit.h - (C) Copyright 1992-93 Qualitas, Inc.  GNU General Public License version 3. */

#include <commdlg.h>
#include <cderr.h>

#include <pif.h>		// .PIF structure
#include <qpe.h>		// .QPE structure

#define APPNAME 	"QPIFEDIT"
#define PROFILE 	"QPIFEDIT.INI"

#ifdef LANG_GR
#define APPTITLE	"Qualitas PIF Editor"
#define APPTITLETHE	"Der Qualitas PIF Editor"
#else
#define APPTITLE	"Qualitas PIF Editor"
#define APPTITLETHE	"The Qualitas PIF Editor"
#endif				/* IFDEF LANG_GR */

#ifdef LANG_GR
#define COMMDLGFAIL_STR "COMMDLG.DLL Fehler"
#define NONE_STR	"Ohne"
#define HOTKEY_STR	"Hotkey"
#define BADHOTKEY_STR	"Hotkey Kombination ist ungültig"
#define CANTREAD_STR	"Kann .PIF nicht lesen\r\n"
#else
#define COMMDLGFAIL_STR "COMMDLG.DLL failure"
#define NONE_STR	"None"
#define HOTKEY_STR	"Hotkey"
#define BADHOTKEY_STR	"Hotkey combination is invalid"
#define CANTREAD_STR	"Can't read .PIF\r\n"
#endif				/* #IFDEF LANG_GR */

    // help keys. These must match topics in Help file.
#ifdef LANG_GR
#define HK_OVERVIEW	"Qualitas PIF-Editor - Überblick"
#define HK_TECHS	"Kundendienst in Deutschland"
#else
#define HK_OVERVIEW	"Qualitas PIF editor overview"
#define HK_TECHS	"Technical support"
#endif				/* #IFDEF LANG_GR */

VOID	FAR cdecl DebugPrintf(LPSTR szFormat, ...);
VOID	FAR cdecl MessageBoxPrintf(LPSTR szFormat, ...);

VOID	StandardModeBitchBox(HWND hWnd);

BOOL	CALLBACK _export SMMsgProc(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);

#define IDD_STANDARD	107		// Standard mode bitch dialog
#define IDB_EXPERT	108		// Don't remind me again

#define IDI_QIF 	100		// App's icon
#define IDI_DOSMAX	101		// DOSMAX icon

// Menu resource IDs

#define IDM_F_NEW		1100	// File.New
#define IDM_F_OPEN		1200	// File.Open
#define IDM_F_SAVE		1300	// File.Save
#define IDM_F_SAVEAS		1400	// File.SaveAs
#define IDM_F_EXIT		1500	// File.eXit

#define IDM_H_OVERVIEW		2100
#define IDM_H_SEARCH		2101
#define IDM_H_TECHSUP		2102
#define IDM_H_ABOUT		2103	// Help.About

// Dialog and control resource IDs

#define IDD_ABOUT	100	// HELP/ABOUT dialog
#define IDB_RUNPIF	119	// Run PIF to test settings
#define IDD_HELP	120	// Help window
#define IDD_FRAME	101	// Main frame dialog resource

#define IDB_GENERAL		102
#define IDB_MEMORY		103
#define IDB_VIDEO		104
#define IDB_TASK		105
#define IDB_OTHER		106

#define IDD_GENERAL	102		// 'General' dialog

#define IDT_FILENAME		200
#define IDE_FILENAME		201
#define IDT_TITLE		202
#define IDE_TITLE		203
#define IDT_PARAMS		204
#define IDE_PARAMS		205
#define IDT_DIRECTORY		206
#define IDE_DIRECTORY		207

#define IDD_MEMORY	103		// 'Memory' dialog

#define IDG_SUPERDOS		300
#define IDB_SUPERVM_DEF 	301
#define IDB_SUPERVM_ON		302
#define IDB_SUPERVM_OFF 	303
#define IDG_MEMOPTS		304
#define IDT_DOSMEM		305
#define IDT_DOSMIN		306
#define IDE_DOSMIN		307
#define IDT_DOSMAX		308
#define IDE_DOSMAX		309
#define IDT_EMSMEM		310
#define IDT_EMSMIN		311
#define IDE_EMSMIN		312
#define IDT_EMSMAX		313
#define IDE_EMSMAX		314
#define IDT_XMSMEM		315
#define IDT_XMSMIN		316
#define IDE_XMSMIN		317
#define IDT_XMSMAX		318
#define IDE_XMSMAX		319
#define IDB_DOSLOCK		320
#define IDB_EMSLOCK		321
#define IDB_XMSLOCK		322
#define IDB_XMSHMA		323

#define IDD_VIDEO	104		// 'Video' dialog

#define IDG_DISPLAY		400
#define IDB_FULLSCREEN		401
#define IDB_WINDOWED		402
#define IDG_VIDEOMEM		403
#define IDB_TEXT		404
#define IDB_LOW 		405
#define IDB_HIGH		406
#define IDG_MONITOR		407
#define IDB_MONTEXT		408
#define IDB_MONLOW		409
#define IDB_MONHIGH		410
#define IDG_OTHER		411
#define IDB_EMULATE		412
#define IDB_RETAIN		413

#define IDD_TASK	105		// 'Task' dialog

#define IDG_PRIORITY		500
#define IDT_BACKPRIO		501
#define IDE_BACKPRIO		502
#define IDT_FOREPRIO		503
#define IDE_FOREPRIO		504
#define IDG_EXEC		505
#define IDB_DETECTIDLE		506
#define IDB_BACKEXEC		507
#define IDB_EXCLEXEC		508

#define IDD_OTHER	106		// 'Other' dialog

#define IDG_SHORTCUT		600
#define IDB_ALT 		601
#define IDB_CTRL		602
#define IDB_SHIFT		603
#define IDT_KEY 		604
#define IDE_KEY 		605
#define IDG_RESERVE		606
#define IDB_ALTTAB		607
#define IDB_ALTESC		608
#define IDB_CTRLESC		609
#define IDB_PRTSC		610
#define IDB_ALTSPACE		611
#define IDB_ALTENTER		612
#define IDB_ALTPRTSC		613
#define IDG_OPTIONS		614
#define IDB_FASTPASTE		615
#define IDB_ALLOWCLOSE		616
#define IDB_CLOSEEXIT		617


/****************************************************************************
*									    *
*			      LOADSTRING CONSTANTS			    *
*									    *
****************************************************************************/

/* General strings */

#define IDS_APPNAME		3001
#define IDS_APPTITLE		3002
#define IDS_APPTITLETHE 	3003

#define IDS_REGISTER_CLASS	3028
#define IDS_CREATE_WINDOW	3029
#define IDS_NOT_BUILT		3030
#define IDS_MODE286		3031
#define IDS_REALMODE		3032	// QIF needs Standard or Enhanced mode
#define IDS_SAVECHANGES 	3033
#define IDS_UNTITLED		3034

#define IDS_FILEMASK		3035	// "PIF Files(*.PIF)\n*.pif\n\0"

#define IDS_CANTOPEN	48	// "Can't open %s"
#define IDS_NOTVALIDPIF 49	// "%s is not a valid .PIF file"
#define IDS_TOOBIG	50	// "File is too big to be a valid .PIF"
#define IDS_OLDPIF	51	// "This is an old Windows PIF", "OpenPIF"
#define IDS_BADCHECKSUM 53	// ".PIF internal structure ... be damaged"
#define IDS_NOTVALIDQPE 54	// "The Qualitas PIF Extension file, %s, associated with %s is invalid"

#define IDS_BADNUM	70	// "'%s' value must be between %d and %d"
#define IDS_BADNUM2	71	// "'%s' value must be -1, or between %d and %d"
#define IDS_FILENAMEREQ 72	// "The required program filename is missing."
#define IDS_BADFILENAME 73	// "The program filename is required. ...

#define IDS_COMMDLGERR	90	// "Problem using COMMDLG.DLL for OPEN or SAVE"
#define IDS_OUTOFMEMORY 91	// "Out of memory"
#define IDS_OUTOFMEMORY2 92	// "Out of memory"      Can't lock PIF
#define IDS_OUTOFMEMORY3 93	// "Out of memory"      Can't lock QPE
#define IDS_NOWIN95	 94	// "Not compatible with Win95"


#define EDITBORDER	5

