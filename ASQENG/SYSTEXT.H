/*' $Header:   P:/PVCS/MAX/ASQENG/SYSTEXT.H_V   1.2   30 May 1997 14:58:44   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SYSTEXT.H								      *
 *									      *
 * Defines for reading/writing system info				      *
 *									      *
 ******************************************************************************/

/*
 * Transferred to German by Herbert Reibe 24-03-1992
 */

#ifndef SYSTEXT_INCLUDED
#define SYSTEXT_INCLUDED

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

/*
 *	Keyword Tables:
 *
 *	BEWARE:  RWKEY elements are used to index RwKeyword,
 *	so DON'T REARRANGE them.
 */

typedef enum _rwkey {
	K_NOTHING,
	K_SNAPTITLE,
	K_SNAPDATE,
	K_SNAPTIME,
	K_ASQVER,
	K_EMSHAND,
	K_EMSHSIZE,
	K_EMSMAP,
	K_TIMELIST,
	K_OPENFILE,
	K_ENVSTR,
	K_CONFIGSYS,
	K_AUTOBAT,
	K_MAXPRO,
	K_EXTRADOSPRO,	/* ExtraDOS.Pro linecount - count of lines to follow */
	K_SYSINI,	/* SYSTEM.INI linecount */
	K_QFILES,	/* QFiles linecount\n date time size fname */
	K_LSEG, 	/* LSEG linecount\n... */
	K_MAXBESTSIZE,	/* Bytes moved high by Maximize */
	K_MAXBEST,	/* MaxBest linecount\n... */
	K_WINDOWSDIR,	/* Windows directory */
	K_WINDOWSVER,	/* Windows version from WINVER.EXE */
	K_WFILES,	/* WFiles linecount\n date time size fname */
	K_ADFINFO,
	K_FLAGS,
	K_ROMSEG,
	K_ROMSIZE,
	K_BOOTDRV,
	K_CPUPARM,
	K_MHZ,
	K_CHIPSET,
	K_LOGDRV,
	K_DOSVER,
	K_IONAME,
	K_DOSNAME,
	K_COMNAME,
	K_BASEMEM,
	K_EXTMEM,
	K_EXTFREE,
	K_BIOSDATA,
	K_BIOSID,
	K_BIOSMFR,
	K_MACHNAME,
	K_ENVSIZE,
	K_ENVUSED,
	K_VIDEO,
	K_SVVENDOR,
	K_SVMODEL,
	K_MOUSE,
	K_KEYBOARD,
	K_DISKROM,
	K_DISKROMSIZE,
	K_ROMLIST,
	K_FLEXROMS,
	K_HOLES,
	K_EXTRAMAP,
	K_EMSXMS,
	K_EMSPARM,
	K_XMSPARM,
	K_DPMIVER,
	K_DPMI32,
	K_IOSTART,
	K_DOSSTART,
	K_DEVSTART,
	K_DATASTART,
	K_DATAEND,
	K_PSP,
	K_CONFIG,
	K_OPENFCBS,
	K_DCACHE,
	K_FDRIVE,
	K_HDRIVE,
	K_HPART0,
	K_HPART1,
	K_CMOS,
	K_MCAID,
	K_VECTORS,
	K_LOWMEM,	/* 1.30 */
	K_HIGHMEM,	/* 1.30 */
	K_LOWDOS,
	K_HIGHDOS,
	K_HIGHLOAD,
	K_SHELL,
	K_COUNTRY,
	K_DRIVPARM,
	K_DDLIST,
	K_DOSDATA,
	K_PCIVER,
	K_PNPDATA,
	K_PNPNODES,
	K_CDROM,
	K_PNPDESC,
	K_END
} RWKEY;

