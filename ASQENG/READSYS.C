/*' $Header:   P:/PVCS/MAX/ASQENG/READSYS.C_V   1.2   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * READSYS.C								      *
 *									      *
 * Functions to read an ASQ snapshot					      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <malloc.h>

#include <commfunc.h>		/* Utility functions */
#include <dcache.h>		/* Disk cache functions and globals */
#include "mapinfo.h"            /* Map info functions */
#include <myalloc.h>		/* Our malloc covers */
#include "sysinfo.h"            /* System info structures */

/* Owned by writsys.c */
#include "systext.h"            /* System info keyword text */

/* #define DEBUGMSG		/* Dump debugging messages */

#ifdef DEBUGMSG
#include <intmsg.h>
#endif	/* ifdef DEBUGMSG */

/* Local Variables */
static FILE *RwFile;		/* Stream pointer for input/output file */
static char *TokenBuf;		/* Scratch space for tokens */
#define MAXTOKEN 1024		/* Largest acceptable token */
static BOOL ReachedEOL; 	/* Last call to scn_token() reached EOL */

/* Array for translating old map id codes to new ones */
		      /*0123456789*/
static char *IdTrans = "?@8CPDARTU";

/* 1.30-style Qtas Map info */
typedef struct _qmap {		/* One memory map item */
	char name[20];		/* Name of entry */
	WORD id;		/* Id of entry */
	WORD start;		/* Starting segment */
	WORD end;		/* Ending segment */
	WORD owner;		/* Owner of segment */
	long length;		/* Length in bytes */
	int ntext;		/* How many chars in text buffer */
	char text[50];		/* Text string, if any */
} QMAP;

/* Local Functions */
static int near scn_token(char *value,int nvalue);
static int near scn_double(double *value);
static int near scn_ichar(int *value);
static int near scn_string(char *value,int nvalue);
static int near scn_HEXWORD(WORD *value);
static int near scn_DECWORD(WORD *value);
static int near scn_DECINT(int *value);
static int near scn_DECDWORD(DWORD *value);
static int near scn_HEXDWORD(DWORD *value);
static int near scn_FARPTR(void far * *value);
static int near scn_HEXWORDS(WORD *value,WORD nvalue);
static int near scn_HEXBYTES(BYTE *value,WORD nvalue);
static int near scn_FARPTRS(void far * *value,WORD nvalue);
static int near scn_SYSBUFH(SYSBUFH *value);
static int near scn_FILE(char **ppszValue,WORD *nvalue,SYSBUFH *pName);

static int near scn_VERSION(WORD *value);
static int near scn_SNAPDATE(WORD *value);
static int near scn_SNAPTIME(WORD *value);
static int near scn_FLAGS(struct _sysflags *value);
static int near scn_CPUPARM(CPUPARM *value);
static int near scn_BIOSID(BIOSID *value);
static int near scn_VIDEO(VIDEO *value,WORD *nvalue);
static int near scn_MOUSE(MOUSEINFO *value);
static int near scn_EMSPARM(EMSPARM *value);
static int near scn_XMSPARM(XMSPARM *value);
static int near scn_CONFIG(CONFIG *value);
static int near scn_DCACHE(void);
static int near scn_DRIVEPARM(DRIVEPARM *value);
static int near scn_PARTTABLE(PARTTABLE *value,WORD nvalue);
static int near scn_MCAID(MCAID *value,WORD nvalue);
static int near scn_EMSHAND(EMSHAND *value,WORD nvalue);
static int near scn_EMSMAP(EMSMAP *value,WORD nvalue);
static int near scn_TIMELIST(SYSBUFH *value,WORD *nvalue);
static int near scn_ROMLIST(SYSBUFH *value,WORD *nvalue);
static int near scn_FLEXROM(SYSBUFH *value,WORD *nvalue);
static int near scn_HOLES(SYSBUFH *value,WORD *nvalue);
static int near scn_OPENFILE(SYSBUFH *value,WORD *nvalue);
static int near scn_ENVSTR(SYSBUFH *value,WORD *nvalue);
static int near scn_MACINFO(SYSBUFH *value,WORD *nvalue);
static int near scn_130_QMAP(SYSBUFH *value,WORD *nvalue);
static int near scn_DDLIST(SYSBUFH *value,WORD *nvalue);
static int near scn_DOSDATA(SYSBUFH *value,WORD *nvalue);
static int near scn_ADFINFO(SYSBUFH *value,WORD nvalue);
static int near scn_ADFOPTION(ADFINFO *value);
static int near scn_ADFCHOICE(ADFOPTION *value);

static int near scn_FSTATS(SYSBUFH *value);
static int near scn_LSEG(SYSBUFH *value);
static int near scn_MAXBEST(SYSBUFH *value);
static int near scn_PNPNODES( SYSBUFH *phList, WORD *pwCount );
static int near scn_STRARRAY( SYSBUFH *phVal, WORD wNum, WORD wWidth );

static void near assert_EOL(void);
static int near ltrnbln(char *s);

#ifdef DEBUGMSG
#pragma optimize("leg",off)
static void near BREAKPT(void)
{ _asm int 1;
}
#pragma optimize("",on)
#endif

/*
 *	sysinfo_read - read system info from file
 *
 *	BEWARE:  For this to work, the glist's have to be of array type
 */

#pragma optimize ("eg",off)

