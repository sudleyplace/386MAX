;' $Header:   P:/PVCS/MAX/INC/EPSON.INV   1.0   05 Sep 1995 13:27:24   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; EPSON.INC
;
; Equates for Epson Tiger system
;

@EPS_CMD equ	 0F060h 	; I/O port for command
@EPS_DAT equ	 0F064h 	; ...	       data

EPSCR1CMD record $EPSCR1_IOF:1,$EPSCR1_F000:2,$EPSCR1_E000:2

; Equates for $EPSCR1_x000

@EPSCR1_DIS equ  00b		; Disable shadow RAM, BIOS enabled
@EPSCR1_RW  equ  10b		; Enable shadow RAM, read-write
@EPSCR1_ROM equ  11b		; ...		     read-only

EPSCR3	  record $EPSCR3_F:1,$EPSCR3_E:1,$EPSCR3_D:1,$EPSCR3_C:1,$EPSCR3_B:1,$EPSCR3_A:1,$EPSCR3_9:1,$EPSCR3_8:1

@EPS_CR0 equ	 1		; Control register #
@EPS_CR1 equ	 2
@EPS_CR2 equ	 3
@EPS_CR3 equ	 4

