;' $Header:   P:/PVCS/MAX/386MAX/QMAX_LOD.ASV   1.2   30 May 1997 10:45:28   BOB  $
	 title	 QMAX_LOD -- 386MAX File Loader
	 page	 58,122
	 name	 QMAX_LOD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include MAXDEV.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_FIL.INC
	 include QMAX_LOD.INC
	 include QMAX_OEM.INC
	 include QMAX_TDT.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PRGBASE:dword,PaPRGBASE:dword
	 extrn	 TOPBASE:dword
	 extrn	 PHYSIZE:dword

	 extrn	 CON1MB:dword
if @OEM_VCPI
	 extrn	 VCPIBASE:dword
endif				; IF @OEM_VCPI

	 public  LOADBYTE
LOADBYTE dd	 0		; Accumulated byte count of file loads

	 public  LOADCOUNT,LOADTABIND
LOADCOUNT dw	 0		; # entries in LOADTAB
LOADTABIND dw	 @LOAD_MAX*(type LOAD_STR) ; Next available index

	 public  LOADTAB
LOADTAB  LOAD_STR @LOAD_MAX dup (<?>) ; Load table

	 public  SWATCODE,SWATMSG
SWATCODE df	 ?		; Selector:offset of SWAT code segment entry
SWATMSG  df	 ?		; ...			  message ...

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_LOD_ECODE
@QMAX_LOD_ECODE:		; Mark module start in .MAP file

	 extrn	 SET_GDT:near

	 NPPROC  LINPHYS -- Check Linear/Physical DTEs vs Paging
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If paging is disabled, ensure all file load DTEs are physical;
otherwise, ensure all file load DTEs are linear.

$DTE_AVL = 0 ==> DTE is physical
	 = 1 ==>	linear

|

LP_STR	 struc

LP_GDT	 df	 ?		; Save area for GDT

LP_STR	 ends

	 push	 ebp		; Prepare to address the stack
	 sub	 esp,size LP_STR ; Make room for structure
	 mov	 ebp,esp	; Hello, Mr. Stack

	 SGDTD	 [ebp].LP_GDT	; Save on the stack

	 REGSAVE <eax,ebx,cx,ds> ; Save registers

	 mov	 cx,LOADCOUNT	; # DTE pairs to check
	 jcxz	 LINPHYS_EXIT	; No DTEs to check

	 push	 DTE_D4GB	; Get all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 ebx,[ebp].LP_GDT.DTR_BASE ; Get linear base of the GDT
	 lea	 ebx,[ebx].DTE_LOAD ; Plus index into descriptor table

	 mov	 eax,cr0	; Get the control register

	 test	 eax,mask $PG	; Izit enabled?
	 jnz	 short LINPHYS_PG_NEXT ; Yes, ensure all load DTEs are linear
				; No, ensure all load DTEs are physical
LINPHYS_NP_NEXT:

; Convert the first DTE (code)

	 test	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_AVL ; Izit physical?
	 jz	 short @F	 ; Yes

	 call	 LINPHYS_NP_SUB ; Convert it
@@:
	 add	 ebx,size DESC_STR ; Skip to next DTE (data)

; Convert the second DTE (data)

	 test	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_AVL ; Izit physical?
	 jz	 short @F	 ; Yes

	 call	 LINPHYS_NP_SUB ; Convert it
@@:
	 add	 ebx,2*(size DESC_STR) ; Skip over next DTE (VCPI base)

	 loop	 LINPHYS_NP_NEXT ; Jump if more selectors to check

	 jmp	 short LINPHYS_EXIT ; Join common exit code

; Ensure all file load DTEs are linear

LINPHYS_PG_NEXT:

; Convert the first DTE (code)

	 test	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_AVL ; Izit linear?
	 jnz	 short @F	; Yes

	 call	 LINPHYS_PG_SUB ; Convert it
@@:
	 add	 ebx,size DESC_STR ; Skip to next DTE (data)

; Convert the second DTE (data)

	 test	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_AVL ; Izit linear?
	 jnz	 short @F	; Yes

	 call	 LINPHYS_PG_SUB ; Convert it
@@:
	 add	 ebx,2*(size DESC_STR) ; Skip over next DTE (VCPI base)

	 loop	 LINPHYS_PG_NEXT ; Jump if more selectors to check
