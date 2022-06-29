/*' $Header:   P:/PVCS/MAX/MAXIMIZE/CHKRAM.C_V   1.0   05 Sep 1995 16:32:50   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CHKRAM.C								      *
 *									      *
 * MAXIMIZE check for available RAM					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>

/* Local includes */
#include <intmsg.h>		/* Intermediate message functions */

#define CHKRAM_C
#include <maxtext.h>		/* MAXIMIZE message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef CHKRAM_C

#ifndef PROTO
#include "chkram.pro"
#include <maxsub.pro>
#include "linklist.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
static long ram_strt[25];
static long ram_end[25];

/* Local functions */

/*********************************** CHKRAM ***********************************/

void chkram (void)
{
	int ii, jj;
	BYTE far *p;
	CONFIG_D *dp;

	do_intmsg(MsgScanRAM);
	for (jj = 0 ; jj < 25 ; jj++) {
		ram_strt [jj] = 0;
		ram_end [jj] = 0;
	} /* End FOR */

	// ramscan() sets bits in *p, 1 byte / 4K of high DOS
	// starting from A000; skip A000 - C000 and don't go
	// into system ROM area - no adapters should be there,
	// only chipset mapped space as on Zenith.
#if SYSTEM == MOVEM
#define ENDHIGHDOS	(((0xffff - 0xA000) / 256) + 1)
#else
#define ENDHIGHDOS	((SysRom - 0xA000) / 256)
#endif
	if ((p = ramscan ()) != NULL) {
		for (ii = 32,	// (0xC000 - 0xA000) / 256
			jj = 0 ; (unsigned) ii < ENDHIGHDOS ; ii++) {
			if (p[ii] & RAMTAB_RAM) {
				ram_strt [jj] = (256 * ii) + 0xA000;
				ram_end [jj] = ram_strt [jj] + 256;
				for ( ii++ ; (unsigned) ii < ENDHIGHDOS ; ii++) {
					if (p[ii] & RAMTAB_RAM) {
						ram_end[jj] += 256;
					}
					else {
						jj++;
						break;
					} /* End FOR/IF/ELSE */
				}
			} /* End IF/FOR/IF */
		}
	}
	// We have constructed lists of starting and ending addresses
	// for RAM blocks; now add them to the profile
	for (jj = 24 ; jj >= 0 ; jj--) {
		if (ram_strt[jj]) {
			dp = get_mem(sizeof(CONFIG_D));
			dp->etype = RAM;
			dp->saddr = ram_strt[jj];
			dp->eaddr = ram_end[jj];
			dp->comment = MsgAdapterMem;
			addtolst(dp, CfgHead);
		} /* End FOR/IF */
	}

} /* End CHKRAM */
