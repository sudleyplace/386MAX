;' $Header:   P:/PVCS/MAX/QMT/MEM_A20.INV   1.0   05 Sep 1995 16:56:06   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_A20.INC
;
; Structure for GATEA20 and DEGATEA20 routines
;
; Derived from QMAX_A20.INC
;

ACTA20_STR struc

ACTA20_I92 dw	 ?		; Action routine for I/O port 92 systems
ACTA20_QUD dw	 ?		; ...		     Quadram 386/XT ...
ACTA20_XT  dw	 ?		; ...		     other XT ...
ACTA20_ISA dw	 ?		; ...		     ISA bus ...
ACTA20_I78 dw	 ?		; ...		     I/O port 78 ...
ACTA20_XMS dw	 ?		; ...		     XMS driver present

ACTA20_STR ends

