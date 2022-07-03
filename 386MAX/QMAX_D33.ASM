;' $Header:   P:/PVCS/MAX/386MAX/QMAX_D33.ASV   1.2   30 May 1997 10:44:16   BOB  $
	 title	 QMAX_D33 -- 386MAX DPMI INT 33h Translation Services
	 page	 58,122
	 name	 QMAX_D33

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Data    segment ACTSEG,word-aligned,  public, class 'idata'

Program derived from:  None.

Original code by:  Bob Smith, October, 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DPMI.INC
	 include ALLMEM.INC
	 include CPUFLAGS.INC
	 include MASM5.MAC
	 include BITFLAGS.INC

	 include QMAX_OEM.INC
	 include QMAXDPMI.INC
	 include QMAX_DTE.INC
	 include QMAX_TSS.INC
.list

if @OEM_DPMI

PGROUP	 group	 ECODE,EDATA
IGROUP	 group	 LCODE,ICODE,IDATA,ACTSEG


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 INTPROC00Z:near
	 extrn	 FSET_PPL0STK:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I31_FLAG:word
	 include QMAX_I31.INC

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
	 include QMAX_VMM.INC

	 extrn	 PageFaultActive:byte
endif

	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword

	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 VMCREGS:tbyte
	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 DPMI_IDEF:word
	 extrn	 LPMSTK_FVEC:fword
	 extrn	 LPMSTK_CNT:dword
	 extrn	 LAST_DPMI_DS:word
	 extrn	 LAST_DPMI_ES:word
	 extrn	 LAST_DPMI_FS:word
	 extrn	 LAST_DPMI_GS:word
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword

	 extrn	 OLD_PCURTSS:dword
	 extrn	 SAVE_EAX:dword

	 extrn	 LaINDOS:dword

EDATA	 ends			; End EDATA segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 GETSELBASE:far

LCODE	 ends			; End LCODE segment

; Define mouse INT 33h functions which we handle

DPMIMOUSEMAC macro VAL,ACT

ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 org	 DPMIMOUSE_ACT + VAL * (type DPMIMOUSE_ACT) ; Set to appropriate origin
	 dw	 IGROUP:INT33_DPMIJMP_&ACT
	 org	 DPMIMOUSE_ACTZ  ; Restore to end of the table

ACTSEG	 ends			; End ACTSEG segment

	 endm			; DPMIMOUSEMAC


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 public  DPMIMOUSE_ACT
DPMIMOUSE_ACT dw  256 dup (IGROUP:INT33_DPMIJMP_PASSTHRU) ; Seed with pass through action
DPMIMOUSE_ACTZ label word

ACTSEG	 ends			; End ACTSEG segment


; The following mouse functions require special treatment

.sall
	 DPMIMOUSEMAC	09h,SETSHAPE	; 09:  Set Pointer Shape
	 DPMIMOUSEMAC	0Ch,HOOKMEI	; 0C:  Hook Mouse Event Interrupt
	 DPMIMOUSEMAC	14h,SWAPINT	; 14:  Swap Mouse Interrupt Subroutines
	 DPMIMOUSEMAC	15h,GETSSRSIZE	; 15:  Get State Save/Restore Buffer Size
	 DPMIMOUSEMAC	16h,SAVESTATE	; 16:  Save Driver State
	 DPMIMOUSEMAC	17h,RESTSTATE	; 17:  Restore Driver State
.lall


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:word
	 extrn	 DPMITYPEIG:byte

DLBL	 macro	 LBL
INT33_DPMIJMP_&LBL label word
	 endm			; DLBL


ACT	 macro	 LBL
	 public  INT33_DPMI_&LBL
	 dw	 IGROUP:INT33_DPMI_&LBL
	 endm			; ACT


DOSFN	 macro	 LBL,ARGS
	 dw	 IGROUP:DOSFN_&LBL
ifnb <ARGS>
	 dw	 ARGS
endif				; IFNB
	 endm			; DOSFN


DJMP	 macro	 LBL
	 dw	 IGROUP:DOSFN_JMP
	 dw	 IGROUP:INT33_DPMIJMP_&LBL
	 endm			; DJMP


	 public  JMPTAB33
