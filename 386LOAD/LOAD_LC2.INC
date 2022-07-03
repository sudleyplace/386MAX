;' $Header:   P:/PVCS/MAX/386LOAD/LOAD_LC2.INV   1.0   05 Sep 1995 14:47:44   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; LOAD_LC2.INC
;
; Equates for LC2_FLAG
;

@LC2_JMAC    equ 8000h		; Low and high MACs joined
@LC2_XUSEF   equ 4000h		; INT 67h called during initialization
@LC2_EXE     equ 2000h		; FIND_FILE has found an .EXE file
@LC2_XHILOAD equ 1000h		; Forced not to be loaded high
@LC2_ZMAC    equ 0800h		; Special ending MAC entry
@LC2_COMSTK  equ 0400h		; C = treat as COM file for stack determination
@LC2_FHCOPY  equ 0200h		; File handles copied
@LC2_I12     equ 0100h		; Use top of DOS trick
@LC2_IGNFLEX equ 0080h		; IGNOREFLEXFRAME in effect
@LC2_XMAX    equ 0040h		; 386MAX not present - loading low
@LC2_ENDLOAD equ 0020h		; Program loads at high end with PSP at low end
@LC2_LINK58  equ 0010h		; High DOS arena linked via 5801h

