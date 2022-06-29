;' $Header:   P:/PVCS/MAX/386MAX/QMAX_N31.ASV   1.2   30 May 1997 10:45:44   BOB  $
	 title	 QMAX_N31 -- 386MAX INT 31h Miscellaneous Interrupt Handlers
	 page	 58,122
	 name	 QMAX_N31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'

Program derived from:  None.

Original code by:  William R. Lewis, April, 1991.
		   Additional code by BOB.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC
	 include OPCODES.INC
	 include DOSERR.INC
	 include MASM5.MAC
	 include IOPBITS.INC
	 include INTVEC.INC
	 include DOSCALL.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAXDPMI.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
FGROUP	 group	 FDATA
IGROUP	 group	 LCODE,LDATA,ICODE,IDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 MSC_FLAG:word
	 include QMAX_MSC.INC

	 extrn	 PRGSIZE:word

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 EXITRCHI:word

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I31_FLAG:word

	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 DPMI_PVFHOOK:byte

	 extrn	 SAVE_EAX:dword

	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword

	 extrn	 INT23_TYP:byte
	 extrn	 INT24_TYP:byte

	 extrn	 PPL0STK_ERR:dword
	 extrn	 PPL0STK_NRM:dword
	 extrn	 PPL0STK_DERR:dword
	 extrn	 PPL0STK_DNRM:dword

	 extrn	 DPMITYPE:byte
	 extrn	 SEL_DS3:word
	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSHI:word

	 extrn	 VMM_FLAG:word

if @OEM_WIN3
	 extrn	 FILES_STR_LEN:byte
	 extrn	 CON1MB:dword
	 extrn	 PDTLEN:dword
	 extrn	 VCPIBASE:dword
endif				; IF @OEM_WIN3

	 public  HPDA_IxxRET
HPDA_IxxRET dd	 ?		; HPDA_I23RET or HPDA_I24RET

@BSAgeInit equ	 18		; Start with 1 second

	 public  BSAgeClock,BSAgeMax
BSAgeClock dw	 @BSAgeInit	; Aging countdown counter
BSAgeMAX   dw	 @BSAgeInit	; Aging maximum counter for refresh

if @OEM_WIN3
; Data for Windows Standard mode HARPO support

	 public  DOSX_FLAG, DOSX_SELGDT, DOSX_SEL4GB, DOSX_SELCS, DOSX_SELDS
DOSX_SELGDT	 dw	?	; Selector providing read/write access to GDT
DOSX_SEL4GB	 dw	?	; All-memory selector
DOSX_SELCS	 dw	?	; Our PGROUP code selector
DOSX_SELDS	 dw	?	; Our PGROUP data selector
DOSX_FLAG	 db	0	; DL at INT 2F AX=1605 -- DOSX if low bit set

;;;;;;	 public  WDEB_FLAG
;;;;;;WDEB_FLAG  db	0	; Indicates a Windows Kernel debugger is present
;;;;;;
;;;;;;	 public  WDEB_SEL0, WDEB_SEL1, WDEB_SEL2
;;;;;;WDEB_SEL0  DESC_STR <>	; 1st of WDEB386's selectors
;;;;;;WDEB_SEL1  DESC_STR <>	; 2nd of WDEB386's selectors
;;;;;;WDEB_SEL2  DESC_STR <>	; 3rd of WDEB386's selectors
;;;;;;
;;;;;;	 public  WDEB_IDT41
;;;;;;WDEB_IDT41	 IDT_STR <>	; WDEB386's INT 41h IDT entry

;  Model of code in KERNEL's DOS initialization

@UNK	 equ	 22h			; Don't-care byte for model comparison

	 public  KERNEL_MODEL, @LKERNEL_MODEL, @KERNEL_PATCHOFF
KERNEL_MODEL	 label	byte		; Model of code in KERNEL
	 db	 76h, 0Eh		;	JBE	Store
	 db	 0EBh, 00h		;	JMP	$+2
	 db	 50h			;	PUSH	AX

@KERNEL_PATCHOFF equ	($-KERNEL_MODEL)
	 db	 0E8h, @UNK, @UNK	;	CALL	CalcFileConst
	 db	 8Bh, 0D8h		;	MOV	BX,AX
	 db	 58h			;	POP	AX
	 db	 83h, 0FBh, 0FFh	;	CMP	BX,-1
	 db	 74h, 0Bh		;	JZ	Error
					; Store:
	 db	 89h, 1Eh, @UNK, @UNK	;	MOV	[0291],BX
	 db	 0B0h, 0Ah		;	MOV	AL,0Ah
	 db	 0B8h, 0FFh, 0FFh	;	MOV	AX,-1
	 db	 0EBh, 09h		;	JMP	Return
					; Error:
	 db	 0BAh, @UNK, @UNK	;	MOV	DX,offset ErrorMsg

@LKERNEL_MODEL	 equ	$-KERNEL_MODEL	; Length of model code
endif				; IF @OEM_WIN3

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 INT11MSG:byte
	 extrn	 MSG_L11:byte

FDATA	 ends			; End FDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DSIG3:word

LDATA	 ends			; End LDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_N31_ECODE
@QMAX_N31_ECODE:		; Mark module start in .MAP file

	 extrn	 INTXXCOM:near
	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC00:near
	 extrn	 INTPROC04:near
	 extrn	 INTPROC05:near
	 extrn	 INTPROC10:near
	 extrn	 INTPROC11:near
	 extrn	 INTPROC1C:near
	 extrn	 INTPROC20:near
	 extrn	 INTPROC23:near
	 extrn	 INTPROC24:near
	 extrn	 INTPROC25:near
	 extrn	 INTPROC26:near
	 extrn	 INTPROC27:near
	 extrn	 INTPROC33:near
	 extrn	 INTPROC41:near
	 extrn	 INTPROC68:near

	 extrn	 HARDINT:near
	 extrn	 INTCOM_DPMI_INT:near
	 extrn	 INTCOM_DPMI_FAULT:near

	 FPPROC  INT10 -- Video Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Video interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   pass the call through our translation services.

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   pass the call through our translation services.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jnz	 near ptr INTPROC10 ; Jump if so (call as VM INT 10h)

; This interrupt is not installed unless DPMI services are enabled,
; so there's no need to test for it here

;;;;;;;; test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
;;;;;;;; jnz	 near ptr INTPROC10 ; Jump if so (call as VM INT 10h)
;;;;;;;;
	 FIXIJMP IGROUP:INT10_DPMI,DTE_CSIG ; Run through our translator

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT10	 endp			; End INT10 procedure
if @OEM_WIN3
	 FPPROC  INT41_DOSX -- Windows Debugger Services INT 41h
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

	INT 41h handler used under Standard mode (VCPI)

	This interrupt handler is executed under DOSX's GDT, etc.
	We have never debugged through it with 386SWAT.

	In order to support HARPO and Windows 3.1 Standard mode, we use this
	opportunity to patch KERNEL.  We get control near the beginning of
	KERNEL via INT 41h, AH=4Fh (Windows Kernel debugger installation check).
	We search the caller's segment for DOS file structure size
	detection code and replace the CALL with a MOV immediate.
	The value placed in the MOV instruction is passed to 386MAX.SYS by
	the HARPO device driver, HARPO.EXE,  via an EMM2CALL.

	Search for model code, using don't-care bytes.
	@UNK (22h) is used as the don't-care byte.

