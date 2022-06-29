	page	,132
	.listall

;Thunk Compiler Version 1.8  May 11 1995 13:16:19
;File Compiled Mon Jun 15 16:51:37 1998

;Command Line: M:\BIN\thunk -t thk S32THK.THK -o ret\W32\S32THK.ASM 

	TITLE	$ret\W32\S32THK.ASM

	.386
	OPTION READONLY


IFNDEF IS_16
IFNDEF IS_32
%out command line error: specify one of -DIS_16 -DIS_32
.err
ENDIF
ENDIF
IFDEF IS_16
IFDEF IS_32
%out command line error: you can't specify both -DIS_16 and -DIS_32
.err
ENDIF

	OPTION SEGMENT:USE16
	.model LARGE,PASCAL

externDef DoesValueExist32:far16
externDef RenameValue32:far16
externDef ItsOurDLL32:far16
externDef DelKey32:far16
externDef Is95Ver32:far16
externDef CompareVersionInfo32:far16
externDef AddReg32:far16
externDef ChangePEVersionNumbers32:far16

externDef C16ThkSL01:far16


	.data

public thk_ThunkData16	;This symbol must be exported.
thk_ThunkData16	dd	31304c53h	;Protocol 'SL01'
	dd	09173h	;Checksum
	dd	0		;Flags.
	dd	0		;RESERVED. MUST BE ZERO.
	dd	0		;RESERVED. MUST BE ZERO.
	dd	0		;RESERVED. MUST BE ZERO.
	dd	0		;RESERVED. MUST BE ZERO.
	dd	3130424ch	;Late-binding signature 'LB01'
	dd	080000000h		;More flags.
	dd	0		;RESERVED. MUST BE ZERO.
	dw	offset thk_ThunkData16ApiDatabase
	dw	   seg thk_ThunkData16ApiDatabase


;; Api database. Each entry == 8 bytes:
;;  byte  0:     # of argument bytes.
;;  byte  1,2,3: Reserved: Must initialize to 0.
;;  dword 4:	 error return value.
public thk_ThunkData16ApiDatabase
thk_ThunkData16ApiDatabase	label	dword
	db	12
	db	0,0,0
	dd	0
	db	16
	db	0,0,0
	dd	0
	db	4
	db	0,0,0
	dd	0
	db	12
	db	0,0,0
	dd	0
	db	4
	db	0,0,0
	dd	0
	db	8
	db	0,0,0
	dd	0
	db	24
	db	0,0,0
	dd	0
	db	12
	db	0,0,0
	dd	0




	.code 


externDef ThunkConnect16:far16

public thk_ThunkConnect16
thk_ThunkConnect16:
	pop	ax
	pop	dx
	push	seg    thk_ThunkData16
	push	offset thk_ThunkData16
	push	seg    thk_TD32Label
	push	offset thk_TD32Label
	push	cs
	push	dx
	push	ax
	jmp	ThunkConnect16
thk_TD32Label label byte
	db	"thk_ThunkData32",0


DoesValueExist32 label far16
	mov	cx,0			; offset in jump table
	jmp	thkEntryCommon

RenameValue32 label far16
	mov	cx,4			; offset in jump table
	jmp	thkEntryCommon

ItsOurDLL32 label far16
	mov	cx,8			; offset in jump table
	jmp	thkEntryCommon

DelKey32 label far16
	mov	cx,12			; offset in jump table
	jmp	thkEntryCommon

Is95Ver32 label far16
	mov	cx,16			; offset in jump table
	jmp	thkEntryCommon

CompareVersionInfo32 label far16
	mov	cx,20			; offset in jump table
	jmp	thkEntryCommon

AddReg32 label far16
	mov	cx,24			; offset in jump table
	jmp	thkEntryCommon

ChangePEVersionNumbers32 label far16
	mov	cx,28			; offset in jump table
	jmp	thkEntryCommon

;===========================================================================
; This is the common setup code for 16=>32 thunks.
;
; Entry:  cx  = offset in flat jump table
;
; Don't optimize this code: C16ThkSL01 overwrites it
; after each discard.

align
thkEntryCommon:
	db	0ebh, 030	;Jump short forward 30 bytes.
;;; Leave at least 30 bytes for C16ThkSL01's code patching.
	db	30 dup(0cch)	;Patch space.
	push	seg    thk_ThunkData16
	push	offset thk_ThunkData16
	pop	edx
	push	cs
	push	offset thkEntryCommon
	pop	eax
	jmp	C16ThkSL01

ELSE	; IS_32
	.model FLAT,STDCALL

