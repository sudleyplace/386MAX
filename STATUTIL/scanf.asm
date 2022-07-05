;' $Header$
	title	SCANF -- SCANF Routines
	page	58,122
	name	SCANF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-1995 Rex C. Conn
			  1994-1996 Qualitas, Inc.  GNU General Public License version 3.

Program derived from:  None.

Original code by:  Rex C. Conn, 1994

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include PTR.INC
	include ASCII.INC
.list

ifnb <WIN>
CODE	equ	<_TEXT>
DATA	equ	<_DATA>
endif

% PGROUP group	CODE
% DGROUP group	DATA


ifdef W16

RAX	equ	<ax>
RBX	equ	<bx>
RCX	equ	<cx>
RDX	equ	<dx>
RSI	equ	<si>
RDI	equ	<di>
RBP	equ	<bp>
RSP	equ	<sp>
WID	equ	<16>
DMSK	equ	<0FFFFh>
USE	equ	<use16>
DOFF	equ	<dw>
DOFFSIZ equ	<2>
DOFFTYP equ	<word>
DVEC	equ	<dd>
DVECSIZ equ	<4>
DVECTYP equ	<dword>
OVEC	equ	<VOFF>
SVEC	equ	<VSEG>
JRCXZ	equ	<jcxz>
DWS2	equ	<2>		; (@WordSize eq 2)?2:0
WS	equ	<2>		; @WordSize
INT_MAX equ	16

elseifdef W32

RAX	equ	<eax>
RBX	equ	<ebx>
RCX	equ	<ecx>
RDX	equ	<edx>
RSI	equ	<esi>
RDI	equ	<edi>
RBP	equ	<ebp>
RSP	equ	<esp>
WID	equ	<32>
DMSK	equ	<0FFFFFFFFh>
USE	equ	<use32>
DOFF	equ	<dd>
DOFFSIZ equ	<4>
DOFFTYP equ	<dword>
DVEC	equ	<dq>
DVECSIZ equ	<8>		; Rounded size for stack operations
DVECTYP equ	<fword>
OVEC	equ	<FOFF>
SVEC	equ	<FSEL>
JRCXZ	equ	<jecxz>
DWS2	equ	<0>		; (@WordSize eq 2)?2:0
WS	equ	<4>		; @WordSize
INT_MAX equ	32

else
%OUT The parameter W16 or W32 is not specified.
.err
endif

@DEC_LEFT  equ	0001h		; Left-justified
@DEC_COMMA equ	0002h		; Comma insertion


% DATA	segment USE dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

;;;;;;; public	PF_XLATLO
PF_XLATLO db	'0123456789abcdef'

DATA	ends			; End DATA segment


% CODE	segment USE byte public 'code' ; Start CODE segment
	assume	cs:PGROUP

if @WordSize eq 2
	assume	ds:PGROUP
ifdef EXTDATASEG
	extrn	DATASEG:word
else
;;;;;;; public	DATASEG
DATASEG dw	seg DGROUP	; DGROUP data segment
endif
endif

	NPPROC	SSCANF -- Scan Source Format
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

Scan source buffer (lpszBuffer) using format string (lpszFormat)
and save results in successive arguments.

Syntax:

SSCANF (lpszBuffer, lpszFormat, [args, ...])

Format String:

%[*][width][size]type
*:
    Scan but don't assign this field.
width:
    Controls the maximum # of characters read.
size:
    F	  Specifies argument is FAR
    l	  Specifies 'd', 'u' is long
    h	  Specifies 'd', 'u' is short
    t	  Specifies 'd', 'u' is tiny
type:
    c	  character
    s	  string
   [ ]	  array of characters
    d	  signed integer
    u	  unsigned integer
    x	  hex integer
    n	  number of characters read so far

On entry:

SS:eBP	==>	SCANF_STR (after initialization)

On exit:

eAX	=	# fields

|

lclSCANF_STR struc		; Local vars

