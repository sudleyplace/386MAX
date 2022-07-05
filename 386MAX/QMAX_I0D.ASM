;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I0D.ASV   1.3   30 May 1997 10:44:38   BOB  $
	 title	 QMAX_I0D -- 386MAX INT 0Dh Handler
	 page	 58,122
	 name	 QMAX_I0D

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Data    segment WBPAT_SEG, word-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include CPUFLAGS.INC
	 include IOPBITS.INC
	 include 386.INC
	 include PTR.INC
	 include 8255.INC
	 include OPCODES.INC
	 include ALLMEM.INC
	 include MASM5.MAC
	 include CPUFET.INC
	include MOVSPR.INC

	 include QMAX_DTE.INC
	 include QMAX_DBG.INC
	 include QMAX_I31.INC
	 include QMAX_IDT.INC
	 include QMAX_OEM.INC
	 include QMAX_TRC.INC
	 include QMAX_TSS.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
FGROUP	 group	 FDATA
IGROUP	 group	 ICODE
JGROUP	 group	 JCODE,JDATA
XGROUP	 group	 WBPAT_SEG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


GPMAC	 macro	 NAM,OPCODE,EXT

	 public  $$&NAM
$$&NAM	 equ	 CNT+0
CNT	 =	 CNT*2

ifnb <EXT>
ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 GP_&NAM:near

ECODE	 ends			; End ECODE segment
else
	 public  GP_&NAM
endif				; IFNB

	 org	 GP_ACT+2*OPCODE
	 dw	 PGROUP:GP_&NAM

	 endm			; GPMAC


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_NF:byte
	 extrn	 MSG_L0D:byte
	 extrn	 MSG_CRn:byte

if @OEM_DEBUG
	 public  INT0DMSG_VM,INT0DMSG_NF
INT0DMSG_VM db	 'GP (not in VM)',0
INT0DMSG_NF db	 'GP (not found)',0
endif				; IF @OEM_DEBUG

FDATA	 ends			; End FDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 public  OLDREGINT0D_FVEC,OLDREGINT0D_ARB
	 public  REGINT0D_FVEC,REGINT0D_ARB
OLDREGINT0D_FVEC df ?		; Save area for old INT 0Dh handler
OLDREGINT0D_ARB db  ?		; ..			0Dh access rights byte
REGINT0D_ARB db  CPL0_INTR3 or CPL3 ; ...	new INT 0Dh access rights byte
REGINT0D_FVEC label fword	; ...			0Dh handler
	 dw	 JGROUP:TMPINT0D,0,DTE_CSJG

JDATA	 ends			; End JDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 FSEGSEL_BASE:far

	 public  @QMAX_I0D_JCODE
@QMAX_I0D_JCODE:		; Mark module start in .MAP file

	 FPPROC  GPJG_RDMSR -- Emulate RDMSR
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate RDMSR instruction

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

All EGP registers except EBP and ESP may be clobbered.

|

	 sub	 esp,type DTR_STR ; Make room for IDTR
	 SIDTD	 [esp].EDF	; Save on the stack
	 mov	 ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	 add	 esp,type DTR_STR ; Strip from the stack

	 call	 INST_TMPINT0D	  ; Install temporary INT 0Dh handler

	 mov	 ecx,[ebp].INTXX_ECX ; Get original value
	 clc			; Assume success
	 RDMSR			; Read Model-Specific Register
				; Return with CF significant from our
				; interrupt handler
	 call	 REST_TMPINT0D	; Restore temporary INT 0Dh handler
	 jc	 short GPJG_RDWRMSR_ERR ; Jump if not valid to common code

	 mov	 [ebp].INTXX_EAX,eax ; Return to caller
	 mov	 [ebp].INTXX_EDX,edx ; ...

;;;;;;;; clc			; Mark as valid (already clear)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GPJG_RDMSR endp 		; End GPJG_RDMSR procedure
	 FPPROC  GPJG_WRMSR -- Emulate WRMSR
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate WRMSR instruction

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

All EGP registers except EBP and ESP may be clobbered.

|

	 sub	 esp,type DTR_STR ; Make room for IDTR
	 SIDTD	 [esp].EDF	; Save on the stack
	 mov	 ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	 add	 esp,type DTR_STR ; Strip from the stack

	 call	 INST_TMPINT0D	  ; Install temporary INT 0Dh handler

	 mov	 ecx,[ebp].INTXX_ECX ; Get original value
	 mov	 eax,[ebp].INTXX_EAX ; ...
	 mov	 edx,[ebp].INTXX_EDX ; ...
	 clc			; Assume success
	 WRMSR			; Write Model-Specific Register
				; Return with CF significant from our
				; interrupt handler
	 call	 REST_TMPINT0D	; Restore temporary INT 0Dh handler
	 jnc	 short GPJG_WRMSR_EXIT ; Jump if valid (note CF=0)
GPJG_RDPMC_ERR:
GPJG_RDWRMSR_ERR:
	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

	 stc			; Mark as invalid
GPJG_WRMSR_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GPJG_WRMSR endp 		; End GPJG_WRMSR procedure
	FPPROC	GPJG_RDPMC -- Emulate RDPMC
	assume	ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate RDPMC instruction

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

All EGP registers except EBP and ESP may be clobbered.

|

	sub	esp,type DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF      ; Save on the stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	add	esp,type DTR_STR ; Strip from the stack

	call	INST_TMPINT0D	 ; Install temporary INT 0Dh handler

