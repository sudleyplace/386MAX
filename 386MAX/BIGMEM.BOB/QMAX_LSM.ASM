;' $Header:   P:/PVCS/MAX/386MAX/QMAX_LSM.ASV   1.2   30 May 1997 10:45:30   BOB  $
	title	QMAX_LSM -- DPMI Linear Space Manager functions
	page	58,122
	name	QMAX_LSM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-2003 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
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
	include PTR.INC
	include MASM5.MAC
	include ALLMEM.INC

	include QMAX_OEM.INC
	include QMAX_DTE.INC
	include QMAX_TSS.INC
	include QMAX_VMM.INC
.list
if @OEM_VIRTUALMEM

FlushTLB macro	reg		; Macro to Flush the TLB
	mov	reg,LCL_CR3	; Get current CR3 value
	mov	CR3,reg 	; Stuff it back in

	endm			; FlushTLB

PGROUP	group	CODE,EDATA
IGROUP	group	LDATA,ICODE,IDATA


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	ds:PGROUP

	extrn	LCL_CR3:dword

CODE	ends			; End CODE segment


EDATA	segment use16 dword public 'edata' ; Start EDATA segment
	assume	ds:PGROUP

	extrn	PCURTSS:dword
	extrn	PVMTSS:dword
	extrn	SEL_DS3:dword
	extrn	PDTLEN:dword

EDATA	ends			; End EDATA segment


LDATA	segment use16 dword public 'icode' ; Start LDATA segment
	assume	ds:IGROUP

	extrn	ISEL_DS3:word	 ; PGROUP selector
	extrn	ISEL_4GB3:word	; AGROUP ...

LDATA	ends			; End LDATA segment


IDATA	segment use16 dword public 'idata' ; Start IDATA segment
	assume	ds:IGROUP

	extrn	PageDirLA:DWORD 	 ; low linear address of page dir

	public LinearBottom, LinearClientBottom
	public LinearClientTop, LinearSystemBreak, DefaultPDE

SharedFreeList		FreeList <0,0,0,0>

LinearBottom		dd	?	; bottom of shared area
LinearClientBottom	dd	?	; start of client linear space
LinearClientTop 	dd	?	; top of client area
LinearSystemBreak	dd	?	; start of system area
DefaultPDE		dd	?	; default page directory entry
LSM_AllocFlags		dd	?	; flags for LSM_ALLOC call

IDATA	ends			; End IDATA segment


ICODE	segment use16 dword public 'icode' ; Start ICODE segment
	assume	cs:IGROUP

	extrn	VMM_GET_PHYSICAL_PAGE:near
	extrn	VMM_ZERO_PAGE:near
	extrn	PPM_FREE:near
	extrn	PPM_QUERY:near
	extrn	PPM_QUERY_SWAPPABLE:near
	extrn	PPM_GET_LOWADDR:near
	extrn	PPM_SET_PAGE_OWNER:near

	public	@QMAX_LSM_ICODE
@QMAX_LSM_ICODE:

	NPPROC	LSM_INIT -- Initialize the Linear Space Manager
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT!

Initialize the linear space manager

This routine sets up important boundaries in the linear space.	The
memory layout is as follows:


      ------------------------- 4GB
      | 		      |
      |  Page tables	      |
      | 		      |
      ------------------------- 4GB-4MB @PTBase
      |  Scratch page	      |
      | 		      |
      |  Backing Store Map    |
      | 		      |
      ------------------------- 4GB-8MB
      | 		      |
      |  Shared List Nodes    |
      | 		      |
      ------------------------- 4GB-12MB LinearSystemBreak
      | 		      |
      |  Client List Nodes    |
      | 		      |
      ------------------------- 4GB-16MB LinearClientTop
      | 		      |
      | 		      |
      |  DPMI Client Area     |
      | 		      |
      | 		      |
      ------------------------- LinearClientBottom
      | 		      |
      |  Shared Area	      |
      | 		      |
      ------------------------- LinearBottom
      | 		      |
      |  386MAX area	      |
      | 		      |
      ------------------------- 0


The LinearBottom is determined by taking the PDT length (with suitable
conversion of units) and rounding up to the next 4MB boundary.	The
size of the shared area is determined by the assembly time constant,
@SharedSize (this could be made configurable).

On exit:

CF	=	0 if all went OK
	=	1 otherwise
AX	=	error code

!

	REGSAVE <esi,edi,es,fs> ; Save registers

; First compute the LinearBottom

	mov	eax,PDTLEN	; Get the length of the PDT in bytes
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	add	eax,@FourMeg-1	; Round up to 4MB
	and	eax,not (@FourMeg-1) ; Finish round up
	mov	LinearBottom,eax ; Set location

	add	eax,@SharedSize ; Define shared area
	mov	LinearClientBottom,eax ; Set location

; Set up high memory area

	mov	LinearSystemBreak,@PTBase - (2*@FourMeg) ; Set location
	mov	LinearClientTop,@PTBase - (3*@FourMeg) ; ...

; Set up the shared free list

	mov	eax,LinearSystemBreak ; Addr for shared nodes
	mov	SharedFreeList.FreeNodes,eax ; Set location
	mov	SharedFreeList.FreeHighNode,eax ; ...

	mov	es,ISEL_4GB3	; Get AGROUP data selector at PL3
	assume	es:AGROUP	; Tell the assembler about it

	call	LSM_GET_SHARED_LIST ; Returns list in FS:EDI
	assume	fs:nothing	; Tell the assembler about it

	call	LSM_ALLOC_FREE_NODE ; ESI <- free node address
	mov	ax,@DERR_INSUFF_LINEAR ; In case we fail
	jc	short LSM_INIT_EXIT ; Jump if it failed (note CF=1)

	mov	eax,LinearBottom ; Address of initial node
				; is base of shared area
	mov	es:[esi].LFNaddr,eax ; Set base of initial node

; Set size of initial node in KB

	mov	es:[esi].LFNsize,@SharedSize shr @BytePage ; Set size in KB
	mov	SharedFreeList.FreeHead,esi ; Set head of shared list

	clc			; Flag success
LSM_INIT_EXIT:
	REGREST <fs,es,edi,esi> ; Restore registers
	assume	es:nothing,fs:nothing ; Tell the assembler about it

	ret			; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_INIT endp			; End LSM_INIT procedure
	NPPROC	LSM_INIT_CLIENT -- Initialize LSM for current client
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Because each DPMI client has its own linear address space, each
needs its own page directory.  The primary task of this function
is to allocate and initialize a new page directory. This involves
allocating a page, then copying the common areas of the address
space (low memory, system tables) from the current page directory
to the new one.  Then we have to create a free list for the client's
linear space, consisting of a single block the size of the client
area. Finally, this routine switches to the new page directory.

On exit:

CF	=	0 ==> success
		 1 ==> failed
