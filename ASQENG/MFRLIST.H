/*' $Header:   P:/PVCS/MAX/ASQENG/MFRLIST.H_V   1.0   05 Sep 1995 15:05:54   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MFRLIST.H								      *
 *									      *
 * List of BIOS/machine maufacturers that we recognize			      *
 *									      *
 ******************************************************************************/

typedef struct _biosmfr {	/* Manufacturer-from-BIOS structure */
	WORD where;	/* Where to look */
	WORD shift;	/* Maximum shift */
	char *what;	/* What to look for */
	char *whobios;	/* Who made BIOS */
	char *whatmach; /* Specific machine name */
} BIOSMFR;

BIOSMFR MfrList1[] = {
	{ 0xE038, 0,"Phoenix Technologies Ltd","Phoenix", "@2" },
	{ 0xE0D9, 0,"American Megatrends Inc","AMI",NULL },
	{ 0xE026, 0,"COPYRIGHT Award Software Inc.","Award", NULL },
	{ 0xEB00,128,"Copyright Chips & Technologies, Inc.","C & T", NULL },
	{ 0x0000,50,"Dell Systems 3","Dell","@1" },
	{ 0x0000,50,"Dell Computer Corp","Dell",NULL },
	{ 0x0010, 0,"(C) COPYRIGHT XTRA BUSINESS SYSTEMS","ITT","ITT XTRA" },
	{ 0x0010, 0,"(C) COPYRIGHT ALCATEL",    "Alcatel","" },
	{ 0x00F8, 0,"HP\x62",   "HP","HP RS/20" },
	{ 0x00F8, 0,"HP\x66",   "HP","HP RS/16" },
	{ 0x00F8, 0,"HP\x67",   "HP","HP QS/16" },
	{ 0x00F8, 0,"HP\x68",   "HP","HP QS/20" },
	{ 0x00F8, 0,"HP\x69",   "HP","HP RS/20C" },
	{ 0x00F8, 0,"HP\x6A",   "HP","HP RS/25C" },
	{ 0x00F8, 0,"HP\x8C",   "HP","HP QS/16S" },
	{ 0x800C, 0,"ZDS",      "Zenith",NULL },
	{ 0xDFDC, 0,"--",       "GRiD",NULL },
	{ 0xE000, 0,"T5100",    "Toshiba", "Toshiba 5100" },
	{ 0xE008, 0,"COPR. IBM 19","IBM", NULL },
	{ 0xE0C1, 0,"System: 386R3","CompuAdd","CompuAdd 386" },
	{ 0xE009, 0,"COPYRIGHT (C) OLIVETTI","Olivetti","@4" },
	{ 0xE076, 0,"NEC Corporation","NEC","@3" },
	{ 0xF96B, 0,"Z-NIX",    "Z-NIX",NULL },
	{ 0xFFEA, 0,"COMPAQ",   "COMPAQ",NULL },
	{ 0xF9B4, 0,"DTK Corp.","DTK",NULL },

	{ 0x0000, 0xFFEA,"COPYRIGHT AST RESEARCH",      "AST","" },
	{ 0x0000, 0xFFEF,"Quadram Quad386XT",   "Quadram","Quadram Quad386XT" },
	{ 0x0000, 0xFFFB,"EPSON",       "Epson","Epson" },
	{ 0xF800, 0x7FFC,"ASEM",        "Asem","Asem" },
#ifdef LANG_GR
	{ 0,	  0,NULL,	"unbekannt", NULL }
#else
	{ 0,	  0,NULL,	"Unknown", NULL }
#endif
};

BIOSMFR MfrList2[] = {
	{ 0xE076, 0,"PC's Limited System 300","@2", "Dell System 300" },
	{ 0xE091, 0,"SX Plus",  "@3", "NEC SX Plus" },

	{ 0xE845, 0,"\x03",     "@1","Dell System 300" },
	{ 0xE845, 0,"\x06",     "@1","Dell System 310" },
	{ 0xE845, 0,"\x07",     "@1","Dell System 325" },
	{ 0xE845, 0,"\x09",     "@1","Dell System 310A" },
	{ 0xE845, 0,"\x0a",     "@1","Dell System 316" },
	{ 0xE845, 0,"\x0d",     "@1","Dell System 316SX" },
	{ 0xE845, 0,"\x0e",     "@1","Dell System 316LT" },
	{ 0xE845, 0,"\x0f",     "@1","Dell System 320LX" },
	{ 0xE845, 0,"\x11",     "@1","Dell System 425E" },
	{ 0xE845, 0,"\x12",     "@1","Dell System 433E" },
	{ 0xE845, 0,"\x13",     "@1","Dell System 320LT" },
	{ 0xE845, 0,"\x14",     "@1","Dell System 325D/333D" },
	{ 0xE845, 0,"\x15",     "@1","Dell System 325P/333P" },
	{ 0xE845, 0,"\x17",     "@1","Dell System 425GE" },
	{ 0xE845, 0,"\x18",     "@1","Dell System 433GE" },
	{ 0xE845, 0,"\x1b",     "@1","Dell System 320N" },

	{ 0x80A1, 0,"\xC0",     "@2","Tandy/GRiD" },
	{ 0xFFFD, 0,"R",        "@4","Olivetti M300" },
	{ 0xFFFD, 0,"b",        "@4","Olivetti M316" },
	{ 0xFFFD, 0,"t",        "@4","Olivetti M305/310" },
	{ 0xFFFD, 0,"V",        "@4","Olivetti M386/25" },
	{ 0xFFFD, 0,"E",        "@4","Olivetti M386/20" },
	{ 0xFFFD, 0,"P",        "@4","Olivetti M386/25" },
#ifdef LANG_GR
	{ 0,	  0,NULL,	"unbekannt", NULL }
#else
	{ 0,	  0,NULL,	"Unknown", NULL }
#endif
};

/* Wed Nov 21 10:44:24 1990 alan:  fix bugs */
/* Fri Jan 04 09:37:52 1991 alan:  Add C&T BIOS signature */
/* Tue Mar 24	       1992 hr:    Transferred to GERMAN */
