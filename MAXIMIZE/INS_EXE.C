/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_EXE.C_V   1.1   13 Oct 1995 12:03:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INS_EXE.C								      *
 *									      *
 * Procedures to handle the exec function of an ADP			      *
 * Not used in MOVE'EM version                                                *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>

/* Local Includes */
#include <ins_var.h>		/* INS_*.* global variables */
#include <intmsg.h>
#include <debug.h>		/* Debug variables */

#define INS_EXE_C			/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef INS_EXE_C

#ifndef PROTO
#include "ins_exe.pro"
#include "ins_adf.pro"
#include "ins_adp.pro"
#include "ins_mca.pro"
#include <maxsub.pro>
#include "screens.pro"
#endif /*PROTO*/

/* Local variables */

typedef struct _rom_hdr_str {
   WORD  romsig;    /* ROM signature 55aa */
   BYTE  romlen;    /* length of ROM in 512 byte blocks */
   BYTE  jmpopcode; /* near JMP opcode- E9 */
   WORD  jmpoff;    /* near offset for JMP to initialization */
} ROM_HDR, far *ROM_HDRp;

struct PATCH_CMP {
   WORD  cmpoff;
   BYTE  cmpdata[10];
};

typedef struct PATCH_CMP  patch_cmp;

patch_cmp scsi1 = {0x016B,
		   {0xCC, 0x2E, 0x8C, 0x1E, 0x0A,
		    0x01, 0x8B, 0x46, 0x08, 0x8E},
		  };

patch_cmp scsi1a= {0x058F,
	   {0x2E, 0xC7, 0x06, 0x18, 0x01, 0x00, 0xC0,
		    /* MOV WORD ptr CS:[0118],C000 */
	    0x2E, 0xC7, 0x06},
		    /* MOV WORD ptr CS:? */
	  };

patch_cmp scsi1b= {0x059D,
	   {0x2E, 0xC6, 0x06, 0x0F, 0x01, 0x00,
		    /* MOV BYTE ptr CS:[010F],00 */
	    0xB9, 0x00, 0x00,	/* MOV CX, 0000 */
	    0x2E},	/* CS:? */
	  };

patch_cmp scsi1c= {0x05A6,
	   {0x2E, 0x81, 0x3E, 0x18, 0x01, 0x00, 0xE0,
		    /* CMP WORD ptr CS:[0118],E000 */
	    0x7D, 0x4E,     /* JGE 05FD */
	    0x2E},	/* CS:? */

	     };

patch_cmp scsi2 = {0x05CE,
		   {0xBB, 0x00, 0x02, 0xF7, 0xE3,
		    0x2E, 0x03, 0x06, 0x1A, 0x01},
		  };

patch_cmp scsi3 = {0x05F4,
		   {0x2E, 0x81, 0x06, 0x1A, 0x01,
		    0x80, 0x00, 0xEB, 0xBA, 0xF9},
		  };

patch_cmp ibm8514a = {0x026F,
		    {0x75, 0x0E, 0x8B, 0x47, 0x02,
		     0x3D, 0x02, 0xFE, 0x75, 0x06},
		    };

patch_cmp ibmxga = {0x133,
		    {0x8b, 0x7e, 0x06,	// MOV DI,[BP+6]
		     0xcc,		// INT 3
		     0x2e, 0x80, 0x3e, 0x0c, 0x01, 0x01},
					// CMP BYTE PTR CS:[10C],01
		    };

struct PATCH_DATA
{
   WORD  patoff;
   BYTE  patdata;
};

typedef struct PATCH_DATA patch_data;

patch_data pdata_8efe [] = {{0x016B, 0x90},
		       {0x05CF, 0x20},
		       {0x05D0, 0x00},
		       {0x05F9, 0x00},
		       {0x05FA, 0x04},
		      };

patch_data romseg_data = {0x0595, 0xC0};    /* high byte of ROM segment */
patch_data romseg_dat2 = {0x059C, 0xC0};    /* high byte of ROM segment */
patch_data romcod_data = {0x05A2, 0x00};    /* code to blast into POS to */
			/* set starting addr of ROM */
