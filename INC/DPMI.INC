;' $Header:   P:/PVCS/MAX/INC/DPMI.INV   1.1   15 Jun 1998 16:02:14   BOB  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; DPMI.INC
;
; DPMI function equates and structures
;

DPMIFMI_STR struc

DPMIFMI_LBFREE dd ?		; 00:  Largest available free block in bytes
				;      (largest bytes free)
DPMIFMI_LPUNLK dd ?		; 04:  Maximum unlocked page allocation in pages
				;      (largest pages unlocked)
DPMIFMI_LPLOCK dd ?		; 08:  Maximum locked page allocation in pages
				;      (largest pages locked)
DPMIFMI_TPMEM1 dd ?		; 0C:  Linear address space size in pages
				;      (total pages of memory -- free or not)
DPMIFMI_TPUNLK dd ?		; 10:  Total # unlocked pages
				;      (total pages unlocked -- may be swapped)
DPMIFMI_TPFREE dd ?		; 14:  Total # free pages
				;      (total pages free)
DPMIFMI_TPMEM2 dd ?		; 18:  Total # physical pages
				;      (total pages of memory -- free or not)
DPMIFMI_APFREE dd ?		; 1C:  Free linear address space in pages
				;      (available pages of memory)
DPMIFMI_PFILE  dd ?		; 20:  Size of paging file/partition in pages
DPMIFMI_RSV dd	 3 dup (-1)	; 24:  reserved (all bytes set to 0FFh)

DPMIFMI_STR ends


; These functions are used via the INT 2Fh multiplex interrupt

@DPMI_RELSLICE	 equ	1680h	; Release Current VM Time Slice
@DPMI_BEG_CRST	 equ	1681h	; Begin Critical Section
@DPMI_END_CRST	 equ	1682h	; End ...
@DPMI_CPUMODE	 equ	1686h	; Get CPU Mode
@DPMI_GPME	 equ	1687h	; Get Real to Protected Mode Switch Entry
@DPMI_API2F	 equ	168Ah	; Get Vendor-Specific API Entry Point

W386_Release_Time	EQU	80h	; Release cur VM's time-slice
W386_Begin_Critical	EQU	81h	; Begin critical section
W386_End_Critical	EQU	82h	; End critical section
W386_Get_Cur_VMID	EQU	83h	; Returns BX = ID of current VM
W386_Get_Device_API	EQU	84h	; Returns ES:DI -> Device API
W386_Switch_And_Call	EQU	85h	; Change VMs and call-back
W386_Test_Int31_Avail	EQU	86h	; Returns AX=0 if Int 31 avail
W386_Get_PM_Switch_Addr EQU	87h	; Get call-back addr for PM
W386_Get_LDT_Base_Sel	EQU	88h	; Get selector to LDT
W386_Win_Kernel_Idle	EQU	89h	; Windows kernel idle call

@DPMI_EPM_32	 equ	0001h	; Client program is USE32


; DPMI NDP Emulation record (for @DPMI_EMUGET).
; The low-order two bits are valid for @DPMI_EMUSET.

NDPEMU_REC record $NDPEMU_TYP:4, \
		  $NDPEMU_EMr:1, \
		  $NDPEMU_MPr:1, \
		  $NDPEMU_EMv:1, \
		  $NDPEMU_MPv:1

; $NDPEMU_TYP	 Bits 4-7:	00 = no coprocessor,
;				01 = reserved
;				02 = 80287
;				03 = 80387
;				04 = 80486 DX or 80486 SX
;				05 = 80586 DX or 80586 SX
; $NDPEMU_EMr	 Bit 3: 	1 = Host is emulating NDP instructions
; $NDPEMU_MPr	 Bit 2: 	1 = NDP is present
; $NDPEMU_EMv	 Bit 1: 	1 = client is emulating NDP instructions
; $NDPEMU_MPv	 Bit 0: 	1 = NDP is enabled for this client


; Get/Set Page Attribute record (functions 0506h/0507h)

SPATTR_REC record $SPATTR_RSVD:9, \
		$SPATTR_DIRTY:1,  \
		$SPATTR_ACC:1,	  \
		$SPATTR_MOD:1,	  \
		$SPATTR_RW:1,	  \
		$SPATTR_TYP:3

