;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I67.ASV   1.4   30 May 1997 10:45:00   BOB  $
	 title	 QMAX_I67 -- 386MAX INT 67h Handler
	 page	 58,122
	 name	 QMAX_I67

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include INTVEC.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include VCPI.INC
	 include MASM5.MAC
	 include ALLMEM.INC

	 include PDTGRP.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_VCP.INC
	 include QMAX_TRC.INC
	 include QMAX_XMS.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA
JGROUP	 group	 JCODE


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 INIT_DATA:far

JCODE	 ends			; End JCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_VCPI and @VCP_OLD
	 extrn	 OLDVCPI:near
endif				; IF @OEM_VCPI and @VCP_OLD
	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC
if @OEM_EMS
	 extrn	 RESINT67_INT:byte
endif				; IF @OEM_EMS

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 CON1KB:dword
	 extrn	 CON4KB:dword
	 extrn	 LOWOFF:dword
	 extrn	 HARDCNT:word

if @OEM_EMS
	 extrn	 EMM_FLAG:word
	 include QMAX_EMM.INC

	 extrn	 HIMEM_CS:word
;;;;;;;; extrn	 OFFCR3:dword
;;;;;;;; extrn	 PDTDIR2:dword
;;;;;;;; extrn	 PDBSIZE:dword

	 extrn	 PPDTVID:dword
	 extrn	 PPDTFRM:dword
	 extrn	 FRAME:word
	 extrn	 PHNDLCNT:dword
	 extrn	 PHNDLPAGE:dword
	 extrn	 PPAGELINK:dword
	 extrn	 PLINKBASE:dword
	 extrn	 NPHYS16S:byte
	 extrn	 NPHYS16F:byte
	 extrn	 PPHYS2SEG:dword

if @OEM_XMS
	 extrn	 XHNDLCNT:word
	 extrn	 PXMSBMAP:dword
endif				; IF @OEM_XMS
	 extrn	 HFRMLEN:dword
	 extrn	 PHFRMSAV:dword
	 extrn	 RPNCURSIZ:word

	 extrn	 PHNDLNAME:dword

	 extrn	 SEL_4GB:word

	 public  PPHNDLFREE,PPHNDLVMS
PPHNDLFREE dd	 ?		; Ptr to ptr to free chain
PPHNDLVMS  dd	 ?		; Ptr to Ptr of VMS (VCPI and XMS) handle chain

	 public  MAXRPN
MAXRPN	 dd	 ?		; Maximum RPN

	 public  EHNDLCNT
EHNDLCNT dw	 ?		; # active EMS handles

; HMAP is a bit map, one bit per handle
; Handle 0 = bit 0 in byte 0
; Handle 1 = bit 1 in byte 0
; ...
; Handle 8 = bit 0 in byte 1, etc.

	 public  HMAP
HMAP	 db	 64 dup (?)	; Handle bit map:  0 = available
				;		   1 = in use
				; Handles are limited to 0-254

	 public  @HMAPSIZE
@HMAPSIZE equ	 size HMAP

COMMENT|

The RPNCUR table consists of relative page numbers which are offsets
into the PAGELINK table.  The table is NPHYS16S words long and is
indexed by EMS physical page number.  This table contains the current
EMS mapping within the first megabyte.

The PRPNTAB table points to a contiguous collection of RPN tables, one
per AMRS mapping.  It is (MRS_MAX + 1) * NPHYS16S words long.  RPNCUR
is one of the tables in the collection.

|

	 public  PRPNTAB,PRPNCUR
PRPNTAB  dd	 ?		; Pointer to start of RPNCUR tables
PRPNCUR  dd	 ?		; ...	     current RPNCUR table

COMMENT|

   The PAGELINK table consists of one dword per 16KB logical page in
the EMS system (EMMSIZE shr (14-10)).  PPAGELINK contains the offset
of the start of the PAGELINK table and is allocated dynamically at
startup.  The contents of the table are either @HP_LAST (logical page
is the last one allocated to a handle), or an offset (from PGROUP:0)
into PAGELINK of the next (higher numbered) logical page in the chain
of pages allocated to a handle (perhaps the unallocated handle).

   The HNDLPAGE table is 255 dwords long and is ordered by handle # in
origin-0 (handles 0 through 254 inclusive).  PHNDLPAGE contains the
offset of the start of the HNDLPAGE table and is allocated dynamically
at startup.  The table contents for any particular handle are either
@HP_LAST (no (more) pages allocated to this handle) or an offset (from
PGROUP:0) into the PAGELINK table.  Each such offset in the HNDLPAGE
table represents logical page #0 allocated to this handle.

   The offset from either HNDLPAGE or PAGELINK is mapped into a
physical address as follows:

1.  Subtract the base of the PAGELINK table (found in PPAGELINK) from
    the offset to get an origin-0 index into a table of dwords.

2.  Save this value temporarily (in say TMP).

3.  Shift left this value by (4-2) to convert from a dword index to a
    four-dword index.

4.  Add the contents of LINKBASE[TMP] to this value to get an offset
    (from PGROUP:0) into the PDT.  The four consecutive dwords at this
    address are the current physical 4KB PTEs of this logical page.

To convert this PDT offset into a linear address

1.  Shift left this value by (12-2)-0 to convert from 4KB in dwords to bytes.

|

	 public  HP_LAST,@MAX_EHNDLCNT
@HP_LAST equ	 -1		; Marker for last   entry in HNDLPAGE & PAGELINK
HP_LAST dd	@HP_LAST	; ...
@MAX_EHNDLCNT equ 255		; Maximum # EMS handles allowed

	 public  @RPN_UNUSED,@RPN_UNMAP,@RPN_IDENT
@RPN_UNUSED equ   00FFh 	; The owning handle is unused
@RPN_UNMAP  equ  -1		; This value *MUST* be -1 to match
				; EMS 4.0 spec for unmapping convention
@RPN_IDENT  equ  -2		; This value *MUST* be -2 to allow range
				; testing for both it and @RPN_UNMAP

	 public  TOTPGCNT,REMPGCNT
TOTPGCNT dw	 ?		; Total # 16KB pages in EMS
REMPGCNT dw	 ?		; Available # 16KB pages

	 public  EMM_FNS
EMM_FNS  dw	 PGROUP:EMM_STATUS	; 40 = Get status		1
	 dw	 PGROUP:EMM_FRAME	; 41 = Get page frame		2
	 dw	 PGROUP:EMM_PGCNT	; 42 = Get page count		3
	 dw	 PGROUP:EMM_ALLOC	; 43 = Allocate pages		4
	 dw	 PGROUP:EMM_PGMAP	; 44 = Map handle page		5
	 dw	 PGROUP:EMM_DEALLOC	; 45 = Deallocate pages 	6
	 dw	 PGROUP:EMM_VERSION	; 46 = Get EMM version		7
	 dw	 PGROUP:EMM_SAVEMAP	; 47 = Save page map		8
	 dw	 PGROUP:EMM_RESTMAP	; 48 = Restore page map 	9
	 public  EMM_FNS10,EMM_FNS11
EMM_FNS10 dw	 PGROUP:EMM_E84 	; 49 = Get PMR array	       10
EMM_FNS11 dw	 PGROUP:EMM_E84 	; 4A = Get log ==> phys map    11
	 dw	 PGROUP:EMM_HNDLCNT	; 4B = Get handle count        12
	 dw	 PGROUP:EMM_HNDLNPG	; 4C = Get # pages for handle  13
	 dw	 PGROUP:EMM_ALLHP	; 4D = Get all handle/pages    14
	 dw	 PGROUP:EMM_GETSET	; 4E = Get/set RPNs	       15
	 dw	 PGROUP:EMM_GETSETPART	; 4F = Get/set partial RPNs    16
	 dw	 PGROUP:EMM_MULPGMAP	; 50 = Map/unmap multiple HPs  17
	 dw	 PGROUP:EMM_REALLOC	; 51 = Reallocate pages        18
	 dw	 PGROUP:EMM_GETSETATTR	; 52 = Get/set handle attr     19
	 dw	 PGROUP:EMM_GETSETNAME	; 53 = Get/set handle name     20
	 dw	 PGROUP:EMM_GETHDIR	; 54 = Get handle directory    21
	 dw	 PGROUP:EMM_PGMAPJMP	; 55 = Alter page map & jump   22
	 dw	 PGROUP:EMM_PGMAPCALL	; 56 = Alter page map & call   23
	 dw	 PGROUP:EMM_XMOVEMEM	; 57 = Exchange/move memory    24
	 dw	 PGROUP:EMM_GETPHYS	; 58 = Get mappable physical   25
	 dw	 PGROUP:EMM_GETXINFO	; 59 = Get hardware info       26
	 dw	 PGROUP:EMM_RAWALLOC	; 5A = Allocate raw pages      27
	 dw	 PGROUP:EMM_ALTMAPREG	; 5B = Alternate map registers 28
	 dw	 PGROUP:EMM_BOOT	; 5C = Prepare for warm boot   29
	 dw	 PGROUP:EMM_OSE 	; 5D = Enable/disable OS/E fns 30

if @OEM_EEMS
; EEMS Functions

	 dw	 PGROUP:EMM_E84 	; 5E = Reserved 	       31
	 dw	 PGROUP:EMM_E84 	; 5F = Reserved 	       32
	 dw	 PGROUP:EMM_EGETPHYS	; 60 = Get mappable physical   33
	 dw	 PGROUP:EMM_E84 	; 61 = Generic Accel Card      34
	 dw	 PGROUP:EMM_E84 	; 62 = Reserved 	       35
	 dw	 PGROUP:EMM_E84 	; 63 = Reserved 	       36
	 dw	 PGROUP:EMM_E84 	; 64 = Reserved 	       37
	 dw	 PGROUP:EMM_E84 	; 65 = Reserved 	       38
	 dw	 PGROUP:EMM_E84 	; 66 = Reserved 	       39
	 dw	 PGROUP:EMM_E84 	; 67 = Reserved 	       40
	 dw	 PGROUP:EMM_EGETSYS	; 68 = Get system physical     41
	 dw	 PGROUP:EMM_EPGMAP	; 69 = Map handle page	       42
	 dw	 PGROUP:EMM_EGETSET	; 6A = Get/set RPNs	       43
endif				; IF @OEM_EEMS
NEMM_FNS equ	 ($-EMM_FNS)/2	; # EMM functions supported
endif				; IF @OEM_EMS

; Local function enhancements

	 public  EMM2_FNS
EMM2_FNS dw	 PGROUP:EMM_E84 	; 00 = Reserved
	 dw	 PGROUP:EMM2_GETMCS	; 01 = Get Memory Chain Structure
	 dw	 PGROUP:EMM2_GETMAP	; 02 = Get Memory Map	Structure
	 dw	 PGROUP:EMM2_GETINFO	; 03 = Get INFO structure
	 dw	 PGROUP:EMM2_GETPPM	; 04 = Get PPMTAB structure
	 dw	 PGROUP:EMM2_GETPTE	; 05 = Save PTEs in ES:DI
if @OEM_TIMEMEM
	 dw	 PGROUP:EMM2_MEMTIME	; 06 = Memory timer
else
	 dw	 PGROUP:EMM_E84 	; 06 = Reserved
endif				; IF @OEM_TIMEMEM
if @OEM_EMS
	 dw	 PGROUP:EMM_PGMAPRET	; 07 = Return from PGMAPCALL
else
	 dw	 PGROUP:EMM_E84 	; 07 = Reserved
endif				; IF @OEM_EMS
	 dw	 PGROUP:EMM2_GOREAL	; 08 = Exit from protected mode
	 dw	 PGROUP:EMM2_GLBFLAG	; 09 = Flip bits in GLB_FLAG
	 dw	 PGROUP:EMM2_DBGFLAG	; 0A = Flip bits in DBG_FLAG
	 dw	 PGROUP:EMM2_DB2FLAG	; 0B = Flip bits in DB2_FLAG
	 dw	 PGROUP:EMM2_CM3FLAG	; 0C = Flip bits in CM3_FLAG
	 dw	 PGROUP:EMM2_HIMEM	; 0D = Set HIMEM_CS from BX
if @OEM_SOFT
	 dw	 PGROUP:EMM2_CURSOR	; 0E = Enable/disable virtual cursor
else
	 dw	 PGROUP:EMM_E84 	; 0E = Reserved
endif				; IF @OEM_SOFT
	 dw	 PGROUP:EMM2_REBOOT	; 0F = Reboot the system
