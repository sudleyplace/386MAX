;'$Header:   P:/PVCS/MAX/VXD/VMAX.ASV   1.10   03 Jul 1998 15:30:54   BOB  $
	 title	 VMAX -- 386MAX LoadHi VxD for Windows 3
	 page	 78,130
	 name	 VMAX

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-99 Qualitas, Inc.  All rights reserved.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'

	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'

	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC		; Fixed version of file from DDK

	 include MASM.INC		; From the Qualitas include library
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include OPCODES.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC
	 include VCPI.INC
	 include ROMSEG.INC		; For adapter ROMs

	 include LOAD_SEG.INC		; From the QMAX source code
	 include EMM2CALL.INC
	 include QMAXWIN3.INC
	 include QMAX_FLX.INC

	 include WINDEVID.INC		; From Qualitas include library
	 include SWATVXD.INC		; Define service table

	 include BREAK.INC
	 include VMAX.INC		; Local includes
	 include VMAX_RMI.INC
	 include VMAX_UPD.INC
	 include VMAX_VID.INC
	 include VMAXSINI.INC

	 include WFW.INC		; Homemade include for WFW VxDs
	include PNP.INC

	 include VERSION.INC		; Specific to the VxD
.list
	 page
VxD_IDATA_SEG				; Begin _IDATA segment

	 extrn	 CULL_LIST:byte

ifdef @DEBUG
	 extrn	 MSG_INST:byte, MSG_INST0:byte, MSG_INST1:byte
	 extrn	 MSG_INST_DEV:byte, MSG_INST_DEV0:byte, MSG_INST_DEV1:byte
	 extrn	 MSG_INST_NAME:byte, MSG_INST_NAME0:byte
endif					; IFDEF @DEBUG

ifdef @DEBUG
	 extrn	 MSG_INST_UMB:byte
	 extrn	 MSG_NOVHD:byte
	 extrn	 MSG_INST_LSEG:byte
endif					; IFDEF @DEBUG

	 extrn	 MSG_VLW4_UGH:byte, MSG_VLW5_UGH:byte

ifdef @VGASWAP
	 extrn	 MSG_ADP2_UGH:byte
	 extrn	 MSG_FLX_PTL_UGH:byte
	 extrn	 MSG_VS_UGH:byte
endif				; IFDEF @VGASWAP

ifdef @DEBUG
	 extrn	 MSG_ROMPAM_UGH:byte, MSG_ROMPAM_UGH0:byte
endif				; IFDEF @DEBUG
	extrn	MSG_RAMPAM_HDR:byte
	 extrn	 MSG_RAMPAM_UGH:byte, MSG_RAMPAM_UGH1:byte, MSG_RAMPAM_UGH2:byte
	 extrn	 MSG_SCI:byte
	 extrn	 MSG_MPTL_UGH:byte
	 extrn	 MSG_CR3_PTL_UGH:byte
	 extrn	 MSG_REF_PTL_UGH:byte
	 extrn	 MSG_PnP_PTL_UGH:byte
	 extrn	 MSG_1ST_PTL_UGH:byte
	 extrn	 MSG_ROMSCAN_UGH:byte
	 extrn	 MSG_RAMSCAN_UGH:byte
	 extrn	 MSG_GDPA_UGH:byte
	 extrn	 MSG_ROMADP_UGH:byte
	 extrn	 MSG_HVF_UGH:byte
	 extrn	 MSG_CFG_PTL_UGH:byte
	 extrn	 MSG_STU_PTL_UGH:byte
	 extrn	 MSG_MPTL3_UGH:byte
	 extrn	 MSG_MPTL4_UGH:byte
	 extrn	 MSG_BAGDTS_UGH:byte
	 extrn	 MSG_HAF_UGH:byte
	 extrn	 MSG_UHAF_UGH:byte
	 extrn	 MSG_AIIF_UGH:byte
	 extrn	 MSG_AUIIF_UGH:byte
	 extrn	 MSG_NU_WRN:byte
	 extrn	 MSG_NO_WINA20:byte
	extrn	MSG_IDATA_PRESS:byte

; Special error messages added to find INTEL trouble with DOS 5
	 extrn	 MSG_FTL_AI01:byte
	 extrn	 MSG_FTL_AI02:byte
	 extrn	 MSG_FTL_AI03:byte
	 extrn	 MSG_FTL_AI04:byte
	 extrn	 MSG_FTL_AI05:byte
	 extrn	 MSG_FTL_AI06:byte
	 extrn	 MSG_FTL_AI07:byte
	 extrn	 MSG_FTL_AI08:byte
	 extrn	 MSG_FTL_AI09:byte
	 extrn	 MSG_FTL_AI10:byte
	 extrn	 MSG_FTL_AI11:byte
	 extrn	 MSG_FTL_AI12:byte
	 extrn	 MSG_FTL_AI13:byte
	 extrn	 MSG_FTL_AI14:byte
	 extrn	 MSG_FTL_AI15:byte
	 extrn	 MSG_FTL_AI16:byte
	 extrn	 MSG_FTL_AI17:byte
	 extrn	 MSG_FTL_AI18:byte

FALSE	equ	0		; Do we have the wisdom
TRUE	equ	1		; ... to tell the difference?

@PnP_BIOS_BEG equ 0F0000h	; Starting address of system PnP BIOS (/4KB)
@PnP_BIOS_END equ 100000h	; Ending ...

	public	LCL_PnP_PMCS,LCL_PnP_PMDS
LCL_PnP_PMCS dd ?		; Local copy of PnP code segment base address
LCL_PnP_PMDS dd ?		; ...		    data ...

	 public  FIRST_NONSPAN
FIRST_NONSPAN	 dd	?	; V86 linear address of 1st non-spanning MAC
				; entry in high DOS

	 public  PMI_PAGE_MAP
PMI_PAGE_MAP	 dd	((110h/8)+3)/4 dup (0)	; Space for Get_Device_V86_Pages

@RAMSTART equ	0C0000h 	; Starting physical address for RAM search
@RAMSTOP  equ	100000h 	; Ending ...

@ROMSTART equ	0C0000h 	; Starting physical address for ROM search
@ROMSTOP  equ	0F0000h 	; Ending ...

	public	RAM_ERRMAP
RAM_ERRMAP	dd	(((@RAMSTOP-@RAMSTART) shr 12)/32) dup (0) ; Bitmap
				; of RAM= region assignment errors
RS_V86_ADDR	dd	?	; V86 address in ROM_SCAN
COUNT_DOWN	dd	?	; Page count rounded down
COUNT_SKIP	dd	?	; Page count to skip after loop

	 public  STR_QUALITAS
STR_QUALITAS	 db	'QUALITAS', 0   ; Section name for Get_Profile_Boolean

STR_WINA20		db	'LA20HMA '
STR_VCPIWARN		db	'VCPIWarning', 0
STR_XMSUMBINITCALLS	db	'XMSUMBINITCALLS', 0
STR_EMMEXCLUDE		db	'EMMEXCLUDE', 0
STR_VIRTUALHIGHDOS	db	'VIRTUALHIGHDOS', 0
STR_V86ASSIGN		db	'V86Assign' ,0
STR_V86DISPLAY		db	'V86Display' ,0

OLD_GET_PROFILE_BOOLEAN dd ?	; Address of the original

LOADHI_AII1_OFF  equ	16h	; Offset within service to dispatch code
LOADHI_ADDINSTANCE1 label byte	; Model of dispatch code in LoadHi's service
	 db	 073h, 00Ah		; jnc	LOCALCODE
	 db	 05Bh			; pop	ebx
	 db	 05Fh			; pop	edi
	 db	 05Eh			; pop	esi
	 db	 0C9h			; leaved
	 db	 0FFh, 025h		; jmpn	[OLDSERVICE]
LOADHI_ADDINSTANCE1_LEN equ $-LOADHI_ADDINSTANCE1 ; Length of above code

LOADHI_AII2_OFF  equ	61h	; Offset within service to instancing code
LOADHI_ADDINSTANCE2 label byte	; Model of instancing code in LoadHi's service
	 db	 0BBh, 0FFh, 0FFh, 0FFh, 0FFh ; mov ebx,-1
	 db	 08Bh, 035h		; mov	esi,[HEADPTR]
LOADHI_ADDINSTANCE2_LEN equ $-LOADHI_ADDINSTANCE2 ; Length of above code

; This model is for the Windows 3.0 retail WIN386.EXE

LINKED_AII1_OFF  equ	02Ch	; Offset within linked-in service routine
LINKED_ADDINSTANCE1 label byte	; Model of instancing code within linked-in code
	 db	 003h, 042h, 00Ch	; add	eax,[edx+0C]
	 db	 03Dh, 0, 0, 08h, 0	; cmp	eax,00080000h
	 db	 077h, 055h		; ja	...
	 db	 0BBh, 0FFh, 0FFh, 0FFh, 0FFh ; mov ebx,-1
	 db	 08Bh, 035h		; mov	esi,[HEADPTR]
LINKED_ADDINSTANCE1_LEN equ $-LINKED_ADDINSTANCE1 ; Length to compare

; This model is for the Windows 3.0 debug WIN386.EXE

LINKED_AII2_OFF  equ	0A6h	; Offset within linked-in service routine
LINKED_ADDINSTANCE2 label byte	; Model of instancing code within linked-in code
	 db	 003h, 042h, 00Ch	; add	eax,[edx+0C]
	 db	 03Dh, 0, 0, 08h, 0	; cmp	eax,00080000h
	 db	 077h, 075h		; ja	...
	 db	 0BBh, 0FFh, 0FFh, 0FFh, 0FFh ; mov ebx,-1
	 db	 08Bh, 035h		; mov	esi,[HEADPTR]
LINKED_ADDINSTANCE2_LEN equ $-LINKED_ADDINSTANCE2 ; Length to compare

; SYSTEM.INI variables

	 SYSINI_STRINGS 386MAX,DEFINE	; List of options w/ SYSINI_xxx names

VxD_IDATA_ENDS				; End _IDATA segment
	 page
VxD_DATA_SEG				; Start _DATA segment

ifdef @VGASWAP
	 extrn	 MSG_PIV2_UGH:byte
endif				; IFDEF @VGASWAP

	 extrn	 MSG_HFF_UGH:byte
	 extrn	 MSG_ROMPIV_UGH:byte
	 extrn	 MSG_PIV3_UGH:byte
	 extrn	 MSG_MPB_UGH:byte
	 extrn	 MSG_MPB2_UGH:byte

	 extrn	 FEP_FLAG:byte		; VMAX_FNS

	 extrn	 LoadHi_DDB:tbyte	; Reference data

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 include VMAX_PMI.INC
	 public  PMI_FLAG
PMI_FLAG dd	 ?			; Protected mode init flags

	align	4
	public	OLD_PnP_PMCS,OLD_PnP_PMDS,LaPnPBIOS
OLD_PnP_PMCS dd ?		; Original copy of PnP code segment base address
OLD_PnP_PMDS dd ?		; ...		       data ...
LaPnPBIOS dd	?		; Linear address of PnP BIOS

	public	OffPnP_RMVEC,OffPnP_PMCS,OffPnP_PMOFF
OffPnP_RMVEC dd PnP_RMVEC	; Offset to PnP_RMVEC in PnP_STR or PnP2_STR
OffPnP_PMCS  dd PnP_PMCS	; ...	    PnP_PMCS  ...
OffPnP_PMOFF dd PnP_PMOFF	; ...	    PnP_PMOFF ...

	 public  DEVICE_LIST
DEVICE_LIST dd	 ?		; Pointer to DEVICE_LIST (ECX upon entry to VxD)

	 public  REF_LIN, OLDREF_LIN
REF_LIN  dd	 ?		; Linear address of adjusted reference data
OLDREF_LIN  dd	 ?		; Linear address of original reference data

	 public  PF_V86_OLD, PF_PM_OLD
PF_V86_OLD	 dd	?	; Offset to original V86 Page Fault handler
PF_PM_OLD	 dd	?	; Offset to original PM Page Fault handler

	 public  PDIR_LIN, CFG_LIN, SIS_LIN
PDIR_LIN dd	 0		; Windows linaddr to 386MAX's PTEs
CFG_LIN  dd	 ?		; Linaddr of 386LOAD.CFG text
SIS_LIN  dd	 ?		; Linaddr of Win386_Startup_Info_Struc chain

	 public  DEV_CB_LEN, DEV_CB_OFFSET
DEV_CB_LEN	 dd	0		; Length of our per VM data
DEV_CB_OFFSET	 dd	0		; Offset into CB of our per VM data

	 public  PENDING_ERROR
PENDING_ERROR	 dd	?	; ==> FatalErrorHandler text if not NULL

PTR_T1_LIN dd	 ?		; Windows linaddr of type 1 UMB instance items

; The following constants are adjusted for use in FLEXed ROMs
; These variables must be continguous and may not be rearranged.

	 public  CON_C0000, CON_C6000, CON_C7000, CON_C8000
CON_C0000 dd	 0C0000h	; Constant for snooping around in VGA ROMS
CON_C6000 dd	 0C6000h	; Constant for snooping around in VGA ROMS
CON_C7000 dd	 0C7000h	; Constant for snooping around in VGA ROMS
CON_C8000 dd	 0C8000h	; Constant for snooping around in VGA ROMS

@CON_CNT equ	 ($-CON_C0000)/4 ; Number of such constants

ifdef @VGASWAP
	 public  FLEXROM_LIN, FLEXROM_CNT
FLEXROM_LIN dd	 ?		; Linaddr of FLEXROM structure in 386MAX
FLEXROM_CNT dw	 ?		; Count of entries in above structure
endif				; IFDEF @VGASWAP

	 public  PGROUP_LIN, IGROUP_LIN, JGROUP_LIN
PGROUP_LIN	 dd	?		; Linear address of PGROUP
IGROUP_LIN	 dd	?		; Linear address of IGROUP
JGROUP_LIN	 dd	?		; Linear address of JGROUP

	 public  AGROUP_4GB3
AGROUP_4GB3	 dw	?		; AGROUP data selector at PL3

	 public  PGROUP_CS, PGROUP_DS, PGROUP_DS3
PGROUP_CS	 dw	?		; PGROUP code selector
PGROUP_DS	 dw	?		; PGROUP data selector
PGROUP_DS3	 dw	?		; PGROUP data selector at PL3

	 public  IGROUP_CS, IGROUP_DS
IGROUP_CS	 dw	?		; IGROUP code selector
IGROUP_DS	 dw	?		; IGROUP data selector

	 public  JGROUP_CS, JGROUP_DS
JGROUP_CS	 dw	?		; JGROUP code selector
JGROUP_DS	 dw	?		; JGROUP data selector

	 public  FGROUP_DS
FGROUP_DS	 dw	?		; FGROUP data selector

	 public  lpfnXMS_VXD2MAX, lpfnUTL_VXD2MAX
lpfnXMS_VXD2MAX df	0		; FAR PTR to 386MAX XMS code
lpfnUTL_VXD2MAX df	0		; FAR PTR to 386MAX util code

	 public  DOS_VER_H, DOS_VER_L, DOS_FLAG
DOS_VER_H	 db	?		; DOS major version number
DOS_VER_L	 db	?		; DOS minor version number
DOS_FLAG	 dw	?		; DX from AX=3306h INT 21h call

	 public  WIN3_VERSION
WIN3_VERSION	 dw	?		; Windows VMM version #

	 public  ARENA_ANCHOR
ARENA_ANCHOR	 dw	?		; Segment of first MAC in low DOS

	 public  OVRMAC
OVRMAC	 dw	 -1	; V86 segment of 1st UMB MAC from reference data
			; Initialized to 0FFFFh to indicate no high DOS memory
	 public  OVRMAC_PAGE
OVRMAC_PAGE dd	 ?	; V86 page # of 1st UMB MAC

MAC_OWNER dw	 ?	; V86 segment of MAC entry owner field of current MAC

LOADSEG  dw	 ?	; V86 segment of 1st UMB LSEG from reference data
LSEG_V86 dd	 ?	; V86 address of LSEG entry currently under inspection

ifdef @DOSMAX
	 public  LaDSTK_TAB, DSTK_CNT, PDSTKCOM
LaDSTK_TAB	 dd	0		; Linear address of DSTK_TAB_STR
DSTK_CNT	 dd	0		; Total # of DOS stacks we supply
PDSTKCOM	 dd	0		; Seg:off of common return routine
endif					; IFDEF @DOSMAX

	 public  OLD_GETSET_HMA_INFO
OLD_GETSET_HMA_INFO dd	?	; Offset to original GetSet_HMA_Info handler

ifdef @DEBUG
	 public  CULLNAME_PTR, CULLNAME_LEN
CULLNAME_PTR	 dd	?	; ==> to name passed to CULL
CULLNAME_LEN	 dd	?	; Length of name passed to CULL
endif				; IFDEF @DEBUG

LOW_INST_ANCHOR  dd	? ; Anchor for low DOS instance data chain
UMB_INST_ANCHOR  dd	? ; Anchor for UMB instance data chain

	 public  DEV_HDR_PTR
DEV_HDR_PTR dd	 ?	; Start of the device header list

; Filename buffer used by DO_TYPE_3 and DO_TYPE_4

DT_FILENAME_FENCE	db	?	; Normally contains a zero
DT_FILENAME	db	(8+1+3+1) dup (?) ; Space to hold filenames

; Bitmaps of cached ROM pages and AssignDeviceV86Pages'ed pages

	 public  ROM_BMP
ROM_BMP  dd	 ((384/4)/32) dup (0) ; Bitmap of cached ROM pages

	 public  ASSIGN_BMP
ASSIGN_BMP dd	 ((384/4)/32) dup (0) ; Bitmap of assigned pages

	 public  HIGHDOS_MAP
HIGHDOS_MAP	 dd	((110h/8)+3)/4 dup (0)	; Bitmap of high DOS pages

; The UMBs from A0000 thru FF000 need 96 instance data entries
; We've allow for all of those, plus a bunch more for the type 1 & 2 lists

	 public  ADDL_INST
ADDL_INST	 label	tbyte	; Space for additional instance data list
		 db	(200 * (type INSTANCE_ITEM_STR)) dup (?)
ADDL_INST_T	 dd	0	; There's always room for this terminator

ADDL_INST_Z	 dd	OFFSET32 ADDL_INST_T ; Pointer to end of list

VxD_DATA_ENDS				; End _DATA segment
	 page
VxD_ICODE_SEG			; Begin _ITEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 PATCH_XGA:near
	 extrn	 EXCLUDE_PVGA:near
	 extrn	 CHK_VIDEO_ROMS:near
	 extrn	 UPD_CHECK_WIN:near

ifdef @VGASWAP
	 extrn	 HOOK_VDD_SYSCRITINIT:near
endif				; IFDEF @VGASWAP

ifdef @HARPO
	 extrn	 INIT_HARPO:near
endif					; IFDEF @HARPO

ifdef @DOSMAX
	 extrn	 DOSMAX_SHORT:near
	 extrn	 DOSMAX_SYSCRITINIT:near
	 extrn	 DOSMAX_DEVICEINIT:near
	 extrn	 DOSMAX_INITCOMPLETE:near
endif					; IFDEF @DOSMAX

ifdef @ZMAX
	 extrn	 ATTACH_ZMAX:near
endif					; IFDEF @ZMAX
	 page
BeginProc SYS_CRITICAL_INIT		; Handler for Sys_Critical_Init event
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	This event handler must be named SYS_CRITICAL_INIT, and must appear
	at offset 0 in IGROUP in order for SWATVXD to fixup the symbols.

DESCRIPTION:
	Sys_Critical_Init is a device init call.  Devices that have a critical
	function that needs initializing before interrupts are enabled should
	do it at Sys_Critical_Init.  Devices which require a certain range of
	V86 pages to operate (such as the VDD video memory) should claim them
	at Sys_Critical_Init.  SYS VM Simulate_Int, Exec_Int ACTIVITY IS NOT
	ALLOWED.  Returning carry aborts device load only.

On entry:

EBX	=	VM handle
ECX	=	VxD_Desc_Block list

|

	 mov	 DEVICE_LIST,ecx ; Save pointer to VxD_Desc_Block list

	 mov	 PMI_FLAG,0	; Initialize flags
	 mov	 PENDING_ERROR,0 ; Initialize FatalErrorHandler delayer

	 call	 SET_DBG_FLAG	; Set DBG_FLAG from SYSTEM.INI switches

	 BREAK	 DBG_FLAG,@DBG_CRITINIT ; Break if 386MAXSysCriticalInit

	 VxDcall SWAT_Get_Version ; Get SWATVXD version (detect presence)

	 mov	 esi,OFFSET32 MSG_SCI ; Offset to message text
	 call	 DISPLAY	; Put text up on debugging screen

	 VMMcall Get_VMM_Version ; Get Windows VMM version #
	 mov	 WIN3_VERSION,ax ; Save it

; Errors occurring in this next sequence are almost always impossible
; to handle in any decent way.

	 push	 LoadHi_DDB.DDB_Reference_Data ; Physical address of REF_STR
	 push	 256		; Maximum length we're interested in
	 call	 PHYS2LIN	; Convert to linear address in EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; This error can not be handled
; Tell 'em REF_DATA PhysToLinear failed and return to LoadHi VxD

	 mov	 esi,OFFSET32 MSG_REF_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 REF_LIN,eax	; Save for use later

; Get a linear address to the original reference data

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 push	 [edx].REF_OLDREF_PTR ; Get physical address of original refdata
	 push	 256		; Maximum length we're interested in
	 call	 PHYS2LIN	; Convert to linear address in EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; This error can not be handled
; Tell 'em REF_DATA PhysToLinear failed and return to LoadHi VxD

	 mov	 esi,OFFSET32 MSG_REF_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 OLDREF_LIN,eax ; Save for use later

; Locate 386MAX's page tables for use later in the mapping call

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 mov	 eax,[edx].REF_CR3 ; Get copy of 386MAX's CR3

				; Isolate address of PDIR
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM)

	 push	 eax		; Physical address of 386MAX's page directory
	 push	 4096		; Length of the directory
	 call	 PHYS2LIN	; Get linear address into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; This error can not be handled
; Tell 'em CR3 PhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_CR3_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; DS:EAX points to the 1st level page directory

	 mov	 esi,[eax]	; Get 1st PDE
				; Isolate address of 1st set of PTEs
	 and	 esi,(mask $PTE_FRMHI) or (mask $PTE_FRM)

	 push	 esi		; Physical address of 1st page directory
	 push	 4096		; Size of the directory
	 call	 PHYS2LIN	; Get linear address of 386MAX's PTEs into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump is if worked

; This error can not be handled
; Tell 'em 1st PDE PhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_1ST_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 PDIR_LIN,eax	; Save pointer to 386MAX's PTEs for later use

; Setup simple variables from reference data
; Copies are made because they are easier to refer to later

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR

	 mov	 ax,[edx].REF_DOSVER ; Get DOS version # into AX in proper order
	 mov	 DOS_VER_H,ah	; Save major and ...
	 mov	 DOS_VER_L,al	; ...  minor number

	 mov	 ax,[edx].REF_DOSFLAG ; Get DX from AX=3306h INT 21h call
	 mov	 DOS_FLAG,ax	; Save it for FIND_WINA20

	 mov	 eax,[edx].REF_DOS_DEV_HDR ; Start of DOS device header chain
	 mov	 DEV_HDR_PTR,eax ; V86 mode linear address

; OVRMAC = 0FFFFh if there is no high DOS memory for whatever reason

	 mov	 ax,[edx].REF_P1MAC ; V86 segment of start of DOS arena
	 mov	 ARENA_ANCHOR,ax ; Save for later use

	 movzx	 eax,[edx].REF_OVRMAC ; V86 segment of 1st UMB MAC
	 mov	 OVRMAC,ax	; Save segment for later use
	 shr	 eax,(12-4)	; Convert from segments to 4KB pages
	 mov	 OVRMAC_PAGE,eax ; Save it for later use

	 mov	 ax,[edx].REF_LOADSEG ; V86 segment of 1st LSEG entry
	 mov	 LOADSEG,ax	; Save for later use

; We setup the V86 and PM API using the brute-force method because the
; VxD declaration is one of the three LoadHi .OBJ files from Microsoft
; Ralph Lipe blessed this approach.

	 mov	 eax,OFFSET32 V86_API ; Pointer to V86 API service routine
	 mov	 LoadHi_DDB.DDB_V86_API_Proc,eax ; Force in for AX=1684 INT 2F

	 mov	 eax,OFFSET32 PM_API ; Pointer to PM API service routine
	 mov	 LoadHi_DDB.DDB_PM_API_Proc,eax ; Force in for AX=1684 INT 2F

; Get the Device_V86_Pages_Array

	 mov	 eax,OFFSET32 PMI_PAGE_MAP ; Get pointer to bit map buffer

	 VMMcall _Get_Device_V86_Pages_Array <0, eax, 0> ; Global

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em GetDeviceV86PagesArray failed and crash

	 mov	 esi,OFFSET32 MSG_GDPA_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; If available, assign the 4K monochrome video memory for debugging use
