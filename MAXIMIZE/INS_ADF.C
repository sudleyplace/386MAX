/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_ADF.C_V   1.1   13 Oct 1995 12:00:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-94 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INS_ADF.C								      *
 *									      *
 * MAXIMIZE routine to _read and process an adapter's ADF file                 *
 * This file is not used in MOVE'EM version                                   *
 *									      *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <conio.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>

/* Local includes */
#include <commfunc.h>		/* Common functions */
#include <ins_var.h>		/* INS_*.* global variables */
#include <stacker.h>

#define INS_ADF_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef INS_ADF_C

#ifndef PROTO
#include "ins_adf.pro"
#include "ins_exe.pro"
#include "ins_mca.pro"
#include "ins_pos.pro"
#include <maxsub.pro>
#include "profile.pro"
#include "screens.pro"
#include "util.pro"
#include "maximize.pro"
#endif /*PROTO*/

/* Local variables */
#define ADID_TIARA 0x6001

WORD PosDir = 0;
int LastBreak = 0;	/* Separator ending last token */

/* Variables in MAXSUB.ASM */
extern struct posd_str PosData[MAX_ASLOTS];
extern struct _mcaid   AdapPosData[MAX_ASLOTS];
extern BYTE far * BIOSConf;
extern BYTE BIOSDate[3];

// The following structure maps the POSFILE.BIN format we use
// to _write to the CMOS directly in 386MAX.SYS.
#pragma pack(1) 		// For byte alignment
typedef struct PosDirStr {
	 BYTE slot;		// The origin-1 slot #
	 WORD index;		// The origin-0 index into CMOS calculated as
				// 0x23 * (slot - 1) to get to the two-byte
				// adapter ID followed by numbytes
	 BYTE numbytes; 	// # following bytes to _write out (typically 4)
	 BYTE data[MAX_CPOS];	// Adapter data
};
#pragma pack()			// Restore

typedef enum {NOP=0, EQ, NE, LT, GT, LE, GE, AND, OR, XOR} OPCODES;
static struct { int Opcode; char *pszOpName; } Opcodes[] = {
 {	EQ,	"eq"    },
 {	NE,	"ne"    },
 {	LT,	"lt"    },
 {	GT,	"gt"    },
 {	LE,	"le"    },
 {	GE,	"ge"    },
 {	AND,	"and"   },
 {	OR,	"or"    },
 {	XOR,	"xor"   }
};
#define NOPCODES (sizeof(Opcodes)/sizeof(Opcodes[0]))

/* Local functions */

/***************************** CHECK_SYM ******************************/
/* Get or set symbol in Defsym list */
/* Returns 1 if value found or replaced, 0 if not found (possibly added). */
/* If piRetVal != NULL, search, otherwise add/replace. */
int check_sym (char *pszSymName, int iSetVal, int *piRetVal)
{
  DEFSYM *pWalk, *pLast;

  /* First, try to find the specified symbol. */
  for (pLast = pWalk = &Defsym; pWalk; pWalk = pWalk->pNext) {
	pLast = pWalk; /* Save last valid record */
	if (!_stricmp (pszSymName, pWalk->pszName)) break;
  } /* Walk until end of list */

  if (pWalk) {

    if (piRetVal)
	*piRetVal = pWalk->iVal;
    else
	pWalk->iVal = iSetVal;

    return (1);

  } /* Found it */
  else {

    if (!piRetVal) {

	pWalk = get_mem (sizeof (DEFSYM));
	pWalk->pszName = str_mem (pszSymName);
	pLast->pNext = pWalk;
	pWalk->iVal = iSetVal;

    } /* Add new record */

    return (0); /* Not found */

  } /* Add it if bSet */

} /* check_sym () */

/******************************** PARSE_DEFSYM ***************************/
/* Parse specified file (usually Dxxxx.ADF, where xxxx is the system board */
/* ID) for DefSym statements. */
void parse_defsym (char *pszFName)
{
  char paBuff[256];
  BOOL GotName;

  if (Adf = fopen (pszFName, "rt")) {

    while (get_token ()) {

	if (!_stricmp (TempBuffer, "defsym")) {

	  /* Symbol name is enclosed in quotes */
	  GotName = get_rawtoken (" \"\n\t=");
	  strcpy (paBuff, TempBuffer); /* Save name */

	  if (GotName && get_token ()) {
		check_sym (paBuff, atoi (TempBuffer), NULL);
	  } /* Got name and value */

	} /* Got DefSym */

    } /* while not EOF */

    fclose (Adf);

  } /* Opened file */

} /* parse_defsym () */

/*********************************** ISINLIST ********************************/
/* Return TRUE if specified word is in null-terminated list of words */
BOOL isinlist (WORD *list, WORD *alist, WORD id)
{
 int i;

 for (i=0; list[i]; i++) {
	if (list[i] == id)		return (TRUE);
 }

 if (alist) {
	for (i=0; alist[i]; i++) {
		if (alist[i] == id)	return (TRUE);
	}
 }

 return (FALSE);

} /* isinlist () */

/*********************************** READ_ADF *********************************/
/* Read the ADF's and build device/adapter lists */
/* Return TRUE if user can find the reference diskette, */
/*	  FALSE if not (caller will then do RAM scan). */

BOOL read_adf (void)	/* Read the ADF's and build device/adapter lists */

