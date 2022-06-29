;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MSC.INV   1.0   11 Aug 1995 10:55:28   HENRY  $
;
; (C) Copyright 1992-3 Qualitas, Inc.  All rights reserved.
;
; QMAX_MSC.INC
;
; Miscellaneous flags in MSC_FLAG
;

; These flags are dynamic

MSC_REC  record  $MSC_LCLX58:1, \
		 $MSC_GETRC:1, \
		 $MSC_NODPMI:1

@MSC_LCLX58 equ  (mask $MSC_LCLX58)	; Locally disable 5800 support
@MSC_GETRC equ	 (mask $MSC_GETRC)	; Lie on next @GETRC call
@MSC_NODPMI equ  (mask $MSC_NODPMI)	; Lie about availability of DPMI services

