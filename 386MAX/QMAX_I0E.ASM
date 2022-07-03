;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I0E.ASV   1.2   30 May 1997 10:44:38   BOB  $
	 title	 QMAX_I0E -- 386MAX INT 0Eh Handler
	 page	 58,122
	 name	 QMAX_I0E

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

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include 386.INC
	 include PTR.INC
	 include 8259.INC
	 include ALLMEM.INC
	 include IOPBITS.INC
	 include OPCODES.INC
	 include MASM5.MAC

	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_OEM.INC

	 include PDTGRP.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
FGROUP	 group	 FDATA
IGROUP	 group	 ICODE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 SEND_CHIPSET:near

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 LCL_CR3:dword

;;;;;;;; extrn	 SYSROM_START:word
;;;;;;;;
	 extrn	 CT_RAM_AB:byte
	 extrn	 CT_RAM_CD:byte
	 extrn	 CT_RAM_EF:byte

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_DPMI
	 extrn	 PPL0STK_DNRM:dword
	 extrn	 PPL0STK_DERR:dword
	 extrn	 DPMITYPE:byte
	 extrn	 DPMI_CPFHOOK:byte
	 extrn	 PCURTSS:dword
	 extrn	 PMVPF:abs
	 extrn	 DPMI_IDEF:word
	 extrn	 SEL_DS3:word
	 extrn	 SEL_4GB3:word
endif				; IF @OEM_DPMI

	 extrn	 OFFCR3:dword
	 extrn	 PPL0STK_NRM:dword
	 extrn	 PPL0STK_ERR:dword

if @OEM_EMS
	 extrn	 EMS_START:dword,EMS_END:dword
	 extrn	 NPHYS16F:byte
endif				; IF @OEM_EMS

	 extrn	 LaVROM_BEG:dword
	 extrn	 LaVROM_END:dword
	 extrn	 PTE_VROM_BEG:word
	 extrn	 PTE_VROM_END:word
	 extrn	 PTE_VROM_SRC:word

if @OEM_VIRTUALMEM
	 extrn	 LPMSTK_FVEC:fword
	 extrn	 LPMSTK_CNT:dword
	 extrn	 VMM_FLAG:word
	 include QMAX_VMM.INC
endif
	 extrn	 CON1MB:dword

	 public  OLDCR2,CR2DATA,CR2OFF,CR2FLAG,CR2INT01_IVEC
OLDCR2	 dd	 ?		; Previous CR2
CR2DATA  dd	 4 dup (?)	; two dwords on eight side of page fault
CR2OFF	 dw	 ?		; Offset into PDE of the PTE
CR2FLAG  dw	 ?		; Caller's flags
CR2INT01_IVEC IDT_STR <>	; Save area for previous INT 01h IDT entry

	 public  CR2_PTE
CR2_PTE  dd	 ?		; PTE associated with a CR2

if @OEM_DPMI
	 public  DPMICNT0E
DPMICNT0E dw	 0		; Count of active INT 0Eh DPMI calls
endif				; IF @OEM_DPMI

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_PNP:byte
	 extrn	 MSG_SUP:byte
	 extrn	 MSG_ROM:byte

if @OEM_DEBUG
	 public  INT0EMSG
INT0EMSG db	 'Page fault',0
endif				; IF @OEM_DEBUG

FDATA	 ends			; End FDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 VMM_PageFaultHandler:far
	 extrn	 FDPMIFN_LPMSTK:far
	 extrn	 FLTPROC_APPL:far
endif				; IF @OEM_VIRTUALMEM

ICODE	ends			; End ICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I0E_ECODE
@QMAX_I0E_ECODE:		; Mark module start in .MAP file

	 extrn	 INTPROC0E:near
	 extrn	 INTXXCOM:near
	 extrn	 FLUSH_TLB:near
	 extrn	 HARDINT:near
	 extrn	 INT0D_IRETD1:near
	 extrn	 IRETD_COM:near
	 extrn	 INTPROC00Z:near
if @OEM_DPMI
	 extrn	 INTCOM_DPMI_INT:near
	 extrn	 INTCOM_DPMI_FAULT:near
	 extrn	 SET_PPL0STK:near
endif				; IF @OEM_DPMI
	 extrn	 DSTK_CHK:near

	 FPPROC  INT0E -- Page Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Page fault interrupt (0Eh) with error code on stack.

Distinguish amongst four cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0E
Page Fault	 VM86	  ESP=PPL0STK_ERR	Attempt to fix it
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto INTCOM_DPMI_INT
Page Fault	 DPMI	  ESP=PPL0STK_DERR	Attempt to fix it
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Page Fault	 PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT0E_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 near ptr INT0E_VM86 ; Yes

if @OEM_DPMI
	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT0E_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 near ptr INT0E_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 near ptr INT0E_UGH ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0E_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*0Eh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Eh

	 jmp	 HARDINT	; It's a hardware interrupt


INT0E_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*0Eh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Eh

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC0E	; Use normal interrupt processor


if @OEM_DPMI

; Hardware/software interrupt from a DPMI client

INT0E_DPMI_INT:
	 mov	 [esp].NRM_INTNO,4*0Eh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Eh

	 jmp	 INTCOM_DPMI_INT ; Join common DPMI interrupt code


; Fault from a DPMI client -- see if we can emulate it
; The stack is mapped by INTDPF_STR -- move it down to look like
; INTXX_STR.

INT0E_DPMI_FAULT:

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

