;' $Header:   P:/PVCS/MAX/INC/PCI.INV   1.0   05 Sep 1995 13:27:44   HENRY  $
;
; (C) Copyright 1994 Qualitas, Inc.	All rights reserved.
;
; PCI.INC
;
; Equates for PCI local bus machines
;
; **** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ****
; This information was gotten through unofficial channels and should
; be checked against the spec from Intel.  Delete this message after
; confirming that all functions are correctly defined.
; ******************************************************************

; We may need a first-level scheme to check for machines that can't
; handle an unknown Int 1Ah function.  For now, we'll assume it's
; OK to call the installation check function.

; Function codes are loaded in AX.
; Return from all functions is CF=0 and AH=0 if success; if CF=1,
; AH=error code.
; EAX, EBX, ECX, and EDX may be trashed by calls where their return
; values are not defined.

@PCIERR_BADFN	 equ	 81h	; Invalid function
;;;;;;;_???	 equ	 82h
@PCIERR_BADVID	 equ	 83h	; Invalid vendor ID
;;;;;;;_???	 equ	 84h
;;;;;;;_???	 equ	 85h
@PCIERR_BADDEV	 equ	 86h	; Invalid device ID
@PCIERR_BADREG	 equ	 87h	; Invalid configuration register

PCICALL  macro	 FN
ifnb <FN>
	 mov	 ax,FN		; Get PCI function code
endif
	 int	 1Ah		; Call PCI function dispatch
	 endm			; PCICALL

; PCI v2.0c functions ----------------------------------------------

@PCI_INST	 equ	 0B101h ; PCI support query
; AL=hardware flags, BH,BL=BCD interface version, CL=highest bus number,
; EDX=' ICP', EDI=physical address of PL0 entry point.
@PCISIG 	 equ	 ' ICP'

@PCI_FINDDEV	 equ	 0B102h ; Find PCI device: CX=Device ID, DX=vendor ID,
				; SI=device index (origin:0)
; BL=bus number, BH:7-3=device number, BH:2-0=function number

@PCI_FINDCLASS	 equ	 0B103h ; Find PCI class: 24-bit class code in ECX,
				; SI=device index (origin:0)
; BL=bus number, BH:7-3=device number, BH:2-0=function number

@PCI_UNK1	 equ	 0B104h
@PCI_UNK2	 equ	 0B105h

@PCI_BUSOPS	 equ	 0B106h ; PCI bus-specific operations: BL=bus number,
				; EDX=special cycle data.

@PCI_UNK3	 equ	 0B107h

@PCI_RDBYTE	 equ	 0B108h ; Read PCI configuration byte: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; DI=register number (00h-FFh)
; Returns byte in CL.

@PCI_RDWORD	 equ	 0B109h ; Read PCI configuration word: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; DI=register number (00h-FFh)
; Returns word in CX.

@PCI_RDDWORD	 equ	 0B10Ah ; Read PCI configuration dword: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; DI=register number (00h-FFh)
; Returns dword in ECX.

@PCI_WRBYTE	 equ	 0B10Bh ; Write PCI configuration byte: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; CL=value, DI=register number (00h-FFh)

@PCI_WRWORD	 equ	 0B10Ch ; Write PCI configuration word: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; CX=value, DI=register number (00h-FFh)

@PCI_WRDWORD	 equ	 0B10Dh ; Write PCI configuration dword: BL=bus number,
				; BH:7-3=device number, BH:2-0=function #,
				; ECX=value, DI=register number (00h-FFh)

@PCI_INST32	 equ	 0B181h ; PCI 32-bit support query
; AL=hardware flags, BH,BL=BCD interface version, CL=highest bus number,
; EDX=' ICP', EDI=physical address of PL0 entry point.

; All 32-bit functions are identical to the ones listed above.

@PCI_FINDDEV32	 equ	 0B182h ; Find 32-bit PCI device
@PCI_FINDCLASS32 equ	 0B183h ; Find 32-bit PCI class
@PCI_UNK32A	 equ	 0B184h
@PCI_UNK32B	 equ	 0B185h
@PCI_BUSOPS32	 equ	 0B186h ; PCI 32-bit bus-specific operations
@PCI_UNK32C	 equ	 0B187h
@PCI_RDBYTE32	 equ	 0B188h ; Read PCI_32 configuration byte
@PCI_RDWORD32	 equ	 0B189h ; Read PCI_32 configuration word
@PCI_RDDWORD32	 equ	 0B18Ah ; Read PCI_32 configuration dword
@PCI_WRBYTE32	 equ	 0B18Bh ; Write PCI_32 configuration byte
@PCI_WRWORD32	 equ	 0B18Ch ; Write PCI_32 configuration word
@PCI_WRDWORD32	 equ	 0B18Dh ; Write PCI_32 configuration dword

