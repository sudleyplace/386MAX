;' $Header:   P:/PVCS/MAX/VXD/VMAX_DBG.INV   1.0   05 Sep 1995 17:20:54   HENRY  $
;
; (C) Copyright 1990-93 Qualitas, Inc.	All rights reserved.
;
; VMAX_DBG.INC
;
; Bit definitions for DBG_FLAG
;

@DBG_DUAL	equ	8000h	; Display debugging info on monochrome screen
;;;@DBG_	equ	4000h	; <<available>>
;;;@DBG_	equ	2000h	; <<available>>
@DBG_HARPO	equ	1000h	; HARPO debugging supprt enabled
@DBG_DOSMAX	equ	0800h	; DOSMAX debugging support enabled
@DBG_FLASH	equ	0400h	; Flash debugging support enabled

@DBG_CRITINIT	equ	0200h	; Break in SYS_CRIT_INIT
@DBG_DEVINIT	equ	0100h	; Break in DEVICE_INIT

@DBG_INITCOMP	equ	0080h	; Break in INIT_COMPLETE
@DBG_SYSVMINIT	equ	0040h	; Break in SYS_VM_INIT
@DBG_CREATEVM	equ	0020h	; Break in CREATE_VM
@DBG_SYSEXIT	equ	0010h	; Break in SYSTEM_EXIT

@DBG_SYSCRITEXIT equ	0008h	; Break in SYS_CRITICAL_EXIT
@DBG_API1684	equ	0004h	; Break in API_1684
@DBG_AUTOINST	equ	0002h	; Break in automatic instancing code
@DBG_INT0E	equ	0001h	; Break in ROM page fault code

