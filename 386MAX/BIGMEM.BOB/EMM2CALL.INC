;' $Header:   P:/PVCS/MAX/386MAX/EMM2CALL.INV   1.1   28 Sep 1995 10:12:56   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; EMM2CALL.INC
;
; Macros and equates for EMM2 functions
;

; Note:  This include file is not mentioned in any MAKEFILE, so we
;	 *MUST* be sure that all changes to it are upward-compatible.

.xcref @EMM2_GETMCS,  @EMM2_GETMAP,	@EMM2_GETINFO, @EMM2_GETPPM	; 01-04
.xcref @EMM2_GETPTE,  @EMM2_MEMTIME,	@EMM2_PGMAPRET,@EMM2_GOREAL	; 05-08
.xcref @EMM2_GLBFLAG, @EMM2_DBGFLAG,	@EMM2_DB2FLAG, @EMM2_CM3FLAG	; 09-0C
.xcref @EMM2_HIMEM,   @EMM2_CURSOR,	@EMM2_REBOOT,  @EMM2_TRACE	; 0D-10
.xcref @EMM2_RAMSCAN, @EMM2_ROMSWAP,	@EMM2_ROMRW,   @EMM2_POSCOPY	; 11-14
.xcref @EMM2_GOREALWIN3, @EMM2_GETTEXT, @EMM2_INITWIN3,@EMM2_PSMEM	; 15-18
.xcref @EMM2_PSINFO,	 @EMM2_PSMAP,	@EMM2_PSROM,   @EMM2_PSRAM	; Subcodes
.xcref @EMM2_PHYS2LIN,	 @EMM2_SETPTE,	@EMM2_FLEXINFO,@EMM2_GETOLDINT	; 19-1C
.xcref @EMM2_DISPSTR,	 @EMM2_EXTADDR, @EMM2_DPMIPRES,@EMM2_GETMAXINT	; 1D-20
.xcref @EMM2_DSTKS,	 @EMM2_INITREST,@EMM2_HARPOINFO,@EMM2_GSLINK58	; 21-24
.xcref @EMM2_TMPCLOSE,	 @EMM2_MALLOC,	@EMM2_DLGROUP,	@EMM2_SWAPFILE	; 25-28
.xcref @EMM2_VMVSAPI							; 29


; Extended Expanded Memory Manager INT 67h Function Calls
;				  Fn =
@EMM2_GETMCS	 equ 01h	; 01 = Get Memory Chain Structure
@EMM2_GETMAP	 equ 02h	; 02 = Get Memory Map	Structure
@EMM2_GETINFO	 equ 03h	; 03 = Get INFO structure
@EMM2_GETPPM	 equ 04h	; 04 = Get PPMTAB structure
@EMM2_GETPTE	 equ 05h	; 05 = Save PTEs in ES:DI

@EMM2_MEMTIME	 equ 06h	; 06 = Memory timer
@EMM2_PGMAPRET	 equ 07h	; 07 = Return from PGMAPCALL
@EMM2_GOREAL	 equ 08h	; 08 = Exit from protected mode
				;      AL=0 unconditionally
				;	 =1 only if EMS memory not in use

@EMM2_GLBFLAG	 equ 09h	; 09 = Flip bits in GLB_FLAG
@EMM2_DBGFLAG	 equ 0Ah	; 0A = Flip bits in DBG_FLAG
@EMM2_DB2FLAG	 equ 0Bh	; 0B = Flip bits in DB2_FLAG
@EMM2_CM3FLAG	 equ 0Ch	; 0C = Flip bits in CM3_FLAG
@EMM2_HIMEM	 equ 0Dh	; 0D = Set new HIMEM_CS value from BX, new
				;      HPDA segment from CX

; The following index *MUST* remain constant for OMNIVIEW
@EMM2_CURSOR	 equ 0Eh	; 0E = Enable/disable cursor virtualization

@EMM2_REBOOT	 equ 0Fh	; 0F = System reboot
@EMM2_TRACE	 equ 10h	; 10 = Return trace table information
@EMM2_RAMSCAN	 equ 11h	; 11 = High DOS memory RAM scan
@EMM2_ROMSWAP	 equ 12h	; 12 = System ROM swap in/out
@EMM2_ROMRW	 equ 13h	; 13 = Swapped ROM write enable
				;      AL=0 Make ROMs read only
				;      AL=1 Make ROMs read/write
@EMM2_POSCOPY	 equ 14h	; 14 = Copy POS data into ES:DI
@EMM2_GOREALWIN3 equ 15h	; 15 = Enter real mode for Windows 3
@EMM2_GETTEXT	 equ 16h	; 16 = Get message text
@EMM2_INITWIN3	 equ 17h	; 17 = Windows initialization,
				;      AL = 0 start of end,
				;      AL = 1 end of end
