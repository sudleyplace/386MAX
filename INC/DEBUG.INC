;' $Header:   P:/PVCS/MAX/INC/DEBUG.INV   1.0   05 Sep 1995 13:27:00   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DEBUG.INC
;
; DEBUG macro
;

DEBUG	 macro	 TXT
	 local	 L1,L2

	 jmp	 short L2
L1	 db	 TXT,CR,LF,EOS
L2:
	 REGSAVE <ax,dx,ds>	; Save registers

	 pushf			; Save flags

	 push	 cs
	 pop	 ds
	 DOSCALL @STROUT,L1

	 popf			; Restore

	 REGREST <ds,dx,ax>	; Restore

	 endm			; DEBUG

