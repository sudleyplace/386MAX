/*' $Header:   P:/PVCS/MAX/ASQENG/WRITSYS.C_V   1.2   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * WRITSYS.C								      *
 *									      *
 * Functions to write ASQ snapshot file 				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <ctype.h>

#include <commfunc.h>		/* Utility functions */
#include <dcache.h>		/* Disk cache detection functions and globals */
#include "mapinfo.h"            /* Map info functions */
#include "sysinfo.h"            /* System info structures */
#define OWNER
#include "systext.h"            /* System info keyword text */
#undef OWNER

/* Local Variables */
static FILE *RwFile;		/* Stream pointer for input/output file */

/* Local Functions */
static void near prt_double(RWKEY kw,double value);
static void near prt_string(RWKEY kw,char *value);
static void near prt_HEXWORD(RWKEY kw,WORD value);
static void near prt_DECWORD(RWKEY kw,WORD value);
static void near prt_DECINT(RWKEY kw,int value);
static void near prt_DECDWORD(RWKEY kw,DWORD value);
static void near prt_HEXDWORD(RWKEY kw,DWORD value);
static void near prt_HEXWORDS(RWKEY kw,WORD *value,WORD nvalue);
static void near prt_HEXBYTES(RWKEY kw,BYTE *value,WORD nvalue);
static void near prt_FARPTRS(RWKEY kw,void far * (*value),WORD nvalue);
static void near prt_SYSBUFH(RWKEY kw,SYSBUFH value);
static void near prt_FILE(RWKEY kw,char *pszValue,WORD nvalue,SYSBUFH Name);

static void near prt_VERSION(RWKEY kw,WORD value);
static void near prt_SNAPDATE(WORD *value);
static void near prt_SNAPTIME(WORD *value);
static void near prt_FLAGS(struct _sysflags *value);
static void near prt_CPUPARM(CPUPARM *value);
static void near prt_BIOSID(BIOSID *value);
static void near prt_VIDEO(VIDEO *value,WORD nvalue);
static void near prt_MOUSE(MOUSEINFO *value);
static void near prt_EMSPARM(EMSPARM *value);
static void near prt_XMSPARM(XMSPARM *value);
static void near prt_CONFIG(CONFIG *value);
static void near prt_DCACHE(void);
static void near prt_DRIVEPARM(RWKEY kw,DRIVEPARM *value);
static void near prt_PARTTABLE(RWKEY kw,PARTTABLE *value,WORD nvalue);
static void near prt_MCAID(MCAID *value,WORD nvalue);
static void near prt_EMSHAND(EMSHAND *value1,WORD nvalue);
static void near prt_EMSMAP(EMSMAP *value,WORD nvalue);
static void near prt_TIMELIST(SYSBUFH value,WORD nvalue);
static void near prt_ROMLIST(SYSBUFH value,WORD nvalue);
static void near prt_FLEXROM(SYSBUFH value,WORD nvalue);
static void near prt_HOLES(RWKEY kw,SYSBUFH value,WORD nvalue);
static void near prt_OPENFILE(SYSBUFH value,WORD nvalue);
static void near prt_ENVSTR(SYSBUFH value,WORD nvalue);
static void near prt_MACINFO(RWKEY kw,SYSBUFH value,WORD nvalue);
static void near prt_DDLIST(SYSBUFH value,WORD nvalue);
static void near prt_DOSDATA(SYSBUFH value,WORD nvalue);
static void near prt_ADFINFO(SYSBUFH *value,WORD nvalue);
static void near prt_ADFOPTION(ADFINFO *value);
static void near prt_ADFCHOICE(ADFOPTION *value);
static void near prt_FSTATS(RWKEY kw,SYSBUFH value);
static void near prt_LSEG(SYSBUFH value);
static void near prt_MAXBEST(SYSBUFH value);
static void near prt_STRARRAY( RWKEY kw, SYSBUFH h, WORD wCount, WORD wWidth );

static void near lprintf(char *fmt, ...);

static void near lprintf(char *fmt, ...)
/* Launder quotes in output string and translate ^Z to " */
{
	va_list arglist;
	char temp[512];
	int i;
	char c;

	va_start(arglist, fmt);

	vsprintf(temp,fmt,arglist);

	for (i=0; (c = temp[i]) && i < sizeof(temp); i++) {
		if (c == '\\' || c == '"') fputc('\\', RwFile);
		else if (c == '\x1a') c = '"';
		fputc(c, RwFile);
	}

} /* End lprintf() */

