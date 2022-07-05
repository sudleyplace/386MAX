;' $Header:   P:/PVCS/MAX/386MAX/QMAX_VMM.ASV   1.3   30 May 1997 10:46:16   BOB  $
	 title	 QMAX_VMM -- 386MAX Virtual Memory Functions
	 page	 58,122
	 name	 QMAX_VMM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'

Program derived from:  None.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include 8259.INC
	 include PTR.INC
	 include MAC.INC
	 include XMS.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include VDISK.INC
	 include INTVEC.INC
	 include ALLMEM.INC
	 include MASM5.MAC
	 include DPMI.INC

	 include LOAD_SEG.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_I31.INC
	 include QMAX_OEM.INC
	 include QMAX_XMS.INC
	 include QMAX_VMM.INC
	 include QMAXDPMI.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
IGROUP	 group	 ICODE,IDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_XMS
	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

if @OEM_WIN3
	 extrn	 LOWWIN3_CB:byte
endif				; IF @OEM_WIN3
endif				; IF @OEM_XMS

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

if @OEM_WIN3
	 extrn	 WIN3_VERSION:word
endif				; IF @OEM_WIN3

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
endif				; IF @OEM_VIRTUALMEM

	 extrn	 HP_LAST:dword
	 extrn	 PPHNDLFREE:dword
	 extrn	 HMASIZE:dword

if @OEM_XMS
	 extrn	 EMMBASE:dword
	 extrn	 CMPSIZEXT:dword
	 extrn	 PPDTCNV:dword
	 extrn	 PPDTCNVZ:dword
	 extrn	 CNVBASE:dword
	 extrn	 PPDTUNW:dword
	 extrn	 PPDTUNWZ:dword
	 extrn	 PPDT1MB:dword
	 extrn	 PPDTEMMZ:dword
	 extrn	 PPHNDLVMS:dword
	 extrn	 PPAGELINK:dword
	 extrn	 PLINKBASE:dword
	 extrn	 PBASEPAGE:dword
	 extrn	 BASEPAGE_INV:dword
	 extrn	 TOTPGCNT:word
	 extrn	 REMPGCNT:word
	 extrn	 CON4KB:dword
	 extrn	 CON16KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON16MB:dword
	 extrn	 PRGPDT:dword

	 extrn	 SEL_DSIG3:word

	 public  ALLOC_LIM
ALLOC_LIM dd	  1-1		; For  1KB boundary in 1KB -- XMS
	  dd	  4-1		; ...  4KB ...		   -- VCPI
	  dd	 16-1		; ... 16KB ...		   -- EMS
	  dd	 (@DPMI_BOUND/1024)-1; ...		   -- DPMI
	  dd	  1-1		; ...  1KB ...		   -- XMS2

	 public  PXMSBMAP,XMSBMAP_LEN
PXMSBMAP dd	 ?		; PGROUP offset to XMSBMAP bytemap allocation table
XMSBMAP_LEN dd	 ?		; Byet length of XMSBMAP

; The XMSBMAP table is 1024+CMPSIZE+HMASIZE bytes long and each
; byte contains the XMS allocation and boundary information about the
; corresponding 1KB block (see QMAX_XMS.INC for record).
; The @XMSB_ALLOC bit is set if the corresponding 1KB block is allocated,
; clear otherwise.
; The @XMSB_BOUND bit is set if there is a physical discontiguity between
; the corresponding 1KB block and the one which follows it.

	 public  XMSBND_BRKPNT
XMSBND_BRKPNT	 dd	01000000h ; Artificial breakpoint (for Windows support)
				; 16 MB = Default for Win30
				;  4 GB = If NOWIN30 option

endif				; IF @OEM_XMS

EDATA	 ends			; End EDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 LinearBottom:DWORD
	 extrn	 VMM_QUERY:FAR
endif				; IF @OEM_VIRTUALMEM

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 FVMM_ALLOC:far
	 extrn	 FVMM_FREE:far
	 extrn	 PPM_DRAIN_POOL:far
endif

ICODE	 ends			; End ICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

if @OEM_XMS
	 public  @QMAX_VMM_ECODE
@QMAX_VMM_ECODE:		; Mark module start in .MAP file

if @OEM_WIN3
	 NPPROC  SET_XMSBND -- Set XMSBMAP Boundary Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set XMSBMAP entries marking where they span physically discontiguous memory

Note: This routine MUST be called after any and all routines in QMAX_EVM
      that swap their PTEs for PTEs at 1.1 MB.
      After all, it wouldn't make sense to mark all the discontiguous
      entries and then add some more discontiniguities later on, would it?

|
	 REGSAVE <ecx,esi>	; Save registers

	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jnz	 short SET_XMSBND_DONE ; Jump if so

; Limit extended memory free chain to physical boundaries
; which don't cross 16MB (bug in Windows 3.00)

; Check conventional entries

	 mov	 esi,PPDTCNV	; Get starting offset of CNV entries
	 mov	 ecx,PPDTCNVZ	; ... ending ...
	 call	 SET_XMSBND_SUB ; Set the entries

; Check the rest of the common memory pool

	 mov	 esi,PPDT1MB	; Get starting offset of CMP entries
	 mov	 ecx,PPDTEMMZ	; ... ending ...
	 call	 SET_XMSBND_SUB ; Set the entries
SET_XMSBND_DONE:
	 REGREST <esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_XMSBND endp 		; End SET_XMSBND procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	 NPPROC  SET_XMSBND_SUB -- Subroutine to SET_XMSBND
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to SET_XMSBND to set XMSBMAP boundary entries.

On entry:

ESI	 =	 starting offset in PDT
ECX	 =	 ending ...

|
	 pushad 		; Save all EGP registers

	 sub	 ecx,esi	; Subtract to get length
	 jz	 short SET_XMSBND_SUB_EXIT ; Jump if nothing to do

	 shr	 ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB
				; ECX = # PDT entries to check

	 mov	 ebx,PXMSBMAP	; DS:EBX ==> XMS bytemap table

	 mov	 eax,esi	; Copy PDT offset
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 mov	 edx,eax	; Set translated address

;;;;;;;; sh?	 edx,10-(12-2) ; Convert from 4KB in dwords to 1KB

; Register usage:

; EBX	 ==>	 XMSBMAP
; EDX	 =	 entry # in XMSBMAP
; ESI	 =	 offset into PDT

	 add	 esi,PRGPDT	; Plus offset in PGROUP of PDT
	 mov	 edi,PGROUP:[esi].PDT_PTE ; Get next PTE
	 and	 di,mask $PTE_FRM ; Isolate 4KB frame