AX	=	error code
CR3	=	(if success) physical addr of client's page directory

|

	REGSAVE <ebx,ecx,edx,esi,edi,es,fs> ; Save registers

	mov	es,ISEL_4GB3	; Get AGROUP data selector at PL3
	assume	es:AGROUP	; Tell the assembler about it

	mov	edi, PCURTSS	; edi <- offset in PGROUP of current TSS

; Allocate a page directory for the client

	xor	eax,eax 	; Never mind virtual address
	xor	ebx,ebx 	; Not swappable, can fail
	call	VMM_GET_PHYSICAL_PAGE ; EBX <- page address

	cmp	ebx, -1 	; Did we get a page?
	mov	ax,@DERR_INSUFF_PHYS ; In case we fail
	je	LSM_INIT_CLIENT_FAIL ; Jump if not

	mov	PGROUP:[edi].TSS_CR3,ebx ; Save page address
	mov	edx,ebx 	; Pass arg in edx
	call	PPM_GET_LOWADDR ; EDX <- low address of PD

; Set up the new directory

	xchg	edi,edx 	; EDI <- PD addr, EDX <- current TSS
	cld			; Forward

; First copy PDEs from zero to LinearClientBottom

	xor	esi,esi 	; Make a zero
	MakePDEaddress esi	; ESI <- PDE addr for lin addr 0
	mov	ecx,LinearClientBottom ; Get base of client region
	shr	ecx,20+2	; Divide by 4MB to get number of PDEs
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy PDEs

; Zero out the client region

	mov	ecx,LinearSystemBreak ; ECX <- top of client region
	sub	ecx,LinearClientBottom ; ECX <- size of client region
	shr	ecx,20+2	; Convert to PDE count for region
	xor	eax,eax 	; Make zero
    rep stos	AGROUP:[edi].EDD ; Zap it

; Copy the remainder

	mov	ecx,LinearSystemBreak ; ECX <- top of system region
	mov	esi,ecx 	; ESI <- top of system region
	MakePDEaddress esi	; ESI <- PDE addr for sys region
	neg	ecx		; Subtract from 4GB
	shr	ecx,20+2	; Convert to PDE count
	dec	ecx		; Save one for PD entry itself
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD>  ; copy PDEs

	mov	eax,PGROUP:[edx].TSS_CR3 ; Pick up current PD addr (phys)
	or	eax,@PTE_URP	; Make it present r/w
	mov	AGROUP:[edi],eax ; Put self reference of page directory

	mov	eax,PGROUP:[edx].TSS_CR3 ; Switch to new page directory
	mov	edi,PageDirLA	; EDI <- linear address of PD
	MakePTEaddress edi	; EDI <- PTE addr for PD

	mov	fs,ISEL_DS3	; Get PGROUP data selector at PL3
	assume	fs:PGROUP	; Tell the assembler about it

	mov	LCL_CR3,eax	; Set CR3 global for this client
	mov	cr3,eax 	; Set CR3 - flushes TLB
	or	eax,@PGBITS_PRESENT or @PG_READWRITE ; make PTE
	mov	AGROUP:[edi],eax ; Stick it in

; Set up the free list

	lea	edi,PGROUP:[edx].DPTSS_VMM_FreeList ; EDI <- client free list structure
	mov	eax,LinearClientTop ; Get address for node area
	mov	PGROUP:[edi].FreeNodes,eax ; Set base of client node area
	mov	PGROUP:[edi].FreeHighNode,eax ; Initially, top is base

	call	LSM_ALLOC_FREE_NODE ; ESI <- free node address
	mov	ax,@DERR_INSUFF_LINEAR ; In case we fail
	jc	short LSM_INIT_CLIENT_FAIL ; jump if failed

; Set the free node to span the entire client area

	mov	PGROUP:[edi].FreeHead,esi ; Set head to point at first node

	mov	eax,LinearClientBottom ; Get base of client area
	mov	AGROUP:[esi].LFNaddr,eax ; Set node address to base
	mov	eax,LinearClientTop  ; Get top of client area
	sub	eax,LinearClientBottom ; Compute size of client area
	shr	eax,@BytePage ; Convert to pages
	mov	AGROUP:[esi].LFNsize,eax ; Store in free node
	mov	AGROUP:[esi].LFNnext,0 ; Just one node now - no next node

	clc			; Flag success
LSM_INIT_CLIENT_EXIT:
	REGREST <fs,es,edi,esi,edx,ecx,ebx> ; Restore registers
	assume	es:nothing,fs:nothing ; Tell the assembler about it

	ret			; Return to client

LSM_INIT_CLIENT_FAIL:
	stc			; Flag error

	jmp	LSM_INIT_CLIENT_EXIT ; Exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_INIT_CLIENT endp		; End LSM_INIT_CLIENT procedure
	FPPROC FLSM_ALLOC	; far version of LSM_ALLOC
	  call LSM_ALLOC	; perform the call (all args in regs)
	  ret			; return to caller
	FLSM_ALLOC endp 	; end of FLSM_ALLOC
	NPPROC LSM_ALLOC -- Allocate linear space
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Allocate linear space

	There are two basic cases: the client either has or has not
	requested the allocation at a specific address.  If a specific
	address is not requested, we simply scan the free list looking
	for the best fit. This requires a complete scan of the list, but
	since we cannot compact the linear space, a best fit strategy is
	indicated.  In the case where a specific address is requested,
	we walk the free list looking for the block (if any) where the
	requested address resides.  This breaks down into four subcases
	that are described in more detail below.

	Once the block is allocated from the free list, it is then
	necessary to make sure that there are valid page table addresses
	in the page directory for the corresponding addresses.	On a
	successful allocation, the caller may assume that the page tables
	are present, but the PTEs are uninitialized.

On entry:
EAX	=	requested linear address of block to allocate, or zero if any
		address is acceptable
EBX	=	size of block in pages
EDX	=	flags: $shared, $commit (ALLOC_FLAGS record)

On exit:
EAX	=	address of block, = zero indicates failure to allocate
CF	=	0 on success, 1 on fail

|
	REGSAVE <ebp, ebx, ecx, edx, esi, edi, es, fs> ; save regs

	mov	LSM_AllocFlags,edx ; Save flags

	mov	es,ISEL_4GB3	; Get AGROUP data selector at PL3
	assume	es:AGROUP	; Tell the assembler about it

; Choose a free list based on shared flag

	test	edx,mask $shared ; Is this a shared alloc?
	jz	short LSM_ALLOC_NOTSHARED ; Jump if not

	call	LSM_GET_SHARED_LIST ; Returns list in FS:EDI
	assume	fs:nothing	; Tell the assembler about it

	jmp	short LSM_ALLOC_GO ; Continue processing with shared list

LSM_ALLOC_NOTSHARED:
	call	LSM_GET_CLIENT_LIST ; Returns list in FS:EDI
	assume	fs:nothing	; Tell the assembler about it
