/*' $Header:   P:/PVCS/MAX/ASQENG/MEM_INFO.C_V   1.2   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MEM_INFO.C								      *
 *									      *
 * Formatting routines for memory screens				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>

#include <engine.h>		/* Engine definitons */
#include "info.h"               /* Information functions */
#include "sysinfo.h"            /* System info functions */
#include <commfunc.h>		/* Common functions */
#include <libtext.h>

#define MEM_INFO_C
#include "engtext.h"            /* Text strings */

typedef struct _inttitles {	/* Interrupt titles */
	int first;		/* First interrupt in range */
	int last;		/* Last interrupt in range */
	char *title;		/* Title text */
} INTTITLES;

INTTITLES IntTitles[] = {
	/* Titles (mostly) from IBM PC AT Technical Reference,
	   pp. 5-5 & 5-6 */
	0x00, 0x00, MSG1001,
	0x01, 0x01, MSG1002,
	0x02, 0x02, MSG1003,
	0x03, 0x03, MSG1004,
	0x04, 0x04, MSG1005,
	0x05, 0x05, MSG1006,
	0x06, 0x06, MSG1007,		/* Invalid Opcode on AT/PS2 */
	0x07, 0x07, MSG1008,
	0x08, 0x08, MSG1009,
	0x09, 0x09, MSG1010,
	0x0A, 0x0A, MSG1011, /* Reserved on PC/XT */
	0x0B, 0x0B, MSG1012,
	0x0C, 0x0C, MSG1013,
	0x0D, 0x0D, MSG1014, /* XT HD */
	0x0E, 0x0E, MSG1015,
	0x0F, 0x0F, MSG1016,
	0x10, 0x10, MSG1017,
	0x11, 0x11, MSG1018,
	0x12, 0x12, MSG1019,
	0x13, 0x13, MSG1020,
	0x14, 0x14, MSG1021,
	0x15, 0x15, MSG1022,
	0x16, 0x16, MSG1023,
	0x17, 0x17, MSG1024,
	0x18, 0x18, MSG1025,
	0x19, 0x19, MSG1026,
	0x1A, 0x1A, MSG1027,
	0x1B, 0x1B, MSG1028,
	0x1C, 0x1C, MSG1029,
	0x1D, 0x1D, MSG1030,
	0x1E, 0x1E, MSG1031,
	0x1F, 0x1F, MSG1032,
	0x20, 0x20, MSG1033,
	0x21, 0x21, MSG1034,
	0x22, 0x22, MSG1035,
	0x23, 0x23, MSG1036,
	0x24, 0x24, MSG1037,
	0x25, 0x25, MSG1038,
	0x26, 0x26, MSG1039,
	0x27, 0x27, MSG1040,
	0x28, 0x28, MSG1041,
	0x29, 0x29, MSG1042,
	0x2A, 0x2A, MSG1043,
	0x2B, 0x2E, MSG1044,
	0x2F, 0x2F, MSG1045,
	0x30, 0x32, MSG1046,
	0x33, 0x33, MSG1047,
	0x34, 0x3F, MSG1048,
	0x40, 0x40, MSG1049,
	0x41, 0x41, MSG1050,
	0x42, 0x42, MSG1051,
	0x43, 0x43, MSG1052,
	0x44, 0x45, MSG1053,
	0x46, 0x46, MSG1054,
	0x47, 0x49, MSG1055,
	0x4A, 0x4A, MSG1056,
	0x4B, 0x5F, MSG1057,
	0x60, 0x66, MSG1058,
	0x67, 0x67, MSG1059,
	0x68, 0x6F, MSG1060,
	0x70, 0x70, MSG1061,
	0x71, 0x71, MSG1062,
	0x72, 0x72, MSG1063,
	0x73, 0x73, MSG1064,
	0x74, 0x74, MSG1065,
	0x75, 0x75, MSG1066,
	0x76, 0x76, MSG1067,
	0x77, 0x77, MSG1068,
	0x78, 0x7F, MSG1069,
	0x80, 0x85, MSG1070,
	0x86, 0xF0, MSG1071,
	0xF1, 0xFF, MSG1072,
	0, 0, NULL
};

char *AltTitles[] = {	/* Alternate titles for PC/XT interrupts */
	MSG1073,
	MSG1074,
};

/* Formats */

