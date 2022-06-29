;' $Header$
;
; (C) Copyright 1998-1999 Qualitas, Inc.  All rights reserved.
;
; MEM_TSR.INC
;
; Equates and structs for PCTEST TSR API
;

PCTSR_STR struc

PCTSR_CMD db	?		; 00:  Command byte (see @PCTSR_xxx below)
PCTSR_ID  dw	?		; 01:  Test ID (see @PCTSR_ID_xxx below)
PCTSR_ADDR dq	?		; 03:  Physical memory address
PCTSR_EXP dq	?		; 0B:  Expected pattern
PCTSR_ACT dq	?		; 13:  Actual pattern
PCTSR_SIZE dd	?		; 1B:  Amount of extended memory in KB (constant)
PCTSR_ETA  dq	?		; 1F:  Estimated time to complete in timer ticks

PCTSR_STR ends

; Command bytes for PCTSR_CMD
				; Type:  valid fields
@PCTSR_START equ 0		; Start test:  _ID
@PCTSR_AWAKE equ 1		; Report as awake:  none
@PCTSR_FAIL  equ 2		; Failure:  _ID, _ADDR, _EXP, _ACT
@PCTSR_END   equ 3		; End of all tests:  none

; Test IDs for PCTSR_ID

@PCTSR_ID_USF equ @ASK_UNLSAF	; (Unlinked) Stuck-at fault test
@PCTSR_ID_UTF equ @ASK_UNLTRN	; (Unlinked) Transition ...
@PCTSR_ID_LIN equ @ASK_LNKINV	; Linked Inversion ...
@PCTSR_ID_UIN equ @ASK_UNLINV	; Unlinked Inversion ...
@PCTSR_ID_LID equ @ASK_LNKIDM	; Linked Idempotent ...
@PCTSR_ID_UID equ @ASK_UNLIDM	; Unlinked Idempotent ...
@PCTSR_ID_MIF equ @ASK_MOVI	; Moving Inversion ...
@PCTSR_ID_DRD equ @ASK_DRD	; Data Retention-13 ...


@PCTSR_INT equ	04h		; PC TSR interrupt
@PCTSR_DEFCNT equ 2*182*6	; # timer ticks in 2 minutes (18.2/second)

