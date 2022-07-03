;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CFG.INV   1.0   11 Aug 1995 10:55:38   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  GNU General Public License version 3.
;
; QMAX_CFG.INC
;
; Equates for 386LOAD.CFG file in memory
;

DSTK_REC record  $DSTK_GLBOFF:1,$DSTK_LCLOFF:1

; $DSTK_GLBOFF = 1 if globally disabled (via 386UTIL STACKS=OFF)
;		   This can be changed via 386UTIL STACKS=ON only
; $DSTK_LCLOFF = 1 if locally disabled (via INT21_EXEC)
;		   This can be changed via another call to INT21_EXEC.

LFLG_STR struc

LFLG_NEXT dd	 ?	; Offset in PGROUP of next field (-1=none)
LFLG_FNAM dd	 ?	; Offset in PGROUP of corresponding filename

LFLG_STR ends

; Define a structure for list of 386LOAD.CFG flag lists.
; We initialize LFLG_DAT here since MASM 5.1 can't handle nested structures.

LLST_STR struc

LLST_LTR db	 ?	; 386LOAD.CFG letter
LLST_NUM db	 0	; Binary value of number qualifier to letter
			; (e.g., U1), 0 if none
LLST_ACT dw	 ?	; Offset of action routine in PGROUP
LLST_DAT db	 (size LFLG_STR) dup (-1) ; LFLG_STR

LLST_STR ends