; This is only needed if the SWAT VxD isn't available and we have a monochrome
; debugging screen.  This is of no use for Tech Support calls.

	 test	 DBG_FLAG,@DBG_DUAL ; Are we using the monochrome debug display?
	 jz	 short @F	; No, skip this stuff

	 bt	 PMI_PAGE_MAP[(0B0h / 32) * 4],(0B0h mod 32) ; Check bit
	 jc	 short @F	; Jump if this one is taken

	 VMMcall _Assign_Device_V86_Pages <0B0h, 1, 0, 0>	; Globally

; Set bit so we'll later remember that we've assigned the page

	 mov	 edx,0B0h-0A0h	; Bit # in EDX
	 bts	 ASSIGN_BMP,edx ; Set bit for the monochrome display page
@@:

	 call	 SETUP_QMAX	; Get GDT selectors for 386MAX.SYS, etc.
	 jc	 VDI_XIT	; Return w/ carry if it failed

	 mov	 edx,REF_LIN	; Get linear address of reference data str

; Get Windows linear address of type 1 UMB instance items

	 push	 [edx].REF_UMB_INST ; UMB instance item ptr from callback
	 push	 4096		; Maximum length of list we can handle
	 call	 PHYS2LIN	; Get linear address of type 1 items into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em MapPhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_MPTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 PTR_T1_LIN,eax ; Linear address of type 1 UMB instance items

	 call	 HOOK_SYSINI	; Deal with various SYSTEM.INI switches
				; VCPIWarning, etc.

	 call	 FIND_WINA20	; Determine if WINA20 is need, and look for it

; This VGA BIOS scanning MUST be performed before any FLEXROM adjustments

	 call	 CHK_VIDEO_ROMS ; Examine VGA BIOS for signatures, setting flags
	 jc	 VSCI_XIT	; Return with carry set if error
				; LoadHi, seeing carry will terminate

ifdef @VGASWAP
; Special handling of FLEXed ROMs

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_VGASWAP ; Is FLEXROM in effect?
	 jz	 short SCI_XFLEX ; Nope, so skip all of this

; Get a linear address to the FLEXROM info

	 push	 [edx].REF_FLEXROM_PTR ; Get physical address of FLEXROM info
	 push	 (100h-0A0h)*(2+2) ; Maximum length we're interested in
				; # of pages in adapater space * 2 WORDs
	 call	 PHYS2LIN	; Convert to linear address in EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; This error can not be handled
; Tell 'em FLEXROM_PTR PhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_FLX_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 FLEXROM_LIN,eax ; Save for use later

	 mov	 ax,[edx].REF_FLEXROM_LEN ; Count of entries in FLEXROM info
	 mov	 FLEXROM_CNT,ax ; Save count for VDD code

	 call	 SETUP_FLEXCONS ; Adjust CON_Cx000 variables for FLEXROM

	 call	 SETUP_FLEXROM	; Handle relocated ROMS
	 jnc	 short @F	; Skip error code if it worked

; Tell 'em SETUP_FLEXROM failed and crash

	 mov	 esi,OFFSET32 MSG_VS_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

SCI_XFLEX:
endif				; IFDEF @VGASWAP

	 call	 ROM_SCAN	; Scan PTEs to find, assign, and attach ROMs
	 jnc	 short @F	; Skip error code if it worked

; Tell 'em ROM_SCAN failed and crash

	 mov	 esi,OFFSET32 MSG_ROMSCAN_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 call	 RAM_SCAN	; Scan PTEs to find, assign, and attach RAM= buffers

	 call	 SETUP_OPTIONS	; Set flags for options VxD features
	 call	 SETUP_HIGHDOS_MAPS ; Setup bitmaps for high DOS memory

	 call	 EXCLUDE_MONO	; Keep VDD away from page B0 thru B7 on Win 3.1

	 call	 EXCLUDE_PVGA	; Keep WIN386 away from pages C6 and C7
				; on certain machines using Paradise Super VGA
				; chipset w/ own ROM

	 call	 PATCH_XGA	; Find and patch IBM XGA VDD

	 call	 FIX_DRDOS	; Hook GetSet_HMA_Info for DR-DOS

ifdef @VGASWAP
	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_VGASWAP ; Is FLEXROM in effect?
	 jz	 short @F	; Nope

	 call	 HOOK_VDD_SYSCRITINIT ; Hook into things to support FLEXROM
@@:
endif				; IFDEF @VGASWAP

ifdef @HARPO
	 call	 INIT_HARPO		; Setup for HARPO
	 jc	 short VSCI_XIT 	; Pass CY along to WIN386
endif					; IFDEF @HARPO

ifdef @DOSMAX
	 cmp	 WIN3_VERSION,030Ah	; Izit Windows 3.10?
	 jb	 short @F		; No DOSMAXs if not 3.10 or better

	 mov	 edx,REF_LIN		; Linear address of REF_DATA_STR
	 test	 [edx].REF_UPDFLAG,@UPD_UPDATE ; Are we updating an old 386MAX?
	 jnz	 short SCI_XDOSMAX	; No DOSMAXs if so (note CY set)

	 test	 [edx].REF_R2PFLAG,@R2P_SHORT ; Disable DOSMAX?
	 jz	 short @F		; Skip if not

	 call	 DOSMAX_SHORT		; Tell DOSMAX low DOS is too short
@@:
	 call	 DOSMAX_SYSCRITINIT	; Setup for DOSMAX
	 jc	 short VSCI_XIT 	; Pass CY along to WIN386
SCI_XDOSMAX:
endif					; IFDEF @DOSMAX

ifdef @ZMAX
	 call	 ATTACH_ZMAX		; Add secondary VxD to the Device_List
endif					; IFDEF @ZMAX

; Allocate the per VM control block space

	 mov	 ecx,DEV_CB_LEN 	; Size of per VM data
	 jecxz	 short VMAX_SCI_NOPERVM ; Skip if none

	 VMMcall _Allocate_Device_CB_Area, <ecx, 0>
	 or	 eax,eax		; Did we get the space?
	 jnz	 short @F		; Skip error code

	 BREAK				; Call the debugger FIXME
@@:
	 mov	 DEV_CB_OFFSET,eax	; Remember our offset into the CB
VMAX_SCI_NOPERVM:

; Now that high DOS memory is hooked up, we can change the PnP struc in BIOS

	call	PATCH_PnP		; Patch PnP struc if present

	 clc				; Clear error return indicator
VSCI_XIT:
	 ret				; Return to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SYS_CRITICAL_INIT		; End SYS_CRITICAL_INIT procedure

BeginProc PATCH_PnP
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Patch PnP struc in BIOS

|

	REGSAVE <eax,ebx,edx,edi>	; Save registers

	mov	edx,REF_LIN		; EDX ==> reference data structure

	cmp	[edx].REF_STRUC_VER,800h ; Izit PnP, or newer?
	jb	near ptr PATCH_PnP_EXIT ; Jump if not

	movzx	edi,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shl	edi,4-0 		; Convert from paras to bytes
	jz	near ptr PATCH_PnP_EXIT ; Jump if not present

	mov	eax,LCL_PnP_PMCS	; Get saved value
	mov	ebx,OffPnP_PMCS 	; Get offset to PnP_PMCS
	xchg	[edi+ebx],eax		; Save in PnP struc in BIOS
	mov	OLD_PnP_PMCS,eax	; Save to restore later

	cmp	[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F		; Jump if not (no PMDS in old struc)

	mov	eax,LCL_PnP_PMDS	; Get saved value
	xchg	[edi].PnP_PMDS,eax	; Save in PnP struc in BIOS
	mov	OLD_PnP_PMDS,eax	; Save to restore later
@@:

; Re-calculate the PnP checksum

	call	CALC_PnPSUM		; Re-calculate it

; In the above code, we've written to the BIOS pages (which are
; already mapped to RW memory), but which are also marked RO.
; This means that a RO page has the Dirty bit set, which can confuse
; Win95.  The following code clears that bit, as well as the Accessed
; bit to make it look just like the other adjacent PTEs.

	mov	eax,cr3 		; Get current PBDR
	and	eax,@PTE_FRM		; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	cmp	eax,-1			; Did it fail?
	je	short PATCH_PnP1	; Jump if so (just ignore the error)

	mov	edx,REF_LIN		; EDX ==> reference data structure
	movzx	ebx,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shl	ebx,4-0 		; Convert from paras to bytes

	push	ebx			; Save for a moment

	and	ebx,mask $LA_DIR	; Isolate the Page Directory index
	shr	ebx,$LA_DIR		; Shift to low-order
	mov	eax,[eax+ebx*4] 	; Get the physical address of the PDE
	and	eax,@PTE_FRM		; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	pop	ebx			; Restore

	cmp	eax,-1			; Did it fail?
	je	short PATCH_PnP1	; Jump if so (just ignore the error)

	and	ebx,mask $LA_PAGE	; Isolate the PTE index
	shr	ebx,$LA_PAGE		; Shift to low-order
	and	[eax+ebx*4].EDD,not ((mask $PTE_D) or (mask $PTE_A)) ; Clear A & D bits
PATCH_PnP1:

; Thanks to some VxD in Win95, the PhysToLin copy of the BIOS is
; checked to get the PnP parameters, but then the code to be executed
; is from F000:0.  Although we have carefully matched the PnP struc
; parameters to the mode (in this case Windows), we need another kludge.
; This time, I'm changing the PhysToLin PTE for the PnP struc to that
; of the BIOS copy.

	mov	eax,cr3 		; Get current PBDR
	and	eax,@PTE_FRM		; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	cmp	eax,-1			; Did it fail?
	je	near ptr PATCH_PnP_EXIT    ; Jump if so (just ignore the error)

	mov	edx,REF_LIN		; EDX ==> reference data structure
	movzx	ebx,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shl	ebx,4-0 		; Convert from paras to bytes
	sub	ebx,@PnP_BIOS_BEG	; Less starting BIOS address
	add	ebx,LaPnPBIOS		; Add to get linear address of PnP struc
					; This is the same address other
					; PhysToLin callers get

	REGSAVE <ebx,edx>		; Keep W's grubby hands away from these

	and	ebx,mask $LA_DIR	; Isolate the Page Directory index
	shr	ebx,$LA_DIR		; Shift to low-order
	mov	eax,[eax+ebx*4] 	; Get the physical address of the PDE
	and	eax,@PTE_FRM		; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	REGREST <edx,ebx>		; Restore

	cmp	eax,-1			; Did it fail?
	je	short PATCH_PnP_EXIT	; Jump if so (just ignore the error)

	and	ebx,mask $LA_PAGE	; Isolate the PTE index
	shr	ebx,$LA_PAGE		; Shift to low-order
	lea	ebx,[eax+ebx*4] 	; Calculate the address

; Now find the patched PTE in 386MAX's PTEs

	movzx	edi,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shr	edi,12-4		; Convert from paras to 4KB
	mov	eax,PDIR_LIN		; Get linear address of 386MAX's PTEs
	mov	eax,[eax+edi*4] 	; Get the matching PTE
	and	eax,@PTE_FRM		; Isolate the frame
	mov	edi,[ebx]		; Get the outgoing PTE
	and	edi,not (@PTE_FRM or (mask $PTE_A) or (mask $PTE_D)) ; Isolate
					; the flags except Accessed and Dirty
	or	eax,edi 		; Merge
	mov	[ebx],eax		; Save in Window's P2L map
PATCH_PnP_EXIT:
	REGREST <edi,edx,ebx,eax>	; Restore

	ret				; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc PATCH_PnP			; End SETUP_PnP procedure

BeginProc HOOKPROC			; Local hook procedure
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Temporary replacement for VMM service procedures

|

	 int	 3			; Call the debugger

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  HOOKPROC			; End HOOKPROC procedure
	 page
BeginProc SET_DBG_FLAG		; Set DBG_FLAG based upon SYSTEM.INI switches
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Use the GetProfileString VMMcall to read our SYSTEM.INI cookies.
	Set debugging flags based on what we find.

|

	 REGSAVE <edx,edi>	; Save caller's registers

; 386MAXDualDisplay - Display debugging information on monochrome screen

	 mov	 edi,OFFSET32 SYSINI_DUALDISPLAY ; Pointer to option
	 mov	 dx,@DBG_DUAL	; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXSysCriticalInit - Break in SysCriticalInit

	 mov	 edi,OFFSET32 SYSINI_SYSCRITINIT ; Pointer to option
	 mov	 dx,@DBG_CRITINIT ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXDeviceInit - Break in DeviceInit

	 mov	 edi,OFFSET32 SYSINI_DEVICEINIT ; Pointer to option
	 mov	 dx,@DBG_DEVINIT	; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXInitComplete - Break in InitComplete

	 mov	 edi,OFFSET32 SYSINI_INITCOMPLETE ; Pointer to option
	 mov	 dx,@DBG_INITCOMP ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXSysVMInit - Break in SysVMInit

	 mov	 edi,OFFSET32 SYSINI_SYSVMINIT ; Pointer to option
	 mov	 dx,@DBG_SYSVMINIT	; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXCreateVM - Break in CreateVM

	 mov	 edi,OFFSET32 SYSINI_CREATEVM ; Pointer to option
	 mov	 dx,@DBG_CREATEVM ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXSystemExit - Break in SystemExit

	 mov	 edi,OFFSET32 SYSINI_SYSEXIT ; Pointer to option
	 mov	 dx,@DBG_SYSEXIT ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXSysCriticalExit - Break in SysCriticalExit

	 mov	 edi,OFFSET32 SYSINI_SYSCRITEXIT ; Pointer to option
	 mov	 dx,@DBG_SYSCRITEXIT ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXAPI1684 - Break in API 1684 service procedure

	 mov	 edi,OFFSET32 SYSINI_API1684 ; Pointer to option
	 mov	 dx,@DBG_API1684	; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXAutoInstance - Break in the automatic instancing code

	 mov	 edi,OFFSET32 SYSINI_AUTOINST ; Pointer to option
	 mov	 dx,@DBG_AUTOINST ; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

; 386MAXInt0E - Break in page faults in our cached ROMs

	 mov	 edi,OFFSET32 SYSINI_INT0E ; Pointer to option
	 mov	 dx,@DBG_INT0E	; Flag bit for option
	 call	 GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	 or	 DBG_FLAG,dx	; Set flag bit if SYSTEM.INI option is TRUE

	 REGREST <edi,edx>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SET_DBG_FLAG		; End SET_DBG_FLAG procedure

	 page
BeginProc HOOK_SYSINI		; Fake out certain SYSTEM.INI switches
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Read SYSTEM.INI looking for and faking out certain switches.

	VCPIWarning=
	    If it's not specifically mentioned, hook into the
	    Get_Profile_Boolean VMM service and lie about it
	    when the V86MMGR and/or DOSMGR asks.

	XMSUMBINITCALLS=
	    Windows 3.10 allocates all the free UMB space in the V86MMGR
	    unless this switch is set to FALSE.  The XMS init calls are
	    required in 3.0 to get the state of the system.
	    Lie about the switch if this is Windows 3.10.

	V86Assign=
	    For RAM= regions, determine whether or not to assign V86
	    pages (and set the $PTE_CD bit) for RAM= regions.

	V86Display=
	    For RAM= regions, if an error occurs when assigning V86
	    pages, determine whether or not to display the warning.

|

	 REGSAVE <eax,esi,edi>	; Save caller's registers

; Check state of VCPIWarning switch in SYSTEM.INI

	 sub	 eax,eax	; Assume option not present or FALSE
	 sub	 esi,esi	; NULL indicates [386Enh] section
	 mov	 edi,OFFSET32 STR_VCPIWARN ; ==> key name string

	 VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid VCPIWarning cookie in SYSTEM.INI

	 jnc	 short @F	; Jump if string found

	 or	 PMI_FLAG,@PMI_VCPIWARN ; Indicate we need to lie
@@:
	 jnz	 short @F	; Jump if string is valid

	 or	 PMI_FLAG,@PMI_VCPIWARN ; Indicate we need to lie
@@:

; Check state of XMSUMBINITCALLS switch in SYSTEM.INI

	 cmp	 WIN3_VERSION,030Ah ; Izit Windows 3.10?
	 jb	 short HS_XUMBINITCALLS ; Skip if not 3.10 or better

	 sub	 eax,eax	; Assume option not present or FALSE
	 sub	 esi,esi	; NULL indicates [386Enh] section
	 mov	 edi,OFFSET32 STR_XMSUMBINITCALLS ; ==> key name string

	 VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid XMSUMBINITCALLS cookie in SYSTEM.INI

	 jnc	 short @F	; Jump if string found

	 or	 PMI_FLAG,@PMI_UMB ; Indicate we need to lie
@@:
	 jnz	 short @F	; Jump if string is valid

	 or	 PMI_FLAG,@PMI_UMB ; Indicate we need to lie
@@:
HS_XUMBINITCALLS:

; Check state of V86Assign switch in SYSTEM.INI
; If it's pre-Win 95, the default is FALSE -- otherwise the default is TRUE

	mov	eax,FALSE	; Assume option not present ==> FALSE

	cmp	WIN3_VERSION,0400h ; Izit Windows 4.00?
	jb	short @F	; Skip if not

	mov	eax,TRUE	; Assume option not present ==> TRUE
@@:
	mov	esi,OFFSET32 STR_QUALITAS ; [Qualitas] section
	mov	edi,OFFSET32 STR_V86ASSIGN ; ==> key name string

	VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid V86Assign cookie in SYSTEM.INI

	cmp	eax,FALSE	; Izit to be assigned?
	je	short @F	; Jump if not

	or	PMI_FLAG,@PMI_V86ASSIGN ; Indicate we need to assign
@@:

; Check state of V86Display switch in SYSTEM.INI

	mov	eax,TRUE	; If option not present ==> TRUE
	mov	esi,OFFSET32 STR_QUALITAS ; [Qualitas] section
	mov	edi,OFFSET32 STR_V86DISPLAY ; ==> key name string

	VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid V86Display cookie in SYSTEM.INI

	cmp	eax,FALSE	; Izit to be displayed?
	je	short @F	; Jump if not

	or	PMI_FLAG,@PMI_V86DISPLAY ; Indicate we need to display
@@:

; Hook into Get_Profile_Boolean if needed

	 test	 PMI_FLAG,@PMI_VCPIWARN+@PMI_UMB
				; Do we need to lie?
	 jz	 short HOOK_SYSINI_XPATCH ; Skip hook if not

	 mov	 eax,Get_Profile_Boolean ; ID for service to steal
	 mov	 esi,OFFSET32 LCL_GET_PROFILE_BOOLEAN ; Address of local handler
	 VMMcall Hook_Device_Service ; Hook in new handler, return old in ESI
	 jc	 short HOOK_SYSINI_XPATCH ; Return w/o patching anything

	 mov	 OLD_GET_PROFILE_BOOLEAN,esi ; Save address of old handler

	 or	 PMI_FLAG,@PMI_HOOKED_GPB ; Indicate we've hooked it
HOOK_SYSINI_XPATCH:

HOOK_SYSINI_XIT:
	 REGREST <edi,esi,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  HOOK_SYSINI		; End HOOK_SYSINI procedure

	 page
BeginProc LCL_GET_PROFILE_BOOLEAN ; Local Get_Profile_Boolean procedure
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Local replacement for the VMM Get_Profile_Boolean used to
	lie to VxDs about certain SYSTEM.INI switches.

	VCPIWarning for V86MMGR and DOSMGR

	XMSUMBINITCALLS for V86MMGR for 'Virtual High DOS' (LocalLoadHi)

|

; Test for VCPIWarning

	 test	 PMI_FLAG,@PMI_VCPIWARN ; Are we checking for VCPIWarning?
	 jz	 short LGPB_XVCPI ; Nope, check the next switch

	 push	 esi		; Save caller's register

	 mov	 esi,OFFSET32 STR_VCPIWARN ; ==> comparison string
	 call	 CMPSBI 	; Do case-insensitive REPE CMPSB
				; ZR indicates they matched

	 pop	 esi		; Restore caller's register

	 jz	 short LGPB_FALSE ; Tell 'em VCPIWarning=FALSE

LGPB_XVCPI:

; Test for XMSUMBINITCALLS

	 test	 PMI_FLAG,@PMI_UMB ; Checking for XMSUMBINITCALLS?
	 jz	 short LGPB_XUMBINITCALLS ; Nope, check the next switch

	 push	 esi		; Save caller's register

	 mov	 esi,OFFSET32 STR_XMSUMBINITCALLS ; ==> comparison string
	 call	 CMPSBI 	; Do case-insensitive REPE CMPSB
				; ZR indicates they matched

	 pop	 esi		; Restore caller's register

	 jz	 short LGPB_FALSE ; Tell 'em XMSUMBINITCALLS=FALSE

LGPB_XUMBINITCALLS:

; Nothing we care about matched the string.  Let the original handler at it

LGPB_CHAIN:
	 jmp	 OLD_GET_PROFILE_BOOLEAN ; Call the original

; We've got a match on switch.  Tell 'em it's TRUE
; We must return EAX = 1, Carry clear, and Zero clear

LGPB_TRUE:
	 sub	 eax,eax	; EAX = 0, ZF set, CF clear
	 inc	 eax		; EAX = 1, ZF clear, CF clear

	 ret			; Return to caller

; We've got a match on switch.  Tell 'em it's FALSE
; We must return EAX = 0, Carry clear, and Zero clear

LGPB_FALSE:
	 sub	 eax,eax	; ZF set, CF clear
	 inc	 eax		; ZF clear, CF clear
	 pushfd 		; Save those flags
	 sub	 eax,eax	; EAX = 0 indicates FALSE
	 popfd			; Restore flags, ZF clear, CF clear

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_GET_PROFILE_BOOLEAN ; End LCL_GET_PROFILE_BOOLEAN procedure
	 page
ifdef @VGASWAP
BeginProc SETUP_FLEXROM 	; Reattach swapped ROMs
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Under certain FLEXROM configurations, there may be memory-mapped
	I/O spaces.  These are no longer 1:1 if FLEXROM is in effect.
	There are page bitmaps in the FLEXROM structure to help us find
	these special pages, assign, and map them.

	Also, if we encounter C000-C7FF in the FLEXROM table, set a bit
	for use later in the ROMSCAN code.

ENTRY:
	EBX is VM handle

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

; The drill here is to loop through the FLEXROM table, looking for
; bits set in the FLEX_MAP entries.

	 mov	 esi,FLEXROM_LIN ; Pointer to FLEXROM table

	 movzx	 ecx,FLEXROM_CNT ; Number of entries in the FLEXROM table
	 jecxz	 short VS_XITCLC ; Exit if nothing is FLEXed

VS_NXTENT:
	 movzx	 edx,[esi].FLEX_DST ; FLEXed ROM destination segment
	 shr	 edx,(12-4)	; Convert from segment to page #

	 sub	 eax,eax	; Clear the page offset within the ROM

	 movzx	 edi,[esi].FLEX_LEN ; Get length (in bytes) of FLEXed ROM
	 shr	 edi,(12-0)	; Convert from bytes to pages

; Test for ROM VGASWAPed to C000-C7FF w/o memory-mapped I/O.
; Set a bit for later if found.

	 cmp	 edx,0C0h	; Is destination page C0h?
	 jne	 short @F	; Skip if not

	 cmp	 edi,8		; Izit an 8 page ROM?
	 jne	 short @F	; Skip if not

	 cmp	 [esi].FLEX_MAP,0 ; Izit devoid of memory-mapped I/O pages?
	 jnz	 short @F	; Skip if there are some memory-mapped I/O pages

	 push	 edx		; Save page #

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 or	 [edx].REF_VIDFLAG,@VID_C000NOIO ; Remember we found it

	 pop	 edx		; Restore page #
@@:

VS_NXTPAGEINROM:
	 bt	 [esi].FLEX_MAP,ax ; Is this page one of the special ones?
	 jnc	 short VS_XPAGEINROM ; Jump if not

; We've got a memory-mapped I/O space due to a FLEXROMed ROM

	 call	 FLEXSUB	; Assign and map the pages
	 jc	 short VS_XIT	; Exit with carry set if error

; Loop back for the next page in the ROM

VS_XPAGEINROM:
	 inc	 eax		; Bump to next page in ROM

	 cmp	 eax,edi	; Any more pages in this ROM?
	 jb	 short VS_NXTPAGEINROM ; Jump if so

; We've examined all the pages in this ROM
; Try all the FLEXed ROMS

	 add	 esi,size FLEXROM_STR ; Advance to next entry in FLEXROM table

	 loop	 VS_NXTENT	; Look in all the entries

VS_XITCLC:
	 clc			; Normal return indicator
VS_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SETUP_FLEXROM		; End SETUP_FLEXROM procedure

