;' $Header:   P:/PVCS/MAX/VXD/VMAX_VID.INV   1.0   05 Sep 1995 17:20:56   HENRY  $
;
; (C) Copyright 1990-92 Qualitas, Inc.	GNU General Public License version 3.
;
; VMAX_VID.INC
;
; Bit definitions for REF_VIDFLAG
;

; In version 5.12, the REF_DATA_STR.REF_VIDFLAG field is a DWORD
; The flag bits were duplicates of those used by the VDD

@VID_VGASWAP	equ	80000000h ; VGASWAP is in effect

@VID_TLVGA	equ	40000000h ; Tseng Labs VGA chipset
@VID_V7VGA	equ	20000000h ; Video 7 VGA chipset
@VID_PVGA	equ	10000000h ; Paradise Super VGA chipset
@VID_PVGAROM	equ	08000000h ; Paradise VGA BIOS ROM
@VID_STBROM	equ	04000000h ; STB VGA BIOS ROM

@VID_CACHEDPVGA equ	02000000h ; Cached the VGA ROM on a Paradise chipset
@VID_C000NOIO	equ	01000000h ; C000 is VGASWAPed w/o memory-mapped I/O