patch_data romjmp_data[] = {	{0x05A3, 0xF8}, /* JMP to short circuit */
		{0x05A4, 0xEB}, /* ROM relocation space finder */
		{0x05A5, 0x58},
	       };

/* IBM 8514/a adapter */
patch_data pdata_ef7f [] = {{0x270, 0x00},	/* jmp to nowhere */
			    {0x278, 0x00},	/* jmp to nowhere */
			   };

/* IBM XGA adapter - not the built-in XGA */
patch_data pdata_8fdb = {0x136, 0x90};		/* Kill the INT 3! */

#pragma optimize ("leg",off)
/********************************* PROCESS_EXEC *******************************/
/*  Procedures to handle the exec function of an ADP */

void process_exec (void)

{  WORD status;
   int i;
   BYTE far *fpatch;
   int	foundrom;
   BYTE slotlcl;	// Local copy of slot
   int adpresult;

   adp_parm_blk.slot = (char) slot; /* Setup ADP exec block */
   adp_parm_blk.Sysmeml = &Sysmeml;
   adp_parm_blk.Sysbrdl = &Sysbrdl;
   adp_parm_blk.P_array = pos_array;
   adp_parm_blk.P_mask = pos_mask;
/* adp_parm_blk.Id_list;*/
   adp_parm_blk.adp_function = (WORD (far *)(void))adp_entry;
   adp_parm_blk.Rqp = &resource_parm_blk;
   adp_parm_blk.Sysmemh = &Sysmemh;
   adp_parm_blk.Sysbrdh = &Sysbrdh;
   adp_parm_blk.Id_list = adapter_id_list;

   create_pos_mask ();			/* Create the POS mask */

   adf_stem[adf_nstem] = '\0';
   sprintf (adf_stem+adf_nstem, "%c%04X.ADF", slot ? 'C' : 'S',
		slots[slot].adapter_id);

   status = load_adp (adf_stem, &slots[slot].exec_seg);

   if (status != 0)
   {   if (status == 2) {
	   /* Unable to find file %s */
	   do_textarg(1,adf_stem);
	   do_error(MsgUnaFind, TRUE);
       }
       else {
	   /* DOS ERROR # %4Xh occurred while loading:	%s */
	   char temp[8];

	   sprintf(temp,"%4X",status);
	   do_textarg(1,temp);
	   do_textarg(2,adf_stem);
	   do_error(MsgDosErr, TRUE);
       }
   } /* End IF */

   /* Set up a far pointer for patching ADP files */
   fpatch = (BYTE far *) (((DWORD) slots[slot].exec_seg) << 16);

   /* Because of several bugs in the IBM PS/2 SCSI Adapter (8EFE or 8EFF) */
   /*	ADP file, we must patch it for it to work */

   if (slots[slot].adapter_id == 0x8EFE  /* Izit our boy? */
    || slots[slot].adapter_id == 0x8EFF) /* ...or our boy w/cache? */
       /* Ensure we know where we are before patching it */
   {   if (adp_cmp (&scsi1) == TRUE
	&& adp_cmp (&scsi1a) == TRUE
	&& adp_cmp (&scsi1b) == TRUE
	&& adp_cmp (&scsi1c) == TRUE
	&& adp_cmp (&scsi2) == TRUE
	&& adp_cmp (&scsi3) == TRUE)

	{

	    do_intmsg (MsgPatching, slots[slot].adapter_id);
	    /* Patch the various locations */
	    for (i = 0; i < (sizeof (pdata_8efe)/sizeof (patch_data)); i++)
		fpatch[pdata_8efe[i].patoff] = pdata_8efe[i].patdata;
	    /*
	     * Now comes the fun part.	Due to another bug in the
	     * ADP file, it has to be told where its own location
	     * in ROM is before it can tell us where it can be
	     * relocated to.  Before patching the ADP file, we must
	     * find that location, then blast it into the ADP,
	     * as well as short-circuiting the subroutine where
	     * the ADP determines a safe location to relocate
	     * itself to.
	     */

	     /* NOTE: in-line _asm blocks do NOT properly handle references
	      * to non-local variables.  Specifically, anything NOT in DGROUP
	      * may get referenced with DS.
	      */
	      slotlcl = slot;	// Get slot # into a local variable
_asm	{
    mov bl, slotlcl;	// get slot #
    mov ax, 0xc401;	// put adapter in slot BL into setup mode
    int 0x15;		// Call BIOS
    jc	NoLuck; 	// there was an error

    mov dx, 0x102;	// _read byte from POS[0]
    in	al, dx; 	// get it
    jmp IOdly0
IOdly0:
    jmp IOdly1
IOdly1:
    jmp IOdly2
IOdly2:
    sub ah, ah		// clear high byte of AX
    mov foundrom, ax	// save value

    mov bl, slotlcl;	// get slot #
    mov ax, 0xc402;	// re-enable adapter in slot BL
    int 0x15;		// call BIOS
    jnc GotAddr;	// we got the ROM address
NoLuck:
    mov foundrom, 0	// we failed
			// Note that under normal circumstances,
			// POS[0] is never 0 because the low-order
			// bit is set if the adapter is enabled.
    jmp AddrDone	// join common exit code
GotAddr:
    mov ax, foundrom	// get value from POS[0]
    mov cl, 4		// prepare to get 4 high bits
    shr ax, cl		// ROM seg = (AL*200h) + C000h
    and al,not 1	// Mask off bit 0 - only bits 1-3 significant
    mov romcod_data.patdata, al // value to blast into POS
    shl ax, 1		// al *= 2
    add al, 0xc0;	// add c000h part
    mov romseg_data.patdata, al // high byte of address
    mov foundrom, 1	// tell'em we found our boy
AddrDone:
};

	/* Now blast the segment of the ROM into the ADP and we're done. */
	if (foundrom) {
	    fpatch[romseg_data.patoff] = romseg_data.patdata;
	    fpatch[romseg_dat2.patoff] = romseg_dat2.patdata;
	    fpatch[romcod_data.patoff] = romcod_data.patdata;
	    /* short circuit hole finder subroutine in ADP */
	    for (   i = 0;
		i < sizeof (romjmp_data) / sizeof (patch_data);
		i++)
	     fpatch[romjmp_data[i].patoff] =
		romjmp_data[i].patdata;
	} /* foundrom */

    }	/* comparison passed - this ADP has more bugs than a roach motel */

   } /* End IFA (8EFE or 8EFF) */

   if (slots[slot].adapter_id == 0xEF7F &&  /* Izit an IBM 8514/a? */
	adp_cmp (&ibm8514a) == TRUE) {	    /* Does it meet our expectations? */

	    do_intmsg (MsgPatching, slots[slot].adapter_id);

	    /* Patch the various locations */
	    for (i = 0; i < (sizeof (pdata_ef7f)/sizeof (patch_data)); i++)
		fpatch[pdata_ef7f[i].patoff] = pdata_ef7f[i].patdata;

   } /* End if (EF7F: IBM 8514/a) */

   if (slots[slot].adapter_id == 0x8FDB &&	// Izit an IBM XGA?
	adp_cmp (&ibmxga) == TRUE) {		// Does it match?

	    do_intmsg (MsgPatching, slots[slot].adapter_id);

	    /* Apply one small patch (remove int 3) */
	    fpatch[pdata_8fdb.patoff] = pdata_8fdb.patdata;

   } /* End if (8FDB: IBM XGA) */

   blocking_factor = tmp_ad.memcnt;
   memcpy (current_block, tmp_ad.mem, MAX_RANGES * 8);
   memcpy (TempBuffer, &tmp_ad, sizeof (struct _adf_choice));

   /* Determine blocking factor and current configuration */
   if (adpresult = call_adp ((BYTE) 5) &&	// Call failed
	slots[slot].adapter_id != 0x8fdb) { // Not an XGA, which will always
					// fail due to block req. outside 1MB
	char adpresult_str[40];
	sprintf (adpresult_str, "Error code %X", adpresult);
	error_adap (MsgADPFailure, adpresult_str, NULL, FALSE);
   } // call_adp (5) failed

   call_adp ((BYTE) 1); 		/* Determine memory block choices */

} /* End PROCESS_EXEC */
#pragma optimize ("",on)