if DBG_TRACE
	 dw	 PGROUP:EMM2_TRACE	; 10 = Return trace information
else
	 dw	 PGROUP:EMM_E84 	; 10 = Reserved
endif				; IF DBG_TRACE
if @OEM_ROMSCAN
	 dw	 PGROUP:EMM2_RAMSCAN	; 11 = High DOS memory RAM scan
else
	 dw	 PGROUP:EMM_E84 	; 11 = Reserved
endif				; IF @OEM_ROMSCAN
	 dw	 PGROUP:EMM2_ROMSWAP	; 12 = System ROM swap in/out
	 dw	 PGROUP:EMM2_ROMRW	; 13 = Swapped ROM write enable
	 dw	 PGROUP:EMM2_POSCOPY	; 14 = Copy POS data into ES:DI
if @OEM_WIN3
	 dw	 PGROUP:EMM2_GOREALWIN3 ; 15 = Enter real mode for Windows 3
else
	 dw	 PGROUP:EMM_E84 	; 15 = Reserved
endif				; IF @OEM_WIN3
	 dw	 PGROUP:EMM2_GETTEXT	; 16 = Get message text
if @OEM_WIN3
	 dw	 PGROUP:EMM2_INITWIN3	; 17 = Initialize for Windows
else
	 dw	 PGROUP:EMM_E84 	; 17 = Reserved
endif				; IF @OEM_WIN3
if @OEM_SYS eq @OEMSYS_RET
	 dw	 PGROUP:EMM2_PSMEM	; 18 = Periscope memory functions
else
	 dw	 PGROUP:EMM_E84 	; 18 = Reserved
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 dw	 PGROUP:EMM2_PHYS2LIN	; 19 = Translate physical to linear
	 dw	 PGROUP:EMM2_SETPTE	; 1A = Set single PTE
if @OEM_FLEXROM
	 dw	 PGROUP:EMM2_FLEXINFO	; 1B = Copy FLEXROM data to ES:DI
else
	 dw	 PGROUP:EMM_E84 	; 1B = Reserved
endif				; IF @OEM_FLEXROM
	 dw	 PGROUP:EMM2_GETOLDINT	; 1C = Get BIOS entry point for INT AL
					;      before 386MAX initilization
	 dw	 PGROUP:EMM2_DISPSTR	; 1D = Display string through INT 10h
	 dw	 PGROUP:EMM2_EXTADDR	; 1E = Get extended memory address into ES:DI
if @OEM_DPMI
	 dw	 PGROUP:EMM2_DPMIPRES	; 1F = Check on DPMI presence
else
	 dw	 PGROUP:EMM_E84 	; 1F = Reserved
endif				; IF @OEM_DPMI
	 dw	 PGROUP:EMM2_GETMAXINT	; 20 = Get BIOS entry point for INT AL
					;      after 386MAX initilization
	 dw	 PGROUP:EMM2_DSTKS	; 21 = Get/Set DOS stacks info
	 dw	 PGROUP:EMM2_INITREST	; 22 = Load module INIT_PROT/REST_PROT
	 dw	 PGROUP:EMM2_HARPOINFO	; 23 = Set globals containing HARPO info
	 dw	 PGROUP:EMM2_GSLINK58	; 24 = Get/Set 5802/5803 link state
	 dw	 PGROUP:EMM2_TMPCLOSE	; 25 = Temporarily close high DOS
	 dw	 PGROUP:EMM2_MALLOC	; 26 = Call MAC_ALLOC
	 dw	 PGROUP:EMM2_DLGROUP	; 27 = Subfunctions for DLGROUP support
if @OEM_VIRTUALMEM
	 dw	 PGROUP:EMM2_SWAPFILE	; 28 = Get SWAPFILE-related data
else
	 dw	 PGROUP:EMM_E84 	; 28 = Reserved
endif				; IF @OEM_VIRTUALMEM
	 dw	 PGROUP:EMM2_VMVSAPI	; 29 = VM Vendor-Specific API call
	 dw	 PGROUP:EMM2_PnP	; 2A = Plug 'n Play functions
NEMM2_FNS equ	 ($-EMM2_FNS)/2  ; # EMM2 functions supported

	 public  LAST_EMSHNDL,LOTUS_EMSHNDL
LAST_EMSHNDL dw  ?		; # of last EMS handle to be allocated
LOTUS_EMSHNDL dw 0		; # of last EMS handle to be allocated

if @OEM_EMS
	 public  GETSET_FNS
GETSET_FNS dw	 PGROUP:EMM_GETSET0
	 dw	 PGROUP:EMM_GETSET1
	 dw	 PGROUP:EMM_GETSET2
	 dw	 PGROUP:EMM_GETSET3
GETSET_CNT equ	 ($-GETSET_FNS)/2

	 public  EMMBUG
EMMBUG	 db	 0		; EMM bug level:
				; 0 = debugging off
				; 1 = mark PTEs after saving page map as Read-only
				; 2 = mark PTEs after saving page map as Supervisor
endif				; IF @OEM_EMS

EDATA	 ends			; End EDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

if @OEM_EMS
	 extrn	 JMM_TEST:far
endif				; IF @OEM_EMS

JCODE	 ends			; End JCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I67_ECODE
@QMAX_I67_ECODE:		; Mark module start in .MAP file

	 extrn	 WRAP_ENABLE:near
	 extrn	 IRETD_COM:near
	 extrn	 INT0D_IRET_TF:near
	 extrn	 FLUSH_TLB:near
if @OEM_EMS
	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC67:near
	 extrn	 COPY2LCL:near
	 extrn	 PURGE_RPNCUR:near
;;;;;;;; extrn	 DMA_WAIT:near
endif				; IF @OEM_EMS
if @OEM_XMS
	 extrn	 INIT_XMS:near
	 extrn	 XMS_XLAT:near
endif				; IF @OEM_XMS
	 extrn	 EMM2_GETTEXT:near
	 extrn	 EMM2_GETMCS:near
	 extrn	 EMM2_GETMAP:near
	 extrn	 EMM2_GETINFO:near
	 extrn	 EMM2_GETPPM:near

if @OEM_TIMEMEM
	 extrn	 EMM2_MEMTIME:near
endif				; IF @OEM_TIMEMEM
if @OEM_EMS
	 extrn	 EMM_PGMAPRET:near
endif				; IF @OEM_EMS
	 extrn	 EMM2_GOREAL:near
if @OEM_WIN3
	 extrn	 EMM2_GOREALWIN3:near
	 extrn	 EMM2_INITWIN3:near
endif				; IF @OEM_WIN3
	 extrn	 EMM2_GETPTE:near
	 extrn	 EMM2_PHYS2LIN:near
	 extrn	 EMM2_SETPTE:near
	 extrn	 EMM2_GETOLDINT:near
	 extrn	 EMM2_DISPSTR:near
	 extrn	 EMM2_EXTADDR:near
if @OEM_DPMI
	 extrn	 EMM2_DPMIPRES:near
endif				; IF @OEM_DPMI
	 extrn	 EMM2_DSTKS:near
	 extrn	 EMM2_INITREST:near
	 extrn	 EMM2_HARPOINFO:near
	 extrn	 EMM2_GSLINK58:near
	 extrn	 EMM2_TMPCLOSE:near
	 extrn	 EMM2_MALLOC:near
	 extrn	 EMM2_DLGROUP:near
	 extrn	 EMM2_SWAPFILE:near
	 extrn	 EMM2_VMVSAPI:near
	 extrn	 EMM2_PnP:near

	 extrn	 EMM2_GLBFLAG:near
	 extrn	 EMM2_DBGFLAG:near
	 extrn	 EMM2_DB2FLAG:near
	 extrn	 EMM2_CM3FLAG:near
	 extrn	 EMM2_HIMEM:near

if @OEM_FLEXROM
	 extrn	 EMM2_FLEXINFO:near
endif				; IF @OEM_FLEXROM

if @OEM_SOFT
	 extrn	 EMM2_CURSOR:near
endif				; IF @OEM_SOFT

	 extrn	 EMM2_REBOOT:near

if DBG_TRACE
	 extrn	 EMM2_TRACE:near
endif				; IF DBG_TRACE

if @OEM_ROMSCAN
	 extrn	 EMM2_RAMSCAN:near
endif				; IF @OEM_ROMSCAN
	 extrn	 EMM2_GOREAL_HI:near
	 extrn	 EMM2_ROMSWAP:near
	 extrn	 EMM2_ROMRW:near
	 extrn	 EMM2_GETMAXINT:near

if @OEM_SYS eq @OEMSYS_RET
	 extrn	 EMM2_PSMEM:near
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 extrn	 EMM2_POSCOPY:near

if @OEM_EMS
	 extrn	 EMM_GETSETPART:near
	 extrn	 EMM_MULPGMAP:near
	 extrn	 EMM_REALLOC:near
	 extrn	 EMM_GETSETATTR:near
	 extrn	 EMM_GETSETNAME:near
	 extrn	 EMM_GETHDIR:near
	 extrn	 EMM_PGMAPJMP:near
	 extrn	 EMM_PGMAPCALL:near
	 extrn	 EMM_XMOVEMEM:near
	 extrn	 EMM_GETPHYS:near
	 extrn	 EMM_GETXINFO:near
	 extrn	 EMM_RAWALLOC:near
	 extrn	 EMM_ALTMAPREG:near
	 extrn	 EMM_BOOT:near
	 extrn	 EMM_OSE:near
endif				; IF @OEM_EMS

if @OEM_EEMS
	 extrn	 EMM_EGETPHYS:near
	 extrn	 EMM_EGETSYS:near
	 extrn	 EMM_EPGMAP:near
	 extrn	 EMM_EGETSET:near
endif				; IF @OEM_EEMS

if @OEM_VCPI
	 extrn	 EMM_VCPI:near
endif				; IF @OEM_VCPI

if @OEM_VIRTUALMEM
	 extrn	 VMM_DRAIN_POOL:near
endif				; IF @OEM_VIRTUALMEM

if @OEM_EMS
	 FPPROC  INT67 -- INT 67h Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Direct INT 67h interrupt handler (instead of using the one
in low memory).

|

if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 near ptr INTPROC67 ; Jump if so (INTCOM catches DPMI calls)
endif				; IF @OEM_DPMI
	 cmp	 [esp].NRM_CS,seg PGROUP ; Check against device driver's CS
	 org	 $-2
	 public  INT67A_HIMEM_CS
INT67A_HIMEM_CS label near
	 org	 $+2
	 jne	 short @F	; Jump if not

	 cmp	 [esp].NRM_EIP.ELO,offset cs:RESINT67_INT[2] ; Same offset?
	 je	 short INT67_ACT ; Jump if so as it's time to act
@@:
if @OEM_VCPI
	 cmp	 ax,(@VCPI shl 8) or @VCPI_EPM ; Izit a VCPI mode switch call?
	 je	 short INT67_ACT ; Yes, don't reflect to VM86

	 cmp	 ax,(@VCPI shl 8) or @VCPI_SIBV ; Izit a VCPI set interrupt base vector?
	 je	 short INT67_ACT ; Yes, don't reflect to VM86
endif				; IF @OEM_VCPI

	 test	 DBG_FLAG,@DBG_X67 ; Skip INT 67h IDT trap?
	 jnz	 near ptr INTPROC67 ; Yes, continue on

; Check the next entry in the interrupt vector chain

	 push	 DTE_D4GB	; Get all memory data selector
	 pop	 es		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 cmp	 INT00_VEC.VSEG[67h*type INT00_VEC],seg PGROUP ; Check against next handler
	 org	 $-2
	 public  INT67B_HIMEM_CS
INT67B_HIMEM_CS label near
	 org	 $+2
	 jne	 near ptr INTPROC67 ; Jump to low memory handler

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

; Put caller's return address on its stack and set the return address
; to that of the device driver

	 sub	 [ebp].INTXX_ESP.ELO,3*2 ; Make room for CS:IP, FL of RESINT67

	 movzx	 eax,[ebp].INTXX_SS ; Get caller's stack segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 edi,[ebp].INTXX_ESP.ELO ; Get caller's stack offset
	 add	 edi,eax	; ES:EDI ==> caller's stack

	 lea	 ax,RESINT67_INT[2] ;  Get device driver's IP
	 xchg	 ax,[ebp].INTXX_EIP.ELO ; Swap with caller's IP
