;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_A20.ASV   1.2   19 Jan 1993 17:48:04   BOB  $

	 title	 XMS_A20 -- XMS A20 Tester
	 page	 58,122
	 name	 XMS_A20
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.286c
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include XMS.INC
	 include HMA.INC
	 include INTVEC.INC

	 include XMS_TEST.INC
.list


PGROUP	 group	 CODE,DATA,TEXT


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte

	 public  MSG_A20
MSG_A20  dw	 PGROUP:MSG_A20DIS
	 dw	 PGROUP:MSG_A20ENA

	 public  MSG_A20DIS,MSG_A20ENA
MSG_A20DIS db	 'The A20 line is disabled.',CR,LF,EOS
MSG_A20ENA db	 'The A20 line is enabled.',CR,LF,EOS

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  CHECK_A20 -- Check The State Of The A20 Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check the state of the A20 line by comparing 0:0 with FFFF:10
while locally enabling and disabling the A20 line through the
control functions.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

; Determine and display the state of A20 line

	 DISPLAY 'ออ> Checking A20 status...'

	 mov	 bl,-1		; Set to known value
	 mov	 ah,@XMS_QRYA20 ; Code to query status of A20 line
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 bl,0		; Check the error code
	 je	 short @F	; Jump if successful

	 SETMSG  "Unable to query A20 status",XMS

	 jmp	 CHECK_A20_ERR	; Join common error code

@@:
	 mov	 bx,ax		; Save return state

	 shl	 bx,1		; Times two to index table of words
	 mov	 dx,MSG_A20[bx] ; Get message
	 shr	 bx,1		; Convert back
	 DOSCALL @STROUT	; Tell the user about it

	 DISPLAY "Checking driver A20 state via memory compare"
	 call	 COMP_A20	; Check the state by comparing memory

	 cmp	 ax,bx		; Check for same value
	 SETMSG  "Mismatch on A20 line status"
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

; Locally enable the A20 line and compare again

	 call	 LCLENA_A20	; Attempt to locally enable the A20 line
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

; Locally disable the A20 line and compare again

	 call	 LCLDIS_A20	; Attempt to locally disable the A20 line
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

; Locally enable the A20 line multiple times, compare memory each time
; and then locally disable it multiple times, again comparing memory

@A20CNT  equ	 20

	 DISPLAY "Multiple Local Enabling A20 state"
	 mov	 cx,@A20CNT	; Iteration count
CHECK_A20_NEXT1:
	 call	 LCLENA_A20	; Attempt to locally enable the A20 line
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

	 loop	 CHECK_A20_NEXT1 ; Jump if more iterations

	 DISPLAY "Multiple Local Disabling A20 state"
	 mov	 cx,@A20CNT-1	; Iteration count
CHECK_A20_NEXT2:

; Attempt to locally disable the A20 line and compare memory;
; it should still be enabled

	 DISPLAY "   Attempting to Locally Disable A20 state"
	 mov	 ah,@XMS_LCLDIS ; Code to locally disable A20 line
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Did we disable it?
	 SETMSG  "Incorrect local disabling of A20 line",XMS
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

	 call	 QRY_A20	; Check state via Query and memory compare
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

	 loop	 CHECK_A20_NEXT2 ; Jump if more iterations

; Locally disable the A20 line and compare memory -- this time it should work

	 call	 LCLDIS_A20	; Attempt to locally disable the A20 line
	 jne	 short CHECK_A20_ERR ; Jump if something went wrong

	 clc			; Indicate all went well

	 jmp	 short CHECK_A20_EXIT ; Join common exit code

CHECK_A20_ERR:
	 stc			; Indicate there was a problem
CHECK_A20_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_A20 endp			; End CHECK_A20 procedure
	 NPPROC  LCLENA_A20 -- Attempt To Locally Enable The A20 Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Attempt to locally enable the A20 line.

On exit:

ZF	 =	 1 if all went well
	 =	 0 otherwise

|

	 REGSAVE <ax>		; Save register

	 DISPLAY "   Locally Enabling A20 state"
	 mov	 ah,@XMS_LCLENA ; Code to locally enable A20 line
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Did we succeed?
	 SETMSG  "Unable to locally enable A20 line",XMS
	 jne	 short LCLENA_A20_EXIT ; Jump if something went wrong (note ZF=0)

	 call	 QRY_A20	; Check state via Query and memory compare
				; Fall through with ZF set if OK, clear if not
LCLENA_A20_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LCLENA_A20 endp 		; End LCLENA_A20 procedure
	 NPPROC  LCLDIS_A20 -- Attempt To Locally Disable The A20 Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Attempt to locally disable the A20 line

On exit:

ZF	 =	 1 if all went well
	 =	 0 otherwise

|

	 REGSAVE <ax>		; Save register

	 DISPLAY "   Locally Disabling A20 state"
	 mov	 ah,@XMS_LCLDIS ; Code to locally disable A20 line
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Did we succeed?
	 SETMSG  "Unable to locally disable A20 line",XMS
	 jne	 short LCLDIS_A20_EXIT ; Jump if something went wrong (note ZF=0)

	 call	 QRY_A20	; Check state via Query and memory compare
				; Return with ZF set if OK, clear if not
LCLDIS_A20_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LCLDIS_A20 endp 		; End LCLDIS_A20 procedure
	 NPPROC  COMP_A20 -- Compare Memory To The State of A20
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check the state of the A20 line by comparing memory.

On exit:

AX	 =	 1 if the A20 line is enabled
	 =	 0 if the A20 line is disabled

|

	 REGSAVE <cx,si,di,ds,es> ; Save registers

	 mov	 ax,seg INTVEC	; Get segment of interrupt vectors
	 mov	 ds,ax		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> start of interrupt vectors

	 mov	 ax,seg HMASEG	; Get segment of HMA
	 mov	 es,ax		; Address it
	 assume  es:HMASEG	; Tell the assembler about it

	 lea	 di,HMASTART	; ES:DI ==> start of HMA

	 xor	 cx,cx		; Address end of segment
	 sub	 cx,di		; Less start to get length
	 cld			; String ops forwardly

	 xor	 ax,ax		; Assume disabled

	 cli			; Disallow interrupts
    repe cmpsb			; Compare 'em
	 sti			; Allow interrupts
	 je	 short @F	; Jump if disabled

	 inc	 ax		; Mark as enabled
@@:
	 REGREST <es,ds,di,si,cx> ; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COMP_A20 endp			; End COMP_A20 procedure
	 NPPROC  QRY_A20 -- Query A20 State and Compare Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check the A20 state by Querying it and comparing memory.

On exit:

ZF	 =	 1 if all went OK
	 =	 0 otherwise

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 bl,-1		; Set to known value
	 mov	 ah,@XMS_QRYA20 ; Code to query status of A20 line
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 bl,00h 	; Did it succeed?
	 SETMSG  "Unable to query A20 status",XMS
	 jne	 short QRY_A20_EXIT ; Join common exit code (note ZF=0)

	 mov	 bx,ax		; Save return state

	 DISPLAY "   Checking driver A20 state via memory compare"
	 call	 COMP_A20	; Check the state by comparing memory

	 cmp	 ax,bx		; Check for same value
	 SETMSG  "Mismatch on A20 line status"
				; Return with ZF significant
QRY_A20_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

QRY_A20  endp			; End QRY_A20 procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_A20 module
