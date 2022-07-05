/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_MCA.C_V   1.1   13 Oct 1995 12:03:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INS_MCA.C								      *
 *									      *
 * Special processing for MCA machines					      *
 * Not used in MOVE'EM version                                                *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>

/* Local includes */
#define OWNER
#include <ins_var.h>		/* INS_*.* global variables */
#undef OWNER

#include <debug.h>		/* Debug variables */
#include <ui.h> 		/* UI definitions */
#include <intmsg.h>		/* Intermediate message functions */

#ifdef DEBUG
#include <conio.h>
#endif

#define INS_MCA_C			/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef INS_MCA_C

#ifndef PROTO
#include "ins_adf.pro"
#include "ins_ems.pro"
#include "ins_exe.pro"
#include "ins_map.pro"
#include "ins_mca.pro"
#include "ins_pos.pro"
#include "linklist.pro"
#include "p1browse.pro"
#include "profile.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
extern BOOL extset;
extern DWORD emsmem;

/* Local functions are prototyped automatically by makefile */

/********************************* PROCESS_MCA ********************************/
/* Process Micro Channel machines */
/* Return TRUE if user can find the reference diskette, */
/*	  FALSE if not (caller will then do RAM scan). */

BOOL process_MCA (void)

{
#ifdef DEBUG
	int n;
#endif

	memset (available_blocks, 0, MAX_BLOCKS);

	set_sysrom ();	/* Set SYSROM variable and mark memory */

	/* Mark A0000-C0000 as unavailable unless they are later */
	/* overridden by an explicit USE= */
	mark_blocks (available_blocks, BLOCK_START, 0xC0000, 1);

	EmsFrame = TRUE;

#ifdef DEBUG
	if (!MCAflag)
#endif
		/* If we can't get the CMOS data, return and do a RAMSCAN */
		if (!scan_adapters ()) return (FALSE);
/*
 * An alternate way of faking POS info on a non-MCA machine.
 *	if (!MCAflag) {
 *		FILE *fp;
 *
 *		fp = fopen("POSDEBUG.OUT","w");
 *		if (fp) {
 *			fwrite(&slots,sizeof(slots[0]),MAX_SLOTS,fp);
 *			fclose(fp);
 *		}
 *	}
 *	else {
 *		FILE *fp;
 *
 *		fp = fopen("POSDEBUG.DAT","r");
 *		if (fp) {
 *			fread(&slots,sizeof(slots[0]),MAX_SLOTS,fp);
 *			fclose(fp);
 *		}
 *	}
 */

#ifdef DEBUG
      /* This is great, but what if you don't have the
       * ADF disk to go with it?
       */
   if (MCAflag) {

      slots[7].adapter_id = 0xDFBF;
      slots[7].cmos_pos[0] = 0x05;
      slots[7].cmos_pos[1] = 0x02;

      slots[7].adapter_id = 0xDDFF;
      slots[7].cmos_pos[0] = 0x19;
      slots[7].cmos_pos[1] = 0x03;

      slots[1].adapter_id = 0xE1FF;
      slots[1].cmos_pos[0] = 1;
      slots[1].cmos_pos[1] = 0xd8;
      slots[1].cmos_pos[2] = 0;
      slots[1].cmos_pos[3] = 0xfa;

      slots[2].adapter_id = 0xEF7F;   /* 8514A */
      slots[2].cmos_pos[0] = 1;

      slots[3].adapter_id = 0xE1FF;
      slots[3].cmos_pos[0] = 0;
      slots[3].cmos_pos[1] = 0xd2;
      slots[3].cmos_pos[2] = 0;
      slots[3].cmos_pos[3] = 0xfa;

      slots[4].adapter_id = 0xDEFF;
      slots[4].cmos_pos[0] = 1;
      slots[4].cmos_pos[1] = 1;

      slots[5].adapter_id = 0xFCFF;
      slots[5].cmos_pos[0] = 1;

      slots[6].adapter_id = 0xEFEF;
      slots[6].cmos_pos[0] = 0x83;

      slots[0].adapter_id = 0xDDFF;
      slots[0].cmos_pos[0] = 0x19;
      slots[0].cmos_pos[1] = 0x02;
      if(Verbose){
	 printf("\n*** DEVICES FOUND ....................................\n");
	 printf("              ....POS....  ....ADP....\n");
	 printf("   SLOT  ID    0  1  2  3   0  1  2  3\n");
	 for(n=0; n<MAX_SLOTS; n++)
	    printf("    %2d  %04X  %02X %02X %02X %02X  %02X %02X %02X %02X  \n",n+1, slots[n].adapter_id,
	       slots[n].cmos_pos[0], slots[n].cmos_pos[1],
	       slots[n].cmos_pos[2], slots[n].cmos_pos[3],
	       slots[n].adapter_pos[0], slots[n].adapter_pos[1],
	       slots[n].adapter_pos[2], slots[n].adapter_pos[3]);
	 press_any ();

      } /* End IF Verbose */

   } /* End IF !MCAflag */
#endif

	if (read_adf () == FALSE) /* Process ADF files on reference diskette */
		return (FALSE); /* Exit if user doesn't want ADF processing */
	if (AnyError)	/* If someone requested we abort, */
		return (TRUE);	/* just quit and let caller check the flags */

	/* Ask about Quick Maximize */
	if (QuickMax == 0) {
		do_quickmax();
	}

	resolve_ramrom ();	/* Resolve RAM= and ROM= */

	if (EmsFrame)	/* If EMS frame wanted, add EMS device */
		add_ems_device ();

#ifdef DEBUG
	dump_devices ("foobar.txt");
#endif

	if (Last_device != NULL) /* If there are any devices */
	{
		/* Display adapter selection window and ask the user to */
		/* decide which ones should change state, and optimize */
		/* the configuration */
		p1browse (); /* Display 'em */

		if (AnyError)
			return (TRUE);

		if (choice_count > 0)		/* If there are any choices, */
		{
			sort_choices ();		/* ...sort the best one to first, */
			activate_choice ();		/* ...activate the best choice */
			construct_choice_pos ();	/* ...construct the POS */
			add_ram ();			/* ...add RAM statements to the profile */
			write_pos ();		/* ...write out the POS */
		} /* End IF */
	} /* End IF */

	return (TRUE);

} /* End PROCESS_MCA */