S32	 stos	 es:[edi].ELO	; Save on caller's stack

	 mov	 ax,HIMEM_CS	; Get device driver's CS in high DOS memory
	 xchg	 ax,[ebp].INTXX_CS ; Swap with caller's CS
S32	 stos	 es:[edi].ELO	; Save on caller's stack

	 mov	 ax,[ebp].INTXX_EFL.ELO ; Get caller's flags
S32	 stos	 es:[edi].ELO	; Save on caller's stack

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Get caller's AX

	 jmp	 short INT67_ACT1 ; Join common code

INT67_ACT:
	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
INT67_ACT1:
	 mov	 [ebp].INTXX_INTNO,4*67h + offset PGROUP:INTPROC00Z ; Mark as INT 67h

	 push	 DTE_DS 	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_DS 	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

if @OEM_VCPI and @VCP_OLD
	 cmp	 ah,3Fh 	; Izit old VCPI call?
	 je	 short INT67_VCPI ; Yes
INT67_XVCPI:
endif				; IF @OEM_VCPI and @VCP_OLD

	 lea	 ecx,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 ecx,LAST_INTCOM ; Swap with previous frame offset
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 ecx,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,cx ; Save it
	 shr	 ecx,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,cx ; Save it

	 cmp	 ah,40h 	; Check against minimum function code
	 jb	 near ptr EMM_E84 ; Invalid function code

	 and	 GLB_FLAG,not @GLB_P67 ; Mark as not a PORT67 function

	 jmp	 short EMU_INT67_COM ; Join common code

if @OEM_VCPI and @VCP_OLD
INT67_VCPI:
	 cmp	 cx,'QE'        ; Ensure valid
	 jne	 short INT67_XVCPI ; Not this time

	 cmp	 dx,'MM'        ; Ensure valid
	 jne	 short INT67_XVCPI ; Not this time

	 mov	 [ebp].INTXX_EAX.ELO.HI,0 ; Return code OK

	 mov	 ax,HIMEM_CS	; Setup ES as return segment
	 mov	 [ebp].INTXX_ES,ax ; Save as caller's ES

	 lea	 ax,OLDVCPI	; ES:DI ==> old VCPI handler
	 mov	 [ebp].INTXX_EDI.ELO,ax ; Save as caller's DI

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 iretd			; Return to caller
endif				; IF @OEM_VCPI and @VCP_OLD

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT67	 endp			; End INT67 procedure
endif				; IF @OEM_EMS
	 FPPROC  EMU_INT67 -- EMS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle all EMS functions.

On entry:

PUSHAD has been done.

Error code is on the stack.

Caller's IP has been incremented past the instruction.

LAST_INTCOM has been saved into ICOMLO/HI.

SS:EBP	 ==>	 INTXX_STR

|

	 mov	 [ebp].INTXX_INTNO,4*67h + offset PGROUP:INTPROC00Z ; Mark as INT 67h

	 mov	 ax,DTE_DS	; Setup DS & ES for later code
	 mov	 ds,ax
	 mov	 es,ax
	 assume  ds:PGROUP,es:PGROUP

	 or	 GLB_FLAG,@GLB_P67 ; Mark as a PORT67 function
EMU_INT67_COM:
	 mov	 ax,DTE_PDT	; Setup FS with PDT selector
	 mov	 fs,ax
	 assume  fs:PDTGRP	; Tell the assembler about it

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Restore original registers
	 mov	 cx,[ebp].INTXX_ECX.ELO
	 mov	 dx,[ebp].INTXX_EDX.ELO

	 test	 DB2_FLAG,@DB2_I67 ; Debug this INT 67h call?
	 jz	 short INT67_XDBG ; Not this time

	 int	 01h		; Call debugger
INT67_XDBG:
if @OEM_EMS
	 cmp	 ah,NEMM2_FNS	; Check for EMM2 functions starting at 00h
	 jb	 near ptr INT67_JMP2 ; It's within range

	 sub	 ah,40h 	; Convert to origin-0
	 jc	 near ptr EMM_E84 ; Invalid function code

	 cmp	 ah,NEMM_FNS	; More than we can handle?
	 jae	 short INT67_JMP1 ; Yes, see if it's VCPI

	 movzx	 ebx,ah 	; Copy to index register, clear high-order bytes

	 jmp	 EMM_FNS[ebx*2] ; Take appropriate action

INT67_JMP1:
if @OEM_VCPI
	 cmp	 ah,@VCPI-40h	; Izit VCPI function?
	 jne	 short INT67_XX67 ; Jump if not

	 test	 GLB_FLAG,@GLB_P67 ; Did we get here via PORT67?
	 jz	 near ptr EMM_VCPI ; Jump if not

	 test	 DBG_FLAG,@DBG_X67 ; Skip INT 67h IDT trap?
	 jz	 near ptr EMM_VCPI ; No, continue on

; We need to IRETD to the current Int 67h handler after creating a
; V86 mode IRET frame on the stack in INTXX_STR to give MEMLIMIT
; a crack at VCPI calls.  We're effectively converting the OUT DX,AL
; to POP DX / PUSHF / CLI / CALL ssss:oooo to the current Int 67h
; entry point.

; Note that DX has already been stripped from the stack.

	 push	 DTE_D4GB	; Get all memory data selector
	 pop	 es		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 ax,INT00_VEC.VSEG[67h*type INT00_VEC] ; Get current V86 segment
	 xchg	 [ebp].INTXX_CS,ax ; Change segment to IRETD to
	 movzx	 ebx,INT00_VEC.VOFF[67h*type INT00_VEC] ; Get current V86 offset
	 xchg	 [ebp].INTXX_EIP,ebx ; Change offset for IRETD

	 assume  es:AGROUP	; Tell the assembler

	 movzx	 esi,[ebp].INTXX_SS ; Get stack segment
	 shl	 esi,4-0	; Convert paras to bytes
	 sub	 [ebp].INTXX_ESP,size IRET_STR ; Make room for IRET frame
	 movzx	 edx,[ebp].INTXX_ESP.ELO ; Get low word of ESP
	 add	 esi,edx	; AGROUP:ESI ==> IRET_STR
	 mov	 AGROUP:[esi].IRET_IP,bx ; Save original return address
	 mov	 AGROUP:[esi].IRET_CS,ax ; Save original return offset
	 mov	 cx,[ebp].INTXX_EFL.ELO ; Get flags
	 mov	 AGROUP:[esi].IRET_FL,cx ; Save flags

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 iretd			; Return to caller

INT67_XX67:
	 assume  es:PGROUP	; Tell the assembler
endif				; IF @OEM_VCPI
	 jmp	 EMM_E84	; Yes, treat as invalid function

INT67_JMP2:
else
	 cmp	 ah,NEMM2_FNS	; Check for EMM2 functions starting at 00h
	 jae	 short EMM_E84	; Invalid function code
endif				; IF @OEM_EMS
	 movzx	 ebx,ah 	; Copy to index register, clear high-order bytes

	 jmp	 EMM2_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_INT67 endp			; End EMU_INT67 procedure
if @OEM_EMS
	 NPPROC  EMM_STATUS -- Get EMM Status
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 1, AH = 40h

Return EMS status (always OK)

No errors possible

|

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_STATUS endp 		; End EMM_STATUS procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_FRAME -- Get EMM Frame
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 2, AH = 41h

Return segment of EMM 64KB page frame in AX

Error return 84 if NPHYS16F < 4

|

	 sti			; Allow interrupts

	 cmp	 NPHYS16F,4	; Page frame available?
	 jb	 near ptr EMM_E84 ; No, so that's an error

	 mov	 ax,FRAME	; Return the segment ...
	 mov	 [ebp].INTXX_EBX.ELO,ax ; in BX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_FRAME endp			; End EMM_FRAME procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_PGCNT -- Get Page Count
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 3, AH = 42h

Return # unallocated 16KB pages in BX,
	     total # 16KB pages in DX

No errors possible

|

if @OEM_VIRTUALMEM
	 call	 VMM_DRAIN_POOL ; Drain the pool if it's filled
endif				; IF @OEM_VIRTUALMEM

	 sti			; Allow interrupts

	 mov	 ax,REMPGCNT	; Get # remaining 16KB pages
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return it in BX

	 mov	 ax,TOTPGCNT	; Get total # 16KB pages
	 mov	 [ebp].INTXX_EDX.ELO,ax ; Return in DX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGCNT endp			; End EMM_PGCNT procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_ALLOC -- Allocate Logical Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 4, AH = 43h

Allocate BX 16KB pages
Return corresponding handle in DX

Error return 89 if BX = 0 (unless entered at EMM_ALLOC_ZERO)
	     87 if BX > TOTPGCNT
	     88 if BX > REMPGCNT
	     85 if no available handles
	     80 if software inconsistency

|

	 cmp	 [ebp].INTXX_EBX.ELO,0 ; Allocating zero pages?
	 je	 near ptr EMM_E89 ; Yes, so that's an error

	 public  EMM_ALLOC_ZERO
EMM_ALLOC_ZERO:
if @OEM_VIRTUALMEM
	 call	 VMM_DRAIN_POOL ; Drain the pool if it's filled
endif				; IF @OEM_VIRTUALMEM
	 sti			; Allow interrupts

; See if there is an available handle

	 cmp	 EHNDLCNT,@MAX_EHNDLCNT ; At maximum as yet?
	 je	 near ptr EMM_E85 ; Yes, so that's an error

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get # 16KB pages to allocate

	 cmp	 bx,TOTPGCNT	; More than we ever had?
	 ja	 near ptr EMM_E87 ; Yes, so that's an error

; As we allocate pages to this handle, we cannot tolerate any interruption

	 cli			; Disallow interrupts

	 cmp	 bx,REMPGCNT	; Enough remaining?
	 ja	 near ptr EMM_E88 ; No, so that's an error

; Get a new handle into DX

	 lea	 di,HMAP	; ES:DI ==> HMAP

	 mov	 cx,size HMAP	; # bytes in HMAP
	 mov	 al,0FFh	; Search for not this
    repe scasb			; Continue
	 je	 near ptr EMM_E80 ; Jump if software bug

	 sub	 di,1+offset es:HMAP ; Convert to origin-0
	 mov	 al,HMAP[di]	; Get the byte with a zero bit
	 not	 al		; Complement the bits so BSF works
	 bsf	 si,ax		; Find the first zero bit in AX, put index into SI
	 shl	 di,3		; Times 8 to make room for bit index
	 add	 si,di		; Add byte index into bit index

	 bts	 HMAP.ELO,si	 ; Set the bit
	 jc	 near ptr EMM_E80 ; Jump if software bug

	 mov	 [ebp].INTXX_EDX.ELO,si ; Return in DX

	 mov	 LAST_EMSHNDL,si ; Save for later use

	 sub	 REMPGCNT,bx	; Fewer remaining 16KB pages, too

	 inc	 EHNDLCNT	; One more active EMS handle

; Search through PAGELINK for BX unallocated 16KB pages

	 call	 ALLOCEMS	; Allocate EMS pages
				; Return with EAX = entry of 1st allocated page
	 jc	 near ptr EMM_E80 ; Jump if software bug

	 movzx	 esi,si 	; Zero to use as dword
	 shl	 esi,2		; Times four to index table of dwords
	 add	 esi,PHNDLPAGE	; Plus base of HNDLPAGE table
	 mov	 PGROUP:[esi].PL_NEXT,eax ; Save pointer to first 16KB page

; Keep the handle-count up-to-date

	 movzx	 esi,[ebp].INTXX_EDX.ELO ; Copy handle
	 shl	 esi,1		; Times two to index table of words
	 add	 esi,PHNDLCNT	; Plus pointer to handle-count table
	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get requested LPN count
	 mov	 PGROUP:[esi],ax ; Save as new LPN count

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALLOC endp			; End EMM_ALLOC procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_PGMAP -- Map Handle Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 5, AH = 44h

For handle DX, map logical 16KB page BX to physical 16KB page AL

Error return 83 if DX not valid handle
	     8A if BX >= # 16KB pages allocated to handle DX
	     8B if AL >= NPHYS16S
	     80 if software inconsistency

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cmp	 al,NPHYS16S	; Check physical 16KB page # (origin-0)
	 jnb	 near ptr EMM_E8B ; It's too big

; ------------------------------------------------------------------------------

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

