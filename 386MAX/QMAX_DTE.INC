;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DTE.INV   1.3   08 Jul 1998 12:06:18   BOB  $
;
; (C) Copyright 1987-98 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_DTE.INC
;
; Structures and equates for the GDT and related issues.
; This file is common to almost all QMAX*.ASM files.
;

;;;;IOPL equ	 0		; Use this IOPL for DPMI clients to catch
				; I/O trapping from PL3 (not anymore)
@DPMIOPL equ	 3		; Use this IOPL for DPMI clients to avoid
				; bugs with PUSHF/CLI/POPF and IRET which don't
				; change IF on the POPF/IRET
@VMIOPL  equ	 3		; Use this IOPL for VM clients to avoid
				; GP Faults on CLI/STI/HLT/INT/IRET/PUSHF/POPF

IRET_STR struc			; IRET frame

IRET_IP  dw	 ?		; 00:  IP
IRET_CS  dw	 ?		; 02:  CS
IRET_FL  dw	 ?		; 04:  FL

IRET_STR ends


NRM_STR  struc			; Stack when no error code present

NRM_EIP   dd	 ?		; 00:  EIP
NRM_CS	  dw	 ?		; 04:  CS
NRM_INTNO dw	 ?		; 06:  INT # times 4 + offset PGROUP:INTPROC00Z
NRM_EFL   dd	 ?		; 08:  EFL

NRM_STR  ends


FLT_STR  struc			; Stack when error code is present

FLT_ERR   dd	 ?		; 00:  Error code
FLT_EIP   dd	 ?		; 04:  EIP
FLT_CS	  dw	 ?		; 08:  CS
FLT_INTNO dw	 ?		; 0A:  INT # times 4 + offset PGROUP:INTPROC00Z
FLT_EFL   dd	 ?		; 0C:  EFL

FLT_STR  ends


; DPMI stack argument structure for faults

INTDPF_STR struc

INTDPF_ERR dd	 ?		; 00:  Error code
INTDPF_EIP dd	 ?		; 04:  Old EIP
INTDPF_CS  dw	 ?		; 08:  Old CS
INTDPF_INTNO dw  ?		; 0A:  INT # times 4 + offset PGROUP:INTPROC00Z
INTDPF_EFL dd	 ?		; 0C:  Old EFL
INTDPF_ESP dd	 ?		; 10:  Old ESP
INTDPF_SS  dw	 ?,0		; 14:  Old SS w/filler

INTDPF_STR ends


; DPMI stack argument structure for interrupts

INTDPI_STR struc

INTDPI_EIP dd	 ?		; 00:  Old EIP
INTDPI_CS  dw	 ?		; 04:  Old CS
INTDPI_INTNO dw  ?		; 06:  INT # times 4 + offset PGROUP:INTPROC00Z
INTDPI_EFL dd	 ?		; 08:  Old EFL
INTDPI_ESP dd	 ?		; 0C:  Old ESP
INTDPI_SS  dw	 ?,0		; 10:  Old SS w/filler

INTDPI_STR ends


; DPMI stack argument structure for far calls

RETFDPI_STR struc

RETFDPI_EIP dd	 ?		; 00:  Old EIP
RETFDPI_CS  dw	 ?,0		; 04:  Old CS w/filler
RETFDPI_ESP dd	 ?		; 08:  Old ESP
RETFDPI_SS  dw	 ?,0		; 0C:  Old SS w/filler

RETFDPI_STR ends


; INTCOM stack argument structure

INTCOM_STR struc

INTCOM_EIP dd	 ?		; 00:  Old EIP
INTCOM_CS dw	 ?		; 04:  Old CS
INTCOM_INTNO dw  ?		; 06:  Interrupt #
INTCOM_EFL dd	 ?		; 08:  Old EFL
INTCOM_ESP dd	 ?		; 0C:  Old ESP3
INTCOM_SS dw	 ?,0		; 10:  Old SS
INTCOM_ES dw	 ?		; 14:  Old ES
INTCOM_ICOMLO dw ?		; 16:  INTCOM-restart point, low-order word
INTCOM_DS dw	 ?		; 18:  Old DS
INTCOM_ICOMHI dw ?		; 1A:  INTCOM-restart point, high-order word
INTCOM_FS dw	 ?,0		; 1C:  Old FS
INTCOM_GS dw	 ?,0		; 20:  Old GS

INTCOM_STR ends


; Record and equate for LAST_INTFLG

