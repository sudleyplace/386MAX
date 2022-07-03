;'$Header:   P:/PVCS/MAX/VXD/VMAX_VDD.ASV   1.0   05 Sep 1995 17:21:12   HENRY  $
	 title	 VMAX_VDD --  VDD Related Routines
	 page	 78,130
	 name	 VMAX_VDD

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-93 Qualitas, Inc.  GNU General Public License version 3.

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

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
	 include VDD.INC	; From the SDK/DDK (Used by PATCH_XGA)

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include OPCODES.INC
	 include MAC.INC
	 include ROMSEG.INC	; For adapter ROMs

	 include QMAX_FLX.INC
	 include QMAXWIN3.INC

	 include BREAK.INC
	 include VMAX.INC
	 include VMAX_VID.INC
.list

; The following two definitions are from the VDD real mode init

fVid_PVGA	equ	00000004h ; Running on Paradise VGA (more regs)
fVid_PVGARom	equ	00010000h ; Paradise VGA ROM (Exclude C600-C7FF)

VxD_DATA_SEG			; Begin _DATA segment

	 extrn	 PDIR_LIN:dword ; In VMAX.ASM
	 extrn	 CON_C0000:dword

ifdef @VGASWAP
	 extrn	 FLEXROM_LIN:dword
	 extrn	 FLEXROM_CNT:word
	 extrn	 MSG_FLEX1:byte, MSG_FLEX1_H1:byte
	 extrn	 MSG_FLEX2:byte, MSG_FLEX2_H1:byte, MSG_FLEX2_H2:byte
	 extrn	 MSG_FTL_FLEX1:byte
	 extrn	 MSG_FTL_FLEX3:byte
endif				; IFDEF @VGASWAP

VxD_DATA_ENDS			; End _DATA segment


VxD_CODE_SEG			; Begin _TEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 PHYS2LIN:near

VxD_CODE_ENDS			; End _TEXT segment


VxD_LOCKED_CODE_SEG		; Begin _LTEXT segment
	 assume  cs:FLAT	; Tell the assembler

VxD_LOCKED_CODE_ENDS		; End _LTEXT segment

	 page
VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 extrn	 LoadHi_DDB:tbyte ; Reference data

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 extrn	 REF_LIN:dword	; ==> reference data structure

	 extrn	 DEVICE_LIST:dword ; ==> to DEVICE_LIST (ECX on VxD entry)

	 extrn	 ASSIGN_BMP:dword

	 public  VDD_FLAG
VDD_FLAG dw	 ?		; Flags for the HOOK_VDD apparatus

@VF_CP_HOOKED	 equ	8000h	; VDD's Control_Proc is hooked
@VF_PARADISE31	 equ	4000h	; Paradise 90C31? chipset
@VF_GDPA_HOOKED  equ	2000h	; We've hooked _Get_Device_V86_Pages_Array
@VF_ADVP_HOOKED  equ	1000h	; We've hooked _Assign_Device_V86_Pages
@VF_PIV_HOOKED	 equ	0800h	; We've hooked _PhysIntoV86

	 public  VDD_COUNT
VDD_COUNT dw	 ?		; Non-zero if we're in the VDD

OLD_RETURN_EIP	 dd	?	; Caller's return EIP

OLD_VDD_CONTROL_PROC dd ?	; Address of original VDD procedure
OLD_GET_DEVICE_V86_PAGES_ARRAY dd ? ; Address of original VMM procedure
OLD_ASSIGN_DEVICE_V86_PAGES dd ? ; Address of original VMM procedure
OLD_PHYS_INTO_V86 dd	?	; Address of original VMM procedure

VDD_NAME	db	'VDD     ' ; Device name of standard VDD

VxD_LOCKED_DATA_ENDS		; End _LDATA segment

	 page
VxD_IDATA_SEG			; Begin _IDATA segment

	 extrn	 PMI_PAGE_MAP:dword
	 extrn	 MSG_MPTL5_UGH:byte

STR_PARADISE	 db	'PARADISE'
@STR_PARADISE_L  equ	$-STR_PARADISE

STR_WDIGITAL	 db	'WESTERN DIGITAL'
@STR_WDIGITAL_L  equ	$-STR_WDIGITAL

STR_STB 	 db	' STB '
@STR_STB_L	 equ	$-STR_STB

TYPESTRNG	db	'VIDEOVGA'

MSG_HOOK_VDD	db	'    VDD_Get_Version = '
MSG_HOOK_VDD_X	db	'xxxxxxxx', CR, LF, 0

XGAVDD_NAME	db	'VDD     ' ; Device name of IBM XGA VDD

XGAVDD_CONTROL	 label	byte	; Model of XGAVDD control dispatch code
	 db	 083h, 0F8h, 011h	; cmp	eax,11
	 db	 077h, 00Dh		; ja	exit
	 db	 083h, 0E8h, 000h	; sub	eax,0
	 db	 072h, 008h		; jc	exit
	 db	 02Eh, 0FFh, 024h, 085h ; jmpn	cs:[eax*4+jmptab]