;;;;;;;; mov	 [ebp].INTXX_ES,es ; Save for later use
;;;;;;;; mov	 [ebp].INTXX_DS,ds ; ...
;;;;;;;; mov	 [ebp].INTXX_FS,fs ; ...
;;;;;;;; mov	 [ebp].INTXX_GS,gs ; ...

	 inc	 DPMICNT0E	; Count in another one

	 jmp	 short INT0E_VM86A ; Join common code

	 assume  ds:nothing	; Tell the assembler about it

endif				; IF @OEM_DPMI
INT0E_VM86:
INT0E_UGH:
	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; Address the stack
INT0E_VM86A:
if @OEM_VIRTUALMEM
	 mov	 [ebp].INTXX_INTNO,4*0Eh + offset PGROUP:INTPROC00Z ; Mark as INT 0Eh

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jnz	 short INT0E_XVMM ; Jump if so

	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 short INT0E_XVMM ; Jump if not

	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX == > INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 FIXICALL IGROUP:FDPMIFN_LPMSTK,DTE_CSIG ; Save new LPM stack as appropriate

	 mov	 eax,cr2	; Get Page Fault linear address
	 push	 eax		; Pass the linear address
	 FIXICALL IGROUP:VMM_PageFaultHandler,DTE_CSIG
	 pop	 LPMSTK_FVEC.FOFF ; De-allocate it
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 or	 eax,eax	; Returns zero on successfully handled
				; transparent fault
	 jz	 near ptr INT0E_IRETD1 ; Join common code

	 and	 [ebp].INTXX_EFL.ELO,not (mask $NT) ; Clear NT flag

	 cmp	 eax,1		; If this is definitely something the user
				; wants to handle, EAX is returned 1
	 jne	 short INT0E_XVMM ; Jump if not

	 popad			; Restore all EGP registers

	 jmp	 INT0E_DPMI_VISIBLE ; Join common code

INT0E_XVMM:
endif

; Turn off nested task flag in PL0 stack

	 and	 [ebp].INTXX_EFL.ELO,not (mask $NT)

; See if this is from a Page Not Present or an access violation

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

; Here we write the address of the page directory to the last
; entry in the page directory, thereby providing addressability
; to all page tables (as well as the page directory itself) at a
; known linear address.

	 mov	 ecx,LCL_CR3	; Pick up saved CR3 value
	 and	 ecx,@PTE_FRM	; Throw away any low bits
	 or	 ecx,@PTE_URP	; Make PTE
	 mov	 ebx,OFFCR3	; Get offset in PGROUP of PDT
	 xchg	 ecx,PGROUP:[ebx+@PageSize-4].PDT_PTE ; Read default PDE, set new PDE

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 mov	 eax,cr2	; Get Page Fault Linear address
	 mov	 esi,eax	; Save for later use
	 shr	 esi,12-0	; Convert from bytes to 4KB
	 shl	 esi,2		; Times four to index table of dwords
	 mov	 CR2OFF,si	; Save the offset into the PDT

; Note that when we need this offset, we're assuming that it
; points into the first PDE (we use it in this context only when
; it comes from VM).  Also, some code below assumes that SI
; contains CR2OFF.

; If a DPMI client makes a mistake and references a memory location
; for which there is no PDE, we must be careful not to read the PTE
; as that'll generate a spurious Page Fault (obscuring the one we're
; trying to handle now).  Instead, because we use the PTE only if it's
; in the first megabyte, we can safely skip any Page Faults above that
; address.

	 mov	 edx,eax	; Copy CR2 address
	 xor	 eax,eax	; Clear bits in PTE if >= 1MB

	 cmp	 edx,CON1MB	; Izit above the fist megabyte?
	 jae	 short @F	; Jump if so

	 MakePTEaddress edx	; EDX <- address of PTE for cur LA
	 mov	 eax,AGROUP:[edx].PDT_PTE ; EAX <- PTE
@@:
	 mov	 CR2_PTE,eax	; Save for debugging

	 mov	 PGROUP:[ebx+@PageSize-4].PDT_PTE,ecx ; Restore old PDE

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

; We now have the PTE in question in EAX (and saved in CR2_PTE).
; If the page is not present or supervisor-only, UGH.
; If the page is in the EMS frame, UGH.
; Otherwise, swap the PTEs back to their original ROM values
; Note we allow the caller to be in protected mode to handle
; DMA into ROM.

	 test	 GLB_FLAG,@GLB_DMA ; DMA transfer in progress?
	 jnz	 short INT0E_DMA_PNP ; Yes, skip not present check

	 test	 ax,mask $PTE_P ; Izit present?
	 jz	 near ptr INT0E_UGHPNP ; No, so that's an error
INT0E_DMA_PNP:
	 test	 ax,mask $PTE_US ; Izit user-accessible?
	 jz	 near ptr INT0E_UGHSUP ; No, so that's an error

if @OEM_EMS
	 cmp	 NPHYS16F,0	; Any EMS frame?
	 je	 short INT0E_NOEMS ; Not this time

; Check for EMMBUG writing into an uninitialized EMS page

	 mov	 ebx,cr2	; Get Page Fault Linear address

	 cmp	 ebx,EMS_START	; Check against lower limit
	 jb	 short INT0E_NOEMS ; It's too small

	 cmp	 ebx,EMS_END	; Check against upper limit
	 jb	 near ptr INT0E_UGHROM ; It's within range
INT0E_NOEMS:
endif				; IF @OEM_EMS

; No errors from here on, so we can afford to set segment registers

if @OEM_DPMI
	 REGSAVE <ds,fs>	; Save segment registers
endif				; IF @OEM_DPMI

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

