;' $Header:   P:/PVCS/MAX/INC/MAXDEV.INV   1.1   30 Sep 1996 17:09:18   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	All rights reserved.
;
; MAXDEV.INC
;
; Equates and Structures for 386MAX device loader
;

MD_STR	 struc

MD_DD	 db	 18 dup (?)	; 00-11:  Room for device driver header
MD_ATTR  dd	 ?		; 12-15:  Attributes
MD_NAME  db	 '        '     ; 16-1D:  Device name
MD_IREAL dd	 ?		; 1E-21:  Seg:Off  of init routine (real mode)
MD_IPROT df	 ?		; 22-27:  Sel:Off     init	   (prot mode)
MD_RPROT df	 ?		; 28-2D:  ...	      restore	   (prot mode)

; The following variables are filled in by the device being loaded
; during its real mode initialization

MD_SIZE  dd	 ?		; 2E-31:  Initialization size
MD_DATA  dd	 ?		; 32-35:  Offset32 to data segment

; The following variables are used by 386SWAT only

MD_INIT  dd	 ?		; 36-39:  Offset32 of initial code (for 386SWAT only)
MD_MSG	 dd	 ?		; 3A-3D:  Offset32 of message code (for 386SWAT only)
MD_IBV0  db	 ?		; 3E-3E:  Master IMR base vector
MD_IBV1  db	 ?		; 3F-3F:  Slave ...
MD_PHYS  dd	 ?		; 40-43:  Physical address of code segment

; The following variables are new to MAX 5.11 (added for GUMBY.BRS)
; and are only valid if @MD_VER is true.

MD_APIVER db	 ?		; 44-44:  Binary version # of this header
				;	  statically present in load module
MD_MAXVER db	 00h		; 45-45:  Binary version # of MAX support
MD_IVIRT  dd	 ?		; 46-49:  Seg:Off of init routine (virtual mode)
MD_OVR	   dw	 ?		; 4A-4B:  Start of High DOS in paras (/4KB)
MD_OVR_LEN dw	 ?		; 4C-4D:  Length of recovered High DOS in paras
				;	  (/4KB) (zero = none recovered)

; The following variables are valid only if MD_APIVER is >= 01h.

; MD_USIZE is used to allocate uninitialized contiguous extended memory.
; Essentially, it provides a means by which a load module can define
; contiguous uninitialized data.

MD_USIZE dd	 0		; 4E-51:  Amount of uninitialized data in bytes

; MD_VSIZE is used to indicate that this load module supports contiguous
; and isolated INIT_VIRT code which 386MAX can leave as the only part
; in low DOS.  The rest of the low DOS memory image after INIT_REAL has
; completed successfully is copied to extended memory.	If @MD_VSIZE is
; set by 386MAX, then the load module need not include the INIT_VIRT
; code as part of its resident PM code.

MD_VSIZE dd	 0		; 52-55:  Size of INIT_VIRT code (0=not supported)
	 dd	 19 dup (0)	; Room for growth

MD_STR	 ends


; Equates for APIVER/MAXVER

@APIVER  equ	 01h		; Latest version #


; Equates for MD_ATTR

@MD_EXE  equ	 80000000h	; MD_INIT is already relocated
@MD_RMIE equ	 40000000h	; Real mode initialization error
@MD_XT	 equ	 20000000h	; System is an XT
@MD_MCA  equ	 10000000h	; System is an MCA-compatible
@MD_INBRD equ	 08000000h	; System is an Inboard/AT
@MD_USE32 equ	 04000000h	; Code segment is USE32
@MD_WIN3 equ	 02000000h	; We're running under Windows 3
@MD_VER  equ	 01000000h	; Ver no. supplied by load module is valid
@MD_VMIE equ	 00800000h	; Virtual mode initialization error
@MD_DPMI equ	 00400000h	; DPMI services requested
@MD_VSIZE equ	 00200000h	; MD_VSIZE is supported by this version of 386MAX
@MD_WKD   equ	 00100000h	; We're a Windows Kernel Debugger
@MD_WSVC  equ	 00080000h	; Win386 services are available


COMMENT|

Usage Notes:

The real mode initialization code is called after loading the file
using DOS function 4Bh (EXEC) overlay.	Its purpose is to allow the
program to parse arguments and fill in file sizes, etc.

The protected mode initialization code is called after loading the
file into place in physical memory.  Paging has not been enabled as
yet.  The GDT and IDT entries are both in their final form, but both
may be relocated in linear memory subsequently.  IDT entries may be
intercepted by saving the IDT base with SIDT and using the 4GB data
selector to address it.  Be sure to preface the SIDT instruction with
a DB 66h to save the 32-bit base address.

The virtual mode initialization code is called after XMS and EMS services
have been established.	Its purpose is to allow the program to make any DOS
or related function calls that it could not acomplish in protected mode.

The program's resident code must precede its resident data area.
Non-resident code and data at the end of the program may be discarded
after the real mode initialization code is executed.

|

