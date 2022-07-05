;' $Header:   P:/PVCS/MAX/386MAX/QMAX_BCF.INV   1.0   11 Aug 1995 10:55:14   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_BCF.INC
;
; BCF header and command cell structures
;

@BCFSKIP equ	-1		; Special flag to avoid duplicate MIVT fixups

; Used to determine how and the type of test done on an interrupt

BCFINT_STR struc

BCFINT_FIND dd	 ?		; Action routine to find it
BCFINT_VEC  dd	 ?		; Pointer to original interrupt vector
BCFLIN_ADR  dd	 @BCFSKIP	; 32 bit linear address of MIVT fixup

BCFINT_STR ends

; Record and equates for FIX_FLAG

FIX_REC record $FIX1:1,$FIX0:1

; BCF header structure

BCFH_STR struc

BCFH_FCRC dw	 ?		; CRC of the BCF file (before encryption)
BCFH_BCRC dw	 ?		; ...	     target BIOS
BCFH_SIZE dw	 ?		; Size of header in bytes
BCFH_NAME db	 80 dup (?)	; Name of target BIOS
BCFH_BOFF dw	 ?		; Starting offset in bytes in new BIOS
BCFH_VERS dw	 ?		; BCF file version #
BCFH_REV  dw	 ?		; Revision # of this BIOS's BCF
BCFH_NCELL dw	 ?		; # command cells

BCFH_STR ends

@BCF_CRYPT    equ 8000h 	; Encryption flag on in BCFH_REV
@BCF_CRYPTOFF equ 1729h 	; Encryption/decryption offset in F000

;
; BCF command cell structure (version 0)
;

BCF_CSTR struc

BCF_CMD  db	 ?		; Command cell (see @BCF_xxxx equates below)
	 db	 0		; Reserved
BCF_OFF  dw	 ?		; Offset
BCF_DATA dw	 ?		; Command dependent data

BCF_CSTR ends

;
; BCF move multiple command structures (version 1)
;

BCF_MMCSTR struc

BCF_MMC  db	 ?		; Move multiple command
BCF_MML  dw	 ?		; Number of BCF_MMA elements that follow

BCF_MMCSTR ends

BCF_MMDSTR struc

BCF_MOF  dw	 ?		; Offset of move multiple data
BCF_MLN  dw	 ?		; Length of move data

BCF_MMDSTR ends

;
; Add multiple fixup structures (version 1)
;

BCF_AMBSTR struc

	 db	 ?		; Command cell code
BCF_AMBN db	 ?		; Number of entries to follow
BCF_AMBV db	 ?		; Value to use for fixup

BCF_AMBSTR ends

BCF_AMWSTR struc

	 db	 ?		; Command cell code
BCF_AMWN db	 ?		; Number of entries to follow
BCF_AMWV dw	 ?		; Value to use for fixup

BCF_AMWSTR ends

;
; BCF MIVTx structure
;
BCF_ISTR struc

BCF_ICMD  db	 ?		; Command cell (see @BCF_xxxx equates below)
	  db	 0		; Reserved
BCF_I0OFF dw	 ?		; Offset into segment 0
BCF_ICNT  dw	 ?		; # replacements

BCF_ICOFF dw	 ?		; Compressed offset into F000 <==\  Repeated
BCF_IUVEC dd	 ?		; Uncompressed offset	      <==/  BCF_ICNT times

BCF_ISTR ends

;
; BCF command cell equates
;
@BCF_EMOV  equ	 01h		; Move from E000
@BCF_FMOV  equ	 02h		; ...	    F000
@BCF_ADDW  equ	 03h		; Add word
@BCF_ADDB  equ	 04h		; ... byte
@BCF_MIVT1 equ	 05h		; Modify interrupt vector table, type 1
@BCF_MIVT2 equ	 06h		; ...				      2
@BCF_EMOVB equ	 @BCF_EMOV+@BIT4 ; Move BASIC from E000
@BCF_FMOVB equ	 @BCF_FMOV+@BIT4 ; ...		   F000
@BCF_EMVM  equ	 07h		; Move multiple from E000
@BCF_FMVM  equ	 08h		; Move multiple from F000
@BCF_ADMW  equ	 09h		; Add word multiple
@BCF_ADMB  equ	 0Ah		; Add byte multiple
