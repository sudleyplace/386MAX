;'$Header:   P:/PVCS/MAX/VXD/VMAX_SVM.ASV   1.4   22 Mar 1996 16:46:12   BOB  $
	 title	 VMAX_SVM -- DOSMAX Related Routines
	 page	 78,130
	 name	 VMAX_SVM

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1992-96 Qualitas, Inc.  All rights reserved.

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

Original code by:  William R. Lewis, September, 1992.

Modifications by:  None.

    Complete documentation on how this all works is found in DOSMAX.TXT.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
	 include DOSMGR.INC
	 include SHELL.INC
	 include VDD.INC

	 include MASM.INC	; From the standard Qualitas include library
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include OPCODES.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include MAC.INC

	 include QMAX_DTE.INC		; From the 386MAX.SYS source code
	 include QMAX_STK.INC
	 include QMAXWIN3.INC

	 include BREAK.INC
	 include VMAX.INC
	 include VMAX_SVM.INC
	 include VMAX_UPD.INC
	 include VMAXAPI.INC

	 include WFW.INC		; Homemade include for WFW VxDs

	 include QPE.INC		; Built using H2INC conversion of QPE.H
					; as a guide
.list
	 page
VxD_IDATA_SEG				; Begin _IDATA segment

	 extrn	 STR_QUALITAS:byte	; VMAX.ASM

ifdef @DEBUG
	 extrn	 MSG_DOSMAX:byte
endif				; IFDEF @DEBUG

ifdef @DOSMAX
	 public  STR_DOSMAX, STR_DOSMAXFONTS, STR_DOSMAXDEF, STR_DOSMAXMONO
	 public  STR_DOSMAXBREAK, STR_DOSMAXJUGGLE
STR_DOSMAX	 db	'DOSMAX', 0             ; Turns the entire apparatus OFF
STR_DOSMAXFONTS  db	'DOSMAXFonts', 0        ; Enables font load translations
STR_DOSMAXDEF	 db	'DOSMAXDefault', 0      ; Makes every VM a DOSMAX VM
STR_DOSMAXMONO	 db	'DOSMAXMono', 0         ; Disable use of B000-B7FF
STR_DOSMAXBREAK  db	'DOSMAXBreak', 0        ; Enables various INT 1s
STR_DOSMAXJUGGLE db	'DOSMAXJuggle', 0       ; Disable INT 10h juggling
endif					; IFDEF @DOSMAX

VxD_IDATA_ENDS				; End _IDATA segment
	 page
VxD_DATA_SEG				; Begin _DATA segment

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 include VMAX_PMI.INC
	 extrn	 PMI_FLAG:word

	 extrn	 ROM_BMP:dword		; VMAX.ASM
	 extrn	 ASSIGN_BMP:dword	; VMAX.ASM
	 extrn	 HIGHDOS_MAP:dword	; VMAX.ASM

	 extrn	 DEV_CB_LEN:dword
	 extrn	 DEV_CB_OFFSET:dword

	 extrn	 ARENA_ANCHOR:word
	 extrn	 OVRMAC:word

ifdef @DOSMAX
	 extrn	 MSG_NOQPOPUP_CAPTION:byte, MSG_NOQPOPUP_TEXT:byte

	 extrn	 LaDSTK_TAB:dword
	 extrn	 DSTK_CNT:dword
	 extrn	 PDSTKCOM:dword
	 extrn	 WIN3_VERSION:word

	public	CreateVMHandle
CreateVMHandle dd ?			; Handle of VM being created

	 public  SVM_FLAG
SVM_FLAG dw	 0			; Flags for DOSMAX apparatus

	 public  DOSMAX_PERVMOFF
DOSMAX_PERVMOFF dd	0		; Offset to DOSMAX per VM data

	 public  SVM_MAX_PAGES_B0
SVM_MAX_PAGES_B0 dd	?		; Max # of pages in B0-B7 region for SVM

	 public  OLD_HOOK_V86_PAGE, OLD_DOSMGR_EXEC_VM, OLD_VDD_PIF_STATE
OLD_HOOK_V86_PAGE	dd	?	; Offset to original Hook_V86_Page svc
OLD_DOSMGR_EXEC_VM	dd	?	; Offset to original _DOSMGR_Exec_VM svc
OLD_VDD_PIF_STATE	dd	?	; Offset to original VDD_PIF_State svc

	 public  OLD_COPY_PAGE_TABLE
OLD_COPY_PAGE_TABLE	dd	?	; Offset to original _CopyPageTable svc

	 public  DOSMGR_CALLER
DOSMGR_CALLER	 dd	?		; DOSMGR_EXEC_VM caller's return address

	public	OLD_AGV86DA
OLD_AGV86DA dd	?			; Allocate_Global_V86_Data_Area return address

	 public  OLD_VDD_PF_HOOK
OLD_VDD_PF_HOOK  dd	?		; Offset to original VDD_PFault proc

	 public  VDD_PF_PAGE
VDD_PF_PAGE	 dd	?		; Page # of last VDD page fault

	 public  PIF_HANDLE
PIF_HANDLE	 dw	?		; File handle for .QPE file

	 public  NUL_PAGE_PTE
NUL_PAGE_PTE	 dd	?		; PTE for the NUL page

	 public  DOSUMB_MAC
DOSUMB_MAC	 dw	0		; Segment of DOS=UMB spanning entry

	 public  DOSMAX
DOSMAX	 dw	 ?			; Requested VM size from .QPE file
					; Always greater than 640K

	 public  szPIFName, szDefaultQPE, sz_DefaultQPE
szPIFName	 db	80 dup (?)	; Buffer to hold .QPE filename
szDefaultQPE	 db	80 dup (0)	; Holds 'd:\path\_default.qpe',0
sz_DefaultQPE	 db	'_DEFAULT.QPE', 0
cb_DefaultQPE	 equ	$-sz_DefaultQPE ; Length of above string

@GLOBV86_SIZE	 equ	(type QPE_STR)	; Big enough to hold .QPE structure

	 public  GLOBAL_V86_LIN, GLOBAL_V86_VEC
GLOBAL_V86_LIN	 dd	?		; Linear address to global data area
GLOBAL_V86_VEC	 dd	?		; V86 FAR PTR to global data area

@XLATFONT_SIZE	 equ	 (256*10h)	; 4K

	 public  XLATFONT_V86_LIN, XLATFONT_V86_VEC
XLATFONT_V86_LIN dd	?		; Linear address to font data area
XLATFONT_V86_VEC dd	?		; V86 FAR PTR to font data area

@WINOLDAP_PIFNAME	equ	04B8h	; Offset to .PIF filename in WINOLDAP

	 public  OLD_INT10, NEW_INT10, INT10_STUB_ADDR
OLD_INT10	 dd	?		; Previous V86 INT 10h vector
NEW_INT10	 dd	0		; New	   V86 INT 10h vector
INT10_STUB_ADDR  dd	?		; Linear address of downstairs stub
INT10_STUB_VEC	 dd	?		; Seg:off of ...

	 public  QPOPUP_CALLBACK
QPOPUP_CALLBACK  df	0		; FAR PTR to QPOPUP.EXE's callback

	 public  EXEC_NAME, EXEC_NAMEL
EXEC_NAME	 dd	?		; ==> to filename.ext in V86 buffer
EXEC_NAMEL	 dd	?		; strlen() of EXEC_NAME

	 public  INTERCEPTS_LIN
INTERCEPTS_LIN	 dd	0		; ==> filename intercepts

; Message text for short DOSMAX setup
	 public  MSG_CAP_SHORT
ifdef LANG_GR
MSG_CAP_SHORT	 db	'386MAX.VXD -- kann DOSMAX Funktionen nicht bereitstellen', 0
else
MSG_CAP_SHORT	 db	'386MAX.VXD -- Unable to provide DOSMAX features', 0
endif				; IFDEF LANG_GR

	 public  MSG_TXT_SHORT
MSG_TXT_SHORT	 label	byte
ifdef LANG_GR
	 db  'DOSMAX hat entdeckt, da· Ihr System weniger als 640K '
	 db  'konventionellen Speicher enthÑlt. Da die obere Grenze des '
	 db  'konv. Speichers nicht an der Untergrenze des Grafikspeichers '
	 db  'liegt (wie bei 640 KB-Systemen), sind DOSMAX-Funktionen '
	 db  'nicht verfÅgbar.', 0
else
	 db	 'DOSMAX has detected your system has less than 640K '
	 db	 'conventional memory.  Because the top of conventional memory '
	 db	 'does not correspond to the bottom of graphics memory '
	 db	 '(as it does on a system with 640K) DOSMAX features are '
	 db	 'unavailable.', 0
endif				; IFDEF LANG_GR

; Message text for QPE file DOS trouble
	 public  MSG_CAP_BADQPE
ifdef LANG_GR
MSG_CAP_BADQPE	 db	'386MAX.VXD -- kann .QPE Datei nicht benutzen', 0
else
MSG_CAP_BADQPE	 db	'386MAX.VXD -- Unable to use .QPE File', 0
endif				; IFDEF LANG_GR

	 public  MSG_TXT_BADQPEREAD, MSG_TXT_BADQPELEN
MSG_TXT_BADQPEREAD	label	byte
ifdef LANG_GR
	 db	 'Kann die .QPE Datei zum entsprechenden .PIF'
	 db	 'fÅr diese Anwendung nicht lesen', 0
else
	 db	 'Cannot read the .QPE file corresponding to the .PIF'
	 db	 'for this application', 0
endif				; IFDEF LANG_GR

MSG_TXT_BADQPELEN	label	byte
ifdef LANG_GR
	 db	 'Die .QPE Datei zum entsprechenden .PIF fÅr diese '
	 db	 'Anwendung ist beschÑdigt', 0
else
	 db	 'The .QPE file corresponding to the .PIF for this '
	 db	 'application is corrupted', 0
endif				; IFDEF LANG_GR

MSG_TXT_BADQPEMAGIC	label	byte
ifdef LANG_GR
	 db	 'Die .QPE Datei zum entsprechenden .PIF fÅr diese '
	 db	 'Anwendung ist beschÑdigt', 0
else
	 db	 'The .QPE file corresponding to the .PIF for this '
	 db	 'application is corrupted', 0
endif				; IFDEF LANG_GR

MSG_TXT_BADQPEVER	label	byte
ifdef LANG_GR
	 db	 'Die .QPE Datei zum entsprechenden .PIF fÅr diese '
	 db	 'Anwendung ist eine veraltete Version', 0
else
	 db	 'The .QPE file corresponding to the .PIF for this '
	 db	 'application is of an obsolete version', 0
endif				; IFDEF LANG_GR

	public	STR_PROPDLL,STR_PROPEXT
STR_PROPDLL	 db	'PIFMGR.DLL', 0         ; Property group DLL
STR_PROPEXT	 db	'DOSMAX', 0             ; Property group extension

endif					; IFDEF @DOSMAX

VxD_DATA_ENDS				; End _DATA segment
	 page
VxD_ICODE_SEG				; Begin _ITEXT segment
	 assume  cs:FLAT		; Tell the assembler

ifdef @DOSMAX
BeginProc DOSMAX_SHORT			; Tell DOSMAX low DOS is short
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|
	Tell DOSMAX low DOS is short.
|

	 or	 SVM_FLAG,@SVM_SHORT	; DOSMAX is off due to short low DOS
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_SHORT			; End DOSMAX_SHORT procedure
	 page
BeginProc DOSMAX_FINDSPAN		; Find the DOS=UMB spanning entry
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Find the DOS=UMB spanning entry.

|

	 REGSAVE <eax,ebx,edx,esi>	; Save caller's registers

	 VMMcall Get_Sys_VM_Handle	; ... into EBX

; Find the DOS=UMB spanning entry

	 mov	 esi,[ebx+CB_High_Linear] ; ESI ==> VMs address space
	 mov	 ax,ARENA_ANCHOR	; Segment of 1st MAC entry
	 sub	 dx,dx			; Clear in case the arena is trashed
DMCH_NXTMAC:
	 movzx	 ebx,ax 		; Segment of MAC entry
	 shl	 ebx,(4-0)		; Convert from paras to linear address

	 inc	 ax			; Bump segment to actual block

	 cmp	 [esi+ebx].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short DMCH_ZMAC	; Exit loop if so

	 cmp	 [esi+ebx].MAC_TYPE,@MAC_MID ; Middle entry?
	 je	 short @F		; Skip error code if so

	 BREAK	 DMCH_ArenaTrashed	; Call the debugger
	 jmp	 short DMCH_SHORT	; If the arena is trashed, make it SHORT
@@:
	 add	 ax,[esi+ebx].MAC_NPAR	; Bump AX to segment of next MAC entry

	 jmp	 short DMCH_NXTMAC	; Continue on to next entry

DMCH_ZMAC:

; AX = segment of Z MAC entry's data block, EBX = linear address
; If the Z entry points to another M or Z entry that has an owner of 8,
; it is the DOS=UMB spanning entry.

	 mov	 dx,ax			; Segment of Z MAC + 1
	 add	 dx,[esi+ebx].MAC_NPAR	; Bump DX to segment of next MAC entry

; If the Z entry points below 640K, disable DOSMAX
	 cmp	 dx,9FFFh		; Less than a full load?
	 jae	 short @F		; Skip if not

DMCH_SHORT:
	 or	 SVM_FLAG,@SVM_SHORT	; DOSMAX is off due to short low DOS?
@@:
	 cmp	 dx,ax			; It must be bigger than the last one
	 jbe	 short DMCH_XMAC	; Exit if not

	 movzx	 ebx,dx 		; Segment of MAC entry
	 shl	 ebx,(4-0)		; Convert from paras to linear address
	 cmp	 [esi+ebx].MAC_OWNR,@MAC_LINK ; Owned by the DOS?
	 jne	 DMCH_XMAC		; Exit if not

	 mov	 DOSUMB_MAC,dx		; Segment of DOS=UMB spanning entry
DMCH_XMAC:
	 REGREST <esi,edx,ebx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_FINDSPAN		; End DOSMAX_FINDSPAN procedure
	 page
BeginProc DOSMAX_SYSCRITINIT		; High priority setup for DOSMAX
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Sys_Critical_Init setup for DOSMAX

	Check for conditions precluding DOSMAX

	Allocate the per VM control block space
	Check on the availability of B0-B7 pages
	Hook the VMM's Hook_V86_Page service to catch the VDD's call
	Hook into the _DOSMGR_Exec_VM service to catch the SHELL
	Hook into the VDD_PIF_State service to catch the SHELL [3]
	If Win95
	   Hook into the SHELL's DOSMAX property extension
	endif
	Hook into the _CopyPageTable service to catch the VDMAD

	Calculate size of DOSMAX per VM data.

	If real mode reports that low DOS is short, we'll pretend to
	install, but no memory will be allocated.  Most of the hooks
	will still be installed so we can get the hooks and popup a warning.

|

	 and	 PMI_FLAG,(not @PMI_DOSMAX) ; Assume DOSMAX support disabled

	 cmp	 LaDSTK_TAB,0		; Do we have 386MAX DOS stacks?
	 je	 ISVM_EXIT		; Exit procedure if not

; Check state of DOSMAX= switch in SYSTEM.INI -- The default is ON.

	 sub	 eax,eax		; Assume option not present or TRUE
	 dec	 eax			; ...
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAX ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
					; Carry flag set:
					;	Entry not found or not boolean
					;	EAX = default value
					; Carry flag clear:
					;	Zero flag set:
					;		String was empty
					;	Zero flag clear:
					;		EAX = 0 if FALSE
					;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid DOSMAX= cookie in SYSTEM.INI

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 ISVM_EXIT		; Exit procedure if DOSMAX=OFF

; Check state of DOSMAXDefault= switch in SYSTEM.INI

	 sub	 eax,eax		; Assume option not present or FALSE
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAXDEF ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short @F		; Skip if DOSMAXDefault=FALSE

	 or	 SVM_FLAG,@SVM_DOSMAX_DEF ; All VMs are DOSMAXs
@@:

	 and	 SVM_FLAG,(not @SVM_XLATFONT) ; Assume no font change xlat

; Check state of DOSMAXFonts= switch in SYSTEM.INI -- The default is ON.

	 sub	 eax,eax		; Assume option not present or TRUE
	 dec	 eax			; ...
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAXFONTS ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short @F		; Skip if DOSMAXFonts=OFF

	 or	 SVM_FLAG,@SVM_XLATFONT ; Translate font changes
@@:

; Check state of DOSMAXMono= switch in SYSTEM.INI -- The default is ON.

	 sub	 eax,eax		; Assume option not present or TRUE
	 dec	 eax			; ...
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAXMONO ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
	 or	 eax,eax		; EAX = 0 if FALSE
	 jnz	 short @F		; Skip if DOSMAXMono != OFF

	 or	 SVM_FLAG,@SVM_NOMONO	; Disable use of B000-B7FF
@@:

; Check state of DOSMAXJuggle= switch in SYSTEM.INI -- The default is ON.

	 sub	 eax,eax		; Assume option not present or ON
	 dec	 eax			; ...
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAXJUGGLE ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
	 or	 eax,eax		; EAX = 0 if FALSE
	 jnz	 short @F		; Skip if DOSMAXJuggle=ON

	 or	 SVM_FLAG,@SVM_NOJUGGLE ; Disable INT 10h unhook/rehook
@@:

; Check state of DOSMAXBreak= switch in SYSTEM.INI

	 sub	 eax,eax		; Assume option not present or FALSE
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_DOSMAXBREAK ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option
					; Carry flag set:
					;	Entry not found or not boolean
					;	EAX = default value
					; Carry flag clear:
					;	Zero flag set:
					;		String was empty
					;	Zero flag clear:
					;		EAX = 0 if FALSE
					;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid DOSMAXBreak= cookie in SYSTEM.INI

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short @F		; Skip set if DOSMAXBreak=FALSE

	 or	 DBG_FLAG,@DBG_DOSMAX	; DOSMAX debugging support enabled
@@:

; Allocate the per VM data area for DOS call data buffers
	 VMMcall _Allocate_Global_V86_Data_Area, <@GLOBV86_SIZE, 0>
	 or	 eax,eax		; Did we get the space?
	 jnz	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_AllocDOSBuffer_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 GLOBAL_V86_LIN,eax	; Save linear address of data area

	 mov	 edx,eax		; Copy linear address
	 and	 ax,000Fh		; Isolate the offset
	 mov	 GLOBAL_V86_VEC.VOFF,ax ; Remember the offset

	 shr	 edx,4			; Convert from linear address to segment
	 mov	 GLOBAL_V86_VEC.VSEG,dx ; Remember the segment

