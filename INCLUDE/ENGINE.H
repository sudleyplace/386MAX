/*' $Header:   P:/PVCS/MAX/INCLUDE/ENGINE.H_V   1.1   01 Feb 1996 10:24:22   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ENGINE.H								      *
 *									      *
 * Access to ASQ engine 						      *
 *									      *
 ******************************************************************************/

#ifndef ENGINE_INCLUDED
#define ENGINE_INCLUDED

#include <commdef.h>            /* Common definitions */
#include <cpu.h>

/* Important!  These are defined BOTH here and in info.h. The definitions
 * must match */

#define DWIDTH1 49	/* Width of normal display area on screen */
#define DWIDTH2 72	/* Width of wide display area on screen */

#define CONTIN_LINE   -1	/* Flag for continuation line */

#ifndef CODE_BASE
#define CODE_BASE     ' '       /* Encoding offset */
#endif

#ifndef IEXTRA
#define IEXTRA 2		/* How many extra bytes at front of line */
#endif

#ifndef CENTER_LINE
#define CENTER_LINE 126-CODE_BASE /* Format code to center line */
#endif

#ifndef SNAPTITLESIZE
#define SNAPTITLESIZE 40
#endif

/* Format ID codes */

#define MEMFMT0 0		/* Base of Memory formats */
#define MEMFMT1 (MEMFMT0+1)
#define MEMFMT2 (MEMFMT0+2)
#define MEMFMT3 (MEMFMT0+3)
#define MEMFMT4 (MEMFMT0+4)
#define MEMFMT5 (MEMFMT0+5)
#define MEMFMT6 (MEMFMT0+6)
#define MEMFMT7 (MEMFMT0+7)
#define MEMFMT8 (MEMFMT0+8)
#define MEMFMT9 (MEMFMT0+9)
#define MEMFMT10 (MEMFMT0+10)
#define MEMFMT11 (MEMFMT0+11)
#define MEMFMT12 (MEMFMT0+12)
#define MEMFMT13 (MEMFMT0+13)
#define MEMFMT14 (MEMFMT0+14)
#define MEMFMT15 (MEMFMT0+15)

#define CFGFMT0 MEMFMT15	/* Base of Config Formats */
#define CFGFMT1 (CFGFMT0+1)
#define CFGFMT2 (CFGFMT0+2)
#define CFGFMT3 (CFGFMT0+3)
#define CFGFMT4 (CFGFMT0+4)
#define CFGFMT5 (CFGFMT0+5)
#define CFGFMT6 (CFGFMT0+6)
#define CFGFMT7 (CFGFMT0+7)

#define HDWFMT0 CFGFMT7 	/* Base of Hardware Formats */
#define HDWFMT1 (HDWFMT0+1)
#define HDWFMT2 (HDWFMT0+2)
#define HDWFMT3 (HDWFMT0+3)
#define HDWFMT4 (HDWFMT0+4)
#define HDWFMT5 (HDWFMT0+5)
#define HDWFMT6 (HDWFMT0+6)
#define HDWFMT7 (HDWFMT0+7)
#define HDWFMT8 (HDWFMT0+8)
#define HDWFMT9 (HDWFMT0+9)
#define HDWFMT10 (HDWFMT0+10)