/* Summary */
char *MemFmt1 = "%21s: %8s (%3d KB)";
char *MemFmt2 = "%21s: %10s (%4d KB)";
/* Low/High DOS */
char *MemFmt3 = "%-12.12s %Fp %7s %s";
/* ROM Scan */
char *MemFmt4 = "%4lX-%5lX %c%3d KB%c %c      %c      %c    %c     %c";
/* Interrupts */
char *MemFmt5a = "%-12.12s %Fp";
char *MemFmt5b = " %02X";
char *MemFmt6 = "%-20.20s %02X  %-12.12s %Fp";
/* Extended */
char *MemFmt7 = "%21s:  %u KB";
char *MemFmt8 = "%-15.15s%9lX:0000  %4d KB";
/* Expanded */
char *MemFmt9a = "%34s: %u%c%u";
char *MemFmt9b = "%34s: %u%c%02u";
char *MemFmt9c = "%34s: %04X";
char *MemFmt9d = "%34s: %u";
char *MemFmt10 = "%21s: %4u KB  %s";
/* EMS Usage */
char *MemFmt11 = "%-8.8s %-40.40s";
char *MemFmt12a = "%c %-6.6s";
char *MemFmt12b = "  %04lX-%04lX";
char *MemFmt12c = "%c %-6.6s  %04lX-%04lX";
/* XMS */
char *MemFmt13a = "%33s: %u%c%02u";
char *MemFmt13b = "%33s: %4u KB";
char *MemFmt13c = "%33s: %s";
char *MemFmt13d = "%33s: %u";
/* Timing */
char *MemFmt14 = "%05X  %5d  %5d %8u %s";
char *MemFmt14b= "%05X  %5d  %5d        * %s";
/* General */
/* MEMFMT15 used for centering */

/* Local functions */
long simple_summ(
	UMAP *um_start, 	/* Starting entry in memory map */
	UMAP *um_end,		/* Ending entry in memory map */
	MAPCLASS class);	/* Which class to summarize */

long program_summ(
	HANDLE info,		/* Control structure */
	UMAP *um_start, 	/* Starting entry in memory map */
	UMAP *um_end,		/* Ending entry in memory map */
	char *fmt);		/* Formatting string */

void use_summ(
	HANDLE info,		/* Control structure */
	BYTE *str,		/* EMS map string */
	int nstr,		/* How many chars in string */
	BYTE chr,		/* Which char we're looking for */
	char *label,		/* Label for this item */
	char *fmt1,		/* Part 1 format */
	char *fmt2);		/* Part 2 format */

char *comma_num(long num);

/*
 *	Memory_Summary - build text for Memory / Summary screen
 */

