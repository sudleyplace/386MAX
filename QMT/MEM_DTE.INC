;' $Header:   P:/PVCS/MAX/QMT/MEM_DTE.INV   1.0   05 Sep 1995 16:55:56   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_DTE.INC
;
; Structures and equates for Descriptor Table Entries.
;

.xcref XDTE_STR
XDTE_STR struc

	 db	 (size DTE_STR) dup (0) ; 00-38 INT 15h/89h (initialized to 0)
DTE_PMCS dq	 0		; 40:  1st selector
DTE_PMDS dq	 0		; 48:  2nd ...
DTE_PMES dq	 0		; 50:  3rd ...
DTE_TSS  dq	 0		; 58:  Task ...
DTE_4GB  dq	 0		; 60:  All memory ...
DTE_LDT  dq	 0		; 68:  LDT ...
DTE_ALIAS dq	 0		; 70:  Code alias
DTE_SWAT dq	 30 dup (0)	; 78:  386SWAT selectors

XDTE_STR ends


