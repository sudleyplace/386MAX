;' $Header:   P:/PVCS/MAX/ASQENG/MULTIME.ASV   1.2   30 May 1997 14:58:40   BOB  $
	TITLE	MULTIME -- Time Execution of Multiply Instructions
	page	 58,122
	name	MULTIME

COMMENT|		Module Specifications

Copyright:  Copyright (c) 1990-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  TIME.ASM, part of ATPERF.EXE

Modifications by:  None.

|
	.MODEL	LARGE,PASCAL

PPI_PORT	EQU	061H
TIMER2_PORT	EQU	042H
TIMER_CTRL	EQU	043H

	.CODE
;***************************************************************;
;	_MULTIME						;
;	TIME EXECUTION OF MULTIPLY INSTRUCTIONS 		;
;***************************************************************;

	PUBLIC	MULTIME
MULTIME PROC	COUNT:WORD
	PUSH	DI			; SAVE DI
	CALL	SETUP_TIMER		; SET UP TIMER
	MOV	DI, 0DAF5h		; Use a large prime number
	MOV	AX, COUNT		; GET COUNT ARGUMENT
	ADD	AX, 99			; ROUND UP
	MOV	CX, 100 		; DIVIDE BY 100 =
	DIV	CL			;  NUMBER OF INSTRUCTIONS
	MOV	CL, AL			;  PER PASS
	NOP				; ALIGN INSTRUCTIONS
	IN	AL, PPI_PORT		; GET CURRENT CONTROL
	MOV	BL, AL			; SAVE IN BL
	OR	AX, 1			; SET TIMER ENABLE BIT
	CLI				; STOP INTERRUPTS
	EVEN
	OUT	PPI_PORT, AL		; ENABLE TIMER
ML:	REPT	100			; DO 100 MULTIPLIES
	MUL	DI			;
	ENDM				; END MACRO
	DEC	CX			; COUNT THIS PASS
	JZ	MD			; JUMP IF COMPLETE
	JMP	ML			; LOOP BACK IF NOT DONE
MD:	MOV	AL, BL			; RESTORE CONTROL VALUE
	OUT	PPI_PORT, AL		;
	STI				; START INTERRUPTS
	CALL	GET_TIMER		; OBTAIN FINAL COUNT
	POP	DI			; RESTORE DI
	RET				; RETURN
MULTIME ENDP

;***************************************************************;
;	SETUP_TIMER						;
;	SET UP THE TIMER FOR MAXIMUM COUNT, TO TIME A RUN	;
;***************************************************************;
SETUP_TIMER	PROC	NEAR
	PUSH	AX			; SAVE AX
	IN	AL, PPI_PORT		; STOP THE TIMER
	AND	AL, 0FCH		;
	OUT	PPI_PORT, AL		;
	MOV	AL, 0B4H		; INITIALIZE THE TIMER
	OUT	TIMER_CTRL, AL		;
	MOV	AL, 0			; CLEAR THE COUNT
	OUT	TIMER2_PORT, AL 	;
	NOP				;
	OUT	TIMER2_PORT, AL 	;
	POP	AX			; RESTORE AX
	RET				; RETURN
SETUP_TIMER	ENDP
;***************************************************************;
;	GET_TIMER						;
;	TAKE THE COUNT FROM THE TIMER				;
;***************************************************************;
GET_TIMER	PROC	NEAR
	PUSH	BX			; SAVE REGISTERS
	IN	AL, TIMER2_PORT 	; GET LOW BYTE OF TIME
	MOV	AH, AL			;
	IN	AL, TIMER2_PORT 	; GET HIGH BYTE
	XCHG	AL, AH			; TIME IN AX
	NEG	AX			; CORRECT FOR COUNT-DOWN
	POP	BX			; RESTORE REGISTERS
	RET				; RETURN
GET_TIMER	ENDP

	END
