;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I31.INV   1.0   11 Aug 1995 10:55:36   HENRY  $
;
; (C) Copyright 1991-3 Qualitas, Inc.  GNU General Public License version 3.
;
; QMAX_I31.INC
;
; Structures and equates for INT 31h support
;

I31_STR  struc			; Registers saved below SS:EBP
				; at start of INT 31h entry
I31_ES	 dw	 ?		; Caller's ES
I31_DS	 dw	 ?		; ...	   DS

I31_STR  ends

@I31BACK equ	 (type I31_STR) ; Amount to step back from EBP
				; to address I31_STR

DPMIHNDL_STR struc		; DPMI memory handle structure

DPMIHNDL_LEN dd  ?		; Length in bytes of the corresponding handle
				; if this value is zero, the corresponding
				; handle is free
DPMIHNDL_LA  dd  ?		; Linear address of the memory block
DPMIHNDL_SEL dw  ?		; Owning LDT selector
DPMIHNDL_TSS dw  ?		; Owning TSS selector

DPMIHNDL_STR ends


; DPMITYPE and DPMITYPEIG equates

@DPMITYPE16 equ  00h		; 16-bit client active
@DPMITYPE32 equ  01h		; 32-...
@DPMITYPEXX equ  02h		; No DPMI clients active

@PMxDEF_LEN equ  2		; # bytes in each PMIDEFxx and PMFDEFxx entry
				; 2:  INT @PMx_INT
@xxTJMP_LEN equ  5		; # bytes in each INTJMPxx and FLTJMPxx entry
				; 5:  JMP xxxx:xxxx
@PMI_INT equ	 <FD>		; Interrupt for PM Interrupts
@PMF_INT equ	 <FC>		; Interrupt for PM Faults
@PMM_INT equ	 <FB>		; Interrupt for PM Miscellaneous Returns (RSP, VPF, VMC, etc.)


; PMINTCOM equates

@PMINTCOM_LPM equ 1		; Use LPM stack for this interrupt
@PMINTCOM_NRM equ 0		; Use application stack ...


; Equates for forced new selector debugging

@NEWSEL_EDQLO equ 00000001h	; Low-order dword
@NEWSEL_EDQHI equ 00000000h	; High-...


; DPM_FLAG record

DPM_REC  record  $DPM_DPMI:1, \
		 $DPM_DPMIERR:1, \
		 $DPM_DPMISEL:1, \
		 $DPM_DPMISTD:1, \
		 $DPM_DPMIXCOPY:1, \
		 $DPM_DPMISPURNT:1, \
		 $DPM_DPMINEWSEL:1, \
		 $DPM_DPMITERM:1, \
		 $DPM_DPMILOCK:1, \
		 $DPM_DPMIV100:1, \
		 $DPM_NOVCPI:1

; $DPM_DPMI:	    Signal INT 01h on DPMI calls
; $DPM_DPMIERR:     Signal INT 01h on DPMI errors
; $DPM_DPMISEL:     Signal INT 01h on LAST_DPMI_xS errors
; $DPM_DPMISTD:     Force KRNL386 to come up in standard mode
; $DPM_DPMIXCOPY:   Don't check DPMI copyright notices
; $DPM_DPMISPURNT:  Signal INT 01h on spurious NT task switches
; $DPM_DPMINEWSEL:  Force new selector on all allocates
; $DPM_DPMITERM:    Signal INT 01h if we free resources upon termination
; $DPM_DPMILOCK:    Check for InDOS when paging
; $DPM_DPMIV100:    Force DPMI version 1.00 even if Rational Systems-based app
; $DPM_NOVCPI:	    Lie about presence of VCPI services to close the back door


; I31_FLAG record

