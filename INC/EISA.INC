;' $Header:   P:/PVCS/MAX/INC/EISA.INV   1.0   05 Sep 1995 13:26:56   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; EISA.INC
;
; Equates for EISA machines
;


; EISA System Board Product Identifier Ports

EISA_SysID_Port1	equ	0C80h	; System ID bytes
EISA_SysID_Port2	equ	0C81h	; System ID bytes
EISA_SysID_Port3	equ	0C82h	; Product number
EISA_SysID_Port4	equ	0C83h	; Revision number

; EISA Function calls (parameters to INT 15h)

ReadEISASlotInfo	equ	0D800h	; Read slot configuration information
ReadEISAFuncInfo	equ	0D801h	; Read function ...
ClearEISANonvolMem	equ	0D802h	; Clear Nonvolatile Memory
WriteEISANonvolMem	equ	0D803h	; Write ...


; Configuration Data Block Structure

EISA_STR struc

EISA_PRODUCT_ID db	 4 DUP (?)	; Four byte compressed ID
EISA_INFO	db	 2 DUP (?)	; ID and Slot Information
EISA_CFG_REV	db	 2 DUP (?)	; CFG File extension Revision Level
EISA_SELECTIONS db	26 DUP (?)	; Selections
EISA_FUNC_INFO	db	 ?		; Function Information (see record below)
EISA_TYPESTRING db	80 DUP (?)	; TYPE and SUBTYPE ASCII string
EISA_MEMCONFIG	db	63 DUP (?)	; Memory Configuration (see struc below)
EISA_INTCONFIG	db	14 DUP (?)	; Interrupt configuration
EISA_DMACONFIG	db	 8 DUP (?)	; DMA Channel Description
EISA_IOCONFIG	db	60 DUP (?)	; Port I/O Config
EISA_INITDATA	db	60 DUP (?)	; Initialization Data

EISA_STR ends


; Record definition for EISA_STR.EISA_FUNC_INFO above

EISAFNC record	$EISAFNC_DISABLE:1,$EISAFNC_RES:1,$EISAFNC_PORTINIT:1,\
		$EISAFNC_PORTRANGE:1,$EISAFNC_DMA:1,$EISAFNC_IRQ:1,\
		$EISAFNC_MEM:1,$EISAFNC_TYPE:1


; EISA Memory Configuration structure for EISA_STR.EISA_MEMCONFIG above

EISAMEM_STR struc

MEM_CONFIG	db	?	; Memory configuration byte (see record below)
MEM_DATASIZE	db	?	; Memory data size (see record below)
MEM_START_LSB	db	?	; LSByte memory start address (/100h)
MEM_START_MID	db	?	; Middle byte memory start address
MEM_START_MSB	db	?	; MSByte memory start address
MEM_LEN 	dw	?	; Memory size (/400h) (0 means 64MB)

EISAMEM_STR ends


; Record definition for EISAMEM_STR.MEM_CONFIG above

EISAMEM record	$EISAMEM_CONT:1,$EISAMEM_RES1:1,$EISAMEM_SHARE:1,\
		$EISAMEM_MEMTYPE:2,$EISAMEM_RES2:1,$EISAMEM_CACHE:1,\
		$EISAMEM_RAM:1


; Equates for $EISAMEM_MEMTYPE above

@EISAMEM_SYS equ  00b		; SYS (base or extended)
@EISAMEM_EXP equ  01b		; EXP (expanded)
@EISAMEM_VIR equ  10b		; VIRtual
@EISAMEM_OTH equ  11b		; OTHer


; Record definition for EISAMEM_STR.MEM_DATASIZE above

EISADATA record  $EISADATA_RES:6,$EISADATA_SIZE:2


; Equates for $EISADATA_SIZE above

@EISADATA_BYTE	equ 00b 	; Bytes
@EISADATA_WORD	equ 01b 	; Word
@EISADATA_DWORD equ 10b 	; Dword
;;;;;;;;;;;;;;; equ 11b 	; (Reserved)

