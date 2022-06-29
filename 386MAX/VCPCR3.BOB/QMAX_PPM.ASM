;' $Header:   P:/PVCS/MAX/386MAX/QMAX_PPM.ASV   1.2   30 May 1997 10:45:54   BOB  $
	 title	 QMAX_PPM -- DPMI Physical Page Manager functions
	 page	 58,122
	 name	 QMAX_PPM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-2000 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'

Program derived from:  None.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include MASM5.MAC
	 include ALLMEM.INC
	 include PTR.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_SHD.INC
.list
if @OEM_VIRTUALMEM

PGROUP	 group	 ECODE,EDATA
IGROUP	 group	 LDATA,ICODE,IDATA


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FALLOCMEM:far
	 extrn	 FDEALLOCMEM:far
	 extrn	 FQRY_PGCNT:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 VMM_FLAG:word
	 include QMAX_VMM.INC

	 extrn	 PHYSIZE:dword
	 extrn	 SHDCNT:word
	 extrn	 SHDTAB:byte
	 extrn	 SEL_DSIG3:word

PrimaryAllocInProg db 0 	; Primary allocate in progress flag

EDATA	 ends			; End EDATA segnmebt


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:WORD	 ; PGROUP selector
	 extrn	 ISEL_DSIG3:WORD ; IGROUP ...
	 extrn	 ISEL_4GB3:WORD  ; AGROUP ...

LDATA	 ends			; End LDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 VMMcurrentClient:WORD	 ; id of current client
	 extrn	 VMMcurrentTime:WORD	 ; current paging time
	 extrn	 BSTotal:DWORD		 ; amount of total backing store
	 extrn	 BSInUse:DWORD		 ; amount of backing store in use
	 extrn	 BSActive:BYTE		 ; swapping (and page-aging)started
	 extrn	 VirtualReserved:DWORD	 ; number of reserved virtual pages

	 public  PhysicalLocked, PhysicalMinUnlocked, PhysicalTotal
	 public  PhysicalInUse, nRegions, RegionTable, PhysicalManaged
	 public  PhysicalSwappable, PhysicalFreeListHead

PPMinitialized		db	0	; initialized flag

PhysicalLocked		dd	?	; number of physical pages
					;  currently locked
PhysicalMinUnlocked	dd	?	; min number of physical pages
					;  that must be kept unlocked
PhysicalFreeListHead	dd	?	; head of physical free list
					; -1 if list is empty
PhysicalTotal		dd	?	; total page count for system
PhysicalManaged 	dd	0	; number of physical pages currently
					;   managed by PPM
PhysicalInUse		dd	?	; number of managed pages currently
					;   in use (by clients and system)
nRegions		db	?	; number of contiguous regions
PhysicalSwappable	dd	?	; number of in-use swappable pages

	 public  TotalPPRSize,PPRBaseAddress
TotalPPRSize		dd	?	; size (bytes) of PhysicalPageRecord
					;    array (/4KB)
PPRBaseAddress		dd	?	; base address of PPR array

NeedToFillPool		db	?	; flag: call primary mgr for memory


RegionTable	PhysicalRegion @MAXREGIONS dup (<0,0,0>)


IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 VMM_SWAP_OUT:near

	 public  @QMAX_PPM_ICODE
@QMAX_PPM_ICODE:

	 NPPROC  PPM_GET_PAGE_RECORD -- Get address of page record
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Locate physical page record for a given page. This routine just walks
the region table until it finds the region in which the specified page
resides, then makes an arithmetic calculation to determine the address
of the PhysicalPageRecord.

On entry:

EBX	 =	 physical address of page for which to get record

On exit:

ESI	 =	 linear address of physical page record

|

	 REGSAVE <eax,ebx,cx,di> ; Save registers

	 movzx	 cx,nRegions	; Pick up region count
	 lea	 di,RegionTable ; Point at region table
	 and	 ebx,not $clientMask ; Discard low bits
PPM_GPR_NEXTREGION:
	 mov	 esi,ebx	; Copy physical address

	 sub	 esi,IGROUP:[di].PRbase ; ESI <- input addr less region base
	 jb	 short PPM_GPR_LOOP ; Jump if page below this region

	 shr	 esi,@BytePage ; ESI <- page count of offset

	 cmp	 esi,IGROUP:[di].PRsize ; In this region?
	 jb	 short PPM_GPR_EXIT ; Jump if so
PPM_GPR_LOOP:
	 add	 di,size PhysicalRegion ; Try next region

	 loop	 PPM_GPR_NEXTREGION ; Go again
PPM_GPR_FAIL:
	 int	 3		; Shouldn't happen

	 jmp	 short PPM_GPR_FAIL ; Tried all regions - didn't find it

PPM_GPR_EXIT:
	 imul	 esi,size PhysicalPageRecord ; Times record size to get offset
	 add	 esi,IGROUP:[di].PRtable ; Add table base to get address of rec

	 REGREST <di,cx,ebx,eax> ; Restore regs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_GET_PAGE_RECORD endp	; End PPM_GET_PAGE_RECORD procedure
	 NPPROC  PPM_SETPHYSMU -- Set PhysicalMinUnlocked
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set PhysicalMinUnlocked.