; Note that if this opcode isn't supported, the CPU signals
; an Invalid Opcode, so we don't need to test for support here.

	MOVSPR	eax,cr4 	; Get CPU extensions register
	or	eax,@PCE	; Mark as enabled
	MOVSPR	cr4,eax 	; Tell the CPU about it

	mov	ecx,[ebp].INTXX_ECX ; Get original value
	clc			; Assume success
	RDPMC			; Read the Performance Counter into EDX:EAX
				; Return with CF significant from our
				; interrupt handler
	call	REST_TMPINT0D	; Restore temporary INT 0Dh handler
	jc	short GPJG_RDPMC_ERR ; Jump if not valid to common code

	mov	[ebp].INTXX_EAX,eax ; Return to caller
	mov	[ebp].INTXX_EDX,edx ; ...

;;;;;;; clc			; Mark as valid (already clear)

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GPJG_RDPMC endp 		; End GPJG_RDPMC procedure
	 NPPROC  INST_TMPINT0D -- Install Temporary INT 0Dh Handler
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install temporary INT 0Dh handler

On entry:

EBX	 =	 linear address of IDT
SS:EBP	 ==>	 INTXX_STR

|

	 REGSAVE <eax,ds>	; Save registers

	 mov	 ds,SEL_DSJG3	; Get JGROUP data selector at PL3
	 assume  ds:JGROUP	; Tell the assembler about it

	 IDTMAC  0Dh,0D,REG,OLDREG,FORCE ; IDT to OLDREG, REG to IDT (EAX clobbered)

	 REGREST <ds,eax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_TMPINT0D endp		; End INST_TMPINT0D procedure
	 NPPROC  REST_TMPINT0D -- Restore Temporary INT 0Dh Handler
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore temporary INT 0Dh handler

On entry:

CF	 =	 1 if error in command
EBX	 =	 linear address of IDT
SS:EBP	 ==>	 INTXX_STR

|

	 pushf			; Save flags
	 REGSAVE <eax,ds>	; Save registers

	 mov	 ds,SEL_DSJG3	; Get JGROUP data selector at PL3
	 assume  ds:JGROUP	; Tell the assembler about it

	 IDTMAC  0Dh,0D,OLDREG,,FORCE ; OLDREG to IDT (EAX clobbered)

	 REGREST <ds,eax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_TMPINT0D endp		; End REST_TMPINT0D procedure
	 FPPROC  TMPINT0D -- Temporary INT 0Dh Handler
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local register INT 0Dh handler

This handler is called if the MSR index is not valid.

|

	 add	 esp,size INTXX_ERR ; Strip off error code

	 add	 [esp].NRM_EIP,2 ; Skip over the instruction
	 or	 [esp].NRM_EFL.ELO,mask $CF ; Set carry flag for the caller

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT0D endp			; End TMPINT0D procedure
	 align	 4		; Ensure dword alignment

JCODE	 ends			; End JCODE segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 FDPMIFN_LMSW:far
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DBG_FLAG:word
;;;;;;;; include QMAX_DBG.INC

if @OEM_DPMI
	 extrn	 PPL0STK_DNRM:dword
	 extrn	 PPL0STK_DERR:dword
	 extrn	 DPMITYPE:byte
endif				; IF @OEM_DPMI

	 extrn	 PPL0STK_NRM:dword
	 extrn	 PPL0STK_ERR:dword
if @OEM_DMA
	 extrn	 DMA_CHAN:byte
endif				; IF @OEM_DMA
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword

	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword

	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSJG3:word

	 extrn	 CPUTYPE:byte

if @OEM_DPMI
	 public  DPMICNT0D,INT0D_DPMIJMP
DPMICNT0D dw	 0		; Count of active INT 0Dh DPMI calls
INT0D_DPMIJMP dw ?		; Address of jump point
endif				; IF @OEM_DPMI

CNT	 =	 1		; Initialize count

	 public  GP_ACT
GP_ACT	 dw	 256 dup (PGROUP:INT0D_UGHNF)

; The prefixes *MUST* come first so that the $$NAM is non-zero

.sall
	 GPMAC	 ES   , @OPCOD_ES	; 0001
	 GPMAC	 CS   , @OPCOD_CS	; 0002
	 GPMAC	 SS   , @OPCOD_SS	; 0004
	 GPMAC	 DS   , @OPCOD_DS	; 0008
	 GPMAC	 FS   , @OPCOD_FS	; 0010
	 GPMAC	 GS   , @OPCOD_GS	; 0020
	 GPMAC	 OSP  , @OPCOD_OSP	; 0040
	 GPMAC	 ASP  , @OPCOD_ASP	; 0080
	 GPMAC	 LOCK , @OPCOD_LOCK	; 0100
	 GPMAC	 REPNE, @OPCOD_REPNE	; 0200
	 GPMAC	 REP  , @OPCOD_REP	; 0400

; Closely followed by the instructions

	 GPMAC	 ESCOD,@OPCOD_2ND	;
	 GPMAC	 FJMP ,@OPCOD_JMPF	;
	 GPMAC	 INIB ,@OPCOD_INIB,EXT	;
	 GPMAC	 INIW ,@OPCOD_INIW,EXT	;
	 GPMAC	 OUTIB,@OPCOD_OUTIB,EXT ;
	 GPMAC	 OUTIW,@OPCOD_OUTIW,EXT ;
	 GPMAC	 INDB ,@OPCOD_INDB,EXT	;
	 GPMAC	 INDW ,@OPCOD_INDW,EXT	;
	 GPMAC	 OUTDB,@OPCOD_OUTDB,EXT ;
	 GPMAC	 OUTDW,@OPCOD_OUTDW,EXT ;
	 GPMAC	 HLT  ,@OPCOD_HLT	;
	 GPMAC	 CLI  ,@OPCOD_CLI	;
	 GPMAC	 STI  ,@OPCOD_STI	;
