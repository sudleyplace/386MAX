;'$Header:   P:/PVCS/MAX/VXD/VMAX_MSG.ASV   1.6   09 Nov 1995 13:36:32   PETERJ  $
	 title	 VMAX_MSG -- Message Text for 386MAX.VXD and DOSMAX.386
	 page	 78,130
	 name	 VMAX_MSG

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-95 Qualitas, Inc.  All rights reserved.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'

	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'

	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

COMMENT|

	 Each error message that a user will ever see has been assigned an
	 error code.   The format of the error code is V####.  The 'V'
	 indicates that this code is associated with a VxD error message.
	 The first digit indicates the message group of the message:
		 1 = Real Mode Init
		 2 = Protected Mode Init
		 3 = Protected Mode post-Init
	 The last three digits are reserved for the unique sequence number
	 within each message group.

	 Messages defined in this file are grouped by message group, and
	 ordered according to their order of appearance in each source file.

|

.386p
.xlist
	 include VMM.INC		; Fixed version of file from DDK

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ASCII.INC

	 include VMAX.INC
	 include QMAX_OEM.INC

	 include VERSION.INC
.list
;******************************************************************************
;
;			R E A L    M O D E    I N I T
;
;******************************************************************************

VxD_REAL_INIT_SEG		; Begin _RCODE segment
	 assume  es:nothing	; Tell the assembler

; VMAX_RMI.ASM messages

	 public MSG_PAK
ifdef LANG_GR
MSG_PAK 	db     '    ', @OEM_TEXT, ' VxD nicht geladen.', CR, LF
		db     '    Windows-Initialisierung beendet; mit beliebiger Taste zum DOS...'
		db     CR, LF, EOS
else
MSG_PAK 	db     '    ', @OEM_TEXT, ' VxD Not Loaded.', CR, LF
		db     '    Windows initialization terminated.  Press any key to return to DOS...'
		db     CR, LF, EOS
endif				; IFDEF LANG_GR


	 public MSG_CRLF
MSG_CRLF	db	CR, LF, EOS


ifdef @DEBUG
	 public  MSG_IMPORT_OPEN
ifdef LANG_GR
MSG_IMPORT_OPEN  db	@OEM_TEXT, ' VxD Error V1001: kann EMMXXXX0 nicht îffnen', CR, LF, EOS
else
MSG_IMPORT_OPEN  db	@OEM_TEXT, ' VxD Error V1001: Can not open EMMXXXX0', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_IOCTL1
ifdef LANG_GR
MSG_IMPORT_IOCTL1 db	@OEM_TEXT, ' VxD Error V1002: Get device info IOCTL call fÅr EMMXXXX0 fehlgeschlagen ', CR, LF, EOS
else
MSG_IMPORT_IOCTL1 db	@OEM_TEXT, ' VxD Error V1002: Get device info IOCTL call for EMMXXXX0 failed', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_NOTCHR
ifdef LANG_GR
MSG_IMPORT_NOTCHR db	@OEM_TEXT, ' VxD Error V1003: EMMXXXX0 ist kein Character-Device', CR, LF, EOS
else
MSG_IMPORT_NOTCHR db	@OEM_TEXT, ' VxD Error V1003: EMMXXXX0 not a character device', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_IOCTL2
ifdef LANG_GR
MSG_IMPORT_IOCTL2 db	@OEM_TEXT, ' VxD Fehler V1004: Get Paging Import IOCTL Aufruf fehlgeschlagen', CR, LF, EOS
else
MSG_IMPORT_IOCTL2 db	@OEM_TEXT, ' VxD Error V1004: Get Paging Import IOCTL call failed', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_IOCTL3
ifdef LANG_GR
MSG_IMPORT_IOCTL3 db	@OEM_TEXT, ' VxD Error V1005: Paging Import IOCTL-LÑnge ist falsch', CR, LF, EOS
else
MSG_IMPORT_IOCTL3 db	@OEM_TEXT, ' VxD Error V1005: Paging Import IOCTL length is wrong', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_IOCTL4
ifdef LANG_GR
MSG_IMPORT_IOCTL4 db	@OEM_TEXT, ' VxD Error V1006: Paging Import IOCTL-Adresse ist NULL', CR, LF, EOS
else
MSG_IMPORT_IOCTL4 db	@OEM_TEXT, ' VxD Error V1006: Paging Import IOCTL address is NULL', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_INFO
MSG_IMPORT_INFO  db	'    WIN386 Paging Import version '

	 public  MSG_IMPORT_INFO0
