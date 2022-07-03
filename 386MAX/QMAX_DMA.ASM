;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DMA.ASV   1.2   30 May 1997 10:44:18   BOB  $
	 title	 QMAX_DMA -- 386MAX DMA Handler
	 page	 58,122
	 name	 QMAX_DMA

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DMA.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TRC.INC

	 include PDTGRP.INC
.list

if @OEM_DMA
PGROUP	 group	 CODE,ECODE,EDATA
FGROUP	 group	 FDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DMA_FLAG:byte
	 include QMAX_DMA.INC

	 extrn	 SEL_DSFG3:word

	 extrn	 PPDTD2M:dword
	 extrn	 CON4KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON1P1MB:dword

	 extrn	 DMA_REMAP:byte
	 extrn	 DMA_ACT:byte
	 extrn	 DMA_PMR:byte
	 extrn	 DMA_ADDR:word
	 extrn	 DMA_CNT:dword
	 extrn	 DMA_MAX:dword

	 extrn	 PHYSIZE:dword

	 public  DMA_BLK
DMA_BLK  dd	 (64*1024)/157	; Transfer size of maximum of 64KB
				; which takes 5 clocks at 4MHz = 82 ms
				; 19.2 Kb comm line generates 157 interrupts
				; in that time

	 public  DMA_PTR,DMA_LEN,DMA_MVD
DMA_PTR  dd	 8 dup (?)	; DMA linear addresses, one per channel
DMA_LEN  dd	 8 dup (?)	; DMA transfer lengths in bytes, ....
DMA_MVD  dd	 8 dup (?)	; DMA transfer amount already moved to DMA_PTR

	 public  DMA_PA,DMA_LA,DMA_D2M
DMA_PA	 dd	 ?		; DMA swapping area physical address
DMA_LA	 dd	 ?		; ...		    linear
DMA_D2M  dd	 ?		; Device-to-memory base linear address

	 public  DMA_IADDR,DMA_ICNT,DMA_FLIP
DMA_IADDR db	 00h,02h,04h,06h,0C0h,0C4h,0C8h,0CCh
DMA_ICNT  db	 01h,03h,05h,07h,0C2h,0C6h,0CAh,0CEh
DMA_FLIP  db	 0Ch,0Ch,0Ch,0Ch,0D8h,0D8h,0D8h,0D8h

	 public  DMA_MODE
DMA_MODE db	 8 dup (?)	; DMA mode register

	 public  DMASIZE
DMASIZE  dw	 @DMA_DEF	; Size of DMA swapping area in 1KB

;;;;;;;; public  DMA_USTATE,DMA_ISTATE
;;;_USTATE db	 00000000b	; DMA user     status,	    channels 0-7
;;;_ISTATE db	 00000000b	; DMA internal status,	    channels 0-7
	 public  DMA_CHAN
DMA_CHAN   db	 00000000b	; DMA transfer in progress, channels 0-7

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_DMAFULL:byte

if @OEM_DEBUG
	 public  INT0E_DMAFULL
INT0E_DMAFULL db 'DMA full err',0
endif				; IF @OEM_DEBUG

FDATA	 ends			; End FDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_DMA_ECODE
@QMAX_DMA_ECODE:		; Mark module start in .MAP file

	 extrn	 INTXXCOM:near
	 extrn	 WRAP_ENABLE:near
	 extrn	 WRAP_DISABLE:near
	 extrn	 FLUSH_TLB:near
	 extrn	 REST_PTE:near
	 extrn	 BIN2BASE:near

if DBG_TRACE
	 extrn	 TRACE:near
endif				; IF DBG_TRACE

	 NPPROC  CHECK_PMR -- Check On DMA Remapping
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on DMA re-mapping.

On entry:

EBX	 =	 DMA channel # (0-7)
SS:EBP	 ==>	 INTXX_STR

On exit:

CF	 =	 0 if no mapping occurred,
	 =	 1 if pages re-mapped

DS, ES, and FS may be changed.

This routine needs to be modified to handle simultaneous DMA *FIXME*.

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 call	 CHECK_DMA	; Check on DMA terminations for channel EBX
	 btr	 DMA_CHAN.ELO,bx ; Clear the bit

; We've got to set the upper 8 bits of the EISA address

	 xor	 ah,ah		; Assume we're not on an EISA (no High Page)

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit an EISA DMA system?
	 jz	 short @F	; Jump if not

	 mov	 dl,DMA_REMAP[bx] ; Get the PMR register
	 mov	 dh,4h		; High Page Segment = Low page segment + 400h

	 in	 al,dx		; Get new PMR (address bits 24-31)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Move High Page byte
@@:

	 mov	 al,DMA_PMR[bx] ; Get PMR value (address bits 16-23)
	 shl	 eax,16 	; Shift to high-order

	 mov	 ecx,DMA_CNT[ebx*(type DMA_CNT)] ; Get count value
	 inc	 ecx		; Convert from limit to length

	 test	 DMA_FLAG[bx],@DMA_BYTE ; Izit an 8-bit transfer?
	 jnz	 short CHECK_PMR_BYTE1 ; Yes

; It's a 16-bit transfer
; The saved count is in units of words

	 shl	 ecx,1-0	; Convert from words to bytes