/*
 *	sysinfo_write - write system info to file
 *
 *	BEWARE:  For this to work, the glist's have to be of array type
 */

int sysinfo_write(char *name)
{
	RwFile = fopen(name,"w");
	if (!RwFile) return -1;

	fprintf(RwFile,"; %s\n",name);

	if (*SysInfo->snaptitle) {
		prt_string(K_SNAPTITLE,SysInfo->snaptitle);
	}
	prt_SNAPDATE(SysInfo->snapdate);
	prt_SNAPTIME(SysInfo->snaptime);

	prt_VERSION(K_ASQVER,	SysInfo->version);

	prt_FLAGS(&SysInfo->flags);

	prt_HEXWORD(K_ROMSEG,	SysInfo->romseg);
	prt_HEXWORD(K_ROMSIZE,	SysInfo->romsize);
	prt_DECWORD(K_BOOTDRV,	SysInfo->bootdrv);

	prt_CPUPARM(&SysInfo->cpu);

	prt_double(K_MHZ,	SysInfo->mhz);
	prt_HEXWORD(K_CHIPSET,	SysInfo->chipset);
	prt_DECWORD(K_LOGDRV,	SysInfo->logdrv);
	prt_HEXWORD(K_DOSVER,	SysInfo->dosver);
	prt_string(K_IONAME,	SysInfo->ioname);
	prt_string(K_DOSNAME,	SysInfo->dosname);
	prt_string(K_COMNAME,	SysInfo->comname);
	prt_DECWORD(K_BASEMEM,	SysInfo->basemem);
	prt_DECWORD(K_EXTMEM,	SysInfo->extmem);
	prt_DECWORD(K_EXTFREE,	SysInfo->extfree);

	prt_BIOSID(&SysInfo->biosid);

	prt_SYSBUFH(K_BIOSMFR,	SysInfo->biosmfr);
	prt_SYSBUFH(K_MACHNAME, SysInfo->machname);

	prt_DECWORD(K_ENVSIZE,	SysInfo->envsize);
	prt_DECWORD(K_ENVUSED,	SysInfo->envused);

	prt_VIDEO(SysInfo->video,SysInfo->nvideo);
	if (*SysInfo->sv_vendor) {
		prt_string(K_SVVENDOR,SysInfo->sv_vendor);
	}
	if (*SysInfo->sv_model) {
		prt_string(K_SVMODEL,SysInfo->sv_model);
	}
	prt_MOUSE(&SysInfo->mouse);
	prt_HEXWORD(K_KEYBOARD,SysInfo->keyboard);

	prt_HEXWORD(K_DISKROM,	SysInfo->diskrom);
	prt_HEXWORD(K_DISKROMSIZE,SysInfo->diskromsize);
	prt_ROMLIST(SysInfo->romlist,SysInfo->romlen);
	prt_FLEXROM(SysInfo->flexlist,SysInfo->flexlen);
	prt_HOLES(K_HOLES,SysInfo->hmap,SysInfo->hmaplen);
	prt_HOLES(K_EXTRAMAP,SysInfo->emap,SysInfo->emaplen);

	prt_HEXDWORD(K_IOSTART, SysInfo->io_start);
	prt_HEXDWORD(K_DOSSTART,SysInfo->dos_start);
	prt_HEXDWORD(K_DEVSTART,SysInfo->dev_start);
	prt_HEXDWORD(K_DATASTART,SysInfo->data_start);
	prt_HEXDWORD(K_DATAEND, SysInfo->data_end);
	prt_HEXWORD(K_PSP,	SysInfo->psp);

	if (SysInfo->ems_xms) prt_DECWORD(K_EMSXMS,SysInfo->ems_xms);
	if (SysInfo->flags.ems) {
		prt_EMSPARM(&SysInfo->emsparm);
		if (SysInfo->emsparm.acthand > 0) {
			if (SysInfo->flags.lim4) prt_EMSHAND(sysbuf_ptr(SysInfo->emshand),SysInfo->emsparm.acthand);
			prt_HEXWORDS(K_EMSHSIZE,sysbuf_ptr(SysInfo->emssize),SysInfo->emsparm.acthand);
		}
		if (SysInfo->emsparm.mpages > 0) {
			prt_EMSMAP(sysbuf_ptr(SysInfo->emsmap),SysInfo->emsparm.mpages);
		}
	}
	if (SysInfo->flags.xms) {
		prt_XMSPARM(&SysInfo->xmsparm);
	}

	if (SysInfo->dpmi_ver) {
		prt_HEXWORD(K_DPMIVER,	SysInfo->dpmi_ver);
		prt_DECWORD(K_DPMI32,	SysInfo->dpmi_32bit);
	}

	prt_TIMELIST(SysInfo->timelist,SysInfo->timelen);

	prt_CONFIG(&SysInfo->config);
	prt_SYSBUFH(K_SHELL,SysInfo->config.shell);
	prt_SYSBUFH(K_COUNTRY,SysInfo->config.country);
	prt_SYSBUFH(K_DRIVPARM,SysInfo->config.drivparm);

	prt_ENVSTR(SysInfo->envstrs,SysInfo->envlen);

	prt_DECWORD(K_OPENFCBS, SysInfo->openfcbs);
	prt_OPENFILE(SysInfo->openfiles,SysInfo->openlen);

	prt_DCACHE();
	prt_DRIVEPARM(K_FDRIVE,SysInfo->fdrive);
	prt_DRIVEPARM(K_HDRIVE,SysInfo->hdrive);

	if (SysInfo->hdrive[0].heads) {
		prt_PARTTABLE(K_HPART0,SysInfo->hpart0,4);
	}
	if (SysInfo->hdrive[1].heads) {
		prt_PARTTABLE(K_HPART1,SysInfo->hpart1,4);
	}

	prt_FILE(K_CONFIGSYS,SysInfo->pszCnfgsys,SysInfo->cnfglen, 0);
	prt_FILE(K_AUTOBAT,SysInfo->pszAutobat,SysInfo->autolen,
			SysInfo->config.startupbat);
	prt_FILE(K_MAXPRO,SysInfo->pszMaxprof,SysInfo->proflen,
			SysInfo->config.maxpro);
	prt_FILE(K_EXTRADOSPRO,SysInfo->pszExtrados,SysInfo->extradoslen,
			SysInfo->config.extradospro);
	prt_FILE(K_SYSINI,SysInfo->pszSysini,SysInfo->sysinilen,
			SysInfo->WindowsData.sysininame);
	prt_FSTATS(K_QFILES,SysInfo->pQFiles);
	prt_LSEG(SysInfo->pLseg);
	if (SysInfo->MaximizeBestsize)
		prt_HEXWORD(K_MAXBESTSIZE,SysInfo->MaximizeBestsize);
	prt_MAXBEST(SysInfo->pMaxBest);

	prt_HEXBYTES(K_BIOSDATA,(BYTE *)&SysInfo->biosdata,sizeof(BIOSDATA));
	if (SysInfo->flags.cmos) {
		prt_HEXBYTES(K_CMOS,SysInfo->cmos,CMOS_SIZE);
	}
	prt_FARPTRS(K_VECTORS,SysInfo->vectors,256);

	prt_MACINFO(K_LOWDOS,SysInfo->lowdos,SysInfo->nlowdos);
	prt_MACINFO(K_HIGHDOS,SysInfo->highdos,SysInfo->nhighdos);
	prt_MACINFO(K_HIGHLOAD,SysInfo->highload,SysInfo->nhighload);
	prt_DDLIST(SysInfo->ddlist,SysInfo->ddlen);
	prt_DOSDATA(SysInfo->dosdata,SysInfo->doslen);

	if (SysInfo->flags.mca) {
		prt_MCAID(SysInfo->mcaid,MCASLOTS);
		prt_ADFINFO(SysInfo->adf,MCASLOTS);
	}

	if (SysInfo->flags.gotwinver) {
		prt_HEXWORD(K_WINDOWSVER, SysInfo->WindowsData.windowsver);
	}
	prt_SYSBUFH(K_WINDOWSDIR, SysInfo->WindowsData.windowsdir);
	prt_FSTATS(K_WFILES,SysInfo->WindowsData.pWFiles);

	if (SysInfo->flags.pci) {
		prt_HEXWORD( K_PCIVER, SysInfo->pci_ver );
	}

	if (SysInfo->flags.pnp) {

		BYTE *pData = sysbuf_ptr( SysInfo->pNodeList );

		lprintf( "%-10s %04X %04X %04X\n", RwKeyword[ K_PNPDATA ].name,
				SysInfo->wPnP_ver, SysInfo->wNumNodes, SysInfo->wMaxNodeSize );
		prt_HEXBYTES( K_PNPNODES, pData, SysInfo->cbNodeList );
		if (SysInfo->ppszPnPDesc) {
			prt_STRARRAY( K_PNPDESC, SysInfo->ppszPnPDesc, SysInfo->wNumNodes, MAXPNP_DESC );
		}
	}

	lprintf( "%-10s %04X %04X\n", RwKeyword[ K_CDROM ].name,
		SysInfo->nCDs, SysInfo->nFirstCD );

	fprintf(RwFile,"%s\n",RwKeyword[K_END]);
	fclose(RwFile);
}