MSG_IMPORT_INFO0 db	'd.'            ; Major version #

	 public  MSG_IMPORT_INFO1
MSG_IMPORT_INFO1 db	'dd, @ '        ; Minor version #s

	 public  MSG_IMPORT_INFO2
ifdef LANG_GR
MSG_IMPORT_INFO2 db	'xxxxxxxx (physikalisch)', CR, LF, EOS
else
MSG_IMPORT_INFO2 db	'xxxxxxxx (Physical)', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public  MSG_IMPORT_NULL
ifdef LANG_GR
MSG_IMPORT_NULL  db	'    WIN386 Paging Import nicht verfÅgbar (EMS=0)', CR, LF, EOS
else
MSG_IMPORT_NULL  db	'    WIN386 Paging Import is unavailable (EMS=0)', CR, LF, EOS
endif				; IFDEF LANG_GR
endif				; IFDEF @DEBUG


	 public MSG_GETREF
ifdef LANG_GR
MSG_GETREF	db	@OEM_TEXT, ' VxD Error V1007: kann die Referenz-Daten nicht ',CR,LF
		db	'    vom Extended Memory kopieren'
else
MSG_GETREF	db	@OEM_TEXT, ' VxD Error V1007: Can''t Copy Reference Data From Extended Memory'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_PUTREF
ifdef LANG_GR
MSG_PUTREF	db	@OEM_TEXT, ' VxD Error V1008: kann die Referenz-Daten nicht ',CR,LF
		db	'    von Extended Memory kopieren'
else
MSG_PUTREF	db	@OEM_TEXT, ' VxD Error V1008: Can''t Copy Reference Data To Extended Memory'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_PAKORESC
ifdef LANG_GR
MSG_PAKORESC	db	'    weiter mit beliebiger Taste, (ESC zum Beenden)...', EOS
else
MSG_PAKORESC	db	'    Press any key to continue (ESC to quit)...', EOS
endif				; IFDEF LANG_GR


	 public MSG_16M_NONSUP
ifdef LANG_GR
MSG_16M_NONSUP	db	@OEM_TEXT, ' VxD Error V1009: physikalischer Speicher oberhalb von 16 MB wird nicht',CR,LF
		db	'    von Windows 3.0 unterstÅtzt.'
else
MSG_16M_NONSUP	db	@OEM_TEXT, ' VxD Error V1009: Physical memory above 16 MB not supported by Windows 3.0.'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_16M_NOXRAM
ifdef LANG_GR
MSG_16M_NOXRAM	db	'    fÅgen Sie die NOXRAM-Option in Ihre ', @OEM_FILE, '.PRO-Datei ein ',CR,LF
		db	'    und starten Sie neu.'
else
MSG_16M_NOXRAM	db	'    Add the NOXRAM keyword to your ', @OEM_FILE, '.PRO file and reboot.'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_16M_REDUCE
ifdef LANG_GR
MSG_16M_REDUCE	db	'    verkleinern Sie Ihren Speicher auf 16 MB und starten Sie neu!'
else
MSG_16M_REDUCE	db	'    Reduce memory to less than 16 MB and reboot.'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_SMART_BOV
ifdef LANG_GR
MSG_SMART_BOV	db	@OEM_TEXT, ' VxD Error V1010: unverstÑndliches "set BUSMASTER=', CR,LF
else
MSG_SMART_BOV	db	@OEM_TEXT, ' VxD Error V1010: Unrecognized "set BUSMASTER=', EOS
endif				; IFDEF LANG_GR
		db	CR, LF, EOS

; Need MSG_SMART_OVER here

	 public MSG_SMART_SNS
ifdef LANG_GR
MSG_SMART_SNS	db	@OEM_TEXT, ' VxD Error V1011: Busmaster-Disk-Subsystem entdeckt, das Laden von ', CR, LF
		db	'    QCache oder anderem passenden Disk-Cache erfordert.'