JMPTAB33 label	 word
.sall
	 DLBL	 SETSHAPE	; 09:  Set Pointer Shape
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 SETSHAPE
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_ES,INTXX_EDX,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,33h
	 DOSFN	 RELBUF 	; No need to copy back the buffer
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 HOOKMEI	; 0C:  Hook Mouse Event Interrupt
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 HOOKMEI
	 DOSFN	 SIMVMI,33h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 SWAPINT	; 14:  Swap Mouse Interrupt Subroutines
	 DOSFN	 SAVE_VMCREGS
	 ACT	 SWAPINT
	 ACT	 HOOKMEI
	 DOSFN	 SIMVMI,33h
	 ACT	 SWAPINT_EXIT
     DLBL	 SWAPINT_TAIL
	 DOSFN	 SEG2SEL,<@CODESEL,VMC_ES,I31_ES-@I31BACK>
	 DOSFN	 IF32ZX,<VMC_EDX.EHI>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT

     DLBL	 SWAPINT_REST
	 DOSFN	 SIMVMI,33h
	 DJMP	 SWAPINT_TAIL


	 DLBL	 GETSSRSIZE	; 15:  Get State Save/Restore Buffer Size
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,33h
	 ACT	 GETSSRSIZE_EXIT
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 SAVESTATE	; 16:  Save Driver State
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 SAVESTATE
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_ES,INTXX_EDX,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,33h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_ES-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 RESTSTATE	; 17:  Restore Driver State
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 RESTSTATE
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_ES,INTXX_EDX,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,33h
	 DOSFN	 RELBUF 	; No need to copy back the buffer
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT

; We rely on 0ffh being unsupported...


	 DLBL	 RESTMEI	; Restore MEI upon termination
	 DOSFN	 SAVE_INTXXREG,<INTXX_EAX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ECX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 RESTMEI
	 DOSFN	 SIMVMI,33h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 DOSFN	 REST_INTXXREG,<INTXX_ECX>
	 DOSFN	 REST_INTXXREG,<INTXX_EAX>
	 ACT	 RESTMEI_EXIT


	 DLBL	 PASSTHRU	; Pass through label for all other functions
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,33h
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT
.lall

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 PMINTCOM:far
	 extrn	 DOSFN_SAVE_INTXXREG:near
	 extrn	 DOSFN_SAVE_VMCREGS:near
	 extrn	 DOSFN_GETBUF:near
	 extrn	 DOSFN_SIMVMI:near
	 extrn	 DOSFN_RELBUF:near
	 extrn	 DOSFN_LOW2EXT:near
	 extrn	 DOSFN_REST_VMCREGS:near
	 extrn	 DOSFN_REST_INTXXREG:near
	 extrn	 DOSFN_SEG2SEL:near
	 extrn	 DOSFN_IF32ZX:near
	 extrn	 DOSFN_JMP:near
	 extrn	 FLTPROC_LPMFULL:near
	 extrn	 PMMEI:abs
	 extrn	 DPMIFN_LMSW:near
	 extrn	 DPMIFN_NESTRET:near
	 extrn	 DPMIFN_LPMSTK:near

	 public  @QMAX_D33_ICODE
@QMAX_D33_ICODE:		; Mark module start in .MAP file

	 FPPROC  INT33_DPMI -- Mouse Calls from DPMI Clients
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mouse calls from DPMI clients

On entry:

AX	 =	 function #

|

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT33_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 assume  ss:PGROUP	; Tell the assembler about it
	 test	 DPMI_CPIHOOK[33h/8],1 shl (33h mod 8) ; Izit hooked by current client?
	 assume  ss:nothing	; Tell the assembler about it
	 jz	 short INT33_INTRETPM ; Jump if not

	 mov	 [esp].INTCOM_INTNO,4*33h + offset PGROUP:INTPROC00Z

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

; We're back to handle it ourselves

	 public  INT33_INTRETPM
INT33_INTRETPM:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; All EGP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
				; (nothing above INTXX_SS is valid)

	 REGSAVE <ds,es>	; Save segment registers

; Note that the above REGSAVE is mapped by I31_STR and must be
; consistent with it

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

; Set new LPM stack top for nested callers if it's active
; and we're called from PM, not PL0

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 call	 DPMIFN_LPMSTK	; Save new LPM stack as appropriate

; Enable interrupts if the caller has them enabled

	 push	 [ebp].INTXX_EFL.ELO ; Get caller's flags
	 and	 [esp].ELO,not ((mask $NT) or (mask $DF) or (mask $TF)) ; NT=TF=DF=0
	 popf			; Put caller's IF into effect

	 movzx	 eax,[ebp].INTXX_EAX.ELO ; Copy function code

