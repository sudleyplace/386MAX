// $Header:   P:/PVCS/MAX/INCLUDE/DUNZIP32.H_V   1.0   16 Apr 1996 11:33:24   PETERJ  $
// Copyright (c) 1993 Inner Media, Inc., GNU General Public License version 3
// Function prototypes and structures for DynaZIP unzip DLL.

#ifdef _DUNZ_OWNER
#define	GLOBAL
#else
#define	GLOBAL extern
#endif

#pragma pack(2)

#ifndef ZINFO
#define ZINFO

#define ZIPINFO_DATETIME_SIZE    18
#define ZIPINFO_FNAME_SIZE      260

typedef struct {
  unsigned short index;
  unsigned long  oSize;
  unsigned long  cSize;
  unsigned short cMethod;
  unsigned short cOption;
  unsigned short cPathType;
  unsigned long crc_32;
  char szDateTime[ZIPINFO_DATETIME_SIZE];
  char szFileName[ZIPINFO_FNAME_SIZE];
  unsigned long attr;
  unsigned long  lziResv1;
  unsigned long  lziResv2;
} ZIPINFO;

typedef struct {
  unsigned long perc;
  char theString[352];
} STATINFO;

// attribute bit definitions
#define READONLY  0x00001L
#define HIDDEN    0x00002L
#define SYSTEM    0x00004L
#define VOLUME    0x00008L
#define SUBDIR    0x00010L
#define ARCHIVE   0x00020L
#define ENCRYPT   0x08000L
#define LFNAME    0x10000L

#endif
 
#ifndef UNZIPSTRUCT
#define UNZIPSTRUCT

typedef struct {
  int unzipStructSize;  
  int function;
  LPSTR lpszZIPFile;
  ZIPINFO FAR *zInfo;
  LPSTR lpszFilespec;
  int index;
  LPSTR lpszDestination;
  BOOL freshenFlag;
  BOOL updateFlag; 
  BOOL overWriteFlag;
  BOOL quietFlag;
  BOOL testFlag;
  BOOL noDirectoryNamesFlag;
  BOOL recurseFlag;
  BOOL noDirectoryItemsFlag;
  FARPROC lpMinorStatus;
  void FAR * lpMinorUserData;
  FARPROC lpMajorStatus;
  void FAR * lpMajorUserData;
  int returnCount;
  LPSTR lpszReturnString;
  BOOL bDiagnostic;
  BOOL bLF2CRLFFlag;
  BOOL  decryptFlag;
  LPSTR lpszDecryptCode;
  // added for rev 2.00
  FARPROC lpMessageDisplay;
  void FAR * lpMessageDisplayData;
  WORD wUnzipSubOptions;
  // added for rev 3.00
  long lResv1;
  long lResv2;
  FARPROC lpRenameProc;
  void FAR * lpRenameUserData;
  LPSTR lpszExtProgTitle;
  void FAR * lpMemBlock;
  long lMemBlockSize;
  long lStartingOffset;

}UNZIPCMDSTRUCT;
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

#ifndef VBUNZIPBLOCKSTRUCT
#define VBUNZIPBLOCKSTRUCT
typedef struct{
  char szZIPFile[260];
  char szFileSpec[5120];
  char szDestination[260];
  char szReturnString[2048];
  char szDecryptCode[66];
  // New for Rev 3.00
  char szExtProgTitle[260];
}VBDUNZIPBLOCK;
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

// Flag Bits for Unzip Sub Options
#define USO_OVERWRITE_RO    0x0001
#define USO_MINORCANCEL     0x0002
#define USO_EXTERNALPROG    0x0004
#define USO_EXTPROGCANCEL   0x0008
#define USO_IGNORELONGNAMES 0x0010
#define USO_MANGLELONGNAMES 0x0020

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