SET_XMSBND_SUB_NEXT:
	 lods	 PGROUP:[esi].PDT_PTE ; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

	 cmp	 eax,XMSBND_BRKPNT ; Izit the artificial breakpoint?
	 je	 short @F	; Jump if so (force a break)

	 cmp	 eax,edi	; Izit in sequence?
	 je	 short SET_XMSBND_SUB_LOOP ; Jump if so
@@:

; Set the boundary bit in XMSBMAP

	 or	 PGROUP:[ebx+edx-1].LO,@XMSB_BOUND ; Set the boundary bit

	 mov	 edi,eax	; Copy as new next expected PTE
SET_XMSBND_SUB_LOOP:
	 add	 edi,CON4KB	; Skip to next expected PTE
	 add	 edx,4		; Skip to next entry index of 4KB

	 loopd	 SET_XMSBND_SUB_NEXT ; Jump if more PTEs to check
SET_XMSBND_SUB_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_XMSBND_SUB endp		; End SET_XMSBND_SUB procedure
endif				; IF @OEM_WIN3
if @OEM_XMS or @OEM_VCPI
	 NPPROC  ALLOCMEM -- Allocate Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate XMS and VCPI memory.  This routine is not used
to allocate EMS memory (use ALLOCEMS instead).

Note that because this routine might be called from the
other side of the VCPI wall, we can't use any SEL_xxx variables.

On exit:

CF	 =	 0 if successful
	 =	 1 if not
EBX	 =	 linear address ...

|

ALLOCMEM_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
ALLOCMEM_LEN dd  ?		; Byte length of allocate
ALLOCMEM_TYP dw  ?		; Allocation type (see QMAX_EMM.INC for equates)

ALLOCMEM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

ALLOCMEM_BACKSTR struc

ALLOCMEM_MSK dd  ?		; Mask for boundary
ALLOCMEM_LIM dd  ?		; Limit value

ALLOCMEM_BACKSTR ends

@ALLOCMEM_BACK equ (size ALLOCMEM_BACKSTR)


	 sub	 esp,@ALLOCMEM_BACK ; Make room for ALLOCMEM_BACKSTR

	 REGSAVE <eax,ecx,edx,edi,es> ; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Set mask and limit values based upon allocation type

	 movzx	 ebx,[ebp].ALLOCMEM_TYP ; Get allocation type

if @OEM_VIRTUALMEM

; Use VMM allocator for DPMI calls

	 test	 VMM_FLAG,@VMM_SYSINIT ; Izit present?
	 jz	 short ALLOCMEM_VMM_NOTACTIVE ; Jump if not

; If VCPI is active (we're running on the client's GDT), skip
; this call as we do not have addressibility to IGROUP.

	 test	 VMM_FLAG,@VMM_VCPIACTIV ; Is VCPI active?
	 jnz	 short ALLOCMEM_VMM_NOTACTIVE ; Jump if so

	 cmp	 bl,@ALLOC_DPMI ; Izit a DPMI allocate?
	 jne	 short notDPMI	; Jump if not

	 xor	 eax,eax	; Any linear address ok
	 mov	 ebx,[ebp].ALLOCMEM_LEN ; EBX <- size in bytes
	 add	 ebx,4096-1	; Round up to 4KB boundary
	 shr	 ebx,12-0	; EBX <- size in pages
	 mov	 edx,ebx	; EDX gets a copy

	 mov	 ecx,mask $commit ; Eventually an argument...
	 FIXICALL IGROUP:FVMM_ALLOC,DTE_CSIG ; Rets address in EAX
	 mov	 ebx,eax	; Save as return value
	 jc	 short VMM_alloc_fail ; Jump if we failed

	 popf			; Restore flags

	 clc			; Mark as successful

	 jmp	 ALLOCMEM_EXIT	; Join common exit code

VMM_alloc_fail:
	 popf

	 stc

	 jmp	 ALLOCMEM_EXIT	; Join common exit code

notDPMI:

; Here if the VMM is active but the request is *not* for DPMI
; memory.  Drain the VMM's page pool to satisfy the request.

	 REGSAVE <ecx,ds>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ecx,edx	; Try to drain enough
	 add	 ecx,@PageSize-1 ; Round up
	 shr	 ecx,@BytePage	; Convert to pages
	 FIXICALL IGROUP:PPM_DRAIN_POOL,DTE_CSIG ; Do the drain

	 REGREST <ds,ecx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
ALLOCMEM_VMM_NOTACTIVE:
endif
	 mov	 eax,ALLOC_LIM[ebx*(type ALLOC_LIM)] ; Get the limit
	 mov	 [ebp-@ALLOCMEM_BACK].ALLOCMEM_LIM,eax ; Save on stack
	 not	 eax		; Complement to use as mask
	 mov	 [ebp-@ALLOCMEM_BACK].ALLOCMEM_MSK,eax ; Save on stack

	 mov	 ecx,XMSBMAP_LEN ; ECX = entry length of XMSBMAP

	 cmp	 bl,@ALLOC_XMS	; Izit XMS allocate?
	 jne	 short @F	; Jump if not

	 mov	 ecx,CMPSIZEXT	; Get size of EXT/XMS CMP
	 add	 ecx,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 ecx,1024	; Plus first megabyte
@@:
	 shr	 [ebp].ALLOCMEM_LEN,10-0 ; Convert from bytes to 1KB

	 push	 ds		; Get PGROUP data selector at PL3
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Check XMSBMAP for adjacent free entries anywhere

	 xor	 ebx,ebx	; Initialize index into XMSBMAP
	 xor	 edi,edi	; Initialize for next instruction
ALLOCMEM_NEXT:
	 add	 ebx,edi	; Add to get next entry #
	 sub	 ecx,edi	; Subtract out from # entries

	 call	 XMS_MEMAVL	; Find next available entry
				; with EBX = starting entry #
				; ...  ECX = # remaining entries
				; Return with EBX = next available entry #
				; ...	      ECX = # remaining entries
	 jc	 near ptr ALLOCMEM_ERR ; Jump if they're all allocated

; Round up the starting address to the appropriate boundary

	 add	 ecx,ebx	; Add to get ending address

	 add	 ebx,[ebp-@ALLOCMEM_BACK].ALLOCMEM_LIM ; Add in limit
	 and	 ebx,[ebp-@ALLOCMEM_BACK].ALLOCMEM_MSK ; Round down
	 sub	 ecx,ebx	; Less new starting offset
	 jc	 near ptr ALLOCMEM_ERR ; Jump if no more entries

