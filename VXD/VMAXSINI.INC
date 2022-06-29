;' $Header:   P:/PVCS/MAX/VXD/VMAXSINI.INV   1.0   05 Sep 1995 17:20:50   HENRY  $
;
; (C) Copyright 1990-93 Qualitas, Inc.	All rights reserved.
;
; VMAXSINI.INC
;
; This include file is used to automatically keep the help screen up-to-date
;

SYSINI_STRINGS macro	VXDNAME, OPTION

ifidni <OPTION>, <DEFINE>
SYSINI_DUALDISPLAY	db	'&VXDNAME', 'DualDisplay', 0
SYSINI_DEBUG		db	'&VXDNAME', 'Debug', 0
SYSINI_NOISE		db	'&VXDNAME', 'Noise', 0

SYSINI_SYSCRITINIT	db	'&VXDNAME', 'SysCriticalInit', 0
SYSINI_DEVICEINIT	db	'&VXDNAME', 'DeviceInit', 0
SYSINI_INITCOMPLETE	db	'&VXDNAME', 'InitComplete', 0
SYSINI_SYSVMINIT	db	'&VXDNAME', 'SysVMInit', 0
SYSINI_CREATEVM 	db	'&VXDNAME', 'CreateVM', 0
SYSINI_SYSEXIT		db	'&VXDNAME', 'SystemExit', 0
SYSINI_SYSCRITEXIT	db	'&VXDNAME', 'SysCriticalExit', 0

ifidni <VXDNAME>, <386MAX>
SYSINI_INT0E		db	'&VXDNAME', 'Int0E', 0
SYSINI_API1684		db	'&VXDNAME', 'API1684', 0
SYSINI_AUTOINST 	db	'&VXDNAME', 'AutoInstance', 0
endif
else
ifidni <OPTION>, <LIST>
			db	80h, '&VXDNAME', 'DualDisplay', 0
			db	80h, '&VXDNAME', 'Debug', 0
			db	80h, '&VXDNAME', 'Noise', 0

			db	80h, '&VXDNAME', 'SysCriticalInit', 0
			db	80h, '&VXDNAME', 'DeviceInit', 0
			db	80h, '&VXDNAME', 'InitComplete', 0
			db	80h, '&VXDNAME', 'SysVMInit', 0
			db	80h, '&VXDNAME', 'CreateVM', 0
			db	80h, '&VXDNAME', 'SystemExit', 0
			db	80h, '&VXDNAME', 'SysCriticalExit', 0

ifidni <VXDNAME>, <386MAX>
			db	80h, '&VXDNAME', 'Int0E', 0
			db	80h, '&VXDNAME', 'API1684', 0
			db	80h, '&VXDNAME', 'AutoInstance', 0
endif
else
.ERR
%OUT Incorrect use of SYSINI_STRINGS macro
endif
endif
	 endm			; End of SYSINI_STRINGS macro
