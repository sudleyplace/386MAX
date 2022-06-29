/*' $Header:   P:/PVCS/MAX/ASQENG/HDW_INFO.C_V   1.3   30 May 1997 14:58:40   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * HDW_INFO.C								      *
 *									      *
 * Formatting routines for hardware screens				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <commfunc.h>		/* Utility functions */
#include <dcache.h>		/* Disk cache functions */
#include <engine.h>		/* Engine definitons */
#include <libtext.h>		/* Localization constants */
#include <pnp.h>		/* Plug and Play definitions */
#include <video.h>		/* Video functions */

#include "info.h"               /* Internal info functions */
#include "sysinfo.h"            /* System info structures / functions */

#define HDW_INFO_C
#include "engtext.h"            /* Text strings */

typedef struct _cmostitles {	/* CMOS titles */
	int first;		/* First byte in range */
	int last;		/* Last byte in range */
	char *title;		/* Title text */
} CMOSTITLES;

/* Titles for CMOS data */
static CMOSTITLES CMOSTitles1[] = {
	/* Titles (mostly) from IBM PC AT Technical Reference,
	   pp. 1-45 & 1-46 */
	0x00, 0x00, MSG3016,
	0x01, 0x01, MSG3017,
	0x02, 0x02, MSG3018,
	0x03, 0x03, MSG3019,
	0x04, 0x04, MSG3020,
	0x05, 0x05, MSG3021,
	0x06, 0x06, MSG3022,
	0x07, 0x07, MSG3023,
	0x08, 0x08, MSG3024,
	0x09, 0x09, MSG3025,
	0x0A, 0x0A, MSG3026,
	0x0B, 0x0B, MSG3027,
	0x0C, 0x0C, MSG3028,
	0x0D, 0x0D, MSG3029,
	0x0E, 0x0E, MSG3030,
	0x0F, 0x0F, MSG3031,
	0x10, 0x10, MSG3032,
	0x11, 0x11, MSG3033,
	0x12, 0x12, MSG3034,
	0x13, 0x13, MSG3035,
	0x14, 0x14, MSG3036,
	0x15, 0x15, MSG3037,
	0x16, 0x16, MSG3038,
	0x17, 0x17, MSG3039,
	0x18, 0x18, MSG3040,
	0, 0, NULL
};

/* This group is only used on non-PS/2 machines */
static CMOSTITLES CMOSTitles2[] = {
	0x19, 0x19, MSG3041,
	0x1A, 0x1A, MSG3042,
	0x1B, 0x2D, MSG3043,
	0x2E, 0x2F, MSG3044,
	0x30, 0x30, MSG3045,
	0x31, 0x31, MSG3046,
	0x32, 0x32, MSG3047,
	0x33, 0x33, MSG3048,
	0x34, 0xFF, MSG3049,
	0, 0, NULL
};

/* This group is only used on PS/2 machines */
static CMOSTITLES CMOSTitles3[] = {
	0x19, 0x31, MSG3050,
	0x32, 0x33, MSG3051,
	0x34, 0x34, MSG3052,
	0x35, 0x35, MSG3053,
	0x36, 0x36, MSG3054,
	0x37, 0x37, MSG3055,
	0x38, 0xFF, MSG3056,
	0, 0, NULL
};

/* Names of the months */
static char *month_name[] = {
	"",
	MSG3058, MSG3059, MSG3060, MSG3061,
	MSG3062, MSG3063, MSG3064, MSG3065,
	MSG3066, MSG3067, MSG3068, MSG3069
};

/* Mouse types */
static char *MouseTypes[] = {
	MSG3250,
	MSG3251,
	MSG3252,
	MSG3253,
	MSG3254,
	MSG3255
};

/* Formats */

/* Summary */
char *HdwFmt1a = "%24s: %s";
char *HdwFmt1b = "%24s: %.0f";
char *HdwFmt1c = "%24s: %02X";
char *HdwFmt1d = "%24s: %d";
char *HdwFmt1e = "%24s: %d, %s";
char *HdwFmt1f = "%22s %c: %s";
char *HdwFmt1g = "%24s: " NATL_NONE;
char *HdwFmt1v = "%24s: %d.%02d";

/* MCA */
char *HdwFmt2a = "     %04X %s";
char *HdwFmt2b = " %2d  %04X %s"; /* %-35.35s */
char *HdwFmt2c = "             %s";
char *HdwFmt2d = "                 %s";

/* Plug and Play */
char *HdwFmt2pa = "   %s";      /* Subsequent line indentation */
char *HdwFmt2pb = ", ";         /* Item separator */
char *HdwFmt2pc = "    >%s"; /* Dependent item */
#define PNP_LINEWRAP	52	/* Where to wrap item listings */

/* Video */
char *HdwFmt3a = "%15s: %s";
char *HdwFmt3b = "%15s: %04X-%04X";

/* Drives */
char *HdwFmt4 = "%-10.10s %d %9.9s    %3d %4d     %3d  %s";

/* Ports */
char *HdwFmt5 = "%27s: %02X";

/* BIOS */
char *HdwFmt6 = "%-22.22s %02X: %s";

/* CMOS */
char *HdwFmt7 = "%-24.24s %02X         %02X";

/* dpl_partition */
char *HdwFmt8 = "%22s %d";
char *HdwFmt9 = "%5d       %02x   %4d  %4d    %c";

/* Local functions */
static void mca_slot(
	HANDLE info,		/* Target list */
	int slot,		/* Slot number */
	MCAID *aid,		/* Adapter ID and POS data */
	SYSBUFH adfh);		/* Handle to adapter info */

static int port_count(char *name,WORD *base,int count,char *string);
static void dpl_partitions(HANDLE info,char *msg,int num,PARTTABLE *table);
char *vga_memsize(		/* Format string for VGA memory size */
	WORD size);		/* Memory size in KB */

