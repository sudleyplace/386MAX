/*' $Header:   P:/PVCS/MAX/INSTALL/COMMON.H_V   1.5   02 Jan 1996 17:45:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * COMMON.H								      *
 *									      *
 * Definitions and structures commonly used by INSTALL.EXE modules	      *
 *									      *
 ******************************************************************************/

#ifndef COMMON_INCLUDED
#define COMMON_INCLUDED

#include "commdef.h"
#include "mbparse.h"

#include "compile.h"

struct	_FILESTRUC {
char	 *fname;	// File name pointer
char	 *ptr;		// Pointer to contents of file in RAM
int	 fhandle;	// Open file handle
WORD	 fseg,	       // Segment pointer to file buffer
	 flen,		// Length of file buffer
	 date,		// File date
	 time;		// File time
};
typedef struct _FILESTRUC FILESTRUC;

struct _DRVHDR_STR {
  unsigned long
      nxthdr;		/* Pointer to next device header */
  unsigned int
      attr,			/* Driver attributes */
      dev_str,		/* Offset to device strategy routine */
      dev_int;		/*		    interrupt */
  char
      name[8];		/* Device name */
};
typedef  struct _DRVHDR_STR DRVHDR_STR;

struct _EXEHDR_STR {
WORD exe_sign, // Signature == 'MZ'
     exe_r512, // Image size/512 remainder
     exe_q512, // Image size/512 quotient
     exe_nrel, // # relocation table items
     exe_hsiz, // Size of header in paras
     exe_min,  // Minimum # paras needed beyond image
     exe_max,  // Maximum ...
     exe_ss,   // Initial SS in paras
     exe_sp,   // Initial SP
     exe_chk,  // Checksum
     exe_ip,   // Initial IP
     exe_cs,   // Initial CS in paras
     exe_irel, // Offset to first relocation table item
     exe_ovrl; // Overlay #
};
typedef  struct _EXEHDR_STR EXEHDR_STR;

struct	_FREEROM {
WORD	strt_blk,      /* Starting 4KB block in paragraphs for USE= statement */
	end_blk;       /* Ending 4KB ...... */
};
typedef struct _FREEROM FREEROM;

typedef struct _CfgText {
struct	_CfgText *prev, *next;
CFGID	ltype;		// Line type; see MBPARSE.H
BYTE	Owner;		// Line owner; matches OwnerID field in SECTNAME
char	*text;		// Original line from CONFIG.SYS
} CFGTEXT;

typedef struct _ProText {
struct	_ProText *prev, *next;
BYTE	Owner;		// Line owner; matches OwnerID field in SECTNAME
char	*keyword;	// Keyword: "RAM", "USE", etc.
char	*text;		// Original line from CONFIG.SYS or profile
} PROTEXT;

typedef struct tagLineDelta {
	struct tagLineDelta *pNext; // Next set of changes in list or NULL==end
	char	*pszMatch;	// Line to match
	char	*pszReplace;	// What to replace with, or NULL to delete
	DWORD	dLine;		// File offset of start of line
} LINEDELTA;

typedef struct tagFileDelta {
	struct tagFileDelta *pNext; // Next file in list or NULL for end
	char	*pszPath;	// Complete pathname (not truename'd)
	char	*pszOutput;	// *.add - if not NULL, we've made changes
	char	*pszDiff;	// *.dif
	char	*pszBackup;	// *.001
	int	Index;		// Used in do_configsysn()
	int	cChanges;	// Number of lines changed
	LINEDELTA *pLines;	// Start of LINEDELTA list or NULL if empty
	BYTE	swap1, swap2;	// Alternate drives to swap to
} FILEDELTA;

#define STACKER 	// Enable compressed drive support

#define     PROGNAME	"SETUP"         // Windows Program name
#define     DOSNAME	"SETUPDOS"      // DOS Program name
#define     OEM_INST	"SETUP.EXE"     // Windows Installation program
#define     OEM_INSTOVL "SETUPDOS.OVL"  // DOS Installation program

/// #if !REDUIT
#define MAX_PRODNAME	"Qualitas MAX"  // Product name
#define MAX_PRODFILE	"386MAX"        // Product file name w/o extension
#define MAX_FILENAME	"386MAX.SYS"    // Filename to install in CONFIG.SYS
#define MAX_OLDNAME	"BlueMAX.SYS"   // Filename to install in CONFIG.SYS
#define MAX_PRODDIR	"QMAX"          // Initial choice for directory name
#define MAX_INIDIR	"C:\\" MAX_PRODDIR // Initial choice for destin dir
#define MAX_ARCATTR	1		// Attribute mask for archive extraction
#define MAX_README	"README"        // README file for 386Max
/// #endif

