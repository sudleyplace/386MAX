;' $Header:   P:/PVCS/MAX/GOAHEAD/STRFNS.ASV   1.2   19 Jan 1996 17:27:32   BOB  $
; ASM version of common string functions
.386
	include MASM.INC
	include PTR.INC

_TEXT	segment use16 byte public 'CODE' ; Start _TEXT segment
	assume	cs:_TEXT

	extrn	UpperCase:near

	NPPROC	StrNCpy -- String Copy With Specific Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy with specific length

On exit:

AX	=	actual length copied

|

StrNCpy_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrNCpyLen dw	?		; Maximum copy length
StrNCpySrc dd	?		; Ptr to source
StrNCpyDst dd	?		; ...	 destin

StrNCpy_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <cx,si,di,ds,es> ; Save registers

	mov	cx,[bp].StrNCpyLen ; Get length to copy
	jcxz	StrNCpyExit	; Jump if string empty

	lds	si,[bp].StrNCpySrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].StrNCpyDst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
@@:
	lods	ds:[si].LO	; Get next char
	stos	es:[di].LO	; Save it back

	cmp	al,0		; Izit EOS?
	loopne	@B		; Jump if not and more chars
StrNCpyExit:
	mov	ax,[bp].StrNCpyLen ; Get length to copy
	sub	ax,cx		; Less length remaining

	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNCpy endp			; End StrNCpy procedure
	NPPROC	StrCpy -- String Copy
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy

|

StrCpy_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrCpySrc dd	?		; Ptr to source
StrCpyDst dd	?		; ...	 destin

StrCpy_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,si,di,ds,es> ; Save registers

	lds	si,[bp].StrCpySrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].StrCpyDst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
@@:
	lods	ds:[si].LO	; Get next char
	stos	es:[di].LO	; Save it back

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	REGREST <es,ds,di,si,ax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrCpy	endp			; End StrCpy procedure
	NPPROC	StrICmp -- String Compare, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, case insensitive

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

StrICmp_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrICmpArg2 dd	?		; Ptr to Arg #2
StrICmpArg1 dd	?		; ...	     #1

StrICmp_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <si,di,ds,es>	; Save registers

	lds	si,[bp].StrICmpArg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].StrICmpArg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it
StrICmpNext:
	mov	ah,ds:[si]	; Get next Arg #2 char
	mov	al,es:[di]	; ...	       #1 ...
	inc	si		; Skip over it
	inc	di		; ...

	and	ax,ax		; Izit EOS?
	jz	short StrICmpExit ; Jump if so with AX=0

; Check for case-sensitivity

	xchg	al,ah		; Put Arg #2 char in AL for UpperCase
	call	UpperCase	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UpperCase	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	jz	short StrICmpNext ; Jump if same
StrICmpExit:
	REGREST <es,ds,di,si>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrICmp endp			; End StrICmp procedure
	NPPROC	StrNICmp -- String Compare, Length Sensitive, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, length sensitive, case insensitive

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

StrNICmp_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrNICmpLen dw	?		; Maximum compare length
StrNICmpArg2 dd ?		; Ptr to Arg #2
StrNICmpArg1 dd ?		; ...	     #1

StrNICmp_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <cx,si,di,ds,es> ; Save registers

	lds	si,[bp].StrNICmpArg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].StrNICmpArg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it

	mov	cx,[bp].StrNICmpLen ; Get maximum compare length
	mov	ax,cx		; Copy as result in case empty
	jcxz	StrNICmpExit	; Jump if so with AX=0
StrNICmpNext:
	mov	ah,ds:[si]	; Get next Arg #2 char
	mov	al,es:[di]	; ...	       #1 ...
	inc	si		; Skip over it
	inc	di		; ...

	and	ax,ax		; Izit EOS?
	jz	short StrNICmpExit ; Jump if so with AX=0

; Check for case-sensitivity

	xchg	al,ah		; Put Arg #2 char in AL for UpperCase
	call	UpperCase	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UpperCase	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	loopz	short StrNICmpNext ; Jump if same and more chars to compare
StrNICmpExit:
	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNICmp endp			; End StrNICmp procedure
	NPPROC	StrLen -- String Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length

On exit:

AX	=	length

|

StrLen_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrLenSrc dd	?		; Ptr to source

StrLen_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <cx,di,es>	; Save registers

	les	di,[bp].StrCpySrc ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	al,0		; Search for this
	mov	cx,-1		; We know (or hope) it's there
  repne scas	es:[di].LO	; Search for it

	mov	ax,-(1+1)	; One for starting -1, one for trailing zero
	sub	ax,cx		; Subtract to get length

	REGREST <es,di,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLen	endp			; End StrLen procedure
	NPPROC	StrChr -- String Character Search
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String character search

On exit:

DX:AX	==>	matching character
	=	0:0 if none

|

StrChr_str struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
StrChrChr db	?,?		; Character to search for
StrChrSrc dd	?		; Ptr to source

StrChr_str ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <si,ds> 	; Save registers

	lds	si,[bp].StrChrSrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	mov	ah,[bp].StrChrChr ; Get character

	cld			; String ops forwards
@@:
	lods	ds:[si].LO	; Get next char

	cmp	al,ah		; Izit a match?
	je	short StrChrFound ; Jump if so

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	xor	ax,ax		; Mark as not found
	xor	dx,dx		; ...

	jmp	short StrChrExit ; Join common exit code

StrChrFound:
	lea	ax,[si-1]	; Back off to matching char
	mov	dx,ds		; DX:AX ==> matching char
StrChrExit:
	REGREST <ds,si> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	4+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrChr	endp			; End StrChr procedure

_TEXT	ends			; End _TEXT segment

	end			; End STRFNS Module
