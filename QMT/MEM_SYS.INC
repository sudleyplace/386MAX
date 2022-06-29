;' $Header:   P:/PVCS/MAX/QMT/MEM_SYS.INV   1.0   05 Sep 1995 16:55:54   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	All rights reserved.
;
; MEM_SYS.INC
;
; Equates for SYS_FLAG.
;

; Equates for SYS_FLAG

@SYS_JET386  equ 8000h		; JET386
@SYS_CPQ     equ 4000h		; COMPAQ Deskpro 386
@SYS_HPRS    equ 2000h		; HP Vectra RS/16 or /20
@SYS_INBRD   equ 1000h		; Either Inboard/AT or /PC
@SYS_INBRDAT equ 0800h		; Inboard/AT
@SYS_INBRDPC equ 0400h		; Inboard/PC
;;;S_PS2     equ 0200h		; PS/2-compatible machine
@SYS_AST386  equ 0100h		; AST Premium 386
@SYS_GRID    equ 0080h		; GRiD Systems
@SYS_QUAD386 equ 0040h		; Quadram 386XT
@SYS_OLI     equ 0020h		; Olivetti/AT&T
@SYS_TOSH    equ 0010h		; Toshiba 5100
@SYS_ITT     equ 0008h		; ITT XTRA
@SYS_EISA    equ 0004h		; EISA system