;					 Bit
@SPATTR_RSVD  equ (mask $SPATTR_RSVD)  ; 7-15: Reserved
@SPATTR_DIRTY equ (mask $SPATTR_DIRTY) ;  6:   Mark page as dirty
@SPATTR_ACC   equ (mask $SPATTR_ACC)   ;  5:   Mark page as accessed
@SPATTR_MOD   equ (mask $SPATTR_MOD)   ;  4:   Set dirty/accessed bits
@SPATTR_RW    equ (mask $SPATTR_RW)    ;  3:   Mark page as read/write
@SPATTR_TYP   equ (mask $SPATTR_TYP)   ; 0-2:  Page type (see @SPTYP_xxx bits)

@SPTYP_UNC equ	 0		; Create page uncommitted
@SPTYP_COM equ	 1		; Create page committed
@SPTYP_MOD equ	 3		; Modify attributes (bits 3-6) only


VMC_STR  struc			; VM call structure

VMC_EDI  dd	 ?		; 00-03:  EDI to use in VM
VMC_ESI  dd	 ?		; 04-07:  ESI ...
VMC_EBP  dd	 ?		; 08-0B:  EBP ...
	 dd	 ?		; 0C-0F:  (reserved)
VMC_EBX  dd	 ?		; 10-13:  EBX ...
VMC_EDX  dd	 ?		; 14-17:  EDX ...
VMC_ECX  dd	 ?		; 18-1B:  ECX ...
VMC_EAX  dd	 ?		; 1C-1F:  EAX ...
VMC_FL	 dw	 ?		; 20-21:  FL ...
VMC_ES	 dw	 ?		; 22-23:  ES ...
VMC_DS	 dw	 ?		; 24-25:  DS ...
VMC_FS	 dw	 ?		; 26-27:  FS ...
VMC_GS	 dw	 ?		; 28-29:  GS ...
VMC_IP	 dw	 ?		; 2A-2A:  IP ...
VMC_CS	 dw	 ?		; 2C-2D:  CS ...
VMC_SP	 dw	 ?		; 2E-2F:  SP ...
VMC_SS	 dw	 ?		; 30-31:  SS ...

VMC_STR  ends


; The remaining functions are used with INT 31h

; LDT Descriptor Management Services

@DPMI_GETLDT	 equ	0000h	; [0.9] Allocate LDT Selectors
@DPMI_RELLDT	 equ	0001h	; [0.9] Free an LDT Selector
@DPMI_SEG2SEL	 equ	0002h	; [0.9] Convert Segment to Selector
@DPMI_NXTSEL	 equ	0003h	; [0.9] Get Next Selector Increment Value
@DPMI_LCKSEG	 equ	0004h	; [0.8] Lock Linear Region using selector
@DPMI_UNLSEG	 equ	0005h	; [0.8] Unlock Linear Region using selector
@DPMI_GSELBAS	 equ	0006h	; [0.9] Get Selector Base Address
@DPMI_SSELBAS	 equ	0007h	; [0.9] Set Selector Base Address
@DPMI_SSELLIM	 equ	0008h	; [0.9] Set Selector Limit
@DPMI_SSELARW	 equ	0009h	; [0.9] Set Selector Access Rights Word
@DPMI_GETALIAS	 equ	000Ah	; [0.9] Get Selector Alias
@DPMI_GETLDTE	 equ	000Bh	; [0.9] Get LDT Entry
@DPMI_SETLDTE	 equ	000Ch	; [0.9] Set LDT Entry
@DPMI_GETRLDT	 equ	000Dh	; [0.9] Allocate Reserved LDT Selector
@DPMI_GETMLDTE	 equ	000Eh	; [1.0] Get Multiple LDT Entries
@DPMI_SETMLDTE	 equ	000Fh	; [1.0] Set Multiple LDT Entries

; DOS Memory Management Services

@DPMI_GETDMEM	 equ	0100h	; [0.9] Allocate DOS Memory Block
@DPMI_RELDMEM	 equ	0101h	; [0.9] Free DOS Memory Block
@DPMI_MODDMEM	 equ	0102h	; [0.9] Resize DOS Memory Block