LSM_ALLOC_GO:			; FS:EDI points to free list object
	test	fs:[edi].FreeFlags,mask $needToMerge ; Need to merge?
	jz	short @F	; Jump if not

	call	LSM_MERGE_FREE_LIST ; Merge the list

	and	fs:[edi].FreeFlags,not mask $needToMerge ; mark merge not needed
@@:
	or	eax,eax 		 ; test requested address for zero
	jnz	LSM_ALLOC_SPECIFIC	; jump if specific address requested

	; Walk the nodes in the free list, looking for the best fit.
	; Whenever a new best block is found, record the size delta and
	; the node address.

	; ebx is requested size in pages

	mov	ecx, -1 		; ecx is best delta
	mov	edx, 0			; esi is address of best node
	mov	esi, fs:[edi].FreeHead	; esi is current node
	mov	ebp, 0			; ebp is previous node

LSM_ALLOC_NEXTNODE:
	or	esi,esi 		; if at end of list
	jz	LSM_ALLOC_ANYDONE	;	go see what happened

	mov	eax,es:[esi].LFNsize	; get size of block for this node
	sub	eax,ebx 		; subtract requested size
	jz	short LSM_ALLOC_EXACTFIT
	jc	short LSM_ALLOC_ADVANCE ; too small, skip this node

; Block is big enough - check this delta against best delta

	cmp	eax, ecx		; if bigger or equal
	jae	short LSM_ALLOC_ADVANCE ;	 ignore it
					; else
	mov	ecx, eax		;	set new best delta
	mov	edx, esi		;	set new best node

	jmp	short LSM_ALLOC_ADVANCE ;	 and go onto next node

LSM_ALLOC_EXACTFIT:
	mov	eax,es:[esi].LFNnext	; link prev to next to unlink this

; On exact fit, unlink this node from the free list

	or	ebp, ebp		 ; test previous node
	jz	short LSM_ALLOC_SETHEAD_NEXT ; if none, go fix list head

	mov	es:[ebp].LFNnext, eax	 ; set link

	jmp	short LSM_ALLOC_EXACT_DONE ; continue processing

LSM_ALLOC_SETHEAD_NEXT:
	mov	fs:[edi].FreeHead, eax	; set new free head
LSM_ALLOC_EXACT_DONE:
	mov	eax, es:[esi].LFNaddr	 ; address of allocated block
	and	es:[esi].LFNflags, not mask $nodeInUse ; node not active

	jmp	LSM_ALLOC_SETUP_PDES	 ; go set up the PDEs now

LSM_ALLOC_ADVANCE:
	mov	ebp, esi		 ; ebp <- previous node
	mov	esi, es:[esi].LFNnext	 ; esi <- pointer to next node

	jmp	LSM_ALLOC_NEXTNODE	 ; examine next node

LSM_ALLOC_ANYDONE:

; Here after a complete scan of the list (exact fit not found)

	or	edx, edx		; edx zero means no block big enough
	jz	LSM_ALLOC_FAIL		; go die

	mov	eax, es:[edx].LFNaddr	; eax <- address to return
	shl	ebx, @BytePage		; shrink block from which allocation
	add	es:[edx].LFNaddr, ebx	;	was made
	shr	ebx, @BytePage		; convert to pages
	sub	es:[edx].LFNsize, ebx	; reduce free node size by alloc amt
	jmp	LSM_ALLOC_SETUP_PDES	; now go fix page tables

LSM_ALLOC_SPECIFIC:
	; Here if the caller has requested that the linear block be allocated
	; at a particular linear address. There are four cases:
	;
	; I.	exact fit in free block
	; II.	requested block at bottom of free block
	; III.	requested block at top of free block
	; IV.	requested block contained by free block


	mov	esi, fs:[edi].FreeHead	; esi is current node
	mov	ebp, 0			; ebp is previous node
LSM_ALLOC_SPECIFIC_NEXT:
	or	esi, esi		; if at end of list
	jz	LSM_ALLOC_FAIL		;	failed

	cmp	es:[esi].LFNaddr, eax	; try for exact match or at bottom
	ja	LSM_ALLOC_FAIL		; fail if block starts above requested
	jb	LSM_ALLOC_CONTAINED	; jump if block starts below requested
					; here if block starts at requested
	cmp	es:[esi].LFNsize, ebx	; see if this block is big enough
	jb	LSM_ALLOC_FAIL		; if below, no go
	je	LSM_ALLOC_EXACTFIT	; if equal, we have case I
					; otherwise, we have case II
	shl	ebx, @BytePage		; adjust block size to take it out
	add	es:[esi].LFNaddr, ebx	; advance base of free node
	shr	ebx, @BytePage		; convert size to pages
	sub	es:[esi].LFNsize, ebx	; reduce size of free node
	jmp	LSM_ALLOC_SETUP_PDES	; go set up page tables

LSM_ALLOC_CONTAINED:
	mov	ecx, ebx		; copy page count
	shl	ecx, @BytePage		; convert to bytes
	add	ecx, eax		; ecx <- address of end of req block

	mov	edx, es:[esi].LFNsize	; get size of free node
	shl	edx, @BytePage		; convert to bytes
	add	edx, es:[esi].LFNaddr	; edx <- address of end of block

	cmp	eax, edx		; if req block starts beyond this blk
	jae	LSM_ALLOC_SPEC_ADVANCE	;	then go on to next block

	cmp	ecx, edx		; if end of req > end of block
	ja	LSM_ALLOC_FAIL		;	block not big enough
	jb	short LSM_ALLOC_SPLIT	; below, go split block

	sub	es:[esi].LFNsize, ebx	; shrink block, case III.
	jmp	LSM_ALLOC_SETUP_PDES	; go set up page tables

LSM_ALLOC_SPLIT:
	mov	ebp, eax		; ebp <- requestesd address
	sub	ebp, es:[esi].LFNaddr	; subtract start of free block
	shr	ebp, @BytePage		; convert to page to get
	mov	es:[esi].LFNsize, ebp	;	new size of block
	mov	ebp, esi		; remember block in ebp

	call	LSM_ALLOC_FREE_NODE	; esi <- new free node
	jnc	short @F		; jump if alloc'ed ok
	int	3			; no free nodes left!
	jmp	LSM_ALLOC_SETUP_PDES	; go set up page tables
@@:
	mov	es:[esi].LFNaddr, ecx	; address of new node = end of req blk
	sub	edx, ecx		; size of new node = end of block -
	shr	edx, @BytePage		;	end of request
	mov	es:[esi].LFNsize, edx	; set size of new node
	mov	edx, es:[ebp].LFNnext	; link in the new block
	mov	es:[ebp].LFNnext, esi	; set link
	mov	es:[esi].LFNnext, edx	; set link
	jmp	LSM_ALLOC_SETUP_PDES	; go set up page tables

