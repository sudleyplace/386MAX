;'$Header:   P:/PVCS/MAX/VXD/VMAX_HRP.ASV   1.0   05 Sep 1995 17:21:12   HENRY  $
	 title	 VMAX_HRP --  HARPO Related Routines
	 page	 78,130
	 name	 VMAX_HRP

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1992-93 Qualitas, Inc.  All rights reserved.

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

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
	 include DOSMGR.INC

	 include MASM.INC	; From the standard Qualitas include library
	 include 386.INC
	 include PTR.INC

	 include PM_BIOS.INC		; Homemade include for Thinkpad PM_BIOS

	 include QMAXWIN3.INC		; From 386MAX.SYS

	 include BREAK.INC
	 include VMAX.INC		; Local includes
	 include VMAX_UPD.INC
.list

VxD_LOCKED_DATA_SEG			; Begin _LDATA segment

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 include VMAX_PMI.INC
	 extrn	 PMI_FLAG:word

	 extrn	 REF_LIN:dword		; ==> reference data structure

ifdef @HARPO
INT41_IDTENT	 IDT_STR <>		; Save area for INT 41h IDT entry
INT41_VEC	 df	?		; FAR PTR to the original INT 41h guy

@DCBYT	 equ	 22h			; Don't-care byte

; Model code found in KRNL386.EXE segment (0)

KERNEL_MODEL	 label	byte		; Model of code in KERNEL
	 db	 76h, 0Eh		; JBE	Store
	 db	 0EBh, 00h		; JMP	$+2
	 db	 50h			; PUSH	AX
@KERNEL_PATCHOFF equ	($-KERNEL_MODEL)
	 db	 0E8h, @DCBYT, @DCBYT	; CALL	CalcFileConst
	 db	 8Bh, 0D8h		; MOV	BX,AX
	 db	 58h			; POP	AX
	 db	 83h, 0FBh, 0FFh	; CMP	BX,-1
	 db	 74h, 0Bh		; JZ	Error
					; Store:
	 db	 89h, 1Eh, @DCBYT, @DCBYT ; MOV [0291],BX
	 db	 0B0h, 0Ah		; MOV	AL,0Ah
	 db	 0B8h, 0FFh, 0FFh	; MOV	AX,-1
	 db	 0EBh, 09h		; JMP	Return
					; Error:
	 db	 0BAh, @DCBYT, @DCBYT	; MOV	DX,offset ErrorMsg

@LKERNEL_MODEL	 equ	$-KERNEL_MODEL	; Length of model code

endif					; IFDEF @HARPO

VxD_LOCKED_DATA_ENDS			; End _LDATA segment
	 page
VxD_IDATA_SEG				; Begin _IDATA segment

	 extrn	 STR_QUALITAS:byte	; VMAX.ASM

ifdef @HARPO
	 public  STR_HARPO, STR_HARPOBREAK, STR_HarpoHookB8
STR_HARPO	 db	'HARPO', 0      ; String for Get_Profile_Boolean
STR_HARPOBREAK	 db	'HARPOBREAK', 0
STR_HarpoHookB8  db	'HARPOHOOKB8', 0

	 public  STR_FixupPMBIOS
STR_FixupPMBIOS  db	'FIXUPPMBIOS', 0

	 public  OLD_DOSMGR_Instance_Device
OLD_DOSMGR_Instance_Device dd	?	; Address of service in DOSMGR

	 public  @CHECKSTART, @CHECKLIMIT, @CHECK1L, CHECK1
@CHECKSTART	 equ	 500h		; Start looking here
@CHECKLIMIT	 equ	 200h		; Limit of search
					; We expect to find it at 624h

CHECK1	 label	 byte			; Comparison model
	 db	 81h, 0FFh, 00h, 00h, 08h, 00h	; CMP EDI,80000h
	 db	 73h, 2Dh			; JNC	xxx
	 db	 33h, 0C0h			; XOR EAX,EAX
	 db	 0A0h, @DCBYT, @DCBYT, @DCBYT, 080h	; MOV AL,[80...]
	 db	 0B9h, 00h, 00h, 08h, 00h	; MOV ECX,80000h
