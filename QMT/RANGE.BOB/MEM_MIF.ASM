;' $Header$
	title	MEM_MIF -- MEMCHK Moving Inversion Fault Checking Routines
	page	58,122
	name	MEM_MIF

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
	include ALLMEM.INC

	include MEM_MIF.MAC
	include MEM_SEGS.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	GL3_FLAG:word
	include MEM_GL3.INC

	extrn	CNT_FLAG:word
	include MEM_CNT.INC

	extrn	SEL_4GB:word

	extrn	TIMETAB:tbyte,TIMECNT:word
	include MEM_TIME.INC

	extrn	ZMSG_MOVI:byte

	extrn	BPU:dword
	extrn	RCNT:word

	extrn	NMIOFF:word
	extrn	ZAPOFF:word
	extrn	RESOFF:word
	extrn	NMIRET:word

	extrn	REG0UP:dword
	extrn	REG0DN:dword
	extrn	REG1UP:dword
	extrn	REG1DN:dword
	extrn	PATCNT:word
	extrn	PATOFF:word
	extrn	NUMOPERS:qword
	extrn	NMIADDR:dword

	extrn	CALIB_W0DN:tbyte
	extrn	CALIB_R0W1R1:tbyte
	extrn	CALIB_R1W0R0:tbyte
	extrn	CALIB_R0W1R1DN:tbyte
	extrn	CALIB_R1W0R0DN:tbyte

	public	PCALIB_MIF
PCALIB_MIF PCALIB_STR <@CALIB_MIF_LEN,DGROUP:CALIB_MIF> ; Calibration struc for
				; this module
	public	MOVI_ACT
MOVI_ACT dw	PGROUP:MOVIB	; Byte-wide memory
	dw	PGROUP:MOVIW	; Word-...
	dw	PGROUP:MOVID	; Dword-...

DATA	ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

	public	CALIB_MIF
CALIB_MIF label word		; Start of calibration ptrs for this module

CALIBSEG ends			; End CALIBSEG segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	DISP_STATLZ:near

	extrn	FMT_W0DN:near
	extrn	FMT_R0W1R1:near
	extrn	FMT_R1W0R0:near
	extrn	FMT_R0W1R1DN:near
	extrn	FMT_R1W0R0DN:near

	extrn	FMT_BLK:near
	extrn	FMT_DONE:near

	extrn	FMT_PATTERNB:near
	extrn	FMT_PATTERNW:near
	extrn	FMT_PATTERND:near

	extrn	DISP_ERRB:near
	extrn	DISP_ERRW:near
	extrn	DISP_ERRD:near
	extrn	DISP_NMIERR:near
	extrn	DISP_OPERS:near

	extrn	ZAPREST:near

	extrn	CHECK_HALT:near
	extrn	CHECK_KEYS:near

	NPPROC	TEST_MOVI -- Test for Moving Inversion Faults
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for Moving Inversion Faults.

This routine runs in Protected Mode.

CF	=	0 if all went well
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

; Display the title line

	push	offset DGROUP:ZMSG_MOVI ; Pass as offset of the line
	call	DISP_STATLZ	; Display on the status line with attributes

	mov	es,SEL_4GB	; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	ax,TIMECNT	; Get # entries
	mov	RCNT,ax 	; Save to decrement
	xor	bx,bx		; Initialize index into TIMETAB
TEST_MOVI_NEXT_ENTRY:
	test	TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	jnz	short TEST_MOVI_LOOP ; Jump if so

; Depending upon the word size, use Byte, Word, or Dword reads and writes

	movzx	eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	shr	eax,3-0 	; Convert from bits per byte to bytes
	mov	BPU,eax 	; Save as bytes per unit

	call	FMT_BLK 	; Format and display block information

	mov	ecx,TIMETAB[bx].TT_LEN ; Get length in bytes

	bsf	eax,BPU 	; Get log base 2 into EAX
	call	MOVI_ACT[eax*(type MOVI_ACT)] ; Get address of action routine
	jc	short TEST_MOVI_ERR ; Jump if something went wrong

	call	CHECK_KEYS	; See if any interesting keys were pressed
	jne	short TEST_MOVI_CLC ; Jump if so
TEST_MOVI_LOOP:
	add	bx,size TT_STR	; Skip to next entry

	dec	RCNT		; Decrement # remaining entries
	jnz	short TEST_MOVI_NEXT_ENTRY ; Jump if more entries
TEST_MOVI_CLC:

; Display done or interrupted message

	call	FMT_DONE	; Tell 'em we're finished

	clc			; Indicate all went well

	jmp	short TEST_MOVI_EXIT ; Join common error code

TEST_MOVI_ERR:
	btr	GL3_FLAG,$GL3_ERRCURB ; Is there an error in current block?
	jc	short TEST_MOVI_NEXT_ENTRY ; Jump if so (start over again)

	stc			; Indicate something went wrong
TEST_MOVI_EXIT:
	REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_MOVI endp			; End TEST_MOVI procedure
	NPPROC	MOVIB -- Moving Inversion Fault Test for Byte-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Moving Inversion Test for byte-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	MIFMAC	MOVI,0,LO,al,B

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVIB	endp			; End MOVIB procedure
	NPPROC	MOVIW -- Moving Inversion Fault Test for Word-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Moving Inversion Test for word-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	MIFMAC	MOVI,1,ELO,ax,W

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVIW	endp			; End MOVIW procedure
	NPPROC	MOVID -- Moving Inversion Fault Test for Dword-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Moving Inversion Test for a dword-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	MIFMAC	MOVI,2,EDD,eax,D

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVID	endp			; End MOVID procedure

CODE	ends			; End CODE segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

@CALIB_MIF_LEN equ ($-CALIB_MIF)/(type CALIB_MIF) ; # calibration entries

CALIBSEG ends			; End CALIBSEG segment

	MEND			; End MEM_MIF module