/********************************* SET_SYSROM *********************************/
/* Set SYSROM variable and mark memory at above it as unavailable */

void set_sysrom (void)

{
	if (!MaxInstalled	/* If MAX not installed, */
	&& !BcfInstalled)	/* and there's no BCF= in the profile, */
		SysRom = 0xE000; /* Force it to a valid state */
	sysroml = ((DWORD) SysRom) << 4;

	/* Mark memory above SYSROML as unavailable */
	mark_blocks (available_blocks, sysroml, BLOCK_END, 1);
} /* End SET_SYSROM */

/******************************** CHECK_REFABIOS *****************************/
/* Return TRUE if we can _read the reference diskette and find ABIOS.SYS */
BOOL check_refabios (void)
{
	char adf_stem[128];

	/* Give the user a chance to put in the reference diskette. */
	/* We won't ask for it again (at least not in this round of MAXIMIZE */
	strcpy (adf_stem, "A:\\");
	if (do_refdsk (adf_stem, sizeof(adf_stem)-12-1) == KEY_ENTER) {

	  strcat (adf_stem, "ABIOS.SYS");
	  if (!_access (adf_stem, 0)) return (TRUE);

	} /* User supplied the reference diskette */

	return (FALSE); /* No reference disk, or it doesn't have ABIOS.SYS */

} /* check_refabios() */