void Memory_Summary(HANDLE info)
{
	UMAP *um_start; 	/* Start point in map */
	UMAP *um_mid;		/* Mid point (low/high) in map */
	UMAP *um_end;		/* End point in map */
	long count;		/* Scratch byte count */
	long subtotal;		/* Subtotal bytes */
	long total;		/* Total bytes */

	info_color(info,22);
	info_format(info,MEMFMT1);

	/* Set up start, mid, and end points in memory map */
	{
		um_start = um_mid = sysbuf_ptr(SysInfo->umap);
		um_end = um_start + SysInfo->umaplen;
		while (um_mid < um_end) {
			if (um_mid->flags.high) break;
			um_mid++;
		}
	}

	/* ----- Low DOS Memory ----- */
	total = subtotal = 0;

	/* DOS System */
	count = simple_summ(um_start,um_mid,CLASS_DOS);
	iprintf(info,MemFmt1,MSG1075,comma_num(count),KBR(count));
	subtotal += count;

	/* Device drivers */
	count = simple_summ(um_start,um_mid,CLASS_DEV);
	iprintf(info,MemFmt1,MSG1076,comma_num(count),KBR(count));
	subtotal += count;

	/* Page Frame */
	if (SysInfo->flags.ems) {
		/* Page Frame */
		count = simple_summ(um_start,um_mid,CLASS_EMS);
		if (count > 0) {
			iprintf(info,MemFmt1,MSG1077,comma_num(count),KBR(count));
			subtotal += count;
		}
	}

	/* Programs in Low DOS */
	count = program_summ(info,um_start,um_mid,MemFmt1);
	subtotal += count;

	/* Unknown */
	count = simple_summ(um_start,um_mid,CLASS_UNKNOWN);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1078,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* Available (i.e., Transient Program Area) */
	count = simple_summ(um_start,um_mid,CLASS_AVAIL);
	iprintf(info,MemFmt1,MSG1079,comma_num(count),KBR(count));
	subtotal += count;

	iprintf(info,MemFmt1,MSG1080,comma_num(subtotal),KBR(subtotal));
	iprintf(info,"");

	total += subtotal;

	/* Memory not installed between low and high DOS */
	count = simple_summ(um_start,um_mid,CLASS_NOTINST);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1082,comma_num(count),KBR(count));
		iprintf(info,"");
	}

	/* ----- High DOS Memory ----- */
	subtotal = 0;

	/* Video */
	count = simple_summ(um_mid,um_end,CLASS_VIDEO);
	iprintf(info,MemFmt1,MSG1084,comma_num(count),KBR(count));
	subtotal += count;

	if (SysInfo->flags.ems) {
		/* Page Frame */
		count = simple_summ(um_mid,um_end,CLASS_EMS);
		if (count > 0) {
			iprintf(info,MemFmt1,MSG1085,comma_num(count),KBR(count));
			subtotal += count;
		}
	}

	/* RAM */
	count = simple_summ(um_mid,um_end,CLASS_RAM);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1189,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* ROM */
	count = simple_summ(um_mid,um_end,CLASS_ROM);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1086,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* RAM or ROM */
	count = simple_summ(um_mid,um_end,CLASS_RAMROM);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1190,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* Programs in High DOS */
	count = program_summ(info,um_mid,um_end,MemFmt1);
	subtotal += count;

	/* UMB */
	count = simple_summ(um_mid,um_end,CLASS_UMB);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1087,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* MAX / ExtraDOS subsegments */
	count = simple_summ(um_mid,um_end,CLASS_SUBSEG);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1087A,comma_num(count),KBR(count));
		subtotal += count;
	}

	count = simple_summ(um_mid,um_end,CLASS_UNKNOWN);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1088,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* Unused */
	count = simple_summ(um_mid,um_end,CLASS_UNUSED);
	if (count > 0) {
		iprintf(info,MemFmt1,MSG1089,comma_num(count),KBR(count));
		subtotal += count;
	}

	/* Available */
	count = simple_summ(um_mid,um_end,CLASS_AVAIL);
	iprintf(info,MemFmt1,MSG1090,comma_num(count),KBR(count));
	subtotal += count;

	iprintf(info,MemFmt1,MSG1091,comma_num(subtotal),KBR(subtotal));

	info_color(info,22);
	info_format(info,MEMFMT2);

	iprintf(info,"");
	count = (DWORD)SysInfo->extfree*1024;
	iprintf(info,MemFmt2,MSG1093,comma_num(count),KBR(count));
	count = (DWORD)SysInfo->extmem*1024;
	iprintf(info,MemFmt2,MSG1094,comma_num(count),KBR(count));

	total += SysInfo->extmem;
	iprintf(info,"");
	count = (DWORD)(SysInfo->basemem + SysInfo->extmem)*1024;
	iprintf(info,MemFmt2,MSG1096,comma_num(count),KBR(count));
	iprintf(info,"");
	count = (DWORD)SysInfo->emsparm.avail * 16 * 1024;
	iprintf(info,MemFmt2,MSG1098,comma_num(count),KBR(count));
	count = (DWORD)SysInfo->emsparm.total * 16 * 1024;
	iprintf(info,MemFmt2,MSG1099,comma_num(count),KBR(count));
	if (SysInfo->flags.ems && SysInfo->flags.xms) {
		count = (DWORD)SysInfo->ems_xms * 1024;
		iprintf(info,MemFmt2,MSG1193,comma_num(count),KBR(count));
	}
}

/*
 *	Memory_Low_DOS - build text for Memory / Low DOS screen
 */

void Memory_Low_DOS(HANDLE info)
{
	UMAP *ump;		/* Pointer to memory map */
	UMAP *umpend;

	info_color(info,DWIDTH1);
	info_format(info,MEMFMT3);

	iprintf(info,MSG1100);
	iprintf(info,MSG1101);
	iprintf(info,"");

	info_color(info,12);

	ump = sysbuf_ptr(SysInfo->umap);
	umpend = ump + SysInfo->umaplen;
	while (ump < umpend) {
		if (ump->flags.high) break;
		if (ump->faddr == SysInfo->io_start ||
		    ump->faddr == SysInfo->dos_start ||
		    ump->faddr == SysInfo->dev_start ||
		    ump->faddr == SysInfo->data_start ||
		    ump->faddr == SysInfo->data_end) {
			iprintf(info,"");
		}
		iprintf(info,MemFmt3,
			ump->name, ump->saddr, comma_num(ump->length), ump->text);
		ump++;
	}
}

/*
 *	Memory_High_DOS - build text for Memory / High DOS screen
 */

void Memory_High_DOS(HANDLE info)
{
	UMAP *ump;		/* Pointer to memory map */
	UMAP *umpend;

	info_color(info,DWIDTH1);
	info_format(info,MEMFMT3);

	iprintf(info,MSG1105);
	iprintf(info,MSG1106);
	iprintf(info,"");

	info_color(info,12);

	ump = sysbuf_ptr(SysInfo->umap);
	umpend = ump + SysInfo->umaplen;
	while (ump < umpend) {
		if (ump->flags.high) break;
		ump++;
	}

	while (ump < umpend) {
		iprintf(info,MemFmt3,
			ump->name, ump->saddr, comma_num(ump->length), ump->text);
		ump++;
	}
}