INTCOM_REC record $INTCOM_RSV:7,$INTCOM_VAL:1 ; Do NOT define additional bits
				; in the low-order byte so we can use SETcc
@INTCOM_VAL equ  mask $INTCOM_VAL ; LAST_INTCOM is valid:  *MUST* be Bit 0.


; INTXX stack argument structure

INTXX_STR struc

INTXX_EDI   dd	 ?		; 00:  Old EDI
INTXX_ESI   dd	 ?		; 04:  Old ESI
INTXX_EBP   dd	 ?		; 08:  Old EBP
INTXX_ESP0  dd	 ?		; 0C:  Old ESP0
INTXX_EBX   dd	 ?		; 10:  Old EBX
INTXX_EDX   dd	 ?		; 14:  Old EDX
INTXX_ECX   dd	 ?		; 18:  Old ECX
INTXX_EAX   dd	 ?		; 1C:  Old EAX
INTXX_ERR   dd	 ?		; 20:  Fault error code
INTXX_EIP   dd	 ?		; 24:  Old EIP
INTXX_CS    dw	 ?		; 28:  Old CS
INTXX_INTNO dw	 ?		; 2A:  Interrupt #
INTXX_EFL   dd	 ?		; 2C:  Old EFL
INTXX_ESP   dd	 ?		; 30:  Old ESP3
INTXX_SS    dw	 ?		; 34:  Old SS
INTXX_OIPLO dw	 ?		; 36:  Original EIP, low-order word
INTXX_ES    dw	 ?		; 38:  Old ES
INTXX_ICOMLO dw  ?		; 3A:  INTCOM-restart point, low-order word
INTXX_DS    dw	 ?		; 3C:  Old DS
INTXX_ICOMHI dw  ?		; 3E:  INTCOM-restart point, high-order word
INTXX_FS    dw	 ?		; 40:  Old FS
INTXX_OIPHI dw	 ?		; 42:  Original EIP, high-order word
INTXX_GS    dw	 ?,0		; 44:  Old GS

INTXX_STR ends


COMMENT|

Equate for VSAPI stack size in dwords to avoid conflict with other
stack sizes during PL0 processing.  This value *MUST* be such that the
stack upon entry to the VSAPI routine is larger than any other initial
stack.	The other entry stacks are as follows:

Variable	  Structure				Byte size
--------------------------------------------------------------------
PPL0STK_DNRM	  size INTDPI_STR			    14h
PPL0STK_DERR	  size INTDPF_STR			    18h
PPL0STK_NRM	  size INTCOM_STR			    24h
PPL0STK_ERR	 (size INTCOM_STR) + (size INTXX_ERR)	    28h

Before entry to the VSAPI routine, the PL3 code subtracts this amount
from the current stack and pushes at least one argument.  The call
gate for VSAPI copies this many dword parameters from the PL3 stack.
Upon entry to the VSAPI routine, the CPU pushes RETFDPI_STR onto the
stack.

|

@VSAPI_DDSTKSIZE equ (((size INTCOM_STR)+(size INTXX_ERR)-(size RETFDPI_STR))/4)


; Equates for XDTE_STR

@LOAD_MAX equ	 8		; Maximum # file loads allowed
@TSS_MAX  equ	 64		; Maximum # TSSs supported and thus
				; this number (less one for the main TSS)
				; becomes the maximum depth of DPMI client
				; nesting we allow

@DPMI_CPL equ	 3		; DPMI client CPL
DTE_DATALDT equ  0080h		; LDT selector offset
DTE_DATALPM equ  0088h		; LPM selector offset
LDTE_DATALDT3 equ (DTE_DATALDT or (mask $TI) or (@DPMI_CPL shl $PL)) ; LDTE for LDT at DPMI DPL
LDTE_DATALPM3 equ (DTE_DATALPM or (mask $TI) or (@DPMI_CPL shl $PL)) ; LDTE for LPM at DPMI DPL


COMMENT|

Extended Descriptor Table Entry structure

N.B. Due to a bug in LINK's handling of the MASM 5.10b 32-bit OMF, an instance
     of XDTE_STR should never be used.

	To define the GDT, use:
		DESC_TAB db (type XDTE_STR) dup (?) ; Extended descriptor tables

	rather than:
		DESC_TAB XDTE_STR <>		; Extended descriptor tables

|

XDTE_STR struc

	 db	 (size DTE_STR) dup (?)