LINPHYS_EXIT:
	 REGREST <ds,cx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 add	 esp,size LP_STR ; Strip structure from stack

	 pop	 ebp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINPHYS  endp			; End LINPHYS procedure
	 NPPROC  LINPHYS_NP_SUB -- Convert DTE from Linear To Physical
	 assume  ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert DTE from linear to physical.

On entry:

DS:EBX	 ==>   this DTE in the GDT

On exit:

EAX	 =	 clobbered

|

; Get the current DTE base

	 call	 GETBASE	; Return with EAX = selector base of DS:EBX

	 sub	 eax,PRGBASE	; Less the program's linear address
	 add	 eax,PaPRGBASE	; Plus its physical address

	 FCALL	 SETBASE	; Set the selector's base of DS:EBX to EAX

	 and	 AGROUP:[ebx].DESC_SEGLM1,not (mask $DTE_AVL) ; Mark as physical

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINPHYS_NP_SUB endp		; End LINPHYS_NP_SUB procedure
	 NPPROC  LINPHYS_PG_SUB -- Convert DTE From Physical To Linear
	 assume  ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert DTE from physical to linear.

On entry:

DS:EBX	 ==>   this DTE in the GDT

On exit:

EAX	 =	 clobbered

|

; Get the current DTE base

	 call	 GETBASE	; Return with EAX = selector base of DS:EBX

	 sub	 eax,PaPRGBASE	; Less its physical address
	 add	 eax,PRGBASE	; Plus the program's linear address

	 FCALL	 SETBASE	; Set the selector's base of DS:EBX to EAX

	 or	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_AVL ; Mark as linear

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINPHYS_PG_SUB endp		; End LINPHYS_PG_SUB procedure
	 NPPROC  GETBASE -- Return Selector Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the selector base of DS:EBX in EAX.

On entry:

DS:EBX	 =	 descriptor table entry for this selector

On exit:

EAX	 =	 selector base

|

	 mov	 eax,ds:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,ds:[ebx].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETBASE  endp			; End GETBASE procedure
	 FPPROC  SETBASE -- Set Selector Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the selector base of DS:EBX to EAX.

On entry:

EAX	 =	 base to set
DS:EBX	 =	 descriptor table entry for this selector

|


	 mov	 ds:[ebx].DESC_BASE01,ax ; Set bytes 0-1
	 ror	 eax,16 	; Shift down high-order word
	 mov	 ds:[ebx].DESC_BASE2,al ; Set byte 2
	 mov	 ds:[ebx].DESC_BASE3,ah ; Set byte 3
	 rol	 eax,16 	; Shift back

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETBASE  endp			; End SETBASE procedure
	 NPPROC  INIT_PROT -- Initialize API Protected Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize API protected mode for all files

|

	 REGSAVE <eax,ebx,cx,ds> ; Save registers

	 mov	 cx,LOADCOUNT	; Get # files to load
	 jcxz	 INIT_PROT_EXIT ; Jump if none

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

; Establish addressibility to GDT

	 sub	 esp,size DTR_STR ; Make room on stack
	 SGDTD	 [esp].EDF	; Save GDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; ES:EBX ==> GDT
	 add	 esp,size DTR_STR ; Strip from stack

	 lea	 ebx,[ebx].DTE_LOAD ; Plus selector of initial file load
INIT_PROT_NEXT:
	 call	 GETBASE	; Return with EAX = selector base of DS:EBX

; Call protected mode initialization code

	 call	 AGROUP:[eax].MD_IPROT ; Call it

	 add	 ebx,3*(size DESC_STR) ; Skip to next API file

	 loop	 INIT_PROT_NEXT ; Jump if more files to initialize
INIT_PROT_EXIT:
	 REGREST <ds,cx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_PROT endp			; End INIT_PROT procedure
	 NPPROC  REST_PROT -- Restore API Protected Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore API protected mode for all files

|

	 REGSAVE <eax,ebx,cx,ds> ; Save registers

	 mov	 cx,LOADCOUNT	; Get # files to load
	 jcxz	 REST_PROT_EXIT ; Jump if none

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

; Establish addressibility to GDT

	 sub	 esp,size DTR_STR ; Make room on stack
	 SGDTD	 [esp].EDF	; Save GDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; ES:EBX ==> GDT
	 add	 esp,size DTR_STR ; Strip from stack

	 lea	 ebx,[ebx].DTE_LOAD ; Plus selector of initial file load
REST_PROT_NEXT:
	 call	 GETBASE	; Return with EAX = selector base of DS:EBX