lclSCANF_FLDCNT DOFF ?		; # fields processed
lclSCANF_WIDTH DOFF ?		; Field width
lclSCANF_SRCBASE DOFF ? 	; Starting source offset
lclSCANF_BASE dd ?		; Numeric base for conversion
lclSCANF_TAB dq 32 dup (?)	; Table of 256 bits (one per character)
lclSCANF_DGR dw ?		; Segment/selector of DGROUP
lclSCANF_FLAGS dw ?		; Flags (see SCANF_REC below)
lclSCANF_LCHR db ?,?		; Last char (w/filler for alignment)
lclSCANF_ARG DOFF ?		; Offset of next argument
lclSCANF_CNT dd ?		; Count of # iterations within parentheses
lclSCANF_NEST dd ?		; Count of # nestings within parentheses

lclSCANF_STR ends


argSCANF_STR struc		; Arguments

argSCANF_SRC DVEC ?		; Ptr to source buffer
argSCANF_FMT DVEC ?		; Ptr to format string
argSCANF_ARG DOFF ?		; Start of argument(s)

argSCANF_STR ends


SCANF_REC record \
$SCANF_IsFar:1,  \
$SCANF_IsSize:2, \
$SCANF_Ignore:1, \
$SCANF_TabCmp:1, \
$SCANF_UseTab:1, \
$SCANF_Sign:1

@SCANF_IsFar  equ (mask $SCANF_IsFar)  ; 'F' specified
@SCANF_IsSize equ (mask $SCANF_IsSize) ; 'l', 'h', 't' ...
@SCANF_Ignore equ (mask $SCANF_Ignore) ; '*' ...
@SCANF_TabCmp equ (mask $SCANF_TabCmp) ; '^' ...
@SCANF_UseTab equ (mask $SCANF_UseTab) ; '[]' ...
@SCANF_Sign   equ (mask $SCANF_Sign)   ; '-' in source

; Equates for @SCANF_IsSize

@SizeTiny  equ	01b		; Tiny	(8-bit)
@SizeShort equ	10b		; Short (16-bit)
@SizeLong  equ	11b		; Long	(32-bit)


SCANF_STR struc

SCANFlcl db	(type lclSCANF_STR) dup (?) ; Local vars
%	DOFF	?		; Caller's eBP
%	DOFF	?		; ...	   eIP
SCANFarg db	(type argSCANF_STR) dup (?) ; Arguments

SCANF_STR ends

	push	RBP		; Prepare to address the stack
	sub	RSP,type lclSCANF_STR ; Make room for local vars
	mov	RBP,RSP 	; Hello, Mr. Stack
if @WordSize eq 2
	push	fs		; Save register

	mov	fs,DATASEG	; Address it
	assume	fs:DGROUP	; Tell the assembler about it
endif
	REGSAVE <RSI,RDI,gs>	; Save registers

	lds	RSI,[RBP].SCANFarg.argSCANF_FMT ; DS:eSI ==> format string
	assume	ds:nothing	; Tell the assembler about it

	mov	RDI,[RBP].SCANFarg.argSCANF_SRC.OVEC ; Get starting source offset
	mov	[RBP].SCANFlcl.lclSCANF_SRCBASE,RDI ; Save for later use
	mov	[RBP].SCANFlcl.lclSCANF_FLDCNT,0 ; Initialize the field count
	mov	[RBP].SCANFlcl.lclSCANF_DGR,fs ; Save for later use
	lea	RAX,[RBP].SCANFarg.argSCANF_ARG ; Get offset to first argument
	mov	[RBP].SCANFlcl.lclSCANF_ARG,RAX ; Save for later use
	mov	[RBP].SCANFlcl.lclSCANF_NEST,0 ; Initialize

	call	SSCANF_SUBFLD	; Scan the next field

	mov	RAX,[bp].SCANFlcl.lclSCANF_FLDCNT ; Return # fields

	REGREST <gs,RDI,RSI>	; Restore
	assume	gs:nothing	; Tell the assembler about it
if @WordSize eq 2
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it
endif
	add	RSP,type lclSCANF_STR ; Strip local vars
	pop	RBP		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SSCANF	endp			; End SSCANF procedure
	NPROC	SSCANF_SUBFLD -- Scan The Next Field
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Scan the next field

On entry:

SS:RBP	==>	SCANF_STR

|

SCANF_NEXTFLD:
	lods	ds:[RSI].LO	; Get next format char

	cmp	al,0		; Izit EOL?
	je	near ptr SCANF_DONE0 ; Jump if so