/* This list corresponds to InfoFunc[] function pointers in ENGINE.C */
typedef enum _infonum { 	/* Information code numbers */
	INFO_UNKNOWN,	/* Unknown value */
	INFO_MEM_SUMM,	/* Memory_Summary */
	INFO_MEM_LOW,	/* Memory_Low_DOS */
	INFO_MEM_HIGH,	/* Memory_High_DOS */
	INFO_MEM_ROM,	/* Memory_ROM_Scan */
	INFO_MEM_INT,	/* Memory_Interrupts */
	INFO_MEM_EXT,	/* Memory_Extended */
	INFO_MEM_EXP,	/* Memory_Expanded */
	INFO_MEM_EMS,	/* Memory_EMS_Usage */
	INFO_MEM_XMS,	/* Memory_XMS */
	INFO_MEM_TIME,	/* Memory_Timing */
	INFO_CFG_SUMM,	/* Config_Summary */
	INFO_CFG_CONFIG,	/* Config_CONFIG_SYS */
	INFO_CFG_AUTOEXEC,	/* Config_AUTOEXEC_BAT */
	INFO_CFG_386MAX,	/* Config_386MAX_PRO */
	INFO_CFG_EXTRADOS,	/* Config_ExtraDOS_PRO */
	INFO_CFG_SYSINI,	/* Config_SYSINI */
	INFO_CFG_QUALITAS,	/* Config_Qualitas */
	INFO_CFG_WINDOWS,	/* Config_Windows */
	INFO_HW_SUMM,	/* Hardware_Summary1 */
	INFO_HW_VIDEO,	/* Hardware_Video */
	INFO_HW_DRIVES, /* Hardware_Drives */
	INFO_HW_PORTS,	/* Hardware_Ports */
	INFO_HW_BIOS,	/* Hardware_BIOS_Detail */
	INFO_HW_CMOS,	/* Hardware_CMOS_Detail */
	INFO_SNAPSHOT,	/* Config_Snapshot */
	INFO_TOOBIG	/* Off the scale */
} INFONUM;

typedef enum _maxflag { /* Special 'max flag */
	MAX_NONE,	/* No special conditions are true */
	MAX_BLUE,	/* Is an MCA, could run Blue Max */
	MAX_386,	/* Is a 386, could run 386max */
	MAX_MOVE,	/* Is a NEAT or LIM 4, could run Move'em */
	MAX_TOOBIG	/* Overflow */
} MAXFLAG;

typedef enum _evalstate { /* Evaluation states */
	EVAL_NONE,	/* Unused */
	EVAL_CPUTYPE,
	EVAL_CPUCLOCK,
	EVAL_MOUSE,
	EVAL_GAME,
	EVAL_KEYBOARD,
	EVAL_BIOS,
	EVAL_BIOSMFR,
	EVAL_DOSLIST,
	EVAL_ROMS,
	EVAL_MACHID,
	EVAL_POS,
	EVAL_ASQPROF,
	EVAL_CMOS,
	EVAL_XMS,
	EVAL_EMS,
	EVAL_EMSXMS,
	EVAL_DISK,
	EVAL_CACHE,
	EVAL_DOS,
	EVAL_DOSINT,
	EVAL_DEVDRV,
	EVAL_OPENFILES,
	EVAL_BASEMEM,
	EVAL_LOWDOS,
	EVAL_HIGHDOS1,
	EVAL_FLEXROM,
	EVAL_HIGHDOS2,
	EVAL_HIGHDOS3,
	EVAL_DISKROM,
	EVAL_VIDROM,
	EVAL_CRC,
	EVAL_CPUSX,
	EVAL_ENVIRON,
	EVAL_CHIPSET,
	EVAL_TIME,
	EVAL_DOSDATA,
	EVAL_MAP,
	EVAL_CONFIG,
	EVAL_AUTOEXEC,
	EVAL_MAXPRO,
	EVAL_EXTRADOS,
	EVAL_SYSINI,
	EVAL_WINDOWS,
	EVAL_QUALITAS,
	EVAL_MCA,
	EVAL_ADF,
	EVAL_PNP,
	EVAL_CDROM,
	EVAL_DONE,
	EVAL_TOOBIG	/* Over the edge */
} EVALSTATE;

