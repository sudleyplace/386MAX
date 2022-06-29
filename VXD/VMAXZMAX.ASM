;'$Header:   P:/PVCS/MAX/VXD/VMAXZMAX.ASV   1.0   05 Sep 1995 17:21:16   HENRY  $
	 title	 VMAXZMAX --  Secondary VxD
	 page	 78,130
	 name	 VMAXZMAX

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1992, 1993 Qualitas, Inc.  All rights reserved.

Environment:  IBM PC, tested under DOS 5.00, 6.00á.

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

Original code by:  William R. Lewis, September, 1992.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC	; From the standard Qualitas include library
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC

	 include VMAX.INC	; Local includes
	 include VMAX_PMI.INC
	 include VMAX_SVM.INC

	 include WINDEVID.INC	; From \INCLUDE
	 include VERSION.INC	; Specific to the VxD
.list
;******************************************************************************
;		 V I R T U A L	 D E V I C E   D E C L A R A T I O N
;
;	In order to pull off all the wierd stuff we do, 386MAX.VXD needs
;	to get control at every WIN386 message both before and after all the
;	other VxDs.  In order to do this, we actually need two VxDs -- one
;	with a very high initialization order (numerically low) and the other
;	with a very low initialization order (numerically high).
;
;	This is the DDB for the special dynamic virtual device added to LoadHi.
;	The normal DDB for LoadHi is in the LOADHI.OBJ file supplied
;	by Microsoft.
;
;******************************************************************************

ZMAX_Init_Order equ	0B8000000h			; After SHELL
ZMAX_Device_ID equ	(QUALITAS_OEM_ID shl 5)+2	; ZMAX

Declare_Virtual_Device ZMAX, VERH, VERL, ZMAX_CONTROL, ZMAX_Device_ID, ZMAX_Init_Order

;******************************************************************************
	 page
VxD_IDATA_SEG				; Begin _IDATA segment

VxD_IDATA_ENDS				; End _IDATA segment
	 page
VxD_DATA_SEG				; Begin _DATA segment

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 include VMAX_PMI.INC
	 extrn	 PMI_FLAG:word

	 extrn	 DEVICE_LIST:dword	; Pointer to DEVICE_LIST

	 extrn	 WIN3_VERSION:word

ifdef @DOSMAX
	 extrn	 SVM_FLAG:word
endif					; IFDEF @DOSMAX

ifdef @ZMAX
ZMAX_CALL_PROCS label dword	; List of handlers for device call messages
	 dd	 OFFSET32 NearRet		; 0000h
	 dd	 OFFSET32 ZMAX_DEVICE_INIT	; 0001h
	 dd	 OFFSET32 NearRet		; 0002h
	 dd	 OFFSET32 NearRet		; 0003h
	 dd	 OFFSET32 NearRet		; 0004h
	 dd	 OFFSET32 NearRet		; 0005h
	 dd	 OFFSET32 NearRet		; 0006h
	 dd	 OFFSET32 NearRet		; 0007h
	 dd	 OFFSET32 NearRet		; 0008h
	 dd	 OFFSET32 ZMAX_VM_INIT		; 0009h
ZMAX_CALL_LAST	 equ	($-ZMAX_CALL_PROCS)/4
endif					; IFDEF @ZMAX

VxD_DATA_ENDS				; End _DATA segment
	 page
VxD_ICODE_SEG				; Begin _ITEXT segment
	 assume  cs:FLAT		; Tell the assembler

ifdef @ZMAX
BeginProc ATTACH_ZMAX			; Connect ZMAX to the Device_List
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	Attach ZMAX_DDB to the end of the Device_List.

|

	 cmp	 WIN3_VERSION,030Ah	; Izit Windows 3.10?
	 jb	 short ATTACH_ZMAX_EXIT ; Exit if not

	 mov	 ecx,DEVICE_LIST	; ==> our DDB
