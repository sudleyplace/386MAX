;' $Header:   P:/PVCS/MAX/386MAX/QMAX_VME.ASV   1.3   08 Jul 1998 12:02:20   BOB  $
	 title	 QMAX_VME -- DPMI Virtual Memory Executive functions
	 page	 58,122
	 name	 QMAX_VME

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Data    segment JDATA, dword-aligned, public, class 'jcode'

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
	 include QMAX_I31.INC
.list

swatmsg MACRO string	;; debug only - macro for use with SWAT trace
	local lbl
ICODE	ends
IDATA	segment use16 dword public 'idata' ; Start IDATA segment
lbl	db	string
	db	10,0
IDATA	ends
ICODE	segment use16 dword public 'icode' ; Start ICODE segment
	push	ax
	push	bx
	push	esi
	mov	ax,0DEF6h
	mov	bl,6
	lea	esi,IGROUP:lbl
	int	67h
	pop	esi
	pop	bx
	pop	ax
	ENDM


if @OEM_VIRTUALMEM
addressOf MACRO _label_
	dw offset IGROUP:_label_
	ENDM

PGROUP	 group	 CODE,EDATA
IGROUP	 group	 LDATA,ICODE,IDATA
JGROUP	 group	 JDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 LCL_CR3:dword

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 DESC_TAB:qword
	 extrn	 SEL_DSIG3:word
	 extrn	 VM2PM_TSS:word
	 extrn	 PSHMEMHANDLES:dword
	 extrn	 SHMEMHANDLESIZE:dword
	 extrn	 I31_FLAG:word

	 public  VMM_FLAG
VMM_FLAG dw	 0		; VMM flags (see QMAX_VMM.INC for equates)

	 public  PageFaultActive
PageFaultActive db 0		; Non-zero during page fault processing

EDATA	 ends			; End EDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_4GB3:word ; AGROUP selector
	 extrn	 ISEL_DSIG3:word ; IGROUP ...

LDATA	 ends			; End LDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 PhysicalManaged:DWORD
	 extrn	 PhysicalInUse:DWORD
	 extrn	 BSTotal:DWORD
	 extrn	 BSInUse:DWORD
	 extrn	 BSActive:BYTE
	 extrn	 LinearClientBottom:DWORD
	 extrn	 PhysicalLocked:DWORD
	 extrn	 PhysicalMinUnlocked:DWORD
	 extrn	 PhysicalTotal:dword
	 extrn	 nRegions:BYTE
	 extrn	 RegionTable:BYTE
	 extrn	 LinearBottom:DWORD
	 extrn	 LinearClientTop:DWORD
	 extrn	 LinearSystemBreak:DWORD
	 extrn	 DefaultPDE:DWORD
	 extrn	 PhysicalSwappable:DWORD
	 extrn	 PPRBaseAddress:dword

	 public VMMcurrentClient, VMMcurrentTime, VirtualReserved, PageDirLA
	 public VMMclientCount

VirtualReserved 	dd	?	; count of pages committed,not touched
VMMcurrentClient	dw	?	; TSS selector of current client
VMMcurrentTime		dw	?	; current swap time
PageDirLA		dd	?	; low linear address of page directory
VMMclientCount		dw	?	; how many clients have we?

IDATA	 ends			; End IDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 FRSP_INIT:far

JCODE	 ends			; End JCODE segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn RSPhead:word

JDATA	 ends			; End JDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 PPM_INIT:near
	 extrn	 PPM_ALLOC:near
	 extrn	 PPM_FREE:near
	 extrn	 PPM_SET_PAGE_OWNER:near
	 extrn	 PPM_GET_LOWADDR:near
	 extrn	 PPM_LOCK:near
	 extrn	 PPM_UNLOCK:near
	 extrn	 PPM_GET_PAGE_RECORD:near
	 extrn	 PPM_SET_PAGE_ADDRESS:near
	 extrn	 PPM_SHUTDOWN:near
	 extrn	 LSM_INIT:near
	 extrn	 LSM_INIT_CLIENT:near
	 extrn	 LSM_ALLOC:near
	 extrn	 LSM_FREE:near
	 extrn	 LSM_SETN_PTES:near
	 extrn	 LSM_NEW_PAGE_TABLE:near
	 extrn	 LSM_EXPAND_UNCOMPDE:near
	 extrn	 BSM_INIT:near
	 extrn	 BSM_INIT_CLIENT:near
	 extrn	 BSM_FREE:near
	 extrn	 BSM_PUTPAGE:near
	 extrn	 BSM_GETPAGE:near
	 extrn	 BSM_INVALIDATE_CACHE_ENTRY:near
	 extrn	 BSM_TERMINATE_CLIENT:near
	 extrn	 BSM_SHUTDOWN:near
	 extrn	 PPM_FILL_POOL:near
	 extrn	 LSM_GET_CLIENT_LIST:near
	 extrn	 LSM_QUERY:near
	 extrn	 LSM_RELEASE_NODE_ARRAY:near
	 extrn	 DPMIFN_SWITCHADDR:near
	 extrn	 DPMIFN_FREELDT:near

FlushTLB	MACRO reg		; flush TLB by reloading CR3
	mov	reg, LCL_CR3
	mov	CR3, reg
	ENDM


SwitchOnPageType	MACRO	PTEaddress
	push	PTEaddress
	call	PAGE_SWITCH
	ENDM

	public	@QMAX_VME_ICODE
@QMAX_VME_ICODE:

	 NPPROC  PAGE_SWITCH -- Switch on page type
	 assume  ds:IGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Switch on page type. This routine is used extensively - changes which
slow it down may impact performance.

On entry:
ES		=	selector of all memory data descriptor
stack arg	=	dword linear address of PTE to switch on

On exit:

This routine replaces the return address with an entry from the table
at the return address, indexed by the PTE type.

|

PageSwitchFrame STRUC
	savedEBP	dd	?
	returnIP	dw	?
	PTEaddress	dd	?
PageSwitchFrame ENDS

CheckType	MACRO	pageType
	mov	dl, @PGTYPE_&pageType
	cmp	ax, @PGBITS_&pageType
	je	short PAGE_SWITCH_DISPATCH
ENDM

	push	ebp				; save baes pointer
	mov	ebp, esp			; address from stack

	REGSAVE <eax, ebx, edx> 		; save registers

	; first make sure the PDE is present

	mov	edx, @PGTYPE_PDE_UNCOMMITTED	; set up for PDE dispatch
	mov	ebx, [ebp].PTEaddress		; the PTE address of the PTE
	mov	eax, ebx			; edx <- copy of PTE addr
	MakePTEaddress ebx			;  address is the PDE address
	cmp	word ptr AGROUP:[ebx], @PGBITS_UNCOMMITTED; if PDE uncommitted
	je	short PAGE_SWITCH_DISPATCH	;  go dispatch it
	mov	dl, @PGTYPE_UNALLOC		; handle PDE not present
	test	byte ptr AGROUP:[ebx], @PG_PRESENT ; is PDE present?
	je	short PAGE_SWITCH_DISPATCH	;  go dispatch it if not

	mov	ax, AGROUP:[eax]		; ax <- low PTE
	and	ax, @PG_TYPEMASK		; ax <- PTE type

	xor	edx, edx			; default type

	; types ordered by likely frequency of occurrence

	CheckType PRESENT			; check present page
	CheckType RESERVED			; check reserved page
	CheckType SWAPPED			; check swapped page
	CheckType UNCOMMITTEDR			; check uncommitted page
	CheckType LOCKED			; check locked page
	CheckType INACC 			; check inaccessible page
	CheckType RESERVED_INACC		; check reserved-inacc page
	CheckType SWAPPED_INACC 		; check swapped-inacc page
	CheckType LOCKED_INACC			; check locked-inacc page
	CheckType MAPPED			; check mapped page
	CheckType SHARED			; check shared page
	CheckType RESERVED_SHARED		; check shared-reserved page
	CheckType SWAPPED_SHARED		; check shared-swapped page
	CheckType LOCKED_SHARED 		; check shared-locked page
	CheckType UNALLOC			; check unallocated page

PAGE_SWITCH_DISPATCH:
	movzx	ebx, [ebp].returnIP		; ebx <- dispatch table addr
	mov	ax, cs:[ebx + edx*2]		; ax <- dispatch addr in cs
	mov	[ebp].returnIP, ax		; plant addr in stack

	REGREST <edx, ebx, eax> 		; restore regs
	pop	ebp				; restore base ptr

	ret	4				; return to caller, pop arg

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAGE_SWITCH endp		; End PAGE_SWITCH procedure
	 FPPROC  FVMM_INIT -- Initailize DPMI Virtual Memory Manager
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	 push	 ds		; save for moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 VMM_INIT	; call the initialization routine

	 pop	 ds		; restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_INIT endp			; End FVMM_INIT procedure
	 NPPROC  VMM_INIT - Initialize the DPMI Virtual Memory Manager
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize the virtual memory manager

On exit:

CF	 =	 0 ==> success
	 =	 1 ==> failed
AX	 =	 error code

|

	 REGSAVE <ebx,dx,es>	; Save registers

	 xor	 dx,dx		; Initialize init flags to nothing init'ed
				; if we get an error, we'll know what to undo

	 test	 VMM_FLAG,@VMM_SYSINIT	; Already initialized?
	 jnz	 near ptr VMM_INIT_EXIT ; Jump if so (note CF=0)

	 mov	 VirtualReserved, 0	; init global var
	 mov	 VMMcurrentTime, 0	; ...
	 mov	 VMMclientCount, 0	; ...
	 mov	 VMMcurrentClient,0	; ...

; Here we write the address of the page directory to the last
; entry in the page directory, thereby providing addressability
; to all page tables (as well as the page directory itself) at a
; known linear address.  In addition, we extract from the page
; directory the default PDE used to catch stray linear references.
; This is needed to determine which PDEs have non-default values.

	 push	 DTE_CR3		; want es <- DTE_CR3
	 pop	 es			; es <- DTE_CR3
	 assume  es:nothing		; Tell the assembler about it

	 mov	 eax,LCL_CR3		; Pick up saved CR3 value
	 and	 eax,@PTE_FRM		; Throw away any low bits
	 or	 eax,@PGBITS_PRESENT or @PG_READWRITE ; Make PTE
	 xchg	 es:[@PageSize-4].PDT_PTE,eax ; Read default PDE, set new PDE
	 mov	 DefaultPDE,eax 	; Save default

; Now we need to determine the low linear address of the page
; directory so that we can maintain coherence with the rest of
; of the system when we change CR3.  We will update the PTE for
; this address with the new page directory address whenever we
; change the PTE.

	 mov	 es,ISEL_4GB3	; Get AGROUP data selecor at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ah,DESC_TAB.DTE_CR3.DESC_BASE3 ; Load base into EAX
	 mov	 al,DESC_TAB.DTE_CR3.DESC_BASE2 ; ...
	 shl	 eax,16 	; Shift it up
	 mov	 ax,DESC_TAB.DTE_CR3.DESC_BASE01; Load low-order word
	 mov	 PageDirLA,eax	; Save as LA of page dir

; Now initialize the VMM subsystems

	 mov	 PPRBaseAddress,-1 ; Mark as invalid in case of error

	 call	 PPM_INIT	; Physical page manager
	 jc	 short VMM_INIT_ERR ; Jump if not enough physical memory
				; error code in AX
	 or	 dx,PPMwasInited ; Flag PPM initialized

	 call	 LSM_INIT	; Linear space manager
	 jc	 short VMM_INIT_ERR ; Jump if not enough linear memory
	 or	 dx,LSMwasInited ; Flag LSM initialized

	 call	 BSM_INIT	; Backing store manager
	 jc	 short VMM_INIT_ERR ; Jump if not enough linear memory
				; error code in AX
	 or	 dx,BSMwasInited ; Flag BSM initialized

	 FIXICALL JGROUP:FRSP_INIT,DTE_CSJG ; init Resident Service Providers

	 mov	 PSHMEMHANDLES, 0  ; init LA of shared memory handles
	 mov	 SHMEMHANDLESIZE, 0; init size of shared memory handles

	 or	 VMM_FLAG,@VMM_SYSINIT ; Mark as initialized

	 clc			; Mark as successful

	 jmp	 short VMM_INIT_EXIT ; Join common exit code

; An error has occurred:  the error code is in AX

VMM_INIT_ERR:
	 test	 dx,BSMwasInited ; If we initialized the BSM
	 jz	 short @F	; Jump if not

	 call	 BSM_SHUTDOWN	;    then shut it down
@@:
	 test	 dx,PPMwasInited ; If we initialized the PPM
	 jz	 short @F	; Jump if not

	 call	 PPM_SHUTDOWN	;    then shut it down
@@:
	 stc			; Mark as in error
VMM_INIT_EXIT:
	 FlushTLB ebx		; Flush TLB after PTE/PDE modify

	 REGREST <es,dx,ebx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_INIT endp			; End VMM_INIT procedure
	 FPPROC  FVMM_INIT_CLIENT -- Init client of VMM - far entry point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 VMM_INIT_CLIENT ; Init client

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_INIT_CLIENT endp		; End FVMM_INIT_CLIENT procedure
	 NPPROC  VMM_INIT_CLIENT -- Init Client Of VMM
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize new client

On exit:

CF	 =	 0 ==> success
	 =	 1 ==> failed
AX	 =	 error code

|

	 REGSAVE <ebx,edx>	; Save registers

	 mov	 ax,VM2PM_TSS	; Get selector of incoming TSS
	 mov	 VMMCurrentClient,ax ; Save for later use

	 mov	 edx,PCURTSS	; Get the offset in PGROUP of the current TSS

	 call	 LSM_INIT_CLIENT ; Init linear space
	 jc	 short VMM_INIT_CLIENT_EXIT ; Jump if failed, AX=error code, CF=1

	 or	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_LSMINIT ; Mark as initialized

	 call	 BSM_INIT_CLIENT ; Init backing store
	 jc	 short VMM_INIT_CLIENT_EXIT ; Jump if failed, AX=error code, CF=1

	 or	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_BSMINIT ; Mark as initialized

	 inc	 VMMclientCount ; Bump client counter

	 clc			; Mark as successful
VMM_INIT_CLIENT_EXIT:
	 FlushTLB edx		; Flush TLB after PDE/PTE modify

	 REGREST <edx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_INIT_CLIENT endp		; End VMM_INIT_CLIENT procedure
	FPPROC	FVMM_ALLOC -- Allocate memory - far entry point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds		; save it

	mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	assume	ds:IGROUP	; Tell the assembler about it

	call	VMM_ALLOC	; call allocator

	pop	ds		; restore ds
	assume	ds:nothing	; Tell the assembler about it

	ret

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_ALLOC endp 	; end of FVMM_ALLOC procedure
	NPPROC	VMM_ALLOC -- Allocate virtual memory
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Allocate virtual memory.

On entry:

EAX	=	virtual address at which to allocate the memory, or zero if
		any address will do
EBX	=	size of requested allocation, in pages
ECX	=	bit flags: see alloc_flags in qmax_vmm.inc
			$commit = 1	allocate committed memory
				= 0	allocate uncommitted memory
			$shared = 1	allocated shared memory
				= 0	allocated client memory
On exit:
CF	=	0	success
	=	1	failed to allocate
EAX	=	if success, address of allocated block
		if failure, error code
|
	REGSAVE <ecx, edx>			; save register

	; do not allow shared uncommitted
	mov	edx, ecx			; get flags to scratch
	and	edx, mask $commit or mask $shared ; isolate flags
	cmp	edx, mask $shared		; shared must be committed
	je	VMM_ALLOC_BAD_REQUEST		; else error

	; if an address is requested, verify that the address
	; is in the proper region (shared or client)

	or	eax, eax			; is specific addr requested?
	jz	short VMM_ALLOC_LINEAR		; jump if not
	test	ecx, mask $shared		; is shared addr requested?
	jz	short VMM_ALLOC_VERIFY_CLIENT	; jump if not

	cmp	eax, LinearClientBottom 	; fail if shared request in
	jae	VMM_ALLOC_BAD_REQUEST		;	client region
	jmp	short VMM_ALLOC_LINEAR		; go do alloc

VMM_ALLOC_VERIFY_CLIENT:
	cmp	eax, LinearClientBottom 	; fail if client request in
	jb	VMM_ALLOC_BAD_REQUEST		;	shared region

VMM_ALLOC_LINEAR:
	mov	edx, ecx			; on call to LSM_ALLOC, pass
	and	edx, mask $shared or mask $commit;shared & commit flgs in edx
	call	LSM_ALLOC
	or	eax, eax			; eax is linear address
	jz	VMM_ALLOC_INSUFF_LINEAR 	; returns zero on fail

	test	ecx, mask $commit		; branch on commit/uncommit
	jnz	short VMM_ALLOC_COMMITTED	; jump if committed

	mov	ecx, @PGBITS_UNCOMMITTED	; set up PTEs and that's it
	call	LSM_SETN_PTES			; set PTEs to uncommitted
	clc					; flag success
	jmp	short VMM_ALLOC_EXIT		; we are done

