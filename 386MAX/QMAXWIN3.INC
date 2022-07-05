;' $Header:   P:/PVCS/MAX/386MAX/QMAXWIN3.INV   1.1   28 Sep 1995 10:13:04   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAXWIN3.INC
;
; Support structures for WIN3
;

@VXD_ID  equ	 001Ch		; LoadHi VxD deivce ID

; Structure of chain used by 1605h INT 2Fh Windows startup broadcast

WIN386_START_STR	struc

SIS_VERSION		db	3,0	; 00-01:  Version number
SIS_NEXT_DEV_PTR	dd	?	; 02-05:  Seg:Off of next device in list
SIS_VIRT_DEV_FILE_PTR	dd	?	; 06-09:  Seg:Off of ASCIIZ file name to load
SIS_REFERENCE_DATA	dd	?	; 0A-0D:  Phys32 of ref data to be passed to dev
SIS_INSTANCE_DATA_PTR	dd	?	; 0E-11:  Seg:Off of instance data list

WIN386_START_STR	ends

; Structure for instance data list

INSTANCE_ITEM_STR	struc

IIS_PTR 		dd	?	; Seg:Off of instance item
IIS_SIZE		dw	?	; Length in bytes

INSTANCE_ITEM_STR	ends

; Structure of chain used by 160Bh INT 2Fh Windows TSR identify broadcast

TSR_Info_Struc		struc		; Windows-aware TSR chain structure
    TSR_Next		dd	?	; Segment:offset to next TSR_Info_Struc
    TSR_PSP_Segment	dw	?	; Segment of TSR's PSP
    TSR_API_Ver_ID	dw	100h	; Version # of the structure
    TSR_Exec_Flags	dw	?	; One of @TSR_xxx flags
    TSR_Exec_Cmd_Show	dw	?	; @SW_xxx flags for WinExec()
    TSR_Exec_Cmd	dd	?	; Segment:offset of command line string
    TSR_Reserved	dd	?	; Reserved
    TSR_ID_Block	dd	?	; Segment:offset of TSR ID block
					; A WORD length followed by an ASCIZ str
    TSR_Data_Block	dd	?	; 32-bit reference data
TSR_Info_Struc		ends		; End TSR_Info_Struc structure

@TSR_NOP	 equ	0		; TSR_Info_Struc.TSR_Exec_Flags
@TSR_WINEXEC	 equ	1
@TSR_LOADLIBRARY equ	2
@TSR_OPENDRIVER  equ	4

@SW_SHOWMINIMIZED equ	2		; nCmdShow argument to WinExec()

; Undocumented structure used during callback for instance data

WIN3UNK_STR		struc

			db	(25h-0+1) dup (?) ;			00 - 25
WIN3UNK_SIS		dd	? ; --> to fake SIS			26 - 29
			db	(4Ah-2Ah+1) dup (?) ;			2A - 4A
WIN3UNK_FLG		db	? ; 1 if instance data already present	4B

WIN3UNK_STR		ends

; Function codes for calls to WINVXD_VEC V86 API entry point
; Push this function code on the stack before making the FAR CALL to the ARPL

@VXDAPI_XMS	 equ	0001h	; Request XMS services
@VXDAPI_UTIL	 equ	0002h	; Request utility service
@VXDAPI_GETVER	 equ	0003h	; Return VxD API version in client AX

; Structure for reference data passed to 386MAX VxD
; N.B. It is vitally important that nothing be removed from the
; middle of this structure.  New items can always be added to the end.
; Note also that this internal reference data version number does not
; necessarily have to be kept in sync with the current MAX.SYS and
; VxD version numbers (which must match), but whenever it's updated
; should be synchronized.

@REF_STRUC_VER	 equ	800h	; Version # of reference data structure

REF_DATA_STR	 struc

; The following fields are valid for 386MAX 5.10 and 5.11

REF_CR3 	 dd	?	; 00-03:  Copy of 386MAX's CR3
REF_DOS_DEV_HDR  dd	?	; 04-07:  Linear address of device header chain
REF_UMB_INST	 dd	?	; 08-0B:  Physical address of UMB instance items

; REF_OLDDOS is never referenced by the VxD in any retail version

;;;;;;REF_OLDDOS dw	?	; 0C-0D:  Original top of DOS in paras
REF_STRUC_VER	 dw	?	; 0C-0D:  Version of the REF_DATA_STR
				;	  Filled in by 386MAX 5.13 and above

REF_OVRMAC	 dw	?	; 0E-0F:  Segment of 1st MAC in high DOS (-1 if none)
REF_MAXPHYS	 dd	?	; 10-13:  Physical address of 386MAX
REF_MAXLEN	 dd	?	; 14-17:  Length in bytes ...
REF_XMS_VXD2MAX  df	?	; 18-1D:  USE32 FAR PTR of VxD -> MAX XMS call
REF_MAX2VXD_CB	 df	?	; 1E-23:  USE32 FAR PTR of MAX -> VxD callback
REF_LOADSEG	 dw	?	; 24-25:  Segment of first LSEG
REF_UTL_VXD2MAX  df	?	; 26-2B:  USE32 FAR PTR of VxD -> MAX utility call
REF_CFGFILE	 dd	0	; 2C-2F:  Physical address of CFGFILE data (0 = none)
REF_STARTUP	 dd	?	; 30-33:  Seg:Off of WIN3 startup structure at end of 1605
REF_P1MAC	 dw	?	; 34-35:  Segment of first MAC in low DOS

