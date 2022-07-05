;' $Header:   P:/PVCS/MAX/386MAX/QMAX_LCL.INV   1.0   11 Aug 1995 10:55:56   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_LCL.INC
;
; Local flags in LCL_FLAG
;

; These flags are constant

@LCL_BCF   equ	 8000h		; BIOS Compression File in effect
@LCL_WRP   equ	 4000h		; WRAPTAB initialized
@LCL_LML   equ	 2000h		; Low memory load on
@LCL_DRV   equ	 1000h		; Another EMS driver present
@LCL_XT    equ	 0800h		; XT system board present
@LCL_4MB   equ	 0400h		; PDE PTE is beyond first 4MB
@LCL_SWAT  equ	 0200h		; 386SWAT installed
@LCL_LOWFR equ	 0100h		; Low EMS page frame in effect
@LCL_NDPIN equ	 0080h		; NDP present in the system
@LCL_MCA   equ	 0040h		; MCA-compatible machine
@LCL_LODHI equ	 0020h		; LOADHI in effect
@LCL_DPMI  equ	 0010h		; DPMI services requested by a load module
@LCL_RBT   equ	 0008h		; Reboot in progress
@LCL_VGA   equ	 0004h		; VGA present
@LCL_QEXT  equ	 0002h		; New-style QEXT.SYS installed
@LCL_CROM  equ	 0001h		; Compressed ROM in effect

