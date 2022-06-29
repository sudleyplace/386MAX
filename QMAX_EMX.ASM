;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EMX.ASV   1.3   30 May 1997 10:44:24   BOB  $
	 title	 QMAX_EMX -- 386MAX INT 67h Handler, Exchange/Move Fns
	 page	 58,122
	 name	 QMAX_EMX

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

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_OEM.INC
.list

if @OEM_EMS

; Local structure for data values

XMOVE_STR struc

XMOVE_LEN dd	 ?		; Region length

; When the source or destination memory is in EMS memory,
; the following four DD variables indicate where the source and
; destination XMOVE areas begin and end.

; Each value is relative to logical page #0 for the corresponding handle
; as if the logical pages were contiguous in EMS memory.

; When the source or destination memory is in conventional memory,
; the following four dwords indicate the linear address of the
; start and end.

SRC_START dd	 ?		; Offset in bytes in EMS
SRC_END   dd	 ?
DST_START dd	 ?
DST_END   dd	 ?

SRC_HNDL dw	 ?		; Source handle
DST_HNDL dw	 ?		; ...	 destin

SRC_NLPN dw	 ?		; # logical pages in source memory area
DST_NLPN dw	 ?		; ...		     destin

SRC_LPN  dw	 ?		; Next LPN in source memory area
DST_LPN  dw	 ?		; ...	      destin

SRC_OFF  dd	 ?		; Offset within current source LPN
DST_OFF  dd	 ?		; ...			destin

SRC_ADDR dd	 ?		; Currrent linear address of source
DST_ADDR dd	 ?		; ...			     destin

MEMTYPE  db	 ?		; Memory types for XMOVEMEM
XM_FLAG  db	 ?		; XMove flags

XMOVE_STR ends

; Equates for MEMTYPE

@MEMSRC  equ	 10b		; 10b = source type: clr=cnv, set=exp
@MEMDST  equ	 01b		; 01b = destin type

; Equates for XM_FLAG

@XM_MOVE equ	 80h		; Move in progress
@XM_XCHG equ	 40h		; Exchange in progress
@XM_HNDL equ	 20h		; Source and destin have same handle
@XM_DO	 equ	 10h		; Destructive overlap for move
@XM_NDO  equ	 08h		; Non-destructive overlap for move

; Calculate backup amount from EBP to address XMOVE_STR

@EBPBACK equ	 (size XMOVE_STR)


PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PPAGELINK:dword
	 extrn	 PLINKBASE:dword
	 extrn	 EMS_START:dword
;;;;;;;; extrn	 EMS_END:dword
	 extrn	 CON16KB:dword
	 extrn	 CON1MB:dword
	 extrn	 NPHYS16F:byte

	 public  XMOVEMEM_FNS
XMOVEMEM_FNS label word
	 dw	 PGROUP:EMM_XMOVEMEM0
	 dw	 PGROUP:EMM_XMOVEMEM1
XMOVEMEM_CNT equ ($-XMOVEMEM_FNS)/2


EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EMX_ECODE
@QMAX_EMX_ECODE:		; Mark module start in .MAP file

	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E8F:near
	 extrn	 EMM_E92:near
	 extrn	 EMM_ERR:near

	 extrn	 VALID_HNDL:near
	 extrn	 PL3DSSI:near
	 extrn	 ACTIVE_PAGES:near
	 extrn	 SKIP_LPN:near
	 extrn	 COPY2LCL:near
	 extrn	 WRAP_DISABLE:near

	 NPPROC  EMM_XMOVEMEM -- Exchange/Move Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 24, AH = 57h

Exchange/move memory

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

XMOVEMEM_STR struc

XMOVEMEM_LEN   dd ?		; Region length in bytes
XMOVEMEM_STYP  db ?		; Source memory type
XMOVEMEM_SHNDL dw ?		; Source handle (if STYP = 1)
XMOVEMEM_SOFF  dw ?		; Source initial offset
XMOVEMEM_SLPSG dw ?		; Source initial segment or logical page
XMOVEMEM_DTYP  db ?		; Destin memory type
XMOVEMEM_DHNDL dw ?		; Destin handle (if DTYP = 1)
XMOVEMEM_DOFF  dw ?		; Destin initial offset
XMOVEMEM_DLPSG dw ?		; Destin initial segment or logical page

XMOVEMEM_STR ends

	 cmp	 al,XMOVEMEM_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 XMOVEMEM_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_XMOVEMEM endp		; End EMM_XMOVEMEM procedure
	 NPPROC  EMM_XMOVEMEM0 -- Move Memory Function
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 24, AX = 5700h

Move memory

DS:ESI	 ==>	 XMOVEMEM_STR

Error return 83 if source or destination handle not valid
	     8A if source or destination logical page invalid
	     92 if move source overlaps destination (move done, though)
	     93 if source or destination length exceeds allocated logical pages
	     94 if conventional and expanded memory regions overlap
	     95 if source or destination offsets exceed 16KB
	     96 if region length exceeds 1MB
	     98 if memory source and destination type conflict
	     A2 if source region wraps at 1MB

All registers except EBP, SS, and ESP may be destroyed.

This routine is interruptible at all times.

|

	 cli			; Disallow interrupts until we've copied
				; the arguments to local storage
	 sub	 esp,size XMOVE_STR ; Make room for local structure

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:AGROUP	; Tell the assembler about it

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ecx,size XMOVEMEM_STR ; CX = # bytes in structure
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 sti			; Allow interrupts

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 [ebp-@EBPBACK].XM_FLAG,@XM_MOVE ; Mark as move

	 call	 CHK_XMOVE	; Check the argument
	 jc	 near ptr EMM_ERR ; Something went wrong; error code in AH

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

