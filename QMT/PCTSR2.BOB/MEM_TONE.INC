;' $Header$
;
; (C) Copyright 1998-1999 Qualitas, Inc.  All rights reserved.
;
; MEM_TONE.INC
;
; Equates for TONE structures
;

@TONETAB_MAXLEN equ 32		; Maximum # tones per event

TONEFD_STR struc

TONEFD_FRQ dw	?		; Frequency
TONEFD_DUR dw	?		; Duration
TONEFD_PAU dw	?		; Pause

TONEFD_STR ends


TONETAB_STR struc

TONETAB_RPT dw	0		; Repeat count
TONETAB_CNT dw	0		; # valid (freq, dur, pause) values
;;;;TAB_FD TONEFD_STR @TONETAB_MAXLEN dup (<>) ; (freq, dur, pause) values
TONETAB_FD db	(@TONETAB_MAXLEN * (type TONEFD_STR)) dup (0) ; (freq, dur, pause) values

TONETAB_STR ends


; Equates for Tables

@TONE_INI equ	0		; Startup
@TONE_RUN equ	1		; Running
@TONE_ATC equ	2		; All-tests-complete
@TONE_MEM equ	3		; Memory error
@TONE_PAR equ	4		; Parity error
@TONE_AUT equ	5		; Auto memory/parity error

