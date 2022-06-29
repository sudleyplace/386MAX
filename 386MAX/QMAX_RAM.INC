;' $Header:   P:/PVCS/MAX/386MAX/QMAX_RAM.INV   1.0   11 Aug 1995 10:55:42   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_RAM.INC
;
; Equates for high DOS memory RAM scan
;

RAM_REC  record  $RAM_VID:1,$RAM_PSM:1,$RAM_OVR:1,$RAM_RO1:1,$RAM_ROM:1, \
		 $RAM_EMS:1,$RAM_IDN:1,$RAM_RAM:1

; $RAM_VID = 1 iff video RAM
; $RAM_PSM = 1 iff PS memory
; $RAM_OVR = 1 iff high DOS memory
; $RAM_RO1 = 1 iff physical address contains first byte of ROM
; $RAM_ROM = 1 iff physical address contains ROM
; $RAM_EMS = 1 iff address is EMS-mappable
; $RAM_IDN = 1 iff linear to physical mapping is one-to-one
; $RAM_RAM = 1 iff physical address contains RAM

