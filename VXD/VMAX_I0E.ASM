;' $Header:   P:/PVCS/MAX/VXD/VMAX_I0E.ASV   1.0   05 Sep 1995 17:21:00   HENRY  $
	 title	 VMAX_I0E -- Page Fault Handler for the 386MAX VxD
	 page	 78,130
	 name	 VMAX_I0E

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-93 Qualitas, Inc.  GNU General Public License version 3.

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

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include 8259.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include ASCII.INC
	 include DEVDRV.INC
	 include DOSCALL.INC
	 include MAC.INC
	 include MAXDEV.INC

	 include QMAXWIN3.INC

	 include BREAK.INC
	 include VMAX.INC
.list


PTES_STR struc			; Structure to access page table entries

PTE	 dd	?		; PTE

PTES_STR ends			; End PTES_STR structure

	 page
VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 include VMAX_DBG.INC
	 extrn	 DBG_FLAG:word

	 extrn	 ROM_BMP:dword
	 extrn	 PF_V86_OLD:dword, PF_PM_OLD:dword

	 public  OLDCR2,CR2DATA,CR2OFF,CR2FLAG,CR2INT01_IVEC
OLDCR2	 dd	 ?		; Previous CR2
CR2DATA  dd	 4 dup (?)	; two dwords on eight side of page fault
CR2OFF	 dd	 ?		; Offset into PDE of the PTE
CR2PDE	 dd	 ?		; Linear address of PDE
CR2FLAG  dw	 ?		; Caller's flags
CR2INT01_IVEC IDT_STR <>	; Save area for previous INT 01h IDT entry

	 public  CT_ROMCFG,CT_RAM_AB,CT_RAM_CD,CT_RAM_EF
CT_ROMCFG db	 09h		; CHIPSet ROM configuration reg:  09h or 65h
CT_RAM_AB db	 0Dh		; ...	  RAM A000-C000     reg:  0Dh or 67h
CT_RAM_CD db	 0Eh		; ...	  RAM C000-E000     reg:  0Eh or 68h
CT_RAM_EF db	 0Fh		; ...	  RAM E000-10000    reg:  0Fh or 69h

PTE_C000 dd	 8 dup (0)	; Save area for C000-C800 VGA ROM PTEs

	 public  CR2_PTE
CR2_PTE  dd	 ?		; PTE associated with a CR2

	 include QMAX_CM2.INC
CM2_FLAG dw	0

	 include QMAX_DB2.INC
DB2_FLAG dw	0

	 include QMAX_GLB.INC
GLB_FLAG dw	0

	 include QMAX_LCL.INC
LCL_FLAG dw	0

SYSROM_START	dw	?

PFV86FLG db	 ?		; 1 if fault from V86 mode

VxD_LOCKED_DATA_ENDS		; End _LDATA segment

	 page
VxD_LOCKED_CODE_SEG		; Begin _LTEXT segment
	 assume  cs:FLAT

	 extrn	 PHYS2LIN:near

BeginProc PAGEFAULT_V86 	; Local handler for V86 mode page faults
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

PAGEFAULT

DESCRIPTION:
	Local handler for V86 Page Faults
ENTRY:
	EBX	=	Current VM handle
	EBP	==>	Client_Register_Structure

EXIT:
	This routine can handle the fault and continue execution via a RETN.
	All registers must be preserved when chaining on to the original
	Windows handler

|

	 mov	 PFV86FLG,1	; Remember it's from V86 mode

	 jmp	  short PFCOM	; Rejoin common code

BeginProc PAGEFAULT_PM		; Local handler for PM mode page faults

	 mov	 PFV86FLG,0	; Remember it's from PM
PFCOM:
	 pushad 		; Save caller's registers

	 mov	 eax,cr2	; Get address of fault
	 mov	 OLDCR2,eax	; Save for later use
	 shr	 eax,(12-0)	; Convert from linear address to V86 page #

	 cmp	 eax,0A0h	; Is it below the 1st ROM page?
	 jb	 PF_CHAIN	; Yes, let Windows' handler deal with it

	 cmp	 eax,0FFh	; Is it above the last ROM page?
	 ja	 PF_CHAIN	; Yes, let Windows' handler deal with it

	 sub	 ax,0A0h	; Convert from V86 page to ROM bitmap index

	 bt	 ROM_BMP,eax	; Test bit for this V86 page
	 jnc	 PF_CHAIN	; Jump if this page isn't cached