VMM_ALLOC_COMMITTED:

; Now we have to determine if there is sufficient virtual memory
; to satisfy the request. The amount of free virtual memory is
;    PhysicalFree ( = PhysicalManaged - PhysicalInUse)
;   +BackFree	  ( = BSTotal - BSInUse)
;   -VirtualReserved

	 mov	 edx,PhysicalManaged ; Calculate PhysicalFree
	 sub	 edx,PhysicalInUse ; ...

	 add	 edx,BSTotal	; Plus BackFree
	 sub	 edx,BSInUse	; ...

	 sub	 edx,VirtualReserved ; Less reserved == available
	 jc	 short @F	; Jump if not enough

	 cmp	 edx,ebx	; Is there enough left?
	 jae	 short VMM_ALLOC_OK ; Jump if yes

; Not enough. Release the linear space.

@@:
	 mov	 ecx,1		; Flag: free PTs behind linear space
	 call	 LSM_FREE	; Free linear space

	 jmp	 short VMM_ALLOC_INSUFF_VIRTUAL  ; error exit

VMM_ALLOC_OK:
	add	VirtualReserved, ebx		; reserve the pages
	mov	edx, ecx			; copy the flags
	test	ecx, mask $shared		; were shared pages requested?
	jnz	VMM_ALLOC_SHARED_PTES		; jump if so
	mov	ecx, @PGBITS_RESERVED or @PG_READWRITE ; set type of PTE
	jmp	short VMM_ALLOC_SETPTES 	; go to set pte code

VMM_ALLOC_SHARED_PTES:
	mov	ecx, @PGBITS_RESERVED_SHARED	; set PTE type for shared

VMM_ALLOC_SETPTES:
	or	ecx,@PG_DIRTY or @PG_READWRITE	; We set new pages to DIRTY
						; to avoid looking for hits
						; in the backing store cache
						; when the page is swapped.
	call	LSM_SETN_PTES			; set PTEs

	clc					; flag success

VMM_ALLOC_EXIT:
	FlushTLB edx			; flush TLB after PDE/PTE modify
	REGREST <edx, ecx>			; restore registers

	ret

VMM_ALLOC_BAD_REQUEST:
	mov	eax,@DERR_INVAL_LINEAR		; invalid linear address

	stc					; flag error

	jmp	VMM_ALLOC_EXIT			; error exit

VMM_ALLOC_INSUFF_LINEAR:
	mov	eax,@DERR_INSUFF_LINEAR 	; not enough linear memory

	stc					; flag error

	jmp	VMM_ALLOC_EXIT			; error exit

VMM_ALLOC_INSUFF_VIRTUAL:
	mov	eax,@DERR_INSUFF_PHYS		; not enough physical memory

	stc					; flag error

	jmp	VMM_ALLOC_EXIT			; error exit

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_ALLOC	ENDP		; end of VMM_ALLOC procedure
	 FPPROC FVMM_FREE -- Free virtual memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	 push	 ds		 ; save it

	 mov	  ds,ISEL_DSIG3  ; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	 ; Tell the assembler about it

	 call	 VMM_FREE	 ; call the free routine

	 pop	 ds		 ; restore ds
	 assume  ds:nothing	 ; Tell the assembler about it

	 ret			 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing 	 ; end of nothing

FVMM_FREE endp			; End FVMM_FREE procedure
	 NPPROC VMM_FREE -- Free virtual memory
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Free virtual memory

On entry:

EAX	 =	 virtual address of region to free
EBX	 =	 number of pages to free

|

	REGSAVE <ecx, edx, es>		; save registers

	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it

	push	eax			; save for a while
	push	ebx			; ...

VMM_FREE_NEXT:
	or	ebx, ebx		; any more to free?
	jz	VMM_FREE_LIN		; jump if not
	mov	edx, eax		; copy address to free
	MakePTEaddress edx		; edx <- addr of PTE for page to free

	SwitchOnPageType edx
	addressOf VMM_FREE_CONTINUE	; unallocated
	addressOf VMM_FREE_RESERVED	; reserved
	addressOf VMM_FREE_PHYSICAL	; present
	addressOf VMM_FREE_SWAPPED	; swapped
	addressOf VMM_FREE_RESERVED	; reserved inaccessible
	addressOf VMM_FREE_PHYSICAL	; inaccessible
	addressOf VMM_FREE_SWAPPED	; swapped inaccessible
	addressOf VMM_FREE_CONTINUE	; uncommitted
	addressOf VMM_FREE_PHYSICAL	; locked
	addressOf VMM_FREE_PHYSICAL	; locked inaccessible
	addressOf VMM_FREE_CONTINUE	; mapped
	addressOf VMM_FREE_PHYSICAL	; shared
	addressOf VMM_FREE_PHYSICAL	; locked shared
	addressOf VMM_FREE_RESERVED	; reserved shared
	addressOf VMM_FREE_SWAPPED	; swapped shared
	addressOf VMM_FREE_UNCOMPDE	; uncommitted PDE

VMM_FREE_UNCOMPDE:			; free from 4 MB uncommitted region
	mov	ecx, ebx		; ecx <- page count remaining to free
	shl	ecx, @BytePage		; ecx <- byte count remaining to free
	add	ecx, eax		; ecx <- 1st address past freed region
	mov	edx, eax		; edx <- current address to free
	add	edx, @FourMeg		; round up to 4 MB boundary
	and	edx, not (@FourMeg-1)
	cmp	edx, ecx		; if next 4MB boundary > top address
	jae	short VMM_FREE_LIN	;   then exit the loop
	xchg	eax, edx		; else set curr addr to 4MB boundary
	sub	edx, eax		; edx <- neg byte delta to boundary
	neg	edx			; edx <- byte delta to boundary
	shr	edx, @BytePage		; convert to page delta
	sub	ebx, edx		; subtract from pages remaining count
	jmp	short VMM_FREE_CONTINUE ; continue processing the request

VMM_FREE_RESERVED:			; free a reserved page
	dec	VirtualReserved 	; dec count of reserved pages
	jmp	short VMM_FREE_CONTINUE ; continue

VMM_FREE_PHYSICAL:			; free a physical page
	mov	ecx, ebx		; hold count
	mov	ebx, es:[edx]		; pick up physical addr from PTE
	call	PPM_FREE		; free the physical page
	mov	ebx, ecx		; restore count
	jmp	short VMM_FREE_CONTINUE ; continue

VMM_FREE_SWAPPED:			; free a swapped page
	mov	ecx, eax		; hold the address
	mov	eax, es:[edx]		; pick up backing store address
	shr	eax, @BytePage		; shift BS address into position
	call	BSM_FREE		; free the backing store page
	mov	eax, ecx		; restore address

VMM_FREE_CONTINUE:
	dec	ebx			; dec count of pages left to go
	add	eax, @PageSize		; advance address to free next
	jmp	VMM_FREE_NEXT		; keep going

VMM_FREE_LIN:
	 pop	 ebx			 ; recall n pages
	 pop	 eax			 ; recall linear address

	 mov	 ecx, 1 		 ; free page tables
	 call	 LSM_FREE		 ; free the linear space
VMM_FREE_EXIT:
	 FlushTLB edx			 ; flush TLB after PDE/PTE modify

	 REGREST <es, edx, ecx> 	 ; restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_FREE endp		; end of VMM_FREE procedure
	 FPPROC FVMM_REALLOC -- Far version of VMM_REALLOC
COMMENT|

See description of VMM_REALLOC

|
	FVMM_REALLOC_FRAME struc
		frf_SavedEBP	dd	?
		frf_RetAddr	dd	?
		frf_BlockLA	dd	?	; start lin addr of block
		frf_BlockSize	dd	?	; size of block in pages
		frf_NewSize	dd	?	; new size of block in pages
		frf_Flags	dd	?	; alloc_flags record
	FVMM_REALLOC_FRAME ends

	push	ebp			; set up stack
	mov	ebp,esp 		; set base ptr

	push	[ebp].frf_Flags 	; pass arg
	push	[ebp].frf_NewSize	; pass arg
	push	[ebp].frf_BlockSize	; pass arg
	push	[ebp].frf_BlockLA	; pass arg
	call	VMM_REALLOC		; call near version

	pop	ebp			; restore base ptr
	ret				; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FVMM_REALLOC	ENDP			; end FVMM_REALLOC
	 NPPROC VMM_REALLOC -- Reallocate (grow/shrink) memory region
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Resize block, moving it in linear space if necessary.

On entry:	args on stack, see struc below

On exit:

EAX	=	linear address of block, zero if failed

|
	VMM_REALLOC_FRAME struc
		vrf_SavedEBP	dd	?
		vrf_RetAddr	dw	?
		vrf_BlockLA	dd	?	; start lin addr of block
		vrf_BlockSize	dd	?	; size of block in pages
		vrf_NewSize	dd	?	; new size of block in pages
		vrf_Flags	dd	?	; alloc_flags record
	VMM_REALLOC_FRAME ends

	push	ebp				; save base pointer
	mov	ebp, esp			; set up stack frame
	REGSAVE <ebx, ecx, edx, esi, edi, ds, es>	; save registers

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	mov	eax, [ebp].vrf_BlockSize	; shrink or grow?
	cmp	eax, [ebp].vrf_NewSize		; compare old size new size
	jne	short @F			; jump if shrink or grow
	mov	eax, [ebp].vrf_BlockLA		; same size, nothing to do
	jmp	VMM_REALLOC_EXIT		; ...
@@:
	ja	VMM_REALLOC_SHRINK		; jump if shrinking

; Here if grow. The strategy is as follows:
;
;	1) Try to allocate the additional memory immediately above
;		the block.
;	2) If that fails, try to allocate the additional memory
;		immediately below the block, and shift contents down.
;	3) If that fails, try to allocate another block somewhere
;		else in memory, and copy contents of current block
;		to the new block.
;	4) If that fails, give up.

	mov	eax, [ebp].vrf_BlockLA		; eax <- start of block
	mov	ebx, [ebp].vrf_BlockSize	; ebx <- block size in pages
	shl	ebx, @BytePage			; ebx <- size in bytes
	add	eax, ebx			; eax <- end of block
	mov	ebx, [ebp].vrf_NewSize		; ebx <- new size
	sub	ebx, [ebp].vrf_BlockSize	; ebx <- delta to grow
	mov	ecx, [ebp].vrf_Flags		; ecx <- flags
	call	VMM_ALLOC			; try to allocate extension
	jc	short @F			; jump if failed
						; here if success
	mov	eax, [ebp].vrf_BlockLA		; load return value
	jmp	VMM_REALLOC_EXIT		; done
@@:
; Here if couldn't allocate the extension immediately above.
; First we must verify that we have enough virtual memory to grow the
; block.
	xor	eax, eax			; init count of pages needed
	test	[ebp].vrf_flags, mask $commit	; if not committed
	jz	short @F			; then jump
	mov	eax, [ebp].vrf_NewSize		; eax <- new size (pages)
	sub	eax, [ebp].vrf_BlockSize	; eax <- size delta (pages)
@@:						; in the worst case we will
						;   need page tables for the
						;   whole new block
	mov	edx, [ebp].vrf_NewSize		; edx <- whole new block
	shr	edx, 10 			; 1024 pages per page table
	inc	edx
	add	eax, edx			; eax <- full required size

	 mov	 edx,PhysicalManaged ; Calculate PhysicalFree
	 sub	 edx,PhysicalInUse ; ...

	 add	 edx,BSTotal	; Plus BackFree
	 sub	 edx,BSInUse	; ...

	 sub	 edx,VirtualReserved ; Less reserved == available
	 jc	 near ptr VMM_REALLOC_FAIL ; Jump if not enough

	cmp	edx, eax			; is there enough?
	jb	near ptr VMM_REALLOC_FAIL	; jump if not

	test	[ebp].vrf_flags, mask $commit	; if not committed
	jz	short @F			; then jump
	mov	eax, [ebp].vrf_NewSize		; eax <- new size (pages)
	sub	eax, [ebp].vrf_BlockSize	; eax <- size delta (pages)
	add	VirtualReserved, eax		; reserve the committed mem
@@:
	mov	eax, [ebp].vrf_BlockLA		; eax <- start of block
	mov	ebx, [ebp].vrf_NewSize		; ebx <- new size
	sub	ebx, [ebp].vrf_BlockSize	; ebx <- page delta
	shl	ebx, @BytePage			; ebx <- byte delta
	sub	eax, ebx			; eax <- new start addr
	jc	short VMM_REALLOC_NEW		; jump on wrap
	shr	ebx, @BytePage			; ebx <- page delta
	mov	edx, [ebp].vrf_Flags		; ecx <- flags
	and	edx, not mask $commit		; get uncommitted memory
	call	LSM_ALLOC			; try to alloc below
	jc	VMM_REALLOC_NEW 		; jump if failed

	push	[ebp].vrf_BlockSize		; push block size
	push	eax				; push destination address
	push	[ebp].vrf_BlockLA		; push source address
	call	VMM_RELOCATE_BLOCK		; shift it down

VMM_REALLOC_FILLEND:
; now fill page tables for the top of the block with the correct PTE value,
; depending on whether it is committed or uncommitted.
	mov	ecx, @PGBITS_UNCOMMITTED	; assume uncommitted
	test	[ebp].vrf_flags, mask $commit	; is it committed
	jz	short @F			; jump if not
	mov	ecx, @PGBITS_RESERVED+@PG_READWRITE; set type to reserved
@@:
	mov	edx, eax			; remember new block addr
	mov	ebx, [ebp].vrf_NewSize		; ebx <- size of grown block
	mov	eax, [ebp].vrf_BlockSize	; eax <- original size
	sub	ebx, eax			; size of leftover area
	shl	eax, @BytePage			; offset to leftover area
	add	eax, edx			; eax <- start of leftover
	call	LSM_SETN_PTES			; set the PTEs

	mov	eax, edx			; eax <- new block address
	jmp	VMM_REALLOC_EXIT		; and we are done

VMM_REALLOC_NEW:

; Try to allocate the block at any linear address. Allocate it
; uncommitted, then change attribute if request is for committed.

	xor	eax, eax			; zero arg == any address
	mov	ebx, [ebp].vrf_NewSize		; page count to allocate
	mov	edx, [ebp].vrf_Flags		; flags per caller
	and	edx, not mask $commit		; uncommitted please
	call	LSM_ALLOC			; eax <- block address
	jc	VMM_REALLOC_FAIL		; jump if couldn't get it

	push	[ebp].vrf_BlockSize		; push size to move
	push	eax				; push where to move it to
	push	[ebp].vrf_BlockLA		; push where to move it from
	call	VMM_RELOCATE_BLOCK		; move it
						; now free the old block
	mov	edx, eax			; remember new block addr
	mov	eax, [ebp].vrf_BlockLA		; address to free
	mov	ebx, [ebp].vrf_BlockSize	; size to free
	mov	ecx, 1				; flag - free the page tables
	call	LSM_FREE			; throw out old linear space
	mov	eax, edx			; return new addr in eax

	jmp	VMM_REALLOC_FILLEND		; continue

VMM_REALLOC_SHRINK:				; just free the end of the
						; block
	mov	eax, [ebp].vrf_BlockLA		; eax <- block addr
	mov	ebx, [ebp].vrf_NewSize		; ebx <- new size of block
	shl	ebx, @BytePage			; ebx <- new size in pages
	add	eax, ebx			; eax <- end of new block
	mov	ebx, [ebp].vrf_BlockSize	; ebx <- old size
	sub	ebx, [ebp].vrf_NewSize		; ebx <- page delta == size to
						;     be freed
	call	VMM_FREE			; free it
	mov	eax, [ebp].vrf_BlockLA		; return value
	jmp	short VMM_REALLOC_EXIT		; continue

VMM_REALLOC_FAIL:
	xor	eax, eax			; zero address --> error

VMM_REALLOC_EXIT:
	FlushTLB edx			; flush TLB after PDE/PTE modify
	REGREST <es, ds, edi, esi, edx, ecx, ebx> ; restore registers
	assume	ds:nothing,es:nothing		; Tell the assembler about it

	pop	ebp				; restore base pointer

	ret	4*4				; return to caller, pop args

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_REALLOC endp		; end of VMM_REALLOC procedure
	FPPROC FVMM_LOCK -- Lock pages - far entry point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds				; save ds

	mov	ds,ISEL_DSIG3			; Get IGROUP data selector
	assume	ds:IGROUP			; Tell the assembler about it

	call	VMM_LOCK			; lock pages

	pop	ds				; restore ds
	assume	ds:nothing			; Tell the assembler about it

	ret					; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FVMM_LOCK ENDP	; end of FVMM_LOCK procedure
	NPPROC VMM_LOCK -- Lock pages
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Lock memory. Increments lock count for each page in the
	 specified region.

On entry:

EAX	=	virtual address of region
EBX	=	size of region in pages

On exit:

CF	=	1 ==> failed, AX is error code
	=	0 ==> success, EAX clobbered