LSM_ALLOC_SPEC_ADVANCE:
	mov	ebp, esi		; prev <- this
	mov	esi, es:[esi].LFNnext	; this <- next
	jmp	LSM_ALLOC_SPECIFIC_NEXT ; examine next

LSM_ALLOC_SETUP_PDES:
; eax is linear address of block
; ebx is size in pages
	push	ebx			; save size

	shl	ebx, @BytePage		; ebx <- size in bytes
	add	ebx, eax		; ebx <- 1st addr past alloc'ed area
	dec	ebx			; ebx <-end address of alloc'ed area
	mov	ecx, eax		; ecx <-linear address of alloc'ed blk

	MakePDEaddress ecx		; ecx <- address of first PDE in blk
	MakePDEaddress ebx		; ebx <- address of last PDE in blk

	test	LSM_AllocFlags, mask $commit ; if allocating committed space
	jnz	short LSM_ALLOC_SETUP_COMMITTED ; jump if committed

; Here if allocating uncommitted memory. Any PDEs that are zero or
; DefaultPDE are set to @PGBITS_UNCOMMITTED. All others are left unchanged.
; No additional physical memory is required for page tables.

LSM_ALLOC_SETUP_UNCOMMITTED:
	cmp	ecx, ebx		; are we done?
	ja	short LSM_ALLOC_UNCOMMITTED_DONE	; jump if so

	cmp	dword ptr es:[ecx], 0	; if PDE is zero
	je	short @F		; go set it to uncommitted

	mov	edx, DefaultPDE 	; edx <- default PDE entry
	xor	edx, es:[ecx]		; check against PDE
	and	edx, @PTE_FRM		; only care about frame address
	jnz	short LSM_ALLOC_UNCOMMITTED_ADVANCE ; jump if not DefaultPDE
@@:
	push	ecx			; page directory address
	push	dword ptr @PGBITS_UNCOMMITTED	; page directory entry
	call	LSM_SET_PDE		; set new PDE value

LSM_ALLOC_UNCOMMITTED_ADVANCE:
	add	ecx, 4			; look at next PDE
	jmp	LSM_ALLOC_SETUP_UNCOMMITTED ; continue processing

LSM_ALLOC_UNCOMMITTED_DONE:
	pop	ebx			; discard size
	clc				; signal success
	jmp	near ptr LSM_ALLOC_EXIT ; leave


LSM_ALLOC_SETUP_COMMITTED:
; If allocating committed memory, we have to make two loops. In the first,
; we count how many new page tables are going to be needed to cover the
; newly allocated linear region.  This count is compared against
; the number of physical pages available. If less, the allocation
; fails. Otherwise, we go through the loop again, and allocate
; the page tables.

	xor	edx, edx		; edx will count how many new PTs
					;	are needed
	push	eax			; save it
	and	eax, 0ffc00000h 	; round blk addr down to 4MB boundary

LSM_ALLOC_PDE_LOOP:
	cmp	ecx, ebx		; are we there yet?
	ja	short LSM_ALLOC_PDES_DONE
					; if current entry is uncommitted,
					;   we will need a new page table
	cmp	dword ptr es:[ecx], @PGBITS_UNCOMMITTED ; uncommitted?
	je	short @F		; jump if UNcommitted
					; here for committed
	push	eax			; save
	mov	eax, DefaultPDE 	; get default PDE
	xor	eax, dword ptr es:[ecx] ; different from current entry?
	and	eax, @PTE_FRM		; (mask off arb bits)
	pop	eax			; restore
	jz	short @F		; jump if different from DefaultPDE

	cmp	dword ptr es:[ecx], 0	; if PDE is zero
	jne	short LSM_ALLOC_PDE_ADVANCE ; jump if not zero
@@:
	inc	edx			; not zero,not default - need another

LSM_ALLOC_PDE_ADVANCE:
	add	ecx, 4			; look at next PDE
	add	eax, @FourMeg		; advance linear address
	jmp	LSM_ALLOC_PDE_LOOP	; do next

LSM_ALLOC_PDES_DONE:			; edx is count of how many PTs needed
	call	PPM_QUERY		; eax <- free physical count
	mov	ecx, eax		; hold count in ecx
	call	PPM_QUERY_SWAPPABLE	; eax <- in-use swappable phys pages
	add	eax, ecx		; eax <- avail + swappable
	cmp	eax, edx		; enough?
	pop	eax			; restore
	jae	short LSM_ALLOC_ENOUGH_PTS ; jump if enough

	; here if we don't have enough pages for the page tables

	pop	ebx			; recall size
	xor	ecx, ecx		; don't touch PTs
	call	LSM_FREE		; release the linear block
	jmp	short LSM_ALLOC_FAIL	; and give up

LSM_ALLOC_ENOUGH_PTS:
	pop	ecx			; discard saved size
	mov	ecx, eax		; copy addr of new block to ecx
	MakePDEaddress ecx		; ecx <- addr of PDE for new block
	push	eax			; save
	and	eax, 0ffc00000h 	; round down to 4MB bound

; We have determined how many new page tables (PDEs) are needed, and
; we know we have enough pages available. Now go through the address
; range again, this time actually allocating the page tables as needed.

LSM_ALLOC_PDE2_LOOP:			; ebx is addr of last PDE in block
	cmp	ecx, ebx		; are we done?
	ja	short LSM_ALLOC_PDE2_DONE; jump if so

	cmp	dword ptr es:[ecx], @PGBITS_UNCOMMITTED ; if !uncommitted PDE
	jne	short @F		; then skip
	call	LSM_EXPAND_UNCOMPDE	; else get new page table
	jmp	short LSM_ALLOC_PDE2_DECCOUNT
@@:
	push	eax			 ; compare current PDE against default
	mov	eax, DefaultPDE 	 ; get default
	xor	eax, dword ptr es:[ecx] ; cmp
	and	eax, @PTE_FRM		 ; clear low bits
	pop	eax			 ; restore
	jz	short @F		 ; if curr PDE is default then jump

	cmp	dword ptr es:[ecx], 0	 ; compare current PDE to zero
	jne	short LSM_ALLOC_PDE2_ADVANCE	; jump if not zero
@@:
	call	LSM_NEW_PAGE_TABLE	 ; get new page table
LSM_ALLOC_PDE2_DECCOUNT:
	dec	edx			 ; dec count of new PDEs needed
	jz	LSM_ALLOC_PDE2_DONE	 ; early out if all done
LSM_ALLOC_PDE2_ADVANCE:
	add	ecx, 4			 ; advance PDE pointer
	add	eax, @FourMeg		 ; advance linear address

	jmp	LSM_ALLOC_PDE2_LOOP	 ; process next 4MB region