@@:
	 mov	 eax,[ecx].DDB_Next	; Link to next DDB
	 or	 eax,eax		; Izit the last device?
	 jz	 short @F		; Exit loop if so

	 mov	 ecx,eax		; Bump to next device

	 jmp	 short @B		; Try next device
@@:

; ECX ==> the last DDB in the Device_List.
; Add ZMAX_DDB to the end of the Device_List.


	 mov	 esi,OFFSET32 ZMAX_DDB	; ==> new device's DDB
	 mov	 [ecx].DDB_Next,esi	; Link it in

	 sub	 eax,eax		; A handy zero
	 mov	 [esi].DDB_Next,eax	; Terminate the Device_List

ATTACH_ZMAX_EXIT:
	 clc				; Clear error return indicator

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ATTACH_ZMAX			; End ATTACH_ZMAX procedure
endif					; IFDEF @ZMAX

ifdef @ZMAX
BeginProc ZMAX_DEVICE_INIT		; Device_Init handler for secondary VxD
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	Device_Init handler for secondary VxD.

|

ifdef @DOSMAX
	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 ZMAX_DEVICE_INIT_XSVM	; Skip DOSMAX code if not

	 test	 SVM_FLAG,@SVM_SHORT	; DOSMAX off due to short low DOS?
	 jnz	 ZMAX_DEVICE_INIT_XSVM	; Skip DOSMAX code if so

	 mov	 eax,10h		; Interrupt 10h
	 mov	 esi,OFFSET32 BEFORE_VDD_INT10 ; ==> INT 10h hook procedure
	 VMMcall Hook_V86_Int_Chain	; Hook INT 10h
ZMAX_DEVICE_INIT_XSVM:
endif					; IFDEF @DOSMAX

	 clc				; Normal return indicator

	 ret				; Return to WIN386

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ZMAX_DEVICE_INIT		; End ZMAX_DEVICE_INIT procedure
endif					; IFDEF @ZMAX

VxD_ICODE_ENDS				; End _ITEXT segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 NearRet:near		; VMAX_LHI.ASM

ifdef @DOSMAX
	 extrn	 BEFORE_VDD_INT10:near
endif					; IFDEF @DOSMAX

BeginProc ZMAX_CONTROL			; Secondary device control proc
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	Control procedure for the secondary virtual device with low
	initialization order.

|

	 cmp	 eax,ZMAX_CALL_LAST	; Izit above the messages we handle?
	 jae	 short @F		; Don't handle it if so

	 jmp	 ZMAX_CALL_PROCS[eax*4] ; Handle the device call message
@@:
	 clc				; Normal return indicator

	 ret				; Return to caller (LoadHi)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ZMAX_CONTROL			; End ZMAX_CONTROL procedure

BeginProc ZMAX_VM_INIT			; VM_Init handler for secondary VxD
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	VM_Init handler for secondary VxD.

|

ifdef @DOSMAX
	 test	 PMI_FLAG,@PMI_DOSMAX	; Is DOSMAX support enabled?
	 jz	 ZMAX_VM_INIT_XSVM	; Skip DOSMAX code if not

	 SetDOSMAXPtr edx		; EDX ==> our per VM structure
	 or	 [edx].CB_wFlags,@CBF_VMINIT ; Indicate we've handled VM_Init
ZMAX_VM_INIT_XSVM:

	 test	 SVM_FLAG,@SVM_NOBASEMEM ; Fail VM_INIT due to low base memory?
	 jz	 short ZVI_EXIT 	; Return carry clear if not

	 stc				; Fail the VM due to low memory
ZVI_EXIT:
	 ret				; Return to WIN386
else
	 clc				; Normal return indicator
	 ret				; Return to WIN386
endif					; IFDEF @DOSMAX

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ZMAX_VM_INIT			; End ZMAX_VM_INIT procedure

VxD_CODE_ENDS				; End _TEXT segment

	 end				; End VMAXZMAX module
