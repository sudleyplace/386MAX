;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MAP.INV   1.1   12 Oct 1995 12:08:54   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_MAP.INC
;
; Map Memory Structure in MAPTAB
;

MAP_STR struc

MAP_PARA_SRC dw  ?		; Paragraph # (Source)
MAP_PARA_DST dw  ?		; Paragraph # (Destin)
MAP_PAR2 dw	 ?		; Low memory paragraph #
MAP_LEN  dw	 ?		; Length in paragraphs
MAP_TIME dw	 ?		; Access time for 32-bit reads
MAP_FLAG dw	 0		; Flags (see below)

MAP_STR ends

MAP_REC record	$MAP_ROM:1,	\
		$MAP_SWAP:1,	\
		$MAP_BOOT:1,	\
		$MAP_CHOP:1,	\
		$MAP_BCF:1,	\
		$MAP_BIOS:1,	\
		$MAP_CPQVGA:1,	\
		$MAP_CPQVGA2:1, \
		$MAP_RSVD:8

@MAP_ROM    equ  (mask $MAP_ROM)     ; Entry is ROM
@MAP_SWAP   equ  (mask $MAP_SWAP)    ; Entry should be swapped
@MAP_BOOT   equ  (mask $MAP_BOOT)    ; Entry has warm boot location
@MAP_CHOP   equ  (mask $MAP_CHOP)    ; Entry has been chopped by 4KB
@MAP_BCF    equ  (mask $MAP_BCF)     ; Entry is to be compressed
@MAP_BIOS   equ  (mask $MAP_BIOS)    ; Entry is system BIOS
@MAP_CPQVGA equ  (mask $MAP_CPQVGA)  ; Entry is COMPAQ VGA with bug
@MAP_CPQVGA2 equ (mask $MAP_CPQVGA2) ; Entry is COMPAQ VGA with bug

