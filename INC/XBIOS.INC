;' $Header:   P:/PVCS/MAX/INC/XBIOS.INV   1.0   05 Sep 1995 13:27:02   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; XBIOS.INC
;
; Segment for Extended BIOS Data Area
;

if (@Cpu and 1000b)		; If 80386 instructions
XBIOS	 segment use16 at 0	; Start XBIOS segment
else
XBIOS	 segment at 0		; Start XBIOS segment
endif				; IF (@Cpu AND 1000b)

XBIOS_SIZE db	 ?		; Size of extended BIOS data area in KB

XBIOS	 ends			; End XBIOS segment

