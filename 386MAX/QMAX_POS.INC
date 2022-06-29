;' $Header:   P:/PVCS/MAX/386MAX/QMAX_POS.INV   1.0   11 Aug 1995 10:55:52   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_POS.INC
;
; Structures and equates for accessing the POS.
;

; Structure used by EMM2_POSCOPY
POSD_STR struc

POSD_ID  dw	 -1		; Adapter ID
POSD_CMOS db	 4 dup (?)	; CMOS POS values

POSD_STR ends

; Structure used by quilib\mca_pos
MCA_STR  struc

MCA_AID  dw	 ?		; Adapter ID
MCA_POS0 db	 ?		; POS[0]
MCA_POS1 db	 ?		; POS[1]
MCA_POS2 db	 ?		; POS[2]
MCA_POS3 db	 ?		; POS[3]
MCA_SUBA dw	 ?		; Subaddress extension

MCA_STR  ends

; NOTE: If this constant changes, the constant for structures in
; related C code must be changed too.  See MCA_POS.H.
@MAXPOSDEV	equ	8+1	; Number of POS devices supported by MAX
				; (8 slots + system board)

@NVRAMPOSMAX	equ	32	; Maximum POS bytes for system board
@NVRAMPOSBASE	equ	0369h	; Base port address for system board POS[0]
@NVRAMIND_LO	equ	74h	; Low byte of NVRAM index
@NVRAMIND_HI	equ	75h	; High byte of NVRAM index
@NVRAMDATA	equ	76h	; Data port for NVRAM values