/********************************** ADP_CMP **********************************/
/* Compare data in ADP prior to patching it */

BOOL adp_cmp (patch_cmp *adpp)

{  char adp_lcl[30];
   char far *dst = adp_lcl;

   _movedata (slots[slot].exec_seg, adpp->cmpoff,
	     FP_LSEG (dst), FP_LOFF (dst), sizeof (adpp->cmpdata));

   return (memcmp (adp_lcl, adpp->cmpdata, sizeof (adpp->cmpdata)) == 0)
	 ? TRUE : FALSE;

} /* End SCSI_CMP */

/********************************* ADP_ENTRY **********************************/
/*  This procedure provides the function support required by an ADP. */
/*  How each function is provided depends on the function requested */
/*  of the ADP.  When the ADP is requested to configure the adapter */
/*  the REQUEST MEMORY BLOCK will always refuse to allocate the */
/*  block, but it will build a list of choices for the adapter. */
/*  When the ADP is requested to determine the current configuration */
/*  the RMB will always confirm the allocation, it will also keep */
/*  track of the memory block's requested as the current CMOS POS */
/*  configuration. */

void adp_entry (void)

{  BYTE status;
   BYTE func;

   func = resource_parm_blk.func;
#ifdef DEBUG
   printf ("ADP resource function: %02X\n", func);
   printf ("slot: %d\n", resource_parm_blk.slot);
   printf ("Start_add: %04X%04X\n", resource_parm_blk.start_add_h, resource_parm_blk.start_add_l);
   printf ("  End_add: %04X%04X\n", resource_parm_blk.end_add_h,   resource_parm_blk.end_add_l);
   printf ("     Size: %04X%04X\n", resource_parm_blk.size_h,      resource_parm_blk.size_l);
#endif
   status = 0xFF;

   switch (func)
   {  case 0:		/* Request memory block */
	 status = request_block ();
	 break;

      case 1:		/* Check memory block */
      case 2:		/* Deallocate memory block */
      case 3:		/* Enable an Adapter */
      case 4:		/* Disable an Adapter */
	 break;

      case 6:		/* Return number of slots */
	 resource_parm_blk.slot = 8;
      case 5:		/* Enable a memory prompt */
	 status = 0;
	 break;

      default:
	 ;
   } /* End SWITCH */

   resource_parm_blk.func = status;

#ifdef DEBUG
   if(Verbose)
   {  if(status == 0xff)
	 printf("\nUNSUPPORTED ADF FUNCTION CALL %d made by C%04X.ADF\n",
	    func, slots[slot].adapter_id);
   } /* End IF */
#endif
} /* End ADP_ENTRY */

