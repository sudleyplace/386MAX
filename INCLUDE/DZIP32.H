// $Header:   P:/PVCS/MAX/INCLUDE/DZIP32.H_V   1.1   28 May 1996 16:10:48   HENRY  $
// Copyright (c) 1993 Inner Media, Inc., All Rights Reserved
// Include file for using DZIP.DLL

#undef GLOBAL

#ifdef _DZIP_OWNER
#define	GLOBAL
#else
#define	GLOBAL extern
#endif

#pragma pack(2)

#ifndef ZIPSTRUCT
#define ZIPSTRUCT
typedef struct { 
  int zipStructSize;
  int function;
  LPSTR lpszZIPFile;
  LPSTR lpszItemList;
  FARPROC lpMajorStatus;
  void FAR * lpMajorUserData;
  FARPROC lpMinorStatus;
  void FAR * lpMinorUserData;
  BOOL dosifyFlag;
  BOOL recurseFlag;
  int compFactor;
  BOOL quietFlag;
  BOOL pathForTempFlag;
  LPSTR lpszTempPath;
  BOOL fixFlag;
  BOOL fixHarderFlag;
  BOOL includeVolumeFlag;
  BOOL deleteOriginalFlag;
  BOOL growExistingFlag;
  BOOL noDirectoryNamesFlag;
  BOOL convertLFtoCRLFFlag;
  BOOL addCommentFlag;
  LPSTR lpszComment;
  BOOL afterDateFlag;
  LPSTR lpszDate;
  BOOL oldAsLatestFlag;
  BOOL includeOnlyFollowingFlag;
  LPSTR lpszIncludeFollowing;
  BOOL excludeFollowingFlag;
  LPSTR lpszExcludeFollowing;
  BOOL noDirectoryEntriesFlag;
  BOOL includeSysHiddenFlag;
  BOOL dontCompressTheseSuffixesFlag;
  LPSTR lpszStoreSuffixes;    
  BOOL bDiagnostic;
  BOOL encryptFlag;
  LPSTR lpszEncryptCode;
  // added for rev 2.0
  FARPROC lpMessageDisplay;
  void FAR * lpMessageDisplayData;
  WORD wMultiVolControl;
  WORD wZipSubOptions;
  // added for rev 3.0
  long lResv1;
  long lResv2;
  FARPROC lpRenameProc;
  void FAR *lpRenameUserData;
  LPSTR lpszExtProgTitle;
  void FAR *lpMemBlock;
  long lMemBlockSize;
}ZIPCMDSTRUCT;
#endif

#ifndef DZR
#define DZR
typedef struct DZRENAME_tag{
  char Name[260];
  int  Date;
  int  Time;
  long Attr;
  char OrigName[260];
}DZRENAME;
#endif

// Multi-Volume Control FLAG definitions
#ifndef MV_CONTROL_FLAGS
#define MV_CONTROL_FLAGS

#define MV_FORMAT         0x0001
#define MV_LOWDENSE       0x0002

#define MV_WIPE           0x0100
#define MV_SUBDIR         0x0200
#define MV_SYSHIDE        0x0400

#define MV_CDFIRST        0x1000
#define MV_USEMULTI       0x8000  
#endif

// defines for bits in wZipSubOptions member
#define ZSO_RELATIVEPATHFLAG   0x0001
#define ZSO_MINORCANCEL        0x0002
#define ZSO_EXTERNALPROG       0x0004
#define ZSO_EXTPROGCANCEL      0x0008
#define ZSO_IGNORELONGNAMES    0x0010
#define ZSO_MANGLELONGNAMES    0x0020
#define ZSO_SKIPLOCKEDFILES    0x0040


// message callback defines
#ifndef MESSAGE_IDS
#define MESSAGE_IDS

#define MSGID_DISK             0 
#define MSGID_DISKOFDISK       1
#define MSGID_ZOPEN            2
#define MSGID_ZREAD            3
#define MSGID_ZWRITE           4
#define MSGID_NOREMOVE         5
#define MSGID_SAMEVOL          6
#define MSGID_ZFORMAT          7
#define MSGID_OVERWRT          8
#define MSGID_CODEERR          9
#define MSGID_MVBADFIRSTDISK  10
#define MSGID_ERROR           11
#define MSGID_WARN            12
#define MSGID_CHANGE          13
#endif


#ifndef VBZIPBLOCKSTRUCT
#define VBZIPBLOCKSTRUCT
typedef struct {
  char szZIPFile[260];
  char szItemList[5120];
  char szTempPath[260];
  char szComment[2048];
  char szDate[7];
  char szIncludeFollowing[2048];
  char szExcludeFollowing[2048];
  char szStoreSuffixes[1024];
  char szEncryptCode[66];
  // Added for Rev 3.00
  char szExtProgTitle[260];
}VBDZIPBLOCK;
#endif

