;' $Header:   P:/PVCS/MAX/INC/MOUSE.INV   1.0   05 Sep 1995 13:27:32   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; MOUSE.INC
;
; MOUSECALL macro and equates
;

@MOUSE_RESET   equ 0000h	; Mouse installed and reset
				; Returns AX=status
				;	  BX=# buttons
@MOUSE_SHOWCUR equ 0001h	; Show cursor
@MOUSE_HIDECUR equ 0002h	; Hide cursor
@MOUSE_GETPOS  equ 0003h	; Get position and button status
				; Returns BX=button status:
				;	     Bit 0:  left button
				;	     Bit 1:  right ...
				;	     Bit 2:  middle ...
				;	  CX=horizontal position
				;	  DX=vertical ...
@MOUSE_SETPOS  equ 0004h	; Set mouse cursor position
				; Using   BX=horizontal
				;	  CX=vertical
@MOUSE_GETBDN  equ 0005h	; Get button press information
				; Using   BX=0 for left, 1 for right, 2 for mid
				; Returns AX=button status
				;	  BX=# buttons pressed since last call
				;	  CX=col cursor of last button press
				;	  DX=row ...
@MOUSE_GETBUP  equ 0006h	; Get button release information
				; Using   BX=0 for left, 1 for right, 2 for mid
				; Returns AX=button status
				;	  BX=# buttons released since last call
				;	  CX=col cursor of last button release
				;	  DX=row ...
@MOUSE_SETHLIM equ 0007h	; Set min/max horizontal position
				; Using   CX=minimum
				;	  DX=maximum
@MOUSE_SETVLIM equ 0008h	; Set min/max vertical position
				; Using   CX=minimum
				;	  DX=maximum
@MOUSE_SETGCUR equ 0009h	; Set graphics cursor block
				; Using   BX=horizontal
				;	  CX=vertical
				;	  ES:DX=screen & cursor mask arrays
@MOUSE_SETTCUR equ 000Ah	; Set text cursor
				; Using   BX=cursor select 0=soft, 1=hard
				;	  CX=screen mask value (soft)
				;	  CX=scan line start   (hard)
				;	  DX=cursor mask value (soft)
				;	  DX=scan line stop    (hard)
@MOUSE_GETREL  equ 000Bh	; Read relative mouse motion counters
				; Returns CX=horizontal counter
				;	  DX=vertical ...
@MOUSE_HOOKMEI equ 000Ch	; Hook Mouse Event Interrupt
				; Using   CX=call mask
				;	     Bit 0:  cursor position changed
				;	     Bit 1:  left button pressed
				;	     Bit 2:  ...	 released
				;	     Bit 3:  right button pressed
				;	     Bit 4:  ...	  released
				;	     Bit 5:  middle button pressed
				;	     Bit 6:  ...	   release
				;	     Bit 7-15:	reserved
				;	  ES:DX=subroutine called with
				;	     AX=call mask for condition as above
				;	     BX=button state
				;	     CX=horizontal cursor position
				;	     DX=vertical ...
@MOUSE_LPENON  equ 000Dh	; Light pen emulation on
@MOUSE_LPENOFF equ 000Eh	; Light pen emulation off
@MOUSE_SETMPR  equ 000Fh	; Set mickey/pixel ratio
				; Using   CX=horizontal mickey/pixel ratio
				;	  DX=vertical ...
@MOUSE_SETDST  equ 0013h	; Set double speed threshold
				; Using   DX=speed threshold in mickeys/sec
@MOUSE_GETSSR  equ 0015h	; Get state save/restore buffer size
				; Returns BX=byte size
@MOUSE_STSAVE  equ 0016h	; Save state
				; Using   ES:DX=buffer
@MOUSE_STREST  equ 0017h	; Restore state
				; Using   ES:DX=buffer


MOUSECALL macro  FN

ifnb <FN>
	 mov	 ax,FN		; Get function code
endif				; IFNB <FN>
	 int	 33h		; Request mouse service

	 endm			; MOUSECALL

