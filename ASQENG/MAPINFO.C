/*' $Header:   P:/PVCS/MAX/ASQENG/MAPINFO.C_V   1.2   02 Jun 1997 14:40:04   BOB  $ */
/******************************************************************************
 *										  *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.			  *
 *										  *
 * MAPINFO.C									  *
 *										  *
 * Functions for building a memory map						  *
 *										  *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <dos.h>

#include "testmem.h"            /* Memory tester function */
#include "sysinfo.h"            /* System info structures */
#include "mapinfo.h"            /* Map info functions */
#include "qtas.h"               /* Imports from Qualitas */
#include <commfunc.h>		/* Utility functions */

#define MAPINFO_C
#include "engtext.h"            /* Text strings */

#ifdef MAPINFO_DBG
#define XWORDHI(v)	(WORD) (((DWORD) v) >> 16)
#define XWORDLO(v)	(WORD) (((DWORD) v) & 0x0000ffffL)
void _cdecl do_intmsg(char *format,...); /* Print intermediate message */
#endif

/* Local functions */
void map_lowmem(GLIST *umlist);
void map_highmem(
	GLIST *umlist,	/* Pointer to map list */
	MACINFO *info,	/* Pointer to mac info */
	int ninfo); /* How many items */
void map_video(GLIST *umlist);
void map_sysrom(GLIST *umlist);
void map_roms(GLIST *umlist);
void map_flexroms(GLIST *umlist);
void find_holes(GLIST *umlist);
void map_holes(GLIST *umlist);
void map_extra(GLIST *umlist);
void map_dd(GLIST *umlist);
void map_dosdata(GLIST *umlist);
void map_ints(GLIST *umlist);
void map_zeroes(GLIST *umlist);
void map_shortitems(GLIST *umlist);

int _cdecl umcmp(const void *p1,const void *p2);
void fix_overlap(GLIST *umlist);
BOOL item_overlap(GLIST *umlist,UMAP *ump1,UMAP *ump2);
char *bits_on(WORD value);

#ifdef MAPINFO_DBG
void dump_umlist (GLIST *um)
{
	UMAP *ump;		/* Pointer to map entry */
	static instance = 0;

	do_intmsg ("dump_umlist[%d]\n", ++instance);
	for (ump = glist_head(um); ump; ump = glist_next (um,ump)) {
	 do_intmsg ("%-20s: class=%2d, addr=%04x:%04x, len=%6lu, layer=%d, frag=%d\n", ump->name, ump->class, XWORDHI(ump->saddr), XWORDLO(ump->saddr), ump->length, ump->layer, ump->flags.frag);
	}

}
#endif

/*
 *	make_umap - Make unified memory map list
 */

