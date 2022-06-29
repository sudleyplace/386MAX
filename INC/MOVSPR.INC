;' $Header:   P:/PVCS/MAX/INC/MOVSPR.INV   1.0   05 Sep 1995 13:27:34   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; MOVSPR.INC
;
; Move to/from special register macro
;
; Use as in   MOVSPR  eax,cr4  for registers which MASM doesn't support.
; Any R32 can be used as well as any special register (CRn, DRn, TRn)
; as either the source or destination.	Requires IOPBITS.INC.
;

MOVSPR	 macro	 DST,SRC	; Move to/from special registers
	 local	 TYP,SPR,R32,OPC,SPN

SPR	 equ	 <DST>		; Assume special register is DST
R32	 catstr  <@>,<SRC>	; Assume R32 is SRC
TYP	 substr  SPR,1,2	; Get 1st and 2nd chars of SPR

% ifidni <TYP>,<CR>		; Check for CRn
OPC	 =	 22h		; Opcode for ...
else
% ifidni <TYP>,<DR>		; Check for DRn
OPC	 =	 23h		; Opcode for ...
else
% ifidni <TYP>,<TR>		; Check for TRn
OPC	 =	 26h		; Opcode for ...
else

SPR	 equ	 <SRC>		; Assume special register is SRC
R32	 catstr  <@>,<DST>	; Assume R32 is DST
TYP	 substr  SPR,1,2	; Get 1st and 2nd chars of SPR

% ifidni <TYP>,<CR>		; Check for CRn
OPC	 =	 20h		; Opcode for ...
else
% ifidni <TYP>,<DR>		; Check for DRn
OPC	 =	 21h		; Opcode for ...
else
% ifidni <TYP>,<TR>		; Check for TRn
OPC	 =	 24h		; Opcode for ...
else
%OUT Invalid register #
.err
endif				; IFIDNI <TYP>,<TR>
endif				; IFIDNI <TYP>,<DR>
endif				; IFIDNI <TYP>,<CR>

endif				; IFIDNI <TYP>,<TR>
endif				; IFIDNI <TYP>,<DR>
endif				; IFIDNI <TYP>,<CR>

SPN	 substr  SPR,3,1	; Get the register number

%	 db	 0Fh,OPC,(11b shl $MOD) or (SPN shl $REG) or (R32 shl $RM)

	 endm			; MOVSPR