GLOBAL struct _rwkeyword {
	char *name;	/* Item name */
	RWKEY key;	/* Item key */
} near RwKeyword[]
#ifdef GLINIT
#if 0 /* LANG_GR - these are snapshot keywords */
 = {
	"",               K_NOTHING,
	"Titel",          K_SNAPTITLE,
	"Datum",          K_SNAPDATE,
	"Zeit",           K_SNAPTIME,
	"AsqVer",         K_ASQVER,
	"EmsHandle",      K_EMSHAND,
	"EmsHandgr”áe",   K_EMSHSIZE,
	"EmsMap",         K_EMSMAP,
	"TimeList",       K_TIMELIST,
	"OpenFile",       K_OPENFILE,
	"EnvStr",         K_ENVSTR,
	"Config.Sys",     K_CONFIGSYS,
	"AutoExec.Bat",   K_AUTOBAT,
	"Max.Pro",        K_MAXPRO,
	"ExtraDOS.Pro",   K_EXTRADOSPRO,
	"SYSTEM.INI",     K_SYSINI,
	"QualitasFiles",  K_QFILES,
	"LsegData",       K_LSEG,
	"MaxBestSize",    K_MAXBESTSIZE,
	"MaxBest",        K_MAXBEST,
	"WindowsDir",     K_WINDOWSDIR,
	"WindowsVer",     K_WINDOWSVER,
	"WindowsFiles",   K_WFILES,
	"Adf",            K_ADFINFO,
	"Flags",          K_FLAGS,
	"RomSeg",         K_ROMSEG,
	"RomGr”áe",       K_ROMSIZE,
	"Boot-LW",        K_BOOTDRV,
	"CpuParm",        K_CPUPARM,
	"MHz",            K_MHZ,
	"ChipSatz",       K_CHIPSET,
	"Log. LW",        K_LOGDRV,
	"DosVer",         K_DOSVER,
	"IoName",         K_IONAME,
	"DosName",        K_DOSNAME,
	"ComName",        K_COMNAME,
	"BasisMem",       K_BASEMEM,
	"ExtMem",         K_EXTMEM,
	"Extfrei",        K_EXTFREE,
	"BiosDaten",      K_BIOSDATA,
	"BiosId",         K_BIOSID,
	"BiosMfr",        K_BIOSMFR,
	"MachName",       K_MACHNAME,
	"EnvSize",        K_ENVSIZE,
	"EnvUsed",        K_ENVUSED,
	"Video",          K_VIDEO,
	"SVGAHerst.",     K_SVVENDOR,
	"SVGAModell",     K_SVMODEL,
	"Maus",           K_MOUSE,
	"Tastatur",       K_KEYBOARD,
	"DiskRom",        K_DISKROM,
	"DiskRomGr”áe",   K_DISKROMSIZE,
	"RomListe",       K_ROMLIST,
	"FlexRoms",       K_FLEXROMS,
	"L”cher",         K_HOLES,
	"ExtraMap",       K_EXTRAMAP,
	"EmsXms",         K_EMSXMS,
	"EmsParam",       K_EMSPARM,
	"XmsParam",       K_XMSPARM,
	"DPMIVer",        K_DPMIVER,
	"DPMI32",         K_DPMI32,
	"IoStart",        K_IOSTART,
	"DosStart",       K_DOSSTART,
	"DevStart",       K_DEVSTART,
	"DataStart",      K_DATASTART,
	"DataEnde",       K_DATAEND,
	"Psp",            K_PSP,
	"Config",         K_CONFIG,
	"OpenFcbs",       K_OPENFCBS,
	"Dcache",         K_DCACHE,
	"Floppy",         K_FDRIVE,
	"Festpl.",        K_HDRIVE,
	"Fpart0",         K_HPART0,
	"Fpart1",         K_HPART1,
	"Cmos",           K_CMOS,
	"McaId",          K_MCAID,
	"Vektoren",       K_VECTORS,
	"LowMem",         K_LOWMEM,       /* 1.30 */
	"HighMem",        K_HIGHMEM,      /* 1.30 */
	"LoDOS",          K_LOWDOS,
	"HiDOS",          K_HIGHDOS,
	"HighLoad",       K_HIGHLOAD,
	"Shell",          K_SHELL,
	"Country",        K_COUNTRY,
	"Lw.-Param.",     K_DRIVPARM,
	"DDliste",        K_DDLIST,
	"DosDaten",       K_DOSDATA,
	?,		  K_PCIVER,
	?,		  K_PNPDATA,
	?,		  K_PNPNODES,
	?,		  K_CDROM,
	?,		  K_PNPDESC,
	"Ende",           K_END,
	NULL,		0
}
#endif
 = {
	"",             K_NOTHING,
	"Title",        K_SNAPTITLE,
	"Date",         K_SNAPDATE,
	"Time",         K_SNAPTIME,
	"AsqVer",       K_ASQVER,
	"EmsHandle",    K_EMSHAND,
	"EmsHandSize",  K_EMSHSIZE,
	"EmsMap",       K_EMSMAP,
	"TimeList",     K_TIMELIST,
	"OpenFile",     K_OPENFILE,
	"EnvStr",       K_ENVSTR,
	"Config.Sys",   K_CONFIGSYS,
	"AutoExec.Bat", K_AUTOBAT,
	"Max.Pro",      K_MAXPRO,
	"ExtraDOS.Pro", K_EXTRADOSPRO,
	"SYSTEM.INI",   K_SYSINI,
	"QualitasFiles",K_QFILES,
	"LsegData",     K_LSEG,
	"MaxBestSize",  K_MAXBESTSIZE,
	"MaxBest",      K_MAXBEST,
	"WindowsDir",   K_WINDOWSDIR,
	"WindowsVer",   K_WINDOWSVER,
	"WindowsFiles", K_WFILES,
	"Adf",          K_ADFINFO,
	"Flags",        K_FLAGS,
	"RomSeg",       K_ROMSEG,
	"RomSize",      K_ROMSIZE,
	"BootDrv",      K_BOOTDRV,
	"CpuParm",      K_CPUPARM,
	"Mhz",          K_MHZ,
	"ChipSet",      K_CHIPSET,
	"LogDrv",       K_LOGDRV,
	"DosVer",       K_DOSVER,
	"IoName",       K_IONAME,
	"DosName",      K_DOSNAME,
	"ComName",      K_COMNAME,
	"BaseMem",      K_BASEMEM,
	"ExtMem",       K_EXTMEM,
	"Extfree",      K_EXTFREE,
	"BiosData",     K_BIOSDATA,
	"BiosId",       K_BIOSID,
	"BiosMfr",      K_BIOSMFR,
	"MachName",     K_MACHNAME,
	"EnvSize",      K_ENVSIZE,
	"EnvUsed",      K_ENVUSED,
	"Video",        K_VIDEO,
	"SVGAVendor",   K_SVVENDOR,
	"SVGAModel",    K_SVMODEL,
	"Mouse",        K_MOUSE,
	"Keyboard",     K_KEYBOARD,
	"DiskRom",      K_DISKROM,
	"DiskRomSize",  K_DISKROMSIZE,
	"RomList",      K_ROMLIST,
	"FlexRoms",     K_FLEXROMS,
	"Holes",        K_HOLES,
	"ExtraMap",     K_EXTRAMAP,
	"EmsXms",       K_EMSXMS,
	"EmsParm",      K_EMSPARM,
	"XmsParm",      K_XMSPARM,
	"DPMIVer",      K_DPMIVER,
	"DPMI32",       K_DPMI32,
	"IoStart",      K_IOSTART,
	"DosStart",     K_DOSSTART,
	"DevStart",     K_DEVSTART,
	"DataStart",    K_DATASTART,
	"DataEnd",      K_DATAEND,
	"Psp",          K_PSP,
	"Config",       K_CONFIG,
	"OpenFcbs",     K_OPENFCBS,
	"Dcache",       K_DCACHE,
	"Fdrive",       K_FDRIVE,
	"Hdrive",       K_HDRIVE,
	"Hpart0",       K_HPART0,
	"Hpart1",       K_HPART1,
	"Cmos",         K_CMOS,
	"McaId",        K_MCAID,
	"Vectors",      K_VECTORS,
	"LowMem",       K_LOWMEM,       /* 1.30 */
	"HighMem",      K_HIGHMEM,      /* 1.30 */
	"LowDOS",       K_LOWDOS,
	"HighDOS",      K_HIGHDOS,
	"HighLoad",     K_HIGHLOAD,
	"Shell",        K_SHELL,
	"Country",      K_COUNTRY,
	"DrivParm",     K_DRIVPARM,
	"DDlist",       K_DDLIST,
	"DosData",      K_DOSDATA,
	"PCIVer",       K_PCIVER,
	"PlugnPlay",    K_PNPDATA,      /* wPnP_ver, wNumNodes, wMaxNodeSize */
	"PnPNodes",     K_PNPNODES,
	"CDROM",        K_CDROM,        /* nCDs, nFirstCD */
	"PnPDesc",      K_PNPDESC,
	"End",          K_END,
	NULL,		0
}
#endif
;

#endif /*SYSTEXT_INCLUDED*/