XGAVDD_CONTROL_LEN equ	$-XGAVDD_CONTROL ; Length of above code

XGAVDD_SCI_OFF	 equ	1F2h	; Offset with SysCriticalInit to XGA code
XGAVDD_SCI	 label	byte	; Model of defective code in XGA
	 db	 08Ah, 006h		; mov	al,[esi]
	 db	 0A8h, 001h		; test	al,1
	 db	 074h, 005h		; jz	short GIVE_DEVICE_CONFLICT
	 db	 0EBh, 03Bh		; jmp	short OK
	 db	 090h, 090h, 090h	; nop
	 db	 033h, 0C0h		; xor	eax,eax
	 db	 08Bh, 035h		; mov	esi,[xxxxxxxx]
XGAVDD_SCI_LEN	 equ	$-XGAVDD_SCI	; Length of above code

XGAVDD_PATCHOFF  equ	1F6h	; Offset to patched instruction

VxD_IDATA_ENDS			; End _IDATA segment

	 page
VxD_ICODE_SEG			; Begin _ITEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 TEST_PAGEMAP:near

BeginProc PATCH_XGA		; Find and patch IBM XGA
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

PATCH_XGA

DESCRIPTION:
	Trundle through the Device_List, find the VDD.	If it is the IBM
	XGAVDD, and the model code looks right, patch it to avoid spurious
	Video Device Conflicts.

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

	 mov	 edx,DEVICE_LIST ; ==> linked list of VxD_Desc_Block structs
PXGA_NXT:
	 mov	 edx,[edx].DDB_Next ; Get pointer to next VXD in chain
;;;;;;	 cmp	 [edx].DDB_Next,0 ; Is it the end of the list?
	 or	 edx,edx	; Is it the end of the list?
	 stc			; Assume it didn't work
	 jz	 short PXGA_XIT ; Yes, exit the loop

	 cmp	 [edx].DDB_Req_Device_Number,VDD_Device_ID ; Is it the right ID?
	 jne	 short PXGA_NXT ; No, skip to next link

	 mov	 ecx,8		; Length of a device name
	 lea	 esi,[edx].DDB_Name ; Get address of name
	 mov	 edi,OFFSET32 XGAVDD_NAME ; Pointer to 'VDD     '
    repe cmpsb			; Compare the names
	 jne	 short PXGA_NXT ; Jump to try next link if they don't match

; We've got our boy

	 mov	 esi,[edx].DDB_Control_Proc ; Get address of control procedure
	 mov	 edi,OFFSET32 XGAVDD_CONTROL ; ==> control code to compare
	 mov	 ecx,XGAVDD_CONTROL_LEN ; Length to compare
    repe cmpsb			; Compare the control dispatch code
	 stc			; Assume it didn't work
	 jne	 short PXGA_XIT ; Exit if we can't patch it

	 mov	 esi,[esi]	; Pick up address of jump table
	 mov	 esi,[esi]	; Pick up address of XGAVDD_Sys_Critical_Init
	 mov	 edx,esi	; Save address for patching
	 add	 esi,XGAVDD_SCI_OFF ; Bump down to code of interest
	 mov	 edi,OFFSET32 XGAVDD_SCI ; ==> SysCriticalInit code to compare
	 mov	 ecx,XGAVDD_SCI_LEN ; Length to compare
    repe cmpsb			; Compare the SysCriticalInit code
	 stc			; Assume it didn't work
	 jne	 short PXGA_XIT ; Exit if we can't patch it

; The code matches, patch it
	 add	 edx,XGAVDD_PATCHOFF ; Bump to the byte that needs patching
	 mov	 [edx].LO,@OPCOD_JMPS ; Change from JZ to JMP

	 clc			; Indicate we patched it
PXGA_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  PATCH_XGA		; End PATCH_XGA procedure

BeginProc EXCLUDE_PVGA		; Keep WIN386 away from pages C6 and C7
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

EXCLUDE_PVGA

DESCRIPTION:
	On some systems with the VGA on the motherboard, using the Paradise
	Super VGA chipset w/o the Paradise BIOS, WIN386 may take over pages
	C6 and/or C7 for its own purposes, fouling up the video.

	An EMMExclude=C600-C6FF will fix the problem.

	This code roots out the situation and assigns the pages to keep
	WIN386 away from 'em.

|

	 REGSAVE <eax,edx>	; Save caller's registers

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 test	 [edx].REF_VIDFLAG,@VID_PVGAROM ; Izit a WD or Paradise ROM?
	 jz	 short @F	; Jump if not

	 or	 VDD_FLAG,@VF_PARADISE31 ; Check for 3CFh in DX
@@:
	 test	 [edx].REF_VIDFLAG,@VID_CACHEDPVGA ; Have we cached ROMs
				; ... on a Paradise chipset?
	 jz	 short EXPVGA_XIT ; Nope

; Check for bogus flags on input to VDD SysCriticalInit
	 or	 VDD_FLAG,@VF_PARADISE31 ; Check for 3CFh in DX

