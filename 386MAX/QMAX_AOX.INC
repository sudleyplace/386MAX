;' $Header:   P:/PVCS/MAX/386MAX/QMAX_AOX.INV   1.0   11 Aug 1995 10:55:54   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_AOX.INC
;
; Structures and equates for AOX CPU replacement cards
;

@AOX_MMD equ	073h	; AOX Micro master data port

;
; Commands for AOX_MMD port
;
@AOX_RID equ	0	; Read CPU information
@AOX_RTT equ	1	; Read translation table

AOXI_STR struc

AOX_SIG  dw	?	; Signature returned from read (0aa55h)
AOX_ILN  dw	?	; Number of bytes to follow
AOX_CPU  db	?	; CPU type (3=386, 4=586)
AOX_REV  db	?	; Intel rev number
AOX_SPD  db	?	; Speed in Mhz
AOX_MSZ  dd	?	; Memory size in bytes
AOX_MST  dd	?	; Bus view of memory start in bytes
AOX_CSZ  dw	?	; Size of cache in Kb
AOX_MID  dw	?	; Manufacture ID (board id)
AOX_MOD  db	?	; Model byte (0)
AOX_ROM  dw	?	; ROM revision

AOXI_STR ends
;
;
;
@RSV_SEG equ	0FFFFh	; Segment of the CPU reset code