; Check for short DOSMAX installation
	 test	 SVM_FLAG,@SVM_SHORT	; DOSMAX is off due to short low DOS?
	 jnz	 ISVM_SHORT		; Skip most of the work if short

; Allocate the per VM data area for font changes
	 test	 SVM_FLAG,@SVM_XLATFONT ; Are we providing font translation?
	 jz	 short ISVM_XFONT	; Skip allocation if not

	 VMMcall _Allocate_Global_V86_Data_Area, <@XLATFONT_SIZE, <0>>
	 or	 eax,eax		; Did we get the space?
	 jnz	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_AllocFontBuffer_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 XLATFONT_V86_LIN,eax	; Save linear address of data area

	 mov	 edx,eax		; Copy linear address
	 and	 ax,000Fh		; Isolate the offset
	 mov	 XLATFONT_V86_VEC.VOFF,ax ; Remember the offset

	 shr	 edx,4			; Convert from linear address to segment
	 mov	 XLATFONT_V86_VEC.VSEG,dx ; Remember the segment
ISVM_XFONT:

; Check on the availability of B0-B7
; To use any of the address space, we'll need a contiguous region starting at B0
; Find the valid pages, assign 'em and hook their V86 page faults

; FIXME Will we need a switch to control this?

	 mov	 eax,0B0h		; Starting page #
	 mov	 edx,0B0h-0A0h		; Starting page # (A0 origin)
	 mov	 ecx,8			; # of pages to check

	 test	 SVM_FLAG,@SVM_NOMONO	; Disable use of B000-B7FF?
	 jnz	 short ISVM_SVM_B0HIT	; No pages if so

ISVM_SVM_B0LOOP:
	 bt	 HIGHDOS_MAP,eax	; Is this a high DOS memory page?
	 jc	 short ISVM_SVM_B0HIT	; Exit loop if so

	 bt	 ROM_BMP,edx		; Is this page a ROM?
	 jc	 short ISVM_SVM_B0HIT	; Exit loop if so

	 bt	 ASSIGN_BMP,edx 	; Do we already have the page assigned?
	 jc	 short ISVM_SVM_B0ASG	; Skip _Assign_Device_V86_Pages if so

	 REGSAVE <eax,ecx,edx>		; Save registers VMMcall will wreck
	 sub	 ecx,ecx		; A handy zero
;					   V86 page #
;					   |	Count (rounded up)
;					   |	|    Global assignment
;					   |	|    |	  Flags
;					   |	|    |	  |
	 VMMcall _Assign_Device_V86_Pages <eax, 1, ecx, ecx>
	 or	 eax,eax		; EAX = 0 if error
	 REGREST <edx,ecx,eax>		; Restore registers

	 jnz	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_AssignDeviceV86Pages_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:

; Keep the VDD away from 'em
	 call	 ProcessPageInMonoDispArea ; Indicate it should fail if B0-B7

	 REGSAVE <eax,ecx,edx>		; Save registers VMMcall will wreck

	 mov	 esi,OFFSET32 B0_PFAULT ; ESI ==> our page fault hook
	 VMMcall Hook_V86_Page		; Page # in EAX -- Carry set if error
	 REGREST <edx,ecx,eax>		; Restore registers

	 jnc	 short @F		; Skip error code if no carry

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_HookV86Page_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
ISVM_SVM_B0ASG:
	 inc	 al			; Bump the page #
	 inc	 dl			; ...	   page # (origin A0)
	 loop	 ISVM_SVM_B0LOOP	; Test 'em all

ISVM_SVM_B0HIT:
	 sub	 ecx,8			; Calculate # of pages in B0-B7 region
	 neg	 ecx			; Maximum we'll use for DOSMAX
	 mov	 SVM_MAX_PAGES_B0,ecx	; Remember it

; Hook into the Hook_V86_Page service to catch the VDD

	 mov	 eax,Hook_V86_Page	; ID for service to hook
	 mov	 esi,OFFSET32 LCL_HOOK_V86_PAGE ; Address of local handler
	 VMMcall Hook_Device_Service	; Return old handler in ESI
	 jnc	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_Hook_HookV86Page_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 OLD_HOOK_V86_PAGE,esi	; Save the original handler

; Hook into the _CopyPageTable service to catch the VDMAD

	 mov	 eax,_CopyPageTable	; ID for service to hook
	 mov	 esi,OFFSET32 LCL_COPY_PAGE_TABLE ; Address of local handler
	 VMMcall Hook_Device_Service	; Return old handler in ESI
	 jnc	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_Hook_CopyPageTable_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 OLD_COPY_PAGE_TABLE,esi ; Save the original handler

ISVM_SHORT:		; Regain control here if short DOSMAX

; Hook into the _DOSMGR_Exec_VM service to catch the SHELL

	 mov	 eax,_DOSMGR_Exec_VM	; ID for service to hook
	 mov	 esi,OFFSET32 LCL_DOSMGR_EXEC_VM ; Address of local handler
	 VMMcall Hook_Device_Service	; Return old handler in ESI
	 jnc	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_Hook_DOSMGRExecVM_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 OLD_DOSMGR_EXEC_VM,esi ; Save the original handler

; Hook into the VDD_PIF_State service to catch the SHELL [3]
	 mov	 eax,VDD_PIF_State	; ID for service to hook
	 mov	 esi,OFFSET32 LCL_VDD_PIF_STATE ; Address of local handler
	 VMMcall Hook_Device_Service	; Return old handler in ESI
	 jnc	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_Hook_VDDPIFState_Failed
	 jmp	 ISVM_EXIT		; No DOSMAXs if it failed
@@:
	 mov	 OLD_VDD_PIF_STATE,esi	; Save the original handler

; If this is Win95, also hook into the SHELL.VXD

	cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
	jb	short ISVM_X95		; Jump if not

; Hook into the Allocate_Global_V86_Data_Area service to workaround
; a bug in the internal VPOWERD driver in VMM32.VxD

	mov	eax,_Allocate_Global_V86_Data_Area ; ID for service to hook
	mov	esi,OFFSET32 LCL_AGV86DA ; Address of local handler
	VMMcall Hook_Device_Service	; Return old handler in ESI
	jnc	short @F		; Skip error code

	BREAK	DBG_FLAG,@DBG_DOSMAX,SVM_Hook_AGV86DA_Failed
	jmp	short ISVM_EXIT 	; No DOSMAXs if it failed
@@:
	mov	OLD_AGV86DA,esi 	; Save the original handler

	mov	eax,OFFSET32 STR_PROPEXT ; GroupID
	mov	edx,OFFSET32 STR_PROPDLL ; Property group DLL
	mov	esi,OFFSET32 DOSMAX_Callback ; Get offset of callback procedure

	VxDcall SHELL_Hook_Properties	; Hook into the SHELL
	jnc	short ISVM_X95		; Jump if it worked

	BREAK	DBG_FLAG,@DBG_DOSMAX,SVM_Shell_Hook_Prop_Failed
	jmp	short ISVM_EXIT 	; No DOSMAXs if it failed

ISVM_X95:

; Calculate size of DOSMAX per VM data.

	 mov	 eax,DEV_CB_LEN 	; Accumulated length of per VM data
	 mov	 DOSMAX_PERVMOFF,eax	; Save as offset to DOSMAX per VM data

	 add	 eax,(type DOSMAX_PERVM_STR) ; Account for additional data
	 mov	 DEV_CB_LEN,eax 	; Update the length

; If we got this far, DOSMAX is enabled and operating

	 or	 PMI_FLAG,@PMI_DOSMAX	; DOSMAX support enabled

ifdef @DEBUG
	 REGSAVE <esi>			; Save caller's registers
	 mov	 esi,OFFSET32 MSG_DOSMAX	; Offset to message text
	 call	 DISPLAY		; Put message on debugging screen
	 REGREST <esi>			; Restore caller's registers
endif					; IFDEF @DEBUG

ISVM_EXIT:
	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_SYSCRITINIT		; End DOSMAX_SYSCRITINIT procedure
	 page
COMMENT|

	This is a template of a small TSR copied into global V86 data in
	every VM.  It is used to cause a mode switch on the way into and
	out of INT 10h functions that do video mode switch or font changes.

	This is real mode code that just happens to be assembled in this
	USE32 segment.	Don't use any proteced mode instruction here.  All
	memory accesses that are to be WORD, should be declared as DWORD to
	avoid erroneous operand size overrides.

	The normal BeginProc/EndProc wrapper is not used to avoid the preamble.

|
	 public  I10Stub, LI10Stub, I10Stub_Entry, I10Stub_Exit
I10Stub  proc	 near			; Stub procedure to hook V86 INT 10h
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 sti				; Allow interrupts

	 or	 ah,ah			; Mode switch?
	 je	 short I10Stub_Switch	; Give the VxD a crack at it if so

	 cmp	 ah,1Ch 		; Save/restore state?
	 je	 short I10Stub_Switch	; Give the VxD a crack at it if so

	 cmp	 ah,11h 		; Font related services?
	 jne	 short I10Stub_Reflect	; Don't trap into protected mode if not

	 cmp	 al,3			; Set char map?
	 je	 short I10Stub_Reflect	; Don't trap into protected mode if so

	 cmp	 al,30h 		; Get font info?
	 je	 short I10Stub_Reflect	; Don't trap into protected mode if so

	 cmp	 al,20h 		; 10h, 12h, etc. Set graphics mode font?
	 jb	 short I10Stub_Switch	; Give the VxD a crack at it if not

	 cmp	 al,24h 		; 20h - 24h, Load font?
	 jbe	 short I10Stub_Reflect	; Don't trap into protected mode if so

I10Stub_Switch: 			; Give the VxD a crack at it
I10Stub_Entry	 equ	$-I10Stub	; Distance to ARPL
	 nop				; Space for V86 breakpoint

I10Stub_Patch	 equ	$-I10Stub	; Distance to this patch area
	 nop				; Leave room in which to compile code
	 nop
	 nop
	 nop

	 pushfd 			; PUSHFD used to avoid 66h
	 cli				; Simulate interrupt
	 db	 @OPCOD_CALLF		; FAR CALL immediate
I10Stub_CALL	 equ	$-I10Stub	; Distance to FAR PTR
	 dd	 ?			; Space for FAR PTR

I10Stub_Exit	 equ	$-I10Stub	; Distance to ARPL
	 nop				; Space for V86 breakpoint

I10Stub_IRET	 equ	$-I10Stub	; Distance to IRET
	 iretd				; IRETD used to avoid 66h

I10Stub_Reflect:
	 db	 @OPCOD_JMPF		; FAR JMP immediate
I10Stub_JMP	 equ	$-I10Stub	; Distance to FAR PTR
	 dd	 ?			; Space for FAR PTR

LI10Stub equ	 $-I10Stub		; Size of stub TSR

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
I10Stub  endp				; End I10Stub procedure

BeginProc DOSMAX_DEVICEINIT		; Lower priority setup for DOSMAX
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Device_Init time setup for DOSMAX

	To get control around the mode switches and font changes, we grab
	some global V86 data area and copy a small TSR into it.  This stub
	has two magic breakpoint ARPLs in it, surrounding a CALLF to the
	original INT 10h guy.  This add 4 mode switches to every INT 10h of
	this special class.

	Control is taken in protected mode to gain control AFTER
	the VDD sees the INT 10h.

	Control is also taken in protected mode to gain control BEFORE
	the VDD sees the INT 10h.  This is done in ZMAX.

	When we get control before the VDD, we unhook our stub TSR and rehook
	it on the back side of the VDD.  This avoids a nasty collision with
	a bug in the VDD if they find they're stub not the current holder
	of INT 10h.  This fixes the problems on Video 7 and Diamond Speedstar
	VGA boards.

	This code will be in every VM that gets created.
	We'll filter out the Sys_VM and the WFW Server_VM in protected mode.

	The VDD uses this scheme in addition to taking the INT 10h in
	protected mode.  They set the V86 INT 10h vector at Device_Init
	and reset it at Sys_Critical_Exit.  Due to their timing and the
	initialization order of the VDD vs. LoadHi, we must allow the VDD
	to unhook both stubs.  To pull this off, we hook in at Init_Complete
	and never unhook.

	FIXME if the VDD doesn't hook in for some reason, this scheme will
	leave the system fucked on exit.  There are comments in the VDD source
	code concerning the future use of a switch to control the downstairs
	stub.

|

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 SVM_DEVICEINIT_XIT	; Exit if not

	 test	 SVM_FLAG,@SVM_SHORT	; DOSMAX off due to short low DOS?
	 jnz	 SVM_DEVICEINIT_XIT	; Exit if not

; Allocate space in every VM for the stub code
; WORD alignment and instanced allows it's use as a stack

	 VMMcall _Allocate_Global_V86_Data_Area, <LI10Stub, <GVDAWordAlign or GVDAInstance>>
					; EAX ==> space downstairs for stub
	 or	 eax,eax		; Did we get the space?
	 jnz	 short @F		; Skip error if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,QPOPUP_EVENTPROC_AllocStub_Failed ; FIXME
@@:
	 mov	 INT10_STUB_ADDR,eax	; Remember its linear address

	 mov	 edi,eax		; EDI ==> downstairs stub
	 mov	 esi,OFFSET32 I10Stub	; ESI ==> model of stub
	 mov	 ecx,LI10Stub		; Length of stub in bytes

	 cld				; Autoincrement
     rep movsb				; Copy the stub downstairs

	 mov	 edx,eax		; EDX ==> downstairs stub
	 and	 edx,0Fh		; Isolate the offset
	 shr	 eax,4			; Isolate segment of stub
	 shl	 eax,16 		; Move segment to upper half
	 mov	 ax,dx			; Copy the offset
					; EAX = segment:offset of new INT 10h
	 mov	 NEW_INT10,eax		; Save the new INT 10h vector
	 mov	 INT10_STUB_VEC,eax	; Save segment:offset of stub

	 add	 eax,I10Stub_Entry	; Bump to spot for first mode switch
	 sub	 edx,edx		; Reference data
	 mov	 esi,OFFSET32 V86_INT10_ENTRY ; ==> callback
	 VMMcall Install_V86_Break_Point ; Place the ARPL

	 add	 eax,I10Stub_Exit-I10Stub_Entry ; Spot for 2nd mode switch
	 sub	 edx,edx		; Reference data
	 mov	 esi,OFFSET32 V86_INT10_EXIT ; ==> callback
	 VMMcall Install_V86_Break_Point ; Place the ARPL

	cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
	jae	short SVM_DEVICEINIT_NOQPE ; Jump if so (QPE not used)

; Build the filespec of the default .PIF
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_DefaultQPE

	 VMMcall Get_Config_Directory	; ... into EDX
	 mov	 esi,edx		; Copy to source register
	 mov	 ecx,(size szDefaultQPE) ; Maximum length of filespec
	 lea	 edi,szDefaultQPE	; ==> filespec buffer
	 cld				; Autoincrement
@@:
	 lodsb				; Copy next character
	 stosb				; ...
	 or	 al,al			; Is it the NUL?
	 loopnz  short @B		; Get 'em all (up to _MAX_PATH)

	 dec	 edi			; Retreat over terminating NUL
	 mov	 ecx,cb_DefaultQPE	; Length of filename.ext
	 lea	 esi,sz_DefaultQPE	; ==> '_DEFAULT.QPE', 0
     rep movsb				; Copy font patterns into buffer
SVM_DEVICEINIT_NOQPE:

; Hook INT 10h in protected mode to be processed AFTER the VDD's hook
	 mov	 eax,10h		; Interrupt 10h
	 mov	 esi,OFFSET32 AFTER_VDD_INT10 ; ==> INT 10h hook procedure
	 VMMcall Hook_V86_Int_Chain	; Hook INT 10h

; Hook INT 21h function 4B00h to catch troublesome graphics programs
	 mov	 eax,21h		; Interrupt #
	 mov	 esi,OFFSET32 SVM_INT21 ; ==> V86 INT 21h hook procedure
	 VMMcall Hook_V86_Int_Chain	; Hook INT 21h

SVM_DEVICEINIT_XIT:
	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_DEVICEINIT		; End DOSMAX_DEVICEINIT procedure
	 page
BeginProc DOSMAX_INITCOMPLETE		; Lower priority setup for DOSMAX
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Init_Complete time setup for DOSMAX

|

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 SVM_INITCOMPLETE_XIT	; Exit if not

	 call	 DOSMAX_FINDSPAN	; Find the DOS=UMB spanning entry

	 test	 SVM_FLAG,@SVM_SHORT	; DOSMAX off due to short low DOS?
	 jnz	 SVM_INITCOMPLETE_XIT	; Exit if not

; Get and save the original V86 INT 10h vector

	 mov	 eax,10h		; Interrupt #
	 VMMcall Get_V86_Int_Vector	; Get the vector
	 shl	 ecx,16 		; Move segment to upper half
	 mov	 cx,dx			; Copy offset to combo register
	 mov	 OLD_INT10,ecx		; Save the previous INT 10h vector

; Compile in the correct FAR PTRs

	 mov	 edi,INT10_STUB_ADDR	; Linear address of stub
	 mov	 [edi+I10Stub_CALL],ecx ; Compile in the proper CALLF pointer
	 mov	 [edi+I10Stub_JMP],ecx	; Compile in the proper JMPF pointer

; Set the new V86 INT 10h vector

	 mov	 ecx,NEW_INT10		; New INT 10h vector
	 jecxz	 short SVM_INITCOMPLETE_XIT ; Exit if we're not hooking INT 10h

	 movzx	 edx,cx 		; Copy the offset
	 shr	 ecx,16 		; Move segment to lower half
	 mov	 eax,10h		; Interrupt #
	 VMMcall Set_V86_Int_Vector	; Update the real mode IDT

SVM_INITCOMPLETE_XIT:
	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_INITCOMPLETE		; End DOSMAX_INITCOMPLETE procedure

endif					; IFDEF @DOSMAX

VxD_ICODE_ENDS				; End _ITEXT segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 ProcessPageInMonoDispArea:near ; In LoadHi.OBJ
	 extrn	 ISWHITE:near		; VMAX.ASM
	 extrn	 SKIPWHITE:near
	 extrn	 CONSUME:near
	 extrn	 TOKENIZE:near
	 extrn	 CHK_CFG_FLAG:near
	 extrn	 FIND_ENV_PGM:near
	 extrn	 CMPSBI:near

