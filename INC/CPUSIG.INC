;' $Header:   P:/PVCS/MAX/INC/CPUSIG.INV   1.0   05 Sep 1995 13:27:34   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  GNU General Public License version 3.
;
; CPUSIG.INC
;
; CPU signature bits
;
; The following record maps the CPU signature

.xcref CPUSIG_REC
CPUSIG_REC record $CPUSIG_MEM:4, \
		  $CPUSIG_FAM:4, \
		  $CPUSIG_MOD:4, \
		  $CPUSIG_REV:4

.xcref @CPUSIG_MEM, @CPUSIG_FAM, @CPUSIG_MOD, @CPUSIG_REV
@CPUSIG_MEM equ  mask $CPUSIG_MEM ; Member # (e.g., the 386 uses 2 for 386 SX,
				  ; 4 for 386 SL)
@CPUSIG_FAM equ  mask $CPUSIG_FAM ; Family # (e.g., 3 for 386, 4 for 486, etc.)
@CPUSIG_MOD equ  mask $CPUSIG_MOD ; Model # (e.g., the 486 uses 0 for 25/33
				  ; MHz, 1 for 50 MHz, and 2 for 486/487 SX)
@CPUSIG_REV equ  mask $CPUSIG_REV ; Revision #

