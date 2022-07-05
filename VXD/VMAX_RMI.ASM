;'$Header:   P:/PVCS/MAX/VXD/VMAX_RMI.ASV   1.1   29 Sep 1995 15:36:54   BOB  $
	 title	 VMAX_RMI -- Real Mode Initialization for the 386MAX VxD
	 page	 78,130
	 name	 VMAX_RMI

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

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC	; From the standard Qualitas include library
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include OPCODES.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include MAXDEV.INC
	 include MAC.INC
	 include DEVDRV.INC
	 include ROMSEG.INC	; For adapter ROMs
	 include XMS.INC
	 include VCPI.INC
	 include EMMCALL.INC	; For EMS disk cache presence detection
	 include VIDCALL.INC

	 include QMAX_CMD.INC	; From QMAX source code
	 include QMAX_CM2.INC
	 include QMAX_CTL.INC
	 include QMAX_DBG.INC
	 include QMAXWIN3.INC
	 include EMM2CALL.INC
	 include LOAD_SEG.INC

	 include BREAK.INC
	 include VMAX.INC	; Local include files
	 include VMAX_UPD.INC
	 include VMAX_VID.INC
	 include VMAXSINI.INC

	 include VERSION.INC	; Specific to the VxD
.list

	 page
PSPSEG	 segment use16 dword at 0 ; Start PSPSEG segment

	 include PSP.INC	; Define symbols for PSP

PSPSEG	 ends			; End PSPSEG segment

	 page
VxD_REAL_INIT_SEG		; Start _RCODE segment
	 assume  cs:_RCODE, ds:nothing, es:nothing, ss:nothing

	 extrn	 RMI_UPD:near	; VMAX_UPD.ASM
	 extrn	 RMI_TOHEX:near ; VMAX_DBG.ASM

ifdef @DEBUG
	 extrn	 RMI_TODEC:near ; VMAX_DBG.ASM
endif				; IFDEF @DEBUG

ifdef @DEBUG
	 extrn	 MSG_IMPORT_NULL:byte
	 extrn	 MSG_IMPORT_INFO:byte
	 extrn	 MSG_IMPORT_INFO0:byte
	 extrn	 MSG_IMPORT_INFO1:byte
	 extrn	 MSG_IMPORT_INFO2:byte

	 extrn	 MSG_IMPORT_OPEN:byte
	 extrn	 MSG_IMPORT_IOCTL1:byte
	 extrn	 MSG_IMPORT_IOCTL2:byte
	 extrn	 MSG_IMPORT_IOCTL3:byte
	 extrn	 MSG_IMPORT_IOCTL4:byte
	 extrn	 MSG_IMPORT_NOTCHR:byte
endif				; IFDEF @DEBUG

	 extrn	 MSG_PSWD:byte
	 extrn	 MSG_CHKENV_BOV:byte
	 extrn	 MSG_EMSDC:byte
	 extrn	 MSG_EMSDC_BOV:byte
	 extrn	 MSG_INT67:byte, MSG_INT67_H:byte
	 extrn	 MSG_NOKRNL:byte
	 extrn	 MSG_SMART_SNS:byte
	 extrn	 MSG_SMART_BOV:byte
	 extrn	 MSG_SMART_SWD:byte
	 extrn	 MSG_16M_NONSUP:byte
	 extrn	 MSG_16M_NOXRAM:byte
	 extrn	 MSG_16M_REDUCE:byte
	 extrn	 MSG_RMI:byte
	 extrn	 MSG_DUP_DEVICE:byte
	 extrn	 MSG_NOMAX:byte
	 extrn	 MSG_BADVER:byte
	 extrn	 MSG_PAK:byte
	 extrn	 MSG_PAKORESC:byte
	 extrn	 MSG_CRLF:byte
	 extrn	 MSG_NOMAX:byte, MSG_BADVER:byte
	 extrn	 MSG_GETREF:byte, MSG_PUTREF:byte

ifdef @DOSMAX
	 extrn	 MSG_NOSTACKS:byte
endif					; IFDEF @DOSMAX

	 extrn	 DEVNAME_MAX:byte

	 include VMAX_RMI.INC
	 public  RMI_FLAG
RMI_FLAG dw	 0		; Flags for real mode init

;	 include QMAXINFO.INC
.xlist
	 include QMAXINFO.INC
.list
	 public  INFO_CTL, INFO
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>

PORT67	 equ	 INFO.INFO_P67		; I/O port for EMMOUT macro
LOWSIZE  equ	 INFO.INFO_LOW		;

;	 include WIN3PAGE.INC
.xlist
	 include WIN3PAGE.INC
.list
	 public  PAGING_IMPORT, @PAGING_IMPORT_L
PAGING_IMPORT	 EMM_Import_IOCTL_Data <>
@PAGING_IMPORT_L equ $-PAGING_IMPORT ; Length of above structure

@PAGING_IMPORT_INFO equ 1	; Return import information

	 public  EMMNAME
EMMNAME  db	 'EMMXXXX0', 0  ; Name to open EMS device driver

	 public  IMPORT_VER, IMPORT_PTR
IMPORT_VER dw	 0		; Version # of paging import
IMPORT_PTR dd	 0		; Physical address of paging import structure

	 public  DEV_HNDL
DEV_HNDL dw	 ?		; DOS file handle for device IOCTL calls

	 public  QMAX_DSHI
QMAX_DSHI dw	 ?		; Segment of QMAX in high DOS

	 public  QMAX_VER
QMAX_VER  dw	 ?		; QMAX.SYS version #

	 public  WIN386_VER
WIN386_VER	 dw	?	; AX upon entry to real mode init code

	 public  LOADER_SVC
LOADER_SVC	 dd	?	; FAR CALL vector to loader services

	 public  RMI_BX
RMI_BX	 dw	 ?		; BX upon entry to real mode init code

	 public  REFDATA_LEN, REFDATA_VER
REFDATA_LEN dw	 ?		; Length of reference data structure
REFDATA_VER dw	 ?		; Version # of reference data structure

	 public  REF_DATA_PHYS, REF_DATA_LIN
REF_DATA_PHYS	 dd	?	; 32-bit physical address of reference data
				; EDX upon entry to real mode init code
REF_DATA_LIN	 dd	?	; 32-bit linear address of reference data ...
				; ... under QMAX's GDT

	 public  RMI_REF_DATA
RMI_REF_DATA	 REF_DATA_STR <> ; Local buffer for reference data

	 public  MAXEMS_0, MAXEMS_4
MAXEMS_0	 dd	?	; 1st 4 bytes of QMAX's INT 67h code
MAXEMS_4	 db	?	; Last byte of 5 saved from above

	 public  QMAX_INT67
QMAX_INT67	 dd	?	; Original INT 67h handler in QMAX.SYS

	 public  INT67_FUNC
INT67_FUNC	 dw	?	; Last INT 67h AX value

	 public  XMS_VEC
XMS_VEC 	 dd	?	; FAR CALL vector to XMS provider

; Busmaster and SMARTDRV stuff

BABE	 equ	 0BABEh 		; SMARTDRV 4 return code
@4409_REMOTE	 equ	1000h		; Bit 12 indicates drive is remote

@SMARTDRV_WARNINGS	equ	0	; Disable mild warnings

	 public  ENVNAM_BM,ENVSTR_VDS
ENVNAM_BM	 db	'BUSMASTER', 0  ; Overrides for busmaster checking
ENVSTR_VDS	 db	'VDS', 0        ; Valid string for above

	 public  DEVNAME_SMART,FILENAME_SMART,SMART_IOCTL
DEVNAME_SMART	 db	'SMARTAAR', 0   ; Name for OPEN and IOCTL
FILENAME_SMART	 db	'SMARTDRV.SYS'  ; Filename for LSEG scan
SMART_IOCTL	 dw	?		; SMARTAAR device IOCTL bits

;	 include SMARTDRV.INC	; From the Windows DDK
.xlist
	 include SMARTDRV.INC	; From the Windows DDK
.list
SMART_INFO	 SD_IOCTL_Read <>
@SMART_INFO_L	 equ	 size SD_IOCTL_Read

; 'Video Device Conflict' stuff

@PSTATCOLR	 equ	3DAh	; Status register
@PSTATMONO	 equ	3BAh	; ...
@PATTREGA	 equ	3C0h	; Attribute register
@PMISCVGAIN	 equ	3CCh	; VGA read misc. output

	 public  STR_PARADISE
STR_PARADISE	 db	'PARADISE'
@STR_PARADISE_L  equ	$-STR_PARADISE

	 public  STR_WDIGITAL
STR_WDIGITAL	 db	'WESTERN DIGITAL'
@STR_WDIGITAL_L  equ	$-STR_WDIGITAL


; EMS disk caching stuff

	 public  ENVNAM_EC,ENVSTR_OK
ENVNAM_EC	 db	'EMSCACHE', 0   ; Overrides for EMS disk caching
ENVSTR_OK	 db	'OK', 0         ; Valid string for above

; Real mode debugging environment variable and its legal options

	 public  ENVNAM_MAXVXD,ENVSTR_DEBUG
ENVNAM_MAXVXD	 db	'MAXVXD', 0     ; Enables real mode debugging features
ENVSTR_DEBUG	 db	'DEBUG', 0      ; Enables full real-mode debugging

; Strings used with the loader services to read SYSTEM.INI in Windows 3.1

; The following name can't be public to avoid a linker conflict with upstairs
STR_QUALITAS	 db	'QUALITAS', 0   ; SYSTEM.INI section

	 public  STR_RMBRK,LCL_DOSMAX_FLAG
;;;;;;;  public  STR_DOSMAX		; Conflicts with VMAX_SVM.ASM
STR_RMBRK	 db	'REALMODEBREAK', 0      ; SYSTEM.INI keyname
STR_DOSMAX	 db	'DOSMAX', 0     ; SYSTEM.INI keyname

LCL_DOSMAX_FLAG  db	1		; Temporary DOSMAX status flag
					; Default=ON

; Environment variable for Windows startup directory

	 public  ENVNAM_WINDIR,ENVNAM_PATH
ENVNAM_WINDIR	 db	'windir', 0     ; Must be in lower case!
ENVNAM_PATH	 db	'PATH', 0       ; PATH environment variable

	 public  SYSINI_FILE
SYSINI_FILE	 db	'\SYSTEM.INI', 0
@SYSINI_FILE_L	 equ	$-SYSINI_FILE	; Length of above name for REP MOVSB

	 public  SYSTEM_PATH
SYSTEM_PATH	 db	'\SYSTEM'       ; Sub-directory under 'windir'
@SYSTEM_PATH_L	 equ	$-SYSTEM_PATH	; Length of above name for REP MOVSB

	 public  KRNL386_FILE
KRNL386_FILE	 db	'\KRNL386.EXE', 0 ; File important to enhanced mode
@KRNL386_FILE_L  equ	$-KRNL386_FILE	; Length of above name for REP MOVSB

	 public  STR_386ENH
STR_386ENH	 db	'[386Enh]'      ; Section heading in SYSTEM.INI
@STR_386ENH_LEN  equ	$-STR_386ENH	; Length of above string

	 public  STR_NETHEAPSIZE
STR_NETHEAPSIZE  db	'NETHEAPSIZE='  ; SYSTEM.INI cookie for NETBIOS
@STR_NETHEAPSIZE_LEN equ $-STR_NETHEAPSIZE ; Length of above string

	 public  STR_VIRTUALHIGHDOS
STR_VIRTUALHIGHDOS db	'VIRTUALHIGHDOS=' ; SYSTEM.INI cookie for 386MAX
@STR_VIRTUALHIGHDOS_LEN equ $-STR_VIRTUALHIGHDOS ; Length of above string

	 public  PATH_BUF,PATH_BUF_PTR
PATH_BUF	 db	128 dup (?)	; Buffer for filespecs
PATH_BUF_PTR	 dw	?		; ==> within above filespec buffer

		 public LINEBUF
@LINEBUF_L	 equ	128
LINEBUF 	 db	@LINEBUF_L dup (?) ; Buffer for RMI_GETLINE
					; This buffer is also used for the
					; output of TRUENAME an must be at
					; least _MAX_PATH (128) chars

; Buffer used during EMS disk cache tests
	 public  EMS_BUF
EMS_BUF  db	 512 dup (?)	; Place to test disk reads for EMS usage
@EMS_BUF_L equ	 $-EMS_BUF	; Length of above buffer

; Buffer to hold page table entries during PHYS2LIN

	 align	 4
	 public  PTE_BUF,PTE_BUFZ,PTE_OFFSET
@PTE_BUFN equ	 64		; # of PTEs buffer will hold
@PTE_BUFL equ	 @PTE_BUFN*4	; Size in bytes of buffer
PTE_BUF  dd	 @PTE_BUFN dup (?) ; Place to hold PTEs for RMI_PHYS2LIN
PTE_BUFZ dw	 ?		; Offset to end of buffer

PTE_OFFSET dw	 ?		; Offset within PTEs of last @EMM2_GETPTE

	 public  MIN_BUF_PAGES,MIN_MAP_PAGES,PRIVATE_MAP_PAGES
MIN_BUF_PAGES	 dw	?	; AL on entry to V86MMGR_Set_Mapping_Info
MIN_MAP_PAGES	 dw	?	; BH on entry to V86MMGR_Set_Mapping_Info
PRIVATE_MAP_PAGES dw	?	; BL on entry to V86MMGR_Set_Mapping_Info

	 public  VIRTUALHIGHDOS
VIRTUALHIGHDOS	 dw	0	; Default VIRTUALHIGHDOS= value (in K)

	 public  NETHEAPSIZE,NETBIOS_BLK
NETHEAPSIZE	 dw	12	; Default NETHEAPSIZE= value (in K)
NETBIOS_BLK	 db	7Fh	; NETBIOS command code (invalid command)
		 db	3Fh dup (0) ; Remainder of NETBIOS control block
	 page
BeginProc Real_Mode_Hook,PUBLIC
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

   Real_Mode_Hook

DESCRIPTION:
      This routine is called from the Real_Mode_Init routine of the Loadhi
      VxD and lets the LIM/UMBulator specific part of the VxD do it's own real
      mode initialization stuff, and set whether to load the device or not.

ENTRY:
	ALL REGISTERS SETUP AS FOR A REAL, REAL_MODE_INIT call.

	AX  = Windows version (AH=Major, AL=Minor)
	BX  = Flags
		NOTE that the caller of this has checked that the
		     Loading_From_INT2F bit is set and the
		     Duplicate_From_INT2F and Duplicate_Device_ID
		     bits are both clear
	EDX = Reference data specified by INT 2Fh load
	EDX = Reference data passed to Windows by QMAX.WIN3_CB
		This is actually a physical address of the
		reference data structure defined in QMAXWIN3.INC
	SI  = Segment of WIN386 environment strings
	ECX = Segment:offset of assistance API (3.10 only)

EXIT:
      Setup EDX, BX, and SI registers appropriately.

      AX should have the Device_Load_Ok return code.

	BX  = pointer to excluded pages list (0 if none)
	SI  = pointer to instance data list (0 if none)
	EDX = Reference data to pass to protected mode portion of VxD
	EDX = Reference data passed to Windows by QMAX.WIN3_CB
	AX  = Real mode return value, one of:

		Device_Load_Ok
		Abort_Device_Load
		Abort_Win386_Load

	      and optionally, No_Fail_Message bit set if no abort massage is
	      wanted. NOTE: PLEASE TELL THE USER WHY WE CAN'T START Windows!
	      If you return AX = (No_Fail_Message + Abort_Win386_Load) you
	      MUST have called DOS (use call AH = 09h) to put up an error
	      message yourself. Please do not abort the WIN386 load without
	      telling the USER (and our, your's and MS's, product support)
	      why the load was aborted!

   USES:
	AX, BX, DX, SI, Flags

|

; QMAX passes a pointer to the WIN3_REF_DATA structure to Windows via the
; 1605 startup chain.  We must preserve it and return it to Windows again
; Actually, with the advent of the retrofit code, it may be updated on the
; way out to point to a new (modified) copy of the reference data structure.

	 mov	 WIN386_VER,ax	; Save WIN386 version #
	 mov	 RMI_BX,bx	; Save flags contained in BX for later
	 mov	 LOADER_SVC,ecx ; Save ptr to loader service entry point
	 mov	 REF_DATA_PHYS,edx ; Save for use later on

	 mov	 RMI_FLAG,0	; Prime the flags

	 cmp	 WIN386_VER,030Ah	; Izit Windows 3.1 or better?
	 jb	 short XWIN31		; Skip if not

	 mov	 ax,0003h		; Get_Profile_Boolean
	 sub	 ecx,ecx		; Default value
	 lea	 si,STR_QUALITAS	; DS:SI ==> 'QUALITAS', 0
	 lea	 di,STR_RMBRK		; DS:DI ==> 'RealModeBreak', 0
	 call	 LOADER_SVC		; WIN386 loader services

	 or	 ecx,ecx		; RealModeBreak=ON?
	 jz	 short @F		; Skip if not

	 int	 1			; Call somebody's debugger
@@:

ifdef @DOSMAX				; Only check if DOSMAX version of VxD

; Check for MONO machine and set default for Get_Profile_boolean

	 mov	 ecx,1		; Default value

	 mov	 al,0		; Code to read the DCC
	 VIDCALL @GSTDCC	; Return the DCC in (BL,BH)
				; BL = active display code
				; BH = alternate display code
				; AL = 1Ah if supported

	 cmp	 al,1ah 	; Is this call supported?
	 jne	 DCC_NOSUP	; No, . . .

	 cmp	 bl,02h 	; Izit color CGA?
	 je	 short @F	; Jump if so

	 cmp	 bl,04h 	; Izit color EGA?
	 je	 short @F	; Jump if so

	 cmp	 bl,06h 	; Izit color PGC?
	 je	 short @F	; Jump if so

	 cmp	 bl,08h 	; Izit analog color?
	 je	 short @F	; Jump if so

	 cmp	 bl,0Ch 	; Izit analog color?
	 je	 short @F	; Jump if so

DCC_NOSUP:
	 xor	 cl,cl		; Clear ECX

@@:

; Check for DOSMAX, and set bit if equal to OFF (or what is left over from above)

	 mov	 ax,0003h		; Get_Profile_Boolean
	 lea	 si,STR_QUALITAS	; DS:SI ==> 'QUALITAS', 0
	 lea	 di,STR_DOSMAX		; DS:DI ==> 'DOSMAX', 0
	 call	 LOADER_SVC		; WIN386 loader services

	 mov	 LCL_DOSMAX_FLAG,cl	; Save result for comparison later


endif	; @DOSMAX