externDef STDCALL K32Thk1632Prolog@0:near32
externDef STDCALL K32Thk1632Epilog@0:near32
externDef STDCALL DoesValueExist32@12:near32
externDef STDCALL RenameValue32@16:near32
externDef STDCALL ItsOurDLL32@4:near32
externDef STDCALL DelKey32@12:near32
externDef STDCALL Is95Ver32@4:near32
externDef STDCALL CompareVersionInfo32@8:near32
externDef STDCALL AddReg32@24:near32
externDef STDCALL ChangePEVersionNumbers32@12:near32

MapSLFix		proto	STDCALL  :DWORD
MapSL		proto	STDCALL  :DWORD
UnMapSLFixArray		proto	STDCALL  :DWORD, :DWORD
externDef	MapHInstSL:near32
externDef	MapHInstSL_PN:near32
externDef	MapHInstLS:near32
externDef	MapHInstLS_PN:near32
externDef T_DOESVALUEEXIST32:near32
externDef T_RENAMEVALUE32:near32
externDef T_ITSOURDLL32:near32
externDef T_DELKEY32:near32
externDef T_IS95VER32:near32
externDef T_COMPAREVERSIONINFO32:near32
externDef T_ADDREG32:near32
externDef T_CHANGEPEVERSIONNUMBERS32:near32

;===========================================================================
	.code 


; This is a jump table to API-specific flat thunk code.

align
thk_JumpTable label dword
	dd	offset FLAT:T_DOESVALUEEXIST32
	dd	offset FLAT:T_RENAMEVALUE32
	dd	offset FLAT:T_ITSOURDLL32
	dd	offset FLAT:T_DELKEY32
	dd	offset FLAT:T_IS95VER32
	dd	offset FLAT:T_COMPAREVERSIONINFO32
	dd	offset FLAT:T_ADDREG32
	dd	offset FLAT:T_CHANGEPEVERSIONNUMBERS32

thk_ThunkDataName label byte
	db	"thk_ThunkData16",0

	.data

public thk_ThunkData32	;This symbol must be exported.
thk_ThunkData32	dd	31304c53h	;Protocol 'SL01'
	dd	09173h	;Checksum
	dd	0	;Reserved (MUST BE 0)
	dd	0	;Flat address of ThunkData16
	dd	3130424ch	;'LB01'
	dd	0	;Flags
	dd	0	;Reserved (MUST BE 0)
	dd	0	;Reserved (MUST BE 0)
	dd	offset thk_JumpTable - offset thk_ThunkDataName



	.code 


externDef ThunkConnect32@24:near32

public thk_ThunkConnect32@16
thk_ThunkConnect32@16:
	pop	edx
	push	offset thk_ThunkDataName
	push	offset thk_ThunkData32
	push	edx
	jmp	ThunkConnect32@24


;===========================================================================
; Common routines to restore the stack and registers
; and return to 16-bit code.  There is one for each
; size of 16-bit parameter list in this script.

align
ExitFlat_4:
	mov	cl,4		; parameter byte count
	mov	esp,ebp		; point to return address
	retn			; return to dispatcher

align
ExitFlat_8:
	mov	cl,8		; parameter byte count
	mov	esp,ebp		; point to return address
	retn			; return to dispatcher

align
ExitFlat_12:
	mov	cl,12		; parameter byte count
	mov	esp,ebp		; point to return address
	retn			; return to dispatcher

align
ExitFlat_16:
	mov	cl,16		; parameter byte count
	mov	esp,ebp		; point to return address
	retn			; return to dispatcher

align
ExitFlat_24:
	mov	cl,24		; parameter byte count
	mov	esp,ebp		; point to return address
	retn			; return to dispatcher

;===========================================================================
T_DOESVALUEEXIST32 label near32

; ebx+30   hkRootKey
; ebx+26   szKey
; ebx+22   szValName

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szKey inline mapping
; szValName inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szKey
; pointer char --> char
; inline mapping

; szValName
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szValName  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

; szKey  from: char
	mov	eax, [ebx+26]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

; hkRootKey  from: unsigned long
	push	dword ptr [ebx+30]	; to unsigned long

	call	K32Thk1632Prolog@0
	call	DoesValueExist32@12		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 2
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_12

;===========================================================================
T_RENAMEVALUE32 label near32

; ebx+34   hkRootKey
; ebx+30   szKey
; ebx+26   szOldValName
; ebx+22   szNewValName

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szKey inline mapping
; szOldValName inline mapping
; szNewValName inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szKey
; pointer char --> char
; inline mapping

; szOldValName
; pointer char --> char
; inline mapping

; szNewValName
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szNewValName  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

; szOldValName  from: char
	mov	eax, [ebx+26]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

; szKey  from: char
	mov	eax, [ebx+30]		; base address
	mov	[esp + 16],eax
	push	eax
	call	MapSLFix	
	push	eax

