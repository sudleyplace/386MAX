;/* $Header:   P:/PVCS/MAX/INCLUDE/PNP.H_V   1.1   01 Feb 1996 10:23:08   HENRY  $
; *
; * (C) Copyright 1995-96 Qualitas, Inc.  All rights reserved.
; *
; * PNP.H
; *
; * Plug 'n Play Equates and Structures
; *
; * Adapted from PNP.INC 20 Jan 95 by Henry Groover
; * Original PNP.INC by Bob Smith
; * Needs work to be fully useable as MASM include.
; ***/

/****
COMMENT;
****/

#ifndef PNP_INCLUDED

#define PNP_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(1)
;

;/****
; PnP Presence Structure and Equates

@PnP_SIG equ	<'$PnP'>        ; Signature
@PnP_SIGREV equ 'PnP$'          ; ...       reversed (for dword comparisons)


PnP_STR struc			; New (longer) PnP struc

PnP_SIG db	@PnP_SIG	; 00:  Signature
PnP_VER db	10h		; 04:  Version:  high-order nibble, low-order nibble
				;		 major, 	    minor
				;		 BCD value of spec:  10h = 1.0
PnP_LEN db	size PnP_STR	; 05:  Byte length of struc
PnP_FLAG dw	?		; 06:  Flags:  see PnPFLAG_REC for details
PnP_SUM db	?		; 08:  Checksum of PnP_STR

; Up to this point the new and old strucs are identical

PnP_ENF dd	?		; 09:  Event notification flag address
PnP_RMVEC dd	?		; 0D:  RM entry point
PnP_PMOFF dw	?		; 11:  PM USE16 entry point offset
PnP_PMCS dd	?		; 13:  PM USE16 code segment base address
PnP_OEM dd	?		; 17:  OEM device identifier
PnP_RMDS dw	?		; 1B:  RM data segment
PnP_PMDS dd	?		; 1D:  PM USE16 data segment base address

PnP_STR ends


PnP2_STR struc			; Old (shorter) PnP struc

	db	@PnP_SIG	; 00:  Signature
	db	10h		; 04:  Version:  high-order nibble, low-order nibble
				;		 major, 	    minor
				;		 BCD value of spec:  10h = 1.0
	db	size PnP2_STR	; 05:  Byte length of struc
	dw	?		; 06:  Flags:  see PnPFLAG_REC for details
	db	?		; 08:  Checksum of PnP_STR

; Up to this point the new and old strucs are identical

PnP2_RMVEC dd	?		; 09:  RM entry point
PnP2_PMOFF dw	?		; 0D:  PM USE16 entry point offset
PnP2_PMCS dd	?		; 0F:  PM USE16 code segment base address

PnP2_STR ends


PnPFLAG_REC record $PnPFLAG_ENM:2

@PnPFLAG_ENM_NS   equ 00b	; Event notification is not supported
@PnPFLAG_ENM_POLL equ 01b	; Event notification is handled through polling

;****/

/* Old structure elements */
typedef struct tagPnPBIOS_old {
	unsigned long dwRMVec;	/* RM entry point */
	unsigned int wPMOff;	/* PM entry point offset */
	unsigned long dwPMCS;	/* PM entry point code selector base address */
} PNPBIOS_OLD, __far *LPPNPBIOS_OLD;

/* New structure elements */
typedef struct tagPnPBIOS_new {
	unsigned long __far *lpdwENF; /* Event notification flag address */
	unsigned long dwRMVec;	/* RM entry point */
	unsigned int wPMOff;	/* PM entry point offset */
	unsigned long dwPMCS;	/* PM entry point code selector base address */
	unsigned long OEM1:4,	/* Low nybble of OEM device identifier... */
		      OEM2:4,
		      OEM3:4,
		      OEM4:4,
		      OEM5:4,
		      OEM6:4,
		      OEM7:4,
		      OEM8:4;
	unsigned int wRMDS;	/* RM data segment */
	unsigned long dwPMDS;	/* PM data segment base address */
} PNPBIOS_NEW, __far *LPPNPBIOS_NEW;