@EMM2_PSMEM	 equ 18h	; 18 = Periscope memory functions
@EMM2_PSINFO	 equ 00h	;      AL = 0 information
@EMM2_PSMAP	 equ 01h	;      AL = 1 map LPN BX to PPN CL
@EMM2_PSROM	 equ 02h	;      AL = 2 Mark all PSMEM memory read-only
@EMM2_PSRAM	 equ 03h	;      AL = 3 Mark all PSMEM memory read-write
@EMM2_PHYS2LIN	 equ 19h	; 19 = Physical to linear address translation
@EMM2_SETPTE	 equ 1Ah	; 1A = Set single PTE
@EMM2_FLEXINFO	 equ 1Bh	; 1B = Copy FLEXROM data to ES:DI
				;      Return physical address in EDX
@EMM2_GETOLDINT  equ 1Ch	; 1C = Get BIOS entry point for INT AL
				;      before 386MAX initilization
				;      Return SEG:OFF in EDX
@EMM2_DISPSTR	 equ 1Dh	; 1D = Display string through INT 10h
@EMM2_EXTADDR	 equ 1Eh	; 1E = Get extended memory address into ES:DI,
				;      # entries into CX.  See EXTADDR_STR
				;      below for details.
@EMM2_DPMIPRES	 equ 1Fh	; 1F = Check for DPMI presence
@EMM2_GETMAXINT  equ 20h	; 20 = Get BIOS entry point for INT AL
				;      after 386MAX initilization
				;      Return SEG:OFF in EDX
@EMM2_DSTKS	 equ 21h	; 21 = Get/Set DOS stacks info
@DSTKS_GETINFO	 equ 0		;      AL = 0 Get info
@DSTKS_SETINFO	 equ 1		;      AL = 1 Set info
@DSTKS_SETSTATE  equ 2		;      AL = 2 Set state (from BL:  0 off, 1 on)
@EMM2_INITREST	 equ 22h	; 22 = Load module INIT_PROT/REST_PROT
				;      AL = 1 - Call INIT_PROT
				;      AL = 0 - Call REST_PROT
@EMM2_HARPOINFO  equ 23h	; 23 = Set globals containing HARPO information
				;      AL = 0 Pass misc. info to MAX
				;      AL = 1 Pass next subseg to MAX
				;      AL = 2 Get all subseg records
				;      AL = 3 Set HARPO profile filespec
				;      AL = 4 Get HARPO profile filespec
@EMM2_GSLINK58	 equ 24h	; 24 = Get/Set 5803 link state
				;      AL = 0 Return link state in BX
				;      AL = 1 Set link state in BX
@EMM2_TMPCLOSE	 equ 25h	; 25 = Temporarily close high DOS
@EMM2_MALLOC	 equ 26h	; 26 = Unguarded call to MAC_ALLOC
				;      (BX=flags,CX=NPARAS,SI=owner,DI=region)
@EMM2_DLGROUP	 equ 27h	; 27 = DLGROUP subfunctions:
				;      AL = 0 Return DLGROUP size in BX
				;      AL = 1 Link LSEG entries (BX=PSP)
				;      AL = 2 Discard LSEG entries
				;      AL = 3 Calculate EXE file load size
				;		(DX,CX=file len,header at
				;		 CS:DLEXEHDR)
@EMM2_SWAPFILE	 equ 28h	; 28 = Get SWAPFILE-related data
@EMM2_VMVSAPI	 equ 29h	; 29 = VM Vendor-Specific API call
@EMM2_PnP	 equ 2Ah	; 2A = Plug 'n Play functions


EMMOUT	 macro	 FN,SUBFN

	 push	 dx		; Push register for OUT "call"
	 mov	 dx,PORT67	; Address INT 67h through the back door
ifnb <FN>
	 mov	 ah,FN		; Function code into AH
endif				; IFNB <FN>
ifnb <SUBFN>
	 mov	 al,SUBFN	; Subfunction code into AL
endif				; IFNB <SUBFN>
	 out	 dx,al		; Request EMM service

	 endm			; EMMOUT


EXTADDR_STR struc

EXTADDR_ADDR dd  ?		; Starting address in bytes
EXTADDR_LEN  dd  ?		; Length in bytes
EXTADDR_HNDL dw  ?		; Handle #
EXTADDR_TYPE db  ?		; Memory type (see @EXTADDRTYPE_xxx below)
EXTADDR_FLAG db  ?		; Flags       (see @EXTADDRFLAG_xxx below)

EXTADDR_STR ends


; Equates for EXTADDR_TYPE