;;;;;;;; GPMAC	 INSB ,@OPCOD_INSB,EXT	 ;
;;;;;;;; GPMAC	 INSW ,@OPCOD_INSW,EXT	 ;
;;;;;;;; GPMAC	 OUTSB,@OPCOD_OUTSB,EXT  ;
;;;;;;;; GPMAC	 OUTSW,@OPCOD_OUTSW,EXT  ;
.xall

	 org	 GP_ACT+2*256

	 public  FLG_GET_CRn,FLG_GET_DRn,FLG_GET_TRn
FLG_GET_CRn db	 00001101b	; Allow 3, 2, and 0
FLG_GET_DRn db	 11111111b	; Allow 7, 6, 5, 4, 3, 2, 1, and 0
FLG_GET_TRn db	 11000000b	; Allow 7 and 6

	 public  FLG_SET_CRn,FLG_SET_DRn,FLG_SET_TRn
FLG_SET_CRn db	 00000101b	; Allow 2, and 0
FLG_SET_DRn db	 11111111b	; Allow 7, 6, 5, 4, 3, 2, 1, and 0
FLG_SET_TRn db	 11000000b	; Allow 7 and 6

; Define external cache default.  256K is the optimal size for most systems.
@CACHESIZE_D equ (256*(1024/4)) ; Size in dwords

	 public  CACHESIZE
CACHESIZE dd	 @CACHESIZE_D * 2 ; External cache size in dwords * 2

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I0D_ECODE
@QMAX_I0D_ECODE:		; Mark module start in .MAP file

	 extrn	 INTPROC01:near
	 extrn	 INTPROC06:near
	 extrn	 INTPROC0D:near
	 extrn	 INTXXCOM:near
	 extrn	 INTCOM_DPMI_FAULT:near
	 extrn	 CHECK_SYSROM:near
	 extrn	 GOREAL:near
	 extrn	 IRETD_COM:near
	 extrn	 HARDINT:near
	 extrn	 GETILEN:near
	 extrn	 INTPROC00Z:near
if @OEM_DMA
	 extrn	 CHECK_PART:near
endif				; IF @OEM_DMA

if @OEM_DPMI
	 extrn	 INTCOM_DPMI_INT:near
endif				; IF @OEM_DPMI
	 extrn	 DSTK_CHK:near

	 NPPROC  CACHE_INVD -- Invalidate cache by hand
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Some Gateway systems have a broken WBINVD instruction (INVD is broken as
well).	This is due to a hardware bug in the chipset, which they don't
seem to work around properly in their motherboard design.  Their systems
which use Intel motherboards with the same chipset don't have this problem.

There's a software workaround, which is basically not to use WBINVD.
We do this when we detect a Gateway BIOS (i.e. Gateway motherboard) or
when the NOGATE option is specified.

The workaround is to read twice as much data as the cache contains.
This could be 512K to 1MB (the P54C has a 512K cache).

This routine is called only in protected mode under MAX's GDT.

|

	 REGSAVE <eax,ecx,dx,esi,ds> ; Save

	 pushf			; Save interrupt flag

	 cld			; Set forward direction

	 cli			; Nobody move

	 mov	 ds,SEL_4GB3	; Address all memory selector
	 assume  ds:nothing	; Tell the assembler

	 mov	 ecx,CACHESIZE	; Size of cache in dwords
	 sub	 esi,esi	; Starting offset
 S32 rep lods	 <ds:[esi].EDD> ; Read it

	 popf			; Restore IF

	 REGREST <ds,esi,dx,ecx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CACHE_INVD endp 		; End CACHE_INVD procedure

	 FPPROC  INT0D -- General Protection Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

General protection interrupt (0Dh) with error code on stack.

Distinguish amongst four cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0D
GP		 VM86	  ESP=PPL0STK_ERR	Parse caller's CS:IP
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto INTCOM_DPMI_INT
GP		 DPMI	  ESP=PPL0STK_DERR	Parse caller's CS:IP
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
GP		 PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Izit a HW/SW interrupt from VM86 mode?
	 je	 short INT0D_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 near ptr INT0D_VM86 ; Yes

if @OEM_DPMI
	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT0D_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 near ptr INT0D_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 near ptr INT0D_UGHMAX ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0D_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*0Dh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Dh

	 jmp	 HARDINT	; It's a hardware interrupt


INT0D_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*0Dh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Dh

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC0D	; Use normal interrupt processor


if @OEM_DPMI

; Hardware/software interrupt from a DPMI client

INT0D_DPMI_INT:
	 mov	 [esp].NRM_INTNO,4*0Dh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Dh

	 jmp	 INTCOM_DPMI_INT ; Join common DPMI interrupt code


; Fault from a DPMI client -- see if we can emulate it
; The stack is mapped by INTDPF_STR -- move it down to look like
; INTXX_STR.

INT0D_DPMI_FAULT:

