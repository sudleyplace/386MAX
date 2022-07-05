;' $Header:   P:/PVCS/MAX/386MAX/QMAX_FIL.INV   1.1   01 Jul 1997 18:22:14   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_FIL.INC
;
; FILE_STR structure of common variables between 386MAX and SWAT
;

FILE_STR struc

FILE_4GB dw	 ?		; Descriptor table entry for DTE_D4GB
FILE_VID dw	 ?		; ...			     Video Buffer
FILE_CR3 dw	 ?		; ...			     Page Directory Base Register
FOLD_4GB dw	 ?		; Previous DTE for 4GB selector
FOLD_CR3 dw	 ?		; ...		   CR3 ...
	 dw	 18 dup (?)	; Reserved

FILE_STR ends


