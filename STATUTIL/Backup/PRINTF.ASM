;' $Header$
	title	PRINTF -- PRINTF Routines
	page	58,122
	name	PRINTF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2000 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, July, 1994.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include PTR.INC
	include ASCII.INC
.list


PGROUP	group	CODE
DGROUP	group	DATA

MAX	macro	R1,R2
	local	L1

	cmp	R1,R2		; Use the larger
	jae	short L1	; Jump if already larger

	mov	R1,R2		; R2 is larger
L1:
	endm			; MAX


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

else
%OUT The parameter W16 or W32 is not specified.
.err
endif

@DEC_LEFT  equ	0001h		; Left-justified
@DEC_COMMA equ	0002h		; Comma insertion


% DATA	segment USE dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

;;;;;;; public	PDispChar
% PDispChar DOFF offset PGROUP:DispChar ; Routine to display characters

;;;;;;; public	CON10
CON10	dd	10		; Constant 10

@PFACT_LOW equ	32		; PFACT lower limit (inclusive)
@PFACT_UPP equ	127		; ...	upper ...

PFACT_MAC macro CHAR,ACT

	org	PFACT + (CHAR - @PFACT_LOW) * (type PFACT)
	DOFF	offset PGROUP:PRINTF32_&ACT

	endm			; PFACT_MAC

; Make room for all 7-bit ASCII chars

;;;;;;; public	PFACT
% PFACT DOFF	(1 + @PFACT_UPP - @PFACT_LOW) dup (offset PGROUP:PRINTF32_ERR)
% PFACTZ label	DOFFTYP

	PFACT_MAC '%',OUT       ; Display '%'
	PFACT_MAC '0',ZPAD      ; Zero-pad
	PFACT_MAC '+',PLUS      ; Plus
	PFACT_MAC '-',LEFT      ; Left
	PFACT_MAC '#',0X        ; 0x
	PFACT_MAC ',',COMMA     ; Insert commas
	PFACT_MAC ' ',BLANK     ; Blank prefix
	PFACT_MAC '*',VWID      ; Variable width/precision
	PFACT_MAC '1',WID       ; Width
	PFACT_MAC '2',WID       ; ...
	PFACT_MAC '3',WID       ; ...
	PFACT_MAC '4',WID       ; ...
	PFACT_MAC '5',WID       ; ...
	PFACT_MAC '6',WID       ; ...
	PFACT_MAC '7',WID       ; ...
	PFACT_MAC '8',WID       ; ...
	PFACT_MAC '9',WID       ; ...
	PFACT_MAC '.',PREC      ; Precision
	PFACT_MAC 't',BYTE      ; Byte size
	PFACT_MAC 'h',WORD      ; Word size
	PFACT_MAC 'l',DWORD     ; Dword size
	PFACT_MAC 'F',FAR       ; Far ptr to data
	PFACT_MAC 'H',OFF16     ; 16-bit offset
	PFACT_MAC 'L',OFF32     ; 32-...
	PFACT_MAC 'N',NEAR      ; Near ptr to data
	PFACT_MAC 'c',CHAR      ; Type character
	PFACT_MAC 'd',SDEC      ; ...  signed decimal
	PFACT_MAC 'u',UDEC      ; ...  unsigned decimal
	PFACT_MAC 'x',LHEX      ; ...  lowercase hex
	PFACT_MAC 'X',UHEX      ; ...  uppercase hex
	PFACT_MAC 'o',OCT       ; ...  octal
	PFACT_MAC 'b',BIN       ; ...  binary
	PFACT_MAC 's',STR8      ; ...  byte string
	PFACT_MAC 'S',STR16     ; ...  wide string

	org	PFACTZ		; Return to normal end

;;;;;;; public	PF_XLATLO,PF_XLATHI
PF_XLATLO db	'0123456789abcdef'
PF_XLATHI db	'0123456789ABCDEF'

;;;;;;; public	MSG_PRINTF,MSG_PRINTFZ
MSG_PRINTF db	16 dup (?)	; Output for "+1234567"
MSG_PRINTFZ db	0		; Ending point

	align	4

;;;;;;; public	MSG_BUFFER,BufCnt
MSG_BUFFER db	128 dup (?)	; File output buffer
% BufCnt DOFF	0		; Buffer count

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

PF_STR	struc

PF_FLAG dd	?		; Flags (see @PF_xxx below)
% PF_CNT  DOFF	?		; # chars printed
% PF_WIDTH DOFF ?		; Width (0=default)
% PF_PREC DOFF	?		; Precision (1=default)
% PF_ARGWID DOFF ?		; Argument width (1, 2, 4)
PF_ARGMSK dd	?		; Argument mask (FF, FFF, FFFFFFFF)
PF_T1	dd	?		; Temporary value #1
PF_T2	dd	?		; ...		  #2

PF_STR	ends


@INI_PF_STR equ (DWS2 + DOFFSIZ) ; Initial per-xPRINTF stack
@MAX_PF_STR equ @INI_PF_STR + 2 * DVECSIZ ; Maximum stack size over
				; all xPRINTF routines

PF2_STR struc

PF2_LCL db	(type PF_STR) dup (?) ; Local struc
%	DOFF	?		; Caller's eBP
%	DOFF	?		; Local    eIP
%	DOFF	?		; Old DispChar routine
PF2_VARG db	@MAX_PF_STR dup (?) ; Variable arguments start here
PF2_VALUE dw	?		; Start of values on stack

PF2_STR ends




	NPPROC	FPRINTFLUSH -- FPRINTF Flush Buffer
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

FPRINTF flush buffer

|

FPF_STR struc

