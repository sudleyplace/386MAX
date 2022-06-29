;' $Header:   P:/PVCS/MAX/386MAX/QMAX_PPM.INV   1.0   11 Aug 1995 10:55:40   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_PPM.INC
;
; Equates for PPMTAB
;

@PPM_AVL equ	 00h		; Available page
@PPM_CNV equ	 01h		; Conventional page
@PPM_INC equ	 02h		; INCLUDEd page
@PPM_EXC equ	 03h		; EXCLUDEd page
@PPM_FRM equ	 04h		; EMS frame
@PPM_SCR equ	 05h		; SCREEN page
@PPM_RAM equ	 06h		; RAM
@PPM_ROM equ	 07h		; ROM

PPM	 record  $PPM_SHD:1,$PPM_RSV:7

