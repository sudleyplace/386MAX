;' $Header:   P:/PVCS/MAX/INC/A20.INV   1.0   05 Sep 1995 13:27:16   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; A20.INC
;
; A20 architecture functions
;

.xcref @A20_DIS,@A20_ENA,@A20_QRY,@A20_SUP
@A20_DIS equ	 2400h		; Disable A20
@A20_ENA equ	 2401h		; Enable A20
@A20_QRY equ	 2402h		; Query A20 (AL = 0 disabled, = 1 enabled)
@A20_SUP equ	 2403h		; Query A20 support (BX has record bits)

; On return
; AH = 00	 successful
; AH = 01	 8042 locked
; AH = 86	 function not supported
; CF = 0	 successful
;    = 1	 unsuccessful

.xcref A20SUP_STR
A20SUP_STR record $A20_MORE:1,$A20_RSVD:13,$A20_I92:1,$A20_8042:1