%	DOFF	?		; Caller's eBP
%	DOFF	?		; ...	   eIP
% FPF_HNDL DOFF ?		; File handle

FPF_STR ends

	push	RBP		; Prepare to address the stack
	mov	RBP,RSP 	; Hello, Mr. Stack

	REGSAVE <ax,bx,RCX,RDX,ds> ; Save registers

if @WordSize eq 2
	mov	ds,DATASEG	; Get DGROUP data segment
else
	mov	ax,fs		; Get DGROUP data segment
	mov	ds,ax		; Address it
endif
	assume	ds:DGROUP	; Tell the assembler about it

	mov	RCX,BufCnt	; # chars to write
	mov	bx,[RBP].FPF_HNDL.ELO ; Get file handle
	DOSCALL @WRITF2,MSG_BUFFER ; Write it out

	mov	BufCnt,0	; Start from the beginning

	REGREST <ds,RDX,RCX,bx,ax> ; Restore

	pop	RBP		; Restore

%	ret	DOFFSIZ 	; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FPRINTFLUSH endp		; End FPRINTFLUSH procedure
%	NPPROC	RPRINTF&WID -- Remote Print Format Routine
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

RPRINTF 16- or 32-bit routine.

Syntax:

RPRINTF (npWrite, lpszFormat, [args, ...])

This function formats output according to standard "C"
fprintf syntax and calls a user-specified routine to
handle the output.

On exit:

eAX	=	# chars printed

|

@RPFSIZE equ	@MAX_PF_STR - @INI_PF_STR - DVECSIZ - DVECSIZ

RPFARG_STR struc

if @WordSize eq 2
	dw	?		; Caller's FS
endif
%	DOFF	?		; Remote eIP
if @RPFSIZE
	db	@RPFSIZE dup (?) ; Filler
endif
% RPFEXT DVEC	?		; lpWrite
% RPFFMT DVEC	?		; lpszFormat

RPFARG_STR ends

PF2_EXT equ	<DVECTYP ptr PF2_VARG.RPFEXT> ; External routine (only if RPRINTF)

if @RPFSIZE
	sub	RSP,@RPFSIZE	; Make room
endif
if @WordSize eq 2
	push	fs		; Save register

	mov	fs,DATASEG	; Address it
	assume	fs:DGROUP	; Tell the assembler about it
endif
	push	PDispChar	; Save for a moment

	mov	PDispChar,offset PGROUP:ExtChar ; Use ExtChar routine

%	call	LPRINTF&WID	; Call local routine

	pop	PDispChar	; Restore
if @WordSize eq 2
	pop	fs		; Restore
endif
if @RPFSIZE
	add	RSP,@RPFSIZE	; Restore
endif
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% RPRINTF&WID endp		; End RPRINTF&WID procedure
%	NPPROC	FPRINTF&WID -- Filed Print Format Routine
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

FPRINTF 16- or 32-bit routine.

Syntax:

FPRINTF (uFileHandle, lpszFormat, [args, ...])

This function formats output according to standard "C"
fprintf syntax and writes the result to a user-specified file.

On exit:

eAX	=	# chars printed

|

@FPFSIZE equ	@MAX_PF_STR - @INI_PF_STR - DOFFSIZ - DVECSIZ

FPFARG_STR struc

if @WordSize eq 2
	dw	?		; Caller's FS
endif
%	DOFF	?		; Remote eIP
if @FPFSIZE
	db	@FPFSIZE dup (?) ; Filler
endif
% FPFHND DOFF	?		; uFileHandle
% FPFFMT DVEC	?		; lpszFormat

FPFARG_STR ends

PF2_HNDL equ	<PF2_VARG.FPFHND> ; File handle (only if FPRINTF)

if @FPFSIZE
	sub	RSP,@FPFSIZE	; Make room
endif
if @WordSize eq 2
	push	fs		; Save register

	mov	fs,DATASEG	; Address it
	assume	fs:DGROUP	; Tell the assembler about it
endif
	push	PDispChar	; Save for a moment

	mov	PDispChar,offset PGROUP:FileChar ; Use FileChar routine

%	call	LPRINTF&WID	; Call local routine

	pop	PDispChar	; Restore
if @WordSize eq 2
	pop	fs		; Restore
endif
if @FPFSIZE
	add	RSP,@FPFSIZE	; Restore
endif
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% FPRINTF&WID endp		; End FPRINTF&WID procedure
%	NPPROC	SPRINTF&WID -- Saved Print Format Routine
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

SPRINTF 16- or 32-bit routine.

This function formats output according to standard "C"
sprintf syntax and saves the result in a user-specified buffer.

Syntax:

SPRINTF (lpszBuffer, lpszFormat, [args, ...])

On exit:

eAX	=	# chars printed

|

@SPFSIZE equ	@MAX_PF_STR - @INI_PF_STR - DVECSIZ - DVECSIZ

SPFARG_STR struc

if @WordSize eq 2
	dw	?		; Caller's FS
endif
%	DOFF	?		; Remote eIP
if @SPFSIZE
	db	@SPFSIZE dup (?) ; Filler
endif
% SPFBUF DVEC	?		; lpszBuffer
% SPFFMT DVEC	?		; lpszFormat

SPFARG_STR ends

PF2_OUT_VEC equ <PF2_VARG.SPFBUF> ; Ptr to output save area (only if SPRINTF)

if @SPFSIZE
	sub	RSP,@SPFSIZE	; Make room
endif
if @WordSize eq 2
	push	fs		; Save register

	mov	fs,DATASEG	; Address it
	assume	fs:DGROUP	; Tell the assembler about it
endif
	push	PDispChar	; Save for a moment

	mov	PDispChar,offset PGROUP:SaveChar ; Use SaveChar routine

