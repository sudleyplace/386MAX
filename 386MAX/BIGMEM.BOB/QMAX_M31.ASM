;' $Header:   P:/PVCS/MAX/386MAX/QMAX_M31.ASV   1.2   30 May 1997 10:45:32   BOB  $
	 title	 QMAX_M31 -- 386MAX INT 31h Miscellaneous Routines
	 page	 58,122
	 name	 QMAX_M31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-2003 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment LCODZ, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Data    segment IDATZ, dword-aligned, public, class 'idata'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'

Program derived from:  None.

Original code by:  Bob Smith, June 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include MAC.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC
	 include MASM5.MAC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAXDPMI.INC
	 include QMAX_DYN.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 CODE,ECODE,EDATA
IGROUP	 group	 LDATA,LCODZ,ICODE,IDATA,IDATZ
XGROUP	 group	 XCODE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_VIRTUALMEM
	 extrn	 SEL_DSIG3:word
	 extrn	 VMM_FLAG:word
endif				; IF @OEM_VIRTUALMEM

	 extrn	 I31_FLAG:word
	 extrn	 DPM_FLAG:word
	 extrn	 CON4KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 SEL_4GB3:word
	 extrn	 PDPMILDT:dword
	 extrn	 PCURTSS:dword
	 extrn	 VM2PM_TSS:word
	 extrn	 LDT_SIZ:dword
	 extrn	 PRGBASE:dword
	 extrn	 IGRBASE:dword
	 extrn	 IGRSIZE:dword
	 extrn	 DPMIHNDL_CNT:dword
	 extrn	 DPMIHNDL_OFF:dword
	 extrn	 DPMIPDIR_CNT:dword
	 extrn	 DPMIPDIR_OFF:dword
	 extrn	 LaDPMIPDIR:dword
	 extrn	 DPMIDYN_SIZ:dword

	 extrn	 LAST_DPMI_DS:word
	 extrn	 LAST_DPMI_ES:word
	 extrn	 LAST_DPMI_FS:word
	 extrn	 LAST_DPMI_GS:word

	 extrn	 DPMI_DATA:word
	 extrn	 DPMI_CPL:byte

	 extrn	 LPMSTK_FVEC:fword
	 extrn	 LPMSTK_CNT:dword

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FSET_GDT:far
	 extrn	 FALLOCMEM:far
	 extrn	 FDEALLOCMEM:far

ECODE	 ends			; End ECODE segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


LCODZ	 segment use16 dword public 'icode' ; Start LCODZ segment
	 assume  ds:IGROUP

	 extrn	 LCODE_NXT:dword

LCODZ	 ends			; End LCODZ segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 @BSCSize:abs
	 extrn	 PBScache:dword
endif				; IF @OEM_VIRTUALMEM

IDATA	 ends			; End IDATA segment


IDATZ	 segment use16 dword public 'idata' ; Start IDATZ segment
	 assume  ds:IGROUP

	 public  IDATA_NXT
IDATA_NXT label  dword		; Next available byte in IGROUP

IDATZ	 ends			; End IDATZ segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 public  @QMAX_M31_ICODE
@QMAX_M31_ICODE:		; Mark module start in .MAP file

	 extrn	VMM_LOCK:near

	 NPPROC  DPMIFN_ZEROSEL -- Zero Matching Selectors
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If this selector matches one of the active selectors, zero that one

On entry:

BX	 =	 selector to check

|

	 REGSAVE <ax>		; Save register

	 cmp	 bx,[ebp-@I31BACK].I31_DS ; Izit same as caller's DS?
	 jne	 short @F	; Jump if not

	 mov	 [ebp-@I31BACK].I31_DS,0 ; Zero it
@@:
	 cmp	 bx,[ebp-@I31BACK].I31_ES ; Izit same as caller's ES?
	 jne	 short @F	; Jump if not

	 mov	 [ebp-@I31BACK].I31_ES,0 ; Zero it
@@:
	 mov	 ax,fs		; Get caller's FS

	 cmp	 bx,ax		; Izit same as caller's FS?
	 jne	 short @F	; Jump if not

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Zero it
	 assume  fs:nothing	; Tell the assembler about it
@@:
	 mov	 ax,gs		; Get caller's GS

	 cmp	 bx,ax		; Izit same as caller's GS?
	 jne	 short @F	; Jump if not

	 xor	 ax,ax		; A convenient zero
	 mov	 gs,ax		; Zero it
	 assume  gs:nothing	; Tell the assembler about it
@@:

; Check LAST_DPMI_xS values and zero them if there's a match

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 bx,LAST_DPMI_DS ; Izit same as last DS?
	 jne	 short @F	; Jump if not

	 mov	 LAST_DPMI_DS,0 ; Zero it
@@:
	 cmp	 bx,LAST_DPMI_ES ; Izit same as last ES?
	 jne	 short @F	; Jump if not

	 mov	 LAST_DPMI_ES,0 ; Zero it
@@:
	 cmp	 bx,LAST_DPMI_FS ; Izit same as last FS?
	 jne	 short @F	; Jump if not

	 mov	 LAST_DPMI_FS,0 ; Zero it
@@:
	 cmp	 bx,LAST_DPMI_GS ; Izit same as last GS?
	 jne	 short @F	; Jump if not

	 mov	 LAST_DPMI_GS,0 ; Zero it
@@:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_ZEROSEL endp		; End DPMIFN_ZEROSEL procedure
	 FPPROC  FDPMIFN_BITMAP_SIZ -- Calculate Byte Size of DPMI LDT Bitmap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DPMIFN_BITMAP_SIZ

On entry:

Same as for DPMIFN_BITMAP_SIZ

On exit:

Same as for DPMIFN_BITMAP_SIZ

|

	 call	 DPMIFN_BITMAP_SIZ ; Return with EBX = byte size of DPMI LDT (/8)
				; bitmap using LDT_SIZ of EAX
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMIFN_BITMAP_SIZ endp 	; End FDPMIFN_BITMAP_SIZ procedure
	 NPPROC  DPMIFN_BITMAP_SIZ -- Calculate Byte Size of DPMI LDT Bitmap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the byte size of the DPMI LDT bitmap

On entry:

EAX	 =	 LDT_SIZ (/8)

On exit:

EBX	 =	 byte size of DPMI LDT bitmap (/8)

