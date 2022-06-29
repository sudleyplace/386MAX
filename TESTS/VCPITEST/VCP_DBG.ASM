;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_DBG.ASV   1.1   22 Feb 1994 12:31:30   HENRY  $

	 title	 VCP_DBG -- VCPI Debug Register Test Routines
	 page	 58,122
	 name	 VCP_DBG
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include VCPI.INC

	 include VCP_TEST.INC
	 include EMM2CALL.INC
.list


PGROUP	 group	 CODE,DATA,TEXT


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 PORT67:word

	 extrn	 CMD_FLAG:word
	 include VCP_FLAG.INC

	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte

	 public  DBGORIG,DBGTST1,DBGTST2
DBGORIG  dd	 8 dup (?)	; Save area for original debug registers
DBGTST1  dd	 8 dup (?)	; 1st test area
DBGTST2  dd	 8 dup (?)	; 2nd test area

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 NPPROC  CHECK_DBG -- Check on Debug Register Get/Set
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check on VCPI debug register get/set

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 DISPLAY '様> Reading original debug registers...'

	 lea	 di,DBGORIG	; ES:DI ==> original debug register save area
	 VCPIBACK @VCPI_GDRN	; Read Drn into ES:DI

	 cmp	 ah,00h 	; Check for presence
	 SETMSG  "Unable to read debug registers:  1st time",ERR
	 jne	 near ptr CHECK_DBG_ERR ; Jump if in error

; Copy registers to separate location

	 lea	 si,DBGORIG	; DS:SI ==> source
	 lea	 di,DBGTST1	; ES:DI ==> destin
	 mov	 cx,8		; # debug registers
     rep movsd			; Copy to test area

; Complement DR0, DR1, DR2, and DR3

	 not	 DBGTST1[0*4]	; Complement DR0
	 not	 DBGTST1[1*4]	; ...	     DR1
	 not	 DBGTST1[2*4]	; ...	     DR2
	 not	 DBGTST1[3*4]	; ...	     DR3

	 DISPLAY '様> Setting debug registers...'

	 lea	 di,DBGTST1	; ES:DI ==> 1st test debug register save area
	 VCPIBACK @VCPI_SDRN	; Set Drn from ES:DI

	 cmp	 ah,00h 	; Check for presence
	 SETMSG  "Unable to set debug registers:  1st time",ERR
	 jne	 near ptr CHECK_DBG_ERR ; Jump if in error

	 DISPLAY '様> Reading test debug registers...'

	 lea	 di,DBGTST2	; ES:DI ==> 2nd test debug register save area
	 VCPIBACK @VCPI_GDRN	; Read Drn into ES:DI

	 cmp	 ah,00h 	; Check for presence
	 SETMSG  "Unable to read debug registers:  2nd time",ERR
	 jne	 short CHECK_DBG_ERR ; Jump if in error

; Compare DBGTST1 and DBGTST2

	 lea	 si,DBGTST1	; DS:SI ==> source
	 lea	 di,DBGTST2	; ES:DI ==> destin
	 mov	 cx,8		; # debug registers
     rep cmpsd			; Copy to test area
	 SETMSG  "Mis-match comparing 1st and 2nd test debug registers"
	 jne	 short CHECK_DBG_ERR ; Jump if in error

; Restore original debug registers

	 DISPLAY '様> Restoring original debug registers...'

	 lea	 di,DBGORIG	; ES:DI ==> original debug register save area
	 VCPIBACK @VCPI_SDRN	; Set Drn from ES:DI

	 cmp	 ah,00h 	; Check for presence
	 SETMSG  "Unable to restore debug registers",ERR
	 jne	 short CHECK_DBG_ERR ; Jump if in error





	 clc			; Indicate present

	 jmp	 short CHECK_DBG_EXIT ; Join common exit code

CHECK_DBG_ERR:
	 stc			; Indicate not present
CHECK_DBG_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_DBG endp			; End CHECK_DBG procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_DBG module