@STK_DIFF equ	 4*4		; Size of GSF, FSF, DSF, and ESF

	 sub	 esp,@STK_DIFF	; Make room for GSF, FSF, DSF, and ESF

	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 eax,[ebp].INTXX_ERR[@STK_DIFF] ; Get original error code
	 mov	 [ebp].INTXX_ERR,eax ; Save in new home

	 mov	 eax,[ebp].INTXX_EIP[@STK_DIFF] ; Get original EIP
	 mov	 [ebp].INTXX_EIP,eax ; Save in new home

	 mov	 eax,[ebp].INTXX_CS.EDD[@STK_DIFF] ; Get original CS w/filler
	 mov	 [ebp].INTXX_CS.EDD,eax ; Save in new home

	 mov	 eax,[ebp].INTXX_EFL[@STK_DIFF] ; Get original EFL
	 mov	 [ebp].INTXX_EFL,eax ; Save in new home

	 mov	 eax,[ebp].INTXX_ESP[@STK_DIFF] ; Get original ESP
	 mov	 [ebp].INTXX_ESP,eax ; Save in new home

	 mov	 eax,[ebp].INTXX_SS.EDD[@STK_DIFF] ; Get original SS w/filler
	 mov	 [ebp].INTXX_SS.EDD,eax ; Save in new home

	 mov	 [ebp].INTXX_ES,es ; Save for later use
	 mov	 [ebp].INTXX_DS,ds ; ...
	 mov	 [ebp].INTXX_FS,fs ; ...
	 mov	 [ebp].INTXX_GS,gs ; ...

	 REGSAVE <ds,es>	; Save selectors

	 assume  ss:PGROUP	; Tell the assembler about it
	 inc	 DPMICNT0D	; Count in another one
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 short INT0D_VM86A ; Join common code

	 assume  ds:nothing	; Tell the assembler about it

endif				; IF @OEM_DPMI
INT0D_VM86:
	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
INT0D_VM86A:
	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 [ebp].INTXX_INTNO,4*0Dh + offset PGROUP:INTPROC00Z ; Mark as INT 0Dh

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 lea	 eax,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with the last one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,ax ; Save to restore later
@@:

if @OEM_DMA

; Check on DMA terminations

	 cmp	 DMA_CHAN,0	; Any DMA channels active?
	 jne	 short INT0D_DMA ; Yes, check 'em out
				; All segment registers clobbered
INT0D_XDMA:
endif				; IF @OEM_DMA

; Search through the caller's code segment for prefixes and
; finally the instruction to emulate

	 push	 DTE_D4GB	; Get all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 esi,[ebp].INTXX_CS ; Get code selector
	 FIXICALL JGROUP:FSEGSEL_BASE,DTE_CSJG ; Return with ESI = segment/selector base
;;;;;;;; jc	 short ???	; Ignore error return
	 mov	 eax,[ebp].INTXX_EIP ; Get caller's IP
	 add	 esi,eax	; ES:ESI ==> caller's instruction stream
	 mov	 [ebp].INTXX_OIPLO,ax ; Save in case we need it
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_OIPHI,ax ; Save in case we need it
	 xor	 bx,bx		; Zero prefix flag word