|

	 cmp	 ax,4Fh 	; Windows Kernel debugger installation check?
	 jne	 INT41_X4F	; Jump if not

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

INT41_STR struc 		; Structure to access stack
	 dd	 ?		; Caller's EBP
INT41_IP dw	 ?		; ...	   IP
INT41_CS dw	 ?		; ...	   CS
INT41_STR ends			; End INT41_4F_STR structure

	 pushad 		; Save caller's registers
	 REGSAVE <ds,es>	; ...

	 mov	 ds,DOSX_SELDS	; Get PGROUP data selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,DOSX_SEL4GB ; Get DOSX's all-memory data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 sub	 esp,size DTR_STR	; Make room for GDTR
	 SGDTD	 [esp].EDF		; Get GDTR
	 mov	 eax,[esp].DTR_BASE	; AGROUP:EAX ==> GDT
	 add	 esp,size DTR_STR	; Strip from stack

	 sub	 ebx,ebx		; A handy zero
	 sldt	 bx			; Get the LDTR
	 and	 bx,not (mask $PL)	; Kill priviledge bits
	 add	 ebx,eax		; AGROUP:EBX ==> GDT entry for LDT

	 mov	 eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2 of LDT entry
	 shl	 eax,8			; Make room for byte 3
	 mov	 al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3 of the LDT entry
	 ror	 eax,8			; Rotate back to normal order
					; AGROUP:EAX ==> LDT

	 sub	 ebx,ebx		; A handy zero
	 mov	 bx,[ebp].INT41_CS	; Caller's caller's CS
	 and	 bx,not ((mask $PL) or (mask $TI)) ; Kill privilege bits
	 add	 ebx,eax		; EBX ==> LDT entry for caller's CS

	 mov	 eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2 of LDT entry
	 shl	 eax,8			; Make room for byte 3
	 mov	 al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3 of the LDT entry
	 ror	 eax,8			; Rotate back to normal order
					; AGROUP:EAX ==> KERNEL(0)
	 mov	 edi,eax		; AGROUP:EDI ==> KERNEL(0)

	 sub	 eax,eax		; Kill high-order half of 32-bit reg
	 mov	 ax,[ebp].INT41_CS	; Get selector of KERNEL segment
	 lsl	 ecx,eax		; Limit of KERNEL seg, limit of search

	 lea	 si,KERNEL_MODEL ; DS:SI ==> KERNEL model code
	 mov	 bx,@LKERNEL_MODEL ; CX = length of ...

	 sub	 cx,bx		; Reduce search limit by length of model

	 lodsb			; AL = 1st byte of model

INT41_4F_OLOOP:
   repne scas	 es:[edi].LO	; Search for 1st byte of model
	 jne	 short INT41_4F_NEVER ; Jump if we can't find the model

; AL = 1st byte of model
; SI ==> 2nd byte of model
; DI ==> 2nd byte of target, 1st byte has been matched

	 REGSAVE <ax,cx,si,edi> ; Save pointers and length

	 mov	 cx,bx		; CX = length of model
	 jmp	 short INT41_4F_NXT ; Jam into the loop to account
				; ... for the 1st byte already matched
INT41_4F_ILOOP:
	 mov	 dl,es:[edi]	; Pick up next byte of target
	 inc	 edi		; Account for byte picked up

	 lodsb			; Pick up next byte of model

	 cmp	 al,@UNK	; Izit a don't-care byte?
	 je	 short INT41_4F_NXT  ; Skip compare if so

	 cmp	 al,dl		; Are model and target equal?
	 jne	 short INT41_4F_MM ; No, so exit loop (Zero flag clear)

INT41_4F_NXT:
	 loop	 INT41_4F_ILOOP ; Test 'em all

INT41_4F_MM:
	 REGREST <edi,si,cx,ax> ; Restore pointers and length

; AL = 1st byte of model
; SI ==> 2nd byte of model
; EDI ==> next byte of target
; CX = limit of search

	 loopne  INT41_4F_OLOOP ; Look for 1st byte again

; If zero flag is clear, we've exahusted the search w/o finding the model

INT41_4F_NEVER:
	 jne	 short INT41_4F_XPATCH ; Skip the patch

	 dec	 edi		; Back up to first byte in target

; Patch the CALL CalcFileConst to MOV AX,type FILES= struct

	 mov	 al,FILES_STR_LEN	; Length of FILES= structure in DOS
	 or	 al,al			; Has it been filled in by HARPO?
	 jz	 short INT41_4F_XPATCH	; Skip the patch if not

	 mov	 AGROUP:[edi+@KERNEL_PATCHOFF].LO,@OPCOD_MOVAXIM ; Patch in MOV

	 sub	 ah,ah			; Convert length from BYTE to WORD
	 mov	 AGROUP:[edi+@KERNEL_PATCHOFF+1],ax ; Length as immediate value

INT41_4F_XPATCH:
	 REGREST <es,ds>	; Restore caller's registers
	 popad			; ...
	 assume  ds:nothing, es:nothing ; Tell the assembler

	 pop	 ebp		; Restore caller's frame pointer

; Returning AX=F386h would tell Windows we're a Kernel debugger
; We won't do that

INT41_X4F:
	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
INT41_DOSX endp 		; End INT41_DOSX procedure
endif				; IF @OEM_WIN3

ECODE	 ends			; End ECODE segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 public  @QMAX_N31_LCODE
@QMAX_N31_LCODE:		; Mark module start in .MAP file

	 NPPROC  INT68_4403 -- Windows Prepare for Protected Mode Operation
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

	Process the INT 68h AX=4403h call from Windows Standard mode.

	Remember important selectors.
	Fill in GDT entries that will be valid under VCPI.
	Fill in the IDT entry for our INT 41h handler.

ENTRY:
	AH	= 44h
	AL	= 0 - WIN386 retail
		= 1 - WIN386 debug
		= 2 - DOSX 3.0
		= 3 - DOSX 3.1 under VCPI (the only case handled here)
		= 4 - DOSX 3.1
	BX	= all-memory selector (386 only)
	CX	= 1st of 3 selectors reserved for the debugger
	DX	= selector allowing read/write access to GDT
	DS:SI  ==> working copy of GDT
	IF AL >= 2 THEN ES:EDI ==> working copy of IDT

	On the stack, ==> INTCOM_STR containing callers segment registers

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

INT68_44_STR	 struc		; Structure to access arguments
		 dd	?	; Caller's EBP
		 dw	?	; ...	    IP