BeginProc FLEXSUB		; Subroutine for SETUP_FLEXROM
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Assign and map the FLEXed memory-mapped I/O page described by the
FLEXROM table entry to which ESI points.

Entry:
	ESI ==> FLEXROM table entry
	EAX = bit # for the page within the ROM

|

	 REGSAVE <eax,ecx,edx>	; Save registers

	 shl	 eax,(12-0)	; Convert from page # to bytes

	 movzx	 edx,[esi].FLEX_DST ; FLEXed ROM destination segment
	 shl	 edx,4		; Convert from paras to bytes
	 add	 edx,eax	; EDX = linear address

	 movzx	 ecx,[esi].FLEX_SRC ; FLEXed ROM source segment
	 shl	 ecx,4		; Convert from paras to bytes
	 add	 eax,ecx	; EAX = physical address

; EAX = physical address
; EDX = linear V86 address

	 push	 eax		; Save physical address
	 push	 edx		; Save linear V86 address

	 shr	 edx,12 	; Convert from bytes to pages
	 sub	 ecx,ecx	; A handy zero

	 push	 edx		; Save V86 page #

;					   V86 page #
;					   |	Count (rounded up)
;					   |	|    Global assignment
;					   |	|    |	  Flags
;					   |	|    |	  |
	 VMMcall _Assign_Device_V86_Pages <edx, 1, ecx, ecx>
	 pop	 edx		; Restore V86 page #

; Set bit so we'll later remember we've assigned the page

	 sub	 edx,0A0h	; Bitmap starts at page A0h
	 bts	 ASSIGN_BMP,edx ; Set bit for this page

	 or	 eax,eax	; Test return code

	 pop	 edx		; Restore linear V86 address
	 pop	 eax		; Restore physical address

	 jnz	 short @F	; Jump around error code if OK

; Tell 'em the AssignDeviceV86Pages failed and crash

	 mov	 esi,OFFSET32 MSG_ADP2_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 shr	 eax,12 	; Convert physical from bytes to pages

	 push	 edx		; Save linear V86 address
	 shr	 edx,12 	; Convert linear from bytes to pages

;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Flags
;				|    |	  |    |  |
	 VMMcall _PhysIntoV86  <eax, ebx, edx, 1, 0>

	 or	 eax,eax	; Test return code

	 pop	 edx		; Restore linear V86 address

	 jnz	 short @F	; Jump around error code if OK

; Tell 'em the PhysIntoV86 failed and crash

	 mov	 esi,OFFSET32 MSG_PIV2_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 clc			; Normal return indicator
VSS_XIT:
	 REGREST <edx,ecx,eax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FLEXSUB		; End FLEXSUB procedure

	 page
BeginProc SETUP_FLEXCONS	; Adjust CON_Cx0000 variables
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Based on the entries in the FLEXROM table, adjust the CON_Cx0000
	variables.  These are used for snooping around in the VGA ROMs
	to prevent Video Device Conflict errors.

	Note that this code doesn't work for machines with the VGA ROM
	at E000, but neither does the VDD, which we are trying to fool.

	For example, CON_C0000 might become 0B0000h.
|

	 REGSAVE <eax,ecx>	; Save caller's registers

	 cld			; String ops forwardly

; Look through the FLEXROM table for C000

	 mov	 esi,FLEXROM_LIN ; Pointer to FLEXROM table
	 movzx	 ecx,FLEXROM_CNT ; Number of entries in the FLEXROM table
@@:
	 mov	 ax,[esi].FLEX_SRC ; FLEXed ROM source segment
	 cmp	 ax,0C000h	; Izit a video ROM?
	 je	 short @F	; Yup, so we found our boy

	 add	 esi,size FLEXROM_STR ; Advance to next entry in FLEXROM table

	 loop	 @B		; Look in all the entries

; We've exhaust the table without finding C000.  Don't adjust anything.

	 jmp	 short SFC_XIT	; Rejoin common exit code

; We've hit and entry in the FLEXROM table for C000.
; Figure out the adjustment value.

@@:
	 movzx	 edx,[esi].FLEX_DST ; FLEXed ROM's new home segment
	 shl	 edx,4		; Convert from segment to linear address
	 sub	 edx,0C0000h	; Less C0000h is the offset

	 mov	 ecx,@CON_CNT ; Number of such constants to be adjusted
	 mov	 esi,OFFSET32 CON_C0000 ; Pointer to first constant
@@:
	 lodsd			; Pick up next constant to be adjusted
	 add	 eax,edx	; Adjust it for the new ROM location
	 mov	 [esi-4],eax	; Store it back

	 loop	 @B		; Adjust 'em all

SFC_XIT:
	 REGREST <ecx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SETUP_FLEXCONS 	; End SETUP_FLEXCONS procedure
endif				; IFDEF @VGASWAP

	 page
BeginProc ROM_SCAN		; Scan PTEs to find, assign, and attach ROMs
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Examine 386MAX's page table to find cached ROMs.
	Assign the V86 pages involved and map in the proper physical memory

	Handle the video BIOS ROM specially to avoid 'Video Device Conflict'.
	Use ROM_AMM as a subroutine to handle a lot of the interface with
	the VMM.

On entry:

EBX	=	VM handle

On exit:

CF	=	0 if no errors
	=	1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save caller's registers

; Scan thru PTEs from page A0h thru FFh looking for cached ROMs

	 mov	 esi,PDIR_LIN	; Linear address of 386MAX's PTEs
	 add	 esi,0A0h*4	; Advance to A0h page in PTEs
	 mov	 edx,0A0000h	; V86 address
ROM_SCAN_NXT:
	 mov	 eax,[esi]	; Pick up next PTE

	 test	 eax,mask $PTE_AV0 ; Is it an EMS mappable page?
	 jnz	 ROM_SCAN_SKP	; Yes, so it's not a ROM

	 test	 eax,mask $PTE_RW ; Is it a ROM?
	 jnz	 ROM_SCAN_SKP	; No, so don't add it to table

	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field

	 mov	 RS_V86_ADDR,edx ; Save the V86 address

; Pick up the length from the 1st page of the ROM and check that many pages

	 mov	 ecx,1		; Assume only 1 page (rounded up)
	 mov	 COUNT_DOWN,ecx ; ...		     (rounded down)

	 cmp	 edx,0E0000h	; Is it a BIOS rom?
	 jae	 RS_ASSUME	; Yes, then go with the assumption

; Due to the FLEXROM feature, we need to inspect the swapped version of the
; ROM rather than the actual V86 address

	 push	 eax		; Physical addr of ROM (potentially FLEXROMed)
	 push	 4096		; Length to map
	 call	 PHYS2LIN	; Get Windows linear address of ROM

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Skip error if it worked

; Tell 'em MapPhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_MPTL4_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 cmp	 [eax].ROMSIGN,@ROMSIGN ; Check for valid ROM signature
	 je	 short @F	; It's valid, so check the length

	 cmp	 [eax].ROMSIGN,@ROMNINIT ; Check for valid non-initializing ROM
	 jne	 short RS_ASSUME ; Not valid, so don't check the length
@@:
	 movzx	 ecx,[eax].ROMLEN ; Pick up # of 512-byte pieces
	 mov	 eax,ecx	; Copy for rounding down
	 shr	 eax,3		; Convert to 4KB pages (rounding down)
	 add	 ecx,(4096/512)-1 ; Round up to 4KB page
	 shr	 ecx,3		; Convert to 4KB pages (rounding up)
	 mov	 COUNT_DOWN,eax ; Save count rounded down
RS_ASSUME:

; EAX is page count rounded down to nearest 4 KB boundary for caching
; ECX is page count rounded up to nearest 4 KB boudary for bitmap assigning

	 mov	 COUNT_SKIP,ecx ; # of PTEs to skip after this loop
	 push	 ecx		; Save page count (rounded up)
RS_NXT:
	 call	 TEST_PAGEMAP	; Test PMI_PAGE_MAP - EDX is V86 linear address
	 jc	 short @F	; Jump if it's not available

	 add	 edx,4096	; Bump V86 address to next page
	 loop	 short RS_NXT	; Check the entire ROM
@@:
	 pop	 ecx		; Restore page count (rounded up)

; Carry is clear if the entire range is available

	 jnc	 short @F	; Skip error code if all pages available

ifdef @DEBUG
	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 eax,edx	; Get V86 linear address
	 shr	 eax,12 	; Convert from linear address to page #

	 lea	 edi,MSG_ROMPAM_UGH0 ; Place to stick ASCII HEX digits
	 mov	 ecx,2		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 esi,OFFSET32 MSG_ROMPAM_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 REGREST <edi,esi,ecx,eax> ; Restore registers
endif				; IFDEF @DEBUG

	 stc			; Error indicator
	 jmp	 RS_XIT 	; Return with error
@@:

; Check for the odd Compaq VGA ROM.  If found, don't cache it

@COMPAQ_NAME	 equ	0C5FEAh ; Address of 'COMPAQ' string
@COMPAQ_DATE	 equ	0C5FF5h ; Address of 'xx/xx/xx'
@COMPAQ_VER	 equ	0C5FE4h ; Address of V5C version string

	 mov	 edx,CON_C0000	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Is it looking like a VGA ROM?
	 jne	 short RS_NOTCOMPAQ ; No, so it's not our boy

	 cmp	 ecx,6		; Is it a 6 page ROM?
	 jne	 short RS_NOTCOMPAQ ; No, so it's not our boy

	 mov	 edx,@COMPAQ_NAME ; Address of 'COMPAQ'
	 cmp	 [edx].EDD,'PMOC' ; Check for 'COMP' ...
	 jne	 short RS_NOTCOMPAQ ; No, so it's not our boy

	 cmp	 [edx+4].ELO,'QA' ; Check for ... 'AQ'
	 jne	 short RS_NOTCOMPAQ ; No, so it's not our boy

	 mov	 edx,@COMPAQ_VER ; Address of 'V5C'
	 cmp	 [edx].EDD,' C5V' ; Check for ROM version C.5
	 jne	 short RS_NOTCOMPAQ ; No, so it's not our boy

; We've identified the Compaq VGA ROM in question

	 jmp	 RS_SKP_AMM	; Skip the assignments for this ROM

RS_NOTCOMPAQ:

; Do we have the Tseng Labs/Trident or Video 7 VGA chipset?

	 mov	 edx,0C8000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Izit too high?
	 jae	 short RS_NOTTSENG ; Yup

	 mov	 edx,0C0000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Izit too low?
	 jb	 short RS_NOTTSENG ; No, so it's not our boy

; We've got a ROM at C000 or above, but below C800

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_TLVGA+@VID_V7VGA ; Check for pesky VGA
	 jz	 short RS_NOTTSENG ; No

; Don't cache anything between C600-C800 on a Tseng Labs or Video 7
; Some Trident boards seem to fit this catagory also

; On the Orchid ProDesigner the ROM will come in via a 16K piece at C0-C4
; and 4K pieces from C4 thru C8.

	 mov	 edx,0C6000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Is it looking like the funky piece?
	 je	 RS_SKP_AMM	; Yup, so don't cache it

	 mov	 edx,0C7000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Is it looking like the funky piece?
	 je	 RS_SKP_AMM	; Yup, so don't cache it

	 cmp	 ecx,6		; Check for assignment above C600
	 jb	 short RS_NOTTSENG ; No, so it's OK

	 mov	 eax,6		; Limit to C000-C600
	 mov	 COUNT_DOWN,eax ; Limit the ROM caching to C000-C600
	 mov	 ecx,eax	; Limit the assignment to C000-C600
RS_NOTTSENG:

; Some Paradise VGA ROM signatures claim they are 32K, but are actually 24K.
; The VDD will complain about Video Device Conflict if we cache all 32K.

	 cmp	 RS_V86_ADDR,0C0000h ; Izit a possible Paradise ROM
	 jne	 short RS_NOTPVGA ; No, so it's not our boy

	 cmp	 ecx,8		; Is it an 8 page ROM?
	 jne	 short RS_NOTPVGA ; No, so it's not our boy

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_PVGAROM ; Check for Paradise ROM
	 jz	 short RS_NOTPVGA ; No

	 test	 [edx].REF_VIDFLAG,@VID_C000NOIO ; Izit VGASWAPed w/o I/O?
	 jnz	 short RS_NOTPVGA ; Yes, so use all 8 pages

	 mov	 eax,6		; Limit to C000-C600
	 mov	 COUNT_DOWN,eax ; Limit the ROM caching to C000-C600
	 mov	 ecx,eax	; Limit the assignment to C000-C600
RS_NOTPVGA:

; On C&T chipset systems, we will cache the Paradise ROM for 24K but mark
; the entire 32K region as R/O.  When somebody writes into the special
; C6 or C7 pages, we page fault and swap the original PTEs back in and
; retry the instruction.  The VXD sees the R/O flags in the PTEs for C6 and
; C7 and caches the area.  The code used in 5.12 got confused by this.
; The following new code for 5.13 detects this case and avoids the Video
; Device Conflict error.

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_PVGAROM ; Check for Paradise ROM
	 jz	 short RS_NOTPVGA2 ; No

	 cmp	 ecx,1		; Izit a 1 page ROM?
	 jne	 short RS_NOTPVGA2 ; No, so it's not our boy

	 mov	 edx,0C6000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Izit the funky RAM area?
	 je	 short @F	; No, so it's not our boy

	 mov	 edx,0C7000h	; Constant for VGA BIOS ROM address
	 cmp	 RS_V86_ADDR,edx ; Izit the funky RAM area?
	 jne	 short RS_NOTPVGA2 ; No, so it's not our boy

; We've hit the funcky case (first seen on Nick's infamous Dell)
; Avoid doing anything with these pages

@@:
	 jmp	 short RS_SKP_AMM ; Skip the assignments for this ROM

RS_NOTPVGA2:
	 push	 edx		; Save

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_PVGA ; Check for Paradise chipset
	 jz	 short @F	; Skip if not

	 test	 [edx].REF_VIDFLAG,@VID_PVGAROM ; Check for Paradise ROM
	 jnz	 short @F	; Skip if so

	 cmp	 RS_V86_ADDR,0C0000h ; Izit a VGA ROM?
	 jne	 short @F	; Skip if not

	 cmp	 ecx,6		; Izit a 6 page assignment?
	 jne	 short @F	; Skip if not

	 cmp	 COUNT_DOWN,6	; Izit a 6 page cache job?
	 jne	 short @F	; Skip if not

; We've got the case on an AST machine with the Paradise chipset on-board.
; Remember this case for later to assign C6 and C7.

	 or	 [edx].REF_VIDFLAG,@VID_CACHEDPVGA ; Indicate we cached ROMs
				; on a Paradise chipset
@@:
	 pop	 edx		; Restore

; Check for funky case on Tandon laptop FIXME

; Assign the V86 pages for this ROM

	 push	 RS_V86_ADDR	; V86 address of start of ROM
	 push	 esi		; --> PTE for V86 page
	 push	 COUNT_DOWN	; Page count rounded down (for caching)
	 push	 ecx		; Page count rounded up (for assignment)
	 call	 ROM_AMM	; ROM assign, map and modify
	 jc	 short RS_XIT	; Bug out if error.  Note CY set

; Advance to the next page

RS_SKP_AMM:
	 mov	 eax,COUNT_SKIP ; Get original count to skip
	 shl	 eax,(2-0)	; Count rounded down * 4
	 add	 esi,eax	; Skip past these PTEs

	 shl	 eax,(12-2-0)	; Count rounded down * 4096
	 add	 RS_V86_ADDR,eax ; Bump past this ROM
	 mov	 edx,RS_V86_ADDR ; V86 address of next ROM page

	 jmp	 short ROM_SCAN_SKP2 ; On to the next one
ROM_SCAN_SKP:
	 add	 esi,4		; Account for last PTE
	 add	 edx,4096	; Bump to next page
ROM_SCAN_SKP2:
	 cmp	 edx,100000h	; Have we exhausted the 1st megabyte?
	 jae	 short @F	; Exit loop if so

	 jmp	 ROM_SCAN_NXT	; Loop on to next PTE
@@:
	 clc			; Normal return indicator
RS_XIT:
	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ROM_SCAN		; End ROM_SCAN procedure

	 page
BeginProc RAM_SCAN		; Scan PTEs to find, assign, and attach RAMs
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Examine 386MAX's page table to find one-to-one RAM buffers.
	This is needed specifically for Win95 because it appears to be
	  more agressive in assigning high DOS address space to itself.
	Assign the V86 pages involved and map in the proper physical memory

	Use RAM_AMM as a subroutine to handle a lot of the interface with
	the VMM.

On entry:

EBX	=	VM handle

On exit:

CF	=	0 if no errors
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save caller's registers

	test	PMI_FLAG,@PMI_V86ASSIGN ; Should we assign the pages?
	jz	short RAM_SCAN_XIT ; Jump if not (note CF=0)

; Scan thru PTEs from page C0h thru FFh looking for RAM= regions

	mov	esi,PDIR_LIN	; Linear address of 386MAX's PTEs
	add	esi,(@RAMSTART shr 12)*4 ; Advance to C0h page in PTEs
	mov	edx,@RAMSTART	; V86 address
RAM_SCAN_NXT:
	test	[esi].EDD,mask $PTE_CD ; Is it in a RAM= statement?
	jz	short RAM_SCAN_SKP ; No, so don't add it to table

; If the address is inside a ROM, it might have been a left over
; block from an odd-sized ROM.	if so, don't attempt to assign the
; page as Windows might already have assigned it.

	call	IZIT_INROM	; Is address EDX inside a ROM?
	jc	short RAM_SCAN_SKP ; Jump if so

	call	TEST_PAGEMAP	; Test PMI_PAGE_MAP - EDX is V86 linear address
	jc	short RAM_SCAN_SKP ; Jump if it's not available (note:  no error)

; Assign the V86 pages for this RAM=

	push	edx		; Physical address of RAM=
	call	RAM_AMM 	; RAM assign, map and modify
	jnc	short RAM_SCAN_SKP ; Jump if successful
RAM_SCAN_ERR:
	mov	eax,edx 	; Copy physical address (/4KB)
	sub	eax,@RAMSTART	; Less starting address
	shr	eax,12-0	; Convert from bytes to 4KB
	bts	RAM_ERRMAP,eax	; Mark as in error

; Advance to the next page

RAM_SCAN_SKP:
	add	esi,4		; Account for last PTE
	add	edx,4096	; Bump to next page

	cmp	edx,@RAMSTOP	; Have we exhausted the 1st megabyte?
	jb	RAM_SCAN_NXT	; Loop on to next PTE
RAM_SCAN_XIT:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	ret			; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc RAM_SCAN		; End RAM_SCAN procedure
	page
BeginProc IZIT_INROM		; Is A Given Address Inside A ROM
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Is a linear address inside a ROM?

On entry:

EDX	=	linear address to check (of length 4KB and /4KB)

On exit:

CF	=	0 if not
	=	1 if so

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	lea	ebx,[edx+4*1024] ; EBX ==> ending address for 4KB at EDX

	mov	eax,@ROMSTART	; Get starting address to search
IZIT_INROM_NEXT:
	lea	ecx,[eax+512]	; Get ending address of single ROM block

	cmp	[eax].ELO,@ROMSIGN ; Izit a ROM?
	jne	short IZIT_INROM_LOOP ; Jump if not

	movzx	ecx,[eax].ROMLEN ; Pick up # of 512-byte pieces
	shl	ecx,9-0 	; Convert from 512 bytes to bytes
	add	ecx,eax 	; Add to get ending address

COMMENT!

Register usage:

EDX	=	start of address to check
EBX	=	end ...
EAX	=	start of current ROM
ECX	=	end ...

The two regions overlap if

((EDX < EAX) && (EAX < EBX)) || ((EAX <= EDX) && (EDX < ECX))

That is,

1.  Is EAX inside [EDX,EBX)?
2.  Is EDX inside [EAX,ECX)?

!

	cmp	edx,eax 	; Izit case 1?
	jb	short @F	; Jump if so

; Test for case 2

	cmp	edx,ecx 	; Is EDX inside [EAX,ECX)?
	jb	short IZIT_INROM_EXIT ; Jump if so (note CF=1)

	jmp	short IZIT_INROM_LOOP ; Join common loop code

@@:

; Test for case 1

	cmp	eax,ebx 	; Is EAX inside [EDX,EBX)?
	jb	short IZIT_INROM_EXIT ; Jump if so (note CF=1)
IZIT_INROM_LOOP:
	mov	eax,ecx 	; Skip to next potential block

	cmp	eax,@ROMSTOP	; Izit the end?
	jb	short IZIT_INROM_NEXT ; Jump if not
				; Fall through with CF=0 (not in a ROM)
IZIT_INROM_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc IZIT_INROM		; End IZIT_INROM procedure
	page
BeginProc DISP_RAMERR		; Display RAM Errors
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Display RAM= region assignment errors

|

	pushad			; Save registers

	test	PMI_FLAG,@PMI_V86DISPLAY ; Should we display any errors?
	jz	near ptr DISP_RAMERR_EXIT ; Jump if not

; See if there were any errors

	mov	ecx,length RAM_ERRMAP ; Get # dwords in RAM_ERRMAP
	xor	esi,esi 	; Initialize index
@@:
	cmp	RAM_ERRMAP[esi*(type RAM_ERRMAP)],0 ; Any errors in the dword?
	jne	short @F	; Jump if so

	inc	esi		; Skip to next dword (note CF unchanged)

	loop	@B		; Jump if more dwords to check

	jmp	DISP_RAMERR_EXIT ; Join common exit code

@@:
	mov	esi,OFFSET32 MSG_RAMPAM_HDR ; Offset to error msg text
	call	DISPLAY 	; Put message on debugging screen

	mov	edx,OFFSET32 MSG_RAMPAM_HDR ; Offset to error msg text
	mov	ah,@STROUT	; Function code to display a string at DS:EDX
	VxDint	21h		; Display a message

	mov	ecx,32*(length RAM_ERRMAP) ; Get # bits in RAM_ERRMAP
	xor	esi,esi 	; Initialize index
DISP_RAMERR_NEXT:

; Look for initial error

	bt	RAM_ERRMAP,esi	; Izit in error?
	jnc	short DISP_RAMERR_LOOP ; Jump if not

	mov	eax,esi 	; Copy initial index

; Look for trailing error

@@:
	bt	RAM_ERRMAP,esi	; Izit in error?
	jnc	short @F	; Jump if not

	inc	esi		; Skip to next 4KB block

	loop	@B		; Jump if more 4KB blocks to check
@@:
	REGSAVE <ecx,esi>	; Save registers

; The indices in the range [EAX, ESI) are in error

	shl	eax,12-4	; Convert from 4KB to paras
	add	eax,@RAMSTART shr (4-0) ; Plus starting para

	lea	edi,MSG_RAMPAM_UGH1 ; Place to stick ASCII HEX digits
	mov	ecx,4		; # of digits
	call	TOHEX		; Format the V86 page #

	mov	eax,esi 	; Get ending address
	shl	eax,12-4	; Convert from 4KB to paras
	add	eax,@RAMSTART shr (4-0)-1 ; Plus starting para,
				; less one to get ending para
	lea	edi,MSG_RAMPAM_UGH2 ; Place to stick ASCII HEX digits
	mov	ecx,4		; # of digits
	call	TOHEX		; Format the V86 page #

	mov	esi,OFFSET32 MSG_RAMPAM_UGH ; Offset to error msg text
	call	DISPLAY 	; Put message on debugging screen

	mov	edx,OFFSET32 MSG_RAMPAM_UGH ; Offset to error msg text
	mov	ah,@STROUT	; Function code to display a string at DS:EDX
	VxDint	21h		; Display a message

	REGREST <esi,ecx>	; Restore registers

	jecxz	DISP_RAMERR_EXIT ; Jump if nothing remains
DISP_RAMERR_LOOP:
	inc	esi		; Skip to next 4KB block

	loop	DISP_RAMERR_NEXT ; Jump if more 4KB blocks to check

	mov	edx,OFFSET32 MSG_IDATA_PRESS ; Offset to error msg text
	mov	ah,@STROUT	; Function code to display a string at DS:EDX
	VxDint	21h		; Display a message

	mov	ah,@GETKEY	; Function code to get a key
	VxDint	16h		; Wait for a keystroke
DISP_RAMERR_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc DISP_RAMERR		; End DISP_RAMERR procedure

	page
BeginProc RAM_AMM		; RAM Assign, Map, and Modify
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Assign the V86 pages used by a RAM= buffer.
	Map the physical memory into the V86 address space.

On entry:

EBX	=	VM handle

|

RAM_AMM_STR struc		; Structure to access stacked arguments

	dd	?		; ...	   EBP
	dd	?		; Caller's EIP
RAM_AMM_PHYS dd ?		; Physical address

RAM_AMM_STR ends		; End RAM_AMM_STR structure

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,edx,esi> ; Save caller's registers

	mov	edx,[ebp].RAM_AMM_PHYS ; Get physical address
	shr	edx,(12-0)	; Convert byte address to page #
	sub	eax,eax 	; A handy zero
	mov	ecx,1		; 4KB page count

	push	edx		; Save V86 page #

