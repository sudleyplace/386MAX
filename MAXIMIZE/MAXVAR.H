/*' $Header:   P:/PVCS/MAX/MAXIMIZE/MAXVAR.H_V   1.4   23 Jan 1996 14:56:54   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MAXVAR.H								      *
 *									      *
 * Global variables for MAXIMIZE					      *
 *									      *
 ******************************************************************************/

#ifndef MAXVAR_INCLUDED
#define MAXVAR_INCLUDED

#include <commdef.h>		/* Common (shared) definitions */
#include <libtext.h>		/* Path terminators and localization data */
#include <max_sys.h>		/* MAXIMIZE version controls */
#include <maxtext.h>		/* MAXIMIZE text */
#include <qualitas.h>		/* Qualitas product-specific defines */

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

#define SCRWIDTH 80
#define SCRHEIGHT 25

typedef struct _CfgFlags {
  WORD	novgaswap:1,		/* NOVGASWAP specified in MAXIMIZE.CFG */
	noromsrch:1,		/* NOROMSRCH specified in MAXIMIZE.CFG */
	noharpo:1,		/* NOHARPO specified in MAXIMIZE.CFG */
	noexpand:1,		/* NOEXPAND specified in MAXIMIZE.CFG */
	drdos:1,		/* DR DOS detected */
	PCIBIOS:1,		/* PCIBIOS keyword detected */
	PCIBIOS_flag:1, 	/* PCI local bus detected by MAX (Phase 2) */
	BREAK:2,		/* Which pass to break on */
	BREAKALL:1,		/* Breakpoint on all passes */
	:6;			/* Unused bits */
} CFGFLAGS;

GLOBAL CFGFLAGS maxcfg
#ifdef GLINIT
 = { 0 }
#endif
;

GLOBAL char LoadString[128];	/* Path spec of .EXE file */
GLOBAL char LoaderDir[128];	/* Directory to use at CONFIG.SYS time */

GLOBAL char LoadTrue[128];	/* True path spec of .EXE file */
GLOBAL char LoaderTrue[128];	/* True path to a directory we can use */
				/* throughout CONFIG.SYS */

GLOBAL char *ProfilePath;	/* Path of profile as specified in CONFIG.SYS */
GLOBAL char *ProfileBoot;	/* Path of profile with boot drive prepended */

GLOBAL char *RecallString	/* EXE spec of program to recall */
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int MaxInstalled;	/* Non-zero if 386max installed */
GLOBAL int BcfInstalled;	/* ????? */

GLOBAL WORD MaxLine;		/* Maximum characters in command line */

GLOBAL int BootDrive		/* Drive letter of boot drive */
#ifdef GLINIT
= 0
#endif
;

GLOBAL int Pass 		/* Which pass we are in: 1, 2, or 3 */
#ifdef GLINIT
= 1
#endif
;

GLOBAL BOOL AnyError		/* TRUE if any errors have occurred */
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL AbyUser		/* TRUE to ask user to abort */
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL ForceIgnflex	/* On Phase I, force IGNOREFLEXFRAME */
#ifdef GLINIT
= FALSE;
#endif
;

GLOBAL int IntMsgCount		/* Intermediate (?) message count */
#ifdef GLINIT
= 0;
#endif
;

GLOBAL int HighParas		/* # paras used in high DOS */
#ifdef GLINIT
= 0;
#endif
;

GLOBAL int LowParas		/* # paras not loaded in high DOS */
#ifdef GLINIT
= 0;
#endif
;

GLOBAL char *RomsrchOpts	/* Options passed to ROMSRCH */
#ifdef GLINIT
= ""
#endif
;

GLOBAL char *MultiBoot		/* Name of MultiBoot section to process */
#ifdef GLINIT
= NULL				/* Default is no MultiBoot */
#endif
;

#ifdef HARPO
GLOBAL HARPOPROF *HarpoPro	/* Harpo profile in memory */
#ifdef GLINIT
= NULL
#endif
;
#endif

GLOBAL char *pszDOSStart	/* c:\windows\dosstart.bat,d:\other.bat,... */
#ifdef GLINIT
= NULL
#endif
;