/*
========================================================================
*/

static void near prt_double(RWKEY kw,double value)
{
	lprintf("%-10s %f\n",RwKeyword[kw].name,value);
}

static void near prt_string(RWKEY kw,char *value)
{
	lprintf("%-10s \x1a%s\x1a\n",RwKeyword[kw].name,value);
}

static void near prt_HEXWORD(RWKEY kw,WORD value)
{
	lprintf("%-10s %04X\n",RwKeyword[kw].name,value);
}

static void near prt_DECWORD(RWKEY kw,WORD value)
{
	lprintf("%-10s %u\n",RwKeyword[kw].name,value);
}

static void near prt_DECINT(RWKEY kw,int value)
{
	lprintf("%-10s %d\n",RwKeyword[kw].name,value);
}

static void near prt_DECDWORD(RWKEY kw,DWORD value)
{
	lprintf("%-10s %lu\n",RwKeyword[kw].name,value);
}

static void near prt_HEXDWORD(RWKEY kw,DWORD value)
{
	lprintf("%-10s %lX\n",RwKeyword[kw].name,value);
}


static void near prt_HEXBYTES(RWKEY kw,BYTE *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		lprintf(" %02X",value[kk]);
		if ((kk % 25) == 24) lprintf("\n");
	}
	if ((kk % 25) != 0) lprintf("\n");
}

