;' $Header:   P:/PVCS/MAX/INC/CMOS.INV   1.0   05 Sep 1995 13:26:42   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; CMOS.INC
;
; CMOS equates
;

; To enable NMI,  write to the command port @CMOS_ENANMI
; To disable NMI, write to the command port @CMOS_DISNMI
; Be sure to read from @CMOS_DATA afterwards to complete the cycle
; The low-order seven bits of the byte select a CMOS register

@CMOS_CMD    equ 70h		; Command register
@CMOS_DATA   equ 71h		; Data register

@CMOS_NMIOFF equ 80h		; Disable NMI
@CMOS_SHUT   equ 0Fh		; Register to access shutdown byte
@CMOS_ENANMI equ 0Dh		; Register to enable  NMI
@CMOS_DISNMI equ @CMOS_ENANMI or @CMOS_NMIOFF ; Register to disable NMI
@CMOS_EXTLO  equ 17h		; Extended memory size, low byte
@CMOS_EXTHI  equ 18h		; ...			high ...
@CMOS_CHKHI  equ 2Eh		; Extended memory size, high byte
@CMOS_CHKLO  equ 2Fh		; ...			low ...

