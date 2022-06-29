VERSION  equ	 004

;' $Header:   P:/PVCS/MAX/386LOAD/VERSBETA.ASV   1.2   10 Nov 1995 22:47:40   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; VERSBETA.ASM
;
; Beta version number for 386LOAD
;

	 public  BETA_H,BETA_T,BETA_U
VER	 equ	 VERSION mod 1000
BETA_H	 equ	 '0'+VER/100
BETA_T	 equ	 '0'+(VER-(BETA_H-'0')*100)/10
BETA_U	 equ	 '0'+VER-(BETA_H-'0')*100-(BETA_T-'0')*10
	 end

