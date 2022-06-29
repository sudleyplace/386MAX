;' $Header:   P:/PVCS/MAX/INC/INTVEC.INV   1.0   05 Sep 1995 13:27:14   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; INTVEC.INC
;
; Interrupt vectors segment
;

.xcref INTVEC,INT00_VEC

if (@Cpu and 1000b)		; If 80386 instructions
INTVEC	 segment use16 at 0000h ; Interrupt vectors
else
INTVEC	 segment at 0000h	; Interrupt vectors
endif				; IF (@Cpu AND 1000b)

	 org	 00h
INT00_VEC dd	 ?		; Offset & segment of INT 00h

INTVEC	 ends