int sysinfo_read(char *buf,WORD nbuf)
{
	int rtn;
	int done;

	char keyword[32];

	RwFile = fopen(buf,"r");
	if (!RwFile) return -2;

	TokenBuf = my_malloc(MAXTOKEN);
	if (!TokenBuf) {
		fclose(RwFile);
		return -2;
	}

	sysinfo_purge();
	SysInfo->flags.readin = TRUE;

#define THISMUCH 16384

	/* Set up the SysInfo buffer */
	if (nbuf >= THISMUCH) {
		SysInfoBuf = buf;
	}
	else {
		SysInfoBuf = my_malloc(THISMUCH);
		if (!SysInfoBuf) {
			my_free(TokenBuf);
			return -2;
		}
		nbuf = THISMUCH;
	}

#ifdef DEBUGMSG
	do_intmsg ("Reading file %s\n", buf);
#endif
	strcpy(TokenBuf,buf);

	*(WORD *)SysInfoBuf = nbuf;
	SysInfo->buffree = nbuf-2;
	SysInfo->bufnext = 2;

	strncpy(SysInfo->snapfile,TokenBuf,sizeof(SysInfo->snapfile)-1);
	SysInfo->snapfile[sizeof(SysInfo->snapfile)-1] = '\0';

	for (rtn = done = 0; !done && rtn == 0;) {
		WORD kk;

		if (scn_token(keyword,sizeof(keyword)) == EOF) break;
#ifdef DEBUGMSG
		do_intmsg ("Scanning for keyword %s\n", keyword);
		if (stricmp (keyword, "lowdos") == 0) BREAKPT();
#endif
		for (kk = 1; RwKeyword[kk].name; kk++) {
			if (stricmp(keyword,RwKeyword[kk].name) == 0) {
				break;
			}
		}

		if (!RwKeyword[kk].name) return -1;

#ifdef DEBUGMSG
		do_intmsg ("Found keyword %d: key=%x-%s\n", kk, RwKeyword[kk].key, RwKeyword[kk].name);
#endif
		switch (RwKeyword[kk].key) {
		case K_ASQVER:
			rtn = scn_VERSION(&SysInfo->version);
			break;
		case K_SNAPTITLE:
			rtn = scn_string(SysInfo->snaptitle,sizeof(SysInfo->snaptitle));
			break;
		case K_SNAPDATE:
			rtn = scn_SNAPDATE(SysInfo->snapdate);
			break;
		case K_SNAPTIME:
			rtn = scn_SNAPTIME(SysInfo->snaptime);
			break;
		case K_FLAGS:
			rtn = scn_FLAGS(&SysInfo->flags);
			break;
		case K_ROMSEG:
			rtn = scn_HEXWORD(&SysInfo->romseg);
			break;
		case K_ROMSIZE:
			rtn = scn_HEXWORD(&SysInfo->romsize);
			break;
		case K_BOOTDRV:
			rtn = scn_DECWORD(&SysInfo->bootdrv);
			break;
		case K_CPUPARM:
			rtn = scn_CPUPARM(&SysInfo->cpu);
			break;
		case K_MHZ:
			rtn = scn_double(&SysInfo->mhz);
			break;
		case K_CHIPSET:
			rtn = scn_HEXWORD(&SysInfo->chipset);
			break;
		case K_LOGDRV:
			rtn = scn_DECWORD(&SysInfo->logdrv);
			break;
		case K_DOSVER:
			rtn = scn_HEXWORD(&SysInfo->dosver);
			break;
		case K_IONAME:
			rtn = scn_string(SysInfo->ioname,sizeof(SysInfo->ioname));
			break;
		case K_DOSNAME:
			rtn = scn_string(SysInfo->dosname,sizeof(SysInfo->dosname));
			break;
		case K_COMNAME:
			rtn = scn_string(SysInfo->comname,sizeof(SysInfo->comname));
			break;
		case K_BASEMEM:
			rtn = scn_DECWORD(&SysInfo->basemem);
			break;
		case K_EXTMEM:
			rtn = scn_DECWORD(&SysInfo->extmem);
			break;
		case K_EXTFREE:
			rtn = scn_DECWORD(&SysInfo->extfree);
			break;
		case K_BIOSID:
			rtn = scn_BIOSID(&SysInfo->biosid);
			break;
		case K_BIOSMFR:
			rtn = scn_SYSBUFH(&SysInfo->biosmfr);
			break;
		case K_MACHNAME:
			rtn = scn_SYSBUFH(&SysInfo->machname);
			break;
		case K_ENVSIZE:
			rtn = scn_DECWORD(&SysInfo->envsize);
			break;
		case K_ENVUSED:
			rtn = scn_DECWORD(&SysInfo->envused);
			break;
		case K_VIDEO:
			rtn = scn_VIDEO(SysInfo->video,&SysInfo->nvideo);
			break;
		case K_SVVENDOR:
			rtn = scn_string(SysInfo->sv_vendor,sizeof(SysInfo->sv_vendor));
			break;
		case K_SVMODEL:
			rtn = scn_string(SysInfo->sv_model,sizeof(SysInfo->sv_model));
			break;
		case K_KEYBOARD:
			rtn = scn_HEXWORD(&SysInfo->keyboard);
			break;
		case K_MOUSE:
			rtn = scn_MOUSE(&SysInfo->mouse);
			break;
		case K_DISKROM:
			rtn = scn_HEXWORD(&SysInfo->diskrom);
			break;
		case K_DISKROMSIZE:
			rtn = scn_HEXWORD(&SysInfo->diskromsize);
			break;
		case K_ROMLIST:
			rtn = scn_ROMLIST(&SysInfo->romlist,&SysInfo->romlen);
			break;
		case K_FLEXROMS:
			rtn = scn_FLEXROM(&SysInfo->flexlist,&SysInfo->flexlen);
			break;
		case K_HOLES:
			rtn = scn_HOLES(&SysInfo->hmap,&SysInfo->hmaplen);
			break;
		case K_EXTRAMAP:
			rtn = scn_HOLES(&SysInfo->emap,&SysInfo->emaplen);
			break;
		case K_IOSTART:
			rtn = scn_HEXDWORD(&SysInfo->io_start);
			break;
		case K_DOSSTART:
			rtn = scn_HEXDWORD(&SysInfo->dos_start);
			break;
		case K_DEVSTART:
			rtn = scn_HEXDWORD(&SysInfo->dev_start);
			break;
		case K_DATASTART:
			rtn = scn_HEXDWORD(&SysInfo->data_start);
			break;
		case K_DATAEND:
			rtn = scn_HEXDWORD(&SysInfo->data_end);
			break;
		case K_PSP:
			rtn = scn_HEXWORD(&SysInfo->psp);
			break;
		case K_EMSXMS:
			rtn = scn_DECWORD(&SysInfo->ems_xms);
			break;
		case K_EMSPARM:
			rtn = scn_EMSPARM(&SysInfo->emsparm);
			break;
		case K_EMSHAND:
			rtn = -1;
			SysInfo->emshand = sysbuf_alloc(SysInfo->emsparm.acthand * sizeof(EMSHAND));
			if (!SysInfo->emshand) goto bottom;
			rtn = scn_EMSHAND(sysbuf_ptr(SysInfo->emshand),SysInfo->emsparm.acthand);
			break;
		case K_EMSHSIZE:
			rtn = -1;
			SysInfo->emssize = sysbuf_alloc(SysInfo->emsparm.acthand * sizeof(WORD));
			if (!SysInfo->emssize) goto bottom;
			rtn = scn_HEXWORDS(sysbuf_ptr(SysInfo->emssize),SysInfo->emsparm.acthand);
			break;
		case K_EMSMAP:
			rtn = -1;
			SysInfo->emsmap = sysbuf_alloc(SysInfo->emsparm.mpages * sizeof(EMSMAP));
			if (!SysInfo->emsmap) goto bottom;
			rtn = scn_EMSMAP(sysbuf_ptr(SysInfo->emsmap),SysInfo->emsparm.mpages);
			break;
		case K_XMSPARM:
			rtn = scn_XMSPARM(&SysInfo->xmsparm);
			break;
		case K_DPMIVER:
			rtn = scn_HEXWORD(&SysInfo->dpmi_ver);
			break;
		case K_DPMI32:
			rtn = scn_DECWORD(&SysInfo->dpmi_32bit);
			break;
		case K_TIMELIST:
			rtn = scn_TIMELIST(&SysInfo->timelist,&SysInfo->timelen);
			break;
		case K_CONFIG:
			rtn = scn_CONFIG(&SysInfo->config);
			break;
		case K_SHELL:
			rtn = scn_SYSBUFH(&SysInfo->config.shell);
			break;
		case K_COUNTRY:
			rtn = scn_SYSBUFH(&SysInfo->config.country);
			break;
		case K_DRIVPARM:
			rtn = scn_SYSBUFH(&SysInfo->config.drivparm);
			break;
		case K_ENVSTR:
			rtn = scn_ENVSTR(&SysInfo->envstrs,&SysInfo->envlen);
			break;
		case K_OPENFCBS:
			rtn = scn_DECWORD(&SysInfo->openfcbs);
			break;
		case K_OPENFILE:
			rtn = scn_OPENFILE(&SysInfo->openfiles,&SysInfo->openlen);
			break;
		case K_DCACHE:
			rtn = scn_DCACHE();
			break;
		case K_FDRIVE:
			rtn = scn_DRIVEPARM(SysInfo->fdrive);
			break;
		case K_HDRIVE:
			rtn = scn_DRIVEPARM(SysInfo->hdrive);
			break;
		case K_HPART0:
			rtn = scn_PARTTABLE(SysInfo->hpart0,4);
			break;
		case K_HPART1:
			rtn = scn_PARTTABLE(SysInfo->hpart1,4);
			break;
		case K_CONFIGSYS:
			rtn = scn_FILE(&SysInfo->pszCnfgsys,&SysInfo->cnfglen,
				NULL);
			break;
		case K_AUTOBAT:
			rtn = scn_FILE(&SysInfo->pszAutobat,&SysInfo->autolen,
				&SysInfo->config.startupbat);
			break;
		case K_MAXPRO:
			rtn = scn_FILE(&SysInfo->pszMaxprof,&SysInfo->proflen,
				&SysInfo->config.maxpro);
			break;
		case K_EXTRADOSPRO:
			rtn = scn_FILE(&SysInfo->pszExtrados,
				&SysInfo->extradoslen,
				&SysInfo->config.extradospro);
			break;
		case K_SYSINI:
			rtn = scn_FILE(&SysInfo->pszSysini,&SysInfo->sysinilen,
				&SysInfo->WindowsData.sysininame);
			break;
		case K_QFILES:
			rtn = scn_FSTATS(&SysInfo->pQFiles);
			break;
		case K_LSEG:
			rtn = scn_LSEG(&SysInfo->pLseg);
			break;
		case K_MAXBESTSIZE:
			rtn = scn_HEXWORD(&SysInfo->MaximizeBestsize);
			break;
		case K_MAXBEST:
			rtn = scn_MAXBEST(&SysInfo->pMaxBest);
			break;
		case K_WINDOWSVER:
			rtn = scn_HEXWORD(&SysInfo->WindowsData.windowsver);
			break;
		case K_WINDOWSDIR:
			rtn = scn_SYSBUFH(&SysInfo->WindowsData.windowsdir);
			break;
		case K_WFILES:
			rtn = scn_FSTATS(&SysInfo->WindowsData.pWFiles);
			break;
		case K_BIOSDATA:
			rtn = scn_HEXBYTES((BYTE *)&SysInfo->biosdata,sizeof(BIOSDATA));
			break;
		case K_CMOS:
			rtn = scn_HEXBYTES(SysInfo->cmos,CMOS_SIZE);
			break;
		case K_VECTORS:
			rtn = scn_FARPTRS(SysInfo->vectors,256);
			break;
		case K_LOWMEM:	/* 1.30 */
			rtn = scn_130_QMAP(&SysInfo->lowdos,&SysInfo->nlowdos);
			break;
		case K_HIGHMEM: /* 1.30 */
			rtn = scn_130_QMAP(&SysInfo->highdos,&SysInfo->nhighdos);
			break;
		case K_LOWDOS:
			rtn = scn_MACINFO(&SysInfo->lowdos,&SysInfo->nlowdos);
			break;
		case K_HIGHDOS:
			rtn = scn_MACINFO(&SysInfo->highdos,&SysInfo->nhighdos);
			break;
		case K_HIGHLOAD:
			rtn = scn_MACINFO(&SysInfo->highload,&SysInfo->nhighload);
			break;
		case K_DDLIST:
			rtn = scn_DDLIST(&SysInfo->ddlist,&SysInfo->ddlen);
			break;
		case K_DOSDATA:
			rtn = scn_DOSDATA(&SysInfo->dosdata,&SysInfo->doslen);
			break;
		case K_MCAID:
			rtn = scn_MCAID(SysInfo->mcaid,MCASLOTS);
			break;
		case K_ADFINFO:
			rtn = scn_ADFINFO(SysInfo->adf,MCASLOTS);
			break;
		case K_PCIVER:
			rtn = scn_HEXWORD( &SysInfo->pci_ver );
			break;
		case K_PNPDATA:
			/*rtn =*/ scn_HEXWORD( &SysInfo->wPnP_ver );
			/*rtn =*/ scn_HEXWORD( &SysInfo->wNumNodes );
			rtn = scn_HEXWORD( &SysInfo->wMaxNodeSize );
			break;
		case K_PNPNODES:
			rtn = scn_PNPNODES( &SysInfo->pNodeList, &SysInfo->cbNodeList );
			break;
		case K_CDROM:
			/*rtn =*/ scn_HEXWORD( &SysInfo->nCDs );
			rtn = scn_HEXWORD( &SysInfo->nFirstCD );
			break;
		case K_PNPDESC:
			rtn = scn_STRARRAY( &SysInfo->ppszPnPDesc, SysInfo->wNumNodes, MAXPNP_DESC );
			break;
		case K_END:
			done++;
			break;
		default:
			rtn = -1;
		} /* switch */

	}
#ifdef DEBUGMSG
	do_intmsg ("End of file.\n");
#endif
bottom:
	my_free(TokenBuf);
	fclose(RwFile);

	/* Memory map */
	make_umap(TRUE);

	{
		WORD used;

		used = nbuf - sysbuf_avail(0);
#ifdef CVDBG
		fprintf(stderr,"used = %u\n",used);
#endif
		if (SysInfoBuf == buf) {
			SysInfoBuf = my_malloc(used);
			if (!SysInfoBuf) {
				return -2;
			}
			memcpy(SysInfoBuf,buf,used);
		}
		else {
			/* We're shrinking the buffer, so this should always work */
			SysInfoBuf = my_realloc(SysInfoBuf,used);
		}
	}
	return rtn;
}

