;'$Header:   P:/PVCS/MAX/VXD/VMAX_FNS.ASV   1.0   05 Sep 1995 17:21:16   HENRY  $
	 title	 VMAX_FNS -- General Purpose Functions
	 page	 78,130
	 name	 VMAX_FNS

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
	 include VMM.INC		; Fixed version of file from DDK

	 include MASM.INC		; From the Qualitas include library
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include OPCODES.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC
	 include VCPI.INC
	 include ROMSEG.INC		; For adapter ROMs

	 include LOAD_SEG.INC		; From the QMAX source code
	 include EMM2CALL.INC
	 include QMAXWIN3.INC
	 include QMAX_FLX.INC

	 include WINDEVID.INC		; From Qualitas include library
	 include SWATVXD.INC		; Define service table

	 include BREAK.INC
	 include VMAX.INC		; Local includes
	 include VMAX_RMI.INC
	 include VMAX_UPD.INC
	 include VMAX_VID.INC
	 include VMAXSINI.INC

	 include WFW.INC		; Homemade include for WFW VxDs

	 include VERSION.INC		; Specific to the VxD
.list
	 page
VxD_DATA_SEG				; Start _DATA segment

	 extrn	 MSG_PTL_UGH:byte
	 extrn	 MSG_VLW1_UGH:byte, MSG_VLW2_UGH:byte, MSG_VLW3_UGH:byte

	 include VMAX_PMI.INC
	 extrn	 PMI_FLAG:word

	 extrn	 DOS_VER_H:byte 	; VMAX.ASM / DMAX.ASM
	 extrn	 DOS_VER_L:byte 	; VMAX.ASM / DMAX.ASM

FEP_OWNER dw	 ?	; V86 segment of MAC entry owner field of current MAC

; Filename buffer used by FIND_ENV_PGM

FEP_FILENAME	db	(8+1) dup (?)	; Space to hold DOS 4 MAC filenames

	 public  FEP_FLAG
FEP_FLAG db	 ?			; 0 - We couldn't find a name
					; 1 - Normal PSP ENV name
					; 2 - DOS 4 MAC name

VxD_DATA_ENDS				; End _DATA segment
	 page
VxD_ICODE_SEG				; Begin _ITEXT segment
	 assume  cs:FLAT		; Tell the assembler

BeginProc GET_SYSTEM_OPTION	; Clear AX if SYSTEM.INI option is NOT set
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Use the GetProfileString VMM service to read a SYSTEM.INI cookie.

	If found, return EDX unchanged.  If not found, or =FALSE is
	found clear EDX.

ENTRY:
	EDX	=	Flag bit for option

EXIT:
	EDX	=	Input flag bit if string found
			NULL if string not found

|

	 REGSAVE <eax,esi>	; Save caller's registers

	 push	 edx		; Save EDX around call
	 sub	 edx,edx	; Assume option not present
	 sub	 esi,esi	; NULL indicates [386Enh] section

	 VMMcall Get_Profile_String ; EDX ==> text of option if present

	 or	 edx,edx	; Is the string present?
	 pop	 edx		; Restore
	 jnz	 short @F	; Jump if option is present

	 sub	 edx,edx	; Kill option bit
@@:

	 REGREST <esi,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  GET_SYSTEM_OPTION		; End GET_SYSTEM_OPTION procedure

VxD_ICODE_ENDS				; End _ITEXT segment
	 page
VxD_CODE_SEG				; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

	 extrn	 DISPLAY:near		; VMAX_DBG.ASM
	 extrn	 Get_Mapped_Page_Num:near ; VMAX_LHI.ASM / DMAX.ASM

BeginProc PHYS2LIN		; VMMcall _MapPhysToLinear that works > 16MB
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Do a VMMcall _MapPhysToLinear that works above 16 MB

	VMMcall _MapPhysToLinear fails to work properly if the input physical
	address is greater than 1000000h (16 MB), AND the range crosses a
	4KB PTE boundary.

Entry:
	Physical address and length on stack

Exit:
	Arguments popped from stack

	EAX	=	Linear address
		=	-1 if it failed

|