;					   V86 page #
;					   |	Count
;					   |	|    Global assignment
;					   |	|    |	  Flags
;					   |	|    |	  |
	VMMcall _Assign_Device_V86_Pages <edx, ecx, eax, eax>
	pop	edx		; Restore V86 page #

	cmp	eax,1		; Test return code
	jb	short RAM_AMM_EXIT ; Jump on error (note CF=1)

; Set bit so we'll later remember we've assigned the page

	sub	edx,0A0h	; Bitmap starts at page A0h.
	bts	ASSIGN_BMP,edx	; Set bit for this page

; Connect the physical memory containing the cached ROMs pages their V86 pages

	mov	eax,[ebp].RAM_AMM_PHYS ; Get physical address
;;;;;;; and	eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	shr	eax,(12-0)	; Convert from byte address to physical page #

;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Flags
;				|    |	  |    |  |
	VMMcall _PhysIntoV86  <eax, ebx, eax, 1, 0>

	cmp	eax,1		; Test return code
	jb	short RAM_AMM_EXIT ; Jump on error (note CF=1)

; Mark the PTE as CD

; Because _ModifyPageBits won't let us set $PTE_CD, we map in CR3,
; get the physical address of the first page table, map it in, and
; set $PTE_CD directly.  So there.

	mov	eax,cr3 	; Get current PBDR
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	cmp	eax,-1		; Did it fail?
	je	short RAM_AMM_DONE ; Jump if so (just ignore the error)

	mov	eax,[eax]	; Get the physical address of the 1st PDE
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	VMMcall _MapPhysToLinear <eax, 4096, 0>

	cmp	eax,-1		; Did it fail?
	je	short RAM_AMM_DONE ; Jump if so (just ignore the error)

	mov	edx,[ebp].RAM_AMM_PHYS ; Get physical address (/4KB)
	shr	edx,(12-2)-0	; Convert from bytes to 4KB in dwords

	or	[eax+edx].EDD,mask $PTE_CD ; Set the cache Disable bit
RAM_AMM_DONE:
	clc			; Normal return indicator
RAM_AMM_EXIT:
	REGREST <esi,edx,ecx,eax> ; Restore caller's registers

	pop	ebp		; Restore any previous stack frame

	ret	1*4		; Return to caller, popping argument

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RAM_AMM		; End RAM_AMM procedure

	 page
BeginProc ROM_AMM		; ROM Assign, Map, and Modify
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Assign the V86 pages used by a cached ROM.
	Map the physical memory into the V86 address space.
	Modify the PTE bits so we get control on writes into the ROM.

On entry:

EBX	=	VM handle

|

RAMM_STR	 struc		; Structure to access stacked arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
RAMM_UP  dd	 ?		; 4KB page count rounded up
RAMM_DN  dd	 ?		; 4KB page count rounded down
RAMM_PTEADR dd	 ?		; Address of PTE associated with V86 address
RAMM_V86 dd	 ?		; V86 address of start of ROM

RAMM_STR	 ends		; End RAMM_STR structure

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,esi> ; Save caller's registers

; Under some circumstances, USE= and VGASWAP will conflict within MAX
; and create high DOS at the end of VGASWAPed ROMs.
; Look for that case and if found reduce the length of the work done here.

	 REGSAVE <esi>		; Save registers

	 mov	 ecx,[ebp].RAMM_DN ; 4KB page count rounded down
	 mov	 edx,[ebp].RAMM_V86 ; Get input V86 address

ROM_AMM_LP1:
	 lodsd			; Pick up next PTE

	 test	 eax,mask $PTE_RW ; Is this a ROM?
	 jz	 short ROM_AMM_SKP ; Yes, so it's OK

	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	 cmp	 eax,edx	; Izit mapped 1:1?
	 je	 short ROM_AMM_SKP ; Yes, so it's OK

; We've hit a page that isn't a ROM and it's not mapped 1:1.
; Limit the lengths to less than this page

	 sub	 ecx,[ebp].RAMM_DN ; Calculate how far we've gone
	 neg	 ecx		; ...

; ECX = # of pages we really want to assign and map

	 mov	 [ebp].RAMM_DN,ecx ; Update 4KB page count rounded down
	 mov	 [ebp].RAMM_UP,ecx ; Update 4KB page count rounded up

	 jmp	 short ROM_AMM_FILTER ; Rejoin common code

ROM_AMM_SKP:
	 loop	 ROM_AMM_LP1	; Check 'em all

ROM_AMM_FILTER:
	 REGREST <esi>		; Restore registers

; Force VxDcall VDD2_Get_Version to fail
; This will cause the over enthusiastic VDD to leave B0-B8 alone.

	 push	 eax		; Save

	 mov	 eax,[ebp].RAMM_V86 ; Get input V86 address
	 shr	 eax,(12-0)	; Convert byte address to page #
	 call	 ProcessPageInMonoDispArea ; Indicate it should fail if B0 - B8

	 pop	 eax		; Restore

	 mov	 edx,[ebp].RAMM_V86 ; Get input V86 address
	 shr	 edx,(12-0)	; Convert byte address to page #
	 sub	 eax,eax	; A handy zero
	 mov	 ecx,[ebp].RAMM_UP ; 4KB page count rounded up

	 push	 edx		; Save V86 page #

;					   V86 page #
;					   |	Count (rounded up)
;					   |	|    Global assignment
;					   |	|    |	  Flags
;					   |	|    |	  |
	 VMMcall _Assign_Device_V86_Pages <edx, ecx, eax, eax>
	 pop	 edx		; Restore V86 page #

; Set bit so we'll later remember we've assigned the page

	 sub	 edx,0A0h	; Bitmap starts at page A0h.
	 bts	 ASSIGN_BMP,edx ; Set bit for this page

	 mov	 ecx,[ebp].RAMM_DN ; 4KB page count rounded down

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em the AssignDeviceV86Pages failed and crash

	 mov	 esi,OFFSET32 MSG_ROMADP_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
RAMM_PAGE_LP:
	 mov	 edx,[ebp].RAMM_V86 ; Get V86 address
	 shr	 edx,(12-0)	; Convert from byte address to page #
	 sub	 edx,0A0h	; Bitmap starts at A0 page
	 bts	 ROM_BMP,edx	; Set bit for this ROM

; Connect the physical memory containing the cached ROMs pages their V86 pages

	 lodsd			; Pick up next PTE
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	 shr	 eax,(12-0)	; Convert from byte address to physical page #

	 mov	 edx,[ebp].RAMM_V86 ; Get V86 address
	 shr	 edx,(12-0)	; Convert byte address to page #

	 push	 ecx		; Save around call
;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Flags
;				|    |	  |    |  |
	 VMMcall _PhysIntoV86  <eax, ebx, edx, 1, 0>
	 pop	 ecx		; Restore after call

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em the PhysIntoV86 failed and crash

	 mov	 esi,OFFSET32 MSG_ROMPIV_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Mark the PTE R/O

	 mov	 edx,[ebp].RAMM_V86 ; Get V86 address
	 shr	 edx,(12-0)	; Convert byte address to page #

	 push	 ecx		; Save around call
	 VMMcall _ModifyPageBits <ebx, edx, 1, <not P_WRITE>, 0, PG_IGNORE, 0>
	 pop	 ecx		; Restore after call

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em the ModifyPageBits failed and crash

	 mov	 esi,OFFSET32 MSG_MPB_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Prepare for and loop to next page of this ROM

	 add	 [ebp].RAMM_V86,4096 ; Bump to next page
;;;;;;	 loop	 RAMM_PAGE_LP	; Get 'em all
	 dec	 ecx		; Account for ROM page just assigned
	 jecxz	 short @F	; Exit loop if done
	 jmp	 RAMM_PAGE_LP	; Get 'em all
@@:

	 clc			; Normal return indicator
RAMM_XIT:
	 REGREST <esi,edx,ecx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore any previous stack frame

	 ret	 4*4		; Return to caller, popping arguments

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ROM_AMM		; End ROM_AMM procedure

	 page
BeginProc TEST_PAGEMAP		; Test PMI_PAGE_MAP
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Test a bit in our local copy of the Device_V86_Pages_Array
	to see if it already assign by another virtual device.

ENTRY:
	EDX = linear address in 1st megabyte

EXIT:
	Carry flag set if page is already taken

|

	 REGSAVE <eax,edx>	; Save caller's registers

	 shr	 edx,(12-0)	; Convert byte address to page #
	 mov	 eax,edx	; Copy page # to EAX
	 and	 eax,1Fh	; Bit # MOD 32
	 shr	 edx,(5-0)	; Convert page # to map index

	 bt	 PMI_PAGE_MAP[edx*4],eax ; Check page bit in pages array

	 REGREST <edx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  TEST_PAGEMAP		; End TEST_PAGEMAP procedure
	 page
BeginProc SETUP_OPTIONS 	; Set flags for optional VxD features
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Set flags for optional VxD features.

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

; Check state of VirtualHighDOS switch in SYSTEM.INI

	 sub	 esi,esi	; NULL indicates [386Enh] section
	 mov	 edi,OFFSET32 STR_VIRTUALHIGHDOS ; Pointer to option

	 sub	 eax,eax	; Assume feature is disabled

	 VMMcall Get_Profile_Decimal_Int ; Get integer value of option
				; Carry flag set:
				;	Entry not found
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;		EAX = default value
				;	Zero flag clear:
				;		EAX = value from SYSTEM.INI

; If CY or ZR there isn't a valid VirtualHighDOS cookie in SYSTEM.INI
; so we'll assume the feature is disabled.

	 jc	 short SETUP_OPTIONS_XVHD ; Skip if VirtualHighDOS not found

	 or	 eax,eax	; Was it 'VirtualHighDOS=0'?
	 jz	 short SETUP_OPTIONS_XVHD ; Skip if so

; VirtualHighDOS != 0 in SYSTEM.INI, enable the feature

SETUP_OPTIONS_VHD:
	 or	 PMI_FLAG,@PMI_VIRT_HIGHDOS ; Indicate we're providing it

SETUP_OPTIONS_XVHD:

ifdef @DEBUG
	 test	 PMI_FLAG,@PMI_VIRT_HIGHDOS ; Are we providing VHD?
	 jnz	 short @F	; Skip if so

	 REGSAVE <esi>		; Save caller's registers

	 mov	 esi,OFFSET32 MSG_NOVHD ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 REGREST <esi>		; Restore caller's registers
@@:
endif				; IFDEF @DEBUG

	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SETUP_OPTIONS		; End SETUP_OPTIONS procedure

	 page
BeginProc SETUP_HIGHDOS_MAPS	; Setup bitmaps for high DOS pages
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Trundle through the high DOS arena setting up a bitmap.
	There is a bit per 4KB page.

|

	 pushad 		; Save caller's registers

	 and	 PMI_FLAG,(not @PMI_NONSPAN) ; Indicate we haven't yet seen
				; any valid high DOS memory

	 movzx	 ebx,OVRMAC	; Pick up segment of 1st MAC in high DOS
	 cmp	 bx,-1		; Is there a high DOS arena?
	 je	 SHM_CLC	; Exit w/ carry clear if not

	 shl	 ebx,(12-8)	; Convert from segment to linear address

SHM_NXT:

; EBX = V86 linear address of the MAC entry being examined

; Before we can examine the MAC entry, we must determine the physical address
; via 386MAX's PTEs and PHYS2LIN them.  What a major pain!

; Get the page # containing the MAC entry and 386MAX's PTE for it

	 mov	 eax,ebx	; V86 linear address of MAC entry
	 shr	 eax,(12-0)	; Convert from linear address to page #

	 mov	 edx,PDIR_LIN	; Get linear address of 386MAX's PTEs
	 mov	 edx,[edx+eax*4] ; Get PTE for page of interest
	 and	 edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field

	 mov	 eax,ebx	; V86 linear address of MAC entry
	 and	 eax,(4096-1)	; Isolate offset
	 add	 edx,eax	; Physical address of MAC entry

; Get Window linear address for the MAC entry

	 push	 edx		; Pass physical address of MAC entry's page
	 push	 (size MAC_STR) ; Maximum length we're interested in
	 call	 PHYS2LIN	; Convert to linear address in EAX

; FIXME Add error test code after PHYS2LIN in SETUP_HIGHDOS_MAPS
ifdef @DEBUG
	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

	 BREAK			; Call the debugger FIXME
@@:
endif				; IFDEF @DEBUG

	 mov	 esi,eax	; Copy Windows linear address of MAC entry

; If this isn't a special entry, map the high DOS pages it overlaps

	 cmp	 [esi].MAC_OWNR,@MAC_SPAN	; Izit a spanning entry?
	 je	 short SHM_ADVANCE		; Advance if so

	 test	 PMI_FLAG,@PMI_NONSPAN	; Have we seen a non-spanning entry?
	 jnz	 short @F		; Jump if so

	 or	 PMI_FLAG,@PMI_NONSPAN	; We've seen a non-spanning entry
	 mov	 FIRST_NONSPAN,ebx	; Remember where we saw it
@@:

; Find the end of this MAC entry

	 movzx	 eax,[esi].MAC_NPAR ; # paragraphs allocated to this MAC entry
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 lea	 edx,[ebx+(type MAC_STR)-1] ; End of this MAC entry space

	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Skip inclusion of next MAC header if so

	 add	 edx,(type MAC_STR) ; Account for next MAC header
@@:
	 add	 edx,eax	; ...

; EBX = V86 linear address of the MAC entry being examined
; EDX = V86 linear address of next MAC entry

	 mov	 eax,ebx	; Copy V86 linear address of MAC entry
	 shr	 eax,(12-0)	; Convert from linear address to page #

	 shr	 edx,(12-0)	; Convert from linear address to page #

; EAX = page # of 1st page
; ECX = page # of the MAC entry itself
; EDX = page # of last page (inclusive)

SHM_ILP:
	 bts	 HIGHDOS_MAP,eax ; Set bit for this page

	 inc	 eax		; Bump to next page

	 cmp	 eax,edx	; Did we get 'em all yet?
	 jbe	 short SHM_ILP	; Jump if not

; Advance to next MAC entry.

SHM_ADVANCE:
	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Yes, exit loop

	 movzx	 eax,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 lea	 ebx,[ebx+(type MAC_STR)] ; Advance to next MAC entry
	 add	 ebx,eax	; ...

	 jmp	 SHM_NXT	; Continue on to next MAC entry
@@:
	 mov	 bx,-1		; Assume no high DOS memory

	 test	 PMI_FLAG,@PMI_NONSPAN ; Did we find any high DOS?
	 jz	 short @F	; Jump if the assumption was correct

	 mov	 ebx,FIRST_NONSPAN ; V86 linear address of lowest high DOS
	 shr	 ebx,4		; Convert from V86 linear address to paras
@@:
	 mov	 OVRMAC,bx	; Update OVRMAC for other users

SHM_CLC:
	 clc			; Normal return indicator
SHM_XIT:
	 popad			; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SETUP_HIGHDOS_MAPS	; End SETUP_HIGHDOS_MAPS procedure
	 page
BeginProc EXCLUDE_MONO		; Keep VDD away from pages B0-B7
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

EXCLUDE_MONO

DESCRIPTION:
	On systems with an ultra high res VGA adapter present,
	a Windows VDD and driver may attempt to use the B000-B7FF area to
	improve graphics performance.  386MAX may have recovered this memory
	for use as high DOS.  Under Windows 3.0 this wasn't a problem because
	386MAX.VXD attached the high DOS manually, before the VDD tried to
	assign it.  Finding it already in use, the VDD ignores the area.
	Under Windows 3.1, the VMM/V86MMGR hooks up the high DOS for us,
	based on information in the Global Paging Import Spec data structure.
	In this case, the VDD gets first crack at the mono area and grabs it.
	When VMM tries to hook up the high DOS, the area's been assigned.
	Windows quits with an error, 'Cannot install a UMB at B000...'.

	A RAM=B000-B800 will fix the problem.

	This code roots out the situation and tricks the LoadHi components
	into responding to VDD2_Get_Version.  The VDD will ignore B0-B8 if
	VDD2 is present.

	This is active for Windows 3.1 only.

	Due to a problem on the Cabletron network adapter, we also check
	for EMMExclude=B000-B7FF in SYSTEM.INI.  If found, we'll call
	ProcessPageInMonoDispArea to keep the VDD away from B0 also.

|

	 REGSAVE <eax,edx,esi,edi>	; Save caller's registers

	 cmp	 WIN3_VERSION,030Ah	; Izit Windows 3.10?
	 jb	 EXLMONO_XIT		; Skip all this work if not

if 0
	 mov	 eax,PDIR_LIN		; Linear address of 386MAX's PTEs
	 mov	 eax,[eax+0B0h*4]	; Pick up PTE for B0

	 test	 eax,mask $PTE_AV0	; Is it an EMS mappable page?
	 jnz	 short EXLMONO_CHKEMM	; Yes, so it's not high DOS

	 test	 eax,mask $PTE_RW	; Is it a ROM?
	 jz	 short EXLMONO_CHKEMM	; Yes, so it's not high DOS

	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	 cmp	 eax,0B0000h		; Izit mapped 1:1?
	 jne	 short EXLMONO_DOIT	; No, so it's high DOS
endif
	 test	 HIGHDOS_MAP[(0B0h/8)].LO,0FFh ; Anything in B0-B7 used?
	 jnz	 short EXLMONO_DOIT	; Use the trick if so

EXLMONO_CHKEMM:
; Check for EMMExclude=B000-B7FF in SYSTEM.INI
	 sub	 edx,edx		; EDX ==> default string
	 sub	 esi,esi		; NULL indicates [386Enh] section
	 lea	 edi,STR_EMMEXCLUDE	; EDI ==> keyname
	 VMMcall Get_Profile_String	; Return CY if not found
	 jc	 short EXLMONO_NOSTRING ; Jump if no string found

EXLMONO_NEXTSTRING:
	 push	 edx			; Save pointer to string
	 mov	 al,[edx]		; Pick up 1st character of string
	 call	 ISHEX			; Return ZR set if AL is a hex digit
	 jne	 short EXLMONO_SKIPSTRING ; Try next string if not

	 VMMcall Convert_Hex_String	; Return value in EAX, update EDX
	 cmp	 eax,0B7FFh		; Is it above the end of the mono?
	 ja	 short EXLMONO_SKIPSTRING ; Try next string if so

	 mov	 al,[edx]		; Pick up next character of string
	 inc	 edx			; Bump past it
	 cmp	 al,'-'                 ; Hyphen?
	 jne	 short EXLMONO_SKIPSTRING ; Try next string if not

	 mov	 al,[edx]		; Pick up next character of string
	 call	 ISHEX			; Return ZR set if AL is a hex digit
	 jne	 short EXLMONO_SKIPSTRING ; Try next string if not

	 VMMcall Convert_Hex_String	; Return value in EAX, update EDX
	 cmp	 eax,0B000h		; Is it below the start of the mono?
	 jb	 short EXLMONO_SKIPSTRING ; Try next string if so

; We've got an EMMExclude= that includes some part of B000-B7FF

	 add	 esp,4			; Strip EDX from the stack
	 jmp	 short EXLMONO_DOIT	; Go call ProcessPageInMonoDispArea

EXLMONO_SKIPSTRING:
	 pop	 edx			; Restore pointer to string
	 lea	 edi,STR_EMMEXCLUDE	; EDI ==> keyname
	 VMMcall Get_Next_Profile_String ; Return CY if not found
	 jnc	 short EXLMONO_NEXTSTRING ; Jump if string found
					; If CY set, fall into EXLMONO_NOSTRING
EXLMONO_NOSTRING:
	 jmp	 short EXLMONO_XIT	; Rejoin common code

EXLMONO_DOIT:
	 sub	 eax,eax		; MOV EAX,0B0h
	 mov	 al,0B0h		; ...
	 mov	 edx,eax		; Tell LoadHi it's mapped 1:1
	 call	 ProcessPageInMonoDispArea ; Indicate it should fail if B0 - B8

EXLMONO_XIT:
	 REGREST <edi,esi,edx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  EXCLUDE_MONO			; End EXCLUDE_MONO procedure
	 page

ISHEX_TAB db	 '0123456789ABCDEF'     ; Hex table for ISHEX

BeginProc ISHEX 		; Return ZR if AL is a hex digit
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return ZR if AL is a hex digit

EXTRY:
	AL = character to be tested

EXIT:
	Zero flag set if AL = a hex digit

|

	 REGSAVE <ecx,edi>		; Save caller's registers

	 lea	 edi,ISHEX_TAB		; ES:EDI ==> hex table
	 mov	 ecx,16 		; # of valid hex digits
	 cld				; Autoincrement
   repne scasb				; Search for hex digit
					; Note zero flag is returned
	 REGREST <edi,ecx>		; Restore caller's registers

	 ret				; Return zero flag to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ISHEX				; End ISHEX procedure
	 page
BeginProc VMAX_DEVICE_INIT		; Handler for Device_Init device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Device init is where most devices do the bulk of their initialization.
	SYS VM Simulate_Int, Exec_Int activity is allowed. Returning carry
	aborts device load only.

ENTRY:
	EBX	=	SYS VM's handle

EXIT:
	Carry clear if no error

ASSUMES:
	Interrupts have been (and still are) disabled.

	This call can NOT be failed without screwing up the LoadHi VxD!

|

	 BREAK	 DBG_FLAG,@DBG_DEVINIT	; Break if 386MAXDeviceInit

	call	DISP_RAMERR	; Display the RAM= assign error results, if any

; Display warning if there is no high DOS memory

	 cmp	 OVRMAC,-1	; OVRMAC == 0FFFFh if there are no UMBs
	 jne	 short @F	; Skip warning if there are UMBs

	 mov	 esi,OFFSET32 MSG_NU_WRN ; Warning: No High DOS Memory
	 call	 DISPLAY	; Put message on debugging screen
@@:

; Setup the V86 Page Fault callback hook

	 mov	 eax,0Eh	; Page Fault interrupt #
	 mov	 esi,OFFSET32 PAGEFAULT_V86 ; Callback procedure entry point

	 VMMcall Hook_V86_Fault ; Arrange for the call back
	 jnc	 short @F	; Skip error code if it appears to have worked

; Tell 'em HookV86Fault failed and crash

	 mov	 esi,OFFSET32 MSG_HVF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 PF_V86_OLD,esi ; Save offset to original handler

; Setup the PM Page Fault callback hook
; This was added 01 JUN 92 to fix Norton AntiVirus for Windows

	 mov	 eax,0Eh	; Page Fault interrupt #
	 mov	 esi,OFFSET32 PAGEFAULT_PM ; Callback procedure entry point

	 VMMcall Hook_PM_Fault	; Arrange for the call back
	 jnc	 short @F	; Skip error code if it appears to have worked

; Tell 'em HookPMFault failed and crash

	 mov	 esi,OFFSET32 MSG_HVF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 PF_PM_OLD,esi	; Save offset to original handler

; Hook INT 21h AX=5802/5803 to allow DOSMGR to unchain the high DOS arena

	 mov	 edx,REF_LIN		; Get Windows linear address of REF_STR
	 cmp	 [edx].REF_STRUC_VER,603h ; Izit 6.03, or newer?
	 jb	 short XSETUP_5802	; Don't setup a 5802/5803 handler

	 mov	 eax,21h		; Interrupt #
	 mov	 esi,OFFSET32 V86_INT21 ; ==> V86 INT 21h hook procedure
	 VMMcall Hook_V86_Int_Chain	; Hook INT 21h
XSETUP_5802:

	 call	 UPD_CHECK_WIN	; Patch CHECK_WIN in QMAX_XMS.ASM if appropriate

; Get a Windows linear address to the 386LOAD.CFG file

	 mov	 edx,REF_LIN	; Get linear address of reference data structure
	 mov	 eax,[edx].REF_CFGFILE ; Physical address of .CFG file text
	 or	 eax,eax	; Is there one?
	 jz	 short @F	; Skip PhysToLinear if not

	 push	 eax		; Physical address of .CFG file contents
	 push	 4096		; Maximum length we can handle
	 call	 PHYS2LIN	; Get linear address of .CFG file into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em CFGFILE PhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_CFG_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 CFG_LIN,eax	; Winlinadr of 386LOAD.CFG text