|
	REGSAVE <ebx, ecx, edx, esi, es>	; save registers
	pushf					; save flags
	cli					; don't interrupt

	test	VMM_FLAG,@VMM_BSPRES		; swapping?
	jz	VMM_LOCK_DONE			; done if not

; Ignore any pages below LinearBottom

	cmp	eax, LinearBottom		; below LinearBottom?
	jb	VMM_LOCK_DONE			; jump if so

; First, we have to scan all the pages, and count up how many
; pages will be newly locked. Also, in this scan, we look for
; any pages which are not lockable. If any of these are found,
; the routine exits without locking anything.

	xor	ecx, ecx			; ecx counts new locks

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it

	push	eax				; save it
	push	ebx				; ...

VMM_LOCK_NEXT1:
	or	ebx, ebx			; any pages left to lock
	jz	VMM_LOCK_CHECK			; jump if not

	mov	edx, eax			; copy address to be locked
	MakePTEaddress edx			; edx <- addr of PTE

	SwitchOnPageType edx
	addressOf VMM_LOCK_BADSTATE	; unallocated
	addressOf VMM_LOCK_NEWLOCK	; reserved
	addressOf VMM_LOCK_NEWLOCK	; present
	addressOf VMM_LOCK_NEWLOCK	; swapped
	addressOf VMM_LOCK_NEWLOCK	; reserved inaccessible
	addressOf VMM_LOCK_NEWLOCK	; inaccessible
	addressOf VMM_LOCK_NEWLOCK	; swapped inaccessible
	addressOf VMM_LOCK_BADSTATE	; uncommitted
	addressOf VMM_LOCK_CONTINUE	; locked
	addressOf VMM_LOCK_CONTINUE	; locked inaccessible
	addressOf VMM_LOCK_CONTINUE	; mapped
	addressOf VMM_LOCK_NEWLOCK	; shared
	addressOf VMM_LOCK_CONTINUE	; locked shared
	addressOf VMM_LOCK_NEWLOCK	; reserved shared
	addressOf VMM_LOCK_NEWLOCK	; swapped shared
	addressOf VMM_LOCK_BADSTATE	; uncommitted PDE

VMM_LOCK_NEWLOCK:
	inc	ecx				; tally new lock required
VMM_LOCK_CONTINUE:
	dec	ebx				; dec count of pages to lock
	add	eax, @PageSize			; advance linear address

	jmp	VMM_LOCK_NEXT1			; continue

VMM_LOCK_CHECK:
	pop	ebx				; restore count
	pop	eax				; restore address of region

	 mov	 edx,PhysicalManaged ; Get managed count
	 sub	 edx,PhysicalLocked ; Less lock count

	 sub	 edx,ecx	; Less # pages to lock
	 jb	 near ptr VMM_LOCK_INSUFF_PHYS ; Jump if not enough

	 cmp	 edx,PhysicalMinUnlocked ; Enough pages?
	 jb	 near ptr VMM_LOCK_INSUFF_PHYS ; Jump if not

; Here if there is sufficient memory. Go through the pages
; again, and modify each according to type.

VMM_LOCK_NEXT2:
	or	ebx, ebx			; any pages left to lock?
	jz	VMM_LOCK_DONE			; jump if not

	mov	edx, eax			; copy address to lock
	MakePTEaddress edx			; edx <- addr of PTE

	SwitchOnPageType edx
	addressOf VMM_LOCK_FAIL 	; unallocated
	addressOf VMM_LOCK_RESERVED	; reserved
	addressOf VMM_LOCK_PRESENT	; present
	addressOf VMM_LOCK_SWAPPED	; swapped
	addressOf VMM_LOCK_RESV_INACC	; reserved inaccessible
	addressOf VMM_LOCK_INACC	; inaccessible
	addressOf VMM_LOCK_NEWLOCK	; swapped inaccessible
	addressOf VMM_LOCK_BADSTATE	; uncommitted
	addressOf VMM_LOCK_PRESENT	; locked
	addressOf VMM_LOCK_INACC	; locked inaccessible
	addressOf VMM_LOCK_LOOP 	; mapped
	addressOf VMM_LOCK_SHARED	; shared
	addressOf VMM_LOCK_SHARED	; locked shared
	addressOf VMM_LOCK_RESV_SHARED	; reserved shared
	addressOf VMM_LOCK_NEWLOCK	; swapped shared
	addressOf VMM_LOCK_BADSTATE	; uncommitted PDE

VMM_LOCK_RESERVED:
	mov	ecx, @PGBITS_LOCKED	; reserved  --> locked
	jmp	short VMM_LOCK_RSVTYPES ; continuen

VMM_LOCK_RESV_INACC:
	mov	ecx, @PGBITS_LOCKED_INACC ; reserved_inacc --> locked_inacc
	jmp	short VMM_LOCK_RSVTYPES ; continuen

VMM_LOCK_RESV_SHARED:
	mov	ecx, @PGBITS_LOCKED_SHARED ; reserved_shared --> locked_shared

VMM_LOCK_RSVTYPES:
	dec	VirtualReserved 	; cash in on reservation
	mov	edx, ebx		; retain counter in edx
	mov	ebx, mask $failIsFatal	; arg: must not fail
	call	VMM_GET_PHYSICAL_PAGE	; get page - swap if necessary

; If zeroing out of demand pages is configured, fill the new page with
; zeros.

	test	I31_FLAG,mask $I31_ZPD	; are we zeroing demand pages?
	jz	short @F		; jump if demand zero not required

	REGSAVE <eax,edx>		; hold those regs
	mov edx,ebx			; edx <- physical addr
	call PPM_GET_LOWADDR		; get low address for page
	mov eax,edx			; pass address to VMM_ZERO_PAGE
	call VMM_ZERO_PAGE		; zap it
	REGREST <edx,eax>		; get regs back
@@:
	cmp	cx, @PGBITS_LOCKED_SHARED ; shared?
	jne	short @F		; jump if not
	push	ax			; save
	mov	ax, $clientMask 	; owner = shared
	call	PPM_SET_PAGE_OWNER	; set owner to shared
	pop	ax			; restore
@@:
	xchg	edx, ebx		; edx <- phys addr, ebx <- counter

	jmp	VMM_LOCK_SETPTE 	; continue

VMM_LOCK_INACC:
	mov	ecx, @PGBITS_LOCKED_INACC ; inacc --> locked_inacc
	jmp	short VMM_LOCK_PHYSICAL ; continue

VMM_LOCK_SHARED:
	mov	ecx, @PGBITS_LOCKED_SHARED ; shared --> locked_shared
	jmp	short VMM_LOCK_PHYSICAL ; continue

VMM_LOCK_PRESENT:
	mov	ecx, @PGBITS_LOCKED	; present --> locked

VMM_LOCK_PHYSICAL:
	mov	edx,  es:[edx]		; pick up physical address from PTE
	and	edx, @PTE_FRM		; clear off low bits
	jmp	VMM_LOCK_SETPTE 	; go lock it

VMM_LOCK_SWAPPED:			; swapped --> locked
	mov	ecx, @PGBITS_LOCKED	; new pte type
	jmp	short VMM_LOCK_SWPTYPES ; common code for swapped types

VMM_LOCK_SWAPPED_INACC: 		; swapped_inacc --> locked_inacc
	mov	ecx, @PGBITS_LOCKED_INACC ; new pte type
	jmp	short VMM_LOCK_SWPTYPES ; common code for swapped types

VMM_LOCK_SWAPPED_SHARED:		; swapped_shared --> locked_shared
	mov	ecx, @PGBITS_LOCKED_SHARED ; new pte type

VMM_LOCK_SWPTYPES:
	 mov	 esi,edx		; Remember address of the PTE
	mov	edx, ebx		; remember counter in edx
	mov	ebx, mask $failIsFatal	; must not fail
	call	VMM_GET_PHYSICAL_PAGE	; get a physical page for swapped page

	cmp	cx, @PGBITS_LOCKED_SHARED; if shared, set Physical Page Record
	jne	short @F		;	to indicate so

	push	ax			; save ax
	mov	ax, $clientMask 	; owner = shared
	call	PPM_SET_PAGE_OWNER	; set page owner
	pop	ax			; restore ax
@@:
	xchg	edx, ebx		; ebx <- counter, edx <- phys address

	REGSAVE <eax,ebx,edx>		; save registers
					; read in page from backing store
	mov	ebx, eax		; ebx <- virtual address
	and	ebx, @PTE_FRM		; make page boundary -mask off attribs
	or	bx, VMMCurrentClient	; encode owner in virtual address
	mov	eax, es:[esi]		; eax <- backing store address
	shr	eax, @BytePage		; shift out low bits
	call	PPM_GET_LOWADDR 	; edx <- address of page's r/w buffer
	call	BSM_GETPAGE		; get the page from backing store

	REGREST <edx,ebx,eax>		; restore registers
VMM_LOCK_SETPTE:

; eax is linear address
; ebx is count of remaining pages
; ecx is page bits
; edx is physical address

	mov	esi, eax		; esi <- virtual address
	MakePTEaddress esi		; esi <- PTE address

	and	edx, @PTE_FRM		; make PTE in ecx . . .
	or	ecx, edx
	and	es:[esi].PDT_PTE, @PG_READWRITE       ; preserve r/w bit
	or	es:[esi], ecx		; set PTE

	xchg	edx, ebx		; edx <- count, ebx <- phys address
	push	eax			; save
	call	PPM_LOCK		; inc lock count
	pop	eax			; restore
	mov	ebx, edx		; ebx <- counter
VMM_LOCK_LOOP:
	add	eax, @PageSize		; onward to next virtual page
	dec	ebx			; one less to go
	jmp	VMM_LOCK_NEXT2		; keep going

VMM_LOCK_DONE:
	popf				; restore flags
	clc				; flag success

VMM_LOCK_EXIT:
	FlushTLB edx			; flush TLB after PDE/PTE modify
	REGREST <es, esi, edx, ecx, ebx>; restore registers
	 assume  es:nothing	; Tell the assembler about it
	ret				; return to caller

VMM_LOCK_ERROR:
	popf				; restore flags
	stc				; flag error
	jmp	VMM_LOCK_EXIT		; exit

VMM_LOCK_BADSTATE:			; tried to lock a page that was
	pop	ebx			; uncommitted, unallocated, or mapped
	pop	eax
	mov	ax,@DERR_INVAL_LINEAR	; invalid linear address
	jmp	VMM_LOCK_ERROR		; error exit

VMM_LOCK_INSUFF_PHYS:			; not enough physical memory to do
	mov	ax, @DERR_INSUFF_PHYS	;	lock
	jmp	VMM_LOCK_ERROR

VMM_LOCK_FAIL:
	int	3			; should never get here
	jmp	VMM_LOCK_ERROR		; error exit

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
VMM_LOCK	ENDP		; end of VMM_LOCK procedure
	FPPROC FVMM_UNLOCK -- Unlock virtual memory - far entry point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds		; save ds

	mov	ds,ISEL_DSIG3	; Get IGROUP data selectgor at PL3
	assume	ds:IGROUP	; Tell the assembler about it

	call	VMM_UNLOCK	; unlock pages

	pop	ds		; restore ds
	assume	ds:nothing	; Tell the assembler about it

	ret			; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_UNLOCK ENDP
	NPPROC VMM_UNLOCK -- Unlock pages
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Unlock memory. Decrements the lock count for each page in the
	specified region. If any pages in the region are not locked,
	nothing is unlocked.

On entry:
EAX	=	virtual address of region to unlock
EBX	=	size of virtual region in pages

On exit:
CF	=	0 ==> success
		1 ==> failure ax = error code
|
	REGSAVE <ecx, edx, esi, es>	; save registers
	pushf				; save flags
	cli				; don't interrupt

	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it
	push	eax			; save
	push	ebx			; ...

	test	VMM_FLAG,@VMM_BSPRES	; swapping?
	jz	VMM_UNLOCK_DONE 	; done if not

; Ignore any pages below LinearBottom

	cmp	eax, LinearBottom	; below LinearBottom?
	jb	VMM_UNLOCK_DONE 	; jump if so

	; In the first loop, verify that all pages in the virtual range
	; specified are indeed locked. If not, return with error.

VMM_UNLOCK_NEXT1:
	or	ebx, ebx		; any pages left to check?
	jz	VMM_UNLOCK_DOIT 	; jump if not

	mov	edx, eax		; copy address to unlock
	MakePTEaddress edx		; edx <- addr of PTE

	SwitchOnPageType edx
	addressOf VMM_UNLOCK_FAIL	; unallocated
	addressOf VMM_UNLOCK_FAIL	; reserved
	addressOf VMM_UNLOCK_FAIL	; present
	addressOf VMM_UNLOCK_FAIL	; swapped
	addressOf VMM_UNLOCK_FAIL	; reserved inaccessible
	addressOf VMM_UNLOCK_FAIL	; inaccessible
	addressOf VMM_UNLOCK_FAIL	; swapped inaccessible
	addressOf VMM_UNLOCK_FAIL	; uncommitted
	addressOf VMM_UNLOCK_OK 	; locked
	addressOf VMM_UNLOCK_OK 	; locked inaccessible
	addressOf VMM_UNLOCK_OK 	; mapped
	addressOf VMM_UNLOCK_FAIL	; shared
	addressOf VMM_UNLOCK_OK 	; locked shared
	addressOf VMM_UNLOCK_FAIL	; reserved shared
	addressOf VMM_UNLOCK_FAIL	; swapped shared
	addressOf VMM_UNLOCK_FAIL	; uncommitted PDE

VMM_UNLOCK_OK:
	add	eax, @PageSize		; advance linear address
	dec	ebx			; dec count of pages left
	jmp	VMM_UNLOCK_NEXT1	; get next


VMM_UNLOCK_DOIT:			; here if all pages in range locked
	pop	ebx			; restore count
	pop	eax			; restore base address

	push	eax			; save again
	push	ebx			; ...

	; In the second loop, decrement the lock count for each page, and
	; if it becomes zero, update the PTE accordingly.

VMM_UNLOCK_NEXT2:
	or	ebx, ebx		; any pages left to unlock?
	jz	VMM_UNLOCK_DONE 	; jump if not

	mov	edx, eax		; copy address to unlock
	MakePTEaddress edx		; edx <- addr of PTE

	SwitchOnPageType edx
	addressOf VMM_UNLOCK_FAIL	; unallocated
	addressOf VMM_UNLOCK_FAIL	; reserved
	addressOf VMM_UNLOCK_FAIL	; present
	addressOf VMM_UNLOCK_FAIL	; swapped
	addressOf VMM_UNLOCK_FAIL	; reserved inaccessible
	addressOf VMM_UNLOCK_FAIL	; inaccessible
	addressOf VMM_UNLOCK_FAIL	; swapped inaccessible
	addressOf VMM_UNLOCK_FAIL	; uncommitted
	addressOf VMM_UNLOCK_DEC	; locked
	addressOf VMM_UNLOCK_DEC	; locked inaccessible
	addressOf VMM_UNLOCK_CONTINUE	; mapped
	addressOf VMM_UNLOCK_FAIL	; shared
	addressOf VMM_UNLOCK_DEC	; locked shared
	addressOf VMM_UNLOCK_FAIL	; reserved shared
	addressOf VMM_UNLOCK_FAIL	; swapped shared
	addressOf VMM_UNLOCK_FAIL	; uncommitted PDE

VMM_UNLOCK_DEC:
	mov	ecx, eax		; save address
	mov	edx, ebx		; save count
	mov	ebx, eax		; ebx <- linear address
	MakePTEaddress ebx		; ebx <- address of PTE
	mov	ebx, es:[ebx]		; ebx <- PTE
	call	PPM_UNLOCK		; decrement lock count
	xchg	eax, ecx		; eax <- address, ecx <- lock count

	or	cl, cl			; is lock count zero?
	jnz	short VMM_UNLOCK_ADVANCE; jump if not
					; here if lock count now zero
	test	bx, @PG_SHARED		; locked_shared -> shared
	jz	short @F		; jump if not shared
	mov	ecx, @PGBITS_SHARED	; set pte type to shared
	jmp	short VMM_UNLOCK_SETPTE ; continue
@@:
	test	bx, @PG_INACCESS	; locked_inacc -> inaccessible
	jz	short @F		; jump if not inaccessible
	mov	ecx, @PGBITS_INACC	; set pte type to inaccessible
	jmp	short VMM_UNLOCK_SETPTE ; continue
@@:
	mov	ecx, @PGBITS_PRESENT	; locked -> present

VMM_UNLOCK_SETPTE:			; ecx is new PTE type
	 and	 ebx, @PTE_FRM		 ; clear out low bits
	 or	 ebx, ecx		 ; or in pte type bits
	 or	 ebx, @PG_DIRTY 	 ; make it dirty
	 mov	 ecx, eax		 ; copy address
	 MakePTEaddress ecx		 ; ecx <- addr of PTE

	 and	 es:[ecx].PDT_PTE,@PG_READWRITE ; preserve r/w bit
	 or	 es:[ecx].PDT_PTE,ebx	 ; set PTE
VMM_UNLOCK_ADVANCE:
	 mov	 ebx, edx		 ; remember count