{  struct find_t dummy;
   char buff[100];
   KEYCODE ret_key;
   int i;

   unget_token = FALSE;
   Last_device = NULL;

   strcpy(adf_stem,"A:\\");
   adf_nstem = strlen(adf_stem);
   for (;;) {
      int rtn;

      ret_key = do_refdsk (adf_stem,sizeof(adf_stem)-12);
      if (ret_key == KEY_ESCAPE)
	  return (FALSE);

      adf_nstem = strlen(adf_stem);

      strcpy(adf_stem+adf_nstem,"*.ADF");
      rtn = _dos_findfirst (adf_stem, _A_NORMAL, &dummy);
      adf_stem[adf_nstem] = '\0';
      if (rtn == 0)
	  break;

      do_error(MsgNoAdf,FALSE);
   } /* End */

   /* Initialize symbol list with model and submodel ID */
   (void) check_sym ("model", BIOSConf[2], NULL);
   (void) check_sym ("submodel", BIOSConf[3], NULL);

   /* Add operators to symbol list */
   for (i=0; i < NOPCODES; i++)
	(void) check_sym (Opcodes[i].pszOpName, Opcodes[i].Opcode, NULL);

   /* Read Dxxxx.ADF (where xxxx is the system board ID) */
   /* and parse all DEFSYM statements; we'll need 'em in */
   /* processing the ADF file. */
   sprintf (adf_stem+adf_nstem, "D%04X.ADF", slots[0].adapter_id);
   parse_defsym (adf_stem);

   for (slot = 0; slot < MAX_SLOTS; slot++)
   {  /* Default choice to current CMOS values */
      memcpy (slots[slot].choice_pos, slots[slot].cmos_pos, sizeof (slots[0].cmos_pos));

      slots[slot].adapter_name = "\0";
      slots[slot].num_mem_devices = 0;
      slots[slot].exec = FALSE;

      /* Check for a board in the slot and not disabled */
      if ((slot < MAX_ASLOTS) &&
	  (slots[slot].adapter_id != 0xFFFF) &&
	  (slots[slot].adapter_pos[0] & 0x01))
      {  /* Construct the ADF file name */

	  sprintf (adf_stem+adf_nstem, "%c%04X.ADF", slot ? '@' : 'P',
			slots[slot].adapter_id);

	  if (isinlist (AdfSkip, AdfSkipU, slots[slot].adapter_id)) {

	     /* Ignoring certain devices because the ADF file is built into */
	     /* the SC program */
	     slots[slot].init_state = NOMEM;
	     slots[slot].cmos_pos[0] = 0x01; /* Mark as enabled */
	     slots[slot].numbytes = 0;	/* ...with no POS values */
	     slots[slot].adapter_name = MsgBuiltIn; /* Built-in adapter */

	  } /* End if (skip this one) */
	  else {

	  /* Attempt to _open the ADF file */
	  if ((Adf = fopen (adf_stem, "rt")) != NULL) /* Get adapter name */
	  {   slots[slot].adapter_name = get_adapter_name ();
	      slots[slot].numbytes = get_numbytes (); /* Get numbytes */

	      /* Scan for the CMOS selection */
	      if (find_cmos_choice (slot) == FALSE /* If not found, */
	       && !slots[slot].exec) {		/* ...and not an ADP file */
		  sprintf (buff, MsgFindCmos2, adf_stem);  /* ADF Name: %s */
		  error_adap (MsgFindCmos1, buff, NULL, TRUE); /* Display error messages and abort */
	      } /* End IF */

	      rewind(Adf);	  /* Reset ADF for building choices */

	      /* If the device has memory or has an ADP build the choice list */
	   /* if (slots[slot].num_mem_devices > 0 || slots[slot].exec) */
		  /* Build the choice list */
	      {   build_choices (slot);

		  /* If the device has an ADP, process it */
		  if (slots[slot].exec)
		      process_exec ();
	      } /* End IF */

	      /* Set initial state */
	      set_istate (slot); /* Check on certain ADFs initial state */

	      fclose (Adf); /* Finished with ADF, release it */

	  } /* End IF no ADF file */
	  else
	  {
		/* Unable to find ADF file for %s. */
		/* Find the most recent working copy of your Reference */
		/* disk and re-run MAXIMIZE. */
		sprintf (buff, MsgFindAdf1, adf_stem);
		error_adap (buff, MsgFindAdf2, MsgFindAdf3, TRUE); /* Display error message and abort */
	  } /* End ELSE */
	  } /* End ELSE (not in skip list) */
      } /* End IF */
   } /* End FOR */

   if (Last_device		/* If there are any adapters in the system, */
    && Last_device->List == NULL /* and last device processed did not use memory */
    && Last_device->Devflags.Ems_device == FALSE /* and it wasn't the EMS page frame */
    && Last_device->Next	/* and there is a preceding device */
    && Last_device->slot == Last_device->Next->slot /* and it's same as previous */
      )
       Last_device = Last_device->Next;  /* then, release this device */

   if (Last_device == NULL)	/* If no adapters in the system, return */
       return (TRUE);

/*analyze();*/			/* Analyze the current data structures */

   return (TRUE);

} /* End READ_ADF */

/*********************************** SET_ISTATE *******************************/
/* Set the initial state for an adapter
   The states are as follows:

     0 = disabled
     1 = no memory
     2 = static
     3 = maximize

   An adapter is marked disabled if that's what CMOS says.

   An adapter is marked with no memory, if its ADF file defines
      no memory actions.

   Adapters whose initial state is static include

   * Any ADF with the characters "3270" in the title:  these files
     typically require that the user make a corresponding change on the
     command line of the associated software driver.

   * ADF 6001 (Tiara LANCARD):	This adapter requires that the selected
     ROM address have matching IO and IRQ changes not reflected in the
     ADF file.

   * Other adapters specified as AdfStatic (by default or via the
     ADFSTATIC keyword in the MAXIMIZE.CFG file).  Temporarily, the
     system board is STATIC by default.

   Otherwise, the initial state is MAXIMIZE.

 */
#pragma optimize("leg",off)
void set_istate (int slot)

{
   if (!slots[slot].cmos_pos[0] & 0x01)
       slots[slot].init_state = DISABLED;
   else
   if ((strstr (slots[slot].adapter_name, "3270")) != NULL)
   {   slots[slot].init_state = STATIC;
       slots[slot].help_static = Static3270;
   }
   else
   if (slots[slot].adapter_id == ADID_TIARA) /* If Tiara LAN*Card, mark as */
				/* NOMEM if PROM disabled, STATIC otherwise */
   {   slots[slot].init_state = (slots[slot].cmos_pos[0] & 0x02) ? STATIC : NOMEM;
       slots[slot].help_static = Static6001;

       /* If the PROM is disabled, clear the CMOS and choice list */
       if (slots[slot].init_state == NOMEM)
	   Last_device->List = Last_device->Cmos = NULL;
   } /* Tiara card */
   else if (slots[slot].num_mem_devices || slots[slot].exec) {
       if (isinlist (AdfStatic, AdfStaticU, slots[slot].adapter_id)) {
	       slots[slot].init_state = STATIC;
	       slots[slot].help_static = StaticUser;
       }
       else {
	       slots[slot].init_state = MAXIMIZE;
       }
   } /* Card has memory or EXEC */
   else {
	slots[slot].init_state = NOMEM;
   } /* Good for nothing */

} /* End SET_ISTATE */
#pragma optimize("",on)

/******************************** PROCESS_ADPITEM *****************************/
/* Process AdpItem [n] Prompt "prompt string" [Exec] help */
/* If Exec is present, add_device() and return 1, otherwise 0. */
int process_adpitem (void)
{
  int iRetVal = 0;

  while (get_token ()) {

    if (!_stricmp (TempBuffer, "exec") && !iRetVal) {

	iRetVal = 1;
	add_device ();
	/* Ignore EXEC on system board */
	slots[slot].exec = (BYTE) slot; /* Set flag for ADP exec */
	matched = TRUE; /* Force CMOS match */

    } /* Found Exec */

    if (!_stricmp (TempBuffer, "help"))
	break;

  } /* Not EOF */

  return (iRetVal);

} /* process_adpitem () */

/******************************** BUILD_CHOICES *******************************/
/* Build the linked list of adapter choices */

void build_choices (BYTE slot)