; Distinguish betweeen MCA and non-MCA machines as the format is different
; An MCA-compatible machine isn't 8237-compatible w.r.t.
; word transfer formats.  On that machine, the address is one-to-one
; bit for bit with the linear address.

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 short CHECK_PMR_BYTE1 ; Yes, set ADDR

	 test	 DMA_FLAG[bx],@DMA_MCA ; Izit an MCA-compatible machine transfer?
	 jnz	 short CHECK_PMR_BYTE1 ; Yes, set ADDR

; The saved address is the real address/2
; The saved PMR value is the real PMR value with bit 0 ignored

	 shr	 eax,1		; Shift PMR bit 0 down
	 mov	 ax,DMA_ADDR[ebx*2] ; Get 16-bit address/2
	 shl	 eax,1		; Shift PMR bit 0 back up

	 jmp	 short CHECK_PMR_BYTE2 ; Join common code

CHECK_PMR_BYTE1:
	 mov	 ax,DMA_ADDR[ebx*2] ; Get 16-bit address
CHECK_PMR_BYTE2:

if DBG_TRACE
	 push	 'L'            ; Pass length flag
	 call	 TRACE		; Save in trace table

	 xchg	 cl,ch		; Swap 'em to display high-order byte first

	 push	 cx		; Get high-order byte of transfer size
	 call	 TRACE		; Save in trace table

	 xchg	 cl,ch		; Swap 'em to display low-order byte next

	 push	 cx		; Get low-order ...
	 call	 TRACE		; Save in trace table
endif				; IF DBG_TRACE

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit an EISA DMA system?
	 jz	 short @F	; Jump if not

; Check for buggy BIOSes which don't set the high order byte
; of the PMR value.  This is a problem only with AMI EISA BIOSes,
; not with Phoenix...

	 push	 eax		; Save

	 add	 eax,ecx	; Skip to end
	 shr	 eax,10-0	; Convert to KB

	 cmp	 eax,PHYSIZE	; Are we ending at or below top of memory?

	 pop	 eax		; Restore

	 jna	 short @F	; Jump if so

	 and	 eax,00ffffffh	; Mask off high order 8 bits
@@:
	 mov	 DMA_PTR[ebx*4],eax ; Save for later use
	 mov	 DMA_LEN[ebx*4],ecx ; Save for later use
	 mov	 DMA_MVD[ebx*4],0  ; Mark as none moved so far

; Disable 1MB wrap if address is in that area
; That is, if  Start < 1.1MB and (Start+Length) > 1MB

	 and	 DMA_FLAG[bx],not @DMA_1MB ; Assume not

	 cmp	 eax,CON1P1MB	; Check starting address
	 ja	 short CHECK_PMR_X1MB ; No

	 lea	 edx,[eax+ecx]	; Point to end+1

	 cmp	 edx,CON1MB	; Check ending+1 address
	 jbe	 short CHECK_PMR_X1MB ; No

	 or	 DMA_FLAG[bx],@DMA_1MB ; Mark as needing 1MB wrap disable

; Disable the 1MB wrap

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap
	 assume  fs:nothing	; Tell the assembler about it
CHECK_PMR_X1MB:
	 mov	 dl,DMA_MODE[bx] ; Get mode byte

; Check for read/write transfer mode, ignore other modes

	 and	 dl,mask $TRANS0B ; Isolate the transfer bits

	 cmp	 dl,@TRANS0B_WR shl $TRANS0B ; Check for write transfer
	 je	 short CHECK_PMR_WRITE ; Jump if write

	 cmp	 dl,@TRANS0B_RD shl $TRANS0B ; Check for read transfer
	 jne	 near ptr CHECK_PMR_CLC  ; Ignore this operation


; Read transfer from memory to DMA channel

CHECK_PMR_READ:

; Check for consecutive PTEs in the source

	 call	 CHECK_PTE	; Check 'em
	 jc	 near ptr CHECK_PMR_EXIT ; Jump if PTEs consecutive (note CF=1)

; Ensure the DMA transfer buffer is large enough (ECX = requested length)

	 movzx	 edx,DMASIZE	; Get size of DMA buffer in 1KB
	 shl	 edx,10-0	; Convert from 1KB to bytes

	 cmp	 ecx,edx	; Ensure it's within range
	 ja	 near ptr CHECK_PMR_ERR ; Jump if it's too long

;;;;;;;; call	 DMA_WAIT	; Wait for DMA to complete

	 or	 GLB_FLAG,@GLB_DMA ; Mark as DMA transfer in progress

; Copy values from memory to DTE_DMA

	 push	 DTE_D4GB	; Get all memory data selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,DMA_LA	; Destin offset is our DMA buffer
	 mov	 esi,eax	; Source offset is user's buffer

	 sti			; Allow interrupts

	 push	 ecx		; Save for a moment

	 shr	 ecx,2-0	; Convert from bytes to dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move them dwords

	 pop	 ecx		; Restore

	 and	 ecx,11b	; Isolate remainder modulo 4

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move them bytes

	 cli			; Disallow interrupts

	 and	 GLB_FLAG,not @GLB_DMA ; Reset DMA flag

	 jmp	 CHECK_PMR_ADDR ; Join common code

	 assume  es:nothing	; Tell the assembler about it

; Write transfer from DMA channel to memory

CHECK_PMR_WRITE:

; Check for consecutive PTEs in the destin

	 call	 CHECK_PTE	; Check 'em
	 jc	 near ptr CHECK_PMR_EXIT ; Jump if PTEs consecutive (note CF=1)