%	call	LPRINTF&WID	; Call local routine

	pop	PDispChar	; Restore
if @WordSize eq 2
	pop	fs		; Restore
endif
if @SPFSIZE
	add	RSP,@SPFSIZE	; Restore
endif
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% SPRINTF&WID endp		; End SPRINTF&WID procedure
%	NPPROC	PRINTF&WID -- Print Format Routine
if @WordSize eq 2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
endif
COMMENT|

Print Format 16- or 32-bit routine.

Syntax:

PRINTF (lpszFormat, [args, ...])

This function formats output according to standard "C"
printf syntax and writes the result to standard output.

On exit:

eAX	=	# chars printed

|

@PFSIZE equ	@MAX_PF_STR - @INI_PF_STR - DVECSIZ

PFARG_STR struc

if @WordSize eq 2
	dw	?		; Caller's FS
endif
%	DOFF	?		; Remote eIP
if @PFSIZE
	db	@PFSIZE dup (?) ; Filler
endif
% PFFMT DVEC	?		; lpszFormat

PFARG_STR ends

PF2_FMT_VEC equ <PF2_VARG.PFFMT> ; Ptr to format string

if @PFSIZE
	sub	RSP,@PFSIZE	; Make room
endif
if @WordSize eq 2
	push	fs		; Save register

	mov	fs,DATASEG	; Address it
	assume	fs:DGROUP	; Tell the assembler about it
endif
	push	PDispChar	; Save for a moment

	mov	PDispChar,offset PGROUP:DispChar ; Use DispChar routine

%	call	LPRINTF&WID	; Call local routine

	pop	PDispChar	; Restore
if @WordSize eq 2
	pop	fs		; Restore
endif
if @PFSIZE
	add	RSP,@PFSIZE	; Restore
endif
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% PRINTF&WID endp		; End PRINTF&WID procedure
%	NPROC	LPRINTF&WID -- Local Print Format Routine
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Local Print Format 16- or 32-bit routine.

This function formats output according to standard "C"
printf syntax.

On exit:

eAX	=	# chars printed

|

PF_REC	record	\
$PF_COMMA:1,	\
$PF_STR:1,	\
$PF_PREC:1,	\
$PF_NEAR:1,	\
$PF_OFF32:1,	\
$PF_OFF16:1,	\
$PF_FAR:1,	\
$PF_ZPAD:1,	\
$PF_PLUS:1,	\
$PF_LEFT:1,	\
$PF_0X:1,	\
$PF_BLNK:1,	\
$PF_SDEC:1,	\
$PF_LHEX:1

@PF_COMMA equ	(mask $PF_COMMA); 2000:  Insert commas
@PF_STR   equ	(mask $PF_STR)	; 1000:  Type is string
@PF_PREC  equ	(mask $PF_PREC) ; 0800:  Precision is specified
@PF_NEAR  equ	(mask $PF_NEAR) ; 0400:  Argument is near ptr to data
@PF_OFF32 equ	(mask $PF_OFF32); 0200:  Argument is 32-bit offset
@PF_OFF16 equ	(mask $PF_OFF16); 0100:  Argument is 16-bit offset
@PF_FAR   equ	(mask $PF_FAR)	; 0080:  Argument is far ptr to data
@PF_ZPAD  equ	(mask $PF_ZPAD) ; 0040:  Zero-pad the output
@PF_PLUS  equ	(mask $PF_PLUS) ; 0020:  Prefix with plus sign if positive
@PF_LEFT  equ	(mask $PF_LEFT) ; 0010:  Left-justify output
@PF_0X	  equ	(mask $PF_0X  ) ; 0008:  Prefix with 0, 0x, or 0X for o, x, and X
@PF_BLNK  equ	(mask $PF_BLNK) ; 0004:  Prefix with blank if positive
@PF_SDEC  equ	(mask $PF_SDEC) ; 0002:  Display as signed decimal
@PF_LHEX  equ	(mask $PF_LHEX) ; 0001:  Display as lowercase hex

	push	RBP		; Prepare to address the stack
	sub	RSP,type PF_STR ; Make room for local variables
	mov	RBP,RSP 	; Hello, Mr. Stack

	mov	[RBP].PF2_LCL.PF_CNT,0 ; Initialize # chars printed

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs,gs>	; Save registers

;;;;;;; mov	ax,seg DGROUP	; Get DGROUP segment
	mov	ax,fs		; Get DGROUP segment
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lds	RSI,DVECTYP ptr [RBP].PF2_FMT_VEC ; DS:eSI ==> format string
	assume	ds:nothing	; Tell the assembler about it

	mov	ax,ss		; Get stack segment
	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	lea	RDI,[RBP].PF2_VALUE ; FS:eDI ==> arguments
PRINTF32_NEXTTYPE:
	mov	[RBP].PF2_LCL.PF_FLAG,0 ; Initialize default values
	mov	[RBP].PF2_LCL.PF_WIDTH,0 ; ...
	mov	[RBP].PF2_LCL.PF_ARGWID,DOFFSIZ ; ...
	mov	[RBP].PF2_LCL.PF_ARGMSK,DMSK ; ...
	mov	[RBP].PF2_LCL.PF_PREC,1 ; ...

	lods	ds:[RSI].LO	; Get next char

	and	al,al		; Izit EOL?
	je	near ptr PRINTF32_EXIT ; Jump if so

	cmp	al,'%'          ; Izit format marker?
	je	short PRINTF32_NEXT ; Jump if so
PRINTF32_OUT:
	mov	dl,al		; Copy to output register
	call	PDispChar	; Display char in DL

	jmp	short PRINTF32_NEXTTYPE ; Go around again