VMM_UNLOCK_CONTINUE:
	 dec	 ebx			 ; dec count of pages left
	 add	 eax, @PageSize 	 ; advance linear address

	 jmp	 VMM_UNLOCK_NEXT2	 ; go do next page

VMM_UNLOCK_DONE:
	 pop	 ebx			 ; restore count
	 pop	 eax			 ; restore address

	 popf				 ; restore flags

	 clc				 ; flag success
VMM_UNLOCK_EXIT:
	 FlushTLB edx			 ; flush TLB after PDE/PTE modify

	 REGREST <es, esi, edx, ecx>	 ; restore registers
	 assume  es:nothing		 ; Tell the assembler about it

	 ret				 ; return to caller

VMM_UNLOCK_FAIL:
	 pop	 ebx			 ; restore count
	 pop	 eax			 ; restore address

	 popf				 ; restore flags

	 stc				 ; flag error

	 jmp	 VMM_UNLOCK_EXIT	 ; continue

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_UNLOCK	ENDP		; end of VMM_UNLOCK procedure
	 FPPROC  FVMM_GET_ATTRIBUTES - Get page attributes - far entry point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds		; save ds

	mov	ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	assume	ds:IGROUP	; Tell the assembler about it

	call	VMM_GET_ATTRIBUTES ; get attributes

	pop	ds		; restore ds
	assume	ds:nothing	; Tell the assembler about it

	ret			; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FVMM_GET_ATTRIBUTES	ENDP		; end of FVMM_GET_ATTRIBUTES procedure
	NPPROC VMM_GET_ATTRIBUTES -- Get attributes of pages
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Get attributes of pages

On entry:
EAX	=	virtual address of region
EBX	=	size of region in pages
FS:EDI	=	user buffer to receive attributes; word (16-bits) per page

	This function is designed to support DPMI function 506h.
|
	REGSAVE <eax, ebx, ecx, edx, edi, es>	; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it

VMM_GET_ATTR_NEXT:
	or	ebx, ebx			; any pages left to get?
	jz	VMM_GET_ATTR_EXIT		; jump if not
	mov	edx, eax			; copy address
	MakePTEaddress edx			; edx <- address of PTE

	SwitchOnPageType edx
	addressOf VMM_GETATTR_UNCOMMIT	; unallocated
	addressOf VMM_GETATTR_COMMITTED ; reserved
	addressOf VMM_GETATTR_COMMITTED ; present
	addressOf VMM_GETATTR_COMMITTED ; swapped
	addressOf VMM_GETATTR_INACC	; reserved inaccessible
	addressOf VMM_GETATTR_INACC	; inaccessible
	addressOf VMM_GETATTR_INACC	; swapped inaccessible
	addressOf VMM_GETATTR_UNCOMMIT	; uncommitted
	addressOf VMM_GETATTR_COMMITTED ; locked
	addressOf VMM_GETATTR_INACC	; locked inaccessible
	addressOf VMM_GETATTR_MAPPED	; mapped
	addressOf VMM_GETATTR_COMMITTED ; shared
	addressOf VMM_GETATTR_COMMITTED ; locked shared
	addressOf VMM_GETATTR_COMMITTED ; reserved shared
	addressOf VMM_GETATTR_COMMITTED ; swapped shared
	addressOf VMM_GETATTR_UNCOMPDE	; uncommitted PDE

VMM_GETATTR_UNCOMPDE:
	mov	cx, @attrUncommitted		; attribute is uncommitted
	mov	edx, eax		; use PDE address to get R/W attr
	MakePDEaddress edx			; edx <- addr of PDE
	jmp	short VMM_GET_ATTR_PUTBUF	; continue

VMM_GETATTR_UNCOMMIT:
	mov	cx, @attrUncommitted		; attribute is uncommitted
	jmp	short VMM_GET_ATTR_PUTBUF	; continue

VMM_GETATTR_INACC:
	mov	cx, @attrInaccessible		; attribute is inaccessible
	jmp	short VMM_GET_ATTR_PUTBUF	; continue

VMM_GETATTR_MAPPED:
	mov	cx, @attrMapped 		; attribute is mapped
	jmp	short VMM_GET_ATTR_PUTBUF	; continuen

VMM_GETATTR_COMMITTED:
	mov	cx, @attrCommitted		; attribute is committed

VMM_GET_ATTR_PUTBUF:
	or	cx, mask $attrAvail	; dirty/access IS available

	test	word ptr es:[edx], @PG_READWRITE	; is page writable?
	jz	short @F			; jump if not
	or	cx, mask $attrR_W		; set attib writable
@@:
	test	word ptr es:[edx], @PG_DIRTY	; is page dirty?
	jz	short @F			; jump if not
	or	cx, mask $attrDirty		; set attrib dirty
@@:
	test	word ptr es:[edx], @PG_ACCESSED ; is page accessed?
	jz	short @F			; jump if not
	or	cx, mask $attrAccess		; set attrib accessed
@@:
	mov	fs:[edi], cx		; stick it in buffer
	add	edi, 2			; advance buffer pointer
	add	eax, @PageSize		; advance virtual address
	dec	ebx			; one less page to go
	jmp	VMM_GET_ATTR_NEXT	; continue

VMM_GET_ATTR_EXIT:
	 REGREST <es, edi, edx, ecx, ebx, eax>	 ; restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_GET_ATTRIBUTES	ENDP		; end of VMM_GET_ATTRIBUTES procedure
	FPPROC FVMM_SET_ATTRIBUTES -- Set page attributes - far entry point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds		; save ds

	mov	ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	assume	ds:IGROUP	; Tell the assembler about it

	call	VMM_SET_ATTRIBUTES ; set attributes

	pop	ds
	assume	ds:nothing	; Tell the assembler about it

	ret			; return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FVMM_SET_ATTRIBUTES	ENDP		; end of FVMM_SET_ATTRIBUTES procedure
	NPPROC VMM_SET_ATTRIBUTES -- Set page attributes
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Set page attributes

On entry:
EAX	=	virtual address of region
EBX	=	size of region in pages
FS:EDI	=	user buffer containing new attributes

On exit:
EBX	=	number of pages that were NOT successfully modified
|
	REGSAVE <eax, ecx, edx, esi, edi, es>	; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it

VMM_SETATTR_NEXT:
	or	ebx, ebx			; any pages left to set?
	jz	VMM_SETATTR_EXIT		; jump if not

	mov	esi, eax			; copy address
	MakePTEaddress esi			; esi <- address of PTE

	mov	cx, fs:[edi]			; pick up attr to set page
	and	cx, mask $attrType		; isolate type
	cmp	cx, @attrUncommitted		; is it uncommitted
	jne	VMM_SETATTR_COMMIT		; jump if not

					;  Set Page to Uncommitted

	mov	edx, @PGBITS_UNCOMMITTED ; new page type must be uncommitted
	SwitchOnPageType esi
	addressOf VMM_SETATTR_FAIL	; unallocated
	addressOf VMM_SETUNCOMMIT_RESV	; reserved
	addressOf VMM_SETUNCOMMIT_PRES	; present
	addressOf VMM_SETUNCOMMIT_SWAP	; swapped
	addressOf VMM_SETUNCOMMIT_RESV	; reserved inaccessible
	addressOf VMM_SETUNCOMMIT_PRES	; inaccessible
	addressOf VMM_SETUNCOMMIT_SWAP	; swapped inaccessible
	addressOf VMM_SETATTR_RW	; uncommitted
	addressOf VMM_SETUNCOMMIT_PRES	; locked
	addressOf VMM_SETUNCOMMIT_PRES	; locked inaccessible
	addressOf VMM_SETATTR_RW	; mapped
	addressOf VMM_SETATTR_FAIL	; shared
	addressOf VMM_SETATTR_FAIL	; locked shared
	addressOf VMM_SETATTR_FAIL	; reserved shared
	addressOf VMM_SETATTR_FAIL	; swapped shared
	addressOf VMM_SETATTR_ADVANCE	; uncommitted PDE

VMM_SETUNCOMMIT_RESV:
	dec	VirtualReserved 	; decommit reserved page
	jmp	VMM_SETATTR_RW		; continue

VMM_SETUNCOMMIT_PRES:
	push	ebx			; save count
	mov	ebx, es:[esi]		; get physical address from PTE
	call	PPM_FREE		; release the physical page
	pop	ebx			; restore count
	jmp	VMM_SETATTR_RW		; continue

VMM_SETUNCOMMIT_SWAP:
	push	eax			; save address
	mov	eax, es:[esi]		; get backing store address from PTE
	shr	eax, @BytePage		; shift bs address into position
	call	BSM_FREE		; release the backing store page
	pop	eax			; restore address
	jmp	VMM_SETATTR_RW		; continue

VMM_SETATTR_COMMIT:			; Set Page to Committed
	cmp	cx, @attrCommitted	; is attrib committed?
	jne	VMM_SETATTR_INACC	; jump if not

	SwitchOnPageType esi
	addressOf VMM_SETATTR_FAIL	; unallocated
	addressOf VMM_SETATTR_GETPTE	; reserved
	addressOf VMM_SETATTR_GETPTE	; present
	addressOf VMM_SETATTR_GETPTE	; swapped
	addressOf VMM_SETATTR_GETPTE	; reserved inaccessible
	addressOf VMM_SETATTR_GETPTE	; inaccessible
	addressOf VMM_SETATTR_GETPTE	; swapped inaccessible
	addressOf VMM_SETCOMMITTED	; uncommitted
	addressOf VMM_SETATTR_GETPTE	; locked
	addressOf VMM_SETATTR_GETPTE	; locked inaccessible
	addressOf VMM_SETATTR_GETPTE	; mapped
	addressOf VMM_SETATTR_GETPTE	; shared
	addressOf VMM_SETATTR_GETPTE	; locked shared
	addressOf VMM_SETATTR_GETPTE	; reserved shared
	addressOf VMM_SETATTR_GETPTE	; swapped shared
	addressOf VMM_SETATTR_EXPAND	; uncommitted PDE

VMM_SETATTR_GETPTE:
	mov	edx, es:[esi]		; edx <- pte
	jmp	VMM_SETATTR_RW		; continue

VMM_SETATTR_EXPAND:
	call	LSM_EXPAND_UNCOMPDE	; expand uncommitted PDE to page table
	jc	near ptr VMM_SETATTR_FAIL ; jump out if failed
					; fall thru

VMM_SETCOMMITTED:			; commit an uncommitted page
	 mov	 edx,PhysicalManaged ; Calculate PhysicalFree
	 sub	 edx,PhysicalInUse ; ...

	 add	 edx,BSTotal	; Plus BackFree
	 sub	 edx,BSInUse	; ...

	 sub	 edx,VirtualReserved ; Less reserved == available
	 jbe	 VMM_SETATTR_FAIL ; Fail if no virtual memory left

	inc	VirtualReserved 	; else reserve a page
	mov	edx, @PGBITS_RESERVED	; new pte type is reserved
	jmp	VMM_SETATTR_RW		; continuen

VMM_SETATTR_INACC:			; Set Page to Inaccessible
	cmp	cx, @attrInaccessible	; is attrib inaccessbible?
	jne	VMM_SETATTR_MAPPED	; jump if not

	SwitchOnPageType esi
	addressOf VMM_SETATTR_FAIL	; unallocated
	addressOf VMM_SETINACC_RESV	; reserved
	addressOf VMM_SETINACC_PRES	; present
	addressOf VMM_SETINACC_SWAP	; swapped
	addressOf VMM_SETATTR_GETPTE	; reserved inaccessible
	addressOf VMM_SETATTR_GETPTE	; inaccessible
	addressOf VMM_SETATTR_GETPTE	; swapped inaccessible
	addressOf VMM_SETINACC_UNCOM	; uncommitted
	addressOf VMM_SETINACC_LOCK	; locked
	addressOf VMM_SETATTR_GETPTE	; locked inaccessible
	addressOf VMM_SETATTR_FAIL	; mapped
	addressOf VMM_SETATTR_FAIL	; shared
	addressOf VMM_SETATTR_FAIL	; locked shared
	addressOf VMM_SETATTR_FAIL	; reserved shared
	addressOf VMM_SETATTR_FAIL	; swapped shared
	addressOf VMM_SETINACC_EXPAND	; uncommitted PDE

VMM_SETINACC_RESV:
	mov	edx, @PGBITS_RESERVED_INACC	; new pte type: reseved-inacc
	jmp	VMM_SETATTR_RW		; continue

VMM_SETINACC_PRES:
	mov	edx, es:[esi]		; get PTE
	and	edx, @PTE_FRM		; throw away low bits
	or	edx, @PGBITS_INACC	; or in inaccessible attrib
	jmp	VMM_SETATTR_RW		; continue

VMM_SETINACC_SWAP:
	mov	edx, es:[esi]		; get PTE
	and	edx, @PTE_FRM		; throw away low bits
	or	edx, @PGBITS_SWAPPED_INACC ; or in swapped-inacc attrib
	jmp	VMM_SETATTR_RW		; continue

VMM_SETINACC_EXPAND:
	call	LSM_EXPAND_UNCOMPDE	; expand uncommitted PDE
	jc	VMM_SETATTR_FAIL	; continue

VMM_SETINACC_UNCOM:
	 mov	 edx,PhysicalManaged ; Calculate PhysicalFree
	 sub	 edx,PhysicalInUse ; ...

	 add	 edx,BSTotal	; Plus BackFree
	 sub	 edx,BSInUse	; ...

	 sub	 edx,VirtualReserved ; Less reserved == available
	 jbe	 VMM_SETATTR_FAIL ; Fail if no virtual memory left

	inc	VirtualReserved 	; else reserve a page
	mov	edx, @PGBITS_RESERVED_INACC ; new PTE type
	jmp	VMM_SETATTR_RW		; continue

VMM_SETINACC_LOCK:
	mov	edx, es:[esi]		; get PTE
	and	edx, @PTE_FRM		; throw away low bits
	or	edx, @PGBITS_LOCKED_INACC ; new page type is locked-inacc
	jmp	VMM_SETATTR_RW		; continue

VMM_SETATTR_MAPPED:				; Set Page to Mapped
	jmp	VMM_SETATTR_FAIL		; ... not allowed here

VMM_SETATTR_RW: 				; set read/write bit
	and	dx, not @PG_READWRITE	 ; clear r/w bit
	test	word ptr fs:[edi], mask $attrR_W ; test requested state
	jz	short @F			; jump if read only
	or	edx, @PG_READWRITE		; set r/w bit in PTE
@@:
	test	word ptr fs:[edi], mask $attrAvail; decide if remaining bits
	jz	short VMM_SETATTR_PUTPTE	;	matter, jump if not

	and	dx, not (@PG_DIRTY or @PG_ACCESSED) ; clear dirty and accessed
	test	word ptr fs:[edi], mask $attrDirty  ; test requested state
	jz	short @F			; jump if not dirty
	or	dx, @PG_DIRTY			; set dirty bit in PTE
@@:
	test	word ptr fs:[edi], mask $attrAccess ; test access bit request
	jz	short @F			; jump if not accessed
	or	edx, @PG_ACCESSED		; set access bit in PTE
@@:
VMM_SETATTR_PUTPTE:
	mov	es:[esi], edx			; set the PTE

VMM_SETATTR_ADVANCE:
	dec	ebx				; dec count of pages left
	add	eax, @PageSize			; advance linear address
	add	edi, 2				; point to next attrib
	jmp	VMM_SETATTR_NEXT		; continue

VMM_SETATTR_FAIL:
VMM_SETATTR_EXIT:
	 FlushTLB edx			 ; flush TLB after PDE/PTE modify

	 REGREST <es, edi, esi, edx, ecx, eax>	 ; restore registers
	 assume  es:nothing			 ; Tell the assembler about it

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_SET_ATTRIBUTES	ENDP		; end of VMM_SET_ATTRIBUTES procedure
	FPPROC FVMM_MAP_PHYSICAL -- Create physical to linear mapping -far
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	push	ds		; save ds

	mov	ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	assume	ds:IGROUP	; Tell the assembler about it

	call	VMM_MAP_PHYSICAL; create mapping

	pop	ds		; restore ds
	assume	ds:nothing	; Tell the assembler about it

	ret			; renturn to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FVMM_MAP_PHYSICAL ENDP		; end of FVMM_MAP_PHYSICAL procedure
	NPPROC VMM_MAP_PHYSICAL -- Create physical to linear mapping
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Create a linear to physical mapping

On entry:

EAX	=	linear address
EBX	=	physical address
ECX	=	number of pages
EDX	=	0 map physical
	=	1 map conventional

On exit:

CF	=	0 ==> success
		1 ==> failed

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi,es>	 ; save registers

	 mov	 edi,edx			 ; copy phys/conv switch

	 cmp	 eax, LinearBottom		 ; is it below managed region?
	 jb	 VMM_MAPPHYS_FAIL		 ; jump if so

	 mov	 edx, ecx			 ; copy page count
	 shl	 edx, @BytePage 		 ; convert to bytes
	 add	 edx, eax			 ; add to start address

	 cmp	 eax, LinearSystemBreak 	 ; is top in managed area?
	 ja	 VMM_MAPPHYS_FAIL		 ; jump if not

	 mov	 es, ISEL_4GB3			 ; es <- AGROUP
	 assume  es:AGROUP			 ; Tell the assembler about it

	 and	 ebx, @PTE_FRM			 ; round down to page boundary
	 and	 eax, @PTE_FRM			 ; round down to page boundary