else
MSG_SMART_SNS	db	@OEM_TEXT, ' VxD Error V1011: Busmaster Disk Subsystem detected that requires', CR, LF
		db	'    QCache or other compliant disk cache to be loaded.'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_SMART_SWD
ifdef LANG_GR
MSG_SMART_SWD	db	'    Siehe README-Datei unter "Busmaster-Einheiten"'
else
MSG_SMART_SWD	db	'    See README file section on "Busmastering Devices"'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_EMSDC_BOV
ifdef LANG_GR
MSG_EMSDC_BOV	db	@OEM_TEXT, ' VxD Error V1012: unverstÑndliche "set EMSCACHE=', EOS
else
MSG_EMSDC_BOV	db	@OEM_TEXT, ' VxD Error V1012: Unrecognized "set EMSCACHE=', EOS
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_INT67, MSG_INT67_H
ifdef LANG_GR
MSG_INT67	db	@OEM_TEXT, ' VxD Error V1013: eine nicht-EMS INT 67h Funktion ('
MSG_INT67_H	db	'xxxxh) wurde wÑhrend Datei-I/O verwendet'
else
MSG_INT67	db	@OEM_TEXT, ' VxD Error V1013: Non-EMS INT 67h Function ('
MSG_INT67_H	db	'xxxxh) Used During File I/O'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_EMSDC
ifdef LANG_GR
MSG_EMSDC	db	@OEM_TEXT, ' VxD Error V1014: Disk-Cache- oder anderes Datei-I/O- ',CR,LF
		db	'    Programm belegt den EMS-Speicher.'
else
MSG_EMSDC	db	@OEM_TEXT, ' VxD Error V1014: Disk Cache or Other File I/O Software Using EMS Memory'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	public	MSG_NOKRNL
ifdef LANG_GR
MSG_NOKRNL	db	@OEM_TEXT, ' VxD Error V1015: kann KRNL386.EXE nicht îffnen.'
else
MSG_NOKRNL	db	@OEM_TEXT, ' VxD Error V1015: Can''t open KRNL386.EXE'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_CHKENV_BOV
ifdef LANG_GR
MSG_CHKENV_BOV	db	'"-Option'
else
MSG_CHKENV_BOV	db	'" Option'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_PSWD
ifdef LANG_GR
MSG_PSWD	db	'    Siehe in der README-Datei'
else
MSG_PSWD	db	'    Please see README'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_DUP_DEVICE
ifdef LANG_GR
MSG_DUP_DEVICE	db	@OEM_TEXT, ' VxD Error V1016: Duplikat-Einheit'
else
MSG_DUP_DEVICE	db	@OEM_TEXT, ' VxD Error V1016: Duplicate Device'
endif				; IFDEF LANG_GR
		db	CR, LF, EOS


	 public MSG_NOMAX
ifdef LANG_GR
MSG_NOMAX	db	@OEM_TEXT, ' VxD Error V1019: ', @OEM_FILE, '.SYS nicht installiert', CR, LF, EOS
else
MSG_NOMAX	db	@OEM_TEXT, ' VxD Error V1019: ', @OEM_FILE, '.SYS Not Installed', CR, LF, EOS
endif				; IFDEF LANG_GR


	 public MSG_BADVER
ifdef LANG_GR
MSG_BADVER	db	@OEM_TEXT, ' VxD Error V1020: ', @OEM_FILE, '.SYS Version pa·t nicht', CR, LF, EOS
else
MSG_BADVER	db	@OEM_TEXT, ' VxD Error V1020: ', @OEM_FILE, '.SYS Version Mismatch', CR, LF, EOS
endif				; IFDEF LANG_GR

ifdef @DOSMAX
	 public MSG_NOSTACKS
ifdef LANG_GR
MSG_NOSTACKS	db	@OEM_TEXT, ' VxD Fehler V1021: ', @OEM_TEXT, ' Stacks erforderlich fÅr DOSMAX UnterstÅtzung', CR, LF
		db	'Entfernen Sie STACKS=0 aus der Datei ', @OEM_TEXT, '.PRO.', CR, LF, EOS