XWIN31:

	 call	 RMI_SYSINI_FLAGS ; Get SYSTEM.INI switches and set flags

	 call	 RMI_CHK_MAXVXD ; Process MAXVXD environment variable
	 jc	 RMI_ERRXIT2	; Bug out if they user requested it
				; Fail the Windows startup

	 BREAK	 RMI_FLAG,@RMI_DEBUG	; Call a debugger if they want it

	 call	 RMI_CHK_DUPVXD 	; Check for duplicate VxD installation
	 jc	 RMI_ERRXIT		; Fail Windows startup

	 call	 RMI_MAX_OPEN		; Open 386MAX$$, read QMAXINFO, etc.
	 jc	 RMI_ERRXIT		; Bug out if it failed

COMMENT|

Getting the correct reference data length is quite tricky due to poor planning
from day one and the need to retrofit Windows support into old versions.

RMI_REFDATA sets the length of the reference data for versions of 386MAX up
to but not including 6.03.  Up to the 6.02a length is copied down.  For
reference data structure versions 6.03 and up, we reset the length to that of
6.03 and copy the data down again.  In this way we get the exact length of
the structure.	Then, on the third block move, we've got it all.

|

	 call	 RMI_REFDATA_LEN	; Get REFDATA_LEN from QMAX_VER

	 call	 RMI_GET_REFDATA	; Copy reference data from upstairs
	 jc	 RMI_ERRXIT		; Bug out if it failed

	 cmp	 RMI_REF_DATA.REF_STRUC_VER,603h ; Is it 6.03 or later?
	 jb	 short @F		; Skip if not

	 mov	 REFDATA_LEN,@REF_LEN603 ; Assume length for 6.03

	 call	 RMI_GET_REFDATA	; Copy reference data from upstairs
	 jc	 RMI_ERRXIT	; Bug out if it failed

	 mov	 ax,RMI_REF_DATA.REF_STRUC_LEN ; Actual length from structure
	 mov	 REFDATA_LEN,ax 	; Save length for others

	 call	 RMI_GET_REFDATA	; Copy reference data from upstairs
	 jc	 RMI_ERRXIT	; Bug out if it failed
@@:
	 mov	 RMI_REF_DATA.REF_VIDFLAG,0 ; Clear out the VDD flags
	 mov	 RMI_REF_DATA.REF_UPDFLAG,0 ; Clear out the retrofit flags
	 mov	 RMI_REF_DATA.REF_R2PFLAG,0 ; Clear out real to prot flags

; Now that the reference data is settled, write in DOSMAX status
	 cmp	 LCL_DOSMAX_FLAG,0	; Izt disabled
	 jnz	 @F			; No, skip this
	 or	 RMI_REF_DATA.REF_R2PFLAG,@R2P_SHORT ; DOSMAX Disabled?
@@:

	 call	 RMI_REFDATA_VER	; Determine version of REF_DATA_STR

	 call	 RMI_GET_DOSVER 	; Place DOS version into reference data

	 call	 RMI_GET_PAGING_IMPORT	; Get GPIS pointer from QMAX.SYS

	 call	 RMI_ADJUST_REFDATA_PTR ; Get new location for the ref data

	 call	 RMI_CHK_16M	; Check on systems with 16 MB or more
				; RMI_FLAG,@RMI_FAIL set if we shouldn't start

; As of version 7, RMI_CHK_EMSDISK is called before the SMARTDRV and
; busmaster tests so we can use the drive letter on which we found KRNL386.EXE

	 call	 RMI_CHK_EMSDISK	; Check EMS-using disk caches
					; @RMI_FAIL set if we shouldn't start

	 call	 RMI_SMARTAAR	; Open SMARTDrive device and get IOCTL bits
				; IOCTL bit are used in the following call
	 call	 RMI_CHK_BM	; Check on busmaster & SMARTDRV problems
				; RMI_FLAG,@RMI_FAIL set if we shouldn't start

ifdef @VGASWAP
	 call	 RMI_CHK_FLEXROM	; Set flag if VGASWAP is in effect
endif					; IFDEF @VGASWAP

	 call	 RMI_CHK_VIDEO		; Set flags for pesky VGAs
					; @RMI_FAIL set if we shouldn't start
	 call	 RMI_FIX_VIDEO		; Fix problems w/ certain VGA adapters

	 call	 RMI_CALC_PAGES 	; Guess # of mapping pages for WIN386

	 call	 RMI_FIX_DRDOS		; Fiddle with XMS A20 for DR-DOS

	 call	 RMI_UPD		; Patch an older QMAX.SYS if needed
	 jc	 short RMI_ERRXIT	; Bug out if it failed

ifdef @DOSMAX
	 test	 RMI_REF_DATA.REF_R2PFLAG,@R2P_SHORT ; DOSMAX Disabled?
	 jnz	 @F			; Skip DOSMAX check if bit is set

	 call	 RMI_DOSMAX		; Check for DOSMAX problems
	 jc	 short RMI_ERRXIT	; Bug out if they wanted to quit

@@:
endif					; IFDEF @DOSMAX

; Test for errors in the preceding tests.  Warnings have already been displayed.

	 test	 RMI_FLAG,@RMI_FAIL ; Should we prevent Windows from starting?
	 jnz	 short RMI_ERRXIT ; Yes, so return with error

; Copy the (possibly modified) reference data back into extended memory

	 call	 RMI_PUT_REFDATA ; Copy reference data to extended memory
	 jc	 short RMI_ERRXIT ; Bug out if it failed

; Return a normal indication to LoadHi, and from there to WIN386.EXE

	 mov	 ax, Device_Load_Ok	; Normal return

	 jmp	 short RMI_XIT	; Rejoin common exit code

; Do the bit about 'Press any key to continue' and return to Windows

RMI_ERRXIT:
	 DOSCALL @STROUT,MSG_PAK ; Display 'press any key; Windows terminated'

	 mov	 al,@KEYIN	; Wait for a key w/o echo
	 DOSCALL @CKEYIN	; Clear keyboard input buffer and wait for a key
RMI_ERRXIT2:
	 DOSCALL @STROUT,MSG_CRLF ; Print CR and LF

; Indicate VxD failure with message already printed

	 mov	 ax,Abort_Win386_Load OR No_Fail_Message ; Fail Windows startup

; Return to LoadHi, and from there to WIN386.EXE

RMI_XIT:

; Restore the pointer to the WIN3_REF_DATA structure passed by QMAX

	 mov	 edx,REF_DATA_PHYS ; Reference data to protected mode

	 sub	 bx,bx		; No pages to exclude
	 sub	 si,si		; No instance items

	 ret			; Return to LoadHi and from there to WIN386.EXE

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc Real_Mode_Hook		; End Real_Mode_Hook procedure

	 page
BeginProc RMI_SHOW_BANNER,PUBLIC ; Display banner if it hasn't been already
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_SHOW_BANNER

DESCRIPTION:
	Display the banner and copyright information if it hasn't been already.

	Set a flag so this happen at most one time.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 test	 RMI_FLAG,@RMI_BANNER ; Did they already get the banner?
	 jnz	 short @F	; Don't print it twice

	 DOSCALL @STROUT,MSG_RMI ; Display version and build info
	 or	 RMI_FLAG,@RMI_BANNER ; Indicate it got printed
@@:
	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_SHOW_BANNER	; End RMI_SHOW_BANNER procedure

	 page
BeginProc RMI_CHK_MAXVXD,PUBLIC ; Process MAXVXD environment string
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_MAXVXD

DESCRIPTION:
	Search the MS-DOS envrionment strings for the 'MAXVXD=' variable.
	Set flags based on its contents.

	Show 'em the copyright banner if they've requested it.

	If they've requested it, print the list of valid SYSTEM.INI
	cookies and indicate which ones are present.

EXIT:
	Carry set if the user requested failing the Windows startup

|

	 REGSAVE <bx,cx,dx,si,di,es> ; Save caller's registers

	 lea	 si,ENVNAM_MAXVXD ; Get offset to "MAXVXD"
	 call	 RMI_GETENV	; Find it in the environment strings
	 assume  es:nothing	; Tell the assembler

; ES:DI ==> MAXVXD environment string.

	 jc	 short RCM_CLCXIT ; Exit with CLC if no MAXVXD= envir variable

; ES:DI ==> MAXVXD environment string.

	 lea	 si,ENVSTR_DEBUG ; Source of comparison
	 call	 RMI_CMPSBI	; Case insensitive REPE CMPSB

	 jne	 short @F	; Skip setting flag if not 'DEBUG'
	 or	 RMI_FLAG,@RMI_DEBUG+@RMI_PAK+@RMI_BANNER

	 DOSCALL @STROUT,MSG_RMI ; Display version and build info
@@:
	 call	 RMI_PAUSE	; Display 'press any key' and wait for key press
				; Carry indicates they hit ESCape
				; The set carry flag is returned to our caller
	 jmp	 short RCM_XIT	; Rejoin common exit code (CF significant)

; Return with carry clear indicating all is well

RCM_CLCXIT:
	 clc			; Indicate we found the MAXVXD= envir string

RCM_XIT:
	 REGREST <es,di,si,dx,cx,bx> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHK_MAXVXD 	; End RMI_CHK_MAXVXD procedure

	 page
BeginProc RMI_REFDATA_LEN,PUBLIC ; Determine length of reference data structure
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_REFDATA_LEN

DESCRIPTION:
    Determine length of the reference data structure, based upon the
    version # of the installed QMAX.SYS.

ENTRY:
	QMAX_VER contains the QMAX.SYS version #

|

	 REGSAVE <ax>		; Save caller's registers

	 mov	 ax,QMAX_VER	; Get QMAX.SYS version #

	 mov	 REFDATA_LEN,@REF_LEN601 ; Assume length for 6.01 & 6.02
	 cmp	 ax,601h	; Izit version 6.01 or 6.02?
	 jae	 short RRV_COM	; Rejoin common code if assumption is correct

	 mov	 REFDATA_LEN,@REF_LEN513 ; Assume length for 5.13 & 6.00
	 cmp	 ax,513h	; Izit version 5.13 or 6.00?
	 jae	 short RRV_COM	; Rejoin common code if assumption is correct

	 mov	 REFDATA_LEN,@REF_LEN512 ; Assume length for 5.12
	 cmp	 ax,512h	; Izit version 5.12?
	 je	 short RRV_COM	; Rejoin common code if assumption is correct

	 mov	 REFDATA_LEN,@REF_LEN511 ; Assume length for 5.11
	 cmp	 ax,511h	; Izit version 5.11?
	 je	 short RRV_COM	; Rejoin common code if assumption is correct

	 mov	 REFDATA_LEN,@REF_LEN510 ; Assume length for 5.10

RRV_COM:
	 REGREST <ax>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_REFDATA_LEN	; End RMI_REFDATA_LEN procedure

	 page
BeginProc RMI_REFDATA_VER,PUBLIC ; Determine version of reference data structure
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_REFDATA_VER

DESCRIPTION:
	Determine version # of the reference data structure

	if the installed QMAX.SYS is version 5.13 or later, take the
	reference data structure version # directly from the structure
	itself.  Otherwise, take if from QMAX.SYS.

ENTRY:
	QMAX_VER contains the QMAX.SYS version #

EXIT:
	REF_DATA_VER filled in with reference data structure version #

|

	 REGSAVE <ax,dx>	; Save caller's registers

; Figure out the reference data structure version

	 mov	 ax,RMI_REF_DATA.REF_STRUC_VER ; Assume it's 5.13 or above

	 cmp	 QMAX_VER,513h	; Izit QMAX 5.13 or later?
	 jae	 short @F	; Yes, so version was in REF_DATA_STR

; For QMAX versions 5.10, 5.11, and 5.12, the reference data structure
; version # is the same as the QMAX version #

	 mov	 ax,QMAX_VER	; Get minor version digits
	 mov	 RMI_REF_DATA.REF_STRUC_VER,ax ; Update reference data for PM

; Since REF_LOADSEG is filled in by EMM2_GOREALWIN3, we must copy it
; here before doing the PUT_REF_DATA

	 mov	 dx,INFO.INFO_LSEG ; Get segment of 386LOAD chain
	 mov	 RMI_REF_DATA.REF_LOADSEG,dx ; Save it in the local refdata
@@:
	 mov	 REFDATA_VER,ax ; Save reference data structure version #

	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_REFDATA_VER	; End RMI_REFDATA_VER procedure

	 page
BeginProc RMI_GET_PAGING_IMPORT,PUBLIC ; Get paging import spec data
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GET_PAGING_IMPORT

DESCRIPTION:
	Open the EMMXXXX0 device driver and ensure it's a character
	device driver.	Perform the IOCTL call to get the WIN386
	Paging Import Spec version # and physical pointer.

	The address of the structure is used to find a home to store the
	modified reference data if we're updating an old QMAX.SYS.
	This is only performed it QMAX.SYS is version 5.10 - 5.12.

	QMAX.SYS version 5.10 - 5.12 implements GPIS 1.00.
	QMAX.SYS version 5.13 and later supports GPIS 1.11.

ENTRY:
	QMAX_VER contains the QMAX.SYS version #

EXIT:
	IMPORT_PTR and IMPORT_VER filled in

|

	 cmp	 QMAX_VER,513h	; Izit QMAX 5.13 or later?
	 jae	 GPI_XIT2	; Skip all this if so

	 REGSAVE <eax,bx,cx,dx,di> ; Save caller's registers

	 mov	 DEV_HNDL,0	; Prime handle so we don't close unopened files

; Open the EMS device driver

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,EMMNAME ; Attempt to open EMS device
	 jnc	 short GPI_XWRN1 ; Skip error if it worked

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_OPEN ; Tell 'em the open failed
@@:
endif				; IFDEF @DEBUG
	 jmp	 GPI_NUL	; Rejoin common code

GPI_XWRN1:

; Ensure it's a character device driver

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jnc	 short GPI_XWRN2 ; Skip error if it worked

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_IOCTL1 ; Tell 'em the IOCTL failed
@@:
endif				; IFDEF @DEBUG
	 jmp	 GPI_NUL	; Rejoin common code

GPI_XWRN2:
	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short GPI_XWRN3 ; Skip error if so

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_NOTCHR ; Tell 'em the device is wrong
@@:
endif				; IFDEF @DEBUG
	 jmp	 GPI_NUL	; Rejoin common code

GPI_XWRN3:

; Get WIN386 Paging Import structure version and pointer

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,@PAGING_IMPORT_L ; CX = # bytes in INFO structure
	 mov	 PAGING_IMPORT.LO,@PAGING_IMPORT_INFO ; Mark as INFO transfer
	 DOSCALL @IOCTL2,PAGING_IMPORT ; Get IOCTL info into PAGING_IMPORT
	 jnc	 short GPI_XWRN4 ; Skip error if it worked

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_IOCTL2 ; Tell 'em the IOCTL failed
@@:
endif				; IFDEF @DEBUG
	 jmp	 GPI_NUL	; Rejoin common code

GPI_XWRN4:
	 cmp	 ax,@PAGING_IMPORT_L ; Did we get all 6 bytes?
	 je	 short GPI_XWRN5 ; Yup

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_IOCTL3 ; Tell 'em the IOCTL failed
@@:
endif				; IFDEF @DEBUG
	 jmp	 short GPI_NUL	; Rejoin common code

GPI_XWRN5:
	 mov	 ah,PAGING_IMPORT.EMM_Import_API_Version_Maj ; Major version #
	 mov	 al,PAGING_IMPORT.EMM_Import_API_Version_Min ; Minor version #
	 mov	 IMPORT_VER,ax	; Save

	 mov	 eax,PAGING_IMPORT.EMM_Import_Data_Phys_Ptr ; ==> import data
	 mov	 IMPORT_PTR,eax ; Save

;;;;;;	 mov	 eax,IMPORT_PTR ; Get physical address of paging import data
	 or	 ax,IMPORT_VER	; Include version # in test
	 jnz	 short GPI_XWRN6 ; Skip complaints if we got a non-zero address

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_IOCTL4 ; Tell 'em we got a zero address
@@:
endif				; IFDEF @DEBUG

	 jmp	 short GPI_NUL	; Try next method if the IOCTL scheme failed

GPI_XWRN6:

ifdef @DEBUG
	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

; Tell 'em the WIN386 Paging Import IOCTL info worked

	 mov	 al,PAGING_IMPORT.EMM_Import_API_Version_Maj ; Major version #
	 add	 al,'0'         ; Form ASCII digit
	 mov	 MSG_IMPORT_INFO0,al ; Save in message text

	 mov	 al,PAGING_IMPORT.EMM_Import_API_Version_Min ; Minor version #
	 sub	 ah,ah		; Convert version # to a word
	 mov	 cx,2		; Number of decimal digits desired
	 lea	 di,MSG_IMPORT_INFO1 ; ==> message text
	 call	 RMI_TODEC

	 mov	 eax,PAGING_IMPORT.EMM_Import_Data_Phys_Ptr ; ==> import data
	 mov	 cx,8		; Number of hex digits in physical address
	 lea	 di,MSG_IMPORT_INFO2 ; ==> message text
	 call	 RMI_TOHEX	; Format into message text

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_INFO ; Tell 'em about the paging import data
@@:
	 jmp	 short GPI_XIT	; Rejoin common code
endif				; IFDEF @DEBUG

; There was no WIN386 Paging Import data available via the IOCTL scheme
; Root around in QMAX.SYS itself to find the data

GPI_NUL:
ifdef @DEBUG
; Tell 'em there's no WIN386 Paging Import data

	 test	 RMI_FLAG,@RMI_SHOWINFO ; Are we showing info like this?
	 jz	 short @F	 ; Nope

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_IMPORT_NULL ; Tell 'em no paging import is present
@@:
endif				; IFDEF @DEBUG

	 push	 es		; Save

	 mov	 es,QMAX_DSHI	; Segment of QMAX.SYS in high DOS memory
	 assume  es:nothing	; Tell the assembler

; These offset are the same between 386MAX and BlueMAX

@EMM_IMPORT_PTR_510 equ 436h	; Offset in HICODE of EMM_IMPORT_PTR
@EMM_IMPORT_PTR_511 equ 432h	; Offset in HICODE of EMM_IMPORT_PTR
@EMM_IMPORT_PTR_512 equ 438h	; Offset in HICODE of EMM_IMPORT_PTR

; Get offset within QMAX.SYS of EMM_IMPORT_PTR based on the QMAX version #

	 mov	 ax,QMAX_VER	; Get version # of QMAX.SYS

	 cmp	 ax,510h	; Izit version 5.10?
	 jne	 short @F	; Nope

	 mov	 bx,@EMM_IMPORT_PTR_510 ; Save it's length

	 jmp	 short GPI_GOTOFF ; Rejoin common code

