;' $Header:   P:/PVCS/MAX/QMT/MEM_DTE.INV   1.0   05 Sep 1995 16:55:56   HENRY  $
;
; (C) Copyright 1988-1999 Qualitas, Inc.  GNU General Public License version 3.
;
; MEM_DTE.INC
;
; Structures and equates for Descriptor Table Entries.
;

.xcref XDTE_STR
XDTE_STR struc

	db	(size DTE_STR) dup (0) ; 00-38 INT 15h/89h (initialized to 0)
DTE_PMCS dq	0		; 40:  1st selector for VCPI PMI
	dq	0		; 48:  2nd ...
	dq	0		; 50:  3rd ...
DTE_TSS dq	0		; 58:  Task selector
DTE_4GB dq	0		; 60:  All memory ...
DTE_LDT dq	0		; 68:  LDT ...
DTE_ERRD dq	0		; 70:  Error data ...
DTE_TTD dq	0		; 78:  TESTTIME data ...
DTE_ALIAS dq	0		; 80:  Code alias
DTE_SWAT dq	30 dup (0)	; 88:  386SWAT selectors

XDTE_STR ends


