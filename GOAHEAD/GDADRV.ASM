;' $Header:   P:/PVCS/MAX/GOAHEAD/GDADRV.ASV   1.9   07 Mar 1996 11:29:50   BOB  $
	title	GDADRV -- GlobalDOSAlloc Fixer
	page	58,122
	name	GDADRV
.386p
.xlist
	include MASM.INC
	include WINDOWS.INC
	include OPCODES.INC
	include ASCII.INC
	include 386.INC
	include PTR.INC
	include CPUFLAGS.INC
	include DPMI.INC
	include TOOLHELP.INC
	include DOSCALL.INC
	include OPEN.INC
	include WINSTR.INC

	include GDADRV.INC
	include MISCFNS.INC
.list


DGROUP	group	_DATA

DEBUG_MAC macro  NN
	local	L1

	test	LCL_FLAG,@LCL_DBG ; Are we in a debuggin' mood?
	jz	short L1	; Jump if not

	int	01h		; Call our debugger
ifnb <NN>
	jmp	short L1	; Skip over signature

	mov	al,NN		; Make it an instruction for disassembly
endif				; IFNB <NN>
L1:
	endm			; DEBUG_MAC


POPF_STR struc

	dw	?		; Caller's BP
POPF_FL dw	?		; ...	   FL

POPF_STR ends

POPF_MAC macro			; Use to POP Interrupt Flag
	local	L1

;;;;;;; popf			; Restore flags

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	xchg	ax,[bp].POPF_FL ; Swap with flags

	test	ax,mask $IF	; Was IF set?
	jz	short L1	; Jump if not

	sti			; Enable it again
L1:
	sahf			; Tell the CPU about it

	pop	bp		; Restore
	pop	ax		; ...

	endm			; POPF_MAC


	extrn	GetWinFlags:far
	extrn	GetVersion:far

	extrn	NotifyRegister:far
	extrn	NotifyUnregister:far
	extrn	TaskFirst:far
	extrn	TaskNext:far
	extrn	TaskFindHandle:far

	extrn	GetModuleHandle:far
	extrn	GetProcAddress:far

	extrn	GetCurrentTask:far

	extrn	AllocCStoDSAlias:far
	extrn	FreeSelector:far

	extrn	GlobalDOSAlloc:far
;;;;;;; extrn	GlobalAlloc:far
	extrn	GlobalDOSFree:far
	extrn	GlobalFree:far

	extrn	LockSegment:far
	extrn	UnlockSegment:far

	extrn	DefDriverProc:far

	extrn	IsWindow:far
	extrn	PostMessage:far

	extrn	GetPrivateProfileInt:far
	extrn	GetPrivateProfileString:far
	extrn	WritePrivateProfileString:far
	extrn	GetSystemDirectory:far
;..............................................
_DATA	segment use16 dword public 'DATA' ; Start _DATA segment
	assume	ds:DGROUP

@CON64KB equ	  64*1024	; Constant 64KB
@CON1MB  equ	1024*1024	; ...	    1MB

@MaxDOSAlloc equ 64*1024	; Maximum DOS allocation size
@MinDOSAlloc equ 16		; Minimum ...

	public	cbDOSAlloc,dwAccumFree
cbDOSAlloc dd	?		; Current DOS allocation size
dwAccumFree dd	?		; # free bytes


DATA_MAC macro	TXT,NAME

	public	lp&TXT&Proc,lpLCL_&TXT&Proc
lp&TXT&Proc dd	NAME		; Save area for &NAME& proc address
lpLCL_&TXT&Proc dd LCL_&TXT&Proc ; ...		 LCL_&TXT&Proc ...
TXT&ProcSel dw	?		; Selector of &TXT& procedure

	endm			; DATA_MAC


;;;;;;; DATA_MAC GA, GlobalAlloc    ; Define data for GA
	DATA_MAC GDA,GlobalDOSAlloc ; ...	      GDA
	DATA_MAC GF, GlobalFree     ; ...	      GF
	DATA_MAC GDF,GlobalDOSFree  ; ...	      GDF

	public	SelIncr
SelIncr dw	8		; Selector increment value

	public	wLowSeg
wLowSeg dw	-1		; Lowest free segment we've encountered

	public	hIniTask
hIniTask dw	?		; Handle of initial task

	public	hOurOwnr
hOurOwnr dw	?		; Handle of initial task


DOSMem_STR struc

DOSMemSeg dw	?		; Segment in 1st megabyte
DOSMemSel dw	?		; Selector
DOSMemELen dw	?		; Length in paras of this individual entry
DOSMemTLen dw	?		; Total length in paras including following
				; adjacent entries
DOSMemAdj dw	?		; # adjacent entries including this one, 1=alone

DOSMem_STR ends


@DOSCnt equ	256		; # DOS segment allocations we support

; The following two data values (DOSMemCnt and DOSMem) must be
; contiguous as other code depends upon getting the count value
; by reading the word which precedes the buffer address.

	public	wGore,DOSMemCnt,DOSMem
wGore	dw	0		; Amount of DOS memory to remain free
				; -1 = disabled
DOSMemCnt dw	0		; # DOS segments allocated
DOSMem	DOSMem_STR @DOSCnt dup (<>) ; Table of DOS memory


	public	LCL_FLAG
LCL_FLAG LCL_REC <>		; Local flags

	align	4
	public	LCL_INST_GDA,LCL_INST_GA
	public	LCL_INST_GDF,LCL_INST_GF
LCL_INST_GA  dd 0		; Counter for GA installs
LCL_INST_GDA dd 0		; ...	      GDA ...
LCL_INST_GF  dd 0		; ...	      GF  ...
LCL_INST_GDF dd 0		; ...	      GDF ...

@NHREGS equ	4		; # registered handles we support

REG_STR struc

REG_hWnd dw	0		; hWnd of WinApp to which messages should be
				; posted (0=none)
REG_uDOSMsg dw	?		; Command message # for DOS memory changes
REG_uTSKMsg dw	?		; ...			task count changes

REG_STR ends

	public	hRegs
	align	4
hRegs	REG_STR @NHREGS dup (<>) ; Registered handles

	public	GAProc,GFProc
GAProc	db	(1+4) dup (?)	; Save area for 1st five bytes of GA procedure
GFProc	db	(1+4) dup (?)	; ...				  GF ...

	public	GDAProc,GDFProc
GDAProc db	(1+4) dup (?)	; Save area for 1st five bytes of GDA procedure
GDFProc db	(1+4) dup (?)	; ...				  GDF ...

	public	lpSysINIFile,szSysINIFile
	align	4
lpSysINIFile dd DGROUP:szSysINIFile ; Ptr to SYSTEM.INI filename
szSysINIFile db 'system.ini',0 ; SYSTEM.INI file name

	public	lpBootSect,szBootSect
	align	4
lpBootSect dd	DGROUP:szBootSect ; Ptr to section name
szBootSect db	'boot',0        ; Section name with "drivers=" line

	public	lpLineName,szLineName
	align	4
lpLineName dd	DGROUP:szLineName ; Ptr to line name
szLineName db	'drivers',0     ; Line name of "drivers=" line

lpDrvrSect equ	lpLineName	; Re-use the same name

	 public  lpDrvrNam2,szDrvrNam2
	align	4
lpDrvrNam2 dd	DGROUP:szDrvrNam2 ; Ptr to line name for WritePrivateProfileString
szDrvrNam2 db	@FILENAME,0	; Name of "GOAHEAD=" line in [drivers] section

	public	lpDrvrValue,szDrvrValue
	align	4
lpDrvrValue dd	DGROUP:szDrvrValue ; Ptr to line name for WritePrivateProfileString
szDrvrValue db	@FILENAMEXT,0	; Value of "GOAHEAD.DRV"

	public	lpBootDescSect,szBootDescSect
	align	4
lpBootDescSect dd DGROUP:szBootDescSect ; Ptr to section name
szBootDescSect db 'boot.description',0 ; Section name with "GOAHEAD=" line

	public	lpBootDesc,szBootDesc
	align	4
lpBootDesc dd	DGROUP:szBootDesc ; Ptr to description
szBootDesc db	'DOS Memory Control',0 ; Description

	public	lpDefValue,szDefValue
	align	4
lpDefValue dd	DGROUP:szDefValue ; Ptr to default value for GetPrivateProfileString
szDefValue db	0		; Default value for GetPrivateProfileString

	public	lpStrBuf1,szStrBuf1
	align	4
lpStrBuf1 dd	DGROUP:szStrBuf1 ; Ptr to string buffer #1
@StrBufLen equ	256		; Length of ...
szStrBuf1 db	@StrBufLen dup (0) ; String buffer #1

	public	lpStrBuf2,szStrBuf2
	align	4
lpStrBuf2 dd	DGROUP:szStrBuf2 ; Ptr to string buffer #2
@StrBufLen equ	256		; Length of ...
szStrBuf2 db	@StrBufLen dup (0) ; String buffer #2

	public	lpDrvrName,szDrvrName
lpDrvrName dd	DGROUP:szDrvrName ; Ptr to driver name followed by string buffer
szDrvrName db	@FILENAMEXT,' ' ; Driver filename.ext
szDrvrNameLen equ $-szDrvrName-1 ; Length of ... (less trailing blank)

	public	lpAfterLine,szAfterLine
	align	4
lpAfterLine dd	DGROUP:szAfterLine ; Ptr to line name
szAfterLine db	'LoadAfter',0   ; Line name of "LoadAfter=" line

	public	lpAfterDef,szAfterDef
	align	4
lpAfterDef dd	DGROUP:szAfterDef ; Ptr to default value
szAfterDef db	'mmsystem.dll',0 ; Default value
szAfterDefLen equ $-szAfterDef-1 ; Length of ... (less trailing blank)

	public	lpAfterBuf,szAfterBuf
lpAfterBuf dd  DGROUP:szAfterBuf ; Ptr to buffer
@AfterBufLen equ 32		; Length of After module string
szAfterBuf db	@AfterBufLen dup (0) ; After module string

	public	lpSBLine,szSBLine
	align	4
lpSBLine dd	DGROUP:szSBLine ; Ptr to buffer
@SBLineLen equ	32		; Length of SB line name buffer
szSBLine db	@SBLineLen dup (0) ; SB line name buffer

	public	lpSBBuf,szSBBuf
	align	4
lpSBBuf dd	DGROUP:szSBBuf	; Ptr to buffer
@SBBufLen equ	32		; Length of SB buffer
szSBBuf db	@SBBufLen dup (0) ; SB buffer

	public	lpWave,szWave
	align	4
lpWave	dd	DGROUP:szWave	; Ptr to line name
szWave	db	'wave',0        ; Line name of "wave="
szWaveLen equ	$-szWave-1	; Length of ... (less trailing zero)

	public	lpMIDI,szMIDI
	align	4