; Strip out EMS to EMS move with same handle, no overlap

	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC or @MEMDST ; EMS to EMS only
	 jne	 short EMM_XMOVEMEM0_CNV ; Not this time

	 test	 [ebp-@EBPBACK].XM_FLAG,@XM_DO ; Izit destructive overlap?
	 jnz	 short @F	; Yes, use different function
				; Fall through for no overlap or for
				; non-destructive overlap

	 call	 MOVE_EE_XDO	; Call EMS-to-EMS not destructive overlap handler

	 jmp	 short EMM_XMOVEMEM0_EXIT ; Join common exit code

@@:
	 call	 MOVE_EE_DO	; Call EMS-to-EMS destructive overlap handler

	 jmp	 short EMM_XMOVEMEM0_EXIT ; Join common exit code

EMM_XMOVEMEM0_CNV:
	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC ; EMS to CNV?
	 jne	 short @F	; Not this time

	 call	 MOVE_EC	; Call EMS-to-CNV handler

	 jmp	 short EMM_XMOVEMEM0_EXIT ; Join common exit code

@@:
	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMDST ; CNV to EMS?
	 jne	 short @F	; Not this time

	 call	 MOVE_CE	; Call CNV-to-EMS handler

	 jmp	 short EMM_XMOVEMEM0_EXIT ; Join common exit code

@@:
	 test	 [ebp-@EBPBACK].XM_FLAG,@XM_DO ; Izit destructive overlap?
	 jnz	 short @F	; Yes, use different function
				; Fall through for no overlap or for
				; non-destructive overlap

	 call	 MOVE_CC_XDO	; Call CNV-to-CNV not destructive ovrelap handler

	 jmp	 short EMM_XMOVEMEM0_EXIT ; Join common exit code

@@:
	 call	 MOVE_CC_DO	; Call CNV-to-CNV destructive overlap handler
EMM_XMOVEMEM0_EXIT:
	 test	 DBG_FLAG,@DBG_XM ; Signal NMI?
	 jz	 short @F	; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI
@@:

; Note that @GLB_XWRP is cleared, WRAP_ENABLE is called at EMM_EXIT,
; and the stack is cut back to EBP.

	 test	 [ebp-@EBPBACK].XM_FLAG,@XM_DO or @XM_NDO ; Was there an overlap?
	 jz	 near ptr EMM_E00AL ; Jump if no overlap

	 jmp	 EMM_E92	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_XMOVEMEM0 endp		; End EMM_XMOVEMEM0 procedure
	 NPPROC  EMM_XMOVEMEM1 -- Exchange Memory Function
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 24, AX = 5701h

Exchange memory

DS:ESI	 ==>	 XMOVEMEM_STR

Error return 83 if source or destination handle not valid
	     8A if source or destination logical page invalid
	     93 if source or destination length exceeds allocated logical pages
	     94 if conventional and expanded memory regions overlap
	     95 if source or destination offsets exceed 16KB
	     96 if region length exceeds 1MB
	     97 if source and destination expanded memory regions overlap
	     98 if memory source and destination type conflict
	     A2 if source region wraps at 1MB

All registers except EBP, SS, and ESP may be destroyed.

This routine is interruptible at all times.

|

	 cli			; Disallow interrupts until we've copied
				; the arguments to local storage
	 sub	 esp,size XMOVE_STR ; Make room for local structure

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:AGROUP	; Tell the assembler about it

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ecx,size XMOVEMEM_STR ; CX = # bytes in structure
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 sti			; Allow interrupts

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 [ebp-@EBPBACK].XM_FLAG,@XM_XCHG ; Mark as exchange

	 call	 CHK_XMOVE	; Check the argument
	 jc	 near ptr EMM_ERR ; Something went wrong; error code in AH

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

; Strip out EMS to EMS exchange

	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC or @MEMDST ; EMS to EMS only
	 jne	 short EMM_XMOVEMEM1_CNV ; Not this time

	 call	 XCHG_EE	; Call EMS-to-EMS

	 jmp	 short EMM_XMOVEMEM1_EXIT ; Join common exit code

EMM_XMOVEMEM1_CNV:
	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC ; EMS to CNV?
	 jne	 short @F	; Not this time

	 call	 XCHG_EC	; Call EMS-to-CNV handler

	 jmp	 short EMM_XMOVEMEM1_EXIT ; Join common exit code

@@:
	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMDST ; CNV to EMS?
	 jne	 short @F	; Not this time

	 call	 XCHG_CE	; Call CNV-to-EMS handler

	 jmp	 short EMM_XMOVEMEM1_EXIT ; Join common exit code

@@:
	 call	 XCHG_CC	; Call CNV-to-CNV
EMM_XMOVEMEM1_EXIT:
	 test	 DBG_FLAG,@DBG_XM ; Signal NMI?
	 jz	 short @F	; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI
@@:

; Note that @GLB_XWRP is cleared, WRAP_ENABLE is called at EMM_EXIT,
; and the stack is cut back to EBP.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_XMOVEMEM1 endp		; End EMM_XMOVEMEM1 procedure
	 NPPROC  MOVE_EE_XDO -- Move EMS to EMS, Not Destructive Overlap
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move EMS to EMS, no overlap or non-destructive overlap

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
MOVE_EE_XDO_NEXT:
	 mov	 esi,CON16KB	; Get source limit
	 mov	 edi,esi	; ... destin

	 sub	 esi,[ebp-@EBPBACK].SRC_OFF ; Less source offset
	 sub	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 mov	 ecx,esi	; Copy to temp register

	 cmp	 ecx,edi	; Use the smaller of the two
	 jbe	 short @F	; Jump if source is smaller

	 mov	 ecx,edi	; Destin is smaller
@@:
	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short MOVE_EE_XDO_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get source limit

	 cmp	 eax,[ebp-@EBPBACK].SRC_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].SRC_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].SRC_LPN ; Skip to the next LPN

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Skip to next destin block

@@:
	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get destin limit

	 cmp	 eax,[ebp-@EBPBACK].DST_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].DST_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].DST_LPN   ; Skip to the next LPN

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 MOVE_EE_XDO_NEXT ; Go around again

MOVE_EE_XDO_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_EE_XDO endp		; End MOVE_EE_XDO procedure
	 NPPROC  MOVE_EE_DO -- Move EMS to EMS, Destructive Overlap
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move EMS to EMS, destructive overlap

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Move the data from the end to the beginning

	 mov	 ax,[ebp-@EBPBACK].SRC_NLPN ; Get # LPNs in source memory area
	 dec	 ax		; Account for discrete arithmetic
	 add	 [ebp-@EBPBACK].SRC_LPN,ax ; Skip to last source LPN

	 mov	 ax,[ebp-@EBPBACK].DST_NLPN ; Get # LPNs in destin memory area
	 dec	 ax		; Account for discrete arithmetic
	 add	 [ebp-@EBPBACK].DST_LPN,ax ; Skip to last destin LPN

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Get move length

; Calculate the source offset in the last logical page

	 mov	 eax,[ebp-@EBPBACK].SRC_OFF ; Get source offset
	 add	 eax,ecx	; Plus move length

	 and	 eax,16*1024-1	; Modulo the limit
	 jnz	 short @F	; Jump if not on 16KB boundary

	 mov	 eax,CON16KB	; Get source limit
@@:
	 mov	 [ebp-@EBPBACK].SRC_OFF,eax ; Save as new source offset

; Calculate the destin offset in the last logical page

	 mov	 eax,[ebp-@EBPBACK].DST_OFF ; Get destin offset
	 add	 eax,ecx	; Plus move length

	 and	 eax,16*1024-1	; Modulo the limit
	 jnz	 short @F	; Jump if not on 16KB boundary

	 mov	 eax,CON16KB	; Get destin limit
@@:
	 mov	 [ebp-@EBPBACK].DST_OFF,eax ; Save as new destin offset

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
MOVE_EE_DO_NEXT:

; Calculate this block's move size
; as the smaller of the offsets in each block

	 mov	 esi,[ebp-@EBPBACK].SRC_OFF ; Get source offset
	 mov	 edi,[ebp-@EBPBACK].DST_OFF ; ... destin

	 mov	 ecx,esi	; Copy to temp register

	 cmp	 ecx,edi	; Use the smaller of the two
	 jbe	 short @F	; Jump if source is smaller

	 mov	 ecx,edi	; Destin is smaller
@@:
	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 dec	 esi		; Back off to last byte
	 dec	 edi		; Back off to last byte

	 std			; String ops backwards
	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB
	 cld			; Restore direction flag

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short MOVE_EE_DO_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next source block

	 sub	 [ebp-@EBPBACK].SRC_OFF,ecx ; Less move size
	 ja	 short @F	; Jump if it's still within range

	 mov	 eax,CON16KB	; Get source limit
	 add	 [ebp-@EBPBACK].SRC_OFF,eax ; Modulo the limit

	 dec	 [ebp-@EBPBACK].SRC_LPN   ; Skip to the next LPN

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Skip to next destin block

@@:
	 sub	 [ebp-@EBPBACK].DST_OFF,ecx ; Less move size
	 ja	 short @F	; Jump if it's still within range

	 mov	 eax,CON16KB	; Get destin limit
	 add	 [ebp-@EBPBACK].DST_OFF,eax ; Modulo the limit

	 dec	 [ebp-@EBPBACK].DST_LPN   ; Skip to the next LPN

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 MOVE_EE_DO_NEXT ; Go around again

MOVE_EE_DO_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_EE_DO endp 		; End MOVE_EE_DO procedure
	 NPPROC  MOVE_CE -- Move CNV to EMS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move CNV to EMS

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 movzx	 eax,[ebp-@EBPBACK].SRC_LPN ; Get the source segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
MOVE_CE_NEXT:
	 mov	 ecx,CON16KB	; Get destin limit
	 sub	 ecx,[ebp-@EBPBACK].DST_OFF ; Less destin offset

	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short MOVE_CE_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size

; Skip to next destin block

	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get destin limit

	 cmp	 eax,[ebp-@EBPBACK].DST_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].DST_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].DST_LPN   ; Skip to the next LPN

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 MOVE_CE_NEXT	; Go around again

MOVE_CE_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_CE  endp			; End MOVE_CE procedure
	 NPPROC  MOVE_EC -- Move EMS to CNV
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move EMS to CNV

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 movzx	 eax,[ebp-@EBPBACK].DST_LPN ; Get the destin segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
MOVE_EC_NEXT:
	 mov	 ecx,CON16KB	; Get source limit
	 sub	 ecx,[ebp-@EBPBACK].SRC_OFF ; Less source offset

	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short MOVE_EC_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next destin block

	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get source limit

	 cmp	 eax,[ebp-@EBPBACK].SRC_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].SRC_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].SRC_LPN   ; Skip to the next LPN

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 MOVE_EC_NEXT	; Go around again