else
MSG_NOSTACKS	db	@OEM_TEXT, ' VxD Error V1021: ', @OEM_TEXT, ' Stacks Required for DOSMAX Support', CR, LF
		db	'Remove STACKS=0 from the ', @OEM_FILE, '.PRO file.', CR, LF, EOS
endif				; IFDEF LANG_GR
endif				; IFDEF @DOSMAX

; VMAX_UPD.ASM messages

ifdef @DEBUG
	 public MSG_UPD_VER
	 public MSG_UPD_VER0, MSG_UPD_VER1
ifdef LANG_GR
MSG_UPD_VER	db     '    Update fÅr Ñltere 386MAX'
		db     ', Referenzdaten-Strukturversion '
else
MSG_UPD_VER	db     '    Updating older 386MAX'
		db     ', reference data structure version '
endif				; IFDEF LANG_GR
MSG_UPD_VER0	db     'x.'
MSG_UPD_VER1	db     'xx'
		db     CR, LF, EOS
endif				; IFDEF @DEBUG

VxD_REAL_INIT_ENDS		; End _RCODE segment
	 page
;******************************************************************************
;
;		    P R O T E C T E D	 M O D E    I N I T
;
;******************************************************************************

VxD_IDATA_SEG			; Begin _IDATA segment

; VMAX.ASM messages

	 public MSG_SCI
MSG_SCI 	db	'--> ', @OEM_TEXT, ' Sys_Critical_Init'
		db	' -- Version ', VERS_H, '.', VERS_T, VERS_U
		db	'.', BETA_H, BETA_T, BETA_U
		db	CR, LF, 0


	 public MSG_REF_PTL_UGH
MSG_REF_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2001: PhysToLinear of Reference Data Failed', CR, LF, 0


	 public MSG_CR3_PTL_UGH
MSG_CR3_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2002: PhysToLinear of CR3 Failed', CR, LF, 0


	 public MSG_1ST_PTL_UGH
MSG_1ST_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2003: PhysToLinear of PDE Failed', CR, LF, 0


	 public MSG_GDPA_UGH
ifdef LANG_GR
MSG_GDPA_UGH	db '    ', @OEM_TEXT, ' VxD Error V2004: GetDeviceV86PagesArray fehlgeschlagen', CR, LF, 0
else
MSG_GDPA_UGH	db '    ', @OEM_TEXT, ' VxD Error V2004: GetDeviceV86PagesArray Failed', CR, LF, 0
endif				; IFDEF LANG_GR


	 public MSG_MPTL_UGH
MSG_MPTL_UGH	db '    ', @OEM_TEXT, ' VxD Error V2005: MapPhysToLinear of Type 1 Instance Items Failed', CR, LF, 0


ifdef @VGASWAP
	 public MSG_FLX_PTL_UGH
MSG_FLX_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2006: PhysToLinear of VGASWAP Data Failed', CR, LF, 0
endif				; IFDEF @VGASWAP


	 public MSG_VS_UGH
ifdef LANG_GR
MSG_VS_UGH	db '    ', @OEM_TEXT, ' VxD Error V2007: VGA ROM Swap fehlgeschlagen', CR, LF, 0
else
MSG_VS_UGH	db '    ', @OEM_TEXT, ' VxD Error V2007: VGA ROM Swap Failed', CR, LF, 0
endif				; IFDEF LANG_GR


	 public MSG_ROMSCAN_UGH
ifdef LANG_GR
MSG_ROMSCAN_UGH db '    ', @OEM_TEXT, ' VxD Error V2008A: ROM Scan, Assign und Map fehlgeschlagen', CR, LF, 0
else
MSG_ROMSCAN_UGH db '    ', @OEM_TEXT, ' VxD Error V2008A: ROM Scan, Assign, and Map Failed', CR, LF, 0
endif				; IFDEF LANG_GR


	 public MSG_RAMSCAN_UGH
ifdef LANG_GR
MSG_RAMSCAN_UGH db '    ', @OEM_TEXT, ' VxD Error V2008B: RAM Scan, Assign und Map fehlgeschlagen', CR, LF, 0
else
MSG_RAMSCAN_UGH db '    ', @OEM_TEXT, ' VxD Error V2008B: RAM Scan, Assign, and Map Failed', CR, LF, 0
endif				; IFDEF LANG_GR