// used by calls to external progress monitor 
#define MAJORSTAT               0
#define MINORSTAT               1

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
#define UNZIP_COUNTALLZIPMEMBERS 1
#define UNZIP_GETNEXTZIPINFO 2
#define UNZIP_COUNTNAMEDZIPMEMBERS 3
#define UNZIP_GETNEXTNAMEDZIPINFO 4
#define UNZIP_GETCOMMENTSIZE 5
#define UNZIP_GETCOMMENT 6
#define UNZIP_GETINDEXEDZIPINFO 7
#define UNZIP_EXTRACT 8 
#define UNZIP_FILETOMEM 9

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

#ifdef __cplusplus
extern "C" {
#endif

int FAR PASCAL dunzip(UNZIPCMDSTRUCT FAR * ucs);
void FAR PASCAL setUnzipExternalCancel(BOOL bExtCancel);
BOOL FAR PASCAL getUnzipExternalCancel(void);

#ifdef __cplusplus
}
#endif

#define UE_OK           0       // success
#define UE_EOF          2       // unexpected end of zip file
#define UE_STRUCT       3       // structure error in zip file
#define UE_MEM1         4       // out of memory
#define UE_MEM2         5       // out of memory
#define UE_NOFILE       9       // file not found error
#define UE_BORED        11      // nothing to do 
#define UE_SAMEVOL      12      // same volume for src and dest not allowed for multi-volume
#define UE_INDEX        25      // index out of bounds
#define UE_OUTPUT       28      // error creating output file
#define UE_OPEN         29      // error opening output file
#define UE_BADCRC       39      // crc error
#define UE_ABORT        40      // application cancelled operation
#define UE_ENCRYPT      41      // file skipped, encrypted
#define UE_UNKNOWN      42      // unknown compression method
#define UE_BADKEY       44      // bad or missing decrypt code
#define UE_BUSY         45      // re-entry not permitted
#define UE_NOVOL        46      // can't unzip a volume item
#define UE_CMDERR       47      // bad command structure
#define UE_CANCEL       48      // user cancelled this operation
#define UE_SKIP         49      // user skipped this operation
#define UE_DISKFULL     50      // disk full

// Message Callback Return Codes not part of standard Windows Message Box
#define IDYESTOALL        100
#define IDRENAME          101
#define MB_YESNOCANCELYTA 0x000F

#ifndef UNZIPERRORSTRINGS
#define UNZIPERRORSTRINGS

/* Error message equivalences for dunzip.dll */
GLOBAL char *UNZIPerrors[]
#ifdef _DUNZ_OWNER
 = {
/*  0 */  "",
/*  1 */  "",
/*  2 */  "Unexpected end of zip file",
/*  3 */  "Zip file structure invalid",
/*  4 */  "Out of memory",
/*  5 */  "Out of memory",
/*  6 */  "",
/*  7 */  "",
/*  8 */  "",
/*  9 */  "File not found",
/* 10 */  "",
/* 11 */  "No files to test, extract, etc.",
/* 12 */  "The same disk volume can not be used as both the source and destination",
/* 13 */  "",
/* 14 */  "",
/* 15 */  "",
/* 16 */  "",
/* 17 */  "",
/* 18 */  "",
/* 19 */  "",
/* 20 */  "",
/* 21 */  "",
/* 22 */  "",
/* 23 */  "",
/* 24 */  "",
/* 25 */  "Index out of bounds",
/* 26 */  "",
/* 27 */  "",
/* 28 */  "Error creating output file",
/* 29 */  "Error opening archive",
/* 30 */  "",
/* 31 */  "",
/* 32 */  "",
/* 33 */  "",
/* 34 */  "",
/* 35 */  "",
/* 36 */  "",
/* 37 */  "",
/* 38 */  "",
/* 39 */  "Bad CRC",
/* 40 */  "Application cancelled operation",
/* 41 */  "File skipped, encrypted",
/* 42 */  "File skipped, unknown compression method",
/* 43 */  "",
/* 44 */  "Bad or missing decrypt code",
/* 45 */  "Busy, can't enter now",
/* 46 */  "Can't extract a Volume ID item",
/* 47 */  "Command syntax error",
/* 48 */  "Operation cancelled",
/* 49 */  "Operation skipped",
/* 50 */  "Disk full"
}
#endif
;

#endif

#pragma pack()
