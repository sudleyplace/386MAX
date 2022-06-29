;' $Header:   P:/PVCS/MAX/QMT/MEM_GL3.INV   1.0   05 Sep 1995 16:56:00   HENRY  $
;
; (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.
;
; MEM_GL3.INC
;
; Record and equates for GL3_FLAG.
;

.xcref GL3_REC
GL3_REC record	\
 $GL3_ERRALL:1, \
 $GL3_DELAY:1,	\
 $GL3_BIOSE820:1,\
 $GL3_BIOSXMEM:1,\
 $GL3_ERRCURB:1,\
 $GL3_ERRMORE:1,\
 $GL3_MEMERR:1, \
 $GL3_PSE:1,	\
 $GL3_VLSI:1,	\
 $GL3_EPM1:1,	\
 $GL3_XPM1:1,	\
 $GL3_BACKVCPI:1,\
 $GL3_A20FN:1,	\
 $GL3_A20SET:1, \
 $GL3_RUNHELP:1,\
 $GL3_CRITERR:1;

@GL3_ERRALL  equ (mask $GL3_ERRALL)	; 8000:  Continue finding all errors
@GL3_DELAY   equ (mask $GL3_DELAY)	; 4000:  In delay
@GL3_BIOSE820 equ (mask $GL3_BIOSE820)	; 2000:  BIOS E820 has extended memory info
@GL3_BIOSXMEM equ (mask $GL3_BIOSXMEM)	; 1000:  BIOS has extended memory info
@GL3_ERRCURB equ (mask $GL3_ERRCURB)	; 0800:  Allocating from current block
@GL3_ERRMORE equ (mask $GL3_ERRMORE)	; 0400:  Continue finding errors
@GL3_MEMERR  equ (mask $GL3_MEMERR)	; 0200:  Displaying memory/NMI error
@GL3_PSE     equ (mask $GL3_PSE)	; 0100:  Use Page Size Extensions
@GL3_VLSI    equ (mask $GL3_VLSI)	; 0080:  VLSI 82C480 L2 cache controller present
@GL3_EPM1    equ (mask $GL3_EPM1)	; 0040:  Perform enter PM actions once
@GL3_XPM1    equ (mask $GL3_XPM1)	; 0020:  Perform exit ...
@GL3_BACKVCPI equ (mask $GL3_BACKVCPI)	; 0010:  386MAX back door VCPI services
@GL3_A20FN equ	 (mask $GL3_A20FN)	; 0008:  A20 Architecture Function supported
@GL3_A20SET equ  (mask $GL3_A20SET)	; 0004:  A20 gating method set
@GL3_RUNHELP equ (mask $GL3_RUNHELP)	; 0002:  Displaying help while running tests
@GL3_CRITERR equ (mask $GL3_CRITERR)	; 0001:  Critical error occurred

; Since we need GL3_FLAG for this macro, this seems an appropriate
; place to define it...
VCPIBACK macro	 FN
	 local	 L1,L2

ifnb <FN>
	 mov	 ax,@VCPI*0100h + FN ; Function code into AL
else
	 mov	 ah,@VCPI	; VCPI major function
endif				; IFNB <FN>

	 test	 GL3_FLAG,@GL3_BACKVCPI ; Using back door VCPI access?
	 jnz	 short L1	; Jump if so

	 int	 67h		; Request VCPI service
	 jmp	 short L2	; Join common code

L1:
	 EMMOUT 		; Use PORT67
L2:
	 endm			; VCPIBACK