void _cdecl bios_item(		/* Format BIOS data items */
	HANDLE info,		/* Handle to info struct */
	char *name,		/* Name of item */
	WORD offset,		/* Offset to item */
	char *dfmt);		/* Data format */

void disp_pnp( HANDLE info );		/* Display all nodes */

/*
 *	Hardware_Summary - build text for Hardware / Summary screen
 */

#pragma optimize ("leg",off)
void Hardware_Summary(HANDLE info)	  /* Control structure */
{
	sysinfo_refresh();

	info_format(info,HDWFMT1);
	info_color(info,25);
	{
		char *classname;

		if (SysInfo->machname)
			classname = sysbuf_ptr(SysInfo->machname);
		else if (SysInfo->flags.pc)
			classname = MSG3070;
		else if (SysInfo->flags.xt)
			classname = MSG3071;
		else if (SysInfo->flags.at) {
			if (SysInfo->cpu.cpu_type == CPU_80386 ||
			    SysInfo->cpu.cpu_type == CPU_80386SX ) {
				classname = MSG3072;
			}
			else if (SysInfo->cpu.cpu_type == CPU_PENTIUM) {
				classname = MSG30P5;
			}
			else if (SysInfo->cpu.cpu_type == CPU_PENTPRO) {
				classname = MSG30P6;
			}
			else if (SysInfo->cpu.cpu_type == CPU_80486 ||
				 SysInfo->cpu.cpu_type == CPU_80486SX) {
				classname = MSG3073;
			}
			else	classname = MSG3074;
		}
		else if (SysInfo->flags.ps2) {
			classname = MSG3075; /* In case of no match */
			switch (SysInfo->biosid.model) {
			case 0xFA:
				classname = MSG3076;
				break;
			case 0xFC:
				switch (SysInfo->biosid.submodel) {
				case 0x04:
					classname = MSG3077;
					break;
				case 0x05:
					classname = MSG3078;
					break;
				case 0x09:
					classname = MSG3076;
					break;
				}
				break;
			case 0xF8:
				switch (SysInfo->biosid.submodel) {
				case 0x0C:
					classname = MSG3079;
					break;
				case 0x04:
				case 0x09:
					classname = MSG3080;
					break;
				case 0x00:
				case 0x01:
					classname = MSG3081;
					break;
				case 0x16:
					classname = MSG3245;
					break;
				case 0x19:
					classname = MSG3247;
					break;
				case 0x1B:
					classname = MSG3248;
					break;
				default:
					classname = MSG3082;
				}
				break;
			}
		}
		else
			classname = MSG3083;

		iprintf( info, HdwFmt1a, MSG3084, classname );
	}
	{
		char temp[16];

		sprintf(temp,"%s %d%c%02d",MSG3128,HIBYTE(SysInfo->dosver),
			NUM_VDECIMAL,LOBYTE(SysInfo->dosver));
		iprintf(info,HdwFmt1a,MSG3085,temp);
	}
	{
		char temp[ 80 ];

		strcpy( temp, cpu_textof( &SysInfo->cpu ) );
		if (SysInfo->cpu.vir_flag) {
			strcat(temp," ");
			strcat(temp,MSG3246);
		}
		iprintf(info,HdwFmt1a,MSG3086,temp);
	}
	if (SysInfo->cpu.family) {

		char szFMS[ 40 ];

		sprintf( szFMS, "%d,%x,%x %.12s", (WORD)SysInfo->cpu.family,
				(WORD)SysInfo->cpu.model,
				(WORD)SysInfo->cpu.stepping,
				SysInfo->cpu.aID );
		iprintf( info, HdwFmt1a, MSG3091C, szFMS );
	}
	{
		char text[30];

		if (!SysInfo->cpu.fpu_bug) {
			strcpy(text,fpu_textof(SysInfo->cpu.fpu_type));
		}
		else	strcpy(text,MSG3087);
		if (SysInfo->cpu.wei_flag) {
			if (SysInfo->cpu.fpu_type) {
				strcat(text,MSG3088);
			}
			else	text[0] = '\0';
			strcat(text,MSG3089);
		}
		iprintf(info,HdwFmt1a,MSG3090,text);
	}

	iprintf(info,HdwFmt1b,MSG3091,SysInfo->mhz);
		/*,SysInfo->mhzcount);*/
	{
		char *text;
		char szPCIVer[ 80 ];

		if (SysInfo->flags.mca) text = MSG3092;
		else if (SysInfo->flags.eisa) text = MSG3093;
		else if (SysInfo->flags.pci) {
			text = MSG309P;
			/* If we have a version display it */
			if (SysInfo->pci_ver != 0xffff) {
				sprintf( szPCIVer, MSG309PV, SysInfo->pci_ver >> 8,
								SysInfo->pci_ver & 0xff );
				text = szPCIVer;
			} /* Display version */
		}
		else text = MSG3094;
		iprintf(info,HdwFmt1a,MSG3095,text);
	}

	iprintf(info,HdwFmt1a,MSG3096,sysbuf_ptr(SysInfo->biosmfr));
	iprintf(info,HdwFmt1a,MSG3097,SysInfo->biosid.date);
	iprintf(info,HdwFmt1c,MSG3098,SysInfo->biosid.model);
	iprintf(info,HdwFmt1c,MSG3099,SysInfo->biosid.submodel);
	iprintf(info,HdwFmt1c,MSG3100,SysInfo->biosid.revision);
	if (SysInfo->biosid.ncrc) {
		char temp[32];

		sprintf(temp,"%04X  %d KB",
			SysInfo->biosid.crc,SysInfo->biosid.ncrc);
		iprintf(info,HdwFmt1a,MSG3101,temp);
	}
	{
		char *text;

		switch (SysInfo->chipset) {
		case CHIPSET_AT386:
			text = MSG3102; break;
		case CHIPSET_NEAT:
			text = MSG3103; break;
		case CHIPSET_NEAT1:
			text = MSG3104; break;
		case CHIPSET_VLSI:
			text = MSG3105; break;
		default:
			text = MSG3106; break;
		}
		iprintf(info,HdwFmt1a,MSG3107,text);
	}
	iprintf(info,HdwFmt1d,MSG3108,
		((SysInfo->biosdata.equip_flag >> 6) & 0x03) + 1);
	iprintf(info,HdwFmt1d,MSG3109,
		SysInfo->biosdata.hf_num);
	if (SysInfo->logdrv > 0) {
		char temp[40];

		sprintf(temp,"%d, %c: %s %c:",
			SysInfo->logdrv,'A',MSG3133,SysInfo->logdrv + 'A' - 1);
		iprintf(info,HdwFmt1a,MSG3110,temp);
	}
	{
		char temp[40];
		char *text = temp;

		switch (SysInfo->dcache) {
		case DCACHE_NONE:
			text = MSG3260;
			break;
		case DCACHE_READ:
			text = MSG3261;
			break;
		case DCACHE_WRITE:
			text = MSG3262;
			break;
		case DCACHE_WRITEDLY:
			sprintf (temp, MSG3265, dcache_dly == 0xffff ? 8.0 :
						dcache_dly / 18.62);
			break;
		case DCACHE_NOWRITE:
			text = MSG3266;
			break;
		default:
			text = NULL;
		}
		if (text) {
			iprintf(info,HdwFmt1a,MSG3259,text);
		}
	}
	if (SysInfo->nCDs) {

		char szTemp[ 40 ];

		if (SysInfo->nCDs > 1) {
			sprintf( szTemp, "%c: - %c:", 'A' + SysInfo->nFirstCD,
				'A' + SysInfo->nFirstCD + SysInfo->nCDs );
		}
		else {
			sprintf( szTemp, "%c:", 'A' + SysInfo->nFirstCD );
		}

		iprintf( info, HdwFmt1a, MSG3110C, szTemp );
	}
	{
		char temp[32];

		sprintf(temp,"%s, %s",
			SysInfo->video[0].name,
			vga_memsize(SysInfo->video[0].osize));
		iprintf(info,HdwFmt1a,MSG3111,temp);
	}
	{
		char temp[32];

		sprintf(temp,"%dx%d, %s",
			SysInfo->video[0].cols,
			SysInfo->video[0].rows,
			SysInfo->video[0].mode);
		iprintf(info,HdwFmt1a,MSG3112,temp);
	}
	{
		char temp[32];
		int count;
		int n;

		n = port_count(MSG3113,SysInfo->biosdata.rs232_base,4,temp);
		iprintf(info,n ? HdwFmt1e : HdwFmt1g, MSG3114,n,temp);
		count = SysInfo->biosid.xbseg ? 3 : 4;
		n = port_count(MSG3115,SysInfo->biosdata.printer_base,
				count,temp);
		iprintf(info,n ? HdwFmt1e : HdwFmt1g, MSG3116,n,temp);
	}

	{
		char *text;

		if (SysInfo->keyboard & 0x02)
			text = MSG3117;
		else
			text = MSG3118;

		iprintf(info,HdwFmt1a,MSG3119,text);
	}

	if (SysInfo->flags.mouse) {
		char temp[32];

		strcpy(temp,MouseTypes[SysInfo->mouse.type]);
		if (SysInfo->mouse.version) {
			sprintf(temp+strlen(temp),", v%d%c%02d",
				HIBYTE(SysInfo->mouse.version),
				NUM_VDECIMAL,
				LOBYTE(SysInfo->mouse.version));
		}
		if (SysInfo->mouse.irq) {
			sprintf(temp+strlen(temp),", IRQ %d",
				SysInfo->mouse.irq);
		}
		iprintf(info,HdwFmt1a,MSG3249,temp);
	}
	else	iprintf(info,HdwFmt1a,MSG3249,MSG3258);

	/* Game Port */
	iprintf(info,HdwFmt1a,MSG3256, SysInfo->flags.game ? MSG3257 : MSG3258);

	if (SysInfo->flags.ems) {
		int majver;
		int minver;
		char temp[32];

		majver = (SysInfo->emsparm.version >> 4) & 0x0f;
		minver = SysInfo->emsparm.version & 0x0f;
		sprintf(temp,"%d%c%d",majver,NUM_VDECIMAL,minver);
		iprintf(info,HdwFmt1a,MSG3120,temp);
	}
	if (SysInfo->flags.cmos) {
		char temp[32];

		iprintf(info,"");

		sprintf(temp,"%02d:%02d",
			bcd_num(SysInfo->cmos[4]),
			bcd_num(SysInfo->cmos[2]));
		iprintf(info,HdwFmt1a,MSG3242,temp);

#ifdef LANG_GR
		sprintf(temp,"%d. %s %02d%02d",
			bcd_num(SysInfo->cmos[7]),
			month_name[bcd_num(SysInfo->cmos[8])],
#else
		sprintf(temp,"%s %d, %02d%02d",
			month_name[bcd_num(SysInfo->cmos[8])],
			bcd_num(SysInfo->cmos[7]),
#endif
			(SysInfo->flags.ps2 ? /* ?mca? */
				bcd_num(SysInfo->cmos[0x37]) : bcd_num(SysInfo->cmos[0x32])),
			bcd_num(SysInfo->cmos[0x09]));
		iprintf(info,HdwFmt1a,MSG3122,temp);
		iprintf(info,"");

		sprintf(temp,"%d KB",
			*(WORD *)(SysInfo->cmos+0x15));
		iprintf(info,HdwFmt1a,MSG3124,temp);

		sprintf(temp,"%d KB",
			*(WORD *)(SysInfo->cmos+0x17));
		iprintf(info,HdwFmt1a,MSG3125,temp);
		iprintf(info,"");

		if (SysInfo->fdrive[0].heads) {
			iprintf(info,HdwFmt1f,MSG3127,'A',
				SysInfo->fdrive[0].text);
		}
		if (SysInfo->fdrive[1].heads) {
			iprintf(info,HdwFmt1f,"",'B',
				SysInfo->fdrive[1].text);
		}
		iprintf(info,"");
		if (SysInfo->hdrive[0].heads) {
			iprintf(info,HdwFmt1f,MSG3132,'1',SysInfo->hdrive[0].text);
		}
		if (SysInfo->hdrive[1].heads) {
			iprintf(info,HdwFmt1f,MSG3132,'2',SysInfo->hdrive[1].text);
		}
	}

	/*SysInfo->flags.mca = 1; for testing */
	if (SysInfo->flags.mca) {
		int k;

		info_format(info,HDWFMT10);
		info_color(info,DWIDTH1);
		iprintf(info,"");
		ictrtext(info,MSG3137,DWIDTH1);

		info_format(info,HDWFMT2);
		iprintf(info,"");
		iprintf(info,MSG3139);
		info_color(info,0);
		iprintf(info,"");
		iprintf(info,HdwFmt2a,SysInfo->mcaid[0].aid,MSG3141);
		for (k = 1; k < MCASLOTS; k++) {
			if (SysInfo->mcaid[k].aid != 0xFFFF) {
				mca_slot(info,k,&SysInfo->mcaid[k],SysInfo->adf[k]);
			}
		}
	}

	/* Plug and Play */
	if (SysInfo->flags.pnp) {

		info_format(info,HDWFMT10);
		info_color(info,DWIDTH1);
		iprintf(info,"");
		ictrtext(info,MSG314P,DWIDTH1);

		info_format(info,HDWFMT2);
		iprintf(info,"");
		iprintf(info, HdwFmt1v, MSG314P1,
			SysInfo->wPnP_ver >> 8, SysInfo->wPnP_ver & 0x0f );
		iprintf( info, HdwFmt1d, MSG314P2, SysInfo->wNumNodes );
		info_color(info,0);
		iprintf(info,"");
		disp_pnp( info );
		iprintf( info, "" );

	} /* Plug and Play */

}
#pragma optimize ("",on)

/*
 *	Hardware_Video - build text for Hardware / Video screen
 */

void Hardware_Video(HANDLE info)	/* Control structure */
{
	WORD k;

	info_format(info,HDWFMT3);
	info_color(info,16);

	for (k = 0; k < SysInfo->nvideo; k++) {
		char temp[32];

		if (k > 0) iprintf(info,"");
		iprintf(info,HdwFmt3a,MSG3143,
			SysInfo->video[k].name);

		if (SysInfo->video[k].acode == ADAPTERID_VGA) {
			if (*SysInfo->sv_vendor) {
				iprintf(info,HdwFmt3a,MSG3161,SysInfo->sv_vendor);
			}
			if (*SysInfo->sv_model) {
				iprintf(info,HdwFmt3a,MSG3162,SysInfo->sv_model);
			}
		}

		iprintf(info,HdwFmt3a,MSG3144,
			vga_memsize(SysInfo->video[k].osize));

		iprintf(info,HdwFmt3a,MSG3145,
			SysInfo->video[k].mode);

		sprintf(temp,"%d x %d",
			SysInfo->video[k].cols,
			SysInfo->video[k].rows);
		iprintf(info,HdwFmt3a,MSG3146,temp);

		if (SysInfo->video[k].graph) {
			iprintf(info,HdwFmt3b,MSG3147,
				SysInfo->video[k].graph,
				SysInfo->video[k].graph+SysInfo->video[k].gsize);
		}
		else {
			iprintf(info,HdwFmt3a,MSG3147,MSG3148);
		}
		iprintf(info,HdwFmt3b,MSG3149,
			SysInfo->video[k].text,
			SysInfo->video[k].text+SysInfo->video[k].tsize);
		if (SysInfo->video[k].rom) {
			iprintf(info,HdwFmt3b,MSG3150,
				SysInfo->video[k].rom,
				SysInfo->video[k].rom+SysInfo->video[k].rsize);
		}
		else {
			iprintf(info,HdwFmt3a,MSG3150,MSG3151);
		}
	}
}

/*
 *	Hardware_Drives - build text for Hardware / Drives screen
 */

void Hardware_Drives(HANDLE info)	 /* Control structure */
{
	int k;

	info_format(info,HDWFMT4);
	info_color(info,DWIDTH1);
	iprintf(info,MSG3153);
	info_color(info,0);
	iprintf(info,"");

	for (k = 0; k < 2; k++) {
		char temp[8];

		if (SysInfo->flags.xt || SysInfo->flags.pc ) strcpy(temp,MSG3158);
		else sprintf(temp,"%3d",SysInfo->fdrive[k].type);
		if (SysInfo->fdrive[k].heads) {
			iprintf(info,HdwFmt4,MSG3156,k+1,
				SysInfo->fdrive[k].text,
				SysInfo->fdrive[k].heads,
				SysInfo->fdrive[k].cyls,
				SysInfo->fdrive[k].sectors,
				temp);
		}
	}

	iprintf(info,"");

	for (k = 0; k < 2; k++) {
		char temp[8];

		if (SysInfo->flags.mca ||
		    SysInfo->flags.xt || SysInfo->flags.pc ) strcpy(temp,MSG3158);
		else sprintf(temp,"%3d",SysInfo->hdrive[k].type);
		if (SysInfo->hdrive[k].heads) {
			iprintf(info,HdwFmt4,MSG3160,k+1,
				SysInfo->hdrive[k].text,
				SysInfo->hdrive[k].heads,
				SysInfo->hdrive[k].cyls,
				SysInfo->hdrive[k].sectors,
				temp);
		}
	}
	if (SysInfo->hdrive[0].heads) {
		dpl_partitions(info,MSG3160,1,SysInfo->hpart0);
	}
	if (SysInfo->hdrive[1].heads) {
		dpl_partitions(info,MSG3160,2,SysInfo->hpart1);
	}
}

/*
 *	Hardware_Ports - build text for Hardware / Ports screen
 */

void Hardware_Ports(HANDLE info)	/* Control structure */
{
	int k;			/* Loop counter */
	int kend;		/* Loop end */

	info_format(info,HDWFMT5);
	info_color(info,28);

	for (k = 0; k < 4; k++) {
		char temp[32];	/* Scratch */

		if (SysInfo->biosdata.rs232_base[k]) {
			sprintf(temp,"%s %s %d %s",MSG3164,MSG3166,k,MSG3167);
			iprintf(info,HdwFmt5,temp,SysInfo->biosdata.rs232_base[k]);
		}
	}
	iprintf(info,"");
	if (SysInfo->biosid.xbseg) kend = 3;
	else kend = 4;
	for (k = 0; k < kend; k++) {
		char temp[32];	/* Scratch */

		if (SysInfo->biosdata.printer_base[k]) {
			sprintf(temp,"%s %s %d %s",MSG3165,MSG3166,k,MSG3167);
			iprintf(info,HdwFmt5,temp,SysInfo->biosdata.printer_base[k]);
		}
	}
}

/*
 *	Hardware_BIOS_Detail - build text for Hardware / BIOS Detail screen
 */

void Hardware_BIOS_Detail(HANDLE info)	    /* Control structure */
{
	info_format(info,HDWFMT6);
	info_color(info,DWIDTH1);
	iprintf(info,MSG3168);
	info_color(info,26);
	iprintf(info,"");

	bios_item(info,MSG3170,0x00,"WWWW");
	if (!SysInfo->biosid.xbseg) {
		bios_item(info,MSG3171,0x08,"WWWW");
	}
	else {
		bios_item(info,MSG3171,0x08,"WWW");
		bios_item(info,MSG3173,0x0E,"W");
	}
	bios_item(info,MSG3174,0x10,"W");
	bios_item(info,MSG3175,0x12,"B");

	bios_item(info,MSG3176,0x13,"W");
	bios_item(info,MSG3177,0x15,"BB");
	bios_item(info,MSG3178,0x17,"BBB");
	bios_item(info,MSG3179,0x1A,"WW");
	bios_item(info,MSG3180,0x1E,"WWWW");
	bios_item(info,MSG3181,0x26,"WWWW");
	bios_item(info,MSG3182,0x2E,"WWWW");
	bios_item(info,MSG3183,0x36,"WWWW");
	bios_item(info,MSG3184,0x3E,"BBBB");
	bios_item(info,MSG3185,0x42,"BBBBBBB");
	bios_item(info,MSG3186,0x49,"B");
	bios_item(info,MSG3187,0x4A,"W");
	bios_item(info,MSG3188,0x4C,"W");
	bios_item(info,MSG3189,0x4E,"W");
	bios_item(info,MSG3190,0x50,"WWWW");
	bios_item(info,MSG3191,0x58,"WWWW");
	bios_item(info,MSG3192,0x60,"BB");
	bios_item(info,MSG3193,0x62,"B");
	bios_item(info,MSG3194,0x63,"W");
	bios_item(info,MSG3195,0x65,"B");
	bios_item(info,MSG3196,0x66,"B");
	bios_item(info,MSG3197,0x67,"P");
	bios_item(info,MSG3198,0x6B,"B");
	bios_item(info,MSG3199,0x6C,"WW");
	bios_item(info,MSG3200,0x70,"B");
	bios_item(info,MSG3201,0x71,"B");
	bios_item(info,MSG3202,0x72,"W");
	bios_item(info,MSG3203,0x74,"B");
	bios_item(info,MSG3204,0x75,"B");
	bios_item(info,MSG3205,0x76,"B");
	bios_item(info,MSG3206,0x77,"B");
	bios_item(info,MSG3207,0x78,"BBBB");
	bios_item(info,MSG3208,0x7C,"BBBB");
	bios_item(info,MSG3209,0x80,"W");
	bios_item(info,MSG3210,0x82,"W");
	bios_item(info,MSG3211,0x84,"B");
	bios_item(info,MSG3212,0x85,"W");
	bios_item(info,MSG3213,0x87,"BB");
	bios_item(info,MSG3214,0x89,"BB");
	bios_item(info,MSG3215,0x8B,"B");
	bios_item(info,MSG3216,0x8C,"BBB");
	bios_item(info,MSG3217,0x8F,"B");
	bios_item(info,MSG3218,0x90,"BB");
	bios_item(info,MSG3219,0x92,"BB");
	bios_item(info,MSG3220,0x94,"BB");
	bios_item(info,MSG3221,0x96,"B");
	bios_item(info,MSG3222,0x97,"B");
	bios_item(info,MSG3223,0x98,"P");
	bios_item(info,MSG3224,0x9C,"P");
	bios_item(info,MSG3225,0xA0,"B");
	bios_item(info,MSG3226,0xA1,"BBBBBBB");
	bios_item(info,MSG3227,0xA8,"P");
}

/*
 *	Hardware_CMOS_Detail - build text for Hardware / CMOS Detail screen
 */

void Hardware_CMOS_Detail(HANDLE info)	    /* Control structure */
{

	if (!SysInfo->flags.cmos) {
		info_format(info,HDWFMT10);
		ictrtext(info,MSG3228,DWIDTH1);
		return;
	}

	info_format(info,HDWFMT7);
	info_color(info,DWIDTH1);
	iprintf(info,MSG3229);
	info_color(info,24);
	{
		int k;
		CMOSTITLES *tp;

		tp = CMOSTitles1;
		for (k = 0; k < sizeof(SysInfo->cmos); k++) {
			if (k > tp->last) {
				tp++;
				if (!(tp->title)) {
					if (!SysInfo->flags.ps2)
						tp = CMOSTitles2;
					else
						tp = CMOSTitles3;
				}
			}

			if ((k % 16) == 0) iprintf(info,"");

			iprintf(info,HdwFmt7,
				tp->title,k,SysInfo->cmos[k]);
		}
	}
}

/*
 *	mca_slot - format text for one MCA bus slot
 */

static void mca_slot(
	HANDLE info,		/* Target list */
	int slot,		/* Slot number */
	MCAID *aid,		/* Adapter ID and POS data */
	SYSBUFH adfh)		/* Handle to adapter info */
{
	if (adfh) {
		WORD kk;
		ADFINFO *ainfo;
		ADFOPTION *opp;

		ainfo = sysbuf_ptr(adfh);

		iprintf(info,HdwFmt2b,slot,aid->aid,ainfo->name);

		opp = sysbuf_ptr(ainfo->foption);
		for (kk = 0; kk < ainfo->noption; kk++,opp = sysbuf_ptr(opp->next)) {
			WORD jj;
			ADFCHOICE *chp;

			chp = sysbuf_ptr(opp->fchoice);
			for (jj = 0; jj < opp->nchoice; jj++,chp = sysbuf_ptr(chp->next)) {
				int k2;

				for (k2 = 0; k2 < 4; k2++) {
					if (*(chp->pos[k2]) &&
					    !pos_test(aid->pos[k2],chp->pos[k2])) break;
				}
				if (k2 >= 4) {
					iprintf(info,HdwFmt2c,opp->name);
					iprintf(info,HdwFmt2d,chp->name);
					break;
				}
			}
		}
	} /* (rtn == 0) */
	else {
		iprintf(info,HdwFmt2b,slot,aid->aid,MSG3235);
	}
}

/*
 *	port_count - count the number of active ports
 */

static int port_count(
	char *name,		/* Base name of ports (COM or LPT) */
	WORD *base,		/* Port address list */
	int count,		/* How many items */
	char *string)		/* Formatted string returned */
{
	int k;			/* Loop counter */
	int n;			/* Port counter */
	char num[4];		/* Scratch */

	*string = '\0';
	memset(num,0,sizeof(num));
	n = 0;
	for (k = 0; k < count; k++,base++) {
		if (*base) {
			if (k > 0) strcat(string,"/");
			strcat(string,name);
			num[0] = (char)(k + '1');
			strcat(string,num);
			n++;
		}
	}
	return n;
}

/*
 * Display partition table
 */

static void dpl_partitions(
	HANDLE info,		/* Target list */
	char *msg,			/* Base text for message */
	int num,			/* Drive number */
	PARTTABLE *table)		/* Partition table data */
{
	int k;

	info_format(info,HDWFMT8);
	info_color(info,DWIDTH1);
	iprintf(info,"");
	iprintf(info,HdwFmt8,msg,num);
	iprintf(info,MSG3239);
	iprintf(info,"");
	info_format(info,HDWFMT9);
	info_color(info,0);
	for (k = 0 ; k <= 3 ; k++) {
		int	low_cyl,high_cyl;
		char	active;
		PARTTABLE *tp;

		tp = table+k;
		low_cyl = (tp->start_cyl & 0xff) + ((tp->start_sec & 0xc0) << 2);
		high_cyl = (tp->last_cyl & 0xff) + ((tp->last_sec & 0xc0) << 2);

		if ((tp->bootind & 0xff) == 0x80) active = 'A';
		else				  active = 'N';

		iprintf(info,HdwFmt9,
			k+1,tp->sysind & 0xff,
			low_cyl,high_cyl,
			active);
	}
}

void _cdecl bios_item(		/* Format BIOS data items */
	HANDLE info,		/* Handle to info struct */
	char *name,		/* Name of item */
	WORD offset,		/* Offset to item */
	char *dfmt)		/* Data format */
{
	char *bp;
	char *tp;
	char temp[40];

	bp = (char *)&SysInfo->biosdata + offset;
	tp = temp;
	while (*dfmt) {
		switch (toupper(*dfmt)) {
		case 'B':       /* BYTE */
			sprintf(tp," %02X",*(BYTE *)bp);
			tp += strlen(tp);
			bp += sizeof(BYTE);
			break;

		case 'W':       /* WORD */
			sprintf(tp," %04X",*(WORD *)bp);
			tp += strlen(tp);
			bp += sizeof(WORD);
			break;

		case 'P':       /* Pointer */
			sprintf(tp," %Fp",*(char far * *)bp);
			tp += strlen(tp);
			bp += sizeof(char far *);
			break;
		}
		dfmt++;
	}
	iprintf(info,HdwFmt6,name,offset,temp);
}

char *vga_memsize(	/* Format string for VGA memory size */
	WORD size)		/* Memory size in KB */
{
	static char text[32];

	switch (size) {
	case 0xffff:	/* (-1) Unknown or error */
		strcpy(text,MSG3263);
		break;
	case 257:	/* 256k or better */
		strcpy(text,MSG3264);
		break;
	default:	/* Specific size */
		sprintf(text,"%u KB",size);
		break;
	}
	return text;
}

/* Format small Plug and Play resource */
void disp_pnp_small( char *pszText, LPPNPSMALLRES lpS ) {

	*pszText = '\0';

	/* If structure empty, nothing to do */
	if (!lpS->Length) return;

	switch (lpS->Name) {

		case PnP_SRES_NAME_VER:
			sprintf( pszText, MSGP_VER, lpS->Ver.VerMajor,
				lpS->Ver.VerMinor );
			break;

		case PnP_SRES_NAME_IRQ:
			if (lpS->IRQ.wMaskBits == 0 || !lpS->Length) return;
			strcpy( pszText, MSGP_IRQ );
			{
				int nBit;

				for (nBit = 0; nBit < 16; nBit++) {
					if (lpS->IRQ.wMaskBits & (0x01 << nBit)) {
						sprintf( &pszText[ strlen( pszText ) ], " %d", nBit );
					}
				}
				if (lpS->Length >= 3) {
					if (lpS->IRQ.HighLevel) strcat( pszText, MSGP_IRQHI );
					if (lpS->IRQ.LowLevel) strcat( pszText, MSGP_IRQLO );
				} /* optional flags are included in structure */
				/* all else is edge-sensitive */
			}
			break;

		case PnP_SRES_NAME_DMA:
			if (lpS->DMA.Mask == 0) return;
			strcpy( pszText, MSGP_DMACH );
			{
				int nBit;

				for (nBit = 0; nBit < 8; nBit++) {
					if (lpS->DMA.Mask & (0x01 << nBit)) {
						sprintf( &pszText[ strlen( pszText ) ], " %d", nBit );
					}
				}
				if (lpS->DMA.BusMaster) strcat( pszText, MSGP_BUS );

				if (!lpS->DMA.PreferredTransfer) strcat( pszText, MSGP_8BITONLY );
				if (lpS->DMA.Mode) strcat( pszText, MSGP_EISADMA );
			}
			break;

		case PnP_SRES_NAME_IO:
			if (lpS->IO.wRangeMinBase != lpS->IO.wRangeMaxBase) {
			  sprintf( pszText, MSGP_IORANGEALIGN,
				lpS->IO.RangeLen,
				lpS->IO.wRangeMinBase,
				lpS->IO.wRangeMaxBase,
				lpS->IO.BaseAlign,
				lpS->IO.Addr16 ? MSGP_IO16BIT : "" );
			}
			else {
			  sprintf( pszText, MSGP_IO, lpS->IO.wRangeMinBase );
			  if (lpS->IO.RangeLen) {
				sprintf( &pszText[ strlen( pszText ) ],
					"-%x", lpS->IO.wRangeMaxBase +
						lpS->IO.RangeLen );
			  }
			  if (lpS->IO.Addr16) {
				strcat( pszText, MSGP_IO16BIT );
			  }
			}
			break;

		case PnP_SRES_NAME_IOF:
			if (lpS->FixedIO.RangeLen > 1) {
				sprintf( pszText, MSGP_IORANGE,
					lpS->FixedIO.wRangeBase,
					lpS->FixedIO.wRangeBase +
						lpS->FixedIO.RangeLen - 1 );
			} /* Multiple ports */
			else {
				sprintf( pszText, MSGP_IO,
					lpS->FixedIO.wRangeBase );
			} /* Single port */
			break;

		default:
			return;

	} /* switch() */

} /* disp_pnp_small() */

/* Decode memory flag bits */
char *memory_bits( LPPNPM32F lpM ) {

	static char szRet[ 80 ];

	szRet[ 0 ] = '\0';

	if (!lpM->Writeable) strcat( szRet, MSGP_MEMROM );
	if (lpM->ShadowROM) strcat( szRet, MSGP_MEMSHADOW );
	if (lpM->ExpansionROM) strcat( szRet, MSGP_MEMEXPAND );
	if (lpM->Cacheable) strcat( szRet, MSGP_MEMCACHE );

	return szRet;

} /* memory_bits() */

/* Format large Plug and Play resource */
void disp_pnp_large( char *pszText, LPPNPLARGERES lpL ) {

	*pszText = '\0';

	switch (lpL->Name) {

		case PnP_LRES_NAME_M16:
			if (!lpL->M16.wLength) break;
			sprintf( pszText, MSGP_MEM16,
				lpL->M16.wMinBaseAddr, lpL->M16.wMaxBaseAddr,
				lpL->M16.wLength, lpL->M16.wAlign,
				memory_bits( &lpL->M32F ) );
			break;

		case PnP_LRES_NAME_IDA:
			sprintf( pszText, MSGP_ID, lpL->Data );
			break;

		case PnP_LRES_NAME_M32:
			if (!lpL->M32.dwLength) break;
			sprintf( pszText, MSGP_MEM32,
				lpL->M32.dwMinBaseAddr, lpL->M32.dwMaxBaseAddr,
				lpL->M32.dwLength, lpL->M32.dwAlign,
				memory_bits( &lpL->M32F ) );
			break;

		case PnP_LRES_NAME_M32F:
			if (!lpL->M32F.dwLength) break;
			sprintf( pszText, MSGP_MEM32F,
				lpL->M32F.dwBaseAddr,
				lpL->M32F.dwBaseAddr + lpL->M32F.dwLength - 1,
				memory_bits( &lpL->M32F ) );
			break;

		default:
			return;

	} /* switch () */

} /* disp_pnp_large() */

/* Decode packed EISA ID */
/* IDs are packed as follows (big-endian): */
/* x1111122 22233333 4444444444444444 */
/* Thus paIn references an array of bits */
void decode_eisa( char *pszOut, unsigned char far *paIn ) {

	typedef struct tagEISAbits {
		DWORD
			  dw4:16,
			  dw3:5,
			  dw2:5,
			  dw1:5,
			  rsvd:1;
	} EISABITS;
	union {
		EISABITS e;
		unsigned char pa[ 4 ];
		DWORD dw;
	} u;

	/* Convert to little-endian */
	u.pa[ 0 ] = paIn[ 3 ];
	u.pa[ 1 ] = paIn[ 2 ];
	u.pa[ 2 ] = paIn[ 1 ];
	u.pa[ 3 ] = paIn[ 0 ];

	pszOut[ 0 ] = (char) ('@' + u.e.dw1);
	pszOut[ 1 ] = (char) ('@' + u.e.dw2);
	pszOut[ 2 ] = (char) ('@' + u.e.dw3);

	sprintf( &pszOut[ 3 ], "%04X", u.e.dw4 );

} /* decode_eisa */

/* Display Plug and Play data for all nodes */
void disp_pnp( HANDLE info ) {

	/* Get address of data */
	BYTE __far *lpBuff = sysbuf_ptr( SysInfo->pNodeList );
	BYTE LastNode = 0xff;
	int nBuffOff;
	LPPNPSMALLRES lpS;
	char szNode[ 128 ];
	char szNode2[ 128 ];
	int IsDependent;
	char __far *lpDesc = NULL;


#define lpD	((LPPNP_DEVNODE)lpBuff)
#define SPACE11 "           "

	szNode[ 0 ] = '\0';

	if (SysInfo->ppszPnPDesc) {
		lpDesc = sysbuf_ptr( SysInfo->ppszPnPDesc );
	} /* Descriptions were read successfully */

	/* Walk the list until we find a length of 0 */
	for ( ; ; lpBuff += lpD->wLen) {

		/* See if we need to display data on this node */
		if (lpD->Node != LastNode) {

			if (szNode[ 0 ]) {
				iprintf( info, IsDependent ? HdwFmt2pc : HdwFmt2pa, szNode );
			}

			IsDependent = 0;

			sprintf( szNode, "%2d ", lpD->Node );
			decode_eisa( &szNode[ 3 ], lpD->paID );
			strcat( szNode, " " );
			if (lpD->Rem) strcat( szNode, MSGP_NREMOVABLE );
			if (lpD->Dock) strcat( szNode, MSGP_NDOCKING );
			if (lpD->IPL) strcat( szNode, MSGP_NBOOTABLE );
			if (lpD->Inp) strcat( szNode, MSGP_NINPUT );
			if (lpD->Out) strcat( szNode, MSGP_NOUTPUT );
			if (lpDesc && lpDesc[ lpD->Node * MAXPNP_DESC ]) {
				int nSpace = sizeof( szNode ) - strlen( szNode ) - 4;
				char szFmt[ 20 ];

				sprintf( szFmt, " %%.%ds", nSpace );
				sprintf( &szNode[ strlen( szNode ) ],
						szFmt, &lpDesc[ lpD->Node * MAXPNP_DESC ] );

			} /* Descriptions exist */
			LastNode = lpD->Node;

			iprintf( info, "%s", szNode );
			szNode[ 0 ] = '\0';

		} /* Display node data */
		else {
			IsDependent = 0;
		}

		if (szNode[ 0 ]) {
			iprintf( info, HdwFmt2pa, szNode );
			szNode[ 0 ] = '\0';
		}


		if (lpD->s.Large) {
			IsDependent = 0;
			disp_pnp_large( szNode2, &lpD->l );
			nBuffOff = lpD->l.wLength + 3;
		}
		else {
			if (lpD->s.Name == PnP_SRES_NAME_SDF) {
				IsDependent = 1;
			} /* Starting dependent function */

			disp_pnp_small( szNode2, &lpD->s );
			nBuffOff = lpD->s.Length + 1;
		}

		if (szNode[ 0 ]) {
			if (strlen( szNode ) + 2 + strlen( szNode2 ) < PNP_LINEWRAP) {
				strcat( szNode, HdwFmt2pb );
				strcat( szNode, szNode2 );
			}
			else {
				iprintf( info, IsDependent ? HdwFmt2pc : HdwFmt2pa, szNode );
				strcpy( szNode, szNode2 );
			}
		}
		else {
			strcpy( szNode, szNode2 );
		}

		/* Display remaining entries */
		while (((int)(nBuffOff + PNP_DEVNODE_BASESIZE) < (int)(lpD->wLen)) || !lpD->wLen) {

			WORD wLen;

			/* Check for end of sub-list */
			if (!lpD->paRest[ nBuffOff ]) {
				break;
			} /* end */

			lpS = (LPPNPSMALLRES)(&lpD->paRest[ nBuffOff ]);

			if (lpS->Large) {
				disp_pnp_large( szNode2, (LPPNPLARGERES)lpS );
				/* Add length of data + type + length word */
				wLen = ((LPPNPLARGERES)lpS)->wLength + 3;
			}
			else {
				if (lpS->Name == PnP_SRES_NAME_SDF) {
					if (szNode[ 0 ]) {
						iprintf( info, IsDependent ? HdwFmt2pc : HdwFmt2pa, szNode );
						szNode[ 0 ] = '\0';
					} /* Flush out previous stuff */
					IsDependent = 1;
				} /* Starting dependent function */

				disp_pnp_small( szNode2, lpS );
				/* Add length of data + length / type byte */
				wLen = lpS->Length + 1;
			}

			nBuffOff += wLen;

			/* Nothing to add */
			if (!szNode2[ 0 ]) continue;

			if (szNode[ 0 ]) {
				if (strlen( szNode ) + 2 + strlen( szNode2 ) < PNP_LINEWRAP) {
					strcat( szNode, HdwFmt2pb );
					strcat( szNode, szNode2 );
				}
				else {
					iprintf( info, IsDependent ? HdwFmt2pc : HdwFmt2pa, szNode );
					strcpy( szNode, szNode2 );
				}
			}
			else {
				strcpy( szNode, szNode2 );
			}

		}

		/* Check for end of list */
		if (!lpD->wLen) break;

	} /* for all nodes */

	if (szNode[ 0 ]) {
		iprintf( info, IsDependent ? HdwFmt2pc : HdwFmt2pa, szNode );
	} /* Something's left */

	/* If undefined, do nothing */

} /* disp_pnp() */

/* Wed Nov 21 10:44:29 1990 alan:  fix bugs */
/* Mon Nov 26 17:05:38 1990 alan:  rwsystxt and other bugs */
/* Thu Nov 29 21:57:34 1990 alan:  fix bugs */
/* Wed Dec 19 17:12:56 1990 alan:  new mapping technique */
/* Thu Dec 20 07:45:07 1990 alan:  fix bug */
/* Wed Dec 26 13:21:58 1990 alan:  fix bugs */
/* Wed Mar 13 21:04:42 1991 alan:  fix bugs */
/* Thu Mar 28 12:39:48 1991 alan:  fix bugs */
/* Thu Mar 28 21:58:29 1991 alan:  fix bugs */