Use a value for PhysicalMinUnlocked which is the smaller of @PhysMin
and PhysicalManaged/2.	That way we can fail less often in a starved
memory configuration as some DPMI clients (MS C7) don't correctly
handle failure of the switch entry point.  Furthermore, this value
must be at least as large as the minimum number of pages which can be
touched by a single instruction.  By my count this is 6 for (say) a
CALL Dword ptr [....] which references two pages via the Dword ptr,
two pages to push the address onto the stack, and two pages for the
first instruction in the new routine.  Note that we're assuming that
the GDT/LDT are in locked memory, otherwise we need to add three more
pages to this count.

|

	 REGSAVE <eax>		; Save register

@PhysMinMax equ  16		; Maximum value for PhysicalMinUnlocked
@PhysMinMin equ   6		; Minimum ...

	 mov	 eax,PhysicalManaged ; Get # pages managed
	 shr	 eax,1		; Divide by two to compare

	 cmp	 eax,@PhysMinMax ; Izit smaller than we ever thought reasonable?
	 jb	 short @F	; Jump if so

	 mov	 eax,@PhysMinMax ; Use maximum working set
@@:
	 cmp	 eax,@PhysMinMin ; Izit no worse than our minimum?
	 jae	 short @F	; Jump if so

	 mov	 eax,@PhysMinMin ; Use minimum working set
@@:
	 mov	 PhysicalMinUnlocked,eax ; Save as minimum working set

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_SETPHYSMU endp		; End PPM_SETPHYSMU procedure
	 NPPROC  PPM_INIT -- Initialize Physical Page Manager
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize Physical Page Manager

This function has two things to get done:

(1) It must set up the RegionTable, which is an array of
PhysicalRegion structures.  The first entry always corresponds
to the contiguous physical memory starting at zero.  Subsequent
entries, if any, are taken from the SHDTAB data structure which
resides in PGROUP.

(2) It must allocate and zero out pages for the PhysicalPageRecords.
The number of pages depends on the total size of physical memory.

On exit:

CF	 =	 0 ==> ok
	 =	 1 ==> failure
AX	 =	 error code

|

	 REGSAVE <ebx,ecx,edx,esi,edi,es> ; Save registers

; Initialize the free list for physical memory.  There are no
; pages actually in the list until PPM_FILL_POOL is called.

	 mov	 PhysicalFreeListHead,-1 ; free list initially empty
	 xor	 eax,eax		; make a zero
	 mov	 PhysicalManaged,eax	; init location
	 mov	 PhysicalInUse,eax	; ...
	 mov	 PhysicalSwappable,eax	; ...
	 mov	 PhysicalLocked,eax	; ...
					; Build the RegionTable
	 mov	 eax,PHYSIZE		; Pick up total machine size in KB
	 shr	 eax,12-10		; Convert KB to pages
	 mov	 PhysicalTotal,eax	; Size in pages of contiguous RAM
					;   starting at physical address 0
	 mov	 nRegions,1		; Init region count
	 xor	 di,di			; Initialize index into region table
	 mov	 RegionTable[di].PRbase,0 ; Base is addr 0
	 mov	 RegionTable[di].PRsize,eax ; EAX == PhysicalTotal
	 mov	 ebx,eax		; Copy page count
	 shl	 ebx,@BytePage		; EBX <- address of top of 1st region

	 mov	 cx,SHDCNT		; Get count of "shadow" regions
	 xor	 si,si			; Initialize index into shadow table

	 cmp	 cx,@MAXREGIONS-1	; Too many shadow regions?
	 jbe	 short @F		; Jump if not

	 mov	 cx,@MAXREGIONS-1	; That's the max
@@:
	 jcxz	 PPM_INIT_SHDDONE	; Jump if done
PPM_INIT_NEXTSHD:			; SI --> SHDTAB  DI --> RegionTab
	 add	 di,size PhysicalRegion ; Point at next physical region

	 cmp	 ebx,SHDTAB[si].SHD_EBASE ; Is top of 1st region above base?
	 jae	 short @F		; Jump if so

	 inc	 nRegions		; increment region count
	 mov	 eax, SHDTAB[si].SHD_EBASE ; Get this shadow region base
	 mov	 RegionTable[di].PRbase,eax ; Copy to physical region base
	 movzx	 eax, SHDTAB[si].SHD_ESIZE ; Get shadow region size
	 shr	 eax,12-10		; Convert 1kb to page (4kb)
	 mov	 RegionTable[di].PRsize,eax ; Store in physical region struc
	 add	 PhysicalTotal,eax	; Tally physical total
@@:
	 add	 si,size SHD_STR	; Point to next shadow

	 loop	 PPM_INIT_NEXTSHD	; Do next
PPM_INIT_SHDDONE:
	 imul	 eax,PhysicalTotal,size PhysicalPageRecord ; Get total page
					; count in bytes
	 add	 eax,@PageSize-1	; Round up to page
	 and	 eax,not (@PageSize-1)	; EAX <- size of PPRs in bytes
	 mov	 TotalPPRSize,eax	; Remember it for shutdown

; Now allocate the memory

	 push	 ds			; Save

	 mov	 ds,ISEL_DS3		; Get PGROUP data selector at PL3
	 assume  ds:PGROUP		; Tell the assembler about it

	 push	 @ALLOC_VCPI		; Will look like a VCPI alloc
	 push	 eax			; Push size to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Returns linear addr in ebx
	 pop	 ds			; Restore
	 assume  ds:IGROUP		; Tell the assembler about it
	 mov	 ax,@DERR_INSUFF_PHYS	; Return error code
	 jc	 short PPM_INIT_EXIT	; Carry set on fail

