;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_EDG.ASV   1.2   29 Oct 1992 16:34:28   DAVID  $

	 title	 XMS_EDG -- XMS Edge Conditions Tester
	 page	 58,122
	 name	 XMS_EDG
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
	 include PTR.INC

	 include XMS_TEST.INC
.list

PGROUP	 group	 CODE,DATA,TEXT


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte
	 extrn	 EXTMOVE:tbyte

	 extrn	 HNDL1:word,HNDL1_LEN:word
	 extrn	 HNDL2:word,HNDL2_LEN:word

DATA	 ends			; End DATA segment


TEXT	 segment use16 byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 SPLIT_MEM:near
	 extrn	 REL_HNDL12:near

	 NPPROC  CHECK_EDGE -- Check Edge Conditions
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check edge conditions

|

	 pusha			; Save all GP registers

	 DISPLAY "様> Checking edge conditions"

	 call	 EDGE_LEN	; Check move length edges
	 jc	 short CHECK_EDGE_ERR ; Jump if something went wrong

	 call	 EDGE_XMS	; Check move length edges
	 jc	 short CHECK_EDGE_ERR ; Jump if something went wrong

;;;;;;;; call	 EDGE_QRY	; Check query XMB size edges
;;;;;;;; jc	 short CHECK_EDGE_ERR ; Jump if something went wrong




	 clc			; Indicate all went well

	 jmp	 short CHECK_EDGE_EXIT ; Join common exit code

CHECK_EDGE_ERR:
	 stc			; Indicate something went wrong
CHECK_EDGE_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_EDGE endp 		; End CHECK_EDGE procedure
	 NPPROC  EDGE_LEN -- Check Move Length Edges
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check move length edges

|

	 pusha			; Save all GP registers

	 DISPLAY "様> Checking length zero move offset edge conditions"

; Move zero bytes at the end+1 of block #1 to end of block #2

	 call	 SPLIT_MEM	; Split it up
	 MJ c	 EDGE_LEN_ERR	; Jump if something went wrong

; Set source and destin handles

	 mov	 ax,HNDL1	; Get handle #1
	 mov	 EXTMOVE.EXTMOVE_SHNDL,ax ; Save as source handle

	 mov	 ax,HNDL2	; Get handle #2
	 mov	 EXTMOVE.EXTMOVE_DHNDL,ax ; Save as destin handle

; Set length as zero

	 mov	 EXTMOVE.EXTMOVE_LEN.ELO,0000h ; Length is 0KB
	 mov	 EXTMOVE.EXTMOVE_LEN.EHI,0000h

; Set source offset as end+1 of block #1

	 SETLEN  1,S,0,0,1	; #1, source, subtract 0KB, 0 bytes, add 1 byte

; Set destin offset as end of block #2

	 SETLEN  2,D,0,0,0	; #2, destin, subtract 0KB, 0 bytes, add 0 bytes

	 DISPLAY "   Moving zero length from end+1 of Handle #1 to end of Handle #2"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 xor	 bl,bl		; Ensure set to know value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 bl,0A4h	; Ensure source offset is invalid
	 SETMSG  "Incorrect error code on invalid source offset",XMS
	 MJ ne	 EDGE_LEN_ERR	; No luck today

; Set source offset as end of block #1

	 SETLEN  1,S,0,0,0	; #1, source, subtract 0KB, 0 bytes, add 0 bytes

; Set destin offset as end+1 of block #2

	 SETLEN  2,D,0,0,1	; #2, destin, subtract 0KB, 0 bytes, add 1 byte

	 DISPLAY "   Moving zero length from end of Handle #1 to end+1 of Handle #2"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 xor	 bl,bl		; Ensure set to know value
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 bl,0A6h	; Ensure destin offset is invalid
	 SETMSG  "Incorrect error code on invalid destin offset",XMS
	 jne	 EDGE_LEN_ERR	; No luck today

; Set source offset as end of block #1

	 SETLEN  1,S,0,0,0	; #1, source, subtract 0KB, 0 bytes, add 0 bytes

