;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_UMB.ASV   1.2   22 Feb 1994 12:48:00   HENRY  $

	 title	 XMS_UMB -- XMS UMB Tester
	 page	 58,122
	 name	 XMS_UMB
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'
	       Group UGROUP:
	       Program segment UCODE, para-aligned,  public, class 'codeu'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.286c
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include XMS.INC
	 include MAC.INC

	 include XMS_TEST.INC
.list


PGROUP	 group	 CODE,DATA,TEXT
UGROUP	 group	 UCODE


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte

	 public  PUMBSTART
PUMBSTART dd	 ?		; Start of UMB test program

	 public  UGRSEG
UGRSEG	 dw	 ?		; Segment of UGROUP

	 public  UMBSEG1,UMBSEG2,UMBSIZE
UMBSEG1  dw	 ?		; UMB segment #1
UMBSEG2  dw	 ?		; UMB segment #2
UMBSIZE  dw	 ?		; Size of UMBs

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  CHECK_UMB -- Check Upper Memory Blocks
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check upper memory blocks

|

	 pusha			; Save all GP registers

	 DISPLAY "様> Checking UMBs"

; Find size of largest UMB

	 DISPLAY "   Requesting UMB free size"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 mov	 dx,-1		; Impossible value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB"
	MJ e	 CHECK_UMB_ERR	; Jump if something went wrong

	 cmp	 bl,0B0h	; Check error code
	 je	 short @F	; Jump if UMBs supported

	 cmp	 bl,80h 	; Check error code
	MJ e	 CHECK_UMB_EXIT ; Jump if function not implemented

	 cmp	 bl,0B1h	; Check error code
	 SETMSG  "Incorrect return code for GETUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 jmp	 CHECK_UMB_EXIT ; Jump if no UMBs available

@@:
	 mov	 UMBSIZE,dx	; Save as # paras in UMBs

; Allocate a UMB of size DX

	 DISPLAY "様> Allocating UMB"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 mov	 UMBSEG1,bx	; Save for later use

; Move some code into the UMB

	 DISPLAY "   Moving code to UMB"
	 REGSAVE <ds,es>	; Save for a moment

	 mov	 es,UMBSEG1	; Get the UMB segment #1
	 assume  es:UGROUP	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of UMB

	 lea	 di,UMB_TEST	; ES:DI ==> start of local UMB code
	 mov	 PUMBSTART.VSEG,es ; Save for later use
	 mov	 PUMBSTART.VOFF,di ; Save for later use

	 mov	 ds,UGRSEG	; Get UGROUP segment
	 assume  ds:UGROUP	; Tell the assembler about it

	 lea	 si,UMB_TEST	; DS:SI ==> start of UMB test code
	 mov	 cx,UMB_TEST_LEN ; Get # bytes in test code
     rep movsb			; Move it to the HMA

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

; Execute code in the UMB

	 DISPLAY "   Executing code in UMB"
	 call	 PUMBSTART	; Call the code
	MJ c	 CHECK_UMB_ERR	; Jump if something went wrong

; Release the UMB

	 DISPLAY "   Releasing UMB"
	 mov	 ah,@XMS_RELUMB ; Function to release Upper Memory Block
	 mov	 dx,UMBSEG1	; Segment # to release
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release UMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if we didn't

; Allocate and split block

	 DISPLAY "   Requesting UMB free size"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 mov	 dx,-1		; Impossible value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB"
	MJ e	 CHECK_UMB_ERR	; Jump if something went wrong

	 cmp	 dx,UMBSIZE	; Ensure same
	 SETMSG  "UMBSIZE not same as at start"
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 sub	 dx,4		; Less size of LSEG header
	 shr	 dx,1		; Halve the value to split

; Allocate a UMB of size DX

	 DISPLAY "様> Allocating UMB #1"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 mov	 UMBSEG1,bx	; Save for later use

; Allocate a UMB of size DX

	 mov	 dx,UMBSIZE	; Get size of UMB area
	 sub	 dx,4		; Less size of LSEG header
	 shr	 dx,1		; Halve the value to split
	 sub	 dx,2		; Less a couple to ensure three-way split

	 DISPLAY "様> Allocating UMB #2"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 mov	 UMBSEG2,bx	; Save for later use

; Release UMB #1

	 DISPLAY "   Releasing UMB #1"
	 mov	 ah,@XMS_RELUMB ; Function to release Upper Memory Block
	 mov	 dx,UMBSEG1	; Segment # to release
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release UMB #1",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if we didn't

