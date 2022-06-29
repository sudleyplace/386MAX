;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_IBV.ASV   1.1   22 Feb 1994 12:31:34   HENRY  $

	 title	 VCP_IBV -- VCPI Interrupt Base Values Routines
	 page	 58,122
	 name	 VCP_IBV
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

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

	 public  IBV0,IBV1,IBV2,IBV3
IBV0	 dw	 ?		; Original master IBV
IBV1	 dw	 ?		; ...	   slave
IBV2	 dw	 ?		; Changed master IBV
IBV3	 dw	 ?		; ...	  slave

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 NPPROC  CHECK_IBV -- Check on IBV Get/Set
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check on VCPI Interrupt Base Values get/set

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

; Read and save original values

	 DISPLAY '様> Reading original Interrupt Base Values...'

	 VCPIBACK @VCPI_GIBV	; Return master in BX, slave in CX

	 mov	 IBV0,bx	; Save to restore later
	 mov	 IBV1,cx	; ...

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to read original Interrupt Base Values",ERR
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error

; Change values to something else

	 DISPLAY '様> Changing Interrupt Base Values...'

	 not	 bl		; Complement master value
	 mov	 IBV2,bx
	 not	 cl		; ...	     slave
	 mov	 IBV3,cx

	 VCPIBACK @VCPI_SIBV	; Set master to BX, slave to CX

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to change Interrupt Base Values",ERR
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error

; Read in changed values

	 DISPLAY '様> Reading changed Interrupt Base Values...'

	 VCPIBACK @VCPI_GIBV	; Return master in BX, slave in CX

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to read changed Interrupt Base Values",ERR
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error

; Compare changed values

	 DISPLAY '様> Comparing changed Interrupt Base Values...'

	 cmp	 bx,IBV2	; Check the master value
	 SETMSG  "Mismatch on master Interrupt Base Value"
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error

	 cmp	 cx,IBV3	; Check the slave value
	 SETMSG  "Mismatch on slave Interrupt Base Value"
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error

; Restore original values

	 DISPLAY '様> Restoring original Interrupt Base Values...'

	 mov	 bx,IBV0	; Get original master value
	 mov	 cx,IBV1	; ...	       slave

	 VCPIBACK @VCPI_SIBV	; Set master to BX, slave to CX

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to restore orignial Interrupt Base Values",ERR
	 jne	 near ptr CHECK_IBV_ERR ; Jump if in error





	 clc			; Indicate present

	 jmp	 short CHECK_IBV_EXIT ; Join common exit code

CHECK_IBV_ERR:
	 stc			; Indicate not present
CHECK_IBV_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_IBV endp			; End CHECK_IBV procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_IBV module
