;'$Header:   P:/PVCS/MAX/VXD/VMAX_LHI.ASV   1.1   11 Mar 1996 09:16:30   BOB  $
	 title	 VMAX_LHI -- Routines Interfacing with LoadHi
	 page	 78,130
	 name	 VMAX_LHI

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-96 Qualitas, Inc.  GNU General Public License version 3.

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

	The routines in this module are modifications of the examples
	supplied by Microsoft with the LoadHi VxD kit.

|


.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ASCII.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC

	 include QMAXWIN3.INC

	 include VMAX.INC
	 include VMAX_UPD.INC
.list

	 page
VxD_ICODE_SEG			; Begin _ITEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 SYS_CRITICAL_INIT:near
	 extrn	 VMAX_DEVICE_INIT:near
	 extrn	 VMAX_INIT_COMPLETE:near

VxD_ICODE_ENDS			; End _ITEXT segment

	 page
VxD_CODE_SEG			; Begin _TEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 VMAX_VM_NOT_EXECUTEABLE:near
	 extrn	 VMAX_DESTROY_VM:near

	 extrn	 VMAX_SYS_VM_INIT:near
	 extrn	 VMAX_CREATE_VM:near
;;;;;;	 extrn	 VMAX_VM_INIT:near
	 extrn	 VMAX_SYSTEM_EXIT:near
	 extrn	 VMAX_SYS_CRITICAL_EXIT:near

ifdef @VGASWAP
	 extrn	 CHK_FLEX_IO:near
endif				; IFDEF @VGASWAP

VxD_CODE_ENDS			; End _TEXT segment

	 page
VxD_DATA_SEG			; Begin LDATA segment
	 assume  ds:FLAT	; Tell the assembler

	 extrn	 DEV_HDR_PTR:dword	; VMAX.ASM

	 extrn	 OVRMAC:word		; VMAX.ASM
	 extrn	 OVRMAC_PAGE:dword	; VMAX.ASM

	 extrn	 ADDL_INST:tbyte	; VMAX.ASM
	 extrn	 PDIR_LIN:dword 	; VMAX.ASM

VxD_DATA_ENDS			; End LDATA segment

	 page
VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 extrn	 REF_LIN:dword					; VMAX.ASM
	 extrn	 ASSIGN_BMP:dword				; VMAX.ASM
	 extrn	 HIGHDOS_MAP:dword
;;;;;;	 extrn	 HIGHDOS_FREE_MAP:dword

	 include VMAX_PMI.INC
	 extrn	 PMI_FLAG:word	; VMAX.ASM

VMAX_CALL_PROCS label dword	; List of handlers for device call messages
	 dd	 OFFSET32 SYS_CRITICAL_INIT		; 0000h
	 dd	 OFFSET32 VMAX_DEVICE_INIT		; 0001h
	 dd	 OFFSET32 VMAX_INIT_COMPLETE		; 0002h
	 dd	 OFFSET32 VMAX_SYS_VM_INIT		; 0003h
	 dd	 OFFSET32 NearRet			; 0004h
	 dd	 OFFSET32 VMAX_SYSTEM_EXIT		; 0005h
	 dd	 OFFSET32 VMAX_SYS_CRITICAL_EXIT	; 0006h
	 dd	 OFFSET32 VMAX_CREATE_VM		; 0007h
	 dd	 OFFSET32 NearRet			; 0008h
	 dd	 OFFSET32 NearRet			; 0009h VM_Init
	 dd	 OFFSET32 NearRet			; 000Ah
	 dd	 OFFSET32 VMAX_VM_NOT_EXECUTEABLE	; 000Bh
	 dd	 OFFSET32 VMAX_DESTROY_VM		; 000Ch
VMAX_CALL_LAST	 equ	($-VMAX_CALL_PROCS)/4

VxD_LOCKED_DATA_ENDS		; End _LDATA segment

	 page
