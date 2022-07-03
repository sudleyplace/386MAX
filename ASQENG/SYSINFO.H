/*' $Header:   P:/PVCS/MAX/ASQENG/SYSINFO.H_V   1.1   01 Feb 1996 10:39:50   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SYSINFO.H								      *
 *									      *
 * System information structures and definitions			      *
 *									      *
 ******************************************************************************/

#include <commdef.h>            /* Common definitions */

#include <c_tload.h>            /* C&T chipset checker */
#include <cpu.h>                /* CPU identification */
#include <emsinfo.h>            /* EMS info structure */
#include <listlist.h>           /* Secrets of DOS */
#include <mca_pos.h>            /* MCA Adapter IDs */

#include "adf.h"                /* Adapter description file info */
#include "biosid.h"             /* BIOS identification */
#include "flexroms.h"           /* Flexxed rom info */
#include "glist.h"              /* Generic list definitions */
#include "sysbuf.h"             /* SysInfo buffer definitions */
#include "timer.h"              /* Memory / CPU timing structure */
#include "xmsinfo.h"            /* XMS info structure */

#pragma pack(1)
typedef struct _biosdata {
	/* ---- General ---- */
	WORD rs232_base[4];	/* (00) Base(s) of RS-232 port(s) */
	WORD printer_base[4];	/* (08) Base(s) of printer port(s) */
	WORD equip_flag;	/* (10) Installed hardware */
	BYTE mfg_tst;		/* (12) Initilization flag */
	WORD memory_size;	/* (13) Menory size in K bytes */
	BYTE mfg_err_flag;	/* (15) Scratchpad for manufacturing */
	BYTE err_codes; 	/* (16) Error codes (?) */
	/* ---- Keyboard Data Areas ---- */
	BYTE kb_flag;		/* (17) Keyboard flag (?) */
	BYTE kb_flag_1; 	/* (18) Second byte of keyboard status */
	BYTE alt_input; 	/* (19) Storage for alternate keypad entry */
	WORD buffer_head;	/* (1A) Pointer to head of keyboard buffer */
	WORD buffer_tail;	/* (1C) Pointer to tail of keyboard buffer */
	WORD kb_buffer[16];	/* (1E) Room for 15 entries */
	/* ---- Diskette Data Areas ---- */
	BYTE seek_status;	/* (3E) Bit 3-0:  Drive 3-0 needs recal before next seek if <> 0 */
	BYTE motor_status;	/* (3F) Bit 3-0:	Drive 3-0 is currently running, bit 7 = current op == write, requires delay */
	BYTE motor_count;	/* (40) Time out counter for drive turn off */
	BYTE diskette_status;	/* (41) Return code status byte */
	BYTE nec_status[7];	/* (42) Status bytes from NEC 765 */
	/* ---- Video Display Data Areas ---- */
	BYTE crt_mode;		/* (49) Current CRT mode */
	WORD crt_cols;		/* (4A) Number of columns on screen */
	WORD crt_len;		/* (4C) Length of regen in bytes */
	WORD crt_start; 	/* (4E) Starting address in regem buffer */
	WORD cursor_posn[8];	/* (50) Cursor for each of up to 8 pages */
	BYTE cursor_mode[2];	/* (60) Current cursor mode setting */
	BYTE active_page;	/* (62) Current page being displayed */
	WORD addr_6845; 	/* (63) Base address for active display card */
	BYTE crt_mode_set;	/* (65) Current setting of the 3x8 register */
	BYTE crt_palette;	/* (66) Current palette setting for color card */
	/* ---- P.O.S.T. Data Area ---- */
	DWORD io_rom;		/* (67) Pointer to optional I/O rom init routine */
	BYTE intr_flag; 	/* (6B) Flag to indicate an interrupt happened */
	/* ---- Timer Data Area ---- */
	DWORD timer_count;	/* (6C) Timer count */
	BYTE timer_ofl; 	/* (70) Timer has rolled over since last read */
	/* ---- System Data Area ---- */
	BYTE bios_break;	/* (71) Bit 7 == 1 if break key has been hit */
	WORD reset_flag;	/* (72) Word == 1234H if keyboard reset underway */
	/* ---- Hardfile Data Area ---- */
	BYTE disk_status1;	/* (74) */
	BYTE hf_num;		/* (75) */
	BYTE control_byte;	/* (76) */
	BYTE port_off;		/* (77) */
	/* ---- Printer and RS232 Time-Out Variables ---- */
	BYTE print_tim_out[4];	/* (78) */
	BYTE rs232_tim_out[4];	/* (7C) */
	/* ---- Additional Keyboard Data Area ---- */
	WORD buffer_start;	/* (80) */
	WORD buffer_end;	/* (82) */
	BYTE scrn_rows; 	/* (84) Screen rows - 1 */
	WORD char_height;	/* (85) Character height */
	BYTE video_ctrl[2];	/* (87) Video control states */
	BYTE filler[2]; 	/* (89) 2 bytes of starchy filler */
	/* ---- Additional Floppy Data ---- */
	BYTE lastrate;		/* (8B) Last data rate selected */
	/* ---- Additional Hard File Data ---- */
	BYTE hf_status; 	/* (8C) Status register */
	BYTE hf_error;		/* (8D) Error register */
	BYTE hf_int_flag;	/* (8E) Hard file interrupt flag */
	BYTE hf_cntrl;		/* (8F) Combo hard file/floppy card bit 0 == 1 */
	/* ---- Additional Diskette Data ---- */
	BYTE d0_media;		/* (90) Drive 0 media state */
	BYTE d1_media;		/* (91) Drive 1 media state */
	BYTE d0_op;		/* (92) Drive 0 operation start state */
	BYTE d1_op;		/* (93) Drive 1 operation start state */
	BYTE d0_cyl;		/* (94) Drive 0 current cylinder */
	BYTE d1_cyl;		/* (95) Drive 1 current cylinder */
	BYTE kb_state;		/* (96) Keyboard state */
	/* ---- Additional Keyboard LED flag ---- */
	BYTE kb_LED;		/* (97) Keyboard LED */
	/* ---- Real Time Clock Data Area ---- */
	DWORD user_flag;	/* (98) Addr of users wait flag */
	DWORD rtc_addr; 	/* (9C) RTC address */
	BYTE rtc_wait_flag;	/* (A0) Wait active flag */
	BYTE reserved[7];	/* (A1) Reserved */
	DWORD ega_struct;	/* (A8) EGA Structures */
} BIOSDATA;