; Now set up each region with the correct base address for its PPR array

	 mov	 PPRBaseAddress,ebx	; Remember this for shutdown
	 movzx	 cx,nRegions		; Init region counter
	 xor	 di,di			; Initialize index into region table
PPM_INIT_REGION_BASE:
	 mov	 RegionTable[di].PRtable,ebx ; Set table address for region

; Now calculate base of next region based on size of this region

	 imul	 eax,RegionTable[di].PRsize,size PhysicalPageRecord
					 ; EAX <- size of region in pages
	 add	 ebx,eax		 ; Table base for next region
	 add	 di,size PhysicalRegion  ; Advance to next record

	 loop	 PPM_INIT_REGION_BASE	 ; do next if not done

; Now zero out the PPR array

	 mov	 es, ISEL_4GB3		 ; es <- AGROUP (all memory)
	 assume  es:AGROUP		 ; tell assembler

	 mov	 edi,PPRBaseAddress	 ; edi <- base of PPR array
	 mov	 ecx,TotalPPRSize	 ; ecx <- size of PPRs in bytes (/4KB)
	 shr	 ecx,2			 ; ecx <- size of PPRs in dwords
	 xor	 eax,eax		 ; eax <- zero
	 cld
     rep stos	 AGROUP:[edi].EDD	 ; zero out the PPR array
PPM_INIT_DONE:
	 mov	 PrimaryAllocInProg, 0	 ; set location
	 mov	 PPMinitialized, 1	 ; ...
	 mov	 NeedToFillPool, 1	 ; flag fill of page pool needed
	 call	 PPM_SETPHYSMU	; Set PhysicalMinUnlocked

	 clc			; Success
PPM_INIT_EXIT:
	 REGREST <es,edi,esi,edx,ecx,ebx> ; Restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_INIT endp			; End PPM_INIT procedure
	 NPPROC  PPM_ALLOC -- Allocate a physical page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Allocate a physical page. The PhysicalPageRecords for
	 free pages are linked in a list headed by PhysicalFreeListHead.
On entry:
EAX	=	virtual address of page
		LSB of address has the following sense:
EDX	=	$canSwap


On exit:
EBX	=	physical address of allocated page
		if EBX == -1 on exit, no page could be allocated
|
	REGSAVE <eax, ecx, esi, es>	; save registers

	mov	ebx, PhysicalFreeListHead ; physical address of next free page
	cmp	ebx, -1 		; at end of list?
	jne	short PPM_ALLOC_GO	; do alloc if not at end of list

	mov	ecx, PhysicalTotal	; get total page count
	call	PPM_FILL_POOL		; get pages from base memory manager
	mov	ebx, PhysicalFreeListHead ; try again
	cmp	ebx, -1 		; end of list?
	je	PPM_ALLOC_EXIT		; give up if so

PPM_ALLOC_GO:				; ebx is physical address of free page
	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it
	call	PPM_GET_PAGE_RECORD	; esi <- page record linear address

	and	eax, not $clientMask	; insert current client into vaddr
	or	ax, VMMcurrentClient	; ...

	xchg	es:[esi].PPaddr, eax	; eax <- free link, PPaddr <- vaddr
	mov	PhysicalFreeListHead, eax  ; set location
	or	es:[esi].PPflags, mask $alloced ; this page is allocated

	test	edx, mask $canSwap	; test swappable argument
	jz	short @F		; jump if not swappable
	or	es:[esi].PPflags, mask $swappable ; page is swappable
	inc	PhysicalSwappable	; bump count of swappable pages
@@:
	mov	es:[esi].PPlocks, 0	; zero lock count
	mov	ax, VMMcurrentTime	; get current VMM time
	mov	es:[esi].PPusage, ax	; make the page new, timewise

	; If we have not started swapping yet, increment the timer so
	; that pages allocated before swapping starts are differentiated
	; by age.

	cmp	BSActive, 0		; have we started swapping?
	je	short @F		; jump if not
	add	VMMcurrentTime, 10h	; advance the clock
@@:
	inc	PhysicalInUse		; inc count of physical pages in use

	and	ebx, not $clientMask	; clear out low bits

PPM_ALLOC_EXIT:
	 REGREST <es, esi, ecx, eax>	 ; restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_ALLOC	ENDP		; end of PPM_ALLOC procedure
	NPPROC PPM_FREE -- Free a physical page
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Free a physical page.	To do this, update the PhysicalPageRecord
	 of the free page (clear flags), update system counts (locked,
	 swappable), and link the page into the free list.

On entry:
EBX	=	physical address of page to free
|
	REGSAVE <es, esi, eax, ebx>	; save registers

	mov	es, ISEL_4GB3		; es <- AGROUP
	 assume  es:AGROUP		; Tell the assembler about it

	call	PPM_GET_PAGE_RECORD	; esi <- page record linear address

	test	es:[esi].PPflags, mask $managed ; verify this is valid to free
	jnz	short @F		; jump if page managed
	int	3			; freeing an unmanaged page
@@:
	test	es:[esi].PPflags, mask $alloced ; is page allocated?
	jnz	short @F		; jump if so
	int	3			; freeing an unallocated page
