/*' $Header:   P:/PVCS/MAX/MAXIMIZE/QUALITAS.H_V   1.1   10 Nov 1995 17:52:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * QUALITAS.H								      *
 *									      *
 * Qualitas product-specific definitions				      *
 *									      *
 ******************************************************************************/

#ifndef QUALITAS_INCLUDED
#define QUALITAS_INCLUDED

#include <commdef.h>		/* Common (shared) definitions */

/* Indices into FILES and SFILES -- Typical name */
#define CONFIG	    0		/* C:\CONFIG.SYS */
#define AUTOEXEC    1		/* C:\AUTOEXEC.BAT */
#define PROFILE     2		/* C:\386MAX\386MAX.PRO */
#define BETAFILE    3		/* C:\AUTOEXEC.ABETA */
#define LASTPHASE   4		/* C:\386MAX\LASTPHAS */
#define PREMAXIM    5		/* C:\386MAX\PREMAXIM.BAT */
#define ERRMAXIM    6		/* C:\386MAX\ERRMAXIM.BAT */
#define HARPOPRO    7		/* C:\386MAX\HARPO.PRO */
#define BATFILES    8		/* Batch files from MAXIMIZE.OUT start here */
#define MAXFILES   20		/* Maximum # files including 0-8 */

#define BATPROC   "batproc.exe"

#if SYSTEM == MOVEM
#define LOADER	  "move'em"
#define LOADERS   "move'em.sys"
#define LOADERC   "move'em.com"
#else
#define LOADER	  "386load"
#define LOADERS   "386load.sys"
#define LOADERC   "386load.com"
#endif

#define LSTPHS	  "LASTPHAS"
#define PRMXM	  "PREMAXIM.BAT"
#define ERRMXM	  "ERRMAXIM.BAT"
#define LOGFILE   "MAXIMIZE.LOG"
#define CFGFILE   "MAXIMIZE.CFG"
#define PROBE	  "ROMSRCH"
#define PROBECOM  PROBE ".COM"
#define PROBEOUT  PROBE ".OUT"
#define XLAT	  "XLAT"
#define XLATCOM   XLAT ".COM"

/* File handles predefined by DOS */
#define STDIN	 0
#define STDOUT	 1
#define STDERR	 2

/*-----------------------------------------------------------*/
/*  Structure used for profile options			     */
/*-----------------------------------------------------------*/

#define VALIDSTOKENS	"BCEFLQSGHRYVX" /* Valid in HARPO profile */
typedef enum _etype {
	XBDAREG='D', HPDAREG='H', STACKREG='M',
	HBUFFERS='B', HCOMMAND='C', HENVIRON='E', HFILES='F',
	HLASTDRV='L', HTEMP='Q', HSTACKS='S', HIFS_G='G', HIFS_H='H',
	HIFS_R='R', HIFS_Y='Y', HDOS3='V', HFCBS='X',
	RAM = 256, ROM, VID, EXC, EMS, EXT, NOFRAME, SFRAME, VGA, EGA,
	CGA, MONO, INC, USE, FRAMEX, NOLOADHI, NOLOADHIGH, PRGREG,
	PRO, POSFILE, BCF, AUTOBCF, VGASWAP, IGNOREFLEXFRAME,
	DISPLAY, FASTROM, NOLOW, CAPS, INT, UMB,
	NOROM, NOSCAN, NULLOPT
} ETYPE;

/* Argument types for OPTIONS structure */

#define NOADDR	    0		/* no address allowed */
#define HEXADDR     1		/* hhhh-hhhh type addresses */
#define NUMADDR     2		/* nnnn type addresses */
#define OPTADDR     3		/* May be either of the above */
#define PROADDR     4		/* pro=d:\path\filename.ext */
#define ONEHEXADDR  5		/* hhhh only */
#define POSNAME     6		/* d:\path\filename.ext */
#define BCFNAME     7		/* d:\path\filename.ext */
#define ADDRLIST    8		/* VGASWAP=[xxxx],[yyyy],[zzzz] */
#define OPTSIZE     9		/* XBDAREG=[size,]reg */
				/* We don't need the parsed value */

typedef struct _options {
	char *name;		/* Pointer to option name with trailing '=' if appropriate */
	int   atype;	/* Option argument type (see defines above) */
	ETYPE etype;	/* Option enum type */
} OPTIONS;

/*-----------------------------------------------------------*/
/*  Structure used for SUMFIT tables			     */
/*-----------------------------------------------------------*/

/* The following flags *MUST* match the ones in LOAD_SEG.INC */