static void near prt_HEXWORDS(RWKEY kw,WORD *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		lprintf(" %04X",value[kk]);
		if ((kk % 16) == 15) lprintf("\n");
	}
	if ((kk % 16) != 0) lprintf("\n");
}

static void near prt_FARPTRS(RWKEY kw,void far * (*value),WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		lprintf(" %Fp",value[kk]);
		if ((kk % 4) == 3) lprintf("\n");
	}
	if ((kk % 4) != 0) lprintf("\n");
}

static void near prt_SYSBUFH(RWKEY kw,SYSBUFH value)
{
	if (!value) return;
	lprintf("%-10s \x1a%s\x1a\n",RwKeyword[kw].name,sysbuf_ptr(value));
}

static void near prt_FILE(RWKEY kw,char *pszValue,WORD nvalue,SYSBUFH Name)
{
	WORD kk;
	char *p;
	char fname[128];

	if (nvalue < 1) return;
	fname[0] = '\0';
	if (Name) sprintf (fname, " %s", sysbuf_ptr (Name));
	lprintf("%-10s %u%s\n",RwKeyword[kw].name,nvalue,fname);
	p = pszValue;
	for (kk = 0; kk < nvalue; kk++) {
		lprintf("%s\n",p);
		p += strlen(p) + 1;
	}
}

static void near prt_STRARRAY( RWKEY kw, SYSBUFH h, WORD wCount, WORD wWidth ) {

	WORD w;
	char *psz;

	lprintf( "%-10s %u\n", RwKeyword[ kw ].name, wCount );
	psz = sysbuf_ptr( h );
	for (w = 0; w < wCount; w++) {
		lprintf( "%s\n", psz );
		psz += wWidth;
	}

}

static void near prt_FSTATS(RWKEY kw,SYSBUFH value)
{
	WORD nvalue;
	FILESTATS *f;
	SYSBUFH h;

	if (!value) return;

	/* Count up the lines */
	for (nvalue = 0, h = value;
		h; h = f->next) {
	  f = sysbuf_ptr (h);
	  nvalue++;
	}

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);

	/* Now write 'em out */
	for (h = value; nvalue; nvalue--) {
	  f = sysbuf_ptr (h);
	  lprintf (" %x %x %lu %s\n", f->ftime, f->fdate, f->fsize, f->fname);
	  h = f->next;
	}
}