; Map this 16KB page # to physical 16KB page # in PGMAP_PPN

	 movzx	 edi,al 	; Get physical 16KB page # (origin-0)
	 shl	 edi,1		; Times two to index table of words
	 add	 edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	 mov	 di,PGROUP:[edi] ; DI has segment # in paras of this
				; physical page (multiple of 4KB in paras)
	 shr	 di,(12-2)-4	; Convert from paras to 4KB in dwords
				; ES:DI ==> 4 PTEs for this 16 KB physical page

	 movzx	 ebx,[ebp].INTXX_EDX.ELO.LO ; Get the handle
	 mov	 cx,[ebp].INTXX_EBX.ELO ; Get the logical page #

	 cmp	 cx,@RPN_IDENT	; Check for identity or unmapped RPNs
	 jae	 short EMM_PGMAP_IDENT ; Replace with identical or unmapped page

	 shl	 ebx,2		; Times four to index table of dwords
	 add	 ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]

	 inc	 cx		; Count in HNDLPAGE entry
EMM_PGMAP1:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

; If this entry is HP_LAST (last entry),
; then the logical page # is too large

	 cmp	 ebx,HP_LAST	; Check for last entry
	 loopne  EMM_PGMAP1	; Jump if it's not the one we need
	 je	 near ptr EMM_E8A ; So that's an error

	 sub	 ebx,PPAGELINK	; Convert to RPN
	 mov	 esi,ebx	; Save for a moment
	 mov	 edx,ebx	; Save RPN for later use
;;;;;;;; shl	 ebx,2-2	; Convert from dword to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-2	; Convert from dword to four-dword index
	 add	 esi,PGROUP:[ebx] ; Plus the corresponding offset

; ES:ESI = address of PTEs in PDT for this 16KB page
; ES:DI = address in PDT of this physical page (calculated above)

; ES:DI = address in PDT of this physical page (calculated above)

;;;;;;;; pushf			; Save flags

	 cli			; Disallow interrupts

	 lods	 OFFPDT[esi]	; Get 1st PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 2nd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 3rd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 4th PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

;;;;;;;; popf			; Restore

	 jmp	 short EMM_PGMAP_OK ; Join common OK code

EMM_PGMAP_IDENT:
	 cli			; Disallow interrupts

	 push	 [ebp].INTXX_EDX.ELO ; Pass the handle
	 push	 [ebp].INTXX_EBX.ELO ; Pass the logical 16KB page # (origin-0)
	 push	 [ebp].INTXX_EAX.ELO ; Pass the physical 16KB page # (origin-0)
	 call	 PGMAP_COM	; Call common page map routine
	 jc	 near ptr EMM_E8A ; Jump if logical page # not found
				; Return with AX = RPN

	 mov	 dx,[ebp].INTXX_EBX.ELO ; Copy the pseudo-RPN
EMM_PGMAP_OK:

; ------------------------------------------------------------------------------

; Keep the RPNCUR up-to-date with RPN for this physical page

	 mov	 eax,size RPN_STR ; Get size of structure
	 mul	 [ebp].INTXX_EAX.ELO.LO ; Times physical 16KB page # (origin-0)
	 mov	 edi,eax	; Copy to index register
	 mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table

	 mov	 PGROUP:[ebx+edi].RPN_RPN,dx ; Save in structure

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAP endp			; End EMM_PGMAP procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_DEALLOC -- Deallocate Handle and Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 6, AH = 45h

For handle DX, deallocate all pages allocated to it,
mark the handle as available for use, and zero its name.

Error return 83 if DX not valid handle
	     86 if page map saved for this handle
	     80 if software inconsistency

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 movzx	 edx,dx 	; Zero to use as dword


; Ensure this handle isn't already saved in HFRMSAV

	 call	 CHECK_HFRMSAV	; Return ZF=1 if entry is free
				; DS:EBX = corresponding record
	 jnz	 near ptr EMM_E86 ; That's an error


; Remove from HFRMSAV any (handle, LPN) entries with a matching handle

;;;;;;;; xor	 ax,ax		; Remove LPNs >= this value
;;;;;;;; call	 PURGE_HFRMSAV	; Purge the HFRMSAV area

	 movzx	 ebx,dx 	; Get the handle
	 shl	 ebx,2		; Times four to index table of dwords
	 add	 ebx,PHNDLPAGE	; Plus start of HNDLPAGE table

; Purge entries from RPNCUR starting at DS:EBX

	 call	 PURGE_RPNCUR	; Purge 'em


; De-allocate the pages, include them in REMPGCNT

	 call	 DEALLOCEMS	; Deallocate 'em starting at DS:EBX


; Keep the handle-count up-to-date

	 mov	 esi,edx	; Copy handle
	 shl	 esi,1		; Times two to index table of words
	 add	 esi,PHNDLCNT	; Plus pointer to handle-count table
	 mov	 PGROUP:[esi].ELO,0 ; Save as new LPN count


; Zero the handle name

	 mov	 edi,edx	; Move to index register
	 shl	 edi,3-0	; Convert from two dwords to bytes
	 add	 edi,PHNDLNAME	; ES:EDI ==> this handle's name

	 xor	 eax,eax	; Zero the name
S32	 stos	 PGROUP:[edi].EDD ; Zero out the handle name (two dwords worth)
S32	 stos	 PGROUP:[edi].EDD


; Reduce the # active handles by one

	 and	 dx,dx		; OS Handle?
	 jz	 short EMM_DEALLOC1 ; Yes, leave the handle as available

	 dec	 EHNDLCNT	; One fewer active EMS handle
	 js	 near ptr EMM_E80 ; Jump if software bug


; Mark the handle as available again

	 btr	 HMAP.ELO,dx	; Test and reset the bit
	 jnc	 near ptr EMM_E80 ; Jump if software bug


; If this is the EMS handle used by Lotus 1-2-3, mark it as inactive

	 cmp	 dx,LOTUS_EMSHNDL ; Izit the EMS handle used by Lotus 1-2-3?
	 jne	 short @F	; Jump if not

	 mov	 LOTUS_EMSHNDL,0 ; Mark as inactive
@@:
EMM_DEALLOC1:
	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_DEALLOC endp		; End EMM_DEALLOC procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_VERSION -- Get EMM Version Number
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 7, AH = 46h

Return the EMM version # in AL

No errors possible

|

	 sti			; Allow interrupts

	 mov	 al,40h 	; Return version # 4.0

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_VERSION endp		; End EMM_VERSION procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_SAVEMAP -- Save Page Map
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM Function 8, AH = 47h

For handle DX, save the page map

Error return 83 if DX not valid handle
	     8C if no room in save area
	     8D if page map already saved for this handle

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cli			; Disallow interrupts

; Ensure this handle isn't already saved in HFRMSAV

	 call	 CHECK_HFRMSAV	; Return ZF=1 if entry is free
				; DS:EBX = corresponding record
	 jnz	 near ptr EMM_E8D ; In use, so that's an error

	 mov	 PGROUP:[ebx].HFRM_OWNR,dl ; Save as the owning handle

; Copy current context from RPNCUR to save area

	 lea	 edi,PGROUP:[ebx].HFRM_SAVE ; ES:EDI ==> save area for RPNs
	 mov	 esi,PRPNCUR	; DS:ESI ==> EMS frame entries in RPNCUR
	 mov	 ecx,HFRMLEN	; ECX = # bytes in an entry
	 sub	 ecx,size HFRM_OWNR ; Less the owner entry
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Save RPNCUR context

	 test	 DB2_FLAG,@DB2_ESAVE ; Is EMMBUG enabled for EMS save page maps?
	 jz	 short EMM_SAVEMAP_EXIT ; Jump if not

; If EMMBUG = 0, skip this
; If EMMBUG = 1, mark pages as read-only
; If EMMBUG = 2, mark pages as supervisor-only

	 xor	 ax,ax		; Start with no bits set

	 cmp	 EMMBUG,1	; Check level of EMS debugging
	 jb	 short EMM_SAVEMAP_EXIT ; No debugging
	 je	 short EMM_SAVEMAP_L1 ; Mark as read-only only

	 or	 ax,mask $PTE_US ; Clear this bit
EMM_SAVEMAP_L1:
	 or	 ax,mask $PTE_RW ; Clear this bit

	 not	 ax		; Complement to clear
	 mov	 esi,PPDTFRM	; DS:ESI ==> PTEs for EMS frame

	 mov	 cx,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	 jcxz	 EMM_SAVEMAP_EXIT ; Jump if no physical pages in EMS frame

; While updating the page table, we cannot allow any interruptions

;;;;;;;; cli			; Disallow interrupts

	 shl	 cx,14-12	; Convert from 16KB to 4KB
EMM_SAVEMAP_NEXT:
	 and	 OFFPDT.ELO[esi],ax ; Remove R/W and/or User bits

	 add	 esi,size PDT_PTE ; Skip to next entry

	 loop	 EMM_SAVEMAP_NEXT ; Jump if more entries

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush
EMM_SAVEMAP_EXIT:
	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_SAVEMAP endp		; End EMM_SAVEMAP procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_RESTMAP -- Restore Page Map
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 9, AH = 48h

For handle DX, restore the page map

Error return 83 if DX not valid handle
	     8E if page map not previously saved for this handle
	     80 if software inconsistency

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

; Ensure this handle is already saved in HFRMSAV

	 call	 CHECK_HFRMSAV	; Return ZF=1 if entry is free
				; DS:EBX = corresponding record
	 jz	 near ptr EMM_E8E ; It's free, so that's an error

	 mov	 PGROUP:[ebx].HFRM_OWNR,@RPN_UNUSED ; Mark as unused
	 lea	 esi,PGROUP:[ebx].HFRM_SAVE ; DS:ESI ==> source of RPN entries

; Copy these entries to the EMS frame entries in RPNCUR

	 mov	 cx,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	 mov	 edi,PRPNCUR	; ES:EDI ==> EMS frame entries in RPNCUR

	 call	 RPN_DIFF	; Remap CX RPNs at DS:ESI which differ
	 jc	 near ptr EMM_E80 ; Jump if software bug

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_RESTMAP endp		; End EMM_RESTMAP procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_HNDLCNT -- Get Handle Count
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 12, AH = 4Bh

Return in BX the # active handles

No errors possible

|

	 sti			; Allow interrupts

	 mov	 ax,EHNDLCNT	; Get # active EMS handles
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in BX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_HNDLCNT endp		; End EMM_HNDLCNT procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_HNDLNPG -- Get Number of Handle Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 13, AH = 4Ch

For handle DX, return in BX the # pages allocated to it

Error return 83 if DX not valid handle
	     80 if software inconsistency

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX
;;;;;;;; jc	 near ptr EMM_E80 ; Jump if software bug

	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in BX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_HNDLNPG endp		; End EMM_HNDLNPG procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_ALLHP -- Get All Handle Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 14, AH = 4Dh

For all handles, store in ES:DI the handle and # pages allocated to it

Error return 80 if software inconsistency

|

	 sti			; Allow interrupts

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 dx,-1		; Initialize handle to one less than first
	 mov	 cx,@MAX_EHNDLCNT ; CX = maximum # EMS handles
	 mov	 [ebp].INTXX_EBX.ELO,0 ; Initialize # active handles to zero
EMM_ALLHP1:
	 inc	 dx		; Bump to next handle

; Because this function references all handles,
; we cannot tolerate any interruptions

	 cli			; Disallow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 short EMM_ALLHP_LOOP ; Jump if not valid

	 inc	 [ebp].INTXX_EBX.ELO ; Count in another one

; The handle in DX is valid, store it in ES:DI followed
; by the # pages allocated to it

	 mov	 ax,dx		; Copy handle #
S32	 stos	 AGROUP:[edi].ELO ; Save the handle #

; Count # pages allocated to handle DX

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX

S32	 stos	 AGROUP:[edi].ELO ; Save page count
EMM_ALLHP_LOOP:
	 sti			; Allow interrupts

	 loop	 EMM_ALLHP1	; Go around again

	 jmp	 EMM_E00AL	; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALLHP endp			; End EMM_ALLHP procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_GETSET -- Get/Set Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 15, AH = 4Eh

Get/Set Page Mapping Registers (actually RPNs)

Error return 8F if subfunction parameter invalid

|

	 cmp	 al,GETSET_CNT	; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETSET_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSET endp 		; End EMM_GETSET procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_GETSET0 -- Store Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 15, AX = 4E00h

Store Page Mapping Registers (actually RPNs)

Store the contents of the page mapping registers at ES:DI

No errors possible

|

	 sti			; Allow interrupts

	 call	 RPN_STORE	; Store 'em out

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSET0 endp		; End EMM_GETSET0 procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_GETSET1 -- Restore Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 15, AX = 4E01h

