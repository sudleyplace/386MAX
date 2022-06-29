;' $Header:   P:/PVCS/MAX/QMT/MEM_MISC.ASV   1.0   05 Sep 1995 16:55:22   HENRY  $
	 title	 MEM_MISC -- MEMCHK Miscellaneous Routines
	 page	 58,122
	 name	 MEM_MISC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.

Segmentation:  See MEM_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOS.INC
	 include BITFLAGS.INC
	 include PTR.INC
	 include 386.INC

	include MEM_FMT.INC
	include MEM_SEG.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	extrn	CON10:dword

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF' ; Translate table

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  BIN2DWORD -- Convert Binary EAX to Hex at ES:DI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This routine runs in both Real and Protected Mode.

On entry:

EAX	 =	 value to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 eax,16 	; Swap order
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 rol	 eax,16 	; Swap order
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DWORD endp			; End BIN2DWORD procedure
	 NPPROC  BIN2WORD -- Convert Binary AX to Hex at ES:DI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This routine runs in both Real and Protected Mode.

On entry:

AX	 =	 value to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 ax,8		; Swap order
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI

	 rol	 ax,8		; Swap order
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2WORD endp			; End BIN2WORD procedure
	 NPPROC  BIN2BYTE -- Convert Binary AL to Hex at ES:DI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This routine runs in both Real and Protected Mode.

On entry:

AL	 =	 value to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 al,4		; Swap order
	 call	 BIN2DIGIT	; Convert low-order digit in AL to hex at ES:DI

	 rol	 al,4		; Swap order
	 call	 BIN2DIGIT	; Convert low-order digit in AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BYTE endp			; End BIN2BYTE procedure
	 NPPROC  BIN2DIGIT -- Convert Low-order Binary Digit in AL to Hex at ES:DI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This routine runs in both Real and Protected Mode.

On entry:

AL	 =	 value to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 REGSAVE <ax,bx>	; Save registers

	 lea	 bx,HEXTABLE	; DS:BX ==> translate table
	 and	 al,@NIB0	; Isolate the digit
	 xlat	 HEXTABLE[bx]
S16	 stos	 es:[di].LO

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DIGIT endp			; End BIN2DIGIT procedure
	 NPPROC  BIN2DEC -- Convert From Binary to Decimal
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2DEC -- Convert the number in AX to ASCII in decimal storing the
low-order digit of the # at ES:DI.

This routine runs in both Real and Protected Mode.

On entry:

AX	 ==>	 value to convert
ES:DI	 ==>	 place to put low-order digit of output

On exit:

ES:DI	 ==>	 next byte below last one stored

|

	 REGSAVE <ax,bx,cx,dx,si,bp> ; Save all registers except DI

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 bp,5		; Go through this many times
	 mov	 cx,10		; Use this base for conversion
BIN2DEC_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 cx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movs	 <es:[di].LO,HEXTABLE[si]> ; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jz	 short BIN2DEC_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short BIN2DEC_LOOP ; Not done yet
BIN2DEC_EXIT:
	 popf			; Restore flags

	 REGREST <bp,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DEC  endp			; End BIN2DEC procedure
	 NPPROC  BIND2DEC -- Convert From Binary to Decimal
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2DEC -- Convert the number in EAX to ASCII in decimal storing the
low-order digit of the # at ES:DI.

This routine runs in both Real and Protected Mode.

On entry:

EAX	 ==>	 value to convert
ES:DI	 ==>	 place to put low-order digit of output

On exit:

ES:DI	 ==>	 next byte below last one stored

|

	 REGSAVE <eax,bx,ecx,edx,si,bp> ; Save all registers except DI

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 bp,10		; Go through this many times
	 mov	 ecx,10 	; Use this base for conversion
BIND2DEC_LOOP:
	 xor	 edx,edx	; Zero high-order word for division
	 div	 ecx		; Divide by number base
				; EDX has remainder, EAX has quotient
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movs	 <es:[di].LO,HEXTABLE[si]> ; Store in result

	 and	 eax,eax	; Check for zero quotient
	 jz	 short BIND2DEC_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short BIND2DEC_LOOP ; Not done yet
BIND2DEC_EXIT:
	 popf			; Restore flags

	 REGREST <bp,si,edx,ecx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIND2DEC endp			; End BIND2DEC procedure
	 NPPROC  BIN2BIT -- Convert From Binary To Bits
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2BIT -- Convert the CX low-order bits in EAX to ASCII storing the
high-order value at ES:DI and beyond.

On entry:

EAX	 =	 value to convert
CX	 =	 # low-order bits to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 REGSAVE <eax,ebx>	; Save registers

	 ror	 eax,cl 	; Rotate into high-order bits
	 mov	 ebx,eax	; Copy value to convert
