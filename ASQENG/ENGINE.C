/*' $Header:   P:/PVCS/MAX/ASQENG/ENGINE.C_V   1.2   02 Jun 1997 14:40:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ENGINE.C								      *
 *									      *
 * Access to ASQ engine 						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sysinfo.h"            /* System info functions */
#include "info.h"               /* Info text functions */
#include <engine.h>		/* Structures and functions */
#include <myalloc.h>		/* malloc() and free() cover functions */

#include "mem_info.h"           /* Memory info functions */
#include "cfg_info.h"           /* Configuration info functions */
#include "hdw_info.h"           /* Hardware info functions */

/* Array of functions to create info text */
static void (*InfoFunc[INFO_TOOBIG])(HANDLE handle) = {
	0,			/* Entry 0 not used */
	Memory_Summary, 	/* INFO_MEM_SUMM */
	Memory_Low_DOS, 	/* INFO_MEM_LOW */
	Memory_High_DOS,	/* INFO_MEM_HIGH */
	Memory_ROM_Scan,	/* INFO_MEM_ROM */
	Memory_Interrupts,	/* INFO_MEM_INT */
	Memory_Extended,	/* INFO_MEM_EXT */
	Memory_Expanded,	/* INFO_MEM_EXP */
	Memory_EMS_Usage,	/* INFO_MEM_EMS */
	Memory_XMS,		/* INFO_MEM_XMS */
	Memory_Timing,		/* INFO_MEM_TIME */
	Config_Summary, 	/* INFO_CFG_SUMM */
	Config_CONFIG_SYS,	/* INFO_CFG_CONFIG */
	Config_AUTOEXEC_BAT,	/* INFO_CFG_AUTOEXEC */
	Config_386MAX_PRO,	/* INFO_CFG_386MAX */
	Config_ExtraDOS_PRO,	/* INFO_CFG_EXTRADOS */
	Config_SYSINI,		/* INFO_CFG_SYSINI */
	Config_Qualitas,	/* INFO_CFG_QUALITAS */
	Config_Windows, 	/* INFO_CFG_WINDOWS */
	Hardware_Summary,	/* INFO_HDW_SUMM */
	Hardware_Video, 	/* INFO_HDW_VIDEO */
	Hardware_Drives,	/* INFO_HDW_DRIVES */
	Hardware_Ports, 	/* INFO_HDW_PORTS */
	Hardware_BIOS_Detail,	/* INFO_HDW_BIOS */
	Hardware_CMOS_Detail,	/* INFO_HDW_CMOS */
	Config_Snapshot 	/* INFO_SNAPSHOT */
};

/* Local functions */
static int get_maxflag(void);	/* Return max recommendation flag */

static int fillin_report(	/* Fill in report structure */
	ENGREPORT *rept);	/* Pointer to structure */

static int fillin_snapinfo(	/* Fill in report structure */
	ENGSNAPINFO *info);	/* Pointer to structure */

/* Exported functions */

int engine_control(		/* General control of engine */
	ENGCTRL ctrl,		/* Control opcode */
	void *ptr,		/* Pointer argument, depends on ctrl */
	WORD num)		/* Numeric argument, depends on ctrl */
/* Return:  0 if successful */
{
	if (!SysInfo) {
		SysInfo = my_malloc (sizeof (SYSINFO));
		if (!SysInfo) return (-1);
		memset(SysInfo, 0, sizeof(SYSINFO));
	} /* SysInfo not allocated yet */
	switch (ctrl) {
	case CTRL_PREINIT:	/* System info pre-init, no args */
		return sysinfo_preinit();
	case CTRL_SYSINIT:	/* System info init, no args */
		return sysinfo_init(ptr,num);
	case CTRL_SYSPURGE:	/* System info purge, no args */
		sysinfo_purge();
		return 0;
	case CTRL_SYSREAD:	/* Read sys info from file, ptr = file name */
		return sysinfo_read(ptr,num);
	case CTRL_SYSWRITE:	/* Write sys info to file, ptr = file name */
		return sysinfo_write(ptr);
	case CTRL_SETBUF:	/* Set up scratch buffer, ptr = buffer, num = sizeof(buffer) */
		info_setbuf(ptr,num);
		return 0;
	case CTRL_ISETUP:	/* Set up specific info block, ptr = ENGTEXT, num = INFONUM */
		{
			ENGTEXT *text;

			text = ptr;
			text->width = 0;
			text->length = 0;
			text->current = 0;
		/*	text->ntext		set by caller */
			text->handle = info_init();
			if (!text->handle) return -1;

			/**** Dispatch to info funcs ****/
			if (num > INFO_UNKNOWN && num < INFO_TOOBIG) {
				(InfoFunc[num])(text->handle);
				text->handle = info_finish(text->handle);
				text->length = info_length(text->handle);
				text->width = info_width(text->handle);
			}
			else	return -1;
		}
		return 0;
	case CTRL_ISEEK:	/* Seek to specific line of info block, */
		{
			ENGTEXT far *text;

			text = ptr;
			text->current = info_seek(text->handle,num);
		}
		return 0;
	case CTRL_IFETCH:	/* Fetch next line of info block, ptr = ENGTEXT */
		{
			ENGTEXT far *text;

			text = ptr;
			text->current = info_fetch(text->handle,
				text->current,
				text->buf,
				text->nbuf);
			if (!text->current) return -1;
		}
		return 0;
	case CTRL_IPURGE:	/* Purge specific info block, ptr = ENGTEXT */
		{
			ENGTEXT *text;

			text = ptr;
			info_purge(text->handle);
			memset(text,0,sizeof(ENGTEXT));
		}
		return 0;
	case CTRL_REPORT:	/* Return 386max flag for recommendations, ptr = int */
		return fillin_report(ptr);
	case CTRL_GETTITLE:	/* Get snapshot title */
		num = min(num,sizeof(SysInfo->snaptitle));
		if (num < 2) return -1;
		strncpy(ptr,SysInfo->snaptitle,num-1);
		*(((char *)ptr)+num) = '\0';
		return 0;
	case CTRL_PUTTITLE:	/* Put snapshot title */
		if (!num) num = strlen(ptr);
		num = min(num,sizeof(SysInfo->snaptitle)-1);
		if (num < 2) return -1;
		strncpy(SysInfo->snaptitle,ptr,num);
		SysInfo->snaptitle[num] = '\0';
		return 0;
	case CTRL_SNAPINFO:	/* Get info about unopened snapshot */
		return fillin_snapinfo(ptr);
	case CTRL_SETBOOT:	/* Set (override) boot drive */
		BootOverride = *(char *)ptr;
		return 0;
	}
	return -1;
}