/********************************************************************/
/*** Variables from UTIL_OPT.ASM ************************************/
/********************************************************************/

extern WORD pascal far NREGS;		/* Total number of high DOS regions */
extern WORD pascal far REGTAB[ 1 ];	/* Table of region sizes in paragraphs */
extern WORD pascal far BESTSIZE;    /* Best paras high */
extern WORD pascal far TOTREG;	    /* Total high DOS */
extern DWORD pascal far ELAPSED;    /* Seconds required for optimization */
#ifdef HARPO
extern SUBFIT far *psubsegs;	/* Pointer to subsegment fit records */
#endif

/********************************************************************/


GLOBAL char *ActiveFiles[MAXFILES];	/* Used file names array */
GLOBAL char *SavedFiles[MAXFILES];	/* Saved file names array */
GLOBAL int  marked[MAXFILES];		/* Indices into ActiveFiles[] of */
					/* files with marked lines */
GLOBAL int  nmark;			/* Number of files with marked lines */

GLOBAL DSPTEXT *HbatStrt[MAXFILES];	/* Array of config/batch files */

GLOBAL PRSL_T *CfgHead
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL PRSL_T *CfgTail
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL BOOL RefDisk
#ifdef GLINIT
 = FALSE
#endif
;

/*** GLOBAL DWORD ExtSize
* #ifdef GLINIT
*  = 0
* #endif
* ;
***/

GLOBAL DWORD EmsCurrent /* Address of current EMS page frame */
#ifdef GLINIT
 = 0
#endif
;

GLOBAL BOOL EmsFrame	/* EMS page frame wanted */
#ifdef GLINIT
 = TRUE
#endif
;

GLOBAL BATFILE *FirstBat;

#define MAX_TEMP 256	/* Temp buffer size */

GLOBAL char TempBuffer[MAX_TEMP]; /* Temporary buffer used for token parsing */

/* These are owned by maxsub.asm */
extern char MaxVer[3];		/* 386max version number */
extern char BcfFlag;		/* BCF flag */
extern WORD SysRom;		/* System ROM segment */
extern char BusmFlag;		/* Bus master flag */
extern char CompROM;		/* COMPROM flag */
extern WORD LoadSeg;		/* Start segment of LOADSEG chain */
extern BYTE PosDataStat;	/* Status of EMM2CALL for CMOS POS values */
extern WORD Pos32;		/* TRUE if MAX supports NVRAM POS writes */
extern char far *RebootCmd;	/* Command to reboot the system (NULL) */
extern char far *Comspec;	/* Path to COMMAND.COM */
#ifdef HARPO
extern char Harpo_profile[];	/* Saved path to HARPO.PRO */
#endif
extern int	nHighRegions;	/* Number of high DOS regions */
extern unsigned int waHighRegions[]; /* Paragraphs in each region */

extern BYTE pascal RAMTAB[];	/* One byte per 4K high DOS */
#define RAMTAB_RAM	0x01	/* Block contains RAM */
#define RAMTAB_UNK	0x02	/* Block protected by NOSCAN */

/* The following structure need not have all options, only those */
/* which need special handling when parsing.  In particular, any */
/* option with a range *MUST* be in this structure. */

