;' $Header:   P:/PVCS/MAX/386MAX/UTIL_USE.INV   1.0   11 Aug 1995 10:56:00   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; UTIL_USE.INC
;
; Structures for USEFRAME
;

PAA_STR  struc			; Physical Address Array Structure

PAA_SEG  dw	 ?		; Segment #
PAA_PPN  db	 ?		; Physical page #
	 db	 ?		; Filler

PAA_STR  ends


@NMAPS	 equ	 8		; Maximum # mappable regions we handle

MAP_STR  struc

MAP_SEG  dw	 ?		; Starting segment # of preceding MAC entry
MAP_END  dw	 ?		; Ending segment of top MAC entry
MAP_LEN  dw	 ?		; Length in paras
				; For example, with a 16KB mappable page
				; at C400 and a page frame at E400,
				; the table entries are
				; C3FF	D3FF  0400
				; E3FF	F3FF  1000

MAP_STR  ends