;;;_DUMMY dq	 ?		; 00:  First entry not accessible
;;;_GDT  dq	 ?		; 08:  Global descriptor table
;;;_IDT  dq	 ?		; 10:  Interrupt ...
;;;_DS	 dq	 ?		; 18:  DS ...
;;;_ES	 dq	 ?		; 20:  ES ...
;;;_SS	 dq	 ?		; 28:  SS ...
;;;_CS	 dq	 ?		; 30:  CS ...
;;;_BIOS dq	 ?		; 38:  Temporary BIOS ...
DTE_BDA  dq	 ?		; 40:  Linear address of BIOS data area
DTE_AMRS dq	 ?		; 48:  Linear address of AMRS PTEs
DTE_CS2  dq	 ?		; 50:  CS2 descriptor (high-memory code segment)
DTE_OPTE dq	 ?		; 58:  PDE descriptor for overflow PTE table
DTE_D4GB dq	 ?		; 60:  4GB descriptor as data
DTE_VID  dq	 ?		; 68:  Video buffer descriptor
DTE_PDT  dq	 ?		; 70:  Page Descriptor Table
DTE_CR3  dq	 ?		; 78:  Page Directory Base Register
DTE_DMA  dq	 ?		; 80:  Temporary page for DMA moves
DTE_TRACE dq	 ?		; 88:  Trace table
DTE_D64K dq	 ?		; 90:  64KB data selector
DTE_CSLO dq	 ?		; 98:  Linear low  DOS memory code
DTE_DSLO dq	 ?		; A0:  Linear low  DOS memory data
DTE_DSHI dq	 ?		; A8:  Linear high DOS memory data
				;      == DTE_DSLO if NOLOADHI
DTE_DSXP dq	 ?		; B0:  Physical extended memory data
DTE_LML  dq	 ?		; B8:  Physical address of low memory load
DTE_VCOD dq	 ?		; C0:  VCPI Code segment
DTE_VDAT dq	 ?		; C8:  VCPI Data segment
DTE_SWAPBUF dq	 ?		; D0:  DPMI swapper's I/O buffer
DTE_CSIO dq	 ?		; D8: Code selector for I/O trapping
DTE_DSIO dq	 ?		; E0: Data ...
DTE_SSIO dq	 ?		; E8: Stack ...
	 dq	 ?		; F0:  (available)
	 dq	 ?		; F8:  (available)
	 dq	 ?		; 100: (available)
	 dq	 ?		; 108: (available)
DTE_DPMI_VSAPI	dq ?		; 110: DPMI Vendor-Specific API entry call gate
	 dq	 ?		; 118: (available)
DTE_DPMIDEF dq	 ?		; 120: DPMI default interrupt handler
DTE_FIXUP dq	 ?		; 128: FGROUP tables
DTE_CSIG dq	 ?		; 130: IGROUP code selector
DTE_DSIG dq	 ?		; 138: IGROUP data selector
DTE_DS3  dq	 ?		; 140: PGROUP data selector at PL3
DTE_D4GB3 dq	 ?		; 148: 4GB    data selector at PL3
DTE_CSJG dq	 ?		; 150: JGROUP code selector
DTE_DSJG dq	 ?		; 158: JGROUP data selector
DTE_TSS  dq	 (2*@TSS_MAX) dup (?) ; 160-1D8:  TSS/LDT descriptors
DTE_PnPCS dq	?		; 1E0: PnP code selector
DTE_PnPDS dq	?		; 1E8: PnP data selector
DTE_PnPARG0 dq	?		; 1F0: PnP argument data selector #0
DTE_PnPARG1 dq	?		; 1F8: PnP ...			  #1
DTE_PnPARG2 dq	?		; 200: PnP ...			  #2
DTE_LOAD dq	 (3*@LOAD_MAX) dup (?) ; Three DTEs per LOAD= line
				; 208: The 1st DTE is the code segment
				; 210: The 2nd DTE is the data segment
				; 218: The 3rd DTE is available (secondary
				;      code segment in SWAT)
	 dq	 16 dup (?)	; 2C8: Make room for more selectors

; Do not add new selectors to the end of the GDT as we need to
; leave room for other programs (such as MMEXT) to intrude into
; our GDT.

XDTE_STR ends

DTE_DPMILDT equ  (DTE_TSS+8)	; LDT selector