; Call protected mode initialization code

	 call	 AGROUP:[eax].MD_RPROT ; Call it

	 add	 ebx,3*(size DESC_STR) ; Skip to next API file

	 loop	 REST_PROT_NEXT ; Jump if more files to restore
REST_PROT_EXIT:
	 REGREST <ds,cx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_PROT endp			; End REST_PROT procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 TDESC_TAB:qword

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_LOD_NCODE
@QMAX_LOD_NCODE:		; Mark module start in .MAP file

	 NPPROC  FILELOAD -- File Loader
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load files from low memory into extended memory.

This routine runs in protected mode only BEFORE paging is enabled.

|

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]
	 REGSAVE <es>		; Save segment register

	 mov	 cx,LOADCOUNT	; Get # files to load

	 and	 cx,cx		; Any files to load
	 jz	 near ptr FILELOAD_EXIT ; None this time

	 mov	 dx,DTE_LOAD	; Get selector of initial file load

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 si,LOADTABIND	; Initialize index into LOADTAB
FILELOAD_NEXT:
	 mov	 ebx,LOADTAB.LOAD_PHYS[si] ; Get physical address of image

	 test	 LOADTAB.LOAD_FLG[si],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jnz	 short @F	; Jump if so

	 movzx	 ebx,LOADTAB.LOAD_SEG[si] ; Get low memory segment
	 shl	 ebx,4-0	; Convert from paras to bytes
@@:
	 mov	 AGROUP:[ebx].MD_IPROT.FSEL,dx ; Save for protected mode init
	 mov	 AGROUP:[ebx].MD_RPROT.FSEL,dx ; Save for protected mode restore

	 mov	 edi,PaPRGBASE	; Get physical address of program base
	 add	 edi,LOADTAB.LOAD_POFF[si] ; Plus offset in PGROUP
	 mov	 AGROUP:[ebx].MD_PHYS,edi ; Save physical address of code segment

	 call	 CHECK_SWAT	; Check for 386SWAT

	 push	 cx		; Save loop counter

	 mov	 ecx,LOADTAB.LOAD_SIZ[si] ; Get the initialized file size
	 add	 ecx,LOADTAB.LOAD_USIZ[si] ; Plus size of uninitialized data

	 mov	 ax,CPL0_CODE	; Start with PL0 code

	 test	 AGROUP:[ebx].MD_ATTR,@MD_USE32 ; Izit a USE32 segment?
	 jz	 short @F	; Jump if not

	 or	 ah,mask $DTE_B ; Mark as USE32 segment
@@:
	 push	 ecx		; Pass segment length
	 push	 ax		; Pass access rights byte
	 push	 dx		; Pass descriptor to set
	 mov	 eax,edi	; Copy current address
	 call	 SET_GDT	; Set the GDT to EAX base

	 add	 dx,size DESC_STR ; Skip to data DTE

	 add	 eax,LOADTAB.LOAD_DAT[si] ; Skip over code segment
	 sub	 ecx,LOADTAB.LOAD_DAT[si] ; Less size of code segment
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 dx		; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base

if @OEM_VCPI
	 mov	 eax,LOADTAB.LOAD_POFF[si] ; Get offset in PGROUP
	 add	 eax,VCPIBASE	; Plus VCPI base address
endif				; IF @OEM_VCPI

; Move data from source (low memory)
;	      to destin (high memory)

	 test	 LOADTAB.LOAD_FLG[si],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jnz	 short @F	; Jump if so

	 REGSAVE <esi,edi>	; Save for a moment

	 mov	 ecx,LOADTAB.LOAD_SIZ[si] ; Get the initialized file size
	 mov	 esi,ebx	; ES:ESI ==> low memory image
				; ES:EDI ==> next available byte in ext memory
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move it
				; ES:EDI ==> next available byte in ext memory
	 REGREST <edi,esi>	; Restore
@@:
	 add	 edi,LOADTAB.LOAD_SIZ[si] ; Plus size of initialized data
	 add	 edi,LOADTAB.LOAD_USIZ[si] ; Plus size of uninitialized data

; Setup common data in loaded file

	 push	 dx		; Pass selector as argument
	 call	 SET_COMMON	; Set 'em up

	 add	 dx,size DESC_STR ; Skip to third DTE

if @OEM_VCPI
; Setup DTE for VCPI interface

	 mov	 ecx,LOADTAB.LOAD_SIZ[si] ; Get the initialized file size
	 add	 ecx,LOADTAB.LOAD_USIZ[si] ; Plus size of uninitialized data

	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 dx		; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base
