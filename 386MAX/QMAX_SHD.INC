;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SHD.INV   1.0   11 Aug 1995 10:55:44   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_SHD.INC
;
; Shadow RAM and Scrub RAM structures
;

; Shadow RAM structure

SHD_STR  struc

SHD_ESIZE dw	 ?		; Size of entry in 1KB
SHD_EBASE dd	 ?		; Physical base address of entry

SHD_STR  ends


; Scrub RAM structure

SCRB_STR struc

SCRB_ESIZE dw	 ?		; Size of entry in 1KB
SCRB_EBASE dd	 ?		; Physical base address of entry

SCRB_STR ends