; Determine the span of available entries starting
; at EBX for no more than ALLOCMEM_LEN entries

	 push	 [ebp].ALLOCMEM_TYP ; Pass allocation type
	 push	 [ebp].ALLOCMEM_LEN ; Pass # entries we need
	 push	 ebx		; Pass starting offset into XMSBMAP
	 call	 XMS_MEMSPAN	; Determine the span of available entries
				; returning EDI = # consecutive available entries

	 cmp	 edi,[ebp].ALLOCMEM_LEN ; Izit big enough?
	 jb	 short ALLOCMEM_NEXT ; Jump if not

if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jnz	 short ALLOCMEM_XWIN ; Jump if so

	 cmp	 [ebp].ALLOCMEM_TYP,@ALLOC_XMS ; Izit XMS allocate?
	 jne	 short ALLOCMEM_XWIN ; Jump if not

; If we're called by Windows, and this is an XMS allocate,
; don't include any free memory which is below 1MB or above
; 16MB (bug in Windows 3.00)

	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 je	 short ALLOCMEM_XWIN ; Jump if not

; Check the PTE for this memory.  Note that we need check the first PTE
; only as it has already been segregated by physical boundary

	 mov	 eax,ebx	; Copy 1KB address
	 shr	 eax,12-10	; Convert from 1KB to 4KB
	 shl	 eax,12-(12-2)	; Convert from 4KB to 4KB in dwords
	 add	 eax,PRGPDT	; Plus offset in PGROUP of PDT
	 mov	 eax,PGROUP:[eax].PDT_PTE ; Get the corresponding PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

	 cmp	 eax,CON1MB	; Izit below 1MB?
	 jb	 near ptr ALLOCMEM_NEXT ; Jump if so (start looking again)

; If we're running under Windows 3.10 or later, the bug of not handling
; memory above 16MB is fixed so we don't need to check for that case

	 cmp	 WIN3_VERSION,30Ah ; Izit Windows 3.10 or later?
	 jae	 short ALLOCMEM_XWIN ; Jump if so

	 cmp	 eax,CON16MB	; Izit above 16MB?
	 jae	 near ptr ALLOCMEM_NEXT ; Jump if so (start looking again)
ALLOCMEM_XWIN:
endif				; IF @OEM_WIN3

; We're at the end of a contiguous block of available memory
; EBX	 =	 starting index

ALLOCMEM_END:
	 mov	 ecx,[ebp].ALLOCMEM_LEN ; Get length in 1KB

	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 shl	 ebx,10-0	; Convert from 1KB to bytes

; If the address passed is in the range 0 to CON1MB,
; wrap back to CNVBASE

	 cmp	 ebx,CON1MB	; Check against upper limit
	 jae	 short @F	; Jump if too large

	 add	 ebx,CNVBASE	; Convert to origin-CNVBASE
@@:

; Allocate ECX bytes at EBX

	 push	 ecx		; Pass # bytes to set
	 push	 ebx		; Pass starting linear address
	 call	 ALLOCMEM_SUB	; Allocate 'em
	 jc	 near ptr ALLOCMEM_ERR ; Jump if something went wrong

	 popf			; Restore
				; (note interrupts might become enabled)
	 clc			; Indicate all went well

	 jmp	 short ALLOCMEM_EXIT ; Join common exit code

ALLOCMEM_ERR:
	 popf			; Restore
				; (note interrupts might become enabled)
	 stc			; Indicate not enough memory

	 jmp	 ALLOCMEM_EXIT	; Join common exit code

ALLOCMEM_EXIT:
	 REGREST <es,edi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 mov	 esp,ebp	; Strip back the stack

	 pop	 ebp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOCMEM endp			; End ALLOCMEM procedure
endif				; IF @OEM_XMS or @OEM_VCPI
if @OEM_XMS or @OEM_VCPI
	 NPPROC  ALLOCMEM_SUB -- Allocate Memory Subroutine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate memory at a specific address and length.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

ALLOCMEM_SUB_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
ALLOCMEM_SUB_LA  dd  ?		; Linear address to allocate
ALLOCMEM_SUB_LEN dd  ?		; Byte length of allocate

ALLOCMEM_SUB_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushad 		; Save all EGP registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 edi,[ebp].ALLOCMEM_SUB_LA  ; Get linear address to allocate
	 mov	 ecx,[ebp].ALLOCMEM_SUB_LEN ; Get byte length ...

if @OEM_VIRTUALMEM

; Determine if this is a DPMI/VM call by examining the
; requested address. If it falls between the known bounds
; of the DPMI managed range, use the VMM to do the allocation.
; Otherwise, pass the call thru to the primary memory manager.

	 test	 VMM_FLAG,@VMM_SYSINIT ; Izit present?
	 jz	 short ALLOCMEM_SUB_NOTDPMI ; Jump if not

	 test	 VMM_FLAG,@VMM_VCPIACTIV ; Is VCPI active?
	 jnz	 short ALLOCMEM_SUB_NOTDPMI ; Jump if so

	 push	 es		; Save for a moment

	 mov	 es,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 cmp	 edi,LinearBottom ; Compare requested address to VMM
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 jb	 short ALLOCMEM_SUB_NOTDPMI ; Jump if not in VMM range

	 mov	 eax,edi	; Pass requested address in eax
	 mov	 ebx,ecx	; Pass size in ebx
	 shr	 ebx,@BytePage	; Convert size to pages
	 mov	 ecx,mask $commit ; Get flags from caller
	 FIXICALL IGROUP:FVMM_ALLOC,DTE_CSIG ; Do VMM allocation
	 jc	 short VMM_allocmemsub_fail ; jump if alloc failed

	 popf			; Restore flags

	 clc			; Signal success

	 jmp	 ALLOCMEM_SUB_EXIT ; Join common exit code

VMM_allocmemsub_fail:
	 popf			; Restore flags

	 stc			; Signal failure

	 jmp	 ALLOCMEM_SUB_EXIT ; Join common exit code

ALLOCMEM_SUB_NOTDPMI:
endif				; IF @OEM_VIRTUALMEM

; Mark ECX entries at EDI as allocated

	 push	 ecx		; Pass # entries to set
	 push	 edi		; Pass starting linear address
	 call	 SET_XMSBMAP	; Set XMSBMAP bits to mark as allocated

; Remove the memory from the EMS free chain and append
; to the start of the VMS chain

; First determine how many EMS pages this allocation spans

	 add	 ecx,edi	; ECX = ending address
	 and	 edi,not (16*1024-1) ; Round down to 16KB boundary
	 sub	 ecx,edi	; Subtract rounded (down) start to get
				; rounded (up) length
	 add	 ecx,16*1024-1	; Plus rounding constant