/********************************* REQUEST_BLOCK ******************************/

BYTE request_block (void)

{  BYTE status = 3;
   DWORD start,end;

   start = xaddr (resource_parm_blk.start_add_h, resource_parm_blk.start_add_l);
   end	 = xaddr (resource_parm_blk.end_add_h,	resource_parm_blk.end_add_l);


   /* Note that memory requests outside of this range are ignored such as
    * if the ADP file requests memory at or above 1MB such as the IBM XGA
    * adapter makes. */
   if (start < BLOCK_START || start > BLOCK_END /* Ensure START in range */
    || end   < BLOCK_START || end   > BLOCK_END /* Ensure END in range */
    || start > end)				/* Ensure in sequence */
       return(status);

/*///if (start > end)			// Ensure in sequence*/
/*///	 return (status);*/
/*///*/
/*///// The IBM XGA adapter makes a 1MB memory request for 1MB to 16MB*/
/*///// and a 2MB memory request from 2MB to 14MB which we must ensure succeed*/
/*///if (start > BLOCK_END)		// If it's out of our range*/
/*///	 return (0);			// ...call it OK*/
/*///*/
      if (adp_parm_blk.func == 1)	/* If the adapter is trying to */
      { 				/* configure itself */
#ifdef DEBUG
      printf("RQB  memcnt: %d, blkcnt: %d, bf: %d, start: %08lX, end: %08lX\n",
	 tmp_ad.memcnt, block_cnt, blocking_factor, start, end);
#endif
      tmp_ad.mem[tmp_ad.memcnt][0] = start;	/* Save the starting */
      tmp_ad.mem[tmp_ad.memcnt][1] = end;	/* and ending addresses */
      block_cnt++;				/* Count in another block */
      tmp_ad.memcnt++;				/* ... */

      if (block_cnt >= blocking_factor)
      {   add_choice ();
	  if (memcmp (current_block, tmp_ad.mem, MAX_RANGES * 8) == 0)
	      Last_device->Cmos = Last_device->List;
	  memcpy (&tmp_ad, TempBuffer, sizeof(struct _adf_choice));
	  block_cnt = tmp_ad.memcnt;
      } /* End IF */
   } /* End IF */
   else
   if (adp_parm_blk.func == 5)
   {   if (blocking_factor < MAX_RANGES)
       {   current_block[blocking_factor][0] = start;
	   current_block[blocking_factor][1] = end;
	   blocking_factor++;
       } /* End IF */
       else	/* Blocking factor error while processing ADP */
	   do_error (MsgBlkFacErr, TRUE); /* Display message and abort */

      status = 0;
   } /* End IF */

   return (status);

} /* End REQUEST_BLOCK */