; Check for invalid functions we should ignore

	 or	 ah,ah		; Izit an odd Int 33h call?
	 jz	 short @F	; Jump if not

	 mov	 ax,0ffh	; Use a known unsupported function
@@:

	 mov	 si,DPMIMOUSE_ACT[eax*(type DPMIMOUSE_ACT)] ; CS:SI ==> action stream

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 09:  Set Pointer Shape

; On entry (in PL3 stack):
; ES:eDX ==>	 64-byte buffer

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_SETSHAPE:
	 mov	 ax,64		; Get pointer shape buffer

	 push	 ax		; RELBUF:  # bytes to release in buffer
	 push	 ax		; GETBUF:  # leading bytes to copy
	 push	 ax		; GETBUF:  # bytes to allocate in buffer

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 0C:  Hook Mouse Event Interrupt

; On entry (in PL3 stack):
; ES:eDX ==>	 PM Mouse Event Interrupt handler

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_HOOKMEI:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 bx,[ebp-@I31BACK].I31_ES ; Get caller's selector
	 mov	 PGROUP:[eax].DPTSS_MEI_FVEC.FSEL,bx ; Set selector

	 mov	 ebx,[ebp].INTXX_EDX ; Get offset
	 mov	 PGROUP:[eax].DPTSS_MEI_FVEC.FOFF,ebx ; Set offset

	 mov	 bx,PGROUP:[eax].DPTSS_HPDASEG ; Get segment of HPDA
	 mov	 VMCREGS.VMC_ES,bx ; Pass to VM
	 mov	 VMCREGS.VMC_EDX.ELO,offset HPDA_MEI ; Save offset

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 14:  Swap Mouse Interrupt Subroutines

; On entry (in PL3 stack):
; ES:eDX ==>	 incoming subroutine
; CX	 =	 incoming call mask

; On exit (in PL3 stack):
; ES:eDX ==>	 previous subroutine
; CX	 =	 previous call mask

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_SWAPINT:

; If the incoming address matches the original address, and the
; call masks match, we assume that the client is restoring it

	 push	 [ebp-@I31BACK].I31_ES ; Pass selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 test	 al,@NIB0	; Izit on a para boundary?
	 jnz	 short INT33_DPMI_SWAPINT1 ; Jump if not

	 cmp	 eax,CON1MB	; Izit within the first megabyte?
	 jae	 short INT33_DPMI_SWAPINT1 ; Jump if not

	 mov	 ebx,[ebp].INTXX_EDX ; Get offset
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client

	 cmp	 ebx,CON64KB	; Izit too large?
	 jae	 short INT33_DPMI_SWAPINT1 ; Jump if so

	 shr	 eax,4-0	; Convert from bytes to paras
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,bx		; Copy offset

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_MEI_ORIG_VEC ; Izit the same?
	 jne	 short INT33_DPMI_SWAPINT1 ; Jump if not

	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get the call mask

	 cmp	 ax,PGROUP:[edx].DPTSS_MEI_ORIG_MASK ; Izit the same?
	 jne	 short INT33_DPMI_SWAPINT1 ; Jump if not

	 shr	 eax,16 	; Shift segment to low-order word
	 mov	 VMCREGS.VMC_ES,ax ; Pass to VM

; As we're restoring the original value, zero the entries
; in DPTSS_STR so we save any new value there the next time.

	 mov	 PGROUP:[edx].DPTSS_MEI_ORIG_VEC,0 ; Zero for next time
	 mov	 PGROUP:[edx].DPTSS_MEI_ORIG_MASK,0 ; ...

	 lea	 si,INT33_DPMIJMP_SWAPINT_REST ; CS:SI ==> action stream
INT33_DPMI_SWAPINT1:
	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT33_DPMI_SWAPINT_EXIT:

; If we've not saved these values in DPTSS_STR, do so now
; so we can restore them when we exit

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 PGROUP:[eax].DPTSS_MEI_ORIG_VEC,0 ; Izit already saved?
	 jne	 short @F	; Jump if so

	 mov	 bx,VMCREGS.VMC_ES ; Get original segment
	 shl	 ebx,16 	; Shift segment to high-order word
	 mov	 bx,VMCREGS.VMC_EDX.ELO ; Get original offset
	 mov	 PGROUP:[eax].DPTSS_MEI_ORIG_VEC,ebx ; Save to restore later

	 mov	 bx,VMCREGS.VMC_ECX.ELO ; Get original mask
	 mov	 PGROUP:[eax].DPTSS_MEI_ORIG_MASK,bx ; Save to restore later
