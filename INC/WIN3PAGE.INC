;' $Header:   P:/PVCS/MAX/INC/WIN3PAGE.INV   1.1   31 Jan 1996 12:33:50   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; WIN3PAGE.INC
;
; Paging Import data structures
;

EMM_Import_IOCTL_Data	struc

EMM_Import_Data_Phys_Ptr	dd	?	; Physical 32-bit address
EMM_Import_API_Version_Maj	db	?	; API version #
EMM_Import_API_Version_Min	db	?	; ...

EMM_Import_IOCTL_Data	ends


EMM_Import_Context	struc

Import_Cntxt_Flags	db	?		; Flags (I_Ctxt_F_...)
Import_Cntxt_Hand	db	?		; EMS handle #
Import_Cntxt_LPag	dw	?		; Logical page #
Import_Cntxt_PPag	db	?		; Physical page #
Import_Cntxt_EFLgs	db	?		; Non EMS/UMB flags (I_Ctxt_EF_...)

EMM_Import_Context	ends

Import_cntxt_UMB_Indx	equ	Import_Cntxt_Hand

; Import_Cntxt_Flags

I_Ctxt_F_IsEMM		equ	00000001b	; Is an EMS-mappable page
I_Ctxt_F_LIM320 	equ	00000010b	; Is in the EMS page frame
I_Ctxt_F_UMBPg0 	equ	00000100b	; Is a UMB page 0
I_Ctxt_F_UMBPg1 	equ	00001000b	; ...		1
I_Ctxt_F_UMBPg2 	equ	00010000b	; ...		2
I_Ctxt_F_UMBPg3 	equ	00100000b	; ...		3

; Import_Cntxt_EFlgs (Version 1.10-specific)

I_Ctxt_EF_Unknown	equ	00b		; UMB page status unknown
I_Ctxt_EF_Usable	equ	01b		; ...	   usable by WIN3
I_Ctxt_EF_NotUsable	equ	10b		; ...	   not usable ...
I_Ctxt_EF_Invalid	equ	11b		; Bit combination invalid



IMPCNTXTSZ		equ	64		; Maximimum # EMS-mappable pages

EMM_Import_Data 	struc

EMM_Import_Flags	dw	?		; Flags (EMM_I_F_...)
EMM_Import_Length	dw	?		; Length of structure in bytes
EMM_Import_Version	dw	?		; Version of struc
EMM_Import_OSKey	dd	?		; OS key, 0 = none
EMM_Import_Cntxt	db	(IMPCNTXTSZ * (size EMM_Import_Context)) dup (?)
EMM_Import_CntxtSz	db	?		; 4E03h return value
EMM_Import_UMB_Cnt	db	?		; Size of UMB array in entries

EMM_Import_Data 	ends

EMM_Import_UMB		equ	EMM_Import_UMB_Cnt+size EMM_Import_UMB_Cnt

EMM_I_F_FRSAlloced	equ	0001h		; A FRS other than 0 is allocated
EMM_I_F_HandHasContext	equ	0002h		; One of the EMS handles has a
						; context saved for it
EMM_I_F_NoXMSHndInfo	equ	0004h		; For EMM_Import_xMS_Cnt == 0
						; 1 = value of zero means don't know
						; 0 = value of zero means none
EMM_I_F_AliasHMAIsFree	equ	0008h		; Aliased HMA is free
EMM_I_F_NoXMSUMBInfo	equ	0010h		; For EMM_Import_FreeUMB_Cnt
						; 1 = value of zero means don't know
						; 0 = value of zero means none

EMM_Import_V110 	struc

EMM_Import_INT67	dd	?		; Backdoor INT 67h hook address
EMM_Import_HMAAliasPhysPtr dd	?		; HMA alias pointer
EMM_Import_Free_Cnt	db	?		; # entries in Free page array

EMM_Import_V110 	ends


EMM_Import_UMB_Map	struc

Import_UMB_Page0	dd	?		; Phys Pg#, 0th page of UMB
Import_UMB_Page1	dd	?		; ...	    1st ...
Import_UMB_Page2	dd	?		; ...	    2nd ...
Import_UMB_Page3	dd	?		; ...	    3rd ...

EMM_Import_UMB_Map	ends



EMM_Import_Handle	struc

Import_HandleNum	db	?		; EMS handle #
Import_HandleFlags	db	?		; Flags (HF_Imp_...)
Import_HandleName	db	8 dup (?)	; Handle name
Import_NumLogPages	dw	?		; # logical pages allocated
Import_PhysPtrToPTEs	dd	?		; Physical ptr to PTEs

EMM_Import_Handle	ends

HF_Imp_HasName		equ	0001h		; Handle has name
HF_Imp_SavedContext	equ	0002h		; Handle has a context saved
HF_Imp_Unused		equ	0004h		; Handle unused


; Regions of free physical pages available for WIN3

EMM_Import_FreeReg	struc

Import_Free_Start	dd	?		; Starting page #
Import_Free_Cnt 	dd	?		; Count of contiguous 4KB pages

EMM_Import_FreeReg	ends



; Structure of the xMS handle information.  NOTE that one of these is
; included for EVERY POSSIBLE xMS handle.  The currently unallocated
; handle numbers are the ones that are available for WIN3 to use.

EMM_Import_xMSHnd	struc

Import_xMS_Hand 	dw	?		; xMS handle #
Import_xMS_Flags	dw	?		; Flags (xHF_Imp_...)
Import_xMS_Size 	dd	?		; Size in 1KB
Import_xMS_PhysAddr	dd	?		; Lock physical address
						; -1 if unused or size zero handle

EMM_Import_xMSHnd	ends

xHF_Imp_Unused		equ	0001h		; Handle is not allocated


; Structure of free UMB information structure

EMM_Import_FreeUMB	struc

Import_Free_UMB_Seg	dw	?		; Starting segment of free UMB
Import_Free_UMB_Size	dw	?		; # paras in free UMB

EMM_Import_FreeUMB	ends


