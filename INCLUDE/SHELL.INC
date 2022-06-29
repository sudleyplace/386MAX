;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp., 1988-1990
;
;   Title:	SHELL.Inc - Public services for SHELL
;
;   Version:	1.00
;
;   Date:	30-Nov-1988
;
;   Author:	ARR
;
;------------------------------------------------------------------------------
;
;   Change log:
;
;      DATE	REV		    DESCRIPTION
;   ----------- --- -----------------------------------------------------------
;   19-Sep-1988 RAL Original
;   12-Oct-1988 RAL Converted to use VxD_Service macros
;   29-Nov-1988 ARR Redo split from VMCTRL
;
;==============================================================================

Begin_Service_Table SHELL

SHELL_Service  SHELL_Get_Version, LOCAL
SHELL_Service  SHELL_Resolve_Contention
SHELL_Service  SHELL_Event,LOCAL
SHELL_Service  SHELL_SYSMODAL_Message,LOCAL
SHELL_Service  SHELL_Message,LOCAL
;
; Following specific to SHELL version >= 3.10
;
ifndef WIN30COMPAT
SHELL_Service	 SHELL_GetVMInfo, LOCAL
endif
ifndef WIN31COMPAT
SHELL_Service	 _SHELL_PostMessage, LOCAL
SHELL_Service	 _SHELL_ShellExecute
SHELL_Service	 _SHELL_PostShellMessage
SHELL_Service	 SHELL_DispatchRing0AppyEvents, LOCAL
SHELL_Service	 SHELL_Hook_Properties, LOCAL
SHELL_Service	 SHELL_Unhook_Properties, LOCAL
SHELL_Service	 SHELL_Update_User_Activity, LOCAL
SHELL_Service	 _SHELL_QueryAppyTimeAvailable, LOCAL
SHELL_Service	 _SHELL_CallAtAppyTime, LOCAL
SHELL_Service	 _SHELL_CancelAppyTimeEvent
SHELL_Service	 _SHELL_BroadcastSystemMessage, LOCAL
SHELL_Service	 _SHELL_HookSystemBroadcast, LOCAL
SHELL_Service	 _SHELL_UnhookSystemBroadcast, LOCAL
SHELL_Service	 _SHELL_LocalAllocEx, LOCAL
SHELL_Service	 _SHELL_LocalFree, LOCAL
SHELL_Service	 _SHELL_LoadLibrary, LOCAL
SHELL_Service	 _SHELL_FreeLibrary, LOCAL
SHELL_Service	 _SHELL_GetProcAddress, LOCAL
SHELL_Service	 _SHELL_CallDll, LOCAL
SHELL_Service	 _SHELL_SuggestSingleMSDOSMode
SHELL_Service	 SHELL_CheckHotkeyAllowed
endif

End_Service_Table SHELL

BeginDoc
;
;   Windows Message Box Flags used on SHELL_SYSMODAL_Message and
;	SHELL_Message services
;
MB_OK			 EQU	    00H
MB_OKCANCEL		 EQU	    01H
MB_ABORTRETRYIGNORE	 EQU	    02H
MB_YESNOCANCEL		 EQU	    03H
MB_YESNO		 EQU	    04H
MB_RETRYCANCEL		 EQU	    05H
MB_ICONHAND		 EQU	    010H
MB_ICONEXCLAMATION	 EQU	    030H
MB_ICONASTERISK 	 EQU	    040H
MB_DEFBUTTON1		 EQU	    00H
MB_DEFBUTTON2		 EQU	    0100H
MB_DEFBUTTON3		 EQU	    0200H
MB_APPLMODAL		 EQU	    00H
MB_SYSTEMMODAL		 EQU	    01000H
MB_NOFOCUS		 EQU	    08000H
;
; Following bits are WIN386 SHELL extensions
;
MB_ASAP 		 EQU	    080000000H	; Message is timely, put
						;   up as soon as possible
