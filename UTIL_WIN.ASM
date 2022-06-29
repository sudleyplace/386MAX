;' $Header:   P:/PVCS/MAX/386MAX/UTIL_WIN.ASV   1.2   30 May 1997 10:46:44   BOB  $
	 title	 UTIL_WIN -- 386MAX Utility Program -- WINOUT
	 page	 58,122
	 name	 UTIL_WIN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  UTIL_COM.ASM

Original code by:  Henry Groover, October 1992.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include PTR.INC
	 include EMM2CALL.INC

	 include COMM_OEM.INC
if @OEM_WIN3
	 include QMAXWIN3.INC
endif				; IF @OEM_WIN3
.list

PGROUP	 group	 CODE,DATA

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 PORT67:word

if @OEM_WIN3
	 public  WINVXD_VEC,WINRUN
WINVXD_VEC dd	 ?		; Pointer to Windows Virtual Device API Entry Point
WINRUN	 db	 0		; 1 = running under Windows, 0 = not

endif				; IF @OEM_WIN3

DATA	 ends			; End DATA segment

CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_WIN3
	 NPPROC  WINOUT_INIT -- Set WINRUN and WINVXD_VEC
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

 See if we're running under Windows 3.  If so, set WINRUN to 1, and
 stash the vector of our VxD in WINVXD_VEC.

On exit:
CF=1	 Error occurred initializing VxD vector.
CF=0	 OK

|

	 REGSAVE <ax,bx,di,es>	; Save

	 mov	 ax,1600h	; Code for Windows/386 Installation Check
	 int	 2Fh		; Request multiplexor service
				; AL = 00h if not running
				; AL = 80h if not running
				; AL = 01h if Version 2.xx running
				; AL = FFh if Version 2.xx running
				; AL = Major version #, AH = Minor ...

	 test	 al,7Fh 	; Test for 00h and 80h
	 jz	 short WINOUT_INITEXIT ; Jump if not running (note CF=0)

	 cmp	 al,01h 	; Izit 2.xx?
	 je	 short WINOUT_INITEXIT ; Jump if so (note CF=0)

	 cmp	 al,0FFh	; Izit the other 2.xx?
	 je	 short WINOUT_INITEXIT ; Jump if so (note CF=0)

	 mov	 WINRUN,1	; Mark as running under Windows

	 xor	 di,di		; In case we're not running Windows 3???
	 mov	 es,di		; ES:DI == 0:0
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,1684h	; Function code for Get Device Entry Point
	 mov	 bx,@VXD_ID	; Our device ID
	 int	 2Fh		; Request multiplexor support
	 assume  es:nothing	; Tell the assembler about it
				; Return with ES:DI ==> Device API Entry Point

	 mov	 ax,es		; Check for error
	 or	 ax,di		; ...
	 cmp	 ax,1		; Set CF if pointer is 0:0
	 jc	 short WINOUT_INITEXIT ; Jump if something went wrong (note CF=1)

	 mov	 WINVXD_VEC.VOFF,di ; Save for later use
	 mov	 WINVXD_VEC.VSEG,es ; ...
WINOUT_INITEXIT:
	 REGREST <es,di,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

WINOUT_INIT endp		; End WINOUT_INIT procedure
endif				; IF @OEM_WIN3

	 NPPROC  WINOUT -- Windows/EMM Out Function
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

AH	 =	 EMMOUT function code

On exit:

AH	 =	 return code

|

	 push	 bp		; Save for a moment

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short WINOUT1	; Jump if so
endif				; IF @OEM_WIN3
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT 		; Perform the function
				; Return error code in AH
	 mov	 sp,bp		; Restore
if @OEM_WIN3
	 jmp	 short WINOUT_EXIT ; Join common code

WINOUT1:
	 push	 @VXDAPI_UTIL	; Code to request Utility service
	 call	 WINVXD_VEC	; Request Windows Virtual Device API service
WINOUT_EXIT:
endif				; IF @OEM_WIN3
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WINOUT	 endp			; End WINOUT procedure

CODE	 ends			; End CODE segment

	 MEND			; End UTIL_WIN module
