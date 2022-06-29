;' $Header:   P:/PVCS/MAX/386MAX/QMAX_VMM.INV   1.0   11 Aug 1995 10:55:54   HENRY  $
;
; (C) Copyright 1992-3 Qualitas, Inc.  All rights reserved.
;
; QMAX_VMM.INC
;
; Virtual Memory equates and structures
;

;;----------------------------------------------------------------------
;; Virtual Memory Manager
;;

;; Page types for DPMI virtual memory manager

@PGTYPE_UNALLOC 	equ	0
@PGTYPE_RESERVED	equ	1
@PGTYPE_PRESENT 	equ	2
@PGTYPE_SWAPPED 	equ	3
@PGTYPE_RESERVED_INACC	equ	4
@PGTYPE_INACC		equ	5
@PGTYPE_SWAPPED_INACC	equ	6
@PGTYPE_UNCOMMITTED	equ	7
@PGTYPE_UNCOMMITTEDR	equ	7
@PGTYPE_LOCKED		equ	8
@PGTYPE_LOCKED_INACC	equ	9
@PGTYPE_MAPPED		equ	0ah
@PGTYPE_SHARED		equ	0bh
@PGTYPE_LOCKED_SHARED	equ	0ch
@PGTYPE_RESERVED_SHARED equ	0dh
@PGTYPE_SWAPPED_SHARED	equ	0eh
@PGTYPE_PDE_UNCOMMITTED equ	0fh

;; PTE attribute bits

@PG_PRESENT		equ	000000000001b	; 001h
@PG_READWRITE		equ	000000000010b	; 002h
@PG_USERSUPER		equ	000000000100b	; 004h
@PG_INACCESS		equ	000000001000b	; 008h == Write Thru
@PG_MAPPED		equ	000000010000b	; 010h == Cache Disable
@PG_ACCESSED		equ	000000100000b	; 020h
@PG_DIRTY		equ	000001000000b	; 040h
@PG_RESERVED		equ	000010000000b	; 080h
@PG_SWAPPED		equ	000100000000b	; 100h
@PG_LOCKED		equ	001000000000b	; 200h
@PG_UNCOMMITTED 	equ	010000000000b	; 400h
@PG_SHARED		equ	100000000000b	; 800h
@PG_TYPEMASK		equ	111110011101b	; F9Dh

;; Valid PTE attribute combinations

@PGBITS_UNALLOC 	equ	0
@PGBITS_RESERVED	equ	@PG_RESERVED
@PGBITS_PRESENT 	equ	@PG_PRESENT + @PG_USERSUPER
@PGBITS_SWAPPED 	equ	@PG_SWAPPED
@PGBITS_INACC		equ	@PG_INACCESS
@PGBITS_RESERVED_INACC	equ	@PG_INACCESS + @PG_RESERVED
@PGBITS_SWAPPED_INACC	equ	@PG_INACCESS + @PG_SWAPPED
@PGBITS_LOCKED_INACC	equ	@PG_INACCESS + @PG_LOCKED
@PGBITS_UNCOMMITTED	equ	@PG_UNCOMMITTED + @PG_READWRITE
@PGBITS_LOCKED		equ	@PGBITS_PRESENT + @PG_LOCKED
@PGBITS_MAPPED		equ	@PGBITS_PRESENT + @PG_MAPPED + @PG_INACCESS
@PGBITS_SHARED		equ	@PGBITS_PRESENT + @PG_SHARED
@PGBITS_LOCKED_SHARED	equ	@PGBITS_PRESENT + @PG_LOCKED + @PG_SHARED
@PGBITS_RESERVED_SHARED equ	@PG_SHARED + @PG_RESERVED
@PGBITS_SWAPPED_SHARED	equ	@PG_SHARED + @PG_SWAPPED

@PGBITS_UNCOMMITTEDR	equ	@PG_UNCOMMITTED


@PageSize		equ	4096	; bytes per page
@BytePage		equ	12	; shift for byte->page, page->byte

MakePTEaddress	MACRO va
	shr	va, 10
	or	va, @PTBase
	and	va, not 3
	ENDM

MakePDEaddress	MACRO va
	shr	va, 20
	or	va, @PTBase + (@PTBase shr 10)
	and	va, not 3
	ENDM

