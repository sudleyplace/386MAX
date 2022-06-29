;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MCS.INV   1.0   11 Aug 1995 10:55:36   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_MCS.INC
;
; Memory Chain Structure in MCSTAB
;

MCS_STR  struc

MCS_PARA dw	 ?		; Paragraph # of this entry
MCS_NPAR dw	 ?		; # paragraphs in this entry
MCS_FLAG dw	 ?		; Flags (see below)

MCS_STR  ends

@MCS_LAST  equ	 -1		; Last entry in MCS_NEXT

; The equates which are used in XLAT_FLAG in QMAX_STA must be 8-bits wide

@MCS_HOLE  equ	 0001h		; It's a hole
@MCS_UNAVL equ	 0002h		; Unavailable
@MCS_AVAIL equ	 0004h		; Allocated and available
@MCS_INUSE equ	 0008h		; Allocated and in use
@MCS_INCL  equ	 0010h		; INCLUDEd memory
@MCS_EXCL  equ	 0020h		; EXCLUDEd memory
@MCS_ROM   equ	 0040h		; ROM
@MCS_RAM   equ	 0080h		; RAM
@MCS_EXTHI equ	 0100h		; Extra high DOS memory