COMMENT|

;;;If we've BCFed or compressed the system ROM, and this entry is in
;;;that region, we must take unusual action.
If the caller is not in video ROM and writing into itself, we must take
unusual action.  In particular, we allow the write to occur by executing
the instruction under our own single-step handler, and restore any damage
it might have done afterwards.

The technique used here is as follows:

* Set the read/write bit in the PTE so as to allow the write to occur
* Save the data in RAM which is to be modified
* Save the state of the caller's trap flag
* Set the trap flag in the caller's flags
* Save the address of the current single-step handler from the PM IDT
* Install our own local single-step handler in the PM IDT
* Restart the instruction

In our local single-step handler

* Restore the address of the previous single-step handler
* Restore the modified data
* Clear the read/write bit in the PTE for the next time
* Restore the state of the caller's trap flag
* Continue execution

We don't do this for all writes into ROM because paged-mode ROMs use a
write into ROM to bring in another page.  For writes into video ROMs by
the ROM itself, the old technique is still used.

|

; If asked to, signal NMI when we return to catch the beast

	 test	 DBG_FLAG,@DBG_ROM ; Signal NMI on return?
	 jz	 short @F	; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Mark it as NMI time when we return

	 jmp	 INT0E_IRETD	; Join common exit code

@@:

; Ignore check if user says so

	 test	 DB2_FLAG,@DB2_ROMSW ; Force ROM swap?
	 jnz	 near ptr INT0E_BLOCK ; Jump if so

; Ignore CS check if it's an MCA machine

	 test	 LCL_FLAG,@LCL_MCA ; Izit MCA-compatible?
	 jnz	 short INT0E_CHK ; Jump if so

; Check to see if the fault is into video ROM -- use single-step
; technique if so

	 mov	 eax,cr2	; Get Page Fault Linear address

	 cmp	 eax,LaVROM_BEG ; Is the fault below video ROM?
	 jb	 short INT0E_CHK ; Jump if so

	 cmp	 eax,LaVROM_END ; Is the fault above video ROM?
	 jae	 short INT0E_CHK ; Jump if so

; Check to see if the caller's CS is in video ROM -- avoid single-step
; technique if so

	 movzx	 eax,[ebp].INTXX_CS ; Get caller's CS
	 shl	 eax,4-0	; Convert from paras to bytes

	 cmp	 eax,LaVROM_BEG  ; Izit smaller than video ROM start?
	 jb	 short INT0E_CHK ; Jump if so

	 cmp	 eax,LaVROM_END  ; Izit larger than video ROM end?
	 jb	 near ptr INT0E_BLOCK ; Jump if it's within video ROM range
INT0E_CHK:
;;;;;;;; test	 LCL_FLAG,@LCL_CROM or @LCL_BCF ; Did we compress the system ROM?
;;;;;;;; jz	 near ptr INT0E_BLOCK ; Jump if not
;;;;;;;;
;;;;;;;; movzx	 eax,SYSROM_START ; Get starting segment of system ROM
;;;;;;;; shl	 eax,4-0	; Convert from paras to bytes
;;;;;;;;
;;;;;;;; cmp	 ebx,eax	; Izit in system ROM?
;;;;;;;; jb	 near ptr INT0E_BLOCK ; Jump if not

; * Set the read/write bit in the PTE so as to allow the write to occur

	 or	 OFFPDT[si],mask $PTE_RW ; Set it

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

; * Save the data in RAM which is to be modified

; Note that we save eight bytes before and after the address in question
; because of 386 Errata # 5 which can allow two iterations of the
; instruction REP MOVS to occur before the single-step interrupt is
; signalled.  Because this instruction can be a dword move and we don't
; bother to detect the direction flag, we save the two dwords on either
; side of the page fault address.

if @OEM_DPMI
	 push	 gs		; Save for a moment
endif				; IF @OEM_DPMI

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 ebx,cr2	; Get Page Fault Linear address
	 mov	 OLDCR2,ebx	; Save for later use
	 mov	 eax,AGROUP:[ebx-08h] ; Get the 2nd preceding dword
	 mov	 CR2DATA[00h],eax ; Save to restore later

	 mov	 eax,AGROUP:[ebx-04h] ; Get the 1st preceding dword
	 mov	 CR2DATA[04h],eax ; Save to restore later

	 mov	 eax,AGROUP:[ebx+00h] ; Get the 1st following dword
	 mov	 CR2DATA[08h],eax ; Save to restore later

	 mov	 eax,AGROUP:[ebx+04h] ; Get the 2nd following dword
	 mov	 CR2DATA[0Ch],eax ; Save to restore later

; * Save the state of the caller's trap flag

	 mov	 ax,[ebp].INTXX_EFL.ELO ; Get caller's low-order flags
	 and	 ax,mask $TF	; Isolate the trap flag
	 mov	 CR2FLAG,ax	; Save to restore later

; * Set the trap flag in the caller's flags

	 or	 [ebp].INTXX_EFL.ELO,mask $TF ; Set it

; * Save the address of the current single-step handler from the PM IDT

	 sub	 esp,size DTR_STR ; Make room for IDTR
	 SIDTD	 [esp].EDF	; Save onto the stack
	 mov	 ebx,[esp].DTR_BASE ; Get the IDT base value
	 add	 esp,size DTR_STR ; Strip from the stack

	 mov	 eax,AGROUP:EDQLO[ebx+01h*(type IDT_STR)] ; Get 1st dword
	 mov	 CR2INT01_IVEC.EDQLO,eax ; Save to restore later
	 mov	 eax,AGROUP:EDQHI[ebx+01h*(type IDT_STR)] ; Get 2nd dword
	 mov	 CR2INT01_IVEC.EDQHI,eax ; Save to restore later