/*
 *	Memory_ROM_Scan - build text for Memory / ROM Scan screen
 */

void Memory_ROM_Scan(HANDLE info)
{
	DWORD start1,start2;		/* Start addresses */
	DWORD length1,length2;		/* Block lengths */
	int check1,check2;		/* Where to put check marks */
	int over1,over2;		/* Overlap flags */
	int done;			/* Done flag */
	UMAP *ump;			/* Pointer to memory map */
	UMAP *umpend;

	ump = sysbuf_ptr(SysInfo->umap);
	umpend = ump + SysInfo->umaplen;
	while (ump < umpend) {
		if (ump->flags.high) break;
		ump++;
	}

	info_format(info,MEMFMT4);
	info_color(info,DWIDTH1);
	iprintf(info,MSG1109);
	iprintf(info,"");
	info_color(info,0);

	/* Set up */
	start1 = ump->faddr;
	length1 = ump->length;
	check1 = 0;
	over1 = FALSE;

	/* Group like regions */
	done  = 0;
	while (!done) {
		if (ump < umpend) {
			start2 = ump->faddr;
			length2 = ump->length;
			over2 = FALSE;

			/* Classify region */
			switch (ump->class) {
			case CLASS_VIDEO:
			case CLASS_RAM:
				check2 = 1;
				break;
			case CLASS_ROM:
				check2 = 3;
				break;
			case CLASS_EMS:
				check2 = 4;
				break;
			case CLASS_UNUSED:
				check2 = 5;
				break;
			case CLASS_UNKNOWN:
			case CLASS_RAMROM:
			case CLASS_AVAIL:
			case CLASS_UMB:
			default:
				/* HighDos */
				check2 = 2;
				if (ump->flags.over) over2 = TRUE;
			}
		}
		else {
			/* End of list, finish up */
			start2 = 0;
			length2 = 0;
			check2 = -1;
			over2 = FALSE;
			done++;
		}
		if (!check1) check1 = check2;
		else {
			if (check1 == check2) {
				/* Current same as previous, combine 'em */
				length1 += ump->length;
			}
			else {
				/* Current different from previous, print it */
				char checks[5+1];

				strcpy(checks,"     ");
				checks[check1-1] = 'û';
				iprintf(info,MemFmt4,
					start1/16,
					(start1+length1)/16,
					over1 ? '[' : ' ',
					KBR(length1),
					over1 ? ']' : ' ',
					checks[0],
					checks[1],
					checks[2],
					checks[3],
					checks[4]);
				start1 = start2;
				length1 = length2;
				check1 = check2;
				over1 = over2;
			}
		}
		ump++;
	}
}

/*
 *	Memory_Interrupts - build text for Memory / Interrupts screen
 */

void Memory_Interrupts(HANDLE info)
{
	WORD ord;			/* UMAP ordinal */
	UMAP *ump;			/* Pointer to memory map */
	UMAP *umpend;

	info_color(info,DWIDTH1);
	info_format(info,MEMFMT15);
	ictrtext(info,MSG1112,DWIDTH1);
	iprintf(info,"");
	info_format(info,MEMFMT5);
	iprintf(info,MSG1114);
	info_color(info,12);
	iprintf(info,"");

	/* Part I:  Interrupts by program */
	ord = 1;
	ump = sysbuf_ptr(SysInfo->umap);
	umpend = ump + SysInfo->umaplen;
	while (ump < umpend) {
		int j,k;
		int nline;
		char line[80];

		j = 0;
		sprintf(line,MemFmt5a,ump->name,ump->saddr);
		nline = strlen(line);
		for (k=0; k < 256; k++) {
			if (SysInfo->intmap[k] == ord) {
				sprintf(line+strlen(line),MemFmt5b,k);
				j++;
				if (j >= 9) {
					iprintf(info,line);
					memset(line,' ',nline);
					line[nline] = '\0';
					j = 0;
				}
			}
		}
		if (j > 0) {
			iprintf(info,line);
		}
		ump++;
		ord++;
	}

	/* Part II:  Interrupts by Number */
	iprintf(info,"");
	info_format(info,MEMFMT15);
	info_color(info,DWIDTH1);
	ictrtext(info,MSG1119,DWIDTH1);
	info_format(info,MEMFMT6);
	iprintf(info,"");
	iprintf(info,MSG1121);
	info_color(info,23);

	{
		int j, k;

		for (k = j = 0; k < 256; k++) {
			char *name;
			char *title;

			if (SysInfo->intmap[k]) {
				ump = (UMAP *)sysbuf_ptr(SysInfo->umap) + SysInfo->intmap[k] - 1;
				name = ump->name;
			}
			else	name = MSG1122;

			if (k > IntTitles[j].last) j++;

			title = IntTitles[j].title;
			if (*title == '@') {
				if (SysInfo->flags.pc || SysInfo->flags.xt) {
					title = AltTitles[title[1]-'0'];
				}
				else	title += 2;
			}

			if ((k % 16) == 0) iprintf(info,"");

			iprintf(info,MemFmt6,
				title,k,name,SysInfo->vectors[k]);
		}
	}
}

