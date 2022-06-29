/*' $Header:   P:/PVCS/MAX/ASQENG/SYSINFO.C_V   1.2   30 May 1997 14:58:42   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SYSINFO.C								      *
 *									      *
 * System information routines						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <conio.h>
#include <io.h>
#include <fcntl.h>
#include <dos.h>
#include <time.h>
#include <malloc.h>

#include <ver.h>	/* From the SDK */

#include <asqvers.h>		/* ASQ version number */
#include <asqshare.h>		/* CONFIG.SYS name */
#include <bioscrc.h>		/* BIOS crc calculator */
#include <dcache.h>		/* Disk cache functions */
#include <commfunc.h>		/* Utility functions */
#include <engine.h>		/* Engine access (to get eval codes) */
#include <gameport.h>		/* Hardware-based detection of game port */
#include <libtext.h>		/* Some text constants */
#include <mbparse.h>		/* MultiConfig parser */
#include <myalloc.h>		/* malloc/free covers */
#include <pnp.h>		/* Plug and play */
#include <svga_inf.h>		/* Super VGA info */
#include <video.h>		/* Video functions */

#include "businfo.h"            /* Bus information functions */
#include "mapinfo.h"            /* Map info functions */
#include "mfrlist.h"            /* BIOS manufacturer list */
#include "profile.h"            /* Profile functions */
#include "qtas.h"               /* Imports from Qualitas */

#define SYSINFO_C
#include "engtext.h"            /* Text strings */

#define OWNER
#include "sysinfo.h"            /* System info structures */

typedef struct _VS_VERSION {
    WORD wTotLen;
    WORD wValLen;
    char szSig[16];
    VS_FIXEDFILEINFO vffInfo;
} VS_VERSION;

/* Local variables */
static int PreInitDone = FALSE;

DRIVEPARM DisketteParms[] = {		/* Diskette parameters for common types */
	{ MSG4149, 0,  0, 0, 0 },	/* 0: Unknown */
	{ MSG4145, 2, 40,  9, 1 },	/* 1: 360k */
	{ MSG4146, 2, 80, 15, 1 },	/* 2: 1.2m */
	{ MSG4147, 2, 80,  9, 1 },	/* 3: 720k */
	{ MSG4148, 2, 80, 18, 1 },	/* 4: 1.44m */
	{ MSG4149, 2, 80, 18, 1 },	/* 5: Unknown */
	{ MSG4185, 2, 80, 36, 1 }	/* 6: 2.88m */
};

/* Local functions */

void get_curtime(void);
int get_bootdrv(void);
void get_machine(void);
void get_cmos(char *cmos,int ncmos);
void get_bios_mfr(SYSBUFH *biosp,SYSBUFH *machp);
int mfr_test(BIOSMFR *mfp);
WORD get_basemem(void);
WORD get_extfree(void);
int get_ems(void);
int get_xms(void);
WORD alloc_ems_xms(void);
int alloc_xms(WORD *total,WORD far *hbuf,WORD hmax);
void free_xms(WORD far *hbuf,WORD hcount);
int alloc_ems(WORD *total,WORD far *hbuf,WORD hmax);
void free_ems(WORD far *hbuf,WORD hcount);
void get_dpmi(void);
int get_video_info(void);
void fixup_video(void); /* Fix up video for XGA / 8514/a */
BOOL aox_check(void);	/* Check for AOX cards */
int lcl_get_mouse(void);
int get_game(void);
void get_drives(void);
void far *get_listlist(void);
void get_dosnames(char *ioname,char *dosname,char *comname);
void get_dosaddrs(void);
void get_ddlist(void);
void get_config_parms(void);
void get_roms(void);
WORD find_video_rom(WORD *psize,BOOL flex);
WORD find_disk_rom(WORD *psize,BOOL flex);
WORD rom_find(WORD start,WORD *size);
TIMELIST *add_time_group(TIMELIST *tp,int *groupnum,char *name);
void get_parttable(int drivenum,PARTTABLE *table,void far *scrat,WORD nscrat);
int get_driveparm(int drvnum,DRIVEPARM *parm);
void get_timelist(void);
void get_envstrs(void);
void get_open_files(void);
void get_dosdata(void);
BOOL find_3x_stacks(DOSDATA *item);
void get_4xdata(void);
void count_4x_fcbs(void);
void get_adf(void);
double get_cpuclock(void);
SYSBUFH get_profile(char *devline, int linetype);
BOOL get_disk_file(char *fname,BOOL useboot,char **ppszBuf,WORD *nbuf);
void add_filename(BYTE far *name);
void fixtabs(char *dst,char *src,int n);
int _cdecl dosdatcmp(const void *p1,const void *p2);
void get_windows_data (void);
void get_file_stats (char *dir, char **fspecs, SYSBUFH *pFiles);
void get_qualitas_data (void);
int GetPnPData( void );
void get_cdrom( void );

/* Filespecs for 386max directory.  These are all files that should */
/* be present in a mirrored directory as well, with the exception */
/* of 386LOAD.COM */
char *MaxFspecs[] = {
	"386max.sys",
	"386load.*",
	"*.lod",
	"*.vxd",
	"*.386",
	"bluemax.sys",
	"extrados.max",
	"move'em.*",
	NULL
};

char *WindowsFspecs[] = {
	"system\\dosx.exe",
	"system\\gdi.exe",
	"system\\krnl*.exe",
	"system\\user.exe",
	"win.*",
	"system\\win386.exe",
	"*.386",
	"system\\*.386",
	"*.drv",
	"system\\*.drv",
	NULL
};

/*
 *	sysinfo_preinit - system information initialization
 */

int sysinfo_preinit(void)
{
	/* This is separate from sysinfo_init so that it can be
	 * called by the surface before any screen painting.
	 */

	PreInitDone = TRUE;
	memset(SysInfo, 0, sizeof(SYSINFO));
	SysInfo->version = (ASQVER_MAJOR << 8) | (ASQVER_MINOR & 0xff);

	/* Read ASQ profile once and only once, before any other evaluations */
	reportEval(EVAL_ASQPROF);
	read_profile(TRUE,TRUE,"ASQ.PRO");
	read_profile(FALSE,TRUE,"ASQ.PRO");

	_fmemcpy(&SysInfo->vectors,FAR_PTR(0x0,0),sizeof(SysInfo->vectors));
	_fmemcpy(&SysInfo->biosdata,FAR_PTR(0x40,0),sizeof(SysInfo->biosdata));

	get_video_info();

	return (0);
}

/*
 *	sysinfo_refresh - refresh selected system information
 */

int sysinfo_refresh(void)
{
	/* This is for refreshing the portions of SysInfo that
	 * are constantly changing, like the cmos date & time.
	 */

	if (!SysInfo->flags.readin) {
		get_cmos(SysInfo->cmos,CMOS_TIME);
	}
	return 0;
}

/*
 *	sysinfo_init - collect system information
 */

int sysinfo_init(void *scrat,WORD nscrat)
{
	if (!PreInitDone) sysinfo_preinit();

	/* Set up the SysInfo buffer */
	SysInfoBuf = scrat;
	*(WORD *)SysInfoBuf = nscrat;
	SysInfo->buffree = nscrat-2;
	SysInfo->bufnext = 2;

	/* Get current date/time for snapshot */
	get_curtime();

	/* Low level stuff */
	reportEval(EVAL_CPUTYPE);
	check_cpu(&SysInfo->cpu);
	reportEval(EVAL_CPUCLOCK);
	SysInfo->mhz = get_cpuclock();

	reportEval(EVAL_MOUSE);
	SysInfo->psp = _psp;
	SysInfo->flags.mouse = lcl_get_mouse();

	if (!NoTestGamePort) {
		reportEval(EVAL_GAME);
		SysInfo->flags.game = (GameCount() ? 1 : 0);
	}
	else	SysInfo->flags.game = 0;

	reportEval(EVAL_KEYBOARD);
	SysInfo->keyboard = keyboard_id();

	reportEval(EVAL_BIOS);
	bios_id(&SysInfo->biosid);

	SysInfo->biosid.bus_flag |= (Is_IBM() & 1);
	SysInfo->romseg = Get_BIOS_Start(1);	/* Get start of compressed ROM */
	SysInfo->romsize = (WORD) (0x10000L - (DWORD)SysInfo->romseg);
	reportEval(EVAL_BIOSMFR);
	get_bios_mfr(&SysInfo->biosmfr,&SysInfo->machname);

	/* Normalize and filter the BIOS date */
	{
		int kk;
		char *p1,*p2;
		char temp[20];

		p1 = SysInfo->biosid.date;
		p2 = temp;
		for (kk = 0; kk < sizeof(SysInfo->biosid.date); kk++) {
			if (isdigit(*p1) || *p1 == '/') *p2++ = *p1;
			if ((p2 - temp) >= 8) break;
			p1++;
		}
		*p2 = '\0';
		strcpy(SysInfo->biosid.date,temp);
	}
	reportEval(EVAL_DOSLIST);
	RawInfo.listlist = get_listlist();
	SysInfo->dosver = (_osmajor << 8) | _osminor;
	reportEval(EVAL_ROMS);
	get_roms();

	SysInfo->diskrom = find_disk_rom(&SysInfo->diskromsize,FALSE);
	reportEval(EVAL_MACHID);
	/* Classify */
	if (Is_MCA()) {
		/* MCA machines */
		SysInfo->flags.mca = TRUE;
		SysInfo->flags.cmos = TRUE;
		SysInfo->flags.ps2 = Is_IBM ();
		reportEval(EVAL_POS);
		mca_pos(SysInfo->mcaid);
		fixup_video();
	}
	else	/* Non-MCA ps/2 machine (Tortuga, etc.) */
	  if ((SysInfo->biosid.bus_flag & 1) && Is_BCF()) {
		SysInfo->flags.ps2 = TRUE;
		SysInfo->flags.cmos = TRUE;
	  }
	else {
		switch (SysInfo->biosid.model) {
		case 0xFF:	/* PC */
		case 0xFD:	/* PC Jr */
			SysInfo->flags.pc = TRUE;
			break;
		case 0xFE:	/* PC XT */
		case 0xFB:	/* PC XT */
			SysInfo->flags.xt = TRUE;
			break;
		case 0xFC:
			if (SysInfo->biosid.submodel == 0x09) {
				/* PS/2 30-286 */
				SysInfo->flags.ps2 = TRUE;
			}
			else {
				/* PC AT or XT-286 */
				SysInfo->flags.at = TRUE;
			}
			SysInfo->flags.cmos = TRUE;
			break;
		case 0xFA:	/* PS/2 Model 30 */
			SysInfo->flags.ps2 = TRUE;
			SysInfo->flags.cmos = TRUE;
			break;
		case 0xF8:	/* PS/2 Model 40 - this one will return Is_BCF() true */
			if (SysInfo->biosid.model == 0x19) {
				/* PS/2 Model 40 */
				SysInfo->flags.ps2 = TRUE;
				SysInfo->flags.cmos = TRUE;
				break;
			}
		default:
			if (SysInfo->cpu.cpu_type < CPU_80286) SysInfo->flags.xt = TRUE;
			else {
				SysInfo->flags.at = TRUE;
				SysInfo->flags.cmos = TRUE;
			}
		}

		/* bus_flag gets OR'ed with 0x02 in biosid.asm */
		if (SysInfo->biosid.bus_flag & 0x02) SysInfo->flags.eisa = TRUE;

		/* 0x04 is reserved for PCI, but we need not set it ... */
		if (SysInfo->biosid.bus_flag & 0x04) SysInfo->flags.pci  = TRUE;

	}

	/* Anybody can bridge just about any two or more bus */
	/* architectures.  Whether they'd want to do so is another */
	/* matter, but we'll at least protect PS/2's from probing */
	/* and skip these tests... */
	if (!SysInfo->flags.ps2) {

		WORD wPCIRes = is_pci();
		if (wPCIRes) SysInfo->flags.pci = TRUE;
		SysInfo->pci_ver = wPCIRes;

	} /* Not IBM PS/2 */

#if 0 /* Debug code for testing ASQ profiles */
	SysInfo->mcaid[1].aid = 1;
	SysInfo->mcaid[1].pos[0] = 0x13;
	SysInfo->mcaid[1].pos[1] = 0xfc;
	SysInfo->mcaid[1].pos[2] = 0x3f;
	SysInfo->mcaid[1].pos[3] = 0xc0;
#endif
	if (SysInfo->flags.cmos) {
		reportEval(EVAL_CMOS);
		get_cmos(SysInfo->cmos,CMOS_SIZE);
	}

	if (SysInfo->flags.at || SysInfo->flags.mca) {
		reportEval(EVAL_XMS);
		get_xms();
		if (SysInfo->xmsparm.flag == 0) {
			SysInfo->flags.xms = TRUE;
		}

		SysInfo->extfree = get_extfree();
		SysInfo->extmem = *(WORD *)(SysInfo->cmos+0x17);

		get_dpmi();
	}

	if (!NoTestEMS) {
		/* Get EMS info */
		reportEval(EVAL_EMS);
		if (!get_ems()) goto bailout;
	}

	if (SysInfo->flags.ems && SysInfo->flags.xms) {
		reportEval(EVAL_EMSXMS);
		SysInfo->ems_xms = alloc_ems_xms();
	}

	/* Disk info */
	reportEval(EVAL_DISK);
	get_drives();
	if (!NoTestDiskCache) {
		reportEval(EVAL_CACHE);
		save_dcvid ();
		SysInfo->dcache = dcache_active("ASQ.TST", 10240, 8*18);
		rest_dcvid ();
		unlink("ASQ.TST");
	}
	else	SysInfo->dcache = -1;

	/* CD-ROM drive(s) */
	reportEval( EVAL_CDROM );
	get_cdrom();

	/* DOS info */
	reportEval(EVAL_DOS);
	SysInfo->bootdrv = get_bootdrv();
	get_dosnames(SysInfo->ioname,SysInfo->dosname,SysInfo->comname);
	reportEval(EVAL_DOSINT);
	get_dosaddrs();
	reportEval(EVAL_DEVDRV);
	get_ddlist();
	reportEval(EVAL_OPENFILES);
	get_open_files();
	reportEval(EVAL_BASEMEM);
	SysInfo->basemem = get_basemem();

	/* Call Qualitas code */
	qtas_init();

	if (SysInfo->flexlen > 0) {
		WORD kk;
		if (!SysInfo->diskrom) {
			reportEval(EVAL_DISKROM);
			SysInfo->diskrom = find_disk_rom(&SysInfo->diskromsize,TRUE);
		}
		for (kk = 0; kk < SysInfo->nvideo; kk++) {
			if (!SysInfo->video[kk].rom) {
				reportEval(EVAL_VIDROM);
				SysInfo->video[kk].rom =
					find_video_rom(&SysInfo->video[kk].rsize,TRUE);
			}
		}
	}
	if (SysInfo->cpu.win_ver < 0x300 &&
	    (SysInfo->flags.max || !SysInfo->cpu.vir_flag)) {
		/* 386MAX present, or not in virtual mode, Get BIOS CRC */
		long result;

		reportEval(EVAL_CRC);
		result = Get_BIOSCRC ();
		if (HIWORD(result)) {
			SysInfo->biosid.crc = LOWORD(result);
			SysInfo->biosid.ncrc = (BYTE)(SysInfo->romsize / 64);
		}
		else {
			SysInfo->biosid.crc = 0;
			SysInfo->biosid.ncrc = 0;
		}
		/* Also check for 386SX */
		if (SysInfo->cpu.cpu_type == CPU_80386) {
			reportEval(EVAL_CPUSX);
			SysInfo->cpu.cpu_type = check_cpusx();
			if (SysInfo->cpu.cpu_type == CPU_80386SX &&
				SysInfo->cpu.fpu_type == FPU_80387) {
			  SysInfo->cpu.fpu_type = FPU_80387SX;
			} /* Assume it's an 80387SX */
		}
	}

	/* MC Parameters */
	if (SysInfo->flags.mca) {
		reportEval(EVAL_MCA);
		get_adf();
	}

	/* FIXME Collect data on PCI adapters - but how? */

	/* Collect Plug'n'Play data */
	if (is_pnp()) {

		SysInfo->flags.pnp = TRUE;
		reportEval( EVAL_PNP );

		if (!GetPnPData()) {
			SysInfo->flags.pnp = FALSE;
		} /* Failed to get data */

	} /* Plug and Play BIOS */

	/* FIXME Collect data on PCMCIA slots */

	/* Collect environment strings, etc. */
	reportEval(EVAL_ENVIRON);
	get_envstrs();
	if (SysInfo->cpu.win_ver < 0x300 && !aox_check()) {
		reportEval(EVAL_CHIPSET);
		SysInfo->chipset = check_chipset();
	}

	/* Memory Timing */
	reportEval(EVAL_TIME);
	get_timelist();
	reportEval(EVAL_DOSDATA);
	/* Dos data info */
	if (SysInfo->dosver >= 0x400) {
		/* Short circuit for DOS 4.0+ */
		get_4xdata();
	}
	else	get_dosdata();

	/* **** read_profile used to be here **** */

	/* Memory map */
	reportEval(EVAL_MAP);
	make_umap(FALSE);

	/* Config */
	reportEval(EVAL_CONFIG);
	get_config_parms();
	SysInfo->flags.cfg = get_disk_file(CONFIG_SYS,TRUE,&SysInfo->pszCnfgsys,&SysInfo->cnfglen);

	reportEval(EVAL_AUTOEXEC);
	SysInfo->flags.aut = get_disk_file(sysbuf_ptr (SysInfo->config.startupbat),FALSE,&SysInfo->pszAutobat,&SysInfo->autolen);

	if (SysInfo->config.maxpro) {
		reportEval(EVAL_MAXPRO);
		get_disk_file(sysbuf_ptr(SysInfo->config.maxpro),
			FALSE,&SysInfo->pszMaxprof,&SysInfo->proflen);
	}

	if (SysInfo->config.extradospro) {
		reportEval (EVAL_EXTRADOS);
		get_disk_file (sysbuf_ptr (SysInfo->config.extradospro),
			FALSE, &SysInfo->pszExtrados, &SysInfo->extradoslen);
	} /* ExtraDOS.PRO */

	/* Windows: First we need to find WINVER.EXE and set the */
	/*	directory, then we can read SYSTEM.INI */
	reportEval (EVAL_WINDOWS);
	get_windows_data ();

	if (SysInfo->WindowsData.sysininame) {
		reportEval (EVAL_SYSINI);
		get_disk_file (sysbuf_ptr (SysInfo->WindowsData.sysininame),
			FALSE, &SysInfo->pszSysini, &SysInfo->sysinilen);
	} /* SYSTEM.INI */

	/* Qualitas info - LSEG data and file size/time/date */
	reportEval (EVAL_QUALITAS);
	get_qualitas_data ();

	/* No errors */
	/*engine_debug(2,MSG4001);*/

	reportEval(EVAL_DONE);

	{
		WORD used;

		used = nscrat - sysbuf_avail(0);
#ifdef CVDBG
		fprintf(stderr,"used = %u\n",used);
#endif
		SysInfoBuf = my_malloc(used);
		if (!SysInfoBuf) {
			nomem_bailout(301);
		}
		memcpy(SysInfoBuf,scrat,used);
	}
	return 0;
bailout:
	return 1;
}

