;' $Header:   P:/PVCS/MAX/VXD/VMAX_API.ASV   1.1   03 Nov 1995 14:56:30   BOB  $
	 title	 VMAX_API -- Application Program Interface for the 386MAX VxD
	 page	 78,130
	 name	 VMAX_API

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-95 Qualitas, Inc.  GNU General Public License version 3.

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

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
	 include SHELL.INC

	 include MASM.INC	; From the standard Qualitas include library
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC

	 include QMAXWIN3.INC	; From the QMAX source code

	 include WINDEVID.INC	; From \INCLUDE
	 include SWATVXD.INC	; Define service table

	 include BREAK.INC
	 include VMAX.INC	; Local includes
	 include VMAXAPI.INC

	 include VERSION.INC	; Specific to the VxD
.list
	 page
VxD_DATA_SEG				; Begin _DATA segment
	 assume  cs:FLAT		; Tell the assembler

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 extrn	 PGROUP_DS:word

	 extrn	 lpfnXMS_VXD2MAX:fword
	 extrn	 lpfnUTL_VXD2MAX:fword

PMAPI_CALL_PROCS label dword	; List of handlers for protected mode API
	 dd	 OFFSET32 PMAPI_GetVer		; 0000h
	 dd	 OFFSET32 PMAPI_GetSwatVer	; 0001h
	 dd	 OFFSET32 PMAPI_GetVMHandle	; 0002h
	 dd	 OFFSET32 PMAPI_GetSysVMHandle	; 0003h

ifdef @DOSMAX
	 dd	 OFFSET32 PMAPI_GetVMInfo	; 0004h
	 dd	 OFFSET32 PMAPI_RegisterCallback   ; 0005h
	 dd	 OFFSET32 PMAPI_UnregisterCallback ; 0006h
	 dd	 OFFSET32 PMAPI_IgnoreModeSwitch   ; 0007h
	 dd	 OFFSET32 PMAPI_Terminate	   ; 0008h
	 dd	 OFFSET32 PMAPI_GetTimeSliceInfo   ; 0009h
	 dd	 OFFSET32 PMAPI_SetTimeSliceInfo   ; 000Ah
	 dd	 OFFSET32 PMAPI_SignalSemaphore    ; 000Bh
	 dd	 OFFSET32 PMAPI_GetDOSMAXInfo	   ; 000Ch
else
	 dd	 OFFSET32 NearRet		; 0004h - reserved
	 dd	 OFFSET32 NearRet		; 0005h - reserved
	 dd	 OFFSET32 NearRet		; 0006h - reserved
	 dd	 OFFSET32 NearRet		; 0007h - reserved
	 dd	 OFFSET32 NearRet		; 0008h - reserved
	 dd	 OFFSET32 NearRet		; 0009h - reserved
	 dd	 OFFSET32 NearRet		; 000Ah - reserved
	 dd	 OFFSET32 NearRet		; 000Bh - reserved
	 dd	 OFFSET32 NearRet		; 000Ch - reserved
endif					; IFDEF @DOSMAX

PMAPI_CALL_LAST  equ	($-PMAPI_CALL_PROCS)/4

V86API_CALL_PROCS label dword	; List of handlers for protected mode API
	 dd	 OFFSET32 NearRet		; 0000h - reserved
	 dd	 OFFSET32 V86API_XMS2MAX	; 0001h
	 dd	 OFFSET32 V86API_UTIL2MAX	; 0002h
	 dd	 OFFSET32 V86API_GetVer 	; 0003h

V86API_CALL_LAST  equ	($-V86API_CALL_PROCS)/4

VxD_DATA_ENDS				; End _DATA segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 DISPLAY:near
	 extrn	 PHYS2LIN:near

	 extrn	 NearRet:near		; VMAX_LHI.ASM

ifdef @DOSMAX
	 extrn	 PMAPI_RegisterCallback:near	; VMAX_SVM.ASM
	 extrn	 PMAPI_UnregisterCallback:near
	 extrn	 PMAPI_IgnoreModeSwitch:near
	 extrn	 PMAPI_Terminate:near
	 extrn	 PMAPI_SignalSemaphore:near
	 extrn	 PMAPI_GetDOSMAXInfo:near
