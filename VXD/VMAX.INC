;' $Header:   P:/PVCS/MAX/VXD/VMAX.INV   1.0   05 Sep 1995 17:20:52   HENRY  $
;
; (C) Copyright 1990-93 Qualitas, Inc.	GNU General Public License version 3.
;
; VMAX.INC
;
; Master include file for 386MAX.VXD
;

ifdef @DEBUG
    if1
	%OUT Including debugging features
    endif			; IF1
else
    if1
	%OUT Disabling debugging features
    endif			; IF1
endif				; IFDEF @DEBUG

ifdef @VGASWAP
    if1
	%OUT Including VGASWAP support
    endif			; IF1
endif				; IFDEF @VGASWAP

ifdef @HARPO
    if1
	%OUT Including HARPO support
    endif			; IF1
endif				; IFDEF @HARPO

ifdef @DOSMAX
    if1
	%OUT Including DOSMAX support
    endif			; IF1
endif				; IFDEF @DOSMAX

ifdef @FLASH
    if1
	%OUT Including FLASH support
    endif			; IF1
endif				; IFDEF @FLASH

; Macros

; Macro to consume MASM 6 OPTION directive in H2INCed include files

OPTION	 macro	 OPT
	 endm			; End OPTION macro

option	 macro	 OPT
	 endm			; End option macro