MOVE_EC_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_EC  endp			; End MOVE_EC procedure
	 NPPROC  MOVE_CC_XDO -- Move CNV to CNV Not Destructive Overlap
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move CNV to CNV, no overlap or non-destructive overlap

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Get move size

; Calculate new SRC_ADDR

	 movzx	 esi,[ebp-@EBPBACK].SRC_LPN ; Get the destin segment
	 shl	 esi,4-0	; Convert from paras to bytes
	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset

; Calculate new DST_ADDR

	 movzx	 edi,[ebp-@EBPBACK].DST_LPN ; Get the destin segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; Plus destin offset

	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB

	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_CC_XDO endp		; End MOVE_CC_XDO procedure
	 NPPROC  MOVE_CC_DO -- Move CNV to CNV Destructive Overlap
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move CNV to CNV, destructive overlap

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Get move size

; Calculate new SRC_ADDR

	 movzx	 esi,[ebp-@EBPBACK].SRC_LPN ; Get the destin segment
	 shl	 esi,4-0	; Convert from paras to bytes
	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 esi,ecx	; Plus move size to last+1 byte
	 dec	 esi		; Back off to last byte

; Calculate new DST_ADDR

	 movzx	 edi,[ebp-@EBPBACK].DST_LPN ; Get the destin segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; Plus destin offset
	 add	 edi,ecx	; Plus move size to last+1 byte
	 dec	 edi		; Back off to last byte

	 std			; String ops backwards
	 call	 MOVE_4GB	; Move ECX bytes from ESI to EDI in 4GB
	 cld			; Restore direction flag

	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_CC_DO endp 		; End MOVE_CC_DO procedure
	 NPPROC  XCHG_EE -- Exchange EMS to EMS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exchange EMS to EMS

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
XCHG_EE_NEXT:
	 mov	 esi,CON16KB	; Get source limit
	 mov	 edi,esi	; ... destin

	 sub	 esi,[ebp-@EBPBACK].SRC_OFF ; Less source offset
	 sub	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 mov	 ecx,esi	; Copy to temp register

	 cmp	 ecx,edi	; Use the smaller of the two
	 jbe	 short @F	; Jump if source is smaller

	 mov	 ecx,edi	; Destin is smaller
@@:
	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 XCHG_4GB	; Exchange ECX bytes between ESI and EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short XCHG_EE_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get source limit

	 cmp	 eax,[ebp-@EBPBACK].SRC_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].SRC_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].SRC_LPN ; Skip to the next LPN

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Skip to next destin block

@@:
	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get destin limit

	 cmp	 eax,[ebp-@EBPBACK].DST_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].DST_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].DST_LPN   ; Skip to the next LPN

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 XCHG_EE_NEXT	; Go around again

XCHG_EE_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_EE  endp			; End XCHG_EE procedure
	 NPPROC  XCHG_CE -- Exchange CNV to EMS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exchange CNV to EMS

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 movzx	 eax,[ebp-@EBPBACK].SRC_LPN ; Get the source segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
XCHG_CE_NEXT:
	 mov	 ecx,CON16KB	; Get destin limit
	 sub	 ecx,[ebp-@EBPBACK].DST_OFF ; Less destin offset

	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 XCHG_4GB	; Exchange ECX bytes between ESI and EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short XCHG_CE_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size

; Skip to next destin block

	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get destin limit

	 cmp	 eax,[ebp-@EBPBACK].DST_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].DST_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].DST_LPN   ; Skip to the next LPN

; Calculate new DST_ADDR

	 mov	 ax,[ebp-@EBPBACK].DST_HNDL ; Get the destin handle
	 mov	 bx,[ebp-@EBPBACK].DST_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 XCHG_CE_NEXT	; Go around again

XCHG_CE_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_CE  endp			; End XCHG_CE procedure
	 NPPROC  XCHG_EC -- Exchange EMS to CNV
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exchange EMS to CNV

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as source linear address

; Calculate new DST_ADDR

	 movzx	 eax,[ebp-@EBPBACK].DST_LPN ; Get the destin segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@EBPBACK].DST_ADDR,eax ; Save as destin linear address
XCHG_EC_NEXT:
	 mov	 ecx,CON16KB	; Get source limit
	 sub	 ecx,[ebp-@EBPBACK].SRC_OFF ; Less source offset

	 cmp	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Use the smaller of the two
	 jbe	 short @F	; Jump if frame count is smaller

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Remaining count is smaller
@@:
	 mov	 esi,[ebp-@EBPBACK].SRC_ADDR ; Get source address
	 mov	 edi,[ebp-@EBPBACK].DST_ADDR ; ... destin

	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; ...  destin

	 call	 XCHG_4GB	; Exchange ECX bytes between ESI and EDI in 4GB

; Account for the move size

	 sub	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Less amount moved
	 jbe	 short XCHG_EC_EXIT ; That's all folks

; Register usage:
;
; ECX	 =	 move size in bytes

; Skip to next destin block

	 add	 [ebp-@EBPBACK].DST_OFF,ecx ; Plus move size