; Get Windows linear address of INT 2Fh/AX=1605 broadcast chain

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 movzx	 eax,[edx].REF_STARTUP.EHI ; ES of chain from AX=1605 broadcast
	 shl	 eax,(4-0)	; Convert from segment to bytes
	 movzx	 edx,[edx].REF_STARTUP.ELO ; ... plus BX
	 add	 eax,edx	; ==> Windows startup chain

	 push	 eax		; V86 linear address of SIS chain
	 push	 4096		; Length to map
	 call	 V86LIN2WIN	; Get Windows linear address of SIS

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em Win386_Startup_Info_Struc PhysToLinear failed and crash

	 mov	 esi,OFFSET32 MSG_STU_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 SIS_LIN,eax	; Winlinadr of 1605 chain

	 sub	 eax,eax	; Get a NULL
	 mov	 LOW_INST_ANCHOR,eax ; Initialize low DOS instance chain
	 mov	 UMB_INST_ANCHOR,eax ; Initialize UMB instance chain

	 call	 InstanceMagic	; Perform the magic instancing

ifdef @DOSMAX
	 call	 DOSMAX_DEVICEINIT	; Setup for DOSMAX
	 jc	 short VDI_XIT		; Pass CY along to WIN386
endif					; IFDEF @DOSMAX

	 clc				; Clear error return indicator

VDI_XIT:
	 ret				; Return to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_DEVICE_INIT	; End VMAX_DEVICE_INIT prcedure

	 page
BeginProc VMAX_INIT_COMPLETE	; Handler for Init_Complete device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Init_Complete is the final phase of device init called just before the
	WIN386 INIT pages are released and the Instance snapshot is taken.
	Devices which wish to search for a region of V86 pages >= A0h to use
	should do it at Init_Complete.
	SYS VM Simulate_Int, Exec_Int activity is allowed. Returning carry
	aborts device load only.

|

	 BREAK	 DBG_FLAG,@DBG_INITCOMP ; Break if 386MAXInitComplete

	 or	 PMI_FLAG,@PMI_INITCOMP ; Remember Init_Complete has occurred

ifdef @DOSMAX
	 call	 DOSMAX_INITCOMPLETE	; Setup for DOSMAX
	 jc	 short VIC_XIT		; Pass CY along to WIN386
endif					; IFDEF @DOSMAX

	 clc			; Clear error return indicator

VIC_XIT:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_INIT_COMPLETE	; End VMAX_INIT_COMPLETE

	 page
BeginProc SETUP_QMAX		; Get GDT selectors for 386MAX & setup XMS hooks
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Get GDT selectors for 386MAX's PGROUP, IGROUP, JGROUP, and FGROUP.
	Setup pointers for VXD2MAX FAR CALLs.

|

	 pushad 			; Save caller's registers

; Create AGROUP data selector at PL3

	 push	 0			; Pass linear address of AGROUP
	 push	 -1			; Pass length of AGROUP
	 push	 CPL0_DATA or CPL3	; Pass selector type
	 call	 SetupGDTE		; Create the GDT entry
	 mov	 AGROUP_4GB3,ax 	; Save as AGROUP data selector at PL3

; Create code and data selectors for PGROUP

	 mov	 edx,REF_LIN		; EDX ==> reference data structure
	 push	 [edx].REF_MAXPHYS	; Physical address of 386MAX
	 push	 [edx].REF_MAXLEN	; Length of 386MAX
	 call	 PHYS2LIN		; Get linear address of PGROUP into EAX
	 mov	 PGROUP_LIN,eax 	; Save linear address of 386MAX

	 push	 OFFSET32 MSG_MPTL3_UGH ; Offset to error msg text
	 call	 P2LERROR		; Fatal error if PHYS2LIN failed

	 push	 eax			; Pass linear address of PGROUP
	 push	 [edx].REF_MAXLEN	; Pass length of PGROUP
	 push	 CPL0_CODE		; Pass selector type
	 push	 CPL0_DATA		; ...
	 call	 SetupGDTE2		; Create the two GDT entries

	 mov	 PGROUP_CS,ax		; Save PGROUP code selector
	add	eax,8			; Skip to next selector
	 mov	 PGROUP_DS,ax		; Save PGROUP data selector

; Create PGROUP data selector at PL3

	 push	 PGROUP_LIN		; Pass linear address of PGROUP
	 push	 [edx].REF_MAXLEN	; Pass length of PGROUP
	 push	 CPL0_DATA or CPL3	; Pass selector type
	 call	 SetupGDTE		; Create the GDT entry
	 mov	 PGROUP_DS3,ax		; Save as PGROUP data selector at PL3

; Update selectors in the reference data

	 cmp	 [edx].REF_STRUC_VER,603h ; Izit 6.03 or newer
	 jb	 SETUP_QMAX_XNEWSELS	; Don't create selectors for old MAXs

	 mov	 ax,PGROUP_CS		; PGROUP code selector
	 mov	 [edx].REF_CSPGR,ax	; Save PGROUP code selector for 386MAX

	 mov	 ax,PGROUP_DS		; PGROUP data selector
	 mov	 [edx].REF_DSPGR,ax	; Save PGROUP data selector for 386MAX

; Create code and data selectors for IGROUP

	 push	 [edx].REF_IGRPHYS	; Physical address of IGROUP
	 push	 [edx].REF_IGRSIZE	; Length of IGROUP
	 call	 PHYS2LIN		; Get linear address of IGROUP into EAX
	 mov	 IGROUP_LIN,eax 	; Save linear address of IGROUP

	 push	 OFFSET32 MSG_MPTL3_UGH ; Offset to error msg text
	 call	 P2LERROR		; Fatal error if PHYS2LIN failed

	 push	 eax			; Pass linear address of IGROUP
	 push	 [edx].REF_IGRSIZE	; Pass length of IGROUP
	 push	 CPL0_CODE		; Pass selector type
	 push	 CPL0_DATA		; ...
	 call	 SetupGDTE2		; Create the two GDT entries

	 mov	 IGROUP_CS,ax		; Save selector
	 mov	 [edx].REF_CSIGR,ax	; Save IGROUP code selector for 386MAX
	add	eax,8			; Skip to next selector
	 mov	 IGROUP_DS,ax		; Save IGROUP data selector
	 mov	 [edx].REF_DSIGR,ax	; Save IGROUP data selector for 386MAX

; Create code and data selectors for JGROUP

	 push	 [edx].REF_JGRPHYS	; Physical address of JGROUP
	 push	 [edx].REF_JGRSIZE	; Length of JGROUP
	 call	 PHYS2LIN		; Get linear address of JGROUP into EAX
	 mov	 JGROUP_LIN,eax 	; Save linear address of JGROUP

	 push	 OFFSET32 MSG_MPTL3_UGH ; Offset to error msg text
	 call	 P2LERROR		; Fatal error if PHYS2LIN failed

	 push	 eax			; Pass linear address of JGROUP
	 push	 [edx].REF_JGRSIZE	; Pass length of JGROUP
	 push	 CPL0_CODE		; Pass selector type
	 push	 CPL0_DATA		; ...
	 call	 SetupGDTE2		; Create the two GDT entries

	 mov	 JGROUP_CS,ax		; Save selector
	 mov	 [edx].REF_CSJGR,ax	; Save JGROUP code selector for 386MAX
	add	eax,8			; Skip to next selector
	 mov	 JGROUP_DS,ax		; Save JGROUP data selector
	 mov	 [edx].REF_DSJGR,ax	; Save JGROUP data selector for 386MAX

; Create data selector for FGROUP

	 push	 [edx].REF_FGRPHYS	; Pass physical address of FGROUP
	 push	 [edx].REF_FGRSIZE	; Pass length of FGROUP
	 call	 PHYS2LIN		; Get linear address of FGROUP into EAX

	 push	 OFFSET32 MSG_MPTL3_UGH ; Offset to error msg text
	 call	 P2LERROR		; Fatal error if PHYS2LIN failed

	 push	 eax			; Pass linear address of FGROUP
	 push	 [edx].REF_FGRSIZE	; Pass length of FGROUP
	 push	 CPL0_DATA		; Pass selector type
	 call	 SetupGDTE		; Create the GDT entry
					; Control never returns if error
	 mov	 FGROUP_DS,ax		; Save FGROUP data selector
	 mov	 [edx].REF_DSFGR,ax	; Save FGROUP data selector for 386MAX
SETUP_QMAX_XNEWSELS:

; Setup pointers for FAR CALLs back into 386MAX.SYS

	 mov	 ax,PGROUP_CS		; Get selector for PGROUP
	 mov	 lpfnXMS_VXD2MAX.FSEL,ax ; Save for FAR CALL
	 mov	 lpfnUTL_VXD2MAX.FSEL,ax ; Save for FAR CALL

	 mov	 eax,[edx].REF_XMS_VXD2MAX.FOFF ; Copy the offset
	 mov	 lpfnXMS_VXD2MAX.FOFF,eax	; ...

	 mov	 eax,[edx].REF_UTL_VXD2MAX.FOFF ; Copy the offset
	 mov	 lpfnUTL_VXD2MAX.FOFF,eax	; ...

ifdef @DOSMAX
	 cmp	 [edx].REF_STRUC_VER,700h ; Izit Cannonball, or newer?
	 jb	 short @F		; Skip if not

	 mov	 eax,[edx].REF_LaDSTK_TAB ; Linear address of DSTK_TAB_STR
	 mov	 LaDSTK_TAB,eax 	; Copy to local storage for quick access

	 movzx	 eax,[edx].REF_DSTK_CNT ; Total # of DOS stacks we supply
	 mov	 DSTK_CNT,eax		; Copy to local storage for quick access

	 mov	 eax,[edx].REF_PDSTKCOM ; Seg:off of common return routine
	 mov	 PDSTKCOM,eax		; Copy to local storage for quick access
@@:
endif					; IFDEF @DOSMAX
	cmp	[edx].REF_STRUC_VER,800h ; Izit PnP, or newer?
	jb	near ptr SETUP_QMAX_XPnP ; Jump if not

	cmp	[edx].REF_PnP_SEG,0	; Izit present?
	je	near ptr SETUP_QMAX_XPnP ; Jump if not

; Map the system BIOS to a linear address

	push	@PnP_BIOS_BEG	; Physical address of system BIOS
	push	dword ptr (64*1024) ; Pass length of PnP BIOS
	call	PHYS2LIN	; Convert to linear address in EAX

	cmp	eax,-1		; Test for error return
	jne	short @F	; Jump if it worked

; This error can not be handled
; Tell 'em PnP PhysToLinear failed and return to LoadHi VxD

	mov	esi,OFFSET32 MSG_PnP_PTL_UGH ; Offset to error msg text
	call	DISPLAY 	; Put message on debugging screen

	VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	mov	LaPnPBIOS,eax		; Save as PnP BIOS linear address

	movzx	edi,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shl	edi,4-0 		; Convert from paras to bytes
	sub	edi,@PnP_BIOS_BEG	; Less starting BIOS address
	add	edi,LaPnPBIOS		; Add to get linear address of PnP struc