@@:
	 cmp	 ax,511h	; Izit version 5.11?
	 jne	 short @F	; Nope

	 mov	 bx,@EMM_IMPORT_PTR_511 ; Save it's length

	 jmp	 short GPI_GOTOFF ; Rejoin common code

@@:
	 cmp	 ax,512h	; Izit version 5.12?
	 jne	 short @F	; Nope

	 mov	 bx,@EMM_IMPORT_PTR_512 ; Save it's length

	 jmp	 short GPI_GOTOFF ; Rejoin common code

; We've got a system error condition here
; Use a zero for the IMPORT_PTR, to be tested later

@@:
	 sub	 eax,eax	; A handy NULL pointer

	 jmp	 short GPI_GOTOFF2 ; Rejoin common code

; ES:BX ==> EMM_IMPORT_PTR DWORD within QMAX.SYS

GPI_GOTOFF:
	 mov	 eax,es:[bx].EDD ; Get EMM_IMPORT_PTR from QMAX HICODE segment
GPI_GOTOFF2:
	 mov	 IMPORT_PTR,eax ; Save

	 mov	 IMPORT_VER,100h ; QMAX.SYS 5.10 - 5.12 supports GPIS 1.00

	 clc			; Indicate everything is normal
GPI_NUL2:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler

GPI_XIT:
	 mov	 bx,DEV_HNDL	; Get device handle
	 or	 bx,bx		; Izit open?
	 jz	 short @F	; Nope

	 DOSCALL @CLOSF2	; Close the device
@@:
	 REGREST <di,dx,cx,bx,eax> ; Restore caller's registers
GPI_XIT2:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GET_PAGING_IMPORT	; End RMI_GET_PAGING_IMPORT procedure

	 page
BeginProc RMI_ADJUST_REFDATA_PTR,PUBLIC ; Adjust the reference data physical pointer
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_ADJUST_REFDATA_PTR

DESCRIPTION:
	Move reference data physical pointer to a safe place in the
	WIN386 Paging Import Spec data if we're updating an older QMAX.SYS.
	The reference data structure in QMAX.SYS 5.13 is larger than
	in 5.10 - 5.12 and it needs a new home.

	During the original Windows support development effort,
	Bob left room in the WIN386 Paging Import Spec data area to
	transfer information about 256 free UMB areas.
	This was never used with Windows 3.0 or QMAX.SYS 5.10 - 5.12.

	QMAX.SYS 5.13, which supports Windows 3.10 and GPIS 1.11
	knows about these free UMB areas, but we still never use the
	fields.

	This leaves a very handy 1K block we can use for other purposes.

	Some of this procedure's code is copied from QMAX_SIZ.ASM.
	It is important that it match that code from 5.10 - 5.12.

	QMAX.SYS will inspect the reference data field, REF_MAX2VXD_CB,
	as it is a far pointer used to call protected mode QMAX.SYS
	code to support the 386UTIL services in a DOS VM.

	For this to continue to work, we must pass the original
	reference data address up to the protected mode code.
	VMAX.ASM/VMAX_UPD.ASM will update the far pointer in the
	original copy of the reference data.

ENTRY:
	REF_DATA_PHYS as passed by QMAX.SYS via the 1605 startup chain

EXIT:
	REF_DATA_PHYS updated to a new larger area

|

	 REGSAVE <ebx>		; Save caller's registers

; Save the original address in the new structure

	 mov	 ebx,REF_DATA_PHYS ; Physical address of reference data
				; Passed by QMAX.SYS via 1605 startup chain
	 mov	 RMI_REF_DATA.REF_OLDREF_PTR,ebx ; Save in structure for PM

; Adjust the physical address for the RMI_PUT_REFDATA routine if needed

	 cmp	 REFDATA_VER,513h ; Izit reference data version 5.13 or later?
	 jae	 short RARP_XIT ; Nothing to do if so

	 sub	 ebx,ebx	; Accumulator for offset of import data fields

; Add in
;	 size EMM_Import_Data	for static elements
;	 1			for EMM_Import_Hnd_Cnt

	 add	 bx,(size EMM_Import_Data)+1 ; Size for GPIS 1.00 - 1.11

; Add in (size EMM_Import_UMB_Map) bytes for each 16KB UMB
; As we don't know at this stage how many UMBs there'll be, we use a
; maximum value of (1024-640)/16.
; Note that this field is valid for Windows 3.10 or later only.

	 add	 bx,(1024-640/16)*(size EMM_Import_UMB_Map)
; N.B.	The above size calculation is incorrectly parenthesized.
; This matches the code in QMAX.SYS in those versions.

; Add in (size EMM_Import_Handle) bytes for each EMS handle
; As we don't know how many EMS handles will be in use, we use a
; maximum value of @MAXNHNDL+1

	 push	 eax		; Save for a moment

@MAXNHNDL equ	 255		; FIXME

	 mov	 eax,@MAXNHNDL+1 ; Get maximum # handles
	 imul	 eax,size EMM_Import_Handle
	 add	 bx,ax	; Add it in

	 pop	 eax		; Restore

; End of version 1.00 import data

; Add in 4 bytes for EMM_Import_INT67 value
; Add in 4	     EMM_Import_HMAAliasPhysPtr
; Add in 1	     EMM_Import_Free_Cnt
; Add in 1	     EMM_Import_xMS_Cnt
; Add in 1	     EMM_Import_FreeUMB_Cnt

	 add	 bx,4+4+1+1+1	; Add it in

; Add in EMM_Import_Free_Cnt * (size EMM_Import_FreeReg) bytes
; for EMM_Import_FreePhys.
; As we don't know how many regions there'll be, we use a
; maximum value of @MAX_FREE_REG.

	 public  @MAX_FREE_REG
@MAX_FREE_REG equ 16		; Maximum # free regions

	 add	 bx,@MAX_FREE_REG * (size EMM_Import_FreeReg)

; Add in EMM_Import_xMS_Cnt * (size EMM_Import_xMSHnd) bytes
; for EMM_Import_xMSHndA.
; As we don't know how many XMS handles will be allocated we use
; a maximum value of @MAX_XMSHNDL.

@MAX_XMSHNDL equ 256		; FIXME

	 add	 bx,@MAX_XMSHNDL * (size EMM_Import_xMSHnd)

; EBX is the offset from the start of the WIN386 Paging Import data area
; to the unused free UMB area

	 add	 ebx,IMPORT_PTR ; Add to the physical address of the import data

	 mov	 REF_DATA_PHYS,ebx ; New physical address of reference data
RARP_XIT:
	 REGREST <ebx>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_ADJUST_REFDATA_PTR ; End RMI_ADJUST_REFDATA_PTR procedure

	 page
BeginProc RMI_GET_DOSVER,PUBLIC ; Get DOS version # for protected mode
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GET_DOSVER

DESCRIPTION:
	Get the DOS version and store it in the reference data structure
	for use upstairs by the protected mode code.  Also, get status
	of DOS=HIGH.

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

	 DOSCALL @DOSVER	; Get DOS version numbers into AX, BX, and CX
	 xchg	 al,ah		; Swap into proper order.  Thanks Aaron.
	 mov	 RMI_REF_DATA.REF_DOSVER,ax ; Save it in the reference data

	 cmp	 ah,5		; Izit at least DOS 5?
	 jb	 short @F	; Nope, so forget extended version call

	 sub	 dx,dx		; Assume not DOS 5, so DOS != HIGH

	 mov	 ax,3306h	; Get MS-DOS Version, extended function code
	 int	 21h		; DOS services
@@:
	 mov	 RMI_REF_DATA.REF_DOSFLAG,dx ; Save DOS=HIGH flag for PM

	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GET_DOSVER 	; End RMI_GET_DOSVER procedure

	 page
BeginProc RMI_GET_REFDATA,PUBLIC ; Copy reference data from extended memory
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GET_REFDATA

DESCRIPTION:
	Copy the reference data from QMAX.SYS's extended memory.

	Use the @EMM2_DBGFLAG call to set the DEBUG=XR bit to allow
	BIOS block move transfers out of QMAX.SYS program storage region.

	Convert the reference data structure physical address to a
	linear address under QMAX's page tables.  Use the @EMM2_PHYS2LIN
	to perform the conversion.  This service was not present in QMAX.SYS
	version 5.10 or 5.11.  If this call fails, we use a local procedure.

	Use the BIOS block move service to copy the reference data in
	our local buffer.

	Use the @EMM2_DBGFLAG call to clear the DEBUG=XR bit if it was
	originally clear upon entry to this procedure.

ENTRY:
	REF_DATA_PHYS contains the physical address of the reference data.
	REFDATA_LEN is the length of the structure.

EXIT:
	Carry set if error.

|

; Copy reference data from extended memory into local buffer

	 REGSAVE <eax,cx,edx,edi,bp> ; Save caller's registers

; Get state of DEBUG=XR bit.  Set if needed.

	 test	 INFO.INFO_DBG,@DBG_XR ; Are block moves to pgm region allowed?
	 jnz	 short @F	; Yes, so skip the EMM2CALL

	 mov	 bx,@DBG_XR	; Bit we want to toggle (set) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:

; Convert reference data physical address to a linear address

	 mov	 edx,REF_DATA_PHYS ; Get reference data passed by Windows

	 call	 RMI_PHYS2LIN	; Convert to a linear address in EDX
	 jc	 short RGR_ERRXIT ; Jump if error

	 mov	 REF_DATA_LIN,edx ; Save for use later on
	 mov	 esi,edx	; Copy to proper source register for BLOCK_MOVE

	 mov	 ax,ds		; Get our data segment
	 movzx	 eax,ax 	; 32-bit it
	 shl	 eax,4		; Form linear address
	 lea	 di,RMI_REF_DATA ; Offset of local buffer for reference data
	 movzx	 edi,di 	; Kill high-order half
	 add	 edi,eax	; Add in offset

	 mov	 cx,REFDATA_LEN ; Length of input reference data in bytes

	 call	 BLOCK_MOVE	; Copy reference data into local buffer
	 jnc	 short RGR_XIT	; Exit normally if it worked
RGR_ERRXIT:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_GETREF ; Tell 'em get reference data failed

	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting

	 stc			;  Error indicator
RGR_XIT:
	 pushf			; Save return indicator

; Clear the DEBUG=XR bit if we set it earlier

	 test	 INFO.INFO_DBG,@DBG_XR	; Was it already set?
	 jnz	 short @F	; Yes, so don't clear it

	 mov	 bx,@DBG_XR	; Bit we want to toggle (clear) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:
	 popf			; Restore return indicator

	 REGREST <bp,edi,edx,cx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GET_REFDATA	; End RMI_GET_REFDATA procedure

	 page
BeginProc RMI_PUT_REFDATA,PUBLIC ; Copy reference data to extended memory
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_PUT_REFDATA

DESCRIPTION:
	Replace the altered reference data in QMAX.SYS's extended memory.

	Use the @EMM2_DBGFLAG call to set the DEBUG=XR bit to allow
	BIOS block move transfers into QMAX.SYS program storage region.

	Convert the reference data structure physical address to a
	linear address under QMAX's page tables.  Use the @EMM2_PHYS2LIN
	to perform the conversion.  This service was not present in QMAX.SYS
	version 5.10 or 5.11.  If this call fails, we use a local procedure.

	Use the BIOS block move service to copy the reference data from
	our local buffer into extended memory.

	Use the @EMM2_DBGFLAG call to clear the DEBUG=XR bit if it was
	originally clear upon entry to this procedure.

ENTRY:
	REF_DATA_PHYS contains the physical address of the reference data.

EXIT:
	Carry set if error

|

	 REGSAVE <eax,cx,edx,edi,bp> ; Save caller's registers

; Get state of DEBUG=XR bit.  Set if needed.

	 push	 si		; Save source offset

	 test	 INFO.INFO_DBG,@DBG_XR ; Are block moves to pgm region allowed?
	 jnz	 short @F	; Yes, so skip the EMM2CALL

	 mov	 bx,@DBG_XR	; Bit we want to toggle (set) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:
	 pop	 si		; Restore source offset

; Convert reference data physical address to a linear address

	 mov	 edx,REF_DATA_PHYS ; Get reference data passed back to Windows

	 call	 RMI_PHYS2LIN	; Convert to a linear address in EDX
	 jc	 short RPR_ERRXIT ; Jump if error

	 mov	 edi,edx	; Copy to proper source register for BLOCK_MOVE

; Copy reference data into extended memory from local buffer

	 mov	 ax,ds			; Get our data segment
	 movzx	 eax,ax 		; 32-bit it
	 shl	 eax,4			; Form linear address
	 lea	 esi,RMI_REF_DATA	; Offset of local reference data
	 add	 esi,eax		; Add in offset

	 mov	 cx,REFDATA_LEN 	; Actual length of reference data
	 cmp	 cx,(type REF_DATA_STR) ; Same size as current structure?
	 je	 short @F		; Use length as-is

	 cmp	 cx,@REF_LEN513 	; Bigger than 5.13 structure?
	 jbe	 short @F		; Use actual length if not

	 mov	 cx,@REF_LEN513 	; Limit to size of 5.13 structure
@@:
	 call	 BLOCK_MOVE	; Copy reference data to extended memory
	 pushf			; Save error flag from BLOCK_MOVE

; Clear the DEBUG=XR bit if we set it earlier

	 test	 INFO.INFO_DBG,@DBG_XR	; Was it already set?
	 jnz	 short @F	; Yes, so don't clear it

	 mov	 bx,@DBG_XR	; Bit we want to toggle (clear) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:
	 popf			; Restore error flag from BLOCK_MOVE
	 jnc	 short RPR_XIT	; Exit normally if it worked
RPR_ERRXIT:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_PUTREF ; Tell 'em put reference data failed

	 call	 RMI_PAUSE	; Display 'press any key' and wait for key press

	 stc			;  Error indicator
RPR_XIT:
	 REGREST <bp,edi,edx,cx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_PUT_REFDATA	; End RMI_PUT_REFDATA procedure

	 page
BeginProc RMI_CMPSBI,PUBLIC	; Case insensitive REPE CMPSB
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CMPSBI

DESCRIPTION:
	Case insensitive string compare procedure that takes the
	pointer registers the same as the REPE CMPSB CPU instruction.

	An STRLEN of the model string is performed to get the length
	of the comparison.

ENTRY:
	DS:SI ==> 1st string (our model, in uppercase)
	ES:DI ==> 2nd string

EXIT:
	Zero flag set if the strings were equivalent.

|

	 REGSAVE <ax,cx,dx,di>	; Save caller's registers

; Calculate the length of the source string

	 push	 di		; Save pointer to ENVSTR_xxx string
	 mov	 cx,-1		; Look forever, we know its there
	 sub	 al,al		; Terminating NULL
	 repne scasb		; Search for the terminating NULL
	 neg	 cx		; Lenght we scanned
	 dec	 cx		; Account for overscan at end
	 pop	 di		; Restore pointer to ENVSTR_xxx string

RMI_CMPSBI_LP:
	 lodsb			; Get next character from compare string
	 mov	 dl,es:[di]	; Get next source character
	 inc	 di		; Bump source pointer

	 and	 dl,(not 20h)	; Convert test character to uppercase form
	 cmp	 al,dl		; Environment against test character
	 jne	 short RMI_CMPSBI_XIT ; Exit NZ

	 loop	 short RMI_CMPSBI_LP ; Loop until done

; Zero flag set or clear depending on previous comparisons

RMI_CMPSBI_XIT:
	 REGREST <di,dx,cx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CMPSBI		; End RMI_CMPSBI procedure

	 page
BeginProc RMI_CMPSBNI,PUBLIC	; Case insensitive REPE CMPSB w/ length
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CMPSBNI

DESCRIPTION:
	Case insensitive string compare procedure that takes the
	pointer registers the same as the REPE CMPSB CPU instruction.

ENTRY:
	CX	= length of comparision
	DS:SI ==> 1st string (our model, in uppercase)
	ES:DI ==> 2nd string

EXIT:
	SI is trashed.
	Zero flag set if the strings were equivalent.

|

	 REGSAVE <ax,cx,dx,di>	; Save caller's registers

RMI_CMPSBNI_LP:
	 lodsb			; Get next character from compare string
	 mov	 dl,es:[di]	; Get next source character
	 inc	 di		; Bump source pointer

	 cmp	 dl,'a'         ; Izit a lowercase character?
	 jb	 short @F	; Nope, so skip the AND

	 cmp	 dl,'z'         ; Izit a lowercase character?
	 ja	 short @F	; Nope, so skip the AND

	 and	 dl,(not 20h)	; Convert test character to uppercase form
@@:
	 cmp	 al,dl		; Environment against test character
	 jne	 short RMI_CMPSBNI_XIT ; Exit NZ

	 loop	 short RMI_CMPSBNI_LP ; Loop until done

; Zero flag set or clear depending on previous comparisons

RMI_CMPSBNI_XIT:
	 REGREST <di,dx,cx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CMPSBNI		; End RMI_CMPSBNI procedure

	 page
BeginProc RMI_SKIPWHITE,PUBLIC	; Skip DS:SI over whitespace
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_SKIPWHITE

DESCRIPTION:
	Advance DS:SI over whitespace characters

ENTRY:
	DS:SI ==> input text

EXIT:
	DS:SI is advanced over blanks and TABs.

|

	 REGSAVE <ax>		; Save caller's registers
@@:
	 lodsb			; Pick up next character

	 cmp	 al,' '         ; Izit a blank?
	 je	 short @B	; Try another if so

	 cmp	 al,TAB 	; Izit a TAB?
	 je	 short @B	; Try another if so

	 dec	 si		; Unget the last character

	 REGREST <ax>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_SKIPWHITE		; End RMI_SKIPWHITE procedure

	 page
BeginProc RMI_SYSINI_FLAGS,PUBLIC ; Get state of SYSTEM.INI switches
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_SYSINI_FLAGS

DESCRIPTION:
	Read SYSTEM.INI and set flags based on switch settings.

	The 'windir' (note it is lowercase) environment variable is used
	to get the Windows directory.  The SYSTEM.INI file is opened and read.

	Get numeric value of the NETHEAPSIZE cookie.
	Get numeric value of the VIRTUALHIGHDOS cookie.

EXIT:
	Global variables and flags updated.

|

	 pusha			; Save caller's registers
	 push	 es		; Save caller's ES

; Find the 'windir' environment variable and put its contents into PATH_BUF

	 call	 RMI_GET_WINDIR ; Fill in PATH_BUF from 'windir' environ var
	 jc	 RMI_NOWINSTR	; Skip display code if not found