LSM_ALLOC_PDE2_DONE:
	pop	eax			 ; restore addr of block

	clc				 ; flag success
LSM_ALLOC_EXIT:
	REGREST <fs, es, edi, esi, edx, ecx, ebx, ebp> ; restore regs
	assume	es:nothing,fs:nothing ; Tell the assembler about it

	ret				; return to caller

LSM_ALLOC_FAIL:
	xor	eax, eax		 ; signal failure

	stc				 ; flag error

	jmp	LSM_ALLOC_EXIT		 ; bye

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_ALLOC	ENDP		; end of LSM_ALLOC procedure
	NPPROC	LSM_FREE -- Free Linear Space
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Free a linear block. We insert the block being freed into the
	 list to maintain the list in order of increasing linear address.

	 The caller may request that the page tables behind the linear
	 space be freed as well (this is the normal case).

On entry:
EAX	=	linear address to free
EBX	=	size of region to free in pages
ECX	=	0 ==> do not update/free page tables
		1 ==> update/free page tables
|
	REGSAVE <eax, ebx, ecx, edx, esi, edi, es, fs>

	push	ecx				; save "free PT" switch

	mov	es, ISEL_4GB3			; all memory selector
	assume	es:AGROUP			; Tell the assembler about it

	cmp	eax, LinearClientBottom 	; is addr in client region?
	jb	short LSM_FREE_SHARED		; jump if not

	call	LSM_GET_CLIENT_LIST ; Returns list in FS:EDI
	assume	fs:nothing	; Tell the assembler about it

	jmp	short LSM_FREE_GO ; Continue

LSM_FREE_SHARED:
	call	LSM_GET_SHARED_LIST ; Returns list in FS:EDI
	assume	fs:nothing	; Tell the assembler about it
LSM_FREE_GO:
	mov	esi,fs:[edi].FreeHead		; esi is current block
	xor	edx,edx 			; edx is "previous" block
LSM_FREE_NEXTBLOCK:
	or	esi, esi			 ; at end of list?
	jz	short LSM_FREE_INSERT		 ; jump if so

	cmp	es:[esi].LFNaddr,eax ; Check this address
	jne	short @F	; Jump if addr ok

	int	3		; Sanity check - don't free
@@:				;	something already free
	ja	short LSM_FREE_INSERT ; If this block above freed
				;   block, insert after prev
LSM_FREE_ADVANCE:				; loop to next block
	mov	edx,esi 	; This becomes prev
	mov	esi,es:[esi].LFNnext ; ...link to next

	jmp	LSM_FREE_NEXTBLOCK ; Go get next

LSM_FREE_INSERT:

; EDX is "prev" or zero, ESI is "current" or zero

	mov	ecx,esi 	; ECX <- current
	call	LSM_ALLOC_FREE_NODE ; ESI <- new free node
	jnc	short @F	; Jump if node ok

	int	3		; No free nodes left!
@@:

; Set up new free node

	mov	es:[esi].LFNaddr,eax ; Base is freed block
	mov	es:[esi].LFNsize,ebx ; Size is freed size
	mov	es:[esi].LFNnext,ecx ; Link to next
	or	es:[esi].LFNflags,mask $nodeInUse ; Mark in use

	or	edx,edx 	; If no prev node,
	jz	short LSM_FREE_SETHEAD ; ...update next ptr of head

	mov	es:[edx].LFNnext,esi ; else

	jmp	short LSM_FREE_CLEAR_PDES ; ...knit it in here

LSM_FREE_SETHEAD:
	mov	fs:[edi].FreeHead, esi		; set new free head


LSM_FREE_CLEAR_PDES:
	or	fs:[edi].FreeFlags, mask $needToMerge ; signal merge needed
	pop	ecx				; recall "free PT" switch

	or	ecx, ecx			; non-zero?
	jz	short LSM_FREE_EXIT		      ; jump if not freeing PTs

	mov	ecx, @PGBITS_UNALLOC		; value to set PTEs to
	call	LSM_SETN_PTES			; set PTEs to unalloc'ed
LSM_FREE_EXIT:
	REGREST <fs, es, edi, esi, edx, ecx, ebx, eax> ; restore regs
	assume	es:nothing,fs:nothing ; Tell the assembler about it

	ret					 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_FREE	ENDP		; end of LSM_FREE procedure
	NPPROC LSM_QUERY -- Query largest available linear block
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get size of largest available linear block.  This routine just walks
the free list passed to it and determines the size of the largest
block.

On entry:

FS:EDI	==>	pointer to free list structure

On exit:

ECX	=	size of largest available linear block, in pages

|

	REGSAVE <esi, es>

	mov	es, ISEL_4GB3		 ; all memory selector
	assume	es:AGROUP		 ; Tell the assembler about it

	xor	ecx, ecx		 ; init max size to zero
	mov	esi, fs:[edi].FreeHead	; esi is current block
LSM_QUERY_NEXT:
	or	esi, esi		 ; end of list?
	jz	short LSM_QUERY_EXIT	 ; jump if yes

	cmp	es:[esi].LFNsize, ecx	 ; is block bigger than current max?
	jbe	short LSM_QUERY_ADVANCE ; jump if not

	mov	ecx, es:[esi].LFNsize	 ; set new max
LSM_QUERY_ADVANCE:
	mov	esi, es:[esi].LFNnext	 ; link to next

	jmp	LSM_QUERY_NEXT		 ; look at next block

LSM_QUERY_EXIT:
	REGREST <es, esi>		 ; restore regs
	assume	es:nothing	; Tell the assembler about it

	ret				 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
LSM_QUERY	ENDP		; end of LSM_QUERY procedure
	NPPROC	LSM_ALLOC_FREE_NODE -- Allocate a node from the free list
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get an unused node in the LFN array.

On entry:

FS:EDI	==>	pointer to free list structure

On exit:

ESI	=	linear address of free node
CF	=	0 ==> success
		 1 ==> failure

|

	REGSAVE <es>

	mov	es, ISEL_4GB3			; all memory selector
	assume	es:AGROUP			; Tell the assembler about it

; We just walk the node array linearly, looking for a node
; with an in-use bit set to zero

	mov	esi, fs:[edi].FreeNodes 	; esi is current node
LSM_ALLOC_NODE_NEXT:
	cmp	esi, fs:[edi].FreeHighNode	; if at addr of highest node
	jae	short LSM_ALLOC_NODE_GROW	;    that's the end - grow it

	test	es:[esi].LFNflags, mask $nodeInUse ; node in use?
	jz	short LSM_ALLOC_NODE_FOUND	; jump if so

	add	esi, size LinearFreeNode	; advance to next node
	jmp	LSM_ALLOC_NODE_NEXT		; continue

LSM_ALLOC_NODE_GROW:				; here if no node found
	call	LSM_GROW_FREE_NODE_ARRAY	; try to grow the node array
	jc	short LSM_ALLOC_NODE_FAIL	; jump if couldn't grow it

	jmp	short LSM_ALLOC_NODE_NEXT	; continue search