VxD_LOCKED_CODE_SEG		; Begin _LTEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 PHYS2LIN:near	; VMAX.ASM

BeginProc NearRet
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	NearRet is a used as a place holder in tables of procedure offsets.

|

	 clc			; Normal return indicator

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc NearRet

BeginProc Control_Call_Hook
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

	Control_Call_Hook

DESCRIPTION:
	This procedure should handle all the control calls that
	the LIM/UMBulator wants to do additional processing on.

	This routine will be called before the LoadHi VxD does it's
	own processing and the VxD will do a PUSHAD/POPAD accross the call.

	Return CARRY SET if the call has to be failed.
	Not all calls can be failed.  While you may fail calls like
	Sys_Critical_Init and Create_VM, you should not fail calls
	like Device_Init which would leave the VXD in an inconsistent
	state.

NOTE:	By hooking the Debug_Query service the LIM/UMBulator specific
	part of the VxD can implement its own stuff that gets done when
	you type .loadhi with the DEBUG version of WIN386.EXE. This
	service hook should always return carry clear, and should all be
	under IFDEF DEBUG conditional assembly.

|

	 cmp	 eax,VMAX_CALL_LAST	; Izit above the messages we handle?
	 jae	 short @F		; Don't handle it if so

	 jmp	 VMAX_CALL_PROCS[eax*4] ; Handle the device call message
@@:
	 clc				; Normal return indicator

	 ret				; Return to caller (LoadHi)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc Control_Call_Hook

VxD_LOCKED_CODE_ENDS		; End _LTEXT segment

	 page
VxD_IDATA_SEG			; Begin _IDATA segment

	 public  NAM_386LOAD
NAM_386LOAD db	 '386LOAD '     ; Name of 386LOAD in a device driver arena

VxD_IDATA_ENDS			; End _IDATA segment


VxD_ICODE_SEG			; Begin _ITEXT segment
	 assume  cs:FLAT	; Tell the assembler

ifdef @DEBUG
	 extrn	 SHOW_INSTANCE_DEVICE:near
endif				; IFDEF @DEBUG

BeginProc Get_UMB_Info
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Get_UMB_Info

This routine is called by the LoadHi SYS_CRITICAL_INIT immediately after
we return from out CONTROL_HOOK stuff.

This routine knows about the interface between the LoadHi VXD and the
LIM/UMBulator that loads it.

ENTRY:
	EBX - SYS VM handle
	EBP - Client register frame for SYS VM
	EDX - Device reference data.

       NOTE THE ASSUMPTION!  We are at SYS-Critical_Init.  None
       of the UMBs are set up.	The page mapping is currently set
       up Linear = Physical.  Thus we observe that this "address"
       is required to live in the low 1Meg, not in a UMB.

EXIT:
	EAX  - First UMB page number. (I)
	EDX  - # of consecutive pages that may have UMBs in them. (J-I+1)

Uses:  EAX,EDX and Flags.

|

	 movzx	 eax,OVRMAC	; Get V86 segment of 1st UMB MAC entry

	 cmp	 ax,-1		; OVRMAC == 0FFFFh if there are no UMBs
	 jne	 short @F	; Skip special handling if UMBs exist

; No UMBs exist -- Return special values

	 mov	 eax,0A0h	; Address of 1st possible UMB
	 sub	 edx,edx	; # of UMB pages ...
	 inc	 edx		; ... is 1

	 jmp	 short GUI_XIT	; Join common exit code

@@:
	 shr	 eax,(12-4)	; Convert from paras to 4KB pages

; Get the # of consecutive pages that may have UMBs in them.

	 mov	 edx,0FFh + 1	; 1 past the last V86 page num
	 sub	 edx,eax	; Total # of consecutive UMB pages
GUI_XIT:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc Get_UMB_Info		; End Get_UMB_Info procedure

	 page
BeginProc Get_Ptr_To_Instance_Data_List
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Get_Ptr_To_Instance_Data_List