PRINTF32_NEXT:
	xor	eax,eax 	; Zero to use as dword
	lods	ds:[RSI].LO	; Get next char

	cmp	al,@PFACT_LOW	; Check against lower limit
	jb	short PRINTF32_OUT ; Jump if too small

	cmp	al,@PFACT_UPP	; Check against upper limit
	ja	short PRINTF32_OUT ; Jump if too large

	mov	edx,eax 	; Copy to jump register
	sub	dl,@PFACT_LOW	; Convert to origin-@PFACT_LOW

	jmp	PFACT[edx*(type PFACT)] ; Take appropriate action


PRINTF32_ERR:			; All else
	int	03h		; Call ourselves

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_ZPAD:			; '0'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_ZPAD ; Mark as zero-padding

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_PLUS:			; '+'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_PLUS ; Mark as plus sign prefixing

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_LEFT:			; '-'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_LEFT ; Mark as left-justifying output

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_0X:			; '0'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_0X ; Mark as 0x prefixing

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_COMMA: 		; ','
	or	[RBP].PF2_LCL.PF_FLAG,@PF_COMMA ; Mark as inserting commas

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_BLANK: 		; ' '
	or	[RBP].PF2_LCL.PF_FLAG,@PF_BLNK ; Mark as blank-prefixing

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_VWID:			; '*'
	call	PF_GETVALZX	; Get next argument value into EAX

	jmp	short PRINTF32_WIDCOM ; Join common code


PRINTF32_WID:			; '1' to '9'
	dec	RSI		; Back off to first digit

	mov	ecx,10		; Convert as decimal
	call	BASE2BIND	; Return value in EAX, CF significant
;;;;;;; jc	short PRINTF32_ERR ; Jump if error
PRINTF32_WIDCOM:
	mov	[RBP].PF2_LCL.PF_WIDTH,RAX ; Save for later use

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_PREC:			; '.'
	cmp	ds:[RSI].LO,'*' ; Get precision from next arg?
	jne	short PRINTF32_PREC1 ; Jump if not

	call	PF_GETVALZX	; Get next argument value into EAX
	inc	esi		; Skip over placeholder

	jmp	short PRINTF32_PREC2 ; Join common code

PRINTF32_PREC1:
	mov	ecx,10		; Convert as decimal
	call	BASE2BIND	; Return value in EAX, CF significant
;;;;;;; jc	short PRINTF32_ERR ; Jump if error
PRINTF32_PREC2:
	or	[RBP].PF2_LCL.PF_FLAG,@PF_PREC ; Mark as precision specified
	mov	[RBP].PF2_LCL.PF_PREC,RAX ; Save for later use

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_BYTE:			; 't'
	mov	[RBP].PF2_LCL.PF_ARGWID,1 ; Mark as byte size
	mov	[RBP].PF2_LCL.PF_ARGMSK,0FFh ; ...

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_WORD:			; 'h'
	mov	[RBP].PF2_LCL.PF_ARGWID,2 ; Mark as word size
	mov	[RBP].PF2_LCL.PF_ARGMSK,0FFFFh ; ...

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_DWORD: 		; 'l'
	mov	[RBP].PF2_LCL.PF_ARGWID,4 ; Mark as dword size
	mov	[RBP].PF2_LCL.PF_ARGMSK,0FFFFFFFFh ; ...

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_FAR:			; 'F'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_FAR ; Mark as far ptr to data

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_OFF16: 		; 'H'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_OFF16 ; Mark as 16-bit offset

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_OFF32: 		; 'L'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_OFF32 ; Mark as 32-bit offset

	jmp	PRINTF32_NEXT	; Join common code


PRINTF32_NEAR:			; 'N'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_NEAR ; Mark as near ptr to data

	jmp	PRINTF32_NEXT	; Join common code


; Character

PRINTF32_CHAR:			; 'c'
	call	PF_GETVAL	; Get next argument value into EAX
	mov	dl,al		; Copy to ouput register

	jmp	PRINTF32_OUT	; Jump if so


; Signed and unsigned decimal

PRINTF32_SDEC:			; 'd'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_SDEC ; Mark as signed decimal
PRINTF32_UDEC:			; 'u'
	call	PF_GETVAL	; Get next argument value into EAX
	jns	short @F	; Jump if non-negative

	test	[RBP].PF2_LCL.PF_FLAG,@PF_SDEC ; Izit signed decimal?
	jz	short @F	; Jump if not

	mov	dl,'-'          ; Copy to output register
	call	PDispChar	; Display char in DL
@@:
	xor	RDX,RDX 	; Assume not left-justified

	test	[RBP].PF2_LCL.PF_FLAG,@PF_LEFT ; Izit left-justified?
	jz	short @F	; Jump if not

	or	RDX,@DEC_LEFT	; Mark as left-justified
@@:
	test	[RBP].PF2_LCL.PF_FLAG,@PF_COMMA ; Izit inserting commas?
	jz	short @F	; Jump if not

	or	RDX,@DEC_COMMA	; Mark as inserting commas
@@:
	REGSAVE <RSI,RDI,ds>	; Save for a moment

	lea	RDI,MSG_PRINTFZ[-1] ; ES:eDI ==> output save area

	push	RDX		; Pass flags
	call	DD2DEC		; Convert EAX to decimal at units digit ES:eDI
				; Return with ES:eDI ==> next available digit
	lea	RSI,[RDI+1]	; Copy for output string

; Ensure minimum width/precision

	mov	RCX,[RBP].PF2_LCL.PF_PREC ; Get precision
	MAX	RCX,[RBP].PF2_LCL.PF_WIDTH ; Use larger of precision and width

