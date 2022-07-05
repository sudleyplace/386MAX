;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I15.INV   1.0   11 Aug 1995 10:55:28   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_I15.INC
;
; Equates for I15_FLAG and other related issues
;

; Equates for I15_FLAG

I15_FLAGBITS record $I15_ROM:1,$I15_SRC:1,$I15_AVL1:1,$I15_FROUND:1,\
	$I15_XBREL:1,$I15_CPQ:1,$I15_AST:1,$I15_DSTK:1,\
	$I15_NOVELL:1,$I15_FLEXFRAME:1,$I15_LINK58:1,$I15_HI4B:1,\
	$I15_XEXEC:1,$I15_X4B:1,$I15_X58:1,$I15_XSPLIT:1;

@I15_ROM  equ (mask $I15_ROM)	; ROM from E000 to E400 disabled
@I15_SRC  equ (mask $I15_SRC)	; Move source value changed
;;;;;;;;;;; equ (mask $I15_AVL1) ; (Available)
@I15_FROUND equ (mask $I15_FROUND) ; Force rounding up to 256 byte boundary + 256
@I15_XBREL equ (mask $I15_XBREL) ; Relocate XBIOS data area
@I15_CPQ  equ (mask $I15_CPQ)	; Use COMPAQ TOP384 scheme
@I15_AST  equ (mask $I15_AST)	; Use AST    TOP384 scheme
@I15_DSTK equ (mask $I15_DSTK)	; DOS stacks present
@I15_NOVELL equ (mask $I15_NOVELL) ; NETX or other program rolling its own 4B
@I15_FLEXFRAME equ (mask $I15_FLEXFRAME) ; 386LOAD FLEXFRAME- fail Int 67h calls
@I15_LINK58 equ (mask $I15_LINK58) ; High DOS arena linked via 5802
@I15_HI4B equ (mask $I15_HI4B)	; Attempt to load high via 4B00h
@I15_XEXEC equ (mask $I15_XEXEC) ; Disable high load 4B00/4B01 support locally
@I15_X4B equ (mask $I15_X4B)	; Disable high load 4B00/4B01 support globally
@I15_X58 equ (mask $I15_X58)	; Disable 5800 support
@I15_XSPLIT equ (mask $I15_XSPLIT) ; Force this program to allocate from only
				; the largest high DOS region


; Equates for COMPAQ's memory-mapped I/O registers

@CPQMIO_HIGH equ 01h		; Memory is addressed at 00FE0000 only
@CPQMIO_WRIT equ 02h		; Memory is writable

; Mark as		     high-only,       read-only
@CPQ_HROM equ	 0FCFCh + (1*@CPQMIO_HIGH + 0*@CPQMIO_WRIT) * 0101h

; Mark as		     high-only,       read-write
@CPQ_HRAM equ	 0FCFCh + (1*@CPQMIO_HIGH + 1*@CPQMIO_WRIT) * 0101h

; Mark as		     high/low,	      read-only
@CPQ_HLROM equ	 0FCFCh + (0*@CPQMIO_HIGH + 0*@CPQMIO_WRIT) * 0101h

; Mark as		     high/low,	      read-write
@CPQ_HLRAM equ	 0FCFCh + (0*@CPQMIO_HIGH + 1*@CPQMIO_WRIT) * 0101h


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


; fASTram register equates

@AST_SWR0 equ	 4001h		; Switch register 0
@AST_INFO equ	 8001h		; Information register


