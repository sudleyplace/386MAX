;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SYS.INV   1.0   11 Aug 1995 10:55:40   HENRY  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_SYS.INC
;
; System flags for SYS_FLAG
;

@SYS_JET386  equ 80000000h	; JET386
@SYS_CPQ     equ 40000000h	; COMPAQ Deskpro 386
@SYS_HPRS    equ 20000000h	; HP Vectra RS/16 or /20
@SYS_INBRD   equ 10000000h	; Either Inboard/AT or /PC
@SYS_INBRDAT equ 08000000h	; Inboard/AT
@SYS_INBRDPC equ 04000000h	; Inboard/PC
@SYS_AST386  equ 02000000h	; AST Premium 386
@SYS_GRID    equ 01000000h	; GRiD Systems
@SYS_QUAD386 equ 00800000h	; Quadram 386XT
@SYS_OLI     equ 00400000h	; Olivetti/AT&T
@SYS_TOSH    equ 00200000h	; Toshiba 5100
@SYS_ITT     equ 00100000h	; ITT XTRA
@SYS_CA      equ 00080000h	; CompuAdd
@SYS_DELL    equ 00040000h	; Dell Systems 310/325/...
@SYS_HPCACHE equ 00020000h	; HP RS20C or 25C with cache controller
@SYS_NEC     equ 00010000h	; NEC System
@SYS_ASEM    equ 00008000h	; ASEM
@SYS_ZDS     equ 00004000h	; Zenith (all systems)
@SYS_EPSON   equ 00002000h	; Epson
@SYS_AMSTRAD equ 00001000h	; AMSTRAD PC 3386 SX
@SYS_MCAXABIOS equ 00000800h	; MCA system with no ABIOS (POS invalid)
@SYS_PCIBIOS equ 00000400h	; PCI local bus BIOS machine