; Find the length of the string

	push	ds		; Pass the selector
	push	RSI		; ...	   offset
	call	StrLen		; Return with length in eAX

; If the width/precision is larger than the string length,
; and the number is not left-justified, output blanks or zeros first

	test	[RBP].PF2_LCL.PF_FLAG,@PF_LEFT ; Izit left-justified?
	jnz	short PRINTF32_DEC1 ; Jump if so

	sub	RCX,RAX 	; Is there a leading component?
	jbe	short PRINTF32_DEC1 ; Jump if not

	mov	dl,'0'          ; Assume we're padding with zeros

	test	[RBP].PF2_LCL.PF_FLAG,@PF_ZPAD ; Are we padding with zeros?
	jnz	short @F	; Jump if so

	mov	dl,' '          ; Pad with blanks
@@:
	call	PDispChar	; Display char in DL

	loop	@B		; Jump if more leading chars
PRINTF32_DEC1:
	push	es		; Pass segment of string
	push	RSI		; ...  offset ...
	call	DispASCIIZ	; Display ASCIIZ string

	REGREST <ds,RDI,RSI>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	PRINTF32_NEXTTYPE ; Go around again


; Octal

PRINTF32_OCT:			; 'o'
	mov	[RBP].PF2_LCL.PF_T1,3	; Rotate amount
	mov	[RBP].PF2_LCL.PF_T2,07h ; Mask value

	jmp	short PRINTF32_HEXCOM ; Join common code


; Binary

PRINTF32_BIN:			; 'b'
	mov	[RBP].PF2_LCL.PF_T1,1	; Rotate amount
	mov	[RBP].PF2_LCL.PF_T2,01h ; Mask value

	jmp	short PRINTF32_HEXCOM ; Join common code


; Lower and uppercase hex

PRINTF32_LHEX:			; 'x'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_LHEX ; Mark as lowercase hex
PRINTF32_UHEX:			; 'X'
	mov	[RBP].PF2_LCL.PF_T1,4	; Rotate amount
	mov	[RBP].PF2_LCL.PF_T2,0Fh ; Mask value
PRINTF32_HEXCOM:
	call	PF_GETVAL	; Get next argument value into EAX
	mov	edx,eax 	; Copy to safe register

	btr	[RBP].PF2_LCL.PF_FLAG,$PF_LHEX ; Izit lowercase hex?
	lea	RBX,PF_XLATLO	; Assume it's lowercase
	jc	short @F	; Jump if so

	lea	RBX,PF_XLATHI	; Assume it's uppercase
@@:

; Ensure minimum width/precision

	mov	RCX,[RBP].PF2_LCL.PF_PREC ; Get precision
	MAX	RCX,[RBP].PF2_LCL.PF_WIDTH ; Use larger of precision and width

; Shift value into high-order depending upon width

	cmp	RCX,8		; Izit too wide?
	jae	short @F	; Jump if so

	bsr	eax,edx 	; Get index of highest-order bit
	jz	short @F	; Jump if it's all zero

	add	eax,4-1+1	; Round up to nearest (origin-1)
;;;;;;; and	eax,not (4-1)	; ...multiple of four
	shr	eax,2-0 	; Convert from bits to hex digits
				; eAX =  1  2  3  4  5	6  7  8
	MAX	ecx,eax 	; Use larger
				; eCX =  1  2  3  4  5	6  7  8
	push	RCX		; Save width

	sub	RCX,8		; Subtract from 8
	neg	RCX		; eCX =  7  6  5  4  3	2  1  0
	shl	RCX,2		; eCX = 28 24 20 16 12	8  4  0
	shl	edx,cl		; Shift to high-order

	pop	RCX		; Restore
@@:
PRINTF32_HEX_NEXT:
	push	RCX		; Save for a moment

	mov	cl,[RBP].PF2_LCL.PF_T1.LO ; Get rotate amount
	rol	edx,cl		; Shift out next digit

	pop	RCX		; Restore

	mov	al,dl		; Copy to temp register
	and	al,[RBP].PF2_LCL.PF_T2.LO ; Isolate the digit
	xlat	PF_XLATLO[RBX]	; Translate it

	push	RDX		; Save for a moment

	mov	dl,al		; Copy to output register
	call	PDispChar	; Display char in DL

	pop	RDX		; Restore

	loop	PRINTF32_HEX_NEXT ; Jump if more width/precision

	jmp	PRINTF32_NEXTTYPE ; Go around again


; String

PRINTF32_STR8:			; 's'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_STR ; Mark as type string

	call	PF_GETADDR	; Get next argument into GS:eAX as address
	assume	gs:nothing	; Tell the assembler about it

	push	RSI		; Save for a moment

	mov	RSI,RAX 	; GS:eSI ==> string
	mov	RCX,[RBP].PF2_LCL.PF_PREC ; Get precision

	test	[RBP].PF2_LCL.PF_FLAG,@PF_PREC ; Is precision specified?
	jnz	short @F	; Jump if so

	mov	RCX,-1		; Use maximum loop value
@@:
	JRCXZ	PRINTF32_STR8B	; Jump if it's empty
PRINTF32_STR8A:
	lods	gs:[RSI].LO	; Get next character

	cmp	al,0		; Izit EOS?
	je	short PRINTF32_STR8B ; Jump if so

	mov	dl,al		; Copy to output register
	call	PDispChar	; Display char in DL

	cmp	[RBP].PF2_LCL.PF_WIDTH,0 ; Izit done?
	je	short @F	; Jump if so

	dec	[RBP].PF2_LCL.PF_WIDTH	; Count out another
