;' $Header:   P:/PVCS/MAX/386LOAD/MACFNS.ASV   1.1   30 May 1997 10:38:08   BOB  $
	 title	 MACFNS -- Memory Allocation Functions
	 page	 58,122
	 name	 MACFNS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOS.INC
	 include MAC.INC
	 include DOSERR.INC
.list

PGROUP	 group	 NCODE,NDATA,DTAIL


NDATA	 segment dword public 'ndata' ; Start DATA segment
	 assume  ds:PGROUP

	 public  MACLOC
MACLOC	 db	 ?		; MAC location fit

	 public  MACALG
MACALG	 db	 ?		; MAC algorithm:
				; 0 = first fit
				; 1 = best  fit
				; 2 = last  fit

NDATA	 ends			; End NDATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word

DTAIL	 ends			; End DTAIL segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 MAC_MERGE:near

	 NPPROC  FIND_OWNER -- Find Owner Of Segment
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Find the owner of a given segment

On entry:

DI	 =	 segment

On exit:

CF	 =	 0 all went OK
DI	 =	 owner

CF	 =	 1 something went wrong
AX	 =	 error code

|

	 REGSAVE <es>		; Save register

	 mov	 es,POVR_MAC	; Get segment of first MAC in high DOS memory
	 assume  es:nothing	; Tell the assembler about it
FIND_OWNER_NEXT:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid
	 je	 short FIND_OWNER_CHK ; It's OK

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short FIND_OWNER_ERRMAC ; It's not, so that's an error
FIND_OWNER_CHK:
	 mov	 ax,es		; Get current MAC segment

	 cmp	 di,ax		; Check for range
	 jb	 short FIND_OWNER_ERRFND ; Too small, we passed it???

	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 cmp	 di,ax		; Check for range
	 jb	 short FIND_OWNER_CLC ; We found it

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 short FIND_OWNER_NEXT ; Go around again

FIND_OWNER_ERRFND:
	 mov	 ax,@DOSERR_MNF ; Mark as invalid MAC address

	 jmp	 short FIND_OWNER_ERRCOM ; Join common error code

FIND_OWNER_ERRMAC:
	 mov	 ax,@DOSERR_XMAC ; Mark as control blocks destroyed
FIND_OWNER_ERRCOM:
	 stc			; Indicate something went wrong

	 jmp	 short FIND_OWNER_EXIT ; Join common exit code

FIND_OWNER_CLC:
	 mov	 di,es:[0].MAC_OWNR ; Return the owner of that entry

	 clc			; Indicate we found it
FIND_OWNER_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_OWNER endp 		; End FIND_OWNER procedure
	 NPPROC  GETMEM -- Allocate Memory
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Allocate memory.

Sensitive to MACLOC and MACALG.

On entry:

DI	 =	 segment of owner
BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX:0	 ==>	 allocated block (not MAC entry)

CF	 =	 1 if not successful
AX	 =	 error codes
BX	 =	 size of largest available block

|

	 REGSAVE <cx,es>	; Save registers

	 call	 GETMEM_SRCH	; Search for at least BX paras of free memory
				; returning AX = MAC entry, CX = region #
	 jc	 short GETMEM_EXIT ; Jump if error, code in AX

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 call	 GETMEM_SUB	; Allocate BX paras from MAC at ES:0
				; returning AX = MAC entry
	 jc	 short GETMEM_EXIT ; Jump if error, code in AX

	 mov	 es:[0].MAC_OWNR,di ; Save owner segment

	 inc	 ax		; Skip over MAC entry

	 clc			; Indicate all went well
GETMEM_EXIT:
	 REGREST <es,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETMEM	 endp			; End GETMEM procedure
	 NPPROC  GETMEM_SRCH -- Search for Allocatable Memory
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Search for allocatable memory.
This routine doesn't actually allocate the memory, it just
ensures that there is a region in which it can be allocated.

Sensitive to MACLOC and MACALG.

On entry:

BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX:0	 ==>	 MAC entry of allocatable block
CX	 =	 region #

CF	 =	 1 if not successful
AX	 =	 error codes
BX	 =	 size of largest available block
CX	 =	 destroyed

|

	 REGSAVE <dx,si,di,es>	; Save registers

	 push	 bx		; Save separately

	 mov	 cx,1		; Initialize region #
	 xor	 dx,dx		; Initialize size of largest block so far
	 mov	 di,-1		; Initialize size of best fit so far

	 mov	 es,POVR_MAC	; Get segment of first MAC in high DOS memory
	 assume  es:nothing	; Tell the assembler about it