{
   char nameditem = 0;
   conflict = FALSE;
   init_tmp_ad ();
   memcpy (&fix_ad, &tmp_ad, sizeof (fix_ad));

   while (get_token ())
   {  if (strcmp (TempBuffer, "fixedresources") == 0)
      {   process_fixed (slot);
	  memcpy (&fix_ad, &tmp_ad, sizeof (fix_ad));
      } /* End IF */
      else
      if (strcmp (TempBuffer, "nameditem") == 0)
      {
	  nameditem = 1;		/* Mark as found */
	  process_nameditem (FALSE, slot);
      } /* End IF */
      else
      if (strcmp (TempBuffer, "adpitem") == 0)
      {
	  if (process_adpitem ()) nameditem = 1;
      } /* End IF AdpItem */
   } /* End WHILE */

   if (!nameditem)			/* If no named item found as yet, */
	 add_device();			/* ...add the device anyway so it */

   if (conflict) /* Resolve a choice conflict */
       resolve_conflict ();
} /* End BUILD_CHOICES */

/******************************* FIND_CMOS_CHOICE *****************************/
/* Process the ADF file scanning for the CMOS selected data */

BOOL find_cmos_choice (BYTE slot)

{
   char nameditem = 0;
   matched = FALSE;
   num_matches = 0;
   init_tmp_ad ();
   memcpy (&fix_ad, &tmp_ad, sizeof (fix_ad));

   while (get_token ())
   {  if (strcmp (TempBuffer, "fixedresources") == 0)
      {   process_fixed (slot);
	  memcpy (&fix_ad, &tmp_ad, sizeof (fix_ad));
      } /* End IF */
      else
      if (strcmp (TempBuffer, "nameditem") == 0)
      {
	  nameditem = 1;		/* Mark as found */
	  process_nameditem (TRUE, slot);
      } /* End IF */
/***	  else
      if (strcmp (TempBuffer, "sysmem") == 0)
	  return (TRUE);
***/
      else
      if (strcmp (TempBuffer, "adpitem") == 0)
      {
	  if (process_adpitem ()) nameditem = 1;
      } /* End IF AdpItem */

   } /* End WHILE */

   if (matched == FALSE)		/* If we didn't find a match, */
   if (!nameditem)			/* ...and there were no nameditems, */
       matched = TRUE;			/* ...call it a match (nothing there) */
   else 				/* ...otherwise */
       matched = cmos_match (slot);	/* ...try a match on the last entry */

   return (matched);

} /* End FIND_CMOS_CHOICE */

/******************************* PROCESS_FIXED ********************************/

void process_fixed (BYTE slot)
{
   init_tmp_ad ();
   process_values (TRUE, slot);
} /* End PROCESS_FIXED */

/******************************* PROCESS_NAMEDITEM ****************************/

void process_nameditem (BOOL first_pass, BYTE slot)

{  struct _adf_choice *A, *B, **Aptr;
   struct _device *D;
   int i;

   if (first_pass == FALSE)
	add_device();

   while (get_token ())
   {  if (strcmp (TempBuffer, "choice") == 0)
      {   memcpy (&tmp_ad, &fix_ad, sizeof (fix_ad));
	  process_values (FALSE, slot);

	  if (first_pass == TRUE)
	  {   if (cmos_match (slot) && !slots[slot].exec)
	      {   matched = TRUE;
		  if (tmp_ad.mem[0][0] > 0L
		   && num_matches < MAX_MATCHES)
		  {   slots[slot].num_mem_devices++;
		      memcpy (&match[num_matches], &tmp_ad, sizeof(match[0]));
		      num_matches++;
		  } /* End IF */
	      } /* End IF */
	  } /* End IF */
	  else
	  if (tmp_ad.mem[0][0] > 0L
	   && valid_choice ())
	  {   add_choice ();
	      if (cmos_match (slot))
		  Last_device->Cmos = Last_device->List;
	  } /* End IF */
      } /* End IF */

      if (strcmp (TempBuffer, "help") == 0)
	  break;
   } /* End WHILE */

   /* If we're finished with the second pass and there's no CMOS choice, */
   /* release the List values. */
   /* If there is a CMOS choice, ensure all List choices have the same length */
   if (first_pass == FALSE)
   if (Last_device->Cmos == NULL)
   {   for (A = Last_device->List; A != NULL; A = B)
       {    B = A->Next;		/* Save before we free */
	    free_mem (A);			/* Free the ADF choice entry */
       } /* End FOR */

       Last_device->List = NULL;	/* Clear the List choice entry */

       /* Finally, if the preceding device is in the same slot, and */
       /* has neither CMOS not List choices, release this one, too. */
       D = Last_device->Next;
       if (D != NULL && Last_device->slot == D->slot)
       {   free_mem (Last_device);
	   Last_device = D;
       } /* End WHILE/IF */
   } /* End IF */
   else  /* Otherwise, ensure all List choices have the same length */
   {   for (A = Last_device->List, Aptr = &Last_device->List;
	    A != NULL;
	    A = B)
       {    B = A->Next;		/* In case we free it */

	    /* Ensure all lengths match */
	    for (i = 0; i < MAX_RANGES; i++)
	    if ((A->mem 	       [i][1] - A->mem		      [i][0])
	     != (Last_device->Cmos->mem[i][1] - Last_device->Cmos->mem[i][0]))
	    {	*Aptr = B;		/* De-link this entry */
		free_mem (A);		/* Free the ADF choice entry */
		break;			/* Exit the FOR statement */
	    } /* End IF */
	    else
		Aptr = &A->Next;	/* Point to next entry's address */
       } /* End FOR */
   } /* End ELSE */

} /* End PROCESS_NAMEDITEM */

/********************************* PROCESS_VALUES *****************************/
/* Scan ADF for pos, io, int, arb, mem and exec keywords */

void process_values (BOOL fixed_flag, BYTE slot)

{
   while (get_token ())
   {  if (strcmp(TempBuffer, "pos") == 0)
	  pos_values (slot);
      else
      if (strcmp (TempBuffer, "io") == 0)
	  range_values (tmp_ad.io_addr, &tmp_ad.iocnt, 0, 0xffffffffL);
      else
      if (strcmp (TempBuffer, "int") == 0)
	  int_values   (tmp_ad.int_lvl,  &tmp_ad.intcnt);
      else
      if (strcmp (TempBuffer, "arb") == 0)
	  int_values   (tmp_ad.arb,	   &tmp_ad.arbcnt);
      else
      if (strcmp (TempBuffer, "mem") == 0)
      {   range_values (tmp_ad.mem,	   &tmp_ad.memcnt, 1, sysroml);
	  tmp_ad.Afixed = fixed_flag;
      } /* End IF */
      else
      if (strcmp (TempBuffer, "exec") == 0)
      {   memcpy (slots[slot].exec_pos_mask, tmp_ad.pos_mask, sizeof(slots[0].exec_pos_mask));
	  matched = TRUE;		/* Force a CMOS match */
	/* Ignore EXEC on system board */
	  slots[slot].exec = (BYTE) slot; /* Set flag for ADP exec */
      } /* End IF */
      else
      {
	 unget_token = TRUE;
	 break;
      } /* End ELSE */
   } /* End WHILE */

} /* End PROCESS_VALUES */