; Ensure the DMA transfer buffer is large enough (ECX = requested length)

	 movzx	 edx,DMASIZE	; Get size of DMA buffer in 1KB
	 shl	 edx,10-0	; Convert from 1KB to bytes

	 cmp	 ecx,edx	; Ensure it's within range
	 ja	 near ptr CHECK_PMR_ERR ; Jump if it's too long

; Copy the PTEs to PPDTD2M

	 push	 DTE_PDT	; Get PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

	 mov	 esi,DMA_PTR[ebx*4] ; Get starting address
	 shr	 esi,12-0	; Convert from bytes to 4KB
	 shl	 esi,12-(12-2)	; Convert from 4KB to 4KB in dwords
	 mov	 edi,PPDTD2M	; ES:EDI ==> destin offset in PDT
	 movzx	 ecx,DMASIZE	; Get size of DMA transfer buffer
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 inc	 ecx		; Plus one for slop

	 REGSAVE <ecx,esi,edi>	; Save for a moment

S32  rep movs	 <es:[edi].EDD,es:[esi].EDD> ; Copy 'em

	 REGREST <edi,esi,ecx>	; Restore

; Check the PTEs for ROM

CHECK_PMR_WRITE_NEXT:
	 test	 es:[edi].ELO,mask $PTE_RW ; Izit read/writable?
	 jnz	 short @F	; Yes

	 mov	 eax,esi	; Get the source offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
	 mov	 es:[edi],eax	; Save as destin PTE
@@:
	 add	 esi,4		; Skip to next PTE in source
	 add	 edi,4		; ...		      destin

	 loop	 CHECK_PMR_WRITE_NEXT ; Jump if more PTEs to check

	 test	 DMA_FLAG[bx],@DMA_1MB ; Need enabling?
	 jnz	 short CHECK_PMR_ADDR ; Yes, so it'll happen then

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB


; Program the DMA address register with the physical address of DTE_DMA

CHECK_PMR_ADDR:
	 mov	 eax,DMA_PA	; Get the physical address
	 call	 SET_DMA	; Set the address to EAX

	 mov	 dl,DMA_MODE[bx] ; Get mode byte
	 and	 dl,mask $TRANS0B ; Isolate the transfer bits

	 cmp	 dl,@TRANS0B_WR shl $TRANS0B ; Check for write transfer
	 jne	 short @F	; Not this time, no need to set DMA_CHAN

	 bts	 DMA_CHAN.ELO,bx ; Mark as transfer in progress
@@:
	 stc			; Indicate we did the OUT

	 jmp	 short CHECK_PMR_EXIT ; Join common exit code

CHECK_PMR_CLC:
	 clc			; Indicate we did nothing
CHECK_PMR_EXIT:
	 pushf			; Save return flag

	 test	 DMA_FLAG[bx],@DMA_1MB ; Need enabling?
	 jz	 short @F	; Not this time

	 assume  fs:PDTGRP	; Tell the assembler about it

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap
	 jnc	 short @F	; Jump if we flushed the TLB

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 assume  fs:nothing	; Tell the assembler about it
@@:
	 popf			; Restore return flag

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

; DMA transfer limit exceeded -- ECX has actual transfer request length

CHECK_PMR_ERR:
	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 mov	 eax,ecx	; Copy to BIN2BASE register
	 add	 eax,4*1024-1	; Round up to 4KB boundary
	 and	 eax,not (4*1024-1) ; Round back
	 shr	 eax,10-0	; Convert from bytes to 1KB

	 lea	 di,FGROUP:MSG_DMAFULL[1] ; ES:DI ==> message start
	 mov	 cx,-1		; We know it's there
	 push	 ax		; Save for a moment
	 mov	 al,'_'         ; Search for the marker
	 cld			; String ops forwardly
   repne scas	 MSG_DMAFULL[di] ; Search for it
	 pop	 ax		; Restore

	 dec	 di		; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

; Set flag to skip display of "at ____:____" message

	 or	 DB3_FLAG,@DB3_XADDR ; Mark as skipping message

	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

	 mov	 si,[ebp].INTXX_INTNO ; Get caller's interrupt # times 4 (if any)
	 lea	 bx,FGROUP:MSG_DMAFULL ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT0E_DMAFULL ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 INTXXCOM	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PMR endp			; End CHECK_PMR procedure
	 NPPROC  CHECK_PTE -- Check For Consecutive PTEs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check for consecutive PTEs which don't span a 64KB boundary.

On entry:

EBX	 =	 DMA channel # (0-7)
EAX	 =	 starting linear address	(also in DMA_PTR[ebx*4])
ECX	 =	 DMA transfer length		(also in DMA_LEN[ebx*4])

On exit:

CF	 =	 1 if we did the OUT to the PMR
		 and we are to ignore this operation.
	 =	 0 if we should use our local buffer (at DTE_DMA)
		 to perform the DMA

DS, ES, and FS may be changed.

|

	 REGSAVE <eax,ecx,edx,si,di> ; Save registers

	 test	 DB2_FLAG,@DB2_XDMA ; Should we skip this optimization?
	 jnz	 near ptr CHECK_PTE_BUF ; Yes, use the local buffer instead

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

