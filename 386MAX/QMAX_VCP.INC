;' $Header:   P:/PVCS/MAX/386MAX/QMAX_VCP.INV   1.0   11 Aug 1995 10:55:50   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_VCP.INC
;
; VCPI Enter Protected Mode structure
;

; Equates

@VCP_OLD  equ	 1		; 1 = implement old VCPI spec
				; 0 = don't

; VCPI Enter Protected Mode structure

EPM_STR  struc

EPM_CR3  dd	 ?		; New CR3
EPM_GDTP dd	 ?		; Pointer to new GDTR base
EPM_IDTP dd	 ?		; Pointer to new IDTR base
EPM_LDTR dw	 ?		; New LDTR
EPM_TR	 dw	 ?		; New TR
EPM_EXIT df	 ?		; CS:EIP of exit point

EPM_STR  ends