P2L_STK_STR	 struc		; Structure to access stacked arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
P2L_LEN  dd	 ?		; Length caller wants included
P2L_PHYS dd	 ?		; Physical address input to PHYS2LIN

P2L_STK_STR	 ends		; End P2L_STK_STR structure

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx>	; Unlike Aaron, we won't trash ECX & EDX

	 mov	 eax,[ebp].P2L_LEN ; Get length for MapPhysToLinear call

	 mov	 edx,[ebp].P2L_PHYS ; Get input physical address
	 add	 edx,[ebp].P2L_LEN ; Last address +1 in area
	 cmp	 edx,16*1024*1024 ; Does any of it sit above 16 MB?
	 jbe	 short @F	; No, so don't force the overflow

	 add	 eax,4095	; Force overflow to next page
@@:
	 VMMcall _MapPhysToLinear <[ebp].P2L_PHYS, eax, 0>

; Any errors occurring in the above MapPhysToLinear are reflected to the caller

	 REGREST <edx,ecx>	; Restore caller's registers

	 pop	 ebp		; Restore any previous stack frame

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  PHYS2LIN			; End PHYS2LIN procedure
	 page
BeginProc P2LERROR		; VMMcall _MapPhysToLinear that works > 16MB
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Fatal error if EAX is not a valid address

Entry:
	Linear address of error message on stack
	EAX = Linear address (or -1)

Exit:
	FatalError if EAX == -1

	Arguments popped from stack otherwise

|

P2LERR_STR	 struc			; Structure to access stacked arguments

	 dd	 ?			; ...	   EBP
	 dd	 ?			; Caller's EIP
P2LERR_MSG dd	 ?			; Linear address of error text

P2LERR_STR	 ends			; End P2LERR_STR structure

	 push	 ebp			; Prepare to address the stack
	 mov	 ebp,esp		; Hello, Mr. Stack

	 cmp	 eax,-1 		; Test for error return
	 jne	 short @F		; Exit OK if not -1

	 mov	 esi,[ebp].P2LERR_MSG	; ESI ==> message text
	 call	 DISPLAY		; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:
	 pop	 ebp			; Restore any previous stack frame

	 ret	 4			; Return to caller, popping argument

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  P2LERROR			; End P2LERROR procedure
	 page
BeginProc V86LIN2WIN		; Map V86 mode linear address to Windows linear
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Map a V86 mode linear address to a ring 0 linear address under
	Windows' page tables.

	After Sys_VM_Init, V86LIN2WIN uses CB_High_Linear for the
	current VM.

	TSR frame pages are returned as-is.

ENTRY:
	V86 linear address and length on stack.

EXIT:
	EAX	= Linear address under Windows' page tables.
	Stacked arguments removed.

|

VL2W_STK_STR	 struc		; Structure to access stacked arguments

	 dd	 ?		; ...	   EBP
	 dd	 ?		; Caller's EIP
VL2W_LEN dd	 ?		; Length caller wants included
VL2W_V86 dd	 ?		; V86 linear address to V86LIN2WIN

VL2W_STK_STR	 ends		; End VL2W_STK_STR structure

	 push	 ebp			; Save caller's stack frame
	 mov	 ebp,esp		; Create our local stack frame

	 test	 PMI_FLAG,@PMI_SYSVM	; Sys_VM_Init been by yet?
	 jz	 short V86LIN2WIN_BEFORE_SVI ; Skip special case if not

	 push	 ebx			; Save caller's register

	 VMMcall Get_Cur_VM_Handle	; ... into EBX
	 mov	 eax,[ebx+CB_High_Linear] ; Offset to VMs address space

	 pop	 ebx			; Restore caller's register

	 add	 eax,[ebp].VL2W_V86	; Offset to input V86 linear address
					; Return to caller in EAX

	 jmp	 short VL2W_XIT0	; Rejoin common exit code

	 public  V86LIN2WIN_BEFORE_SVI
