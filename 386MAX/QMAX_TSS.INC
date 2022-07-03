;' $Header:   P:/PVCS/MAX/386MAX/QMAX_TSS.INV   1.0   11 Aug 1995 10:55:12   HENRY  $
;
; (C) Copyright 1991-3 Qualitas, Inc.  GNU General Public License version 3.
;
; QMAX_TSS.INC
;
; Structures and equates for TSSs
;

DPTSS_STR struc

DPTSS_TSS db	 (size TSS_STR) dup (?) ; A normal TSS goes here
DPTSS_INTCOM dd  ?		; 68-6B:  Previous LAST_INTCOM
DPTSS_INTFLG dd  ?		; 6C-6F:  Previous LAST_INTFLG
DPTSS_STKERR dd  ?		; 70-73:  Offset of stack when error code present
DPTSS_STKNRM dd  ?		; 74-77:  Offset of stack when normal start
DPTSS_STKMIN dd  ?		; 78-7B:  Offset of stack minimum for interrupts
DPTSS_STKMAP dd  ?		; 7C-7F:  Offset of stack bottom for Map & Call struc
DPTSS_STKDNRM dd ?		; 80-83:  Offset of stack when DPMI HW/SW occurs
DPTSS_STKDERR dd ?		; 84-87:  Offset of stack when DPMI fault occurs
DPTSS_LaHPDA dd  ?		; 88-8B:  Linear address of the matching HPDA
DPTSS_VMSTKBOT dw ?,0		; 8C-8F:  Fixed stack bottom in HPDA as dword
DPTSS_VMSTKOFF dw ?		; 90-91:  Current stack offset
DPTSS_VMSTKSEG dw ?		; 92-93:  Current stack segment
DPTSS_VMBUFOFF dw ?,0		; 94-97:  Current buffer offset in HPDA as dword
DPTSS_VMBUFSIZ dw ?,0		; 98-9B:  Current buffer size in HPDA as dword
DPTSS_HPDASEG dw ?,0		; 9C-9F:  Segment of HPDA as dword
DPTSS_LPMBASE dd ?		; A0-A3:  Linear address of LPM stack
DPTSS_LPMSTK_CNT dd ?		; A4-A7:  Starting LPM stack usage count
DPTSS_LPMSTK_FVEC df ?		; A8-AD:  Starting stack Sel:Off
DPTSS_FLAG dw	 0		; AE-AF:  Flag values (see DPTSS_REC below)
DPTSS_DYN dd	 ?		; B0-B3:  Linear address of dynamic save area
DPTSS_OLDPM dd	 ?		; B4-B7:  Linear address of old PM data area
DPTSS_DTA_FVEC df ?		; B8-BD:  Sel|Off of current DTA
DPTSS_MOUSE_SSRSIZE dw ?	; BE-BF:  Mouse State Save/Restore Size
DPTSS_MEI_FVEC df ?		; C0-C5:  Sel|Off of Mouse Event Interrupt
DPTSS_MSW dw	 ?		; C6-C7:  Local value of MSW (only $EM and $MP are defined)
DPTSS_LaLDT dd	 ?		; C8-CB:  Linear address of this TSS's LDT
DPTSS_LDT_SIZ dd ?		; CC-CF:  Size in bytes of ... (excluding bitmap)
				;	  never bigger than 64KB
DPTSS_LaDPMIHNDL dd ?		; D0-D3:  Linear address of this TSS's DPMI memory
				;	  handle table
DPTSS_DPMIHNDL_CNT dd ? 	; D4-D7:  # DPMI memory handles in above table
DPTSS_MEI_ORIG_VEC  dd ?	; D8-DB:  Original MEI Handler in VM (0=none)
DPTSS_MEI_ORIG_MASK dw ?	; DC-DD:  Original MEI Mask
DPTSS_SEL dw	 ?		; DE-DF:  Selector for this TSS
DPTSS_IDT07 dq	 ?		; E0-E7:  This client's IDT entry for INT 07h
DPTSS_PLNKTSS dd ?		; E8-EB:  Offset in PGROUP of previous linked TSS
DPTSS_PRMSTSS dd ?		; EC-EF:  Offset in PGROUP of previous RMS TSS
DPTSS_LaSIRBCUR dd ?		; F0-F3:  Linear address of current SIRB table
DPTSS_I24BP  dw  ?		; F4-F5:  Initial INT 24h value of BP
DPTSS_I24FLG db  ?		; F6   :  Initial INT 24h flags (I24_REC)

DPTSS_VMM_Flags db ?		; F7	:  Per Client Flags for VMM/DPMI 1.0
DPTSS_VMM_FreeList db 16 dup (?); F8-107: linear free list struc
DPTSS_VMM_BS_PSP dw ?		;108-109: PSP on which swapfile is opened
DPTSS_VMM_BS_handle dw ?	;10A-10B: handle on which swapfile is opened
DPTSS_VMM_IO_buffer dd ?	;10C-10F: linear address of HPDA buffer save
				;	  area
DPTSS_VMM_Saved_offset dw ?	;110-111: saved HPDA buffer offset
DPTSS_VMM_Saved_size dw ?	;112-113: saved HPDA buffer size
DPTSS_VMM_RSP_code32 dq ?	;114-11B: RSP 32-bit code descriptor
DPTSS_VMM_RSP_data32 dq ?	;11C-123: RSP 32-bit data descriptor
DPTSS_VMM_RSP_code16 dq ?	;124-12B: RSP 16-bit code descriptor
DPTSS_VMM_RSP_data16 dq ?	;12C-133: RSP 16-bit data descriptor
DPTSS_VMM_RSP_cb32 dd ? 	;134-137: RSP 32-bit callback entry offset
DPTSS_VMM_RSP_cb16 dw ? 	;138-139: RSP 16-bit callback entry offset
DPTSS_VMM_P2LMapTable dd ?	;13A-13D: LA of P2L mapping table
DPTSS_VMM_P2LMapSize dd ?	;13E-141: size (bytes) of mapping table

if (($-DPTSS_TSS) mod 4)
	 db	 (4-(($-DPTSS_TSS) mod 4)) dup (?) ; For dword alignment
endif				; IF (($-DPTSS_TSS) MOD 4)

; Remember:  the size of DPTSS_STR must be a multiple of four so that
; the TSS is always dword-aligned.

DPTSS_STR ends


DPTSS_REC record $DPTSS_WRAP:1, \
		 $DPTSS_INIT:1, \
		 $DPTSS_LSMINIT:1, \
		 $DPTSS_BSMINIT:1

COMMENT|

$DPTSS_WRAP:	 1 = 1MB wrap enabled when previously disabled
		 0 = not
$DPTSS_INIT:	 1 = TSS has been initialized
		 0 = not
$DPTSS_LSMINIT:  1 = LSM has been initialized for this client
$DPTSS_BSMINIT:  1 = BSM ...

|

SIRB_MAC macro	 NN		; Set bit in SIRB table at AGROUP:EDI

	 or	 AGROUP:[edi+0&NN&h/8].LO,1 shl (0&NN&h mod 8)

	 endm			; SIRB_MAC