@PTBase 			equ	0ffc00000h
@AccessBitOrd			equ	5


;; Error codes

@DERR_INSUFF_LINEAR	equ	8012h
@DERR_INSUFF_PHYS	equ	8013h
@DERR_INSUFF_BACK	equ	8014h
@DERR_INVAL_LINEAR	equ	8025h
@DERR_BADSTATE		equ	8002h
@DERR_CTRLBREAK_SWP	equ	80ffh	; Ctrl-Break during swapfile init


;; Used by Get and Set attribute calls

GetSetAttrWord	RECORD	$attrResv:9,	\
			$attrDirty:1,	\
			$attrAccess:1,	\
			$attrAvail:1,	\
			$attrR_W:1,	\
			$attrType:3

@attrUncommitted	equ	0
@attrCommitted		equ	1
@attrMapped		equ	2
@attrInaccessible	equ	5

ALLOC_FLAGS	record	$commit:1, $shared:1, $failIsFatal:1, $canSwap:1


;; Get Memory Information (50Bh) structure

MemInfo struc
	MI_physical		dd	?
	MI_virtual		dd	?
	MI_available		dd	?
	MI_virtualVM		dd	?
	MI_availableVM		dd	?
	MI_virtualClient	dd	?
	MI_availableClient	dd	?
	MI_lockedClient 	dd	?
	MI_maxLockedClient	dd	?
	MI_highAddr		dd	?
	MI_largestFree		dd	?
	MI_minAlloc		dd	?
	MI_allocAlign		dd	?
	MI_reserved		dd	4Ch/4 dup (?)
MemInfo ends

;; Shared Memory request structure (used by clients, function 0D00h)

SharedMemReq	struc
	SMR_reqSize		dd	?	; requested size
	SMR_actSize		dd	?	; actual size
	SMR_handle		dd	?	; shared memory handle
	SMR_address		dd	?	; linear address
	SMR_name		df	?	; ptr to asciiz name
	SMR_reserved		dw 3 dup (?)	; reserved
SharedMemReq	ends

;; SharedMemHandle structures

SMClientInfo struc	; client information tracking structure
	smci_client	dw	?	; TSS selector of client
	smci_uses	dw	?	; allocation count by client
	smci_shares	dw	?	; shared serialization count by client
	smci_excl	dw	?	; exclusive ser'tion count by client
SMClientInfo ends

SharedMemHandle struc	; per shared memory block
	SMH_la		dd	?	; base linear address
	SMH_length	dd	?	; size in bytes
	SMH_name	db 128 dup (?)	; the asciiz name of the block
	SMH_cinfo	db (size SMClientInfo)*@TSS_MAX dup (?) ; client information
SharedMemHandle ends

;; Shared memory states

@SMEM_FREE		equ	1	; not serialized
@SMEM_SHARED		equ	2	; shared serialized
@SMEM_EXCLUSIVE 	equ	3	; exclusive serialized


;; Resident Service Provider struc

RSPdata struc
	RSP_flags	db	?	; see RSPbits record below
	RSP_usecount	db	?	; current number of users
	RSP_next	dw	?	; link to next RSP
	RSP_prev	dw	?	; link to previous RSP
	RSP_code32	dq	?	; 32-bit code descriptor
	RSP_data32	dq	?	; 32-bit data descriptor
	RSP_code16	dq	?	; 16-bit code descriptor
	RSP_data16	dq	?	; 16-bit data descriptor
	RSP_cb32	dd	?	; 32-bit callback entry offset
	RSP_cb16	dw	?	; 16-bit callback entry offset
	RSP_selectors	dw @TSS_MAX dup (?) ; base selector per client
	RSP_regions	dd 4 dup (?,?)	; (base,pagecount) pairs for shared
					; memory regions used by RSP
RSPdata ends

@MAX_RSPS	equ	8		; maximum number of RSPs

RSPbits record	$RSPdefined:1,$RSP1stTerm:1

; Field 		Meaning when set
;----------------------------------------
; $RSPdefined		RSP defined, structure in use
; $RSP1stTerm		New RSP, do not call when terminating


; Physical to Linear Mapping support

P2LMAP_STR struc
	P2L_lin 	dd	?	; linear address
	P2L_phys	dd	?	; physical address
	P2L_size	dd	?	; size in pages
	P2L_count	dd	?	; use count for mapping