/******************************** SCAN_ADAPTERS *******************************/
/* Return TRUE if successful; otherwise, we cannot proceed */
BOOL scan_adapters (void)
{
	/* See if ABIOS calls can be made and init for POS _read */
	/* If MAX is present, ALWAYS use EMM2CALL; ROMSRCH may have */
	/* zapped ABIOS */
	if (!MaxInstalled) {
	  if (posinit ()) {
		if (!check_refabios ()) goto CRAPOUT; /* No ABIOS.SYS */
		if (posinit ()) goto CRAPOUT;	/* Two strikes and you're out */
	  } /* End if posinit() failed */
	  abios = TRUE;
	  readpos_abios ();
	} /* End if MAX not installed */
	else
	{
		if (!PosDataStat) {	/* If MAX has CMOS POS values */
			readpos ();	/* Do it the old-fashioned way */
		}
		else {
			if (check_refabios ()) {
			  /* Tell 'em they can reboot or continue */
			  do_abreboot ();
			  return (FALSE);
			} /* Reference diskette had ABIOS.SYS */
CRAPOUT:
			do_error (AbiosErr, FALSE);	/* Display error message and abort */
			return (FALSE);
		}
	} /* End IF/ELSE */

	/* Get POS for system board - not supported by ABIOS past first 4 */
	read_syspos ();

	/* Setup adapter ID list */
	set_adapid ();

	return (TRUE);

} /* End SCAN_ADAPTERS */

#ifdef DEBUG
/*___ press_any ____________________________________________________*/

void press_any (void)
{
	fprintf(stderr,"\nPress a key to continue\n");
	_getch();
} /* press_any */
#endif

/******************************** RESOLVE_RAMROM ******************************/

void resolve_ramrom (void)

{
	ETYPE etype;
	BOOL found_use = FALSE;
	CONFIG_D *C;
	PRSL_T *L;
	DWORD start, end;	/* Temp vars used for range conversion */

	Last_ramrom = NULL;	/* Initialize linked list */

	for (L = CfgHead; L != NULL; L = L->next)
	{
		C = L->data;
		etype = C->etype;

#ifdef DEBUG
		if (Verbose)
			printf("TYPE: %d,  SADDR: %08lX, EADDR: %08lX %p\n   %s\n",
			etype, C->saddr, C->eaddr, C->origstr, C->origstr);
#endif

		switch (etype)
		{
		case USE:	  /* Keep track if a USE or INCLUDE is found */
		case INC:	  /* Handled on a second pass */

			/* Note if USE and INC are not processed when found. because */
			/* the order important (i.e. if USE comes before EXCLUDE or VID). */
			/* To take into account the order dependency, we delay */
			/* processing USE and INC until a second pass is made. */

			found_use = TRUE;
			start = C->saddr << 4;
			end = C->eaddr << 4;
			mark_blocks (available_blocks, start, end, 0);

			break;

		case RAM:	  /* Throw away RAM statements */
			/* Free the comment and zap it to force deletion */
			delfromlst (L, 1);

			break;

		case ROM:	  /* Check if associated with a device */
			if (!device_association (L))
				delfromlst (L, 1); /* Free the comment and zap it to force deletion */

			break;

		case VID:	  /* Mark this area as not available */
		case EXC:
			start = C->saddr << 4;
			end = C->eaddr << 4;
			mark_blocks (available_blocks, start, end, 1);

			break;

		case EMS:	  /* Preset the EMS flag */
			emsmem = C->saddr;	/* Save original EMS= value */
			if (emsmem == 0L)	/* If it's zero, */
			{
				ems_services = FALSE; /* ...disable services */
				EmsFrame = FALSE;	/* ...and frame */
			} /* End IF */

			/* Free the comment and zap it to force deletion */
			delfromlst (L, 1);

			break;

		case FRAMEX:	  /* Force the EMS page frame into existence */
			if (ems_services == FALSE)
			{   /* Free the comment and zap it to force deletion */
				delfromlst (L, 1);

				break;
			} /* End IF */

			EmsFrame = TRUE;

			/* Save the EMS starting address for later detection of the */
			/* current EMS block during creation of the dummy EMS device */
			EmsCurrent = C->saddr << 4;

			break;

		case SFRAME:   /* Convert SHORTFRAME to NOFRAME */
			C->etype = NOFRAME;

		case NOFRAME:  /* Flag EMS services but no page frame */
			EmsFrame = FALSE;

			/* Free the comment and zap it to force deletion */
			delfromlst (L, 1);

			break;

		case VGA:	  /* Mark blocks not available */
		case EGA:
			mark_blocks (available_blocks, 0xA0000, 0xC0000, 1);

			break;

		case CGA:	  /* Mark blocks not available */
			mark_blocks (available_blocks, 0xB8000, 0xC0000, 1);

			break;

		case MONO:
			mark_blocks (available_blocks, 0xB0000, 0xC0000, 1);

			break;

		case POSFILE:
			/* Free the comment and zap it to force deletion */
			delfromlst (L, 1);

			break;

		default:
			;
		} /* End SWITCH */
	} /* End FOR */

	/* Make a 2nd pass looking for USE & INCLUDE */
	/* and force these areas available */
	if (found_use)
		for (L = CfgHead; L != NULL; L = L->next)
		{
			C = L->data;
			switch (C->etype)
			{
			case USE:
			case INC:
				start = C->saddr << 4;
				end = C->eaddr << 4;
				mark_blocks (available_blocks, start, end, 0);

				break;

			default:
				;
			} /* End SWITCH */
		} /* End FOR/IF */

} /* End RESOLVE_RAMROM */

