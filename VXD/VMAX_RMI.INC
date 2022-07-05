;' $Header:   P:/PVCS/MAX/VXD/VMAX_RMI.INV   1.0   05 Sep 1995 17:20:52   HENRY  $
;
; (C) Copyright 1990-92 Qualitas, Inc.	GNU General Public License version 3.
;
; VMAX_RMI.INC
;
; Bit definitions for RMI_FLAG and REFDATA.REF_R2PFLAG
;

; RMI_FLAG

@RMI_DEBUG	equ	8000h	; Do an INT 1 in RMI
@RMI_PAK	equ	4000h	; Wait for a keystroke after list
;;;@RMI_	equ	2000h	; <<<available>>>
@RMI_BANNER	equ	1000h	; Display the RMI banner

@RMI_EMSCACHE	equ	0800h	; EMS call detected during EMS disk cache test

@RMI_SHOWINFO	equ	0400h	; MAXVXD environment variable set
				; Show all warnings and debugging information

@RMI_INT67	equ	0200h	; INT 67h got called during EMS disk cache test
@RMI_EMSPATCH	equ	0100h	; QMAX.SYS' EMS handler is patched

@RMI_FAIL	equ	0040h	; Prevent Windows from starting due to errors
@RMI_NOLOAD	equ	0020h	; Prevent device  from starting due to errors

;;;@RMI_	equ	0008h	; <<<available>>>
@RMI_386ENH	equ	0004h	; We're inside the [386Enh] section

@RMI_KRNLFND	equ	0002h	; We found and opened KRNL386.EXE
@RMI_SMART4_DB	equ	0001h	; SMARTDRV 4 found to be double buffering

; RMI_REF_DATA.REF_R2PFLAG

@R2P_SHORT	equ	8000h	; No DOSMAX due to short low DOS size