@CHECK1L	 equ	 $-CHECK1	; Length of model

	 public  @PATCHOFF1, @PATCH1
@PATCHOFF1	 equ	 3		; Patch offset
@PATCH1 	 equ	 0FF0h		; Patch word

	 public  @PATCHOFF2, @PATCH2
@PATCHOFF2	 equ	 0Fh+2		; Patch offset
@PATCH2 	 equ	 0FF0h		; Patch word
endif					; IFDEF @HARPO

VxD_IDATA_ENDS				; End _IDATA segment

VxD_DATA_SEG				; Begin _DATA segment

	 public  OLD_PageAllocate
OLD_PageAllocate dd	?		; Offset to original _PageAllocate

	 public  PageAllocate_CALLER
PageAllocate_CALLER dd	?		; _PageAllocate caller's return address

	 public  PageAllocate_PTE
PageAllocate_PTE dd	?		; Buffer to hold one PTE

	 public  HARPO_OLD_HOOK_V86_PAGE, HARPO_OLD_VDD_PF_HOOK
HARPO_OLD_HOOK_V86_PAGE dd	?	; Offset to original Hook_V86_Page svc
HARPO_OLD_VDD_PF_HOOK dd	?	; Offset to VDD's original hook proc

VxD_DATA_ENDS				; End _DATA segment


VxD_LOCKED_CODE_SEG			; Begin _LTEXT segment
	 assume  cs:FLAT		; Tell the assembler

ifdef @HARPO
BeginProc LCL_INT41			; Windows debugger interface, INT 41h
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Windows debugger interface, INT 41h, handler for HARPO.

	Watches for KERNEL(0) to load, and patches it.

|

	 cmp	 ax,4Fh 		; Izit 'Are you a Windows debugger'?
	 jne	 INT41_X4F		; Skip if not

	 BREAK	 DBG_FLAG,@DBG_HARPO	; Break if HarpoBreak=TRUE

; SS:ESP ==> the instruction in KERNEL after the INT 41h

	 push	 ebp			; Save previous stack frame
	 mov	 ebp,esp		; Address the stack

