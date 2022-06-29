;' $Header:   P:/PVCS/MAX/386MAX/QMAX_RSP.ASV   1.2   30 May 1997 10:45:56   BOB  $
	 title	 QMAX_RSP -- 386MAX INT 31h Resident Service Provider Routines
	 page	 58,122
	 name	 QMAX_RSP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, June 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 ECODE,EDATA
IGROUP	 group	 ICODE,IDATA
JGROUP	 group	 JCODE,JDATA


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 SEL_DSIG3:word
	 extrn	 SEL_DS3:word
	 extrn	 SEL_4GB3:word
	 extrn	 LPMSTK_FVEC:fword
	 extrn	 LPMSTK_CNT:dword
	 extrn	 PMRSP:abs
	 extrn	 DPMITYPE:byte
	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 DPMI_IDEF:word
	 extrn	 CON1P1MB:dword

	 public  TSRsize
TSRsize  dw	 ?		; For RSPs, the number of paragraphs
				; to retain when TSRing

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FSET_PPL0STK:far

ECODE	 ends			; End ECODE segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 LinearClientTop:dword
	 extrn	 LinearBottom:dword
	 extrn	 LinearClientBottom:dword

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 FDPMIFN_CHKACCESS:far
	 extrn	 FLSM_ALLOC:far
	 extrn	 FVMM_RELOCATE_BLOCK:far
	 extrn	 FVMM_FREE:far
	 extrn	 FLSM_SETN_PTES:far
	 extrn	 FGET_LDT:far
	 extrn	 INT21_DPMI_EXITRC:near

ICODE	 ends			; End ICODE segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 public  RSPs
RSPs	 RSPdata @MAX_RSPS dup (<>) ; Declare RSP strucs

; The order in which RSPs are installed is significant because we must call
; the initialization callbacks in the same order, and we must call the
; termination callbacks in the reverse order.  Therefore, we need to keep
; them in a doubly linked list.

	 public  RSPhead,RSPtail
RSPhead  dw	 -1		; Offset in JGROUP of head of forward list
RSPtail  dw	 -1		; ...		      ...     reverse ...

JDATA	 ends			; End JDATA segment


COMMENT *
The data structure tracking RSPs is defined as follows:

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


RSPbits record	$RSPdefined:1,$RSP1stTerm:1

 Field		Meaning when set
----------------------------------------
 $RSPdefined	RSP defined, structure in use
 $RSP1stTerm	New RSP, do not call when terminating


An array of these (RSPs) is kept in JGROUP, and initialized to zero by
RSP_INIT.  In addition, they are kept in a doubly linked list corresponding
to the order in which they were installed.  This is necessary because
when a client starts, the RSPs must be called in order, and when a client
terminates they must be called in reverse order.  RSPhead and RSPtail
variables mark the start and end of the two lists.  The RSP_next and RSP_prev
members of the RSPdata struc provide storage for the links.

The RSP_flags member marks an entry in the RSPs array as in use
($RSPdefined), or as a new RSP ($RSP1stTerm).  The latter is needed
because we do not want to call an RSP to inform it of its own
termination when it first installs.

The RSP_usecount member tracks how many clients the RSP is currently
attached to.  RSPs attach to all clients that initialize after the RSP
is installed, provided that the RSP supports the client's bitness.

The next four entries hold the code and data descriptors for the 16 and
32 bit segments defined by the RSP. RSP_cb32 and RSP_cb16 are the offsets
in the 32 and 16 bit code segments where the RSP callback resides.  These
fields are zero if the RSP does not support the indicated bitness.

The RSP_selectors member is array of selectors, one for each possible
client in the system.  The entry for a given client is the first of
four contiguous selectors that map the RSP segments.

RSP_regions is a set of four pairs of dwords. Each pair is the base
address and size in pages of a shared memory region. There is one
such memory region for each of the RSPs four segments.	In practice,
an RSP may map all four of its segments to the same memory region.
The RSP_regions array is a reduced set to filter out all overlap.
The memory segments specified by an install RSP call are eventually
copied to shared memory.  If there are overlapping regions defined by
an RSP, they must be combined so that only the necessary shared memory
is allocated. This analysis of how the memory regions specified by the
RSP overlap requires a large amount of code in qmax_rsp.asm.  Note
that when there is overlap, there will be less than four regions
(there will always be at least one).  When there are less than four,
the unused regions have size of zero.


* ; end comment



JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 public  @QMAX_RSP_JCODE
@QMAX_RSP_JCODE:		; Mark module start in .MAP file

	 FPPROC  FRSP_INIT -- System Initialization of RSPs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize static data for Resident Service Providers

|
	 REGSAVE <ax,cx,di,es>	; Save registers

	 mov	 ax,DTE_DSJG	; Get JGROUP data selector
	 mov	 es,ax		; load in to ES
	 assume  es:JGROUP	; tell assembler

	 mov	 ax,-1		; Get initial marker
	 mov	 RSPhead,ax	; Init forward list head
	 mov	 RSPtail,ax	; ...  reverse ...

	 mov	 cx,size RSPs	; Prepare to zap array
	 xor	 al,al		; Array fill value
	 lea	 di,RSPs	; Point to RSP strucs
	 cld			; Forward
     rep stos	 RSPs[di].LO	; Zap array

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FRSP_INIT endp			; End FRSP_INIT procedure
	 NPPROC  RSP_ALLOC -- Alloc a RSP struc from array
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Does a linear search on the RSPs array, looking for an element that is
available.

On exit:

AX	 =	-1 if none was found
	 =	offset in JGROUP of RSPdata struc

|

	 REGSAVE <bx,cx,si,ds>	; Save registers

	 mov	 ax,DTE_DSJG	; Get JGROUP data selector at PL0
	 mov	 ds,ax		; Address it
	 assume  ds:JGROUP	; Tell the assembler about it

	 lea	 si,RSPs	; Get base of RSPs array
	 mov	 cx,@MAX_RSPS	; Init counter
RSP_ALLOC_NEXT: 		; Look for a free one
	 bts	 JGROUP:[si].RSP_flags, $RSPdefined ; is this one avail?
	 jnc	 short RSP_ALLOC_INIT ; jump if so

	 add	 si,type RSPdata ; Advance to next record

	 dec	 cx		; Decrement count of RSPs left to check
	 jnz	 short RSP_ALLOC_NEXT ; Jump if more

	 mov	 si,-1		; Didn't find an available one

	 jmp	 short RSP_ALLOC_EXIT ; Return error

RSP_ALLOC_INIT: 	; Init the new RSP record
	 mov	 JGROUP:[si].RSP_usecount,0 ; Clear use count

	 mov	 bx,RSPtail	; Get tail of list

	 cmp	 bx,-1		; Is list empty?
	 je	 short RSP_ALLOC_NEWLIST ; Jump if so

	 mov	 JGROUP:[bx].RSP_next,si ; Link this record to old tail
	 mov	 JGROUP:[si].RSP_next,-1 ; Mark this record as new tail
	 mov	 JGROUP:[si].RSP_prev,bx ; Old tail is prev of new tail
	 mov	 RSPtail,si	; Set new tail

	 jmp	 short RSP_ALLOC_EXIT