INT68_44_PINTCOM dd	?	; ==> INTCOM_STR
INT68_44_STR	 ends		; End INT68_44_STR structure

	 pushad 		; Save caller's registers
	 REGSAVE <ds,es>	; ...

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ebp,[ebp].INT68_44_PINTCOM ; EBP ==> INTCOM_STR

	 mov	 DOSX_SELGDT,dx ; Save selector to read/write their GDT
	 movzx	 ecx,cx 	; Kill high-order half in GDT index for use
				; in a 32-bit ADD later
	 mov	 DOSX_SELCS,cx	; Save our future PGROUP code selector

; Caller's DS:SI ==> working copy of GDT

	 sub	 eax,eax	; Kill 32-bit register
	 mov	 ax,[ebp].INTCOM_DS ; Caller's V86 mode DS
	 shl	 eax,4		; Convert from paras to bytes
	 movzx	 esi,si 	; Clear high-order half
	 add	 esi,eax	; AGROUP:ESI ==> working copy of GDT

; Caller's ES:DI ==> working copy of IDT

	 sub	 eax,eax	; Kill 32-bit register
	 mov	 ax,[ebp].INTCOM_ES ; Caller's V86 mode ES
	 shl	 eax,4		; Convert from paras to bytes
	 movzx	 edi,di 	; Clear high-order half
	 add	 edi,eax	; AGROUP:EDI ==> working copy of IDT

; The all-memory selector passed in BX is not reliable
; Search their GDT for the real one

	 REGSAVE <cx,esi>	; Save GDT pointer and starting selector

	 mov	 cx,200h/(type DESC_STR) ; # of entries we'll search through
	 mov	 eax,esi	; Remember original ==> GDT
	 sub	 bx,bx		; Assume we never find it

SRCH_GDT_TOL:
	 cmp	 AGROUP:[esi].EDQLO,0000FFFFh ; Low dword of 4GB descriptor?
	 jne	 short SRCH_GDT_NEXT ; Advance if not correct

	 cmp	 AGROUP:[esi].EDQHI,008F9200h ; High DWORD of 4GB descriptor?
	 jne	 short SRCH_GDT_NEXT ; Advance if not correct

	 sub	 esi,eax	; Form 4GB selector
	 mov	 bx,si		; Copy to proper register

	 jmp	 short SRCH_GDT_EXIT ; Rejoin common code

SRCH_GDT_NEXT:
	 add	 esi,(type DESC_STR) ; Advance to next GDT entry
	 loop	 SRCH_GDT_TOL	; Keep going

SRCH_GDT_EXIT:
	 REGREST <esi,cx>	; Restore GDT pointer and starting selector

	 or	 bx,bx		; Did we find the selector?
	 jz	 near ptr INT68_44_EXIT ; Exit without hooking IDT if not

	 mov	 DOSX_SEL4GB,bx ; Save as the all-memory selector

; FIll in our code and data GDT entries

	 add	 esi,ecx	; Bump GDT pointer to our first DTE

	 add	 cx,8		; Bump to next selector
	 mov	 DOSX_SELDS,cx	; Save our future PGROUP data selector

;;;;;;;; FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; EAX = base of selector on stack
	 mov	 eax,VCPIBASE		; Base of our VCPI program
	 mov	 AGROUP:[esi].DESC_BASE01.EDD,eax ; Base bytes 0-1, and 2
	 mov	 AGROUP:[esi+8].DESC_BASE01.EDD,eax ; Base bytes 0-1, and 2
	 rol	 eax,8			; Rotate out the high-order byte
	 mov	 AGROUP:[esi].DESC_BASE3,al ; Base byte 3
	 mov	 AGROUP:[esi+8].DESC_BASE3,al ; Base byte 3

	 sub	 eax,eax	; Kill high-order half
	 mov	 ax,PRGSIZE	; Length of our program in 1KB
	 shl	 eax,(10-0)	; Convert from 1KB units to bytes
	 add	 eax,PDTLEN	; Plus length of PDT in bytes
	 dec	 eax		; Convert from length to limit

	 cmp	 eax,CON1MB	; Bigger than 1M limit on byte granular DTE?
	 jb	 short @F	; Skip if not

	 shr	 eax,(12-0)	; Convert to page granular limit
	 or	 eax,(mask $DTE_G) shl 16 ; Set the G-bit
@@:
	 mov	 AGROUP:[esi].DESC_SEGLM0,ax ; Limit, 0-15
	 mov	 AGROUP:[esi+8].DESC_SEGLM0,ax ; Limit, 0-15
	 rol	 eax,16 	; Swap high- and low-order words
	 mov	 AGROUP:[esi].DESC_SEGLM1,al ; Limit, 16-19, and flags
	 or	 al,(mask $DTE_B) ; Set B-bit in data selector
	 mov	 AGROUP:[esi+8].DESC_SEGLM1,al ; Limit, 16-19, and flags

	 mov	 AGROUP:[esi].DESC_ACCESS,CPL0_CODE ; Access rights
	 mov	 AGROUP:[esi+8].DESC_ACCESS,CPL0_DATA ; Access rights

; Fill in the IDT entry for INT 41h
; Don't change the DPL of the Standard mode IDT entry

	 add	 edi,41h * (type IDT_STR) ; Bump to INT 41h in IDT

	 mov	 ax,DOSX_SELCS
	 mov	 AGROUP:[edi].IDT_SELECT,ax ; Selector to PGROUP
	 lea	 eax,INT41_DOSX 	; Offset of INT41_DOSX within PGROUP
	 mov	 AGROUP:[edi].IDT_OFFLO,ax ; Store low-end of offset in IDT
	 shr	 eax,16 		; Move high-order end down
	 mov	 AGROUP:[edi].IDT_OFFHI,ax ; Store high-order end

INT68_44_EXIT:
	 REGREST <es,ds>	; Restore caller's registers
	 popad			; ...
	 assume  ds:nothing, es:nothing

	 pop	 ebp		; Restore caller's frame

	 ret	 4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
INT68_4403 endp 		; End INT68_4403 procedure

LCODE	 ends			; End LCODE segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 BSActive:byte
	 extrn	 PageIOActive:byte
endif				; IF @OEM_VIRTUALMEM

	 extrn	 DPMITYPEIG:byte

	 public  INT00NXT_FVEC
INT00NXT_FVEC df ?		; Address of next interrupt in GP_INT

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 public  @QMAX_N31_ICODE
@QMAX_N31_ICODE:		; Mark module start in .MAP file

	 extrn	 INT10_DPMI:far
	 extrn	 INT33_DPMI:far
	 extrn	 PMINTCOM:far
	 extrn	 VMFLTCOM:far
	 extrn	 DPMIFN_LMSW:near
	 extrn	 DPMIFN_TERMINATE:near
	 extrn	 DPMIFN_ESPMOD:near

if @OEM_VIRTUALMEM
	 extrn	 PPM_AGE_PAGES:near
endif				; IF @OEM_VIRTUALMEM

	 FPPROC  INT00 -- Divide Overflow Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Divide overflow interrupt handler

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC00.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, continue with INTPROC00.

|


; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT00_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[00h/8],1 shl (00h mod 8) ; Izit hooked by current client?
	 jz	 short INT00_ORIG ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*00h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 jmp	 near ptr VMFLTCOM ; Jump to common code

