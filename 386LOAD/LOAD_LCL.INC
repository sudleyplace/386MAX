;' $Header:   P:/PVCS/MAX/386LOAD/LOAD_LCL.INV   1.0   05 Sep 1995 14:47:46   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; LOAD_LCL.INC
;
; Equates for LCL_FLAG
;

@LCL_INST  equ	 8000h		; We're installed
@LCL_INIT  equ	 4000h		; We're initialized
@LCL_DISP  equ	 2000h		; Device driver line displayed
@LCL_RES   equ	 1000h		; Program went resident
;;;;_ACTIV equ	 0800h		; INTs 20h, 21h, and 27h are active
;;;;_INTS  equ	 0400h		; INTs 20h, 21h, and 27h are intercepted
@LCL_DTA   equ	 0200h		; DTA intercepted
@LCL_PSP   equ	 0100h		; PSP intercepted
@LCL_TSR   equ	 0080h		; Set = TSRLOAD, clr = DRVLOAD
@LCL_EXT   equ	 0040h		; File extension present
@LCL_EXE   equ	 0020h		; File has an .EXE header
;;;;_I29   equ	 0010h		; INT 29h intercepted
@LCL_XMS   equ	 0008h		; Install XMS handler (MOVE'EM only)
@LCL_I67   equ	 0004h		; Install INT 67h handler (MOVE'EM only)
@LCL_IN67  equ	 0002h		; INT 67h handler installed
@LCL_XFLEX equ	 0001h		; INT 67h handler invoked during GETSIZE