/*___ create_pos_mask _______________________________________________*/

void create_pos_mask (void)	/* Create the pos mask for the ADP */

{
unsigned int n;
BYTE mask;

   for(n=0; n<32; n++)
      slots[slot].pos_mask[n] = 0xff;

   for(n=0; n<slots[slot].numbytes; n++){
      mask = slots[slot].exec_pos_mask[n][0] | slots[slot].exec_pos_mask[n][1];
      if(n == 0)
	 mask |= 1;
#ifdef DEBUG
      printf("MASK[%d]: %02X  pos0: %02X  pos1: %02X\n",n,mask,
	 tmp_ad.pos_mask[n][0],tmp_ad.pos_mask[n][1]);
#endif
      slots[slot].pos_mask[n] ^= mask;
   }

#ifdef DEBUG
   printf("POS MASK FOR SLOT %d\n",slot);

   for(n=0; n<32; n++){
      printf(" %02X",slots[slot].pos_mask[n]);
      if(n == 15)
	 printf("\n");
   }
   printf("\n");
#endif
}

/*___ fill_pos_array ________________________________________________*/

void fill_pos_array (void)	/* Create the pos data array for the ADP */

{  int n;

   memset(&pos_array[0], 0, sizeof(pos_array));

   for(n=0; n<MAX_SLOTS; n++){
      pos_array[n].numbytes = slots[n].numbytes;
      memcpy(pos_array[n].pos_data, slots[n].cmos_pos, MAX_POS);
   }
}

/********************************* CALL_ADP ***********************************/
// Execute a specified ADP function, and return the result code.  Nonzero
// indicates failure.
int call_adp (BYTE func)	/* call the ADP */
{
#ifdef DEBUG
   printf("ADP FUNCTION: %d  memcnt: %d\n",func,tmp_ad.memcnt);

   /*dump_adapter(&tmp_ad);*/
#endif
   memcpy(pos_mask, slots[slot].pos_mask, sizeof(pos_mask));
   fill_pos_array();
   block_cnt = tmp_ad.memcnt;
   adp_parm_blk.func = func;
   exec_adp(slots[slot].exec_seg, &adp_parm_blk);
   return (adp_parm_blk.func);
}

/********************************* ADP_CONFIG *********************************/

void adp_config (void)	 /* Configure the ADP */