/// #if REDUIT
/// #define MAX_PRODNAME    "BlueMAX"       // Product name
/// #define MAX_PRODFILE    "BLUEMAX"       // Product file name w/o extension
/// #define MAX_FILENAME    "BlueMAX.SYS"   // Filename to install in CONFIG.SYS
/// #define MAX_OLDNAME     "386MAX.SYS"    // Filename to install in CONFIG.SYS
/// #define MAX_PRODDIR     "BlueMAX"       // Initial choice for directory name
/// #define MAX_INIDIR	    "C:\\" MAX_PRODDIR // Initial choice for destin dir
/// #define MAX_ARCATTR     2		    // Attribute mask for archive extraction
/// #define MAX_README	    "README"        // README file for Bluemax
/// #endif

#define MAX_UTILCOM	"386UTIL.COM"   // Filename to be IDed by INSTALL
#define MAX_LOADBASE	"386LOAD"       // Basename for 386MAX loader
#define MAX_LOADCOM	MAX_LOADBASE ".COM" // Filename to be IDed by INSTALL
#define MAX_XLAT	"XLAT.COM"      // File to copy to split install dir
#define MAX_HARPO	"ExtraDOS"      // Groucho's brother
#define MAX_HARPO_EXE	MAX_HARPO ".max" // ...with extension

#define MAX_QSHELL	"MAX.EXE"       // Filename to be IDed by INSTALL
#define MAX_ASQ 	"ASQ.EXE"       // Filename to be IDed by INSTALL
#define MAX_MAXIMIZE	"MAXIMIZE.EXE"  // Filename to be IDed by INSTALL
#define MAX_SWAPNAME	MAX_PRODFILE ".swp" // Swapfile name

#define MOV_PRODNAME	"MOVE'EM"       // Product name
#define MOV_FILENAME	"MOVE'EM.MGR"   // Filename to install in CONFIG.SYS
#define MOV_OLDNAME	"MOVE'EM.MGR"   // Filename to install in CONFIG.SYS
#define MOV_MAXCOM	"MOVE'EM.COM"   // Filename to be IDed by INSTALL
#define MOV_OLDCOM	"MOVE'EM.COM"   // Filename to be IDed by INSTALL
#define MOV_LOADBASE	MOV_PRODNAME	// Basename for Move'EM loader
#define MOV_INIDIR	"C:\\MOVE'EM"   // Initial choice for destin dir
#define MOV_ARCATTR	4		// Attribute mask for archive extraction
#define MOV_README	"README"        // README file for Move'Em

// Other files to be copied from distribution disk
#define QLOGO_OVL "QLOGO.OVL"

// Other file-related defines
#define INIT_WINDIR "C:\\WINDOWS"
#define WIN_COMFLE  "WIN.COM"
#define RMOLDMAX    "RMOLDMAX"          // Batch file to remove backup
#define OLDMAX	    "OLDMAX"            // Backup directory name (+ .1, .2, etc)
#define OLDREADME   "README.EXE"        // Old README program to be moved out
#define QMT	    "QMT"               // Qualitas Memory Test
#define QMT_EXE     QMT ".exe"          // With .EXE extension
#define RAMEXAM     "RAMexam"           // Standalone QMT
#define QUTIL	    "QUTIL"             // Name of our batch file
#define QUTIL_BAT   QUTIL ".BAT"

#define YES	 1
#define NO	 0
#define SECURITY_CHK 2

#define INSTALL_CFG	"SETUPDOS.CFG"  // Name of INSTALL.CFG
#define MAXIMIZE_CFG	"MAXIMIZE.CFG"  // Name of MAXIMIZE.CFG

// 386Cache names
#define OLDQCACHE	"386Cache"      // Old QCACHE name
#define OLDQCACHE_EXE	OLDQCACHE ".exe"
#define OLDQCACHE_WIN	OLDQCACHE ".win"
#define QCACHE		"QCache"        // MAXCache
#define QCACHE_EXE	QCACHE ".exe"   // MAXCache.exe
#define QCACHE_WIN	QCACHE ".win"   // PCKWIN.SYS
#define QCACHE_WINF	QCACHE		// basename portion only
#define QCACHE_WINE	".win"          // extension only
#define QCACHE_BUF	"8"             // new BUFFERS= value
#define QCACHE_TST	QCACHE ".tst"   // Test file
#define QCACHE_MAX	2048		// Maximum argument for size (KB)
#define WINENHEXTCRITICAL 1288		// Minimum extended memory size for
			// which we'll install QCACHE and still have Windows
			// run with win/3
#define WINENHEXTMIN	1326		// Minimum extended memory for
					// algorithmic calculation of cache size
#define WINEXTDIV4FLOOR 322		// Floor for cache size with ...CRITICAL
					// (used to determine how far above
					// 256K we can go)

#define STRIPMGR	"STRIPMGR"      // Until we come up with something else

