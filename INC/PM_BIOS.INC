;'$Header:   P:/PVCS/MAX/INC/PM_BIOS.INV   1.0   05 Sep 1995 13:27:40   HENRY  $
;
; (C) Copyright 1993 Qualitas, Inc.  GNU General Public License version 3.
;
; PM_BIOS.INC
;
; Definitions for Thinkpad PM_BIOS.386 (PMVDD)
;

PM_BIOS_Device_ID	equ	2250h	; Thinkpad PM_BIOS.386 (PMVDD)
PMVDD_Device_ID 	equ	2250h	; Thinkpad PM_BIOS.386 (PMVDD)

Begin_Service_Table	PM_BIOS

PM_BIOS_Service PM_BIOS_Get_Version
PM_BIOS_Service PM_BIOS_Unknown1

End_Service_Table	PM_BIOS