@@:
	loop	PRINTF32_STR8A	; Go around again
PRINTF32_STR8B:
	jmp	short PRINTF32_STRCOM ; Join common code


PRINTF32_STR16: 		; 'S'
	or	[RBP].PF2_LCL.PF_FLAG,@PF_STR ; Mark as type string

	call	PF_GETADDR	; Get next argument into GS:eAX as address
	assume	gs:nothing	; Tell the assembler about it

	push	RSI		; Save for a moment

	mov	RSI,RAX 	; GS:eSI ==> string
	mov	RCX,[RBP].PF2_LCL.PF_PREC ; Get precision

	test	[RBP].PF2_LCL.PF_FLAG,@PF_PREC ; Is precision specified?
	jnz	short @F	; Jump if so

	mov	RCX,-1		; Use maximum loop value
@@:
	JRCXZ	PRINTF32_STR16B ; Jump if it's empty
PRINTF32_STR16A:
	lods	gs:[RSI].ELO	; Get next character

	cmp	ax,0		; Izit EOS?
	je	short PRINTF32_STR16B ; Jump if so

	mov	dl,al		; Copy to output register
	call	PDispChar	; Display char in DL

	cmp	[RBP].PF2_LCL.PF_WIDTH,0 ; Izit done?
	je	short @F	; Jump if so

	dec	[RBP].PF2_LCL.PF_WIDTH	; Count out another
@@:
	loop	PRINTF32_STR16A ; Go around again
PRINTF32_STR16B:
PRINTF32_STRCOM:
	mov	RCX,[RBP].PF2_LCL.PF_WIDTH ; Get remaining width
	JRCXZ	PRINTF32_STRCOM1 ; Jump if done

	mov	dl,' '          ; Get trailing blank
@@:
	call	PDispChar	; Display char in DL

	loop	@B		; Jump if more blanks to display
PRINTF32_STRCOM1:
	pop	RSI		; Restore

	jmp	PRINTF32_NEXTTYPE ; Join common code


PRINTF32_EXIT:
	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it
	popad			; Restore

	mov	RAX,[RBP].PF2_LCL.PF_CNT ; Return # chars printed

	add	RSP,type PF_STR ; Strip local variables from stack
	pop	RBP		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% LPRINTF&WID endp		; End LPRINTF&WID procedure
	NPROC	PF_GETADDR -- Printf Get Argument As Address
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument as address

Types		Modifiers
-------------------------
s		t l h a F
A S G M g m	t l h a F L H N

On entry:

SS:eBP	==>	PF_STR
FS:eDI	==>	argument list

On exit:

FS:eDI	==>	(updated)
GS:EAX	=	address

|

	test	[RBP].PF2_LCL.PF_FLAG,@PF_FAR ; Izit far ptr to data?
	jz	short PF_GETADDR_STR_NEAR ; Jump if not

	cmp	[RBP].PF2_LCL.PF_ARGWID,4 ; Izit 16:32?
	je	short PF_GETADDR_STR_FAR32 ; Jump if so

	movzx	eax,fs:[RDI].VOFF ; Get the offset
	mov	gs,fs:[RDI].VSEG ; ...	    segment
	assume	gs:nothing	; Tell the assembler about it

	add	RDI,2+2 	; Skip over it

	jmp	short PF_GETADDR_STR_FAR_COM ; Join common code


PF_GETADDR_STR_FAR32:
	mov	eax,fs:[RDI].FOFF ; Get the offset
	mov	gs,fs:[RDI].FSEL ; ...	    segment
	assume	gs:nothing	; Tell the assembler about it

	add	RDI,4+4 	; Skip over it
PF_GETADDR_STR_FAR_COM:
	jmp	short PF_GETADDR_EXIT ; Join common exit code


PF_GETADDR_STR_NEAR:
	xor	ax,ax		; A convenient zero
	mov	gs,ax		; Address it
	assume	gs:nothing	; Tell the assembler about it

	mov	eax,fs:[RDI]	; Get argument
	and	eax,[RBP].PF2_LCL.PF_ARGMSK ; Isolate the relevant portion
	add	RDI,[RBP].PF2_LCL.PF_ARGWID ; Skip over the argument
PF_GETADDR_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETADDR endp 		; End PF_GETADDR procedure
	NPROC	PF_GETVAL -- Printf Get Argument Value
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument value.

Types		Modifiers
-------------------------
c		t l h
d u x X o b	t l h

On entry:

SS:eBP	==>	PF_STR
FS:eDI	==>	argument list

On exit:

EAX	=	argument
FS:eDI	==>	(updated)
SF	=	1 if negative
	=	0 if non-negative

|

	push	edx		; Save register

	mov	eax,fs:[RDI]	; Get argument
	and	eax,[RBP].PF2_LCL.PF_ARGMSK ; Isolate the relevant portion
	add	RDI,[RBP].PF2_LCL.PF_ARGWID ; Skip over the argument
	mov	edx,eax 	; Copy for sign test

	test	[RBP].PF2_LCL.PF_FLAG,@PF_SDEC ; Izit signed extended?
	jz	short PF_GETVAL_COM ; Jump if not

	cmp	[RBP].PF2_LCL.PF_ARGWID,4 ; Izit dword argument size?
	je	short PF_GETVAL_COM ; Jump if so

	cmp	[RBP].PF2_LCL.PF_ARGWID,2 ; Izit word argument size?
	je	short PF_GETVAL_WORD ; Jump if so

	movsx	eax,al		; Sign-extend into high-order bits
	shl	edx,24		; Shift sign to high-order word

	jmp	short PF_GETVAL_COM ; Join common code

