;' $Header:   P:/PVCS/MAX/INC/DTA.INV   1.0   05 Sep 1995 13:27:04   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DTA.INC
;
; Disk Transfer Area structure
;

; D I S K   T R A N S F E R   A R E A	--   D O S   2.x

.xcref DTA_STR,DTA_ATTR,DTA_TIME,DTA_DATE,DTA_SIZE,DTA_FID
DTA_STR  struc
	 db	 21 dup (?)	; Reserved for DOS
DTA_ATTR db	 ?		; Directory attribute
DTA_TIME dw	 ?		; The file's timestamp
DTA_DATE dw	 ?		; The file's datestamp
DTA_SIZE dd	 ?		; The file's size
DTA_FID  db	 13 dup (?)	; The filename.ext,0

DTA_STR  ends

.xcref DTA_SIZE_LO,DTA_SIZE_HI,DTA_SEG
DTA_SIZE_LO equ  word ptr DTA_SIZE[0] ; High- and low-order portions
DTA_SIZE_HI equ  word ptr DTA_SIZE[2]
DTA_SEG  equ	 word ptr DTA_SIZE[0]

