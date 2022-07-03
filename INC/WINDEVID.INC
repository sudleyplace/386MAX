;' $Header:   P:/PVCS/MAX/INC/WINDEVID.INV   1.0   05 Sep 1995 13:27:10   HENRY  $
;
; (C) Copyright 1990-93 Qualitas, Inc.	GNU General Public License version 3.
;
; WINDEVID.INC
;
; Equates for OEM ID number and virtual device ID numbers
;

COMMENT|

	Device ID's are a combination of OEM # and device # in the form:

		xOOOOOOOOOODDDDD

	The high bit of the device ID is reserved for future use.  The next
	10 bits are the OEM # which is assigned by Microsoft.  The last 5 bits
	are the device #.  This allows each OEM to create 32 unique devices.
	If an OEM is creating a replacement for a standard device, then it
	should re-use the standard ID listed below.  Microsoft reserves the
	first 16 OEM #'s (0 thru 0Fh)

|

LoadHi_Device_ID equ	001Ch	; 386MAX.VxD built with LoadHi components

QUALITAS_OEM_ID equ	288	; Assigned to Qualitas by Microsoft
				; Keith in the SDK group @ 206-635-4652

SWAT_Device_ID	equ	(QUALITAS_OEM_ID shl 5)+0 ; SWATVXD
FIXNET_Device_ID equ	(QUALITAS_OEM_ID shl 5)+1 ; FIXNET
DOSMAX_Device_ID equ	(QUALITAS_OEM_ID shl 5)+2 ; DOSMAX