P2LMAP_STR ends

;;----------------------------------------------------------------------
;; Physical Page Manager structures

;; PhysicalRegion
;;
;;	This structure is in the general case to support machines that
;;	have discontiguous physical memory.  The array of PhysicalRegions
;;	form a description of the physical memory layout of the machine,
;;	enabling fast lookup of a PhysicalPageRecord for a given physical
;;	address.

PhysicalRegion	struc
	PRbase		dd	?	; base physical address of region
	PRsize		dd	?	; size of region (pages)
	PRtable 	dd	?	; linear address of
					;	PhysicalPageRecords for this
					;	region
PhysicalRegion	ends

;; PhysicalPageRecord
;;
;;	This structure tracks information for a physical page.	The
;;	PhysicalPageRecords are indexable by physical addresss for a
;;	particular PhysicalRegion.

	PPbits RECORD	 $marked:1, $managed:1, $alloced:1, $swappable:1

PhysicalPageRecord	struc
	PPflags 	db	?	; flags (see above)
	PPlocks 	db	?	; page lock count
	PPusage 	dw	?	; timestamp
	PPaddr		dd	?	; current virtual address, or, if page
					;   is free (alloced=0) free list link
	PPlowAddr	dd	?	; the primary allocator's address for
					;   this page. Used for freeing, and
					;   swapping
PhysicalPageRecord	ends


$clientMask	equ	0fffh		; mask for client id in PPaddr

@MAXREGIONS	equ	8		; Maximum # regions of discontiguous RAM

@FourMeg	equ	400000h


;;----------------------------------------------------------------------
;; Linear Space Manager structures
;;
FreeBits	record	$needToMerge:1	; true if need to merge list

FreeList struc
	FreeNodes	dd	?	; pointer to base of nodes array
	FreeHighNode	dd	?	; address of highest committed node
	FreeHead	dd	?	; list head
	FreeFlags	dd	?	; flags (none currently defined)
FreeList ends

if size FreeList-10h
	.err
	%out Fix size of DPTSS_VMM_FREELIST in QMAX_TSS.INC
endif


LFNbits 	record	$nodeInUse:1	; true if node active

LinearFreeNode struc
	LFNaddr 	dd	?	; virtual address of free block
	LFNsize 	dd	?	; size of free block in pages
	LFNnext 	dd	?	; link to next node in free list
	LFNflags	dd	?	; node status bits (LFNbits)
LinearFreeNode ends

@SharedSize	equ	1000000h	; size of shared region (bytes)

; Record for DPTSS_VMM_Flags field (see qmax_tss.inc)

vciBits RECORD	$vciInit:1,		\
		$vciBufferSaved:1,	\
		$vciRSP_registered:1,	\
		$vciRSP_isResident:1

; Record and equates for VMM_FLAG

VMMFL_REC record $VMM_BSTEMP:1,  \
		 $VMM_BSPRES:1, \
		 $VMM_BSCLOSE:1, \
		 $VMM_SYSINIT:1, \
		 $VMM_BSGLOBAL:1, \
		 $VMM_MUSTDRAIN:1, \
		 $VMM_VCPIACTIV:1, \
		 $VMM_CTRLBREAK:1

@VMM_BSTEMP   equ   mask $VMM_BSTEMP	; Swap file is temporary
@VMM_BSPRES   equ   mask $VMM_BSPRES	; Swap file is present
@VMM_BSCLOSE  equ   mask $VMM_BSCLOSE	; Swap file is closing
@VMM_SYSINIT  equ   mask $VMM_SYSINIT	; VMM system is initialized
@VMM_BSGLOBAL equ   mask $VMM_BSGLOBAL	; Swap file is global (if BSPRES=0, inactive)
@VMM_MUSTDRAIN equ  mask $VMM_MUSTDRAIN ; VMM needs to be drained
@VMM_VCPIACTIV equ  mask $VMM_VCPIACTIV ; VCPI client is active (their GDT)
@VMM_CTRLBREAK equ  mask $VMM_CTRLBREAK ; Ctrl-Break pressed during page I/O

PPMwasInited	equ	0001h	; flag for tracking initialization progress
BSMwasInited	equ	0002h	; ...
LSMwasInited	equ	0004h	; ...