; Examine global bitmap to see if someone else has assigned C6 or C7

	 mov	 edx,0C6000h	; Page C6h
	 call	 TEST_PAGEMAP	; Test PMI_PAGE_MAP - EDX is V86 linear address
	 jc	 short EXPVGA_XIT ; Jump if its not available

	 mov	 edx,0C7000h	; Page C7h
	 call	 TEST_PAGEMAP	; Test PMI_PAGE_MAP - EDX is V86 linear address
	 jc	 short EXPVGA_XIT ; Jump if its not available

; Examine our local bitmap to see if we've assigned C6 or C7

	 mov	 edx,0C6h-0A0h	; Page C6h, origin A0h.
	 bt	 ASSIGN_BMP,edx ; Test bit for page C6
	 jc	 short EXPVGA_XIT ; Give up if it's already taken

	 mov	 edx,0C7h-0A0h	; Page C7h, origin A0h.
	 bt	 ASSIGN_BMP,edx ; Test bit for page C7
	 jc	 short EXPVGA_XIT ; Give up if it's already taken

; Assign pages C6 and C7

	 sub	 eax,eax	; A handy zero
	 push	 ecx		; Save ECX since Aaron will trash it

;					   V86 page #
;					   |	Count
;					   |	|    Global assignment
;					   |	|    |	  Flags
;					   |	|    |	  |
	 VMMcall _Assign_Device_V86_Pages <0C6h, 2, eax, eax>
	 pop	 ecx		; Restore ECX

; Totally ignore the error return code.  If this doesn't do the trick,
; let 'em stick an EMMExclude=C600-C6FF in SYSTEM.INI.

EXPVGA_XIT:
	 REGREST <edx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  EXCLUDE_PVGA		; End EXCLUDE_PVGA procedure

ifdef @VGASWAP
	 page
BeginProc HOOK_VDD_SYSCRITINIT	; Install hooks for VDD and VGASWAP
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

HOOK_VDD_SYSCRITINIT

DESCRIPTION:
	Trundle through the Device_List and find the VDD.
	Hook into its control procedure

	Hook into VMM _Get_Device_V86_Pages_Array
	Hook into VMM _Assign_Device_V86_Pages
	Hook into VMM _PhysIntoV86

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

	 VxDcall VDD_Get_Version ; AH:AL is version, ESI ==> 8-byte ID

	 push	 esi		; Save pointer to ID string

	 mov	 ecx,8		; Length of a device name
	 mov	 edi,OFFSET32 MSG_HOOK_VDD_X ; ==> to hole in message text
S32	 rep movsb		; Copy ID string in message

	 mov	 esi,OFFSET32 MSG_HOOK_VDD ; ==> message text
	 call	 DISPLAY	; Print it on the monochrome

	 pop	 esi		; Restore pointer to ID string

	 mov	 ecx,8		; Length of a device name
	 mov	 edi,OFFSET32 TYPESTRNG ; ==> 'VIDEOVGA'
    repe cmpsb			; Compare the names

	 mov	 edx,DEVICE_LIST ; ==> linked list of VxD_Desc_Block structs
HKVDD_NXT:
	 mov	 edx,[edx].DDB_Next ; Get pointer to next VXD in chain
;;;;;;	 cmp	 [edx].DDB_Next,0 ; Is it the end of the list?
	 or	 edx,edx	; Is it the end of the list?
	 stc			; Assume it didn't work
	 jz	 HKVDD_XIT	; Yes, exit the loop

	 cmp	 [edx].DDB_Req_Device_Number,VDD_Device_ID ; Is it the right ID?
	 jne	 short HKVDD_NXT ; No, skip to next link

	 mov	 ecx,8		; Length of a device name
	 lea	 esi,[edx].DDB_Name ; Get address of name
	 mov	 edi,OFFSET32 VDD_NAME ; Pointer to 'VDD     '
    repe cmpsb			; Compare the names
	 jne	 short HKVDD_NXT ; Jump to try next link if they don't match

; We've got our boy.  EDX ==> VxD_Desc_Block for the VDD.

; Replace the DDB_Control_Proc address with our local VDD_CONTROL_PROC

	 mov	 eax,OFFSET32 LCL_VDD_CONTROL_PROC ; Address of our local proc
	 xchg	 eax,[edx].DDB_Control_Proc ; Swap with original
	 mov	 OLD_VDD_CONTROL_PROC,eax ; Save it for replacement later

	 or	 VDD_FLAG,@VF_CP_HOOKED ; Indicate we've hooked it

; Hook into the _Get_Device_V86_Pages_Array VMMcall

	 mov	 eax,_Get_Device_V86_Pages_Array ; Dynalink for service to steal
	 mov	 esi,OFFSET32 LCL_GET_DEVICE_V86_PAGES_ARRAY ; ==> local handler
	 VMMcall Hook_Device_Service ; Hook in new handler, return old in ESI
	 jc	 short HKVDD_XIT ; Return w/o patching anything

	 mov	 OLD_GET_DEVICE_V86_PAGES_ARRAY,esi ; Save original handler

	 or	 VDD_FLAG,@VF_GDPA_HOOKED ; Indicate we've hooked it

