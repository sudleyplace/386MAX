;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CM3.INV   1.0   11 Aug 1995 10:55:16   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_CM3.INC
;
; Local flags for command line arguments for CM3_FLAG
;


@CM3_NOFR  equ	 8000h		;	   NOFRAME
@CM3_FSTRM equ	 4000h		;	   FASTRAM
@CM3_XSCRB equ	 2000h		;	   NOSCRUB
@CM3_DMA   equ	 1000h		;	   DMA=nnn
@CM3_XA20  equ	 0800h		;	   FORCEA20
@CM3_LOWFR equ	 0400h		;	   LOWFRAME (HPRS only)
@CM3_TRACE equ	 0200h		;	   TRACE
@CM3_XPULS equ	 0100h		;	   NOPULSE
@CM3_XLHI  equ	 0080h		;	   NOLOADHI
@CM3_DOS4  equ	 0040h		;	   DOS4
@CM3_SHDCA equ	 0020h		;	   SHADOWRAM for CompuAdd
@CM3_PREG  equ	 0010h		;	   PRGREG=n
@CM3_PREG0 equ	 0008h		;	   PRGREG=0
@CM3_XCROM equ	 0004h		;	   NOCOMPROM
@CM3_ROMSH equ	 0002h		;	   SHADOWROM
@CM3_NOWIN3 equ  0001h		;	   NOWIN3

