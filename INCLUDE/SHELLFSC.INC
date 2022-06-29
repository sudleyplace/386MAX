;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp., 1988-1990
;
;   Title:	SHELLFSC.Inc - EQUATES related to the File Sys Change stuff
;
;   Version:	1.00
;
;   Date:	19-Sep-1988
;
;   Author:	ARR
;
;------------------------------------------------------------------------------
;
;   Change log:
;
;      DATE	REV		    DESCRIPTION
;   ----------- --- -----------------------------------------------------------
;   19-Sep-1988 ARR Original
;
;==============================================================================

VDA_FileSysChange	EQU	0400H+20+11

;
; On VDA_FileSysChange, wParam is not used
;   Particular VMDOSAPP instance which gets the message is the VM that has
;   changed the file system
;
; NOTE THERE MUST BE A CALL BACK ON THIS EVENT.
;
; The reference data MUST BE A pointer to a structure of the following type:
;
; It is the responsibility of the caller to "FREE" this structure (if needed)
;   on the call back.
;
; Caller can extend this structure if needed by tacking extra info on the end.
;
MAXFSCINFOSIZE		EQU	256

VMDA_FileSysChng  STRUC
VMDA_FSC_Func		dw	?
VMDA_FSC_Buffer 	db	MAXFSCINFOSIZE DUP(?)
VMDA_FileSysChng  ENDS

;
; equates for VMDA_FSC_Func
;
VMDA_FSC_CREATE 	EQU	0
VMDA_FSC_DELETE 	EQU	1
VMDA_FSC_RENAME 	EQU	2
VMDA_FSC_ATTRIBUTES	EQU	3
VMDA_FSC_NETCONNECT	EQU	4
VMDA_FSC_NETDISCONNECT	EQU	5
VMDA_FSC_REFRESH	EQU	6
VMDA_FSC_MKDIR		EQU	7
VMDA_FSC_RMDIR		EQU	8
