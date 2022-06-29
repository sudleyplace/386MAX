;' $Header$
	title	STRFNS -- ASM Version Of Common String Functions
	page	58,122
	name	STRFNS

COMMENT|				Module Specifications

Copyright: (C) Copyright 2001-2002 Qualitas, Inc.  All rights reserved.

|
.386
	include MASM.INC
	include PTR.INC

ifdef WIN
CODE	equ	<_TEXT>
endif

% PGROUP group	CODE


% CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP

	NPPROC	StrNCpy -- String Copy With Specific Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy with specific length

On entry:

SS:BP	==>	CPYN_STR (after lclPROLOG)

On exit:

AX	=	actual length copied

|

lclCPYN_STR struc		; Local vars
lclCPYN_STR ends


argCPYN_STR struc		; Arguments

argCPYN_Len dw	?		; Maximum copy length
argCPYN_Src dd	?		; Ptr to source
argCPYN_Dst dd	?		; ...	 destin

argCPYN_STR ends


CPYN_STR struc

;CPYNlcl db	 (type lclCPYN_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
CPYNarg db	(type argCPYN_STR) dup (?) ; Arguments

CPYN_STR ends


	lclPROLOG <CPYN_STR>	; Address local vars

	REGSAVE <cx,si,di,ds,es> ; Save registers

	mov	cx,[bp].CPYNarg.argCPYN_Len ; Get length to copy
	jcxz	StrNCpyExit	; Jump if string empty

	lds	si,[bp].CPYNarg.argCPYN_Src ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].CPYNarg.argCPYN_Dst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
@@:
	lods	ds:[si].LO	; Get next char
	stos	es:[di].LO	; Save it back

	cmp	al,0		; Izit EOS?
	loopne	@B		; Jump if not any more chars
StrNCpyExit:
	mov	ax,[bp].CPYNarg.argCPYN_Len ; Get length to copy
	sub	ax,cx		; Less length remaining

	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	lclEPILOG <CPYN_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNCpy endp			; End StrNCpy procedure
	NPPROC	StrCpy -- String Copy
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy

On entry:

SS:BP	==>	CPY_STR (after lclPROLOG)

On exit:

AX	=	# chars copied (excluding trailing zero)

|

lclCPY_STR struc		; Local vars
lclCPY_STR ends


argCPY_STR struc		; Arguments

argCPY_Src dd	?		; Ptr to source
argCPY_Dst dd	?		; ...	 destin

argCPY_STR ends


CPY_STR struc

;CPYlcl  db	 (type lclCPY_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
CPYarg	db	(type argCPY_STR) dup (?) ; Arguments

CPY_STR ends


	lclPROLOG <CPY_STR>	; Address local vars

	REGSAVE <cx,si,di,ds,es> ; Save registers

	lds	si,[bp].CPYarg.argCPY_Src ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].CPYarg.argCPY_Dst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	xor	cx,cx		; Initialize count
@@:
	lods	ds:[si].LO	; Get next char
	stos	es:[di].LO	; Save it back

	inc	cx		; Count in another

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	dec	cx		; Count out the terminating zero
	mov	ax,cx		; Copy to result register

	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	lclEPILOG <CPY_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrCpy	endp			; End StrCpy procedure
	NPPROC	StrCat -- String Catenate
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String catenate

On entry:

SS:BP	==>	CAT_STR (after lclPROLOG)

On exit:

AX	=	# chars catenated (excluding trailing zero)

|

lclCAT_STR struc		; Local vars
lclCAT_STR ends


argCAT_STR struc		; Arguments

argCAT_Src dd	?		; Ptr to source
argCAT_Dst dd	?		; ...	 destin

argCAT_STR ends


CAT_STR struc

;CATlcl  db	 (type lclCAT_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
CATarg	db	(type argCAT_STR) dup (?) ; Arguments

CAT_STR ends


	lclPROLOG <CAT_STR>	; Address local vars

	REGSAVE <cx,si,di,ds,es> ; Save registers

	lds	si,[bp].CATarg.argCAT_Src ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].CATarg.argCAT_Dst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	push	[bp].CATarg.argCAT_Dst	; Pass ptr to destin
	call	StrLen		; Calculate length, return in AX

	add	di,ax		; Skip over string in destin

	cld			; String ops forwards
	xor	cx,cx		; Initialize count
@@:
	lods	ds:[si].LO	; Get next char
	stos	es:[di].LO	; Save it back

	inc	cx		; Count in another

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	dec	cx		; Count out the terminating zero

	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	lclEPILOG <CAT_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrCat	endp			; End StrCat procedure
	NPPROC	StrICmp -- String Compare, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, case insensitive

On entry:

SS:BP	==>	ICMP_STR (after lclPROLOG)

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

lclICMP_STR struc		; Local vars
lclICMP_STR ends


argICMP_STR struc		; Arguments

argICMP_Arg2 dd ?		; Ptr to Arg #2
argICMP_Arg1 dd ?		; ...	     #1

argICMP_STR ends


ICMP_STR struc

;ICMPlcl db	 (type lclICMP_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
ICMParg db	(type argICMP_STR) dup (?) ; Arguments

ICMP_STR ends


	lclPROLOG <ICMP_STR>	; Address local vars

	REGSAVE <si,di,ds,es>	; Save registers

	lds	si,[bp].ICMParg.argICMP_Arg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].ICMParg.argICMP_Arg1 ; Get Arg #1 ptr
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
	call	UPPERCASE	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	jz	short StrICmpNext ; Jump if same
