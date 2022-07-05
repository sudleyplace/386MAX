;' $Header:   P:/PVCS/MAX/VXD/VMAX_UPD.ASV   1.0   05 Sep 1995 17:21:10   HENRY  $
	 title	 VMAX_UPD -- Update Older Versions of 386MAX
	 page	 78,130
	 name	 VMAX_UPD

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-92 Qualitas, Inc.  GNU General Public License version 3.

Environment:  IBM PC, tested under DOS 3.30, 3.31, 4.01, 5.00.

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

Link requirements:  Final routine should have extension .386 or .VXD.

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include OPCODES.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC
	 include VCPI.INC

	 include QMAX_CMD.INC
	 include QMAX_CM2.INC
	 include QMAX_CTL.INC
	 include QMAX_DBG.INC
	 include QMAXWIN3.INC
	 include EMM2CALL.INC
	 include LOAD_SEG.INC
	 include ROMSEG.INC	; For adapter ROMs

	 include VMAX.INC
	 include VMAXSINI.INC
	 include VMAX_UPD.INC

	 include VERSION.INC
.list

	 page
VxD_REAL_INIT_SEG		; Begin _RCODE segment
	 assume  cs:_RCODE

	 extrn	 RMI_SHOW_BANNER:near
	 extrn	 RMI_PAUSE:near

	 extrn	 MSG_PAK:byte
	 extrn	 MSG_PAKORESC:byte
	 extrn	 MSG_CRLF:byte
ifdef @DEBUG
	 extrn	 MSG_UPD_VER:byte
	 extrn	 MSG_UPD_VER0:byte, MSG_UPD_VER1:byte
endif				; IFDEF @DEBUG

	 extrn	 DEVNAME_MAX:byte

	 extrn	 RMI_REF_DATA:tbyte

	 extrn	 QMAX_VER:word
	 extrn	 QMAX_DSHI:word

	 extrn	 WIN386_VER:word

	 extrn	 REFDATA_VER:word
	 extrn	 REFDATA_LEN:word

	 include VMAX_RMI.INC
	 extrn	 RMI_FLAG:word

.xlist
	 include QMAXINFO.INC
.list
	 extrn	 INFO:tbyte

	 page
BeginProc RMI_UPD,PUBLIC	; Update an old 386MAX to newer functionality
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Fix bugs in older versions of 386MAX.
Retrofit Windows 3.10 support into older versions of 386MAX.

This code currently handles 386MAX 5.10 - 5.13, and 6.00.

|

	 REGSAVE <eax,dx,si>	; Save caller's registers

; Fix the bug in 386MAX 5.10 under DOS 5 that caused the DOS itself to not
; be instanced properly.
; Programs trolling for the 1605 Windows startup broadcast that were in place
; before 386MAX we being left out of the WIN3_STARTUP.SIS_NEXT_DEV_PTR in
; low DOS memory.  The high DOS copy was correct.

; Find the WIN3_STARTUP sturcture in 386MAX's high DOS data and retrieve the
; SIS_NEXT_DEV_PTR field.  Stuff it into the low DOS copy.
; The WIN386 loader will examine the 1605 ES:BX chain after our real mode
; init code returns and correctly find DOS's entry.

@WIN3_STARTUP_510 equ	01DCh	; Offset in 386MAX 5.10 of WIN3_STARTUP

	 cmp	 QMAX_VER,510h	; Izit 386MAX version 5.10?
	 jne	 short RMI_UPD_XDOS5 ; Nope

	 mov	 si,@WIN3_STARTUP_510 ; ES:SI ==> WIN3_STARTUP

	 push	 es		; Save caller's register

; Get SIS_NEXT_DEV_PTR from high DOS instance of structure

	 mov	 es,QMAX_DSHI	; Segment of 386MAX in high DOS memory
	 assume  es:nothing	; Tell the assembler

	 mov	 eax,es:[si].SIS_NEXT_DEV_PTR ; ==> previous link in 1605 chain

; Update the WIN3_STARTUP.SIS_NEXT_DEV_PTR in low DOS instance of structure

	 mov	 es,INFO.INFO_QMAX ; Get low segment of 386MAX device driver
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[si].SIS_NEXT_DEV_PTR,eax ; ==> previous link in 1605 chain

	 pop	 es		; Restore caller's register
	 assume  es:nothing	; Tell the assembler

RMI_UPD_XDOS5:

; Updates specific to Windows 3.10

	 cmp	 WIN386_VER,030Ah ; Izit Windows 3.10?
	 jb	 short @F	; Skip if not

COMMENT|

