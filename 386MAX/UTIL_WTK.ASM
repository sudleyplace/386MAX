;' $Header:   P:/PVCS/MAX/386MAX/UTIL_WTK.ASV   1.2   30 May 1997 10:46:46   BOB  $
	 title	 UTIL_WTK -- 386MAX Utility Program -- WTK= Action
	 page	 58,122
	 name	 UTIL_WTK

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

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
	 include BITFLAGS.INC
	 include EMM2CALL.INC

	 include QMAX_CTL.INC
	 include QMAX_OEM.INC
.list

if @OEM_WTK
PGROUP	 group	 CODE,DATA,NCODE


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

if @OEM_WIN3
	 extrn	 MSG_WINERR:byte
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 extrn	 PORT67:word
	 extrn	 INFO_CTL:byte
	 extrn	 MSG_NOWTK:byte

	 extrn	 MSG_WTK0:byte
	 extrn	 MSG_WTK1:byte
	 extrn	 MSG_WTKHMA:byte

DATA	 ends			; End DATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 INFO_READ:near
	 extrn	 INFO_WRITE:near
	 extrn	 CHECK_STATE:near
	 extrn	 SEND_CMD:near

	 NPPROC  ACT_WTK0 -- Action To Disable Weitek Coprocessor
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Disable Weitek coprocessor

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,dx,bp> ; Save registers

	 xor	 eax,eax	; Zero entire register
	 int	 11h		; Get equipment flags into EAX

	 test	 eax,@BIT24	; Check for Weitek 1167
	 jz	 short ACT_WTK0_ERR0 ; Not installed

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short ACT_WTK0_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 test	 eax,@BIT23	; Check for activity
	 jz	 short ACT_WTK0_MSG ; Already disabled

	 mov	 dx,GLB_FLAG	; Save current state

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 short ACT_WTK0_ERR ; Jump if not successful

	 mov	 bx,@GLB_WTK	; Flip this flag
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_GLBFLAG	; Call PRG in extended memory
	 mov	 sp,bp		; Restore

	 or	 ah,ah		; Check return code
	 jnz	 short ACT_WTK0_ERR ; Something went wrong

; We've disabled Weitek support --- restore to previous state

	 test	 dx,@GLB_AUTO	; Were we AUTO previously?
	 jnz	 short ACT_WTK0_OFF ; Yes, attempt to go AUTO inactive

	 test	 dx,@GLB_ON	; Were we ON previously?
	 jnz	 short ACT_WTK0_FLAG ; Yes, let's stay that way
ACT_WTK0_OFF:
	 mov	 INFO_CTL,@CTL_OFF ; Mark as state OFF
	 call	 SEND_CMD	; Attempt to set state

	 cmp	 INFO_CTL,0	; Check for success
	 jne	 short ACT_WTK0_FLAG ; Jump if unsuccessful

	 call	 INFO_READ	; Read in INFO structure

	 and	 GLB_FLAG,not (@GLB_ON or @GLB_WTK) ; Mark as OFF and W=OFF

	 jmp	 short ACT_WTK0_WRITE ; Join common write code

ACT_WTK0_FLAG:
	 call	 INFO_READ	; Read in INFO structure

	 and	 GLB_FLAG,not @GLB_WTK ; Mark as W=OFF
ACT_WTK0_WRITE:
	 call	 INFO_WRITE	; Write out INFO structure
ACT_WTK0_MSG:
	 call	 DISP_WTK	; Display the Weitek state, if present

	 clc			; Indicate all went well

	 jmp	 short ACT_WTK0_EXIT ; Join common exit code

if @OEM_WIN3
ACT_WTK0_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short ACT_WTK0_ERR ; Join common error code
endif				; IF @OEM_WIN3

ACT_WTK0_ERR0:
	 lea	 dx,MSG_NOWTK	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
ACT_WTK0_ERR:
	 stc			; Indicate something went wrong
ACT_WTK0_EXIT:
	 REGREST <bp,dx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ACT_WTK0 endp			; End ACT_WTK0 procedure
	 NPPROC  ACT_WTK1 -- Action To Enable Weitek Coprocessor
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Enable Weitek coprocessor

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,dx,bp> ; Save registers

	 xor	 eax,eax	; Zero entire register
	 int	 11h		; Get equipment flags into EAX

	 test	 eax,@BIT24	; Check for Weitek 1167
	 jz	 short ACT_WTK1_ERR0 ; Not installed

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short ACT_WTK1_WINERR ; Jump if so
endif				; IF @OEM_WIN3

; See if the HMA is in use or if the 1MB wrap is forced disabled

	 test	 GLB_FLAG,@GLB_HMA or @GLB_X1MB
	 jnz	 short ACT_WTK1_ERR1 ; Jump if it is

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 short ACT_WTK1_ERR ; Jump if not successful

	 test	 eax,@BIT23	; Check for activity
	 jnz	 short ACT_WTK1_MSG ; Already enabled

	 mov	 bx,@GLB_WTK	; Flip this flag
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_GLBFLAG	; Call PRG in extended memory
	 mov	 sp,bp		; Restore

	 or	 ah,ah		; Check return code
	 jnz	 short ACT_WTK1_ERR ; Something went wrong

	 call	 INFO_READ	; Read in INFO structure

	 or	 GLB_FLAG,@GLB_WTK ; Mark as W=ON

	 call	 INFO_WRITE	; Write out INFO structure
ACT_WTK1_MSG:
	 call	 DISP_WTK	; Display the Weitek state, if present

	 clc			; Indicate all went well

	 jmp	 short ACT_WTK1_EXIT ; Join common exit code

if @OEM_WIN3
ACT_WTK1_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short ACT_WTK1_ERR ; Join common error code
endif				; IF @OEM_WIN3

ACT_WTK1_ERR0:
	 lea	 dx,MSG_NOWTK	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 short ACT_WTK1_ERR ; Join common error code

ACT_WTK1_ERR1:
	 lea	 dx,MSG_WTKHMA	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
ACT_WTK1_ERR:
	 stc			; Indicate something went wrong
ACT_WTK1_EXIT:
	 REGREST <bp,dx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ACT_WTK1 endp			; End ACT_WTK1 procedure
	 NPPROC  DISP_WTK -- Display the Weitek FPA State
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Display the Weitek FPA state, if present

|

	 REGSAVE <eax,dx>	; Save registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short DISP_WTK_EXIT ; Jump if so
endif				; IF @OEM_WIN3

	 xor	 eax,eax	; Zero entire register
	 int	 11h		; Get equipment flags into EAX

	 test	 eax,@BIT24	; Check for Weitek 1167
	 jz	 short DISP_WTK_EXIT ; Not installed

	 lea	 dx,MSG_WTK0	; Assume OFF

	 test	 eax,@BIT23	; Check for activity
	 jz	 short DISP_WTK_MSG ; Already disabled

	 lea	 dx,MSG_WTK1	; It's ON
DISP_WTK_MSG:
	 call	 STROUT 	; Display string at DS:DX
DISP_WTK_EXIT:
	 REGREST <dx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

DISP_WTK endp			; End DISP_WTK procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_WTK

	 MEND			; End UTIL_WTK module