StrICmpExit:
	REGREST <es,ds,di,si>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	lclEPILOG <ICMP_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrICmp endp			; End StrICmp procedure
	NPPROC	StrNICmp -- String Compare, Length Sensitive, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, length sensitive, case insensitive

On entry:

SS:BP	==>	NICMP_STR (after lclPROLOG)

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

lclNICMP_STR struc		; Local vars
lclNICMP_STR ends


argNICMP_STR struc		; Arguments

argNICMP_Len dw ?		; Maximum compare length
argNICMP_Arg2 dd ?		; Ptr to Arg #2
argNICMP_Arg1 dd ?		; ...	     #1

argNICMP_STR ends


NICMP_STR struc

;NICMPlcl db	 (type lclNICMP_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
NICMParg db	(type argNICMP_STR) dup (?) ; Arguments

NICMP_STR ends


	lclPROLOG <NICMP_STR>	; Address local vars

	REGSAVE <cx,si,di,ds,es> ; Save registers

	lds	si,[bp].NICMParg.argICMP_Arg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].NICMParg.argNICMP_Arg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it

	mov	cx,[bp].NICMParg.argNICMP_Len ; Get maximum compare length
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
	call	UPPERCASE	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	loopz	short StrNICmpNext ; Jump if same and more chars to compare
StrNICmpExit:
	REGREST <es,ds,di,si,cx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	lclEPILOG <NICMP_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNICmp endp			; End StrNICmp procedure
	NPPROC	StrLen -- String Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length

On entry:

SS:BP	==>	LEN_STR (after lclPROLOG)

On exit:

AX	=	length

|

lclLEN_STR struc		; Local vars
lclLEN_STR ends


argLEN_STR struc		; Arguments

argLEN_Src dd	?		; Ptr to source

argLEN_STR ends


LEN_STR struc

;LENlcl  db	 (type lclLEN_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
LENarg	db	(type argLEN_STR) dup (?) ; Arguments

LEN_STR ends


	lclPROLOG <LEN_STR>	; Address local vars

	REGSAVE <cx,di,es>	; Save registers

	les	di,[bp].LENarg.argLEN_Src ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	al,0		; Search for this
	mov	cx,-1		; We know (or hope) it's there
  repne scas	es:[di].LO	; Search for it

	mov	ax,-(1+1)	; One for starting -1, one for trailing zero
	sub	ax,cx		; Subtract to get length

	REGREST <es,di,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	lclEPILOG <LEN_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLen	endp			; End StrLen procedure
	NPPROC	StrLenW -- String Length, Wide
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length, wide

On entry:

SS:BP	==>	LENW_STR (after lclPROLOG)

On exit:

AX	=	length

|

lclLENW_STR struc		; Local vars
lclLENW_STR ends


argLENW_STR struc		; Arguments

argLENW_Src dd	 ?		; Ptr to source

argLENW_STR ends


LENW_STR struc

;LENWlcl db	 (type lclLENW_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
LENWarg db	(type argLENW_STR) dup (?) ; Arguments

LENW_STR ends


	lclPROLOG <LENW_STR>	; Address local vars

	REGSAVE <cx,di,es>	; Save registers

	les	di,[bp].LENWarg.argLENW_Src ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	ax,0		; Search for this
	mov	cx,-1		; We know (or hope) it's there
  repne scas	es:[di].ELO	; Search for it

	mov	ax,-(1+1)	; One for starting -1, one for trailing zero
	sub	ax,cx		; Subtract to get length

	REGREST <es,di,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	lclEPILOG <LENW_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLenW endp			; End StrLenW procedure
	NPPROC	StrChr -- String Character Search
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String character search

On entry:

SS:BP	==>	CHR_STR (after lclPROLOG)

On exit:

DX:AX	==>	matching character
	=	0:0 if none

|

lclCHR_STR struc		; Local vars
lclCHR_STR ends


argCHR_STR struc		; Arguments

argCHR_Chr db	?		; Character to search for
	db	?		; For alignment
argCHR_Src dd	?		; Ptr to source

argCHR_STR ends


CHR_STR struc

;CHRlcl  db	 (type lclCHR_STR) dup (?) ; Local vars
	dw	?		; Caller's BP
	dw	?		; ...	   IP
CHRarg	db	(type argCHR_STR) dup (?) ; Arguments

CHR_STR ends


	lclPROLOG <CHR_STR>	; Address local vars

	REGSAVE <si,ds> 	; Save registers

	lds	si,[bp].CHRarg.argCHR_Src ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	mov	ah,[bp].CHRarg.argCHR_Chr ; Get character

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

	lclEPILOG <CHR_STR>	; Strip local vars and return

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrChr	endp			; End StrChr procedure
	NPPROC	UPPERCASE -- Convert AL to Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to uppercase.

On entry:

AL	=	value to convert

On exit:

AL	=	converted value

|


	cmp	al,'a'          ; Check against lower limit
	jb	short @F	; Jump if too small

	cmp	al,'z'          ; Check against upper limit
	ja	short @F	; Jump if too big

	add	al,'A'-'a'      ; Convert to uppercase
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure

% CODE	ends			; End CODE segment

	end			; End STRFNS Module
