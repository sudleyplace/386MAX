;' $Header:   P:/PVCS/MAX/INC/VMAXAPI.INV   1.0   05 Sep 1995 13:27:36   HENRY  $
;
; (C) Copyright 1990-3 Qualitas, Inc.  All rights reserved.
;
; VMAXAPI.INC
;
; 386MAX VxD API equates and masks
;

VMAX_GetVer		equ		00h
VMAX_GetSwatVer 	equ		01h
VMAX_GetVMHandle	equ		02h
VMAX_GetSysVMHandle	equ		03h
VMAX_GetVMInfo		equ		04h

VMAX_RegisterCallback	equ		05h
CFG_WARNFLAG		equ		'W'
CFG_FAILFLAG		equ		'F'

VMAX_UnregisterCallback equ		06h
VMAX_IgnoreModeSwitch	equ		07h
VMAX_Terminate		equ		08h
VMAX_GetTimeSliceInfo	equ		09h
VMAX_SetTimeSliceInfo	equ		0Ah

VMStat_Exclusive	equ		01h
VMStat_Background	equ		02h

VMAX_SignalSemaphore	equ		0Bh