; Append filename to PATH_BUF

	 lea	 si,SYSINI_FILE ; Pointer to '\SYSTEM.INI', 0
	 mov	 cx,@SYSINI_FILE_L ; Get length of above filename
S16	 rep movsb		; Copy filename to end of path

; Open SYSTEM.INI file.  It we get an error opening it,
; return with no RMI_FLAGs set.

	 mov	 al,0		; R/O access
	 DOSCALL @OPENF2,PATH_BUF ; Open SYSTEM.INI
	 jc	 RMI_NOWINSTR	; Return w/o setting flags if open failed

	 mov	 bx,ax		; Move handle to proper register

; Read in each line from SYSTEM.INI using RMI_GETLINE in a loop

RSF_GETLINE:
	 call	 RMI_GETLINE	; Read next line from file
	 jc	 RSF_CSI	; Close SYSTEM.INI

; Find the first non-whitespace character in the SYSTEM.INI line
	 lea	 si,LINEBUF	; Get pointer to line
@@:
	 lodsb			; Get next character

	 or	 al,al		; Is it the EOL?
	 jz	 RSF_IGNORE_LINE ; Skip out if so

	 cmp	 al,' '         ; Is it a blank?
	 je	 short @B	; Ignore it if so

	 cmp	 al,TAB 	; Is it a TAB?
	 je	 short @B	; Ignore it if so

	 dec	 si		; Back up SI ==> 1st non-whitespace character

; Compare this line against [386Enh] to signal looking for various cookies.

	 cmp	 [si].LO,'['    ; Izit a section heading?
	 jne	 short RSF_XSECTION ; Jump if not

; We've hit a section heading

	 and	 RMI_FLAG,(not @RMI_386ENH) ; Indicate we're not in [386Enh]

	 REGSAVE <cx,si,di>	; Save registers over REP CMPSB

	 lea	 di,STR_386ENH	; ES:DI ==> '[386Enh]'
	 mov	 cx,@STR_386ENH_LEN ; Length of '[386Enh]'
    repe cmpsb			; Compare SYSTEM.INI line against '[386Enh]'

	 REGREST <di,si,cx>	; Restore registers after REP CMPSB

	 jne	 short @F	; Skip if not the [386Enh] section

	 or	 RMI_FLAG,@RMI_386ENH ; Indicate we're in the [386Enh] section
@@:
	 jmp	 RSF_IGNORE_LINE ; Skip out if so

RSF_XSECTION:

; If we're in the [386Enh] section, compare this SYSTEM.INI line
; against some popular cookies.

	 test	 RMI_FLAG,@RMI_386ENH ; Are we in the [386Enh] section?
	 jz	 short RSF_X386ENH ; Jump if not

; Look for NETHEAPSIZE

	 REGSAVE <cx,si,di>	; Save registers across compare

	 call	 RMI_SKIPWHITE	; Skip whitespace

	 mov	 di,si		; ES:DI ==> SYSTEM.INI line
	 lea	 si,STR_NETHEAPSIZE ; DS:SI ==> 'NETHEAPSIZE='
	 mov	 cx,@STR_NETHEAPSIZE_LEN ; Length of target string
	 call	 RMI_CMPSBNI	; Case insensitive REPE CMPSB w/ length in CX

	 REGREST <di,si,cx>	; Restore registers after compare
				; Zero flag set if strings matched
	 jne	 short RSF_XNETHEAPSIZE ; Jump if not found

; We've encountered NETHEAPSIZE= in SYSTEM.INI.
; Pick up the number.

	 REGSAVE <si>		; Save registers

	 call	 RMI_SKIPWHITE	; Skip whitespace

	 add	 si,@STR_NETHEAPSIZE_LEN ; Bump past '=' in SYSTEM.INI line
	 call	 RMI_GETDEC	; Pick up the decimal number

	 REGREST <si>		; Restore registers

	 or	 eax,eax	; Zero means it's no good
	 jz	 RSF_IGNORE_LINE ; Jump if number is bad

	 cmp	 eax,640 shl 2	; Izit bigger than VNETBIOS will accept?
				; This comparison comes from the VBETBIOS source
	 ja	 RSF_IGNORE_LINE ; Jump if so

	 mov	 NETHEAPSIZE,ax ; Update over top of the default value

	 jmp	 short RSF_IGNORE_LINE ; Go examine the next SYSTEM.INI line

RSF_XNETHEAPSIZE:

; Look for VIRTUALHIGHDOS

	 REGSAVE <cx,si,di>	; Save registers across compare

	 call	 RMI_SKIPWHITE	; Skip whitespace

	 mov	 di,si		; ES:DI ==> SYSTEM.INI line
	 lea	 si,STR_VIRTUALHIGHDOS ; DS:SI ==> 'VIRTUALHIGHDOS='
	 mov	 cx,@STR_VIRTUALHIGHDOS_LEN ; Length of target string
	 call	 RMI_CMPSBNI	; Case insensitive REPE CMPSB w/ length in CX

	 REGREST <di,si,cx>	; Restore registers after compare
				; Zero flag set if strings matched
	 jne	 short RSF_XVIRTUALHIGHDOS ; Jump if not found

; We've encountered VIRTUALHIGHDOS= in SYSTEM.INI.
; Pick up the number.

	 REGSAVE <si>		; Save registers

	 call	 RMI_SKIPWHITE	; Skip whitespace

	 add	 si,@STR_VIRTUALHIGHDOS_LEN ; Bump past '=' in SYSTEM.INI line
	 call	 RMI_GETDEC	; Pick up the decimal number

	 REGREST <si>		; Restore registers

	 or	 eax,eax	; Zero means it's no good
	 jz	 short RSF_IGNORE_LINE ; Jump if number is bad

	 cmp	 eax,-1 	; Izit the special 'maximize' option?
	 je	 short @F	; Jump if so

	 cmp	 eax,384	; We can't ever have more than this much
	 ja	 short RSF_IGNORE_LINE ; Jump if so
@@:
	 mov	 VIRTUALHIGHDOS,ax ; Update over top of the default value

	 jmp	 short RSF_IGNORE_LINE ; Go examine the next SYSTEM.INI line

RSF_XVIRTUALHIGHDOS:

; Look for SystemROMBreakPoint
; FIXME under construction

RSF_X386ENH:

RSF_IGNORE_LINE:
	 jmp	 RSF_GETLINE	; Go back and check the next line

RSF_CSI:
	 DOSCALL @CLOSF2	; Close SYSTEM.INI file

RMI_NOWINSTR:
	 pop	 es		; Restore caller's ES
	 assume  es:nothing	; Tell the assembler

	 popa			; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_SYSINI_FLAGS	; End RMI_SYSINI_FLAGS procedure

	 page
BeginProc RMI_GETDEC,PUBLIC	; Get decimal number, carry set if none
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Get and convert decimal number from DS:[SI] stream.
	Return number in EAX.  Return zero if no number is present.

ENTRY:
	DS:SI ==> input text.

EXIT:
	EAX = converted binary number, or zero if the number was invalid.
	DS:SI is advanced over the number.

|

	 REGSAVE <ebx,dx>	; Save caller's registers

	 sub	 ebx,ebx	; Initialize accumulator to zero
	 sub	 dl,dl		; Positive value flag

; Check for a negative number

	 cmp	 [si].LO,'-'    ; Izit a negative number?
	 jne	 short RMI_GETDEC_XNEG ; Jump if not

	 inc	 si		; Bump past '-'
	 inc	 dl		; Remember it's negative
RMI_GETDEC_XNEG:

RMI_GETDEC_NEXT:
	 lodsb			; Get next character from SYSTEM.INI line
	 call	 RMI_ISDEC	; Convert digit to binary, set carry if error
	 jc	 short RMI_GETDEC_NOTDEC ; Jump if no more decimal digits

	 movzx	 eax,al 	; Convert digit from BYTE to DWORD
	 imul	 ebx,10 	; Shift existing digits left one position
	 jo	 short RMI_GETDEC_OVERFLOW ; Exit if number is too big

	 add	 ebx,eax	; Add into accumulated sum
	 jc	 short RMI_GETDEC_OVERFLOW ; Exit if number is too big

	 jmp	 short RMI_GETDEC_NEXT ; Try another digit

RMI_GETDEC_OVERFLOW:
	 sub	 eax,eax	; Return zero on bad conversions

	 jmp	 short RMI_GETDEC_XIT ; Rejoin common exit code

RMI_GETDEC_NOTDEC:
	 mov	 eax,ebx	; Copy result to proper register for return

	 or	 dl,dl		; Izit negative
	 jz	 short @F	; Nope

	 neg	 eax		; Convert result to negative value
@@:

RMI_GETDEC_XIT:
	 REGREST <dx,ebx>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GETDEC		; End RMI_GETDEC procedure

	 page
BeginProc RMI_ISDEC,PUBLIC	; Get next decimal digit, carry set if none
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Check if char in AL is a decimal digit and convert it to binary if so.
	Carry set if not.

ENTRY:
	AL = character to get against decimal digits.

EXIT:
	Carry set if AL was not a decimal digit, clear otherwise.
	AL = binary form of digit if carry clear.

|

	 sub	 al,'0'         ; Kill ASCII digit bias
	 jc	 short RMI_ISDEC_XIT ; Exit error if AL < '0'

	 cmp	 al,9+1 	; Izit within 0 - 9?
				; Carry clear if within 0 - 9

	 cmc			; Toggle so carry set if AL >= 10
RMI_ISDEC_XIT:
	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_ISDEC		; End RMI_ISDEC procedure

	 page
BeginProc RMI_PAUSE,PUBLIC	; Display 'press and ley' and wait for key press
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_PAUSE

DESCRIPTION:
	Display a 'press any key' message and wait for the user to do so.
	If they hit escape, set the flag bit to fail the Windows startup.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 DOSCALL @STROUT,MSG_PAKORESC ; Display 'press any key or ESC' message

	 mov	 al,@KEYIN	; Wait for a key w/o echo
	 DOSCALL @CKEYIN	; Clear keyboard input buffer and wait for a key

	 cmp	 al,ESCAPE	; Izit it an ESC?
	 clc			; Assume not

	 jne	 short @F	; Skip if not

	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting

	 stc			; Indicate ESC pressed
@@:
	 pushf			; Save ESC flag

	 DOSCALL @STROUT,MSG_CRLF ; Print CR and LF
	 DOSCALL @STROUT,MSG_CRLF ; Print CR and LF

	 popf			; Restore ESC flag

	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_PAUSE		; End RMI_PAUSE procedure

	 page
BeginProc RMI_GET_WINDIR,PUBLIC ; Fill in PATH_BUF from 'windir' environ var
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GET_WINDIR

DESCRIPTION:
	Fill in PATH_BUF from 'windir' environment variable.

EXIT:
	DS:DI ==> Next available character in PATH_BUF after WINDIR.
	Carry set if environment variable not set.

|

	 REGSAVE <ax,cx,si,ds,es> ; Save caller's registers

	 mov	 ax,ds		; Copy DS to ES for search
	 mov	 es,ax		; ...
	 assume  es:_RCODE	; Tell the assembler

	 lea	 si,ENVNAM_WINDIR ; Get offset to "windir"
	 call	 RMI_GETENV	; Find it in the environment strings
	 assume  es:nothing	; Tell the assembler

	 jc	 short GWD_XIT	; Return with CF set if not found

; ES:DI ==> WINDIR environment string.

	 push	 di		; Save pointer to start of path
	 mov	 cx,8000h	; We know its in there
	 sub	 al,al		; We'll be searching for this NULL
	 repne scasb		; Scan to the end of the string
	 pop	 di		; Restore pointer to start of path

	 sub	 cx,8000h	; Find distance travelled in the REPNE SCASB
	 neg	 cx		; Length of pathname including NULL
	 dec	 cx		; Less the NULL

	 mov	 si,di		; Source is path from WINDIR environment string
	 lea	 di,PATH_BUF	; Destination

	 push	 ds		; Save original DS

	 push	 ds		; Exchange DS and ES
	 push	 es		; ...

	 pop	 ds		; ES <== DS
	 assume  ds:nothing	; Tell the assembler

	 pop	 es		; DS <== ES
	 assume  es:_RCODE	; Tell the assembler

S16	 rep movsb		; Copy the WINDIR path to our path buffer
	 pop	 ds		; Restore original DS
	 assume  ds:_RCODE	; Tell the assembler

	 clc			; Normal return indicator
GWD_XIT:
	 REGREST <es,ds,si,cx,ax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GET_WINDIR 	; End RMI_GET_WINDIR procedure

ifdef @VGASWAP
	 page
BeginProc RMI_CHK_FLEXROM,PUBLIC ; Set flag if VGASWAP is in effect
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_FLEXROM

DESCRIPTION:
	Use the @EMM2_FLEXINFO service to fetch the ROMSWAP info.
	Set RMI_FLAG.@VID_VGASWAP if ROMSWAP seems to be in effect
	Save the physical address of the FLEXROM structure in the updated
	reference data structure.

|

	 REGSAVE <ax,bx,cx,edx,di,bp,es> ; Save caller's registers

	 sub	 edx,edx	; Assume no FLEXROM info is available

	 mov	 bp,sp		; Save current stack pointer
	 EMMOUT  @EMM2_FLEXINFO ; Get address of FLEXROM info structure
	 mov	 sp,bp		; Cut back the stack in case of error

	 or	 ah,ah		; Did the EMM2 call fail?
	 jnz	 short @F	; Yup, so there's no VGASWAP support this time

	 or	 edx,edx	; Izit NULL?
	 jz	 short @F	; Yup, so FLEXROM info isn't available

	 mov	 RMI_REF_DATA.REF_FLEXROM_PTR,edx ; Save physical address ...
				; ... of FLEXROM structure for use upstairs

	 mov	 RMI_REF_DATA.REF_FLEXROM_LEN,cx ; Save count of entries

	 jcxz	 @F		; Don't set FLEXROM bit if count is zero

	 or	 RMI_REF_DATA.REF_VIDFLAG,@VID_VGASWAP ; Indicate using VGASWAP

@@:
	 REGREST <es,bp,di,edx,cx,bx,ax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_CHK_FLEXROM		; End RMI_CHK_FLEXROM procedure
endif					; IFDEF @VGASWAP
	 page
BeginProc RMI_CHK_VIDEO,PUBLIC	; Set bits for pesky VGAs
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_VIDEO

DESCRIPTION:
	Duplicate the code in the VDD's real mode init (without its bugs)
	to determine which type of video hardware is present.

	Pass the information along to the protected mode portion of
	the VxD to avoid 'Video Device Conflict' later.

EXIT:
	RMI_REF_DATA.REF_VIDFLAG set to indicate problem VGAs

|

	 REGSAVE <eax,dx,esi,es> ; Save caller's registers

; Check for the presence of a VGA

	 mov	 ax,1A00h	; Read display combination code
	 int	 10h		; Video BIOS services

	 cmp	 al,1Ah 	; Does this BIOS recognize the function?
	 jne	 RCV_XITOK	; No, so it's not a VGA we care about

	 cmp	 bl,7		; VGA w/ monochrome analog display
	 jb	 RCV_XITOK	; Lesser codes aren't VGAs

	 cmp	 bl,8		; VGA w/ color analog display
	 ja	 RCV_XITOK	; Greater codes aren't VGAs

; The following code is mostly copied from \WIN3\SDK\VDDEGA\VDDINIT.ASM
; Check for presence of any Video 7 board

	 xor	 bx,bx			; Assume not Video 7 or VEGA VGA
	 mov	 ax,6F00h		; V7 presence detection
	 int	 10h			; Video services

	 cmp	 bx,'V7'                ; Any of the products?
	 jnz	 short VRI_NOTV7	; Nope, rejoin common code

; Check the chip version #

	 mov	 cx,0ffffh		; Assume not V7 VGA
	 mov	 ax,06f07h		; Get video memory configuration
	 int	 10h			; Video services

; Must be in the range 70h - 7Fh

	 or	 cx,cx			; Zero if Video 7 board
	 jnz	 short VRI_NOTV7	; Nope, rejoin common code

	 cmp	 bh,70h 		; V7VGA chip?
	 jl	 short VRI_NOTV7	; Nope, rejoin common code

; If we get here it is a video seven board with all the trimmings

	 or	 RMI_REF_DATA.REF_VIDFLAG,@VID_V7VGA ; Video 7 VGA chipset

	 jmp	 VRI_ENDTESTS		; Rejoin common code

; Check for Paradise chipset

VRI_NOTV7:
	 mov	 dx,3CEh		; Paradise Super VGA index port
	 mov	 al,0Fh 		; Index to PR5
	 out	 dx,al			; Prepare to read PR5

	 inc	 dx			; Bump to data port
	 in	 al,dx			; Get original PR5 register

	 push	 ax			; Save original I/O port value
	 and	 al,0F0h		; Isolate upper 4 bits
	 mov	 ah,al			; Save
	 xor	 al,0F0h		; Reverse upper 4 bits
	 or	 al,5			; Enable the extensions

	 out	 dx,al			; Respecify PR5
	 jmp	 short $+2		; Wait for slow AT bus

	 in	 al,dx			; Get PR5
	 xor	 al,ah			; Are lower bits 5 & upper 3 unchanged?
	 cmp	 al,5			; ...
	 pop	 ax			; Restore original PR5 value

	 out	 dx,al			; Respecify original PR5

	 jnz	 short NOT_PVGA 	; Not be PVGA if bits don't match up

	 or	 RMI_REF_DATA.REF_VIDFLAG,@VID_PVGA ; Paradise Super VGA chipset

; Paradise VGA, check for Paradise VGA ROM

	 mov	 ax,0C000h		; Segment address of VGA ROM
	 mov	 es,ax			; Setup addressibility to ROM
	 assume  es:nothing		; Tell the assembler

	 lea	 si,STR_PARADISE	; String for comparison
	 xor	 di,di			; Start of ROM
	 mov	 cx,128 		; # of tries
PVGA_FINDROMLOOP:
	 push	 di			; Save ROM address
	 push	 cx			; Save retry count
	 lea	 si,STR_PARADISE	; String for comparison
	 mov	 cx,@STR_PARADISE_L	; Length of comparison
	 repe cmpsb			; Izit the Paradise ROM?
	 pop	 cx			; Restore retry count
	 pop	 di			; Restore ROM address

	 je	 short ISPVGAROM	; Jump if Paradise ROM

	 inc	 di			; Bump to next byte in ROM
	 loop	 PVGA_FINDROMLOOP	; Look thru all 128 ranges