static void near prt_LSEG(SYSBUFH value)
{
	WORD nvalue;
	LSEGDATA *l;
	SYSBUFH h;

	if (!value) return;

	/* Count up the lines */
	for (nvalue = 0, h = value; h; h = l->next) {
	  l = sysbuf_ptr (h);
	  nvalue++;
	}

	lprintf("%-10s %u\n",RwKeyword[K_LSEG].name,nvalue);

	/* Now write 'em out */
	for (h = value; nvalue; nvalue--) {
	  l = sysbuf_ptr (h);
	  lprintf (" \x1a%s\x1a %x %x %x %x "
		   "%lx %lx %lx "
		   "%x %x  "
		   "%x %x %x  "
		   "%x %x %x\n",
		l->fne, l->rpara, l->epar0, l->epar1, l->rpar2,
		l->asize, l->lsize, l->isize,
		l->preg, l->ereg,
		l->flags, l->npara, l->grp,
		l->ownrhi, l->instlo, l->instlen);
	  h = l->next;
	}
}

static void near prt_MAXBEST(SYSBUFH value)
{
	WORD nvalue;
	MAXIMIZEBST *m;
	SYSBUFH h;

	if (!value) return;

	/* Count up the lines */
	for (nvalue = 0, h = value; h; h = m->next) {
	  m = sysbuf_ptr (h);
	  nvalue++;
	}

	lprintf("%-10s %u\n",RwKeyword[K_MAXBEST].name,nvalue);

	/* Now write 'em out */
	for (h = value; nvalue; nvalue--) {
	  m = sysbuf_ptr (h);
	  lprintf (" %x %x %x %x  %x %x %x %x  %x %x\n",
		m->ipara, m->rpara, m->epar0, m->epar1,
		m->preg, m->ereg, m->group, m->ord,
		m->lflags, m->subseg);
	  h = m->next;
	}
}

/* -------------------- */

static void near prt_VERSION(RWKEY kw,WORD value)
{
	lprintf("%-10s %d.%02d\n",RwKeyword[kw].name,HIBYTE(value),LOBYTE(value));
}

static void near prt_SNAPDATE(WORD *value)
{
	lprintf("%-10s %02u %02u %04u\n",
		RwKeyword[K_SNAPDATE].name,value[0],value[1],value[2]);
}

static void near prt_SNAPTIME(WORD *value)
{
	lprintf("%-10s %02u %02u %02u\n",
		RwKeyword[K_SNAPTIME].name,value[0],value[1],value[2]);
}

static void near prt_FLAGS(struct _sysflags *value)
{
	lprintf("%-10s \x1a",RwKeyword[K_FLAGS].name);
	if (value->pc)		lprintf(" pc");
	if (value->xt)		lprintf(" xt");
	if (value->at)		lprintf(" at");
	if (value->ps2) 	lprintf(" ps2");
	if (value->mca) 	lprintf(" mc");
	if (value->eisa)	lprintf(" eisa");
	if (value->pci) 	lprintf(" pci");
	if (value->pnp) 	lprintf(" pnp");
	if (value->cmos)	lprintf(" cmos");
	if (value->max) 	lprintf(" max");
	if (value->ems) 	lprintf(" ems");
	if (value->lim4)	lprintf(" lim4");
	if (value->xms) 	lprintf(" xms");
	if (value->readin)	lprintf(" rdin");
	if (value->cfg) 	lprintf(" cfg");
	if (value->aut) 	lprintf(" aut");
	if (value->mouse)	lprintf(" mouse");
	if (value->game)	lprintf(" game");
	if (value->mov) 	lprintf(" mov");
	lprintf("\x1a\n");
}

static void near prt_CPUPARM(CPUPARM *value)
{
	lprintf("%-10s %u %u %u %u %u %04X %04X %08lX %08lX %-12.12s\n",
		RwKeyword[K_CPUPARM].name,
		value->cpu_type,
		value->vir_flag,
		value->fpu_type,
		value->fpu_bug,
		value->wei_flag,
		value->vcpi_ver,
		value->win_ver,
		value->dwFlags,
		value->dwCPUID,
		value->aID );
}

static void near prt_BIOSID(BIOSID *value)
{
	lprintf("%-10s %X %X %X %X %X %X %X %X %X %X \x1a%s\x1a %Fp\n",
		RwKeyword[K_BIOSID].name,
		value->model,		/* Model code */
		value->submodel,	/* Submodel code */
		value->revision,	/* Revision number */
		value->flags,		/* Configuration flags */
		value->bus_flag,	/* 1 if true IBM system | 2 if EISA bus | 4 if PCI */
		value->ncrc,		/* Kb in BIOS crc: 64 or 128 */
		value->crc,		/* CRC of BIOS */
		value->sys_id,		/* System board ID for MCA's */
		value->xbseg,		/* XBIOS segment, if any */
		value->xbsize,		/* XBIOS size in KB */
		value->date,		/* Rev date from BIOS ROM */
		value->i15_ptr);	/* Pointer to int 15 param block */
}

