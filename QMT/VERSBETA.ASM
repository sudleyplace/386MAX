BETAVERSION	equ	003

;' $Header:   P:/PVCS/MAX/QMT/VERSBETA.ASV   1.2   21 Feb 1996 09:36:52   BOB  $
;
; (C) Copyright 1992-4 Qualitas, Inc.  GNU General Public License version 3.
;
; VERSBETA.ASM
;
; Beta numbering scheme for RAMEXAM / QMT
;

	 public  BETA_H, BETA_T, BETA_U
BVER	 equ	 BETAVERSION mod 1000
BETA_H	 equ	'0'+BVER/100
BETA_T	 equ	'0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	'0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

	 end