ifdef @VGASWAP
	 public MSG_ADP2_UGH
MSG_ADP2_UGH	db '    ', @OEM_TEXT, ' VxD Error V2009: FLEXROM AssignDeviceV86Pages Failed', CR, LF, 0


	 public MSG_PIV2_UGH
MSG_PIV2_UGH	db '    ', @OEM_TEXT, ' VxD Error V2010: FLEXROM PhysIntoV86 Failed', CR, LF, 0
endif				; IFDEF @VGASWAP


	 public MSG_MPTL4_UGH
MSG_MPTL4_UGH	db '    ', @OEM_TEXT, ' VxD Error V2011: MapPhysToLinear of ROM Failed', CR, LF, 0


ifdef @DEBUG
	 public MSG_ROMPAM_UGH, MSG_ROMPAM_UGH0
MSG_ROMPAM_UGH	db '    ', @OEM_TEXT, ' DEBUG: V86 ROM Page ('
MSG_ROMPAM_UGH0 db	'xx) Already Mapped', CR, LF, 0
endif				; IFDEF @DEBUG

	public MSG_RAMPAM_HDR
MSG_RAMPAM_HDR	db CR,LF,'    ', @OEM_TEXT,' VxD Error V2035:  V86 RAM Page(s) in use.  Modify RAM=',CR,LF
		db	 '    ', '    statement(s) in ', @OEM_FILE, '.PRO file to remove the following region(s):',CR,LF
		db EOS

	 public MSG_RAMPAM_UGH, MSG_RAMPAM_UGH1, MSG_RAMPAM_UGH2
MSG_RAMPAM_UGH	db	'     ', '    '
MSG_RAMPAM_UGH1 db	'xxxx-'
MSG_RAMPAM_UGH2 db	'xxxx',CR,LF,0,EOS

	public	MSG_IDATA_PRESS
MSG_IDATA_PRESS db	'     ', 'Press any key to continue...',CR,LF,0,EOS


	 public MSG_ROMADP_UGH
MSG_ROMADP_UGH	db '    ', @OEM_TEXT, ' VxD Error V2012: V86 ROM Page AssignDeviceV86Pages Failed', CR, LF, 0


	 public MSG_ROMPIV_UGH
MSG_ROMPIV_UGH	db '    ', @OEM_TEXT, ' VxD Error V2013: V86 ROM Page PhysIntoV86 Failed', CR, LF, 0


	 public MSG_MPB_UGH
MSG_MPB_UGH	db '    ', @OEM_TEXT, ' VxD Error V2014: V86 ROM Page ModifyPageBits Failed', CR, LF, 0


	 public  MSG_NOVHD
ifdef LANG_GR
MSG_NOVHD	 db	'    UnterstÅtzung des virtuellen HiDOS ausgeschaltet', CR, LF, 0
else
MSG_NOVHD	 db	'    VirtualHighDOS support disabled', CR, LF, 0
endif				; IFDEF LANG_GR

	 public  MSG_DOSMAX
ifdef LANG_GR
MSG_DOSMAX	 db	'    DOSMAX UnterstÅtzung eingeschaltet', CR, LF, 0
else
MSG_DOSMAX	 db	'    DOSMAX support enabled', CR, LF, 0
endif				; IFDEF LANG_GR

	 public MSG_NU_WRN
ifdef LANG_GR
MSG_NU_WRN	db '    WARNUNG: kein HiDOS Speicher vorhanden', CR, LF, 0
else
MSG_NU_WRN	db '    WARNING: No High DOS Memory Present', CR, LF, 0
endif				; IFDEF LANG_GR


	 public MSG_HVF_UGH
MSG_HVF_UGH	db '    ', @OEM_TEXT, ' VxD Error V2015: HookV86Fault Failed', CR, LF, 0


	 public MSG_CFG_PTL_UGH
MSG_CFG_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2016: PhysToLinear of 386LOAD.CFG Text Failed', CR, LF, 0

	 public MSG_STU_PTL_UGH
MSG_STU_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2017: PhysToLinear of Win386_Startup_Info_Struc Chain Failed', CR, LF, 0

	 public MSG_MPTL3_UGH
