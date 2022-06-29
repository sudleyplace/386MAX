;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_HMA.ASV   1.1   06 Aug 1992 13:18:04   HENRY  $

	 title	 XMS_HMA -- XMS HMA Tester
	 page	 58,122
	 name	 XMS_HMA
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'
	       Tail    segment DTAIL, para-aligned,  public, class 'data'
	       Group HGROUP:
	       Program segment HCODE, para-aligned,  public, class 'hcode'

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
	 include HMA.INC
	 include XMS.INC
	 include XMS_TEST.INC
.list


PGROUP	 group	 CODE,DATA,TEXT,DTAIL
HGROUP	 group	 HCODE


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte
	 extrn	 UGRSEG:word
	 extrn	 EXTSIZE:word

	 public  PHMASTART
PHMASTART dd	 ?		; Start of HMA test program

	 public  HGRSEG
HGRSEG	 dw	 ?		; Segment of HGROUP

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 LCLENA_A20:near
	 extrn	 LCLDIS_A20:near

	 NPPROC  CHECK_HMA -- Check The HMA
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check the HMA

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

; Get and save current extended memory size

	 DISPLAY '様> Checking HMA status...'

; Request the HMA

	 DISPLAY "Requesting HMA"
	 mov	 dx,-1		; Request it all
	 mov	 ah,@XMS_REQHMA ; Function to request High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we got it
	 SETMSG  "Unable to request HMA",XMS
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

	 DISPLAY "   Ensuring BIOS extended memory size is zero"
	 mov	 ah,88h 	; Code to get extended memory size
	 int	 15h		; Request BIOS service

	 cmp	 ax,0		; Ensure zero
	 SETMSG  "Extended memory size is non-zero"
	 MJ ne	 CHECK_HMA_ERR	; Jump if not

; Multiple requests of the HMA

	 DISPLAY "様> Multiple Requests of HMA"
	 mov	 cx,20		; Attempt to request it again this many times
CHECK_HMA_NEXT1:
	 DISPLAY "   Attempting to Request HMA"
	 xor	 bl,bl		; Ensure set to known value
	 mov	 dx,-1		; Request it all
	 mov	 ah,@XMS_REQHMA ; Function to request High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,0		; Ensure we failed
	 SETMSG  "Incorrectly able to request HMA" ; No error code
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

	 cmp	 bl,91h 	; Ensure correct error code
	 SETMSG  "Incorrect error code when requesting HMA",XMS
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

	 DISPLAY "   Ensuring BIOS extended memory size is zero"
	 mov	 ah,88h 	; Code to get extended memory size
	 int	 15h		; Request BIOS service

	 cmp	 ax,0		; Ensure zero
	 SETMSG  "Extended memory size is non-zero"
	 MJ ne	 CHECK_HMA_ERR	; Jump if not

	 loop	 CHECK_HMA_NEXT1 ; Jump if more iterations

; Release the HMA

	 DISPLAY "Releasing HMA"
	 mov	 ah,@XMS_RELHMA ; Function to release High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release HMA",XMS
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

; Multiple releases of the HMA

	 DISPLAY "様> Multiple Releases of HMA"
	 mov	 cx,20		; Attempt to release it again this many times
CHECK_HMA_NEXT2:
	 DISPLAY "   Attempting to Release HMA"
	 mov	 ah,@XMS_RELHMA ; Function to release High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,0		; Ensure we failed
	 SETMSG  "Incorrectly able to release HMA" ; No error code
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

	 cmp	 bl,93h 	; Ensure correct error code
	 SETMSG  "Incorrect error code when releasing HMA",XMS
	 MJ ne	 CHECK_HMA_ERR	; Jump if we didn't

	 DISPLAY "   Ensuring BIOS extended memory size is same as at start"
	 mov	 ah,88h 	; Code to get extended memory size
	 int	 15h		; Request BIOS service

	 cmp	 ax,EXTSIZE	; Ensure same
	 SETMSG  "Extended memory size is not the same"
	 MJ ne	 CHECK_HMA_ERR	; Jump if not

	 loop	 CHECK_HMA_NEXT2 ; Jump if more iterations

