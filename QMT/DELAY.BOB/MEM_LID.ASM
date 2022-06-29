;' $Header:   P:/PVCS/MAX/QMT/MEM_LID.ASV   1.0   05 Sep 1995 16:55:46   HENRY  $
	 title	 MEM_LID -- MEMCHK Linked Idempotent Coupling Fault Checking Routines
	 page	 58,122
	 name	 MEM_LID

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

	 include MEM_LID.MAC
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

	 extrn	 ZMSG_LNKIDM:byte

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
	 extrn	 CALIB_R0W1R1W0R0W1:tbyte
	 extrn	 CALIB_R1W0W1:tbyte
	 extrn	 CALIB_R1W0W1W0DN:tbyte
	 extrn	 CALIB_R0W1W0DN:tbyte

	 public  PCALIB_LID
PCALIB_LID PCALIB_STR <@CALIB_LID_LEN,DGROUP:CALIB_LID> ; Calibration struc for
				; this module
	 public  LNKIDM_ACT
LNKIDM_ACT dw	 PGROUP:MARCHBB ; Byte-wide memory
	 dw	 PGROUP:MARCHBW ; Word-...
	 dw	 PGROUP:MARCHBD ; Dword-...

DATA	 ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	 assume  ds:DGROUP

	 public  CALIB_LID
CALIB_LID label  word		; Start of calibration ptrs for this module

CALIBSEG ends			; End CALIBSEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_STATLZ:near

	 extrn	 FMT_W0:near
	 extrn	 FMT_R0W1R1W0R0W1:near
	 extrn	 FMT_R1W0W1:near
	 extrn	 FMT_R1W0W1W0DN:near
	 extrn	 FMT_R0W1W0DN:near

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

	 NPPROC  TEST_LNKIDM -- Test for Linked Idempotent Coupling Faults
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for Linked Idempotent Coupling Faults.

This routine runs in Protected Mode.

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,es> ; Save registers

; Display the title line

	 push	 offset DGROUP:ZMSG_LNKIDM ; Pass as offset of the line
	 call	 DISP_STATLZ	; Display on the status line with attributes

	 mov	 es,SEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ax,TIMECNT	; Get # entries
	 mov	 RCNT,ax	; Save to decrement
	 xor	 bx,bx		; Initialize index into TIMETAB
TEST_LNKIDM_NEXT_ENTRY:
	 test	 TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 short TEST_LNKIDM_LOOP ; Jump if so

; Depending upon the word size, use Byte, Word, or Dword reads and writes

	 movzx	 eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	 shr	 eax,3-0	; Convert from bits per byte to bytes
	 mov	 BPU,eax	; Save as bytes per unit

	 call	 FMT_BLK	; Format and display block information

	 mov	 ecx,TIMETAB[bx].TT_LEN ; Get length in bytes

	 bsf	 eax,BPU	; Get log base 2 into EAX
	 call	 LNKIDM_ACT[eax*(type LNKIDM_ACT)] ; Get address of action routine
	 jc	 short TEST_LNKIDM_ERR ; Jump if something went wrong

	 call	 CHECK_KEYS	; See if any interesting keys were pressed
	 jne	 short TEST_LNKIDM_CLC ; Jump if so
TEST_LNKIDM_LOOP:
	 add	 bx,size TT_STR ; Skip to next entry

	 dec	 RCNT		; Decrement # remaining entries
	 jnz	 short TEST_LNKIDM_NEXT_ENTRY ; Jump if more entries
TEST_LNKIDM_CLC:

; Display done or interrupted message

	 call	 FMT_DONE	; Tell 'em we're finished

	 clc			; Indicate all went well

	 jmp	 short TEST_LNKIDM_EXIT ; Join common error code

TEST_LNKIDM_ERR:
	 stc			; Indicate something went wrong
TEST_LNKIDM_EXIT:
	 REGREST <es,esi,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_LNKIDM endp		; End TEST_LNKIDM procedure
	 NPPROC  MARCHBB -- March B for Byte-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March B for byte-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|
.lall
	 LIDMAC  MARCHB,0,LO,al,B

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHBB  endp			; End MARCHBB procedure
	 NPPROC  MARCHBW -- March B for Word-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March B for word-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 LIDMAC  MARCHB,1,ELO,ax,W

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHBW  endp			; End MARCHBW procedure
	 NPPROC  MARCHBD -- March B for Dword-Wide Memory
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

March B for a dword-wide memory.

On entry:

BX	 =	 index into TIMETAB structure
ECX	 =	 # bytes to test

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 LIDMAC  MARCHB,2,EDD,eax,D

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARCHBD  endp			; End MARCHBD procedure

CODE	 ends			; End CODE segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
	 assume  ds:DGROUP

@CALIB_LID_LEN equ ($-CALIB_LID)/(type CALIB_LID) ; # calibration entries

CALIBSEG ends			; End CALIBSEG segment

	 MEND			; End MEM_LID module
