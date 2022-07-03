;' $Header:   P:/PVCS/MAX/INC/IOTRAP.INV   1.0   05 Sep 1995 13:27:46   HENRY  $
;
; (C) Copyright 1995 Qualitas, Inc.  GNU General Public License version 3.
;
; IOTRAP.INC
;
; I/O Trapping structures and equates
;

@IOTRAP_API equ  4A15h		; API signature

@IOTRAP_INST equ 0		; Function code to install handler
@IOTRAP_UNIN equ 1		; ...		   uninstall ...
@IOTRAP_CAP  equ 3		; ...		   get driver capabilities

IOTRAP_CAP_REC record \
		 $IOTRAP_CAP_ERRCOD:1, \
		 $IOTRAP_CAP_WIDTH:1,  \
		 $IOTRAP_CAP_DPMI:1

@IOTRAP_CAP_ERRCOD equ (mask $IOTRAP_CAP_ERRCOD) ; 0004:  Error codes returned in AX
@IOTRAP_CAP_WIDTH  equ (mask $IOTRAP_CAP_WIDTH)  ; 0002:  I/O port width in ECX
@IOTRAP_CAP_DPMI   equ (mask $IOTRAP_CAP_DPMI)	 ; 0001:  I/O trapping in DPMI

IOTRAP_REC record $IOTRAP_OUT:1, \
		  $IOTRAP_WID:2

@IOTRAP_OUT equ  (mask $IOTRAP_OUT) ; 0004:  output (must be value 4)
@IOTRAP_WID equ  (mask $IOTRAP_WID) ; 0003:  I/O width (see @IOTRAP_xxx below)
@IOTRAP_DB  equ  0		; Byte I/O
@IOTRAP_DW  equ  1		; Word I/O
@IOTRAP_DD  equ  2		; Dword I/O

@IOTRAP_ERR_BADFN  equ 8000h	; Invalid function
@IOTRAP_ERR_EDX    equ 8001h	; EDX.HI < EDX.LO
@IOTRAP_ERR_CSDS   equ 8002h	; CS <> DS
@IOTRAP_ERR_CX0    equ 8003h	; CX = 0
@IOTRAP_ERR_NOHND  equ 8004h	; Too many I/O handlers
@IOTRAP_ERR_DI_MIN equ 8005h	; DI_WPort < minimum
@IOTRAP_ERR_DI_LO  equ 8006h	; DI_wPort < EDX.LO
@IOTRAP_ERR_DI_HI  equ 8007h	; DI_wPort > EDX.HI
@IOTRAP_ERR_DI_IO  equ 8008h	; DI_wPort in use by I/O handler
@IOTRAP_ERR_DI_MM  equ 8009h	; DI_wPort in use by MM
@IOTRAP_ERR_HNDINV equ 800Ah	; Invalid handle
@IOTRAP_ERR_HNDREM equ 800Bh	; Handle already removed
@IOTRAP_ERR_DI_REM equ 800Ch	; DI_wPort already removed


@IOTRAP_MAX equ  32		; # I/O trapping handlers we support

@IOTRAP_STKSIZ equ 4*1024	; Stack size for I/O trap handler

@IOTRAP_MINIO equ 0		; All I/O ports trapped must be >= this value


DISPATCH_INFO struc

DI_wPORT dw	 ?		; I/O port #
DI_wOFF  dw	 ?		; Offset of I/O handler in caller's CS

DISPATCH_INFO ends


IOTRAP_STR struc

IOTRAP_GDTCS dq  ?		; GDT entry for CS
IOTRAP_GDTDS dq  ?		; ...		DS
IOTRAP_LaTAB dd  ?		; Caller's I/O dispatch table (linear address)
IOTRAP_TABCNT dw ?,?		; ...	   I/O dispatch table length (# entries)
IOTRAP_IO dd	 ?		; ...	   I/O address range

IOTRAP_STR ends