PF_GETVAL_WORD:
	movsx	eax,ax		; Sign-extend into high-order bits
	shl	edx,16		; Shift sign to high-order word
PF_GETVAL_COM:
PF_GETVAL_EXIT:
	test	edx,edx 	; Check the sign

	pop	edx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETVAL endp			; End PF_GETVAL procedure
	NPROC	PF_GETVALZX -- Printf Get Argument Value, Zero-extended
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument value, zero-extended.

On entry:

SS:eBP	==>	PF_STR
FS:eDI	==>	argument list

On exit:

EAX	=	argument
FS:eDI	==>	(updated)

|

	mov	eax,fs:[RDI]	; Get argument
	and	eax,[RBP].PF2_LCL.PF_ARGMSK ; Isolate the relevant portion
	add	RDI,[RBP].PF2_LCL.PF_ARGWID ; Skip over the argument size

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETVALZX endp		; End PF_GETVALZX procedure
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

Convert the number at DS:SI in base ECX to binary.

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
	NPROC	StrLen -- String Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length

On exit:

eAX	=	length

|

StrLen_str struc

%	DOFF	?		; Caller's eBP
%	DOFF	?		; ...	   eIP
% StrLenSrc DVEC ?		; Ptr to source

StrLen_str ends

	push	RBP		; Prepare to address the stack
	mov	RBP,RSP 	; Hello, Mr. Stack

	REGSAVE <RCX,RDI,es>	; Save registers

	les	RDI,DVECTYP ptr [RBP].StrLenSrc ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	al,0		; Search for this
	mov	RCX,-1		; We know (or hope) it's there
  repne scas	es:[RDI].LO	; Search for it

	mov	RAX,-(1+1)	; One for starting -1, one for trailing zero
	sub	RAX,RCX 	; Subtract to get length

	REGREST <es,RDI,RCX>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	RBP		; Restore

	ret	DVECSIZ 	; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLen	endp			; End StrLen procedure
	NPROC	DispChar -- Display Character
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display character.

On entry:

DL	=	char to display
SS:eBP	==>	PF2_STR

|

	push	RAX		; Save register

	DOSCALL @CHROUT 	; Display character in DL

	pop	RAX		; Restore

	inc	[RBP].PF2_LCL.PF_CNT ; Count in another char printed

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispChar endp			; End DispChar procedure
	NPROC	SaveChar -- Save Character
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save character (called iff SPRINTF)

On entry:

DL	=	char to save
SS:eBP	==>	PF2_STR

|

	REGSAVE <RAX,RDI,es>	; Save registers

	les	RDI,DVECTYP ptr [RBP].PF2_OUT_VEC ; ES:eDI ==> output save area
	assume	es:nothing	; Tell the assembler about it

	mov	al,dl		; Copy character to save
	stos	es:[RDI].LO	; Save it
%	mov	[RBP].PF2_OUT_VEC.OVEC,RDI ; Save back for later use

	inc	[RBP].PF2_LCL.PF_CNT ; Count in another char printed

	REGREST <es,RDI,RAX>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SaveChar endp			; End SaveChar procedure
	NPROC	FileChar -- File Character
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

File character (called iff FPRINTF)

On entry:

DL	=	char to save
SS:eBP	==>	PF2_STR

|

	REGSAVE <eax,fs>	; Save registers

	mov	ax,es		; Get DGROUP data segment
	mov	fs,ax		; Address it
	assume	fs:PGROUP	; Tell the assembler about it

	xor	eax,eax 	; Zero to use as dword
	mov	RAX,BufCnt	; Get current buffer count

	cmp	RAX,size MSG_BUFFER ; Izit at the end?
	jb	short @F	; Jump if not

	push	[RBP].PF2_HNDL	; Pass file handle
	call	FPRINTFLUSH	; Flush the buffer

	mov	RAX,BufCnt	; Get current buffer count
@@:
	mov	MSG_BUFFER[eax],dl ; Save in buffer

	inc	BufCnt		; Count in another char

	inc	[RBP].PF2_LCL.PF_CNT ; Count in another char printed

	REGREST <fs,eax>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FileChar endp			; End FileChar procedure
	NPROC	ExtChar -- External Write Character
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

External write character (called iff RPRINTF)

On entry:

DL	=	char to write
SS:eBP	==>	PF2_STR

|

	REGSAVE <eax,fs>	; Save registers

	mov	ax,es		; Get DGROUP data segment
	mov	fs,ax		; Address it
	assume	fs:PGROUP	; Tell the assembler about it

	call	[RBP].PF2_EXT	; Call external routine

	inc	[RBP].PF2_LCL.PF_CNT ; Count in another char printed

	REGREST <fs,eax>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ExtChar endp			; End ExtChar procedure
	NPROC	DispASCIIZ -- Display ASCIIZ String
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ACIIZ string.

|

DA_STR	struc

% DA_RBP DOFF	?		; Caller's eBP
%	DOFF	?		; ...	   eIP
% DA_VEC DVEC	?		; Ptr to text

DA_STR	ends

	push	RBP		; Prepare to address the stack
	mov	RBP,RSP 	; Hello, Mr. Stack

	REGSAVE <RAX,RDX,RSI,ds> ; Save registers

	lds	RSI,DVECTYP ptr [RBP].DA_VEC ; DS:eSI ==> ASCIIZ string
	mov	RBP,[RBP].DA_RBP ; Restore eBP for PDispChar
DispASCIIZNext:
	lods	ds:[RSI].LO	; Get next character

	cmp	al,0		; Izit EOS?
	je	short DispASCIIZExit ; Jump if so

	mov	dl,al		; Copy to @CHROUT register
	call	PDispChar	; Display the character in DL

	jmp	DispASCIIZNext	; Go around again