; PARADISE not found, now look for WESTERN DIGITAL

	 xor	 di,di			; Start of ROM
	 mov	 cx,128 		; Retry counter
PVGA_FINDROMLOOP1:
	 push	 di			; Save ROM address
	 push	 cx			; Save retry count
	 lea	 si,STR_WDIGITAL	; String for comparison
	 mov	 cx,@STR_WDIGITAL_L	; Length for comparison
	 repe cmpsb			; Izit the Paradise ROM?
	 pop	 cx			; Restore retry count
	 pop	 di			; Restore ROM address

	 je	 SHORT ISPVGAROM	; Jump if it is a Paradise ROM

	 inc	 di			; Bump to next byte in ROM
	 loop	 PVGA_FINDROMLOOP1	; Look thru all 128 ranges

	 test	 RMI_REF_DATA.REF_VIDFLAG,@VID_PVGA ; Paradise Super VGA chipset
	 jnz	 short VRI_ENDTESTS	; Rejoin common exit code

	 jmp	 short NOT_PVGA 	; Rejoin common code

ISPVGAROM:
	 or	 RMI_REF_DATA.REF_VIDFLAG,@VID_PVGA+@VID_PVGAROM
					; Indicate Paradise VGA BIOS ROM

	 jmp	 short VRI_ENDTESTS	; Rejoin common code

NOT_PVGA:

; Test for Tseng Labs VGA (we need to exclude some V86 memory if present)
; Attribute Controller Reg 16h is known to exist only on Tseng Labs VGA

	 mov	 dx,@PMISCVGAIN 	; Read VGA misc. output (03CCh)
	 in	 al,dx			; ...

	 test	 al,1
	 mov	 dl,(@PSTATCOLR and 0FFh) ; Color status register port (03DAh)
	 jnz	 short VSI_COLR

	 mov	 dl,(@PSTATMONO and 0FFh) ; Mono status register port (03BAh)
VSI_COLR:
	 push	 dx			; Save port address (03DAh / 03BAh)
	 in	 al,dx			; Read status to setup attribute index
	 jmp	 short $+2		; Wait for slow AT bus

	 mov	 dl,(@PATTREGA and 0FFh) ; Attribute write port (03C0h)
	 in	 al,dx			; Get attribute (03C0h)
	 mov	 bl,al			; Save original attr register value
	 jmp	 short $+2		; Wait for slow AT bus

	 mov	 al,16h+20h		; Select misc reg. 16h (leave video on)
	 out	 dx,al			; Send new attribute (03C0h)
	 jmp	 short $+2		; Wait for slow AT bus

	 inc	 dx			; Bump to read attribute port (03C1h)
	 in	 al,dx			; Get attribute data
	 jmp	 short $+2		; Wait for slow AT bus
	 mov	 ah,al			; Save current reg 16h in AH

	 dec	 dx			; Back to attribute write port (03C0h)
	 xor	 al,10h 		; Complement bit 4
	 out	 dx,al			; Write it out (03C0h)
	 jmp	 short $+2		; Wait for slow AT bus

;;;;;;	 pop	 dx			; Refresh port address
;;;;;;	 push	 dx			; ... and save it again
	 mov	 dx,[esp]		; Refresh port address
	 in	 al,dx			; Read status to setup attribute index

	 mov	 dx,@PATTREGA		; Attribute write port (03C0h)
	 mov	 al,16h+20h		; Select 16h (leave video on)
	 out	 dx,al			; Send new attr (03C0h)
	 jmp	 short $+2		; Wait for slow AT bus

	 inc	 dx
	 in	 al,dx
	 jmp	 short $+2		; Wait for slow AT bus

	 dec	 dx
	 xor	 al,10h
	 cmp	 al,ah			; Is value same as written?
	 jnz	 short NOT_TLVGA	; No, rejoin common code

	 or	 RMI_REF_DATA.REF_VIDFLAG,@VID_TLVGA ; Flag as Tseng Labs VGA
NOT_TLVGA:
	 mov	 al,ah			; Get original misc. reg. 16h value
	 out	 dx,al			; Restore it
	 jmp	 short $+2		; Wait for slow AT bus

	 pop	 dx			; Status port (03DAh / 03BAh)
	 in	 al,dx			; Read status to setup attribute index
	 jmp	 short $+2		; Wait for slow AT bus

	 mov	 dl,(@PATTREGA and 0FFh) ; Attribute write port (03C0h)
	 mov	 al,bl			; Get original attribute register value
	 out	 dx,al

VRI_ENDTESTS:

RCV_XITOK:
	 clc			; Normal return indicator
RCV_NOTPVGA:
RCV_XIT:
	 REGREST <es,esi,dx,eax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHK_VIDEO		; End RMI_CHK_VIDEO procedure
	 page
BeginProc RMI_FIX_VIDEO,PUBLIC	; Fix problems w/ certain VGA adapters
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_FIX_VIDEO

DESCRIPTION:
	Certain VGA adapters are left in a funky state by the real mode init
	code of the standard Windows 3.0 VDD.  This code fiddles the
	VGA just right to try and avoid the problems.

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

; Check for the presence of a VGA

	 mov	 ax,1A00h	; Read display combination code
	 int	 10h		; Video BIOS services

	 cmp	 al,1Ah 		; Does this BIOS recognize the function?
	 jne	 short RFV_XITOK	; No, so it's not a VGA we care about

	 cmp	 bl,8			; VGA w/ color analog display?
	 jne	 short RFV_XITOK	; Nope, so we won't try to fix it

; We've got a VGA.  Check for graphics mode used by WIN.COM

	 mov	 ah,0Fh 	; Get current video mode
	 int	 10h		; Video BIOS services

	 cmp	 al,12h 		; Izit Mode 12h, 648x480x16 VGA mode?
	 jne	 short RFV_XITOK	; Exit if not

; Get and save current cursor position

	 mov	 ah,03h 	; Get cursor position
	 mov	 bh,0		; Indicate it's graphics mode
	 int	 10h		; Video BIOS services
				; DH,DL = row, column
				; CH,CL = cursor start, end

	 REGSAVE <dx>		; Save cursor position

	 mov	 dx,(1 shl 8) or 4 ; Cursor within the 'M' or black background
	 mov	 bh,0		; Display page
	 mov	 ah,02h 	; Set cursor position
	 int	 10h		; Video BIOS services

; Select the proper color based on the Windows version.
; The Windows 3.0 famous 'blue screen' is blue.
; The Windows 3.1 'blue screen' is, in fact, black.

	 mov	 bx,(0 shl 8) or 00h	; Display page and black attribute
					; Assume Windows 3.1
	 cmp	 WIN386_VER,030Ah	; Izit WIN386 3.1?
	 jae	 short @F		; Skip if assumption was correct

	 mov	 bx,(0 shl 8) or 04h	; Display page and attribute (blue)
@@:
	 mov	 ah,09h 	; Write character and attribute at cursor
	 mov	 al,0DBh	; Character to write (full block graphics char)
	 mov	 cx,1		; Repetition count
	 int	 10h		; Video BIOS services

	 REGREST <dx>		; Restore cursor position

	 mov	 ah,02h 	; Set cursor position
	 mov	 bh,0		; Display page
	 int	 10h		; Video BIOS services

RFV_XITOK:
	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_FIX_VIDEO		; End RMI_FIX_VIDEO procedure
	 page
BeginProc RMI_FIX_DRDOS,PUBLIC	; Fiddle with XMS A20 for DR-DOS
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_FIX_DRDOS

DESCRIPTION:
	DR-DOS 6.0 loaded into the HMA uses the XMS global enable A20
	scheme rather than the local enable A20 used by MS-DOS 5.  Windows
	3.1 is built assuming the DOS acts like MS-DOS.  WIN386 issues
	local disable A20 calls in a loop (4096 times).  After each call it
	checks to see if the A20 line is still enabled.  This scheme is used
	to detect the enable count.  It turns out that HIMEM.SYS isn't
	built to the letter of the XMS 2.0 spec as is 386MAX.SYS.  HIMEM.SYS
	will disable a global A20 in response to a local disable call whereas
	386MAX will not.  This causes the WIN386 loader to pass incorrect
	information about the state of A20 up to V86MMGR.  When V86MMGR takes
	over control of A20, it doesn't get the HMA setup right, so the first
	V86 mode DOS call crashes the system.  This generally comes from the
	PageSwap or PageFile devices, depending on the paging system setup.

	In this code, we detect the case of Windows 3.1, DR-DOS 6.0 with the
	Windows 3.1 patches, DOS=HIGH, and HMA in-use.	If all conditions
	are met, we'll convert the global enable to a local enable upstairs
	in the protected mode code.

	Hopefully, this won't wreck DR-DOS after Windows exits.

|

; We'll be issuing undocumented DOS calls, so we save the world

	 pusha				; Save caller's GP registers

	 cmp	 WIN386_VER,030Ah	; Izit WIN386 3.1?
	 jb	 RFDR_XDRDOS		; Exit if not

; FIXME Someday 386MAX.SYS will use the HIMEM.SYS behavior.
; If and when that happens, check for the version number here.

	 DOSCALL @DOSVER		; Get DOS version # into AL:AH
	 xchg	 al,ah			; Correct the major/minor order
					; ... for ease of debugging

; If it's DOS 3.31, check for DR-DOS using their undocumented 4452h call

	 cmp	 ax,031Fh		; Izit 3.31?
	 jne	 short RFDR_XDRDOS	; Jump if not

	 REGSAVE <ds,es,fs,gs>		; Save caller's segment registers

	 stc				; Assume nobody's home
	 mov	 ax,4452h		; DR-DOS call to get internal version #
	 int	 21h			; DOS services

	 REGREST <gs,fs,es,ds>		; Restore segment registers
	 assume  ds:_RCODE		; Tell the assembler
	 assume  es:nothing, fs:nothing, gs:nothing

	 jc	 short RFDR_XDRDOS	; Jump if not DR-DOS

; The known DR-DOS versions and the corresponding AX value are:
;	 AX    Version
;	1060h	3.40
;	1063h	3.41
;	1065h	5.0
;	1066h	6.0
;	1067h	6.0	Windows 3.1 patch level

	 cmp	 ax,1067h		; Izit DR-DOS 6.0 with Windows 3.1 patch
	 jb	 short RFDR_XDRDOS	; Jump if not

	 cmp	 ax,106Fh		; Izit newer than our risk factor?
	 ja	 short RFDR_XDRDOS	; Jump if so

; Check for an enabled A20 line

	 mov	 ax,4300h		; XMS driver detection
	 int	 2Fh			; ...

	 cmp	 al,80h 		; Did it work?
	 jne	 RFDR_XDRDOS		; No, so give up

	 push	 es			; Save around XMS call

	 mov	 ax,4310h		; Get XMS FAR CALL vector
	 int	 2Fh			; ...
	 assume  es:nothing

	 mov	 XMS_VEC.VOFF,bx	; Save the offset
	 mov	 XMS_VEC.VSEG,es	; ... and the segment

	 pop	 es			; Restore
	 assume  es:nothing		; Tell the assembler

	 mov	 ah,@XMS_QRYA20 	; Query A20 status
	 call	 XMS_VEC		; ...

	 cmp	 ax,0001h		; Is A20 enabled?
	 jne	 short RFDR_XDRDOS	; Exit if not

; Check for HMA in use

	 mov	 dx,0FFFFh		; Size of request (the whole thing)
	 mov	 ah,@XMS_REQHMA 	; Request HMA
	 call	 XMS_VEC		; ...

	 cmp	 ax,0001h		; Did we get the HMA?
	 jne	 short @F		; Don't release it if we didn't get it

	 mov	 ah,@XMS_RELHMA 	; Release HMA
	 call	 XMS_VEC		; ...

	 jmp	 short RFDR_XDRDOS	; If DR-DOS isn't in the HMA, exit

@@:

; Check for DR-DOS presence in the HMA
; It sure would be nice if there was a call for this.  MS-DOS has one.
; We scan FFFF:0 --> FFFF:1000 for 'OS=DRDOS VER='.

; FIXME I've defered that test.  For now I'm assuming if DR-DOS is loaded
; and the HMA is in use, that it is DR-DOS that is in it.

; Now see if a local disable will loose the HMA.  If so, we'll assume that
; either DR-DOS has used a local enable, or the behavior of 386MAX.SYS has
; changed to work like HIMEM.SYS.

	 mov	 ah,@XMS_LCLDIS 	; Local Disable A20
	 call	 XMS_VEC		; ...

	 cmp	 ax,0001h		; Did we loose the HMA?
	 jne	 short RFDR_OR		; Skip remaining checks if not
					; Note this should never occur

	 mov	 ah,@XMS_QRYA20 	; Query A20 status
	 call	 XMS_VEC		; ...

	 push	 ax			; Save return status

	 mov	 ah,@XMS_LCLENA 	; Local Enable A20
	 call	 XMS_VEC		; ...
					; We'll ignore the return code from this

	 pop	 ax			; Restore query A20 status

	 cmp	 ax,0001h		; Was A20 still enabled?
	 jne	 short RFDR_XDRDOS	; Exit if 386MAX is acting like HIMEM

RFDR_OR:
	 or	 RMI_REF_DATA.REF_UPDFLAG,@UPD_DRDOS ; Tell PM about DR-DOS

RFDR_XDRDOS:
	 popa			; Restore caller's GP registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_FIX_DRDOS		; End RMI_FIX_DRDOS procedure
	 page
BeginProc RMI_CALC_PAGES,PUBLIC ; Guess # of mapping pages needed by WIN386
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CALC_PAGES

DESCRIPTION:
	Simulate the activity of the various VxDs to figure out
	how much API mapping buffer pages they'll need.  Update the
	reference data with this value.

	QMAX.SYS will use this value at disable callback time while
	editing the high DOS arena.

EXIT:
	Global variables updated.

|

	 REGSAVE <ax,bx,cx,dx,si,es> ; Save caller's registers

COMMENT|

Check for a VIRUTALHIGHDOS= override in SYSTEM.INI

	VIRTUALHIGHDOS=0
		Means provide no virtual high DOS.
		Minimize the WIN386 footprint in low DOS.

	VIRTUALHIGHDOS=-1
		Means maximize the virtual high DOS at the expense of
		the WIN386 footprint in low DOS.

	VIRTUALHIGHDOS=nn
		Means provide up to nn KB of virtual high DOS.
		The high DOS arena editor in 386MAX will stop when
		it has nn KB left.

|

; Try to determine the exact number of mapping pages needed by WIN386

	 mov	 PRIVATE_MAP_PAGES,0 ; Initialize high water mark
	 mov	 MIN_MAP_PAGES,0 ; Initialize high water mark
	 mov	 MIN_BUF_PAGES,1 ; Default copy buffer size for Windows 3.0

	 cmp	 WIN386_VER,030Ah	; Izit WIN386 3.10?
	 jb	 short @F		; Skip if not

	 inc	 MIN_BUF_PAGES	; Add another page if it's Windows 3.10
@@:

; Assume values for the PageSwap device

	 inc	 PRIVATE_MAP_PAGES ; Add in another private page for PageSwap

; Check for Novell IPX
; This code copied from VIPX

	 mov	 ax,7AFFh	; Function check
	 mov	 cx,4E65h	; 'NetW'
	 mov	 dx,7457h	; ...
	 mov	 bx,0001h	; Unknown
	 mov	 si,0FFFFh	; Unkwown
	 int	 2Fh		; IPX installation check and reference data ptr

	 cmp	 cx,8000h	; Unknown
	 jne	 short RCP_XVIPX ; Jump if VIPX will not be installed

	 cmp	 si,2		; Unknown
	 jne	 short RCP_XVIPX ; Jump if VIPX will not be installed

; IPX is installed

	 mov	 ax,3		; BH input to V86MMGR_Set_Mapping_Info

	 cmp	 MIN_MAP_PAGES,ax ; MIN_MAP_PAGES = max(MIN_MAP_PAGES, 3);
	 jae	 short @F	; Jump if present value is bigger

	 mov	 MIN_MAP_PAGES,ax ; Update maximum seen so far
@@:
	 inc	 PRIVATE_MAP_PAGES ; Account for another private page

RCP_XVIPX:

; Check for NETBIOS
; This code is a modified version of code from VNETBIOS

	 push	 es		; Save ES around DOSCALL

	 mov	 al,5Ch 	; NETBIOS interrupt #
	 DOSCALL @GETINT	; Get interrupt vector for AL into ES:BX
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es		; Copy the segment
	 or	 ax,bx		; Is there anybody home at 5Ch?
	 jz	 short RCP_XNETBIOS ; Nope, so NETBIOS isn't installed

; Issue a bogus NETBIOS call.  NETBIOS will return 3 if installed

	 push	 ds		; Get addressibility to _RCODE ...
	 pop	 es		; ... via ES
	 assume  es:_RCODE	; Tell the assembler

	 lea	 bx,NETBIOS_BLK ; ES:BX ==> NETBIOS control block
	 sub	 ax,ax		; Clear to value other than the expected 3
	 int	 5Ch		; NETBIOS

	 cmp	 al,3		; Check return code for 'invalid command'
	 jne	 short RCP_XNETBIOS ; Jump if VNETBIOS won't install

; NETBIOS is installed

	 mov	 ax,NETHEAPSIZE ; Value of NETHEAPSIZE from SYSTEM.INI
				; Default = 12
	 add	 ax,3		; Round up to even number of 4K pages
	 shr	 ax,2		; Convert from 1 KB to 4 KB

	 cmp	 MIN_MAP_PAGES,ax ; MIN_MAP_PAGES = max(MIN_MAP_PAGES, 3);
	 jae	 short @F	; Jump if present value is bigger

	 mov	 MIN_MAP_PAGES,ax ; Update maximum seen so far
@@:
	 inc	 PRIVATE_MAP_PAGES ; Account for another private page

RCP_XNETBIOS:
	 pop	 es		; Restore original ES
	 assume  es:nothing	; Tell the assembler

; Done with individual VxD components; calculate # of pages needed

	 mov	 ax,MIN_BUF_PAGES ; Request size = Min_Buf_Pages
	 add	 ax,MIN_MAP_PAGES ; ... + Min_Map_Pages
	 add	 ax,PRIVATE_MAP_PAGES ; ... + Private_Map_Pages

; Update the reference data

	 mov	 RMI_REF_DATA.REF_MAP_PAGES,ax ; Update reference data ...
				; ... for 386MAX disable callback

	 mov	 ax,VIRTUALHIGHDOS ; Pick up SYSTEM.INI value, or default 0
	 mov	 RMI_REF_DATA.REF_VHD_SIZE,ax ; Update reference data

	 REGREST <es,si,dx,cx,bx,ax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CALC_PAGES 	; End RMI_CALC_PAGES procedure

	 page