typedef struct _hdparam {	/* Hard disk parameters from BIOS */
	WORD cyls;		/* Cylinders */
	char heads;		/* Heads */
	WORD z1;		/* Always zero */
	WORD precomp;		/* Write Precomp */
	char z2;		/* Always zero */
	WORD ctrl;		/* Control byte (?) */
	WORD z3;		/* Always zero */
	WORD lzone;		/* Landing zone */
	WORD sectors;		/* Always 17 */
} HDPARAM;

typedef struct _macentry {	/* Memory allocation chain entry */
	BYTE type;		/* 'Z' = last, 'M' = valid */
	WORD owner;		/* Owner:  0 = unallocated */
	WORD npara;		/* # paragraphs allocated to this entry */
	/* Actually, theres more, but not that you can count on */
	/* in DOS prior to 4.0 */
} MACENTRY;

typedef struct _ddentry {		/* Device driver header */
	struct _ddentry far *next;	/* Pointer to next header */
	WORD attr;			/* Device attributes */
	WORD strat;			/* Pointer to strategy routine */
	WORD intr;			/* Pointer to interrupt routine */
	char name[8];			/* Device name */
} DDENTRY;
#pragma pack()

typedef struct _video { /* Video Adapter info */
	int  acode;	/* Adapter code from VideoID() */
	int  dcode;	/* Display code from VideoID() */
	char name[32];	/* Name of adapter (CGA, EGA, etc.) */
	char mode[32];	/* Mode of adapter (Color or Mono) */
	WORD text;	/* Address of text memory */
	WORD tsize;	/* Size of text memory in paragraphs */
	WORD graph;	/* Address of graphics memory */
	WORD gsize;	/* Size of graphics memory in paragraphs */
	WORD rom;	/* Address of adapter ROM */
	WORD rsize;	/* Size of adapter ROM in paragraphs */
	WORD osize;	/* Effective size of adapter memory in kb */
	WORD cols;	/* Display columns */
	WORD rows;	/* Display rows */
} VIDEO;

