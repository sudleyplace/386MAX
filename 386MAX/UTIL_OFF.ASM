;' $Header:   P:/PVCS/MAX/386MAX/UTIL_OFF.ASV   1.3   08 Jul 1998 12:30:12   BOB  $
	 title	 UTIL_OFF -- 386MAX Utility Program -- OFF/ON/AUTO Actions
	 page	 58,122
	 name	 UTIL_OFF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include EMM2CALL.INC

	 include QMAX_OEM.INC
	 include QMAX_CTL.INC
.list

if @OEM_AUTO
PGROUP	 group	 CODE,DATA,NCODE


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

if @OEM_WIN3
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 extrn	 INFO_CTL:byte
	 extrn	 DEV_HNDL:word
	 extrn	 ONFSIZE:word

	 extrn	 MSG_STATE_OFF:byte
	 extrn	 MSG_STATE_ON:byte
	 extrn	 MSG_STATE_AUTO0:byte
	 extrn	 MSG_STATE_AUTO1:byte

	 extrn	 MSG_FORCE:byte
	 extrn	 MSG_FORCE_LEN:abs

	 extrn	 MSG_EXTINUSE:byte
	 extrn	 MSG_EXTINUSE_LEN:abs

	 extrn	 MSG_OFF:byte
	 extrn	 MSG_OFF_LEN:abs

	 public  PMSG_STATE
PMSG_STATE dw	 PGROUP:MSG_STATE_OFF
	 dw	 PGROUP:MSG_STATE_ON
	 dw	 PGROUP:MSG_STATE_AUTO0
	 dw	 PGROUP:MSG_STATE_AUTO1

DATA	 ends			; End DATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near
	 extrn	 CHECK_LINE:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 INFO_WRITE:near

	 NPPROC  CHECK_ONFSIZE -- Check On ONFSIZE
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure ONFSIZE same as current extended memory size

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax>		; Save registers

	 mov	 ah,88h 	; Function to get extended memory size into AX
	 int	 15h		; Request BIOS service

	 cmp	 ax,ONFSIZE	; Same as we expected?
	 je	 short CHECK_ONFSIZE_EXIT ; Jump if same (note CF=0)

	 call	 DISP_EXT	; Display extended memory in use message

	 stc			; Indicate something went wrong
CHECK_ONFSIZE_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ONFSIZE endp		; End CHECK_ONFSIZE procedure
	 NPPROC  SEND_CMD -- Set The State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the state to INFO_CTL.

On exit:

INFO_CTL =	 0 if successful
	 >	 0 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,03h 	; Write into device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,1		; CX = # bytes in INFO_CTL
	 DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_CMD endp			; End SEND_CMD procedure
	 NPPROC  STATE_OFF -- Change State to OFF
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change state to OFF

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 mov	 INFO_CTL,@CTL_OFF ; Mark as state OFF
	 call	 SEND_CMD	; Attempt to set state

	 cmp	 INFO_CTL,0	; Check for success
	 je	 short STATE_OFF_EXIT ; Jump if successful

	 call	 DISP_FORCED	; Display forced ON message
	 call	 DISP_STATE	; Display the current state

	 stc			; Indicate something went wrong

	 jmp	 short STATE_OFF_EXIT ; Join common exit code

STATE_OFF_OK:
	 and	 GLB_FLAG,not @GLB_ON ; Mark as OFF

	 call	 INFO_WRITE	; Write out INFO structure

	 clc			; Indicate all went well
STATE_OFF_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STATE_OFF endp			; End STATE_OFF procedure
	 NPPROC  SET_ONFSIZE -- Get and Save New Value for ONFSIZE
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get and save a new value for ONFSIZE.

|

	 push	 ax		; Save for a moment

	 mov	 ah,88h 	; Function to get extended memory size
	 int	 15h		; Request BIOS service
	 mov	 ONFSIZE,ax	; Save to write into device driver

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_ONFSIZE endp		; End SET_ONFSIZE procedure
	 NPPROC  DISP_STATE -- Display The Current State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current OFF/ON/AUTO active/inactive state

|

	 REGSAVE <ax,bx,dx>	; Save registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short DISP_STATE_EXIT ; Jump if so
endif				; IF @OEM_WIN3

	 xor	 bx,bx		; Assume both bits off

	 test	 GLB_FLAG,@GLB_AUTO ; Check AUTO state
	 jz	 short DISP_STATE1 ; It's clear

	 or	 bx,10b 	; Mark as set
DISP_STATE1:
	 test	 GLB_FLAG,@GLB_ON ; Check OFF/ON state
	 jz	 short DISP_STATE2 ; It's clear

	 or	 bx,01b 	; Mark as set
DISP_STATE2:
	 shl	 bx,1		; Times two to index table of words

	 mov	 dx,PMSG_STATE[bx] ; Get the appropriate state message

	 call	 STROUT 	; Display string at DS:DX
DISP_STATE_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATE endp 		; End DISP_STATE procedure
	 NPPROC  DISP_FORCED -- Display Forced ON Message
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display forced ON message.

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,MSG_FORCE_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_FORCE ; Tell 'em we can't do it
	 call	 CHECK_LINE	; Count in another line and check for pause

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FORCED endp		; End DISP_FORCED procedure
	 NPPROC  DISP_EXT -- Display Extended Memory In Use Message
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display extended memory in use message

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,MSG_EXTINUSE_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_EXTINUSE ; Tell 'em we can't do it
	 call	 CHECK_LINE	; Count in another line and check for pause

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_EXT endp			; End DISP_EXT procedure
	 NPPROC  CHECK_STATE -- Check ON/OFF/AUTO State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're ON or AUTO active state.

State		 Action
-----------------------
OFF		 Exit error
ON		 Exit OK
AUTO active	 Exit OK
AUTO inactive	 Change to ON, exit OK

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 test	 GLB_FLAG,@GLB_ON ; Are we ON?
	 jnz	 short CHECK_STATE_ON ; Yes

	 test	 GLB_FLAG,@GLB_AUTO ; Can we go ON?
	 jnz	 short CHECK_STATE_AUTO ; Yes, give it a try

	 mov	 cx,MSG_OFF_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_OFF ; Tell 'em we can't do it
	 call	 CHECK_LINE	; Count in another line and check for pause

	 stc			; Indicate error

	 jmp	 short CHECK_STATE_EXIT ; Join common error code

CHECK_STATE_AUTO:
	 call	 STATE_ON	; Turn us ON
	 jc	 short CHECK_STATE_EXIT ; Jump if not successful (note CF=1)
CHECK_STATE_ON:
	 clc			; Assume we are
CHECK_STATE_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_STATE endp		; End CHECK_STATE procedure
	 NPPROC  STATE_ON -- Change State to ON
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change state to ON

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 mov	 INFO_CTL,@CTL_ON ; Mark as state ON
	 call	 SEND_CMD	; Attempt to set state

	 cmp	 INFO_CTL,0	; Check for success
	 je	 short STATE_ON_OK ; Jump if successful

	 call	 DISP_FORCED	; Display forced ON message
	 call	 DISP_STATE	; Display the current state

	 stc			; Indicate something went wrong

	 jmp	 short STATE_ON_EXIT ; Join common exit code

STATE_ON_OK:
	 or	 GLB_FLAG,@GLB_ON ; Mark as ON

	 call	 INFO_WRITE	; Write out INFO structure

	 clc			; Indicate all went well
STATE_ON_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STATE_ON endp			; End STATE_ON procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_AUTO

	 MEND			; End UTIL_OFF module
