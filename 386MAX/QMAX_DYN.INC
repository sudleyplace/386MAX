;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DYN.INV   1.0   11 Aug 1995 10:55:30   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; QMAX_DYN.INC
;
; Structures and equates for DPMI Dynamic save area
;

DYNHDR_STR struc

DYNHDR_FN db	 ?	; Function code (@DYNHDR_EOL = end of the line)
DYNHDR_LEN db	 ?	; Byte length of this entry (including the header)
DYNHDR_TSS dw	 ?	; TSS selector of allocator

; The header is followed by variable length data depending
; upon the function code

DYNHDR_STR ends


@DYNFN_EOL    equ 0FFh	; Function code indicating no more records
@DYNFN_DEL    equ 0FEh	; Function code indicating deleted record

@DYNFN_VMIV   equ 00h	; Function code for SETVMIV
@DYNFN_P2L    equ 01h	; ...		    GETP2L


DYNVMIV_STR struc

	 db	 (size DYNHDR_STR) dup (?) ; Header structure
DYNVMIV_NUM db	 ?	; Interrupt #
DYNVMIV_VEC dd	 ?	; Last specified interrupt vector

DYNVMIV_STR ends


DYNP2L_STR struc

	 db	 (size DYNHDR_STR) dup (?) ; Header structure
DYNP2L_OFF dd	 ?	; Offset in PGROUP of 1st PTE
DYNP2L_LEN dd	 ?	; # PTEs assigned

DYNP2L_STR ends