DispASCIIZExit:
	REGREST <ds,RSI,RDX,RAX> ; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	pop	RBP		; Restore

	ret	DVECSIZ 	; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispASCIIZ endp 		; End DispASCIIZ procedure
	NPROC	DD2DEC -- Convert EAX To Decimal At ES:eDI
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert EAX to decimal at ES:eDI.

On entry:

EAX	=	# to convert
ES:eDI	==>	save area

On exit:

ES:eDI	==>	(incremented)

|

LDD2DEC_STR struc

% LDD2DEC_FVEC DVEC ?		; Address of caller's buffer
LDD2DEC_BUF db	14 dup (?)	; Local buffer big enough to handle
				; 4G with commas (4,xxx,xxx,xxx),0

LDD2DEC_STR ends


DD2DEC_STR struc

DD2DEC_LCL db  (type LDD2DEC_STR) dup (?) ; LDD2DEC_STR
%	DOFF	?		; Caller's eBP
%	DOFF	?		;	   eIP
% DD2DEC_FLG DOFF ?		; Flags

DD2DEC_STR ends

@LDD2DEC_SIZE equ size LDD2DEC_STR ; Size of local stack in bytes

	push	RBP		; Prepare to address the stack
	sub	RSP,@LDD2DEC_SIZE ; Make room on stack
	mov	RBP,RSP 	; Hello, Mr. Stack

	pushf			; Save flags

	REGSAVE <eax,ebx,ecx,edx,RSI,es> ; Save registers

	test	[RBP].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

	mov	[RBP].DD2DEC_LCL.LDD2DEC_FVEC.OVEC,RDI ; Save address of caller's buffer
	mov	[RBP].DD2DEC_LCL.LDD2DEC_FVEC.SVEC,es ; ...

	push	ss		; Setup ES for string operations
	pop	es		; ...
	assume	es:nothing	; Tell the assembler about it

	lea	RDI,[RBP].DD2DEC_LCL.LDD2DEC_BUF[(size LDD2DEC_BUF)-1] ; ES:eDI ==> buffer end
@@:
	xor	ecx,ecx 	; Initialize byte count
	xor	edx,edx 	; Zero high-order dword
	std			; String ops backwards
DD2DEC_COMMA:
	xor	ebx,ebx 	; Initialize comma count
DD2DEC_NEXT:
	div	CON10		; Split off another decimal digit
				; EAX = quotient
				; EDX = remainder
	xchg	eax,edx 	; Swap to display AL
	add	al,'0'          ; Convert to decimal ASCII
	stos	es:[RDI].LO	; Save in buffer
	inc	ecx		; Account for it
	mov	eax,edx 	; Copy to dividend register
	xor	edx,edx 	; Zero for next time

	and	eax,eax 	; Check the remainder
	jz	short DD2DEC_END ; Jump if that's all

	test	[RBP].DD2DEC_FLG,@DEC_COMMA ; Comma insertion requested?
	jz	short DD2DEC_NEXT ; Not this time

	inc	ebx		; Account for it

	cmp	ebx,3		; Izit time to comma-insert?
	jne	short DD2DEC_NEXT ; Not as yet

	push	eax		; Save for a moment
	mov	al,','          ; Separator
	stos	es:[RDI].LO	; Save in buffer
	pop	eax		; Restore

	inc	ecx		; Account for it

	jmp	DD2DEC_COMMA	; Go around again

DD2DEC_END:
	test	[RBP].DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

	lea	RSI,[RDI+1]	; SS:eSI ==> start of buffer
	les	RDI,DVECTYP ptr [RBP].DD2DEC_LCL.LDD2DEC_FVEC ; ES:eDI ==> caller's buffer
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
    rep movs	es:[RDI].LO,ss:[RSI].LO ; Move into caller's data area
@@:
	REGREST <es,RSI,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	popf			; Restore flags

	add	RSP,@LDD2DEC_SIZE ; Remove room from stack
	pop	RBP		; Restore

	ret	DOFFSIZ 	; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2DEC	endp			; End DD2DEC procedure
	NPROC	DG2HEX -- Convert Low-order Digit in AL to Hex At ES:eDI
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	RCX		; Save for a moment
	mov	RCX,1		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	RCX		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DG2HEX	endp			; End DG2HEX procedure
	NPROC	DB2HEX -- Convert AL to Hex At ES:eDI
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	RCX		; Save for a moment
	mov	RCX,2		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	RCX		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	endp			; End DB2HEX procedure
	NPROC	DW2HEX -- Convert AX to Hex At ES:eDI
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	RCX		; Save for a moment
	mov	RCX,4		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	RCX		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	endp			; End DW2HEX procedure
	NPROC	DD2HEX -- Convert EAX to Hex At ES:eDI
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	RCX		; Save for a moment
	mov	RCX,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	RCX		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPROC	BIN2HEX_SUB -- Binary To hex Subroutine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Binary to hex subroutine.

On entry:

EAX	=	number to convert
eCX	=	# digits to convert
ES:eDI	==>	output save area

On exit:

ES:eDI	==>	(updated)

|

	REGSAVE <eax,ebx,edx>	; Save registers

	pushf			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	RBX,PF_XLATHI	; XLAT table
	add	RDI,RCX 	; Skip to the end+1

	push	RDI		; Save to return

	dec	edi		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	PF_XLATHI[RBX]	; Convert to ASCII hex
	stos	es:[RDI].LO	; Save in output stream

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	RDI		; Restore

	popf			; Restore flags

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	ends			; End CODE segment

	MEND			; End PRINTF module
