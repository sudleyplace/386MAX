;' $Header:   P:/PVCS/MAX/INC/LIB.INV   1.0   05 Sep 1995 13:27:46   HENRY  $
; (C) Copyright 1995 Qualitas, Inc.  GNU General Public License version 3.
;
; LIB.INC
;
; Library File structures, records, and equates
;

LIBHDR_STR struc		; Library header struc

LIBHDR_TYPE db	 ?		; 00:  Type byte (F0h)
LIBHDR_RLEN dw	 ?		; 01:  Record length
LIBHDR_DOFF dd	 ?		; 03:  Dictionary offset
LIBHDR_DSIZ dw	 ?		; 07:  Dictionary size in blocks
LIBHDR_FLAG db	 ?		; 09:  Flags:  see LIBHDR_REC below

LIBHDR_STR ends

LIBHDR_REC record \
		  $LIBHDR_CASE:1

@LIBHDR_CASE equ (mask $LIBHDR_CASE) ; 01:  Name comparisons are case-sensitive


LIBXHDR_STR struc		; Library ext dict header struc

LIBXHDR_TYPE db  ?		; 00:  Type byte (F2h)
LIBXHDR_RLEN dw  ?		; 01:  Record length
LIBXHDR_NMOD dw  ?		; 03:  # modules in library

LIBXHDR_STR ends


LIBXMOD_STR struc		; Library ext dict module table

LIBXMOD_PGNO dw  ?		; 00:  Page #
LIBXMOD_PMOD dw  ?		; 02:  Offset from start of extended dictionary
				; to list of dependent modules (null-terminated)
LIBXMOD_STR ends


LIBDEP_STR struc		; Library dependency table in extended dictionary

LIBDEP_MOD dw	 ?		; 00:  Dependent module #

LIBDEP_STR ends


