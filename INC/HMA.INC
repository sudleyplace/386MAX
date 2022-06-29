;' $Header:   P:/PVCS/MAX/INC/HMA.INV   1.0   05 Sep 1995 13:26:52   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; HMA.INC
;
; High Memory Area segment
;

if (@Cpu and 1000b)		; If 80386 instructions
HMASEG	 segment use16 at 0FFFFh ; Start HMASEG segment
else
HMASEG	 segment at 0FFFFh	; Start HMASEG segment
endif				; IF (@Cpu AND 1000b)

	 org	 0010h
HMASTART label	 byte

HMASEG	 ends			; End HMASEG segment

