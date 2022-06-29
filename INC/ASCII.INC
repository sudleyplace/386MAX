;' $Header:   P:/PVCS/MAX/INC/ASCII.INV   1.0   05 Sep 1995 13:27:02   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; ASCII.INC
;
; Equates for ASCII characters
;

.xcref BRK,BEL,BS,TAB,CR,LF,EOF,ESCAPE,EOS
BRK	 equ	 03h		; Break as an extended code
BEL	 equ	 07h		; Bell
BS	 equ	 08h		; Backspace
TAB	 equ	 09h		; Tab
CR	 equ	 0Dh		; Carriage return
LF	 equ	 0Ah		; Linefeed
EOF	 equ	 1Ah		; End-of-file
ESCAPE	 equ	 1Bh		; Escape
EOS	 equ	 '$'            ; End of string

