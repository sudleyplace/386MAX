;' $Header:   P:/PVCS/MAX/QUILIB/DMALLOC.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 title	 DMALLOC -- DOS and UMB memory allocation
	 page	 58,122
	 name	 MAXSUB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Ungrouped:
	       Program segment xxx_TEXT, word-aligned,	public, class 'code'
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Link requirements:  Callable from MSC 6.

Program derived from:  None.

Original code by:  Henry Groover, July 1992.

Modifications by:  None.

|

.8086
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include PTR.INC
	 include XMS.INC
.list

%.model  &MODEL,c

.data

XMS_VEC  dd	 0		; Far entry to XMS services

.code

	 extrn	 _fmalloc:proc
	 extrn	 _frealloc:proc
	 extrn	 _ffree:proc

	 PPROC	 _dmalloc -- Allocate memory from DOS or UMB
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |
; void _far * _dmalloc (unsigned bsize)

Return a far pointer in DX:AX or NULL if no memory available.
ES, BX and CX are destroyed.

If UMB's are available, allocate'em.

|

dmalloc_str struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
bsize	 dw	 ?		; Bytes to allocate
dmalloc_str ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 bx,[bp].bsize	; Get bytes to allocate
	 push	 bx		; Put on stack for _fmalloc ()

	 cmp	 bx,0800h	; Izit less than 2K?
	 jbe	 short dmalloc_heap ; Jump if so

	 mov	 cl,4		; Convert bytes to paras
	 add	 bx,16-1	; Round up
	 shr	 bx,cl		; BX = paras to allocate

	 or	 bx,bx		; Izit valid?
	 jz	 short dmalloc_heap ; Let _fmalloc choke on it

	 ; If UMB memory can be allocated, go for it.  Note that
	 ; _drealloc and _dfree blindly try XMS services before
	 ; DOS services (then failing).  We ASSUME the XMS UMB
	 ; provider is smart enough to recognize its own entries...
	 call	 GETXMS_VEC	; Check for XMS presence
	 jc	 short dmalloc_dos ; Jump if not there

	 push	 bx		; Save paras in case we re-try with DOS call

	 mov	 ah,@XMS_GETUMB ; Allocate UMB
	 mov	 dx,bx		; Size in paras
	 call	 XMS_VEC	; AX=1/0 for success/failure, BX:0 ==> UMB
	 xchg	 bx,ax		; Put segment in AX, result in BX
	 cmp	 bx,1		; Set CF if BX=0

	 pop	 bx		; Restore paras to allocate

	 jnc	 short dmalloc_com ; Join common code if we succeeded

dmalloc_dos:
	 DOSCALL @GETMEM	; AX = new segment
	 jc	 short dmalloc_heap ; Try C heap

dmalloc_com:
	 mov	 dx,ax		; Segment
	 sub	 ax,ax		; Offset
	 jmp	 short dmalloc_exit ; Join common exit

dmalloc_heap:
	 call	 _fmalloc	; Return DX:AX ==> memory

dmalloc_exit:
	 pop	 bx		; Clean up stack

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_dmalloc	 endp		; End _dmalloc procedure

	 PPROC	 _drealloc -- Reallocate memory from DOS or UMB
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |
; void _far * _drealloc (void _far *p, unsigned newsize)

Return a far pointer in DX:AX if reallocate successful or NULL if not.
ES, BX and CX are destroyed.

|

drealloc_str struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
reallocp dd	 ?		; Far pointer to modify
newsize  dw	 ?		; Size to reallocate to

drealloc_str ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 les	 bx,[bp].reallocp ; Get pointer
	 or	 bx,bx		; Izit one of ours?
	 jnz	 short drealloc_heap ; Jump if not

	 mov	 bx,[bp].newsize ; New size in paras
	 add	 bx,16-1	; Round up
	 mov	 cl,4-0 	; Bytes to paras
	 shr	 bx,cl		; BX = new size in paras
	 cmp	 bx,1		; Izit 0?
	 adc	 bx,0		; If so, make it 1 (minimum)

	 call	 GETXMS_VEC	; Check status of XMS services
	 jc	 short drealloc_dos ; Jump if not available

	 mov	 ah,@XMS_MODUMB ; Reallocate UMB
	 mov	 dx,es		; Segment to reallocate
	 push	 bx		; Save new size
	 call	 XMS_VEC	; Reallocate DX:0 to BX paras
	 pop	 bx		; Restore new size
	 cmp	 ax,1		; Set CF if AX=0
	 je	 short drealloc_com ; Join common code (note CF=0)