;
; The following flag bits are 3.10 extensions.
;
MB_NOWINDOW		 EQU	    040000000H	; DO NOT switch to Windows
						;   to do this message, do it
						;   in full screen mode always.
						;   ONLY FOR SHELL_SYSMODAL_Message

MB_HANGSYS		 EQU	    020000000H	; Hang with ints disabled.
						;   This is for especially
						;   severe errors (like parity
						;   errors).
						;   ONLY FOR SHELL_SYSMODAL_Message

;
;   Windows Message Box Return codes used on SHELL_SYSMODAL_Message and
;	SHELL_Message services
;
IDOK			 EQU	1
IDCANCEL		 EQU	2
IDABORT 		 EQU	3
IDRETRY 		 EQU	4
IDIGNORE		 EQU	5
IDYES			 EQU	6
IDNO			 EQU	7

EndDoc

;
; On SHELL_Event, the wParam in EAX occupies the low 16 bits of EAX. The High 16
;	bits contain extra flags
;
SE_WP_SetFocusBoost	equ	00000000000000010000000000000000b
SE_WP_SetFocusBoostBit	equ	16		; Boost the SYS VM till a
						; Set_Focus call
SE_WP_SwitcherBoost	equ	00000000000000100000000000000000b
SE_WP_SwitcherBoostBit	equ	17		; Boost the SYS VM on Switcher
						;  screen
SE_WP_FilSysChgBoost	equ	00000000000001000000000000000000b
SE_WP_FilSysChgBoostBit equ	18		; Boost the SYS VM till response
						;  to VDA_FileSysChange
SE_WP_ClipAPIBoost	equ	00000000000010000000000000000000b
SE_WP_ClipAPIBoostBit	equ	19		; Boost the SYS VM during clipbrd
						;  API
SE_WP_PrtScBoost	equ	00000000000100000000000000000000b
SE_WP_PrtScBoostBit	equ	20		; Boost the SYS VM during Print screen

SE_WP_DispUpdBoost	equ	00000000001000000000000000000000b
SE_WP_DispUpdBoostBit	equ	21		; Boost the SYS VM during updates

include shellfsc.inc

BeginDoc
;
; Bits of returned EAX flags for SHELL_GetVMInfo service
;
SGVMI_Windowed	  equ 00000000000000000000000000000100B ; Is Windowed
SGVMI_ALTTABdis   equ 00000000000000000000000000100000b ; Alt+Tab is reserved
SGVMI_ALTESCdis   equ 00000000000000000000000001000000b ; Alt+Esc is reserved
SGVMI_ALTSPACEdis equ 00000000000000000000000010000000b ; Alt+Space is reserved
SGVMI_ALTENTERdis equ 00000000000000000000000100000000b ; Alt+Enter is reserved
SGVMI_ALTPRTSCdis equ 00000000000000000000001000000000b ; Alt+PrtSc is reserved
SGVMI_PRTSCdis	  equ 00000000000000000000010000000000b ; PrtSc is reserved
SGVMI_CTRLESCdis  equ 00000000000000000000100000000000b ; Ctrl+Esc is reserved
SGVMI_HasHotKey   equ 00000000000000000100000000000000b ; Has a shortcut key
SGVMI_Polling	  equ 00000000000000000001000000000000b ; Polling detection Enab
SGVMI_FastPaste   equ 00000000000000100000000000000000b ; Allow Fast paste Enab
SGVMI_NoHMA	  equ 00000000000000000010000000000000b ; No HMA
SGVMI_XMS_Lock	  equ 00000000000000010000000000000000b ; XMS Hands Locked
SGVMI_EMS_Lock	  equ 00000000000000001000000000000000b ; EMS Hands Locked
SGVMI_V86_Lock	  equ 00000000000001000000000000000000b ; V86 Memory Locked
SGVMI_ClsExit	  equ 01000000000000000000000000000000b ; Close on Exit Enab

;
; Bits of returned ECX flags for SHELL_GetVMInfo service
;	Currently no bits defined.
;

EndDoc
