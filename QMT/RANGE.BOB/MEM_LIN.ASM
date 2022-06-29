;' $Header:   P:/PVCS/MAX/QMT/MEM_LIN.ASV   1.0   05 Sep 1995 16:55:46   HENRY  $
	title	MEM_LIN -- MEMCHK Linked Inversion Coupling Fault Checking Routines
	page	58,122
	name	MEM_LIN

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

	include MEM_LIN.MAC
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

	extrn	ZMSG_LNKINV:byte

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

	extrn	CALIB_W0:tbyte
	extrn	CALIB_R0W1R1:tbyte
	extrn	CALIB_R1W0R0DN:tbyte
	extrn	CALIB_R0DN:tbyte

	public	PCALIB_LIN
PCALIB_LIN PCALIB_STR <@CALIB_LIN_LEN,DGROUP:CALIB_LIN> ; Calibration struc for
				; this module
	public	LNKINV_ACT
LNKINV_ACT dw	PGROUP:MARCHYB	; Byte-wide memory
	dw	PGROUP:MARCHYW	; Word-...
	dw	PGROUP:MARCHYD	; Dword-...

DATA	ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

	public	CALIB_LIN
CALIB_LIN label word		; Start of calibration ptrs for this module

CALIBSEG ends			; End CALIBSEG segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	DISP_STATLZ:near

	extrn	FMT_W0:near
	extrn	FMT_R0W1R1:near
	extrn	FMT_R1W0R0DN:near
	extrn	FMT_R0DN:near

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

	NPPROC	TEST_LNKINV -- Test for Linked Inversion Coupling Faults
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for Linked Inversion Coupling Faults.

This routine runs in Protected Mode.

CF	=	0 if all went well
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

; Display the title line

	push	offset DGROUP:ZMSG_LNKINV ; Pass as offset of the line
	call	DISP_STATLZ	; Display on the status line with attributes

	mov	es,SEL_4GB	; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	ax,TIMECNT	; Get # entries
	mov	RCNT,ax 	; Save to decrement
	xor	bx,bx		; Initialize index into TIMETAB
TEST_LNKINV_NEXT_ENTRY:
	test	TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	jnz	short TEST_LNKINV_LOOP ; Jump if so

; Depending upon the word size, use Byte, Word, or Dword reads and writes

	movzx	eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	shr	eax,3-0 	; Convert from bits per byte to bytes
	mov	BPU,eax 	; Save as bytes per unit

	call	FMT_BLK 	; Format and display block information

	mov	ecx,TIMETAB[bx].TT_LEN ; Get length in bytes

	bsf	eax,BPU 	; Get log base 2 into EAX
	call	LNKINV_ACT[eax*(type LNKINV_ACT)] ; Get address of action routine
	jc	short TEST_LNKINV_ERR ; Jump if something went wrong

	call	CHECK_KEYS	; See if any interesting keys were pressed
	jne	short TEST_LNKINV_CLC ; Jump if so
TEST_LNKINV_LOOP:
	add	bx,size TT_STR	; Skip to next entry

	dec	RCNT		; Decrement # remaining entries
	jnz	short TEST_LNKINV_NEXT_ENTRY ; Jump if more entries
TEST_LNKINV_CLC:

; Display done or interrupted message

	call	FMT_DONE	; Tell 'em we're finished

	clc			; Indicate all went well

	jmp	short TEST_LNKINV_EXIT ; Join common error code

TEST_LNKINV_ERR:
	stc			; Indicate something went wrong
TEST_LNKINV_EXIT:
	REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_LNKINV endp		; End TEST_LNKINV procedure
	NPPROC	MARCHYB -- March Y for Byte-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March Y for byte-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	LINMAC	MARCHY,0,LO,al,B

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHYB endp			; End MARCHYB procedure
	NPPROC	MARCHYW -- March Y for Word-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March Y for word-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	LINMAC	MARCHY,1,ELO,ax,W

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHYW endp			; End MARCHYW procedure
	NPPROC	MARCHYD -- March Y for Dword-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March Y for a dword-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	LINMAC	MARCHY,2,EDD,eax,D

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHYD endp			; End MARCHYD procedure

CODE	ends			; End CODE segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

@CALIB_LIN_LEN equ ($-CALIB_LIN)/(type CALIB_LIN) ; # calibration entries

CALIBSEG ends			; End CALIBSEG segment

	MEND			; End MEM_LIN module