; Interrupt Management Services

@DPMI_GETVMIV	 equ	0200h	; [0.9] Get VM Interrupt Vector
@DPMI_SETVMIV	 equ	0201h	; [0.9] Set VM Interrupt Vector
@DPMI_GETPEHV	 equ	0202h	; [0.9] Get Processor Exception Handler Vector
@DPMI_SETPEHV	 equ	0203h	; [0.9] Set Processor Exception Handler Vector
@DPMI_GETPMIV	 equ	0204h	; [0.9] Get Protected Mode Interrupt Vector
@DPMI_SETPMIV	 equ	0205h	; [0.9] Set Protected Mode Interrupt Vector
@DPMI_GETEPMPEHV equ	0210h	; [1.0] Get Extended PM Proc Exception Handler
@DPMI_GETEVMPEHV equ	0211h	; [1.0] Get Extended VM Proc Exception Handler
@DPMI_SETEPMPEHV equ	0212h	; [1.0] Set Extended PM Proc Exception Handler
@DPMI_SETEVMPEHV equ	0213h	; [1.0] Set Extended VM Proc Exception Handler
@DPMI_SETPEHVWIN equ	0283h	; [Win] Set Processor Exception Handler Vector

@DPMI_INTCLI	 equ	0900h	; [0.9] Get & Disable Virtual Interrupt State
@DPMI_INTSTI	 equ	0901h	; [0.9] Get & Enable Virtual Interrupt State
@DPMI_GETIF	 equ	0902h	; [0.9] Get Virtual Interrupt State

; Translation Services

@DPMI_SIMVMI	 equ	0300h	; [0.9] Simulate VM Interrupt
@DPMI_SIMVMCFR	 equ	0301h	; [0.9] Simulate VM Call With Far Return
@DPMI_SIMVMCIR	 equ	0302h	; [0.9] Simulate VM Call With IRET Return
@DPMI_GETVMCB	 equ	0303h	; [0.9] Allocate VM Callback Address
@DPMI_RELVMCB	 equ	0304h	; [0.9] Free VM Callback Address
@DPMI_GETSSR	 equ	0305h	; [0.9] Get State Save/Restore Addresses
@DPMI_GETRMS	 equ	0306h	; [0.9] Get Raw Mode Switch Addresses

; Extended Memory Management Services

@DPMI_GETFMI	 equ	0500h	; [0.9] Get Free Memory Information
@DPMI_GETMEM	 equ	0501h	; [0.9] Allocate Memory Block
@DPMI_RELMEM	 equ	0502h	; [0.9] Free Memory Block
@DPMI_MODMEM	 equ	0503h	; [0.9] Resize Memory Block
@DPMI_GETLMB	 equ	0504h	; [1.0] Allocate Linear Memory Block
@DPMI_MODLMB	 equ	0505h	; [1.0] Resize Linear Memory Block
@DPMI_GPGATTR	 equ	0506h	; [1.0] Get Page Attributes
@DPMI_SPGATTR	 equ	0507h	; [1.0] Set Page Attributes
@DPMI_MAPDEV	 equ	0508h	; [1.0] Map Device in Memory Block
@DPMI_MAPCONV	 equ	0509h	; [1.0] Map Conventional Memory in Memory Block
@DPMI_GETMBLKSZ  equ	050Ah	; [1.0] Get Memory Block Size & Base
@DPMI_GETMEMI	 equ	050Bh	; [1.0] Get Memory Information

@DPMI_GETP2L	 equ	0800h	; [0.9] Get Physical to Linear Address Mapping
@DPMI_RELP2L	 equ	0801h	; [1.0] Free Physical to Linear Address Mapping

@DPMI_GETSHR	 equ	0D00h	; [1.0] Allocate Shared Memory
@DPMI_RELSHR	 equ	0D01h	; [1.0] Free Shared Memory
@DPMI_SERIALIZE  equ	0D02h	; [1.0] Serialize on Shared Memory
@DPMI_RELSERIAL  equ	0D03h	; [1.0] Free Serialization on Shared Memory

; Page Management Services

