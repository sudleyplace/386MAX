;' $Header:   P:/PVCS/MAX/INCLUDE/BIOSCRC.INV   1.0   05 Sep 1995 13:30:18   HENRY  $
;
; (C) Copyright 1991-92 Qualitas, Inc.	All rights reserved.
;
; BIOSCRC.INC
;
; Include file for BIOSCRC.ASM
;

.code

IF @NO_UNDERBAR EQ 1

extrn	_Get_BIOSCRC:proc

ELSE

extrn	Get_BIOSCRC:proc

ENDIF		; @NO_UNDERBAR