lpMIDI	dd	DGROUP:szMIDI	; Ptr to line name
szMIDI	db	'MIDI',0        ; Line name of "MIDI="
szMIDILen equ	$-szMIDI-1	; Length of ... (less trailing zero

	public	lpSNDBLST2,szSNDBLST2
	align	4
lpSNDBLST2 dd	DGROUP:szSNDBLST2 ; Ptr to line value
szSNDBLST2 db	'SNDBLST2.DRV',0 ; Line value

	public	lpQMAXINIFile,szQMAXINIFile
	align	4
lpQMAXINIFile dd DGROUP:szQMAXINIFile ; Ptr to QMAX.INI filename
szQMAXINIFile db 'qmax.ini',0   ; QMAX.INI file name

	public	lpProgSect,szProgSect
lpProgSect dd	DGROUP:szProgSect ; Ptr to Programs section name
szProgSect db	'Go Ahead - Programs',0 ; Programs section name

	public	lpGenSect,szGenSect
lpGenSect dd	DGROUP:szGenSect ; Ptr to General section name
szGenSect db	'Go Ahead - General',0 ; General section name

	public	lpDbgName,szDbgName
	align	4
lpDbgName dd	DGROUP:szDbgName ; Ptr to line name
szDbgName db	'Debug',0       ; Line name of "Debug=" line

	public	lpGFAName,szGFAName
	align	4
lpGFAName dd	DGROUP:szGFAName ; Ptr to line name
szGFAName db	'GFAlloc',0     ; Line name of "GFAlloc=" line

	public	lpGMH,dwTaskCnt,lpNotify
	align	4
lpGMH	dd	0		; Sel:Off of GlobalMasterHandle()
dwTaskCnt dd	0		; Count of active tasks
lpNotify dd	LCL_Notify	; Local function to receive notifications

	 public  szKERNEL,szGMH
szKERNEL db	"KERNEL",0      ; Module name
szGMH	db	"GLOBALMASTERHANDLE",0 ; Function name


@MEMHISTCNT equ 64	       ; # memory history table entries

MemHistStr struc

MemHistFree dw	?		; # paras free

MemHistStr ends

	 public  MemHistStart,MemHistEnd,MemHistHead,MemHistTab

; The following data items from MemHistStart to MemHistTab inclusive
; must be consecutive to the memory history buffer can be read by Win Apps

MemHistStart dw 0		; Static buffer index start
MemHistEnd dw	@MEMHISTCNT	; ...		      end
MemHistHead dw	0		; Dynamic buffer index head (next entry)
MemHistTab MemHistStr @MEMHISTCNT dup (<0>) ; The memory history table

	public	TaskEntry
TaskEntry tagTASKENTRY <>	; Task entry structure

	public	AppName
AppName db	@APPNAME	; Module name of our .EXE


; Special module entries

SpecModStr struc

SpecModName db	8 dup (' ')     ; Module name, padded with blanks
SpecModPara dw	0		; # paras we should free (0=this entry is free)
				; -1 = disable
SpecModNext dw	-1		; Next entry in doubly-linked list (-1=last)
SpecModPrev dw	-1		; Prev ...

SpecModStr ends

@SPECMOD equ	64		; # special modules for which we have room

	public	SpecModIni
SpecModIni SpecModStr <>	; Initialization entry

	public	wTaskLink
wTaskLink dw	-1		; Link to next task (-1=none)

	public	SpecModCnt
SpecModCnt dw	@SPECMOD	; Static count of # special modules
	public	SpecMod
SpecMod SpecModStr @SPECMOD dup (<>) ; Save area for special modules


@MODHISTCNT equ 10		; # module names we keep track of

ModHistStr struc

ModHistName db	8 dup (' ')     ; The module name

ModHistStr ends

	public	ModHistStart,ModHistEnd,ModHistHead,ModHistTab

; The following data items from ModHistStart to ModHistTab inclusive
; must be consecutive to the module history buffer can be read by Win Apps

ModHistStart dw 0		; Static buffer index start
ModHistEnd dw	@MODHISTCNT	; ...		      end
ModHistHead dw	0		; Dynamic buffer index head (next entry)
ModHistTab ModHistStr @MODHISTCNT dup (<>) ; The module history table

_DATA	ends			; End _DATA segment

;..............................................................
_TEXT	segment use16 byte public 'CODE' ; Start _TEXT segment
	assume	cs:_TEXT

	extrn	StrCpy:near
	extrn	StrNCpy:near
	extrn	StrICmp:near
	extrn	UpperCase:near
	extrn	SKIP_WHITE:near
	extrn	SKIP_BLACK:near
	extrn	DD2DEC:near
	extrn	ReadIncompat:near

PATCH_INST_MAC macro TXT

%	NPPROC	TXT&_PATCH_INST -- Install Our &TXT& Patch
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install our &TXT& patch

|

	REGSAVE <eax,di,es>	; Save registers

	pushf			; Save flags (IF in particular)
	cli			; Nobody move

	inc	LCL_INST_&TXT	; Count in another installation

	cmp	LCL_INST_&TXT,1 ; Izit already installed?
	ja	short TXT&_PATCH_INST_EXIT ; Jump if so

; Patch ourselves into the &TXT procedure

	les	di,lp&TXT&Proc	; ES:DI ==> &TXT& procedure
	assume	es:nothing	; Tell the assembler about it

	mov	al,@OPCOD_JMPF	; Get opcode for far jump immediate
	xchg	al,es:[di+0]	; Swap with 1st byte
	mov	TXT&Proc[0],al	; Save to restore later

	mov	eax,lpLCL_&TXT&Proc ; Get Sel:Off of local &TXT& procedure
	xchg	eax,es:[di+1]	; Swap with 2nd-5th bytes
	mov	TXT&Proc[1].EDD,eax ; Save to restore later
% TXT&_PATCH_INST_EXIT:

; Because we might be running at IOPL < CPL, POPF might not restore
; the Interrupt Flag (IF).  Thus we need to use STI explicitly, as
; appropriate.

	POPF_MAC		; POPF with IF check

	REGREST <es,di,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% TXT&_PATCH_INST endp		; End TXT&_PATCH_INST procedure

	endm			; PATCH_INST_MAC

;;;;;;; PATCH_INST_MAC GA	; Define routine to patch into GA procedure
	PATCH_INST_MAC GDA	; ...			       GDA
	PATCH_INST_MAC GF	; ...			       GF
	PATCH_INST_MAC GDF	; ...			       GDF


PATCH_REST_MAC macro TXT

%	NPPROC	TXT&_PATCH_REST -- Restore Original &TXT& Code
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the original &TXT& code we had patched

|

	REGSAVE <eax,di,es>	; Save registers

	pushf			; Save flags (IF in particular)
	cli			; Nobody move

	cmp	LCL_INST_&TXT,0 ; Izit already restored?
	je	short TXT&_PATCH_REST_EXIT ; Jump if so

	dec	LCL_INST_&TXT	; Mark as original code restored

	cmp	LCL_INST_&TXT,0 ; Izit still installed?
	ja	short TXT&_PATCH_REST_EXIT ; Jump if so

; Restore the original &TXT& code

	les	di,lp&TXT&Proc	; ES:DI ==> &TXT& procedure
	assume	es:nothing	; Tell the assembler about it

	mov	al,TXT&Proc[0]	; Get the first byte
	xchg	al,es:[di+0]	; Swap

	cmp	al,@OPCOD_JMPF	; Izit our signature?
	je	short @F	; Jump if so

	DEBUG_MAC -1		; Call our debugger
@@:
	mov	eax,TXT&Proc[1].EDD ; Get the next four bytes
	xchg	eax,es:[di+1]	; Swap

	cmp	eax,lpLCL_&TXT&Proc ; Izit our Sel:Off?
	je	short @F	; Jump if so

	DEBUG_MAC -1		; Call our debugger
@@:
% TXT&_PATCH_REST_EXIT:

; Because we might be running at IOPL < CPL, POPF might not restore
; the Interrupt Flag (IF).  Thus we need to use STI explicitly, as
; appropriate.

	POPF_MAC		; POPF with IF check

	REGREST <es,di,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

% TXT&_PATCH_REST endp		; End TXT&_PATCH_REST procedure

	endm			; PATCH_REST_MAC


;;;;;;; PATCH_REST_MAC GA	; Define routine to restore GA code
	PATCH_REST_MAC GDA	; ...			    GDA
	PATCH_REST_MAC GF	; ...			    GF
	PATCH_REST_MAC GDF	; ...			    GDF


	NPPROC	FN_DRV_FREE -- Free Driver From Memory
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Free driver from memory

|

	pusha			; Save all GP registers

	btr	LCL_FLAG,$LCL_INSTNR ; Mark as no longer installed
	jnc	short @F	; Jump if not previously installed

	push	hIniTask	; Pass handle of initial task
	call	NotifyUnregister ; Tell 'em we're finished
@@:

RELLIN	macro	TXT
	local	L1

; This code reverses the steps taken in the GETLIN macro

	btr	LCL_FLAG,$LCL_INST&TXT ; Mark as no longer installed
	jnc	short L1	; Jump if not previously installed

; Restore the original &TXT& procedure contents

	call	TXT&_PATCH_REST ; Restore the original &TXT& code

	push	TXT&ProcSel	; Pass selector of &TXT& procedure
	call	UnlockSegment	; Unlock it

	push	lp&TXT&Proc.VSEG ; Pass the selector to free
	call	FreeSelector	; Free the data selector
L1:
	endm			; RELLIN


;;;;;;; RELLIN	GA		; Restore, unlock, and free
	RELLIN	GDA		; ...
	RELLIN	GF		; ...
	RELLIN	GDF		; ...

	popa			; Restore all GP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FN_DRV_FREE endp		; End FN_DRV_FREE procedure
	FPPROC	LibMain -- Main DLL Procedure
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Entry point from W.

Here's where library initialization code normally goes.  In the case
of an installable driver, you can use the DRV_LOAD message instead
(LibMain is called first, however).

On entry:

SS:SP	==>	LibMain_STR (after we PUSH BP)

On exit:

AX	=	TRUE or FALSE

|

LibMain_STR struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
lpszCmdLine dd	?		; 06:  lpszCmdLine (always NULL)
cbHeapSize dw	?		; 0A:  cbHeapSize
wDataSeg dw	?		; 0C:  wDataSeg
hInstance dw	?		; 0E:  hInstance

LibMain_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; SS:BP ==> LibMain_STR

	pusha			; Save all GP registers

	or	LCL_FLAG,@LCL_FREE ; Mark as free

; For reasons I haven't bothered to determine, GoAhead doesn't
; run in a Windows box of OS/2 -- check for that and quit silently

	DOSCALL @DOSVER 	; Return DOS version as
				; AL=major
				; AH=minor
				; BX=CX=0
	cmp	al,20		; Izit too big for MS?
	jae	near ptr LibMainErr ; Jump if so

; Because of reliance on internal data structures for the Global Heap,
; we don't run under KRNL286.

; Check W flags to see if this is KRNL286

	call	GetWinFlags	; Return with DX:AX = flags

; If this is W 3.0, the flags are handled differently

	push	ax		; Save for a moment

	call	GetVersion	; Return with AX = version #
	xchg	al,ah		; Swap to comparison order

	cmp	ax,0300h	; Izit W 3.0?
	pop	ax		; Restore
	jne	short @F	; Jump if not

	test	ax,WF_CPU386	; Izit on a 386 CPU?
	jnz	short LibMain1	; Jump if so
@@:
	test	ax,WF_WIN386	; Izit KRNL386?
	jz	near ptr LibMainErr ; Jump if not
LibMain1:

; Get the handle of the initial task

	call	GetCurrentTask	; Return with handle in AX
	mov	hIniTask,ax	; Save for later use
	mov	hOurOwnr,ax	; ...

; Find our owner entry in the Global Heap

	push	cs		; Pass the handle
	call	FindOwner	; Find the matching Global Heap entry
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:EBX ==> Global heap entry
	jc	short @F	; Jump if not found???

	mov	ax,es:[ebx].GA32Owner ; Get the owner entry
	mov	hOurOwnr,ax	; Save for later use
@@:

; Get selector increment value for > 64KB allocations

	DPMICALL @DPMI_NXTSEL	; Get next selector increment value
	jc	short @F	; Jump on error ???

	mov	SelIncr,ax	; Save for later use
@@:

; Walk the global heap counting tasks

	push	ds		; Pass segment of TaskEntry struc
	push	offset ds:TaskEntry ; ... offset ...
	call	TaskFirst	; Request fill in of TaskEntry struc

	and	ax,ax		; Did it work?
	jz	short LibMainTaskEnd ; Jump if not
@@:
	inc	dwTaskCnt	; Count in another task

	push	ds		; Pass segment of TaskEntry struc
	push	offset ds:TaskEntry ; ... offset ...
	call	TaskNext	; Request fill in of TaskEntry struc

	and	ax,ax		; Did it work?
	jnz	short @B	; Jump if so
LibMainTaskEnd:

; Read profile string to control debugging

	push	lpGenSect	; Pass ptr to section name
	push	lpDbgName	; ...	      line name
	push	FALSE		; ...	      default value
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileInt ; Return value in AX
	assume	es:nothing	; Tell the assembler about it

	cmp	ax,FALSE	; Izit to be skipped?
	je	short @F	; Jump if so

	or	LCL_FLAG,@LCL_DBG ; Mark as in a debuggin' mood
	DEBUG_MAC		; Call our debugger
@@:

; Read profile string to control GFAlloc

	push	lpGenSect	; Pass ptr to section name
	push	lpGFAName	; ...	      line name
	push	FALSE		; ...	      default value
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileInt ; Return value in AX
	assume	es:nothing	; Tell the assembler about it

	cmp	ax,FALSE	; Izit to be skipped?
	je	short @F	; Jump if so

	or	LCL_FLAG,@LCL_GFALLOC ; Mark as allocating DOS memory on GlobalFree
@@:

; Read in the special module profile

	call	ReadProfile	; Read it in
;;;;;;; jc	short ???	; Ignore error code

; Setup TOOLHELP notification for start and exit task

	bts	LCL_FLAG,$LCL_INSTNR ; Mark as installed
	jc	short @F	; Jump if already installed

	push	NULL		; Pass current task
	push	lpNotify	; ...  ptr to notification function
	push	NF_NORMAL	; Normal notifications
	call	NotifyRegister	; Request notification
@@:

; Read in profile section of Incompatible Drivers

	call	ReadIncompat	; Read it in
	jc	short LibMainDone ; Jump if there's a match

GETLIN	macro	TXT
	local	L1

	bts	LCL_FLAG,$LCL_INST&TXT ; Mark as installed
	jc	short L1	; Jump if already installed

; Lock the &TXT& segment into memory so it won't be reloaded

	mov	ax,lp&TXT&Proc.VSEG ; Get selector of &TXT& procedure
	mov	TXT&ProcSel,ax	; Save for later use

	push	ax		; Pass selector of &TXT& procedure
;;;;;;; push	TXT&ProcSEL	; Pass selector of &TXT& procedure
	call	LockSegment	; Lock it

; Get an alias for the above code selector

	push	TXT&ProcSel	; Pass selector of &TXT& procedure
	call	AllocCStoDSAlias ; Returns AX = alias

	mov	lp&TXT&Proc.VSEG,ax ; Save for later use

	call	TXT&_PATCH_INST ; Install our &TXT& patches
L1:
	endm			; GETLIN


;;;;;;; GETLIN	GA		; Lock and get linear address for GA
	GETLIN	GDA		; ...				  GDA

	test	LCL_FLAG,@LCL_GFALLOC ; Allocate memory in GlobalFree?
	jz	short @F	; Jump if not (no need to hook it)

	GETLIN	GF		; ...				  GF
@@:
	GETLIN	GDF		; ...				  GDF

; Allocate all of low DOS memory

	call	HookedAllocMem	; Allocate all of DOS memory

	or	LCL_FLAG,@LCL_INSTALL ; Mark as installed
	and	LCL_FLAG,not @LCL_FREE ; Mark as not free
LibMainDone:
	clc			; Mark as successful

	jmp	short LibMainExit ; Join common exit code

LibMainErr:
	stc			; Mark as not successful
LibMainExit:
	popa			; Restore all GP registers
	mov	ax,FALSE	; Assume not successful
	jc	short @F	; Jump if not successful

	mov	ax,TRUE 	; Return to caller
@@:
	pop	bp		; Restore

	ret	4+2+2+2 	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LibMain endp			; End LibMain procedure
	NPPROC	ReadProfile -- Read In The Profile
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in the profile

On Exit:

CF	=	0 if successful
	=	1 if not

|

	pusha			; Save all GP registers
	push	es		; Save register

	mov	ax,ds		; Get DGROUP selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	wTaskLink,-1	; Mark as invalid

; Read in the entire [GoAhead - Programs] section
; We'll read it into the tail of the SpecMod struct and move the items
; down from the front to back

	lea	si,SpecMod[@SPECMOD * (type SpecModStr)] ; Point to ending+1
	mov	cx,1+@SPECMOD * (1+length SpecModName) ; Get size of names
				; we can handle (plus terminating zero)
	sub	si,cx		; Less length to get start

	push	es		; Keep W's grubby hands away from

	push	lpProgSect	; Pass ptr to section name
	PUSHD	0		; ...	      line name (entire section contents)
	push	lpDefValue	; ...	      default string (empty)
	push	ds		; ...	      segment of dest buffer
	push	si		; ...	      offset  ...
	push	cx		; ...  size of ...
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileString ; Return length in AX,
				; not counting the last zero
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	and	ax,ax		; Did it succeed?
	stc			; Assume it didn't
	jz	short ReadProfileNone ; Jump if not (note CF=1)

; Parse the entries moving them down one by one

	xor	bx,bx		; Initialize entry count
	mov	cx,ax		; Copy # bytes in buffer

; Copy the next entry at DS:SI to SpecMod[bx*(type SpecModStr)].SpecModName

ReadProfileNextEntry:
	mov	dx,length SpecModName ; Initialize the maximum name length
	imul	di,bx,type SpecModStr ; Get index into SpecMod
	lea	di,SpecMod[di].SpecModName ; Get offset in DGROUP
ReadProfileNextChar:
	lods	SpecMod[si].LO	; Get the next char
	dec	cx		; Count it out

	cmp	al,0		; Izit the terminator?
	je	short ReadProfileLastChar ; Jump if so

	call	UpperCase	; Convert AL to uppercase
	stos	SpecMod[di].SpecModName ; Save in buffer

	dec	dx		; Count out one more char
	jnz	short ReadProfileNextChar ; Jump if more room

; Skip to the terminating zero

@@:
	lods	SpecMod[si].LO	; Get the next char
	dec	cx		; Count it out

	cmp	al,0		; Izit the terminator?
	jne	short @B	; Jump if not
ReadProfileLastChar:

; Pad out the name with trailing blanks

	push	cx		; Save for a moment

	mov	cx,dx		; Copy # remaining bytes
	mov	al,' '          ; Fill character
    rep stos	SpecMod[di].SpecModName ; Save in buffer

	pop	cx		; Restore

; Fill in values for the other fields

	imul	di,bx,type SpecModStr ; Get index into SpecMod

	mov	SpecMod[di].SpecModPara,-1 ; Mark as in use

	mov	ax,SpecModIni.SpecModNext ; Copy default next setting
	mov	SpecMod[di].SpecModNext,ax ; Save in current entry

	mov	ax,SpecModIni.SpecModPrev ; Copy default prev setting
	mov	SpecMod[di].SpecModPrev,ax ; Save in current entry

	inc	bx		; Count in another entry

	and	cx,cx		; Any bytes remaining
	jnz	short ReadProfileNextEntry ; Jump if so

	clc			; Mark as successful

	jmp	short @F	; Join common code

ReadProfileNone:
	mov	ax,ds		; Get DGROUP selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	xor	bx,bx		; Initialize entry count
@@:

; Clear the remaining contents

	lea	si,SpecModIni	; DS:SI ==> initialization entry
	mov	cx,SpecModCnt	; Get # entries
	sub	cx,bx		; Less # entries we've filled in
	imul	di,bx,type SpecModStr ; Get index into SpecMod
	lea	di,SpecMod[di]	; ES:DI ==> next entry in SpecMod struc
@@:
	REGSAVE <cx,si> 	; Save for a moment

	mov	cx,(type SpecModStr)/2 ; Get # words in struc
    rep movs	SpecMod[di].ELO,SpecModIni[si].ELO ; Initialize this entry

	REGREST <si,cx> 	; Restore

	loop	@B		; Jump if more entries

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ReadProfile endp		; End ReadProfile procedure
;;;	    NPPROC  ReadProfLine -- Read In And Process One Profile Line
;;;	    assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Read in and process one profile line
;;;
;;; On entry:
;;;
;;; BX	    =	    file handle
;;; SI	    =	    offset into SpecMod of next entry
;;;
;;; On exit:
;;;
;;; CF	    =	    0 if successful
;;;	    =	    1 if not
;;;
;;; |
;;;
;;;	    REGSAVE <ax,cx,dx,di>  ; Save registers
;;;
;;; ; Skip over leading CRs and LFs and white space
;;;
;;;	    call    SkipFileEOL     ; Skip over EOLs, white space, and comments in the file
;;;	    jb	    near ptr ReadProfLineExit ; Jump if no more chars (note CF=1)
;;;
;;;	    cmp     szStrBuf[0],'[' ; Izit a section name?
;;;	    stc 		    ; Assume so
;;;	    je	    near ptr ReadProfLineExit ; Jump if no more chars (note CF=1)
;;;
;;; ; Read in the module name (no more than 8 chars or until we get a blank)
;;;
;;;	    lea     di,SpecMod[si].SpecModName ; ES:DI ==> destin
;;;	    xor     cx,cx	    ; Initialize length counter
;;; ReadProfLineNext1:
;;;	    push    cx		    ; Save for a moment
;;;
;;;	    mov     cx,1	    ; Read in one character
;;;	    DOSCALL @READF2,szStrBuf ; Read it in
;;;	    jc	    short @F	    ; Jump if something went wrong
;;;
;;;	    cmp     ax,cx	    ; Did it succeed?
;;; @@:
;;;	    pop     cx		    ; Restore length counter
;;;	    jb	    short ReadProfLineExit ; Jump if no more chars (note CF=1)
;;;
;;;	    mov     al,szStrBuf[0]  ; Get the character
;;;
;;;	    cmp     al,' '          ; Izit white space or below?
;;;	    jbe     short ReadProfLineDone1 ; Jump if so
;;;
;;;	    call    UpperCase	    ; Convert AL to uppercase
;;;	    stos    SpecMod.SpecModName[di] ; Save in table
;;;
;;;	    inc     cx		    ; Count in another char
;;;
;;;	    cmp     cx,length SpecModName ; Izit at the limit?
;;;	    jb	    short ReadProfLineNext1 ; Jump if not
;;;
;;; ; There are more chars in the module name than we have room for -- skip over them
;;;
;;;	    call    SkipFileBlack   ; Skip over black space in the file
;;;	    jb	    short ReadProfLineExit ; Jump if no more chars (note CF=1)
;;; ReadProfLineDone1:
;;;	    mov     SpecMod[si].SpecModPara,-1 ; Mark as in use
;;; ;;;
;;; ;;; ; Skip over intervening white space
;;; ;;;
;;; ;;; 	call	SkipFileWhite	; Skip over white space in the file
;;; ;;; 	jb	short ReadProfLineExit ; Jump if no more chars (note CF=1)
;;; ;;;
;;; ;;; ; Read in the decimal digits
;;; ;;;
;;; ;;; 	xor	dx,dx		; Initialize the accumulator
;;; ;;; 	xor	di,di		; ...	     symbol count
;;; ;;; 	xor	cx,cx		; ...	     sign
;;; ;;; ReadProfLineNext2:
;;; ;;; 	push	dx		; Save accumulator
;;; ;;;
;;; ;;; 	mov	cx,1		; Read in one character
;;; ;;; 	DOSCALL @READF2,szStrBuf ; Read it in
;;; ;;; 	jc	short @F	; Jump if something went wrong
;;; ;;;
;;; ;;; 	cmp	ax,cx		; Did it succeed?
;;; ;;; @@:
;;; ;;; 	pop	dx		; Restore
;;; ;;; 	jb	short ReadProfLineDone2 ; Jump if not
;;; ;;;
;;; ;;; 	mov	ah,0		; Zero to use as word
;;; ;;; 	mov	al,szStrBuf[0]	; Get the character
;;; ;;;
;;; ;;; 	cmp	al,'-'          ; Izit a minus sign?
;;; ;;; 	jne	short @F	; Jump if not
;;; ;;;
;;; ;;; 	and	di,di		; Izit the first digit?
;;; ;;; 	jnz	short ReadProfLineDone2 ; Jump if not
;;; ;;;
;;; ;;; 	mov	cx,-1		; Save as sign
;;; ;;; 	mov	al,'0'          ; Call it a zero
;;; ;;; @@:
;;; ;;; 	sub	al,'0'          ; Izit a decimal digit?
;;; ;;; 	jb	short ReadProfLineDone2 ; Jump if not
;;; ;;;
;;; ;;; 	cmp	al,9		; Izit a decimal digit?
;;; ;;; 	ja	short ReadProfLineDone2 ; Jump if not
;;; ;;;
;;; ;;; 	imul	dx,10		; Shift over the accumulator
;;; ;;; 				; Ignore error return
;;; ;;; 	add	dx,ax		; Add in the new digit
;;; ;;; 	inc	di		; Count in another symbol
;;; ;;;
;;; ;;; 	jmp	ReadProfLineNext2 ; Go around again
;;; ;;;
;;; ;;;
;;; ;;; ReadProfLineDone2:
;;; ;;; 	imul	dx,cx		; Times the sign
;;; ;;;
;;; ;;; 	cmp	dx,-1		; Izit a special value?
;;; ;;; 	je	short @F	; Jump if so
;;; ;;;
;;; ;;; 	shl	dx,10-4 	; Convert from 1KB to paras
;;; ;;; @@:
;;; ;;; 	mov	SpecMod[si].SpecModPara,dx ; Save in special module table
;;; ;;;
;;; ;;; ; Back up the file pointer by one
;;; ;;;
;;; ;;; 	mov	cx,-1		; CX:DX = move amount
;;; ;;; 	mov	dx,-1		; ...
;;; ;;; 	mov	al,1		; Move relative to current position
;;; ;;; 	DOSCALL @MOVFP2 	; Move it
;;; ;;; 				; Ignore return code
;;;	    clc 		    ; Mark as successful
;;; ReadProfLineExit:
;;;	    REGREST <di,dx,cx,ax>   ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; ReadProfLine endp		    ; End ReadProfLine procedure
;;;	    NPPROC  SkipFileEOL -- Skip Over EOLs And White Space In The File
;;;	    assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Skip over EOLs, white space, and comments in the file
;;;
;;; On entry:
;;;
;;; BX	    =	    file handle
;;;
;;; On exit:
;;;
;;; CF	    =	    0 if sucessful
;;;	    =	    1 if no more file characters
;;; szStrBuf[0] =   next character to read in
;;;
;;; |
;;;
;;;	    REGSAVE <ax,cx,dx>	    ; Save registers
;;; SkipFileEOLNext:
;;;	    mov     cx,1	    ; Read in one character
;;;	    DOSCALL @READF2,szStrBuf ; Read it in
;;;	    jc	    short @F	    ; Jump if something went wrong
;;;
;;;	    cmp     ax,cx	    ; Did it succeed?
;;; @@:
;;;	    jb	    short SkipFileEOLExit ; Jump if not (note CF=1)
;;;
;;;	    mov     al,szStrBuf[0]  ; Get the character
;;;
;;;	    cmp     al,CR	    ; Izit a line terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,LF	    ; Izit a line terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,EOF	    ; Izit a file terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,' '          ; Izit white space?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,TAB	    ; Izit white space?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,';'          ; Izit a comment marker?
;;;	    jne     short SkipFileEOLDone ; Jump if not
;;; SkipFileEOL1:
;;;
;;; ; Skip over the comment to the next EOL marker
;;;
;;;	    mov     cx,1	    ; Read in one character
;;;	    DOSCALL @READF2,szStrBuf ; Read it in
;;;	    jc	    short @F	    ; Jump if something went wrong
;;;
;;;	    cmp     ax,cx	    ; Did it succeed?
;;; @@:
;;;	    jb	    short SkipFileEOLExit ; Jump if not (note CF=1)
;;;
;;;	    mov     al,szStrBuf[0]  ; Get the character
;;;
;;;	    cmp     al,CR	    ; Izit a line terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,LF	    ; Izit a line terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    cmp     al,EOF	    ; Izit a file terminator?
;;;	    je	    short SkipFileEOLNext ; Jump if so
;;;
;;;	    jmp     SkipFileEOL1    ; Go around again
;;;
;;;
;;; SkipFileEOLDone:
;;;
;;; ; Back up the file pointer by one
;;;
;;;	    mov     cx,-1	    ; CX:DX = move amount
;;;	    mov     dx,-1	    ; ...
;;;	    mov     al,1	    ; Move relative to current position
;;;	    DOSCALL @MOVFP2	    ; Move it
;;;				    ; Ignore return code
;;;	    clc 		    ; Mark as successful
;;; SkipFileEOLExit:
;;;	    REGREST <dx,cx,ax>	    ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SkipFileEOL endp		    ; End SkipFileEOL procedure
;;;	    NPPROC  SkipFileWhite -- Skip Over White Space In The File
;;;	    assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Skip over white space in the file
;;;
;;; On entry:
;;;
;;; BX	    =	    file handle
;;;
;;; On exit:
;;;
;;; CF	    =	    0 if sucessful
;;;	    =	    1 if no more file characters
;;;
;;; |
;;;
;;;	    REGSAVE <ax,cx,dx>	    ; Save registers
;;; SkipFileWhiteNext:
;;;	    mov     cx,1	    ; Read in one character
;;;	    DOSCALL @READF2,szStrBuf ; Read it in
;;;	    jc	    short @F	    ; Jump if something went wrong
;;;
;;;	    cmp     ax,cx	    ; Did it succeed?
;;; @@:
;;;	    jb	    short SkipFileWhiteExit ; Jump if not (note CF=1)
;;;
;;;	    mov     al,szStrBuf[0]  ; Get the character
;;;
;;;	    cmp     al,' '          ; Izit white space?
;;;	    je	    short SkipFileWhiteNext ; Jump if so
;;;
;;;	    cmp     al,TAB	    ; Izit white space?
;;;	    je	    short SkipFileWhiteNext ; Jump if so
;;;
;;; ; Back up the file pointer by one
;;;
;;;	    mov     cx,-1	    ; CX:DX = move amount
;;;	    mov     dx,-1	    ; ...
;;;	    mov     al,1	    ; Move relative to current position
;;;	    DOSCALL @MOVFP2	    ; Move it
;;;				    ; Ignore return code
;;;	    clc 		    ; Mark as successful
;;; SkipFileWhiteExit:
;;;	    REGREST <dx,cx,ax>	    ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SkipFileWhite endp		    ; End SkipFileWhite procedure
;;;	    NPPROC  SkipFileBlack -- Skip Over Black Space In The File
;;;	    assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Skip over black space in the file
;;;
;;; On entry:
;;;
;;; BX	    =	    file handle
;;;
;;; On exit:
;;;
;;; CF	    =	    0 if sucessful
;;;	    =	    1 if no more file characters
;;;
;;; |
;;;
;;;	    REGSAVE <ax,cx,dx>	    ; Save registers
;;; SkipFileBlackNext:
;;;	    mov     cx,1	    ; Read in one character
;;;	    DOSCALL @READF2,szStrBuf ; Read it in
;;;	    jc	    short @F	    ; Jump if something went wrong
;;;
;;;	    cmp     ax,cx	    ; Did it succeed?
;;; @@:
;;;	    jb	    short SkipFileBlackExit ; Jump if not (note CF=1)
;;;
;;;	    mov     al,szStrBuf[0]  ; Get the character
;;;
;;;	    cmp     al,CR	    ; Izit a line terminator?
;;;	    je	    short SkipFileBlackDone ; Jump if so
;;;
;;;	    cmp     al,LF	    ; Izit a line terminator?
;;;	    je	    short SkipFileBlackDone ; Jump if so
;;;
;;;	    cmp     al,EOF	    ; Izit a file terminator?
;;;	    je	    short SkipFileBlackDone ; Jump if so
;;;
;;;	    cmp     al,' '          ; Izit white space?
;;;	    je	    short SkipFileBlackDone ; Jump if so
;;;
;;;	    cmp     al,TAB	    ; Izit white space?
;;;	    jne     short SkipFileBlackNext ; Jump if not
;;; SkipFileBlackDone:
;;;
;;; ; Back up the file pointer by one
;;;
;;;	    mov     cx,-1	    ; CX:DX = move amount
;;;	    mov     dx,-1	    ; ...
;;;	    mov     al,1	    ; Move relative to current position
;;;	    DOSCALL @MOVFP2	    ; Move it
;;;				    ; Ignore return code
;;;	    clc 		    ; Mark as successful
;;; SkipFileBlackExit:
;;;	    REGREST <dx,cx,ax>	    ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SkipFileBlack endp		    ; End SkipFileBlack procedure
;;;	    NPPROC  GHCountFree -- Count Free DOS Memory In GH
;;;	    assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Count free DOS memory in the GH
;;;
;;; On exit:
;;;
;;; EAX     =	    # free bytes
;;;
;;; |
;;;
;;;	    REGSAVE <ebx,cx,es>     ; Save registers
;;;
;;;	    mov     es,wGlobalHeap  ; ES:0 ==> Global Info Struc
;;;	    assume  es:nothing	    ; Tell the assembler about it
;;;
;;;	    xor     eax,eax	    ; Initialize accumulator
;;;	    mov     cx,es:[0].GH32_GHCNT ; Get the # Global Arena entries
;;;	    mov     ebx,es:[0].GH32_OFF1ST ; Get the offset to the first Global Arena
;;; GHCountFreeNext:
;;;	    cmp     es:[ebx].GA32Handle,0 ; Izit free?
;;;	    jne     short @F	    ; Jump if not
;;;
;;;	    cmp     es:[ebx].GA32Base,@CON1MB ; Izit within the fist megabyte?
;;;	    jae     short @F	    ; Jump if not
;;;
;;;	    add     eax,es:[ebx].GA32Size ; Add in its size in bytes
;;; @@:
;;;	    mov     ebx,es:[ebx].GA32Next ; Get offset of next Global Arena
;;;
;;;	    loop    GHCountFreeNext ; Jump if more entries
;;;
;;;	    REGREST <es,cx,ebx>     ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; GHCountFree endp		    ; End GHCountFree procedure
	FPPROC	LCL_Notify -- Local Notification Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

AX	=	seg DGROUP???

On exit:

|

LNFY_STR struc

	dw	?		; Caller's BP
	dd	?		; ...	   CS:IP
LNFY_dwData dd	?		; dwData
LNFY_wID dw	?		; wID

LNFY_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ds>		; Save registers

	mov	ax,seg DGROUP	; Get our data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	cmp	[bp].LNFY_wID,NFY_STARTTASK ; Izit starting a task?
	jne	short @F	; Jump if not

	inc	dwTaskCnt	; Count in another
	call	TaskChanged	; Tell any app interested that task count changed

	push	1		; Mark as incoming task
	call	CheckTask	; See if we should free memory for this task
@@:
	cmp	[bp].LNFY_wID,NFY_EXITTASK ; Izit exiting a task?
	jne	short @F	; Jump if not

	dec	dwTaskCnt	; Count out another
	call	TaskChanged	; Tell any app interested that task count changed

	push	0		; Mark as outgoing task
	call	CheckTask	; See if we should free memory for this task
@@:
	mov	ax,FALSE	; Indicate we didn't handle this message

	REGREST <ds>		; Restore

	pop	bp		; Restore

	ret	6		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_Notify endp 		; End LCL_Notify procedure
	NPPROC	TaskChanged -- Task Changed Procedure
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Task count changed -- tell others about it.

|

	REGSAVE <cx,si> 	; Save registers

	xor	si,si		; Initialize index into hRegs
	mov	cx,@NHREGS	; Get # entries in table
TaskChangedNext:
	cmp	hRegs[si].REG_hWnd,0 ; Izit free?
	je	short TaskChangedLoop ; Jump if so

	cmp	hRegs[si].REG_uTSKMsg,0 ; Izit invalid?
	je	short TaskChangedLoop ; Jump if so

	REGSAVE <cx>		; Keep away from W

	push	hRegs[si].REG_hWnd ; Pass hWnd
	call	IsWindow	; Return 0 if invalid window handle

	cmp	ax,0		; Izit an invalid window handle?
	je	short @F	; Jump if so

	push	hRegs[si].REG_hWnd ; Pass hWnd
	push	WM_USER 	; ...  command message
	push	hRegs[si].REG_uTSKMsg ; wParam = the message
	push	dwTaskCnt	; lParam = # active tasks
	call	PostMessage	; Tell 'em the memory changed

	mov	ax,hRegs[si].REG_hWnd ; Get hWnd
@@:
	REGREST <cx>		; Restore

	mov	hRegs[si].REG_hWnd,ax ; Save hWnd
TaskChangedLoop:
	add	si,type REG_STR ; Skip to next entry

	loop	TaskChangedNext ; Jump if more entries

	REGREST <si,cx> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TaskChanged endp		; End TaskChanged procedure
	NPPROC	CheckTask -- Check Current Task For Memory Requirements
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the current task for any special memory requirements

|

CheckTaskStr struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CheckTaskFlag dw ?		; Flag:  1 = incoming, 0 = outgoing

CheckTaskStr ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; SS:BP ==> LibMain_STR

	pusha			; Save registers
	push	es		; ...

; Get the module name of the current task

	call	GetCurrentTask	; Return with handle in AX

	push	ds		; Pass segment of TaskEntry struc
	push	offset ds:TaskEntry ; ... offset ...
	push	ax		; ...  task handle
	call	TaskFindHandle	; Request fill in of TaskEntry struc

	mov	ax,ds		; Get DGROUP selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	cld			; String ops forwardly

; If this is an incoming task, save the module name in our ring buffer

	cmp	[bp].CheckTaskFlag,1 ; Izit an incoming task?
	jne	near ptr CheckTask3 ; Jump if not

; Convert the string to uppercase

	mov	cx,length ModHistName ; Get # bytes in module name
	lea	si,TaskEntry.TE_szModule[0] ; DS:SI ==> current module name
@@:
	lods	TaskEntry.TE_szModule[si] ; Get the next char

	cmp	al,0		; Izit a string terminator?
	je	short @F	; Jump if so

	call	UpperCase	; Convert AL to uppercase
	mov	DGROUP:[si-1],al ; Save back

	loop	@B		; Jump if more chars
@@:
	mov	al,' '          ; Fill in trailing blanks (if any)
	lea	di,DGROUP:[si-1] ; Copy to destin register
    rep stos	TaskEntry.TE_szModule[di] ; It's history

; See if this string is our matching .EXE -- if so, skip it

	mov	cx,length ModHistName ; Get # bytes in module name
	lea	si,TaskEntry.TE_szModule[0] ; DS:SI ==> current module name
	lea	di,AppName	; ES:DI ==> our .EXE module name
   repe cmps	TaskEntry.TE_szModule[si],AppName[di] ; Izit the same?
	je	near ptr CheckTaskExit ; Jump if so (ignore it)

; See if this string matches a name already in our history table
; If so, delete the old entry

	mov	cx,ModHistEnd	; Get # module history entries
	lea	si,TaskEntry.TE_szModule[0] ; DS:SI ==> current module name
	lea	di,ModHistTab[0].ModHistName ; ES:DI ==> 1st entry in ModHistTab
	xor	bx,bx		; Initialize entry counter
@@:
	REGSAVE <cx,si,di>	; Save for a moment
	mov	cx,length ModHistName ; Get # bytes in module name
   repe cmps	TaskEntry.TE_szModule[si],ModHistTab[di].ModHistName ; Izit the same?
	REGREST <di,si,cx>	; Restore
	je	short @F	; Jump if it matches

	add	di,type ModHistStr ; Skip to next entry
	inc	bx		; Skip to next entry

	loop	@B		; Jump if more entries to compare

	jmp	short CheckTask2 ; Join common code

@@:

	push	eax		; Save for a moment

	movzx	eax,ModHistHead ; Get index in ModHistTab of next entry
	lea	cx,ModHistTab[eax*(type ModHistStr)].ModHistName ; DS:CX ==> next entry in ModHistTab

	pop	eax		; Restore

; Delete the entry at ES:DI (index BX) unless it is at ModHistHead

; If the head entry is below the entry-to-be-deleted, move the
; entries from ModHistHead to BX upwards

; If the head entry is above the entry-to-be-deleted, move the
; entries from BX to ModHistHead downwards

	cmp	ModHistHead,bx	; Izit it about to be deleted anyway?
	je	short CheckTask2 ; Jump if so
	jb	short CheckTask1 ; Jump if moving upwards

; Move the entries from BX < ModHistHead downwards
; ES:DI ==>	entry-to-be-deleted (index in BX)
; DS:CX ==>	ModHistHead entry

	lea	si,es:[di+(type ModHistStr)] ; DS:SI ==> one entry above
	sub	cx,si		; Less source to get length
    rep movs	ModHistTab[di].ModHistName,ModHistTab[si].ModHistName ; Move downwards

	dec	ModHistHead	; Back off by one (note it can't go below 0)

	jmp	short CheckTask2 ; Join common code

CheckTask1:

; Move the entries from ModHistHead < BX upwards
; ES:DI ==>	entry-to-be-deleted (index in BX)
; DS:CX ==>	ModHistHead entry

	mov	si,di		; Copy as source
	add	di,type ModHistStr ; Skip to destin
	sub	cx,si		; Subtract to get negative of length
	neg	cx		; Negate to get positive length

	dec	si		; Back off for backwards move
	dec	di		; ...
	std			; String ops backwards
    rep movs	ModHistTab[di].ModHistName,ModHistTab[si].ModHistName ; Move upwards
	cld			; Restore direction flag
CheckTask2:
	push	ebx		; Save for a moment

	movzx	ebx,ModHistHead ; Get index in ModHistTab of next entry
	lea	di,ModHistTab[ebx*(type ModHistStr)].ModHistName ; ES:DI ==> next entry in ModHistTab
	lea	si,TaskEntry.TE_szModule[0] ; DS:SI ==> current module name
	mov	cx,length ModHistName ; Get # bytes in module name
    rep movs	ModHistTab.ModHistName[di],TaskEntry.TE_szModule[si] ; Copy to history table

	inc	bx		; Skip to next entry

	cmp	bx,ModHistEnd	; Izit at the end?
	jne	short @F	; Jump if not

	mov	bx,ModHistStart ; Start over again
@@:
	mov	ModHistHead,bx	; Save for next time

	pop	ebx		; Restore
CheckTask3:

; See if it matches one of our special names

	xor	bx,bx		; Initialize index into local table
	mov	cx,SpecModCnt	; Get # special module entries
	lea	di,TaskEntry.TE_szModule[0] ; ES:DI ==> current module name
CheckTaskNext:
	cmp	SpecMod[bx].SpecModPara,0 ; Izit free?
	je	short CheckTaskLoop ; Jump if so

	REGSAVE <cx,di> 	; Save for a moment

	mov	cx,length SpecModName ; Get # bytes in module name
	lea	si,SpecMod[bx].SpecModName[0] ; DS:SI ==> next special module name

   repe cmps	TaskEntry.TE_szModule[di],SpecMod.SpecModName[si] ; Compare 'em
	je	short @F	; Jump if it's a match (note ZF=1)

; Handle short names

	mov	al,ds:[si-1]	; Get mismatch in source
	mov	ah,es:[di-1]	; ...		  destin

	cmp	ax,' '          ; Izit ' ' in source, 0 in destin?
@@:
	REGREST <di,cx> 	; Restore
	je	short CheckTaskFound ; Jump if it's a match
CheckTaskLoop:
	add	bx,type SpecModStr ; Skip to next entry

	loop	CheckTaskNext	; Jump if more entries

	jmp	CheckTaskExit	; Join common exit code


CheckTaskFound:
	cmp	[bp].CheckTaskFlag,1 ; Izit an incoming task?
	je	short CheckTaskIncoming ; Jump if so

; It's an outgoing task
; If it's linked in, delink it

	mov	di,-1		; Get de-linked marker
	xchg	di,SpecMod[bx].SpecModNext ; De-link and get ptr to next entry
	mov	si,-1		; Get de-linked marker
	xchg	si,SpecMod[bx].SpecModPrev ; De-link and get ptr to prev entry

	cmp	di,-1		; Duzit point to an entry?
	je	short @F	; Jump if not

	mov	SpecMod[di].SpecModPrev,si ; De-link it
@@:
	cmp	si,-1		; Duz an entry point to it?
	je	short @F	; Jump if not

	mov	SpecMod[si].SpecModNext,di ; De-link it
@@:

; If this entry is the first one in the linked list, de-link it

	cmp	bx,wTaskLink	; Izit the first one?
	jne	short @F	; Jump if not

	mov	wTaskLink,di	; De-link it
@@:
	jmp	short CheckTaskDone ; Join common exit code


CheckTaskIncoming:

; It's an incoming task
; If it's not already linked in, do so

	cmp	SpecMod[bx].SpecModNext,-1 ; Duzit point to an entry?
	jne	short CheckTaskExit ; Jump if so

	cmp	SpecMod[bx].SpecModPrev,-1 ; Duz an entry point to it?
	jne	short CheckTaskExit ; Jump if so

; By construction, wTaskLink (if valid) always points to an entry
; whose SpecModPrev entry is invalid (-1).

	mov	si,bx		; Copy current entry
	xchg	si,wTaskLink	; Swap with current task link
	mov	SpecMod[bx].SpecModNext,si ; Link in as next entry

	cmp	si,-1		; Izit invalid?
	je	short @F	; Jump if so

	mov	ax,bx		; Copy current entry
	xchg	ax,SpecMod[si].SpecModPrev ; Link in as prev entry

	cmp	ax,-1		; Izit a terminator?
	je	short @F	; Jump if so

	DEBUG_MAC -1		; Call our debugger
@@:
CheckTaskDone:
	call	CheckGoreDisable ; Check on gore/command disabled state
CheckTaskExit:
	pop	es		; Restore
	popa			; ...

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckTask endp			; End CheckTask procedure
	NPPROC	CalcGore -- Calculate The Gore Size
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the gore size

|

	REGSAVE <bx,di> 	; Save registers

; Re-calculate the gore size

	xor	ax,ax		; Initialize with maximum identity element

	mov	di,wTaskLink	; Get first link
CalcGoreNext:
	cmp	di,-1		; Izit invalid?
	je	short CalcGoreExit ; Jump if so

	mov	bx,SpecMod[di].SpecModPara ; Get # paras

	cmp	bx,ax		; Izit larger?
	jbe	short @F	; Jump if not

	mov	ax,bx		; Save as larger
@@:
	mov	di,SpecMod[di].SpecModNext ; Get link to next entry

	jmp	CalcGoreNext	; Go around again


CalcGoreExit:
	REGREST <di,bx> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CalcGore endp			; End CalcGore procedure
	NPPROC	CheckGoreDisable -- Check on Gore/Command Disabled State
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on gore/command line disabled state

|

	REGSAVE <ax>		; Save register

	call	CalcGore	; Calculate the gore size into AX

	cmp	ax,wGore	; Izit different?
	je	short CheckGoreDisableExit ; Jump if not

	mov	wGore,ax	; Save for next time

	cmp	ax,-1		; Izit new state disabled?
	je	short CheckGoreDisableGore ; Jump if so

	btr	LCL_FLAG,$LCL_GOREDIS ; Mark as not gore disabled
	jnc	short @F	; Jump if already not gore disabled

	test	LCL_FLAG,@LCL_CMDDIS or @LCL_DUPDIS; Izit otherwise disabled?
	jnz	short @F	; Jump if so

	call	ChangeToEnable	; Change state to enabled
@@:
	jmp	short CheckGoreDisableExit ; Join common exit code

CheckGoreDisableGore:
	bts	LCL_FLAG,$LCL_GOREDIS ; Mark as gore disabled
	jc	short @F	; Jump if already gore disabled

	test	LCL_FLAG,@LCL_CMDDIS or @LCL_DUPDIS; Izit otherwise disabled?
	jnz	short @F	; Jump if so

	call	ChangeToDisable ; Change state to disabled
@@:
CheckGoreDisableExit:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckGoreDisable endp		; End CheckGoreDisable procedure
	NPPROC	ChangeToDisable -- Change State To Disabled
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change the state to disabled

|

; Restore the original code for GA, GDA, GF, and GDF

;;;;;;; call	GA_PATCH_REST	; Restore the original GA  code
	call	GDA_PATCH_REST	; ...		       GDA ...

	test	LCL_FLAG,@LCL_GFALLOC ; Allocate memory in GlobalFree?
	jz	short @F	; Jump if not (no need to unhook it)

	call	GF_PATCH_REST	; ...		       GF  ...
@@:
	call	GDF_PATCH_REST	; ...		       GDF ...

	call	FreeAllMem	; Free all memory
	call	MemChanged	; Tell any app interested that memory changed

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ChangeToDisable endp		; End ChangeToDisable procedure
	NPPROC	ChangeToEnable -- Change State To Enabled
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change the state to enabled

|

	mov	wGore,0 	; Mark as inactive

; Allocate all of available DOS memory

	call	AllocMem	; Allocate all of DOS memory
				; and call MemChanged if we got any
; Install our patch to GA, GDA, GF, and GDF

;;;;;;; call	GA_PATCH_INST	; Install our GA  patch
	call	GDA_PATCH_INST	; ...	      GDA ...

	test	LCL_FLAG,@LCL_GFALLOC ; Allocate memory in GlobalFree?
	jz	short @F	; Jump if not (no need to hook it)

	call	GF_PATCH_INST	; ...	      GF  ...
@@:
	call	GDF_PATCH_INST	; ...	      GDF ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ChangeToEnable endp		; End ChangeToEnable procedure
	NPPROC	GoreMem -- Ensure Gore Memory Available
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure some gore memory is available

|

	pusha			; Save registers

	mov	di,wGore	; Get # paras to remain free
GoreMemNext:
	call	FindLargest	; Find the largest size block in BX

	and	bx,bx		; Izit empty?
	jz	short GoreMemExit ; Jump if so

	cmp	di,bx		; Izit it too big?
	jae	short @F	; Jump if not

	mov	bx,di		; Use gore size
@@:
	sub	di,bx		; Subtract from total needed

	call	FindMem 	; Find room for BX paras
				; Return with DX = -1 if none
				; DOSMem[si] = block, if successful
; See if we found a hole

	cmp	dx,-1		; Did we find a hole?
	je	short GoreMemExit ; Jump if not

	call	FreeMem 	; Free the memory block at DOSMem[si] for BX paras

	and	di,di		; Is there any remainder?
	jnz	short GoreMemNext ; Jump if so
GoreMemExit:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GoreMem endp			; End GoreMem procedure
	NPPROC	HookedAllocMem -- Unhook, Allocate All DOS Memory, Hook
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Unhook GDA patches, allocate all DOS memory, hook back in

|

; Restore the original code for GDA/GDF

	call	GDA_PATCH_REST	; Restore the original GDA code
	call	GDF_PATCH_REST	; ...		       GDF ...

; Allocate all of available DOS memory

	call	AllocMem	; Allocate all of DOS memory

; Install our patch to GDA/GDF

	call	GDF_PATCH_INST	; Install our GDF patch
	call	GDA_PATCH_INST	; ...	      GDA ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HookedAllocMem endp		; End HookedAllocMem procedure
	NPPROC	AllocMem -- Allocate All DOS Memory
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate all of DOS memory

|

	pushad			; Save all EGP registers

	test	LCL_FLAG,@LCL_DISABLE ; Are we disabled?
	jnz	near ptr AllocMemExit1 ; Jump if so

;;;;;;; call	GetCurrentTask	; Return with handle in AX
;;;;;;; mov	hCurTask,ax	; Save to restore later
;;;;;;;
AllocMemStart:
	imul	si,DOSMemCnt,type DOSMem_STR ; Initialize index into DOSMem table
	mov	cbDOSAlloc,@MaxDOSAlloc ; Initialize DOS allocation size
	xor	di,di		; Initialize allocation count
AllocMemNext1:
	cmp	si,@DOSCnt * (type DOSMem_STR) ; Is the table full?
	jb	short AllocMemNext2 ; Jump if not

	bts	LCL_FLAG,$LCL_TABFULL ; Mark as full
	jc	short AllocMemExit ; Jump if already marked

	call	FreeAllMem	; Free all memory

	jmp	short AllocMemStart ; Start over again

AllocMemNext2:
	cmp	cbDOSAlloc,@MinDOSAlloc ; Is the requested size too small?
	jb	short AllocMemExit ; Jump if so

	REGSAVE <si,di> 	; Save for a moment

	push	cbDOSAlloc	; Pass size of allocation
	call	GlobalDOSAlloc	; Request DOS memory
				; Return with AX = selector
				; ...	      DX = segment
	REGREST <di,si> 	; Restore

	and	ax,ax		; Did it work?
	jnz	short @F	; Jump if so

	shr	cbDOSAlloc,1	; Divide current allocation size by two

	jmp	AllocMemNext2	; ...and try again

@@:

; AX = 1st selector
; DX = segment

	inc	di		; Count it in
	inc	DOSMemCnt	; Count it in, protecting the memory
	imul	si,DOSMemCnt,type DOSMem_STR ; Initialize index into DOSMem table
	sub	si,type DOSMem_STR ; Back off to new entry

	mov	DOSMem[si].DOSMemSeg,dx  ; Save for later use
	mov	DOSMem[si].DOSMemSel,ax  ; ...

; See if this is a lower segment than we've encountered before

	cmp	dx,wLowSeg	; Izit lower?
	jae	short @F	; Jump if not

	mov	wLowSeg,dx	; Save as new low segment
@@:
	mov	ecx,cbDOSAlloc	; Get the allocation size
	shr	ecx,4-0 	; Convert from bytes to paras
	mov	DOSMem[si].DOSMemELen,cx  ; Save for later use

; Because the current task will end up owning the memory, we
; need to change the owner field of any memory we allocate to
; that of the initial task (presumably, it's PROGMAN) so it'll
; end up owning the memory

; Walk the heap and change the owner of memory we allocated to
; that of the initial task or PDB as appropriate

	push	DOSMem[si].DOSMemSel ; Pass the handle
	call	ChangeOwner	; Change the owner to us

	add	si,type DOSMem_STR ; Skip to next entry
AllocMemBug1:
	jmp	AllocMemNext1	; ...and try again

AllocMemExit:
	and	LCL_FLAG,not @LCL_TABFULL ; Clear table full flag for next time

	and	di,di		; Did we allocate aything?
	jz	short AllocMemExit1 ; Jump if not

	call	SortMem 	; Sort and merge free memory blocks

	cmp	wGore,0 	; Izit inactive?
	je	short @F	; Jump if so

	call	GoreMem 	; Ensure at least wGore paras available
@@:
	call	MemChanged	; Tell any app interested that memory changed
AllocMemExit1:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AllocMem endp			; End AllocMem procedure
	NPPROC	GetGlobalHeap -- Get Selector Of Global Heap
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get selector of global heap

On exit:

AX	=	selector

|

	REGSAVE <bx,cx,dx,si,di,es> ; Save registers

; Get the address of the GlobalMasterHandle function
; #define GETPROC(modname, funcname) \
;	  GetProcAddress(GetModuleHandle(modname), (funcname))
; GlobalMasterHandle = GETPROC("KERNEL", "GLOBALMASTERHANDLE");

	push	ds		; Pass segment of "KERNEL"
	push	offset DGROUP:szKERNEL ; ... offset ...
	call	GetModuleHandle ; Return AX = module handle

	push	ax		; Pass the module handle
	push	ds		; Pass segment of "GLOBALMASTERHANDLE"
	push	offset DGROUP:szGMH ; ... offset ...
	call	GetProcAddress	; Return DX:AX ==> address

	mov	lpGMH.VOFF,ax	; Save for later use
	mov	lpGMH.VSEG,dx	; ...

	call	lpGMH		; Returns AX = handle
				; ...	  DX = selector
	mov	ax,dx		; Copy to return register

	REGREST <es,di,si,dx,cx,bx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetGlobalHeap endp		; End GetGlobalHeap procedure
	NPPROC	ChangeOwner -- Change The Owner Of Block To Us
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Chanege the owner of a memory block to us

On entry:

SS:SP	==>	CO_STR (before PUSH BP)

|

CO_STR	struc

	dw	?		; Caller's IP
	dw	?		; ...	   BP
CO_HNDL dw	?		; Handle to search for

CO_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save registers

	push	[bp].CO_HNDL	; Pass the handle
	call	FindOwner	; Find the matching Global Heap entry
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:EBX ==> Global heap entry
	jc	short ChangeOwnerExit ; Jump if not found

	mov	ax,hOurOwnr	; Get the handle of our owner
	mov	es:[ebx].GA32Owner,ax ; Change the owner
ChangeOwnerExit:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; ...

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ChangeOwner endp		; End ChangeOwner procedure
	NPPROC	FindOwner -- Find Owner Entry In Global Heap
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find owner entry in Global heap.

On exit:

If successful,

CF	=	0
ES:EBX	==>	owner entry in Global Heap

If not,

CF	=	1
ES clobbered

|

FO_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
FO_HNDL dw	?		; The handle to find

FO_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,cx> 	; Save registers

	call	GetGlobalHeap	; Return with AX = selector of global heap

	mov	es,ax		; ES:0 ==> global heap
	assume	es:nothing	; Tell the assembler about it

	mov	cx,es:[0].GH32_GHCNT ; Get the # Global Arena entries
	jcxz	FindOwnerError	; Jump if none???

	mov	ebx,es:[0].GH32_OFF1ST ; Get the offset to the first Global Arena
	mov	ax,[bp].FO_HNDL ; Get the handle
FindOwnerNext:
	cmp	ax,es:[ebx].GA32Handle ; Izit the same handle?
	je	short FindOwnerExit ; Jump if so (note CF=0)

	mov	ebx,es:[ebx].GA32Next ; Get offset of next Global Arena

	loop	FindOwnerNext	; Jump if more Global Arena entries
FindOwnerError:
	stc			; Mark as not found
FindOwnerExit:
	REGREST <cx,ax> 	; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindOwner endp			; End FindOwner procedure
	NPPROC	FreeAllMem -- Free All Allocated Memory
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Free all allocated memory

|

	pusha			; Save registers
	push	es		; ...

; We loop backwards through the DOSMem table so if there's an error,
; we end up with a valid table (DOSMemCnt is valid and the trailing
; entries are zero).

	mov	cx,DOSMemCnt	; Get # entries
	jcxz	FreeAllMemExit	; Jump if none
	imul	si,cx,type DOSMem_STR ; Initialize index into DOSMem table
FreeAllMemNext:
	sub	si,type DOSMem_STR ; Back off to next entry

	REGSAVE <cx,si> 	; Keep away from W

	push	DOSMem[si].DOSMemSel ; Pass the first selector
	call	GlobalDOSFree	; Free the memory
	assume	es:nothing	; Tell the assembler about it
				; Returns AX = 0 if successful
	REGREST <si,cx> 	; Restore

	and	ax,ax		; Did it work?
	jz	short @F	; Jump if so

	DEBUG_MAC 1		; Call our debugger

	jmp	short FreeAllMemErr ; Join common error code

@@:
	push	cx		; Save loop counter

	mov	ax,ds		; Copy seg DGROUP
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	di,DOSMem[si]	; ES:DI ==> DOSMem entry to clear
	xor	ax,ax		; Set to this value
	mov	cx,(type DOSMem_STR)/2 ; Get # words to set
	cld			; String ops forwardly
    rep stos	DOSMem[di].ELO	; Zero the last entry

	pop	cx		; Restore loop counter

	dec	DOSMemCnt	; One fewer entry

	loop	FreeAllMemNext	; Jump if more entries
FreeAllMemErr:
FreeAllMemExit:
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
	popa			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FreeAllMem endp 		; End FreeAllMem procedure
	NPPROC	AccumFree -- Accumulate Amount Of Free DOS Memory
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Accumulate the amount of free DOS memory

On exit:

EAX	=	amount of free DOS in bytes

|

	REGSAVE <cx,si> 	; Save registers

	xor	eax,eax 	; Initialize accumulator
	xor	si,si		; Initialize index into DOSMem
	mov	cx,DOSMemCnt	; Get # entries
	jcxz	AccumFreeNone	; Jump if none
AccumFreeNext:
	add	ax,DOSMem[si].DOSMemELen ; Add in the size in paras

	add	si,type DOSMem_STR ; Skip to new entry

	loop	AccumFreeNext	; Jump if more
AccumFreeNone:
	shl	eax,4-0 	; Convert from paras to bytes

	REGREST <si,cx> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AccumFree endp			; End AccumFree procedure
	NPPROC	AccumMemHist -- Accumulate Memory History
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Accumulate memory history

|

	REGSAVE <eax,esi>	; Save registers

	call	AccumFree	; Return EAX = amount of free DOS in bytes
	shr	eax,4-0 	; Convert from bytes to paras

	movzx	esi,MemHistHead ; Get index in MemHistTab of head
	mov	MemHistTab[esi*(type MemHistStr)].MemHistFree,ax ; Save as recent memory history

	inc	si		; Skip to next entry

	cmp	si,MemHistEnd	; Izit at the end?
	jne	short @F	; Jump if not

	mov	si,MemHistStart ; Start over again
@@:
	mov	MemHistHead,si	; Save for next time

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AccumMemHist endp		; End AccumMemHist procedure
	NPPROC	MemChanged -- Memory Changed Procedure
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory changed -- tell others about it.

|

	pushad			; Save all EGP registers

; Accumulate the amount of free DOS memory

	call	AccumFree	; Return EAX = amount of free DOS in bytes
	mov	dwAccumFree,eax ; Save for later use

	xor	si,si		; Initialize index into hRegs
	mov	cx,@NHREGS	; Get # entries in table
MemChangedNext:
	cmp	hRegs[si].REG_hWnd,0 ; Izit free?
	je	short MemChangedLoop ; Jump if so

	REGSAVE <cx>		; Keep away from W

	push	hRegs[si].REG_hWnd ; Pass hWnd
	call	IsWindow	; Return 0 if invalid window handle

	cmp	ax,0		; Izit an invalid window handle?
	je	short @F	; Jump if so

	push	hRegs[si].REG_hWnd ; Pass hWnd
	push	WM_USER 	; ...  command message
	push	hRegs[si].REG_uDOSMsg ; wParam = the message
	push	dwAccumFree	; lParam = size of free DOS in bytes
	call	PostMessage	; Tell 'em the memory changed

	mov	ax,hRegs[si].REG_hWnd ; Get hWnd
@@:
	REGREST <cx>		; Restore

	mov	hRegs[si].REG_hWnd,ax ; Save hWnd
MemChangedLoop:
	add	si,type REG_STR ; Skip to next entry

	loop	MemChangedNext	; Jump if more entries

; Accumulate as memory history

	call	AccumMemHist	; Accumulate it

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MemChanged endp 		; End MemChanged procedure
	NPPROC	FindMem -- Find Room For A Memory Allocation
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find room for a memory allocation

First we try finding it in the ELen values.
If we fail, we try in the TLen values.

On entry:

BX	=	# paras to allocate

On exit:

DX	=	-1 if not successful
SI	=	offset into DOSMem of block if successful

|

	REGSAVE <ax,cx,di>	; Save registers

	xor	di,di		; Initialize index into DOSMem
	mov	dx,-1		; Mark as none found as yet
;;;;;;; mov	si,-1		; ...
	mov	cx,DOSMemCnt	; Get # entries
	jcxz	FindMemExit	; Jump if none
FindMemNext1:
	mov	ax,DOSMem[di].DOSMemELen ; Get the individual length in paras

	sub	ax,bx		; Izit big enough?
	jc	short FindMemLoop1 ; Jump if not

	cmp	ax,dx		; Izit a better fit?
	jae	short FindMemLoop1 ; Jump if not

	mov	dx,ax		; Save as best fit so far
	mov	si,di		; ...
FindMemLoop1:
	add	di,type DOSMem_STR ; Skip to next entry

	loop	FindMemNext1	; Jump if more entries to check

	cmp	dx,-1		; Did we find anything?
	jne	short FindMemExit ; Jump if so

	xor	di,di		; Initialize index into DOSMem
;;;;;;; mov	dx,-1		; Mark as none found as yet
;;;;;;; mov	si,-1		; ...
	mov	cx,DOSMemCnt	; Get # entries
FindMemNext2:
	mov	ax,DOSMem[di].DOSMemTLen ; Get the total length in paras

	sub	ax,bx		; Izit big enough?
	jc	short FindMemLoop2 ; Jump if not

	cmp	ax,dx		; Izit a better fit?
	jae	short FindMemLoop2 ; Jump if not

	mov	dx,ax		; Save as best fit so far
	mov	si,di		; ...
FindMemLoop2:
	add	di,type DOSMem_STR ; Skip to next entry

	loop	FindMemNext2	; Jump if more entries to check
FindMemExit:
	REGREST <di,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindMem endp			; End FindMem procedure
	NPPROC	FindLargest -- Find Size of Largest Free Block
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the size of the largest free block

On exit:

BX	=	# paras in largest free block
SI	=	offset into DOSMem of largest block

|

	REGSAVE <ax,cx,di>	; Save registers

	xor	bx,bx		; Initialize accumulator
	xor	di,di		; Initialize index into DOSMem
	mov	cx,DOSMemCnt	; Get # entries
	jcxz	FindLargestExit ; Jump if none
FindLargestNext:
	mov	ax,DOSMem[di].DOSMemTLen ; Get the total size in paras

	cmp	ax,bx		; Izit bigger?
	jb	short @F	; Jump if not

	mov	bx,ax		; Save as largest size
	mov	si,di		; Save as offset into DOSMem
@@:
	add	di,type DOSMem_STR ; Skip to new entry

	loop	FindLargestNext ; Jump if more
FindLargestExit:
	REGREST <di,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindLargest endp		; End FindLargest procedure
	NPPROC	FreeMem -- Free A Memory Block
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Free a memory block

On entry:

BX	=	# paras to free
SI	=	offset into DOSMem of 1st memory block to free

|

	pusha			; Save all GP registers

; Free the memory back to W

	call	GDF_PATCH_REST ; Restore the original GDF code

	mov	cx,DOSMem[si].DOSMemAdj ; Get # adjacent entries
FreeMemNext:
	REGSAVE <bx,cx,si>	; Keep W's grubby hands off these

	push	DOSMem[si].DOSMemSel ; Pass the selector
	call	GlobalDOSFree	; Free the memory
				; Returns AX = 0 if successful
	and	ax,ax		; Did it work?
	jz	short @F	; Jump if so

	DEBUG_MAC 2		; Call our debugger
@@:
	REGREST <si,cx,bx>	; Restore

	mov	ax,DOSMem[si].DOSMemELen ; Get length in paras
				; before DeleteMem clobbers it

; Delete the entry from our table

	call	DeleteMem	; Delete the block at SI

; Note that there's no need to increment SI as the above call to
; DeleteMem has moved the entries above SI down on top of it

	sub	bx,ax		; Less the length of this entry
	jbe	short @F	; Jump if that's enough

	loop	FreeMemNext	; Jump if more adjacent entries
@@:
	call	MergeMem	; Merge adjacent memory blocks

	call	GDF_PATCH_INST	; Install our GDF patch

	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FreeMem endp			; End FreeMem procedure
	FPPROC	WEP -- W Exit Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

W exit procedure

On exit:

AX	=	TRUE or FALSE

|

WEP_STR struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
bSystemExit dw	?		; 06:  bSystemExit = WEP_SYSTEM_EXIT
				;		  or WEP_FREE_DLL
WEP_STR ends

;;;;;;; push	bp		; Prepare to address the stack
;;;;;;; mov	bp,sp		; SS:BP ==> WEP_STR
;;;;;;;
	push	ds		; Save register

	mov	ax,seg DGROUP	; Get our data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	call	FN_DRV_FREE	; Free us from memory

	mov	ax,TRUE 	; Return to caller

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

;;;;;;; pop	bp		; Restore
;;;;;;;
	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WEP	endp			; End WEP procedure
	FPPROC	LCL_GDAProc -- Local GlobalDOSAlloc Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local GlobalDOSAlloc procedure

On entry:

SS:SP	==>	GDA_STR (after PUSH BP)

On exit:

AX	=	selector
DX	=	segment

|

GDA_STR struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
GDA_Count dd	?		; 06:  # bytes to allocate

GDA_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ebx,si,ds>	; Save registers

	mov	ax,seg DGROUP	; Get our data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; Search for the best fit

	mov	ebx,[bp].GDA_Count ; Get the # bytes to allocate

	cmp	ebx,@CON1MB	; Izit too large?
	jae	short LCL_GDAProcErr ; Jump if so

	add	ebx,16+16-1	; Round up to para boundary plus another
				; para because that's what W does
	shr	ebx,4-0 	; Convert from bytes to paras
	jz	short LCL_GDAProcErr ; Jump if none

	call	FindMem 	; Find room for BX paras
				; Return with DX = -1 if none
				; DOSMem[si] = block, if successful
; See if we found a hole

	cmp	dx,-1		; Did we find a hole?
	je	short LCL_GDAProcErr ; Jump if not

	call	FreeMem 	; Free the memory block at DOSMem[si] for BX paras

; Ask W to allocate the memory

LCL_GDAProcErr:
	DEBUG_MAC		; Call our debugger

	call	GDA_PATCH_REST	; Restore the original GDA code
	call	GDF_PATCH_REST	; ...		       GDF ...

	push	[bp].GDA_Count	; Get the # bytes to allocate
	call	GlobalDOSAlloc	; Request DOS memory
				; Return with AX = selector
				; ...	      DX = segment
	and	ax,ax		; Did it work?
	jnz	short @F	; Jump if so

	DEBUG_MAC -1		; Call our debugger
@@:
	call	AllocMem	; Allocate all of DOS memory
				; and call MemChanged if we got any
	call	GDF_PATCH_INST	; Install our GDF patch
	call	GDA_PATCH_INST	; ...	      GDA ...

	REGREST <ds,si,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_GDAProc endp		; End LCL_GDAProc procedure
;;;;	      FPPROC  LCL_GAProc -- Local GlobalAlloc Procedure
;;;;	      assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;; COMMENT|
;;;;
;;;; Local GlobalAlloc and GlobalDOSAlloc procedures
;;;;
;;;; 1.  If DOS alloc, handle separately.
;;;; 2.  If not DOS alloc, restore the original code for GA
;;;; 3.  Call original GlobalAlloc with original args
;;;; 4.  Install our patch to GA
;;;;
;;;; On entry:
;;;;
;;;; SS:SP    ==>     GA_STR (after PUSH BP)
;;;;
;;;; On exit:
;;;;
;;;; AX       =       0 or hGlobal
;;;;
;;;; |
;;;;
;;;; GA_STR   struc
;;;;
;;;;	      dw      ? 	     ; 00:  Caller's BP
;;;;	      dd      ? 	     ; 02:  ...      CS:IP
;;;; GA_Count dd      ? 	     ; 06:  # bytes to allocate
;;;; GA_Flags dw      ? 	     ; 0A:  Flags (see GMEM_xxx)
;;;;
;;;; GA_STR   ends
;;;;
;;;;	      push    bp	     ; Prepare to address the stack
;;;;	      mov     bp,sp	     ; Hello, Mr. Stack
;;;;
;;;;	      REGSAVE <ds>	     ; Save register
;;;;
;;;;	      mov     ax,seg DGROUP  ; Get our data selector
;;;;	      mov     ds,ax	     ; Address it
;;;;	      assume  ds:DGROUP      ; Tell the assembler about it
;;;;
;;;; ; 1.  If DOS alloc, handle separately
;;;;
;;;;	      test    [bp].GA_Flags,GMEM_DOSALLOC ; Izit a DOS allocate?
;;;;	      jz      short @F	     ; Jump if not
;;;;
;;;;	      push    [bp].GA_Count  ; Pass the original byte count
;;;;	      call    LCL_GDAProc    ; Handle separately
;;;;
;;;;	      jmp     short LCL_GAProcExit ; Join common exit code
;;;;
;;;; @@:
;;;;
;;;; ; 2.  If not DOS alloc, restore the original code for GA
;;;;
;;;;	      call    GA_PATCH_REST  ; Restore the original GA code
;;;;
;;;; ; 3.  Call original GlobalAlloc with original args
;;;;
;;;;	      push    [bp].GA_Flags  ; Pass the original flags
;;;;	      push    [bp].GA_Count  ; ...		 byte count
;;;;	      call    GlobalAlloc    ; Call the original routine
;;;;				     ; Return AX = hGlobal or 0
;;;; ; 4.  Install our patch to GA
;;;;
;;;;	      call    GA_PATCH_INST  ; Install our GA patch
;;;; LCL_GAProcExit:
;;;;	      REGREST <ds>	     ; Restore
;;;;	      assume  ds:nothing     ; Tell the assembler about it
;;;;
;;;;	      pop     bp	     ; Restore
;;;;
;;;;	      ret     2+4	     ; Return to caller, popping arguments
;;;;
;;;;	      assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;;
;;;; LCL_GAProc endp		     ; End LCL_GAProc procedure
	FPPROC	LCL_GDFProc -- Local GlobalDOSFree Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local GlobalDOSFree procedure

Previously I did the following:

1.  Restore the original GDF code
2.  Call GlobalDOSFree on the original selector
3.  Install our GDF patch
4.  Allocate all available DOS memory

However, this doesn't work as W isn't expecting to get
GlobalDOSAlloc calls if it has just freed the current TDB
as it references that selector within GDA, hence a GP Fault
(that one was fun to find).

Instead, the GDF selector is appended to our local table directly.

1.  Append the freed memory to DOSMem table
2.  Merge the entries
3.  Change the owner of the freed block to us

On entry:

SS:SP	==>	GDF_STR (after PUSH BP)

On exit:

AX	=	0 if successful
	=	original selector if not

|

GDF_STR struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
GDF_Sel dw	?		; 06:  Selector whose memory to free

GDF_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ds>		; Save register

	mov	ax,seg DGROUP	; Get our data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	REGSAVE <bx,ecx,dx,si>	; Save registers

	call	GDF_PATCH_REST	; Restore the original GDF code

; 1.  Append the freed memory to DOSMem table

	DEBUG_MAC		; Call our debugger

	mov	bx,[bp].GDF_Sel ; Get the selector
	mov	ax,bx		; Copy to check the RPL
	and	ax,mask $PL	; Isolate the RPL bits

	cmp	ax,RPL3 	; Izit RPL 3?
	jne	short LCL_GDFProcErr ; Jump if not

	DPMICALL @DPMI_GSELBAS	; Return selector base address in CX:DX
	jc	short LCL_GDFProcErr ; Jump on error

	shl	ecx,16		; Shift to high-order word
	mov	cx,dx		; Copy low-order word

	cmp	ecx,@CON1MB	; Izit bigger than DOS can handle?
	jae	short LCL_GDFProcErr ; Jump if so

	shr	ecx,4-0 	; Convert from bytes to paras

	imul	si,DOSMemCnt,type DOSMem_STR ; Initialize index into DOSMem table

	cmp	si,(@DOSCnt * (type DOSMem_STR))-1 ; Is the table full?
	jae	short LCL_GDFProcErr ; Jump if so

	inc	DOSMemCnt	; Count it in, protecting the memory
	imul	si,DOSMemCnt,type DOSMem_STR ; Initialize index into DOSMem table
	sub	si,type DOSMem_STR ; Back off to new entry

	mov	DOSMem[si].DOSMemSel,bx ; Save as selector

	mov	DOSMem[si].DOSMemSeg,cx ; Save as segment

	lsl	ecx,ebx 	; Get the segment limit
	add	ecx,1+(16-1)	; Convert from limit to length
				; round up to para boundary
	shr	ecx,4-0 	; Convert from bytes to paras
	mov	DOSMem[si].DOSMemELen,cx ; Save as length in paras

; 2.  Sort and merge the entries

	call	SortMem 	; Sort and merge free memory blocks
	call	MemChanged	; Tell any app interested that memory changed

; 3.  Change the owner of the freed block to us

;;;;;;; call	GetCurrentTask	; Return with handle in AX
;;;;;;; mov	hCurTask,ax	; Save to restore later
;;;;;;;
	push	[bp].GDF_Sel	; Pass the handle
	call	ChangeOwner	; Change the owner to us

	xor	ax,ax		; Mark as successful

	jmp	short LCL_GDFProcExit ; Join common exit code

LCL_GDFProcErr:
	push	[bp].GDF_Sel	; Pass the selector
	call	GlobalDOSFree	; Let W handle the error
LCL_GDFProcExit:
	call	GDF_PATCH_INST	; Install our GDF patch

	REGREST <si,dx,ecx,bx>	; Restore

; Because we just freed a selector and it could be DS, we can't
; pop DS without running into a GP Fault

;;;;;;; REGREST <ds>		; Restore
;;;;;;; assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore DS

	verr	bp		; Izit a valid selector?
	jz	short @F	; Jump if so

	xor	bp,bp		; Set to known value
@@:
	mov	ds,bp		; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_GDFProc endp		; End LCL_GDFProc procedure
	FPPROC	LCL_GFProc -- Local GlobalFree Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local GlobalFree procedure

1.  Restore the original code for GF
2.  Call original GlobalFree with original args
3.  Install our patch to GF
4.  Allocate all of available DOS memory

On entry:

SS:SP	==>	GF_STR (after PUSH BP)

|

GF_STR	struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
GF_Sel	dw	?		; 06:  Selector whose memory to free

GF_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ds>		; Save register

	mov	ax,seg DGROUP	; Get our data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; 1.  Restore the original code for GF

	call	GF_PATCH_REST	; Restore the original GF code

; 2.  Call original GlobalFree with original args

	push	[bp].GF_Sel	; Pass the original selector
	call	GlobalFree	; Call the original routine

; 3.  Install our patch to GF

	call	GF_PATCH_INST	; Install our GF patch

; 4.  Allocate all of available DOS memory

	test	LCL_FLAG,@LCL_GFALLOC ; Allocate more memory?
	jz	short @F	; Jump if not

	call	HookedAllocMem	; Allocate all of DOS memory
				; and call MemChanged if we got any
@@:
LCL_GFProcExit:

; Because we just freed a selector and it could be DS, we can't
; pop DS without running into a GP Fault

;;;;;;; REGREST <ds>		; Restore
;;;;;;; assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore DS

	verr	bp		; Izit a valid selector?
	jz	short @F	; Jump if so

	xor	bp,bp		; Set to known value
@@:
	mov	ds,bp		; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_GFProc endp 		; End LCL_GFProc procedure
	NPPROC	DeleteMem -- Delete A Memory Block
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Delete a memory block

On entry:

SI	=	offset into DOSMem table

|

	REGSAVE <ax,cx,si,di,es> ; Save registers

	mov	ax,ds		; Copy seg DGROUP
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	imul	cx,DOSMemCnt,type DOSMem_STR ; Initialize index into DOSMem table
	sub	cx,type DOSMem_STR ; Less the one we're losing
	sub	cx,si		; Less source offset to get length in bytes
	shr	cx,1-0		; Convert from bytes to words

	lea	di,DOSMem[si]	; Copy as destination offset
	lea	si,DOSMem[si+(type DOSMem_STR)] ; Skip to next (source) offset

	cld			; String ops forwardly
    rep movs	DOSMem[di].ELO,DOSMem[si].ELO ; Copy the table down

	xor	ax,ax		; Set to this value
	mov	cx,(type DOSMem_STR)/2 ; Get # words to set
    rep stos	DOSMem[di].ELO	; Zero the last entry

	dec	DOSMemCnt	; One fewer table entry

	REGREST <es,di,si,cx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DeleteMem endp			; End DeleteMem procedure
	NPPROC	SortMem -- Sort And Merge Memory Blocks
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Sort and merge memory blocks

|

	REGSAVE <ax,cx,si,di,es> ; Save registers

	mov	ax,ds		; Copy seg DGROUP
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	si,DOSMem	; DS:SI ==> DOSMem_STR structure

; As there are relatively few entries, we'll use a simple bubble sort

	mov	cx,DOSMemCnt	; Get # entries

	sub	cx,1		; Account for last entry (the number of
				; comparisons is DOSMemCnt-1)
	jbe	short SortMemExit ; Jump if nothing to sort
SortMemOuter:
	push	cx		; Save outer loop counter

	lea	di,DGROUP:[si+(type DOSMem_STR)] ; Skip to next entry
	mov	ax,DGROUP:[si].DOSMemSeg ; Get starting address
SortMemInner:
	cmp	ax,DGROUP:[di].DOSMemSeg ; Izit in sequence?
	jbe	short SortMemInnerLoop ; Jump if so

; Rotate the entries between SI (low) and DI (high) upwards

	push	si		; Save starting offset

; Save the last entry on the stack

	mov	cx,(type DOSMem_STR)/2 ; Get # words in each entry
@@:
	push	DGROUP:[di].ELO ; Save on stack
	add	di,2		; Skip to next word
	loop	@B		; Jump if more words to save

; DI points to next word following higher entry

	mov	cx,di		; Copy higher ending address
	sub	cx,si		; Subtract to get # bytes to rotate
	sub	cx,type DOSMem_STR ; Less one entry saved on the stack
	shr	cx,1-0		; Convert from bytes to words
	sub	di,2		; Back off to previous word
	lea	si,[di-(type DOSMem_STR)] ; Point to entry below higher
	std			; String ops backwards
    rep movs	DOSMem[di].ELO,DOSMem[si].ELO ; Move downwards
	cld			; Restore

; Restore the last entry from the stack to the first entry
; to complete the rotation

	mov	cx,(type DOSMem_STR)/2 ; Get # words in each entry
@@:
	pop	DGROUP:[di].ELO ; Restore from stack
	sub	di,2		; Skip to previous word
	loop	@B		; Jump if more words to restore

	pop	si		; Restore
	pop	cx		; Restore outer loop counter

	jmp	short SortMemOuter ; Go around again

SortMemInnerLoop:
	add	di,type DOSMem_STR ; Skip to next entry

	loop	SortMemInner	; Jump if more entries in inner loop

	pop	cx		; Restore outer loop counter

	add	si,type DOSMem_STR ; Skip to next entry

	loop	SortMemOuter	; Jump if more entries in outer loop
SortMemExit:
	call	MergeMem	; Merge adjacent memory blocks

	REGREST <es,di,si,cx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SortMem endp			; End SortMem procedure
	NPPROC	MergeMem -- Merge Adjacent Memory Blocks
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Merge adjacent memory blocks via adjacency numbers.
We can't actually combine the entries because we need
to preserve the individual selectors.

|

	pusha			; Save registers
MergeMemAgain:
	mov	cx,DOSMemCnt	; Get # entries
	and	cx,cx		; Izit empty?
	jz	near ptr MergeMemExit ; Jump if no entries

	dec	cx		; Account for last entry (the number of
				; comparisons is DOSMemCnt-1)
	imul	si,cx,type DOSMem_STR ; Initialize index into DOSMem table
				; SI is the index of the last entry
	mov	dx,1		; Initialize adjacency #
	mov	bx,DOSMem[si].DOSMemELen ; Get the indivdual length
	jcxz	MergeMemExit0	; Jump if only one entry
MergeMemNext:
	mov	DOSMem[si].DOSMemAdj,dx ; Save as the adjacency #
	mov	DOSMem[si].DOSMemTLen,bx ; Save as the total length

	sub	si,type DOSMem_STR ; Skip to prev entry

	mov	ax,DOSMem[si].DOSMemSeg ; Get the segment

	cmp	ax,DOSMem[si+(type DOSMem_STR)].DOSMemSeg ; Duplicate?
	jne	short MergeMemNoDup1 ; Jump if not

	DEBUG_MAC -1		; Call our debugger

	jmp	short MergeMemDup ; Join common code

MergeMemNoDup1:
	add	ax,DOSMem[si].DOSMemELen ; Plus its length in paras

	cmp	ax,DOSMem[si+(type DOSMem_STR)].DOSMemSeg ; Overlap?
	jbe	short MergeMemNoDup2 ; Jump if not

	DEBUG_MAC -1		; Call our debugger
MergeMemDup:
	mov	ax,DOSMem[si].DOSMemELen ; Get its length in paras

	cmp	ax,DOSMem[si+(type DOSMem_STR)].DOSMemELen ; Delete the larger block
	jae	short @F	; Jump if block SI is larger

	add	si,type DOSMem_STR ; Skip to larger entry
@@:
	call	DeleteMem	; Delete the block at SI

	bts	LCL_FLAG,$LCL_DUPDIS ; Mark as disabled due to duplication
	jc	short @F	; Jump if already so marked

	test	LCL_FLAG,@LCL_GOREDIS or @LCL_CMDDIS ; Izit already disabled?
	jnz	short @F	; Jump if so

	call	ChangeToDisable ; Change state to disabled
@@:
	jmp	MergeMemAgain	; Go around again

MergeMemNoDup2:
	cmp	ax,DOSMem[si+(type DOSMem_STR)].DOSMemSeg ; Izit adjacent?
	jne	short MergeMemLoop ; Jump if not

	inc	dx		; Skip to next adjaceny #
	add	bx,DOSMem[si].DOSMemELen ; Plus its length in paras

	jmp	short MergeMemLoop1 ; Join common loop code

MergeMemLoop:
	mov	dx,1		; Initialize adjacency #
	mov	bx,DOSMem[si].DOSMemELen ; Get the indivdual length
MergeMemLoop1:
	loop	MergeMemNext	; Jump if more entries
MergeMemExit0:
	mov	DOSMem[si].DOSMemAdj,dx ; Save as the adjacency #
	mov	DOSMem[si].DOSMemTLen,bx ; Save as the total length
MergeMemExit:
	test	LCL_FLAG,@LCL_DUPDIS ; Izit disabled due to duplication?
	jz	short @F	; Jump if not

	call	FreeAllMem	; Free all memory
	call	MemChanged	; Tell any app interested that memory changed
@@:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MergeMem endp			; End MergeMem procedure
	FPPROC	DriverProc -- Callback Driver Message handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Callback driver message handler

The sequence of calls is

Startup:
	LibMain

In response to drivers= line in SYSTEM.INI [boot] section
	DRV_FIRST
	DRV_LOAD
	DRV_ENABLE

In response to OpenDriver call:
	DRV_FIRST (unless already loaded)
	DRV_LOAD (unless already loaded)
	DRV_ENABLE (unless already enabled)
	DRV_OPEN

In response to CloseDriver call:
	DRV_CLOSE
	DRV_DISABLE (if last instance of driver)
	DRV_FREE (if last instance of driver)

Per application:
	DRV_EXITAPPLICATION (as needed)

End:
	DRV_EXITSESSION
	DRV_DISABLE
	DRV_FREE

On entry:

SS:SP	==>	DP_STR (before PUSH BP)

On exit:

DX:AX	=	result

|

DP_STR	struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
DP_lParam2 dd	?		; 06:  lParam2
DP_lParam1 dd	?		; 0A:  lParam1
DP_wMessage dw	?		; 0E:  wmessage
DP_hDriver dw	?		; 10:  hDriver
DP_dwDriverIdent dd ?		; 12:  dwDriverident

DP_STR	ends

	push	ds		; This is some standard preliminary
	pop	ax		; shuffling of the registers.
	nop			;	 /
	inc	bp		;	 / (it is called the prolog code)
	push	bp		;	 /
	mov	bp,sp		;	 /
	push	ds		;	 /

	mov	ds,ax		;	 /
	assume	ds:DGROUP	;	 / (enters function with DS=_DATA)

	mov	ax,[bp].DP_wMessage ; Get message-type

	DEBUG_MAC		; Call our debugger

	cmp	ax,DRV_LOAD	; Izit load time?
	je	near ptr DP_DRV_LOAD ; Jump if so

	cmp	ax,DRV_FREE	; Izit free time?
	je	near ptr DP_DRV_FREE ; Jump if so

;;;;;;; cmp	ax,DRV_ENABLE	; Izit enable time?
;;;;;;; je	near ptr DP_DRV_ENABLE ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,DRV_DISABLE	; Izit disable time?
;;;;;;; je	near ptr DP_DRV_DISABLE ; Jump if so
;;;;;;;
	cmp	ax,DRV_OPEN	; Izit open time?
	je	near ptr DP_DRV_OPEN ; Jump if so

	cmp	ax,DRV_CLOSE	; Izit close time?
	je	near ptr DP_DRV_CLOSE ; Jump if so

;;;;;;; cmp	ax,DRV_CONFIGURE ; Izit configure time?
;;;;;;; je	short DP_DRV_CONFIGURE ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,DRV_QUERYCONFIGURE ; Izit query configure time?
;;;;;;; je	short DP_DRV_QUERYCONFIGURE ; Jump if so
;;;;;;;
	cmp	ax,DRV_INSTALL	; Izit install time?
	je	near ptr DP_DRV_INSTALL ; Jump if so

	cmp	ax,DRV_REMOVE	; Izit remove time?
	je	near ptr DP_DRV_REMOVE ; Jump if so

;;;;;;; cmp	ax,DRV_EXITAPPLICATION ; Izit exit application time?
;;;;;;; je	near ptr DP_DRV_EXITAPPLICATION ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,DRV_EXITSESSION ; Izit exit session time?
;;;;;;; je	short DP_DRV_EXITSESSION ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,DRV_POWER	; Izit power time?
;;;;;;; je	short DP_DRV_POWER ; Jump if so
;;;;;;;
; User-defined messages are numbered between DRV_RESERVED (0800h)
; and DRV_USER (4000h).  Use SendDriverMessage() to send a message
; of this type.

; Process user-defined messages

	cmp	ax,LCLDRV_GETBUFADDR ; Izit get DOSMem table address?
	je	short DP_LCLDRV_GETBUFADDR ; Jump if so

	cmp	ax,LCLDRV_GETCSDS ; Izit get CS & DS values?
	je	short DP_LCLDRV_GETCSDS ; Jump if so

	cmp	ax,LCLDRV_REGISTER ; Izit a WinApp registering with us?
	je	short DP_LCLDRV_REGISTER ; Jump if so

	cmp	ax,LCLDRV_UNREGISTER ; Izit a WinApp unregistering with us?
	je	near ptr DP_LCLDRV_UNREGISTER ; Jump if so

	cmp	ax,LCLDRV_QUERYCLOSE ; Izit a WinApp querying our DRV_CLOSE count?
	je	near ptr DP_LCLDRV_QUERYCLOSE ; Jump if so

	cmp	ax,LCLDRV_QUERYENABLE ; Izit a WinApp querying our enable state?
	je	near ptr DP_LCLDRV_QUERYENABLE ; Jump if so

	cmp	ax,LCLDRV_QUERYINSTALL ; Izit a WinApp querying our install flag?
	je	near ptr DP_LCLDRV_QUERYINSTALL ; Jump if so

	cmp	ax,LCLDRV_QUERYLOWSEG ; Izit a WinApp querying our lowest seg?
	je	near ptr DP_LCLDRV_QUERYLOWSEG ; Jump if so

	cmp	ax,LCLDRV_QUERYGORE ; Izit a WinApp querying our gore size?
	je	near ptr DP_LCLDRV_QUERYGORE ; Jump if so

	cmp	ax,LCLDRV_DISABLE ; Izit time to free memory and go dormant?
	je	near ptr DP_LCLDRV_DISABLE ; Jump if so

	cmp	ax,LCLDRV_ENABLE ; Izit time to allocate low DOS and awaken?
	je	near ptr DP_LCLDRV_ENABLE ; Jump if so

	cmp	ax,LCLDRV_GETMEMHISTORY ; Izit get MemHistTab address?
	je	near ptr DP_LCLDRV_GETMEMHISTORY ; Jump if so

	cmp	ax,LCLDRV_GETMODHISTORY ; Izit get ModHistTab address?
	je	near ptr DP_LCLDRV_GETMODHISTORY ; Jump if so

	cmp	ax,LCLDRV_GETMODFILE ; Izit get SpecMod address?
	je	near ptr DP_LCLDRV_GETMODFILE ; Jump if so

	cmp	ax,LCLDRV_READPROFILE ; Izit re-read profile?
	je	near ptr DP_LCLDRV_READPROFILE ; Jump if so

;;;;;;; jmp	short DP_DRV_DEFAULT ; Join common default processing code


;;;; DP_DRV_ENABLE:
;;;;
;;;; ; DRV_ENABLE:  Sent when the driver is loaded or reloaded and
;;;; ; when W is enabled.  Hook or rehook interrupts and
;;;; ; initialize hardware.  Expect the driver to be in memory
;;;; ; only between the enable and disable messages.
;;;; ; Return FALSE if your driver processes this message.
;;;;
;;;;
;;;; DP_DRV_DISABLE:
;;;;
;;;; ; DRV_DISABLE:  Sent before the driver is freed or when W
;;;; ; is disabled.  Unhook interrupts and place peripherals in an
;;;; ; inactive state.
;;;; ; Return FALSE if your driver processes this message.
;;;;
;;;;
;;;; DP_DRV_QUERYCONFIGURE:
;;;;
;;;; ; DRV_QUERYCONFIGURE:  Sent to determine if the driver can be
;;;; ; configured.
;;;; ; Return TRUE to indicate local configuration dialog, FALSE if not.
;;;;
;;;;
;;;; DP_DRV_CONFIGURE:
;;;;
;;;; ; DRV_CONFIGURE:  Sent to display the custom-configuration
;;;; ; dialog box for the driver.
;;;; ; Return TRUE if successful, FALSE if not.
;;;;
;;;;
;;;; DP_DRV_EXITAPPLICATION:
;;;;
;;;; ; DRV_EXITAPPLICATION:  Notifies driver that an application has terminated
;;;; ; (lParam1 specifies DRVEA_NORMALEXIT or DRVEA_ABNORMALEXIT).
;;;; ; The return value is ignored.
;;;;
;;;;
;;;; DP_DRV_EXITSESSION:
;;;;
;;;; ; DRV_EXITSESSION:  Sent when W is terminating
;;;; ; The return value is ignored.
;;;;
;;;;
;;;; DP_DRV_POWER:
;;;;
;;;; ; DRV_POWER:  Notifies driver that power source for device
;;;; ; is about to be turned off or on.
;;;; ; Return FALSE if your driver processes this message.
;;;;
;;;;
DP_DRV_DEFAULT:
	push	[bp].DP_dwDriverIdent ; Pass original data
	push	[bp].DP_hDriver       ; ...
	push	[bp].DP_wMessage      ; ...
	push	[bp].DP_lParam1       ; ...
	push	[bp].DP_lParam2       ; ...
	call	DefDriverProc	; Let the default handler process the message

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_GETBUFADDR:

; LCLDRV_GETBUFADDR:  Get address of DOSMem buffer
; Return the address of our DOSMem buffer in DX:AX

	mov	dx,ds		; Return our buffer address
	lea	ax,DOSMem	; ... in DX:AX

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_GETCSDS:

; LCLDRV_GETCSDS:  Get CS & DS values
; Return the values in DX:AX

	mov	dx,cs		; Return CS
	mov	ax,ds		; ...	 DS

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_REGISTER:

; LCLDRV_REGISTER:  Register a WinApp
; DP_lParam1.ELO contains the hWnd to register.
; DP_lParam2.ELO contains the message value to use for DOS memory changes
; DP_lParam2.EHI contains the message value to use for task count changes
; Messages should be posted to this WinApp when DOS
; memory is changed (allocated or freed).
; Return TRUE if successful, FALSE if not.

; Find a free value

	xor	si,si		; Initialize index into hRegs
	mov	cx,@NHREGS	; Get # entries in table
@@:
	cmp	hRegs[si].REG_hWnd,0 ; Izit free?
	je	short @F	; Jump if so

	add	si,type REG_STR ; Skip to next entry

	loop	@B		; Jump if more entries

	jmp	DP_FALSE	; Tell 'em we failed

@@:
	mov	ax,[bp].DP_lParam1.ELO ; Get the hWnd value
	mov	hRegs[si].REG_hWnd,ax ; Save for later use
	mov	ax,[bp].DP_lParam2.ELO ; Get the uMsg value
	mov	hRegs[si].REG_uDOSMsg,ax ; Save for later use
	mov	ax,[bp].DP_lParam2.EHI ; Get the uMsg value
	mov	hRegs[si].REG_uTSKMsg,ax ; Save for later use

; Accumulate the amount of free DOS memory

	call	AccumFree	; Return EAX = amount of free DOS in bytes
	mov	dwAccumFree,eax ; Save for later use

; Tell the caller about our DOS memory

	push	hRegs[si].REG_hWnd ; Pass hWnd
	push	WM_USER 	; ...  command message
	push	hRegs[si].REG_uDOSMsg ; wParam = the message
	push	dwAccumFree	; lParam = size of free DOS in bytes
	call	PostMessage	; Tell 'em the memory changed

; Tell the caller about our task count

	push	hRegs[si].REG_hWnd ; Pass hWnd
	push	WM_USER 	; ...  command message
	push	hRegs[si].REG_uTSKMsg ; wParam = the message
	push	dwTaskCnt	; lParam = # active tasks
	call	PostMessage	; Tell 'em the memory changed

	jmp	DP_TRUE 	; Join common TRUE code


DP_LCLDRV_UNREGISTER:

; LCLDRV_UNREGISTER:  Unregister a WinApp
; DP_lParam1.ELO contains the hWnd to unregister.
; Return TRUE if successful, FALSE if not.

; Find the incoming value

	xor	si,si		; Initialize index into hRegs
	mov	cx,@NHREGS	; Get # entries in table
	mov	ax,[bp].DP_lParam1.ELO ; Get the hWnd value
@@:
	cmp	ax,hRegs[si].REG_hWnd ; Izit our boy?
	je	short @F	; Jump if so

	add	si,type REG_STR ; Skip to next entry

	loop	@B		; Jump if more entries

	jmp	DP_FALSE	; Tell 'em we failed

@@:
	mov	hRegs[si].REG_hWnd,0 ; Clear it

	jmp	DP_TRUE 	; Join common TRUE result code


DP_LCLDRV_QUERYCLOSE:

; LCLDRV_QUERYCLOSE:  Query DRV_CLOSE count
; Return the command count in DX:AX

	xor	ax,ax		; Zero to use as word
	test	LCL_FLAG,@LCL_CLOSE ; Have we been closed before?
	setnz	al		; AL = 1 iff we've been closed before

	jmp	DP_RESULT	; Join common result in AX code


DP_LCLDRV_QUERYENABLE:

; LCLDRV_QUERYENABLE:  Query enable state
; Return the state in DX:AX

	mov	ax,4		; Assume disabled due to incompatible driver

	test	LCL_FLAG,@LCL_RIDDIS ; Izit disabled due to incompatible driver?
	jnz	short DP_LCLDRV_QE_DONE ; Jump if so

	dec	ax		; Assume disabled due to program

	test	LCL_FLAG,@LCL_DUPDIS ; Izit disabled due to duplicate memory?
	jnz	short DP_LCLDRV_QE_DONE ; Jump if so

	dec	ax		; Assume disabled due to program

	test	LCL_FLAG,@LCL_GOREDIS ; Izit disabled due to program?
	jnz	short DP_LCLDRV_QE_DONE ; Jump if so

	dec	ax		; Assume disabled due to command

	test	LCL_FLAG,@LCL_CMDDIS ; Izit disabled due to command?
	jnz	short DP_LCLDRV_QE_DONE ; Jump if so

	dec	ax		; It's not disabled
DP_LCLDRV_QE_DONE:
	jmp	DP_RESULT	; Join common result in AX code


DP_LCLDRV_QUERYINSTALL:

; LCLDRV_QUERYINSTALL:	Query install flag
; If the install flag is set and our close count is > 0, return TRUE
; otherwise return FALSE.
; Return TRUE or FALSE in DX:AX

	mov	ax,FALSE	; Assume we're not really installed

	test	LCL_FLAG,@LCL_INSTALL ; Izit installed?
	jz	short @F	; Jump if not

	test	LCL_FLAG,@LCL_CLOSE ; Have we been closed before?
	jz	short @F	; Jump if not

	mov	ax,TRUE 	; We're really installed
@@:
	jmp	DP_RESULT	; Join common result in AX code


DP_LCLDRV_QUERYLOWSEG:

; LCLDRV_QUERYLOWSEG:  Query lowest free segment ever encountered
; Return wLowSeg in DX:AX

	mov	ax,wLowSeg	; Return the value

	jmp	DP_RESULT	; Join common result in AX code


DP_LCLDRV_QUERYGORE:

; LCLDRV_QUERYGORE:  Query size in bytes of gore (amount of DOS memory to leave free)
; Return wGore*16 in DX:AX unless wGore is -1 in which case DX:AX = -1

	mov	ax,wGore	; Get the size in paras
	mov	dx,ax		; Copy to get high-order nibble

	cmp	ax,-1		; Izit disabled?
	je	short @F	; Jump if so

	shl	ax,4-0		; Convert from paras to bytes
	shr	dx,16-4 	; ...
@@:
	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_DISABLE:

; LCLDRV_DISABLE:  Free all allocated memory and go dormant.
; Return TRUE if successful, FALSE if not.

	bts	LCL_FLAG,$LCL_CMDDIS ; Mark as command disabled
	jc	short @F	; Jump if already command disabled

	test	LCL_FLAG,@LCL_GOREDIS or @LCL_DUPDIS; Izit otherwise disabled?
	jnz	short @F	; Jump if so

	call	ChangeToDisable ; Change state to disabled
@@:
	jmp	DP_TRUE 	; Join common TRUE result code


DP_LCLDRV_ENABLE:

; LCLDRV_ENABLE:  Allocate all of low DOS memory and awaken
; Return TRUE if successful, FALSE if not.

	btr	LCL_FLAG,$LCL_CMDDIS ; Mark as not command disabled
	jnc	short @F	; Jump if already not command disabled

	test	LCL_FLAG,@LCL_GOREDIS or @LCL_DUPDIS; Izit otherwise disabled?
	jnz	short @F	; Jump if so

	call	ChangeToEnable	; Change state to enabled
@@:
	jmp	short DP_TRUE	; Join common TRUE result code


DP_LCLDRV_GETMEMHISTORY:

; LCLDRV_GETMEMHISTORY:  Get address of MemHistTab buffer
; Return the address of our MemHistTab buffer in DX:AX

	mov	dx,ds		; Return our buffer address
	lea	ax,MemHistTab	; ... in DX:AX

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_GETMODHISTORY:

; LCLDRV_GETMODHISTORY:  Get address of ModHistTab buffer
; Return the address of our MemHistTab buffer in DX:AX

	mov	dx,ds		; Return our buffer address
	lea	ax,ModHistTab	; ... in DX:AX

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_GETMODFILE:

; LCLDRV_GETMODFILE:  Get address of SpecMod buffer
; Return the address of our SpecMod buffer in DX:AX

	mov	dx,ds		; Return our buffer address
	lea	ax,SpecMod	; ... in DX:AX

	jmp	DP_RETURN	; Join common result in DX:AX code


DP_LCLDRV_READPROFILE:

; LCLDRV_READPROFILE:  Re-read the profile and reset to enabled state
; Return TRUE if successful

; Change to enable state if disabled

	test	LCL_FLAG,@LCL_DISABLE ; Izit disabled?
	jz	short @F	; Jump if not

	and	LCL_FLAG,not @LCL_DISABLE ; Mark as enabled

	call	ChangeToEnable	; Change state to enabled
@@:

; Read in the special module profile

	call	ReadProfile	; Read it in
	jnc	short DP_TRUE	; Join common TRUE result code

	jmp	DP_FALSE	; Join common FALSE result code


DP_DRV_OPEN:

; DRV_OPEN:  Sent when the driver is opened.
; The open count value is subsequently used for dwDriverIdentifier.
; This function must be handled for OpenDriver() to work.
; Return TRUE if successful, FALSE if not.

	jmp	short DP_TRUE	; Join common exit code


DP_DRV_CLOSE:

; DRV_CLOSE:  Sent when the driver is closed.  Drivers are
; unloaded when the open count reaches zero.
; This function must be handled for CloseDriver() to work.
; Return TRUE if successful, FALSE if not.

	or	LCL_FLAG,@LCL_CLOSE ; Mark as having been closed

	jmp	short DP_TRUE	; Join common exit code


DP_DRV_INSTALL:

; DRV_INSTALL:	Sent when the driver is installed.  Put code here
; to insert appropriate lines into SYSTEM.INI, or elsewhere.
; Return DRVCNF_OK, DRVCNF_CANCEL, or DRVCNF_RESTART.

	push	TRUE		; Pass argument to add to "drivers=" line
	call	UpdateDrivers	; Change "drivers=" line in SYSTEM.INI [boot]
				; non-BP GP registers destroyed
	assume	es:nothing	; Tell the assembler about it
	mov	ax,DRVCNF_CANCEL ; Assume something went wrong
	jc	short @F	; Jump if already installed

	mov	ax,DRVCNF_RESTART ; Mark as needing restart

	jmp	short DP_RESULT ; Join common result in AX code


DP_DRV_REMOVE:

; DRV_REMOVE:  Sent when the driver is removed.  Put code here
; to remove lines from SYSTEM.INI such as [....] section, or
; elsewhere.
; Return TRUE if successful, FALSE if not.

	btr	LCL_FLAG,$LCL_INSTALL ; Mark as removed
	jnc	short @F	; Jump if already removed

	push	FALSE		; Pass argument to delete to "drivers=" line
	call	UpdateDrivers	; Change "drivers=" line in SYSTEM.INI [boot]
				; non-BP GP registers destroyed
	assume	es:nothing	; Tell the assembler about it
;;;;;;; jc	short ???	; Jump if not previously installed
@@:
	jmp	short DP_TRUE	; Join common true code


DP_DRV_FREE:

; DRV_FREE:  Sent when the driver is about to be discarded.
; This is the last message a driver receives before it is freed.
; Return FALSE if your driver processes this message.


	call	FN_DRV_FREE	; Free us from memory

	jmp	short DP_FALSE	; Join common FALSE return code


DP_DRV_LOAD:

; DRV_LOAD:  Sent when the driver is loaded. This is always
; the first message received by a driver.
; Return TRUE if successful, FALSE if not.

DP_TRUE:
	mov	ax,TRUE 	; Tell W we processed this message

	jmp	short DP_RESULT ; Join common code
;.........................
DP_FALSE:
	mov	ax,FALSE	; Tell W we didn't process this message
DP_RESULT:
	cwd			; Convert AX to DX:AX
DP_RETURN:
	dec	bp		; Final standard manipulation of regs.
	dec	bp		;	 /
	mov	sp,bp		;	 / (it is called the epilog code).
	pop	ds		;	 /
	pop	bp		;	 /
	dec	bp		;	 /

	ret	4+4+2+2+4	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DriverProc endp 		; End DriverProc procedure
	NPPROC	FindDriver -- Find A Driver
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find a drive name in an ASCIIZ	"drivers=" line

On exit:

DS:SI	==>	string in "drivers=" line
	==>	0 if not found

|

FD_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
FD_LEN	dw	?		; Length of string
FD_OFF	dw	?		; Offset in DGROUP of string to find

FD_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,bx,cx,di>	; Save registers

	lea	si,szStrBuf1	; DS:SI ==> "drivers=" line
FindDriversNext:
	cmp	DGROUP:[si].LO,0 ; Izit the end of the line?
	je	short FindDriversStrDone ; Jump if so

	mov	di,[bp].FD_OFF	; ES:DI ==> driver name
	mov	cx,[bp].FD_LEN	; CX = length of ...
	mov	bx,si		; Copy source offset
FindDriversNext1:
	push	si		; Save starting offset
	cmp	al,al		; Ensure ZF=1 in case CX=0
   repe cmps	szStrBuf1[si],es:[di] ; Are they the same?
	mov	bx,si		; Copy ending offset in DGROUP
	pop	si		; Restore starting offset
	je	short FindDriversStrDone ; Jump if so with SI = starting offset

; Check for case-sensitivity

	mov	al,ds:[bx-1]	; Get the last source char
	mov	ah,es:[di-1]	; ...	       destin ...
	or	ax,2020h	; Convert to lowercase

	cmp	al,ah		; Izit the same?
	je	short FindDriversNext1 ; Jump if so

; No match at this offset, skip to next driver and try again

	mov	si,bx		; Copy offset in DGROUP
	call	SKIP_BLACK	; Skip over non-white space
	call	SKIP_WHITE	; Skip over white space

	jmp	FindDriversNext ; Go around again


FindDriversStrDone:
	REGREST <di,cx,bx,ax>	; Restore

	pop	bp		; Restore

	ret	2+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindDriver endp 		; End FindDriver procedure
	NPPROC	GPPS_Blast -- GetPrivateProfileString And Compare
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

GetPrivateProfileString and compare it with sound blaster

On exit:

CF	=	0 if it's a match
	=	1 if not

|

	pusha			; Save registers

	push	es		; Keep W's grubby hands away from

	push	lpDrvrSect	; Pass ptr to section name
	push	lpSBLine	; ...	      line name
	push	lpDefValue	; ...	      default string (empty)
	push	lpSBBuf 	; ...	      dest buffer
	push	@SBBufLen	; ...  size of ...
	push	lpSYSINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileString ; Return length in AX
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	and	ax,ax		; Wuzit found?
	jz	short GPPS_BlastErr ; Jump if not

; See if compares with SNDBLST2.DRV

	push	lpSNDBLST2	; Pass first ptr
	push	lpSBBuf 	; ...  second ...
	call	StrICmp 	; Compare 'em

	and	ax,ax		; Are they equal?
	jz	short GPPS_BlastExit ; Jump if so (note CF=0)
GPPS_BlastErr:
	stc			; Indicate no match
GPPS_BlastExit:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GPPS_Blast endp 		; End GPPS_Blast procedure
	NPPROC	FindBlaster -- Find Sound Blaster Driver
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if the sound blaster driver is present.

On exit:

CF	=	0 if found
	=	1 if not found

|

	REGSAVE <ax,cx,dx,di>	; Save registers

; Look for "wave"

	push	lpSBLine	; Pass destin ptr
	push	lpWave		; ...  source ...
	call	StrCpy		; Copy the "wave" line name

	call	GPPS_Blast	; Get the profile value
	jnc	short FindBlastExit ; Jump if it's a match (note CF=0)

; Look for "wave",nn

	mov	cx,100		; Get counter for 0-99 suffixes
	mov	ax,0		; Get initial value
	xor	dx,dx		; Initialize high-order word for DD2DEC
@@:
	lea	di,szSBLine[szWaveLen] ; Skip to end of suffix position
	mov	es:[di].EDD,0	; Ensure properly terminated

	push	@DEC_LEFT	; Mark as left-justified
	call	DD2DEC		; Convert (DX,AX) to decimal at ES:DI,
				; return with ES:DI ==> next char
	call	GPPS_Blast	; Get the profile value
	jnc	short FindBlastExit ; Jump if it's a match (note CF=0)

	inc	ax		; Skip to the next value

	loop	@B		; Jump if more values to check

; Look for "MIDI"

	push	lpSBLine	; Pass destin ptr
	push	lpMIDI		; ...  source ...
	call	StrCpy		; Copy the "wave" line name

	call	GPPS_Blast	; Get the profile value
	jnc	short FindBlastExit ; Jump if it's a match (note CF=0)

; Look for "MIDI",nn

	mov	cx,100		; Get counter for 0-99 suffixes
	mov	ax,0		; Get initial value
	xor	dx,dx		; Initialize high-order word for DD2DEC
@@:
	lea	di,szSBLine[szMIDILen] ; Skip to end of suffix position
	mov	es:[di].EDD,0	; Ensure properly terminated

	push	@DEC_LEFT	; Mark as left-justified
	call	DD2DEC		; Convert (DX,AX) to decimal at ES:DI
				; return with ES:DI ==> next char
	call	GPPS_Blast	; Get the profile value
	jnc	short FindBlastExit ; Jump if it's a match (note CF=0)

	inc	ax		; Skip to the next value

	loop	@B		; Jump if more values to check

	stc			; Indicate not found
FindBlastExit:
	REGREST <di,dx,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindBlaster endp		; End FindBlaster procedure
	NPPROC	UpdateDrivers -- Update "drivers=" Line In SYSTEM.INI [boot]
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Update "drivers" line in SYSTEM.INI [boot] section
Update [drivers] section in SYSTEM.INI
Update [Qualitas] section in SYSTEM.INI

On entry:

SS:SP	==>	UD_STR (after PUSH BP)

On exit:

CF	=	0 if successful
	=	1 if wrong state (if adding, already present
				   if deleting, not already present)
non-BP GP registers and ES destroyed

|

UD_STR	struc

	dw	?		; 00:  Caller's BP
	dw	?		; 02:  ...	IP
UD_FLAG dw	?		; 04:  TRUE or FALSE

UD_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

; Get current "drivers=" line from [boot] section...

	push	lpBootSect	; Pass ptr to section name
	push	lpLineName	; ...	      line name
	push	lpDefValue	; ...	      default string (empty)
	push	lpStrBuf1	; ...	      dest buffer
	push	@StrBufLen	; ...  size of ...
	push	lpSysINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileString ; Return length in AX
	assume	es:nothing	; Tell the assembler about it

	mov	ax,ds		; Copy seg DGROUP
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Search for the driver name in list of drivers

	push	offset DGROUP:szDrvrName ; Pass offset of driver to find
	push	szDrvrNameLen	; Pass length of ...
	call	FindDriver	; Search for the driver, returning SI = offset

	cmp	DGROUP:[si].LO,0 ; Did we find the driver?
	je	short UpdateDriversStrDone1 ; Jump if not

; Regardless of whether we're here to add or delete the driver, if it's
; already in the "drivers=" line, we need to delete it in case it's not
; the first driver in sequence.

; Delete the driver from the "drivers=" line
; SI = index in szStrbuf1 of our driver

; Delete the driver from the line by copying the text downwards

	mov	di,si		; ES:DI ==> destin driver name in buffer
	add	si,szDrvrNameLen ; DS:SI ==> source offset in buffer

; DS:SI ==> end of driver name
; If there's a trailing blank there, skip over it

	cmp	DGROUP:[si].LO,' ' ; Izit a trailing blank?
	jne	short @F	; Jump if not

	inc	si		; Skip over it
@@:

; Find the length of the move

	push	di		; Save for a moment

	mov	di,si		; ES:DI ==> source offset
	mov	cx,-1		; We know it's there
	mov	al,0		; String terminator
  repne scas	es:[di].LO	; Search for the end
	neg	cx		; Subtract from 64K
	dec	cx		; Less one for initial -1

	pop	di		; Restore

	cld			; String ops forwardly
    rep movs	szStrBuf1[di],szStrBuf1[si] ; Copy down over driver name

	push	es		; Keep W's grubby hands away from

	push	lpBootSect	; Pass ptr to section name
	push	lpLineName	; ...	      line name
	push	lpStrBuf1	; ...	      deleted line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it
UpdateDriversStrDone1:

; Add or delete the driver as requested

	cmp	[bp].UD_FLAG,TRUE ; Should we add the driver?
	je	near ptr UpdateDriversAdd ; Jump if so

; Delete the entry in the [drivers] section

	push	es		; Keep W's grubby hands away from

	push	lpDrvrSect	; Pass ptr to section name
	push	lpDrvrNam2	; ...	      line name
	PUSHD	0		; ...	      delete the line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

; Delete the entry in the [boot.description] section

	push	lpBootDescSect	; Pass ptr to section name
	push	lpDrvrNam2	; ...	      line name
	PUSHD	0		; ...	      delete the line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	clc			; Mark as successful

	jmp	UpdateDriversExit ; Join common exit code

UpdateDriversAdd:

COMMENT|

When GOAHEAD.DRV loads before MMSYSTEM.DLL and that driver further
loads an early Sound Blaster driver (SNDBLST2.DRV which ships with
Windows), there is an incompatibility (no sound).  When Go Ahead is
loaded first, it sucks up all low DOS, and so fixed memory is always
allocated in extended memory.  When the Sound Blaster driver is
loaded, it GlobalAlloc()s fixed memory and fails if the base linear
address if >= 16MB which is the case with Go Ahead.  Of course the
driver should be checking for the PHYSICAL address >= 16MB, but that
detail escaped them.

Because of this, we need to install our driver after MMSYSTEM.DLL
under certain curcumstances, which works around this problem.  Also,
to handle future cases, the following algorithm is used:

1.  If there is a "LoadAfter=" line in the [Go Ahead - General]
    section of QMAX.INI, or

2.  If SNDBLST2.DRV is present in the [Drivers] section of SYSTEM.INI
    for any of the keywords "wave=", "wavenn=" (where nn can range
    from 0 to 99), "midi=", "midinn=" (nn has the same range),

then we load our driver after the file named in the "LoadAfter=" line
in the [Go Ahead - General] section of QMAX.INI or "mmsystem.dll" if
there is no "LoadAfter=" line.

|

; See if there is a "LoadAfter=" line

	push	es		; Keep W's grubby hands away from

	push	lpGenSect	; Pass ptr to section name
	push	lpAfterLine	; ...	      line name
	push	lpDefValue	; ...	      default string (empty)
	push	lpAfterBuf	; ...	      dest buffer
	push	@AfterBufLen	; ...  size of ...
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileString ; Return length in AX
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	lea	si,szStrBuf1	; DS:SI ==> "drivers=" line

	and	ax,ax		; Did it succeed?
	jnz	short @F	; Jump if so

	call	FindBlaster	; See if SNDBLST2.DRV is present
	jc	short UpdateDriversAdd1 ; Jump if not found

; Use default value for "LoadAfter=" line

	push	lpAfterBuf	; Pass destin ptr
	push	lpAfterDef	; ...  source ...
	call	StrCpy		; Copy the default "LoadAfter=" value

	mov	ax,szAfterDefLen ; Get length of default value
@@:

; If we're to place our driver after a specific driver, find it now

	push	offset DGROUP:szAfterBuf ; Pass offset of driver to find
	push	ax		; Pass length of ...
	call	FindDriver	; Search for the driver, returning SI = offset

	mov	bx,si		; Copy in case found
	lea	si,szStrBuf1	; DS:SI ==> "drivers=" line

	cmp	DGROUP:[bx].LO,0 ; Did we find it?
	je	short UpdateDriversAdd1 ; Jump if not

; Skip over the found driver

	mov	si,bx		; Restore
@@:
	lods	DGROUP:[si].LO	; Get next char

	cmp	al,' '          ; Are we past it?
	je	short @F	; Jump if so

	cmp	al,0		; Are we past it?
	jne	short @B	; Jump if not

	mov	ds:[si-1].ELO,' ' ; End the line with ' ',0
@@:
UpdateDriversAdd1:

; Insert our driver at DS:SI

; Copy the contents of StrBuf1 below this point to StrBuf2

	mov	ax,si		; Copy current offset
	sub	ax,offset DGROUP:szStrBuf1 ; Less start of buffer
	lea	di,szStrBuf2	; Get start of buffer

	push	ds		; Pass destin segment
	push	di		; ...	      offset
	push	lpStrBuf1	; ...  source ptr
	push	ax		; ...  length to copy
	call	StrNCpy 	; Insert it, return copy length in AX

; Copy our driver name

	add	di,ax		; Skip over length copied

	push	ds		; Pass destin segment
	push	di		; ...	      offset
	push	lpDrvrName	; Pass source ptr
	push	szDrvrNameLen+1 ; Pass length to copy (including trailing blank)
	call	StrNCpy 	; Copy our driver name, return copy length in AX

; Copy the rest of the line

	add	di,ax		; Skip over length copied

	push	ds		; Pass destin segment
	push	di		; ...	      offset
	push	ds		; Pass source segment
	push	si		; ...	      offset
	call	StrCpy		; Copy the line after the found driver

; Write out the new line

	push	es		; Keep W's grubby hands away from

	push	lpBootSect	; Pass ptr to section name
	push	lpLineName	; ...	      line name
	push	lpStrBuf2	; ...	      new "drivers=" line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

; Add the entry in the [drivers] section

	push	lpDrvrSect	; Pass ptr to section name
	push	lpDrvrNam2	; ...	      line name
	push	lpDrvrValue	; ...	      add the line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

; Add the entry in the [boot.description] section

	push	lpBootDescSect	; Pass ptr to section name
	push	lpDrvrNam2	; ...	      line name
	push	lpBootDesc	; ...	      add the line
	push	lpSysINIFile	; ...	      .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	clc			; Mark as successful

	jmp	short UpdateDriversExit ; Join common exit code

UpdateDriversErr:
	stc			; Mark as wrong state
UpdateDriversExit:
	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UpdateDrivers endp		; End UpdateDrivers procedure

_TEXT	ends			; End _TEXT segment

	END	LibMain 	; End GDADRV Module