V86LIN2WIN_BEFORE_SVI:
	 REGSAVE <ecx,edx>		; Save caller's registers

	 mov	 eax,[ebp].VL2W_V86	; Get input V86 linear address
	 shr	 eax,(12-0)		; Convert from bytes to 4KB page #

	 call	 Get_Mapped_Page_Num	; Get physical page # mapping into EDX
	 or	 edx,edx		; Did we map this page?
	 jnz	 short @F		; Skip copy if so

	 mov	 edx,eax		; Assume mapped 1:1
@@:
	 shl	 edx,(12-0)		; Convert from page # to byte address

	 mov	 eax,[ebp].VL2W_V86	; Get input V86 linear address
	 and	 eax,not ((mask $PTE_FRMHI) or (mask $PTE_FRM))
					; Get V86 address MOD 4KB page
	 add	 edx,eax		; ... plus linear address of 4KB page
	 push	 edx			; Physical address we're interested in
	 push	 [ebp].VL2W_LEN 	; Length we'll want to inspect
	 call	 PHYS2LIN		; Get linear address into EAX

	 cmp	 eax,-1 		; Test for error return
	 jne	 short @F		; Jump if it worked

; Tell 'em PhysToLinear failed and return

	 push	 esi			; Save register
	 mov	 esi,OFFSET32 MSG_PTL_UGH ; Offset to error msg text
	 call	 DISPLAY		; Put message on debugging screen
	 pop	 esi			; Restore register

	 mov	 eax,-1 		; Error indicator

;;;;;;	 jmp	 short VL2W_XIT 	; Join common exit code
@@:
VL2W_XIT:
	 REGREST <edx,ecx>		; Restore caller's registers

VL2W_XIT0:
	 pop	 ebp			; Restore any previous stack frame

	 ret	 2*4			; Return to caller, popping arguments

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  V86LIN2WIN			; End V86LIN2WIN procedure
	 page
BeginProc FIND_ENV_PGM		; Find program name in PSP, return ptr in EDI
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Look for a program's name in a PSP.

ENTRY:
	AX	=	Segment of PSP itself (not the MAC)

EXIT:
	ESI	==>	Entire path and filename
	EDI	==>	Program name
	EDX	=	Length of filename including terminating NULL

	CY if we couldn't find a name

|

	 REGSAVE <eax,ecx>	; Save caller's registers

	 pushfd 		; Save direction

	 mov	 FEP_OWNER,ax	; Save for use later use in comparisons

	 shl	 eax,4		; Convert from paras to bytes

	 push	 eax		; V86 linear address of PSP
	 push	 4096		; Length
	 call	 V86LIN2WIN	; Get Winlinadr of owner MAC (PSP)

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em V86LIN2WIN failed and crash

	 mov	 esi,OFFSET32 MSG_VLW1_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

;;;;;;	 movzx	 eax,PSP_ENVIR_PTR ; Get segment of environment strings
	 movzx	 eax,[eax+2Ch].ELO ; Get segment of enivronment strings

	 or	 eax,eax	; Has it been freed and the ptr NULLed?
	 jz	 short FEP_TRYDOS4MAC ; Let's try to get it from the DOS 4 MAC

	 shl	 eax,4		; Convert from paras to bytes

	 sub	 eax,size MAC_STR ; Back up to inspect the MAC itself

	 push	 eax		; V86 linear address of environment strings
	 push	 4096		; Length
	 call	 V86LIN2WIN	; Get Winlinadr of environment strings

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em V86LIN2WIN failed and crash

	 mov	 esi,OFFSET32 MSG_VLW2_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 mov	 edi,eax	; Copy pointer to register for REPNZ SCASB

; EDI is a Winlinadr to the MAC header of the environment strings
; Perform some sanity checks before trudging through the strings

	 cmp	 [edi].MAC_TYPE,@MAC_END ; Ending entry?
	 je	 short @F	; Jump if environment looks OK so far

	 cmp	 [edi].MAC_TYPE,@MAC_MID ; Middle entry?
	 jne	 short FEP_TRYDOS4MAC ; Try to get name from DOS 4 MAC entry
@@:
	 mov	 ax,FEP_OWNER	; Get our MAC owner

	 cmp	 ax,[edi].MAC_OWNR ; Is it owned by our boy?
	 je	 short FEP_ZOOM ; Yes, so go scan for the name

