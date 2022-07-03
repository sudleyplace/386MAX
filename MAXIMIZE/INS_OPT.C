/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_OPT.C_V   1.0   05 Sep 1995 16:33:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INS_OPT.C								      *
 *									      *
 * Maximize optimization routines					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>

/* Local Includes */
#include <ins_var.h>		/* INS_*.* global variables */

#define INS_OPT_C			/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef INS_OPT_C

#ifndef PROTO
#include "ins_map.pro"
#include "ins_opt.pro"
#endif /*PROTO*/

/* Local functions */
static void walk_devices (struct _device *D);
static BOOL check_conflict (struct _adf_choice *A, BYTE with);
static BOOL no_conflict (void);
static void check_choice (void);
static void analyze_choice (void);

/* long perm_count; */

/********************************* OPTIMIZE ***********************************/

void optimize (void)
{
	int n;
	struct _device *LD;

	memcpy (conflict_map, available_blocks, MAX_BLOCKS);

	choice_count = 0;
	/* perm_count = 0L; */

	/* analyze_current (); */

	/* for (n = 1; n < MAX_CHOICES; n++) */
	for (n = 0; n < MAX_CHOICES; n++)
	{
		nholes[n] = 32767;
		maxhole[n] = 0;
		emshole[n] = 0;
	} /* End FOR */

	if (Last_device == NULL)
		return;

	/* Set adapter states based upon user's preferences */
	for (LD = Last_device; LD; LD = LD->Next)
		LD->Devflags.Dfixed = (BYTE)
			((slots[LD->slot].exec && LD->List == NULL)
			    || (slots[LD->slot].cur_state != MAXIMIZE)
			    ? TRUE : FALSE);

	walk_devices (Last_device);

} /* End OPTIMIZE */

/****************************** WALK_DEVICES **********************************/

static void walk_devices (struct _device *D)
{
	struct _adf_choice *A;

	if (D != NULL)		/* If not at end of recursion, */
	{
		for (A = D->Devflags.Dfixed ? D->Cmos : D->List; /* ...select all choices */
	   D->Devflags.Dfixed || A != NULL;
	   A = A->Next)
		    {
			D->Choice = A;	/* Make it the optimized choice */

			if (check_conflict (A, 1)) /* Check if choice has conflict and */
				/* fill in conflict map */
			{
				walk_devices (D->Next); /* Recurse through next device */
				check_conflict (A, 0); /* Remove choice from conflict map */
			} /* End IF */

			D->Choice = NULL;	/* Remove above assumption */

			if (D->Devflags.Dfixed) /* If it's a fixed device, */
				break;		/* ...quit after once through */
		} /* End FOR */
	}
	else {
		/* perm_count++; */
		map_used (FALSE);

		if (no_conflict ())
			analyze_choice ();
	} /* End ELSE */
} /* End WALK_DEVICES */

/******************************** NO_CONFLICT *********************************/
/***
 * Checks for conflicts in map_sum[], which is initialized by
 * INS_MAP.C!map_used().
 *
 * Called from walk_devices().
***/
static BOOL no_conflict (void)
{
	register int n;

	for (n = 0; n < MAX_BLOCKS; n++)
		if (map_sum[n] > 1)
			return (FALSE);

	return (TRUE);
} /* End NO_CONFLICT */

/********************************* CHECK_CHOICE *******************************/

