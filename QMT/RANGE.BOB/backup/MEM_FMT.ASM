;' $Header:   P:/PVCS/MAX/QMT/MEM_FMT.ASV   1.0   05 Sep 1995 16:55:42   HENRY  $
	title	MEM_FMT -- MEMCHK Formatting Routines
	page	58,122
	name	MEM_FMT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC

	include MEM_FMT.INC
	include MEM_SEGS.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	GL2_FLAG:word
	include MEM_GL2.INC

	extrn	TIMETAB:tbyte
	include MEM_TIME.INC

	extrn	REG1UP:dword
	extrn	DELAYNUM:dword

	extrn	ZMSG_CURPATB:byte
	extrn	ZMSG_CURPATB1:byte
	extrn	ZMSG_CURPATW:byte
	extrn	ZMSG_CURPATW1:byte
	extrn	ZMSG_CURPATD:byte
	extrn	ZMSG_CURPATD1:byte

	extrn	MSG_DMSEC:byte,@DMSEC_LEN:abs

EMAC	macro	NAM,SUF,ALEN

	extrn	NAM:byte
	extrn	NAM&A:byte
	extrn	NAM&B:byte
ifnb <SUF>
	extrn	NAM&SUF:byte	; An extra suffix
endif				; IFNB <SUF>
ifnb <ALEN>
	irp	XX,<ALEN>
	extrn	NAM&&XX:abs	; An extra suffix
	endm			; IRP
else
	extrn	NAM&_LEN:abs
endif				; IFNB <ALEN>
	endm			; EMAC

	EMAC	MSG_DELAY
	EMAC	MSG_R0
	EMAC	MSG_R0W1
	EMAC	MSG_R0W1R1
	EMAC	MSG_R0W1R1W0R0W1,Z,<_LEN1,_LEN2>
	EMAC	MSG_R0W1W0
	EMAC	MSG_R1
	EMAC	MSG_R1W0
	EMAC	MSG_R1W0R0
	EMAC	MSG_R1W0W1
	EMAC	MSG_R1W0W1W0
	EMAC	MSG_W0
	EMAC	MSG_W1

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	DISP_STATL:near
	extrn	BIN2DVAL:near
	extrn	BIN2BIT:near
	extrn	DW2DEC:near

	extrn	DISP_CURPAT:near

FMT_MAC macro	NAM,N,D1,D2,SP

	NPPROC	FMT_&NAM -- Format and Display NAM Message
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display NAM message.

On entry:

BX	=	index into TIMETAB
EDX	=	N in bytes

|

	REGSAVE <eax,di,es>	; Save registers

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	lea	di,MSG_&N&D1	; ES:DI ==> output save area
	call	BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	add	eax,edx 	; EAX ==> A[N]
	dec	eax		; EAX ==> A[N-1] (high-order byte)
	lea	di,MSG_&N&D2	; ES:DI ==> output save area
	call	BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

ifb <SP>
	push	offset ds:MSG_&N ; Pass address of local buffer
	push	MSG_&N&_LEN	; Pass message length in bytes
	call	DISP_STATL	; Display on the status line
else
	push	offset ds:MSG_&N ; Pass address of local buffer
	push	MSG_&N&_LEN1	; Pass message length in bytes
	call	DISP_STATL	; Display on the status line

	push	offset ds:MSG_&N&Z ; Pass address of local buffer
	push	MSG_&N&_LEN2	; Pass message length in bytes
	call	DISP_STATL	; Display on the status line