endif				; IF @OEM_VCPI

; Call protected mode initialization code

	 call	 AGROUP:[ebx].MD_IPROT ; Call it

	 add	 dx,size DESC_STR ; Skip over third DTE
	 add	 si,size LOAD_STR ; Skip to next structure entry

	 pop	 cx		; Restore loop counter

;;;;;;;; loop	 FILELOAD_NEXT	; Jump if more files to load
	 dec	 cx		; Count out one more
	 jnz	 near ptr FILELOAD_NEXT ; Jump if more files to load
FILELOAD_EXIT:
	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILELOAD endp			; End FILELOAD procedure
	 NPPROC  CHECK_SWAT -- Check for 386SWAT
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for 386SWAT.

On entry:

ES:EBX	 ==>	 file loaded into low DOS memory

|

	 cmp	 es:[ebx].MD_NAME.EDQLO,'S683' ; Check for name '386SWAT'
	 jne	 short CHECK_SWAT_EXIT ; Not this time

	 cmp	 es:[ebx].MD_NAME.EDQHI,' TAW' ; Check for name '386SWAT'
	 jne	 short CHECK_SWAT_EXIT ; Not this time

; Copy Inboard/AT bit to SWAT attributes

	 test	 SYS_FLAG,@SYS_INBRDAT ; Izit an Inboard/AT?
	 jz	 short @F	; Jump if not

	 or	 es:[ebx].MD_ATTR,@MD_INBRD ; Mark as Inboard/AT
@@:

; Initialize SWAT variables in DTE_DS (high memory)

	 call	 INIT_SWAT	; Initialize SWAT parameters *FIXME*

; Initialize SWAT variables in DTE_SS (low memory)

	 push	 ds		; Save for a moment

	 push	 DTE_SS 	; Get low memory selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 call	 INIT_SWAT	; Initialize SWAT parameters *FIXME*

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
CHECK_SWAT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SWAT endp 		; End CHECK_SWAT procedure
	 NPPROC  INIT_SWAT -- Initialize SWAT Parameters
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize SWAT parameters

On entry:

DS:SI	 ==>	 Current entry in LOADTAB
DX	 =	 code selector
DX+8	 =	 data selector

|

	 REGSAVE <eax,ebx>	; Save registers

	 or	 LCL_FLAG,@LCL_SWAT ; Mark as debugger installed

	 mov	 eax,LOADTAB.LOAD_PHYS[si] ; Get physical address of image

	 test	 LOADTAB.LOAD_FLG[si],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jnz	 short @F	; Jump if so

	 movzx	 eax,LOADTAB.LOAD_SEG[si] ; Get low memory segment
	 shl	 eax,4-0	; Convert from paras to bytes
@@:
	 mov	 ebx,AGROUP:[eax].MD_INIT ; Get offset to initial code
	 mov	 SWATCODE.FOFF,ebx ; Save for later use
	 mov	 SWATCODE.FSEL,dx ; Save selector

	 mov	 ebx,AGROUP:[eax].MD_MSG ; Get offset to error message code
	 mov	 SWATMSG.FOFF,ebx ; Save for later use
	 mov	 SWATMSG.FSEL,dx ; Save selector

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_SWAT endp			; End INIT_SWAT procedure
	 NPPROC  SET_COMMON -- Setup Common Data Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup common file load data area

|

SETCOM_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SETCOM_DS dw	 ?		; Data selector

SETCOM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ds>		; Save register

	 mov	 ds,[ebp].SETCOM_DS ; Address the file's data segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[0].FILE_4GB,DTE_D4GB ; Save descriptor
	 mov	 ds:[0].FILE_VID,DTE_VID  ; Save descriptor
	 mov	 ds:[0].FILE_CR3,DTE_CR3  ; Save descriptor

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_COMMON endp 		; End SET_COMMON procedure
if @OEM_DEBUG
	 NPPROC  SWATINI -- Initialize 386SWAT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize 386SWAT into GDT and IDT.
This routine is called from protected mode only.

On exit:

CF	 =	 0 if 386SWAT loaded
	 =	 1 if not

|

	 REGSAVE <eax,ebx,ecx,dx,si,es,fs> ; Save registers

	 mov	 cx,LOADCOUNT	; Get # files to load

	 and	 cx,cx		; Any modules loaded?
	 jz	 near ptr SWATINI_ERR ; Jump if none

	 mov	 dx,TDTE_LOAD	; Get selector of initial file load

	 push	 TDTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 si,LOADTABIND	; Initialize index into LOADTAB