; Determine the # PTEs spanned by this transfer

	 add	 ecx,eax	; Point to end+1 of transfer
	 dec	 ecx		; Back off to the end

	 shr	 eax,12-0	; Convert from bytes to 4KB
	 shr	 ecx,12-0	; ...

	 sub	 cx,ax		; The difference is the # PTEs - 1
	 inc	 cx		; Get # PTEs to check

	 mov	 si,ax		; Copy to index register
	 shl	 si,12-(12-2)	; Convert from 4KB to 4KB in dwords
	 mov	 di,si		; Save address for later use

	 mov	 edx,OFFPDT[si] ; Get the first PTE to use as a seed

; Check for ROM in the initial entry

	 test	 dx,mask $PTE_RW ; Read-writable page?
	 jnz	 short @F	; Yes, OK to proceed

; Restore FS:SI entry in PDT to original ROM value

	 push	 di		; Save for a moment

	 mov	 di,si		; Copy as physical source for REST_PTE
	 call	 REST_PTE	; Restore 'em and flush page translation cache

	 pop	 di		; Restore

	 mov	 edx,OFFPDT[si] ; Get the first PTE to use as a seed
@@:
	 and	 dx,mask $PTE_FRM ; Isolate 4KB frame
CHECK_PTE_NEXT:
	 mov	 eax,OFFPDT[si] ; Get the next PTE

; Ignore this operation if it's not physical memory.

;;;;;;;; test	 ax,mask $PTE_AV1 ; Check for not physical memory
;;;;;;;; jnz	 short CHECK_PTE_OUT ; Yes, let 'em DMA into the air if they want to

; Check for ROM

	 test	 ax,mask $PTE_RW ; Read-writable page?
	 jnz	 short @F	; Yes, OK to proceed

; Restore FS:SI entry in PDT to original ROM value

	 push	 di		; Save for a moment

	 mov	 di,si		; Copy as physical source for REST_PTE
	 call	 REST_PTE	; Restore 'em and flush page translation cache

	 pop	 di		; Restore

	 mov	 eax,OFFPDT[si] ; Get the next PTE
@@:
;;;;;;;; test	 ax,mask $PTE_US ; User-level page?
;;;;;;;; jz	 short CHECK_PMR_USNO ; No, so that's an error

	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

	 cmp	 eax,DMA_MAX	; At or above our maximum DMA physical address?
	 jae	 short CHECK_PTE_BUF ; Yes, use local DMA buffer

	 cmp	 eax,edx	; Same address?
	 jne	 short CHECK_PTE_BUF ; No, use our local DMA buffer

	 add	 edx,CON4KB	; Skip to next 4KB address
	 add	 si,4		; Bump to next PTE

	 loop	 CHECK_PTE_NEXT ; Jump if more 4KB pages to check

; See if these PTEs span a 64KB boundary --
; they do if the 64KB quotient (high-order word)
; of the first and last PTEs are different.
; OFFPDT[di]	 =	first PTE
; EAX		 =	last PTE

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 short CHECK_PTE_OUT ; Yes, no DMA boundary error possible

	 shr	 eax,16-0	; Convert from bytes to 64KB

	 cmp	 ax,OFFPDT[di].EHI ; Compare 'em to determine if 64KB boundary cross
	 jne	 short CHECK_PTE_BUF ; It's a cross, use local DMA buffer

; The PTEs are consecutive.
; See if we need to re-specify the 24-bit address

CHECK_PTE_OUT:
	 mov	 eax,OFFPDT[di] ; Restore the first PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

;;;;;;;; mov	 edx,DMA_PTR[ebx*4] ; Restore starting address
;;;;;;;; and	 dx,mask $PTE_FRM ; Isolate 4KB frame
;;;;;;;;
;;;;;;;; cmp	 eax,edx	; Check the full 32-bit address
;;;;;;;; je	 short CHECK_PTE_END ; Jump if they match exactly

	 mov	 dx,DMA_PTR.ELO[ebx*4] ; Restore low-order 16-bits
				; of the starting address
	 and	 dx,not (mask $PTE_FRM) ; Isolate 4KB offset
	 or	 ax,dx		; Include in EAX

; EAX has the new 24-bit address

	 call	 SET_DMA	; Set the address to EAX
CHECK_PTE_END:
	 stc			; Indicate we did the OUT

	 jmp	 short CHECK_PTE_EXIT ; Join common exit code

CHECK_PTE_BUF:
	 clc			; Indicate we should use local DMA buffer
CHECK_PTE_EXIT:
	 REGREST <di,si,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PTE endp			; End CHECK_PTE procedure
	 NPPROC  SET_DMA -- Set DMA Address
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Program the DMA address.

On entry:

EAX	 =	 24-bit address to use
EBX	 =	 DMA channel # (0-7)

|

	 REGSAVE <eax,dx>	; Save registers

	 test	 DMA_FLAG[bx],@DMA_MCA ; Izit an MCA-compatible machine transfer?
	 jnz	 short SET_DMA_MCA ; Yes

	 movzx	 dx,DMA_FLIP[bx] ; Get the flip-flop I/O port
	 out	 dx,al		; Set flip-flop
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 movzx	 dx,DMA_IADDR[bx] ; Get base address

	 test	 DMA_FLAG[bx],@DMA_BYTE ; Izit an 8-bit transfer?
	 jnz	 short SET_DMA_COM  ; Yes, no need to adjust the address

