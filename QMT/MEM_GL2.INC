;' $Header:   P:/PVCS/MAX/QMT/MEM_GL2.INV   1.0   05 Sep 1995 16:56:04   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	All rights reserved.
;
; MEM_GL2.INC
;
; Record and equates for GL2_FLAG.
;

.xcref GL2_REC
GL2_REC  record  $GL2_EGA:1,$GL2_MEMOVF:1,$GL2_ADV:1,$GL2_HEX:1, \
		 $GL2_ACTIV:1,$GL2_NOPARITY:1,$GL2_CONT:1,$GL2_HSCR:1, \
		 $GL2_MEMERR:1,$GL2_NMIERR:1,$GL2_DPMI:1,$GL2_VCPI:1, \
		 $GL2_SWAT:1,$GL2_MAX:1,$GL2_LARGER:1,$GL2_SMALLER:1

@GL2_EGA    equ  (mask $GL2_EGA)	; There's an EGA present
@GL2_MEMOVF equ  (mask $GL2_MEMOVF)	; Memory screen overflow
@GL2_ADV    equ  (mask $GL2_ADV)	; Advanced mode
@GL2_HEX    equ  (mask $GL2_HEX)	; Display addresses in hexadecimal
@GL2_ACTIV  equ  (mask $GL2_ACTIV)	; Testing is active
@GL2_NOPARITY equ (mask $GL2_NOPARITY)	; This system doesn't support parity
@GL2_CONT   equ  (mask $GL2_CONT)	; Continuous testing in progress
@GL2_HSCR   equ  (mask $GL2_HSCR)	; Help topic screen is active
@GL2_MEMERR equ  (mask $GL2_MEMERR)	; Memory error has occurred
@GL2_NMIERR equ  (mask $GL2_NMIERR)	; Parity ...
@GL2_DPMI   equ  (mask $GL2_DPMI)	; Using DPMI services to enter PM
@GL2_VCPI   equ  (mask $GL2_VCPI)	; ...	VCPI ...
@GL2_SWAT   equ  (mask $GL2_SWAT)	; SWAT is present via VCPI
@GL2_MAX    equ  (mask $GL2_MAX)	; 386MAX/BlueMAX is present
@GL2_LARGER equ  (mask $GL2_LARGER)	; Use larger of CMOS and BIOS values
@GL2_SMALLER equ (mask $GL2_SMALLER)	; ... smaller ...