The original code here compared against equality which erroneously resulted
in the RMI_REF_DATA.REF_UPDFLAG,@RMI_UPDATE bit being set when it shouldn't be.
That caused the protected mode part to ask LoadHi to setup the high DOS PTEs
which caused WIN386 to complain about not being able to setup UMB via
the GPIS 1.11.

This occured with 386MAX.SYS 6.02.063 when REFDATA_VER bumped to 700h.
386MAX.VXD 6.02.005 and older wasn't ready to handle it.  386MAX.SYS 6.02.006
was compiled with @REF_STRUC_VER = 700h which worked around the problem.

Of course that didn't last long.  We've decided to ship a 6.03 to handle
MS-DOS 6.0.  This means that the QMAX.SYS 7.0 features can't be included.

The 6.03 reference data includes the HARPO FILES= length.
The 6.03 REFDATA_VER is 603h.

The last REFDATA_VER for which we do Windows 3.1 special update is 513h.

|

	 cmp	 REFDATA_VER,@REF_STRUC_VER ; Izit the one we know, or newer?
	 jae	 short RMI_UPD_XITOK	; Yup, so we're not updating

	 cmp	 REFDATA_VER,513h	; Izit later than the ones we upgrade?
	 jae	 short @F		; Don't tell upstairs if so

	 or	 RMI_REF_DATA.REF_UPDFLAG,@UPD_UPDATE ; Tell PM we're updating
@@:

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we displaying this kind of stuff?
	 jz	 short @F	; Nope

; Tell 'em we're updating an older 386MAX

	 mov	 ax,REFDATA_VER ; Get version # of reference data structure

	 add	 ah,'0'         ; Form ASCII digit of major #
	 mov	 MSG_UPD_VER0,ah ; Save in message text

	 mov	 ah,al		; Copy minor #s into high-order half
	 shr	 ah,4		; Move high-order minor digit to low end
	 and	 al,0Fh 	; Isolate low digit
	 add	 ax,('0' shl 8) or '0' ; Form ASCII digits
	 xchg	 al,ah		; Swap 'em
	 mov	 MSG_UPD_VER1.ELO,ax ; Save in message text

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_UPD_VER ; Tell 'em we're updating an older 386MAX

	 call	 RMI_PAUSE	; Wait for a key press
	 jc	 short RMI_UPD_XIT ; Return if they hit ESCape
				; Note the CY transfers to the exit code
@@:
endif				; IFDEF @DEBUG

RMI_UPD_XITOK:
	 clc			; Normal return indicator
RMI_UPD_XIT:
	 REGREST <si,dx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_UPD		; End RMI_UPD procedure

VxD_REAL_INIT_ENDS		; End _RCODE segment

	 page
VxD_DATA_SEG			; Begin _DATA segment

	 extrn	 WIN3_VERSION:word

	 extrn	 PGROUP_DS:word ; Writeable selector for 386MAX's PGROUP

CHECK_WIN_OFFSET dd	0	; Offset in QMAX_XMS.ASM to CHECK_WIN or zero

OLD_CHECK_WIN	 db	2 dup (?) ; Space to hold original bytes from CHECK_WIN

VxD_DATA_ENDS			; End _DATA segment

	 page
VxD_LOCKED_CODE_SEG		; Begin _LTEXT segment
VxD_LOCKED_CODE_ENDS		; End _LTEXT segment

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 extrn	 LoadHi_DDB:tbyte ; Reference data

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 extrn	 REF_LIN:dword	; ==> reference data structure

VxD_LOCKED_DATA_ENDS

	 page
VxD_IDATA_SEG			; Begin _IDATA segment

	 extrn	 MSG_UPD_UGH1:byte
	 extrn	 MSG_UPD_UGH2:byte

	 public  IZIT_WIN3_MODEL
IZIT_WIN3_MODEL  label	 byte
	 db	 66h,0B9h, 15h, 00h, 00h, 00h	; mov	ecx,00000015h
	 db	 66h, 57h			; push	edi
	 db	0F3h, 67h,0A6h			; repe cmpsb
	 db	 66h, 5Fh			; pop	edi
	 db	 74h, 3Dh			; jz	short @F

@IZIT_WIN3_MODEL equ	$-IZIT_WIN3_MODEL	; Length of above model code

@IZIT_WIN3_LOWEST equ	7F00h	; Lowest offset in PGROUP of above model code
@IZIT_WIN3_HIGHEST equ	8600h	; Highest offset in PGROUP of above model code

@IZIT_WIN3_BACKUP equ	21h	; Backward distance from model to IZIT_WIN3

@IZIT_WIN3_1ST2  equ	8E2Eh	; 1st two bytes if IZIT_WIN3

	 public  CHECK_WIN_MODEL