; Set destin offset as end of block #2

	 SETLEN  2,D,0,0,0	; #2, destin, subtract 0KB, 0 bytes, add 0 bytes

	 DISPLAY "   Moving zero length from end of Handle #1 to end of Handle #2"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Ensure no error
	 SETMSG  "Unable to move zero length from end of Hanlde #1 to end of Handle #2",XMS
	 jne	 short EDGE_LEN_ERR ; No luck today

	 call	 REL_HNDL12	; Release handles 1 and 2
	 jc	 short EDGE_LEN_ERR ; Jump if something went wrong

	 clc			; Indicate all went well

	 jmp	 short EDGE_LEN_EXIT ; Join common exit code

EDGE_LEN_ERR:
	 stc			; Indicate something went wrong
EDGE_LEN_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EDGE_LEN endp			; End EDGE_LEN procedure
	 NPPROC  EDGE_QRY -- Check Query XMB Size Edges
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check query XMB size edges

|

	 REGSAVE <ax,bx,dx>	; Save registers

	 DISPLAY "様> Checking correct error code when all EMBs allocated"

	 call	 SPLIT_MEM	; Split it up
	 jc	 short EDGE_QRY_ERR ; Jump if something went wrong

	 DISPLAY "   Requesting free size"
	 mov	 ah,@XMS_QRYXMB ; Function to query XMB size
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,0		; Check return code
	 SETMSG  "Incorrect error code for no extended memory",XMS
	 jne	 short EDGE_QRY_ERR ; No luck today

	 cmp	 bl,0A0h	; Check error code
	 SETMSG  "Incorrect error code for no extended memory",XMS
	 jne	 short EDGE_QRY_ERR ; No luck today

	 call	 REL_HNDL12	; Release handles 1 and 2
	 jc	 short EDGE_QRY_ERR ; Jump if something went wrong

	 clc			; Indicate all went well

	 jmp	 short EDGE_QRY_EXIT ; Join common exit code

EDGE_QRY_ERR:
	 stc			; Indicate something went wrong
EDGE_QRY_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EDGE_QRY endp			; End EDGE_QRY procedure

	 NPPROC  EDGE_XMS -- Check Allocate XMB Failure Results
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check allocate XMB failure results

|

	 REGSAVE <ax,bx,edx>	; Save registers

	 DISPLAY "様> Checking allocation when not enough extended memory"

; Allocate 64 MB to check the results of a failure -- assume it will fail

	 DISPLAY "   Allocating XMB and failing"
	 mov	 dx,-1		; Allocate 64 MB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 call	 EDGE_XMS_SUB	; Check the results
	 jc	 EDGE_XMS_ERR	; Jump on error

; Allocate 4 TB to check the results of a failure -- assume it will fail

	 DISPLAY "   Allocating 32-bit XMB and failing"
	 mov	 edx,-1 	; Allocate 4 TB
	 mov	 ah,@XMS_GET2XMB ; Function to allocate a 32-bit XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 call	 EDGE_XMS_SUB	; Check the results
	 jc	 EDGE_XMS_ERR	; Jump on error

	 clc			; Indicate all went well

	 jmp	 short EDGE_XMS_EXIT ; Join common exit code

EDGE_XMS_ERR:
	 stc			; Indicate something went wrong
EDGE_XMS_EXIT:
	 REGREST <edx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EDGE_XMS endp			; End EDGE_XMS procedure

	 NPPROC  EDGE_XMS_SUB -- Check Allocate XMB Failure Results Subroutine
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check allocate XMB failure results

|

	 cmp	 ax,0		; Check return code
	 SETMSG  "Incorrect return code for not enough extended memory",XMS
	 jne	 short EDGE_XMS_SUB_ERR ; No luck today

	 cmp	 dx,0		; Check handle
	 SETMSG  "Incorrect handle for not enough extended memory",XMS
	 jne	 short EDGE_XMS_SUB_ERR ; No luck today

	 cmp	 bl,0A0h	; Check error code
	 SETMSG  "Incorrect error code for not enough extended memory",XMS
	 jne	 short EDGE_XMS_SUB_ERR ; No luck today

	 clc			; Indicate all went well

	 jmp	 short EDGE_XMS_SUB_EXIT ; Join common exit code

EDGE_XMS_SUB_ERR:
	 stc			; Indicate something went wrong
EDGE_XMS_SUB_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EDGE_XMS_SUB endp		; End EDGE_XMS_SUB procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_EDG module
