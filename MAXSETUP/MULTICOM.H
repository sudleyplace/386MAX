// $Header:   P:/PVCS/MAX/MAXSETUP/MULTICOM.H_V   1.1   26 Jan 1996 12:31:04   PETERJ  $
/****************************************************************
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.	*
 * MULTICOM.H								                        *
 * Definitions and structures used multi.h module	            *
 ****************************************************************/

#ifndef MULTI_INCLUDED
#define MULTI_INCLUDED

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

typedef struct _CfgText {
struct	_CfgText *prev, *next;
CFGID	ltype;		// Line type; see MBPARSE.H
BYTE	Owner;		// Line owner; matches OwnerID field in SECTNAME
char	*text;		// Original line from CONFIG.SYS
} CFGTEXT;

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


#define MAX_PRODNAME	"Qualitas MAX"  // Product name
#define MAX_PRODFILE	"386MAX"        // Product file name w/o extension
#define MAX_FILENAME	"386MAX.SYS"    // Filename to install in CONFIG.SYS
#define MAX_OLDNAME	"BlueMAX.SYS"   // Filename to install in CONFIG.SYS
#define MAX_PRODDIR	"QMAX"          // Initial choice for directory name
#define MAX_INIDIR	"C:\\" MAX_PRODDIR // Initial choice for destin dir
#define MAX_ARCATTR	1		// Attribute mask for archive extraction
#define MAX_README	"README"        // README file for 386Max
#define MAX_LOADBASE	"386LOAD"       // Basename for 386MAX loader

#define INSTALL_CFG	"SETUPDOS.CFG"  // Name of INSTALL.CFG
#define MAXIMIZE_CFG	"MAXIMIZE.CFG"  // Name of MAXIMIZE.CFG

// Maximum path and directory length
#define MAXPATH 	127	   // Maximum path length (allow for networks)
#define MAXDIR		MAXPATH-12 // defined in stdlib.h

#endif /* MULTI_INCLUDED*/