/*********************************** POS_VALUES *******************************/
/* Process an ADF pos keyword */

void pos_values (BYTE slot)

{  BYTE pos_index=0xff;
   WORD index_tmp;

   get_token ();
   /* POS values range from 0 - 31 */
   if (
	sscanf (TempBuffer, "%u", &index_tmp) == 1 &&
	index_tmp < MAX_POS
							)
       pos_index = (BYTE) index_tmp;

   while (get_token ())
   if ((strchr ("01x", TempBuffer[0])) != NULL)
   {
	if (pos_index != 0xff) {
		tmp_ad.pos_mask[pos_index][0] |= make_posmask (TempBuffer, '0');
		tmp_ad.pos_mask[pos_index][1] |= make_posmask (TempBuffer, '1');
		break;
	}
	else return;
   } /* End WHILE/IF */

   /* Because we can't rely upon the actual value of numbytes in */
   /* the ADF file, we use the larger of the ADF value and the */
   /* maximum POS index+1 */
   slots[slot].numbytes = max (slots[slot].numbytes, (BYTE) (pos_index + 1));

} /* End POS_VALUES */

/********************************** RANGE_VALUES ******************************/
/* Process an ADF keyword that uses dword ranges */
/* Reject range if either start or end is above maxval */
void range_values (DWORD range[][2], BYTE *index, WORD flag, DWORD maxval)

{  int n;
   DWORD val;

   n = 0;
   while (get_token ())
   {  if (valid_number ())
      {  if (*index >= MAX_RANGES)
	     if (flag == 1)
		error_adap (MsgRangeValErr, NULL, NULL, TRUE); /* Mismatched range value */
	     else
		flag = 2;

	 if (flag != 2) {
		if (strchr (TempBuffer, 'h') != NULL)
			scanlhex (TempBuffer, &val);
		else
			scanldec (TempBuffer, &val);

		if (val < maxval) {
			range[*index][n] = val;
			(*index) += n;
		} /* Range value is valid */
		else if (!n) {	/* Skip remainder of bogus range */
			n++;
			if (!get_token ())	break;
		} /* Range value is invalid */
	}

	n ^= 0x01;	/* Flip between 0 and 1 */

      } /* End IF */
      else
	 break;
   } /* End WHILE */

   if (n != 0)
       error_adap (MsgRangeValErr, NULL, NULL, TRUE); /* Display error and abort */

   unget_token = TRUE;

} /* End RANGE_VALUES */

/*********************************** INT_VALUES *******************************/
/* Process an ADF keyword that uses int ranges */

void int_values (BYTE level[], BYTE *index)

{
   while (get_token ())
   {  if (valid_number ())
      {  if (*index >= MAX_RANGES)
	     error_adap (MsgTooMany, NULL, NULL, TRUE); /* Error, too many int values */
	 if ((strchr (TempBuffer, 'h')) != NULL)
	     scanhex (TempBuffer, (WORD *) &level[*index]); /* Scan off hex WORD */
	  /* sscanf (TempBuffer, "%x", &level[*index]); */
	 else
	     level[*index] = (BYTE) atoi (TempBuffer);
	 (*index)++;
      } /* End IF */
      else
	 break;
   } /* End WHILE */

   unget_token = TRUE;

} /* End INT_VALUES */

/*********************************** GET_RAWTOKEN *****************************/
/* Get token using specified separators. */
/* Put parsed token into TempBuffer, return FALSE if EOF encountered. */
/* If " is not included in pszSeps, discard all quoted strings. */
BOOL get_rawtoken (char *pszSeps)
{
  int c,n;

   while ((c = fgetc(Adf)) != EOF)
   {   if (c == '"' && !strchr (pszSeps, '"'))
       {   while ((c = fgetc (Adf)) != EOF && (c != '"'))
		;
	   if ((c = fgetc (Adf)) == EOF)
	       return (FALSE);
      } /* End IF */

      if (c == ';')
	  while ((c = fgetc (Adf)) != EOF && (c != '\n'))
	       ;
      if ((strchr (pszSeps, c)) == NULL)
      {   n = 1;
	  TempBuffer[0] = (BYTE) c;
	  while ((c = fgetc (Adf)) != EOF && (n < sizeof (TempBuffer)))
	  {  if ((strchr (pszSeps, c)) != NULL)
	     {	TempBuffer[n] = '\0';
		LastBreak = c;
		_strlwr (TempBuffer);
		return (TRUE);
	     } /* End IF */

	     TempBuffer[n++] = (BYTE) c;
	  } /* End WHILE */
      } /* End IF */
   } /* End WHILE */

   return(FALSE);		/* We've reached EOF */

} /* get_rawtoken () */

/**************************** ELIM_EXP **********************************/
/* Eliminate subexpression */
void elim_exp (int *piOps, int *pcOps)
{
  int iTemp;

  if (*pcOps < 3) return;

  switch (piOps[1]) {

    case EQ:
	iTemp = (piOps[0] == piOps[2]);
	break;

    case NE:
	iTemp = (piOps[0] != piOps[2]);
	break;

    case LT:
	iTemp = (piOps[0] <  piOps[2]);
	break;

    case GT:
	iTemp = (piOps[0] >  piOps[2]);
	break;

    case LE:
	iTemp = (piOps[0] <= piOps[2]);
	break;

    case GE:
	iTemp = (piOps[0] >= piOps[2]);
	break;

    case AND:
	iTemp = (piOps[0] && piOps[2]);
	break;

    case OR:
	iTemp = (piOps[0] || piOps[2]);
	break;

    case XOR:
	iTemp = (piOps[0] ^  piOps[2]);
	break;

    default:
	iTemp = (piOps[0]);
	break;

  } /* switch () */

  piOps[0] = iTemp;
  *pcOps = 1;

} /* elim_exp () */