; Hook into the _Assign_Device_V86_Pages VMMcall

	 mov	 eax,_Assign_Device_V86_Pages ; Dynalink for service to steal
	 mov	 esi,OFFSET32 LCL_ASSIGN_DEVICE_V86_PAGES ; ==> local handler
	 VMMcall Hook_Device_Service ; Hook in new handler, return old in ESI
	 jc	 short HKVDD_XIT ; Return w/o patching anything

	 mov	 OLD_ASSIGN_DEVICE_V86_PAGES,esi ; Save original handler

	 or	 VDD_FLAG,@VF_ADVP_HOOKED ; Indicate we've hooked it

HKVDD_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  HOOK_VDD_SYSCRITINIT	; End HOOK_VDD_SYSCRITINIT procedure
endif				; IFDEF @VGASWAP

BeginProc CHK_VIDEO_ROMS	; Examine VGA BIOS ROMs for signatures
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

CHK_VIDEO_ROMS

DESCRIPTION:
	Scan the VGA BIOS ROM looking for signatures identifying
	problematic adapters.

EXIT:
	REF_VIDFLAG set as appropriate if a special adapter was found.


|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

	 push	 CON_C0000	; Address of ROM with VGASWAP taken into account
	 push	 4096		; Length to map
	 call	 PHYS2LIN	; Get Windows linear address of ROM

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Skip error if it worked

; Tell 'em MapPhysToLinear failed and return to LoadHi VxD

	 mov	 esi,OFFSET32 MSG_MPTL5_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 mov	 esi,eax	; Copy ROM linear address to proper register

; Check for 'PARADISE'

	 mov	 ecx,128	; Limit searches to 1st 128 bytes
	 mov	 edi,OFFSET32 STR_PARADISE ; Linear address of 'PARADISE'
	 mov	 edx,@STR_PARADISE_L ; Length of above string
	 call	 SCAN_FOR_SIG	; Scan the ROM for 'PARADISE'
	 jnz	 short @F	; Skip setting bit if not found

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 or	 [edx].REF_VIDFLAG,@VID_PVGA+@VID_PVGAROM ; Indicate we found it
@@:

; Check for 'WESTERN DIGITAL'

	 mov	 ecx,128	; Limit searches to 1st 128 bytes
	 mov	 edi,OFFSET32 STR_WDIGITAL ; Linear address of 'WESTERN DIGITAL'
	 mov	 edx,@STR_WDIGITAL_L ; Length of above string
	 call	 SCAN_FOR_SIG	; Scan the ROM for 'WESTERN DIGITAL'
	 jnz	 short @F	; Skip setting bit if not found

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 or	 [edx].REF_VIDFLAG,@VID_PVGA+@VID_PVGAROM ; Indicate we found it
@@:

; Check for ' STB '

	 mov	 ecx,256	; Limit searches to 1st 256 bytes
	 mov	 edi,OFFSET32 STR_STB ; Linear address of ' STB '
	 mov	 edx,@STR_STB_L ; Length of above string
	 call	 SCAN_FOR_SIG	; Scan the ROM for ' STB '
	 jnz	 short CVR_XSTB ; Skip setting bit if not found

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_STR
	 or	 [edx].REF_VIDFLAG,@VID_STBROM ; Indicate we found it

; The STB VGA with Tseng Labs chipset uses B000-B7FF, we assign the pages
; so WIN386 won't try to use 'em as mapping buffers.

	 test	 [edx].REF_VIDFLAG,@VID_TLVGA ; Izit a Tseng Labs VGA chipset?
	 jz	 short CVR_XSTB ; Nope

;;;;;;	 BREAK			; Call the debugger FIXME

; If SWATVXD is installed, its likely that B0 is already assigned for the
; debugging output sent to the mono screen.  If we simply try to assign
; B0 for 8 pages the call will fail and none of the pages will get assigned.
; Try the assignment in two calls, to maximize the number of pages we
; actually get assigned.

	 VMMcall _Assign_Device_V86_Pages <0B0h, 1, 0, 0> ; Globally
	 or	 eax,eax	; Did we get the assignment?
	 jz	 short @F	; Jump if not

; Set bit so we'll later remember that we've assigned the B0 page

	 mov	 eax,(0B0h-0A0h) ; Page # B0
	 bts	 ASSIGN_BMP,eax ; Set bit
@@:
	 VMMcall _Assign_Device_V86_Pages <0B1h, 7, 0, 0> ; Globally
	 or	 eax,eax	; Did we get the assignment?
	 jz	 short @F	; Jump if not

; Set bits so we'll later remember that we've assigned the B1-B7 pages

	 or	 ASSIGN_BMP+((0B0h-0A0h)/8).LO,11111110b ; Set bits for B1-B7
@@:
CVR_XSTB:
	 clc			; Indicate it worked OK
CVR_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  CHK_VIDEO_ROMS 	; End CHK_VIDEO_ROMS procedure

BeginProc SCAN_FOR_SIG		; Look through a range looking for a signature
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

SCAN_FOR_SIG

DESCRIPTION:
	Scan through a range of memory looking for a signature

