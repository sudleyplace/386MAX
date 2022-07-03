;' $Header:   P:/PVCS/MAX/INC/I11.INV   1.0   05 Sep 1995 13:26:50   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; I11.INC
;
; Equipment flags
;

.xcref I11_REC,$I11_PRN,$I11_RSV1,$I11_COM,$I11_RSV2,$I11_DISK,$I11_IVM
.xcref $I11_RSV3,$I11_NDP,$I11_IPL
I11_REC  record  $I11_PRN:2,$I11_RSV1:2,$I11_COM:3,$I11_RSV2:1,$I11_DISK:2,\
		 $I11_IVM:2,$I11_RSV3:2,$I11_NDP:1,$I11_IPL:1

; $I11_PRN:2  = C000 = # parallel ports attached (origin-0)
; $I11_RSV1:2 = 3000 = (reserved)
; $I11_COM:3  = 0E00 = # serial ...
; $I11_RSV1:1 = 0100 = (reserved)
; $I11_DISK:2 = 00C0 = # diskette drives attached (origin-1)
; $I11_IVM:2  = 0030 = initial video mode (00=unused, 01=CO40, 10=CO80, 11=Mono)
; $I11_RSV3:2 = 000C = (reserved)
; $I11_NDP:1  = 0002 = # math coprocessors installed (origin-0)
; $I11_IPL:1  = 0001 = Any diskette drivers installed

.xcref @I11_CO40,@I11_CO80,@I11_MONO
@I11_CO40 equ	 01b
@I11_CO80 equ	 10b
@I11_MONO equ	 11b