LSM_ALLOC_NODE_FOUND:
	or	es:[esi].LFNflags, mask $nodeInUse	; mark node in use
	clc					; flag success

LSM_ALLOC_NODE_EXIT:
	REGREST <es>				 ; restore regs
	assume	es:nothing	; Tell the assembler about it

	ret					 ; return to caller

LSM_ALLOC_NODE_FAIL:
	stc					 ; flag error - no nodes

	jmp	LSM_ALLOC_NODE_EXIT		 ; exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_ALLOC_FREE_NODE	ENDP		; end of LSM_ALLOC_FREE_NODE procedure
	NPPROC LSM_GROW_FREE_NODE_ARRAY - Grow the free node array
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Grow the array of linear free nodes for a client (or shared list) by
adding a page to the LFN array

On entry:

FS:EDI	==>	pointer to free list structure

On exit:

CF	=	0 ==> success
		 1 ==> failure

|

	REGSAVE <eax, ebx>			 ; save regs

	xor	eax, eax			 ; addr unimportant
	xor	ebx, ebx			 ; flags: no swap, can fail

	call	VMM_GET_PHYSICAL_PAGE		 ; get a page

	cmp	ebx, -1 			 ; did we get one?
	je	short LSM_GROW_ARRAY_FAIL	 ; jump if not

	mov	eax, fs:[edi].FreeHighNode	 ; addr at which to map new page
	call	LSM_MAP_PAGE			 ; map it in
	call	VMM_ZERO_PAGE			 ; zero it out
	add	fs:[edi].FreeHighNode, @PageSize; set new high water mark

	clc					 ; success
LSM_GROW_ARRAY_EXIT:
	REGREST <ebx, eax>			 ; restore regs

	ret					 ; return to caller

LSM_GROW_ARRAY_FAIL:
	stc					 ; flag error

	jmp	LSM_GROW_ARRAY_EXIT		 ; exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
LSM_GROW_FREE_NODE_ARRAY	ENDP		; end of LSM_GROW_FREE_NODE_ARRAY procedure
	NPPROC LSM_NEW_PAGE_TABLE -- Allocate and intialize new page table
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Allocate a page table for a given linear address, and insert it
	 in the current page directory

On entry:
EAX	=	linear address

On exit:
CF	=	0 ==> success
		1 ==> failure
|
	REGSAVE <eax, ebx, edx, es>	; save regs

	mov	es, ISEL_4GB3		; all memory selector
	assume	es:AGROUP		; Tell the assembler about it
	mov	edx, eax		; edx <- linear address
	xor	eax, eax		; addr not important
	xor	ebx, ebx		; flags: no swap, can fail
	call	VMM_GET_PHYSICAL_PAGE	; get a page
	cmp	ebx, -1 		; did we get one?
	je	LSM_NEW_PT_FAIL 	; jump if not

; if the address is in the shared area, set the owner of the page table
; to "shared"

	cmp	eax,LinearClientBottom	; in shared region?
	jae	short @F		; jump if not

	push	ax			; save for a moment
	mov	ax,$clientMask		; client mask means "shared"
	call	PPM_SET_PAGE_OWNER	; set page owner
	pop	ax			; restore
@@:
	mov	eax, edx		; eax <- linear address
	MakePDEaddress edx		; eax <- addr of PDE
	or	ebx, @PGBITS_PRESENT or @PG_READWRITE ; make PDE
	push	edx			; page directory address
	push	ebx			; page directory entry
	call	LSM_SET_PDE		; set new PDE value

	and	eax, not (@FourMeg-1)	; round down to 4MB boundary
	MakePTEaddress eax		; prepare to zero page
	call	VMM_ZERO_PAGE		; zero the page table

	clc				; success

LSM_NEW_PT_EXIT:
	REGREST <es, edx, ebx, eax>	 ; restore regs
	assume	es:nothing	; Tell the assembler about it

	ret				 ; return to caller

LSM_NEW_PT_FAIL:
	stc				 ; flag error

	jmp	LSM_NEW_PT_EXIT 	 ; exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_NEW_PAGE_TABLE	ENDP		; end of LSM_NEW_PAGE_TABLE procedure
	NPPROC	LSM_MAP_PAGE -- Map a physical page at a given linear address
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Map a given physical page to a linear address.	This routine will
allocate a new page table if necessary.

On entry:

EAX	=	linear address
EBX	=	physical address

On exit:

CF	=	0 ==> success
		 1 ==> failure

|

	REGSAVE <eax, ebx, ecx, edx, es>; save registers

	mov	es, ISEL_4GB3		; all memory selector
	assume	es:AGROUP		; Tell the assembler about it

	and	eax, @PTE_FRM		; clear out non-address bits
	mov	ecx, eax		; copy addr to ecx
	MakePDEaddress ecx		; ecx <- addr of PDE for linear addr

; A new page table is necessary if (1) the PDE is the default PDE, or
; (2) the PDE is zero

	mov	edx, DefaultPDE 	; get default PDE
	xor	edx, dword ptr es:[ecx] ; if no PDE
	and	edx, @PTE_FRM		; clear out low bits
	jz	short  LSM_MAP_NEW_PT	; jump if same as default
	cmp	dword ptr es:[ecx], 0	; is it zero?
	jne	short @F		; jump if not

LSM_MAP_NEW_PT:
	call	LSM_NEW_PAGE_TABLE	; no PDE was there, so make a new one
	jc	short LSM_MAP_PAGE_EXIT ; bail on fail
@@:
	MakePTEaddress eax		; eax <- addr of PTE
	and	ebx, @PTE_FRM		; clear non-address bits
	or	ebx, @PGBITS_PRESENT or @PG_READWRITE ; set for normal PTE
	mov	es:[eax], ebx		; stick new PTE
	clc				; success

LSM_MAP_PAGE_EXIT:
	REGREST <es, edx, ecx, ebx, eax>; restore regs
	assume	es:nothing	; Tell the assembler about it

	ret				 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_MAP_PAGE	ENDP		; end of LSM_MAP_PAGE procedure
	NPPROC LSM_MERGE_FREE_LIST -- Merge the free list
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Merge adjacent blocks in the free list.

Whenever a linear block is freed, we set a flag in the free list
object to indicate it needs to be merged.  The merge operation is not
initiated until the next allocation, at which time the "need to merge"
flag is cleared.

On entry:

FS:EDI		=	pointer to free list structure

|
	REGSAVE <eax, ebx, esi, es>		; save regs

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it
	mov	esi, fs:[edi].FreeHead		; esi is current block
