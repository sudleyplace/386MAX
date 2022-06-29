;' $Header:   P:/PVCS/MAX/INC/WINSTR.INV   1.3   15 Jun 1998 15:59:52   BOB  $
;
; WINSTR.INC
;
; Windows structures and equates
;


GH32_STR struc			; Global Heap

	dw	?		; Set to non-zero enable heap checking
	dw	?		; Set to non-zero to prevent heap compaction
GH32_GHCNT dw	?		; # entries in the global heap
GH32_OFF1ST dd	?		; Offset of 1st Global Arena

; There's more

GH32_STR ends


GA32_STR struc			; Global heap entry

GA32Next dd	?		; Next Global Arena
GA32Prev dd	?		; Prev ...
GA32Base dd	?		; Base address
GA32Size dd	?		; Block size in bytes
GA32Handle dw	?		; Handle
GA32Owner dw	?		; Owner (see GA32Ownerxxx for special values)

; There's more

GA32_STR ends

@GA32OwnerSentinel equ -1	; First and last owner entry
@GA32OwnerDPMI	   equ -4	; Allocated from DPMI


@MPI_SIG equ	'TP'            ; MakeProcInstance signature
@TDB_SIG equ	'DT'            ; TDB signature

TDB_STR struc			; Task Database

TDB_NEXT dw	?		; 00:  Selector of next task (0=end)
TDB_STKVEC dd	?		; 02:  SS:SP of the task when last switched away from
TDB_NEVENTS dw	?		; 06:  # events waiting for tthe task
TDB_PRIORITY db ?		; 08:  Priority
	db	?		; 09:  Unused???
	dw	?		; 0A:  Unused???
TDB_SEL dw	?		; 0C:  This task's selector
	dw	?		; 0E:  Unused???
	dw	?		; 10:  Unused???
	dw	?		; 12:  Unused???
TDB_FLDCW dw	?		; 14:  80x87 control word
TDB_FLAGS dw	?		; 16:  Flags (See TDBF_xxx below)
TDB_ERRFL dw	?		; 18:  Error flags (See SEM_xxx below)
TDB_MINVER dw	?		; 1A:  Minimum version of Windows to run this task
TDB_DGR dw	?		; 1C:  Instance handle (DGROUP) for this task
TDB_MOD dw	?		; 1E:  Module handle for task
TDB_TMQ dw	?		; 20:  Selector for task message queue
TDB_PARENT dw	?		; 22:  Selector of TDB parent
TDB_ASHFL dw	?		; 24:  Flags for TDB_ASH
TDB_ASH dd	?		; 26:  Application Signal Handler address
TDB_USH dd	?		; 2A:  User Signal handler address
TDB_GDNH dd	?		; 2E:  GlobalDiscard() notification handler
TDB_INT00 dd	?		; 32:  Interrupt 00h address
TDB_INT02 dd	?		; 36:  ...	 02h ...
TDB_INT04 dd	?		; 3A:  ...	 04h ...
TDB_INT06 dd	?		; 3E:  ...	 06h ...
TDB_INT07 dd	?		; 42:  ...	 07h ...
TDB_INT3E dd	?		; 46:  ...	 3Eh ...
TDB_INT75 dd	?		; 4A:  ...	 75h ...
TDB_COMPFL dd	?		; 4E:  Application compatibility flags
TDB_TIBSEL dw	?		; 52:  Thread Information Block selector
TDB_LATDB dd	?		; 54:  Linear address of Thread Database
TDB_HTASK16 dw	?		; 58:  For Win16 tasks, DGROUP handle
	db	6 dup (?)	; 5A:  Unused???
TDB_PSPSEL dw	?		; 60:  Selector of PSP
TDB_DTA dd	?		; 62:  Ptr to DTA
TDB_CURDRV db	?		; 66:  Current drive of task + 80h (origin-80)
TDB_CURDIR db	65 dup (?)	; 67:  Current directory of task
	dw	?		; A8:  Unused???
TDB_HNEXT dw	?		; AA:  hTask to be scheduled next
TDB_DLLCHAIN dd ?		; AC:  Ptr to chain of referenced DLLs
TDB_CSALIAS dw	?		; B0:  Code selector alias
TDB_MPISEL dw	?		; B2:  Selector to additional MakeProcInstance thunks
TDB_MPISIG dw	@MPI_SIG	; B4:  'PT' signature for MakeProcInstance thunks
	dw	?		; B6:  Unused???
TDB_MPINEXT dw	?		; B8:  Next available MakeProcInstance thunk
TDB_MPITHUNKS db (7*8) dup (?)	; BA:  Space for up to seven MakeProcInstance thunks
TDB_MODNAME db	8 dup (?)	; F2:  ASCIIZ Module name for task, no terminating zero if full
TDB_TDBSIG dw	@TDB_SIG	; FA:  TDB signature
	dd	?		; FC:  Unused???
TDB_PSP db	100h dup ()	;100:  PSP

TDB_STR ends

TDBF_WINOLDAP equ	0001h
TDBF_NEWTASK  equ	0008h
TDBF_WIN32    equ	0010h

