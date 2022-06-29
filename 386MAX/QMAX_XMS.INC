;' $Header:   P:/PVCS/MAX/386MAX/QMAX_XMS.INV   1.0   11 Aug 1995 10:55:36   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; QMAX_XMS.INC
;
; XMS_REC record
;

; Try to avoid changing the meanings of old bits:  insert new
; symbols at the top instead of the bottom of this record.

XMS_REC  record  $XMS_AVAIL:7, \
		 $XMS_NOXMSUMB:1, \
		 $XMS_LCKPHYS:1, \
		 $XMS_E2X:1,  \
		 $XMS_OLD:1,  \
		 $XMS_LON:1,  \
		 $XMS_XHMA:1, \
		 $XMS_I15:1,  \
		 $XMS_VDISK:1,\
		 $XMS_A20:1

;				  $XMS_NOXMSUMB= Deny XMS UMB requests
;				  $XMS_LCKPHYS = Return physical addr on lock
;				  $XMS_E2X   = EMS-to-XMS memory appended
;				  $XMS_OLD   = XMS driver already installed
;				  $XMS_LON   = 386LOAD state is on
;				  $XMS_XHMA  = HMA permanently unavailable
;				  $XMS_I15   = XMSINT15 installed
;				  $XMS_VDISK = VDISK installed
;				  $XMS_A20   = A20 enabled globally

; Record for XMSBMAP

XMSB_REC record  $XMSB_FLOW:1,	\
		 $XMSB_ALLOC:1, \
		 $XMSB_BOUND:1

; Note that $XMSB_ALLOC must be one bit below $XMSB_FLOW
; so we can test for overflow and underflow

@XMSB_FLOW4  equ (mask $XMSB_FLOW)  * 01010101h ; Four byte overflow/underflow test
@XMSB_ALLOC4 equ (mask $XMSB_ALLOC) * 01010101h ; Four byte allocation marker

@XMSB_FLOW   equ (mask $XMSB_FLOW)  ; Test this bit for overflow/underflow
@XMSB_ALLOC  equ (mask $XMSB_ALLOC) ; Memory at this address is allocated.
@XMSB_BOUND  equ (mask $XMSB_BOUND) ; Physical boundary discontiguity between
				; this address and the next one.


