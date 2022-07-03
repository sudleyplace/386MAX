;' $Header:   P:/PVCS/MAX/INC/BIOSCONF.INV   1.1   23 May 1997 16:00:12   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	GNU General Public License version 3.
;
; BIOSCONF.INC
;
; Structure and equates for BIOS configuration table parameters
;

; BIOS configuration table parameters are obtained through INT 15h, AH=0C0h.

.xcref CFG_STR
CFG_STR  struc

CFG_LEN   dw	 ?		; 00:  Length of following configuration table
CFG_MODEL db	 ?		; 02:  System model byte
CFG_TYPE  db	 ?		; 03:  System type byte
CFG_LEVEL db	 ?		; 04:  BIOS revision level
CFG_PARMS db	 ?		; 05:  Parameter bits (see equates below)
CFG_PARM2 db	 ?		; 06:  ... byte #2
CFG_PARM3 db	 ?		; 07:  ... byte #3
CFG_PARM4 db	 ?		; 08:  ... byte #4
CFG_PARM5 db	 ?		; 09:  ... byte #5

CFG_STR  ends

.xcref @CFG_DMA3,@CFG_CASC,@CFG_CLOCK,@CFG_SCAN,@CFG_WAIT,@CFG_XBIOS,@CFG_MCA
@CFG_DMA3  equ	 10000000b	; 80:  Fixed disk BIOS uses DMA channel 3
@CFG_CASC  equ	 01000000b	; 40:  Cascaded interrupt level 2
@CFG_CLOCK equ	 00100000b	; 20:  Real time clock available
@CFG_SCAN  equ	 00010000b	; 10:  Keyboard scan hook fn 4Fh INT 15h supported
@CFG_WAIT  equ	 00001000b	; 08:  Wait for external event supported
@CFG_XBIOS equ	 00000100b	; 04:  Extended BIOS data area allocated
@CFG_MCA   equ	 00000010b	; 02:  Micro Channel implemented
@CFG_DUAL  equ	 00000001b	; 01:  System has dual bus (MCA and ISA)

.xcref @CF2_KEYB
;;;;;;;;;; equ	 10000000b	; 80:  Reserved
@CF2_KEYB  equ	 01000000b	; 40:  INT 16h/AH=09h:	keyboard funtionality supported
@CF2_POS   equ	 00100000b	; 20:  INT 15h/AH=C6h:	get POS data supported
@CF2_MEMMAP equ  00010000b	; 10:  INT 15h/AH=C7h:	get memory map info supported
@CF2_CPUFN equ	 00001000b	; 08:  INT 15h/AH=C8h:	en/disable CPU functions supported
@CF2_X8042 equ	 00000100b	; 04:  Non-8042 keyboard controller
@CF2_STREM equ	 00000010b	; 02:  Data streaming supported
;;;;;;;;;; equ	 00000001b	; 01:  Reserved

;;;;;;;;;; equ	 10000000b	; 80:  Reserved
;;;;;;;;;; equ	 01000000b	; 40:  Reserved
;;;;;;;;;; equ	 00100000b	; 20:  Reserved
@CF3_UNK   equ	 00010000b	; 10:  Set on some 1992 IBM systems
@CF3_SCSI  equ	 00001000b	; 08:  SCSI subsystem supported on system board
@CF3_INFP  equ	 00000100b	; 04:  Information panel installed
@CF3_IML   equ	 00000010b	; 02:  Initial Machine Load system
@CF3_SCSI2 equ	 00000001b	; 01:  SCSI supported in IML

