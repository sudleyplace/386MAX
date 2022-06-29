;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DB2.INV   1.0   11 Aug 1995 10:55:18   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_DB2.INC
;
; Local flags in DB2_FLAG
;

; This data item is constant

@DB2_VDS   equ	 8000h		; Call SWAT on VDS calls
@DB2_EVM   equ	 4000h		; Debug Enter VM 8086 Mode
@DB2_I67   equ	 2000h		; Debug INT 67h calls
@DB2_ESAVE equ	 1000h		; Enable EMMBUG for EMS save page maps
@DB2_XWRAP equ	 0800h		; Debug stack wraps on even boundaries
@DB2_X09   equ	 0400h		; Don't install INT 09h handler to avoid
				; keyboard problems
@DB2_XDMA  equ	 0200h		; Don't check for consecutive PTEs in DMA
@DB2_VCPI  equ	 0100h		; Install debugging code for VCPI
@DB2_I06   equ	 0080h		; Signal error on Invalid Opcodes (INT 06h)
@DB2_XMS   equ	 0040h		; Call SWAT on XMS calls
@DB2_VMS   equ	 0020h		; Check EPM on VM86 to PM mode switches
@DB2_AROM  equ	 0010h		; Force all ROM to RAM and make writable
@DB2_DPMIPHYS equ 008h		; Disable checks in DPMI_GETP2L
@DB2_CROM  equ	 0004h		; Display debug info if COMPROM fails
@DB2_SROM  equ	 0002h		; Display debug info if UNSHADOWROM fails
@DB2_ROMSW equ	 0001h		; Don't single-step over writes into video ROM