int sysinfo_look(char *name,char *title,int ntitle,WORD *date,WORD *time)
{
	int rtn;
	int done;
	char keyword[32];

	RwFile = fopen(name,"r");
	if (!RwFile) return -2;

	TokenBuf = my_malloc(MAXTOKEN);
	if (!TokenBuf) {
		fclose(RwFile);
		return -2;
	}

	memset(date,0,3*sizeof(WORD));
	memset(time,0,3*sizeof(WORD));
	for (done = 0; done < 3;) {
		if (scn_token(keyword,sizeof(keyword)) == EOF) break;
		if (stricmp(keyword,RwKeyword[K_SNAPTITLE].name) == 0) {
			scn_token(title,ntitle);
			done++;
		}
		else if (stricmp(keyword,RwKeyword[K_SNAPDATE].name) == 0) {
			rtn = scn_SNAPDATE(date);
			done++;
		}
		else if (stricmp(keyword,RwKeyword[K_SNAPTIME].name) == 0) {
			rtn = scn_SNAPTIME(time);
			done++;
		}
		else {
			/* Eat stuff we don't care about */
			assert_EOL();
		}
	}

	if (done >= 3) rtn = 0;
	else	       rtn = -1;

	my_free(TokenBuf);
	fclose(RwFile);

	return rtn;
}