DESCRIPTION:
	Returns a pointer to the list of instance data address and
	size that was copied out of the Windows/386 3.00 initialization
	data structure.

	NOTE THAT THIS ROUTINE IS NOT CALLED IF VMM VERSION IS >= 3.10

	Called by LoadHi during DeviceInit time.

EXIT:
	EDI - 32 bit pointer to an array where each entry is of 6 bytes
	(except last). The first DWORD is a seg:off address of the
	start of a data area that is to be instanced and the last
	WORD is the size of the area in bytes.

	The last entry in the array must be a DWORD of 0.

USES:
	FLAGS,EDX

|

	 lea	 edi,ADDL_INST	; Return pointer to list of instance items

	 ret			; Return to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  Get_Ptr_To_Instance_Data_List ; End Get_Ptr_To_Instance_Data_List

	 page
DEV_ARENA_TYPE	equ	44h	; MAC associated with devices (from Amit)

BeginProc Get_Device_Info	; Size a DOS device loaded high
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Get_Device_Info:

DESCRIPTION:
	Tries to get the starting address and size of a device which is
	loaded high (interested in CONFIG.SYS devices only).

	PLEASE NOTE, VERY IMPORTANT.  This code relies on the
	LimStartUMBPage and DeviceHeaderStartPtr variables being
	set to work properly.  These variables are set in the
	Get_UMB_Info routine.  If the VMM version is >= 3.10 and
	the Get_Hooks_To_Install routine returns bit 0 set,
	and bit 1 clear (do not manage UMBs, but do put in
	DOSMGR_Instance_Device hook) the Get_UMB_Info routine is
	NOT called and these variables will NOT be set.  For this config
	to work properly, these variables will have to get set somewhere
	else (Get_Hooks_To_Install for instance).

ENTRY:
	ESI -> 8 character device name string
	    This string must exactly match the name as it will be
	    found in the device header in low/umb memory.
	    No case conversion is performed (name in dev hdr is upper case)
	    Length is 8 (name must be space padded as DOS device names are)
	    No ':'s!! There is no ':' in the name in the device header.

EXIT:
	Carry clear if the device is loaded high and was loaded from
	    config.sys. (This implementaion assumes that devices loaded
	    from config.sys will have the special DOS4/DOS5 arena
	    associated with them).  In this case:

       EDX - Start of the device part that has to be instanced.
       EAX - Length of the portion in bytes.

Carry set if:
       Device cannot be found in the device header chain
       Device not loaded high
       Device is not a character device
       Device cannot be sized properly

USES:
	FLAGS,EAX,EDX

|

	 REGSAVE <ebx,ecx,edi>	; Save caller's registers

	 cmp	 OVRMAC,-1	; OVRMAC == 0FFFFh if there are no UMBs
	 je	 GDI_DEVBAD	; There are no UMBs, so device isn't in one

	 mov	 edi,DEV_HDR_PTR ; Get pointer to the first device
	 sub	 ebx,ebx	; Previous segment starts off at zero
	 sub	 edx,edx	; ...
GDI_CHKDEV:
	 test	 [edi].DD_ATTR,DRV_ATTR_CHAR ; Deal with character devices only
	 jz	 short GDI_NEXTDEV ; Skip non character devices

	 REGSAVE <esi,edi>	; Save registers around REPE CMPSB

	 lea	 edi,[edi].DD_NAME ; Start of this device's name
	 mov	 ecx,8		; Length of name
	 cld			; Forward
	 repe cmpsb		; Check to see if it matches

	 REGREST <edi,esi>	; Restore registers

	 jz	 short GDI_FOUNDDEV ; Jump if we've found the correct device