; Skip to next source block

	 add	 [ebp-@EBPBACK].SRC_OFF,ecx ; Plus move size
	 mov	 eax,CON16KB	; Get source limit

	 cmp	 eax,[ebp-@EBPBACK].SRC_OFF ; Check against limit
	 ja	 short @F	; Jump if it's within range

	 sub	 [ebp-@EBPBACK].SRC_OFF,eax ; Modulo the limit
	 inc	 [ebp-@EBPBACK].SRC_LPN   ; Skip to the next LPN

; Calculate new SRC_ADDR

	 mov	 ax,[ebp-@EBPBACK].SRC_HNDL ; Get the source handle
	 mov	 bx,[ebp-@EBPBACK].SRC_LPN ; Get the # LPNs to skip
	 call	 GET_EMSADDR	; Calculate it
	 mov	 [ebp-@EBPBACK].SRC_ADDR,eax ; Save as destin linear address
@@:
	 jmp	 XCHG_EC_NEXT	; Go around again

XCHG_EC_EXIT:
	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_EC  endp			; End XCHG_EC procedure
	 NPPROC  XCHG_CC -- Exchange CNV to CNV
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exchange CNV to CNV

On entry:

SS:EBP	 ==>	 INTXX_STR
SS:EBP-@EBPBACK ==> XMOVE_STR

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 mov	 ecx,[ebp-@EBPBACK].XMOVE_LEN ; Get move size

; Calculate new SRC_ADDR

	 movzx	 esi,[ebp-@EBPBACK].SRC_LPN ; Get the destin segment
	 shl	 esi,4-0	; Convert from paras to bytes
	 add	 esi,[ebp-@EBPBACK].SRC_OFF ; Plus source offset

; Calculate new DST_ADDR

	 movzx	 edi,[ebp-@EBPBACK].DST_LPN ; Get the destin segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,[ebp-@EBPBACK].DST_OFF ; Plus destin offset

	 call	 XCHG_4GB	; Exchange ECX bytes between ESI and EDI in 4GB

	 popad			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_CC  endp			; End XCHG_CC procedure
	 NPPROC  MOVE_4GB -- Move Bytes in 4GB
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move ECX bytes from ESI to EDI in 4GB.
This routine is sensitive to DF.
Note that the source and destin may overlap (non-destructively),
so, for that case at least, we can't optimize it to move dwords.

On entry:

DF	 =	 0 or 1
ECX	 =	 move length in bytes
ESI	 ==>	 source offset in DTE_D4GB
EDI	 ==>	 destin offset in DTE_D4GB

|

	 REGSAVE <ecx,esi,edi,es> ; Save registers

	 push	 DTE_D4GB	; Get selector of all memory
	 pop	 es
	 assume  es:AGROUP	; Tell the assembler about it

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move the bytes

	 REGREST <es,edi,esi,ecx> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_4GB endp			; End MOVE_4GB procedure
	 NPPROC  XCHG_4GB -- Exchange Bytes in 4GB
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exchange ECX bytes between ESI and EDI in 4GB.
This routine must be executed with DF = UP.
Note that the source and destin cannot overlap (non-destructively),
thus we can optimize it by exchanging dwords.

On entry:

ECX	 =	 exchange length in bytes
ESI	 ==>	 source offset in DTE_D4GB
EDI	 ==>	 destin offset in DTE_D4GB

|

	 REGSAVE <eax,ebx,ecx,esi,edi,es> ; Save registers

	 push	 DTE_D4GB	; Get selector of all memory
	 pop	 es
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ebx,esi	; Copy starting offset
	 mov	 esi,edi	; Ensure ESI same as EDI

; Exchange leading dwords

	 push	 ecx		; Save for a moment

	 shr	 ecx,2-0	; Convert from bytes to dwords
	 jz	 short XCHG_4GB_END1 ; Jump if no dwords to exchange
XCHG_4GB_NEXT1:
	 lods	 AGROUP:[esi].EDD ; Get next destin value at ES:ESI
	 xchg	 eax,AGROUP:[ebx] ; Swap with source at ES:EBX
S32	 stos	 AGROUP:[edi].EDD ; Save back into destin at ES:EDI

	 add	 ebx,4		; Skip to next destination entry

	 loop	 XCHG_4GB_NEXT1.EDD ; Jump if more bytes to transfer
XCHG_4GB_END1:
	 pop	 ecx		; Restore

; Exchange trailing bytes modulo 4

	 and	 ecx,4-1	; Isolate length modulo 4
	 jz	 short XCHG_4GB_END2 ; Jump if no bytes to exchange
XCHG_4GB_NEXT2:
	 lods	 AGROUP:[esi].LO ; Get next destin value at ES:ESI
	 xchg	 al,AGROUP:[ebx] ; Swap with source at ES:EBX
S32	 stos	 AGROUP:[edi].LO ; Save back into destin at ES:EDI

	 inc	 ebx		; Skip to next destination entry

	 loop	 XCHG_4GB_NEXT2.EDD ; Jump if more bytes to transfer
XCHG_4GB_END2:
	 REGREST <es,edi,esi,ecx,ebx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_4GB endp			; End XCHG_4GB procedure
	 NPPROC  GET_EMSADDR -- Calculate Next EMS Address
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the next EMS address.

On entry:

AX	 =	 source handle
BX	 =	 # source LPNs to skip

On exit:

EAX	 =	 next source EMS address