/*
========================================================================
*/

static int near scn_token(char *value,int nvalue)
{
	int c;
	int nn = 0;
	BOOL quote = FALSE;
	BOOL escape = FALSE;
	BOOL arg = FALSE;

	if (nvalue < 1) return 0;
	nvalue--;

	ReachedEOL = FALSE;
	while (nn < nvalue) {
		c = fgetc(RwFile);
		if (c == ';' && !quote) {
			/* Eat comments */
			do {
				c = fgetc(RwFile);
			} while (c != EOF && c != '\n');
		}
		if (c == '\n') ReachedEOL = TRUE;
		if (c == EOF) {
			if (nn == 0) return EOF;
			else break;
		}
		if (c == '\\' && !escape) escape = TRUE;
		else {
			/* Check for older snapshot files */
			if (escape && c != '\\' && c != '"') value[nn++] = '\\';
			if (arg) {
				if (quote) {
					if (c == '"' && !escape) break;
					else	value[nn++] = (char)c;
				}
				else {
					if (isspace(c)) break;
					else value[nn++] = (char)c;
				}
			}
			else {
				if (!isspace(c)) {
					if (c == '"') {
						quote = TRUE;
					}
					else {
						value[nn++] = (char)c;
					}
					arg = TRUE;
				}
			}
			escape = FALSE;
		} /* Not escape */
	} /* End WHILE */
	value[nn++] = '\0';
	return nn;
}

static int near scn_double(double *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%lf",value);
	return 0;
}

static int near scn_ichar(int *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	*value = *TokenBuf;
	return 0;
}

static int near scn_string(char *value,int nvalue)
{
	if (nvalue < 1) return -1;
	memset(TokenBuf,0,nvalue);
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	memcpy(value,TokenBuf,nvalue-1);
	return 0;
}

static int near scn_HEXBYTE(BYTE *value)
{
	WORD w;

	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%x",&w);
	*value = (BYTE)w;
	return 0;
}

static int near scn_HEXWORD(WORD *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%x",value);
	return 0;
}

static int near scn_DECWORD(WORD *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%u",value);
	return 0;
}

static int near scn_DECINT(int *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%d",value);
	return 0;
}

static int near scn_DECDWORD(DWORD *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%lu",value);
	return 0;
}

static int near scn_HEXDWORD(DWORD *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%lx",value);
	return 0;
}

static int near scn_FARPTR(void far * *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
#if 0	/* Problem in Windows */
	sscanf(TokenBuf,"%Fp",value);
#else
	TokenBuf[4] = ' ';
	sscanf(TokenBuf,"%x %x",((char *)value+2),value);
#endif
	return 0;
}

static int near scn_HEXWORDS(WORD *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;
	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
		sscanf(TokenBuf,"%x",&value[kk]);
	}
	return 0;
}

static int near scn_HEXBYTES(BYTE *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;
	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		WORD w;
		if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
		sscanf(TokenBuf,"%x",&w);
		value[kk] = (BYTE)w;
	}
	return 0;
}

static int near scn_FARPTRS(void far * *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;
	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
#if 0	/* Problem in Windows */
		sscanf(TokenBuf,"%Fp",&value[kk]);
#else
		TokenBuf[4] = ' ';
		sscanf(TokenBuf,"%x %x",(((char *)(&value[kk]))+2),&value[kk]);
#endif
	}
	return 0;
}

static int near scn_SYSBUFH(SYSBUFH *value)
{
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sysbuf_store(value,TokenBuf,0);
	return 0;
}

/* To avoid heap fragmentation, we'll write the cooked input to */
/* a temporary binary file, then calculate the file size, allocate */
/* the exact amount required and suck it all back in. */
static int near scn_FILE(char **ppszValue,WORD *nvalue,SYSBUFH *pName)
{
	WORD kk;
	FILE *temp;
	long fsize;
	int res = -1, nc;
	char pathname[128];

	if (scn_DECWORD(nvalue)) return -1;
	if (!ReachedEOL) {
	  if (!scn_string(pathname, sizeof(pathname)) && pName) {
		sysbuf_store (pName, pathname, 0);
	  } /* Got filename and we need to save it */
	} /* There's more... read the pathname of the file */

	/* tmpfile() returns a temporary file pointer in binary mode */
	if (!(temp = tmpfile ())) return (-1);

	for (kk = 0; kk < *nvalue; kk++) {
		if (!fgets(TokenBuf,MAXTOKEN,RwFile)) goto scn_file_exit;
		nc = ltrnbln(TokenBuf) + 1; /* Write trailing null as well */
		if (fwrite (TokenBuf, 1, nc, temp) != (size_t) nc)
			goto scn_file_exit;
	}
	if ((fsize = ftell (temp)) == -1L || fsize > (long) _HEAP_MAXREQ ||
		fseek (temp, 0L, SEEK_SET) == -1) goto scn_file_exit;
	if ((*ppszValue = my_malloc ((size_t) fsize)) == NULL)
			goto scn_file_exit;
	fread (*ppszValue, 1, (size_t) fsize, temp);
	if (!ferror (temp)) res = 0; /* Success */
scn_file_exit:
	fclose (temp); /* This also deletes the temporary file */
	return (res);
}