GDI_NEXTDEV:
	 mov	 edi,[edi].DD_NEXT ; Get pointer to next device
	 mov	 ebx,edx	; Save pointer to previous device
	 mov	 edx,edi	; EDX is seg:off of device

	 cmp	 di,0FFFFh	; End of device list?
	 je	 GDI_DEVBAD	; Jump if done with device instance data

	 movzx	 eax,di 	; Offset
	 shr	 edi,16 	; Shift segment to low-order end
	 shl	 edi,4		; Convert from paras to bytes
	 add	 edi,eax	; EDI is linear address of device

	 jmp	 short GDI_CHKDEV ; Continue searching

; EDI has a pointer to the device, check to see if this is past the UMB line.

GDI_FOUNDDEV:
	 mov	 eax,OVRMAC_PAGE ; Get the start of the UMB page
	 shl	 eax,(12-0)	; Convert from 4 KB page to byte linear address

	 cmp	 edi,eax	; Is it above the UMB line ?
	 jae	 GDI_FOUNDHI	; Jump if so

; This device is in low DOS.
; Check for a 386LOAD stub.
; We will automatically instance devices that aren't mentioned by name
; in 386LOAD.CFG that are in SYSTEM.INI, via lines like LOCAL=CON.

; Scan through the high DOS arena looking for device entries

GDI_HISCAN0:
	 movzx	 edi,OVRMAC	; Get V86 segment of 1st UMB MAC entry
	 shl	 edi,(4-0)	; Convert from paras to linear address
GDI_HISCAN:
	 cmp	 [edi].MAC_OWNR,@MAC_DRV ; Is this MAC a device driver?
	 jne	 short GDI_HINEXT ; Skip to next MAC entry if not

; EDI ==> MAC entry for a device driver

	 mov	 ebx,edi	; Remember address of MAC entry
	 add	 edi,(type MAC_STR) ; Bump from MAC entry to device itself

; EDI ==> device driver

	 mov	 edx,edi	; Remember linear address of 1st device

GDI_HINEST:
	 test	 [edi].DD_ATTR,DRV_ATTR_CHAR ; Character device?
	 jz	 short GDI_HINEXT0 ; Skip if not a character device

	 REGSAVE <esi,edi>	; Save registers around REPE CMPSB

	 lea	 edi,[edi].DD_NAME ; Start of this device's name
	 mov	 ecx,8		; Length of name
	 cld			; Forward
	 repe cmpsb		; Check to see if it matches

	 REGREST <edi,esi>	; Restore registers

	 je	 short GDI_FOUNDOVR ; Jump if the names match

; The names don't match.  Check for a nested device

	 mov	 eax,[edi].DD_NEXT ; Get seg:off of next device
;;;;;;	 cmp	 eax,-1 	; Izit the end of a nested device?
	 cmp	 ax,-1		; Izit the end of a nested device?
	 je	 short GDI_HINEXT0 ; Go on to the next MAC entry if so

	 shr	 eax,16 	; Shift segment to low end
	 shl	 eax,(4-0)	; Convert from segment to linear address

	 cmp	 eax,edx	; Are the segments the same?
	 jne	 short GDI_HINEXT0 ; If not it can't be a nested device

; We've got a nested device

	 movzx	 eax,[edi].DD_NEXT.VOFF ; Get the offset
	 mov	 edi,edx	; Recover linear address of the 1st device
	 add	 edi,eax	; Advance to next device within nested device

	 jmp	 short GDI_HINEST ; Check this one's name

; We've got a matching device name.  Now let Aaron's original code handle it.

GDI_FOUNDOVR:
	 mov	 edi,ebx	; Recover address of MAC entry

ifdef @DEBUG
	 REGSAVE <eax,edx>	; Save registers

	 movzx	 eax,[edi].MAC_NPAR ; Get size in paragraphs
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 lea	 edx,[edi+size MAC_STR] ; Start of the device

	 call	 SHOW_INSTANCE_DEVICE ; Tell 'em about EDX and EAX

	 REGREST <edx,eax>	; Restore registers