#ifndef VBSTATUSBLOCK
#define VBSTATUSBLOCK
typedef struct {
  HANDLE hMinorStat;
  HANDLE hMajorStat;
  // added for rev 2.00
  HANDLE hResv1;
  HANDLE hResv2;
}VBSTATBLK;

// status window messages
#define WM_SETSTATUSBASEMSG     WM_USER+28
#define WM_GETSTATUSBASEMSG     WM_USER+29
#define WM_SETSTATUSPERCENT     WM_USER+30
#define WM_GETSTATUSPERCENT     WM_USER+31
#define WM_SHOWSTATUSWINDOW     WM_USER+32
#define WM_HIDESTATUSWINDOW     WM_USER+33
#define WM_GETCONTROLDATA       WM_USER+34
#define WM_SETCONTROLDATA       WM_USER+35
#define WM_GETCANCELFLAG        WM_USER+36
#define WM_SETCANCELFLAG        WM_USER+37

// status window misc defines
//ControlData bit mask definition
// Bit  00 - Allow Bkgnd Processing    1 = allow bkgnd process / 0 = No bkgnd process allowed
// Bit  01 - Allow Cancel              1 = allow Cancel        / 0 = No Cancel allowed
// Bits 02 - 15                        reserved and undefined
//
#define CONTROLDATA_BKGNDPROC   0x01
#define CONTROLDATA_CANCEL      0x02
#define CONTROLDATA_MASK        0x03        

// Status Window FRAME extra words
#define WW_STATPERCENT          0
#define WW_STATPERCENT_OLD      2

#define STATUS_EXTRAS           4

#endif

// the "function"s that are supported
#define ZIP_FRESHEN   1
#define ZIP_DELETE    2
#define ZIP_UPDATE    3
#define ZIP_ADD       4
#define ZIP_MEMTOFILE 5

#ifdef __cplusplus
extern "C" {
#endif

//Function Prototype
int FAR PASCAL dzip(ZIPCMDSTRUCT FAR *zcs);
void FAR PASCAL setZipExternalCancel(BOOL bExtCancel);
BOOL FAR PASCAL getZipExternalCancel(void);

#ifdef __cplusplus
}
#endif

/* Error return values.  The values 0..4 and 12..18 follow the conventions
   of PKZIP.   The values 4..10 are all assigned to "insufficient memory"
   by PKZIP, so the codes 5..10 are used here for other purposes. */
#define ZE_OK           0       // success
#define ZE_BUSY         1       // can't reenter
#define ZE_EOF          2       // unexpected end of zip file
#define ZE_FORM         3       // zip file structure error
#define ZE_MEM          4       // out of memory
#define ZE_LOGIC        5       // internal logic error
#define ZE_BIG          6       // entry too large to split
#define ZE_NOTE         7       // invalid comment format
#define ZE_TEST         8       // zip test (-T) failed or out of memory
#define ZE_ABORT        9       // user cancelled
#define ZE_TEMP         10      // error using a temp file
#define ZE_READ         11      // read or seek error
#define ZE_NONE         12      // nothing to do
#define ZE_NAME         13      // missing or empty zip file
#define ZE_WRITE        14      // error writing to a file
#define ZE_CREAT        15      // couldn't open to write
#define ZE_PARMS        16      // bad control parameters
#define ZE_INCOMPLETE   17      // could not complete operation
#define ZE_OPEN         18      // could not open a specified file to read
#define ZE_MEDIA        19      // media error... disk not ready, HW r/w error, etc.
#define ZE_MVPARMS      20      // bad Multi-Volume control parameters
#define ZE_MVUSAGE      21      // Improper usage of a Multi-Volume Zip File

#ifndef ZIPERRORSTRINGS
#define ZIPERRORSTRINGS

/* Error message equivalences for dzip.dll */
GLOBAL char *ZIPerrors[]
#ifdef _DZIP_OWNER
 = {
/*  0 */  "",
/*  1 */  "Busy, can't enter now",
/*  2 */  "Unexpected end of zip file",
/*  3 */  "Zip file structure invalid",
/*  4 */  "Out of memory",
/*  5 */  "Internal logic error",
/*  6 */  "Entry too big to split",
/*  7 */  "Invalid comment format",
/*  8 */  "Zip file invalid or insufficient memory",
/*  9 */  "Application cancelled operation",
/* 10 */  "Temporary file failure",
/* 11 */  "Input file read failure",
/* 12 */  "Nothing to do!",
/* 13 */  "Missing or empty zip file",
/* 14 */  "Output file write failure, possible disk full",
/* 15 */  "Could not create output file",
/* 16 */  "Invalid combination of control parameters",
/* 17 */  "Could not complete operation",
/* 18 */  "File not found or no read permission",
/* 19 */  "Media Error Encountered",
/* 20 */  "Invalid combination of Multi-Volume control parameters",
/* 21 */  "Improper use of Multi-Volume Zip file",
}
#endif
;

#endif

#pragma pack()