MSG_MPTL3_UGH	db '    ', @OEM_TEXT, ' VxD Error V2018: MapPhysToLinear of Segment Group Failed', CR, LF, 0

	 public MSG_BAGDTS_UGH
MSG_BAGDTS_UGH	db '    ', @OEM_TEXT, ' VxD Error V2019: Build/Allocate GDT Selector for ', @OEM_TEXT, ' Failed', CR, LF, 0

	 public MSG_GDTSNC_UGH
MSG_GDTSNC_UGH	db '    ', @OEM_TEXT, ' VxD Error V2020: GDT Selectors for ', @OEM_TEXT, ' Not Consecutive', CR, LF, 0


; Messages added to AutoInstance code to find INTEL trouble with DOS 5

	 public MSG_FTL_AI01
MSG_FTL_AI01	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2501: AutoInstance Failure - DO_TYPE_1 General Error', CR, LF, 0


	 public MSG_FTL_AI02
MSG_FTL_AI02	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2502: AutoInstance Failure - DO_TYPE_3 General Error', CR, LF, 0


	 public MSG_FTL_AI03
MSG_FTL_AI03	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2503: AutoInstance Failure - DO_TYPE_4 General Error', CR, LF, 0


	 public MSG_FTL_AI15
MSG_FTL_AI15	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2515: AutoInstance Failure - DO_TYPE_5 General Error', CR, LF, 0


	 public MSG_FTL_AI04
MSG_FTL_AI04	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2504: AutoInstance Failure - TYPE_1 Instance List Full', CR, LF, 0


	 public MSG_FTL_AI05
MSG_FTL_AI05	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2505: AutoInstance Failure - TYPE_3 LSEG Entry V86LIN2WIN Failed', CR, LF, 0


	 public MSG_FTL_AI06
MSG_FTL_AI06	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2506: AutoInstance Failure - TYPE_3 LSEG_WINST w/o OWNRHI or INSTLO', CR, LF, 0


	 public MSG_FTL_AI07
MSG_FTL_AI07	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2507: AutoInstance Failure - TYPE_3 ADD_LOWDOS_ITEM Failed', CR, LF, 0


	 public MSG_FTL_AI08
MSG_FTL_AI08	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2508: AutoInstance Failure - TYPE_3 MAC_OWNER V86LIN2WIN Failed', CR, LF, 0


	 public MSG_FTL_AI09
MSG_FTL_AI09	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2509: AutoInstance Failure - TYPE_3 ADD_HIGHDOS_ITEM Failed', CR, LF, 0


	 public MSG_FTL_AI10
MSG_FTL_AI10	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2510: AutoInstance Failure - TYPE_3 MAC_PASS2 Failed', CR, LF, 0


	 public  MSG_INST_LSEG
MSG_INST_LSEG	 db	'    Instancing last LSEG_NEXT field', CR, LF, 0


	 public MSG_FTL_AI18
MSG_FTL_AI18	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2518: AutoInstance Failure - TYPE_5 Instancing LSEG_NEXT Failed', CR, LF, 0


	 public MSG_FTL_AI11
MSG_FTL_AI11	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2511: AutoInstance Failure - TYPE_4 SCAN_ARENA Failed', CR, LF, 0


	 public MSG_FTL_AI16
MSG_FTL_AI16	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2516: AutoInstance Failure - TYPE_5 MAC Entry V86LIN2WIN Failed', CR, LF, 0


	 public  MSG_INST_UMB
MSG_INST_UMB	 db	'    Instancing an unallocated UMB', CR, LF, 0


	 public MSG_FTL_AI17
MSG_FTL_AI17	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2517: AutoInstance Failure - TYPE_5 ADD_HIGHDOS_ITEM Failed', CR, LF, 0


	 public MSG_FTL_AI14
MSG_FTL_AI14	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2514: AutoInstance Failure - SCAN_ARENA ADD_LOWDOS_ITEM Failed', CR, LF, 0


	 public MSG_VLW1_UGH, MSG_VLW2_UGH, MSG_VLW3_UGH, MSG_VLW4_UGH
	 public MSG_VLW5_UGH
