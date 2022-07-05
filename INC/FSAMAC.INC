;' $Header:   P:/PVCS/MAX/INC/FSAMAC.INV   1.0   05 Sep 1995 13:27:02   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; FSAMAC.INC
;
; FSAMAC macro
;

FSAMAC	 macro	 SYM,ACT,TAB

	 if	 FSA_CNT eq 0
	 ifb	 <TAB>
ACTION	 label	 word
	 else
TAB	 label	 word
	 endif
	 endif

SYM	 =	 FSA_CNT	;; Define the symbol *MUST* use "=" not "equ"
FSA_CNT  =	 FSA_CNT+2	;; By twos to index FSA and ACTION
	 dw	 ACT		;; Entry in ACTION table

	 endm

