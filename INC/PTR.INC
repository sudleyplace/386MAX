;' $Header:   P:/PVCS/MAX/INC/PTR.INV   1.0   05 Sep 1995 13:26:54   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; PTR.INC
;
; Pointer Structures and others
;

.xcref VECTOR,VOFF,VSEG
VECTOR	 struc

VOFF	 dw	 ?		; Offset
VSEG	 dw	 ?		; Segment

VECTOR	 ends


.xcref HILO_STR,LO,HI
HILO_STR struc

LO	 db	 ?		; Register low-order byte
HI	 db	 ?		; Register high-order byte

HILO_STR ends


.xcref EGP_STR,ELO,EHI
EGP_STR  struc

ELO	 dw	 ?		; Extended register low-order word
EHI	 dw	 ?		; Extended register high-order word

EGP_STR  ends


.xcref EDD_STR,EDD
EDD_STR struc

EDD	 dd	 ?		; Doubleword

EDD_STR ends


.xcref EDF_STR,EDF
EDF_STR struc

EDF	 df	 ?		; Six-bytes

EDF_STR ends

.xcref PTR32_STR,FOFF,FSEL
PTR32_STR struc

FOFF	 dd	 ?		; 32-bit base offset
FSEL	 dw	 ?		; Selector

PTR32_STR ends

.xcref EDQ_STR,EDQLO,EDQHI
EDQ_STR  struc

EDQLO	 dd	 ?		; Low-order dword
EDQHI	 dd	 ?		; High-...

EDQ_STR  ends

.xcref DQ_STR,EDQ
DQ_STR	 struc

EDQ	 dq	 ?		; Eight-bytes

DQ_STR	 ends

