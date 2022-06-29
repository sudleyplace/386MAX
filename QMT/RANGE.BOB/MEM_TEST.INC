;' $Header$
;
; (C) Copyright 1998-1999 Qualitas, Inc.  All rights reserved.
;
; MEM_TEST.INC
;
; Equates and structs for TESTTIME
;


TIME_STR struc

TIME_HR  db	?		; Hour (0-23)
TIME_MIN db	?		; Minuts (0-59)
TIME_SEC db	?		; Second (0-59)
TIME_100 db	?		; Hundreths of a second (0-99)

TIME_STR ends


TESTTIME_STR struc

TESTTIME_BEG db (type TIME_STR) dup (?) ; Beginning time
TESTTIME_END db (type TIME_STR) dup (?) ; Ending ...
TESTTIME_TEST dw ?		; Offset in DGROUP to test text

TESTTIME_STR ends


@DEF_TESTTIME_MAX equ 128	; Default maximum # entries in TESTTIME