BeginProc RMI_INT67B,PUBLIC	; Dummy INT 67h for EMS disk cache testing
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_INT67B

DESCRIPTION:
	Temporary dummy INT 67h handler used during the EMS disk
	cache testing code.

	If this handler gets called, a flag is set to indicate that
	a disk cache is (probably) using EMS memory.

	The EMS function code is ranged check, and another flag set if
	the function was outside the range of normal EMS functions.

	It has been known to yield a false positive return when the
	DECNET is installed.

ENTRY:
	AH/AX	=	EMS function code
			Valid EMS functions in the range AH=40h to 5Dh

|

	 pushf			; Save original caller's flags

	 cmp	 ah,@VCPI	; Izit VCPI major function code?
	 je	 short RI67_VCPI ; Skip if so

	 assume  ds:_RCODE	; Tell a white lie
CSOVR	 or	 <RMI_FLAG,@RMI_INT67> ; Indicate INT 67h got called
CSOVR	 or	 <INT67_FUNC,ax> ; Remember the function for later
	 assume  ds:nothing	; Cover the tracks

	 cmp	 ah,40h 	; Izit below the lowest EMS function?
	 jb	 short @F	; Skip if so

	 cmp	 ah,5Dh 	; Izit above the highest EMS function?
	 ja	 short @F	; Skip if so

; We've got a real EMS function call

	 assume  ds:_RCODE	; Tell a white lie
CSOVR	 or	 <RMI_FLAG,@RMI_EMSCACHE> ; Indicate a real EMS service got used
	 assume  ds:nothing	; Cover the tracks
@@:
	 REGSAVE <eax,bx,es>	; Save around restoration

	 les	 bx,INFO.INFO_C67 ; Get vector to QMAX.SYS's INT 67h handler
	 assume  es:nothing	; Tell the assembler

	 cli			; Let's not get caught with our pants down

	 mov	 eax,MAXEMS_0	; Get 1st 4 original bytes of MAX's handler
	 mov	 es:[bx],eax	; Restore 'em
	 mov	 al,MAXEMS_4	; Get last of the 5 bytes
	 mov	 es:[bx+4],al	; Restore it

	 REGREST <es,bx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler

RI67_VCPI:
	 popf			; Restore original caller's flags

	 jmp	 QMAX_INT67	; Rejoin original INT 67h handler in QMAX.SYS

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_INT67B		; End RMI_INT67B interrupt handler

	 page
BeginProc RMI_CHK_16M,PUBLIC	; Check on systems with 16 MB or more
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_16M

DESCRIPTION:
	Check on possible troubles with systems having more than
	16 Meg of RAM.	A flag is set in the QMAXINFO structure
	if the system has memory over 16 Meg that can't be properly
	handled.

	Complain about it if the condition is found and fail the
	Windows startup.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 cmp	 WIN386_VER,030Ah	; Izit WIN386 3.10 or better?
	 jae	 short RC16_XIT 	; Memory above 16 MB is cool for 3.10

	 test	 INFO.INFO_CMD,@CMD_OVR16 ; Check > 16 MB flag
	 jz	 short RC16_XIT ; Skip complaints if not set (CF=0)

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_16M_NONSUP ; Common error text

	 test	 INFO.INFO_CM2,@CM2_SHD ; Did we recover C&T shadow memory
	 jnz	 short RC16_REDUCE ; Yes, shadow RAM not the problem

	 cmp	 INFO.INFO_SHD,0 ; Have we recovered shadow memory
	 jz	 short RC16_REDUCE ; No, shadow RAM not the problem

	 DOSCALL @STROUT,MSG_16M_NOXRAM ; Suggest they try NOXRAM

	 jmp	 short RC16_ERRXIT ; Join common error exit

RC16_REDUCE:
	 DOSCALL @STROUT,MSG_16M_REDUCE ; Pull the chips

RC16_ERRXIT:
	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting
	 stc			; Error indicator

RC16_XIT:
	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHK_16M		; End RMI_CHK_16M procedure

	 page
BeginProc RMI_SMARTAAR,PUBLIC	; Check for presence of SMARTDRV
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_SMARTAAR

DESCRIPTION:
	Open the SMARTAAR device driver used with the old SMARTDRV.SYS
	and get its IOCTL bits.

	Use the INT 2Fh API to check for SMARTDRV 4 and its double buffer.

EXIT:
	SMART_IOCTL filled in.
	@RMI_SMART4_DB flag set if SMARTDRV 4 found to be double buffering.

|

	 pusha				; Save caller's registers
	 REGSAVE <es>			; ...

	 mov	 SMART_IOCTL,0		; Assume SMARTAAR not present

	 mov	 al,02h 		; R/W access
	 DOSCALL @OPENF2,DEVNAME_SMART	; Attempt to open SMARTDRV device driver
	 jc	 short RSA_SNS2 	; Exit if SMARTDRV.SYS not loaded

	 mov	 bx,ax			; Move handle to proper register

	 mov	 al,00h 		; Sub function to get device information
	 DOSCALL @IOCTL2		; Return in DX
	 jc	 short RSA_SNS		; Exit if SMARTDRV.SYS not loaded

	 mov	 SMART_IOCTL,dx 	; Save IOCTL bits
RSA_SNS:
	 DOSCALL @CLOSF2		; Close SMARTAAR device driver
RSA_SNS2:

; Check for SMARTDRV 4

	 push	 ds			; MOV ES,DS
	 pop	 es			; ...
	 assume  es:_RCODE		; Tell the assembler

	 and	 RMI_FLAG,(not @RMI_SMART4_DB) ; Assume no SMARTDRV 4

	 mov	 ax,4A10h		; Multiplexor code for SMARTDRV 4
	 sub	 bx,bx			; Installation check subfunction
	 int	 2Fh			; DOS multiplexor services

	 cmp	 ax,BABE		; SMARTDRV 4 installed and repsonding?
	 jne	 short RSA_XSMART4	; Exit if not

	 test	 RMI_FLAG,@RMI_KRNLFND	; Did we find and open KRNL386.EXE?
	 jz	 short RSA_USE_DRIVE_C	; No, so use C:

	 lea	 si,PATH_BUF		; DS:SI ==> filespec for KRNL386.EXE
	 lea	 di,LINEBUF		; ES:DI ==> TRUENAME buffer
	 DOSCALL @FIXPTH		; Canonize path in DS:SI to ES:DI
	 jc	 short RSA_USE_DRIVE_C	; Just use C: if it fails

	 sub	 bx,bx			; Zero to use as WORD
	 mov	 bl,LINEBUF		; Drive letter from TRUENAME
	 sub	 bx,'A'                 ; A = 0, B = 1, etc.
	 mov	 ax,(@IOCTL2 shl 8) or 09h ; 'Is drive remote' function
	 int	 21h			; DOS services
					; DX = flags, bit 12 = remote
	 jc	 short RSA_USE_DRIVE_C	; Just use C: if it fails

	 mov	 al,LINEBUF		; Drive letter
	 test	 dx,@4409_REMOTE	; Is it remote?
	 jz	 short RSA_GOT_DRIVE	; Rejoin common code if not

RSA_USE_DRIVE_C:
	 mov	 al,'C'                 ; Assume C:
RSA_GOT_DRIVE:
	 sub	 ah,ah			; Zero to use as WORD
	 sub	 ax,'A'                 ; A = 0, B = 1, etc.
	 mov	 bp,ax			; Drive #

	 mov	 ax,4A10h		; Multiplexor code for SMARTDRV 4
	 mov	 bx,5			; Double buffer status for drive BP
	 int	 2Fh			; SMARTDRV 4 services
					; ES:DI ==> undocumented status buffer
					; Actually the entire thing is a secret
	 assume  es:nothing		; Tell the assembler

	 cmp	 ax,BABE		; This drive double buffered?
	 jne	 short RSA_XSMART4	; Skip if not

	 or	 RMI_FLAG,@RMI_SMART4_DB ; SMARTDRV 4 is double buffering
RSA_XSMART4:
	 REGREST <es>			; Restore caller's registers
	 popa				; ...

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_SMARTAAR		; End SMARTAAR procedure

	 page
BeginProc RMI_CHK_BM,PUBLIC	; Check on busmaster & SMARTDRV problems
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_BM

DESCRIPTION:
	Check the QMAXINFO flag indicating the NOSCSI flags is set
	or the busmaster tests have failed.  If set, check for a valid
	BUSMASTER=VDS environment variable.  If that is not found,
	ensure that SMARTDRV (or something that acts like it) is loaded.
	If not, tell 'em about the trashed disk they are about to have
	on their hands and fail the Windows startup.

|

	 REGSAVE <ax,dx,si,di,es> ; Save caller's registers

	 test	 INFO.INFO_CM2,@CM2_XSCSI ; Check busmaster flag
	 jz	 short RCB_NOBUS ; Skip checking the override stuff

	 push	 offset _RCODE:ENVNAM_BM	; ==> "BUSMASTER"
	 push	 offset _RCODE:ENVSTR_VDS	; ==> "VDS"
	 push	 offset _RCODE:MSG_SMART_BOV	; ==> error prefix
	 call	 RMI_CHKENV	; Look for it in the environment strings
	 jc	 short RCB_XIT	; Jump if override buggered
	 jnz	 short RCB_NO_OVERRIDE ; Jump if legal override not found

RCB_OVERRIDE:
; CM2_XSCSI is set and the BUSMASTER environment variable is present
; Display a mild warning, and continue

if @SMARTDRV_WARNINGS
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_SMART_OVER ; Display the mild warning
endif				; IF @SMARTDRV_WARNINGS

	 clc			; Normal return indicator

	 jmp	 short RCB_XIT	; Join exit code

RCB_NO_OVERRIDE:

; No override exists, check IOCTL bits for old SMARTDRV

	 mov	 dx,SMART_IOCTL 	; Get IOCTL bits
	 and	 dx,@IOCTL_DEV+@IOCTL_CTRL ; Isolate bits of interest
	 cmp	 dx,@IOCTL_DEV+@IOCTL_CTRL ; A device that can process IOCTL?
	 je	 short RCB_NOBUS	; Exit OK if old SMARTDRV is loaded

; No override exists, and old SMARTDRV isn't loaded -- check for SMARTDRV 4

	 test	 RMI_FLAG,@RMI_SMART4_DB ; Is SMARTDRV 4 double buffering?
	 jnz	 short RCB_NOBUS	; Exit OK if SMARTDRV 4 is loaded
					; ... and double buffering

; Busmaster and no override and no SMARTDRV-type disk cache
; See section on SMARTDRV in WINDOWS.DOC

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already
	 DOSCALL @STROUT,MSG_SMART_SNS ; SMARTDRV not loaded
	 DOSCALL @STROUT,MSG_SMART_SWD ; Please see WINDOWS.DOC

	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting
	 stc			; Error indicator

	 jmp	 short RCB_XIT	; Rejoin common exit code

RCB_NOBUS:
	 clc			; Normal return indicator
RCB_XIT:
	 REGREST <es,di,si,dx,ax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_CHK_BM		; End RMI_CHK_BM procedure

	 page
FCS_STR  struc			; Structure to access immediate FAR JMP code

FCS_OPCODE db	 ?		; Opcode for immediate FAR JMP
FCS_OFF  dw	 ?		; Offset
FCS_SEG  dw	 ?		; Segment

FCS_STR  ends			; End FCS_STR structure

BeginProc RMI_CHK_EMSDISK,PUBLIC ; Check for EMS-using disk caches
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_EMSDISK

DESCRIPTION:
	Check for EMS-using disk caches.

	Patch a far call to our local INT 67h handler into the handler
	in QMAX.SYS.  Open and read all of KRNL386.EXE.  Our local handler
	will set a bit indicating it has been called.
	Unpatch QMAX.SYS.  If the bit is set, tell 'em they've got
	a disk cache using EMS memory and fail the Windows startup.

	The MS-DOS environment variable EMSCACHE=OK will allow Windows
	to start anyway.

|

	 REGSAVE <eax,cx,dx,si,di,bp,es> ; Save caller's registers

	 and	 RMI_FLAG,(not @RMI_KRNLFND) ; Kill 'found KRNL386' bit

; Check for valid overrides

	 push	 offset _RCODE:ENVNAM_EC	; ==> "EMSCACHE"
	 push	 offset _RCODE:ENVSTR_OK	; ==> "OK"
	 push	 offset _RCODE:MSG_EMSDC_BOV	; ==> error prefix
	 call	 RMI_CHKENV	; Look for it in the environment strings
	 jc	 RCE_XIT	; Jump if override buggered
	 jz	 RCE_OK 	; Jump if legal override found

COMMENT|
Try to open KRNL386.EXE.  Look in the following places:

1) %windir%\KRNL386.EXE
2) %windir%\SYSTEM\KRNL386.EXE
3) .\KRNL386.EXE
4) .\SYSTEM\KRNL386.EXE
5) The path to WIN386.EXE, from its own PSP
6) Every directory specified in the PATH, with and w/o '\SYSTEM' appended.

If we can't open if after all these attempts, we'll assume that
Windows isn't going to work anyway and that there is an EMS disk cache present
|

RCE_NOOVR:
	 mov	 ax,ds		; Get addressibility to _RCODE...
	 mov	 es,ax		; ... via ES
	 assume  es:_RCODE	; Tell the assembler

; (1) Try %windir%\KRNL386.EXE

	 call	 RMI_GET_WINDIR ; Fill in PATH_BUF from 'windir' environ var
	 jc	 RCE_XWINDIR	; Skip to PATH attempts if no 'windir'

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it
	 jnc	 RCE_OPENED	; Rejoin common code if it opened OK

; (2) %windir%\SYSTEM\KRNL386.EXE

	 call	 RMI_GET_WINDIR ; Fill in PATH_BUF from 'windir' environ var
	 jc	 RCE_XWINDIR	; Skip to PATH attempts if no 'windir'

; Append '\SYSTEM' to PATH_BUF

	 lea	 si,SYSTEM_PATH ; Pointer to '\SYSTEM'
	 mov	 cx,@SYSTEM_PATH_L ; Get length of above sub-directory
S16	 rep movsb		; Copy sub-directory to end of path

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it
	 jnc	 RCE_OPENED	; Rejoin common code if it opened OK

; (3) Try .\KRNL386.EXE

RCE_XWINDIR:
	 mov	 PATH_BUF,'.'   ; Put '.', '\0' in the path buffer
	 mov	 PATH_BUF+1,0	; ...
	 lea	 di,PATH_BUF+2	; ES:DI ==> path buffer, past the '.', '\0'

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it
	 jnc	 RCE_OPENED	; Rejoin common code if it opened OK

; (4) Try .\SYSTEM\KRNL386.EXE

	 mov	 PATH_BUF,'.'   ; Put '.' in the path buffer
	 lea	 di,PATH_BUF+1	; ES:DI ==> path buffer, past the '.'

	 lea	 si,SYSTEM_PATH ; Pointer to '\SYSTEM'
	 mov	 cx,@SYSTEM_PATH_L ; Get length of above sub-directory
S16	 rep movsb		; Copy sub-directory to end of path

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it
	 jnc	 RCE_OPENED	; Rejoin common code if it opened OK

; (5) Path to WIN386.EXE, from its own PSP

; Find WIN386's PSP and then scan its environment to find the string section

	 DOSCALL @GETPSP	; Get current PSP into BX
	 mov	 es,bx		; Get addressibility to PSP
	 assume  es:PSPSEG	; Tell the assembler

	 mov	 es,PSP_ENVIR_PTR ; Get segment of environment strings
	 assume  es:nothing	; Tell the assembler

	 sub	 di,di		; Offset of 1st string
	 mov	 cx,8000h	; Biggest environment we're going to encounter
	 sub	 al,al		; A handy zero
@@:
   repne scasb			; Search for the NUL terminator

	 cmp	 es:[di].LO,0	; Was it the last string?
	 jne	 short @B	; Nope, so keep going

	 inc	 di		; Bump past extra NUL

				; ES:DI ==> string count word
	 cmp	 es:[di].ELO,1	; Is there at least one string present?
	 jb	 short TRY5_BAD ; Skip if not

	 lea	 di,[di+2]	; DS:DI ==> WIN386 full pathname
	 mov	 si,di		; DS:SI ==> WIN386 fill pathname

; Scan to the end of the string, then scan backwards to the first '\'

	 mov	 cx,8000h	; Biggest environment
	 sub	 al,al		; Scan for a terminating NUL
   repnz scasb			; Look for end of string

@@:
	 cmp	 es:[di-1].LO,'\'       ; Is the previous char the last '\'?
	 je	 short TRY5_COPYPATH	; Exit loop if so

	 dec	 di		; Back up to previous character

	 cmp	 di,si		; Make sure we don't run off the front
	 ja	 short @B	; Go around again if still within bounds

	 jmp	 short TRY5_BAD ; The string is buggered up in some way

TRY5_COPYPATH:

; ES:DI ==> character just after last '\' in pathname

	 cmp	 es:[di].LO,'w' ; It better be the 'w' in WIN386.EXE
	 je	 short @F	; The string is cool

	 cmp	 es:[di].LO,'W' ; ... or 'W'
	 jne	 short TRY5_BAD ; The string is buggered up in some way
@@:
	 lea	 cx,[di-2+1]	; ES:CX ==> '\'
	 sub	 cx,si		; CX = length of path to copy

; Copy path portion of WIN386 full pathname to our buffer

	 lea	 di,PATH_BUF	; ES:DI ==> path buffer

	 REGSAVE <ds>		; Save our DS

	 REGSAVE <ds,es>	; Swap DS and ES ...
	 REGREST <ds,es>	; ...
	 assume  es:_RCODE, ds:nothing
				; DS:SI ==> WIN386's full pathname
				; ES:DI ==> path buffer

S16  rep movsb			; Copy WIN386's path to our buffer

	 REGREST <ds>		; Restore our DS
	 assume  ds:_RCODE	; Tell the assembler

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it
	 jnc	 short RCE_OPENED ; Rejoin common code if it opened OK

TRY5_BAD:

; This scheme failed to find KRNL386.EXE.  Fall through into the next scheme.

TRY6:

; (6) Search the PATH for KRNL386.EXE

	 lea	 si,ENVNAM_PATH ; Get offset to "PATH"
	 call	 RMI_GETENV	; Find it in the environment strings
	 assume  es:nothing	; ES:DI ==> text of PATH environment variable
	 jc	 RCE_NODIR	; Bugout if unable to get a search PATH

