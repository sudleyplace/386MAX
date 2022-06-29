/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_EMS.C_V   1.0   05 Sep 1995 16:33:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INS_EMS.C								      *
 *									      *
 * Add the EMS memory choices into device list				      *
 * Not used in MOVE'EM version                                                *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>

/* Local Includes */
#include <ins_var.h>		/* INS_*.* global variables */
#include <maxvar.h>		/* MAXIMIZE global variables */

#ifndef PROTO
#include "ins_ems.pro"
#include "ins_adf.pro"
#endif /*PROTO*/


/********************************* ADD_EMS_DEVICE *****************************/
/* Add the EMS memory choices into device list */

void add_ems_device (void)

{
   struct _device *LastLast;
   int Old_Ems_device;

   slot = PSLOT_EMS;			/* Pseudo-device slot for page frame */
   slots[slot].init_state = MAXIMIZE;	/* Initial state for page frame */
   LastLast = Last_device;		/* Save pointer to old Last_device */
   if (LastLast) {
	/* Save previous Ems_device value (should be 0!) */
	Old_Ems_device = LastLast->Devflags.Ems_device;
	/* Force us to NOT overwrite existing device */
	LastLast->Devflags.Ems_device = TRUE;
   }
   add_device ();
   Ems_device = Last_device;
   Last_device->Devflags.Ems_device = TRUE; /* Flag this as the dummy EMS device */
   if (LastLast) {
	/* Restore previous value */
	LastLast->Devflags.Ems_device = Old_Ems_device;
   }
/* Last_device->analysis = 2; */

   init_tmp_ad();

   tmp_ad.mem[0][0] = 0xC0000;		/* Start EMS blocks at C0000 */
   tmp_ad.mem[0][1] = 0xCFFFF;		/* For 64KB */
   tmp_ad.memcnt = 1;

   while (tmp_ad.mem[0][1] < sysroml)	/* Continue until we bump into SYSROM */
   {	  add_choice ();

	  /* When we create the EMS page frame choices, watch for the */
	  /* current EMS page frame, when found, set the current CMOS flag */
	  if (tmp_ad.mem[0][0] == EmsCurrent)
	      Last_device->Cmos = Last_device->List;

	  tmp_ad.mem[0][0] += 0x4000;	/* Skip to next 16KB location */
	  tmp_ad.mem[0][1] += 0x4000;
   } /* End WHILE */
} /* End ADD_EMS_DEVICE */