VMM_MAPPHYS_NEXT:
	 or	 ecx, ecx			 ; any left?
	 jz	 VMM_MAPPHYS_DONE		 ; jump if not

	 mov	 edx, eax			 ; copy address to edx
	 MakePDEaddress edx			 ; edx <- address of PDE

	 cmp	 es:[edx].PDT_PTE, @PGBITS_UNCOMMITTED ; is PDE uncommitted?
	 jne	 short @F			 ; jump if not

	 call	 LSM_EXPAND_UNCOMPDE		 ; expand uncommitted PDE
	 jc	 VMM_MAPPHYS_FAIL		 ; jump if failed

	 jmp	 short VMM_MAPPHYS_SWITCH	 ; continue

@@:
	 cmp	 es:[edx].PDT_PTE,0		 ; if no page table here
	 je	 short @F			 ; then we will need to make 1

	 push	 eax				 ; compare to default
	 mov	 eax, DefaultPDE		 ; get default
	 xor	 eax, es:[edx].PDT_PTE		 ; is it the same?
	 and	 eax, @PTE_FRM			 ; throw away low bits
	 pop	 eax				 ; restore address
	 jnz	 short VMM_MAPPHYS_SWITCH	 ; jump if page table there
@@:
	 call	 LSM_NEW_PAGE_TABLE		 ; make new page table
	 jc	 VMM_MAPPHYS_FAIL		 ; and give up if we can't
VMM_MAPPHYS_SWITCH:
	 mov	 esi, eax			 ; copy address to esi
	 MakePTEaddress esi			 ; esi <- PTE address

	 SwitchOnPageType esi
	 addressOf VMM_MAPPHYS_FREE	 ; unallocated
	 addressOf VMM_MAPPHYS_RESERVED  ; reserved
	 addressOf VMM_MAPPHYS_PHYSICAL  ; present
	 addressOf VMM_MAPPHYS_SWAPPED	 ; swapped
	 addressOf VMM_MAPPHYS_RESERVED  ; reserved inaccessible
	 addressOf VMM_MAPPHYS_PHYSICAL  ; inaccessible
	 addressOf VMM_MAPPHYS_SWAPPED	 ; swapped inaccessible
	 addressOf VMM_MAPPHYS_SETPTE	 ; uncommitted
	 addressOf VMM_MAPPHYS_PHYSICAL  ; locked
	 addressOf VMM_MAPPHYS_PHYSICAL  ; locked inaccessible
	 addressOf VMM_MAPPHYS_SETPTE	 ; mapped
	 addressOf VMM_MAPPHYS_ADVANCE	 ; shared
	 addressOf VMM_MAPPHYS_ADVANCE	 ; locked shared
	 addressOf VMM_MAPPHYS_ADVANCE	 ; reserved shared
	 addressOf VMM_MAPPHYS_ADVANCE	 ; swapped shared
	 addressOf VMM_MAPPHYS_UNCOMPDE  ; uncommitted PDE
VMM_MAPPHYS_UNCOMPDE:
	 call	 LSM_EXPAND_UNCOMPDE	 ; expand uncommitted PDE - make PT
	 jc	 VMM_MAPPHYS_FAIL	 ; jump if failed

	 jmp	 VMM_MAPPHYS_SETPTE	 ; set up mapping

VMM_MAPPHYS_FREE:			; if was unallocated
	 push	 ebx			 ; then grab the linear page
	 mov	 ebx, 1
	 xor	 edx, edx		 ; edx <- client space

	 cmp	 eax, LinearClientBottom ; if in client region
	 jae	 short @F		 ; jump over

	 mov	 edx, mask $shared	 ; edx <- shared space
@@:
	 call	 LSM_ALLOC		 ; allocate linear space
	 pop	 ebx			 ; restore phys addr

	 jmp	 VMM_MAPPHYS_SETPTE	 ; continue

VMM_MAPPHYS_RESERVED:			; map over reserved page
	 dec	 VirtualReserved	 ; dec count of reserved pages

	 jmp	 VMM_MAPPHYS_SETPTE	 ; continue

VMM_MAPPHYS_SWAPPED:			; map over swapped page
	 push	 eax			 ; save address

	 mov	 edx,eax		 ; copy address
	 MakePTEaddress edx		 ; edx <- address of PTE
	 mov	 eax,es:[edx]		 ; get PTE
	 shr	 eax,@BytePage		 ; shift bs address into position
	 call	 BSM_FREE		 ; free the bs page

	 pop	 eax			 ; restore address

	 jmp	 short VMM_MAPPHYS_SETPTE; continue

VMM_MAPPHYS_PHYSICAL:			; map over physical page
	 mov	 edx,ebx		 ; release the page
	 mov	 ebx,es:[esi]		 ; get PTE
	 call	 PPM_FREE		 ; free the page
	 mov	 ebx,edx		 ; restore physical address
VMM_MAPPHYS_SETPTE:
	 mov	 edx,ebx		 ; copy physical/conventional address

	 or	 edi,edi		 ; physical or conventional?
	 jz	 short @F		 ; jump if physical

	 MakePTEaddress edx		 ; find the PTE for conv addr
	 mov	 edx, es:[edx]		 ; get physical address
	 and	 edx, not (@PageSize-1)  ; clear the low bits
@@:					; join physical code
	 or	 edx, @PGBITS_MAPPED+@PG_READWRITE ; set page type
	 mov	 es:[esi], edx		 ; set the pte

VMM_MAPPHYS_ADVANCE:
	 dec	 ecx			 ; dec count of pages left
	 add	 eax, @PageSize 	 ; advance linear address
	 add	 ebx, @PageSize 	 ; advance physical address

	 jmp	 VMM_MAPPHYS_NEXT	 ; continue

VMM_MAPPHYS_DONE:
	 clc			; Flag success
VMM_MAPPHYS_EXIT:
	 FlushTLB edx		; Flush TLB after PDE/PTE modify

	 REGREST <es,edi,esi,edx,ecx,ebx,eax> ; restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret				 ; return to caller

VMM_MAPPHYS_FAIL:
	 stc				 ; flag error

	 jmp	 VMM_MAPPHYS_EXIT	 ; error exit

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_MAP_PHYSICAL endp		; End VMM_MAP_PHYSICAL procedure
	FPPROC	VMM_PageFaultHandler - Page Fault Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

The VMM's page fault handler is called from QMAX_I0E.ASM with the
CR2 value on the stack.  It ignores any calls in which the CR2
value does not specify an address within the region managed by
the VMM (i.e. anything below Linear_Bottom).

If the page directory entry is not present and it is not of type
PDE_UNCOMMITTED, the page fault handler gives up and returns indicating
that the fault was not handled.

If the page directory entry is of type PDE_UNCOMMITTED, the page
fault handler returns indicating that the fault should be made
visible to the client (i.e., if the client has a page fault handler,
it should be called).

For present page directory entries, the handler branches on the type
of page as determined by the page table entry.	There are four
distinct cases:


	1) The page was not owned by any client.  This is a transparent
	   fault (fatal).

	2) A reserved page faulted. The handler decrements the reserved
	   count, allocates a physical page and makes it present.

	3) A swapped page faulted. The handler allocates a physical
	   page, and calls BSM_GETPAGE to read the contents from the
	   backing store to the physical page.	It makes the page
	   present.

	4) A visible fault occurred.  The handler returns indicating
	   that the client's handler should be called.

On entry:

CR2	(on stack)	linear address of fault (error bits ignored)

On exit:
EAX	=	-1	fault is fatal
EAX	=	0	fault is transparent (and was handled)
EAX	=	1	fault is visible - call user handler if installed

|
	PFframe struc
		PFsavedEBP	dd	?
		PFretIP 	dw	?
		PFretCS 	dw	?
		PFcr2		dd	?
	PFframe ends

	push	ebp			; save base pointer
	mov	ebp, esp		; set up stack frame
	REGSAVE <ebx, ecx, edx, esi, ds, es>; save registers

	mov	ds,ISEL_DSIG3		; Get IGROUP data selector at PL3
	assume	ds:IGROUP		; Tell the assembler about it

	inc	PageFaultActive 	; indicate page fault processing

	mov	es, ISEL_4GB3		; es <- AGROUP
	 assume  es:AGROUP		; Tell the assembler about it

	mov	esi, [ebp].PFcr2	; pick up CR2
	mov	eax, esi		; eax <- CR2

	cmp	esi, LinearBottom	; below LinearBottom?
	jb	VMM_PFAULT_FATAL	; jump if so
	cmp	esi, LinearClientTop	; above LinearTop
	jae	VMM_PFAULT_FATAL	; jump if so

	MakePDEaddress esi		; esi <- PDE address
	mov	edx, AGROUP:[esi]	; edx <- PDE
	or	edx, edx		; if no directory entry, fatal
	jz	near ptr VMM_PFAULT_FATAL;  jump if PDE is zero

; check for uncommitted PDE
	cmp	edx, @PGBITS_UNCOMMITTED; check PDE
	je	VMM_PFAULT_VISIBLE	; jump if uncommitted

	mov	esi, eax
	MakePTEaddress esi
	SwitchOnPageType esi
	addressOf VMM_PFAULT_FATAL	; unallocated
	addressOf VMM_PFAULT_RESERVED	; reserved
	addressOf VMM_PFAULT_VISIBLE	; present
	addressOf VMM_PFAULT_SWAPPED	; swapped
	addressOf VMM_PFAULT_VISIBLE	; reserved inaccessible
	addressOf VMM_PFAULT_VISIBLE	; inaccessible
	addressOf VMM_PFAULT_VISIBLE	; swapped inaccessible
	addressOf VMM_PFAULT_VISIBLE	; uncommitted
	addressOf VMM_PFAULT_VISIBLE	; locked
	addressOf VMM_PFAULT_VISIBLE	; locked inaccessible
	addressOf VMM_PFAULT_VISIBLE	; mapped
	addressOf VMM_PFAULT_VISIBLE	; shared
	addressOf VMM_PFAULT_VISIBLE	; locked shared
	addressOf VMM_PFAULT_RES_SHARED ; reserved shared
	addressOf VMM_PFAULT_SWP_SHARED ; swapped shared

VMM_PFAULT_RES_SHARED:
	mov	edx, @PGBITS_SHARED	; new pte type is shared
	jmp	short VMM_PFAULT_RESTYPES ; process shared

VMM_PFAULT_RESERVED:
	mov	edx, @PGBITS_PRESENT	; new pte type is present

VMM_PFAULT_RESTYPES:
	dec	VirtualReserved 	; dec count of reserved pages
	mov	eax, [ebp].PFcr2	; pass fault address
	mov	ebx, mask $canSwap or mask $failIsFatal ; flags
	call	VMM_GET_PHYSICAL_PAGE	; get a page - fatal if fails
	and	ebx, @PTE_FRM		; throw away low bits

; If zeroing out of demand pages is configured, fill the new page with
; zeros.

	 test	 I31_FLAG,mask $I31_ZPD  ; are we zeroing demand pages?
	 jz	 short @F		 ; jump if demand zero not required

	 REGSAVE <eax,edx>		 ; hold those regs

	 mov	 edx,ebx		; EDX <- physical addr
	 call	 PPM_GET_LOWADDR	; get low address for page

	 mov	 eax,edx		; pass address to VMM_ZERO_PAGE
	 call	 VMM_ZERO_PAGE		; zap it

	 REGREST <edx,eax>		; get regs back
@@:
	 or	 ebx, edx
	 and	 es:[esi].PDT_PTE, @PG_READWRITE       ; preserve r/w bit
	 or	 es:[esi].PDT_PTE, ebx		 ; set the pte

	 jmp	 VMM_PFAULT_TRANS	 ; continue

VMM_PFAULT_SWP_SHARED:
	 mov	 edx, @PGBITS_SHARED	 ; new pte type is shared

	 jmp	 short VMM_PFAULT_SWPTYPES ; continue

VMM_PFAULT_SWAPPED:
	 mov	 edx, @PGBITS_PRESENT	 ; new pte type is present
VMM_PFAULT_SWPTYPES:
	 mov	 eax, [ebp].PFcr2	 ; pick up fault address
	 mov	 ebx,(mask $canSwap) or (mask $failIsFatal) ; flags
	 call	 VMM_GET_PHYSICAL_PAGE	 ; ebx <- physical address

	 push	 edx			 ; save PTE type
	 push	 ebx			 ; save physical address

	 mov	 edx, ebx		 ; edx <- physical address
	 call	 PPM_GET_LOWADDR	 ; edx <- low address of page

	 mov	 eax, es:[esi].PDT_PTE	 ; eax <- PTE
	 and	 eax, @PG_READWRITE	 ; isolate r/w bit
	 xchg	 eax, es:[esi].PDT_PTE	 ; zero pte while swapping (keep R/W)
	 shr	 eax, @BytePage 	 ; eax <- backing store address
	 mov	 ebx, [ebp].PFcr2	 ; ebx <- virtual address
	 and	 ebx, @PTE_FRM		 ; throw away low bits
	 or	 bx, VMMcurrentClient	 ; ebx <- va/client
	 call	 BSM_GETPAGE		 ; read page from backing store

	 pop	 ebx			 ; recall physical address
	 pop	 edx			 ; recall pte bits

	 and	 ebx, @PTE_FRM		 ; throw away low bits
	 or	 ebx, edx		 ; or in new arb bits
	 and	 es:[esi].PDT_PTE,@PG_READWRITE       ; preserve r/w bit
	 or	 es:[esi].PDT_PTE,ebx	; set the pte
VMM_PFAULT_TRANS:
	 test	 edx, @PG_SHARED	 ; if page is not shared
	 jz	 short @F		 ; skip

	 mov	 ax, $clientMask	 ; else
	 call	 PPM_SET_PAGE_OWNER	 ; set page owner to "shared"
@@:
	 FlushTLB eax			 ; flush TLB after PDE/PTE modify
	 xor	 eax, eax		 ; indicate transparent fault
VMM_PFAULT_EXIT:
	 dec	 PageFaultActive	 ; clear page fault processing

	 REGREST <es, ds, esi, edx, ecx, ebx> ;restore registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp			; restore base pointer

	ret	4			; return to caller, pop arg

VMM_PFAULT_FATAL:
	mov	eax, -1 		; it's not my fault
	jmp	VMM_PFAULT_EXIT 	; exit

VMM_PFAULT_VISIBLE:
	mov	eax, 1			; client wants the fault
	jmp	VMM_PFAULT_EXIT 	; exit
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
VMM_PageFaultHandler	ENDP		; end of VMM_PageFaultHandler procedure
	 NPPROC  VMM_SWAP_OUT - Swap out a page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Move a virtual page from physical memory to backing store

|
	REGSAVE <eax, ebx, ecx, edx, esi, edi, es> ; save registers

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it

	xor	cx, cx				; cx <- oldest age
	xor	edi, edi			; edi <- phys addr of old page

	movzx	bx, nRegions			; bx <- count of regions left
	xor	esi, esi
	mov	si, offset IGROUP:RegionTable	; si <- current region struc
VMM_SWAPOUT_NEXT_REGION:
	or	bx, bx				; any regions left?
	jz	VMM_SWAPOUT_PUTPAGE		; jump if not

	push	bx				; save region count
	push	si				; save region pointer

	mov	edx, [si].PRsize		; edx <-page count
	mov	ebx, [si].PRbase		; ebx <-phys addr of region
	call	PPM_GET_PAGE_RECORD		; esi <-address of page record
VMM_SWAPOUT_NEXT_PAGE:
	or	edx, edx			; any pages left in region?
	jz	VMM_SWAPOUT_REGION_ADVANCE	; jump if not
						; ignore not swappable pages
	test	es:[esi].PPflags, mask $swappable ; is page swappable?
	jz	VMM_SWAPOUT_PAGE_ADVANCE	; jump if not

	test	es:[esi].PPflags, mask $marked	; if marked for swap
	jnz	VMM_SWAPOUT_FOUND_MARKED	; we've got our winner

	mov	ax, VMMcurrentTime		; get the VMM time
	add	ax, 10h 			; use next quantum as ref
	sub	ax, es:[esi].PPusage		; ax is age of this page

	cmp	ax, cx				; if younger, skip it
	jb	VMM_SWAPOUT_PAGE_ADVANCE	; jump if younger
	je	short VMM_SWAPOUT_EQUALAGE	; jump if == to current oldest
						; here if page is new oldest
	mov	cx, ax				; cx <- new oldest age
	mov	edi, ebx			; edi <- phys addr of old page
	mov	eax, es:[esi].PPaddr		; eax <- va/client
	call	VMM_GET_PTE_ADDRESS		; eax <- address of PTE
						; (possibly not this client)