RSP_ALLOC_NEWLIST:		; Here if new record is first in list
	 mov	 RSPhead,si	; Set new head
	 mov	 RSPtail,si	; ...	  tail
	 mov	 JGROUP:[si].RSP_next,-1; nothing ahead
	 mov	 JGROUP:[si].RSP_prev,-1; nothing behind
RSP_ALLOC_EXIT:
	 mov	 ax,si		; Return pointer in ax

	 REGREST <ds,si,cx,bx>	; Restore regs
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RSP_ALLOC endp			; End RSP_ALLOC procedure
	 FPPROC  FDPMI_TSRSRV -- DPMI 1.0 Function to Install RSP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to install a Resident Service Provider

FDPMI_TSRSRV registers an RSP.	To do this, it validates the segments
passed in by the client, and copies the information to the TSS
(DPTSS_VMM_RSP_xxxx).

On entry (in INTXX_STR):

AX	=	0C00h
ES:eDI	=	selector:offset of 40-byte buffer in INST_RSP_STR.

On exit:

CF	=	0 success
CF	=	1 error
AX	=	8021 bad descriptor bits
	=	8025 bad linear addresses in descriptors
	=	8015 couldn't allocate callback

|

INST_RSP_STR struc

INSTRSP_DATA16	dq ?		; 16-bit data desc
INSTRSP_CODE16	dq ?		; 16-bit code desc
INSTRSP_ENTRY16 dw ?		; Offset of 16-bit callback
		dw ?		; Reserved
INSTRSP_DATA32	dq ?		; 32-bit data desc
INSTRSP_CODE32	dq ?		; 32-bit code desc
INSTRSP_ENTRY32 dd ?		; Offset of 32-bit callback

INST_RSP_STR ends

; Get the address of the data structure to ES:ESI

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 esi,[ebp].INTXX_EDI ; Get offset of struc
	 IF16ZX  si		; Zero to use as dword if 16-bit client

; We must validate each of the descriptors passed in

	 mov	 edx,-1 	; No entry point
	 lea	 ebx,es:[esi].INSTRSP_DATA16 ; Get data-16 desc addr
	 call	 DPMIFN_VALIDATE_RSP_DESC ; Check it out
	 jc	 near ptr FDPMI_TSRSRV_ERR ; Jump if it failed

	 movzx	 edx,es:[esi].INSTRSP_ENTRY16 ; Load code entry offset
	 lea	 ebx,es:[esi].INSTRSP_CODE16 ; Get code-16 desc addr
	 call	 DPMIFN_VALIDATE_RSP_DESC ; Check it out
	 jc	 near ptr FDPMI_TSRSRV_ERR ; Jump if it failed

	 mov	 edx,-1 	; No entry point
	 lea	 ebx,es:[esi].INSTRSP_DATA32 ; Get data-32 desc addr
	 call	 DPMIFN_VALIDATE_RSP_DESC ; Check it out
	 jc	 near ptr FDPMI_TSRSRV_ERR ; Jump if it failed

	 mov	 edx,es:[esi].INSTRSP_ENTRY32 ; Load code entry offset
	 lea	 ebx,es:[esi].INSTRSP_CODE32 ; Get code-32 desc addr
	 call	 DPMIFN_VALIDATE_RSP_DESC ; Check it out
	 jc	 near ptr FDPMI_TSRSRV_ERR ; Jump if it failed

; Here if all check out ok. Now copy the information to the TSS.

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of the current TSS

	 mov	 eax,es:[esi].INSTRSP_DATA16.EDQLO ; Get low half data16 desc
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_data16.EDQLO,eax ; Store in TSS
	 mov	 eax,es:[esi].INSTRSP_DATA16.EDQHI ; Get hi half ...
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_data16.EDQHI,eax ; ...

	 mov	 eax,es:[esi].INSTRSP_CODE16.EDQLO ; Get low half code16 desc
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_code16.EDQLO,eax ; Store in TSS
	 mov	 eax,es:[esi].INSTRSP_CODE16.EDQHI ; Get hi half ...
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_code16.EDQHI,eax ; ...

	 mov	 eax,es:[esi].INSTRSP_DATA32.EDQLO ; Get low half data32 desc
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_data32.EDQLO,eax ; Store in TSS
	 mov	 eax,es:[esi].INSTRSP_DATA32.EDQHI ; Get hi half ...
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_data32.EDQHI,eax ; ...

	 mov	 eax,es:[esi].INSTRSP_CODE32.EDQLO ; Get low half code32 desc
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_code32.EDQLO,eax ; Store in TSS
	 mov	 eax,es:[esi].INSTRSP_CODE32.EDQHI ; Get hi half ...
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_code32.EDQHI,eax ; ...

	 mov	 eax,es:[esi].INSTRSP_ENTRY32  ; Get- callback 32 offset
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_cb32,eax ; Store in TSS

	 mov	 ax,es:[esi].INSTRSP_ENTRY16   ; Get callback 16 offset
	 mov	 PGROUP:[ebx].DPTSS_VMM_RSP_cb16,ax ; Store in TSS

; Mark client as a registered RSP

	 or	 PGROUP:[ebx].DPTSS_VMM_Flags,mask $vciRSP_registered

	 clc			; Flag success

	 ret			; Return to caller

FDPMI_TSRSRV_ERR:
	 stc			; Flag error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_TSRSRV endp		; End DPMI_TSRSRV procedure
	 NPPROC  DPMIFN_VALIDATE_RSP_DESC -- Validate descriptor for RSP usage
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Used by DPMI_TSRSRV to validate descriptors

On entry:

ES:EBX	 =	 address of 8-byte descriptor
EDX	 =	 for code segments, the offset of the entry point
	 =	 for data segments, -1

On exit:

CF	 =	 0 descriptor is OK (or all zeros)
	 =	 1 descriptor not acceptable
AX	 =	 appropriate DPMI error code
		   8021    bad value
		   8025    bad linear address

|

	 REGSAVE <ecx,fs>	; Save registers

	 mov	 fs,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  fs:IGROUP	; Tell the assembler about it

; First check for all zeros in the descriptor

	 cmp	 es:[ebx].EDQLO,0 ; Is first dword zero?
	 jne	 short @F	; Jump if not

	 cmp	 es:[ebx].EDQHI,0 ; Is second dword zero?
	 je	 near ptr DPMIFN_VALIDATE_RSP_OK ; Jump out if all zero
@@:

; Validate access byte

	 mov	 al,es:[ebx].DESC_ACCESS ; Pick up arb byte
	 FIXICALL IGROUP:FDPMIFN_CHKACCESS,DTE_CSIG ; Call standard checker
	 jc	 near ptr DPMIFN_VALIDATE_RSP_BADVAL ; Bail on fail

