;' $Header:   P:/PVCS/MAX/386MAX/QMAX_PMR.ASV   1.3   30 May 1997 10:45:52   BOB  $
	 title	 QMAX_PMR -- 386MAX PMR I/O Functions
	 page	 58,122
	 name	 QMAX_PMR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386

.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC

	 include PDTGRP.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_OEM.INC
.list

if @OEM_EMS

PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PRPNCUR:dword
	 extrn	 @RPN_UNMAP:abs
	 extrn	 HP_LAST:dword
	 extrn	 PPAGELINK:dword
	 extrn	 PHNDLPAGE:dword
	 extrn	 PLINKBASE:dword
	 extrn	 PPHYS2SEG:dword

	 public  NBOARDS,PORTPMR,PORTPMRZ
NBOARDS  dw	 ?		; # 2MB "boards" in the EMS system
PORTPMR  dw	 0F000h 	; Base I/O port for PMRs
PORTPMRZ dw	 ?		; End+1 I/O port for PMRs

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_PMR_ECODE
@QMAX_PMR_ECODE:		; Mark module start in .MAP file

	 extrn	 INT0D_IRETD:near
	 extrn	 PL3ESDI:near
	 extrn	 VALID_HNDL:near
	 extrn	 ACTIVE_PAGES:near
	 extrn	 RPNMAP_COM:near

	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E00:near
	 extrn	 EMM_E80:near
	 extrn	 EMM_E83:near

	 NPPROC  EMM_GETPMR -- Get Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 10, AH = 49h

Get the page mapping register I/O port array

Return in AL the # 2MB EMS "boards"
Store  in ES:DI the PMR I/O port array
Note that this array maps physical pages in the EMS frame only

No errors possible

|

	 mov	 cx,NBOARDS	; Get # 2MB "boards" in EMS system

	 shl	 cx,2		; Times four I/O ports per board
	 jz	 short EMM_GETPMR_EXIT ; No EMS memory

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,PORTPMR	; Get the base I/O port address
EMM_GETPMR_NEXT:
S32	 stos	 es:[edi].ELO	; Save I/O port address in output area
	 inc	 ax		; Bump to next I/O port
	 loop	 EMM_GETPMR_NEXT ; Jump if more I/O port addresses to save
EMM_GETPMR_EXIT:
	 mov	 al,NBOARDS.LO	; Return # 2MB "boards" in EMS system in AL

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETPMR endp 		; End EMM_GETPMR procedure
	 NPPROC  EMM_GETL2PMAP -- Get Logical to Physical Page Map
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 11, AH = 4Ah

Get the logical to physical page map

For handle DX, return in BX the # pages allocated to it
Store in ES:DI the logical to physical page translation array

On entry:

SS:EBP	 ==>	 INTXX_STR

Error return 83 if DX not valid handle
	     80 if software inconsistency

|

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:nothing	; Tell the assembler about it

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX

	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in BX
	 inc	 ax		; Count in HNDLPAGE entry
	 mov	 cx,ax		; Save in count register

	 movzx	 ebx,dx 	; Get the handle
	 shl	 ebx,2		; Times four to index table of dwords
	 add	 ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]
GETL2PMAP1:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

	 cmp	 ebx,HP_LAST	; Check for last entry
	 je	 short GETL2PMAP2 ; That's all folks

; The relative page # is the offset from the start of the PAGELINK table
; divided by four to get single increments.

	 mov	 eax,ebx	; Copy offset
	 sub	 eax,PPAGELINK	; Less start of PAGELINK table
	 shr	 eax,2		; Divide by size PL_STR