VMM_SWAPOUT_TESTDIRTY:
	test	word ptr es:[eax], @PG_DIRTY	; is page dirty?
	jz	short @F			; jump if not

	or	edi, 1				; set low bit of phys addr to
						;	indicate dirty
@@:
	jmp	short VMM_SWAPOUT_PAGE_ADVANCE	; continue

VMM_SWAPOUT_EQUALAGE:

; Here if current page is as old as oldest. Prefer to swap out a
; clean page.

	test	edi, 1				; is oldest dirty?
	jz	short VMM_SWAPOUT_PAGE_ADVANCE	; jump if clean

	mov	edi, ebx			; edi <- oldest phys page
	mov	eax, es:[esi].PPaddr		; eax <- physical address
	call	VMM_GET_PTE_ADDRESS		; eax <- address of PTE

	jmp	VMM_SWAPOUT_TESTDIRTY		; continue

VMM_SWAPOUT_PAGE_ADVANCE:
	add	ebx, @PageSize			; advance physical address
	add	esi, size PhysicalPageRecord	; advance to next page rec
	dec	edx				; dec count of pages in region

	jmp	VMM_SWAPOUT_NEXT_PAGE		; continue

VMM_SWAPOUT_REGION_ADVANCE:
	pop	si				; restore region ptr
	pop	bx				; restore region count

	dec	bx				; dec count of regions left
	add	si, size PhysicalRegion 	; advance region ptr

	jmp	VMM_SWAPOUT_NEXT_REGION 	; do next

VMM_SWAPOUT_FOUND_MARKED:
	mov	edi, ebx			; edi <- oldest phys page
	mov	eax, es:[esi].PPaddr		; eax <- va/client
	call	VMM_GET_PTE_ADDRESS		; eax <- address of PTE
						; (possibly not this client)
	test	word ptr es:[eax], @PG_DIRTY	; is page dirty?
	jz	short @F			; jump if not

	or	edi, 1				; set low bit of phys addr to
						;	indicate dirty
@@:
	pop	si				; restore region ptr
	pop	bx				; restore region count
VMM_SWAPOUT_PUTPAGE:

; edi is physical address of oldest page

	or	edi, edi			; did we get one?
	jnz	short @F			; jump if we did

	int	3				; not good
@@:
	mov	ebx, edi			; copy old phys addr
	call	PPM_GET_PAGE_RECORD		; esi <- page record addr
						; prepare for putpage call
	and	es:[esi].PPflags, not mask $swappable
	mov	eax, edi			; copy dirty bit to eax
	and	eax, 1				; isolate dirty
	and	di, not 1			; clear dirty
	mov	ebx, es:[esi].PPaddr		; get virtual address/client
	mov	edx, edi			; edx <- old phys addr
	call	PPM_GET_LOWADDR 		; get mapped addr
	call	BSM_PUTPAGE			; send it backing store

	dec	PhysicalSwappable		; one less swappable page

	mov	ebx, eax			; ebx <- backing store addr
	shl	ebx, @BytePage			; shift it up

	mov	eax, es:[esi].PPaddr		; eax <- virtual address
	call	VMM_GET_PTE_ADDRESS		; eax <- address of PTE
	and	es:[eax].PDT_PTE,@PG_READWRITE or @PG_SHARED or @PG_INACCESS
	or	ebx, @PGBITS_SWAPPED		; set type to swapped
	or	es:[eax].PDT_PTE,ebx		; set up the new pte

	mov	ebx, edi			; ebx <- addr of swapped page
	call	PPM_FREE			; free that physical page

	mov	BSActive, 1			; signal swapping activity

	FlushTLB edx			; flush TLB after PDE/PTE modify

	REGREST <es, edi, esi, edx, ecx, ebx, eax>
	assume	es:nothing			; Tell the assembler about it

	ret

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_SWAP_OUT	ENDP		; end of VMM_SWAP_OUT procedure
	NPPROC VMM_GET_PHYSICAL_PAGE -- Get a physical page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

This routine will allocate a page from the PPM if available.  If not, it will
force a page out to the swapfile.

On entry:

EAX	=	virtual address (assumes current client is owner)
EBX	=	flags: $canSwap if page is swappable; $failIsFatal

On exit:

EBX	=	physical address of page, or -1 if failed
|
	REGSAVE <edx>				; save register

	mov	edx, ebx			; save flags
	call	PPM_ALLOC			; try for a page
	cmp	ebx, -1 			; did we get one?
	jne	short VMM_GETPAGE_EXIT		; jmp if yes

	cmp	PhysicalSwappable, 0		; any swappable pages?
	jne	short @F			; jump if so
	mov	ebx, -1 			; alas there are none
	jmp	short VMM_GETPAGE_EXIT		; continue
@@:
	call	VMM_SWAP_OUT			; swap something out

	call	PPM_ALLOC			; try again
	cmp	ebx, -1 			; did we get one
	jne	short VMM_GETPAGE_EXIT		; jmp if yes

	 test	 edx, mask $failIsFatal 	 ; we failed
	 jz	 short VMM_GETPAGE_EXIT 	 ; exit if ok to fail

	 int	 3				 ; else complain
VMM_GETPAGE_EXIT:
	 REGREST <edx>				 ; restore register

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_GET_PHYSICAL_PAGE	ENDP		; end of VMM_GET_PHYSICAL_PAGE procedure
	 NPPROC VMM_EXCHANGE_MAPPING -- Exchange mapping of two regions
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Exchange page mapping between two linear regions. Caller must
	 validate regions before calling.

On entry:

EBX	=	linear address of first region
EDX	=	linear address of second region
ECX	=	size of region in pages
|
	REGSAVE <eax, ebx, ecx, edx, esi, edi, es> ; save registers

	mov	esi, ebx			; copy addres of 1st region
	mov	edi, edx			; copy addres of 1st region
	MakePTEaddress esi			; esi <- addr of PTE for 1st
	MakePTEaddress edi			; edi <- addr of PTE for 2nd

	mov	es, ISEL_4GB3			; es <- AGROUP
	assume	es:AGROUP			; Tell the assembler about it

VMM_EXCHANGE_NEXT:
	or	ecx, ecx			; any pages left?
	jz	VMM_EXCHANGE_EXIT		; jump if not

	push	esi				; pte addr
	push	ebx				; old addr
	push	edx				; new addr
	call	VMM_UPDATE_PAGEINFO		; update page information

	push	edi				; pte addr
	push	edx				; old addr
	push	ebx				; new addr
	call	VMM_UPDATE_PAGEINFO		; update page information

	mov	eax, es:[esi]			; get PTE of 1st
	xchg	eax, es:[edi]			; swap with PTE of 2nd
	mov	es:[esi], eax			; set PTE of 1st to 2nd

VMM_EXCHANGE_ADVANCE:
	dec	ecx				; one less page to go
	add	esi, 4				; point to next PTE in 1st
	add	edi, 4				; point to next PTE in 2nd
	add	ebx, @PageSize			; advance address
	add	edx, @PageSize			; ...
	jmp	VMM_EXCHANGE_NEXT		; continue

VMM_EXCHANGE_EXIT:
	FlushTLB edx			; flush TLB after PDE/PTE modify

	REGREST <es, edi, esi, edx, ecx, ebx, eax> ; restore registers
	assume	es:nothing			; Tell the assembler about it

	ret					; return to caller
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
VMM_EXCHANGE_MAPPING	ENDP		; end of VMM_EXCHANGE_MAPPING procedure
	NPPROC VMM_UPDATE_PAGEINFO - update page information
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT| Auxilliary routine for VMM_EXCHANGE_MAPPING

On entry:

stack:	address of pte
	old virtual address
	new virtual address
|
	UPDATEframe	struc
		UPDsavedEBP	dd	?
		UPDretIP	dw	?
		UPDnewVA	dd	?	; new virtual address
		UPDoldVA	dd	?	; old virtual address
		UPDpteAddr	dd	?	; address of pte
	UPDATEframe	ends


	push	ebp				; save base ptr
	mov	ebp, esp			; set up stack frame
	REGSAVE <eax, ebx>			; save registers

	mov	eax, [ebp].UPDpteAddr	; get the PTE address
	SwitchOnPageType eax
	addressOf VMM_UPDATE_EXIT	; unallocated
	addressOf VMM_UPDATE_EXIT	; reserved
	addressOf VMM_UPDATE_SETADDR	; present
	addressOf VMM_UPDATE_INVAL	; swapped
	addressOf VMM_UPDATE_EXIT	; reserved inaccessible
	addressOf VMM_UPDATE_SETADDR	; inaccessible
	addressOf VMM_UPDATE_INVAL	; swapped inaccessible
	addressOf VMM_UPDATE_EXIT	; uncommitted
	addressOf VMM_UPDATE_SETADDR	; locked
	addressOf VMM_UPDATE_SETADDR	; locked inaccessible
	addressOf VMM_UPDATE_EXIT	; mapped
	addressOf VMM_UPDATE_SETADDR	; shared
	addressOf VMM_UPDATE_SETADDR	; locked shared
	addressOf VMM_UPDATE_EXIT	; reserved shared
	addressOf VMM_UPDATE_INVAL	; swapped shared
	addressOf VMM_UPDATE_EXPAND	; uncommitted PDE

VMM_UPDATE_EXPAND:
	mov	eax, [ebp].UPDoldVA	; get the old address
	call	LSM_EXPAND_UNCOMPDE	; make a full page table of uncomm...
	jmp	short VMM_UPDATE_EXIT	; done

VMM_UPDATE_INVAL:			; invalidate BS cache if was swapped
	mov	ebx, [ebp].UPDoldVA	; get the old virtual address
	call	BSM_INVALIDATE_CACHE_ENTRY ;invalidate the BS cache entry
	jmp	short VMM_UPDATE_EXIT	; continue

VMM_UPDATE_SETADDR:
	mov	ebx, es:[eax]		; get PTE (phys addr)
	mov	eax, [ebp].UPDnewVA	; get new PTE address
	call	PPM_SET_PAGE_ADDRESS	; set virtual address for page

VMM_UPDATE_EXIT:
	 REGREST <ebx, eax>		 ; restore registers

	 pop	 ebp			 ; restore base pointer

	 ret	 0Ch			 ; return to caller, pop args

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_UPDATE_PAGEINFO endp	; End VMM_UPDATE_PAGEINFO procedure
	 NPPROC  VMM_GET_PTE_ADDRESS - Get PTE Address
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get the address of the PTE for a given address and client.  The client
id is in the low 12 bits of the address.  If the client is not the
current client, we have to find the physical address of that client's
page directory, use its lowAddr to find the physical address of the
page table, and use its lowAddr to locate the specific page table
entry.

On entry:

EAX	 =	 virtual address/client id

On exit:

EAX	 =	 linear address of PTE

|

	 REGSAVE <ebx,edx,edi,es> ; Save registers

	 mov	 ebx,eax	; EBX <- va/c
	 and	 ebx,not @PTE_FRM ; EBX <- client id

	 cmp	 bx,$clientMask ; Izit a shared owner?
	 je	 short VMM_GETPTE1 ; Jump if so

	 cmp	 bx,VMMcurrentClient ; If not current client
	 jne	 short @F	; Then jump
VMM_GETPTE1:
	 MakePTEaddress eax	; Else easy case

	 jmp	 VMM_GETPTE_EXIT ; And out

@@:
	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 xchg	 eax,ebx	; AX <- client id, EBX <- va/c
	 call	 VMM_GET_CLIENT_INFO ; es:edi <- NON-current client's TSS addr

	 mov	 edx,es:[edi].TSS_CR3 ; Pick up client's page dir
	 call	 PPM_GET_LOWADDR ; EDX <- low addr of page dir

	 mov	 eax,ebx
	 shr	 eax,22 	; Get top ten bits
	 shl	 eax,2		; Mul by 4 to get PDE offset
	 add	 eax,edx	; Add to PDE address
	 mov	 edx,es:[eax]	; EDX <- PDE (page table phys)
	 and	 edx,@PTE_FRM	; Mask off attribs
	 call	 PPM_GET_LOWADDR ; EDX <- low addr of page tab

	 shr	 ebx,@BytePage	; Shift in PT offset
	 shl	 ebx,2		; PTEs are dwords
	 and	 ebx,not @PTE_FRM ; Discard top bits
	 add	 edx,ebx	; Add in page table address
	 mov	 eax,edx	; Return in EAX
VMM_GETPTE_EXIT:
	 REGREST <es,edi,edx,ebx> ; restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_GET_PTE_ADDRESS endp	; End VMM_GET_PTE_ADDRESS procedure
	 FPPROC FVMM_ZERO_PAGE -- Far version of VMM_ZERO_PAGE
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

See below

|

	 call	 VMM_ZERO_PAGE			 ; call near version

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_ZERO_PAGE endp		; End PVMM_ZERO_PAGE procedure
	 NPPROC  VMM_ZERO_PAGE -- Zero Out A Page
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Zero out a page

On entry:

EAX	=	linear address of page

On exit:

|

	 REGSAVE <eax,ecx,edi,es> ; Save registers

	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ecx,@PageSize/4 ; Count of dwords to zap
	 mov	 edi,eax	; Destination address
	 xor	 eax,eax	; Value to store
	 cld			; Go forward
     rep stos	 es:[edi].EDD	; Zap

	 REGREST <es,edi,ecx,eax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_ZERO_PAGE endp		; End VMM_ZERO_PAGE procedure
	 NPPROC  VMM_GET_CLIENT_INFO
	 assume  ds:IGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get linear address of VMM client information structure. Normally we
prefer to use PCURTSS, but in at least one case (locating the
TSS of a non-current client to find its page directory when swapping
out a page), this routine is necessary.

On entry:

AX	 =	 client id, if 0 use VMMcurrentClient

On exit:

EDI	 =	 linear address of current TSS

|

	 REGSAVE <eax>		; Save register

	 or	 ax,ax		; Use current id?
	 jnz	 short @F	; Jump if not

	 mov	 ax,VMMcurrentClient ; Use current client
@@:
	 mov	 di,ax		; Copy to index register
	 and	 di,not (mask $PL) ; Clear PL bits

	 mov	 ah,DESC_TAB[di].DESC_BASE3 ; Load base into EAX
	 mov	 al,DESC_TAB[di].DESC_BASE2 ; Get byte 2
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,DESC_TAB[di].DESC_BASE01 ; Get bytes 0,1
	 mov	 edi,eax	; Return in EDI

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_GET_CLIENT_INFO endp	; End VMM_GET_CLIENT_INFO procedure
	 NPPROC  VMM_TERMINATE_CLIENT -- Terminate The Current DPMI Client
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Terminate the current DPMI client

|

	pushad
	REGSAVE <ds,es,fs>	; Save registers

	 pushf				; save flags
	 cli				; don't interrupt

	 mov	 ds, ISEL_DSIG3 	; IGROUP
	 assume  ds:IGROUP		; tell assembler

; Close the swapfile for this client

	mov	ecx,PCURTSS	; Get the offset in PGROUP of the current TSS

	test	PGROUP:[ecx].DPTSS_FLAG,mask $DPTSS_BSMINIT ; Izit initialized?
	jz	short @F       ; Jump if not

	 call	 BSM_TERMINATE_CLIENT	; terminate backing store mgr for client
@@:

; Deallocate old LDT and restore new one

	 call	 DPMIFN_FREELDT 	; Free it

	 test	 PGROUP:[ecx].DPTSS_FLAG,mask $DPTSS_LSMINIT ; Izit initialized?
	 jz	 near ptr VMM_TERMINATE_EXIT ; Jump if not

; We will walk the client's linear free list and free any
; memory that is NOT in that list.

	 call	 LSM_GET_CLIENT_LIST	; fs:edi <- first list structure ptr
	 mov	 esi, fs:[edi].FreeHead ; esi <- ptr to first free block
	 mov	 eax, LinearClientBottom; eax <- base of block to free

	 mov	 es, ISEL_4GB3		; AGROUP
	 assume  es:AGROUP		; tell assembler
VMM_TERM_FREE_LOOP:
	 or	 esi, esi		; esi zero at end of free list
	 jz	 short VMM_TERM_FREE_LAST ; jump if at end

	 mov	 ebx, AGROUP:[esi].LFNaddr ; ebx <- base of free block
	 sub	 ebx, eax		; ebx <- size of free block in bytes
	 shr	 ebx, @BytePage 	; ebx <- size of free block in pages

	 or	 ebx, ebx		; test for non-zero
	 jz	 short @F		; skip if zero

	 call	 VMM_FREE		; else free it
@@:
	 mov	 eax, AGROUP:[esi].LFNaddr ; calc new block to free at end
	 mov	 ebx, AGROUP:[esi].LFNsize ;	of the free block
	 shl	 ebx, @BytePage 	; ebx <- size of block in bytes
	 add	 eax, ebx		; eax <- end of free block
	 mov	 esi, AGROUP:[esi].LFNnext ; chain to next free block

	 jmp	 VMM_TERM_FREE_LOOP	; go free the next block