{  BYTE status;
   WORD func;

   func = (WORD) resource_parm_blk.func;
#ifdef DEBUG
   printf("ADP config function: %02X\n",func);
   printf("slot: %d\n",resource_parm_blk.slot);
   printf("Start_add: %04X%04X\n",resource_parm_blk.start_add_h,resource_parm_blk.start_add_l);
   printf("  End_add: %04X%04X\n",resource_parm_blk.end_add_h,resource_parm_blk.end_add_l);
   printf("     Size: %04X%04X\n",resource_parm_blk.size_h,resource_parm_blk.size_l);
#endif
   status = 0xff;

   switch (func)
   {  case 0:		/* Request memory block */
	 status = selected_choice(Device_Choice->Choice);
	 break;

      case 1:		/* Check memory block */
      case 2:		/* Deallocate memory block */
      case 3:		/* Enable an Adapter */
      case 4:		/* Disable an Adapter */
      case 5:		/* Enable a memory prompt */
	 break;

      case 6:		/* Return number of slots */
	 status = 0;
	 resource_parm_blk.slot = 8;
	 break;

      default:
	 ;
   } /* End SWITCH */

   resource_parm_blk.func = status;

#ifdef DEBUG
   if(Verbose){
      if(status == 0xff)
	 printf("\nUNSUPPORTED ADF FUNCTION CALL %d made by C%04X.ADF\n",
	    func, slots[slot].adapter_id);
   } /* End IF */
#endif
} /* End ADP_CONFIG */

/******************************** EXEC_POS ************************************/

void exec_pos (struct _device *D)     /* Construct the pos by calling the ADP */

{  register unsigned int n;

   Device_Choice = D;		/* Setup global device pointer for ADP */
				/* function calls */

   adp_parm_blk.slot = (BYTE) slot;	/* Setup ADP exec block */
   adp_parm_blk.Sysmeml = &Sysmeml;
   adp_parm_blk.Sysbrdl = &Sysbrdl;
   adp_parm_blk.P_array = pos_array;
   adp_parm_blk.P_mask = pos_mask;
/* adp_parm_blk.Id_list;*/
   adp_parm_blk.adp_function = (WORD (far *)(void))adp_config;
   adp_parm_blk.Rqp = &resource_parm_blk;
   adp_parm_blk.Sysmemh = &Sysmemh;
   adp_parm_blk.Sysbrdh = &Sysbrdh;
   adp_parm_blk.Id_list = adapter_id_list;

   call_adp (1); /* Configure the adapter */

#ifdef DEBUG
   if(Verbose){
      printf("\nPOS ARRAY returned by C%04X.ADF\n",slots[slot].adapter_id);
      printf("    ....POS....\n");
      printf("    %02X %02X %02X %02X\n",
	 pos_array[slot].pos_data[0], pos_array[slot].pos_data[1],
	 pos_array[slot].pos_data[2], pos_array[slot].pos_data[3]);
      press_any();
   } /* End IF */
#endif

   /* Updating the choice POS array with the calculated data */
   /* from the ADP will force an update to the CMOS POS */
   for (n = 0; n < slots[slot].numbytes; n++)
      slots[slot].choice_pos[n] = pos_array[slot].pos_data[n];
} /* End EXEC_POS */

/******************************* SELECTED_CHOICE ******************************/
/* Determines if the ADP is requesting the selected choices blocks */
/* returns the ADP status of 0 if ok, 3 if not the right block	   */

BYTE selected_choice (struct _adf_choice *A)

{  register WORD n;
   DWORD start,end;

   if (A == NULL)		/* If not valid, */
       return (0);		/* return OK */

   start = xaddr (resource_parm_blk.start_add_h, resource_parm_blk.start_add_l);
   end	 = xaddr (resource_parm_blk.end_add_h,	resource_parm_blk.end_add_l);

   for (n = 0; n < A->memcnt; n++)	/* Check if block is one of the */
	if (A->mem[n][0] == start	/* starting and */
	 && A->mem[n][1] == end)	/* ending selected choice blocks */
	    return (0); 		/* Return if it is */

   return (3);				/* Otherwise, it isn't */

} /* End SELECTED_CHOICE */