MSG_VLW1_UGH	 db '    ', @OEM_TEXT, ' VxD Error V2021: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0
MSG_VLW2_UGH	 db '    ', @OEM_TEXT, ' VxD Error V2022: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0
MSG_VLW3_UGH	 db '    ', @OEM_TEXT, ' VxD Error V2023: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0
MSG_VLW4_UGH	 db '    ', @OEM_TEXT, ' VxD Error V2024: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0
MSG_VLW5_UGH	 db '    ', @OEM_TEXT, ' VxD Error V2025: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0


	 public MSG_UHAF_UGH
MSG_UHAF_UGH	db '    ', @OEM_TEXT, ' VxD Error V2026: Add_UMB_Instance_Item HeapAllocate Failed', CR, LF, 0


	 public MSG_AUIIF_UGH
MSG_AUIIF_UGH	db '    ', @OEM_TEXT, ' VxD Error V2027: Add_UMB_Instance_Item AddInstanceItem Failed', CR, LF, 0


	 public MSG_HAF_UGH
MSG_HAF_UGH	db '    ', @OEM_TEXT, ' VxD Error V2028: Add_LowDOS_Instance_Item HeapAllocate Failed', CR, LF, 0


	 public MSG_AIIF_UGH
MSG_AIIF_UGH	db '    ', @OEM_TEXT, ' VxD Error V2029: Add_LowDOS_Instance_Item AddInstanceItem Failed', CR, LF, 0


	 public MSG_FTL_AI12
MSG_FTL_AI12	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2512: AutoInstance Failure - MAC_PASS2 LSEG Entry V86LIN2WIN Failed', CR, LF, 0


	 public MSG_FTL_AI13
MSG_FTL_AI13	db	CR, LF, '    ', @OEM_TEXT
		db	' VxD Error V2513: AutoInstance Failure - MAC_PASS2 ADD_HIGHDOS_ITEM Failed', CR, LF, 0


	 public MSG_NO_WINA20
ifdef LANG_GR
MSG_NO_WINA20	db '    ', @OEM_TEXT, ' VxD Error V2030: WINA20.386 wurde nicht geladen', CR, LF, 0
else
MSG_NO_WINA20	db '    ', @OEM_TEXT, ' VxD Error V2030: WINA20.386 Is Not Loaded', CR, LF, 0
endif				; IFDEF LANG_GR


; VMAX_UPD.ASM messages

	 public  MSG_UPD_UGH1
MSG_UPD_UGH1	 db	CR, LF, '    ', @OEM_TEXT
ifdef LANG_GR
		 db	' VxD Error V2031: Windows 3.10 Support Patch Target 1 nicht gefunden', CR, LF, 0
else
		 db	' VxD Error V2031: Windows 3.10 Support Patch Target 1 Not Found', CR, LF, 0
endif				; IFDEF LANG_GR


	 public  MSG_UPD_UGH2
MSG_UPD_UGH2	 db	CR, LF, '    ', @OEM_TEXT
ifdef LANG_GR
		 db	' VxD Error V2032: Windows 3.10 Support Patch Target 2 nicht gefunden', CR, LF, 0
else
		 db	' VxD Error V2032: Windows 3.10 Support Patch Target 2 Not Found', CR, LF, 0
endif				; IFDEF LANG_GR


; VMAX_VDD.ASM messages

	 public MSG_MPTL5_UGH
MSG_MPTL5_UGH	db '    ', @OEM_TEXT, ' VxD Error V2033: MapPhysToLinear of VGA ROM Failed', CR, LF, 0


; More VMAX.ASM messages

	 public MSG_PnP_PTL_UGH
MSG_PnP_PTL_UGH db '    ', @OEM_TEXT, ' VxD Error V2034: PhysToLinear of PnP BIOS Failed', CR, LF, 0


; VMAX_DBG.ASM messages

ifdef @DEBUG
	 public  MSG_INST, MSG_INST0, MSG_INST1
MSG_INST	 db	'    Adding instance item @ '
MSG_INST0	 db	'xxxxx ('
MSG_INST1	 db	'xxxxx)', CR, LF, 0

	 public  MSG_INST_DEV, MSG_INST_DEV0, MSG_INST_DEV1