VMM_TERM_FREE_LAST:			; here at end of free list
	 mov	 ebx, LinearClientTop	; free the end block (if any)
	 sub	 ebx, eax		; ebx <- size in bytes
	 shr	 ebx, @BytePage 	; ebx <- size in pags

	 or	 ebx, ebx		; non-zero?
	 jz	 short @F		; jump if not

	 call	 VMM_FREE		; free the pages
@@:
	 call	 LSM_RELEASE_NODE_ARRAY ; free the pages for the client's
					;    free list nodes array

; Now walk the page directory and free any lingering page tables

	 mov	 esi, LinearClientBottom; get base of client region
VMM_TERM_FREE_PDES:
	 cmp	 esi, LinearSystemBreak ; are we done yet ?
	 je	 short VMM_TERM_SWITCH_CR3 ; jump if so

	 mov	 edx, esi		; edx <- linear address
	 MakePDEaddress edx		; edx <- PDE address
	 mov	 ebx, AGROUP:[edx]	; ebx <- PDE

	 test	 ebx, @PG_PRESENT	; present?
	 jz	 short VMM_TERM_PDES_ADVANCE ; jump if not

	 cmp	 ebx, DefaultPDE	; default PDE?
	 je	 short VMM_TERM_PDES_ADVANCE	; jump if so

	 call	 PPM_FREE		; toss it
VMM_TERM_PDES_ADVANCE:
	 add	 esi, @FourMeg		; point to next 4meg area

	 jmp	 VMM_TERM_FREE_PDES	; go again

VMM_TERM_SWITCH_CR3:

; Change DTE_CR3 back to the previous value

	 mov	 ebx, LCL_CR3	; save current CR3 for free

;;;;;;; mov	ecx,PCURTSS    ; Get the offset in PGROUP of the current TSS
	push	PGROUP:[ecx].DPTSS_PLNKTSS ; Pass offset in PGROUP of incoming TSS
	 call	 DPMIFN_SWITCHADDR ; Switch to the incoming address space

	 call	 PPM_FREE	; free the old page dir (ebx is phys addr)
VMM_TERMINATE_EXIT:
;;;;;;; mov	ecx,PCURTSS    ; Get the offset in PGROUP of the current TSS

	test	PGROUP:[ecx].DPTSS_FLAG,mask $DPTSS_BSMINIT ; Izit initialized?
	jz	short @F	; Jump if not

	 dec	 VMMclientCount ; decrement the count of client
	jnz	short @F	; If it wasn't the last one, done

	 call	 VMM_SHUTDOWN	; otherwise, shut the whole thing down
@@:

; If this is the first DPMI client, clear the swapfile state
; to not present and zero total (the same as the initial state).

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 eax,PGROUP:[eax].DPTSS_PLNKTSS ; Get the back link to PCURTSS

	 cmp	 eax,PVMTSS	; Izit the 1st TSS?
	 jne	 short @F	; Jump if not

	 and	 VMM_FLAG,not @VMM_BSPRES ; Mark as not present
	 mov	 BSTotal,0	; Zero the swapfile
@@:
	 popf

	REGREST <fs,es,ds>	; Restore
	assume	ds:nothing,es:PGROUP,fs:nothing ; Tell the assembler about it
	popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_TERMINATE_CLIENT endp	; End VMM_TERMINATE_CLIENT procedure
	 NPPROC  VMM_SHUTDOWN - shut down the Virtual Memory Manager
	 assume  ds:IGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Shut down the VMM. Should only be called by VMM_TERMINATE_CLIENT when
all clients have terminated.

|
	 REGSAVE <eax, ebx, ecx, edx, esi, edi, ds, es> ; save registers

;; Don't shutdown if there are Resident Service Providers active

	 mov	 ax,DTE_DSJG	; get JGROUP data sel
	 mov	 es,ax		; load into es
	 assume  es:JGROUP	; Tell the assembler about it

	 cmp	 RSPhead,-1	; any RSPs?
	 jne	 short VMM_SHUTDOWN_EXIT ; jump if so

	 call	 PPM_SHUTDOWN	; close down the PPM
	 call	 BSM_SHUTDOWN	; close down the BSM

	 mov	 VMMcurrentClient, 0
	 and	 VMM_FLAG, not @VMM_SYSINIT ; Mark as uninitialized

	 push	 DTE_CR3		; want es=DTE_CR3
	 pop	 es			; es <- DTE_CR3
	 assume  es:nothing		; Tell the assembler about it
	 mov	 eax, DefaultPDE	; restore PDE for top of lin space
	 mov	 es:[@PageSize-4], eax	; set top
	 mov	 es:[@PageSize-8], eax	; set 2nd to top
	 mov	 es:[@PageSize-0ch], eax; set 3rd to top

;; Restore the PDEs for the shared memory region

	 mov	 ebx,LinearBottom	; ebx <- start of shared area
	 shr	 ebx,2+20		; divide by four meg
	 shl	 ebx,2			; mul by 4 to get PD offset
	 mov	 ecx,LinearClientBottom ; ecx <- end of shared area
	 shr	 ecx,2+20		; divide by four meg
	 shl	 ecx,2			; mul by 4 to get PD offset
@@:
	 mov	 es:[ebx],eax		; set to default PDE
	 add	 ebx,4			; point to next PDE
	 cmp	 ebx,ecx		; done?
	 jb	 short @B		; jump if not

	 mov	 BSActive, 0		; turn off page aging

VMM_SHUTDOWN_EXIT:
	 REGREST <es,ds,edi,esi,edx,ecx,ebx,eax> ; restore regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_SHUTDOWN endp		; End VMM_SHUTDOWN procedure
	 FPPROC  VMM_QUERY -- Query Virtual Memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Return the amount of linear committable memory.

On exit:

EDX	 =	 size of largest committable block in 1KB

|

	 REGSAVE <ecx,edi,ds,fs> ; Save registers

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 LSM_GET_CLIENT_LIST ; Returns list in FS:EDI

	 call	 LSM_QUERY	; Return in ECX the size of largest
				; available linear block in 4KB
	 mov	 edx,ecx	; Copy to reuse ECX

	 mov	 ecx,PhysicalTotal ; Get total # physical pages
	 call	 PPM_FILL_POOL	; Get pages from base memory manager
				; Return ECX = number of pages added to pool
				; (ignored)
	 mov	 ecx,PhysicalManaged ; Calculate PhysicalFree
	 sub	 ecx,PhysicalInUse ; ...

	 add	 ecx,BSTotal	; Plus BackFree
	 sub	 ecx,BSInUse	; ...

	 sub	 ecx,VirtualReserved ; Less reserved == available
	 jae	 short @F	; Jump if enough

	 xor	 ecx,ecx	; Call it zero
@@:

; The size of the largest committable block is the smaller of
; EDX (Largest contiguous address space) and ECX (# available
; committable pages)

	 UMIN	 edx,ecx	; Get the smaller into EDX

	 mov	 ecx,edx	; ecx <- # pages
	 shr	 ecx,22-12	; divide by pages/4MB
	 sub	 edx,ecx	; subtract from total to compensate for new
				; page tables

	 shl	 edx,12-10	; Convert from 4KB to 1KB

	 REGREST <fs,ds,edi,ecx> ; Restore
	 assume  ds:nothing,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_QUERY endp			; End VMM_QUERY procedure
	 NPPROC  VMM_MARK_CANDIDATES -- Mark Pages As Demand Paging Candidates
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Mark Pages As Demand Paging Candidates. When choosing a page to swap out,
pages so marked are preferred above all others.

On entry:

EAX	 =	 starting linear address (/4KB)
EBX	 =	 size in pages

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
AX	 =	 error code

|

	REGSAVE <eax, ebx, ecx, es>	; Save registers
	pushf				; save flags
	cli				; no interrupts, thank you
	mov	es, ISEL_4GB3		; AGROUP
	assume	es:AGROUP		; tell assembler

	cmp	eax, LinearBottom	; ignore anything below LinearBottom
	jb	VMM_MARKCAN_EXIT	; jump if below LinearBottom

	MakePTEaddress eax		; eax <- address of PTE


VMM_MARKCAN_NEXT:
	or	ebx,ebx 		; any pages left?
	jz	VMM_MARKCAN_EXIT	; jump if not

	SwitchOnPageType eax
	addressOf VMM_MARKCAN_ADVANCE	; unallocated
	addressOf VMM_MARKCAN_ADVANCE	; reserved
	addressOf VMM_MARKCAN_PRESENT	; present
	addressOf VMM_MARKCAN_ADVANCE	; swapped
	addressOf VMM_MARKCAN_ADVANCE	; reserved inaccessible
	addressOf VMM_MARKCAN_PRESENT	; inaccessible
	addressOf VMM_MARKCAN_ADVANCE	; swapped inaccessible
	addressOf VMM_MARKCAN_ADVANCE	; uncommitted
	addressOf VMM_MARKCAN_ADVANCE	; locked
	addressOf VMM_MARKCAN_ADVANCE	; locked inaccessible
	addressOf VMM_MARKCAN_ADVANCE	; mapped
	addressOf VMM_MARKCAN_PRESENT	; shared
	addressOf VMM_MARKCAN_ADVANCE	; locked shared
	addressOf VMM_MARKCAN_ADVANCE	; reserved shared
	addressOf VMM_MARKCAN_ADVANCE	; swapped shared
	addressOf VMM_MARKCAN_ADVANCE	; uncommitted PDE

VMM_MARKCAN_PRESENT:
	push	ebx			; save a moment
	mov	ebx, es:[eax]		; pick up PTE contents
	call	PPM_GET_PAGE_RECORD	; esi <- LA of PPR
	or	es:[esi].PPflags, mask $marked ; mark for swap out
	pop	ebx

VMM_MARKCAN_ADVANCE:
	 dec	 ebx			 ; dec count of pages left
	 add	 eax,4			 ; advance PTE address

	 jmp	 VMM_MARKCAN_NEXT

VMM_MARKCAN_EXIT:
	 popf				 ; maybe allow interrupts now

	 clc				 ; always succeeds

	 FlushTLB eax			 ; flush TLB after PDE/PTE modify

	 REGREST <es, ecx, ebx, eax>	 ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_MARK_CANDIDATES endp	; End VMM_MARK_CANDIDATES procedure
	 NPPROC  VMM_DISCARD_PAGES -- Mark Pages As Discardable
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Mark Pages As Discardable. This means that the page remains committed but
its contents may be discarded.	To implement this, we free the page and
increment the reserved count.

On entry:

EAX	 =	 starting linear address (/4KB)
EBX	 =	 size in pages

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
AX	 =	 error code

|

	 REGSAVE <eax, ebx, ecx, es>	 ; Save registers

	 pushf				 ; save flags
	 cli				 ; no interrupts, thank you

	 mov	 es, ISEL_4GB3		 ; AGROUP
	 assume  es:AGROUP		 ; tell assembler

	 cmp	 eax, LinearBottom	 ; ignore anything below LinearBottom
	 jb	 VMM_DISCARD_EXIT	 ; jump if below LinearBottom

	 MakePTEaddress eax		 ; eax <- address of PTE
VMM_DISCARD_NEXT:
	 or	 ebx,ebx		 ; any pages left?
	 jz	 VMM_DISCARD_EXIT	 ; jump if not

	SwitchOnPageType eax
	addressOf VMM_DISCARD_ADVANCE	; unallocated
	addressOf VMM_DISCARD_ADVANCE	; reserved
	addressOf VMM_DISCARD_PRESENT	; present
	addressOf VMM_DISCARD_SWAPPED	; swapped
	addressOf VMM_DISCARD_ADVANCE	; reserved inaccessible
	addressOf VMM_DISCARD_INACC	; inaccessible
	addressOf VMM_DISCARD_SWINACC	; swapped inaccessible
	addressOf VMM_DISCARD_ADVANCE	; uncommitted
	addressOf VMM_DISCARD_ADVANCE	; locked
	addressOf VMM_DISCARD_ADVANCE	; locked inaccessible
	addressOf VMM_DISCARD_ADVANCE	; mapped
	addressOf VMM_DISCARD_SHARED	; shared
	addressOf VMM_DISCARD_ADVANCE	; locked shared
	addressOf VMM_DISCARD_ADVANCE	; reserved shared
	addressOf VMM_DISCARD_SWSHARED	; swapped shared
	addressOf VMM_DISCARD_ADVANCE	; uncommitted PDE

VMM_DISCARD_SHARED:
	 mov	 ecx, @PGBITS_RESERVED_SHARED	 ; handle like present

	 jmp	 short @F		 ; continue

VMM_DISCARD_INACC:
	 mov	 ecx, @PGBITS_RESERVED_INACC	 ; handle like present

	 jmp	 short @F		 ; continue

VMM_DISCARD_PRESENT:
	 mov	 ecx, @PGBITS_RESERVED+@PG_READWRITE ; make it reserved
@@:
	 push	 ebx			 ; save a moment

	 mov	 ebx,es:[eax].PDT_PTE	 ; pick up PTE contents
	 call	 PPM_FREE		 ; throw it away

	 pop	 ebx			 ; restore

	 mov	 es:[eax].PDT_PTE,ecx	 ; set new pte
	 inc	 VirtualReserved	 ; reserve a committed page

	 jmp	 short VMM_DISCARD_ADVANCE ; continue

VMM_DISCARD_SWSHARED:
	 mov	 ecx, @PGBITS_RESERVED_SHARED	 ; handle like swapped

	 jmp	 short @F		 ; continue

VMM_DISCARD_SWINACC:
	 mov	 ecx, @PGBITS_RESERVED_INACC	 ; handle like swapped

	 jmp	 short @F		 ; continue

VMM_DISCARD_SWAPPED:
	 mov	 ecx, @PGBITS_RESERVED+@PG_READWRITE ; make it reserved
@@:
	 push	 eax

	 mov	 eax,es:[eax].PDT_PTE	 ; eax <- backing store address
	 shr	 eax,@BytePage		 ; shift out low bits
	 call	 BSM_FREE		 ; free the backing store page

	 pop	 eax			 ; restore

	 inc	 VirtualReserved	 ; reserve a committed page
	 mov	 es:[eax].PDT_PTE,ecx	 ; set pte
VMM_DISCARD_ADVANCE:
	 dec	 ebx			 ; dec count of pages left
	 add	 eax,4			 ; advance PTE address

	 jmp	 VMM_DISCARD_NEXT	 ; continue

VMM_DISCARD_EXIT:
	 popf				 ; maybe allow interrupts now

	 clc				 ; always succeeds

	 FlushTLB eax			 ; flush TLB after PDE/PTE modify

	 REGREST <es, ecx, ebx, eax>	 ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_DISCARD_PAGES endp		; End VMM_DISCARD_PAGES procedure
	 NPPROC  VMM_RELOCATE_BLOCK -- Relocate memory region
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Warning: Don't use this function to move a block to a *higher* address if
	 there is *overlap* between the areas spanned by the block in its
	 original and moved positions.

On entry:
	args on stack - see struc below

|
	vrb_FRAME struc
			dd	?	; saved ebp
			dw	?	; return ip
	vrb_src 	dd	?	; source linear address
	vrb_dest	dd	?	; destination linear address
	vrb_size	dd	?	; size to move, in pages
	vrb_FRAME ends

	push	ebp			; set up stack frame
	mov	ebp, esp		; address via stack
	REGSAVE <eax, ebx, ecx, edx, esi, edi, es> ; save registers

	mov	es, ISEL_4GB3		; es <- AGROUP (all memory)
	assume es:AGROUP		; tell assembler
VMM_RELOC_NEXT:
	cmp	[ebp].vrb_size, 0		;are we done?
	je	near ptr VMM_RELOC_DONE 	;jmp if no pages left to move

	mov	esi, [ebp].vrb_src		;esi <- src addr
	xor	ecx, ecx			;init repeat count in ecx

	mov	eax, [ebp].vrb_src		;eax <- src address
	MakePDEaddress eax			;eax <- PDE address for src

	test	es:[eax].PDT_PTE,@PG_PRESENT  ;test for present page table
	jnz	short @F			;jmp if present

	mov	edx, @PGBITS_UNCOMMITTED	;edx <- page type

	jmp	short VMM_RELOC_SCAN

@@:
	 mov	 eax, [ebp].vrb_src		 ;eax <- src address
	 MakePTEaddress eax			 ;eax <- PTE address for src
	 mov	 edx,es:[eax].PDT_PTE		 ;edx <- PTE contents
VMM_RELOC_SCAN:
	 mov	 eax, esi			 ;copy address
	 MakePDEaddress eax			 ;eax <- addr of PTE

	 cmp	 es:[eax].PDT_PTE,@PGBITS_UNCOMMITTED ;if !uncommitted PDE
	 jne	 short @F			 ;then jump

	 cmp	 edx, @PGBITS_UNCOMMITTED	 ;if not a match
	 jne	 short VMM_RELOC_MOVE		 ;break now and move mapping
						;else
	 mov	 ebx, esi			 ;ebx <- current src addr
	 and	 ebx, @FourMeg-1		 ;get low bits
	 sub	 ebx, @FourMeg			 ;ebx <- low bits - 4MB
	 neg	 ebx				 ;ebx <- 4MB-low bits = delta
						;  to next 4MB boundary
	 shr	 ebx, @BytePage 		 ;ebx <- page delta to next 4M
	 add	 ecx, ebx			 ;increment repeat counter
	 add	 esi, @FourMeg			 ;round up addr
	 and	 esi, not (@FourMeg-1)		 ; to next 4MB boundary

	 jmp	 short VMM_RELOC_ADVANCE