; This environment looks funny - try to get the name from a DOS 4 MAC

FEP_TRYDOS4MAC:
	 cmp	 DOS_VER_H,4	; Running under DOS 4.00 or later?
	 jl	 FEP_ERRXIT	; No, so we're up the creek FIXME

	 movzx	 eax,FEP_OWNER	; Segment of MAC owner in V86 address space
	 shl	 eax,(4-0)	; Convert from paras to V86 linear address

	 sub	 eax,size MAC_STR ; Back up to inspect the MAC itself

	 push	 eax		; V86 linear address of DOS 4 MAC entry
	 push	 size MAC_STR	; Length
	 call	 V86LIN2WIN	; Get Winlinadr of DOS 4 MAC entry

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Jump if it worked

; Tell 'em V86LIN2WIN failed and crash

	 mov	 esi,OFFSET32 MSG_VLW3_UGH ; Offset to error msg text
	 call	 DISPLAY	; Put message on debugging screen

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler
@@:

	 lea	 esi,[eax].MAC_NAME ; Pointer to name in DOS 4 MAC entry
	 mov	 edi,OFFSET32 FEP_FILENAME ; Pointer to destination

	 mov	 ecx,8		; Maximum length of name in the DOS 4 MAC
FEP_D4_NXT:
	 lodsb			; Get next byte of filename
	 cmp	 al,0		; Is it a NULL?
	 je	 short FEP_D4_DON ; Yes, so exit loop

	 cmp	 al,' '         ; Is it a space?
	 je	 short FEP_D4_DON ; Yes, so exit loop

	 stosb			; Store filename character in buffer
	 loop	 short FEP_D4_NXT ; Go back for more
FEP_D4_DON:
	 sub	 al,al		; Get a terminating NULL
	 stosb			; Terminate the filename string

	 mov	 edx,edi	; Address of terminator + 1
	 sub	 edx,OFFSET32 FEP_FILENAME ; Length of name for return

	 mov	 edi,OFFSET32 FEP_FILENAME ; Pointer to destination
	 mov	 esi,edi	; Return copy in ESI

	 mov	 FEP_FLAG,2	; Indicate we got a DOS 4 MAC name

	 jmp	 short FEP_OKXIT ; Join common normal exit code

; This environment looks OK

FEP_ZOOM:
	 add	 edi,size MAC_STR ; Pointer to environment strings themselves

; Zoom through environment strings to find program name

	 cld			; Forward
	 sub	 al,al		; Byte for which to search
FEP_EVN:
	 mov	 ecx,8000h	; Give it plenty of slack
	 repnz scasb		; Find terminating NULL

	 cmp	 [edi].LO,0	; Last string?
	 jne	 short FEP_EVN	; Loop back if more strings to skip

	 add	 edi,1+2	; Advance source pointer past extra NULL
				; ... and string count

; Find end of path and filename

FEP_FEND:
	 mov	 esi,edi	; Copy start of path
	 cld			; Forward
	 sub	 al,al		; Scan for a terminating NULL
	 mov	 ecx,-1 	; Look forever
	 repnz scasb		; Look for end of string
	 dec	 edi		; Back up once for the last SCASB
	 mov	 edx,edi	; Save pointer to terminating NULL
	 dec	 edi		; ... and once for the NULL itself

; Search backward for any of '\', '/', ':', or NULL

	 std			; Backward
	 xchg	 esi,edi	; ESI ==> end, EDI ==> start of path
FEP_SBNXT:
	 lodsb			; Get next character of path

	 cmp	 al,'\'         ; Is it a path separator?
	 je	 short FEP_SBX	; Yes, we've hit our boy

	 cmp	 al,'/'         ; Is it a path separator?
	 je	 short FEP_SBX	; Yes, we've hit our boy

	 cmp	 al,':'         ; Is it a drive specifier?
	 je	 short FEP_SBX	; Yes, we've hit our boy

	 or	 al,al		; Are we at the front end of the list?
	 jne	 short FEP_SBNXT ; No, go get the next character