;;;;;;;; and	 ecx,not (16*1024-1) ; Round down to 16KB boundary
	 shr	 ecx,14-0	; Convert from bytes to 16KB
	 mov	 edx,PPHNDLVMS	; Get ptr to ptr of VMS free chain

; ECX = # EMS pages to allocate
; EDI has the EMS rounded (down) address
; EDX = next VMS free chain entry

ALLOCMEM_SUB_NEXTPL:
	 mov	 eax,edi	; Copy rounded (down) base address
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 shr	 eax,(14-2)-10	; Convert from 1KB to 16KB in dwords
	 add	 eax,PBASEPAGE	; Plus base of BASEPAGE table
	 mov	 ebx,PGROUP:[eax].PL_NEXT ; Get next PL to allocate

; EBX = next PL entry to allocate

	 cmp	 ebx,BASEPAGE_INV ; Izit invalid?
	 je	 short ALLOCMEM_SUB_INV ; Jump if so

; Find EBX in the EMS free chain
; If found, delete it and prepend to VMS chain
; If not, it must already be in the VMS chain (check that)

	 mov	 eax,PPHNDLFREE  ; DS:EAX ==> ptr to start of free chain
@@:
	 mov	 esi,eax	; Copy to index register
	 mov	 eax,PGROUP:[esi].PL_NEXT ; Get next PL

	 cmp	 eax,ebx	; Izit a match?
	 je	 short ALLOCMEM_SUB_FOUNDPL ; Jump if so

	 cmp	 eax,HP_LAST	; Izit the end?
	 jne	 short @B	; Jump if not

; We didn't find this entry in the EMS free chain
; For debugging purposes, ensure that it's in the VMS chain

	 mov	 eax,PPHNDLVMS	; Get ptr to start of free chain
ALLOCMEM_SUB_NEXTVMS:
	 mov	 esi,eax	; Copy last index
	 mov	 eax,PGROUP:[esi].PL_NEXT ; Get next PL

	 cmp	 eax,ebx	; Izit our baby?
	 je	 short ALLOCMEM_SUB_LOOPPL ; Jump if so

	 cmp	 eax,HP_LAST	; Check for end-of-the-chain
	 jne	 short ALLOCMEM_SUB_NEXTVMS ; Jump if not

	 int	 03h		; Call our debugger

	 popf			; Restore
				; (note interrupts might become enabled)
	 stc			; Indicate not enough memory

	 jmp	 short ALLOCMEM_SUB_EXIT ; Join common exit code


; If the address in EDI is below EMMBASE, we can ignore this one
; as it's not in the EMS pool

ALLOCMEM_SUB_INV:
	 cmp	 edi,EMMBASE	; Izit below start of EMS memory?
	 jb	 short ALLOCMEM_SUB_LOOPPL ; Jump if so

	 int	 03h		; Call our debugger
ALLOCMEM_SUB_FOUNDPL:

; DS:ESI ==>	 current entry pointing to the one to delete
; EBX	 =	 PL to move

; Delete this entry from the EMS free chain

	 mov	 eax,PGROUP:[ebx].PL_NEXT ; Get this PL's next PL
	 xchg	 eax,PGROUP:[esi].PL_NEXT ; Swap with prev next PL
				; Now EAX = EBX

; Append this entry to the start of the VMS chain

	 mov	 esi,edx	; Get ptr to next entry in VMS free chain
	 xchg	 eax,PGROUP:[esi].PL_NEXT ; Save as the new head of VMS free chain
	 mov	 PGROUP:[ebx].PL_NEXT,eax ; Point BX to prev 1st PL of VMS chain
	 mov	 edx,PGROUP:[esi].PL_NEXT ; Point to next entry for next time

; Count this EMS page out of TOTPGCNT and REMPGCNT

	 dec	 TOTPGCNT	; Count it out
	 dec	 REMPGCNT	; ...
ALLOCMEM_SUB_LOOPPL:
	 add	 edi,CON16KB	; Skip to next 16KB address

;;;;;;;; loopd	 ALLOCMEM_SUB_NEXTPL ; Jump if more PLs to mark
	 dec	 ecx		; Count one out
	 jnz	 near ptr ALLOCMEM_SUB_NEXTPL ; Jump if more PLs to mark

	 popf			; Restore
				; (note interrupts might become enabled)
	 clc			; Indicate all went well
ALLOCMEM_SUB_EXIT:
	 popad			; Restore all EGP registers

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOCMEM_SUB endp		; End ALLOCMEM_SUB procedure
endif				; IF @OEM_XMS or @OEM_VCPI
if @OEM_XMS or @OEM_VCPI
	 NPPROC  DEALLOCMEM -- Deallocate Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Deallocate XMS and VCPI memory.  This routine is not used
to deallocate EMS memory (use DEALLOCEMS instead).

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

DEALLOCMEM_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DEALLOCMEM_LA  dd  ?		; Linear address to deallocate
DEALLOCMEM_LEN dd  ?		; Byte length of deallocate

DEALLOCMEM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushad 		; Save all EGP registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 edi,[ebp].DEALLOCMEM_LA ; Get linear address to deallocate
	 mov	 ecx,[ebp].DEALLOCMEM_LEN ; Get byte length ...

if @OEM_VIRTUALMEM

; Determine if the deallocation is in the VMM managed area
; by comparing the requested address to the start of the VMM
; managed area.

	 test	 VMM_FLAG,@VMM_SYSINIT	 ; Izit present?
	 jz	 short DEALLOCMEM_NOTDPMI; Jump if not

	 test	 VMM_FLAG,@VMM_VCPIACTIV ; Is VCPI active?
	 jnz	 short DEALLOCMEM_NOTDPMI; Jump if so

	 push	 es		; Save for a moment

	 mov	 es,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 cmp	 edi,LinearBottom ; Test requested address
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 jb	 short DEALLOCMEM_NOTDPMI ; Jump if below VMM area

	 mov	 eax,edi	; Pass address to free in EAX
	 mov	 ebx,ecx	; Pass size to free in EBX
	 shr	 ebx,@BytePage	; Convert size to pages
	 FIXICALL IGROUP:FVMM_FREE,DTE_CSIG ; Deallocate EBX pages at EAX
	 jc	 short VMM_deallocmem_fail ; Jump if dealloc failed

	 popf			; Restore flags

	 clc			; Signal success

	 jmp	 DEALLOCMEM_EXIT ; Join common exit code

