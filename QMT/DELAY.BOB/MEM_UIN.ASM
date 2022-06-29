;' $Header:   P:/PVCS/MAX/QMT/MEM_UIN.ASV   1.0   05 Sep 1995 16:55:44   HENRY  $
	 title	 MEM_UIN -- MEMCHK Unlinked Inversion Coupling Fault Checking Routines
	 page	 58,122
	 name	 MEM_UIN

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
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC

	 include MEM_UIN.MAC
	include MEM_SEG.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	extrn	ONESEC:dword
	extrn	DELAYNUM:word
	extrn	DELAYCNT:dword

	 extrn	 CNT_FLAG:word
	 include MEM_CNT.INC

	extrn	GL3_FLAG:word
	include MEM_GL3.INC

	 extrn	 SEL_4GB:word

	 extrn	 TIMETAB:tbyte,TIMECNT:word
	 include MEM_TIME.INC

	 extrn	 ZMSG_UNLINV:byte

	 extrn	 BPU:dword
	 extrn	 RCNT:word

	 extrn	 NMIOFF:word
	 extrn	 ZAPOFF:word
	extrn	NMIRET:word
	extrn	RESOFF:word

	 extrn	 REG0UP:dword
	 extrn	 REG0DN:dword
	 extrn	 REG1UP:dword
	 extrn	 REG1DN:dword
	 extrn	 PATCNT:word
	 extrn	 PATOFF:word
	 extrn	 NUMOPERS:qword
	 extrn	 NMIADDR:dword

	 extrn	 CALIB_W0:tbyte
	 extrn	 CALIB_R0W1:tbyte
	 extrn	 CALIB_R1W0DN:tbyte
	 extrn	 CALIB_R0DN:tbyte

	 public  PCALIB_UIN
PCALIB_UIN PCALIB_STR <@CALIB_UIN_LEN,DGROUP:CALIB_UIN> ; Calibration struc for
				; this module
	 public  UNLINV_ACT
UNLINV_ACT dw	 PGROUP:MARCHXB ; Byte-wide memory
	 dw	 PGROUP:MARCHXW ; Word-...
	 dw	 PGROUP:MARCHXD ; Dword-...

DATA	 ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	 assume  ds:DGROUP

	 public  CALIB_UIN
CALIB_UIN label  word		; Start of calibration ptrs for this module

CALIBSEG ends			; End CALIBSEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_STATLZ:near

	 extrn	 FMT_W0:near
	 extrn	 FMT_R0W1:near
	 extrn	 FMT_R1W0DN:near
	 extrn	 FMT_R0DN:near

	 extrn	 FMT_BLK:near
	 extrn	 FMT_DONE:near

	 extrn	 FMT_PATTERNB:near
	 extrn	 FMT_PATTERNW:near
	 extrn	 FMT_PATTERND:near

	 extrn	 DISP_ERRB:near
	 extrn	 DISP_ERRW:near
	 extrn	 DISP_ERRD:near
	 extrn	 DISP_NMIERR:near
	 extrn	 DISP_OPERS:near

	 extrn	 ZAPREST:near

	 extrn	 CHECK_HALT:near
	 extrn	 CHECK_KEYS:near

	 NPPROC  TEST_UNLINV -- Test for Unlinked Inversion Coupling Faults
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for Unlinked Inversion Coupling Faults.

This routine runs in Protected Mode.

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

; Display the title line

	 push	 offset DGROUP:ZMSG_UNLINV ; Pass as offset of the line
	 call	 DISP_STATLZ	; Display on the status line with attributes

	 mov	 es,SEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ax,TIMECNT	; Get # entries
	 mov	 RCNT,ax	; Save to decrement
	 xor	 bx,bx		; Initialize index into TIMETAB
TEST_UNLINV_NEXT_ENTRY:
	 test	 TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 short TEST_UNLINV_LOOP ; Jump if so

; Depending upon the word size, use Byte, Word, or Dword reads and writes

	 movzx	 eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	 shr	 eax,3-0	; Convert from bits per byte to bytes
	 mov	 BPU,eax	; Save as bytes per unit

	 call	 FMT_BLK	; Format and display block information

	 mov	 ecx,TIMETAB[bx].TT_LEN ; Get length in bytes

	 bsf	 eax,BPU	; Get log base 2 into EAX
	 call	 UNLINV_ACT[eax*(type UNLINV_ACT)] ; Get address of action routine
	 jc	 short TEST_UNLINV_ERR ; Jump if something went wrong

	 call	 CHECK_KEYS	; See if any interesting keys were pressed
	 jne	 short TEST_UNLINV_CLC ; Jump if so
TEST_UNLINV_LOOP:
	 add	 bx,size TT_STR ; Skip to next entry

	 dec	 RCNT		; Decrement # remaining entries
	 jnz	 short TEST_UNLINV_NEXT_ENTRY ; Jump if more entries
TEST_UNLINV_CLC:

; Display done or interrupted message

	 call	 FMT_DONE	; Tell 'em we're finished

	 clc			; Indicate all went well

	 jmp	 short TEST_UNLINV_EXIT ; Join common error code

TEST_UNLINV_ERR:
	 stc			; Indicate something went wrong
TEST_UNLINV_EXIT:
	 REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_UNLINV endp		; End TEST_UNLINV procedure
	 NPPROC  MARCHXB -- March X for Byte-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March X for byte-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 UINMAC  MARCHX,0,LO,al,B

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHXB  endp			; End MARCHXB procedure
	 NPPROC  MARCHXW -- March X for Word-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March X for word-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 UINMAC  MARCHX,1,ELO,ax,W

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHXW  endp			; End MARCHXW procedure
	 NPPROC  MARCHXD -- March X for Dword-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March X for a dword-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 UINMAC  MARCHX,2,EDD,eax,D

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHXD  endp			; End MARCHXD procedure

CODE	 ends			; End CODE segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	 assume  ds:DGROUP

@CALIB_UIN_LEN equ ($-CALIB_UIN)/(type CALIB_UIN) ; # calibration entries

CALIBSEG ends			; End CALIBSEG segment

	 MEND			; End MEM_UIN module
