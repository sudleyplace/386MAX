;' $Header:   P:/PVCS/MAX/INC/EXE.INV   1.2   15 Jun 1998 15:58:10   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	All rights reserved.
;
; EXE.INC
;
; .EXE header structure
;

.xcref EXE_STR,@EXE_SIGN,@EXE_SIG2
@EXE_SIGN equ	'ZM'            ; Signature
@EXE_SIG2 equ	'MZ'            ; Secondary signature

EXE_STR  struc

EXE_SIGN dw	@EXE_SIGN	; 00:  Signature
EXE_R512 dw	?		; 02:  Image size/512 remainder
EXE_Q512 dw	?		; 04:  Image size/512 quotient
EXE_NREL dw	?		; 06:  # relocation table items
EXE_HSIZ dw	?		; 08:  Size of header in paras
EXE_MIN  dw	?		; 0A:  Minimum # paras needed beyond image
EXE_MAX  dw	?		; 0C:  Maximum ...
EXE_SS	 dw	?		; 0E:  Initial SS in paras
EXE_SP	 dw	?		; 10:  Initial SP
EXE_CHK  dw	?		; 12:  Checksum
EXE_IP	 dw	?		; 14:  Initial IP
EXE_CS	 dw	?		; 16:  Initial CS in paras
EXE_IREL dw	?		; 18:  Offset to first relocation table item
EXE_OVRL dw	?		; 1A:  Overlay #

EXE_STR  ends

DOSHDR_STR struc

DOSHDR_EXE db	(size EXE_STR) dup (?) ; 00:  EXE header
DOSHDR_RES  dw	4 dup (?)	; 1C:  Reserved words
DOSHDR_OEMID dw ?		; 24:  OEM identifier (for _oeminfo)
DOSHDR_OEMINFO dw ?		; 26:  OEM information; _oemid specific
DOSHDR_RES2 dw	10 dup (?)	; 28:  Reserved words
DOSHDR_LFANEW dd ?		; 3C:  File address of new exe header

DOSHDR_STR ends 

