;' $Header:   P:/PVCS/MAX/INCLUDE/RAMSCAN.INV   1.0   05 Sep 1995 13:30:20   HENRY  $
;
; (C) Copyright 1991-94 Qualitas, Inc.	All rights reserved.
;
; RAMSCAN.INC
;
; Include file for RAMSCAN.ASM
;

.code

IFNDEF @RAMSCAN_OWNR

IF @NO_UNDERBAR EQ 1

extrn	_Get_BIOS_Start:proc
extrn	_Get_CMOS_POS:proc

extrn	_MAXPRES:proc
extrn	_CHECK_RAM:proc
extrn	_EMM2_VXD_Call:proc
extrn	_FLUSH_CACHE:proc

ELSE

extrn	Get_BIOS_Start:proc
extrn	Get_CMOS_POS:proc

extrn	MAXPRES:proc
extrn	CHECK_RAM:proc
extrn	EMM2_VXD_Call:proc
extrn	FLUSH_CACHE:proc

ENDIF		; @NO_UNDERBAR

ENDIF		; IFDEF @RAMSCAN_OWNR

@LCLMEM_BITS equ 10		; Significant bits for @LCLMEM_LEN
@LCLMEM_LEN equ  (1 shl (@LCLMEM_BITS-1)) ; Size in bytes of LCLMEM (512).
				; NOTE: The smaller LCLMEM is, the
				; longer memory scans will take.

