;' $Header:   P:/PVCS/MAX/386MAX/QMAXDPMI.INV   1.0   11 Aug 1995 10:55:50   HENRY  $
;
; (C) Copyright 1991-5 Qualitas, Inc.  GNU General Public License version 3.
;
; QMAXDPMI.INC
;
; Structures and equates for DPMI support
;

; Host private data area

HPDA_STR struc

HPDA_SIGN db	 'HPDA'         ; 00-03:  Signature of HPDA
HPDA_ENVSEG dw	 ?		; 04-05:  Segment of environment
HPDA_PCURTSS dd  ?		; 06-09:  Offset in PGROUP of corresponding TSS
HPDA_pCS dw	 ?		; 0A-0B:  Code selector
HPDA_pDS dw	 ?		; 0C-0D:  Data ...
HPDA_pES dw	 ?		; 0E-0F:  PSP ...
HPDA_pSS dw	 ?		; 10-11:  Stack ...
HPDA_vDS dw	 ?		; 12-13:  DS segment upon entry
HPDA_vES dw	 ?		; 14-15:  ES ...
HPDA_vFS dw	 ?		; 16-17:  FS ...
HPDA_vGS dw	 ?		; 18-19:  GS ...
HPDA_SIMRET db	 0CDh,0FFh	; 1A-1B:  Simulated INT return address
HPDA_RMSRET db	 0CDh,0FFh	; 1C-1D:  Raw Mode Switch ...
HPDA_REFRET db	 0CDh,0FFh	; 1E-1F:  Reflected Interrupt ...
HPDA_INT21 db	 0CDh,021h	; 20-21:  DOS call entry address
HPDA_SSR   db	 0CBh		; 22   :  State Save/restore return address
HPDA_MEI db	 0CDh,0FFh,0CBh ; 23-25:  Mouse Event Interrupt address
HPDA_PDBI db	 0CDh,0FFh,0CBh ; 26-28:  Mouse Event Interrupt address

; The following two labels *MUST* be contiguous as the first one may be
; replaced by NOPs so we can jump to the previous Terminate address.

; Default terminate (INT 22h) handler
HPDA_I22DEF db	  50h		; 29   :  PUSH AX
	 db	 0B4h, 4Dh	; 2A-2B:  MOV  AH,4Dh
	 db	 0CDh, 21h	; 2C-2D:  INT  21h
	 db	 0CDh,0FFh	; 2E-2F:  INT 0FFh
HPDA_I22DEF2 db  0EAh		; 30   :  JMPF to previous handler
HPDA_I22VEC dd	 ?		; 31-34:  Previous Terminate address

; The following two labels *MUST* be contiguous as the first one may be
; replaced by NOPs so we can jump to the previous Ctrl-Break address.

HPDA_I23DEF db	 0CDh,0FFh	; 35-36:  Default Ctrl-Break (INT 23h) handler
HPDA_I23DEF2 db  0EAh		; 37   :  JMPF to previous handler
HPDA_I23VEC dd	 ?		; 38-3B:  Previous Ctrl-Break address
HPDA_I23CLC db	 0F8h,0CBh	; 3C-3D:  CLC/RETF
HPDA_I23STC db	 0F9h,0CBh	; 3E-3F:  STC/RETF

; The following two labels *MUST* be contiguous as the first one may be
; replaced by NOPs so we can jump to the previous Critical Error address.

HPDA_I24DEF db	 0CDh,0FFh	; 40-41:  Default Critical Error (INT 24h) handler
HPDA_I24DEF2 db  0EAh		; 42   :  JMPF to previous handler
HPDA_I24VEC dd	 ?		; 43-46:  Previous Critical Error address
HPDA_I24IRET db  0CFh		; 47   :  IRET

if (($-HPDA_SIGN) mod 4)
	 db	 (4-(($-HPDA_SIGN) mod 4)) dup (?) ; For dword alignment
endif				; IF (($-HPDA_SIGN) MOD 4)

; Note:  the size of the HPDA should be a multiple of four for
; better performance when accessing the buffer and stack

; Other data areas are allocated dynamically at this point

HPDA_STR ends


HPDAVMC_STR struc		; VM callback structure

HPDAVMC_INTFF db 4 dup (?)	; 00-03:  Room for INT FF (if the first byte is
				;	  CC, the entry is available) followed
				;	  by RETF, NOP
HPDAVMC_VMSS  dw ?		; 04-05:  VM stack selector
HPDAVMC_CALLFVEC df ?		; 06-0B:  PM procedure to call
HPDAVMC_REGFVEC df ?		; 0C-11:  PM register data struc

HPDAVMC_STR ends


; DPMI equates

@NLDTE_RSV equ	  16		; # reserved specific LDT selectors
@NLDTE_MIN    equ @NLDTE_RSV+16 ; Minimum # LDT entries
@NLDTE_DEF    equ @NLDTE_RSV+600 ; Default ...

ifdef DTE_DATALDT
.errnz DTE_DATALDT lt (@NLDTE_RSV*(type DESC_STR))
endif				; IFDEF DTE_DATALDT

@HPDASTK_MIN equ 1024		; Minimum size of HPDA stack in bytes
@HPDASTK_DEF equ 2048		; Default ...

@HPDABUF_MIN equ 512		; Minimum size of HPDA buffer in bytes
@HPDABUF_DEF equ 4096		; Default ...

@HPDAVMC_MIN equ 16		; Minimum # VM callback addresses
@HPDAVMC_DEF equ 32		; Default ...

@DPMIHNDL_MIN equ 1		; Minimum # DPMI memory handles
@DPMIHNDL_DEF equ 32		; Default ...

@DPMIPDIR_MIN equ 1		; Minimum # DPMI page directories
@DPMIPDIR_DEF equ 1		; Default ...

@DPMI_BOUNDLOG2 equ 12		; Log base 2 of @DPMI_BOUND (4KB)
@DPMI_BOUND equ  (1 shl @DPMI_BOUNDLOG2) ; DPMI memory allocation boundary unit
				; and multiplier
@DPMIDYN_MIN  equ @DPMI_BOUND	; Minimum size of dynamic save area
@DPMIDYN_DEF  equ @DPMI_BOUND	; Default ...

@HPDAFRM_SIZ equ @HPDASTK_MIN/2 ; Size of HPDA interrupt frame in bytes
@LPMSTK_DEF  equ  4096		; Default size of PL3 locked protected mode stack

COMMENT|

The maximum size of the dynamic elements in the HPDA is
calculated such that they don't overflow FFF0 in the HPDA segment.

The minimum size of the HPDA buffer is the largest of the
following static needs:

* 512 byte minimum for string display (DOS function 09h)
* (size CDI_STR) (DOS function 38h)
* 128 bytes for buffered keyboard input (DOS function 0Ah)
* (size XFCB_STR) (DOS FCB functions)
* 80 bytes (DOS file functions using ASCIIZ file name)

|

