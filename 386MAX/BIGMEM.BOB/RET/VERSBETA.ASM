VERSION  equ	 004

;' $Header:   P:/PVCS/MAX/386MAX/VERSBETA.ASV   1.30   08 Oct 1996 13:46:24   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	GNU General Public License version 3.
;
; VERSBETA.ASM
;
; Beta numbering scheme for 386MAX
;

	 public  BETA_H,BETA_T,BETA_U
VER	 equ	 VERSION mod 1000
BETA_H	 equ	 '0'+VER/100
BETA_T	 equ	 '0'+(VER-(BETA_H-'0')*100)/10
BETA_U	 equ	 '0'+VER-(BETA_H-'0')*100-(BETA_T-'0')*10
	 end
