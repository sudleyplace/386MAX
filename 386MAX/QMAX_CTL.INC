;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CTL.INV   1.0   11 Aug 1995 10:55:12   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_CTL.INC
;
; Equates for IOCTL calls
;


@CTL_OFF  equ	 01h		; Set state to OFF
@CTL_ON   equ	 02h		; ...	       ON
@CTL_XFER equ	 03h		; Transfer INFO variable
@CTL_OPEN equ	 04h		; Open up high memory
@CTL_EMSOFF equ  05h		; 386LOAD FLEXFRAME in effect; fail all EMS calls
@CTL_EMSON equ	 06h		; Restore Int 67h processing prior to @CTL_EMSOFF

