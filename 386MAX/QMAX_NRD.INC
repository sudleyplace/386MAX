;' $Header:   P:/PVCS/MAX/386MAX/QMAX_NRD.INV   1.0   11 Aug 1995 10:55:10   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_NRD.INC
;
; Non-resident data flags
;

@NRD_VER   equ	 80000000h	; DOS Version # found
;;;;_DRV   equ	 40000000h	; Another EMS driver present
@NRD_WTK   equ	 20000000h	; Weitek 1167 present
@NRD_RES   equ	 10000000h	; Program already resident
@NRD_EGA   equ	 08000000h	; EGA present
@NRD_CLR   equ	 04000000h	; Color graphics adapter present (possibly EGA)
@NRD_MDA   equ	 02000000h	; Monochrome adapter present (possibly EGA)
@NRD_MAC   equ	 01000000h	; Pointer to last entry in MAC found
@NRD_EMC87 equ	 00800000h	; CYRIX EMC87 installed
@NRD_BCFERR equ  00400000h	; Error occurred in INIT_MIVT
@NRD_WSF   equ	 00200000h	; EMSFULL displayed
@NRD_1MB   equ	 00100000h	; HPRS 1MB system
@NRD_INC   equ	 00080000h	; Allow auto INCLUDE=
@NRD_PRO   equ	 00040000h	; PRO= being processed
@NRD_E000  equ	 00020000h	; ROM at E000
@NRD_VGA   equ	 00010000h	; VGA present
@NRD_HMA   equ	 00008000h	; HMA initially in use
@NRD_A20   equ	 00004000h	; A20 initially enabled
@NRD_LSEG  equ	 00002000h	; LSEG entry filled in for 386MAX
@NRD_UE000 equ	 00001000h	; E000 segment available for use
@NRD_EISA  equ	 00000800h	; EISA system present
@NRD_ABIOSERR equ 00000400h	; ABIOS init error
@NRD_CPQVGA equ  00000200h	; COMPAQ VGA with bug present
@NRD_A20FN equ	 00000100h	; A20 services present in BIOS
@NRD_VGASWAP equ 00000080h	; VGA SWAP in effect
@NRD_INT2FEQ equ 00000040h	; INT 2Fh vectors equal in RM
@NRD_CPQVGA2 equ 00000020h	; COMPAQ VGA with bug present
@NRD_XBRSPEC equ 00000010h	; XBDAREG specified
@NRD_SRSPEC equ  00000008h	; STACKREG specified
@NRD_CPQBIM equ  00000004h	; CPQ BIM recovered
@NRD_XBIOSHI equ 00000002h	; XBIOSHI (set XBDAREG=PRGREG)
@NRD_STACKHI equ 00000001h	; STACKS /h (set STACKREG=PRGREG)

REG_STR  struc

RSIZE	 dw	 -1		; Size of subsegment in paras
RREG	 dw	 0		; Region for subsegment (default=low)
RMSG	 dw	 ?		; Offset in YGROUP of error message

REG_STR  ends