@EXTADDRTYPE_HMA   equ	 0	; Entry is HMA
@EXTADDRTYPE_EXTUP equ	 1	; ...	   Extended memory bottom up
@EXTADDRTYPE_EXTMD equ	 2	; ...	   Extended memory middle out
@EXTADDRTYPE_EXTDN equ	 3	; ...	   Extended memory top down
@EXTADDRTYPE_XMS   equ	 4	; ...	   XMS memory
@EXTADDRTYPE_EMS   equ	 5	; ...	   EMS memory
@EXTADDRTYPE_DPMI  equ	 6	; ...	   DPMI memory
@EXTADDRTYPE_ABS   equ	 7	; ...	   Remapped memory
@EXTADDRTYPE_LOWF  equ	 8	; ...	   Low DOS memory fill
@EXTADDRTYPE_OVRF  equ	 9	; ...	   High DOS memory fill
@EXTADDRTYPE_ROMF  equ	10	; ...	   ROM fill
@EXTADDRTYPE_PRG   equ	11	; ...	   Program storage
@EXTADDRTYPE_DMA   equ	12	; ...	   DMA buffer
@EXTADDRTYPE_AMRS  equ	13	; ...	   AMRS page tables
@EXTADDRTYPE_PT1   equ	14	; ...	   Page Table level 1
@EXTADDRTYPE_PT2   equ	15	; ...	   Page Table level 2
@EXTADDRTYPE_IGR   equ	16	; ...	   IGROUP code/data
@EXTADDRTYPE_TSS   equ	17	; ...	   TSSs
@EXTADDRTYPE_IOBIT equ	18	; ...	   I/O Bit Permission Map
@EXTADDRTYPE_DHNDL equ	19	; ...	   DPMI memory handle table
@EXTADDRTYPE_LDT   equ	20	; ...	   LDT
@EXTADDRTYPE_LPMLO equ	21	; ...	   Unused part of LPM
@EXTADDRTYPE_DPDIR equ	22	; ...	   DPMI Page Directories
@EXTADDRTYPE_LOAD  equ	23	; ...	   Load module
@EXTADDRTYPE_WIN3  equ	24	; ...	   Windows 3 Paging Import Data
@EXTADDRTYPE_INST  equ	25	; ...	   Windows 3 UMB Instance Data
@EXTADDRTYPE_CFG   equ	26	; ...	   Windows 3 Configuration File
@EXTADDRTYPE_STK   equ	27	; ...	   Stack
@EXTADDRTYPE_EMS16 equ	28	; ...	   EMS 16-bit Tables
@EXTADDRTYPE_IOCHK equ	29	; ...	   I/O Check Tables
@EXTADDRTYPE_EMS32 equ	30	; ...	   EMS 32-bit Tables
@EXTADDRTYPE_XMS32 equ	31	; ...	   XMS 32-bit Tables
@EXTADDRTYPE_MAX   equ	32	; ...	   Static code/data
@EXTADDRTYPE_AVL   equ	33	; ...	   Unallocated
@EXTADDRTYPE_PSM   equ	34	; ...	   Periscope Memory
@EXTADDRTYPE_DPOPM equ	35	; ...	   DPMI old PM save area
@EXTADDRTYPE_DPDYN equ	36	; ...	   DPMI dynamic save area
@EXTADDRTYPE_VDS   equ	37	; ...	   Previous VDS table
@EXTADDRTYPE_LPMHI equ	38	; ...	   Used part of LPM
@EXTADDRTYPE_FGR   equ	39	; ...	   FGROUP code/data
@EXTADDRTYPE_JGR   equ	40	; ...	   JGROUP code/data
@EXTADDRTYPE_BSC   equ	41	; ...	   Backing Store cache
@EXTADDRTYPE_IOTRAP equ 42	; ...	   I/O trapping strucs
@EXTADDRTYPE_WINSIZ equ 43	; ...	   Windows extra physical memory


; Equates for EXTADDR_FLAG

@EXTADDRFLAG_HNDL  equ	80h	; Handle field is valid
@EXTADDRFLAG_NAME  equ	40h	; Name ...


; Equates and structures for variable length High DOS allocators such as
; High STACKS, HPDA, XBIOSHI, and all the HARPO sub-segments

@HARPO_SET_INFO     equ  0	; BL = size of FILES= structure in DOS
@HARPO_SET_SUBSEG   equ  1	; BL=type, BH=region, CX=nparas, DX=flags
@HARPO_GET_SUBSEGS  equ  2	; CX=maximum bytes, ES:DI ==> destination
@HARPO_SET_FILESPEC equ  3	; ES:DI ==> new ASCIIZ profile filespec
@HARPO_GET_FILESPEC equ  4	; Copy ASCIIZ profile filespec to ES:DI

SUBSEG_STR struc
  SUBSEG_TYPE db ?	; Identifier: Usually subsegment type (F,X,B,L,S)
  SUBSEG_NPAR dw ?	; # of paras needed
  SUBSEG_REG  db ?	; Optimized region number:4, Region number:4
  SUBSEG_FLAG dw ?	; Misc flags
SUBSEG_STR ends

; Changes to definition of the flags bit fields and owner values must
; also be made to QUALITAS.H (MAXIMIZE).

SUBSEG_FLAGS record $SFLAG_RSVD:14,$SFLAG_OWNR:2;

@SFO_HARPO	 equ	 00b	; Owner of subsegment is HARPO
@SFO_MAX	 equ	 01b	;	   "             386MAX
@SFO_WINST	 equ	 10b	;	   "             Windows instance data
@SFO_UNK	 equ	 11b	;	   "             totally bogus

@MAX_SUBSEGS	 equ	 16	; Maximum number of subsegments is limited
				; by the number of bits in a word.