/*
 *	Memory_Extended - build text for Memory / Extended screen
 */

void Memory_Extended(HANDLE info)
{

	if (!(SysInfo->flags.at || SysInfo->flags.mca)) {
		info_format(info,MEMFMT15);
		ictrtext(info,MSG1125,DWIDTH1);
		return;
	}
	info_color(info,22);
	info_format(info,MEMFMT7);
	iprintf(info,MemFmt7,MSG1126,SysInfo->extmem);
	iprintf(info,"");

	info_format(info,MEMFMT8);
	info_color(info,DWIDTH1);

	iprintf(info,MSG1128);
	info_color(info,0);
	iprintf(info,"");
	if (SysInfo->extfree) {
		iprintf(info,MemFmt8,MSG1130,0x10000L,SysInfo->extfree);
	}

	if ((SysInfo->extmem - SysInfo->extfree) > 0) {
		iprintf(info,MemFmt8,MSG1131,
			0x10000L + (DWORD)SysInfo->extfree * 1024/16,
			SysInfo->extmem - SysInfo->extfree);
	}
}

/*
 *	Memory_Expanded - build text for Memory / Expanded screen
 */

void Memory_Expanded(HANDLE info)
{
	WORD kk;		/* Loop counter */
	WORD avail;		/* Available memory in KB */
	WORD total;		/* Total memory in KB */
	int majver;		/* EMS major version number */
	int minver;		/* EMS minor version number */
	EMSHAND *emshand;	/* Pointer to EMS handle info */
	WORD *emssize;

	if (!SysInfo->flags.ems) {
		info_format(info,MEMFMT15);
		ictrtext(info,MSG1132,DWIDTH1);
		return;
	}

	info_color(info,35);
	info_format(info,MEMFMT9);

	emshand = sysbuf_ptr(SysInfo->emshand);
	emssize = sysbuf_ptr(SysInfo->emssize);

	majver = (SysInfo->emsparm.version >> 4) & 0x0f;
	minver = SysInfo->emsparm.version & 0x0f;
	iprintf(info,MemFmt9a,MSG1133,majver,NUM_VDECIMAL,minver);
	if (SysInfo->cpu.vcpi_ver) {
		iprintf(info,MemFmt9b,MSG1165,
			bcd_num(SysInfo->cpu.vcpi_ver / 256),
			NUM_VDECIMAL,
			bcd_num(SysInfo->cpu.vcpi_ver & 0xff));
	}
	if (SysInfo->cpu.win_ver) {
		iprintf(info,MemFmt9b,MSG1166,
			bcd_num(SysInfo->cpu.win_ver / 256),
			NUM_VDECIMAL,
			bcd_num(SysInfo->cpu.win_ver & 0xff));
	}

	if (SysInfo->emsparm.frame) iprintf(info,MemFmt9c,MSG1134,SysInfo->emsparm.frame);
	if (SysInfo->flags.lim4) {
		iprintf(info,MemFmt9d,MSG1135,SysInfo->emsparm.mpages);
		iprintf(info,MemFmt9d,MSG1136,SysInfo->emsparm.tothand);
		iprintf(info,MemFmt9d,MSG1137,SysInfo->emsparm.amrs);
	}
	iprintf(info,"");
	total = 0;

	info_color(info,22);
	info_format(info,MEMFMT10);

	for (kk = 0; kk < SysInfo->emsparm.acthand; kk++) {
		char temp1[16];
		char temp2[16];

		if (SysInfo->flags.lim4) {
			sprintf(temp1,"%s %3d",MSG1139,emshand[kk].handle);
			memcpy(temp2,emshand[kk].name,8);
			temp2[8] = '\0';
		}
		else {
			sprintf(temp1,"%s    ",MSG1139,emshand[kk].handle);
			temp2[0] = '\0';
		}

		iprintf(info,MemFmt10,
			temp1,
			emssize[kk] * 16,
			temp2);
		total += emssize[kk] * 16;
	}
	avail = SysInfo->emsparm.avail * 16;
	iprintf(info,MemFmt10,"",avail,MSG1141);
	total += avail;
	iprintf(info,MemFmt10,MSG1142,total,"");
}