GETMEM_SRCH_NEXT:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid
	 je	 short GETMEM_SRCH_CHK ; It's OK

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short GETMEM_SRCH_ERRMAC ; It's not, so that's an error
GETMEM_SRCH_CHK:
	 mov	 ax,es:[0].MAC_OWNR ; Get owner's segment

	 cmp	 ax,@MAC_SPAN	; Izit a RAM or ROM entry?
	 jne	 short GETMEM_SRCH_CHK1 ; Not this time

	 inc	 cx		; Skip to next region

	 jmp	 short GETMEM_SRCH_LOOP ; Continue on

GETMEM_SRCH_CHK1:
	 and	 ax,ax		; Izit available?
	 jnz	 short GETMEM_SRCH_LOOP ; No, continue on

	 mov	 ax,es:[0].MAC_NPAR ; Get # paras in the block

	 cmp	 bx,ax		; Is the block large enough?
	 ja	 short GETMEM_SRCH_FREE ; No, but it's available

	 cmp	 MACALG,1	; Branch based upon MAC algorithm
	 jb	 short GETMEM_SRCH_FOUND ; First fit, take it
	 ja	 short GETMEM_SRCH_LAST ; Last fit, save it
				; Fall through for best fit

	 cmp	 di,ax		; Check against best fit so far
	 jbe	 short GETMEM_SRCH_LOOP ; The previous one was better
GETMEM_SRCH_LAST:
	 mov	 si,es		; Save segment of MAC entry
	 mov	 di,ax		; Save size of block

	 jmp	 short GETMEM_SRCH_LOOP ; Continue on

GETMEM_SRCH_FREE:
	 cmp	 dx,ax		; Put larger into DX in case we fail
	 jae	 short GETMEM_SRCH_LOOP ; A previous block is larger

	 mov	 dx,ax		; Current block is larger
GETMEM_SRCH_LOOP:
	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for the end-of-the-line
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 jne	 short GETMEM_SRCH_NEXT ; Go around again

	 inc	 di		; See if we found anything that would fit
	 jz	 short GETMEM_SRCH_ERRWSF ; No luck, not enough memory

	 mov	 es,si		; Address the segment
	 assume  es:nothing	; Tell the assembler about it
GETMEM_SRCH_FOUND:
	 mov	 ax,es		; Return segment of MAC entry

	 clc			; Indicate all went well

	 jmp	 short GETMEM_SRCH_EXIT ; Join common exit code

GETMEM_SRCH_ERRWSF:
	 mov	 ax,@DOSERR_XMEM ; Mark as insufficient memory

	 jmp	 short GETMEM_SRCH_ERRCOM ; Join common error code

GETMEM_SRCH_ERRMAC:
	 mov	 ax,@DOSERR_XMAC ; Mark as control blocks destroyed
GETMEM_SRCH_ERRCOM:
	 pop	 bx		; Restore
	 push	 dx		; Return size of largest block on error in BX

	 stc			; Indicate something went wrong
GETMEM_SRCH_EXIT:
	 pop	 bx		; Restore separately

	 REGREST <es,di,si,dx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETMEM_SRCH endp		; End GETMEM_SRCH procedure
	 NPPROC  GETMEM_SUB -- Get Memory Subroutine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Allocate BX paras from the MAC at ES:0

Sensitive to MACLOC.

On entry:

ES:0	 ==>	 MAC entry
BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX:0	 ==>	 allocated block

CF	 =	 1 if not successful
AX	 =	 error codes

|

	 REGSAVE <bx,es>	; Save registers

	 cmp	 bx,es:[0].MAC_NPAR ; Check against # available paragraphs
	 je	 short GETMEM_SUB_CLC ; Just enough, use them all
	 ja	 short GETMEM_SUB_ERRWSF ; Too large, so that's an error

	 cmp	 MACLOC,@MACLOC_HI ; Check MAC location
	 je	 short GETMEM_SUB_HIGH ; Jump if high fit

	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short GETMEM_SUB_EXIT ; Jump if error, code in AX

	 mov	 ax,es		; Return current MAC segment

	 jmp	 short GETMEM_SUB_CLC ; Join common ending code

GETMEM_SUB_HIGH:
	 sub	 bx,es:[0].MAC_NPAR ; Less # paragraphs in this entry
	 neg	 bx		; Negate to get difference
	 dec	 bx		; Count out MAC paragraph

	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short GETMEM_SUB_EXIT ; Jump if error, code in AX

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
GETMEM_SUB_CLC:
	 clc			; Indicate all went well

	 jmp	 short GETMEM_SUB_EXIT ; Join common exit code

GETMEM_SUB_ERRWSF:
	 mov	 ax,@DOSERR_XMEM ; Assume insufficient memory

	 stc			; Indicate something went wrong
