;' $Header:   P:/PVCS/MAX/INC/DIR.INV   1.0   05 Sep 1995 13:27:12   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; DIR.INC
;
; Directory Entry structure and equates
;

; D I R E C T O R Y   E N T R I E S

.xcref DIR_ATTR_NORM,DIR_ATTR_READ,DIR_ATTR_HIDDEN,DIR_ATTR_SYSTEM
.xcref DIR_ATTR_LABEL,DIR_ATTR_SUBDIR,DIR_ATTR_ARCHIV,DIR_ATTR_HIDSYS
DIR_ATTR_NORM	equ 00h 	; Normal
DIR_ATTR_READ	equ 01h 	; Read only
DIR_ATTR_HIDDEN equ 02h 	; Hidden file
DIR_ATTR_SYSTEM equ 04h 	; System file
DIR_ATTR_LABEL	equ 08h 	; Label
DIR_ATTR_SUBDIR equ 10h 	; Subdirectory
DIR_ATTR_ARCHIV equ 20h 	; Archive

; Read-only hidden system files

DIR_ATTR_HIDSYS equ DIR_ATTR_HIDDEN+DIR_ATTR_SYSTEM+DIR_ATTR_READ

.xcref DIR_STR,DIR_FNAM,DIR_FEXT,DIR_ATTR,DIR_TIME,DIR_DATE,DIR_CLUS,DIR_SIZE
DIR_STR  struc

DIR_FNAM db	 'filename'     ; name
DIR_FEXT db	 'ext'          ; extension
DIR_ATTR db	 DIR_ATTR_NORM	; Attribute
	 db	 10 dup (0)	; Reserved
DIR_TIME dw	 ?		; Time of creation
DIR_DATE dw	 ?		; Date of creation
DIR_CLUS dw	 ?		; Starting cluster #
DIR_SIZE dd	 ?		; File size

DIR_STR  ends

.xcref DIR_SIZE_LO,DIR_SIZE_HI
DIR_SIZE_LO equ  word ptr DIR_SIZE ; High- and low-order portions
DIR_SIZE_HI equ  word ptr DIR_SIZE+2

.xcref TIME_REC,$TIME_HH,$TIME_MM,$TIME_XX
TIME_REC record  $TIME_HH:5,$TIME_MM:6,$TIME_XX:5
				; 0 <= HH <= 23 (hour)
				; 0 <= MM <= 59 (minute)
				; 0 <= XX <= 31 (bi-second)

.xcref DATE_REC,$DATE_YY,$DATE_MM,$DATE_DD
DATE_REC record  $DATE_YY:7,$DATE_MM:4,$DATE_DD:5
				; 0 <= YY <= 119 (year-1980)
				; 1 <= MM <= 12 (month)
				; 1 <= DD <= 31 (day)