; Distinguish betweeen MCA and non-MCA machines as the format is different
; An MCA-compatible machine isn't 8237-compatible w.r.t.
; word transfer formats.  On that machine, the address is one-to-one
; bit for bit with the linear address.

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 short SET_DMA_COM ; Jump if so
;;;;;;;; jz	 short SET_DMA_WORD ; Jump if not
;;;;;;;;
; Adjust the address to conform to DMA controller #2 format
; of A31-A16 ³ 0,A15-A1 in the high ³ low words
;;;;;;;;
;;;;;;;;			; A31-A16    ³	   A15-A0
;;;;;;;; shr	 ax,1		; A31-A16    ³	0, A15-A1
;;;;;;;;
;;;;;;;; jmp	 short SET_DMA_COM ; Join common code

; Adjust the address to conform to DMA controller #2 format
; of A31-A17, x ³ A16-A1 in the high ³ low words

;;;SET_DMA_WORD:
				; A31-A16    ³	   A15-A0
	 ror	 eax,17 	; A16-A1     ³ A0, A31-A17
	 shl	 ax,1		; A16-A1     ³ A31-A17, 0
	 rol	 eax,16 	; A31-A17, 0 ³ A16-A1
SET_DMA_COM:
	 out	 dx,al		; Set new address, (address bits 0-7)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 shr	 eax,8		; Shift down one byte

	 out	 dx,al		; Set new address, (address bits 8-15)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 shr	 eax,8		; Get the PMR value

	 mov	 DMA_ACT[bx],al ; Save for later use
	 movzx	 dx,DMA_REMAP[bx] ; Get the PMR register

	 out	 dx,al		; Set new PMR (address bits 16-23)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit an EISA DMA system?
	 jz	 short @F	; Jump if not

	 shr	 eax,8		; Get the PMR value (highest byte)

;;;;;;;; mov	 dl,DMA_REMAP[bx] ; Get the PMR register (already set)
	 mov	 dh,4h		; High Page Segment = Low page segment + 400h

	 out	 dx,al		; Set new PMR (address bits 24-31)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
@@:

	 jmp	 short SET_DMA_EXIT ; Join common exit code

SET_DMA_MCA:
	 mov	 dl,al		; Save for a moment
	 mov	 al,bl		; Get the channel #
	 or	 al,@DMA3_WADDR ; Write memory address register
	 out	 @DMA3_CMD,al	; Tell the DMA controller

	 mov	 al,dl		; Restore byte 0
	 out	 @DMA3_DATA,al	; Write byte 0

	 shr	 eax,8		; Shift down bytes 1-2
	 out	 @DMA3_DATA,al	; Write byte 1

	 shr	 eax,8		; Shift down byte 2
	 out	 @DMA3_DATA,al	; Write byte 2

	 mov	 DMA_ACT[bx],al ; Save for later use
SET_DMA_EXIT:
	 REGREST <dx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_DMA  endp			; End SET_DMA procedure
	 NPPROC  CHECK_DMA -- Check On DMA Transfer Terminations
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on DMA transfer terminations.

DMA_CHAN indicates what is in progress

This routine needs to be modified to handle simultaneous DMA *FIXME*.

|

;;;;;;;; test	 GLB_FLAG,@GLB_DMA ; DMA transfer in progress?
;;;;;;;; jnz	 short CHECK_DMA_RET ; Yes, skip out

	 REGSAVE <eax,ebx>	; Save registers

	 cld			; String ops forwardly

DMA_STAT equ	 1		; 1 = Use @DMAx_STAT ports for TC
				; 0 = Use count registers for TC
if DMA_STAT
	 call	 GET_TC 	; Get TC bits for all DMA channels into AL
	 jz	 short CHECK_DMA_EXIT ; No channels terminated
else
	 mov	 al,DMA_CHAN	; Get channel flags
endif				; IF DMA_STAT
CHECK_DMA_NEXT:
	 call	 NEXT_DMACHAN	; Get the next DMA channel into EBX
	 jz	 short CHECK_DMA_EXIT ; No more

if DBG_TRACE
	 push	 'D'            ; Get CHECK_DMA indicator
	 call	 TRACE		; Save in trace table
endif				; IF DBG_TRACE

ife DMA_STAT
	 push	 eax		; Save remaining DMA_CHAN bits

	 mov	 al,DMA_MODE[bx] ; Get mode bits for this channel
	 and	 al,mask $TRANS0B ; Isolate the transfer bits

	 cmp	 al,@TRANS0B_WR shl $TRANS0B ; Check for write transfer
	 jne	 short CHECK_DMA_LOOP ; Jump if not

	 call	 CHECK_TERM	; See if any DMA on channel EBX has terminated
				; Return with EAX = length
	 jnz	 short CHECK_DMA_LOOP ; Not yet
endif				; IFE DMA_STAT

; Copy all of the remaining bytes of the data from
; DTE_DMA to DMA_PTR for channel EBX, and clear that bit from DMA_CHAN

	 call	 DMA_COPYALL	; Copy it all
				; ES and FS clobbered
CHECK_DMA_LOOP:
ife DMA_STAT
	 pop	 eax		; Restore
endif				; IFE DMA_STAT

	 jmp	 CHECK_DMA_NEXT ; Go around again

CHECK_DMA_EXIT:
	 REGREST <ebx,eax>	; Restore
CHECK_DMA_RET:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DMA endp			; End CHECK_DMA procedure
	 NPPROC  DMA_COPYALL -- Copy All DMA Data From DTE_DMA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Copy all of the remaining bytes of the data from
DTE_DMA to DMA_PTR for channel EBX, and clear that bit from DMA_CHAN.

On entry:

EBX	 =	 DMA channel # (0-7)

ES and FS clobbered.

|