; * Install our own local single-step handler in the PM IDT

	 lea	 eax,CR2INT01	; Get offset of our INT 01h handler
	 mov	 AGROUP:[ebx+01h*(type IDT_STR)].IDT_SELECT,cs
	 mov	 AGROUP:[ebx+01h*(type IDT_STR)].IDT_OFFLO,ax
	 shr	 eax,16 	; Shift down high-order word
	 mov	 AGROUP:[ebx+01h*(type IDT_STR)].IDT_OFFHI,ax
	 mov	 AGROUP:[ebx+01h*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3+CPL3

if @OEM_DPMI
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it
endif				; IF @OEM_DPMI
; * Restart the instruction

INT0E_IRETD:
if @OEM_DPMI
	 REGREST <fs,ds>	; Restore
	 assume  ds:nothing,fs:nothing ; Tell the assembler about it
INT0E_IRETD1:

; If this was a fault from a DPMI client, we need to restore selectors
; and the stack

	 cmp	 DPMICNT0E,0	; Izit active?
	 je	 short INT0E_XDPMI ; Jump if not

	 dec	 DPMICNT0E	; Count it out

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

;;;;;;;; mov	 eax,[ebp].INTXX_ERR ; Get original error code
;;;;;;;; mov	 [ebp].INTXX_ERR[@STK_DIFF],eax ; Restore

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,@STK_DIFF + (size INTXX_ERR) ; Strip off error code
				; and restore stack to original state

	 iretd			; Return to caller

INT0E_XDPMI:
endif				; IF @OEM_DPMI
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 IRETD_COM	; Return to caller

	 assume  gs:nothing	; Tell the assembler about it

; Back off to beginning of this ROM block so we can swap the entire ROM
; in case it's a paged-mode ROM

INT0E_BLOCK:
	 assume  fs:PDTGRP	; Tell the assembler about it

	 test	 OFFPDT[si-4],mask $PTE_RW ; Izit Read/Write?
	 jnz	 short INT0E_RWMIN ; Yes, we hit the end

	 sub	 si,4		; Back off by one PTE

	 jmp	 short INT0E_BLOCK ; Go around again

INT0E_RWMIN:

; If this entry is in the video ROM segment, start testing at PTE_VROM_BEG

	 mov	 di,PTE_VROM_SRC ; Get source PTE pseudo-offset

	 cmp	 si,PTE_VROM_END ; Check against upper limit
	 jae	 short INT0E_RWTEST ; It's outside that range

	 mov	 si,PTE_VROM_BEG ; Use minimum
INT0E_RWTEST:
	 test	 OFFPDT[si],mask $PTE_RW ; Izit Read/Write?
	 jnz	 short INT0E_CHKLIM ; Yes, check against limit

	 or	 OFFPDT[si],mask $PTE_RW ; Ensure Read/Write as REST_PTE
				; doesn't change the flags
; Swap back to ROM the affected page
; Restore FS:SI entry in PDT to physical memory calculated from DI

	 call	 REST_PTE	; Restore 'em and flush page translation cache
INT0E_CHKLIM:
	 add	 si,4		; Skip to next PTE
	 add	 di,4		; ...

	 cmp	 si,PTE_VROM_END ; Check against upper limit
	 jb	 short INT0E_RWTEST ; Still in range, continue testing

if @OEM_DPMI
	 REGREST <fs,ds>	; Restore
	 assume  ds:nothing,fs:nothing ; Tell the assembler about it
endif				; IF @OEM_DPMI

	 jmp	 INT0D_IRETD1	; Return to caller


	 public  INT0E_UGHPNP
INT0E_UGHPNP:
if @OEM_DPMI
	 popad			; Restore all EGP registers

; The stack is mapped by INTDPF_STR
; Note that INTDPF_INTNO is already filled in with the
; INT # times 4 + offset PGROUP:INTPROC00Z

; If this fault came from a DPMI client, give 'em a crack at it.
; If it came from VM, abort.

	 test	 [esp].INTDPF_EFL.EHI,mask $VM ; Izit from V86 mode?
	 jnz	 short @F	; Jump if so

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0E_DPMI_VISIBLE ; Jump if so
@@:
	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
endif				; IF @OEM_DPMI
	 lea	 bx,FGROUP:MSG_PNP ; Offset of message to display to user

	 jmp	 INT0E_UGHCOM	; Join common code


if @OEM_DPMI

; The stack is mapped by INTDPF_STR

	 public  INT0E_DPMI_VISIBLE
INT0E_DPMI_VISIBLE:
	 cmp	 DPMICNT0E,0	; Make sure DPMICNT0E is properly maintained
	 je	 short @F	; Jump if not active

	 dec	 DPMICNT0E	; Dec before calling client handler
@@:
	 test	 [esp].INTDPF_CS,mask $PL ; Izit at PL0?
	 jnz	 near ptr INTCOM_DPMI_FAULT ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPFHOOK[0Eh/8],1 shl (0Eh mod 8) ; Izit hooked by current client?
	 jnz	 short @F	; Jump if so

	 FIXIJMP IGROUP:FLTPROC_APPL,DTE_CSIG ; Join common code

@@:

DPMI_VPF_STR struc

DPMI_VPF_ESP0 dd ?		; Previous TSS_ESP0
DPMI_VPF_SS0 dw  ?		; ...	   TSS_SS0
DPMI_VPF_LPMSTK df ?		; Original LPMSTK_FVEC
DPMI_VPF_DS  dw  ?		; Caller's DS
DPMI_VPF_EBP dd  ?		; ...	   EBP
DPMI_VPF_EBX dd  ?		; ...	   EBX
DPMI_VPF_EAX dd  ?		; ...	   EAX
DPMI_VPF_NXT db  (size INTDPF_STR) dup (?) ; The rest of the stack

DPMI_VPF_STR ends

	 REGSAVE <eax,ebx,ebp,ds> ; Save registers

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 push	 PGROUP:[eax].TSS_SS0  ; Save old stack selector
	 push	 PGROUP:[eax].TSS_ESP0 ; Save pointer to stack top

; The stack is now mapped by DPMI_VPF_STR

	 mov	 ebp,esp	; Hello, Mr. Stack

; Set new LPM stack top for nested callers if it's active
; and we're called from PM, not PL0

	 lea	 ebx,[ebp].DPMI_VPF_NXT.INTDPF_EIP ; SS:EBX ==> INTDPI_STR from PL3
	 push	 ebx		; Pass the offset
	 FIXICALL IGROUP:FDPMIFN_LPMSTK,DTE_CSIG ; Save new LPM stack as appropriate

; * Save SS:ESP as new top of stack pointer

	 mov	 PGROUP:[eax].TSS_SS0,ss ; Save for next time
	 mov	 PGROUP:[eax].TSS_ESP0,esp ; ...

	 cli			; Disallow interrupts

; * Recalculate PL0STK pointers

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

; Setup the PL0 stack as if the fault occurred at PL3

	 inc	 LPMSTK_CNT	; Count in another one

	 push	 LPMSTK_FVEC.FSEL.EDD ; Fake up the SS for the fault
	 push	 LPMSTK_FVEC.FOFF ; Fake up the ESP for the fault
	 push	 [ebp].DPMI_VPF_NXT.INTDPF_EFL ; Pass the return flags
	 push	 [ebp].DPMI_VPF_NXT.INTDPF_INTNO ; Pass INT #
	 push	 DPMI_IDEF	 ; Pass the return CS
	 push	 dword ptr PMVPF ; Pass the return EIP
	 push	 [ebp].DPMI_VPF_NXT.INTDPF_ERR ; Pass the error code

	 mov	 ds,[ebp].DPMI_VPF_DS ; Restore original DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 eax,[ebp].DPMI_VPF_EAX ; ...		 EAX
	 mov	 ebx,[ebp].DPMI_VPF_EBX ; ...		 EBX
	 mov	 ebp,[ebp].DPMI_VPF_EBP ; ...		 EBP

	 jmp	 INTCOM_DPMI_FAULT ; Continue with the DPMI handler


	 public  DPMI_VPFRET
DPMI_VPFRET:

; We arrive at this label after a visible fault at ring 0.  When a
; fault at ring 0 occurs, the client is given a phony ring 3
; address (DPMI_IDEF:PMVPF) as the address where the fault occurred.
; Code at that address calls (via a call-gate) to here.  At this
; point, the user handler has been executed, and all registers are
; in the correct state.  All we have to do is to pop excess data from
; the stack and issue the IRETD.

; The stack is mapped by INTDPI_STR followed by DPMI_VPF_STR

	 add	 esp,size INTDPI_STR ; Strip off pseudo-return address

	 mov	 [esp].DPMI_VPF_DS,ds ; Save original DS
	 mov	 [esp].DPMI_VPF_EAX,eax ; ...	      EAX

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

; Restore the previous TSS_ESP0 and TSS_SS0 to the TSS

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 pop	 PGROUP:[eax].TSS_ESP0 ; Restore
	 pop	 PGROUP:[eax].TSS_SS0 ; ...

; Recalculate PL0STK pointers

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

; De-allocate our portion of the LPM stack

	 pop	 LPMSTK_FVEC.FOFF ; De-allocate it
	 pop	 LPMSTK_FVEC.FSEL ; ...
	 dec	 LPMSTK_CNT	; Count it out

; Restore caller's registers

	 pop	 ds		; Restore original DS
	 assume  ds:nothing	; Tell the assembler about it
	 pop	 eax		; ...		 EBP
	 pop	 eax		; ...		 EBX
	 pop	 eax		; ...		 EAX

	 add	 esp,size INTDPF_ERR ; Strip off pseudo-error code

	 iretd			; Return to fault address
endif				; IF @OEM_DPMI


	 public  INT0E_UGHSUP
INT0E_UGHSUP:
	 lea	 bx,FGROUP:MSG_SUP ; Offset of message to display to user

	 jmp	 short INT0E_UGHCOM ; Join common code


	 public  INT0E_UGHROM
INT0E_UGHROM:
if @OEM_DPMI
	 popad			; Restore all EGP registers

; The stack is mapped by INTDPF_STR
; Note that INTDPF_INTNO is already filled in with the
; INT # times 4 + offset PGROUP:INTPROC00Z

; If this fault came from a DPMI client, give 'em a crack at it.
; If it came from VM, abort.

	 test	 [esp].INTDPF_EFL.EHI,mask $VM ; Izit from V86 mode?
	 jnz	 short @F	; Jump if so

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 near ptr INTCOM_DPMI_FAULT ; Jump if so
@@:
	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
endif				; IF @OEM_DPMI
	 lea	 bx,FGROUP:MSG_ROM ; Offset of message to display to user
INT0E_UGHCOM:
if @OEM_DEBUG
	 lea	 di,FGROUP:INT0EMSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 mov	 si,4*0Eh	; Interrupt # times 4

	 jmp	 INTXXCOM	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0E	 endp			; End INT0E procedure
	 NPPROC  CR2INT01 -- CR2 Single-step Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler.	This routine is called iff there is
a page fault on a write into BCF or compressed ROM.

We take the following actions:

* Restore the address of the previous single-step handler
* Restore the modified data
* Clear the read/write bit in the PTE for the next time
* Restore the state of the caller's trap flag
* Continue execution

|

CR2INT01_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
	 dw	 ?,?		; ...	   CS
CR2INT01_EFL dd  ?		; ...	   EFL

CR2INT01_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ds,fs> ; Save registers

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; * Restore the address of the previous single-step handler

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 fs		; Address it
	 assume  fs:AGROUP	; Tell the assembler about it

	 sub	 esp,size DTR_STR ; Make room for IDTR
	 SIDTD	 [esp].EDF	; Save onto the stack
	 mov	 ebx,[esp].DTR_BASE ; Get the IDT base value
	 add	 esp,size DTR_STR ; Strip from the stack

	 mov	 eax,CR2INT01_IVEC.EDQLO ; Get 1st dword
	 mov	 AGROUP:EDQLO[ebx+01h*(type IDT_STR)],eax ; Restore
	 mov	 eax,CR2INT01_IVEC.EDQHI ; Get 2nd dword
	 mov	 AGROUP:EDQHI[ebx+01h*(type IDT_STR)],eax ; Restore

; * Restore the modified data

	 mov	 ebx,OLDCR2	; Get page fault linear address

	 mov	 eax,CR2DATA[00h] ; Get the 2nd preceding dword
	 mov	 AGROUP:[ebx-08h],eax ; Save back

	 mov	 eax,CR2DATA[04h] ; Get the 1st preceding dword
	 mov	 AGROUP:[ebx-04h],eax ; Save back

	 mov	 eax,CR2DATA[08h] ; Get the 1st following dword
	 mov	 AGROUP:[ebx+00h],eax ; Save back

	 mov	 eax,CR2DATA[0Ch] ; Get the 2nd following dword
	 mov	 AGROUP:[ebx+04h],eax ; Save back

; * Clear the read/write bit in the PTE for the next time

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

	 mov	 bx,CR2OFF	; FS:BX ==> PTE in PDE of page fault
	 and	 OFFPDT[bx],not (mask $PTE_RW) ; Clear it

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

; * Restore the state of the caller's trap flag

	 and	 [ebp].CR2INT01_EFL.ELO,not (mask $TF) ; Clear it
	 mov	 ax,CR2FLAG	; Get caller's trap flag
	 or	 [ebp].CR2INT01_EFL.ELO,ax ; Set caller's value

; * Continue execution

	 REGREST <fs,ds,ebx,eax> ; Restore
	 assume  ds:nothing,fs:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CR2INT01 endp			; End CR2INT01 procedure
	 NPPROC  REST_PTE -- Restore PTEs
	 assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:PGROUP
COMMENT|

Restore FS:SI entry in PDT to physical memory calculated from DI
without modifying flag bits.
Flush page translation cache.

On entry:

FS:SI	 ==>	 destin PTE (e.g., C000 or if VGASWAP B000)
FS:DI	 ==>	 source PTE (	   C000 	      C000)

|

	 REGSAVE <eax,cx>	; Save registers

	 movzx	 eax,di 	; Copy offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

; Add new frame to existing flags in PTE

	 and	 OFFPDT[si],not (mask $PTE_FRMHI or mask $PTE_FRM)
	 or	 OFFPDT[si],eax ; Save in lowmem area (keep old flags)

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 or	 GLB_FLAG,@GLB_ROM ; Mark as some ROM area swapped out

; If we're on a shadow RAM system, restore the old CHIPset register value

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short REST_PTE_EXIT ; Not this time

	 shr	 eax,14-0	; Convert from bytes to 16KB

	 sub	 ax,0A000h shr (14-4) ; Convert to origin-A000
	 jc	 short REST_PTE_EXIT ; Jump if bananas

	 mov	 ch,CT_RAM_AB	; Register #

	 cmp	 ax,(0C000h-0A000h) shr (14-4) ; Check for range
	 jb	 short REST_PTE1 ; Jump if within range

	 sub	 ax,(0C000h-0A000h) shr (14-4) ; Convert to origin-C000
	 mov	 ch,CT_RAM_CD	; Register #

	 cmp	 ax,(0E000h-0C000h) shr (14-4) ; Check for range
	 jb	 short REST_PTE1 ; Jump if within range

	 sub	 ax,(0E000h-0C000h) shr (14-4) ; Convert to origin-E000
	 mov	 ch,CT_RAM_EF	; Register #

	 cmp	 al,04h 	; Izit F000 or greater?
	 jae	 short REST_PTE_EXIT ; Yes, don't reset CHIPset
REST_PTE1:
	 mov	 cl,al		; Copy to count register

	 mov	 al,ch		; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH

	 mov	 al,1		; Set strobe bit
	 shl	 al,cl		; Shift into position
	 or	 ah,al		; Set the bit

	 mov	 al,ch		; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPset
REST_PTE_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_PTE endp			; End REST_PTE procedure
	 NPPROC  READ_CHIPSET -- Read Command/Data from CHIPset
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read data into AH from command register in AL in the CHIPset.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 out	 @CT_INDX,al	; Send command to CHIPset
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Copy value

	 in	 al,@CT_DATA	; Read data from CHIPset
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Return in data in AH, original command in AL

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CHIPSET endp		; End READ_CHIPSET procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

$P	 equ	 00h		; Prefix

$M	 equ	 01h		; MOD R/M byte present
$A	 equ	 02h		; Immediate word:word (OSP=0) or word:dword (OSP=1)
$O	 equ	 04h		; Immediate word (ASP=0) or dword (ASP=1)
$B	 equ	 08h		; Immediate byte
$W	 equ	 10h		; Immediate word
$V	 equ	 20h		; Immediate word (OSP=0) or dword (OSP=1)
$OSP	 equ	 40h		; Operand size prefix
$ASP	 equ	 80h		; Address ...

$BW	 equ	 $B or $W	; Immediate word and immediate byte
$MB	 equ	 $M or $B	; MOD R/M byte with immediate byte
$MV	 equ	 $M or $V	; MOD R/M byte with immediate word (OSP=0) or dword (OSP=1)

	 public  OPCOD1
;		 x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
OPCOD1	 db	 $M ,$M ,$M ,$M ,$MB,$MV, 0 , 0 ,$M ,$M ,$M ,$M ,$MB,$MV, 0 ,$P  ; 0x
	 db	 $M ,$M ,$M ,$M ,$MB,$MV, 0 , 0 ,$M ,$M ,$M ,$M ,$MB,$MV, 0 , 0  ; 1x
	 db	 $M ,$M ,$M ,$M ,$MB,$MV,$P , 0 ,$M ,$M ,$M ,$M ,$MB,$MV,$P , 0  ; 2x
	 db	 $M ,$M ,$M ,$M ,$MB,$MV,$P , 0 ,$M ,$M ,$M ,$M ,$MB,$MV,$P , 0  ; 3x
	 db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; 4x
	 db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; 5x
	 db	  0 , 0 ,$M ,$M ,$P ,$P ,$P ,$P ,$V ,$MV,$B ,$MB, 0 , 0 , 0 , 0  ; 6x
	 db	 $B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B  ; 7x
	 db	 $MB,$MV,$MB,$MB,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M  ; 8x
	 db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,$A , 0 , 0 , 0 , 0 , 0  ; 9x
	 db	 $O ,$O ,$O ,$O , 0 , 0 , 0 , 0 ,$B ,$V , 0 , 0 , 0 , 0 , 0 , 0  ; Ax
	 db	 $B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V  ; Bx
	 db	 $MB,$MB,$W , 0 ,$M ,$M ,$MB,$MV,$BW, 0 ,$W , 0 , 0 ,$B , 0 , 0  ; Cx
	 db	 $M ,$M ,$M ,$M ,$B ,$B , 0 , 0 ,$P ,$P ,$P ,$P ,$P ,$P ,$P ,$P  ; Dx
	 db	 $B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$V ,$V ,$V ,$B , 0 , 0 , 0 , 0  ; Ex
	 db	 $P , 0 ,$P ,$P , 0 , 0 ,$M ,$M , 0 , 0 , 0 , 0 , 0 , 0 ,$M ,$M  ; Fx

	 public  OPCOD2
;		 x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
OPCOD2	 db	 $M ,$M ,$M ,$M , ? , 0 , 0 , 0 , 0 , 0 , ? , ? , ? , ? , ? , ?  ; 0x
	 db	 $M ,$M ,$M ,$M , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 1x
	 db	  0 , 0 , 0 , 0 , 0 , ? , 0 , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 2x
	 db	  0 , 0 , 0 , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 3x
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 4x
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 5x
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 6x
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 7x
	 db	 $V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V  ; 8x
	 db	 $M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M  ; 9x
	 db	  0 , 0 , 0 ,$M ,$MB,$M ,$M ,$M , 0 , 0 , 0 ,$M ,$MB,$M , ? ,$M  ; Ax
	 db	 $M ,$M ,$M ,$M ,$M ,$M ,$M ,$M , ? , ? ,$MB,$M ,$M ,$M ,$M ,$M  ; Bx
	 db	 $M ,$M , ? , ? , ? , ? , ? ,$M , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; Cx
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; Dx
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; Ex
	 db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , 0  ; Fx

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 NPPROC  GETILEN -- Get Instruction Length
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get instruction length

On entry:

ES:ESI	 ==>	 First byte of instruction

On exit:

AX	 =	 length of instruction (assuming no immediate data)
ES:ESI	 ==>	 changed

|

	 REGSAVE <bx,cx,dx>	; Save registers

	 xor	 dl,dl		; Initialize flags
	 xor	 cx,cx		; Initialize byte count
GETILEN_NEXT:
	 lods	 AGROUP:[esi].LO ; Get next instruction byte
	 inc	 cx		; Count it in

	 cmp	 al,@OPCOD_CS	; Check for CS:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_DS	; Check for DS:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_ES	; Check for ES:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_FS	; Check for FS:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_GS	; Check for GS:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_SS	; Check for SS:
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_REPE ; Check for REPE
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_REPNE ; Check for REPNE
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_LOCK ; Check for LOCK
	 je	 short GETILEN_NEXT ; Jump if so

	 cmp	 al,@OPCOD_ESC0 ; Izit below ESC 0?
	 jb	 short @F	; Jump if so

	 cmp	 al,@OPCOD_ESC7 ; Izit above ESC 7?
	 jbe	 short GETILEN_NEXT ; Jump if not
@@:
	 cmp	 al,@OPCOD_OSP ; Check for OSP
	 jne	 short @F	; Jump if not

	 or	 dl,$OSP	; Mark as present

	 jmp	 short GETILEN_NEXT ; Jump if so

@@:
	 cmp	 al,@OPCOD_ASP ; Check for ASP
	 jne	 short @F	; Jump if not

	 or	 dl,$ASP	; Mark as present

	 jmp	 short GETILEN_NEXT ; Jump if so

@@:
	 lea	 bx,OPCOD1	; ES:BX ==> one-byte opcode table

	 cmp	 al,@OPCOD_2ND	; Check for secondary opcodes
	 jne	 short @F	; Jump if not

	 lods	 AGROUP:[esi].LO ; Get next instruction byte (opcode)
	 inc	 cx		; Count it in
	 lea	 bx,OPCOD2	; ES:BX ==> two-byte opcode table
@@:
	 xlat	 OPCOD1 	; Translate opcode into flags
	 or	 dl,al		; Include with OSP/ASP flags

; Check for immediate word:word (OSP=0) or word:dword (OSP=1)

	 test	 dl,$A		; Check it
	 jz	 short GETILEN_XA ; Jump if not

	 add	 cx,2+2 	; Count in word:word

	 test	 dl,$OSP	; Check for OSP
	 jz	 short GETILEN_XA ; Jump if OSP=0

	 add	 cx,2		; Count in extra word
GETILEN_XA:

; Check for immediate word (ASP=0) or dword (ASP=1)

	 test	 dl,$O		; Check it
	 jz	 short GETILEN_XO ; Jump if not

	 add	 cx,2		; Count in word

	 test	 dl,$ASP	; Check for ASP
	 jz	 short GETILEN_XO ; Jump if ASP=0

	 add	 cx,2		; Count in extra word
GETILEN_XO:

; Check for immediate byte

	 test	 dl,$B		; Check it
	 jz	 short GETILEN_XB ; Jump if not

	 inc	 cx		; Count in byte
GETILEN_XB:

; Check for immediate word

	 test	 dl,$W		; Check it
	 jz	 short GETILEN_XW ; Jump if not

	 add	 cx,2		; Count in word
GETILEN_XW:

; Check for immediate word (OSP=0) or dword (OSP=1)

	 test	 dl,$V		; Check it
	 jz	 short GETILEN_XV ; Jump if not

	 add	 cx,2		; Count in word

	 test	 dl,$OSP	; Check for OSP
	 jz	 short GETILEN_XV ; Jump if OSP=0

	 add	 cx,2		; Count in extra word
GETILEN_XV:
	 test	 dl,$M		; Izit present?
	 jz	 short GETILEN_EXIT ; Jump if not

	 lods	 AGROUP:[esi].LO ; Get next instruction byte (mod R/M)
	 inc	 cx		; Count it in
	 mov	 ah,al		; Save for later use

;;;;;;;; mov	 al,ah		; Copy for destructive test
	 and	 al,mask $MOD	; Isolate the MOD bits

	 test	 dl,$ASP	; Check for Address Size Prefix
	 jnz	 short GETILEN_ASP ; Jump if so

	 cmp	 al,11b shl $MOD ; Check for MOD=11 (register operand)
	 je	 short GETILEN_EXIT ; Jump if that's all

	 cmp	 al,10b shl $MOD ; Check for MOD=10 (DISP16)
	 je	 short GETILEN_D16 ; Jump if so

	 cmp	 al,01b shl $MOD ; Check for MOD=01 (DISP8)
	 je	 short GETILEN_D8 ; Jump if so

	 mov	 al,ah		; Copy for destructive test
	 and	 al,mask $RM	; Isolate the RM bits

	 cmp	 al,110b shl $RM ; Check for special DISP16
	 jne	 short GETILEN_EXIT ; Not this time
GETILEN_D16:
	 inc	 cx		; Count in another byte
	 inc	 esi		; Skip past the instruction byte
GETILEN_D8:
	 inc	 cx		; Count in another byte
	 inc	 esi		; Skip past the instruction byte

	 jmp	 short GETILEN_EXIT ; Join common code


; There's an Address Size Prefix, hence maybe an SIB byte

GETILEN_ASP:
	 mov	 al,ah		; Copy for destructive test
	 and	 al,mask $MOD	; Isolate the MOD bits

	 cmp	 al,11b shl $MOD ; Check for MOD=11 (register operand)
	 je	 short GETILEN_EXIT ; Jump if that's all

	 mov	 dh,ah		; Copy for destructive test
	 and	 dh,mask $RM	; Isolate the RM bits

	 cmp	 dh,100b shl $RM ; Check for special SIB byte
	 jne	 short @F	; Not this time

	 inc	 cx		; Count in another byte
	 inc	 esi		; Skip past the instruction byte
@@:
	 cmp	 al,10b shl $MOD ; Check for MOD=10 (DISP32)
	 je	 short GETILEN_D32 ; Jump if so

	 cmp	 al,01b shl $MOD ; Check for MOD=01 (DISP8)
	 je	 short GETILEN_D8 ; Jump if so

	 mov	 al,ah		; Copy for destructive test
	 and	 al,mask $RM	; Isolate the RM bits

	 cmp	 al,101b shl $RM ; Check for special DISP32
	 jne	 short GETILEN_EXIT ; Not this time
GETILEN_D32:
	 add	 cx,4		; Count in another dword
	 add	 esi,4		; Skip past the DISP32
GETILEN_EXIT:
	 mov	 ax,cx		; Copy to return register

	 REGREST <dx,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETILEN  endp			; End GETILEN procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_I0E module