Restore Page Mapping Registers (actually RPNs)

Read the contents of the page mapping registers from DS:SI

Error return A3 if any logical or physical page is out of range

|

	 sti			; Allow interrupts

	 call	 RPN_READ	; Read 'em in
	 jc	 near ptr EMM_EA3 ; Something went wrong

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSET1 endp		; End EMM_GETSET1 procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_GETSET2 -- Store and Restore Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 15, AX = 4E02h

Store/restore Page Mapping Registers (actually RPNs)

Store the contents of the page mapping registers at ES:DI,
then read the contents of the page mapping registers from DS:SI

Error return A3 if any logical or physical page in DS:SI is out of range

|

	 sti			; Allow interrupts

	 call	 RPN_STORE	; Store 'em out

	 call	 RPN_READ	; Read 'em in
	 jc	 near ptr EMM_EA3 ; Something went wrong

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSET2 endp		; End EMM_GETSET2 procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  EMM_GETSET3 -- Get Size of Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 15, AX = 4E03h

Get Page Mapping Registers size for EMS frame entries

Return in AL size in bytes of RPNs in user's save area

No errors possible

|

	 sti			; Allow interrupts

	 mov	 al,RPNCURSIZ.LO ; Get # bytes in RPNCUR save area

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSET3 endp		; End EMM_GETSET3 procedure
endif				; IF @OEM_EMS
	 NPPROC  EMM_RETURN -- EMM Return Codes
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

if @OEM_EMS
	 public  EMM_E80
EMM_E80:
	 mov	 ah,80h 	; Software bug
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E83
EMM_E83:
	 mov	 ah,83h 	; Invalid handle
	 jmp	 short EMM_ERR	; Join common error exit code
endif				; IF @OEM_EMS

	 public  EMM_E84
EMM_E84:
	 mov	 ah,84h 	; Invalid function
	 jmp	 short EMM_ERR	; Join common error exit code

if @OEM_EMS
	 public  EMM_E85
EMM_E85:
	 mov	 ah,85h 	; No handles available
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E86
EMM_E86:
	 mov	 ah,86h 	; Matching RPN in save area
	 jmp	 short EMM_ERR	; Join common error exit code
endif				; IF @OEM_EMS

	 public  EMM_E87
EMM_E87:
	 mov	 ah,87h 	; Total # pages in EMS system exceeded
	 jmp	 short EMM_ERR	; Join common error exit code

if @OEM_EMS
	 public  EMM_E88
EMM_E88:
	 mov	 ah,88h 	; Remaining # pages in EMS system exceeded
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E89
EMM_E89:
	 mov	 ah,89h 	; Can't allocate zero pages
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E8A
EMM_E8A:
	 mov	 ah,8Ah 	; Logical page # out of range
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E8B
EMM_E8B:
	 mov	 ah,8Bh 	; Physical page # out of range
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E8D
EMM_E8D:
	 mov	 ah,8Dh 	; Save page map already done
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E8E
EMM_E8E:
	 mov	 ah,8Eh 	; Save page map not previously done
	 jmp	 short EMM_ERR	; Join common error exit code
endif				; IF @OEM_EMS

	 public  EMM_E8F
EMM_E8F:
	 mov	 ah,8Fh 	; Invalid subfunction
	 jmp	 short EMM_ERR	; Join common error exit code

if @OEM_EMS
	 public  EMM_E91
EMM_E91:
	 mov	 ah,91h 	; Non-volatile attrs disallowed
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E92
EMM_E92:
	 mov	 ah,92h 	; Move source and dest overlap
	 jmp	 short EMM_ERR	; Join common error exit code

;;;;;;;; public  EMM_E93
;;;_E93:
;;;;;;;; mov	 ah,93h 	; XMove source or dest exceeds allocated pages
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
;;;;;;;; public  EMM_E94
;;;_E94:
;;;;;;;; mov	 ah,94h 	; XMove conventional and expanded memory overlaps
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
;;;;;;;; public  EMM_E95
;;;_E95:
;;;;;;;; mov	 ah,95h 	; Initial xmove offset too big
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
;;;;;;;; public  EMM_E96
;;;_E96:
;;;;;;;; mov	 ah,96h 	; XMove region length > 1MB
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
;;;;;;;; public  EMM_E97
;;;_E97:
;;;;;;;; mov	 ah,97h 	; Exchange source and dest overlap
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
;;;;;;;; public  EMM_E98
;;;_E98:
;;;;;;;; mov	 ah,98h 	; XMove types undefined or incompatible
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
	 public  EMM_E9B
EMM_E9B:
	 mov	 ah,9Bh 	; No available AMRS
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E9C
EMM_E9C:
	 mov	 ah,9Ch 	; DMA register sets not supported
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_E9D
EMM_E9D:
	 mov	 ah,9Dh 	; AMRS undefined or not allocated
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_EA0
EMM_EA0:
	 mov	 ah,0A0h	; Handle name not found
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_EA1
EMM_EA1:
	 mov	 ah,0A1h	; Duplicate handle name found
	 jmp	 short EMM_ERR	; Join common error exit code

;;;;;;;; public  EMM_EA2
;;;_EA2:
;;;;;;;; mov	 ah,0A2h	; XMove wrap at 1MB
;;;;;;;; jmp	 short EMM_ERR	; Join common error exit code
;;;;;;;;
	 public  EMM_EA3
EMM_EA3:
	 mov	 ah,0A3h	; Unreadable source RPN array
	 jmp	 short EMM_ERR	; Join common error exit code

	 public  EMM_EA4
EMM_EA4:
	 mov	 ah,0A4h	; Access denied
	 jmp	 short EMM_ERR	; Join common error exit code
endif				; IF @OEM_EMS

	 public  EMM_E00AL
EMM_E00AL:
	 mov	 ah,00h 	; All went OK
	 jmp	 short EMM_EXITAL ; Join common exit code

if @OEM_EMS
	 public  EMM_E00
EMM_E00:
	 mov	 ah,00h 	; All went OK
	 jmp	 short EMM_EXIT ; Join common exit code
endif				; IF @OEM_EMS

	 public  EMM_ERR
EMM_ERR:
	 test	 DBG_FLAG,@DBG_EMSERR ; Signal INT 01h on EMS errors?
	 jz	 short EMM_EXITAL ; Jump if not

	 int	 01h		; Call our debugger

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 public  EMM_EXITAL
EMM_EXITAL:
	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Restore original value of AL

	 public  EMM_EXIT
EMM_EXIT:
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Return it

	 public  EMM_EXIT1
EMM_EXIT1:
;;;;;;;; push	 DTE_DS 	; Get our data selector
;;;;;;;; pop	 ds		; Address it
	 assume  ss:PGROUP	; Tell the assembler about it

	 mov	 esp,ebp	; Cut back the stack

	 cli			; Disallow interrupts

	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous frame offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous frame offset
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore it

; Ensure TLB flushed if necessary

	 test	 GLB_FLAG,@GLB_TLB ; Duzit need to be flushed?
	 jz	 short @F	; Jump if not

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 and	 GLB_FLAG,not @GLB_TLB ; Clear for next time
@@:

; Is the 1MB wrap disabled or already enabled?

	 test	 GLB_FLAG,@GLB_X1MB or @GLB_1MB
	 jnz	 short @F	; Yes

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap
@@:

COMMENT|

If any of the following are true, we must remain active.

* Come from Port 67h call
* ON forced
* Weitek support active
* A20 virtually ON

|

	 test	 GLB_FLAG,@GLB_P67 or @GLB_WTK or @GLB_X1MB or @GLB_FORC
	 jnz	 near ptr INT67_IRETD ; Yes, just exit

if @OEM_EMS
	 test	 EMM_FLAG,@EMM_INUSE ; Access key in use?
	 jnz	 near ptr INT67_IRETD ; Yes, just exit
endif				; IF @OEM_EMS

	 cmp	 HARDCNT,0	; Any hardware interrupts outstanding?
	 jne	 near ptr INT67_IRETD ; Yes, just exit

; If we're AUTO active, attempt to go to AUTO inactive

	 test	 GLB_FLAG,@GLB_AUTO ; In AUTO mode?
	 jz	 near ptr INT67_IRETD ; No, just exit

; Note we must be AUTO active to get here

if @OEM_EMS
; If there are any active EMS handles, we can't go inactive

	 cmp	 EHNDLCNT,1	; Check the EMS handle count
	 jne	 near ptr INT67_IRETD ; Jump if some are still active
endif				; IF @OEM_EMS

if @OEM_XMS
; If there are any active XMS handles, we can't go inactive

	 cmp	 XHNDLCNT,1	; Any handles in use?
	 ja	 near ptr INT67_IRETD ; Jump if some are still active
endif				; IF @OEM_XMS

	 public  EMM_EXIT_GOREAL
EMM_EXIT_GOREAL:

; If any of the PTEs in the system board memory are not one-to-one
; with linear address, make them so

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

; Ensure PDE for conventional, and screen memory is mapped in in case
; FIND_PTE finds a PTE which is unmapped and found in that area only
;;;;;;;;
;;;;;;;; mov	 edi,OFFCR3	; ES:EDI ==> page directory base
;;;;;;;; mov	 esi,PDTDIR2	; FS:ESI ==> offset in PDT of 2nd level dir entries
;;;;;;;; mov	 eax,PDBSIZE	; Get # page directory base entries
;;;;;;;; shl	 eax,2-0	; Convert from dwords to bytes
;;;;;;;; add	 esi,ax 	; Skip over initial entries
;;;;;;;; add	 edi,eax	; Skip over initial entries
;;;;;;;;
;;;;;;;; push	 PGROUP:[edi].EDD ; Save the PDE to restore later
;;;;;;;; push	 edi		; Save the offset
;;;;;;;;
;;;;;;;; mov	 eax,OFFPDT[esi] ; Get the PTE
;;;;;;;; mov	 PGROUP:[edi].EDD,eax ; Save into the first level PDIR
;;;;;;;;
; Because we just changed the page table, we must flush the TLB
;;;;;;;;
;;;;;;;; call	 FLUSH_TLB	; Flush the TLB
;;;;;;;;
	 mov	 cx,LOWOFF.ELO	; Get size of system board memory in 1KB
	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 xor	 si,si		; Initialize index into PDT
	 xor	 edx,edx	; Initialize to first PTE
	 xor	 bx,bx		; Initialize flag (0=PTEs 1-1)
EMM_EXIT_NEXTPTE:
	 lods	 OFFPDT[si]	; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate the address

	 cmp	 eax,edx	; Check against expected value
	 je	 short EMM_EXIT_LOOPPTE ; Jump if they're 1-1

if @OEM_EMS

; See if this PTE is unmapped

	 cmp	 eax,@UNMAP_PTE ; Check for unmapped PTE
	 jae	 short EMM_EXIT_SAVEPTE ; It's unmapped, just restore the PTE
endif				; IF @OEM_EMS

; Copy data from the current PTE (EAX) to the one that should be there (EDX)

	 push	 DTE_D4GB	; Get all memory DTE
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

@OFFSEG  equ	 0FF00h 	; Segment in PDT
@OFFPDT  equ	 @OFFSEG shr ((12-2)-4) ; Convert from paras to 4KB in dwords
@OFFBYT  equ	 <@OFFSEG shl (4-0)> ; Convert from paras to bytes

	 REGSAVE <ecx,esi,OFFPDT[@OFFPDT]> ; Save registers and data

	 mov	 eax,edx	; Copy the correct PTE
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 mov	 OFFPDT[@OFFPDT],eax ; Save as new PTE

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 mov	 esi,edx	; ES:ESI ==> source data (current PTE)
	 mov	 edi,@OFFBYT	; ES:EDI ==> destin data (substitute PTE)
	 mov	 ecx,CON1KB	; Get # dwords to swap

; Exchange data between current PTE and expected PTE

@@:
	 lods	 AGROUP:[esi].EDD ; Get next dword
	 xchg	 eax,AGROUP:[edi] ; Swap with other dword
	 mov	 AGROUP:[esi-4],eax ; Save back
	 add	 edi,4		; Skip to next dword

	 loop	 @B		; Jump if more dwords to exchange

	 REGREST <OFFPDT[@OFFPDT],esi,ecx> ; Restore

; Replace all occurences of the PTE in EDX from FS:SI for CX-1 PTEs
; with the PTE in FS:SI-4 and vice versa

	 call	 REPL_PTE	; Replace 'em