; Get base of segment to EAX

	 mov	 eax,es:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,es:[ebx].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

; Get size of segment to ECX

	 mov	 cl,es:[ebx].DESC_SEGLM1 ; Get bits 16-19
	 and	 cx,mask $SEGLM1 ; Isolate the limit bits, zero high-order byte
	 shl	 ecx,16 	; Shift to high-order word
	 mov	 cx,es:[ebx].DESC_SEGLM0 ; Pull in low bits

	 test	 es:[ebx].DESC_SEGLM1,mask $DTE_G ; Test Granularity bit
	 jz	 short @F	; Jump if byte granular

	 shl	 ecx,@BytePage	; Convert to pages
	 or	 ecx,@PageSize-1 ; Set low bits
@@:
	 inc	 ecx		; Convert from limit to length

; If it's not a code or data selector, exit now

	 test	 es:[ebx].DESC_ACCESS,mask $DT_DC ; Is it code or data?
	 jz	 short DPMIFN_VALIDATE_RSP_BADVAL ; Jump if not

; If it's a code segment, make sure arb is correct and entry point within
; bounds.

	 cmp	 edx,-1 	; Is it supposed to be code?
	 je	 short @F	; Jump if not

	 test	 es:[ebx].DESC_ACCESS,mask $DC_COD ; Is it code?
	 jz	 short DPMIFN_VALIDATE_RSP_BADVAL ; Jump if data

	 cmp	 edx,ecx	; Is it within bounds
	 jae	 short DPMIFN_VALIDATE_RSP_BADVAL ; Jump if not
@@:

; We now have base in EAX and length in ECX.

	 add	 ecx,eax	; ECX is now top of region

; If base is below 1MB+64K, then entire block must be below same

	 cmp	 eax,CON1P1MB	; Compare base to bound
	 ja	 short @F	; Jump if not in low meg

	 cmp	 ecx,CON1P1MB	; Compare to top bound
	 jbe	 short DPMIFN_VALIDATE_RSP_OK ; Success if below or equal

	 jmp	 short DPMIFN_VALIDATE_RSP_BADADDR; else fail it

@@:

; If base above 1MB+64K, then it must be at least LinearBottom, which is the
; beginning of the DPMI managed area

	 cmp	 eax,LinearBottom ; Compare base to bound
	 jb	 short DPMIFN_VALIDATE_RSP_BADADDR ; Fail if below DPMI area

; If base is below LinearClientBottom, i.e. it is in the shared region,
; then the entire range must be in the shared region.

	 cmp	 eax,LinearClientBottom ; Compare base to bound
	 ja	 short @F	; Jump if not in shared region

	 cmp	 ecx,LinearClientBottom ; Is it in shared region?
	 jbe	 short DPMIFN_VALIDATE_RSP_OK ; Jump if so

	 jmp	 short DPMIFN_VALIDATE_RSP_BADADDR ; Else fail it

@@:

; If above shared region, then it must be contained within the client area.

	 cmp	 ecx,LinearClientTop ; Are we in bounds?
	 ja	 short DPMIFN_VALIDATE_RSP_BADADDR ; Fail if not
DPMIFN_VALIDATE_RSP_OK:
	 clc			; Flag success
DPMIFN_VALIDATE_RSP_EXIT:
	 REGREST <fs,ecx>	; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

DPMIFN_VALIDATE_RSP_BADVAL:	; Invalid value error
	 mov	 ax,8021h	; Error return value

	 stc			; Flag error

	 jmp	 DPMIFN_VALIDATE_RSP_EXIT ; Join common exit

DPMIFN_VALIDATE_RSP_BADADDR:	; Invalid linear address err
	 mov	 ax,8025h	; Error return value

	 stc			; Flag error

	 jmp	 DPMIFN_VALIDATE_RSP_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_VALIDATE_RSP_DESC endp	; End DPMIFN_VALIDATE_RSP_DESC procedure
	 FPPROC  FDPMI_TSRXIT -- DPMI 1.0 Function to Terminate and Stay Res
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to terminate and stay resident

On entry (in INTXX_STR):

AX	=	0C01h
BL	=	return code
DX	=	number of DOS paragraphs to keep (may be zero)

|

	 mov	 es,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

; The client has requested to TSR. Make sure the client is a registered RSP.

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS

	 test	 PGROUP:[eax].DPTSS_VMM_Flags,mask $vciRSP_registered
	 jz	 DPMI_TSRXIT_TERMINATE ; Just kill it if not reg'ed

; Now make sure the client supports at least one bitness

	 cmp	 PGROUP:[eax].DPTSS_VMM_RSP_code16.DESC_ACCESS,0
	 jne	 short @F	; Jump if 16-bit supported

	 cmp	 PGROUP:[eax].DPTSS_VMM_RSP_code32.DESC_ACCESS,0
	 je	 near ptr DPMI_TSRXIT_TERMINATE ; Bail out if neither
				; Fall through if 32-bit supported
@@:

; Any of the to-be-resident segments must reside in memory regions common
; to all clients, namely either the region below 1MB or in the shared region
; between LinearBottom and LinearClientBottom.	Furthermore, the segments
; that we are making resident may overlap, and we must preserve that overlap
; correctly when doing the relocation.	We determined at the registration
; call that the resident segments each individually reside within a single
; region of our page map (i.e., each is fully contained in either the low,
; client, or shared area). What we must do now is relocate segments in the
; client area to the shared area.  We first normalize the segments to
; page boundaries and compute the segment sizes in pages, then build an array
; of all resident segments with their page sizes.

NormalizedRSPSegment struc

NRSPS_base dd	 ?		; Orig base linear address
NRSPS_size dd	 ?		; Size in pages

NormalizedRSPSegment ends

	 sub	 esp,4*(type NormalizedRSPSegment) ; Alloc array on stack
	 mov	 ebx,esp	; EBX will be pointer to array

; Normalize each descriptor to the local array

	 lea	 esi,PGROUP:[eax].DPTSS_VMM_RSP_code16 ; Code 16 desc
	 lea	 edi,ss:[ebx+0*(type NormalizedRSPSegment)] ; Get target
	 call	 DPMIFN_NORMALIZE_RSPSEG ; Extract values

	 lea	 esi,PGROUP:[eax].DPTSS_VMM_RSP_data16 ; Data 16 desc
	 lea	 edi,ss:[ebx+1*(type NormalizedRSPSegment)] ; Get target
	 call	 DPMIFN_NORMALIZE_RSPSEG ; Extract values

	 lea	 esi,PGROUP:[eax].DPTSS_VMM_RSP_code32 ; Code 32 desc
	 lea	 edi,ss:[ebx+2*(type NormalizedRSPSegment)] ; Get target
	 call	 DPMIFN_NORMALIZE_RSPSEG ; Extract values

	 lea	 esi,PGROUP:[eax].DPTSS_VMM_RSP_data32 ; Data 32 desc
	 lea	 edi,ss:[ebx+3*(type NormalizedRSPSegment)] ; Get target
	 call	 DPMIFN_NORMALIZE_RSPSEG ; Extract values