endif					; IFDEF @DOSMAX

BeginProc V86_API			; VxD V86 API Service Routine
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Entry:
	EBX	=	Current VM handle
	EDX	=	Reference data at time of VMMcall Allocate_V86_Call_Back
	EBP	==>	Current VM's client register structure

	Client pushes word function code before call

|

	 BREAK	 DBG_FLAG,@DBG_API1684	; Break if 386MAXAPI1684=TRUE

	 REGSAVE <eax,edx,esi,ds,fs,gs> ; Save caller's registers

	 push	 ds			; MOV FS,DS
	 pop	 fs			; ...
	 assume  fs:FLAT		; Tell the assembler

	 movzx	 eax,[ebp].Client_SS	; Get V86 client's SS
	 shl	 eax,(4-0)		; Convert from paras to bytes
	 add	 eax,[ebp].Client_ESP	; Form linear address to client's stack

	 movzx	 eax,[eax].ELO		; Get service code

	 cmp	 eax,V86API_CALL_LAST	; Izit above the functions we handle?
	 jae	 short V86API_STC	; Don't handle it if so

	 call	 V86API_CALL_PROCS[eax*4] ; Handle the V86 API

	 jmp	 short V86API_EXIT	; Rejoin common exit code

V86API_STC:
	 or	 [ebp].Client_Flags,(mask $CF) ; Set carry in client's flags
	 mov	 [ebp].Client_AX,-1	; Return -1 to indicate error

V86API_EXIT:
	 add	 [ebp].Client_ESP,2 ; Strip function opcode from client stack

	 REGREST <gs,fs,ds,esi,edx,eax> ; Restore caller's registers
	 assume  ds:FLAT, fs:nothing, gs:nothing ; Tell the assembler

	 ret				; Return to V86 caller via WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86_API			; End V86_API procedure
	 page
BeginProc V86API_XMS2MAX		; Pass an XMS call down to 386MAX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Pass an XMS call down to 386MAX

|

	 push	 ds			; MOV GS,DS
	 pop	 gs			; For 386MAX's use as a 4GB selector
	 assume  gs:FLAT		; Tell the assembler

	 mov	 ds,PGROUP_DS		; Get DS for use by 386MAX XMS code
	 assume  ds:nothing		; Tell the assembler

	 call	 lpfnXMS_VXD2MAX	; Call 386MAX XMS code

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86API_XMS2MAX 		; End V86API_XMS2MAX procedure
	 page
BeginProc V86API_UTIL2MAX		; Pass a 386UTIL call down to 386MAX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Pass a 386UTIL call down to 386MAX

|

	 push	 ds			; MOV GS,DS
	 pop	 gs			; For 386MAX's use as a 4GB selector
	 assume  gs:FLAT		; Tell the assembler

	 mov	 ds,PGROUP_DS		; Get DS for use by 386MAX UTIL code
	 assume  ds:nothing		; Tell the assembler

	 call	 lpfnUTL_VXD2MAX	; Call 386MAX UTIL code

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86API_UTIL2MAX		; End V86API_UTIL2MAX procedure
	 page
BeginProc V86API_GetVer 		; Return API version in client AX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return API version in client AX

|

; The following instruction won't work because LINK386 can't handle mixing
; 16-bit fixups in a USE32 FLAT segment.
;;;;;;	 mov	 ax,VERS_HTU		; Pick up the version #

	 mov	 ah,VERH		; Pick up the high-order version #
	 mov	 al,VERL		; Pick up the low-order version #

	 mov	 [ebp].Client_AX,ax	; Load up the return code

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86API_GetVer			; End V86API_GetVer procedure
	 page
BeginProc PM_API			; VxD Protected mode API Service Routine
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Entry:
	EBX	=	Current VM handle
	EDX	=	Reference data at time of VMMcall Allocate_V86_Call_Back
	EBP	==>	Current VM's client register structure

	Client_AX =	Function code

