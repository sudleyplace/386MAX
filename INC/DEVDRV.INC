;' $Header:   P:/PVCS/MAX/INC/DEVDRV.INV   1.0   05 Sep 1995 13:27:18   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; DEVDRV.INC
;
; Device driver structures and equates
;


; Device driver attributes -- all other bits must be 0

DRV_ATTR_CHAR equ     8000h	; Character device
DRV_ATTR_IOCTL equ    4000h	; IOCTL supported
DRV_ATTR_NON_IBM equ  2000h	; Non-IBM format		 (BLOCK only)
;		      2000h	  Output until busy		 (CHAR	only)
DRV_ATTR_REMOTE equ   1000h	; Remote vs. local
DRV_ATTR_OCREM equ    0800h	; Open/close/RM supported	 (BLOCK only)
;		      0400h
;		      0200h
;		      0100h
;		      0080h
DRV_ATTR_LOGDEV equ   0040h	; Get/Set logical device
;		      0020h
DRV_ATTR_INT29 equ    0010h	; INT 29h supported		 (CHAR	only)
DRV_ATTR_CLOCK equ    0008h	; Current CLOCK device		 (CHAR	only)
DRV_ATTR_NUL equ      0004h	; Current NUL device		 (CHAR	only)
DRV_ATTR_OUT equ      0002h	; Current STANDARD OUTPUT device (CHAR	only)
DRV_ATTR_HUGE equ     0002h	; Driver supports 32-bit sectors (BLOCK only)
DRV_ATTR_INP equ      0001h	; Current STANDARD INPUT device  (CHAR	only)
;		      0001h	  Supports Generic IOCTL	 (BLOCK only)


STATUS	macro	STATE,ERR,RC
STAT_CODE = 0
	ifidn	<STATE>,<DONE>
STAT_CODE = STAT_CODE or 0100h
	endif
	ifidn	<STATE>,<BUSY>
STAT_CODE = STAT_CODE or 0200h
	endif
	ifidn	<STATE>,<DONEBUSY>
STAT_CODE = STAT_CODE or 0300h
	endif
	ifidn	<ERR>,<ERROR>
STAT_CODE = STAT_CODE or 8000h
	endif
	ifdif	<RC>,<>
STAT_CODE = STAT_CODE or RC
	endif
	or	es:[bx].SRH_STA,STAT_CODE
	endm

;	  E Q U A T E S

; Status error codes

ERR_WRITE_PROTECT equ	00h	; Write-protect violation
ERR_UNK_UNIT	  equ	01h	; Unknown unit
ERR_NOT_READY	  equ	02h	; Device not ready
ERR_UNK_CMD	  equ	03h	; Unknown command
ERR_CRC 	  equ	04h	; CRC error
ERR_REQ_LEN	  equ	05h	; Bad drive request structure length
ERR_SEEK	  equ	06h	; Seek error
ERR_UNK_MED	  equ	07h	; Unknown media
ERR_SECT_NF	  equ	08h	; Sector not found
ERR_POP 	  equ	09h	; Printer out of paper
ERR_WRITE_ERR	  equ	0Ah	; Write fault
ERR_READ_ERR	  equ	0Bh	; Read fault
ERR_UGH 	  equ	0Ch	; General failure


; S T A T I C	R E Q U E S T	H E A D E R

SRH_STR  struc			; Statuc request header

SRH_LEN  db	?		; 00-00:  Length
SRH_UCD  db	?		; 01-01:  Unit code
SRH_CCD  db	?		; 02-02:  Command code
SRH_STA  dw	?		; 03-04:  Status
SRH_RES  db	8 dup (?)	; 05-0C:  Reserved area

SRH_STR  ends


; I N I T

INIT_STR struc

	db	 (size SRH_STR) dup (?) ; 00-0C:  Static request header
INIT_UNITS db	?		; 0D-0D:  # units (block only)
INIT_END_VEC dd  ?		; 0E-11:  Ending address
INIT_BPB_VEC dd  ?		; 12-15:  BPB array pointer & command line address
INIT_DRIV db	?		; 16-16:  For DOS 3.x -- drive # (origin-0)
INIT_ERR dw	?		; 17-18:  For DOS 4.x -- Error message control flag

INIT_STR ends

INIT_CMD_VEC equ INIT_BPB_VEC		 ; Command line


; R E A D / W R I T E

READ_WRITE_STR struc

	db	(size SRH_STR) dup (?) ; Static request header
RW_MD	db	?		; Media descriptor byte
RW_DTA_VEC dd	?		; Disk transfer address
RW_COUNT dw	?		; Byte/sector count
RW_SSN	dw	?		; Starting sector number
RW_VOLID dd	?		; For DOS 3.x -- Seg:Off of ASCIIZ volume ID
RW_HUGE_SSN dd	?		; For DOS 4.x -- if RW_SSN==-1, 32-bit SSN

READ_WRITE_STR ends


DD_STR	struc

DD_NEXT  dd	-1		; Pointer to next device drive in chain
DD_ATTR  dw	?		; Attributes
DD_STRA  dw	?		; Offset of strategy routine
DD_INTR  dw	?		; Offset of interrupt routine
DD_NAME  db	'        '      ; Char device name, block device # units

DD_STR	 ends

