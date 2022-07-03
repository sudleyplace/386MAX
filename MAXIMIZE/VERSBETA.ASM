BETAVERSION	equ	010

;' $Header:   P:/PVCS/MAX/MAXIMIZE/VERSBETA.ASV   1.7   23 Jan 1996 14:57:02   HENRY  $
;
; (C) Copyright 1992-6 Qualitas, Inc.  GNU General Public License version 3.
;
; VERSBETA.ASM
;
; Beta numbering scheme for MAXIMIZE
;

	 public  BETA_H, BETA_T, BETA_U
BVER	 equ	 BETAVERSION mod 1000
BETA_H	 equ	'0'+BVER/100
BETA_T	 equ	'0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	'0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

	 end