/**************************** EVAL_EXP **********************************/
/* Evaluate infix expression, left to right, no operator precedence. */
/* This function calls itself recursively for n levels of nested */
/* parens. */
/* The Adf input stream is positioned at the first character following */
/* the opening (. */
int eval_exp (void)
{
  int iaVals[3] = {0,NOP,0};
  int iValIdx = 0;
  int c, n;

  while ((c = fgetc (Adf)) != EOF) {

    switch (c) {

	case ' ':
	case '\t':
	case '\n':
	case '\r':

	/* Note that if we have a nested expression, it'll get handled */
	/* in the '(' case.  This means we're done. */
	case ')':
		break;

	case '(':
		iaVals [iValIdx++] = eval_exp ();
		break;

	/* We have a constant (decimal), an operator, or a symbol. */
	default:
		n = 0;
		TempBuffer [n++] = (BYTE) c;

		while ((c = fgetc (Adf)) != EOF) {

		  if (strchr (" )\t\n\r", c)) {

			TempBuffer [n] = '\0';
			_strlwr (TempBuffer);

			if (!check_sym (TempBuffer, 0, &(iaVals[iValIdx]))) {
			  sscanf (TempBuffer,
				(strchr (TempBuffer,'h') != NULL) ? "%x" : "%d",
				&(iaVals[iValIdx]));
			} /* Didn't find a symbol or operator */

			iValIdx++;
			break;

		  } /* Got the end */
		  else	TempBuffer [n++] = (BYTE) c;

		} /* Get token characters */
		break;

    } /* switch () */

    if (c == ')') break;

    elim_exp (iaVals, &iValIdx);

  } /* not EOF */

  elim_exp (iaVals, &iValIdx);

  return (iaVals[0]);

} /* eval_exp () */

/*********************************** GET_TOKEN ********************************/
/* Get the next token from the ADF file */
/* This is where we'll evaluate if () { } else { } */
/* Whenever we're asked to get a token and the value is IF, */
/* we'll evaluate the following infix expression. */
/* We then get the next token.	If the evaluation was false */
/* we'll skip the next expression or block.  If true, */
/* we need to execute the next expression but skip else */
/* (if present) with its associated expression or block. */
/* Yet another interesting wrinkle is that expressions */
/* can only be identified by parsing.  Both of the following */
/* are single expressions: */
/*
IF (Model EQ F8)
   pos[0] = 0XX10XXXb
	int 0ah
	arb 3
	mem 0fffe000h - 0ffff000h
ELSE
   choice "B000h, 11MB"
	pos[3] = XXXX1011b
	mem 0B00000h - 0Bfffffh
*/
/* If the conditional block begins with a { there's no problem. */
/* If it starts with pos, we need to find the next pos, else, or */
/* address (end of FixedResources).  If it starts with choice, */
/* look for choice, NamedItem, Help, or end. */

BOOL get_token (void)

{  int c;
   int bExpRes;
   char paTemp[128];
   static char break_char [] = " \n\t=[-(";
   static char *pszClosing;

   if (unget_token)	/* Check for reuse of last token */
   {   unget_token = FALSE;
       return (TRUE);
   } /* End IF */

   if (get_rawtoken (break_char) == FALSE)
	return (FALSE); /* Encountered EOF */

   if (_stricmp (TempBuffer, "if")) {

     /* Note that we don't care about block endings (}). */
     if (_stricmp (TempBuffer, "else"))
	return (TRUE); /* Not an else-expression either */

     /* If an else-expression wasn't parsed along with the if-expression, */
     /* the expression evaluated to true, we executed the if-expression, */
     /* and we need to skip the else-expression. */
     bExpRes = FALSE; /* Skip expression */
     goto GT_NEXT; /* Join common if-expression code */

   } /* Not a conditional expression */

   /* Evaluate the parenthetical expression */
   while ((c = fgetc (Adf)) != EOF && c != '(') ;
   if (c == EOF)
	return (FALSE);

   bExpRes = eval_exp ();

   /* Get the next statement. */
   /* Note that we don't handle nested conditionals.  It's a safe bet */
   /* that SC doesn't, either. */
GT_NEXT:
   if (get_rawtoken (break_char) == FALSE)
	return (FALSE);

   if (strcmp (TempBuffer, "{")) {

	if (!_stricmp (TempBuffer, "pos"))
	  pszClosing = " pos else address ";
	else
/*	  if (!_stricmp (TempBuffer, "choice")) */
	    pszClosing = " choice nameditem help end ";
/*	  else ???; */

   } /* Not a block; determine possible endings */
   else {

	pszClosing = " } ";

	/* Get actual token */
	if (get_rawtoken (break_char) == FALSE)
	  return (FALSE);

   } /* Got a block start */

   if (bExpRes)
	return (TRUE);

   /* Skip until we find a closing expression */
   /* Note that all closing expression, including } but excepting else, */
   /* will be processed as the actual token. "else" requires that we */
   /* get the next token. */
   while (get_rawtoken (break_char)) {

	sprintf (paTemp, " %s ", TempBuffer);

	if (strstr (pszClosing, paTemp)) {

	  if (!_stricmp (TempBuffer, "else"))
		return (get_rawtoken (break_char));
	  else
		return (TRUE);

	} /* Found closing expression */

   } /* while not EOF */

   return (FALSE); /* End of file encountered */

} /* End GET_TOKEN */

/****************************** GET_ADAPTER_NAME ******************************/
/* Scan for the adapter name keyword and save the adapter name */

char *get_adapter_name (void)

{  int c, i;
   char buff[MAX_ADP_NAME + 1];

   while (get_token ())
   if (strcmp (TempBuffer, "adaptername") == 0)
   {   while ((c = fgetc (Adf)) != EOF && (c != '"'))
	    ;
       i = 0;
       while ((c = fgetc (Adf)) != EOF && (c != '"') && i < MAX_ADP_NAME)
	      buff[i++] = (BYTE) c;
       buff[i] = '\0';
       return (str_mem(buff));
   } /* End WHILE/IF */
} /* End GET_ADAPTER_NAME */

/********************************* GET_NUMBYTES *******************************/
/* Scan the ADF for the numbytes keyword and save */

BYTE get_numbytes (void)

{  int c;

   while (get_token ())
   if (strcmp (TempBuffer, "numbytes") == 0)
   {   while ((c = fgetc (Adf)) == ' ')
	    ;
       return ((BYTE) (c & 0x0F));
   } /* End WHILE/IF */
} /* End GET_NUMBYTES */

/*********************************** MAKE_POSMASK *****************************/
/* Create a POS mask */

BYTE make_posmask (char *Bin, char mask_type)

{
   BYTE mask;
   char *Err;
   char buff[100];

   mask = 0;
   Err = Bin;

   while (*Bin && ((strchr ("x10", *Bin)) != NULL))
   {	  mask = (BYTE) (mask << 1);
	  if (*Bin == mask_type)
	      mask |= 1;
	  Bin++;
   } /* End WHILE */

   if (*Bin != 'b' && *Bin != '\0')
   {   sprintf(buff, MsgErrPosMask, Bin); /* Error while processing POS MASK:  %s */
       error_adap (buff, NULL, NULL, TRUE); /* Display error and abort */
   } /* End IF */

   return(mask);

} /* End MAKE_POSMASK */

/********************************** READPOS ***********************************/
/* Get POS values when ABIOS functions are not available */

void readpos (void)

{  int slot, i;

   for (slot = 0; slot < MAX_ASLOTS; slot++)
   {	slots[slot].adapter_id = PosData[slot].id;

	if (slots[slot].adapter_id != 0xFFFF) {

		for (i = 0; i < MAX_CPOS; i++)
		{    slots[slot].cmos_pos[i] = PosData[slot].cmos[i];
		     slots[slot].adapter_pos[i] = AdapPosData[slot].pos[i];
		} // End FOR

	} /* Adapter is present */

   } /* End FOR */

} /* End READPOS */

