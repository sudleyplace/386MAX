;' $Header:   P:/PVCS/MAX/386MAX/QMAX_D15.ASV   1.2   30 May 1997 10:44:12   BOB  $
	 title	 QMAX_D15 -- 386MAX DPMI INT 15h Translation Services
	 page	 58,122
	 name	 QMAX_D15

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Data    segment ACTSEG,word-aligned,  public, class 'idata'

Program derived from:  None.

Original code by:  Bob Smith, August, 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DPMI.INC
	 include CPUFLAGS.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAXDPMI.INC
.list

if @OEM_DPMI

PGROUP	 group	 ECODE,EDATA
IGROUP	 group	 LDATA,ICODE,IDATA,ACTSEG


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 INTPROC00Z:near

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 LPMSTK_FVEC:fword
	 extrn	 PCURTSS:dword
	 extrn	 VMCREGS:tbyte

EDATA	 ends			; End EDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


; Define BIOS INT 15h functions which we handle

DPMIBIOSMAC macro VAL,ACT

ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 org	 DPMIBIOS_ACT + VAL * (type DPMIBIOS_ACT) ; Set to appropriate origin
	 dw	 IGROUP:INT15_DPMIJMP_&ACT
	 org	 DPMIBIOS_ACTZ	; Restore to end of the table

ACTSEG	 ends			; End ACTSEG segment

	 endm			; DPMIBIOSMAC


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 public  DPMIBIOS_ACT
DPMIBIOS_ACT dw  256 dup (IGROUP:INT15_DPMIJMP_PASSTHRU) ; Seed with pass through action
DPMIBIOS_ACTZ label word

ACTSEG	 ends			; End ACTSEG segment


; The following BIOS functions require special treatment

.sall
	 DPMIBIOSMAC  87h,MOVEBLOCK	; 87:  Move block using GDT at ES:eSI
	 DPMIBIOSMAC 0C0h,BIOSCONF	; C0:  Get BIOS configuration data into ES:eBX
	 DPMIBIOSMAC 0C1h,XBDASEG	; C1:  Get extended BIOS data segment into ES
	 DPMIBIOSMAC 0C2h,PDBI		; C2:  Pointing Device BIOS Interface
.lall


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

DLBL	 macro	 LBL
INT15_DPMIJMP_&LBL label word
	 endm			; DLBL


ACT	 macro	 LBL
	 dw	 IGROUP:INT15_DPMI_&LBL
	 endm			; ACT


DOSFN	 macro	 LBL,ARGS
	 dw	 IGROUP:DOSFN_&LBL
ifnb <ARGS>
	 dw	 ARGS
endif				; IFNB
	 endm			; DOSFN


	 public  JMPTAB15
JMPTAB15 label	 word
.sall
	 DLBL	 MOVEBLOCK	; 87:  Move block using GDT at ES:eSI
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 MOVEBLOCK
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_ES,INTXX_ESI,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,15h
	 DOSFN	 RELBUF 	; No need to copy back the GDT
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 ACT	 EXIT


	 DLBL	 BIOSCONF	; C0:  Get BIOS configuration data into ES:eBX
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,15h
	 DOSFN	 SEG2SEL,<@DATASEL,VMC_ES,I31_ES-@I31BACK>
	 DOSFN	 IF32ZX,<VMC_EBX.EHI>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 XBDASEG	; C1:  Get extended BIOS data segment into ES
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,15h
	 DOSFN	 SEG2SEL,<@DATASEL,VMC_ES,I31_ES-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 PDBI		; C2:  Pointing Device BIOS Interface
	 ACT	 PDBI
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,15h
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT

     DLBL	 PDBIHOOK
	 DOSFN	 SAVE_INTXXREG,<INTXX_EBX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 PDBIHOOK
	 DOSFN	 SIMVMI,15h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EBX>
	 ACT	 EXIT


	 DLBL	 PASSTHRU	; Pass through label for all other functions
	 DOSFN	 SAVE_VMCREGS
	 DLBL	 SIMVMI
	 DOSFN	 SIMVMI,15h
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
	 extrn	 DOSFN_REST_VMCREGS:near
	 extrn	 DOSFN_REST_INTXXREG:near
	 extrn	 DOSFN_SEG2SEL:near
	 extrn	 DOSFN_IF32ZX:near
	 extrn	 DPMIFN_LPMSTK:near

	 public  @QMAX_D15_ICODE
@QMAX_D15_ICODE:		; Mark module start in .MAP file

	 FPPROC  INT15_DPMI -- BIOS Calls from DPMI Clients
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIOS calls from DPMI clients

On entry:

AH	 =	 function #

|

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT15_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 assume  ss:PGROUP	; Tell the assembler about it
	 test	 DPMI_CPIHOOK[15h/8],1 shl (15h mod 8) ; Izit hooked by current client?
	 assume  ss:nothing	; Tell the assembler about it
	 jz	 short INT15_INTRETPM ; Jump if not

	 mov	 [esp].INTCOM_INTNO,4*15h + offset PGROUP:INTPROC00Z

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

; We're back to handle it ourselves

	 public  INT15_INTRETPM
INT15_INTRETPM:
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

	 movzx	 eax,[ebp].INTXX_EAX.ELO.HI ; Copy function code
	 mov	 si,DPMIBIOS_ACT[eax*(type DPMIBIOS_ACT)] ; CS:SI ==> action stream

	 lods	 JMPTAB15[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; 87:  Move block using GDT at ES:SI

; On entry (in PL3 stack):
; ES:SI  ==>	 string to display

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT15_DPMI_MOVEBLOCK:
	 mov	 ax,size MDTE_STR ; Get size of move GDT

	 push	 ax		; RELBUF:  # bytes to release in buffer
	 push	 ax		; GETBUF:  # leading bytes to copy
	 push	 ax		; GETBUF:  # bytes to allocate in buffer

	 lods	 JMPTAB15[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; C2:  Pointing Device BIOS Interface

; On entry (in PL3 stack):
; AL	 =	 subfunction

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT15_DPMI_PDBI:
	 cmp	 [ebp].INTXX_EAX.ELO.LO,07h ; Izit hook call?
	 jne	 short @F	; Jump if not (continue on)

	 lea	 si,INT15_DPMIJMP_PDBIHOOK ; CS:SI ==> action stream
@@:
	 lods	 JMPTAB15[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

; C207:  Pointing Device BIOS Interface Hook

; On entry (in PL3 stack):
; ES:eBX ==>	 PM Mouse Event Interrupt handler

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT15_DPMI_PDBIHOOK:
	 mov	 eax,PCURTSS	; Get offset in DGROUP of current TSS

	 mov	 bx,[ebp-@I31BACK].I31_ES ; Get caller's selector
	 mov	 PGROUP:[eax].DPTSS_MEI_FVEC.FSEL,bx ; Set selector

	 mov	 ebx,[ebp].INTXX_EBX ; Get offset
	 mov	 PGROUP:[eax].DPTSS_MEI_FVEC.FOFF,ebx ; Set offset

	 mov	 bx,PGROUP:[eax].DPTSS_HPDASEG ; Get segment of HPDA
	 mov	 VMCREGS.VMC_ES,bx ; Pass to VM
	 mov	 VMCREGS.VMC_EBX.ELO,offset HPDA_PDBI ; Save offset

	 lods	 JMPTAB15[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

	 assume  ss:PGROUP	; Tell the assembler about it
INT15_DPMI_EXIT:
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

INT15_DPMI endp 		; End INT15_DPMI procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_D15 module