INT00_ORIG:
	 FIXIJMP PGROUP:INTPROC00,DTE_CS2 ; Jump if so (call as VM INT 00h)

INT00_PM:

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT00_ORIG ; Jump if no DPMI clients active

COMMENT!

Because of a bug in the Intel Codebuilder which uses self-modifying
code to execute an arbitrary interrupt, we must handle INT 00h
specially.  What they do is as follows:

	 lea	 esi,INT00+1
	 mov	 [esi],al
INT00:
	 int	 00h

which fails to take into account the prefetch instruction queue.  In
particular, the above code always executes the preceding interrupt #,
never the one written into the INT instruction.  To my great
disappointment, the above code works under Windows for all the wrong
reasons.  When running DPMI code, Windows sets up the IDT for most
interrupts to be at DPL 0 (and defines only the first 60h IDT
entries).  This means that the INT instruction actually doesn't
execute; instead, it signals a GP Fault.  The GP Fault handler then
checks to see which interrupt # was specified at which time it sees
the value written by the self-modifying code and executes the correct
instruction.

Here's what I propose to do:

* Detect the problem in our INT 00h handler as that is the default
  value in the INT instruction.
* Save the xxh value in INT xxh, and change it back to 00h.
* Simulate the INT xxh.

Detection Phase:

The Divide Overflow interrupt is a fault, meaning that the CS|EIP on
the stack point to the faulting instruction.  The first check then is
that the instruction to which the CS|EIP on the stack points is either
DIV or IDIV.  The opcodes for DIV are F6 /6 and F7 /6; for IDIV, they
are F6 /7 and F7 /7.

If the instruction at CS|EIP is neither DIV nor IDIV and the two bytes
which precede it are CD xx where xx is not zero, then we assume we
have detected this bug.

Correction Phase:

* Save the xxh value in INT xxh, and change it back to 00h.
* Simulate the INT xxh.

!

INT00_STR struc

	 dd	 ?		; Caller's EBP
INT00_EIP dd	 ?		; ...	   EIP
INT00_CS  dw	 ?,?		; ...	   CS w/filler
INT00_EFL dd	 ?		; ...	   EFL

INT00_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,ds,es> ; Save registers

	 lds	 ebx,[ebp].INT00_EIP.EDF ; Get caller's CS|EIP
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 ecx,ecx	; Initialize index register
INT00_NEXTINSTR:
	 mov	 al,ds:[ebx+ecx] ; Get next instruction byte
	 inc	 ecx		; Skip over it

; Strip off segment overrides prefixes

	 cmp	 al,@OPCOD_CS	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_DS	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_ES	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_FS	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_GS	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_SS	; Izit segment override?
	 je	 short INT00_NEXTINSTR ; Jump if so

; Strip off operand and address size prefixes

	 cmp	 al,@OPCOD_OSP	; Izit Operand Size Prefix?
	 je	 short INT00_NEXTINSTR ; Jump if so

	 cmp	 al,@OPCOD_ASP	; Izit Address Size Prefix?
	 je	 short INT00_NEXTINSTR ; Jump if so

; No more valid prefixes:  check for DIV and IDIV opcodes

	 cmp	 al,@OPCOD_GRP3A ; Izit Group 3, type A?
	 je	 short @F	; Jump if so

	 cmp	 al,@OPCOD_GRP3B ; Izit Group 3, type B?
	 jne	 short INT00_CHK1 ; Jump if not
@@:
	 mov	 al,ds:[ebx+ecx] ; Get MOD R/M byte
	 and	 al,mask $REG	; Isolate the REG bits
	 shr	 al,$REG	; Shift to low-order

	 cmp	 al,110b	; Izit DIV or IDIV?
	 jae	 short INT00_DIV ; Jump if so

; The current instruction is neither DIV not IDIV
; Check for CD xx preceding the current instruction

INT00_CHK1:
	 sub	 ebx,2		; Back off to CD xxh
	 jc	 short INT00_DIV ; Jump if we are confused

	 cmp	 ds:[ebx].LO,@OPCOD_INT ; Izit INT instruction?
	 jne	 short INT00_DIV ; Jump if we are quite confused

	 movzx	 eax,ds:[ebx].HI ; Get the interrupt #

	 cmp	 al,00h 	; Izit INT 00h instruction?
	 je	 short INT00_DIV ; Jump if we are totally confused

; We have detected the case described above:  now we must correct it

; Get the address of the corresponding interrupt

	 sub	 esp,size DTR_STR ; Make room on the stack
	 SIDTD	 [esp].EDF	; Save linear address of the IDT
	 mov	 ebx,[esp].DTR_BASE ; Get base address of the IDT
	 add	 esp,size DTR_STR ; Remove from the stack

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 es,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 cx,AGROUP:[ebx+eax*(type IDT_STR)].IDT_SELECT ; Get the selector
	 mov	 INT00NXT_FVEC.FSEL,cx ; Save for later use

	 mov	 cx,AGROUP:[ebx+eax*(type IDT_STR)].IDT_OFFHI ; Get the high-order offset
	 shl	 ecx,16 	; Shift to high-order word
	 mov	 cx,AGROUP:[ebx+eax*(type IDT_STR)].IDT_OFFLO ; Get the low-...
	 mov	 INT00NXT_FVEC.FOFF,ecx ; Save for later use

	 clc			; Indicate we need to emulate

	 jmp	 short INT00_EXIT ; Join common exit code (note CF=0)

	 assume  ds:nothing	; Tell the assembler about it

INT00_DIV:
	 stc			; Mark as no fixup needed
INT00_EXIT:
	 REGREST <es,ds,ecx,ebx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore
	 jc	 short @F	; Jump if no fixup needed

	 jmp	 INT00NXT_FVEC	; Jump to next interrupt

	 jmp	 near ptr INT00 ; In case we jumped to a task gate

@@:

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI,
; or FLT_STR if we came from MAX.

	 mov	 [esp].INTDPF_INTNO,4*00h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 FIXIJMP PGROUP:INTCOM_DPMI_FAULT,DTE_CS2 ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT00	 endp			; End INT00 procedure
	 FPPROC  INT04 -- INTO Overflow Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

INTO overflow interrupt handler

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC04.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, continue with INTPROC04.

|


; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT04_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[04h/8],1 shl (04h mod 8) ; Izit hooked by current client?
	 jz	 short INT04_ORIG ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*04h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 jmp	 near ptr VMFLTCOM ; Jump to common code

INT04_ORIG:
	 FIXIJMP PGROUP:INTPROC04,DTE_CS2 ; Jump if so (call as VM INT 04h)

INT04_PM:

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT04_ORIG ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI,
; or FLT_STR if we came from MAX.

	 mov	 [esp].INTDPF_INTNO,4*04h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 FIXIJMP PGROUP:INTCOM_DPMI_FAULT,DTE_CS2 ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT04	 endp			; End INT04 procedure
	 FPPROC  INT05 -- BOUND Instruction Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