/* Read a fixed length array of strings.  It will be allocated for */
/* wNum elements but will not be read in excess of wNum.  */
static int near scn_STRARRAY( SYSBUFH *phVal, WORD wNum, WORD wWidth )
{
	WORD wNumDesc, w;
	char *psz, *pszLF;

	/* If this count is greater than wNum we'll just ignore the excess */
	if (scn_DECWORD( &wNumDesc )) return -1;

	*phVal = sysbuf_alloc( wWidth * wNum );
	psz = sysbuf_ptr( *phVal );

	for (w = 0; w < wNumDesc; w++) {

		if (!fgets( TokenBuf, MAXTOKEN, RwFile )) {
			return -1;
		}
		TokenBuf[ MAXTOKEN - 1 ] = '\0';
		if (pszLF = strchr( TokenBuf, '\n' )) {
			*pszLF = '\0';
		}
		if (w < wNum) {
			strncpy( psz + w * wWidth, TokenBuf, wWidth - 1 );
		}
	}

	return 0;
}

static int near scn_VERSION(WORD *value)
{
	int v1 = 0;
	int v2 = 0;
	char *p;

	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	p = strchr(TokenBuf,'.');
	if (!p) p = TokenBuf;
	else   *p++ = ' ';
	sscanf(TokenBuf,"%d %d",&v1,&v2);
	*value = (v1 << 8) | (v2 & 0xff);
	return 0;
}

static int near scn_SNAPDATE(WORD *value)
{
	if (scn_DECWORD(value+0) != 0) return -1;
	if (scn_DECWORD(value+1) != 0) return -1;
	if (scn_DECWORD(value+2) != 0) return -1;
	return 0;
}

static int near scn_SNAPTIME(WORD *value)
{
	if (scn_DECWORD(value+0) != 0) return -1;
	if (scn_DECWORD(value+1) != 0) return -1;
	if (scn_DECWORD(value+2) != 0) return -1;
	return 0;
}

static int near scn_FLAGS(struct _sysflags *value)
{
	char *p;

	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	p = strtok(TokenBuf," ");
	while (p) {
		if (stricmp(p,"pc") == 0)               value->pc = TRUE;
		else if (stricmp(p,"xt") == 0)          value->xt = TRUE;
		else if (stricmp(p,"at") == 0)          value->at = TRUE;
		else if (stricmp(p,"ps2") == 0)         value->ps2 = TRUE;
		else if (stricmp(p,"mc") == 0)          value->mca = TRUE;
		else if (stricmp(p,"eisa") == 0)        value->eisa = TRUE;
		else if (stricmp(p,"pci") == 0)         value->pci = TRUE;
		else if (stricmp(p,"pnp") == 0)                 value->pnp = TRUE;
		else if (stricmp(p,"cmos") == 0)        value->cmos = TRUE;
		else if (stricmp(p,"max") == 0)         value->max = TRUE;
		else if (stricmp(p,"ems") == 0)         value->ems = TRUE;
		else if (stricmp(p,"lim4") == 0)        value->lim4 = TRUE;
		else if (stricmp(p,"xms") == 0)         value->xms = TRUE;
		else if (stricmp(p,"rdin") == 0)        value->readin = TRUE;
		else if (stricmp(p,"cfg") == 0)         value->cfg = TRUE;
		else if (stricmp(p,"aut") == 0)         value->aut = TRUE;
		else if (stricmp(p,"mouse") == 0)       value->mouse = TRUE;
		else if (stricmp(p,"game") == 0)        value->game = TRUE;
		else if (stricmp(p,"mov") == 0)         value->mov = TRUE;

		p = strtok(NULL," ");
	}
	return 0;
}

static int near scn_CPUPARM(CPUPARM *value)
{
	char szTemp[ 16 ];

	if (scn_DECWORD(&value->cpu_type) != 0) return -1;
	if (scn_DECWORD(&value->vir_flag) != 0) return -1;
	if (scn_DECWORD(&value->fpu_type) != 0) return -1;
	if (scn_DECWORD(&value->fpu_bug) != 0) return -1;
	if (scn_DECWORD(&value->wei_flag) != 0) return -1;
	if (scn_HEXWORD(&value->vcpi_ver) != 0) return -1;
	if (scn_HEXWORD(&value->win_ver) != 0) return -1;
	(void)scn_HEXDWORD( &value->dwFlags );
	(void)scn_HEXDWORD( &value->dwCPUID );
	(void)scn_string( szTemp, sizeof( szTemp ) );
	memcpy( value->aID, szTemp, sizeof( value->aID ) );
	return 0;
}

static int near scn_BIOSID(BIOSID *value)
{
	if (scn_HEXBYTE(&value->model) != 0) return -1;
	if (scn_HEXBYTE(&value->submodel) != 0) return -1;
	if (scn_HEXBYTE(&value->revision) != 0) return -1;
	if (scn_HEXBYTE(&value->flags) != 0) return -1;
	if (scn_HEXBYTE(&value->bus_flag) != 0) return -1;
	if (scn_HEXBYTE(&value->ncrc) != 0) return -1;
	if (scn_HEXWORD(&value->crc) != 0) return -1;
	if (scn_HEXWORD(&value->sys_id) != 0) return -1;
	if (scn_HEXWORD(&value->xbseg) != 0) return -1;
	if (scn_HEXWORD(&value->xbsize) != 0) return -1;
	if (scn_string(value->date,sizeof(value->date)) != 0) return -1;
	if (scn_FARPTR(&value->i15_ptr) != 0) return -1;
	return 0;
}

static int near scn_VIDEO(VIDEO *value,WORD *nvalue)
{
	int rtn;
	WORD kk;

	if (scn_DECWORD(nvalue)) return rtn;

	for (kk = 0; kk < *nvalue; kk++) {
		VIDEO *vp = value + kk;

		if (scn_DECWORD(&vp->acode) != 0) return -1;
		if (scn_DECWORD(&vp->dcode) != 0) return -1;
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
		if (scn_string(vp->mode,sizeof(vp->mode)) != 0) return -1;
		if (scn_HEXWORD(&vp->text) != 0) return -1;
		if (scn_HEXWORD(&vp->tsize) != 0) return -1;
		if (scn_HEXWORD(&vp->graph) != 0) return -1;
		if (scn_HEXWORD(&vp->gsize) != 0) return -1;
		if (scn_HEXWORD(&vp->rom) != 0) return -1;
		if (scn_HEXWORD(&vp->rsize) != 0) return -1;
		if (scn_HEXWORD(&vp->osize) != 0) return -1;
		if (scn_DECWORD(&vp->cols) != 0) return -1;
		if (scn_DECWORD(&vp->rows) != 0) return -1;
	}
	return 0;
}

