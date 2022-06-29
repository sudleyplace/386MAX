// $Header
//
// TOOLBOX Application
// Copyright (c) 1995  Rex Conn for Qualitas Inc.

#include <windows.h>
#include <ctl3d.h>
#include <toolhelp.h>

#include <sfttabs.h>			// Tabbed dialogs

#define MAXICON 		    500

#define IDC_MULTISECTION	     99

#define IDD_STARTUP		    100
#define IDC_QMT 		    101
#define IDC_EXTRADOS		    102
#define IDC_DOSMAX		    103
#define IDC_MAXRAM		    104
#define IDC_MAXMETER		    105
#define IDC_STACKS		    106

#define IDD_HIGHDOS		    200
#define IDC_MDA 		    201
#define IDC_VGASWAP		    202
#define IDC_ROMSEARCH		    203
#define IDC_UMBTEXT		    205
#define IDC_RAMTEXT		    206
#define IDC_RAMEDITSTART	    207
#define IDC_RAMTEXTTO		    208
#define IDC_RAMSCROLLSTART	    209
#define IDC_RAMEDITEND		    210
#define IDC_RAMSCROLLEND	    211
#define IDC_ADDRAM		    212
#define IDC_REMOVERAM		    213
#define IDC_RAMLIST		    214

#define IDD_DPMI		    300
#define IDC_DPMI		    301
#define IDC_DPMISWAP		    302
#define IDC_DPMISWAPFILETEXT	    303
#define IDC_DPMISWAPFILE	    304
#define IDC_DPMISWAPSIZETEXT	    305
#define IDC_DPMISWAPSIZE	    306
#define IDC_DPMISWAPKBTEXT	    307
#define IDC_EMS 		    308
#define IDC_EMSFRAMETEXT	    309
#define IDC_EMSFRAME		    310

#define IDD_UNINSTALL		    400
#define IDC_STRIPMMSECTION	    402
#define IDC_STRIPLHSECTION	    403
#define IDC_REMOVEMAX		    404
#define IDC_REMOVEINIENTRIES	    405
#define IDC_REMOVEINIFILE	    406
#define IDC_REMOVEMAXGROUP	    407
#define IDC_REMOVEMAXDIR	    408

#define IDD_BASEDIALOG		    600
#define IDC_STRIPMM		    601
#define IDC_STRIPLH		    602
#define IDHELP			    603

#define IDC_CONTINUE		800
#define IDC_EXIT		801

#define EXITMAXIMIZEDLGBOX	700
#define EXITREBOOTDLGBOX	701
#define EXITRESTARTDLGBOX	702
#define MODELESSDLGBOX		703

#define CONFLICTDLGBOX		750
#define IDC_CONFLICT1		751
#define IDC_CONFLICT2		752

#define ABOUTDLGBOX		800

#define IDM_HELP		900
#define IDM_HELPSEARCH		901
#define IDM_HELPTS		902
#define IDM_ABOUT		903


#define DEL_SUBDIRS 0x1
#define DEL_RMDIR 0x02

#define MODE_FILE    0x7
#define MODE_SUBDIRS 0x17

typedef struct
{
	char szSource[80];
	char szTarget[80];
	char *pszFilename;
	unsigned int fFlags;
} DEL_STRUCT;

// MISC.C
int FileCopy(char *, char *);
void _fastcall FreeMem(char _far *);
char _far *AllocMem(unsigned int *);
char _far *ReallocMem(char _far *, unsigned long);
void MakePath(char *, char *, char *);
unsigned long freeKB(char *);
int GetLine( HFILE, char *, int );
void strip_leading( char *arg, char * );
void strip_trailing( char *, char * );
int FindString(char *, char *);
char * strins( char *, char *);
char * ntharg(char *, int);
char * scan(char *, char *);
char * path_part(char *);
char * fname_part(char *);
char * gcdir(char *);
int gcdisk(char *);
void mkdirname(char *, char *);
char * mkfname( char * );
int QueryFileExists(char *);
char * FindFile( int, char *, int, struct _find_t *, char * );
int del(char *);
int del_cmd(char *);
static int _del(DEL_STRUCT *);

// SETUPDDE.C
extern unsigned int InitDDE(void);
extern void EndDDE(void);
extern BOOL pmQueryGroup( LPSTR, LPSTR );
extern BOOL pmCreateGroup(LPSTR, LPSTR);
extern BOOL pmDeleteGroup(LPSTR);
extern BOOL pmShowGroup(LPSTR, WORD);
extern BOOL pmAddItem(LPSTR, LPSTR, int);
extern BOOL pmDeleteItem(LPSTR);
extern BOOL pmReplaceItem(LPSTR);
extern BOOL pmReload(LPSTR);
extern BOOL pmExit(BOOL);