/******************************** READ_SYSPOS ********************************/
/* Read POS values from system board directly from NVRAM. */
/* This is not supported at all by the ABIOS. */

void read_syspos (void)
{
  int i;

  /* For some reason, the system board with ID FBFF (56SX) doesn't support */
  /* 32 bytes of POS in the NVRAM... */
  if (slots[0].adapter_id != 0xFBFF) {
	for (i=0; i < MAX_POS; i++) {
		slots[0].cmos_pos[i] = readpos32 (NVRAM_SYSPOS+i);
	} /* End for () */
  } /* End if () */

} /* End read_syspos () */

/********************************** SET_POSDIR ********************************/
// Set the PosDir variable based upon BIOS dates and other animal entrails.

/********
   Recognize Reply systems with BIOS Model F8, E2, 00 of date
   preceding 7/93 as having a broken BIOS.  In particular, the POS
   _write function we use in 386MAX.SYS doesn't work because the BIOS
   uses the wrong registers to set the CMOS.  For these systems, we
   need to _write to the CMOS directly which is what PosDir indicates.
   Moreover, we don't want to use the poswrite code here so we don't
   have to maintain two versions of the workaround, so we force use of
   the POSFILE.BIN mechanism later on if PosDir is set.
 ********/

void set_posdir (void)

{
   if (BIOSDate[0] < 93 ||
       ((BIOSDate[0] == 93) && (BIOSDate[1] < 7)))
      PosDir |= (BIOSConf[2] == 0xF8) && (BIOSConf[3] == 0xE2);
} // End SET_POSDIR

/********************************** WRITE_POS *********************************/
/* Write new POS values if ABIOS available, else */
/* create file with values for 386MAX to _write out later */

void write_pos (void)

{  unsigned int slot, n, fh = -1, posbytes;
   char csumflag = 0, newflag = 0, buff[128], buff2[128];
   WORD buff_posbytes, buff_len;
   char *p;

   set_posdir();		// Set PosDir as appropriate

   for (slot = 0; slot < MAX_ASLOTS; slot++)
   {
   posbytes = MAX_CPOS < slots[slot].numbytes ? MAX_CPOS : slots[slot].numbytes;
   if (slots[slot].adapter_id == 0xFFFF
    || slots[slot].cur_state != MAXIMIZE
    || memcmp (slots[slot].cmos_pos, slots[slot].choice_pos, sizeof(slots[0].cmos_pos)) == 0)
	continue;
#ifdef DEBUG
     if (VERBOSE) {
	printf("Reconfiguring slot %d %s\n",slot+1,slots[slot].adapter_name);
	printf("   Old pos: %02X %02X %02X %02X  New pos:  %02X %02X %02X %02X\n",
		slots[slot].cmos_pos[0],slots[slot].cmos_pos[1],
		slots[slot].cmos_pos[2],slots[slot].cmos_pos[3],
		slots[slot].choice_pos[0],slots[slot].choice_pos[1],
		slots[slot].choice_pos[2],slots[slot].choice_pos[3]);
	press_any();
     }
#endif
       for (n = 0; n < posbytes; n++)
	    slots[slot].adapter_pos[n] = slots[slot].choice_pos[n];
       for (	 ; n < MAX_CPOS; n++)
	    slots[slot].adapter_pos[n] = slots[slot].choice_pos[n] = 0;

	/*** Even if the ABIOS is present, we'll use the POSFILE mechanism
	 *   to make changes to system POS values.  This allows us to keep
	 *   all the really dirty system specific code to manually recalculate
	 *   the NVRAM CRC for the Model 56 486SLC2 up in QMAX_POS.ASM.
	***/
       if ((!PosDir) && abios && slots[0].numbytes <= MAX_CPOS)
       {
	   poswrite (slot, slots[slot].choice_pos, slots[slot].adapter_pos,
		     &slots[slot].adapter_id);
	   csumflag = 1;		/* Mark as needing NVRAM checksum recomputation */
       } /* End IF */
       else	 /* Otherwise, _write out NEWPOS file */
       {   if (!newflag)		/* If we've not created the file as yet */
	   {   strcpy (buff, ProfileBoot); /* Start with the profile path */
					/* (including drive letter) */
	       strcat (buff, NEWPOS);	/* Followed by the filename.ext */
	       disable23 ();
	       if (createfile (buff) == -1
		|| -1 == (fh = _open (buff, O_WRONLY|O_BINARY)))
		   error_newpos (MsgUnaCreate); /* Unable to create %s. */
	       enable23 ();

	       newflag = 1;		/* Mark as created and opened */
	   } /* End IF */

	   /* Setup buffer with slot # and new POS values */
	   /* Note that 32 bytes of POS are supported by ADP files, but */
	   /* the maximum supported by the ABIOS is 4.	If direct _write */
	   /* to NVRAM is needed, we set bit 7 in the slot number. */
	   /* MAX will also support writes to any NVRAM index; see */
	   /* FCN_POSFILE in QMAX_FCN.ASM for details. */
	   buff[0] = (char) (slot);
	   if (PosDir && slot)	// If we're writing to the POS directly, and
	   {			// it's not slot 0, use the PosDir_str format.
				// Note we skip over (2+1) the two-byte
				// adapter ID and the numbytes value in CMOS.

#define PosDirBuff ((struct PosDirStr *) &buff)

	       PosDirBuff->slot |= 0x40;
	       PosDirBuff->index = (2+1) + (0x23 * (slot - 1));
	       buff_posbytes = PosDirBuff->numbytes = slots[slot].numbytes;
	       // Length of buffer to _write
	       buff_len = sizeof(struct PosDirStr)	// The whole struct
			  - sizeof(PosDirBuff->data)	// Less pseudo-data size
			  + buff_posbytes;		// Plus actual # bytes
	       p = &PosDirBuff->data[0];		// Start of data
	   } // End IF
	   else
	   {   if (!slot && Pos32 && slots[slot].numbytes > MAX_CPOS) {
		    buff[0] |= 0x80;
		    buff_posbytes = MAX_POS;	// Length of POS data
	       }
	       else buff_posbytes = MAX_CPOS;	// Length of POS data
	       buff_len = 1 + buff_posbytes;	// Length of buffer to _write
	       p = &buff[1];			// Start of data
	   } // End ELSE

	   for (n = 0; n < buff_posbytes; n++)
		p[n] = slots[slot].choice_pos[n];

	   /* Write out the buffer to NEWPOS file */
	   disable23 ();
	   if (_write (fh, buff, buff_len) < 0)
	       error_newpos (MsgUnaWrite); /* Unable to _write to %s. */
	   enable23 ();
       } /* End ELSE */
   } /* End FOR/IF */

   /* Recompute NVRAM checksum if needed */
   if (csumflag)
       nvramcheck ();

   /* Close the NEWPOS file if opened */
   if (newflag)
   {   buff[0] = '\xff';		/* Write trailing marker */
       if (_write (fh, buff, 1) < 0)
	   error_newpos (MsgUnaWrite); /* Unable to _write to %s. */
       if (_close (fh) < 0)
	   error_newpos (MsgUnaClose); /* Unable to _close %s. */

#ifdef STACKER
	if (SwappedDrive > 0) {

		sprintf (buff, "%s%s", ProfileBoot, NEWPOS);
		strcpy (buff2, buff);
		buff2[0] = CopyMax1;
		(void) copy (buff, buff2);
		if (CopyMax2) {
			buff2[0] = CopyMax2;
			(void) copy (buff, buff2);
		}

	} // Update swapped drive with POSFILE.BIN
#endif			/* ifdef STACKER */

       /* POSFILE=%s%s ; Write out POS values */
       /* Use the original profile path (may not have a drive letter) */
       sprintf (buff, MsgPosFilEqu, ProfilePath, NEWPOS);
       add_to_profile (POSFILE, buff, 0L, 0L);
   } /* End IF */

} /* End WRITE_POS */