; At this point [edi] ==> PnP struc in BIOS

	cmp	[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F		; Jump if so

	mov	OffPnP_RMVEC,PnP2_RMVEC ; Save as offset
	mov	OffPnP_PMCS, PnP2_PMCS	; ...
	mov	OffPnP_PMOFF,PnP2_PMOFF ; ...
@@:
	mov	ebx,OffPnP_PMCS 	; Get offset to PnP_PMCS
	mov	eax,[ebx+edi]		; Get code segment base address
	sub	eax,@PnP_BIOS_BEG	; Less starting BIOS address
	add	eax,LaPnPBIOS		; Plus PnP BIOS linear address
	mov	LCL_PnP_PMCS,eax	; Save locally

; Setup GDT entry for PnP code segment base address

	push	eax			; Pass linear address of PnP BIOS
	push	dword ptr (64*1024)	; Pass length of PnP BIOS
	push	CPL0_CODE		; Pass selector type
	call	SetupGDTE		; Create the GDT entry

	mov	[edx].REF_PnPCS,ax	; Save PnP code selector

; Setup GDT entry for PnP data segment base address

	cmp	[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short SETUP_QMAX_PnP_OLD1 ; Jump if not (no PMDS in old struc)

	mov	eax,[edi].PnP_PMDS	; Get data segment base address

	cmp	eax,@PnP_BIOS_BEG	; Izit below start of system BIOS?
	jb	short @F		; Jump if so

	sub	eax,@PnP_BIOS_BEG	; Less our starting base
	add	eax,LaPnPBIOS		; Plus linear address of PnP BIOS
@@:
	mov	LCL_PnP_PMDS,eax	; Save locally

	push	eax			; Pass linear address of PnP BIOS
	push	dword ptr (64*1024)	; Pass length of PnP BIOS
	push	CPL0_DATA		; Pass selector type
	call	SetupGDTE		; Create the GDT entry

	mov	[edx].REF_PnPDS,ax	; Save PnP data selector
SETUP_QMAX_PnP_OLD1:
	PUSHD	0			; Pass pseudo-linear address
	push	dword ptr (64*1024)	; Pass length of PnP BIOS
	push	CPL0_DATA		; Pass selector type
	call	SetupGDTE		; Create the GDT entry

	mov	[edx].REF_PnPARG0,ax	; Save PnP argument data selector #0

	PUSHD	0			; Pass pseudo-linear address
	push	dword ptr (64*1024)	; Pass length of PnP BIOS
	push	CPL0_DATA		; Pass selector type
	call	SetupGDTE		; Create the GDT entry

	mov	[edx].REF_PnPARG1,ax	; Save PnP argument data selector #1

	PUSHD	0			; Pass pseudo-linear address
	push	dword ptr (64*1024)	; Pass length of PnP BIOS
	push	CPL0_DATA		; Pass selector type
	call	SetupGDTE		; Create the GDT entry

	mov	[edx].REF_PnPARG2,ax	; Save PnP argument data selector #2
SETUP_QMAX_XPnP:

; The REF_MAX2VXD_CB is a special case.  It must be updated in the original
; reference data structure maintained by 386MAX.

	 mov	 edx,OLDREF_LIN 	; ==> original reference data before
					; updating by the real mode init code

	 mov	 [edx].REF_MAX2VXD_CB.FSEL,cs ; Save selector for 386MAX utils
	 mov	 [edx].REF_MAX2VXD_CB.FOFF,OFFSET32 QMAX_HELPER ; ... the offset

; Callback to 386MAX.SYS to fixup all the FICALL and FIJMP selectors

	 mov	 edx,REF_LIN		; Get Windows linear address of REF_STR
	 cmp	 [edx].REF_STRUC_VER,603h ; Izit Cannonball, or newer?
	 jb	 short SETUP_QMAX_XFIXUP ; Don't call FIXUP_ISELS if not

	 mov	 ax,PGROUP_CS		; Get selector for 386MAX
	 mov	 [edx].REF_FIXUP_ISELS.FSEL,ax ; Save in DF for FAR CALL

	 REGSAVE <ds,es,fs,gs>		; Don't trust 386MAX.SYS to save 'em

; Prepare for fake CALLF

	 push	 PGROUP_CS		; Pass PGROUP code selector
	 push	 IGROUP_CS		; Pass IGROUP code selector
	 push	 JGROUP_CS		; Pass JGROUP code selector
	 push	 PGROUP_DS3		; Pass PGROUP data selector at PL3
	 push	 AGROUP_4GB3		; Pass AGROUP data selector at PL3

	 push	 cs			; Stack the selector for the RETFD
	 push	 OFFSET32 FIXUP_ISELS_RET ; Stack the offset

	 mov	 edx,REF_LIN		; Get Windows linear address of REF_STR
	 push	 [edx].REF_FIXUP_ISELS.FSEL.EDD ; Stack the selector
	 push	 [edx].REF_FIXUP_ISELS.FOFF ; Stack the offset ...

	 mov	 gs,FGROUP_DS		; Data selector for FGROUP
	 assume  gs:nothing		; Tell the assembler

	 mov	 fs,JGROUP_DS		; Data selector for JGROUP
	 assume  fs:nothing		; Tell the assembler

	 mov	 es,IGROUP_DS		; Data selector for IGROUP
	 assume  es:nothing		; Tell the assembler

	 mov	 ds,PGROUP_DS		; Data selector for PGROUP
	 assume  ds:nothing		; Tell the assembler

	 retf				; 'Call' FIXUP_ISELS in 386MAX.SYS
					; Returns to the next instruction
FIXUP_ISELS_RET:
	 REGREST <gs,fs,es,ds>		; Restore 'em all
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing

SETUP_QMAX_XFIXUP:
	 clc				; Normal return indicator

	 jmp	 short SETUP_QMAX_XIT	; Rejoin common exit code

SETUP_QMAX_ERRXIT:
	 stc				; Error indicator
SETUP_QMAX_XIT:
	 popad				; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SETUP_QMAX			; End SETUP_QMAX procedure
	 page
BeginProc SetupGDTE		; Allocate and initialize a GDT entry
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Allocate and initialize a GDT entry

Entry:
	On the stack (pushed in this order)
	    Linear address of base
	    Length
	    Selector type

Exit:
	FatalError if any error

	AX = allocated selector
	Arguments popped from stack

|

SETUPGDTE_STR	 struc			; Structure to access stacked arguments

		 dd	?		; ...	   EBP
		 dd	?		; Caller's EIP
SETUPGDTE_TYPE	 dd	?		; CPL0_DATA or CPL0_CODE
SETUPGDTE_LEN	 dd	?		; Length of segment
SETUPGDTE_BASE	 dd	?		; Base of segment

SETUPGDTE_STR	 ends			; End SETUPGDTE_STR structure

	 push	 ebp			; Prepare to address the stack
	 mov	 ebp,esp		; Hello, Mr. Stack

	 REGSAVE <ecx,edx>		; Save caller's registers

	 mov	 ecx,[ebp].SETUPGDTE_LEN ; Length of segment

; Convert the length in ECX to a descriptor limit, taking into account that
; the segment may exceed 1 MB.

	 sub	 edx,edx		; Assume BYTE granularity

	 cmp	 ecx,1024*1024		; Izit bigger than 1 MB?
	 jbe	 short @F		; Skip if so

	 or	 dl,(mask $DTE_G)	; Convert from BYTE to PAGE granularity

	 add	 ecx,4096-1		; Round up to next page ...
	 shr	 ecx,(12-0)		; ... and convert from bytes to pages
@@:
	 dec	 ecx			; Convert from length to limit

	 mov	 eax,[ebp].SETUPGDTE_TYPE ; CPL0_CODE or CPL0_DATA (CPL0 / CPL3)
	 and	 ax,(mask $DT_TYP)	; Isolate the selector type
	 cmp	 ax,CPL0_DATA and (mask $DT_TYP) ; Is it a data segment?
	 jne	 short @F		; Skip if not

	 or	 dl,(mask $DTE_B)	; Set the default to USE32 for DATA segs
@@:
	 mov	 eax,[ebp].SETUPGDTE_TYPE ; CPL0_CODE or CPL0_DATA (CPL0 / CPL3)

	 VMMcall _BuildDescriptorDWORDs <<[ebp].SETUPGDTE_BASE>,ecx,eax,edx,1>
	 VMMcall _Allocate_GDT_Selector <edx,eax,0>

	 or	 eax,eax		; Test for failure
	 jnz	 short @F		; Skip error code if OK

; Tell 'em Build/Allocate GDT Selector failed and crash

	 mov	 esi,OFFSET32 MSG_BAGDTS_UGH ; Offset to error msg text
	 call	 DISPLAY		; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 REGREST <edx,ecx>		; Restore caller's registers

	 pop	 ebp			; Restore any previous stack frame

	 ret	 3*4			; Return to caller, popping arguments

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SetupGDTE			; End SetupGDTE procedure
	page
BeginProc SetupGDTE2		; Allocate and initialize a GDT entry
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Allocate and initialize a GDT entry

Entry:
	On the stack (pushed in this order)
	    Linear address of base
	    Length
	    Selector type

Exit:
	FatalError if any error

	AX = allocated selector
	Arguments popped from stack

|

SETUPGDTE2_STR	 struc			; Structure to access stacked arguments

		 dd	?		; ...	   EBP
		 dd	?		; Caller's EIP
SETUPGDTE2_TYPE2 dd	?		; CPL0_DATA or CPL0_CODE
SETUPGDTE2_TYPE1 dd	?		; CPL0_DATA or CPL0_CODE
SETUPGDTE2_LEN	 dd	?		; Length of segment
SETUPGDTE2_BASE  dd	?		; Base of segment

SETUPGDTE2_STR	 ends			; End SETUPGDTE_STR structure

	push	ebp			; Prepare to address the stack
	mov	ebp,esp 		; Hello, Mr. Stack

	REGSAVE <ecx,edx>		; Save caller's registers

	push	[ebp].SETUPGDTE2_BASE	; Pass selector base
	push	[ebp].SETUPGDTE2_LEN	; ...		length
	push	[ebp].SETUPGDTE2_TYPE1	; ...  1st selector type
	call	SetupDesc		; Return with EDX:EAX == descriptor DDs

	push	edx			; Pass 1st selector's 1st desc dword
	push	eax			; ...		      2nd ...

	push	[ebp].SETUPGDTE2_BASE	; Pass selector base
	push	[ebp].SETUPGDTE2_LEN	; ...		length
	push	[ebp].SETUPGDTE2_TYPE2	; ...  2nd selector type
	call	SetupDesc		; Return with EDX:EAX == descriptor DDs

	push	edx			; Pass 2nd selector's 1st desc dword
	push	eax			; ...		      2nd ...

	call	GetSelPair		; Allocate consecutive selectors
					; Return with AX = 1st of two selectors

	REGREST <edx,ecx>		; Restore caller's registers

	pop	ebp			; Restore any previous stack frame

	ret	4*4			; Return to caller, popping arguments

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SetupGDTE2			; End SetupGDTE2 procedure
	page
BeginProc SetupDesc
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Setup descriptor dwords

On exit:

EDX	=	high-order descriptor dword
EAX	=	low-...

|

SDESC_STR struc

	dd	?			; Caller's EBP
	dd	?			; ...	   EIP
SDESC_TYPE dd	?			; CPL0_DATA or CPL0_CODE
SDESC_LEN  dd	?			; Length of segment
SDESC_BASE dd	?			; Base of segment

SDESC_STR ends

	push	ebp			; Prepare to address the stack
	mov	ebp,esp 		; Hello, Mr. Stack

	REGSAVE <ecx>			; Save register

	mov	ecx,[ebp].SDESC_LEN	; Length of segment

; Convert the length in ECX to a descriptor limit, taking into account that
; the segment may exceed 1 MB.

	sub	edx,edx 		; Assume BYTE granularity

	cmp	ecx,1024*1024		; Izit bigger than 1 MB?
	jbe	short @F		; Skip if so

	or	dl,(mask $DTE_G)	; Convert from BYTE to PAGE granularity

	add	ecx,4096-1		; Round up to next page ...
	shr	ecx,(12-0)		; ... and convert from bytes to pages
@@:
	dec	ecx			; Convert from length to limit

	mov	eax,[ebp].SDESC_TYPE	; CPL0_CODE or CPL0_DATA (CPL0 / CPL3)
	and	ax,(mask $DT_TYP)	; Isolate the selector type

	cmp	ax,CPL0_DATA and (mask $DT_TYP) ; Is it a data segment?
	jne	short @F		; Skip if not

	or	dl,(mask $DTE_B)	; Set the default to USE32 for DATA segs
@@:
	mov	eax,[ebp].SDESC_TYPE	; CPL0_CODE or CPL0_DATA (CPL0 / CPL3)

	VMMcall _BuildDescriptorDWORDs <<[ebp].SDESC_BASE>,ecx,eax,edx,1>

	REGREST <ecx>			; Restore

	pop	ebp			; Restore any previous stack frame

	ret	3*4			; Return to caller, popping arguments

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc SetupDesc
	page
BeginProc GetSelPair
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Allocate a pair of consecutive selectors

|

GSP_STR struc

	dd	?			; Caller's EIP
	dd	?			; ...	   EBP
GSP_DESC2LO dd	  ?			; 2nd selector low dword of descriptor
GSP_DESC2HI dd	  ?			; ...	       high ...
GSP_DESC1LO dd	  ?			; 1st selector low dword of descriptor
GSP_DESC1HI dd	  ?			; ...	       high

GSP_STR ends

	push	ebp			; Prepare to address the stack
	mov	ebp,esp 		; Hello, Mr. Stack

	REGSAVE <ebx,esi>		; Save registers

; Allocate one selector

	push	[ebp].GSP_DESC1HI	; Pass high dword of descriptor
	push	[ebp].GSP_DESC1LO	; ...  low ...
	call	GetOneSel		; Allocate one selector

	mov	ebx,esp 		; Save top of stack

	push	eax			; Save the selector
GetSelPairNext:

; Attempt to allocate another GDT selector which we hope
; is consecutive with the previous one

	push	[ebp].GSP_DESC1HI	; Pass high dword of descriptor
	push	[ebp].GSP_DESC1LO	; ...  low ...
	call	GetOneSel		; Allocate one selector

	push	eax			; Save the selector

	sub	eax,8			; Back off to previous selector

	cmp	ax,[esp+4]		; Izit consecutive?
	jne	short GetSelPairNext	; Jump if not

	add	esp,2*4 		; Strip off last two selectors
	mov	esi,eax 		; Save to return as result
@@:
	cmp	esp,ebx 		; Are we done?
	je	short @F		; Jump if so

	pop	eax			; Get next selector to free

	VMMcall _Free_GDT_Selector <eax,0> ; Free it

	jmp	short @B		; Go around again

@@:

; Set the descriptor types as appropriate

	VMMcall _SetDescriptor <esi,0,[ebp].GSP_DESC1HI,[ebp].GSP_DESC1LO,0> ; Set it

	lea	eax,[esi+8]		; Skip to next selector
	VMMcall _SetDescriptor <eax,0,[ebp].GSP_DESC2HI,[ebp].GSP_DESC2LO,0> ; Set it

	mov	eax,esi 		; Return selector in EAX

	REGREST <esi,ebx>		; Restore

	pop	ebp			; Restore any previous stack frame

	ret	4*4			; Return to caller, popping arguments

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc GetSelPair			; End SelPair procedure
	 page
BeginProc GetOneSel
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Allocate one selector

|

GOS_STR struc

	dd	?			; Caller's EBP
	dd	?			; ...	   EIP
GOS_DESC2 dd	?			; Second dword of descriptor
GOS_DESC1 dd	?			; First ...

GOS_STR ends

	push	ebp			; Prepare to address the stack
	mov	ebp,esp 		; Hello, Mr. Stack

	VMMcall _Allocate_GDT_Selector <[ebp].GOS_DESC1,[ebp].GOS_DESC2,0>

	or	eax,eax 		; Test for failure
	jnz	short @F		; Skip error code if OK

; Tell 'em Build/Allocate GDT Selector failed and crash

	mov	esi,OFFSET32 MSG_BAGDTS_UGH ; Offset to error msg text
	call	DISPLAY 	       ; Put message on debugging screen

	VMMcall Fatal_Error_Handler	; Return to real mode, print msg, and exit
					; Control never returns from Fatal_Error_Handler
@@:
	pop	ebp			; Restore any previous stack frame

	ret	2*4			; Return to caller, popping arguments

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc GetOneSel
	 page
BeginProc InstanceMagic 	; Perform the magic instancing
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	There are five sources of instance data:

(1)	VxD Real mode initialization via DS:SI
	These instance items are sorted in QMAX_EM2 by COPY_INST_DATA
	and pointed to by the REF_UMB_INST field.  These instance items are
	handed off to LoadHi by Get_Ptr_To_Instance_Data_List.

	Ex:	VINSTD.EXE dummy data instancing VxD and its stub TSR
		Novell IPX.COM and NET3/4 via NETWARE.386

(2)	Win386_Startup_Info_Struc via ES:BX after AX=1605h Int 2Fh broadcast
	LoadHi takes care of UMB instance items in this list by hooking
	the AddInstanceItem VMMcall.

	Ex:	API1605.COM dummy Windows-aware self-instancing TSR

(3)	386LOAD via the @LSEG_WINST flag and LSEG_INSTLO fields (386LOAD.CFG)

	Ex:	ANSI.SYS loaded high (its low DOS memory component)
		PC-MATE.COM loaded high or GETSIZE'ed

(4)	The 386MAX VxD via the 386LOAD.CFG file

	Ex:	PC-MATE.COM loaded low in the normal DOS manner

(5)	Unallocated high DOS memory via 386MAX.VXD

|

	 BREAK	 DBG_FLAG,@DBG_AUTOINST ; Break if 386MAXAutoInstance

	 push	 eax		; Save caller's registers

	 lea	 edi,ADDL_INST	; Ptr to output list of instance items

	 call	 DO_TYPE_1	; Copy UMB instance items provided by VxDs
	 jnc	 short @F	; Skip error code if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI01 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 call	 DO_TYPE_3	; Instance items via 386LOAD LSEG chain
	 jnc	 short @F	; Skip error code if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI02 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 call	 DO_TYPE_4	; Instance items via 386LOAD.CFG file and MACs
	 jnc	 short @F	; Skip error code if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI03 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 call	 DO_TYPE_5	; Instance the unallocated high DOS memory
	 jnc	 short @F	; Skip error code if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI15 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 sub	 eax,eax	; The terminating NULL
S32	 stosd			; End the list

	 pop	 eax		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc InstanceMagic		; End InstanceMagic procedure

	 page
BeginProc DO_TYPE_1		; Copy type 1 instance items
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Process type 1 instance data.

	Type 1 items come from VxD real mode init code via DS:SI

|

	 REGSAVE <eax,esi>	; Save caller's registers

	 cmp	 WIN3_VERSION,030Ah ; Izit Windows 3.10?
	 jae	 short DT1_XIT	; Skip all this work if so

	 cld			; Forward

; Move entries from Low DOS table into our table

	 mov	 esi,PTR_T1_LIN ; Winlinadr of type 1 UMB instance items
DT1_NXT:
	 lodsd			; Get next instance item from list
	 or	 eax,eax	; Is it the NULL terminator?
	 jz	 short DT1_NOMO ; Yes, exit the loop

	 cmp	 edi,ADDL_INST_Z ; Is our list full?
	 jb	 short @F	; Skip error code if not full yet

	 mov	 esi,OFFSET32 MSG_FTL_AI04 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
S32	 stosd			; Save the instance item
S32	 movsw			; ... and the length

	 jmp	 short DT1_NXT	; On to the next entry

DT1_NOMO:
	 clc			; Normal return indicator
DT1_XIT:
	 REGREST <esi,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DO_TYPE_1		; End DO_TYPE_1 procedure

	 page
BeginProc DO_TYPE_3		; Decide what to instance via 386LOAD LSEG chain
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Process type 3 instance items.

	Type 3 items come from 386LOAD via the @LSEG_WINST flag
	and LSEG_INSTLO fields.

|

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save caller's registers

	 movzx	 eax,LOADSEG	; Get segment of LSEG chain
	 or	 eax,eax	; Is there an LSEG chain?
	 jz	 DT3_GFD	; No, so we're done

	 shl	 eax,(4-0)	; Convert from paras to bytes
	 mov	 ebx,eax	; Save V86 address of 1st LSEG entry
DT3_LNXT:
	 mov	 LSEG_V86,ebx	; Save V86 address of current LSEG entry

	 push	 ebx		; V86 linear address of LSEG entry
	 push	 size LSEG_STR	; Length of LSEG entry
	 call	 V86LIN2WIN	; Do PhysToLin assuming our mapping

	 cmp	 eax,-1 	; Did it work?
	 jne	 short @F	; Yes, skip error code

	 mov	 esi,OFFSET32 MSG_FTL_AI05 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 esi,eax	; Linear address of LSEG entry

; Check for 386LOAD instance item request

	 test	 [esi].LSEG_FLAG,@LSEG_WINST ; Is the INSTANCE option set?
	 jz	 DT3_LSKP	; Skip on to next LSEG

; We've got a request to instance a TSR or device driver
; Find the MAC owner in the LSEG

	 movzx	 eax,[esi].LSEG_OWNRHI ; MAC owner in high DOS (if any)
	 or	 eax,eax	; Is there a high DOS owner?
	 jnz	 short @F	; Skip low DOS owner if so

	 movzx	 eax,[esi].LSEG_INSTLO ; MAC owner in low DOS
	 or	 eax,eax	; Is there a low DOS owner?
	 jnz	 short @F	; Skip error code if so

; LSEG_FLAG.@LSEG_WINST set with no corresponding LSEG_OWNRHI or LSEG_INSTLO
; Print the pending error apparatus

	 mov	 esi,OFFSET32 MSG_FTL_AI06 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 MAC_OWNER,ax	; Save for use in the MAC scans

; Get name of TSR or device driver file from LSEG

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save registers

	 lea	 esi,[esi].LSEG_FNE ; Get pointer to file name in LSEG

	 mov	 DT_FILENAME_FENCE,0 ; Fill in fence
	 lea	 edi,DT_FILENAME ; Get start of filename buffer
	 cld			; Forward
	 mov	 ah,' '         ; Scan for a terminating blank
	 mov	 ecx,8+1+3	; Length of filename including '.'
DT3_LSEGNAM_NXT:
	 lodsb			; Get character from name
	 cmp	 al,ah		; Is it the terminator?
	 je	 short DT3_LSEGNAM_XIT ; Exit loop if so
S32	 stosb			; Save in local buffer
	 loop	 short DT3_LSEGNAM_NXT ; Go back for next character
DT3_LSEGNAM_XIT:
	 sub	 al,al		; Get a NULL
S32	 stosb			; NULL terminate the local buffer

	 sub	 ecx,12 	; Get length of filename
	 neg	 ecx		; ...
	 inc	 ecx		; Plus one for the terminating NULL

	 lea	 edi,DT_FILENAME ; Get start of filename buffer

; EDI ==> filename, ECX = length

ifdef @DEBUG
	 mov	 CULLNAME_PTR,edi ; Save name for debugging output
	 mov	 CULLNAME_LEN,ecx ; Save length for debugging output
endif				; IFDEF @DEBUG
	 call	 CULL		; Weed out dangerous requests
	 REGREST <edi,esi,edx,ecx,eax> ; Restore registers

	 jc	 DT3_LSKP	; Skip this program if dangerous to instanced

; Low DOS areas may need to be instanced in two situations
; (1)	The low DOS component of a device driver 386LOADed high
; (2)	A TSR 386LOADed and GETSIZEed

	 movzx	 ecx,[esi].LSEG_INSTLEN ; Get length in paras to instance
	 jecxz	 short @F	; Skip the call if no low DOS area

	 shl	 ecx,(4-0)	; Convert from paras to bytes
	 movzx	 edx,[esi].LSEG_INSTLO ; Get segment in low DOS to be instanced
	 shl	 edx,(4-0)	; Convert to paras to V86 linear address

; N.B. CHK_TYPE_1 isn't get called because there can be no low DOS type 1 items

	 call	 CHK_TYPE_2	; Return CY if type 2 overlaps
	 jc	 short @F	; Skip instance call if overlapping

ifdef @DEBUG
	 call	 SHOW_INSTNAME	; Show 'em the program's name
endif				; IFDEF @DEBUG

	 call	 ADD_LOWDOS_ITEM ; Add instance item
	 jnc	 short @F	; Skip error code if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI07 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 movzx	 eax,[esi].LSEG_OWNRHI ; Get owner segment in high DOS
	 or	 eax,eax	; Is there one?
	 jz	 DT3_LSKP	; Skip instancing on this one

	 mov	 MAC_OWNER,ax	; Save for use in the MAC scans

; We've got a high DOS area to be instance tested

; ESI ==> LSEG entry
; EAX = Segment of owner MAC

; See if it's a device driver

DT3_LHI:
	 test	 [esi].LSEG_FLAG,@LSEG_DRV ; Is it a device driver?
	 jz	 short DT3_NOTBLK ; No, so it's OK

; Get Winlinadr of device driver header and make sure it's not a block device

	 movzx	 eax,MAC_OWNER	; Get segment of device driver
	 shl	 eax,4		; Convert from paras to bytes
	 sub	 eax,size MAC_STR ; Back up to MAC entry header

	 push	 eax		; V86 linear address of MAC entry header
	 push	 4096		; Length
	 call	 V86LIN2WIN	; Get Winlinadr of device driver header

	 cmp	 eax,-1 	; Did it work?
	 jne	 short @F	; Yes, skip error code

	 mov	 esi,OFFSET32 MSG_FTL_AI08 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 test	 [eax+size MAC_STR].DD_ATTR,DRV_ATTR_CHAR ; Character device?
	 jz	 short DT3_LSKP ; It's a block device, so refuse it

; Instance a character device driver 386LOADed high

; Check on overriding a Windows aware programs' self-instancing

	 movzx	 ecx,[eax].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes

	 movzx	 edx,MAC_OWNER	; Segment of the block being instanced
	 shl	 edx,(4-0)	; Convert to V86 linear address

; EDX	=	V86 linear address of block to be instanced
; ECX	=	Length in bytes to instance
	 call	 CHK_TYPE_1	; Return CY if type 1 overlaps
	 jc	 short DT3_LSKP ; Skip it if already instanced

	 call	 CHK_TYPE_2	; Return CY if type 2 overlaps
	 jc	 short DT3_LSKP ; Skip it if already instanced and overlapped

ifdef @DEBUG
	 call	 SHOW_INSTNAME	; Show 'em the program's name
endif				; IFDEF @DEBUG

	 call	 ADD_HIGHDOS_INSTANCE_ITEM ; Instance it in high DOS memory
	 jnc	 short @F	; Skip error if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI09 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 jmp	 short DT3_LSKP ; Go on to the next entry

; Scan MACs for this owner, checking against old instance data

DT3_NOTBLK:
	 call	 MAC_PASS1	; Check MACs against type 1 instance items
	 jc	 short DT3_LSKP ; Old instance data overlapped this owner

	 call	 MAC_PASS2	; Scan MACs marking new instance data
	 jnc	 short @F	; Skip error if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI10 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Go on to next LSEG entry

DT3_LSKP:
	 movzx	 ebx,[esi].LSEG_NEXT ; Get pointer to next LSEG
	 cmp	 bx,-1		; Are we at the end of all the LSEGs?
	 je	 short @F	; Exit loop if so

	 shl	 ebx,(4-0)	; Convert from paras to bytes
	 jmp	 DT3_LNXT	; Go on to the next entry
@@:

; Instance the last entry for the 'Virtual High DOS' or 'Local LoadHi' feature
; ESI is a Windows linear address of the last LSEG in the chain
; LSEG_V86 is a V86 linear address of the last LSEG

	 mov	 ecx,type LSEG_NEXT ; Length to be instanced (2 bytes)
	 mov	 edx,LSEG_V86	; EDX is V86 linear address of last LSEG_NEXT

ifdef @DEBUG
	 push	 esi		; Save register

	 mov	 esi,OFFSET32 MSG_INST_LSEG ; ==> message text
	 call	 DISPLAY	; Tell 'em were about to instance a UMB

	 pop	 esi		; Restore register
endif				; IFDEF @DEBUG
	 cmp	 edx,0A0000h	; Izit above the high DOS line?
				; (as Windows see things)
	 jae	 short DT3_LL1	; Jump if so

	 call	 ADD_LOWDOS_ITEM ; Instance the LSEG in low DOS

	 jmp	 short DT3_LL2	; Rejoin common code

DT3_LL1:
	 call	 ADD_HIGHDOS_INSTANCE_ITEM ; Instance the LSEG in high DOS
DT3_LL2:
	 jnc	 short @F	; Skip error if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI18 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:


DT3_GFD:
	 clc			; Normal error indicator

	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DO_TYPE_3		; End DO_TYPE_3 procedure

	 page
BeginProc DO_TYPE_4		; Decide what to instance from 386LOAD.CFG file
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Process type 4 instance items.

	Type 4 items come from 386MAX VxD via the 386LOAD.CFG file.

|

	 REGSAVE <eax,ecx,edx,edi,esi> ; Save caller's registers

	 cld			; Forward

	 mov	 esi,CFG_LIN	; Winlinadr of 386LOAD.CFG text

DT4_NEXT:
	 cmp	 [esi].LO,EOF	; Are we at the end?
	 je	 short DT4_ALLDONE ; Exit inspection if so

	 call	 ISWHITE	; Are we looking at whitespace?
	 je	 short DT4_SKIP ; Consume and ignore remainder of line

	 cmp	 [esi].LO,CR	; Are we looking at an empty line?
	 je	 short DT4_SKIP ; Consume and ignore remainder of line

	 cmp	 [esi].LO,';'   ; Is it a comment line?
	 je	 short DT4_SKIP ; Consume and ignore remainder of line

	 mov	 dl,'I'         ; Instancing flag
	 call	 CHK_CFG_FLAG	; Inspect field for 'I' instancing flag
	 jne	 short DT4_SKIP ; Consume remainder of line if 'I' not present

; We found a line with the I flag present

	 call	 SKIPWHITE	; Skip over whitespace
	 jc	 short DT4_ALLDONE ; Carry indicates EOF
	 jz	 short DT4_SKIP ; Zero indicates CRLF

; FIXME start a subroutine here
; ESI ==> filename

	 call	 TOKENIZE	; Get length of filename into ECX

; Note ESI is advanced over filename by the following code

	 push	 ecx		; Save length
	 lea	 edi,DT_FILENAME ; Pointer to buffer
S32	 rep movsb		; Move filename to local buffer
	 sub	 al,al		; A handy zero
S32	 stosb			; Null terminate the name
	 pop	 ecx		; Restore length
	 inc	 ecx		; Account for NULL terminator
; FIXME end the subroutine here

	 lea	 edi,DT_FILENAME ; Pointer to buffer
	 call	 CULL		; Filter out nasty names
	 jc	 short DT4_SKIP ; Skip if it's on the forbidden list

; ECX is length for the comparisons
; Search the DOS arena for an instance of it loaded low.  (instance, get it?)

	 call	 SCAN_ARENA	; Trundle through the DOS arena
	 jnc	 short @F	; Skip error if it returned normally

	 mov	 esi,OFFSET32 MSG_FTL_AI11 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Skip and ignore remainder of line

DT4_SKIP:
	 call	 CONSUME	; Consume and ignore remainder of the line

	 jmp	 short DT4_NEXT ; Continue scanning the file

; Finished scanning the entire file

DT4_ALLDONE:
	 clc			; Indicate it all worked OK
DT4_XIT:
	 REGREST <esi,edi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DO_TYPE_4		; End DO_TYPE_4 procedure

	 page
BeginProc DO_TYPE_5		; Instance unallocated UMBs
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Process type 5 instance items.

	Type 5 items are unallocateed UMBs.

|

	 REGSAVE <eax,ebx,ecx,esi> ; Save caller's registers

	 test	 PMI_FLAG,@PMI_VIRT_HIGHDOS ; Are we supporting VHD?
	 jz	 short DT5_XITOK ; Skip the whole thing if not

	 movzx	 eax,OVRMAC	; Get segment of 1st UMB MAC entry into EAX

	 cmp	 ax,-1		; OVRMAC = 0FFFFh if there are no UMBs
	 je	 short DT5_XITOK ; Forget the whole thing if there's no high DOS

	 shl	 eax,(4-0)	; Convert from paras to bytes
	 mov	 ebx,eax	; Save V86 address of 1st MAC entry
DT5_NXT:
	 push	 ebx		; V86 linear address of MAC entry
	 push	 size MAC_STR	; Length of arena entry
	 call	 V86LIN2WIN	; Do LinToLin assuming our mapping

	 cmp	 eax,-1 	; Did it work?
	 jne	 short @F	; Yes, skip error code

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG

	 mov	 esi,OFFSET32 MSG_FTL_AI16 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 esi,eax	; Linear address of MAC entry

	 cmp	 [esi].MAC_OWNR,@MAC_FREE ; Is this entry unallocated
	 jne	 short DT5_SKP	; No, go test the next entry

; Instance this unallocated area of high DOS memory

; EDX	=	V86 linear address of block to be instanced
; ECX	=	Length in bytes to instance

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 inc	 ecx		; Add a paragraph for the MAC entry itself
	 shl	 ecx,(4-0)	; Convert from paras to bytes

	 mov	 edx,ebx	; Copy V86 address of MAC entry to proper reg

ifdef @DEBUG
	 push	 esi		; Save register

	 mov	 esi,OFFSET32 MSG_INST_UMB ; ==> message text
	 call	 DISPLAY	; Tell 'em were about to instance a UMB

	 pop	 esi		; Restore register
endif				; IFDEF @DEBUG

	 call	 ADD_HIGHDOS_INSTANCE_ITEM ; Instance it in high DOS memory
	 jnc	 short @F	; Skip error if it returned normally

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG

	 mov	 esi,OFFSET32 MSG_FTL_AI17 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Check for the last MAC entry and continue on to the next if appropriate

DT5_SKP:
	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Yes, exit loop

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes
	 lea	 ebx,[ebx+(type MAC_STR)] ; Advance to next MAC entry
	 add	 ebx,ecx	; ...

	 jmp	 short DT5_NXT	; Continue on to next entry
@@:

DT5_XITOK:
	 clc			; Normal error indicator

	 REGREST <esi,ecx,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DO_TYPE_5		; End DO_TYPE_5 procedure
	 page
BeginProc SCAN_ARENA		; Scan arean for our name
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Scan through the DOS arena looking for program to be instanced.
	If found, we instance the program.

ENTRY:
	EDI	==>	Filename we're looking for
	ECX	=	Length for the comparisons

|

	 REGSAVE <eax,edx,esi,edi> ; Save caller's registers

	 movzx	 eax,ARENA_ANCHOR ; Get segment of 1st MAC entry
SA_NXT:
	 movzx	 esi,ax 	; Segment of MAC entry
	 shl	 esi,(4-0)	; Convert from paras to V86 linear address

	 inc	 ax		; Bump segment to actual block

; Loop termination code changed to fix NOHIGH bug - WRL - 06DEC90
	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 SA_DONE	; Yes, exit - we don't instance the last block

; See if this block and its owner are one in the same

	 cmp	 ax,[esi].MAC_OWNR ; Check against owner
	 jne	 SA_SKP 	; No, so skip this MAC

; This MAC and its owner are equal

	 lea	 edx,[esi+size MAC_STR] ; EDX points to PSP

;;;;;;	 cmp	 ax,PSP_CTRL_PSP ; Are PSP segment and PSP_CTRL_PSP equal?
	 cmp	 ax,[edx+16h]	; Are PSP segment and PSP_CTRL_PSP equal?
	 je	 SA_SKP 	; Yes, so it's COMMAND.COM

	 push	 esi		; Save pointer to MAC
	 push	 edi		; Save pointer to filename we're looking for
	 call	 FIND_ENV_PGM	; Return EDI ==> program name
				; ESI ==> entire path and filename
				; EDX = length of filename including NULL
				; FEP_FLAG = 0 we couldn't find a name
				;	     1 for a PSP ENV name
				;	     2 for a DOS 4 MAC name

; Here's the drill on the name comparisons

	 cmp	 FEP_FLAG,0	; Did we find a name?
	 jne	 short @F	; Yes, skip special kludge

	 cmp	 FEP_FLAG,255	; Force NZ flag

	 jmp	 short SA_SKPCMP ; Skip comparision if FIND_ENV_PGM failed
@@:

; If FEP_FLAG = 1 we compare the entire filename and extension

	 cmp	 FEP_FLAG,1	; Are we doing the entire name and extension?
	 jne	 short SA_NAMONLY ; No, so go compare just the names

	 mov	 esi,edi	; Pointer to filename from PSP environment
	 mov	 edi,[esp]	; Refresh pointer to filename from .CFG

	 push	 ecx		; Save comparison length
	 repe cmpsb		; Compare the two filenames
	 pop	 ecx		; Restore comparison length

	 jmp	 short SA_SKPCMP ; Rejoin common code

; If FEP_FLAG = 2 we can only compare the filename
; ECX is length of the truncated filename

SA_NAMONLY:
	 mov	 esi,edi	; Pointer to filename environment
	 mov	 edi,[esp]	; Refresh pointer to filename from .CFG

; Saving the comparison length around the following REPE CMPSB is the fix
; for the bug discovered on Jesse's machine with the RECALL TSR and Windows 3.10
; This bug eventually caused some huge area of low DOS to be instanced
; which caused an Allocate_V86_Pages in the SHELL VxD to fail.

	 push	 ecx		; Save comparison length
	 repe cmpsb		; Compare the filenames
	 pop	 ecx		; Restore comparison length

; The above comparison will always fail (unless something's really wrong)
; If the failing source char is a NULL and the destination char is '.',
; then we've got a match

	 jne	 short @F	; Skip special UGH code

	 sub	 edi,edi	; Set ZR flag
	 inc	 edi		; Set NZ to indicate no match

	 jmp	 short SA_SKPCMP ; We'll just call it a no-match
@@:
	 cmp	 [edi-1].LO,'.' ; Was it the period from the extension?
	 jne	 short SA_SKPCMP ; Jump if no match

	 cmp	 [esi-1].LO,0	; Was it the terminating NULL?
	 jne	 short SA_SKPCMP ; Jump if no match

; They matched!  Unbelieveable

; Common post-comparison code

SA_SKPCMP:
	 pop	 edi		; Restore pointer to filename from .CFG
	 pop	 esi		; Restore pointer to MAC

ifdef @DEBUG
	 mov	 CULLNAME_PTR,edi ; Save name for debugging output
	 mov	 CULLNAME_LEN,ecx ; Save length for debugging output
endif				; IFDEF @DEBUG

	 jne	 short SA_NOMTCH ; Skip instancing if names differ

; Instance everything in the arena owned by the MAC in AX

	 BREAK	 DBG_FLAG,@DBG_AUTOINST ; Break if 386MAXAutoInstance

	 REGSAVE <eax,ecx,edx>	; Save registers

	 movzx	 edx,ax 	; Copy segment to be instanced
	 shl	 edx,(4-0)	; Convert from paras to V86 linear address

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes

	 call	 CHK_TYPE_2	; Return CY if type 2 overlaps
	 jc	 short @F	; Skip instance call if overlapping

ifdef @DEBUG
	 call	 SHOW_INSTNAME	; Show 'em the program's name
endif				; IFDEF @DEBUG

	 call	 ADD_LOWDOS_ITEM ; Add instance item (N.B. CY live thru REGREST
	 jnc	 short @F	; Skip error if OK

	 mov	 esi,OFFSET32 MSG_FTL_AI14 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 clc			; Kill CY from CHK_TYPE_2
	 REGREST <edx,ecx,eax>	; Restore registers

; Continue on to the next MAC entry

SA_NOMTCH:			; Names didn't match
SA_SKP: 			; Skip to next MAC entry
	 add	 ax,[esi].MAC_NPAR ; Bump AX to segment of next MAC entry

	 jmp	 SA_NXT 	; Continue on to next entry

SA_DONE:
	 clc			; Normal return indicator
SA_XIT:
	 REGREST <edi,esi,edx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SCAN_ARENA		; End SCAN_ARENA procedure

	 page
BeginProc CULL			; Weed out dangerous instancing requests
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Compare filename with .NFG list to weed out programs that
	should never be instanced.

ENTRY:
	EDI	==>	Filename we're searching for
	ECX	=	Length for comparisons

EXIT:
	Carry set if program was found in internal CULL_LIST.

	Carry clear if OK to instance program.

|

	 REGSAVE <eax,ecx,edi,esi> ; Save caller's registers

; Trundle through the CULL_LIST looking for our program name

CULL_GN:
	 cld			; Forward
	 lea	 esi,CULL_LIST	; Get Winlinadr to instance cull list
CULL_CMPNXT:
	 push	 edi		; Save pointer to filename
	 push	 esi		; Save pointer to CULL_LIST entry
	 push	 ecx		; Save length

	 repe cmpsb		; Compare the names

	 pop	 ecx		; Restore length
	 pop	 esi		; Restore pointer to CULL_LIST entry
	 pop	 edi		; Restore pointer to filename

	 je	 short CULL_CMPFND	; Exit loop if we hit a match

; Bump to next CULL_LIST entry

	 push	 ecx		; Save length
	 xchg	 esi,edi	; Swap pointers for SCASB
	 sub	 al,al		; Look for this terminating NULL
	 mov	 ecx,-1 	; Get it plenty of slack
	 repnz scasb		; Find terminating NULL
	 xchg	 edi,esi	; Restore pointers after SCASB
	 pop	 ecx		; Restore length

	 cmp	 [esi].LO,0	; Are we at the end of the list?
	 jne	 short CULL_CMPNXT ; Loop back if not

; We've exhausted the CULL_LIST without finding a match

	 clc			; Clear carry indicates instancing is OK

	 jmp	 short CULL_XIT ; Join common exit code

; We found the name in the CULL_LIST, return with CY

CULL_CMPFND:
	 stc			; Indicate it should NOT be instanced
CULL_XIT:
	 REGREST <esi,edi,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CULL			; End CULL procedure
	 page
BeginProc CHK_TYPE_1		; Check entry with type 1 instance items
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Given a V86 address and length we intend to instance, check against
	existing type 1 items for overlap.

ENTRY:
	EDX	==>	V86 address of start of area to be checked
	ECX	=	Length in bytes

EXIT:
	Return CY if this area is ALREADY instanced

|

	 REGSAVE <eax,ebx,esi,edi> ; Save caller's registers

	 mov	 esi,PTR_T1_LIN ; Winlinadr of type 1 UMB instance items
CI_NXT:
	 lodsd			; Get next instance item from list
	 or	 eax,eax	; Is it the NULL terminator?
	 jz	 short CI_NOMO	; Yes, exit the loop

	 movzx	 ebx,ax 	; Isolate and save V86 offset
	 sub	 ax,ax		; Kill offset
	 shr	 eax,(16-4)	; Form bytes address
	 add	 eax,ebx	; 32-bit linear address of instance item

; EAX is 32-bit address of instance item from existing list
; EDX is 32-bit address of area under test

; Does any part of the old item overlap the new item?

	 mov	 ebx,edx	; Start of new item
	 add	 ebx,ecx	; End of new item +1

	 cmp	 eax,ebx	; Compare start of old against end of new
	 jb	 short @F	; It may overlap, so check opposite end

	 add	 esi,2		; Skip IIS_SIZE field

	 jmp	 short CI_NXT	; Go on to next entry
@@:
	 movzx	 ebx,[esi].ELO	; Get IIS_SIZE
	 add	 esi,2		; Account for IIS_SIZE just fetched
	 add	 eax,ebx	; End of old item +1

	 cmp	 edx,eax	; Compare end of old item against start of new
	 jae	 short CI_NXT	; Doesn't overlap, so go on to next item

; This entry is already instanced

	 stc			; Indicate it's already instanced

	 jmp	 short CI_XIT	; Join common exit code

; We've exhausted the existing instance items and there were no matches

CI_NOMO:
	 clc			; Indicate it should be instanced
CI_XIT:
	 REGREST <edi,esi,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc CHK_TYPE_1		; End CHK_TYPE_1 procedure

	 page
BeginProc CHK_TYPE_2		; Check entry with type 2 instance items
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Given a V86 address and length we intend to instance, check against
	existing type 2 items for overlap.

ENTRY:
	EDX	=	V86 linear address and length of area to be checked
	ECX	=	Length of area to be checked

EXIT:
	Return CY if this area is ALREADY instanced

|

CSC_LCL_STR struc		; Structure for local storage

CLS_V86  dd	 ?		; Save area for input V86 linear address

CSC_LCL_STR ends		; End CSC_LCL_STR struc

	 enter	 size CSC_LCL_STR,0 ; Build local stack frame

	 mov	 [ebp-size CSC_LCL_STR].CLS_V86,edx ; Save input V86 linaddr

	 REGSAVE <eax,ebx,edx,esi> ; Save caller's registers

	 cld			; Forward through the instance list
	 mov	 esi,SIS_LIN	; Winlinadr of Win386_Startup_Info_Struc chain
CSC_NXT:
	 mov	 eax,[esi].SIS_INSTANCE_DATA_PTR ; Seg:off of instance list

	 or	 eax,eax	; Any instance items?
	 jz	 short CSC_BMP ; Jump if not

	 movzx	 edx,ax 	; Get and save offset
	 shr	 eax,16 	; Move segment to low-order end
	 shl	 eax,4		; Convert from paras to bytes
	 add	 eax,edx	; V86 linear address of instance list

	 push	 eax		; V86 linear address of instance list
	 push	 4096		; Length we want to inspect
	 call	 V86LIN2WIN	; Get Winlinadr of instance list

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em V86LIN2WIN failed and crash

	 mov	 esi,OFFSET32 MSG_VLW4_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 push	 esi		; Save pointer to next entry in SIS chain
	 mov	 esi,eax	; Get pointer to instance list
CSC_I_NXT:
	 lodsd			; Get next instance item from list
	 or	 eax,eax	; Is it the NULL terminator?
	 jz	 short CSC_I_XIT ; Yes, exit the loop

	 movzx	 ebx,ax 	; Isolate and save V86 offset
	 sub	 ax,ax		; Kill offset
	 shr	 eax,(16-4)	; Form bytes address
	 add	 eax,ebx	; 32-bit linear address of instance item

; EAX is V86 linear address of instance item from list

; Does any part of the new item overlap the old item?

	 mov	 edx,[ebp-size CSC_LCL_STR].CLS_V86 ; V86 linaddr to check

	 mov	 ebx,edx	; Start of new item
	 add	 ebx,ecx	; End of new item +1

	 cmp	 eax,ebx	; Compare start of old against end of new
	 jb	 short @F	; It may overlap, so check opposite end

	 add	 esi,2		; Skip IIS_SIZE field

	 jmp	 short CSC_I_NXT ; Go on to next entry
@@:
	 movzx	 ebx,[esi].ELO	; Get IIS_SIZE
	 add	 esi,2		; Account for IIS_SIZE just fetched
	 add	 eax,ebx	; End of old item +1

	 cmp	 edx,eax	; Compare end of old item against start of new
	 jae	 short CSC_I_NXT ; Doesn't overlap, so go on to next item

; This entry is already instanced

	 add	 esp,4		; Scrap pointer to SIS chain
	 stc			; Indicate it should not be instanced

	 jmp	 short CSC_XIT	; Join common exit code

CSC_I_XIT:
	 pop	 esi		; Restore pointer to SIS chain

; Bump to the next entry

CSC_BMP:
	 mov	 eax,[esi].SIS_NEXT_DEV_PTR ; Get seg:off to next link in chain

	 or	 eax,eax	; End of chain?
	 jz	 short CSC_XIT_OK ; Jump if so

	 movzx	 edx,ax 	; Get and save offset
	 shr	 eax,16 	; Move segment to low-order end
	 shl	 eax,4		; Convert from paras to bytes
	 add	 eax,edx	; V86 linear address of next device in SIS chain

	 push	 eax		; V86 linear address of next device in SIS chain
	 push	 size WIN386_START_STR ; Length we need to inspect
	 call	 V86LIN2WIN	; Get Winlinadr of SIS entry

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em V86LIN2WIN failed and crash

	 mov	 esi,OFFSET32 MSG_VLW5_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 mov	 esi,eax	; Copy to our register

	 jmp	 CSC_NXT	; Loop around again

CSC_XIT_OK:
	 clc			; Indicate there was no overlap found
CSC_XIT:
	 REGREST <esi,edx,ebx,eax> ; Restore caller's registers

	 leave			; Tear down local stack frame

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc CHK_TYPE_2		; End CHK_TYPE_2 procedure

	 page
BeginProc ADD_HIGHDOS_INSTANCE_ITEM ; Instance something in high DOS memory
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Instance an item in high DOS.

ENTRY:
	EDI	==>	List of new instance items being filled in
	EDX	=	V86 linear address of block to be instanced
	ECX	=	Length in bytes to instance

EXIT:
	Carry set if output table is full (Windows 3.0) or VMM service
	failed (Windows 3.10)

|

ifdef @DEBUG
	 call	 SHOW_INSTANCE_ITEM ; Tell 'em about EDX and ECX
endif				; IFDEF @DEBUG

	 cmp	 WIN3_VERSION,030AH ; Izit Windows 3.10?
	 jb	 short @F	; No, do it the old way

	 call	 Add_UMB_Instance_Item_310 ; Do it the new way

	 jmp	 short AHII_XIT ; Rejoin common code

@@:
	 call	 Add_UMB_Instance_Item_300 ; Do it the old way
AHII_XIT:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ADD_HIGHDOS_INSTANCE_ITEM ; End ADD_HIGHDOS_INSTANCE_ITEM procedure

	 page
BeginProc Add_UMB_Instance_Item_300 ; Add new entry to list of instance items
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Instance an item in high DOS.  Windows 3.0 version.

ENTRY:
	EDI	==> List of new instance items being filled in
	EDX	= V86 linear address of block to be instanced
	ECX	= Length in bytes to instance

EXIT:
	CY if output table is full

|

	 REGSAVE <eax,ecx,edx>	; Save caller's registers

	 cmp	 edi,ADDL_INST_Z ; Is our list full?
	 jb	 short @F	; Skip error code if not full yet

	 stc			; Error indicator

	 jmp	 short AHI_XIT	; Join common exit code
@@:
	 mov	 eax,edx	; V86 linear address of area to be instanced
	 shl	 eax,(16-4)	; Form segment in high-order half
AHI_INXT:
	 jecxz	 short AHI_IZ	; Nothing left in this MAC to instance

	 mov	 edx,32768	; Biggest piece we instance
	 cmp	 ecx,edx	; Get MAX(remaining length, 32768)
	 jae	 short @F	; Jump if 32768 bytes or more remain
	 mov	 edx,ecx	; Get remaining size
@@:
	 sub	 ecx,edx	; Get size for next loop

	 mov	 [edi].IIS_PTR,eax ; Fill in address
	 mov	 [edi].IIS_SIZE,dx ; Fill in length field
	 add	 edi,type INSTANCE_ITEM_STR ; Advance to next entry

	 add	 eax,(32768 shl (16-4)) ; Bump address to next 32K piece

	 jmp	 short AHI_INXT ; Loop until entire MAC is instanced
AHI_IZ:
	 clc			; Normal return indicator
AHI_XIT:
	 REGREST <edx,ecx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  Add_UMB_Instance_Item_300 ; End Add_UMB_Instance_Item_300 procedure

	 page
BeginProc Add_UMB_Instance_Item_310 ; Instance something in a UMB for 3.10
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Instance an item in high DOS.  Windows 3.10 version.

ENTRY:
	EDX	= V86 linear address (in highdos) of block to be instanced
	ECX	= Length in bytes to instance

EXIT:
	Carry clear if it worked

|

	 REGSAVE <eax,ecx,edx,edi> ; Save caller's registers

; Allocate space for another InstDataStruc

	 REGSAVE <ecx,edx>	; Save around C call

	 VMMcall _HeapAllocate <<size LCL_INST_STR>, HeapZeroInit>

	 REGREST <edx,ecx>	; Restore input registers

	 or	 eax,eax	; Did we get the space?
	 jnz	 short @F	; Yes, so skip the error code

; Tell 'em HeapAllocate failed and return to caller

	 mov	 esi,OFFSET32 MSG_UHAF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Chain to existing entries

	 mov	 edi,eax	; Pointer to LCL_INST_STR
	 mov	 eax,UMB_INST_ANCHOR ; Get start of chain
	 mov	 [edi].CHAIN,eax ; Attach to new entry
	 mov	 UMB_INST_ANCHOR,edi ; New entry becomes start of chain

; Fill in InstDataStruc

	 sub	 eax,eax	; A handy zero

	 mov	 [edi].IDS.InstLinkF,eax ; Clear out forward pointer
	 mov	 [edi].IDS.InstLinkB,eax ; Clear out back pointer
	 mov	 [edi].IDS.InstLinAddr,edx ; Linaddr of area to be instanced
	 mov	 [edi].IDS.InstSize,ecx ; Length of the area in bytes
	 mov	 [edi].IDS.InstType,ALWAYS_Field ; ALWAYS switch required

; Tell Windows to instance the area

	 lea	 edi,[edi].IDS	; Pointer to InstDataStruc
	 VMMcall _AddInstanceItem <edi, 0> ; Add the low DOS area instance item

	 or	 eax,eax	; Did it work?
	 jnz	 short @F	; Skip error code if it worked

; Tell 'em AddInstanceItem failed and return to caller

	 mov	 esi,OFFSET32 MSG_AUIIF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 clc			; Normal return indicator

	 jmp	 short AUI_XIT	; Join common exit code

AUI_ERRXIT:
	 stc			; Error return indicator
AUI_XIT:
	 REGREST <edi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  Add_UMB_Instance_Item_310 ; End Add_UMB_Instance_Item_310 procedure

	 page
LCL_INST_STR struc		; Structure for local instance chains

CHAIN	 dd	 ?		; Chain to next link or NULL
IDS	 db	 (size InstDataStruc) dup (?) ; Instance of an InstDataStruc

LCL_INST_STR ends		; Endof of LCL_INST_STR structure

BeginProc ADD_LOWDOS_ITEM	; Add new low DOS instance item
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Instance an item in low DOS.

ENTRY:
	EDX	==>	V86 linear address of low DOS area to be instanced
	ECX	=	Length of area to be instanced

EXIT:
	Carry clear if it all worked

|

ifdef @DEBUG
	 call	 SHOW_INSTANCE_ITEM ; Tell 'em about EDX and ECX
endif				; IFDEF @DEBUG

	 REGSAVE <eax,edi>	; Save caller registers

; Allocate space for another InstDataStruc

	 REGSAVE <ecx,edx>	; Save around C call

	 VMMcall _HeapAllocate <<size LCL_INST_STR>, HeapZeroInit>

	 REGREST <edx,ecx>	; Restore input registers

	 or	 eax,eax	; Did we get the space?
	 jnz	 short @F	; Yes, so skip the error code

; Tell 'em HeapAllocate failed and return to caller

	 mov	 esi,OFFSET32 MSG_HAF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Chain to existing entries

	 mov	 edi,eax	; Pointer to LCL_INST_STR
	 mov	 eax,LOW_INST_ANCHOR ; Get start of chain
	 mov	 [edi].CHAIN,eax ; Attach to new entry
	 mov	 LOW_INST_ANCHOR,edi ; New entry becomes start of chain

; Fill in InstDataStruc

	 sub	 eax,eax	; A handy zero

	 mov	 [edi].IDS.InstLinkF,eax ; Clear out forward pointer
	 mov	 [edi].IDS.InstLinkB,eax ; Clear out back pointer
	 mov	 [edi].IDS.InstLinAddr,edx ; Linaddr of area to be instanced
	 mov	 [edi].IDS.InstSize,ecx ; Length of the area in bytes
	 mov	 [edi].IDS.InstType,ALWAYS_Field ; ALWAYS switch required

; Tell Windows to instance the area

	 lea	 edi,[edi].IDS	; Pointer to InstDataStruc
	 VMMcall _AddInstanceItem <edi, 0> ; Add the low DOS area instance item

	 or	 eax,eax	; Did it work?
	 jnz	 short @F	; Skip error code if it worked

; Tell 'em AddInstanceItem failed and return to caller

	 mov	 esi,OFFSET32 MSG_AIIF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 clc			; Normal return indicator
ALDI_XIT:
	 REGREST <edi,eax>	; Restore caller's registers

	 ret			; Return to caller

ALDI_ERRXIT:
	 stc			; Error return indicator

	 jmp	 short ALDI_XIT ; Join common error code

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ADD_LOWDOS_ITEM	; End ADD_LOWDOS_ITEM procedure

	 page
BeginProc MAC_PASS1		; Scan MACs checking against old instance data
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Given the segment of the MAC_OWNER of a region we intend to
	instance in high DOS, check against existing instance regions
	to prevent overlaps.

ENTRY:
	MAC_OWNER = Owner of program being checked

EXIT:
	 Carry clear if we should instance this owner

|

	 REGSAVE <ebx,ecx,edx,esi> ; Save caller's registers

	 movzx	 eax,OVRMAC	; Get segment of 1st UMB MAC entry into EAX

	 shl	 eax,(4-0)	; Convert from paras to bytes
	 mov	 ebx,eax	; Save V86 address of 1st MAC entry
MP1_NXT:
	 push	 ebx		; V86 linear address of MAX entry
	 push	 size LSEG_STR	; Length of LSEG entry
	 call	 V86LIN2WIN	; Do LinToLin assuming our mapping

	 cmp	 eax,-1 	; Did it work?
	 jne	 short @F	; Yes, skip error code

	 stc			; Error indicator

	 jmp	 short MP1_XIT	; Join common exit code
@@:
	 mov	 esi,eax	; Linear address of MAC entry

	 mov	 ax,MAC_OWNER	; Get our owner
	 cmp	 [esi].MAC_OWNR,ax ; Is this owned by our boy?
	 jne	 short MP1_SKP	; No, so skip it

; Scan existing UMB instance items for matches

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes

	 mov	 edx,ebx	; V86 address of this UMB MAC entry
	 add	 edx,type MAC_STR ; Bump past MAC entry header

	 call	 CHK_TYPE_1	; Return CY if type 1 overlaps
	 jc	 short MP1_XIT	; Refuse to instance this one

	 call	 CHK_TYPE_2	; Return CY if type 2 overlaps
	 jc	 short MP1_XIT	; Refuse to instance this one

; Check for the last MAC entry and continue on to the next if appropriate

MP1_SKP:
	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Yes, exit loop

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes
	 add	 ebx,type MAC_STR ; Skip past MAC entry header
	 add	 ebx,ecx	; Bump to next MAC entry

	 jmp	 MP1_NXT	; Continue on to next entry
@@:

	 clc			; OK, let's instance this one
MP1_XIT:
	 REGREST <esi,edx,ecx,ebx> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  MAC_PASS1		; End MAC_PASS1 procedure

	 page
BeginProc MAC_PASS2		; Scan MACs Marking new instance data
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Given the segment of the MAC_OWNER of a region add it to our
	list of high DOS instance items.

ENTRY:
	EDI	==>	Table of instance items being built
	MAC_OWNER =	Owner of program being instanced

EXIT:
	 Carry clear if it all worked

|

	 REGSAVE <ebx,ecx,edx,esi> ; Save caller's registers

	 movzx	 eax,OVRMAC	; Get segment of 1st UMB MAC entry into EAX

	 shl	 eax,(4-0)	; Convert from paras to bytes
	 mov	 ebx,eax	; Save V86 address of 1st MAC entry
MP2_NXT:
	 push	 ebx		; V86 linear address of MAC entry
	 push	 size LSEG_STR	; Length of LSEG entry
	 call	 V86LIN2WIN	; Do LinToLin assuming our mapping

	 cmp	 eax,-1 	; Did it work?
	 jne	 short @F	; Yes, skip error code

	 mov	 esi,OFFSET32 MSG_FTL_AI12 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 esi,eax	; Linear address of MAC entry

	 mov	 ax,MAC_OWNER	; Get our owner
	 cmp	 [esi].MAC_OWNR,ax ; Is this owned by our boy?
	 jne	 short MP2_SKP	; No, so skip it

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes

	 mov	 edx,ebx	; V86 address of MAC entry
	 add	 edx,type MAC_STR ; Bump to actual data of interest

ifdef @DEBUG
	 call	 SHOW_INSTNAME	; Show 'em the program's name
endif				; IFDEF @DEBUG

	 call	 ADD_HIGHDOS_INSTANCE_ITEM ; Instance it in high DOS memory
	 jnc	 short @F	; Skip error code if OK

	 mov	 esi,OFFSET32 MSG_FTL_AI13 ; Text of error message
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

; Check for the last MAC entry and continue on to the next if appropriate

MP2_SKP:
	 cmp	 [esi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Yes, exit loop

	 movzx	 ecx,[esi].MAC_NPAR ; # paragraphs allocated to this entry
	 shl	 ecx,(4-0)	; Convert from paras to bytes
	 add	 ebx,type MAC_STR ; Skip past MAC entry header
	 add	 ebx,ecx	; Bump to next MAC entry

	 jmp	 MP2_NXT	; Continue on to next entry
@@:
	 clc			; Normal return indication
MP2_XIT:
	 REGREST <esi,edx,ecx,ebx> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  MAC_PASS2		; End MAC_PASS2 procedure
	 page
BeginProc FIND_WINA20		; Trundle the device list looking for WINA20
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ecx,esi,edi>	; Save caller's registers

	 cmp	 DOS_VER_H,5	; Running under DOS 5.0 or later?
	 jb	 short FW_XIT	; WINA20.386 is only needed for DOS 5

	 test	 DOS_FLAG,1000h ; Is DOS=HIGH in effect?
	 jz	 short FW_XIT	; WINA20.386 is only need if DOS=HIGH

	 cmp	 WIN3_VERSION,0300h ; Izit Windows 3.0?
	 ja	 short FW_XIT	; WINA20.386 is only needed for Windows 3.0

	 mov	 ecx,DEVICE_LIST ; Return to 1st DDB
FW_NEXT_DEVICE:
	 lea	 edi,[ecx].DDB_Name ; ==> VxDs name

	 push	 ecx		; Save ==> DDB
	 push	 esi		; Save ==> name we're looking for

	 mov	 ecx,8		; Length to compare
	 mov	 esi,OFFSET32 STR_WINA20 ; Name we're looking for

    repe cmpsb			; Compare the names

	 pop	 esi		; Restore ==> name we're looking for
	 pop	 ecx		; Restore ==> DDB

	 je	 short FW_XIT	; We've found the VxD, exit loop

	 mov	 ecx,[ecx].DDB_Next ; Bump to next link

	 jecxz	 short FW_NOT_FOUND ; Exit loop if NULL

	 jmp	 short FW_NEXT_DEVICE ; Go try next device

; Couldn't find the WINA20 device, and we need it

FW_NOT_FOUND:
	 mov	 esi,OFFSET32 MSG_NO_WINA20 ; Offset to message text
	 call	 DISPLAY	; Put text up on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler

FW_XIT:
	 REGREST <edi,esi,ecx>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FIND_WINA20		; End FIND_WINA20 procedure
	 page
BeginProc FIX_DRDOS		; Hook GetSet_HMA_Info for DR-DOS
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	FIX_DRDOS

DESCRIPTION:
	Hook into the GetSet_HMA_Info service to correct the problem with
	the loader data concerned with the state of the A20 line when
	running under DR-DOS 6.0.

|

	 REGSAVE <edx,esi>	; Save caller's registers

	 mov	 edx,REF_LIN			; Linear address of REF_DATA_STR
	 test	 [edx].REF_UPDFLAG,@UPD_DRDOS	; DR-DOS 6.0 in the HMA?
	 jz	 short FIX_DRDOS_XIT		; Exit if not

	 mov	 eax,GetSet_HMA_Info		; ID for service to hook
	 mov	 esi,OFFSET32 LCL_GETSET_HMA_INFO ; Address of local handler
	 VMMcall Hook_Device_Service		; Return old handler in ESI
	 jc	 short FIX_DRDOS_XIT		; Exit if we couldn't hook it

	 mov	 OLD_GETSET_HMA_INFO,esi	; Save address of old handler

FIX_DRDOS_XIT:
	 REGREST <esi,edx>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FIX_DRDOS			; End FIX_DRDOS procedure
ifdef @DEBUG
	 page
BeginProc SHOW_INSTANCE_ITEM	; Display address and length of instance item
COMMENT|

For debugging purposes, display the address and length of an instance region

Input:
	EDX	=	Address of instance region
	ECX	=	Length of instance region

|

	 pushad 		; Save all EGP registers

	 push	 ecx		; Save length

	 mov	 eax,edx	; Address of instance region

	 lea	 edi,MSG_INST0 ; Place to stick ASCII HEX digits
	 mov	 ecx,5		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 pop	 ecx		; Restore length

	 mov	 eax,ecx	; Length of instance region

	 lea	 edi,MSG_INST1 ; Place to stick ASCII HEX digits
	 mov	 ecx,5		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 esi,OFFSET32 MSG_INST ; Offset to message text
	 call	 DISPLAY	; Put text up on debugging screen

	 popad			; Restore all EGP registers

	 ret

EndProc  SHOW_INSTANCE_ITEM	; End SHOW_INSTANCE_ITEM procedure
	 page
BeginProc SHOW_INSTANCE_DEVICE	; Display address and length of instanced DEV
COMMENT|

For debugging purposes, display the address and length of an instanced device

Input:
	EDX	=	Address of instance region
	EAX	=	Length of instance region

|

	 pushad 		; Save all EGP registers

	 push	 eax		; Save length

	 mov	 eax,edx	; Address of instance region

	 lea	 edi,MSG_INST_DEV0 ; Place to stick ASCII HEX digits
	 mov	 ecx,5		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 pop	 eax		; Restore length

	 lea	 edi,MSG_INST_DEV1 ; Place to stick ASCII HEX digits
	 mov	 ecx,5		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 esi,OFFSET32 MSG_INST_DEV ; Offset to message text
	 call	 DISPLAY	; Put text up on debugging screen

	 popad			; Restore all EGP registers

	 ret

EndProc  SHOW_INSTANCE_DEVICE	; End SHOW_INSTANCE_DEVICE procedure
	 page
BeginProc SHOW_INSTNAME 	; Display name of program to be instanced
COMMENT|

For debugging purposes, display the address and length of an instanced device

Input:
	CULLNAME_PTR ==>	Name
	CULLNAME_LEN =		Length of name

|

	 pushad 		; Save all EGP registers

; Copy name into message text

	 mov	 edi,OFFSET32 MSG_INST_NAME0 ; ==> place for name in message
	 mov	 esi,CULLNAME_PTR ; ==> name
	 mov	 ecx,CULLNAME_LEN ; Length of name

	 cmp	 ecx,8+1+3	; Izit longer than we can fit?
	 jbe	 short @F	; Nope

	 mov	 ecx,8+1+3	; Limit names to 12 bytes
@@:

     rep movsb			; Copy name in

	 mov	 al,CR		; Store a CR after the name
	 stosb			; ...

	 mov	 al,LF		; Store a LF
	 stosb			; ...

	 sub	 al,al		; Store a terminating NUL
	 stosb			; ...

	 mov	 esi,OFFSET32 MSG_INST_NAME ; Offset to message text
	 call	 DISPLAY	; Put text up on debugging screen

	 popad			; Restore all EGP registers

	 ret

EndProc  SHOW_INSTNAME			; End SHOW_INSTNAME procedure
endif					; IFDEF @DEBUG

VxD_ICODE_ENDS				; End _ITEXT segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 GET_SYSTEM_OPTION:near ; VMAX_FNS

	 extrn	 PHYS2LIN:near		; VMAX_FNS
	 extrn	 P2LERROR:near		; VMAX_FNS
	 extrn	 V86LIN2WIN:near	; VMAX_FNS

	 extrn	 CHK_CFG_FLAG:near	; VMAX_FNS
	 extrn	 CMPSBI:near		; VMAX_FNS
	 extrn	 CONSUME:near		; VMAX_FNS
	 extrn	 FIND_ENV_PGM:near	; VMAX_FNS
	 extrn	 ISWHITE:near		; VMAX_FNS
	 extrn	 SKIPWHITE:near 	; VMAX_FNS
	 extrn	 TOKENIZE:near		; VMAX_FNS

	 extrn	 ProcessPageInMonoDispArea:near ; In LoadHi.OBJ
	 extrn	 PAGEFAULT_V86:near, PAGEFAULT_PM:near
	 extrn	 XUPD_CHECK_WIN:near

ifdef @VGASWAP
	 extrn	 UNHOOK_VDD:near
endif				; IFDEF @VGASWAP

	 extrn	 DISPLAY:near		; VMAX_DBG.ASM
	 extrn	 TOHEX:near		; VMAX_DBG.ASM

	 extrn	 V86_API:near		; VMAX_API.ASM
	 extrn	 PM_API:near		; VMAX_API.ASM
	 extrn	 QMAX_HELPER:near	; VMAX_API.ASM

ifdef @DOSMAX
	 extrn	 DOSMAX_CREATEVM:near
	 extrn	 DOSMAX_DESTROYVM:near
	 extrn	 DOSMAX_VMNOTEXECUTEABLE:near
	 extrn	 DOSMAX_SYSTEMEXIT:near
endif					; IFDEF @DOSMAX

BeginProc VMAX_SYS_VM_INIT		; Handler for Sys_VM_Init device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Same as VM_Init, except for SYS VM.

	Free up heap space used for low DOS and UMB instancing.

ENTRY:
	EBX	=	Handle of System Virtual Machine

EXIT:
	Carry clear if no error

|

	 BREAK	 DBG_FLAG,@DBG_SYSVMINIT ; Break if 386MAXSysVMInit

	 or	 PMI_FLAG,@PMI_SYSVM	; Remember Sys_VM_Init has occurred

; Free up heap space used for low DOS instancing

	 mov	 esi,LOW_INST_ANCHOR ; Get start of chain
	 call	 FREE_LCL_ITEMS ; Trundle through chain freeing structs

; Free up heap space used for UMB instancing

	 mov	 esi,UMB_INST_ANCHOR ; Get start of chain
	 call	 FREE_LCL_ITEMS ; Trundle through chain freeing structs

	 clc			; Clear error return indicator

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_SYS_VM_INIT	; End VMAX_SYS_VM_INIT procedure
	 page
BeginProc VMAX_VM_NOT_EXECUTEABLE ; Handler for VM_Not_Executeable device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Second phase of Destroy_VM.  EBX = VM Handle, EDX = Flags.
	Note that in the case of destroying a running VM, this is
	the first call made (VM_Terminate call does not occur).
	Call cannot be failed.	VM Simulate_Int, Exec_Int activity is
	NOT allowed.

ENTRY:
	EBX=	Handle of VM being terminated
	EDX =	Flags

EXIT:
	Carry clear if no error

|

ifdef @DOSMAX
	 call	 DOSMAX_VMNOTEXECUTEABLE ; DOSMAX related processing
endif					; ENDIF @DOSMAX

	 clc			; Normal exit indicator

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_VM_NOT_EXECUTEABLE ; End VMAX_VM_NOT_EXECUTEABLE procedure
	 page
BeginProc VMAX_DESTROY_VM	; Handler for Destroy_VM device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Final phase of Destroy_VM.  EBX = VM Handle.
	Note that considerable time can elaps between the
	VM_Not_Executeable call and this call.	Call cannot
	be failed.  VM Simulate_Int, Exec_Int activity is NOT allowed.

ENTRY:
	EBX	=	Handle of VM being terminated

EXIT:
	Carry clear if no error

|

ifdef @DOSMAX
	 call	 DOSMAX_DESTROYVM	; DOSMAX related Destroy_VM processing
endif					; ENDIF @DOSMAX

	 clc				; Normal exit indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_DESTROY_VM		; End VMAX_DESTROY_VM procedure

	 page
BeginProc VMAX_CREATE_VM		; Handler for Create_VM device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Create_VM creates a new VM.
	EBX = VM handle of new VM.
	Returning Carry will fail the Create_VM.

	The cached ROMs are reattached during this call.

	The DDK doc claims this isn't needed, but Aaron Reynolds
	said to do it anyway.

Entry:
	EBX	=	Handle of VM being created

Exit:
	Carry clear if no error

|

	 BREAK	 DBG_FLAG,@DBG_CREATEVM ; Break if 386MAXCreateVM

	 call	 CACHE_ROMS	; Connect the cached ROMs - Return CY if error

ifdef @DOSMAX
	 call	 DOSMAX_CREATEVM	; DOSMAX related Create_VM processing
endif					; ENDIF @DOSMAX

	 clc				; Normal exit indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_CREATE_VM 		; End VMAX_CREATE_VM procedure
if 0
	 page
BeginProc VMAX_VM_INIT			; Handler for VM_Init device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Third phase of Create_VM.
	EBX = VM handle of new VM.

	Returning Carry will cause the VM to go Not_Executeable,
	then be destroyed.

	VM Simulate_Int and Exec_Int activity is allowed.

ENTRY:
	EBX	=	Handle of VM being terminated

EXIT:
	Carry clear if no error

|

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_VM_INIT			; End VMAX_VM_INIT procedure
endif					; IF 0
	 page
BeginProc CACHE_ROMS		; Connect the cached ROMs to a VM
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Hook up cached ROMs to a virtual machine.

	Connect the cached ROMs using the PhysIntoV86 VMM service.
	Use the ModifyPageBit VMM service to clear the R/W bit.

	Note the Windows 3.10 debug WIN386.EXE will bitch ad nauseum
	while these calls are being made.  A debug trap will also
	occur for each call.  Aaron must keep control of his baby.

|

	 REGSAVE <eax,ebx,ecx,edx>	; Save caller's registers

	 mov	 ecx,384/4	; # of 4K pages in the top 384K
	 sub	 edx,edx	; Bitmap bit # corresponding to A0h page
CR_PAGE_NXT:
	 bt	 ROM_BMP,edx	; Test bit for this ROM page
	 jnc	 short CR_PAGE_SKIP ; Jump if this page isn't cached

	 push	 ecx		; Save loop counter around VMM calls
	 push	 edx		; Save ROM bitmap index

	 add	 edx,0A0h	; Convert bitmap index to V86 page #

	 mov	 eax,PDIR_LIN	; Get linear address of 386MAX's PTEs
	 mov	 eax,[eax+edx*4] ; Get PTE for page of interest
	 shr	 eax,(12-0)	; Isolate and convert to physical page #

; EAX = physical page #
; EDX = V86 page #
; EBX = VM handle

	 push	 edx		; Save V86 page # around VMM call

	 VMMcall _PhysIntoV86 <eax, ebx, edx, 1, 0>

	 pop	 edx		; Restore V86 page #

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em PhysIntoV86 failed and return to LoadHi VxD

	 mov	 esi,OFFSET32 MSG_PIV3_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 jmp	 short CR_ERRXIT ; Join common error return code
@@:

; Mark the PTE R/O

	 VMMcall _ModifyPageBits <ebx, edx, 1, <not P_WRITE>, 0, PG_IGNORE, 0>

	 or	 eax,eax	; Test return code
	 jnz	 short @F	; Jump around error code if OK

; Tell 'em ModifyPageBits failed and return to LoadHi VxD

	 mov	 esi,OFFSET32 MSG_MPB2_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 pop	 edx		; Restore ROM bitmap index
	 pop	 ecx		; Restore loop counter

	 jmp	 short CR_ERRXIT ; Join common error return code
@@:

; Continue on with next page

	 pop	 edx		; Restore ROM bitmap index
	 pop	 ecx		; Restore loop counter
CR_PAGE_SKIP:
	 inc	 edx		; Bump to next page

;;;;;;	 loop	 CR_PAGE_NXT	; Loop for each entry in bitmap (384/4) in all
	 dec	 ecx		; Account for entry just examined
	 jecxz	 short @F	; Exit loop if done
	 jmp	 CR_PAGE_NXT	; Loop on to next entry
@@:
	 clc			; Normal return indicator

	 jmp	 short CR_XIT	; Rejoin common exit code

CR_ERRXIT:
	 stc			; Error return indicator
CR_XIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CACHE_ROMS		; End CACHE_ROMS procedure
	 page
BeginProc REST_PnP
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Restore PnP struc in BIOS

|

	REGSAVE <eax,ebx,edx,edi>	; Save registers

	mov	edx,REF_LIN		; EDX ==> reference data structure

	cmp	[edx].REF_STRUC_VER,800h ; Izit PnP, or newer?
	jb	short REST_PnP_EXIT    ; Jump if not

	movzx	edi,[edx].REF_PnP_SEG	; Get PnP struc segment in BIOS
	shl	edi,4-0 		; Convert from paras to bytes
	jz	short REST_PnP_EXIT	; Jump if not present

	mov	eax,OLD_PnP_PMCS	; Get original value
	mov	ebx,OffPnP_PMCS 	; Get offset to PnP_PMCS
	mov	[edi+ebx],eax		; Save in PnP struc in BIOS

	cmp	[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F		; Jump if not (no PMDS in old struc)

	mov	eax,OLD_PnP_PMDS	; Get original value
	mov	[edi].PnP_PMDS,eax	; Save in PnP struc in BIOS
@@:

; Re-calculate the PnP checksum

	call	CALC_PnPSUM		; Re-calculate it
REST_PnP_EXIT:
	REGREST <edi,edx,ebx,eax>	; Restore

	ret				; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc REST_PnP			; End REST_PnP procedure
	page
BeginProc CALC_PnPSUM
	assume	ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Re-calculate the PnP checksum

On entry:

EDI	=	linear address of PnP struc in BIOS

|

	REGSAVE <eax,ecx,esi>		; Save registers

	movzx	ecx,[edi].PnP_LEN	; Get # bytes in the struc
	mov	ah,0			; Initialize the checksum
	mov	esi,edi 		; AGROUP:ESI ==> start of PnP struc
@@:
	lods	[esi].LO		; Get next byte
	add	ah,al			; Accumulate in checksum

	loop	@B			; Jump if more bytes to checksum

	sub	[edi].PnP_SUM,ah	; Save as new checksum

	REGREST <esi,ecx,eax>		; Restore

	ret				; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc CALC_PnPSUM			; End CALC_PnPSUM procedure
	 page
BeginProc VMAX_SYSTEM_EXIT	; Handler for System_Exit device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	System_Exit call is made when WIN386 is exiting either
	normally or via a crash.  INTERRUPS ARE ENABLED.
	The instance snapshot has been restored.
	SYS VM Simulate_Int, Exec_Int ACTIVITY IS NOT ALLOWED.

	We remove our hooks into the VDD during this call.

|

	 BREAK	 DBG_FLAG,@DBG_SYSEXIT ; Break if 386MAXSystemExit

ifdef @VGASWAP
	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_VGASWAP ; Is FLEXROM in effect?
	 jz	 short @F	; Nope

	 call	 UNHOOK_VDD	; Hook into things to support FLEXROM
@@:
endif				; IFDEF @VGASWAP

	call	REST_PnP	; Unpatch PnP struc in BIOS

ifdef @DOSMAX
	 call	 DOSMAX_SYSTEMEXIT	; Termination for DOSMAX
	 jc	 short VSE_XIT		; Pass CY along to WIN386
endif					; IFDEF @DOSMAX
	 clc			; Clear error return indicator

VSE_XIT:
	 ret			; Return to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_SYSTEM_EXIT	; End VMAX_SYSTEM_EXIT procedure

	 page
BeginProc VMAX_SYS_CRITICAL_EXIT ; Handler for Sys_Critical_Exit device call
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Sys_Critical_Exit call is made when WIN386 is exiting
	either normally or via a crash.   INTERRUPS ARE DISABLED.
	SYS VM Simulate_Int, Exec_Int ACTIVITY IS NOT ALLOWED.

	We unpatch QMAX.SYS's CHECK_WIN procedure during this call.

|

	 BREAK	 DBG_FLAG,@DBG_SYSCRITEXIT ; Break if 386MAXSysCriticalExit

	 call	 XUPD_CHECK_WIN ; Unpatch CHECK_WIN in QMAX_XMS.ASM

	call	REST_PnP	; Unpatch PnP struc in BIOS

	 clc				; Clear error return indicator

	 ret				; Return to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  VMAX_SYS_CRITICAL_EXIT ; End VMAX_SYS_CRITICAL_EXIT procedure

	 page
BeginProc FREE_LCL_ITEMS	; Trundle through chain freeing structs
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Free the locally allocated structures used to add
	instance items.  There are two chains; this is a subroutine
	used for both.

ENTRY:
	ESI ==> head of the chain we're freeing.

|

	 REGSAVE <eax,ecx,edx,esi> ; Save caller's registers

FLDI_NXT:
	 or	 esi,esi	; Is it the end of the list?
	 jz	 short FLDI_XIT ; Yes, exit the loop

	 mov	 eax,esi	; Copy chain pointer to be freed
	 mov	 esi,[esi].CHAIN ; Get pointer to next link

	 VMMcall _HeapFree <eax, 0> ; Free next link in chain

	 or	 eax,eax	; Did it work?
	 jnz	 short @F	; Yes, so skip error code

; Tell 'em HeapFree failed

	 mov	 esi,OFFSET32 MSG_HFF_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen
@@:
	 jmp	 short FLDI_NXT ; No, go back for more
FLDI_XIT:
	 REGREST <esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FREE_LCL_ITEMS 	; End FREE_LCL_ITEMS procedure
ifdef @VGASWAP
	 page
BeginProc CHK_FLEX_IO		; Check UMB page for FLEXROM memory-mapped I/O
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Given a UMB page # in EAX, check the FLEXROM table to see if it
	is memory-mapped I/O.

Entry:
	EAX	=	UMB page number

Exit:
	Carry set if UMB page is memory-mapped I/O

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

; Loop through the FLEXROM table, looking for our page

	 mov	 esi,FLEXROM_LIN ; Pointer to FLEXROM table

	 movzx	 ecx,FLEXROM_CNT ; Number of entries in the FLEXROM table
	 jecxz	 short CFI_XITCLC ; Exit if nothing is FLEXed

CFI_NXTENT:
	 movzx	 edx,[esi].FLEX_DST ; FLEXed ROM destination segment
	 shr	 edx,(12-4)	; Convert from segment to page #

	 cmp	 eax,edx	; Is our page below the start of this FLEXed ROM
	 jb	 short CFI_LP	; Yes, so it's not an I/O page

	 movzx	 edi,[esi].FLEX_LEN ; Get length (in bytes) of FLEXed ROM
	 shr	 edi,(12-0)	; Convert from bytes to pages
	 add	 edi,edx	; Page # just past this FLEXed ROM

	 cmp	 eax,edi	; Is our page above the end of this ROM?
	 jae	 short CFI_LP	; Yes, so it's not an I/O page

; Our UMB page is within this FLEXed ROM
; Check the FLEX_MAP for an I/O page

	 sub	 edx,eax	; Page offset with this ROM
	 neg	 edx		; ...
	 bt	 [esi].FLEX_MAP,dx ; Is this page one of the special ones?
	 jc	 short CFI_XIT	; Exit if so, carry is set

; Try all the FLEXed ROMS

CFI_LP:
	 add	 esi,size FLEXROM_STR ; Advance to next entry in FLEXROM table

	 loop	 CFI_NXTENT	; Look in all the entries

CFI_XITCLC:
	 clc			; Normal return indicator
CFI_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CHK_FLEX_IO		; End CHK_FLEX_IO procedure
endif				; IFDEF @VGASWAP
	 page
BeginProc LCL_GETSET_HMA_INFO	; Local handler for GetSet_HMA_Info
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	On input to GetSet_HMA_Info, ECX=0 if it's the 'get' call.
	Call the original service.  If the A20 enable count (EDX) comes
	back 0, return EDX=1 to the caller.  Otherwise pass EDX along unchanged.

	If ECX != 0 on input, simply chain on to the original service.

|

	 cmp	 ecx,0			; 'Get' or 'set'?
	 jne	 short LCL_GSHI_PASS	; Jump to original handler if 'set'

	 call	 OLD_GETSET_HMA_INFO	; Call the original

	 cmp	 edx,0			; Is the A20 enable count 0?
	 jne	 short LCL_GSHI_XIT	; Pass along A20 count as-is if not

; The WIN386 loader data incorrectly reports the A20 enable count to be 0
; We know it should be 1 since DR-DOS is in the HMA.

	 mov	 edx,1			; Correct A20 enable count

	 jmp	 short LCL_GSHI_XIT	; Pass along corrected A20 count

; Pass the call on to the original handler

LCL_GSHI_PASS:
	 jmp	 OLD_GETSET_HMA_INFO	; Call the original

LCL_GSHI_XIT:
	 ret			; Return to caller of GetSet_HMA_Info service

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_GETSET_HMA_INFO	; End LCL_GETSET_HMA_INFO procedure
	 page
BeginProc V86_INT21			; Handler for V86 INT 21h
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	V86 INT 21h hook.

    DOSMGR:
	Check for 5802/5803 calls from DOSMGR(1).
	Send 'em down to 386MAX via EMM2_GSLINK58.
	Disable further activity.
	Return carry clear to avoid the next handler in the chain.

Entry:
	EAX =	Interrupt # (21h)
	EBX =	VM Handle
	EBP ==> Client register structure

Exit:
	Carry set if interrupt not serviced

|

	 cmp	 [ebp].Client_AH,58h	; Is it memory allocation strategy?
	 jne	 V86_INT21_STC		; Chain to next handler if not

	 cmp	 [ebp].Client_AL,01h	; Is it 5802h or 5803h?
	 jbe	 V86_INT21_STC		; Chain to next handler if not

	 test	 PMI_FLAG,@PMI_INITCOMP ; Init_Complete been by yet?
	 jnz	 V86_INT21_STC		; Chain to next handler if so

; Process call before Init_Complete time, presumably from DOSMGR(1)

	 REGSAVE <eax,ebx,edx>		; Save caller's registers

	 mov	 al,[ebp].Client_AL	; Pick up 02/03
	 sub	 al,2			; Convert to 0 bias for EMM2 call

	 mov	 bx,[ebp].Client_BX	; Trash for 5802, link state for 5803

	 Push_Client_State		; Save client's register structure

	 REGSAVE <ds,fs,gs>		; Save caller's registers

	 mov	 dx,ds			; Get addressibility
	 mov	 fs,dx			; ... via FS
	 mov	 gs,dx			; ... via GS
	 assume  fs:FLAT, gs:nothing	; Tell the assembler

	 mov	 [ebp].Client_AH,@EMM2_GSLINK58 ; Get/Set 5803 link state
	 mov	 [ebp].Client_AL,al	; 0 for 5802, 1 for 5803

	 mov	 [ebp].Client_BX,bx	; Trash for 5802, link state for 5803

	 mov	 edx,REF_LIN		; Linear address of REF_STR

	 mov	 ds,PGROUP_DS		; Get DS for use by 386MAX UTIL code
	 assume  ds:nothing		; Tell the assembler

	 call	 lpfnUTL_VXD2MAX	; Call 386MAX UTIL code

	 mov	 ah,[ebp].Client_AH	; Error code from EMM2 call
	 sub	 al,al			; Assume no carry on return from INT 21h

	 mov	 bl,[ebp].Client_BL	; Returned 5802 link state

	 REGREST <gs,fs,ds>		; Restore caller's registers
	 assume  ds:FLAT, fs:nothing, gs:nothing

	 Pop_Client_State		; Restore client's register structure

	 or	 ah,ah			; Did the EMM2 call succeed?
	 jnz	 short @F		; Don't change client registers if not

	 and	 [ebp].Client_Flags,not (mask $CF) ; Kill carry
	 or	 [ebp].Client_Flags.LO,al ; Set carry if error from EMM2 call

	 mov	 [ebp].Client_AL,bl	; Returned 5802 link state
@@:
	 or	 ah,ah			; Did the EMM2 call succeed?
					; Zero flag crosses the POPs
	 REGREST <edx,ebx,eax>		; Restore caller's registers
	 jnz	 V86_INT21_STC		; Chain to next handler if EMM2 failed

	 clc				; Indicate we serviced the INT 21h

	 jmp	 short V86_INT21_EXIT	; Rejoin common exit code

V86_INT21_STC:
	 stc				; Chain to the next V86 handler

V86_INT21_EXIT:
	 ret				; Return to WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86_INT21			; End V86_INT21 procedure

VxD_CODE_ENDS				; End _TEXT segment

	 end				; End VMAX module
