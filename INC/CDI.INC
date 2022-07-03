;' $Header:   P:/PVCS/MAX/INC/CDI.INV   1.0   05 Sep 1995 13:27:08   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; CDI.INC
;
; Country-Dependent Information structure
;

; C O U N T R Y - D E P E N D E N T   I N F O R M A T I O N

CDI_STR  struc

CDI_FMTDAT dw	 ?		; Date format
				; 0000 = mm dd yy
				; 0001 = dd mm yy
				; 0002 = yy mm dd

CDI_SYMCUR db	 4 dup (?)	; Currency symbol
	   db	 0		; Zero terminator
CDI_SEPTHO db	 ?		; Thousands separator
	   db	 0		; Zero terminator
CDI_SEPDEC db	 ?		; Decimal separator
	   db	 0		; Zero terminator
CDI_SEPDAT db	 ?		; Date separator
	   db	 0		; Zero terminator
CDI_SEPTIM db	 ?		; Time separator
	   db	 0		; Zero terminator
CDI_FMTCUR db	 ?		; Bit field currency format
				; 00000001 = 0 for $val
				;	   = 1 for val$
				; 00000010 = # spaces between value &
				;	     currency symbol (0 or 1)
CDI_NUMDIG db	 ?		; # significant decimal digits in currency
CDI_FMTTIM db	 ?		; Bit field time format
				; 01 = 0 for 12-hour clock
				;    = 1 for 24-hour clock
CDI_CASEMAP dd	 ?		; Uppercase call map address
CDI_SEPLST db	 ?		; Data list separator
	   db	 0		; Zero terminator
CDI_RESV dw	 5 dup (?)	; Reserved

CDI_STR  ends