static void check_choice (void)
{
	struct _device *D;
	int index, n;
	int tmp_ems_hole,
	tmp_big_hole,
	tmp_hole_count;

	/* No duplicates of current configuration */
	/* if (choice_count > 0 && current_choice ()) */
	/*    return; */
	/* */
	if (choice_count < MAX_CHOICES)
	{
		index = choice_count;
		choice_index[choice_count] = choice_count;
		choice_count++;
	} /* End IF */
	else
	{
		index = -1;
		tmp_ems_hole   = ems_hole;
		tmp_big_hole   = big_hole;
		tmp_hole_count = hole_count;

		for (n = 0; n < choice_count; n++)
			if (emshole[n] < tmp_ems_hole)
			{
				index = n;
				tmp_ems_hole	 = emshole[n];
				tmp_big_hole	 = maxhole[n];
				tmp_hole_count = nholes[n];
			} /* End FOR/IF */
			else
				if (emshole[n] == tmp_ems_hole)
				{
					if (maxhole[n] < tmp_big_hole)
					{
						index = n;
						tmp_big_hole   = maxhole[n];
						tmp_hole_count = nholes[n];
					} /* End IF */
					else
						if (maxhole[n] == tmp_big_hole)
							if (nholes[n] > tmp_hole_count)
							{
								index = n;
								tmp_hole_count = nholes[n];
							} /* End IF/ELSE/IF/IF */
				} /* End FOR/IF/ELSE/IF */

		if (index < 0)
			return;
	} /* End IF/ELSE */

	emshole[index] = ems_hole;
	nholes[index] = hole_count;
	maxhole[index] = big_hole;

	for (D = Last_device; D ; D = D->Next)
		D->Choices[index] = D->Choice;

} /* End CHECK_CHOICE */

/******************************* ANALYZE_CHOICE *******************************/

static void analyze_choice (void)
{
	register int n;
	int hole_size;
	unsigned int key;

	/* Initialize global variables */
	ems_hole = 0;
	big_hole = 0;
	hole_count = 0;

	key = -1;
	hole_size = 0;

	/* Calculate size of largest hole and the # holes */
	for (n = 0; n < MAX_BLOCKS; n++)
	{
		if (key != map_sum[n])
		{
			if (map_sum[n] == 0)	/* Start of hole */
			{
				hole_size = 1;
				hole_count++;
			} /* End IF */
			else			/* End of hole */
			{
				if (hole_size > big_hole)
					big_hole = hole_size;
				hole_size = 0;
			} /* End ELSE */
			key = map_sum[n];
		} /* End IF */
		else
			if (map_sum[n] == 0)
				hole_size++;
	} /* End FOR */

	if (hole_size > 0
	    && hole_size > big_hole)
		big_hole = hole_size;

	/* Calculate size of ems_hole */
	if (EmsFrame)
		for (n = (int) ((Ems_device->Choice->mem[0][0] - BLOCK_START) / BLOCK_SIZE) - 1;
	n && map_sum[n] == 0;
	n--)
			    ems_hole++;

	check_choice ();

} /* End ANALYZE_CHOICE */

/******************************* CHECK_CONFLICT *******************************/

static BOOL check_conflict (struct _adf_choice *A, BYTE with)
{
	int start, end, redo;
	DWORD from, to;

	if (A == NULL)	/* Empty devices */
		return (TRUE);	/* ...never conflict */

	from = A->mem[0][0];
	to = A->mem[0][1]; /* Only processing 1st mem range */
	/* Most devices only have one range */
	/* other cases handled by no_conflict() */

	if (from < BLOCK_START || from > BLOCK_END
	    || to   < BLOCK_START || to   > BLOCK_END
	    || from > to)
		return (FALSE);

	start = (int) ((from - BLOCK_START) / BLOCK_SIZE);
	end = (start - 1) + (int) (((to + (BLOCK_SIZE - 1)) - from) / BLOCK_SIZE);

	/* Handles special case of ending value 1 too large */
	if (with > 0)
	{
		redo = start;
		while (start <= end)
		{
			if (conflict_map[start] > 0)
			{
				while (redo < start) /* Conflict exists, undo the damage to MAP */
					conflict_map[redo++] = 0;
				return (FALSE);
			} /* End IF */

			conflict_map[start++] = with;
		} /* End WHILE */
	} /* End IF */
	else
		while (start <= end)
			conflict_map[start++] = with;

	return(TRUE);

} /* End CHECK_CONFLICT */
