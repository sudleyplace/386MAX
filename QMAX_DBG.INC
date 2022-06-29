;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DBG.INV   1.0   11 Aug 1995 10:55:20   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_DBG.INC
;
; Local flags in DBG_FLAG
; This data item is constant
;

@DBG_EMSERR equ  8000h		; Signal INT 01h on EMS errors
@DBG_XR    equ	 4000h		; XR moves allowed
@DBG_SOR   equ	 2000h		; Signal INT 0Dh on UGHNF
@DBG_XM    equ	 1000h		; Signal NMI on XMove interrupts
@DBG_ROM   equ	 0800h		; Signal NMI on ROM writes
@DBG_RC    equ	 0400h		; Reason code termination message
@DBG_CAPS  equ	 0200h		; Breakpoint if CapsLock on
@DBG_CR3   equ	 0100h		; Set high-order bit of CR3
@DBG_PMR   equ	 0080h		; Signal NMI after PMR I/O
@DBG_HLT   equ	 0040h		; Signal NMI after CLI/HLT
@DBG_CALL  equ	 0020h		; Signal NMI after PGMAPCALL
@DBG_JMP   equ	 0010h		; Signal NMI after PGMAPJMP
@DBG_EPTE  equ	 0008h		; Test EMS PTEs
@DBG_INV   equ	 0004h		; Signal INT 06h on UGHNF
@DBG_X67   equ	 0002h		; Skip optimized INT 67h trap
@DBG_LED   equ	 0001h		; Blink LEDs during EVM code


CHECK	 macro	 NN

	 push	 NN		;; Checkpoint #
	 call	 CHECKPOINT	;; Mark next checkpoint

	 endm			; CHECK