@@:
	cmp	es:[esi].PPlocks, 0	; was page locked?
	jz	short @F		; jump if not
	dec	PhysicalLocked		; decrement locked total
@@:
	test	es:[esi].PPflags, mask $swappable ; was page swappable?
	jz	short @F		; jump if not
	dec	PhysicalSwappable	; decrement count of swappable pages
@@:
	and	es:[esi].PPflags, \
		       not (mask $alloced OR mask $swappable OR mask $marked)
	mov	eax, PhysicalFreeListHead ; get head
	mov	es:[esi].PPaddr, eax	; old head follows freed page

	and	ebx, not $clientMask	; clear out low bits
	mov	PhysicalFreeListHead, ebx ; set new head

	dec	PhysicalInUse		; dec count of phys pages in use

	REGREST <ebx, eax, esi, es>	; restore registers
	ret				; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_FREE	ENDP		; end of PPM_FREE procedure
	NPPROC PPM_QUERY -- Query number of free pages
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Determine the number of free pages

On exit:
EAX	=	Number of currently available physical pages. Fills the
		pool.
|
	REGSAVE <ecx>			; save register


	cmp	NeedToFillPool, 0	; has page pool been drained?
	je	short @F		; jump if not
	mov	ecx, PhysicalTotal	; get total physical page count
	call	PPM_FILL_POOL		; fill the pool from primary mgr
@@:
	mov	eax, PhysicalManaged	; eax <- count of managed pages
	sub	eax, PhysicalInUse	; eax <- available pages

	REGREST <ecx>			; restore registers
	ret				; return to caller
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_QUERY	ENDP		; end of PPM_QUERY procedure
	NPPROC PPM_QUERY_SWAPPABLE -- Query number of swappable pages
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Get the number of swappable pages

On exit:
EAX	=	number of currently in-use but swappable pages
|
	; swappable = min(PhysicalSwappable, BSFree)

	mov	eax, BSTotal		; eax <- total number of BS pages
	sub	eax, BSInUse		; eax <- available BS pages
	cmp	eax, PhysicalSwappable	; compare to physical swappable
	jb	short @F		; jump if fewer BS pages than swappable
	mov	eax, PhysicalSwappable	; max is swappable count
@@:
	ret				; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_QUERY_SWAPPABLE	ENDP		; end of PPM_QUERY_SWAPPABLE procedure
	FPPROC PPM_DRAIN_POOL -- Move pages to primary (XMS/EMS) manager
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Release free pages in page pool to primary allocator

On entry:
ECX	=	number of pages to release

On exit:
ECX	=	number of pages actually released

|
	cmp	PrimaryAllocInProg, 0	; if not doing a primary allocate
	je	short @F		; proceed with normal processing
	xor	ecx, ecx		; zero pages moved
	ret				; else never mind
@@:
	REGSAVE <eax, ebx, edx, esi, es>	; save registers

; We might be called before any memory has been allocated.  If so,
; skip out early

	 cmp	 PhysicalManaged,0	; Izit available?
	 je	 near ptr PPM_DRAIN_ZERO; Jump if none

; We have to careful about how many pages we release, because some may
; in fact be committed. The reservation mechanism used for virtual memory
; allocation assumes that it can get virtual storage on demand, up to
; certain limits.  Some of this virtual storage may be in backing store,
; so the calculation of how much physical memory to free depends on how
; much backing store is available, how much virtual memory has been
; reserved (committed but not assigned to either physical memory or backing
; store) and, finally, on how much free physical memory there is.
;
; The logic is:
;
;	if (VirtualReserved > BackFree) i.e. if backing store doesn't cover
;						amount reserved
;	{
;		canDrain = PhysicalFree - (VirtualReserved - BackFree);
;		willDrain = min(request, canDrain);
;	}
;
; Even if no virtual memory is reserved, there are still constraints. We
; cannot drain more than is currently free, nor can we let the number of
; unlocked pages fall below the minimum threshold. The logic continues:
;
;	willDrain = min(willDrain, PhysicalManaged-PhysicalInUse);
;	willDrain = min(willDrain, PhysicalManaged-PhysicalLocked-
;							PhysicalMinUnlocked);

	 and	 VMM_FLAG,not @VMM_MUSTDRAIN ; Mark as no longer needed
PPM_DRAIN_BEGIN:
	mov	esi, ecx		; save request size
	mov	eax, BSTotal		; compute BackFree=BSTotal-BSInUse
	sub	eax, BSInUse		; eax <- available bs pages

	cmp	VirtualReserved, eax	; see if physical pages are needed
	jb	short PPM_DRAIN_CHECK_FREE; jump if there are enough bs pages

	add	eax, PhysicalManaged
	sub	eax, PhysicalInUse	; eax=PhysicalFree+BackFree

	sub	eax, VirtualReserved	; compute PhysicalFree+BackFree-VirtualReserved
	jbe	PPM_DRAIN_ZERO		; jump if can't drain

	cmp	eax, ecx		; if this quantity less than requested
	jae	short @F		;  amount to drain, then set new
	mov	ecx, eax		;  request to this quantity
@@:

PPM_DRAIN_CHECK_FREE:			; check request against free pages
	mov	eax, PhysicalManaged	; compute eax = PhysManaged-PhysInUse
	sub	eax, PhysicalInUse
	cmp	eax, ecx		; do min() operation
	jae	short @F
	mov	ecx, eax		; ecx <- min(requested,free)