I31_REC  record  $I31_ZPD:1, \
		 $I31_DUSE:1, \
		 $I31_WIN3:1, \
		 $I31_KRNL:1, \
		 $I31_XMEI:1, \
		 $I31_L15:1,  \
		 $I31_VER090:1, \
		 $I31_RSI:1, \
		 $I31_NOSWAP:1, \
		 $I31_EXIT:1, \
		 $I31_FAULT:1, \
		 $I31_NOSWITCH:1, \
		 $I31_RETCALL:1

; Update the following equate whenever any per DPMI client attribute is added.

@I31_PERCLIENT equ (mask $I31_ZPD)	  or \
		   (mask $I31_DUSE)	  or \
		   (mask $I31_WIN3)	  or \
		   (mask $I31_KRNL)	  or \
		   (mask $I31_XMEI)	  or \
		   (mask $I31_L15)	  or \
		   (mask $I31_VER090)	  or \
		   (mask $I31_RSI)	  or \
		   (mask $I31_NOSWAP)

; Update the following equate whenever any per DPMI exit attribute is added.

@I31_PEREXIT   equ (mask $I31_EXIT)	  or \
		   (mask $I31_FAULT)	  or \
		   (mask $I31_NOSWITCH)   or \
		   (mask $I31_RETCALL)

; $I31_ZPD:	    Zero out demand pages when they are touched
; $I31_DUSE:	    Enforce descriptor usage rules
; $I31_WIN3:	    Windows 3.00 DPMI client
; $I31_KRNL:	    Windows DPMI client
; $I31_XMEI:	    Don't allow MEIs in DOS with swapping
; $I31_L15:	    Limit lockable page count to 15MB
; $I31_VER090:	    Lie about the DPMI version # (say it's 0.90)
; $I31_RSI:	    This is a Rational Systems-based application
; $I31_NOSWAP:	    Skip swapfile for this DPMI client
; $I31_EXIT:	    Coming from EXITRC task switch
; $I31_FAULT:	    Terminating because of a fault
; $I31_NOSWITCH:    Do not switch stacks on termination
; $I31_RETCALL:     Return to caller upon termination, not AH=4C/INT 21

@I31_ZPD      equ (mask $I31_ZPD)
@I31_DUSE     equ (mask $I31_DUSE)
@I31_WIN3     equ (mask $I31_WIN3)
@I31_KRNL     equ (mask $I31_KRNL)
@I31_XMEI     equ (mask $I31_XMEI)
@I31_L15      equ (mask $I31_L15)
@I31_VER090   equ (mask $I31_VER090)
@I31_RSI      equ (mask $I31_RSI)
@I31_NOSWAP   equ (mask $I31_NOSWAP)
@I31_EXIT     equ (mask $I31_EXIT)
@I31_FAULT    equ (mask $I31_FAULT)
@I31_NOSWITCH equ (mask $I31_NOSWITCH)
@I31_RETCALL  equ (mask $I31_RETCALL)

@HEX	 equ	 <0123456789ABCDEF> ; Binary to hex translate table


IF16ZX	 macro	 REG,GRP	; If this is a 16-bit client, MOVZX the REG
	 local	 L1		; GRP = "IG" or blank

	 cmp	 DPMITYPE&GRP,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short L1	; Jump if not

	 movzx	 e&REG,REG	; Zero to use as dword
L1:
	 endm			; IF16ZX


; Equates for DOSFN_SEG2SEL

@CODESEL equ	 0		; Marker for code selector
@DATASEL equ	 1		; ...	     data

; Equates for VSAPI calls

@VSAPI_MSDOS  equ 0		; Caller is for MS-DOS
@VSAPI_386MAX equ 1		; ...		386MAX

; Equates for INT23_TYP

@INT23_IGNORE equ 0		; Client terminated via IRET/D
@INT23_ABORT  equ 1		; ...			RETF/D with CF=1
@INT23_REFLVM equ 2		; ...			JMPF/CALLF

; Equate for LPM stack filler pattern

@LPMSTKFILL equ 'STAC'          ; Filler pattern for LPM stack