typedef enum _moutype { 	/* Mouse type */
	MOUTYPE_NONE,		/* Unknown or not installed */
	MOUTYPE_BUS,		/* 1 = Bus mouse */
	MOUTYPE_SER,		/* 2 = Serial mouse */
	MOUTYPE_INP,		/* 3 = InPort mouse */
	MOUTYPE_PS2,		/* 4 = PS/2 mouse */
	MOUTYPE_HP,		/* 5 = HP mouse */
	MOUTYPE_TOOBIG		/* Out of range */
} MOUTYPE;

typedef struct _mouseinfo {	/* Mouse Information */
	MOUTYPE type;		/* Type as defined above */
	WORD version;		/* Major/minor version number */
	WORD irq;		/* IRQ number (0 for PS/2) */
} MOUSEINFO;

typedef struct _driveparm {	/* Floppy/hard driver parameters */
	char text[16];		/* General type (360kb, 20 mb, etc.) */
	WORD heads;		/* How many heads */
	WORD cyls;		/* How many cylinders */
	WORD sectors;		/* How many sectors */
	WORD type;		/* Type number */
} DRIVEPARM;

typedef struct _parttable {	/* Hard disk partition table */
	BYTE	bootind;	/* boot indicator 0/0x80	*/
	BYTE	start_head;	/* head value for first sector	*/
	BYTE	start_sec;	/* sector value for first sector*/
	BYTE	start_cyl;	/* track value for first sector */
	BYTE	sysind; 	/* system indicator 00=?? 01=DOS*/
	BYTE	last_head;	/* head value for last sector	*/
	BYTE	last_sec;	/* sector value for last sector */
	BYTE	last_cyl;	/* track value for last sector	*/
	long	lowsec; 	/* logical first sector 	*/
	long	size;		/* size of partion in sectors	*/
} PARTTABLE;

typedef struct _config {	/* DOS configuration parameters */
	int files;		/* Current FILES setting */
	int buffers;		/* Current BUFFERS setting */
	int fcbx;		/* Current FCBS x setting */
	int fcby;		/* Current FCBS y setting */
	int stackx;		/* Current STACKS x setting */
	int stacky;		/* Current STACKS y setting */
	int lastdrive;		/* Letter of last drive 'A'-'Z' */
	int brk;		/* BREAK flag */
	int print;		/* PRINT TSR is loaded */
	int fastopen;		/* FASTOPEN TSR is loaded */
	SYSBUFH maxpro; 	/* 386MAX profile name */
	SYSBUFH shell;		/* SHELL string */
	SYSBUFH country;	/* COUNTRY string */
	SYSBUFH drivparm;	/* DRIVPARM string */
	SYSBUFH extradospro;	/* ExtraDOS profile name */
	SYSBUFH startupbat;	/* AUTOEXEC.BAT path name */
} CONFIG;

#define CMOS_CTRL 0x70		/* CMOS control port */
#define CMOS_DATA 0x71		/* CMOS data port */
#define CMOS_SIZE 128		/* How many bytes in CMOS ram */
#define CMOS_TIME 10		/* How many bytes in CMOS ram, RTC only */

/*
 *	Map Classes:
 *
 *	BEWARE:  These are written to the snapshot files as integers.
 *	So DON'T REARRANGE them.
 */

typedef enum _mapclass {	/* Map class ids */
	CLASS_UNKNOWN,		/* Unknown class */
	CLASS_DOS,		/* "DOS System" */
	CLASS_DEV,		/* "Device Drivers" */
	CLASS_UMB,		/* XMS Upper Memory Block */
	CLASS_AVAIL,		/* "Available" */
	CLASS_VIDEO,		/* "Video" */
	CLASS_RAM,		/* "RAM" */
	CLASS_ROM,		/* "ROM" */
	CLASS_PRGM,		/* Programs */
	CLASS_ENV,		/* Environments */
	CLASS_EMS,		/* EMS page frame */
	CLASS_UNUSED,		/* Unused */
	CLASS_NOTINST,		/* Not Installed */
	CLASS_RAMROM,		/* RAM or ROM (386max spanning entry) */
	CLASS_SUBSEG,		/* MAX / ExtraDOS subsegments */
	CLASS_TOOBIG		/* Off the scale */
} MAPCLASS;