; Now we remove overlapping regions by comparing each pair of segments,
; and adjusting each accordingly.  This insures that we copy the minimum
; amount of linear space and preserve the correct overlapping of the
; linear memory as specified by the registration call.

removeOverlap macro seg1,seg2	; Start macro definition

	 lea	 esi,ss:[ebx + (seg1)*(size NormalizedRSPSegment)]
	 lea	 edi,ss:[ebx + (seg2)*(size NormalizedRSPSegment)]
	 call	 DPMIFN_REMOVE_OVERLAP

	 endm			; End of macro definition

	 removeOverlap 0,1	; reduce code 16, data 16
	 removeOverlap 0,2	; reduce code 16, code 32
	 removeOverlap 0,3	; reduce code 16, data 32
	 removeOverlap 1,2	; reduce data 16, code 32
	 removeOverlap 1,3	; reduce data 16, data 32
	 removeOverlap 2,3	; reduce code 32, data 32

; The array of normalized segments pointed to by ebx is now properly
; adjusted, and we can now relocate any of the segments that reside
; in the client area.

	 mov	 esi,ebx	; ESI will point to array
	 mov	 edi,esi	; Hold array addr in edi as well
	 mov	 cx,4		; CX <- count of segments to move
DPMI_TSRXIT_RELOC_NEXT:

; Only move segments in the client area

	 mov	 eax,ss:[esi].NRSPS_base ; Get base address of segment

	 cmp	 eax,LinearClientBottom ; Is it in client region?
	 jb	 short DPMI_TSRXIT_ADVANCE ; Jump if not

	 cmp	 ss:[esi].NRSPS_size,0	; Is size non-zero?
	 je	 short DPMI_TSRXIT_ADVANCE ; Jump if so

; We have a non-zero segment in the client area, so allocate some shared
; linear memory and move it there.

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 xor	 eax,eax	; Any old address will do
	 mov	 ebx,ss:[esi].NRSPS_size ; Number of pages to allocate
	 mov	 edx,(mask $commit) or (mask $shared) ; Get shared committed pages
	 FIXICALL IGROUP:FLSM_ALLOC,DTE_CSIG ; Try for the linear space
				; Return with CF significant
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 short @F	; Jump if alloc of linear space OK

	 add	 esp,4*(type NormalizedRSPSegment) ; Dealloc array on stack

	 jmp	 DPMI_TSRXIT_TERMINATE	; Sorry, no linear space, you die

@@:

; The address of the new linear space is in eax. Now relocate the segment.

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Need ds=IGROUP
	 assume  ds:IGROUP	; Tell the assembler about it

	 push	 ss:[esi].NRSPS_size ; Number of pages to relocate
	 push	 eax		; The destination address
	 push	 ss:[esi].NRSPS_base ; The source address
	 FIXICALL IGROUP:FVMM_RELOCATE_BLOCK,DTE_CSIG ; Move to shared region

	 call	 DPMIFN_RELOC_ZERO_SEGMENT ; Move any segments that had been
				; overlapping

	 push	 eax		; Save new linear address
	 push	 ecx		; Save counter

; Mark the pages that were copied as unallocated so that they are not
; released when the client terminates.

	 mov	 eax,ss:[esi].NRSPS_base ; EAX <- orig addr of region
	 mov	 ebx,ss:[esi].NRSPS_size ; Number of pages to clear
	 mov	 ecx,@PGBITS_UNALLOC ; New PTE value
	 FIXICALL IGROUP:FLSM_SETN_PTES,DTE_CSIG ; Set the PTEs to unallocated

	 pop	 ecx		; Restore counter

	 pop	 ss:[esi].NRSPS_base ; Record new base in local array
	 pop	 ds		; Get PGROUP back
	 assume  ds:PGROUP	; Tell the assembler about it
DPMI_TSRXIT_ADVANCE:
	 add	 esi,size NormalizedRSPSegment ; Point to next segment

	 dec	 cx		; Dec count remaining
	 jnz	 DPMI_TSRXIT_RELOC_NEXT ; Go get next if more to do

; Now we update the base addresses of the RSP segments in the TSS, so
; that we will be able to build the descriptors at the time of the callback.


RSP_SetBase macro base,desc	; Start macro definiton

	 mov	edx,base	; Pick up the new base
	 mov	cx,desc.desc_base01 ; Get original base - low word
	 and	cx,@PageSize-1	; Save page offset
	 or	dx,cx		; Add to new base
	 mov	desc.desc_base01,dx ; Set new base - low word
	 shr	edx,16		; Shift high base to DX
	 mov	desc.desc_base2,dl ; Set new base byte 2
	 mov	desc.desc_base3,dh ; ...	       3

	 endm

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 sub	 esi,size NormalizedRSPSegment ; point to last array entry
	 RSP_SetBase ss:[esi].NRSPS_base, PGROUP:[eax].DPTSS_VMM_RSP_data32

	 sub	 esi,size NormalizedRSPSegment ; point to previous segment
	 RSP_SetBase ss:[esi].NRSPS_base, PGROUP:[eax].DPTSS_VMM_RSP_code32

	 sub	 esi,size NormalizedRSPSegment ; point to previous segment
	 RSP_SetBase ss:[esi].NRSPS_base, PGROUP:[eax].DPTSS_VMM_RSP_data16

	 sub	 esi,size NormalizedRSPSegment ; point to previous segment
	 RSP_SetBase ss:[esi].NRSPS_base, PGROUP:[eax].DPTSS_VMM_RSP_code16

; Allocate a RSP struc from the static array. The call links it into the
; list and initializes the use count.

	 call	 RSP_ALLOC	; Get an RSP struc

	 cmp	 ax,-1		; Did it succeed?
	 je	 DPMI_TSRXIT_TERMINATE ; Jump if not

	 mov	 si,ax		; SI <- pointer to RSP struc

	 mov	 ax,DTE_DSJG	; Get JGROUP data selector at PL0
	 mov	 fs,ax		; FS=JGROUP to access RSPs
	 assume  fs:JGROUP	; Tell the assembler about it

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS

; Now copy the data from the TSS to the RSP struc

	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_code16.EDQLO ; Get code 16 desc
	 mov	 JGROUP:[si].RSP_code16.EDQLO,edx ; Store in RSP struc
	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_code16.EDQHI ; ...
	 mov	 JGROUP:[si].RSP_code16.EDQHI,edx ; ...

	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_code32.EDQLO ; Get code 32 desc
	 mov	 JGROUP:[si].RSP_code32.EDQLO,edx ; Store in RSP struc
	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_code32.EDQHI ; ...
	 mov	 JGROUP:[si].RSP_code32.EDQHI,edx ; ...

	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_data16.EDQLO ; get data 16 desc
	 mov	 JGROUP:[si].RSP_data16.EDQLO,edx ; Store in RSP struc
	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_data16.EDQHI ; ...
	 mov	 JGROUP:[si].RSP_data16.EDQHI,edx ; ...

	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_data32.EDQLO ; Get data 32 desc
	 mov	 JGROUP:[si].RSP_data32.EDQLO, edx    ; Store in RSP struc
	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_data32.EDQHI ; ...
	 mov	 JGROUP:[si].RSP_data32.EDQHI, edx  ; ...

	 mov	 edx,PGROUP:[eax].DPTSS_VMM_RSP_cb32 ; Get 32-bit callback
	 mov	 JGROUP:[si].RSP_cb32,edx ; Store in RSP struc
	 mov	 dx,PGROUP:[eax].DPTSS_VMM_RSP_cb16 ; ...
	 mov	 JGROUP:[si].RSP_cb16,dx ; ...

; When the RSP terminates, normal RSP processing is in effect. We do not
; want to inform the RSP of its own termination, so we set a flag in the
; RSP structure to indicate this state.  This flag will be cleared when the
; RSP terminates.

	 or	 JGROUP:[si].RSP_flags,mask $RSP1stTerm ; Flag first termination

; Now copy the normalized segments into the RSP structure. We will need them
; when we free the RSP.  The bases of the normalized segments now reflect
; any relocations we have done.

	 lea	 edi,JGROUP:[si].RSP_regions ; EDI <- destination
	 mov	 esi,esp	; Get ptr to NormRSPSegment

	 push	 es		; Save for a moment

	 push	 fs		; Move to ES thru stack
	 pop	 es		; ES <- JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 mov	 ecx,4*size NormalizedRSPSegment ; Byte count to move
S32  rep movs	 <JGROUP:[edi].LO,ss:[esi].LO> ; Copy segments

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler about it

; Discard the normalized segment array

	 add	 esp,4*(type NormalizedRSPSegment) ; Dealloc array on stack

; The termination routine expects the return code to be found in al; since
; we have it in bl, move it over

	 mov	 al,[ebp].INTXX_EBX.ELO.LO ; Get return code
	 mov	 [ebp].INTXX_EAX.ELO.LO,al ; Put it where expected

; If the client has TSRed with a non-zero value in DX (the number of
; DOS paragraphs to keep), we need to save the paragraph count in a
; global location where the termination routine can test it.

	 mov	 ax,[ebp].INTXX_EDX.ELO ; Get para count
	 mov	 TSRsize,ax	; Save it for exit code
DPMI_TSRXIT_TERMINATE:
	 push	 ss		; Set up ES for terminate
	 pop	 es		; ES=PGROUP
	 assume  es:PGROUP	; Tell the assembler about it

	 FIXIJMP IGROUP:INT21_DPMI_EXITRC,DTE_CSIG ; terminate the client

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_TSRXIT endp		; End FDPMI_TSRXIT procedure
	 NPPROC  DPMIFN_NORMALIZE_RSPSEG -- Utility function for RSP call
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Extract base and size of descriptor; convert to page values

On entry:

DS:ESI	 ==>	 Source descriptor
SS:EDI	 ==>	 NormalizedRSPSegment to be filled in

|

	 REGSAVE <eax,ecx>	; Save registers

; Get base of segment to EAX

	 mov	 eax,ds:[esi].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,ds:[esi].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

; Get size of segment to ECX

	 mov	 cl,ds:[esi].DESC_SEGLM1 ; Get bits 16-19
	 and	 cx,mask $SEGLM1 ; Isolate the limit bits, zero high-order byte
	 shl	 ecx,16 	; Shift to high-order word
	 mov	 cx,ds:[esi].DESC_SEGLM0 ; Pull in low bits

	 test	 ds:[esi].DESC_SEGLM1,mask $DTE_G ; Test Granularity bit
	 jz	 short @F	; Jump if byte granular

	 shl	 ecx,@BytePage	; Convert to pages
	 or	 ecx,@PageSize-1 ; Set low bits
@@:

; We now have base in EAX and limit in ECX.

	 add	 ecx,eax	; Ecx is now top of region

	 add	 ecx,@PageSize	; Start round up to page
	 and	 cx,not (@PageSize-1) ; Complete round off

	 and	 ax,not (@PageSize-1) ; Round base down to page
	 sub	 ecx,eax	; ECX <- size in bytes
	 shr	 ecx,@BytePage	; ECX <- size in pages

	 mov	 ss:[edi].NRSPS_base,eax ; Set base in output struc
	 mov	 ss:[edi].NRSPS_size,ecx ; ... size ...

	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_NORMALIZE_RSPSEG endp	; End DPMIFN_NORMALIZE_RSPSEG procedure
	 NPPROC  DPMIFN_REMOVE_OVERLAP -- Utility function for RSP call
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Remove overlapping region of two segments, if any, by setting the length
of one of the two overlapping segments such that it includes both, and
setting the length of the other segment to zero.

On entry:

SS:ESI	 ==>	 the first segment (NormalizedRSPSegment)
SS:EDI	 ==>	 the second segment (NormalizedRSPSegment)

|

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

	 mov	 eax,ss:[esi].NRSPS_base       ; eax <- base of 1st seg
	 mov	 ebx,ss:[esi].NRSPS_size       ; ebx <- size of 1st (pages)
	 shl	 ebx,@BytePage		       ; ebx <- size of 1st (bytes)
	 add	 ebx,eax		       ; ebx <- end of 1st seg

	 mov	 ecx,ss:[edi].NRSPS_base       ; ecx <- base of 2nd seg
	 mov	 edx,ss:[edi].NRSPS_size       ; edx <- size of 2nd (pages)
	 shl	 edx,@BytePage		       ; edx <- size of 2nd (bytes)
	 add	 edx,ecx		       ; edx <- end of 2nd seg

; Test if the segments are disjoint

	 cmp	 ebx,ecx			; if end of 1 < begin of 2
	 jbe	 short DPMIFN_RO_EXIT		; they are disjoint - done

	 cmp	 edx,eax			; if end of 2 < begin of 1
	 jbe	 short DPMIFN_RO_EXIT		; they are disjoint - done

; Test if segment 1 contained within segment 2

	 cmp	 ecx,eax			; if beg of 2 > beg of 1
	 ja	 short @F			; jump - seg 1 not contained

	 cmp	 ebx,edx			; if end of 1 < end of 2
	 ja	 short @F			; jump - seg 1 not contained

	 mov	 ss:[esi].NRSPS_size,0		; seg 1 contained - kill it

	 jmp	 short DPMIFN_RO_EXIT		; done

@@:

; Test if segment 2 contained within segment 1

	 cmp	 eax,ecx			; if beg of 1 > beg of 2
	 ja	 short @F			; jump - seg 2 not contained

	 cmp	 edx,ebx			; if end of 1 < end of 2
	 ja	 short @F			; jump - seg 2 not contained

	 mov	 ss:[edi].NRSPS_size,0		; seg 2 contained - kill it

	 jmp	 short DPMIFN_RO_EXIT		; done