; Check for end of nested parentheses

	cmp	al,')'          ; Izit right paren?
	jne	short SCANF_XRPAREN ; Jump if not

	cmp	[RBP].SCANFlcl.lclSCANF_NEST,0 ; Izit inactive?
	jne	near ptr SCANF_DONE ; Jump if not
SCANF_XRPAREN:

; Check for start of format field

	cmp	al,'%'          ; Check for start of format
	jne	near ptr SCANF_XFMT ; Jump if not
if @WordSize eq 2
	mov	[RBP].SCANFlcl.lclSCANF_FLAGS,@SizeShort shl $SCANF_IsSize ; Initialize
else
	mov	[RBP].SCANFlcl.lclSCANF_FLAGS,@SizeLong  shl $SCANF_IsSize ; Initialize
endif
	mov	[RBP].SCANFlcl.lclSCANF_WIDTH,INT_MAX ; ...
	mov	[RBP].SCANFlcl.lclSCANF_CNT,-1 ; ...

	lods	ds:[RSI].LO	; Get next format char

; Check for ignore marker

	cmp	al,'*'          ; Izit to be ignored?
	jne	short @F	; Jump if so

	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Ignore ; Mark as to be ignored
	lods	ds:[RSI].LO	; Get next format char
@@:

; Check for format width

	cmp	al,'0'          ; Izit below field width?
	jb	short SCANF_NEXTFMT1 ; Jump if so

	cmp	al,'9'          ; Izit above field width?
	ja	short SCANF_NEXTFMT1 ; Jump if so

	dec	RSI		; Back off to initial digit

	mov	ecx,10		; Convert as decimal
	call	BASE2BIND	; Convert text at DS:eSI to binary in base ECX
				; Return with EAX = value, CF significant
				; ...	      eSI incremented past numeric text
;;;;;;; jc	short SCANF_ERR2 ; Jump if error

	mov	[RBP].SCANFlcl.lclSCANF_WIDTH,RAX ; Save for later use
SCANF_NEXTFMT:
	lods	ds:[RSI].LO	; Get next format char
SCANF_NEXTFMT1:

; Check for EOL

	cmp	al,0		; Izit EOL?
	je	near ptr SCANF_ERR1 ; Jump if so

; Check for left paren

	cmp	al,'('          ; Izit left paren?
	jne	short SCANF_XLPAREN ; Jump if not

; Copy width to count

	mov	eax,INT_MAX	; Get maximum width
	xchg	RAX,[RBP].SCANFlcl.lclSCANF_WIDTH ; Swap w/width
	mov	[RBP].SCANFlcl.lclSCANF_CNT,eax ; Save for later use
	inc	[RBP].SCANFlcl.lclSCANF_NEST ; Count in another nesting level
	mov	[RBP].SCANFarg.argSCANF_FMT.OVEC,RSI ; Save to restore
SCANF_NEXTBLK:
	mov	RSI,[RBP].SCANFarg.argSCANF_FMT.OVEC ; Start over again

	push	[RBP].SCANFlcl.lclSCANF_CNT ; Save over next call
	call	SSCANF_SUBFLD	; Scan another field
	pop	[RBP].SCANFlcl.lclSCANF_CNT ; Restore

	dec	[RBP].SCANFlcl.lclSCANF_CNT ; Count out another
	jnz	short SCANF_NEXTBLK ; Jump if more

	dec	[RBP].SCANFlcl.lclSCANF_NEST ; Count out another nesting level

	jmp	SCANF_NEXTFLD	; Go around again


SCANF_XLPAREN:

; Check for long

	cmp	al,'l'          ; Izit long?
	jne	short SCANF_XL	; Jump if not

	and	[RBP].SCANFlcl.lclSCANF_FLAGS,not @SCANF_IsSize ; Clear the size flags
	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SizeLong shl $SCANF_IsSize ; Mark as long

	jmp	SCANF_NEXTFMT	; Go Around again


SCANF_XL:

; Check for short

	cmp	al,'h'          ; Izit short?
	jne	short SCANF_XH	; Jump if not

	and	[RBP].SCANFlcl.lclSCANF_FLAGS,not @SCANF_IsSize ; Clear the size flags
	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SizeShort shl $SCANF_IsSize ; Mark as short

	jmp	SCANF_NEXTFMT	; Go Around again


