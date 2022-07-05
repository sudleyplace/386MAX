;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SCR.ASV   1.2   30 May 1997 10:45:56   BOB  $
	 title	 QMAX_SCR -- 386MAX Screen Routines
	 page	 58,122
	 name	 QMAX_SCR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include VIDCALL.INC
	 include ASCII.INC
	 include VIDATTR.INC

	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,NCODE,NDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

CODE	 ends			; End CODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  LASTCHAR
LASTCHAR db	 ?		; Last character written by DISP_COLOR

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_SCR_NCODE
@QMAX_SCR_NCODE:		; Mark module start in .MAP file

	 NPPROC  DISP_COLOR -- Display String in Color
	 assume  ds:PGROUP,es:nothing
COMMENT|

Display an EOS-terminated string in color

|

DC_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DC_OFF	 dw	 ?		; Offset in DS of string to display

DC_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,ds> ; Save registers

	 cld			; String ops fowardly

; Note we can't use "seg PGROUP" here as this file is also LINKed
; in with the .COM utility

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 si,[bp].DC_OFF ; DS:SI ==> string to display

	 VIDCALL @GETINF	; Get current information
				; AL = mode
				; AH = # cols
				; BH = page #
	 and	 al,not 80h	; Isolate mode
	 mov	 cl,ah		; Copy # cols

	 mov	 bl,@ATCFwhite or @ATCBblue ; White on blue attributes

	 cmp	 al,03h 	; Color graphics mode?
	 je	 short DISP_COLOR_INIT ; Yes

	 mov	 bl,@ATBWnorm	; Normal attributes
DISP_COLOR_INIT:
	 push	 cx		; Save for a moment
	 VIDCALL @GETPOS	; Get cursor position into (DH,DL) from page BH
				; (CH,CL) is cursor type
	 pop	 cx		; Restore

	 mov	 al,LF		; The last character if in the first column

	 cmp	 dl,0		; In column 0?
	 jne	 short DISP_COLOR_NEXT ; No, so don't start with a blank

	 call	 WRITE_BLANK	; Write out a blank character to page BH
	 mov	 al,LF		; The character before the blank
DISP_COLOR_NEXT:
	 mov	 LASTCHAR,al	; Save as last character written

	 lodsb			; Get next character

	 cmp	 al,EOS 	; End of the string?
	 je	 short DISP_COLOR_EXIT ; Yes

	 cmp	 al,20h 	; ASCII character?
	 jb	 short DISP_COLOR_TTY ; No

	 push	 cx		; Save for a moment
	 mov	 cx,1		; # characters to write
if @OEM_SYS eq @OEMSYS_3COM or @OEM_SYS eq @OEMSYS_TOSH or @OEM_SYS eq @OEMSYS_ILIM
	 VIDCALL @SETCHR	; Write character AL at current pos
else
	 test	 SYS_FLAG,@SYS_TOSH ; Izit a Toshiba 5100?
	 jz	 short DISP_COLOR1 ; Not this time

	 VIDCALL @SETCHR	; Write character AL at current pos

	 jmp	 short DISP_COLOR2 ; Join common code

DISP_COLOR1:
	 VIDCALL @SETCAT	; Write character/attr AL/BL at current pos
DISP_COLOR2:
endif				; IF @OEM_SYS eq @OEMSYS_3COM or @OEM_SYS eq @OEMSYS_TOSH or @OEM_SYS eq @OEMSYS_ILIM

;;;;;;;; VIDCALL @GETPOS	; Get cursor position into (DH,DL) from page BH
;;;;;;;;			; (CH,CL) is cursor type
	 pop	 cx		; Restore

;;;;;;;; inc	 dl		; Skip to next column
;;;;;;;;
;;;;;;;; cmp	 dl,cl		; At the line's end as yet?
;;;;;;;; jae	 short DISP_COLOR_CRLF ; Yes
;;;;;;;;
;;;;;;;; VIDCALL @SETPOS	; Set cursor position to (DH,DL) in page BH
;;;;;;;;
	 VIDCALL @SETTTY	; Write it out advancing the cursor

	 jmp	 short DISP_COLOR_NEXT ; Go around again

DISP_COLOR_CRLF:
	 mov	 al,CR		; Change the column
	 VIDCALL @SETTTY	; Write it out

	 mov	 al,LF		; Change the row
DISP_COLOR_TTY:
	 push	 ax		; Save for a moment
	 VIDCALL @SETTTY	; Write it out
	 pop	 ax		; Restore

	 cmp	 al,LF		; Was it a linefeed?
	 jne	 short DISP_COLOR_NEXT ; No, go around again

	 call	 WRITE_BLANK	; Write out a blank character to page BH

	 jmp	 short DISP_COLOR_NEXT ; Go around again

DISP_COLOR_EXIT:
	 cmp	 LASTCHAR,LF	; Was the last character a linefeed?
	 jne	 short DISP_COLOR_EXIT1 ; No, so don't back up

	 mov	 al,BS		; Back up one position
	 VIDCALL @SETTTY	; Write it out
DISP_COLOR_EXIT1:
	 REGREST <ds,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing

DISP_COLOR endp 		; End DISP_COLOR procedure
	 NPPROC  WRITE_BLANK -- Write A Blank
	 assume  ds:nothing,es:nothing
COMMENT|

Write out a blank character at the current cursor position
into display page BH.

On entry:

BH	 =	 display page #

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 al,' '         ; Character to write
	 mov	 bl,@ATBWnorm	; Normal attributes
	 VIDCALL @SETTTY	; Write it out

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WRITE_BLANK endp		; End WRITE_BLANK procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End QMAX_SCR module