ifdef @DEBUG
	 extrn	 DISPLAY:near		; VMAX_DBG.ASM
endif					; IFDEF @DEBUG

ifdef @DOSMAX
BeginProc DOSMAX_Callback
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Callback procedure for Win95 SHELL.VXD.

This routine is called immediately after Create_VM processing
and whenever the properties of an existing VM machine are changed.

For our purposes, it's not called soon enough.  This means that
at Create_VM time, we assume the maximum and reduce from there
at this point as necessary.

On entry:

EBX	=	VM handle
EDX	==>	data
EDI	==>	ordinal (address of property ordinal)
		if the property ordinal is zero, it's
		immediately followed by an ASCIIZ string
		specifying the name of the property group.
|

	cmp	ebx,CreateVMHandle	; Izit the handle of the just created VM?
	jne	short DOSMAX_Callback_Exit ; Jump if not

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_Call_Back

	push	eax			; Save for a moment

	SetDOSMAXPtr eax		; EAX ==> DOSMAX per VM structure
	or	[eax].CB_wFlags,@CBF_DOSMAX_CALLBACK ; Mark as called

	test	[eax].CB_wFlags,@CBF_DOSMAX ; Izit a DOSMAX session?
	pop	eax			; Restore
	jz	short DOSMAX_Callback_Exit ; Jump if not

	cmp	[edx].DMPIF_bFlag,@DOSMAX_ON ; Is 'Force ON' in effect?
	je	short DOSMAX_Callback_Exit ; Exit if so -- already handled

	cmp	[edx].DMPIF_bFlag,@DOSMAX_OFF ; Is 'Force OFF' in effect?
	je	short DOSMAX_Callback_Off ; Jump if so to back out

; The setting is @DOSMAX_DEF -- check DOSMAXDefault state

	test	SVM_FLAG,@SVM_DOSMAX_DEF ; All VMs are DOSMAXs?
	jnz	short DOSMAX_Callback_Exit ; Jump if so (already handled)
DOSMAX_Callback_Off:
	call	DOSMAX_SetOff		; Turn off DOSMAX settings for this VM
DOSMAX_Callback_Exit:
	mov	CreateVMHandle,0	; Zero for next time

	ret				; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc DOSMAX_Callback
	page
BeginProc DOSMAX_SetOff
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Turn off DOSMAX settings

The DOSMAX setting for this VM is either OFF or default and
the default is OFF.

We need to back out of the DOSMAX memory assignments we made
in Create_VM.

On entry:

EBX	=	VM handle

|

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_Set_Off

	call	DOSMAX_DESTROYVM	; Remove mappings

	push	eax			; Save for a moment

	SetDOSMAXPtr eax		; EAX ==> DOSMAX per VM structure
	and	[eax].CB_wFlags,not @CBF_DOSMAX ; No longer a DOSMAX VM

	pop	eax			; Restore

	ret				; Return to caller

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc DOSMAX_SetOff
	page
BeginProc DOSMAX_SYSTEMEXIT			; DOSMAX termination code
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Final cleanup for DOSMAX.  Remove V86 breakpoints, etc.

|

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_SystemExit

	 mov	 eax,NEW_INT10		; Vector to our INT 10h stub downstairs
	 or	 eax,eax		; Did we ever install?
	 jz	 short @F		; Don't remove what we didn't install

	 add	 eax,I10Stub_Entry	; Bump to spot for first mode switch
	 VMMcall Remove_V86_Break_Point ; Remove the ARPL

	 mov	 eax,NEW_INT10		; Vector to our INT 10h stub downstairs
	 add	 eax,I10Stub_Exit	; Spot for 2nd mode switch
	 VMMcall Remove_V86_Break_Point ; Remove the ARPL
@@:
	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_SYSTEMEXIT			; End DOSMAX_SYSTEMEXIT proc
	 page
BeginProc BEFORE_VDD_INT10		; DOSMAX V86 INT 10h hook (BEFORE VDD)
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	V86 INT 10h hook.
	This procedure gets control before VDD_Int_10.

	Check for situations requiring QPopup.
	Schedule the callback.
	Return carry clear to avoid the next handler in the chain.

	Otherwise, return carry set to give the VDD a crack at the INT 10h.

|

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 BEFORE_VDD_INT10_STC	; Ignore the INT 10h if not

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_VMINIT ; Has VM_Init been processed yet?
	 jz	 BEFORE_VDD_INT10_STC	; Ignore the INT 10h if not

	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 BEFORE_VDD_INT10_STC	; Ignore the INT 10h if not

	 cmp	 [ebp].Client_AH,00h	; Is it video mode switch?
	 jne	 BEFORE_VDD_INT10_STC	; Ignore it if not
					; If it's a font service, we'll get it
					; in the stub in V86 mode

	 mov	 al,[ebp].Client_AL	; Pick up mode
	 and	 al,(not 80h)		; Kill the erase bit

;;;;;;	 cmp	 al,7			; Mono 25 x 80?
;;;;;;	 je	 BEFORE_VDD_INT10_STC	; Ignore the INT 10h if so
;;;;;;
;;;;;;	 cmp	 al,4			; CGA or higher graphics mode?
	 cmp	 al,8			; PCjr or higher graphics mode?
	 jb	 BEFORE_VDD_INT10_STC	; Map in the real video memory if not

; They're trying to enter graphics mode.

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,BEFORE_VDD_INT10_GRAPHICSMODE

	 sub	 ah,ah			; Convert video mode from BYTE to WORD
	 mov	 [edx].CB_wVideoMode,ax ; Save in per VM data

; Dig out the program name

	 Push_Client_State		; Save client's register structure
	 VMMcall Begin_Nest_V86_Exec	; Switch VM to V86 mode

	 mov	 [ebp].Client_AH,@GETPSP ; Get current PSP into BX
	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call

	 mov	 ax,[ebp].Client_BX	; Get segment of PSP

	 VMMcall End_Nest_Exec		; Restore VM to original state
	 Pop_Client_State		; Restore client's register structure

	 REGSAVE <edx>			; Save registers around call

	 call	 FIND_ENV_PGM		; Return EDI ==> program name
					; ESI ==> entire path and filename
					; EDX = length of filename including NUL
					; FEP_FLAG = 0 we couldn't find a name
					;	     1 for a PSP ENV name
					;	     2 for a DOS 4 MAC name

	 REGREST <edx>			; Restore registers

	 mov	 [edx].CB_PFILENAME,edi ; Save ==> filename in per VM data

; Send a message upstairs to QPOPUP.EXE
; The user will have the opportunity to allow the mode switch, ignore it,
; or terminate the VM.

	 mov	 [edx].CB_wFunction,@CBFN_MODESWITCH ; Attempted a mode switch
	 call	 ScheduleQpopup 	; PostMessage to QPOPUP.EXE
	 call	 SemaphoreBlock 	; Block the VM, using a semaphore
					; Control returns with the semaphore
					; is signalled.
	 call	 ScheduleCleanup	; Cleanup after scheduled event

BEFORE_VDD_INT10_SEMAPHORE_UNBLOCK:
	 clc				; Pretend we serviced the INT 10h

	 jmp	 short BEFORE_VDD_INT10_EXIT ; Rejoin common code

BEFORE_VDD_INT10_STC:			; We fell through or it's too early

; Unhook our INT 10h TSR so the VDD will use emulate mode
;;;;;;;; BREAK	 DBG_FLAG,@DBG_DOSMAX,Before_Unhook

	 test	 SVM_FLAG,@SVM_NOJUGGLE ; Disable INT 10h unhook/rehook?
	 jnz	 short BEFORE_VDD_INT10_XJUGGLE ; Jump if not

	 mov	 ecx,ds:[10h*(type VECTOR)] ; Current VMs V86 INT 10h vector
	 cmp	 ecx,NEW_INT10		; INT 10h pointing to our TSR?
	 jne	 short BEFORE_VDD_INT10_XJUGGLE ; Skip juggle if not

	 mov	 ecx,OLD_INT10		; Previous INT 10h vector
	 movzx	 edx,cx 		; Copy the offset
	 shr	 ecx,16 		; Move segment to lower half
	 mov	 eax,10h		; Interrupt #
	 VMMcall Set_V86_Int_Vector	; Update the real mode IDT
BEFORE_VDD_INT10_XJUGGLE:

	 stc				; Chain to the next handler

BEFORE_VDD_INT10_EXIT:
	 ret				; Return to WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  BEFORE_VDD_INT10		; End BEFORE_VDD_INT10 procedure
	 page
BeginProc AFTER_VDD_INT10		; DOSMAX V86 INT 10h hook (AFTER VDD)
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	V86 INT 10h hook.
	This procedure gets control after VDD_Int_10.

	Rehook the real mode IDT.

|

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 short AFTER_VDD_INT10_STC ; Ignore the INT 10h if not

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_VMINIT ; Has VM_Init been processed yet?
	 jz	 short AFTER_VDD_INT10_STC ; Ignore the INT 10h if not

; Rehook our INT 10h TSR
;;;;;;;; BREAK	 DBG_FLAG,@DBG_DOSMAX,After_Rehook

	 test	 SVM_FLAG,@SVM_NOJUGGLE ; Disable INT 10h unhook/rehook?
	 jnz	 short AFTER_VDD_INT10_XJUGGLE ; Jump if not

	 mov	 ecx,ds:[10h*(type VECTOR)] ; Current VMs V86 INT 10h vector
	 cmp	 ecx,OLD_INT10		; INT 10h pointing to VDD's TSR?
	 jne	 short AFTER_VDD_INT10_XJUGGLE ; Skip juggle if not

	 mov	 ecx,NEW_INT10		; New INT 10h vector
	 movzx	 edx,cx 		; Copy the offset
	 shr	 ecx,16 		; Move segment to lower half
	 mov	 eax,10h		; Interrupt #
	 VMMcall Set_V86_Int_Vector	; Update the real mode IDT
AFTER_VDD_INT10_XJUGGLE:

AFTER_VDD_INT10_STC:			; We fell through or it's too early
	 stc				; Chain to the next handler

AFTER_VDD_INT10_EXIT:
	 ret				; Return to WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  AFTER_VDD_INT10		; End AFTER_VDD_INT10 procedure
	 page
BeginProc SemaphoreBlock		; Block the VM, using a semaphore
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Block the VM (current, and handle in EBX) using a semaphore
	Return control when the semaphore is signalled.

ENTRY:
	EDX	==>	DOSMAX per VM data

EXIT:
	All registers preserved

|

	 pushad 			; Save 'em all

	 sub	 ecx,ecx		; Initial token count
	 VMMcall Create_Semaphore	; Allocate and initialize a semaphore
	 jnc	 short @F		; Skip error code

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,DOSMAX_CreateSemaphoreFailed
@@:
	 mov	 [edx].CB_SEMAPHORE,eax ; Save the semaphore handle
	 or	 [edx].CB_wFlags,@CBF_SEMAPHORE ; Blocked on a semaphore

	 mov	 ecx,(Block_Svc_Ints or Block_Enable_Ints)
	 VMMcall Wait_Semaphore 	; Block the VM
					; Control doesn't return until the
					; semaphore is signalled

	 sub	 eax,eax		; A handy NULL
	 xchg	 [edx].CB_SEMAPHORE,eax ; Swap with the semaphore handle
	 VMMcall Destroy_Semaphore	; Free it

	 and	 [edx].CB_wFlags,(not @CBF_SEMAPHORE) ; Not blocked

	 popad				; Restore 'em all
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SemaphoreBlock 		; End SemaphoreBlock procedure
	 page
BeginProc IsWindowed			; Return ZR set if VM is Windowed
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Returns ZR set if VM is windowed

Entry:
	EBX = VM handle

Exit:
	ZR set if VM is windowed

|

	 REGSAVE <eax,ecx,edx,esi,edi>	; Save caller's registers

	 VxDcall SHELL_GetVMInfo	; Get bits into EAX, ECX
					; EDX, ESI, and EDI trashed
	 not	 eax			; Flip sense of windowed bit
	 test	 eax,SGVMI_Windowed	; Is the VM in a window?
					; Sets zero flag if not windowed

	 REGREST <edi,esi,edx,ecx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  IsWindowed			; End IsWindowed procedure
	 page
BeginProc SVM_SwitchStacks		; Switch if Client_SS:SP ==> video pages
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	Switch to 386MAX DOS stack if the Client_SS:SP points to the video pages

Entry:
	EBX	=	Current VM handle
	EBP	==>	Client_Reg_Struc

|

	 REGSAVE <eax,ecx,edx>		; Save caller's registers

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 sub	 eax,eax		; Clear 32-bit register
	 mov	 ax,[ebp].Client_SS	; Client SS
	 shl	 eax,(4-0)		; Convert from segment to linear address
	 sub	 ecx,ecx		; Clear 32-bit register
	 mov	 cx,[ebp].Client_SP	; Client SP
	 add	 eax,ecx		; EAX ==> client stack
	 cmp	 eax,0A0000h		; Is it possibly in the video area?
	 jb	 short SVM_SwitchStacks_EXIT ; Jump if not

	 BREAK	DBG_FLAG,@DBG_DOSMAX,Switch_Stacks ; Call the debugger

	 call	 DSTK_SUB		; Switch to 386MAX DOS stack
					; Carry will be set if we couldn't
					; switch the stacks -- So now what?

SVM_SwitchStacks_EXIT:
	 REGREST <edx,ecx,eax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SVM_SwitchStacks		; End SVM_SwitchStacks procedure
	 page
BeginProc SVM_XlatFont			; Copy font data out of video pages
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Check for AX=1100h and AX=1110h user font loads.
	Client registers:
	    ES:BP ==> user font patterns
	    CX = # of patterns
	    BH = # of bytes per pattern

	If the font data at ES:BP extends into the video memory at A0,
	remap it into our V86 data area.

Entry:
	EBX	=	Current VM handle
	EDX	==>	DOSMAX per VM structure
	EBP	==>	Client_Reg_Struc

Exit:
	All registers preserved.

FIXME what about a critical section around the whole mess while the new font
patterns are in the translation buffer?

|

;;;;;;	 BREAK	 XlatFont		; Call the debugger FIXME

	 test	 SVM_FLAG,@SVM_XLATFONT ; Are we providing font translation?
	 jz	 short SVM_XF_EXIT	; Exit if not

	 cmp	 [ebp].Client_AH,11h	; Is it a font service?
	 jne	 short SVM_XF_EXIT	; How the hell did we get here?

	 REGSAVE <eax,ecx,esi,edi>	; Save caller's reigsters

	 mov	 al,[ebp].Client_AL	; Sub function
	 and	 al,(not 10h)		; Kill do-all bit
	 jnz	 short SVM_XF_EXIT0	; Exit if not AL=00h or AL=10h
					; FIXME handle other cases, too

	 call	 IsWindowed		; Return zero flag set if windowed
	 jz	 short SVM_XF_EXIT0	; Ignore if windowed

	 movzx	 ecx,[ebp].Client_CX	; # of patterns
	 movzx	 eax,[ebp].Client_BX.HI ; # of bytes per pattern
	 imul	 ecx,eax		; ECX = # of bytes in new patterns

	 cmp	 ecx,@XLATFONT_SIZE	; Too big for our translation buffer?
	 ja	 short SVM_XF_EXIT0	; Exit if so -- FIXME break it up?

	 movzx	 eax,[ebp].Client_ES	; V86 segment of font patterns
	 shl	 eax,4			; Convert from segment to linear address
	 movzx	 esi,[ebp].Client_BP	; V86 offset of font patterns
	 add	 esi,eax		; Linear address of font patterns

	 add	 eax,ecx		; End of patterns + 1
	 cmp	 eax,0A0000h		; Do the patterns overlap video memory?
	 jb	 short SVM_XF_EXIT0	; Exit if not -- no translation needed

	 mov	 edi,XLATFONT_V86_LIN	; Linear address of translation buffer
     rep movsb				; Copy font patterns into buffer

	 mov	 ax,XLATFONT_V86_VEC.VSEG ; Swap in new segment
	 xchg	 ax,[ebp].Client_ES	; ... in client registers
	 mov	 [edx].CB_FONTPTR.VSEG,ax ; Save for replacement later

	 mov	 ax,XLATFONT_V86_VEC.VOFF ; Swap in new offset
	 xchg	 ax,[ebp].Client_BP	; ... in client registers
	 mov	 [edx].CB_FONTPTR.VOFF,ax ; Save for replacement later

	 or	 [edx].CB_wFlags,@CBF_XLATFONT ; Translating a font

SVM_XF_EXIT0:

	 REGREST <edi,esi,ecx,eax>	; Restore caller's registers
SVM_XF_EXIT:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SVM_XlatFont			; End SVM_XlatFont procedure
	 page
BeginProc V86_INT10_ENTRY			; Local V86 INT 10h callback
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Called by VMM via an ARPL triggered by a V86 INT 10h

	Switch stacks if Client_SS:SP is above A0000h

	Troll for INT 10h AH=00h video mode switch
	Troll for INT 10h AX=11xx font change

	Map in the real A0 page for the video BIOS

Entry:
	EAX	=	Segment:offset of ARPL
	EBX	=	Current VM handle
	EDX	=	Reference data
	ESI	=	Linear address of ARPL
	EBP	==>	Client_Reg_Struc

Exit:
	Client CS:IP advanced past the ARPL

|

	 inc	 [ebp].Client_IP	; Advance over the ARPL

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jnz	 short @F		; Skip error if not

; How the hell did we ever get here?

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,V86_INT10_Entry_UghNoDOSMAX
@@:

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jz	 VI10ENTRY_EXIT 	; Ignore the INT 10h if so

; The VDD issues at least two INT 10h functions to set the initial video mode
; and font.  These occur at VM_Init before the machine is completely
; established.	We set a flag in ZMAX_VM_INIT, after the VDD has done its
; VM_Init processing.  Here we'll skip trapping INT 10h until after that
; flag is set.

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_VMINIT ; Has VM_Init been processed yet?
	 jz	 VI10ENTRY_EXIT 	; Ignore the INT 10h if not

	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 VI10ENTRY_EXIT 	; Ignore the INT 10h if not

	 call	 SVM_SwitchStacks	; Switch if Client_SS:SP ==> video pages

	 cmp	 [ebp].Client_AH,00h	; Is it video mode switch?
	 jne	 VI10ENTRY_CHKFONT	; Check for font changes if not

	 mov	 al,[ebp].Client_AL	; Pick up mode
	 and	 al,(not 80h)		; Kill the erase bit