@@:					; now check againt lock constraints
	mov	eax, PhysicalManaged	; eax <- managed count
	sub	eax, PhysicalLocked	; eax <- managed - locked
	sub	eax, PhysicalMinUnlocked; eax <- managed - locked - min unlock
	 jc	 short PPM_DRAIN_SWAP	; Jump if not enough pages

	cmp	eax, ecx		; do min operation
	jae	short @F
	mov	ecx, eax		; ...
@@:					; ecx now holds amount that can be
					;   safely drained
	or	ecx,ecx 		; can we drain any?
	jnz	PPM_DRAIN_CAN		; jump if so
PPM_DRAIN_SWAP:

;; If all the pages are in use, try swapping some out

	cmp	PhysicalSwappable,0	; are any pages swappable
	je	PPM_DRAIN_ZERO		; jump if not

	mov	ecx,BSTotal		; calc bs free
	sub	ecx,BSInUse		; ecx <- bs pages free
	cmp	ecx,PhysicalSwappable	; get min(swappable, bsfree)
	jb	short @F		; jump if below
	mov	ecx,PhysicalSwappable	; swappable is min
@@:
	cmp	ecx,PhysicalMinUnlocked ; leave some pages for swapping in
	jb	PPM_DRAIN_ZERO		; need at least PhysicalMinUnlocked
	sub	ecx,PhysicalMinUnlocked ; ecx <- new how many to swap out

	cmp	esi,ecx 		; only need to swap as many as req'ed
	ja	short @F		; jump if requested more

	mov	ecx,esi 		; swap out number requested
@@:
	or	ecx,ecx 		; are there any pages?
	jz	PPM_DRAIN_ZERO		; jump if not

PPM_DRAIN_PAGEOUT:
	call	VMM_SWAP_OUT		; free a page
	loopd	PPM_DRAIN_PAGEOUT

	mov	ecx, esi		; restore request size
	jmp	PPM_DRAIN_BEGIN 	; try again

PPM_DRAIN_CAN:
	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it
	xor	edx, edx		; use edx as counter
	mov	NeedToFillPool, 1	; flag that we will need a refill

PPM_DRAIN_NEXT:
	cmp	edx, ecx		; are we there yet?
	je	short PPM_DRAIN_EXIT	; jump if so

	mov	ebx, PhysicalFreeListHead ; get first page in free list
	cmp	ebx, -1 		; is free list empty?
	jne	short @F		; jump if not
	int	3			; unexpected end of list
@@:
	call	PPM_GET_PAGE_RECORD	; get the record for this page
	test	es:[esi].PPflags, mask $swappable ; is it swappable?
	jz	short @F		; jump if not
	dec	PhysicalSwappable	; dec count of swappable pages
@@:
	and	es:[esi].PPflags, not mask $managed ; un-manage the page
	mov	eax, es:[esi].PPaddr	; get free link
	mov	PhysicalFreeListHead, eax ; set new free head

	push	ds			; save it
	mov	ds,ISEL_DS3		; Get PGROUP data selector at PL3
	assume	ds:PGROUP		; Tell the assembler about it

	 push	 dword ptr @PageSize	 ; pass size to deallocate
	 push	 es:[esi].PPlowAddr	 ; eax <- linear address to free
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; release to primary manager

	 pop	 ds		; Restore
	 assume  ds:IGROUP	; Tell the assembler about it

	 dec	 PhysicalManaged ; Dec count of managed phys pages
	 call	 PPM_SETPHYSMU	; Set PhysicalMinUnlocked
	 inc	 edx		; Inc count of pages released

	 jmp	 PPM_DRAIN_NEXT ; Go for more

PPM_DRAIN_EXIT:
	 REGREST <es,esi,edx,ebx,eax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

PPM_DRAIN_ZERO:
	 xor	 ecx,ecx	; Didn't drain any pages

	 jmp	 PPM_DRAIN_EXIT ; Exit

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_DRAIN_POOL endp		; End PPM_DRAIN_POOL procedure
	 NPPROC  PPM_FILL_POOL -- Move pages from primary manager to VMM pool
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Allocate pages from primary allocator; insert into VMM managed pool

On entry:

ECX	=	number of pages to add to pool

On exit:

ECX	=	number of pages added to pool

|

	REGSAVE <eax, ebx, edx, esi, edi, ds, es> ; save registers

	 or	 VMM_FLAG,@VMM_MUSTDRAIN ; Mark as needing draining
				; if VCPI app does VM to PM switch
PPM_FILL_POOL_GO:
	push	ecx			; save the request size

	mov	ds,ISEL_DS3		; Get PGROUP data selector at PL3
	assume	ds:PGROUP		; Tell the assembler about it

	mov	PrimaryAllocInProg, 1	; signal for drain pool

	push	@ALLOC_VCPI		; Pass allocation type
	FIXICALL PGROUP:FQRY_PGCNT,DTE_CS2 ; eax <- available mem in KB
	shr	eax, 12-10		; convert to pages
	mov	edi, eax		; edi <- pages available

	cmp	eax, ecx		; get min of request, available
	ja	short @F
	mov	ecx, eax		; ecx <- min(available, requested)
@@:
; Now allocate that memory from the primary manager

	shl	ecx, @BytePage		; convert size to bytes

