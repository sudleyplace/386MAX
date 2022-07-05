;' $Header:   P:/PVCS/MAX/INC/DSKSER.INV   1.0   05 Sep 1995 13:27:30   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DSKSER.INC
;
; Disk serial number structure
;

DSKSER_STR struc		; Disk serial # structure

DSKSER_INF dw	 ?		; Info level
DSKSER_NUM dd	 ?		; Serial # in binary
DSKSER_LBL db	 11 dup (?)	; Volume label
DSKSER_FST db	 8 dup (?)	; File system type, e.g. "FAT12   "

DSKSER_STR ends