SWATINI_NEXT:
	 mov	 ebx,LOADTAB.LOAD_PHYS[si] ; Get physical address of image

	 test	 LOADTAB.LOAD_FLG[si],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jnz	 short @F	; Jump if so

	 movzx	 ebx,LOADTAB.LOAD_SEG[si] ; Get low memory segment
	 shl	 ebx,4-0	; Convert from paras to bytes
@@:
	 cmp	 AGROUP:[ebx].MD_NAME.EDQLO,'S683' ; Check for name '386SWAT'
	 jne	 short SWATINI_LOOP ; Not this time

	 cmp	 AGROUP:[ebx].MD_NAME.EDQHI,' TAW' ; Check for name '386SWAT'
	 jne	 short SWATINI_LOOP ; Not this time

	 mov	 AGROUP:[ebx].MD_IPROT.FSEL,dx ; Save for protected mode init
	 mov	 AGROUP:[ebx].MD_RPROT.FSEL,dx ; Save for protected mode restore

	 mov	 ecx,LOADTAB.LOAD_SIZ[si] ; Get the file size
	 add	 ecx,LOADTAB.LOAD_USIZ[si] ; Plus size of uninitialized data

	 mov	 eax,ebx	; Copy current address
	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 dx		; Pass descriptor to set
	 call	 SET_TGDT	; Set the timing GDT to EAX base

	 add	 dx,size DESC_STR ; Skip to data DTE

	 add	 eax,LOADTAB.LOAD_DAT[si] ; Skip over code segment
	 sub	 ecx,LOADTAB.LOAD_DAT[si] ; Less size of code segment
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 dx		; Pass descriptor to set
	 call	 SET_TGDT	; Set the timing GDT to EAX base

; Setup common data selectors

	 mov	 fs,dx		; Address caller's data area
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 fs:[0].FILE_4GB,TDTE_D4GB ; Save descriptor
;;;;;;;; mov	 fs:[0].FILE_VID,TDTE_VID  ; Save descriptor
;;;;;;;; mov	 fs:[0].FILE_CR3,TDTE_CR3  ; Save descriptor

; Call protected mode initialization code

	 call	 AGROUP:[ebx].MD_IPROT ; Call it

	 clc			; Indicate all went well

	 jmp	 short SWATINI_EXIT ; Join common exit code

SWATINI_LOOP:
	 add	 si,size LOAD_STR ; Skip to next structure entry

	 loop	 SWATINI_NEXT	; Jump if more load files to check
SWATINI_ERR:
	 stc			; Indicate not loaded
SWATINI_EXIT:
	 REGREST <fs,es,si,dx,ecx,ebx,eax> ; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWATINI  endp			; End SWATINI procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 NPPROC  SET_TGDT -- Set Timing Global Descriptor Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the global descriptor table to base EAX.

Note that this routine executes in protected mode only.

On entry:

EAX	 =	 segment base

|

SET_TGDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SET_TGDT_DTE dw  ?		; DTE to set
SET_TGDT_ARB db  ?		; Access rights byte
SET_TGDT_FLG db  ?		; DTE flags
SET_TGDT_LEN dd  ?		; Segment length

SET_TGDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <bx,ecx>	; Save registers

	 mov	 ecx,[ebp].SET_TGDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1MB	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 [ebp].SET_TGDT_FLG,mask $DTE_G ; Set G-bit
@@:
	 mov	 bx,[ebp].SET_TGDT_DTE ; Get the DTE to set

	 mov	 TDESC_TAB.DESC_BASE01.EDD[bx],eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.DESC_BASE3[bx],al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.DESC_SEGLM0[bx],cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 or	 cl,[ebp].SET_TGDT_FLG ; Include any flags
	 mov	 TDESC_TAB.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 cl,[ebp].SET_TGDT_ARB ; Get it
	 mov	 TDESC_TAB.DESC_ACCESS[bx],cl ; Set it

	 REGREST <ecx,bx>	; Restore

	 pop	 ebp		; Restore

	 ret	 2*2+1*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_TGDT endp			; End SET_TGDT procedure
endif				; IF @OEM_DEBUG