PPM_FILL_GETMEM:
	or	ecx, ecx		; is request non-zero?
	jz	PPM_FILL_POOL_FAIL	; jump if so

	push	@ALLOC_VCPI
	push	ecx
	FIXICALL PGROUP:FALLOCMEM,DTE_CS2; returns linear addr in ebx
	jnc	short @F		; jump ahead if succeeded

	shr	ecx, 1			; if failed, try for half as much
	and	ecx, not (@PageSize-1)	; round down to page
	jmp	PPM_FILL_GETMEM
@@:
	mov	eax, ebx		; eax <- linear address of block

	mov	es, ISEL_4GB3		; set up es with AGROUP
	assume	es:AGROUP		; Tell the assembler about it

	mov	ds, SEL_DSIG3		; set up ds with IGROUP
	assume	ds:IGROUP		; Tell the assembler about it

	shr	ecx, @BytePage		; convert size to pages
	push	ecx			; remember how many pages we got
	sub	edi,ecx 		; edi <- available - allocated
	jecxz	short PPM_FILL_POOL_DONE

; Walk over the allocated block and process each page.

PPM_FILL_POOL_NEXT:
	 mov	 ebx, eax		 ; ebx <- current linear address
	 MakePTEaddress ebx		 ; ebx <- address of PTE for cur LA

	 mov	 ebx, AGROUP:[ebx]	 ; ebx <- PTE
	 and	 ebx, @PTE_FRM		 ; mask off low bits to get phys addr
	 call	 PPM_GET_PAGE_RECORD	 ; esi <- page record pointer (AGROUP)
	 mov	 AGROUP:[esi].PPlowAddr, eax ; remember low address
	 mov	 AGROUP:[esi].PPflags, mask $managed
	 mov	 edx, PhysicalFreeListHead ; link this page into the chain
	 mov	 AGROUP:[esi].PPaddr, edx
	 mov	 PhysicalFreeListHead, ebx ;
	 inc	 PhysicalManaged
	 call	 PPM_SETPHYSMU	; Set PhysicalMinUnlocked
	 add	 eax, @PageSize 	 ; advance linear address

	 loopd	 PPM_FILL_POOL_NEXT	 ; get next
PPM_FILL_POOL_DONE:
	 pop	 ecx			 ; recall page count added

	 pop	 eax			 ; recall request size

	 cmp	 eax, ecx		 ; did we satisfy the request
	 je	 short @F		 ; jump if yes

	 or	 edi, edi		 ; is there more available?
	 jz	 short @F		 ; jump if not

	 sub	 eax, ecx		 ; calc how much more is needed
	 mov	 ecx, eax		 ; load as arg

	 jmp	 PPM_FILL_POOL_GO	 ; go back for more

@@:
	 mov	 NeedToFillPool, 0	 ; flag that pool has been filled
PPM_FILL_POOL_EXIT:
	 mov	 PrimaryAllocInProg, 0	 ; signal for drain pool

	 REGREST <es, ds, edi, esi, edx, ebx, eax> ; restore regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret				 ; return to caller

PPM_FILL_POOL_FAIL:
	 pop	 ecx			 ; discard request size
	 xor	 ecx, ecx		 ; no pages moved

	 jmp	 PPM_FILL_POOL_EXIT	 ; exit

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_FILL_POOL	ENDP		; end of PPM_FILL_POOL procedure
	NPPROC PPM_LOCK -- lock physical pages
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Lock a physical page

On entry:
EBX	=	physical address of page to lock

On exit:
AL	=	new lock count
|
	REGSAVE <es, esi>			; save registers

	mov	es, ISEL_4GB3
	 assume  es:AGROUP			; Tell the assembler about it
	call	PPM_GET_PAGE_RECORD		; get the page record

	cmp	es:[esi].PPlocks, 0ffh		; if already at max, quit
	je	short PPM_LOCK_EXIT		; jump if at max lock count

	cmp	es:[esi].PPlocks, 0		; is lock count zero?
	jne	short @F			; jump if not
	inc	PhysicalLocked			; it is a new locked page
@@:
	inc	es:[esi].PPlocks		; increment lock count for page
	test	es:[esi].PPflags, mask $swappable ; was it swappable before?
	jz	short @F			; jump if not
	dec	PhysicalSwappable		; else dec count of swappables
@@:
	and	es:[esi].PPflags, not mask $swappable ; the whole point

PPM_LOCK_EXIT:
	 mov	 al, es:[esi].PPlocks		 ; return new lock count

	 REGREST <esi, es>			 ; restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_LOCK endp			; End PPM_LOCK procedure
	NPPROC PPM_UNLOCK -- Unlock physical page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Unlock a physical page

On entry:
EBX	=	physical address of page to unlock

On exit:
AL	=	new lock count
|
	REGSAVE <esi, es>			; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it
	call	PPM_GET_PAGE_RECORD		; get the page record

	cmp	es:[esi].PPlocks, 0		; if lock count already zero
	je	short PPM_PAGE_UNLOCK_EXIT	;	quit

	dec	es:[esi].PPlocks		; if new count is not zero
	jnz	short PPM_PAGE_UNLOCK_EXIT	;	done
						; else
	or	es:[esi].PPflags, mask $swappable ; page is now swappable
	inc	PhysicalSwappable		; inc swappable count
	dec	PhysicalLocked			; dec locked count