@DPMI_LOCKLINREG equ	0600h	; [0.9] Lock Linear Region
@DPMI_UNLKLINREG equ	0601h	; [0.9] Unlock Linear Region
@DPMI_PAGEVM	 equ	0602h	; [0.9] Mark VM Region as Pageable
@DPMI_RLCKVM	 equ	0603h	; [0.9] Relock VM Region
@DPMI_GETPAGESIZ equ	0604h	; [0.9] Get Page Size

@DPMI_PGUNLK	 equ	0702h	; [0.9] Mark Page as Pageable
@DPMI_PGFREE	 equ	0703h	; [0.9] Mark Page as Discardable

; Debug Support Services

@DPMI_DBGSET	 equ	0B00h	; [0.9] Set Debug Watchpoint
@DPMI_DBGCLR	 equ	0B01h	; [0.9] Clear Debug Watchpoint
@DPMI_DBGQRY	 equ	0B02h	; [0.9] Query State of Debug Watchpoint
@DPMI_DBGRST	 equ	0B03h	; [0.9] Reset Debug Watchpoint

; Miscellaneous Services

@DPMI_GETVER	 equ	0400h	; [0.9] Get Version Information
@DPMI_GETCAP	 equ	0401h	; [1.0] Get DPMI Capabilities

@DPMI_VSAPI	 equ	0A00h	; [0.9] Get Vendor-Specific API Entry Point

@DPMI_TSRSRV	 equ	0C00h	; [1.0] Install Resident Service Provider CB
@DPMI_TSRXIT	 equ	0C01h	; [1.0] Terminate & Stay Resident

@DPMI_EMUGET	 equ	0E00h	; [1.0] Get Coprocessor Status
@DPMI_EMUSET	 equ	0E01h	; [1.0] Set Coprocessor Emulation

; Error codes

@DPMIERR_UNK	  equ	8001h	; Unsupported function
@DPMIERR_BADSTATE equ	8002h	; Invalid state
@DPMIERR_SYSINT   equ	8003h	; System integrity
@DPMIERR_DEADLOCK equ	8004h	; Deadlock
@DPMIERR_REQCAN   equ	8005h	; Request cancelled
@DPMIERR_NORES	  equ	8010h	; Resource unavailable
@DPMIERR_NODTE	  equ	8011h	; Descriptor unavailable
@DPMIERR_NOLMEM   equ	8012h	; Linear memory unavailable
@DPMIERR_NOPMEM   equ	8013h	; Physical memory unavailable
@DPMIERR_NOBSS	  equ	8014h	; Backing store unavailable
@DPMIERR_NOCALLB  equ	8015h	; Callback unavailable
@DPMIERR_NOHNDL   equ	8016h	; Handle unavailable
@DPMIERR_LOCKOVF  equ	8017h	; Lock count exceeded
@DPMIERR_RESEXCL  equ	8018h	; Resource owned exclusively
@DPMIERR_RESSHAR  equ	8019h	; Resource owned shared
@DPMIERR_BADVALUE equ	8021h	; Invalid value
@DPMIERR_BADSEL   equ	8022h	; Invalid selector
@DPMIERR_BADHNDL  equ	8023h	; Invalid handle
@DPMIERR_BADCALLB equ	8024h	; Invalid callback
@DPMIERR_BADLADDR equ	8025h	; Invalid linear address
@DPMIERR_BADREQ   equ	8026h	; Invalid request


DPMICALL macro	 FNCODE

ifnb	<FNCODE>
	 mov	 ax,FNCODE	; Get subfunction
endif				; IFNB <FNCODE>
	 int	 31h		; Request DPMI service

	 endm			; DPMICALL


DPMICALL0 macro  FNCODE 	; DPMICALL from PL0

ifnb	<FNCODE>
	 mov	 ax,FNCODE	; Get subfunction
endif				; IFNB <FNCODE>
	 PUSHD	 ss		; Simulate PL3 ring transition
	 push	 esp		; ...by saving SS|ESP
	 add	 [esp].EDD,4	; Add so that SS:ESP on stack points to the
				; PL0 stack before this call
	 int	 31h		; Request DPMI service
	 lea	 esp,[esp+2*4]	; Strip from the stack w/o modifying flags

	 endm			; DPMICALL0

