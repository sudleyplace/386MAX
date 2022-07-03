;' $Header:   P:/PVCS/MAX/QMT/MEM_GLB.INV   1.0   05 Sep 1995 16:55:52   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_GLB.INC
;
; Equates for GLB_FLAG.
;

@GLB_XT    equ	 8000h		; System is an XT
@GLB_X1MB  equ	 4000h		; A20 state
@GLB_XPULS equ	 2000h		; Don't pulse 8042
@GLB_SELFT equ	 1000h		; Self-test on RESET_KEYB
@GLB_NMI   equ	 0800h		; Parity error
@GLB_E000  equ	 0400h		; ROM at E000:0
@GLB_E800  equ	 0200h		; ROM at E800:0
@GLB_SHD   equ	 0100h		; Shadow RAM line displayed
@GLB_AT386 equ	 0080h		; AT/386 shadow RAM present
@GLB_XMS   equ	 0040h		; XMS handler installed
@GLB_HMA   equ	 0020h		; HMA allocated
@GLB_I15   equ	 0010h		; INT 15h intercepted
@GLB_I21   equ	 0008h		; INT 21h intercepted
@GLB_DPMIERR equ 0004h		; DPMI error has occurred, DPMIERR is valid
@GLB_WIN3  equ	 0002h		; Windows 3.x is active
@GLB_VDS   equ	 0001h		; VDS server present