typedef struct _lsegflag {	/* LSEG flags */
	WORD  flex:1,		/* Allows FLEXFRAME */
	      inst:1,		/* Called via DOS 4.x INSTALL= */
	      gsize:1,		/* Forced GETSIZE if no room in high DOS */
	      xlhi:1,		/* NOLOADHI on 386MAX line */
	      xems:1,		/* EMS error during FLEXFRAME */
	      fsiz:1,		/* Forced SIZE= present */
	      drv:1,		/* This is a device driver */
	      winst:1,		/* Force local instancing under Windows 3 */

	      inpro:1,		/* 386LOAD in progress */
	      inflex:1, 	/* FLEXFRAME used */
	      xres:1,		/* Program did not go resident */
	      imax:1,		/* Initial allocation was maximum size */
	      lsiz:1,		/* Load size > initialization size:  force SIZE= */
	      stra:2,		/* Strategy: 0-first, 1-best, 2-last */
	      umb:1;		/* Program allocated UMBs */
} LSEGFLAG;

typedef struct _sumfit {
	WORD lseg;		/* 00-01:  Para # of LSEG (0=last+1 entry) */
	WORD ipara;		/* 02-03:  # paras needed to install */
	WORD rpara;		/* 04-05:  # paras needed as resident program */
	WORD epar0;		/* 06-07:  # paras needed for environment before */
				/*		(0=device driver) */
				/* UMBs: paras to attempt to allocate */
	WORD epar1;		/* 08-09:  # paras needed for environment after */
				/* UMBs: LSEG_EPAR1UMB (see LOAD_SEG.INC) */
	BYTE preg;		/* 0A-0A:  Program region # specified (0=load low) */
	BYTE ereg;		/* 0B-0B:  Environment ... */
	BYTE grp;		/* 0C-0C:  Group # specified (0=none, */
				/*		-1=386MAX, */
				/*		-2=UMB) */
	BYTE ord;		/* 0D-0D:  Program order # (origin-0) */
	LSEGFLAG flag;		/* 0E-0F:  Flags */
				/* *MUST* be on a word boundary */
} SUMFIT;

/* Define equates for GRP above */
#define GRPMAX	 ((BYTE) -1)
#define GRPUMB	 ((BYTE) -2)
#ifdef HARPO
#define GRP_SUBSEG ((BYTE) -3)
#define GRP_HIPROG ((BYTE) -4)
#endif

#ifdef HARPO
/*-----------------------------------------------------------*/
/*  Structure overlaid on SUMFIT for subsegments	     */
/*-----------------------------------------------------------*/

/* The following flags *MUST* match the ones in EMM2CALL.INC */

typedef struct _subfit {
	WORD lseg;		/* 00-01:  Para # of LSEG (0=last+1 entry) */
	WORD rsvd1;		/* 02-03:  Not used */
	WORD rpara;		/* 04-05:  # paras needed */
	WORD rsvd2;		/* 06-07:  Not used */
	WORD rsvd3;		/* 08-09:  Not used */
	BYTE newreg;		/* 0A-0A:  Subsegment region # after optimization (0=load low) */
	BYTE oldreg;		/* 0B-0B:  Region # before optimization */
	BYTE type;		/* 0C-0C:  'F','X','L', etc. */
	BYTE rsvd4;		/* 0D-0D:  Not used */
	WORD ownr:2,		/* 0E-0F:  Flags: owner is 0 for HARPO, etc. */
		:14;
} SUBFIT;

/* Define equates for ownr field */
#define SFO_HARPO	0x00	/* Owner is HARPO */
#define SFO_MAX 	0x01	/* 386MAX */
#define SFO_WIN 	0x02	/* Windows instance data */
#define SFO_UNK 	0x03	/* Not used */

#endif		/* ifdef HARPO */

/*-----------------------------------------------------------*/
/*  Structure used for LSEG access for module names	     */
/*-----------------------------------------------------------*/

typedef struct _lseg_fit {
	WORD	 next;		/* 00-01:  Segment of next LSEG (-1 if last) */
	WORD	 prev;		/* 02-03:  Segment of prev LSEG (-1 if first) */
	char	 name[12];	/* 04-0F:  Program name */
	WORD	 rpara; 	/* 10-11:  Resident size in paras (wo/MAC) */
	WORD	 epar0; 	/* 12-13:  Environment size in paras before (w/MAC) */
				/* UMBs: paras to attempt to allocate */
	WORD	 epar1; 	/* 14-15:  ...			     after  ... */
				/* UMBs: LSEG_EPAR1UMB (see LOAD_SEG.INC) */
	WORD	 rpar2; 	/* 16-17:  Forced resident size in paras if SIZE=n,n */
	DWORD	 asize; 	/* 18-1B:  Actual SIZE= */
	DWORD	 lsize; 	/* 1C-1F:  Load size */
	DWORD	 isize; 	/* 20-23:  Initialization size */
	BYTE	 preg;		/* 24-24:  Program region # */
	BYTE	 ereg;		/* 25-25:  Environment region # */
	LSEGFLAG flag;		/* 26-27:  Flags: *MUST* be on a word boundary */
	WORD	 ipara; 	/* 28-29:  Interrupt block size in paras */
	BYTE	 grp;		/* 2A-2A:  Group # (0 if none) */
	BYTE	 fill1; 	/* 2B-2B:  Filler for alignment */
	WORD	 ownrhi;	/* 2C-2D:  Segment of owner in high DOS (0=none) */
	WORD	 instlo;	/* 2E-2F:  Segment of low DOS to instance */
	WORD	 instlen;	/* 30-31:  Length in paras of INSTLO (0=none) */
} LSEGFIT;

