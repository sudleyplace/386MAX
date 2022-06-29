;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SWP.ASV   1.2   30 May 1997 10:46:02   BOB  $
	 title	 QMAX_SWP -- 386MAX Memory Swapping Routines
	 page	 58,122
	 name	 QMAX_SWP

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

	 include PDTGRP.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 SWPSIZE:word

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 MAPTAB:tbyte
	 include QMAX_MAP.INC

	 extrn	 PTE_FLAG:word
	 include QMAX_PTE.INC

if @OEM_XMS
	 extrn	 PPDTCVD:dword
endif				; IF @OEM_XMS
	 extrn	 PPDT1MB:dword
	 extrn	 PPDTCNV:dword

	 extrn	 CON4KB:dword
	 extrn	 CON1MB:dword
if @OEM_DMA
	 extrn	 DMA_SWAP:word
endif				; IF @OEM_DMA

	 public  SWAP_SRC,SWAP_SRC2
SWAP_SRC dd	 00100000h	; Physical address for source swap (1MB)
SWAP_SRC2 dd	 ?		; Secondary copy

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_SWP_ECODE
@QMAX_SWP_ECODE:		; Mark module start in .MAP file

	 extrn	 FIND_PTE:near

	 extrn	 WRAP_DISABLE:near
	 extrn	 WRAP_ENABLE:near

	 extrn	 FLUSH_TLB:near

	 extrn	 MOVE_DB:near
	 extrn	 SET_GDT:near

	 NPPROC  SWAP_MAP -- Swap PDT Entries for MAPBASE
	 assume  ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Swap PDT entries for MAPBASE and MAPTAB entries.

On entry:

EDX	 =	 current linear address of MAPBASE
ESI	 =	 offset in PDT of next MAPBASE entry
DI	 =	 index into MAPTAB

On exit:

EDX	 =	 (updated)
ESI	 =	 (updated)

|

	 REGSAVE <eax,cx,di>	; Save registers

	 test	 MAPTAB.MAP_FLAG[di],@MAP_ROM ; Izit ROM?
	 jz	 short SWAP_MAP_EXIT ; No, so don't swap it

	 test	 MAPTAB.MAP_FLAG[di],@MAP_SWAP ; Izit subject to swapping?
	 jz	 short SWAP_MAP_EXIT ; No, so don't swap it

	 mov	 cx,MAPTAB.MAP_LEN[di] ; Get entry length in paras
	 jcxz	 SWAP_MAP_EXIT	; Nothing there, skip this one
	 shr	 cx,12-4	; Convert from paras to # 4KB

	 mov	 di,MAPTAB.MAP_PARA_DST[di] ; Get paragraph #
	 shr	 di,12-4	; Convert from paras to 4KB
	 shl	 di,2		; Times four to index table of dwords
				; FS:DI ==> this page in PDT
SWAP_MAP_NEXT:
	 mov	 eax,OFFPDT[esi] ; Get MAPBASE PTE
	 and	 ax,mask $PTE_FRM ; Ignore flags

; Copy original PTE frame back in
; Leave PTE flags intact, but mark as Read Only

	 and	 OFFPDT[di],not (mask $PTE_FRM or mask $PTE_FRMHI or mask $PTE_RW)
	 or	 OFFPDT[di],eax ; Save in low memory entry

	 or	 OFFPDT[esi],mask $PTE_AV1 ; Mark as absent

	 add	 esi,4		; Skip to next source PTE offset
	 add	 di,4		; Skip to next destin PTE offset

	 add	 edx,CON4KB	; Skip to next linear address

	 loop	 SWAP_MAP_NEXT	; Jump if more pages to swap
SWAP_MAP_EXIT:
	 REGREST <di,cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_MAP endp			; End SWAP_MAP procedure
	 FPPROC  SWAP_MEM -- Swap Slow for Fast Memory
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Swap slow for fast memory

This routine ensures that the SWPSIZE KB of physical addresses
starting at SWAP_SRC are contiguous in the page tables starting
at linear address 0.