; The page fault is for one of our cached ROMs

	 add	 ax,0A0h	; Convert from ROM bitmap index to V86 page #
	 mov	 edx,eax	; V86 page #

	 call	 READ_CR3	; Get page directory anchor
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address

	 push	 eax		; Physical address of 1st PDE
	 push	 4		; Length of a PDE
	 call	 PHYS2LIN	; Get linear address of 1st PDE into EAX

; If the MapPhysToLinear fails, let the Windows page fualt code handle it

	 cmp	 eax,-1 	; Test for error return
	 je	 PF_CHAIN_BUG	; Chain to Windows handler if it failed

	 mov	 eax,[eax]	; Pick up 1st PDE
	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address

	 push	 eax		; Physical address of PTEs
	 push	 1024		; Length
	 call	 PHYS2LIN	; Get linear address of PTEs into EAX

; If the MapPhysToLinear fails, let the Windows page fualt code handle it

	 cmp	 eax,-1 	; Test for error return
	 je	 PF_CHAIN_BUG	; Chain to Windows handler if it failed

	 mov	 CR2PDE,eax	; Save linear address to PDE
	 shl	 edx,2		; Convert from page # to PDE index in DWORDS
	 mov	 CR2OFF,edx	; Save page # of faulting page within PDE

; EDX = Fault page # within PDE

	 mov	 edx,[eax+edx] ; Get PTE for faulting page

	 test	 edx,mask $PTE_RW ; Sanity test for R/W bit in PTE
	 jnz	 PF_CHAIN_BUG	; Oops, better let Windows handle it

	 mov	 esi,CR2OFF	; Page # of faulting page within PDE

	 BREAK	 DBG_FLAG,@DBG_INT0E ; Break if 386MAXInt0E=TRUE

COMMENT|

If the caller is not in video ROM and writing into itself, we must take
unusual action.  In particular, we allow the write to occur by executing
the instruction under our own single-step handler, and restore any damage
it might have done afterwards.

The technique used here is as follows:

* Set the read/write bit in the PTE so as to allow the write to occur
* Save the data in RAM which is to be modified
* Save the state of the caller's trap flag
* Set the trap flag in the caller's flags
* Save the address of the current single-step handler from the PM IDT
* Install our own local single-step handler in the PM IDT
* Restart the instruction

In our local single-step handler

* Restore the address of the previous single-step handler
* Restore the modified data
* Clear the read/write bit in the PTE for the next time
* Restore the state of the caller's trap flag
* Continue execution

We don't do this for all writes into ROM because paged-mode ROMs use a
write into ROM to bring in another page.  For writes into video ROMs by
the ROM itself, the old technique is still used.

|

	 and	 GLB_FLAG,not @GLB_ROM ; Kill ROM area swapped out flag

; Ignore check if user says so

	 test	 DB2_FLAG,@DB2_ROMSW ; Force ROM swap?
	 jnz	 INT0E_BLOCK	; Jump if so

; Ignore CS check if it's an MCA machine

	 test	 LCL_FLAG,@LCL_MCA ; Izit MCA-compatible?
	 jnz	 short INT0E_CHK ; Jump if so

; Check to see if the fault is into video ROM

	 mov	 eax,OLDCR2	; Get Page Fault Linear address

	 cmp	 eax,000C0000h	; Is the fault below video ROM?
	 jb	 short INT0E_CHK ; Jump if so

	 cmp	 eax,000C8000h	; Is the fault above video ROM?
	 jae	 short INT0E_CHK ; Jump if so

; The fault is into video ROM
; Check to see if the caller's CS is in video ROM -- avoid single-step
; technique if so

	 mov	 ax,[ebp].Client_CS ; Get V86 client's CS

	 cmp	 ax,0C000h	; Izit smaller than video ROM start?
	 jb	 short INT0E_CHK ; Jump if so

	 cmp	 ax,0C800h	; Izit larger than video ROM end?
	 jb	 INT0E_BLOCK	; Jump if it's within video ROM range
INT0E_CHK:

; Set the read/write bit in the PTE so as to allow the write to occur

	 mov	 eax,CR2PDE	; Linear address of PDE for faulting page
	 or	 [eax+esi].PTE,mask $PTE_RW ; Set it

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

; Save the data in RAM which is to be modified

; Note that we save eight bytes before and after the address in question
; because of 386 Errata # 5 which can allow two iterations of the
; instruction REP MOVS to occur before the single-step interrupt is
; signalled.  Because this instruction can be a dword move and we don't
; bother to detect the direction flag, we save the two dwords on either
; side of the page fault address.

	 mov	 ebx,OLDCR2	; Get Page Fault Linear address

	 mov	 eax,[ebx-08h] ; Get the 2nd preceding dword
	 mov	 CR2DATA[00h],eax ; Save to restore later

	 mov	 eax,[ebx-04h] ; Get the 1st preceding dword
	 mov	 CR2DATA[04h],eax ; Save to restore later

	 mov	 eax,[ebx+00h] ; Get the 1st following dword
	 mov	 CR2DATA[08h],eax ; Save to restore later

	 mov	 eax,[ebx+04h] ; Get the 2nd following dword
	 mov	 CR2DATA[0Ch],eax ; Save to restore later

; Save the state of the caller's trap and interrupt flag

INT0E_TRAP_GO:
	 mov	 ax,[ebp].Client_EFlags.ELO ; Get caller's low-order flags
	 and	 ax,(mask $TF) or (mask $IF) ; Isolate the trap and int flags
	 mov	 CR2FLAG,ax	; Save to restore later

;  Set the trap bit in the caller's flags

	 or	 [ebp].Client_EFlags.ELO,mask $TF ; Set trap bit
	 and	 [ebp].Client_EFlags.ELO,not (mask $IF) ; Kill interrupt bit

; Save the address of the current single-step handler from the PM IDT

	 sub	 esp,size DTR_STR ; Make room for IDTR
	 sidt	 [esp].EDF	; Save onto the stack
	 mov	 ebx,[esp].DTR_BASE ; Get the IDT base value
	 add	 esp,size DTR_STR ; Strip from the stack

	 mov	 eax,EDQLO[ebx+01h*(type IDT_STR)] ; Get 1st dword
	 mov	 CR2INT01_IVEC.EDQLO,eax ; Save to restore later
	 mov	 eax,EDQHI[ebx+01h*(type IDT_STR)] ; Get 2nd dword
	 mov	 CR2INT01_IVEC.EDQHI,eax ; Save to restore later

