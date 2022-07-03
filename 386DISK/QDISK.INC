;' $Header:   P:/PVCS/MAX/386DISK/QDISK.INV   1.0   05 Sep 1995 13:14:06   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QDISK.INC
;
; Master include file for 386DISK
;

; M A C R O S

	 if1
STATUS	 macro	 STATE,ERR,RC
STAT_CODE = 0
	 ifidn	 <STATE>,<DONE>
STAT_CODE = STAT_CODE or 0100h
	 endif
	 ifidn	 <STATE>,<BUSY>
STAT_CODE = STAT_CODE or 0200h
	 endif
	 ifidn	 <ERR>,<ERROR>
STAT_CODE = STAT_CODE or 8000h
	 endif
	 ifnb	 <RC>
STAT_CODE = STAT_CODE or RC
	 endif
	 or	 es:[bx].SRH_STA,STAT_CODE
	 endm

SET_DS	 macro	 P

	 push	 cs			; Move CS
	 pop	 ds			; ...to DS for addressibility

	 ifidn	 <P>,<TELL>
	 assume  ds:PGROUP		; Tell the assembler about it
	 endif
	 endm

SET_ES	 macro				; Move CS to ES for addressibility

	 push	 cs
	 pop	 es

	 endm

J	 macro	 COND,LAB		; Jump out of range to label LAB
	 local	 L
	 jn&COND L			;; Jump on negative condition
	 jmp	 LAB
L:
	 endm

JN	 macro	 COND,LAB		; Jump out of range to label LAB
	 local	 L
	 j&COND  L			;; Jump on negative condition
	 jmp	 LAB
L:
	 endm

	 endif				; End IF1
;  M E D I A   D E S C R I P T O R   B Y T E S

MD_DS	 equ	 00000001b		; Double sided
MD_8SEC  equ	 00000010b		; 8 sectors/side
MD_REM	 equ	 00000100b		; Removable
MD_	 equ	 11111000b		; Remaining bits MUST be set to 1

MD_FD	 equ	 MD_			; Fixed disk
MD_SS9	 equ	 MD_+MD_REM		; Single-sided 9 sectors/track
MD_DS9	 equ	 MD_+MD_REM+MD_DS	; Double-sided 9 sectors/track
MD_SS8	 equ	 MD_+MD_REM+MD_8SEC	; Single-sided 8 sectors/track
MD_DS8	 equ	 MD_+MD_REM+MD_8SEC+MD_DS ; Double-sided 8 sectors/track

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
	 page
; S T A T I C	R E Q U E S T	H E A D E R

SRH_STR  struc

SRH_LEN  db				; Static requ header length field
SRH_UCD  db				;   "      "    "    unit code field
SRH_CCD  db				;   "      "    "    command code field
SRH_STA  dw				;   "      "    "    status field
SRH_RES  db	 8 dup (?)		;   "      "    "    reserved area field

SRH_STR  ends

; I N I T

INIT_STR struc

	 db	 (size SRH_STR) dup (?) ; Static request header
INIT_UNITS db				; # units
INIT_END_OFF dw 			; Ending address -- offset
INIT_END_SEG dw 			;   "       "    -- segment
INIT_BPB_OFF dw 			; BPB array pointer -- offset
INIT_BPB_SEG dw 			;  "    "      "    -- segment
INIT_DRIV db				; DOS 3.00 only -- drive # (origin-0)

INIT_STR ends

; Disk parameters for discontiguous disk

QDISK_PARM_STR struc

NSEC	 dw				; # sectors in this section    - fixed
SEG1	 dw				; Segment of this section      - fixed
LEN	 dw				; # bytes to read/write
OFF	 dw	 0			; Offset within this section (always 0)
SSEG	 dw				; Starting segment within this section

QDISK_PARM_STR ends
QDISK_PARM_LEN equ type QDISK_PARM_STR	; Length of disk parm area

BPS	 equ	 512			; # bytes per sector