static int near scn_MOUSE(MOUSEINFO *value)
{
	if (scn_VERSION(&value->version) != 0) return -1;
	if (scn_DECWORD(&value->type) != 0) return -1;
	if (scn_DECWORD(&value->irq) != 0) return -1;
	return 0;
}

static int near scn_EMSPARM(EMSPARM *value)
{
	if (scn_HEXWORD(&value->version) != 0) return -1;
	if (scn_HEXWORD(&value->frame) != 0) return -1;
	if (scn_DECWORD(&value->avail) != 0) return -1;
	if (scn_DECWORD(&value->total) != 0) return -1;
	if (scn_DECWORD(&value->mpages) != 0) return -1;
	if (scn_DECWORD(&value->tothand) != 0) return -1;
	if (scn_DECWORD(&value->acthand) != 0) return -1;
	if (scn_DECWORD(&value->rawsize) != 0) return -1;
	if (scn_DECWORD(&value->amrs) != 0) return -1;
	if (scn_DECWORD(&value->mcsize) != 0) return -1;
	if (scn_DECWORD(&value->dmars) != 0) return -1;
	if (scn_DECWORD(&value->dmatype) != 0) return -1;
	return 0;
}

static int near scn_XMSPARM(XMSPARM *value)
{
	if (scn_DECWORD(&value->flag) != 0) return -1;
	if (scn_HEXWORD(&value->version) != 0) return -1;
	if (scn_HEXWORD(&value->driver) != 0) return -1;
	if (scn_DECWORD(&value->hmaexist) != 0) return -1;
	if (scn_DECWORD(&value->hmaavail) != 0) return -1;
	if (scn_DECWORD(&value->a20state) != 0) return -1;
	if (scn_DECWORD(&value->embhand) != 0) return -1;
	if (scn_DECWORD(&value->embtotal) != 0) return -1;
	if (scn_DECWORD(&value->embavail) != 0) return -1;
	if (scn_DECWORD(&value->umbtotal) != 0) return -1;
	if (scn_DECWORD(&value->umbavail) != 0) return -1;
	return 0;
}

static int near scn_CONFIG(CONFIG *value)
{
	if (scn_DECWORD(&value->files) != 0) return -1;
	if (scn_DECWORD(&value->buffers) != 0) return -1;
	if (scn_DECWORD(&value->fcbx) != 0) return -1;
	if (scn_DECWORD(&value->fcby) != 0) return -1;
	if (scn_DECWORD(&value->stackx) != 0) return -1;
	if (scn_DECWORD(&value->stacky) != 0) return -1;
	if (scn_ichar(&value->lastdrive) != 0) return -1;
	if (scn_DECWORD(&value->brk) != 0) return -1;
	if (scn_DECWORD(&value->print) != 0) return -1;
	if (scn_DECWORD(&value->fastopen) != 0) return -1;
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	if (strlen(TokenBuf) > 0) {
		sysbuf_store(&value->maxpro,TokenBuf,0);
	}
	return 0;
}

static int near scn_DCACHE(void)
{
	/* The two values are written as one token (surrounded by quotes) */
	/* so that earlier versions of ASQ won't choke */
	if (scn_token(TokenBuf,MAXTOKEN) == EOF) return -1;
	sscanf(TokenBuf,"%d %u",&SysInfo->dcache,&dcache_dly);
	return 0;
}

static int near scn_DRIVEPARM(DRIVEPARM *value)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;

	for (kk = 0; kk < count; kk++) {
		DRIVEPARM *vp = value + kk;

		if (scn_string(vp->text,sizeof(vp->text)) != 0) return -1;
		if (scn_DECWORD(&vp->heads) != 0) return -1;
		if (scn_DECWORD(&vp->cyls) != 0) return -1;
		if (scn_DECWORD(&vp->sectors) != 0) return -1;
		if (scn_DECWORD(&vp->type) != 0) return -1;
	}
	return 0;
}

static int near scn_PARTTABLE(PARTTABLE *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;

	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		PARTTABLE *vp = value+kk;

		if (scn_HEXBYTE(&vp->bootind) != 0) return -1;
		if (scn_HEXBYTE(&vp->start_head) != 0) return -1;
		if (scn_HEXBYTE(&vp->start_sec) != 0) return -1;
		if (scn_HEXBYTE(&vp->start_cyl) != 0) return -1;
		if (scn_HEXBYTE(&vp->sysind) != 0) return -1;
		if (scn_HEXBYTE(&vp->last_head) != 0) return -1;
		if (scn_HEXBYTE(&vp->last_sec) != 0) return -1;
		if (scn_HEXBYTE(&vp->last_cyl) != 0) return -1;
		if (scn_HEXDWORD(&vp->lowsec) != 0) return -1;
		if (scn_HEXDWORD(&vp->size) != 0) return -1;
	}
	return 0;
}

static int near scn_MCAID(MCAID *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;

	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		MCAID *vp = value + kk;

		if (scn_HEXWORD(&vp->aid) != 0) return -1;
		if (scn_HEXBYTE(&vp->pos[0]) != 0) return -1;
		if (scn_HEXBYTE(&vp->pos[1]) != 0) return -1;
		if (scn_HEXBYTE(&vp->pos[2]) != 0) return -1;
		if (scn_HEXBYTE(&vp->pos[3]) != 0) return -1;
		if (scn_HEXWORD(&vp->suba) != 0) return -1;
	}
	return 0;
}

static int near scn_EMSHAND(EMSHAND *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;

	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		EMSHAND *vp = value + kk;

		if (scn_HEXWORD(&vp->handle) != 0) return -1;
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
	}
	return 0;
}

static int near scn_EMSMAP(EMSMAP *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	if (scn_DECWORD(&count)) return rtn;

	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		EMSMAP *vp = value + kk;

		if (scn_HEXWORD(&vp->base) != 0) return -1;
		if (scn_HEXWORD(&vp->number) != 0) return -1;
	}
	return 0;
}

static int near scn_TIMELIST(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	TIMELIST *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(TIMELIST));
	vp = sysbuf_ptr(*value);

	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_HEXWORD(&vp->start) != 0) return -1;
		if (scn_HEXWORD(&vp->length) != 0) return -1;
		if (scn_HEXWORD(&vp->count) != 0) return -1;
	}
	return 0;
}