/********************************* ERROR_NEWPOS *******************************/
/* Write out NEWPOS error message and quit */

void error_newpos (char *text)

{  char buff[80];

   sprintf (buff, text, LoadString, NEWPOS);
   error_adap (buff, NULL, NULL, TRUE); /* Display error message and abort */

} /* End ERROR_NEWPOS */

/******************************** READPOS_ABIOS *******************************/
/* Get the POS values using the BIOS functions */

void readpos_abios (void)

{  int slot;

   for (slot = 0; slot < MAX_ASLOTS; slot++)
   {	posread (slot, slots[slot].cmos_pos, slots[slot].adapter_pos,
		 &slots[slot].adapter_id);
	adapter_id_list[slot] = slots[slot].adapter_id; /* Id list for exec */
   } /* End FOR */
} /* End READPOS_ABIOS */

/********************************** SET_ADAPID ********************************/
/* Setup adapter ID list */

void set_adapid (void)

{  int slot;

   for (slot = 0; slot < MAX_ASLOTS; slot++)
	adapter_id_list[slot] = slots[slot].adapter_id; /* Id list for exec */

} /* End SET_ADAPID */

/********************************* VALID_NUMBER *******************************/

BOOL valid_number (void)

{  char *T;

   if ((strchr (TempBuffer, 'h')) != NULL)
   {   T = TempBuffer;
       while (*T)
       {      if (*T != 'h' && isxdigit (*T) == 0)
		  return (FALSE);
	      T++;
       } /* End WHILE */
   } /* End IF */
   else
   {  T = TempBuffer;
      while (*T)
      {      if (isdigit (*T) == 0)
		 return (FALSE);
	     T++;
      } /* End WHILE */
   } /* End ELSE */

   return (TRUE);
} /* End VALID_NUMBER */

/********************************* INIT_TMP_AD ********************************/
/* Initialize the temp adapter data structure */

void init_tmp_ad (void)

{
   memset (&tmp_ad, 0, sizeof (tmp_ad));
   tmp_ad.Afixed = FALSE;
   tmp_ad.Next = NULL;

} /* End INIT_TMP_AD */

/********************************* CMOS_MATCH *********************************/
/* Check the CMOS POS values for a match */
/* In particular, for NUMBYTES POS values, the selected 0s and 1s */
/* must match the actual CMOS values. */

BOOL cmos_match (BYTE slot)

{  BYTE n, t0, t1;

   for (n = 0; n < slots[slot].numbytes; n++)
   {	t0 = tmp_ad.pos_mask[n][0];	/* Get forced 0s */
	t1 = tmp_ad.pos_mask[n][1];	/* ...	      1s */

	if (((t0 | t1) & slots[slot].cmos_pos[n]) != t1)
	    return (FALSE);
   } /* End FOR */

   return(TRUE);
} /* End CMOS_MATCH */

/******************************** VALID_CHOICE ********************************/
/* Determine if temp adapter has valid data */

BOOL valid_choice (void)

{  unsigned int m;
   struct _adf_choice *A;

   for (m = 0; m < tmp_ad.memcnt; m++)
   if (tmp_ad.mem[m][0] >= sysroml
    || tmp_ad.mem[m][1] >= sysroml)
       return (FALSE);

   for (m = 0; m < num_matches; m++)
   if (0 == memcmp (&match[m].io_addr, &tmp_ad.io_addr, sizeof (tmp_ad.io_addr))
    && 0 == memcmp (&match[m].arb,     &tmp_ad.arb,	sizeof (tmp_ad.arb))
    && 0 == memcmp (&match[m].int_lvl, &tmp_ad.int_lvl, sizeof (tmp_ad.int_lvl)))
   {   for (A = Last_device->List; A != NULL; A = A->Next)
       if (memcmp (tmp_ad.mem, A->mem, sizeof (tmp_ad.mem)) == 0)
       {   conflict = TRUE;
	   break;
       } /* End FOR/IF */

      return (TRUE);
   } /* End FOR/IF */

   return (FALSE);	/* (m == 0); */
} /* End VALID_CHOICE */

/********************************* ADD_DEVICE *********************************/
/* Add a device to the device linked list */

void add_device (void)

{  struct _device *D, *A;

   if (Last_device != NULL		/* If there's a previous device */
    && Last_device->List == NULL	/* and it had no choices */
    && Last_device->slot == slot	/* and it was in the same slot */
    && Last_device->Devflags.Ems_device == FALSE) /* and it wasn't the EMS device */
   {   D = Last_device; 		/* then, re-use its structure */
       A = D->Next;			/* Save next pointer */
       memset (D, 0, sizeof (*D));	/* Clear the structure to zero */
       D->Next = A;			/* Restore the next pointer */
   } /* End IF */
   else 				/* Otherwise, allocate new memory */
   {   D = get_mem (sizeof (struct _device));

       /* Link new memory into the device chain */
       D->Next = Last_device;
       Last_device = D;
   } /* End IF/ELSE */

   D->slot = slot;
/* D->Devflags.Dfixed = FALSE; */
/* D->analysis = 0; */
/* D->Cmos = NULL; */
/* D->List = NULL; */
/* D->Choice = NULL; */
/* D->Devflags.Ems_device = FALSE; */
/* for (n = 0; n < MAX_CHOICES; n++) */
/*	D->Choices[n] = NULL; */
/* for (n = 0; n < MAX_RANGES; n++) */
/*	D->Cfg_ramrom[n] = NULL; */

} /* End ADD_DEVICE */

/********************************* ADD_CHOICE *********************************/
/* Add a choice to the adapter choice linked list */

void add_choice (void)