; We assume the PATH is of a reasonable form.  We got this far so it must be...

; Copy the next item from the PATH into PATH_BUF.

	 mov	 dx,di		; ES:DX ==> next PATH item
	 REGSAVE <ds,es>	; Swap DS and ES ...
	 REGREST <ds,es>	; DS:SI ==> next PATH item
	 assume  es:_RCODE, ds:nothing

; Copy the next item from the PATH into PATH_BUF up to a ';' or a NUL.

RCE_NEXTPATH:
	 lea	 di,PATH_BUF	; ES:DI ==> PATH_BUF
	 mov	 si,dx		; DS:SI ==> next PATH item

	 cmp	 [si].LO,0	; Have we exhausted the path?
	 jz	 short RCE_XPATHS ; Give up search if so

@@:
	 lodsb			; Pick up next character of PATH item

	 cmp	 al,';'         ; Izit a separating ';'?
	 je	 short @F	; Exit loop if so

	 or	 al,al		; Izit the terminating NUL?
	 jz	 short @F	; Exit loop if so

	 stosb			; Save another character in PATH_BUF

	 jmp	 short @B	; Get 'em all

@@:
	 mov	 dx,si		; Save pointer to next PATH item

; PATH_BUF contains the next item from the path

	 mov	 bp,di		; Save pointer to end of PATH_BUF+1

	 REGSAVE <ds,es>	; Save segment registers around RMI_OPENKRNL

	 REGSAVE <ds,es>	; Swap 'em 'round
	 REGREST <ds,es>	; ...
	 assume  ds:_RCODE, es:nothing

	 call	 RMI_OPENKRNL	; Append KRNL386.EXE and try to open it

	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:nothing, es:_RCODE

	 jnc	 short RCE_SOPENED ; Rejoin common code if it opened OK

	 mov	 di,bp		; Restore pointer to end of PATH_BUF+1

	 REGSAVE <ds,es>	; Save segment registers around RMI_OPENKRNL

	 push	 ds		; Save around REP MOVSB

	 push	 es		; Get addressibility to _RCODE ...
	 pop	 ds		; ... via DS
	 assume  ds:_RCODE	; Tell the assembler

	 lea	 si,SYSTEM_PATH 	; Pointer to '\SYSTEM'
	 mov	 cx,@SYSTEM_PATH_L	; Get length of above sub-directory
S16	 rep movsb			; Copy sub-directory to end of path

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 REGSAVE <ds,es>	; Swap 'em 'round
	 REGREST <ds,es>	; ...
	 assume  ds:_RCODE, es:nothing

	 call	 RMI_OPENKRNL		; Append KRNL386.EXE and try to open it
	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:nothing, es:_RCODE

	 jnc	 short RCE_SOPENED	; Rejoin common code if it opened OK?

; Go back and try the next item from the PATH

	 jmp	 short RCE_NEXTPATH	; Try 'em all

; We've exhausted the path, and didn't find KRNL386.EXE

RCE_XPATHS:
	 push	 es		; Restore addressibility to _RCODE ...
	 pop	 ds		; ... via DS
	 assume  ds:_RCODE, es:nothing	; Tell the assembler

; We couldn't open the file, so it's unlikely that the SHELL VxD will either.
; Tell 'em it can't be opened, and fail the Windows startup.

	 jmp	 RCE_NODIR	; Bugout if all open attempts failed

; We've managed to open KRNL386.EXE.  Reload DS.

RCE_SOPENED:
	 push	 es		; Restore addressibility to _RCODE ...
	 pop	 ds		; ... via DS
	 assume  ds:_RCODE, es:nothing	; Tell the assembler

RCE_OPENED:

; Set a bit to remember we found KRNL386.EXE for the SMARTDRV double buffer
; tests later.

	 or	 RMI_FLAG,@RMI_KRNLFND	; We found and opened KRNL386.EXE

	 test	 RMI_FLAG,@RMI_EMSCACHE ; Did EMS get used during the open?
	 jnz	 short RCE_CLOSE ; Yes, so forget the rest

	 mov	 bx,ax		; Move handle to proper register

; Prepare and patch into QMAX.SYS's EMS handler

	 and	 RMI_FLAG,(not @RMI_EMSPATCH) ; QMAX.SYS' EMS is NOT patched

	 REGSAVE <bx,es>	; Save registers around patch code

; Set the DBG_FLAG.@DBG_X67 bit in QMAX.SYS so INT 67 will go through the
; RESINT67 handler.

; Get state of DEBUG=X67 bit.  Set if needed.

	 test	 INFO.INFO_DBG,@DBG_X67 ; Are we passing INT 67h to RESINT67?
	 jnz	 short @F	; Yes, so skip the EMM2CALL

	 mov	 bx,@DBG_X67	; Bit we want to toggle (set) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:

; Patch ourselves into QMAX.SYS's INT 67h handler
; N.B. Bob has provided a 5-byte area for this to be safely pulled off

	 les	 bx,INFO.INFO_C67 ; Get vector to QMAX.SYS's INT 67h handler
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,bx		; Offset within QMAX.SYS
	 add	 ax,1+2+2	; Bump past the FAR JMP immediate

	 mov	 QMAX_INT67.VOFF,ax	; Remember for chaining later
	 mov	 QMAX_INT67.VSEG,es	; ...

	 pushf			; Save flags
	 cli			; Disable around patching

	 mov	 eax,es:[bx]	; Get 1st 4 bytes of MAX's handler
	 mov	 MAXEMS_0,eax	; Save
	 mov	 al,es:[bx+4]	; Get last of 5 bytes we'll be patching
	 mov	 MAXEMS_4,al	; Save

	 mov	 es:[bx].FCS_OPCODE,@OPCOD_JMPF ; Patch in immediate FAR JMP
	 lea	 ax,RMI_INT67B	; Offset of our EMS handler
	 mov	 es:[bx].FCS_OFF,ax ; Stuff in our offset
	 mov	 es:[bx].FCS_SEG,cs ; ... and our code segment

	 popf			; Reenable if appropriate

	 or	 RMI_FLAG,@RMI_EMSPATCH ; QMAX.SYS' EMS handler is patched

	 REGREST <es,bx>	; Restore registers around patch code
	 assume  es:nothing	; Tell the assembler

; Read from KRNL386.EXE

RCE_RDLP:
	 mov	 cx,@EMS_BUF_L	; Length to read in bytes
	 DOSCALL @READF2,EMS_BUF ; Read from file BX, to DS:DX
	 jc	 short RCE_CLOSE ; Close file if read failed

	 test	 RMI_FLAG,@RMI_EMSCACHE ; Did EMS services get used?
	 jnz	 short RCE_CLOSE ; Yes, so forget the rest

	 cmp	 ax,@EMS_BUF_L	; Did we get a whole buffer full?
	 je	 short RCE_RDLP ; Yes, go try for more

; We've read the entire file without an error

; Close KRNL386.EXE

RCE_CLOSE:
	 DOSCALL @CLOSF2	; Close KRNL386.EXE file

; Restore original INT 67h handler contents

	 test	 RMI_FLAG,@RMI_EMSPATCH ; Is QMAX.SYS' EMS handler patched?
	 jz	 short RCE_NOTPATCHED ; Nope, so don't unpatch it

	 REGSAVE <eax,bx,es>	; Save around restoration
	 les	 bx,INFO.INFO_C67 ; Get vector to QMAX.SYS's INT 67h handler
	 assume  es:nothing	; Tell the assembler

	 pushf			; Save flags
	 cli			; Disable around patching

	 mov	 eax,MAXEMS_0	; Get 1st 4 original bytes of MAX's handler
	 mov	 es:[bx],eax	; Restore 'em
	 mov	 al,MAXEMS_4	; Get last of the 5 bytes
	 mov	 es:[bx+4],al	; Restore it

	 popf			; Reenable if appropriate

	 REGREST <es,bx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler

; Clear the DEBUG=X67 bit if we set it earlier

	 test	 INFO.INFO_DBG,@DBG_X67 ; Was it already set?
	 jnz	 short @F	; Yes, so don't clear it

	 mov	 bx,@DBG_X67	; Bit we want to toggle (clear) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:

RCE_NOTPATCHED:

; If we got an EMS call during the reads, complain about it

	 test	 RMI_FLAG,@RMI_EMSCACHE ; Did EMS services get used?
	 jnz	 short RCE_EMSUSED ; Yes, so warn 'em about it

; No true EMS services got used.  Test for any other INT 67h users

	 test	 RMI_FLAG,@RMI_INT67 ; Did INT 67h get called at all?
	 jz	 short RCE_OK	; Nope, exit normally

ifdef @DEBUG
	 BREAK			; Call the debugger
endif				; IFDEF @DEBUG

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 mov	 ax,INT67_FUNC	; INT 67h function used
	 mov	 cx,4		; Number of hex digits in function code
	 lea	 di,MSG_INT67_H ; ==> message text
	 call	 RMI_TOHEX	; Format into message text

	 DOSCALL @STROUT,MSG_INT67 ; Warn about INT 67h use

	 jmp	 short RCE_STC	; Rejoin common error exit code

RCE_EMSUSED:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_EMSDC ; Warn about EMS disk caching

	 jmp	 short RCE_STC	; Rejoin common error exit code

	 assume  es:nothing	; Tell the assembler

; Error exit used when there is no 'windir' environment variable or we
; couldn't open KRNL386.EXE for some other reason.
; Fail the Windows startup

RCE_NODIR:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_NOKRNL ; Warn about KRNL386.EXE

;;;;;;	 jmp	 short RCE_STC	; Rejoin common error exit code

RCE_STC:
	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting
	 stc			; Error indicator

	 jmp	 short RCE_XIT	; Join common error code

RCE_OK:
	 clc			; Normal return indicator

RCE_XIT:
	 REGREST <es,bp,di,si,dx,cx,eax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHK_EMSDISK	; End RMI_CHK_EMSDISK procedure

	 page
BeginProc RMI_OPENKRNL,PUBLIC	; Append KRNL386.EXE and try to open it
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_OPENKRNL

DESCRIPTION:
	Subroutine for RMI_CHK_EMSDISK to append 'KRNL386.EXE' to the
	filename buffer and attempt to open the file.

ON EXIT:
	If carry set, the open failed.
	If carry clear, AX = file handle.

|

	 REGSAVE <cx,dx,si,es>	; Save caller's registers

	 push	 ds		; Get addressibility to _RCODE ...
	 pop	 es		; ... via ES
	 assume  es:_RCODE	; Tell the assembler

; Append '\KRNL386.EXE' to PATH_BUF

	 lea	 si,KRNL386_FILE	; Pointer to '\KRNL386.EXE', 0
	 mov	 cx,@KRNL386_FILE_L	; Get length of above filename
S16	 rep movsb			; Copy filename to end of path

; Attempt to open it

	 mov	 al,0			; R/O access
	 DOSCALL @OPENF2,PATH_BUF	; Open SYSTEM\KRNL386.EXE

	 REGREST <es,si,dx,cx>	; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_OPENKRNL		; End RMI_OPENKRNL procedure

	 page
BeginProc RMI_GETENV,PUBLIC	; Search environment for string
	 assume  ds:_RCODE, es:_RCODE, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GETENV

DESCRIPTION:
	Search the MS-DOS environment for a particular variable

ENTRY:
	DS:SI ==> string to search for

EXIT:
	If carry clear:
		ES:DI ==> text of string, if found

	If carry set:
		the variable was not found

|

	 REGSAVE <ax,cx,si>	; Save caller's registers

; Find end of search string

	 mov	 di,si		; Copy start of string to proper register
	 mov	 cx,8000h	; Look forever
	 sub	 al,al		; Scan for a terminating NUL
	 repnz scasb		; Look for end of string
	 mov	 cx,di		; Offset to last byte
	 sub	 cx,si		; Less start offset is length to compare
	 dec	 cx		; Less the NUL

	 DOSCALL @GETPSP	; Get current PSP into BX
	 mov	 es,bx		; Get addressibility to PSP
	 assume  es:PSPSEG	; Tell the assembler

	 mov	 es,PSP_ENVIR_PTR ; Get segment of environment strings
	 assume  es:nothing	; Tell the assembler

	 sub	 di,di		; Address of 1st string

RMI_GETENV_NXT:
	 cmp	 es:[di].LO,0	; Last string?
	 jz	 short RMI_GETENV_NOF ; Jump if never found

	 push	 cx		; Save search length
	 push	 si		; Save start of search string
	 repe cmpsb		; Compare strings
	 pop	 si		; Restore start of search string
	 pop	 cx
	 jz	 short RMI_GETENV_OK ; Jump if we've found it

; This string didn't match.  Scan ahead to start of next string

	 push	 cx		; Save search length

	 mov	 cx,8000h	; Scan to start of next string
	 repnz scasb		; Find terminating NUL

	 pop	 cx		; Restore search length
	 jmp	 short RMI_GETENV_NXT	; On to next string

; Never found the search string in the environment

RMI_GETENV_NOF:
	 stc			; Indicate failure to find search string

	 jmp	 short RMI_GETENV_XIT ; Join common exit code

; Found the search string.  DI points to contents of string

RMI_GETENV_OK:
	 clc			; Indicate we've found it

	 inc	 di		; Bump past the '=', ptr returned in ES:DI
RMI_GETENV_XIT:
	 REGREST <si,cx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GETENV		; End RMI_GETENV procedure
	 page
BeginProc RMI_CHKENV,PUBLIC	; Check override environment variables
	 assume  ds:_RCODE, es:_RCODE, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHKENV

DESCRIPTION:
	Check an environment variable used to override a warning.

ENTRY:
	Passed on the stack:
	==> environment variable name
	==> text after the '='
	==> error message text if faulty

EXIT:
	If carry set:
		Error in the variable.

	If carry clear and zero clear:
		The variable isn't set.

	If carry clear and zero set:
		The variable is set.

|

CHKENV_STR	 struc		; Structure to access stacked arguments

	 dw	 ?		; ...	   BP
	 dw	 ?		; Caller's IP
CE_ERROR dw	 ?		; ==> error message prefix
CE_ENVVAL dw	 ?		; ==> environment variable value
CE_ENVNAM dw	 ?		; ==> environment variable name

CHKENV_STR	 ends		; End CHKENV_STR structure

	 push	 bp		; Save previous stack frame
	 mov	 bp,sp		; Prepare new stack frame

	 REGSAVE <ax,dx,si,di,es>	; Save caller's registers

	 mov	 si,[bp].CE_ENVNAM	; ==> variable name
	 call	 RMI_GETENV		; Find it in the environment strings
	 assume  es:nothing		; Tell the assembler
	 jc	 short CE_NCNZ		; Jump if override not possible

; ES:DI ==> environment variable value

	 mov	 si,[bp].CE_ENVVAL	; ==> variable value
	 call	 RMI_CMPSBI		; Case insensitive REPE CMPSB
	 je	 CE_NCZR		; Jump if legal option found

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 mov	 dx,[bp].CE_ERROR	; ==> error message prefix
	 mov	 ah,@STROUT		; Display text at DS:DX
	 int	 21h			; DOS services
@@:
	 mov	 al,es:[di]	; Get next character
	 inc	 di		; Bump pointer
	 or	 al,al		; Is it the end of a string?
	 jz	 short @F	; Yes, exit display loop

	 mov	 dl,al		; Move character to proper register for DOS
	 DOSCALL @CHROUT	; Display character

	 jmp	 short @B	; Go back for more

@@:
	 DOSCALL @STROUT,MSG_CHKENV_BOV ; Bad override suffix
	 DOSCALL @STROUT,MSG_PSWD	; Please see WINDOWS.DOC

	 or	 RMI_FLAG,@RMI_FAIL	; Prevent Windows from starting

	 stc			; Return CY if bad override

	 jmp	 CE_XIT 	; Rejoin common exit code

CE_NCNZ:
	 sub	 ax,ax		; NC, ZR
	 inc	 ax		; NC, NZ

	 jmp	 CE_XIT 	; Rejoin common exit code

CE_NCZR:
	 sub	 ax,ax		; NC, ZR

CE_XIT:
	 REGREST <es,di,si,dx,ax>	; Restore caller's registers
	 assume  es:nothing		; Tell the assembler

	 pop	 bp			; Restore previous stack frame

	 ret	 (3*2)			; Return to caller, popping arguments

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHKENV		; End RMI_CHKENV procedure

	 page
BeginProc RMI_CHK_DUPVXD,PUBLIC ; Check for duplicate VxD installation
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_DUPVXD

DESCRIPTION:
	Check for duplicate VxD installation via either SYSTEM.INI or
	another link in the 1605 startup chain.

	If we're a duplicate, complain about it and fail the
	Windows startup.

EXIT:
	Carry set if duplicate VxD installation is attempted.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 test	 RMI_BX,Duplicate_Device_ID ; Check for stupid installations
	 clc			; Assume its all OK
	 jz	 short @F	; 1st time through so it is OK

	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_DUP_DEVICE ; Piss and moan about it

	 stc			; Return error indicator
@@:
	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_CHK_DUPVXD 	; End RMI_CHK_DUPVXD procedure

ifdef @DOSMAX
	 page
BeginProc RMI_DOSMAX,PUBLIC	; Check for DOSMAX problems
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_MAXSTACKS

DESCRIPTION:
	Ensure 386MAX.SYS is providing DOS stacks for the DOSMAX.

	Ensure we're not on a 512K motherboard.

	If we're updating an older 386MAX.SYS, we won't be providing
	DOSMAX support, so skip this check.

|

	 REGSAVE <ax,dx>		; Save caller's registers

; Check for retrofit situations
	 cmp	 REFDATA_VER,@REF_STRUC_VER ; Izit the one we know, or newer?
	 jb	 short RCM_EXITOK	; Don't check for an older 386MAX

; Check for short low DOS systems
	 int	 12h			; Get DOS base memory size into AX
	 cmp	 ax,640 		; Is it less than a full load?
	 jae	 short @F		; Skip if not

	 or	 RMI_REF_DATA.REF_R2PFLAG,@R2P_SHORT ; Disable DOSMAX
@@:

; Check for missing 386MAX stacks
	 cmp	 RMI_REF_DATA.REF_LaDSTK_TAB,0 ; MAX stacks present?
	 jz	 short RCM_BITCH	; Tell 'em DOSMAX won't work

	 cmp	 RMI_REF_DATA.REF_DSTK_CNT,0 ; Double check
	 jnz	 short RCM_EXITOK	; Exit if stacks are present