ENTRY:
	ESI = Linear address of start of range to look for
	ECX = Length of range
	EDI = Linear address of signature string for which to search
	EDX = Length of signature

EXIT:
	Zero flag set if we found the signature.

|

	 REGSAVE <esi>		; Save caller's register
@@:
	 REGSAVE <ecx,esi,edi>	; Save length of range and addresses

	 mov	 ecx,edx	; Get length of signature into proper register

    repe cmpsb			; Izit our boy?

	 REGREST <edi,esi,ecx>	; Restore length of range and addresses

	 je	 short @F	; Yup, exit loop (with zero flag set)

	 inc	 esi		; Bump to next byte in ROM
	 loop	 @B		; Try 'em all

	 or	 edx,edx	; Ensure zero flag not set for return
@@:
	 REGREST <esi>		; Restore caller's register

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  SCAN_FOR_SIG		; End SCAN_FOR_SIG procedure

VxD_ICODE_ENDS			; End _ITEXT segment

	 page
VxD_CODE_SEG			; Begin _LTEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 DISPLAY:near	; VMAX_DBG.ASM
	 extrn	 TOHEX:near	; VMAX_DBG.ASM

ifdef @VGASWAP
BeginProc UNHOOK_VDD		; Remove hooks for VDD and VGASWAP
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

UNHOOK_VDD

DESCRIPTION:
	Replace the original VDD Control_Proc

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

	 mov	 edx,DEVICE_LIST ; ==> linked list of VxD_Desc_Block structs
UHKVDD_NXT:
	 mov	 edx,[edx].DDB_Next ; Get pointer to next VXD in chain
;;;;;;	 cmp	 [edx].DDB_Next,0 ; Is it the end of the list?
	 or	 edx,edx	; Is it the end of the list?
	 stc			; Assume it didn't work
	 jz	 short UHKVDD_XIT ; Yes, exit the loop

	 cmp	 [edx].DDB_Req_Device_Number,VDD_Device_ID ; Is it the right ID?
	 jne	 short UHKVDD_NXT ; No, skip to next link

	 mov	 ecx,8		; Length of a device name
	 lea	 esi,[edx].DDB_Name ; Get address of name
	 mov	 edi,OFFSET32 VDD_NAME ; Pointer to 'VDD     '
    repe cmpsb			; Compare the names
	 jne	 short UHKVDD_NXT ; Jump to try next link if they don't match

; We've got our boy.  EDX ==> VxD_Desc_Block for the VDD.

	 mov	 eax,OLD_VDD_CONTROL_PROC ; Get original VDD Control_Proc
	 mov	 [edx].DDB_Control_Proc,eax ; Replace it in the device chain

	 and	 VDD_FLAG,not @VF_CP_HOOKED ; Indicate we've NOT hooked it

UHKVDD_XIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  UNHOOK_VDD		; End UNHOOK_VDD procedure
endif				; IFDEF @VGASWAP

ifdef @VGASWAP
	 page
BeginProc LCL_VDD_CONTROL_PROC	; Local replacement for VDD's Control_Proc
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

LCL_VDD_CONTROL_PROC

DESCRIPTION:
	Local replacement for the VDD's Control_Proc

	Set IN_VDD flag.
	Call original VDD Control_Proc
	Reset IN_VDD flag.

|

	 pushfd 		; Save flags

	 test	 VDD_FLAG,@VF_CP_HOOKED ; Have we hooked the Control_Proc
	 jnz	 short @F	; Yes, so that's OK

ifdef @DEBUG
	 push	 esi		; Save caller's register

	 mov	 esi,OFFSET32 MSG_FTL_FLEX1 ; ==> message text
	 call	 DISPLAY	; Send it to SWATVXD

	 pop	 esi		; Restore caller's register

	 BREAK			; Huh?	We shouldn't have received control
else
	 mov	 esi,OFFSET32 MSG_FTL_FLEX1 ; Text of error message
	 call	 DISPLAY	; Send it to SWATVXD

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
endif				; IFDEF @DEBUG
@@:
	 cmp	 VDD_COUNT,0	; Are we already in the VDD
	 jz	 short @F	; Nope, so that's OK

ifdef @DEBUG
	 push	 esi		; Save caller's register

	 mov	 esi,OFFSET32 MSG_FTL_FLEX3 ; ==> message text
	 call	 DISPLAY	; Send it to SWATVXD

	 pop	 esi		; Restore caller's register
endif				; IFDEF @DEBUG
@@:
	 inc	 VDD_COUNT	; Indicate VMMcalls are coming from the VDD

; Hook into the _PhysIntoV86 VMMcall
; Hooking here rather than globally fixes the WINA20 low DOS bug in 6.00.

	 cmp	 VDD_COUNT,1		; Have we already hooked it?
	 ja	 short LVCP_XHOOK	; Skip rehooking if so

	 REGSAVE <eax,ecx,edx,esi>	; Save VDD's registers
				; ECX & EDX are trashed by many VMM services

	 mov	 eax,_PhysIntoV86 ; Dynalink for service to steal
	 mov	 esi,OFFSET32 LCL_PHYS_INTO_V86 ; ==> local handler
	 VMMcall Hook_Device_Service ; Hook in new handler, return old in ESI
	 jnc	 short @F	; Skip if no error

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG

; Complain and terminate Windows if the hook failed

	 mov	 esi,OFFSET32 MSG_FTL_FLEX1 ; Text of error message
	 call	 DISPLAY	; Send it to SWATVXD

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 mov	 OLD_PHYS_INTO_V86,esi ; Save original handler

	 or	 VDD_FLAG,@VF_PIV_HOOKED ; Indicate we've hooked it

	 REGREST <esi,edx,ecx,eax> ; Restore caller's registers

; If we have a Paradise chipset (such as the Compaq Prolinea series uses)
; the VDD sets DX to 3CF (this is recognizably left over from IN AL,DX)
; then tests bit 1 (among others).  If bit 1 is set, the VDD will attempt
; to allocate C6-C8.  When this fails (as it invariably will) it craps
; out with a "Video Device Conflict."

; Bit 16 is used by the real mode init code to indicate that a 32K ROM
; is present and the VDD needs to grab it.  We need to mask it off to
; prevent a video device conflict.

	 test	 VDD_FLAG,@VF_PARADISE31 ; Izit one of these chipsets with
				; the overzealous VDD?
	 jz	 short LVCP_XHOOK ; Jump if not

	 push	 edx		; Save for a moment

	 and	 dx,7fffh	; Isolate low order 15 bits
	 cmp	 dx,03cfh	; Izit left over from IN AL,DX?

	 pop	 edx		; Restore

	 jne	 short LVCP_XHOOK ; Jump if not

	 and	 edx,not 103ffh ; Clear spurious low order bits and bit 16
LVCP_XHOOK:

	 popfd			; Restore flags

	 call	 OLD_VDD_CONTROL_PROC ; Call the original

	 pushfd 		; Save return error indicator

	 dec	 VDD_COUNT	; Indicate VMMcalls are NOT coming from the VDD
	 jnz	 short LVCP_XUNHOOK	; Unhook only on the last recursion

; Unhook the _PhysIntoV86 VMMcall
; Unhooking here rather than globally fixes the WINA20 low DOS bug in 6.00.

	 REGSAVE <eax,ecx,edx,esi> ; Save VDD's registers
				; ECX & EDX are trashed by many VMM services

	 test	 VDD_FLAG,@VF_PIV_HOOKED ; Have we hooked it?
	 jnz	 short @F	; Jump if so

; Should never get here with the _PhysIntoV86 VMMcall unhooked.
; Something's really fouled up

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG
@@:
	 mov	 eax,_PhysIntoV86 ; Dynalink for service to steal
	 mov	 esi,OLD_PHYS_INTO_V86 ; Address of original handler
	 VMMcall Hook_Device_Service ; Replace original handler
	 jnc	 short @F	; Skip if no error

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG
@@:
	 and	 VDD_FLAG,(not @VF_PIV_HOOKED) ; Indicate we've replaced it

	 REGREST <esi,edx,ecx,eax> ; Restore caller's registers
LVCP_XUNHOOK:

	 popfd			; Restore return error indicator

	 ret			; Return to caller (VDD)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  LCL_VDD_CONTROL_PROC	; End LCL_VDD_CONTROL_PROC procedure
endif				; IFDEF @VGASWAP

ifdef @VGASWAP
	 page
BeginProc LCL_GET_DEVICE_V86_PAGES_ARRAY ; Local _Get_Device_V86_Pages_Array
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

LCL_GET_DEVICE_V86_PAGES_ARRAY

DESCRIPTION:
	Local replacement for the VMM _Get_Device_V86_Pages_Array

|

	 cmp	 VDD_COUNT,0	; Are we in the VDD
	 jnz	 short @F	; Jump to special code if so

; Jump to the original handler if we aren't in the VDD
; Control will return to the original caller

	 jmp	 OLD_GET_DEVICE_V86_PAGES_ARRAY ; Call the original
@@:

; First we must pop the caller's return address so the stacked will be
; presented to the original handler with the arguments in the proper places.

	 pop	 OLD_RETURN_EIP ; Save for restoration later

	 call	 OLD_GET_DEVICE_V86_PAGES_ARRAY ; Call the original

	 push	 OLD_RETURN_EIP ; Restore the stack

	 or	 eax,eax	; Non-zero EAX indicates success
	 jz	 short LCL_GDVP_RET ; Jump if error

; If we detected pesky special VGAs that tend to generate video device conflict,
; we need to edit the Device_V86_Pages_Array returned by WIN386.EXE

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

GDVP_STR struc			; Structure to access arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
GDVP_VMHANDLE dd ?		; VM handle
GDVP_BUFPTR dd	 ?		; Pointer to buffer
GDVP_FLAGS dd	 ?		; Flags