VMM_deallocmem_fail:
	 popf			; Restore flags

	 stc			; Signal failure

	 jmp	 DEALLOCMEM_EXIT ; Join common exit code

DEALLOCMEM_NOTDPMI:
endif				; IF @OEM_VIRTUALMEM

; Mark ECX entries at EDI as available

	 push	 ecx		; Pass # entries to clear
	 push	 edi		; Pass starting linear address
	 call	 CLR_XMSBMAP	; Clear XMSBMAP bits to mark as free

; Remove the memory from the VMS free chain and append
; to the start of the EMS chain

; First determine how many EMS pages this allocation spans

	 add	 ecx,edi	; ECX = ending address
	 and	 edi,not (16*1024-1) ; Round down to 16KB boundary
	 sub	 ecx,edi	; Subtract rounded (down) start to get
				; rounded (up) length
	 add	 ecx,16*1024-1	; Round up to 16KB boundary
;;;;;;;; and	 ecx,not (16*1024-1) ; Round down to 16KB boundary
	 shr	 ecx,14-0	; Convert from bytes to 16KB
	 mov	 edx,PPHNDLFREE ; Get ptr to ptr of EMS free chain

; ECX = # EMS pages to deallocate
; EDI has the EMS rounded (down) address
; EDX = next EMS free chain entry

DEALLOCMEM_NEXTPL:
	 mov	 eax,edi	; Copy rounded (down) base address
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 shr	 eax,(14-2)-10	; Convert from 1KB to 16KB in dwords
	 add	 eax,PBASEPAGE	; Plus base of BASEPAGE table
	 mov	 ebx,PGROUP:[eax].PL_NEXT ; Get next PL to de-allocate

; EBX = next PL entry to deallocate

	 cmp	 ebx,BASEPAGE_INV ; Izit invalid?
	 je	 short DEALLOCMEM_INV ; Jump if so

; If all sixteen 1KB pages in the corresponding 16KB EMS page
; are now free, delete the page from the VMS chain and append it
; to the start of the free chain

	 mov	 eax,ebx	; Copy PL
	 sub	 eax,PPAGELINK	; Convert to RPN
	 mov	 esi,eax	; Save for a moment
;;;;;;;; shl	 eax,2-2	; Convert from dword to dword index
	 add	 eax,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-2	; Convert from dword to four-dword index
	 add	 esi,PGROUP:[eax] ; Plus the corresponding offset

	 mov	 eax,esi	; Copy PDT offset
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 mov	 esi,eax	; Set translated address

;;;;;;;; sh?	 esi,10-(12-2) ; Convert from 4KB in dwords to 1KB
	 add	 esi,PXMSBMAP	; Plus base address of XMS bytemap allocation table

; Check the sixteen entries in the XMSBMAP table

	 test	 PGROUP:[esi+0].EDD,@XMSB_ALLOC4 ; Izit allocated?
	 jnz	 short DEALLOCMEM_SKIP ; Jump if so

	 test	 PGROUP:[esi+4].EDD,@XMSB_ALLOC4 ; Izit allocated?
	 jnz	 short DEALLOCMEM_SKIP ; Jump if so

	 test	 PGROUP:[esi+8].EDD,@XMSB_ALLOC4 ; Izit allocated?
	 jnz	 short DEALLOCMEM_SKIP ; Jump if so

	 test	 PGROUP:[esi+12].EDD,@XMSB_ALLOC4 ; Izit allocated?
	 jnz	 short DEALLOCMEM_SKIP ; Jump if so

; Delete entry BX from the VMS chain

	 mov	 eax,PPHNDLVMS	; Get ptr to start of VMS free chain
DEALLOCMEM_NEXTVMS:
	 mov	 esi,eax	; Copy last index
	 mov	 eax,PGROUP:[esi].PL_NEXT ; Get next PL

	 cmp	 eax,ebx	; Izit our baby?
	 je	 short DEALLOCMEM_COM ; Jump if so

	 cmp	 eax,HP_LAST	; Check for end-of-the-chain
	 jne	 short DEALLOCMEM_NEXTVMS ; Jump if not

	 int	 03h		; Call our debugger

	 popf			; Restore
				; (note interrupts might become enabled)
	 stc			; Indicate we had a problem

	 jmp	 short DEALLOCMEM_EXIT ; Join common error code


; If the address in EDI is below EMMBASE, we can ignore this one
; as it's not in the EMS pool

DEALLOCMEM_INV:
	 cmp	 edi,EMMBASE	; Izit below start of EMS memory?
	 jb	 short DEALLOCMEM_SKIP ; Jump if so

	 int	 03h		; Call our debugger
DEALLOCMEM_COM:

; DS:ESI ==>	 current entry pointing to the one to delete
; EBX	 =	 PL to move

; Delete this entry from the VMS free chain

	 mov	 eax,PGROUP:[ebx].PL_NEXT ; Get this PL's next PL
	 xchg	 eax,PGROUP:[esi].PL_NEXT ; Swap with prev next PL
				; Now EAX = EBX

; Append this entry to the start of the EMS free chain

	 mov	 esi,edx	; Get ptr to next entry in EMS free chain
	 xchg	 eax,PGROUP:[esi].PL_NEXT ; Save as the new head of EMS free chain
	 mov	 PGROUP:[ebx].PL_NEXT,eax ; Point BX to prev 1st PL of EMS chain
	 mov	 edx,PGROUP:[esi].PL_NEXT ; Point to next entry for next time

; Count this EMS page into TOTPGCNT and REMPGCNT

	 inc	 TOTPGCNT	; Count it in
	 inc	 REMPGCNT	; ...
DEALLOCMEM_SKIP:
	 add	 edi,CON16KB	; Skip to next linear address

;;;;;;;; loopd	 DEALLOCMEM_NEXTPL ; Jump if more PLs to deallocate
	 dec	 ecx		; One fewer PL
	 jnz	 near ptr DEALLOCMEM_NEXTPL ; Jump if more PLs to deallocate

	 popf			; Restore
				; (note interrupts might become enabled)
	 clc			; Indicate all went well
DEALLOCMEM_EXIT:
	 popad			; Restore all EGP registers

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEALLOCMEM endp 		; End DEALLOCMEM procedure
endif				; IF @OEM_XMS or @OEM_VCPI
if @OEM_XMS or @OEM_VCPI
	 NPPROC  QRY_PGCNT -- Query Remaining Page Count
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the # available bytes on a given boundary.

Note that because this routine might be called from the
other side of the VCPI wall, we can't use any SEL_xxx variables.

On exit:

EAX	 =	 # available 1KB on the given boundary
EDX	 =	 size of largest (if @ALLOC_XMS or @ALLOC_DPMI)

|

QRYPGCNT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
QRYPGCNT_TYP dw  ?		; Allocation type (see QMAX_EMM.INC for equates)

QRYPGCNT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

QRYPGCNT_BACKSTR struc

QRYPGCNT_MSK dd  ?		; Mask for boundary
QRYPGCNT_LIM dd  ?		; Limit value
QRYPGCNT_TOT dd  ?		; Total # kilobytes
QRYPGCNT_BIG dd  ?		; Largest block

QRYPGCNT_BACKSTR ends

@QRYPGCNT_BACK equ (size QRYPGCNT_BACKSTR)


	 sub	 esp,@QRYPGCNT_BACK ; Make room for QRYPGCNT_BACKSTR

	 REGSAVE <ebx,ecx,edx,esi,edi,es> ; Save registers

	 push	 ds		; Get PGROUP data selector at PL3
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Set mask and limit values based upon allocation type

	 movzx	 ebx,[ebp].QRYPGCNT_TYP ; Get allocation type

if @OEM_VIRTUALMEM

; If this is not a query of DPMI memory, and virtual memory
; is active, drain the DPMI VMM pool into the CMP.

	 test	 VMM_FLAG,@VMM_SYSINIT ; Izit present?
	 jz	 short QRY_PGCNT_NOTDPMI ; Jump if not

	 test	 VMM_FLAG,@VMM_VCPIACTIV ; Is VCPI active?
	 jnz	 short QRY_PGCNT_NOTDPMI ; Jump if so

	 cmp	 bl,@ALLOC_DPMI ; Izit a DPMI query?
	 je	 short QRY_PGCNT_DPMI ; Jump if so (skip draining the pool)

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ecx,-1 	; The whole enchilada
	 FIXICALL IGROUP:PPM_DRAIN_POOL,DTE_CSIG ; Release free pages in page
				; pool to us
				; Returns ECX = # pages actually released
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 short QRY_PGCNT_NOTDPMI ; Join common code

	 assume  ds:PGROUP	; Tell the assembler about it
QRY_PGCNT_DPMI:
	 pushf			; Save flags
	 cli			; Disallow interrupts
	 FIXICALL IGROUP:VMM_QUERY,DTE_CSIG ; EDX <- size of largest avail
				;	     block in kb
	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_TOT,edx ; Save for later use
	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_BIG,edx ; ...

	 jmp	 QRY_PGCNT_EXIT ; Join common exit code

QRY_PGCNT_NOTDPMI:
endif				; IF @OEM_VIRTUALMEM
	 mov	 eax,ALLOC_LIM[ebx*(type ALLOC_LIM)] ; Get bit limit
	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_LIM,eax ; Save on stack
	 not	 eax		; Complement to use as mask
	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_MSK,eax ; Save on stack

; Trundle through the XMS allocation bytemap looking for contiguous
; available memory.

	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_TOT,0 ; Initialize total
	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_BIG,0 ; Initialize largest

	 mov	 ecx,XMSBMAP_LEN ; ECX = entry length of XMSBMAP

	 cmp	 bl,@ALLOC_XMS	; Izit XMS allocate?
	 jne	 short @F	; Jump if not

	 mov	 ecx,CMPSIZEXT	; Get size of EXT/XMS CMP
	 add	 ecx,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 ecx,1024	; Plus first megabyte
@@:
	 pushf			; Save flags
	 cli			; Disallow interrupts

	 xor	 ebx,ebx	; Initialize index into XMSBMAP
QRY_PGCNT_NEXT:

; Round up the starting address to the appropriate boundary

	 add	 ecx,ebx	; Add to get ending address

	 add	 ebx,[ebp-@QRYPGCNT_BACK].QRYPGCNT_LIM ; Add in limit
	 and	 ebx,[ebp-@QRYPGCNT_BACK].QRYPGCNT_MSK ; Round down
	 sub	 ecx,ebx	; Less new starting offset
	 jbe	 short QRY_PGCNT_EXIT ; Jump if no more entries

	 call	 XMS_MEMAVL	; Find next available entry
				; with EBX = starting entry #
				; ...  ECX = # remaining entries
				; Return with EBX = next available entry #
				; ...	      ECX = # remaining entries
	 jc	 short QRY_PGCNT_EXIT ; Jump if none available

	 test	 ebx,[ebp-@QRYPGCNT_BACK].QRYPGCNT_LIM ; Izit on appopriate boundary?
	 jnz	 short QRY_PGCNT_NEXT ; Jump if not

; Determine the span of available entries starting
; at EBX for no more than ECX entries

	 push	 [ebp].QRYPGCNT_TYP ; Pass allocation type
	 push	 ecx		; Pass # remaining entries
	 push	 ebx		; Pass starting offset into XMSBMAP
	 call	 XMS_MEMSPAN	; Determine the span of available entries
				; returning EDI = # consecutive available entries

	 add	 ebx,edi	; Add to get next entry #
	 sub	 ecx,edi	; Subtract out from # entries

; We're at the end of a contiguous block of available memory
; EBX	 =	 next entry # after this block
; EDI	 =	 # available entries
; ECX	 =	 # remaining entries in XMSBMAP to test

	 and	 edi,[ebp-@QRYPGCNT_BACK].QRYPGCNT_MSK ; Round down to appropriate boundary

	 add	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_TOT,edi ; Add into result

	 cmp	 edi,[ebp-@QRYPGCNT_BACK].QRYPGCNT_BIG ; Izit bigger than before?
	 jbe	 short @F	; Jump if not

	 mov	 [ebp-@QRYPGCNT_BACK].QRYPGCNT_BIG,edi ; Save as new largest
@@:
	 jecxz	 QRY_PGCNT_EXIT ; Jump if no more entries

	 jmp	 short QRY_PGCNT_NEXT ; Go around again

QRY_PGCNT_EXIT:
	 popf			; Restore flags

	 REGREST <es,edi,esi,edx,ecx,ebx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 mov	 eax,[ebp-@QRYPGCNT_BACK].QRYPGCNT_TOT ; Get total # kilobytes
if @OEM_DPMI
	 cmp	 [ebp].QRYPGCNT_TYP,@ALLOC_DPMI ; Izit DPMI allocate?
	 je	 short QRY_PGCNT_EXIT1 ; Jump if so
endif				; IF @OEM_DPMI
	 cmp	 [ebp].QRYPGCNT_TYP,@ALLOC_XMS ; Izit XMS allocate?
	 jne	 short @F	; Jump if not
