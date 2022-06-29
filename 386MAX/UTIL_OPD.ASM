;' $Header:   P:/PVCS/MAX/386MAX/UTIL_OPD.ASV   1.2   30 May 1997 10:46:30   BOB  $
	 title	 UTIL_OPD -- 386MAX Utility Program -- Optimization Progress Display
	 page	 58,122
	 name	 UTIL_OPD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Henry Groover, July 1991.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include VIDCALL.INC
	 include ASCII.INC

	 include UTIL_OPT.INC
.list

PGROUP	 group	 ACODE,UDATA


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 public  _OPT_PROGRESS
_OPT_PROGRESS	label	dword
		dw	PGROUP:SHOW_PROGRESS,?

	 public  OP_DISPLAY,OP_DISPPCTHUN,OP_DISPPCT
OP_DISPLAY	db	'Percent completed: '
OP_DISPPCTHUN	db	' '
OP_DISPPCT	db	'00%',CR,0

UDATA	 ends			; End UDATA segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 FPPROC  SHOW_PROGRESS -- Display optimization progress
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT |

The ORDFIT procedure in UTIL_OPT.ASM calls this procedure C style,
with a far pointer to OPROG_STR (defined in UTIL_OPT.INC).

This module is linked with UTIL_OPT and other modules for 386UTIL,
386MAX, and 386LOAD.  MAXIMIZE has its own version of SHOW_PROGRESS,
as does Move'EM.

Input:
Arguments on stack (shown above)
Output:
None (function is type void)

|

ARG_STR  struc
	 dw	?		; Caller's BP saved on stack
	 dd	?		; Return address
pptr	 dd	?		; Far pointer to OPROG_STR structure
ARG_STR  ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Stack!

	 REGSAVE <ax,bx,cx,dx,si,es> ; Save registers

	 lea	 si,OP_DISPLAY	; Get pointer to display buffer
	 les	 bx,[bp].pptr	; Get pointer to caller info structure
	 assume  es:nothing	; Tell the assembler about it
	 mov	 al,es:[bx].OPROG_PCT ; Get percentage
	 cmp	 al,100 	; Izit 100%?
	 jnb	 short @F	; Handle specially

	 aam			; AH=10's, AL=1's
	 or	 ax,3030h	; Convert to ASCII
	 xchg	 ah,al		; Swap bytes
	 mov	 OP_DISPPCT.ELO,ax ; Put in display buffer
	 jmp	 short OP_DISPOUT ; Join common code

@@:
	 mov	 OP_DISPPCTHUN,'1' ; Put 1 in hundreds place
	 mov	 OP_DISPPCT.ELO,'00' ; Put 0's in 10,1 places

OP_DISPOUT:
	 lodsb			; Get character to display
	 or	 al,al		; Izit 0?
	 jz	 short OPT_PROGRESS_EXIT ; If so, bail out

	 mov	 bl,7		; Default color
	 VIDCALL @SETTTY	; DIsplay character in AL
	 jmp	 short OP_DISPOUT ; Get next

OPT_PROGRESS_EXIT:
	 REGREST <es,si,dx,cx,bx,ax> ; Restore registers

	 pop	 bp		; Restore BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SHOW_PROGRESS endp		; End SHOW_PROGRESS procedure

ACODE	 ends			; End ACODE segment

	 MEND			; End UTIL_STR module
