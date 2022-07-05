;' $Header:   P:/PVCS/MAX/386MAX/UTIL_STR.ASV   1.3   30 May 1997 10:46:40   BOB  $
	 title	 UTIL_STR -- 386MAX Utility Program -- String Output
	 page	 58,122
	 name	 UTIL_STR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include BIOSDATA.INC
.list

PGROUP	 group	 ACODE,ADATA


ADATA	 segment use16 dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 UTL_FLAG:word
	 include QMAX_UTL.INC

	 public  LINECNT
LINECNT  dw	 0		; Count of lines displayed so far

	 public  MSG_PAUSE
ifdef LANG_GR
MSG_PAUSE db	 'weiter mit beliebiger Taste...',0
else
MSG_PAUSE db	 'Press any key to continue...',0
endif				; IFDEF LANG_GR
MSG_PAUSELEN equ ($-MSG_PAUSE)-1

	 public  MSG_CRSPCR
MSG_CRSPCR db	 CR,MSG_PAUSELEN dup (' '),CR,0
MSG_CRSPCRLEN equ ($-MSG_CRSPCR)-1

ADATA	 ends			; End ADATA segment


ACODE	 segment use16 byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 NPPROC  CHECK_LINE -- Count Lines and Check Pause
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 inc	 LINECNT	; Count in another line

	 push	 ds		; Save for a moment

	 mov	 ax,seg BIOSDATA ; Address BIOS DATA
	 mov	 ds,ax		; . . .
	 assume  ds:BIOSDATA	; Tell assembler

	 movzx	 ax,EGA_ROWS	; Get number of rows (minus one)

	 pop	 ds		; Restore DS

	 assume  ds:PGROUP	; Tell assembler

; If there's no EGA/VGA (mono only), the EGA_ROWS variable hasn't
; been filled in.  In this case, assume it's a 25-line screen

	and	ax,ax		; Izit zero?
	jnz	short @F	; Jump if not

	mov	ax,25-1 	; Get # screen rows (minus one)
@@:
	 cmp	 LINECNT,ax	; Are we out of lines?
	 jb	 short CHECK_LINE_EXIT ; Not this time

	 mov	 LINECNT,0	; Reset to zero

	 test	 UTL_FLAG,@UTL_COT ; Check on standard output
	 jz	 short CHECK_LINE_EXIT ; Jump if it's redirected

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_PAUSELEN ; Length of message
	 DOSCALL @WRITF2,MSG_PAUSE ; Display the line

	 KEYCALL @GETKEY	; Get and discard a keystroke

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_CRSPCRLEN ; Length of message
	 DOSCALL @WRITF2,MSG_CRSPCR ; Display the line
CHECK_LINE_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_LINE endp 		; End CHECK_LINE procedure
	 NPPROC  STROUT -- String Out Function
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

String out function handling multiple lines
in conjunction with CHECK_LINE.

On entry:

DS:DX	 ==>	 EOS-terminated string to display

|

	 REGSAVE <ax,bx,dx,si>	; Save registers

	 mov	 si,dx		; DS:SI ==> string to display
STROUT_NEXT:
	 lodsb			; Get next character

	 cmp	 al,EOS 	; Check for terminator
	 je	 short STROUT_EOS ; Jump if so

	 cmp	 al,LF		; Check for linefeed
	 jne	 short STROUT_NEXT ; Jump if not

	 mov	 bl,EOS 	; Terminator
	 xchg	 bl,ds:[si]	; Swap with next byte
	 DOSCALL @STROUT	; Display the line
	 xchg	 bl,ds:[si]	; Restore
	 call	 CHECK_LINE	; Count in another line and check for pause

	 mov	 dx,si		; DS:DX ==> start of next line

	 jmp	 short STROUT_NEXT ; Go around again

; Display the last (partial) line

STROUT_EOS:
	 DOSCALL @STROUT	; Display the line
STROUT_EXIT:
	 REGREST <si,dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

STROUT	 endp			; End STROUT procedure

ACODE	 ends			; End ACODE segment

	 MEND			; End UTIL_STR module
