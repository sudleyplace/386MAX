VERSION  equ	 119

;' $Header:   P:/PVCS/MAX/MEMLIMIT/VERSION.ASV   1.1   25 Oct 1995 13:12:36   PETERJ  $
;
; (C) Copyright 1991-93 Qualitas, Inc.	All rights reserved.
;
; VERSION.ASM
;
; MEMLIMIT.EXE version number
;

	 public  VER,VERS_H,VERS_T,VERS_U,VERS_HTU
VER	 equ	 VERSION mod 1000
VERS_H	 equ	 '0'+VER/100
VERS_T	 equ	 '0'+(VER-(VERS_H-'0')*100)/10
VERS_U	 equ	 '0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	 ((VER/100)*100h)+(VER mod 100)

	 end