static int fillin_report(	/* Fill in report structure */
	ENGREPORT *rept)	/* Pointer to structure */
{
	memset(rept,0,sizeof(ENGREPORT));
	rept->cpu = SysInfo->cpu;
	rept->dosver = SysInfo->dosver;
	rept->files = SysInfo->config.files;
	rept->buffers = SysInfo->config.buffers;
	rept->envsize = SysInfo->envsize;
	rept->envused = SysInfo->envused;
	rept->fcbx = SysInfo->config.fcbx;
	rept->fcby = SysInfo->config.fcby;
	rept->stackx = SysInfo->config.stackx;
	rept->stacky = SysInfo->config.stacky;
	rept->maxflag = get_maxflag();
	rept->print = SysInfo->config.print;
	rept->fastopen = SysInfo->config.fastopen;
	if (SysInfo->flags.cfg)
		sprintf(rept->config_sys,"%c:\\CONFIG.SYS",SysInfo->bootdrv+'A');
	if (SysInfo->flags.aut)
		rept->pszAutoexec_bat = sysbuf_ptr (SysInfo->config.startupbat);

	if (SysInfo->config.maxpro)
		rept->pszMax_pro = sysbuf_ptr(SysInfo->config.maxpro);

	if (SysInfo->config.extradospro)
		rept->pszExtraDOS_pro = sysbuf_ptr(SysInfo->config.extradospro);

	if (SysInfo->WindowsData.sysininame)
		rept->pszSYSINI = sysbuf_ptr(SysInfo->WindowsData.sysininame);

	if (SysInfo->WindowsData.windowsdir)
		rept->pszWindir = sysbuf_ptr(SysInfo->WindowsData.windowsdir);


	/* Count up device driver and tsr bytes that MIGHT be loaded high */
	/* I admit this is kludgey.  --acl */
	{
		UMAP *ump;		/* Pointer to memory map */
		UMAP *umpend;		/* Pointer to end of memory map */

		rept->ddbytes = rept->tsrbytes = 0;

		ump = sysbuf_ptr(SysInfo->umap);
		umpend = ump + SysInfo->umaplen;

		while (ump < umpend) {
			if (ump->flags.high) break;
			if (ump->class == CLASS_DEV && ump->length > 512) {
				rept->ddbytes += ump->length;
			}
			else if ((ump->class == CLASS_PRGM || ump->class == CLASS_ENV) &&
				 stricmp(ump->name,"COMMAND.COM") != 0) {
				rept->tsrbytes += ump->length;
			}
			ump++;
		}
	}

	return 0;	/* Always success */
}

/*
 *	get_maxflag - return 386MAX recommendation
 */

static int get_maxflag(void)	/* Return max recommendation flag */
{
/*
 * This function decides what 386max family product to recommend, based
 * on the system:
 *
 * If it's a real 386 IBM MCA, recommend Blue Max.
 * If it's a 386 with 640k main and at least 256k extended,
 *    then recommend 386max
 * If it's a 286 with NEAT and 256k extended OR has Lim 4 hardware,
 *    then recommend Mov'em
 * else recommend nothing.
 */
	if (SysInfo->cpu.cpu_type >= CPU_80386 &&
	    SysInfo->flags.mca &&
	   (SysInfo->biosid.bus_flag & 1)) return MAX_BLUE;
	if (SysInfo->cpu.cpu_type >= CPU_80386 &&
	    SysInfo->extmem >= 256) return MAX_386;
	if (SysInfo->cpu.cpu_type == CPU_80286 ) {
		if (SysInfo->chipset == CHIPSET_NEAT) return MAX_MOVE;
		else if (SysInfo->flags.lim4) {
			/* Our definition of Lim 4 hardware is:
			 *   Any mappable pages in low DOS other than
			 *   the Page Frame.
			 */
			WORD kk;
			EMSMAP *emsmap;

			emsmap = sysbuf_ptr(SysInfo->emsmap);
			for (kk = 0; kk < SysInfo->emsparm.mpages; kk++) {
				WORD addr = emsmap[kk].base;

				if (addr < 0xA000 && (!SysInfo->emsparm.frame ||
				    !(addr >= SysInfo->emsparm.frame &&
				      addr < SysInfo->emsparm.frame + 0x1000))){
					return MAX_MOVE;
				}
			}
		}
	}
	return 0;
}

static int fillin_snapinfo(	/* Fill in report structure */
	ENGSNAPINFO *info)	/* Pointer to structure */
{
	int rtn;

	rtn = sysinfo_look(info->name,info->title,sizeof(info->title),info->date,info->time);
	return rtn;
}

/* Tue Nov 20 18:38:25 1990 alan:  work */
/* Mon Nov 26 17:05:49 1990 alan:  rwsystxt and other bugs */
/* Mon Feb 18 13:28:41 1991 alan:  this is a very much longer comment than what was there before */
