;' $Header:   P:/PVCS/MAX/386MAX/QMAX_STK.INV   1.0   11 Aug 1995 10:55:56   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; QMAX_STK.INC
;
; Structures and equates for STACKS= keyword support
;

@STKSIG  equ	 'STAC'         ; Top of stack signature
@STKFILL equ	 'CATS'         ; Remainder of the stack signature


; DSTK_TAB_OLDSTKVEC equates
; These values must not conflict with valid values for this field

@STKAVL  equ	  0		; Stack is available
@STKOVF  equ	 -1		; Stack has overflowed

DSTK_TAB_STR struc

DSTK_TAB_OLDSTKVEC dd @STKAVL	; Caller's SS:SP                 (variable)
DSTK_TAB_DOSSTKVEC dd ? 	; Seg:Off of top stack		 (fixed)
DSTK_TAB_LaDOSTOP  dd ? 	; Linear address of top of stack (fixed)

DSTK_TAB_STR ends