@PnP_BIOS_BEG equ 0E0000h	; Starting address of system PnP BIOS (/4KB)
@PnP_BIOS_END equ 100000h	; Ending ...
@PnP_NPTES equ	(@PnP_BIOS_END - @PnP_BIOS_BEG) shr 12 ; # PTEs in PnP BIOS


LOWGDT_STR struc		; Low memory skeleton GDT for Windows 3

	 dq	 ?		; 00:  Dummy entry
LOWDTE_GDT dq	 ?		; 08:  GDTR
LOWDTE_CSLHI dq  ?		; 10:  CS for extended memory with paging enabled

LOWGDT_STR ends


; LENTXT2 is used for message creation with leading word length

LENTXT2  macro	 LAB,MSG
	 local	 LABA,LABZ

	 public  LAB
LAB	 LENTXT_STR <LABZ-LABA>
LABA	 db	 MSG
LABZ	 label	 byte

	 endm			; LENTXT2

LENTXT_STR struc

LENTXT_LEN dw	 ?		; Length of following string
				; First byte of following string
LENTXT_STR ends


PDT_STR  struc

PDT_PTE  dd	 ?		; Page Table Entry in PDT

PDT_STR  ends


.xcref FIXIJMP
FIXIJMP  macro	 LAB,SEL
	 local	 L1,CURGRP,IND

	 db	 0EAh		; Opcode for immediate far jump
	 dw	 offset LAB	; ...to this label
L1	 dw	 SEL		; ...and selector

IND	 instr	 <CODE..ECODE.LCODE.ICODE.JCODE.>,@CurSeg
if IND EQ 0
.err
endif				; IF IND EQ 0
CURGRP	 substr  <PGROUPPGROUPIGROUPIGROUPJGROUP>,IND,6

ifndef FGROUP
FGROUP	 group	 FIX_PGROUP, FIX_IGROUP, FIX_JGROUP

FIX_PGROUP segment use16 word public 'fixup'
FIX_PGROUP ends

FIX_IGROUP segment use16 word public 'fixup'
FIX_IGROUP ends

FIX_JGROUP segment use16 word public 'fixup'
FIX_JGROUP ends
endif				; IFNDEF

% FIX_&&CURGRP segment use16 word public 'fixup'
%	 dw	 offset CURGRP:L1
% FIX_&&CURGRP ends

	 endm			; FIXIJMP


.xcref FIXICALL
FIXICALL macro	 LAB,SEL,RSEG
	 local	 L1,L2,CURGRP,IND

ifb <RSEG>
	 db	 9Ah		; Opcode for immediate far call
	 dw	 offset LAB	; ...to this label
L1	 dw	 SEL		; ...and selector
else
	 push	 RSEG		; Save return segment
	 push	 offset cs:L2	; ...	      offset

	 db	 0EAh		; Opcode for immediate far jump
	 dw	 offset LAB	; ...to this label
L1	 dw	 SEL		; ...and selector
L2:
endif				; IFB <RSEG>

IND	 instr	 <CODE..ECODE.LCODE.ICODE.JCODE.>,@CurSeg
if IND EQ 0
.err
endif				; IF IND EQ 0
CURGRP	 substr  <PGROUPPGROUPIGROUPIGROUPJGROUP>,IND,6

ifndef FGROUP
FGROUP	 group	 FIX_PGROUP, FIX_IGROUP, FIX_JGROUP

FIX_PGROUP segment use16 word public 'fixup'
FIX_PGROUP ends

FIX_IGROUP segment use16 word public 'fixup'
FIX_IGROUP ends

FIX_JGROUP segment use16 word public 'fixup'
FIX_JGROUP ends
endif				; IFNDEF

% FIX_&&CURGRP segment use16 word public 'fixup'
%	 dw	 offset CURGRP:L1
% FIX_&&CURGRP ends

	 endm			; FIXICALL

WBPAT_STR struc

WBPAT_PTR dd	 ?		; Far pointer to CALL instruction
WBPAT_LEN dw	 ?		; Length in bytes

WBPAT_STR ends

; Encodes a near or far call.  Adds 3 words to WBPAT_TAB: seg:offset of
; CALL instruction and length.
.xcref WBPAT
WBPAT	 macro	 CALLTARG,CURGRP
	 local	 L1,LEN

L1:
	 call	 CALLTARG	; Make near or far call
LEN = $-L1			; Length (3 or 5)

WBPAT_SEG segment use16 word public 'xdata'
	 WBPAT_STR <CURGRP:L1,LEN>
WBPAT_SEG ends

	 endm			; WBPAT