; ES:ESI =   CS3:EIP3	(User's CS:IP)

INT0D_OPCODE:
	 lods	 AGROUP:[esi].LO ; Get next instruction byte

	 inc	 [ebp].INTXX_EIP ; Skip past the instruction byte
	 movzx	 eax,al 	; Zero the rest of the register

	 jmp	 GP_ACT[eax*2]	; Take appropriate action

if @OEM_DMA
INT0D_DMA:
	 call	 CHECK_PART	; Check on partial DMA transfers in progress
				; ES and FS clobbered
	 jmp	 short INT0D_XDMA ; Join common code
endif				; IF @OEM_DMA

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_ES:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$ES	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_CS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$CS	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_SS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$SS	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_DS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$DS	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_FS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$FS	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_GS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$GS	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_OSP:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$OSP	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_ASP:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$ASP	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_LOCK:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$LOCK	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_REPNE:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$REPNE	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_REP:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 bx,$$REP	; Mark as present

	 jmp	 INT0D_OPCODE	; Go around again

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_HLT:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 test	 [ebp].INTXX_EFL.ELO,mask $IF ; Test IF
	 jnz	 short GP_HLT1	; Return to caller at CS:IP

	 test	 DBG_FLAG,@DBG_HLT ; Signal NMI instead?
	 jz	 short GP_HLT2	; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Mark as NMI occurred

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_HLT1:
	 sti			; Allow interrupts
	 hlt

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_HLT2:
	 cli			; Stop the presses
	 hlt

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_CLI:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 and	 [ebp].INTXX_EFL.ELO,not (mask $IF) ; IF=0

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_STI:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 or	 [ebp].INTXX_EFL.ELO,mask $IF ; IF=1

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it
GP_FJMP:			; Retry the instruction at CS:IP
	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_INVD:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 invd			; Invalidate cache

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_WBINVD:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 wbinvd 		; Write-back and invalidate cache

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_CLTS:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 clts			; Clear task switched flag in CR0

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_RDMSR:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 FIXICALL JGROUP:GPJG_RDMSR,DTE_CSJG ; Attempt to emulate it
	 jnc	 near ptr INT0D_IRETD ; Jump if all went well

	 jmp	 INT0D_SOR	; Jump if not valid

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_WRMSR:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 FIXICALL JGROUP:GPJG_WRMSR,DTE_CSJG ; Attempt to emulate it
	 jnc	 near ptr INT0D_IRETD ; Jump if all went well

	 jmp	 INT0D_SOR	; Jump if not valid

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_RDTSC:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

; Note that if this opcode isn't supported, the CPU signals
; an Invalid Opcode, so we don't need to test for support here.

	 RDTSC			; Read the Time Stamp Counter into EDX:EAX
	 mov	 [ebp].INTXX_EAX,eax ; Return to caller
	 mov	 [ebp].INTXX_EDX,edx ; ...

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_RDPMC:
	assume	ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	FIXICALL JGROUP:GPJG_RDPMC,DTE_CSJG ; Attempt to emulate it
	jnc	near ptr INT0D_IRETD ; Jump if all went well

	jmp	INT0D_SOR	; Jump if not valid

	assume	ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
GP_ESCOD:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lods	 AGROUP:[esi].LO ; Get next instruction byte

	 inc	 [ebp].INTXX_EIP ; Skip past the instruction byte

	 cmp	 al,@OPCOD_CLTS shr 8 ; Check for CLTS instruction
	 je	 short GP_CLTS	; Good guess

	 cmp	 al,@OPCOD_INVD shr 8 ; Check for INVD instruction
	 je	 short GP_INVD	; Good guess

	 cmp	 al,@OPCOD_WBINVD shr 8 ; Check for WBINVD instruction
	 je	 short GP_WBINVD  ; Good guess

	 cmp	 al,@OPCOD_MOV_R32_CRn shr 8 ; Check for MOV r32,CRn
	 je	 near ptr GP_MOV_R32_CRn ; Good guess

	 cmp	 al,@OPCOD_MOV_R32_DRn shr 8 ; Check for MOV r32,DRn
	 je	 near ptr GP_MOV_R32_DRn ; Good guess

	 cmp	 al,@OPCOD_MOV_R32_TRn shr 8 ; Check for MOV r32,TRn
	 je	 near ptr GP_MOV_R32_TRn ; Good guess

	 cmp	 al,@OPCOD_MOV_CRn_R32 shr 8 ; Check for MOV CRn,r32
	 je	 near ptr GP_MOV_CRn_R32 ; Good guess

	 cmp	 al,@OPCOD_MOV_DRn_R32 shr 8 ; Check for MOV DRn,r32
	 je	 near ptr GP_MOV_DRn_R32 ; Good guess

	 cmp	 al,@OPCOD_MOV_TRn_R32 shr 8 ; Check for MOV TRn,r32
	 je	 near ptr GP_MOV_TRn_R32 ; Good guess

	 cmp	 al,@OPCOD_GRP7 shr 8 ; Check for Group 7 instructions
	 je	 near ptr GP_GRP7 ; Good guess

	 cmp	 al,@OPCOD_RDMSR shr 8 ; Izit RDMSR?
	 je	 near ptr GP_RDMSR ; Good guess

	 cmp	 al,@OPCOD_WRMSR shr 8 ; Izit WRMSR?
	 je	 short GP_WRMSR ; Good guess

	 cmp	 al,@OPCOD_RDTSC shr 8 ; Izit RDTSC?
	 je	 short GP_RDTSC ; Good guess

	 cmp	 al,@OPCOD_RDPMC shr 8 ; Izit RDPMC?
	 je	 short GP_RDPMC ; Good guess

	 jmp	 INT0D_UGHNF	; It's not found

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	 public  GP_MOV_R32_CRN
GP_MOV_R32_CRN:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_R32_CRnA[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_R32_CRn	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_GET_CRn 	; DL = flags of valid register

	 jmp	 short GP_MOV_R32_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  GP_MOV_R32_DRN
GP_MOV_R32_DRN:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_R32_DRnA[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_R32_DRn	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_GET_DRn 	; DL = flags of valid register

	 jmp	 short GP_MOV_R32_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  GP_MOV_R32_TRN
GP_MOV_R32_TRN:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_R32_TRnA[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_R32_TRn	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_GET_TRn 	; DL = flags of valid register

;;;;;;;; jmp	 short GP_MOV_R32_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

GP_MOV_R32_COM:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lods	 AGROUP:[esi].LO ; Get next instruction byte

	 inc	 [ebp].INTXX_EIP ; Skip past the instruction byte

	 mov	 cl,al		; Copy to test for validity
	 and	 cl,mask $REG	; Isolate control register bits
	 shr	 cl,$REG	; Shift to low-order
	 mov	 ch,1		; Strobe bit
	 shl	 ch,cl		; Set bit in place

	 test	 dl,ch		; Izit a valid register?
	 jz	 near ptr INT0D_INVOPCOD ; No, call it an invalid opcode

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 si,ax		; Save original value
	 and	 al,not mask $RM ; Zero R/M field (set EGP register to EAX)
S16	 stosb			; Save into instruction
	 call	 bx		; Execute subroutine

	 and	 esi,mask $RM	; Isolate the r/m field (EGP register #)
	 neg	 si		; Subtract from 7
	 add	 si,mask $RM
	 shl	 si,2		; Times 4 to index table of dwords
	 mov	 [ebp+esi],eax	; Save output value on stack

	 jmp	 INT0D_IRETD	; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	 public  GP_MOV_CRN_R32
GP_MOV_CRN_R32:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_CRn_R32A[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_CRn_R32	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_SET_CRn 	; DL = flags of valid register

	 jmp	 short GP_MOV_CRn_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  GP_MOV_DRN_R32
GP_MOV_DRN_R32:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_DRn_R32A[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_DRn_R32	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_SET_DRn 	; DL = flags of valid register

	 jmp	 short GP_MOV_CRn_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  GP_MOV_TRN_R32
GP_MOV_TRN_R32:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lea	 di,INS_MOV_TRn_R32A[2] ; CS:DI ==> MOD-REG-R/M byte
	 lea	 bx,INS_MOV_TRn_R32	; CS:BX ==> subroutine to call
	 mov	 dl,FLG_SET_TRn 	; DL = flags of valid register

;;;;;;;; jmp	 short GP_MOV_CRn_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

GP_MOV_CRN_COM:
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it

	 lods	 AGROUP:[esi].LO ; Get next instruction byte

	 inc	 [ebp].INTXX_EIP ; Skip past the instruction byte

	 mov	 cl,al		; Copy to test for validity
	 and	 cl,mask $REG	; Isolate control register bits
	 shr	 cl,$REG	; Shift to low-order
	 mov	 ch,1		; Strobe bit
	 shl	 ch,cl		; Set bit in place

	 test	 dl,ch		; Izit a valid register?
	 jz	 near ptr INT0D_INVOPCOD ; No, call it an invalid opcode

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 si,ax		; Save original value
	 and	 al,not mask $RM ; Zero r/m field (EGP register to EAX)
S16	 stosb			; Save into instruction

	 and	 esi,mask $RM	 ; Isolate the r/m field (EGP register #)
	 neg	 si		; Subtract from 7
	 add	 si,mask $RM
	 shl	 si,2		; Times 4 to index table of dwords
	 mov	 eax,[ebp+esi]	; Get input value from stack

	 call	 bx		; Execute subroutine

; If this is not a move into CR0, there's no further action to take.
; If we're coming from VM, transfer the $EM bit into the MSW
; for VM operation.  Otherwise, transfer it into the DPMI MSW.

	 cmp	 bx,offset PGROUP:INS_MOV_CRn_R32 ; Izit move into CRn?
	 jne	 short GP_MOV_CRN_COM1 ; Jump if not

	 cmp	 cl,00h 	; Izit move into CR0?
	 jne	 short GP_MOV_CRN_COM1 ; Jump if not

	 mov	 ebx,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM?
	 jnz	 short @F	; Jump if so

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of the current TSS
@@:
	 and	 ax,mask $EM	; Isolate $EM bit
	 and	 PGROUP:[ebx].DPTSS_MSW,not (mask $EM) ; Clear old $EM bit
	 or	 PGROUP:[ebx].DPTSS_MSW,ax ; Save new value for $EM bit
GP_MOV_CRN_COM1:
	 jmp	 short INT0D_IRETD ; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	 assume  ds:PGROUP,es:AGROUP,ss:nothing ; Tell the assembler about it
	 page
GP_GRP7:
	 mov	 al,AGROUP:[esi] ; Get Mod R/M byte
	 and	 al,mask $REG	; Isolate the REG bits

; Check for LMSW reg which we'll emulate

	 cmp	 al,110b shl $REG ; Check for LMSW
	 jne	 near ptr INT0D_UGHNF ; It's not found

; It's LMSW -- save the value into the low-order word of CR0

	 mov	 al,AGROUP:[esi] ; Get Mod R/M byte
	 and	 al,mask $MOD	; Isolate the MOD bits

	 cmp	 al,11b shl $MOD ; Check for register source
	 jne	 short GP_GRP7_LMSW_EXIT ; Jump if not

	 movzx	 edi,AGROUP:[esi].LO ; Get Mod R/M byte
	 and	 di,mask $RM	; Isolate the RM bits
	 shr	 di,$RM 	; Shift to low-order
	 sub	 di,111b	; Subtract from largest value to invert
	 neg	 di		; Negate to complete the inversion
	 shl	 di,2-0 	; Times four to index table of dwords
	 mov	 ax,[ebp+edi].INTXX_EDI.ELO ; Get the incoming value
	 or	 ax,mask $PE	; Ensure we're still in PM
	 lmsw	 ax		; Tell the CPU about it

; If we're coming from VM, transfer the $EM bit into the MSW
; for VM operation.  Otherwise, transfer it into the DPMI MSW.

	 mov	 ebx,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM?
	 jnz	 short @F	; Jump if so

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of the current TSS
@@:
	 and	 ax,mask $EM	; Isolate $EM bit
	 and	 PGROUP:[ebx].DPTSS_MSW,not (mask $EM) ; Clear old $EM bit
	 or	 PGROUP:[ebx].DPTSS_MSW,ax ; Save new value for $EM bit
if @OEM_DPMI

; Ensure IGROUP is present

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short @F	; Jump if so

	 push	 ebx		; Pass offset in PGROUP of TSS
	 FIXICALL IGROUP:FDPMIFN_LMSW,DTE_CSIG ; Put MSW and INT 07h values into effect
@@:
endif				; IF @OEM_DPMI
GP_GRP7_LMSW_EXIT:

; Determine the instruction length and skip over it

	 sub	 esi,2		; Skip over two-byte code to start of instruction

	 call	 GETILEN	; Return with AX = length of instruction
				;  with DS:ESI==> Mod R/M byte
	 movzx	 eax,ax 	; Zero to use as dword
	 sub	 ax,2		; Less two-byte opcode already accounted for
	 add	 [ebp].INTXX_EIP,eax ; Skip to the next insrtuction

	 jmp	 short INT0D_IRETD ; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it
	 page
; อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	 assume  ds:nothing,es:nothing,ss:PGROUP ; Tell the assembler about it

; N.B.:  THE FOLLOWING CODE IS DUPLICATED AT INT67_IRETD
; If there's DPMI client active, all entries to this label
; *MUST* REGSAVE <ds,es> and PUSH/POP any other selectors used
; as well as setup the stack to look like INTXX_STR.

	 public  INT0D_IRETD
INT0D_IRETD:
	 cli			; Disable interrupts

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous INTCOM-restartable point
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous INTCOM-restartable point
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore
@@:
if @OEM_DPMI

; If this was a fault from a DPMI client, we need to restore selectors
; and the stack

	 cmp	 DPMICNT0D,0	; Izit active?
	 je	 short INT0D_XDPMI ; Jump if not

	 dec	 DPMICNT0D	; Count it out

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 mov	 eax,[ebp].INTXX_SS.EDD ; Get current SS w/filler
	 mov	 [ebp].INTXX_SS.EDD[@STK_DIFF],eax ; Save back

	 mov	 eax,[ebp].INTXX_ESP ; Get current ESP
	 mov	 [ebp].INTXX_ESP[@STK_DIFF],eax ; Save back

	 mov	 eax,[ebp].INTXX_EFL ; Get current EFL
	 mov	 [ebp].INTXX_EFL[@STK_DIFF],eax ; Save back

	 mov	 eax,[ebp].INTXX_CS.EDD ; Get current CS w/filler
	 mov	 [ebp].INTXX_CS.EDD[@STK_DIFF],eax ; Save back

	 mov	 eax,[ebp].INTXX_EIP ; Get current EIP
	 mov	 [ebp].INTXX_EIP[@STK_DIFF],eax ; Save back

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,@STK_DIFF + (size INTXX_ERR) ; Strip off error code
				; and restore stack to original state

	 iretd			; Return to caller

INT0D_XDPMI:
endif				; IF @OEM_DPMI
	 public  INT0D_IRETD1
INT0D_IRETD1:
	 test	 [ebp].INTXX_EFL.ELO,mask $TF ; Single stepping?
	 jnz	 short INT0D_IRET_TF ; Yes

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 IRETD_COM	; Return to caller

	 public  INT0D_IRET_TF
INT0D_IRET_TF:
	 mov	 eax,dr6	; Get the debug status register
	 or	 ax,mask $BS	; Set the single-step bit
	 mov	 dr6,eax	; Set new value

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 INTPROC01	; Call it a single-step interrupt

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

; Fault while running in MAX
; The stack is mapped by FLT_STR

INT0D_UGHMAX:
	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 si,4*0Dh	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L0D ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT0DMSG_VM ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 INTXXCOM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  INT0D_UGHNF
INT0D_UGHNF:
	 assume  ds:PGROUP,es:nothing,ss:nothing ; Tell the assembler about it
if @OEM_DPMI

; Note IF=0 (so we can save into INT0D_DPMIJMP)

	 mov	 INT0D_DPMIJMP,offset PGROUP:INT0D_UGHNF1 ; Save jump address

	 public  INT0D_DPMIREST
INT0D_DPMIREST:
endif				; IF @OEM_DPMI
	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

if @OEM_DPMI

; If this was a fault from a DPMI client, we need to restore selectors
; and the stack

	 cmp	 DPMICNT0D,0	; Izit active?
	 je	 short INT0D_DPMIREST_EXIT ; Jump if not

	 dec	 DPMICNT0D	; Count it out

	 REGREST <es,ds>	; Restore selectors
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

; The stack is mapped by INTXX_STR -- restore it to its original state

	 mov	 eax,[ebp].INTXX_SS.EDD ; Get original SS w/filler
	 mov	 [ebp].INTXX_SS.EDD[@STK_DIFF],eax ; Restore

	 mov	 eax,[ebp].INTXX_ESP ; Get original ESP
	 mov	 [ebp].INTXX_ESP[@STK_DIFF],eax ; Restore

	 mov	 eax,[ebp].INTXX_EFL ; Get original EFL
	 mov	 [ebp].INTXX_EFL[@STK_DIFF],eax ; Restore

	 mov	 eax,[ebp].INTXX_CS.EDD ; Get original CS w/filler
	 mov	 [ebp].INTXX_CS.EDD[@STK_DIFF],eax ; Restore

	 mov	 eax,[ebp].INTXX_EIP ; Get original EIP
	 mov	 [ebp].INTXX_EIP[@STK_DIFF],eax ; Restore

	 mov	 eax,[ebp].INTXX_ERR ; Get original error code
	 mov	 [ebp].INTXX_ERR[@STK_DIFF],eax ; Restore

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,@STK_DIFF	; Strip off GSF, FSF, DSF, and ESF

; The stack is mapped by INTDPF_STR
; Note that INTDPF_INTNO is already filled in with the
; INT # times 4 + offset PGROUP:INTPROC00Z

; If this fault came from a DPMI client, give 'em a crack at it.
; If it came from VM, abort.

	 test	 [esp].INTDPF_EFL.EHI,mask $VM ; Izit from V86 mode?
	 jz	 near ptr INTCOM_DPMI_FAULT ; Jump if not
INT0D_DPMIREST_EXIT:
	 jmp	 INT0D_DPMIJMP	; Continue with next routine

INT0D_UGHNF1:
endif				; IF @OEM_DPMI
	 test	 DBG_FLAG,@DBG_SOR ; Signal segment overrun?
	 jnz	 short INT0D_SOR ; Yes, do so

	 test	 DBG_FLAG,@DBG_INV ; Signal invalid opcode?
	 jnz	 near ptr INT0D_INVOPCOD1 ; Yes, do so

	 mov	 si,4*0Dh	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_NF ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT0DMSG_NF ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 INTXXCOM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  INT0D_SOR
INT0D_SOR:
	 assume  ds:PGROUP,es:nothing,ss:nothing ; Tell the assembler about it

	 cli			; Ensure disabled

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 INTPROC0D	; Handle as segment overrun

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

	 public  INT0D_INVOPCOD
INT0D_INVOPCOD:
	 assume  ds:PGROUP,es:nothing,ss:nothing ; Tell the assembler about it
if @OEM_DPMI

; Note IF=0 (so we can save into INT0D_DPMIJMP)

	 mov	 INT0D_DPMIJMP,offset PGROUP:INT0D_INVOPCOD1 ; Save jump address

	 jmp	 INT0D_DPMIREST ; Join common code
else
	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

endif				; IF @OEM_DPMI
INT0D_INVOPCOD1:
	 cli			; Ensure disabled

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 INTPROC06	; Handle as invalid opcode

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0D	 endp			; End INT0D procedure
	 NPPROC  INS_MOV_R32_CRn
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV R32,CRn

On entry:

CL	 =	 CRn register # (00=CR0, etc.)

On exit:

EAX	 =	 current CRn

|

INS_MOV_R32_CRnA:
	 mov	 eax,cr0	; Get current CR0

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_R32_CRn endp		; End INS_MOV_R32_CRn procedure
	 NPPROC  INS_MOV_R32_DRn
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV R32,DRn

On entry:

CL	 =	 DRn register # (00=DR0, etc.)

On exit:

EAX	 =	 current DRn

|

INS_MOV_R32_DRnA:
	 mov	 eax,dr0

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_R32_DRn endp		; End INS_MOV_R32_DRn procedure
	 NPPROC  INS_MOV_R32_TRn
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV R32,TRn  taking care to avoid spurious DRn breakpoints.

On entry:

CL	 =	 TRn register # (00=TR0, etc.)

On exit:

EAX	 =	 current TRn

|

	 push	 ebx		; Save for a moment

	 mov	 ebx,dr7	; Get debug command register
	 push	 ebx		; Save on stack

; Clear G0-3 and L0-3

;;;;;;;; and	 ebx,not ((mask $G3) or (mask $G2) or (mask $G1) or (mask $G0)\
;;;;;;;;	       or (mask $L3) or (mask $L2) or (mask $L1) or (mask $L0))
	 mov	 bl,0		; Clear 'em this way
	 mov	 dr7,ebx	; Restore
INS_MOV_R32_TRnA:
	 mov	 eax,tr6	; Read the appropriate test register
	 jmp	 short $+2	; Drain the PIQ

	 pop	 ebx		; Get original DR7
	 mov	 dr7,ebx	; Restore

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_R32_TRn endp		; End INS_MOV_R32_TRn procedure
	 NPPROC  INS_MOV_CRn_R32
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV CRn,R32

On entry:

EAX	 =	 caller's value for CRn
CL	 =	 CRn register # (00=CR0, etc.)

|

	 cmp	 cl,00h 	; Izit move into CR0?
	 jne	 short INS_MOV_CRn_R32A ; Jump if not

	 call	 CHECK_SYSROM	; Is caller in system ROM?
	 jnae	 short INS_MOV_CRn_R32B ; No, continue on

	 test	 ax,mask $PE	; Izit disabling Protect Enable?
	 jnz	 short INS_MOV_CRn_R32B ; No, continue on

	 lea	 bx,FGROUP:MSG_CRn ; Reason code for move into CRn in system ROM

; Yes, exit VM86 mode

	 jmp	 GOREAL 	; Jump to code to enter real mode

INS_MOV_CRn_R32B:

; Ensure paging and protected mode set

	 or	 eax,(mask $PG) or (mask $PE)

; If we're to Disable the Write-through and this CPU supports INVD/WBINVD,
; also disable the cache(s) via INVD and WBINVD.

	 test	 eax,mask $NW	; Izit set?
	 jz	 short INS_MOV_CRn_R32A ; Jump if not

; Note that INSTALL and / or MAXIMIZE may use this instruction, so we
; emulate WBINVD by hand unless DEBUG=WBINVD was specified.  BIOSes should
; not use it if it doesn't work.
	 cmp	 CPUTYPE,04h	; Izit a 486?
	 jb	 short INS_MOV_CRn_R32_EXIT ; Jump if not

	 WBPAT	 CACHE_INVD,PGROUP ; Invalidate and flush cache by hand

	 mov	 cr0,eax	; Set current CR0

	 jmp	 short INS_MOV_CRn_R32_EXIT ; Join common exit code

INS_MOV_CRn_R32A:
	 mov	 cr0,eax	; Set current CR0

; Flush the pre-fetch instruction queue after messing with the paging bit

	 jmp	 short $+2	; Flush it

INS_MOV_CRn_R32_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_CRn_R32 endp		; End INS_MOV_CRn_R32 procedure
	 NPPROC  INS_MOV_DRn_R32
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV DRn,R32

On entry:

EAX	 =	 caller's value for DRn
CL	 =	 DRn register # (00=DR0, etc.)

|

INS_MOV_DRn_R32A:
	 mov	 dr0,eax

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_DRn_R32 endp		; End INS_MOV_DRn_R32 procedure
	 NPPROC  INS_MOV_TRn_R32
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate 	 MOV TRn,R32

On entry:

EAX	 =	 caller's value for TRn
CL	 =	 TRn register # (00=TR0, etc.)

|

INS_MOV_TRn_R32A:
	 mov	 tr6,eax

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INS_MOV_TRn_R32 endp		; End INS_MOV_TRn_R32 procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_I0D module
