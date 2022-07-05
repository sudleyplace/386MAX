VERSION  equ	 104
BVERSION  equ	 005

;' $Header:   P:/PVCS/MAX/XLAT/VERSION.ASV   1.1   25 Oct 1995 13:14:08   PETERJ  $
;
; (C) Copyright 1991-93 Qualitas, Inc.	GNU General Public License version 3.
;
; VERSION.ASM
;
; XLAT.COM version number
;

;-------------------

	 public  VER,VERS_H,VERS_T,VERS_U,VERS_HTU
VER	 equ	 VERSION mod 1000
VERS_H	 equ	 '0'+VER/100
VERS_T	 equ	 '0'+(VER-(VERS_H-'0')*100)/10
VERS_U	 equ	 '0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	 ((VER/100)*100h)+(VER mod 100)

;-------------------

	 public  BETA_H,BETA_T,BETA_U
BVER	 equ	 BVERSION mod 1000
BETA_H	 equ	 '0'+BVER/100
BETA_T	 equ	 '0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	 '0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

;-------------------

	 end