/*
 *	Memory_EMS_Usage - build text for Memory / EMS Usage screen
 */

#define UNUSED_CHR '#'  /* Character for unused entries */
#define DOS_CHR    '²'  /* (178) Character for DOS entries */
#define FRAME_CHR  '°'  /* (176) Character for Page Frame entries */
#define ROM_CHR    'þ'  /* (254) Character for ROM entries */
#define RAM_CHR    'è'  /* (232) Character for RAM entries */
#define VID_CHR    '÷'  /* (247) Character for Video entries */

void Memory_EMS_Usage(HANDLE info)
{
	WORD kk;		/* Loop counter */
	UMAP *ump;		/* Pointer to memory map */
	UMAP *umpend;
	BYTE mapstr[(4*16)+1];	/* EMS map string */
	BYTE hinum[(4*16)+1];	/* Tens part of page numbers */
	BYTE lonum[(4*16)+1];	/* Ones part of page numbers */
	EMSMAP *emsmap; 	/* Pointer to EMS mapping info */

	emsmap = sysbuf_ptr(SysInfo->emsmap);
	if (!SysInfo->flags.ems) {
		info_format(info,MEMFMT15);
		ictrtext(info,MSG1144,DWIDTH1);
		return;
	}

	if (!SysInfo->flags.lim4) {
		info_format(info,MEMFMT15);
		iprintf(info,"");
		ictrtext(info,MSG1146,DWIDTH1);
		return;
	}

	/* Initialize the map strings */
	memset(mapstr,UNUSED_CHR,sizeof(mapstr)-1);
	memset(lonum,' ',sizeof(lonum)-1);
	memset(hinum,' ',sizeof(hinum)-1);
	mapstr[sizeof(mapstr)-1] = '\0';
	lonum[sizeof(lonum)-1] = '\0';
	hinum[sizeof(hinum)-1] = '\0';

	/* Fill in EMS frame and mappable pages */
	for (kk = 0; kk < SysInfo->emsparm.mpages; kk++) {
		BYTE c;
		int jj;

		if (SysInfo->emsparm.frame &&
		    emsmap[kk].base >= SysInfo->emsparm.frame &&
		    emsmap[kk].base <	SysInfo->emsparm.frame + 0x1000) {
			c = (BYTE) FRAME_CHR;
		}
		else	c = (BYTE) DOS_CHR;
		jj = emsmap[kk].base / 1024;
		mapstr[jj] = c;
		hinum[jj] = (BYTE)(((emsmap[kk].number / 10) % 10) + '0');
		lonum[jj] = (BYTE)((emsmap[kk].number % 10) + '0');
	}

	/* Strip off excess numbering */
	for (kk = sizeof(hinum)-1; kk > 0; kk--) {
		if (hinum[kk] == hinum[kk-1]) hinum[kk] = ' ';
	}

	/* Fill in ROM, RAM, and video from UMAP list */
	ump = sysbuf_ptr(SysInfo->umap);
	umpend = ump + SysInfo->umaplen;
	while (ump < umpend) {
		char mapchr;

		switch (ump->class) {
		case CLASS_VIDEO:	mapchr = VID_CHR;	break;
		case CLASS_RAM: 	mapchr = RAM_CHR;	break;
		case CLASS_ROM: 	mapchr = ROM_CHR;	break;
		default:
			mapchr = 0;
		}

		if (mapchr) {
			DWORD addr1;
			DWORD addr2;
			int ii;

			addr1 = ump->faddr;
			addr2 = addr1 + ump->length;

			while (addr1 < addr2) {
				ii = (int)(addr1 / 16384L);
				if (mapstr[ii] == UNUSED_CHR) mapstr[ii] = mapchr;
				addr1 += 16384;
			}
		}
		ump++;
	}

	info_color(info,DWIDTH1);
	info_format(info,MEMFMT11);

	iprintf(info,MemFmt11,MSG1147,MSG1148);

	info_color(info,8);

	iprintf(info,MemFmt11,"",mapstr);
	iprintf(info,MemFmt11,"",hinum);
	iprintf(info,MemFmt11,MSG1150,lonum);
	iprintf(info,"");

	info_color(info,DWIDTH1);
	iprintf(info,MemFmt11,MSG1152,MSG1153);

	info_color(info,8);
	iprintf(info,MemFmt11,"",mapstr+40);

	iprintf(info,MemFmt11,"",hinum+40);
	iprintf(info,MemFmt11,MSG1150,lonum+40);
	iprintf(info,"");

	info_color(info,0);
	info_format(info,MEMFMT12);

	use_summ(info,mapstr,sizeof(mapstr)-1,(BYTE)UNUSED_CHR,MSG1157,MemFmt12a,MemFmt12b);
	use_summ(info,mapstr,sizeof(mapstr)-1,(BYTE)DOS_CHR,MSG1158,MemFmt12a,MemFmt12b);
	if (SysInfo->emsparm.frame)
	  iprintf(info,MemFmt12c,FRAME_CHR,MSG1160,
		(DWORD)SysInfo->emsparm.frame,(DWORD)SysInfo->emsparm.frame+0x1000);
	use_summ(info,mapstr,sizeof(mapstr)-1,(BYTE)VID_CHR,MSG1192,MemFmt12a,MemFmt12b);
	use_summ(info,mapstr,sizeof(mapstr)-1,(BYTE)RAM_CHR,MSG1191,MemFmt12a,MemFmt12b);
	use_summ(info,mapstr,sizeof(mapstr)-1,(BYTE)ROM_CHR,MSG1161,MemFmt12a,MemFmt12b);
}