;;;;;;;; btr	 DMA_ISTATE.ELO,bx ; Clear it if set
	 btr	 DMA_CHAN.ELO,bx ; Check the bit and clear it if set
	 jnc	 short @F	; Jump if not enabled

	 REGSAVE <eax>		; Save register

	 xor	 eax,eax	; Set amount remaining to be
				; transferred into DTE_DMA (it's all there)
	 call	 DMA_COPY	; Copy it
				; Ignore return CF
				; ES and FS clobbered

	 REGREST <eax>		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DMA_COPYALL endp		; End DMA_COPYALL procedure
	 NPPROC  CHECK_PART -- Check On Partial DMA Transfers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on partial DMA transfers.

ES and FS clobbered.

|

	 REGSAVE <eax,ebx,edx>	; Save registers

; Note that only DMA writes set a bit in DMA_CHAN

	 mov	 al,DMA_CHAN	; Get outstanding channel flags
CHECK_PART_NEXT:
	 call	 NEXT_DMACHAN	; Get the next DMA channel # into EBX
	 jz	 short CHECK_PART_EXIT ; No more

if DBG_TRACE
	 push	 'P'            ; Get CHECK_PART indicator
	 call	 TRACE		; Save in trace table
endif				; IF DBG_TRACE

	 push	 ax		; Save for a moment

	 mov	 eax,-1 	; Ignore transfer for diskette unless TC

	 cmp	 bl,2		; Izit DMA channel #2 (diskette)?
	 je	 short CHECK_PART_TC ; Yes, check for TC only

	 call	 CHECK_TERM	; Return with EAX = length transferred so far
				; Ignore return ZF

	 test	 DMA_FLAG[bx],@DMA_BYTE ; Izit an 8-bit transfer?
	 jnz	 short CHECK_PART_TC ; Yes, leave the length alone

	 shl	 eax,1-0	; Convert from words to bytes
CHECK_PART_TC:
	 call	 CHECK_TC	; See if the TC bit is set for DMA channel EBX
				; If so, EAX = 0 on return
				; Otherwise, EAX unchanged

; Copy all but EAX bytes of the data from DTE_DMA to DMA_PTR for channel EBX

	 mov	 edx,DMA_BLK	; Use specified transfer size
	 call	 DMA_COPY	; Copy it
				; ES and FS clobbered
;;;;;;;; jc	 short CHECK_PART_CLEAR ; Jump if we should clear the bit

	 and	 eax,eax	; Everything there?
	 jnz	 short CHECK_PART_LOOP ; Not this time
;;;CHECK_PART_CLEAR:
	 btr	 DMA_CHAN.ELO,bx ; Clear channel EBX from DMA_CHAN
CHECK_PART_LOOP:
	 pop	 ax		; Restore

	 jmp	 short CHECK_PART_NEXT ; Go around again

CHECK_PART_EXIT:
	 REGREST <edx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PART endp 		; End CHECK_PART procedure
	 NPPROC  GET_TC -- Get TC Bits
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get TC bits for all DMA channels.

On exit:

AL	 =	 TC bits for DMA channels 0-7
ZF	 =	 1 if no in-progress channels have terminated
	 =	 0 if at least one has

|

;;;;;;;; xor	 ah,ah		; In case it's an XT
;;;;;;;;
;;;;;;;; test	 LCL_FLAG,@LCL_XT ; Izit an XT?
;;;;;;;; jnz	 short @F	; Yes, so no second controller
;;;;;;;;
;;;;;;;; in	 al,@DMA2_STAT	; Get controller #2 status
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;;
;;;;;;;; shl	 ax,8+4 	; Shift to channels 4-7 in AH
;;:
;;;;;;;; in	 al,@DMA1_STAT	; Get controller #1 status
;;;;;;;; and	 al,@NIB0	; Isolate TC bits
;;;;;;;; or	 al,ah		; Include channels 4-7
;;;;;;;; or	 al,DMA_ISTATE	; Include previous internal state TC bits
;;;;;;;; mov	 DMA_ISTATE,0	; Clear 'em for next time
;;;;;;;; or	 DMA_USTATE,al	; Include as user state TC bits
;;;;;;;;
;;;;;;;; and	 al,DMA_CHAN	; Check against outstanding requests
;;;;;;;;			; and set ZF accordingly

	 REGSAVE <bx,dx,si>	; Save registers

	 movzx	 si,DMA_CHAN	; Get DMA channels in progress
GET_TC_NEXT:
	 bsf	 bx,si		; Get bit index into BX
	 jz	 short GET_TC_EXIT ; Jump if no more (note ZF=0)

	 btr	 si,bx		; Clear the bit for next time

	 movzx	 dx,DMA_ICNT[bx] ; Get DMA channel count address

	 in	 al,dx		; Get 1st count byte
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 in	 al,dx		; Get 2nd count byte
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 inc	 ax		; Check for -1
	 jnz	 short GET_TC_NEXT ; Not this time

	 bts	 ax,bx		; Set the bit
	 inc	 bx		; Ensure ZF=0
GET_TC_EXIT:
	 REGREST <si,dx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_TC	 endp			; End GET_TC procedure
	 NPPROC  CHECK_TC -- Check TC Bits
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check the TC bits for DMA channel EBX

On entry:

EBX	 =	 DMA channel #

On exit:

EAX	 =	 0 if DMA channel # EBX has reached TC
	 =	 unchanged otherwise

|

	 REGSAVE <ecx>		; Save register

	 mov	 ecx,eax	; Save original value

	 call	 GET_TC 	; Get TC bits into AL
	 jz	 short CHECK_TC_EXIT ; No channels terminated

	 bt	 ax,bx		; Check the value
	 jnc	 short CHECK_TC_EXIT ; Not this time

	 xor	 ecx,ecx	; Ensure zero
CHECK_TC_EXIT:
	 mov	 eax,ecx	; Pass back to caller

	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TC endp			; End CHECK_TC procedure
	 NPPROC  NEXT_DMACHAN -- Get Next DMA Channel
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next DMA channel

On entry:

AL	 =	 DMA channels in service

On exit:

ZF	 =	 1 if no more channels
	 =	 0 otherwise
AL	 =	 updated
EBX	 =	 next DMA channel (0-7)

|

	 xor	 ah,ah		; Zero to use as word
	 movzx	 ebx,bx 	; Zero upper word

	 bsf	 bx,ax		; Put channel # into BX
	 jz	 short @F	; No more (note ZF=1)
				; At least one (note ZF=0)
; Clear bit BX from AL

	 btr	 ax,bx		; Test and reset the bit
				; Note ZF=0 still
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEXT_DMACHAN endp		; End NEXT_DMACHAN procedure
	 NPPROC  DMA_COPY -- Copy Data to User's Buffer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Copy the data from DTE_DMA to DMA_PTR

On entry:

EAX	 =	 amount remaining to be transferred into DTE_DMA
EBX	 =	 DMA channel # (0-7)
EDX	 =	 maximum size for this transfer (undefined if EAX=0)

On exit:

CF	 =	 1 if we should clear channel bit
	 =	 0 if not

ES, FS clobbered

|

	 cld			; String ops forwardly

	 REGSAVE <ecx,esi,edi>	; Save registers

; Display amount remaining in transfer

if DBG_TRACE
	 xchg	 al,ah		; Swap 'em to display high-order byte first

	 push	 ax		; Get high-order byte of transfer size
	 call	 TRACE		; Save in trace table

	 xchg	 al,ah		; Swap 'em to display low-order byte next

	 push	 ax		; Get low-order ...
	 call	 TRACE		; Save in trace table
endif				; IF DBG_TRACE

	 mov	 ecx,DMA_LEN[ebx*4] ; Get total requested transfer length
	 mov	 edi,DMA_PTR[ebx*4] ; Get the destin linear address
	 and	 edi,(4*1024)-1 ; Round down to 4KB boundary
	 add	 edi,DMA_D2M	; Plus device-to-memory linear address
	 mov	 esi,DMA_MVD[ebx*4] ; Get amount already moved to DMA_PTR
	 add	 edi,esi	; Skip over it in destination address

	 sub	 ecx,eax	; Less amount remaining to be transferred
				; yields amount in DTE_DMA
	 jbe	 near ptr DMA_COPY_EXIT ; Jump if nothing to transfer

	 sub	 ecx,esi	; Reduce amount in DTE_DMA
				; by amount already moved
	 jbe	 short DMA_COPY_EXIT ; Jump if nothing to transfer

	 and	 eax,eax	; Check for zero
	 jz	 short @F	; Ignore EDX for full transfer

; Use smaller of that and maximum transfer size in EDX

	 cmp	 ecx,edx	; Check 'em
	 jbe	 short @F	; Use actual value

	 mov	 ecx,edx	; Use maximum value
@@:
	 add	 DMA_MVD[ebx*4],ecx ; Save for the next time

if DBG_TRACE
	 xchg	 cl,ch		; Swap 'em to display high-order byte first

	 push	 cx		; Get high-order byte of transfer size
	 call	 TRACE		; Save in trace table

	 xchg	 cl,ch		; Swap 'em to display low-order byte next

	 push	 cx		; Get low-order ...
	 call	 TRACE		; Save in trace table
endif				; IF DBG_TRACE

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

	 test	 DMA_FLAG[bx],@DMA_1MB ; Need disabling?
	 jz	 short @F	; Not this time

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap
@@:

; Copy values from DTE_DMA to memory

; Registers used by DMA_ROM

; EDI = linear address of transfer
; ECX = transfer length in bytes

;;;;;;;; call	 DMA_ROM	; Ensure we're not DMAing into ROM

	 push	 DTE_D4GB	; Get all memory data selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 add	 esi,DMA_LA	; Plus our DMA buffer base address

	 or	 GLB_FLAG,@GLB_DMA ; Mark as DMA transfer in progress

; If we choose to enable interrupts here, modify all calls to
; CHECK_PART to save LAST_INTCOM

;;;;;;;; sti			; Allow interrupts

	 push	 ecx		; Save for a moment

	 shr	 ecx,2-0	; Convert from bytes to dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move them dwords

	 pop	 ecx		; Restore

	 and	 ecx,11b	; Isolate remainder modulo 4

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move them bytes

;;;;;;;; cli			; Disallow interrupts

	 and	 GLB_FLAG,not @GLB_DMA ; Reset DMA flag

	 test	 DMA_FLAG[bx],@DMA_1MB ; Need enabling?
	 jz	 short DMA_COPY_CLC ; Not this time

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap
DMA_COPY_CLC:
	 clc			; Indicate all went well
DMA_COPY_EXIT:
	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DMA_COPY endp			; End DMA_COPY procedure
;;;	     NPPROC  DMA_ROM -- Handle DMA Into ROM
;;;	     assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Ensure we're not DMAing into ROM
;;; If we are, mark the page as not present so our INT 0Eh handle will
;;; swap the PTEs with ROM
;;;
;;; Too bad we can't use the protection afforded to user-level
;;; programs by $PTE_RW; that bit isn't checked in supervisor mode
;;;
;;; On entry:
;;;
;;; EDI      =	     linear address of transfer
;;; ECX      =	     transfer length in bytes
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ecx,esi>  ; Save for a moment
;;;
;;;	     mov     esi,edi	    ; Copy base address
;;;	     and     si,mask $PTE_FRM ; Round down to 4KB boundary (multiple of 4KB)
;;;	     shr     esi,(12-2)-0   ; Convert from bytes to 4KB in dwords
;;;
;;;	     add     ecx,edi	    ; Plus starting address
;;;	     dec     ecx	    ; Convert from length to limit
;;;	     shr     ecx,(12-2)-0   ; Convert from bytes to 4KB in dwords
;;;
;;;	     sub     cx,si	    ; Less starting value
;;;	     sar     cx,2	    ; Divide by four to get count-1
;;;	     inc     cx 	    ; CX has # 4KB pages to check
;;; DMA_ROM_NEXT:
;;;	     lods    OFFPDT[si]     ; Get next PTE into EAX
;;;
;;;	     test    ax,mask $PTE_RW ; Izit read/write?
;;;	     jnz     short @F	    ; Yes
;;;
;;;	     and     OFFPDT[si-4],not (mask $PTE_P) ; Mark as not present
;;; @@:
;;;	     loop    DMA_ROM_NEXT   ; Jump if more PTEs to check
;;;
;;;	     REGREST <esi,ecx,eax>  ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; DMA_ROM  endp		    ; End DMA_ROM procedure
	 NPPROC  CHECK_TERM -- Check on DMA Terminations
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on DMA termination for channel EBX.
Note that because we can't latch the contents
of the count registers, we must read them two
or more times until the value stabilizes.

On entry:

EBX	 =	 DMA channel # (0-7)

On exit:

EAX	 =	 current length
ZF	 =	 1 if channel has terminated
	 =	 0 if not

|

	 REGSAVE <cx,dx>	; Save registers

;;;;;;;; test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
;;;;;;;; jz	 short CHECK_TERM_XMCA ; No
;;;;;;;;
;;;;;;;; mov	 al,bl		; Copy channel #
;;;;;;;; or	 al,@DMA3_RCNT	; Transfer count read function
;;;;;;;;
;;;;;;;; out	 @DMA3_CMD,al	; Tell the DMA controller about it
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;;
;;;;;;;; mov	 dx,@DMA3_DATA	; DMA data register
;;;;;;;;
;;;;;;;; jmp	 short CHECK_TERM_COM ; Join common code
;;;;;;;;
;;;CK_TERM_XMCA:
;;;	 movzx	 dx,DMA_FLIP[bx] ; Get I/O port address for flip-flop
;;;
;;;	 out	 dx,al		; Set the flip-flop
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ

	 movzx	 dx,DMA_ICNT[bx] ; Get I/O port address for count
;;;CK_TERM_COM:
	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to usual order
CHECK_TERM_AGAIN:
	 mov	 cx,ax		; Save as previous value

	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to usual order

	 cmp	 ah,ch		; Same high-order byte as last time?
	 jne	 short CHECK_TERM_AGAIN ; No, so go around again

	 inc	 ax		; Reached terminal count (-1)?
	 movzx	 eax,ax 	; Zero high-order word

; Return with ZF set if terminated, clear if not

	 REGREST <dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TERM endp 		; End CHECK_TERM procedure
;;;	     NPPROC  DMA_WAIT -- Wait For DMA To Complete
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Wait for DMA to complete.
;;;
;;; This routine should be called for all EMS page maps as we might be
;;; mapping a new EMS page onto an area into which a DMA device-to-memory
;;; transfer is still active.
;;;
;;; |
;;;
;;;	     push    ax 	    ; Save for a moment
;;;
;;;	     mov     al,DMA_CHAN    ; Get active DMA channel bits
;;;
;;;	     and     al,not @BIT2   ; Disregard DMA channel #2 (diskette)
;;;				    ; because it might "stick" because of
;;;				    ; "Drive not ready"
;;;	     jz      short DMA_WAIT_EXIT ; Nothing outstanding
;;;
;;;	     REGSAVE <es,fs>	    ; Save registers
;;; DMA_WAIT_NEXT:
;;;	     mov     al,DMA_CHAN    ; Get active DMA channel bits
;;;
;;;	     and     al,not @BIT2   ; Disregard DMA channel #2 (diskette)
;;;				    ; because it might "stick" because of
;;;				    ; "Drive not ready"
;;;	     jz      short DMA_WAIT_EXIT0 ; Nothing outstanding
;;;
;;;	     call    CHECK_PART     ; Check on partial DMA transfers in progress
;;;				    ; ES and FS clobbered
;;;	     jmp     short DMA_WAIT_NEXT ; Go around again
;;;
;;; DMA_WAIT_EXIT0:
;;;	     REGREST <fs,es>	    ; Restore
;;; DMA_WAIT_EXIT:
;;;	     pop     ax 	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; DMA_WAIT endp		    ; End DMA_WAIT procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_DMA

	 MEND			; End QMAX_DMA module