EMM_EXIT_SAVEPTE:

; Mark as User/Read-write/Present and mapped

	 mov	 eax,edx	; Copy the correct PTE
	 or	 ax,@PTE_URP or (mask $PTE_AV0)
	 mov	 OFFPDT[si-4],eax ; Save correct PTE

; Although we just changed the page table, we won't refer to this
; page again until we exit at which time we'll flush the page
; translation cache.

	 inc	 bx		; Mark as PTEs not 1-1
EMM_EXIT_LOOPPTE:
	 add	 edx,CON4KB	; Skip to next expected PTE

	 loop	 EMM_EXIT_NEXTPTE ; Jump if more PTEs to check

	 and	 bx,bx		; Were any PTEs not 1-1?
	 jz	 short EMM_EXIT_GOREAL1 ; Not this time

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Initialize the various data areas

	 FIXICALL JGROUP:INIT_DATA,DTE_CSJG ; Initialize 'em
if @OEM_XMS
	 call	 INIT_XMS	; Initialize XMS areas
endif				; IF @OEM_XMS

if @OEM_EMS
	 test	 DBG_FLAG,@DBG_EPTE ; Testing EMS PTEs?
	 jz	 short EMM_EXIT_GOREAL1 ; Jump if not

	 FIXICALL JGROUP:JMM_TEST,DTE_CSJG ; Test 'em
endif				; IF @OEM_EMS
EMM_EXIT_GOREAL1:

; Restore the PDE we saved
;;;;;;;;
;;;;;;;; pop	 edi		; Restore the offset
;;;;;;;; pop	 PGROUP:[edi].EDD ; Restore the PDE
;;;;;;;;
; Because we just changed the page table, we must flush the TLB
;;;;;;;;
;;;;;;;; call	 FLUSH_TLB	; Flush the TLB

	 jmp	 EMM2_GOREAL_HI ; Join common exit code

; Restore the PDE we saved
;;;;;;;;
;;;;;;;; pop	 edi		; Restore the offset
;;;;;;;; pop	 PGROUP:[edi].EDD ; Restore the PDE
;;;;;;;;
; Because we just changed the page table, we must flush the TLB
;;;;;;;;
;;;;;;;; call	 FLUSH_TLB	; Flush the TLB

; N.B.:  THE FOLLOWING CODE IS DUPLICATED AT INT0D_IRETD

	 public  INT67_IRETD
INT67_IRETD:
	 cli			; Disable interrupts

	 test	 [ebp].INTXX_EFL.ELO,mask $TF ; Single stepping?
	 jnz	 near ptr INT0D_IRET_TF ; Yes

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 IRETD_COM	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_RETURN endp 		; End EMM_RETURN procedure
	 NPPROC  REPL_PTE -- Replace PTEs
	 assume  ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Replace all occurrences of the PTE in EDX from FS:SI for CX-1 PTEs
with the PTE in FS:SI-4 and vice versa

On entry:

CX-1	 =	 # remaining PTEs to check
EDX	 =	 new PTE
FS:SI	 ==>	 old PTE

|

	 REGSAVE <eax,ebx,cx,si> ; Save registers

	 sub	 cx,1		; Less the last PTE
	 jbe	 short REPL_PTE_EXIT ; Jump if nothing remains

	 mov	 ebx,OFFPDT[si-4] ; Save old PTE
	 and	 bx,mask $PTE_FRM ; Isolate the address
REPL_PTE_NEXT:
	 lods	 OFFPDT[si]	; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate the address

	 cmp	 eax,edx	; Check for our boy
	 jne	 short REPL_PTE1 ; Jump if not

	 mov	 eax,ebx	; Copy PTE to save

	 jmp	 short REPL_PTE_SAVE ; Join common code

REPL_PTE1:
	 cmp	 eax,ebx	; Check for our boy
	 jne	 short REPL_PTE_LOOP ; Jump if not

	 mov	 eax,edx	; Copy PTE to save

; Mark as User/Read-write/Present and mapped

REPL_PTE_SAVE:
	 or	 ax,@PTE_URP or (mask $PTE_AV0)
	 mov	 OFFPDT[si-4],eax ; Complete the swap
REPL_PTE_LOOP:
	 loop	 REPL_PTE_NEXT	; Jump if more PTEs to check
REPL_PTE_EXIT:
	 REGREST <si,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REPL_PTE endp			; End REPL_PTE procedure
if @OEM_EMS
	 NPPROC  PGMAP_ALL -- Map All RPNCUR Entries Into PTEs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate the RPNCUR entries into PTEs and put them into EMS physical pages.

On exit:

CF	 =	 0 if all went well
	 =	 1 if something went wrong

|

	 REGSAVE <eax,ebx,ecx,esi,ds,es> ; Save registers

	 cld			; String ops forwardly

	 mov	 ax,DTE_DS	; Get data selector
	 mov	 ds,ax
	 mov	 es,ax
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 mov	 cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 jcxz	 PGMAP_ALL_CLC	; Jump if none

	 xor	 esi,esi	; Zero index into RPNCUR
	 mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table
	 xor	 ax,ax		; Zero physical page #
PGMAP_ALL_NEXT:
	 push	 PGROUP:[ebx+esi].RPN_RPN ; Pass the relative 16KB page # (origin-0)
	 push	 ax		; Pass the physical 16KB page # (origin-0)
	 call	 RPNMAP_COM	; Call common page map routine
	 jc	 short PGMAP_ALL_EXIT ; Jump if logical page # not found (note CF=1)

	 add	 esi,size RPN_STR ; Skip to next RPN entry
	 inc	 ax		; Skip to next physical 16KB page #

	 loop	 PGMAP_ALL_NEXT ; Jump if more 16KB pages
PGMAP_ALL_CLC:
	 clc			; Indicate all went well
PGMAP_ALL_EXIT:
	 REGREST <es,ds,esi,ecx,ebx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PGMAP_ALL endp			; End PGMAP_ALL procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  PGMAP_COM -- Common Page Mapping Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate logical page PGMAP_LPN of handle PGMAP_HNDL
into a PTE and save in the physical page PGMAP_PPN in the EMS frame.

If PGMAP_LPN = @RPN_UNMAP, unmap the corresponding physical page.
If PGMAP_LPN = @RPN_IDENT, map in the identity physical page.

**** N.B.:  This routine has been unfolded in EMM_PGMAP ****
****** Changes here should be reflected there as well ******

On entry:

PGMAP_STR filled in.

On exit:

AX	 =	 RPN

CF	 =	 0 if all went well
	 =	 1 if logical page # not found

|

PGMAP_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's return address
PGMAP_PPN  db	 ?,?		; The physical page #
PGMAP_LPN  dw	 ?		; The logical page #
PGMAP_HNDL db	 ?,?		; The handle

PGMAP_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,esi,edi,ds,es> ; Save registers

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

; Map this 16KB page # to physical 16KB page # in PGMAP_PPN

	 movzx	 edi,[ebp].PGMAP_PPN ; Get physical 16KB page # (origin-0)
	 shl	 edi,1		; Times two to index table of words
	 add	 edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	 mov	 di,PGROUP:[edi] ; DI has segment # in paras of this
				; physical page (multiple of 4KB in paras)
	 shr	 di,(12-2)-4	; Convert from paras to 4KB in dwords
				; ES:DI ==> 4 PTEs for this 16 KB physical page

	 movzx	 ebx,[ebp].PGMAP_HNDL ; Get the handle

	 cmp	 bx,@MAX_EHNDLCNT ; Check against maximum
	 jae	 short PGMAP_COM_ERR ; That's an error

	 mov	 cx,[ebp].PGMAP_LPN ; Get the logical page #

	 cmp	 cx,@RPN_IDENT	; Check for identity or unmapped LPN
	 jae	 short PGMAP_COM_IDENT ; Replace with identical or unmapped page

	 shl	 ebx,2		; Times four to index table of dwords
	 add	 ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]

	 inc	 cx		; Count in HNDLEPAGE entry
PGMAP_COM1:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

; If this entry is HP_LAST (last entry),
; then the logical page # is too large

	 cmp	 ebx,HP_LAST	; Check for last entry
	 loopne  PGMAP_COM1	; Jump if it's not the one we need
	 je	 short PGMAP_COM_ERR ; So that's an error

	 sub	 ebx,PPAGELINK	; Convert to (size PL_STR) * 16KB page #
	 mov	 esi,ebx	; Save for a moment
	 mov	 eax,ebx	; Save to return as result
;;;;;;;; shl	 ebx,2-2	; Convert from dword to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-2	; Convert from dword to four-dword index
	 add	 esi,PGROUP:[ebx] ; Plus the corresponding offset

; ES:ESI = offset of PTEs in PDT for this 16KB page
; ES:DI = offset in PDT of this physical page (calculated above)

; DI = offset in PDT of this physical page (calculated above)

	 push	 eax		; Save RPN

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 lods	 OFFPDT[esi]	; Get 1st PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 2nd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 3rd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 4th PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	 popf			; Restore

	 pop	 eax		; Restore RPN

	 jmp	 short PGMAP_COM_OK ; Join common OK code

PGMAP_COM_ERR:
	 stc			; Indicate we had a problem

	 jmp	 short PGMAP_COM_EXIT ; Join common exit code

PGMAP_COM_IDENT:
	 push	 eax		; Save for a moment

	 ja	 short PGMAP_COM_UNMAP ; It's to be unmapped

; Replace the corresponding physical 16KB page with its identity mapping

	 mov	 eax,edi	; Copy the PDT offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

; Mark as present, user-accessible, read-writable, and mapped

	 or	 eax,@PTE_URP or (mask $PTE_AV0)

; If it's outside conventional memory, use EMMBUG

	 cmp	 edi,PPDTVID	; Check against start of video memory
	 jb	 short PGMAP_COM_UNMAP_LOOP ; Jump if in conventional memory
	 jmp	 short PGMAP_COM_UNMAP1 ; Jump if above conventional memory

; Replace the corresponding physical 16KB page with an unmapped one.
; Use an invalid entry

PGMAP_COM_UNMAP:

; Mark as present, user-accessible, read-writable (all so we don't signal
; a page fault), and mapped, but just not physical memory

	 mov	 eax,@UNMAP_PTE or (mask $PTE_AV1) or (mask $PTE_AV0) or @PTE_URP
PGMAP_COM_UNMAP1:

; If EMMBUG = 0, skip this
; If EMMBUG = 1, mark pages as read-only
; If EMMBUG = 2, mark pages as supervisor-only

	 cmp	 EMMBUG,1	; Check middle value
	 jb	 short PGMAP_COM_UNMAP3 ; Skip all this
	 je	 short PGMAP_COM_UNMAP2 ; Mark as read-only

	 and	 ax,not mask $PTE_US ; Mark as supervisor-only
PGMAP_COM_UNMAP2:
	 and	 ax,not mask $PTE_RW ; Mark as read-only
PGMAP_COM_UNMAP3:
PGMAP_COM_UNMAP_LOOP:
;;;;;;;; call	 DMA_WAIT	; Wait for DMA to complete

; DI = offset in PDT of this physical page (calculated above)

	 mov	 cx,16/4	; # 4KB pages in 16KB

	 pushf			; Save flags

	 cli			; Disallow interrupts
@@:
S16	 stos	 OFFPDT[di]	; Unmap the PTE

	 add	 eax,CON4KB	; Skip to next 4KB page

	 loop	 @B		; Jump if more pages to unmap

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	 popf			; Restore flags

	 pop	 eax		; Restore

	 mov	 ax,[ebp].PGMAP_LPN ; Return the logical page #

	 test	 DBG_FLAG,@DBG_EPTE ; Testing EMS PTEs?
	 jz	 short @F	; Jump if not

	 FIXICALL JGROUP:JMM_TEST,DTE_CSJG ; Test 'em
@@:
PGMAP_COM_OK:
	 clc			; Indicate all went well
PGMAP_COM_EXIT:
	 REGREST <es,ds,edi,esi,ecx,ebx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 3*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PGMAP_COM endp			; End PGMAP_COM procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  RPNMAP_COM -- Common RPN Mapping Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate relative page RPNMAP_RPN into a PTE and save
in the physical page RPNMAP_PPN in the EMS frame.

If RPNMAP_RPN = @RPN_UNMAP, unmap the corresponding physical page.
If RPNMAP_RPN = @RPN_IDENT, map in the identity physical page.

On entry:

