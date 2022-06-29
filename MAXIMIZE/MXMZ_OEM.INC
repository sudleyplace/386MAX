;' $Header:   P:/PVCS/MAX/MAXIMIZE/MXMZ_OEM.INV   1.0   05 Sep 1995 16:33:42   HENRY  $
;
; (C) Copyright 1991-92 Qualitas, Inc.	All rights reserved.
;
; MXMZ_OEM.INC
;
; MAXIMIZE include file for adding OEM-specific equates
;

@OEM_FLEX	 equ 1	; 1 = Supports FLEXFRAME
if (ASYS ne MOVEM)
@OEM_HARPO	 equ 1	; 1 = Supports subsegments
else
@OEM_HARPO	 equ 0	; Doesn't support subsegments
endif			; IF (ASYS ne MOVE)

