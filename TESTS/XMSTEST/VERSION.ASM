VERSION  equ	 222

;' $Header:   P:/PVCS/MISC/XMSTEST/VERSION.ASV   1.4   22 Feb 1994 12:47:40   HENRY  $

	 public  VER,VERS_H,VERS_T,VERS_U,VERS_HTU
VER	 equ	 VERSION mod 1000
VERS_H	 equ	 '0'+(VER/100) mod 10
VERS_T	 equ	 '0'+(VER-(VERS_H-'0')*100)/10
VERS_U	 equ	 '0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	 ((VER/100)*100h)+(VER mod 100)
	 end
