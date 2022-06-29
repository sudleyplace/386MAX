;' $Header:   P:/PVCS/MAX/386MAX/QMAX_GLB.INV   1.0   11 Aug 1995 10:55:26   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_GLB.INC
;
; Global flags for GLB_FLAG
;

; These flags are dynamic

@GLB_NMI  equ	 8000h		; NMI encountered while executing in TSS
@GLB_ERR  equ	 4000h		; Error code present
@GLB_TLB  equ	 2000h		; TLB flush needed
@GLB_ROM  equ	 1000h		; ROM swapped out
@GLB_RC   equ	 0800h		; Reason code on termination message now
@GLB_WTK  equ	 0400h		; Weitek support active
@GLB_1MB  equ	 0200h		; 1MB wrap enabled
@GLB_HMA  equ	 0100h		; HMA in use
@GLB_I67  equ	 0080h		; INT 67h intercepted
@GLB_ON   equ	 0040h		; ON/OFF state
@GLB_AUTO equ	 0020h		; AUTO state
@GLB_FORC equ	 0010h		; ON forced
@GLB_P67  equ	 0008h		; INT 67h called from PORT67 function
@GLB_X1MB equ	 0004h		; Disable 1MB wrap
@GLB_DMA  equ	 0002h		; DMA transfer in progress
@GLB_I01  equ	 0001h		; Single-step next instruction in VM

GLB_REC  record  $GLB_NMI:1,	\
		 $GLB_ERR:1,	\
		 $GLB_TLB:1,	\
		 $GLB_ROM:1,	\
		 $GLB_RC :1,	\
		 $GLB_WTK:1,	\
		 $GLB_1MB:1,	\
		 $GLB_HMA:1,	\
		 $GLB_I67:1,	\
		 $GLB_ON :1,	\
		 $GLB_AUT:1,	\
		 $GLB_FOR:1,	\
		 $GLB_P67:1,	\
		 $GLB_X1M:1,	\
		 $GLB_DMA:1,	\
		 $GLB_I01:1