@@:
	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 15:  Get State Save/Restore Buffer Size

; On entry (in PL3 stack):
; BX	 =	 State Save/Restore Buffer Size (in bytes)

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_GETSSRSIZE_EXIT:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 bx		; Save for a moment

	 mov	 bx,VMCREGS.VMC_EBX.ELO ; Get State Save/Restore Buffer Size
	 mov	 PGROUP:[eax].DPTSS_MOUSE_SSRSIZE,bx ; Save size

	 pop	 bx		; Restore

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 16:  Save Driver State

; On entry (in PL3 stack):
; ES:eDX ==>	 Buffer into which state is to be saved

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_SAVESTATE:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 ax,PGROUP:[eax].DPTSS_MOUSE_SSRSIZE ; Get size of buffer

	 push	 ax		; LOW2EXT:  # bytes to release (entire buffer)
	 push	 ax		; LOW2EXT:  # trailing bytes to copy (entire buffer)
	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate in buffer

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 17:  Restore Driver State

; On entry (in PL3 stack):
; ES:eDX ==>	 Buffer from which state is to be restored

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT33_DPMI_RESTSTATE:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 ax,PGROUP:[eax].DPTSS_MOUSE_SSRSIZE ; Get size of buffer

	 push	 ax		; RELBUF:  # bytes to release in buffer
	 push	 ax		; GETBUF:  # leading bytes to copy
	 push	 ax		; GETBUF:  # bytes to allocate in buffer

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

	 assume  ss:PGROUP	; Tell the assembler about it
INT33_DPMI_EXIT:
	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT33_DPMI endp 		; End INT33_DPMI procedure
	 NPPROC  DPMI_PDBI -- PDBI Mouse Event Interrupt Handler
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

PDBI Mouse event interrupt handler

On entry (in registers):

SS:EBP	 ==>	 INTXX_STR

|

	 mov	 ecx,4		; Set # words to copy from the VM
				; stack to DPMI client's PL3 stack
	 jmp	 short DPMI_MEI_NXT ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PDBI endp			; End DPMI_PDBI procedure
	 NPPROC  DPMI_MEI -- Mouse Event Interrupt Handler
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Mouse event interrupt handler

On entry (in registers):

SS:EBP	 ==>	 INTXX_STR

|

	 xor	 ecx,ecx	; Set # words to copy from the VM
				; stack to DPMI client's PL3 stack
DPMI_MEI_NXT:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 OLD_PCURTSS	; Save previous value in case we need
				; ...to restore it upon exit
	 push	 PGROUP:[eax].TSS_SS0  ; Save old stack selector
	 push	 PGROUP:[eax].TSS_ESP0 ; Save old pointer to stack top

	 push	 LAST_INTCOM	; Save old LAST_INTCOM
	 push	 LAST_INTFLG	; ...and its flag
	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack offset
	 push	 LPMSTK_FVEC.FOFF ; ...

; * Save SS:ESP as new top of stack pointer

	 mov	 PGROUP:[eax].TSS_SS0,ss ; Save for next time
	 mov	 PGROUP:[eax].TSS_ESP0,esp ; ...

; * Recalculate PL0STK pointers

	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

; Save new value for LAST_INTCOM

	 lea	 eax,[ebp].INTXX_EIP ; Get stack offset of new LAST_INTCOM
	 xchg	 eax,LAST_INTCOM ; Swap with the last one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,ax ; Save to restore later

; Set new LPM stack top for nested callers if it's active
; and we're called from PM, not PL0

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 call	 DPMIFN_LPMSTK	; Save new LPM stack as appropriate

	 lfs	 esi,LPMSTK_FVEC ; FS:ESI ==> special stack used by faults
	 assume  fs:nothing	; Tell the assembler about it

	 inc	 LPMSTK_CNT	; Count in another one

; Copy parameters from the VM stack to the DPMI client's PL3 stack
; if we entered from DPMI_PDBI

	 jecxz	 DPMI_MEI_XPARM ; Jump if no parameters to copy

	 movzx	 eax,[ebp].INTXX_SS ; Get VM stack segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 edx,[ebp].INTXX_ESP.ELO ; Get VM stack pointer
	 add	 eax,edx	; Plus VM stack pointer

COMMENT|

The VM stack at this point (AGROUP:EAX) contains from the bottom up

CS:IP	 16-bit far return to caller
Parms	 four word parameters

|

;;;;;;;; add	 eax,4-2	; Skip over far return, back off to last word --
				; Instead this addition is done in the EA calc