FEP_SBX:
	 inc	 esi		; Advance once for the extra LODSB
	 inc	 esi		; ... and once for the terminating char itself

	 xchg	 esi,edi	; EDI ==> filename, ESI ==> entire pathname
	 sub	 edx,edi	; Length of filename
	 inc	 edx		; ... plus 1 for the terminating NULL

	 mov	 FEP_FLAG,1	; Indicate we got a PSP environment name
FEP_OKXIT:
	 popfd			; Restore direction flag

	 clc			; Indicate we found a name
FEP_XIT:
	 REGREST <ecx,eax>	; Restore caller's registers

	 ret			; Return to caller

FEP_ERRXIT:
	 mov	 FEP_FLAG,0	; Indicate we failed to get a name

	 popfd			; Restore direction flag

	 stc			; Indicate we couldn't find a name

	 jmp	 short FEP_XIT	; Join common exit code

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  FIND_ENV_PGM			; End FIND_ENV_PGM procedure
	 page
BeginProc ISWHITE		; Return ZR if ESI ==> a whitespace character
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Test a character for whitespace.


EXTRY:
	DS:ESI ==> character to be tested

EXIT:
	Zero flag set if DS:ESI ==> a whitespace character

|

	 cmp	 [esi].LO,' '   ; Is it a blank?
	 je	 short IW_XIT	; Exit with ZR if so

	 cmp	 [esi].LO,TAB	; Is it a tab?
IW_XIT:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  ISWHITE		; End ISWHITE procedure
	 page
BeginProc SKIPWHITE		; Advance ESI to non-whitespace character
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Advance past whitespace characters.

ENTRY:
	DS:ESI ==> input characters

EXIT:
	DS:ESI ==> a non-whitespace character

|

	 REGSAVE <eax>		; Save caller's registers

SW_NXT:
	 mov	 al,[esi].LO	; Get next character
	 cmp	 al,' '         ; Is it a blank?
	 je	 short SW_SKP	; Keep going if so

	 cmp	 al,TAB 	; Is it a TAB?
	 je	 short SW_SKP	; Keep going if so

	 cmp	 al,EOF 	; Is it EOF?
	 je	 short SW_XIT_CY ; Return CY if so

	 cmp	 al,CR		; Is it CR?
	 jne	 short SW_XIT_NCNZ ; Return normal non-whitespace indicator

	 inc	 esi		; Skip over CR
	 inc	 esi		; ... and LF

	 jmp	 short SW_XIT_ZR ; Return ZR

SW_XIT_CY:
	 stc			; Set carry - Found EOF

	 jmp	 short SW_XIT	; Join common exit code

SW_XIT_ZR:
	 cmp	 al,al		; Set ZR - Found CR/LF

	 jmp	 short SW_XIT	; Join common exit code

SW_XIT_NCNZ:
	 sub	 al,al		; Set ZR
	 inc	 al		; Clear ZR - not CR/LF
	 clc			; Clear carry - not EOF

	 jmp	 short SW_XIT	; Join common exit code

SW_SKP:
	 inc	 esi		; Advance over last character

	 jmp	 short SW_NXT
SW_XIT:
	 REGREST <eax>		; Restore caller's registers

	 ret

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SKIPWHITE		; End SKIPWHITE procedure
	 page
BeginProc TOKENIZE		; Get length to token into ECX
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Get length of a whitespace-terminated token.

ENTRY:
	DS:ESI ==> input character

EXIT:
	ECX = length of token

|

	 REGSAVE <eax,esi,edi>	; Save caller's registers

	 mov	 edi,esi	; Save pointer to start of token
TOK_NXT:
	 lodsb			; Get next character of token

	 cmp	 al,EOF 	; Is it EOF?
	 je	 short TOK_EOT	; Exit loop if so

	 cmp	 al,CR		; Is it CR/LF?
	 je	 short TOK_EOT	; Exit loop if so

	 cmp	 al,' '         ; Is it a blank?
	 je	 short TOK_EOT	; Exit loop if so

	 cmp	 al,TAB 	; Is it a TAB?
	 je	 short TOK_EOT	; Exit loop if so

	 jmp	 short TOK_NXT	; Go try next character

