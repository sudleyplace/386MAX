;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DB3.INV   1.1   05 Nov 1995 21:00:58   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_DB3.INC
;
; Local flags in DB3_FLAG
;

; This data item is constant

@DB3_SCRUB equ	 8000h		; Call SWAT in SCRUB_SHADOW
@DB3_TIME  equ	 4000h		; Call SWAT in TIME_ALLMEM
@DB3_XPTE  equ	 2000h		; Test XMS PTEs
@DB3_ABIOS equ	 1000h		; Signal NMI on ABIOS calls if BCF in effect
@DB3_BCF   equ	 0800h		; Display Interrupt nos. in SRCH_BCFINT
@DB3_EPM   equ	 0400h		; Force PM entry via our method
@DB3_XADDR equ	 0200h		; Don't display "at ____:____" message
@DB3_TRIP  equ	 0100h		; Use triple fault to reboot
@DB3_PIC   equ	 0080h		; Reprogram PIC when entering PM
@DB3_8042  equ	 0040h		; Use 8042 reset to reboot