; The following fields are valid for 386MAX 5.12 and later

REF_VIDFLAG	 dd	?	; 36-39:  Flags returned by VxD real mode init
				;	  Defined in VMAX_VID.INC

; The following fields are valid for 386MAX 5.13 and later

REF_UPDFLAG	 dw	?	; 3A-3B:  Flags for Windows 3.10 patching
				;	  Defined in VMAX_UPD.INC
REF_OLDREF_PTR	 dd	?	; 3C-3F:  Original physical address of
				;	  reference data passed to RM init
REF_FLEXROM_PTR  dd	?	; 40-43:  Physical address of FLEXROM info
REF_FLEXROM_LEN  dw	?	; 44-45:  Number of entries in FLEXROM info

REF_DOSVER	 dw	?	; 46-47:  DOS version # in the proper order
REF_DOSFLAG	 dw	?	; 48-49:  DX from DOS call 3306h
				;	  DX & 1000h means DOS=HIGH

; The following fields are valid for 386MAX 6.01 and later

REF_VHD_SIZE	 dw	?	; 4A-4B:  Size in K of desired virtual high DOS
				;	  Filled in by the VxD real mode init
REF_MAP_PAGES	 dw	?	; 4C-4D:  # of 4 KB pages needed for API
				;	  translation mapping buffers
				;	  Filled in by the VxD real mode init

; The following fields are valid for 386MAX 6.03 and later

REF_FILES_LEN dw	?	; 4E-4F:  Size of FILES= structure in bytes
				;	  Communicated to QMAX.SYS by HARPO.SYS
REF_STRUC_LEN	 dw	?	; 50-51:  Length of the REF_DATA_STR in bytes
REF_R2PFLAG	 dw	?	; 52-53:  Real mode to protected mode info flag

REF_IGRPHYS	 dd	?	; 54-57:  Physical base of IGROUP
REF_IGRSIZE	 dd	?	; 58-5B:  Length in bytes of IGROUP
REF_JGRPHYS	 dd	?	; 5C-5F:  Physical base of JGROUP
REF_JGRSIZE	 dd	?	; 60-63:  Length in bytes of JGROUP
REF_FGRPHYS	 dd	?	; 64-67:  Physical base of FGROUP
REF_FGRSIZE	 dd	?	; 68-6B:  Length in bytes of FGROUP

; The following selectors are filled in by the VxD, 6.03 and later

REF_CSPGR	 dw	?	; 6C-6D:  PGROUP code selector
REF_DSPGR	 dw	?	; 6E-6F:  PGROUP data selector
REF_CSIGR	 dw	?	; 70-71:  IGROUP code selector
REF_DSIGR	 dw	?	; 72-73:  IGROUP data selector
REF_CSJGR	 dw	?	; 74-75:  JGROUP code selector
REF_DSJGR	 dw	?	; 76-77:  JGROUP data selector
REF_DSFGR	 dw	?	; 78-79:  FGROUP data selector

REF_FIXUP_ISELS  df	?	; 7A-7F:  FAR PTR to 386MAX FICALL translator
				;	  Offset  filled in by 386MAX
				;	  Segment filled in by the VxD

; The following fields are valid for 386MAX 7.00 and later

REF_LaDSTK_TAB	 dd	0	; 80-83:  Linear address of DSTK_TAB_STR
REF_PDSTKCOM	 dd	0	; 84-87:  Seg:offset of common return routine
REF_DSTK_CNT	 dw	0	; 88-89:  Total # of DOS stacks

; The following fields are valid for 386MAX 8.00 and later

REF_PnP_SEG	dw	0	; 8A-8B:  PnP struc segment in BIOS (0=none)
REF_PnPCS	dw	0	; 8C-8D:  ... code selector
REF_PnPDS	dw	0	; 8E-8F:  ... data ...
REF_PnPARG0	dw	0	; 90-91:  ... argument data selector #0
REF_PnPARG1	dw	0	; 92-93:  ...			      1
REF_PnPARG2	dw	0	; 94-95:  ...			      2

REF_DATA_STR	 ends		; End REF_DATA_STR structure

@REF_LEN510	 equ	REF_P1MAC+size REF_P1MAC ; Length of 5.10 structure
@REF_LEN511	 equ	REF_P1MAC+size REF_P1MAC		; ... 5.11
@REF_LEN512	 equ	REF_VIDFLAG+size REF_VIDFLAG		; ... 5.12
@REF_LEN513	 equ	REF_DOSFLAG+size REF_DOSFLAG		; ... 5.13
@REF_LEN601	 equ	REF_MAP_PAGES+size REF_MAP_PAGES	; ... 6.01
@REF_LEN603	 equ	REF_FIXUP_ISELS+size REF_FIXUP_ISELS	; ... 6.03
@REF_LEN700	 equ	REF_DSTK_CNT+size REF_DSTK_CNT		; ... 7.00
@REF_LEN800	 equ	(size REF_DATA_STR)			; ... 8.00