RPNMAP_STR filled in.

On exit:

CF	 =	 0 if all went well
	 =	 1 if logical page # not found

|

RPNMAP_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's return address
RPNMAP_PPN db	 ?,?		; The physical page #
RPNMAP_RPN dw	 ?		; The logical page #

RPNMAP_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,esi,edi,ds,es> ; Save registers

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

; Map this 16KB page # to physical 16KB page # in PGMAP_PPN

	 movzx	 edi,[ebp].RPNMAP_PPN ; Get physical 16KB page # (origin-0)
	 shl	 edi,1		; Times two to index table of words
	 add	 edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	 mov	 di,PGROUP:[edi] ; DI has segment # in paras of this
				; physical page (multiple of 4KB in paras)
	 shr	 di,(12-2)-4	; Convert from paras to 4KB in dwords
				; ES:DI ==> 4 PTEs for this 16 KB physical page

	 movzx	 ebx,[ebp].RPNMAP_RPN ; Get the RPN, zero high-order word

	 cmp	 bx,@RPN_IDENT	; Check for identity or unmapped LPN
	 jae	 short RPNMAP_COM_IDENT ; Identify or unmap it

	 test	 bx,@BIT0 or @BIT1 ; Ensure it's a multiple of a dword
	 jnz	 short RPNMAP_COM_ERR ; Not this time

	 cmp	 ebx,MAXRPN	; Check against unattainable maximum
	 jae	 short RPNMAP_COM_ERR ; Jump if it's too big

	 mov	 esi,ebx	; Save for a moment
;;;;;;;; shl	 ebx,2-2	; Convert from dword to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-2	; Convert from dword to four-dword index
	 add	 esi,PGROUP:[ebx] ; Plus the corresponding offset

; ES:ESI = offset of PTEs in PDT for this 16KB page
; ES:DI = offset in PDT of this physical page (calculated above)

; DI = offset in PDT of this physical page (calculated above)

	 push	 eax		; Save register

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 lods	 OFFPDT[esi]	; Get 1st PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 2nd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 3rd PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 lods	 OFFPDT[esi]	; Get 4th PTE
	 or	 ax,(mask $PTE_AV0) or (mask $PTE_P) ; Mark as present mapped memory
S16	 stos	 OFFPDT[di]	; Save into low memory of PDT

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	 popf			; Restore

	 pop	 eax		; Restore

	 jmp	 short RPNMAP_COM_OK ; Join common OK code

RPNMAP_COM_ERR:
	 stc			; Indicate something went wrong

	 jmp	 short RPNMAP_COM_EXIT ; Join common exit code

RPNMAP_COM_IDENT:
	 REGSAVE <eax,cx>	; Save for a moment

	 ja	 short RPNMAP_COM_UNMAP ; Join common unmap code

; Replace the corresponding physical 16KB page with its identity mapping

	 mov	 eax,edi	; Copy the PDT offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

; Mark as present, user-accessible, read-writable, and mapped

	 or	 eax,@PTE_URP or (mask $PTE_AV0)

; If it's outside conventional memory, use EMMBUG

	 cmp	 edi,PPDTVID	; Check against start of video memory
	 jb	 short RPNMAP_COM_UNMAP_LOOP ; Jump if in conventional memory
	 jmp	 short RPNMAP_COM_UNMAP1 ; Jump if above conventional memory

; Replace the corresponding physical 16KB page with an unmapped one.
; Use an invalid entry

RPNMAP_COM_UNMAP:

; Mark as present, user-accessible, read-writable (all so we don't signal
; a page fault), and mapped, but just not physical memory

	 mov	 eax,@UNMAP_PTE or (mask $PTE_AV1) or (mask $PTE_AV0) or @PTE_URP
RPNMAP_COM_UNMAP1:

; If EMMBUG = 0, skip this
; If EMMBUG = 1, mark pages as read-only
; If EMMBUG = 2, mark pages as supervisor-only

	 cmp	 EMMBUG,1	; Check middle value
	 jb	 short RPNMAP_COM_UNMAP3 ; Skip all this
	 je	 short RPNMAP_COM_UNMAP2 ; Mark as read-only

	 and	 ax,not mask $PTE_US ; Mark as supervisor-only
RPNMAP_COM_UNMAP2:
	 and	 ax,not mask $PTE_RW ; Mark as read-only
RPNMAP_COM_UNMAP3:
;;;;;;;; call	 DMA_WAIT	; Wait for DMA to complete
RPNMAP_COM_UNMAP_LOOP:

; DI = offset in PDT of this physical page (calculated above)

	 mov	 cx,16/4	; # 4KB pages in 16KB

	 pushf			; Save flags

	 cli			; Disallow interrupts
@@:
S16	 stos	 OFFPDT[di]	; Unmap the PTE

	 add	 eax,CON4KB	; Skip to next 4KB page

	 loop	 @B		; Jump if more pages to unmap

	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	 popf			; Restore flags

	 REGREST <cx,eax>	; Restore

	 test	 DBG_FLAG,@DBG_EPTE ; Testing EMS PTEs?
	 jz	 short @F	; Jump if not

	 FIXICALL JGROUP:JMM_TEST,DTE_CSJG ; Test 'em
@@:
RPNMAP_COM_OK:
	 clc			; Indicate all went well
RPNMAP_COM_EXIT:
	 REGREST <es,ds,edi,esi,ebx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RPNMAP_COM endp 		; End RPNMAP_COM procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  VALID_HNDL -- Validate Handle DX
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate handle in DX.

On entry:

DX	 =	 handle to validate

On exit:

CF	 =	 1 if handle in use
	 =	 0 if not

|

	 cmp	 dx,@MAX_EHNDLCNT-1 ; Check against maximum # EMS handles
	 ja	 short @F	; Jump if out of range (note CF=0)

	 bt	 HMAP.ELO,dx	; Test the bit
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALID_HNDL endp 		; End VALID_HNDL procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  ACTIVE_PAGES -- Get No. Active Pages
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the # active pages for a specified handle

On entry:

DX	 =	 handle

On exit:

AX	 =	 # active pages

|

	 REGSAVE <esi>		; Save register

	 movzx	 esi,dx 	; Copy to index register
	 shl	 esi,1		; Times two to index table of words
	 add	 esi,PHNDLCNT	; Plus pointer to handle-count table
	 mov	 ax,PGROUP:[esi] ; Get # active LPNs

	 REGREST <esi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACTIVE_PAGES endp		; End ACTIVE_PAGES procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  PL3DSSI -- Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the PL3 DS:SI to DTE_D4GB:ESI.

|

	 push	 eax		; Save register

	 mov	 ds,SEL_4GB	; Get our all memory selector
	 assume  ds:nothing	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_DS ; Get segment of save area
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_ESI.ELO ; Copy ESI from PL3 SI
	 add	 esi,eax	; DS:ESI ==> PL3 DS:SI

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PL3DSSI  endp			; End PL3DSSI procedure
endif				; IF @OEM_EMS
	 NPPROC  PL3ESDI -- Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the PL3 ES:DI to DTE_D4GB:EDI.

|

	 push	 eax		; Save register

	 mov	 es,SEL_4GB	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_ES ; Get segment of save area
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 edi,[ebp].INTXX_EDI.ELO ; Copy DI from PL3 DI
	 add	 edi,eax	; ES:EDI ==> PL3 ES:DI

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PL3ESDI  endp			; End PL3ESDI procedure
if @OEM_EMS
	 NPPROC  RPN_STORE -- Store RPNs Out
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Store Page Mapping Registers (actually RPNs) for the entire EMS system
into user's data area.

|

	 REGSAVE <ecx,esi,edi,es> ; Save registers

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:DI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 esi,PRPNCUR	; DS:ESI ==> EMS frame entries in RPNCUR
	 movzx	 ecx,RPNCURSIZ	; ECX = # bytes in RPNCUR

	 pushf			; Save flags
	 cli			; Disallow interrupts

S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Move the bytes

	 popf			; Restore

	 REGREST <es,edi,esi,ecx> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RPN_STORE endp			; End RPN_STORE procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  RPN_READ -- Read RPNs In
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read Page Mapping Registers (actually RPNs) for the entire EMS system
from user's data area.

Note that we read the data into local storage before
remapping any pages.  That way the user's data area can
reside in a page about to mapped out.

On exit:

CF	 =	 0 if all went well
	 =	 1 if something went wrong

|

	 REGSAVE <eax,ecx,esi,edi,ds> ; Save registers

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 eax,esp	; Save stack offset
	 movzx	 ecx,RPNCURSIZ	; CX = # bytes in RPNCUR area
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 mov	 edi,PRPNCUR	; ES:EDI ==> EMS entries in RPNCUR

	 call	 RPN_DIFF	; Remap CX RPNs at DS:ESI which differ
	 mov	 esp,eax	; Cut back the stack
				; Return with CF=1 if error

	 REGREST <ds,edi,esi,ecx,eax> ; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RPN_READ endp			; End RPN_READ procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  RPN_DIFF -- Remap Different RPNs
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy the CX RPN entries at DS:ESI into RPNCUR[edi]
and remap via RPNMAP_COM those that are different from
the existing entries.

On entry:

CX	 =	 # RPNs
DS:ESI	 ==>	 incoming entries
ES:EDI	 ==>	 RPNCUR entries

On exit:

CF	 =	 0 if all went OK
	 =	 1 if logical page not found

|

	 REGSAVE <ax,cx,esi,edi> ; Save registers

	 xor	 ax,ax		; Initialize physical page #
RPN_DIFF_NEXT:
	 cmps	 ds:[esi].RPN_RPN,es:[edi].RPN_RPN ; Compare the RPNs
	 je	 short RPN_DIFF_LOOP ; Same, so just skip over it

	 sub	 esi,size RPN_STR ; Back off to source RPN
	 sub	 edi,size RPN_STR ; ... 	dest

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 push	 ds:[esi].RPN_RPN ; Pass the relative 16KB page # (origin-0)
	 push	 ax		; Pass the physical 16KB page # (origin-0)
	 call	 RPNMAP_COM	; Call common page map routine
	 jc	 short RPN_DIFF_ERR ; Jump if relative page # not found

S32	 movs	 <es:[edi].ELO,ds:[esi].ELO> ; Move RPN

	 popf			; Restore flags
RPN_DIFF_LOOP:
	 inc	 ax		; Skip to next physical 16KB page

	 loop	 RPN_DIFF_NEXT	; Jump if more physical 16KB pages to map

	 clc			; Indicate all went well

	 jmp	 short RPN_DIFF_EXIT ; Join common exit code

RPN_DIFF_ERR:
	 popf			; Restore flags

	 stc			; Indicate something went wrong
RPN_DIFF_EXIT:
	 REGREST <edi,esi,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RPN_DIFF endp			; End RPN_DIFF procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  CHECK_HFRMSAV -- Check HFRMSAV For DX
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the HFRMSAV area for handle DX in use.

On entry:

DL	 =	 handle to check

On exit:

DS:EBX	 ==>	 entry for this handle
ZF	 =	 1 the entry is free
	 =	 0 the entry is in use