PPM_PAGE_UNLOCK_EXIT:
	 mov	 al, es:[esi].PPlocks		 ; return new lock count

	 REGREST <es, esi>			 ; restore regiseters
	 assume  es:nothing	; Tell the assembler about it

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_UNLOCK	ENDP		; end of PPM_UNLOCK procedure
	NPPROC PPM_SET_PAGE_OWNER -- Set owner of physical page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Set the owner (client) of a physical page

On entry:
EBX	=	physical address of page
AX	=	client id
|
	REGSAVE <esi, es>			; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it
	call	PPM_GET_PAGE_RECORD		; get the page record

	and	ax, $clientMask 		; just the low bits thanks
	and	word ptr es:[esi].PPaddr, not $clientMask ; clear old owner
	or	word ptr es:[esi].PPaddr, ax	; set new owner

	REGREST <es,esi>			; restore regs
	ret					; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_SET_PAGE_OWNER	ENDP		; end of PPM_SET_PAGE_OWNER procedure
	NPPROC PPM_SET_PAGE_ADDRESS -- Set mapped linear address of page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Set the virtual address of a physical page

On entry:
EBX	=	physical address of page
EAX	=	virtual address of page
|
	REGSAVE <esi, es>			; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it
	call	PPM_GET_PAGE_RECORD		; get the page record

	and	eax, not $clientMask		; just the high bits
	and	es:[esi].PPaddr, $clientMask	; clear out old address
	or	es:[esi].PPaddr, eax		; set new address

	REGREST <es,esi>			; restore registers
	ret					; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_SET_PAGE_ADDRESS	ENDP		; end of PPM_SET_PAGE_ADDRESS procedure
	 NPPROC PPM_AGE_PAGES -- Age the pages
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Age the pages

The "age" of page is based on the value in the PPusage field of the
physical page record.  The high 12 bits of this word are the timestamp,
and the low four bits are the "history".

The history bits work as follows: Bit i is set if the page was referenced 4-i
intervals ago.	For example, if the page was referenced in the interval
immediately prior to the interval specified in the timestamp, then bit
3 (=4-1) is set.

The job of this routine is to (1) bump the timestamp, and (2) update the
PPusage words on all pages. NOTE: only pages that belong to the current
client are updated.
|
	REGSAVE <eax, ebx, ecx, edx, esi, edi, ds, es> ; save registers

	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it

	mov	ds,ISEL_DSIG3		; Get IGROUP data selector at PL3
	assume	ds:IGROUP		; Tell the assembler about it

	add	VMMcurrentTime, 10h	; advance the "clock"

	movzx	cx, nRegions		; pick up region count
	mov	di, offset IGROUP:RegionTable ; point to region table

PPM_AGE_NEXT_REGION:

	mov	edx, [di].PRsize	; use edx as page counter for region
	mov	esi, [di].PRtable	; point to page records for region
	push	cx			; save
	push	di			; ...

	mov	di, VMMcurrentClient	; pick up current client id
	mov	cx, VMMcurrentTime	; pick up current time

PPM_AGE_NEXT_PAGE:
	or	edx, edx		; done with this region?
	jz	short PPM_AGE_LOOP_REGION ; jump if yes

	mov	al, es:[esi].PPflags	; qualify page state
	and	al, mask $managed OR mask $alloced OR mask $swappable
	cmp	al, mask $managed OR mask $alloced OR mask $swappable
	jne	short PPM_AGE_ADVANCE	; jump if not age-able

	mov	ax, word ptr es:[esi].PPaddr	; qualify client
	and	ax, $clientMask 	; isolate client id
	cmp	ax, $clientMask 	; if shared page
	je	PPM_AGE_CHECK_REFER	;   further processing
	cmp	ax, di			; if not current client
	jne	short PPM_AGE_ADVANCE	;   skip

PPM_AGE_CHECK_REFER:
	mov	eax, es:[esi].PPaddr	; get virtual address
	and	eax, not $clientMask	; strip client info
	MakePTEaddress eax		; eax <- address of PTE for page
	btr	byte ptr es:[eax], @AccessBitOrd ; was it touched? (+clear it)
	jnc	PPM_AGE_ADVANCE 	; jump if not

	; if we get here, the page must be updated

	mov	bx, es:[esi].PPusage	; get current usage word
	and	bx, 0fff0h		; mask off history
	mov	ax, cx			; ax <- current time
	sub	ax, bx			; subtract page time
	shr	ax, 4			; ax <- number of interval since last
					;    referenced
	xchg	ax, cx			; cx <- delta , ax <- current time
	cmp	cx, 4			; was reference within history range?
	ja	short PPM_AGE_HISTZERO	; jump if not

	mov	bx, es:[esi].PPusage	; get history bits
	and	bx, 0fh 		; isolate history bits
	or	bl, 10h 		; set bit for this quantum
	shr	bx, cl			; shift by delta since last ref'ed
	or	bx, ax			; new PPusage value with history
	mov	es:[esi].PPusage, bx	; set new usage/history
	jmp	short PPM_AGE_DONE	; continue processing

PPM_AGE_HISTZERO:
	mov	es:[esi].PPusage, ax	; set usage to current time

PPM_AGE_DONE:
	mov	cx, ax			; cx <- current time

PPM_AGE_ADVANCE:
	dec	edx			; dec count of pages in region
	add	esi, size PhysicalPageRecord ; advance to next page
	jmp	PPM_AGE_NEXT_PAGE	; go do next page


