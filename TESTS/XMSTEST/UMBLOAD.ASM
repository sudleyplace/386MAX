;' $Header:   P:/PVCS/MISC/XMSTEST/UMBLOAD.ASV   1.1   06 Aug 1992 13:17:54   HENRY  $

	 title	 UMBLOAD -- UMB Load Tester
	 page	 58,122
	 name	 UMBLOAD
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.286c
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include HMA.INC
	 include XMS.INC
	 include KEYCALL.INC

	 include QMAX_CTL.INC
.list

PGROUP	 group	 STACK,CODE,DATA

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Address of XMS driver controller

	 public  UMBSEG1
UMBSEG1  dw	 ?		; UMB segment #1

	 public  BASNAM1,BASNAM2
BASNAM1  db	 "MOVE'EM$",0   ; Base device driver name for MOVE'EM
BASNAM2  db	 "386MAX$$",0   ; ...                         386MAX

	 public  INFO_CTL
INFO_CTL db	 ?		; INFO control byte

	 public  MSG_COPY
MSG_COPY db	 'UMBLOAD  -- Version 1.00'
;;;;;;;; db	 VERS_H,'.',VERS_T,VERS_U
	 db	 ' (C) Copyright 1988 Qualitas, Inc.',CR,LF,EOS

	 public  XLAT_TAB
XLAT_TAB db	 '0123456789ABCDEF'

	 public  LCLSTK,LCLSTKZ
	 even
LCLSTK	 dw	 256 dup (?)	; Local stack
LCLSTKZ  dw	 0		; End of the stack

DATA	 ends			; End DATA segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  UMBLOAD -- UMB Load Tester
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

; Switch to local stack

	 lea	 sp,LCLSTKZ

; Display our copyright notice

	 DOSCALL @STROUT,MSG_COPY

; Check for presence

	 mov	 ax,4300h	; Function to determine presence
	 int	 2Fh		; Request redirector service

	 cmp	 al,80h 	; Check for presence
	MJ ne	 UMBLOAD_ERR	; Jump if not present

; Request driver control address

	 push	 es		; Save for a moment

	 mov	 ax,4310h	; Function to get address
	 int	 2Fh		; Request redirector service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Turn load state on

;;;;;;;; call	 INFO_LON	; Turn load state on

; Find size of largest UMB

	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 mov	 dx,-1		; Impossible value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	MJ e	 UMBLOAD_ERR	; Jump if something went wrong

	 cmp	 bl,0B0h	; Check error code
	 je	 short @F	; Jump if UMBs supported

	 cmp	 bl,80h 	; Check error code
	MJ e	 UMBLOAD_EXIT	; Jump if function not implemented

	 cmp	 bl,0B1h	; Check error code
	MJ ne	 UMBLOAD_ERR	; Jump if something went wrong

	 jmp	 UMBLOAD_EXIT	; Jump if no UMBs available

@@:

; Allocate a UMB of size DX

	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	MJ ne	 UMBLOAD_ERR	; Jump if something went wrong

	 mov	 UMBSEG1,bx	; Save for later use

; Release UMB #1

	 mov	 ah,@XMS_RELUMB ; Function to release Upper Memory Block
	 mov	 dx,UMBSEG1	; Segment # to release
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 jne	 short UMBLOAD_ERR ; Jump if we didn't






UMBLOAD_ERR:
UMBLOAD_EXIT:

; Turn load state off

;;;;;;;; call	 INFO_LOFF	; Turn load state off

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UMBLOAD  endp			; End UMBLOAD procedure
;;;	    NPPROC  INFO_LON -- Turn On Load State
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;	    REGSAVE <ax,bx,cx,dx,ds> ; Save registers
;;;
;;;	    push    cs		   ; Setup for data references
;;;	    pop     ds		   ; Address it
;;;	    assume  ds:PGROUP	   ; Tell the assembler about it
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAM1 ; Attempt to open base program device driver
;;;	    jnc     short INFO_LON1 ; Jump if found
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAM2 ; Attempt to open base program device driver
;;;	    jc	    short @F	   ; Jump if not found
;;;INFO_LON1:
;;;	    mov     bx,ax	   ; Copy to handle register
;;;
;;;	    mov     al,03h	   ; Write to device
;;;	    mov     cx,1	   ; CX = # bytes in INFO structure
;;;	    mov     INFO_CTL,@CTL_LON ; Mark as load state on
;;;	    DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO
;;;
;;;	    DOSCALL @CLOSF2	   ; Close it up
;;;@@:
;;;	    REGREST <ds,dx,cx,bx,ax> ; Restore
;;;	    assume  ds:nothing	   ; Tell the assembler about it
;;;
;;;	    ret 		   ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;INFO_LON endp		   ; End INFO_LON procedure
;;;	    NPPROC  INFO_LOFF -- Turn Off Load State
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;	    REGSAVE <ax,bx,cx,dx,ds> ; Save registers
;;;
;;;	    push    cs		   ; Setup for data references
;;;	    pop     ds		   ; Address it
;;;	    assume  ds:PGROUP	   ; Tell the assembler about it
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAM1 ; Attempt to open base program device driver
;;;	    jnc     short INFO_LOFF1 ; Jump if found
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAM2 ; Attempt to open base program device driver
;;;	    jc	    short @F	   ; Jump if not found
;;;INFO_LOFF1:
;;;	    mov     bx,ax	   ; Copy to handle register
;;;
;;;	    mov     al,03h	   ; Write to device
;;;	    mov     cx,1	   ; CX = # bytes in INFO structure
;;;	    mov     INFO_CTL,@CTL_LOFF ; Mark as load state off
;;;	    DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO
;;;
;;;	    DOSCALL @CLOSF2	   ; Close it up
;;;@@:
;;;	    REGREST <ds,dx,cx,bx,ax> ; Restore
;;;	    assume  ds:nothing	   ; Tell the assembler about it
;;;
;;;	    ret 		   ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;INFO_LOFF endp		   ; End INFO_LOFF procedure

CODE	 ends			; End CODE segment

	 MEND	 UMBLOAD	; End UMBLOAD module