@@:

; Here if not disjoint, non contained - must overlap

	 cmp	 eax,ecx			; test if 1 runs into 2
	 jae	 short @F			; jump if not

; 1 runs over 2. Set size of 1 so it includes 2. Zero out 2.

	 sub	 edx,eax			; edx = end of 2 - beg of 1
	 shr	 edx, @BytePage 		; convert to pages
	 mov	 ss:[esi].NRSPS_size,edx	; set new size of 1
	 mov	 ss:[edi].NRSPS_size,0		; zero out second segment

	 jmp	 short DPMIFN_RO_EXIT		; done

@@:
; 2 runs over 1. Set size of 2 so it includes 1. Zero out 1.

	 sub	 ebx,ecx			; ebx = end of 1 - beg of 2
	 shr	 ebx, @BytePage 		; convert to pages
	 mov	 ss:[edi].NRSPS_size,ebx	; set new size of 2
	 mov	 ss:[esi].NRSPS_size,0		; zero out first segment
DPMIFN_RO_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_REMOVE_OVERLAP endp	; End DPMIFN_REMOVE_OVERLAP procedure
	 NPPROC  DPMIFN_RELOC_ZERO_SEGMENT -- Relocate overlapped segment
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

We have an array of normalized segments on the stack that we are in the
process of relocating.	Previously, we have reduced this array of segments
such that, for any pair of segments that overlapped, one of the pair now
has zero length and the length of the other is set to include the zeroed one.

The problem is that we have to build descriptors based on the relocated
bases, so the bases of those segments that overlapped and have been set
to length zero must now be relocated along with the segment that includes
them.

On entry:

SS:EDI	=	base of normalized segment array
SS:ESI	=	newly relocated normalized segment (still with old base)
EAX	=	new base

On exit:

Segment array updated.

|
	 REGSAVE <eax,ebx,ecx,edx,edi>		; save regs

	 mov	 cx,4				; init segment counter

	 mov	 edx, ss:[esi].NRSPS_base	; get old base
	 mov	 ebx, ss:[esi].NRSPS_size	; get size
	 shl	 ebx, @BytePage 		; convert size to bytes
	 add	 ebx, edx			; ebx <- old end of segment
	 sub	 eax, edx			; edx <- relocation delta

DPMIFN_RZS_NEXT:
	 cmp	 esi, edi			; is current the reloc'ed one?
	 je	 short DPMIFN_RZS_ADVANCE	; skip if so

	 cmp	 ss:[edi].NRSPS_size,0		; is this an overlapped one?
	 jne	 short DPMIFN_RZS_ADVANCE	; skip if not

	 cmp	 ss:[edi].NRSPS_base,edx	; did base lie below this one?
	 jb	 short DPMIFN_RZS_ADVANCE	; skip if so

	 cmp	 ss:[edi].NRSPS_base,ebx	; did base lie above this one?
	 jae	 short DPMIFN_RZS_ADVANCE	; skip if so

	 add	 ss:[edi].NRSPS_base,eax	; ok, apply relocation delta
DPMIFN_RZS_ADVANCE:
	 add	 edi,type NormalizedRSPSegment ; Point to next segment

	 loop	 DPMIFN_RZS_NEXT ; Get next if more

	 REGREST <edi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_RELOC_ZERO_SEGMENT endp	; End DPMIFN_RELOC_ZERO_SEGMENT procedure
	 FPPROC  DPMIFN_CALL_RSPS - Call Resident Service Providers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT |

Call all Resident Service Providers

On entry:

AH	=	0	Initialization call
	=	1	Termination call
AL	=	0	16-bit client
	=	1	32-bit client
|
	 REGSAVE <ds,es,fs,gs>		; save seg regs
	 pushad 			; save all regs

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_DSJG	; Get JGROUP data selector at PL0
	 pop	 es		; Set up ES with JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 mov	 fs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  fs:AGROUP	; Tell the assembler about it

; For initialization calls, we call the RSPs in the order that they were
; installed; for termination calls, in the reverse order.

	 or	 ah,ah		; Is this an init call?
	 jnz	 short @F	; Jump if not

	 mov	 bx,RSPhead	; Start at front of list for inits

	 jmp	 short DPMIFN_RSPS_NEXT ; Do next RSP

@@:
	 mov	 bx,RSPtail	; Start at tail of list for terms
DPMIFN_RSPS_NEXT:
	 cmp	 bx,-1		; Are we at end of list?
	 je	 near ptr DPMIFN_RSPS_DONE ; Jump if so

; Ignore if the RSP itself is terminating

	 btr	 JGROUP:[bx].RSP_flags,$RSP1stTerm ; 1st termination?
	 jc	 near ptr DPMIFN_RSPS_ADVANCE ; Jump if so

; We must determine if the RSP is servicing clients of the current bitness.

	 or	 al,al		; Is this a 32-bit client?
	 jnz	 short @F	; Jump if not

	 cmp	 JGROUP:[bx].RSP_code16.DESC_ACCESS,0 ; Is descriptor valid?
	 je	 near ptr DPMIFN_RSPS_ADVANCE ; Jump if not

	 jmp	 short DPMIFN_RSPS_CONTINUE ; Continue processing

@@:
	 cmp	 JGROUP:[bx].RSP_code32.DESC_ACCESS,0 ; Is descriptor valid?
	 je	 near ptr DPMIFN_RSPS_ADVANCE ; Jump if not
DPMIFN_RSPS_CONTINUE:

; If this is an initialization call, we have to get descriptors for
; the RSP in the new client

	 or	 ah,ah		; Is this an init call?
	 jnz	 near ptr DPMIFN_RSPS_LOADSELS ; Jump if not

; Allocate a code and data descriptor for the current RSP

	 push	 ax		; Save our args
	 push	 0		; Flags for GET_LDT
	 push	 2		; Number of descs to allocate
	 FIXICALL IGROUP:FGET_LDT,DTE_CSIG ; Allocate descriptors
	 jc	 near ptr DPMIFN_RSPS_ADVANCE ; Failed? - sorry, give up
	 mov	 edx,eax	; First selector to EDX
	 pop	 ax		; Restore our args

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 esi,PGROUP:[esi].DPTSS_LaLDT ; Get LDT address

	 mov	 edi,edx	; Copy base selector to edi
	 and	 edi,not ((mask $TI) or (mask $PL)) ; Clear low bits

	 or	 al,al		; Is this a 32-bit client?
	 jnz	 short @F	; Jump if so

	 mov	 ecx,JGROUP:[bx].RSP_code16.EDQLO ; Get code descriptor
	 mov	 AGROUP:[esi+edi].EDQLO,ecx ; Store in LDT
	 mov	 ecx,JGROUP:[bx].RSP_code16.EDQHI ; ...
	 mov	 AGROUP:[esi+edi].EDQHI,ecx ; ...

	 add	 edi,size DESC_STR ; Advance to next descriptor

	 mov	 ecx,JGROUP:[bx].RSP_data16.EDQLO ; Get data descriptor
	 mov	 AGROUP:[esi+edi].EDQLO,ecx   ; Store in LDT
	 mov	 ecx,JGROUP:[bx].RSP_data16.EDQHI ; ...
	 mov	 AGROUP:[esi+edi].EDQHI,ecx ; ...

	 jmp	 short DPMIFN_RSPS_SETSELS ; Join common code

