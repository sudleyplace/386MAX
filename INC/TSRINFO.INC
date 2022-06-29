;' $Header:   P:/PVCS/MAX/INC/TSRINFO.INV   1.0   31 Jan 1996 12:31:52   BOB  $
;
; (C) Copyright 1995-6 Qualitas, Inc.  All rights reserved.
;
; TSRINFO.INC
;
; TSR Info structure used by Windows via INT 2Fh/160Bh
;

TSR_Info_Struc struc

TSR_Next	dd	?		; 00:  Seg:Off of next struc
TSR_PSP_Segment dw	?		; 04:  Segment of PSP
TSR_API_Ver_ID	dw	0100h		; 06:  API version #
TSR_Exec_Flags	dw	0		; 08:  Flags:  see TSR_xxx below
TSR_Exec_Cmd_Show dw	0		; 0A:  SW_xxxx for TSR_Exec_Cmd (if non-zero)
TSR_Exec_Cmd	dd	0		; 0C:  Seg:Off of command to WinExec (0=none)
TSR_Reserved	dd	0		; 10:  Reserved
TSR_ID_Block	dd	0		; 14:  Seg:Off of ID block (see TSR_IDB below)
TSR_Data_Block	dd	0		; 18:  Seg:Off of data block (or 0)

TSR_Info_Struc ends

@TSR_WINEXEC	equ	0001b		; WinExec the program
@TSR_LOADLIB	equ	0010b		; LoadLibrary ...
@TSR_OPENDRVR	equ	0100b		; OpenDriver ...


TSR_IDB struc				; TSR ID Block

TSR_IDB_Len	dw	?		; Length of name string in bytes
TSR_IDB_Name	db	?		; First byte of name string

TSR_IDB ends

