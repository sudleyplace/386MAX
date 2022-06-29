;' $Header:   P:/PVCS/MAX/QUILIB/INT9HOOK.ASV   1.1   30 May 1997 12:09:02   BOB  $
	 title	 INT9HOOK   ; Interrupt 9 (keyboard) hook
	 page	 58,122
	 name	 INT9HOOK
COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

|
	.MODEL	LARGE,PASCAL

	.DATA

buf	db	64 dup(?)	; Data buffer
inptr	dw	0		; In pointer
outptr	dw	0		; Out pointer

their_int9 dd	0		; Original INT 9 vector

	.CODE

SET_HOOK9 proc
	mov	ax,3509h	; Get current INT 9 vector
	int	21h
	mov	word ptr their_int9,bx
	mov	word ptr their_int9+2,es

	push	ds
	mov	dx,offset our_int9
	push	cs
	pop	ds
	mov	ax,2509h	; Install our INT 9 handler
	cli			; No interrupts while we do this
	int	21h
	sti
	pop	ds
	ret

our_int9:
	push	ds		; Save registers
	push	bx
	push	ax
	mov	bx,seg DGROUP
	mov	ds,bx		; Set up our DS
	in	al,60h		; Read keyboard port
	mov	bx,offset buf	; Point at buffer
	add	bx,inptr	; Indexed by in pointer
	mov	[bx],al
	inc	inptr		; Bump inptr
	and	inptr,2fh	; mod 64
	pushf			; Fake an interrupt call
	call	their_int9	; Call the original interrupt handler
	pop	ax
	pop	bx		; Restore registers
	pop	ds
	iret			; and return

SET_HOOK9 endp

CLR_HOOK9 proc
	push	ds
	lds	dx,their_int9
	mov	ax,2509h	; Install our INT 9 handler
	cli			; No interrupts while we do this
	int	21h
	sti
	pop	ds
	ret
CLR_HOOK9 endp

GET_CODE9 proc
	mov	bx,offset buf	; Point at buffer
	mov	ax,outptr	; Pick up out pointer
	add	bx,ax		; Index into buffer
	cmp	ax,inptr	; Compare in with out
	mov	ax,-1		; Prep for neg return
	jz	@F		; Jump if buffer empty
	mov	al,[bx] 	; Pick up code
	inc	outptr		; Bump pointer
	and	outptr,2Fh	; mod 64
	mov	ah,0		; Make byte into word
@@:
	ret			; and return

GET_CODE9 endp

	end