RCM_BITCH:
	 call	 RMI_SHOW_BANNER	; Display banner if needed
	 DOSCALL @STROUT,MSG_NOSTACKS	; Display the warning

	 call	 RMI_PAUSE	; Display 'press any key' and wait for key press
				; Carry indicates they hit ESCape
				; The set carry flag is returned to our caller
	 jmp	 RCM_EXIT		; Rejoin common exit code

RCM_EXITOK:
	 clc				; Normal return indicator

RCM_EXIT:
	 REGREST <dx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_DOSMAX			; End RMI_DOSMAX procedure
endif					; IFDEF @DOSMAX
	 page
BeginProc RMI_SCAN_LSEG,PUBLIC	; Scan LSEG chain looking for pgm name
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_SCAN_LSEG

DESCRIPTION:
	Scan the QMAX.SYS LSEG chain looking for a a particular
	TSR or device driver by name.
	If found loaded in high DOS return CY.

ENTRY:
	DS:SI ==> program name in which we're interested.

EXIT:
	Carry set if program was found in LSEG chain in high DOS memory.

|

	 REGSAVE <bx,cx,si,di,es> ; Save caller's registers

	 mov	 es,INFO.INFO_LSEG ; Get segment of LSEG chain
	 assume  es:nothing	; Tell the assembler

RSL_LNXT:
	 test	 es:[0].LSEG_FLAG,@LSEG_DRV ; Is it a device driver?
	 jz	 short RSL_LSKP ; No, so it's not our boy

; Get name of TSR or device driver file from LSEG

	 lea	 di,es:[0].LSEG_FNE ; Get pointer to file name in LSEG

	 mov	 cx,8+1+3	; Length of filename including '.'
	 push	 si		; Save pointer to name of interest
	 repe cmpsb		; Compare names
	 pop	 si		; Restore pointer to name of interest
	 jne	 short RSL_LSKP ; We didn't find it

; If LSEG_OWNRHI is NULL, GETSIZE must be in effect.

	 cmp	 es:[0].LSEG_OWNRHI,0 ; Segment of owner in high DOS (0=none)
	 je	 short RSL_LSKP ; We didn't find it in high DOS

	 stc			; Filename was found in LSEG chain

	 jmp	 short RSL_XIT	; Join common exit code

RSL_LSKP:
	 mov	 bx,es:[0].LSEG_NEXT ; Get segment of next LSEG
	 cmp	 bx,-1		; Are we at the end of all the LSEGs?
	 je	 short @F	; Exit loop if so
	 mov	 es,bx		; Set segment to next LSEG
	 assume  es:nothing	; Tell the assembler

	 jmp	 RSL_LNXT	; Go on to the next entry
@@:
	 clc			; Filename not found in LSEG chain
RSL_XIT:
	 REGREST <es,di,si,cx,bx> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_SCAN_LSEG		; End RMI_SCAN_LSEG procedure

	 page
BeginProc RMI_GETLINE,PUBLIC	; Read In A Line From A File
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GETLINE

DESCRIPTION:
	Read in a line of text from the file handle in BX.

ENTRY:
	BX = file handle

EXIT:
	Carry set if something went wrong, or EOL

	LINEBUF filled in with ASCIIZ line.

|

	 REGSAVE <ax,cx,dx,si>	; Save registers

	 mov	 cx,@LINEBUF_L ; Get buffer length
	 DOSCALL @READF2,LINEBUF ; Read it in
	 jc	 short RMI_GETLINE_EXIT ; Jump if something went wrong (CF=1)

	 mov	 cx,ax		; Copy actual amount read
	 jcxz	 RMI_GETLINE_ERR ; Jump if that's all

	 cmp	 LINEBUF,EOF	; Izit the last line?
	 je	 short RMI_GETLINE_ERR ; Jump if so

; Search for line ending

	 lea	 si,LINEBUF	; DS:SI ==> the line plus tail
@@:
	 lodsb			; Get next character

	 cmp	 al,CR		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,EOF 	; Izit EOF?
	 je	 short @F	; Jump if so

	 loop	 @B		; Jump if more characters
@@:
	 mov	 [si-1].LO,0 ; Set line terminator

; Skip over trailing line terminators

@@:
	 jcxz	 @F		; Jump if none left
	 lodsb			; Get next character
	 dec	 cx		; Account for it

	 cmp	 al,CR		; Izit EOL?
	 je	 short @B	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @B	; Jump if so

	 cmp	 al,EOF 	; Izit EOF?
	 je	 short @B	; Jump if so
@@:

; Back up the file pointer to point to the next line

	 mov	 dx,cx		; Copy low-order of amount to move
	 xor	 cx,cx		; Zero high-...

	 neg	 dx		; Negate to move backwards
	 sbb	 cx,0		; In case of underflow
	 mov	 al,1		; Method = from current position
	 DOSCALL @MOVFP2	; Move the file pointer
RMI_GETLINE_DONE:
	 clc			; Mark as OK

	 jmp	 short RMI_GETLINE_EXIT ; Join common exit code

RMI_GETLINE_ERR:
	 stc			; Mark as all over
RMI_GETLINE_EXIT:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; RetReturn to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GETLINE		; End RMI_GETLINE procedure

	 page
BeginProc RMI_MAX_OPEN,PUBLIC	; Check for 386MAX$$ device presence
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_MAX_OPEN

DESCRIPTION:
	Open 386MAX$$, ensure it's a character device driver.
	Read in the QMAXINFO structure.  Check and save the version #.
	Determine the segment of QMAX.SYS in high DOS.

EXIT:
	QMAX_VER filled in with QMAX.SYS version #.
	QMAX_DSHI filled in with segment of QMAX.SYS in high DOS.

	Carry set if 386MAX$$ could not be opened or the
	version # did not match the valid range of 5.10 - x.xx.

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

	 mov	 DEV_HNDL,0	; Clear handle so we don't close unopened files

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX$$ device driver
	 jnc	 short RMO_OK1	; Skip error code if open

RMO_NOMAX:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_NOMAX ; Tell 'em QMAX.SYS is not present

	 jmp	 RMO_ERRXIT	; Join common error exit code

RMO_BADVER:
	 call	 RMI_SHOW_BANNER ; Display banner if it hasn't been already

	 DOSCALL @STROUT,MSG_BADVER ; Tell 'em QMAX.SYS is the wrong version

	 jmp	 RMO_ERRXIT	; Join common error exit code
RMO_OK1:

; Ensure it's a device

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short RMO_NOMAX ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short RMO_NOMAX ; No???

; Get QMAXINFO structure

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,size INFO_STR ; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

; Make sure its us and versions are in order

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short RMO_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short RMO_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short RMO_NOMAX ; Not this time

COMMENT|

Originally, the 386MAX.VXD did a strict version check since it makes use
of structures within QMAX.SYS itself.  With the advent of Windows 3.10,
we need to try and work with old versions of QMAX.SYS to avoid a plethora
of tech support calls.	Also, it has become valuable to ship an updated VxD
to customers with QMAX.SYS 5.10, 5.11, and 5.12 without shipping them
an entirely new package.

386MAX.VXD versions 5.13 and above try to patch old versions of QMAX.SYS.

|

; Get the QMAX.SYS version # into a more convenient form

	 mov	 ax,INFO.INFO_VER[2].ELO ; Get minor version digits
	 sub	 ax,('0' shl 8) or '0' ; Remove ASCII digit base
	 shl	 al,4		; Shift high-order minor digit to high nibble
	 or	 al,ah		; AL = minor version #s

	 mov	 ah,INFO.INFO_VER[0] ; Get major version digit
	 sub	 ah,'0'         ; Remove ASCII digit base

	 mov	 QMAX_VER,ax	; Save for later

; Check the version # for the proper range (5.10 - x.xx)

	 cmp	 QMAX_VER,VERS_HTU	; Izit QMAX.SYS x.xx?
	 ja	 short RMO_BADVER	; Error if higher than expected

	 cmp	 QMAX_VER,510h	; Izit QMAX.SYS 5.10 or later?
	 jb	 short RMO_BADVER ; Not this time
@@:
	 push	 es		; Save

	 mov	 es,INFO.INFO_QMAX ; Get low segment of QMAX.SYS device driver
	 assume  es:nothing	; Tell the assembler

	 mov	 bx,es:[0].DD_INTR ; Get offset to interrupt routine

; If QMAX.SYS is loaded into high DOS memory,
; ES:BX will be pointing to a FAR JMP into high DOS.

; If NOLOADHI is in effect, ES:BX points to the code in
; low DOS directly so ES is already the segment for DSHI.

	 cmp	 es:[bx].LO,@OPCOD_JMPF ; Does it look like our FAR JMP?
	 jne	 short @F	; No, so NOLOADHI must be in effect

	 mov	 es,es:[bx+1].VSEG ; Get segment of QMAX.SYS in high DOS
	 assume  es:nothing	; Tell the assembler
@@:
	 mov	 QMAX_DSHI,es	; Save for use later

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler

	 clc			; Indicate all went well

	 jmp	 short RMO_XIT	; Rejoin common code

RMO_ERRXIT:
	 stc			; Indicate something went wrong
RMO_XIT:
	 pushf			; Save return flags

	 mov	 bx,DEV_HNDL	; Get the device driver handle
	 or	 bx,bx		; Izit open?
	 jz	 short @F	; Nope, so don't close it

	 DOSCALL @CLOSF2	; Close the device
@@:
	 popf			; Restore return flags

	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_MAX_OPEN		; End RMI_MAX_OPEN procedure

	 page
BeginProc RMI_PHYS2LIN,PUBLIC	; Convert physical to linear address
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_PHYS2LIN

DESCRIPTION:
	Convert physical to linear address under QMAX's page tables.

	We attempt to use the @EMM2_PHYS2LIN service.  This service
	was not available in QMAX.SYS version 5.10 or 5.11.  If the
	service fails, we use a local procedure instead.  This alternate
	code uses the @EMM2_GETPTE service.

ENTRY:
	EDX is physical address to be converted

EXIT:
	EDX is linear address under QMAX's page tables.

	Carry set if we couldn't find the physical address in the page
	table.

|

	 REGSAVE <eax,ebx,ecx,si,di,bp> ; Save caller's registers

; First try to use the PHYS2LIN EMM2CALL

	 mov	 ebx,edx	; Save physical address in case it gets wrecked

	 mov	 bp,sp		; Save current stack pointer
	 EMMOUT  @EMM2_PHYS2LIN ; Translate address of reference data
	 mov	 sp,bp		; Cut back the stack in case of error

	 or	 ah,ah		; Did it fail?
	 jz	 RMI_P2L_XIT	; Nope, so EDX = linear address (Note CF = 0)

; The PHYS2LIN EMM2CALL didn't work, propably because QMAX.SYS is too old
; Trundle through the page table entries by hand

	 mov	 ebx,edx	; Physical address for which we're searching
	 and	 ebx,not (mask $LA_OFF) ; Kill offset within 4KB page

; Due to the changes made to 386MAX.SYS to allow memory above 60 meg,
; the INFO_TOT field moved and widened.  This, of course, was done without
; any regard for the Windows support code that used it while retrofitting
; old versions.  To work around the problem, we kludge it off of the field
; sitting immediately before the old INFO_TOT position.

;	 movzx	 ecx,INFO.INFO_TOT ; Get size of extended memory
	 movzx	 ecx,INFO.INFO_MAP+2 ; Get size of extended memory
	 shr	 ecx,(2-0)	; Convert size in 1KB to size in 4KB (# PTEs)

	 lea	 ax,PTE_BUF	; DS:SI ==> local copy of PTEs
	 add	 ax,@PTE_BUFL	; ==> end of buffer
	 mov	 PTE_BUFZ,ax	; Save for end-o-buffer comparisons

	 mov	 si,(1024*1024) shr (12-2) ; Offset in PTEs to 1 Meg line (400h)

	 jmp	 short RMI_P2L_JAM ; Jam into the middle of the loop

RMI_P2L_NXT:
	 cmp	 si,PTE_BUFZ	; Are we at the end of the buffer?
	 jb	 short RMI_P2L_XGET ; Skip reload of buffer if not

; Fetch another buffer load of PTEs from QMAX.SYS

	 mov	 si,PTE_OFFSET	; Offset within PTEs
	 add	 si,@PTE_BUFL	; Bump past the current buffer load
RMI_P2L_JAM:
	 mov	 PTE_OFFSET,si	; Save offset within PTEs

	 push	 ecx		; Save count of PTEs still to be examined

	 lea	 di,PTE_BUF	; Address of our local PTE buffer

	 cmp	 cx,@PTE_BUFN	; Do we have a full buffer load remaining?
	 jb	 short @F	; Nope, so use the remaining count instead

	 mov	 cx,@PTE_BUFN	; # of PTEs local buffer will hold
@@:
	 call	 RMI_GETPTE	; Copy next load of page table entries
				; Carry set if it failed to copy the PTEs

	 pop	 ecx		; Restore count of PTEs still to be examined

	 jc	 short RMI_P2L_XIT ; Rejoin common exit code (carry is set)

	 lea	 si,PTE_BUF	; DS:SI ==> local copy of PTEs
RMI_P2L_XGET:
	 lodsd			; EAX = next PTE

	 test	 ax,mask $PTE_P ; Izit present?
	 jz	 short RMI_P2L_LOOP ; It's not our boy if it's not present

	 and	 eax,not (mask $LA_OFF) ; Isolate 4KB frame

	 cmp	 eax,ebx	; Izit our boy?
	 je	 short RMI_P2L_FND ; Jump if so, we're found it

RMI_P2L_LOOP:
	 LOOPD	 RMI_P2L_NXT	; Get 'em all

; We've exhaust all the PTEs without finding the physical address
; Something is wrong

	 stc			; Indicate we never found the physical address

	 jmp	 short RMI_P2L_XIT ; Rejoin common exit code

; We've found the physical address
; Calculate it's linear address

RMI_P2L_FND:
	 mov	 ax,si		; ==> next PTE in buffer
	 sub	 ax,offset PTE_BUF ; Less the start of the buffer
	 sub	 ax,4		; Less the autoincrement from the LODSD

	 add	 ax,PTE_OFFSET	; Plus buffer offset within PTEs

	 movzx	 eax,ax 	; Convert to 32-bit
	 shl	 eax,($LA_PAGE-2)-0 ; Convert from 4KB in dwords to bytes
				; EAX = linear address of start of 4KB page

	 and	 edx,(mask $LA_OFF) ; Isolate offset within 4KB page of physaddr
	 add	 edx,eax	; Linear address

	 clc			; Indicate EDX is a linear address
RMI_P2L_XIT:
	 REGREST <bp,di,si,ecx,ebx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_PHYS2LIN		; End RMI_PHYS2LIN procedure

	 page
BeginProc RMI_GETPTE,PUBLIC	; Get PTEs into local buffer via EMMOUT
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_GETPTE

DESCRIPTION:
	Copy page table entries into local buffer using the @EMM2_GETPTE
	QMAX.SYS service.

ENTRY:
	SI =	Offset within page tables of 1st PTE to copy
		To copy PTE for C0000h, SI = 300h
	DI ==>	Buffer to hold PTEs
	CX =	# of PTEs to copy

EXIT:
	Buffer filled with PTEs if carry clear.

	Carry set if error.

|

	 REGSAVE <ax,cx,dx,bp,es> ; Save caller's registers

; Read in the PTEs using the QMAX.SYS EMM2 feature

	 mov	 ax,ds		; Get addressibility to data
	 mov	 es,ax		; ... into ES
	 assume  es:_RCODE	; Tell the assembler

	 shl	 cx,(2-0)	; Convert from # of PTEs to # bytes
	 mov	 al,0		; 1 MB wrap disabled

	 mov	 bp,sp		; Save current stack pointer
	 EMMOUT  @EMM2_GETPTE	; Get the PTEs
	 mov	 sp,bp		; Cut back the stack in case of error

	 or	 ah,ah		; Check for error
	 jz	 short RMI_GETPTE_XIT ; Jump if OK (carry is clear)

	 stc			; Error indicator

	 jmp	 short RMI_GETPTE_XIT ; Join common exit code

RMI_GETPTE_XIT:
	 REGREST <es,bp,dx,cx,ax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_GETPTE		; End RMI_GETPTE procedure

	 page
DESCTAB  MDTE_STR <>		; Extended memory move descriptor table

BeginProc BLOCK_MOVE,PUBLIC	; Move In and Out of Extended Memory
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	BLOCK_MOVE

DESCRIPTION:
	Use the BIOS block move service (INT 15h function 87h) to copy
	data into and out of extended memory.

ENTRY:
	CX	=	Number of bytes to move
	ESI	=	32-bit source address
	EDI	=	32-bit destination address

EXIT:
	Carry clear if it worked.

|

	 REGSAVE <eax,bx,cx,dx,esi,edi> ; Save registers

; Save source address in DESCTAB

	 dec	 cx		; Convert from length to limit

	 mov	 eax,esi	; Get address for later use

	 mov	 DESCTAB.MDTE_DS.DESC_BASE01,ax ; Save bytes 0 and 1
	 shr	 eax,16 			; Move down
	 mov	 DESCTAB.MDTE_DS.DESC_BASE2,al	; ...	     2
	 mov	 DESCTAB.MDTE_DS.DESC_BASE3,ah	; ...	     3
	 mov	 DESCTAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	 mov	 DESCTAB.MDTE_DS.DESC_SEGLM1,0	; Save size & flags
	 mov	 DESCTAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Save destination address in DESCTAB

	 mov	 eax,edi	; Destination address

	 mov	 DESCTAB.MDTE_ES.DESC_BASE01,ax ; Save bytes 0 and 1
	 shr	 eax,16 			; Move down
	 mov	 DESCTAB.MDTE_ES.DESC_BASE2,al	; ...	     2
	 mov	 DESCTAB.MDTE_ES.DESC_BASE3,ah	; ...	     3
	 mov	 DESCTAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	 mov	 DESCTAB.MDTE_ES.DESC_SEGLM1,0	; Save size & flags
	 mov	 DESCTAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Move data into or out of our buffer

	 inc	 cx		; Convert from limit to length
	 shr	 cx,(1-0)	; Convert from bytes to words for INT 15h
	 lea	 si,DESCTAB	; ES:SI ==> descriptor table
	 mov	 ah,87h 	; Function code to move data
	 int	 15h		; Request BIOS service

	 or	 ah,ah		; Check for error
	 jz	 short @F	; Jump if all went well

	 stc			; Error return

	 jmp	 short BLK_MV_EXIT
@@:
	 clc			; Normal return
BLK_MV_EXIT:
	 REGREST <edi,esi,dx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  BLOCK_MOVE		; End READ_MEM procedure

VxD_REAL_INIT_ENDS		; End _RCODE segment

	 MEND			; End VMAX_RMI module