/****************************** DEVICE_ASSOCIATION ****************************/

BOOL device_association (PRSL_T *L)

{
	CONFIG_D *C;
	struct _device *D;
	struct _adf_choice *A;
	DWORD start, end;
	register unsigned int n;

	C = L->data;

	start = C->saddr << 4;
	end = C->eaddr << 4;

	for (D = Last_device; D != NULL; D = D->Next) {
		if (!D->Devflags.Ems_device && (A = D->Cmos) != NULL) {
			for (n = 0; n < A->memcnt; n++) {
				if (A->mem[n][0] <= start && start < A->mem[n][1])
				{
					associate (D, n, L);	/* Associate this ROM with this device range */
					return(TRUE);
				} /* End FOR/IF/FOR/IF */
			}
		}
	}

	return(FALSE);

} /* End DEVICE_ASSOCIATION */

/******************************** ASSOCIATE ***********************************/
/* Associate a ROM with a device */

void associate (struct _device *D, int which_mem, PRSL_T *L)

{
	struct _ramrom *R;		/* Ptr to allocated RAMROM struct space */
	CONFIG_D *C;		/* Ptr to ROM profile data */

	R = get_mem (sizeof (struct _ramrom));

	D->Cfg_ramrom[which_mem] = R;
	C = L->data;
	R->start = C->saddr << 4;
	R->end = C->eaddr << 4;
	R->Cfg = L;
	R->Next = Last_ramrom;
	Last_ramrom = R;

#ifdef DEBUG
	if (Verbose)
		printf ("ASSOC ROM=%06lX-%06lX with %s\n",R->start,R->end,
		slots[D->slot].adapter_name);
	press_any();
#endif

} /* End ASSOCIATE */

/**************************** CONSTRUCT_CHOICE_POS ****************************/
#pragma optimize("leg",off)
void construct_choice_pos (void)