; Install our own local single-step handler in the PM IDT

	 mov	 eax,OFFSET32 CR2INT01 ; Get offset of our INT 01h handler

	 mov	 [ebx+01h*(type IDT_STR)].IDT_SELECT,cs
	 mov	 [ebx+01h*(type IDT_STR)].IDT_OFFLO,ax
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebx+01h*(type IDT_STR)].IDT_OFFHI,ax
;;;;;;	 mov	 [ebx+01h*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3+CPL3
	 mov	 [ebx+01h*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3

; Restart the instruction

	 popad			; Restore caller's registers

	 ret			; ... to instruction causing fault, via Windows


; Back off to beginning of this ROM block so we can swap the entire ROM
; in case it's a paged-mode ROM

INT0E_BLOCK:
	 mov	 eax,CR2PDE	; Linear address of PDE for faulting page
	 test	 [eax+esi-4].PTE,mask $PTE_RW ; Izit Read/Write?
	 jnz	 short INT0E_RWMIN ; Yes, we hit the end

	 sub	 esi,4		; Back off by one PTE

	 jmp	 short INT0E_BLOCK ; Go around again

INT0E_RWMIN:

; If this entry is in the C000-C800 segment, start testing at C000

	 cmp	 esi,0C800h shr ((12-2)-4) ; Check against C000-C800 limit
	 jae	 short INT0E_RWTEST ; It's outside that range

	 mov	 esi,0C000h shr ((12-2)-4) ; Use minimum
INT0E_RWTEST:
	 mov	 eax,CR2PDE	; Linear address of PDE for faulting page
	 test	 [eax+esi].PTE,mask $PTE_RW ; Izit Read/Write?
	 jz	 short INT0E_RESTPTE ; No, restore original PTE

; Zero out the PTE_C000[xxxx] entry for this page so we'll later know
; to leave it alone.

	 mov	 PTE_C000[esi-(0C0h*4)],0 ; Zero so we'll later know
				; this page is not swapped
	 jmp	 short INT0E_CHKLIM ; Rejoin common code

; Swap back to ROM the affected page
; Restore FS:SI entry in PDT to original ROM value

INT0E_RESTPTE:
	 call	 REST_PTE	; Restore 'em and flush page translation cache

INT0E_CHKLIM:
	 add	 esi,4		; Skip to next PTE

	 cmp	 esi,0C800h shr ((12-2)-4) ; Check against C000-C800 limit
	 jb	 short INT0E_RWTEST ; Still in range, continue testing

INT0E_EXIT:
; FIXME Page-mode ROMs with trap flag set?

; Join the common trap flag and restart code

	 jmp	 INT0E_TRAP_GO	; Join common restart code

; Let the original Windows Page Fault code handle it

PF_CHAIN_BUG:
PF_CHAIN:
	 popad			; Restore caller's registers

	 cmp	 PFV86FLG,0	; Izit from V86 mode?
	 je	 short @F	; Skip if not

	 jmp	 PF_V86_OLD	; Chain to original V86 Page Fault handler
@@:
	 jmp	 PF_PM_OLD	; Chain to original PM	Page Fault handler

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  PAGEFAULT_PM		; End PAGEFAULT_PM  procedure
EndProc  PAGEFAULT_V86		; End PAGEFAULT_V86 procedure

	 page
BeginProc READ_CR3		; Get Current Value of CR3
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

READ_CR3

DESCRIPTION:
	Read CR3 into EAX taking care to avoid spurious DRn breakpoints.

|

	 push	 ebx		; Save for a moment

	 mov	 ebx,dr7	; Get debug command register
	 push	 ebx		; Save on stack

; Clear G0-3 and L0-3

;;;;;;;; and	 ebx,not ((mask $G3) or (mask $G2) or (mask $G1) or (mask $G0)\
;;;;;;;;	       or (mask $L3) or (mask $L2) or (mask $L1) or (mask $L0))
	 mov	 bl,0		; Clear 'em this way
	 mov	 dr7,ebx	; Restore

	 mov	 eax,cr3	; Get current PDE base
	 jmp	 short $+2	; Drain the PIQ

	 pop	 ebx		; Get original DR7
	 mov	 dr7,ebx	; Restore

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  READ_CR3		; End READ_CR3 procedure

	 page
BeginProc READ_CHIPSET		; Read Command/Data from CHIPset
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

READ_CHIPSET

DESCRIPTION:
	Read data into AH from command register in AL in the CHIPset.

|

	 pushfd 		; Save flags
	 cli			; Disallow interrupts

	 out	 @CT_INDX,al	; Send command to CHIPset
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Copy value

	 in	 al,@CT_DATA	; Read data from CHIPset
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Return in data in AH, original command in AL

	 popfd			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  READ_CHIPSET		; End READ_CHIPSET procedure

	 page
BeginProc SEND_CHIPSET		; Send Command/Data to CHIPSet
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

SEND_CHIPSET

DESCRIPTION:
	Send data in AH to command register in AL in the CHIPSet.

|

	 REGSAVE <eax>		; Save caller's register

	 out	 @CT_INDX,al	; Send command to CHIPSet
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,ah		; Put data into AL
	 out	 @CT_DATA,al	; Send data to CHIPSet
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 REGREST <eax>		; Restore caller's register

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  SEND_CHIPSET		; End SEND_CHIPSET procedure

	 page
BeginProc FLUSH_TLB		; Flush Translation Lookaside Buffer
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

FLUSH_TLB

DESCRIPTION:
	Respecify CR3 to flush the TLB

|

	 REGSAVE <eax>		; Save caller's registers

	 call	 READ_CR3	; Get CR3 without causing debug exceptions

	 mov	 cr3,eax	; Flush the TLB

	 REGREST <eax>		; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  FLUSH_TLB

	 page
BeginProc CR2INT01		; CR2 Single-step Interrupt Handler
COMMENT|

CR2INT01

DESCRIPTION:
	Single-step interrupt handler.	This routine is called iff there is
	a page fault on a write into BCF or compressed ROM.

	We take the following actions:

	* Restore the address of the previous single-step handler
	* Restore the modified data
	* Clear the read/write bit in the PTE for the next time
	* Restore the state of the caller's trap flag
	* Continue execution

|

CR2INT01_STR struc		; Structure to access faulter

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
	 dw	 ?,?		; ...	   CS
CR2INT01_EFL dd  ?		; ...	   EFL

CR2INT01_STR ends		; End CR2INT01_STR structure

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ds,es> ; Save registers

; Setup DS and ES

	 push	 cs		; Get Windows' CS
	 add	 [esp].ELO,8	; Bump from Windows' CS to DS
	 mov	 es,[esp]	; Load ES = CS + 8
	 pop	 ds		; Load DS = CS + 8

; Restore the address of the previous single-step handler

	 sub	 esp,size DTR_STR ; Make room for IDTR
	 sidt	 [esp].EDF	; Save onto the stack
	 mov	 ebx,[esp].DTR_BASE ; Get the IDT base value
	 add	 esp,size DTR_STR ; Strip from the stack

	 mov	 eax,CR2INT01_IVEC.EDQLO ; Get 1st dword
	 mov	 EDQLO[ebx+01h*(type IDT_STR)],eax ; Restore
	 mov	 eax,CR2INT01_IVEC.EDQHI ; Get 2nd dword
	 mov	 EDQHI[ebx+01h*(type IDT_STR)],eax ; Restore

; See if we came back from a video ROM

	 test	 GLB_FLAG,@GLB_ROM ; Mark as some ROM area swapped out
	 jz	 CR2I0E_RMD	; Join code to handle normal case

; Handle the special case of a page-mode video ROM

	 pushad 		; Save all EGP registers

; Copy the data out of the actual ROMs into the caching area

	 mov	 ecx,8		; # of PTEs in region
CR2I0E_CVR:
	 mov	 eax,PTE_C000[ecx*4-4] ; Get next PTE for RAM caching area

	 or	 eax,eax	; Wazit swapped?
	 jz	 short CR2I0E_LOOP ; Skip swap back if not

	 and	 eax,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate address

	 push	 eax		; Physical address of RAM
	 push	 4096		; Length of a page
	 call	 PHYS2LIN	; Get linear address of RAM into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Skip error

	 VMMcall Fatal_Memory_Error ; Bug out of Windows
@@:
	 mov	 edi,eax	; Destination of move

	 mov	 eax,ecx	; Get count
	 dec	 eax		; Convert from count to index
	 shl	 eax,12 	; Convert from bytes to 4KB pages
	 add	 eax,0C0000h	; Add offset to get source address in video ROM

	 push	 eax		; Physical address of ROM
	 push	 4096		; Length of a page
	 call	 PHYS2LIN	; Get linear address of ROM into EAX

	 cmp	 eax,-1 	; Test for error return
	 jne	 short @F	; Skip error

	 VMMcall Fatal_Memory_Error ; Bug out of Windows
@@:
	 mov	 esi,eax	; Source of move

	 push	 ecx		; Save index
	 mov	 ecx,4096/4	; Number of double words to copy
S32	 rep movsd		; Copy actual video ROM to RAM caching area
	 pop	 ecx		; Restore index

CR2I0E_LOOP:
	 loop	 CR2I0E_CVR	; Continue until all video ROMs are copied

; Swap the PTEs to reenable the ROM caching
; FIXME It might not be a great idea to blast these in directly.
; FIXME It might foul up WIN386's idea of what's where.

	 mov	 ecx,8		; # of PTEs in region
	 mov	 edx,CR2PDE	; Linear address of PDE for faulting page
CR2I0E_RVRP:
	 mov	 eax,PTE_C000[ecx*4-4] ; Get next PTE for ROM caching area

	 or	 eax,eax	; Wazit swapped?
	 jz	 short CR2I0E_RVRLOOP ; Skip replacement if not

	 mov	 [edx+ecx*4+((0C0h*4)-4)],eax ; Restore ROM caching PTE for page

CR2I0E_RVRLOOP:
	 loop	 CR2I0E_RVRP	; Continue until all video ROM PTEs are replaced

	 popad			; Restore all EGP registers

	 jmp	 short CR2I0E_FTLB ; Rejoin common case

; Restore the modified data
CR2I0E_RMD:
	 mov	 ebx,OLDCR2	; Get page fault linear address

	 mov	 eax,CR2DATA[00h] ; Get the 2nd preceding dword
	 mov	 [ebx-08h],eax	; Save back

	 mov	 eax,CR2DATA[04h] ; Get the 1st preceding dword
	 mov	 [ebx-04h],eax	; Save back

	 mov	 eax,CR2DATA[08h] ; Get the 1st following dword
	 mov	 [ebx+00h],eax	; Save back

	 mov	 eax,CR2DATA[0Ch] ; Get the 2nd following dword
	 mov	 [ebx+04h],eax	; Save back

; Clear the read/write bit in the PTE for the next time

	 mov	 ebx,CR2OFF	; ESI ==> PTE in PDE of page fault
	 mov	 eax,CR2PDE	; Linear address of PDE for faulting page
	 and	 [eax+ebx].PTE,not (mask $PTE_RW) ; Clear it

; Because we just changed the page table, we must flush the TLB
CR2I0E_FTLB:
	 call	 FLUSH_TLB	; Flush the TLB

; Restore the state of the caller's trap and interrupt flags

	 and	 [ebp].CR2INT01_EFL.ELO,not ((mask $TF) or (mask $IF))
	 mov	 ax,CR2FLAG	; Get caller's trap and interrupt flags
	 or	 [ebp].CR2INT01_EFL.ELO,ax ; Set caller's value

; Continue execution

	 REGREST <es,ds,ebx,eax> ; Restore caller's registers

	 pop	 ebp		; Restore any previous stack frame

	 iretd			; ... just past faulting instruction

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  CR2INT01		; End CR2INT01 procedure

	 page
BeginProc REST_PTE		; Restore PTEs
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

REST_PTR

DESCRIPTION:
	Restore PTE at ESI with default ROM value.
	Flush page translation cache.

|

	 REGSAVE <eax,ecx,edx>	; Save registers

	 mov	 edx,CR2PDE	; Linear address of PDE for faulting page
	 mov	 eax,[edx+esi]	; Get original PTE for page
	 mov	 PTE_C000[esi-(0C0h*4)],eax ; Save original PTE for page

	 mov	 eax,esi	; Copy offset
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present

	 mov	 [edx+esi],eax	 ; Save in lowmem area

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 or	 GLB_FLAG,@GLB_ROM ; Mark as some ROM area swapped out

; If we're on a shadow RAM system, restore the old CHIPset register value

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short REST_PTE_EXIT ; Not this time

	 shr	 eax,14-0	; Convert from bytes to 16KB

	 sub	 ax,0A000h shr (14-4) ; Convert to origin-A000
	 jc	 short REST_PTE_EXIT ; Jump if bananas

	 mov	 ch,CT_RAM_AB	; Register #

	 cmp	 ax,(0C000h-0A000h) shr (14-4) ; Check for range
	 jb	 short REST_PTE1 ; Jump if within range

	 sub	 ax,(0C000h-0A000h) shr (14-4) ; Convert to origin-C000
	 mov	 ch,CT_RAM_CD	; Register #

	 cmp	 ax,(0E000h-0C000h) shr (14-4) ; Check for range
	 jb	 short REST_PTE1 ; Jump if within range

	 sub	 ax,(0E000h-0C000h) shr (14-4) ; Convert to origin-E000
	 mov	 ch,CT_RAM_EF	; Register #

	 cmp	 al,04h 	; Izit F000 or greater?
	 jae	 short REST_PTE_EXIT ; Yes, don't reset CHIPset
REST_PTE1:
	 mov	 cl,al		; Copy to count register

	 mov	 al,ch		; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH

	 mov	 al,1		; Set strobe bit
	 shl	 al,cl		; Shift into position
	 or	 ah,al		; Set the bit

	 mov	 al,ch		; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPset
REST_PTE_EXIT:
	 REGREST <edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  REST_PTE		; End REST_PTE procedure

VxD_LOCKED_CODE_ENDS		; End _LTEXT segment

	 MEND			; End VMAX_I0E module