SCANF_XH:

; Check for tiny

	cmp	al,'t'          ; Izit tiny?
	jne	short SCANF_XT	; Jump if not

	and	[RBP].SCANFlcl.lclSCANF_FLAGS,not @SCANF_IsSize ; Clear the size flags
	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SizeTiny shl $SCANF_IsSize ; Mark as tiny

	jmp	SCANF_NEXTFMT	; Go Around again


SCANF_XT:

; Check for far

	cmp	al,'F'          ; Izit far?
	jne	short SCANF_XF	; Jump if not

	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_IsFar ; Mark as far

	jmp	SCANF_NEXTFMT	; Go around again


SCANF_XF:

; Check for table of chars

	cmp	al,'['          ; Izit table?
	jne	short SCANF_XLBR; Jump if not

	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_UseTab ; Mark as using table

	xor	eax,eax 	; A handy zero

; Check for table complement

	cmp	ds:[RSI].LO,'^' ; Izit to be complemented?
	jne	short @F	; Jump if not

	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_TabCmp ; Mark as using table complement
	inc	RSI		; Skip over it
	dec	eax		; Store all 1s instead of 0s
@@:

; Initialize the table to all 0s or 1s

	lea	RBX,[RBP].SCANFlcl.lclSCANF_TAB ; SS:eBX ==> table
	mov	RCX,256/32	; # dwords in table
@@:
	mov	ss:[RBX].EDD,eax ; Set to zero
	add	RBX,4		; Skip to next table entry
	loop	@B		; Jump if more table entries

; Save table of chars as bits

	lea	RBX,[RBP].SCANFlcl.lclSCANF_TAB ; SS:eBX ==> table
	xor	eax,eax 	; Zero to use as dword
SCANF_NEXTTAB:
	lods	ds:[RSI].LO	; Get next table char

	cmp	al,0		; Izit EOL?
	je	near ptr SCANF_ERR1 ; Jump if so

	cmp	al,']'          ; Izit EOT?
	je	near ptr SCANF_NEXTFMT ; Jump if so

	btc	ss:[RBX].EDD,eax ; Complement the bit

	jmp	SCANF_NEXTTAB	; Go around again


SCANF_XLBR:
	mov	[RBP].SCANFlcl.lclSCANF_LCHR,al ; Save for later use

; Check for chars and strings

	cmp	al,'c'          ; Izit character?
	je	short SCANF_C	; Jump if so

	cmp	al,'s'          ; Izit string?
	je	short SCANF_S	; Jump if so

	jmp	SCANF_XSC	; Jump if not


SCANF_C:
	cmp	[RBP].SCANFlcl.lclSCANF_WIDTH,INT_MAX ; Izit max width?
	jne	short SCANF_SC_COM ; Jump if not

	mov	[RBP].SCANFlcl.lclSCANF_WIDTH,1 ; Save for later use

	jmp	short SCANF_SC_COM ; Join common code


; Skip over leading white space in the source buffer

SCANF_S:
	call	SkipWhiteSrc	; Skip over white space in the source buffer
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:eDI ==> next source char
SCANF_SC_COM:

; If we're not ignoring this field, get the next argument ptr

	call	GetNextArgPtr	; Get (and skip over) the next argument ptr
				; Return with GS:RBX ==> argument
; GS:eBX ==>	argument save area

; Loop through the source buffer for the smaller of
; SCANF_WIDTH chars and the end of source

	mov	RCX,[RBP].SCANFlcl.lclSCANF_WIDTH ; Get current width
%	JRCXZ	SCANF_LOOPWIDZ	; Jump if empty

	les	RDI,[RBP].SCANFarg.argSCANF_SRC ; ES:eDI ==> source buffer
	assume	es:nothing	; Tell the assembler about it