TOK_EOT:
	 mov	 ecx,esi	; Get pointer to character just past token
	 sub	 ecx,edi	; Minus start of token = length
	 dec	 ecx		; Minus the extra one from the LODSB

	 REGREST <edi,esi,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  TOKENIZE		; End TOKENIZE procedure
	 page
BeginProc CONSUME		; Advance ESI to next line or EOF
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Advance to the next line or end-of-file.

ENTRY:
	DS:ESI ==> current position in text.

EXIT:
	DS:ESI ==> start of next line or end-of-file.

|

	 REGSAVE <eax>		; Save caller's registers
CONSUME_NXT:
	 mov	 al,[esi].LO	; Get next character

	 cmp	 al,EOF 	; Is it EOF?
	 je	 short CONSUME_XIT ; Exit if so

	 cmp	 al,CR		; Is it a CR?
	 jne	 short @F	; Skip CR/LF work if not

	 inc	 esi		; Bump past CR
	 inc	 esi		; ... and LF

	 jmp	 short CONSUME_XIT ; Join common exit code
@@:
	 inc	 esi		; Bump to next character

	 jmp	 short CONSUME_NXT ; Go around again
CONSUME_XIT:
	 REGREST <eax>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CONSUME		; End CONSUME procedure
	 page
BeginProc CHK_CFG_FLAG		; Return ZR if field contains flag in DL
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Check fields in 386LOAD.CFG entry for the specified flag.

ENTRY:
	DS:ESI ==> current position in 386LOAD.CFG text.
	DL	=	ASCII flag letter

EXIT:
	Zero flag set if flag field contains DL.

|

	 REGSAVE <eax>		; Save caller's registers

CF_NXT:
	 cmp	 [esi].LO,EOF	; Are we at EOF?
	 je	 short CF_XIT_FALSE ; Exit NZ if so

	 call	 ISWHITE	; Did we hit whitespace?
	 je	 short CF_XIT_FALSE ; Exit NZ if so

	 lodsb			; Get next flag character

	 cmp	 al,dl		; Is it our flag letter?
	 je	 short CF_XIT	; Exit if so (note ZF=1)

	 jmp	 short CF_NXT	; Go back for next character

CF_XIT_FALSE:
	 sub	 al,al		; Set the ZR flag
	 inc	 al		; Clear ZR flag
CF_XIT:
	 REGREST <eax>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CHK_CFG_FLAG		; End CHK_CFG_FLAG procedure
	 page
BeginProc CMPSBI		; Case insensitive REPE CMPSB
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Case insensitive string compare procedure that takes the
	pointer registers the same as the REPE CMPSB CPU instruction.

	An STRLEN of the model string is performed to get the length
	of the comparison.

ENTRY:
	DS:ESI ==> 1st string (our model, in uppercase)
	ES:EDI ==> 2nd string

EXIT:
	Zero flag set if the strings were equivalent.


|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save caller's registers

; Calculate the length of the destination string

	 push	 edi		; Save pointer to destination string
	 mov	 ecx,-1 	; Look forever, we know it's there
	 sub	 al,al		; Terminating NULL
	 repne scasb		; Search for the terminating NULL
	 neg	 ecx		; Lenght we scanned
	 dec	 ecx		; Account for overscan at end
	 pop	 edi		; Restore pointer to destination string

CMPSBI_LP:
	 lodsb			; Get next character from source string
	 or	 al,20h 	; Form lowercase version of source character

	 mov	 dl,es:[edi]	; Get next destination character
	 inc	 edi		; Bump source pointer
	 or	 dl,20h 	; Form lowercase version of destination char

	 cmp	 al,dl		; Source against destination
	 jne	 short CMPSBI_XIT ; Exit NZ

; Loop and compare next character

CMPSBI_NXT:
	 loop	 short CMPSBI_LP ; Loop until done

; Zero flag set or clear depending on previous comparisons

CMPSBI_XIT:
	 REGREST <edi,esi,edx,ecx,eax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  CMPSBI 			; End CMPSBI procedure

VxD_CODE_ENDS				; End _TEXT segment

	 end				; End VMAX module