/*
 *	sysinfo_purge - purge system info data
 */

void sysinfo_purge(void)
{
	if (SysInfoBuf) {
		my_free(SysInfoBuf);
		SysInfoBuf = NULL;
	}
	if (SysInfo->pszCnfgsys) my_free (SysInfo->pszCnfgsys);
	if (SysInfo->pszAutobat) my_free (SysInfo->pszAutobat);
	if (SysInfo->pszMaxprof) my_free (SysInfo->pszMaxprof);
	if (SysInfo->pszExtrados) my_free (SysInfo->pszExtrados);
	if (SysInfo->pszSysini) my_free (SysInfo->pszSysini);

	memset(SysInfo,0,sizeof(SYSINFO));
	PreInitDone = FALSE;
}

/*
 *	get_curtime - get current date/time for snapshot
 */

void get_curtime(void)
{
	time_t t;
	struct tm *tms;

	time(&t);
	tms = localtime(&t);

	SysInfo->snapdate[0] = tms->tm_mon+1;
	SysInfo->snapdate[1] = tms->tm_mday;
	SysInfo->snapdate[2] = tms->tm_year+1900;
	SysInfo->snaptime[0] = tms->tm_hour;
	SysInfo->snaptime[1] = tms->tm_min;
	SysInfo->snaptime[2] = tms->tm_sec;
}

/*
 *	get_bootdrv - get (our idea of) boot drive
 */

#pragma optimize ("leg",off)
int get_bootdrv(void)
{
	if (BootOverride) {
		/* Short Circuit */
		return toupper(BootOverride) - 'A';
	}

	if (_osmajor >= 4) {
		/* DOS 4.00+, we can ask the system */
		int rtn;
		_asm {
			mov ax,3305h
			int 21h 	; Do the function
			mov dh,0	; Make a word out of the return
			dec dx		; minus 1
			mov rtn,dx	; ..and store it
		}
		return rtn;
	}

	{	/* Try COMSPEC */
		char drive;
		char *p = getenv("COMSPEC");

		if (p && strlen(p) > 1 && isalpha(p[0]) && p[1] == ':') {
			drive = (char)toupper(p[0]);
		}
		if (drive == 'A' || drive == 'C') {
			return drive - 'A';
		}
	}

	/* Last ditch */
	if (SysInfo->hdrive[0].heads) {
		/* If they have a hard disk, it's drive C: */
		return 2;
	}
	/* else, it's drive A: */
	return 0;
}
#pragma optimize ("",on)

/*
 *	get_cmos - read entire CMOS region
 */

void get_cmos(char *cmos,int ncmos)
{
	int kk; 	/* Loop counter */

	for (kk=0; kk < ncmos; kk++) {
		outp(CMOS_CTRL,kk);
		cmos[kk] = (BYTE) inp(CMOS_DATA);
	}
}

/*
 *	get_bios_mfr - (try to) determine BIOS / machine manufacturer
 */

void get_bios_mfr(SYSBUFH *biosp,SYSBUFH *machp)
{
	BIOSMFR *mfp;	/* Pointer to manufacturer entry */

	/* Part I:  Primary list */
	for (mfp = MfrList1; mfp->what; mfp++) {
		if (mfr_test(mfp)) break;
	}

	sysbuf_store(biosp,mfp->whobios,0);
	*machp = 0;

	if (strcmp(mfp->whobios,MSG4120) == 0 && SysInfo->biosid.i15_ptr) {
		/* Very special case for AST machines */
		char far *p;

		p = SysInfo->biosid.i15_ptr + (*(int far *)SysInfo->biosid.i15_ptr) + 2;
		switch (*p) {
		case 0x01:
			sysbuf_store(machp,MSG4121,0);
			break;
		case 0x08:
			sysbuf_store(machp,MSG4122,0);
			break;
		case 0x09:
			sysbuf_store(machp,MSG4123,0);
			break;
		case 0x0B:
			sysbuf_store(machp,MSG4124,0);
			break;
		case 0x0D:
			sysbuf_store(machp,MSG4125,0);
			break;
		}
	}
	else if (stricmp(mfp->whobios,MSG4183) == 0) {
		/* Compaq:  another special case */
		char *p;
		char temp[32];

		p = cpu_textof ( &SysInfo->cpu );
		if (!stricmp (p, NATL_UNKNOWN)) {
			if (_fmemcmp(FAR_PTR(0xF000,0xFFE8),"  ",2) == 0) p = MSG4184;
			else p = NULL;
		} /* CPU unknown */

		strcpy(temp,MSG4183);
		if (p) {
			strcat(temp," ");
			strcat(temp,p);
		}
		sysbuf_store(machp,temp,0);
	}

	if (*machp) return;

	/* Part II:  Secondary list */
	if (*mfp->whatmach == '@') {
		BIOSMFR *mfp0 = mfp;

		for (mfp = MfrList2; mfp->what; mfp++) {
			if (strcmp(mfp0->whatmach,mfp->whobios) == 0 &&
			    mfr_test(mfp)) {
				sysbuf_store(machp,mfp->whatmach,0);
				return;
			}
		}
	}
	else if (mfp->whatmach) {
		sysbuf_store(machp,mfp->whatmach,0);
	}
}

/*
 *	mfr_test - test for a given manufacturer
 */

int mfr_test(BIOSMFR *mfp)
{
	WORD here;	/* Scratch segment address */
	WORD there;	/* Scratch segment address */
	int howmuch;	/* How much text to look for */
	BYTE far *p;	/* Scratch pointer */

	/* Hey!  Don't change this to SysInfo->romseg */
	p = FAR_PTR(0xF000,0);

	here = mfp->where;
	there = mfp->where + mfp->shift;
	howmuch = strlen(mfp->what);
	do {
		if (_fmemcmp(p+here,mfp->what,howmuch) == 0) {
			return TRUE;
		}
		here++;
	} while ( here < there );
	return FALSE;
}

/*
 *	get_basemem - return base memory in KB
 */

WORD get_basemem(void)
{
	if (SysInfo->cmos) {
		/* From CMOS */
		return *(WORD *)(SysInfo->cmos+0x15);
	}
	else {
		/* else, from INT 12H */
		union REGS regs;
		struct SREGS segs;

		segread(&segs);
		int86x(0x12,&regs,&regs,&segs);
		return regs.x.ax;
	}
}

/*
 *	get_extfree - return available extended memory in KB
 */

WORD get_extfree(void)
{
	union REGS regs;
	struct SREGS segs;

	segread(&segs);
	regs.h.ah = 0x88;
	int86x(0x15,&regs,&regs,&segs);
	return regs.x.ax;
}

/*
 *	get_ems - get information about EMS memory
 */

BOOL get_ems(void)
{
	if (emsparm(&SysInfo->emsparm) != 0) {
		/* No EMS present */
		return TRUE;
	}

	SysInfo->flags.ems = 1;
	if (SysInfo->emsparm.version >= 0x40) SysInfo->flags.lim4 = TRUE;
	if (SysInfo->flags.lim4 && SysInfo->emsparm.acthand) {
		SysInfo->emshand = sysbuf_alloc(SysInfo->emsparm.acthand * sizeof(EMSHAND));
		if (!SysInfo->emshand) return FALSE;
		emshand(sysbuf_ptr(SysInfo->emshand));
	}

	if (SysInfo->flags.lim4 && SysInfo->emsparm.mpages) {
		SysInfo->emsmap = sysbuf_alloc(SysInfo->emsparm.mpages * sizeof(EMSMAP));
		if (!SysInfo->emsmap) return FALSE;
		emsmap(sysbuf_ptr(SysInfo->emsmap));
	}

	if (SysInfo->emsparm.acthand) {
		WORD kk;
		WORD *emssize;

		SysInfo->emssize = sysbuf_alloc(SysInfo->emsparm.acthand * sizeof(WORD));
		if (!SysInfo->emssize) return FALSE;
		emssize = sysbuf_ptr(SysInfo->emssize);
		for (kk = 0; kk < SysInfo->emsparm.acthand; kk++) {
			emssize[kk] = emshsize(kk);
		}
	}
	return TRUE;
}

/*
 *	get_xms - get information about XMS memory
 */

int get_xms(void)
{
	xmsparm(&SysInfo->xmsparm);
	/* 0xffff UMB available apparently means none available */
	if (SysInfo->xmsparm.umbavail == 0xffff) {
		SysInfo->xmsparm.umbavail = 0;
		SysInfo->xmsparm.umbtotal = 0;
	}

	/* My version of 386max 5.00 had a bug in allocating
	 * UMBs that leaves 64 or 48 byte UMB areas lying
	 * around, typically one per alloc/free operation,
	 * so this code may give bogus results.
	 */
	if (SysInfo->xmsparm.flag == 0 && SysInfo->xmsparm.umbavail) {

		SysInfo->xmsparm.umbtotal = umbtavail ();

	}

	return 0;
}