static int near scn_ROMLIST(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	ROMITEM *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(ROMITEM));
	vp = sysbuf_ptr(*value);

	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_HEXWORD(&vp->seg) != 0) return -1;
		if (scn_HEXWORD(&vp->size) != 0) return -1;
	}
	return 0;
}

static int near scn_FLEXROM(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	FLEXROM *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(FLEXROM));
	vp = sysbuf_ptr(*value);

	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_HEXWORD(&vp->src) != 0) return -1;
		if (scn_HEXWORD(&vp->dst) != 0) return -1;
		if (scn_HEXWORD(&vp->len) != 0) return -1;
		if (scn_HEXWORD(&vp->flag) != 0) return -1;
		/* Because of a bug in previous (pre-7.0 beta 3) ASQ */
		/* versions, we may have invalid FLEXROM entries in a */
		/* snapshot file. */
		/* Check for 'em here and discard any that have a source */
		/* or destination of 0. */
		if (!vp->src || !vp->dst) {
		  *nvalue = 0;	/* Nobody home */
		  sysbuf_free (*value);
		  *value = 0;
		  break;
		} /* Invalid entries */
	}

	return 0;
}

static int near scn_HOLES(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	MEMHOLE *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(MEMHOLE));
	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_HEXDWORD(&vp->faddr) != 0) return -1;
		if (scn_HEXDWORD(&vp->length) != 0) return -1;
		if (scn_DECWORD(&vp->class) != 0) return -1;
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
	}
	return 0;
}

static int near scn_OPENFILE(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	OPENFILE *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(MEMHOLE));
	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
	}
	return 0;
}

static int near scn_ENVSTR(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;

	if (scn_DECWORD(nvalue)) return -1;

	*value = 0;
	for (kk = 0; kk < *nvalue; kk++) {
		if (!fgets(TokenBuf,MAXTOKEN,RwFile)) return -1;
		ltrnbln(TokenBuf);
		sysbuf_append(value,TokenBuf,0);
	}
	return 0;
}

static int near scn_MACINFO(SYSBUFH *value,WORD *nvalue)
{
	int rtn;
	WORD kk;
	MACINFO *vp;

#ifdef DEBUGMSG
	do_intmsg ("scn_MAC():\n");
#endif
	rtn = scn_DECWORD(nvalue);
	if (rtn != 0) return rtn;

#ifdef DEBUGMSG
	do_intmsg ("Reading %u values\n", *nvalue);
#endif
	*value = sysbuf_alloc(*nvalue * sizeof(MACINFO));
	if (!(*value)) return -1;

	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		memset( vp, 0, sizeof(MACINFO) );		// Zero INIT structure
		if (scn_ichar(&vp->type) != 0) return -1;
		if (scn_HEXWORD(&vp->start) != 0) return -1;
		if (scn_HEXWORD(&vp->size) != 0) return -1;
		if (scn_HEXWORD(&vp->owner) != 0) return -1;
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
		if (scn_string(vp->text,sizeof(vp->text)) != 0) return -1;
		assert_EOL();
#ifdef DEBUGMSG
	do_intmsg ("Got MAC: %c %04x %04x %04x \"%s\" \"%s\"\n",
		vp->type, vp->start, vp->size, vp->owner, vp->name, vp->text);
#endif
	}
#ifdef DEBUGMSG
	do_intmsg ("scn_MAC() OK\n");
#endif
	return 0;
}

static int near scn_130_QMAP(SYSBUFH *value,WORD *nvalue)
{
	int rtn;
	WORD kk;
	MACINFO *vp;

	rtn = scn_DECWORD(nvalue);
	if (rtn != 0) return rtn;

	*value = sysbuf_alloc(*nvalue * sizeof(MACINFO));
	if (!(*value)) return -1;

	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		QMAP oldvalue;

		if (scn_DECWORD(&oldvalue.id) != 0) return -1;
		if (scn_HEXWORD(&oldvalue.start) != 0) return -1;
		if (scn_HEXWORD(&oldvalue.end) != 0) return -1;
		if (scn_HEXWORD(&oldvalue.owner) != 0) return -1;
		if (scn_HEXDWORD(&oldvalue.length) != 0) return -1;
		if (scn_DECWORD(&oldvalue.ntext) != 0) return -1;
		if (scn_string(oldvalue.name,sizeof(oldvalue.name)) != 0) return -1;
		if (scn_string(oldvalue.text,sizeof(oldvalue.text)) != 0) return -1;

		/* Translate old format to new one */
		vp->type = IdTrans[oldvalue.id];
		vp->start = oldvalue.start;
		vp->size = (WORD)(oldvalue.length / 16);
		vp->owner = oldvalue.owner;
		oldvalue.name[sizeof(vp->name)-1] = '\0';
		strcpy(vp->name,oldvalue.name);
		oldvalue.text[sizeof(vp->text)-1] = '\0';
		strcpy(vp->text,oldvalue.text);
		if (vp->type == MACTYPE_DD && vp->start == 0 && kk != 0) {
			/* Fixup for nested device drivers */
			vp->start = (vp-1)->start;
			vp->owner = (vp-1)->owner;
		}
		assert_EOL();
	}
	return 0;
}


static int near scn_DDLIST(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	DDLIST *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(MEMHOLE));
	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_FARPTR(&vp->this) != 0) return -1;
		if (scn_FARPTR(&vp->next) != 0) return -1;
		if (scn_HEXWORD(&vp->attr) != 0) return -1;
		if (scn_HEXWORD(&vp->strat) != 0) return -1;
		if (scn_HEXWORD(&vp->intr) != 0) return -1;
		if (vp->attr & 0x8000) {
			if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
		}
		else {
			WORD num;

			if (scn_DECWORD(&num) != 0) return -1;
			memset(vp->name,8,0);
			*(BYTE *)vp->name = (BYTE)num;
		}
		assert_EOL();
	}
	return 0;
}

static int near scn_DOSDATA(SYSBUFH *value,WORD *nvalue)
{
	WORD kk;
	DOSDATA *vp;

	if (scn_DECWORD(nvalue)) return -1;

	/* Allocate the list */
	*value = sysbuf_alloc(*nvalue * sizeof(DOSDATA));
	vp = sysbuf_ptr(*value);
	for (kk = 0; kk < *nvalue; kk++,vp++) {
		if (scn_ichar(&vp->type) != 0) return -1;
		if (scn_FARPTR(&vp->saddr) != 0) return -1;
		if (scn_HEXDWORD(&vp->faddr) != 0) return -1;
		if (scn_HEXDWORD(&vp->length) != 0) return -1;
		if (scn_DECWORD(&vp->count) != 0) return -1;
		if (scn_string(vp->name,sizeof(vp->name)) != 0) return -1;
		assert_EOL();
	}
	return 0;
}