BOUND instruction interrupt handler

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC05.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, continue with INTPROC05.

|


; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT05_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[05h/8],1 shl (05h mod 8) ; Izit hooked by current client?
	 jz	 short INT05_ORIG ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*05h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 jmp	 near ptr VMFLTCOM ; Jump to common code

INT05_ORIG:
	 FIXIJMP PGROUP:INTPROC05,DTE_CS2 ; Jump if so (call as VM INT 05h)

INT05_PM:

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT05_ORIG ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI,
; or FLT_STR if we came from MAX.

	 mov	 [esp].INTDPF_INTNO,4*05h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 FIXIJMP PGROUP:INTCOM_DPMI_FAULT,DTE_CS2 ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT05	 endp			; End INT05 procedure
	 FPPROC  INT11 -- Alignment Check Fault handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Alignment check fault handler

Distinguish amongst four cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC11
Segment Overrun  VM86	  ESP=PPL0STK_ERR	UGH
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Segment Overrun  DPMI	  ESP=PPL0STK_DERR	UGH
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Segment Overrun  PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 jne	 short @F	 ; Jump if not

	 FIXIJMP PGROUP:INTPROC11,DTE_CS2 ; Jump if so (call as VM INT 11h)

@@:
	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 short INT11_VM86 ; Yes

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT11_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 short INT11_DPMI_FAULT ; Jump if so

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 short INT11_UGH ; No, so that's a big UGH

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPEIG,@DPMITYPEXX ; Izit active?
	 jne	 short INT11_DPMI_INT ; Jump if so

	 mov	 [esp].NRM_INTNO,4*11h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 11h

	 FIXIJMP PGROUP:HARDINT,DTE_CS2 ; It's a hardware interrupt???

; A hardware interrupt from a DPMI client has occurred

INT11_DPMI_INT:

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*11h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 11h

	 FIXIJMP PGROUP:INTCOM_DPMI_INT,DTE_CS2 ; Join common code


; A fault from a DPMI client has occurred

INT11_DPMI_FAULT:

; The stack is mapped by INTDPF_STR

	 mov	 [esp].INTDPF_INTNO,4*11h + offset PGROUP:INTPROC00Z ; Mark as INT 11h

	 FIXIJMP PGROUP:INTCOM_DPMI_FAULT,DTE_CS2 ; Join common code

INT11_UGH:
INT11_VM86:
	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 cld			; String ops forwardly

	 mov	 si,4*11h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L11 ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT11MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG
	 FIXIJMP PGROUP:INTXXCOM,DTE_CS2 ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT11	 endp			; End INT11 procedure
if @OEM_VIRTUALMEM
	 FPPROC  INT1C -- Secondary Timer Tick Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Secondary timer tick handler

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 cmp	 BSActive,0	; Is paging active?
	 je	 short INT1C_ORIG ; Jump if not

	 dec	 BSAgeClock	; Count out one fewer timer tick
	 jnz	 short INT1C_ORIG ; Jump if it's not our time as yet

	 REGSAVE <ax>		; Save register

	 mov	 ax,BSAgeMax	; Get maximum time
	 mov	 BSAgeClock,ax	; Set for next time

	 call	 PPM_AGE_PAGES	; Age 'em

	 REGREST <ax>		; Restore
INT1C_ORIG:
	 FIXIJMP PGROUP:INTPROC1C,DTE_CS2 ; Continue with next handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT1C	 endp			; End INT1C procedure
endif				; IF @OEM_VIRTUALMEM
	 FPPROC  INT20 -- DOS Terminate Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DOS terminate interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 FIXIJMP PGROUP:INTPROC20,DTE_CS2 ; Jump if so (call as VM INT 20h)

@@:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT20_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[20h/8],1 shl (20h mod 8) ; Izit hooked by current client?
	 jz	 short INT20_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*20h + offset PGROUP:INTPROC00Z ; Mark as INT 20h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT20_INTRETPM
INT20_INTRETPM:
	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT20	 endp			; End INT20 procedure
	 NPPROC  INT22DEF -- Terminate Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:PGROUP
COMMENT|

Terminate interrupt handler

This code is entered from DPMI_SIMRET.

We are called only when a client has terminated in VM but not in PM.
This can happen if the client has installed an INT 23h/24h handler
in VM and it terminated there without reflecting to PM.  Our job is
to terminate in PM.

On entry:

AGROUP:EAX ==>	 HPDA
SS:EBP	 ==>	 INTXX_STR

The PL3 stack has AX pushed onto it with the exit return code
the AX in INTXX_EAX.ELO.

|

; Restore the address of the previous INT 22h handler into the VM IDT.

	 mov	 ebx,AGROUP:[eax].HPDA_I22VEC ; Get the previous INT 22h handler

	 assume  gs:INTVEC	; Tell the assembler about it
	 mov	 INT00_VEC[22h*(type INT00_VEC)],ebx ; Restore
	 assume  gs:AGROUP	; Tell the assembler about it

; Pop the old AX from the stack and restore it

	 movzx	 ebx,[ebp].INTXX_SS ; Get caller's SS
	 shl	 ebx,4-0	; Convert from paras to bytes
	 movzx	 ecx,[ebp].INTXX_ESP.ELO ; Get caller's SP

	 mov	 bx,AGROUP:[ebx+ecx] ; Get the original AX
	 xchg	 bx,[ebp].INTXX_EAX.ELO ; Swap with EXITRC value

	 add	 [ebp].INTXX_ESP.ELO,2 ; Strip from the stack

; Because the exit return code is available only once (why, why, why?),
; we must save the return code back into our resident INT 21h handler
; so we can return it the next time someone asks.

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 EXITRCHI,bx	; Save into high DOS
	 or	 MSC_FLAG,@MSC_GETRC ; Tell 'em to return the saved value
				; the next time
	 assume  ds:nothing	; Tell the assembler about it

; Check the return code in BH:	if we terminated because of INT 23h/24h,
; terminate the DPMI application.  Otherwise, ignore this call.

	 cmp	 bh,@GETRC_I23	; Izit an INT 23h termination?
	 je	 short @F	; Jump if so

	 cmp	 bh,@GETRC_I24	; Izit an INT 24h termination?
				; Fall through with ZF significant
@@:
	 popad			; Restore all EGP registers

	 lea	 esp,[esp+(size INTXX_ERR)] ; Strip pseudo-error code
	 jne	 short @F	; Jump if not error termination

; The stack is mapped by INTCOM_STR

	 mov	 [esp].INTCOM_INTNO,4*22h + offset PGROUP:INTPROC00Z ; Mark as INT 22h

	 cmp	 DPMITYPEIG,@DPMITYPEXX ; Izit active?
	 jne	 short INT22_INTRETPM_ABORT ; Jump if so to common abort code
@@:
	 iretd			; Return to caller (which jumps to the
				; next handler)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT22DEF endp			; End INT22DEF procedure
if @OEM_VIRTUALMEM
	 FPPROC  INT23 -- Ctrl-Break Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Ctrl-Break interrupt handler

