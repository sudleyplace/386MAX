;' $Header:   P:/PVCS/MAX/RAMBASIC/RB_LCL.INV   1.0   05 Sep 1995 17:11:52   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; RB_LCL.INC
;
; Local flags in RB_FLAG for RAMBASIC.ASM
;

; These flags are constant

@LCL_EMS	equ	8000h	; ROM BASIC is to be copied to EMS Page Frame
@LCL_REMOVE	equ	4000h	; Remove a resident TSR
@LCL_PCDOS	equ	2000h	; Assume PC-DOS is present
@LCL_DPMI_PRES	equ	1000h	; Use DPMI to transfer ROM BASIC
@LCL_DPMI_ERR	equ	0800h	; DPMI error condition
@LCL_F600	equ	0400h	; Assume BASIC is at F600