;;;;;;	 cmp	 al,7			; Mono 25 x 80?
;;;;;;	 je	 VI10ENTRY_EXIT 	; Ignore the INT 10h if so
;;;;;;
;;;;;;	 cmp	 al,4			; CGA or higher graphics mode?
	 cmp	 al,8			; PCjr or higher graphics mode?
	 jb	 VI10ENTRY_MODE 	; Map in the real video memory if not

; They're trying to enter graphics mode.
; This should have been caught in our protected mode INT 10h hook.
; Control could get this far if a TSR is loaded locally in a DOS VM
; AND it does a FAR CALL to the previous INT 10h guy.
; That case seems quite unlikely, but we'll handle it anyway -- more slowly.

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,V86_INT10_Entry_MissedINT10InPM

	 sub	 ah,ah			; Convert to WORD
	 mov	 [edx].CB_wVideoMode,ax ; Save in per VM data

; Dig out the program name

	 Push_Client_State		; Save client's register structure
	 VMMcall Begin_Nest_V86_Exec	; Switch VM to V86 mode

	 mov	 [ebp].Client_AH,@GETPSP ; Get current PSP into BX
	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call

	 mov	 ax,[ebp].Client_BX	; Get segment of PSP

	 VMMcall End_Nest_Exec		; Restore VM to original state
	 Pop_Client_State		; Restore client's register structure

	 REGSAVE <edx>			; Save registers around call

	 call	 FIND_ENV_PGM		; Return EDI ==> program name
					; ESI ==> entire path and filename
					; EDX = length of filename including NUL
					; FEP_FLAG = 0 we couldn't find a name
					;	     1 for a PSP ENV name
					;	     2 for a DOS 4 MAC name

	 REGREST <edx>			; Restore registers

	 mov	 [edx].CB_PFILENAME,edi ; Save ==> filename in per VM data

; Blast a JMP $ into the INT 10h patch area

	 mov	 esi,[ebx+CB_High_Linear] ; Offset to VMs address space
	 add	 esi,INT10_STUB_ADDR	; Linear address of I10Stub
	 add	 esi,I10Stub_Patch	; ESI ==> patch point in INT 10h stub

	 mov	 word ptr [esi],((-2 shl 8) or @OPCOD_JMPS)

	 mov	 [edx].CB_wFunction,@CBFN_MODESWITCH ; Attempted a mode switch
	 call	 ScheduleQpopup 	; PostMessage to QPOPUP.EXE

	 jmp	 short VI10ENTRY_EXIT	; Rejoin common code

VI10ENTRY_CHKFONT:
	 cmp	 [ebp].Client_AH,11h	; Is it a font service?
	 je	 short VI10ENTRY_FONT	; Map in the real video memory

	 cmp	 [ebp].Client_AH,1Ch	; Is it save/restore state?
	 jne	 short VI10ENTRY_CHKFONT_X1C ; Ignore it if not

	 cmp	 [ebp].Client_AL,0	; Is it Get size of buffer?
	 je	 short VI10ENTRY_CHKFONT_X1C ; Ignore if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SVM_PM_SaveRestoreState
	 call	 IsWindowed		; Return zero flag set if windowed
	 jz	 short VI10ENTRY_CHKFONT_X1C ; Ignore if windowed

	 jmp	 short VI10ENTRY_FONT	; Map in the real video memory

VI10ENTRY_CHKFONT_X1C:
	 jmp	 short VI10ENTRY_EXIT	; Ignore it

VI10ENTRY_MODE:
	 or	 [edx].CB_wFlags,@CBF_MODE ; Trapping a mode switch
	 jmp	 short VI10ENTRY_MAPIT	; Rejoin common code

VI10ENTRY_FONT:
	 or	 [edx].CB_wFlags,@CBF_FONT ; Trapping a font service
	 call	 SVM_XlatFont		; Perform translation services

VI10ENTRY_MAPIT:
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,V86INT10_ENTRY_IGNORE_A0 ; Break if DOSMAXBreak=TRUE

	 call	 IsWindowed		; Return zero flag set if windowed
	 jz	 short VI10ENTRY_XMAPIT ; Skip mapping if so

; Rather than mapping in the real pages, mark 'em not-present so
; the VDD will catch the page fault and keep track of the changes.

	 or	 [edx].CB_wFlags,@CBF_IGNOREA0 ; Ignore page faults from A0

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _ModifyPageBits,<ebx,0A0h,16,<NOT P_AVAIL>,ecx,PG_HOOKED,ecx>
VI10ENTRY_XMAPIT:

VI10ENTRY_EXIT:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86_INT10_ENTRY		; End V86_INT10_ENTRY procedure
	 page
BeginProc V86_INT10_EXIT			; Call_When_VM_Returns callback
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Called by VMM via an ARPL when the V86 INT 10h returns

	Map in the NUL page at A0.

Entry:
	EAX	=	Segment:offset of ARPL
	EBX	=	Current VM handle
	EDX	=	Reference data
	ESI	=	Linear address of ARPL (uninteresting)
	EBP	==>	Client_Reg_Struc

|

	 inc	 [ebp].Client_IP	; Advance past the breakpoint

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jz	 VI10EXIT_EXIT		; Ignore the INT 10h if so

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_VMINIT ; Has VM_Init been processed yet?
	 jz	 VI10EXIT_EXIT		; Ignore the INT 10h if not

; Blast NOPs into the INT 10h patch area

	 mov	 esi,[ebx+CB_High_Linear] ; Offset to VMs address space
	 add	 esi,INT10_STUB_ADDR	; Linear address of I10Stub
	 add	 esi,I10Stub_Patch	; ESI ==> patch point in INT 10h stub
	 mov	 dword ptr [esi],90909090h ; Blast in four NOPs

; Check for special events

	 test	 [edx].CB_wFlags,@CBF_XLATFONT ; Translating a font?
	 jz	 short VI10EXIT_XXLATFONT ; Skip client pointer swap if not

	 mov	 ax,[edx].CB_FONTPTR.VSEG ; Replace original client segment
	 mov	 [ebp].Client_ES,ax	; ...

	 mov	 ax,[edx].CB_FONTPTR.VOFF ; Replace original client offset
	 mov	 [ebp].Client_BP,ax	; ...

	 and	 [edx].CB_wFlags,(not @CBF_XLATFONT) ; Forget it happened

VI10EXIT_XXLATFONT:

	 test	 [edx].CB_wFlags,@CBF_FONT ; Trapping a font change?
	 jnz	 short VI10EXIT_FONT	; Handle it

	 test	 [edx].CB_wFlags,@CBF_MODE ; Trapping a mode switch?
	 jnz	 short VI10EXIT_MODE	; Ignore it if not

	 jmp	 short VI10EXIT_EXIT	; Ignore it if not

VI10EXIT_MODE:
	 and	 [edx].CB_wFlags,(not @CBF_MODE) ; Forget mode switch

	 jmp	 short VI10EXIT_MAPIT	; Rejoin common code

VI10EXIT_FONT:
	 and	 [edx].CB_wFlags,(not @CBF_FONT) ; Forget font change

VI10EXIT_MAPIT:
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,V86INT10_EXIT_IGNORE_A0 ; Break if DOSMAXBreak=TRUE

	 and	 [edx].CB_wFlags,(not @CBF_IGNOREA0) ; Catch A0 page faults

	 call	 IsWindowed		; Return zero flag set if windowed
	 jz	 short VI10EXIT_XMAPIT	; Skip mapping if so

; Kill the PRESENT bit in the A000 pages to force the correct memory
; to be mapped in later at the first reference.

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _ModifyPageBits,<ebx,0A0h,16,<NOT P_AVAIL>,ecx,PG_HOOKED,ecx>
VI10EXIT_XMAPIT:

VI10EXIT_EXIT:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86_INT10_EXIT 		; End V86_INT10_EXIT procedure
endif					; IFDEF @DOSMAX

ifdef @DOSMAX
BeginProc DOSMAX_CREATEVM		; DOSMAX related Create_VM processing
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Do per VM processing related to DOSMAX:

	If this is a short DOSMAX setup, tell 'em the bad news and skip
	everything else.

	Allocate pages
	Copy the NUL page's PTE
	Map into V86
	Modify PTE bits

Entry:
	EBX	=	Handle of VM being created

|

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_Create_VM

	mov	CreateVMHandle,ebx	; Save for later use

	 and	 SVM_FLAG,(not @SVM_NOBASEMEM) ; Don't fail VM_INIT in ZMAX

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 VCVM_XDOSMAX		; Exit if not

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 mov	 [edx].CB_VMHANDLE,ebx	; VM_Handle itself for QPopup

	 sub	 eax,eax		; A handy zero
	 mov	 [edx].CB_wFlags,ax	; This VM doesn't get the feature

	 test	 SVM_FLAG,@SVM_DOSMAX_REQ ; Is DOSMAX requested for this VM?
	 jz	 VCVM_XDOSMAX		; Skip if not

	 mov	 [edx].CB_LASTEXEC,0	; Kill the name

; Assume we're not providing anything extra

	 mov	 [edx].CB_SELPERVM,ax	; No selector to the per VM struc
	 mov	 [edx].CB_lpszFilename,eax ; No FAR PTR to filename
	 mov	 [edx].CB_NPAGES_A0,eax ; Remember # of pages we're using
	 mov	 [edx].CB_HPAGE_A0,eax	; Remember the page handle (or NULL)
	 mov	 [edx].CB_NPAGES_B0,eax ; Remember # of pages we're using
	 mov	 [edx].CB_HPAGE_B0,eax	; Remember the page handle (or NULL)

; Check for a short DOSMAX setup and send 'em a dialog box if so
	 test	 SVM_FLAG,@SVM_SHORT	; DOSMAX off due to short low DOS?
	 jz	 short VCVM_NOTSHORT	; Skip error code if not

	 mov	 edi,OFFSET32 MSG_CAP_SHORT ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_TXT_SHORT ; ECX ==> message text
	 mov	 eax,MB_OK or MB_ICONEXCLAMATION
	 call	 ShellMessage		; EDX ==> caption, ECX ==> message

	 jmp	 VCVM_XDOSMAX		; Skip all DOSMAX work

VCVM_NOTSHORT:
	 or	 [edx].CB_wFlags,@CBF_DOSMAX ; This VM gets the feature

	 call	 SuspendIfNotRegistered ; Check for QPopup; suspend if absent

; Allocate the pages for A0-AF

	 sub	 eax,eax		; A handy zero
	 mov	 ax,DOSMAX		; Requested size of VM in KB
	 sub	 eax,640		; Size above 640 in K
	 shr	 eax,2			; Convert from 1K units to 4K pages

	 or	 eax,eax		; Do we need anything from A0-AF?
	 jz	 VCVM_XDOSMAX		; Jump if not

	 cmp	 eax,16 		; More than 16 pages?
	 jbe	 short @F		; Skip if not

	 mov	 eax,16 		; Maximum # of pages in A0-AF
@@:
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 mov	 [edx].CB_NPAGES_A0,eax ; Remember # of pages we're using

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _PageAllocate,<eax,PG_VM,ebx,ecx,ecx,ecx,ecx,PageLocked>
					; EAX = handle, EDX = linear address
	 mov	 ecx,eax		; Did we get the page?
	 or	 ecx,edx		; ...
	 jnz	 short @F		; Skip error code if it worked

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,DOSMAXCreateVM_A0PageAllocateFailed
@@:
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 mov	 [edx].CB_HPAGE_A0,eax	; Remember the page handle (or NULL)
CVSV_SKIPA0:

; Allocate the pages for B0-B7

	 sub	 eax,eax		; A handy zero
	 mov	 ax,DOSMAX		; Requested size of VM in KB
	 sub	 eax,640		; Size above 640 in K
	 shr	 eax,2			; Convert from 1K units to 4K pages
	 sub	 eax,16 		; Account for pages in A0-AF
	 jb	 short CVSV_SKIPB0	; Jump if no pages left for B0-B7

	 cmp	 eax,SVM_MAX_PAGES_B0	; More than we've got?
	 jbe	 short @F		; Skip if not

	 mov	 eax,SVM_MAX_PAGES_B0	; Set to the max we've got
@@:

; Ensure we've got something worth allocating

	 or	 eax,eax		; Do we want any pages at B0?
	 jz	 short CVSV_SKIPB0	; Jump if not

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 mov	 [edx].CB_NPAGES_B0,eax ; Remember # of pages we're using

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _PageAllocate,<eax,PG_HOOKED,ebx,ecx,ecx,ecx,ecx,PageLocked>
					; EAX = handle, EDX = linear address
	 mov	 ecx,eax		; Did we get the page?
	 or	 ecx,edx		; ... (zero flag crosses the macro)
	 pushfd 			; Save ZF
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 popfd				; Restore ZF
	 jnz	 short @F		; Skip error code if it worked

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,DOSMAXCreateVM_B0PageAllocateFailed
					; Save a NULL handle if the alloc failed
	 mov	 [edx].CB_NPAGES_B0,eax ; Remember # of pages we're using
@@:
	 mov	 [edx].CB_HPAGE_B0,eax	; Remember the page handle (or NULL)
CVSV_SKIPB0:

; Map in the NUL page and get its physical address

	 VMMcall _GetNulPageHandle	; ... into EAX

	 sub	 ecx,ecx		; A handy zero
;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Page offset
;				|    |	  |    |  |    Flags
;				|    |	  |    |  |    |
	 VMMcall _MapIntoV86, <eax, ebx, 0A0h, 1,ecx, ecx>

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 lea	 edx,[edx].CB_PTE_A0_NUL ; EDX ==> save area for _CopyPageTable
	 push	 edx			; Save around C call

	 sub	 ecx,ecx		; A handy zero
	 mov	 eax,[ebx+CB_High_Linear] ; Offset to VM's address space
	 add	 eax,0A0000h		; Plus the offset of the video
	 shr	 eax,(12-0)		; Convert from linear address to page #
	 VMMcall _CopyPageTable,<eax,1,edx,ecx>
	 pop	 edx			; Restore after C call

	 mov	 eax,[edx]		; Pick up NUL page PTE
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address
	 mov	 NUL_PAGE_PTE,eax	; Save it for LCL_DOSMGR_EXEC_VM

; Prepare the B0-B7 pages for their page faults

	 VMMcall _GetNulPageHandle	; ... into EAX

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 cmp	 [edx].CB_NPAGES_B0,0	; Doing anything at B0-B7?
	 je	 short @F		; Skip if not

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _MapIntoV86,<eax,ebx,0B0h,<[edx].CB_NPAGES_B0>,ecx,ecx>

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _ModifyPageBits,<ebx,0B0h,<[edx].CB_NPAGES_B0>,<NOT P_AVAIL>,ecx,PG_HOOKED,ecx>
@@:

VCVM_XDOSMAX:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_CREATEVM		; End DOSMAX_CREATEVM procedure
;;;;;;	 page
;;;;;;BeginProc DOSMAX_5802			; Handle 5802/5803 in DOSMAX VMs
;;;;;;	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
;;;;;;COMMENT|
;;;;;;
;;;;;;	Process INT 21h 5802 and 5803 call from DOSMAXs
;;;;;;
;;;;;;Entry:
;;;;;;	EAX =	Interrupt # (21h)
;;;;;;	EBX =	VM Handle
;;;;;;	EBP ==> Client register structure
;;;;;;
;;;;;;Exit:
;;;;;;	All registers preserved.
;;;;;;
;;;;;;	Carry set if the INT 21h hasn't been handled -- pass it down.
;;;;;;	Carry clear if it has.
;;;;;;
;;;;;;|
;;;;;;
;;;;;;	 REGSAVE <edx>			; Save caller's registers
;;;;;;
;;;;;;	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
;;;;;;	 jz	 short SVM58_STC	; Exit if not -- pass the INT 21h down
;;;;;;
;;;;;;	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
;;;;;;	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
;;;;;;	 jz	 short SVM58_STC	; Exit if not -- pass the INT 21h down
;;;;;;
;;;;;;	 BREAK	 SVM58			; Call the debugger FIXME
;;;;;;	 cmp	 [ebp].Client_AX,0	; FIXME just to reference the register
;;;;;;	 cmp	 [ebp].Client_BX,0	; FIXME just to reference the register
;;;;;;
;;;;;;SVM58_CLC:
;;;;;;	 clc				; Return NC -- we've handled the INT 21h
;;;;;;	 jmp	 short SVM58_EXIT	; Rejoin common exit code
;;;;;;
;;;;;;SVM58_STC:
;;;;;;	 stc				; Return CY -- pass the INT 21h down
;;;;;;
;;;;;;SVM58_EXIT:
;;;;;;	 REGREST <edx>			; Restore caller's registers
;;;;;;	 ret				; Return to caller
;;;;;;
;;;;;;	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
;;;;;;EndProc  DOSMAX_5802			; End DOSMAX_5802 procedure
	 page
BeginProc SuspendIfNotRegistered	; Bitch if QPopup isn't running
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Check for a registered QPopup callback
	Tell 'em the bad news via SHELL_Message if QPopup isn't running
	Suspend the VM

|

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 short SINR_EXIT	; Exit if not

	 cmp	 QPOPUP_CALLBACK.FSEL,0 ; Is there a callback?
	 jne	 short SINR_EXIT	; Skip if QPopup is installed

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SuspendIfNotRegistered_NoCallback

	 mov	 eax,MB_OKCANCEL or MB_ICONEXCLAMATION or MB_DEFBUTTON2
	 mov	 edi,OFFSET32 MSG_NOQPOPUP_CAPTION ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_NOQPOPUP_TEXT  ; ECX ==> message text
	 mov	 esi,OFFSET32 NOQPOPUP_CB ; ==> callback routine
	 mov	 edx,ebx		; VM_Handle is reference data
	 VxDcall SHELL_Message		; Put up a message box

	 VMMcall Suspend_VM		; Stop the VM

SINR_EXIT:
	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SuspendIfNotRegistered 	; End SuspendIfNotRegistered procedure
	 page
BeginProc NOQPOPUP_CB			; Callback for SHELL_Message
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Callback procedure for SHELL_Message

	Either terminate or resume the VM, depending on which button
	the user clicked.

