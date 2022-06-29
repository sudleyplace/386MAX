;' $Header$
;
; (C) Copyright 1998 Qualitas, Inc.  All rights reserved.
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


