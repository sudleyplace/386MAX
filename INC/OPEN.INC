;' $Header:   P:/PVCS/MAX/INC/OPEN.INV   1.0   05 Sep 1995 13:27:00   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; OPEN.INC
;
; DOS Open File equates
;

; Access bits

@OPEN_R   equ	 000b
@OPEN_W   equ	 001b
@OPEN_RW  equ	 010b

; Sharing bits

@OPEN_DRW equ	 001b shl 4
@OPEN_DW  equ	 010b shl 4
@OPEN_DR  equ	 011b shl 4
@OPEN_DN  equ	 100b shl 4

; Inheritance bit

@OPEN_LCL equ	 1 shl 7