|

	 mov	 ebx,eax	; Copy to calculate size of bitmap
	 shr	 ebx,3-0	; Convert from bytes to qwords (# LDTEs)
	 add	 ebx,8*8-1	; Round up to next qword of bits
	 and	 ebx,not (8*8-1) ; ...
	 shr	 ebx,3-0	; Convert from bits to bytes

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_BITMAP_SIZ endp		; End DPMIFN_BITMAP_SIZ procedure
	 FPPROC  FDPMIFN_XLDT_SIZ -- Calculate Byte Size of Extended LDT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DPMIFN_XLDT_SIZ

On entry:

Same as for DPMIFN_XLDT_SIZ

On exit:

Same as for DPMIFN_XLDT_SIZ

|

	 call	 DPMIFN_XLDT_SIZ ; Return with EBX = byte size of extended LDT
				; using LDT_SIZ of EAX
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMIFN_XLDT_SIZ endp		 ; End FDPMIFN_XLDT_SIZ procedure
	 NPPROC  DPMIFN_XLDT_SIZ -- Calculate Byte Size of Extended LDT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the byte size of the extended LDT

On entry:

EAX	 =	 LDT_SIZ (/8)

On exit:

EBX	 =	 XLDT_SIZ (/@DPMI_BOUND)

|

	 call	 DPMIFN_BITMAP_SIZ ; Return with EBX = byte size of DPMI LDT (/8)
				; bitmap using LDT_SIZ of EAX
	 add	 ebx,eax	; Add to get size of extended LDT
	 add	 ebx,@DPMI_BOUND-1 ; Round up to next
	 and	 ebx,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_XLDT_SIZ endp		; End DPMIFN_XLDT_SIZ procedure
	 NPPROC  DPMIFN_GROWLDT -- Attempt To Grow The LDT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to grow the LDT.

On entry:

IF	 =	 0 (interrupts disabled)

On exit:

CF	 =	 0 if we succeeded
	 =	 1 if we didn't

|

GROWLDT_LOCALS	struc
	old_LA		dd	?
	old_size	dd	?
	do_free 	dw	?
GROWLDT_LOCALS	ends

	 push	 es		; Save selector

	 pushad 		; Save all EGP registers

	 sub	 esp, size GROWLDT_LOCALS ; alloc some scratch space
	 mov	 ebp, esp
	 mov	 [ebp].do_free, 0; init free-old-ldt flag to "no"

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 mov	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 call	 DPMIFN_XLDT_SIZ ; Return with EBX = byte size of extended LDT
				; using LDT_SIZ of EAX
	 mov	 ecx,ebx	; Save current byte size of extended LDT
				; Note that this value may be larger than
				; we need because it has been rounded up to
				; be a multiple of @DPMI_BOUND.
COMMENT|

In the following calculations we use the magic number 504 which
is the largest # LDTEs which fit into a @DPMI_BOUND size page
including room for the trailing bitmap.  The calculations are
as follows:

504 LDTEs = 504*8*8 bits
	  = 32,256  bits
	  +    504  bits for the bitmap
	  = 32,760  bits
	  =  4,095  bytes
|

@NLDTE_GROW equ  504

; Round up the current # LDTEs to the next multiple of @NLDTE_GROW.
; If the size of the extended LDT is larger, allocate more memory.
; If it's not larger, then the extra LDTEs fit into the current space.

	 push	 edx		; Save for a moment

;;;;;;;; mov	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 add	 eax,@NLDTE_GROW*(type DESC_STR)-1 ; Round up to next multiple
	 xor	 edx,edx	; Zero to use EDX:EAX as a qword
	 mov	 ebx,@NLDTE_GROW*(type DESC_STR) ; Get divisor
	 div	 ebx		; Return with quotient in EAX
	 mul	 ebx		; Multiply to get next multiple of @NLDTE_GROW

	 pop	 edx		; Restore

; Because the LDT_SIZ cannot exceed 64KB, enforce that now

	 cmp	 eax,CON64KB	; Izit too big for an LDT?
	 jbe	 short @F	; Jump if not

	 mov	 eax,CON64KB	; Use maximum LDT size
@@:
	 call	 DPMIFN_XLDT_SIZ ; Return with EBX = byte size of extended
				; DPMI LDT using LDT_SIZ of EAX

	 cmp	 ebx,ecx	; Izit the same extended size?
	 jne	 short DPMIFN_GROWLDT1 ; Jump if not

	 cmp	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Izit the same size?
	 ja	 near ptr DPMIFN_GROWLDT2 ; Jump if not (new LDT_SIZ in EAX
				; fits into the existing region)

	 add	 eax,@NLDTE_GROW*(type DESC_STR) ; Add in another page

; Because the LDT_SIZ cannot exceed 64KB, enforce that now

	 cmp	 eax,CON64KB	; Izit too big for an LDT?
	 jbe	 short @F	; Jump if not

	 mov	 eax,CON64KB	; Use maximum LDT size
@@:

; If the new LDT size is no larger than the old one, we're hosed
; because we need more selectors than the LDT can hold

	 cmp	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Izit the same size?
	 je	 near ptr DPMIFN_GROWLDT_ERR ; Jump if so

	 call	 DPMIFN_XLDT_SIZ ; Return with EBX = byte size of extended
				; DPMI LDT using LDT_SIZ of EAX
DPMIFN_GROWLDT1:

; No room in the same LDT:  look for more memory elsewhere

; Allocate memory for our extended LDT
; and save its address in the new DPTSS_STR

	 mov	 edi, ebx	; copy size to edi
	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 ebx		; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr DPMIFN_GROWLDT_ERR ; Jump if no memory found

	 mov	 [ebp].do_free, 1; set free-old-ldt flag to "yes"

if @OEM_VIRTUALMEM

; Lock down the memory

	 push	 eax		; Save for a moment
	 push	 ebx		; Save for a moment
	 push	 ds
	 mov	 ds, SEL_DSIG3	; set up DS with IGROUP
	 assume  ds:IGROUP

	 mov	 eax, ebx	; eax <- linear address
	 mov	 ebx, edi	; ebx <- size in bytes
	 add	 ebx, @PageSize-1 ; start convert to page
	 shr	 ebx, @BytePage ; convert to pages
	 call	 VMM_LOCK	; lock it down
	 pop	 ds		; restore registers
	 assume  ds:PGROUP
	 pop	 ebx
	 pop	 eax
	 jc	 near ptr DPMIFN_GROWLDT_ERR ; Jump if no memory found
endif
	 mov	 edi,PGROUP:[edx].DPTSS_LaLDT	; save old values in scratch
	 mov	 [ebp].old_LA,edi		;    for delete later
	 mov	 [ebp].old_size,ecx


; Copy contents of old LDT to new location

	 mov	 edi,ebx	; Copy new linear (destin) address
	 xchg	 ebx,PGROUP:[edx].DPTSS_LaLDT ; Swap linear addresses
	 mov	 esi,ebx	; Get old linear (source) address
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy it
DPMIFN_GROWLDT2:

COMMENT|

At this point:

DPTSS_LaLDT	 linear address of new DPMI LDT
DPTSS_LDT_SIZ	 byte size of old DPMI LDT
EAX	 =	 new LDT_SIZ
EDX	 =	 PCURTSS

|

; Copy the trailing bitmap to the end of the new DPMI LDT
; Because the new and old bitmap might overlap (destructively),
; we must copy it backwards.

	 xchg	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Swap byte size of DPMI LDT (/8)

; EAX	 =	 byte size of old DPMI LDT
; DPTSS_LDT_SIZ = ...	      new ...

	 mov	 esi,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 mov	 edi,esi	; Copy for later use
	 add	 esi,eax	; Plus byte size of old DPMI LDT (/8) to skip
				; to the start of original trailing bitmap

	 call	 DPMIFN_BITMAP_SIZ ; Return with EBX = byte size of DPMI LDT (/8)
				; bitmap using LDT_SIZ of EAX
	 add	 esi,ebx	; Skip to end+1 of original trailing bitmap

	 add	 edi,PGROUP:[edx].DPTSS_LDT_SIZ ; Plus byte size of new DPMI LDT (/8)
				; to skip to the start of new trailing bitmap
	 add	 edi,ebx	; Skip to corresponding position of the
				; trailing bitmap in the larger LDT
	 mov	 ecx,ebx	; Copy as # bytes to move (backwards)
	 dec	 esi		; Decrement to address last byte
	 dec	 edi		; ...

	 std			; String ops backwards
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy it
	 cld			; String ops fowards

; Zero the new LDTEs

	 mov	 edi,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 add	 edi,eax	; Plus old byte size of DPMI LDT
	 mov	 ecx,PGROUP:[edx].DPTSS_LDT_SIZ ; Get new byte size of DPMI LDT (/8)
	 sub	 ecx,eax	; Less old ...
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 xor	 eax,eax	; Fill with this value
     rep stos	 AGROUP:[edi].EDD ; Zero 'em

; Set linear address of new DPMI LDT in the GDT

	 mov	 eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	push	PGROUP:[edx].DPTSS_LDT_SIZ ; Pass size of area in bytes
	push	word ptr (CPL0_LDT or (@DPMI_CPL shl $DT_DPL)) ; Pass access rights word
	push	PGROUP:[edx].TSS_LDT ; Pass descriptor to set
	FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

; Tell the CPU about the new LDTR

	 lldt	 PGROUP:[edx].TSS_LDT ; Set LDTR

; Save linear address of DPMI LDT as Read-Write data descriptor at PL3

	 mov	 eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 push	 PGROUP:[edx].DPTSS_LDT_SIZ ; Pass size of area in bytes
	 push	 DPMI_DATA	; Pass access rights byte
	 push	 LDTE_DATALDT3	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

; Now free the old LDT

	 cmp	 [ebp].do_free, 0; test free-old-ldt flag
	 je	 short @F

	 push	 [ebp].old_size ; pass number of bytes to free
	 push	 [ebp].old_LA	; pass address to free
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Free old LDT
@@:
	 clc			; Indicate we succeeded

	 jmp	 short DPMIFN_GROWLDT_EXIT ; Join common error code

DPMIFN_GROWLDT_ERR:
	 stc			; Mark as failure
DPMIFN_GROWLDT_EXIT:
	 lea	 esp,[esp+size GROWLDT_LOCALS] ; Deallocate scratch space
				; preserving EFL
	 popad			; Restore all EGP registers

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GROWLDT endp		; End DPMIFN_GROWLDT procedure
	 NPPROC  GET_LDT -- Get Available Selectors from LDT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get one or more available selectors from the LDT
and mark them as in use.

On entry:

GETLDT_CNT =	 # consecutive selectors to allocate
		 N.B. we assume that the caller never sets
		 this value to zero.

On exit:

CF	 =	 0 if we succeeded
	 =	 1 if we didn't
EAX	 =	 found selector (with $TI and $PL set)
		 with LDT entry(ies) marked as CPL3_DATA

|

GETLDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
GETLDT_CNT dw	 ?		; # consecutive selectors needed
GETLDT_FLG dw	 ?		; Flag values:
				;   Bit 0 = Set for Segment-to-selector
GETLDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx,esi,es> ; Save for a moment

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it
GET_LDT_GROWUP:
	 mov	 esi,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 eax,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 add	 eax,@NLDTE_RSV*(type DESC_STR) ; Skip over reserved selectors
	 mov	 ecx,PGROUP:[esi].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 shr	 ecx,3-0	; Convert from bytes to qwords (# LDTEs)
	 sub	 cx,@NLDTE_RSV	; Less # reserved ...
GET_LDT_NEXTOUTER:
	 mov	 dx,[ebp].GETLDT_CNT ; Get the # selectors we need
GET_LDT_NEXTINNER:
	 cmp	 AGROUP:[eax].EDQLO,0 ; Izit available?
	 jne	 short @F	; Jump if not

	 cmp	 AGROUP:[eax].EDQHI,0 ; Izit available?
	 je	 short GET_LDT_AVL ; Jump if so
@@:
	 add	 eax,type DESC_STR ; Skip to next LDT entry

	 loop	 GET_LDT_NEXTOUTER ; Jump if more DTEs to check
GET_LDT_FULL:
	 call	 DPMIFN_GROWLDT ; Attempt to grow the LDT
	 jnc	 short GET_LDT_GROWUP ; Jump if succeeded

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 stc			; Indicate we couldn't find a selector

	 jmp	 short GET_LDT_EXIT ; Join common exit code

GET_LDT_AVL:
	 dec	 dx		; Count it out
	 jz	 short GET_LDT_FOUND ; Jump if we've found them all

	 add	 eax,type DESC_STR ; Skip to next LDT entry

	 loop	 GET_LDT_NEXTINNER ; Jump if more DTEs to check

	 jmp	 short GET_LDT_FULL ; Join common LDT full code

GET_LDT_FOUND:
	 mov	 cx,[ebp].GETLDT_CNT ; Get the # selectors we allocated

; Mark these selectors as in use, present, PL3 data

@@:
	 mov	 AGROUP:[eax].EDQLO,0 ; Zero the LDTE
	 mov	 AGROUP:[eax].EDQHI,0 ; ...
	 mov	 dl,DPMI_DATA.LO ; Get A/R byte for DPMI data
	 mov	 AGROUP:[eax].DESC_ACCESS,dl ; Set the AR byte

	 sub	 eax,type DESC_STR ; Back off to previous LDT entry

	 loop	 @B		; Jump if more selectors to mark

	 add	 eax,type DESC_STR ; Skip to next LDT entry
	 mov	 edx,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 sub	 eax,edx	; Less the base address to get selector #
	 add	 edx,PGROUP:[esi].DPTSS_LDT_SIZ ; Skip to bitmap table

; Set or clear the segment-selector bits as required

	 push	 eax		; Save for a moment

	 mov	 cx,[ebp].GETLDT_CNT ; Get the # selectors we allocated
	 shr	 eax,3-0	; Convert from bytes to qwords
GET_LDT_NEXTBIT:
	 test	 [ebp].GETLDT_FLG,@BIT0 ; Izit segment-to-selector?
	 jnz	 short @F	; Jump if so

	 btr	 AGROUP:[edx].EDD,eax ; Clear the bit

	 jmp	 short GET_LDT_LOOPBIT ; Join common loop code

@@:
	 bts	 AGROUP:[edx].EDD,eax ; Set the bit
GET_LDT_LOOPBIT:
	 inc	 eax		; Skip to next LDTE #

	 loop	 GET_LDT_NEXTBIT ; Jump if more bits to set/clear

	 pop	 eax		; Restore

	 or	 al,DPMI_CPL	; Plus DPMI CPL
	 or	 al,mask $TI	; Mark as in the LDT

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 clc			; Indicate we found one
GET_LDT_EXIT:
	 REGREST <es,esi,edx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_LDT  endp			; End GET_LDT procedure
	 FPPROC  FGET_LDT -- Get Available Selectors from LDT - far version
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|
	Far version of GET_LDT
|
FGETLDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
	 dw	 ?		; ...	   CS
FGETLDT_CNT dw	 ?		; # consecutive selectors needed
FGETLDT_FLG dw	 ?		; Flag values:
				;   Bit 0 = Set for Segment-to-selector
FGETLDT_STR ends

	 push	 ebp		; save
	 mov	 ebp,esp	; address stack

	 push	 [ebp].FGETLDT_FLG; push flags
	 push	 [ebp].FGETLDT_CNT; push count
	 call	 GET_LDT	; do the call

	 pop	 ebp		; restore
	 ret	 2+2		; return to caller, pop args

FGET_LDT	endp		; End FGET_LDT procedure
	 NPPROC  GETSET_LDTVAR -- Get/Set A Modifiable LDT Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get/set a modifiable (and freeable) LDT entry
Allocate one and set its base and limit.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
EAX	 =	 found selector (with $TI and $PL bits set)

|

GS_NEW_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
GS_NEW_BASE dd	 ?		; Base address to set
GS_NEW_LEN  dd	 ?		; Selector length
GS_NEW_ARW  dw	 ?		; A/R word

GS_NEW_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Allocate a new LDTE

	 push	 0		; Not segment-to-selector
	 push	 1		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 jc	 short GETSET_LDTVAR_ERR ; Jump if not available

; Note that the LDT might move after the above call.

	 push	 eax		; Save selector

	 push	 [ebp].GS_NEW_LEN ; Pass size of area in bytes
	 push	 [ebp].GS_NEW_ARW ; Pass access rights word
	 push	 ax		; Pass descriptor to set
	 mov	 eax,[ebp].GS_NEW_BASE ; Get base address
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the LDT to EAX base

	 pop	 eax		; Restore selector

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 clc			; Indicate we found one

	 jmp	 short GETSET_LDTVAR_EXIT ; Join common code

GETSET_LDTVAR_ERR:
	 popf			; Restore flags
				; (note interrupts might become enabled)
	 stc			; Indicate we couldn't find a selector
GETSET_LDTVAR_EXIT:
	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETSET_LDTVAR endp		; End GETSET_LDTVAR procedure
	 NPPROC  GETSET_LDTFIX -- Get/Set An Unmodifiable LDT Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get/set an unmodifiable LDT entry which cannot be freed.
If found, return the selector.
If not, allocate one and set its base and limit.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
EAX	 =	 found selector (with $TI and $PL bits set)

|

GS_64_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
GS_64_BASE dd	 ?		; Base address to lookup
GS_64_LEN  dd	 ?		; Selector length
GS_64_ARW  dw	 ?		; A/R word to use if to be allocated

GS_64_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,edx,esi,es> ; Save for a moment

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ebx,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 add	 ebx,@NLDTE_RSV*(type DESC_STR); Skip over reserved selectors
	 mov	 ecx,PGROUP:[esi].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 shr	 ecx,3-0	; Convert from bytes to qwords (# LDTEs)
	 sub	 cx,@NLDTE_RSV	; Less # reserved ...
GETSET_LDTFIX_NEXT:
	 cmp	 AGROUP:[ebx].EDQLO,0 ; Izit available?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].EDQHI,0 ; Izit available?
	 jne	 short GETSET_LDTFIX_INUSE ; Jump if not
@@:
GETSET_LDTFIX_LOOP:
	 add	 ebx,type DESC_STR ; Skip to next LDT entry

	 loop	 GETSET_LDTFIX_NEXT ; Jump if more DTEs to check

; No matching selectors:  allocate one

	 push	 @BIT0		; Mark as segment-to-selector
	 push	 1		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 jc	 short GETSET_LDTFIX_ERR ; Jump if not available

; Note that the LDT might move after the above call
; in which case EBX might be invalid.

	 mov	 edx,eax	; Save selector
	 mov	 eax,[ebp].GS_64_BASE ; Get base address

	 push	 [ebp].GS_64_LEN ; Pass size of area in bytes
	 push	 [ebp].GS_64_ARW ; Pass access rights word
	 push	 dx		; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the LDT to EAX base

	 mov	 eax,edx	; Restore selector

	 jmp	 short GETSET_LDTFIX_CLC ; Join common OK code

GETSET_LDTFIX_ERR:
	 popf			; Restore flags
				; (note interrupts might become enabled)
	 stc			; Indicate we couldn't find a selector

	 jmp	 short GETSET_LDTFIX_EXIT ; Join common exit code

; The selector is in use:  check the base address and A/R byte

GETSET_LDTFIX_INUSE:

; Ensure this selector is segment-to-selector

	 push	 ebx		; Save for a moment

	 mov	 eax,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 sub	 ebx,eax	; Subtract to get LDTE #
	 shr	 ebx,3-0	; Convert from LDTE # to bit index

	 add	 eax,PGROUP:[esi].DPTSS_LDT_SIZ ; Skip to trailing bitmap

	 bt	 AGROUP:[eax].EDD,ebx ; Izit segment-to-selector?
	 pop	 ebx		; Restore
	 jnc	 short GETSET_LDTFIX_LOOP ; Jump if not

; Get the base address of the DTE at DS:EBX

	 mov	 eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

	 cmp	 eax,[ebp].GS_64_BASE ; Izit same base?
	 jne	 short GETSET_LDTFIX_LOOP ; Jump if not

; Ensure it's a data selector with 64KB limit

	 mov	 ax,AGROUP:[ebx].DESC_ACCESS.ELO ; Get the descriptor A/R word
	 and	 ah,mask $DTE_B ; Isolate B-bit
	 and	 al,not (mask $DD_ACC) ; Clear accessed bit

	 cmp	 ax,[ebp].GS_64_ARW ; Izit same as we're looking for?
	 jne	 short GETSET_LDTFIX_LOOP ; Jump if not

	 mov	 eax,ebx	; Copy to return register
	 sub	 eax,PGROUP:[esi].DPTSS_LaLDT ; Less linear address of DPMI LDT
				; to get selector #
	 or	 al,DPMI_CPL	; Plus DPMI CPL
	 or	 al,mask $TI	; Mark as in the LDT

	 lsl	 edx,eax	; Get segment limit into EDX
	 nop			; Errata # ??
	 inc	 edx		; Convert from limit to length

	 cmp	 edx,[ebp].GS_64_LEN ; Izit same length?
	 jne	 near ptr GETSET_LDTFIX_LOOP ; Jump if not
GETSET_LDTFIX_CLC:
	 popf			; Restore flags
				; (note interrupts might become enabled)
	 clc			; Indicate we found one
GETSET_LDTFIX_EXIT:
	 REGREST <es,esi,edx,ecx,ebx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETSET_LDTFIX endp		; End GETSET_LDTFIX procedure
	 NPPROC  CLR_LDT -- Clear an LDT Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear an LDT entry

Note that it's valid to clear a selector that is already free.

On entry:

Stack	 =	 LDT selector to clear

On exit:

CF	 =	 0 if selector is valid and now clear
	 =	 1 if not

|

CLRL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
CLRL_SEL dw	 ?		; Selector to clear

CLRL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,es>	; Save registers

	 movzx	 eax,[ebp].CLRL_SEL ; Get the selector to clear
	 and	 ax,not (mask $PL) ; Clear PL bits

	 btr	 ax,$TI 	; Ensure it's from the LDT
	 jnc	 short CLR_LDT_EXIT ; Jump if not (note CF=0)

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[ebx].DPTSS_LDT_SIZ ; Izit within limits?
	 jae	 short CLR_LDT_EXIT ; Jump if not (note CF=0)

	 add	 eax,PGROUP:[ebx].DPTSS_LaLDT ; Plus linear address of DPMI LDT

; Zero the entire entry

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 AGROUP:[eax].EDQLO,0 ; Zero the low-order dword
	 mov	 AGROUP:[eax].EDQHI,0 ; ...	 high-...

	 test	 DPM_FLAG,mask $DPM_DPMINEWSEL ; Should we force new selector?
	 jz	 short @F	; Jump if not

	 mov	 AGROUP:[eax].EDQLO,@NEWSEL_EDQLO ; Set the low-order dword
	 mov	 AGROUP:[eax].EDQHI,@NEWSEL_EDQHI ; ...     high-
@@:
	 popf			; Restore

	 stc			; Prepare to complement
CLR_LDT_EXIT:
	 cmc			; Set CF = 1 if in error, 0 if valid

	 REGREST <es,ebx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_LDT  endp			; End CLR_LDT procedure
	 NPPROC  CLR_LDTZERO -- Clear an LDT Entry And Zero Selectors
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear an LDT entry and zero matching selectors.

Note that it's valid to clear a selector that is already free.

On entry:

SS:EBP	 ==>	 INTXX_STR
Stack	 =	 LDT selector to clear

On exit:

CF	 =	 0 if selector is valid and now clear
	 =	 1 if not

|

CLRLZ_STR struc

CLRLZ_EBP dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
CLRLZ_SEL dw	 ?		; Selector to clear

CLRLZ_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 push	 [ebp].CLRLZ_SEL ; Pass the selector
	 call	 CLR_LDT	; Free this LDT selector
	 jc	 short CLR_LDTZERO_ERR ; Jump if something went wrong

	 mov	 ebp,[ebp].CLRLZ_EBP ; SS:EBP ==> INTXX_STR
	 call	 DPMIFN_ZEROSEL ; Zero selectors which match BX

	 popf			; Restore

	 clc			; Indicate well went well

	 jmp	 short CLR_LDTZERO_EXIT ; Join common exit code

CLR_LDTZERO_ERR:
	 popf			; Restore

	 stc			; Prepare to complement
CLR_LDTZERO_EXIT:
	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_LDTZERO endp		; End CLR_LDTZERO procedure
	 NPPROC  GETLBASE -- Get Base Address From LDT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get base address from LDT.
The selector is assumed to be in the LDT and valid.

On entry:

Selector on stack

On exit:

EAX	 =	 32-bit linear base address

|

GETL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
GETL_SEL dw	 ?		; Selector to use

GETL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,es>	; Save registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 ebx,[ebp].GETL_SEL ; Get the selector
	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 REGREST <es,ebx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETLBASE endp			; End GETLBASE procedure
	 FPPROC  FGETLBASE -- Get Base Address From LDT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to GETLBASE

On entry:

Same as for GETLBASE

On exit:

Same as for GETLBASE

|

FGETLBASE_STR struc

	 dd	 ?		; Caller's CS:IP
FGETLBASE_DTE dw  ?		; DTE to set

FGETLBASE_STR ends

	 push	 [esp].FGETLBASE_DTE ; Pass LDT selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FGETLBASE endp			; End FGETLBASE procedure
	 NPPROC  VALID_LSEL -- Validate LDT Selector
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate LDT selector

On entry:

Selector on stack

On exit:

CF	 =	 0 if valid selector
	 =	 1 if not

|

VALL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
VALL_SEL dw	 ?		; Selector to use
VALL_FLG dw	 ?		; Bit 0:  1 = ensure modifiable
				; Bit 1:  1 = ensure DOS memory block
VALL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,esi,es> ; Save registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 eax,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 movzx	 ebx,[ebp].VALL_SEL ; Get the selector
	 and	 bx,not (mask $PL) ; Clear PL bits
	 jz	 near ptr VALID_LSEL_ERR ; Jump if null GDT selector

	 btr	 bx,$TI 	; Izit in the LDT?
	 jnc	 short VALID_LSEL_GDT ; Jump if not

	 cmp	 ebx,PGROUP:[esi].DPTSS_LDT_SIZ ; Izit within limits?
	 jae	 near ptr VALID_LSEL_ERR ; Jump if not

	 cmp	 AGROUP:[eax+ebx].EDQLO,0 ; Izit available?
	 jne	 short @F	; Jump if not

	 cmp	 AGROUP:[eax+ebx].EDQHI,0 ; Izit available?
	 je	 near ptr VALID_LSEL_ERR ; Jump if so
@@:
; If we're forcing new selectors, ensure this one is not that type

	 test	 DPM_FLAG,mask $DPM_DPMINEWSEL ; Did we force new selector?
	 jz	 short VALID_LSEL_GDT ; Jump if not

	 cmp	 AGROUP:[eax+ebx].EDQLO,@NEWSEL_EDQLO ; Izit available?
	 jne	 short @F	; Jump if not

	 cmp	 AGROUP:[eax+ebx].EDQHI,@NEWSEL_EDQHI ; Izit available?
	 je	 short VALID_LSEL_ERR ; Jump if so
@@:
VALID_LSEL_GDT:
	 test	 [ebp].VALL_FLG,@BIT0 ; Should we check for modifiable?
	 jz	 short VALID_LSEL_XMOD ; Jump if not

	 test	 [ebp].VALL_SEL,mask $TI ; Izit in the LDT?
	 jz	 short VALID_LSEL_ERR ; Jump if not (not modifiable)

	 test	 I31_FLAG,mask $I31_DUSE ; Enforce descriptor usage rules?
	 jz	 short VALID_LSEL_XMOD ; Jump if not

	 cmp	 bx,@NLDTE_RSV*(type DESC_STR) ; Izit one of the reserved selectors?
	 jb	 short VALID_LSEL_XMOD ; Jump if so

	 add	 eax,PGROUP:[esi].DPTSS_LDT_SIZ ; Skip to bitmap table at end
				; of DPMI LDT
	 push	 ebx		; Save for a moment

	 shr	 ebx,3-0	; Convert from bytes to qwords

	 bt	 AGROUP:[eax].EDD,ebx ; Izit segment-to-selector?
	 pop	 ebx		; Restore
	 jc	 short VALID_LSEL_ERR ; Jump if so (not modifiable)
VALID_LSEL_XMOD:
	 test	 [ebp].VALL_FLG,@BIT1 ; Should we check for DOS memory block?
	 jz	 short VALID_LSEL_EXIT ; Jump if not (note CF=0)

	 test	 [ebp].VALL_SEL,mask $TI ; Izit in the LDT?
	 jz	 short VALID_LSEL_ERR ; Jump if not (not DOS memory block)

	 test	 I31_FLAG,mask $I31_DUSE ; Enforce descriptor usage rules?
	 jz	 short VALID_LSEL_EXIT ; Jump if not

; Our test for DOS memory block is not sufficient, but it is necessary
; We ensure that the memory it maps is below 1MB and that it is preceded
; by @MAC_MID or @MAC_END.

	 push	 bx		; Pass the selector
	 call	 GETLBASE	; Return with EAX = selector base

	 cmp	 eax,CON1MB	; Izit within the first megabyte?
	 jae	 short VALID_LSEL_EXIT ; Jump if not (note CF=0)

	 sub	 eax,size MAC_STR ; Back off to MAC entry
	 jc	 short VALID_LSEL_ERR ; Jump if too small

	 cmp	 AGROUP:[eax].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short VALID_LSEL_EXIT ; Jump if so (note CF=0)

	 cmp	 AGROUP:[eax].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short VALID_LSEL_EXIT ; Jump if so (note CF=0)
VALID_LSEL_ERR:
	 stc			; Mark as valid
VALID_LSEL_EXIT:
	 REGREST <es,esi,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALID_LSEL endp 		; End VALID_LSEL procedure
	 NPPROC  SETLBASE -- Set Base Address In LDT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set base address in LDT

On entry:

EAX	 =	 selector base
Selector on stack

On exit:

CF	 =	 0 if valid selector
	 =	 1 if not

|

SETL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
SETL_SEL dw	 ?		; Selector to use

SETL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,esi,es>	; Save registers

	 movzx	 ebx,[ebp].SETL_SEL ; Get the selector
	 and	 bx,not (mask $PL) ; Clear PL bits

	 btr	 bx,$TI 	; Ensure it's in the LDT
	 jnc	 short SETLBASE_EXIT ; Jump if not (note CF=0)

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 ebx,PGROUP:[esi].DPTSS_LDT_SIZ ; Izit within limits?
	 jae	 short SETLBASE_EXIT ; Jump if not (note CF=0)

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 add	 ebx,PGROUP:[esi].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 cmp	 AGROUP:[ebx].EDQLO,0 ; Izit available?
	 jne	 short @F	; Jump if not

	 cmp	 AGROUP:[ebx].EDQHI,0 ; Izit available?
	 je	 short SETLBASE_EXIT ; Jump if so (note CF=0)
@@:

; If we're forcing new selectors, ensure this one is not that type

	 test	 DPM_FLAG,mask $DPM_DPMINEWSEL ; Did we force new selector?
	 jz	 short SETLBASE_XNEWSEL ; Jump if not

	 cmp	 AGROUP:[ebx].EDQLO,@NEWSEL_EDQLO ; Izit available?
	 jne	 short SETLBASE_XNEWSEL ; Jump if not

	 cmp	 AGROUP:[ebx].EDQHI,@NEWSEL_EDQHI ; Izit available?
	 je	 short SETLBASE_EXIT ; Jump if so (note CF=0)
SETLBASE_XNEWSEL:
	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 AGROUP:[ebx].DESC_BASE01,ax ; Set bytes 0-2
	 ror	 eax,16 	; Rotate down high-order word
	 mov	 AGROUP:[ebx].DESC_BASE2,al ; Set byte 2
	 mov	 AGROUP:[ebx].DESC_BASE3,ah ; Set byte 3
	 rol	 eax,16 	; Rotate back high-order word

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 stc			; Mark as valid
SETLBASE_EXIT:
	 cmc			; Set CF = 1 if in error, 0 if valid

	 REGREST <es,esi,ebx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETLBASE endp			; End SETLBASE procedure
	 NPPROC  DPMIFN_GETDYN -- Allocate Memory From Dynamic Save Area
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate memory from the dynamic save area

On exit:

CF	 =	 0 if successful
EDI	 =	 start of block (mapped by DYNHDR_STR)

CF	 =	 1 if not successful
EDI	 =	 clobbered

|

GETDYN_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
GETDYN_LEN db	 ?,?		; # bytes to allocate

GETDYN_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 edi,PGROUP:[edx].DPTSS_DYN ; Get linear address of dynamic save area

	 and	 edi,edi	; Izit present?
	 jz	 near ptr DPMIFN_GETDYN_ERR ; Jump if not

	 movzx	 ebx,[ebp].GETDYN_LEN ; Get # bytes to allocate

; Make sure there's enough room

DPMIFN_GETDYN_NEXT:
	 movzx	 eax,AGROUP:[edi].DYNHDR_LEN ; Get byte length of this entry

	 cmp	 AGROUP:[edi].DYNHDR_FN,@DYNFN_EOL ; Izit End-of-the-line?
	 je	 short DPMIFN_GETDYN_EOL ; Jump if so

	 cmp	 AGROUP:[edi].DYNHDR_FN,@DYNFN_DEL ; Izit deleted?
	 jne	 short DPMIFN_GETDYN_LOOP ; Jump if not

	 cmp	 al,bl		; Izit enough room?
	 jb	 short DPMIFN_GETDYN_LOOP ; Jump if not
	 je	 short DPMIFN_GETDYN_CLC ; Jump if it fits exactly

; The block at EDI has enough room -- split it into two pieces

	 sub	 al,bl		; Subtract to get length of second piece

	 cmp	 al,size DYNHDR_STR ; Izit enough room for a splitting entry?
	 jb	 short DPMIFN_GETDYN1 ; Jump if not (take the entire block)

	 mov	 AGROUP:[edi].DYNHDR_LEN,bl ; Save new length

	 mov	 AGROUP:[edi+ebx].DYNHDR_LEN,al ; Save as new length
	 mov	 AGROUP:[edi+ebx].DYNHDR_FN,@DYNFN_DEL ; Mark as deleted entry

	 jmp	 short DPMIFN_GETDYN_CLC ; Join common code

DPMIFN_GETDYN1:
	 xor	 ebx,ebx	; Clear offset from start
				; (we're re-using the block)
DPMIFN_GETDYN_CLC:
	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 AGROUP:[edi+ebx].DYNHDR_TSS,ax ; Save as new TSS selector

	 clc			; Indicate success

	 jmp	 DPMIFN_GETDYN_EXIT ; Join common exit code

DPMIFN_GETDYN_LOOP:
	 add	 edi,eax	; Skip to next entry

	 jmp	 DPMIFN_GETDYN_NEXT ; Go around again


; There's not enough room in the interstices (deleted entries)
; Attempt to append the new entry at the end
; EDI	 ==>	 EOL entry

DPMIFN_GETDYN_EOL:
	 lea	 eax,[edi+ebx+1] ; Add in the size we need (plus new EOL entry)
	 sub	 eax,PGROUP:[edx].DPTSS_DYN ; Less linear address of dynamic save area

	 cmp	 eax,DPMIDYN_SIZ ; Izit within range?
	 jbe	 short DPMIFN_GETDYN_APPEND ; Jump if so

; There's not enough room at the end -- compress out deleted entries

	 mov	 edi,PGROUP:[edx].DPTSS_DYN ; Get linear address of dynamic save area
DPMIFN_GETDYN_NEXT2:
	 movzx	 eax,AGROUP:[edi].DYNHDR_LEN ; Get byte length of this entry

	 cmp	 AGROUP:[edi].DYNHDR_FN,@DYNFN_EOL ; Izit End-of-the-line?
	 je	 short DPMIFN_GETDYN_EOL2 ; Jump if so

	 cmp	 AGROUP:[edi].DYNHDR_FN,@DYNFN_DEL ; Izit deleted?
	 jne	 short DPMIFN_GETDYN_LOOP2 ; Jump if not

; Move the data above it down

	 mov	 ecx,DPMIDYN_SIZ ; Get size of the entire dynamic save area
	 add	 ecx,PGROUP:[edx].DPTSS_DYN ; Plus linear address of dynamic save area
	 sub	 ecx,edi	; Less current base
	 sub	 ecx,eax	; Less size of this entry
	 lea	 esi,[edi+eax]	; AGROUP:ESI ==> move source

	 push	 edi		; Save base address
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move it down
	 pop	 edi		; Restore

	 jmp	 DPMIFN_GETDYN_NEXT2 ; Go around again

DPMIFN_GETDYN_LOOP2:
	 add	 edi,eax	; Skip to next entry

	 jmp	 DPMIFN_GETDYN_NEXT2 ; Go around again


; Attempt to append the new entry at the end
; EDI	 ==>	 EOL entry

DPMIFN_GETDYN_EOL2:
	 lea	 eax,[edi+ebx+1] ; Add in the size we need (plus new EOL entry)
	 sub	 eax,PGROUP:[edx].DPTSS_DYN ; Less linear address of dynamic save area

	 cmp	 eax,DPMIDYN_SIZ ; Izit within range?
	 ja	 short DPMIFN_GETDYN_ERR ; Jump if not
DPMIFN_GETDYN_APPEND:
	 mov	 AGROUP:[edi].DYNHDR_FN,@DYNFN_DEL ; Mark as deleted entry
	 mov	 AGROUP:[edi].DYNHDR_LEN,bl ; Save as new length

	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 AGROUP:[edi].DYNHDR_TSS,ax ; Save as new TSS selector

; Mark as new ending entry

	 mov	 AGROUP:[edi+ebx].DYNHDR_FN,@DYNFN_EOL ; Mark it

	 clc			; Indicate success

	 jmp	 short DPMIFN_GETDYN_EXIT ; Join common exit code


; No room anywhere

DPMIFN_GETDYN_ERR:
	 stc			; Indicate we failed
DPMIFN_GETDYN_EXIT:
	 REGREST <esi,edx,ecx,ebx,eax> ; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GETDYN endp		; End DPMIFN_GETDYN procedure
	 FPPROC  DPMIFN_VSAPI -- Vendor-Specific API Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Vendor-specific API entry point

On entry:

IF	 =	 0	DO NOT allow interrupts so we don't have to
			save LPMSTK_FVEC in case we're on the LPM stack.
SS:ESP	 ==>	 RETFDPI1_STR

AX	 =	 function code
	 =	 0000h to get version #
	 =	 0100h to get read-write LDT selector

No other registers defined as yet.

On exit:

If RETFDPI1_ARG1 == @VSAPI_MSDOS,

For function 0000h,

AX	 =	 version # of MS-DOS extensions.

For function 0100h,

AX	 =	 read-write PL3 selector (in the LDT) of the LDT.

If RETFDPI1_ARG1 == @VSAPI_386MAX,

For function 0000h,

AX	 =	 version # of 386MAX extensions.

|

RETFDPI1_STR struc		 ; DPMI stack argument structure for far calls
				 ; with one dword argument
RETFDPI1_EIP dd   ?		 ; 00:	Old EIP
RETFDPI1_CS  dw   ?,0		 ; 04:	Old CS w/filler
RETFDPI1_EFL dd   ?		 ; 08:	Old EFL
RETFDPI1_ARG1 dd  ?		 ; 0C:	Argument #1
	     dd   @VSAPI_DDSTKSIZE dup (?) ; 10:  (reserved)
	     dd   ?		 ;   :	Old ESP
	     dw   ?,0		 ;   :	Old SS w/filler

RETFDPI1_STR ends

	 cmp	 ax,0000h	; Izit get version #?
	 jne	 short DPMIFN_VSAPI1 ; Jump if not

	 mov	 ax,0100h	; Return version # of MS-DOS extensions
				; This number is the same as what
				; Windows 3.10 returns.

	 cmp	 [esp].RETFDPI1_ARG1,@VSAPI_MSDOS ; Izit MS-DOS calling?
	 je	 short @F	; Jump if so

	 mov	 ax,0104h	; Return version # indicating we support
				; nested DPMI clients with callback, and
				; emulation of mouse function 14h.
				; VSAPI version 0101h was released in 6.02.
				; VSAPI version 0102h includes Ctrl-C and
				;   Critical Error handling
				; VSAPI version 0103h includes bug fixes for
				;   DOS functions 11h, 12h, and 44h and is
				;   released in 6.03.
				; VSAPI version 0104h includes bug fix for
				;   resident DPMI apps over Windows (wrong LDTR)
@@:
	 jmp	 short DPMIFN_VSAPI_CLC ; Join common success code

DPMIFN_VSAPI1:

; The read-write selector is used by Windows 3.10 only

	 cmp	 ax,0100h	; Izit get LDT selector?
	 jne	 short DPMIFN_VSAPI2 ; Jump if not

; Only MS-DOS has a corresponding function for this argument

	 cmp	 [esp].RETFDPI1_ARG1,@VSAPI_MSDOS ; Izit MS-DOS calling?
	 jne	 short DPMIFN_VSAPI_ERR ; Jump if not

; Return the LDT selector in AX at DPMI CPL

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,DTE_DATALDT or (mask $TI) ; Return it
	 or	 al,DPMI_CPL	; Plus DPMI CPL

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it
DPMIFN_VSAPI_CLC:
	 and	 [esp].RETFDPI1_EFL.ELO,not (mask $CF) ; Indicate success (CF=0)

	 jmp	 short DPMIFN_VSAPI_EXIT ; Join common exit code

DPMIFN_VSAPI2:
DPMIFN_VSAPI_ERR:
	 or	 [esp].RETFDPI1_EFL.ELO,mask $CF ; Indicate not supported (CF=1)
DPMIFN_VSAPI_EXIT:
	 push	 [esp].RETFDPI1_EFL.ELO ; Get return flags (with caller's IF)
	 popf			; Put into effect (interrupts not enabled
				; until after the next instruction
				; at which point we're back at PL3).
	 retfd	 (@VSAPI_DDSTKSIZE+2)*4 ; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_VSAPI endp		; End DPMIFN_VSAPI procedure
	 NPPROC  DPMIFN_DTECACHE -- Reset Invisible Descriptor Caches
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset invisible descriptor caches

|

	 REGSAVE <ds,es,fs,gs>	; Save for a moment

; Because some DPMI clients (pssst, it's Windows 3.10 á 2) may
; invalidate the selectors we carefully pushed onto the stack
; when we handled an interrupt so we can restore them now, we must
; VERR them and zero the invalid ones.

	 VERREST <gs,fs,es,ds>	; Restore selectors with VERR

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_DTECACHE endp		; End DPMIFN_DTECACHE procedure
	 NPPROC  DPMIFN_LPMSTK -- Save New LPM Stack As Appropriate
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Set new LPM stack top for nested callers if it's active
and we're called from PM, not PL0

|

LPMSTK_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
LPMSTK_OFF dd	 ?		; Offset in SS of INTDPI_STR

LPMSTK_STR ends

	 cmp	 LPMSTK_CNT,0	; Is the LPM stack active?
	 je	 short DPMIFN_LPMSTK_RET ; Jump if not

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 eax,[ebp].LPMSTK_OFF ; SS|EAX ==> INTDPI_STR

	 test	 ss:[eax].INTDPI_EFL.EHI,mask $VM ; Izit from VM?
	 jnz	 short DPMIFN_LPMSTK_EXIT ; Jump if so

	 test	 ss:[eax].INTDPI_CS,mask $PL ; Izit from PL0?
	 jz	 short DPMIFN_LPMSTK_EXIT ; Jump if so

; If the B-bit in the stack selector is clear, zero the upper
; word of the stack offset.

	 lea	 ebx,ss:[eax].INTDPI_ESP ; SS:EBX ==> SS|ESP from PL3
	 push	 ebx		; Pass the offset
	 call	 DPMIFN_ESPMOD	; Clear the high-order word of the PL3 ESP
				; if the B-bit in the PL3 SS is clear
	 mov	 ebx,ss:[eax].INTDPI_ESP ; Save caller's offset
	 mov	 LPMSTK_FVEC.FOFF,ebx ; ...
	 mov	 bx,ss:[eax].INTDPI_SS ; Save caller's selector
	 mov	 LPMSTK_FVEC.FSEL,bx ; ...
DPMIFN_LPMSTK_EXIT:
	 REGREST <ebx,eax>	; Restore

	 pop	 ebp		; Restore
DPMIFN_LPMSTK_RET:
	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_LPMSTK endp		; End DPMIFN_LPMSTK procedure
	 FPPROC  FDPMIFN_LPMSTK -- Save New LPM Stack As Appropriate
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Far call to DPMIFN_LPMSTK

On entry:

Same as for DPMIFN_LPMSTK

|

FLPMSTK_STR struc

	 dd	 ?		; Caller's CS|IP
FLPMSTK_OFF dd	 ?		; Offset in SS of INTDPI_STR

FLPMSTK_STR ends

	 push	 [esp].FLPMSTK_OFF ; Pass the offset
	 call	 DPMIFN_LPMSTK	; Save new LPM stack as appropriate

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMIFN_LPMSTK endp		; End FDPMIFN_LPMSTK procedure
	 NPPROC  DPMIFN_ESPMOD -- Modify High-order Word of PL3 ESP
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Modify the high-order word of the PL3 ESP if the B-bit in
the PL3 SS is clear.

On entry:

SS:EAX	 ==>	 PL3 SS:ESP as an fword

|

ESPMOD_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
ESPMOD_OFF dd	 ?		; Offset in SS of PL3 SS|ESP

ESPMOD_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,ds> ; Save registers

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 eax,[ebp].ESPMOD_OFF ; Get offset in SS of PL3 SS|ESP

	 movzx	 ebx,ss:[eax].FSEL ; Get the selector
	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits

	 mov	 ecx,PCURTSS	; Plus offset in PGROUP of the current TSS
	 mov	 ecx,PGROUP:[ecx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 test	 AGROUP:[ebx+ecx].DESC_SEGLM1,mask $DTE_B ; Izit Big or Small?
	 jnz	 short @F	; Jump if it's Big

	 mov	 ss:[eax].FOFF.EHI,0 ; Clear the high-order word of the offset
@@:
	 REGREST <ds,ecx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_ESPMOD endp		; End DPMIFN_ESPMOD procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_M31_XCODE
@QMAX_M31_XCODE:		; Mark module start in .MAP file

	 NPPROC  ROOM_DPMI -- Make Room for DPMI Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for DPMI tables

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ebx		; Save for a moment

; Make room for the IGROUP code/data

	 mov	 IGRBASE,eax	; Save as start of IGROUP code/data

	 lea	 ebx,IGROUP:LCODE_NXT ; Get offset of next available byte
				; in IGROUP (and thus its length) after LCODE
	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short @F	; Jump if so

	 lea	 ebx,IGROUP:IDATA_NXT ; Get offset of next available byte
				; in IGROUP (and thus its length)
@@:
	 mov	 IGRSIZE,ebx	; Save as length of IGROUP
	 add	 eax,ebx	; Skip over the IGROUP code/data

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short ROOM_DPMI_EXIT ; Jump if so

	 sub	 eax,PRGBASE	; Convert from linear address to offset
	 mov	 PDPMILDT,eax	; Save the offset in PGROUP
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 add	 eax,LDT_SIZ	; Skip over the LDT

; Make room for the LDT's trailing bitmap
; at one bit per LDT entry

	 mov	 ebx,LDT_SIZ	; Get byte size of the DPMI LDT (/8)
	 shr	 ebx,3-0	; Convert from bytes to qwords (# LDTEs)
	 add	 ebx,8*8-1	; Round up to next qword of bits
	 and	 ebx,not (8*8-1) ; ...
	 shr	 ebx,3-0	; Convert from bits to bytes
	 add	 eax,ebx	; Skip over bitmap

; Note we don't round up to the next @DPMI_BOUND boundary as this
; is the resident LDT, not the one used by any DPMI client.

; Make room for DPMI memory handles

	 sub	 eax,PRGBASE	; Convert from linear address to offset
	 mov	 DPMIHNDL_OFF,eax ; Save the offset in PGROUP
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 mov	 ebx,DPMIHNDL_CNT ; Get # handles
	 imul	 ebx,type DPMIHNDL_STR ; Times # bytes per handle
	 add	 eax,ebx	; Skip over the handles

if @OEM_VIRTUALMEM

; Make room for the backing store cache

	 test	 VMM_FLAG,@VMM_BSGLOBAL ; Is there a swap file present?
	 jz	 short ROOM_DPMI_EXIT ; Jump if not

	 push	 es		; Save for a moment

	 mov	 bx,seg IGROUP	; Get segment of PBSCache
	 mov	 es,bx		; Address it
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 ebx,eax	; Get current linear address
	 sub	 ebx,IGRBASE	; Less linear address of IGROUP to get
				; offset in IGROUP
	 mov	 PBSCache,ebx	; Save for later use
	 add	 eax,@BSCSize	; Skip over the BSCache

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
endif				; IF @OEM_VIRTUALMEM
ROOM_DPMI_EXIT:
	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_DPMI endp			; End ROOM_DPMI procedure
	 NPPROC  ROOM_DPMI2 -- Make Room for DPMI Page Directories
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for DPMI page directories

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ebx		; Save for a moment

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short ROOM_DPMI2_EXIT ; Jump if so

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

; Make room for DPMI page directories

	 mov	 LaDPMIPDIR,eax ; Save its linear address
	 sub	 eax,PRGBASE	; Convert from linear address to offset
	 mov	 DPMIPDIR_OFF,eax ; Save the offset in PGROUP
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 mov	 ebx,DPMIPDIR_CNT ; Get # handles
	 shl	 ebx,12-0	; Convert from 4KB to bytes
	 add	 eax,ebx	; Skip over the page directories
ROOM_DPMI2_EXIT:
	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_DPMI2 endp 		; End ROOM_DPMI2 procedure

XCODE	 ends			; End XCODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_M31 module