GETMEM_SUB_EXIT:
	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETMEM_SUB endp 		; End GETMEM_SUB procedure
	 NPPROC  MODMEM -- Modify Memory Allocation Chain Entry
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Modify memory allocation chain entry.

On entry:

ES:0	 ==>	 MAC entry
BX	 =	 new requested size in paras

On exit:

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 error codes
BX	 =	 size of largest available block

|

	 REGSAVE <cx,dx,si,es>	; Save registers

	 cmp	 bx,es:[0].MAC_NPAR ; Check against size of current block
	 jb	 short MODMEM_SHRINK ; Too small, shrink it
	MJ e	 MODMEM_CLC	; Just right, exit

; Increase the size of the block at ES:0 to BX paras

MODMEM_GROW:

; Find the size of the largest contiguous block

	 mov	 si,es		; Save original segment

	 mov	 dx,es:[0].MAC_NPAR ; Get # paragraphs in this entry
MODMEM_NEXT:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for end-of-the-chain
	 je	 short MODMEM_CALC ; That's all folks

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid
	 je	 short MODMEM_CHK ; It's OK

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short MODMEM_ERRMAC ; It's not, so that's an error
MODMEM_CHK:
	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short MODMEM_CALC ; No, so that's the end of the line

	 add	 dx,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 inc	 dx		; Count in the MAC paragraph

	 jmp	 short MODMEM_NEXT ; Go around again

; DX has the size of the largest contiguous block

MODMEM_CALC:
	 cmp	 bx,dx		; See if there's enough room
	 ja	 short MODMEM_ERRWSF ; Not enough room

	 mov	 es,si		; Address the block
	 assume  es:nothing	; Tell the assembler about it

; Merge free entries starting at ES:0

	 mov	 si,@MAC_FREE	; A free entry
	 xchg	 si,es:[0].MAC_OWNR ; Ensure free
	 push	 es		; Merge starting at this segment
	 call	 MAC_MERGE	; Merge adjacent free MACs starting at ES:0
	 xchg	 si,es:[0].MAC_OWNR ; Restore
	 jc	 short MODMEM_ERRMAC ; Jump if MAC error

	 cmp	 bx,es:[0].MAC_NPAR ; Check against size of current block
	 je	 short MODMEM_CLC ; Just right, exit

; Shrink the block at ES:0 to BX paras

MODMEM_SHRINK:
	 mov	 ax,bx		; Copy requested size
	 xchg	 ax,es:[0].MAC_NPAR ; Swap with current size
	 sub	 ax,bx		; Less smaller size
	 dec	 ax		; Count out MAC paragraph

	 mov	 cx,es		; Copy current segment
	 inc	 cx		; Count in MAC paragraph
	 add	 cx,bx		; Plus size of block

	 push	 cx		; Save new segment

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,es:[0].MAC_TYPE ; Swap with current type

	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,cl ; Save as new type
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark as free
	 mov	 es:[0].MAC_NPAR,ax ; Save new size
MODMEM_CLC:
	 clc			; Indicate all went well

	 jmp	 short MODMEM_EXIT ; Join common exit code

MODMEM_ERRWSF:
	 mov	 ax,@DOSERR_XMEM ; Mark as insufficient memory

	 jmp	 short MODMEM_ERRCOM ; Join common error code

MODMEM_ERRMAC:
	 mov	 ax,@DOSERR_XMAC ; Mark as control blocks destroyed
MODMEM_ERRCOM:
	 mov	 bx,dx		; Return size of largest available block

	 stc			; Indicate something went wrong
MODMEM_EXIT:
	 REGREST <es,si,dx,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MODMEM	 endp			; End MODMEM procedure
	 NPPROC  MAC_FREE -- Free MAC Entries Owned By BX
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Free all MAC entries owned by BX.

On entry:

BX	 =	 owner to free
ES:0	 ==>	 starting MAC entry

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

	 REGSAVE <ax,es>	; Save registers

; Mark as free any MAC entries whose owner is BX

MAC_FREE_NEXT:
	 cmp	 bx,es:[0].MAC_OWNR ; Same as our boy?
	 jne	 short MAC_FREE_CHK ; Not this time

	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark it as free
MAC_FREE_CHK:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end of the MAC entries?
	 je	 short MAC_FREE_END ; Yes, note CF=0

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short MAC_FREE_ERRMAC ; Not this time

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Account for MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 short MAC_FREE_NEXT ; Go around again

MAC_FREE_ERRMAC:
	 stc			; Indicate something went wrong
MAC_FREE_END:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MAC_FREE endp			; End MAC_FREE procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End MACFNS module
