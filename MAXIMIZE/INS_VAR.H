/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_VAR.H_V   1.0   05 Sep 1995 16:33:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-94 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INS_VAR.H								      *
 *									      *
 * Global variables for ins_.* routines 				      *
 *									      *
 ******************************************************************************/

#ifndef INS_VAR_INCLUDED
#define INS_VAR_INCLUDED

#include <commdef.h>		/* Common (shared) definitions */
#include <max_sys.h>		/* MAXIMIZE version controls */
#include <qualitas.h>		/* Qualitas product-specific defines */
#include <mca_pos.h>		/* Adapter and system POS definitions */

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

#define NEWPOS	"POSFILE.BIN"

#define MAX_ASLOTS MCASLOTS	/* Maximum adapter slots */
#define MAX_SLOTS MAX_ASLOTS+1+1 /* Number of slots including pslots */
#define PSLOT_PLANAR MAX_ASLOTS /* Pseudo-slot index for planar ADF */
#define PSLOT_EMS PSLOT_PLANAR+1 /* Pseudo-slot index for EMS page frame */
#define MAX_RANGES 5		/* Number of ranges allowed for each item */
				/* Have not seen more than 4, YET!	  */

#define MAX_CPOS 4	/* Maximum CMOS-storable POS bytes */
#define MAX_POS 32	/* Number of POS bytes (includes ADP POS bytes) */

#define MAX_ADP_NAME 75 /* From the IBM definition */

#define MAX_MATCHES 4	/* Max number of CMOS matches during ADF processing */

#define MAX_CHOICES 8	/* Max choices to be saved during optimization */

#define NVRAM_SYSPOS 0x369 /* Magic port number for port to index */
			/* system board NVRAM (CMOS) POS values */

/* Note that the range for MAX_BLOCKS starts at A000 so as to */
/* include VIDMEM statements as low as that */
#define BLOCK_SIZE  0x01000		/* Size of 4KB block in bytes */
#define BLOCK_START 0xA0000
#define BLOCK_END   0xF4000		/* Blocks can't start at or above this */
/* Max number of 4KB memory blocks to be mapped */
#define MAX_BLOCKS (int) ((BLOCK_END - BLOCK_START) / BLOCK_SIZE)

#define MAXIMIZE     ((BYTE) 1)
#define STATIC	     ((BYTE) 2)
#define DISABLED     ((BYTE) 3)
#define EMSZERO      ((BYTE) 4)
#define NO_FRAME     ((BYTE) 5)
#define NOMEM	     ((BYTE) 6)

#pragma pack(1) 	/* Pack the following structures on byte boundaries */

struct _adf_choice {		/* One for each NAMEDITEM choice with MEM */
	struct _adf_choice *Next;		/* Ptr next adapter choice in list */
	DWORD io_addr[MAX_RANGES][2];	/* IO addresses */
	BYTE arb[MAX_RANGES];		/* arbitration values */
	BYTE int_lvl[MAX_RANGES];		/* interrupt values */
	DWORD mem[MAX_RANGES][2];		/* mem block ranges used */

	BYTE pos_mask[MAX_POS][2];	/* pos_mask[0] = force "0" mask */
					/* pos_mask[1] = force "1" mask */
	BOOL Afixed;			/* adapter has fixed parameters */
	BYTE memcnt;			/* mem range counter */
	BYTE arbcnt;			/* arb counter */
	BYTE iocnt;			/* io counter */
	BYTE intcnt;			/* int counter */
};

struct _devflags {
	int	Dfixed:1,		/* Device has fixed parameters */
		Ems_device:1,		/* Flag this as the dummy EMS device */
		P_device:1;		/* Planar ADF device */
};

struct _device {		/* More than one device can be on a board */
	struct _device *Next;	/* Ptr to next device in list */
	struct _adf_choice *Cmos;	/* Ptr to CMOS pos defined device */
	struct _adf_choice *List;	/* Linked list of choices */
	/*  with same io, int and arb values */
	struct _adf_choice *Choice; /* Ptr to optimized choice */
	struct _adf_choice *Choices[MAX_CHOICES]; /* Ptrs to optimized choices */
	struct _ramrom *Cfg_ramrom[MAX_RANGES]; /* Associated config ram/rom */
	BYTE slot;			/* Slot # */
	struct _devflags Devflags;	/* Device flags */
};