; Release UMB #2

	 DISPLAY "   Releasing UMB #2"
	 mov	 ah,@XMS_RELUMB ; Function to release Upper Memory Block
	 mov	 dx,UMBSEG2	; Segment # to release
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release UMB #2",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if we didn't

; Find size of largest UMB to ensure same as UMBSIZE

	 DISPLAY "   Requesting UMB free size"
	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 mov	 dx,-1		; Impossible value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB"
	MJ e	 CHECK_UMB_ERR	; Jump if something went wrong

	 cmp	 dx,UMBSIZE	; Ensure same
	 SETMSG  "UMBSIZE not same as at start"
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

; Test re-allocate of UMB

@UMB_SLOP equ	 2

	 mov	 dx,UMBSIZE	; Get size of UMB area
	 sub	 dx,@UMB_SLOP	; Less a little to allow upwards re-allocate

	 DISPLAY "様> Allocating UMB"

	 push	 dx		; Save expected size

	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 pop	 dx		; Restore expected size

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for GETUMB",XMS

	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 mov	 UMBSEG1,bx	; Save for later use

	 DISPLAY "    Checking actual size allocated"

	 push	 es		; Save

	 dec	 bx		; Back off to UMB MAC entry
	 mov	 es,bx		; Address UMB MAC
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_NPAR,dx ; Izit the expected size?

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 SETMSG  "Size allocated doesn't match expected size",XMS

	MJ ne	 CHECK_UMB_ERR	; Jump if size doesn't match

	 DISPLAY "様> Re-allocating UMB to same size"
	 mov	 bx,UMBSIZE	; Get size of UMB area
	 sub	 bx,@UMB_SLOP	; Less a little to allow upwards re-allocate
	 mov	 dx,UMBSEG1	; Get segment of UMB
	 mov	 ah,@XMS_MODUMB ; Function to re-allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for MODUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 DISPLAY "様> Re-allocating UMB to zero size"
	 xor	 bx,bx		; Get new size of UMB area
	 mov	 dx,UMBSEG1	; Get segment of UMB
	 mov	 ah,@XMS_MODUMB ; Function to re-allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for MODUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong

	 DISPLAY "様> Re-allocating UMB to larger size"
	 mov	 bx,UMBSIZE	; Get size of UMB area
	 mov	 dx,UMBSEG1	; Get segment of UMB
	 mov	 ah,@XMS_MODUMB ; Function to re-allocate an Upper Memory Block
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 SETMSG  "Incorrect return code for MODUMB",XMS
	MJ ne	 CHECK_UMB_ERR	; Jump if something went wrong


	 DISPLAY "    Checking reallocated size"

	 push	 es		; Save

	 mov	 dx,UMBSIZE	; Get expected size of reallocated UMB
	 mov	 bx,UMBSEG1	; Get UMB segment
	 dec	 bx		; Back off to UMB MAC entry
	 mov	 es,bx		; Address UMB MAC
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_NPAR,dx ; Izit the expected size?

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 SETMSG  "Reallocated size doesn't match expected size",XMS

	MJ ne	 CHECK_UMB_ERR	; Jump if size doesn't match

	 DISPLAY "   Releasing re-allocated UMB"
	 mov	 ah,@XMS_RELUMB ; Function to release Upper Memory Block
	 mov	 dx,UMBSEG1	; Segment # to release
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release re-allocated UMB",XMS
	 jne	 short CHECK_UMB_ERR ; Jump if we didn't







	 clc			; Indicate all went well

	 jmp	 short CHECK_UMB_EXIT ; Join common exit code

CHECK_UMB_ERR:
	 stc			; Indicate something went wrong
CHECK_UMB_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_UMB endp			; End CHECK_UMB procedure

CODE	 ends			; End CODE segment


UCODE	 segment para public 'codeu' ; Start UCODE segment
	 assume  cs:UGROUP

	 FPPROC  UMB_TEST -- UMB Test Code
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

UMB test code

|

	 REGSAVE <>		; Save registers


	 clc			; Indicate all went well

	 jmp	 short UMB_TEST_EXIT ; Join common error code

UMB_TEST_ERR:
	 stc			; Indicate we had a problem
UMB_TEST_EXIT:
	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UMB_TEST endp			; End UMB_TEST procedure

UMB_TEST_LEN equ $-UMB_TEST	; Length of UMB test code

UCODE	 ends			; End UCODE segment

	 MEND			; End XMS_UMB module