LSM_MERGE_NEXT:
	or	esi, esi			; if current zero, done
	jz	short LSM_MERGE_EXIT

	mov	ebx, es:[esi].LFNnext		; if next zero, done
	or	ebx, ebx			; is there a next?
	jz	short LSM_MERGE_EXIT		; jump if not
						; check for adjacent blocks
	mov	eax, es:[esi].LFNsize		; get size of this node
	shl	eax, @BytePage			; convert to bytes
	add	eax, es:[esi].LFNaddr		; eax <- end of current block
	cmp	eax, es:[ebx].LFNaddr		; compare to start of next
	jne	short LSM_MERGE_ADVANCE 	; if not adjacent, jump
						; here if adjacent blocks
	mov	eax, es:[ebx].LFNsize		; grow current by size of next
	add	es:[esi].LFNsize, eax		; set new size of node
	mov	eax, es:[ebx].LFNnext		; unlink next
	mov	es:[esi].LFNnext, eax		; set new link
	and	es:[ebx].LFNflags, not mask $nodeInUse ; free the node
	jmp	LSM_MERGE_NEXT			; go again on current node

LSM_MERGE_ADVANCE:
	mov	esi, es:[esi].LFNnext		; this <- next
	jmp	LSM_MERGE_NEXT			; continue processing

LSM_MERGE_EXIT:
	REGREST <es, esi, ebx, eax>		 ; restore regs
	assume	es:nothing	; Tell the assembler about it

	ret					 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_MERGE_FREE_LIST	ENDP		; end of LSM_MERGE_FREE_LIST procedure
	NPPROC	LSM_FILL_PT -- Fill Page Table entries
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Fill part or all of a page table with a constant value.  Assumes
corresponding PDE is present.

On entry:

EAX	=	linear address to start at
EBX	=	number of PTEs to set
ECX	=	value to set them to

|

	REGSAVE <eax,ecx,edi,es> ; Save registers

	mov	es,ISEL_4GB3	; Get AGROUP data selector at PL3
	assume	es:AGROUP	; Tell the assembler about it

	mov	edi,eax 	; Copy address
	MakePTEaddress edi	; EDI <- PTE address
	mov	eax,ecx 	; Value to set
	mov	ecx,ebx 	; ECX <- count
	cld			; Forward
    rep stos	AGROUP:[edi].EDD ; Set PTEs

	REGREST <es,edi,ecx,eax> ; Restore registers
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_FILL_PT endp		; End LSM_FILL_PT procedure
	FPPROC FLSM_SETN_PTES -- the far version of LSM_SETN_PTES
	  call LSM_SETN_PTES	; just call it
	  ret			; return to caller
FLSM_SETN_PTES endp	; end of FLSM_SETN_PTES
	NPPROC LSM_SETN_PTES
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Set contiguous PTEs.

; If all entries in a page table become uncommitted, this routine will
; free that page table and set the PDE to "uncommitted pde".  Furthermore,
; if one or more pages in a page table that was previously uncommitted
; becmome committed, this routine will allocate a new page table.

On entry:
eax		=	linear address to start at
ebx		=	number of PTEs to set
ecx		=	value to set them to

On exit:
CF		=	0 success
		=	1 failed
|
	REGSAVE <eax, ebx, ecx, edx, esi, edi, es> ; save registers
	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; tell assembler

	mov	edx, ebx		; edx <- page count
	shl	edx, @BytePage		; edx <- byte count
	add	edx, eax		; edx <- address past region
	dec	edx			; edx <- last address of region
	MakePDEaddress edx		; edx <- last PDE for region
	mov	esi, eax		; esi <- linear address of region
	MakePDEaddress esi		; esi <- first PDE for region
	sub	edx, esi		; edx <- PDE address delta
	shr	edx, 2			; edx <- count of PDEs for region - 1
	inc	edx			; edx <- count of PDEs for region

LSM_SETN_NEXT_PDE:
	or	edx, edx		; check PDEs left count
	jz	near ptr LSM_SETN_EXIT	; jmp if no more
	push	edx			; save PDE counter

	mov	edi, eax		; edi <- current region address
	MakePDEaddress edi		; edi <- PDE address for current addr

	mov	esi, ebx		; esi <- page count of region
	shl	esi, @BytePage		; esi <- byte count of region
	add	esi, eax		; esi <- addr past region
	mov	edx, eax		; edx <- current region address
	add	edx, @FourMeg		; start round up to next 4MB
	and	edx, not (@FourMeg-1)	; edx <- rounded up address
	cmp	esi, edx		; choose top addr for this PDE
	jb	short @F		; get the min to esi
	mov	esi, edx		; rounded up addr was smaller
@@:
	sub	esi, eax		; esi <- byte delta for this PDE
	shr	esi, @BytePage		; esi <- page count for this PDE
	cmp	esi, @PageSize/4	; if not setting the entire PT
	jne	short LSM_SETN_CHECK_EXPAND ; then jump

	cmp	ecx, @PGBITS_UNALLOC	; if setting to unallocated
	je	short LSM_SETN_CHECK_PDE; then jump

	cmp	ecx, @PGBITS_UNCOMMITTED; if not setting to uncommitted
	jne	short LSM_SETN_CHECK_EXPAND; then jump

LSM_SETN_CHECK_PDE:			; here if setting full page table to
					; either uncommitted or  unallocated
	test	byte ptr es:[edi], @PG_PRESENT ; if PDE is present
	jz	short @F		; jump if not present
	push	ebx
	mov	ebx, es:[edi]		; ebx <- PDE (physical page table)
	call	PPM_FREE		; free the page table
	pop	ebx			; ebx <- pages remaining count
@@:
	push	edi			; page directory address
	push	ecx			; page directory entry
	call	LSM_SET_PDE		; set new PDE value
	jmp	short LSM_SETN_ADVANCE_PDE ; continue

LSM_SETN_CHECK_EXPAND:
	cmp	dword ptr es:[edi], @PGBITS_UNCOMMITTED ; if current PDE
					;	isn't uncommitted
	jne	short @F		; skip
	cmp	ecx, @PGBITS_UNCOMMITTED; if new setting is uncommitted
	je	short LSM_SETN_ADVANCE_PDE ; skip
	call	LSM_EXPAND_UNCOMPDE	; else expand the page table
	jc	short LSM_SETN_FAIL	; jump if error
@@:
	xchg	esi, ebx		; pass count in ebx
	call	LSM_FILL_PT		; fill ptes
	xchg	ebx, esi		; restore regs

LSM_SETN_ADVANCE_PDE:
	sub	ebx, esi		; dec count of pages left
	pop	edx			; edx <- count of PDEs left
	dec	edx			; dec PDE count
	shl	esi, @BytePage		; esi <- byte count
	add	eax, esi		; eax <- addr of next region

	jmp	LSM_SETN_NEXT_PDE ; Process next

LSM_SETN_DONE:
	clc			; Success