typedef struct _umap {		/* One entry for unified memory map */
	struct {		/* Flags */
		int high:1;	/* TRUE if in High DOS */
		int frag:1;	/* TRUE if this block overlaps with another */
		int over:1;	/* TRUE if this block overlaps with another */
		int hole:1;	/* TRUE if this block found by mapping holes */
		int spare:1;	/* Spare flag for use during summary */
	} flags;
	MAPCLASS class; 	/* Classification for summary */
	int layer;		/* Layer number for overlap calculations */
	char name[20];		/* Name of entry */
	char far *saddr;	/* 'Segmented' address of entry */
	DWORD faddr;		/* 'Flat' address for doing arithmetic */
	long length;		/* Length in bytes */
	char text[40];		/* Text string, if any */
} UMAP;

#define TIMEITEMS 20		/* Max items in time list */

typedef struct _openfile {	/* Open file item */
	char name[14];		/* File name */
} OPENFILE;

typedef struct _romitem {	/* On-card ROM item */
	WORD seg;		/* Segment address of start of ROM */
	WORD size;		/* Size in paras */
} ROMITEM;

typedef struct _memhole {	/* Memory hole item */
	DWORD faddr;		/* 'Flat' address for doing arithmetic */
	long length;		/* Length in bytes */
	MAPCLASS class; 	/* Classification for summary */
	char name[20];		/* Name of entry */
} MEMHOLE;

typedef struct _dosdata {	/* Dos data area info (similar to UMAP */
	int type;		/* Entry type */
	char far *saddr;	/* 'Segmented' address of entry */
	DWORD faddr;		/* 'Flat' address for doing arithmetic */
	long length;		/* Length in bytes */
	int count;		/* File count for file entries */
	char name[20];		/* Name of entry (dos 4.x) */
} DOSDATA;


typedef struct _ddlist {	/* Device driver list */
	void far *this; 	/* Address of this DD entry */
	void far *next; 	/* Address of next DD header */
	WORD attr;		/* Device attributes */
	WORD strat;		/* Pointer to strategy routine */
	WORD intr;		/* Pointer to interrupt routine */
	char name[8];		/* Device name */
} DDLIST;

/* MACINFO types */
#define MACTYPE_DOS	'@'
#define MACTYPE_DRVRS	'8'
#define MACTYPE_CMDCOM	'C'
#define MACTYPE_PRGM	'P'
#define MACTYPE_ENV	'E'
#define MACTYPE_DD	'D'
#define MACTYPE_AVAIL	'A'
#define MACTYPE_RAMROM	'R'
#define MACTYPE_CURRENT 'T'
#define MACTYPE_UMB	'U'
#define MACTYPE_SUBSEG	'S'
#define MACTYPE_UNKNOWN '?'

typedef struct _macinfo {	/* One memory allocation chain info */
	WORD type;		/* Type of entry */
	WORD start;		/* Starting segment */
	WORD size;		/* Size in paras */
	WORD owner;		/* Owner of segment */
	char name[16];		/* Name of entry: name.ext */
	char text[40];		/* Handle to environment text, if any */
} MACINFO;

typedef struct tagWindowsData {
	WORD windowsver;	/* Version from WINVER.EXE */
	SYSBUFH windowsdir;	/* Home directory for Windows */
	SYSBUFH sysininame;	/* Pathname for SYSTEM.INI */
	SYSBUFH pWFiles;	/* Start of Windows file stats */
} WINDOWSDATA;

