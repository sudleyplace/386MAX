;' $Header:   P:/PVCS/MAX/INC/KEYCALL.INV   1.0   05 Sep 1995 13:27:12   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; KEYCALL.INC
;
; KEYCALL macro and equates
;

; Equates for KEYCALL

.xcref KREC
KREC record $DSYS:1,$DCP:1,$DNM:1,$DSCR:1,$DRAL:1,$DRCT:1,$DLAL:1,$DLCT:1,\
	    $INS:1,  $CP:1, $NM:1,$SCRL:1,$DALT:1,$DCTL:1,$DLSH:1,$DRSH:1

.xcref @GETKEY,@GETKST,@GETSHF, 	       @PUTKEY		       ; 00-07
								       ; 08-0F
.xcref @EXTKEY,@EXTKST,@EXTSHF					       ; 10-12

@GETKEY  equ	 00h		; Get key from buffer
@GETKST  equ	 01h		; Get key status into ZF
@GETSHF  equ	 02h		; Get shift states into AL (See record KREC above)

@PUTKEY  equ	 05h		; Put key (CH,CL)=(Scan, ASCII) into buffer
				; AL = 0, successful
				;    = 1, buffer full

@EXTKEY  equ	 10h		; Get extended key from buffer
@EXTKST  equ	 11h		; Get extended key status into ZF
@EXTSHF  equ	 12h		; Get extended shift states into (AH,AL)
				; (See record KREC above)
@CPQCACHE equ	 0F4h		; COMPAQ cache controller

.xcref KEYCALL
KEYCALL  macro	 FUNC

ifnb <FUNC>
	 mov	 ah,FUNC
endif				; IFNB
ifidn <FUNC>,<@CPQCACHE>
	 REGSAVE <di,es>	; Save trashed registers

	 int	 16h		; Request keyboard service

	 REGREST <es,di>	; Restore
else
	 int	 16h		; Request keyboard service
endif				; IFIDN

	 endm			; KEYCALL

