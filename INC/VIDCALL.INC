;' $Header:   P:/PVCS/MAX/INC/VIDCALL.INV   1.0   05 Sep 1995 13:27:06   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; VIDCALL.INC
;
; VIDCALL macro and equates
;

; Equates for VIDCALL

.xcref @SETMOD,@SETTYP,@SETPOS,@GETPOS,@GETPEN,@SETPAG,@SCRUP, @SCRDN  ; 00-07
.xcref @GETCAT,@SETCAT,@SETCHR,@SETPAL,@SETDOT,@GETDOT,@SETTTY,@GETINF ; 08-0F
.xcref @SETPA2,@SETCG, @GETEGA,@SETSTR,@LCDCHR,@GETPHY		       ; 10-15

@SETMOD  equ	 00h		; Set video mode to AL
@SETTYP  equ	 01h		; Set cursor type to (CH,CL)
@SETPOS  equ	 02h		; Set cursor position to (DH,DL) in page BH
@GETPOS  equ	 03h		; Get cursor position into (DH,DL) from page BH
				; (CH,CL) is cursor type
@GETPEN  equ	 04h		; Get light pen position into AH, (DH,DL), CH, BX
@SETPAG  equ	 05h		; Select active display page to AL
@SCRUP	 equ	 06h		; Scroll active page up between (CX,DX) by AL lines using attr BH
@SCRDN	 equ	 07h		; Scroll active page down betwn (CX,DX) by AL lines using attr BH
@GETCAT  equ	 08h		; Get current position's char/attr into (AL,AH) from page BH
@SETCAT  equ	 09h		; Set current position's char/attr to (AL,BL) CX times in page BH
@SETCHR  equ	 0Ah		; Set current position's char to AL CX times in page BH
@SETPAL  equ	 0Bh		; Set color pallette BH to BL
@SETDOT  equ	 0Ch		; Set dot at row DX col CX in page BH to AL
@GETDOT  equ	 0Dh		; Get dot at row DX col CX in page BH into AL
@SETTTY  equ	 0Eh		; Write AL via TTY interface using color BL
@GETINF  equ	 0Fh		; Get video state into mode AL, cols AH, page BH
@SETPA2  equ	 10h		; Set EGA pallette registers
@SETCG	 equ	 11h		; Set EGA character generator
@GETEGA  equ	 12h		; Get EGA information
@SETSTR  equ	 13h		; Write string at ES:BP length CX at (DH,DL) in page BH, type AL
@LCDCHR  equ	 14h		; Load LCD font/set LCD intense substitute
@GETPHY  equ	 15h		; Get physical display parameters
@GSTDCC  equ	 1Ah		; Get/set display combination code

.xcref VIDCALL
VIDCALL  macro	 FUNC
ifnb	<FUNC>
	 mov	 ah,FUNC
F_C	 =	 FUNC
F_SIDI	 =	 (F_C eq 06h) or (F_C eq 07h) or (F_C eq 0Eh)
F_BP	 =	 F_SIDI or (F_C eq 08h)
if F_BP
	 push	 bp		; Save for a moment
endif				; IF
if F_SIDI
	 push	 si		; Save in case they're clobbered
	 push	 di
endif				; IF
	 int	 10h		; Request video service
if F_SIDI
	 pop	 di		; Restore
	 pop	 si
endif				; IF
if F_BP
	 pop	 bp		; Restore
endif				; IF
else
	 int	 10h		; Request video service
endif				; IFNB
	 endm			; VIDCALL

.xcref @VID_ATTR_UND,@VID_ATTR_NORM,@VID_ATTR_UNDH,@VID_ATTR_HIGH,@VID_ATTR_REV
@VID_ATTR_UND  equ   1		; Attribute for underline
@VID_ATTR_NORM equ   7		; Attribute for normal output
@VID_ATTR_UNDH equ   9		; Attribute for underline/high
@VID_ATTR_HIGH equ  15		; Attribute for high intensity
@VID_ATTR_REV  equ 112		; Attribute for reverse video