@@:					; here for 32-bit clients
	 mov	 ecx,JGROUP:[bx].RSP_code32.EDQLO ; Get code descriptor
	 mov	 AGROUP:[esi+edi].EDQLO,ecx ; Store in LDT
	 mov	 ecx,JGROUP:[bx].RSP_code32.EDQHI ; ...
	 mov	 AGROUP:[esi+edi].EDQHI,ecx ; ...

	 add	 edi,size DESC_STR ; Advance to next descriptor

	 mov	 ecx,JGROUP:[bx].RSP_data32.EDQLO ; Get data descriptor low dword
	 mov	 AGROUP:[esi+edi].EDQLO,ecx ; Store in LDT
	 mov	 ecx,JGROUP:[bx].RSP_data32.EDQHI ; ...
	 mov	 AGROUP:[esi+edi].EDQHI,ecx ; ...
DPMIFN_RSPS_SETSELS:
	 call	 DPMIFN_GET_TSS_INDEX ; Get index of current TSS into ECX

	 lea	 edi,JGROUP:[bx].RSP_selectors ; Get offset of selector array
	 mov	 JGROUP:[edi+ecx*(type RSP_selectors)],dx ; Store base selector

	 jmp	 short @F

DPMIFN_RSPS_LOADSELS:
	 call	 DPMIFN_GET_TSS_INDEX ; Get index of current TSS into ECX

	 lea	 edi,JGROUP:[bx].RSP_selectors ; Get offset of selector array
	 mov	 dx,JGROUP:[edi+ecx*(type RSP_selectors)] ; Get base selector
@@:
	 or	 al,al			; Is this a 32-bit client?
	 jnz	 short @F		; Jump if so

	 movzx	 ecx,JGROUP:[bx].RSP_cb16 ; Load 16-bit callback offset

	 jmp	 short DPMIFN_RSPS_DOCALL ; Go do the call

@@:
	 mov	 ecx,JGROUP:[bx].RSP_cb32 ; Load 32-bit callback offset
DPMIFN_RSPS_DOCALL:

; It is possible that a terminating client may have been present in the
; system prior to installation of the RSP.  In this case, the selector
; for the client will be zero, and we just skip calling this RSP.

	 or	 dx,dx			; does client have a selector?
	 jz	 near ptr DPMIFN_RSPS_ADVANCE ; jump if not

	 pushad 		; Save the world
	 REGSAVE <ds,es,fs,gs>	; Save segment registers

	 push	 LPMSTK_FVEC.FSEL ; Save LPM stack selector
	 push	 LPMSTK_FVEC.FOFF ; ... 	   offset

; Protect the PL0 stack to here

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 push	 PGROUP:[esi].TSS_SS0  ; Save old stack selector
	 push	 PGROUP:[esi].TSS_ESP0 ; Save pointer to stack top

	 mov	 PGROUP:[esi].TSS_ESP0,esp ; Protect the stack to this point

	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

; The PL0 stack is mapped by RSPRET_STR

RSPRET_STR struc

RSPRET_ESP0 dd	 ?		; Old TSS_ESP0 to be restored
RSPRET_SS0 dw	 ?		; ... TSS_SS0 ...
RSPRET_LPMSTK df ?		; ... LPMSTK_FVEC ...
RSPRET_SELS dw	 4 dup (?)	; DS, ES, FS, GS
RSPRET_EGP db	 (size PUSHAD_STR) dup (?) ; All EGP registers

RSPRET_STR ends

	 lds	 ebx,LPMSTK_FVEC ; Get PL3 stack
	 assume  ds:nothing	; Tell the assembler about it

	 inc	 LPMSTK_CNT	; Count in another one

	 mov	 si,DPMI_IDEF	; Get selector for PL3 return

RETF_STR struc

RETF_IP  dw	 ?
RETF_CS  dw	 ?

RETF_STR ends

	 or	 al,al		; Is client 16-bit?
	 jnz	 short @F	; jump if 32-bit

	 sub	 ebx,type RETF_STR ; Make room for 16-bit RETF frame

	 mov	 ds:[ebx].RETF_CS,si ; Build 16-bit RETF frame
	 mov	 ds:[ebx].RETF_IP,PMRSP ; Save offset for PL3 return

	 jmp	 short DPMI_RSPS_FRAME ; Continue processing

@@:

RETFD_STR struc

RETFD_EIP dd	  ?
RETFD_CS  dw	  ?,?

RETFD_STR ends

	 sub	 ebx,type RETFD_STR ; Make room for 32-bit RETF frame

	 mov	 ds:[ebx].RETFD_CS,si ; Build 32-bit RETF frame
	 mov	 ds:[ebx].RETFD_EIP,PMRSP ; Save offset for PL3 return
DPMI_RSPS_FRAME:
	 mov	 LPMSTK_FVEC.FOFF,ebx ; Protect the PL3 stack

	 movzx	 ax,ah		; Set init/term arg to RSP
	 push	 LPMSTK_FVEC.FSEL.EDD ; Stack to run RSP on - selector
	 push	 ebx		; Stack to run RSP on - offset
	 push	 dword ptr (@DPMIOPL shl $IOPL) ; Flags for RSP
	 push	 edx		; RSP code selector (w/filler)
	 push	 ecx		; RSP entry offset

	 add	 dx,size DESC_STR ; Get data selector
	 mov	 ds,dx		; Load data selector
	 xor	 dx,dx		; Make a zero
	 mov	 es,dx		; Zero es
	 mov	 fs,dx		; Zero fs
	 mov	 gs,dx		; Zero gs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 str	 bx		; Task identifier

	 iretd			; Run the RSP

	 assume  ss:PGROUP	; Tell the assembler about it

	 public DPMI_RSPRET
DPMI_RSPRET:

COMMENT|

We arrive here via the call gate at DPMI_IDEF:PMRSP.  The stack is
mapped by INTDPI_STR followed by RSPRET_STR.

The state of the carry bit is important for termination calls, and
must be preserved.

|

	 lea	 esp,[esp+(size INTDPI_STR)] ; Strip off, preserve carry
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS

	 pop	 PGROUP:[eax].TSS_ESP0 ; Restore
	 pop	 PGROUP:[eax].TSS_SS0  ; ...

	 pushf			; Preserve carry across call
	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers
	 popf			; Recall flags