/*
 *	Memory_XMS - build text for Memory / XMS screen
 */

void Memory_XMS(HANDLE info)
{

	if (!SysInfo->flags.xms) {
		info_format(info,MEMFMT15);
		if (SysInfo->xmsparm.flag == 0x81) ictrtext(info,MSG1188,DWIDTH1);
		else ictrtext(info,MSG1162,DWIDTH1);
		return;
	}

	info_color(info,34);
	info_format(info,MEMFMT13);

	iprintf(info,MemFmt13a,MSG1163,
		bcd_num(SysInfo->xmsparm.version / 256),
		NUM_VDECIMAL,
		bcd_num(SysInfo->xmsparm.version & 0xff));
	iprintf(info,MemFmt13a,MSG1164,
		bcd_num(SysInfo->xmsparm.driver / 256),
		NUM_VDECIMAL,
		bcd_num(SysInfo->xmsparm.driver & 0xff));
	iprintf(info,"");
	iprintf(info,MemFmt13b,MSG1168,
			SysInfo->xmsparm.umbtotal / 64);
	iprintf(info,MemFmt13b,MSG1169,
			SysInfo->xmsparm.umbavail / 64);
	iprintf(info,MemFmt13b,MSG1170,
			SysInfo->xmsparm.embtotal);
	iprintf(info,MemFmt13b,MSG1171,
			SysInfo->xmsparm.embavail);
	iprintf(info,"");
	{
		char *text;

		if (SysInfo->xmsparm.hmaexist) {
			if (SysInfo->xmsparm.hmaavail)
				text = MSG1173;
			else
				text = MSG1174;
		}
		else	text = MSG1175;
		iprintf(info,MemFmt13c,MSG1176,text);
	}
	iprintf(info,MemFmt13d,MSG1177,SysInfo->xmsparm.embhand);
	iprintf(info,MemFmt13c,MSG1178,
			SysInfo->xmsparm.a20state ? MSG1179 : MSG1180);

	if (SysInfo->dpmi_ver) {
		iprintf(info,"");
		iprintf(info,MemFmt13a,MSG1194,
			HIBYTE(SysInfo->dpmi_ver),
			NUM_VDECIMAL,
			LOBYTE(SysInfo->dpmi_ver));
		iprintf(info,MemFmt13c,MSG1195,
			SysInfo->dpmi_32bit ? MSG1196 : MSG1197);
	}

}

/*
 *	Memory_Timing - build text for Memory / Timing screen
 */

#define GRAPH_CHR 'Ü'   /* (220) Character for drawing graphs */

void Memory_Timing(HANDLE info)
{
	TIMELIST *tp;		/* Pointer to time list */
	TIMELIST *tpend;	/* Pointer to end of time list */
	WORD low,high;		/* Low/high access times */
	WORD spread;		/* Spread between low and high values */

	info_color(info,DWIDTH1);
	info_format(info,MEMFMT14);

	iprintf(info,MSG1181);
	iprintf(info,MSG1182);

	info_color(info,0);
	iprintf(info,"");

	low = 0xFFFF;
	high = 0;
	tp = sysbuf_ptr(SysInfo->timelist);
	tpend = tp + SysInfo->timelen;
	while (tp < tpend) {
		if (tp->count) {
		  if (tp->count < low) low = tp->count;
		  if (tp->count > high) high = tp->count;
		} /* Count is available */
		tp++;
	}
	if (high == low) high++;

	spread = high - low;

	tp = sysbuf_ptr(SysInfo->timelist);
	while (tp < tpend) {

		int n;
		WORD pct;
		char graph[21];

		if (tp->count) {

		  pct = (WORD) ((((DWORD)tp->count - (DWORD)low) * 100)
							  / (DWORD) spread);
		  n = (int) ((100 - pct) / 5);

		  if (n > 20) n = 20;
		  if (n < 1) n = 1;
		  memset(graph,GRAPH_CHR,n);
		  graph[n] = '\0';

		  iprintf(info, MemFmt14,
			tp->start,
			tp->start / 64,
			tp->length / 64,
			tp->count,
			graph);

		} /* Info was available */
		else {

		  strcpy (graph, MSG1078); /* Unknown */
		  iprintf(info, MemFmt14b,
			tp->start,
			tp->start / 64,
			tp->length / 64,
			MSG1078);

		} /* Not available */

		tp++;

	} /* while not end of timelist */

} /* Memory_Timing () */

