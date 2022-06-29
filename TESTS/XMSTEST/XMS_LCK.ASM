;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_LCK.ASV   1.1   06 Aug 1992 13:18:10   HENRY  $

	 title	 XMS_LCK -- XMS XMB Lock Tester
	 page	 58,122
	 name	 XMS_LCK
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include XMS.INC
	 include XMS_TEST.INC
.list


PGROUP	 group	 CODE,DATA,TEXT


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMS_GETXMB:byte
	 extrn	 XMS_MODXMB:byte

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte

	 extrn	 HNDL1:word
	 extrn	 HNDL1_LEN:word
	 extrn	 HNDL2:word

	 extrn	 MODMEM_TOT:word
	 extrn	 MODMEM_BIG:word

DATA	 ends			; End DATA segment


TEXT	 segment use16 byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 QRY_XMB:near
	 extrn	 ALLOC_XMB:near
	 extrn	 ALTDEALLOC_XMB:near
	 extrn	 DEALLOC_XMB:near
	 extrn	 SPLIT_MEM:near

	 NPPROC  CHECK_LCK -- Check XMB Locking
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check XMS locking

|

	 pusha			; Save all GP registers

	 DISPLAY "ออ> Checking XMS Lock"

; Get amount of available memory

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 MJ c	 CHECK_LCK_ERR	; No memory free

	 mov	 MODMEM_TOT,dx	; Save for later use
	 mov	 MODMEM_BIG,ax	; Save for later use

; Allocate largest block

	 mov	 dx,MODMEM_BIG	; Get size of largest block
	 mov	 HNDL1_LEN,dx	; Save for later use
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate largest block of extended memory",XMS
	MJ ne	 CHECK_LCK_ERR	; No luck today

	 mov	 HNDL1,dx	; Save as handle #

; Re-allocate Handle #1 down to half size

	 DISPLAY "   Re-allocating Handle #1 down to half size"

	 mov	 dx,HNDL1	; Get handle #
	 mov	 bx,MODMEM_BIG	; Get original requested size
	 shr	 bx,1		; Halve the size
	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate Handle #1 down to half size",XMS
	 MJ ne	 CHECK_LCK_ERR	; No luck today

; Re-allocate memory for handle #1 to previous size

	 DISPLAY "   Re-allocating Handle #1 back to previous size"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 bx,HNDL1_LEN	; Get previous size of Handle #1
	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate Handle #1 back to previous size",XMS
	 MJ ne	 CHECK_LCK_ERR	; No luck today

; Lock handle #1

	 DISPLAY "   Locking Handle #1"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 ah,@XMS_LCKXMB ; Function to lock an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to lock Handle #1",XMS
	 MJ ne	 CHECK_LCK_ERR	; No luck today

; Unlock handle #1

	 DISPLAY "   Unlocking Handle #1"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 ah,@XMS_UNLXMB ; Function to unlock an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to unlock Handle #1",XMS
	 MJ ne	 CHECK_LCK_ERR	; No luck today

; Release handle #1

	 DISPLAY "   Releasing Handle #1"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 ah,@XMS_RELXMB ; Function to release an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to release Handle #1",XMS
	 MJ ne	 CHECK_LCK_ERR	; No luck today

	 clc			; Indicate all went well

	 jmp	 short CHECK_LCK_EXIT ; Join common exit code

CHECK_LCK_ERR:
	 stc			; Indicate something went wrong
CHECK_LCK_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_LCK endp			; End CHECK_LCK procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_LCK module