Entry:
	EAX	=	Response code from message box
	EDX	=	Reference data (VM_Handle)

|

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SHELL_Message_Callback

	 REGSAVE <ebx>			; Save caller's registers

	 mov	 ebx,edx		; VM_Handle to terminate or resume

	 VMMcall Validate_VM_Handle	; Return CY if EBX isn't a valid handle
	 jnc	 short @F		; Skip error

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,SHELL_Message_Callback_BadVMHandle
@@:

; Resume the VM if they clicked 'OK'

	 cmp	 eax,IDOK		; Did they click 'OK'?
	 jne	 short NOQPOPUP_CB_XOK	; Jump if not

	 VMMcall Resume_VM		; Resume the VM

	 jmp	 short NOQPOPUP_CB_EXIT ; Rejoin common code

; They clicked 'Cancel'

NOQPOPUP_CB_XOK:
	 sub	 eax,eax		; Don't wait before terminating
	 sub	 ecx,ecx		; Flags - Don't continue executing
	 VMMcall Nuke_VM		; Terminate the VM

NOQPOPUP_CB_EXIT:
	 REGREST <ebx>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  NOQPOPUP_CB			; End NOQPOPUP_CB procedure
	 page
BeginProc DOSMAX_DESTROYVM		; DOSMAX related Destroy_VM processing
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Do per VM processing related to DOSMAX:

	Free pages

On entry:

EBX	=	VM handle

|

	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 near ptr VDVM_XDOSMAX	; Skip if not

	pushad				; Save all EGP registers

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_Destroy_VM

	 and	 SVM_FLAG,(not @SVM_DOSMAX_REQ) ; Kill DOSMAX required

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

; Get rid of the blocking semaphore, if any

	 mov	 eax,[edx].CB_SEMAPHORE ; Handle of semaphore (or NULL)
	 or	 eax,eax		; Has a semaphore been allocated
	 jz	 short @F		; Skip free if not

	REGSAVE <ebx,edx>		; Save register near and dear
	 VMMcall Destroy_Semaphore	; Free the semaphore's memory
	REGREST <edx,ebx>		; Restore to our heart
@@:
	mov	[edx].CB_NPAGES_A0,0	; Zero # of pages in A0-AF
	mov	[edx].CB_NPAGES_B0,0	; ...		     B0-BF

; FIXME Do we need to unmap the block before freeing it?
; This seems to work OK

	 mov	 eax,[edx].CB_HPAGE_A0	; Page handle for A0-AF
	 or	 eax,eax		; Is it NULL?
	 jz	 short @F		; Skip the _PageFree if so

	push	ebx			; Save register near and dear
	 VMMcall _PageFree,<eax>	; Free the pages
					; Ignore the error
	pop	ebx			; Restore
@@:
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 mov	 eax,[edx].CB_HPAGE_B0	; Page handle for B0-B7
	 or	 eax,eax		; Is it NULL?
	 jz	 short @F		; Skip the _PageFree if so

;;;;;;; REGSAVE <ebx,edx>		; Save register near and dear
	 VMMcall _PageFree,<eax>	; Free the pages
					; Ignore the error
;;;;;;; REGREST <edx,ebx>		; Restore to our heart
@@:
	popad				; Restore
VDVM_XDOSMAX:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_DESTROYVM		; End DOSMAX_DESTROYVM procedure
	 page
BeginProc DOSMAX_VMNOTEXECUTEABLE	; Handler for VM_Not_Executeable call
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

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_VM_Not_Executeable

	 and	 SVM_FLAG,(not @SVM_DOSMAX_REQ) ; Kill DOSMAX required

	 clc			; Normal exit indicator

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DOSMAX_VMNOTEXECUTEABLE ; End DOSMAX_VMNOTEXECUTEABLE procedure
	 page
BeginProc LCL_HOOK_V86_PAGE	; Local handler for Hook_V86_Page
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Watch for the VDD hooking pages A0-AF.	Insert our own local
	handler while remembering the VDD's callback address.

ON ENTRY:
	EAX	=	Page # to hook
	ESI	==>	Callback procedure

On EXIT:
	Carry clear to indicate the hook has been installed.

|

	 test	 SVM_FLAG,@SVM_VDDPF	; Is VDD_PFault hooked?
	 jnz	 short LHVP_CHAIN	; Skip if so

	 cmp	 eax,0A0h		; Is it below a video graphics page?
	 jb	 short LHVP_CHAIN	; Chain to original handler if not

	 cmp	 eax,0AFh		; Is it above a video graphics page?
	 ja	 short LHVP_CHAIN	; Chain to original handler if not

	BREAK	DBG_FLAG,@DBG_DOSMAX,DOSMAX_LCL_Hook_V86_Page

	 or	 SVM_FLAG,@SVM_VDDPF	; Remember VDD_PFault is hooked

	 mov	 OLD_VDD_PF_HOOK,esi	; Remember the address of the VDD's hook
	 mov	 esi,OFFSET32 LCL_VDD_PF_HOOK ; Switch to our own

LHVP_CHAIN:
	 jmp	 OLD_HOOK_V86_PAGE	; Call the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_HOOK_V86_PAGE	; End LCL_HOOK_V86_PAGE procedure

BeginProc LCL_VDD_PF_HOOK	; Local replacement for VDD_PFault hook
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY:
	EAX	=	Faulting page #
	EBX	=	Current VM handle

On EXIT:
	The PTE has been corrected, or the VM destroyed

|

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jz	 LVPH_CHAIN		; Chain to the original if so

	 cmp	 eax,0A0h		; Is it below a video graphics page?
	 jb	 LVPH_CHAIN		; Chain to original handler if not

	 cmp	 eax,0AFh		; Is it above a video graphics page?
	 ja	 LVPH_CHAIN		; Chain to original handler if not

	 push	 edx			; Save VMM's registers
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 test	 [edx].CB_wFlags,@CBF_IGNOREA0 ; Ignore page faults from A0?
	 pop	 edx			; Restore VMM's registers
	 jnz	 LVPH_CHAIN		; Chain to original handler if so

; We've got a V86 page fault on a video graphics page in other than the Sys_VM.
; Call the original VDD_PFault handler to process it.  Then check for the
; NUL page being mapped into the page tables.  If other than the NUL page
; is mapped in, the VDD is processing an INT 10h for a font change.

; Set a flag to modify the behavior of our CopyPageTable handler to avoid
; infinitely recursive page faults from eating the stack.

;;;;;;;; BREAK	 DBG_FLAG,@DBG_DOSMAX,Calling_OLD_VDD_PF_HOOK

	 or	 SVM_FLAG,@SVM_PAGEFAULT ; Remember page faults are with the VDD

	 pushad 			; Save caller's registers
	 call	 OLD_VDD_PF_HOOK	; Call the VDD's original handler
	 popad				; Restore caller's registers

	 and	 SVM_FLAG,(not @SVM_PAGEFAULT) ; No page faults from within VDD

;;;;;;	 BREAK	 DBG_FLAG,@DBG_DOSMAX,BackFrom_LCL_VDD_PF_HOOK

; FIXME Does this code need to be in a critical section?  The VDD's is...

; EAX = faulting page #

	 push	 eax			; Save faulting page #

	 mov	 VDD_PF_PAGE,eax	; Save faulting page #

	 sub	 eax,0A0h		; Remove A0 bias

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 cmp	 eax,[edx].CB_NPAGES_A0 ; Is it a page we're handling?
					; Note flags cross the POP
	 pop	 eax			; Restore faulting page #
	 jae	 LVPH_RET		; Exit if not

	 shl	 eax,(12-0)		; Convert from page # to linear address
	 add	 eax,[ebx+CB_High_Linear] ; Offset to VM's address space
	 shr	 eax,(12-0)		; Convert from linear address to page #

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 lea	 edx,[edx].CB_PTE_A0_VDD ; EDX ==> save area for _CopyPageTable

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _CopyPageTable,<eax,1,edx,ecx>

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 mov	 eax,[edx].CB_PTE_A0_NUL ; Original PTE from NUL page
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address

	 mov	 edx,[edx].CB_PTE_A0_VDD ; PTE after VDD handled the page fault
	 and	 edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address

	 cmp	 eax,edx		; Is it the NUL page?
	 jne	 short LVPH_RET 	; Exit if not

;;;;;;	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_VDD_PF_HOOK_Map

; Map in the 'correct' DOSMAX page

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 sub	 ecx,ecx		; A handy zero
	 mov	 eax,VDD_PF_PAGE	; Faulting page #
	 sub	 eax,0A0h		; Remove A0 bias
;			       Physical page #
;			       |		  VM Handle
;			       |		  |   V86 page #
;			       |		  |   | 	  # of pages
;			       |		  |   | 	  | Page offset
;			       |		  |   | 	  | |	Flags
;			       |		  |   | 	  | |	|
	 VMMcall _MapIntoV86,<<[edx].CB_HPAGE_A0>,ebx,VDD_PF_PAGE,1,eax,ecx>

LVPH_RET:
	 ret				; Return to caller

LVPH_CHAIN:
	 or	 SVM_FLAG,@SVM_PAGEFAULT ; Remember page faults are with the VDD
	 call	 OLD_VDD_PF_HOOK	; Transfer to the VDD's original handler
	 and	 SVM_FLAG,(not @SVM_PAGEFAULT) ; No page faults from within VDD
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_VDD_PF_HOOK	; End LCL_VDD_PF_HOOK procedure
	 page
BeginProc LCL_DOSMGR_EXEC_VM	; Local handler for _DOSMGR_Exec_VM
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY: (on the stack)
	VM handle
	V86Size 	# of pages above GetFirstV86Page to set INT 12h value
	Callback	==> to VM exit callback procedure
	RefData 	Reference data passed to callback procedure

On EXIT:

|

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_DOSMGR_ExecVM

	 push	 ebp			; Save previous frame pointer
	 mov	 ebp,esp		; Address the stack

LDEV_STR	 struc			; Access to _DOSMGR_Exec_VM arguments
		 dd	?		; Caller's EBP
		 dd	?		; Caller's EIP
    LDEV_VM	 dd	?		; VM handle
    LDEV_V86SIZE dd	?		; Size for INT 12h, less GetFirstV86Page
    LDEV_CALLBACK dd	?		; ==> VM exit callback procedure
    LDEV_REFDATA dd	?		; Reference data for callback
LDEV_STR	 ends			; End LDEV_STR structure

	 push	 ebx			; Save caller's register

	 mov	 ebx,[ebp].LDEV_VM	; Get target VM handle
	 VMMcall Test_Sys_VM_Handle	; Is it the system VM?

	 pop	 ebx			; Restore caller's register
	 jz	 LDEV_CHAIN		; Pass on to DOSMGR if so

	 REGSAVE <eax,edx>		; Save caller's registers

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

; If this is Win95 and we were not called at DOSMAX_Callback, then
; this VM uses the default settings

	cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
	jb	short @F		; Jump if not

	test	[edx].CB_wFlags,@CBF_DOSMAX_CALLBACK ; Has it been called?
	jnz	short @F		; Jump if so (already handled)

	test	SVM_FLAG,@SVM_DOSMAX_DEF ; All VMs are DOSMAXs?
	jnz	short @F		; Jump if so (already handled)

	call	DOSMAX_SetOff		; Turn off DOSMAX settings for this VM
@@:
	 mov	 eax,[edx].CB_NPAGES_A0 ; # of pages in A0-AF
	 add	 eax,[edx].CB_NPAGES_B0 ; Plus # of pages in B0-B7

	 add	 [ebp].LDEV_V86SIZE,eax ; Update the VM's new size

	 REGREST <edx,eax>		; Restore caller's registers

	 pop	 ebp			; Restore previous stack frame

	 pop	 [DOSMGR_CALLER]	; Save return address
	 call	 OLD_DOSMGR_EXEC_VM	; 'Call' the original handler
	 push	 [DOSMGR_CALLER]	; Replace return address

; Now that the DOSMGR has done its thing, we've got some clean up to do.

	 push	 ebp			; Save previous frame pointer
	 mov	 ebp,esp		; Address the stack

	 REGSAVE <eax,ebx,ecx,edx,esi>	; Save caller's registers