GLOBAL OPTIONS Options[]
#ifdef GLINIT
 = {
	"",             0,              0,      /*  00 */
	"RAM=",         HEXADDR,        RAM,            /*01 */
	"ROM=",         HEXADDR,        ROM,            /*02 */
	"VIDMEM=",      HEXADDR,        VID,            /*03 */
#if SYSTEM == MOVEM
	"EMS=",         NOADDR,         EMS,            /*04 */
#else
	"EMS=",         NUMADDR,        EMS,            /*04 */
#endif
	"EXCLUDE=",     HEXADDR,        EXC,            /*05 */
	"EXT=",         NUMADDR,        EXT,            /*06 */
	"NOFRAME=",     NOADDR,         NOFRAME,        /*07 */
	"SHORTFRAME=",  NOADDR,         SFRAME,         /*08 */
	"VGA",          NOADDR,         VGA,            /*09 */
	"EGA",          NOADDR,         EGA,            /*0A */
	"CGA",          NOADDR,         CGA,            /*0B */
	"MONO",         NOADDR,         MONO,           /*0C */
#if SYSTEM == MOVEM
	"INCLUDE=",     HEXADDR,        INC,            /*0D */
#else
	"INCLUDE=",     OPTADDR,        INC,            /*0D */
#endif
	"USE=",         HEXADDR,        USE,            /*0E */
	"FRAME=",       ONEHEXADDR,     FRAMEX,         /*0F */
	"NOLOADHI",     NOADDR,         NOLOADHI,       /*10 */
	"NOLOADHIGH",   NOADDR,         NOLOADHIGH,     /*11 */
	"PRGREG=",      NUMADDR,        PRGREG,         /*12 */
	"PRO=",         PROADDR,        PRO,            /*13 */
	"POSFILE=",     POSNAME,        POSFILE,        /*14 */
	"BCF=",         BCFNAME,        BCF,            /*15 */
	"AUTOBCF",      NOADDR,         AUTOBCF,        /*16 */
	"VGASWAP",      ADDRLIST,       VGASWAP,        /*17 */
	"IGNOREFLEXFRAME", NOADDR,      IGNOREFLEXFRAME,/*18 */
	"NOFLEX",       NOADDR,         IGNOREFLEXFRAME,/*19 */

	"DISPLAY",      NOADDR,         DISPLAY,        /*1A - MOVE'EM only */
	"FASTROM",      NOADDR,         FASTROM,        /*1B - MOVE'EM only */
	"NOLOW",        NOADDR,         NOLOW,          /*1C - MOVE'EM only */
	"CAPS",         NOADDR,         CAPS,           /*1D - MOVE'EM only */
	"INT",          NOADDR,         INT,            /*1E - MOVE'EM only */
	"UMB",          NOADDR,         UMB,            /*1F - MOVE'EM only */

	"NOROM",        NOADDR,         NOROM,          /*20 */
	"NOSCAN",       HEXADDR,        NOSCAN,         /*21 */

#ifdef HARPO	/* Implies SYSTEM != MOVEM */
	"HPDAREG=",     OPTSIZE,        HPDAREG,        /*22 */
	"XBDAREG=",     OPTSIZE,        XBDAREG,        /*23 */
	"STACKREG=",    OPTSIZE,        STACKREG,       /*24 */
#endif
	0,			0
}
#endif	/* GLINIT */
;

#define MAXGROUPS 26	/* Maximum number of groups */

/* Vector of group numbers in use */
GLOBAL int GroupVector[MAXGROUPS];

GLOBAL BOOL QuickMax		/* Quick MAXIMIZE flag: */
#ifdef GLINIT			/* -1 = NO, 1 = YES, 0 = Unset */
= 0
#endif
;

GLOBAL BOOL NopauseMax		/* Nopause MAXIMIZE flag */
#ifdef GLINIT
= 0
#endif
;

GLOBAL BOOL FromWindows		/* Started from Windows */
#ifdef GLINIT
= 0
#endif
;

GLOBAL char *CfgFile		/* MAXIMIZE.CFG filename */
#ifdef GLINIT
= NULL
#endif
;

#ifdef HARPO

typedef struct _subsid {
  BYTE	owner;		/* SFO_HARPO, SFO_MAX, SFO_WIN, SFO_UNK */
  BYTE	type;		/* 'F', 'X', 'L', 'B', 'S', 'V', etc. */
  char	*keywd; 	/* "F=%lu,%d" */
  char	*comment;	/* "; Move FILES into region %d for %lu bytes" */
  char	*idtext;	/* " Files" */
} SUBSID;

