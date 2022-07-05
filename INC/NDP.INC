;' $Header:   P:/PVCS/MAX/INC/NDP.INV   1.0   05 Sep 1995 13:27:30   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; NDP.INC
;
; Numeric data processor equates
;

.xcref NDPCW,NDPSW
NDPCW	 record  $R4:3,$IC:1,$RC:2,$PC:2,$IEM:1,$R5:1,$PM:1,$UM:1,$OM:1,$ZM:1,$DM:1,$IM:1
;;;;;	 record  $XRSV0:3,$INF:1,$RC:2,$PC:2,$IEM:1,\
;;;;;		 $XRSV1:1,$XMPRC:1,$XMUNF:1,$XMOVF:1,$XMZDV:1,$XMDOP:1,$XMIOP:1
NDPSW	 record  $BUSY:1,$C3:1,$ST0:1,$ST1:1,$ST2:1,$C2:1,$C1:1,$C0:1,$IR:1, \
		 $XRSV2:1,$XFPRC:1,$XFUNF:1,$XFOVF:1,$XFZDV:1,$XFDOP:1,$XFIOP:1

; Use the following equates on the control word (FNSTCW target) as a mask
; and comparison to ensure it's a 287 or 387.  To test for 8087, include
; (mask $IC) in @CWVALID.

.xcref @CWMASK,@CWVALID
@CWVALID equ	 (mask $PM) or (mask $UM) or (mask $OM) or (mask $ZM) or (mask $DM) or (mask $IM)
@CWMASK  equ	 (mask $IC) or @CWVALID