INT41_STR	 struc
INT41_EBP	 dd	 ?		; Caller's EBP
INT41_EIP	 dd	 ?		; ...	   EIP
INT41_CS	 dw	 ?,?		; ...	   CS, padding
INT41_EFL	 dd	 ?		; ...	   EFLAGS
INT41_STR	 ends			; End INT41_STR structure

	 pushad 			; Save caller's registers
	 REGSAVE <ds,es>		; Save caller's segment registers

	 mov	 ax,ss			; Get addressibility to FLAT
	 mov	 ds,ax			; ... via DS
	 mov	 es,ax			; ... via ES
	 assume  ds:FLAT, es:FLAT	; Tell the assembler

	 sub	 esp,size DTR_STR	; Make room for GDTR
	 sgdt	 [esp].EDF		; Get GDTR
	 mov	 eax,[esp].DTR_BASE	; Get GDT base
	 add	 esp,size DTR_STR	; Strip from stack

	 sub	 ebx,ebx		; A handy zero
	 sldt	 bx			; Get the LDTR
	 and	 bx,not (mask $PL)	; Kill priviledge bits
	 add	 ebx,eax		; EBX ==> GDT entry for LDT

	 mov	 eax,[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8			; Make room for byte 3
	 mov	 al,[ebx].DESC_BASE3	; Get byte 3
	 ror	 eax,8			; Rotate back to normal order

	 sub	 ebx,ebx		; A handy zero
	 mov	 bx,[ebp].INT41_CS	; Pick up return address selector
	 and	 bx,not ((mask $PL) or (mask $TI))	; Kill priviledge bits
	 add	 ebx,eax		; EBX ==> GDT entry for caller's CS

	 mov	 eax,[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8			; Make room for byte 3
	 mov	 al,[ebx].DESC_BASE3	; Get byte 3
	 ror	 eax,8			; Rotate back to normal order

	 sti				; Enable interrupts

	 mov	 edi,eax		; ES:EDI ==> KERNEL target segment
	 sub	 eax,eax		; Kill high-order half of 32-bit reg
	 mov	 ax,[ebp].INT41_CS	; Get selector of KERNEL segment
	 lsl	 ebx,eax		; Get limit of KERNEL segment

	 lea	 esi,KERNEL_MODEL	; DS:ESI ==> KERNEL model code
	 mov	 ecx,@LKERNEL_MODEL	; ECX = length of model code
	 call	 CODESRCH		; Find the code in KERNEL
	 jc	 short INT41_NOTFOUND	; Jump if error

	 mov	 edx,REF_LIN		; Get linear address of REF_DATA_STR
	 mov	 ax,[edx].REF_FILES_LEN ; Pick up length of FILES= structure

	 mov	 [edi+@KERNEL_PATCHOFF].EDD,8B0000B8h ; MOV AX,imm & NOP
	 mov	 [edi+@KERNEL_PATCHOFF+1],al ; Patch in correct length

INT41_NOTFOUND:

; Unhook INT 41h

	 mov	 eax,INT41_IDTENT.EDQLO ; Pick up the original INT 41h IDT entry
	 mov	 edx,INT41_IDTENT.EDQHI ; ...

	 pushfd 			; Save interrupt enable flag
	 cli				; Disable interrupts

	 sub	 esp,size DTR_STR	; Make room for IDTR
	 sidt	 [esp].EDF		; Get IDTR
	 mov	 ebx,[esp].DTR_BASE	; Get IDT base
	 add	 esp,size DTR_STR	; Strip from stack

	 lea	 ebx,[ebx+(41h*size IDT_STR)] ; Bump to INT 41h

	 mov	 [ebx].EDQLO,eax	; Replace original INT 41h
	 mov	 [ebx].EDQHI,edx	; ...

	 popfd				; Restore interrupt enable flag

	 mov	 al,INT41_IDTENT.IDT_ACCESS ; Pick up the access rights
	 and	 al,(mask $DT_DPL)	; Isolate the DPL bits
	 cmp	 al,CPL3		; Izit ready to take INTs or faults?
					; N.B. Zero flag travels to INT41_X4F

	 REGREST <es,ds>		; Restore caller's segment registers
	 assume  ds:nothing, es:nothing ; Tell the assembler

	 popad				; Restore caller's registers

	 pop	 ebp			; Restore previous stack frame

INT41_X4F:
	 je	 short @F		; Jump if we got here via a PL3 INT

	 iretd				; Return from fault

@@:
	 cli				; Disable interrupts
	 jmp	 INT41_VEC		; Chain to original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_INT41			; End LCL_INT41 procedure

BeginProc CODESRCH			; Find model code
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Search for model code, using don't-care bytes.
	@DCBYT (22h) is used as the don't-care byte.

ENTRY:
	DS:ESI ==> model code
	ES:EDI ==> target code
	ECX    =   length of model
	EBX    =   limit of search

EXIT:
	Carry clear if found, ES:EDI ==> start of code in target segment
	Carry set if not found.

|

	 REGSAVE <eax,ebx,ecx,edx,esi>	; Save caller's registers

	 sub	 ebx,ecx		; Reduce search limit by length of model

	 xchg	 ebx,ecx		; EBX = length of model
					; ECX = limit of search
	 lodsb				; AL = 1st byte of model

CODESRCH_OLOOP:
   repne scasb				; Find 1st byte of model
	 jne	 short CODESRCH_NEVER	; Jump if we can't find the model

; AL = 1st byte of model
; ESI ==> 2nd byte of model
; EDI ==> 2nd byte of target, 1st byte has been matched

	 REGSAVE <eax,ecx,esi,edi>	; Save pointers and length

	 mov	 ecx,ebx		; ECX = length of model
	 jmp	 short CODESRCH_NXT	; Jam into the loop to account
					; ... for the 1st byte already matched
CODESRCH_ILOOP:
	 mov	 dl,es:[edi]		; Pick up next byte of target
	 inc	 edi			; Account for byte picked up

	 lodsb				; Pick up next byte of model

	 cmp	 al,@DCBYT		; Izit a don't-care byte?
	 je	 short CODESRCH_NXT	; Skip compare if so

	 cmp	 al,dl			; Are model and target equal?
	 jne	 short CODESRCH_MM	; No, so exit loop (Zero flag clear)

CODESRCH_NXT:
	 loop	 CODESRCH_ILOOP 	; Test 'em all

CODESRCH_MM:
	 REGREST <edi,esi,ecx,eax>	; Restore pointers and length

; AL = 1st byte of model
; ESI ==> 2nd byte of model
; EDI ==> next byte of target
; ECX = limit of search

	 loopne  CODESRCH_OLOOP 	; Look for 1st byte again

; If zero flag is clear, we've exahusted the search w/o finding the model

CODESRCH_NEVER:
	 jne	 short CODESRCH_STC	; Exit with carry set

	 dec	 edi			; Back up to first byte in target

	 clc				; 'Found' return indicator

	 jmp	 short CODESRCH_EXIT	; Rejoin common exit code

CODESRCH_STC:
	 stc				; 'Not found' return indicator

CODESRCH_EXIT:
	 REGREST <esi,edx,ecx,ebx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CODESRCH			; End CODESRCH procedure
endif					; IFDEF @HARPO

VxD_LOCKED_CODE_ENDS			; End _LTEXT segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 PHYS2LIN:near

BeginProc LCL_PageAllocate		; Local handler for _PageAllocate
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY:
	Parameters to _PageAllocate VMMcall on the stack
	See the structure below

On EXIT:

|

	 test	 PMI_FLAG,@PMI_INITCOMP ; Init_Complete been by yet?
	 jnz	 LPA_CHAIN2		; Jump to original handler if so

	 push	 ebp			; Save previous frame pointer
	 mov	 ebp,esp		; Address the stack

LPA_STR 	 struc			; Access to _PageAllocate arguments
		 dd	?		; Caller's EBP
		 dd	?		; Caller's EIP
    LPA_nPages	 dd	?		; # of pages
    LPA_pType	 dd	?		; PG_HOOKED, PG_SYS, PG_VM
    LPA_VM	 dd	?		; VM handle, or NULL for PG_SYS
    LPA_AlignMask dd	?		; 1, 3, 7, ...
    LPA_minPhys  dd	?		; Minimum page # - 1
    LPA_maxPhys  dd	?		; Maximum page # + 1
    LPA_PhysAddr dd	?		; ==> DWORD to get physical address
    LPA_flags	 dd	?		; PageContig, PageFixed, ...
LPA_STR 	 ends			; End LPA_STR structure

	 cmp	 [ebp].LPA_pType,PG_SYS ; pType = PG_SYS?
	 jne	 LPA_CHAIN		; Pass on to VMM if not

	 cmp	 [ebp].LPA_flags,(PageLocked or PageFixed or PageUseAlign or PageZeroInit)
	 jne	 LPA_CHAIN		; Not our boy if not -- pass on to VMM

	 cmp	 [ebp].LPA_minPhys,0A0h ; Minimum page above 640K?
	 jae	 short LPA_CHAIN	; Pass on to VMM if so

	 cmp	 [ebp].LPA_maxPhys,0A0h ; Maximum page above 640K?
	 jae	 short LPA_CHAIN	; Pass on to VMM if so

	 pop	 ebp			; Restore previous stack frame

;;;;;;	 BREAK	 PMBIOS_PageAllocate	; Call the debugger FIXME

	 pop	 [PageAllocate_CALLER]	; Save return address
	 call	 OLD_PageAllocate	; 'Call' the original handler
	 push	 [PageAllocate_CALLER]	; Replace return address

	 push	 ebp			; Save previous frame pointer
	 mov	 ebp,esp		; Address the stack

	 REGSAVE <eax,ebx,edx,esi>	; Save caller's registers

	 mov	 esi,[ebp].LPA_PhysAddr ; ==> physical page #
	 mov	 eax,[esi]		; Pick up physical page #
	 shr	 eax,(12-0)		; Convert from byte address to page #
	 cmp	 eax,0A0h		; Is it in the low 640K?
	 ja	 short LPA_EXIT 	; Exit if not

	 sub	 ecx,ecx		; A handy zero for the flags
	 VMMcall _CopyPageTable,<eax,1,<OFFSET32 PageAllocate_PTE>,ecx>
	 or	 eax,eax		; Check for error return
	 jz	 short LPA_EXIT 	; Exit if error

	 cmp	 PageAllocate_PTE,0	; Did the entry get zeroed?
	 jne	 short LPA_EXIT 	; Exit if not

	 BREAK	 DBG_FLAG,@DBG_HARPO,GotTheZeroEntry ; Break if HarpoBreak=TRUE

	 mov	 esi,[ebp].LPA_PhysAddr ; ==> physical page #
	 mov	 eax,[esi]		; Pick up physical page #
	 shr	 eax,(12-0)		; Convert from byte address to page #
;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Flags
;				|    |	  |    |  |
	 VMMcall _PhysIntoV86  <eax, ebx, eax, 1, 0>
LPA_EXIT:
	 REGREST <esi,edx,ebx,eax>	; Restore caller's registers
	 pop	 ebp			; Restore previous stack frame

	 ret				; Return to caller

LPA_CHAIN:
	 pop	 ebp			; Restore previous stack frame
LPA_CHAIN2:
	 jmp	 OLD_PageAllocate	; Jump to the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LCL_PageAllocate		; End LCL_PageAllocate procedure

	 page
BeginProc HARPO_LCL_HOOK_V86_PAGE	; Local handler for Hook_V86_Page
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Watch for the VDD hooking pages B8-BF.	Insert our own local
	handler while remembering the VDD's callback address.

ON ENTRY:
	EAX	=	Page # to hook
	ESI	==>	Callback procedure

On EXIT:
	Carry clear to indicate the hook has been installed.

|

	 test	 PMI_FLAG,@PMI_VDDPF	; Is VDD_PFault hooked?
	 jnz	 short HLHVP_CHAIN	; Skip if so

	 cmp	 eax,0B8h		; Is it below a video text page?
	 jb	 short HLHVP_CHAIN	; Chain to original handler if not

	 cmp	 eax,0BFh		; Is it above a video text page?
	 ja	 short HLHVP_CHAIN	; Chain to original handler if not

	 or	 PMI_FLAG,@PMI_VDDPF	; Remember VDD_PFault is hooked

	 mov	 HARPO_OLD_VDD_PF_HOOK,esi	; Remember the address
	 mov	 esi,OFFSET32 HARPO_LCL_VDD_PF_HOOK ; Switch to our own

HLHVP_CHAIN:
	 jmp	 HARPO_OLD_HOOK_V86_PAGE ; Call the original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  HARPO_LCL_HOOK_V86_PAGE	; End HARPO_LCL_HOOK_V86_PAGE procedure

BeginProc HARPO_LCL_VDD_PF_HOOK ; Local replacement for VDD_PFault hook
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ON ENTRY:
	EAX	=	Faulting page #
	EBX	=	Current VM handle

On EXIT:
	The PTE has been corrected, or the VM destroyed

|

	 test	 PMI_FLAG,@PMI_INITCOMP ; Init_Complete been by yet?
	 jnz	 short HLVPH_CHAIN	; Chain to original if so

	 VMMcall Test_Sys_VM_Handle	; Is it the System VM?
	 jnz	 short HLVPH_CHAIN	; Chain to the original if not

	 cmp	 eax,0B8h		; Is it below a video text page?
	 jb	 short HLVPH_CHAIN	; Chain to original handler if not

	 cmp	 eax,0BFh		; Is it above a video text page?
	 ja	 short HLVPH_CHAIN	; Chain to original handler if not

;				Physical page #
;				|    VM Handle
;				|    |	  V86 page #
;				|    |	  |    # of pages
;				|    |	  |    |  Flags
;				|    |	  |    |  |
	 VMMcall _PhysIntoV86  <eax, ebx, eax, 1, 0>

HLVPH_RET:
	 ret				; Return to caller

HLVPH_CHAIN:
	 jmp	 HARPO_OLD_VDD_PF_HOOK	; Transfer to the VDD's original handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  HARPO_LCL_VDD_PF_HOOK		; End HARPO_LCL_VDD_PF_HOOK procedure

VxD_CODE_ENDS				; End _TEXT segment
	 page
VxD_ICODE_SEG				; Begin _ITEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 HOOKPROC:near		; VMAX.ASM

ifdef @HARPO
BeginProc INIT_HARPO			; Setup for HARPO
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Patch the DOS file structure checker in DOSMGR for HARPO

	The code in the DOSMGR limits the comparisons to 80000h.
	We patch it to run up to FF000h.

|

	 and	 PMI_FLAG,(not @PMI_HARPO) ; HARPO support disabled

	 mov	 edx,REF_LIN		; Get linear address of REF_DATA_STR
	 test	 [edx].REF_UPDFLAG,@UPD_UPDATE ; Are we updating an old 386MAX?
	 jnz	 IHARPO_EXIT		; Provide no HARPO support if so

; Check the state of HARPO= switch in the [QUALITAS] section of SYSTEM.INI

	 sub	 eax,eax		; Assume option not present or TRUE
	 dec	 eax			; ...
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_HARPO ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option

; If CY or ZR there isn't a valid HARPO= switch in SYSTEM.INI

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 IHARPO_EXIT		; Exit procedure if HARPO=FALSE

	 or	 PMI_FLAG,@PMI_HARPO	; HARPO support enabled
@@:

; Check state of HarpoBreak= switch in SYSTEM.INI

	 sub	 eax,eax		; Assume option not present or FALSE
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_HARPOBREAK ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option

; If CY or ZR there isn't a valid HarpoBreak= switch in SYSTEM.INI

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short @F		; Skip setting flag if HarpoBreak=FALSE

	 or	 DBG_FLAG,@DBG_HARPO	; HARPO debugging support enabled
@@:

; Get address of known point in DOSMGR.386

	 mov	 eax,DOSMGR_Instance_Device	; Service to steal
	 mov	 esi,OFFSET32 HOOKPROC	; Address of replacement
	 VMMcall Hook_Device_Service	; Steal the service
	 jc	 IHARPO_EXIT		; Return CY if error

	 mov	 OLD_DOSMGR_Instance_Device,esi ; Save address of service

	 mov	 eax,DOSMGR_Instance_Device	; Service to replace
	 VMMcall Hook_Device_Service	; Replace the service
	 jc	 IHARPO_EXIT		; Return if error

; Find code in DOSMGR that checks the length of the FILES= structures

	 mov	 edi,OLD_DOSMGR_Instance_Device
	 lea	 edi,[edi+@CHECKSTART]	; ES:EDI ==> start of search area
	 mov	 ebx,@CHECKLIMIT	; EBX is limit of search

	 lea	 esi,CHECK1		; DS:ESI ==> DOSMGR model code
	 mov	 ecx,@CHECK1L		; ECX = length of model code
	 call	 CODESRCH		; Find the code in DOSMGR
	 jc	 IHARPO_EXIT		; Jump if not found
					; We don't return an error because
					; we can't do anything about it anyway

; Patch code in DOSMGR's DOS file structures internals check

	 mov	 [edi+@PATCHOFF1].ELO,@PATCH1	; Patch the offset
	 mov	 [edi+@PATCHOFF2].ELO,@PATCH2	; Patch the count

; Hook into the Windows debugger interface, INT 41h in protected mode

	 mov	 edx,REF_LIN		; Get linear address of REF_DATA_STR
	 cmp	 [edx].REF_FILES_LEN,0	; Is patching KERNEL required?
	 je	 IHARPO_EXIT		; Skip it if not

	 mov	 edx,OFFSET32 LCL_INT41 ; Offset of interrupt handler
	 mov	 ax,cs			; Segment selector of handler
	 shl	 eax,16 		; Move to proper end
	 mov	 ax,dx			; Low end of offset
	 mov	 dh,(CPL0_INTR3 or CPL3) ; Access bits
	 sub	 dl,dl			; Clear reserved bits

; EAX is low DWORD of IDT entry for INT 41h
; EDX is high DWORD

	 pushfd 			; Save interrupt enable flag
	 cli				; Disable interrupts

	 sub	 esp,size DTR_STR	; Make room for IDTR
	 sidt	 [esp].EDF		; Get IDTR
	 mov	 ebx,[esp].DTR_BASE	; Get IDT base
	 add	 esp,size DTR_STR	; Strip from stack

	 lea	 ebx,[ebx+(41h*size IDT_STR)] ; Bump to INT 41h

	 xchg	 eax,[ebx].EDQLO	; Swap with INT 41h IDT entry
	 xchg	 edx,[ebx].EDQHI	; ...

	 popfd				; Restore interrupt enable flag

	 mov	 INT41_IDTENT.EDQLO,eax ; Save the IDT entry
	 mov	 INT41_IDTENT.EDQHI,edx ; ...

	 mov	 ax,INT41_IDTENT.IDT_SELECT ; Pick up the selector
	 mov	 INT41_VEC.FSEL,ax	; Save the selector in our DF

	 mov	 ax,INT41_IDTENT.IDT_OFFHI ; Pick up the high-order offset
	 shl	 eax,16 		; Move the upper-end
	 mov	 ax,INT41_IDTENT.IDT_OFFLO ; Pick up the low-order offset
	 mov	 INT41_VEC.FOFF,eax	; Save the offset in our DF

; Hook into the Hook_V86_Page service to catch the VDD grabbing B8-BF
; Check state of HarpoHookB8= switch in SYSTEM.INI

	 sub	 eax,eax		; Assume option not present or FALSE
	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_HarpoHookB8 ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option

; If CY or ZR there isn't a valid HarpoHookB8= switch in SYSTEM.INI

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short HARPO_XHOOKB8	; Skip setting flag if HarpoHookB8=FALSE

	 mov	 eax,Hook_V86_Page	; ID for service to hook
	 mov	 esi,OFFSET32 HARPO_LCL_HOOK_V86_PAGE ; Address of local handler
	 VMMcall Hook_Device_Service	; Return old handler in ESI
	 jc	 short HARPO_XHOOKB8	; If we can't hook it, just give up

	 mov	 HARPO_OLD_HOOK_V86_PAGE,esi	; Save the original handler
HARPO_XHOOKB8:

; To work around the problem with the ThinkPad's PM_BIOS.386
; we must hook _PageAllocate.

; First check for the presence of the PM_BIOS.386 (PMVDD) device and
; the FixupPMBIOS=OFF override switch.

	 mov	 esi,OFFSET32 STR_QUALITAS ; ==> [QUALITAS] section name
	 mov	 edi,OFFSET32 STR_FixupPMBIOS ; ==> key name string

	 VMMcall Get_Profile_Boolean	; Get TRUE/FALSE setting of option

; If CY or ZR there isn't a valid switch in SYSTEM.INI

	 jc	 short IHARPO_PMBIOS_CHKVER ; Check for presence of PM_BIOS
	 jz	 short IHARPO_PMBIOS_CHKVER ; Check for presence of PM_BIOS

	 or	 eax,eax		; EAX = 0 if FALSE
	 jz	 short IHARPO_XPMBIOS	; Skip patch if FALSE
	 jmp	 short IHARPO_PMBIOS_FORCED ; Forced ON

IHARPO_PMBIOS_CHKVER:
	 VxDcall PM_BIOS_Get_Version	; Get Thinkpad PM_BIOS version
					; i.e. is it installed?
	 cmp	 eax,0300h		; We'll patch version 3.00
	 jb	 short IHARPO_XPMBIOS	; Forget it if too low

	 cmp	 eax,0301h		; ... up to version 3.01
	 ja	 short IHARPO_XPMBIOS	; Forget it if too high

IHARPO_PMBIOS_FORCED:
	 mov	 eax,_PageAllocate	; Service to steal
	 mov	 esi,OFFSET32 LCL_PageAllocate	; Address of local replacement
	 VMMcall Hook_Device_Service	; Steal the service
	 jc	 short IHARPO_XPMBIOS	; If we can't hook it, just give up

	 mov	 OLD_PageAllocate,esi	; Save address of original service
IHARPO_XPMBIOS:

IHARPO_EXIT:
	 clc				; Normal return indicator
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  INIT_HARPO			; End INIT_HARPO procedure
endif					; IFDEF @HARPO

VxD_ICODE_ENDS				; End _ITEXT segment

	 end				; End VMAX_HRP module