/* Flags common to LSEG and SUMFIT structures */
typedef struct tagLSEGFlags {
	WORD	flex:1, 	/* FLEXFRAME allowed */
		inst:1, 	/* Loaded via INSTALL= */
		gsize:1,	/* Forced GETSIZE */
		xlhi:1, 	/* NOLOADHI */
		xems:1, 	/* EMS error during FLEXFRAME */
		fsiz:1, 	/* Forced resident SIZE= */
		drv:1,		/* Device driver */
		winst:1,	/* Instance under Windows */

		inpro:1,	/* 386LOAD in progress */
		inflex:1,	/* FLEXFRAME used */
		xres:1, 	/* Not resident */
		imax:1, 	/* UMB: initial allocation was maximum */
		flsize:1,	/* LSIZE > ISIZE */
		stra:2, 	/* 0=first, 1=best, 2=last fit */
		umb:1;		/* UMBs allocated */
} LSEGFLAGS;

typedef struct tagEPAR1Flags {
	  WORD	pinst:12,	/* Ancestor bitmap - high order bit is */
				/* immediate predecessor */
		dlghi:1,	/* DLGROUP allocated from high DOS */
		pimax:1,	/* imax was set previously */
		prevmap:1,	/* pinst is valid */
		psp:1;		/* Created by 4B PSP */
} EPAR1FLAGS;

/* Structure for MAX/Move'EM LSEG entries */
#pragma pack(1)
typedef struct tagLSEGData {
	SYSBUFH next;		/* Next LSEG or 0 if last */
/*	WORD prev;	*/	/* Previous (not used here) */
	char fne[14];		/* Name */
	WORD rpara;		/* Resident size in paras */
	union {
	  WORD epar0;		/* Environment size in paras (before) */
	  WORD reqsize; 	/* For 4B UMBs, size requested in paras */
	};
	union {
	  WORD epar1;		/* Final environment size in paras */
	  EPAR1FLAGS ep1u;	/* Ancestor bitmap, etc. */
	};
	WORD rpar2;		/* Forced resident size in paras */
	DWORD asize;		/* Actual SIZE= in bytes */
	DWORD lsize;		/* Load size in bytes */
	DWORD isize;		/* Init size in bytes */
	BYTE preg;		/* Program region # (origin:1, 0 for low, */
	BYTE ereg;		/* ff if not specified) */
	LSEGFLAGS flags;	/* FLEXFRAME, etc. */
	WORD npara;		/* Size of interrupt block */
	BYTE grp;		/* Group (0=none, -1=MAX, -2=UMB) */
	BYTE filler;		/* ...to word boundary */
	WORD ownrhi;		/* Segment of high DOS owner */
	WORD instlo;		/* Segment of low DOS to instance */
	WORD instlen;		/* Length in paras of instlo */
} LSEGDATA;

typedef struct tagFileStats {
	SYSBUFH next;		/* Pointer to next record or 0 if end */
	char fname[13]; 	/* FILENAME.EXE,'\0' */
	DWORD fsize;		/* Size in bytes */
	union {
	  WORD	ftime;
	  struct {
	  WORD	fseconds:5,	/* Seconds / 2 (0-29) */
		fminutes:6,	/* Minutes (0-59) */
		fhours:5;	/* Hours (0-23) */
	  };
	};
	union {
	  WORD	fdate;
	  struct {
	  WORD	fday:5, 	/* Day of month (1-31) */
		fmonth:4,	/* Month (1-12) */
		fyear:7;	/* Year (1980-2099) */
	  };
	};
} FILESTATS;

/* This corresponds to the SUMFIT and SUBFIT structures in MAXIMIZE's */
/* QUALITAS.H */
typedef struct tagMaximizeBst {
	SYSBUFH next;		/* If 0, previous entry was last */
				/* and we should ignore this entry. */
				/* After reading, 0 indicates last entry. */
	WORD ipara;		/* max (ISIZE, LSIZE, RSIZE) */
	WORD rpara;		/* Resident size (RPARA) */
	union {
	  WORD epar0;		/* Environment size in paras (before) */
	  WORD reqsize; 	/* For 4B UMBs, size requested in paras */
	  WORD unused2; 	/* IPARA and EPAR0 not used for subsegs */
	};
	union {
	  WORD epar1;		/* Final environment size in paras */
	  EPAR1FLAGS ep1u;	/* Ancestor bitmap, etc. */
	  WORD unused3; 	/* EPAR1 not used for subsegs */
	};
	union {
	  BYTE preg;		/* Program or UMB region */
	  BYTE newreg;		/* New region for subsegs */
	};
	union {
	  BYTE ereg;		/* Environment region (ff for UMBs) */
	  BYTE oldreg;		/* Old region for subsegs */
	};
	union {
	  BYTE group;		/* Group: 0=none, -1=MAX, -2=UMB, -4=COMMAND */
	  BYTE stype;		/* @TOKEN_FILES, etc. from MAC.INC */
	};
	BYTE ord;		/* Order (unused for subsegs) */
	union {
	  LSEGFLAGS lflags;	/* For programs and UMBs */
	  WORD owner:2, 	/* 0=ExtraDOS, 1=386MAX */
		:14;		/* Unused */
	};
	BYTE subseg;		/* 1 for subsegments */
} MAXIMIZEBST;
#pragma pack()