endif				; IFDEF @DEBUG

	 jmp	 short GDI_FOUNDHI2	; Rejoin original code

; Skip to the next MAC entry

GDI_HINEXT0:
	 mov	 edi,ebx	; Recover address of MAC entry
GDI_HINEXT:
	 cmp	 [edi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short GDI_DEVBAD ; Yes, exit loop, and we didn't find it

	 movzx	 eax,[edi].MAC_NPAR ; # of paragraphs allocated to this entry
	 inc	 eax		; Add another paragraph for the MAC entry
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 add	 edi,eax	; Advance to the next MAC entry

	 jmp	 short GDI_HISCAN ; Continue on to next entry

; Device found in high DOS
; Check to see if the device has a valid device header

GDI_FOUNDHI:
	 sub	 edi,size MAC_STR ; Point to the device header

	 cmp	 [edi].MAC_TYPE,DEV_ARENA_TYPE ; Type for a device driver
	 jnz	 SHORT GDI_DevMayBeCombined ; May be a combined case

	 movzx	 eax,[edi].MAC_OWNR ; Get the owner
	 dec	 eax		; Back one up
	 shl	 eax,(4-0)	; Convert from paras to bytes

	 cmp	 eax,edi	; Correct owner ?
	 jnz	 SHORT GDI_DevMayBeCombined ; May be a combined case

; This device has a valid arena header.  However, if the previous device has
; the same segment start value as this one, then this device is the first
; in a combined list.

	 REGSAVE <ebx,edx>	; Save previous and current seg:off

	 shr	 ebx,16 	; Move previous segment to low end
	 shr	 edx,16 	; Move current segment to low end

	 cmp	 ebx,edx	; Are they the same?

	 REGREST <edx,ebx>	; Restore previous and current seg:off

	 jz	 short GDI_DevNotLastInMany ; 1st device of a combined list

; Return with a pointer to the start of the device in EDX and a size in
; EAX and carry clear.

GDI_FOUNDHI2:
	 movzx	 eax,[edi].MAC_NPAR ; Get size in paragraphs
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 lea	 edx,[edi+size MAC_STR] ; Start of the device
GDI_DevSuccess:
	 clc			; Indicate success
GDI_DEVXIT:
	 REGREST <edi,ecx,ebx>	; Restore caller's registers

	 ret			; Return to caller

GDI_DevExit:
GDI_DEVBAD:
	 stc			; Indicate device not found or not in a UMB

	 jmp	 short GDI_DEVXIT ; Join common exit code

; EDI points to the device arena which is either the first or one of the
; middle ones in a group of devices that have been loaded together.
; EDX has the seg:off of this device.
; EBX has the seg:off of the previous device.
; Their difference should give the size.

GDI_DevNotLastInMany:
	 cmp	 edx,ebx	; Are they linked in reverse order?
	 ja	 short GDI_DevExit ; Jump if they don't look right

	 add	 edi,size MAC_STR ; Point to the start of the device
	 xchg	 edx,edi	; EDX is the start of the device
	 mov	 eax,ebx	; Seg:off of previous device
	 sub	 eax,edi	; Difference of offsets, as the segs are equal

	 jmp	 short GDI_DevSuccess ; Join common return code

; This device does not have an associated arena header.  It may be either the
; middle one or the last one amongst a group of devices loaded together.
; EDX is the seg:off of the current device.
; EBX is the seg:off of the previous device.
; If the segments match, then this is a middle one and the
; difference of EBX and EDX is the size.

GDI_DevMayBeCombined:
	 REGSAVE <ebx,edx>	; Save previous and current seg:off

	 shr	 ebx,16 	; Move segment of previous device to low end
	 shr	 edx,16 	; Move segment of current device to low end

	 cmp	 ebx,edx	; Are they the same?

	 REGREST <edx,ebx>	; Restore the current and previous seg:off

	 jz	 short GDI_DevNotLastInMany ; Middle device in group

; This device could be the last one in the chain.
; We scan forward and see when we get a case where a device has the same
; segment as well as a device header.

	 add	 edi,size MAC_STR ; Advance to the device header
GDI_DevScanFwd:
	 mov	 eax,[edi].DD_NEXT ; Get pointer to next device
	 shr	 eax,16 	; Move segment to low end

	 push	 edx		; Save current device's seg:off
	 shr	 edx,16 	; Move segment to low end
	 cmp	 eax,edx	; Still the same?
	 pop	 edx		; Restore current device's seg:off

	 jnz	 short GDI_DevIsItTheFirst ; Did we get the 1st one

	 mov	 edi,[edi].DD_NEXT ; Get pointer to next device
	 movzx	 ecx,di 	; Offset of device
	 shr	 edi,16 	; Move segment to low end
	 shl	 edi,4		; Convert from paras to bytes
	 add	 edi,ecx	; EDI is Winlinaddr of device

	 jmp	 short GDI_DevScanFwd ; Keep going

; EDI should now be pointing to the 1st device in the group of devices.
; Check to see if the device has a valid arena header

GDI_DevIsItTheFirst:
	 sub	 edi,size MAC_STR ; Point to the arena entry
	 cmp	 [edi].MAC_TYPE,DEV_ARENA_TYPE ; Type for a device driver?
;;;;;;	 jnz	 short GDI_DevExit ; Don't know about this one
	 jnz	 GDI_HISCAN0	   ; Don't know about this one

	 movzx	 eax,[edi].MAC_OWNR ; Get the owner
	 dec	 eax		; Back up to the arena
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 cmp	 eax,edi	; Correct owner?
;;;;;;	 jnz	 short GDI_DevExit ; Don't know about this one
	 jnz	 GDI_HISCAN0	   ; Don't know about this one

; EDI points to the arena.  Get the size of the combined device

	 movzx	 eax,[edi].MAC_NPAR ; Get size in paragraphs
	 shl	 eax,(4-0)	; Convert from paras to bytes
	 movzx	 edx,dx 	; Get offset of current device
	 sub	 eax,ebx	; Size of current device
	 shr	 edx,16 	; Segment of device
	 shl	 edx,4		; Convert from paras to bytes
	 add	 edx,ebx	; Winlinaddr of the device

	 jmp	 short GDI_DevSuccess ; Join common exit code

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  Get_Device_Info	; End Get_Device_Info procedure

VxD_ICODE_ENDS			; End _ITEXT segment

	 page
VxD_CODE_SEG			; Begin _LTEXT segment
	 assume  cs:FLAT	; Tell the assembler

BeginProc Get_Hooks_To_Install
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Get_Hooks_To_Install

DESCRIPTION:
	This routine specifies which optional LoadHi functions are
	to be installed on Windows versions >= 3.10.

	Note that this function may be called more than once!
	Note that this function is not called if Windows version is < 3.10.

ENTRY:
	AX - VMM version # of Windows running

	This is >= 030Ah.  This routine is not called if the
	VMM version is < 030Ah.

	EDX - Device reference data set by real mode init.

EXIT:
	EAX = Option Install flags

	Bit 0 - DOSMGR_Instance_Device hook bit. If bit 0 is set
		this hook will be installed.

	Bit 1 - Set up UMBs bit. If bit 1 is set, the LoadHi Vxd
		is responsible for setting up the UMB page map.
		If the bit is clear, either there are no UMBs, or
		the LIM/UMBulator has specified the UMB import via
		the 1.11 PAGING IMPORT so this functionality of the
		LoadHi VxD is not needed.

	 All other bits must be 0

USES:
	Flags, EAX, EDX

|

	 REGSAVE <edx>		; Save caller's registers

	 sub	 eax,eax	; Initialize the return flags to zero

; If it's Windows 3.10, and we're updating 386MAX 5.10 - 5.12,
; we need to attach the high DOS.

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_DATA_STR
	 test	 [edx].REF_UPDFLAG,@UPD_UPDATE ; Are we updating an old 386MAX?
	 jz	 short @F	; Nope

	 or	 al,02h 	; Setup UMBs
@@:
	 or	 al,01h 	; Install the DOSMGR_Instance_Device function

	 REGREST <edx>		; Restore caller's registers

	 ret			; ... to LoadHi

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  Get_Hooks_To_Install	; End Get_Hooks_To_Install procedure
	 page
BeginProc Get_Mapped_Page_Num
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Get_Mapped_Page_Num

DESCRIPTION:
	Convert a UMB page number in EAX into the physical page
	that gets mapped there, in EDX.

	Note that this routine is not called if the VMM version
	is >= 3.10 and the Get_Hooks_To_Install routine returned
	with bit 1 clear.

ENTRY:
	EAX - Page number in the range of pages that have UMBs.

EXIT:
	EAX - Entry time EAX
	EDX - Page that is mapped into the page num in EAX (0 if
		no page is mapped in there.

USES:
	EDX, Flags

|

	 REGSAVE <eax>		; Save input UMB page #

	 cmp	 OVRMAC,-1	; OVRMAC == 0FFFFh if there are no UMBs
	 je	 MAP_NOTUMB	; Return EDX=0 if not a UMB page

	 mov	 edx,PDIR_LIN	; Get linear address of 386MAX's PTEs
	 mov	 edx,[edx+eax*4] ; Get PTE for page of interest

	 bt	 HIGHDOS_MAP,eax	; Is this a high DOS memory page?
	 jnc	 short MAP_NOTUMB	; Jump if not

	 test	 PMI_FLAG,@PMI_VIRT_HIGHDOS ; Are we supporting VirtualHighDOS?
	 jnz	 short @F	; Jump if so

; We are not supporting Virtual High DOS, so don't assign free high DOS pages

;;;;;;	 bt	 HIGHDOS_FREE_MAP,eax	; Is this a free high DOS memory page?
;;;;;;	 jc	 short MAP_NOTUMB	; Jump if so
@@:

;;;;;;	 test	 edx,mask $PTE_AV0	; Is this an EMS mappable page?
;;;;;;	 jnz	 short MAP_NOTUMB	; Yes, so its not a UMB page
;;;;;;
;;;;;;	 test	 edx,mask $PTE_RW	; Is this a ROM?
;;;;;;	 jz	 short MAP_NOTUMB	; Yes, so its not a UMB page

;;;;;;	 and	 edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	 shr	 edx,(12-0)	; Isolate and convert to physical page #

	 cmp	 edx,eax	; Is it mapped 1:1?
	 je	 short MAP_UMB	; Return with EDX physical page number

; We've got a page that is not mapped 1:1.
; If VGASWAP is in effect, it might be a relocated memory-mapped I/O page

ifdef @VGASWAP
	 call	 CHK_FLEX_IO	; Check page # in EAX for memory-mapped I/O
				; Returns carry set if page is I/O
	 jc	 short MAP_NOTUMB ; Return to caller with EDX=0 if an I/O page
endif				; IFDEF @VGASWAP

; The LoadHi VxD will do an Assign_Device_V86_Pages on this page.
; Set a bit so we'll later remember it has been assigned.

MAP_UMB:
	 sub	 eax,0A0h	; Bitmap starts at page A0h.
	 bts	 ASSIGN_BMP,eax ; Set bit for this page

	 jmp	 short MAP_XIT	; Rejoin common code

MAP_NOTUMB:
	 sub	 edx,edx	; Zero indicates not UMB page
MAP_XIT:
	 REGREST <eax>		; Restore UMB page #

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  Get_Mapped_Page_Num	; End Get_Mapped_Page_Num procedure

VxD_CODE_ENDS			; End _LTEXT segment

	 MEND			; End VMAX_LHI module