/* The one-letter identifiers defined in QUALITAS.H and used here */
/* must match those in MAC.INC */
/* Note that no keyword formatting text is needed for MAX subsegments; */
/* this is handled in PROCCFG1!wrprofile(). */
GLOBAL SUBSID SubsIDs[]
#ifdef GLINIT
 = {
	{ SFO_UNK,    0, ";???",        "\n",                   "???" },

	{ SFO_HARPO, HFILES, "F=%5lu,%d",  MsgSubIDFComment,  MsgSubIDFText },
	{ SFO_HARPO, HFCBS,  "X=%5lu,%d",  MsgSubIDXComment,  MsgSubIDXText },
	{ SFO_HARPO, HBUFFERS,"B=%5lu,%d", MsgSubIDBComment,  MsgSubIDBText },
	{ SFO_HARPO, HLASTDRV,"L=%5lu,%d", MsgSubIDLComment,  MsgSubIDLText },
	{ SFO_HARPO, HSTACKS, "S=%5lu,%d", MsgSubIDSComment,  MsgSubIDSText },
	{ SFO_HARPO, HIFS_G,  "G=%5lu,%d", MsgSubIDGComment,  MsgSubIDGText },
	{ SFO_HARPO, HIFS_H,  "H=%5lu,%d", MsgSubIDHComment,  MsgSubIDHText },
	{ SFO_HARPO, HIFS_R,  "R=%5lu,%d", MsgSubIDRComment,  MsgSubIDRText },
	{ SFO_HARPO, HIFS_Y,  "Y=%5lu,%d", MsgSubIDYComment,  MsgSubIDYText },
	{ SFO_HARPO, HDOS3,  "V=%5lu,%d",  MsgSubIDVComment,  MsgSubIDVText },
	{ SFO_HARPO, HTEMP,  "Q=%5lu,%d",  MsgSubIDQComment,  MsgSubIDQText },

	{ SFO_MAX, XBDAREG, "XBDAREG=", MsgSubIDXBDAComment, MsgSubIDXBDAText },
	{ SFO_MAX, HPDAREG, "HPDAREG=", MsgSubIDHPDAComment, MsgSubIDHPDAText },
	{ SFO_MAX, STACKREG, "STACKREG=", MsgSubIDMSTACKComment, MsgSubIDMSTACKText },

	{ 0, 0, NULL, NULL, NULL }
     }
#endif
;

GLOBAL SUMFIT *HarpoComspec
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL SUMFIT *HarpoShare
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL HARPO_OPTAB HarpoOptions[]
#ifdef GLINIT
= {
	{ HOPT_GETSIZE, 	"GETSIZE"       },
	{ HOPT_GETSIZE, 	"OVERFLOW"      },
	{ HOPT_DEADMAN, 	"NOLOADHI"      },
/*	{ HOPT_UNK,		"NOPSP"         },      */
/*	{ HOPT_UNK,		"SHARE"         },      */
/*	{ HOPT_UNK,		"DEBUG"         },      */

	{ HOPT_SUBSEG,		"F"             },
	{ HOPT_SUBSEG,		"X"             },
	{ HOPT_SUBSEG,		"B"             },
	{ HOPT_SUBSEG,		"L"             },
	{ HOPT_SUBSEG,		"S"             },
	{ HOPT_SUBSEG,		"G"             },
	{ HOPT_SUBSEG,		"H"             },
	{ HOPT_SUBSEG,		"R"             },
	{ HOPT_SUBSEG,		"Y"             },
	{ HOPT_SUBSEG,		"Q"             },
	{ HOPT_SUBSEG,		"V"             },

	{ HOPT_CCOM,		"C"             },
	{ HOPT_CCOM,		"E"             },

	{ HOPT_UNK,		 NULL		}
}
#endif
;

#endif

GLOBAL char *Essentials[]
#ifdef GLINIT
 = {
	LOADERS,		/* 386LOAD.SYS */
	LOADERC,		/* 386LOAD.COM */
	BATPROC,		/* BATPROC.EXE */
	"MAXIMIZE.EXE",
	"MAXIMIZE.TRM",
/*	HARPO_EXE,	*/	/* Not required if NOHARPO */
	NULL
 }
#endif
;

GLOBAL int BackupMax
#ifdef GLINIT
= 0	/* BACKUP= not specified; ask once it hits 8 */
#endif
;

GLOBAL int BackupMin
#ifdef GLINIT
= 3	/* Default to keep */
#endif
;

#endif /* MAXVAR_INCLUDED */