PPM_AGE_LOOP_REGION:
	pop	di			; restore
	pop	cx			; ...
	add	di, size PhysicalRegion ; advance to next region
	dec	cx			; dec count of regions left to go
	jnz	PPM_AGE_NEXT_REGION	; continue if more

	REGREST <es, ds, edi, esi, edx, ecx, ebx, eax> ;restore registers
	ret				; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
PPM_AGE_PAGES	ENDP		; end of PPM_AGE_PAGES procedure
	 NPPROC  PPM_GET_LOWADDR -- Get page's address in non-VMM space
	 assume  ds:IGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get low address of page, which is stored in the page's PhysicalPageRecord

On entry:

EDX	 =	 physical address of page
ES	 =	 all memory selector

On exit:

EDX	 =	 low address of page

|

	 REGSAVE <ebx,esi>	; Save registers

	 mov	 ebx,edx	; Copy page address
	 call	 PPM_GET_PAGE_RECORD ; Look it up

	 mov	 edx,AGROUP:[esi].PPlowAddr ; Pull out the lowaddr

	 REGREST <esi,ebx>	; restore registers

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_GET_LOWADDR endp		; End PPM_GET_LOWADDR procedure
	 NPPROC  PPM_SHUTDOWN -- Shutdown the physical page manager
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Shut down the Physical Page Manager

|

	 pushad 			 ; save all regs
	 REGSAVE <ds,es,fs>		 ; save seg regs

	 mov	 fs,ISEL_DSIG3		 ; fs <- IGROUP
	 assume  fs:IGROUP		 ; tell assembler

	 mov	 ds,ISEL_DS3		 ; Get PGROUP data selector at PL3
	 assume  ds:PGROUP		 ; Tell the assembler about it

; Instead of freeing pages one at time, which is very slow, we try
; to find contiguous linear pages in the PPRs, and free them in a
; block.  The outer loop finds a managed page.	The inner loops
; scan forward to find contiguous linear pages.  When a non-contiguous
; page is found, we call DEALLOCMEM and the non-contiguous page
; becomes the start of the next block.

	 mov	 esi, PPRBaseAddress	 ; esi <- start addr of PPRs

	 mov	 es,ISEL_4GB3		 ; es <- AGROUP
	 assume  es:AGROUP

	 mov	 edx, esi		 ; edx <- ppr base address
	 add	 edx, TotalPPRSize	 ; edx <- end of PPRs
PPM_SHUT_LOOP1:
	 cmp	 PhysicalManaged, 0	 ; have all pages been released?
	 je	 near ptr PPM_SHUT_FREE_PPRS ; jump if yes
@@:
	 cmp	 esi, edx		 ; are we at the end of the PPRs
	 je	 near ptr PPM_SHUT_FREE_PPRS ; jump if yes

	 test	 es:[esi].PPflags, mask $managed ; is this page managed?
	 jnz	 short @F		 ; jump if yes

	 add	 esi, size PhysicalPageRecord ; else advance pointer

	jmp	short @B		; and continue

@@:
	 xor	 ecx, ecx		 ; init byte count to free
	 mov	 edi, esi		 ; esi will address next mng'd page
PPM_SHUT_LOOP2:
	 add	 edi, size PhysicalPageRecord ; point to next PPR
	 add	 ecx, @PageSize 	 ; increment byte count to free
PPM_SHUT_FINDNEXT:
	 cmp	 edi, edx		 ; are we at the end?
	 je	 short PPM_SHUT_DEALLOCBLOCK ; jump if yes

	 test	 es:[edi].PPflags, mask $managed ; is this page managed?
	 jnz	 short @F		 ; jump if yes

	 add	 edi, size PhysicalPageRecord ; else advance

	 jmp	 short PPM_SHUT_FINDNEXT

@@:					; here we have the next mng'd page
	 mov	 eax, es:[esi].PPlowAddr ; get linear address of start page
	 add	 eax, ecx		 ; add size delta

	 cmp	 eax, es:[edi].PPlowAddr ; are the pages contigous?
	 je	 short PPM_SHUT_LOOP2	 ; if yes look for more
PPM_SHUT_DEALLOCBLOCK:			; now deallocate what we've accumulated
	 push	 ecx			 ; byte size to free
	 push	 es:[esi].PPlowAddr	 ; start address to free
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2	 ; free it

	 shr	 ecx, @BytePage 	 ; convert size to page
	 sub	 PhysicalManaged, ecx	 ; decrement managed count

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 PPM_SETPHYSMU	; Set PhysicalMinUnlocked

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 esi, edi		 ; advance PPR pointer

	 jmp	 PPM_SHUT_LOOP1

PPM_SHUT_FREE_PPRS:
	 push	 TotalPPRSize	; Size to free (/4KB)
	 push	 PPRBaseAddress ; Address to free
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Free it
	 jnc	 short @F	; Should be ok

	 int	 03h		; What happened?
@@:
	 and	 VMM_FLAG,not @VMM_MUSTDRAIN ; Mark as no longer needed

	 REGREST <fs,es,ds>	; Restore seg registers
	 popad			; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPM_SHUTDOWN ENDP		; End PPM_SHUTDOWN procedure
	 align	 4

ICODE	 ends			; End ICODE segment

endif
	 MEND			; End QMAX_PPM.ASM