struct _ramrom {
	struct _ramrom *Next;	/* Ptr to next ramrom entry */
	struct _device *Device; /* Device association ptr */
	struct _prsl_t *Cfg;	/* Ptr to Ken's linked list pointers */
	DWORD start;		/* Starting address */
	DWORD end;		/* End of block */
	int type;		/* Type  RAM=1	ROM=2 */
};

struct _slot {
	WORD adapter_id;		/* Adapter ID as assigned by manufacture */
	char *adapter_name;	/* Adapter's name */
	BYTE numbytes;		/* Number of significant POS bytes */
	BYTE init_state;		/* Initial state:  STATIC, MAXIMIZE, NOMEM, etc. */
	BYTE cur_state; 	/* Current state:  STATIC, MAXIMIZE, NOMEM, etc. */
	BYTE exec;			/* Flag this device as using an ADP */
	/* NOTE: cmos_pos[] and choice_pos[] MUST be the same size. */
	/* adapter_pos[] need not be the full 32 bytes. */
	BYTE cmos_pos[MAX_POS]; 	/* The current defined CMOS pos bytes */
	BYTE choice_pos[MAX_POS];	/* Pos for new setup */
	BYTE adapter_pos[MAX_CPOS];	/* Adapter defined pos bytes */
	BYTE pos_mask[MAX_POS]; 	/* Mask used for ADP processing */
	int num_mem_devices;	/* number of devices using mem for this slot */
	BYTE exec_pos_mask[MAX_POS][2]; /* POS mask for use during ADP exec */
	WORD exec_seg;		/* Segment address for loaded ADP */
	char *help_static;	/* Help message if user requests change from STATIC */
};

struct _pos_data {	/* pos data passed to an ADP */
	WORD numbytes;	/* Book says this is reserved, but it looks like it */
	/* should be the numbytes			    */
	BYTE pos_data[32];
};

struct _rqp {		/* Resource query packet to provide service to ADP */
	BYTE func;
	BYTE slot;
	WORD start_add_h;
	WORD start_add_l;
	WORD end_add_h;
	WORD end_add_l;
	WORD size_h;
	WORD size_l;
};

struct _exec_block {	/* ADP parameter block passed to an executing ADP */
	BYTE func;
	BYTE slot;
	DWORD far *Sysmeml;		/* System memory below 16MB */
	DWORD far *Sysbrdl;		/* System board memory below 16MB */
	struct _pos_data far *P_array;	/* Ptr to pos data array */
	BYTE far *P_mask;			/* Ptr to pos mask array */
	WORD far *Id_list;			/* Ptr to adapter id list */
	WORD (far *adp_function)(void); /* Ptr to resource query function */
	struct _rqp far *Rqp;		/* Ptr to resource query packet */
	DWORD far *Sysmemh;		/* System memory above 16MB */
	DWORD far *Sysbrdh;		/* System board memory above 16MB */
};

struct posd_str {			/* Use for Redwheat */
	WORD id;				/* Adapter ID */
	BYTE cmos[MAX_CPOS];		/* CMOS POS values */
};

#pragma pack()

typedef struct tagDefsym {
	struct tagDefsym *pNext;
	char *pszName;			/* "I_100ns_Stream_Data" */
	int iVal;			/* 0 or 1 (0 by default) */
} DEFSYM;

struct _slot slots[MAX_SLOTS];	/* Array of slot structures */

GLOBAL int adf_nstem			/* How many chars in adf_stem */
#ifdef GLINIT
= 0
#endif
;

GLOBAL char adf_stem[100];	/* Path spec stem for ADF files */

GLOBAL char ems_name[]
#ifdef GLINIT
 = {"EMS Page Frame"}
#endif
;

GLOBAL BYTE slot;		/* Current slot being processed */
GLOBAL WORD num_matches;	/* Number of CMOS matches */

GLOBAL FILE *Adf;		/* Stream ptr for ADF files */

GLOBAL BOOL low_frame
#ifdef GLINIT
 = FALSE
#endif
; /* Low EMS page frame wanted */

GLOBAL BOOL ems_services
#ifdef GLINIT
 = TRUE
#endif
; /* EMS services wanted */

GLOBAL BOOL abios;		/* Flag that ABIOS calls can be made */
GLOBAL BOOL optimize_adf;	/* Flag for optimization wanted */
GLOBAL BOOL unget_token;	/* Flag for re-using current token */
GLOBAL BOOL matched;		/* Flag used to indicate a CMOS match */
GLOBAL BOOL conflict;