GDVP_STR ends			; End GDVP_STR structure

	 REGSAVE <eax,edx,esi>	; Save caller's registers

	 mov	 edx,0C6h-0A0h	; V86 page # (bitmap starts with page A0)
	 bt	 ASSIGN_BMP,edx ; Do we have that page assigned?
	 jnc	 short @F	; Nope, so don't lie about it

	 mov	 edx,0C6h	; V86 page #
	 mov	 eax,edx	; Copy page # to EAX
	 and	 eax,1Fh	; Bit # MOD 32
	 shr	 edx,(5-0)	; Convert page # to map index

	 mov	 esi,[ebp].GDVP_BUFPTR ; ==> Device_V86_Pages_Array
	 btr	 [esi+edx*4],eax ; Reset bit for page 0C6h
@@:
	 mov	 edx,0C7h-0A0h	; V86 page # (bitmap starts with page A0)
	 bt	 ASSIGN_BMP,edx ; Do we have that page assigned?
	 jnc	 short @F	; Nope, so don't lie about it

	 mov	 edx,0C7h	; V86 page #
	 mov	 eax,edx	; Copy page # to EAX
	 and	 eax,1Fh	; Bit # MOD 32
	 shr	 edx,(5-0)	; Convert page # to map index
	 btr	 [esi+edx*4],eax ; Reset bit for page 0C7h
@@:
	 REGREST <esi,edx,eax>	; Restore caller's registers

	 pop	 ebp		; Restore stack frame

LCL_GDVP_RET:
	 ret			; Return to caller (in VDD)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  LCL_GET_DEVICE_V86_PAGES_ARRAY ; End LCL_GET_DEVICE_V86_PAGES_ARRAY
endif				; IFDEF @VGASWAP

ifdef @VGASWAP
	 page
ADVP_STR struc			; Structure to access arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
ADVP_V86PAGE dd  ?		; V86 page #
ADVP_NPAGES dd	 ?		; # of pages
ADVP_VMHANDLE dd ?		; VM handle
ADVP_FLAGS dd	 ?		; Flags

ADVP_STR ends			; End ADVP_STR structure

BeginProc LCL_ASSIGN_DEVICE_V86_PAGES ; Local _Get_Device_V86_Pages_Array
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

LCL_ASSIGN_DEVICE_V86_PAGES

DESCRIPTION:
	Local replacement for the VMM _Assign_Device_V86_Pages
	If the VDD attempts to Assign_Device_V86_Pages in the VGA BIOS ROM
	area, tell 'em it worked without actually assigning the pages.

|

	 cmp	 VDD_COUNT,0	; Are we in the VDD
	 jz	 short LADVP_IGNORE ; Nope

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Determine if page being assigned is within a VGASWAPed range.
; If so, lie about it accordingly

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save caller's registers

	 mov	 esi,FLEXROM_LIN ; Pointer to FLEXROM info structure
	 movzx	 ecx,FLEXROM_CNT ; Count of entries in above table
LADVP_NXT:
	 mov	 edx,[ebp].ADVP_V86PAGE ; Page # being assigned
	 shl	 edx,(12-0)	; Convert from page # to linear address

	 movzx	 eax,[esi].FLEX_SRC ; Segment of FLEXed ROM source
	 shl	 eax,(12-8)	; Convert from segment to linear address

	 cmp	 edx,eax	; Is page being assigned below FLEXed ROM?
	 jb	 short LADVP_LP ; Nope

	 movzx	 ebx,[esi].FLEX_LEN ; Length in bytes of FLEXed ROM
	 add	 eax,ebx	; Linear address just above FLEXed ROM

	 cmp	 edx,eax	; Is page being assigned above FLEXed ROM?
	 jae	 short LADVP_LP ; Nope

; Requested page is within range a FLEXed ROM.	Lie to 'em.

	 jmp	 short LADVP_LIE ; Return an OK indication to the caller

; Advance to the next entry in the FLEXROM table

LADVP_LP:
	 add	 esi,size FLEXROM_STR ; Advance to next entry in FLEXROM table

	 loop	 LADVP_NXT	; Test the page # against all FLEXed ROMs

	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore stack frame
LADVP_IGNORE:
	 jmp	 OLD_ASSIGN_DEVICE_V86_PAGES ; Call the original
				; The original handler will return to the caller

; We've decided to lie to the VDD and tell 'em they got the pages.

LADVP_LIE:
ifdef @DEBUG
	 pushad 		; Save caller's registers

	 mov	 eax,[ebp].ADVP_V86PAGE ; Page # being assigned
	 lea	 edi,MSG_FLEX1_H1 ; Place to stick ASCII HEX digits
	 mov	 ecx,2		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 esi,OFFSET32 MSG_FLEX1 ; ==> message text
	 call	 DISPLAY	; Send it to SWATVXD

	 popad			; Restore caller's registers

;;;;;;	 BREAK			; Call the debugger FIXME
endif				; IFDEF @DEBUG

	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore stack frame

	 mov	 eax,-1 	; Normal return indicator

	 ret			; Return to caller (VDD)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  LCL_ASSIGN_DEVICE_V86_PAGES	; End LCL_ASSIGN_DEVICE_V86_PAGES proc
endif				; IFDEF @VGASWAP