static int near scn_ADFINFO(SYSBUFH *value,WORD nvalue)
{
	int rtn;
	WORD kk;
	WORD count;

	memset(value,0,nvalue * sizeof(SYSBUFH));

	if (scn_DECWORD(&count)) return rtn;
	if (count > nvalue) count = nvalue;

	for (kk = 0; kk < count; kk++) {
		ADFINFO v;

		if (scn_HEXWORD(&v.aid) != 0) return -1;
		if (scn_string(v.name,sizeof(v.name)) != 0) return -1;
		if (scn_DECWORD(&v.noption) != 0) return -1;
		v.foption = v.loption = 0;
		if (v.noption > 0) {
			scn_ADFOPTION(&v);
		}
		if (v.aid) {
			sysbuf_store(value+kk,&v,sizeof(v));
		}
		assert_EOL();
	}
	return 0;
}

static int near scn_ADFOPTION(ADFINFO *value)
{
	WORD kk;

	/* Init the list */
	value->foption = value->loption = 0;

	for (kk = 0; kk < value->noption; kk++) {
		SYSBUFH hh;
		ADFOPTION v;

		if (scn_string(v.name,sizeof(v.name)) != 0) return -1;
		if (scn_DECWORD(&v.nchoice) != 0) return -1;
		if (v.nchoice > 0) {
			scn_ADFCHOICE(&v);
		}
		sysbuf_store(&hh,&v,sizeof(v));
		if (value->loption) {
			ADFOPTION *p;

			p = sysbuf_ptr(value->loption);
			p->next = hh;
			value->loption = hh;
		}
		else {
			value->foption = value->loption = hh;
		}
	}
	return 0;
}

static int near scn_ADFCHOICE(ADFOPTION *value)
{
	WORD kk;

	/* Init the list */
	value->fchoice = value->lchoice = 0;

	for (kk = 0; kk < value->nchoice; kk++) {
		WORD ii;
		SYSBUFH hh;
		ADFCHOICE v;

		if (scn_string(v.name,sizeof(v.name)) != 0) return -1;
		for (ii = 0; ii < 4; ii++) {
			if (scn_string(v.pos[ii],10) != 0) return -1;
		}
		sysbuf_store(&hh,&v,sizeof(v));
		if (value->lchoice) {
			ADFCHOICE *p;

			p = sysbuf_ptr(value->lchoice);
			p->next = hh ;
			value->lchoice = hh;
		}
		else {
			value->fchoice = value->lchoice = hh;
		}
	}
	return 0;
}

static int near scn_FSTATS(SYSBUFH *value)
{
	WORD kk;
	FILESTATS fs, *fp;
	SYSBUFH newh;

	if (scn_DECWORD(&kk)) return -1;

	*value = 0;
	for (fp=NULL; kk; kk--) {
		if (fscanf (RwFile, "%x %x %lu %s\n", &fs.ftime, &fs.fdate,
			&fs.fsize, &fs.fname) < 4) return -1;
		fs.next = 0;
		sysbuf_store (&newh, &fs, sizeof(FILESTATS));
		if (fp) fp->next = newh;
		else *value = newh;
		fp = sysbuf_ptr (newh);
	}
	return 0;
}

static int near scn_LSEG(SYSBUFH *value)
{
	WORD kk;
	LSEGDATA ls, *lp;
	SYSBUFH newh;

	if (scn_DECWORD(&kk)) return -1;

	*value = 0;
	for (lp=NULL; kk; kk--) {
		if (scn_string (ls.fne, sizeof(ls.fne)) == -1) return (-1);
		if (fscanf (RwFile,
		    "%x %x %x %x %lx %lx %lx %x %x  %x %x %x  %x %x %x\n",
			&ls.rpara, &ls.epar0, &ls.epar1, &ls.rpar2,
			&ls.asize, &ls.lsize, &ls.isize,
			&ls.preg, &ls.ereg,
			&ls.flags, &ls.npara, &ls.grp,
			&ls.ownrhi, &ls.instlo, &ls.instlen) < 15) return -1;
		ls.next = 0;
		sysbuf_store (&newh, &ls, sizeof(LSEGDATA));
		if (lp) lp->next = newh;
		else *value = newh;
		lp = sysbuf_ptr (newh);
	}
	return 0;
}

static int near scn_MAXBEST(SYSBUFH *value)
{
	WORD kk;
	MAXIMIZEBST ms, *mp;
	SYSBUFH newh;

	if (scn_DECWORD(&kk)) return -1;

	*value = 0;
	for (mp=NULL; kk; kk--) {
		if (fscanf (RwFile, " %x %x %x %x  %x %x %x %x  %x %x\n",
			&ms.ipara, &ms.rpara, &ms.epar0, &ms.epar1,
			&ms.preg, &ms.ereg, &ms.group, &ms.ord,
			&ms.lflags, &ms.subseg) < 4) return -1;
		ms.next = 0;
		sysbuf_store (&newh, &ms, sizeof(MAXIMIZEBST));
		if (mp) mp->next = newh;
		else *value = newh;
		mp = sysbuf_ptr (newh);
	}
	return 0;
}

static int near scn_PNPNODES( SYSBUFH *phList, WORD *pwCount ) {

	WORD wCount = 0;
	WORD kk;
	BYTE *pData;

	if (scn_DECWORD( &wCount )) return -1;

	if (!wCount) return 0;

	*phList = sysbuf_alloc( wCount );
	*pwCount = wCount;
	pData = sysbuf_ptr( *phList );

	/* Read actual data */

	for (kk = 0; kk < wCount; kk++) {

		WORD w;

		if (scn_token( TokenBuf, MAXTOKEN) == EOF) return -1;
		sscanf( TokenBuf, "%x", &w );
		pData[ kk ] = (BYTE)w;

	}

	return 0;

} /* scn_PNPNODES() */

static void near assert_EOL(void)
/* Ensure we've read to the end of the line on last scn_token() call */
{
 char c;

 if (!ReachedEOL) {
	while ((c = (char) fgetc(RwFile)) != '\n' && c != EOF)  ;
	ReachedEOL = TRUE;
 }

} /* End assert_EOL () */

static int near ltrnbln (char *s)
{
 int escape = 0;
 char c,*l,*m;

 for (m=l=s; c = *m; m++) {
	if (c == '\\' && !escape)       escape = 1;
	else {
		/* Handle older snapshot files */
		if (escape && c != '"' && c != '\\') *l++ = '\\';
		escape = 0;
		*l++ = c;
	}
 }
 *l = '\0';
 return (trnbln (s));

}