Because when paging is active we switch to the PSP
in which we opened the swapfile (the DPMI client),
we can't allow Ctrl-Break to terminate the client.
Thus if paging is active (meaning we switched PSPs),
we ignore this event by returning to the caller.

We take note of the event, however.  If Ctrl-Break
is pressed during swapfile initialization, we'll
simulate an Int 23 on return from client initialization.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)

|

	 bt	 PageIOActive,0 ; Izit active?
	 jnc	 short @F	; Jump if not

	 or	 VMM_FLAG,@VMM_CTRLBREAK ; Mark as Ctrl-Break pressed

	 iretd			; Return to caller, ignoring the event

@@:
	 FIXIJMP PGROUP:INTPROC23,DTE_CS2 ; Jump if not (call as VM INT 23h)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT23	 endp			; End INT23 procedure
endif				; IF @OEM_VIRTUALMEM
	 NPPROC  INT23DEF -- Ctrl-Break Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Ctrl-Break interrupt handler

This code is entered from DPMI_SIMRET.

If there are no DPMI clients active, continue on.

If there are DPMI clients active, give them a crack at this interrupt.
   When we regain control, if the handler made a decision, take that
   action.  Otherwise, terminate the DPMI client.

On entry:

SS:EBP	 ==>	 INTXX_STR

|

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip pseudo-error code

; The stack is mapped by INTCOM_STR

	 mov	 [esp].INTCOM_INTNO,4*23h + offset PGROUP:INTPROC00Z ; Mark as INT 23h

	 cmp	 DPMITYPEIG,@DPMITYPEXX ; Izit active?
	 jne	 short @F	; Jump if so

	 iretd			; Return to caller (which jumps to the
				; next handler)
@@:
	 mov	 INT23_TYP,@INT23_ABORT ; Set to special value in case
				; there's no DPMI client hooking INT 23h or
				; there is, but the client exits via JMPF/CALLF
				; so we terminate the client.

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[23h/8],1 shl (23h mod 8) ; Izit hooked by current client?
	 jz	 short INT23_INTRETPM ; Jump if not

; The stack is mapped by INTCOM_STR

	 push	 @PMINTCOM_LPM	; Use LPM stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

COMMENT|

Enter here from one of the following situations:

1.  From above with the PL0 stack mapped by INTCOM_STR from the
    original INT 23h in VM (no decision, so we terminate).

2.  From DPMI_INTRET when the DPMI client returns control to us via
    JMPF/CALLF with the PL0 stack mapped by INTDPI_STR (no decision,
    so we terminate).

3.  From DPMI_INTRET when the DPMI client returns control to us via
    RETF/D or IRET/D with the PL0 stack mapped by INTCOM_STR from the
    original INT 23h (ignore or abort).

In all cases, INT23_TYP contains an action code.

Cases #1 and #3 have the $VM bit set, case #2 does not.

|

	 public  INT23_INTRETPM
INT23_INTRETPM:
	 test	 [esp].INTDPI_EFL.EHI,mask $VM ; Izit from VM?
	 jnz	 short INT23_INTRETPM1 ; Jump if so

; Make the stack look like STC/RETF to mark as terminating

	 or	 [esp].INTDPI_EFL.ELO,mask $CF ; CF=1

; If it's a 16-bit client, subtract 2 (size of FL)
; If it's a 32-bit client, subtract 4 (size of EFL)

	 xchg	 eax,[esp].INTDPI_ESP ; Get caller's return ESP

	 sub	 ax,2		; Assume 16-bit client

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 sub	 ax,4-2 	; It's a 32-bit client
@@:
	 xchg	 eax,[esp].INTDPI_ESP ; Set new ESP, restore EAX

	 iretd			; Return to caller to complete the cycle

INT23_INTRETPM1:
	 cmp	 INT23_TYP,@INT23_IGNORE ; Should we ignore it?
	 je	 short INT23_INTRETPM_IGNORE ; Jump if so

; Fall through if we're to abort the client

; The check for CF=1 if the client returns via RETF/D
; is performed in DPMI_INTRET.

; Tell DOS that we're aborting by returning to the address
; in the HPDA which does STC/RETF.

	 mov	 [esp].INTCOM_EIP,dword ptr HPDA_I23STC ; Mark as aborting
INT22_INTRETPM_ABORT:
INT24_INTRETPM_ABORT:
	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 SAVE_EAX,eax	; Save for a moment
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 eax,PGROUP:[eax].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 mov	 PGROUP:[eax].TSS_ESP,esp ; Save to use after IRET NT below
	 mov	 eax,SAVE_EAX	; Restore

; If there are any activities which need to be done at
; termination time when PCURTSS and TR match, now's the time

	 call	 DPMIFN_TERMINATE ; Handle termination (note IF=0 upon return)
	 assume  ds:nothing,es:PGROUP  ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; ...

; Set NT bit and IRET to it to effect task switch

	 pushf			; Save flags
	 or	 [esp].ELO,mask $NT ; Set the NT bit
	 popf			; Put it into effect

; Tell our terminate code that we're terminating normally,
; not to switch stacks, and to return to the caller
; Note that we set these bits after calling DPMIFN_TERMINATE as it
; restores the previous I31_FLAG values.

	 or	 I31_FLAG,(mask $I31_EXIT)     or \
			  (mask $I31_NOSWITCH) or \
			  (mask $I31_RETCALL)

; The following IRET causes a task switch to the back link TSS
; which is (presumably) PVMTSS.  As the task switch from PVMTSS
; was initiated by the hand-constructed CALLF VM2PM_TSS, execution
; continues at that point.

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP


; Ignore the event

INT23_INTRETPM_IGNORE:

; Tell DOS that we're ignoring by returning to the address
; in the HPDA which does CLC/RETF.

	 mov	 [esp].INTCOM_EIP,dword ptr HPDA_I23CLC ; Mark as ignoring
INT24_INTRETPM_IGNORE:
INT24_INTRETPM_REFLVM:
	 push	 PVMTSS 	; Pass offset in PGROUP of the 1st TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

	 iretd			; Return to caller in VM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT23DEF endp			; End INT23DEF procedure
if @OEM_VIRTUALMEM
	 FPPROC  INT24 -- Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Critical Error interrupt handler

Because when paging is active we switch to the PSP
in which we opened the swapfile (the DPMI client),
we can't allow Critical Error to terminate the client.
Thus if paging is active (meaning we switched PSPs),
we fail this event by returning to the caller.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)

|

	 bt	 PageIOActive,0 ; Izit active?
	 jnc	 short @F	; Jump if not

	 mov	 al,@INT24_RETRY ; Tell 'em we're retrying the DOS call

	 iretd			; Return to caller, ignoring the event

@@:
	 FIXIJMP PGROUP:INTPROC24,DTE_CS2 ; Jump if not (call as VM INT 24h)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT24	 endp			; End INT24 procedure
endif				; IF @OEM_VIRTUALMEM
	 NPPROC  INT24DEF -- Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Critical error interrupt handler

This code is entered from DPMI_SIMRET.

If there are no DPMI clients active, continue on.