|

	 REGSAVE <eax>		; Save register

	 mov	 eax,HFRMLEN	; Get size of each HFRMSAV entry
	 mul	 dl		; Times handle # to get offset into table
	 add	 eax,PHFRMSAV	; Plus base of table
	 mov	 ebx,eax	; Copy to index register

	 cmp	 PGROUP:[ebx].HFRM_OWNR,@RPN_UNUSED ; Izit unused?
				; Return with ZF set if in use, clear if not

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_HFRMSAV endp		; End CHECK_HFRMSAV procedure
endif				; IF @OEM_EMS
;;;	     NPPROC  PURGE_HFRMSAV -- Purge HFRMSAV Area
;;;	     assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; On entry:
;;;
;;; AX	     =	     discard LPNs >= this value
;;; DL	     =	     matching handle
;;;
;;; |
;;;
;;;	     REGSAVE <ax,bx,cx,si,di> ; Save registers
;;;
;;; ; If there is a saved page mapping contexts with the
;;; ; de-allocated logical pages, unmap the page in the saved context.
;;;
;;;	     cmp     NPHYS16F,0     ; Check # entries in HFRMSAV row
;;;	     jz      short PURGE_HFRMSAV_EXIT ; None, so that's all folks
;;;
;;;	     mov     si,PHFRMSAV    ; DS:SI ==> HFRMSAV area
;;;	     mov     cx,@MAX_EHNDLCNT ; CX = # entries in HFRMSAV area
;;;
;;; ; Outer loop:  executed one per HFRM saved mapping context
;;; ; DS:SI ==> HFRM_STR in HFRMSAV area
;;;
;;; PURGE_HFRMSAV_NEXTROW:
;;;	     cmp     PGROUP:[si].HFRM_OWNR,@RPN_UNUSED ; Entry unused?
;;;	     je      short PURGE_HFRMSAV_LOOPROW ; Yes, skip it
;;;
;;;	     push    cx 	    ; Save for a moment
;;;
;;;	     mov     cx,NPHYS16F.ELO ; # (handle, LPN) entries in HFRMSAV row
;;;	     lea     bx,[si].HFRM_SAVE ; DS:BX ==> CX of (handle, LPN) entries
;;; PURGE_HFRMSAV_NEXTCOL:
;;;	     mov     di,PGROUP:[bx].RPN_RPN ; Get saved relative page #
;;;
;;;	     cmp     di,@RPN_IDENT  ; Mapped or identity?
;;;	     jae     short PURGE_HFRMSAV_LOOPCOL ; Yes, skip check
;;;
;;;	     cmp     di,ax	    ; Check against minimum removal value
;;;	     jb      short PURGE_HFRMSAV_LOOPCOL ; Jump if within new range of LPNs
;;;
;;; ; The saved LPN is no longer to be allocated -- unmap it
;;;
;;;	     mov     PGROUP:[bx].RPN_RPN,@RPN_UNMAP ; Remove the RPN
;;;				    ; Leave the handle alone
;;; PURGE_HFRMSAV_LOOPCOL:
;;;	     add     bx,size RPN_STR ; Skip to next RPN entry
;;;
;;;	     loop    PURGE_HFRMSAV_NEXTCOL ; Jump if more entries to check
;;;
;;;	     pop     cx 	    ; Restore
;;; PURGE_HFRMSAV_LOOPROW:
;;;	     add     si,HFRMLEN     ; Skip to next row
;;;
;;;	     loop    PURGE_HFRMSAV_NEXTROW ; Jump if more rows to check
;;; PURGE_HFRMSAV_EXIT:
;;;	     REGREST <di,si,cx,bx,ax> ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; PURGE_HFRMSAV endp		    ; End PURGE_HFRMSAV procedure
if @OEM_EMS
	 NPPROC  SWAP_H0PAGES -- Swap Handle Zero Pages To Start
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap handle zero pages to start of free chain.

On entry:

BX	 =	 # pages to swap

|

	 REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

	 mov	 cx,bx		; CX = # entries we need

; Skip to end of handle zero entries

	 mov	 eax,PHNDLPAGE	; Get start of HNDLPAGE table (handle zero)
@@:
	 mov	 ebx,eax	; Copy to index register
	 mov	 eax,PGROUP:[ebx].PL_NEXT ; Get next link

	 cmp	 eax,HP_LAST	; Last entry?
	 jne	 short @B	; Jump if not

	 lea	 edi,PPHNDLFREE ; DS:EDI ==> ptr to ptr to start of free chain
SWAP_H0PAGES_NEXT:
	 add	 ebx,size PL_STR ; Skip to next entry for search
	 mov	 edi,PGROUP:[edi].PL_NEXT ; Set to next address in free chain

; Search for entry EBX in the free chain

	 mov	 eax,PPHNDLFREE ; DS:EAX ==> ptr to start of free chain
@@:
	 mov	 esi,eax	; Copy to index register
	 mov	 eax,PGROUP:[esi].PL_NEXT ; Get next entry

	 cmp	 eax,ebx	; Izit a match?
	 je	 short SWAP_H0PAGES_MATCH ; Jump if so

	 cmp	 eax,HP_LAST	; Izit the end?
	 jne	 short @B	; Jump if not

	 jmp	 short SWAP_H0PAGES_EXIT ; Jump if not found

SWAP_H0PAGES_MATCH:

; DS:EDI ==> next entry in free chain to link into
; DS:ESI ==> current entry pointing to the one to move to front of free chain

; Delete this entry from the EMS free chain

	 mov	 eax,PGROUP:[ebx].PL_NEXT ; Get this PL's next PL
	 xchg	 eax,PGROUP:[esi].PL_NEXT ; Swap with prev next PL
				; Now EAX = EBX

; Append this entry to the start of the EMS free chain

	 xchg	 eax,PGROUP:[edi].PL_NEXT ; Save as the new head of EMS free chain
	 mov	 PGROUP:[ebx].PL_NEXT,eax ; Point EBX to prev 1st PL of EMS chain

	 loop	 SWAP_H0PAGES_NEXT ; Jump if more entries to swap
SWAP_H0PAGES_EXIT:
	 REGREST <edi,esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_H0PAGES endp		; End SWAP_H0PAGES procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  DEALLOCEMS -- Deallocate EMS Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Deallocate remaining pages starting at DS:EBX and
include them in REMPGCNT.

On entry:

DS:EBX	 ==>	 next page to deallocate

|

	 REGSAVE <eax,ebx,esi,edi> ; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 eax,HP_LAST	; Initialize last entry marker
	 xchg	 eax,PGROUP:[ebx].PL_NEXT ; Mark it as the last entry

	 cmp	 eax,HP_LAST	; Check for last 16KB page
	 je	 near ptr DEALLOCEMS_EXIT ; Jump if it is

	 mov	 esi,eax	; Save start of chain-to-be-freed
DEALLOCEMS_NEXT:
	 mov	 ebx,eax	; Copy to index register

if @OEM_XMS

; Calculate the corresponding linear address so we can append it
; to the XMS free chain

	 sub	 eax,PPAGELINK	; Convert to (size PL_STR) * 16KB page #
	 mov	 edi,eax	; Save for a moment
;;;;;;;; shl	 eax,2-2	; Convert from word to dword index
	 add	 eax,PLINKBASE	; Plus base of PDT PTEs
	 shl	 edi,4-2	; Convert from dword to four-dword index
	 add	 edi,PGROUP:[eax] ; Plus the corresponding offset

	 mov	 eax,edi	; Copy PDT offset
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 mov	 edi,eax	; Set translated address

	 shr	 edi,10-(12-2) ; Convert from 4KB in dwords to 1KB
	 add	 edi,PXMSBMAP	; Plus base address of XMS bytemap allocation table

; Free the sixteen entries in the XMSBMAP table

	 sub	 PGROUP:[edi+0].EDD,@XMSB_ALLOC4 ; Mark as free

	 test	 PGROUP:[edi+0].EDD,@XMSB_FLOW4 ; Were any already free?
	 jnz	 short DEALLOCEMS_ERR ; Jump if so

	 sub	 PGROUP:[edi+4].EDD,@XMSB_ALLOC4 ; Mark as free

	 test	 PGROUP:[edi+4].EDD,@XMSB_FLOW4 ; Were any already free?
	 jnz	 short DEALLOCEMS_ERR ; Jump if so

	 sub	 PGROUP:[edi+8].EDD,@XMSB_ALLOC4 ; Mark as free

	 test	 PGROUP:[edi+8].EDD,@XMSB_FLOW4 ; Were any already free?
	 jnz	 short DEALLOCEMS_ERR ; Jump if so

	 sub	 PGROUP:[edi+12].EDD,@XMSB_ALLOC4 ; Mark as free

	 test	 PGROUP:[edi+12].EDD,@XMSB_FLOW4 ; Were any already free?
	 jnz	 short DEALLOCEMS_ERR ; Jump if so
endif				; IF @OEM_XMS
	 inc	 REMPGCNT	; Count in another available page

	 mov	 eax,PGROUP:[ebx].PL_NEXT ; EAX = next link

	 cmp	 eax,HP_LAST	; Check for last 16KB page
	 jne	 near ptr DEALLOCEMS_NEXT ; Jump if not

	 mov	 edi,PPHNDLFREE ; Get ptr to start of free chain
	 xchg	 esi,PGROUP:[edi].PL_NEXT ; Swap with start of free chain
	 mov	 PGROUP:[ebx].PL_NEXT,esi ; Save as pointer to previous ending
DEALLOCEMS_EXIT:
	 popf			; Restore

	 REGREST <edi,esi,ebx,eax> ; Restore

	 ret			; Return to caller

DEALLOCEMS_ERR:
	 int	 03h		; Call our debugger

	 popf			; Restore

	 jmp	 short DEALLOCEMS_EXIT ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEALLOCEMS endp 		; End DEALLOCEMS procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  ALLOCEMS -- Allocate EMS Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate EMS memory

On entry:

IF	 =	 0 (interrupts disabled)
BX	 =	 # EMS pages to allocate

On exit:

EAX	 =	 entry of first allocated page
CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <ebx,cx,esi,edi> ; Save registers

	 mov	 cx,bx		; CX = # entries we need
	 mov	 esi,PPHNDLFREE ; DS:ESI ==> ptr to start of free chain
	 and	 cx,cx		; Are there any to allocate?
	 jz	 near ptr ALLOCEMS_DONE ; Jump if not
ALLOCEMS_NEXT:
	 cmp	 esi,HP_LAST	; Izit an ending entry?
	 je	 near ptr ALLOCEMS_ERR ; Jump if so

	 mov	 esi,PGROUP:[esi].PL_NEXT ; Get address of next 16KB page

if @OEM_XMS

; Remove this block from the XMS free chain

	 mov	 ebx,esi	; Copy to convert to PDT index
	 sub	 ebx,PPAGELINK	; Convert to (size PL_STR) * 16KB page #
	 mov	 edi,ebx	; Save for a moment
	 mov	 eax,ebx	; Save to return as result
;;;;;;;; shl	 ebx,2-2	; Convert from dword to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 edi,4-2	; Convert from dword to four-dword index
	 add	 edi,PGROUP:[ebx] ; Plus the corresponding offset

	 mov	 eax,edi	; Copy PDT offset
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 mov	 edi,eax	; Set translated address

;;;;;;;; sh?	 edi,10-(12-2) ; Convert from 4KB in dwords to 1KB
	 add	 edi,PXMSBMAP	; Plus base address of XMS bytemap allocation table

; Allocate the sixteen entries in the XMSBMAP table

	 add	 PGROUP:[edi+0].EDD,@XMSB_ALLOC4 ; Mark as allocated

	 test	 PGROUP:[edi+0].EDD,@XMSB_FLOW4 ; Were any already allocated?
	 jnz	 short ALLOCEMS_ERR1 ; Jump if so

	 add	 PGROUP:[edi+4].EDD,@XMSB_ALLOC4 ; Mark as allocated

	 test	 PGROUP:[edi+4].EDD,@XMSB_FLOW4 ; Were any already allocated?
	 jnz	 short ALLOCEMS_ERR1 ; Jump if so

	 add	 PGROUP:[edi+8].EDD,@XMSB_ALLOC4 ; Mark as allocated

	 test	 PGROUP:[edi+8].EDD,@XMSB_FLOW4 ; Were any already allocated?
	 jnz	 short ALLOCEMS_ERR1 ; Jump if so

	 add	 PGROUP:[edi+12].EDD,@XMSB_ALLOC4 ; Mark as allocated

	 test	 PGROUP:[edi+12].EDD,@XMSB_FLOW4 ; Were any already allocated?
	 jnz	 short ALLOCEMS_ERR1 ; Jump if so
endif				; IF @OEM_XMS
;;;;;;;; loop	 ALLOCEMS_NEXT	; Jump if more entries
	 dec	 cx		; Count one out
	 jnz	 near ptr ALLOCEMS_NEXT ; Jump if more entries
ALLOCEMS_DONE:
	 mov	 ebx,PPHNDLFREE ; DS:EBX ==> ptr to start of free chain
	 mov	 eax,HP_LAST	; Save as address of last 16KB page
	 xchg	 eax,PGROUP:[esi] ; Mark as last page allocated
	 xchg	 eax,PGROUP:[ebx] ; Save as offset of next unallocated page

	 clc			; Indicate all went well
ALLOCEMS_EXIT:
	 REGREST <edi,esi,cx,ebx> ; Restore

	 ret			; Return to caller

ALLOCEMS_ERR:
	 int	 03h		; Call our debugger
ALLOCEMS_ERR1:
	 int	 03h		; Call our debugger

	 stc			; Indicate something went wrong

	 jmp	 short ALLOCEMS_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOCEMS endp			; End ALLOCEMS procedure
endif				; IF @OEM_EMS
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_I67 module
