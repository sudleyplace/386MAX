BVERSION  equ	 006

;' $Header:   P:/PVCS/MAX/ROMSRCH/VERSION.ASV   1.7   30 Jan 1996 16:23:20   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; VERSION.ASM
;
; ROMSRCH beta version number
;

	 public  BETA_H,BETA_T,BETA_U
BVER	 equ	 BVERSION mod 1000
BETA_H	 equ	 '0'+BVER/100
BETA_T	 equ	 '0'+(BVER-(BETA_H-'0')*100)/10
BETA_U	 equ	 '0'+BVER-(BETA_H-'0')*100-(BETA_T-'0')*10

;-------------------

	 end