QRY_PGCNT_EXIT1:
	 mov	 edx,[ebp-@QRYPGCNT_BACK].QRYPGCNT_BIG ; Get size of largest
@@:
	 mov	 esp,ebp	; Strip back the stack

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

QRY_PGCNT endp			; End QRY_PGCNT procedure
endif				; IF @OEM_XMS or @OEM_VCPI
	 NPPROC  XMS_XLAT -- Translate Non-Standard Addresses
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate non-standard addresses

These cases occur when LINKBASE is used to
direct PTE references to other than the normal ones.
For example, both PPDTCNV and PPDTUNW are non-standard
conventions to direct PTE references away from the
normal set.

On entry:

EAX	 =	 offset in PDT

On exit:

EAX	 =	 translated offset

|

; Check for PPDTCNV to PPDTCNVZ

	 cmp	 eax,PPDTCNV	; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 eax,PPDTCNVZ	; Check against upper limit
	 jae	 short @F	; Jump if too large??

	 sub	 eax,PPDTCNV	; Convert to origin-0
@@:

; Check for PPDTUNW to PPDTUNWZ

	 cmp	 eax,PPDTUNW	; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 eax,PPDTUNWZ	; Check against upper limit
	 jae	 short @F	; Jump if too large

	 sub	 eax,PPDTUNW	; Convert to origin-0
	 add	 eax,PPDT1MB	; Convert to origin-1MB
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMS_XLAT endp			; End XMS_XLAT procedure
if @OEM_EMS or @OEM_XMS or @OEM_VCPI
	 NPPROC  SET_XMSBMAP -- Set XMSBMAP Bits To Mark As Allocated
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set XMSBMAP bits to mark as allocated.

On entry:

IF	 =	 0 (interrupts disabled)

|

SETXMS_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
SETXMS_LA dd	 ?		; Starting linear address
SETXMS_LEN dd	 ?		; # entries

SETXMS_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 mov	 ecx,[ebp].SETXMS_LEN ; Get # entries

	 test	 ecx,1024-1	; Izit on 1KB boundary?
	 jnz	 short SET_XMSBMAP_ERR ; Jump if not

	 mov	 eax,[ebp].SETXMS_LA ; Get linear address

	 test	 eax,1024-1	; Izit on 1KB boundary?
	 jnz	 short SET_XMSBMAP_ERR ; Jump if not

	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 shr	 eax,10-0	; Convert from bytes to 1KB

	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE

	 lea	 ebx,[eax+ecx]	; Get 1+ending address

	 cmp	 ebx,XMSBMAP_LEN ; Check against table's byte length
	 ja	 short SET_XMSBMAP_ERR1 ; Jump if it's out of bounds

	 add	 eax,PXMSBMAP	; DS:EAX ==> XMS bytemap allocation table
	 mov	 ebx,ecx	; Copy # entries to mark
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 jz	 short SET_XMSBMAP_TAIL ; Jump if less than four entries
SET_XMSBMAP_NEXT1:
	 add	 PGROUP:[eax].EDD,@XMSB_ALLOC4 ; Mark as allocated

	 test	 PGROUP:[eax].EDD,@XMSB_FLOW4 ; Were any already allocated?
	 jnz	 short SET_XMSBMAP_ERR2 ; Jump if so

	 add	 eax,4		; Skip to next 4KB page

	 loopd	 SET_XMSBMAP_NEXT1 ; Jump if more bits to set
SET_XMSBMAP_TAIL:
	 mov	 ecx,ebx	; Copy original entry count
	 and	 ecx,4-1	; Isolate remainder modulo 4
	 jz	 short SET_XMSBMAP_EXIT ; Jump if no more entries to mark
SET_XMSBMAP_NEXT2:
	 add	 PGROUP:[eax].LO,@XMSB_ALLOC ; Mark as allocated

	 test	 PGROUP:[eax].LO,@XMSB_FLOW ; Were any already allocated?
	 jnz	 short SET_XMSBMAP_ERR3 ; Jump if so

	 inc	 eax		; Skip to next 1KB page

	 loopd	 SET_XMSBMAP_NEXT2 ; Jump if more bits to set
SET_XMSBMAP_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

SET_XMSBMAP_ERR:
	 int	 03h		; Call our debugger
SET_XMSBMAP_ERR1:
	 int	 03h		; Call our debugger
SET_XMSBMAP_ERR2:
	 int	 03h		; Call our debugger
SET_XMSBMAP_ERR3:
	 int	 03h		; Call our debugger

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_XMSBMAP endp		; End SET_XMSBMAP procedure
endif				; IF @OEM_EMS or @OEM_XMS or @OEM_VCPI
if @OEM_EMS or @OEM_XMS or @OEM_VCPI
	 NPPROC  CLR_XMSBMAP -- Clear XMSBMAP Bits To Mark As Free
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear XMSBMAP bits to mark as free.

On entry:

IF	 =	 0 (interrupts disabled)

|

CLRXMS_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
CLRXMS_LA dd	 ?		; Starting linear address
CLRXMS_LEN dd	 ?		; # entries

CLRXMS_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 mov	 ecx,[ebp].CLRXMS_LEN ; Get # entries

	 test	 ecx,1024-1	; Izit on 1KB boundary?
	 jnz	 short CLR_XMSBMAP_ERR ; Jump if not

	 mov	 eax,[ebp].CLRXMS_LA ; Get linear address

	 test	 eax,1024-1	; Izit on 1KB boundary?
	 jnz	 short CLR_XMSBMAP_ERR ; Jump if not

	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 shr	 eax,10-0	; Convert from bytes to 1KB

	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE

	 lea	 ebx,[eax+ecx]	; Get 1+ending address

	 cmp	 ebx,XMSBMAP_LEN ; Check against table's length
	 ja	 short CLR_XMSBMAP_ERR1 ; Jump if it's out of bounds

	 add	 eax,PXMSBMAP	; DS:EAX ==> XMS bytemap allocation table
	 mov	 ebx,ecx	; Copy # entries to mark
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 jz	 short CLR_XMSBMAP_TAIL ; Jump if less than four entries
CLR_XMSBMAP_NEXT1:
	 sub	 PGROUP:[eax].EDD,@XMSB_ALLOC4 ; Mark as free

	 test	 PGROUP:[eax].EDD,@XMSB_FLOW4 ; Were any already free?
	 jnz	 short CLR_XMSBMAP_ERR2 ; Jump if so

	 add	 eax,4		; Skip to next 4KB page

	 loopd	 CLR_XMSBMAP_NEXT1 ; Jump if more bits to set
