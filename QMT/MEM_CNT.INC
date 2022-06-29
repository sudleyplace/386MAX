;' $Header:   P:/PVCS/MAX/QMT/MEM_CNT.INV   1.0   05 Sep 1995 16:56:02   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	All rights reserved.
;
; MEM_CNT.INC
;
; Record and equates for CNT_FLAG.
;

.xcref CNT_REC
CNT_REC  record  $CNT_AVAIL:5,$CNT_BASIC:1,$CNT_KFLUSH:1,$CNT_CHG:1,\
		 $CNT_CONT:1,$CNT_NUM:1,$CNT_HALT:1,$CNT_AUTO:1,\
		 $CNT_NOEXIT:1,$CNT_NMI:1,$CNT_DISPEXIT:1,$CNT_NEWKEY:1
@CNT_BASIC equ	 mask $CNT_BASIC  ; Selection made from BASIC screen
@CNT_KFLUSH equ  mask $CNT_KFLUSH ; Halt triggered via Int 9; flush buffer
@CNT_CHG equ	 mask $CNT_CHG	  ; An item count value has changed
@CNT_CONT equ	 mask $CNT_CONT   ; One or more counts are continuous
@CNT_NUM  equ	 mask $CNT_NUM	  ; The last char was numeric
@CNT_HALT equ	 mask $CNT_HALT   ; The user said to halt
@CNT_AUTO equ	 mask $CNT_AUTO   ; Run tests in automatic mode
@CNT_NOEXIT equ  mask $CNT_NOEXIT ; Don't exit after automatic run
@CNT_NMI equ	 mask $CNT_NMI	  ; External NMI has occurred
@CNT_DISPEXIT equ mask $CNT_DISPEXIT ; DIsplay message upon exit
@CNT_NEWKEY equ  mask $CNT_NEWKEY ; A new key is available in the buffer


@ICNT_CONT equ	 -1		; Continuous value
@CNT_MAX equ	 999		; Count values above this number are
				; considered continuous

; Equates for fault test indices

@ASK_UNLSAF equ  0		; Index for Unlinked Stuck-At
@ASK_UNLTRN equ  1		; ...	    Unlinked Transition
@ASK_LNKINV equ  2		; ...	    Linked Transition and Inversion Coupling
@ASK_UNLINV equ  3		; ...	    Unlinked Inversion Coupling
@ASK_LNKIDM equ  4		; ...	    Linked Transition and Idempotent Coupling
@ASK_UNLIDM equ  5		; ...	    Unlinked Idempotent Coupling
@ASK_START  equ  6		; ...	    Start key