static void near prt_VIDEO(VIDEO *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[K_VIDEO].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		VIDEO *vp = value + kk;

		lprintf(" %d %d \x1a%s\x1a \x1a%s\x1a %04X %04X %04X %04X %04X %04X %04X %d %d\n",
			vp->acode,	/* Adapter code from VideoID() */
			vp->dcode,	/* Display code from VideoID() */
			vp->name,		/* Name of adapter (CGA, EGA, etc.) */
			vp->mode,		/* Mode of adapter (Color or Mono) */
			vp->text,		/* Address of text memory */
			vp->tsize,	/* Size of text memory in paragraphs */
			vp->graph,	/* Address of graphics memory */
			vp->gsize,	/* Size of graphics memory in paragraphs */
			vp->rom,		/* Address of adapter ROM */
			vp->rsize,	/* Size of adapter ROM in paragraphs */
			vp->osize,	/* Effective size of adapter memory in kb */
			vp->cols,		/* Display columns */
			vp->rows);	/* Display rows */
	}
}

static void near prt_MOUSE(MOUSEINFO *value)
{
	lprintf("%-10s %d.%02d %u %u\n",
		RwKeyword[K_MOUSE].name,
		HIBYTE(value->version),
		LOBYTE(value->version),
		value->type,
		value->irq);
}

static void near prt_EMSPARM(EMSPARM *value)
{
	lprintf("%-10s %X %X %u %u %u %u %u %u %u %u %u %u\n",
		RwKeyword[K_EMSPARM].name,
		value->version, /* Version number */
		value->frame,		/* Page frame segment */
		value->avail,		/* Available pages */
		value->total,		/* Total pages */
		value->mpages,		/* !! Mappable physical pages */
		value->tothand, /* !! Total handles supported */
		value->acthand, /* Number of active handles */
		value->rawsize, /* !! Size of raw pages in paragraphs */
		value->amrs,		/* !! Number of alternate map register sets */
		value->mcsize,		/* !! Size of mapping-context save area in bytes */
		value->dmars,		/* !! Number of register sets that can be assigned to DMA */
		value->dmatype);	/* !! DMA operation type */
}

static void near prt_EMSHAND(EMSHAND *value,WORD nvalue)
{
	WORD kk;	/* Loop counter */

	lprintf("%-10s %d\n",RwKeyword[K_EMSHAND].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		EMSHAND *vp = value + kk;

		lprintf(" %4X \x1a%-8.8s\x1a",
			vp->handle,	/* !! Handle number */
			vp->name);	/* !! Name of handle */
		if ((kk % 4) == 3) lprintf("\n");
	}
	if ((kk % 4) != 0) lprintf("\n");
}

static void near prt_EMSMAP(EMSMAP *value,WORD nvalue)
{
	WORD kk;	/* Loop counter */

	lprintf("%-10s %d\n",RwKeyword[K_EMSMAP].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		EMSMAP *vp = value + kk;

		lprintf(" %4X %2X",
			vp->base,	/* !! Base segment address */
			vp->number);	/* !! Physical page number */
		if ((kk % 8) == 7) lprintf("\n");
	}
	if ((kk % 8) != 0) lprintf("\n");
}

static void near prt_XMSPARM(XMSPARM *value)
{
	lprintf("%-10s %u %X %X %u %u %u %u %u %u %u %u\n",
		RwKeyword[K_XMSPARM].name,
		value->flag,		/* 0 if XMS installed, 0x80 if not, 0x81 if VDISK running */
		value->version, 	/* XMS version number */
		value->driver,		/* Driver version number */
		value->hmaexist,	/* HMA exists flag */
		value->hmaavail,	/* HMA available flag */
		value->a20state,	/* State of A20 line */
		value->embhand, 	/* EMB handles */
		value->embtotal,	/* Total Kb EMB free */
		value->embavail,	/* Available Kb in largest EMB block */
		value->umbtotal,	/* Total Kb UMB free */
		value->umbavail);	/* Available Kb in largest UMB block */
}

static void near prt_TIMELIST(SYSBUFH value,WORD nvalue)
{
	TIMELIST *vp;
	TIMELIST *vpend;

	if (nvalue < 1) return;

	lprintf("%-10s %u\n",RwKeyword[K_TIMELIST].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" %4X %4X %4X\n",
		vp->start,	/* Block segment address */
		vp->length,	/* Block length in paras */
		vp->count);	/* Access count */
		vp++;
	}
}