; hkRootKey  from: unsigned long
	push	dword ptr [ebx+34]	; to unsigned long

	call	K32Thk1632Prolog@0
	call	RenameValue32@16		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 3
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_16

;===========================================================================
T_ITSOURDLL32 label near32

; ebx+22   szFileName

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
; szFileName inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szFileName
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szFileName  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

	call	K32Thk1632Prolog@0
	call	ItsOurDLL32@4		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 1
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_4

;===========================================================================
T_DELKEY32 label near32

; ebx+30   hkRootKey
; ebx+26   szParentKey
; ebx+22   szDelKey

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szParentKey inline mapping
; szDelKey inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szParentKey
; pointer char --> char
; inline mapping

; szDelKey
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szDelKey  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

; szParentKey  from: char
	mov	eax, [ebx+26]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

; hkRootKey  from: unsigned long
	push	dword ptr [ebx+30]	; to unsigned long

	call	K32Thk1632Prolog@0
	call	DelKey32@12		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 2
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_12

;===========================================================================
T_IS95VER32 label near32

; ebx+22   szOld

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
; szOld inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szOld
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szOld  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

	call	K32Thk1632Prolog@0
	call	Is95Ver32@4		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code unsigned long --> unsigned long
	mov	edx,eax
	rol	edx,16

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 1
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_4

;===========================================================================
T_COMPAREVERSIONINFO32 label near32

; ebx+26   szOld
; ebx+22   szNew

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szOld inline mapping
; szNew inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szOld
; pointer char --> char
; inline mapping

; szNew
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szNew  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

; szOld  from: char
	mov	eax, [ebx+26]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

	call	K32Thk1632Prolog@0
	call	CompareVersionInfo32@8		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code unsigned long --> unsigned long
	mov	edx,eax
	rol	edx,16

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 2
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_8

;===========================================================================
T_ADDREG32 label near32

; ebx+42   hkRootKey
; ebx+38   szKey
; ebx+34   szValName
; ebx+30   szVal
; ebx+26   dwType
; ebx+22   dwLen

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szKey inline mapping
; szValName inline mapping
; szVal inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szKey
; pointer char --> char
; inline mapping

; szValName
; pointer char --> char
; inline mapping

; szVal
; pointer unsigned char --> unsigned char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; dwLen  from: unsigned long
	push	dword ptr [ebx+22]	; to unsigned long

; dwType  from: unsigned long
	push	dword ptr [ebx+26]	; to unsigned long

; szVal  from: unsigned char
	mov	eax, [ebx+30]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

; szValName  from: char
	mov	eax, [ebx+34]		; base address
	mov	[esp + 16],eax
	push	eax
	call	MapSLFix	
	push	eax

; szKey  from: char
	mov	eax, [ebx+38]		; base address
	mov	[esp + 24],eax
	push	eax
	call	MapSLFix	
	push	eax

; hkRootKey  from: unsigned long
	push	dword ptr [ebx+42]	; to unsigned long

	call	K32Thk1632Prolog@0
	call	AddReg32@24		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 3
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_24

;===========================================================================
T_CHANGEPEVERSIONNUMBERS32 label near32

; ebx+30   szSrc
; ebx+26   szDst
; ebx+22   szImage

;-------------------------------------
; temp storage

	xor	eax,eax
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
	push	eax	;MapLS unfix temp
; szSrc inline mapping
; szDst inline mapping
; szImage inline mapping
;-------------------------------------
; *** BEGIN parameter packing

; szSrc
; pointer char --> char
; inline mapping

; szDst
; pointer char --> char
; inline mapping

; szImage
; pointer char --> char
; inline mapping

; *** END   parameter packing
;-------------------------------------
; create new call frame and make the call

; szImage  from: char
	mov	eax, [ebx+22]		; base address
	mov	[esp + 0],eax
	push	eax
	call	MapSLFix	
	push	eax

; szDst  from: char
	mov	eax, [ebx+26]		; base address
	mov	[esp + 8],eax
	push	eax
	call	MapSLFix	
	push	eax

; szSrc  from: char
	mov	eax, [ebx+30]		; base address
	mov	[esp + 16],eax
	push	eax
	call	MapSLFix	
	push	eax

	call	K32Thk1632Prolog@0
	call	ChangePEVersionNumbers32@12		; call 32-bit version
	call	K32Thk1632Epilog@0

; return code long --> short
; no conversion needed

	lea	ecx, [esp+0]
	push	ecx
	push	dword ptr 3
	call	UnMapSLFixArray	;! Preserves eax & edx
;-------------------------------------
	jmp	ExitFlat_12

ENDIF
END