|

	 movzx	 eax,[ebp].Client_AX	; Load up the function code

	 cmp	 eax,PMAPI_CALL_LAST	; Izit above the functions we handle?
	 jae	 short PMAPI_STC	; Don't handle it if so

	 call	 PMAPI_CALL_PROCS[eax*4] ; Handle the PM API

	 jmp	 short PMAPI_EXIT	; Rejoin common exit code

PMAPI_STC:
	 or	 Client_Flags[ebp],(mask $CF) ; Set carry in client's flags
	 mov	 [ebp].Client_AX,-1	; Return -1 to indicate error

PMAPI_EXIT:
	 clc				; Normal return indicator (to WIN386)

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PM_API 			; End PM_API procedure

BeginProc PMAPI_GetVer			; Return version of PM API services
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return protected mode API services version # in Client_AX

|

; The following instruction won't work because LINK386 can't handle mixing
; 16-bit fixups in a USE32 FLAT segment.
;;;;;;	 mov	 ax,VERS_HTU		; Pick up the version #

	 mov	 ah,VERH		; Pick up the high-order version #
	 mov	 al,VERL		; Pick up the low-order version #

	 mov	 [ebp].Client_AX,ax	; Load up the return code

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetVer			; End PMAPI_GetVer procedure

BeginProc PMAPI_GetSwatVer		; Return version of PM API services
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return protected mode API services version # in Client_AX

|

	 VxDcall SWAT_Get_Version	; Get SWATVXD version (detect presence)

	 mov	 [ebp].Client_AX,ax	; Load up the return code

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetSwatVer		; End PMAPI_GetSwatVer procedure

BeginProc PMAPI_GetVMHandle		; Return EBX in client's EBX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return calling machine's VM_Handle in client EBX

|

	 mov	 [ebp].Client_EBX,ebx	; Return it in the client's EBX

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetVMHandle		; End PMAPI_GetVMHandle procedure

BeginProc PMAPI_GetSysVMHandle		; Return Sys_VM_Handle in EBX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Return Sys_VM_Handle in EBX

|

	 REGSAVE <ebx>			; Save current VM handle

	 VMMcall Get_Sys_VM_Handle	; ... into EBX

	 mov	 [ebp].Client_EBX,ebx	; Return it in the client's EBX

	 REGREST <ebx>			; Restore current VM handle

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetSysVMHandle		; End PMAPI_GetSysVMHandle procedure
	 page
BeginProc PMAPI_GetVMInfo		; PMAPI_GetVMInfo ... into EAX, ECX, EDX
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Get VM PIF info into EAX, ECX, EDX

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX = VM handle of interest

EXIT:
	Client_EFlags.CF = 0 if successful

	All registers except EBX may be trashed

|

	 REGSAVE <ebx>			; Save caller's registers

	 or	 [ebp].Client_EFlags.ELO,(mask $CF) ; Set client's CF

	 mov	 ebx,[ebp].Client_EBX	; VM handle of interest

	 VMMcall Validate_VM_Handle	; Set carry if EBX isn't valid
	 jc	 short @F		; Return AX = 1 if not valid

	 VxDcall SHELL_GetVMInfo	; Get bits into EAX, ECX
					; EDX, ESI, and EDI trashed
	 mov	 [ebp].Client_EAX,eax	; Save PIF bits into client's regs
	 mov	 [ebp].Client_ECX,ecx	; ...
	 mov	 [ebp].Client_EDX,edx	; ...

	 and	 [ebp].Client_EFlags.ELO,not (mask $CF) ; Clear client's CF
@@:
	 REGREST <ebx>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetVMInfo		; End PMAPI_GetVMInfo procedure
	 page
BeginProc PMAPI_GetTimeSliceInfo
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Get time slice priority and flags in client registers

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX = VM handle of interest

EXIT:
	Client_EFlags.CF = 0 if successful
	Client_ESI = CB_VM_Status flags
	Client_ECX = foreground priority
	Client_EDX = background priority
	Client_EAX = percentage of CPU time available

	All registers except EBX may be trashed

