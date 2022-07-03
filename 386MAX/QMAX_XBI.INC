;' $Header:   P:/PVCS/MAX/386MAX/QMAX_XBI.INV   1.0   11 Aug 1995 10:55:44   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_XBI.INC
;
; XBIOS Data Area BIOS compression patching structure
;

COMMENT|

Field descriptions:

	BCFX_STR_CRC is the field containing the 128K CRC
	of the BIOS to act on

	BCFX_STR_POF is the word location of the paragraph offset to apply
	when computing the base of the structure being patched.

	BCFX_STR_FUP is used in combination with BCFX_STR_POF to compute the
	dword location to patch.

	BCFX_STR_OLD is the value of the information befor we patch it

	BCFX_STR_NEW is the value of the fixup location after we patch it.

Algorithm for using structure:

	The address of the XBDA is 40:E shl 4

	If the BIOS in question matches BCFX_STR_CRC then
	   If BCFX_STR_POF is not 0 then
	      the FIXUP is XBDA+(XBDA[BCFX_STR_POF] shl 4)+BCFX_STR_FUP
	   else
	      the FIXUP is XBDA[BCFX_STR_FUP]

	If BCFX_STR_OLD is equal to the dword at FIXUP[0] then
	   FIXUP[0] should be set to BCFX_STR_NEW

|

BCF_XBDA_STR struc		; XBIOS patching table

BCFX_STR_CRC	dw	?	; CRC for BIOS in question
BCFX_STR_POF	dw	?	; XBDA location of the paragraph offset of
BCFX_STR_FUP	dw	?	; Offset of structure element to fixup
BCFX_STR_OLD	dd	?	; Information that should be at location
BCFX_STR_NEW	dd	?	; Information for XDBA patch

BCF_XBDA_STR ends		; End BCF_XBDA_STR

XBDAFMAC macro	 NAME		; XBIOS Data Area patch table macro

	 public  NAME&_TBL	 ; Define table as public label
NAME&_TBL label   tbyte 	 ; Define label for table

 BCF_XBDA_STR <09A7Ch,	0h,0E8h,0E0001E5Eh,0F0006402h> ; Model 40  04/04/91
 BCF_XBDA_STR <0EF6Eh,0B4h, 0Eh,0F00043A2h,0F0007933h> ; Model 57  06/07/91
 BCF_XBDA_STR <08DC0h,0B4h, 0Eh,0F00043A2h,0F0007933h> ; Model 57  07/03/91
 BCF_XBDA_STR <0A934h,0B4h, 0Eh,0F0003DFAh,0F000781Fh> ; Model 57  08/14/91
 BCF_XBDA_STR <017BAh,0B4h, 0Eh,0F00043A2h,0F0007933h> ; Model 57  08/28/91
 BCF_XBDA_STR <06550h,0B4h, 0Eh,0F00043BCh,0F0007377h> ; Model 57  10/22/91
 BCF_XBDA_STR <00F65h,0B4h, 0Eh,0F00043BCh,0F0007368h> ; Model 57  12/07/91
 BCF_XBDA_STR <0F075h,	0h,074h,0F0002A55h,0F000D62Dh> ; Model P70 12/16/91

	public	NAME&_CNT
NAME&_CNT equ ($ - NAME&_TBL)/size BCF_XBDA_STR ; Count of items in XBDA table

	 endm			; XBDAFMAC