{  struct _adf_choice *A;

   A = get_mem (sizeof (struct _adf_choice));
   memcpy (A, &tmp_ad, sizeof (*A));

   A->Next = Last_device->List;
   Last_device->List = A;

} /* End ADD_CHOICE */

#ifdef DEBUG
/*___ dump_devices __________________________________________________*/

void dump_devices(char *fname)	/* Debug routine to dump the device linked list */
{
struct _device *D;
struct _adf_choice *A;
int ndevs=0,ch;
char flags[2];
char *name;
FILE *f = NULL;

   if (fname) f = fopen (fname, "w");
   if (!f) f = stdout;

   D = Last_device;

   fprintf(f, "\n");

   while (D != NULL)
   {  ndevs++;
      if (D->Devflags.Ems_device)
	 name = ems_name;
      else
	 name = slots[D->slot].adapter_name;
      fprintf(f, "\n**** DEVICE %d   %s ****\n",ndevs,name);
      fprintf(f, "   SLOT: %d\n", D->slot);
		/*  ",    ANALYSIS: %02X\n",D->slot,D->analysis); */
      fprintf(f, "\n * CMOS CHOICE,   @ OPTIMIZED CHOICE\n");

      A = D->List;
      ch = 0;

      fprintf(f, "\n   CHOICES ------------------------------\n");

      while(A != NULL){
	 ch++;
	 flags[0] = ' ';
	 flags[1] = ' ';
	 if(A == D->Cmos)
	    flags[0] = '*';
	 if(A == D->Choice)
	    flags[1] = '@';
	 fprintf(f, " %c %c CHOICE %d:",flags[0], flags[1],ch);
	 dump_adf_choice(A, f);
	 A = A->Next;
      }
      D = D->Next;
   }
   if (f != stdout) fclose (f);
}
#endif

#ifdef DEBUG
/*___ dump_adf_choice __________________________________________________*/

void dump_adf_choice (struct _adf_choice *A, FILE *f) /* Debug routine to dump an adf choice */
{
int n;
      fprintf(f, "\n                MEM                IO         ARB  INT\n");
   for(n=0; n<MAX_RANGES; n++){
      fprintf(f, "          %06lXh - %06lXh    %04lXh - %04lXh   %2d   %02Xh\n",
	 A->mem[n][0],A->mem[n][1], A->io_addr[n][0],A->io_addr[n][1],
	 A->arb[n], A->int_lvl[n]);
   }

   for(n=0; n<MAX_POS; n++){
      fprintf(f, "          POS[%d]    Mask0: ",n);
      itob(A->pos_mask[n][0], f);
      fprintf(f, "    Mask1: ");
      itob(A->pos_mask[n][1], f);
      fprintf(f, "\n");
   }

   /*fprintf(f, "          FIXED: %3s\n",(A->fixed ? "YES" : "NO"));*/
   fprintf(f, "\n");
} /* End DUMP_ADF_CHOICE */
#endif

/******************************* RESOLVE_CONFLICT *****************************/
/* Resolves multiple choices in an ADF that defines the same memory blocks */

void resolve_conflict (void)

{  struct _device *D;
   struct _adf_choice *A,*C,*T;
   register int n;
   WORD mask[MAX_POS], cmos[MAX_POS], diff;
   BOOL match;

   D = Last_device;

   C = D->Cmos;
   for (n = 0; n < MAX_POS; n++)
   {	mask[n] = 0;
	cmos[n] = combine (C->pos_mask[n]);
   } /* End FOR */

   match = FALSE;

   /* Scan list for matching CMOS mem ranges */
   /* Building a mask of bits unique to the CMOS selection */
   for (A = D->List; A != NULL; A = A->Next)
   if (A != C && memcmp (C->mem, A->mem, MAX_RANGES * 8) == 0)
   {   match = TRUE;

       for (n = 0; n < MAX_POS; n++)
       {    diff = combine (A->pos_mask[n]) ^ cmos[n]; /* XOR to find diff bits */
	    mask[n] |= diff;	/* Accumulate resulting mask */
       } /* End FOR */
   } /* End FOR/IF */

   for (n = 0; n < MAX_POS; n++) /* Extract unique bits to CMOS choice */
	cmos[n] &= mask[n];	/* Include only choices that match these bits */

   if (match)
   {  A = D->List;
      D->List = NULL;	/* Setup for re-creating linked list of choices */
      while (A != NULL)
      {   match = TRUE;
	  T = A->Next;

	  for (n = 0; n < MAX_POS; n++)
	  {    diff = combine (A->pos_mask[n]);
	       diff &= mask[n];
	       if (diff != cmos[n])
		   match = FALSE;
	  } /* End FOR */

	  if (match)		/* Found a match, save this choice */
	  {   A->Next = D->List;
	      D->List = A;
	  } /* End IF */
	  A = T;
      } /* End WHILE */

      if (D->List == NULL)	/* Anything left in the list? */
	  force_fixed ();
   } /* End IF */
   else
      force_fixed ();

} /* End RESOLVE_CONFLICT */

/********************************* FORCE_FIXED ********************************/
/* Force the device described by Last_device to be fixed */

void force_fixed (void)

{/*struct _adf_choice *C; */

   Last_device->Devflags.Dfixed = TRUE;
} /* End FORCE_FIXED */

/*********************************** COMBINE **********************************/
/* Combine POS mask into a word */

WORD combine (BYTE pos[])

{  WORD m0, m1;

   m0 = (WORD) pos[0];
   m1 = (WORD) pos[1];
   m0 = (m0 << 8) | m1;

   return(m0);
} /* End COMBINE */

#ifdef DEBUG
/*___ itob __________________________________________________________*/

void itob (BYTE bits, FILE *f) /* Debug routine to print pos data in binary */
{
BYTE mask;
register int n;

   mask = 0x80;
   for(n=0; n<8; n++){
      fprintf(f, "%c",((bits & mask) > 0) ? '1' : '0');
      mask = (BYTE) (mask >> 1);
   }
}
#endif

void error_adap(char *s1, char *s2, char *s3, BOOL abort)
// Display error box for an adapter.  The system board is slots[0],
// and all others are 1-based.
{
	char buf[512];
	static char nullstring[2] = "\0";
	int i=0;

	if (slots[slot].adapter_name[0])
	 do_textarg (++i, slots[slot].adapter_name);
	sprintf (buf, MsgErrAdap, slots[slot].adapter_id, slot);
	if (s3 == NULL || !i)
	 do_textarg (++i, buf);
	do_textarg (++i, s1);
	if (s2)
	 do_textarg (++i, s2);
	if (i<4) {
	 // Ensure that we don't have any null pointers
	 if (s3)
		do_textarg (++i, s3);
	 else
		do_textarg (++i, nullstring);
	 } // ARG4 was available

	if (abort) {	/* ??? errorwnd ???? */
	 do_error(MsgErrAdap2, abort);
	}
	else
	 do_warning(MsgErrAdap2, 0);
}
