;' $Header:   P:/PVCS/MAX/386LOAD/LOAD_RES.INV   1.0   05 Sep 1995 14:47:48   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; LOAD_RES.INC
;
; Structure for secondary resident programs
;

RESTAB_STR struc

RES_PSP  dw	 ?		; Segment # of resident program PSP
;;;_LEN  dw	 ?		; Length of resident program in paras

RESTAB_STR ends