SEM_FAILCRITICALERRORS		equ 0001h
SEM_NOGPFAULTERRORBOX		equ 0002h
SEM_NOALIGNMENTFAULTEXCEPT	equ 0004h
SEM_NOOPENFILEERRORBOX		equ 8000h


@MOD_SIG equ	'EN'            ; Module signature

MOD_STR struc			; Module

MOD_MODSIG dw	@MOD_SIG	; 00:  Module signature
MOD_USECNT dw	?		; 02:  Usage count
MOD_NPENTRY dw	?		; 04:  Near ptr to entry table
MOD_NEXT dw	?		; 06:  Selector of next module (0=end)
MOD_NPSEGDRP dw ?		; 08:  Near ptr to segment table entry for DGROUP
MOD_NPLFI dw	?		; 0A:  Near ptr to load file info (LFIxxSTRUCT)
MOD_FLAGS dw	?		; 0C:  Module flags (based on NE flags)
MOD_LSEG  dw	?		; 0E:  Logical segment # of DGROUP (1-based)
MOD_IHEAP dw	?		; 10:  Initial local heap byte size
MOD_ISTACK dw	?		; 12:  Initial stack byte size
MOD_CSIP  dd	?		; 14:  Starting CS:IP
MOD_SSSP  dd	?		; 18:  Starting SS:SP
MOD_NSEGS dw	?		; 1C:  # segments in segment table
MOD_NMREF dw	?		; 1E:  # entries in module ref table
MOD_SNRNT dw	?		; 20:  Size of non-resident names table on disk
MOD_NPSEG dw	?		; 22:  Near ptr to segment table
MOD_NPRES dw	?		; 24:  Near ptr to resource table
MOD_NPRNAM dw	?		; 26:  Near ptr to resident name table
MOD_NPMREF dw	?		; 28:  Near ptr to module reference table
MOD_NPINAM dw	?		; 2A:  Near ptr to imported names table
MOD_ONRNT dd	?		; 2C:  File offset of non-resident name table
MOD_NMOVE dw	?		; 30:  # moveable entries in entry table
MOD_SHIFT dw	?		; 32:  Alignment shift count
MOD_TTFNT dw	?		; 34:  Set to 2 if True Type font
MOD_OSFLG db	?		; 36:  Operating system flags
MOD_OTHER db	?		; 37:  Other flags
MOD_SAME1 dw	?		; 38:  Same as offset 2Ah
MOD_SAME2 dw	?		; 3A:  Same as offset 2Ah except in KERNEL
MOD_SWAP  dw	?		; 3C:  Minimum swap area size for this module
MOD_EXPWV dw	?		; 3E:  Expected Windows version #
MOD_PE_RVA dd	?		; 40:  PE-only RVA of PE file
MOD_PE_BASE dd	?		; 44:  PE-only LA of PE file base
MOD_PE_RSRC dd	?		; 48:  PE-only LA of PE file resources

MOD_STR ends

MDBF_DLL	equ 8000h	; It's a DLL
MDBF_CALL_WEP	equ 4000h	; Call WEP on unload
MDBF_SELF_LOAD	equ 0800h	; Uses self-loading mechanism
MDBF_TEXTMODE	equ 0200h	; Console app
MDBF_FULLSCREEN equ 0100h	; Writes into video buffer
MDBF_PRELOAD	equ 0040h	; Load when module is loaded rather than when accessed
MDBF_WIN32	equ 0010h	; Win32 PE file
MDBF_AUTODATA	equ 0002h	; Each module gets separate DGROUP
MDBF_SINGLEDATA equ 0001h	; Single DGROUP for all instances


MDBF_DATA     equ 0001h 	; Set = Data segment, Clr = Code segment
MDBF_ITERATED equ 0008h 	; Contains run length encoded data
MDBF_MOVEABLE equ 0010h 	; Set = Moveable in linear memory, Clr = FIXED
MDBF_PRELOAD  equ 0040h 	; Load when module is loaded rather than when accessed
MDBF_RELOC    equ 0100h 	; Contains relocation data
MDBF_DISCARD  equ 1000h 	; Discardable
MDBF_32BIT    equ 2000h 	; 32-bit code segment


LFI32STRUCT struc

LFI32_cBytes	 dw ?		; 00:  Length of data (not counting trailing 0
				;      in path name)
LFI32_fFixedDisk db ?		; 02:  1 iff on fixed media
LFI32_nErrCode	 dw ?		; 03:  Error code
LFI32_FileDate	 dw ?		; 05:  File data in MS-DOS format
LFI32_FileTime	 dw ?		; 07:  File time ...
LFI32_szPathName db 128 dup (?) ; 09:  File name in ASCIIZ format

LFI32STRUCT ends


LFI16STRUCT struc

LFI16_cBytes	 db ?		; 00:  Length of data (not counting trailing 0
				;      in path name)
LFI16_fFixedDisk db ?		; 01:  1 iff on fixed media
LFI16_nErrCode	 dw ?		; 02:  Error code
LFI16_FileDate	 dw ?		; 04:  File data in MS-DOS format
LFI16_FileTime	 dw ?		; 06:  File time ...
LFI16_szPathName db 128 dup (?) ; 08:  File name in ASCIIZ format

LFI16STRUCT ends




; PE file structure

@PE_SIG equ	'EP'            ; PE file signature