SCANF_NEXTWID:
	xor	eax,eax 	; Zero to use as dword
	mov	al,es:[RDI]	; Get next source char
	inc	RDI		; Skip over it

	cmp	al,0		; Izit EOL?
	je	short SCANF_LOOPWIDZ ; Jump if so

	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_UseTab ; Using table?
	jz	short SCANF_XTAB ; Jump if not

	push	RDI		; Save for a moment

	lea	RDI,[RBP].SCANFlcl.lclSCANF_TAB ; SS:eDI ==> table

	bt	ss:[RDI].EDD,eax ; Check the bit
	pop	RDI		; Restore
	jc	short SCANF_SAVE ; Jump if we're to save it

	jmp	short SCANF_LOOPWIDZ ; Join common loop exit code


SCANF_XTAB:
	cmp	[RBP].SCANFlcl.lclSCANF_LCHR,'s' ; Izit a string?
	jne	short SCANF_SAVE ; Jump if not

	cmp	al,' '          ; Izit white space?
	je	short SCANF_LOOPWIDZ ; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short SCANF_LOOPWIDZ ; Jump if so
SCANF_SAVE:
	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Ignore ; Izit to be ignored?
	jnz	short @F	; Jump if so

	mov	gs:[RBX],al	; Save in argument
	inc	RBX		; Skip over it
@@:
	inc	[RBP].SCANFarg.argSCANF_SRC.OVEC ; Skip to next source char

	loop	SCANF_NEXTWID	; Jump if more width
SCANF_LOOPWIDZ:
	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Ignore ; Izit to be ignored?
	jnz	short @F	; Jump if so

	inc	[RBP].SCANFlcl.lclSCANF_FLDCNT ; Count in another field

	cmp	[RBP].SCANFlcl.lclSCANF_LCHR,'s' ; Izit a string?
	jne	short @F	; Jump if not

	mov	gs:[RBX].LO,0	; Terminate the string
;;;;;;; inc	RBX		; Skip over it
@@:
	mov	[RBP].SCANFarg.argSCANF_SRC.OVEC,RDI ; Save as next source offset

	jmp	SCANF_NEXTFMT	; Go around again


SCANF_XSC:

; Check for numbers

	mov	[RBP].SCANFlcl.lclSCANF_BASE,10 ; Assume decimal

	cmp	al,'u'          ; Izit unsigned decimal?
	je	short @F	; Jump if so

	cmp	al,'d'          ; Izit signed decimal?
	je	short @F	; Jump if so

	cmp	al,'x'          ; Izit hexadecimal?
	jne	short SCANF_XNUM ; Jump if not

	mov	[RBP].SCANFlcl.lclSCANF_BASE,16 ; It's hexadecimal
@@:

; Skip over leading white space in the source buffer

	call	SkipWhiteSrc	; Skip over white space in the source buffer
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:eDI ==> next source char
; Check for sign

	cmp	es:[RDI].LO,'-' ; Izit signed?
	jne	short @F	; Jump if not

	or	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Sign ; Mark as negative
	inc	RDI		; Skip over it
@@:
	mov	[RBP].SCANFarg.argSCANF_SRC.OVEC,RDI ; Save for later use

; Convert the number

	REGSAVE <RSI,ds>	; Save for a moment

	lds	RSI,[RBP].SCANFarg.argSCANF_SRC ; DS:eSI ==> source
	assume	ds:nothing	; Tell the assembler about it

	mov	ecx,[RBP].SCANFlcl.lclSCANF_BASE ; Get the conversion base
	call	BASE2BIND	; Convert text at DS:eSI to binary in base ECX
				; Return with EAX = value, CF significant
				; ...	      eSI incremented past numeric text
	mov	RDI,RSI 	; Copy new ending ofset

	REGREST <ds,RSI>	; Restore
	assume	ds:nothing	; Tell the assembler about it
;;;;;;; jc	short SCANF_ERR2 ; Jump if error

	mov	[RBP].SCANFarg.argSCANF_SRC.OVEC,RDI ; Save for later use

	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Sign ; Izit negative?
	jz	short @F	; Jump if not

	neg	eax		; Change the sign
@@:
	jmp	short SCANF_XNUM1 ; Join common code


SCANF_XNUM:

; Check for character count

	cmp	al,'n'          ; Izit char count?
	jne	short SCANF_XCNT ; Jump if not

ifdef W16
	xor	eax,eax 	; Zero to use as dword in case long
endif
	mov	RAX,[RBP].SCANFarg.argSCANF_SRC.OVEC ; Get starting source offset
	sub	RAX,[RBP].SCANFlcl.lclSCANF_SRCBASE ; Less the starting offset