/* These are separate because they aren't written out */
typedef struct _rawinfo {	/* Low-level system information structure */
	LISTLIST far *listlist; /* Pointer to list of lists */
	DDENTRY far *ddp;	/* Pointer to head of device driver chain */
} RAWINFO;

typedef struct _sysinfo {	/* Master system information structure */
	WORD	version;	/* Version of ASQ for/from snapshot file */

	WORD	umaplen;	/* Number of UMAP items */
	SYSBUFH umap;		/* Array of UMAP items */
	WORD	emaplen;	/* Number of extra UMAP items */
	SYSBUFH emap;		/* (MEMHOLE) Extra items for UMAP */
	WORD	hmaplen;	/* Number of items in hole map */
	SYSBUFH hmap;		/* (MEMHOLE) Array of memory holes */

	WORD	timelen;	/* Number of memory timing items */
	SYSBUFH timelist;	/* (TIMELIST) Memory timing list */

	WORD	romlen; 	/* Number of ROM list items */
	SYSBUFH romlist;	/* (ROMITEM) on-card ROM list */

	WORD	flexlen;	/* Number of Flexxed ROM items */
	SYSBUFH flexlist;	/* (FLEXROM) Flexxed ROM list */

	WORD	openlen;	/* Number of open file items */
	SYSBUFH openfiles;	/* Open files list */
	WORD	openfcbs;	/* Open fcbs count */

	WORD	envlen; 	/* Number of environment strings */
	SYSBUFH envstrs;	/* (char *) Pointer to array of env strings */
	WORD	cnfglen;	/* Number of lines in CONFIG.SYS */
	char	*pszCnfgsys;	/* Lines from CONFIG.SYS */
	WORD	autolen;	/* Number of lines in AUTOEXEC.BAT */
	char	*pszAutobat;	/* Lines from AUTOEXEC.BAT */
	WORD	proflen;	/* Number of lines in 386MAX.PRO */
	char	*pszMaxprof;	/* Lines from 386MAX.PRO */
	WORD	extradoslen;	/* Lines in EXTRADOS.PRO */
	char	*pszExtrados;	/* Lines from EXTRADOS.PRO */
	WORD	sysinilen;	/* Lines in SYSTEM.INI */
	char	*pszSysini;	/* Lines from SYSTEM.INI */

	WORD	ddlen;		/* Number of device driver entries */
	SYSBUFH ddlist; 	/* (DDENTRY) Device driver list */
	WORD	logdrv; 	/* Number of logical drives */

	WORD	doslen; 	/* Number of DOS data items */
	SYSBUFH dosdata;	/* (DOSDATA) Dos data area info */

	MCAID mcaid[MCASLOTS];	/* (mca_pos.h) MCA adapter IDs if PS/2 */
	SYSBUFH adf[MCASLOTS];	/* (ADFINFO) MCA adapter desc file info (adf.h) */

	struct _sysflags {	/* Control flags */
		int pc:1;	/* TRUE if PC or XT class machine */
		int xt:1;	/* TRUE if XT class machine */
		int at:1;	/* TRUE if AT class machine */
		int ps2:1;	/* TRUE if PS/2 including model 30 */
		int mca:1;	/* TRUE if MCA bus architecture */
		int eisa:1;	/* TRUE if EISA bus architecture */
		int pci:1;	/* TRUE if PCI bus */
		int pnp:1;	/* TRUE if Plug and Play functions available */
		int cmos:1;	/* TRUE if CMOS available */

		int max:1;	/* TRUE if 386MAX running */
		int ems:1;	/* TRUE if any EMS driver present */
		int lim4:1;	/* TRUE if EMS driver is LIM 4.0+ */
		int xms:1;	/* TRUE if XMS driver present */
		int readin:1;	/* TRUE if this data read from file */
		int cfg:1;	/* TRUE if we have a CONFIG.SYS file */
		int aut:1;	/* TRUE if we have a AUTOEXEC.BAT file */
		int mouse:1;	/* TRUE if mouse present */

		int game:1;	/* TRUE if game adapter present */
		int mov:1;	/* TRUE if MOVE'EM running */
		int gotwinver:1; /* TRUE if windowsver is valid */
	} flags;

	WORD romseg;		/* Segment addr of System Rom */
	WORD romsize;		/* Size of system ROM in paras */
	WORD bootdrv;		/* Drive number of boot drive */

	CPUPARM cpu;		/* CPU/FPU id parameters (cpu.h) */
	double mhz;		/* Estimated Mhz of CPU */
	WORD chipset;		/* Chip Set, if any */

	WORD dosver;		/* DOS version */
	char ioname[16];	/* Name of I/O kernel */
	char dosname[16];	/* Name of DOS kernel */
	char comname[16];	/* Name of DOS command shell */

	DWORD io_start; 	/* Flat address for start of IBMBIO */
	DWORD dos_start;	/* Flat address for start of IBMDOS */
	DWORD dev_start;	/* Flat address for start of IDDs */
	DWORD data_start;	/* Flat address for start of DOS data */
	DWORD dos_stackc;	/* Flat address of DOS stacks code area */
	DWORD dos_stackd;	/* Flat address of DOS stacks data area */
	DWORD data_end; 	/* Flat address for end of DOS data */

	WORD basemem;		/* How many Kb base memory memory total */
	WORD extmem;		/* How many Kb extended memory total */
	WORD extfree;		/* How many Kb extended memory free */

	WORD dpmi_ver;		/* DPMI version */
	BOOL dpmi_32bit;	/* TRUE if DPMI supports 32-bit programs */

	BIOSID biosid;		/* BIOS Identification info (biosid.h) */
	SYSBUFH biosmfr;	/* Name of BIOS manufacturer */
	SYSBUFH machname;	/* Specific machine name if known */

	WORD envsize;		/* Bytes total in master environment */
	WORD envused;		/* Bytes used in master environment */

	WORD nvideo;		/* Number of video adapters */
	VIDEO video[2]; 	/* Video adapter info */
	char sv_vendor[33];	/* SVGA vendor */
	char sv_model[33];	/* SVGA model */
	MOUSEINFO mouse;	/* Mouse info */
	WORD keyboard;		/* Keyboard type */

	WORD diskrom;		/* Addr of fixed disk ROM, if any */
	WORD diskromsize;	/* Size of fixed disk ROM, if any */

	EMSPARM emsparm;	/* EMS general parameters */
	SYSBUFH emshand;	/* (EMSHAND) EMS handle info */
	SYSBUFH emssize;	/* (WORD) EMS handle size info */
	SYSBUFH emsmap; 	/* (EMSMAP) EMS mapping info */

	XMSPARM xmsparm;	/* XMS parameters (xmsinfo.h) */
	WORD ems_xms;		/* KB of EMS+XMS available */

	CONFIG config;		/* DOS configuration settings */

	int dcache;		/* Disk cache status */
	DRIVEPARM fdrive[2];	/* Floppy drive parameters */
	DRIVEPARM hdrive[2];	/* Hard drive parameters */
	PARTTABLE hpart0[4];	/* Hard drive 0 partition table */
	PARTTABLE hpart1[4];	/* Hard drive 1 partition table */

	WORD nCDs;		/* Number of CD-ROM drives */
	WORD nFirstCD;		/* 0 = A:, etc. */

	int	nlowdos;	/* Number of low DOS memory items */
	SYSBUFH lowdos; 	/* (MACINFO) Pointer to low DOS memory allocation info */
	int	nhighdos;	/* Number of foreign or 386MAX high DOS memory items */
	SYSBUFH highdos;	/* (MACINFO) Pointer to foreign or 386MAX high DOS memory allocation info */
	int	nhighload;	/* Number of MOVE'EM high DOS items */
	SYSBUFH highload;	/* (MACINFO) Pointer to MOVE'EM high DOS allocation info */

	char snapfile[80];	/* Snapshot filespec */
	char snaptitle[40];	/* Snapshot title */
	WORD snapdate[3];	/* Snapshot date (mm, dd, yyyy) */
	WORD snaptime[3];	/* Snapshot time (hh, mm, ss) */

	WORD intmap[256];	/* Interrupt map */
	void far *vectors[256]; /* Copy of interrupt vectors */
	BIOSDATA biosdata;	/* Copy of BIOS data area */
	BYTE cmos[CMOS_SIZE];	/* Pointer CMOS data */

	WORD psp;		/* Effective Program Segment Prefix */
	WORD bufnext;		/* Next available byte in SysInfo buffer */
	WORD buflasth;		/* Handle of last block in SysInfo buffer */
	WORD buflastn;		/* Number of bytes in last block in SysInfo buffer */
	WORD buffree;		/* Free bytes in in SysInfo buffer */

	WORD MaximizeBestsize;	/* From MAXIMIZE.BST, paras moved high */
	SYSBUFH pszMaxdir;	/* Directory of MAX.SYS (w/ trailing BS) */
	SYSBUFH pLseg;		/* Start of LSEG chain */
	SYSBUFH pMaxBest;	/* Start of MAXIMIZE.BST chain */
	SYSBUFH pQFiles;	/* Start of Qualitas file stats */
	WINDOWSDATA WindowsData; /* Windows configuration */

	WORD pci_ver;		/* PCI BIOS version (BCD) or ffff if unknown */
				/* (AMI). Ex: 0204 for ver 2.04 */

	WORD wPnP_ver;		/* Plug and Play BIOS version (BCD) */
	WORD wNumNodes;		/* Number of Plug and Play device nodes */
	WORD wMaxNodeSize;	/* Size in bytes of largest device node */

	WORD cbNodeList;	/* Length in bytes of PnP node list */
	SYSBUFH pNodeList;	/* Plug and Play node list */

/* Typically (conceivably) we have 16-32 nodes.  Thus we're using at most */
/* 2560 bytes for descriptions. */
#define MAXPNP_DESC 80		/* Maximum PnP description length */
	SYSBUFH ppszPnPDesc;	/* char [ MAXPNP_DESC ][ wNumNodes ] */

} SYSINFO;

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

