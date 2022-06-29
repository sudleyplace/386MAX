;' $Header:   P:/PVCS/MAX/386MAX/QMAX_HDM.INV   1.0   11 Aug 1995 10:55:26   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_HDM.INC
;
; Equates for High DOS Memory Status.
;

HDM_FLAG equ	 QMAX_VER[1]	; High DOS memory flag

; Equates for HDM_FLAG

@HDM_OPEN equ	 '.'            ; High DOS memory open
@HDM_CLOS equ	 ';'            ; High DOS memory closed
@HDM_REL equ	 ':'            ; Memory released