{
	struct _device *D;
	struct _adf_choice *A;
	unsigned int n;
	BYTE pos_byte;

	/* Setup Choice_POS with current CMOS_POS values */
	for (slot = 0; slot < MAX_SLOTS; slot++)
		memcpy (slots[slot].choice_pos, slots[slot].cmos_pos, MAX_POS);

	for (D = Last_device; D != NULL; D = D->Next)
		if (!(D->Devflags.Ems_device || D->Devflags.P_device))
		{
			slot = D->slot;

			if (slots[slot].adapter_id != 0xFFFF
			    && slots[slot].cur_state != NOMEM)
			{
				A = D->Choice;

				if (slots[slot].exec)	/* Call the ADP to get the POS data */
					exec_pos (D);
				else			/* Use the ADF POS data */
				{
					for (n = 0; n < slots[slot].numbytes; n++)
					{    /* Force the required 1 bits to a 1 */
						pos_byte = slots[slot].choice_pos[n] | A->pos_mask[n][1];

						/* Force the required 0 bits to a 0 */
						pos_byte &= ~A->pos_mask[n][0];

						slots[slot].choice_pos[n] = pos_byte;
					} /* End FOR */

#ifdef DEBUG
					if (Verbose)
					{
						printf("NEW POS FOR %s\n",slots[slot].adapter_name);
						printf("    ....OLD....    ....NEW....\n");
						printf("     0  1  2  3     0  1  2  3\n");
						printf("    %02X %02X %02X %02X    %02X %02X %02X %02X\n",
						slots[slot].cmos_pos[0],slots[slot].cmos_pos[1],
						slots[slot].cmos_pos[2],slots[slot].cmos_pos[3],
						slots[slot].choice_pos[0],slots[slot].choice_pos[1],
						slots[slot].choice_pos[2],slots[slot].choice_pos[3]);
					} /* End IF */
#endif

				} /* End IF/ELSE */
			} /* End IF */
		} /* End FOR/IF */
} /* End CONSTRUCT_CHOICE_POS */
#pragma optimize("",on)

/******************************** ACTIVATE_CHOICE *****************************/
/* Setup the choice pointer */
/* Select the best choice (based upon MAXHOLE, NHOLES, and CHOICE_EMSHOLE) */
/* with the EMS page frame at its highest address */
/* Note that if a device has no memory, the ->Choices entry is NULL */

void activate_choice (void)

{
	struct _device *D;
	int i = 0;

	/* The index to use is in I */
	for (D = Last_device; D != NULL; D = D->Next)
		D->Choice = D->Choices[choice_index[i]];

} /* End ACTIVATE_CHOICE */

/********************************** ADD_RAM ***********************************/

/* Add the RAM= statements to the profile linked list */
/* Also adjust associated RAM statements to reflect new ranges */
/* If any RAM= statements have been added, also add IGNOREFLEXFRAME */

void add_ram (void)

{
	struct _device	   *D;
	struct _adf_choice *A;
	struct _ramrom	   *R;
	CONFIG_D   *C;
	PRSL_T	   *L;

	DWORD saddr, eaddr;
	unsigned int n;
	int	 count;

	for (count = 0, D = Last_device; D != NULL; D = D->Next)
	{
		A = D->Choice;
		if (A == NULL)
			continue;

		for (n = 0; n < A->memcnt; n++)
		{
			saddr = A->mem[n][0] >> 4;
			eaddr = A->mem[n][1] >> 4;

			if (D->Devflags.Ems_device)
			{
				sprintf (TempBuffer, "FRAME=%04lX  ; %s\n", saddr, ems_name);
				count += replace_in_profile (FRAMEX, TempBuffer, saddr, eaddr);
			} /* End IF */
			else
				if (D->Cfg_ramrom[n] != NULL)  /* Device associated, update range */
				{
					R = D->Cfg_ramrom[n];
					L = R->Cfg;
					C = L->data;
					C->saddr = saddr;
					C->eaddr = eaddr;
				} /* End IF */
				else
				{
					sprintf (TempBuffer, "RAM=%04lX-%04lX  ; %s\n",
					saddr, eaddr, slots[D->slot].adapter_name);
					count += add_to_profile (RAM, TempBuffer, saddr, eaddr);
				} /* End ELSE */
		} /* End FOR */
	} /* End FOR */

	if (count) {
		(void) replace_in_profile (IGNOREFLEXFRAME, MsgIgnoreFlex, 0L, 0L);
	} /* RAM statements were added */

} /* End ADD_RAM */