typedef enum _engctrl { /* Engine control opcodes */
	CTRL_NOOP,	/* No-op, unused */
	CTRL_PREINIT,	/* System info pre-init, no args, returns video flag */
	CTRL_SYSINIT,	/* System info init, no args */
	CTRL_SYSPURGE,	/* System info purge, no args */
	CTRL_SYSREAD,	/* Read sys info from file, ptr = file name */
	CTRL_SYSWRITE,	/* Write sys info to file, ptr = file name */
	CTRL_SETBUF,	/* Set up scratch buffer, ptr = buffer, num = sizeof(buffer) */
	CTRL_ISETUP,	/* Set up specific info block, ptr = ENGTEXT, num = INFONUM */
	CTRL_ISEEK,	/* Seek to specific line of info block, */
			/* ptr = ENGTEXT, num = ordinal from 0	*/
	CTRL_IFETCH,	/* Fetch next line of info block, ptr = ENGTEXT */
	CTRL_IPURGE,	/* Purge specific info block, ptr = ENGTEXT */
	CTRL_REPORT,	/* Report selected system info, ptr to struct */
	CTRL_GETTITLE,	/* Get snapshot title */
	CTRL_PUTTITLE,	/* Put snapshot title */
	CTRL_SNAPINFO,	/* Get info about unopened snapshot */
	CTRL_SETBOOT,	/* Set (override) boot drive */
	CTRL_TOOBIG	/* Over the edge */
} ENGCTRL;

typedef struct _engtext {	/* Engine (info) text return structure */
	HANDLE handle;		/* Handle to info block */
	int width;		/* How many chars in widest line */
	int length;		/* How many lines in block */
	unsigned current;	/* Current position for fetch */
	int nbuf;		/* Max chars in text buffer below */
	char *buf;		/* You decide how big */
} ENGTEXT;

typedef struct _engreport {	/* Engine report info */
	CPUPARM cpu;		/* cpu_type, fpu_type, and wei_flag live here */
	WORD dosver;		/* DOS version */
	int files;		/* FILES= from CONFIG.SYS */
	int buffers;		/* BUFFERS= from CONFIG.SYS */
	int envsize;		/* Bytes total in master environment */
	int envused;		/* Bytes used in master environment */
	int fcbx;		/* Current FCBS x setting */
	int fcby;		/* Current FCBS y setting */
	int stackx;		/* Current STACKS x setting */
	int stacky;		/* Current STACKS y setting */
	MAXFLAG maxflag;	/* 386 max recommendation flag */
	int print;		/* Is PRINT command resident */
	int fastopen;		/* Is FASTOPEN command resident */
	char config_sys[20];	/* Filespec for CONFIG.SYS */
	char *pszAutoexec_bat;	/* Filespec for AUTOEXEC.BAT */
	char *pszMax_pro;	/* Filespec for MAX profile */
	char *pszExtraDOS_pro;	/* Filespec for ExtraDOS profile */
	char *pszSYSINI;	/* Filespec for Windows SYSTEM.INI */
	char *pszWindir;	/* Windows directory (w/ trailing backslash) */
	WORD winver;		/* Version from WINVER.EXE */
	long ddbytes;		/* Device driver bytes loaded low */
	long tsrbytes;		/* TSR bytes loaded low */
} ENGREPORT;

typedef struct _engsnapinfo {	/* Engine report info */
	char name[80];		/* Name of snapshot file supplied */
	char title[40]; 	/* Snapshot title returned */
	WORD date[3];		/* Snapshot date returned, MM DD YYYY */
	WORD time[3];		/* Snapshot time returned, HH MM SS */
} ENGSNAPINFO;

int engine_control(		/* General control of engine */
	ENGCTRL ctrl,		/* Control opcode */
	void *ptr,		/* Pointer argument, depends on ctrl */
	WORD num);		/* Numeric argument, depends on ctrl */
/* Return:  0 if successful */

void reportEval(EVALSTATE state); /* Report evaluation state */


/* Special function to collect ADF path spec thru surface code. */
BOOL adf_spec(char *spec,int nspec,BOOL err);


#endif /* ENGINE_INCLUDED */
/* Tue Nov 20 18:37:56 1990 alan:  work */
/* Mon Nov 26 17:05:43 1990 alan:  rwsystxt and other bugs */
/* Thu Nov 29 13:01:11 1990 alan:  update from curt */
/* Fri Dec 28 11:13:06 1990 alan:  change version from 1.10 to 1.20 */
/* Sat Mar 09 12:05:49 1991 alan:  fix bugs */
/* Wed Mar 13 21:02:52 1991 alan:  fix bugs */