; Due to a (nother) bug in VMM (or maybe it's DOSMGR) if there isn't enough
; memory (physical or virtual) to fill in the base 640K region, no error will
; be reported back to the user.  COMMAND.COM or whatever gets loaded into
; the NUL pages will crash.  Make sure all of low DOS is mapped in.  If it
; isn't, set a bit so ZMAX can return carry from its VM_INIT event.  This
; will result in WINOLDAP telling the user there wasn't enough memory.
; Check the pages at both 9E and 9F, because under certain conditions, VMM
; seems to fill in 9F before any other page.

	 mov	 ebx,[ebp].LDEV_VM	; Get target VM handle
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 LDEV_EXIT		; Skip these patches if not

	 sub	 esp,4			; Make room for 1 PTE

	 mov	 edx,esp		; EDX ==> save area for _CopyPageTable
	 sub	 ecx,ecx		; A handy zero
	 mov	 eax,[ebx+CB_High_Linear] ; Offset to VM's address space
	 add	 eax,09EFFFh		; Plus the end of low DOS
					; less the last 4K block holding the
					; spanning entry
	 shr	 eax,(12-0)		; Convert from linear address to page #
	 VMMcall _CopyPageTable,<eax,1,edx,0>

	 mov	 eax,NUL_PAGE_PTE	; PTE for the NUL page
	 mov	 edx,[esp]		; PTE for page at 9EFFF
	 and	 edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address
	 cmp	 eax,edx		; NUL page at 9EFFF?
	 jne	 short @F		; Skip if not

	 or	 SVM_FLAG,@SVM_NOBASEMEM ; Fail VM_INIT in ZMAX
@@:
	 mov	 edx,esp		; EDX ==> save area for _CopyPageTable
	 sub	 ecx,ecx		; A handy zero
	 mov	 eax,[ebx+CB_High_Linear] ; Offset to VM's address space
	 add	 eax,09FFFFh		; Plus the end of low DOS
	 shr	 eax,(12-0)		; Convert from linear address to page #
	 VMMcall _CopyPageTable,<eax,1,edx,0>

	 mov	 eax,NUL_PAGE_PTE	; PTE for the NUL page
	 mov	 edx,[esp]		; PTE for page at 9FFFF
	 and	 edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address
	 cmp	 eax,edx		; NUL page at 9FFFF?
	 jne	 short @F		; Skip if not

	 or	 SVM_FLAG,@SVM_NOBASEMEM ; Fail VM_INIT in ZMAX
@@:
	 add	 esp,4			; Strip PTE from the stack

; Fixup the MAC chain so the last arena entry points backwards to the
; spanning entry
	 cmp	 DOSUMB_MAC,0		; DOS=UMB or 386MAX 5802 support?
	 je	 LDEV_EXIT		; Exit if not

; Fix the end of the DOS arena if 5802 support is provided

	 mov	 esi,[ebx+CB_High_Linear] ; ESI ==> VMs address space
	 movzx	 eax,ARENA_ANCHOR	; Segment of 1st MAC entry
LDEV_NXTMAC:
	 movzx	 ebx,ax 		; Segment of MAC entry
	 shl	 ebx,(4-0)		; Convert from paras to linear address

	 inc	 ax			; Bump segment to actual block

	 cmp	 [esi+ebx].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short LDEV_ZMAC	; Exit loop if so

	 cmp	 [esi+ebx].MAC_TYPE,@MAC_MID ; Middle entry?
	 je	 short @F		; Skip error code if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,DOSMGR_EXEC_VM_ARENATRASHED
	 jmp	 short LDEV_XMAC	; Forget the whole thing if the arena
					; is trashed.
@@:
	 add	 ax,[esi+ebx].MAC_NPAR	; Bump AX to segment of next MAC entry
	 jmp	 short LDEV_NXTMAC	; Continue on to next entry

; AX = segment of 'Z' MAC entry's data block, EBX = linear address
LDEV_ZMAC:
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,FIX_DOSUMB

	 add	 ax,[esi+ebx].MAC_NPAR	; Bump AX to segment of next MAC entry
	 cmp	 ax,DOSUMB_MAC		; Does it point to the spanning MAC?
	 je	 short @F		; Skip if so

; We've found the 'Z' entry and it points to the spanning entry.
; Form the spanning entry into the real McCoy unless there's no high DOS

	 movzx	 ebx,ax 		; Segment of MAC entry
	 shl	 ebx,(4-0)		; Convert from paras to linear address

	 sub	 ecx,ecx		; A handy zero
	 mov	 [esi+ebx].MAC_BACK,cx	; Zero the back link
	 mov	 [esi+ebx].MAC_DRV,cl	; Block device driver starting drive #

; Fill in 'SC', 6 dup (0)
	 mov	 [esi+ebx].MAC_NAME.EDD,ecx ; Program name
	 mov	 [esi+ebx+4].MAC_NAME.EDD,ecx ; ...
	 mov	 [esi+ebx].MAC_NAME.ELO,'CS' ; ...

	 mov	 [esi+ebx].MAC_TYPE,@MAC_END ; Kill the entry, assuming NOHIGH

	 cmp	 OVRMAC,-1		; Is there any high DOS?
	 je	 short @F		; Skip fixup if not

	 mov	 [esi+ebx].MAC_TYPE,@MAC_MID ; Enable the spanning entry

	 sub	 ax,OVRMAC		; Distance to next MAC
	 not	 ax			; ... less the MAC entry itself
	 mov	 [esi+ebx].MAC_NPAR,ax	; Fixup the length
@@:
LDEV_XMAC:

LDEV_EXIT:
	 REGREST <esi,edx,ecx,ebx,eax>	; Restore caller's registers
	 pop	 ebp			; Restore previous stack frame

	 ret				; Return to caller (SHELL VxD)

LDEV_CHAIN:
	 pop	 ebp			; Restore previous stack frame

	 jmp	 OLD_DOSMGR_EXEC_VM	; Jump to the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_DOSMGR_EXEC_VM		; End LCL_DOSMGR_EXEC_VM procedure
	 page
BeginProc LCL_VDD_PIF_STATE		; Local handler for VDD_PIF_State
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	This call is made by SHELL [3] (Crt_VM from WINOLDAP).	We use it
	to get control before the SHELL does the VMMcall System_Control(7)
	to fetch and save the name of the .PIF.  This is done while the
	Sys_VM is executing.

	This call is also made by SHELL (9) with EBX identifying the newly
	created VM.  We ignore this call.

ON ENTRY:
	EBX =	Sys_VM handle
	EBP ==> Sys_VM client register structure
	AX  =	PIF bits, defined in VDD.INC

	ESI ==> Data within WINOLDAP's data segment

	[ESI+4] = PIF.H pif386.VidFlags
	[ESI+04B8] is a buffer containing the name of the .PIF.

On EXIT:

|

	 test	 PMI_FLAG,@PMI_SYSVM	; Have we already seen Sys_VM_Init?
	 jz	 LVPS_EXIT		; Exit immediately if not

	 VMMcall Test_Sys_VM_Handle	; Return ZF if EBX is Sys_VM
	 jnz	 LVPS_EXIT		; Exit immediately if not the Sys_VM

	 pushad 			; Save caller's registers

	 and	 SVM_FLAG,(not @SVM_DOSMAX_REQ) ; Assume normal VM
	 mov	 DOSMAX,640		; Size for default DOSMAX

; Last chance check on the buffer
; If it's not allocated, bug out and use a normal VM
	 cmp	 GLOBAL_V86_LIN,0	; Downstairs buffer allocated?
	 jz	 LVPS_EXIT0		; Rejoin common code

	cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
	jae	LVPS_95 		; Jump if so (assume DOSMAX forced ON
					; for this VM)
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

; Sanity check on WINOLDAP DGROUP
	 cmp	 [esi+4],ax		; Do the PIF bits match?
	 je	 short @F		; Skip error if so

; FIXME put a message up here
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_VDD_PIF_STATE_BadBits
	 jmp	 LVPS_EXIT0		; Rejoin commom code
@@:

; Copy the filespec of the default .QPE on speculation that it'll be needed
	 push	 esi			; Save ==> into WINOLDAP
	 mov	 ecx,(size szDefaultQPE) ; Maximum length of filespec
	 lea	 esi,szDefaultQPE	; ==> default .QPE filespec
	 mov	 edi,GLOBAL_V86_LIN	; ==> downstairs buffer
	 cld				; Autoincrement
     rep movsb				; Copy the filespec
	 pop	 esi			; Restore ==> into WINOLDAP

; Sanity check on the filename
; If the filename doesn't look like D:\path\filename.PIF, use the default QPE
	 cmp	 [esi+@WINOLDAP_PIFNAME+1].LO,':' ; 2nd char should be a colon
	 je	 short @F		; Skip error if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,NoFilenameColon
	 jmp	 short LVPS_OPEN	; Jump to open the file
@@:

; Copy the .PIF filename to our local buffer
	 mov	 ecx,(size szPIFName)	; Length of filename
	 lea	 edi,szPIFName		; ==> local .PIF filename
	 lea	 esi,[esi+@WINOLDAP_PIFNAME] ; ==> .PIF filename in WINOLDAP
	 cld				; Autoincrement
@@:
	 lodsb				; Pick up character of name
	 stosb				; Save it

	 or	 al,al			; Is it the NUL?
	 jne	 short @B		; Get 'em all

; EDI should be pointing just past '.PIF', 0
; Check it and then change '.PIF' to '.QPE'

	 sub	 edi,5			; EDI ==> '.PIF', 0
	 cmp	 dword ptr [edi],'FIP.' ; Does it match?
	 je	 short @F		; Skip error if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,NoDotPIF
	 jmp	 short LVPS_OPEN	; Jump to open the file
@@:
	 mov	 dword ptr [edi],'EPQ.' ; Change '.PIF' to '.QPE'

; Copy the .QPE filename downstairs
	 mov	 ecx,(size szPIFName)	; Length of filename
	 mov	 edi,GLOBAL_V86_LIN	; ==> downstairs buffer
	 lea	 esi,szPIFName		; ==> .QPE filename
     rep movsb				; Copy the filename downstairs

LVPS_OPEN:
	 mov	 PIF_HANDLE,0		; Assume the file isn't open

	 mov	 ecx,(Block_Svc_If_Ints_Locked OR Block_Enable_Ints)
	 VMMcall Begin_Critical_Section

	 Push_Client_State		; Save client's register structure
	 VMMcall Begin_Nest_V86_Exec	; Switch VM to V86 mode

; Open the .QPE file
	 mov	 [ebp].Client_AX,(@OPENF2 shl 8) or 0 ; Open file, readonly

	 mov	 eax,GLOBAL_V86_VEC	; Segment:offset of global V86 data area
	 mov	 [ebp].Client_DX,ax	; Blast offset into client's DX
	 shr	 eax,16 		; Move segment to low-order end
	 mov	 [ebp].Client_DS,ax	; Blast in segment

	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call

; If we can't open the QPE file we'll use the DOSMAXDefault= setting
	 test	 [ebp].Client_Flags,(mask $CF) ; Check carry flag for errors
	 jz	 short LVPS_OPENED	; Skip default checking if opened

	 test	 SVM_FLAG,@SVM_DOSMAX_DEF ; All VMs are DOSMAXs?
	 jz	 LVPS_ENDNEST		; Exit if not
LVPS_95A:
	 mov	 ax,-1			; No QPE, and DOSMAXDefault=ON is -1
	 jmp	 LVPS_ISBIG		; Rejoin common code to provide DOSMAX

LVPS_95:
	cmp	QPOPUP_CALLBACK.FSEL,0	; Is there a callback registerd as yet?
	jne	short LVPS_95A		; Jump if so (continue normally)

	mov	ax,640			; Use normal size

	jmp	LVPS_ISBIG		; Rejoin common code to provide DOSMAX

LVPS_OPENED:
	 mov	 ax,[ebp].Client_AX	; Pick up the handle
	 mov	 PIF_HANDLE,ax		; Save file handle

; Read the .QPE file
;;;;;;;  mov	 ax,PIF_HANDLE		; Pick up the handle
	 mov	 [ebp].Client_BX,ax	; File handle
	 mov	 [ebp].Client_AX,(@READF2 shl 8) ; Read from file or device

	 mov	 [ebp].Client_CX,(type QPE_STR) ; Length of file

	 mov	 eax,GLOBAL_V86_VEC	; Segment:offset of global V86 data area
	 mov	 [ebp].Client_DX,ax	; Blast offset into client's DX
	 shr	 eax,16 		; Move segment to low-order end
	 mov	 [ebp].Client_DS,ax	; Blast in segment

	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call

	 test	 [ebp].Client_Flags,(mask $CF) ; Check carry flag for errors
	 jz	 short @F		; Skip error if carry clear

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_VDD_PIF_STATE_QPE_ReadFailed

	 mov	 edi,OFFSET32 MSG_CAP_BADQPE ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_TXT_BADQPEREAD ; ECX ==> message text
	 mov	 eax,MB_OKCANCEL or MB_ICONEXCLAMATION or MB_DEFBUTTON2
	 call	 ShellMessage		; EDX ==> caption, ECX ==> message

	 jmp	 LVPS_ENDNEST		; Exit --use a normal VM

@@:
	 cmp	 [ebp].Client_AX,(type QPE_STR) ; Did we read it all?
	 je	 short @F		; Skip error if sizes match

	 BREAK	 DBG_FLAG,@DBG_DOSMAX	; Call the debugger

	 mov	 edi,OFFSET32 MSG_CAP_BADQPE ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_TXT_BADQPELEN ; ECX ==> message text
	 mov	 eax,MB_OKCANCEL or MB_ICONEXCLAMATION or MB_DEFBUTTON2
	 call	 ShellMessage		; EDX ==> caption, ECX ==> message

	 jmp	 LVPS_ENDNEST		; Exit -- use a normal VM

@@:
	 mov	 esi,GLOBAL_V86_LIN	; ESI ==> QPE_STR in downstairs buffer
	 cmp	 [esi].QPE_cSig,'FIPQ'  ; Signature should be 'QPIF'
	 je	 short @F		; Skip error if signature is OK

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_VDD_PIF_STATE_BadQPEMagic

	 mov	 edi,OFFSET32 MSG_CAP_BADQPE ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_TXT_BADQPEMAGIC ; ECX ==> message text
	 mov	 eax,MB_OKCANCEL or MB_ICONEXCLAMATION or MB_DEFBUTTON2
	 call	 ShellMessage		; EDX ==> caption, ECX ==> message

	 jmp	 short LVPS_ENDNEST	; Exit -- use a normal VM

@@:
	 cmp	 [esi].QPE_bVersion,1	; Version 1?
	 je	 short @F		; Skip error if version 1

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_VDD_PIF_STATE_BadQPEVersion

	 mov	 edi,OFFSET32 MSG_CAP_BADQPE ; EDI ==> caption
	 mov	 ecx,OFFSET32 MSG_TXT_BADQPEVER ; ECX ==> message text
	 mov	 eax,MB_OKCANCEL or MB_ICONEXCLAMATION or MB_DEFBUTTON2
	 call	 ShellMessage		; EDX ==> caption, ECX ==> message

	 jmp	 short LVPS_ENDNEST	; Exit -- use a normal VM

@@:
	 test	 [esi].QPE_Flags1,@QPE_OFF ; Is 'Force OFF' in effect?
	 jnz	 short LVPS_ENDNEST	; Exit if so -- use a normal VM

	 test	 [esi].QPE_Flags1,@QPE_ON ; Is 'ON' in effect?
	 jnz	 short @F		; Jump if so -- use a DOSMAX VM

	 test	 SVM_FLAG,@SVM_DOSMAX_DEF ; All VMs are DOSMAXs?
	 jz	 short LVPS_ENDNEST	; Exit if not -- use a normal VM
@@:
	 mov	 ax,[esi].QPE_DosMax	; Requested size of VM in KB

; Process the requested size.  If it's -1, make it 736K.
; If it's 640K or less, leave it as-is, and don't enable the DOSMAX.
; Otherwise, round it up to the next 4K boundary and enable the DOSMAX.

LVPS_ISBIG:
	 cmp	 ax,-1			; Is it -1?
	 jne	 short @F		; Skip if not

	 mov	 ax,736 		; Try for 736K
@@:
	 cmp	 ax,640 		; Is it at least 640K?
	 jbe	 short @F		; Skip if so

	 or	 SVM_FLAG,@SVM_DOSMAX_REQ ; Remember for Create_VM, etc.

	 add	 ax,3			; Round up to the next 4K boundary
	 and	 al,-4			; ...

	 mov	 DOSMAX,ax		; Remember for Create_VM, etc.
@@:

LVPS_ENDNEST:
	cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
	jae	LVPS_EXIT0		; Jump if so (no nesting to end)

; Close the .QPE file

	 mov	 ax,PIF_HANDLE		; Pick up the handle
	 or	 ax,ax			; Is it open?
	 jz	 short @F		; Skip close if not

	 mov	 [ebp].Client_BX,ax	; File handle
	 mov	 [ebp].Client_AX,(@CLOSF2 shl 8) ; Close file

	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call
@@:
	 VMMcall End_Nest_Exec		; Restore VM to original state
	 Pop_Client_State		; Restore client's register structure

	 VMMcall End_Critical_Section

LVPS_EXIT0:
	 popad				; Restore caller's registers

; As we don't know at this point whether or not we're to provide
; DOSMAX services if Win95, we default to the positive

;;;;;;; cmp	WIN3_VERSION,0400h	; Izit Win95 or later?
;;;;;;; jae	short LVPS_EXIT1	; Jump if so
;;;;;;;
	 test	 SVM_FLAG,@SVM_DOSMAX_REQ ; DOSMAX requested?
	 jz	 short @F		; Skip if not
LVPS_EXIT1:
	 or	 ax,fVidHghRsGrfxMd	; Reserve high graphics mode memory
	 and	 ax,(not fVidNoTrpTxt)	; Monitor text port
@@:

LVPS_EXIT:
	 jmp	 OLD_VDD_PIF_STATE	; Chain to the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_VDD_PIF_STATE		; End LCL_VDD_PIF_STATE procedure
	 page
BeginProc LCL_AGV86DA			; Local handler for _Allocate_V86_Data_Area
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Local handler for Allocate Global V86 Data Area services.

Because of an alignment bug in the internal VPOWERD driver in Win95's
VMM32.VxD, we need to hook this service and promote the alignment for
at least their calls to this service from dword to para.  The VPOWERD
code requests dword alignment, but their use of the resulting data
area actually requires para alignment.

|

AGV86DA_STR struc

	dd	?	; Caller's EIP
AGV86DA_nBytes dd ?	; # bytes to allocate
AGV86DA_flags  dd ?	; flags (see GVDAxxx for meaning)

AGV86DA_STR ends

	test	[esp].AGV86DA_flags,GVDADWordAlign ; Izit dword-aligned?
	jz	short @F		; Jump if not

	xor	[esp].AGV86DA_flags,GVDADWordAlign or GVDAParaAlign ; Now it's para-aligned
@@:
	jmp	OLD_AGV86DA		; Chain to the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_AGV86DA			; End LCL_AGV86DA procedure
	 page
BeginProc LCL_COPY_PAGE_TABLE		; Local handler for _CopyPageTable
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Local handler for _CopyPageTable service.  Under certain conditions,
	the DMA device may be called upon to lock a region that includes
	DOSMAX pages that aren't yet mapped in.  We'll weed out those cases
	here and simulate the call.

	By inspection, I've determined that the VDMAD only makes the call for
	one page at a time.  Only that case is handled.

	I believe VMM won't switch VMs while it's in the middle of handling
	a page fault, so I'm not using per-VM flags in here.

ON ENTRY: (on the stack)
	LinPgNum	Page # of 1st PTE to copy
	nPages		# of PTEs to copy
	PageBuf 	==> buffer to hold PTEs
	flags		Reserved flags -- must be zero

On EXIT:

|

	 push	 ebp			; Save previous frame pointer
	 mov	 ebp,esp		; Address the stack

LCPT_STR	 struc			; Access to _CopyPageTable arguments
		 dd	?		; Caller's EBP
		 dd	?		; Caller's EIP
    LCPT_LinPgNum dd	?		; 1st page #
    LCPT_nPages dd	?		; # of PTEs to copy
    LCPT_PageBuf dd	?		; ==> output buffer
    LCPT_flags dd	?		; flags -- must be zero
LCPT_STR	 ends			; End LCPT_STR structure

	 test	 SVM_FLAG,@SVM_PAGEFAULT ; Within a video page fault from VDD?
	 jnz	 LCPT_NESTED		; If so, let VMM handle it

	 cmp	 [ebp].LCPT_nPages,1	; Asking for one PTE only?
	 jne	 LCPT_NOT1		; Let the original handler process it

	 cmp	 [ebp].LCPT_flags,0	; Zero flags?
	 jne	 LCPT_FLAGS		; Let the original handler process it

	 REGSAVE <eax,ebx,edx>		; Save caller's registers

	 mov	 eax,[ebp].LCPT_LinPgNum ; Get linear page #
	 shl	 eax,(12-0)		; Convert from page # to linear address
	 and	 eax,(not 000FFFFFh)	; Isolate the CB_High_Linear part
	 jz	 LCPT_CHAIN_POP 	; Looking for the current mapping

	 mov	 edx,eax		; Save high linear offset

	 mov	 eax,[ebp].LCPT_LinPgNum ; Get linear page #
	 and	 eax,0FFh		; Isolate the page in the 1st meg
	 cmp	 eax,0A0h		; Is it below a DOSMAX page?
	 jb	 LCPT_CHAIN_POP 	; Not for us if so

	 cmp	 eax,0B7h		; Is it above a DOSMAX page?
	 ja	 short LCPT_CHAIN_POP	; Not for us if so

; Trundle the list of VMs, looking for the one with the right CB_High_Linear
	 VMMcall Get_Sys_VM_Handle	; EBX = Sys_VM_Handle
@@:
	 cmp	 edx,[ebx+CB_High_Linear] ; Same high linear offset?
	 je	 short @F		; Exit loop if so (EBX = VM handle)

	 VMMcall Get_Next_VM_Handle	; EBX = next VM handle in list
	 VMMcall Test_Sys_VM_Handle	; Have we wrapped the list?
	 jne	 short @B		; Test next VM if not

;;;;;;;; BREAK	 DBG_FLAG,@DBG_DOSMAX,Bad_High_Linear
	 jmp	 short LCPT_CHAIN_POP	; CB_High_Linear doesn't exist
@@:

; EBX = handle of VM with the matching high linear offset
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 short LCPT_CHAIN_POP	; Not for us if not

	 mov	 eax,[ebp].LCPT_LinPgNum ; Get linear page #
	 and	 eax,0FFh		; Isolate the page in the 1st meg
	 sub	 eax,0A0h		; Remove A0 bias

	 cmp	 eax,[edx].CB_NPAGES_A0 ; Is it a page we're handling in A0-AF?
	 jb	 short LCPT_GOTONE	; Jump if so

LCPT_CHECK_B0:
	 cmp	 [edx].CB_NPAGES_B0,0	; Doing anything at B0-B7?
	 je	 short LCPT_CHAIN_POP	; Not for us if not

	 sub	 eax,10h		; Remove B0 bias
	 cmp	 eax,[edx].CB_NPAGES_B0 ; Doing anything at B0-B7?
	 jae	 short LCPT_CHAIN_POP	; Not for us if not

LCPT_GOTONE:
;;;;;;	 BREAK	 CopyPageTable_GotOne	; It's for us
	 mov	 eax,[ebp].LCPT_LinPgNum ; Get linear page #
	 shl	 eax,(12-0)		; Convert from page # to linear address
	 mov	 al,[eax]		; Touch the page to pull it in

	 jmp	 short LCPT_CHAIN_POP	; Rejoin original handler

LCPT_FLAGS:		; Error case
	 BREAK	 DBG_FLAG,@DBG_DOSMAX,LCL_CopyPageTable_ODD
	 jmp	 LCPT_CHAIN		; Rejoin common code

LCPT_CHAIN_POP:
	 REGREST <edx,ebx,eax>		; Restore caller's registers
LCPT_NESTED:
LCPT_NOT1:
LCPT_CHAIN:
	 pop	 ebp			; Restore previous stack frame

	 jmp	 OLD_COPY_PAGE_TABLE	; Jump to the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_COPY_PAGE_TABLE		; End LCL_COPY_PAGE_TABLE procedure
	 page
BeginProc ShellMessage			; Cover for SHELL_Message
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY:
	EDI	==>	Caption ASCIZ string
	ECX	==>	Message ASCIZ string
	EAX	=	MB_xxx flags

|

	 mov	 esi,OFFSET32 ShellMessageCB ; ==> callback routine
	 VxDcall SHELL_Message		; Put up a message box

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ShellMessage			; End ShellMessage procedure

BeginProc ShellMessageCB		; SHELL_Message Callback Procedure
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 ret				; Return to caller (SHELL_Message)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ShellMessageCB 		; End ShellMessageCB procedure

BeginProc B0_PFAULT			; Page fault hook for B0-B7
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY:
	EAX	=	Faulting page #
	EBX	=	Current VM handle

On EXIT:
	The PTE has been corrected, or the VM destroyed

|

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jz	 B0PF_CHAIN		; Chain to the original if so

;;;;;;	 BREAK	 DBG_FLAG,@DBG_DOSMAX,B0PageFaultNotInSysVM

; Map in the 'correct' page

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _MapIntoV86,<<[edx].CB_HPAGE_B0>,ebx,0B0h,<[edx].CB_NPAGES_B0>,ecx,ecx>

B0PF_CHAIN:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  B0_PFAULT			; End B0_PFAULT procedure
	 page
BeginProc PMAPI_RegisterCallback	; PMAPI_RegisterCallback
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Register the callback address within QPOPUP.EXE.

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_ES:BX	==> callback procedure in QPOPUP.EXE
	Client_DX	=   Sys VM LDT selector of filename intercepts

	The data at DX:0 is formatted like the 386LOAD.CFG file.
	The end is marked with a CTRL+Z and a NUL.

EXIT:
	Client_AX	=	0 if successful

|

	 REGSAVE <fs>		; Save caller's registers

	 mov	 ax,[ebp].Client_ES	; Pick up selector of client's callback
	 mov	 QPOPUP_CALLBACK.FSEL,ax ; Save it

	 movzx	 eax,[ebp].Client_BX	; Pick up offset of client's callback
	 mov	 QPOPUP_CALLBACK.FOFF,eax ; Save it

; Allocate space for the filename intercept data

	 movzx	 edx,[ebp].Client_DX	; Selector of intercept data

	 verr	 dx			; Verify valid for reading
	 jmp	 short $+2		; Avoid 386 errata #20
	 jnz	 short PMAPI_RC_BADSEL	; Error return

	 lsl	 ecx,edx		; Get segment limit into EAX
	 jmp	 short $+2		; Avoid 386 errata #20
	 jnz	 short PMAPI_RC_BADSEL	; Error return

	 inc	 ecx			; Convert limit to length

	 REGSAVE <ecx,edx>		; Save registers wrecked by "C" calls
	 VMMcall _HeapAllocate <ecx, HeapZeroInit>
	 REGREST <edx,ecx>		; Restore registers

	 or	 eax,eax		; Did we get the space?
	 jnz	 short @F		; Yes, so skip the error code

	 BREAK				; Call the debugger FIXME
	 jmp	 short PMAPI_RC_NOSPACE ; Return an error
@@:
	 mov	 INTERCEPTS_LIN,eax	; Save address of filename intercepts

	 mov	 edi,eax		; ES:EDI ==> buffer area

	 mov	 fs,dx			; Selector of intercept data
	 assume  fs:nothing		; Tell the assembler

	 sub	 esi,esi		; FS:ESI ==> filename intercepts
	 shr	 ecx,1			; Convert to # of WORDs
	 cld				; Autoincrement
S32  rep movs	 <es:[edi].ELO,fs:[esi].ELO> ; Copy the WORDs
	 adc	 ecx,ecx		; Count in the odd byte
S32  rep movs	 <es:[edi].LO,fs:[esi].LO> ; Copy the BYTE

	 sub	 ax,ax			; Normal return code
	 jmp	 short PMAPI_RC_EXIT	; Rejoin common exit code

PMAPI_RC_BADSEL:
PMAPI_RC_NOSPACE:
	 mov	 ax,1			; Error code

PMAPI_RC_EXIT:
	 mov	 [ebp].Client_AX,ax	; Normal return indicator in client's AX

	 REGREST <fs>		; Restore caller's registers
	 assume  fs:nothing		; Tell the assembler

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_RegisterCallback 	; End PMAPI_RegisterCallback procedure
	 page
BeginProc PMAPI_UnregisterCallback	; PMAPI_UnregisterCallback
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Unregister the callback address within QPOPUP.EXE.

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

EXIT:
	Client_AX	=	1 if successful

|

	 sub	 eax,eax		; A handy zero
	 mov	 QPOPUP_CALLBACK.FOFF,eax ; Clear callback address
	 mov	 QPOPUP_CALLBACK.FSEL,ax ; ...

	 mov	 ecx,INTERCEPTS_LIN	; ==> filename intercepts
	 jecxz	 short @F		; Skip if none

	 VMMcall _HeapFree <ecx, 0> ; Free filename intercepts

	 mov	 INTERCEPTS_LIN,0	; Kill the pointer
@@:
	 mov	 [ebp].Client_AX,0	; Normal return indicator in client's AX

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_UnregisterCallback	; End PMAPI_UnregisterCallback procedure

BeginProc PMAPI_IgnoreModeSwitch	; Ignore the mode switch
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Ignore the mode switch.
	Change the target of the JMP $ to skip the INT 10h.

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX	=	Handle of VM to skip past INT 10h

EXIT:
	Client_AX	=	1 if successful

|

	 REGSAVE <edx,esi>		; Save caller's registers

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,StartOf_PMAPI_IgnoreModeSwitch

	 push	 ebx			; Save VM_Handle
	 mov	 ebx,[ebp].Client_EBX	; VM blocked in INT 10h
	 call	 FreePerVM		; Free the LDT selector
	 pop	 ebx			; Restore VM_Handle

	 mov	 esi,[ebp].Client_EBX	; VM blocked in INT 10h
	 SetDOSMAXPtr edx,esi		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_SEMAPHORE ; Blocked on a semaphore?
	 jz	 short PMAPI_QPOPUP_IGNORE_UNSPIN ; Skip if not

PMAPI_QPOPUP_IGNORE_UNBLOCK:

; Unblock the VM waiting on the semaphore

	 mov	 eax,[edx].CB_SEMAPHORE ; Handle of semaphore
	 VMMcall Signal_Semaphore	; Unblock the VM

; The semaphore will be destroyed in the backend of the protected mode INT 10h
; handler.

	 jmp	 short PMAPI_QPOPUP_IGNORE_EXIT ; Rejoin common exit code

PMAPI_QPOPUP_IGNORE_UNSPIN:

; Change the target of the JMP $ to skip the INT 10h.

	 mov	 esi,[ebp].Client_EBX	; VM blocked in INT 10h
	 mov	 esi,[esi+CB_High_Linear] ; Offset to VM's address space
	 add	 esi,INT10_STUB_ADDR	; Linear address of I10Stub
	 add	 esi,I10Stub_Patch	; ESI ==> patch point in INT 10h stub

; Make sure the JMP $ is really there

	 cmp	 word ptr [esi],((-2 shl 8) or @OPCOD_JMPS)
	 je	 short @F		; Skip error if so

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,PMAPI_IgnoreModeSwitch_BadSpin
@@:

Ignore_JMP_Disp  equ	(I10Stub_Exit - (I10Stub_Patch + 2))

	 mov	 [esi+1].LO,Ignore_JMP_Disp ; Change the JMP SHORT target

	 call	 ScheduleCleanup	; Cleanup after scheduled event

; Reset original background execution bit

	 push	 ebx			; Save VM_Handle
	 mov	 ebx,[ebp].Client_EBX	; VM blocked in INT 10h

	 test	 [edx].CB_wFlags,@CBF_BACKGROUND ; Background previously set?
	 jnz	 short PMAPI_QPOPUP_IGNORE_XBACKGROUND ; Skip if so

	 REGSAVE <edx>			; Save per VM pointer

	 VMMcall Get_Time_Slice_Priority ; Get flags and priorities
					; ... into EAX, ECX, EDX, and ESI
	 test	 eax,VMStat_Background	; Background execution enabled?
	 jz	 short @F		; Skip if not

	 and	 eax,(not VMStat_Background) ; Kill background execution bit
	 VMMcall Set_Time_Slice_Priority ; Set flags and priorities
@@:
	 REGREST <edx>			; Restore background timeslice priority
PMAPI_QPOPUP_IGNORE_XBACKGROUND:
	 pop	 ebx			; Restore VM handle

PMAPI_QPOPUP_IGNORE_EXIT:
	 mov	 [ebp].Client_AX,1	; TRUE return indicator in client's AX

	 REGREST <esi,edx>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_IgnoreModeSwitch 	; End PMAPI_IgnoreModeSwitch procedure

BeginProc PMAPI_Terminate		; Terminate the VM
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Terminate the VM.

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX	=	Handle of VM to terminate

EXIT:
	Client_AX	=	1 if successful

|

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,StartOf_PMAPI_Terminate	; FIXME

	 REGSAVE <ebx>			; Save VM handle

	 mov	 ebx,[ebp].Client_EBX	; Handle of VM to terminate
	 call	 FreePerVM		; Free the LDT selector

	 sub	 eax,eax		; Don't wait before terminating
	 sub	 ecx,ecx		; Flags - Don't continue executing
	 VMMcall Close_VM		; Terminate the VM
					; Calling Close_VM on the Sys_VM_Handle
					; will RIP the whole system

	 REGREST <ebx>			; Restore VM handle

	 mov	 [ebp].Client_AX,1	; TRUE return indicator in client's AX

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_Terminate		; End PMAPI_Terminate procedure
	 page
BeginProc PMAPI_SignalSemaphore 	; Release VM blocked by a semaphore
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Release VM blocked by a semaphore

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX	=	Handle of VM to skip past INT 10h

EXIT:
	Client_AX	=	1 if successful

|

	 REGSAVE <edx,esi>		; Save caller's registers

	 push	 ebx			; Save VM_Handle
	 mov	 ebx,[ebp].Client_EBX	; VM blocked by semaphore
	 call	 FreePerVM		; Free the LDT selector
	 pop	 ebx			; Restore VM_Handle

	 mov	 esi,[ebp].Client_EBX	; VM blocked by semaphore
	 SetDOSMAXPtr edx,esi		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_SEMAPHORE ; Blocked on a semaphore?
	 jnz	 short @F		; Jump if not

	 BREAK	 PMAPI_SIGSEM_NOSEMAPHORE ; Call the debugger FIXME
@@:

; Unblock the VM waiting on the semaphore

	 mov	 eax,[edx].CB_SEMAPHORE ; Handle of semaphore
	 VMMcall Signal_Semaphore	; Unblock the VM

	 mov	 [ebp].Client_AX,1	; TRUE return indicator in client's AX

	 REGREST <esi,edx>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_SignalSemaphore		; End PMAPI_SignalSemaphore procedure
	 page
BeginProc FreePerVM			; Free the LDT selector
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Free the selector in the Sys_VM's LDT that maps the program name.
	Free the selector in the Sys_VM's LDT that maps the per VM data.

Entry:
	EBX	=	Handle of VM in trouble
	EBP	==>	Client register structure

|

	 REGSAVE <eax,ebx,ecx,edx>	; Save caller's registers

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 VMMcall Get_Sys_VM_Handle	; Handle of VM whose LDT we're affecting

	 push	 edx			; Save ==> per VM data

	 movzx	 eax,[edx].CB_lpszFilename.VSEG ; Selector to filename

	 or	 eax,eax		; Has a filename selector been alloc'ed?
	 jz	 short @F		; Skip the free if so

	 call	 KillClientSelectors	; Zero client selectors containing AX

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _Free_LDT_Selector, <ebx, eax, ecx>
@@:
	 pop	 edx			; Restore ==> per VM data

	 movzx	 eax,[edx].CB_SELPERVM	; Selector to per VM struc
	 or	 eax,eax		; Has a selector been allocated?
	 jz	 short @F		; Skip the free if so

	 call	 KillClientSelectors	; Zero client selectors containing AX

	 sub	 ecx,ecx		; A handy zero
	 VMMcall _Free_LDT_Selector, <ebx, eax, ecx>
@@:
	 REGREST <edx,ecx,ebx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FreePerVM			; End FreePerVM procedure
	 page
BeginProc KillClientSelectors		; Zero any invalid client selector
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Zero any client selector matching the one in AX

Entry:
	AX	=	Selector value becoming invalid
	EBX	=	Handle of VM in trouble
	EBP	==>	Client register structure

|

	 REGSAVE <ecx>			; Save caller's registers

	 sub	 ecx,ecx		; A handy zero

	 cmp	 ax,[ebp].Client_DS	; DS to become invalid?
	 jne	 short @F		; Skip if not

	 mov	 [ebp].Client_DS,cx	; Zero it
@@:
	 cmp	 ax,[ebp].Client_ES	; ES to become invalid?
	 jne	 short @F		; Skip if not

	 mov	 [ebp].Client_ES,cx	; Zero it
@@:
	 cmp	 ax,[ebp].Client_FS	; FS to become invalid?
	 jne	 short @F		; Skip if not

	 mov	 [ebp].Client_FS,cx	; Zero it
@@:
	 cmp	 ax,[ebp].Client_GS	; GS to become invalid?
	 jne	 short @F		; Skip if not

	 mov	 [ebp].Client_GS,cx	; Zero it
@@:
	 REGREST <ecx>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  KillClientSelectors		; End KillClientSelectors procedure
	 page
BeginProc ScheduleQpopup		; PostMessage to QPOPUP.EXE
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Schedules an event into the Sys_VM to PostMessage QPOPUP.EXE

Entry:
	EBX	=	Current VM handle

Exit:

|

	 REGSAVE <ebx,edx,esi>		; Save caller's registers

	 mov	 edx,ebx		; Reference data is Cur_VM_Handle

	 push	 ebx			; Save the current VM handle

	 VMMcall Get_Sys_VM_Handle	; ... into EBX

;;;;;; flags for Call_Priority_VM_Event
;;;;;;	 mov	 eax,0			; Priority boost
;;;;;;	 mov	 ecx,0			; PEF_xxx flags
;;;;;;	 VMMcall Call_VM_Event		; Schedule a callback for the Sys_VM

	 mov	 esi,OFFSET32 QPOPUP_EVENTPROC ; ESI ==> callback
	 VMMcall Schedule_VM_Event	; Schedule a callback for the Sys_VM

	 pop	 ebx			; Restore the current VM handle

	 REGREST <esi,edx,ebx>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ScheduleQpopup 		; End ScheduleQpopup procedure

	 page
BeginProc ScheduleCleanup		; Cleanup after ScheduleQpopup
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Cleanup after returning from ScheduleQpopup event

Entry:
	EBX	=	Current VM handle

Exit:

|

	 REGSAVE <edx>			; Save caller's registers

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 and	 [edx].CB_wFlags,(not @CBF_EVENT) ; Kill scheduled event bit

	 REGREST <edx>			; Restore caller's registers
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ScheduleCleanup		; End ScheduleCleanup procedure
	 page
BeginProc QPOPUP_EVENTPROC		; Callback from Schedule_VM_Event
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Callback procedure scheduled during INT 10h mode switch
	This causes the dialog to popup.  When they make their selection
	the QPopup will call the PM API entry point.

	Saves the current Time_Slice_Priority flags in the per VM data,
	and sets the background execution bit.

ENTRY:

	EBX	=	Sys_VM_Handle
	EDX	=	Reference data - VM handle
	EBP	=	Client register structure

EXIT:
	We can trash EAX, EBX, ECX, EDX, ESI, EDI, and flags
	No change to client's registers

|

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,StartOf_QPOPUP_EVENTPROC	; FIXME

	 cmp	 QPOPUP_CALLBACK.FSEL,0 ; Is there a callback?
	 je	 QPOPUP_EVENTPROC_EXIT	; Don't call what's not there

; Save the current Time_Slice_Priority flags and enable background execution

	 REGSAVE <ebx,edx>		; Save registers

	 mov	 ebx,edx		; Handle of VM in trouble

	 VMMcall Get_Time_Slice_Priority ; EAX = flags
					; ECX = foreground, EDX = background
					; ESI = % of CPU time used

	 REGSAVE <edx>			; Save background timeslice priority

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 or	 [edx].CB_wFlags,@CBF_EVENT ; Remember we scheduled an event
	 and	 [edx].CB_wFlags,(not @CBF_BACKGROUND)	; Kill background bit
	 test	 eax,VMStat_Background	; Background execution enabled?
	 jz	 short @F		; Skip if not

	 or	 [edx].CB_wFlags,@CBF_BACKGROUND ; Remember background bit
@@:
	 REGREST <edx>			; Restore background timeslice priority

	 test	 eax,VMStat_Background	; Background execution enabled?
	 jnz	 short @F		; Skip if already set

	 or	 eax,VMStat_Background	; Set background execution bit
	 VMMcall Set_Time_Slice_Priority
@@:
	 REGREST <edx,ebx>		; Restore reference data

; Prepare a selector in the Sys_VM's LDT to access the filename, etc.

	 REGSAVE <edx>			; Save reference data

	 SetDOSMAXPtr edx,edx		; EDX ==> DOSMAX per VM structure

	 mov	 [edx].CB_lpszFilename.VSEG,0 ; Assume no selector can be had

	 mov	 esi,[edx].CB_PFILENAME ; ==> filename (CB_High_Linear based)
	 mov	 ecx,15 		; Limit
	 sub	 eax,eax

;					   Base
;					   |	Limit
;					   |	|	   Type, DPL
;					   |	|	   |	Big/Default
;					   |	|	   |	|    Flags
;					   |	|	   |	|    |
	 VMMcall _BuildDescriptorDWORDs,<esi, ecx, CPL0_DATA, eax, eax>

;					   VM_Handle
;					   |   High-order descriptor DWORD
;					   |	|    Low-order descriptor DWORD
;					   |	|    |	Count
;					   |	|    |	|  Flags
;					   |	|    |	|  |
	 VMMcall _Allocate_LDT_Selector,<ebx, edx, eax, 1, 0>
	 REGREST <edx>			; Restore reference data

	 or	 eax,eax		; Test for failure
	 jnz	 short @F		; Skip error code if OK

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,QPOPUP_EVENTPROC_LDTAllocFailed	; FIXME
@@:

; Set the FAR PTR to the filename into the per VM data

	 REGSAVE <ebx,edx>		; Save caller's registers

					; EDX = reference data = VM_Handle
	 SetDOSMAXPtr edx,edx		; EDX ==> DOSMAX per VM structure
	 mov	 [edx].CB_lpszFilename.VSEG,ax ; Set selector to filename
	 mov	 [edx].CB_lpszFilename.VOFF,0 ; Set offset

	 REGREST <edx,ebx>		; Restore caller's registers

; Prepare a selector for the per VM data for the VM in trouble (Sys_VM's LDT).

	 REGSAVE <edx>			; Save reference data

					; EDX is reference data (VM_Handle)
	 SetDOSMAXPtr edx,edx		; EDX ==> DOSMAX per VM structure
	 mov	 ecx,(type DOSMAX_PERVM_STR)-1 ; Limit
	 sub	 eax,eax

;					   Base
;					   |	Limit
;					   |	|	   Type, DPL
;					   |	|	   |	Big/Default
;					   |	|	   |	|    Flags
;					   |	|	   |	|    |
	 VMMcall _BuildDescriptorDWORDs,<edx, ecx, CPL0_DATA, eax, eax>

;					   VM_Handle
;					   |   High-order descriptor DWORD
;					   |	|    Low-order descriptor DWORD
;					   |	|    |	Count
;					   |	|    |	|  Flags
;					   |	|    |	|  |
	 VMMcall _Allocate_LDT_Selector,<ebx, edx, eax, 1, 0>
	 REGREST <edx>			; Restore reference data

	 or	 eax,eax		; Test for failure
	 jnz	 short @F		; Skip error code if OK

	 BREAK	 DBG_FLAG,@DBG_DOSMAX,QPOPUP_EVENTPROC_LDTAlloc2Failed	; FIXME
@@:

; Make the callback
	 Push_Client_State		; Save client machine state

	 VMMcall Begin_Nest_Exec	; Switch VM to locked PM stack

; The callback procedure in QPOPUP.EXE is prototyped as follows:
;	VOID FAR PASCAL CallBack(WORD wSelPerVMCB, DWORD lParam)

; Push wParam

	 REGSAVE <ebx,edx>		; Save caller's registers

	 mov	 ebx,edx		; Reference data is VM handle
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 mov	 [edx].CB_SELPERVM,ax	; Save selector to per VM data itself

	 VMMcall Simulate_Push		; Push selector as wParam

	 REGREST <edx,ebx>		; Restore caller's registers

; Push lParam
	 sub	 eax,eax		; A handy zero
	 ror	 eax,16 		; Get high-order word first
	 VMMcall Simulate_Push		; Push onto client's stack

	 rol	 eax,16 		; Move low-order word into position
	 VMMcall Simulate_Push		; ...

	 mov	 cx,QPOPUP_CALLBACK.FSEL	; Selector of callback
	 mov	 edx,QPOPUP_CALLBACK.FOFF	; Offset   of callback
	 VMMcall Simulate_Far_Call	; Compile the CALLF

	 VMMcall Resume_Exec		; Actually execute the code

	 VMMcall End_Nest_Exec		; Restore VM to original state

	 Pop_Client_State		; Restore client machine state

QPOPUP_EVENTPROC_EXIT:
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  QPOPUP_EVENTPROC		; End QPOPUP_EVENTPROC procedure
	 page
DSTKCOM_STR struc

DSTKCOM_OFF dw	 ?		; DSTK_TAB_STR entry offset
DSTKCOM_SIG dd	 @STKSIG	; Stack signature

DSTKCOM_STR ends

BeginProc DSTK_SUB			; Search for a free stack
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

This is a modification of a procedure by the same name in QMAX_IDT.ASM

Search through the structure looking for a free stack

On entry:

EBP	 ==>	 Client_Reg_Struc

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx>		; Save registers

; Search through the structure looking for a free stack

	 mov	 ebx,LaDSTK_TAB 	; Get linear address of DSTK_TAB_STR

	 and	 ebx,ebx		; Stacks present?
	 jz	 DSTK_SUB_EXIT		; Jump if not (note CF=0)

	 mov	 ecx,DSTK_CNT		; Get total # DOS stacks we supply
DSTK_SUB_NEXT:
	 cmp	 [ebx].DSTK_TAB_OLDSTKVEC,@STKAVL ; Izit available?
	 je	 short DSTK_SUB_AVL	; Jump if so

DSTK_SUB_LOOP:
	 add	 ebx,(type DSTK_TAB_STR) ; Skip to next entry
	 loop	 DSTK_SUB_NEXT		; Jump if more entries

; No DOS stacks available, so we won't bother

	 stc				; Mark as in error

	 jmp	 short DSTK_SUB_EXIT	; Join common exit code

; Because the previous stack might have overflowed into this stack,
; we check for our signature

DSTK_SUB_AVL:
	 mov	 eax,[ebx].DSTK_TAB_LaDOSTOP ; Get linear address of top
					; of the corresponding stack
	 sub	 eax,(type DSTKCOM_STR) ; Back off by one structure

	 cmp	 [eax].DSTKCOM_SIG,@STKSIG ; Izit still there?
	 je	 short @F		; Jump if so

; Mark the stack as having overflowed

	 mov	 [ebx].DSTK_TAB_OLDSTKVEC,@STKOVF ; Mark it

	 jmp	 short DSTK_SUB_LOOP	; Go around again

@@:

; Save the offset of the corresponding entry of DSTK_TAB_STR
; on the new client stack

	 mov	 ecx,ebx		; Copy to convert
	 sub	 ecx,LaDSTK_TAB 	; Convert to origin-0
	 mov	 [eax].DSTKCOM_OFF,cx	; Save for later use

; Swap the current SS:SP with the new client SS:SP

	 mov	 eax,[ebx].DSTK_TAB_DOSSTKVEC ; Get the new SS:SP
	 sub	 ax,(type DSTKCOM_STR)	; Make room for structure
; Make room for IRET on MAX stack
	 sub	 ax,(type IRET_STR)	; Make room for IRET frame

	 xchg	 ax,[ebp].Client_ESP.ELO ; Swap with old SP
;;;;;;	 sub	 ax,(type IRET_STR)	; Make room for IRET frame
	 mov	 [ebx].DSTK_TAB_OLDSTKVEC.VOFF,ax ; Save to restore later

	 shr	 eax,16 		; Shift down high-order word
	 xchg	 ax,[ebp].Client_SS	; Swap with old SS
	 mov	 [ebx].DSTK_TAB_OLDSTKVEC.VSEG,ax ; Save to restore later

; Address the new client stack

	 mov	 ax,[ebp].Client_SS	; Get client SS
	 shl	 eax,(4-0)		; Convert from paras to bytes
	 movzx	 ebx,[ebp].Client_ESP.VOFF ; Get client SP
	 add	 ebx,eax		; Linear address of new client stack

; Setup the IRET frame to point to the DSTKCOM code in the MAX stack

	 mov	 eax,PDSTKCOM		; Get Seg:Off of return handler

	 mov	 [ebx].IRET_IP,ax	; Save in IRET frame on MAX stack

	 shr	 eax,16 		; Shift down high-order word
	 mov	 [ebx].IRET_CS,ax	; Save in IRET frame on MAX stack

	 mov	 ax,[ebp].Client_EFlags.ELO ; Get caller's flags
	 mov	 [ebx].IRET_FL,ax	; Save to restore later

; Upon entry to DSTKCOM, we must ensure TF=0 to avoid being traced

	 and	 ax,not (mask $TF) ; TF=0
	 mov	 [ebp].Client_EFlags.ELO,ax ; Save caller's flags

	 clc				; Mark as successful
DSTK_SUB_EXIT:
	 REGREST <ecx,ebx,eax>		; Restore

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  DSTK_SUB			; End DSTK_SUB procedure

BeginProc SVM_INT21			; Handler for V86 INT 21h
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	V86 INT 21h hook.
	Check for 4B00h exec() call.
	TRUENAME the filespec and search the [INTERCEPTS] data for a match.
	Trigger a callback in QPOPUP to bitch about the program.

	The attitude here is that if anything goes wrong along the way,
	we act like the program name is OK.

Entry:
	EAX =	Interrupt # (21h)
	EBX =	VM Handle
	EBP ==> Client register structure

Exit:
	Carry set if interrupt not serviced

|

	 cmp	 [ebp].Client_AX,4B00h	; Is it exec()?
	 jne	 SVM_INT21_CHAIN	; Chain to next handler if not

; Weed out early callers, the System VM, and non-DOSMAX VMs

	 test	 PMI_FLAG,@PMI_INITCOMP ; Init_Complete been by yet?
	 jz	 SVM_INT21_CHAIN	; Chain to next handler if not

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jz	 SVM_INT21_CHAIN	; Chain to the next handler if so

	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 test	 [edx].CB_wFlags,@CBF_VMINIT ; Has VM_Init been processed yet?
	 jz	 SVM_INT21_CHAIN	; Chain to the next handler if not

	 test	 [edx].CB_wFlags,@CBF_DOSMAX ; Is this a DOSMAX VM?
	 jz	 SVM_INT21_CHAIN	; Chain to the next handler if not

	 test	 [ebx+CB_VM_Status],VMStat_PM_Exec ; DPMI app?
	 jnz	 SVM_INT21_CHAIN	; Chain to the next handler if so

; Check for a troublesome program

;;;;;;	 BREAK	 DOSMAX_EXEC		; Call the debugger FIXME

	 Client_Ptr_Flat esi,DS,DX	; DS:ESI ==> filename

; Get the truename into our V86 data area.
; This area is used to hold the .QPE files, which themselves contain a
; full pathname, so we know it's big enough.

	 Push_Client_State		; Save client's register structure
	 VMMcall Begin_Nest_V86_Exec	; Switch VM to V86 mode

	 mov	 ax,GLOBAL_V86_VEC.VSEG ; Segment of buffer
	 mov	 [ebp].Client_ES,ax	; ... into client's ES

	 mov	 ax,GLOBAL_V86_VEC.VOFF ; Offset of buffer
	 mov	 [ebp].Client_DI,ax	; ... into client's DI

	 mov	 ax,[ebp].Client_DX	; Client MOV SI,DX
	 mov	 [ebp].Client_SI,ax	; ...

	 mov	 [ebp].Client_AH,@FIXPTH ; Canonize path in DS:SI to ES:DI
	 mov	 eax,21h		; DOS services
	 VMMcall Exec_Int		; Do the DOS call

	 mov	 dx,[ebp].Client_Flags	; Check carry flag for errors

	 VMMcall End_Nest_Exec		; Restore VM to original state
	 Pop_Client_State		; Restore client's register structure

	 test	 dx,(mask $CF)		; Check carry flag for TRUENAME error
	 jnz	 SVM_INT21_CHAIN	; Chain to next handler if error

	 REGSAVE <eax,ebx,ecx,esi>	; Save registers

; Zoom to the trailing NUL, then scan backwards to the '\'.
; Save a pointer to the filename.ext and its length.

	 mov	 edi,GLOBAL_V86_LIN	; EDI ==> TRUENAME buffer
	 mov	 ecx,-1 		; Look forever, we know it's there
	 sub	 al,al			; Terminating NUL
   repne scasb				; Search for the terminating NUL
	 not	 ecx			; Length we scanned
	 dec	 ecx			; Account for overscan at end

	 dec	 edi			; Account for overscan
	 mov	 esi,edi		; ESI ==> end
	 mov	 al,'\'                 ; Path separator
	 std				; Autodecrement
   repne scasb				; Search backward for path separator
	 cld				; Autoincrement
	 jne	 SVM_EXEC_MISSING	; Something's wrong so we won't find it

	 inc	 edi			; EDI ==> start of filename.ext
	 inc	 edi			; ...
	 xchg	 esi,edi		; ESI ==> start, EDI ==> end
	 sub	 edi,esi		; Length of filename.ext
	 mov	 EXEC_NAMEL,edi 	; Save length of filename.ext
	 mov	 EXEC_NAME,esi		; Save pointer to filename.ext

; Check for a match in the QPOPUP [INTERCEPTS] data

	 cld				; Autoincrement
	 mov	 esi,INTERCEPTS_LIN	; Linear address of [INTERCEPTS] text

SVM_EXEC_NEXT_CFG_LINE:
	 sub	 dl,dl			; Kill CFG flag letter
	 cmp	 [esi].LO,EOF		; Are we at the end?
	 je	 short SVM_EXEC_MISSING ; Exit inspection if so

	 call	 ISWHITE		; Are we looking at whitespace?
	 je	 short SVM_EXEC_SKIP	; Consume and ignore remainder of line

	 cmp	 [esi].LO,CR	; Are we looking at an empty line?
	 je	 short SVM_EXEC_SKIP ; Consume and ignore remainder of line

	 cmp	 [esi].LO,';'           ; Is it a comment line?
	 je	 short SVM_EXEC_SKIP	; Consume and ignore remainder of line

	 mov	 dl,CFG_WARNFLAG	; Graphics mode warning flag
	 push	 esi			; Save CFG pointer
	 call	 CHK_CFG_FLAG		; Inspect field for flag
	 pop	 esi			; Restore CFG pointer
	 je	 short SVM_EXEC_FOUND_FLAG ; Compare file names if found

	 mov	 dl,CFG_FAILFLAG	; Graphics mode fail flag
	 push	 esi			; Save CFG pointer
	 call	 CHK_CFG_FLAG		; Inspect field for flag
	 pop	 esi			; Restore CFG pointer
	 jne	 short SVM_EXEC_SKIP	; Consume remainder if not present

SVM_EXEC_FOUND_FLAG:
; We found a line with the flag present

	 call	 CHK_CFG_FLAG		; Consume flag
	 call	 SKIPWHITE		; Skip over whitespace
	 jc	 short SVM_EXEC_MISSING ; Carry indicates EOF
	 jz	 short SVM_EXEC_SKIP	; Zero indicates CRLF

	 call	 TOKENIZE		; Get length of filename into ECX

	 cmp	 ecx,EXEC_NAMEL 	; Do the lengths match?
	 jne	 short SVM_EXEC_SKIP	; Consume and ignore if not

	 mov	 edi,EXEC_NAME		; EDI ==> filename.ext in buffer
    repe cmpsb				; Compare the names
	 jne	 short SVM_EXEC_SKIP	; Consume and ignore if different

; We've got a match on the names -- DL contains the CFG flag letter

	 jmp	 SVM_EXEC_FOUND

; Skip and ignore remainder of line

SVM_EXEC_SKIP:
	 call	 CONSUME		; Consume and ignore remainder of line

	 jmp	 short SVM_EXEC_NEXT_CFG_LINE ; Continue scanning

SVM_EXEC_MISSING:
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure
	 lea	 edi,[edx].CB_LASTEXEC	; EDI ==> last name we trapped
	 mov	 esi,EXEC_NAME		; ESI ==> filename.ext in buffer
	 mov	 ecx,8+1+3		; Length of filename.ext
     rep movsb				; Copy the name for next time
	 sub	 dl,dl			; Not-found-in-CFG flag

SVM_EXEC_FOUND:

	 REGREST <esi,ecx,ebx,eax>	; Restore registers

; Finished scanning the entire [INTERCEPTS] data
; DL contains the CFG flag letter if we got a match

	 cmp	 dl,0			; Did we find anything troublesome?
	 je	 short SVM_INT21_CHAIN	; Chain to next handler if not

	 mov	 ax,@CBFN_WARNFLAG	; Assume troublesome program
	 cmp	 dl,CFG_WARNFLAG	; Troublesome program?
	 je	 short SVM_EXEC_SCHED	; Rejoin common code

	 mov	 ax,@CBFN_FAILFLAG	; Assume graphics mode program
	 cmp	 dl,CFG_FAILFLAG	; Graphics mode program?
	 je	 short SVM_EXEC_SCHED	; Rejoin common code

	 BREAK	 SVM_EXEC_BADFLAG	; Call the debugger FIXME

SVM_EXEC_SCHED:
	 SetDOSMAXPtr edx		; EDX ==> DOSMAX per VM structure

	 mov	 esi,EXEC_NAME		; ESI ==> filename.ext in buffer
	 mov	 [edx].CB_PFILENAME,esi ; Save ==> filename in per VM data
	 mov	 [edx].CB_wFunction,ax	; Reason flag

	 lea	 edi,[edx].CB_LASTEXEC	; EDI ==> last name we trapped
;;;;;;	 mov	 esi,EXEC_NAME		; ESI ==> filename.ext in buffer
	 call	 CMPSBI 		; Do case-insensitive REPE CMPSB
	 pushf				; ZR indicates they matched

	 mov	 ecx,8+1+3		; Length of filename.ext
     rep movsb				; Copy the name

	 popf				; Restore ZR match flag
	 jz	 short @F		; Skip if same name as last time

	 call	 ScheduleQpopup 	; PostMessage to QPOPUP.EXE
	 call	 SemaphoreBlock 	; Block the VM, using a semaphore
					; Control returns with the semaphore
					; is signalled.
	 call	 ScheduleCleanup	; Cleanup after scheduled event
@@:
DOSMAX_EXEC_SEMAPHORE_UNBLOCK:
	 cmp	 [edx].CB_wFunction,@CBFN_FAILFLAG ; Was it FAIL?
	 jne	 short SVM_INT21_CHAIN	; Chain to the next handler if not
					; They've had their warning

	 or	 [ebp].Client_Flags,(mask $CF) ; Indicate 4B00 failed
	 mov	 [ebp].Client_AX,5	; ACCESS DENIED
					; COMMAND.COM will print a message.

	 clc				; Indicate we serviced the INT 21h

	 jmp	 short SVM_INT21_EXIT	; Rejoin common exit code

SVM_INT21_CHAIN:
	 stc				; Chain to the next V86 handler

SVM_INT21_EXIT:
	 ret				; Return to WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SVM_INT21			; End SVM_INT21 procedure

BeginProc PMAPI_GetDOSMAXInfo		; Return DOSMAX Info PM API services
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return DOSMAX info in Client_AX

|

	test	PMI_FLAG,@PMI_DOSMAX	; Izit enabled?
	setnz	al			; AL = 1 if so
					;      0 if not
	cbw				; Extend to AH
	mov	[ebp].Client_AX,ax	; Load up the return code

	ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetDOSMAXInfo		; End PMAPI_GetDOSMAXInfo procedure

endif					; IFDEF @DOSMAX

VxD_CODE_ENDS				; End _TEXT segment

	 end				; End VMAX_SVM module