/* Elements common to both structures are defined in PNPBIOS_STR */
typedef struct tagPnPBIOS_str {
	char	szSig[ 4 ];	/* "PnP$" */
	unsigned char bVer;	/* BIOS version (BCD) */
	unsigned char cLen;	/* Structure length in bytes */
	unsigned int Notify:2,	/* Event notification */
		wReservedFl:14;	/* Reserved flag bits */
	unsigned char cCheckSum; /* Checksum */
	union {
		PNPBIOS_OLD old;
		PNPBIOS_NEW new;
	};
} PNPBIOS_STR, __far *LPPNPBIOS_STR;

/* Sizes for new and old structures (assumes new structure len > old) */
#define	PNPBIOS_OLDLEN	(sizeof( PNPBIOS_STR ) - sizeof( PNPBIOS_NEW ) + sizeof( PNPBIOS_OLD ))
#define	PNPBIOS_NEWLEN	sizeof( PNPBIOS_STR )

;/****

; PnP System Device Node Strcture

PnP_DEV_STR struc

PnP_DEV_LEN dw	?		; Size of the structure
PnP_DEV_NODE db ?		; Node #
PnP_DEV_PROD dd ?		; Compressed product ID
PnP_DEV_TYPE db 3 dup (?)	; Device type code
PnP_DEV_FLAG dw ?		; Attributes:  see PnPDEVFLG_REC for details
PnP_DEV_REST db ?		; The rest of the data

; Allocated resource configuration descriptor block:  variable length

; Possible resource configuration descriptor block:  variable length

; Compatible device identifiers:  variable length

PnP_DEV_STR ends

PnPDEVFLAG_REC record			\
		$PnP_DEVFLAG_CFG:2,	\
		$PnP_DEVFLAG_REM:1,	\
		$PnP_DEVFLAG_DOCK:1,	\
		$PnP_DEVFLAG_IPL:1,	\
		$PnP_DEVFLAG_INP:1,	\
		$PnP_DEVFLAG_OUT:1,	\
		$PnP_DEVFLAG_XCFG:1,	\
		$PnP_DEVFLAG_XDIS:1

@PnP_DEVFLAG_CFG_NBO	equ 00b ; Device can be configured for next boot only
@PnP_DEVFLAG_CFG_RT	equ 01b ; ...			   at runtime
;;;;;DEVFLAG_CFG_	equ 10b ; (Reserved)
@PnP_DEVFLAG_CFG_RTO	equ 11b ; Device can be configured at runtime only

@PnP_DEVFLAG_CFG equ	(mask $PnP_DEVFLAG_CFG)  ; 0180: Device configure state
						 ; See @PnP_DEVFLAG_CFG_xxx for details
@PnP_DEVFLAG_REM equ	(mask $PnP_DEVFLAG_REM)  ; 0040: Device is removable
@PnP_DEVFLAG_DOCK equ	(mask $PnP_DEVFLAG_DOCK) ; 0020: Device is docking station
@PnP_DEVFLAG_IPL equ	(mask $PnP_DEVFLAG_IPL)  ; 0010: Device can be primary IPL
@PnP_DEVFLAG_INP equ	(mask $PnP_DEVFLAG_INP)  ; 0008: Device is primary input
@PnP_DEVFLAG_OUT equ	(mask $PnP_DEVFLAG_OUT)  ; 0004: Device is primary output
@PnP_DEVFLAG_XCFG equ	(mask $PnP_DEVFLAG_XCFG) ; 0002: Device cannot be configured
@PnP_DEVFLAG_XDIS equ	(mask $PnP_DEVFLAG_XDIS) ; 0001: Device cannot be disabled

;****/

/* Small resource version structure */
/***
 *   Byte 0 = packed BCD
 *	 1 = vendor-specific
 ***/
typedef struct tagPnPSmallVer {
	unsigned char
		VerMinor:4,
		VerMajor:4;
	unsigned char VendorSpecific;
} PNPSMALLVER, __far *LPPNPSMALLVER;

