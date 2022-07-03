;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DMA.INV   1.0   11 Aug 1995 10:55:20   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_DMA.INC
;
; Equates for DMA_FLAG
;

@DMA_MCA  equ	 04h		; MCA-compatible machine transfer
@DMA_1MB  equ	 02h		; Source is within 1MB wrap area
@DMA_BYTE equ	 01h		; 1 = 8-bit transfer channel, 0 = 16-bit

; Equates for DMA controllers #1 and #2 when in same byte

DMA_CTRL record  $DMA_CTRL2:4,$DMA_CTRL1:4

@DMA_MIN_LEN	 equ	   8	; Minimum value for DMASIZE
@DMA_MAX_LEN	 equ	 128	; Maximum ...
@DMA_MAX_EISALEN equ 16*1024	; Maximum ...		    (if EISA system)

@DMA_DEF equ	  16		; Default ...
@DMA_DSK equ	  64		; Hard disk ...
@DMA_288 equ	  64		; 2.88MB diskette drive
@DMA_PA_XT  equ   000A0000h	; Maximum physical address for XTs
@DMA_PA_SHD equ   000A0000h	; Maximum physical address for SHADOWRAM systems
@DMA_PA_ATLO equ  000A0000h	; Maximum low physical address for AT-class systems
@DMA_PA_ATHI equ  01000000h	; Maximum high ...
@DMA_PA_BIMHI equ 00FE0000h	; Maximum high physical address for BIM machines
@DMA_PA_EISA equ 0FFFFFFFFh	; Maximum high physical address for EISA machines