drealloc_dos:
	 DOSCALL @MODMEM	; Change block at ES to BX paras
drealloc_com:
	 mov	 dx,0		; Assume failure
	 mov	 ax,dx		; AX = segment or error code
	 jc	 short drealloc_exit ; Jump if we failed

	 mov	 dx,es		; Segment (unchanged)
	 jmp	 short drealloc_exit ; Join common exit code

drealloc_heap:
	 push	 [bp].newsize	; Size to reallocate to
	 push	 [bp].reallocp.VSEG ; Segment
	 push	 [bp].reallocp.VOFF ; Offset
	 call	 _frealloc	; Reallocate block

drealloc_exit:
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_drealloc	 endp		; End _drealloc procedure

	 PPROC	 _dfree -- Free memory allocated via _dmalloc
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |
; void _dfree (void _far *fp)

If offset portion of far pointer is 0, free it via XMS UMB or DOS
services (whichever happends to succeed).  Otherwise, pass to _ffree ().

ES, BX and CX are destroyed.

|

dfree_str  struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
freep	 dd	 ?		; Far pointer to modify

dfree_str  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 les	 bx,[bp].freep	; Get pointer
	 or	 bx,bx		; Izit one of ours?
	 jnz	 short dfree_heap ; Jump if not

	 call	 GETXMS_VEC	; Check status of XMS services
	 jc	 short dfree_dos ; Jump if not available

	 mov	 ah,@XMS_RELUMB ; Release UMB
	 mov	 dx,es		; Get segment to free
	 call	 XMS_VEC	; Release BX:0
	 cmp	 ax,1		; Did we succeed?
	 je	 short dfree_exit ; Join common exit if so

dfree_dos:
	 DOSCALL @RELMEM	; Release memory block at ES:0
	 jmp	 short dfree_exit ; Join common exit

dfree_heap:
	 push	 [bp].freep.VSEG ; Segment
	 push	 [bp].freep.VOFF ; Offset
	 call	 _ffree 	; Free segment
	 add	 sp,2*2 	; Remove arguments from stack

dfree_exit:
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_dfree	 endp			; End _dfree procedure

	 NPPROC  GETXMS_VEC -- Get entry point to XMS services
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |

Check XMS_VEC.	If set, return with CF=0.  If 0, try to get XMS
entry point via Int 2f.  If failed or version does not support
UMB services, return with CF=1.

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save

	 mov	 ax,XMS_VEC.VOFF ; Get offset
	 or	 ax,XMS_VEC.VSEG ; Combine with segment
	 jnz	 short GETXMS_VEC_EXIT ; Jump if already set (note CF=0)

	 mov	 ax,4300h	; XMS presence check
	 int	 2Fh		; AL = 80h if installed
	 cmp	 al,80h 	; Are XMS services present?
	 jne	 short GETXMS_VEC_ERR ; Jump if not

	 mov	 ax,4310h	; Get driver entry point
	 int	 2Fh		; ES:BX ==> driver entry point
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es		; Get segment
	 or	 ax,bx		; Combine with offset
	 jz	 short GETXMS_VEC_ERR ; Jump if null

	 ; Note CF=0
	 mov	 XMS_VEC.VOFF,bx ; Save offset
	 mov	 XMS_VEC.VSEG,es ; ... and segment

;;;;;;	 clc			; Indicate success
	 jmp	 short GETXMS_VEC_EXIT ; Join common exit

GETXMS_VEC_ERR:
	 stc			; Indicate error
GETXMS_VEC_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETXMS_VEC endp 		; End GETXMS_VEC procedure

	 MEND			; End DMALLOC module