/* Small resource IRQ structure */
typedef struct tagPnPSmallIRQ {
	unsigned int wMaskBits;
	/* The remainder of this structure is optional.  Check PNPSMALLRES.Length */
	/* and if less than 3, ignore it. */
	unsigned char HighEdge:1,	/* Edge-triggered high */
		LowEdge:1,		/* Edge-triggered low */
		HighLevel:1,		/* Level-triggered high */
		LowLevel:1;		/* Level-triggered low */
} PNPSMALLIRQ, __far *LPPNPSMALLIRQ;

/* Small resource DMA structure */
/*   Byte 0 = DMA channel mask bits
 *	 1 = flags
 *	     Bit 7    = 0
 *	     Bits 6:5 = 00:  compatibility mode
 *			01:  Type A DMA (EISA)
 *			10:  Type B DMA
 *			11:  Type F DMA
 *	     Bit 4    = DMA word mode
 *			0 = not supported
 *			1 = is supported
 *	     Bit 3    = DMA byte mode status
 *			0 = not supported
 *			1 = is supported
 *	     Bit 2    = Logical device bus master
 *			0 = not bus master
 *			1 = is bus master
 *	     Bits 1:0 = Transfer type preference
 *			00 = 8-bit only
 *			01 = 8- and 16-bit
 *			10 = 16-bit only
 *			11 = (Reserved)
**/
typedef struct tagPnPSmallDMA {
	unsigned char Mask;		/* DMA channel mask bits */
	unsigned char PreferredTransfer:2, /* Preferred transfer type:
					 * 00b = 8-bit only
					 * 01b = 8- and 16-bit 
					 * 10b = 16-bit only
					 * 11b   (reserved) */
		BusMaster:1,		/* Is bus master */
		ByteMode:1,		/* Supports byte mode */
		WordMode:1,		/* Supports word mode */
		Mode:2,			/* DMA type:
					 * 00b = compatibility mode
					 * 01b = type A (EISA)
					 * 10b = type B
					 * 11b = type F */
		Rsvd:1;			/* Always 0 */
} PNPSMALLDMA, __far *LPPNPSMALLDMA;

/* Small resource I/O port descriptor structure */
/* I/O Port Descriptor
 *   Byte 0:  Bit 0 = 1 if 16-bit I/O decode
 *		   = 0 if 10-bit ...
 *	 1 = Range min base addr bits[7:0]
 *	 2 = ...		     15:8
 *	 3 = Range max base addr bits[7:0]
 *	 4 = ...		     15:8
 *	 5 = Base alignment
 *	 6 = Range length
 */
typedef struct tagPnPSmallIO {
	unsigned char Addr16:1,		/* 10 bits if 0, 16 if 1 */
		Rsvd:7;
	unsigned int wRangeMinBase;	/* Minimum base address for range */
	unsigned int wRangeMaxBase;	/* Maximum base address for range */
	unsigned char BaseAlign;	/* Base alignment in bytes (1,2,4,8,...) */
	unsigned char RangeLen;		/* Range length in bytes */
} PNPSMALLIO, __far *LPPNPSMALLIO;

/* Small resource fixed I/O port structure */
/* Fixed Location I/O Port Descriptor
 *   Byte 0 = Range base addr bits[7:0]
 *	 1 = ...		 15:8
 *	 2 = Range length
 */
typedef struct tagPnPSmallFixedIO {
	unsigned int wRangeBase;	/* Base address of range */
	unsigned char RangeLen;		/* Range length in bytes */
} PNPSMALLFIXEDIO, __far *LPPNPSMALLFIXEDIO;

/* Logical device ID */
/* Compatible device ID */

/* Small resource structure */
typedef struct tagPnPSmallResource {
	unsigned char Length:3,		/* Length in bytes of Data */
		Name:4,			/* Name (type) of resource - see list */
		Large:1;		/* Large resource flag - always 0 */
	union {
		unsigned char Data[ 0 ];
		PNPSMALLVER Ver;
		PNPSMALLIRQ IRQ;
		PNPSMALLDMA DMA;
		PNPSMALLIO IO;
		PNPSMALLFIXEDIO FixedIO;
	};
} PNPSMALLRES, __far *LPPNPSMALLRES;