GLOBAL struct _adf_choice tmp_ad; /* Structure used during ADF nameditem processing */
GLOBAL struct _adf_choice fix_ad; /* Structure used during ADF fixeditem processing */
GLOBAL struct _adf_choice match[MAX_MATCHES]; /* Array of CMOS matched data */

GLOBAL struct _device *Last_device;	/* Ptr to last entry in device linked list */
GLOBAL struct _device *Current_device; /* Ptr to current entry in device linked list */

GLOBAL BYTE map_sum[MAX_BLOCKS];	/* Summation array for map analysis */
GLOBAL BYTE conflict_map[MAX_BLOCKS];	/* Used to detected device memory */
/* conflicts during optimization */

GLOBAL BYTE available_blocks[MAX_BLOCKS]; /* Available memory block array */
/* 0 = available, 1 = reserved */

GLOBAL int choice_count;		/* Counter for number of optimized choices */

GLOBAL int nholes [MAX_CHOICES];	/* # holes for each choice */
GLOBAL int maxhole[MAX_CHOICES];	/* Largest holesize ... */
GLOBAL int emshole[MAX_CHOICES];	/* Size of hole under EMS page frame */
GLOBAL int choice_index[MAX_CHOICES];	/* Sort index for choices */

GLOBAL int ems_hole;
GLOBAL int big_hole;
GLOBAL int hole_count;		/* Used in optimization analysis */

GLOBAL struct _exec_block adp_parm_blk; /* ADP parameter block for ADP execution */
GLOBAL struct _pos_data pos_array[MAX_SLOTS];	/* POS data for ADP exec */
GLOBAL BYTE pos_mask[32];			/* POS mask used by ADP exec */
GLOBAL WORD adapter_id_list[MAX_SLOTS]; /* Adapter id list for ADP exec */
GLOBAL struct _rqp resource_parm_blk;	/* Resource query parameter block */

/* These values may change if the correct values are needed */

GLOBAL DWORD Sysmeml
#ifdef GLINIT
 = 0x1000
#endif
;	/* 4meg - system mem 1-16meg */

GLOBAL DWORD Sysbrdl
#ifdef GLINIT
 = 0x0800
#endif
;	/* 2meg - system board mem 1-16meg */

GLOBAL DWORD Sysmemh
#ifdef GLINIT
= 0
#endif
;	/* 0meg - system mem above 16meg */

GLOBAL DWORD Sysbrdh
#ifdef GLINIT
 = 0
#endif
;	/* 0meg - system board mem above 16meg */

GLOBAL int blocking_factor, block_cnt; /* Memory blocking control for ADP exec */
GLOBAL DWORD current_block[MAX_RANGES][2]; /* Current block requested by ADP */

GLOBAL DWORD sysroml;	/* DWORD version of sysrom starting address */

GLOBAL struct _ramrom *Last_ramrom;

GLOBAL struct _device *Device_Choice;

GLOBAL struct _device *Ems_device
#ifdef GLINIT
= NULL
#endif
;

GLOBAL BOOL extset;
GLOBAL DWORD emsmem;

GLOBAL WORD AdfSkip[]		/* Adapters which don't have an .ADF file */
#ifdef GLINIT
= {
	0xDFFA, 		/* 5.25" floppy controller */
	0xDFFD, 		/* Integrated fixed disk */
	0xDFFF, 		/* Model 70 */
	0xEDAF, 		/* ??? LOOKUP */
	0xFDFF, 		/* Vic's Model 80 */
	0xFBFF, 		/* Model 50, 56SX, & NCR system boards */
	0
}
#endif
;

GLOBAL WORD AdfStatic[] 	/* Adapters to default to static */
#ifdef GLINIT
= {
	0x71D4, 	/* Kingston Datacard */
	0
}
#endif
;

GLOBAL WORD *AdfSkipU		/* User-defined list of adapters to skip */
#ifdef GLINIT
= NULL
#endif
;

GLOBAL WORD *AdfStaticU 	/* User-defined list of static adapters */
#ifdef GLINIT
= NULL
#endif
;

GLOBAL DEFSYM Defsym		/* Defsym list for newer ADFs */
#ifdef GLINIT
= { NULL, "Model", 0}
#endif
;

#endif /*INS_VAR_INCLUDED*/