@@:
	 mov	 dx,AGROUP:[eax+ecx*2+2] ; Get the next word
	 sub	 esi,2		; Make room for it
	 mov	 fs:[esi],dx	; Save on PL3 stack

	 loop	 @B		; Jump if more parameters to copy
DPMI_MEI_XPARM:

; Pass our return address onto the LPM stack
; for the callback procedure to RETF/D

DPMI_MEI16_STR struc

DPMI_MEI16_RIP dw ?		; Our return IP
DPMI_MEI16_RCS dw ?		; ...	     CS

DPMI_MEI16_STR ends


DPMI_MEI32_STR struc

DPMI_MEI32_REIP dd ?		; Our return EIP
DPMI_MEI32_RCS dw ?,?		; ...	     CS w/filler

DPMI_MEI32_STR ends

	 mov	 ax,DPMI_IDEF	; Get our interrupt selector

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short DPMI_MEI16 ; Jump if so

	 sub	 esi,size DPMI_MEI32_STR ; Make room on LPM stack
	 jc	 near ptr DPMI_MEI_LPMFULL ; Jump if we overflowed

	 mov	 fs:[esi].DPMI_MEI32_REIP,PMMEI ; Return EIP
	 mov	 fs:[esi].DPMI_MEI32_RCS,ax	; ... CS

	 jmp	 short DPMI_MEI_COM ; Join common code

DPMI_MEI16:
	 sub	 esi,size DPMI_MEI16_STR ; Make room on LPM stack
	 jc	 near ptr DPMI_MEI_LPMFULL ; Jump if we overflowed

	 mov	 fs:[esi].DPMI_MEI16_RIP,PMMEI ; Return IP
	 mov	 fs:[esi].DPMI_MEI16_RCS,ax    ; ... CS
DPMI_MEI_COM:

; Put the address (SSF, ESP, EFL, EIP, CSF) to which we're
; transferring on our PL0 stack

	 PUSHD	 fs		; Pass SS w/filler
	 push	 esi		; Pass ESP
	 push	 [ebp].INTXX_EFL ; Pass EFL
	 and	 [esp].EDD,not ((mask $VMHI) or (mask $RFHI) \
			     or (mask $IOPL) or (mask $TF)) ; VM=RF=IOPL=TF=0
	 or	 [esp].EDD,@DPMIOPL shl $IOPL ; IOPL=@DPMIOPL

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 PGROUP:[ebx].DPTSS_MEI_FVEC.FSEL.EDD ; Pass selector w/filler
	 push	 PGROUP:[ebx].DPTSS_MEI_FVEC.FOFF     ; Pass offset

	 mov	 eax,[ebp].INTXX_EAX ; Restore caller's EAX
	 mov	 ebx,[ebp].INTXX_EBX ; ...		EBX
	 mov	 ecx,[ebp].INTXX_ECX ; ...		ECX
	 mov	 edx,[ebp].INTXX_EDX ; ...		EDX
	 mov	 esi,[ebp].INTXX_ESI ; ...		ESI
	 mov	 edi,[ebp].INTXX_EDI ; ...		EDI
	 mov	 ebp,[ebp].INTXX_EBP ; ...		EBP

if @OEM_VIRTUALMEM

; If this is a program which doesn't lock its Mouse handler pages,
; we're inside DOS, and swapping is active, ignore this call.

	 test	 I31_FLAG,mask $I31_XMEI ; Izit one to worry about?
	 jz	 short DPMI_MEI_XDOS ; Jump if not

	 test	 VMM_FLAG,@VMM_BSPRES ; Is swapping active?
	 jz	 short DPMI_MEI_XDOS ; Jump if not

	 cmp	 PageFaultActive,0 ; Are we processing a page fault?
	 jne	 near ptr DPMI_MEIRET ; Jump if so

	 push	 eax		; Save for a moment

	 mov	 eax,LaINDOS	; AGROUP:EAX ==> InDOS flag

	 cmp	 AGROUP:[eax].LO,0 ; Are we inside DOS?
	 pop	 eax		; Restore
	 jne	 near ptr DPMI_MEIRET ; Jump if so
DPMI_MEI_XDOS:
endif				; IF @OEM_VIRTUALMEM
	 REGSAVE <LAST_DPMI_DS,LAST_DPMI_ES, \
		  LAST_DPMI_FS,LAST_DPMI_GS> ; Get previous values
	 VERREST <gs,fs,es,ds>	; Restore selectors with VERR
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 iretd			; Continue with the callback procedure

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing


	 public  DPMI_MEI_LPMFULL
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
DPMI_MEI_LPMFULL:

; We overflowed the LPM stack:	strip back to the original INTDPI_STR
; and exit to common error code

	 pop	 LPMSTK_FVEC.FOFF ; De-allocate it
	 pop	 LPMSTK_FVEC.FSEL ; ...
	 dec	 LPMSTK_CNT	; Count it out

	 pop	 LAST_INTFLG	; Restore
	 pop	 LAST_INTCOM	; Restore

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 pop	 PGROUP:[eax].TSS_ESP0 ; Restore
	 pop	 PGROUP:[eax].TSS_SS0  ; ...

; Restore PCURTSS

	 pop	 PCURTSS	; Restore

; * Recalculate PL0STK pointers

	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

	 popad			; Restore all EGP registers

; The MAX stack contains INTDPF_STR

	 jmp	 FLTPROC_LPMFULL ; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MEI endp			; End DPMI_MEI procedure
	 NPPROC  DPMI_MEIRET -- Return From Mouse Event Interrupt Procedure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return from mouse event interrupt procedure

On entry:

IF	 =	 0
SS:EBP	 ==>	 INTDPI_STR (discarded) followed by MEI_STR

|

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 PVMTSS 	; Pass offset in PGROUP of the 1st TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

; Restore MEI_STR

	 add	 esp,size INTDPI_STR ; Discard the client's return frame

	 pop	 LPMSTK_FVEC.FOFF ; De-allocate it
	 pop	 LPMSTK_FVEC.FSEL ; ...
	 dec	 LPMSTK_CNT	; Count it out

	 pop	 LAST_INTFLG	; Restore
	 pop	 LAST_INTCOM	; Restore

	 mov	 SAVE_EAX,eax	; Save for a moment
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 pop	 PGROUP:[eax].TSS_ESP0 ; Restore
	 pop	 PGROUP:[eax].TSS_SS0  ; ...

; Restore PCURTSS

	 pop	 PCURTSS	; Restore

; Check for return from nesting

	 call	 DPMIFN_NESTRET ; Check for nesting return with EAX=old PCURTSS
	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it

; * Recalculate PL0STK pointers

	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

; Note that we may have switched to a new LDT
; so some selectors may have been set to zero

	 mov	 eax,SAVE_EAX	; Restore offset ...

; The stack is mapped by the original INTXX_STR which we use for the IRETD to VM

	 mov	 [esp].INTXX_EAX,eax ; Return caller's EAX
	 mov	 [esp].INTXX_EBX,ebx ; ...	       EBX
	 mov	 [esp].INTXX_ECX,ecx ; ...	       ECX
	 mov	 [esp].INTXX_EDX,edx ; ...	       EDX
	 mov	 [esp].INTXX_ESI,esi ; ...	       ESI
	 mov	 [esp].INTXX_EDI,edi ; ...	       EDI
	 mov	 [esp].INTXX_EBP,ebp ; ...	       EBP

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 iretd			; Return to VM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MEIRET endp		; End DPMI_MEIRET procedure
	 NPPROC  DPMIFN_RESTMEI -- Restore Mouse Event Interrupt
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore mouse event interrupt

|

	 pushad 		; Save all EGP registers

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 PGROUP:[edx].DPTSS_MEI_ORIG_VEC,0 ; Izit valid?
	 je	 short INT33_DPMI_RESTMEI_EXIT ; Jump if not

	 lea	 si,INT33_DPMIJMP_RESTMEI ; CS:SI ==> action stream
	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT33_DPMI_RESTMEI:
	 mov	 VMCREGS.VMC_EAX.ELO,000Ch ; Mark as Hook Mouse Event Interrupt

	 mov	 ax,PGROUP:[edx].DPTSS_MEI_ORIG_MASK ; Get original mask value
	 mov	 VMCREGS.VMC_ECX.ELO,ax ; Pass as call mask in CX

	 mov	 eax,PGROUP:[edx].DPTSS_MEI_ORIG_VEC ; Get original address
	 mov	 VMCREGS.VMC_EDX.ELO,ax ; Pass as offset in DX
	 shr	 eax,16 	; Shift down segment high order word
	 mov	 VMCREGS.VMC_ES,ax ; Pass as segment in ES

	 lods	 JMPTAB33[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT33_DPMI_RESTMEI_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_RESTMEI endp		; End DPMIFN_RESTMEI procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_D33 module
