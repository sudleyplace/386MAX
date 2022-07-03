;' $Header$
;
; (C) Copyright 1999 Qualitas, Inc.  GNU General Public License version 3.
;
; MEM_ERRD.INC
;
; Equates and strucuts for ERRDATA
;


; These values correspond to PLERR entries

@ERRLOG_NONE	equ	-1	; Entry not in use
@ERRLOG_BYTE	equ	0	; Byte mismatch error
@ERRLOG_WORD	equ	1	; Word mismatch error
@ERRLOG_DWORD	equ	2	; Dword mismatch error
@ERRLOG_NMI	equ	3	; Parity error
@ERRLOG_NMIX	equ	4	; Parity error, spurious


@DEF_ERRLOGMAX	equ	1024	; Default maximum errors to save


ERRDATA_STR struc

ERRDATA_TYP dw	@ERRLOG_NONE	; @ERRLOG_BYTE, etc.
ERRDATA_TEST dw ?		; Offset in DGROUP to test text
ERRDATA_ACT dd	?		; Actual data (ignored for NMI)
ERRDATA_EXP dd	?		; Expected    (...)
ERRDATA_ADDR dd ?		; Physical address

ERRDATA_STR ends


