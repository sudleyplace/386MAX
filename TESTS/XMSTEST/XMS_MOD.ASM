;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_MOD.ASV   1.1   06 Aug 1992 13:18:08   HENRY  $

	 title	 XMS_MOD -- XMS XMB Reallocation Tester
	 page	 58,122
	 name	 XMS_MOD
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

	 public  MODMEM_TOT,MODMEM_BIG
MODMEM_TOT dw	 ?
MODMEM_BIG dw	 ?

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

	 NPPROC  CHECK_MOD2 -- Check XMB Reallocation, Secondary Function
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check XMS reallocation, secondary function

|

	 DISPLAY "ออ> Checking Secondary XMS Reallocation"

	 REGSAVE <ax,ebx>	; Save for a moment

	 xor	 ebx,ebx	; Zero high-order word for MOD2XMB
	 mov	 al,@XMS_MOD2XMB ; Get new function
	 xchg	 al,XMS_MODXMB	; Install it, save old function
	 mov	 ah,@XMS_GET2XMB ; Get new function
	 xchg	 ah,XMS_GETXMB	; Install it, save old function
	 call	 CHECK_MOD	; Call primary routine
	 mov	 XMS_GETXMB,ah	; Restore old function
	 mov	 XMS_MODXMB,al	; Restore old function

	 REGREST <ebx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MOD2 endp 		; End CHECK_MOD2 procedure
	 NPPROC  CHECK_MOD -- Check XMB Reallocation, Primary
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check XMS reallocation

|

	 pusha			; Save all GP registers

	 DISPLAY "ออ> Checking XMS Reallocation"

; Get amount of available memory

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 MJ c	 CHECK_MOD_ERR	; No memory free

	 mov	 MODMEM_TOT,dx	; Save for later use
	 mov	 MODMEM_BIG,ax	; Save for later use

; Allocate some memory

	 call	 ALLOC_XMB	; Allocate 'em
	 MJ c	 CHECK_MOD_ERR	; No so fast

; De-allocate every other handle

	 call	 ALTDEALLOC_XMB ; De-allocate 'em
	 MJ C	 CHECK_MOD_ERR	; No so fast

; Allocate all of the rest of memory to two handles

	 call	 SPLIT_MEM	; Split it up
	 MJ c	 CHECK_MOD_ERR	; Jump if something went wrong

; De-allocate the second handle

	 mov	 dx,HNDL2	; Copy to handle register

	 DISPLAY "   De-allocating Handle #2"

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate Handle #2",XMS
	 MJ ne	 CHECK_MOD_ERR	; No luck today

; Request size of Handle #1 and confirm against expected length

	 DISPLAY "   Requesting size of Handle #1"

	 mov	 dx,HNDL1	; Get handle #
	 mov	 ah,@XMS_GETINF ; Function to request handle information
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Unable to request handle information",XMS
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

	 cmp	 dx,HNDL1_LEN	; Check against expected length
	 SETMSG  "Mis-match on Handle #1 length"
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

; Re-allocate Handle #1 down to zero

	 DISPLAY "   Re-allocating Handle #1 down to zero"

	 mov	 dx,HNDL1	; Get handle #
	 xor	 bx,bx		; New requested size
	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate Handle #1 down to zero",XMS
	 MJ ne	 CHECK_MOD_ERR	; No luck today

; Request size of Handle #1 and confirm it's zero

	 DISPLAY "   Requesting size of Handle #1"

	 mov	 dx,HNDL1	; Get handle #
	 mov	 ah,@XMS_GETINF ; Function to request handle information
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Unable to request handle information",XMS
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

	 cmp	 dx,0		; Ensure it's zero
	 SETMSG  "Incorrect size returned for Handle #1"
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

; Re-allocate memory for handle #1 to previous size

	 DISPLAY "   Re-allocating Handle #1 back to previous size"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 bx,HNDL1_LEN	; Get previous size of Handle #1

	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate Handle #1 back to previous size",XMS
	 MJ ne	 CHECK_MOD_ERR	; No luck today

; Request size of Handle #1 and confirm it's same as before

	 DISPLAY "   Requesting size of Handle #1"

	 mov	 dx,HNDL1	; Get handle #
	 mov	 ah,@XMS_GETINF ; Function to request handle information
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Unable to request handle information",XMS
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

	 cmp	 dx,HNDL1_LEN	; Ensure it's same as before
	 SETMSG  "Incorrect size returned for Handle #1"
	 MJ ne	 CHECK_MOD_ERR	; Not a good sign

; Get free extended memory

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 MJ c	 CHECK_MOD_ERR	; No memory free

; Re-allocate memory for Handle #1 to append AX additional bytes

	 DISPLAY "   Re-allocating Handle #1 upwards"

	 mov	 dx,HNDL1	; Get Handle #1
	 mov	 bx,HNDL1_LEN	; Get size of Handle #1
	 add	 bx,ax		; Plus size of largest free block

	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate Handle #1 upwards",XMS
	MJ ne	 CHECK_MOD_ERR	; No luck today

; De-allocate the first handle

	 mov	 dx,HNDL1	; Copy to handle register

	 DISPLAY "   De-allocating Handle #1"

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate Handle #1",XMS
	MJ ne	 CHECK_MOD_ERR	; No luck today

; De-allocate the rest of the handles

	 call	 DEALLOC_XMB	; De-allocate 'em
	 jc	 short CHECK_MOD_ERR ; No so fast

; Allocate an XMB with length 0
	 mov	 dx,0		; Allocate 0KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate XMS handle with length 0",XMS
	 jne	 short CHECK_MOD_ERR ; No luck today

; Reallocate it upwards (DX contains handle)
	 push	 dx		; Save handle

	 mov	 bx,HNDL1_LEN	; Get previous size of Handle #1

	 mov	 ah,XMS_MODXMB	; Function to re-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 pop	 dx		; Restore handle

; De-allocate it
	 push	 ax		; Save result

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate XMB in reallocate from 0 test",XMS

	 pop	 ax		; Get result of re-allocate call

	 jne	 short CHECK_MOD_ERR ; No luck today

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to re-allocate empty handle to larger size",XMS
	 jne	 short CHECK_MOD_ERR ; No luck today

; Get amount of available memory

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 jc	 short CHECK_MOD_ERR ; No memory free

	 cmp	 dx,MODMEM_TOT	; Ensure same as at start
	 SETMSG  "Total available memory not same as at start",XMS
	 jne	 short CHECK_MOD_ERR ; Jump if something went wrong

	 cmp	 ax,MODMEM_BIG	; Ensure same as at start
	 SETMSG  "Total available memory not same as at start",XMS
	 jne	 short CHECK_MOD_ERR ; Jump if something went wrong

	 clc			; Indicate all went well

	 jmp	 short CHECK_MOD_EXIT ; Join common exit code

CHECK_MOD_ERR:
	 stc			; Indicate something went wrong
CHECK_MOD_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MOD endp			; End CHECK_MOD procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_MOD module
