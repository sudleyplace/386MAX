;' $Header:   P:/PVCS/MAX/QMT/MEM_CNT.INV   1.0   05 Sep 1995 16:56:02   HENRY  $
;
; (C) Copyright 1988-1999 Qualitas, Inc.  GNU General Public License version 3.
;
; MEM_CNT.INC
;
; Record and equates for CNT_FLAG.
;

.xcref CNT_REC
CNT_REC record	$CNT_AVAIL:4,	\
		$CNT_NMIX:1,	\
		$CNT_BASIC:1,	\
		$CNT_KFLUSH:1,	\
		$CNT_CHG:1,	\
		$CNT_CONT:1,	\
		$CNT_NUM:1,	\
		$CNT_HALT:1,	\
		$CNT_AUTO:1,	\
		$CNT_NOEXIT:1,	\
		$CNT_NMI:1,	\
		$CNT_DISPEXIT:1,\
		$CNT_NEWKEY:1

@CNT_NMIX equ	 mask $CNT_NMIX   ; 0800:  Spurious external NMI has occurred
@CNT_BASIC equ	 mask $CNT_BASIC  ; 0400:  Selection made from BASIC screen
@CNT_KFLUSH equ  mask $CNT_KFLUSH ; 0200:  Halt triggered via Int 9; flush buffer
@CNT_CHG equ	 mask $CNT_CHG	  ; 0100:  An item count value has changed
@CNT_CONT equ	 mask $CNT_CONT   ; 0080:  One or more counts are continuous
@CNT_NUM  equ	 mask $CNT_NUM	  ; 0040:  The last char was numeric
@CNT_HALT equ	 mask $CNT_HALT   ; 0020:  The user said to halt
@CNT_AUTO equ	 mask $CNT_AUTO   ; 0010:  Run tests in automatic mode
@CNT_NOEXIT equ  mask $CNT_NOEXIT ; 0008:  Don't exit after automatic run
@CNT_NMI equ	 mask $CNT_NMI	  ; 0004:  External NMI has occurred
@CNT_DISPEXIT equ mask $CNT_DISPEXIT ; 0002:  Display message upon exit
@CNT_NEWKEY equ  mask $CNT_NEWKEY ; 0001:  A new key is available in the buffer


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
@ASK_MOVI   equ  6		; ...	    Moving Inversion
@ASK_DRD    equ  7		; ...	    Data Retention-13
@ASK_START  equ  8		; ...	    Start key

