;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CM2.INV   1.1   28 Sep 1995 10:13:12   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_CM2.INC
;
;  Local flags for command line arguments for CM2_FLAG

@CM2_NOPnP equ	 8000h		;	   Skip Plug 'n Play support
@CM2_RAM   equ	 4000h		;	   RAM=xxxx L llll
@CM2_ROM   equ	 2000h		;	   ROM=xxxx L llll
@CM2_USE   equ	 1000h		;	   USE=xxxx L llll
@CM2_NWB   equ	 0800h		;	   NOWARMBOOT
@CM2_SHD   equ	 0400h		;	   SHADOWRAM
@CM2_TOP   equ	 0200h		;	   TOP384
@CM2_INC   equ	 0100h		;	   INCLUDE=xxxx L llll
@CM2_NOTIME equ  0080h		;	   NOTIME
@CM2_SELFT equ	 0040h		;	   RESETKEYB (self test)
@CM2_SDMA  equ	 0020h		;	   SLOWDMA
@CM2_EISA_DMA equ 0010h 	;	   EISA DMA machine
@CM2_SCR   equ	 0008h		;	   SCREEN
@CM2_XSCSI equ	 0004h		;	   NOSCSI
@CM2_X384  equ	 0002h		;	   NOXRAM
@CM2_UNSH  equ	 0001h		;	   UNSHIFT

