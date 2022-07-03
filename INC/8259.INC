;' $Header:   P:/PVCS/MAX/INC/8259.INV   1.0   05 Sep 1995 13:27:24   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; 8259.INC
;
; Equates for 8259 programming
;


.xcref IRQ_REC,$IRQ15,$IRQ14,$IRQ13,$IRQ12,$IRQ11,$IRQ10,$IRQ9,$IRQ8
.xcref	       $IRQ0, $IRQ1, $IRQ2, $IRQ3, $IRQ4, $IRQ5, $IRQ6,$IRQ7
IRQ_REC  record  $IRQ15:1,$IRQ14:1,$IRQ13:1,$IRQ12:1,$IRQ11:1,$IRQ10:1,$IRQ9:1,$IRQ8:1,\
		 $IRQ7:1, $IRQ6:1, $IRQ5:1, $IRQ4:1, $IRQ3:1, $IRQ2:1, $IRQ1:1,$IRQ0:1

.xcref @EOI,@EOI0,@EOI1,@EOI2,@EOI3,@EOI4,@EOI5,@EOI6,@EOI7
@EOI	 equ	 20h		; Non-specific End-of-interrupt command to 8259
@EOI0	 equ	 60h+$IRQ0	; Specific EOI for IRQ0
@EOI1	 equ	 60h+$IRQ1	;		   IRQ1
@EOI2	 equ	 60h+$IRQ2	;		   IRQ2
@EOI3	 equ	 60h+$IRQ3	;		   IRQ3
@EOI4	 equ	 60h+$IRQ4	;		   IRQ4
@EOI5	 equ	 60h+$IRQ5	;		   IRQ5
@EOI6	 equ	 60h+$IRQ6	;		   IRQ6
@EOI7	 equ	 60h+$IRQ7	;		   IRQ7

.xcref @ICR,@IMR,@CT_INDX,@CT_DATA,@ICR2,@IMR2
@ICR	 equ	 20h		; 8259 port for Master Control Register
@IMR	 equ	 21h		;		Master Mask Register
@CT_INDX equ	 22h		; C&T index port
@CT_DATA equ	 23h		; ... data  ...
@ICR2	 equ	 20h+80h	; 8259 port for Slave  Control Register
@IMR2	 equ	 21h+80h	;		Slave  Mask Register

.xcref @IMRBASE,@IMR2BASE
@IMRBASE equ	 08h		; Master PIC base
@IMR2BASE equ	 70h		; Slave ...

.xcref @GETIRR,@GETISR
@GETIRR  equ	 0Ah		; Code to request IRR from ICR
@GETISR  equ	 0Bh		;		  ISR

