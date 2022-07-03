;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SWT.INV   1.0   11 Aug 1995 10:55:44   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_SWT.INC
;
; Macro for calling 386SWAT
;


SWAT	 macro	 DSUME		; Signal INT 01h to call local debugger
	 local	 L1

.errb <DSUME>

	 test	 LCL_FLAG,@LCL_SWAT ; Is 386SWAT loaded?
	 jz	 short L1	; Not this time

;;;;;;;; push	 ds		; Save for a moment
;;;;;;;;
;;;;;;;; push	 DTE_DSHI	; Get selector of data in high DOS memory
;;;;;;;; pop	 ds		; Address it
;;;;;;;; assume  ds:PGROUP	; Tell the assembler about it
;;;;;;;;
;;;;;;;; or	 GLB_FLAG,@GLB_DBG ; Mark as debugging in progress
;;;;;;;;
;;;;;;;; pop	 ds		; Restore
;;;;;;;; assume  ds:DSUME	; Tell the assembler about it
;;;;;;;;
	 int	 01h		; Call the debugger
L1:
	 endm			; SWAT