LSM_SETN_EXIT:
	REGREST <es,edi,esi,edx,ecx,ebx,eax> ; Restore regs
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

LSM_SETN_FAIL:
	pop	edx		; Discard

	stc			; Flag error

	jmp	LSM_SETN_EXIT	; Exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_SETN_PTES endp		; End LSM_SETN_PTES procedure
	NPPROC LSM_GET_SHARED_LIST -- Return free list for shared memory
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get a pointer to the shared free list structure

On exit:

FS:EDI	==>	pointer to the shared free list structure

|

	push	ds		; Copy DS to FS
	pop	fs		; ...for return register
	assume	fs:IGROUP	; Tell the assembler about it

	lea	edi,SharedFreeList ; FS:EDI ==> list

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_GET_SHARED_LIST endp	; End LSM_GET_SHARED_LIST procedure
	NPPROC LSM_GET_CLIENT_LIST -- Get list for current client
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Get a pointer to the free list structure for the current client

On exit:
FS:EDI		=	pointer to free list structure for the current client
|
	mov	edi, PCURTSS
	lea	edi,PGROUP:[edi].DPTSS_VMM_FreeList ; point to free list struc

	mov	fs, SEL_DS3		; fs <- PGROUP
	assume	fs:PGROUP		; Tell the assembler about it

	ret				; return to caller
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
LSM_GET_CLIENT_LIST	ENDP		; end of LSM_GET_CLIENT_LIST procedure
	NPPROC LSM_RELEASE_NODE_ARRAY -- Free pages in node array
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| At client termination, release the pages backing the free list
	node array.
|
	REGSAVE <fs,esi,ebx,edi>	; save registers

	call	LSM_GET_CLIENT_LIST	; fs:edi <- the list
	assume	fs:nothing

	mov	esi, fs:[edi].FreeNodes ; esi <- addr of start of array
	mov	es, ISEL_4GB3		; set up AGROUP
	assume	es:AGROUP

LSM_RELEASE_LOOP:
	cmp	esi, fs:[edi].FreeHighNode	; are we done yet?
	je	LSM_RELEASE_EXIT		; jump if so

	mov	ebx, esi			; ebx <- array addr
	MakePTEaddress ebx			; ebx <- pte addr
	mov	ebx, AGROUP:[ebx]		; ebx <- page addr
	call	PPM_FREE			; free it

	add	esi, @PageSize			; advance to next page
	jmp	LSM_RELEASE_LOOP		; iterate

LSM_RELEASE_EXIT:
	REGREST <edi,ebx,esi,fs>		 ; restore regs
	assume	fs:nothing	; Tell the assembler about it

	ret					 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_RELEASE_NODE_ARRAY	ENDP		; end of LSM_RELEASE_NODE_ARRAY procedure
	NPPROC LSM_EXPAND_UNCOMPDE -- Expand PDE to uncommitted page table
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

For the given linear address in a 4MB uncommitted area, create the
page table and fill it with uncommitted PTEs.

On entry:
EAX	=	linear address mapped by PDE


On exit:
CF	=	1	failed
	=	0	successful
|
	REGSAVE <eax, ebx, ecx>

	call	LSM_NEW_PAGE_TABLE		; get a new page table
	jc	short LSM_EXPAND_EXIT		; quit if failed

	mov	ebx, @PageSize/4		; count of PTEs
	mov	ecx, @PGBITS_UNCOMMITTED	; value to set to
	and	eax, not (@FourMeg-1)		; start at bottom of PT
	call	LSM_FILL_PT			; fill page table
LSM_EXPAND_EXIT:
	REGREST <ecx, ebx, eax> 		 ; restore regs

	ret					 ; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_EXPAND_UNCOMPDE	ENDP		; end of LSM_EXPAND_UNCOMPDE procedure
	NPPROC	LSM_SET_PDE -- Set a PDE - maintaining system wide coherence
	assume	ds:IGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

On entry:

Set Page Directory Entry value. If the page directory entry is in the
shared region, set the value for all existing page directories.

On entry:

ES	=	AGROUP

|

LSM_SP_STR	struc

	db	(size PUSHAD_STR) dup (?) ; EGPs
		dw	?	; return address
LSP_value	dd	?	; new PDE value to set
LSP_addr	dd	?	; linear address of PDE

LSM_SP_STR	ends

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	edi, [ebp].LSP_addr	; get address
	mov	ebx, [ebp].LSP_value	; get value
	mov	AGROUP:[edi], ebx	; write PDE to directory
	FlushTLB eax			; make sure CPU knows about it

; Now decide if we need to update other PDs in the system

	mov	eax, LinearClientBottom ; get top of shared area
	MakePDEaddress eax		; get its PDE address

	cmp	eax, edi		; is given address in shared area?
	jbe	short LSM_SP_EXIT	; jump if not

; We have determined that the PDE is in the shared area. Now loop through
; and update all the other PDs in the system.

; Convert the absolute linear address to the address relative to the start
; of the page directory by subtracting the base address of the page
; page directory.  The result can then be used as an offset into each of the
; other active page directories.

	sub	edi, @PTBase + (@PTBase shr 10) ; make addr relative to base

	mov	eax,PVMTSS		; Get offset in PGROUP of the 1st TSS
	mov	cx, @TSS_MAX		; get count of TSSs in system

; As we cycle thru the TSSs, we'll have to map in the Page Directory for
; each. We'll map the page directories, one at a time, just below our
; page table area (a scratch linear address).

	mov    esi, @PTBase-@PageSize	; esi <- scratch LA for page dirs
	MakePTEaddress esi		; convert to addr of PTE for scr page
LSM_SP_NEXT_TSS:
	cmp	eax, PCURTSS		; Skip the current TSS
	je	short LSM_SP_ADVANCE	; jump if this is the current client

	mov	edx, PGROUP:[eax].TSS_CR3 ; get phys addr of page dir

	or	edx, @PGBITS_PRESENT+@PG_READWRITE ; make it into a PTE
	mov	AGROUP:[esi], edx	; map it into the scratch page
	FlushTLB edx			; make sure CPU knows about it
	mov	edx, @PTBase-@PageSize	; edx <- linear addr of page dir

	mov	AGROUP:[edx+edi], ebx	; set PDE value
LSM_SP_ADVANCE:
	add	eax, type DPTSS_STR	; advance to next TSS

	dec	cx			; dec count remaining
	jz	LSM_SP_EXIT		; jump if done

	cmp	PGROUP:[eax].TSS_LINK,-1; link is -1 if TSS not in use
	je	short LSM_SP_ADVANCE	; skip next if TSS not in use

	jmp	LSM_SP_NEXT_TSS 	; process next


LSM_SP_EXIT:
	popad			; Restore registers

	ret	8		; Return popping args

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LSM_SET_PDE	ENDP		; end of LSM_SET_PDE procedure
	align	4

ICODE	ends

endif
	MEND