/* Small resource names (types) as found in PNPSMALLRES.Name */

#define	PnP_SRES_NAME_VER 0x01	/* Version # */
#define	PnP_SRES_NAME_LID 0x02	/* Logical device ID */
#define	PnP_SRES_NAME_CID 0x03	/* Compatible device ID */
#define	PnP_SRES_NAME_IRQ 0x04	/* IRQ format */
#define	PnP_SRES_NAME_DMA 0x05	/* DMA format */
#define	PnP_SRES_NAME_SDF 0x06	/* Start dependent function */
#define	PnP_SRES_NAME_EDF 0x07	/* End ... */
#define	PnP_SRES_NAME_IO  0x08	/* I/O port descriptor */
#define	PnP_SRES_NAME_IOF 0x09	/* Fixed location I/O port descriptor */
/***_SRES_NAME_    equ	0Ah	* (Reserved)
;;;;_SRES_NAME_    equ	0Bh	* (Reserved)
;;;;_SRES_NAME_    equ	0Ch	* (Reserved)
;;;;_SRES_NAME_    equ	0Dh	* (Reserved) ****/
#define	PnP_SRES_NAME_VEN 0x0E	/* Vendor defined */
#define	PnP_SRES_NAME_EOT 0x0F	/* End tag */


/* Large Resource 32-bit Fixed Memory format */
/***
; 32-bit Fixed Location Memory Range Descriptor
;   Byte 0 = Information bits
;	     Bit 7 = 0
;	     Bit 6 = Expansion ROM
;		     0 = not
;		     1 = is
;	     Bit 5 = Shadow ROM
;		     0 = not
;		     1 = is
;	     Bits 4:3 = Memory control
;			00 = 8-bit memory only
;			01 = 16-bit memory only
;			10 = 8- and 16-bit memory
;			11 = 32-bit memory only
;	     Bit 2 = Support type
;		     0 = decode supports range length
;		     1 = decode supports high address
;	     Bit 1 = Cache support type
;		     0 = non-cacheable
;		     1 = read cacheable, write-through
;	     Bit 0 = Write status
;		     0 = non-writeable (ROM)
;		     1 = writeable
;   Bytes 1-4 = address
;   Bytes 5-8 = length
***/
typedef struct tagPnPM32F {
	unsigned char Writeable:1,	/* 0 if ROM */
		Cacheable:1,		/* 1 if write-through caching supported */
		SupportsDecodeHigh:1,	/* 1 if decode supports high address,
					 * 0 if decode supports range length */
		Control:2,		/* 00b = 8-bit memory only
					 * 01b = 16-bit memory only
					 * 10b = 8- and 16-bit memory only
					 * 11b = 32-bit memory only */
		ShadowROM:1,		/* 1 if shadow ROM */
		ExpansionROM:1,		/* 1 if expansion ROM */
		Rsvd:1;			/* always 0 */
	unsigned long dwBaseAddr;
	unsigned long dwLength;
} PNPM32F, __far *LPPNPM32F;

/***
; 16-bit Memory Range Descriptor
;   Byte 0   = Information bits (see M32F for details)
;	 1-2 = minimum base address
;	 3-4 = maximum ...
;	 5-6 = alignment bits
;	 7-8 = length
***/
typedef struct tagPnPM16 {
	unsigned char flags;		/* Use M32F.Writeable - .ExpansionROM */
	unsigned int wMinBaseAddr;	/* Minimum base address */
	unsigned int wMaxBaseAddr;	/* Maximum base address */
	unsigned int wAlign;		/* Alignment bits */
	unsigned int wLength;		/* Range length in bytes / 256 */
} PNPM16, __far *LPPNPM16;

