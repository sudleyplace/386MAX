BETAVERSION	equ	004

;' $Header:   P:/PVCS/MAX/INSTALL/VERSBETA.ASV   1.3   08 Feb 1996 12:43:14   BOB  $
;
; (C) Copyright 1992-96 Qualitas, Inc.	GNU General Public License version 3.
;
; VERSBETA.ASM
;
; Beta numbering scheme for INSTALL
;

	 public  BETA_H, BETA_T, BETA_U
BVER	 equ	 BETAVERSION mod 1000
BETA_H	 equ	'0'+BVER/100
BETA_T	 equ	'0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	'0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

	 end