BIN2BIT_NEXT:
	 mov	 al,'0'         ; Assume the next bit is a zero
	 shl	 ebx,1		; Split off another bit
	 adc	 al,0		; In case it's a one

S16	 stos	 es:[di].LO	; Store the digit

	 loop	 BIN2BIT_NEXT	; Jump if more bits to convert

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BIT  endp			; End BIN2BIT procedure
	 NPPROC  BIN2DVAL -- Convert Binary EAX to Hex or Decimal at ES:DI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2DVAL -- Convert Binary EAX to Hex or Decimal at ES:DI

This routine runs in both Real and Protected Mode.

On entry:

EAX	 =	 value to convert
ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

; Split cases depending upon the desired base

	 test	 GL2_FLAG,@GL2_HEX ; Should we display it in hex?
	 jnz	 short BIN2DVAL_HEX ; Jump if so

	 mov	 es:[di].EDQLO,'    ' ; Clear the field
	 mov	 es:[di].EDQHI,'    ' ; ...

	 add	 di,8-1-2	; Skip to the end of the field,
				; less room for ' K'
	 mov	 es:[di+1].ELO,'K ' ; Save ' K'

	 push	 eax		; Save for a moment

	 add	 eax,1024/2	; Round to halfway point
	 shr	 eax,10-0	; Convert from bytes to 1KB (rounding down)
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

	 pop	 eax		; Restore

	 jmp	 short BIN2DVAL_EXIT ; Join common exit code

BIN2DVAL_HEX:
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI
BIN2DVAL_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DVAL endp			; End BIN2DVAL procedure
	NPPROC	DW2DEC -- Convert AX To Decimal At ES:DI
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AX to decimal at ES:DI.

On entry:

AX	=	# to convert
ES:DI	==>	save area

On exit:

ES:DI	==>	(incremented)

|

DW2DEC_STR struc

DW2DEC_VEC dd	?		; Address of caller's buffer
DW2DEC_BUF db	7 dup (?)	; Local buffer big enough to handle
				; 64K-1 with commas (xx,xxx)
	dw	?		; Caller's BP
	dw	?		;	   IP
DW2DEC_FLG dw	?		; Flags

DW2DEC_STR ends

@DW2DEC_SIZE equ (size DW2DEC_STR)-3*2 ; Size of local stack in bytes
				; less BP, IP, flags
	push	bp		; Prepare to address the stack
	sub	sp,@DW2DEC_SIZE ; Make room on stack
	mov	bp,sp		; Hello, Mr. Stack

	pushf			; Save flags

	REGSAVE <ax,bx,cx,dx,si,es> ; Save registers

	test	[bp].DW2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F       ; Not this time

	mov	[bp].DW2DEC_VEC.VOFF,di ; Save address of caller's buffer
	mov	[bp].DW2DEC_VEC.VSEG,es ; ...

	push	ss		; Setup ES for string operations
	pop	es		; ...
	assume	es:nothing	; Tell the assembler about it

	lea	di,[bp].DW2DEC_BUF[(size DW2DEC_BUF)-1] ; ES:DI ==> buffer end
@@:
	xor	cx,cx		; Initialize byte count
	xor	dx,dx		; Zero high-order dword
	std			; String ops backwards
DW2DEC_COMMA:
	xor	bx,bx		; Initialize comma count
DW2DEC_NEXT:
	div	CON10.ELO	; Split off another decimal digit
				; AX = quotient
				; DX = remainder
	xchg	ax,dx		; Swap to display AL
	add	al,'0'          ; Convert to decimal ASCII
	stos	es:[di].LO	; Save in buffer
	inc	cx		; Account for it
	mov	ax,dx		; Copy to dividend register
	xor	dx,dx		; Zero for next time

	and	ax,ax		; Check the remainder
	jz	short DW2DEC_END ; Jump if that's all

	test	[bp].DW2DEC_FLG,@DEC_COMMA ; Comma insertion requested?
	jz	short DW2DEC_NEXT ; Not this time

	inc	bx		; Account for it

	cmp	bx,3		; Izit time to comma-insert?
	jne	short DW2DEC_NEXT ; Not as yet

	push	ax		; Save for a moment
	mov	al,','          ; Separator
	stos	es:[di].LO	; Save in buffer
	pop	ax		; Restore

	inc	cx		; Account for it

	jmp	DW2DEC_COMMA	; Go around again

DW2DEC_END:
	test	[bp].DW2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

	lea	si,[di+1]	; SS:SI ==> start of buffer
	les	di,[bp].DW2DEC_VEC ; ES:DI ==> caller's buffer
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
    rep movs	es:[di].LO,ss:[si].LO ; Move into caller's data area
@@:
	REGREST <es,si,dx,cx,bx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	popf			; Restore flags

	add	sp,@DW2DEC_SIZE ; Remove room from stack
	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2DEC	endp			; End DW2DEC procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_MISC module
