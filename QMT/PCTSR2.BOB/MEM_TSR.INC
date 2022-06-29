;' $Header$
;
; (C) Copyright 1998-2001 Qualitas, Inc.  All rights reserved.
;
; MEM_TSR.INC
;
; Equates and structs for PCTEST TSR API, version 2
;

PCTSR_STR struc

PCTSR_CMD db	?		; 00:  Command byte (see @PCTSR_xxx below)
PCTSR_BANK dq	?		; 01:  Physical memory back (0=0-64MB, 1=64-128MB, etc.)
PCTSR_MASK dq	?		; 09:  Error mask (bit n=1 iff error in that bit)
PCTSR_ESUMSIZE db ?		; 11:  # entries in error summary table
PCTSR_ESUM dq	?		; 12:  Ptr to error summary table

PCTSR_STR ends

; Command bytes for PCTSR_CMD
				; Type:  valid fields
@PCTSR_AWAKE   equ 0		; Report as awake:  (none)
@PCTSR_FAIL    equ 1		; Failure:  (BANK, MASK)
@PCTSR_SUMMARY equ 2		; Get summary table size/address:  (ESUMSIZE, ESUM)


@PCTSR_INT equ	04h		; PC TSR interrupt
@PCTSR_DEFCNT equ 2*182*6	; # timer ticks in 2 minutes (18.2/second)