; De-allocate our portion of the LPM stack

	 pop	 LPMSTK_FVEC.FOFF ; De-allocate it
	 pop	 LPMSTK_FVEC.FSEL ; ...
	 dec	 LPMSTK_CNT	; Count it out

	 REGREST <gs,fs,es,ds>	; Restore segment registers
	 assume  ds:PGROUP,es:JGROUP ; Tell the assembler about it
	 assume  fs:AGROUP,gs:nothing ; ...

	 popad			; Restore all EGP registers

	 setc	 dl		; Save carry state in DL

	 or	 ah,ah		; Is this a termination call?
	 jnz	 short @F	; Jump if so

	 inc	 JGROUP:[bx].RSP_usecount ; Indicate RSP has another user

	 jmp	 short DPMIFN_RSPS_ADVANCE ; go do next one

@@:
	 dec	 JGROUP:[bx].RSP_usecount ; One fewer user
	 jnz	 short DPMIFN_RSPS_ADVANCE ; If RSP still has users, continue

	 or	 dl,dl		; Was carry set?
	 jz	 short DPMIFN_RSPS_ADVANCE ; Jump if not

	 call	 DPMIFN_REMOVE_RSP ; Get rid of this RSP; returns with
				; RSP_prev field in bx
	 jmp	 DPMIFN_RSPS_NEXT ; Go around again

DPMIFN_RSPS_ADVANCE:		; Get next in list
	 or	 ah,ah		; Is this an init call?
	 jnz	 short @F	; Jump if not

	 mov	 bx,JGROUP:[bx].RSP_next; get next for init calls

	 jmp	 DPMIFN_RSPS_NEXT ; Go around again

@@:
	 mov	 bx,JGROUP:[bx].RSP_prev ; Go backwards for terminate calls

	 jmp	 DPMIFN_RSPS_NEXT ; Go around again

DPMIFN_RSPS_DONE:
	 popad			; Restore all EGP registers

	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_CALL_RSPS endp		; End DPMIFN_CALL_RSPS procedure
	 NPPROC  DPMIFN_GET_TSS_INDEX -- Get Index Of Current TSS
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT |

Calculate the zero-based index of the current TSS.

On exit:

ECX	=	index of current TSS

|

	 REGSAVE <eax,edx>	; Save regs

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 sub	 eax,PVMTSS	; Sub offset in PGROUP of the 1st TSS
	 xor	 edx,edx	; Zero high part of qword dividend
	 mov	 ecx,type DPTSS_STR ; Load divisor
	 div	 ecx		; Calc index
	 mov	 ecx,eax	; Return result

	 REGREST <edx,eax>	; Restore regs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GET_TSS_INDEX endp	; End DPMIFN_GET_TSS_INDEX procedure
	 NPPROC  DPMIFN_REMOVE_RSP -- Remove Resident Service Provider
	 assume  ds:PGROUP,es:JGROUP,fs:AGROUP,gs:nothing,ss:nothing
COMMENT |

Remove an RSP and free its resources.

On entry:

BX	=	offset in JGROUP of RSP struc

On exit:

BX	=	RSP_prev from deleted RSP struc

|
	 REGSAVE <eax,ecx,edx,esi,edi,ds,es,fs,gs> ; Save registers

	 push	 ds			; swap ds and es
	 push	 es
	 pop	 ds			; ds <- JGROUP
	 pop	 es			; es <- PGROUP
	 assume  ds:JGROUP,es:PGROUP	; tell assembler

	 mov	 gs,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  gs:IGROUP	; Tell the assembler about it

; Free any memory that was relocated to the shared memory area

	 lea	 esi,JGROUP:[bx].RSP_regions	; point to 1st region
	 call	 RSP_FREE_SEGMENT		; free the region

	 add	 esi,size NormalizedRSPSegment ; point to next region
	 call	 RSP_FREE_SEGMENT		; free the region

	 add	 esi,size NormalizedRSPSegment ; point to next region
	 call	 RSP_FREE_SEGMENT		; free the region

	 add	 esi,size NormalizedRSPSegment ; point to next region
	 call	 RSP_FREE_SEGMENT		; free the region

; unlink this RSP from the chain

	 mov	 si,JGROUP:[bx].RSP_next	; si <- next RSP
	 mov	 di,JGROUP:[bx].RSP_prev	; di <- prev RSP

	 cmp	 si,-1				; is this the tail?
	 je	 short @F			; jump if so

	 mov	 JGROUP:[si].RSP_prev,di	; link out of reverse chain

	 jmp	 short DPMIFN_RSP_REMREV	; now go do other chain

@@:
	 mov	 RSPtail,di	; Set new tail
DPMIFN_RSP_REMREV:
	 cmp	 di,-1		; Is this the head?
	 je	 short @F	; Jump if so

	 mov	 JGROUP:[di].RSP_next,si ; Link out of forward chain

	 jmp	 short DPMIFN_RSP_FREE

@@:
	 mov	 RSPhead,si	; Set new head
DPMIFN_RSP_FREE:
	 mov	 si,bx		; Save RSP ptr
	 mov	 bx,di		; Return old RSP_prev ptr

	 mov	 ax,DTE_DSJG	; AX <- JGROUP data sel
	 mov	 es,ax		; ES <- JGROUP data sel
	 assume  es:JGROUP	; Tell the assembler about it

; Now zero the whole thing

	 mov	 di,si		; DI <- ptr to RSP struc
	 mov	 cx,type RSPdata ; Number of bytes to zap
	 xor	 al,al		; Byte value to store
	 cld			; Forward
     rep stos	 JGROUP:[di].LO ; Zap it

	 REGREST <gs,fs,es,ds,edi,esi,edx,ecx,eax> ; restore regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; ...

	 ret					; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_REMOVE_RSP endp		; End DPMIFN_REMOVE_RSP procedure
	 NPPROC  RSP_FREE_SEGMENT -- Subfunction To DPMIFN_REMOVE_RSP
	 assume  ds:JGROUP,es:PGROUP,fs:nothing,gs:IGROUP,ss:nothing
COMMENT|

Auxilliary function for DPMIFN_REMOVE_RSP

On entry:

DS:ESI	 =	 NormalizedRSPSegment being removed

|

	 REGSAVE <eax,ebx,ds>	; Save registers

	 mov	 eax,ds:[esi].NRSPS_base ; Get base of segment

	 cmp	 eax,LinearBottom ; Do we need to free this?
	 jb	 short @F	; Jump if not

	 mov	 ebx,ds:[esi].NRSPS_size ; Get the size argument

	 or	 ebx,ebx	; Is it zero length?
	 jz	 short @F	; Skip if so

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 FIXICALL IGROUP:FVMM_FREE,DTE_CSIG ; Free the memory
@@:
	 REGREST <ds,ebx,eax>	; Restore regs
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RSP_FREE_SEGMENT endp		; End RSP_FREE_SEGMENT procedure
	 align	 4		; Ensure dword alignment

JCODE	 ends			; End JCODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_RSP module
