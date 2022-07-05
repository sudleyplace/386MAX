;' $Header:   P:/PVCS/MAX/386MAX/QMAX_ROM.INV   1.0   11 Aug 1995 10:55:42   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_ROM.INC
;
; Equates and structures used for Video ROM Relocation (Obsolete)
;

COMMENT |

This file was used for relocating video ROMs.

However, with VGASWAP and 386MAX version 6.0, this method
is obsolete.  This file is left here for historical reasons.
it is not accessed by any MAX source module.

; Equates and structures used for Video ROM Relocation

ROMINT_STR struc

ROMINT_NUM  dw	 ?		; Interrupt # times 4
ROMINT_FLAG dw	 ?		; Flags
ROMINT_FIND dd	 ?		; Action routine to find it
ROMINT_VEC  dd	 ?		; Pointer to original interrupt vector

ROMINT_STR ends

	public	 @ROMINT_STRLEN
@ROMINT_STRLEN	equ	size ROMINT_STR


; Flags for ROMINT_FLAG

@ROMINT_RELOC equ 80h		; Relocation needed
@ROMINT_CODE  equ 40h		; Interrupts points to code
@ROMINT_C000  equ 20h		; This interrupt points into C000
@ROMINT_VGA   equ 10h		; This ROM is a video BIOS

|