/*-----------------------------------------------------------*/
/*  Structure containing options for 386MAX		     */
/*-----------------------------------------------------------*/

typedef struct _config_d {
	ETYPE etype;	/* See ENUM above */
	DWORD saddr;	/* Start address */
	DWORD eaddr;	/* End address */
	char *comment;	/* Text of comment if any */
	char *origstr;	/* Original text line */
	BYTE Owner;	/* Multiboot owner of this line */
} CONFIG_D;

/*-----------------------------------------------------------*/
/*  Link structure pointing to above			     */
/*-----------------------------------------------------------*/

typedef struct _prsl_t {
	struct _prsl_t	*prev;
	struct _prsl_t	*next;
	CONFIG_D	*data;
} PRSL_T;

typedef enum _dsp_device {
	DSP_DEV_UNKNOWN = 0, DSP_DEV_DEVICE, DSP_DEV_INSTALL
} DSP_DEVICE;

typedef enum _dsp_mark {
	DSP_MARK_UNMARKED = 0,	DSP_MARK_GETSIZE, DSP_MARK_LOW,
				DSP_MARK_HIGH, DSP_MARK_WARN
} DSP_MARK;

typedef struct _dsptext {
	struct _dsptext *prev;	/* Pointer to previous DSPTEXT entry */
	struct _dsptext *next;	/* ...	      next ... */
	BYTE	MBtype; 	/* (MultiBoot only) Line type - see MBPARSE.H */
	BYTE	MBOwner;	/* (MultiBoot only) Section owner */
	char   *text;		/* Original text line */
	BYTE	device; 	/* 2 = install, 1 = device, 0 = neither */
	BYTE	max;		/* 0 = non-install= line which precedes 386MAX */
				/* 1 = is 386MAX */
				/* 2 = device= or install= which follows 386MAX */
				/*     or install= which precedes 386MAX */
	BYTE	mark;		/* 0 = not marked */
				/* 1 = marked & displayed w/LOADER */
				/* 2 = marked & loaded low */
				/* 3 = marked & using original line */
				/* 4 = marked & loaded low; busmaster warning */
	BYTE	umb;		/* How many UMBs this program allocates */
	BYTE	umbfailed;	/* 1 = attempted to allocate UMB(s); no luck */
	struct {		/* Options present on original line */
		unsigned display:1,  /* DISPLAY present */
			 envname:1,  /* ENVNAME ... */
			 envreg :1,  /* ENVREG ... */
			 envsave:1,  /* ENVSAVE ... */
			 getsize:1,  /* GETSIZE ... */
			 group	:1,  /* GROUP= ... */
			 inter	:1,  /* INT ... */
			 nopause:1,  /* NOPAUSE ... */
			 noretry:1,  /* NORETRY ... */
			 pause	:1,  /* PAUSE ... */
			 prgreg :1,  /* PRGREG= ... */
			 prog	:1,  /* Also used to test for LOADER */
			 quiet	:1,  /* QUIET ... */
			 size	:1,  /* SIZE= ... */
			 flex	:1,  /* FLEXFRAME ... */
			 vds	:1,  /* VDS ... */
			 loadsw :1,  /* If loader present on line, use */
				     /* as switch */
			 terse	:1,  /* TERSE ... */
			 verbose:1;   /* VERBOSE . .  */
	} opts;
	BYTE prgreg,		/* Integer value for PRGREG= */
	     envreg,		/*		     ENVREG= */
	     group,		/*		     GROUP= */
	     group0;		/* Original group number to undo reordering */
	char	   *devicen;	/* Pointer to text following Device=/Install= */
	char	   *profilen;	/* ...			     pro= (if any) */
	SUMFIT far *psumfit;	/* Ptr to corresponding SUMFIT structure */
	LSEGFIT far *plseg;	/* Ptr to corresponding LSEGFIT structure */
	char	   *pdevice;	/* ...	  text following prog= (if present) */
				/*	  == devicen (if not) */
	BYTE	    envmark:1,	/* 1 = envname displayed, 0 = not */
		    busmark:1,	/* 1 = BUSM and L-flag w/o VDS */
		    visible:1,	/* 1 = line is active for this configuration */
			deleted:1;	/* 1 = line should not be written out */
	int	    high;	/* 1 = to be loaded high, 0 = not */
	int	    nlead;	/* # leading chars of ->TEXT to preserve */
	int	    action;	/* Actions:  see P2BROWSE for details */
	char groupspec[16];	/* File spec / group id for group matching */
} DSPTEXT;

