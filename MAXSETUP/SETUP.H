/*
    SETUP.H
*/

#include <windows.h>
#include <ctl3d.h>

#include "implode.h"		// for PKZIP lib


// use the Windows Throw and Catch instead of longjmp/setjmp
#define longjmp		Throw
#define setjmp		Catch
#define jmp_buf		CATCHBUF

// general constants

// Bitmap id
#define LOGO    1               // resource id


//Dialog ID's
#define IDM_INSTALL	    1000
#define IDM_ABOUT           1001

#define SPLASHDLGBOX        100
#define SPLASH_BITMAP	    110
#define WELCOMEDLGBOX       120
#define REGISTERDLGBOX      130
#define CONFIRMDLGBOX       140
#define PREBRANDEDDLGBOX    150
#define MULTIDLGBOX         160
#define PARTSDLGBOX	        170
#define DIRECTORYDLGBOX     180
#define EXTRACTDLGBOX       190
#define CONFIGUREDLGBOX     200
#define FILESDLGBOX         210
#define SHOWDLGBOX          220
#define ASKQUITDLGBOX       230
#define EXITFAILUREDLGBOX   240
#define EXITQUITDLGBOX      250
#define EXITSUCCESSDLGBOX   260
#define EXITREBOOTDLGBOX    270
#define EXITRESTARTDLGBOX   275
#define EXITNEWDLGBOX       280
#define SOURCEDLGBOX        290
#define UPDATEDLGBOX        300
#define UPDATEERRORDLGBOX   310
#define MODELESSDLGBOX      320
#define REFSRCDLGBOX        330

#define IDC_SETUP	666

#define IDC_CONTINUE	101
#define IDC_BACK	102
#define IDC_EXIT	103
#define IDC_HELP	104
#define IDC_TEXT	105

#define IDC_NAME	201
#define IDC_COMPANY	202
#define IDC_SERIAL	203

#define IDC_MULTI	261

#define IDC_PROGRAMS	301
#define IDC_ONLINEHELP	302
#define IDC_DOSREADER	303
#define IDC_IDISK	304
#define IDC_DISKFREE    305
#define IDC_DISKNEEDED  306
#define IDC_PATH	310
#define IDC_BROWSE      311
#define IDC_METER	312

#define IDC_MDA		501
#define IDC_QMT		502
#define IDC_QMTMULTI	503
#define IDC_MAXMETER	504
#define IDC_GOAHEAD	505
#define IDC_EMS		506
#define IDC_CLEAN	507

#define IDC_FILESLB     601
#define IDC_UPDATEFILES 602
#define IDC_NEWFILES    603

#define IDC_DIF_FILE	610


// globals in SETUP.C

extern char *szAppName;

void SetupYield(int);
void CenterWindow(HWND);


// EXTRACT.C
void BackupMAX(void);
void RestoreMAX(void);


// MISC.C
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
char * ext_part(char *);
char * gcdir(char *);
int gcdisk(char *);
void mkdirname(char *, char *);
char * mkfname( char * );
int QueryFileExists( char * );
char * FindFile( int, char *, struct _find_t *, char * );


// externals in FILECOPY.C
extern int FileCopy(char *, char *);


// externals in SETUPDDE.C
extern unsigned int InitDDE(void);
extern void EndDDE(void);

extern BOOL FAR PASCAL pmQueryGroup( LPSTR, LPSTR );
extern BOOL FAR PASCAL pmCreateGroup(LPSTR, LPSTR);
extern BOOL FAR PASCAL pmDeleteGroup(LPSTR);
extern BOOL FAR PASCAL pmShowGroup(LPSTR, WORD);
extern BOOL FAR PASCAL pmAddItem(LPSTR, LPSTR, LPSTR, int);
extern BOOL FAR PASCAL pmReplaceItem(LPSTR);
extern BOOL FAR PASCAL pmDeleteItem(LPSTR);


// SERIALNO.H
unsigned char weight_digit (char *);
unsigned char check_digit (char *);
unsigned char * encode_serialno (unsigned char *);
unsigned char * decode_serialno (unsigned char *);


// SETUPDIF.C
int Difference(char *, char *, char *);


// TRUENAME.H
char *truename_fn (char _far *, char _far *);
void truename (char *);
int truename_cmp (char *, char *);
void truedir (char *);

