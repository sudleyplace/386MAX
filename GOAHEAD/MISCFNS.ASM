.386
	include MASM.INC
	include PTR.INC
	include ASCII.INC

	include MISCFNS.INC

_TEXT	segment use16 byte public 'CODE' ; Start _TEXT segment
	assume	cs:_TEXT

	NPPROC	UpperCase -- Convert AL To Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to uppercase

On entry:

AL	=	char to convert

On exit:

AL	=	converted char

|

	cmp	al,'a'          ; Izit below lowest lowercase?
	jb	short @F	; Jump if so

	cmp	al,'z'          ; Izit above highest lowercase?
	ja	short @F	; Jump if so

	add	al,'A'-'a'      ; Convert to uppercase
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UpperCase endp			; End UpperCase procedure
	NPPROC	SkipWhite -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

ES:DI	==>	command line

On exit:

ES:DI	==>	(updated)

|

	REGSAVE <ax>		; Save for a moment

	xchg	si,di		; Swap with source register
@@:
	lods	es:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Yes, go around again

	cmp	al,TAB		; Izit white space?
	je	short @B	; Yes, go around again

	dec	si		; Back off to previous character
	xchg	di,si		; Restore

	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipWhite endp			; End SkipWhite procedure
	NPPROC	SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	==>	command line

On exit:

AL	=	non-white space character
DS:SI	==>	(updated)

|

@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Yes, go around again

	cmp	al,TAB		; Izit white space?
	je	short @B	; Yes, go around again

	dec	si		; Back off to previous character

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	SKIP_BLACK -- Skip Over Non-White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over non-white space and return the last
character in AL.

On entry:

DS:SI	==>	command line

On exit:

DS:SI	==>	command line (updated)
AL	=	lower case last character

|

@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,0		; Are we at the end of the line?
	je	short @F	; Yes, we are done, exit

	cmp	al,' '          ; Check for blank
	je	short @F	; We are done, exit

	cmp	al,TAB		; Check for TAB
	jne	short @B	; No, check next char
@@:
	dec	si		; Back off to previous character

	ret			; Return to caller with next byte in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_BLACK endp 		; End SKIP_BLACK procedure
	NPPROC	DD2DEC -- Convert (DX,AX) To Decimal At ES:DI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert (DX,AX) to decimal at ES:DI.

On entry:

(DX,AX) =	# to convert
ES:DI	==>	units digit of save area

On exit:

ES:DI	==>	next available byte

|

DD2DEC_STR struc

DD2DEC_VEC dd	?		; Address of caller's buffer if left-justified
DD2DEC_BUF db	13 dup (?)	; Local buffer big enough to handle
				; 4G with commas (4,xxx,xxx,xxx)
	dw	?		; Caller's BP
	dw	?		;	   IP
DD2DEC_FLG dw	?		; Flags

DD2DEC_STR ends

@DD2DEC_SIZE equ (size DD2DEC_STR)-6 ; Size of local stack in bytes

	push	bp		; Prepare to address the stack
	sub	sp,@DD2DEC_SIZE ; Make room on stack
	mov	bp,sp		; Hello, Mr. Stack

	pushf			; Save flags

	REGSAVE <ax,bx,cx,dx,si,es> ; Save registers

	test	[bp].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

	mov	[bp].DD2DEC_VEC.VOFF,di ; Save address of caller's buffer
	mov	[bp].DD2DEC_VEC.VSEG,es ; ...

	push	ss		; Setup ES for string operations
	pop	es		; Address it
	assume	es:nothing	; Tell the assembler about it

	lea	di,[bp].DD2DEC_BUF[(size DD2DEC_BUF)-1] ; ES:DI ==> buffer end
@@:
	xor	cx,cx		; Initialize byte count
	std			; String ops backwards
DD2DEC_COMMA:
	xor	si,si		; Initialize comma count
DD2DEC_NEXT:
	call	DD2DEC_DIG	; Split off another decimal digit from (DX,AX)
				; (DX,AX) = quotient
				; BL	  = remainder
	xchg	al,bl		; Swap to display AL
	add	al,'0'          ; Convert to decimal ASCII
	stos	es:[di].LO	; Save in local buffer
	inc	cx		; Account for it
	mov	al,bl		; Restore

	mov	bx,dx		; Copy high-order of quotient
	or	bx,ax		; Check the remainder
	jz	short DD2DEC_END ; Jump if that's all

	test	[bp].DD2DEC_FLG,@DEC_COMMA ; Comma insertion requested?
	jz	short DD2DEC_NEXT ; Not this time

	inc	si		; Account for it

	cmp	si,3		; Izit time to comma-insert?
	jne	short DD2DEC_NEXT ; Not as yet

	push	ax		; Save for a moment
	mov	al,@NATL_THOU	; Separator
	stos	es:[di].LO	; Save in buffer
	pop	ax		; Restore

	inc	cx		; Account for it

	jmp	DD2DEC_COMMA	; Go around again

DD2DEC_END:
	lea	si,[di+1]	; SS:SI ==> start of buffer
	add	di,cx		; Skip to next available byte in
				; case not left-justified
	test	[bp].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short DD2DEC_XLJ ; Not this time

	les	di,[bp].DD2DEC_VEC ; ES:DI ==> caller's buffer
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
    rep movs	es:[di].LO,ss:[si].LO ; Move into caller's data area
DD2DEC_XLJ:
	REGREST <es,si,dx,cx,bx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	popf			; Restore flags

	add	sp,@DD2DEC_SIZE ; Remove room from stack
	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2DEC	endp			; End DD2DEC procedure
	NPPROC	DD2DEC_DIG -- Subroutine to DD2DEC
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide by 10

On entry:

(DX,AX) =	dividend

On exit:

(DX,AX) =	quotient
BL	=	remainder

|

	REGSAVE <cx>		; Save register

	mov	cx,10		; Divisor

	push	ax		; Save low-order word

	mov	ax,dx		; Copy high-order to low-order word
	xor	dx,dx		; Zero high-order word
	div	cx		; Strip off a decimal digit
				; AX = quotient
				; DX = remainder < 10
	mov	bx,ax		; Save quotient as high-order result

	pop	ax		; Restore low-order word

	div	cx		; Strip off a decimal digit
				; AX = quotient
				; DX = remainder < 10
	xchg	dx,bx		; Swap new high-order result and remainder

	REGREST <cx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2DEC_DIG endp 		; End DD2DEC_DIG procedure

_TEXT	ends			; End _TEXT segment

	END			; End MISCFNS Module