/***
; 32-bit Memory Range Descriptor
;   Byte 0     = Information bits (see M32F for details)
;	 1-4   = minimum base address
;	 5-8   = maximum ...
;	 9-12  = alignment bits
;	 13-16 = length
***/
typedef struct tagPnPM32 {
	unsigned char flags;		/* Use M32F.Writeable... */
	unsigned long dwMinBaseAddr;	/* Minimum base address */
	unsigned long dwMaxBaseAddr;	/* Maximum base address */
	unsigned long dwAlign;		/* Alignment bits */
	unsigned long dwLength;		/* Range length in bytes */
} PNPM32, __far *LPPNPM32;

/* Large resource structure */
typedef struct tagPnPLargeRes {
	unsigned char Name:7,	/* Resource name (type).  See list below */
		Large:1;	/* Large type.  Always 1. */
	unsigned int wLength;	/* Length in bytes of Data */

	union {
		unsigned char Data[ 0 ];
		PNPM32F M32F;
		PNPM16 M16;
		PNPM32 M32;
	};

} PNPLARGERES, __far *LPPNPLARGERES;

/* Large resource names (types) as found in PNPLARGERES.Name */

#define	PnP_LRES_NAME_M16  0x01	/* 16-bit memory range descriptor */
#define	PnP_LRES_NAME_IDA  0x02	/* Identifier string (ANSI) */
#define	PnP_LRES_NAME_IDU  0x03	/* Identifier string (Unicode) */
#define	PnP_LRES_NAME_VEN  0x04	/* Vendor defined */
#define	PnP_LRES_NAME_M32  0x05	/* 32-bit memory range descriptor */
#define	PnP_LRES_NAME_M32F 0x06	/* 32-bit fixed location memory range descriptor */


/* PnP System Device Node Structure */
typedef struct tagPnPDevNodeStr {

	unsigned int wLen;	/* Size of structure */
	unsigned char Node;	/* Node # */
	unsigned char paID[ 4 ]; /* Compressed product ID */
	unsigned char paType[ 3 ]; /* Device type code */
	unsigned int XDis:1,	/* Can't be disabled */
		XCfg:1,		/* Can't be configured */
		Out:1,		/* Primary output */
		Inp:1,		/* Primary input */
		IPL:1,		/* Can be primary IPL device */
		Dock:1,		/* Is a docking station */
		Rem:1,		/* Is removable */
		ConfigType:2,	/* 00b = configurable for next boot only
				   01b = configurable at runtime
				   10b   (rsvd)
				   11b = configurable only at runtime */
		Rsvd:7;		/* Unused */
	union {
		unsigned char paRest[ 0 ]; /* Remainder */

		PNPSMALLRES s;	/* Small resource */
		PNPLARGERES l;	/* Large resource */

	};

/* Allocated resource configuration descriptor block:  variable length */
/* Possible resource configuration descriptor block:  variable length */
/* Compatible device identifiers:  variable length */

} PNP_DEVNODE, __far *LPPNP_DEVNODE;

/* Define size of device node structure less trailing portion */
typedef union {
	PNPSMALLRES s;
	PNPLARGERES l;
} __MAXRES__;

#define PNP_DEVNODE_BASESIZE	(sizeof( PNP_DEVNODE ) - sizeof( __MAXRES__ ))

;/****

; PnP function codes

@PnP_GET_NUM_NODES  equ 00h	; Get # nodes
@PnP_GET_DEV_NODE   equ 01h	; Get info for a device node
@PnP_SET_DEV_NODE   equ 02h	; Set ...
@PnP_GET_EVENT	    equ 03h	; Get Event Type
@PnP_SEND_MSG	    equ 04h	; Send Message
@PnP_GET_DOCK_INFO  equ 05h	; Get docking station info
;;;;		    equ 06h	; Reserved
;;;;		    equ 07h	; Reserved
;;;;		    equ 08h	; Reserved
@PnP_SET_STATIC_RES equ 09h	; Set statically allocated resources
@PnP_GET_STATIC_RES equ 0Ah	; Get statically allocated resources
@PnP_GET_APM_ID_TAB equ 0Bh	; Get APM ID table
@PnP_GET_ISA_CFG    equ 40h	; Get ISA configuration structure
@PnP_GET_ESCD_INFO  equ 41h	; Get ESCD info
@PnP_GET_ESCD	    equ 42h	; Get ESCD data
@PnP_SET_ESCD	    equ 43h	; Set ESCD data

; BIOS Boot Specification Functions

@PnP_GET_VERSION    equ 60h	; Get Version #
@PnP_GET_DEV_CNT    equ 61h	; Get Device Count
@PnP_GET_PRIORITY   equ 62h	; Get Priority and Table
@PnP_SET_PRIORITY   equ 63h	; Set Priority
@PnP_GET_IPLDEV     equ 64h	; Get IPL Device from Last Boot
@PnP_GET_BOOT1ST    equ 65h	; Get Boot First
@PnP_SET_BOOT1ST    equ 66h	; Set Boot First

;****/

