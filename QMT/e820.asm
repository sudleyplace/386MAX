;' $Header:   P:/PVCS/MAX/QMT/MEM_MAIN.ASV   1.3   05 Jun 1998 14:03:24   BOB  $
	title	E820 -- Display E820 Values
	page	58,122
	name	E820

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1999 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, dword-aligned, stack,  class 'stack'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include ASCII.INC
	include PTR.INC
.list

PGROUP	group	CODE,DATA,STACK


STACK	segment use16 dword stack 'stack' ; Start STACK segment
STACK	ends		       ; End STACK segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
CODE	ends		       ; End CODE segment


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	public	MEMCNT
MEMCNT	dw	0		; Count if memory entries
	
	public	MSGTAB
MSGTAB	dw	offset PGROUP:MSG_UNK ; 00
	dw	offset PGROUP:MSG_MEM ; 01
	dw	offset PGROUP:MSG_RSV ; 02
	dw	offset PGROUP:MSG_REC ; 03
	dw	offset PGROUP:MSG_NVS ; 04

MB_STR	struc

MB_BASE dq	?		; Base address
MB_LEN	dq	?		; Length in bytes
MB_TYPE dd	?		; Memory type (see @MB_xxx below)

MB_STR	ends

@MB_UNK equ	00h		; Unknown memory type
@MB_MEM equ	01h		; Memory, available to OS
@MB_RSV equ	02h		; Reserved, not available (e.g. system ROM, memory-mapped device)
@MB_REC equ	03h		; ACPI Reclaim Memory (usable by OS after reading ACPI tables)
@MB_NVS equ	04h		; ACPI NVS Memory (OS is required to save this memory between NVS sessions)
@MB_MAX equ	06h		; Unknown memory type

	public	MEMBUF
MEMBUF	MB_STR	<>		; Buffer

	public	MSGHDR,MSGBUF
MSGHDR	db	'  Base    Length  Type',CR,LF
	db	'----------------------',CR,LF,EOS
;;;;;;; 	'12345678 12345678 '
MSGBUF	label	byte
MSGBUF1 db	'12345678 '
MSGBUF2 db	'12345678 '
	db	EOS

	public	MSG_UNK,MSG_MEM,MSG_RSV,MSG_REC,MSG_NVS
MSG_UNK db	'*** Unknown Memory ***',CR,LF,EOS
MSG_MEM db	'Memory',CR,LF,EOS
MSG_RSV db	'Reserved',CR,LF,EOS
MSG_REC db	'ACPI Reclaim Memory',CR,LF,EOS
MSG_NVS db	'ACPI NVS Memory',CR,LF,EOS

	public	MSG_COPY,MSG_UNSUP
MSG_COPY db	'E820     -- Display E820 Memory Values -- Version 1.00',CR,LF
	db	'  (C) Copyright 1999 Qualitas, Inc.  All Rights Reserved.',CR,LF,EOS
MSG_UNSUP db	'*** E820 not supported byt this BIOS.',CR,LF,EOS

	public	NUMBERS_HI
NUMBERS_HI db	'0123456789ABCDEF'

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	include PSP.INC

	NPPROC	E820 -- Display E820 Values
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display E820 Values

|

; Display our copyright notice

	DOSCALL @STROUT,MSG_COPY ; Display the flag
	
; See if the BIOS supports E820
	
	xor	ebx,ebx 	; Mark as start of map
E820_NEXT:
	mov	eax,0E820h	; Some BIOSes require high-order word to be zero
	mov	ecx,type MB_STR ; Size of buffer
	mov	edx,'SMAP'      ; Special value
	lea	di,MEMBUF	; ES:DI ==> buffer
	int	15h		; Request BIOS service
	jc	short E820_DONE ; Jump if no more data

	cmp	ebx,0		; Izit over?
	je	short E820_DONE ; Jump if no more data
	
	cmp	MEMCNT,0	; Izit the first time?
	jne	short @F	; Jump if not
	
	DOSCALL @STROUT,MSGHDR	; Display the header
@@:	
	inc	MEMCNT		; Mark as one more entry

	mov	eax,MEMBUF.MB_BASE.EDQLO ; Get base address
	lea	edi,MSGBUF1	; ES:EDI ==> otuput save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	eax,MEMBUF.MB_LEN.EDQLO ; Get length
	lea	edi,MSGBUF2	; ES:EDI ==> otuput save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSGBUF	; Display the message

	mov	eax,MEMBUF.MB_TYPE ; Get memory type
	
	cmp	eax,@MB_MAX	; Izit unknown type?
	jb	short @F	; Jump if not
	
	mov	eax,@MB_UNK	; Mark as unknown
@@:	   
	mov	dx,MSGTAB[eax*(type MSGTAB)] ; DS:DX ==> message
	DOSCALL @STROUT 	; Display the memory type

	jmp	E820_NEXT	; Go around again
	
	
E820_DONE:
	cmp	MEMCNT,0	; Izit unsupported?
	jne	short E820_EXIT ; Jump if not
	
	DOSCALL @STROUT,MSG_UNSUP ; Tell 'em the bad news
E820_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

E820	endp			; End E820 procedure
	NPPROC	DD2HEX -- Convert EAX to Hex At ES:EDI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <eax,ebx,edx>	; Save registers

	pushfd			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	ebx,NUMBERS_HI	; XLAT table
	add	edi,ecx 	; Skip to the end+1

	push	edi		; Save to return

	dec	edi		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	NUMBERS_HI[ebx] ; Convert to ASCII hex
	stos	es:[edi].LO	; Save in output stream

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	edi		; Restore

	popfd			; Restore flags

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	ends			; End CODE segment

	MEND	E820		; End E820 module