SCANF_XNUM1:
	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Ignore ; Izit to be ignored?
	jnz	short SCANF_IGN1 ; Jump if so

	call	GetNextArgPtr	; Get (and skip over) the next argument ptr
				; Return with GS:RBX ==> argument
; GS:eBX ==>	argument save area

	mov	dx,[RBP].SCANFlcl.lclSCANF_FLAGS ; Get the flags
	and	dx,@SCANF_IsSize ; Isolate the size bits

	cmp	dx,@SizeLong shl $SCANF_IsSize ; Izit long?
	jne	short @F	; Jump if not

	mov	gs:[RBX],eax	; Save in argument

	jmp	short SCANF_COM1 ; Join common code


@@:
	cmp	dx,@SizeShort shl $SCANF_IsSize ; Izit short?
	jne	short @F	; Jump if not

	mov	gs:[RBX],ax	; Save in argument

	jmp	short SCANF_COM1 ; Join common code


@@:
	cmp	dx,@SizeTiny shl $SCANF_IsSize ; Izit tiny?
	jne	short @F	; Jump if not

	mov	gs:[RBX],al	; Save in argument

	jmp	short SCANF_COM1 ; Join common code


@@:
	int	03h		; We should never get here
SCANF_COM1:
	inc	[RBP].SCANFlcl.lclSCANF_FLDCNT ; Count in another field
SCANF_IGN1:
	jmp	SCANF_NEXTFMT	; Go around again


; Match the next character in source and format

SCANF_XCNT:
	les	RDI,[RBP].SCANFarg.argSCANF_SRC ; ES:eDI ==> source buffer
	assume	es:nothing	; Tell the assembler about it

	inc	[RBP].SCANFarg.argSCANF_SRC.OVEC ; Skip over it

	cmp	al,es:[RDI]	; Izit same?
	je	near ptr SCANF_NEXTFLD ; Jump if so

	jmp	short SCANF_DONE ; We're done


SCANF_XFMT:

; If the format character is white space, skip over it

	cmp	al,' '          ; Izit white space?
	je	short @F	; Jump if so

	cmp	al,TAB		; Izit white space?
	jne	short SCANF_XFMT1 ; Jump if not
@@:

; Skip over leading white space in the format string

	inc	RSI		; Skip over it

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so

	dec	RSI		; Back off to last char

; Skip over leading white space in the source buffer

	call	SkipWhiteSrc	; Skip over white space in the source buffer
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:eDI ==> next source char
	jmp	SCANF_NEXTFLD	; Join common code


; Match the next character in source and format

SCANF_XFMT1:
	les	RDI,[RBP].SCANFarg.argSCANF_SRC ; ES:eDI ==> source buffer
	assume	es:nothing	; Tell the assembler about it

	inc	[RBP].SCANFarg.argSCANF_SRC.OVEC ; Skip over it

	cmp	al,es:[RDI]	; Izit same?
	je	near ptr SCANF_NEXTFLD ; Jump if so

	jmp	short SCANF_DONE ; We're done


; EOL in midst of format string

SCANF_ERR1:

; *FIXME*




SCANF_DONE0:
	dec	RSI		; Back off to terminating zero
SCANF_DONE:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SSCANF_SUBFLD endp		; End SSCANF_SUBFLD procedure
	NPROC	GetNextArgPtr -- Get Next Argument Ptr
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next argument ptr

On entry:

SS:RBP	==>	SSCANF_STR

On exit:

GS:RBX	==>	argument

|

	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_Ignore ; Izit to be ignored?
	jnz	short GNAP_EXIT ; Jump if so

	mov	RBX,[RBP].SCANFlcl.lclSCANF_ARG ; Get offset to next argument
	add	[RBP].SCANFlcl.lclSCANF_ARG,DOFFSIZ ; Skip over it
	mov	gs,[RBP].SCANFlcl.lclSCANF_DGR ; Get DGROUP segment/selector
	assume	gs:nothing	; Tell the assembler about it

	test	[RBP].SCANFlcl.lclSCANF_FLAGS,@SCANF_IsFar ; Izit far?
	jz	short @F	; Jump if not

	mov	gs,ss:[RBX].SVEC ; Get segment/selector
	assume	gs:nothing	; Tell the assembler about it

	add	[RBP].SCANFlcl.lclSCANF_ARG,DOFFSIZ ; Skip over it
