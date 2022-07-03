;' $Header:   P:/PVCS/MAX/386MAX/QMAX_A20.INV   1.0   11 Aug 1995 10:55:12   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_A20.INC
;
; Structure for GATEA20 and DEGATEA20 routines
;

ACTA20_STR struc

ACTA20_I92 dw	 ?		; Action routine for I/O port 92 systems
ACTA20_QUD dw	 ?		; ...		     Quadram 386/XT ...
ACTA20_XT  dw	 ?		; ...		     other XT ...
ACTA20_ISA dw	 ?		; ...		     ISA bus ...
ACTA20_I78 dw	 ?		; ...		     I/O port 78 ...

ACTA20_STR ends