@@:						;here if not uncommitted PDE
	 mov	 eax, esi			 ;eax <- current src addr
	 MakePTEaddress eax			 ;eax <- addr of PTE for src

	 cmp	 es:[eax].PDT_PTE,edx		 ;check for a matching PTE
	 jne	 short VMM_RELOC_MOVE		 ;break if no match

	 inc	 ecx				 ;advance counter
	 add	 esi, @PageSize 		 ;advance source 1 page
VMM_RELOC_ADVANCE:
	 mov	 edi, [ebp].vrb_size		 ;edi <- size left
						;else fall thru
	 sub	 edi, ecx			 ;check for enough tested
	 ja	 short VMM_RELOC_SCAN		 ;jmp back for more if not
VMM_RELOC_MOVE:
	 cmp	 ecx, 1 			 ;single PTE run?
	 jne	 near ptr VMM_RELOC_GENERAL	 ;jump if not

	 mov	 eax, [ebp].vrb_dest		 ;eax <- current dest addr
	 MakePDEaddress eax			 ;eax <- addr of PDE for dest

	 cmp	 es:[eax].PDT_PTE,@PGBITS_UNCOMMITTED ;uncommitted PDE?
	 jne	 short @F			 ;jmp if not

	 mov	 eax, [ebp].vrb_dest		 ;eax <- current dest addr
	 call	 LSM_EXPAND_UNCOMPDE		 ;expand uncommitted PDE to
@@:
	 mov	 eax, [ebp].vrb_dest		 ;eax <- current dest addr
	 MakePTEaddress eax			 ;eax <- addr of PDE for dest

	 mov	 ebx, [ebp].vrb_src		 ;ebx <- src addr
	 MakePTEaddress ebx			 ;ebx <- addr of PTE for src

	 mov	 edx,es:[ebx].PDT_PTE		;edx <- src PTE
	 mov	 es:[eax].PDT_PTE,edx		;dest <- src PTE
						;treat physical pages special
	 and	 edx, @PG_TYPEMASK		 ;get page type

	 cmp	 edx, @PGBITS_PRESENT		 ;if present page
	 je	 short @F			 ;process it

	 cmp	 edx, @PGBITS_INACC		 ;if inaccessible page
	 je	 short @F			 ;process it

	 cmp	 edx, @PGBITS_SHARED		 ;if shared page
	 je	 short @F			 ;process it

	 test	 edx, @PG_LOCKED		 ;if any kind of locked page
	 jz	 short VMM_RELOC_ADVDEST	 ;else continue
@@:						 ;page is moving to new addr
	 mov	 ebx,es:[eax].PDT_PTE		 ;ebx <- physical addr (PTE)
	 mov	 eax,[ebp].vrb_dest		 ;eax <- new linear addr
	 call	 PPM_SET_PAGE_ADDRESS		 ;inform Phys Page Manager

VMM_RELOC_ADVDEST:
	 mov	 ebx, [ebp].vrb_src		 ;ebx <- src
	 call	 BSM_INVALIDATE_CACHE_ENTRY	 ;kill bsm cache entry at src

	 mov	 ebx, [ebp].vrb_dest		 ;ebx <- dest
	 call	 BSM_INVALIDATE_CACHE_ENTRY	 ;kill bsm cache entry at dest

	 add	 [ebp].vrb_dest, @PageSize	 ;advance destination

	 jmp	 short VMM_RELOC_MORE		 ;continue

VMM_RELOC_GENERAL:				;general case (multiple run)
	 mov	 eax, [ebp].vrb_dest		 ;eax <- linear address
	 mov	 ebx, ecx			 ;ebx <- page count
	 mov	 ecx, edx			 ;ecx <- PTE contents
	 call	 LSM_SETN_PTES			 ;set PTEs (and maybe PDEs too)

	 mov	 ecx, ebx			 ;ecx <- page count
	 shl	 ecx, @BytePage 		 ;convert size to bytes
	 add	 [ebp].vrb_dest, ecx		 ;advance destination
	 shr	 ecx, @BytePage 		 ;restore size to pages
VMM_RELOC_MORE:
	 mov	 [ebp].vrb_src, esi		 ;new source addr
	 sub	 [ebp].vrb_size, ecx		 ;new size remaining

	 jmp	 VMM_RELOC_NEXT

VMM_RELOC_DONE:
	 clc					 ;flag success

	 FlushTLB edx			 ; flush TLB after PDE/PTE modify

	 REGREST <es, edi, esi, edx, ecx, ebx, eax>; restore registers
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp				 ; restore base ptr

	 ret	 3*4				 ; return to caller, pop args

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_RELOCATE_BLOCK ENDP 	; end of VMM_RELOCATE_BLOCK procedure
	FPPROC FVMM_RELOCATE_BLOCK -- the far version of VMM_RELOCATE_BLOCK
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

fvrb_FRAME struc		; argument frame
		dd	?	; saved ebp
		dw	?	; return ip
		dw	?	; return cs
fvrb_src	dd	?	; source linear address
fvrb_dest	dd	?	; destination linear address
fvrb_size	dd	?	; size to move, in pages
fvrb_FRAME ends

	 push	 ebp		; Set up stack
	 mov	 ebp,esp

	 push	 [ebp].fvrb_size ; Pass size
	 push	 [ebp].fvrb_dest ; Pass destination address
	 push	 [ebp].fvrb_src  ; Pass source address
	 call	 VMM_RELOCATE_BLOCK ; Do it

	 pop	 ebp		; Restore base ptr

	 ret	 3*4		; return to caller popping args

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMM_RELOCATE_BLOCK endp	; End FVMM_RELOCATE_BLOCK procedure
	 NPPROC  VMM_MAPP2L -- Map Physical To Linear
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Supports DPMI function 800h - create physical to linear mapping.  This
routine, along with VMM_UNMAPP2L, maintains a database of all the
client's physical-to-linear maps, so that they can be re-used
appropriately.

The code works such that all mappings and related resources are
automatically released as part of the normal client termination
clean-up process.

On entry:

args on stack

On exit:
CF	=	0 success
EAX	=	linear address for mapping


CF	=	1 failed
|

VMM_P2Larg_STR struc
			dd	?	; saved ebp
			dw	?	; return ip
	P2Larg_phys	dd	?	; physical address to map
	P2Larg_size	dd	?	; number of *pages* to map
VMM_P2Larg_STR ends

	push	ebp		; save base pointer
	mov	ebp,esp 	; set up stack frame

	REGSAVE <ebx,ecx,edx,esi,ds,es> ; save registers

	mov	ds, SEL_DSIG3	; DS=IGROUP
	assume ds:IGROUP	; tell assembler

	mov	es, ISEL_4GB3	; ES=AGROUP
	assume es:AGROUP	; tell assembler

	mov	edx,PCURTSS		; pick up offset in PGROUP of TSS
	mov	ebx,PGROUP:[edx].DPTSS_VMM_P2LMapTable ; get map table LA

	or	ebx,ebx 	; has it been initialized?
	jnz	VMM_MAPP2L_SRCH ; yes - go search it

; We need to initialize the map table for this client. Just alloc a page
; and zero it out.

	xor	eax,eax 		; arg: any address ok
	mov	ebx,1			; arg: alloc 1 page
	 mov	 ecx,mask $commit	 ; get a committed page
	 call	 VMM_ALLOC		 ; do the allocation
	 jc	 VMM_MAPP2L_ERROR	 ; jump if couldn't get a page

	 call	 VMM_ZERO_PAGE		 ; zero out the page

	 mov	 PGROUP:[edx].DPTSS_VMM_P2LMapTable, eax ; save address in TSS
	 mov	 PGROUP:[edx].DPTSS_VMM_P2LMapSize, @PageSize ; save size in TSS

	 jmp	 VMM_MAPP2L_NEWMAP	 ; go add new mapping

VMM_MAPP2L_SRCH:			; ebx has table address

; Scan the table of physical-to-linear mappings, looking for a match to
; the current.

	 mov	 eax,PGROUP:[edx].DPTSS_VMM_P2LMapSize ; get size of map
	 add	 eax,ebx		 ; eax <- LA of end of map
VMM_MAPP2L_SRCHNEXT:
	 cmp	 ebx,eax		 ; are we at end of table?
	 jae	 VMM_MAPP2L_NEWMAP	 ; jump if so

	 mov	 ecx,AGROUP:[ebx].P2L_phys ; get physical address

	 cmp	 ecx,[ebp].P2Larg_phys	 ; does it match request?
	 jne	 short VMM_MAPP2L_SRCH_ADV ; jump if not

	 mov	 ecx,AGROUP:[ebx].P2L_size ; get size

	 cmp	 ecx,[ebp].P2Larg_size	 ; does it match request?
	 jne	 short VMM_MAPP2L_SRCH_ADV ; jump if not

; We have found an exact match of the request - return the linear address
; in eax.

	 inc	 AGROUP:[ebx].P2L_count  ; increment use count for mapping
	 mov	 eax,AGROUP:[ebx].P2L_lin ; get linear address

	 clc				 ; flag success

	 jmp	 VMM_MAPP2L_EXIT ; exit

VMM_MAPP2L_SRCH_ADV:
	 add	 ebx, size P2LMAP_STR	 ; point to next mapping record

	 jmp	 VMM_MAPP2L_SRCHNEXT	 ; go do next mapping record

VMM_MAPP2L_NEWMAP:

; There is no existing mapping to satisfy the request, so make a new one.
; First locate a free record in the mapping table (P2L_lin == 0).

	 mov	 ebx,PGROUP:[edx].DPTSS_VMM_P2LMapTable ; get addr of map
	 mov	 eax,PGROUP:[edx].DPTSS_VMM_P2LMapSize	 ; get size of map
	 add	 eax,ebx		 ; eax <- LA of end of map
VMM_MAPP2L_NEW_NEXT:
	 cmp	 ebx,eax		 ; are we at end of table?
	 jae	 VMM_MAPP2L_GROW_MAP	 ; jump if so

	 cmp	 AGROUP:[ebx].P2L_lin,0  ; is this record free?
	 je	 short VMM_MAPP2L_ADD_MAP ; jump if so

	 add	 ebx,size P2LMAP_STR	 ; point to next mapping record

	 jmp	 VMM_MAPP2L_NEW_NEXT	 ; check next one

VMM_MAPP2L_GROW_MAP:

; We searched the whole table and didn't find a free map, so we have to
; try to grow the table.

	 mov	 edx,PCURTSS		 ; pick up offset in PGROUP of TSS
	 mov	 eax,PGROUP:[edx].DPTSS_VMM_P2LMapSize	 ; get size of map
	 inc	 eax			 ; try to make it one page bigger

	 push	 dword ptr (mask $commit) ; arg: committed page
	 push	 eax			 ; arg: new size to allocate
	 dec	 eax			 ; get old size
	 push	 eax			 ; arg: old size
	 push	 PGROUP:[edx].DPTSS_VMM_P2LMapTable ; arg: address of block
	 call	 VMM_REALLOC		 ; try to grow it

	 or	 eax,eax		 ; did it grow?
	 jz	 near ptr VMM_MAPP2L_ERROR; jump if not

	 mov	 PGROUP:[edx].DPTSS_VMM_P2LMapTable, eax ; store new address
	 mov	 ecx,PGROUP:[edx].DPTSS_VMM_P2LMapSize ; get old size
	 shl	 ecx,@BytePage		 ; convert to bytes
	 add	 eax,ecx		 ; eax <- address of new page
	 call	 VMM_ZERO_PAGE		 ; zero out the new page

	 inc	 PGROUP:[edx].DPTSS_VMM_P2LMapSize ; update table size

	 mov	 ebx,PGROUP:[edx].DPTSS_VMM_P2LMapTable ; ebx <- table address

	 jmp	 VMM_MAPP2L_SRCH	 ; try again

VMM_MAPP2L_ADD_MAP:

; Found a free record in the table at ebx. Now set up the mapping.

	 mov	 esi,ebx		 ; copy table entry addr to esi
	 xor	 eax,eax		 ; arg: any old addr will do
	 mov	 ebx,[ebp].P2Larg_size	 ; arg: page count
	 mov	 edx,mask $commit	 ; commit the page tables
	 call	 LSM_ALLOC		 ; get linear space
	 jc	 short VMM_MAPP2L_ERROR  ; jump if failed

; Set the PTEs to uncommitted so that the mapper will know what to do.

	 mov	 ecx, @PGBITS_UNCOMMITTED ; value to set PTEs to
	 call	 LSM_SETN_PTES		 ; set the ptes

; We have the linear address in eax. Now set up the table entry.

	 mov	 AGROUP:[esi].P2L_lin, eax ; save linear address
	 mov	 ebx,[ebp].P2Larg_phys	 ; get physical address
	 mov	 AGROUP:[esi].P2L_phys,ebx ; save in table
	 mov	 ecx,[ebp].P2Larg_size	 ; get page count
	 mov	 AGROUP:[esi].P2L_size,ecx ; save in table
	 mov	 AGROUP:[esi].P2L_count,1 ; initialize use count

; Now do the mapping

	 push	 edx			 ; save
	 xor	 edx,edx		 ; flag arg: physical (not conv'nal)
	 call	 VMM_MAP_PHYSICAL	 ; do the mapping
	 pop	 edx			 ; restore
	 jc	 VMM_MAPP2L_ERROR	 ; jump if failed

; Fall thru with carry clear and linear address in eax

VMM_MAPP2L_EXIT:
	 REGREST <es,ds,esi,edx,ecx,ebx> ; Restore registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore base ptr

	 ret	 4*2		; Return to caller, pop args

VMM_MAPP2L_ERROR:
	 stc			; Some error occurred

	 jmp	 VMM_MAPP2L_EXIT ; exit

	 assume ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_MAPP2L endp 		; End VMM_MAPP2L procedure
	 NPPROC VMM_UNMAPP2L -- Undo physical to linear mapping
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Supports DPMI function 801h.

On entry

EAX	=	linear address to unmap

On exit:

CF	=	0 success
	=	1 failed
|

	REGSAVE <eax,ebx,ecx,edx,edi,ds,es>; save registers

	mov	edi,eax 		; copy address to edi

	mov	ds, SEL_DSIG3		; DS=IGROUP
	assume ds:IGROUP		; tell assembler

	mov	es, ISEL_4GB3		; ES=AGROUP
	assume es:AGROUP		; tell assembler

	mov	edx,PCURTSS		; pick up offset in PGROUP of TSS
	mov	ebx,PGROUP:[edx].DPTSS_VMM_P2LMapTable ; get map table LA
	or	ebx,ebx 		; initialized?
	jz	short VMM_UNMAPP2L_ERROR; no - that's an error

; Scan the table of physical-to-linear mappings, looking for a match to
; the request

	mov	eax,PGROUP:[edx].DPTSS_VMM_P2LMapSize ; get size of map
	add	eax,ebx 		; eax <- LA of end of map

VMM_UNMAPP2L_SRCHNEXT:
	cmp	ebx,eax 		; are we at end of table?
	jae	VMM_UNMAPP2L_ERROR	; jump if didn't find a match

	cmp	edi,AGROUP:[ebx].P2L_lin ; match?
	jne	short VMM_UNMAPP2L_SRCH_ADV ; jump if not

; We have found a match of the request - clear the record and free
; the linear space.

	dec	AGROUP:[ebx].P2L_count	; dec use count for mapping
	jnz	short VMM_UNMAPP2L_EXITOK; done if no more users

	mov	AGROUP:[ebx].P2L_lin, 0 ; mark record as free
	mov	AGROUP:[ebx].P2L_phys,0 ; clean for good measure
	mov	eax,edi 		; arg: address to free
	mov	ebx,AGROUP:[ebx].P2L_size ; arg: number of pages to free
	mov	ecx,1			; arg: free the page tables, too
	call	LSM_FREE		; free the linear space

VMM_UNMAPP2L_EXITOK:
	clc				; flag success
	jmp	VMM_UNMAPP2L_EXIT	; exit

VMM_UNMAPP2L_SRCH_ADV:
	add	ebx, size P2LMAP_STR	; point to next mapping record
	jmp	VMM_UNMAPP2L_SRCHNEXT	; check next map record

VMM_UNMAPP2L_EXIT:
	 REGREST <es,ds,edi,edx,ecx,ebx,eax>; restore registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret				 ; return to caller

VMM_UNMAPP2L_ERROR:
	 stc				 ; flag error

	 jmp	 VMM_UNMAPP2L_EXIT	 ; exit

	 assume ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_UNMAPP2L	endp			; end of VMM_UNMAPP2L procedure
	 align	 4

ICODE	 ends
endif
	 MEND
