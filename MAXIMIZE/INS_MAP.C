/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_MAP.C_V   1.0   05 Sep 1995 16:33:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INS_MAP.C								      *
 *									      *
 * Maximize memory map routines 					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>

/* Local Includes */
#include <ins_var.h>		/* INS_*.* global variables */
#include <maxvar.h>		/* MAXIMIZE global variables */

/***
 * map_used ()
 *
 * This function walks through the device list starting with Last_device
 * (which, despite the name, is the head of the list) and records all
 * the blocks used by the selected configuration in the global map_sum[]
 * for later checking for potential conflicts.	Each element of map_sum[]
 * represents the number of blocks potentially overlaying it.  Conflicts
 * are detected immediately after map_sum[] has been initialized here
 * by calling INS_OPT.C!no_conflict().
 *
 * Called from INS_OPT.C!walk_devices().
 *
***/

void map_used (BOOL full_map)

{
	struct _device *D;
	struct _adf_choice *A;
	register int i, n;
	BOOL emsflag;
	DWORD addr;

	if (full_map); /* Make compiler shut up */

	/* Initialize the map summary with the available blocks */

	memcpy (map_sum, available_blocks, MAX_BLOCKS);
	/* map_index = 0; */		/* Initialize map entry counter  */

	/* Walk through devices and fill in the map */
	for (D = Last_device; D != NULL; D = D->Next)
	{
		slot = D->slot;
		emsflag = D->Devflags.Ems_device; /* Save for later use */

		/* Walk through the devices choices */
		for (A = D->List; A != NULL; A = A->Next)
		{/*/if (map_index >= MAX_MAP) */
			/* errorwnd (overflow_msg, 1, 1);*/ /* Display message and abort */

			if (A != D->Choice) {
				continue;
			} /* End ELSE */

			addr = BLOCK_START;	/* Go though the range and fill map */
			for (n = 0 ; n < MAX_BLOCKS ; n++)
			{
				for (i = 0 ; i < MAX_RANGES; i++)
					if ((A->mem[i][0] <= addr) && (addr <= A->mem[i][1]))
					{/*/map[map_index][n] = emsflag ? EMSMAP : */
						/*/			 (full_map && A->Afixed) ? FIXED : INUSE; */
						map_sum[n]++;
					} /* End FOR/IF */

				addr += BLOCK_SIZE;
			} /* End FOR */

			/* map_index++; */
		} /* End FOR */
	} /* End FOR */
} /* End MAP_USED */

/*___ mark_blocks _______________________________________________________________*/

void mark_blocks (BYTE array[], DWORD from, DWORD to, BYTE with)

{
	int start, end;

	if (from < BLOCK_START || from > BLOCK_END
	    || to   < BLOCK_START || to   > BLOCK_END
	    || from > to)
		return;

	start = (int) ((from - BLOCK_START) / BLOCK_SIZE);
	end = (start - 1) + (int) (((to + (BLOCK_SIZE - 1)) - from) / BLOCK_SIZE);

	/* Handles special case of ending value 1 too large */
	while (start <= end)
		array[start++] = with;

} /* End MARK_BLOCKS */

/******************************** SORT_CHOICES ********************************/
/* Simple bubble sort of choices sorted */
/*   descendingly by biggest EMS hole size, */
/*   descendingly by biggest high DOS hole size, */
/*   ascendingly by hole count, */
/*   higher EMS page frame. */

void sort_choices (void)

{
	register int i;
	int idx1, idx2;
	BOOL swapped;

	swapped = TRUE;
	while (swapped)
	{
		swapped = FALSE;
		for (i = 0; i < (choice_count - 1); i++)
		{
			idx1 = choice_index[i]; /* Select adjacent pair of indices */
			idx2 = choice_index[i + 1];

			if (emshole[idx1] < emshole[idx2] /* If EMS hole 1 < EMS hole 2 */
			|| (emshole[idx1] == emshole[idx2] /* or same size, and */
			&& (maxhole[idx1] < maxhole[idx2]	/* Holesize 1 < Holesize 2 */
			|| (maxhole[idx1] == maxhole[idx2]	/* or same Holesizes, and */
			&& (nholes[idx1] > nholes[idx2] /* and #holes1 > #holes2 */
			|| (nholes[idx1] == nholes[idx2]	/* or same # holes, and */
			&& (EmsFrame			/* If there's an EMS page frame */
			&&  Ems_device->Choices[idx1]->mem[0][0]
			    < Ems_device->Choices[idx2]->mem[0][0]
			)))))))
			{
				choice_index[i] = idx2;
				choice_index[i + 1] = idx1;

				swapped = TRUE;
			} /* End IF */
		} /* End FOR */
	} /* End WHILE */
} /* End SORT_CHOICES */
