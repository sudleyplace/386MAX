;' $Header:   P:/PVCS/MAX/QMT/MEM_UTF.ASV   1.0   05 Sep 1995 16:55:42   HENRY  $
	title	MEM_UTF -- MEMCHK (Unlinked) Transition Fault Checking Routines
	page	58,122
	name	MEM_UTF

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

	include MEM_UTF.MAC
	include MEM_SEGS.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	CNT_FLAG:word
	include MEM_CNT.INC

	extrn	SEL_4GB:word

	extrn	TIMETAB:tbyte,TIMECNT:word
	include MEM_TIME.INC

	extrn	ZMSG_UNLTRN:byte

	extrn	BPU:dword
	extrn	RCNT:word

	extrn	NMIOFF:word
	extrn	ZAPOFF:word

	extrn	REG0UP:dword
	extrn	REG0DN:dword
	extrn	REG1UP:dword
	extrn	REG1DN:dword
	extrn	NUMOPERS:qword
	extrn	NMIADDR:dword

	extrn	CALIB_W0:tbyte
	extrn	CALIB_R0W1:tbyte
	extrn	CALIB_R1W0R0DN:tbyte

	public	PCALIB_UTF
PCALIB_UTF PCALIB_STR <@CALIB_UTF_LEN,DGROUP:CALIB_UTF> ; Calibration struc for
				; this module
	public	UNLTRN_ACT
UNLTRN_ACT dw	PGROUP:MATSPPB	; Byte-wide memory
	dw	PGROUP:MATSPPW	; Word-...
	dw	PGROUP:MATSPPD	; Dword-...

DATA	ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

	public	CALIB_UTF
CALIB_UTF label word		; Start of calibration ptrs for this module

CALIBSEG ends			; End CALIBSEG segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	DISP_STATLZ:near

	extrn	FMT_W0:near
	extrn	FMT_R0W1:near
	extrn	FMT_R1W0R0DN:near

	extrn	FMT_BLK:near
	extrn	FMT_DONE:near

	extrn	DISP_ERRB:near
	extrn	DISP_ERRW:near
	extrn	DISP_ERRD:near
	extrn	DISP_NMIERR:near
	extrn	DISP_OPERS:near

	extrn	ZAPREST:near

	extrn	CHECK_HALT:near
	extrn	CHECK_KEYS:near

	NPPROC	TEST_UNLTRN -- Test for (Unlinked) Transition Faults
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for (Unlinked) Transition Faults.

This routine runs in Protected Mode.

CF	=	0 if all went well
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

; Display the title line

	push	offset DGROUP:ZMSG_UNLTRN ; Pass as offset of the line
	call	DISP_STATLZ	; Display on the status line with attributes

	mov	es,SEL_4GB	; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	ax,TIMECNT	; Get # entries
	mov	RCNT,ax 	; Save to decrement
	xor	bx,bx		; Initialize index into TIMETAB
TEST_UNLTRN_NEXT_ENTRY:
	test	TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	jnz	short TEST_UNLTRN_LOOP ; Jump if so

; Depending upon the word size, use Byte, Word, or Dword reads and writes

	movzx	eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	shr	eax,3-0 	; Convert from bits per byte to bytes
	mov	BPU,eax 	; Save as bytes per unit

	call	FMT_BLK 	; Format and display block information

	mov	ecx,TIMETAB[bx].TT_LEN ; Get length in bytes

	bsf	eax,BPU 	; Get log base 2 into EAX
	call	UNLTRN_ACT[eax*(type UNLTRN_ACT)] ; Get address of action routine
	jc	short TEST_UNLTRN_ERR ; Jump if something went wrong

	call	CHECK_KEYS	; See if any interesting keys were pressed
	jne	short TEST_UNLTRN_CLC ; Jump if so
TEST_UNLTRN_LOOP:
	add	bx,size TT_STR	; Skip to next entry

	dec	RCNT		; Decrement # remaining entries
	jnz	short TEST_UNLTRN_NEXT_ENTRY ; Jump if more entries
TEST_UNLTRN_CLC:

; Display done or interrupted message

	call	FMT_DONE	; Tell 'em we're finished

	clc			; Indicate all went well

	jmp	short TEST_UNLTRN_EXIT ; Join common error code

TEST_UNLTRN_ERR:
	stc			; Indicate something went wrong
TEST_UNLTRN_EXIT:
	REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_UNLTRN endp		; End TEST_UNLTRN procedure
	NPPROC	MATSPPB -- Modified ATS Plus Plus for Byte-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Modified ATS++ for byte-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	UTFMAC	MATSPP,0,LO,AL,B

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MATSPPB endp			; End MATSPPB procedure
	NPPROC	MATSPPW -- Modified ATS Plus Plus for Word-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Modified ATS++ for word-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	UTFMAC	MATSPP,1,ELO,ax,W

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MATSPPW endp			; End MATSPPW procedure
	NPPROC	MATSPPD -- Modified ATS Plus Plus for Dword-Wide Memory
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Modified ATS++ for a dword-wide memory.

On entry:

BX	=	index into TIMETAB structure
ECX	=	# bytes to test

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	UTFMAC	MATSPP,2,EDD,eax,D

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MATSPPD endp			; End MATSPPD procedure

CODE	ends			; End CODE segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	assume	ds:DGROUP

@CALIB_UTF_LEN equ ($-CALIB_UTF)/(type CALIB_UTF) ; # calibration entries

CALIBSEG ends			; End CALIBSEG segment

	MEND			; End MEM_UTF module