|

	 REGSAVE <ebx>			; Save caller's registers

	 or	 [ebp].Client_EFlags.ELO,(mask $CF) ; Set client's CF

	 mov	 ebx,[ebp].Client_EBX	; VM handle of interest

	 VMMcall Validate_VM_Handle	; Set carry if EBX isn't valid
	 jc	 short @F		; Return AX = 1 if not valid

	 VMMcall Get_Time_Slice_Priority ; Get flags and priorities
					; ... into EAX, ECX, EDX, and ESI
	 mov	 [ebp].Client_ESI,eax	; Flags and priorities into client regs
	 mov	 [ebp].Client_ECX,ecx	; ...
	 mov	 [ebp].Client_EDX,edx	; ...
	 mov	 [ebp].Client_EAX,esi	; ... percentage of CPU time

	 and	 [ebp].Client_EFlags.ELO,not (mask $CF) ; Clear client's CF
@@:
	 REGREST <ebx>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_GetTimeSliceInfo 	; End PMAPI_GetTimeSliceInfo procedure
	 page
BeginProc PMAPI_SetTimeSliceInfo
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Set time slice priority and flags from client registers

ENTRY:
	EBP ==> Client register structure
	EBX = VM handle

	Client_EBX = VM handle of interest
	Client_ESI = CB_VM_Status flags
	Client_ECX = foreground priority
	Client_EDX = background priority

EXIT:
	Client_EFlags.CF = 0 if successful

	All registers except EBX may be trashed

|

	 REGSAVE <ebx>			; Save caller's registers

	 or	 [ebp].Client_EFlags.ELO,(mask $CF) ; Set client's CF

	 mov	 ebx,[ebp].Client_EBX	; VM handle of interest

	 VMMcall Validate_VM_Handle	; Set carry if EBX isn't valid
	 jc	 short @F		; Return AX = 1 if not valid

	 mov	 eax,[ebp].Client_ESI	; Flags and priorities from client regs
	 mov	 ecx,[ebp].Client_ECX	; ...
	 mov	 edx,[ebp].Client_EDX	; ...
	 VMMcall Set_Time_Slice_Priority ; Set flags and priorities
					; ... from EAX, ECX, and EDX

	 and	 [ebp].Client_EFlags.ELO,not (mask $CF) ; Clear client's CF
@@:
	 REGREST <ebx>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PMAPI_SetTimeSliceInfo 	; End PMAPI_SetTimeSliceInfo procedure
	 page
BeginProc QMAX_HELPER		; Direct call 386MAX.SYS service routine
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	This routine provides services to 386MAX.SYS through a direct call
	interface.

Entry:
	AH	=	1 -- PhysToLinear
		EDX	=	Physical address to be mapped
		ECX	=	Length


Exit:
		EDX	=	Linear address corresponding to input physaddr

	CY	=	0 -- Normal return
	CY	=	1 -- Error exit

|

	 assume  ds:nothing, es:nothing ; Tell the assembler

	 REGSAVE <eax,ecx,ds,es> ; Save caller's registers

	 cmp	 ah,1		; Is it the MapPhysToLinear call?
	 jne	 short AS_ERRXIT ; No, that's a mistake

	 mov	 ax,cs			; Get out code selector
	 add	 ax,(type DESC_STR)	; Bump to next one -- our data selector
	 mov	 ds,ax			; Load as our DS
	 mov	 es,ax			; Load as our ES
	 assume  ds:FLAT, es:FLAT	; Tell the assembler

	 push	 edx		; Physical address
	 push	 ecx		; Length
	 call	 PHYS2LIN	; Get linear address into EAX
;;;;;;	 VMMcall _MapPhysToLinear <edx, ecx, 0> ; Get linear address for MAX

	 cmp	 eax,-1 	; Test for error return
	 je	 short AS_ERRXIT ; Jump if it failed

	 mov	 edx,eax	; Move linear address to proper return register

	 clc			; All lights green
AS_XIT:
	 REGREST <es,ds,ecx,eax> ; Restore caller's registers
	 assume  ds:FLAT, es:FLAT

	 retf			; Return to caller (386MAX)
AS_ERRXIT:
	 stc			; Put up the red flag

	 jmp	 short AS_XIT	; Join common return code

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  QMAX_HELPER		; End QMAX_HELPER procedure

VxD_CODE_ENDS			; End _TEXT segment

	 MEND			; End VMAX_API module