|

	 REGSAVE <ebx>		; Save register

	 push	 bx		; Pass the # LPNs to skip
	 push	 ax		; Pass the source handle
	 call	 SKIP_LPN	; Skip over logical pages
	 jc	 near ptr EMM_ERR ; Must be a software bug, error code in AH
				; Return with EBX ==> next logical page offset

	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; Get offset of next logical page #
	 sub	 ebx,PPAGELINK	; Convert to RPN
	 mov	 eax,ebx	; Save for a moment
;;;;;;;; shl	 ebx,2-2	; Convert from dword to dword index
	 add	 ebx,PLINKBASE	; Plus base of PDT PTEs
	 shl	 eax,4-2	; Convert from dword to four-dword index
	 add	 eax,PGROUP:[ebx] ; Plus the corresponding offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_EMSADDR endp		; End GET_EMSADDR procedure
	 NPPROC  CHK_XMOVE -- Check XMove Argument
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the XMove argument at DS:ESI.

Fill in the following items

MEMTYPE  with	 @MEMSRC  @MEMDST
SRC_START
SRC_END
DST_BASE (conventional only)
DST_START
DST_END
XM_FLAG  with	 @XM_HNDL  @XM_DO  @XM_NDO

On entry:

DS:ESI	 ==>	 XMOVEMEM_STR

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

AH	 =	 error code if CF=1
EAX	 =	 destroyed otherwise

|

	 REGSAVE <ebx,ecx,dx>	; Save registers

; Pick off the easy errors

; Ensure region length is < 1MB

	 mov	 ecx,ds:[esi].XMOVEMEM_LEN ; Save length in ECX
	 mov	 [ebp-@EBPBACK].XMOVE_LEN,ecx ; Save for later use

	 cmp	 ecx,CON1MB	; Check against 1MB limit
	 ja	 near ptr CHK_XMOVE_ERR96 ; Too big

; Check memory types

	 mov	 al,ds:[esi].XMOVEMEM_STYP ; Get source type

	 cmp	 al,1		; Check for above expanded type
	 ja	 near ptr CHK_XMOVE_ERR98 ; Unknown memory type

	 mov	 ah,ds:[esi].XMOVEMEM_DTYP ; Get destin type

	 cmp	 ah,1		; Check for above expanded type
	 ja	 CHK_XMOVE_ERR98 ; Unknown memory type

	 shl	 al,1		; Shift source type over to distinguish later
	 or	 al,ah		; Join together
	 mov	 [ebp-@EBPBACK].MEMTYPE,al ; Save for later use

; Save data in local data structure

	 mov	 ax,ds:[esi].XMOVEMEM_SLPSG ; Get initial LPN
	 mov	 [ebp-@EBPBACK].SRC_LPN,ax ; Save for later use

	 mov	 ax,ds:[esi].XMOVEMEM_DLPSG ; Get initial LPN
	 mov	 [ebp-@EBPBACK].DST_LPN,ax ; Save for later use

	 movzx	 eax,ds:[esi].XMOVEMEM_SOFF ; Get the initial offset
	 mov	 [ebp-@EBPBACK].SRC_OFF,eax ; Save for later use

	 movzx	 eax,ds:[esi].XMOVEMEM_DOFF ; Get the initial offset
	 mov	 [ebp-@EBPBACK].DST_OFF,eax ; Save for later use

; Check source data if expanded

	 test	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC ; Check source type
	 jz	 short CHK_XMOVE_SCNV ; It's conventional
	 page

; Source memory is expanded

; Check source handle

	 mov	 dx,ds:[esi].XMOVEMEM_SHNDL ; Get the handle into DX
	 mov	 [ebp-@EBPBACK].SRC_HNDL,dx ; Save for later use

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 CHK_XMOVE_ERR83 ; It's not

; Check initial source offset

	 cmp	 ds:[esi].XMOVEMEM_SOFF,03FFFh ; Ensure within limits
	 ja	 CHK_XMOVE_ERR95 ; It's too big

; Check initial logical source pages

	 xor	 eax,eax	; Zero entire register

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX

	 cmp	 ax,ds:[esi].XMOVEMEM_SLPSG ; Check initial logical page #
	 jbe	 CHK_XMOVE_ERR8A ; Initial page is too big

	 shl	 eax,14-0	; Convert from 16KB to bytes

; EAX = byte length of expanded memory allocated to this handle

	 movzx	 ebx,ds:[esi].XMOVEMEM_SLPSG ; Get initial logical page #

	 shl	 ebx,14-0	; Convert from 16KB to bytes
	 add	 bx,ds:[esi].XMOVEMEM_SOFF ; Add in initial offset
				; Note that this can't overflow

; EBX = starting byte offset of expanded source memory

	 mov	 [ebp-@EBPBACK].SRC_START,ebx ; Save for later use

	 add	 ebx,ecx	; Plus region length

; EBX = ending byte offset of expanded source memory

	 mov	 [ebp-@EBPBACK].SRC_END,ebx ; Save for later use

	 cmp	 eax,ebx	; Ensure not too big
	 jb	 near ptr CHK_XMOVE_ERR93 ; Region is too large for us

; Calculate # logical pages in source memory region

	 shr	 ebx,14-0	; Convert from bytes to 16KB (LPN)

	 mov	 eax,[ebp-@EBPBACK].SRC_START ; Get source starting offset
	 shr	 eax,14-0	; Convert from bytes to 16KB (LPN)

	 sub	 bx,ax		; Difference is # LPNs - 1

	 test	 [ebp-@EBPBACK].SRC_END.ELO,16*1024-1 ; Check ending for 16KB boundary
	 jz	 short CHK_XMOVE_S1   ; It's on a boundary, hence no extra page

	 inc	 bx		; Account for discrete arithmetic
