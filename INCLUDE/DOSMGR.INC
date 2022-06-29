;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp., 1988-1990
;
;   Title:	DOSMGR.Inc - Public services for DOSMGR
;
;   Version:	1.00
;
;   Date:	29-Nov-88
;
;   Author:	ARR
;
;------------------------------------------------------------------------------
;
;   Change log:
;
;      DATE	REV		    DESCRIPTION
;   ----------- --- -----------------------------------------------------------
;   29-Nov-1988 ARR Original
;
;==============================================================================

Begin_Service_Table DOSMGR

DOSMGR_Service	DOSMGR_Get_Version, LOCAL
DOSMGR_Service	_DOSMGR_Set_Exec_VM_Data, LOCAL
DOSMGR_Service	DOSMGR_Copy_VM_Drive_State, LOCAL
DOSMGR_Service	_DOSMGR_Exec_VM, LOCAL
DOSMGR_Service	DOSMGR_Get_IndosPtr, LOCAL
DOSMGR_Service	DOSMGR_Add_Device
DOSMGR_Service	DOSMGR_Remove_Device
DOSMGR_Service	DOSMGR_Instance_Device
DOSMGR_Service	DOSMGR_Get_DOS_Crit_Status, LOCAL
DOSMGR_Service	DOSMGR_Enable_Indos_Polling, LOCAL
;
; End of 3.00 table
;
DOSMGR_Service	DOSMGR_BackFill_Allowed, LOCAL
DOSMGR_Service	DOSMGR_LocalGlobalReg, LOCAL

End_Service_Table DOSMGR