@@:
	mov	RBX,ss:[RBX].OVEC ; Get offset
GNAP_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetNextArgPtr endp		; End GetNextArgPtr procedure
	NPROC	SkipWhiteSrc -- Skip Over White Space In Source
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space in source

On entry:

SS:RBP	==>	SCANF_STR

On exit:

ES:RDI	==>	next source char

|

	les	RDI,[RBP].SCANFarg.argSCANF_SRC ; ES:eDI ==> source buffer
	assume	es:nothing	; Tell the assembler about it
@@:
	inc	RDI		; Skip to next char

	cmp	es:[RDI-1].LO,' ' ; Izit white space?
	je	short @B	; Jump if so

	cmp	es:[RDI-1].LO,TAB ; Izit white space?
	je	short @B	; Jump if so

	dec	RDI		; Back off to last char
	mov	[RBP].SCANFarg.argSCANF_SRC.OVEC,RDI ; Save for later use

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipWhiteSrc endp		; End SkipWhiteSrc procedure
	NPROC	LOWERCASE -- Convert AL to Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert to lowercase

On entry:

AL	=	character to convert

On exit:

AL	=	converted character

|

	cmp	al,40h		; Test for conversion of alpha to lower case
	jb	short @F	; Not this time

	or	al,20h		; Convert alpha to lower case
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPROC	SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:eSI	==>	<text>

On exit:

AL	=	first char after white space in <text>,
		converted to lowercase
DS:eSI	==>	first char after white space in <text>

|

@@:
	lods	ds:[RSI].LO	; Get the next byte

	cmp	al,' '          ; Check for blank
	je	short @B	; Go around again

	cmp	al,TAB		; Check for TAB
	je	short @B	; Go around again

	call	LOWERCASE	; Convert to lowercase

	ret			; Return to caller with next byte in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPROC	SKIP_BLACK -- Skip Over Non-White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over non-white space

On entry:

DS:eSI	==>	<text>

On exit:

DS:eSI	==>	first char after non-white space in <text>

|

	push	ax		; Save for a moment
@@:
	lods	ds:[RSI].LO	; Get the next byte

	cmp	al,' '          ; Check for blank or below
	ja	short @B	; Jump if not

	dec	RSI		; Back off to white space

	pop	ax		; Restore

	ret			; Return to caller with next byte in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_BLACK endp 		; End SKIP_BLACK procedure
	NPROC	BASE2BIND -- Convert From Specified Base to Binary
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the number at DS:eSI in base ECX to binary.

On entry:

ECX	=	base for converson
DS:eSI	==>	ASCII number to convert

On exit:

EAX	=	converted number
DS:eSI	==>	next character after converted number

|

	REGSAVE <ebx,ecx,edx,edi> ; Save registers

	call	SKIP_WHITE	; Skip over more white space

	xor	ebx,ebx 	; Zero accumulator
BASE2BIND_LOOP:
	lea	edi,PF_XLATLO	; Get address of number conversion table
	push	ecx		; Save number base (and table length)
  repne scas	PF_XLATLO[RDI]	; Look for the character
	pop	ecx		; Restore number base
	jne	short BASE2BIND_EXIT ; Not one of ours

	sub	edi,1+offset es:PF_XLATLO ; Convert to origin 0
	mov	eax,ebx 	; Copy old to multiply by base
	mul	ecx		; Shift over accumulated #
	mov	ebx,eax 	; Copy back
	add	ebx,edi 	; Add in new #

	lods	ds:[RSI].LO	; Get next digit
	call	LOWERCASE	; Convert to lowercase

	jmp	BASE2BIND_LOOP	; Go around again


BASE2BIND_EXIT:
	dec	RSI		; Back off to previous character
	mov	eax,ebx 	; Place result in accumulator

	REGREST <edi,edx,ecx,ebx> ; Restore registers

	ret			; Return to caller with number in AX

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIND endp			; End BASE2BIND procedure

CODE	ends			; End CODE segment

	MEND			; End SCANF module