If there are DPMI clients active, give them a crack at this interrupt.
   When we regain control, if the handler made a decision, take that
   action.  Otherwise, pass the buck to VM (which, presumably,
   displays the usual "Abort, Retry, Ignore, Fail" message).

On entry:

AH	 =	 flags as in I24_REC
SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)

|

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip pseudo-error code

; The stack is mapped by INTCOM_STR

	 mov	 [esp].INTCOM_INTNO,4*24h + offset PGROUP:INTPROC00Z ; Mark as INT 24h

	 cmp	 DPMITYPEIG,@DPMITYPEXX ; Izit active?
	 jne	 short @F	; Jump if so

	 iretd			; Return to caller (which jumps to the
				; next handler)
@@:

; Save flags in AH in the DPTSS to reference later.
; Save the value in BP in the DPTSS to restore later.

	 push	 esi		; Save for a moment

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 PGROUP:[esi].DPTSS_I24FLG,ah ; Save for later use
	 mov	 PGROUP:[esi].DPTSS_I24BP,bp ; Save to restore later

	 pop	 esi		; Restore

COMMENT|

Given that we come here only if no decision has been made in VM, the
following paths through this code are possible:

No PM handler:

* Jumps to INT24_INTRETPM (with $VM=1).

PM handler makes a decision (Abort, Retry, Ignore, Fail):

* Code in DPMI_INTRET saves a value into INT24_TYP based on the
  handler's decision and jumps to INT24_INTRETPM (with $VM=1).

PM handle does not make a decision (JMPF/CALLF):

* Code in DPMI_INTRET does not save a value into INT24_TYP, but it
  does jump to INT24_INTRETPM (with $VM=0).

  To complete the cycle, this case is detected at INT24_INTRETPM
  ($VM=0), sets INT24_TYP to @INT24_REFLVM and IRETDs (to complete the
  JMPF/CALLF).	Eventually, the code at DPMI_INTRET is entered with
  INT24_TYP set to a special value, and jumps to INT24_INTRETPM (with $VM=1).

If a DPMI client has hooked INT 24h, the initial value for INT24_TYP
is set to anything other than @INT24_REFLVM so we can distinguish it
from the case where we save @INT24_REFLVM into INT24_TYP.  Otherwise,
the initial value is set to @INT24_REFLVM so we reflect the decision to
VM.

|

	 mov	 INT24_TYP,@INT24_REFLVM ; Set to special value so we reflect
				; the decision to VM.

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[24h/8],1 shl (24h mod 8) ; Izit hooked by current client?
	 jz	 short INT24_INTRETPM ; Jump if not

	 mov	 INT24_TYP,@INT24_FAIL ; Set to any value other than REFLVM

; The stack is mapped by INTCOM_STR

	 push	 @PMINTCOM_LPM	; Use LPM stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

COMMENT|

Enter here from one of the following situations:

1.  From above with the PL0 stack mapped by INTCOM_STR from the
    original INT 24h (pass the buck to VM).

2.  From DPMI_INTRET when the DPMI client returns control to us via
    JMPF/CALLF with the PL0 stack mapped by INTDPI_STR (pass the buck
    to VM).

3.  From DPMI_INTRET when the DPMI client returns control to us via
    IRET/D with the PL0 stack mapped by INTCOM_STR from the original
    INT 24h (ignore, retry, abort or fail).

In all cases, INT24_TYP contains an action code.

Case #2 is distinguished by the $VM bit in INTCOM_EFL or INTDPI_EFL
which are both in the same location.  The other cases are handled
identically and don't need to be distinguished.

|

	 public  INT24_INTRETPM
INT24_INTRETPM:
	 test	 [esp].INTDPI_EFL.EHI,mask $VM ; Izit from VM?
	 jnz	 short INT24_INTRETPM1 ; Jump if so

	 mov	 INT24_TYP,@INT24_REFLVM ; Set to special value so we reflect
				; the decision to VM.

	 iretd			; Return to caller to complete the cycle

INT24_INTRETPM1:

; If there was a PM handler, we translated the value in BP to
; a selector; restore the original value now.

	 push	 esi		; Save for a moment

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 bp,PGROUP:[esi].DPTSS_I24BP ; Restore original value

	 pop	 esi		; Restore

	 cmp	 INT24_TYP,@INT24_REFLVM ; Should we pass the buck to VM?
	 je	 near ptr INT24_INTRETPM_REFLVM ; Jump if so

	 mov	 [esp].INTCOM_EIP,dword ptr HPDA_I24IRET ; Save as return address

	 mov	 al,INT24_TYP	; Get the type code when we return

	 cmp	 al,@INT24_ABORT ; Should we abort the program?
	 je	 near ptr INT24_INTRETPM_ABORT ; Jump if so (join common abort code)

	 jmp	 INT24_INTRETPM_IGNORE ; Join common return code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT24DEF endp			; End INT24DEF procedure
	 FPPROC  INT25 -- DOS Absolute Disk Read Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DOS absolute disk read interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 FIXIJMP PGROUP:INTPROC25,DTE_CS2 ; Jump if so (call as VM INT 25h)

@@:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT25_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[25h/8],1 shl (25h mod 8) ; Izit hooked by current client?
	 jz	 short INT25_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*25h + offset PGROUP:INTPROC00Z ; Mark as INT 25h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT25_INTRETPM
INT25_INTRETPM:

INT25_STR struc

	 dd	 ?		; Callers' EBP
INT25_NXT db	 (size INTDPI_STR) dup (?) ; Remainder of the stack

INT25_STR ends

; Set CF in the return flags and put the original flags onto the stack

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ds>	; Save for a moment

; Note that if we're not called by a DPMI client, there's no
; ring transition and INTDPI_ESP and above are not present.
; On the other hand, we would like to think that none of our
; own load modules would make such a silly call.

	 sub	 [ebp].INT25_NXT.INTDPI_ESP,2 ; Make room for original flags

; If the B-bit in the stack selector is clear, zero the upper
; word of the stack offset.

	 lea	 eax,[ebp].INT25_NXT.INTDPI_ESP ; SS:EAX ==> SS|ESP from PL3
	 push	 eax		; Pass the offset
	 call	 DPMIFN_ESPMOD	; Clear the high-order word of the PL3 ESP
				; if the B-bit in the PL3 SS is clear
	 lds	 eax,[ebp].INT25_NXT.INTDPI_ESP.EDF ; DS:EAX ==> caller's stack
	 assume  ds:nothing	; Tell the assembler about it

	 push	 [ebp].INT25_NXT.INTDPI_EFL.ELO ; Get original flags
	 pop	 ds:[eax].ELO	; Save onto caller's stack

	 or	 [ebp].INT25_NXT.INTDPI_EFL.ELO,mask $CF ; CF=1

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT25	 endp			; End INT25 procedure
	 FPPROC  INT26 -- DOS Absolute Disk Write Interrupt handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DOS absolute disk write interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 FIXIJMP PGROUP:INTPROC26,DTE_CS2 ; Jump if so (call as VM INT 26h)