static void near prt_ROMLIST(SYSBUFH value,WORD nvalue)
{
	ROMITEM *vp;
	ROMITEM *vpend;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_ROMLIST].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" %4X %4X\n",
			vp->seg,	/* Segment address */
			vp->size);	/* Size in paras */
		vp++;
	}
}

static void near prt_FLEXROM(SYSBUFH value,WORD nvalue)
{
	FLEXROM *vp;
	FLEXROM *vpend;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_FLEXROMS].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" %4X %4X %4X %4X\n",
			vp->src,	/* Source segment */
			vp->dst,	/* Destination segment */
			vp->len,	/* Length in bytes */
			vp->flag);	/* Flag word */
		vp++;
	}
}

static void near prt_HOLES(RWKEY kw,SYSBUFH value,WORD nvalue)
{
	MEMHOLE *vp;
	MEMHOLE *vpend;

	if (nvalue < 1) return;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" %8lX %8lX %u \x1a%s\x1a\n",
			vp->faddr,	/* Flat address */
			vp->length,	/* Length in bytes */
			vp->class,	/* Classification for summary */
			vp->name);	/* Item name */
		vp++;
	}
}

static void near prt_CONFIG(CONFIG *value)
{
	char *p;

	if (value->maxpro) p = sysbuf_ptr(value->maxpro);
	else		   p = "";
	lprintf("%-10s %d %d  %d %d  %d %d  %c  %d %d %d \x1a%s\x1a\n",
		RwKeyword[K_CONFIG].name,
		value->files,		/* Current FILES setting */
		value->buffers, 	/* Current BUFFERS setting */
		value->fcbx,		/* Current FCBS x setting */
		value->fcby,		/* Current FCBS y setting */
		value->stackx,		/* Current STACKS x setting */
		value->stacky,		/* Current STACKS y setting */
		value->lastdrive,	/* Letter of last drive 'A'-'Z' */
		value->brk,		/* BREAK flag */
		value->print,		/* PRINT TSR is loaded */
		value->fastopen,	/* FASTOPEN TSR is loaded */
		p);	/* 386MAX profile name */
}

static void near prt_ENVSTR(SYSBUFH value,WORD nvalue)
{
	WORD kk;
	char *p;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_ENVSTR].name,nvalue);
	p = sysbuf_ptr(value);
	for (kk = 0; kk < nvalue; kk++) {
		lprintf("%s\n",p);
		p += strlen(p) + 1;
	}
}

static void near prt_OPENFILE(SYSBUFH value,WORD nvalue)
{
	OPENFILE *vp;
	OPENFILE *vpend;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_OPENFILE].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" \x1a%s\x1a\n",vp->name);
		vp++;
	}
}

static void near prt_DCACHE(void)
{
	/* Note that we surround values with quotes so that older */
	/* versions of ASQ will still read newer snapshot files */
	lprintf("%-10s \x1a%d %u\x1a\n", RwKeyword[K_DCACHE].name,
		SysInfo->dcache, dcache_dly);
}

static void near prt_DRIVEPARM(RWKEY kw,DRIVEPARM *value)
{
	WORD kk;
	WORD nn;

	nn = 0;
	if (value[0].heads) nn++;
	if (value[1].heads) nn++;
	if (nn < 1) return;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nn);
	for (kk = 0; kk < nn; kk++) {
		DRIVEPARM *vp = value + kk;

		lprintf(" \x1a%s\x1a %u %u %u %u\n",
			vp->text,		/* General type (360kb, 20 mb, etc.) */
			vp->heads,		/* How many heads */
			vp->cyls,		/* How many cylinders */
			vp->sectors,		/* How many sectors */
			vp->type);		/* Type number */
	}
}

static void near prt_PARTTABLE(RWKEY kw,PARTTABLE *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		PARTTABLE *vp = value+kk;

		lprintf(" %02X %02X %02X %02X %02X %02X %02X %02X %08lX %08lX\n",
			vp->bootind,	/* boot indicator 0/0x80	*/
			vp->start_head, /* head value for first sector	*/
			vp->start_sec,	/* sector value for first sector*/
			vp->start_cyl,	/* track value for first sector */
			vp->sysind,	/* system indicator 00=?? 01=DOS*/
			vp->last_head,	/* head value for last sector	*/
			vp->last_sec,	/* sector value for last sector */
			vp->last_cyl,	/* track value for last sector	*/
			vp->lowsec,	/* logical first sector 	*/
			vp->size);	/* size of partition in sectors */
	}
}

