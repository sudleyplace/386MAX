;' $Header:   P:/PVCS/MAX/INC/ROMSEG.INV   1.0   05 Sep 1995 13:26:38   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; ROMSEG.INC
;
; ROMSEG include file
;

.xcref ROMSEG,ROMSIGN,@ROMSIGN,@ROMNINIT,ROMLEN,ROMENTRY

RGROUP	 group	 ROMSEG

if (@Cpu and 1000b)		; If 80386 instructions
ROMSEG	 segment use16 at 0	; Start ROMSEG segment
else
ROMSEG	 segment at 0		; Start ROMSEG segment
endif				; IF (@Cpu AND 1000b)

ROMSIGN  dw	 ?		; ROM signature
@ROMSIGN equ	 0AA55h 	; Valid signature
@ROMNINIT equ	 055AAh 	; Valid signature for non-initializing ROM

ROMLEN	 db	 ?		; # 512 blocks
ROMENTRY label	 far		; Entry point to ROM

	 org	 05FEAh
CPQVID_SIG db	 'COMPAQ'       ; COMPAQ Video signature

ROMSEG	 ends			; End ROMSEG segment


