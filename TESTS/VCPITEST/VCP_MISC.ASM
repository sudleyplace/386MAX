;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_MISC.ASV   1.1   22 Feb 1994 12:32:16   HENRY  $

	 title	 VCP_MISC -- VCPI Miscellaneous Routines
	 page	 58,122
	 name	 VCP_MISC
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
	 include IOCTL.INC
	 include OPEN.INC
	 include PTR.INC

	 include QMAX_CTL.INC
.list


PGROUP	 group	 CODE,DATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include VCP_FLAG.INC

	 public  EMMNAME
EMMNAME  db	 'EMMXXXX0',0   ; Name of EMS device driver

	 public  EMMNAM2,EMMNAM3,EMMNAM4,EMMNAM5
EMMNAM2  db	 '$MMXXXX0',0   ; EMM386.EXE device name if NOEMS
EMMNAM3  db	 'EMMXXXQ0',0   ; QEMM386.SYS device name if NOEMS
EMMNAM4  db	 'EMMQXXX0',0   ; RM386.EXE device name if NOFRAME
EMMNAM5  db	 'QMMXXXX0',0   ; 386MAX.SYS device name if EMS=0

	 public  MAXNAME
MAXNAME  db	 '386MAX$$',0   ; 386MAX IOCTL name

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 align	 2		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  PORT67
PORT67	 equ	 INFO.INFO_P67	; 14 = I/O port for INT 67h communications

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 NPPROC  CHECK_DEV -- Check for device
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return CF=0 if device exists.

On entry:
DS:DX ==> Device name

On exit:
CF=0	 Exists and is a device
CF=1	 Doesn't exist or isn't a device

|

	 REGSAVE <ax,bx,dx>	; Save

	 mov	 al,@OPEN_R	; Code for read-only access
	 DOSCALL @OPENF2	; Open it
	 jc	 short CHECK_DEV_EXIT ; Jump if no luck

	 mov	 bx,ax		; Save handle

	 mov	 al,0		; Code to get device info
	 DOSCALL @IOCTL2	; Read device info
	 pushf			; Save CF from call
	 DOSCALL @CLOSF2	; Close the file
	 popf			; Restore CF
	 jc	 short CHECK_DEV_EXIT ; Jump if something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short CHECK_DEV_EXIT ; Jump if so (note CF=0)

	 stc			; Not a device
CHECK_DEV_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEV endp			; End CHECK_DEV procedure
	 NPPROC  CHECK_EMS -- Check on EMS Driver Presence
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check on EMS or other Int 67h handler presence.

On exit:

CF	 =	 0 if present
	 =	 1 if not

|

	 pusha			; Save registers

; First, there must be an EMS provider

	 lea	 dx,EMMNAME	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_EMS_EXIT ; Jump if present (note CF=0)

	 lea	 dx,EMMNAM2	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_EMS_EXIT ; Jump if present (note CF=0)

	 lea	 dx,EMMNAM3	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_EMS_EXIT ; Jump if present (note CF=0)

	 lea	 dx,EMMNAM4	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_EMS_EXIT ; Jump if present (note CF=0)

	 lea	 dx,EMMNAM5	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_EMS_ERR ; Jump if not

; Versions of MAX prior to 7.01.033 did not handle VCPI calls if
; EMS services are not available.  We'll try to open 386MAX$$; if it's present
; (along with QMMXXXX0, which we just checked for) we need to get
; the PORT67 value for back-door access to VCPI.

	 lea	 dx,MAXNAME	; 386MAX device driver
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_EMS_ERR ; Jump if not - it's another program

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2	; Attempt to open 386MAX device driver
	 jc	 short CHECK_EMS_ERR ; Jump if not present

	 mov	 bx,ax		; Copy to handle register

; From this point we need to exit via CHECK_EMS_ERRCLOSE
; CHECK_DEV has already ensured that this is an IOCTL device.  Read the
; info structure.

	 mov	 al,02h 	; Read from device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO
;;;;;;;  jc	 ???		; Ignore error

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short CHECK_EMS_ERRCLOSE ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short CHECK_EMS_ERRCLOSE ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short CHECK_EMS_ERRCLOSE ; Not this time


	 or	 CMD_FLAG,@CMD_BACKVCPI ; Use 386MAX back door VCPI services

CHECK_EMS_ERRCLOSE:
	 DOSCALL @CLOSF2	; Close file handle BX

	 test	 CMD_FLAG,@CMD_BACKVCPI ; Are we using the back door?
	 jnz	 short CHECK_EMS_EXIT ; Jump if so (note CF=0)

CHECK_EMS_ERR:
	 stc			; Indicate not present
CHECK_EMS_EXIT:
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_EMS endp			; End CHECK_EMS procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_MISC module
