#include "windows.h"
#include "drivinit.h"
#include "resource.h"
#include <ctl3d.h>

#ifndef CDECL
#define CDECL cdecl
#endif

#define WINDOWMENU  3	/* position of window menu		 */

#define DEFFILESEARCH	(LPSTR) "*.INI"

#ifdef RC_INVOKED
#define ID(id) id
#else
#define ID(id) MAKEINTRESOURCE(id)
#endif

/* edit control identifier */
#define ID_EDIT 0xCAC

/* resource ID's */
#define IDMAXEDIT     ID(1)
#define IDCHILDICO    ID(2)

/* Window word values for child windows */
#define GWW_HWNDEDIT	0
#define GWW_CHANGED	2
#define GWW_WORDWRAP	4
#define GWW_UNTITLED	6
#define GWW_EDITPTR	8
#define CBWNDEXTRA	12

/* menu ID's */
#define IDM_EDITFIRST	IDM_EDITUNDO
#define IDM_EDITLAST	IDM_EDITSELECT
#define IDM_SEARCHFIRST IDM_SEARCHFIND
#define IDM_SEARCHLAST	IDM_SEARCHPREV

/* dialog ids */
#define IDD_FILEOPEN	ID(200)
#define IDD_ABOUT	ID(300)
#define IDD_FIND	ID(400)
#define IDD_SAVEAS	ID(500)
#define IDD_PRINT	ID(600)
#define IDD_FONT	ID(700)
#define IDD_NEXT	IDOK

/* attribute flags for DlgDirList */
#define ATTR_DIRS	0xC010		/* find drives and directories */
#define ATTR_FILES	0x0000		/* find ordinary files	       */
#define PROP_FILENAME	szPropertyName	/* name of property for dialog */


// Toolbar defines
    #define ONE_UNIT		  nOneUnit
    #define BUTTON_HEIGHT	  wIconHeight/2
    #define BUTTON_WIDTH	  wIconWidth
    #define BUTTON_BORDER	  ONE_UNIT * 2

//    #define BUTTONBAR_OFFSET	    (wIconWidth*2)
#define BUTTONBAR_OFFSET      8
    #define SPACE_BETWEEN_BUTTONS ONE_UNIT*4
    #define TOOLBAR_BORDER	  ONE_UNIT*2
    #define TOOLBAR_HEIGHT	  BUTTON_HEIGHT + TOOLBAR_BORDER * 2 + BUTTON_BORDER * 2 + 1
    #define NUMTOOLS		  13

    // hIcon is the bitmap that will represent the button
    // The command ID is the command that will be generated if the
    // button is clicked.
    // the x,y,dx and dy are the cordinates and the extents of the
    // buttons that are used in hit testing and in drawing
    typedef struct tagTOOL
    {
	HICON	  hIcon;
	WORD	  CommandID;
	WORD	  x, y, dx, dy;
    }TOOL;


/*
 *  External variable declarations
 */
extern HANDLE hInst;		/* application instance handle		  */
extern HANDLE hAccel;		/* resource handle of accelerators	  */
extern HWND hwndFrame;		/* main window handle			  */
extern HWND hwndMDIClient;	/* handle of MDI Client window		  */
extern HWND hwndActive; 	/* handle of current active MDI child	  */
extern HWND hwndActiveEdit;	/* handle of edit control in active child */
extern char szChild[];		/* class of child			  */
extern char szSearch[]; 	/* search string			  */
extern BOOL fCase;		/* searches case sensitive		  */

extern WORD wIconHeight, wIconWidth;
extern int nOneUnit;

/*  externally declared functions
 */
extern BOOL PASCAL InitializeApplication(VOID);
extern BOOL PASCAL InitializeInstance(LPSTR,WORD);
extern BOOL CALLBACK __export AboutDlgProc( HWND, UINT, WPARAM, LPARAM );
extern HWND PASCAL AddFile(char *);
extern VOID PASCAL ReadFile(HWND);
extern VOID PASCAL SaveFile(HWND);
extern BOOL PASCAL ChangeFile(HWND);
extern int PASCAL LoadFile(HWND, char *);
extern VOID PASCAL PrintFile(HWND);
extern BOOL PASCAL GetInitializationData(HWND);
extern short CDECL MPError(HWND,WORD,WORD,...);
extern VOID PASCAL Find(void);
extern VOID PASCAL FindNext(void);
extern VOID PASCAL FindPrev(void);
extern VOID PASCAL MPSpotHelp(HWND,POINT);
extern LONG FAR PASCAL __export MPFrameWndProc(HWND,UINT,WPARAM,LPARAM);
extern LONG FAR PASCAL __export MPMDIChildWndProc(HWND,UINT,WPARAM,LPARAM);
extern HDC PASCAL GetPrinterDC(void);
extern VOID PASCAL SetSaveFrom (HWND, PSTR);
extern BOOL PASCAL RealSlowCompare (LPSTR, LPSTR);
extern VOID PASCAL FindPrev (void);
extern VOID PASCAL FindNext (void);
extern BOOL PASCAL IsWild (PSTR);
extern VOID PASCAL SelectFile (HWND);
extern VOID PASCAL MyFindText ( int );

void BuildTools( void );
void DestroyTools( void );
extern LONG FAR PASCAL __export ControlBarWndProc(HWND,UINT,WPARAM,LPARAM);

