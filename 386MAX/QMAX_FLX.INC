;' $Header:   P:/PVCS/MAX/386MAX/QMAX_FLX.INV   1.0   11 Aug 1995 10:55:38   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_FLX.INC
;
; Structures and equates for FLEXROM
;

; The equate below is used for MAX to check XLAT's version number
; XLAT no longer performs any version number checking
; This is an ordinal number and is not related to a retail version number

@XLATVERS_HTU	 equ	 103h	; MAX uses this number for checking

; Structures and equates for FLEXROM

FLEXROM_STR	 struc		; Structure for FLEXed ROM info

FLEX_SRC  dw	 ?		; Source segment for BIOS
FLEX_DST  dw	 ?		; Destin ...
FLEX_LEN  dw	 ?		; Length in bytes
FLEX_FLAG dw	 ?		; Flags
FLEX_MAP  dw	 ?		; Bitmap of memory-mapped I/O pages

FLEXROM_STR	 ends		; End FLEXROM_STR structure

@FLEXROM_STRLEN  equ	size FLEXROM_STR ; Size of above structure

; Equates for FLEXROM_STR.FLEXROM_FLAG

@FLEXFLAG_VGA	 equ	8000h	; ROM is VGA

FLEXROMINT_STR	 struc		; Structure for interrupt relocation

FLEXROMINT_NUM	 dw	 ?	; Interrupt # times 4
FLEXROMINT_FLAG  dw	 ?	; Flags
FLEXROMINT_FIND  dd	 ?	; Action routine to find BIOS entry point
FLEXROMINT_VEC	 dd	 ?	; Pointer to original interrupt vector
FLEXROMINT_SRC	 dw	 ?	; Segment of ROM before being FLEXed

FLEXROMINT_STR	 ends		; End FLEXROMINT_STR structure

@FLEXROMINT_STRLEN equ	 size FLEXROMINT_STR ; Size of above structure

@FLEX_UNUSED	 equ	-1	; Entry is unused in FLEXROMINT_STR

; Flags for FLEXROMINT_FLAG

@ROMINT_RELOC equ 80h		; Relocation needed
@ROMINT_CODE  equ 40h		; Interrupts points to code
@ROMINT_C000  equ 20h		; This interrupt points into C000
@ROMINT_VGA   equ 10h		; This ROM is a video BIOS

@FLEXROM_RESOURCE_MAX	equ	30	; Maximum number of resources
@FLEXROM_ROM_MAX	equ	6	; Maximum number of ROMs

@FLEXFILE	 equ	'XLAT.COM'      ; Name of Video translation file


; Interface between MAX and XLAT.COM
; This table must start at offset 03h in XLAT.COM to be in synch with MAX.
; The three bytes in front of this structure are used for a near jump
; so that XLAT may also perform as a .COM program

@XLAT_OFF equ	103h		; Size of PSP + [jmp  near ptr ??]

XLAT_STR struc			; Structure for MAX to XLAT interface

XLAT_VER dw	?		; 0100h => 1.00
MAX_VER  dw	?		; 050Dh => 5.13 (filled in by MAX)
MAX_XLAT dw	?		; Offset of MAX to XLAT function dispatcher

XLAT_STR ends			; End of XLAT_STR structure

; MAXLAT function values

@MAXLAT_INIT		equ	 00h	; Initialization by XLAT
@MAXLAT_GETSRCSEG	equ	 01h	; Get source segment
@MAXLAT_SETSRCSEG	equ	 02h	; Set ...
@MAXLAT_GETDSTSEG	equ	 03h	; Get Destin segment
@MAXLAT_SETDSTSEG	equ	 04h	; Set ...
@MAXLAT_GETROMLEN	equ	 05h	; Get ROM length
@MAXLAT_SETROMLEN	equ	 06h	; Set ...
@MAXLAT_DETECTION	equ	 07h	; Find off-limit data areas
@MAXLAT_RESTORE 	equ	 08h	; Restore variables for pass 2
@MAXLAT_TRANSLATE	equ	 09h	; Translate BIOS action
@MAXLAT_GETCACHELEN	equ	 0Ah	; Get the cache length of BIOS


; Equates for FLEXROM_FLAG

@FR_ACTIVE	equ	8000h	; At least one ROM is being swapped
@FR_VGA 	equ	4000h	; Video ROM is being swapped
@FR_VSRC	equ	2000h	; Source of Video is NOT explicitly specified
@FR_VDST	equ	1000h	; Destin ...
@FR_VLEN	equ	0800h	; Length ...
@FR_GORE	equ	0400h	; VGA ROM source and MAC entry at C000
@FR_SHDROM	equ	0200h	; A shadowed VGA ROM is present
@FR_SHDVGA	equ	0100h	; VGASWAP keyword and shadowed ROM is present
@FR_VID_C000	equ	0080h	; A video ROM resides at C000
@FR_NOGORE	equ	0040h	; User requested us to omit GORE area

; Length in bytes (/16) of VGA ROM header signature

@VGAHDR  equ	 512		; # bytes in VGA header (/512)