MSG_INST_DEV	 db	'    Device instance item @ '
MSG_INST_DEV0	 db	'xxxxx ('
MSG_INST_DEV1	 db	'xxxxx)', CR, LF, 0

	 public  MSG_INST_NAME, MSG_INST_NAME0
ifdef LANG_GR
MSG_INST_NAME	 db	'    Instancing-Programmname: '
else
MSG_INST_NAME	 db	'    Instancing program name: '
endif				; IFDEF LANG_GR
MSG_INST_NAME0	 db	'ffffffff.eeeXXX' ; Space for name, CR, LF, and 0

endif				; IFDEF @DEBUG

VxD_IDATA_ENDS			; End _IDATA segment
	 page
;******************************************************************************
;
;	     P R O T E C T E D	  M O D E    ( P O S T	 I N I T )
;
;******************************************************************************

VxD_DATA_SEG			; Begin _DATA segment


; VMAX.ASM messages

	 public MSG_PTL_UGH
MSG_PTL_UGH	db '    ', @OEM_TEXT, ' VxD Error V3001: MapPhysToLinear in V86LIN2WIN Failed', CR, LF, 0


ifdef @VGASWAP
	 public MSG_PIV3_UGH
MSG_PIV3_UGH	db '    ', @OEM_TEXT, ' VxD Error V3002: FLEXROM PhysIntoV86 Failed', CR, LF, 0
endif				; IFDEF @VGASWAP


	 public MSG_MPB2_UGH
MSG_MPB2_UGH	db '    ', @OEM_TEXT, ' VxD Error V3003: V86 ROM Page ModifyPageBits Failed', CR, LF, 0

	 public MSG_HFF_UGH
MSG_HFF_UGH	db	'    ', @OEM_TEXT, ' DEBUG: HeapFree Failed', CR, LF, 0


; VMAX_VDD.ASM messages

ifdef @VGASWAP
	 public MSG_FLEX1, MSG_FLEX1_H1
MSG_FLEX1	db '    AssignDeviceV86Pages VMMcall from VDD faked (page '
MSG_FLEX1_H1	db	'xx)', CR, LF, 0


	 public MSG_FLEX2, MSG_FLEX2_H1, MSG_FLEX2_H2
MSG_FLEX2	db '    PhysIntoV86 VMMcall from VDD adjusted  '
MSG_FLEX2_H1	db	'xx ==> '
MSG_FLEX2_H2	db	'xxxxxxxx', CR, LF, 0


	 public MSG_FTL_FLEX1
MSG_FTL_FLEX1	db '    ', @OEM_TEXT, ' VxD Error V3004: VGASWAP Suspicious VDD Control Hook Entry', CR, LF, 0


	 public MSG_FTL_FLEX3
MSG_FTL_FLEX3	db '    ', @OEM_TEXT, ' VxD Error V3005: VGASWAP VDD Control Hook Recursion', CR, LF, 0
endif				; IFDEF @VGASWAP

ifdef @DOSMAX
	 public  MSG_NOQPOPUP_CAPTION, MSG_NOQPOPUP_TEXT
ifdef LANG_GR
MSG_NOQPOPUP_CAPTION	 db	 @OEM_FILE,'.',@OEMEXT,' -- QPopup ist nicht aktiv', 0
MSG_NOQPOPUP_TEXT	 label	 byte
	 db	 'QPopup ist nicht aktiv.  '
	 db	 'Der ',@OEM_TEXT,' Treiber wird nicht in der Lage sein, dieses '
	 db	 'DOSMAX vor Programmen zu schÅtzen, die Grafikmodi benutzen', 0
else
MSG_NOQPOPUP_CAPTION	db	@OEM_FILE,'.',@OEMEXT,' -- QPopup is not running', 0
MSG_NOQPOPUP_TEXT	label	byte
	 db	 'QPopup is not running.  '
	 db	 'The ',@OEM_TEXT,' device will not be able to protect this '
	 db	 'DOSMAX window from programs attempting to enter graphics mode', 0
endif				; IFDEF LANG_GR
endif				; FIDEF @DOSMAX

VxD_DATA_ENDS			; End _DATA segment

	 MEND			; End VMAX_MSG module