DS and ES point to high memory
CS and SS point to low memory

Because we will swap our own code and stack segment in the code
below, we must ensure we don't pull the rug out from under ourselves.
Thus this procedure must be in high memory which is in the static
ECODE segment (not the dynamic NCODE segment which is being overwritten
by the dynamic data addressed by DS and ES).

|


	 REGSAVE <eax,ecx,esi>	; Save registers

	 test	 GLB_FLAG,@GLB_FORC ; Is the ON state forced?
	 jz	 short SWAP_MEM_END ; No, ignore SWAP=

	 mov	 cx,SWPSIZE	; Get swap size in 1KB (it's a multiple of 4KB)

	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 jz	 short SWAP_MEM_END ; Jump if nothing to swap

	 cli			; Disallow interrupts

if @OEM_XMS

; Toggle PTE at PPDTCVD

	 mov	 eax,CON1MB	; Get common source flip-flop
	 mov	 esi,PPDTCVD	; Get offset of PTE in PDT
	 xor	 OFFPDT[esi],eax ; Flip the bits

endif				; IF @OEM_XMS

; Copy SWAP_SRC

	 mov	 eax,SWAP_SRC
	 mov	 SWAP_SRC2,eax

; Before, switch to a stack in high memory

	 mov	 si,ss		; Save old stack selector

	 mov	 ax,DTE_DS	; Get selector of high memory data
	 mov	 ss,ax		; Switch to high memory stack
	 assume  ss:nothing	; Tell the assembler about it

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

	 call	 SWAP_MEM_SUB	; Handle via subroutine

; Map the first 64KB of memory above the 1MB limit to the first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap
	 jnc	 short @F	; Jump if we flushed the TLB

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB
@@:

; After, switch back to the stack in low memory

	 mov	 ss,si		; Restore stack selector
	 assume  ss:nothing	; Tell the assembler about it

if @OEM_DMA

; Start DMA swaps at the new physical address at 1MB

	 mov	 esi,PPDT1MB	; Get offset to start of 1MB in the PDT
	 mov	 ax,OFFPDT.EHI[esi] ; Get high-order word
	 mov	 DMA_SWAP,ax	; Save for DMA swapping
endif				; IF @OEM_DMA

; For next time, the swap source physical address is 0

	 mov	 eax,CON1MB	; Get common source flip-flop
	 xor	 SWAP_SRC,eax	; Save as swap source physical address

SWAP_MEM_END:
	 REGREST <esi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_MEM endp			; End SWAP_MEM procedure
	 NPPROC  SWAP_MEM_SUB -- SWAP_MEM Subroutine in ECODE
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

DS and ES point to high memory
CS and SS point to low memory

***********************************************************************
This procedure relies upon the high memory stack residing in the static
data area.

Any routines called from here must be in static high memory.
***********************************************************************

On entry:

CX	 =	 # PTEs to swap

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 or	 PTE_FLAG,@PTE_SWAP ; Note we're doing SWAP_MEM

; Swap 4KB pages and the associated PTEs

	 xor	 edi,edi	; Initialize destin linear address offset in PDT
SWAP_MEM_SUB_NEXT:

; See if this PTE is already one-to-one

	 mov	 eax,OFFPDT[edi] ; Get the corresponding PTE
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame

	 cmp	 eax,SWAP_SRC2	; Izit one-to-one?
	 je	 short SWAP_MEM_SUB_LOOP0 ; Yes, keep on trucking

	 push	 SWAP_SRC2	; Pass physical address as argument
	 call	 FIND_PTE	; Find PTE in the PDT, return offset in ESI
				; assume ss:PGROUP
	 jc	 short SWAP_MEM_SUB_LOOP0 ; Jump if not found

	 mov	 eax,PPDTCNV	; Get offset of conventional memory entries
	 add	 eax,edi	; Plus low memory offset

	 cmp	 esi,eax	; Same offset?
	 je	 short SWAP_MEM_SUB_LOOP0 ; Yes, keep on trucking

; Convert the address in DI to a linear address for DTE_LML

	 mov	 eax,edi	; Copy to SET_GDT base register
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	 push	 CON4KB 	; Pass size of page
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_LML	; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base

; Convert the PDT offset in ESI to a linear address for DTE_BIOS

	 call	 OFF2LIN	; Return with linear address in EAX

; Setup DTE_BIOS to point to linear address with next source PTE

	 push	 CON4KB 	; Pass size of page
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_BIOS	; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base

	 REGSAVE <ecx>		; Save register

	 mov	 ecx,CON4KB	; # bytes to move

	 push	 DTE_DMA	; Pass descriptor of DMA    area
	 push	 DTE_LML	; ...		     dest
	 call	 MOVE_DB	; Move ECX bytes

; Swap the PTEs

	 and	 OFFPDT[edi],not (mask $PTE_AV0) ; Clear low memory mapped
				; memory bit so PPDTCNV won't have it set
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE
				; although we ignore the increment to ESI

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 test	 PTE_FLAG,@PTE_MISS ; Was the PTE missing?
	 jnz	 short SWAP_MEM_SUB_MISS1 ; Yes, ignore copy to source

	 push	 DTE_BIOS	; Pass descriptor of source area
	 push	 DTE_LML	; ...		     dest
	 call	 MOVE_DB	; Move ECX bytes
SWAP_MEM_SUB_MISS1:
	 push	 DTE_LML	; Pass descriptor of dest   area
	 push	 DTE_DMA	; ...		     DMA
	 call	 MOVE_DB	; Move ECX bytes

	 REGREST <ecx>		; Restore

	 jmp	 short SWAP_MEM_SUB_LOOP ; Join common loop code

SWAP_MEM_SUB_LOOP0:
	 add	 edi,4		; Skip to next low memory PTE

; Skip to next 4KB page for both source and destination

SWAP_MEM_SUB_LOOP:
	 mov	 eax,CON4KB	; Get constant 4KB
	 add	 SWAP_SRC2,eax	; Skip to next source physical page

;;;;;;;; loop	 SWAP_MEM_SUB_NEXT ; Jump if more pages to swap
	 dec	 cx		; One fewer from count register
	 jnz	 near ptr SWAP_MEM_SUB_NEXT ; Jump if more pages to swap

	 and	 PTE_FLAG,not @PTE_SWAP ; Reset SWAP_MEM flag

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_MEM_SUB endp		; End SWAP_MEM_SUB procedure
	 NPPROC  XCHG_PTE -- Exchange PTEs
	 assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Exchange PTEs

On entry:

FS:ESI	 ==>	 source PTE
FS:EDI	 ==>	 dest	PTE

On exit:

FS:ESI	 ==>	 next source PTE
FS:EDI	 ==>	 next dest   PTE

|

	 push	 eax		; Save EGP register

	 mov	 eax,OFFPDT[esi] ; Get source PTE
	 xchg	 eax,OFFPDT[edi] ; Swap with destination PTE
	 mov	 OFFPDT[esi],eax ; Save back as source PTE

	 add	 esi,type OFFPDT ; Skip to next source PTE
	 add	 edi,type OFFPDT ; Skip to next dest   PTE

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XCHG_PTE endp			; End XCHG_PTE procedure
	 NPPROC  OFF2LIN -- Convert PDT Offset to Linear Address
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the PDT offset in SI to a linear address
taking into account the mapping of PTEs at PPDTCNV
to conventional memory at 00000000.

On entry:

ESI	 =	 offset in PDT

On exit:

EAX	 =	 corresponding linear address

|

	 mov	 eax,esi	; Copy to result register

	 cmp	 eax,PPDTCNV	; In the conventional memory entries?
	 jb	 short OFF2LIN1 ; No, too small

	 sub	 eax,PPDTCNV	; Yes, convert to origin-0
OFF2LIN1:
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OFF2LIN  endp			; End OFF2LIN procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_SWP module