/*
 *	alloc_ems_xms - do XMS / EMS allocation test
 */

WORD alloc_ems_xms(void)
{
	WORD *hbuf;
	WORD hmax;
	WORD ex1;
	WORD ex2;
	WORD xtotal;
	WORD etotal;
	WORD ecount;
	WORD xcount;
	SYSBUFH hscrat;

	hmax = sysbuf_avail(10*sizeof(WORD)) / sizeof(WORD);

	hscrat = sysbuf_alloc(hmax);
	hbuf = sysbuf_ptr(hscrat);

	ecount = alloc_ems(&etotal,hbuf,hmax);
	xcount = alloc_xms(&xtotal,hbuf+ecount,hmax-ecount);
	ex1 = etotal+xtotal;
	free_xms(hbuf+ecount,xcount);
	free_ems(hbuf,ecount);

	xcount = alloc_xms(&xtotal,hbuf,hmax);
	ecount = alloc_ems(&etotal,hbuf+xcount,hmax-xcount);
	ex2 = etotal+xtotal;
	free_ems(hbuf+xcount,ecount);
	free_xms(hbuf,xcount);

	sysbuf_free(hscrat);

	return ((ex1 < ex2) ? ex1 : ex2);
}

/*
 *	alloc_xms - allocate all available XMS (EMB) memory
 */

int alloc_xms(WORD *total,WORD far *hbuf,WORD hmax)
{
	WORD hcount = 0;
	WORD nkb;

	*total = 0;

	nkb = SysInfo->xmsparm.embavail;
	while (nkb > 0) {
		/* Allocate EMBs until failure */
		hbuf[hcount] = emballoc(nkb);
		if (hbuf[hcount]) {
			hcount++;
			if (hcount > hmax) break;
			*total += nkb;
		}
		else {
			nkb /= 2;
		}
	}
	return hcount;
}

/*
 *	free_xms - free all the XMS (EMB) memory we allocated
 */

void free_xms(WORD far *hbuf,WORD hcount)
{
	while (hcount > 0) {
		hcount--;
		embfree(hbuf[hcount]);
	}
}

/*
 *	alloc_ems - allocate all available EMS memory
 */

int alloc_ems(WORD *total,WORD far *hbuf,WORD hmax)
{
	WORD hcount = 0;
	WORD npages;

	*total = 0;

	npages = SysInfo->emsparm.avail;
	while (npages > 0) {
		/* Allocate EMS pages until failure */
		hbuf[hcount] = emsalloc(npages);
		if (hbuf[hcount]) {
			hcount++;
			if (hcount > hmax) break;
			*total += npages;
		}
		else {
			npages /= 2;
		}
	}
	/* Convert pages to kb */
	*total *= 16;
	return hcount;
}

/*
 *	free_ems - free all the XMS (EMB) memory we allocated
 */

void free_ems(WORD far *hbuf,WORD hcount)
{
	while (hcount > 0) {
		hcount--;
		emsfree(hbuf[hcount]);
	}
}

/*
 *	get_dpmi - get information about DPMI
 */

#pragma optimize ("leg",off)
void get_dpmi(void)
{
	WORD version = 0;
	BOOL bit32 = 0;

	_asm {
		mov ax,1687h	/* Magic cookie */
		int 2fh 	/* Multiplex interrupt */
		or  ax,ax	/* AX == 0 means success */
		jnz nogo
		mov version,dx	/* Major, minor version numbers */
		and bx,1	/* BX.0 == 32-bit support */
		mov bit32,bx
	nogo:
	}

	SysInfo->dpmi_ver = version;
	SysInfo->dpmi_32bit = bit32;
}
#pragma optimize ("",on)

/*
 *	get_video_info - get information about video subsystems
 */

int get_video_info(void)
{
	int kk; 		/* Loop counter */
	int egamem;		/* KB of EGA memory */
	int currmode;		/* Current video mode */
	long vrtn;		/* Return value from VideoID */
	VIDEO *vp;		/* Pointer to video info structure */
	VIDEOID vid[2]; 	/* Video ID data */
	char _far *pp;		/* Scratch */

	vrtn = VideoID(vid,sizeof(vid)/sizeof(VIDEOID));
	egamem = (int)(vrtn & 0xffff);
	currmode = (int)((vrtn >> 16) & 0xffff);

	memset(SysInfo->video,0,2*sizeof(VIDEO));
	vp = SysInfo->video;
	for (kk = 0; kk < 2; kk++,vp++) {
		vp->acode = vid[kk].adapter;
		vp->dcode = vid[kk].display;
		switch (vp->acode) {
		case ADAPTERID_MDA:		/* Monochrome display adapter */
			strcpy(vp->name,MSG4126);
			strcpy(vp->mode,MSG4127);
			vp->text = 0xB000;
			vp->tsize = 0x800;
			vp->osize = 4;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_CGA:		/* Color Graphics adapter */
			strcpy(vp->name,MSG4128);
			strcpy(vp->mode,MSG4129);
			vp->text = 0xB800;
			vp->tsize = 0x800;
			vp->osize = 16;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_EGA:		/* Enhanced Graphics adapter */
			strcpy(vp->name,MSG4130);
			strcpy(vp->mode,
				vp->dcode == DISPLAYID_MDA ? MSG4131 : MSG4132);
			vp->text = 0xB800;
			vp->tsize = 0x800;
			vp->graph = 0xA000;
			vp->gsize = 0x1000;
			vp->rom =
				find_video_rom(&vp->rsize,FALSE);
			vp->osize = egamem;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_MCGA:	/* Multi Color Graphics Array */
			strcpy(vp->name,MSG4133);
			strcpy(vp->mode,
				vp->dcode == DISPLAYID_PS2MONO ? MSG4134 : MSG4135);
			vp->text = 0xB800;
			vp->tsize = 0x800;
			vp->graph = 0xA000;
			vp->gsize = 0x1000;
			vp->rom =
				find_video_rom(&vp->rsize,FALSE);
			vp->osize = 64;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_VGA:		/* Video Graphics Array */
			strcpy(vp->name,MSG4136);

			if (!NoTestVGA) {
			 pp = SVGA_VENDORID(-1);
			 /* While not strictly necessary for the vendor, */
			 /* we may need to truncate the model name as the */
			 /* increasingly popular VESA BIOSes may return */
			 /* a pointer to an 80-character+ string. */
#define SVVENDORSIZE sizeof(SysInfo->sv_vendor)
#define SVMODELSIZE sizeof(SysInfo->sv_model)
			 if (pp && _fstricmp(pp,"*Unknown*") != 0) {
				_fstrncpy(SysInfo->sv_vendor,pp,SVVENDORSIZE-1);
				SysInfo->sv_vendor[SVVENDORSIZE-1] = '\0';
				strcpy(vp->name,MSG4188);
			 }
			 pp = SVGA_MODELID(-1);
			 if (pp && _fstricmp(pp,"*Unknown*") != 0) {
				_fstrncpy(SysInfo->sv_model,pp,SVMODELSIZE-1);
				SysInfo->sv_model[SVMODELSIZE-1] = '\0';
			 }

			 vp->osize = SVGA_MEMSIZE();

			} /* SVGA test enabled */
			else	vp->osize = 0xffff;

			strcpy(vp->mode,
				vp->dcode == DISPLAYID_PS2MONO ? MSG4137 : MSG4138);
			vp->text = 0xB800;
			vp->tsize = 0x800;
			vp->graph = 0xA000;
			vp->gsize = 0x1000;
			vp->rom =
				find_video_rom(&vp->rsize,FALSE);
			/*if (vp->osize == -1) vp->osize = 256;*/
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_HGC:		/* Hercules Graphics Card */
			strcpy(vp->name,MSG4139);
			strcpy(vp->mode,MSG4140);
			vp->text = 0xB000;
			vp->tsize = 0x1000;
			vp->graph = 0xB000;
			vp->gsize = 0x1000;
			vp->rom = 0;
			vp->osize = 64;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_HGCPLUS: /* Hercules Graphics Card Plus */
			strcpy(vp->name,MSG4141);
			strcpy(vp->mode,MSG4142);
			vp->text = 0xB000;
			vp->tsize = 0x1000;
			vp->graph = 0xB000;
			vp->gsize = 0x1000;
			vp->rom = 0;
			vp->osize = 64;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		case ADAPTERID_INCOLOR: /* Hercules InColor Card */
			strcpy(vp->name,MSG4143);
			strcpy(vp->mode,MSG4144);
			vp->text = 0xB000;
			vp->tsize = 0x1000;
			vp->graph = 0xB000;
			vp->gsize = 0x1000;
			vp->rom = 0;
			vp->osize = 64;
			vp->cols = 80;
			vp->rows = 25;
			SysInfo->nvideo++;
			break;
		}
	}
	if (SysInfo->video[0].cols > SysInfo->biosdata.crt_cols) {
		SysInfo->video[0].cols = SysInfo->biosdata.crt_cols;
	}
	if (SysInfo->video[0].acode == ADAPTERID_EGA ||
	    SysInfo->video[0].acode == ADAPTERID_VGA) {
		if (SysInfo->video[0].rows < (WORD)SysInfo->biosdata.scrn_rows+1) {
			SysInfo->video[0].rows = SysInfo->biosdata.scrn_rows+1;
		}
	}
	if (SysInfo->video[0].dcode == DISPLAYID_MDA ||
	    SysInfo->video[0].dcode == DISPLAYID_PS2MONO) return 0;
	else if (currmode == 2) return 0;
	return 1;
}

void fixup_video(void)	/* Fix up video for XGA / 8514/a */
{
	int kk;

	/* Check for XGA or 8514/a */
	if (SysInfo->video[0].acode == ADAPTERID_VGA && SysInfo->flags.mca) {
		for (kk = 1; kk < MCASLOTS; kk++) {
			if (SysInfo->mcaid[kk].aid == 0x8FDB) {
				/* XGA */
				strcpy(SysInfo->video[0].name,MSG4186);
			}
			else if (SysInfo->mcaid[kk].aid == 0xEF7F) {
				/* 8514/a */
				strcpy(SysInfo->video[0].name,MSG4187);
			}
		}
	}
}

BOOL aox_check(void)	/* Check for AOX cards */
{
	int kk;

	if (SysInfo->flags.mca) {
		for (kk = 1; kk < MCASLOTS; kk++) {
			if (SysInfo->mcaid[kk].aid == 0x006E ||
			    SysInfo->mcaid[kk].aid == 0x006F) {
				return TRUE;
			}
		}
	}
	return FALSE;
}

/*
 *	lcl_get_mouse - get mouse info if mouse present
 */