static void near prt_MACINFO(RWKEY kw,SYSBUFH value,WORD nvalue)
{
	WORD kk;
	MACINFO *vp;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[kw].name,nvalue);
	vp = sysbuf_ptr(value);
	for (kk = 0; kk < nvalue; kk++,vp++) {
		lprintf(" %c %04X %04X %04X \x1a%s\x1a \x1a%s\x1a\n",
			vp->type,	/* Entry type */
			vp->start,	/* Starting segment */
			vp->size,	/* Length in paras */
			vp->owner,	/* Owner of segment */
			vp->name,	/* Name of entry */
			vp->text);	/* Text string, if any */
	}
}

static void near prt_DDLIST(SYSBUFH value,WORD nvalue)
{
	DDLIST *vp;
	DDLIST *vpend;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_DDLIST].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		char temp[16];

		if (vp->attr & 0x8000) {
			sprintf(temp,"\x1a%-8.8s\x1a",vp->name);
		}
		else {
			sprintf(temp,"%d",*(BYTE *)vp->name);
		}
		lprintf(" %Fp %Fp %04X %04X %04X %s\n",
			vp->this,	/* Address of this DD entry */
			vp->next,	/* Address of next DD header */
			vp->attr,	/* Device attributes */
			vp->strat,	/* Pointer to strategy routine */
			vp->intr,	/* Pointer to interrupt routine */
			temp);		/* Device name */

		vp++;
	}
}

static void near prt_DOSDATA(SYSBUFH value,WORD nvalue)
{
	DOSDATA *vp;
	DOSDATA *vpend;

	if (nvalue < 1) return;
	lprintf("%-10s %u\n",RwKeyword[K_DOSDATA].name,nvalue);
	vp = sysbuf_ptr(value);
	vpend = vp + nvalue;
	while (vp < vpend) {
		lprintf(" %c %Fp %lX %lX %d \x1a%s\x1a\n",
			vp->type,	/* Entry type */
			vp->saddr,	/* 'Segmented' address of entry */
			vp->faddr,	/* 'Flat' address for doing arithmetic */
			vp->length,	/* Length in bytes */
			vp->count,	/* File count for file entries */
			vp->name);	/* Name of entry */
		vp++;
	}
}

static void near prt_MCAID(MCAID *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[K_MCAID].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		MCAID *vp = value + kk;

		lprintf(" %04X %02X %02X %02X %02X %04X\n",
			vp->aid,		/* Adapter ID */
			vp->pos[0],	/* POS bytes */
			vp->pos[1],	/* POS bytes */
			vp->pos[2],	/* POS bytes */
			vp->pos[3],	/* POS bytes */
			vp->suba);	/* Subaddress extension */
	}
}

static void near prt_ADFINFO(SYSBUFH *value,WORD nvalue)
{
	WORD kk;

	lprintf("%-10s %u\n",RwKeyword[K_ADFINFO].name,nvalue);
	for (kk = 0; kk < nvalue; kk++) {
		ADFINFO *vp;

		if (value[kk]) {
			vp = sysbuf_ptr(value[kk]);
			lprintf(" %04X \x1a%s\x1a %u\n",
				vp->aid,	/* Adapter id */
				vp->name,	/* Adapter name */
				vp->noption);	/* How many programmable options */
			if (vp->noption > 0) {
				prt_ADFOPTION(vp);
			}
		}
		else	lprintf(" 0000 \x1a\x1a 0\n");
	}
}

static void near prt_ADFOPTION(ADFINFO *value)
{
	WORD kk;
	ADFOPTION *vp;

	vp = sysbuf_ptr(value->foption);
	for (kk = 0; kk < value->noption; kk++,vp = sysbuf_ptr(vp->next)) {
		lprintf("  \x1a%s\x1a %u\n",vp->name,vp->nchoice);
		if (vp->nchoice > 0) {
			prt_ADFCHOICE(vp);
		}
	}
}

static void near prt_ADFCHOICE(ADFOPTION *value)
{
	WORD jj;
	ADFCHOICE *vp;

	vp = sysbuf_ptr(value->fchoice);
	for (jj = 0; jj < value->nchoice; jj++,vp = sysbuf_ptr(vp->next)) {
		WORD kk;

		lprintf("   \x1a%s\x1a",vp->name);
		for (kk = 0; kk < 4; kk++) {
			lprintf(" \x1a%s\x1a",vp->pos[kk]);
		}
		lprintf("\n");
	}
}

