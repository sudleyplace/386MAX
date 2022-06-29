VERSION  equ	 803
VERSLTR  equ	 <>

;' $Header:   P:/PVCS/MAX/386MAX/VERSRET.ASV   1.5   06 Nov 1996 15:42:26   BOB  $
;
; (C) Copyright 1987-2000 Qualitas, Inc.  All rights reserved.
;
; VERSRET.ASM
;
; 386MAX version number
;

	 public  VER,VERS_H,VERS_T,VERS_U,VERS_HTU
	 public  BINVERS_H,BINVERS_TU
	 public  VERSLTR1,VERSLTR2
VER	 equ	 VERSION mod 1000
VERS_H	 equ	 '0'+VER/100
VERS_T	 equ	 '0'+(VER-(VERS_H-'0')*100)/10
VERS_U	 equ	 '0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	 ((VER/100)*100h)+(VER mod 100)

	 public  VERH, VERL
VERH	 equ	 VER / 100
VERL	 equ	 VER mod 100

BINVERS_H equ	 VER/100
BINVERS_TU equ	 VER-BINVERS_H*100

VERSLTRS catstr  VERSLTR,< Í>
@VERSLTR1 substr VERSLTRS,1,1
@VERSLTR1 catstr <'>,@VERSLTR1,<'>
@VERSLTR2 substr VERSLTRS,2,1
@VERSLTR2 catstr <'>,@VERSLTR2,<'>

VERSLTR1 =	 @VERSLTR1
VERSLTR2 =	 @VERSLTR2

	 end