; Request HMA, locally enable A20, move code to HMA, and execute it

	 DISPLAY "様> Testing code in HMA"

	 DISPLAY "   Requesting HMA"
	 mov	 dx,-1		; Request it all
	 mov	 ah,@XMS_REQHMA ; Function to request High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we got it
	 SETMSG  "Unable to request HMA",XMS
	 jne	 short CHECK_HMA_ERR ; Jump if we didn't

	 call	 LCLENA_A20	; Attempt to locally enable the A20 line
	 jne	 short CHECK_HMA_ERR ; Jump if something went wrong

	 DISPLAY "   Moving code to HMA"
	 REGSAVE <ds,es>	; Save for a moment

	 mov	 ax,seg HMASEG	; Get segment of HMA
	 mov	 es,ax		; Address it
	 assume  es:HMASEG	; Tell the assembler about it

	 lea	 di,HMASTART	; ES:DI ==> start of local HMA code
	 mov	 PHMASTART.VSEG,es ; Save for later use
	 mov	 PHMASTART.VOFF,di ; Save for later use

	 mov	 ds,HGRSEG	; Get HGROUP segment
	 assume  ds:HGROUP	; Tell the assembler about it

	 lea	 si,HMA_TEST	; DS:SI ==> start of HMA test code
	 mov	 cx,HMA_TEST_LEN ; Get # bytes in test code
     rep movsb			; Move it to the HMA

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 DISPLAY "   Executing code in HMA"
	 call	 PHMASTART	; Call the code
	 jc	 short CHECK_HMA_ERR ; Jump if something went wrong

; Release the HMA and locally disable the A20 line

	 DISPLAY "   Releasing HMA"
	 mov	 ah,@XMS_RELHMA ; Function to release High Memory Area
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure we released it
	 SETMSG  "Unable to release HMA",XMS
	 jne	 short CHECK_HMA_ERR ; Jump if we didn't

	 call	 LCLDIS_A20	; Attempt to locally disable the A20 line
	 jne	 short CHECK_HMA_ERR ; Jump if something went wrong

	 clc			; Indicate all went well

	 jmp	 short CHECK_HMA_EXIT ; Join common exit code

CHECK_HMA_ERR:
	 stc			; Indicate we had a problem
CHECK_HMA_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_HMA endp			; End CHECK_HMA procedure
	 NPPROC  MEM_SHRINK -- Shrink Our Memory Usage
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Shrink our memory usage.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,dx>	; Save registers

	 mov	 ax,cs		; Get current segment
	 lea	 bx,ZTAIL[16-1] ; Get offset to tail of data segment,
				; and start of HGROUP
	 shr	 bx,4-0 	; Convert from bytes to para
	 add	 ax,bx		; Add to get segment of HGROUP/HCODE
	 mov	 HGRSEG,ax	; Save for later use

	 lea	 bx,HTAIL[16-1] ; Get offset to tail of hdata segment,
				; and start of UGROUP
	 shr	 bx,4-0 	; Convert from bytes to para
	 add	 ax,bx		; Add to get segment of UGROUP/UCODE
	 mov	 UGRSEG,ax	; Save for later use

; Minimize our memory allocation block

	 mov	 bx,HGRSEG	; Get HGROUP segment
	 add	 bx,(HMA_TEST_LEN+16-1)/4 ; Plus length in paras
	 mov	 ax,cs		; Get current segment
	 sub	 bx,ax		; Difference is new size in paras
	 DOSCALL @MODMEM	; Modify it
	 SETMSG  "Unable to minimize our own memory block"
				; Return with CF set/clear

	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MEM_SHRINK endp 		; End MEM_SHRINK procedure

CODE	 ends			; End CODE segment


HCODE	 segment para public 'hcode' ; Start HCODE segment
	 assume  cs:HGROUP

	 FPPROC  HMA_TEST -- HMA Test Code
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

HMA test code

|

	 REGSAVE <>		; Save registers


	 clc			; Indicate all went well

	 jmp	 short HMA_TEST_EXIT ; Join common error code

HMA_TEST_ERR:
	 stc			; Indicate we had a problem
HMA_TEST_EXIT:
	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

HMA_TEST endp			; End HMA_TEST procedure

HMA_TEST_LEN equ $-HMA_TEST	; Length of HMA test code

HTAIL	 label	 near		; End of HGROUP code

HCODE	 ends			; End HCODE segment

	 MEND			; End XMS_HMA module
