;'$Header:   P:/PVCS/MAX/INC/WFW.INV   1.0   05 Sep 1995 13:27:40   HENRY  $
;
; (C) Copyright 1990-92 Qualitas, Inc.	All rights reserved.
;
; WFW.INC
;
; Definitions for Windows for Workgroups devices
;

VNB_Device_ID		equ	0031h	; WFW Netbind
SERVER_Device_ID	equ	0032h	; WFW Server VM
VNetSup_Device_ID	equ	0480h	; WFW unknown device
VRedir_Device_ID	equ	0481h	; WFW Redirector
VBrowse_Device_ID	equ	0482h	; WFW unknown device
VSHARE_Device_ID	equ	0483h	; WFW unknown device

Begin_Service_Table	SERVER

SERVER_Service	SERVER_Get_Version
SERVER_Service	SERVER_Unknown1
SERVER_Service	SERVER_Get_Server_VM_Handle
SERVER_Service	SERVER_Test_Server_VM_Handle

End_Service_Table	SERVER

Begin_Service_Table	VRedir

SERVER_Service	VRedir_Get_Version

End_Service_Table	VRedir

