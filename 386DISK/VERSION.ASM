VERSION  equ	 800

;' $Header:   P:/PVCS/MAX/386DISK/VERSION.ASV   1.1   03 Oct 1995 10:33:52   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; VERSION.ASM
;
; 386DISK version number
;

	 public  VER,VERS_H,VERS_T,VERS_U,VERS_HTU
VER	 equ	 VERSION mod 1000
VERS_H	 equ	 '0'+VER/100
VERS_T	 equ	 '0'+(VER-(VERS_H-'0')*100)/10
VERS_U	 equ	 '0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	 ((VER/100)*100h)+(VER mod 100)
	 end