; This value is then translated into a pseudo-physical page on
; a pseudo-board by dividing it by 128.  The quotient is the
; pseudo-board #, the remainder is the pseduo-physical page #.

	 shl	 ax,1		; Put quotient (pseudo-board #) into AH
	 stc			; Ensure "page-enabled" bit is set
	 rcr	 al,1		; Isolate remainder (pseudo-physical page #)
	 xchg	 al,ah		; Swap to save order

S32	 stos	 es:[edi].ELO	; Save pseudo-board and physical page #

	 loop	 GETL2PMAP1	; Jump if more entries
EMM_E80B:
	 jmp	 EMM_E80	; We ran out of entries before last one

GETL2PMAP2:
	 loop	 EMM_E80B	; Ensure we used all the pages (jump if CX <> 1)

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETL2PMAP endp		; End EMM_GETL2PMAP procedure
	 NPPROC  PPN2BRDRPN -- Translate PPN to (Board #, RPN)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate a physical page # into a (Board #, RPN) pair

On entry:

DX	 =	 Board #:14, PPN:2

On exit:

BX	 =	 Board #:8, Page enable:1=0, RPN:7

CF	 =	 1 if page is unmapped
	 =	 0 otherwise

|

	 REGSAVE <eax>		; Save register

	 mov	 bx,dx		; Copy to index register
	 mov	 eax,size RPN_STR ; Get size of structure
	 and	 bl,11b 	; Isolate the physical page #
	 mul	 bl		; Times physical 16KB page # (origin-0)
	 mov	 ebx,eax	; Copy to index register

; The relative page # is the offset from the start of the PAGELINK table,
; thus they are even numbers by definition

	 add	 ebx,PRPNCUR	; Plus start of current RPNCUR table
	 mov	 bx,PGROUP:[ebx].RPN_RPN ; Get the relative page #

; This value is then translated into a relative page on
; a pseudo-board by dividing it by 128.  The quotient is the
; pseudo-board #, the remainder is the relative page #.

	 shr	 bl,1		; Put remainder (relative page #) into BL

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPN2BRDRPN endp 		; End PPN2BRDRPN procedure
	 FPPROC  EMU_PORTPMRI -- Emulate PMR IN For Functions 10 and 11
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate EMS functions 10 and 11
This function handles the IN from the corresponding I/O ports.

For a given (handle, LPN) pair find the corresponding entry in
the PAGELINK table.  Subtract from this value the start of the
PAGELINK table (found in PPAGELINK).  Assume AX contains this value.

The relative page # is AL/2.
The pseudo-board # is  AH.

On entry:

PUSHAD has been done.

Error code is on the stack.

Caller's IP has been incremented past the instruction.

SS:EBP	 ==>	 INTXX_STR

|

	 mov	 ax,DTE_DS	; Setup DS & ES for later code
	 mov	 ds,ax
	 mov	 es,ax
	 assume  ds:PGROUP,es:PGROUP

	 test	 DBG_FLAG,@DBG_PMR ; Debugging PMR I/O?
	 jz	 short EMU_PORTPMRI_NODBG ; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI upon return
EMU_PORTPMRI_NODBG:
	 mov	 dx,[ebp].INTXX_EDX.ELO ; Restore original register
	 sub	 dx,PORTPMR	; Convert to origin-0

; The low-order two bits of DX point to the physical page.
; The remaining bits are the pseudo-board #.

	 call	 PPN2BRDRPN	; Translate PPN in DX into (Board #, RPN) in BX
				; On return BX = (Board #:8, Page enable:1=0, RPN:7)
	 jc	 short EMU_PORTPMRI_UNMAP ; Jump if unmapped

	 shr	 dx,2		; DX = pseudo-board #

	 cmp	 bh,dl		; Same pseudo-board # ?
	 jne	 short EMU_PORTPMRI_EXIT ; No, so the page-enable bit is clear

	 or	 bl,@BIT7	; Ensure page-enable bit is set

	 jmp	 short EMU_PORTPMRI_EXIT ; Join common exit code

EMU_PORTPMRI_UNMAP:
	 mov	 bl,0		; Return a zero if unmapped
EMU_PORTPMRI_EXIT:
	 mov	 [ebp].INTXX_EAX.ELO.LO,bl ; Return in caller's AL

	 jmp	 INT0D_IRETD	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_PORTPMRI endp		; End EMU_PORTPMRI procedure
	 FPPROC  EMU_PORTPMRO -- Emulate PMR OUT For Functions 10 and 11
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Emulate EMS functions 10 and 11
This function handles the OUT to the corresponding I/O ports.

On entry:

PUSHAD has been done.

Error code is on the stack.

Caller's IP has been incremented past the instruction.

SS:EBP	 ==>	 INTXX_STR

|

	 push	 DTE_DS 	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

;;;;;;;; push	 DTE_PDT	; Get our PDT selector
;;;;;;;; pop	 fs		; Address it
;;;;;;;; assume  fs:PDTGRP	; Tell the assembler about it
;;;;;;;;
	 test	 DBG_FLAG,@DBG_PMR ; Debugging PMR I/O?
	 jz	 short EMU_PORTPMRO_NODBG ; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI upon return
EMU_PORTPMRO_NODBG:
	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Restore original registers
	 mov	 dx,[ebp].INTXX_EDX.ELO
	 sub	 dx,PORTPMR	; Convert to origin-0

; The low-order two bits of DX point to the physical page to map.
; The remaining bits are the 2MB "board" #.  The value in AL is the
; 7-bit relative page # with the high-order bit acting as the
; page-enable bit.

	 ror	 dx,2		; Rotate out the PPN bits
	 mov	 ah,dl		; Copy pseudo-board # as high-order byte
	 shr	 dx,16-2	; Bring down the PPN
				; and clear the rest of the register

; AX = (Board #:8, Page enable:1, RPN:7)
; DX = PPN

	 shl	 al,1		; Test and remove page-enable bit,
				; times two to index table of words
	 jnc	 short EMU_PORTPMRO_UNMAP ; We're to unmap the physical page

	 movzx	 ebx,ax 	; Copy to index register
	 mov	 esi,ebx	; Save for a moment
	 shl	 ebx,2-1	; Convert from word to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-1	; Convert from word to four-dword index
	 add	 esi,PGROUP:[ebx] ; Plus the corresponding offset

	 movzx	 edi,dx 	; Get physical 16KB page # (origin-0)
	 shl	 edi,1		; Times two to index table of words
	 mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table
	 mov	 PGROUP:[ebx+edi].RPN_RPN,ax ; Save as new RPN

;;;;;;;; shr	 edi,1		; Convert from bytes to page #
;;;;;;;; shl	 edi,1		; Convert from page # to words

	 add	 edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	 mov	 di,PGROUP:[edi] ; DI has segment # in paras of this
				; physical page (multiple of 4KB in paras)
	 shr	 di,(12-2)-4	; Convert from paras to 4KB in dwords
				; ES:DI ==> 4 PTEs for this 16 KB physical page

; ES:ESI = offset of PTEs in PDT for this 16KB page
; ES:DI = offset in PDT of this physical page (calculated above)

; Re-map the first 64KB of memory above the 1MB limit into itself
; only if the source operand is within the first 64KB above 1MB
; This also flushes the TLB if CF=0 on return

; DI = offset in PDT of this physical page (calculated above)

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

	 jmp	 short EMU_PORTPMRO_EXIT ; Join common exit code

COMMENT|

We're to disable a (board #, RPN, PPN).

First, we must determine whether or not this triple is currently mapped in.
If not, simply ignore the operation (the caller is unmapping PPNs on other
boards).

|

EMU_PORTPMRO_UNMAP:
	 call	 PPN2BRDRPN	; Translate PPN in DX into (Board #, RPN) in BX
				; On return BX = (Board #:8, Page enable:1=0, RPN:7)
	 jc	 short EMU_PORTPMRO_EXIT ; Jump if already unmapped

	 cmp	 ah,bh		; Same pseudo-board #?
	 jne	 short EMU_PORTPMRO_EXIT ; No, so ignore the operation

	 movzx	 edi,dx 	; Get physical 16KB page # (origin-0)
	 shl	 edi,1		; Times two to index table of words
	 mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table
	 mov	 PGROUP:[ebx+edi].RPN_RPN,@RPN_UNMAP ; Save as new RPN

	 push	 @RPN_UNMAP	; Pass the relative 16KB page # (origin-0)
	 push	 dx		; Pass the physical 16KB page # (origin-0)
	 call	 RPNMAP_COM	; Call common page map routine
;;;;;;;; jc	 ???		; Ignore if logical page # not found
EMU_PORTPMRO_EXIT:
	 jmp	 INT0D_IRETD	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_PORTPMRO endp		; End EMU_PORTPMRO procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_EMS

	 MEND			; End QMAX_PMR module