void make_umap(BOOL snap)	/* TRUE if reading snapshot file */
{
	DWORD top_mem;		/* Flat addr for top of low memory */
	DWORD top_dos;		/* Flat addr for top of DOS memory */
	DWORD xb_addr;		/* Flat addr for Extended BIOS */
	UMAP item;		/* Scratch UMAP item */
	GLIST umlist;		/* Working copy of map list */

	glist_init(&umlist,GLIST_ARRAY,sizeof(UMAP),4*sizeof(UMAP));

	/* Part I:	Low DOS */

	memset(&item,0,sizeof(item));

	/* First item:	Interrupt vectors */
	strcpy(item.name,MSG5001);
	item.class = CLASS_DOS;
	item.faddr = 0;
	item.saddr = 0;
	item.length = 4*256;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Second item:  BIOS Data - segment 40h */
	strcpy(item.name,MSG5002);
	item.saddr = FAR_PTR(0x40,0);
	item.faddr = FLAT_ADDR(item.saddr);
	item.length = 0x10 * 16;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Third item:	System Data - segments 50h & 60H */
	strcpy(item.name,MSG5003);
	item.saddr = FAR_PTR(0x50,0);
	item.faddr = FLAT_ADDR(item.saddr);
	item.length = 0x20 * 16;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Fourth item:  IBMBIO */
	strcpy(item.name,SysInfo->ioname);
	item.faddr = SysInfo->io_start;
	item.saddr = SEG_ADDR(item.faddr);
	item.length = SysInfo->dos_start - SysInfo->io_start;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Fifth item: IBMDOS */
	strcpy(item.name,SysInfo->dosname);
	item.faddr = SysInfo->dos_start;
	item.saddr = SEG_ADDR(item.faddr);
	item.length = SysInfo->dev_start - SysInfo->dos_start;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Sixth item:	Device Drivers */
	strcpy(item.name,MSG5004);
	item.faddr = SysInfo->dev_start;
	item.saddr = SEG_ADDR(item.faddr);
	item.length = SysInfo->data_start - SysInfo->dev_start;
	item.class = CLASS_DEV;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Seventh item:  DOS Files/Buffers */
	strcpy(item.name,MSG5005);
	item.faddr = SysInfo->data_start;
	item.saddr = SEG_ADDR(item.faddr);
	item.length = SysInfo->data_end - SysInfo->data_start;
	item.class = CLASS_DOS;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

	/* Bring in stuff rom the qtas low map */
	map_lowmem(&umlist);

	top_dos = (DWORD)SysInfo->biosdata.memory_size * 1024;
	top_mem = 0xA0000;
	xb_addr = (DWORD)SysInfo->biosid.xbseg * 16;
	if (xb_addr >= top_dos && xb_addr < top_mem) top_mem = xb_addr;

	if (SysInfo->biosdata.memory_size < 640) {
		/* Map Unused mem between end of DOS and 640k */

		if (top_dos < top_mem) {
			/* Map Unused mem between end of DOS and 640k */
			memset(&item,0,sizeof(item));
			strcpy(item.name,MSG5006);
			item.faddr = top_dos;
			item.saddr = SEG_ADDR(item.faddr);
			item.length = top_mem - item.faddr;
			item.class = CLASS_NOTINST;
			item.layer = 3;
			glist_new(&umlist,&item,sizeof(item));
		}
	}

	/* Part II:  High DOS */

	/* Map the video adapter(s) RAM */
	map_video(&umlist);

	/* Map on-card ROMs */
	map_roms(&umlist);
	map_flexroms(&umlist);

	/* Map Extended BIOS, if any */
	if (SysInfo->biosid.xbseg) {
		memset(&item,0,sizeof(item));
		strcpy(item.name,MSG5007);
		item.faddr = xb_addr;
		item.saddr = SEG_ADDR(item.faddr);
		if (item.faddr > 0xA0000) item.flags.high = TRUE;
		item.length = SysInfo->biosid.xbsize * 1024;
		item.class = CLASS_DOS;
		item.layer = 3;
		glist_new(&umlist,&item,sizeof(item));
	}

	/* Map the EMS page frame (if any) */
	if (SysInfo->flags.ems && SysInfo->emsparm.frame) {
		memset(&item,0,sizeof(item));
		strcpy(item.name,MSG5008);
		item.saddr = FAR_PTR(SysInfo->emsparm.frame,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = 64*1024L;
		if (item.faddr >= 0xA0000) item.flags.high = TRUE;
		item.class = CLASS_EMS;
		item.layer = 5;
		glist_new(&umlist,&item,sizeof(item));
	}
#if 0	/* This is wrong, but I don't know what to replace it with */
	/* Map ROM Basic if a Real IBM, but not a PS/2 */
	if ((SysInfo->biosid.bus_flag & 1) && !SysInfo->flags.ps2) {
		memset(&item,0,sizeof(item));
		strcpy(item.name,MSG5043);
		item.faddr = 0xE0000;
		item.saddr = SEG_ADDR(item.faddr);
		item.flags.high = TRUE;
		item.length = 0x10000;
		item.class = CLASS_ROM;
		item.layer = 1;
		glist_new(&umlist,&item,sizeof(item));
	}
#endif
	/* Map the System ROM */
	memset(&item,0,sizeof(item));
	strcpy(item.name,MSG5020);
	item.saddr = FAR_PTR(SysInfo->romseg,0);
	item.faddr = FLAT_ADDR(item.saddr);
	item.length = (long)SysInfo->romsize * 16;
	item.flags.high = TRUE;
	item.class = CLASS_ROM;
	item.layer = 1;
	glist_new(&umlist,&item,sizeof(item));

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 1 */
#endif

	/* Bring in stuff from the qtas high map */
	map_highmem(&umlist,sysbuf_ptr(SysInfo->highdos),SysInfo->nhighdos);
	map_highmem(&umlist,sysbuf_ptr(SysInfo->highload),SysInfo->nhighload);

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 2 */
#endif

	/* Bring in device drivers */
	map_dd(&umlist);

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 3 */
#endif

	/* Bring in DOS data */
	map_dosdata(&umlist);

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 4 */
#endif

	/* Bring in extra items */
	map_extra(&umlist);

	/* Sort the map */
	glist_sort(&umlist,umcmp);

	/* Diagnostics */
	/*engine_debug(1,MSG5009);*/

	/* Make corrections for overlapping blocks */
	fix_overlap(&umlist);

	/* Sort the map again */
	glist_sort(&umlist,umcmp);

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 5 */
#endif

	/* Zap any zero length entries */
	map_zeroes(&umlist);

	/* Merge any short items */
	map_shortitems(&umlist);

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 6 */
#endif

	/* Fill in any remaining holes */
	if (snap)
		map_holes(&umlist);
	else
		find_holes(&umlist);


	/* Build the interrupt map */
	map_ints(&umlist);

	/*engine_debug(1,MSG5010);*/

#ifdef MAPINFO_DBG
	dump_umlist(&umlist);	/* 7 */
#endif

	/* Now move the whole thing to the sysinfo buffer */
	sysbuf_glist(&umlist,sizeof(UMAP),&SysInfo->umap,&SysInfo->umaplen);
	glist_purge(&umlist);	/* bye-bye */
}

/*
 *	map_lowmem - build map for low DOS memory
 */

void map_lowmem(
	GLIST *umlist)		/* Pointer to map list */
{
	UMAP item;	/* One memory map item */
	MACINFO *mp;	/* Pointer to MAC info entry */
	MACINFO *mpend; /* Pointer to end of MAC info */
	UMAP *lastavail; /* Pointer to last UMAP item if it was an -Available- */

	lastavail = NULL;
	mp = sysbuf_ptr(SysInfo->lowdos);
	mpend = mp + SysInfo->nlowdos;
	for (; mp < mpend; mp++) {
		memset(&item,0,sizeof(item));
		item.saddr = FAR_PTR(mp->start,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = (long)(mp->size + 1) * 16;

		switch (mp->type) {
		case MACTYPE_DOS:
		case MACTYPE_DRVRS:
		case MACTYPE_SUBSEG:
			/* Already processed */
			break;
		case MACTYPE_CMDCOM:
		case MACTYPE_PRGM:
		case MACTYPE_DD:
			if (SysInfo->psp && mp->owner == SysInfo->psp) {
				/* Blocks owned by our PSP count as available */
				item.class = CLASS_AVAIL;
				strcpy(item.name,MSG5011);
			}
			else if (mp->type == MACTYPE_CMDCOM && !(*mp->name))	/* COMMAND.COM */
				strcpy(item.name,SysInfo->comname);
			else					/* Program name */
				strcpy(item.name,mp->name);

			if (*mp->text) {
				item.class = CLASS_ENV;
				strcpy(item.text,mp->text);
			}
			else {
				item.class = CLASS_PRGM;
			}
			break;

		case MACTYPE_CURRENT:
			/* These are counted with -Available- */
		case MACTYPE_AVAIL:
			item.class = CLASS_AVAIL;
			strcpy(item.name,MSG5011);
			break;

		case MACTYPE_RAMROM:
			/* This shouldn't actually appear in low memory */
			strcpy(item.name,MSG5012);
			break;

		case MACTYPE_UMB:
			/* This shouldn't actually appear in low memory */
			strcpy(item.name,MSG5013);
			break;

		default:
			strcpy(item.name,MSG5014);
			break;
		}
		if (*item.name) {
			if (item.class == CLASS_AVAIL && lastavail) {
				/* Merge adjacent -Available- items */
				lastavail->length += item.length;
			}
			else {
				item.layer = 3;
				lastavail = glist_new(umlist,&item,sizeof(item));
				if (item.class != CLASS_AVAIL) lastavail = NULL;
			}
		}
	}
}

/*
 *	map_highmem - build map for high DOS memory
 */

void map_highmem(
	GLIST *umlist,	/* Pointer to map list */
	MACINFO *info,	/* Pointer to mac info */
	int ninfo)	/* How many items */
{
	UMAP item;	/* One memory map item */
	UMAP *lastitem; /* Last memory map item */
	MACINFO *mp;	/* Pointer to MAC info entry */
	MACINFO *mpend; /* Pointer to end of MAC info */
	DWORD loadaddr; /* Where our .EXE begins */

	if (!info || ninfo < 1) return;

	loadaddr = 0;
	lastitem = NULL;
	mp = info;
	mpend = mp + ninfo;
	for (; mp < mpend; mp++) {
		memset(&item,0,sizeof(item));
		item.flags.high = TRUE;
		item.saddr = FAR_PTR(mp->start,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = (long)(mp->size + 1) * 16;

#ifdef MAPINFO_DBG
		do_intmsg ("mp->type=%d, start=%04x, size=%04x, ownr=%04x, n=\"%s\", t=\"%s\", \n", mp->type,
			mp->start, mp->size, mp->owner, mp->name, mp->text);
#endif
		switch (mp->type) {
		case MACTYPE_DRVRS:
		case MACTYPE_CURRENT:
			/* These don't happen here */
			break;

		case MACTYPE_CMDCOM:
			if (!(*mp->name)) { /* COMMAND.COM */
				strcpy(item.name,SysInfo->comname);
				goto MACPRGM_2;
			} /* Nameless command processor */
			else			/* Program name */
				goto MACPRGM_1;

		case MACTYPE_DD:
			if (mp->type == MACTYPE_DD && mp->size == 0) {
				/* Special case for nested device drivers */
				item.length = 0;
			}
		case MACTYPE_PRGM:
MACPRGM_1:
			strcpy(item.name,mp->name);
MACPRGM_2:
			if (*mp->text) {
				item.class = CLASS_ENV;
				strcpy(item.text,mp->text);
			}
			else {
				item.class = CLASS_PRGM;
			}
			break;

		case MACTYPE_AVAIL:
			item.class = CLASS_AVAIL;
			strcpy(item.name,MSG5015);
			break;

		case MACTYPE_RAMROM:
			if (lastitem) {
				/* Merge RAM or ROM entry with previous item */
				lastitem->length += 16;
			}
			else {
				/* This should never happen */
				item.class = CLASS_RAMROM;
				item.length = 16;
				strcpy(item.name,MSG5024);
			}
			break;

		case MACTYPE_UMB:
			/* XMS Upper Memory Block */
			item.class = CLASS_UMB;
			strcpy(item.name,MSG5016);
			break;

		case MACTYPE_SUBSEG:
			item.class = CLASS_SUBSEG;
			strcpy(item.name,mp->name);
			break;

		default:
			strcpy(item.name,MSG5017);
			break;
		}
		if (*item.name) {
			item.layer = 3;
			lastitem = glist_new(umlist,&item,sizeof(item));
		}
	}
}

/*
 *	map_video - build map for video memory
 */

void map_video(
	GLIST *umlist)	/* Pointer to map list */
{
	int k;
	UMAP item;	/* One memory map item */		/* Scratch UMAP item */

	/* Fill in the mappings for video adapters */

	memset(&item,0,sizeof(item));
	item.flags.high = TRUE;
	item.class = CLASS_VIDEO;

	for (k = SysInfo->nvideo-1; k >= 0; k--) {
		strcpy(item.name,MSG5018);
		strcat(item.name,SysInfo->video[k].name);
		strcat(item.name,")");
		item.saddr = FAR_PTR(SysInfo->video[k].text,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = (long)SysInfo->video[k].tsize * 16;
		item.layer = 1;
		glist_new(umlist,&item,sizeof(item));

		if (SysInfo->video[k].graph) {
			strcpy(item.name,MSG5018);
			strcat(item.name,SysInfo->video[k].name);
			strcat(item.name,")");
			item.saddr = FAR_PTR(SysInfo->video[k].graph,0);
			item.faddr = FLAT_ADDR(item.saddr);
			item.length = (long)SysInfo->video[k].gsize * 16;
			item.layer = 1;
			glist_new(umlist,&item,sizeof(item));
		}
	}
}

/*
 *	map_roms - build map for on-card roms
 */

void map_roms(
	GLIST *umlist)	/* Pointer to map list */
{
	ROMITEM *romitem;	/* Pointer to ROM list item */
	ROMITEM *romend;	/* Pointer to end of ROM list */
	UMAP item;		/* One memory map item */

	memset(&item,0,sizeof(item));
	romitem = sysbuf_ptr(SysInfo->romlist);
	romend = romitem + SysInfo->romlen;
	while (romitem < romend) {
		WORD k;

		for (k = 0; k < SysInfo->nvideo; k++) {
			if (romitem->seg == SysInfo->video[k].rom) {
				break;
			}
		}
		if (k < SysInfo->nvideo) {
			strcpy(item.name,MSG5021);
		}
		else if (romitem->seg == SysInfo->diskrom) {
			strcpy(item.name,MSG5023);
		}
		else  {
			strcpy(item.name,MSG5022);
		}

		item.class = CLASS_ROM;
		item.flags.high = TRUE;
		item.saddr = FAR_PTR(romitem->seg,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = (long)romitem->size * 16;
		item.layer = 3;
		glist_new(umlist,&item,sizeof(item));
		romitem++;
	}
}

/*
 *	map_flexroms - build map for flexxed roms
 */

void map_flexroms(
	GLIST *umlist)	/* Pointer to map list */
{
	FLEXROM *flexitem;	/* Pointer to flexxed ROM list item */
	FLEXROM *flexend;	/* Pointer to end of flexxed ROM list */
	UMAP item;		/* One memory map item */

	memset(&item,0,sizeof(item));
	flexitem = sysbuf_ptr(SysInfo->flexlist);
	flexend = flexitem + SysInfo->flexlen;
	while (flexitem < flexend) {
		WORD k;

		for (k = 0; k < SysInfo->nvideo; k++) {
			if (flexitem->dst == SysInfo->video[k].rom) {
				break;
			}
		}
		if (k < SysInfo->nvideo) {
			strcpy(item.name,MSG5021);
		}
		else if (flexitem->dst == SysInfo->diskrom) {
			strcpy(item.name,MSG5023);
		}
		else  {
			strcpy(item.name,MSG5022);
		}

		item.class = CLASS_ROM;
		item.flags.high = TRUE;
		item.saddr = FAR_PTR(flexitem->dst,0);
		item.faddr = FLAT_ADDR(item.saddr);
		item.length = flexitem->len;
		item.layer = 3;
		glist_new(umlist,&item,sizeof(item));
		flexitem++;
	}
}

/*
 *	find_holes - build map for any regions unaccounted for
 */

void find_holes(
	GLIST *umlist)	/* Pointer to map list */
{
	UMAP item;	/* One memory map item */
	UMAP *ump;	/* Pointer to map entry */
	GLIST hlist;	/* Temporary memory hole list */
	DWORD here; /* Where we are in memory */
	DWORD top_dos;	/* Address of top of DOS memory */

	/* Walk the map and fill in any holes.	By the time
	 * we get to this, there should be very few holes. */

	glist_init(&hlist,GLIST_ARRAY,sizeof(MEMHOLE),4*sizeof(MEMHOLE));
	top_dos = (DWORD)SysInfo->biosdata.memory_size * 1024;
	if (top_dos < 0xA0000) top_dos = 0xA0000;
	here = 0;
	ump = glist_head(umlist);
	for ( ;ump; ump = glist_next(umlist,ump)) {
		if (here < ump->faddr) {
			WORD seg;
			DWORD dsize;
			WORD size;
			int type;
			MEMHOLE hitem;

			seg = (WORD)(here/16);
			dsize = ump->faddr - here;
			size = (WORD)(dsize/16);

			memset(&item,0,sizeof(item));

			if (size && !NoTestMem) {
				type = testmem(seg,&size);
				dsize = (DWORD)size * 16;
			}
			else	type = TESTMEM_UNKNOWN;

			switch (type) {
			case TESTMEM_UNKNOWN:
				strcpy(item.name,MSG5025);
				break;
			case TESTMEM_RAM:
				strcpy(item.name,MSG5026);
				item.class = CLASS_RAM;
				break;
			case TESTMEM_ROM:
			case TESTMEM_EMPTY:
				strcpy(item.name,MSG5027);
				item.class = CLASS_UNUSED;
				break;
			case TESTMEM_MCAMEM:
				strcpy(item.name,MSG5024b);
				item.class = CLASS_RAM;
				break;
			}

			item.saddr = FAR_PTR(seg,0);
			item.faddr = FLAT_ADDR(item.saddr);
			if (item.faddr >= top_dos) item.flags.high = TRUE;
			item.length = dsize;
			item.layer = 1;
			item.flags.hole = TRUE;
			ump = glist_insert(umlist,ump,&item,sizeof(item));
			strcpy(hitem.name,item.name);
			hitem.class = item.class;
			hitem.faddr = item.faddr;
			hitem.length = dsize;
			glist_new(&hlist,&hitem,sizeof(hitem));
			here += dsize;
		}
		else if (here == ump->faddr) {
			here += ump->length;
		}
	}
	/* Transfer memory holes to SysInfo buffer */
	sysbuf_glist(&hlist,sizeof(MEMHOLE),&SysInfo->hmap,&SysInfo->hmaplen);
	glist_purge(&hlist);	/* bye-bye */
}

/*
 *	map_holes - add hole items to memory map
 */

void map_holes(
	GLIST *umlist)	/* Pointer to map list */
{
	UMAP item;	/* One memory map item */
	UMAP *ump;	/* Pointer to map entry */
	MEMHOLE *hp;	/* Pointer to memory hole entry */
	MEMHOLE *hpend; /* Pointer to end of memory hole array */
	DWORD top_dos;	/* Address of top of DOS memory */

	hp = sysbuf_ptr(SysInfo->hmap);
	hpend = hp + SysInfo->hmaplen;
	if (!hp) return;

	top_dos = (DWORD)SysInfo->biosdata.memory_size * 1024;
	if (top_dos < 0xA0000) top_dos = 0xA0000;
	ump = glist_head(umlist);
	for ( ;ump; ump = glist_next(umlist,ump)) {
		if (hp->faddr < ump->faddr) {
			memset(&item,0,sizeof(item));
			strcpy(item.name,hp->name);
			item.class = hp->class;
			item.faddr = hp->faddr;
			item.saddr = SEG_ADDR(hp->faddr);
			if (item.faddr >= top_dos) item.flags.high = TRUE;
			item.length = hp->length;
			item.layer = 1;
			item.flags.hole = TRUE;
			ump = glist_insert(umlist,ump,&item,sizeof(item));
			hp++;
			if (hp >= hpend) break;
		}
	}
}

/*
 *	map_extra - add extra items to memory map
 */

void map_extra(
	GLIST *umlist)	/* Pointer to map list */
{
	UMAP item;	/* One memory map item */
	MEMHOLE *hp;	/* Pointer to memory hole entry */
	MEMHOLE *hpend; /* Pointer to end of memory holes */
	DWORD top_dos;	/* Address of top of DOS memory */

	hp = sysbuf_ptr(SysInfo->emap);
	hpend = hp + SysInfo->emaplen;
	if (!hp) return;

	top_dos = (DWORD)SysInfo->biosdata.memory_size * 1024;
	if (top_dos < 0xA0000) top_dos = 0xA0000;
	while (hp < hpend) {
		memset(&item,0,sizeof(item));
		strcpy(item.name,hp->name);
		item.class = hp->class;
		item.faddr = hp->faddr;
		item.saddr = SEG_ADDR(hp->faddr);
		if (item.faddr >= top_dos) item.flags.high = TRUE;
		item.length = hp->length;
		item.layer = 3;
		glist_new(umlist,&item,sizeof(item));
		hp++;
	}
}

/*
 *	map_dd - build map for device drivers
 */

void map_dd(
	GLIST *umlist)	/* Pointer to map list */
{
	WORD kk;	/* Loop counter */
	int drv;	/* Drive number */
	UMAP *ump;	/* Pointer to map entry */
	GLIST templist; /* Scratch list */
	DDLIST *ddl;	/* Pointer to device driver header */
	DDLIST *ddlend; /* Pointer to end of device driver list */

	if (SysInfo->ddlen < 1) return; /* Nothing to do */

	/* Set up temp list */
	glist_init(&templist,GLIST_ARRAY,sizeof(UMAP),4*sizeof(UMAP));

	kk = 0;
	ddl = sysbuf_ptr(SysInfo->ddlist);
	ddlend = ddl + SysInfo->ddlen;
	drv = SysInfo->logdrv;
#ifdef MAPINFO_DBG
	do_intmsg ("----- Begin list ----\n");
#endif
	while (ddl < ddlend) {
#ifdef MAPINFO_DBG
		char dtemp[9];
		WORD x1,x2;
		_fmemcpy (dtemp,ddl->name,8);
		dtemp[8] = '\0';
		x1 = XWORDHI(ddl->this);
		x2 = XWORDLO(ddl->this);
		do_intmsg ("Driver %04x:%04x \"%s\" (%04x)\n", x1, x2, dtemp, ddl->attr);
#endif
		ump = glist_new(&templist,NULL,sizeof(UMAP));
		ump->saddr = (char far *)ddl->this;
		ump->faddr = FLAT_ADDR(ump->saddr);
		ump->length = 0;
		ump->class = CLASS_DOS;
		ump->layer = 3;
		if (ddl->attr & 0x8000) {
			_fmemcpy(ump->name,ddl->name,8);
			ump->name[8] = '\0';
		}
		else {
			int ndrv;

			ndrv = *(BYTE far *)ddl->name;
			drv -= ndrv;
			if (ndrv > 1) {
				sprintf(ump->name,MSG5028,
					drv + 'A',
					drv + 'A' + ndrv - 1);
			}
			else {
				sprintf(ump->name,MSG5029,
					drv + 'A');
			}
		}
		strcpy(ump->text,bits_on(ddl->attr));
		ddl++;
		kk++;
	}

	/* Sort 'em */
	glist_sort(&templist,umcmp);

	/* Calculate the sizes of the installable device drivers */
	{
		DWORD low;
		DWORD high;
		UMAP *ump1;
		UMAP *ump2;

		low = SysInfo->dev_start;
		high = SysInfo->data_start;
		ump1 = glist_head(&templist);
#ifdef MAPINFO_DBG
	do_intmsg("Low=%04x:%04x, high=%04x:%04x\n",
		XWORDHI(low), XWORDLO(low), XWORDHI(high), XWORDLO(high));
#endif
		for (kk = 0; kk < SysInfo->ddlen; kk++,ump1 = glist_next(&templist,ump1)) {
			if (kk+1 < SysInfo->ddlen) {
				ump2 = glist_next(&templist,ump1);
				if (ump1->faddr >= low && ump1->faddr < high) {
					ump1->class = CLASS_DEV;
					if (ump2->faddr >= low && ump2->faddr < high) {
						ump1->length = ump2->faddr - ump1->faddr;
					}
					else {
						ump1->length = high - ump1->faddr;
						break;
					}
				}
			}
			else {
				if (ump1->faddr >= low && ump1->faddr < high) {
					ump1->class = CLASS_DEV;
					ump1->length = high - ump1->faddr;
					break;
				}
			}
#ifdef MAPINFO_DBG
	do_intmsg ("kk=%d, faddr=%04x:%04x, len=%04x%04x\n",
		kk, XWORDHI(ump1->faddr), XWORDLO(ump1->faddr),
		XWORDHI(ump1->length), XWORDLO(ump1->length));
#endif
		}
	}

	/* Put everybody into the master list */
	ump = glist_head(&templist);
	while (ump) {
		glist_new(umlist,ump,sizeof(UMAP));
		ump = glist_next(&templist,ump);
	}
	/* ...and toss the temp list */
	glist_purge(&templist);
}

/*
 *	map_dosdata - build map for DOS data areas
 */

void map_dosdata(
	GLIST *umlist)	/* Pointer to UMAP list */
{
	DOSDATA *dmp;	/* Pointer to dosdata item */
	DOSDATA *dmpend;/* End of dosdata items */

	if (SysInfo->doslen < 1) {
		/* Nothing to do */
		return;
	}

	dmp = sysbuf_ptr(SysInfo->dosdata);
	dmpend = dmp + SysInfo->doslen;

	for (; dmp < dmpend; dmp++) {
		UMAP item;

		if (dmp->faddr < SysInfo->data_start ||
			dmp->faddr >= SysInfo->data_end) {
			continue;
		}

		memset(&item,0,sizeof(item));
		switch (dmp->type) {
#if 0
		case 'D':       /* This is actually covered by map_dd */
			sprintf(item.name,MSG5030,dmp->name);
			break;
#endif
		case 'E':
			sprintf(item.name,MSG5031,dmp->name);
			break;
		case 'I':
			sprintf(item.name,MSG5032,dmp->name);
			break;
		case 'F':
			sprintf(item.name,MSG5033,dmp->count);
			break;
		case 'C':
			sprintf(item.name,MSG5034,dmp->name);
			break;
		case 'B':
			sprintf(item.name,MSG5035,dmp->count);
			break;
		case 'X':
			sprintf(item.name,MSG5036,dmp->count);
			break;
		case 'L':
			sprintf(item.name,MSG5037);
			break;
		case 'S':
			sprintf(item.name,MSG5038);
			break;
		default:
			*item.name = '\0';
		}

		if (*item.name) {
			item.saddr = dmp->saddr;
			item.faddr = dmp->faddr;
			item.length = dmp->length;
			item.layer = 3;
			item.class = CLASS_DOS;
			glist_new(umlist,&item,sizeof(item));
		}
	}
}

/*
 *	map_ints - build map for interrupts
 */

void map_ints(GLIST *umlist)
{
	int k;			/* Loop counter */
	int ord;		/* UMAP ordinal */
	UMAP *ump;		/* Pointer to map entry */

	/* Walk the memory map and figure out where each interrupt vector
	 * points */

	ord = 1;
	ump = glist_head(umlist);
	while (ump) {
		for (k = 0; k < 256; k++) {
			DWORD faddr;

			if (!SysInfo->vectors[k]) continue;
			faddr = FLAT_ADDR(SysInfo->vectors[k]);
			if (faddr >= ump->faddr &&
				faddr <  ump->faddr+ump->length) {
				SysInfo->intmap[k] = ord;
			}
		}
		ord++;
		ump = glist_next(umlist,ump);
	}
}


/*
 *	map_zeroes - delete any zero length fragments
 */

void map_zeroes(GLIST *umlist)
{
	UMAP *ump;		/* Pointer to map entry */

	ump = glist_head(umlist);
	while (ump) {
		if (ump->flags.frag && ump->length == 0) {
			ump = glist_delete(umlist,ump);
		}
		else	ump = glist_next(umlist,ump);
	}
}


/*
 *	map_shortitems - merge any short (<16b) items with preceedint items
 */

void map_shortitems(GLIST *umlist)
{
	UMAP *ump;		/* Pointer to map entry */
	UMAP *umplast;		/* Pointer to last map entry */

	/* By the way, this only applies up thru the Dos Drivers/Data area */
	ump = glist_head(umlist);
	umplast = NULL;
	while (ump) {
		if (ump->faddr == SysInfo->dev_start) {
			/* Merge first item up instead of down */
			if (ump->length > 0 && ump->length < 32) {
				umplast = ump;
				ump = glist_next(umlist,ump);
				if (ump) {
					ump->faddr -= umplast->length;
					ump->saddr = SEG_ADDR(ump->faddr);
					ump->length += umplast->length;
					ump = glist_delete(umlist,umplast);
					umplast = NULL;
					continue;
				}
			 }
		}

		if (ump->faddr >= SysInfo->data_end) break;

		if (umplast && ump->length > 0 && ump->length < 32) {
			umplast->length += ump->length;
			ump = glist_delete(umlist,ump);
		}
		else {
			if (ump->length > 0) umplast = ump;
			ump = glist_next(umlist,ump);
		}
	}
}

/*
 *	umcmp - compare two memory map items
 */

int _cdecl umcmp(
	const void *p1,   /* Pointer to first item */
	const void *p2)   /* Pointer to second item */
{
	if (((UMAP *)p1)->faddr < ((UMAP *)p2)->faddr) return -1;
	if (((UMAP *)p1)->faddr > ((UMAP *)p2)->faddr) return  1;

	if (((UMAP *)p1)->layer < ((UMAP *)p2)->layer) return -1;
	if (((UMAP *)p1)->layer > ((UMAP *)p2)->layer) return 1;

	/* Notice lengths are sorted descending */
	if (((UMAP *)p1)->length < ((UMAP *)p2)->length) return 1;
	if (((UMAP *)p1)->length > ((UMAP *)p2)->length) return -1;

	return stricmp(((UMAP *)p1)->name,((UMAP *)p2)->name);
}

/*
 *	fix_overlap - correct for overlapping memory regions
 */

void fix_overlap(
	GLIST *umlist)	/* Pointer to map list */
{
	UMAP *ump;	/* Pointer to map entry */

top:
	ump = glist_head(umlist);
#ifdef MAPINFO_DBG
	do_intmsg ("Top of fix_overlap() (first is %s)\n", ump->name);
#endif
	for (; ump; ump = glist_next(umlist,ump)) {
		UMAP *ump1;
		UMAP *ump2;

		ump1 = ump;
		if (ump1->length == 0) continue;

		ump2 = glist_next(umlist,ump1);
		if (!ump2) break;
		if (ump1->faddr > ump2->faddr) {
			/* In certain unusual situations, fragmenting can
			 * make things out of order.  If this happens, we
			 * re-sort the map and start over */
			glist_sort(umlist,umcmp);
			goto top;
		}
#ifdef MAPINFO_DBG
	do_intmsg ("fix_overlap() lvl 2: %s (first is %s)\n", ump->name, ump2->name);
#endif
		for (; ump2; ump2 = glist_next(umlist,ump2)) {
			if (ump1->faddr > ump2->faddr) {
				/* Same comment as above... */
				glist_sort(umlist,umcmp);
				goto top;
			}
			if ((ump1->faddr + ump1->length) <= ump2->faddr) {
				/* No overlap */
				break;
			}
#ifdef MAPINFO_DBG
			do_intmsg ("Checking for overlap %s:%d vs %s:%d\n",
				ump1->name, ump1->layer, ump2->name, ump2->layer);
#endif
			if (ump1->layer >= ump2->layer) {
				if (item_overlap(umlist,ump1,ump2)) goto top;
			}
			else {
				if (item_overlap(umlist,ump2,ump1)) goto top;
			}
		}
	}
}

BOOL item_overlap(	/* Fix overlap on one pair of items */
	GLIST *umlist,		/* Pointer to UMAP list */
	UMAP *ump1,	/* Upper (dominant) item */
	UMAP *ump2)	/* Lower (submissive) item */
/* Return:	TRUE if re-sort done */
{
	BOOL rtn;
	DWORD ump1end;		/* Flat address for end of upper item */
	DWORD ump2end;		/* Flat address for end of lower item */
	DWORD delta;		/* Scratch difference */

	rtn = FALSE;
	ump1end = ump1->faddr + ump1->length;
	ump2end = ump2->faddr + ump2->length;
	ump1->flags.over = TRUE;
	ump2->flags.frag = TRUE;
	if (ump1->faddr <= ump2->faddr) {
		/* Upper starts before lower */
		if (ump1end >= ump2end) {
			/* Upper covers lower, lower disappears */
			ump2->length = 0;
#ifdef MAPINFO_DBG
			do_intmsg ("Deleting fragment %s (inside %s)\n", ump2->name, ump1->name);
#endif
		}
		else {
			/* Upper covers start of lower */
			delta = ump1end-ump2->faddr;
			ump2->faddr += delta;
			ump2->saddr = SEG_ADDR(ump2->faddr);
			ump2->length -= delta;
		}
	}
	else {
		/* Lower starts before upper */
		if (ump1end >= ump2end) {
			/* Upper covers end of lower */
			delta = ump2end-ump1->faddr;
			ump2->length -= delta;
		}
		else {
			/* Upper covers middle of lower */
			UMAP item;	/* One memory map item */

			memcpy(&item,ump2,sizeof(item));
			ump2->length = ump1->faddr - ump2->faddr;

			item.faddr = ump1end;
			item.saddr = SEG_ADDR(item.faddr);
			item.length = ump2end - ump1end;
			glist_new(umlist,&item,sizeof(item));
			glist_sort(umlist,umcmp);
			rtn = TRUE;
		}
	}
	return rtn;
}

/*
 *	bits_on - format string to show which bits are on
 */

char *bits_on(
	WORD value)	/* Source value */
{
	int n;
	char *pp;
	static char temp[40];

	pp = temp;

	n = 0;
	while (value) {
		if (value & 1) {
			itoa(n,pp,16);
			strupr(pp);
			pp += strlen(pp);
			if (value > 1) *pp++ = ',';
		}
		value /= 2;
		n++;
	}
	*pp = '\0';
	return temp;
}

/* Mon Nov 26 17:06:07 1990 alan:  rwsystxt and other bugs */
/* Tue Nov 27 11:45:57 1990 alan:  bug in fix_overlap */
/* Wed Dec 19 17:12:54 1990 alan:  new mapping technique */
/* Thu Jan 03 10:17:06 1991 alan:  changes for ps/2 128k bios */
/* Tue Feb 19 15:42:25 1991 alan:  fix rom_find bug */
/* Wed Feb 20 13:14:59 1991 alan:  fix map_holes bug */
/* Wed Feb 20 15:42:54 1991 alan:  fix more bugs */
/* Thu Feb 21 16:35:56 1991 alan:  fix bugs */
/* Sat Mar 09 12:06:18 1991 alan:  fix bugs */
/* Wed Mar 13 21:04:32 1991 alan:  fix bugs */
/* Thu Mar 28 21:58:25 1991 alan:  fix bugs */