// Keyword definitions
#define AUTOBCF 	"AUTOBCF"
#define NODPMI		"NODPMI"
#define XBIOSHI 	"XBIOSHI"
#define NOWIN30 	"NOWIN30" // Windows 3.0 support not needed for 3.1
#define NOWIN3		"NOWIN3"  // Disable all Windows 3 support
#define SWAPFILE	"SWAPFILE"
#define VGASWAP 	"VGASWAP"
#if MOVEM
#define USE		"INCLUDE"
#define RAM		"EXCLUDE"
#else
#define USE		"USE"
#define RAM		"RAM"
#endif

#define USER_NAME_LEN	45
#define USER_COMPANY_LEN 45
#define USER_SERIAL_LEN 13

/* Arguments to reset_batch () */
#define BT_QCACHE	1	// Search for QCACHE or SMARTDRV
#define BT_QMT		2	// Search for QMT
#define BT_QUTIL	3	// Search for Call QUTIL
#define BT_PATH 	4	// Search for PATH

/* Test for a previous MAX version */
/* Note that the version appears as "6;03" in the info structure, and */
/* the ';' is a flag (openhigh/closehigh). */
#define ISPREVIOUS(s)	(s[0]<'7')

/* OEMPROD_xxx equates */
#define     OEMPROD_MAX    0	   // 386MAX
#define     OEMPROD_MOV    1	   // MOVE'EM

/* OEMSYS_xxx equates */
#define     OEMSYS_RET	    0	   // Retail system
#define     OEMSYS_OEM	    1	   // Any generic OEM
#define     OEMSYS_ILIM     2	   // INTEL Limulator
#define     OEMSYS_JET386   3	   // Orchid JET 386
#define     OEMSYS_HPRS     4	   // HP Vectra RS/16, /20, /25C, or QS/16S
#define     OEMSYS_AST386   5	   // AST Premium 386
#define     OEMSYS_3COM     6	   // 3COM software
#define     OEMSYS_GRID     7	   // GRiD Systems
#define     OEMSYS_QUAD386  8	   // Quadram 386XT
#define     OEMSYS_MIT	    9	   // Mitsubishi 386
#define     OEMSYS_SHS	   10	   // Sunnyhill Software
#define     OEMSYS_OLI	   11	   // Olivetti/AT&T
#define     OEMSYS_TOSH    12	   // Toshiba 5100
////////   //////////////  13	   // SoftBytes/386
#define     OEMSYS_CA	   14	   // CompuAdd
#define     OEMSYS_NEC	   15	   // NEC Home Electronics
#define     OEMSYS_ASEM    16	   // ASEM
#define     OEMSYS_DEC	   17	   // Digital Equipment Corp.
#define     OEMSYS_TANDY   18	   // Tandy 4000
#define     OEMSYS_LHY	   19	   // Lahey FORTRAN

#define     OEM_SYS	    OEMSYS_RET
#define     OEM_PROD	    OEMPROD_MAX
#define     OEM_CHKFILE     archive(1)	    // Check for presence on dist disk
#define     OEM_INIDRV	    "C"

#define     SYSADD_FLE	    "system.add"

// Constants & bit mapped flags for disk caches - DCACHE_* constants in DCACHE.H
//#define DCACHE_NONE	0	// No disk cache found
//#define DCACHE_SMARTDRV 1	// Smartdrv found
#define DCF_SD_EMS	0x0100	// Smartdrv /a option
#define DCF_SD_NOSIZE	0x0200	// No size options specified; use default (256)
#define DCF_SD_WIN	0x0400	// DEVICE=386Cache.Win found
#define DCF_SD_BUFF	0x0800	// Buffers=n statement replaced
#define DCF_SD_SETLEND	0x1000	// Second argument to SMARTDRV found; use it
				// to calculate amount to lend.
#define DCF_SD_DEFSIZE 256	// default size if no args is 256K

#define DCACHE_ANYCACHE 0x00ff	// Mask off all flags
#define DCACHE_ANYFLAGS 0xff00	// Isolate flags
// end of disk cache constants

// Bit mapped flags for VGAWARN
#define VW_SAFE 	0x01	// OK to recover MDA
#define VW_UNSAFE	0x02	// Unsafe to recover B000-B800
#define VW_RISKY	0x04	// Could recover B000-B800, but warn the user
#define VW_FORCED	0x08	// VW_SAFE or _UNSAFE forced by /S or /U
#define VW_NOSWAP	0x10	// USE=B000-B800 works, VGASWAP doesn't

// Maximum path and directory length
#define MAXPATH 	127	   // Maximum path length (allow for networks)
#define MAXDIR		MAXPATH-12 // defined in stdlib.h

// Flags for adjust_pfne
#define ADJ_PATH	0x0001
#define ADJ_FNAME	0x0002
#define ADJ_DRIVE	0x0004

#define  MAX_SPAWNARGS	8		// Maximum args for spawnv()

#endif /*COMMON_INCLUDED*/

