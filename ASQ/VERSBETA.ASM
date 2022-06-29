BETAVERSION	equ	002

;' $Header:   P:/PVCS/MAX/ASQ/VERSBETA.ASV   1.1   01 Feb 1996 10:20:40   HENRY  $
;
; (C) Copyright 1992-94 Qualitas, Inc.	All rights reserved.
;
; VERSBETA.ASM
;
; Beta numbering scheme for ASQ
;

	 public  BETA_H, BETA_T, BETA_U
BVER	 equ	 BETAVERSION mod 1000
BETA_H	 equ	'0'+BVER/100
BETA_T	 equ	'0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	'0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

	 end