endif
	REGREST <es,di,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_&NAM endp			; End FMT_&NAM procedure

	endm			; FMT_MAC

	FMT_MAC R0	    , R0	  , A, B
	FMT_MAC R0DN	    , R0	  , B, A
	FMT_MAC R0W1	    , R0W1	  , A, B
	FMT_MAC R0W1DN	    , R0W1	  , B, A
	FMT_MAC R0W1R1	    , R0W1R1	  , A, B
	FMT_MAC R0W1R1DN    , R0W1R1	  , B, A
	FMT_MAC R0W1R1W0R0W1, R0W1R1W0R0W1, A, B, SP
	FMT_MAC R0W1W0	    , R0W1W0	  , A, B
	FMT_MAC R0W1W0DN    , R0W1W0	  , B, A
	FMT_MAC R1	    , R1	  , A, B
	FMT_MAC R1DN	    , R1	  , B, A
	FMT_MAC R1W0	    , R1W0	  , A, B
	FMT_MAC R1W0DN	    , R1W0	  , B, A
	FMT_MAC R1W0R0	    , R1W0R0	  , A, B
	FMT_MAC R1W0R0DN    , R1W0R0	  , B, A
	FMT_MAC R1W0W1	    , R1W0W1	  , A, B
	FMT_MAC R1W0W1DN    , R1W0W1	  , B, A
	FMT_MAC R1W0W1W0DN  , R1W0W1W0	  , B, A
	FMT_MAC W0	    , W0	  , A, B
	FMT_MAC W0DN	    , W0	  , B, A
	FMT_MAC W1	    , W1	  , A, B

	NPPROC	FMT_DELAY -- Format and Display DELAY Message
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display DELAY message.

On entry:

BX	=	index into TIMETAB
EDX	=	N in bytes

|

	REGSAVE <eax,di,es>	; Save registers

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,DELAYNUM.ELO ; Get the current delay # (in milliseconds)
	lea	di,MSG_DELAYA	; ES:DI ==> output save area
	push	@DEC_LEFT	; Mark as left-justified
	call	DW2DEC		; Convert AX to decimal at ES:DI
				; Return with ES:DI ==> next byte

; Append the tail

	lea	si,MSG_DMSEC	; DS:SI ==> trailing text (plural)
	mov	cx,@DMSEC_LEN	; Length of ...
    rep movs	es:[di].LO,MSG_DMSEC[si] ; Append the tail

	push	offset ds:MSG_DELAY ; Pass address of local buffer
	push	MSG_DELAY_LEN	; Pass message length in bytes
	call	DISP_STATL	; Display on the status line

	REGREST <es,di,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_DELAY endp			; End FMT_DELAY procedure
	NPPROC	FMT_PATTERNB -- Format and Display Current Byte Pattern
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current byte pattern.

|

	test	GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	jz	short FMT_PATTERNB_EXIT ; Jump if not

	REGSAVE <ax,cx,di,es>	; Save registers

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	al,REG1UP.LO	; Get the pattern value to display
	lea	di,ZMSG_CURPATB1 ; ES:DI ==> output save area
	mov	cx,8		; CX = # bits to display
	call	BIN2BIT 	; Convert EAX to CX bits

	push	offset ds:ZMSG_CURPATB ; Pass offset of message
	call	DISP_CURPAT	; Display the current pattern

	REGREST <es,di,cx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it
FMT_PATTERNB_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERNB endp		; End FMT_PATTERNB procedure
	NPPROC	FMT_PATTERNW -- Format and Display Current Word Pattern
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current word pattern.

|

	test	GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	jz	short FMT_PATTERNW_EXIT ; Jump if not

	REGSAVE <ax,cx,di,es>	; Save registers

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,REG1UP.ELO	; Get the pattern value to display
	lea	di,ZMSG_CURPATW1 ; ES:DI ==> output save area
	mov	cx,16		; CX = # bits to display
	call	BIN2BIT 	; Convert EAX to CX bits

	push	offset ds:ZMSG_CURPATW ; Pass offset of message
	call	DISP_CURPAT	; Display the current pattern

	REGREST <es,di,cx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it
FMT_PATTERNW_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERNW endp		; End FMT_PATTERNW procedure
	NPPROC	FMT_PATTERND -- Format and Display Current Dword Pattern
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current dword pattern.

|

	test	GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	jz	short FMT_PATTERND_EXIT ; Jump if not

	REGSAVE <eax,cx,di,es>	; Save registers

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	eax,REG1UP	; Get the pattern value to display
	lea	di,ZMSG_CURPATD1 ; ES:DI ==> output save area
	mov	cx,32		; CX = # bits to display
	call	BIN2BIT 	; Convert EAX to CX bits

	push	offset ds:ZMSG_CURPATD ; Pass offset of message
	call	DISP_CURPAT	; Display the current pattern

	REGREST <es,di,cx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it
FMT_PATTERND_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERND endp		; End FMT_PATTERND procedure

CODE	ends			; End CODE segment

	MEND			; End MEM_FMT module