@@:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT26_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[26h/8],1 shl (26h mod 8) ; Izit hooked by current client?
	 jz	 short INT26_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*26h + offset PGROUP:INTPROC00Z ; Mark as INT 26h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT26_INTRETPM
INT26_INTRETPM:
	 jmp	 INT25_INTRETPM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT26	 endp			; End INT26 procedure
	 FPPROC  INT27 -- DOS TSR Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DOS TSR interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 FIXIJMP PGROUP:INTPROC27,DTE_CS2 ; Jump if so (call as VM INT 27h)

@@:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT27_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[27h/8],1 shl (27h mod 8) ; Izit hooked by current client?
	 jz	 short INT27_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*27h + offset PGROUP:INTPROC00Z ; Mark as INT 27h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT27_INTRETPM
INT27_INTRETPM:
	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT27	 endp			; End INT27 procedure
	 FPPROC  INT33 -- Mouse Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mouse interrupt handler

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   pass the call through our translation services.

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   pass the call through our translation services.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not
INT33_ORIG:
	 FIXIJMP PGROUP:INTPROC33,DTE_CS2 ; Jump if so (call as VM INT 33h)

@@:

; This interrupt is not installed unless DPMI services are enabled,
; so there's no need to test for it here

;;;;;;;; test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
;;;;;;;; jnz	 short INT33_ORIG ; Jump if so (call as VM INT 33h)
;;;;;;;;
	 jmp	 near ptr INT33_DPMI ; Run through our translator

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT33	 endp			; End INT33 procedure
	 FPPROC  INT41 -- Windows Debugger Services
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Windows debugger services

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 FIXIJMP PGROUP:INTPROC41,DTE_CS2 ; Jump if so (call as VM INT 41h)

@@:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT41_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[41h/8],1 shl (41h mod 8) ; Izit hooked by current client?
	 jz	 short INT41_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*41h + offset PGROUP:INTPROC00Z ; Mark as INT 41h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT41_INTRETPM
INT41_INTRETPM:
	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT41	 endp			; End INT41 procedure
	 FPPROC  INT68 -- Windows Debugger Services
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Windows debugger services

If we're called from VM, continue on (the code at INTCOM_DPMI_INT
   will call any active DPMI clients).

If we're called from PM, and there are no DPMI clients active,
   ignore the call (MAX did this?).

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   ignore the call.

On entry:

SS:ESP	 ==>	 INTCOM_STR (if we're called from VM86 mode)
SS:ESP	 ==>	 INTDPI_STR (if we're called from DPMI)

|

	 test	 [esp].INTCOM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short INT68_XVM ; Jump if not

if @OEM_WIN3
	 test	 DOSX_FLAG,1	; Izit from within Windows Standard mode?
	 jz	 short INT68_VM ; Jump if not

	 cmp	 FILES_STR_LEN,0 ; Is HARPO installed?
	 je	 short INT68_VM ; Don't patch anything if not

	 cmp	 ah,43h 	; Windows Kernel debugger installation check?
	 jne	 INT68_X43	; Jump if not

;;;;;;; Pass the INT 68h AH=43h call on to the next handler
;;;;;;; If they return AX=F386h, we remember that fact and process
;;;;;;; AH=44h specially.  This will require a boat load of code to simulate
;;;;;;; a bunch of other debugger calls.  Another problem is that WDEB386
;;;;;;; seems to look at the caller in some way to ensure it's Windows.
;;;;;;; For now, if they want to use WDEB386 with Standard mode, let 'em
;;;;;;; disable HARPO.
;;;;;;
;;;;;;; SS:ESP ==> INTCOM_STR
;;;;;;
;;;;;;; Simulate a 32-bit IRET frame
;;;;;;
;;;;;;	 pushfd 		; Pass EFL
;;;;;;	 PUSHD	 cs		; ...  CS
;;;;;;	 PUSHD	 <offset cs:INT68_43_RET>
;;;;;;	 dw	 0		; 32-bit high-order word for PUSHD
;;;;;;
;;;;;;LC3_STR	 struc
;;;;;;	 dd	 ?		; Return EIP
;;;;;;	 dw	 ?,?		; ...	 CS w/ filler
;;;;;;	 dd	 ?		; ...	 EFL
;;;;;;LC3_INTCOM db	 (type INTCOM_STR) dup (?) ; Remainder of the stack
;;;;;;LC3_STR	 ends			; End LC3_STR structure
;;;;;;
;;;;;;; Because we came from VM and the VM stack may be reused, ensure
;;;;;;; we protect it via LAST_INTCOM
;;;;;;
;;;;;;	 lea	 eax,[esp].LC3_INTCOM.INTCOM_EIP ; Get INTCOM-restartable point
;;;;;;	 xchg	 eax,LAST_INTCOM ; Swap with the previous one
;;;;;;	 mov	 [esp].LC3_INTCOM.INTCOM_ICOMLO,ax ; Save to restore later
;;;;;;	 shr	 eax,16 	; Move down the high-order end
;;;;;;	 mov	 [esp].LC3_INTCOM.INTCOM_ICOMHI,ax ; Save to restore later
;;;;;;
;;;;;;	 FIJMP	 PGROUP:INTPROC68,DTE_CS2 ; Jump if so (call as VM INT 68h)
;;;;;;INT68_43_RET:
;;;;;;
;;;;;;; Control back from previous VM INT 68h handler (maybe WDEB386)
;;;;;;
;;;;;;; SS:ESP ==> INTCOM_STR
;;;;;;
;;;;;;	 mov	 ax,[esp].INTCOM_ICOMHI ; Get previous INTCOM-restartable point
;;;;;;	 shl	 eax,16 	; Move to high-order word
;;;;;;	 mov	 ax,[esp].INTCOM_ICOMLO ; Get previous INTCOM-restartable point
;;;;;;	 mov	 LAST_INTCOM,eax ; Restore original address

	 mov	 ax,0F386h	; Tell 'em yes, we are a kernel debugger
				; This tells KERNEL to send the INT 41h AX=4403h

	 jmp	 short INT68_INTRETPM ; Rejoin common IRETD code

INT68_X43:
	 cmp	 ax,4403h	; Izit prepare for VCPI operation?
	 jne	 short INT68_X44 ; Jump if not

; N.B. ESP must be the same here as it was upon entry to the INT68 procedure

	 push	 esp		; Pass a pointer to the INTCOM_STR
	 call	 INT68_4403	; Process the 4403h

	 jmp	 short INT68_INTRETPM ; Rejoin common IRETD code
INT68_X44:
endif				; IF @OEM_WIN3

INT68_VM:
	 FIXIJMP PGROUP:INTPROC68,DTE_CS2 ; Jump if so (call as VM INT 68h)

INT68_XVM:

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT68_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[68h/8],1 shl (68h mod 8) ; Izit hooked by current client?
	 jz	 short INT68_INTRETPM ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*68h + offset PGROUP:INTPROC00Z ; Mark as INT 68h

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT68_INTRETPM
INT68_INTRETPM:
	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT68	 endp			; End INT68 procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_N31 module
