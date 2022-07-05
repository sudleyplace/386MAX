;' $Header:   P:/PVCS/MAX/386MAX/QMAX_LOD.INV   1.0   11 Aug 1995 10:55:34   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_LOD.INC
;
; File loader structure
;


LOAD_STR struc

LOAD_SIZ dd	 ?		; Load size after real mode initialization
LOAD_USIZ dd	 ?		; Byte size of uninitialized data
LOAD_DAT dd	 ?		; Offset to data segment
LOAD_PHYS dd	 ?		; Physical address of file image
LOAD_POFF dd	 ?		; Offset in PGROUP of this LOD module
LOAD_FLG dw	 0		; Flags (see @LOAD_xxx below)
LOAD_SEG dw	 ?		; Memory segment with file image

LOAD_STR ends

@LOAD_VSIZE equ  8000h		; Load module supports MD_VSIZE