enum {
	PnP_GET_NUM_NODES=0,
	PnP_GET_DEV_NODE,
	PnP_SET_DEV_NODE,
	PnP_GET_EVENT,
	PnP_SEND_MSG,
	PnP_GET_DOCK_INFO,
	/* Reserved */
	/* Reserved */
	/* Reserved */
	PnP_SET_STATIC_RES=9,
	PnP_GET_STATIC_RES,
	PnP_APM_ID_TAB,

	PnP_GET_ISA_CFG=0x40,
	PnP_GET_ESCD_INFO,
	PnP_GET_ESCD,
	PnP_SET_ESCD,

	PnP_GET_VERSION=0x60,
	PnP_GET_DEV_CNT,
	PnP_GET_PRIORITY,
	PnP_SET_PRIORITY,
	PnP_GET_IPLDEV,
	PnP_GET_BOOT1ST,
	PnP_SET_BOOT1ST
};

;/****

; PnP Message Codes

@PnP_MSG_OK	equ	0	; Continue with sequence which initiated the event
@PnP_MSG_ABORT	equ	1	; Abort the ...


; PnP BIOS Boot Specification Equates

@PnP_BBS_IPL	equ	0	; IPL-relative
@PnP_BBS_BCV	equ	1	; BCV-relative


; PnP function return values

@PnP_SUCCESS	 equ	0	; Successful
@PnP_ERR_UNKFN	 equ	81h	; Unknown function
@PnP_ERR_NOTSUP  equ	82h	; Function not supported
@PnP_ERR_INVHNDL equ	83h	; Invalid handle
@PnP_ERR_BADPARM equ	84h	; Bad parameter
@PnP_ERR_SETFAIL equ	85h	; Set failed
@PnP_ERR_NOEVENT equ	86h	; Events not pending
@PnP_ERR_SYSXLCK equ	87h	; System not locked
@PnP_ERR_NOISA	 equ	88h	; No ISA PnP cards
@PnP_ERR_NODOCK  equ	89h	; Unable to determine dock capabilities
@PnP_ERR_NOBATT  equ	8Ah	; Config changed failed - no battery
@PnP_ERR_RESCONF equ	8Bh	; Config changed failed - resource conflict
@PnP_ERR_TINYBUF equ	8Ch	; Buffer too small
@PnP_ERR_ESCD	 equ	8Dh	; Use ESCD support
@PnP_ERR_NOMSG	 equ	8Eh	; Message not supported
@PnP_ERR_HARDERR equ	8Fh	; Hardware error
;*****/

/****
COMMENT;
****/

enum {
	PnP_SUCCESS=0,
	PnP_ERR_UNKFN=0x81,
	PnP_ERR_NOTSUP,
	PnP_ERR_INVHNDL,
	PnP_ERR_BADPARM,
	PnP_ERR_SETFAIL,
	PnP_ERR_NOEVENT,
	PnP_ERR_SYSXLCK,
	PnP_ERR_NOISA,
	PnP_ERR_NODOCK,
	PnP_ERR_NOBATT,
	PnP_ERR_RESCONF,
	PnP_ERR_TINYBUF,
	PnP_ERR_ESCD,
	PnP_ERR_NOMSG,
	PnP_ERR_HARDERR
};

#pragma pack()

#ifdef __cplusplus
}
#endif

#endif
;


