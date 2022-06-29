;' $Header:   P:/PVCS/MAX/INC/SWAT_I3.INV   1.0   28 May 1996 19:22:44   HENRY  $
;
; SWAT_I3.INC - 386SWAT interface via Int 3 sequence
;
; Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
;
; This is an alternative interface to 386SWAT which requires no
; setup and should work identically in all environments.

@SWI3_SIG equ	'386S'          ; Signature to put in EAX

@SWI3_OP1 equ	0ED8603CDh	; First part of opcode sequence
@SWI3_OP2 equ	0CCD286CCh	; Second part of opcode sequence

; Load subfunction into BX and get SWAT's attention.  DS:ESI ==> ASCIIZ
; message.
SWAT_INT3 macro SUBFN

	  local L1,L2,L3

	  jmp	short L2	; Force entire sequence to be loaded
L1:
	  dd	@SWI3_OP1	; INT 3 (2 byte form); XCHG CH,CH
	  dd	@SWI3_OP2	; INT 3; XCHG DL,DL; INT 3

	  jmp	short L3	; Join common code

L2:
	  jmp	short L1	; Jump to start of sequence

L3:
	  endm			; SWAT_INT3

SWAT_INT3_MSG macro SUBFN,MSG

	  lds	esi,MSG 	; DS:ESI ==> ASCIIZ message to log
	  SWAT_INT3 SUBFN

	  endm			; SWAT_INT3_MSG

@SWI3FN_DISPLAY equ	0	; Subfn 0: display message only
@SWI3FN_DISPBRK equ	1	; Subfn 1: display msg and break

