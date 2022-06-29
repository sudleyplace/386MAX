;' $Header:   P:/PVCS/MAX/INC/CPUFET.INV   1.2   30 May 1997 11:15:56   BOB  $
;
; (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.
;
; CPUFET.INC
;
; CPU feature bits
;
; The following record maps the CPU feature bits for CPUs which
; support the CPUID instruction.

if (@Cpu and 1000b)		; If 80386 instructions
.xcref CPUFET_REC
CPUFET_REC record $CPUFET_INVD:1,   \
		  $CPUFET_INTEL:1,  \
		  $CPUFET_RSV2:6,   \
		  $CPUFET_MMX:1,    \
		  $CPUFET_RSV1:7,   \
		  $CPUFET_CMOV:1,   \
		  $CPUFET_MCA:1,    \
		  $CPUFET_PGE:1,    \
		  $CPUFET_MTRR:1,   \
		  $CPUFET_RSV0:2,   \
		  $CPUFET_APIC:1,   \
		  $CPUFET_CMP8B:1,  \
		  $CPUFET_MCE:1,    \
		  $CPUFET_PAE:1,    \
		  $CPUFET_MSREG:1,  \
		  $CPUFET_TSCNT:1,  \
		  $CPUFET_4MBPG:1,  \
		  $CPUFET_IOBRK:1,  \
		  $CPUFET_VME:1, \
		  $CPUFET_NDPIN:1

.xcref @CPUFET_LOCAL, @CPUFET_INVD, @CPUFET_INTEL, @CPUFET_MMX, @CPUFET_CMOV
.xcref @CPUFET_MCA, @CPUFET_PGE, @CPUFET_MTRR
.xcref @CPUFET_APIC, @CPUFET_CMP8B, @CPUFET_MCE
.xcref @CPUFET_PAE, @CPUFET_MSREG, @CPUFET_TSCNT
.xcref @CPUFET_4MBPG, @CPUFET_PSE, @CPUFET_IOBRK, @CPUFET_VME, @CPUFET_NDPIN

; @CPUFET_LOCAL contains local flags not defined by Pentium; append
; to this list any new flags in the same category.

@CPUFET_LOCAL  equ  ((mask $CPUFET_INVD) or (mask $CPUFET_INTEL))

@CPUFET_INVD   equ  mask $CPUFET_INVD	; 80000000: INVD/WBINVD supported
@CPUFET_INTEL  equ  mask $CPUFET_INTEL	; 40000000: GenuineIntel CPU
;;;;;;;_RSV2   equ  mask $CPUFET_RSV2	; 3F000000: (Reserved)
@CPUFET_MMX    equ  mask $CPUFET_MMX	; 00800000: MMX technology supported
;;;;;;;_RSV1   equ  mask $CPUFET_RSV1	; 007F0000: (Reserved)
@CPUFET_CMOV   equ  mask $CPUFET_CMOV	; 00008000: Conditional move supported
@CPUFET_MCA    equ  mask $CPUFET_MCA	; 00004000: Machine Check Architecture
@CPUFET_PGE    equ  mask $CPUFET_PGE	; 00002000: Global PTE bit (avoids TLB flush)
@CPUFET_MTRR   equ  mask $CPUFET_MTRR	; 00001000: Memory Type Range Register MSRs
;;;;;;;_RSV0   equ  mask $CPUFET_RSV0	; 00000C00: (Reserved)
@CPUFET_APIC   equ  mask $CPUFET_APIC	; 00000200: On-chip APIC supported
@CPUFET_CMP8B  equ  mask $CPUFET_CMP8B	; 00000100: CMPXCHG8B
@CPUFET_MCE    equ  mask $CPUFET_MCE	; 00000080: Machine Check Exception
@CPUFET_PAE    equ  mask $CPUFET_PAE	; 00000040: Physical Address Extensions
@CPUFET_MSREG  equ  mask $CPUFET_MSREG	; 00000020: Model-specific registers ...
@CPUFET_TSCNT  equ  mask $CPUFET_TSCNT	; 00000010: Time Stamp counter ...
@CPUFET_4MBPG  equ  mask $CPUFET_4MBPG	; 00000008: 4MB page ...
@CPUFET_PSE    equ  @CPUFET_4MBPG	;	    Page Size Extensions
@CPUFET_IOBRK  equ  mask $CPUFET_IOBRK	; 00000004: I/O breakpoint ...
@CPUFET_VME    equ  mask $CPUFET_VME	; 00000002: V86 mode extensions ...
@CPUFET_NDPIN  equ  mask $CPUFET_NDPIN	; 00000001: NDP installed (not necessarily on chip
					; as the Pentium bit defines)
endif				; IF (@Cpu AND 1000b)

