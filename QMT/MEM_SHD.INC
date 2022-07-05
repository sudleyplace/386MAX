;' $Header:   P:/PVCS/MAX/QMT/MEM_SHD.INV   1.0   05 Sep 1995 16:55:54   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_SHD.INC
;
; Structures and equates for shadow RAM tables.
;

; Shadow RAM structure

.xcref SHD_STR
SHD_STR  struc

SHD_ESIZE dd	 ?		; 00-03:  Size of entry in 1KB
SHD_LBASE dd	 ?		; 04-07:  Linear base address of entry
SHD_OLBASE dd	 ?		; 08-0B:  Original Linear base address of entry
SHD_PBASE dd	 ?		; 0C-0F:  Physical ...
SHD_HNDL  dd	 0		; 10-13:  Memory handle (-1=none)
SHD_FLAG  dw	 0		; 14-15:  Flags (see @TT_xx for equates)
	 db	 10 dup (?)	; 16-1F:  Filler to para boundary

SHD_STR  ends


; Equates for COMPAQ's memory-mapped I/O registers

@CPQMIO_HIGH equ 01h		; Memory is addressed at 00FE0000 only
@CPQMIO_WRIT equ 02h		; Memory is writable

; Mark as		     high-only,       read-only
@CPQ_HROM equ	 0FCFCh + (1*@CPQMIO_HIGH + 0*@CPQMIO_WRIT) * 0101h

; Mark as		     high-only,       read-write
@CPQ_HRAM equ	 0FCFCh + (1*@CPQMIO_HIGH + 1*@CPQMIO_WRIT) * 0101h

; Flags for CPQSTR_FLAG

@CPQ_NOMEM equ	 0FFFFh 	; No built-in memory

.xcref CPQSTR
CPQSTR	 struc

CPQSTR_FLAG dw	 ?		; 0FFFFh if no memory available
CPQSTR_TOT dw	 ?		; Total memory in paras
CPQSTR_AVL dw	 ?		; Available memory in paras
CPQSTR_LOW dw	 ?		; Lowest para in use

CPQSTR	 ends


; Equates for AST's memory-mapped I/O registers

@ASTMIO_HILO equ 01h		; 0 = memory is addressed at 00FE0000 only
				; 1 = memory is addressed at 000E0000 also
@ASTMIO_ROM  equ 02h		; Memory is read-only
@ASTMIO_N512 equ 04h		; Not 512KB system

; Mark as	    high-only,	     read-only
@AST_HROM equ	 (0*@ASTMIO_HILO + 1*@ASTMIO_ROM) * 0101h

; Mark as	    high-only,	     read-write
@AST_HRAM equ	 (0*@ASTMIO_HILO + 0*@ASTMIO_ROM) * 0101h