#pragma optimize ("leg",off)
int lcl_get_mouse(void)
{
	WORD mouver;
	BYTE moutype;
	BYTE irq;

	_asm {
		mov ax,0024h	; Get mouse information
		xor bx,bx	; Set return registers to known state
		xor cx,cx
		int 33h
		mov moutype,ch	; Save type
		mov irq,cl	; Save IRQ number
		mov mouver,bx	; Save version
	}
	SysInfo->mouse.version = mouver;
	if (moutype > MOUTYPE_NONE && moutype < MOUTYPE_TOOBIG) {
		SysInfo->mouse.type = moutype;
	}
	if (moutype != MOUTYPE_PS2) SysInfo->mouse.irq = irq;
	if (SysInfo->mouse.type) return 1;

	/* Try Int 15h AX=C204: get mouse type (returns device type in BH) */
	moutype = 0;
#if 0 // Don't use this - ROMSRCH has not been exercising this call !!!
	_asm {
		mov ax,0xC204	; Get type
		int 0x15	; Return AH=0, CF=0 if successful
		jc no_mouse	; Jump if failed

		or ah,ah	; AH=0 if successful
		jnz no_mouse	; Jump if failed

		cmp bh,1	; Is the type 0?
		adc bh,0	; Force it non-zero
		mov moutype,bh	; Save type
no_mouse:
		;
	}

	if (moutype) {
#else
	if (SysInfo->biosdata.equip_flag & 0x0004) {
#endif
		SysInfo->mouse.type = MOUTYPE_PS2;
		SysInfo->mouse.version = 0; // Unknown
		SysInfo->mouse.irq  = 0;
		return 1;
	}
	return 0;
}

/*
 *	get_drives - get diskette and hard disk drive parameters
 */

void get_drives(void)
{
	int ndrv;	/* How many drives */
	WORD nbytes;
	SYSBUFH bufh;
	void *bufp;

	ndrv = get_driveparm(0,&SysInfo->fdrive[0]);
	if (ndrv > 1) get_driveparm(1,&SysInfo->fdrive[1]);

	ndrv = get_driveparm(0x80,&SysInfo->hdrive[0]);

	nbytes = sysbuf_avail(512);

	bufh = sysbuf_alloc(nbytes);
	bufp = sysbuf_ptr(bufh);

	if (ndrv > 1) {
		get_driveparm(0x81,&SysInfo->hdrive[1]);
	}
	if (ndrv > 0) {
		get_parttable(0,SysInfo->hpart0,bufp,nbytes);
	}
	if (ndrv > 1) {
		get_driveparm(0x81,&SysInfo->hdrive[1]);
		get_parttable(1,SysInfo->hpart1,bufp,nbytes);
	}
	sysbuf_free(bufh);
}

/*
 *	get_parttable - get hard drive partition table
 */

void get_parttable(int drivenum,PARTTABLE *table,void far *scrat,WORD nscrat)
{
	struct SREGS sregs;
	union REGS regs;

	memset(table,0,4 * sizeof(PARTTABLE));
	if (nscrat < 512) return;

	segread(&sregs);	/* get ds */

	regs.x.ax = 0x201;	/* read 1 sector */
	regs.h.ch = 0;		/* track */
	regs.h.cl = 1;		/* first sector = 1 */
	regs.h.dh = 0;		/* head = 0 */
	regs.h.dl = (char) (0x80+drivenum); /* drive = 0 */
	sregs.es = FP_SEG(scrat); /* buffer address	*/
	regs.x.bx = FP_OFF(scrat);

	int86x(0x13,&regs,&regs,&sregs);
	if (regs.x.cflag) return;

	_fmemcpy(table,(char far *)scrat+0x1be,4 * sizeof(PARTTABLE));
}

/*
 *	get_driveparm - get parameters for one drive
 */

int get_driveparm(int drvnum,DRIVEPARM *parm)
{
	struct SREGS segs;
	union REGS regs;
	int drives;		/* Drive count */

	memset(parm,0,sizeof(DRIVEPARM));
	strcpy(parm->text,MSG4149);

	segread(&segs);

	regs.x.ax = 0x0800;
	regs.x.dx = drvnum;

	int86x(0x13,&regs,&regs,&segs);
	if (regs.x.cflag) {
		if (SysInfo->flags.cmos && drvnum >= 0 && drvnum < 2) {
			/* Some machines don't support the function.
			 * Fallback to use CMOS data */
			WORD type1;
			WORD type2;

			type1 = (SysInfo->cmos[0x10] >> 4) & 0x0f;
			type2 = (SysInfo->cmos[0x10]) & 0x0f;

			if (drvnum == 0) parm->type = type1;
			else		 parm->type = type2;

			if (parm->type > 0 && parm->type <= 4) {
				memcpy(parm,DisketteParms+parm->type,sizeof(DRIVEPARM));
				if (type2 != 0 && type2 != 0x0f) return 2;
				return 1;
			}
			else {
				return 0;
			}
		}
		if (SysInfo->flags.pc || SysInfo->flags.xt && drvnum < 0x80) {
			/* Kludge for PC/XT floppies */
			memcpy(parm,DisketteParms+1,sizeof(DRIVEPARM));
			return 1;
		}
		else	return 0;
	}

	parm->type = regs.h.bl;
	parm->cyls = (regs.h.ch & 0xff) + ((regs.h.cl & 0xc0) << 2) + 1;
	parm->sectors = regs.h.cl & 0x3f;
	parm->heads = regs.h.dh + 1;
	drives = regs.h.dl;
	if (drvnum < 0x80) {
		switch (parm->type) {
		case 1:
			strcpy(parm->text,MSG4145);
			break;
		case 2:
			strcpy(parm->text,MSG4146);
			break;
		case 3:
			strcpy(parm->text,MSG4147);
			break;
		case 4:
			strcpy(parm->text,MSG4148);
			break;
		case 6:
			strcpy(parm->text,MSG4185);
			break;
		default:
			strcpy(parm->text,MSG4149);
			break;
		}
	}
	else {
		double mb;

		if (drvnum == 0x80 && SysInfo->flags.cmos) {
			parm->type = (SysInfo->cmos[0x12] >> 4) & 0x0f;
			if (parm->type == 0x0f) parm->type = SysInfo->cmos[0x19];
		}
		else if (drvnum == 0x81 && SysInfo->flags.cmos) {
			parm->type = (SysInfo->cmos[0x12]) & 0x0f;
			if (parm->type == 0x0f) parm->type = SysInfo->cmos[0x1A];
		}
		parm->cyls++;
		mb = ((((double)parm->cyls *
			(double)parm->heads *
			(double)parm->sectors) * 512.0) / (1024.0 * 1024.0));
			/* Some people think this should be:	(1000 * 1000) */
		sprintf(parm->text,MSG4150,mb);
	}
	/*parmp = (char far *)((DWORD)segs.es << 16 | regs.x.bx);*/
	return drives;
}

/*
 *	get_listlist - get pointer to secret "list of lists"
 */

void far *get_listlist(void)
{
	union REGS regs;
	struct SREGS segs;
	void far *llp;		/* Pointer to list of lists */

	segread(&segs);
	regs.x.ax = 0x5200;
	int86x(0x21,&regs,&regs,&segs);

	llp = (void far *)(((long)segs.es << 16) | (regs.x.bx - 12));
	return llp;
}

/*
 *	get_dosnames - get the real names of the DOS kernel files
 *	(i.e. IBMBIO and IBMDOS for PC-DOS, or IO and MSDOS for MS-DOS)
 *	Also get the name of the command shell
 */

void get_dosnames(char *ioname,char *dosname,char *comname)
{
	unsigned rtn;		/* Status return */
	struct find_t find;	/* File find structure */
	char filespec[16];	/* Target filespec */
	char *p;		/* Scratch pointer */

	/* Find the first two files in the root dir of the boot drive
	 * Assume that they are the IO and DOS modules */
	sprintf(filespec,MSG4151,SysInfo->bootdrv+'A');
	rtn = _dos_findfirst(filespec,
		_A_ARCH | _A_HIDDEN | _A_SYSTEM | _A_RDONLY,&find);
	if (rtn == 0) {
		strcpy(ioname,find.name);
		p = strrchr(ioname,'.');
		if (p) *p = '\0';

		rtn = _dos_findnext(&find);
		if (rtn == 0) {
			strcpy(dosname,find.name);
			p = strrchr(dosname,'.');
			if (p) *p = '\0';
		}
		else	strcpy(dosname,MSG4152);
	}
	else	strcpy(ioname,MSG4153);

	p = getenv("COMSPEC");
	if (p) {
		char *p2;

		for (p2 = p; *p; p++) {
			if (*p == '\\' || *p == ':' || *p == '/') {
				p2 = p+1;
			}
		}
		strcpy(comname,p2);
	}
}

/*
 *	get_dosaddrs - get addresses of components of DOS
 */

void get_dosaddrs(void)
{
	MACENTRY far *macp;	/* Pointer to MAC entry */
	FILEHDR far *fp;	/* Pointer to file table header */

	/* Locate the I/O kernel, DOS kernel, Device driver and Data areas */
	macp = FAR_PTR(RawInfo.listlist->base.first_mac,0);
	SysInfo->io_start = 0x700;
	SysInfo->dos_start = (DWORD)FP_SEG(RawInfo.listlist) * 16;
	SysInfo->dev_start = (DWORD)RawInfo.listlist->base.first_mac * 16;
	SysInfo->data_start = SysInfo->dev_start + 16;
	SysInfo->data_end = (DWORD)(RawInfo.listlist->base.first_mac+macp->npara+1) * 16;
	if (SysInfo->data_start > SysInfo->data_end) {
		/* This shouldn't happen, but just in case... */
		SysInfo->data_start = SysInfo->data_end;
	}
	/**/ {
		/* As far as we're concerned, the 'DOS Data' area begins with
		 * the first (and only?) file table in the device driver
		 * memory block.  This isn't exactly true in DOS 4.x, but
		 * it works.
		 */
		fp = RawInfo.listlist->base.files;
		while (fp && FP_OFF(fp) != 0xFFFF) {
			DWORD faddr;

			faddr = (DWORD)FP_SEG(fp) * 16;
			if (faddr >= SysInfo->dev_start && faddr < SysInfo->data_end) {
				SysInfo->data_start = faddr;
				if (SysInfo->dosver >= 0x400) {
					SysInfo->data_start -= 16;
				}
				break;
			}
			fp = fp->next;
		}
	}

	/* Get the head of the device driver chain */
	if (SysInfo->dosver >= 0x200 && SysInfo->dosver < 0x300) {
		/* DOS 2.0 - 2.1 */
		RawInfo.ddp = (DDENTRY far *)RawInfo.listlist->ext.v2x.nuldev;
	}
	else if (SysInfo->dosver >= 0x300 && SysInfo->dosver < 0x30A) {
		/* DOS 3.0 */
		RawInfo.ddp = (DDENTRY far *)RawInfo.listlist->ext.v30.nuldev;
	}
	else if (SysInfo->dosver >= 0x30A && SysInfo->dosver < 0x400) {
		/* DOS 3.1 - 3.31 */
		RawInfo.ddp = (DDENTRY far *)RawInfo.listlist->ext.v3x.nuldev;
	}
	else if (SysInfo->dosver >= 0x400) {
		/* DOS 4.0 - ?.?? */
		/* This works under dos 4.x and 5.0.  Don't know about
		 * > 5.0 */
		RawInfo.ddp = (DDENTRY far *)RawInfo.listlist->ext.v4x.nuldev;
	}
	else {
		/* Forget it */
		RawInfo.ddp = NULL;
	}
}

/*
 *	get_ddlist - get device driver list
 */

void get_ddlist(void)
{
	DDENTRY far *ddp; /* Pointer to device driver header */

	SysInfo->ddlen = 0;
	SysInfo->ddlist = 0;

	SysInfo->logdrv = 0;
	ddp = RawInfo.ddp;
	while (ddp && FP_OFF(ddp) != 0xFFFF) {
		DDLIST *ddl;

		ddl = sysbuf_append(&SysInfo->ddlist,NULL,sizeof(DDLIST));
		ddl->this  = ddp;		/* Address of this DD entry */
		ddl->next  = ddp->next; 	/* Address of next DD header */
		ddl->attr  = ddp->attr; 	/* Device attributes */
		ddl->strat = ddp->strat;	/* Pointer to strategy routine */
		ddl->intr  = ddp->intr; 	/* Pointer to interrupt routine */
		_fmemcpy(ddl->name,ddp->name,sizeof(ddl->name)); /* Device name */

		if (!(ddp->attr & 0x8000)) {
			SysInfo->logdrv += *(ddp->name);
		}
		ddp = ddp->next;
		SysInfo->ddlen++;
	}
}

/* Callback function used for parsing CONFIG.SYS */
int _far gcp_callback (CONFIGLINE _far *lpCfg)
{
  char	buff[512];
  char	*kwd, *arg1;

  if (lpCfg->line) {

	_fstrncpy (buff, lpCfg->line, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';

	if (!(kwd = strtok (buff, CfgKeywordSeps))) return (0);
	arg1 = strtok (NULL, CfgKeywordSeps);

	if (lpCfg->ID == ID_DEVICE) {
	  if (!SysInfo->config.maxpro) SysInfo->config.maxpro =
			get_profile (arg1, 1);
	  if (!SysInfo->config.extradospro) SysInfo->config.extradospro =
			get_profile (arg1, 2);
	} /* Found a DEVICE= line */
	else if (lpCfg->ID == ID_SHELL && !SysInfo->config.shell) {
	  sysbuf_store(&SysInfo->config.shell,arg1,0);
	} /* Found a SHELL= statement */
	else if (lpCfg->ID == ID_OTHER) {
	  if (strcmpi (kwd, MSG4168) == 0) {
		sysbuf_store(&SysInfo->config.country,arg1,0);
	  }
	  else if (strcmpi (kwd, MSG4169) == 0) {
		sysbuf_store(&SysInfo->config.drivparm,arg1,0);
	  }
	} /* Found COUNTRY= or DRIVPARM= */

  } /* Line is not null */

  return (0);	// Not relocating any lines

#if 0 /* This is the old code from get_config_parms () */
			char *p;

			p = strchr(line,'=');
			if (p) {
				*p++ = '\0';
				trim(line);
				trim(p);
#if 0
				if (strcmpi(line,MSG4163) == 0) {
					SysInfo->config.files = atoi(p);
				}
				else if (strcmpi(line,MSG4164) == 0) {
					SysInfo->config.buffers = atoi(p);
				}
				else if (strcmpi(line,MSG4165) == 0) {
					SysInfo->config.fcbx = atoi(p);
					p = strchr(p,',');
					if (p) {
						SysInfo->config.fcby = atoi(p+1);
					}
				}
				else if (strcmpi(line,MSG4167) == 0) {
					SysInfo->config.lastdrive = toupper(*p);
				}
				else if (strcmpi(line,MSG4166) == 0) {
					SysInfo->config.stackx = atoi(p);
					p = strchr(p,',');
					if (p) {
						SysInfo->config.stacky = atoi(p+1);
					}
				}
				else
#endif

				if (strcmpi(line,MSG4167) == 0) {
					sysbuf_store(&SysInfo->config.shell,p,0);
				}
				else if (strcmpi(line,MSG4168) == 0) {
					sysbuf_store(&SysInfo->config.country,p,0);
				}
				else if (strcmpi(line,MSG4169) == 0) {
					sysbuf_store(&SysInfo->config.drivparm,p,0);
				}
				else if (!SysInfo->config.maxpro &&
					 strcmpi(line,MSG4179) == 0) {
					SysInfo->config.maxpro = get_maxpro(p);
				}
			}
#endif

} /* gcp_callback () */

/*
 *	get_config_params - get parameters from CONFIG.SYS
 */

void get_config_parms(void)
{
	/* Set defaults, if not set already */
	if (!SysInfo->config.files) SysInfo->config.files = 8;
	if (!SysInfo->config.buffers) SysInfo->config.buffers = 2;
	if (!SysInfo->config.fcbx) SysInfo->config.fcbx = 4;
	SysInfo->config.print = 0;
	SysInfo->config.fastopen = 0;

	/* Get some things direct from DOS */
	{
		union REGS regs;

		SysInfo->config.lastdrive =
			(bdos(0x0e,bdos(0x19,0,0),0) & 0xff) + '@';

		memset(&regs,0,sizeof(regs));
		regs.x.ax = 0x3300;
		intdos(&regs,&regs);
		SysInfo->config.brk = regs.h.dl;
	}

	/* Get some more things from DOS List of Lists */
	/* ???????????? */

	{
		UMAP *ump;
		UMAP *umpend;

		/* Check for PRINT or FASTOPEN loaded */
		ump = sysbuf_ptr(SysInfo->umap);
		umpend = ump + SysInfo->umaplen;
		while (ump < umpend) {
			if (ump->class == CLASS_PRGM) {
				if (memicmp(ump->name,MSG4177,5) == 0 &&
				    (ump->name[5] == '.' || ump->name[5] == '\0')) {
					SysInfo->config.print = TRUE;
				}
				else if (memicmp(ump->name,MSG4178,8) == 0) {
					SysInfo->config.fastopen = TRUE;
				}
			}
			ump++;
		}
	}

	/* Get the rest by (yuk!) reading CONFIG.SYS */
	/* Note that we also need to get the startup batch file name */
	/* (not necessarily boot:\autoexec.bat) by parsing the SHELL */
	/* statement. */
	ConfigName[0] = (char) (SysInfo->bootdrv+'A');
	if (BootOverride) ConfigName[0] = (char) BootOverride;
	if (!menu_parse (ConfigName[0], 0)) {
	  char _far *tmp;
	  WORD high_mac, lseg;

	  if (qmaxpres (&high_mac, &lseg) == FALSE &&
		qmovpres (&high_mac, &lseg) == FALSE) high_mac = 0xffff;
	  tmp = CurrentMboot (high_mac);
	  if (tmp) {
		set_current (tmp);
	  } /* Found CONFIG= */
	  else	ActiveOwner = CommonOwner;

	  if (!config_parse (ConfigName[0],	/* Boot drive */
			ActiveOwner,	/* Section owner */
			"/dev/nul",     /* Output file */
			0,		/* Don't keep in memory */
			gcp_callback)) { /* Callback function */
		_fstrcpy (AutoexecName, StartupBat);
	  } /* Multiboot parser succeeded */
	  else {
		AutoexecName[0] = ConfigName[0];
	  } /* MultiConfig parser failed */

	  /* Get startup batch file name */
	  sysbuf_store (&SysInfo->config.startupbat, AutoexecName, 0);

	} /* Parsed 0 or more MultiConfig menus */

	return;
}

/*
 *	get_windows_data - Find Windows directory and get info
 */

void get_windows_data (void)
{
  char winver_exe[256];
  char fdrive[_MAX_DRIVE],fdir[_MAX_DIR],
	fname[_MAX_FNAME],fext[_MAX_EXT];
  char *tmp;
  DWORD dLen;
  DWORD dHandle;
  void *pBlock;
  VS_VERSION FAR *lpvs;

  _searchenv ("WINVER.EXE", "PATH", winver_exe);
  if (winver_exe[0]) {
	/* Get WINVER data from WINVER.EXE (windowsver) */
	if (!access (winver_exe, 04)) {
	    if ((dLen = GetFileVersionInfoSize (winver_exe, &dHandle)) &&
		(pBlock = my_malloc ((WORD) dLen))) {
		if (GetFileVersionInfo (winver_exe, 0L, dLen, pBlock)) {
		  lpvs = (VS_VERSION FAR *) pBlock;
		  SysInfo->WindowsData.windowsver = 256 * HIWORD(lpvs->vffInfo.dwFileVersionMS) + LOWORD(lpvs->vffInfo.dwFileVersionMS);
		  SysInfo->flags.gotwinver = 1;
		} // Got version info
		my_free (pBlock);
	    } // Version info found
	} /* WINVER.EXE readable */

	/* Get list of Windows files */
	_splitpath (winver_exe, fdrive, fdir, fname, fext);
	sprintf (winver_exe, "%s%s", fdrive, fdir);
	get_file_stats (winver_exe, WindowsFspecs, &SysInfo->WindowsData.pWFiles);

	/* Save Windows directory without trailing backslash */
	if (*(tmp = winver_exe+strlen(winver_exe)-1) == '\\') *tmp = '\0';
	sysbuf_store(&SysInfo->WindowsData.windowsdir, winver_exe, 0);

	/* Look for SYSTEM.INI */
	_makepath (winver_exe, fdrive, fdir, "SYSTEM", ".INI");
	if (!access (winver_exe, 04)) {
	  sysbuf_store(&SysInfo->WindowsData.sysininame, winver_exe, 0);
	} /* SYSTEM.INI exists and is readable */

  } /* Found WINVER.EXE */

} /* get_windows_data () */


/*
 *	get_roms - locate any on-card ROMs
 */

void get_roms(void)
{
	WORD seg = 0;		/* Segment addr of ROM region */
	WORD size = 0;		/* Size of ROM region */

	SysInfo->romlen = 0;
	SysInfo->romlist = 0;
	while ((seg = rom_find(seg,&size)) != 0) {
		ROMITEM *rp;	/* Pointer to rom item in buffer */

		rp = sysbuf_append(&SysInfo->romlist,NULL,sizeof(ROMITEM));
		SysInfo->romlen++;
		rp->seg = seg;
		rp->size = size;
	}
}

/*
 *	find_video_rom - locate video adapter rom
 */

WORD find_video_rom(WORD *psize,BOOL flex)
{
	int k;			/* Loop counter */
	DWORD video_addr[4];

	/* Video interrupts that should map into ROM */
	static int video_ints[4] = { 0x10, 0x1D, 0x1F, 0x00 };

	for (k=0; k < 4; k++) {
		video_addr[k] = FLAT_ADDR(SysInfo->vectors[video_ints[k]]);
	}

	if (flex) {
		FLEXROM *flexitem;	/* Pointer to flexxed ROM list item */
		FLEXROM *flexend;	/* Pointer to end of flexxed ROM list */

		flexitem = sysbuf_ptr(SysInfo->flexlist);
		flexend = flexitem + SysInfo->flexlen;
		while (flexitem < flexend) {
			DWORD addr;

			addr = (DWORD)flexitem->dst * 16;
			for (k=0; k < 4; k++) {
				if (video_addr[k] >= addr && video_addr[k] < addr + flexitem->len) {
					break;
				}
			}
			if (k < 4) {
				*psize = flexitem->len / 16;
				return flexitem->dst;
			}
			flexitem++;
		}
	}
	else {
		WORD seg = 0;		/* Segment addr */
		WORD size = 0;		/* Size of rom region */

		while ((seg = rom_find(seg,&size)) != 0) {
			DWORD addr;

			addr = (DWORD)seg * 16;
			for (k=0; k < 4; k++) {
				if (video_addr[k] >= addr && video_addr[k] < addr + ((DWORD)size * 16)) {
					break;
				}
			}
			if (k < 4) {
				*psize = size;
				return seg;
			}
		}
	}
	*psize = 0;
	return 0;
}

/*
 *	find_disk_rom - locate fixed disk adapter rom in XT class machines
 */

WORD find_disk_rom(WORD *psize,BOOL flex)
{
	int k;			/* Loop counter */
	DWORD disk_addr[4];

	/* Disk interrupts that should map into ROM */
	static int disk_ints[4] = { 0x0D, 0x13, 0x19, 0x41 };

	for (k=0; k < 4; k++) {
		disk_addr[k] = FLAT_ADDR(SysInfo->vectors[disk_ints[k]]);
	}

	if (flex) {
		FLEXROM *flexitem;	/* Pointer to flexxed ROM list item */
		FLEXROM *flexend;	/* Pointer to end of flexxed ROM list */

		flexitem = sysbuf_ptr(SysInfo->flexlist);
		flexend = flexitem + SysInfo->flexlen;
		while (flexitem < flexend) {
			DWORD addr;

			addr = (DWORD)flexitem->dst * 16;
			for (k=0; k < 4; k++) {
				if (disk_addr[k] >= addr && disk_addr[k] < addr + flexitem->len) {
					break;
				}
			}
			if (k < 4) {
				*psize = flexitem->len / 16;
				return flexitem->dst;
			}
			flexitem++;
		}
	}
	else {
		WORD seg = 0;		/* Segment addr */
		WORD size = 0;		/* Size of rom region */

		while ((seg = rom_find(seg,&size)) != 0) {
			DWORD addr;

			addr = (DWORD)seg * 16;
			for (k=0; k < 4; k++) {
				if (disk_addr[k] >= addr && disk_addr[k] < addr + ((DWORD)size * 16)) {
					break;
				}
			}
			if (k < 4) {
				*psize = size;
				return seg;
			}
		}
	}
	*psize = 0;
	return 0;
}

/*
 *	rom_find - find the next on-card rom
 */

WORD rom_find(
	WORD start,		/* Segment for where to start looking */
	WORD *size)		/* How much was found in paras */
{
	BYTE far *p;		/* Pointer to ROM region */
	int n;			/* Paragraph count */
	BYTE sig1 = 0x44;
	BYTE sig2 = 0xBB;
	BYTE fudge = 0x11;

	if (start) {
		p = FAR_PTR(start,0);
		p = FAR_PTR(FP_SEG(p)+(p[2]*32),0);
	}
	else {
		p = FAR_PTR(0xC000,0);
		*size = 0;
	}
	n = (int)(0xE000L - FP_SEG(p));

	while (n > 0) {
		if ((p[0]-fudge) == sig1 && (p[1]+fudge) == sig2 &&
		    (p[2]-fudge) != sig1 && (p[3]+fudge) != sig2) {
			*size = p[2] * 32;
			return FP_SEG(p);
		}
		else {
			p = FAR_PTR(FP_SEG(p)+(2048/16),0);
			n -= 2048/16;
		}
	}
	*size = 0;
	return 0;
}

/*
 *	get_envstrs - get environment strings / size / used
 */

void get_envstrs(void)
{
	MACINFO *mp;	/* Pointer to MAC entry */
	MACINFO *mpend; /* Pointer to end of MAC entries */
	BYTE far *cmdpsp; /* Pointer to PSP for COMMAND.COM */
	BYTE far *cmdenv; /* Pointer to environment for COMMAND.COM */

	/* Init */
	SysInfo->envsize = SysInfo->envused = 0;
	SysInfo->envstrs = 0;

	/* Look for env block in low DOS */
	cmdpsp = cmdenv = NULL;
	mp = sysbuf_ptr(SysInfo->lowdos);
	mpend = mp + SysInfo->nlowdos;
	for (; mp < mpend; mp++) {
		/* Find (the first) COMMAND.COM environment block */
		if (mp->type == MACTYPE_CMDCOM) {
			if (*mp->text) {
				/* Found environment block */
				cmdenv = (BYTE far *)FAR_PTR(mp->start+1,0);
				SysInfo->envsize = mp->size * 16;
				break;
			}
			else {
				cmdpsp = (BYTE far *)FAR_PTR(mp->start+1,0);
			}
		}
	}

	/* With ExtraDOS, COMMAND.COM and its environment may be loaded high */
	if (!cmdenv) {
	  mp = sysbuf_ptr( SysInfo->highdos );
	  mpend = mp + SysInfo->nhighdos;
	  for ( ; mp < mpend; mp++) {
		if (mp->type == MACTYPE_CMDCOM) {
			if (*mp->text) {
				/* Found environment */
				cmdenv = (BYTE __far *)FAR_PTR( mp->start + 1, 0 );
				SysInfo->envsize = mp->size * 16;
				break;
			} /* Found it */
			/* Don't scavenge high DOS for command.com unless we */
			/* didn't find it in low DOS. */
			else if (!cmdpsp) {
				cmdpsp = (BYTE __far *)FAR_PTR( mp->start + 1, 0 );
			} /* Haven't found a COMMAND.COM PSP yet */
		} /* Found a COMMAND.COM MAC */
	  } /* for all high DOS blocks */
	} /* Didn't find COMMAND.COM environment in low DOS */

	/* Special case */
	if (cmdpsp && !cmdenv) {
		/* Get env pointer from COMMAND.COM PSP */
		WORD envseg;
		MACENTRY far *mac;

		envseg = *(WORD far *)(cmdpsp+0x2C);
		cmdenv = FAR_PTR(envseg,0);
		mac = FAR_PTR(envseg-1,0);
		if (mac->type == 'M' || mac->type == 'Z') {
			/* Assume a MAC-like entry before env */
			SysInfo->envsize = mac->npara * 16;
		}
	}

	if (cmdenv) {
		/* Collect all the environment strings */
		char far *pp;

		SysInfo->envlen = 0;
		pp = cmdenv;
		while (*pp) {
			char *pp2;

			pp2 = sysbuf_append(&SysInfo->envstrs,pp,0);
			launder_string(pp2);
			pp += _fstrlen(pp)+1;
			SysInfo->envlen++;
		}
		sysbuf_append(&SysInfo->envstrs,"",1);
		SysInfo->envused = pp - cmdenv + 1;
	}
}

/*
 *	get_timelist - get list of memory timing data
 *
 *	There's a good reason for scanning 32K blocks.  The video memory
 *	typically gives widely differing timings depending on where we
 *	are in the retrace cycle, so we need a value that won't give us
 *	differing values within (usually) B800-C000.
 *
 *	This has the undesirable side effect of an 8K adapter RAM
 *	causing an entire 32K block to be unavailable for timing
 *	results.
 */

#define TIMEBLOCK 0x0800	/* Paras per timing region (2K*16=32K bytes) */
#define TESTMEM_ATOM 0x0100	/* Paras per TESTMEM_MAP element */
#define MAXVARIANCE 6		/* Maximum variance between ranges */

/* In TESTMEM.ASM: 1 byte per 4K block in high DOS */
extern unsigned char pascal TESTMEM_MAP[1];

void get_timelist(void)
{
	int jj,kk,nn;		/* Counters */
	int flag;		/* Is-a-386 flag */
	WORD start;		/* Start segment address */
	WORD next;		/* Next segment address */
	WORD length = 0;	/* Length of region */
	WORD average = 0;	/* Average access time */
	WORD count;		/* How many regions in average */
	DWORD sum = 0;		/* Sum of access times */
	TIMELIST item;		/* Time list entry */
	TIMELIST *timebuf;	/* Pointer to entry in buffer */

	flag = ((SysInfo->cpu.cpu_type < CPU_80386) ? 0 : 1);

	SysInfo->timelen = 0;
	SysInfo->timelist = sysbuf_alloc(0);

	start = next = 0;
	nn = (int)(65536L/TIMEBLOCK);
	for (jj=0,kk=0; jj < nn; jj++) {
		int ll, noscan, variance;

		noscan = 0; /* Assume timing is OK */
		if (next >= 0xA000) {

		  for (ll = 0; ll < TIMEBLOCK/TESTMEM_ATOM; ll++) {

		    if ((TESTMEM_MAP[(next-0xA000)/TESTMEM_ATOM+ll] & 0x03)
								    == 0x03) {
			noscan = 1;
			break;
		    } /* Found a NOSCAN block */

		  } /* for all 4K blocks in this 32K range */

		} /* Check for NOSCAN in this 32K range */

		if (noscan) {
			count = 0;
			/* Force a new range if last was non-zero */
			variance = MAXVARIANCE + (average ? 1 : 0);
		}
		else {
			count = time_mem (next,flag);
			if (kk) {
			  /* If last range was NOSCAN, force a new one */
			  if (average)
				variance = (int) (((long) abs(average - count)
						  * 100) / average);
			  else	variance = MAXVARIANCE + 1;
			} /* Start of list; calculate variance */
		}

		if (kk == 0) {

			sum = count;
			length = TIMEBLOCK;
			kk = 1;
			average = count;

		} /* start of first block */
		else if (variance <= MAXVARIANCE) {

			sum += count;
			length += TIMEBLOCK;
			kk++;
			average = (WORD)(sum / kk);

		} /* Variance is less than 7% */
		else {

			item.start = start;
			item.length = length;
			item.count = average;

			SysInfo->timelist = sysbuf_realloc(SysInfo->timelist,(SysInfo->timelen+1) * sizeof(TIMELIST));
			timebuf = (TIMELIST *)sysbuf_ptr(SysInfo->timelist) + SysInfo->timelen;
			memcpy(timebuf,&item,sizeof(item));
			SysInfo->timelen++;

			start += length;

			sum = count;
			length = TIMEBLOCK;
			kk = 1;
			average = count;

		} /* Summation time; exceeded variance limit */

		next += TIMEBLOCK;

	} /* for all possible blocks */

	if (kk > 0) {

		item.start = start;
		item.length = length;
		item.count = average;

		SysInfo->timelist = sysbuf_realloc(SysInfo->timelist,(SysInfo->timelen+1) * sizeof(TIMELIST));
		timebuf = (TIMELIST *)sysbuf_ptr(SysInfo->timelist) + SysInfo->timelen;
		memcpy(timebuf,&item,sizeof(item));
		SysInfo->timelen++;

	} /* Close out remaining range */

} /* get_timelist () */

/*
 *	get_open_files - get list of open files
 */

void get_open_files(void)
{
	int a20state;
	int filesize;		/* Size of file table entry */
	int filecount;		/* FILES= count */
	FILEHDR far *filep;	/* Pointer to file header */
	FILEHDR far *fcbp;	/* Pointer to FCB header */

	SysInfo->openfcbs = 0;
	SysInfo->openlen = 0;
	filecount = 0;

	if (SysInfo->flags.xms) {
		/* J.I.C. the chain goes into the HMA */
		a20state = setA20(1);
	}

	filep = RawInfo.listlist->base.files;
	if (SysInfo->dosver >= 0x200 && SysInfo->dosver < 0x300) {
		/* DOS 2.x */
		while (filep && FP_OFF(filep) != -1) {
			WORD kk;
			FILE2X far *fe;

			fe = (FILE2X far *)(filep+1);

			for (kk = 0; kk < filep->nfiles; kk++) {
				if (!fe[kk].count) continue;
				add_filename(fe[kk].name);
			}
			filep = filep->next;
		}
		goto bottom;
	}

	if (SysInfo->dosver >= 0x300 && SysInfo->dosver < 0x30A) {
		/* DOS 3.0 */
		fcbp = RawInfo.listlist->ext.v30.fcbs;
		filesize = sizeof(FILE3X);
	}
	else if (SysInfo->dosver >= 0x30A && SysInfo->dosver < 0x400) {
		/* DOS 3.x */
		fcbp = RawInfo.listlist->ext.v3x.fcbs;
		filesize = sizeof(FILE3X);
	}
	else if (SysInfo->dosver >= 0x400) {
		/* DOS 4.x */
		fcbp = RawInfo.listlist->ext.v4x.fcbs;
		filesize = sizeof(FILE4X);
	}
	else {
		/* Just forget it */
		goto bottom;
	}

	{
		while (filep && FP_OFF(filep) != -1) {
			WORD kk;
			char far *p;

			filecount += filep->nfiles;

			p = (char far *)(filep+1);
			for (kk = 0; kk < filep->nfiles; kk++) {
				FILE3X far *fe; /* This works for 4.x on the fields we care about */

				fe = (FILE3X far *)p;
				p += filesize;
				if (!fe->count) continue;
				if ((fe->info & 0x8000) == 0) {
					add_filename(fe->name);
				}
			}
			filep = filep->next;
		}

		while (fcbp && FP_OFF(fcbp) != -1) {
			WORD kk;
			char far *p;

			p = (char far *)(fcbp+1);
			for (kk = 0; kk < fcbp->nfiles; kk++) {
				FILE3X far *fe; /* This works for 4.x on the fields we care about */

				fe = (FILE3X far *)p;
				p += filesize;
				if (!fe->count) continue;
				if ((fe->info & 0x8000) == 0) {
					add_filename(fe->name);
					SysInfo->openfcbs++;
				}
			}
			fcbp = fcbp->next;
		}
	}
	SysInfo->config.files = filecount;
bottom:
	if (SysInfo->flags.xms) {
		setA20(a20state);
	}
}

/*
 *	get_dosdata - get information about dos data area
 */

#pragma optimize("leg",off)
void get_dosdata(void)
{
	int nlist;		/* How many items in list */
	GLIST templist; 	/* Temporary item list */

	SysInfo->doslen = 0;
	SysInfo->dosdata = 0;
	SysInfo->config.buffers = 0;
	SysInfo->config.fcbx = 0;
	SysInfo->config.fcby = 0;

	{
		int filesize;		/* Size of file table entry */
		int bufsize;		/* Size of buffer table entry */
		int drvsize;		/* Size of drive list entry */
		int lastdrive;		/* How many drives in drive list */
		DOSDATA item;		/* One data map item */
		FILEHDR far *filep;	/* Pointer to file table entry */
		FILEHDR far *fcbp;	/* Pointer to FCB table entry */
		BUFXX far *bufp;	/* Pointer to buffer list entry */
		void far *drvp; 	/* Pointer to drive list */

		/* Collect the individual entries */
		nlist = 0;
		glist_init(&templist,GLIST_ARRAY,sizeof(DOSDATA),4*sizeof(DOSDATA));

		filep = RawInfo.listlist->base.files;
		if (SysInfo->dosver >= 0x200 && SysInfo->dosver < 0x300) {
			/* DOS 2.0 - 2.1 */
			fcbp = NULL;
			filesize = sizeof(FILE2X);
			bufp = (BUFXX far *)RawInfo.listlist->ext.v2x.bufp;
			bufsize = sizeof(BUF2X);
			drvp = NULL;
			drvsize = 0;
			lastdrive = 0;
		}
		else if (SysInfo->dosver >= 0x300 && SysInfo->dosver < 0x30A) {
			/* DOS 3.0 */
			fcbp = RawInfo.listlist->ext.v30.fcbs;
			SysInfo->config.fcby = RawInfo.listlist->ext.v30.fcby;
			filesize = sizeof(FILE3X);
			bufp = (BUFXX far *)RawInfo.listlist->ext.v30.bufp;
			bufsize = sizeof(BUF3X);
			drvp = RawInfo.listlist->ext.v30.curdir;
			drvsize = D3XSIZE;
			lastdrive = RawInfo.listlist->ext.v30.lastdrive;
		}
		else if (SysInfo->dosver >= 0x30A && SysInfo->dosver < 0x400) {
			/* DOS 3.1 - 3.31 */
			fcbp = RawInfo.listlist->ext.v3x.fcbs;
			SysInfo->config.fcby = RawInfo.listlist->ext.v3x.fcby;
			filesize = sizeof(FILE3X);
			bufp = (BUFXX far *)RawInfo.listlist->ext.v3x.bufp;
			bufsize = sizeof(BUF3X);
			drvp = RawInfo.listlist->ext.v3x.curdir;
			drvsize = D3XSIZE;
			lastdrive = RawInfo.listlist->ext.v3x.lastdrive;
		}
		else {
			/* Forget it */
			return;
		}

		/* File entries */
		{
			memset(&item,0,sizeof(item));
			item.type = 'F';
			while (filep && FP_OFF(filep) != -1) {
				item.faddr = FLAT_ADDR(filep);
				item.length = filep->nfiles * filesize;
				item.count = filep->nfiles;
				glist_new(&templist,&item,sizeof(item));
				nlist++;
				filep = filep->next;
			}
		}

		/* FCB entries */
		if (fcbp) {
			memset(&item,0,sizeof(item));
			item.type = 'X';
			while (fcbp && FP_OFF(fcbp) != -1) {
				item.faddr = FLAT_ADDR(fcbp);
				item.length = fcbp->nfiles * filesize;
				item.count = fcbp->nfiles;
				glist_new(&templist,&item,sizeof(item));
				nlist++;
				SysInfo->config.fcbx += fcbp->nfiles;
				fcbp = fcbp->next;
			}
		}

		/* Buffer entries */
		{
			memset(&item,0,sizeof(item));
			item.type = 'B';
			while (bufp && FP_OFF(bufp) != -1) {
				item.faddr = FLAT_ADDR(bufp);
				item.length = bufsize;
				item.count = 1;
				glist_new(&templist,&item,sizeof(item));
				nlist++;
				SysInfo->config.buffers++;
				bufp = bufp->next;
			}
		}

		/* Drive list */
		{
			memset(&item,0,sizeof(item));
			item.type = 'L';
			item.faddr = FLAT_ADDR(drvp);
			item.length = lastdrive * drvsize;
			item.count = 1;
			glist_new(&templist,&item,sizeof(item));
			nlist++;
		}
		/* DOS Stacks */
		if (SysInfo->dosver >= 0x314 && SysInfo->dosver < 0x400) {
			if (find_3x_stacks(&item)) {
				glist_new(&templist,&item,sizeof(item));
				nlist++;
			}
		}
	}

	if (nlist < 1) {
		/* Nothing to do */
		return;
	}

	/* Sort 'em */
	glist_sort(&templist,dosdatcmp);

	{
		/* Group and put into master list */
		int kk;
		DOSDATA item;		/* One data map item */
		DOSDATA *dmp;		/* Pointer to dosdata item */

		memset(&item,0,sizeof(item));
		dmp = glist_head(&templist);
		for (kk = 0; kk <= nlist; kk++,dmp = glist_next(&templist,dmp)) {
			if (kk < nlist && item.type == dmp->type &&
			    item.faddr + item.length == dmp->faddr) {
				item.length += dmp->length;
				item.count += dmp->count;
				continue;
			}
			if (item.type) {
				item.saddr = SEG_ADDR(item.faddr);
				sysbuf_append(&SysInfo->dosdata,&item,sizeof(item));
				SysInfo->doslen++;
				memset(&item,0,sizeof(item));
			}
			if (kk < nlist) {
				memcpy(&item,dmp,sizeof(item));
			}
		}
	}
}
#pragma optimize("",on)

/*
 *	find_3x_stacks - find DOS Stacks regiondevice driver list
 *
 *	In DOS 3.2 and 3.3x, We have to use smoke and mirrors to
 * locate the DOS Stacks area, if there is one.  To do this, we
 * look at the 'hardware' interrupt vectors, and if any of them
 * vector to the region between data_start and data_end, then
 * that's where we look for Stacks.  In DOS 4.x+, we handle
 * this (much more directly) in get_4xdata().
 */

BOOL find_3x_stacks(
	DOSDATA *item)		/* Item to fill in */
{
	int kk;
	BOOL rtn = FALSE;

	/* Interrupts to look at */
	static int int_nums[] = {
		0x02, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e,
		0x70, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77 };

	for (kk=0; kk < sizeof(int_nums)/sizeof(int_nums[0]); kk++) {
		void far *saddr;
		DWORD faddr;

		saddr = SysInfo->vectors[int_nums[kk]];
		faddr = FLAT_ADDR(saddr);
		if (SysInfo->data_start <= faddr && faddr < SysInfo->data_end) {
			/* Got one, go look at it */
			struct {
				WORD huh;	/* ??? */
				WORD x; 	/* x in STACKS=x,y */
				WORD scbsiz;	/* Size of stack control block array (8 * x) */
				WORD y; 	/* y in STACKS=x,y */
				void far *pd;	/* Pointer to Stacks data segment */
				WORD sdstart;	/* Offset to start of Stacks data */
				WORD sdend;	/* Offset to end of Stacks data */
				WORD sdnext;	/* Offset to next stack to be allocated */
			} far *p;
			DWORD flatp;
			DWORD flatpd;

			p = FAR_PTR(FP_SEG(saddr),0);
			flatp = FLAT_ADDR(p);
			flatpd = FLAT_ADDR(p->pd);
			if (p->x >= 8 && p->x <= 64 &&
			    p->y >= 32 && p->y <= 512 &&
			    p->scbsiz == (WORD)8 * p->x &&
			    flatpd >= SysInfo->data_start &&
			    flatpd <  SysInfo->data_end &&
			    flatp < flatpd ) {
				/* We'll take this one, wrap it up */
				SysInfo->config.stackx = p->x;
				SysInfo->config.stacky = p->y;
				item->type = 'S';
				item->saddr = (void far *)p;
				item->faddr = FLAT_ADDR(item->saddr);
				item->length = (p->x * (p->y + 8)) + (flatpd - flatp);
				item->count = 0;
				*item->name = '\0';
				rtn = TRUE;
				break;
			}
		}
	}
	return rtn;
}

/*
 *	get_4xdata - get info for DOS 4.x data area
 */

void get_4xdata(void)
{
	DWORD next;	/* Address of next subsegment */
	DOSDATA item;	/* One memory map item */
	SUB4X far *sp;	/* Pointer to subsegment header */

	SysInfo->doslen = 0;
	SysInfo->dosdata = 0;
	SysInfo->config.buffers = RawInfo.listlist->ext.v4x.buffer_x;
	SysInfo->config.fcby = RawInfo.listlist->ext.v4x.fcby;

	sp = FAR_PTR(RawInfo.listlist->base.first_mac+1,0);
	do {
		memset(&item,0,sizeof(item));
		item.type = sp->type;
		trnbln(item.name);
		switch (item.type) {
		case 'F':
			item.count = (sp->size * 16) / sizeof(FILE4X);
			break;
		case 'B':
			item.count = (sp->size *16) / B4XSIZE;
			break;
		case 'X':
			item.count = (sp->size * 16) / sizeof(FILE4X);
			break;
		case 'D':
		case 'E':
		case 'I':
		case 'C':
			sprintf(item.name,"%-8.8Fs",sp->name);
			break;
		case 'L':
			break;
		case 'S':
			{
				/* Dos Stacks */
				struct {
					WORD huh;	/* ??? */
					WORD x; 	/* x in STACKS=x,y */
					WORD scbsiz;	/* Size of stack control block array (8 * x) */
					WORD y; 	/* y in STACKS=x,y */
					void far *pd;	/* Pointer to Stacks data segment */
					WORD sdstart;	/* Offset to start of Stacks data */
					WORD sdend;	/* Offset to end of Stacks data */
					WORD sdnext;	/* Offset to next stack to be allocated */
				} far *p;
				p = (void far *)(sp + 1);
				SysInfo->config.stackx = p->x;
				SysInfo->config.stacky = p->y;
			}
			break;
		default:
			item.type = 0;
		}
		if (item.type) {
			item.saddr = (char far *)sp;
			item.faddr = FLAT_ADDR(item.saddr);
			item.length = (long)sp->size * 16;
			sysbuf_append(&SysInfo->dosdata,&item,sizeof(item));
			SysInfo->doslen++;
		}
		sp = FAR_PTR(FP_SEG(sp)+sp->size+1,0);
		next = FLAT_ADDR(sp);
	} while(next < SysInfo->data_end);
	count_4x_fcbs();
}

/*
 *	count_4x_fcbs - Count FCBS for DOS 4.X+
 */

void count_4x_fcbs(void)
{
	int a20state;
	FILEHDR far *fcbp;	/* Pointer to FCB table entry */

	SysInfo->config.fcbx = 0;

	if (SysInfo->flags.xms) {
		/* J.I.C. the chain goes into the HMA */
		a20state = setA20(1);
	}

	fcbp = RawInfo.listlist->ext.v4x.fcbs;

	/* FCB entries */
	while (fcbp && FP_OFF(fcbp) != -1) {
		SysInfo->config.fcbx += fcbp->nfiles;
		fcbp = fcbp->next;
	}

	if (SysInfo->flags.xms) {
		setA20(a20state);
	}
}

/*
 *	get_adf - get ADF information from Adapter Description Files
 */

void get_adf(void)
{
	int kk; 	/* Loop counter */

	/* Init */
	memset(SysInfo->adf,0,sizeof(SysInfo->adf));

	if (adf_setup() < 0) return;
	for (kk = 1; kk < MCASLOTS; kk++) {
		if (SysInfo->mcaid[kk].aid != 0xFFFF) {
			int rtn;

			rtn = adf_read(NULL,&SysInfo->mcaid[kk],&SysInfo->adf[kk]);
			if (rtn != 0) {
				SysInfo->adf[kk] = 0;
			}
		}
	}
}

/*
 *	Parameters for CPU timing
 */

#define COUNT 1000	/* How many multiplies */
#define TRIALS 100	/* How many times to test */

/* Timer rate in MHz */
#define TIMER2_RATE 1.193180
/* Number of processor clocks in a multiply instruction */
#define MULCLKS88 118
#define MULCLKS286 21
#define MULCLKS386 25
#define MULCLKS486 26
#define MULCLKS486DX2 6 // DX2 or DX4
#define MULCLKS586 11	// Intel Pentium
#define MULCLKSP6   5	// Pentium Pro

/* Overhead in the multiply test */
/* Overhead components are (for Pentium):
 * Top of loop: OUT 4x,AL to start timer - overhead occurs before timer starts
 *						so use 12, RM value
 * Each 100 multiplies: DEC CX - 1; JZ rel8 - 1
 * Prefetch per 100 multiplies: ???
 * Bottom of loop: IN AL,4x to read timer - 7 RM, 19 VM (TSS hit, not GPF)
***/
#define MULOVH88 ( 31 + 22*COUNT/100 )
#define MULOVH286 ( 15 + 14*COUNT/100 )
#define MULOVH386 ( 15 + 14*COUNT/100 )
#define MULOVH486 ( 15 + 14*COUNT/100 )
#define MULOVH586 ( 15 + 10*COUNT/100 ) // Number is lower, but
					// this seems to work well
#define MULOVHP54C ( 12 + 6*COUNT/100 + 13 )
#define MULOVHP6   ( 12 + 3*COUNT/100 + 13 )

// Adjustment table - each line contains max, divider1, divider2, divider3 and
// a divisor for all 3 dividers (so we don't have to use float or double).
#define NUMPERROW 5
static int nAdjustRanges[][ NUMPERROW ] = {
	{ 12, 1,  2,   0,   0 }, // 2, 4, 6, 8, 10, 12
	{ 20, 1,  4,   0,   0 }, // 16, 20
	{ 40, 3, 15, 100,   0 }, // 25, 30, 33, 35, 40
	{ -1, 3, 75,  90, 100 }  // 50, 60, 66, 75, 90, 100, 120, 125, 133, 150
};
#define NUMRANGES (sizeof( nAdjustRanges ) / sizeof( nAdjustRanges[ 0 ][ 0 ])) / NUMPERROW

/*
 *	get_cpuclock - Estimate CPU processor clock rate
 */

double get_cpuclock(void)
{
	double clkrate; 	/* Processor clock rate, MHz */
	double clktime; 	/* Processor clock period, usec */
	double raw;		/* Variable for raw data */
	double clocks;		/* Clocks per multiply */
	int ovrhead;		/* Test overhead */
	int kk; 		/* Loop counter */

	switch( SysInfo->cpu.cpu_type )
		{
		case	CPU_8088	:		// Catch low CPU types
		case	CPU_8086	:
		case	CPU_V20 	:
		case	CPU_V30 	:
		case	CPU_80188:
		case	CPU_80186:
			clocks = MULCLKS88;
			ovrhead = MULOVH88;
			break;

		case	CPU_80286:
			clocks = MULCLKS286;
			ovrhead = MULOVH286;
			break;

		case	CPU_80386:
		case	CPU_80386SX:
			clocks = MULCLKS386;
			ovrhead = MULOVH386;
			break;

		case	CPU_80486:
		case	CPU_80486SX:
			// For steppings supporting CPUID, use Pentium timings
			if (SysInfo->cpu.model > 1) {
				clocks = MULCLKS486DX2;
				ovrhead = MULOVHP54C;
			} // DX2 or DX4
			else {
				clocks = MULCLKS486;
				ovrhead = MULOVH486;
			} // Not an DX2 or DX4
			break;

		case  CPU_PENTIUM:
			clocks = MULCLKS586;
			ovrhead = MULOVH586;
			if (SysInfo->cpu.model > 2) {
				ovrhead = MULOVHP54C;
			}
			break;

		case CPU_PENTPRO:
		default:							// And beyond
			clocks = MULCLKSP6;
			ovrhead = MULOVHP6;
;;;;;;	break;

		}

	clktime = 0;
	for (kk = 0; kk < TRIALS; kk++) {
		/* Obtain the number of clock ticks for 1000 multiplies. */
		raw = multime(COUNT);
		/* Accumulate the clock time in microseconds by adjusting for the
		 * timer rate, number of clocks per multiply, instruction count, and
		 * test overhead. */
		clktime +=  raw / (TIMER2_RATE * (clocks*COUNT + ovrhead));
	}
	clktime /= TRIALS;
	clkrate = 1.0 / clktime;

	/* Adjust clock rate to a multiple of 2 if <= 12,
	 * a multiple of 4 if <= 20, a multiple of 5 or 33.33
	 * if <= 40, and a multiple of 25, 30 or 33.33 for speeds
	 * > 40 (rounding adds 0.2 and truncates):
	 *   2	 4   5	 25   30   33.33
	 *  --	--  --	---  ---  ---
	 *   2	16  25	 50   60   33
	 *   4	20  30	 75   90   66
	 *   6	    35	100  120  100
	 *   8	    40	125  150  133
	 *  10		150  180  166
	 *  12		175  210  200
	 *		200  240  233
	 *		225  270  266
	 *		250  300  300
	***/
	for (kk = 0; kk < NUMRANGES; kk++) {

		int n;
		double divisor, remainder, min_remainder, quotient, min_divisor;

		// Use the first range we fit in
		if (nAdjustRanges[ kk ][ 0 ] > 0 &&
			(int)clkrate > nAdjustRanges[ kk ][ 0 ]) continue;

		min_remainder = clkrate;
		min_divisor = 1.0;

		// Now find the smallest remainder
		for (n = 2; n < NUMPERROW; n++) {

			if (!nAdjustRanges[ kk ][ n ]) break;

			// Convert ?, 3, 15, 100, 75 to 5, 33.33, 25
			// Ex: divisor = 33.33
			divisor = 1.0 * nAdjustRanges[ kk ][ n ] / nAdjustRanges[ kk ][ 1 ];
			// Ex: clkrate = 169.24, quotient = 5.0777077
			quotient = clkrate / divisor;
			// Ex: remainder = 169.24 - 166.66 = 2.58
			remainder = clkrate - divisor * (int)quotient;

			if (remainder < min_remainder) {
				min_remainder = remainder;
				min_divisor = divisor;
			} // Save this as the best so far

		} // for all possible divisors

		clkrate = min_divisor * (int)(clkrate / min_divisor);
		clkrate = (int)(clkrate + 0.2);

		break;

	} // Check all ranges

	return clkrate;
}

/*
 *	get_profile - read .pro from DEVICE= line
 *	formerly get_maxpro ()
 */

SYSBUFH get_profile(
	char *devline,		/* DEVICE= pathname from CONFIG.SYS */
	int linetype)		/* 1 for 386MAX/BlueMAX/Move'EM, */
				/* 2 for ExtraDOS */
{
	SYSBUFH hh;		/* Handle to return */
	char fdrive[_MAX_DRIVE+_MAX_DIR],
		fdir[_MAX_DIR],
		fname[_MAX_FNAME+_MAX_EXT],
		fext[_MAX_EXT];
	char *arg;

	_splitpath (devline, fdrive, fdir, fname, fext);
	strcat (fname, fext);

	/* Search for 386MAX.SYS, BLUEMAX.SYS, or MOVE'EM.MGR */
	if (linetype == 1) {
		if (	stricmp (fname, MSG4180) &&
			stricmp (fname, MSG4181) &&
			stricmp (fname, MSG4189) )	return (0);
		if (!SysInfo->pszMaxdir) {
			strcat (fdrive, fdir);
			sysbuf_store (&SysInfo->pszMaxdir, fdrive, 0);
		} /* Didn't get MAX subdirectory yet */
	} /* Looking for MAX or Move'EM */
	else /* linetype == 2 */ {
		if (stricmp (fname, MSG4189A)) return (0);
	} /* Looking for ExtraDOS */

	/* Call strtok () until we get a pro= */
	/* ValPathTerms will give us "pro", then the pathname */
	while (arg = strtok (NULL, ValPathTerms)) {
	  if (!stricmp (arg, "pro")) {
		arg = strtok (NULL, ValPathTerms);
		if (arg) {
		  sysbuf_store (&hh, arg, 0);
		  return (hh);
		} else return (0);
	  } /* Got a "pro" */
	} /* Processing all command line arguments */

	return (0);
}

/*
 *	get_disk_file - read contents of a file into memory
 */

BOOL get_disk_file(
	char *fname,		/* Name of file */
	BOOL useboot,		/* TRUE to prefix name with boot drive */
	char **ppszBuf, 	/* Buffer handle returned */
	WORD *nbuf)		/* Number of lines returned */
{
	FILE *f1;		/* Stream pointer for file */
	char line[256]; 	/* Scratch text space */
	long fsize;
	BOOL res = FALSE;
	char *psz;


	/* Set up the file name */
	if (useboot) {
		sprintf(line,MSG4176,SysInfo->bootdrv+'A',fname);
	}
	else {
		strcpy(line,fname);
	}


	/* Open the file */
	f1 = fopen(line,"r");
	if (!f1) return FALSE;

	/* Read lines into list */
	/* Note that we defer tab expansion until we're ready to */
	/* display the file.  This saves a little space and simplifies */
	/* allocation of space for the file data. */
	if (fseek (f1, 0L, SEEK_END) == -1) goto get_disk_file_exit;
	if ((fsize = ftell (f1)) == -1L || fseek (f1, 0L, SEEK_SET) == -1)
						goto get_disk_file_exit;
	if (fsize > (long) _HEAP_MAXREQ ||
		(*ppszBuf = my_malloc ((size_t) fsize)) == NULL)
						goto get_disk_file_exit;

	psz = *ppszBuf;
	while (fgets(line,sizeof(line),f1)) {

		line[sizeof(line)-1] = '\0';
		trnbln(line);
		/* fixtabs(p,line,sizeof(line)); */
		strcpy (psz, line);
		psz += strlen (line) + 1; /* Skip over trailing null as well */
		(*nbuf)++;
	}
	res = TRUE;
get_disk_file_exit:
	fclose(f1);
	return (res);
}

/*
 *	add_filename - add name to list of open files
 */

void add_filename(BYTE far *name)
{
	int nc; 	/* Char count */
	OPENFILE *op;	/* Open file entry */

	if (SysInfo->openlen < 1) {
		SysInfo->openfiles = sysbuf_alloc(sizeof(OPENFILE));
		op = sysbuf_ptr(SysInfo->openfiles);
	}
	else {
		SysInfo->openfiles = sysbuf_realloc(SysInfo->openfiles,(SysInfo->openlen+1) * sizeof(OPENFILE));
		op = (OPENFILE *)sysbuf_ptr(SysInfo->openfiles) + SysInfo->openlen;
	}
	SysInfo->openlen++;

	memset(op,0,sizeof(OPENFILE));
	_fmemcpy(op->name,name,8);
	nc = trnbln(op->name);
	if (_fmemcmp(name+8,MSG4170,3) != 0) {
		op->name[nc++] = '.';
		_fmemcpy(op->name+nc,name+8,3);
		trnbln(op->name);
	}
}

/*
 *	fixtabs - expand tab characters into spaces
 */

void fixtabs(char *dst,char *src,int n)
{
	int col;		/* Column counter */

	col = 0;
	while (col<n) {
		if (*src == '\0') break;
		if (*src == '\t') {
			src++;
			do {
				*dst++ = ' ';
				col++;
			} while (col<n && (col&7) != 0);
			continue;
		}
		else {
			*dst = *src++;
			dst++;
			col++;
		}
	}
	*dst = '\0';
}

/*
 *	dosdatcmp - compare two dos data items
 */

int _cdecl dosdatcmp(
	void *p1,	/* Pointer to first item */
	void *p2)	/* Pointer to second item */
{
	if (((DOSDATA *)p1)->faddr < ((DOSDATA *)p2)->faddr) return -1;
	if (((DOSDATA *)p1)->faddr > ((DOSDATA *)p2)->faddr) return  1;

	return 0;
}

/* Get stats for listed files. */
/* We'll save the name, size, date, and time for each one. */
void get_file_stats (char *dir, 	/* Directory (w/trailing backslash) */
			 char **fspecs, /* List of filespecs, ending w/NULL */
			 SYSBUFH *pFiles) /* Pointer to save pointer */
{
  char temp[256];
  struct find_t f;
  SYSBUFH newh;
  FILESTATS _far *lpLast = NULL;

  while (*fspecs) {
	sprintf (temp, "%s%s", dir, *fspecs);

	if (!_dos_findfirst (temp, _A_ARCH|_A_HIDDEN|_A_RDONLY|_A_SYSTEM, &f))
		do {
		  newh = sysbuf_alloc (sizeof (FILESTATS));
		  if (lpLast) lpLast->next = newh;
		  else *pFiles = newh;
		  lpLast = sysbuf_ptr (newh);
		  _fstrcpy (lpLast->fname, f.name);
		  lpLast->fsize = f.size;
		  lpLast->ftime = f.wr_time;
		  lpLast->fdate = f.wr_date;
		  /* lpLast->fattr = f.attrib; */
		  lpLast->next = 0;
		} while (!_dos_findnext (&f));

	fspecs++;
  } /* not end of list */

} /* get_file_stats () */

/* Try to open and read MAXIMIZE.BST.  Return success==1, failure==0. */
/* Note that this won't work with a pre-7.0 Move'EM MAXIMIZE.BST. */
int read_maxbst (char *fname)
{
  int fh;
  DWORD garbage;
  MAXIMIZEBST tmp, *pLast = NULL;
  SYSBUFH newh;
  int subsegs=0;

  if ((fh = open (fname, O_BINARY|O_RDONLY)) != -1) {

	read (fh, &garbage, sizeof(garbage)); /* Discard psumfit */
	read (fh, &SysInfo->MaximizeBestsize,
				sizeof(SysInfo->MaximizeBestsize));
	read (fh, &garbage, sizeof(garbage)); /* Discard psubsegs (0 if */
						/* Move'EM Maximize) */

	/* We've inflated the MAXIMIZEBST structure by */
	/* one byte to accommodate the subseg flag. */
	while (read (fh, &tmp, sizeof (tmp)-1) != -1) {
	  if (!tmp.next) {
	    if (subsegs) break;
	    else subsegs++;
	  } /* End of list */
	  else {
	    tmp.next = 0;
	    tmp.subseg = (BYTE) subsegs;
	    sysbuf_store (&newh, &tmp, sizeof(tmp));
	    if (pLast)	pLast->next = newh;
	    else SysInfo->pMaxBest = newh;
	    pLast = sysbuf_ptr (newh);
	  } /* Valid entry */
	} /* Read SUMFIT and SUBFIT data */

	close (fh);
	return (1);

  } /* Opened it OK */
  else return (0);

} /* read_maxbst */

void get_qualitas_data (void)
{
  WORD highstart, loadseg = 0xffff;
  LSEGDATA _far *lpLseg, _far *lpLast = NULL;
  SYSBUFH newh;
  char maxbstname[256];

  if (SysInfo->pszMaxdir) get_file_stats (sysbuf_ptr (SysInfo->pszMaxdir),
	MaxFspecs, &SysInfo->pQFiles);

  /* Save LSEG data */
  if (qmaxpres (&highstart, &loadseg) || qmovpres (&highstart, &loadseg)) {
	while (loadseg != 0xffff) {
	  lpLseg = FAR_PTR(loadseg,0);
	  sysbuf_store (&newh, lpLseg, sizeof(LSEGDATA));
	  if (lpLast) lpLast->next = newh;
	  else SysInfo->pLseg = newh;
	  loadseg = lpLseg->next;
	  lpLast = sysbuf_ptr (newh);
	  lpLast->next = 0;
	  /* The LSEG name doesn't have room for a trailing NULL. */
	  /* We don't need the prev field, so we move it down two bytes. */
	  _fstrncpy (lpLast->fne, &lpLast->fne[2], 12);
	  lpLast->fne[12] = '\0';
	} /* while not end of chain */
  } /* Got an LSEG */

  /* Look for MAXIMIZE.BST in the MAX directory. */
  if (SysInfo->pszMaxdir) {
	sprintf (maxbstname, "%sMAXIMIZE.BST", sysbuf_ptr (SysInfo->pszMaxdir));
	if (read_maxbst (maxbstname)) return;
  } /* Check Maxdir */

  /* Look for MAXIMIZE.BST in the ASQ.EXE directory. */
  /* This may be necessary even if Maxdir exists, because we may have */
  /* a stub directory for CONFIG.SYS use because of drive compression. */
  get_exepath (maxbstname, sizeof(maxbstname));
  strcat (maxbstname, "MAXIMIZE.BST");
  read_maxbst (maxbstname);

} /* get_qualitas_data () */

/* Get Plug and Play data, return TRUE if successful */
BOOL
GetPnPData( void ) {

	DWORD dwPnPEntry;
	WORD wPnPDataSeg, wNode, wReadNode;
	BYTE __far *lpBuff, __far *lpStart;
	int wNumNodes, wMaxNodeSize;
	LPPNPBIOS_STR lpPnP;
	char szPnPText[ _MAX_PATH ];
	WORD pwIDs[ 64 ];
	int iNumIDs;

	wNumNodes = 0;
	wMaxNodeSize = 0;
	SysInfo->wNumNodes = 0;

	dwPnPEntry = pnp_vm( &wPnPDataSeg );

	if (!dwPnPEntry) {
		return FALSE;
	} /* Failure */

	lpPnP = pnp_bios_str();
	if (!lpPnP) {
		return FALSE;
	} /* Couldn't get BIOS structure */

	/* Save version as a BCD word rather than a BCD byte */
	SysInfo->wPnP_ver = lpPnP->bVer;
	SysInfo->wPnP_ver = (SysInfo->wPnP_ver & 0x0f) |
			    ((SysInfo->wPnP_ver & 0xf0) << 4);

	if (fnGetNumNodes( PnP_GET_NUM_NODES, &wNumNodes, &wMaxNodeSize,
				wPnPDataSeg ) != PnP_SUCCESS) {
		return FALSE;
	} /* Unable to get number of nodes */

	SysInfo->wNumNodes = (WORD)wNumNodes;
	SysInfo->wMaxNodeSize = (WORD)wMaxNodeSize;

	/* Allocate buffer */
	if (((DWORD)wNumNodes) * wMaxNodeSize > 32767L - 16L ||
		wNumNodes <= 0 || wMaxNodeSize <= 0 ||
	    !(SysInfo->pNodeList = sysbuf_alloc( wNumNodes * wMaxNodeSize ))) {
		return FALSE;
	} /* Too big or unable to allocate */

	/* Get the maximum number of IDs we can get descriptions for */
	iNumIDs = sizeof( pwIDs ) / sizeof( pwIDs[ 0 ] );
	if (iNumIDs > (int)wNumNodes) {
		iNumIDs = wNumNodes;
	}

	lpStart = lpBuff = sysbuf_ptr( SysInfo->pNodeList );

	/* Now get data for nodes.  Pack one after the other - some space */
	/* at the end should be left unused. */
	for (wNode = wReadNode = 0;
		 fnGetSetDevNode( PnP_GET_DEV_NODE, &wNode, lpBuff,
					GSDN_CTL_CURRENT, wPnPDataSeg )
					== PnP_SUCCESS &&
		 wNode < (WORD)wNumNodes;
		 lpBuff += ((LPPNP_DEVNODE)lpBuff)->wLen) {

		if ((int)wReadNode < iNumIDs) {

			LPPNP_DEVNODE lpD = (LPPNP_DEVNODE)lpBuff;

			pwIDs[ wReadNode ] = lpD->paID[ 2 ] * 256 + lpD->paID[ 3 ];
		}

		wReadNode = wNode;

		/* Check for last node */
		if (wNode >= 255) break;

	} /* for all nodes */

	/* FIXME also get statically allocated resources ??? */

	/* Terminate list with a length word of 0 */
	((LPPNP_DEVNODE)lpBuff)->wLen = 0;

	/* Reallocate and save (approximate) actual length */
	SysInfo->cbNodeList = wMaxNodeSize + (int)(lpBuff - lpStart);
	/* SysInfo->pNodeList = sysbuf_realloc( SysInfo->pNodeList,
	 *					SysInfo->cbNodeList ); */

	/* Now read descriptions from PNP.TXT */
	/* Get PNP.TXT path */
	get_exepath( szPnPText, sizeof( szPnPText ) );
	strcat( szPnPText, "PNP.TXT" );
	if (!_access( szPnPText, 00 )) {
		SysInfo->ppszPnPDesc = sysbuf_alloc( wNumNodes * MAXPNP_DESC );
		if (SysInfo->ppszPnPDesc) {

			char __far *ppszPnPDesc = sysbuf_ptr( SysInfo->ppszPnPDesc );
			FILE *pfPNP = fopen( szPnPText, "r" );
			char szBuff[ 128 ];
			WORD wID;
			int nDesc, nOff;
			char *pszLF;

			_fmemset( ppszPnPDesc, 0, wNumNodes * MAXPNP_DESC );
			if (pfPNP) {

				while (fgets( szBuff, sizeof( szBuff ), pfPNP )) {
					/* Make sure it's terminated */
					szBuff[ sizeof( szBuff ) - 1 ] = '\0';

					/* Make sure it's the right type */
					if (strncmp( szBuff, "PNP", 3 )) {
						continue;
					} /* Ignore it */

					/* Clobber trailing LF */
					if (pszLF = strchr( szBuff, '\n' )) {
						*pszLF = '\0';
					}

					/* Grope our list of IDs */
					if (sscanf( &szBuff[ 3 ], "%4x %n", &wID, &nOff ) < 1) {
						continue;
					} /* Not a valid hex word */

					for (nDesc = 0; nDesc < iNumIDs;
						nDesc++) {
					  if (pwIDs[ nDesc ] == wID) {
						_fstrncpy( &ppszPnPDesc[ nDesc * MAXPNP_DESC ], &szBuff[ nOff + 3 ], MAXPNP_DESC - 1 );
					  } /* Got a match */
					} /* for all IDs */

				} /* Not EOF */

				fclose( pfPNP );

			} /* File opened OK */

		} /* Buffer allocated OK */
	} /* Attempt to allocate description text buffer */

	return TRUE;

} /* GetPnPData */

/* Get CD-ROM data.  First check for MSCDEX installed. */
void get_cdrom( void ) {

	WORD nCDs, nFirstCD;

	nCDs = 0;
	_asm {

		mov ax,0xdada	; Value to push
		push ax 	; MSCDEX is supposed to change it
		mov ax,0x1100	; Detect MSCDEX
		int 0x2f	; Word on stack changed, AL=ff if installed
		cmp al,0xff	; Izit installed
		pop ax		; Get (possibly) changed word from stack
		jne no_mscdex	; Jump if not installed

		cmp ax,0xadad	; Is Microsoft's present?
		je mscdex	; Jump if so

		cmp ax,0xdadb	; Is Lotus's present?
		jne no_mscdex	; Jump if not

mscdex:
		mov ax,0x1500	; CD-ROM installation check
		sub bx,bx	; Number of drives on return
		mov cx,bx	; Starting drive (origin 0=a:) on return
		int 0x2f	; BX = number of drives, CX = starting drive

		mov nCDs,bx	; Save number of drives
		mov nFirstCD,cx ; Starting drive (0=a:, etc)

no_mscdex:
		;
	}

	SysInfo->nCDs = nCDs;
	SysInfo->nFirstCD = nFirstCD;

} /* get_cdrom() */

/* Tue Nov 20 18:37:25 1990 alan:  work */
/* Wed Nov 21 10:44:31 1990 alan:  fix bugs */
/* Mon Nov 26 17:05:47 1990 alan:  rwsystxt and other bugs */
/* Tue Nov 27 13:25:08 1990 alan:  snapshot bugs */
/* Tue Nov 27 15:09:32 1990 alan:  bugs */
/* Thu Nov 29 16:42:00 1990 alan:  fix bugs */
/* Thu Nov 29 21:57:28 1990 alan:  fix bugs */
/* Wed Dec 19 17:12:50 1990 alan:  new mapping technique */
/* Wed Dec 26 13:21:55 1990 alan:  fix bugs */
/* Thu Jan 03 10:17:01 1991 alan:  changes for ps/2 128k bios */
/* Tue Feb 19 15:41:16 1991 alan:  fix rom_find bug */
/* Wed Feb 20 13:14:14 1991 alan:  fix map_holes bug */
/* Wed Mar 13 21:03:46 1991 alan:  fix bugs */
/* Thu Mar 28 12:39:42 1991 alan:  fix bugs */
/* Thu Mar 28 21:58:20 1991 alan:  fix bugs */