NCODE	 ends			; End NCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
XDATA	 ends			; End XDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_LOD_XCODE
@QMAX_LOD_XCODE:		; Mark module start in .MAP file

	 NPPROC  CALC_LODSTART -- Calculate The Start Of Each LOD Module
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the start (offset in PGROUP) of each LOD module

This number is A - B where

A is (TOPBASE - PRGBASE)    which is the distance from the top of linear memory
B is (PHYSIZE - LOAD_PHYS)  ... 				  physical ...

The actual calculation is (TOPBASE - PRGBASE - PHYSIZE) + LOAD_PHYS

|

	 REGSAVE <eax,ebx,cx,si> ; Save registers

	 mov	 cx,LOADCOUNT	; CX = number of entries to process
	 jcxz	 CALC_LODSTART_EXIT ; No entries to process

; Calculate the offset in PGROUP of this LOD module

	 mov	 eax,TOPBASE	; Get top of extended memory
	 and	 ax,not (4*1024-1) ; Round down to 4KB boundary
	 sub	 eax,PRGBASE	; Less start of PRG to get distance from the
				; top of linear memory
	 mov	 ebx,PHYSIZE	; Use current physical size
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 and	 bx,not (4*1024-1) ; Round down to 4KB boundary

	 sub	 eax,ebx	; Subtract to get above number
	 mov	 si,LOADTABIND	; Initialize index into LOADTAB
CALC_LODSTART_NEXT:
	 mov	 ebx,eax	; Copy above number

	 add	 ebx,LOADTAB.LOAD_PHYS[si] ; Plus physical address of image
	 mov	 LOADTAB.LOAD_POFF[si],ebx ; Save for later use

	 add	 si,size LOAD_STR ; Skip to next structure entry

	 loop	 CALC_LODSTART_NEXT ; Jump if more LOD modules
CALC_LODSTART_EXIT:
	 REGREST <si,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_LODSTART endp		; End CALC_LODSTART procedure
	 FPPROC  INIT_VIRT -- Initialize All Virtual Mode Load Modules
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize API Virtual mode for all files

This procedure is called just before we relocate the XBDA and
fill the STACKS structure.  PGROUP in low DOS may be partly
destroyed by the code called by this procedure under the following
combination of circumstances:

- A load module with INIT_VIRT exists
- That load module has requested PL0 DPMI services
- In that load module's INIT_VIRT, the full HPDA is used
- HPDAREG is low (default)

Since HPDAREG is the first subsegment we'll relocate low, it should
start at XHI_ENDADDR.  Upon return, any PGROUP data must be taken from
PGRSEG below XHI_ENDADDR.

On entry:
LOADCOUNT is assumed to be non-zero

On exit:

CF	 =	 0 if all went well
	 =	 1 if error

|

	 REGSAVE <bx,cx,ds,es>	; Save registers

; Get the address and count of Load Table

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 cx,LOADCOUNT	; Number of entries to process
;;;;;;;  jcxz	 INIT_VIRT_CLC	; No entries to process

	 mov	 bx,LOADTABIND	; Initialize index into LOADTAB
INIT_VIRT_NEXT:

; Get the address of the file image

	 mov	 ds,LOADTAB.LOAD_SEG[bx] ; Get segment where file image is
	 assume  ds:nothing	; Tell the assembler about it

; Does this file support the INIT_VIRT entry point?

	 test	 ds:[0].MD_ATTR,@MD_VER ; Does this one have init_virt?
	 jz	 short INIT_VIRT_LOOP ; Nope, try next one

; Call the file's INIT_VIRT routine

	 call	 ds:[0].MD_IVIRT ; Call it!

	 test	 ds:[0].MD_ATTR,@MD_VMIE ; Did it fail?
	 jnz	 short INIT_VIRT_ERR ; Jump if so
INIT_VIRT_LOOP:
	 add	 bx,size LOAD_STR ; Skip to next structure entry

	 loop	 short INIT_VIRT_NEXT ; Do next file
INIT_VIRT_CLC:
	 clc			; Mark as successful

	 jmp	 short INIT_VIRT_EXIT ; Join common exit code

; Something went wrong with a file's VM init routine
; Tell the user, reset our interrupts through INTR_SET,
; and call GOREAL to enter back into real mode.

INIT_VIRT_ERR:






	 stc			; Mark as in error
INIT_VIRT_EXIT: 		; Note: CF flag is significant
	 REGREST <es,ds,cx,bx>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_VIRT endp			; End INIT_VIRT procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_LOD module
