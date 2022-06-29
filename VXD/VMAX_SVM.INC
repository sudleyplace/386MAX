;'$Header:   P:/PVCS/MAX/VXD/VMAX_SVM.INV   1.2   03 Nov 1995 14:56:46   BOB  $
;
; (C) Copyright 1992-5 Qualitas, Inc.  All rights reserved.
;
; VMAX_SVM.INC
;
; Definitions for DOSMAX
;

; enum DOSMAXNums {DOSMAX_OFF=0, DOSMAX_ON, DOSMAX_DEF};
; from DOSMAX.H

@DOSMAX_OFF	equ	0
@DOSMAX_ON	equ	1
@DOSMAX_DEF	equ	2

strDMPIF	struc

DMPIF_bFlag	db	?	; Flag:  DOSMAX_xxx (OFF/ON/DEF)
DMPIF_wMem	dw	-1	; Memory to use for this VM

strDMPIF	ends

; Bit definitions for SVM_FLAG

@SVM_VDDPF	equ	8000h	; VDD_PFault is hooked for DOSMAX
@SVM_DOSMAX_REQ equ	4000h	; DOSMAX support requested for next Create_VM
@SVM_DOSMAX_DEF equ	2000h	; All VMs will be DOSMAX
@SVM_XLATFONT	equ	1000h	; Translate font changes
@SVM_NOMONO	equ	0800h	; Disable use of B000-B7FF
@SVM_SHORT	equ	0400h	; Popup if DOSMAX attempted due to short low DOS
@SVM_NOBASEMEM	equ	0200h	; Fail VM_INIT in ZMAX due to low memory
@SVM_NOJUGGLE	equ	0100h	; Disable unhook/rehook of real mode INT 10h
@SVM_PAGEFAULT	equ	0080h	; We're within a video page fault from the VDD

DOSMAX_PERVM_STR	struc		; Structure defining DOSMAX per VM data

; The following fields are inputs to, and are referenced, by QPOPUP.EXE
; Changes here must be reflected there

    CB_wSize		dw	?	; Size accessible to callback
    CB_wFunction	dw	?	; Requested function code
    CB_VMHANDLE 	dd	?	; VM to which this data belongs
    CB_lpszFilename	dd	?	; LPSTR to filename (16-bit Sys_VM)
    CB_wFlags		dw	?	; Per VM flags
    CB_wVideoMode	dw	?	; Video mode being attempted

; End of QPOPUP related data

    CB_SELPERVM 	dw	?	; Selector in Sys_VM's LDT to this struc
			dw	?	; Padding

    CB_SEMAPHORE	dd	?	; Handle of semaphore (or NULL)
    CB_PFILENAME	dd	?	; ==> filename (CB_High_Linear based)

    CB_HPAGE_A0 	dd	?	; Handle to pages allocated for A0-AF
    CB_NPAGES_A0	dd	?	; # of pages in A0-AF
    CB_PTE_A0_NUL	dd	?	; A0 PTE with NUL page mapped in
    CB_PTE_A0_VDD	dd	?	; A0 PTE after VDD handles page fault
    CB_HPAGE_B0 	dd	?	; Handle to pages allocated for B0-B7
    CB_NPAGES_B0	dd	?	; # of pages in B0-B7

    CB_FONTPTR		dd	?	; Original client ES:BP for font xlat

    CB_LASTEXEC 	db	(8+1+3) dup (?) ; filename.ext of last exec()
DOSMAX_PERVM_STR	ends		; End DOSMAX_PERVM_STR structure

; DOSMAX_PERVM_STR.CB_dwFlags equates

@CBF_DOSMAX		equ	8000h	; This is a DOSMAX VM
@CBF_VMINIT		equ	4000h	; VM_Init seen by secondary VxD
@CBF_EVENT		equ	2000h	; VM caused an event in the Sys VM
@CBF_MODE		equ	0800h	; Trapped V86 INT 10h due to mode switch
@CBF_FONT		equ	0400h	; Trapped V86 INT 10h due to font change
@CBF_XLATFONT		equ	0200h	; Translating a font
@CBF_SEMAPHORE		equ	0100h	; Blocked on an allocated semaphore
@CBF_IGNOREA0		equ	0080h	; Ignore page faults in A0
@CBF_BACKGROUND 	equ	0040h	; Set if background execution enabled
@CBF_DOSMAX_CALLBACK	equ	0020h	; DOSMAX Callback invoked

; DOSMAX_PERVM_STR.CB_dwFunction equates

@CBFN_MODESWITCH	equ	8000h	; VM has attempted a video mode switch
@CBFN_WARNFLAG		equ	4000h	; exec() of a troublesome program
@CBFN_FAILFLAG		equ	2000h	; exec() of a graphics only program

SetDOSMAXPtr macro REG,VMHand		; Load DOSMAX per VM data pointer

ifndef	 DEV_CB_OFFSET
VxD_DATA_SEG	 NO_ALIGN
	 extrn	 DEV_CB_OFFSET:dword
VxD_DATA_ENDS
endif					; IFNDEF DEV_CB_OFFSET

ifndef	 DOSMAX_PERVMOFF
VxD_DATA_SEG	 NO_ALIGN
	 extrn	 DOSMAX_PERVMOFF:dword
VxD_DATA_ENDS
endif					; IFNDEF DOSMAX_PERVMOFF

IFNB	 <VMHand>
	 push	 ebx			; Save
	 mov	 ebx,VMHand		; Get VM handle
ENDIF

	 mov	 REG,ebx		; ==> VM CB
	 add	 REG,[DEV_CB_OFFSET]	; Plus offset of our per VM data
	 add	 REG,[DOSMAX_PERVMOFF] ; Plus offset of DOSMAX specific data

IFNB	 <VMHand>
	 pop	 ebx			; Restore
ENDIF
	 endm				; End SetDOSMAXPtr macro