ifdef @VGASWAP
	 page
PIV_STR struc			; Structure to access arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
PIV_PHYSPAGE dd  ?		; Physical page #
PIV_VMHANDLE dd ?		; VM handle
PIV_V86PAGE dd	 ?		; V86 page #
PIV_NPAGES dd	 ?		; # of pages
PIV_FLAGS dd	 ?		; Flags

PIV_STR ends			; End PIV_STR structure

BeginProc LCL_PHYS_INTO_V86	; Local _PhysIntoV86 procedure
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

LCL_PHYS_INTO_V86

DESCRIPTION:
	Local replacement for the VMM _PhysIntoV86

	If the VDD attempts to _PhysIntoV86 in the VGA BIOS ROM
	area, tell 'em it worked without actually assigning the pages.

	We've already assigned the pages properly, taking FLEXed ROMs
	into account.

|

	 cmp	 VDD_COUNT,0	; Are we in the VDD
	 jz	 short LPIV_IGNORE ; Nope

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Determine if page being mapped in within a VGASWAPed range.
; If so, lie about it accordingly

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save caller's registers

	 mov	 esi,FLEXROM_LIN ; Pointer to FLEXROM info structure
	 movzx	 ecx,FLEXROM_CNT ; Count of entries in above table
LPIV_NXT:
;;;;;;	 BREAK			; Call the debugger FIXME

	 mov	 edx,[ebp].PIV_V86PAGE ; Page # being mapped
	 shl	 edx,(12-0)	; Convert from page # to linear address

	 movzx	 eax,[esi].FLEX_SRC ; Segment of FLEXed ROM source
	 shl	 eax,(12-8)	; Convert from segment to linear address

	 cmp	 edx,eax	; Is page being assigned below FLEXed ROM?
	 jb	 short LPIV_LP	; Nope

	 movzx	 ebx,[esi].FLEX_LEN ; Length in bytes of FLEXed ROM
	 add	 eax,ebx	; Linear address just above FLEXed ROM

	 cmp	 edx,eax	; Is page being assigned above FLEXed ROM?
	 jae	 short LPIV_LP	; Nope

; Requested page is within range a FLEXed ROM
; If we have already mapped this page FLEX_SRC:FLEX_DST
; for a FLEXed ROM, ignore the request
; Otherwise, let it through to WIN386

	 mov	 eax,[ebp].PIV_V86PAGE ; Page # being mapped
	 cmp	 eax,[ebp].PIV_PHYSPAGE ; Izit a 1:1 mapping?
	 je	 short LPIV_LIE ; Yup, so lie to 'em.  Tell 'em it worked.

;;;;;;	 BREAK			; Call the debugger FIXME

	 mov	 edx,PDIR_LIN	; Linear address of 386MAX's PTEs
	 mov	 eax,[edx+eax*4] ; Get PTE for this page under 386MAX's control
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	 shr	 eax,4		; Convert from linear address to segment
	 cmp	 ax,[esi].FLEX_DST ; Izit FLEXROMed, but not a ROM?
	 jne	 short LPIV_PASS ; Yes, so let WIN386 handle it
				; Otherwise we'll lie to the VDD

ifdef @DEBUG
	 shr	 eax,(12-4)	; Convert from segment to page #
endif				; IFDEF @DEBUG

	 jmp	 short LPIV_LIE ; Return an OK indication to the caller

; Advance to the next entry in the FLEXROM table

LPIV_LP:
	 add	 esi,size FLEXROM_STR ; Advance to next entry in FLEXROM table

	 loop	 LPIV_NXT	; Test the page # against all FLEXed ROMs
LPIV_PASS:
	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore stack frame
LPIV_IGNORE:
	 jmp	 OLD_PHYS_INTO_V86 ; Call the original service in WIN386

; We've decided to lie to the VDD
; We have already properly mapped these ROM pages taking FLEXROM into account

LPIV_LIE:
ifdef @DEBUG
	 pushad 		; Save caller's registers

	 lea	 edi,MSG_FLEX2_H2 ; Place to stick ASCII HEX digits
	 mov	 ecx,8		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 eax,[ebp].PIV_V86PAGE ; Page # being mapped
	 lea	 edi,MSG_FLEX2_H1 ; Place to stick ASCII HEX digits
	 mov	 ecx,2		; # of digits
	 call	 TOHEX		; Format the V86 page #

	 mov	 esi,OFFSET32 MSG_FLEX2 ; ==> message text
	 call	 DISPLAY	; Send it to SWATVXD

	 popad			; Restore caller's registers

;;;;;;	 BREAK			; Call the debugger FIXME
endif				; IFDEF @DEBUG

	 REGREST <esi,edx,ecx,ebx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore stack frame

	 mov	 eax,-1 	; Normal return indicator

	 ret			; Return to caller (VDD)

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  LCL_PHYS_INTO_V86	; End LCL_PHYS_INTO_V86 procedure
endif				; IFDEF @VGASWAP

VxD_CODE_ENDS			; End _LTEXT segment

	 MEND			; End VMAX_VDD module