CHK_XMOVE_S1:
	 mov	 [ebp-@EBPBACK].SRC_NLPN,bx ; Save for later use

	 jmp	 CHK_XMOVE_DEST ; OK, check destination memory
	 page

; Source memory is conventional

CHK_XMOVE_SCNV:

; Check initial source offset (can't be out of range)
; Check initial source segment

	 movzx	 ebx,ds:[esi].XMOVEMEM_SLPSG ; Get initial segment #
	 shl	 ebx,4-0	; Convert from paras to bytes

; EBX = starting base of conventional source memory

	 movzx	 eax,ds:[esi].XMOVEMEM_SOFF ; Get starting offset
	 add	 ebx,eax	; Plus starting offset

; EBX = starting byte offset of conventional source memory

	 mov	 [ebp-@EBPBACK].SRC_START,ebx ; Save for later use

	 cmp	 NPHYS16F,0	; Any EMS frame?
	 je	 short CHK_XMOVE_SNOEMS ; Not this time

; Check for overlap with EMS frame

	 cmp	 ebx,EMS_START	; Check against start of EMS frame
	 jb	 short CHK_XMOVE_SOVR ; It's below
;;;;;;;;
;;;;;;;; cmp	 ebx,EMS_END	; Check against end of EMS frame
;;;;;;;; jb	 CHK_XMOVE_ERR94 ; They overlap
CHK_XMOVE_SNOEMS:
	 add	 ebx,ecx	; Plus region length

	 jmp	 short CHK_XMOVE_S1MB ; Join common code

CHK_XMOVE_SOVR:
	 add	 ebx,ecx	; Plus region length
;;;;;;;;
;;;;;;;; cmp	 ebx,EMS_START	; Check against start of EMS frame
;;;;;;;; ja	 CHK_XMOVE_ERR94 ; They overlap

; EBX = ending byte offset of conventional source memory

CHK_XMOVE_S1MB:
	 mov	 [ebp-@EBPBACK].SRC_END,ebx ; Save for later use

; Check for 1MB wrap

	 cmp	 ebx,CON1MB	; Ensure not too big
	 ja	 CHK_XMOVE_ERRA2 ; Attempt to wrap at 1MB
	 page

; Check destin data if expanded

CHK_XMOVE_DEST:
	 test	 [ebp-@EBPBACK].MEMTYPE,@MEMDST ; Check destin type
	 jz	 short CHK_XMOVE_DCNV ; It's conventional

; Check destin handle

	 mov	 dx,ds:[esi].XMOVEMEM_DHNDL ; Get the handle into DX
	 mov	 [ebp-@EBPBACK].DST_HNDL,dx ; Save for later use

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 CHK_XMOVE_ERR83 ; It's not

; Check initial destin offset

	 cmp	 ds:[esi].XMOVEMEM_DOFF,03FFFh ; Ensure within limits
	 ja	 CHK_XMOVE_ERR95 ; It's too big

; Check initial logical destin pages

	 xor	 eax,eax	; Zero entire register

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX

	 cmp	 ax,ds:[esi].XMOVEMEM_DLPSG ; Check initial logical page #
	 jbe	 CHK_XMOVE_ERR8A ; Initial page is too big

	 shl	 eax,14-0	; Convert from 16KB to bytes

; EAX = byte length of expanded memory allocated to this handle

	 movzx	 ebx,ds:[esi].XMOVEMEM_DLPSG ; Get initial logical page #

	 shl	 ebx,14-0	; Convert from 16KB to bytes
	 add	 bx,ds:[esi].XMOVEMEM_DOFF ; Add in initial offset
				; Note that this can't overflow

; EBX = starting byte offset of expanded destin memory

	 mov	 [ebp-@EBPBACK].DST_START,ebx ; Save for later use

	 add	 ebx,ecx	; Plus region length

; EBX = ending byte offset of expanded destin memory

	 mov	 [ebp-@EBPBACK].DST_END,ebx ; Save for later use

	 cmp	 eax,ebx	; Ensure not too big
	 jb	 CHK_XMOVE_ERR93 ; Region is too large for us

; Calculate # logical pages in destin memory region

	 shr	 ebx,14-0	; Convert from bytes to 16KB (LPN)

	 mov	 eax,[ebp-@EBPBACK].DST_START ; Get destin starting offset
	 shr	 eax,14-0	; Convert from bytes to 16KB (LPN)

	 sub	 bx,ax		; Difference is # LPNs -1

	 test	 [ebp-@EBPBACK].DST_END.ELO,16*1024-1 ; Check ending for 16KB boundary
	 jz	 short CHK_XMOVE_D1   ; It's on a boundary, hence no extra page

	 inc	 bx		; Account for discrete arithmetic
CHK_XMOVE_D1:
	 mov	 [ebp-@EBPBACK].DST_NLPN,bx ; Save for later use

	 jmp	 CHK_XMOVE_COM	; Join common code
	 page

; Destin memory is conventional

CHK_XMOVE_DCNV:

; Check initial destin offset (can't be out of range)
; Check initial destin segment

	 movzx	 ebx,ds:[esi].XMOVEMEM_DLPSG ; Get initial segment #
	 shl	 ebx,4-0	; Convert from paras to bytes

; EBX = starting base of conventional destin memory

	 movzx	 eax,ds:[esi].XMOVEMEM_DOFF ; Get starting offset
	 add	 ebx,eax	; Plus starting offset

; EBX = starting byte offset of conventional destin memory

	 mov	 [ebp-@EBPBACK].DST_START,ebx ; Save for later use

	 cmp	 NPHYS16F,0	; Any EMS frame?
	 je	 short CHK_XMOVE_DNOEMS ; Not this time

; Check for overlap with EMS frame

	 cmp	 ebx,EMS_START	; Check against start of EMS frame
	 jb	 short CHK_XMOVE_DOVR ; It's below
;;;;;;;;
;;;;;;;; cmp	 ebx,EMS_END	; Check against end of EMS frame
;;;;;;;; jb	 CHK_XMOVE_ERR94 ; They overlap
CHK_XMOVE_DNOEMS:
	 add	 ebx,ecx	; Plus region length

	 jmp	 short CHK_XMOVE_D1MB ; Join common code

CHK_XMOVE_DOVR:
	 add	 ebx,ecx	; Plus region length
;;;;;;;;
;;;;;;;; cmp	 ebx,EMS_START	; Check against start of EMS frame
;;;;;;;; ja	 CHK_XMOVE_ERR94 ; They overlap

; EBX = ending byte offset of conventional destin memory

CHK_XMOVE_D1MB:
	 mov	 [ebp-@EBPBACK].DST_END,ebx ; Save for later use

; Check for 1MB wrap

	 cmp	 ebx,CON1MB	; Ensure not too big
	 ja	 CHK_XMOVE_ERRA2 ; Attempt to wrap at 1MB
	 page

CHK_XMOVE_COM:

; Check region length

	 jecxz	 CHK_XMOVE_ERR00 ; That's all folks

; See if the conventional source and destination overlap destructively

	 cmp	 [ebp-@EBPBACK].MEMTYPE,0 ; Both in conventional memory?
	 je	 short CHK_XMOVE_CNVCNV ; Yes

; See if the expanded source and destination overlap destructively

	 cmp	 [ebp-@EBPBACK].MEMTYPE,@MEMSRC or @MEMDST ; Both in EMS memory?
	 jne	 short CHK_XMOVE_OK ; No

	 mov	 ax,ds:[esi].XMOVEMEM_SHNDL ; Get source handle

	 cmp	 ax,ds:[esi].XMOVEMEM_DHNDL ; Same as destin handle?
	 jne	 short CHK_XMOVE_OK ; No

	 or	 [ebp-@EBPBACK].XM_FLAG,@XM_HNDL ; Mark as having same handle
CHK_XMOVE_CNVCNV:

; They overlap destructively iff SRC_START <= DST_START < SRC_END

	 mov	 eax,[ebp-@EBPBACK].DST_START ; Get start of destination

	 cmp	 eax,[ebp-@EBPBACK].SRC_START ; Check against lower one
	 jb	 short CHK_XMOVE_OVR ; Out of range

	 cmp	 eax,[ebp-@EBPBACK].SRC_END ; Check against upper one
	 jae	 short CHK_XMOVE_OVR ; Out of range

	 test	 [ebp-@EBPBACK].XM_FLAG,@XM_XCHG ; Doing an exchange?
	 jnz	 short CHK_XMOVE_ERR97 ; Yes, so that's an error

	 or	 [ebp-@EBPBACK].XM_FLAG,@XM_DO ; Mark as destructive overlap

; See if the source and destin overlap non-destructively
; They overlap non-destructively iff DST_START <= SRC_START < DST_END

CHK_XMOVE_OVR:
	 mov	 eax,[ebp-@EBPBACK].SRC_START ; Get start of destination

	 cmp	 eax,[ebp-@EBPBACK].DST_START ; Check against lower one
	 jb	 short CHK_XMOVE_OK ; Out of range

	 cmp	 eax,[ebp-@EBPBACK].DST_END ; Check against upper one
	 jae	 short CHK_XMOVE_OK ; Out of range

	 test	 [ebp-@EBPBACK].XM_FLAG,@XM_XCHG ; Doing an exchange?
	 jnz	 short CHK_XMOVE_ERR97 ; Yes, so that's an error

	 or	 [ebp-@EBPBACK].XM_FLAG,@XM_NDO ; Mark as non-destructive overlap
CHK_XMOVE_OK:
	 clc			; Indicate all went well

	 jmp	 short CHK_XMOVE_EXIT ; Join common exit code

CHK_XMOVE_ERR00:
	 mov	 ah,00h 	; Exit to caller with success

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR80:
	 mov	 ah,80h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR83:
	 mov	 ah,83h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR8A:
	 mov	 ah,8Ah 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR93:
	 mov	 ah,93h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

;;;_XMOVE_ERR94:
;;;;;;;; mov	 ah,94h 	; Exit to caller with error code in AH
;;;;;;;;
;;;;;;;; jmp	 short CHK_XMOVE_ERR ; Join common error exit code
;;;;;;;;
CHK_XMOVE_ERR95:
	 mov	 ah,95h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR96:
	 mov	 ah,96h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR97:
	 mov	 ah,97h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERR98:
	 mov	 ah,98h 	; Exit to caller with error code in AH

	 jmp	 short CHK_XMOVE_ERR ; Join common error exit code

CHK_XMOVE_ERRA2:
	 mov	 ah,0A2h	; Exit to caller with error code in AH
CHK_XMOVE_ERR:
	 stc
CHK_XMOVE_EXIT:
	 REGREST <dx,ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_XMOVE endp			; End CHK_XMOVE procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_EMS

	 MEND			; End QMAX_EMX module