GLOBAL RAWINFO RawInfo;
GLOBAL SYSINFO *SysInfo
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL BYTE *SysInfoBuf
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL BOOL NoTestMem
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL NoTestEMS
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL NoTestDiskCache
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL NoTestVGA
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL BOOL GraphicsLogo
#ifdef GLINIT
= TRUE
#endif
;

GLOBAL BOOL SnowControl
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL int BootOverride
#ifdef GLINIT
= 0
#endif
;

GLOBAL BOOL NoTestGamePort
#ifdef GLINIT
= FALSE
#endif
;

int sysinfo_preinit(void);
int sysinfo_refresh(void);
int sysinfo_init(void *scratch,WORD nscratch);
int sysinfo_read(char *buf,WORD nbuf);
int sysinfo_look(char *name,char *title,int ntitle,WORD *date,WORD *time);
int sysinfo_write(char *name);
void sysinfo_purge(void);

/* Tue Nov 20 18:38:48 1990 alan:  work */
/* Mon Nov 26 17:06:09 1990 alan:  rwsystxt and other bugs */
/* Tue Nov 27 15:10:10 1990 alan:  bugs */
/* Wed Dec 19 17:12:46 1990 alan:  new mapping technique */
/* Tue Feb 19 15:41:09 1991 alan:  fix rom_find bug */
/* Wed Feb 20 15:42:33 1991 alan:  fix more bugs */
/* Sat Mar 09 12:06:02 1991 alan:  fix bugs */
/* Wed Mar 13 21:03:31 1991 alan:  fix bugs */
