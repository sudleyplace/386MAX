;'$Header:   P:/PVCS/MAX/VXD/VMAX_PMI.INV   1.1   11 Oct 1995 17:43:14   BOB  $
;
; (C) Copyright 1990-95 Qualitas, Inc.	GNU General Public License version 3.
;
; VMAX_PMI.INC
;
; Bit definitions for PMI_FLAG
;

@PMI_V86DISPLAY equ    20000h	; Display errors from assigning V86 RAM= pages
@PMI_V86ASSIGN	equ    10000h	; Assign V86 RAM= pages
@PMI_HOOKED_GPB equ	8000h	; We've hooked Get_Profile_Boolean
@PMI_VCPIWARN	equ	4000h	; We need to lie about VCPIWarning
@PMI_UMB	equ	2000h	; We need to lie about XMSUMBINITCALLS

@PMI_NONSPAN	equ	1000h	; Hit a non-spanning entry in SETUP_HIGHDOS_MAPS

@PMI_SYSVM	equ	0800h	; Sys_VM_Init has been by
@PMI_INITCOMP	equ	0400h	; Init_Complete has been by

@PMI_VDDPF	equ	0200h	; VDD's page fault is hooked for HARPO

@PMI_VIRT_HIGHDOS equ	0008h	; Virtual high DOS is enabled
@PMI_HARPO	equ	0004h	; HARPO support enabled
@PMI_DOSMAX	equ	0002h	; DOSMAX support enabled
@PMI_FLASH	equ	0001h	; Flash support enabled