/*
 *	simple_summ - do summary of single memory class
 */

long simple_summ(
	UMAP *um_start, 	/* Starting entry in memory map */
	UMAP *um_end,		/* Ending entry in memory map */
	MAPCLASS class) 	/* Which class to summarize */
{
	long count = 0; 	/* Byte count */
	UMAP *ump;		/* Pointer to memory map */

	ump = um_start;
	while (ump != um_end) {
		if (ump->class == class) count += ump->length;
		ump++;
	}
	return count;
}

/*
 *	program_summ - print program summary lines
 */

long program_summ(
	HANDLE info,		/* Control structure */
	UMAP *um_start, 	/* Starting entry in memory map */
	UMAP *um_end,		/* Ending entry in memory map */
	char *fmt)		/* Formatting string */
{
	long count = 0; 	/* Byte count */
	UMAP *ump;		/* Pointer to memory map */

	/* Set all the flags */
	ump = um_start;
	while (ump != um_end) {
		ump->flags.spare = 1;
		ump++;
	}

	/* Summarize programs/environments by program name */
	ump = um_start;
	while (ump != um_end) {
		if (ump->flags.spare &&
		    (ump->class == CLASS_PRGM || ump->class == CLASS_ENV)) {
			long progbytes;
			UMAP *ump2;

			progbytes = 0;
			ump2 = ump;
			while (ump2 != um_end) {
				if ((ump->class == CLASS_PRGM || ump->class == CLASS_ENV) &&
				    strcmp(ump2->name,ump->name) == 0) {
					ump2->flags.spare = 0;
					progbytes += ump2->length;
				}
				ump2++;
			}

			count += progbytes;
			iprintf(info,fmt,ump->name,comma_num(progbytes),KBR(progbytes));
		}
		ump++;
	}
	return count;
}

/*
 *	use_summ - do summary for EMS usage
 */

void use_summ(
	HANDLE info,		/* Control structure */
	BYTE *str,		/* EMS map string */
	int nstr,		/* How many chars in string */
	BYTE chr,		/* Which char we're looking for */
	char *label,		/* Label for this item */
	char *fmt1,		/* Part 1 format */
	char *fmt2)		/* Part 2 format */
{
	int nline;
	int hits;
	int jj,kk;
	DWORD start,end;
	char line[80];

	sprintf(line,fmt1,chr,label);
	nline = strlen(line);
	hits = 0;
	for (jj = 0; jj < nstr; jj++) {
		if (str[jj] == chr) {
			start = (DWORD)jj * 1024;
			for (kk = jj+1; kk < nstr; kk++) {
				if (str[kk] != chr) break;
			}
			end = (DWORD)kk * 1024;
			sprintf(line+strlen(line),fmt2,start,end);

			hits++;
			if (hits >= 3) {
				iprintf(info,line);
				memset(line,' ',nline);
				line[nline] = '\0';
				hits = 0;
			}
			jj = kk-1;
		}
	}
	if (hits > 0) {
		iprintf(info,line);
	}
}

/*
 *	comma_num - format integer number with commas
 */

char *comma_num(
	long num)		/* Number to format */
{
	int nc; 		/* Char count */
	static char temp[50];	/* Scratch text */
				/* ltoa() may return as much as 33 characters,
				   and we need room for commas as well. */

	ltoa(num, temp, 10);
	nc = strlen(temp);
	while (nc > 3) {
		nc -= 3;
		memmove(temp+nc+1, temp+nc,strlen(temp+nc)+1);
		temp[nc] = ','; /* We'll launder it in iprintf() */
	}
	return temp;
}
/* Wed Nov 21 10:44:17 1990 alan:  fix bugs */
/* Mon Nov 26 17:05:54 1990 alan:  rwsystxt and other bugs */
/* Wed Dec 19 17:12:52 1990 alan:  new mapping technique */
/* Sat Mar 09 12:06:12 1991 alan:  fix bugs */