CHECK_WIN_MODEL  label	 byte
	 db	 01h, 02h			; mov	byte ptr [01EE],02
						; Part of the last instruction
	 db	 74h, 0Bh			; jz	@F
	 db	 1Eh				; push	ds
	 db	 8Eh, 1Eh			; mov	ds,[A84E]
						; Part of the last instruction

@CHECK_WIN_MODEL equ	$-CHECK_WIN_MODEL	; Length of above model code

@CHECK_WIN_LOWEST equ	7F00h	; Lowest offset in PGROUP of above model code
@CHECK_WIN_HIGHEST equ	8600h	; Highest offset in PGROUP of above model code

@CHECK_WIN_BACKUP equ	03h	; Backward distance from model to CHECK_WIN

VxD_IDATA_ENDS			; End _IDATA segment

	 page
VxD_ICODE_SEG			; Begin _ICODE segment
	 assume  cs:FLAT	; Tell the assembler

BeginProc UPD_CHECK_WIN 	; Update an old 386MAX to Windows 3.10
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

This routine patches the CHECK_WIN procedure
in QMAX_XMS.ASM to return a 'No, it is not Windows' indication.

The original code in CHECK_WIN looks like this:

	CHECK_WIN	proc	near
			cmp	LOWWIN3_CB,2	; Are we under Windows' GDT?
			je	short @F	; Jump if so, carry is clear

			push	ds		; Save
			mov	ds,SEL_DSHI	; Load DS with high mem selector
			cmp	INTXMS_LVL,1	; Are we called by Windows?
			pop	ds		; Restore

			ret			; Return to caller

	CHECK_WIN	endp			; End CHECK_WIN procedure

We convert it to:

	CHECK_WIN	proc	near

			stc			; Indicate it's not Windows
			ret			; Return to caller

	CHECK_WIN	endp			; End CHECK_WIN procedure

|

; If it's Windows 3.10, and we're updating 386MAX 5.10 - 5.12,
; check IZIT_WIN3 to see if it's been patched by WINUPD.LOD.
; If not, patch CHECK_WIN so it never reports Windows is running.

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save caller's registers

	 sub	 eax,eax	; A handy zero
	 mov	 CHECK_WIN_OFFSET,eax ; Zero to indicate we've patched nothing

	 cmp	 WIN3_VERSION,030Ah ; Izit Windows 3.10?
	 jb	 UPD_CHECK_WIN_XIT ; Use the original kludge if not
				; Bob, looking for Windows as the caller
				; to 4310h was, in my opinion, a really
				; bad idea!

	 mov	 edx,REF_LIN	; Get Windows linear address of REF_DATA_STR
	 test	 [edx].REF_UPDFLAG,@UPD_UPDATE ; Are we updating an old 386MAX?
	 jz	 UPD_CHECK_WIN_XIT ; Nope, so don't patch anything

	 mov	 ax,[edx].REF_STRUC_VER ; Get reference data structure version

	 cmp	 ax,@REF_STRUC_VER ; Izit the one we know and love?
	 je	 UPD_CHECK_WIN_XIT ; Yup, so forget patching anything

; Get addressibility to 386MAX's code with a writeable selector

	 mov	 es,PGROUP_DS	; Address 386MAX's code w/ a writeable selector
	 assume  es:nothing	; Tell the assembler

; Figure out the correct offset in 386MAX to IZIT_WIN3
; Search MAX's PGROUP for the model IZIT_WIN3 code

	 lea	 esi,IZIT_WIN3_MODEL ; DS:SI ==> IZIT_WIN3 model code
	 mov	 edi,@IZIT_WIN3_LOWEST ; ES:DI ==> MAX's PGROUP for search
	 mov	 ecx,@IZIT_WIN3_HIGHEST ; ==> highest offset were it'll be found
	 sub	 ecx,edi	; Limit search to this range
@@:
	 inc	 edi		; Advance one byte in PGROUP
	 REGSAVE <ecx,esi,edi>	; Save pointers, and compare count

	 mov	 ecx,@IZIT_WIN3_MODEL ; Length of model code
    repe cmpsb			; Compare model with code in MAX's PGROUP

	 REGREST <edi,esi,ecx>	; Restore pointers, and compare count

	 je	 short UPD_IZIT_WIN3_FND ; Exit loop if we found IZIT_WIN3

	 loopne  @B		; Bump one byte in PGROUP and compare again

; We've exhausted the search loop without finding IZIT_WIN3

	 lea	 esi,MSG_UPD_UGH1 ; ESI ==> 'Failed to locate patch target'
	 push	 esi		; Save pointer to error message text
	 lea	 esi,[esi+3]	; Bump past BEL, CR, and LF
	 call	 DISPLAY	; Show error message on debugging screen
	 pop	 esi		; Restore original text pointer

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler

; We've found IZIT_WIN3

UPD_IZIT_WIN3_FND:
	 sub	 edi,@IZIT_WIN3_BACKUP ; DI is offset within MAX's PGROUP ...
				; ... of IZIT_WIN3

; ES:EDI ==> IZIT_WIN3 in QMAX_XMS.ASM

; Examine it to see if it has been patched by WINUPD.LOD

	 cmp	 es:[edi].ELO,@IZIT_WIN3_1ST2 ; Does it match?
	 jne	 short UPD_CHECK_WIN_XIT ; Skip patch of CHECK_WIN if it's been patched

; Figure out the correct offset in 386MAX to CHECK_WIN
; Search MAX's PGROUP for the model CHECK_WIN code

	 lea	 esi,CHECK_WIN_MODEL ; DS:SI ==> CHECK_WIN model code
	 mov	 edi,@CHECK_WIN_LOWEST ; ES:DI ==> MAX's PGROUP for search
	 mov	 ecx,@CHECK_WIN_HIGHEST ; ==> highest offset were it'll be found
	 sub	 ecx,edi	; Limit search to this range
@@:
	 inc	 edi		; Advance one byte in PGROUP
	 REGSAVE <ecx,esi,edi>	; Save pointers, and compare count

	 mov	 ecx,@CHECK_WIN_MODEL ; Length of model code
    repe cmpsb			; Compare model with code in MAX's PGROUP

	 REGREST <edi,esi,ecx>	; Restore pointers, and compare count

	 je	 short UPD_CHECK_WIN_FND ; Exit loop if we found CHECK_WIN

	 loopne  @B		; Bump one byte in PGROUP and compare again

; We've exhausted the search loop without finding CHECK_WIN

	 lea	 esi,MSG_UPD_UGH2 ; ESI ==> 'Failed to locate patch target'
	 push	 esi		; Save pointer to error message text
	 lea	 esi,[esi+3]	; Bump past BEL, CR, and LF
	 call	 DISPLAY	; Show error message on debugging screen
	 pop	 esi		; Restore original text pointer

	 VMMcall Fatal_Error_Handler ; Return to real mode, print msg, and exit
				; Control never returns from Fatal_Error_Handler

; We've found CHECK_WIN

UPD_CHECK_WIN_FND:
	 sub	 edi,@CHECK_WIN_BACKUP ; DI is offset within MAX's PGROUP ...
				; ... of CHECK_WIN
	 mov	 esi,edi	; Move pointer to proper register

; ES:ESI ==> CHECK_WIN in QMAX_XMS.ASM

	 mov	 CHECK_WIN_OFFSET,esi ; Save offset for XUPD_CHECK_WIN

	 mov	 ax,es:[esi]	; Pick up original code from CHECK_WIN
	 mov	 OLD_CHECK_WIN.ELO,ax ; Save 'em

	 mov	 es:[esi].LO,@OPCOD_STC ; Stuff in a STC
	 mov	 es:[esi+1].LO,@OPCOD_RET ; ... and a RETN

UPD_CHECK_WIN_XIT:
	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  UPD_CHECK_WIN		; End UPD_CHECK_WIN procedure

VxD_ICODE_ENDS			; End _ICODE segment

	 page
VxD_CODE_SEG			; Begin _LTEXT segment
	 assume  cs:FLAT	; Tell the assembler

	 extrn	 DISPLAY:near		; VMAX_DBG.ASM

BeginProc XUPD_CHECK_WIN	; Unpatch CHECK_WIN in QMAX_XMS.ASM
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Undo the patches put in by UPD_CHECK_WIN

|

	 REGSAVE <esi,fs>	; Save caller's registers

	 mov	 esi,CHECK_WIN_OFFSET ; Offset if patched, or zero

	 or	 esi,esi	; Did we patch anything?
	 jz	 short XUPD_CHECK_WIN_XIT ; Jump if not

; Get addressibility to 386MAX's code with a writeable selector

	 mov	 fs,PGROUP_DS	; Address 386MAX's code w/ a writeable selector
	 assume  fs:nothing	; Tell the assembler

; FS:ESI ==> CHECK_WIN in QMAX_XMS.ASM

	 mov	 ax,OLD_CHECK_WIN.ELO ; Pick up original code from CHECK_WIN
	 mov	 fs:[esi],ax	; Replace it in 386MAX

XUPD_CHECK_WIN_XIT:
	 REGREST <fs,esi>	; Restore caller's registers
	 assume  fs:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  XUPD_CHECK_WIN 	; End XUPD_CHECK_WIN procedure

VxD_CODE_ENDS			; End _LTEXT segment

	 end			; End VMAX_UPD module
