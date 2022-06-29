;' $Header:   P:/PVCS/MAX/INCLUDE/VENDINFO.INV   1.0   05 Sep 1995 13:30:20   HENRY  $
;
; (C) Copyright 1991-94 Qualitas, Inc.	All rights reserved.
;
; VENDINFO.INC
;
; Include file for VENDINFO.ASM
;

IFNDEF @VENDINFO_OWNR

.code

IF @NO_UNDERBAR EQ 1

extrn	_Is_MCA:proc
extrn	_Is_VM:proc
extrn	_Is_IBM:proc
extrn	_Is_BCF:proc

ELSE

extrn	Is_MCA:proc
extrn	Is_VM:proc
extrn	Is_IBM:proc
extrn	Is_BCF:proc

ENDIF		; @NO_UNDERBAR

ENDIF		; IFNDEF @VENDINFO_OWNR

@SUB_VM   equ	 8000h		; 1 = Virtual Mode
@SUB_PRES equ	 4000h		; 1 = 386MAX present
@SUB_MCA  equ	 2000h		; 1 = it's an MCA
@SUB_XT   equ	 1000h		; 1 = it's an XT
@SUB_I23  equ	 0800h		; 1 = INT 23h enabled
@SUB_BCF  equ	 0400h		; 1 = BCF capable
@SUB_486  equ	 0200h		; 1 = 486 or later CPU
@SUB_XINVD equ	 0100h		; 1 = WBINVD doesn't work (NOGATE)