CLR_XMSBMAP_TAIL:
	 mov	 ecx,ebx	; Copy original entry count
	 and	 ecx,4-1	; Isolate remainder modulo 4
	 jz	 short CLR_XMSBMAP_EXIT ; Jump if no more entries to mark
CLR_XMSBMAP_NEXT2:
	 sub	 PGROUP:[eax].LO,@XMSB_ALLOC ; Mark as free

	 test	 PGROUP:[eax].LO,@XMSB_FLOW ; Were any already free?
	 jnz	 short CLR_XMSBMAP_ERR3 ; Jump if so

	 inc	 eax		; Skip to next 1KB page

	 loopd	 CLR_XMSBMAP_NEXT2 ; Jump if more bits to set
CLR_XMSBMAP_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

CLR_XMSBMAP_ERR:
	 int	 03h		; Call our debugger
CLR_XMSBMAP_ERR1:
	 int	 03h		; Call our debugger
CLR_XMSBMAP_ERR2:
	 int	 03h		; Call our debugger
CLR_XMSBMAP_ERR3:
	 int	 03h		; Call our debugger

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_XMSBMAP endp		; End CLR_XMSBMAP procedure
endif				; IF @OEM_EMS or @OEM_XMS or @OEM_VCPI
	 NPPROC  XMS_MEMAVL -- Find Next Available Entry
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find next available entry

On entry:

EBX	 =	 starting entry #
ECX	 =	 # remaining entries

On exit:

CF	 =	 1 if none available
	 =	 0 otherwise with
EBX	 =	 next available entry #
ECX	 =	 # remaining entries

|

	 REGSAVE <ax,edi>	; Save registers

	 mov	 edi,ebx	; Get the starting entry #
	 add	 edi,PXMSBMAP	; ES:EDI ==> next entry in XMSBMAP
	 mov	 al,@XMSB_ALLOC ; Get allocated marker
XMS_MEMAVL_NEXT:
	 cmp	 ecx,0		; Ensure ZF=1 if ECX=0 for SCAS fall through
    repe scas	 PGROUP:[edi].LO ; Skip over allocated markers
	 stc			; Assume they're all allocated
	 je	 short XMS_MEMAVL_EXIT ; Jump if they're all allocated

	 test	 PGROUP:[edi-1].LO,@XMSB_ALLOC ; Izit allocated?
	 jnz	 short XMS_MEMAVL_NEXT ; Jump if so

	 dec	 edi		; Back off to starting address
	 inc	 ecx		; Count it back in

	 mov	 ebx,edi	; Copy next address
	 sub	 ebx,PXMSBMAP	; Convert to entry #

	 clc			; Indicate all went well
XMS_MEMAVL_EXIT:
	 REGREST <edi,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMS_MEMAVL endp 		; End XMS_MEMAVL procedure
	 FPPROC  FXMS_MEMSPAN -- Far Call to  XMS_MEMSPAN
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to XMS_MEMSPAN

On entry:

Same as XMS_MEMSPAN

On exit:

Same as XMS_MEMSPAN

|

FMEMSPAN_STR struc

	 dd	 ?		; Caller's CS:IP
	 dd	 ?		; Caller's EBP
FMEMSPAN_OFF dd  ?		; Starting offset into XMSBMAP
FMEMSPAN_LEN dd  ?		; # remaining entries
FMEMSPAN_TYP dw  ?		; Allocation type (see QMAX_EMM.INC for equates)

FMEMSPAN_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 es		; Save for a moment

	 push	 ds		; Get PGROUP data selector at PL3
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 [ebp].FMEMSPAN_TYP ; Pass allocation type
	 push	 [ebp].FMEMSPAN_LEN ; Pass # remaining entries
	 push	 [ebp].FMEMSPAN_OFF ; Pass starting offset into XMSBMAP
	 call	 XMS_MEMSPAN	; Determine the span of available entries
				; returning EDI = # consecutive available entries
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FXMS_MEMSPAN endp		; End FXMS_MEMSPAN procedure
	 NPPROC  XMS_MEMSPAN -- Determine Memory Span
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine the number of consecutive available entries
at a starting entry # for at most a specific # entries.

On exit:

EDI	 =	 # consecutive available entries

|

MEMSPAN_STR struc

	 dw	 ?		; Caller's IP
	 dd	 ?		; Caller's EBP
MEMSPAN_OFF dd	 ?		; Starting offset into XMSBMAP
MEMSPAN_LEN dd	 ?		; # remaining entries
MEMSPAN_TYP dw	 ?		; Allocation type (see QMAX_EMM.INC for equates)

MEMSPAN_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,ecx>	; Save registers

	 mov	 ecx,[ebp].MEMSPAN_LEN ; Get # entries we need
	 mov	 edi,[ebp].MEMSPAN_OFF ; Get starting offset into XMSBMAP
	 add	 edi,PXMSBMAP	; Plus start of XMS bytemap

	 mov	 al,0		; Get available marker
XMS_MEMSPAN_NEXT:
	 cmp	 ecx,0		; Ensure ZF=1 if ECX=0 for SCAS fall through
    repe scas	 PGROUP:[edi].LO ; Check for available memory
	 je	 short XMS_MEMSPAN_DONE ; Jump if all available

	 test	 PGROUP:[edi-1].LO,@XMSB_ALLOC ; Izit allocated?
	 jnz	 short XMS_MEMSPAN_DONE0 ; Jump if so

; There's a physical boundary discontiguity between EDI-1 and EDI.
; If that's the last block, that's OK, or
; if we're not supporting WIN3 and it's not an XMS allocate, that's OK

	 jecxz	 XMS_MEMSPAN_DONE ; Jump if there's no more entries to check

	 cmp	 [ebp].MEMSPAN_TYP,@ALLOC_XMS ; Izit XMS allocate?
	 jne	 short XMS_MEMSPAN_NEXT ; Jump if not
if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jz	 short XMS_MEMSPAN_DONE ; Jump if not
endif				; IF @OEM_WIN3
	 jmp	 short XMS_MEMSPAN_NEXT ; Go around again

XMS_MEMSPAN_DONE0:
	 dec	 edi		; Back off to last unavailable entry
XMS_MEMSPAN_DONE:
	 sub	 edi,PXMSBMAP	; Convert to origin-0
	 sub	 edi,[ebp].MEMSPAN_OFF ; Less starting offset into XMSBMAP

	 REGREST <ecx,ax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMS_MEMSPAN endp		; End XMS_MEMSPAN procedure
	 align	 4		; Ensure dword alignment
endif				; IF @OEM_XMS

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_VMM module
