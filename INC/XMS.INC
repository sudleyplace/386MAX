;' $Header:   P:/PVCS/MAX/INC/XMS.INV   1.0   05 Sep 1995 13:26:50   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; XMS.INC
;
; Equates for XMS functions
;

@XMS_PRES equ	 4300h		; Detect XMS presence via INT 2Fh
@XMS_ADDR equ	 4310h		; Request XMS entry point ...

@XMS_VERS   equ  00h		; Return version # in AX, debugging in DX
@XMS_REQHMA equ  01h		; Request HMA
@XMS_RELHMA equ  02h		; Release HMA
@XMS_GLBENA equ  03h		; Global Enable A20
@XMS_GLBDIS equ  04h		; Global Disable A20
@XMS_LCLENA equ  05h		; Local Enable A20
@XMS_LCLDIS equ  06h		; Local Disable A20
@XMS_QRYA20 equ  07h		; Query A20 status
@XMS_QRYXMB equ  08h		; Query free extended memory block
@XMS_GETXMB equ  09h		; Allocate extended memory block
@XMS_RELXMB equ  0Ah		; Release extended memory block
@XMS_MOVXMB equ  0Bh		; Move extended memory block
@XMS_LCKXMB equ  0Ch		; Lock extended memory block
@XMS_UNLXMB equ  0Dh		; Unlock extended memory block
@XMS_GETINF equ  0Eh		; Get handle information
@XMS_MODXMB equ  0Fh		; Reallocate extended memory block
@XMS_GETUMB equ  10h		; Allocate upper memory block
@XMS_RELUMB equ  11h		; Release upper memory block
@XMS_MODUMB equ  12h		; Re-allocate upper memory block
@XMS_QRY2XMB equ 88h		; Query free extended memory block
@XMS_GET2XMB equ 89h		; Allocate extended memory block
@XMS_GET2INF equ 8Eh		; Get handle information
@XMS_MOD2XMB equ 8Fh		; Reallocate extended memory block
@XMS_GET2UMB equ 90h		; Allocate upper memory block from specific region


; Structure for XMS Block Moves

XMBMOVE_STR struc		; XMS Block Move structure

XMBMOVE_LEN dd	 ?		; 00-03:  Length of move in bytes
XMBMOVE_SHNDL dw ?		; 04-05:  Source handle (0=conventional)
XMBMOVE_SOFF  dd ?		; 06-09:  Source offset (if handle=0, Seg:Off)
XMBMOVE_DHNDL dw ?		; 0A-0B:  Destin handle ...
XMBMOVE_DOFF  dd ?		; 0C-0F:  Destin offset ...

XMBMOVE_STR ends

GETXSTAT macro			; Return XMS status
	mov	ax,@XMS_PRES
	int	2FH
	endm

GETXPTR macro			; Return Pointer to XMS functions
	mov	ax,@XMS_ADDR
	int	2FH
	endm