typedef struct _batfile {
	struct _batfile  *prev;
	struct _batfile  *next;
	struct _batfile  *prevbat;
	struct _batfile  *nextbat;
	DSPTEXT *batline;
	char	*flags;
	char	*command;
	char	*batname;
	int	line;
	int	nlead;
} BATFILE;

/*-----------------------------------------------------------*/
/*  Structure used for scrolling windows		     */
/*-----------------------------------------------------------*/

typedef struct _texthd {
	struct _texthd *prev;
	struct _texthd *next;
	DSPTEXT *disp;
	int	 atr;		/* Display attribute for this line */
	int	 mlines;	/* Indicator for multiple lines */
	char	*textline;	/* Displayed text for this line  */
} TEXTHD;

typedef struct _bcfh {
	WORD fcrc;	/* 00-01:  CRC of the BCF file (before encryption) */
	WORD bcrc;	/* 02-03:  ...	      target BIOS */
	WORD size;	/* 04-05:  Size of header in bytes */
	BYTE name[80];	/* 06-55:  Name of target BIOS */
	WORD boff;	/* 56-57:  Starting offset in bytes in new BIOS */
	WORD vers;	/* 58-59:  BCF file version # */
	WORD rev;	/* 5A-5B:  Revision # of this BIOS's BCF */
	WORD ncell;	/* 5C-5D:  # command cells */
} BCFH;

/* Structure used for optimization progress display */
typedef struct _opt_prog {
	WORD	pct;		/* Percent completed */
	WORD	flags;		/* BEST_DIRTY & other flags */
	/* Other than pct, all structure members are far pointers to
	   ASCIIZ representations.  Data is already formatted.
	*/
	char _far *pdone;	/* Number completed (n,nnn,nnn...) */
	char _far *pelapsed;	/* HH:MM:SS elapsed */
	char _far *ptotal;	/* Domain of possibilities */
	char _far *ptothigh;	/* Total bytes in high DOS */
	char _far *pbestcnt;	/* Number processed to reach best so far */
	char _far *pbestelap;	/* HH:MM:SS elapsed when best so far found */
	char _far *pbestbyte;	/* Number of bytes moved high for best so far */
	char _far *pbestpct;	/* Best count as percentage of total */
	char _far *pbestbpct;	/* Best bytes as percentage of high DOS */

} OPT_PROG, _far *OPT_PROGfp;

/* MAC entry size macro - No MAC entry used if and only if it's a device */
/* driver loaded low  */
#define MACSIZE(p)	!(p->flag.drv && !p->preg)

#ifdef HARPO

#define HMACSIZE(p)	(p->preg ? 1 : 0) /* HARPO doesn't load drivers */
#define HSMACSIZE(p)	(p->newreg ? 1 : 0) /* Add MAC para if loaded high */

/* Define integer values for HARPO options.  We'll associate these */
/* with the keywords in the option table structure declared here */
/* and filled in MAXVAR.H (HarpoOptions[]) */
typedef enum _harpo_opt {
	HOPT_UNK = 0,	/* Unknown, don't care, or not in our MB section */
	HOPT_GETSIZE,	/* GETSIZE or OVERFLOW - discard at end of Phase 3 */
	HOPT_DEADMAN,	/* NOLOADHI deadman switch - disable HARPO support */
	HOPT_SUBSEG,	/* F, X, B, L, S, V, or Q */
	HOPT_CCOM	/* C or E */
} HARPO_OPT;

typedef struct _harpo_optab {
	HARPO_OPT optoken;
	char *optname;	/* Text name of option */
} HARPO_OPTAB;

typedef struct _harpoprof {
	struct _harpoprof *next;
	int nspace;	/* Space before comments (if any) minus 1 */
	char *comments; /* Comment text without leading space and ; */
	char *keyword;	/* Option keyword (NOLOADHI, E, C, etc.) */
	char *arg1;	/* First argument (or NULL) */
	char *arg2;	/* Second argument (or NULL) */
	char *workspace; /* Original contents with some '\0's blown in */
			/* If optype == HOPT_UNK, it's unchanged and */
			/* nothing else is valid. */
	HARPO_OPT optype; /* Option type */
	BYTE Owner;	/* Multiboot owner of this line */
	int  deleted:1, /* This option was deleted; don't write it */
		:15;
} HARPOPROF;

#endif /* HARPO support enabled */

#endif /* QUALITAS_INCLUDED */

